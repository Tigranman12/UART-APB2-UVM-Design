`timescale 1ns/1ps
package apb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // --- APB Transaction ---
  class apb_transaction extends uvm_sequence_item;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        write;

    `uvm_object_utils_begin(apb_transaction)
      `uvm_field_int(addr,  UVM_ALL_ON)
      `uvm_field_int(data,  UVM_ALL_ON)
      `uvm_field_int(write, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_transaction");
      super.new(name);
    endfunction
  endclass

  // --- APB Sequencer ---
  typedef uvm_sequencer #(apb_transaction) apb_sequencer;

  // --- APB Driver ---
  class apb_driver extends uvm_driver #(apb_transaction);
    `uvm_component_utils(apb_driver)
    virtual apb_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_fatal("APB_DRV", "Could not get vif")
    endfunction

    virtual task run_phase(uvm_phase phase);
      `uvm_info("APB_DRV", "Starting APB Driver", UVM_LOW)
      vif.drv_cb.PSEL    <= 0;
      vif.drv_cb.PENABLE <= 0;
      
      // Wait for reset release
      wait(vif.PRESETn === 1'b1);
      
      forever begin
        seq_item_port.get_next_item(req);
        `uvm_info("APB_DRV", $sformatf("Driving trans: addr=0x%0h data=0x%0h write=%0b", req.addr, req.data, req.write), UVM_MEDIUM)
        drive_trans(req);
        seq_item_port.item_done();
      end
    endtask

    virtual task drive_trans(apb_transaction tr);
      @(vif.drv_cb);
      vif.drv_cb.PADDR   <= tr.addr;
      vif.drv_cb.PWRITE  <= tr.write;
      vif.drv_cb.PSEL    <= 1;
      if (tr.write) vif.drv_cb.PWDATA <= tr.data;
      @(vif.drv_cb);
      vif.drv_cb.PENABLE <= 1;
      while (!vif.drv_cb.PREADY) @(vif.drv_cb);
      if (!tr.write) tr.data = vif.drv_cb.PRDATA;
      @(vif.drv_cb);
      vif.drv_cb.PSEL    <= 0;
      vif.drv_cb.PENABLE <= 0;
    endtask
  endclass

  // --- APB Monitor ---
  class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)
    virtual apb_if vif;
    uvm_analysis_port #(apb_transaction) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_fatal("APB_MON", "Could not get vif")
    endfunction

    virtual task run_phase(uvm_phase phase);
      apb_transaction tr;
      forever begin
        @(vif.mon_cb);
        if (vif.mon_cb.PSEL && vif.mon_cb.PENABLE && vif.mon_cb.PREADY) begin
          tr = apb_transaction::type_id::create("tr");
          tr.addr  = vif.mon_cb.PADDR;
          tr.write = vif.mon_cb.PWRITE;
          if (tr.write) tr.data = vif.mon_cb.PWDATA;
          else          tr.data = vif.mon_cb.PRDATA;
          ap.write(tr);
          `uvm_info("APB_MON", $sformatf("Captured trans: addr=0x%0h data=0x%0h write=%0b", tr.addr, tr.data, tr.write), UVM_MEDIUM)
        end
      end
    endtask
  endclass

  // --- APB Agent ---
  class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    apb_driver    driver;
    apb_monitor   monitor;
    apb_sequencer sequencer;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = apb_monitor::type_id::create("monitor", this);
      if (get_is_active() == UVM_ACTIVE) begin
        driver    = apb_driver::type_id::create("driver", this);
        sequencer = apb_sequencer::type_id::create("sequencer", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (get_is_active() == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
      end
    endfunction
  endclass

endpackage
