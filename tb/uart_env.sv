`ifndef UART_ENV_SV
`define UART_ENV_SV

// =============================================================================
// UART Environment
// Top-level UVM environment containing TX agent, RX agent, scoreboard,
// and coverage collector. Connects all analysis ports.
// =============================================================================
class uart_env extends uvm_env;

  `uvm_component_utils(uart_env)

  uart_tx_agent    tx_agent;
  uart_rx_agent    rx_agent;
  apb_pkg::apb_agent apb_agent;
  uart_scoreboard  scoreboard;
  uart_coverage    coverage_tx;
  uart_coverage    coverage_rx;
  uart_coverage    coverage_all;  // Unified collector for cross-direction coverage

  uart_regs        regmodel;
  uart_reg_adapter adapter;

  uart_config      cfg;

  function new(string name = "uart_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")

    // Create agents
    tx_agent = uart_tx_agent::type_id::create("tx_agent", this);
    rx_agent = uart_rx_agent::type_id::create("rx_agent", this);
    apb_agent = apb_pkg::apb_agent::type_id::create("apb_agent", this);

    // Create scoreboard
    scoreboard = uart_scoreboard::type_id::create("scoreboard", this);

    // Create coverage collectors (one per path)
    coverage_tx = uart_coverage::type_id::create("coverage_tx", this);
    coverage_rx = uart_coverage::type_id::create("coverage_rx", this);
    coverage_all = uart_coverage::type_id::create("coverage_all", this);

    // Get regmodel from config db
    if (!uvm_config_db#(uart_regs)::get(this, "", "regmodel", regmodel))
      `uvm_fatal("NOREG", "Could not get regmodel from config_db")
      
    // Create adapter
    adapter = uart_reg_adapter::type_id::create("adapter", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect RAL to APB sequencer
    if (regmodel == null)
      `uvm_fatal("NOREG", "regmodel is null in connect_phase")
    if (regmodel.get_parent() == null) begin
      regmodel.default_map.set_sequencer(apb_agent.sequencer, adapter);
      regmodel.default_map.set_auto_predict(1);
    end

    // TX input monitor (snoops FIFO writes) → scoreboard expected TX
    tx_agent.input_monitor.ap.connect(scoreboard.tx_fifo_in.analysis_export);
    // TX monitor (serial line observer) → scoreboard actual TX + coverage
    tx_agent.monitor.ap.connect(scoreboard.tx_serial_in.analysis_export);
    tx_agent.monitor.ap.connect(coverage_tx.analysis_export);

    // --- RX path connections ---
    // RX input monitor (snoops serial line) → scoreboard expected RX
    rx_agent.input_monitor.ap.connect(scoreboard.rx_serial_in.analysis_export);
    // RX monitor (FIFO output reader) → scoreboard actual RX + coverage
    rx_agent.monitor.ap.connect(scoreboard.rx_fifo_out.analysis_export);
    rx_agent.monitor.ap.connect(coverage_rx.analysis_export);

    // --- Unified coverage (both paths) ---
    tx_agent.monitor.ap.connect(coverage_all.analysis_export);
    rx_agent.monitor.ap.connect(coverage_all.analysis_export);
  endfunction

endclass : uart_env

`endif // UART_ENV_SV
