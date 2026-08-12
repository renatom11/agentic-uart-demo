# SPEC-uart_lite — a fixed-rate 8N1 serial port

Status: **DRAFT** · Owner: architect_docs_lead · Target: `rtl/`

## 1. Scope

`uart_lite` is a fixed-rate 115200 baud 8N1 UART for a 50 MHz FPGA board: a
transmitter, a 16x-oversampled receiver, a 16-deep receive FIFO, and a top level
that ties them together. One clock domain. No PLL, no block RAM, no vendor
primitive, no runtime-programmable baud rate.

Out of scope: parity, flow control (RTS/CTS), multiple baud rates, break
generation, a register bus.

## 2. Divisor arithmetic — the numbers everything else derives from

At 50.000 MHz with a 115200 baud target:

| Quantity | Derivation | Value | Error |
|---|---|---|---|
| Ideal bit period | 50e6 / 115200 | 434.0278 cycles | — |
| `DIV_TX` (transmit bit period) | round(434.0278) | **434** cycles | 50e6/434 = 115207.373 baud, **+0.0064 %** |
| Ideal oversample period | 50e6 / (115200 x 16) | 27.1267 cycles | — |
| `DIV_OS` (oversample tick period) | round(27.1267) | **27** cycles | — |
| `OS` (samples per bit) | fixed | **16** | — |
| Receive bit period | `DIV_OS` x `OS` = 27 x 16 | **432** cycles | 50e6/432 = 115740.74 baud, **+0.4694 %** |

The transmit and receive bit periods are deliberately **not equal** (434 vs 432).
Each is the best integer available to its own divider structure, and both are
inside the tolerance a UART link allows. §8 states the tolerance requirement.

## 3. Frame format

Line idles high. One start bit (0), eight data bits **least significant first**,
no parity, one stop bit (1). A frame is therefore 10 bit times. Frames may be
back-to-back: the start bit of the next frame may begin in the cycle
immediately after the stop bit of the previous one.

## 4. Module decomposition

| Module | Role |
|---|---|
| `uart_pkg` | The constants of §2, in one place. No logic. |
| `uart_tick_gen` | Divide-by-N strobe generator with a restart input. |
| `uart_tx` | 8N1 transmitter. |
| `uart_rx` | 16x-oversampled 8N1 receiver. |
| `uart_fifo` | Synchronous FIFO, 16 deep x 8 bits. |
| `uart_lite` | Top level: instantiates the above and owns the overrun flag. |

## 5. Interface contracts

All ports are `logic`. All modules are synchronous to `clk` on the rising edge
with a **synchronous, active-high** reset `rst`.

### 5.1 `uart_tick_gen #(parameter int N)`

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `clk`, `rst` | in | 1 | clock, synchronous active-high reset |
| `restart` | in | 1 | when high, the counter is forced to 0 for that cycle and `tick` is suppressed |
| `tick` | out | 1 | registered; high for exactly one cycle every `N` cycles |

Counting the cycle after reset release (or after a `restart` pulse) as cycle 0,
the k-th `tick` is high during cycle **N·k**. `tick` is never high in two
consecutive cycles. `N` must be at least 2.

### 5.2 `uart_tx`

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `clk`, `rst` | in | 1 | |
| `tx_data` | in | 8 | byte to send, sampled when `tx_valid & tx_ready` |
| `tx_valid` | in | 1 | host asserts to offer a byte |
| `tx_ready` | out | 1 | high only when idle; a byte is accepted on `tx_valid & tx_ready` |
| `tx_line` | out | 1 | serial output, registered, idles high |
| `tx_busy` | out | 1 | high from acceptance until the stop bit completes |

Each of the ten bit intervals is exactly `DIV_TX` = 434 clock cycles.

### 5.3 `uart_rx`

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `clk`, `rst` | in | 1 | |
| `rx_line` | in | 1 | serial input, **asynchronous** to `clk` |
| `rx_byte` | out | 8 | received byte, valid in the cycle `rx_strobe` is high |
| `rx_strobe` | out | 1 | one-cycle strobe: a frame completed with a valid stop bit |
| `rx_frame_err` | out | 1 | one-cycle strobe: a frame completed with the stop bit sampled low |
| `rx_busy` | out | 1 | high from an accepted start bit until the stop sample |

`rx_strobe` and `rx_frame_err` are **mutually exclusive**: never both high in
the same cycle.

**Sampling.** `rx_line` passes through two flip-flops before any logic reads it.
A falling edge on the synchronised line, while idle, pulses `restart` on the
receiver's `uart_tick_gen #(DIV_OS)` — that cycle is cycle 0 of the frame. The
receiver then samples the line at oversample ticks **8, 24, 40, …, 152**, i.e.
at clock cycles **216 + 432·n** for n = 0…9 measured from cycle 0:

| n | Purpose | Oversample tick | Clock cycle |
|---|---|---|---|
| 0 | start-bit confirmation | 8 | 216 |
| 1…8 | data bits d0…d7 | 24, 40, …, 136 | 648, 1080, …, 3672 |
| 9 | stop bit | 152 | 4104 |

**False start.** If the sample at tick 8 reads high, the frame is abandoned and
the receiver returns to idle without emitting `rx_strobe` or `rx_frame_err`.

### 5.4 `uart_fifo #(parameter int DEPTH = 16, parameter int W = 8)`

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `clk`, `rst` | in | 1 | |
| `wr_en` | in | 1 | write request |
| `wr_data` | in | W | |
| `rd_en` | in | 1 | pop request; ignored when empty |
| `rd_data` | out | W | head of the queue, valid whenever `!empty` (first-word fall-through) |
| `full`, `empty` | out | 1 | exact |
| `level` | out | $clog2(DEPTH)+1 | number of entries stored |

A write while `full` is **silently ignored**: stored entries are unchanged and
no flag is raised by this module. The overrun policy is the top level's (§5.5).

### 5.5 `uart_lite`

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `clk`, `rst` | in | 1 | |
| `tx_data`, `tx_valid`, `tx_ready` | | | as §5.2 |
| `rx_data` | out | 8 | FIFO head |
| `rx_valid` | out | 1 | FIFO not empty |
| `rx_ready` | in | 1 | host pops on `rx_valid & rx_ready` |
| `rx_overrun` | out | 1 | **sticky**; set when a byte completes while the FIFO is full |
| `rx_ovr_clr` | in | 1 | clears `rx_overrun` |
| `rx_frame_err` | out | 1 | one-cycle strobe, passed through from `uart_rx` |
| `tx_line` | out | 1 | |
| `rx_line` | in | 1 | |

**Overrun.** `rx_overrun` is set on any cycle where `uart_rx.rx_strobe` is high
and the FIFO is `full`, and stays set until `rx_ovr_clr`. The arriving byte is
dropped; the 16 stored bytes are unchanged and read out in the order written.
A framing error does **not** write the FIFO.

## 6. Reset

One cycle after `rst` deasserts: `tx_line` = 1, `tx_ready` = 1, the FIFO is
empty, `rx_overrun` = 0, and the receiver is idle.
