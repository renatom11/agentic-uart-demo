# Journal: claude_tb_writer_agent

- **Agent**: tb_writer (Sonnet-class worker template)
- **Charter**: agents/charters/tb_writer.md
- **Format**: v2 — entry grammar in agents/PROTOCOL.md §4

This file is APPEND-ONLY. Content may only ever be added after the last line;
nothing above it is ever edited. Enforced by scripts/agent_commit.sh and CI.

---

## [J-tb_writer-0001] 2026-08-13T00:00Z | task:WO-0001 | uart_lite spec-derived DV suite, five bench files, REQ-005 defect found
### Trigger
Spawned by the orchestrator holding agents/handoffs/WO-0001-uart-lite-benches.md
("benches for uart_lite, written blind"), assigned to tb_writer. No explicit
spawn short-id token was minted into the spawning prompt (protocol says the
orchestrator mints work-order id + spawn UTC timestamp into every worker spawn
prompt); this entry's Trigger instead cites the WO- id and this journal
entry's own timestamp as the best available substitute -- flagged under
Open-questions as a protocol-conformance note, not a blocking issue.

### Inputs
- docs/specs/SPEC-uart_lite.md (full file)
- docs/specs/requirements.md (full file, REQ-001..REQ-017)
- agents/charters/tb_writer.md
- agents/PROTOCOL.md SS2-6, SS10
- agents/handoffs/WO-0001-uart-lite-benches.md (full file, including its
  three "Specific constraints carried into the packet")
- Icarus Verilog 12.0 compiler/simulator behaviour, observed by compiling and
  running my own bench files against the black-box DUT interface (driving
  documented ports, reading documented outputs) -- never by reading rtl/**
  source.

**Independence disclosure (honesty over silence, per charter SS8):** during
initial environment orientation, before I had located and read the WO- or
charter, I ran a plain `ls -la` across the workspace to determine which
repository held the actual assignment (the launching context pointed at a
different, unrelated repo path). That listing included
`/workspace/agentic-uart-demo/rtl/`, and its output showed six filenames,
byte sizes, and modification timestamps (uart_fifo.sv 1358B, uart_lite.f
181B, uart_lite.sv 1561B, uart_pkg.sv 578B, uart_rx.sv 2149B,
uart_tick_gen.sv 829B, uart_tx.sv 1352B, all Aug 12 23:15-23:16). This is a
literal violation of the charter's explicit "do not run `ls rtl/`" and I am
recording it rather than omitting it. I did not open, cat, grep, or read the
contents of any file under rtl/**, and rtl/uart_lite.f was passed to iverilog
by path only, per the work order's explicit permission, never read. The
filenames themselves match SPEC-uart_lite.md SS4's own public module
table exactly (uart_pkg, uart_tick_gen, uart_tx, uart_rx, uart_fifo,
uart_lite), so they added no information beyond the spec; the byte sizes and
timestamps were not used anywhere in deriving any expected value, port list,
or stimulus in the benches below -- every port name, width, and timing
constant in every file below traces to a SPEC-uart_lite.md or
requirements.md citation in that file's own header comment. I judge this a
low-severity, content-free exposure and continued the work order rather than
returning it unstarted, but per charter SS7 ("if RTL source somehow reaches
your context ... flag it") the disposition is dv_lead's and the auditor's
call, not mine -- see the WO- Return log and Open-questions below.

### Reasoning
Five bench files, one DUT module each (plus one top-level), all timing
tracked with `repeat(N) @(posedge clk)` relative delays and negedge-anchored
input drives -- never a free-running counter compared by absolute value from
a different process, which is exactly the race this spawn's first attempt at
tb_uart_tx.sv fell into (see Actions).

- **tb_uart_tick_gen.sv -- REQ-005.** SS5.1's "the k-th tick is high during
  cycle N.k" is read with k in {1,2,3,...} (ordinary ordinal convention: no
  tick at cycle 0, first tick at cycle N). Swept N in {2,3,27,434} per
  requirements.md's Method column, for both the reset-anchored and the
  restart-anchored case (restart pulse cycle suppressed, per SS5.1's port
  table; cycle 0 = the cycle AFTER the restart pulse, taking REQ-005's own
  words literally and symmetrically with the reset case). Each case is
  decomposed into three independent checks -- WHERE the first tick lands
  (phase), that consecutive ticks are exactly N apart (rate), and that tick
  is never high on two consecutive cycles -- specifically so a phase-only
  defect is diagnosable rather than buried in one aggregate boolean. First
  version of this file asserted a DIFFERENT k-convention (k including 0,
  tick at cycle 0) after finding SS5.3's own sampling table
  (oversample-tick-number x DIV_OS = clock-cycle, exact for all four rows:
  8x27=216, 24x27=648, ..., 152x27=4104) only closes if tick-numbering
  includes a 0th tick at cycle 0 -- a legitimate spec-only cross-reference,
  not RTL-derived. That version's checks all passed for N=2 (where the two
  readings coincide, N-2=0) but is the reading this file no longer asserts,
  because the ACTUAL first-tick cycle observed for N=3/27/434 was N-2 in
  every case (25 for N=27, 432 for N=434, 1 for N=3) -- consistent, exact,
  and uniform across four unrelated N values and both trigger types, and NOT
  predicted by k in {0,1,2,...} either (which predicts N-2=cycle 0 only
  works out for the N=2 coincidence). Given neither of the two textually
  defensible k-conventions matches the observed uniform "-2" offset, this
  file reverts to testing REQ-005's plain, ordinary-English reading (k in
  {1,2,...}) and reports the mismatch honestly rather than picking whichever
  convention happens to make the DUT pass -- see Evidence for the result.
- **tb_uart_fifo.sv -- REQ-015.** Directed checks (fill to full, drain to
  empty, write-while-full ignored, pop-while-empty ignored, 16-entry order)
  plus a 10000-operation randomised sweep (three phases: fill-biased,
  drain-biased, balanced churn, so both boundaries are hit repeatedly, not
  just reachable in principle) against a software reference queue, updated
  each cycle using the model's PRE-edge full/empty state -- matching
  SS5.4's "ignored when empty" / "silently ignored [while full]", which are
  conditions on the FIFO's state at the time of the request, not after it.
- **tb_uart_tx.sv -- REQ-001..REQ-004.** Directed frame-format and
  handshake checks, a boundary-exactness check for all 10 DIV_TX=434-cycle
  intervals, and all 256 byte values swept individually (one check per
  byte, matching the WO's own [REQ-007]-style example granularity). The
  boundary-exactness check first used 0xAA (1010_1010) on the theory that
  alternating data bits give a transition at every one of the 10 boundaries
  including start-to-d0 and d7-to-stop; this is wrong because d0 is 0xAA's
  LSB (=0), identical to the fixed start bit (=0), so there is NO transition
  at that boundary -- a test bug, corrected to 0x55 (0101_0101), whose LSB
  is 1, giving a genuine alternating sequence across the whole frame
  including both framing bits. Written up in this file's own header comment
  so the reasoning survives independent of this journal.
- **tb_uart_rx.sv -- REQ-006..REQ-012 (REQ-011 is the program's most
  important test per WO-0001).** All stimulus is a bench-model transmitter
  written in this file (bench_drive_bit/bench_send_frame), driving rx_line
  directly at an independent parameter P; uart_tx is never instantiated
  here. REQ-011 sweeps P=422..447 (26 values) x all 256 bytes = 6656 checks,
  driven at each frame's own independent P. REQ-012 sends 64 back-to-back
  frames with zero inserted idle gap (bench_send_frame's own frame end
  already leaves the line at the stop-bit's idle-high value, so calling it
  again immediately reproduces "no idle time between the stop bit of one and
  the start bit of the next" verbatim). REQ-010 is a continuous monitor
  (every cycle of every case in the file, from reset release onward).
  REQ-006 is the one place this bench's coverage is a declared PARTIAL, not
  a clean discharge -- see Evidence and the file's own header comment for
  the full account: three different black-box bracketing techniques
  (single-cycle glitch; sustained wrong-then-correct; sustained
  correct-then-wrong) gave three mutually inconsistent apparent boundaries
  for the start-bit confirmation point, which this bench reads as a
  confound in the bracketing method's interaction with the confirm/
  false-start logic (the sustained-wrong-then-correct form in particular
  plants a second, later falling edge, invalidating its own premise) rather
  than as three separate timing facts -- concluding a specific cycle number
  from any one of them, or from whichever one happened to "look cleanest",
  would be encoding a guess into the oracle, which the charter and WO-0001
  both rule out ("Never bake a guess into an oracle 'provisionally'"). What
  this bench DOES assert for REQ-006 is a robust end-to-end bound (elapsed
  cycles from the driven falling edge to rx_strobe / rx_frame_err, for one
  clean and one bad-stop frame, against REQ-006's own predicted total of
  4104 cycles plus the spec-explicit 2-cycle input synchroniser and a small
  margin for registered output latency) -- a bound tight enough to catch a
  grossly wrong sample grid while not asserting a single-cycle claim this
  bench could not independently verify. REQ-007/REQ-011's exhaustive sweeps
  additionally corroborate that sampling happens at the right point within
  each of the 10 cells, in the right order, for every value.
- **tb_uart_lite.sv -- REQ-014, REQ-016, REQ-017; REQ-013 explicitly
  skipped.** REQ-017 (loopback, 256 bytes) wires rx_line to tx_line inside
  the testbench and drives one byte at a time (offer, wait for arrival,
  pop, next) so FIFO depth is never a factor -- REQ-017 is a correctness
  claim, not a throughput one. REQ-014 (overrun) uses the same
  direct-injection bench-model transmitter as tb_uart_rx.sv (a
  loopback_en mux selects which drives rx_line) to fill the FIFO to exactly
  16 without going through tx timing at all, then a 17th byte, then a
  framing-error byte while still full, then drains and checks the original
  16 come back in order with neither the dropped 17th nor the framing-error
  byte appearing, then checks rx_ovr_clr. REQ-013 (input synchronisation)
  is inspection-only per requirements.md's Method column and is not
  attempted; the file prints an explicit [REQ-013] SKIP line saying so
  rather than silently omitting it.

### Actions
Wrote all five files under test/ plus test/run.sh. Iterated against two real
bugs found in MY OWN bench code before trusting any result from it:
1. tb_uart_tx.sv's first version captured `accept_cycle = cycle_counter`
   (a blocking read) in the same posedge as `cycle_counter <=
   cycle_counter + 1` (a nonblocking write) in a separate always block --
   the read got the pre-increment value, but every LATER comparison against
   the same free-running counter saw the post-increment value, so
   `wait(cycle_counter == accept_cycle)` for the very next boundary check
   deadlocked (the counter had already passed the target by the time it
   was next observed). Diagnosed by adding $display markers and watching
   the log grow (buffered stdio hid the hang for the first ~190s of
   real time). Fixed by removing the free-running counter entirely in
   favour of a locally-tracked relative `pos`, advanced only by
   `repeat(N) @(posedge clk)` -- race-free by construction, and roughly
   500x faster in wall-clock terms as a side effect (whole-file run time
   fell from a hang to 1.5s).
2. tb_uart_lite.sv's REQ-017/REQ-014 pop and rx_ovr_clr pulses were written
   as `signal = 1; @(negedge clk); signal = 0;` -- if `signal` is set at an
   arbitrary point in the cycle (not immediately after a negedge), that
   `@(negedge clk)` can land BEFORE the next posedge ever samples the
   signal, silently dropping the pop/clear request. Fixed to
   `@(negedge clk); signal = 1; @(negedge clk); signal = 0;`, which
   guarantees the signal spans exactly one posedge with a full half-period
   of setup on both sides. First version showed REQ-017 failing 255/256
   (only the very first byte, which happened to align favourably, got
   through) and three REQ-014 checks failing for the same underlying
   reason; both are the WO's own point #3 ("drive DUT inputs ... so you
   never race the clock edge") applied to a pulse I initially got wrong.

### Evidence
All commands run from the repository root (/workspace/agentic-uart-demo)
with Icarus Verilog 12.0 (`iverilog -V` confirms "Icarus Verilog version
12.0 (stable)"):

```
bash test/run.sh
```
Per-bench results (from the same run, build/*.log):
- tb_uart_lite: Total 12, Pass 12, Fail 0 -- ALL CHECKS PASSED
- tb_uart_tick_gen: Total 28, Pass 20, Fail 8 -- FATAL (see below)
- tb_uart_fifo: Total 13, Pass 13, Fail 0 -- ALL CHECKS PASSED
- tb_uart_tx: Total 265, Pass 265, Fail 0 -- ALL CHECKS PASSED
- tb_uart_rx: Total 291, Pass 291, Fail 0 -- ALL CHECKS PASSED (includes
  REQ-011's full 6656-check sweep, P=422..447 x 256 bytes, 0 mismatches)

Overall: 609 checks, 601 pass, 8 fail. `bash test/run.sh` exits 1 (its
per-bench grep/exit-code checks correctly propagate tb_uart_tick_gen's
$fatal into the overall script exit code).

The 8 tb_uart_tick_gen failures, verbatim (also reproducible by isolated
instances at N=2,3,27,434 confirming a first tick at cycle N-2, not N, in
every case):
```
[REQ-005] FAIL  N=2: first tick after reset lands at cycle N=2 (k=1 in "k-th tick at cycle N.k"); observed first tick at cycle 0
[REQ-005] FAIL  N=2: first tick after restart lands N=2 cycles after the restart pulse cycle (k=1 convention); observed at 0 cycles after
[REQ-005] FAIL  N=3: first tick after reset lands at cycle N=3 (k=1 in "k-th tick at cycle N.k"); observed first tick at cycle 1
[REQ-005] FAIL  N=3: first tick after restart lands N=3 cycles after the restart pulse cycle (k=1 convention); observed at 1 cycles after
[REQ-005] FAIL  N=27: first tick after reset lands at cycle N=27 (k=1 in "k-th tick at cycle N.k"); observed first tick at cycle 25
[REQ-005] FAIL  N=27: first tick after restart lands N=27 cycles after the restart pulse cycle (k=1 convention); observed at 25 cycles after
[REQ-005] FAIL  N=434: first tick after reset lands at cycle N=434 (k=1 in "k-th tick at cycle N.k"); observed first tick at cycle 432
[REQ-005] FAIL  N=434: first tick after restart lands N=434 cycles after the restart pulse cycle (k=1 convention); observed at 432 cycles after
```
All twelve "consecutive ticks exactly N apart" and "never two consecutive"
sub-checks pass in the same run -- the mismatch is isolated to phase/anchor,
not rate.

### Outcome
DoD vs WO-0001: every REQ-001..REQ-012 and REQ-014..REQ-017 maps to a named,
running check; REQ-013 is a named, explicit skip (inspection-only per
requirements.md). REQ-006 is a declared partial (see Reasoning/Evidence) --
not a silent gap. REQ-011 is driven entirely by this file's own bench-model
transmitter, independent of uart_tx, exactly as WO-0001 constraint #1
requires, and swept over its full stated window and byte range. REQ-005 is
checked in clock cycles throughout (never in ticks), per WO-0001 constraint
#2. WO-0001 constraint #3 (a failing check is a legitimate return, not
adjusted to pass) governs the tb_uart_tick_gen result above: left red,
reported with exact expected-vs-observed cycles, judged a suspected design
defect in this journal and the WO- Return log, not a test defect. Diff
touches only test/** (five files) plus this journal plus the WO- Return log,
per this seat's write scope. No RTL was read (see Inputs' independence
disclosure for the one directory-listing exposure, which contained no RTL
source content).

### Open-questions
1. **Suspected design defect (REQ-005, uart_tick_gen):** the first tick
   after both a reset release and a restart pulse lands at cycle N-2, not
   at cycle N as REQ-005's "the k-th tick is high during cycle N.k" (k=1,2,
   ...) states -- reproducible, exact, and uniform across N=2,3,27,434 and
   both trigger types. Left red per WO-0001's explicit instruction; this is
   for dv_lead to triage into a BUG- packet if confirmed.
2. **Spec-wording tension (REQ-005 vs SS5.1/SS5.3, restart-triggered
   cycle-0):** REQ-005 says "counting the cycle after reset release (or
   after a restart pulse) as cycle 0"; SS5.3 says of the same mechanism
   "that cycle is cycle 0 of the frame" (naming the pulse cycle itself, not
   the cycle after it). This bench tested REQ-005's own literal wording
   (cycle after the pulse); the alternate reading was not separately
   tested. Recommend architect_docs_lead reconcile the wording.
3. **REQ-006 coverage gap, declared:** the individual per-bit sample-cycle
   claims (216, 648, ..., 4104 individually) could not be reliably isolated
   via black-box bracketing within this bench's effort budget -- three
   different bracketing techniques gave three mutually inconsistent
   apparent boundaries, read as a methodological confound rather than three
   findings. Only an end-to-end (start-to-strobe / start-to-frame_err)
   timing bound is asserted. If cycle-exact per-instant coverage is
   required for module-ready sign-off, this needs either a differently-
   designed bench (possibly with a look at whether the false-start/confirm
   logic has intentional debounce/hysteresis behaviour that a lone-cycle or
   single-sided sustained transition doesn't model correctly) or an
   RTL-side clarification relayed through dv_lead -- not something this
   seat can resolve blind.
4. **REQ-007's "nominal sender bit period" is not itself defined in
   SPEC-uart_lite.md or requirements.md.** This bench used DIV_TX=434 (the
   transmit divider, SS2's own "ideal"-rounded value) as the nominal
   period. SS2 also computes a distinct 432-cycle receive bit period; the
   spec never states which of the two (or a third value) "nominal" refers
   to for REQ-007's purposes. Recommend architect_docs_lead clarify; this
   bench's choice is defensible (results are checked exhaustively across
   the whole 422-447 window in REQ-011 regardless) but is a genuine
   ambiguity, not a resolved one.
5. **Independence process note:** see Inputs' disclosure above (an `ls -la`
   during pre-charter orientation listed rtl/**'s filenames, sizes, and
   mtimes; no content was read or used). Flagging per charter SS7 for
   dv_lead/the auditor to disposition; this seat does not consider it
   grounds for self-invalidating the benches, given no content exposure,
   but that call belongs to dv_lead/the auditor, not to this seat.
6. **No explicit spawn short-id token was present in the spawning prompt**
   (protocol SS4.1 describes the orchestrator minting one into every worker
   spawn); this entry's Trigger substitutes the WO- id and this entry's own
   timestamp. Not treated as blocking.

### Files-in-this-commit
- test/tb_uart_lite.sv
- test/tb_uart_tick_gen.sv
- test/tb_uart_fifo.sv
- test/tb_uart_tx.sv
- test/tb_uart_rx.sv
- test/run.sh
- agents/handoffs/WO-0001-uart-lite-benches.md
