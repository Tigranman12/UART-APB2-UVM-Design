`ifndef UART_RX_AGENT_SV
`define UART_RX_AGENT_SV

// =============================================================================
// UART RX Agent
// Contains RX driver (drives uart_rx serial line), RX monitor (reads from
// RX FIFO), and RX sequencer.
// =============================================================================
class uart_rx_agent extends uvm_agent;

  `uvm_component_utils(uart_rx_agent)

  uart_rx_driver          driver;
  uart_rx_monitor         monitor;
  uart_rx_input_monitor   input_monitor;
  uart_rx_sequencer       sequencer;

  uart_config       cfg;

  function new(string name = "uart_rx_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_fatal("NOCFG", "Could not get uart_config from config_db")

    // Monitors are always created (passive)
    monitor       = uart_rx_monitor::type_id::create("monitor", this);
    input_monitor = uart_rx_input_monitor::type_id::create("input_monitor", this);

    // Driver and sequencer only in active mode
    if (cfg.rx_agent_is_active == UVM_ACTIVE) begin
      driver    = uart_rx_driver::type_id::create("driver", this);
      sequencer = uart_rx_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.rx_agent_is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass : uart_rx_agent

`endif // UART_RX_AGENT_SV
