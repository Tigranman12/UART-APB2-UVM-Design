// =============================================================================
// Interrupt Interface
// Simple interface to monitor the DUT interrupt line
// =============================================================================
`ifndef INTR_IF_SV
`define INTR_IF_SV

interface intr_if(input logic clk, input logic reset_n);
  logic interrupt;
endinterface

`endif
