module uart_tx_fsm(
	clk,
	reset_n,
	uart_tx_clk_gen_en,
	uart_tx_clk,
	uart_tx_data,
	uart_tx,
	uart_tx_en,
	uart_tx_fifo_empty,
	uart_tx_fifo_read,
	uart_tx_fifo_data_ready,
	packet_width,
	parity_en,
	parity_odd_even,
	stop_bit_count
);

input clk;
input reset_n;
input uart_tx_fifo_empty;
input uart_tx_fifo_data_ready;
input uart_tx_clk;
input parity_en;
input parity_odd_even;
input [1:0] packet_width;
input [1:0] stop_bit_count;
input [7:0] uart_tx_data;
input uart_tx_en;

output reg uart_tx;
output reg uart_tx_fifo_read;
output reg uart_tx_clk_gen_en;

reg [1:0] fsm_state;
reg [8:0] uart_tx_temp_data;
reg [3:0] uart_tx_clk_count;
reg [3:0] uart_tx_bit_count;
reg uart_tx_bit_ready;
reg uart_tx_half_bit_ready;

parameter IDLE = 2'd0;
parameter START_BIT_SEND = 2'd1;
parameter DATA_SEND = 2'd2;
parameter STOP_BIT_SEND = 2'd3;

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		fsm_state <= IDLE;
		uart_tx <= 1'b1;
		uart_tx_fifo_read <= 1'b0;
		uart_tx_clk_gen_en <= 1'b0;
		uart_tx_temp_data <= 9'd0;
		uart_tx_bit_count <= 4'd0;
	end
	else begin
			case (fsm_state) 
				IDLE: begin
					uart_tx <= 1'b1;
					uart_tx_fifo_read <= 1'b0;
					uart_tx_clk_gen_en <= 1'b0;
					uart_tx_temp_data <= {parity_odd_even,8'd0};
					uart_tx_bit_count <= 4'd0;
					if (!uart_tx_fifo_empty && uart_tx_en) begin
						fsm_state <= START_BIT_SEND;
						uart_tx_fifo_read <= 1'b1;
					end
				end
				START_BIT_SEND: begin
					uart_tx_fifo_read <= 1'b0;
					if (uart_tx_fifo_data_ready) begin
						uart_tx_temp_data <= uart_tx_data;
						if (parity_en) begin
							uart_tx_temp_data[8] <= uart_tx_temp_data[8]^uart_tx_data[0]^uart_tx_data[1]^uart_tx_data[2]^uart_tx_data[3]^uart_tx_data[4]^uart_tx_data[5]^uart_tx_data[6]^uart_tx_data[7];
						end
						uart_tx_clk_gen_en <= 1'b1;
						uart_tx <= 1'b0; // start bit
						fsm_state <= DATA_SEND;
					end
				end
				DATA_SEND: begin
					if (uart_tx_bit_ready) begin
						uart_tx <= uart_tx_temp_data[0];
						uart_tx_temp_data <= {{1'b0},{uart_tx_temp_data[8:1]}};
						uart_tx_bit_count <= uart_tx_bit_count + 1'b1;
						if (uart_tx_bit_count == {2'b01,{packet_width[1:0]}} + 1'b1 + parity_en) begin
							fsm_state <= STOP_BIT_SEND;
							uart_tx <= 1'b1;//stop bit
							uart_tx_bit_count <= 4'd0; 
						end
					end
				end
				STOP_BIT_SEND: begin
					case (stop_bit_count) 
						2'b00: begin
							if (uart_tx_bit_ready) begin
								fsm_state <= IDLE;
							end
						end
						2'b01: begin
							if (uart_tx_bit_ready & !uart_tx_bit_count[0]) begin
								uart_tx_bit_count[0] <= 1'b1; 
							end
							else if (uart_tx_bit_count[0]) begin
								if(uart_tx_half_bit_ready) begin
									fsm_state <= IDLE;
								end
							end
						end
						2'b11: begin
							if (uart_tx_bit_ready & !uart_tx_bit_count[0]) begin
								uart_tx_bit_count[0] <= 1'b1; 
							end
							else if (uart_tx_bit_count[0]) begin
								if(uart_tx_bit_ready) begin
									fsm_state <= IDLE;
								end
							end
						end
						default: begin
							if (uart_tx_bit_ready) begin
								fsm_state <= IDLE;
							end
						end
					endcase
				end
			endcase
	end
end

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		uart_tx_clk_count <= 4'd0;
		uart_tx_bit_ready <= 1'b0;
		uart_tx_half_bit_ready <= 1'b0;
	end
	else if(uart_tx_clk_gen_en) begin 
		if (uart_tx_clk) begin
			if (uart_tx_clk_count == 4'd9) begin
				uart_tx_clk_count <= 4'd0;
				uart_tx_bit_ready <= 1'b1;
			end
			else if (uart_tx_clk_count == 4'd4) begin
				uart_tx_half_bit_ready <= 1'b1;
				uart_tx_clk_count <= uart_tx_clk_count + 1'b1;
			end
			else begin 
				uart_tx_clk_count <= uart_tx_clk_count + 1'b1;
				uart_tx_bit_ready <= 1'b0;
				uart_tx_half_bit_ready <= 1'b0;
			end
		end
		else begin
			uart_tx_bit_ready <= 1'b0;
			uart_tx_half_bit_ready <= 1'b0;
		end
	end
	else begin
		uart_tx_clk_count <= 4'd0;
	end
end

endmodule
 