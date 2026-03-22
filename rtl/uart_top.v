module uart_top(
	clk,
	reset_n,
	uart_rx,
	uart_rx_parity_error,
	uart_rx_frame_error,
	uart_rx_en,
	uart_tx_en,
	uart_tx,
	uart_sm,
	parity_en,
	parity_odd_even,
	packet_width,
	stop_bit_count,
	uart_tx_fifo_full,
	uart_tx_fifo_write,
	uart_tx_fifo_write_data,
	uart_tx_fifo_write_error,
	uart_rx_fifo_read_data,
	uart_rx_fifo_data_out,
	uart_rx_fifo_data_ready,
	uart_rx_fifo_full,
	uart_rx_fifo_empty,
	uart_rx_fifo_write_error,
	uart_rx_fifo_read_error
);

input clk;
input reset_n;
input uart_rx;
input uart_rx_en;
input uart_tx_en;
input [4:0] uart_sm;
input parity_en;
input parity_odd_even;
input [1:0] packet_width; 
input [1:0] stop_bit_count;
input uart_tx_fifo_write;
input [7:0] uart_tx_fifo_write_data;
input uart_rx_fifo_read_data;


output uart_rx_parity_error;
output uart_rx_frame_error;
output uart_tx;
output uart_tx_fifo_full;
output uart_tx_fifo_write_error;
output [7:0]uart_rx_fifo_data_out;
output uart_rx_fifo_data_ready;
output uart_rx_fifo_full;
output uart_rx_fifo_empty;
output uart_rx_fifo_write_error;
output uart_rx_fifo_read_error;

uart_rx_top U_uart_rx_top(
	.uart_rx(uart_rx),
	.uart_rx_en(uart_rx_en),
	.parity_error(uart_rx_parity_error),
	.frame_error(uart_rx_frame_error),
	.uart_sm(uart_sm), 
	.clk(clk), 
	.reset_n(reset_n),
	.parity_en(parity_en), 
	.parity_odd_even(parity_odd_even),
	.packet_width(packet_width),
	.uart_rx_fifo_read_data(uart_rx_fifo_read_data),
	.uart_rx_fifo_data_out(uart_rx_fifo_data_out),
	.uart_rx_fifo_data_ready(uart_rx_fifo_data_ready),
	.uart_rx_fifo_full(uart_rx_fifo_full),
	.uart_rx_fifo_empty(uart_rx_fifo_empty),
	.uart_rx_fifo_write_error(uart_rx_fifo_write_error),
	.uart_rx_fifo_read_error(uart_rx_fifo_read_error)
);


uart_tx_top U_uart_tx_top(
	.clk(clk),
	.reset_n(reset_n),
	.uart_sm(uart_sm),
	.uart_tx(uart_tx),
	.uart_tx_en(uart_tx_en),
	.packet_width(packet_width),
	.parity_en(parity_en),
	.parity_odd_even(parity_odd_even),
	.stop_bit_count(stop_bit_count),
	.uart_tx_fifo_full(uart_tx_fifo_full),
	.uart_tx_fifo_write(uart_tx_fifo_write),
	.uart_tx_fifo_write_data(uart_tx_fifo_write_data),
	.uart_tx_fifo_write_error(uart_tx_fifo_write_error)
);

endmodule
