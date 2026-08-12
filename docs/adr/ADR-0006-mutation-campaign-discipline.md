# ADR-0006: Mutation-campaign discipline — freeze-first qualification of the verification instrument

- **Status**: **ACCEPTED (pre-adopted at seeding)** — adopted as part of the
  shell's constitution; provenance below; amendable only via PROTOCOL §11.
- **Deciders**: pre-adopted from the model as practiced and hardened across
  the source program's five campaigns (WO-0039, WO-0041, WO-0042, WO-0045,
  WO-0050), which superseded the source constitution's original written
  model. This shell's PROTOCOL §10 codifies the practiced model natively.
- **Scope**: how a verification suite earns the right to say PASS. A
  campaign qualifies the **instrument**, never the module: a campaign that
  goes 5/5 does not issue a sign-off, it makes the suite's future green
  runs mean something.

## Context

The founding observation, from the first campaign's brief: a suite whose
checks are all in-code assertions produces a green run that "is
indistinguishable from a suite that never executed a single check." Seeded
mutations are the only evidence that green means anything. The source ran
five campaigns under this discipline; every rule below was either designed
into the first or paid for during one of the five — including three rules
learned when the campaign's own referee got something wrong and the
discipline caught it.

## Decision

1. **Freeze first.** The campaign lead commits an auditor-facing brief plus
   a SEALED predictions companion **before any defect exists**; the seeder
   is spawned only afterwards. Predictions live in a separate sealed file,
   not a sealed section — "a bar you can trip over by opening a file is not
   a bar." The seal is a committed artifact in the same commit as the claim
   (R-SEAL-1, ADR-0004).
2. **Predictions are three-way: REQUIRED / MUST-STAY-GREEN / PERMITTED.**
   Every cell of the scoring surface is classified. A flat kill list scores
   every monitor surprise as a prediction failure and gets quietly widened
   after the fact; MUST-STAY-GREEN as a first-class committed prediction is
   what makes the test two-sided.
3. **The denominator never moves.** Units, rows, and benches are fixed at
   freeze; no row, unit, or bench edit lands between a freeze and its
   scoring. A late addition is scored in the next round, never folded into
   this one.
4. **Mutant hygiene.** Each mutant is known-green base SHA plus exactly one
   diff, authored before any run executes, on a throwaway never-merged
   branch carrying a greppable marker; the frozen base is re-confirmed
   green at the campaign's first and last runs (drift insurance). CI
   executes the campaign.
5. **Adjudication is verbatim and two-sided.** The lead adjudicates the
   verbatim test-runner output — including the name of every failing unit
   — against the sealed file; a paraphrase destroys it. Kills count only
   **in the named rows with the named messages**; a red cell outside the
   prediction, or a named row with the wrong message, is a finding, not a
   kill. A green run is relayed prominently, because a survived mutation is
   the single most important result a campaign can produce.
6. **Messages discriminate; row sets do not.** Distinct defects routinely
   share a row set and are separated only by which assertion speaks —
   sealing messages is what buys discrimination. Corollary obligations:
   read every unit's assertion order **and iteration order** before sealing
   a message (fail-fast loops mean only the first case speaks), and treat
   assertion order as part of a row's contract — ordered deliberately,
   reorders announced prominently.
7. **A freeze is never edited after its result.** A falsified sealed
   prediction stays as written and dies on the record. And **a seal
   reasoning from what a row asserts beats a correction reasoning from a
   second-hand mechanism**: verify the detail first or leave the prediction
   alone — the source's one falsified-by-itself round came from replacing a
   right sealed prediction with a wrong "corrected" one.
8. **Every qualification owes a silently-always-pass mutation**: a defect
   whose symptom is a green suite that checks nothing (the hardwired-verdict
   class). It is expected to look "too quiet", and the seeder is told not to
   improve it — a small observable footprint is the correct outcome.
9. **An equivalent-mutant claim is a proof obligation**, discharged only by
   an argument covering the **whole legal stimulus space** — down to the
   spec's floors, not the bench's habits — never by the suite's failure to
   kill.
10. **Snapshot/determinism drift is not a unit.** A mutant that survives the
    suite and fails only on its own snapshot drift is not killed and the
    drift is never scored as an unnamed-unit finding or harvested as an
    expectation.
11. **A packet specifies the observable and leaves the mechanism to the
    party that can see it.** Across any blinding or scope boundary, intents
    are behavioural specifications — minimal, faithful, stated in terms of
    observable output — and the concrete diff (or check) is authored by the
    agent with legitimate sight of the artifact. When an intent collides
    with a spec rule, the seeder preserves the spec rule and discloses the
    collision: an intent is never a licence to break a second rule on the
    way to the first.

## Alternatives considered

- **The source constitution's original written model** (transient
  uncommitted-tree mutations applied by the orchestrator, manifests under
  the audit tree, kills N/N with no sealed predictions): superseded in
  practice by campaign one and never updated in the source's protocol — a
  drift its harvest flags as a lesson. This shell adopts the practiced
  model as the written one; see LESSONS F8.
- **Unsealed predictions ("the lead will just say what it expects").**
  Rejected: an unsealed prediction can be authored after the outcome, and a
  seeder who knows the predicted rows can — with the best intentions —
  choose sites that redden exactly those rows, confirming the prediction
  instead of testing the bench.
- **Scoring red-anywhere as a kill.** Rejected: it means the bench caught
  the defect for a reason other than the one it was built to catch it for —
  worth knowing, not worth crediting.
- **Conceding equivalence when the suite fails to kill.** Rejected: that
  converts every bench blind spot into a proof of the mutant's innocence.
- **Merging mutants or batching diffs per branch.** Rejected: one diff per
  branch is what makes every result attributable to exactly one defect.

## Consequences

- Sign-off packets can state "this suite has been demonstrated to fail" —
  the only evidence a green run means anything — with kills adjudicated
  against predictions that provably predate the defects.
- The campaign referee is bound by its own freeze: the discipline catches
  the lead's errors (falsified predictions die on the record) as well as
  the bench's, which is what makes the verdicts trustworthy.
- Cost per qualification: a brief, a sealed companion, one CI run per
  mutant, and an adjudication round. The source paid it five times and
  every payment produced at least one bench or process finding.

## Provenance

Source program, pinned at commit `1799e10a37f19059ac3337982af4b6d035e14d0c`
— the five campaigns (briefs include their verdicts; sealed companions are
committed alongside but are not cited here):

- [agents/handoffs/WO-0039_m03-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0039_m03-mutation-campaign.md)
  — the founding brief: freeze-first, §5 verbatim relay ("a paraphrase
  destroys it"; green relayed prominently), §6 pass criteria, §7 "a green
  run here is indistinguishable from a suite that never executed a single
  check". Adjudicated `J-dv_lead-0036`/`-0037`; freeze adopted
  `J-dv_lead-0035`.
- [agents/handoffs/WO-0041_family-d-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0041_family-d-mutation-campaign.md)
  — the equivalent-mutant proof ("Proven, not conceded", `J-dv_lead-0044`
  §3), messages-discriminate (shared row sets separated only by message),
  the falsified prediction left standing, the silently-always-pass class
  seeded deliberately (D-M1).
- [agents/handoffs/WO-0042_family-d-m6-mini-round.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0042_family-d-m6-mini-round.md)
  — mini-round completing a family's qualification; snapshot-drift-is-not-
  a-unit ruled at `J-dv_lead-0046`.
- [agents/handoffs/WO-0045_family-e-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0045_family-e-mutation-campaign.md)
  — denominator honoured at scoring (`J-dv_lead-0054`: scored first, added
  second), seal-beats-second-hand-correction ("more analysis made the
  answer worse"), assertion-and-iteration-order rule (`J-dv_lead-0053`),
  the spec-collision standing clause.
- [agents/handoffs/WO-0050_family-f-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0050_family-f-mutation-campaign.md)
  — the regime consolidated: frozen at `J-dv_lead-0061` with a measured
  denominator, base SHA chosen as the green control run's own SHA.
- Silently-always-pass as a standing debt owed to every qualification:
  `J-dv_lead-0037`, relayed at `J-orchestrator-0113`; the worker-facing
  observable/mechanism contract: 
  [agents/handoffs/WO-0047_tb-m03-family-f-runts.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0047_tb-m03-family-f-runts.md)
  (§4.2, §6). Journals:
  [agents/journals/claude_dv_lead_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_dv_lead_agent.md),
  [agents/journals/claude_orchestrator_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_orchestrator_agent.md).
