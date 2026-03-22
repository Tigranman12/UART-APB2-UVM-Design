`ifndef UART_TEST_LIB_SV
`define UART_TEST_LIB_SV

// =============================================================================
// UART Test Library
// Collection of specific test cases extending uart_base_test.
// =============================================================================

// =============================================================================
// Parity Test — Test with parity enabled (even and odd)
// =============================================================================
class uart_parity_test extends uart_base_test;

  `uvm_component_utils(uart_parity_test)

  function new(string name = "uart_parity_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    if (!cfg.randomize() with {
      parity_en  == 1;
      uart_sm    == 5'd19;  // fast simulation
    })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for parity test")
    `uvm_info("TEST_CFG", $sformatf("Parity Test Config: %s", cfg.convert2string()), UVM_LOW)
  endfunction

endclass : uart_parity_test


// =============================================================================
// Packet Width Test — Sweep all four packet widths
// =============================================================================
class uart_packet_width_test extends uart_base_test;

  `uvm_component_utils(uart_packet_width_test)

  function new(string name = "uart_packet_width_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    if (!cfg.randomize() with {
      uart_sm == 5'd19;
    })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for packet width test")
    cfg.num_transactions = 5;
    `uvm_info("TEST_CFG", $sformatf("Packet Width Test Config: %s", cfg.convert2string()), UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    uart_tx_base_sequence tx_seq;
    uart_rx_base_sequence rx_seq;

    phase.raise_objection(this, "uart_packet_width_test");
    #100;

    // Test each packet width
    for (int pw = 0; pw < 4; pw++) begin
      cfg.packet_width = pw[1:0];
      cfg.post_randomize();  // recalculate derived values
      `uvm_info("TEST", $sformatf("=== Testing packet_width=%0d (%0d bits) ===",
                pw, cfg.get_data_bits()), UVM_LOW)

      tx_seq = uart_tx_base_sequence::type_id::create($sformatf("tx_seq_pw%0d", pw));
      rx_seq = uart_rx_base_sequence::type_id::create($sformatf("rx_seq_pw%0d", pw));

      fork
        tx_seq.start(env.tx_agent.sequencer);
        rx_seq.start(env.rx_agent.sequencer);
      join

      // Drain time for this width
      #(cfg.cycles_per_bit * 30 * cfg.num_transactions);
    end

    phase.drop_objection(this, "uart_packet_width_test");
  endtask

endclass : uart_packet_width_test


// =============================================================================
// Baudrate Test — Test with different baud rate settings
// =============================================================================
class uart_baudrate_test extends uart_base_test;

  `uvm_component_utils(uart_baudrate_test)

  function new(string name = "uart_baudrate_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    if (!cfg.randomize() with {
      uart_sm == 5'd19;  // start fast
    })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for baudrate test")
    cfg.num_transactions = 3;
    `uvm_info("TEST_CFG", $sformatf("Baudrate Test Config: %s", cfg.convert2string()), UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    uart_tx_base_sequence tx_seq;
    uart_rx_base_sequence rx_seq;
    int baud_settings[] = '{17, 18, 19}; // fast settings for simulation

    phase.raise_objection(this, "uart_baudrate_test");
    #100;

    foreach (baud_settings[b]) begin
      cfg.uart_sm = baud_settings[b][4:0];
      cfg.post_randomize();
      `uvm_info("TEST", $sformatf("=== Testing uart_sm=%0d (cycles_per_bit=%0d) ===",
                cfg.uart_sm, cfg.cycles_per_bit), UVM_LOW)

      tx_seq = uart_tx_base_sequence::type_id::create($sformatf("tx_seq_baud%0d", b));
      rx_seq = uart_rx_base_sequence::type_id::create($sformatf("rx_seq_baud%0d", b));

      fork
        tx_seq.start(env.tx_agent.sequencer);
        rx_seq.start(env.rx_agent.sequencer);
      join

      #(cfg.cycles_per_bit * 30 * cfg.num_transactions);
    end

    phase.drop_objection(this, "uart_baudrate_test");
  endtask

endclass : uart_baudrate_test


// =============================================================================
// FIFO Full Test — Overflow the TX FIFO to check error flags
// =============================================================================
class uart_fifo_full_test extends uart_base_test;

  `uvm_component_utils(uart_fifo_full_test)

  function new(string name = "uart_fifo_full_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    if (!cfg.randomize() with {
      uart_sm == 5'd19;
      packet_width == 2'b11;
      parity_en    == 0;
    })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for FIFO full test")
    cfg.num_transactions = 12; // more than FIFO depth (8)
    `uvm_info("TEST_CFG", $sformatf("FIFO Full Test Config: %s", cfg.convert2string()), UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    uart_fifo_overflow_sequence ovf_seq;

    phase.raise_objection(this, "uart_fifo_full_test");
    #100;

    ovf_seq = uart_fifo_overflow_sequence::type_id::create("ovf_seq");
    ovf_seq.start(env.tx_agent.sequencer);

    // Wait for all data to be transmitted out
    #(cfg.cycles_per_bit * 30 * 12);

    phase.drop_objection(this, "uart_fifo_full_test");
  endtask

endclass : uart_fifo_full_test


// =============================================================================
// All Config Random Test — Random config parameters for maximum coverage
// =============================================================================
class uart_all_config_test extends uart_base_test;

  `uvm_component_utils(uart_all_config_test)

  function new(string name = "uart_all_config_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    // Turn off fast simulation constraint for full randomization
    cfg.c_fast_sim.constraint_mode(0);
    // But still limit to fast-ish rates for simulation
    if (!cfg.randomize() with {
      uart_sm inside {[15:19]};
    })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for all config test")
    cfg.num_transactions = 8;
    `uvm_info("TEST_CFG", $sformatf("All Config Test: %s", cfg.convert2string()), UVM_LOW)
  endfunction

endclass : uart_all_config_test
// =============================================================================
// Error Injection Test — Verify DUT response to parity and framing errors
// =============================================================================
class uart_error_injection_test extends uart_base_test;

  `uvm_component_utils(uart_error_injection_test)

  function new(string name = "uart_error_injection_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    if (!cfg.randomize() with {
      parity_en == 1;
      uart_sm   == 5'd19;
    })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for error test")
    `uvm_info("TEST_CFG", $sformatf("Error Injection Test Config: %s", cfg.convert2string()), UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    uart_error_injection_sequence err_seq;
    apb_config_sequence           cfg_seq;

    phase.raise_objection(this, "uart_error_injection_test");
    #100;

    // 1. Configure DUT via APB
    cfg_seq = apb_config_sequence::type_id::create("cfg_seq");
    cfg_seq.start(env.apb_agent.sequencer);

    // 2. Start Error Injection Sequence on RX path
    err_seq = uart_error_injection_sequence::type_id::create("err_seq");
    err_seq.start(env.rx_agent.sequencer);

    // Drain time
    #(cfg.cycles_per_bit * 30 * 4);

    phase.drop_objection(this, "uart_error_injection_test");
  endtask

endclass : uart_error_injection_test

// =============================================================================
// Interrupt Test — Verify interrupt toggle on errors
// =============================================================================
class uart_interrupt_test extends uart_base_test;

  `uvm_component_utils(uart_interrupt_test)

  function new(string name = "uart_interrupt_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    if (!cfg.randomize() with { parity_en == 1; uart_sm == 5'd19; })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for interrupt test")
  endfunction

  task run_phase(uvm_phase phase);
    uart_error_injection_sequence err_seq;
    apb_config_sequence           cfg_seq;
    apb_interrupt_verification_sequence int_seq;

    phase.raise_objection(this, "uart_interrupt_test");
    
    // 1. Config
    cfg_seq = apb_config_sequence::type_id::create("cfg_seq");
    cfg_seq.start(env.apb_agent.sequencer);

    // 2. Drive errors
    err_seq = uart_error_injection_sequence::type_id::create("err_seq");
    err_seq.start(env.rx_agent.sequencer);

    // 3. Verify interrupt and clear
    int_seq = apb_interrupt_verification_sequence::type_id::create("int_seq");
    int_seq.start(env.apb_agent.sequencer);

    #(cfg.cycles_per_bit * 50);
    phase.drop_objection(this, "uart_interrupt_test");
  endtask

endclass : uart_interrupt_test

// =============================================================================
// FIFO Status Test — Verify FIFO full/empty bits via APB
// =============================================================================
class uart_fifo_status_test extends uart_base_test;

  `uvm_component_utils(uart_fifo_status_test)

  function new(string name = "uart_fifo_status_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void configure();
    if (!cfg.randomize() with { uart_sm == 5'd19; })
      `uvm_fatal("RANDFAIL", "Failed to randomize config for fifo status test")
  endfunction

  task run_phase(uvm_phase phase);
    uart_fifo_overflow_sequence   ovf_seq;
    apb_config_sequence           cfg_seq;
    apb_fifo_status_sequence      stat_seq;

    phase.raise_objection(this, "uart_fifo_status_test");
    
    cfg_seq = apb_config_sequence::type_id::create("cfg_seq");
    cfg_seq.start(env.apb_agent.sequencer);

    fork
      begin
        ovf_seq = uart_fifo_overflow_sequence::type_id::create("ovf_seq");
        ovf_seq.start(env.tx_agent.sequencer);
      end
      begin
        stat_seq = apb_fifo_status_sequence::type_id::create("stat_seq");
        stat_seq.start(env.apb_agent.sequencer);
      end
    join

    #(cfg.cycles_per_bit * 100);
    phase.drop_objection(this, "uart_fifo_status_test");
  endtask

endclass : uart_fifo_status_test

`endif // UART_TEST_LIB_SV
