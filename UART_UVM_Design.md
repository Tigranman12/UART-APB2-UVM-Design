# UART APB2 UVM Design — Architecture & Functional Description

## Overview

This document describes the architecture and operation of a UVM testbench for a UART module with an APB2 slave register interface. The design implements a configurable UART (baud rate, packet width, parity, stop bits) with dual 8-deep FIFOs, verified using a UVM environment with Register Abstraction Layer (RAL) for APB2 register access.

---

## ASCII Architecture Diagram

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                              tb_top (testbench.sv)                              ║
║                                                                                  ║
║  CLOCKS/RESET        VIRTUAL INTERFACES                                          ║
║  ┌────────────┐      uart_if ─────────────────────────────────────────────────┐ ║
║  │ PCLK 100MHz│      uart_fifo_if ──────────────────────────────────────────┐ │ ║
║  │ PRESETn    │      apb_if ────────────────────────────────────────────┐   │ │ ║
║  └─────┬──────┘      intr_if ─────────────────────────────────────────┐ │   │ │ ║
║        │                                                               │ │   │ │ ║
║  ┌─────▼──────────────────────────────────────────────────────────────▼─▼───▼─▼─╗
║  │                          apb2uart_top (DUT)                                   ║
║  │                                                                                ║
║  │   ┌──────────────┐   CONFIG0/1 regs    ┌──────────────────────────────────┐  ║
║  │   │  regbank     │ ──uart_sm,parity──► │           uart_top               │  ║
║  │   │  (APB slave) │ ──rx/tx_en,width──► │  ┌────────────┐ ┌─────────────┐ │  ║
║  │   │              │                     │  │ uart_tx_top│ │ uart_rx_top │ │  ║
║  │   │ STATUS0/1 ◄──│ ◄──errors,FIFO────  │  │ ┌────────┐ │ │ ┌─────────┐│ │  ║
║  │   │ interrupt ───┼──────────────────►  │  │ │tx_fsm  │ │ │ │rx_fsm   ││ │  ║
║  │   └──────────────┘                     │  │ │tx_clkgen│ │ │ │rx_clkgen││ │  ║
║  │        APB bus                         │  │ │tx_fifo │ │ │ │rx_fifo  ││ │  ║
║  │   PSEL/PENABLE/PWRITE                  │  │ └────────┘ │ │ └─────────┘│ │  ║
║  │   PADDR/PWDATA/PRDATA                  │  │   uart_tx──►   ◄──uart_rx  │ │  ║
║  │                                        │  └────────────┘ └─────────────┘ │  ║
║  │                                        └──────────────────────────────────┘  ║
║  └────────────────────────────────────────────────────────────────────────────────
║
║  ┌──────────────────────────────── uart_env ─────────────────────────────────────┐
║  │                                                                                │
║  │  ┌─────────────────────┐         ┌─────────────────────┐                      │
║  │  │    uart_tx_agent    │         │    uart_rx_agent     │                      │
║  │  │  ┌───────────────┐  │         │  ┌────────────────┐  │                      │
║  │  │  │  tx_driver    │  │         │  │  rx_driver     │  │                      │
║  │  │  │(writes FIFO   │  │         │  │(drives uart_rx │  │                      │
║  │  │  │ via fifo_if)  │  │         │  │ serial frames) │  │                      │
║  │  │  └───────┬───────┘  │         │  └───────┬────────┘  │                      │
║  │  │  ┌───────▼───────┐  │         │  ┌───────▼────────┐  │                      │
║  │  │  │  tx_sequencer │  │         │  │  rx_sequencer  │  │                      │
║  │  │  └───────────────┘  │         │  └────────────────┘  │                      │
║  │  │                     │         │                       │                      │
║  │  │  ┌───────────────┐  │         │  ┌────────────────┐  │                      │
║  │  │  │  tx_monitor   │──┼─ap──┐   │  │  rx_monitor    │──┼─ap──┐               │
║  │  │  │(observes uart │  │     │   │  │(reads RX FIFO  │  │     │               │
║  │  │  │ _tx serial)   │  │     │   │  │ data_out)      │  │     │               │
║  │  │  └───────────────┘  │     │   │  └────────────────┘  │     │               │
║  │  │                     │     │   │                       │     │               │
║  │  │  ┌───────────────┐  │     │   │  ┌────────────────┐  │     │               │
║  │  │  │tx_input_monitor│─┼─ap──┼─┐ │  │rx_input_monitor│──┼─ap──┼─┐            │
║  │  │  │(snoops FIFO   │  │     │ │ │  │(snoops uart_rx │  │     │ │            │
║  │  │  │ write signals)│  │     │ │ │  │ serial line)   │  │     │ │            │
║  │  │  └───────────────┘  │     │ │ │  └────────────────┘  │     │ │            │
║  │  └─────────────────────┘     │ │ └──────────────────────┘     │ │            │
║  │                               │ │                               │ │            │
║  │  ┌────────────────────────────▼─▼───────────────────────────────▼─▼──────┐   │
║  │  │                     uart_scoreboard                                     │   │
║  │  │                                                                          │   │
║  │  │  TX path:  tx_fifo_in (expected) ──► compare ◄── tx_serial_in (actual)  │   │
║  │  │  RX path:  rx_serial_in (expected) ─► compare ◄── rx_fifo_out (actual)  │   │
║  │  │                                                                          │   │
║  │  │  Reports: MATCH / MISMATCH, error flag checks                           │   │
║  │  └──────────────────────────────────────────────────────────────────────────┘   │
║  │                                                                                │
║  │  ┌─────────────────┐   ┌─────────────────────────────────────────────────┐   │
║  │  │   apb_agent     │   │              uart_coverage (×3)                  │   │
║  │  │ ┌─────────────┐ │   │  coverage_tx  ◄── tx_monitor.ap                 │   │
║  │  │ │ apb_driver  │ │   │  coverage_rx  ◄── rx_monitor.ap                 │   │
║  │  │ │ apb_monitor │ │   │  coverage_all ◄── tx + rx monitor.ap            │   │
║  │  │ │ apb_seqr    │ │   │                                                  │   │
║  │  │ └─────────────┘ │   │  Coverpoints: direction, data, packet_width,     │   │
║  │  └────────┬────────┘   │  parity_en, parity_error, frame_error            │   │
║  │           │            │  Crosses: dir×data, width×parity, parity_err     │   │
║  │           │            └─────────────────────────────────────────────────┘   │
║  │           │                                                                    │
║  │  ┌────────▼────────────────────────────────────┐                             │
║  │  │  uart_regs (RAL) + uart_reg_adapter         │                             │
║  │  │  CONFIG0: rx_en, tx_en, uart_sm, parity_en  │                             │
║  │  │  CONFIG1: parity_o_e, packet_width, stop_bit│                             │
║  │  │  STATUS0: error flags (RO)                  │                             │
║  │  │  STATUS1: FIFO status  (RO)                 │                             │
║  │  └─────────────────────────────────────────────┘                             │
║  └────────────────────────────────────────────────────────────────────────────────┘
╚══════════════════════════════════════════════════════════════════════════════════╝
```

---

## How It Works

### TX Path (Write to UART, transmit on wire)

1. The test randomizes `uart_config` and writes CONFIG0/CONFIG1 registers via RAL (APB agent → apb_slave → regbank).
2. `uart_tx_base_sequence` sends `uart_seq_item` transactions to `tx_sequencer`.
3. `tx_driver` pulses `uart_tx_fifo_write` with data on `uart_fifo_if`.
4. `uart_tx_top` serializes: **start bit → LSB-first data bits → optional parity bit → stop bit(s)**, driven on `uart_tx` serial line.
5. `tx_input_monitor` snoops the FIFO write signals → sends **expected** item to scoreboard `tx_fifo_in`.
6. `tx_monitor` samples the `uart_tx` serial line at bit-center timing → sends **actual** item to scoreboard `tx_serial_in`.
7. Scoreboard compares expected vs actual data; reports MATCH/MISMATCH.

### RX Path (Receive serial frame, read from FIFO)

1. `uart_rx_base_sequence` sends `uart_seq_item` to `rx_sequencer`.
2. `rx_driver` bit-bangs serial frames onto `uart_rx` at `cycles_per_bit` timing.
3. `uart_rx_top` detects the start edge via negedge detector, samples bits at center using a **majority-vote 3-sample filter**, and writes the deserialized byte to the RX FIFO.
4. `rx_input_monitor` snoops the `uart_rx` serial line, reconstructs the data, and sends **expected** item including observed error flags (`parity_error`, `frame_error`).
5. `rx_monitor` waits for `uart_rx_fifo_data_ready` pulse, reads `uart_rx_fifo_data_out`, and sends **actual** item to scoreboard.
6. Scoreboard compares; skips data check if parity/frame error was observed on the serial line; verifies that DUT raised the correct error flags in STATUS0.

### Baud Rate Generation

```
uart_sm [4:0]  →  count_top lookup (uart_tx/rx_clk_gen)
                         │
               16-bit counter divides 100 MHz clock
                         │
         1-cycle pulse every count_top system clocks
                         │
         FSM counts 10 sub-pulses = 1 bit period
                         │
   bit_period = count_top × 10 × 10 ns
```

| uart_sm | Baud Rate | count_top |
|---------|-----------|-----------|
| 0       | 300       | 33333     |
| 7       | 9600      | 1042      |
| 9       | 19200     | 521       |
| 11      | 38400     | 260       |
| 12      | 57600     | 174       |
| 14      | 115200    | 87        |
| 19      | 1,000,000 | 10        |

### RAL Configuration Flow

```
Test
  └─► uart_ral_config_seq
        └─► regmodel.config0.write(data)
              └─► uart_reg_adapter.reg2bus()
                    └─► APB transaction (PSEL, PENABLE, PWRITE, PADDR, PWDATA)
                          └─► apb_driver drives APB bus
                                └─► regbank stores to mem[0] / mem[1]
                                      └─► wires feed directly to uart_top control inputs
```

### Interrupt Flow

```
uart_rx_top detects parity/frame error
  └─► error flags → STATUS0 register
        └─► regbank: interrupt = |reg_status_0x0002
              └─► interrupt signal → intr_if → interrupt_handler_sequence
                    └─► regmodel.status0.read() via RAL
```

---

## Register Map

| Register | Address | Access | Fields |
|----------|---------|--------|--------|
| CONFIG0  | 0x00    | RW     | `[7]` rx_en, `[6]` tx_en, `[5:1]` uart_sm, `[0]` parity_en |
| CONFIG1  | 0x01    | RW     | `[4]` parity_odd_even, `[3:2]` packet_width, `[1:0]` stop_bit_count |
| STATUS0  | 0x02    | RO     | `[4]` rx_parity_err, `[3]` rx_frame_err, `[2]` tx_fifo_wr_err, `[1]` rx_fifo_wr_err, `[0]` rx_fifo_rd_err |
| STATUS1  | 0x03    | RO     | `[2]` tx_fifo_full, `[1]` rx_fifo_full, `[0]` rx_fifo_empty |

---

## Available Tests

| Test | Description |
|------|-------------|
| `uart_base_test`         | Default: TX/RX with randomized config |
| `uart_parity_test`       | Parity error detection (even and odd) |
| `uart_packet_width_test` | Sweeps all packet widths (5, 6, 7, 8 bits) |
| `uart_baudrate_test`     | Tests baud rate settings (uart_sm 17–19) |
| `uart_fifo_full_test`    | FIFO overflow (12 transactions, 8-deep FIFO) |
| `uart_all_config_test`   | Fully randomized configuration |
| `uart_error_injection_test` | Parity/frame error injection on RX |
| `uart_interrupt_test`    | Interrupt generation on error conditions |
| `uart_fifo_status_test`  | FIFO full/empty status verification |
| `uart_full_coverage_test`| Sweeps all packet_width × parity_en combinations for 100% cross coverage |

---

## Functional Coverage

Three `uart_coverage` instances collect coverage:

- **coverage_tx** — TX monitor transactions only
- **coverage_rx** — RX monitor transactions only
- **coverage_all** — both paths combined

Coverpoints:

| Coverpoint | Bins |
|------------|------|
| `cp_direction` | TX, RX |
| `cp_data` | zero (0x00), low (0x01–3F), mid (0x40–BF), high (0xC0–FE), all_1s (0xFF) |
| `cp_packet_width` | 5-bit, 6-bit, 7-bit, 8-bit |
| `cp_parity_en` | disabled, enabled |
| `cp_parity_error` | no_error, error |
| `cp_frame_error` | no_error, error |
| `cross_dir_data` | direction × data |
| `cross_width_parity` | packet_width × parity_en |
| `cross_parity_error` | parity_en × parity_error (ignores parity disabled + error) |

---

## RTL Critical Issues (for reference)

| # | Severity | File | Description |
|---|----------|------|-------------|
| 1 | Critical | `uart_{tx,rx}_clk_gen.v` | Counter wrap-around when uart_sm changes to smaller count_top mid-count — bit period becomes ~65535 cycles |
| 2 | Critical | `apb_slave.sv` | Missing `begin/end` after `else` — APB state machine logic runs outside reset guard |
| 3 | Critical | `apb_slave.sv` | Mixed blocking/non-blocking assignments in same sequential always block |
| 4 | Moderate | `uart_{tx,rx}_clk_gen.v` | `count_top` is a `reg` driven combinatorially — glitch-prone on uart_sm transitions |
| 5 | Minor    | `uart_rx_bit_sampler.v` | `stop_bit_ready` asserts 2 sub-clocks early (count=7 vs count=9) |
