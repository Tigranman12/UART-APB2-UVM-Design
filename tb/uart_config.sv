`ifndef UART_CONFIG_SV
`define UART_CONFIG_SV

// =============================================================================
// UART Configuration Object
// Holds all configurable parameters for the UART testbench.
// Set in uvm_config_db by the test and used by all components.
// =============================================================================
class uart_config extends uvm_object;

  `uvm_object_utils(uart_config)

  // ---- UART configuration parameters ----
  rand bit [4:0]  uart_sm;           // Baud rate selector (0-19)
  rand bit        parity_en;         // 1 = parity enabled
  rand bit        parity_odd_even;   // 0 = even, 1 = odd
  rand bit [1:0]  packet_width;      // 2'b00=5, 2'b01=6, 2'b10=7, 2'b11=8
  rand bit [1:0]  stop_bit_count;    // 2'b00=1, 2'b01=1.5, 2'b11=2

  // ---- Test control ----
  rand bit        uart_rx_en;        // Enable RX path
  rand bit        uart_tx_en;        // Enable TX path
  int             num_transactions = 10;

  // ---- Virtual Interface ----
  virtual uart_if vif;

  // ---- Agent activity ----
  uvm_active_passive_enum tx_agent_is_active = UVM_ACTIVE;
  uvm_active_passive_enum rx_agent_is_active = UVM_ACTIVE;

  // ---- Derived: cycles per bit (10 sub-clocks × count_top) ----
  int cycles_per_bit;

  // Constraints
  constraint c_uart_sm   { uart_sm inside {[0:19]}; }
  constraint c_enables   { uart_rx_en == 1; uart_tx_en == 1; }
  constraint c_stop_bit  { stop_bit_count inside {2'b00, 2'b01, 2'b11}; } // no 2'b10
  constraint c_fast_sim  { uart_sm == 5'd19; } // fastest baud for simulation

  function new(string name = "uart_config");
    super.new(name);
  endfunction

  // Calculate cycles_per_bit from uart_sm after randomization
  function void post_randomize();
    cycles_per_bit = get_count_top(uart_sm) * 10;
  endfunction

  // Returns the count_top divider value for a given uart_sm setting
  // (matches uart_tx_clk_gen / uart_rx_clk_gen RTL)
  function int get_count_top(bit [4:0] sm);
    case (sm)
      5'd0:  return 33333; // 300    baud
      5'd1:  return 16667; // 600    baud
      5'd2:  return 8333;  // 1200   baud
      5'd3:  return 5556;  // 1800   baud
      5'd4:  return 4167;  // 2400   baud
      5'd5:  return 2083;  // 4800   baud
      5'd6:  return 1389;  // 7200   baud
      5'd7:  return 1042;  // 9600   baud
      5'd8:  return 694;   // 14400  baud
      5'd9:  return 521;   // 19200  baud
      5'd10: return 347;   // 28800  baud
      5'd11: return 260;   // 38400  baud
      5'd12: return 174;   // 57600  baud
      5'd13: return 130;   // 76800  baud
      5'd14: return 87;    // 115200 baud
      5'd15: return 78;    // 128000 baud
      5'd16: return 43;    // 230400 baud
      5'd17: return 40;    // 250000 baud
      5'd18: return 20;    // 500000 baud
      5'd19: return 10;    // 1000000 baud
      default: return 1042;
    endcase
  endfunction

  // Get the actual number of data bits from packet_width
  function int get_data_bits();
    return 5 + packet_width;
  endfunction

  function string convert2string();
    return $sformatf("uart_sm=%0d parity_en=%0b parity_odd_even=%0b packet_width=%0d(%0d bits) stop_bit_count=%0b cycles_per_bit=%0d num_tx=%0d",
                     uart_sm, parity_en, parity_odd_even, packet_width, get_data_bits(),
                     stop_bit_count, cycles_per_bit, num_transactions);
  endfunction

endclass : uart_config

`endif // UART_CONFIG_SV
