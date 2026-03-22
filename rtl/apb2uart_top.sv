module apb2uart_top #(
	parameter ADDR_WIDTH = 8 ,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 64
)(
	input                      PCLK                        ,
	input                      PRESETn                     ,
	input                      PSEL                        ,
	input                      PENABLE                     ,
	input                      PWRITE                      ,
	input  [ADDR_WIDTH-1:0]    PADDR                       ,
	input  [DATA_WIDTH-1:0]    PWDATA                      ,
	output [DATA_WIDTH-1:0]    PRDATA                      ,
	output reg                 PREADY                      ,
	output                     interrupt                   ,
    input                      uart_rx                     ,
    input                      uart_tx_fifo_write          ,
    input  [7:0]               uart_tx_fifo_write_data     ,
    input                      uart_rx_fifo_read_data      ,
    output                     uart_tx                     ,
    output [7:0]               uart_rx_fifo_data_out       ,
    output                     uart_rx_fifo_data_ready 
);

	logic [7:0]                wreg_config_0x0000          ;
	logic [7:0]                wreg_config_0x0001          ;
	logic [7:0]                wreg_status_0x0002          ;
	logic [7:0]                wreg_status_0x0003          ;
	logic                      wuart_rx_parity_error       ;
	logic                      wuart_rx_frame_error        ;
	logic                      wuart_tx_fifo_write_error   ;
	logic                      wuart_rx_fifo_write_error   ;
	logic                      wuart_rx_fifo_read_error    ;
	logic                      wuart_tx_fifo_full          ;
	logic                      wuart_rx_fifo_full          ;
	logic                      wuart_rx_fifo_empty         ;
	logic                      wuart_rx_en                 ;
	logic                      wuart_tx_en                 ;
	logic [4:0]                wuart_sm                    ;
	logic                      wparity_en                  ;
	logic                      wparity_odd_even            ;
	logic [1:0]                wpacket_width               ;
	logic [1:0]                wstop_bit_count             ;

	assign wreg_status_0x0002 = {wuart_rx_parity_error     , 
								 wuart_rx_frame_error      ,
								 wuart_tx_fifo_write_error ,
								 wuart_rx_fifo_write_error ,
								 wuart_rx_fifo_read_error  };
								 
	assign wreg_status_0x0003 = {wuart_tx_fifo_full        ,
								 wuart_rx_fifo_full        ,
								 wuart_rx_fifo_empty       };
								 
								 
	assign {wuart_rx_en,
		    wuart_tx_en,
		    wuart_sm,
		    wparity_en}       = wreg_config_0x0000         ;
		   
	assign {wparity_odd_even,
		    wpacket_width,
		    wstop_bit_count}  = wreg_config_0x0001         ;

	regbank #( 
	.ADDR_WIDTH (ADDR_WIDTH),
	.DATA_WIDTH (DATA_WIDTH),
	.NUM_REGS   (NUM_REGS  )
	)
	u_regbank (
		.PCLK                       (PCLK                      ),
	    .PRESETn                    (PRESETn                   ),
	    .PSEL                       (PSEL                      ),
	    .PENABLE                    (PENABLE                   ),
	    .PWRITE                     (PWRITE                    ),
	    .PADDR                      (PADDR                     ),
	    .PWDATA                     (PWDATA                    ),
	    .reg_status_0x0002          (wreg_status_0x0002        ),
	    .reg_status_0x0003          (wreg_status_0x0003        ),
	    .PRDATA                     (PRDATA                    ),
	    .PREADY                     (PREADY                    ),
	    .reg_config_0x0000          (wreg_config_0x0000        ),
	    .reg_config_0x0001          (wreg_config_0x0001        ),
	    .interrupt                  (interrupt                 )
	);
	
	uart_top  u_uart_top(
		.clk                        (PCLK                      ),
		.reset_n                    (PRESETn                   ),
		.uart_rx                    (uart_rx                   ),
		.uart_rx_parity_error       (wuart_rx_parity_error     ),
		.uart_rx_frame_error        (wuart_rx_frame_error      ),
		.uart_rx_en                 (wuart_rx_en               ),
		.uart_tx_en                 (wuart_tx_en               ),
		.uart_tx                    (uart_tx                   ),
		.uart_sm                    (wuart_sm                  ),
		.parity_en                  (wparity_en                ),
		.parity_odd_even            (wparity_odd_even          ),
		.packet_width               (wpacket_width             ),
		.stop_bit_count             (wstop_bit_count           ),
		.uart_tx_fifo_full          (wuart_tx_fifo_full        ),
		.uart_tx_fifo_write         (uart_tx_fifo_write        ),
		.uart_tx_fifo_write_data    (uart_tx_fifo_write_data   ),
		.uart_tx_fifo_write_error   (wuart_tx_fifo_write_error ),
		.uart_rx_fifo_read_data     (uart_rx_fifo_read_data    ),
		.uart_rx_fifo_data_out      (uart_rx_fifo_data_out     ),
		.uart_rx_fifo_data_ready    (uart_rx_fifo_data_ready   ),
		.uart_rx_fifo_full          (wuart_rx_fifo_full        ),
		.uart_rx_fifo_empty         (wuart_rx_fifo_empty       ),
		.uart_rx_fifo_write_error   (wuart_rx_fifo_write_error ),
		.uart_rx_fifo_read_error    (wuart_rx_fifo_read_error  )
	);
	
endmodule 