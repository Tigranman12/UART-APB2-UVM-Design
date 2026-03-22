// =============================================================================
// UART Package
// Includes all UART and APB UVM components.
// =============================================================================
`timescale 1ns/1ps
package uart_pkg;
  import uvm_pkg::*;
  import apb_pkg::*;
  import uart_regs_uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "uart_seq_item.sv"
  `include "uart_config.sv"
  `include "uart_tx_sequencer.sv"
  `include "uart_rx_sequencer.sv"
  `include "uart_tx_driver.sv"
  `include "uart_rx_driver.sv"
  `include "uart_tx_monitor.sv"
  `include "uart_rx_monitor.sv"
  `include "uart_tx_input_monitor.sv"
  `include "uart_rx_input_monitor.sv"
  `include "uart_tx_agent.sv"
  `include "uart_rx_agent.sv"
  `include "uart_sequences.sv"
  `include "uart_reg_adapter.sv"
  `include "uart_scoreboard.sv"
  `include "uart_coverage.sv"
  `include "uart_env.sv"
  `include "uart_base_test.sv"
  `include "uart_full_coverage_test.sv"
  `include "uart_test_lib.sv"

endpackage : uart_pkg
