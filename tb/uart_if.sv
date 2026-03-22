// =============================================================================
// UART Serial Interface
// Contains the UART serial lines (rx, tx) for connecting agents to the DUT.
// =============================================================================
interface uart_if(input logic clk, input logic reset_n);

  logic uart_rx = 1'b1;   // Serial data input to DUT (driven by RX driver), init to idle
  logic uart_tx;           // Serial data output from DUT (monitored by TX monitor)

  // -------------------------------------------------------------------------
  // Modports
  // -------------------------------------------------------------------------
  modport tx_monitor (input clk, input reset_n, input uart_tx);
  modport rx_driver  (input clk, input reset_n, output uart_rx);
  modport rx_monitor (input clk, input reset_n, input uart_rx);

endinterface : uart_if
