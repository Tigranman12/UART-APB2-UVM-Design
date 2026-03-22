`ifndef UART_TX_MONITOR_SV
`define UART_TX_MONITOR_SV

// =============================================================================
// UART TX Monitor
// Monitors the uart_tx serial output line from the DUT.
// Detects start bit, samples data bits at mid-bit, optional parity, stop bit.
// Broadcasts received transactions on an analysis port.
// =============================================================================
class uart_tx_monitor extends uvm_monitor;

  `uvm_component_utils(uart_tx_monitor)

  virtual uart_if.tx_monitor       vif;
  uart_config           cfg;

  uvm_analysis_port #(uart_seq_item) ap;

  function new(string name = "uart_tx_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual uart_if.tx_monitor)::get(this, "", "uart_vif_tx_mon", vif))
      `uvm_fatal("NOVIF", "Could not get uart_if from config_db")
    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_seq_item item;
    @(posedge vif.reset_n);
    repeat(5) @(posedge vif.clk);

    forever begin
      item = uart_seq_item::type_id::create("tx_mon_item");
      item.direction       = UART_DIR_TX;
      item.packet_width    = cfg.packet_width;
      item.parity_en       = cfg.parity_en;
      item.parity_odd_even = cfg.parity_odd_even;
      collect_serial_frame(item);
      ap.write(item);
      `uvm_info("TX_MON", $sformatf("Captured TX: %s", item.convert2string()), UVM_MEDIUM)
    end
  endtask

  // -------------------------------------------------------------------------
  // Collect one UART frame from the uart_tx serial line.
  //
  // Uses the standard UART receiver approach:
  //   1. Detect falling edge of start bit
  //   2. Wait 1.5 bit-periods to reach mid-point of first data bit
  //   3. Sample, then advance 1 bit-period for each subsequent bit
  // -------------------------------------------------------------------------
  virtual task collect_serial_frame(uart_seq_item item);
    int data_bits;
    bit [7:0] rx_data;
    bit parity_bit;
    bit parity_calc;

    data_bits = cfg.get_data_bits();

    // Wait for start bit (uart_tx goes low)
    @(negedge vif.uart_tx);

    // Advance 1.5 bit-periods to reach the middle of the first data bit.
    // This skips the start bit entirely and lands mid-data-bit[0].
    repeat(cfg.cycles_per_bit + cfg.cycles_per_bit / 2) @(posedge vif.clk);

    // Sample data bits (LSB first)
    rx_data = 8'h00;
    rx_data[0] = vif.uart_tx;
    for (int i = 1; i < data_bits; i++) begin
      repeat(cfg.cycles_per_bit) @(posedge vif.clk);
      rx_data[i] = vif.uart_tx;
    end
    item.data = rx_data;

    // Sample parity bit if enabled
    if (cfg.parity_en) begin
      repeat(cfg.cycles_per_bit) @(posedge vif.clk);
      parity_bit = vif.uart_tx;
      // Check parity
      parity_calc = cfg.parity_odd_even; // init with odd/even select
      for (int i = 0; i < data_bits; i++)
        parity_calc = parity_calc ^ rx_data[i];
      if (parity_calc != parity_bit)
        item.parity_error = 1'b1;
    end

    // Wait through stop bit(s)
    repeat(cfg.cycles_per_bit) @(posedge vif.clk);
    if (vif.uart_tx !== 1'b1)
      item.frame_error = 1'b1;

  endtask

endclass : uart_tx_monitor

`endif // UART_TX_MONITOR_SV
