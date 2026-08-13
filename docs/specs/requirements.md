# uart_lite — numbered requirements

Status: **DRAFT** · Owner: architect_docs_lead

Every requirement carries a number, a falsifiable statement, and a stated
verification method. A testbench cites the number; a sign-off cites the number.
A requirement no test can fail is a defect in this file, not in the design.

Method vocabulary: **sim** (a directed simulation case), **sweep** (a
simulation over a parameter range), **inspection** (reading a committed file).

| ID | Title | Requirement | Method |
|---|---|---|---|
| REQ-001 | Frame format | A transmitted frame shall be, in order: `tx_line` low for one bit interval (start), then d0…d7 one bit interval each, then `tx_line` high for one bit interval (stop). Bit d0 is the least significant bit of the accepted byte. | sim |
| REQ-002 | Transmit bit period | Each of the ten bit intervals of a transmitted frame shall be exactly 434 clock cycles, **including the first**: the start bit shall span exactly 434 cycles measured from the cycle after `tx_valid & tx_ready`. A check that measures only the interval between successive bit boundaries does not discharge this row, because it is satisfied by a transmitter whose first interval is wrong and whose spacing is right. | sweep |
| REQ-003 | Transmit byte integrity | For each of the 256 values of `tx_data`, the ten bit intervals emitted shall encode that value per REQ-001. | sweep, all 256 values |
| REQ-004 | Transmit handshake | `tx_ready` shall be high only when the transmitter is idle. A byte is accepted on the cycle `tx_valid & tx_ready`; `tx_ready` shall fall in the next cycle and shall not rise again until the stop bit has completed. | sim |
| REQ-005 | Oversample tick rate | `uart_tick_gen #(N)` shall raise `tick` for exactly one cycle every N cycles, with the k-th tick during cycle N·k **counting the cycle in which `rst` or `restart` is sampled high as cycle 0**, and shall never raise `tick` in two consecutive cycles. **Verified in clock cycles, never in ticks**, and the k=1 case must be measured from the anchor cycle itself, because interval-based checks cannot distinguish the anchor conventions. | sweep over N ∈ {2, 3, 27, 434} |
| REQ-006 | Receive sample points | Measuring cycle 0 as the cycle in which the synchronised `rx_line` falling edge is detected, `uart_rx` shall sample the line at clock cycles 216 + 432·n for n = 0…9, and at no other cycles. | sim, cycle-accurate |
| REQ-007 | Receive byte integrity | For each of the 256 byte values, a well-formed frame at the nominal sender bit period shall produce `rx_strobe` high for one cycle with `rx_byte` equal to that value. | sweep, all 256 values |
| REQ-008 | False start rejection | If the sample at oversample tick 8 reads high, `uart_rx` shall return to idle and shall assert neither `rx_strobe` nor `rx_frame_err` for that frame. | sim |
| REQ-009 | Framing error | If the stop-bit sample reads low, `uart_rx` shall assert `rx_frame_err` for exactly one cycle and shall not assert `rx_strobe`. | sim |
| REQ-010 | Strobe exclusivity | `rx_strobe` and `rx_frame_err` shall never both be high in the same cycle. | sim, checked every cycle of every case |
| REQ-011 | Far-end tolerance | `uart_rx` shall receive correctly from a sender whose bit period P is any integer in **422…447** clock cycles inclusive. The window is 3 % of the ideal period 434.0278 (13.0208), rounded inward: ceil(421.007)=422, floor(447.049)=447. | sweep over P = 422…447, all 256 byte values |
| REQ-012 | Back-to-back reception | `uart_rx` shall receive an unbounded run of frames with no idle time between the stop bit of one and the start bit of the next, losing none. | sim, 64 consecutive frames |
| REQ-013 | Input synchronisation | `rx_line` shall pass through two flip-flops in the `clk` domain before any logic reads it, and shall have exactly one reader in the elaborated design. | inspection |
| REQ-014 | Overrun is flagged, never corrupting | If a byte completes while the FIFO holds 16 entries, `rx_overrun` shall be set and stay set until `rx_ovr_clr`, the arriving byte shall be discarded, and the 16 stored bytes shall be unchanged and read out in the order written. | sim |
| REQ-015 | FIFO ordering and exactness | `uart_fifo` shall return entries in the order written, shall assert `full` exactly when `level` = DEPTH and `empty` exactly when `level` = 0, and shall ignore a write while full and a pop while empty. | sweep, randomised 10 000 operations |
| REQ-016 | Reset state | One cycle after `rst` deasserts: `tx_line` = 1, `tx_ready` = 1, `rx_valid` = 0, `rx_overrun` = 0. | sim |
| REQ-017 | Loopback | With `tx_line` connected to `rx_line`, every byte written shall be read back byte-for-byte in order. **This requirement is deliberately weak**: transmitter and receiver derive their timing from the same clock, so a loopback pass is evidence about self-consistency and not about either side's agreement with the world. It never discharges REQ-011. | sim, 256 bytes |
