# Journal: claude_auditor_agent

- **Agent**: auditor (Opus-class, independent)
- **Charter**: agents/charters/auditor.md
- **Format**: v2 — entry grammar in agents/PROTOCOL.md §4

This file is APPEND-ONLY. Content may only ever be added after the last line;
nothing above it is ever edited. Enforced by scripts/agent_commit.sh and CI.

---

## [J-auditor-0001] 2026-08-18T19:38:16Z | task:WO-0002 | Seeded 17 defects and two equivalence controls under the campaign blind; the mandated precheck itself delivered sealed material, disclosed as F-01

### Trigger
Orchestrator dispatch, my first spawn on this program. I am the WO-0002 mutation
campaign's no-stake seeder, blinded (PROTOCOL §10; charter §3). The board records
the auditor's absence as a stated limitation; this round begins closing it.
Dispatch-only round, declared as such. Base pin `c7762b0`.

### Inputs
Read, inside the brief's §1 allowlist:

- `agents/handoffs/WO-0002-mutation-campaign.md` (row 1) — the campaign brief.
- `docs/specs/SPEC-uart_lite.md`, `docs/specs/requirements.md` (row 2).
- `rtl/uart_pkg.sv`, `rtl/uart_tick_gen.sv`, `rtl/uart_tx.sv`, `rtl/uart_rx.sv`,
  `rtl/uart_fifo.sv`, `rtl/uart_lite.sv`, `rtl/uart_lite.f` (row 3).
- `agents/charters/auditor.md`, `agents/PROTOCOL.md`,
  `docs/playbooks/mutation-campaign.md` (row 5).
- `.gitignore` (row 6).

Also read: the spawn dispatch itself (my work order), and this journal's own
seeded header — the latter is not enumerated in §1, and I record it because
PROTOCOL §4 obliges me to append to it and I cannot append correctly without
seeing where its frozen header ends. I did **not** read any other agent's journal
even for house format; the entry grammar came from PROTOCOL §4.1, which is
row 5 and states it in full.

Read, and OUTSIDE the allowlist — disclosed:

- `tasks/BOARD.md`. §1 places it out of bounds ("the board narrates which checks
  caught what"). The spawn dispatch listed it as a mandatory first action and I
  read it before reaching the brief that forbids it. It carries the per-bench
  check counts, the bench-to-REQ mapping, and a paragraph about a requirement a
  defective transmitter formerly satisfied. No finding and no detectability
  judgement in this round's output rests on any of it. Written up as F-02.

Ambient exposure — the important one, quoted here because this journal is out of
bounds to seeders under §1 while `docs/reports/audit/**` is row 4 and readable by
them. The §4.1 precheck the dispatch mandated (`git log --oneline -1`) returned:

  > The seal is frozen before any defect exists: seventeen classes with their
  > expected message text - and writing the predictions found three rows that
  > cannot fail, including the only bit-order check, which uses a palindrome

That subject names sealed material: the class count, the count of rows judged
unable to fail, and a discriminating property of one specific predicted check.
It breaches the brief's own §0 commit-subject hygiene rule, PROTOCOL §10, and the
playbook. Written up as F-01, cited there by SHA and shape and deliberately not
reproduced in the audit tree.

Deliberately NOT read, though the dispatch listed it in bounds: `docs/adr/**`.
The brief places `docs/` outside `docs/specs/**`, the campaign playbook and
`docs/reports/audit/**` out of bounds. The allowlist is dv_lead's to set in the
brief, not the orchestrator's to widen at spawn, so I took the narrower set.
A voluntary refusal, recorded because the charter says conduct may exceed
instructions (L-F06).

Never opened, in any state: `agents/handoffs/WO-0002-SEALED-predictions.md`;
`agents/journals/claude_dv_lead_agent.md`; **all of `test/**`** — every bench,
`test/run.sh`, and `test/wave/**`; every other packet, verdict and journal under
`agents/**`.

### Reasoning
**The blind runs seeder-away-from-suite, and that decided almost everything.** A
seeder who knows which checks exist can pick sites those checks miss or hit, and
the campaign then measures the seeder's aim. So the working rule all round was:
every decision must be justifiable from `docs/specs/**` and `rtl/**` alone, and
must stay justifiable if the benches turn out to contain anything at all.

**Class selection was not mine, and that is a feature.** The dispatch asked for
"at least 10" classes with fresh ids `M-01…M-nn`; the brief's §2 already fixes
exactly 17 intents, and the seal is keyed to *those* ids and predicts messages
per class. Renumbering would make the seal unmatchable, and adding scored classes
would move a denominator the playbook says is fixed at freeze. I resolved it by
authoring exactly the brief's 17, keyed to the brief's ids, with `M-nn` carried
as a parallel index so the dispatch's numbering request is satisfied without the
campaign id ever being displaced. This also means the F-01 exposure could not
steer *which* defects exist — I had no discretion there. Where discretion did
exist, within a class, I bound myself to one checkable rule: **the smallest edit
at the site the cited spec text points to.**

**Fidelity beat minimality wherever the two pulled apart**, since §2 says
"behaves as described, not merely broken nearby". Three places:

- **TX-3 / RX-2** could be one-token edits to `uart_pkg.sv` (`DIV_TX = 433`,
  `DIV_OS = 26`). I rejected both. The intents are behavioural — "each of the ten
  intervals is 433 cycles", "the oversample rate is 26" — and a mutant whose
  defect can be cancelled by the same published constant it moves is not a
  faithful realisation of a behavioural claim. Editing the instantiation
  (`DIV_TX - 1`, `DIV_OS - 1`) is equally minimal and cannot self-cancel. I
  reached this without knowing whether anything imports the package; it is a
  fidelity argument, not an aim. Both alternatives are recorded in the manifest
  so dv_lead can substitute.
- **RX-4** could be `s2 <= rx_line`, a one-token edit. Rejected: it gives
  `rx_line` two readers and so breaks REQ-013's "exactly one reader" property,
  which the intent explicitly says is preserved. An intent is never a licence to
  break a second rule (L-C12). I used a wire alias so one flop remains and
  `rx_line` keeps exactly one reader.
- **LT-4** is filed under `uart_lite` but no edit can change the top level's
  reset value without changing `uart_tx`'s — they are the same wire
  (`rtl/uart_lite.sv:27`). Edited the transmitter's reset branch, disclosed.

**The one collision I could not avoid, and did not paper over.** RX-1's intent
lists sample points 0, 16 … 144. Tick 0 is the falling-edge cycle; no tick event
occurs there, so implementing the list faithfully also removes start-bit
abandonment, overlapping RX-3. Both alternatives were worse: keeping the
confirmation at tick 8 would contradict the intent's own list, and a preload
trick (`tcnt <= 8'd8`) reaches the same shift but by silently never reaching the
compare, which reads as an accident rather than as the intent. I implemented the
list as written, three constants moving together, and disclosed the overlap.
Preserve the spec rule, disclose the collision.

**Rejected as low value or unsafe, with the ground:**

- A streaming reverse `{<<{tx_data}}` for TX-1 — rejected on toolchain risk;
  Icarus 12 support is not something I wanted a campaign round to discover. The
  explicit bit list is certain and reads as deliberate. (Vindicated indirectly:
  Icarus rejected `break` in my own probe, so the caution was not theoretical.)
- `if (s2 && 1'b0)` as RX-3's realisation — rejected in favour of a guarded empty
  block; dead-code-by-constant reads as a formal-tool artifact rather than as
  "the sample is taken and not acted on".
- A one-shot stall flop, or a widened terminal compare, for TG-2 — rejected:
  each adds state or changes the spacing, and the intent says spacing is
  unaffected. This is also why TG-1 and TG-2 land on the same line despite §2's
  nudge: they are not symmetric in form (one consumes the anchor cycle, one
  spends a cycle in wrap), and every non-symmetric alternative was less faithful.
- Reordering the conjuncts of RX-1's sample window as the near-miss control —
  rejected as too trivial to be a control; a reader would not accept it as an
  edit at all. `t_next inside {…}` — rejected on the same toolchain-risk ground
  as the streaming operator.
- Adding *scored* classes beyond the brief's 17 to reach the dispatch's "at
  least 10" more decoratively — rejected: the denominator is frozen. Only the two
  unscored controls were added, and they are flagged as unscoreable rather than
  smuggled into the surface.

**The near-miss controls, and why two.** The dispatch requires at least one; I
authored two so the control is not a single point of evidence, and put one in the
FIFO's flag logic and one in `uart_tick_gen` — the timing core, where an edit is
most likely to look alarming and where a control therefore proves the most.
PROTOCOL §10 says an equivalence claim is a proof obligation discharged by
argument over the whole legal stimulus space and never by a suite's failure to
kill, so each carries such an argument, including the 4-state cases for
`level == '0` versus `~(|level)` and the carry-out case for the width cast.
They are outside the sealed surface, which is a real problem for scoring and is
raised as F-06 — a request, explicitly not a block (L-E07).

**Why I built a probe as well as a compile check.** The dispatch requires apply
and compile. Neither establishes that a diff behaves *as described*, which is
what §2 actually asks for, and an unfaithful mutant is worth less than no mutant
because it consumes a scored cell. So I wrote a probe of my own that asserts
nothing and prints port-level observables, ran it on the base and all 19 mutants,
and compared. This is me checking my own work against my own intents on an
instrument I wrote; it is not a suite result, it tells me nothing about `test/**`,
and no prediction anywhere in my output rests on it.

### Actions
- Ran the §4.1 precheck: `git status --short`, `git log --oneline -1`. Exactly
  two git commands this round; no git write command; no subcommand pointed at any
  path outside the allowlist (§1 bar 11).
- Authored 19 diffs — the brief's 17 intents plus two near-miss controls —
  entirely before any run executed (§1 bar 7). Each generated by exact,
  anchor-unique string substitution; the generator refuses an anchor matching
  other than once, and all 19 anchors matched exactly once.
- Worked in a private scratch directory (§1 bar 9). Every tree copy contained
  `rtl/` only — `test/` was excluded at copy time, never after (§1 bar 10), so no
  build could reach a bench even by accident.
- Wrote two throwaway files of my own under scratch: an elaboration stub that
  instantiates all five modules standalone (including `uart_tx.tx_busy`, which
  `uart_lite` leaves unconnected and which would otherwise not elaborate with its
  port), and the fidelity probe. Neither is under `test/`; neither is staged.
- Staged nothing outside `docs/reports/audit/**`: the manifest, the 19 patches,
  the mutation-directory README, and audit-0001.

### Evidence
All commands below were run at the base pin's `rtl/` content. Paths under
`/tmp/…/scratchpad/seed/` are **ephemeral** — the scratch directory, the
elaboration stub and the probe do not survive this session and are not committed.
The patch files themselves are committed, so the apply check is reproducible from
a checkout at `c7762b0` as `git apply --check docs/reports/audit/WO-0002-mutations/<id>.patch`.

Apply + compile, per mutant (`patch -p1` into a fresh `rtl/`-only copy, then
`iverilog -g2012 -o elab.out -f rtl/uart_lite.f <ephemeral stub>`):

    FF-1 … TX-4, NM-1, NM-2:  apply=OK compile=OK warnlines=0 elaborated=1
    === applied+compiled: 19   failed: 0 ===

Round-tripped from the committed copies under
`docs/reports/audit/WO-0002-mutations/`: `ok=19 bad=0`. **No build-only repair
was needed by any diff**, so there is nothing to disclose under §1 bar 8.

Marker check, every hunk of every patch (`<id> MUTATION (WO-0002)`):
19/19 patches, `unmarked=none` for all, including the two-hunk `FF-2`.

Unmutated control under the ephemeral probe, matching the spec where the spec
states a number:

    A_TG_FIRST_TICK_CYCLE=27        (SPEC §5.1: k-th tick at cycle N·k, N=27)
    A_TG_SPACING=27,27
    A_TG_PHASES_WITH_TICK_IN_RESTART_CYCLE=0/27
    B_TX_READY_RISE_CYCLE=4341      (SPEC §5.2: 1 + 10·DIV_TX = 1 + 10·434)
    B_TX_EDGES=5                    (0xB2 emitted LSB-first, edges at 1+i·434)
    D_FF_WR n=16 level=16 full=1    (SPEC §5.4: full exactly at level = DEPTH)
    E_LT_TXLINE_AFTER_RESET=1       (SPEC §6)
    E_LT_OVERRUN_3000_LATER=1       (SPEC §5.5: sticky)

Per-mutant deltas against that control, all matching their intents — a sample:
TG-1 first tick 26 with spacing unchanged and the transmitter showing a 433-cycle
first interval and nine at 434 (BUG-0001's recorded signature); TG-2 first tick
28; TG-3 exactly 1 of 27 restart phases producing a tick where the control
produces none; TX-1 seven edges instead of five with `tx_ready` still at 4341;
TX-2 `tx_ready` at 3907 = 1 + 9·434 with a **bit-identical** line trace; TX-3
`tx_ready` at 4331 = 1 + 10·433; TX-4 differing in one line only; RX-2 strobe 152
cycles early; RX-4 strobe one cycle early and nothing else; FF-2 twenty writes
into a sixteen-deep FIFO leaving entries 5..20 in order.

Both controls: `cmp` clean against the control output — byte-identical.

**One negative result about my own instrument, recorded because my claims must be
as falsifiable as those I audit.** My first probe reported the tick generator
never ticking. That was my bug, not the design's: I drove stimulus with blocking
assignments landing on the clock edge, racing the flops. A minimal isolation test
showed the unmutated generator ticking at cycles 30, 57, 84 — spacing 27, exactly
per spec. I rewrote the probe to drive and sample only on the negative edge, and
re-ran everything above. Icarus 12 also rejected `break`, which I replaced with
guarded `while` loops. No mutant diff was touched in either repair.

### Outcome
DoD met for the round as dispatched, with one deliberate departure and one
addition, both argued above and in the manifest:

- **Departure**: class ids are the brief's (`TG-1` … `LT-4`), not fresh `M-nn`,
  because the seal is keyed to them; `M-nn` is carried as a parallel index.
- **Addition**: `audit-0001_wo-0002-seeding-integrity.md`. The dispatch asked for
  the manifest and this entry; my charter requires findings to be published as
  numbered committed reports, and this round produced six. Keeping them out of
  the manifest also keeps the campaign artifact clean of audit content.

Deliverable: 19 diffs, all applying and compiling, authored before any run, all
markers present, silently-always-pass class present (TX-4) and left quiet, all
five modules spanned, near-miss control present (two). Handoff: the orchestrator
commits; dv_lead adjudicates. **I do not run these diffs and do not see the
results.**

Findings: F-01 MAJOR (freeze commit subject leaks sealed material — disposition
is dv_lead's), F-02 MAJOR (dispatch widened the allowlist; concerns the
orchestrator), F-03 MINOR (the precheck is F-01's delivery mechanism), F-04 MINOR
(playbook cites a non-existent shape reference), F-05 MINOR (unclean tree at the
pin; concerns the orchestrator), F-06 REQUEST (controls sit outside the sealed
surface). **No CRITICAL, so nothing here blocks a gate.**

### Open-questions
1. **F-01 disposition is dv_lead's**, not mine and not the orchestrator's: does
   the precheck exposure void any mutant? I have stated why it could not have
   steered class selection and flagged the one sentence in the manifest that sits
   adjacent to the leaked material.
2. **F-06**: rule on `NM-1`/`NM-2` before the runs — out-of-scoring controls, or
   declined. A ruling belongs beside the seal in the packet's Return log, issued
   before results exist; the seal is never edited.
3. **Commit-subject hygiene applies to this commit too.** Given F-01, the subject
   for this round must be thin. Something like "auditor: seed the WO-0002
   mutation diffs" carries everything a reader needs. Please do not name a class,
   a count, a row, a message or a module in it.
4. `docs/reports/audit/dv_escapes.md` does not exist yet. Nothing has escaped a
   sign-off because no `SO-` has issued; the ledger is owed at the first one.
5. The audit duties this round did **not** perform — commit-range R1–R10,
   Evidence re-execution, independence, relay fidelity — are listed as owed in
   audit-0001 §4. They need their own spawn, with a commit range and no blind.

### Files-in-this-commit
- docs/reports/audit/WO-0002-manifest.md
- docs/reports/audit/audit-0001_wo-0002-seeding-integrity.md
- docs/reports/audit/WO-0002-mutations/README.md
- docs/reports/audit/WO-0002-mutations/TG-1.patch
- docs/reports/audit/WO-0002-mutations/TG-2.patch
- docs/reports/audit/WO-0002-mutations/TG-3.patch
- docs/reports/audit/WO-0002-mutations/TX-1.patch
- docs/reports/audit/WO-0002-mutations/TX-2.patch
- docs/reports/audit/WO-0002-mutations/TX-3.patch
- docs/reports/audit/WO-0002-mutations/TX-4.patch
- docs/reports/audit/WO-0002-mutations/RX-1.patch
- docs/reports/audit/WO-0002-mutations/RX-2.patch
- docs/reports/audit/WO-0002-mutations/RX-3.patch
- docs/reports/audit/WO-0002-mutations/RX-4.patch
- docs/reports/audit/WO-0002-mutations/FF-1.patch
- docs/reports/audit/WO-0002-mutations/FF-2.patch
- docs/reports/audit/WO-0002-mutations/LT-1.patch
- docs/reports/audit/WO-0002-mutations/LT-2.patch
- docs/reports/audit/WO-0002-mutations/LT-3.patch
- docs/reports/audit/WO-0002-mutations/LT-4.patch
- docs/reports/audit/WO-0002-mutations/NM-1.patch
- docs/reports/audit/WO-0002-mutations/NM-2.patch
