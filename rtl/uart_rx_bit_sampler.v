module uart_rx_bit_sampler(
	clk,
	bit_ready,
	sampled_bit,
	bit_sampling_en,
	uart_rx_clk,
	uart_rx,
	stop_bit_ready,
	reset_n
);

input uart_rx;
input bit_sampling_en;
input uart_rx_clk;
input clk;
input reset_n;
output sampled_bit;
output reg bit_ready;
output reg stop_bit_ready;

reg [2:0]sampled_bits;
reg [3:0]count;



always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin 
  		count <= 4'd0;
		stop_bit_ready <= 1'b0;
		bit_ready <= 1'b0; 
		sampled_bits <= 3'd0;
		stop_bit_ready <= 1'b0;
  end 
  else begin
	if (bit_sampling_en) begin
		if (uart_rx_clk) begin
			if (count == 4'd9) begin
				count <= 4'd0;
				bit_ready <= 1'b1;
			end
			else begin 
				count <= count + 1'b1;
				bit_ready <= 1'b0;
			end
			
			if (count == 4'd3 || count == 4'd4 || count == 4'd5) begin
				sampled_bits <= {{uart_rx},{sampled_bits[2:1]}};
			end
			if (count == 4'd7) begin
				stop_bit_ready <= 1'b1;
			end
			else begin 
				stop_bit_ready <= 1'b0;
			end
		end
		else begin
			bit_ready <= 1'b0;
		end
	end	
	else begin
		count <= 4'd0;
		stop_bit_ready <= 1'b0;
		bit_ready <= 1'b0;
	end
  end	
end 

assign sampled_bit = (sampled_bits[2]) ? (sampled_bits[1] | sampled_bits[0]) : 
													  (sampled_bits[1] & sampled_bits[0]) ;
													  
endmodule
