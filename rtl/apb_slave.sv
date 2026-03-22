module regbank #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 64
    )(
        input                      PCLK              ,
        input                      PRESETn           ,
        input                      PSEL              ,
        input                      PENABLE           ,
        input                      PWRITE            ,
        input  [ADDR_WIDTH-1:0]    PADDR             ,
        input  [DATA_WIDTH-1:0]    PWDATA            ,
		input      [7:0]           reg_status_0x0002 ,  
		input      [7:0]           reg_status_0x0003 ,  
        output [DATA_WIDTH-1:0]    PRDATA            ,
        output reg                 PREADY            ,
		output reg [7:0]           reg_config_0x0000 ,
		output reg [7:0]           reg_config_0x0001 ,
		output                     interrupt      
	);
    
    reg [ADDR_WIDTH-1:0]  reg_addr          ;
    reg [DATA_WIDTH-1:0]  mem [NUM_REGS-1:0];
	integer i;
	
	assign reg_config_0x0000 = mem[0]             ;
	assign reg_config_0x0001 = mem[1]             ;
	assign interrupt         = |reg_status_0x0002 ;
    assign PRDATA            = mem[reg_addr]      ;
	
    always @(posedge PCLK, negedge PRESETn)
		begin 
			if (!PRESETn)
				begin 
					for (i= 0; i < NUM_REGS; i++)
						begin 
							mem[i] <= 8'd0;
						end 
					PREADY = 0;
				end 
			else
				mem[2]           = reg_status_0x0002;
				mem[3]           = reg_status_0x0003;
				if(PSEL && !PENABLE && !PWRITE)
					PREADY = 0; 
				else if(PSEL && PENABLE && !PWRITE)
					begin  	
						PREADY   = 1     ;
						reg_addr =  PADDR; 
					end
				else if(PSEL && !PENABLE && PWRITE)
					PREADY = 0;
				else if(PSEL && PENABLE && PWRITE)
					begin  
						PREADY     = 1     ;
						mem[PADDR] = PWDATA;
					end
				else 
					PREADY = 0;
				end
    endmodule