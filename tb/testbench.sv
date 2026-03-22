// =============================================================================
// Top-level Testbench for UART UVM Environment
// =============================================================================
`timescale 1ns/1ps
`include "uart_if.sv"
`include "uart_fifo_if.sv"
`include "apb_if.sv"
`include "intr_if.sv"
`include "uart_regs_uvm_pkg.sv"
`include "apb_pkg.sv"
`include "uart_pkg.sv"

//import uvm_pkg::*;
import uart_pkg::*;
import apb_pkg::*;

module tb_top;

  // Clock and Reset signals
  logic PCLK;
  logic PRESETn;

  // Clock Generation (100MHz)
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end

  // Reset Generation
  initial begin
    PRESETn = 0;
    #100 PRESETn = 1;
  end

  // Interface instances
  uart_if      u_if(.clk(PCLK), .reset_n(PRESETn));
  uart_fifo_if f_if(.clk(PCLK), .reset_n(PRESETn));
  apb_if       a_if(.PCLK(PCLK), .PRESETn(PRESETn));
  intr_if      i_if(.clk(PCLK), .reset_n(PRESETn));

  // DUT instantiation
  apb2uart_top dut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PADDR(a_if.PADDR),
    .PSEL(a_if.PSEL),
    .PENABLE(a_if.PENABLE),
    .PWRITE(a_if.PWRITE),
    .PWDATA(a_if.PWDATA),
    .PRDATA(a_if.PRDATA),
    .PREADY(a_if.PREADY),
    // .PSLVERR() // Not present in DUT
    .interrupt(i_if.interrupt),
    .uart_rx(u_if.uart_rx),
    .uart_tx(u_if.uart_tx),
    .uart_tx_fifo_write(f_if.uart_tx_fifo_write),
    .uart_tx_fifo_write_data(f_if.uart_tx_fifo_write_data),
    .uart_rx_fifo_read_data(f_if.uart_rx_fifo_read_data),
    .uart_rx_fifo_data_out(f_if.uart_rx_fifo_data_out),
    .uart_rx_fifo_data_ready(f_if.uart_rx_fifo_data_ready)
  );

  // ---- RX FIFO Auto-Reader ----
  // Continuously pulse read_data so the DUT FIFO outputs data whenever available.
  // The RX monitor passively watches data_ready to capture items.
  initial begin
    f_if.uart_rx_fifo_read_data = 1'b0;
    @(posedge PRESETn);           // wait for reset release
    repeat(10) @(posedge PCLK);   // small settling delay
    forever begin
      @(posedge PCLK);
      f_if.uart_rx_fifo_read_data = 1'b1;
      @(posedge PCLK);
      f_if.uart_rx_fifo_read_data = 1'b0;
      repeat(3) @(posedge PCLK);  // gap between reads
    end
  end

  // UVM Config and Test Start
  initial begin
    string test_name;
    uvm_root r;

    // Set virtual interfaces in config_db
    uvm_config_db#(virtual uart_if)::set(null, "*", "uart_vif", u_if);
    uvm_config_db#(virtual uart_if.tx_monitor)::set(null, "*", "uart_vif_tx_mon", u_if.tx_monitor);
    uvm_config_db#(virtual uart_if.rx_monitor)::set(null, "*", "uart_vif_rx_mon", u_if.rx_monitor);
    uvm_config_db#(virtual uart_fifo_if.tx_driver)::set(null, "*", "fifo_vif_tx_drv", f_if.tx_driver);
    uvm_config_db#(virtual uart_fifo_if.tx_monitor)::set(null, "*", "fifo_vif_tx_mon", f_if.tx_monitor);
    uvm_config_db#(virtual uart_fifo_if.rx_monitor)::set(null, "*", "fifo_vif_rx_mon", f_if.rx_monitor);
    uvm_config_db#(virtual uart_if.rx_driver)::set(null, "*", "uart_vif_rx_drv", u_if.rx_driver);
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", a_if);
    uvm_config_db#(virtual intr_if)::set(null, "*", "intr_vif", i_if);

    // Get test name from command line
    if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) begin
      test_name = "uart_base_test";
    end
    
    r = uvm_root::get();
    r.finish_on_completion = 0;
    run_test(test_name);
  end

  // Trace Dumping
  initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0, tb_top);
  end

  // Safety Timeout
  initial begin
    #500000000; // 5ms timeout
    $display("[%0t] tb_top: FATAL - Simulation timeout reached!", $time);
    $finish;
  end

endmodule
