interface apb_if #(parameter ADDR_WIDTH = 8, parameter DATA_WIDTH = 32) (input logic PCLK, input logic PRESETn);
  logic [ADDR_WIDTH-1:0] PADDR;
  logic                  PSEL;
  logic                  PENABLE;
  logic                  PWRITE;
  logic [DATA_WIDTH-1:0] PWDATA;
  logic [DATA_WIDTH-1:0] PRDATA;
  logic                  PREADY;

  clocking drv_cb @(posedge PCLK);
    default input #1 output #1;
    output PADDR, PSEL, PENABLE, PWRITE, PWDATA;
    input  PRDATA, PREADY;
  endclocking

  clocking mon_cb @(posedge PCLK);
    default input #1 output #1;
    input PADDR, PSEL, PENABLE, PWRITE, PWDATA, PRDATA, PREADY;
  endclocking

  modport driver (clocking drv_cb, input PCLK, input PRESETn);
  modport monitor (clocking mon_cb, input PCLK, input PRESETn);

endinterface : apb_if
