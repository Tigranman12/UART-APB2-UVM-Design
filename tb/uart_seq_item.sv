`ifndef UART_SEQ_ITEM_SV
`define UART_SEQ_ITEM_SV

// =============================================================================
// UART Sequence Item (Transaction)
// Represents a single UART data transaction with direction awareness.
// =============================================================================

typedef enum bit { UART_DIR_TX = 0, UART_DIR_RX = 1 } direction_e;

class uart_seq_item extends uvm_sequence_item;

  `uvm_object_utils(uart_seq_item)

  // ---- Direction field ----
  direction_e direction;  // UART_DIR_TX or UART_DIR_RX

  // ---- Data field ----
  rand bit [7:0] data;


  // ---- Status fields (populated by monitors) ----
  bit        parity_error;
  bit        frame_error;
  bit        fifo_write_error;
  bit        fifo_read_error;

  // ---- Error Injection fields (driven by sequence) ----
  rand bit   inject_parity_error;
  rand bit   inject_frame_error;

  constraint c_no_errors_default { 
    soft inject_parity_error == 0;
    soft inject_frame_error  == 0;
  }

  // ---- Configuration snapshot (set by the sequence or driver) ----
  bit [1:0]  packet_width;    // to know how many bits are valid
  bit        parity_en;
  bit        parity_odd_even;

  // Constraint: mask upper bits based on packet_width
  constraint c_data_width {
    (packet_width == 2'b00) -> data[7:5] == 3'b0;  // 5-bit
    (packet_width == 2'b01) -> data[7:6] == 2'b0;  // 6-bit
    (packet_width == 2'b10) -> data[7]   == 1'b0;  // 7-bit
    // 2'b11 = 8-bit, no constraint
  }

  function new(string name = "uart_seq_item");
    super.new(name);
    direction = UART_DIR_TX;
  endfunction

  function string convert2string();
    return $sformatf("dir=%s data=0x%02h parity_err=%0b frame_err=%0b fifo_wr_err=%0b fifo_rd_err=%0b",
                     direction.name(), data, parity_error, frame_error, fifo_write_error, fifo_read_error);
  endfunction

  function void do_copy(uvm_object rhs);
    uart_seq_item rhs_item;
    super.do_copy(rhs);
    $cast(rhs_item, rhs);
    this.direction           = rhs_item.direction;
    this.data                = rhs_item.data;
    this.parity_error        = rhs_item.parity_error;
    this.frame_error         = rhs_item.frame_error;
    this.fifo_write_error    = rhs_item.fifo_write_error;
    this.fifo_read_error     = rhs_item.fifo_read_error;
    this.packet_width        = rhs_item.packet_width;
    this.parity_en           = rhs_item.parity_en;
    this.parity_odd_even     = rhs_item.parity_odd_even;
    this.inject_parity_error = rhs_item.inject_parity_error;
    this.inject_frame_error  = rhs_item.inject_frame_error;
  endfunction

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    uart_seq_item rhs_item;
    bit result;
    result = super.do_compare(rhs, comparer);
    $cast(rhs_item, rhs);
    result &= (this.direction == rhs_item.direction);
    result &= (this.data == rhs_item.data);
    return result;
  endfunction

endclass : uart_seq_item

`endif // UART_SEQ_ITEM_SV
