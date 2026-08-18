# WO-0002 sealed predictions — the uart_lite bench suite (17 defect classes)

> **FROZEN — unopened.** This file was written before any defect for this
> campaign existed. The seeder never reads it, in any state. The orchestrator
> relays nothing from it to anyone before adjudication. Opening it early voids
> the campaign's blinding and is a finding against whoever opened it.

- **State**: `FROZEN — unopened.`
- **Campaign**: `agents/handoffs/WO-0002-mutation-campaign.md`
- **Author**: dv_lead · **Journal entry**: `J-dv_lead-0002`
- **Base SHA**: the freeze commit — the commit that first stages this file. Its
  parent is `509173a`. The orchestrator records the freeze SHA in the campaign
  packet's Return log when it issues the packet.
- **Predecessor control**: `509173a`, suite green (§1).
- **Derived from**: `docs/specs/SPEC-uart_lite.md`,
  `docs/specs/requirements.md` (the defect classes) and `test/tb_*.sv` (the
  expected message text and the assertion order). **No file under `rtl/` was
  read to author this file.**

## 0. This file is never edited — not before a result, not after

The template this packet starts from
(`agents/handoffs/templates/SEALED-predictions-template.md`) carries a "flip
the State line to UNSEALED at adjudication" convention. **This campaign does
not use it.** The State line above stays `FROZEN — unopened.` permanently and
no byte of this file is ever rewritten. The unsealing, the scores, the
findings, and every wrong prediction are recorded in the campaign packet's
Return log (`WO-0002-mutation-campaign.md`) and in the adjudicating journal
entry — *beside* the seal, never inside it.

The reason is the one the charter states (L-C05): a prediction that can be
edited after its result is not a prediction. Removing the only permitted edit
removes the only way to launder one.

**Two independent copies exist.** The discriminating content of this file — the
class → expected-message mapping — is restated in `J-dv_lead-0002` in
`agents/journals/claude_dv_lead_agent.md`, which is append-only and
machine-enforced as such (PROTOCOL §5 R3). If either copy is later altered to
fit a result, the other exposes it. Anyone checking the seal's integrity runs,
at the adjudication SHA:

```
git show <freeze-sha>:agents/handoffs/WO-0002-SEALED-predictions.md | sha256sum
git show HEAD:agents/handoffs/WO-0002-SEALED-predictions.md | sha256sum
```

Byte equality is the integrity argument, and it is checkable by anyone.

## 1. Denominator — fixed here, never moves

**Measured**, not relayed: `bash test/run.sh` at `509173a`, Icarus Verilog
12.0, exit 0, 1m08s wall clock.

| bench | checks | REQ ids discharged |
|---|---|---|
| `tb_uart_tick_gen` | 28 | REQ-005 |
| `tb_uart_fifo` | 13 | REQ-015 |
| `tb_uart_tx` | 265 | REQ-001, 002, 003, 004 |
| `tb_uart_rx` | 291 | REQ-006…012 |
| `tb_uart_lite` | 12 | REQ-014, 016, 017 |
| **total** | **609** | |

A **unit** (a scorable row) is one `check()` call's printed line — the
`[REQ-nnn] PASS|FAIL  <message>` text. There are 609 of them. The 6 656
sub-comparisons inside `tb_uart_rx`'s REQ-011 sweep are **not** units: they are
`$display` lines that fold into 26 per-`P` units plus one aggregate unit. They
are quoted below where they discriminate, but they carry no score.

This denominator is fixed at freeze. A coverage gap discovered mid-campaign is
recorded as an obligation and acted on **after** adjudication.

**Surface equality, verified rather than assumed.** The freeze commit adds
`test/wave/**` and `agents/handoffs/**` only. `test/wave/**` is not compiled by
`test/run.sh` — the runner names its five benches literally at
`test/run.sh:72-76`. Therefore, before the campaign starts:

```
git diff 509173a <freeze-sha> -- rtl/ test/run.sh \
    test/tb_uart_lite.sv test/tb_uart_tick_gen.sv test/tb_uart_fifo.sv \
    test/tb_uart_tx.sv test/tb_uart_rx.sv
```

must be empty. That check, not an assumption, carries the green control forward
to the base SHA.

## 2. Three facts about the harness that shape every prediction below

**Derived by reading the benches**, with file:line, because a prediction of a
failure *message* is only as good as the reader's knowledge of which check
speaks and when (charter L-C09).

### 2.1 No bench fails fast

`check()` increments a counter and returns (`tb_uart_tick_gen.sv:40-48`, and
the identical task in each of the other four benches); `$fatal` fires only in
the summary block. Every unit a defect breaks therefore prints its own `FAIL`
line, and the predictions below name *sets* of rows rather than only the first.

### 2.2 Three sites can hang instead of failing

None is bounded by a watchdog, and neither `test/run.sh` nor any bench arms a
simulation timeout:

- `test/tb_uart_tx.sv:90-93` — `offer_byte`'s `while (!accepted)` spins on
  `tx_ready` forever.
- `test/tb_uart_lite.sv:121-124` — the same loop at the top level.
- `test/tb_uart_rx.sv:182-191` and `:202-211` — the counting branch of the
  `fork…join` in `measure_strobe_latency` / `measure_frame_err_latency` never
  terminates if the strobe never arrives, so the `join` never returns.

A defect that suppresses `tx_ready` or `rx_strobe` entirely therefore produces
**no FAIL line at all** and **no `ALL CHECKS PASSED` line**: `vvp` runs
forever. `test/run.sh`'s guards (`:60-67`) can only fire after `vvp` exits, so
they never fire. **Every mutant must be run under an external wall-clock
timeout**, and §5.6 dispositions a timeout explicitly. None of the 17 classes
below is predicted to hang; if one does, that is a finding against this seal
and is recorded as one.

### 2.3 Three rows are already vacuous at the base SHA

Sealed here, before any defect exists, rather than discovered afterwards:

- `test/tb_uart_fifo.sv:138` asserts `full === 1'b1` while its message claims
  `full asserted exactly when level=DEPTH=16 after 16 writes`. It tests one
  direction only. Class **FF-1** is predicted to leave it green.
- `test/tb_uart_lite.sv:246` asserts `rx_overrun === 1'b0` after pulsing
  `rx_ovr_clr`, with the message `rx_ovr_clr clears rx_overrun`. It cannot
  distinguish "cleared" from "was never set". Class **LT-1** is predicted to
  leave it green.
- `test/tb_uart_tx.sv:126,140` — the one directed row that checks bit **order**,
  `d0..d7 on the wire equal tx_data, LSB first (byte 8'b10100101)`, uses
  `8'hA5`, which is a **bit-reversal palindrome**: `1010_0101` reversed is
  itself. The row compares an MSB-first wire against an LSB-first expectation
  and finds them equal. Class **TX-1** is predicted to leave it green.

All three are MUST-STAY-GREEN below. **A green there is not a credit to the
suite**, and the scorecard must record each as a vacuity.

## 3. The classes

Seventeen classes across all five modules: `uart_tick_gen` 3, `uart_tx` 4,
`uart_rx` 4, `uart_fifo` 2, `uart_lite` 4. `uart_pkg` carries no logic (SPEC
§4) and is exercised through its consumers — TX-3 and RX-2 are its constant
classes.

Every class states what a conforming design does (with its spec clause), what
the defective one does instead, and then the prediction. **Predictions are
grounded in what the row asserts** — the observable — not in how I guess the
mutation will be written.

Message-quoting convention: text in `code` is the literal printed text, without
the `[REQ-nnn] FAIL  ` prefix. Where a message embeds an observed value, the
`%0d` / `%02x` field is left in place and the surrounding fixed text is what is
being predicted; the expected value is stated in the prose beside it.

---

### TG-1 — tick anchor one cycle EARLY (the historical BUG-0001 class)

**Conforming** (SPEC §5.1, REQ-005): cycle 0 is the cycle in which `rst` or
`restart` is *sampled high*; the k-th `tick` is high during cycle N·k. The
first tick lands N cycles after the anchor cycle.

**Defective**: the divider reloads to 1 instead of 0 and so reaches terminal
count one cycle early. The first tick lands at cycle N−1; every later interval
is exactly N. This is BUG-0001 verbatim, fixed at `27104a8`.

**Prediction: KILL.** 9 REQUIRED rows.

- **REQUIRED** — `tb_uart_tick_gen`, 8 rows (4 values of N × 2 anchors):
  - `N=2: first tick after reset lands at cycle N=2 (k=1 in "k-th tick at cycle N.k"); observed first tick at cycle 1`
  - the same message with `N=3 … at cycle 2`, `N=27 … at cycle 26`,
    `N=434 … at cycle 433`
  - `N=2: first tick after restart lands N=2 cycles after the restart pulse cycle (k=1 convention); observed at 1 cycles after`
  - the same message with `N=3 … at 2`, `N=27 … at 26`, `N=434 … at 433`
- **REQUIRED** — `tb_uart_tx`, 1 row:
  - `each of the 10 bit-interval boundaries (frame 0x55, transition at every boundary) lands exactly DIV_TX=434 cycles from the previous one, grid anchored one cycle after acceptance`

  *Ground*: the start interval becomes 433 cycles, so the start→d0 transition
  lands at cycle 434 while the check samples `before` at 434 and `after` at 435
  (`tb_uart_tx.sv:166,181-185`). Both read d0; the required transition is
  missing; `period_errors` sets.
- **MUST-STAY-GREEN** — 596 rows, and specifically:
  - `tb_uart_tx`'s two REQ-004 rows. The frame is 433 + 9·434 = 4339 cycles, so
    `tx_ready` rises at cycle 4340; the glitch loop stops at i = 4339
    (`tb_uart_tx.sv:199`) and the ready-rise check samples 4341 (`:205`). Both
    miss it by exactly one cycle. **This is the row pair that discriminates
    TG-1 from TG-2 and I am staking the class on it.**
  - all 291 `tb_uart_rx` rows. `uart_rx` contains a `uart_tick_gen #(DIV_OS)`
    and is equally defective, but its sample grid shifts by one cycle against a
    216-cycle mid-bit margin and a 12-cycle REQ-006 window. The historical
    record agrees: all 8 observed BUG-0001 failures were REQ-005
    (`J-dv_lead-0001`).
  - all 256 REQ-003 rows and all 3 REQ-001 rows — mid-bit sampling at
    `b·434 + 217` absorbs a one-cycle shift.
  - all 12 `tb_uart_lite` and all 13 `tb_uart_fifo` rows.
- **PERMITTED** — 4 rows: the N=2 spacing and consecutive-cycle rows on both
  anchors. At N=2 a reload-to-1 divider may degenerate rather than merely shift
  phase, and the spec does not fix which.

**Historical class — the negative-control-in-reverse.** This class's outcome is
already fixed by the record and is not in question: `tb_uart_tick_gen` caught
it on the suite's first run, 8 checks red, all REQ-005, written by a seat that
had never seen the design (`tasks/BOARD.md`; `J-dv_lead-0001`). What is *newly*
at stake is the `tb_uart_tx` row. The historical bench passed REQ-002 265/265
against this same defect, because the row as written then measured only the
interval between successive boundaries; it was re-anchored to the acceptance
cycle at `J-dv_lead-0001`. **The claim under test is that the amendment gave
the row teeth.** If that REQUIRED row stays green, the amendment did not work,
and that is a finding against me, not against the seeder.

---

### TG-2 — tick anchor one cycle LATE

**Conforming**: as TG-1.

**Defective**: cycle 0 is taken as the cycle *after* the anchor, so the first
tick lands at cycle N+1 and every later interval is exactly N. This is the
off-by-one SPEC §5.1's own prose warns about ("makes the first transmit bit
interval 435 cycles instead of 434 while every later interval stays correct").
It is the opposite sign to TG-1, and the pair exists to test whether the suite
discriminates *direction* or merely notices trouble.

**Prediction: KILL.** 10 REQUIRED rows.

- **REQUIRED** — `tb_uart_tick_gen`, the same 8 rows as TG-1, with the observed
  values one *above* N instead of one below: `…observed first tick at cycle 3`
  (N=2), `4` (N=3), `28` (N=27), `435` (N=434); and `…observed at 3 cycles
  after` / `4` / `28` / `435`.
- **REQUIRED** — `tb_uart_tx`, 2 rows:
  - `each of the 10 bit-interval boundaries (frame 0x55, transition at every boundary) lands exactly DIV_TX=434 cycles from the previous one, grid anchored one cycle after acceptance`
  - `tx_ready rises again once the stop bit has completed`

  *Ground for the second*: the frame is 435 + 9·434 = 4341 cycles, `tx_ready`
  rises at 4342, and the check samples at 4341 (`tb_uart_tx.sv:205-206`).
  **This row is the single-row difference between TG-1 and TG-2.** A campaign
  that reddens the same row set for both classes has not discriminated them,
  whatever its kill count says.
- **MUST-STAY-GREEN** — 595 rows: as TG-1, minus the row above. In particular
  `tx_ready falls the cycle after acceptance and stays low until the stop bit completes`
  stays green (the glitch loop still stops at 4339), and all 291 `tb_uart_rx`
  rows stay green.
- **PERMITTED** — 4 rows: the N=2 spacing and consecutive rows, as TG-1.

---

### TG-3 — `restart` does not suppress `tick` in the anchor cycle

**Conforming** (SPEC §5.1 port table): while `restart` is high, "the counter is
forced to 0 for that cycle and `tick` is suppressed".

**Defective**: the counter is still forced to 0, but `tick` is emitted during
the restart cycle if the divider happened to be at terminal count. The
post-restart schedule, the reset schedule and the spacing are unaffected.

**Prediction: KILL.** 4 REQUIRED rows.

- **REQUIRED** — `tb_uart_tick_gen`, 4 rows:
  - `N=2: tick suppressed during the restart pulse cycle itself`, and the same
    message for `N=3`, `N=27`, `N=434`.

  *Ground*: the bench runs into a fixed phase — `repeat (2*n + (n/2) + 1)`
  posedges, `tb_uart_tick_gen.sv:156` — then raises `restart` and samples
  `tick` at the next posedge (`:158-161`). The phase is deterministic per N, so
  this is a deterministic prediction, not a probabilistic one.
- **MUST-STAY-GREEN** — 37 rows: the other 24 `tb_uart_tick_gen` rows and all
  13 `tb_uart_fifo` rows.
- **PERMITTED** — 568 rows: all of `tb_uart_tx`, `tb_uart_rx`, `tb_uart_lite`.
  *Ground for permitting rather than predicting*: the specification does not
  state how `uart_tx` and `uart_rx` consume `tick`, so whether one extra tick
  in the restart cycle perturbs a frame is **not derivable from the spec**, and
  I will not seal a prediction I could only have derived from the design. A red
  anywhere in this block is neither a kill nor a finding for this class; the
  adjudication records what happened and the SO- coverage arithmetic uses it.

---

### TX-1 — data bits transmitted MSB-first

**Conforming** (SPEC §3, REQ-001): one start bit (0), eight data bits **least
significant first**, one stop bit (1).

**Defective**: the eight data bits are emitted d7…d0. Framing bits, bit period
and handshake are unaffected.

**Prediction: KILL.** 242 REQUIRED rows.

- **REQUIRED** — `tb_uart_tx`, 241 rows:
  - `each of the 10 bit-interval boundaries (frame 0x55, transition at every boundary) lands exactly DIV_TX=434 cycles from the previous one, grid anchored one cycle after acceptance` — 1 row. *Ground*: 0x55 reversed is 0xAA, whose first-emitted bit (d7 = 0) equals the start bit and whose last-emitted bit (d0 = 1) equals the stop bit, so boundaries 1 and 9 carry no transition — the exact trap this bench's own header records at `tb_uart_tx.sv:150-154`.
  - `byte 0x%02x transmitted with correct frame format` — **240 of the 256**
    REQ-003 rows. The first red is `byte 0x01`.
- **REQUIRED** — `tb_uart_lite`, 1 row:
  - `loopback: all 256 bytes read back byte-for-byte in order (240 mismatches)`
    — the count is part of the prediction.
- **MUST-STAY-GREEN** — 367 rows, and by name:
  - `d0..d7 on the wire equal tx_data, LSB first (byte 8'b10100101)` — the
    vacuity of §2.3. **The only row in the suite whose text claims to check bit
    order cannot detect this defect**, because `8'hA5` is a bit-reversal
    palindrome.
  - the **16** bit-palindromic REQ-003 rows, which stay green:
    `0x00, 0x18, 0x24, 0x3c, 0x42, 0x5a, 0x66, 0x7e, 0x81, 0x99, 0xa5, 0xbd,
    0xc3, 0xdb, 0xe7, 0xff`. A campaign that reports "REQ-003 red" without
    noticing that exactly 16 rows survived has not read its own evidence.
  - `start bit is low`, `stop bit is high`, both REQ-004 rows.
  - all 28 `tb_uart_tick_gen`, 13 `tb_uart_fifo` and 291 `tb_uart_rx` rows —
    the receiver bench's stimulus is its own model transmitter, never
    `uart_tx` (`tb_uart_rx.sv:13-16`) — and the remaining 11 `tb_uart_lite`
    rows.
- **PERMITTED**: none.

---

### TX-2 — the frame is one full bit period short (no stop interval)

**Conforming** (SPEC §5.2, REQ-002/REQ-004): ten bit intervals of exactly 434
cycles each; `tx_ready` rises at cycle `1 + 10·DIV_TX` from acceptance.

**Defective**: the transmitter completes after nine intervals — start plus
eight data bits — and returns to idle. `tx_line` still reads high where the
stop bit would have been, because idle and stop are the same level; only the
handshake moves. Bit period, bit order and byte value are unaffected.

**Prediction: KILL, with exactly one red row in 609.**

- **REQUIRED** — `tb_uart_tx`, 1 row:
  - `tx_ready falls the cycle after acceptance and stays low until the stop bit completes`

  *Ground*: `tx_ready` rises at cycle 3907; the glitch loop samples every cycle
  from 1 to 4339 (`tb_uart_tx.sv:199-202`) and sets `ready_glitch` at 3907.
- **MUST-STAY-GREEN** — 608 rows. Specifically:
  - all three REQ-001 rows, **including `stop bit is high`** — the mid-bit
    sample for interval 9 falls at cycle 4123, where the line is idle high. The
    row that names the stop bit cannot see the stop bit's absence.
  - the REQ-002 boundary row: boundary 9 still carries a d7→high transition
    (d7 of 0x55 is 0) and boundary 10 still finds the line high
    (`tb_uart_tx.sv:172-176`).
  - all 256 REQ-003 rows.
  - `tx_ready rises again once the stop bit has completed` — it rose early, so
    at cycle 4341 it is high and the row passes.
  - `tb_uart_lite`'s REQ-017 loopback row: the receiver samples its stop bit at
    cycle 4104 of its own grid, finds the idle line high, and every byte still
    round-trips.
- **PERMITTED**: none.

**This is the sharpest claim in the seal.** One row out of 609, named in
advance, against a defect that three differently-worded rows *appear* to cover.
If any other row reddens, my model of this suite is wrong and the campaign has
found something better than a kill.

---

### TX-3 — transmit bit period one cycle short (433 instead of 434)

**Conforming** (SPEC §2, REQ-002): `DIV_TX` = 434.

**Defective**: every one of the ten intervals is 433 cycles. Bit order, frame
structure and byte value are unaffected.

**Prediction: KILL.** 2 REQUIRED rows.

- **REQUIRED** — `tb_uart_tx`, 2 rows:
  - `each of the 10 bit-interval boundaries (frame 0x55, transition at every boundary) lands exactly DIV_TX=434 cycles from the previous one, grid anchored one cycle after acceptance`
  - `tx_ready falls the cycle after acceptance and stays low until the stop bit completes` — `tx_ready` rises at cycle 4331, inside the glitch loop's 1…4339 window.
- **MUST-STAY-GREEN** — 607 rows. Specifically:
  - all 256 REQ-003 rows and all 3 REQ-001 rows: accumulated drift at the last
    sample is 9 cycles against a 217-cycle half-bit margin.
  - `tx_ready rises again once the stop bit has completed` — high at 4341.
  - `tb_uart_lite`'s REQ-017 loopback row: 433 is inside the receiver's
    REQ-011 tolerance window of 422…447, so the round trip still works. **A
    green loopback row against a transmitter that is out of specification is
    exactly the weakness REQ-017's own text declares** ("deliberately weak …
    evidence about self-consistency and not about either side's agreement with
    the world"), and the scorecard should quote it.
  - all 291 `tb_uart_rx`, 28 `tb_uart_tick_gen`, 13 `tb_uart_fifo` rows.
- **PERMITTED**: none.

---

### TX-4 — `tx_busy` never asserts *(silently-always-pass; negative control 1)*

**Conforming** (SPEC §5.2): `tx_busy` is high from acceptance until the stop bit
completes.

**Defective**: `tx_busy` is tied low. Every other transmitter behaviour —
frame, period, handshake, byte — is untouched.

**Prediction: SURVIVE. All 609 rows stay green.**

- **REQUIRED**: none.
- **MUST-STAY-GREEN**: all 609, and one row by name:
  - `[REQ-004] PASS  post-reset: tx_busy is low (idle)` (`tb_uart_tx.sv:122`).
- **The ground — what leaves the suite blind.** `tx_busy` is read by exactly
  one of the 609 rows, and that row reads it in the one state where the correct
  and the defective design agree: at reset, when `tx_busy` is *supposed* to be
  low. `tx_busy` is not a port of `uart_lite` (SPEC §5.5), so no top-level
  bench can reach it, and `tb_uart_rx` never instantiates `uart_tx`. **No row
  anywhere in the suite samples `tx_busy` while a frame is in flight.** The
  requirement is named in the spec and unchecked by the suite.

This class discharges PROTOCOL §10's owed **silently-always-pass** obligation:
the design is wrong, the suite is green, and a named row passes while asserting
something that is true only by coincidence. **Expect it to look quiet. Do not
strengthen it.** A seeder who makes this one louder has destroyed the
measurement.

---

### RX-1 — the receiver samples at the bit boundary, not mid-bit

**Conforming** (SPEC §5.3, REQ-006): samples at oversample ticks 8, 24, …, 152
— clock cycles 216 + 432·n for n = 0…9, i.e. the middle of each bit cell.

**Defective**: samples at oversample ticks 0, 16, …, 144 — clock cycles 432·n —
the leading edge of each cell. The oversample rate, the frame length and the
start-edge detection are unaffected.

**Prediction: KILL.** 276 REQUIRED rows.

Sample n therefore lands at cycle 432·n + 2 measured from the bench's driven
falling edge (the +2 is the two-flop synchroniser, SPEC §5.3).

- **REQUIRED** — `tb_uart_rx`, 276 rows:
  - `clean frame: elapsed cycles from the falling edge to rx_strobe is %0d, within the predicted window [4105,4116] (stop-bit sample at cycle 4104 + synchroniser + registered-output margin)` — expect a value near **3890**, roughly 216 low.
  - `bad-stop frame: elapsed cycles from the falling edge to rx_frame_err is %0d, within the predicted window [4105,4116]` — same shift.
  - both REQ-008 rows —
    `a brief low glitch that returns high before the confirmation sample produces neither rx_strobe nor rx_frame_err`
    and
    `receiver has returned to idle (rx_busy low) after an abandoned false start`.
    *Ground*: the confirmation sample now lands at cycle 2, inside the 40-cycle
    glitch, so the start is confirmed, the frame proceeds on an idle line and
    strobes ~3890 cycles later — long after the bench samples `rx_busy` at
    cycle 490 (`tb_uart_rx.sv:255-262`).
  - `byte 0x%02x received correctly at the nominal sender bit period` — **255
    of the 256** REQ-007 rows; the first red is `byte 0x00`.
  - `64 back-to-back frames all produced a strobe (observed %0d strobe events)`
    — expect a value well under 64.
  - `P=%0d: all 256 byte values received correctly (%0d mismatches)` for
    **P = 433 … 447 — and for no smaller P**: 15 rows.
  - `far-end tolerance window P=422..447, all 256 byte values each: %0d/%0d checks failed`
- **MUST-STAY-GREEN** — 319 rows, and by name:
  - `byte 0xff received correctly at the nominal sender bit period` — **the one
    REQ-007 row that survives.** *Derivation*: at P = 434 the samples read
    cells 0,1,1,2,3,4,5,6,7,8, so the received byte is
    `{d6,d5,d4,d3,d2,d1,d0,d0}` and the stop sample reads d7. Correct reception
    therefore requires all eight bits equal *and* d7 = 1 — only `0xFF`. `0x00`
    reads a low stop and raises a framing error instead.
  - `P=%0d: all 256 byte values received correctly (%0d mismatches)` for
    **P = 422 … 432**, 11 rows. *Derivation*: sample n lands inside cell n iff
    `0 ≤ (432−P)·n + 2 < P` for n ≤ 9; the left inequality holds for every
    P ≤ 432 and fails first at P = 433. **The boundary between the green and
    red halves of the tolerance sweep is P = 432/433, and if it lands anywhere
    else this prediction was wrong.**
  - `rx_strobe and rx_frame_err never both high in the same cycle, checked every cycle of every case in this file (%0d violations)` — exclusivity is structural and untouched.
  - all 28 `tb_uart_tick_gen`, 13 `tb_uart_fifo` and 265 `tb_uart_tx` rows.
- **PERMITTED** — 14 rows: the two REQ-009 rows and all 12 `tb_uart_lite` rows.
  The spurious frame confirmed during REQ-008 is still in flight when REQ-009
  begins driving, and that seam's outcome is a cascade rather than a derivation.

---

### RX-2 — the oversample divisor is 26 instead of 27

**Conforming** (SPEC §2): `DIV_OS` = 27, `OS` = 16, receive bit period 432.

**Defective**: `DIV_OS` = 26, so the receive bit period is 416 and the sample
grid is 208 + 416·n. Mid-bit sampling, tick-8 confirmation, frame structure and
sample *count* are all unaffected — only the rate is wrong.

**Prediction: KILL — and this is the class where the seal earns its keep,
because 598 of the 609 rows stay green.**

Sample n lands at cycle 210 + 416·n from the driven falling edge.

- **REQUIRED** — `tb_uart_rx`, 11 rows:
  - `clean frame: elapsed cycles from the falling edge to rx_strobe is %0d, within the predicted window [4105,4116] (stop-bit sample at cycle 4104 + synchroniser + registered-output margin)` — the stop sample moves to cycle 3954, so expect a value near **3955**, far below 4105.
  - `bad-stop frame: elapsed cycles from the falling edge to rx_frame_err is %0d, within the predicted window [4105,4116]`
  - `P=%0d: all 256 byte values received correctly (%0d mismatches)` for
    **P = 440, 441, 442, 443, 444, 445, 446, 447 — and for no smaller P**:
    8 rows.
  - `far-end tolerance window P=422..447, all 256 byte values each: %0d/%0d checks failed`
- **MUST-STAY-GREEN** — 598 rows, and by name:
  - **all 256** `byte 0x%02x received correctly at the nominal sender bit period`
    rows. REQ-007 drives P = 434; sample n lands 210 − 18·n cycles into the
    sender's cell, inside it for every n ≤ 9. **The 256-row sweep this suite is
    proudest of cannot see a 4 % error in the receiver's clock.**
  - `P=%0d: all 256 byte values received correctly (%0d mismatches)` for
    **P = 422 … 439**, 18 rows.
  - `64 back-to-back frames all produced a strobe (observed %0d strobe events)`
    — REQ-012 also runs at P = 434.
  - both REQ-008 rows (the confirmation sample at cycle 210 still finds the
    40-cycle glitch gone), both REQ-009 rows, the REQ-010 exclusivity row.
  - all 265 `tb_uart_tx`, 28 `tb_uart_tick_gen`, 13 `tb_uart_fifo` rows.
  - all 12 `tb_uart_lite` rows, **including the REQ-017 loopback row**: the
    transmitter sends at 434 and the receiver's 416-cycle grid still lands
    inside every cell, so 256 bytes round-trip perfectly through a receiver
    running 3.7 % fast.
- **PERMITTED**: none.

**The derivation, so the P = 439/440 boundary is falsifiable rather than
decorative.** Sample n must land inside sender cell n:
`0 ≤ 210 + 416·n − P·n < P` for n = 0…9. The left inequality binds at n = 9 and
gives `P ≤ 416 + 210/9 = 439.3`, so P = 439 is the last value that works and
P = 440 the first that fails. If the boundary lands anywhere else, this
prediction was wrong and the adjudication says so.

---

### RX-3 — false-start rejection removed

**Conforming** (SPEC §5.3 "False start", REQ-008): if the sample at oversample
tick 8 reads high, the frame is abandoned and the receiver returns to idle,
asserting neither `rx_strobe` nor `rx_frame_err`.

**Defective**: the tick-8 sample is taken but its result is not acted on; the
frame proceeds regardless. Sample timing is unchanged.

**Prediction: KILL.** 2 REQUIRED rows.

- **REQUIRED** — `tb_uart_rx`, 2 rows:
  - `a brief low glitch that returns high before the confirmation sample produces neither rx_strobe nor rx_frame_err`
  - `receiver has returned to idle (rx_busy low) after an abandoned false start`

  *Ground for the second*: the bench samples `rx_busy` 490 cycles after the
  glitch (`tb_uart_rx.sv:255-262`) and the bogus frame runs to ~4106 cycles, so
  the receiver is still busy.
- **MUST-STAY-GREEN** — 318 rows: all 28 `tb_uart_tick_gen`, 13
  `tb_uart_fifo`, 265 `tb_uart_tx` and all 12 `tb_uart_lite` rows. The
  top-level bench drives only well-formed frames and a clean loopback line, so
  no false start ever occurs there.
- **PERMITTED** — 289 rows: the rest of `tb_uart_rx`. The abandoned frame
  completes as `0xFF` with a high stop bit and emits a spurious strobe roughly
  4106 cycles later, landing inside the REQ-009 case's window; the cascade from
  there is real but not derivable with the precision a REQUIRED cell demands.

**Note the pairing with RX-1.** Both classes redden the same two REQ-008 rows.
RX-1 reddens 274 more; RX-3 reddens none. If the campaign returns the same red
set for both, the receiver bench is detecting "the start logic is disturbed"
and nothing finer — which is precisely what the message-level seal exists to
expose.

---

### RX-4 — the input synchroniser is one flip-flop, not two *(negative control 2)*

**Conforming** (SPEC §5.3, REQ-013): `rx_line` passes through **two**
flip-flops in the `clk` domain before any logic reads it.

**Defective**: one flip-flop. The design still functions in simulation; it has
simply lost its metastability margin, and everything it does happens one cycle
earlier.

**Prediction: SURVIVE. All 609 rows stay green.**

- **REQUIRED**: none.
- **MUST-STAY-GREEN**: all 609, and two rows by name:
  - `[REQ-006] PASS  clean frame: elapsed cycles from the falling edge to rx_strobe is %0d, within the predicted window [4105,4116] (stop-bit sample at cycle 4104 + synchroniser + registered-output margin)` — the observed value drops by one and stays inside a window twelve cycles wide.
  - `[REQ-011] PASS  far-end tolerance window P=422..447, all 256 byte values each: %0d/%0d checks failed` — a one-cycle shift against a 216-cycle margin.
- **The ground — what leaves the suite blind.** REQ-013's Method column is
  **inspection**, not simulation, and `tb_uart_lite` says so in its own output:
  `[REQ-013] SKIP  inspection-only per requirements.md Method column -- not a simulation check`
  (`tb_uart_lite.sv:254`). That line is not a check and is not one of the 609.
  The only row whose timing could have noticed the missing cycle is REQ-006,
  and its window was deliberately widened to `[4105, 4116]` to absorb exactly
  this latency — the bench's own header explains why (`tb_uart_rx.sv:148-157`).

  The finding this class produces is not "the bench is bad" but **"REQ-013 has
  no executable owner"**: a requirement verified by inspection is verified by
  whoever last inspected it, and no `SO-` may record it as a discharged row. It
  is a declared gap.

---

### FF-1 — the FIFO's `full` flag is off by one entry

**Conforming** (SPEC §5.4, REQ-015): `full` is asserted **exactly** when
`level` = DEPTH = 16; a write while full is ignored.

**Defective**: `full` asserts at `level` = 15, so the FIFO stores at most 15
entries. `empty`, ordering and first-word fall-through are unaffected.

**Prediction: KILL.** 10 REQUIRED rows.

- **REQUIRED** — `tb_uart_fifo`, 7 rows:
  - `level==DEPTH=16 after 16 writes`
  - `a write while full is silently ignored: level, full, and head unchanged`
  - `entries read back in the exact order written (16-entry run)`
  - `rd_data equals model head (first-word fall-through) over 10000 random operations (%0d mismatches)`
  - `full asserted exactly when level=DEPTH over 10000 random operations (%0d mismatches)`
  - `empty asserted exactly when level=0 over 10000 random operations (%0d mismatches)`
  - `level tracks the reference model exactly over 10000 random operations (%0d mismatches)`
- **REQUIRED** — `tb_uart_lite`, 3 rows:
  - `rx_overrun is not set after exactly 16 bytes (FIFO exactly full, not yet overrun)`
  - `the 16 stored bytes are unchanged and read out in the order written (dropped 17th byte and the framing-error byte are absent)`
  - `FIFO is empty again after draining exactly 16 entries`
- **MUST-STAY-GREEN** — 590 rows, and by name:
  - `full asserted exactly when level=DEPTH=16 after 16 writes`
    (`tb_uart_fifo.sv:138`) — the vacuity of §2.3. Its message claims
    exactness; its assertion is `full === 1'b1`. Under a FIFO that fills at 15,
    `full` is high after 16 write attempts and the row passes. **A green here
    is evidence of nothing and must be recorded as a vacuity, not as a
    MUST-STAY-GREEN credit.**
  - `post-reset: empty is asserted`, `post-reset: level is 0`,
    `post-reset: full is not asserted`,
    `empty asserted exactly when level=0 after draining all entries`,
    `a pop while empty is silently ignored: empty and level unchanged`.
  - all 28 `tb_uart_tick_gen`, 265 `tb_uart_tx`, 291 `tb_uart_rx` rows.
- **PERMITTED** — 9 rows: the remaining `tb_uart_lite` rows, whose behaviour
  against a FIFO one entry shallower is not worth staking a cell on.

---

### FF-2 — a write while full is accepted and overwrites the oldest entry

**Conforming** (SPEC §5.4): "A write while `full` is **silently ignored**:
stored entries are unchanged and no flag is raised by this module."

**Defective**: a write while full is accepted; the oldest entry is dropped and
the head advances. `level` stays 16, `full` stays high, `empty` is unaffected.

**Prediction: KILL.** 4 REQUIRED rows.

- **REQUIRED** — `tb_uart_fifo`, 3 rows:
  - `a write while full is silently ignored: level, full, and head unchanged`
    — the head reads `0xFF` instead of `0x00` (`tb_uart_fifo.sv:143-146`).
  - `entries read back in the exact order written (16-entry run)`
  - `rd_data equals model head (first-word fall-through) over 10000 random operations (%0d mismatches)`
- **REQUIRED** — `tb_uart_lite`, 1 row:
  - `the 16 stored bytes are unchanged and read out in the order written (dropped 17th byte and the framing-error byte are absent)`
- **MUST-STAY-GREEN** — 605 rows, and by name:
  `full asserted exactly when level=DEPTH over 10000 random operations (%0d mismatches)`,
  `level tracks the reference model exactly over 10000 random operations (%0d mismatches)`,
  `empty asserted exactly when level=0 over 10000 random operations (%0d mismatches)`,
  `level==DEPTH=16 after 16 writes`,
  `rx_overrun is not set after exactly 16 bytes (FIFO exactly full, not yet overrun)`,
  `rx_overrun is set when a 17th byte completes while the FIFO is full`,
  and all of `tb_uart_tick_gen`, `tb_uart_tx`, `tb_uart_rx`.
- **PERMITTED**: none.

**The pairing with FF-1 is the point.** Two defects in the same flag — one
moving `level`, one moving the data — must redden **different** row sets. If
FF-1 and FF-2 produce the same red set, the FIFO bench is detecting "something
is wrong near the full path" and nothing finer.

---

### LT-1 — `rx_overrun` is a one-cycle strobe, not sticky

**Conforming** (SPEC §5.5, REQ-014): `rx_overrun` is **sticky** — set when a
byte completes while the FIFO is full, and it "stays set until `rx_ovr_clr`".

**Defective**: `rx_overrun` pulses for one cycle at the overrun event and
self-clears. The byte is still dropped, the stored bytes are still intact, and
`rx_ovr_clr` still acts on a flag that is already low.

**Prediction: KILL.** 3 REQUIRED rows, all in `tb_uart_lite`.

- **REQUIRED**:
  - `rx_overrun is set when a 17th byte completes while the FIFO is full` — the
    bench samples 30 cycles later (`tb_uart_lite.sv:208-211`).
  - `rx_overrun stays set across a subsequent framing error while full`
  - `rx_overrun remains set after draining the FIFO (sticky until rx_ovr_clr)`
- **MUST-STAY-GREEN** — 606 rows, and by name:
  - `rx_ovr_clr clears rx_overrun` (`tb_uart_lite.sv:246`) — the vacuity of
    §2.3. It asserts `rx_overrun === 1'b0` after the clear pulse, and the flag
    is already 0. **The row passes against a design that has no flag to
    clear.** Recorded as a vacuity, not a credit.
  - `rx_overrun is not set after exactly 16 bytes (FIFO exactly full, not yet overrun)`,
    `one cycle after rst deasserts: rx_overrun = 0`, the REQ-017 loopback row,
    and all four other benches.
- **PERMITTED**: none.

---

### LT-2 — a framing error writes the FIFO *(negative control 3)*

**Conforming** (SPEC §5.5): "A framing error does **not** write the FIFO."

**Defective**: a completed frame with a low stop bit pushes its byte into the
FIFO as if it were valid. `rx_frame_err` is still asserted, `rx_strobe` is
still withheld, overrun behaviour is unchanged.

**Prediction: SURVIVE. All 609 rows stay green.**

- **REQUIRED**: none.
- **MUST-STAY-GREEN**: all 609, and one row by name:
  - `[REQ-014] PASS  the 16 stored bytes are unchanged and read out in the order written (dropped 17th byte and the framing-error byte are absent)`
- **The ground — worse than a gap.** The suite contains exactly one framing
  error at the top level: the `8'hEE` bad-stop frame at `tb_uart_lite.sv:217`.
  It is sent **while the FIFO already holds 16 entries**, so the illegal write
  is swallowed by the FIFO's own write-while-full rule before it can corrupt
  anything. The row quoted above asserts, in its own parenthetical, that "the
  framing-error byte" is absent — and it *is* absent, for a reason that has
  nothing to do with the rule the row claims to be checking. **There is no case
  anywhere in the 609 in which a framing error arrives at a FIFO with room in
  it.** The clause is stated in the spec, quoted in a check's message, and
  untested.

This is the class that shows the campaign distinguishes a suite with teeth from
an apparatus that reddens at anything: the RTL is genuinely wrong against a
numbered spec clause, and a check whose text quotes that clause goes green.

---

### LT-3 — `rx_valid` is asserted when the FIFO is empty

**Conforming** (SPEC §5.5): `rx_valid` = FIFO not empty; the host pops on
`rx_valid & rx_ready`.

**Defective**: `rx_valid` is driven from the FIFO's `empty` flag rather than
its complement, so it is high exactly when there is nothing to read. `rx_data`,
the FIFO and the receiver are unaffected.

**Prediction: KILL.** 3 REQUIRED rows, all in `tb_uart_lite`.

- **REQUIRED**:
  - `one cycle after rst deasserts: rx_valid = 0 (FIFO empty)`
  - `loopback: all 256 bytes read back byte-for-byte in order (%0d mismatches)`
    — the loop waits on `rx_valid` (`tb_uart_lite.sv:162-167`), which is already
    high before the byte arrives, so it reads the empty FIFO's `rx_data`
    immediately. Expect a mismatch count at or near 256.
  - `FIFO is empty again after draining exactly 16 entries` — the row asserts
    `rx_valid === 1'b0` on an empty FIFO.
- **MUST-STAY-GREEN** — 606 rows: the other three REQ-016 rows; the whole
  REQ-014 overrun sequence apart from the row above (the drain loop pulses
  `rx_ready` unconditionally rather than gating on `rx_valid`,
  `tb_uart_lite.sv:224-232`, so it still empties the FIFO in order); and all
  four other benches.
- **PERMITTED**: none.

---

### LT-4 — `tx_line` does not idle high out of reset

**Conforming** (SPEC §6, REQ-016): one cycle after `rst` deasserts,
`tx_line` = 1, `tx_ready` = 1, the FIFO is empty, `rx_overrun` = 0, and the
receiver is idle.

**Defective**: `tx_line` resets to 0 and stays low until the first frame is
requested, after which the transmitter behaves normally.

**Prediction: KILL.** 2 REQUIRED rows.

- **REQUIRED**:
  - `tb_uart_lite`: `one cycle after rst deasserts: tx_line = 1`
  - `tb_uart_tx`: `post-reset: tx_line idles high`
- **MUST-STAY-GREEN** — 332 rows: all 291 `tb_uart_rx` rows (its `rx_line` is
  driven by the bench's own model transmitter and never by `uart_tx`, so a low
  idle line at the top level cannot reach it), all 28 `tb_uart_tick_gen` and
  all 13 `tb_uart_fifo` rows.
- **PERMITTED** — 275 rows: the rest of `tb_uart_tx` and `tb_uart_lite`. A line
  held low out of reset looks like a start bit to the loopback receiver, and
  the resulting cascade through REQ-017 and REQ-014 is real but not worth
  staking a cell on.

---

## 4. Summary table — the mapping, sealed

| id | module | class | verdict | REQUIRED | the discriminating message |
|---|---|---|---|---|---|
| TG-1 | tick_gen | anchor one cycle early (BUG-0001) | KILL | 9 | `…observed first tick at cycle 433` (N=434) |
| TG-2 | tick_gen | anchor one cycle late | KILL | 10 | `tx_ready rises again once the stop bit has completed` |
| TG-3 | tick_gen | tick not suppressed during restart | KILL | 4 | `N=%0d: tick suppressed during the restart pulse cycle itself` |
| TX-1 | tx | data bits MSB-first | KILL | 242 | `loopback: all 256 bytes read back byte-for-byte in order (240 mismatches)` |
| TX-2 | tx | frame one bit period short | KILL | **1** | `tx_ready falls the cycle after acceptance and stays low until the stop bit completes` |
| TX-3 | tx | bit period 433, not 434 | KILL | 2 | `…lands exactly DIV_TX=434 cycles from the previous one…` |
| TX-4 | tx | `tx_busy` never asserts | **SURVIVE** | 0 | stays green: `post-reset: tx_busy is low (idle)` |
| RX-1 | rx | samples at the bit boundary, not mid-bit | KILL | 276 | green boundary at `P=432` / red from `P=433` |
| RX-2 | rx | `DIV_OS` = 26 | KILL | 11 | green boundary at `P=439` / red from `P=440` |
| RX-3 | rx | false start not rejected | KILL | 2 | `a brief low glitch that returns high before the confirmation sample…` |
| RX-4 | rx | one synchroniser flop, not two | **SURVIVE** | 0 | stays green: REQ-013 has no executable owner |
| FF-1 | fifo | `full` off by one entry | KILL | 10 | `level==DEPTH=16 after 16 writes` |
| FF-2 | fifo | write while full overwrites | KILL | 4 | `a write while full is silently ignored: level, full, and head unchanged` |
| LT-1 | lite | `rx_overrun` not sticky | KILL | 3 | `rx_overrun remains set after draining the FIFO (sticky until rx_ovr_clr)` |
| LT-2 | lite | framing error writes the FIFO | **SURVIVE** | 0 | stays green: `…the framing-error byte are absent` |
| LT-3 | lite | `rx_valid` inverted | KILL | 3 | `one cycle after rst deasserts: rx_valid = 0 (FIFO empty)` |
| LT-4 | lite | `tx_line` idles low out of reset | KILL | 2 | `post-reset: tx_line idles high` |

14 KILL, 3 SURVIVE. **If all 17 kill, this seal was wrong three times.**

## 5. The scoring rule — written before any result exists

1. **KILL** requires *every* REQUIRED row for that class to go red, each
   carrying the message named above. Where a message embeds an observed value
   (`%0d`, `%02x`), the fixed text must match and the value is compared against
   the stated expectation; a row that matches its text but carries an
   unexpected value is recorded as a **PARTIAL**, named, never silently counted
   as a kill.
2. A REQUIRED row that stays green is a **MISS**, named individually with the
   row, the class, and the ground — the reason the row could not see the
   defect. A miss is a finding against the bench and, where this seal claimed
   the row would fire, against me.
3. A red in **MUST-STAY-GREEN** is a **FINDING**, not a kill (PROTOCOL §10).
   Each is named individually with the row and the class.
4. **PERMITTED** rows carry no score in either direction and are reported as
   observations only.
5. A **SURVIVE** class is scored by the same rule from the other side: any red
   anywhere in the 609 means the prediction was wrong. It is recorded as
   `PREDICTION WRONG` with the row that reddened. It is not retro-fitted into a
   kill, and this file is not edited to accommodate it.
6. **Non-termination**: a mutant whose run does not terminate under the
   campaign's external wall-clock timeout is dispositioned `NO-VERDICT — HANG`,
   with the hang site named from §2.2. It is never counted as a kill: a suite
   that wedges has not detected anything, it has stopped.
7. **Build failure**: `NO-VERDICT — BUILD`, returned to the seeder for a
   disclosed build-only repair. Never a kill.
8. **An equivalent-mutant claim is a proof obligation**, discharged only by an
   argument covering the whole legal stimulus space — never by the suite's
   failure to kill.
9. **No ratio stands in for the dispositions.** A figure of the form "n of 17
   killed" may appear only alongside the individually named disposition of
   every single non-kill: which class, which row, which ground. A campaign
   reported as a percentage has reported nothing. The vacuous rows of §2.3 are
   reported as vacuities even when green, because a green vacuity is not a
   credit to the suite.
10. **The scorecard states what the campaign licenses and what it does not.**
    Seventeen classes over 609 rows is evidence about seventeen classes. It is
    not a detection rate, and no `SO-` may quote it as one.

## 6. What the seeder must not be told

Swept against the brief, the commit subject and every relayed message before
issue:

- The class → row mapping (which units each class reddens).
- The MUST-STAY-GREEN columns, and in particular the three SURVIVE classes
  (TX-4, RX-4, LT-2) — the seeder must not learn that any class is expected to
  survive, or it will be tempted to make it louder.
- Every expected failure message, and the counts embedded in them: the 240
  mismatches, the 16 palindromic bytes, the `P = 432/433` and `P = 439/440`
  boundaries, the single surviving `0xff` row.
- The three vacuous rows of §2.3.
- The three non-termination sites of §2.2.
- The entire contents of `test/**`, which is why the brief's allowlist excludes
  it by construction rather than by enumeration.
