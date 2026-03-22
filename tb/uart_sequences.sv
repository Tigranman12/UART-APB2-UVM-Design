`ifndef UART_SEQUENCES_SV
`define UART_SEQUENCES_SV

// =============================================================================
// UART Sequence Library
// Contains all sequences used to generate stimulus for UART verification.
// =============================================================================

// =============================================================================
// Base TX Sequence — Sends N random transactions into the TX FIFO
// =============================================================================
class uart_tx_base_sequence extends uvm_sequence #(uart_seq_item);

  `uvm_object_utils(uart_tx_base_sequence)

  uart_config cfg;
  int num_transactions = 10;

  function new(string name = "uart_tx_base_sequence");
    super.new(name);
  endfunction

  task pre_body();
    if (!uvm_config_db#(uart_config)::get(null, get_full_name(), "uart_cfg", cfg))
      if (!uvm_config_db#(uart_config)::get(null, "", "uart_cfg", cfg))
        `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
    num_transactions = cfg.num_transactions;
  endtask

  task body();
    uart_seq_item item;
    `uvm_info("TX_SEQ", $sformatf("Starting TX sequence with %0d items", num_transactions), UVM_MEDIUM)
    for (int i = 0; i < num_transactions; i++) begin
      item = uart_seq_item::type_id::create($sformatf("tx_item_%0d", i));
      item.packet_width = cfg.packet_width;
      start_item(item);
      if (!item.randomize()) begin
        `uvm_warning("RANDFAIL", "Failed to randomize TX seq_item, using manual $urandom")
        item.data = $urandom;
        // Apply packet width mask manually
        if (cfg.packet_width == 2'b00) item.data[7:5] = 3'b0;
        else if (cfg.packet_width == 2'b01) item.data[7:6] = 2'b0;
        else if (cfg.packet_width == 2'b10) item.data[7] = 1'b0;
      end
      finish_item(item);
    end
    `uvm_info("TX_SEQ", "TX sequence complete", UVM_MEDIUM)
  endtask

endclass : uart_tx_base_sequence


// =============================================================================
// Base RX Sequence — Drives N random frames on uart_rx serial line
// =============================================================================
class uart_rx_base_sequence extends uvm_sequence #(uart_seq_item);

  `uvm_object_utils(uart_rx_base_sequence)

  uart_config cfg;
  int num_transactions = 10;

  function new(string name = "uart_rx_base_sequence");
    super.new(name);
  endfunction

  task pre_body();
    if (!uvm_config_db#(uart_config)::get(null, get_full_name(), "uart_cfg", cfg))
      if (!uvm_config_db#(uart_config)::get(null, "", "uart_cfg", cfg))
        `uvm_fatal("NOCFG", "Could not get uart_config from config_db")
    num_transactions = cfg.num_transactions;
  endtask

  task body();
    uart_seq_item item;
    `uvm_info("RX_SEQ", $sformatf("Starting RX sequence with %0d items", num_transactions), UVM_MEDIUM)
    for (int i = 0; i < num_transactions; i++) begin
      item = uart_seq_item::type_id::create($sformatf("rx_item_%0d", i));
      item.packet_width = cfg.packet_width;
      start_item(item);
      if (!item.randomize()) begin
        `uvm_warning("RANDFAIL", "Failed to randomize RX seq_item, using manual $urandom")
        item.data = $urandom;
        if (cfg.packet_width == 2'b00) item.data[7:5] = 3'b0;
        else if (cfg.packet_width == 2'b01) item.data[7:6] = 2'b0;
        else if (cfg.packet_width == 2'b10) item.data[7] = 1'b0;
      end
      finish_item(item);
    end
    `uvm_info("RX_SEQ", "RX sequence complete", UVM_MEDIUM)
  endtask

endclass : uart_rx_base_sequence


// =============================================================================
// Specific Data Sequence — Sends known data values for easy debugging
// =============================================================================
class uart_known_data_sequence extends uvm_sequence #(uart_seq_item);

  `uvm_object_utils(uart_known_data_sequence)

  bit [7:0] data_queue[$];

  function new(string name = "uart_known_data_sequence");
    super.new(name);
  endfunction

  task body();
    uart_seq_item item;
    foreach (data_queue[i]) begin
      item = uart_seq_item::type_id::create($sformatf("known_item_%0d", i));
      start_item(item);
      item.data = data_queue[i];
      finish_item(item);
    end
  endtask

endclass : uart_known_data_sequence


// =============================================================================
// FIFO Overflow Sequence — Rapidly writes more than 8 items to overflow TX FIFO
// =============================================================================
class uart_fifo_overflow_sequence extends uvm_sequence #(uart_seq_item);

  `uvm_object_utils(uart_fifo_overflow_sequence)

  function new(string name = "uart_fifo_overflow_sequence");
    super.new(name);
  endfunction

  task body();
    uart_seq_item item;
    `uvm_info("FIFO_OVF", "Starting FIFO overflow sequence (12 rapid writes)", UVM_MEDIUM)
    for (int i = 0; i < 12; i++) begin
      item = uart_seq_item::type_id::create($sformatf("ovf_item_%0d", i));
      start_item(item);
      item.data = i[7:0];
      finish_item(item);
    end
  endtask

endclass : uart_fifo_overflow_sequence
// =============================================================================
// APB Configuration Sequence — Sets up DUT registers
// =============================================================================
class apb_config_sequence extends uvm_sequence #(apb_pkg::apb_transaction);

  `uvm_object_utils(apb_config_sequence)

  uart_config cfg;

  function new(string name = "apb_config_sequence");
    super.new(name);
  endfunction

  task body();
    apb_pkg::apb_transaction tr;
    
    if (!uvm_config_db#(uart_config)::get(null, "*", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_cfg")

    `uvm_info("APB_CFG", "Starting APB configuration sequence", UVM_LOW)

    // Config Register 0x0000: {rx_en, tx_en, sm[4:0], parity_en}
    tr = apb_pkg::apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr  = 32'h0000;
    tr.write = 1;
    tr.data  = {cfg.uart_rx_en, cfg.uart_tx_en, cfg.uart_sm, cfg.parity_en};
    finish_item(tr);

    // Config Register 0x0001: {parity_odd_even, packet_width[1:0], stop_bit_count[1:0]}
    tr = apb_pkg::apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr  = 32'h0001;
    tr.write = 1;
    tr.data  = {cfg.parity_odd_even, cfg.packet_width, cfg.stop_bit_count};
    finish_item(tr);

    `uvm_info("APB_CFG", "APB configuration sequence complete", UVM_LOW)
  endtask

endclass : apb_config_sequence

// =============================================================================
// Error Injection Sequence — Targeted errors (parity, frame)
// =============================================================================
class uart_error_injection_sequence extends uvm_sequence #(uart_seq_item);

  `uvm_object_utils(uart_error_injection_sequence)

  function new(string name = "uart_error_injection_sequence");
    super.new(name);
  endfunction

  task body();
    uart_seq_item item;
    
    `uvm_info("ERR_SEQ", "Starting error injection sequence (2 parity, 2 frame errors)", UVM_MEDIUM)

    // 1. Parity errors
    for (int i = 0; i < 2; i++) begin
      item = uart_seq_item::type_id::create($sformatf("p_err_item_%0d", i));
      start_item(item);
      if (!item.randomize() with { inject_parity_error == 1; inject_frame_error == 0; }) begin
         `uvm_warning("RANDFAIL", "Failed to randomize parity error item")
         item.data = 8'hAA; item.inject_parity_error = 1;
      end
      // Ensure driver sees the config flags
      item.parity_en = 1;
      finish_item(item);
    end

    // 2. Frame errors
    for (int i = 0; i < 2; i++) begin
      item = uart_seq_item::type_id::create($sformatf("f_err_item_%0d", i));
      start_item(item);
      if (!item.randomize() with { inject_frame_error == 1; inject_parity_error == 0; }) begin
         `uvm_warning("RANDFAIL", "Failed to randomize frame error item")
         item.data = 8'h55; item.inject_frame_error = 1;
      end
      finish_item(item);
    end
  endtask

endclass : uart_error_injection_sequence

// =============================================================================
// APB Interrupt Verification Sequence — Reads status to verify interrupt clear
// =============================================================================
class apb_interrupt_verification_sequence extends uvm_sequence #(apb_pkg::apb_transaction);

  `uvm_object_utils(apb_interrupt_verification_sequence)

  function new(string name = "apb_interrupt_verification_sequence");
    super.new(name);
  endfunction

  task body();
    apb_pkg::apb_transaction tr;
    
    `uvm_info("APB_INT", "Reading status registers to verify interrupt", UVM_LOW)

    // Read Status Register 0x0002
    tr = apb_pkg::apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr = 32'h0002; tr.write = 0;
    finish_item(tr);
    `uvm_info("APB_INT", $sformatf("Status 0x0002: 0x%0h", tr.data), UVM_LOW)

    // Read Status Register 0x0003
    tr = apb_pkg::apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr = 32'h0003; tr.write = 0;
    finish_item(tr);
    `uvm_info("APB_INT", $sformatf("Status 0x0003: 0x%0h", tr.data), UVM_LOW)
  endtask

endclass : apb_interrupt_verification_sequence

// =============================================================================
// APB FIFO Status Sequence — Polls FIFO status bits
// =============================================================================
class apb_fifo_status_sequence extends uvm_sequence #(apb_pkg::apb_transaction);

  `uvm_object_utils(apb_fifo_status_sequence)

  function new(string name = "apb_fifo_status_sequence");
    super.new(name);
  endfunction

  task body();
    apb_pkg::apb_transaction tr;
    
    `uvm_info("APB_FIFO", "Polling FIFO status registers", UVM_LOW)

    repeat(5) begin
        tr = apb_pkg::apb_transaction::type_id::create("tr");
        start_item(tr);
        tr.addr = 32'h0002; tr.write = 0;
        finish_item(tr);
        `uvm_info("APB_FIFO", $sformatf("FIFO Status 0x0002: 0x%0h", tr.data), UVM_LOW)
        #1000;
    end
  endtask

endclass : apb_fifo_status_sequence

// =============================================================================
// RAL Configuration Sequence
// =============================================================================
class uart_ral_config_seq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(uart_ral_config_seq)

  uart_regs regmodel;
  uart_config cfg;

  function new(string name = "uart_ral_config_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t data;

    if (!uvm_config_db#(uart_config)::get(null, "*", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_cfg")

    if (regmodel == null)
      `uvm_fatal("NOREG", "regmodel is null")

    `uvm_info("RAL_CFG", "Configuring DUT via RAL", UVM_LOW)

    // Write Config 0
    data = {24'h0, cfg.uart_rx_en, cfg.uart_tx_en, cfg.uart_sm, cfg.parity_en};
    regmodel.config0.write(status, data, .parent(this));

    // Write Config 1
    data = {24'h0, 3'b000, cfg.parity_odd_even, cfg.packet_width, cfg.stop_bit_count};
    regmodel.config1.write(status, data, .parent(this));

  endtask
endclass

// =============================================================================
// Interrupt Handler Sequence
// =============================================================================
class interrupt_handler_sequence extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(interrupt_handler_sequence)

  virtual intr_if vif;
  uart_regs regmodel;

  function new(string name = "interrupt_handler_sequence");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t data;

    if (!uvm_config_db#(virtual intr_if)::get(null, "*", "intr_vif", vif))
      `uvm_fatal("NOVIF", "Could not get intr_vif")
      
    if (regmodel == null)
      `uvm_fatal("NOREG", "regmodel is null")

    forever begin
      // Wait for interrupt to go high
      @(posedge vif.interrupt);
      `uvm_info("INTR_HNDLR", "Interrupt detected! Reading status registers via RAL...", UVM_LOW)

      // Read status 0
      regmodel.status0.read(status, data, .parent(this));
      `uvm_info("INTR_HNDLR", $sformatf("Status 0: 0x%0h", data), UVM_LOW)
      
      // Read status 1
      regmodel.status1.read(status, data, .parent(this));
      `uvm_info("INTR_HNDLR", $sformatf("Status 1: 0x%0h", data), UVM_LOW)

      // Wait for interrupt to clear (if it doesn't immediately clear, might need a delay or write-to-clear)
      wait(vif.interrupt == 0);
    end
  endtask
endclass

// =============================================================================
// Top Virtual Sequence
// =============================================================================
class uart_top_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(uart_top_vseq)

  uart_regs regmodel;
  uvm_sequencer #(uart_seq_item) tx_sqr;  // TX agent sequencer
  uvm_sequencer #(uart_seq_item) rx_sqr;  // RX agent sequencer
  uart_config cfg;

  function new(string name = "uart_top_vseq");
    super.new(name);
  endfunction

  task body();
    uart_ral_config_seq cfg_seq;
    uart_tx_base_sequence tx_seq;
    uart_rx_base_sequence rx_seq;
    interrupt_handler_sequence intr_seq;

    if (!uvm_config_db#(uart_config)::get(null, "*", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_cfg")

    // 1. Configure DUT via RAL (must complete before interrupt handler can issue RAL reads)
    cfg_seq = uart_ral_config_seq::type_id::create("cfg_seq");
    cfg_seq.regmodel = regmodel;
    `uvm_info("TOP_VSEQ", "Starting RAL config sequence", UVM_LOW)
    cfg_seq.start(null);

    // Start background interrupt handler AFTER config is done to avoid
    // APB bus contention (both RAL config writes and interrupt reads
    // share the same APB sequencer)
    intr_seq = interrupt_handler_sequence::type_id::create("intr_seq");
    intr_seq.regmodel = regmodel;
    fork
      intr_seq.start(null);
    join_none

    // 2. Start UART sequences in parallel (full-duplex)
    fork
      begin
        tx_seq = uart_tx_base_sequence::type_id::create("tx_seq");
        tx_seq.num_transactions = cfg.num_transactions;
        `uvm_info("TOP_VSEQ", "Starting TX sequence", UVM_LOW)
        tx_seq.start(tx_sqr);
      end
      begin
        rx_seq = uart_rx_base_sequence::type_id::create("rx_seq");
        rx_seq.num_transactions = cfg.num_transactions;
        `uvm_info("TOP_VSEQ", "Starting RX sequence", UVM_LOW)
        rx_seq.start(rx_sqr);
      end
    join

    `uvm_info("TOP_VSEQ", "Top virtual sequence complete", UVM_LOW)
  endtask
endclass

`endif // UART_SEQUENCES_SV
