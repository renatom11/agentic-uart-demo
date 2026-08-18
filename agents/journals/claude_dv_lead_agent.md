# Journal: claude_dv_lead_agent

- **Agent**: dv_lead (Opus-class lead)
- **Charter**: agents/charters/dv_lead.md
- **Format**: v2 — entry grammar in agents/PROTOCOL.md §4

This file is APPEND-ONLY. Content may only ever be added after the last line;
nothing above it is ever edited. Enforced by scripts/agent_commit.sh and CI.

---

---
## [J-dv_lead-0001] 2026-08-13T01:55:00Z | task:none | Adjudicating WO-0001's eight red checks: one design defect, two bench defects, all three the same anchor ambiguity

### Trigger
tb_writer returned WO-0001 with 609 checks, 601 passing and 8 failing, and did
not adjust any expected value to make them pass. Adjudication is this seat's.

### Verdict on each failure
All eight failures were REQ-005 in `uart_tick_gen`, and they were **correct**:
BUG-0001 is real, and the fix landed at 27104a8. The bench was right and the
design was wrong.

Investigating it surfaced two further defects **in the benches**, both the same
mistake as the one in the specification: an event-relative anchor stated or
assumed one cycle off.

1. **`tb_uart_tick_gen`, both anchors.** `observe_tick_pattern()` labels its
   first observed posedge as cycle 0, and that posedge is the one *after* the
   reset/restart anchor. The checks compared that observation directly against
   N. Corrected by converting observation cycles into spec cycles explicitly
   (`first_tick + 1`) rather than by moving the expected value, so the anchor
   stays visible to a reader instead of being folded into a constant.
2. **`tb_uart_tx`, REQ-002 and REQ-004.** The boundary grid was anchored at
   `i * DIV_TX` from the acceptance cycle, which requires the start bit to be
   low *during* acceptance. `tx_line` is a registered output and cannot change
   in the same cycle as the input that causes it, so that anchor is
   unsatisfiable by any conforming design. Corrected to `1 + i * DIV_TX`, and
   the REQ-004 ready-rise check moved by the same one cycle.

### The finding worth keeping
One ambiguity — where cycle 0 sits relative to an event — produced three
defects, in three different artifacts, written by three different seats: the
specification's §5.1 anchor, the RTL's reload value, and the bench's boundary
grid. Each was individually plausible. None was catchable by an interval-based
check, because every one of them preserves the spacing and moves only the phase.

The rule this earns: **a timing requirement anchored to an event must state
which cycle is cycle 0 in the requirement itself, and at least one check must
measure from the anchor to the first event rather than between events.**

### A coverage gap in the suite as returned, now closed
As returned, REQ-002 measured only the interval between successive bit
boundaries. That check passes a transmitter whose first interval is wrong and
whose spacing is right — which is exactly BUG-0001. The bench passed REQ-002
265/265 against the defective design. The requirement has been amended to
require the first interval measured from acceptance, and the bench's boundary
grid now starts at the acceptance anchor, so the row is discharged by a check
that can actually fail it.

### Evidence
Full suite after all three corrections: **609 checks, 609 pass, 0 fail**,
`bash test/run.sh` exit 0, Icarus 12.0.

| bench | checks | result |
|---|---|---|
| tb_uart_tick_gen | 28 | pass (was 20/28) |
| tb_uart_fifo | 13 | pass |
| tb_uart_tx | 265 | pass |
| tb_uart_rx | 291 | pass, incl. REQ-011 sweep P=422..447 x 256 bytes = 6656 checks |
| tb_uart_lite | 12 | pass |

### Note on who wrote what
The corrections in this commit are mine, not tb_writer's. They were made by a
seat that has read the RTL, so they are not blind work and are not committed
under the blind seat's name. tb_writer's return is committed unmodified at
6c8d65c; this commit is the adjudication on top of it. An earlier attempt staged
both together under tb_writer, which would have misrepresented what the blind
session produced; it was reset before it was pushed.

### Files-in-this-commit
- test/tb_uart_tick_gen.sv
- test/tb_uart_tx.sv

---
## [J-dv_lead-0002] 2026-08-18T19:07:11Z | task:none | Five waveform vignettes, and the first mutation campaign sealed before a single defect exists

### Trigger
Orchestrator dispatch, this round: build a curated waveform vignette per module
so the sponsor can *see* each one working, and — the load-bearing half — freeze
the predictions for the first mutation campaign. `tasks/BOARD.md` states the
program's honest position in terms: **"No mutation campaign has been run.
Nothing establishes in general that these benches would catch a defect."** This
entry is the first half of the answer, and it is only worth anything because it
was written before the question could be looked up.

### Inputs
Read, in this order, and the order matters:

- `agents/charters/dv_lead.md`, `agents/PROTOCOL.md` (§3, §4, §5, §6, §10),
  `tasks/BOARD.md`.
- `docs/specs/SPEC-uart_lite.md` (§2, §3, §4, §5.1–§5.5, §6) and
  `docs/specs/requirements.md` (REQ-001…REQ-017) — **the sole basis for the
  defect-class taxonomy.**
- All five benches: `test/tb_uart_tick_gen.sv`, `test/tb_uart_fifo.sv`,
  `test/tb_uart_tx.sv`, `test/tb_uart_rx.sv`, `test/tb_uart_lite.sv`, and
  `test/run.sh` — read for **assertion text and iteration order only**, which
  is what L-C09 requires before sealing an expected failure message.
- `agents/handoffs/templates/CAMPAIGN-template.md`,
  `agents/handoffs/templates/SEALED-predictions-template.md`,
  `docs/playbooks/mutation-campaign.md`.
- Journal entry `J-dv_lead-0001` (the BUG-0001 adjudication and the REQ-002
  amendment whose effectiveness this campaign puts to the test).

**Independence declaration.** No file under `rtl/` was read at any point this
round — not for the taxonomy, not for the vignettes. The vignettes instantiate
each module using only the port and parameter names the specification's §5
interface tables declare. Two incidental exposures, disclosed because
undisclosed exposure is the thing that rots a blinding claim: the VCDs the
vignettes produce name some of the DUTs' internal signals in their `$var`
headers (`uart_tick_gen.cnt`, `uart_rx.fall`, `uart_rx.t_next`), and I read
those headers while measuring file sizes. That is output, not source, it
happened after the seal was written, and it tells me nothing the spec did not.

### Reasoning

**Why the seal was written first, before a single line of the vignettes.**
A seal's whole value is its position in time. Anything I read or built before
writing it is inside its provenance; anything after is not. The vignettes touch
the same five modules, so I authored and froze the predictions first and only
then wrote a bench — which is why the independence declaration above can be
unconditional instead of hedged.

**Taxonomy: 17 classes, not the 8 asked for, and why the extra nine earn their
place.** Eight classes can be chosen so that every one is loud. The interesting
question is not "does the suite go red" but "does it go red *in the right row,
for the right reason, and stay green where it should*". That needs pairs whose
outcomes differ by a single row. So the taxonomy is built out of deliberate
pairs:

- **TG-1 / TG-2** — the same off-by-one in opposite directions. Both redden the
  same eight `tb_uart_tick_gen` rows. They differ in exactly one row of
  `tb_uart_tx`: `tx_ready rises again once the stop bit has completed`. If the
  campaign returns identical row sets for the two, the suite noticed trouble
  and did not measure direction.
- **RX-1 / RX-2** — two ways for the receiver's sample grid to be wrong. Both
  redden REQ-006. They separate on the far-end sweep: RX-1's green/red boundary
  falls at P=432/433, RX-2's at P=439/440, and RX-2 leaves all 256 REQ-007 rows
  green while RX-1 reddens 255 of them.
- **FF-1 / FF-2** — two defects in the same `full` path, one moving `level` and
  one moving the data. If they redden the same rows, the FIFO bench is
  detecting "something near the full flag" and nothing finer.
- **RX-1 / RX-3** — both redden the two REQ-008 rows. RX-1 reddens 274 more;
  RX-3 reddens none.

**Three classes are predicted to SURVIVE, deliberately, and naming them in
advance is the point.** A campaign in which everything dies measures nothing:
it cannot distinguish a suite with teeth from an apparatus that reddens at
anything. So three classes make the RTL genuinely wrong against a numbered spec
clause and are predicted to leave all 609 checks green:

- **TX-4** (`tx_busy` never asserts) — PROTOCOL §10's owed
  silently-always-pass class. `tx_busy` is read by exactly one row in the whole
  suite, at reset, in the one state where the correct and defective designs
  agree, and it is not a port of `uart_lite` so no other bench can reach it.
- **RX-4** (one synchroniser flop instead of two) — REQ-013's Method column is
  *inspection*, and `tb_uart_lite` prints `[REQ-013] SKIP` in its own output.
  The requirement has no executable owner. The one row whose timing could have
  noticed was deliberately given a twelve-cycle tolerance to absorb exactly
  this latency.
- **LT-2** (a framing error writes the FIFO) — the strongest of the three. The
  suite's only top-level framing error arrives when the FIFO already holds 16
  entries, so the illegal write is swallowed by the FIFO's own
  write-while-full rule. The row that would catch it asserts, in its own
  parenthetical, that "the framing-error byte" is absent — and it *is* absent,
  for a reason unrelated to the clause the row quotes.

**Three rows are vacuous at the base SHA, and I sealed that before any defect
existed rather than discovering it afterwards.** Finding these was the most
valuable part of the round:

1. `tb_uart_fifo.sv:138` asserts `full === 1'b1` under the message
   `full asserted exactly when level=DEPTH=16 after 16 writes`. It tests one
   direction. A FIFO that fills at 15 passes it.
2. `tb_uart_lite.sv:246` asserts `rx_overrun === 1'b0` after `rx_ovr_clr` under
   the message `rx_ovr_clr clears rx_overrun`. It cannot tell "cleared" from
   "was never set".
3. `tb_uart_tx.sv:126,140` — the **only** row in the suite whose text claims to
   check bit order uses `8'hA5`, which is a bit-reversal palindrome
   (`1010_0101` reversed is itself). It compares an MSB-first wire against an
   LSB-first expectation and finds them equal. I nearly sealed this row as a
   TX-1 kill; catching it is why REQ-003's 240-of-256 arithmetic is in the seal
   and the REQ-001 row is not.

**The harness can hang instead of failing, at three named sites.** No bench
arms a watchdog and `test/run.sh` arms no timeout, so a defect that starves
`tx_ready` or `rx_strobe` produces no FAIL line and no `ALL CHECKS PASSED`
line: `vvp` runs forever and `run.sh`'s guards, which only fire after `vvp`
exits, never fire. The sites are `tb_uart_tx.sv:90-93`, `tb_uart_lite.sv:121-124`
and the `fork…join` counting branches at `tb_uart_rx.sv:182-191,202-211`. The
campaign packet therefore requires an external wall-clock timeout on every
mutant, and the scoring rule dispositions a timeout as `NO-VERDICT — HANG`,
never as a kill: a suite that wedges has not detected anything, it has stopped.

**I declined to verify any prediction by hand-mutating the RTL.** My charter
§3 tells me to spot-check a bench by mutating the module in a scratch tree.
PROTOCOL §10 tells me a campaign's seal is committed before any defect exists.
Here the second rule governs: a defect authored by me, now, to check my own
prediction is a defect that exists before the seal is scored, and adjusting the
seal after seeing it would turn a prediction into a description. The campaign
*is* the spot-check, at seventeen times the scale. If a prediction is wrong it
dies on the record, which is the arrangement I want.

**Freeze discipline, stronger than the template's.** The template flips a State
line to UNSEALED at adjudication. The seal I wrote never changes state and is
never edited: unsealing, scores and findings are recorded beside it in the
campaign packet's Return log. A prediction that can be edited after its result
is not a prediction, and removing the only permitted edit removes the only way
to launder one. The class → message mapping is restated in Evidence below so
two append-only copies exist; if either is altered to fit a result, the other
exposes it.

**Vignettes: what I did not do.** The dispatch asked for a small divisor on the
tx, rx and lite vignettes. I used the real ones (434, 27) and state the reason
in each file's header: SPEC §5.2, §5.3 and §5.5 declare **no** divisor
parameter on `uart_tx`, `uart_rx` or `uart_lite` — the constants live in
`uart_pkg` per §4 — so a bench derived from the specification has no legal way
to shrink them, and inventing one would have meant reading the design in the
same round I was sealing predictions about it. `uart_tick_gen`'s `N` *is* a
spec-declared parameter, so `wv_tick_gen` uses N=8 exactly as asked. The
constraint the dispatch actually cared about — VCD size — is met by measurement
instead: all five are under the 200 KiB ceiling, achieved by cutting per-cycle
marker buses out of the dumps rather than by cutting scenarios.

Three rejected vignette ideas, recorded because the rejected list is what an
auditor mines: (a) a REQ-011 tolerance vignette — the sweep is 6 656
comparisons over 26 sender periods and has no readable waveform at any zoom,
which is precisely why `wv_lite`'s header states that a green loopback is not
evidence about REQ-011; (b) an overrun vignette at the top level — it needs 17
frames, ~74 000 cycles, and a VCD an order of magnitude over the ceiling, so
the FIFO's full/ignore boundary is shown at module level in `wv_fifo` instead,
where it costs 3 KB; (c) a back-to-back (REQ-012) vignette — 64 frames, same
problem, and it shows nothing a single frame does not.

### Actions
- Authored `agents/handoffs/WO-0002-SEALED-predictions.md` — 17 classes, the
  denominator, the three harness facts, the scoring rule, and the
  seeder-blinding list. Frozen; never to be edited.
- Authored `agents/handoffs/WO-0002-mutation-campaign.md` (state `ISSUED`) —
  the cast, the read allowlist, the process bars, the 17 published intents
  (classes only, no rows and no messages), the orchestrator's mechanics
  including the mandatory external timeout, and an empty Return log.
- Wrote five vignettes under `test/wave/` plus `test/wave/run_wave.sh`, and ran
  every one.
- Ran the full suite twice: once at `509173a` to fix the denominator, once at
  the freeze tree to prove the vignettes changed nothing the suite compiles.
- Verified `.gitignore` covers every generated artifact by command, not by
  reading the file.

### Evidence

**§4.1 precheck**, at the start of the round, in `/workspace/agentic-uart-demo`:

```
$ git status --short
                      (no output — clean tree)
$ git log --oneline -1
509173a The benches get a page of their own: 1372 lines of testbench readable
        with line numbers, check counts and requirement mappings, generated
        from the tree rather than typed
```

**Denominator, measured at `509173a`** — `bash test/run.sh`, Icarus Verilog
12.0, exit 0, 1m08.5s:

| bench | checks | pass | fail |
|---|---|---|---|
| tb_uart_tick_gen | 28 | 28 | 0 |
| tb_uart_fifo | 13 | 13 | 0 |
| tb_uart_tx | 265 | 265 | 0 |
| tb_uart_rx | 291 | 291 | 0 |
| tb_uart_lite | 12 | 12 | 0 |
| **total** | **609** | **609** | **0** |

**Control unchanged at the freeze tree** — `bash test/run.sh` re-run with
`test/wave/**` present: exit 0, same 609/609. `test/run.sh:72-76` names its
five benches literally, so nothing under `test/wave/` is compiled by the suite.

**Vignettes** — `bash test/wave/run_wave.sh`, exit 0, all five under the
204 800-byte ceiling the script enforces:

| vignette | VCD bytes | observed, not asserted |
|---|---|---|
| `wv_tick_gen` | 2 792 | first tick at `cyc_since_anchor` = 8 after reset **and** after restart (N=8) |
| `wv_tx` | 181 073 | wire order `start=0  d0..d7=11000101  stop=1` for 0xA3 — LSB-first confirmed against the header's prediction |
| `wv_rx` | 185 558 | `rx_byte`=0x3a, strobe seen, no frame error; `spec_sample` pulses exactly **10** times at 432-cycle spacing |
| `wv_fifo` | 3 058 | level 4 → push+pop leaves level 4 and advances head 0x11→0x22 → full at level 16 → 17th write changes nothing → drain to empty → pop-while-empty changes nothing |
| `wv_lite` | 108 462 | 0xA3 round trip in 4 108 cycles, `rx_frame_err`=0, `rx_overrun`=0, FIFO empty after the pop |

`wv_rx`'s marker grid was checked against the VCD rather than trusted:
extracting the `spec_sample` identifier and its rising edges gives pulse deltas
`[0, 432, 864, 1296, 1728, 2160, 2592, 3024, 3456, 3888]` — SPEC §5.3's
216 + 432·n grid, ten samples, no more and no fewer.

**gitignore, verified by command:**

```
$ git check-ignore -v build/wave/wv_tx.vcd
.gitignore:11:build/	build/wave/wv_tx.vcd
```

`.out`, `.log`, `.compile.log` and `.vcd` under `build/` all resolve to the
same rule; `*.vcd` at `.gitignore:12` is a second, independent net. No
waveform, log or simulation binary is committed by this round.

**The sealed mapping — independent append-only copy** (PROTOCOL §10 R-SEAL-1;
the other copy is `agents/handoffs/WO-0002-SEALED-predictions.md`, and this one
exists so neither can be quietly rewritten to fit a result):

| id | module | class | verdict | REQUIRED | the discriminating expectation |
|---|---|---|---|---|---|
| TG-1 | tick_gen | anchor one cycle early (BUG-0001) | KILL | 9 | 8 × `…observed first tick at cycle N-1` + tx REQ-002 boundary row; **both REQ-004 rows stay green** |
| TG-2 | tick_gen | anchor one cycle late | KILL | 10 | as TG-1 with `N+1`, **plus** `tx_ready rises again once the stop bit has completed` |
| TG-3 | tick_gen | tick not suppressed during restart | KILL | 4 | `N=%0d: tick suppressed during the restart pulse cycle itself`, all four N |
| TX-1 | tx | data bits MSB-first | KILL | 242 | 240 of 256 REQ-003 rows (16 palindromes green, first red `byte 0x01`); `loopback: … (240 mismatches)`; **the REQ-001 bit-order row stays green — 8'hA5 is a palindrome** |
| TX-2 | tx | frame one bit period short | KILL | **1** | `tx_ready falls the cycle after acceptance and stays low until the stop bit completes` — and nothing else in 609 |
| TX-3 | tx | bit period 433 | KILL | 2 | REQ-002 boundary row + the same REQ-004 glitch row; loopback stays green |
| TX-4 | tx | `tx_busy` never asserts | **SURVIVE** | 0 | 609 green; `post-reset: tx_busy is low (idle)` passes |
| RX-1 | rx | samples at boundary, not mid-bit | KILL | 276 | REQ-006 ×2, REQ-008 ×2, 255 of 256 REQ-007 (**only `byte 0xff` survives**), REQ-012, REQ-011 red for **P=433…447** and green for **P=422…432** |
| RX-2 | rx | `DIV_OS` = 26 | KILL | 11 | REQ-006 ×2 (~3955 vs window [4105,4116]), REQ-011 red for **P=440…447** only; **all 256 REQ-007 rows and the loopback stay green** |
| RX-3 | rx | false start not rejected | KILL | 2 | the two REQ-008 rows and no other REQUIRED cell |
| RX-4 | rx | one synchroniser flop | **SURVIVE** | 0 | 609 green; REQ-013 is inspection-only and prints `SKIP` |
| FF-1 | fifo | `full` off by one entry | KILL | 10 | `level==DEPTH=16 after 16 writes` + 6 more fifo rows + 3 lite rows; **`full asserted exactly when level=DEPTH=16 after 16 writes` stays green (vacuous)** |
| FF-2 | fifo | write while full overwrites | KILL | 4 | `a write while full is silently ignored: level, full, and head unchanged` + order + fall-through + the lite order row; level/full/empty sweep rows stay green |
| LT-1 | lite | `rx_overrun` not sticky | KILL | 3 | the three sticky rows; **`rx_ovr_clr clears rx_overrun` stays green (vacuous)** |
| LT-2 | lite | framing error writes the FIFO | **SURVIVE** | 0 | 609 green; the only top-level framing error arrives at a full FIFO |
| LT-3 | lite | `rx_valid` inverted | KILL | 3 | `one cycle after rst deasserts: rx_valid = 0 (FIFO empty)` + loopback + drain row |
| LT-4 | lite | `tx_line` idles low out of reset | KILL | 2 | `one cycle after rst deasserts: tx_line = 1` and `post-reset: tx_line idles high` |

14 KILL, 3 SURVIVE, across all five modules. **If all 17 kill, this seal was
wrong three times, and the record will say so.**

### Outcome
DoD met. Both halves delivered: five vignettes with a runner, all run and all
inside the size ceiling; and the campaign frozen — brief plus seal in one
commit, before any defect exists, satisfying R-SEAL-1 in the form it requires
(the seal is a file in this commit's own file list, not a sentence).

Handoff: `agents/handoffs/WO-0002-mutation-campaign.md`, state `ISSUED`, to the
auditor as blinded seeder via the orchestrator. The orchestrator records the
freeze SHA in that packet's Return log at issue. Nothing from the sealed
companion is relayed to anyone before adjudication, and campaign-adjacent
commit subjects stay thin — a subject line naming a predicted row or message
is a leak into the seeder's ambient exposure.

No `SO-uart_lite` issues this round and none can: PROTOCOL §10 forbids a PASS
on unqualified benches, and the qualification has not run yet.

### Open-questions

1. **A file appeared in the working tree that is not mine and not from my
   round: `site/wave.py`, untracked, 216 lines, a VCD parser and SVG renderer
   for the site.** The tree was clean at my precheck (output quoted above) and
   `site/` is outside dv_lead's write scope (PROTOCOL §6), so I neither touched
   nor staged it, and it is absent from my file list below. **The orchestrator
   must stage this round's files by explicit path — a `git add -A` would sweep
   `site/wave.py` into my commit and break R4 files-list equality and R7 path
   isolation in one move.** If a concurrent seat is writing this workspace, the
   spawn discipline in PROTOCOL §3 wants it declared.
2. **`SPEC-uart_lite.md` §2 forward-references a "§8" that does not exist** —
   "§8 states the tolerance requirement". The spec ends at §6. The tolerance
   requirement is real and lives in `requirements.md` REQ-011, so nothing is
   missing in substance, but the pointer is dangling and the spec is still
   marked DRAFT. For architect_docs_lead.
3. **REQ-013 has no executable owner.** Its Method is *inspection*, and the
   only artifact that mentions it in simulation prints `SKIP`. RX-4 is the
   class that measures this; whatever the campaign returns, no `SO-` may record
   REQ-013 as a discharged row, and it should be carried as a declared gap.
4. **The suite has no watchdog.** Three unbounded wait loops (named in
   Reasoning) turn a whole class of defect into a hang rather than a failure.
   The campaign works around it with an external timeout; the durable fix is a
   simulation timeout in each bench, which is a `test/**` change I did not make
   this round because it would have moved the denominator after the freeze.
   Recorded as an obligation to act on after adjudication.

### Files-in-this-commit
- agents/handoffs/WO-0002-SEALED-predictions.md
- agents/handoffs/WO-0002-mutation-campaign.md
- test/wave/run_wave.sh
- test/wave/wv_fifo.sv
- test/wave/wv_lite.sv
- test/wave/wv_rx.sv
- test/wave/wv_tick_gen.sv
- test/wave/wv_tx.sv

## [J-dv_lead-0003] 2026-08-18T20:15:00Z | task:none | Unsealing WO-0002 and scoring it: nine clean kills, one class the suite never saw, and a ruling that the blind broke on two classes

### Trigger
Orchestrator dispatch, act 4 of WO-0002 — the scoring round, dispatch-only, no
siblings. I froze the seal in round 1 (`J-dv_lead-0002`) before any defect
existed; the auditor seeded 19 diffs blind (`4fe6014`, `J-auditor-0001`) and the
orchestrator ran them (`1c06a20`, `J-orchestrator-0011`). This round opens the
seal, scores it, dispositions every survivor, and rules on two audit findings the
party they name cannot rule on.

### Inputs
- `agents/charters/dv_lead.md`, `agents/PROTOCOL.md`
- `agents/handoffs/WO-0002-SEALED-predictions.md` — **my own seal, opened here for
  the first time and for this purpose**; and `agents/handoffs/WO-0002-mutation-campaign.md`
- `docs/reports/audit/audit-0001_wo-0002-seeding-integrity.md` (six findings, in
  full) and `docs/reports/audit/WO-0002-manifest.md` (all 19 diffs, in full)
- `docs/reports/audit/WO-0002-mutations/*.patch` — all 19 patches read against
  their published intents (needed for the F-01 ruling)
- `test/tb_uart_rx.sv`, `test/tb_uart_fifo.sv`, `test/tb_uart_lite.sv`,
  `test/tb_uart_tick_gen.sv`, `test/run.sh`, `tools/campaign_run.sh` — bench sites
  cited as grounds for the misses
- `build/campaign/*.log` (the operator's raw run) and my own independent re-run
- Commit `c7762b0`'s subject line, for the F-01 ruling
- **RTL read this round, and I say so explicitly** (charter §8): the manifest
  quotes all 19 diffs with their surrounding `rtl/**` context, and I read them to
  rule on whether the leak could have steered any diff. This is post-freeze,
  post-seal adjudication forensics, not test derivation — every prediction being
  scored was authored at `J-dv_lead-0002` from specs and benches only, and nothing
  read this round could have changed it, because the seal is byte-frozen and
  verified so.

### Reasoning
**Why I re-ran the campaign before scoring it.** The operator's verdicts arrived as
a table of bench-level reddening. My scoring rule is by *message*, not by bench,
so a bench-level table cannot be scored against it at all — and a relayed table is
a relay, not a measurement (L-B01). I re-executed all 19 mutants myself and
compared the `[REQ-nnn] FAIL` line sets: byte-identical for 19 of 19. Only then
did I score. The campaign is deterministic (fixed seeds, no wall-clock
dependence), so this is a genuine reproduction rather than a coincidence.

**Why four classes are partials rather than kills.** My own rule 1 says KILL
requires *every* REQUIRED row of a class to go red with the named message. TG-3
(1 of 4), RX-1 (274 of 276), FF-1 (9 of 10) and LT-3 (2 of 3) each left REQUIRED
rows green. The operator's table called all four KILLED because the suite went
red somewhere. Scoring them as kills would have been the easy read and would have
made the campaign look much better; the rule I wrote before results existed
forbids it, and the whole point of writing it then was to bind me now.

**Why I ran experiments instead of asserting grounds.** Rule 2 requires each miss
be named with *the reason the row could not see the defect*. For two of them I had
a hypothesis and no evidence, and a hypothesis stated as a ground is exactly the
unfalsifiable move I would refuse from anyone else. So: (a) for TG-3 I swept the
bench's arbitrary pre-restart delay across five values and watched the red set
move — `N=3` at +0, `N=2` at +1, none at +2, both at +3, none at +4 — which proves
the row tests one counter phase rather than the suppression property, with
detection probability ~1/N; (b) for the REQ-008 rows I ran a three-arm experiment
(mutant+shipped bench, mutant+repaired stimulus, **unmutated**+repaired stimulus)
so that the third arm isolates the cause. Arm C being green is what makes arm B's
failure attributable to the mutation. Both experiments ran in scratch trees
outside the repository; I changed no bench in the tree, because the denominator
may not move under a running campaign (L-C08).

**The REQ-008 discovery is the campaign's real yield.** RX-3 was the one class the
suite did not detect at all, and the reason is structural rather than marginal:
the case is preceded by a bad-stop frame, whose final driven bit leaves `rx_line`
low, so the "glitch" that follows contains no falling edge and the receiver never
starts a frame. Both rows therefore pass for *any* idle receiver, including one
with false-start rejection deleted. Two checks name REQ-008, describe it in their
message text, and cannot fail. This is the same pathology as the TX-4 mutation
class — a green that checks nothing — except that here it was the bench doing it,
and only mutation exposed it.

**Where the seal was wrong, recorded and not smoothed.** Five out-of-prediction
reds and nine misses, all against me. The three FF-2 flag rows are the ones worth
naming: I predicted the flags would follow the control's trajectory, and so did
the seeder's independent fidelity argument — both of us missed the coincident
read-and-write-while-full case, where the DUT holds `level` at DEPTH while a
spec-conformant FIFO decrements. `tb_uart_fifo`'s 10 000-operation random sweep
caught what two readers of the design did not. That is the bench being better than
its adjudicator's model of it, and it is worth more to me than a clean prediction
would have been. Likewise the named `0xff` survivor died, and LT-3's drain-loop
reasoning was wrong because the gating I looked for in the bench lives in the
design's port wiring. I did not retro-fit any of these into kills; rule 5 exists
precisely to stop me.

**The F-01 ruling — the test I applied, and why it is not a wave-through.** The
freeze commit's subject named the count of rows I judged unable to fail and the
discriminating property of the suite's only bit-order check, and the §4.1 precheck
delivered it straight into the blind. F-02 compounds it: the dispatch opened
`tasks/BOARD.md`, which carries TG-1's staked claim. The question that decides
validity is not "was there a leak" (there was) but "could the leak reach a
decision the seeder actually had". The seeder had no discretion over *which*
defects to seed — I published all 17 intents — so the only reachable decisions are
placement and strength. I therefore read all 19 diffs against their published
intents. TX-1 is a pure bit reversal of the shift-register load and TG-1 is a
single reload constant; "MSB-first" and "one cycle early" each denote exactly one
behaviour, so there was nothing for the leak to steer. Hence: scores stand,
because a score measures the suite's response to a determined diff. But the
*blindness claim* does not stand, and I will not let the two be conflated — TX-1
is this campaign's most impressive-looking result and the subtlety a reader would
credit to my seal was also sitting in the commit subject. Void the blindness claim
for TX-1 and TG-1, permanently, travelling with every citation.

I also had to decide whether F-01 becomes CRITICAL. The auditor set the trigger
precisely: it does, if the adjudication relies on the leaked property without
recording the exposure. My adjudication *does* rely on it. So I discharge the
trigger by recording the exposure at the point of reliance rather than by avoiding
reliance, and F-01 stays MAJOR.

On responsibility, the auditor declined to adjudicate between me and the
orchestrator and was right to. It lands on both and I take my share first: the
hygiene rule that subject line defeats is a rule I wrote, in a packet I authored,
protecting a seal I froze — and I did not read the subject line that carried my
own freeze. Authoring a rule is not complying with it.

**F-06 — why the controls are admitted but unscored.** They have no cells in the
seal, so scoring them would manufacture the very "red outside the prediction" case
the playbook calls a finding, for a mutant the seal never had a chance to classify.
But declining them outright would throw away their real function: they are the
instrument check, and their green is the precondition that makes every other red
in the campaign meaningful. So: admitted, zero to numerator and denominator,
recorded as instrument-validity PASSED. I re-derived NM-2's equivalence myself
rather than accept it on the seeder's word.

**What I refused to do.** I did not sign anything. Five classes carry surviving
REQUIRED cells, and charter §6.3 makes a surviving REQUIRED mutation a gate block,
so this campaign's own result blocks the gate I might otherwise have wanted to
sign. I also did not repair any bench: the eight coverage obligations are real and
urgent, but a repaired bench is not a qualified bench until re-measured, and doing
the repairs inside the adjudication commit would blur the two.

### Actions
- Opened `agents/handoffs/WO-0002-SEALED-predictions.md` for the first time; **did
  not edit it**, and verified its sha256 at HEAD equals its sha256 at `c7762b0`.
- Re-executed all 19 mutants independently via `tools/campaign_run.sh` into a
  private outdir; compared FAIL-line sets against the operator's run.
- Scored all 17 sealed classes row-by-row and message-by-message against the seal.
- Ran two falsification experiments in scratch trees (TG-3 phase sweep; REQ-008
  three-arm isolation).
- Wrote `docs/reports/dv/WO-0002-adjudication.md` — the scorecard, the nine misses,
  the five findings, six vacuities, six survivor dispositions, and the F-06 and
  F-01/F-02 rulings.
- Appended round 3 to the campaign packet's Return log and set its State to
  `ACCEPTED`, with the explicit note that acceptance closes the campaign and does
  not qualify the benches.
- Ran **no git write command**.

### Evidence
All commands runnable from a checkout at this SHA. The per-mutant logs under
`build/campaign/` and the scratch experiment trees are **ephemeral artifacts**,
stated as such; each regenerates from the commands below.

- Precheck: `git log --oneline -1` → `1c06a20 operator: run the WO-0002 mutants and
  record the raw verdicts`; `git status --porcelain` → empty.
- Denominator unmoved (both empty):
  `git diff 509173a c7762b0 -- rtl/ test/run.sh test/tb_uart_lite.sv test/tb_uart_tick_gen.sv test/tb_uart_fifo.sv test/tb_uart_tx.sv test/tb_uart_rx.sv`
  and `git diff c7762b0 HEAD --stat -- rtl/ test/`.
- Seal integrity:
  `git show c7762b0:agents/handoffs/WO-0002-SEALED-predictions.md | sha256sum` and
  the same at `HEAD` → both
  `ead9e4f73421dbb0924612b66279c46697ccd8be319a15ca24cdec88cb117f9c`.
- Campaign re-run: `bash tools/campaign_run.sh <outdir>` (Icarus Verilog 12.0,
  240 s/mutant). FAIL-line sets byte-identical to the operator's run for 19/19
  mutants (sha256 per mutant).
- Per-bench failing-unit counts, measured (lite/tick_gen/fifo/tx/rx): TG-1
  0/8/0/1/0; TG-2 0/8/0/2/0; TG-3 0/1/0/0/0; TX-1 1/0/0/241/0; TX-2 0/0/0/1/0;
  TX-3 0/0/0/2/0; TX-4 all zero; RX-1 1/0/0/0/275; RX-2 0/0/0/0/11; RX-3 all zero;
  RX-4 all zero; FF-1 2/0/7/0/0; FF-2 1/0/6/0/0; LT-1 3/0/0/0/0; LT-2 all zero;
  LT-3 3/0/0/0/0; LT-4 1/0/0/1/0; NM-1 all zero; NM-2 all zero.
- Sealed boundaries confirmed exactly: RX-1 REQ-011 green `P=422..432`, red
  `P=433..447`; RX-2 green `P=422..439`, red `P=440..447`.
- TX-1: exactly 240 REQ-003 rows red; the 16 green rows are exactly the sealed
  list `0x00 0x18 0x24 0x3c 0x42 0x5a 0x66 0x7e 0x81 0x99 0xa5 0xbd 0xc3 0xdb 0xe7
  0xff`; loopback printed `(240 mismatches)`.
- TX-2: exactly one failing unit in 609, the sealed row.
- REQ-006 latency: control 4110; RX-1 3894 (−216); RX-2 3958 (−152).
- TG-3 phase sweep (scratch): extra pre-restart delay +0 → `N=3` red; +1 → `N=2`;
  +2 → none; +3 → `N=2,N=3`; +4 → none. `N=27` and `N=434` never red.
- REQ-008 three-arm experiment (scratch): A = RX-3 mutant + shipped bench →
  291/291 green; B = RX-3 mutant + `bench_drive_bit(1'b1, 100)` inserted before the
  glitch → `receiver has returned to idle (rx_busy low) after an abandoned false
  start` **FAIL**, 287/291; C = unmutated RTL + the same bench edit → 291/291
  green.
- Scorecard: `docs/reports/dv/WO-0002-adjudication.md`.

### Outcome
Act 4 met. Delivered: the unsealing recorded beside the seal (never inside it);
the scored tally — 9 clean kills, 4 partials, 1 undetected class, 3 SURVIVE
predictions held, 570/579 REQUIRED cells red, 9 misses, 5 out-of-prediction reds,
6 vacuous rows (3 sealed, 3 newly found); an individual disposition for each of the
six survivors; and rulings on F-06 and F-01/F-02. Handoff: the committed scorecard
plus the campaign packet's round-3 Return log.

**Nothing was signed.** `P1-module-ready` stays UNSIGNED and is now blocked by this
campaign's own result rather than by the absence of one: five classes carry
surviving REQUIRED cells (charter §6.3). No `SO-` issues from this round.

### Open-questions
1. **Eight coverage obligations are open** (scorecard §11), headed by REQ-008,
   which has two checks that name it and no stimulus that exercises it. They need
   a work order; each repair re-opens the campaign question for the class it
   touches.
2. **The board sentence must change.** "No mutation campaign has been run" is now
   false. Proposed replacement text is in scorecard §10.1; `tasks/BOARD.md` is
   orchestrator scope, so this is a proposal and not an edit.
3. **F-03 needs an ADR, and it is not mine to write.** The §4.1 precheck as worded
   is the delivery mechanism for F-01; the fix (`git log -1 --format=%H` for
   campaign-adjacent rounds) touches `agents/PROTOCOL.md`, outside my write scope.
   Escalated to the orchestrator under PROTOCOL §11.
4. **REQ-013 still has no executable owner**, and REQ-008 now joins it as a
   requirement no row discharges. Both must be carried as declared gaps in any
   future `SO-`.
5. The blind rests on the seeder's self-report that `test/**` was never opened,
   which is not mechanically enforceable here. Unchanged by this round; stated so
   no reader mistakes disclosure discipline for a mechanism.

### Files-in-this-commit
- agents/handoffs/WO-0002-mutation-campaign.md
- docs/reports/dv/WO-0002-adjudication.md
