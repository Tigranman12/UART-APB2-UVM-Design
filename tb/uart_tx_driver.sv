`ifndef UART_TX_DRIVER_SV
`define UART_TX_DRIVER_SV

// =============================================================================
// UART TX Driver
// Writes data into the DUT's TX FIFO via the uart_fifo_if interface.
// Gets transactions from the TX sequencer, asserts fifo_write + write_data.
// =============================================================================
class uart_tx_driver extends uvm_driver #(uart_seq_item);

  `uvm_component_utils(uart_tx_driver)

  virtual uart_fifo_if.tx_driver vif;
  uart_config                    cfg;



  function new(string name = "uart_tx_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_fifo_if.tx_driver)::get(this, "", "fifo_vif_tx_drv", vif))
      `uvm_fatal("NOVIF", "Could not get uart_fifo_if.tx_driver from config_db")
    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
  endfunction

  task run_phase(uvm_phase phase);
    uart_seq_item item;
    // Initialize FIFO write signals
    vif.tx_drv_cb.uart_tx_fifo_write      <= 1'b0;
    vif.tx_drv_cb.uart_tx_fifo_write_data <= 8'h00;
    @(posedge vif.reset_n);  // Wait for reset deassert
    repeat(5) @(vif.tx_drv_cb);  // Small settling delay

    forever begin
      seq_item_port.get_next_item(item);
      drive_item(item);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(uart_seq_item item);
    // Wait until TX FIFO is not full
    while (vif.tx_drv_cb.uart_tx_fifo_full === 1'b1)
      @(vif.tx_drv_cb);

    // Write data to FIFO
    vif.tx_drv_cb.uart_tx_fifo_write      <= 1'b1;
    vif.tx_drv_cb.uart_tx_fifo_write_data <= item.data;
    @(vif.tx_drv_cb);
    vif.tx_drv_cb.uart_tx_fifo_write      <= 1'b0;
    @(vif.tx_drv_cb);

    `uvm_info("TX_DRV", $sformatf("Wrote data=0x%02h to TX FIFO", item.data), UVM_MEDIUM)
  endtask

endclass : uart_tx_driver

`endif // UART_TX_DRIVER_SV
