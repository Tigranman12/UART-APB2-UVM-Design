`ifndef UART_TX_AGENT_SV
`define UART_TX_AGENT_SV

// =============================================================================
// UART TX Agent
// Contains TX driver (writes to TX FIFO), TX monitor (observes uart_tx line),
// and TX sequencer.
// =============================================================================
class uart_tx_agent extends uvm_agent;

  `uvm_component_utils(uart_tx_agent)

  uart_tx_driver          driver;
  uart_tx_monitor         monitor;
  uart_tx_input_monitor   input_monitor;
  uart_tx_sequencer       sequencer;

  uart_config       cfg;

  function new(string name = "uart_tx_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")

    // Monitors are always created (passive)
    monitor       = uart_tx_monitor::type_id::create("monitor", this);
    input_monitor = uart_tx_input_monitor::type_id::create("input_monitor", this);

    // Driver and sequencer only in active mode
    if (cfg.tx_agent_is_active == UVM_ACTIVE) begin
      driver    = uart_tx_driver::type_id::create("driver", this);
      sequencer = uart_tx_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.tx_agent_is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass : uart_tx_agent

`endif // UART_TX_AGENT_SV
