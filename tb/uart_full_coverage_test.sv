// =============================================================================
// Full Coverage Test for UART UVM Environment
// =============================================================================
`ifndef UART_FULL_COVERAGE_TEST_SV
`define UART_FULL_COVERAGE_TEST_SV

class uart_full_coverage_test extends uart_base_test;
  `uvm_component_utils(uart_full_coverage_test)

  function new(string name = "uart_full_coverage_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void configure();
    // We want to run a lot of transactions to hit all coverage bins.
    // Instead of completely randomizing in one shot, we could just run
    // a very large number of transactions with everything randomized.
    if (!cfg.randomize()) begin
       `uvm_warning("RANDFAIL", "Failed to randomize uart_config, using manual defaults")
    end
    
    // Force a large number of transactions and ensure variety
    cfg.num_transactions = 1000;
    
    // Let's ensure packet widths and parity configs are fully covered by allowing
    // them to be highly randomized in the sequences, but the test config sets the initial.
    // However, since packet width / parity are in cfg and used by sequences,
    // we may need to run the top_vseq multiple times inside run_phase with different configs,
    // or just rely on the coverage of `uart_seq_item` which is randomized per item.

    // Actually, `uart_seq_item` randomizes `data` and `parity_error`/`frame_error`.
    // It takes `packet_width` and `parity_en` from the config.
    // So to cover all `cross_width_parity`, we MUST run sequences with different configs.
    
    `uvm_info("TEST_CFG", $sformatf("Config: uart_sm=%0d parity_en=%0d parity_odd_even=%0d packet_width=%0d num_tx=%0d", 
      cfg.uart_sm, cfg.parity_en, cfg.parity_odd_even, cfg.packet_width, cfg.num_transactions), UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_top_vseq top_vseq;
    
    phase.raise_objection(this, "early_obj");
    `uvm_info("TEST", "run_phase: started", UVM_LOW)
    
    // Wait for reset release
    if (cfg.vif.reset_n !== 1'b1) begin
      `uvm_info("TEST", "run_phase: waiting for reset release...", UVM_LOW)
      wait(cfg.vif.reset_n === 1'b1);
    end
    
    // To hit 100% coverage on cross_width_parity, we iterate through all packet widths
    // and parity enable combinations.
    for (int pw = 0; pw < 4; pw++) begin
      for (int pe = 0; pe < 2; pe++) begin
        `uvm_info("TEST", $sformatf("Running iteration with packet_width=%0d, parity_en=%0d", pw, pe), UVM_LOW)
        
        cfg.packet_width = pw;
        cfg.parity_en = pe;
        cfg.num_transactions = 50; // 50 transactions per config = 400 total
        
        // Re-write config_db just in case (though components have the handle)
        uvm_config_db#(uart_config)::set(null, "*", "uart_cfg", cfg);
        
        top_vseq = uart_top_vseq::type_id::create("top_vseq");
        top_vseq.regmodel = regmodel;
        top_vseq.tx_sqr = env.tx_agent.sequencer;
        top_vseq.rx_sqr = env.rx_agent.sequencer;
        top_vseq.start(null);
        
        // Wait a bit between configs
        #(cfg.cycles_per_bit * 50);
      end
    end

    // Add error injection sequences here to hit parity and frame error coverpoints
    for (int pe = 0; pe < 2; pe++) begin // Need one with parity enabled to hit parity err
        cfg.packet_width = 3; // 8 bit
        cfg.parity_en = pe;
        cfg.num_transactions = 10;
        
        // Let's run a special sequence for errors
        begin
           uart_error_injection_sequence err_tx_seq;
           uart_rx_base_sequence         rx_seq;
           uart_ral_config_seq           cfg_seq;
           
           cfg_seq = uart_ral_config_seq::type_id::create("cfg_seq");
           cfg_seq.regmodel = regmodel;
           cfg_seq.start(null);
           
           fork
             begin
               err_tx_seq = uart_error_injection_sequence::type_id::create("err_tx_seq");
               err_tx_seq.start(env.rx_agent.sequencer);
             end
             begin
               rx_seq = uart_rx_base_sequence::type_id::create("rx_seq");
               rx_seq.num_transactions = 4;
               rx_seq.start(env.tx_agent.sequencer);
             end
           join
           #(cfg.cycles_per_bit * 50);
        end
    end

    `uvm_info("TEST", "run_phase: all sequences finished, draining...", UVM_LOW)
    #(cfg.cycles_per_bit * 100);
    phase.drop_objection(this, "early_obj");
  endtask

endclass

`endif
