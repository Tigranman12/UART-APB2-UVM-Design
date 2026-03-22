module uart_rx_fsm(
	uart_data,
	uart_data_ready,
	clk,
	reset_n,
	bit_ready,
	sampled_bit,
	bit_sampling_en,
	parity_error,
	frame_error,
	parity_en,
	parity_odd_even,
	uart_rx_clk_gen_en,
	uart_rx_negedge,
	stop_bit_ready,
	packet_width,
	uart_rx_en
);

// inputs
input clk;
input reset_n;
input uart_rx_negedge;
input bit_ready;
input sampled_bit;
input stop_bit_ready;
// inputs from config registers
input parity_en; // 0 - parity check disabled; 1 - parity check enabled
input parity_odd_even; // 0 - even parity check; 1 - odd parity check
input [1:0] packet_width;
input uart_rx_en;

//fsm states parameters
parameter IDLE = 2'b00;
parameter START_BIT_CHECK = 2'b01;
parameter DATA_SAMPLING = 2'b11;
parameter STOP_BIT_CHECK = 2'b10;


//outputs
output reg uart_data_ready;
output reg [7:0] uart_data;
output reg parity_error;
output reg frame_error;
output reg bit_sampling_en;
output reg uart_rx_clk_gen_en;

//internal regs
reg [1:0] fsm_state;
reg [3:0] bit_count;
reg [8:0] temp_uart_data;
reg parity_bit;


//config regs
//reg flow_control; // 0 - disabled; 1 - XON/XOFF enable


//fsm description
always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		fsm_state <= IDLE;
		uart_data_ready <= 1'b0;
		uart_rx_clk_gen_en <= 1'b0;
		bit_sampling_en <= 1'b0;
		temp_uart_data <= 9'd0;
		bit_count <= 4'd0;
		frame_error <= 1'b0;
		parity_error <= 1'b0;		
		uart_data <= 8'd0;
		parity_bit <= 1'b0;
	end 
	else begin
		case (fsm_state) 
			IDLE: begin 
				bit_count <= 4'd0;
				temp_uart_data <= 9'd0;
				uart_data_ready <= 1'b0;
				bit_sampling_en <= 1'b0;
				uart_rx_clk_gen_en <= 1'b0;
				if (uart_rx_en && uart_rx_negedge) begin
					frame_error <= 1'b0;
					parity_error <= 1'b0;					
					if (parity_en) begin
						parity_bit <= parity_odd_even;
					end
					bit_sampling_en <= 1'b1;
					uart_rx_clk_gen_en <= 1'b1;
					fsm_state <= START_BIT_CHECK;
				end 
			end
			START_BIT_CHECK: begin 
				if (bit_ready) begin
					if(!sampled_bit) begin
						fsm_state <= DATA_SAMPLING;
					end else begin
						fsm_state <= IDLE;
					end
				end
			end
			DATA_SAMPLING: begin 
				if (bit_ready) begin
					temp_uart_data <= {{sampled_bit},{temp_uart_data[8:1]}};
					if (parity_en) begin
						parity_bit <= parity_bit ^ sampled_bit;
					end
					bit_count <= bit_count + 1'b1;
					if (bit_count == ({2'b01,{packet_width[1:0]}}+parity_en)) begin
						fsm_state <= STOP_BIT_CHECK;
					end
				end
			end
			STOP_BIT_CHECK: begin
				if (stop_bit_ready) begin
					if(!sampled_bit) begin // stop bit valid
						frame_error <= 1'b1;
					end
					if (parity_bit & parity_en) begin
						parity_error <= 1'b1;
					end
					if (parity_en) begin
						case (packet_width)
							2'b00: uart_data <= {3'b000,{temp_uart_data[7:3]}};
							2'b01: uart_data <= {2'b00,{temp_uart_data[7:2]}};
							2'b10: uart_data <= {1'b0,{temp_uart_data[7:1]}};
							2'b11: uart_data <= temp_uart_data[7:0];
						endcase
					end
					else begin
						case (packet_width) 
							2'b00: uart_data <= {3'b000,{temp_uart_data[8:4]}};
							2'b01: uart_data <= {2'b00,{temp_uart_data[8:3]}};
							2'b10: uart_data <= {1'b0,{temp_uart_data[8:2]}};							
							2'b11: uart_data <= temp_uart_data[8:1];
						endcase
					end
					uart_data_ready <= 1'b1;
					fsm_state <= IDLE;
				end
			end
		endcase
	end
end

endmodule
