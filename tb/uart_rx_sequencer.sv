`ifndef UART_RX_SEQUENCER_SV
`define UART_RX_SEQUENCER_SV

// =============================================================================
// UART RX Sequencer
// Standard sequencer for RX serial drive transactions.
// =============================================================================
class uart_rx_sequencer extends uvm_sequencer #(uart_seq_item);

  `uvm_component_utils(uart_rx_sequencer)

  function new(string name = "uart_rx_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : uart_rx_sequencer

`endif // UART_RX_SEQUENCER_SV
