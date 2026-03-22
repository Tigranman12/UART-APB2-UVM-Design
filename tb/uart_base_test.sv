`ifndef UART_BASE_TEST_SV
`define UART_BASE_TEST_SV

// =============================================================================
// Base Test for UART UVM Environment
// =============================================================================
class uart_base_test extends uvm_test;
  `uvm_component_utils(uart_base_test)

  uart_env     env;
  uart_config  cfg;
  uart_regs    regmodel;

  function new(string name = "uart_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TEST", "build_phase started", UVM_LOW)
    
    // Create and randomize config
    cfg = uart_config::type_id::create("cfg");
    configure();
    
    // Get VIF for config
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", cfg.vif))
      `uvm_fatal("NOVIF", "Could not get uart_vif for config")

    // Create and build RAL model
    regmodel = new("regmodel");
    regmodel.build();
    regmodel.lock_model();
    regmodel.reset();

    // Set config in config_db for all components
    uvm_config_db#(uart_config)::set(null, "*", "uart_cfg", cfg);
    uvm_config_db#(uart_regs)::set(null, "*", "regmodel", regmodel);

    // Create environment
    env = uart_env::type_id::create("env", this);
    `uvm_info("TEST", "build_phase finished", UVM_LOW)
  endfunction

  virtual function void configure();
    if (!cfg.randomize()) begin
       `uvm_fatal("RANDFAIL", "Failed to randomize uart_config, using manual defaults")
       //cfg.uart_rx_en = 1;
       //cfg.uart_tx_en = 1;
       //cfg.uart_sm = 19;
       //cfg.parity_en = 0;
       //cfg.parity_odd_even = 0;
       //cfg.packet_width = 3;
       //cfg.stop_bit_count = 0;
       //cfg.cycles_per_bit = 100;
       //cfg.num_transactions = 10;
    end
    `uvm_info("TEST_CFG", $sformatf("Config: uart_sm=%0d parity_en=%0d parity_odd_even=%0d packet_width=%0d(%0d bits) stop_bit_count=%0d cycles_per_bit=%0d num_tx=%0d", 
      cfg.uart_sm, cfg.parity_en, cfg.parity_odd_even, cfg.packet_width, cfg.packet_width+5, cfg.stop_bit_count, cfg.cycles_per_bit, cfg.num_transactions), UVM_LOW)
  endfunction


  // Raise objection early so UVM-1.2 (with UVM_NO_DPI) doesn't kill the
  // run phase before the run_phase task body gets a chance to execute.
//  function void end_of_elaboration_phase(uvm_phase phase);
 //   uvm_phase run_ph;
 //   super.end_of_elaboration_phase(phase);
 //   run_ph = uvm_run_phase::get();
 //   run_ph.raise_objection(this, "early_obj");
 // endfunction


  virtual task run_phase(uvm_phase phase);
    uart_top_vseq top_vseq;
    phase.raise_objection(this, "early_obj");

    `uvm_info("TEST", "run_phase: started", UVM_LOW)
    
    // Wait for reset release
    if (cfg.vif.reset_n !== 1'b1) begin
      `uvm_info("TEST", "run_phase: waiting for reset release...", UVM_LOW)
      wait(cfg.vif.reset_n === 1'b1);
    end
    `uvm_info("TEST", "run_phase: reset released, starting sequences", UVM_LOW)

    // Run top sequence which configures RAL and starts TX/RX base sequences
    top_vseq = uart_top_vseq::type_id::create("top_vseq");
    top_vseq.regmodel = regmodel;
    // Set expected counts on scoreboard so it triggers completion events
    env.scoreboard.expected_tx_count = cfg.num_transactions;
    env.scoreboard.expected_rx_count = cfg.num_transactions;

    top_vseq.tx_sqr = env.tx_agent.sequencer;
    top_vseq.rx_sqr = env.rx_agent.sequencer;
    top_vseq.start(null);

    `uvm_info("TEST", "run_phase: all sequences finished, waiting for scoreboard completion...", UVM_LOW)

    // Wait for all TX items to be matched: both expected and actual FIFOs empty
    // means every expected item has been paired with its actual counterpart
    fork
      begin
        wait(env.scoreboard.tx_fifo_in.used() == 0 &&
             env.scoreboard.tx_serial_in.used() == 0 &&
             env.scoreboard.tx_match_count > 0);
        `uvm_info("TEST", $sformatf("run_phase: TX scoreboard matched all %0d items",
                  env.scoreboard.tx_match_count), UVM_LOW)
      end
      begin
        // Safety timeout: worst case ~15 bit-times per frame × num_transactions
        #(cfg.cycles_per_bit * 15 * 10 * (cfg.num_transactions + 1));
        `uvm_warning("TEST", "run_phase: TX completion timeout reached!")
      end
    join_any
    disable fork;

    // Drop the early objection to end the run phase
    phase.drop_objection(this, "early_obj");
    `uvm_info("TEST", "run_phase: objection dropped, finishing", UVM_LOW)
  endtask


  function void report_phase(uvm_phase phase);
    uvm_report_server server;
    int err_num;
    server = uvm_report_server::get_server();
    err_num = server.get_severity_count(UVM_ERROR);

    if (err_num == 0) begin
      `uvm_info("TEST_RESULT", "*** TEST PASSED ***", UVM_LOW)
    end else begin
      `uvm_info("TEST_RESULT", "*** TEST FAILED ***", UVM_LOW)
    end
  endfunction

endclass

`endif // UART_BASE_TEST_SV
