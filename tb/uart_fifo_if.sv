// =============================================================================
// UART FIFO Control Interface
// Contains TX FIFO write signals, RX FIFO read signals, configuration inputs,
// enable signals, and error/status outputs.
// =============================================================================
interface uart_fifo_if(input logic clk, input logic reset_n);

  // ---- Configuration inputs (driven by testbench) ----
  logic        uart_rx_en;
  logic        uart_tx_en;
  logic [4:0]  uart_sm;              // Baud rate selector
  logic        parity_en;
  logic        parity_odd_even;
  logic [1:0]  packet_width;         // 2'b00=5bit .. 2'b11=8bit
  logic [1:0]  stop_bit_count;

  // ---- TX FIFO write interface (driven by TX driver) ----
  logic        uart_tx_fifo_write;
  logic [7:0]  uart_tx_fifo_write_data;

  // ---- TX FIFO status (from DUT) ----
  logic        uart_tx_fifo_full;
  logic        uart_tx_fifo_write_error;

  // ---- RX FIFO read interface (driven by RX monitor) ----
  logic        uart_rx_fifo_read_data;

  // ---- RX FIFO status (from DUT) ----
  logic [7:0]  uart_rx_fifo_data_out;
  logic        uart_rx_fifo_data_ready;
  logic        uart_rx_fifo_full;
  logic        uart_rx_fifo_empty;
  logic        uart_rx_fifo_write_error;
  logic        uart_rx_fifo_read_error;

  // ---- RX error flags (from DUT) ----
  logic        uart_rx_parity_error;
  logic        uart_rx_frame_error;

  // -------------------------------------------------------------------------
  // Modports
  // -------------------------------------------------------------------------
  // -------------------------------------------------------------------------
  // Clocking block for TX driver (writes into TX FIFO)
  // -------------------------------------------------------------------------
  clocking tx_drv_cb @(posedge clk);
    default input #1 output #1;
    output uart_tx_fifo_write;
    output uart_tx_fifo_write_data;
    input  uart_tx_fifo_full;
    input  uart_tx_fifo_write_error;
  endclocking

  // -------------------------------------------------------------------------
  // Clocking block for RX monitor (reads from RX FIFO)
  // -------------------------------------------------------------------------
  clocking rx_mon_cb @(posedge clk);
    default input #1 output #1;
    input  uart_rx_fifo_data_out;
    input  uart_rx_fifo_data_ready;
    input  uart_rx_fifo_full;
    input  uart_rx_fifo_empty;
    input  uart_rx_fifo_write_error;
    input  uart_rx_fifo_read_error;
    input  uart_rx_parity_error;
    input  uart_rx_frame_error;
  endclocking

  // -------------------------------------------------------------------------
  // Clocking block for TX input monitor (snoops TX FIFO writes)
  // -------------------------------------------------------------------------
  clocking tx_mon_cb @(posedge clk);
    default input #1 output #1;
    input  uart_tx_fifo_write;
    input  uart_tx_fifo_write_data;
    input  uart_tx_fifo_full;
  endclocking

  // -------------------------------------------------------------------------
  // Modports
  // -------------------------------------------------------------------------
  modport tx_driver  (clocking tx_drv_cb, input clk, input reset_n);
  modport rx_monitor (clocking rx_mon_cb, input clk, input reset_n);
  modport tx_monitor (clocking tx_mon_cb, input clk, input reset_n);

endinterface : uart_fifo_if

