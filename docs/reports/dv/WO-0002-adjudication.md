# WO-0002 adjudication — scoring the uart_lite bench suite against the sealed predictions

- **Adjudicator**: dv_lead · **Journal entry**: `J-dv_lead-0003`
- **Campaign packet**: `agents/handoffs/WO-0002-mutation-campaign.md`
- **Sealed companion**: `agents/handoffs/WO-0002-SEALED-predictions.md` (frozen at
  `c7762b0`, **never edited** — see §2)
- **Base pin**: `c7762b0` (freeze). Seeding `4fe6014`. Operator run `1c06a20`.
  Adjudication performed at `1c06a20`, clean tree.
- **Subject under test**: **not the design.** The five benches under `test/`,
  609 checks, and whether they have teeth.

> **What this file is.** It is the scorecard the seal's §5 requires, issued
> *beside* the seal and never inside it. Every non-kill is dispositioned
> individually by name, row and ground, because rule 9 forbids a ratio from
> standing in for a disposition.

---

## 1. Precheck, provenance, reproducibility

**§4.1 precheck, both outputs recorded** (measured):

```
$ git log --oneline -1
1c06a20 operator: run the WO-0002 mutants and record the raw verdicts
$ git status --porcelain
(empty)
```

This was a **dispatch-only round**: no sibling agent was spawned, no work order
was issued, and every judgement below is this seat's own.

**The denominator did not move.** Fixed at freeze at 609 units across five
benches, and verified rather than assumed:

```
$ git diff 509173a c7762b0 -- rtl/ test/run.sh test/tb_uart_lite.sv \
      test/tb_uart_tick_gen.sv test/tb_uart_fifo.sv test/tb_uart_tx.sv test/tb_uart_rx.sv
(empty)
$ git diff c7762b0 HEAD --stat -- rtl/ test/
(empty)
```

No compiled file changed between the green control at `509173a`, the freeze, and
the adjudication SHA. The control is green at 609/609 (12 + 28 + 13 + 265 + 291),
measured.

**The seal is byte-identical to its frozen form** (measured):

```
$ git show c7762b0:agents/handoffs/WO-0002-SEALED-predictions.md | sha256sum
ead9e4f73421dbb0924612b66279c46697ccd8be319a15ca24cdec88cb117f9c
$ git show HEAD:agents/handoffs/WO-0002-SEALED-predictions.md | sha256sum
ead9e4f73421dbb0924612b66279c46697ccd8be319a15ca24cdec88cb117f9c
```

**The result is reproducible, not relayed.** The operator's verdicts reached this
seat as a table. A table is a relay, and a relay is not a measurement (L-B01), so
this seat re-ran the entire campaign independently:

```
$ CAMPAIGN_SCRATCH=/tmp/wo0002-dv-rerun bash tools/campaign_run.sh <outdir>
```

All 19 mutants were re-executed. **The set of `[REQ-nnn] FAIL` lines is
byte-identical between the operator's run and this seat's run for all 19 of 19
mutants** (sha256 per mutant, compared). The per-bench failing-unit counts are
identical. The campaign is deterministic: the benches use fixed seeds and no
wall-clock dependence. Every number below is measured twice.

*Ephemeral-artifact note (PROTOCOL §4.1): the per-mutant logs live under
`build/campaign/` and in a scratch directory. Neither is committed. Both
regenerate from the command above at this SHA.*

**Applied discipline, confirmed**: every mutant recorded `rtl_files_changed=1` —
each run was [frozen base + exactly one diff], nothing else.

**Two grounds below are established by experiment rather than assertion** (§4,
M1–M3 and M4–M7). Both were run in scratch trees outside the repository; no bench
was modified in the tree, because the denominator may not move under a running
campaign. Each recipe is: copy `rtl/` + `test/` to a scratch directory, apply the
named patch from `docs/reports/audit/WO-0002-mutations/`, make the one stated
bench edit, then `iverilog -g2012 -f rtl/uart_lite.f test/tb_<name>.sv -o x.out &&
vvp x.out`. The edits are stated verbatim at each experiment.

---

## 2. The unsealing

The seal was opened by this seat, for the first time and for this purpose, at
this round. Per the seal's §0 the State line remains `FROZEN — unopened.`
byte-for-byte and **no byte of the seal has been rewritten**; the unsealing is
recorded in the campaign packet's Return log as round 3 and here. The seal's
second copy in `J-dv_lead-0002` is likewise untouched and remains the
cross-check any reader can run.

---

## 3. The scored tally

Scoring is the seal's §5, written before any result existed. **KILL requires
every REQUIRED row of that class to go red, carrying the message named in
advance.** A REQUIRED row that stays green is a MISS. A red in MUST-STAY-GREEN is
a FINDING, never a kill. PERMITTED rows carry no score.

| id | sealed | REQUIRED | red | missed | MSG-red (findings) | score |
|---|---|---|---|---|---|---|
| TG-1 | KILL | 9 | 9 | 0 | 0 | **CLEAN KILL** |
| TG-2 | KILL | 10 | 10 | 0 | 0 | **CLEAN KILL** |
| TG-3 | KILL | 4 | 1 | **3** | 0 | **PARTIAL — not a kill** |
| TX-1 | KILL | 242 | 242 | 0 | 0 | **CLEAN KILL** |
| TX-2 | KILL | 1 | 1 | 0 | 0 | **CLEAN KILL** |
| TX-3 | KILL | 2 | 2 | 0 | 0 | **CLEAN KILL** |
| TX-4 | SURVIVE | 0 | — | — | 0 | **PREDICTION HELD** |
| RX-1 | KILL | 276 | 274 | **2** | **1** | **PARTIAL — not a kill** |
| RX-2 | KILL | 11 | 11 | 0 | 0 | **CLEAN KILL** |
| RX-3 | KILL | 2 | 0 | **2** | 0 | **MISS — class survived; prediction wrong** |
| RX-4 | SURVIVE | 0 | — | — | 0 | **PREDICTION HELD** |
| FF-1 | KILL | 10 | 9 | **1** | 0 | **PARTIAL — not a kill** |
| FF-2 | KILL | 4 | 4 | 0 | **3** | **KILL on REQUIRED + 3 findings** |
| LT-1 | KILL | 3 | 3 | 0 | 0 | **CLEAN KILL** |
| LT-2 | SURVIVE | 0 | — | — | 0 | **PREDICTION HELD** |
| LT-3 | KILL | 3 | 2 | **1** | **1** | **PARTIAL — not a kill** |
| LT-4 | KILL | 2 | 2 | 0 | 0 | **CLEAN KILL** |

**Totals.** 579 REQUIRED cells sealed; **570 red, 9 missed**. 5 out-of-prediction
reds (findings). Of 17 classes: **9 clean kills on every REQUIRED cell**
(8 with no findings at all, FF-2 with three), **4 partials** (caught, but not in
every row the seal named), **1 class not detected at all** (RX-3), **3 SURVIVE
predictions that held exactly**.

The seal said "14 KILL, 3 SURVIVE. **If all 17 kill, this seal was wrong three
times.**" It was not wrong three times in that direction: all three SURVIVE
predictions held. It was wrong in the other direction — one predicted kill did
not happen, and four happened less completely than sealed.

### 3.1 What landed exactly, and is therefore evidence

These are stated because the seal staked them in advance and a reader is entitled
to check them:

- **TX-2 — one row in 609, named in advance.** Observed: exactly one failing unit
  in the whole suite, `[REQ-004] tx_ready falls the cycle after acceptance and
  stays low until the stop bit completes`. The three differently-worded rows that
  *appear* to cover a missing stop bit — `stop bit is high`, the REQ-002 boundary
  row, the 256-byte REQ-003 sweep — all stayed green, as sealed. This is the
  sharpest claim in the seal and it is exact.
- **TX-1 — the palindrome arithmetic.** Sealed: 240 of 256 REQ-003 rows red, and
  the surviving 16 named individually. Observed: exactly 240 red, and the 16 green
  rows are exactly the sealed list — `0x00 0x18 0x24 0x3c 0x42 0x5a 0x66 0x7e 0x81
  0x99 0xa5 0xbd 0xc3 0xdb 0xe7 0xff`. The top-level loopback row printed
  `(240 mismatches)` — the count was part of the prediction. **See §9: this seat
  may not cite this result as evidence about the blind.**
- **RX-1 — the tolerance-sweep boundary.** Sealed: red from `P=433`, green at
  `P≤432`, from the inequality `0 ≤ (432−P)·n + 2 < P`. Observed: green
  `P=422…432`, red `P=433…447`. The boundary is exactly where the derivation put
  it.
- **RX-2 — the other boundary.** Sealed: red from `P=440`, green at `P≤439`, from
  `0 ≤ 210 + 416·n − P·n < P` binding at n=9 to give P ≤ 439.3. Observed: green
  `P=422…439`, red `P=440…447`. Exact. And the sealed claim that **598 of 609 rows
  stay green** held: all 256 nominal-period REQ-007 rows and all 12 `tb_uart_lite`
  rows — including the loopback — passed against a receiver running 3.7 % fast.
- **TG-1 vs TG-2 — direction discrimination.** The pair exists to test whether the
  suite discriminates the *sign* of an anchor error or merely notices trouble.
  TG-1 reddened 9 rows, TG-2 reddened 10, and the sets differ in exactly the one
  row the seal named as the discriminator: `tx_ready rises again once the stop bit
  has completed`. The suite discriminates direction.
- **TG-1's staked claim.** The seal staked the class on whether the REQ-002
  boundary row — re-anchored to the acceptance cycle at `J-dv_lead-0001` after the
  historical bench passed 265/265 against this same defect — now has teeth. **It
  fired.** The amendment worked. Had it stayed green that would have been a
  finding against this seat; it is recorded here because the stake was recorded in
  advance.
- **Observed values matched their sealed derivations.** REQ-006 clean-frame
  latency: control 4110; RX-1 observed **3894** (exactly 216 low — the sealed
  ground, "roughly 216 low"); RX-2 observed **3958** (exactly 152 low — matching
  the auditor's independently measured 152). *Honest note: the seal's round
  numerals were "near 3890" and "near 3955"; both were approximations of the
  control value, off by 4 and 3 cycles respectively. The derivations were right;
  the arithmetic on the control constant was loose. Recorded, not smoothed.*

---

## 4. The nine misses, each named with its ground

Rule 2: a REQUIRED row that stays green is a MISS, named individually with the
row, the class, and **the reason the row could not see the defect** — a finding
against the bench and, where the seal claimed the row would fire, against this
seat.

### M1–M3 · TG-3 · three of four suppression rows (`tb_uart_tick_gen`)

Green: `N=2:`, `N=27:`, `N=434: tick suppressed during the restart pulse cycle
itself`. Red: `N=3:` only.

**Ground — proven by experiment, not asserted.** The defect emits a spurious
`tick` only when the divider happens to sit at terminal count in the restart
cycle. The bench runs into one arbitrary phase — `repeat (2*n + (n/2) + 1)
@(posedge clk)` at `test/tb_uart_tick_gen.sv:156` — and tests that single phase.
Sweeping that constant on the TG-3 mutant in a scratch tree moves the red set:

| extra pre-restart delay | suppression row RED for |
|---|---|
| +0 (as shipped) | `N=3` |
| +1 | `N=2` |
| +2 | none |
| +3 | `N=2`, `N=3` |
| +4 | none |

`N=27` and `N=434` never redden at any of the five phases tried. **The row's
detection probability is ~1/N**, so at N=27 and N=434 it is effectively blind to
the property it names. The row does not test suppression; it tests suppression at
one arbitrary phase.

**Against this seat.** The seal claimed: "The phase is deterministic per N, so
this is a deterministic prediction, not a probabilistic one." The determinism was
real and the inference from it was wrong — a deterministic phase is still *one*
phase. This seat asserted all four rows would fire without deriving the counter
value at the restart cycle for each N. That is the L-C09 discipline (read the
iteration order before sealing a message) applied to ordering but not to
arithmetic. Wrong prediction, on the record.

### M4–M7 · RX-1 and RX-3 · the two REQ-008 rows, missed under *both* classes

Green under both classes:
`a brief low glitch that returns high before the confirmation sample produces
neither rx_strobe nor rx_frame_err`, and
`receiver has returned to idle (rx_busy low) after an abandoned false start`.

**Ground — the REQ-008 case is structurally vacuous.** It is preceded by
`measure_frame_err_latency(8'hA5, RX_BIT_PERIOD)`, which sends a **bad-stop**
frame (`test/tb_uart_rx.sv:203`); `bench_send_frame`'s last act drives the stop
bit **low**, so `rx_line` is left at 0. `settle(50)` holds it at 0. The REQ-008
case then calls `bench_drive_bit(1'b0, 40)` — driving a line that is *already
low* — before raising it. **There is no falling edge, so the receiver never
starts a frame, so no false start is ever presented.** Both rows then pass
trivially, for any receiver that happens to be idle — including one with the
false-start logic entirely removed.

**Verified by a three-arm experiment**, so the cause is isolated rather than
asserted. In a scratch tree outside the repository, a genuine idle-high interval
(`bench_drive_bit(1'b1, 100)`) was inserted before the glitch so that a real
falling edge exists:

| arm | RTL | bench | REQ-008 `rx_busy` row | bench total |
|---|---|---|---|---|
| **A** | RX-3 mutant | as shipped | **PASS** | 291/291 green |
| **B** | RX-3 mutant | genuine idle-high inserted | **FAIL** | 287/291 |
| **C** | **unmutated** | genuine idle-high inserted | **PASS** | 291/291 green |

Arm C is the one that makes the experiment conclusive: the inserted stimulus does
not itself break anything, so B's failure is attributable to the mutation and to
nothing else. Arm A reproduces the campaign result exactly.

The rows stay green in the shipped suite because of the *stimulus*, not because
of the receiver. **REQ-008 is currently unverified by this suite.**

A second, independent weakness in the first of the two rows: it compares strobe
counters sampled 490 cycles after the glitch, while an unabandoned bogus frame
does not strobe until ~4106 cycles. Even with a genuine false start it stays
green (measured in the experiment above). That row is broken twice.

### M8 · FF-1 · `FIFO is empty again after draining exactly 16 entries` (`tb_uart_lite`)

**Ground.** Under a FIFO that fills at 15, the drain loop pops 16 times; the 16th
pop lands on an empty FIFO and is *silently ignored* by the FIFO's own
pop-while-empty rule. The row then asserts `rx_valid === 1'b0` on an empty FIFO
and passes. **The row cannot distinguish a 15-deep FIFO from a 16-deep one**,
because over-popping is free. Its message says "exactly 16 entries"; its assertion
observes only that the FIFO ended up empty.

### M9 · LT-3 · `FIFO is empty again after draining exactly 16 entries` (`tb_uart_lite`)

The *same row* misses again, for the opposite reason — and this is the more
interesting of the two.

**Ground.** Under inverted `rx_valid`, the FIFO's `rd_en` is `rx_valid & rx_ready`
as wired in `uart_lite`, so with `rx_valid` low on a non-empty FIFO **no pop ever
happens**. The drain loop drains nothing. At the end the FIFO still holds 16
entries, `fempty = 0`, so `rx_valid = fempty = 0`, and the row asserting
`rx_valid === 1'b0` **passes on a FIFO that never drained**.

**Against this seat.** The seal predicted this row RED, reasoning that "the drain
loop pulses `rx_ready` unconditionally rather than gating on `rx_valid` … so it
still empties the FIFO in order." That was wrong: the gating this seat looked for
in the *bench* lives in the *design's* port wiring. The row passed for a reason
opposite to the one that would have made it pass correctly.

---

## 5. The five out-of-prediction reds (findings, never kills)

Rule 3. Each is named with row and class. **None is counted as a kill**, and none
is used to improve any score.

| # | class | row that reddened | verdict |
|---|---|---|---|
| F-a | RX-1 | `byte 0xff received correctly at the nominal sender bit period` | seal wrong — §5.1 |
| F-b | FF-2 | `full asserted exactly when level=DEPTH over 10000 random operations (939 mismatches)` | seal wrong — §5.2 |
| F-c | FF-2 | `empty asserted exactly when level=0 over 10000 random operations (4 mismatches)` | seal wrong — §5.2 |
| F-d | FF-2 | `level tracks the reference model exactly over 10000 random operations (1762 mismatches)` | seal wrong — §5.2 |
| F-e | LT-3 | `the 16 stored bytes are unchanged and read out in the order written (dropped 17th byte and the framing-error byte are absent)` | seal wrong — §5.3 |

### 5.1 F-a — the named `0xff` survivor did not survive

Sealed as **MUST-STAY-GREEN** — "the one REQ-007 row that survives" — with an
explicit derivation. Observed: **red**. All 256 REQ-007 rows reddened, not 255.

The seal reasoned that under boundary sampling the grid reconstructs
`{d6,d5,d4,d3,d2,d1,d0,d0}` with the stop sample reading d7, so correct reception
requires all eight bits equal *and* d7 = 1 — only `0xFF`. The seeder's disclosed
collision perturbs that grid: the mutated sample list contains oversample tick 0,
which is the falling-edge cycle, where no tick event occurs, so start confirmation
is never taken and the frame's phase differs from the one this seat modelled.

Recorded as a finding and a wrong derivation. It is **not** retro-fitted into a
kill, even though doing so would have made RX-1 look better: the row was named as a
survivor in advance, and a named survivor that dies is a wrong prediction, not a
bonus.

### 5.2 F-b/F-c/F-d — the FIFO flag rows

**The ground, and it is a credit to the bench.** The seal predicted
that FF-2 (write-while-full overwrites the oldest) leaves the *flags* untouched:
"`level` stays 16, `full` stays high, `empty` is unaffected." The seeder's own
fidelity argument says the same thing — "`full`, `empty` and `level` follow
exactly the same trajectory as the control … the read supplies the pointer
advance and the level is unchanged, which is the same net effect."

**Both models are wrong, and `tb_uart_fifo`'s 10 000-operation random sweep caught
it.** In the coincident read-and-write-while-full case the DUT holds `level` at
DEPTH (`case ({do_wr, do_rd})` selects `2'b11` → default → hold), while a
spec-conformant FIFO ignores the write and *decrements* on the read. The bench's
reference model (`model_q`, `test/tb_uart_fifo.sv:100-113`) implements the spec,
so it diverges — correctly. Two independent readers of the design, working from
opposite directions, both missed a case that the bench's randomised sweep found.
That is the bench being stronger than its adjudicator's model of it, and it is
worth more than a clean prediction would have been.

### 5.3 F-e — the lite byte-order row under LT-3

Same mechanism as M9: with `rx_valid` inverted, `rd_en = rx_valid & rx_ready` is
never asserted on a non-empty FIFO, so no pop occurs and every `seen_bytes[i]`
reads the same unchanged head. The order check therefore fails. The seal placed
this row in MUST-STAY-GREEN on the premise that the drain loop pulses `rx_ready`
unconditionally — true of the bench, but irrelevant, because the gating lives in
the design's port wiring rather than in the bench.

---

## 6. Vacuities — three sealed in advance, three found by the campaign

Rule 9: a green vacuity is not a credit to the suite and is reported as a vacuity
even when green.

**Sealed at freeze (§2.3), all three confirmed exactly as predicted:**

| row | class that proves it | observed |
|---|---|---|
| `d0..d7 on the wire equal tx_data, LSB first (byte 8'b10100101)` | TX-1 | **green** — the suite's only bit-order row cannot detect a bit-reversal, because `0xA5` is a bit-reversal palindrome |
| `full asserted exactly when level=DEPTH=16 after 16 writes` | FF-1 | **green** — its message claims exactness, its assertion is `full === 1'b1` |
| `rx_ovr_clr clears rx_overrun` | LT-1 | **green** — it cannot distinguish "cleared" from "was never set" |

**Found by this campaign, not sealed — new obligations:**

| row(s) | discovered via | why it is vacuous |
|---|---|---|
| the two REQ-008 false-start rows | RX-3 (survived), RX-1 (2 misses) | the stimulus contains no falling edge, so no false start is ever presented; **cannot fail under any receiver behaviour** as written |
| `FIFO is empty again after draining exactly 16 entries` | FF-1 (M8) and LT-3 (M9) | passes on an over-popped FIFO *and* on a FIFO that never drained — vacuous in two independent ways |
| `N=%0d: tick suppressed during the restart pulse cycle itself` | TG-3 (3 misses) | not strictly vacuous — it *can* fail — but detection probability is ~1/N, so it is effectively blind at N=27 and N=434 |

**Six rows in 609 do not do what their text claims.** Three were sealed before any
defect existed; three the campaign found. That ratio — half the vacuities visible
by reading, half only by mutating — is itself the argument for running campaigns.

---

## 7. Disposition of every survivor, individually

Six mutants survived. No ratio stands in for these (rule 9). The auditor's
judgements on TX-4 and RX-4 are **weighed here, not inherited** — they are
statements about the design, and the question this campaign asks is about the
suite.

### TX-4 — `tx_busy` never asserts · **coverage gap** (predicted survivor, ground held)

Sealed SURVIVE, 609/609 green. Observed: 609/609 green. **Prediction held exactly.**

*Disposition: coverage gap in the suite — not an equivalent mutant.*

The auditor calls it "equivalent at the `uart_lite` boundary", because
`uart_lite` instantiates the transmitter with `.tx_busy()` unconnected
(`rtl/uart_lite.sv:27`). **That is correct and it is not the whole question.**
The suite is not only `tb_uart_lite`. `tb_uart_tx` instantiates `uart_tx`
directly, where `tx_busy` is a port and its value is wrong whenever the
transmitter is running. The suite therefore *has* a bench at the boundary where
the defect is observable, and that bench reads `tx_busy` exactly once — at reset,
in the one state where the correct and the defective design agree
(`post-reset: tx_busy is low (idle)`, `test/tb_uart_tx.sv:122`). **No row anywhere
in the 609 samples `tx_busy` while a frame is in flight.**

Equivalence is a proof obligation discharged over the whole legal stimulus space
(PROTOCOL §10). At the `uart_lite` boundary that obligation is discharged. At the
`uart_tx` boundary it is not, and cannot be — the mutant is observably wrong
there. So the correct disposition is **gap**, and the auditor's equivalence claim
is accepted only for the top level.

This is the **silently-always-pass** class PROTOCOL §10 requires every
qualification to own: the design is wrong against a numbered spec clause, the
suite is green, and a named row passes while asserting something true only by
coincidence. It delivered exactly what it exists to deliver, and it was left
quiet as instructed.

### RX-3 — false start not rejected · **coverage gap** (prediction WRONG)

Sealed KILL on 2 REQUIRED rows. Observed: **609/609 green — the class was not
detected at all.**

*Disposition: coverage gap, and the most serious finding of this campaign.*

Not an equivalent mutant: the auditor measured a false-start stimulus completing
and strobing `0xFF` where the control abandons silently. The defect is real,
observable at both the `uart_rx` and `uart_lite` boundaries, and the suite is
blind to it — for the structural reason proven by experiment in §4 (M4–M5): the
REQ-008 stimulus presents no falling edge, so no false start ever reaches the
receiver.

**REQ-008 is a requirement with a check that names it, a message that describes
it, and no stimulus that exercises it.** It must not be recorded as discharged in
any `SO-`.

### RX-4 — one synchroniser flop, not two · **declared gap** (predicted survivor, ground held)

Sealed SURVIVE, 609/609 green, with the ground "REQ-013 has no executable owner".
Observed: 609/609 green. **Prediction held exactly.**

*Disposition: declared gap — and the mutant is not equivalent.*

The auditor's judgement is that the property destroyed — metastability margin on
an asynchronous input — is "not observable in any RTL simulation". **Accepted, as
to the property.** RTL simulation has no metastability for a margin to be against,
and REQ-013's stated Method is *inspection*
(`docs/specs/requirements.md:26`), which the suite honours by printing
`[REQ-013] SKIP` (`test/tb_uart_lite.sv:254`) — a line that is not a check and is
not one of the 609.

**Not inherited as equivalence.** The mutant is *not* equivalent: everything
downstream happens one cycle earlier, and the auditor's own probe measured the
strobe moving 4108 → 4107. The only row that could have noticed is REQ-006, whose
window `[4105, 4116]` is twelve cycles wide and was deliberately widened to absorb
exactly this latency. So a green here is a *choice* the bench made, not a
property of physics. The honest statement is two-part and both parts matter:
the requirement's substance is unobservable in simulation, **and** the suite
additionally cannot see the one-cycle shift that *is* observable.

Consequence: **no `SO-` may record REQ-013 as a discharged row.** It is carried as
a declared gap needing an inspection owner.

### LT-2 — a framing error writes the FIFO · **coverage gap** (predicted survivor, ground held)

Sealed SURVIVE, 609/609 green. Observed: 609/609 green. **Prediction held exactly.**

*Disposition: coverage gap — worse than an ordinary one.*

Not equivalent: the auditor measured a bad-stop frame's byte appearing at
`rx_data` with `rx_valid` high, where the control produces nothing. The suite
contains exactly one top-level framing error — the `8'hEE` bad-stop frame at
`test/tb_uart_lite.sv:217` — and it is sent **while the FIFO already holds 16
entries**, so the illegal write is swallowed by the FIFO's own write-while-full
rule before it can corrupt anything. The row
`the 16 stored bytes are unchanged and read out in the order written (dropped 17th
byte and the framing-error byte are absent)` asserts in its own parenthetical that
the framing-error byte is absent — **and it is absent, for a reason that has
nothing to do with the clause the row claims to check.**

**There is no case anywhere in the 609 in which a framing error arrives at a FIFO
with room in it.** The clause is stated in the spec, quoted in a check's message,
and untested.

### NM-1 — rename + equivalent `empty` expression · **out-of-scoring control**

Survived, 0 of 609 rows red. *Disposition: control, not scored — see §8.*

The equivalence argument is a proof obligation (PROTOCOL §10) and the auditor
discharged it over the whole 4-state domain of `level`: the `==` form and the
`~(|level)` form agree on all-zero, on any-bit-one, and on the mixed
zero/X/Z case. **Reviewed and accepted.** Alpha-renaming two module-internal nets
cannot affect simulation semantics.

### NM-2 — equivalent increment expression · **out-of-scoring control**

Survived, 0 of 609 rows red. *Disposition: control, not scored — see §8.*

Equivalence re-derived independently by this seat rather than accepted on the
seeder's word: `cnt + 1` evaluated at 32 bits and truncated by `CW'()` yields the
low CW bits, which is identical to CW-width addition modulo 2^CW, for every value
of `cnt` including the all-ones wrap; and with N = 27 (CW = 5) and N = 434
(CW = 9) the wrap is unreachable in any case. **Accepted.**

---

## 8. Ruling on F-06 — the near-miss controls

The auditor asked for a ruling on NM-1 and NM-2 before the runs, noting that they
sit outside the sealed surface and have no predicted cells. The request was
correct to make and this seat did not answer it in time — the ruling is issued
now, which is later than the auditor asked and later than it should have been.
**Recorded as such rather than back-dated.**

**Ruling: ADMITTED as out-of-scoring instrument controls.**

- They contribute **0 to the numerator and 0 to the denominator**. The denominator
  was fixed at freeze at 609 units over 17 classes and does not move (L-C08).
- They **cannot be scored against the seal**, because the seal classifies no cell
  of theirs. Scoring them would manufacture exactly the rule-3 "red cell outside
  the prediction" case for a mutant the seal never had the chance to classify. The
  auditor's reasoning on this point is sound and is adopted.
- They nonetheless **carry a verdict**, and it is not a score: they test the
  *instrument*, not the suite. Their result is recorded as the campaign's
  **instrument-validity check: PASSED** — 0 of 609 rows red in each, against two
  edits argued equivalent over the whole legal stimulus space.

**Why this is not a technicality.** The controls' green is a *precondition* for
every other number in this report meaning anything. Had either reddened, the
suite would have been shown to redden at edits that change no behaviour, and every
red elsewhere in the campaign would be suspect — the instrument, not the design,
would be the finding. Two behaviour-preserving edits, one of them planted in the
timing core where an edit looks most alarming, produced zero reds.

**What they do not license.** Two equivalent mutants are a sample of two. This
campaign does not establish that the suite has no false positives in general; it
establishes that it had none on these two.

---

## 9. Ruling on F-01 — did the blind hold?

This is a finding against the orchestrator and this seat's own freeze, routed
here because the party a finding names cannot rule on it. This seat's seal is what
is at stake, so the ruling is written to be checkable rather than reassuring.

### 9.1 What was leaked, precisely

The subject line of the freeze commit `c7762b0` was rendered into the blinded
seeder's context by the §4.1 precheck's mandated `git log --oneline -1`. Broken
into its claims:

| the subject says | sealed? | verdict |
|---|---|---|
| seventeen classes | **no** — the brief §2 publishes all 17 intents | no leak |
| "with their expected message text" | says *that* messages are sealed, not which | no discriminating content |
| "found three rows that cannot fail" | **yes** — seal §6 forbids "the three vacuous rows of §2.3" | **leak: the count** |
| "including the only bit-order check, which uses a palindrome" | **yes** — seal §6 forbids "the 16 palindromic bytes" and the §2.3 vacuities | **leak: a discriminating property of a specific check** |

The last row is the serious one. It tells the seeder three things at once: the
suite has exactly one bit-order check; that check uses a palindromic byte;
therefore it cannot detect a bit-reversal defect. That is precisely what §0 seals.

**F-02 compounds it.** The spawn dispatch widened the allowlist and ordered
`tasks/BOARD.md` read as a mandatory first action, before the seeder reached the
brief forbidding it. BOARD.md carries per-bench check counts, the bench→REQ
mapping, and — by the seeder's own disclosure — "a narrative paragraph about a
requirement a defective transmitter formerly satisfied." **That paragraph is
TG-1's staked claim**: the historical bench passed REQ-002 265/265 against the
BUG-0001 anchor defect. So the contamination is not one class but two.

### 9.2 The test this seat applied

A leak voids a mutant's score **only if it could have changed the mutant**. The
score measures the *suite's response*, and the suite's response is a function of
the diff, not of what the seeder knew. So the operative question is: **did the
leaked information reach any decision the seeder actually had?**

The seeder had no discretion over *which* defects to seed — the brief publishes
all 17 intents and the manifest authors those 17 and nothing else. The only
discretion available is *where within a class a diff lands* and *how strong it is*.
This seat therefore read every diff against its published intent. For the two
contaminated classes:

- **TX-1**: `sh <= {1'b1, tx_data[0]…tx_data[7], 1'b0}` — a pure bit-reversal of
  the shift-register load. "MSB-first" denotes exactly one behaviour and this is
  it. There is no weaker or stronger version available, so there was no decision
  for the leak to steer.
- **TG-1**: `cnt <= CW'(1)` in the anchor branch — the minimal reload change
  producing "first tick one cycle early". Likewise fully determined.

The two places the seeder *did* have a genuine choice — TX-3 and RX-2, instantiation
(`DIV_TX - 1`, `DIV_OS - 1`) versus the package constant — were disclosed in the
manifest with the alternative named and the reason given, and neither touches
leaked material.

### 9.3 The ruling

**No score is withdrawn. No mutant is re-run. The blindness claim is void for
TX-1 and TG-1, and weakened globally.**

1. **Score validity — intact for all 17 classes.** Each mutant is the minimal
   determined realisation of a *published* intent. The suite's response to a
   determined diff is a property of the suite. The leak could not make a bench
   redden or stay green.
2. **Blindness claim — VOID for TX-1 and TG-1.** For these two, the seeder had
   been told, in advance, material the seal protects. This campaign **may not be
   cited** as evidence that a seeder ignorant of the benches produced a mutant
   whose subtle row-level behaviour the seal then predicted. For TX-1 in
   particular — the campaign's most impressive-looking result, 240 reds with
   exactly 16 named survivors — **the subtlety was in the commit subject.** The
   seal's *priority* is intact (the seal is in `c7762b0`, the diffs in `4fe6014`,
   and the seal is byte-identical, §1); the *independence* of the seeder from the
   suite's structure is not, for this class.
3. **Blindness claim — weakened globally by F-02.** The seeder knew the suite's
   *shape* — per-bench check counts and the bench→REQ mapping — before reading the
   brief that forbade it. It did not thereby know what any check asserts. The
   honest global statement is: **the seeder knew the suite's shape and not its
   content.**
4. **Re-running is not the remedy and would not be one.** The contaminated diffs
   are uniquely determined by their published intents, so a fresh seeder would
   author the same two diffs. A re-run would cost a day and change no number. The
   remedy is the disclosure in ruling 2, which is permanent and travels with every
   citation of TX-1.
5. **F-01's CRITICAL trigger is discharged, not avoided.** The auditor wrote that
   F-01 "becomes CRITICAL if the adjudication relies on the leaked property without
   recording that the seeder had been exposed to it." **This adjudication does rely
   on the leaked property** — the palindrome result is the seal's showpiece in §3.1.
   The exposure is therefore recorded at the point of reliance, in §3.1 and here.
   With that recorded, F-01 remains **MAJOR**.
6. **Responsibility.** The auditor declined to adjudicate between this seat and the
   orchestrator, and it was right not to. This seat rules that it lands on both,
   and takes its own share first: **the hygiene rule the subject line defeats is a
   rule this seat wrote, in a packet this seat authored, protecting a seal this
   seat froze — and this seat did not read the subject line that carried its own
   freeze.** Authoring a rule is not complying with it. The orchestrator, as sole
   committer and holder of §0's relay restriction, owns the other share.
7. **What was NOT contaminated, stated so the ruling is bounded.** The leak's
   "three rows that cannot fail" points at FF-1, LT-1 and TX-1. FF-1's and LT-1's
   vacuous rows stayed green exactly as sealed, and neither class's diff shows any
   sign of steering. The seal's most protected item — that **three classes were
   expected to survive** (TX-4, RX-4, LT-2) — was **not** leaked, and the evidence
   supports that: TX-4 was left deliberately quiet, exactly as a seeder ignorant of
   its predicted survival would leave it. A seeder who had known would have been
   tempted to make it louder, and the measurement would have been destroyed.

### 9.4 The standing weakness this ruling does not cure

The attestation that `test/**` was never opened is the seeder's own testimony
about its own conduct, corroborated by its own report. PROTOCOL §9's honest-
enforcement note and the brief's §1 both say plainly that read restrictions are
not mechanically enforceable here. That was true before the leak and is unchanged
by it: **the leak does not weaken the attestation, and the attestation does not
cure the leak.** Any reader weighing this campaign should know that the blind rests
on disclosure discipline, not on a mechanism — and that in this round the
disclosure discipline worked (the seeder disclosed the exposure unprompted, and
declined `docs/adr/**` that the dispatch had wrongly opened to it).

### 9.5 Obligation arising

F-03 is correct that the §4.1 precheck is the *delivery mechanism* for F-01: two
rules that cannot both be honoured as written. The remedy — pinning a baseline
with `git log -1 --format=%H`, which records the pin and renders no subject —
belongs in an ADR under PROTOCOL §11 and is the orchestrator's to raise. Recorded
here as an obligation, not actioned: `agents/PROTOCOL.md` is outside this seat's
write scope.

---

## 10. What this campaign licenses

**A reader may now truthfully say:**

- The five-bench suite (609 checks) was measured against **17 spec-derived defect
  classes plus 2 equivalence controls**, each run as [frozen base + exactly one
  diff] under a 240 s wall-clock timeout, against predictions **sealed before any
  defect existed** and never edited.
- **16 of 17 classes were detected** by at least one check. **1 was not detected at
  all** (RX-3, false-start rejection).
- **9 of 17 classes reddened exactly the rows named in advance, with the messages
  named in advance** — including a one-row-in-609 prediction (TX-2), two
  independently derived tolerance boundaries that landed exactly (P=432/433,
  P=439/440), a 240/16 palindrome split named byte-by-byte, and a single-row
  discrimination between two opposite-sign anchor defects.
- **3 classes predicted to survive did survive**, each on a ground stated in
  advance.
- The suite **does not redden at behaviour-preserving edits** (2 controls, 0 reds).
- The campaign is **byte-reproducible**: two independent executions produced
  identical failure-message sets for all 19 mutants.
- **At least 6 of the 609 checks cannot do what their text claims** — 3 identified
  by reading before the campaign, 3 that only mutation exposed.

**A reader may NOT say:**

- **That this is a detection rate.** Seventeen classes is evidence about seventeen
  classes. No percentage computed from this table means anything, and no `SO-` may
  quote one (seal rule 10).
- **That the benches are qualified.** Five classes have surviving REQUIRED cells
  (RX-3 entirely; TG-3, RX-1, FF-1, LT-3 partially). Under charter §6.3 a surviving
  REQUIRED mutation **blocks the module-ready gate**.
- **That REQ-008 is verified.** It has a check that names it and no stimulus that
  exercises it.
- **That REQ-013 is verified.** It has no executable owner; its Method is
  inspection and the suite prints `SKIP`.
- **That `tx_busy` is verified.** No row samples it while a frame is in flight.
- **That the spec clause "a framing error does not write the FIFO" is verified.**
  No case presents a framing error to a FIFO with room in it.
- **That the seeder was blind, for TX-1 or TG-1.** See §9.
- **That the suite has no false positives.** Two equivalent mutants is a sample of
  two.

### 10.1 The board sentence

`tasks/BOARD.md` currently states: *"No mutation campaign has been run. Nothing
establishes in general that these benches would catch a defect."*

**The first sentence is now false and should change. The second should be
narrowed, not deleted.** Proposed replacement (BOARD.md is orchestrator scope —
this is a proposal, not an edit):

> A mutation campaign has been run and adjudicated (WO-0002, `J-dv_lead-0003`):
> 17 spec-derived defect classes plus 2 equivalence controls, seeded blind by the
> auditor against predictions sealed before any defect existed. 16 of 17 classes
> were detected; 9 reddened exactly the rows and messages named in advance; 1
> (RX-3, false-start rejection) was not detected at all, and 6 checks were found
> unable to do what their text claims. This is evidence about 17 classes, not a
> detection rate. The blind is disclosed as broken for 2 classes (audit F-01/F-02,
> adjudicated at `J-dv_lead-0003` §9).

**The module-ready gate stays UNSIGNED, and this campaign is now one of the
reasons rather than the absence of one.** Five classes carry surviving REQUIRED
cells; charter §6.3 makes that a block. **This report does not sign the gate and
is not a request to sign it.**

---

## 11. Obligations arising (not actioned in this round)

The seal's §1 requires a coverage gap found mid-campaign to be recorded as an
obligation and acted on **after** adjudication, so the denominator cannot move
under a running campaign. Adjudication completes with this file; the following are
owed to a subsequent work order and **were deliberately not made here**:

1. **REQ-008 — restore a real false start.** Drive `rx_line` genuinely idle-high
   before the glitch so a falling edge exists, and sample the strobe counters
   after a full frame time rather than 490 cycles. Both rows are currently
   incapable of failing. *(Highest priority: it is the only wholly undetected
   class.)*
2. **REQ-005 suppression — test the property, not one phase.** Sweep the divider
   phase across all N residues, or force the counter to terminal count before the
   restart pulse. Current detection probability ~1/N.
3. **`FIFO is empty again after draining exactly 16 entries`** — assert the byte
   count actually popped, not the terminal emptiness that over-popping and
   never-popping both produce.
4. **`tx_busy`** — add a `tb_uart_tx` row sampling it while a frame is in flight.
   One row closes the silently-always-pass gap.
5. **The framing-error write rule** — add a top-level case presenting a bad-stop
   frame to a FIFO with room in it.
6. **The three sealed vacuities of §2.3** — the palindromic bit-order byte (use a
   non-palindrome), the one-directional `full` assertion, and the
   `rx_ovr_clr` row that cannot distinguish cleared from never-set.
7. **REQ-013** — either an inspection owner of record, or removal of the claim
   that it is discharged.
8. **Watchdogs** — three unbounded wait loops (seal §2.2) turn a class of defect
   into a hang rather than a failure. The campaign works around it with an
   external timeout; the durable fix is a per-bench simulation timeout.

Items 1–6 are coverage repairs to `test/**`; each **re-opens the campaign
question** for the class it touches, and a repaired bench is not qualified until
re-measured.

---

*Adjudicated by dv_lead against `agents/handoffs/WO-0002-SEALED-predictions.md`,
which was opened for the first time in this round and has not been edited. Wrong
predictions are recorded above under their own names, per L-C05: a prediction that
can be edited after its result is not a prediction.*
