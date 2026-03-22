module uart_rx_fifo(
	clk,
	reset_n,
	write_data,
	read_data,
	data_in,
	data_out,
	data_ready,
	full,
	empty,
	write_error,
	read_error
);

input clk;
input reset_n;
input write_data;
input read_data;
input [7:0] data_in;

output reg full;
output reg empty;
output reg [7:0] data_out;
output reg data_ready;
output reg write_error;
output reg read_error;

reg [7:0] fifo_mem [0:7];
reg [2:0] write_address;
reg [2:0] read_address;
reg [3:0] data_count;
reg full_internal;
reg empty_internal;


always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		write_address <= 3'd0;
		read_address <= 3'd0;
		data_count <= 4'd0;
		data_ready <= 1'b0;
		write_error <= 1'b0;
		read_error <= 1'b0;
		data_out <= 8'd0;
	end
	else begin
		if (write_data && full_internal) begin
			write_error <= 1'b1;
			if (read_data) begin
				read_address <= read_address + 1'b1;
				data_out <= fifo_mem [read_address];
				data_count <= data_count - 1'b1;
				read_error <= 1'b0;
				data_ready <= 1'b1;
			end
		end
		else if (write_data && !full_internal && !read_data) begin
			write_address <= write_address + 1'b1;
			fifo_mem [write_address] <= data_in;
			data_count <= data_count + 1'b1;
			write_error <= 1'b0;
		end
		if (read_data && empty_internal) begin
			read_error <= 1'b1;
			if (write_data) begin
				write_address <= write_address + 1'b1;
				fifo_mem [write_address] <= data_in;
				data_count <= data_count + 1'b1;
				write_error <= 1'b0;
			end
		end
		else if (read_data && !empty_internal && !write_data) begin
			read_address <= read_address + 1'b1;
			data_out <= fifo_mem [read_address];
			data_count <= data_count - 1'b1;
			read_error <= 1'b0;
			data_ready <= 1'b1;
		end
		if (read_data && write_data && !full_internal && !empty_internal) begin
			write_address <= write_address + 1'b1;
			fifo_mem [write_address] <= data_in;
			read_address <= read_address + 1'b1;
			data_out <= fifo_mem [read_address];
			read_error <= 1'b0;
			write_error <= 1'b0;
			data_ready <= 1'b1;
		end
		if (!read_data) begin
			data_ready <= 1'b0;
		end
	end
end

always @* begin
	if (data_count == 4'd8) begin
		full_internal = 1'b1;
	end
	else begin
		full_internal = 1'b0;
	end
	if (data_count == 4'd0) begin
		empty_internal = 1'b1;
	end
	else begin
		empty_internal = 1'b0;
	end
	if (data_count == 4'd8 || (data_count == 4'd7 && write_data)) begin
      full = 1'b1;
	end
	else begin
      full = 1'b0;
	end
	if (data_count == 4'd0 || (data_count == 4'd1 && read_data)) begin
      empty = 1'b1;
	end
	else begin
      empty = 1'b0;
	end
end



endmodule
