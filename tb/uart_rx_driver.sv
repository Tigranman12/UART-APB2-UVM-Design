`ifndef UART_RX_DRIVER_SV
`define UART_RX_DRIVER_SV

// =============================================================================
// UART RX Driver
// Drives the uart_rx serial line into the DUT to simulate incoming UART data.
// Generates start bit → data bits (LSB first) → parity → stop bit(s)
// at the correct baud rate timing derived from uart_config.
// =============================================================================
class uart_rx_driver extends uvm_driver #(uart_seq_item);

  `uvm_component_utils(uart_rx_driver)

  virtual uart_if.rx_driver vif;
  uart_config               cfg;



  function new(string name = "uart_rx_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if.rx_driver)::get(this, "", "uart_vif_rx_drv", vif))
      `uvm_fatal("NOVIF", "Could not get uart_if.rx_driver from config_db")
    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_seq_item item;
    // Initialize uart_rx to idle (high)
    vif.uart_rx = 1'b1;
    @(posedge vif.reset_n);
    repeat(10) @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(item);
      drive_serial_frame(item);
      seq_item_port.item_done();
    end
  endtask

  // -------------------------------------------------------------------------
  // Drive one UART frame on the uart_rx line
  // -------------------------------------------------------------------------
  virtual task drive_serial_frame(uart_seq_item item);
    int data_bits;
    bit parity_calc;

    data_bits = cfg.get_data_bits();

    `uvm_info("RX_DRV", $sformatf("Driving RX: data=0x%02h (%0d bits) cycles_per_bit=%0d", item.data, data_bits, cfg.cycles_per_bit), UVM_MEDIUM)

    // --- Start bit (logic 0) ---
    vif.uart_rx <= 1'b0;
    #(cfg.cycles_per_bit * 10);

    // --- Data bits (LSB first) ---
    for (int i = 0; i < data_bits; i++) begin
      vif.uart_rx <= item.data[i];
      #(cfg.cycles_per_bit * 10);
    end

    // --- Parity bit (if enabled) ---
    if (cfg.parity_en) begin
      parity_calc = cfg.parity_odd_even;
      for (int i = 0; i < data_bits; i++)
        parity_calc = parity_calc ^ item.data[i];
      
      // Inject parity error if requested
      if (item.inject_parity_error) begin
        parity_calc = ~parity_calc;
        `uvm_info("RX_DRV", "Injecting PARITY ERROR", UVM_MEDIUM)
      end
      
      vif.uart_rx <= parity_calc;
      #(cfg.cycles_per_bit * 10);
    end

    // --- Stop bit(s) (logic 1) ---
    // Inject frame error if requested (drive logic 0 during stop bit)
    if (item.inject_frame_error) begin
        `uvm_info("RX_DRV", "Injecting FRAME ERROR", UVM_MEDIUM)
        vif.uart_rx <= 1'b0; 
    end else begin
        vif.uart_rx <= 1'b1;
    end

    case (cfg.stop_bit_count)
      2'b00: #(cfg.cycles_per_bit * 10);       // 1 stop bit
      2'b01: #(cfg.cycles_per_bit * 15);      // 1.5 stop bits (1.5 * 10 = 15)
      default: #(cfg.cycles_per_bit * 20);    // 2 stop bits (2 * 10 = 20)
    endcase

    // Restore idle (especially after injected frame error)
    vif.uart_rx <= 1'b1;

    // Small idle gap
    #(cfg.cycles_per_bit * 10);
  endtask

endclass : uart_rx_driver

`endif // UART_RX_DRIVER_SV
