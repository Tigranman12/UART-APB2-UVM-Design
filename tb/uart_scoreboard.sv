`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

// =============================================================================
// UART Scoreboard
// Compares data sent through the UART with data received to verify correctness.
//
// TX path: data written to TX FIFO (expected) → observed on uart_tx serial line (actual)
// RX path: data driven on uart_rx serial line (expected) → read from RX FIFO (actual)
// =============================================================================
class uart_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(uart_scoreboard)

  // Analysis FIFOs
  uvm_tlm_analysis_fifo #(uart_seq_item) tx_fifo_in;   // from TX input monitor (expected TX data)
  uvm_tlm_analysis_fifo #(uart_seq_item) tx_serial_in;  // from TX output monitor (actual TX serial)
  uvm_tlm_analysis_fifo #(uart_seq_item) rx_serial_in; // from RX input monitor (expected RX data)
  uvm_tlm_analysis_fifo #(uart_seq_item) rx_fifo_out;   // from RX output monitor (actual RX FIFO)

  // Statistics
  int tx_match_count   = 0;
  int tx_mismatch_count = 0;
  int rx_match_count   = 0;
  int rx_mismatch_count = 0;

  uart_config cfg;

  // Completion events — triggered when all expected items have been matched
  event tx_done;
  event rx_done;
  int   expected_tx_count = 0;
  int   expected_rx_count = 0;

  // Deadlock timeout: 20 full frames at worst-case baud (uart_sm=0, 300 baud)
  // 20 * (1+8+1+2) * 33333 * 10 = ~88 ms of sim time
  localparam int SB_TIMEOUT_NS = 100_000_000;

  function new(string name = "uart_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tx_fifo_in   = new("tx_fifo_in", this);
    tx_serial_in = new("tx_serial_in", this);
    rx_serial_in = new("rx_serial_in", this);
    rx_fifo_out  = new("rx_fifo_out", this);

    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
  endfunction

  task run_phase(uvm_phase phase);
    fork
      compare_tx_path();
      compare_rx_path();
    join_none
  endtask

  // -------------------------------------------------------------------------
  // TX path: Compare data written to TX FIFO with data captured on serial line
  // -------------------------------------------------------------------------
  task compare_tx_path();
    uart_seq_item expected_item, actual_item;
    bit [7:0] expected_data, actual_data;
    int data_bits;

    forever begin
      fork : sb_tx_wait
        begin
          tx_fifo_in.get(expected_item);
          tx_serial_in.get(actual_item);
          disable sb_tx_wait;
        end
        begin
          #(SB_TIMEOUT_NS * 1ns);
          `uvm_fatal("SB_TX", "Deadlock timeout waiting for TX scoreboard items")
        end
      join

      data_bits = cfg.get_data_bits();

      // Mask upper bits according to packet_width
      expected_data = mask_data(expected_item.data, data_bits);
      actual_data   = mask_data(actual_item.data, data_bits);

      if (expected_data === actual_data) begin
        tx_match_count++;
        `uvm_info("SB_TX", $sformatf("TX MATCH #%0d [%s]: expected=0x%02h actual=0x%02h",
                  tx_match_count, expected_item.direction.name(), expected_data, actual_data), UVM_MEDIUM)
        if (expected_tx_count > 0 && tx_match_count >= expected_tx_count)
          -> tx_done;
      end
      else begin
        tx_mismatch_count++;
        `uvm_error("SB_TX", $sformatf("TX MISMATCH #%0d [%s]: expected=0x%02h actual=0x%02h",
                   tx_mismatch_count, expected_item.direction.name(), expected_data, actual_data))
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // RX path: Compare data driven on serial line with data read from RX FIFO
  // -------------------------------------------------------------------------
  task compare_rx_path();
    uart_seq_item expected_item, actual_item;
    bit [7:0] expected_data, actual_data;
    int data_bits;

    forever begin
      fork : sb_rx_wait
        begin
          rx_serial_in.get(expected_item);
          rx_fifo_out.get(actual_item);
          disable sb_rx_wait;
        end
        begin
          #(SB_TIMEOUT_NS * 1ns);
          `uvm_fatal("SB_RX", "Deadlock timeout waiting for RX scoreboard items")
        end
      join

      data_bits = cfg.get_data_bits();

      expected_data = mask_data(expected_item.data, data_bits);
      actual_data   = mask_data(actual_item.data, data_bits);

      if (expected_data === actual_data) begin
        rx_match_count++;
        `uvm_info("SB_RX", $sformatf("RX MATCH #%0d [%s]: expected=0x%02h actual=0x%02h",
                  rx_match_count, expected_item.direction.name(), expected_data, actual_data), UVM_MEDIUM)
        if (expected_rx_count > 0 && rx_match_count >= expected_rx_count)
          -> rx_done;
      end
      else begin
        // Parity or frame error on the serial line corrupts the received data — skip data check
        if (expected_item.parity_error) begin
          `uvm_info("SB_RX", "Ignoring data mismatch due to observed parity error", UVM_MEDIUM)
        end else if (expected_item.frame_error) begin
          `uvm_info("SB_RX", "Ignoring data mismatch due to observed frame error", UVM_MEDIUM)
        end else begin
          rx_mismatch_count++;
          `uvm_error("SB_RX", $sformatf("RX MISMATCH #%0d [%s]: expected=0x%02h actual=0x%02h",
                     rx_mismatch_count, expected_item.direction.name(), expected_data, actual_data))
        end
      end

      // Check DUT error flags match what the input monitor observed on the serial line
      if (expected_item.parity_error) begin
        if (actual_item.parity_error)
          `uvm_info("SB_RX", "SUCCESS: Parity error correctly flagged by DUT", UVM_LOW)
        else
          `uvm_error("SB_RX", "FAILURE: Parity error NOT flagged by DUT")
      end

      if (expected_item.frame_error) begin
        if (actual_item.frame_error)
          `uvm_info("SB_RX", "SUCCESS: Frame error correctly flagged by DUT", UVM_LOW)
        else
          `uvm_error("SB_RX", "FAILURE: Frame error NOT flagged by DUT")
      end
    end
  endtask

  // Mask data bits based on packet width
  function bit [7:0] mask_data(bit [7:0] data, int bits);
    bit [7:0] mask;
    mask = (1 << bits) - 1;
    return data & mask;
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB_REPORT", "========================================", UVM_LOW)
    `uvm_info("SB_REPORT", "       SCOREBOARD SUMMARY REPORT        ", UVM_LOW)
    `uvm_info("SB_REPORT", "========================================", UVM_LOW)
    `uvm_info("SB_REPORT", $sformatf("TX Path: %0d matches, %0d mismatches",
              tx_match_count, tx_mismatch_count), UVM_LOW)
    `uvm_info("SB_REPORT", $sformatf("RX Path: %0d matches, %0d mismatches",
              rx_match_count, rx_mismatch_count), UVM_LOW)
    `uvm_info("SB_REPORT", "========================================", UVM_LOW)

    if (tx_mismatch_count > 0 || rx_mismatch_count > 0)
      `uvm_error("SB_REPORT", "TEST FAILED — mismatches detected!")
    else if (tx_match_count == 0 && rx_match_count == 0)
      `uvm_error("SB_REPORT", "TEST FAILED — no data was processed!")
    else
      `uvm_info("SB_REPORT", "TEST PASSED — all data matched!", UVM_LOW)
  endfunction

endclass : uart_scoreboard

`endif // UART_SCOREBOARD_SV
