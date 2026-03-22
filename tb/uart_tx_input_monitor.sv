`ifndef UART_TX_INPUT_MONITOR_SV
`define UART_TX_INPUT_MONITOR_SV

// =============================================================================
// UART TX Input Monitor (Passive)
// Snoops the TX FIFO write interface to capture data being written into the
// DUT's TX FIFO. Sends captured items to an analysis port as "expected" TX data.
// This replaces the old driver→scoreboard analysis port connection.
// =============================================================================
class uart_tx_input_monitor extends uvm_monitor;

  `uvm_component_utils(uart_tx_input_monitor)

  virtual uart_fifo_if.tx_monitor vif;
  uart_config                     cfg;

  uvm_analysis_port #(uart_seq_item) ap;

  function new(string name = "uart_tx_input_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual uart_fifo_if.tx_monitor)::get(this, "", "fifo_vif_tx_mon", vif))
      `uvm_fatal("NOVIF", "Could not get uart_fifo_if.tx_monitor from config_db")
    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
  endfunction

  virtual task run_phase(uvm_phase phase);
    @(posedge vif.reset_n);
    repeat(5) @(vif.tx_mon_cb);

    forever begin
      collect_tx_write();
    end
  endtask

  // -------------------------------------------------------------------------
  // Passive: wait for fifo_write pulse, capture write_data
  // -------------------------------------------------------------------------
  virtual task collect_tx_write();
    uart_seq_item item;

    // Wait for a FIFO write pulse
    while (vif.tx_mon_cb.uart_tx_fifo_write !== 1'b1)
      @(vif.tx_mon_cb);

    // Only capture if the FIFO accepted the write (not full)
    if (vif.tx_mon_cb.uart_tx_fifo_full !== 1'b1) begin
      // Capture the data being written
      item = uart_seq_item::type_id::create("tx_in_mon_item");
      item.direction    = UART_DIR_TX;
      item.data         = vif.tx_mon_cb.uart_tx_fifo_write_data;
      item.packet_width = cfg.packet_width;
      item.parity_en    = cfg.parity_en;
      item.parity_odd_even = cfg.parity_odd_even;

      ap.write(item);
      `uvm_info("TX_IN_MON", $sformatf("Snooped TX FIFO write: data=0x%02h", item.data), UVM_MEDIUM)
    end else begin
      `uvm_info("TX_IN_MON", $sformatf("Skipped TX FIFO write (FIFO full): data=0x%02h",
                vif.tx_mon_cb.uart_tx_fifo_write_data), UVM_MEDIUM)
    end

    // Wait for write to deassert before looking for next
    @(vif.tx_mon_cb);
  endtask

endclass : uart_tx_input_monitor

`endif // UART_TX_INPUT_MONITOR_SV
