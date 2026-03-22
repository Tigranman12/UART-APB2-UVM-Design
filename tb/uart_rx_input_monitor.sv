`ifndef UART_RX_INPUT_MONITOR_SV
`define UART_RX_INPUT_MONITOR_SV

// =============================================================================
// UART RX Input Monitor (Passive)
// Snoops the uart_rx serial line to reconstruct the data being driven into
// the DUT. Sends captured items to an analysis port as "expected" RX data.
// This replaces the old driver→scoreboard analysis port connection.
//
// Uses the same sampling algorithm as uart_tx_monitor:
//   1. Detect falling edge of start bit
//   2. Wait 1.5 bit-periods to reach mid-point of first data bit
//   3. Sample, then advance 1 bit-period for each subsequent bit
// =============================================================================
class uart_rx_input_monitor extends uvm_monitor;

  `uvm_component_utils(uart_rx_input_monitor)

  virtual uart_if.rx_monitor vif;
  uart_config                cfg;

  uvm_analysis_port #(uart_seq_item) ap;

  function new(string name = "uart_rx_input_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual uart_if.rx_monitor)::get(this, "", "uart_vif_rx_mon", vif))
      `uvm_fatal("NOVIF", "Could not get uart_if.rx_monitor from config_db")
    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
  endfunction

  virtual task run_phase(uvm_phase phase);
    @(posedge vif.reset_n);
    repeat(5) @(posedge vif.clk);

    forever begin
      collect_serial_frame();
    end
  endtask

  // -------------------------------------------------------------------------
  // Passive: detect start bit on uart_rx, sample data bits at mid-bit timing
  // -------------------------------------------------------------------------
  virtual task collect_serial_frame();
    uart_seq_item item;
    int data_bits;
    bit [7:0] rx_data;
    bit parity_bit;
    bit parity_calc;

    data_bits = cfg.get_data_bits();

    // Wait for start bit (uart_rx goes low)
    @(negedge vif.uart_rx);

    // Advance 1.5 bit-periods to reach the middle of the first data bit
    repeat(cfg.cycles_per_bit + cfg.cycles_per_bit / 2) @(posedge vif.clk);

    // Sample data bits (LSB first)
    rx_data = 8'h00;
    rx_data[0] = vif.uart_rx;
    for (int i = 1; i < data_bits; i++) begin
      repeat(cfg.cycles_per_bit) @(posedge vif.clk);
      rx_data[i] = vif.uart_rx;
    end

    // Build the item
    item = uart_seq_item::type_id::create("rx_in_mon_item");
    item.direction    = UART_DIR_RX;
    item.data         = rx_data;
    item.packet_width = cfg.packet_width;
    item.parity_en    = cfg.parity_en;
    item.parity_odd_even = cfg.parity_odd_even;

    // Sample parity bit if enabled
    if (cfg.parity_en) begin
      repeat(cfg.cycles_per_bit) @(posedge vif.clk);
      parity_bit = vif.uart_rx;
      // Check parity
      parity_calc = cfg.parity_odd_even;
      for (int i = 0; i < data_bits; i++)
        parity_calc = parity_calc ^ rx_data[i];
      if (parity_calc != parity_bit)
        item.parity_error = 1'b1;  // Flag that a parity error was observed
    end

    // Wait through stop bit
    repeat(cfg.cycles_per_bit) @(posedge vif.clk);
    if (vif.uart_rx !== 1'b1)
      item.frame_error = 1'b1;  // Flag that a frame error was observed

    ap.write(item);
    `uvm_info("RX_IN_MON", $sformatf("Snooped RX serial: data=0x%02h", item.data), UVM_MEDIUM)
  endtask

endclass : uart_rx_input_monitor

`endif // UART_RX_INPUT_MONITOR_SV
