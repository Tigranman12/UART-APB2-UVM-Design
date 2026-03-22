module uart_rx_negedge_detect(
	uart_rx,
	clk,
	reset_n,
	uart_rx_negedge
);

input uart_rx;
input clk;
input reset_n;
output uart_rx_negedge;
wire uart_rx_negedge;
reg uart_rx_reg;
reg uart_rx_reg_1;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin 
		uart_rx_reg <=  1'b1;
		uart_rx_reg_1 <= 1'b1;
	end else begin
		uart_rx_reg <= uart_rx;
		uart_rx_reg_1 <= uart_rx_reg;
	end
end

assign uart_rx_negedge = ~uart_rx_reg && uart_rx_reg_1;

endmodule