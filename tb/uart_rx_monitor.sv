`ifndef UART_RX_MONITOR_SV
`define UART_RX_MONITOR_SV

// =============================================================================
// UART RX Monitor (Passive)
// Monitors the DUT's RX FIFO output — purely passive, no output signals.
// Watches uart_rx_fifo_data_ready (driven by the auto-reader in testbench),
// captures uart_rx_fifo_data_out, and broadcasts on an analysis port.
// Also monitors error flags (parity_error, frame_error).
// =============================================================================
class uart_rx_monitor extends uvm_monitor;

  `uvm_component_utils(uart_rx_monitor)

  virtual uart_fifo_if.rx_monitor vif;
  uart_config                     cfg;

  uvm_analysis_port #(uart_seq_item) ap;

  function new(string name = "uart_rx_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual uart_fifo_if.rx_monitor)::get(this, "", "fifo_vif_rx_mon", vif))
      `uvm_fatal("NOVIF", "Could not get uart_fifo_if.rx_monitor from config_db")
    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
  endfunction

  virtual task run_phase(uvm_phase phase);
    @(posedge vif.reset_n);
    repeat(5) @(vif.rx_mon_cb);

    forever begin
      collect_rx_data();
    end
  endtask

  // -------------------------------------------------------------------------
  // Passive: wait for data_ready pulse from the auto-reader, capture data
  // -------------------------------------------------------------------------
  virtual task collect_rx_data();
    uart_seq_item item;

    // Wait for data_ready to go high (FIFO read completed by auto-reader)
    while (vif.rx_mon_cb.uart_rx_fifo_data_ready !== 1'b1)
      @(vif.rx_mon_cb);

    // Capture the data
    item = uart_seq_item::type_id::create("rx_mon_item");
    item.direction        = UART_DIR_RX;
    item.data             = vif.rx_mon_cb.uart_rx_fifo_data_out;
    item.parity_error     = vif.rx_mon_cb.uart_rx_parity_error;
    item.frame_error      = vif.rx_mon_cb.uart_rx_frame_error;
    item.fifo_write_error = vif.rx_mon_cb.uart_rx_fifo_write_error;
    item.fifo_read_error  = vif.rx_mon_cb.uart_rx_fifo_read_error;
    item.packet_width     = cfg.packet_width;
    item.parity_en        = cfg.parity_en;
    item.parity_odd_even  = cfg.parity_odd_even;

    // Wait for data_ready to deassert before looking for next item
    @(vif.rx_mon_cb);

    ap.write(item);
    `uvm_info("RX_MON", $sformatf("Read RX FIFO: %s", item.convert2string()), UVM_MEDIUM)
  endtask

endclass : uart_rx_monitor

`endif // UART_RX_MONITOR_SV
