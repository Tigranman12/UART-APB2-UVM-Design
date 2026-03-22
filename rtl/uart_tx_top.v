module uart_tx_top(
	clk,
	reset_n,
	uart_sm,
	uart_tx,
	uart_tx_en,
	packet_width,
	parity_en,
	parity_odd_even,
	stop_bit_count,
	uart_tx_fifo_full,
	uart_tx_fifo_write,
	uart_tx_fifo_write_data,
	uart_tx_fifo_write_error
);

input clk;
input reset_n;
input parity_en;
input parity_odd_even;
input uart_tx_fifo_write;
input [1:0] packet_width;
input [1:0] stop_bit_count;
input [7:0] uart_tx_fifo_write_data;
input [4:0] uart_sm;
input uart_tx_en;

output uart_tx;
output uart_tx_fifo_full;
output uart_tx_fifo_write_error;

wire uart_tx_clk_gen_en;
wire uart_tx_clk;
wire uart_tx_fifo_empty;
wire uart_tx_fifo_read;
wire uart_tx_fifo_data_ready;
wire [7:0] uart_tx_data;

uart_tx_fsm U_uart_tx_fsm(
	.clk(clk),
	.reset_n(reset_n),
	.uart_tx_clk_gen_en(uart_tx_clk_gen_en),
	.uart_tx_clk(uart_tx_clk),
	.uart_tx_data(uart_tx_data),
	.uart_tx(uart_tx),
	.uart_tx_en(uart_tx_en),
	.uart_tx_fifo_empty(uart_tx_fifo_empty),
	.uart_tx_fifo_read(uart_tx_fifo_read),
	.uart_tx_fifo_data_ready(uart_tx_fifo_data_ready),
	.packet_width(packet_width),
	.parity_en(parity_en),
	.parity_odd_even(parity_odd_even),
	.stop_bit_count(stop_bit_count)
);

uart_tx_fifo U_uart_tx_fifo(
	.clk(clk),
	.reset_n(reset_n),
	.write_data(uart_tx_fifo_write),
	.read_data(uart_tx_fifo_read),
	.data_in(uart_tx_fifo_write_data),
	.data_out(uart_tx_data),
	.data_ready(uart_tx_fifo_data_ready),
	.full(uart_tx_fifo_full),
	.empty(uart_tx_fifo_empty),
	.write_error(uart_tx_fifo_write_error),
	.read_error()
);

uart_tx_clk_gen U_uart_tx_clk_gen(
	.clk(clk),
	.reset_n(reset_n),
	.uart_tx_clk_gen_en(uart_tx_clk_gen_en),
	.uart_tx_clk(uart_tx_clk),
	.uart_sm(uart_sm)
);

endmodule
