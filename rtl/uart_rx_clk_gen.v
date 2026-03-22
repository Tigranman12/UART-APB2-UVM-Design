module uart_rx_clk_gen(
	clk,
	reset_n,
	uart_rx_clk_gen_en,
	uart_rx_clk,
	uart_sm
);

input clk;
input reset_n;
input uart_rx_clk_gen_en;
input [4:0] uart_sm;
reg [15:0] count_top;
output reg uart_rx_clk;
reg [15:0] count;

always @(posedge clk or negedge reset_n) begin
   if (!reset_n) begin
      uart_rx_clk <= 1'b0;
      count <= 16'd0;
   end
	else begin
		if (uart_rx_clk_gen_en) begin
			if (count == count_top - 1'b1) begin
				count <= 16'd0;
				uart_rx_clk <= 1'b1;
			end
			else begin
				count <= count + 1'b1;
				uart_rx_clk <= 1'b0;
			end
		end
		else begin
			uart_rx_clk <= 1'b0;
			count <= 16'd0;
		end
	end
end

always @* begin
	case (uart_sm)
		5'd0: count_top = 16'd33333; // 300    baud (err 0.001%)
		5'd1: count_top = 16'd16667; // 600    baud (err 0.002%)
		5'd2: count_top = 16'd8333;  // 1200   baud (err 0.004%)
		5'd3: count_top = 16'd5556;  // 1800   baud (err 0.008%)
		5'd4: count_top = 16'd4167;  // 2400   baud (err 0.008%)
		5'd5: count_top = 16'd2083;  // 4800   baud (err 0.016%)
		5'd6: count_top = 16'd1389;  // 7200   baud (err 0.006%)
		5'd7: count_top = 16'd1042;  // 9600   baud (err 0.032%)
		5'd8: count_top = 16'd694;   // 14400  baud (err 0.064%)
		5'd9: count_top = 16'd521;   // 19200  baud (err 0.031%)
		5'd10: count_top = 16'd347;  // 28800  baud (err 0.064%)
		5'd11: count_top = 16'd260;  // 38400  baud (err 0.160%)
		5'd12: count_top = 16'd174;  // 57600  baud (err 0.220%)
		5'd13: count_top = 16'd130;  // 76800  baud (err 0.160%)
		5'd14: count_top = 16'd87;   // 115200 baud (err 0.220%)
		5'd15: count_top = 16'd78;   // 128000 baud (err 0.160%)
		5'd16: count_top = 16'd43;   // 230400 baud (err 0.930%)
		5'd17: count_top = 16'd40;   // 250000 baud (err 0.000%)
		5'd18: count_top = 16'd20;   // 500000 baud (err 0.000%)
		5'd19: count_top = 16'd10;   // 1000000 baud (err 0.000%)
		default: count_top = 16'd1042;
	endcase
end

endmodule
