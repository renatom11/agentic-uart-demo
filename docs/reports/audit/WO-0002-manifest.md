# WO-0002 defect manifest - the uart_lite mutation campaign

Author: auditor (the campaign's no-stake seeder, blinded).
Base pin: `c7762b0`, the freeze commit that stages `WO-0002-mutation-campaign.md`
and its sealed companion. Every diff in this file applies to that tree.

**Status: authored before any run executed.** No mutant has been branched, no
suite has been invoked on any of these diffs, and no result exists. Nothing in
this file may be revised after a result exists except a disclosed build-only
repair (WO-0002 §1 bar 8; PROTOCOL §10).

**This manifest contains no prediction about `test/**`.** I have not read the
benches, and a statement about what they would do is not one I am in a position
to make. Each class carries a judgement about whether the defect is *detectable
in principle from the design's observable behaviour* - a statement about the
design, which is wanted - and nothing else.


## 1. What was seeded

19 classes: the 17 defect intents `WO-0002-mutation-campaign.md` §2 names,
plus 2 near-miss controls that are not defects. Every one applies cleanly to the
base pin and compiles under Icarus Verilog 12.0; **no build-only repair was
needed by any of them.**

`M-nn` is the index the seeding work order asked for; the campaign id (`TG-1` ...)
is the id the sealed predictions are keyed to and the id each hunk's marker
comment carries. **Where the two disagree, the campaign id governs** - renumbering
would make the seal unmatchable.

| M | id | module | file | class | control? |
|---|---|---|---|---|---|
| M-01 | `TG-1` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | off-by-one in a phase (anchor), wrong reload constant | defect |
| M-02 | `TG-2` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | off-by-one in a phase (anchor), opposite sign to M-01 | defect |
| M-03 | `TG-3` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | dropped side condition on a control input | defect |
| M-04 | `TX-1` | `uart_tx` | `rtl/uart_tx.sv` | wrong bit order | defect |
| M-05 | `TX-2` | `uart_tx` | `rtl/uart_tx.sv` | boundary condition on a terminal count | defect |
| M-06 | `TX-3` | `uart_tx` | `rtl/uart_tx.sv` | corrupted timing parameter | defect |
| M-07 | `TX-4` | `uart_tx` | `rtl/uart_tx.sv` | **silently-always-pass** - an output stuck at its inactive value | defect |
| M-08 | `RX-1` | `uart_rx` | `rtl/uart_rx.sv` | off-by-eight in a sample phase (mis-selected sample point) | defect |
| M-09 | `RX-2` | `uart_rx` | `rtl/uart_rx.sv` | corrupted timing parameter | defect |
| M-10 | `RX-3` | `uart_rx` | `rtl/uart_rx.sv` | weakened check - a guard evaluated and not acted on | defect |
| M-11 | `RX-4` | `uart_rx` | `rtl/uart_rx.sv` | removed CDC stage (structural) | defect |
| M-12 | `FF-1` | `uart_fifo` | `rtl/uart_fifo.sv` | boundary condition on a flag (off-by-one) | defect |
| M-13 | `FF-2` | `uart_fifo` | `rtl/uart_fifo.sv` | inverted policy on a full-condition write | defect |
| M-14 | `LT-1` | `uart_lite` | `rtl/uart_lite.sv` | lost state - a sticky flag made transient | defect |
| M-15 | `LT-2` | `uart_lite` | `rtl/uart_lite.sv` | widened enable condition | defect |
| M-16 | `LT-3` | `uart_lite` | `rtl/uart_lite.sv` | inverted polarity | defect |
| M-17 | `LT-4` | `uart_lite` (reset value lives in `uart_tx`) | `rtl/uart_tx.sv` | wrong reset state | defect |
| M-18 | `NM-1` | `uart_fifo` | `rtl/uart_fifo.sv` | **control, not a defect** | **control** |
| M-19 | `NM-2` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | **control, not a defect** | **control** |

All five modules are covered. **By the module whose behaviour the class breaks**:
`uart_tick_gen` 4, `uart_tx` 4, `uart_rx` 4, `uart_fifo` 3, `uart_lite` 4 = 19.
**By the file each diff edits**: `uart_tick_gen.sv` 4, `uart_tx.sv` 5,
`uart_rx.sv` 4, `uart_fifo.sv` 3, `uart_lite.sv` 3 = 19. The two tallies differ
by one because M-17 is filed under `uart_lite` by the brief and necessarily edits
`rtl/uart_tx.sv`; the reason is under its entry.

**The near-miss controls, and a scoring warning.** M-18 and M-19 are changes to
`rtl/**` that leave observable behaviour unchanged, argued below over the whole
legal stimulus space and confirmed byte-identical under my own probe. They exist
so the campaign can show it measures behaviour rather than reddening at any edit.
**They are not among the 17 intents, so the sealed predictions cannot name them
and they have no predicted cells.** They must be dispositioned as out-of-scoring
controls, or declined - scoring them against a seal that does not name them would
manufacture exactly the "red cell outside the prediction" case the playbook calls
a finding. The call is dv_lead's, not mine.


## 2. How the diffs were verified

Two things were checked for every class, by me, before anything was handed on.

**Applies cleanly.** Each patch was applied with `patch -p1` to a fresh copy of
the base `rtl/` tree. The copy contains `rtl/` and nothing else - `test/` was
never copied, per WO-0002 §1 bar 10, so no build could reach it even by accident.

**Compiles.** Each mutated tree was elaborated with
`iverilog -g2012 -f rtl/uart_lite.f <my own stub>`, using a throwaway stub of my
own under my scratch directory that instantiates all five modules standalone -
including `uart_tx.tx_busy`, which `uart_lite` leaves unconnected and which would
otherwise not be elaborated with its port. **19/19 applied and compiled, zero
warnings, zero repairs.**

**Fidelity, additionally.** Buildability does not establish that a diff behaves
*as described* rather than merely broken nearby, which is what §2 asks for. I
wrote a second throwaway file of my own - a probe, not a bench: it asserts
nothing, scores nothing, and prints observables of the design at each module's
ports. I ran it against the unmutated base and against all 19 mutants and
compared. The base's output matches the specification exactly where the spec
states a number: first tick at cycle N = 27 (SPEC §5.1), `tx_ready` rising at
cycle 4341 = 1 + 10 x 434 (SPEC §5.2), `full` exactly at level 16 (SPEC §5.4),
`rx_overrun` sticky (SPEC §5.5), `tx_line` = 1 after reset (SPEC §6). Each class
below carries what the probe measured.

Both throwaway files live in my private scratch directory, are not under `test/`,
and are not staged. **This is not a suite result and is not a prediction**: it is
me checking my own work against my own intents, on an instrument I wrote, which
tells me nothing about what any bench contains.


## 3. The classes


### M-01 / `TG-1` - tick anchor one cycle early

- **Module**: `uart_tick_gen`  |  **File**: `rtl/uart_tick_gen.sv`  |  **Block**: the `always_ff`, `rst || restart` branch
- **Spec anchor**: SPEC §5.1 (Anchor); REQ-005
- **Defect class**: off-by-one in a phase (anchor), wrong reload constant

```diff
--- a/rtl/uart_tick_gen.sv
+++ b/rtl/uart_tick_gen.sv
@@ -23,7 +23,7 @@
 
   always_ff @(posedge clk) begin
     if (rst || restart) begin
-      cnt  <= '0;
+      cnt  <= CW'(1);   // TG-1 MUTATION (WO-0002): reload 1, first tick one cycle early
       tick <= 1'b0;
     end else if (cnt == CW'(N - 1)) begin
       cnt  <= '0;
```

**Fidelity.** The reload value in the anchor branch becomes 1, so the anchor cycle is
consumed by the counter: the first tick after `rst` or `restart` lands one cycle
before the spec's cycle N. The terminal-count branch still reloads to 0, so every
later interval is exactly N.

**Does not change**: the spacing between successive ticks (still exactly N), the
width of `tick` (still one cycle), the never-two-consecutive property, the counter
width, or anything outside `uart_tick_gen`. Both anchors move together, which is
what SPEC §5.1 describes as one anchor rule.

This is the historical BUG-0001 restored, as the intent asks. The transmitter
signature is the recorded one: a first bit interval of 433 cycles with all nine
following intervals at 434.

**Detectable in principle?** **Yes, at the `uart_tick_gen` boundary** - but only by an observation anchored to
the restart or reset cycle. SPEC §5.1 says so itself: the spacing between ticks is
N under either convention, so an observation that measures only the interval
between successive ticks cannot separate them; only a measurement taken from the
anchor to the *first* tick can. At the `uart_tx` boundary the same defect appears
as a first bit interval of 433 cycles with the following nine at 434, so an
observation of the start bit's own duration can see it and an observation of
bit-boundary spacing cannot.

**Measured by my own probe** (not a suite result): first tick at cycle 26 (control 27); spacing 27, 27 unchanged; `tx_ready` rise 4340 (control 4341); every frame edge shifted by -1.


### M-02 / `TG-2` - tick anchor one cycle late

- **Module**: `uart_tick_gen`  |  **File**: `rtl/uart_tick_gen.sv`  |  **Block**: the `always_ff`, `rst || restart` branch
- **Spec anchor**: SPEC §5.1 (Anchor); REQ-005
- **Defect class**: off-by-one in a phase (anchor), opposite sign to M-01

```diff
--- a/rtl/uart_tick_gen.sv
+++ b/rtl/uart_tick_gen.sv
@@ -23,7 +23,7 @@
 
   always_ff @(posedge clk) begin
     if (rst || restart) begin
-      cnt  <= '0;
+      cnt  <= '1;       // TG-2 MUTATION (WO-0002): reload all-ones, first tick one cycle late
       tick <= 1'b0;
     end else if (cnt == CW'(N - 1)) begin
       cnt  <= '0;
```

**Fidelity.** The reload value in the anchor branch becomes all-ones. The counter spends the
anchor cycle at 2^CW-1, wraps to 0 in the next cycle, and therefore reaches
terminal count one cycle later than the unmutated design: the first tick lands at
cycle N+1.

**Does not change**: spacing (still exactly N after the first tick), width, the
never-two-consecutive property, or the reset/restart forcing of the counter.

**Bound worth stating**: the diff relies on 2^CW-1 != N-1, i.e. on N not being a
power of two. That holds for every N this design and REQ-005 use (2, 3, 27, 434).
For a power-of-two N the same edit would make the first tick land in cycle 1
instead of cycle N+1 - a different defect. Named here rather than discovered later.

**On the pairing**: §2 asks that M-01 and M-02 not be symmetric edits of the same
line if fidelity is better served otherwise. They do land on the same line, and I
kept it there deliberately: every alternative I considered for the late direction
(a one-shot stall flop, a widened compare, a second counter state) adds structure
that the intent does not describe and changes more than the anchor. The two diffs
are not symmetric in form - one substitutes a constant that shortens the phase by
consuming the anchor cycle, the other substitutes a constant that lengthens it by
spending a cycle in wrap - and each is the smallest edit producing its own
described behaviour.

**Detectable in principle?** **Yes, at the `uart_tick_gen` boundary**, under exactly the same condition as M-01
and with the opposite sign: measured from the anchor, the first tick is late by one.
At the `uart_tx` boundary it appears as a first bit interval of 435 cycles with the
following nine at 434.

**Measured by my own probe** (not a suite result): first tick at cycle 28 (control 27); spacing 27, 27 unchanged; `tx_ready` rise 4342; every frame edge shifted by +1.


### M-03 / `TG-3` - `restart` does not suppress `tick`

- **Module**: `uart_tick_gen`  |  **File**: `rtl/uart_tick_gen.sv`  |  **Block**: the `always_ff`, `rst || restart` branch
- **Spec anchor**: SPEC §5.1 port table; REQ-005
- **Defect class**: dropped side condition on a control input

```diff
--- a/rtl/uart_tick_gen.sv
+++ b/rtl/uart_tick_gen.sv
@@ -24,7 +24,8 @@
   always_ff @(posedge clk) begin
     if (rst || restart) begin
       cnt  <= '0;
-      tick <= 1'b0;
+      // TG-3 MUTATION (WO-0002): restart forces the counter but no longer suppresses tick
+      tick <= ~rst & (cnt == CW'(N - 1));
     end else if (cnt == CW'(N - 1)) begin
       cnt  <= '0;
       tick <= 1'b1;
```

**Fidelity.** `restart` still forces the counter to 0. What is removed is only the
unconditional suppression of `tick` in that cycle: `tick` now takes the value the
terminal-count comparison would have produced. `rst` still suppresses `tick`, so
the reset behaviour is untouched - the intent names `restart`'s suppression, and
the standing clause says an intent is not a licence to break a second rule.

**Does not change**: the post-restart schedule (the first tick after a restart is
still at cycle N, because the counter is still forced to 0), the reset schedule,
the spacing, or the width. The never-two-consecutive property is also preserved:
the counter cannot be at terminal count in two adjacent cycles, so the extra tick
can never abut another one.

**Detectable in principle?** **Yes at the `uart_tick_gen` boundary; phase-dependent above it.** A restart applied
while the divider sits at terminal count produces a tick in a cycle where the
unmutated design produces none - directly observable at the module's own port.
Measured: exactly 1 of the 27 possible restart phases exhibits it. At the `uart_tx`
and `uart_rx` boundaries the divider free-runs while idle, so whether a given frame
exposes the defect depends on the arrival phase of the request or the start edge -
1 in N events, with N = 434 for the transmitter and 27 for the receiver. A single
directed frame at an unlucky phase shows nothing; the defect is real and its
exposure is probabilistic above the unit boundary.

**Measured by my own probe** (not a suite result): 1 of 27 restart phases now produces a tick in the restart cycle (control 0 of 27); first tick still at cycle 27; spacing unchanged.


### M-04 / `TX-1` - data bits transmitted MSB-first

- **Module**: `uart_tx`  |  **File**: `rtl/uart_tx.sv`  |  **Block**: the `always_ff`, `load` branch (shift-register load)
- **Spec anchor**: SPEC §3; REQ-001, REQ-003
- **Defect class**: wrong bit order

```diff
--- a/rtl/uart_tx.sv
+++ b/rtl/uart_tx.sv
@@ -31,7 +31,9 @@
       running <= 1'b0;
       tx_line <= 1'b1;
     end else if (load) begin
-      sh      <= {1'b1, tx_data, 1'b0};
+      // TX-1 MUTATION (WO-0002): data bits loaded reversed, so they leave MSB-first
+      sh      <= {1'b1, tx_data[0], tx_data[1], tx_data[2], tx_data[3],
+                        tx_data[4], tx_data[5], tx_data[6], tx_data[7], 1'b0};
       bitcnt  <= '0;
       running <= 1'b1;
       tx_line <= 1'b0;                 // start bit begins in the next cycle
```

**Fidelity.** The shift register is loaded with the data byte bit-reversed, so the same
emission logic walks it out d7 first. The explicit bit list is used in preference
to a streaming operator so that the diff cannot depend on a simulator's support
for `{<<{}}`.

**Does not change**: the start bit (still `sh[0]` = 0, still one interval, still
driven at acceptance), the stop bit (still `sh[9]` = 1, still one interval), the
number of intervals, the interval length, `tx_ready`/`tx_busy`, or the handshake.
Measured: the ten intervals still begin at cycles 1 + i·434 exactly as in the
control, and `tx_ready` still rises at cycle 4341.

**Detectable in principle?** **Yes**, at the `uart_tx` and `uart_lite` boundaries, for any byte that is not equal
to its own bit-reversal. Note the size of that exception: 16 of the 256 byte values
are bit-palindromes, and for those the emitted waveform is identical to the
control. An observation that exercises only palindromic data cannot see this defect
at all; one that exercises any of the other 240 values can.

**Measured by my own probe** (not a suite result): seven line edges instead of five, at 435, 869, 1303, 2171, 3039, 3473, 3907 - byte 0xB2 emitted d7..d0; `tx_ready` rise unchanged at 4341.


### M-05 / `TX-2` - frame one bit period short, no stop interval

- **Module**: `uart_tx`  |  **File**: `rtl/uart_tx.sv`  |  **Block**: the `always_ff`, `running && tick` branch (terminal count)
- **Spec anchor**: SPEC §5.2; REQ-001, REQ-004
- **Defect class**: boundary condition on a terminal count

```diff
--- a/rtl/uart_tx.sv
+++ b/rtl/uart_tx.sv
@@ -36,7 +36,7 @@
       running <= 1'b1;
       tx_line <= 1'b0;                 // start bit begins in the next cycle
     end else if (running && tick) begin
-      if (bitcnt == 4'd9) begin
+      if (bitcnt == 4'd8) begin   // TX-2 MUTATION (WO-0002): finish after nine intervals, no stop interval
         running <= 1'b0;
         tx_line <= 1'b1;               // return to idle
       end else begin
```

**Fidelity.** The terminal comparison drops from 9 to 8, so the transmitter finishes after
the ninth interval - start plus eight data bits - and returns to idle. No stop
interval is emitted.

**Does not change**: bit order, bit period, byte value, the start bit, or the
`tx_line` *value* at any time. Idle and stop are the same level, so the emitted
waveform is bit-identical to the control; measured, the edge trace differs in
zero places. What moves is when the transmitter declares itself done:
`tx_ready` rises at cycle 3907 = 1 + 9·434 instead of 4341 = 1 + 10·434.

Read as the intent requires: this is one full bit period, not one clock cycle.

**Detectable in principle?** **Yes, but not from `tx_line` alone.** Idle and stop are the same level, so the
emitted waveform is bit-identical to the control - measured, zero edge differences.
The defect is observable through `tx_ready`/`tx_busy` returning one full bit period
early, or through the start bit of a following frame arriving one bit period early.
An observation that looks only at the line during a single frame cannot see it.

**Measured by my own probe** (not a suite result): `tx_ready` rise at 3907 = 1 + 9x434 (control 4341 = 1 + 10x434); the `tx_line` edge trace is identical to the control.


### M-06 / `TX-3` - bit period 433 instead of 434

- **Module**: `uart_tx`  |  **File**: `rtl/uart_tx.sv`  |  **Block**: the `uart_tick_gen` instantiation `u_tick`
- **Spec anchor**: SPEC §2 (`DIV_TX` = 434); REQ-002
- **Defect class**: corrupted timing parameter

```diff
--- a/rtl/uart_tx.sv
+++ b/rtl/uart_tx.sv
@@ -20,7 +20,8 @@
   assign tx_ready = ~running;
   assign tx_busy  = running;
 
-  uart_tick_gen #(.N(DIV_TX)) u_tick (
+  // TX-3 MUTATION (WO-0002): every bit interval is 433 cycles, not DIV_TX = 434
+  uart_tick_gen #(.N(DIV_TX - 1)) u_tick (
     .clk(clk), .rst(rst), .restart(load), .tick(tick)
   );
 
```

**Fidelity.** The transmitter's divider is instantiated at DIV_TX - 1, so all ten intervals
are 433 cycles.

**Choice worth disclosing.** The alternative diff is `DIV_TX = 433` in
`rtl/uart_pkg.sv`. I did not take it. The package constant is the design's
published statement of the number; anything that computes an expected bit period
from `uart_pkg::DIV_TX` would move with the mutation and could cancel it. A mutant
whose defect can be cancelled by its own constant is not a faithful realisation of
"each of the ten intervals is 433 cycles", which is a statement about the
transmitter's behaviour. Editing the instantiation makes the behaviour wrong while
leaving the published constant telling the truth. I record the alternative so
dv_lead can substitute it if it prefers the package form.

**Does not change**: bit order, frame structure, the number of intervals, the byte
value, the receiver (which takes `DIV_OS`, untouched here), or the package.
Measured: intervals begin at 1 + i·433 and `tx_ready` rises at 4331 = 1 + 10·433.

**Detectable in principle?** **Yes**, at the `uart_tx` and `uart_lite` boundaries, as a 1-cycle-per-interval error
in every interval and a 10-cycle error in the frame. Visible both to an
interval-duration observation and to a whole-frame duration observation.

**Measured by my own probe** (not a suite result): edges at 867, 1300, 2166, 3032, 3465 (= 1 + i x 433); `tx_ready` rise 4331 = 1 + 10x433.


### M-07 / `TX-4` - `tx_busy` never asserts  **(silently-always-pass)**

- **Module**: `uart_tx`  |  **File**: `rtl/uart_tx.sv`  |  **Block**: the continuous assignment to `tx_busy`
- **Spec anchor**: SPEC §5.2 port table
- **Defect class**: **silently-always-pass** - an output stuck at its inactive value

```diff
--- a/rtl/uart_tx.sv
+++ b/rtl/uart_tx.sv
@@ -18,7 +18,7 @@
 
   assign load     = tx_valid & tx_ready;
   assign tx_ready = ~running;
-  assign tx_busy  = running;
+  assign tx_busy  = 1'b0;   // TX-4 MUTATION (WO-0002): tx_busy never asserts
 
   uart_tick_gen #(.N(DIV_TX)) u_tick (
     .clk(clk), .rst(rst), .restart(load), .tick(tick)
```

**Fidelity.** `tx_busy` is tied to its inactive value. Nothing else in the transmitter is
touched.

**Does not change**: absolutely everything else - frame, period, bit order,
`tx_ready`, `tx_line`, the shift register, the handshake. Measured: the probe's
entire output is identical to the control except the single line that reports
whether `tx_busy` was ever high.

**This mutant is deliberately quiet and has not been strengthened.** A correct
implementation of this intent has a very small observable footprint; that small
footprint is the defect class, and enlarging it would destroy the measurement the
class exists to take (PROTOCOL §10 - every qualification owes one of these).

**Detectable in principle?** **At the `uart_tx` boundary, yes: `tx_busy` is a port and its value is wrong
whenever the transmitter is running.** At the `uart_lite` boundary, **no - and this
one is worth stating precisely**: `uart_lite` instantiates the transmitter with
`.tx_busy()` left unconnected (`rtl/uart_lite.sv:27`), so the signal has no
top-level observable at all. Seen from `uart_lite` the mutant is an equivalent
design, and that is a property of the design's port map, not of anyone's tests.

**Measured by my own probe** (not a suite result): `tx_busy` never observed high; every other line of the probe identical to the control.


### M-08 / `RX-1` - sampling at the cell boundary, not mid-cell

- **Module**: `uart_rx`  |  **File**: `rtl/uart_rx.sv`  |  **Block**: the sampling `always_ff`, the three sample-point comparisons
- **Spec anchor**: SPEC §5.3 (Sampling); REQ-006, REQ-007
- **Defect class**: off-by-eight in a sample phase (mis-selected sample point)

```diff
--- a/rtl/uart_rx.sv
+++ b/rtl/uart_rx.sv
@@ -49,12 +49,14 @@
       tcnt    <= '0;
     end else if (running && tick) begin
       tcnt <= t_next;
-      if (t_next == 8'd8) begin
+      // RX-1 MUTATION (WO-0002): sample points moved from mid-cell (8, 24 .. 152)
+      // to the leading edge of each cell (0, 16 .. 144).
+      if (t_next == 8'd0) begin
         // start-bit confirmation: a line that has gone high again is noise
         if (s2) running <= 1'b0;
-      end else if (t_next >= 8'd24 && t_next <= 8'd136 && t_next[3:0] == 4'd8) begin
+      end else if (t_next >= 8'd16 && t_next <= 8'd128 && t_next[3:0] == 4'd0) begin
         rx_byte <= {s2, rx_byte[7:1]};        // LSB first
-      end else if (t_next == 8'd152) begin
+      end else if (t_next == 8'd144) begin
         running <= 1'b0;
         if (s2) rx_strobe <= 1'b1;            // stop bit high: byte is good
         else    rx_frame_err <= 1'b1;         // stop bit low: framing error
```

**Fidelity.** All three sample-point comparisons move eight oversample ticks earlier, so the
receiver samples at ticks 0, 16, ... 144 - the leading edge of each bit cell -
instead of 8, 24, ... 152.

**Does not change**: the oversample rate (still 27 cycles per tick; measured, the
strobe moves by exactly 216 cycles = 8 x 27), the number of sample points (still
ten), the start-edge detection and the `restart` pulse it produces, the tick
counter, or the mutual exclusivity of `rx_strobe` and `rx_frame_err`.

**Collision, disclosed** (charter L-C12, brief §2 standing clause). Sample point
n = 0 is oversample tick 0, which is the cycle of the falling edge itself. No tick
event occurs in that cycle, so the start-bit confirmation is not taken and the
frame is never abandoned. This is a consequence of the intent as written, not a
second defect I added: the intent's own sample list contains tick 0, and a sample
taken at the falling edge would read the line low and confirm the frame anyway.
The effect overlaps M-10 (RX-3). I am recording it rather than silently choosing a
different sample list, because substituting one would have made the diff unfaithful
to the intent I was given.

**Detectable in principle?** **Yes**, at the `uart_rx` and `uart_lite` boundaries. The receive bit period is 432
cycles and the sample points move 216 cycles - half a bit cell - so each sample
lands on a cell boundary where the sender's line is transitioning. Measured: a byte
sent as 0xB2 is received as 0x64, and the strobe arrives 216 cycles early. Because
the stop sample lands inside d7's interval, frames whose d7 is 0 are reported as
framing errors instead of reaching the FIFO.

**Measured by my own probe** (not a suite result): 0xB2 received as 0x64; strobe 216 cycles early; a false-start stimulus now strobes 0xFF; frames with d7 = 0 report framing errors.


### M-09 / `RX-2` - oversample divisor 26 instead of 27

- **Module**: `uart_rx`  |  **File**: `rtl/uart_rx.sv`  |  **Block**: the `uart_tick_gen` instantiation `u_os`
- **Spec anchor**: SPEC §2 (`DIV_OS` = 27); REQ-006, REQ-011
- **Defect class**: corrupted timing parameter

```diff
--- a/rtl/uart_rx.sv
+++ b/rtl/uart_rx.sv
@@ -33,7 +33,8 @@
   assign rx_busy = running;
   assign t_next  = tcnt + 8'd1;
 
-  uart_tick_gen #(.N(DIV_OS)) u_os (
+  // RX-2 MUTATION (WO-0002): oversample tick period is 26 cycles, not DIV_OS = 27
+  uart_tick_gen #(.N(DIV_OS - 1)) u_os (
     .clk(clk), .rst(rst), .restart(restart), .tick(tick)
   );
 
```

**Fidelity.** The receiver's oversample divider is instantiated at DIV_OS - 1, giving a 26-cycle
oversample tick and a 416-cycle receive bit period instead of 432.

The same disclosure as M-06 applies: the alternative diff is `DIV_OS = 26` in
`rtl/uart_pkg.sv`, and I chose the instantiation for the same reason - a mutant
whose defect is cancelled by the constant it moves is not faithful to "the
oversample rate is wrong". The alternative is recorded so dv_lead can substitute.

**Does not change**: `OS` (the sample tick indices are literals in `uart_rx` and are
untouched, so sampling stays at tick 8 of each cell, mid-bit), the number of
samples, the frame structure, the transmitter, or the package. Only the rate is
wrong. Measured: the strobe arrives 152 cycles early, which is exactly
9 x 16 x (27-26) + 8 x (27-26) - the accumulated rate error, not a phase shift.

**Detectable in principle?** **Yes**, at the `uart_rx` and `uart_lite` boundaries. The receive bit period falls
from 432 to 416 cycles, a 3.7 % rate error against the nominal sender, which alone
exceeds the ±3 % window REQ-011 requires the receiver to tolerate; combined with a
sender at either end of that window the accumulated drift over ten samples
misplaces the sample points. Measured: at the nominal 434-cycle sender period the
strobe arrives 152 cycles early. Note that the nominal-period byte still decodes
correctly, so an observation taken only at the nominal sender period sees a timing
shift but not a data error; an observation across the REQ-011 sweep sees data
errors.

**Measured by my own probe** (not a suite result): strobe 152 cycles early at the nominal sender period; byte still 0xB2 at that period.


### M-10 / `RX-3` - false start not rejected

- **Module**: `uart_rx`  |  **File**: `rtl/uart_rx.sv`  |  **Block**: the sampling `always_ff`, start-confirmation branch
- **Spec anchor**: SPEC §5.3 (False start); REQ-008
- **Defect class**: weakened check - a guard evaluated and not acted on

```diff
--- a/rtl/uart_rx.sv
+++ b/rtl/uart_rx.sv
@@ -50,8 +50,8 @@
     end else if (running && tick) begin
       tcnt <= t_next;
       if (t_next == 8'd8) begin
-        // start-bit confirmation: a line that has gone high again is noise
-        if (s2) running <= 1'b0;
+        // RX-3 MUTATION (WO-0002): the confirmation sample is read and not acted on
+        if (s2) begin /* frame is no longer abandoned */ end
       end else if (t_next >= 8'd24 && t_next <= 8'd136 && t_next[3:0] == 4'd8) begin
         rx_byte <= {s2, rx_byte[7:1]};        // LSB first
       end else if (t_next == 8'd152) begin
```

**Fidelity.** The start-bit confirmation sample is still taken at oversample tick 8 and is still
read; the action it used to trigger is removed, so the frame proceeds regardless.

**Does not change**: sample timing (measured: the good-frame strobe cycle is
identical to the control), the stop-bit check, `rx_frame_err` on a genuinely low
stop bit, the byte assembly, or exclusivity. Measured: the probe output differs
from the control in exactly one line - a false-start stimulus that the control
abandons silently now completes and strobes.

**Detectable in principle?** **Yes**, at the `uart_rx` and `uart_lite` boundaries, but only under a stimulus that
actually presents a false start - a low excursion on `rx_line` shorter than the
start-bit confirmation point, followed by a return to idle. Under well-formed
traffic the mutant and the control are indistinguishable, because the confirmation
sample reads low in both. Measured: a 100-cycle low pulse that the control abandons
silently now completes a frame and strobes 0xFF.

**Measured by my own probe** (not a suite result): exactly one line differs from the control: the false-start stimulus strobes 0xFF.


### M-11 / `RX-4` - one synchroniser flop instead of two

- **Module**: `uart_rx`  |  **File**: `rtl/uart_rx.sv`  |  **Block**: the synchroniser declaration and `always_ff`
- **Spec anchor**: SPEC §5.3 (Sampling); REQ-013
- **Defect class**: removed CDC stage (structural)

```diff
--- a/rtl/uart_rx.sv
+++ b/rtl/uart_rx.sv
@@ -16,10 +16,12 @@
   output logic       rx_busy
 );
   // ---- two-flop synchroniser (s1, s2) plus one delay for edge detect -------
-  logic s1, s2, s2_d;
+  // RX-4 MUTATION (WO-0002): one synchroniser flop instead of two
+  logic s1, s2_d;
+  wire  s2 = s1;
   always_ff @(posedge clk) begin
-    if (rst) begin s1 <= 1'b1; s2 <= 1'b1; s2_d <= 1'b1; end
-    else     begin s1 <= rx_line; s2 <= s1; s2_d <= s2; end
+    if (rst) begin s1 <= 1'b1; s2_d <= 1'b1; end
+    else     begin s1 <= rx_line; s2_d <= s2; end
   end
   wire fall = s2_d & ~s2;
 
```

**Fidelity.** `rx_line` now passes through one flip-flop. `s1` is the single reader of `rx_line`;
`s2` becomes a wire alias of `s1`, so the edge detector and every downstream reader
keep their existing names and structure and REQ-013's "exactly one reader" property
is preserved, as the intent requires.

**Does not change**: the design still functions in simulation - a well-formed frame
is still received correctly; the sample schedule, the byte assembly and the flag
logic are untouched. Everything downstream happens one cycle earlier. Measured: the
strobe moves from cycle 4108 to 4107 and nothing else in the probe changes.

**Detectable in principle?** **Two different answers, and the distinction matters.** The *functional* effect -
everything downstream one cycle earlier - is observable at the `uart_rx` boundary
by any cycle-accurate observation of the sample points or the strobe; measured, the
strobe moves from 4108 to 4107. The property the defect actually destroys -
metastability margin on an asynchronous input - is **not observable in any RTL
simulation**, because RTL simulation has no metastability to be a margin against.
That is consistent with the spec: REQ-013's stated verification method is
**inspection**, not sim (`docs/specs/requirements.md:26`). So a simulation result on
this mutant, either way, is evidence about the one-cycle shift and not about the
requirement's substance.

**Measured by my own probe** (not a suite result): strobe at cycle 4107 (control 4108); no other difference.


### M-12 / `FF-1` - `full` asserts one entry early

- **Module**: `uart_fifo`  |  **File**: `rtl/uart_fifo.sv`  |  **Block**: the continuous assignment to `full`
- **Spec anchor**: SPEC §5.4; REQ-015
- **Defect class**: boundary condition on a flag (off-by-one)

```diff
--- a/rtl/uart_fifo.sv
+++ b/rtl/uart_fifo.sv
@@ -20,7 +20,8 @@
   logic [AW-1:0] wp, rp;
   logic          do_wr, do_rd;
 
-  assign full    = (level == ($clog2(DEPTH)+1)'(DEPTH));
+  // FF-1 MUTATION (WO-0002): full asserts one entry early, at level = DEPTH-1
+  assign full    = (level == ($clog2(DEPTH)+1)'(DEPTH-1));
   assign empty   = (level == '0);
   assign do_wr   = wr_en & ~full;
   assign do_rd   = rd_en & ~empty;
```

**Fidelity.** `full` compares `level` against DEPTH-1, so the FIFO refuses the sixteenth entry.

**Does not change**: `empty` (still exact), ordering (measured: entries still come
out 1, 2, 3, ... in write order), first-word fall-through, the ignore-a-write-while-
full rule (still honoured, just at the wrong level), the ignore-a-pop-while-empty
rule, or `level`'s meaning - `level` still reports the number of entries stored, it
simply never reaches 16.

**Detectable in principle?** **Yes**, at the `uart_fifo` boundary, by any observation that fills the FIFO to
capacity and reads `full`, `level`, or the number of entries that survive. At the
`uart_lite` boundary it is observable as overrun occurring after 15 buffered bytes
rather than 16.

**Measured by my own probe** (not a suite result): `full` high at level 15; twenty writes leave 15 entries; readout 1..15 in order.


### M-13 / `FF-2` - write while full overwrites the oldest entry

- **Module**: `uart_fifo`  |  **File**: `rtl/uart_fifo.sv`  |  **Block**: the `do_wr` assignment, the `rp` update and the `level` case
- **Spec anchor**: SPEC §5.4 (write while full is silently ignored); REQ-015
- **Defect class**: inverted policy on a full-condition write

```diff
--- a/rtl/uart_fifo.sv
+++ b/rtl/uart_fifo.sv
@@ -22,7 +22,7 @@
 
   assign full    = (level == ($clog2(DEPTH)+1)'(DEPTH));
   assign empty   = (level == '0);
-  assign do_wr   = wr_en & ~full;
+  assign do_wr   = wr_en;   // FF-2 MUTATION (WO-0002): a write while full is accepted
   assign do_rd   = rd_en & ~empty;
   assign rd_data = mem[rp];
 
@@ -31,9 +31,10 @@
       wp <= '0; rp <= '0; level <= '0;
     end else begin
       if (do_wr) begin mem[wp] <= wr_data; wp <= wp + AW'(1); end
-      if (do_rd) rp <= rp + AW'(1);
+      // FF-2 MUTATION (WO-0002): a write while full drops the oldest entry
+      if (do_rd || (do_wr && full)) rp <= rp + AW'(1);
       case ({do_wr, do_rd})
-        2'b10:   level <= level + 1;
+        2'b10:   level <= full ? level : level + 1;   // FF-2 MUTATION (WO-0002)
         2'b01:   level <= level - 1;
         default: level <= level;
       endcase
```

**Fidelity.** A write is accepted unconditionally; when it arrives while the FIFO is full the read
pointer advances too, so the oldest entry is dropped and `level` stays at DEPTH.

Three lines move because one policy changes: the write must be accepted, the head
must advance, and the level must hold. There is no smaller edit that produces the
described behaviour rather than a corrupted level or a lost entry count.

**Does not change**: `full` still asserts exactly at `level` = DEPTH; `empty` is
still exact; `level` still reports the number of entries stored; a pop while empty
is still ignored (`do_rd` is untouched); no flag is raised by the FIFO. When a read
and an overwriting write coincide the read supplies the pointer advance and the
level is unchanged, which is the same net effect. Measured: after twenty writes to
a sixteen-deep FIFO the readout is 5..20 - the last sixteen written, in order.

**Detectable in principle?** **Yes**, at the `uart_fifo` boundary, by any observation that overfills the FIFO and
then drains it: the surviving entries are the newest DEPTH rather than the oldest.
Note it is **not** observable from the flags alone - `full`, `empty` and `level`
follow exactly the same trajectory as the control - so an observation that checks
only flags and levels cannot see it; one that checks the data read back can.

**Measured by my own probe** (not a suite result): twenty writes into a 16-deep FIFO leave entries 5..20 in order; `full`/`empty`/`level` trajectories identical to the control.


### M-14 / `LT-1` - `rx_overrun` is a strobe, not sticky

- **Module**: `uart_lite`  |  **File**: `rtl/uart_lite.sv`  |  **Block**: the overrun `always_ff`
- **Spec anchor**: SPEC §5.5 (Overrun); REQ-014
- **Defect class**: lost state - a sticky flag made transient

```diff
--- a/rtl/uart_lite.sv
+++ b/rtl/uart_lite.sv
@@ -47,6 +47,7 @@
   always_ff @(posedge clk) begin
     if (rst)              rx_overrun <= 1'b0;
     else if (rx_ovr_clr)  rx_overrun <= 1'b0;
-    else if (rxs & ffull) rx_overrun <= 1'b1;
+    // LT-1 MUTATION (WO-0002): rx_overrun is a one-cycle strobe, not sticky
+    else                  rx_overrun <= rxs & ffull;
   end
 endmodule
```

**Fidelity.** The overrun flag becomes a one-cycle pulse that self-clears: the final `else if`
becomes an `else` that drives the flag from the set condition directly.

**Does not change**: the arriving byte is still dropped (the FIFO's own
write-while-full rule is untouched), the sixteen stored bytes are still unchanged
and still read out in order, and `rx_ovr_clr` still exists and still clears the
flag. Measured: the stored-data observables are identical to the control; only the
flag's persistence changes.

**Detectable in principle?** **Yes**, at the `uart_lite` boundary, by any observation that reads `rx_overrun`
later than the cycle in which the overrunning byte completed. An observation that
happens to sample the flag in exactly that cycle sees the same value as the
control.

**Measured by my own probe** (not a suite result): `rx_overrun` reads 0 when sampled 300 and 3300 cycles after the overrunning byte (control: 1 at both).


### M-15 / `LT-2` - a framing error writes the FIFO

- **Module**: `uart_lite`  |  **File**: `rtl/uart_lite.sv`  |  **Block**: the `uart_fifo` instantiation, `wr_en` port
- **Spec anchor**: SPEC §5.5 ("A framing error does not write the FIFO")
- **Defect class**: widened enable condition

```diff
--- a/rtl/uart_lite.sv
+++ b/rtl/uart_lite.sv
@@ -34,7 +34,8 @@
 
   uart_fifo #(.DEPTH(FIFO_DEPTH), .W(8)) u_fifo (
     .clk(clk), .rst(rst),
-    .wr_en(rxs), .wr_data(rxb),           // a framing error never writes
+    // LT-2 MUTATION (WO-0002): a framing error writes the FIFO
+    .wr_en(rxs | rxfe), .wr_data(rxb),
     .rd_en(rx_valid & rx_ready), .rd_data(rx_data),
     .full(ffull), .empty(fempty), .level(flevel)
   );
```

**Fidelity.** The FIFO's write enable widens to include the framing-error strobe, so a frame
whose stop bit sampled low pushes its byte as if it were valid.

**Does not change**: `rx_frame_err` is still asserted for one cycle, `rx_strobe` is
still withheld by the receiver, exclusivity holds (the two strobes are still
mutually exclusive inside `uart_rx`), and the overrun rule is unchanged - overrun is
still driven from `rxs & ffull`, not from the widened enable. Measured: a bad-stop
frame now appears at the FIFO head.

**Detectable in principle?** **Yes**, at the `uart_lite` boundary: a frame with a low stop bit produces a byte at
`rx_data` with `rx_valid` high, where the control produces nothing. Measured.

**Measured by my own probe** (not a suite result): a frame with a low stop bit appears at `rx_data` = 0x3C with `rx_valid` high (control: `rx_valid` 0).


### M-16 / `LT-3` - `rx_valid` polarity inverted

- **Module**: `uart_lite`  |  **File**: `rtl/uart_lite.sv`  |  **Block**: the continuous assignment to `rx_valid`
- **Spec anchor**: SPEC §5.5 port table (`rx_valid` = FIFO not empty); REQ-016
- **Defect class**: inverted polarity

```diff
--- a/rtl/uart_lite.sv
+++ b/rtl/uart_lite.sv
@@ -39,7 +39,7 @@
     .full(ffull), .empty(fempty), .level(flevel)
   );
 
-  assign rx_valid     = ~fempty;
+  assign rx_valid     = fempty;   // LT-3 MUTATION (WO-0002): rx_valid high exactly when empty
   assign rx_frame_err = rxfe;
 
   // Overrun is the top level's: the receiver cannot stall a serial line, so
```

**Fidelity.** `rx_valid` is driven from the FIFO's `empty` flag directly.

**Does not change**: `rx_data` still presents the FIFO head, the FIFO itself is
untouched, and `rx_ready` still pops on `rx_valid & rx_ready` exactly as wired -
the wiring is identical, only the value it carries differs. The FIFO's own
ignore-a-pop-while-empty rule still holds, so the inverted flag cannot corrupt the
queue.

**Detectable in principle?** **Yes**, at the `uart_lite` boundary, immediately and under almost any stimulus -
`rx_valid` is high out of reset with an empty FIFO, which REQ-016 states directly.

**Measured by my own probe** (not a suite result): `rx_valid` = 1 out of reset with an empty FIFO; `rx_valid` = 0 while the FIFO holds data.


### M-17 / `LT-4` - `tx_line` resets low instead of high

- **Module**: `uart_lite` (reset value lives in `uart_tx`)  |  **File**: `rtl/uart_tx.sv`  |  **Block**: the `always_ff`, `rst` branch
- **Spec anchor**: SPEC §6 (Reset); REQ-016
- **Defect class**: wrong reset state

```diff
--- a/rtl/uart_tx.sv
+++ b/rtl/uart_tx.sv
@@ -29,7 +29,7 @@
       sh      <= 10'h3FF;
       bitcnt  <= '0;
       running <= 1'b0;
-      tx_line <= 1'b1;
+      tx_line <= 1'b0;   // LT-4 MUTATION (WO-0002): tx_line resets low, not high
     end else if (load) begin
       sh      <= {1'b1, tx_data, 1'b0};
       bitcnt  <= '0;
```

**Fidelity.** `tx_line`'s reset value becomes 0. The transmitter holds the line low out of reset
until the first frame is requested; the first frame's start bit drives it low
anyway, and the end of that frame returns it high, after which the transmitter
behaves normally.

**Filed under `uart_lite`, edited in `uart_tx` - disclosed.** SPEC §6 states the
reset requirement at the top level, and `uart_lite.tx_line` is `uart_tx.tx_line`
wired straight through (`rtl/uart_lite.sv:27`). There is no edit that changes the
top-level reset value without changing the transmitter's, so the minimal faithful
diff is the transmitter's reset branch. The behaviour that changes is exactly the
behaviour SPEC §6 describes.

**Does not change**: `tx_ready` = 1 out of reset, the FIFO empty, `rx_overrun` = 0,
the receiver idle, or any frame the transmitter subsequently sends. Measured: the
whole frame trace, the interval boundaries and the `tx_ready` rise cycle are
identical to the control.

**Detectable in principle?** **Yes**, at both the `uart_lite` and `uart_tx` boundaries, by any observation of
`tx_line` in the cycles after reset deasserts and before the first frame is
requested. It disappears permanently once the first frame completes, so an
observation that begins after traffic has started cannot see it.

**Measured by my own probe** (not a suite result): `tx_line` = 0 one cycle after reset deasserts, at both the `uart_tx` and `uart_lite` boundaries; frame trace and `tx_ready` rise unchanged.


### M-18 / `NM-1` - **NEAR-MISS CONTROL** - local rename + equivalent `empty` expression

- **Module**: `uart_fifo`  |  **File**: `rtl/uart_fifo.sv`  |  **Block**: declarations, two continuous assignments, the `always_ff`
- **Spec anchor**: none - no behaviour is intended to change
- **Defect class**: **control, not a defect**

```diff
--- a/rtl/uart_fifo.sv
+++ b/rtl/uart_fifo.sv
@@ -18,21 +18,21 @@
   localparam int AW = $clog2(DEPTH);
   logic [W-1:0]  mem [DEPTH];
   logic [AW-1:0] wp, rp;
-  logic          do_wr, do_rd;
+  logic          wr_fire, rd_fire;   // NM-1 MUTATION (WO-0002): near-miss control, rename only
 
   assign full    = (level == ($clog2(DEPTH)+1)'(DEPTH));
-  assign empty   = (level == '0);
-  assign do_wr   = wr_en & ~full;
-  assign do_rd   = rd_en & ~empty;
+  assign empty   = ~(|level);   // NM-1 MUTATION (WO-0002): equivalent rewrite
+  assign wr_fire = wr_en & ~full;
+  assign rd_fire = rd_en & ~empty;
   assign rd_data = mem[rp];
 
   always_ff @(posedge clk) begin
     if (rst) begin
       wp <= '0; rp <= '0; level <= '0;
     end else begin
-      if (do_wr) begin mem[wp] <= wr_data; wp <= wp + AW'(1); end
-      if (do_rd) rp <= rp + AW'(1);
-      case ({do_wr, do_rd})
+      if (wr_fire) begin mem[wp] <= wr_data; wp <= wp + AW'(1); end
+      if (rd_fire) rp <= rp + AW'(1);
+      case ({wr_fire, rd_fire})
         2'b10:   level <= level + 1;
         2'b01:   level <= level - 1;
         default: level <= level;
```

**Fidelity.** **This is a control, not a defect. It is expected to change nothing observable at
any port, and it is in the manifest so that the campaign can show it is measuring
behaviour rather than reddening at any edit to `rtl/**`.**

Two changes, both equivalence-preserving:

1. `do_wr` -> `wr_fire`, `do_rd` -> `rd_fire`. Pure alpha-renaming of two
   module-internal `logic` nets. Neither appears in the port list; every occurrence
   is renamed. A local identifier's spelling cannot affect simulation semantics for
   any stimulus.
2. `empty = (level == '0)` -> `empty = ~(|level)`.

**Equivalence argument, over the whole legal stimulus space** (PROTOCOL §10 - an
equivalent-mutant claim is a proof obligation, discharged by argument and never by
a suite's failure to kill). `level` is the only operand, and the claim is that the
two expressions agree on every 4-state value it can hold:

- some bit is 1: `==` finds a mismatch in a known bit and yields 1'b0; `|level`
  yields 1'b1 and `~` yields 1'b0. Agree.
- no bit is 1, at least one bit X or Z: `==` with an unknown operand yields 1'bx;
  `|` over {0, x} yields 1'bx and `~1'bx` is 1'bx. Agree.
- all bits 0: both yield 1'b1. Agree.

The mapping is total over the 4-state domain, so no stimulus - legal or illegal,
before or after reset - can distinguish them. `empty` also feeds `do_rd`/`rd_fire`
internally; since `empty` itself is indistinguishable, so is everything downstream.

Measured: the probe's output is byte-identical to the unmutated control.

**Detectable in principle?** **No, by construction and by argument** - see the equivalence argument above. This
is the control. Any red produced by this mutant is a finding about the observation,
not about the design.

**Measured by my own probe** (not a suite result): probe output **byte-identical** to the unmutated control (`cmp` clean).


### M-19 / `NM-2` - **NEAR-MISS CONTROL** - equivalent increment expression

- **Module**: `uart_tick_gen`  |  **File**: `rtl/uart_tick_gen.sv`  |  **Block**: the `always_ff`, counting branch
- **Spec anchor**: none - no behaviour is intended to change
- **Defect class**: **control, not a defect**

```diff
--- a/rtl/uart_tick_gen.sv
+++ b/rtl/uart_tick_gen.sv
@@ -29,7 +29,7 @@
       cnt  <= '0;
       tick <= 1'b1;
     end else begin
-      cnt  <= cnt + CW'(1);
+      cnt  <= CW'(cnt + 1);   // NM-2 MUTATION (WO-0002): near-miss control, equivalent rewrite
       tick <= 1'b0;
     end
   end
```

**Fidelity.** **This is a control, not a defect,** for the same reason as M-18, and it is placed
in `uart_tick_gen` deliberately - the timing core, where an edit is most likely to
look alarming.

`cnt <= cnt + CW'(1)` becomes `cnt <= CW'(cnt + 1)`.

**Equivalence argument, over the whole legal stimulus space.** In the original both
operands are CW bits wide, the addition is evaluated at CW bits and wraps modulo
2^CW. In the mutant `cnt + 1` is evaluated at 32 bits (the integer literal's width)
and the cast truncates to the low CW bits, which is the same value modulo 2^CW.
The two agree for every value of `cnt`, including the all-ones value where the
original wraps and the mutant discards a carry out. X/Z propagation is identical:
in both forms every bit at or above the least-significant unknown is unknown, and
truncation preserves the low CW bits unchanged. Reachability makes the point moot
as well as sound - with N = 27 (CW = 5) `cnt` never exceeds 26 and with N = 434
(CW = 9) never exceeds 433, so the wrap case is not reachable in this design at all.

Measured: the probe's output is byte-identical to the unmutated control.

**Detectable in principle?** **No, by construction and by argument** - see the equivalence argument above. This
is the control. Any red produced by this mutant is a finding about the observation,
not about the design.

**Measured by my own probe** (not a suite result): probe output **byte-identical** to the unmutated control (`cmp` clean).


## 4. Classes I flagged as wholly or partly unobservable

An equivalent mutant is not a failure of a test suite, and calling one a miss is
the easiest way to libel a suite. Four entries need stating.

| class | status |
|---|---|
| M-18 / `NM-1` | **Deliberately equivalent.** Control. Argued over the whole 4-state domain of `level`; measured byte-identical. |
| M-19 / `NM-2` | **Deliberately equivalent.** Control. Argued over every value of `cnt`, including the unreachable wrap; measured byte-identical. |
| M-07 / `TX-4` | **Equivalent at the `uart_lite` boundary**, observable at the `uart_tx` boundary. `uart_lite` leaves `.tx_busy()` unconnected (`rtl/uart_lite.sv:27`), so the mutated signal has no top-level observable. This is a property of the design's port map. |
| M-11 / `RX-4` | **Its functional shift is observable; the property it destroys is not.** Metastability margin cannot be observed in RTL simulation. REQ-013's stated method is *inspection* (`docs/specs/requirements.md:26`), so a simulation result on this mutant is evidence about a one-cycle shift, not about the requirement. |

Two further entries are observable but through a narrower window than they look,
and I state the window rather than let it be discovered at adjudication:

- **M-05 / `TX-2`** - the `tx_line` waveform is bit-identical to the control
  (measured: zero edge differences). Only `tx_ready`/`tx_busy` timing, or a
  following frame's arrival, carries the defect.
- **M-04 / `TX-1`** - 16 of the 256 byte values are bit-palindromes and emit an
  identical waveform under this mutant. Only the other 240 carry the defect.

None of the 17 intents is fully equivalent at its own module's boundary.


## 5. What I could not do faithfully, said plainly

**One collision, and I preserved the spec rule rather than the convenience**
(charter L-C12, brief §2 standing clause).

- **M-08 / `RX-1`** necessarily also disables start-bit abandonment, overlapping
  M-10 / `RX-3`. The intent's own sample list contains oversample tick 0, which is
  the falling-edge cycle; no tick event occurs there, and a sample taken at the
  falling edge would read the line low and confirm the frame in any case. I
  implemented the intent as written and disclosed the overlap, rather than
  substituting a sample list that would have been unfaithful to it.

**Two choices between equally minimal diffs, disclosed with the alternative:**

- **M-06 / `TX-3`** and **M-09 / `RX-2`** edit the *instantiation*
  (`DIV_TX - 1`, `DIV_OS - 1`) rather than the constant in `rtl/uart_pkg.sv`.
  Both edits are one token. I chose the instantiation because a mutant whose
  defect can be cancelled by the same constant it moves is not a faithful
  realisation of "each interval is 433 cycles" / "the oversample rate is 26",
  which are statements about behaviour. The package edit is recorded in both
  entries so dv_lead can substitute it if it prefers that form.

**One filing discrepancy, disclosed:**

- **M-17 / `LT-4`** is filed under `uart_lite` and edits `rtl/uart_tx.sv`. No edit
  can change the top-level reset value without changing the transmitter's, since
  `uart_lite.tx_line` is `uart_tx.tx_line` wired through.

**One bound stated rather than left to be found:**

- **M-02 / `TG-2`** relies on N not being a power of two. True for every N this
  design and REQ-005 use (2, 3, 27, 434); false in general.

Nothing else was substituted, weakened, or strengthened. In particular **M-07 /
`TX-4` was left quiet on purpose**: it is the silently-always-pass class every
qualification owes, and making it louder would destroy the measurement.


## 6. Scope statement - what I read, checked against the allowlist

WO-0002 §1's allowlist is the complete set of repository paths readable this
round. Against it:

**Read, and inside the allowlist:**

| path | allowlist row |
|---|---|
| `agents/handoffs/WO-0002-mutation-campaign.md` | 1 |
| `docs/specs/SPEC-uart_lite.md`, `docs/specs/requirements.md` | 2 |
| `rtl/uart_pkg.sv`, `uart_tick_gen.sv`, `uart_tx.sv`, `uart_rx.sv`, `uart_fifo.sv`, `uart_lite.sv`, `uart_lite.f` | 3 |
| `agents/charters/auditor.md`, `agents/PROTOCOL.md`, `docs/playbooks/mutation-campaign.md` | 5 |
| `.gitignore` | 6 |

Also read: the spawn dispatch that ordered this round (my own work order), and
my own journal's seeded header.

**Read, and OUTSIDE the allowlist - disclosed, not concealed:**

- **`tasks/BOARD.md`** - placed out of bounds by §1 in terms. I read it because the
  spawn dispatch listed it as a mandatory first action, before I had reached the
  brief that forbids it. What it carries that a seeder should not have: the
  per-bench check counts and the mapping of benches to REQ ids, and a narrative
  paragraph about a requirement that a defective transmitter formerly satisfied.

**Ambient exposure, disclosed unprompted** (charter L-C15 - a bar list is a floor,
and the call on whether an exposure voids a mutation is dv_lead's, never mine):

- The §4.1 precheck this round required (`git log --oneline -1`) rendered the
  subject line of the freeze commit `c7762b0`. That subject **names sealed
  material**: the count of sealed classes, the count of rows its author judged
  unable to fail, and a discriminating property of one specific predicted check.
  I am deliberately not reproducing the sentence here, because
  `docs/reports/audit/**` is itself row 4 of this allowlist and reproducing it
  would propagate the leak to every future seeder; the verbatim text is quoted in
  my journal entry `J-auditor-0001`, which §1 places out of bounds to seeders.
  It is written up as finding F-01 of
  `audit-0001_wo-0002-seeding-integrity.md`.
- **Why it could not have steered the seeding.** I had no discretion over which
  defects to seed: dv_lead published all 17 intents in §2 of the brief, and I
  authored those 17 and nothing else. The exposure could in principle have
  steered *where within a class* a diff lands, so I state the placement rule I
  used and it is checkable against every diff above: **the smallest edit at the
  site the cited spec text points to.** The exposure has not been used anywhere
  in this manifest, and no detectability judgement here rests on it.

**Deliberately NOT read, though the spawn dispatch listed it as in bounds:**

- **`docs/adr/**`** - §1 places `docs/` outside `docs/specs/**`,
  `docs/playbooks/mutation-campaign.md` and `docs/reports/audit/**` out of bounds.
  The dispatch widened the allowlist; the allowlist is dv_lead's to set in the
  brief (PROTOCOL §10), not the orchestrator's to widen at spawn. I took the
  narrower set and did not read the ADRs. Written up as F-02.

**Not read, at any point, in any state:**

- `agents/handoffs/WO-0002-SEALED-predictions.md` - the seal. Never opened.
- `agents/journals/claude_dv_lead_agent.md` - carries the seal's second copy.
  Never opened.
- **`test/**` in its entirety** - every bench, `test/run.sh`, and `test/wave/**`.
  Never opened, never copied into a build tree, never referenced.
- Every other journal, packet and verdict under `agents/**`.

**Git discipline**: exactly two read-only git commands were run this round, both
from the §4.1 precheck (`git status --short`, `git log --oneline -1`). No git
write command was run. No `git log`, `git show`, `git diff` or any other
subcommand was pointed at a path outside the allowlist (§1 bar 11).


---

*Authored by the auditor as the campaign's no-stake seeder. I do not run these
diffs and I do not see the results (WO-0002 §3). Findings arising from this round
are in `docs/reports/audit/audit-0001_wo-0002-seeding-integrity.md`; the reasoning
record is `J-auditor-0001`.*

