module uart_rx_top(
	uart_rx,
	parity_error,
	frame_error,
	uart_sm, // baude rate
	clk, 
	reset_n,
	parity_en, // 0 - parity check disabled; 1 - parity check enabled
	parity_odd_even,  // 0 - even parity check; 1 - odd parity check
	packet_width, // 2'b11 - 8bit; 2'b10 - 7bit; 2'b01 - 6bit; 2'b00 - 5bit; 
	uart_rx_en,
	uart_rx_fifo_read_data,
	uart_rx_fifo_data_out,
	uart_rx_fifo_data_ready,
	uart_rx_fifo_full,
	uart_rx_fifo_empty,
	uart_rx_fifo_write_error,
	uart_rx_fifo_read_error
);

input uart_rx;
input uart_rx_en;
input clk;
input reset_n;
input parity_en;
input parity_odd_even;
input [1:0] packet_width; 
input [4:0] uart_sm;
wire [7:0] uart_data;
wire uart_data_ready;
output parity_error;
output frame_error;
wire bit_ready;
wire sampled_bit;
wire bit_sampling_en;
wire uart_rx_clk_gen_en;
wire uart_rx_negedge;
wire uart_rx_clk;
wire stop_bit_ready;

wire		uart_rx_fifo_write_data; // uart_data_in
input		uart_rx_fifo_read_data; // input
wire		[7:0]uart_rx_fifo_data_in; // uart_data
output	[7:0]uart_rx_fifo_data_out; // output
output	uart_rx_fifo_data_ready; // output 
output	uart_rx_fifo_full; // flow control sent suspend symbol
output	uart_rx_fifo_empty; // output 
output	uart_rx_fifo_write_error; // data overrun
output	uart_rx_fifo_read_error; //output

assign 	uart_rx_fifo_data_in = uart_data;
assign 	uart_rx_fifo_write_data = uart_data_ready;


uart_rx_fsm U_uart_rx_fsm(
	.uart_data(uart_data),
	.uart_rx_en(uart_rx_en),
	.uart_data_ready(uart_data_ready),
	.clk(clk),
	.reset_n(reset_n),
	.bit_ready(bit_ready),
	.sampled_bit(sampled_bit),
	.bit_sampling_en(bit_sampling_en),
	.parity_error(parity_error),
	.frame_error(frame_error),
	.parity_en(parity_en),
	.parity_odd_even(parity_odd_even),
	.uart_rx_clk_gen_en(uart_rx_clk_gen_en),
	.uart_rx_negedge(uart_rx_negedge),
	.stop_bit_ready(stop_bit_ready),
	.packet_width(packet_width)
);

uart_rx_negedge_detect U_uart_rx_negedge_detect(
	.uart_rx(uart_rx),
	.clk(clk),
	.uart_rx_negedge(uart_rx_negedge),
	.reset_n(reset_n)
);

uart_rx_bit_sampler U_uart_rx_bit_sampler(
	.clk(clk),
	.bit_ready(bit_ready),
	.sampled_bit(sampled_bit),
	.bit_sampling_en(bit_sampling_en),
	.uart_rx_clk(uart_rx_clk),
	.uart_rx(uart_rx),
	.stop_bit_ready(stop_bit_ready),
	.reset_n(reset_n)
);

uart_rx_clk_gen U_uart_rx_clk_gen(
	.clk(clk),
	.reset_n(reset_n),
	.uart_rx_clk_gen_en(uart_rx_clk_gen_en),
	.uart_rx_clk(uart_rx_clk),
	.uart_sm(uart_sm)
);

uart_rx_fifo U_uart_rx_fifo(
	.clk(clk),
	.reset_n(reset_n),
	.write_data(uart_rx_fifo_write_data),
	.read_data(uart_rx_fifo_read_data),
	.data_in(uart_rx_fifo_data_in),
	.data_out(uart_rx_fifo_data_out),
	.data_ready(uart_rx_fifo_data_ready),
	.full(uart_rx_fifo_full),
	.empty(uart_rx_fifo_empty),
	.write_error(uart_rx_fifo_write_error),
	.read_error(uart_rx_fifo_read_error)
);


endmodule
