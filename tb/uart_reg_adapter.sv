// =============================================================================
// UART Register Adapter
// Bridges between UVM RAL (uvm_reg_bus_op) and APB transactions
// =============================================================================
`ifndef UART_REG_ADAPTER_SV
`define UART_REG_ADAPTER_SV

class uart_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(uart_reg_adapter)

  function new(string name = "uart_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses = 0;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_pkg::apb_transaction tr = apb_pkg::apb_transaction::type_id::create("apb_tr");
    tr.addr = rw.addr;
    tr.write = (rw.kind == UVM_WRITE) ? 1 : 0;
    if (tr.write) begin
      tr.data = rw.data;
    end
    return tr;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_pkg::apb_transaction tr;
    if (!$cast(tr, bus_item)) begin
      `uvm_fatal("ADAPT", "Provided bus_item is not of type apb_transaction")
    end
    rw.kind = tr.write ? UVM_WRITE : UVM_READ;
    rw.addr = tr.addr;
    rw.data = tr.data;
    rw.status = UVM_IS_OK;
  endfunction
endclass

`endif
