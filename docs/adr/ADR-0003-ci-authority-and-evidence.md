# ADR-0003: CI is the authoritative build environment, and what counts as evidence from it

- **Status**: **ACCEPTED (pre-adopted at seeding)** — adopted as part of the
  shell's constitution; provenance below; amendable only via PROTOCOL §11.
- **Deciders**: pre-adopted from the source program's build-environment
  ruling, its CI-lane ADR, and the first run of its differential lane.
- **Scope**: which environment's results are citable, how machine-produced
  expectations enter the tree, how a lane that cannot reach a verdict
  reports itself, and the standing requirements on any new CI lane.

## Context

The source program's development container could not install its own
toolchain (network policy), so correctness was established by CI or not at
all — and the org discovered that this constraint, honestly stated, is a
*better* evidence regime than local builds even where local builds are
possible: a CI run has an ID, a conclusion, and a log that anyone can cite
and no one can quietly re-run until it passes. The rules below were then
stress-tested by a promotion pipeline whose evidence could be suppressed by
its own checkers, and by a differential lane whose first run reported a
comparison failure when in fact no comparison had occurred.

## Decision

1. **CI is the authoritative build environment.** No gate signature, sign-off
   packet, or work-order Evidence rests on a local build result; evidence
   cites a CI run ID and its conclusion (PROTOCOL §10). A local run is a
   convenience for iteration, not evidence — nobody else can reproduce the
   environment it ran in.
2. **Machine-produced expectations are promoted from CI's own diff output,
   never authored by hand.** Writing a plausible-looking expected value into
   a snapshot block is fabricated evidence — the one thing the journal
   protocol exists to prevent. A promotion that fills an existing
   expectation block by hand is routing around this rule.
3. **The promotion-block pattern.** When a run's diff is the promotion
   source, CI must emit that source in a form the org can actually retrieve:
   printed **after** the diff so it sits at the log tail inside any bounded
   fetch window, as a checksum plus a compact re-creatable encoding of every
   staged path. And evidence-producing steps run **before**
   evidence-consuming gates: a checker failure must never suppress the diff
   that is the promotion source.
4. **The NO-VERDICT class.** A skipped, absent, or failed-to-install
   verification lane is never a PASS; a broken harness is never reportable
   as an anchor finding. Every lane's exit classes partition along *did the
   lane reach a verdict?* — no-verdict is a distinct class from a negative
   verdict, run summaries distinguish *ran and agreed* from *did not run*,
   and no sign-off may cite a run in which the lane did not execute. Exit
   codes are chosen not to collide with the runtime's own failure codes, so
   an infrastructure crash cannot masquerade as a verdict.
5. **Fail-closed grammars.** Where two producers meet at a comparison, the
   comparator's reader is fail-closed and stays that way: **producers
   conform to the grammar; the grammar does not accommodate producers.** A
   reader relaxed to accept a malformed input would let the lane issue its
   first agreement on machinery that was not working.
6. **Standing requirements on any new CI lane — R-CI-1 … R-CI-6**
   (review-enforced; the enforcement class is this sentence):
   - **R-CI-1 — separate job per lane.** A red lane must not redden the main
     suite, and a lane's artifacts must not trip the main job's
     cleanliness/determinism checks.
   - **R-CI-2 — distro-provenance installs.** Lane tooling installs from the
     distribution archive, not from ad-hoc source builds or third-party
     repositories: the tool version becomes a fact about the runner image,
     with the distribution's provenance behind it.
   - **R-CI-3 — version sidecars.** The lane records its tool versions into
     the run's **artifact**, not only into the log; a reproducibility
     guarantee whose condition is not in the record is not checkable.
   - **R-CI-4 — written de-gating conditions.** A lane may land
     non-blocking, but the condition under which it becomes blocking is
     written down at landing, in the ADR or packet that lands it — a
     permanently non-blocking lane is decoration.
   - **R-CI-5 — artifacts outside the checkout** (or on paths ignored in the
     same change), so a lane cannot fail its own or another job's
     working-tree checks.
   - **R-CI-6 — failure evidence in the log and uploaded artifacts:** the
     stimulus, both compared outputs, and the diff. A finding that cannot be
     adjudicated from the artifact is not a finding; such artifacts are
     ephemeral and are cited as such (PROTOCOL §4.1).
7. **Lanes trigger on push, never on a schedule.** A lane that runs on a
   schedule produces failures attributable to no commit.

## Alternatives considered

- **Local builds as evidence where available.** Rejected: irreproducible by
  anyone else, and it splits the evidence regime in two. The source recorded
  the asymmetry honestly when one lane *was* locally runnable — usable for
  iteration, still not evidence.
- **Vendoring the toolchain / loosening network policy** to make local
  authoritative: rejected in the source on measured grounds (the blockers
  were transitive and environmental); the decision above remains correct
  regardless, since CI stays the environment gate signatures cite.
- **One big CI job.** Rejected: the main job's working-tree determinism check
  is deliberately a tripwire for anything that writes into the tree; a lane
  inside it either breaks the tripwire or is broken by it (R-CI-1/R-CI-5).
- **Relaxing the comparator's reader to accept a producer's near-miss
  format.** Rejected explicitly in the source's first differential run —
  the honest repairs are a producer fix and an exit-class fix, and the
  lane's first agreement must mean agreement.
- **Post-processing generated output to satisfy a checker.** Rejected as
  fabricated conformance; the honest repairs are a checker fix and a
  workflow fix.

## Consequences

- Iteration is slower (a CI round-trip per verification cycle); correctness
  is unaffected and citability is absolute. Agents batch work accordingly.
- CI configuration is load-bearing and is therefore itself an audited,
  versioned artifact.
- Every future lane inherits R-CI-1..6 as its starting checklist; deviations
  need their own ADR sentence, not silence.
- NO-VERDICT discipline costs an exit-class design conversation per lane and
  buys the org immunity from its most seductive failure: a green light that
  means "nothing ran".

## Provenance

Source program, pinned at commit `1799e10a37f19059ac3337982af4b6d035e14d0c`:

- CI authority, hand-authored-snapshot ban:
  [docs/adr/ADR-0005-build-environment.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0005-build-environment.md)
  (Decision, rules 1–2).
- Lane requirements (source R-CI-1…R-CI-8, including "a lane that runs on a
  schedule produces failures attributable to no commit"), the no-verdict
  rule ("a skipped, absent or failed-to-install simulator is never a
  PASS"), vendored-reference and pin-bump rules:
  [docs/adr/ADR-0015-the-cosim-lane-dependency-reference-and-determinism.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0015-the-cosim-lane-dependency-reference-and-determinism.md)
  (D1 requirements table, D2, D3).
- The promotion-block arc (log-tail evidence after an ~11k-line diff
  overran a 5,000-line fetch window; step reorder so the checker cannot
  suppress its own evidence): `J-orchestrator-0067`, `-0068`, `-0079`,
  `-0080` in
  [agents/journals/claude_orchestrator_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_orchestrator_agent.md)
- The differential lane's run 1 (exit "DIFFERENTIAL" on a format rejection
  when no comparison had occurred; exit-code collision with the runtime's
  uncaught-exception code; NO-VERDICT exit class 8; "producers conform to
  the grammar"): `J-dv_lead-0059` in
  [agents/journals/claude_dv_lead_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_dv_lead_agent.md),
  `J-data_wrangler-0003` in
  [agents/journals/workers/claude_data_wrangler_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/workers/claude_data_wrangler_agent.md),
  [agents/handoffs/WO-0049_cosim-canon-format-fix.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0049_cosim-canon-format-fix.md)
  (§8), implemented in
  [tools/cosim/run_cosim.sh](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/tools/cosim/run_cosim.sh)
- Fabricated-conformance refusal: `J-rtl_lead-0004` in
  [agents/journals/claude_rtl_lead_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_rtl_lead_agent.md),
  accepted at `J-orchestrator-0067`.
