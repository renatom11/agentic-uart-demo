# Playbook — the freeze-first mutation campaign

The procedure that qualifies a verification instrument: seeded defects the
bench must catch, predicted before they exist, adjudicated verbatim. No
`SO-` PASS issues on an unqualified bench (PROTOCOL §10). This playbook is
the practiced model end-to-end; the packet forms are
[`CAMPAIGN-template.md`](../../agents/handoffs/templates/CAMPAIGN-template.md)
and
[`SEALED-predictions-template.md`](../../agents/handoffs/templates/SEALED-predictions-template.md).

**Cast**: dv_lead designs and adjudicates; the auditor seeds (no stake,
blinded); the orchestrator runs branches and relays; CI executes.

## The procedure

### 1. Freeze

dv_lead commits, **in one commit, before any defect exists** (R-SEAL-1):

- the campaign brief (from CAMPAIGN-template): base SHA, defect-class
  intents, the seeder's allowlist, mechanics, pass criteria;
- the sealed predictions companion: every cell of the scoring surface
  classified REQUIRED (must fail, in the named rows, with the named
  messages), MUST-STAY-GREEN, or PERMITTED.

The **denominator** — units, rows, benches — is fixed at freeze and never
moves mid-campaign. A coverage gap discovered mid-flight is recorded as an
obligation and acted on **after** adjudication: a freeze scored against a
moved denominator is not a freeze.

The base SHA's control is **verified, not assumed**: show that the compiled
surface at the base is byte-identical to a named green run's (e.g.
`git diff <base> <control-sha> -- test/ rtl/` is empty), so "the control is
green" is established before any mutant exists.

### 2. Seal

The seal is a **file, not a sentence** (R-SEAL-1): committed beside the
brief, named `*-SEALED-predictions.md`, opened by no one until every run has
executed. Predictions name rows **and messages** — row sets rarely
discriminate between defect classes; messages do. Predict from **what the
row asserts** (the observable), not from how you guess the mutation will be
implemented: the practiced record shows observable-grounded predictions
survive mechanism details that mechanism-grounded predictions do not.

### 3. Seed

The orchestrator spawns the auditor with the brief. The seeder:

- reads only the brief's §1 **allowlist** (an allowlist, not a bar list — it
  cannot be defeated by a document the author forgot to enumerate);
- authors **all diffs before any run executes**, each minimal and faithful
  to its intent, each hunk carrying the greppable marker
  `<id> MUTATION (WO-NNNN)`;
- stages diffs + report to `docs/reports/audit/WO-NNNN-mutations/` (shape:
  [`../reports/audit/README.md`](../reports/audit/README.md)), committed by
  the orchestrator's commit service under `Agent: auditor`;
- never runs the diffs, never sees the results.

**Compile-only repair exception**: a diff that fails to *build* may be
repaired to build — changing nothing else, disclosed in the report. Where
the build enforces formatting, the formatter's own output counts; hand
reformatting does not. Nothing else about a diff changes after any run
result exists.

### 4. Branch

The orchestrator creates one **throwaway branch per mutant**:
`mut/wo-NNNN-<id>` = frozen base SHA + exactly one diff, nothing else.
Never merged, never rebased onto, deleted only after the audit lane's
marker-check duty has recorded it. A mutant never touches the working tree
of any live branch.

### 5. Run

CI executes each branch — the same authoritative environment as everything
else (PROTOCOL §10); nobody scores a local run.

### 6. Harvest

The orchestrator harvests each run into a relay stating: parent SHA,
mutation id, CI run id, build state, and the test step's **verbatim** output
— complete failure messages and the name of every failing test, not a
summary. Harvest hygiene:

- **verbatim relay** — the adjudicator scores the text, so the text is the
  artifact; paraphrase destroys the by-message discrimination;
- **sanity-scan** the harvest before relaying: unit names present, messages
  complete, no log-window truncation (see
  [`ci-evidence.md`](ci-evidence.md) for why long evidence needs the
  promotion-block form);
- **never write harvested output into the tree** — results live in the
  relay and the adjudication record, not as files in the repository;
- **a green run on any mutant is a campaign failure, relayed prominently**
  — never buried in a batch summary;
- generated-artifact drift at CI's determinism step is expected under every
  design mutation, is never an unnamed-unit finding, and is never harvested.

### 7. Adjudicate

dv_lead opens the seal only when all runs are in, flips its State line to
UNSEALED (quoting the freeze SHA and the file's sha256 — integrity is
checkable), and scores the verbatim results against the frozen cells:

- a kill counts **only** in the named rows with the named messages;
- a red cell outside the prediction — unnamed unit red, or named unit red
  with the wrong message — is a **finding**, not a kill;
- any red in MUST-STAY-GREEN is a finding;
- **the frozen prediction is never edited**, before a result or after —
  corrections and pre-result rulings are issued *beside* it in the packet's
  Return log, where a wrong prediction dies on the record;
- an **equivalent-mutant claim is a proof obligation**: discharged only by
  an argument covering the whole legal stimulus space, never by the suite's
  failure to kill (PROTOCOL §10).

### 8. Scorecard

The verdict lands in the campaign packet's Return log
(`RV-NNNN-VERDICT`) and the mutation directory's README: per-mutant rows —
REQUIRED n/n, MUST-STAY-GREEN n/n, message class, verdict — plus the
campaign verdict, findings, and **what the campaign licenses with its bounds
attached** (which stimulus positions were driven, which rows fail fast,
which rows are NO-ASSERT). The bounds are not decoration; they are what the
next campaign is designed against.

## Campaign design checklist (dv_lead, at freeze)

- [ ] Base SHA pinned; control run named; surface-equality check shown.
- [ ] Every intent is a behavioural spec with explicit "unaffected" bounds.
- [ ] At least one **silently-always-pass** intent — a defect whose symptom
      is a green suite that checks nothing. Every qualification owes one
      (PROTOCOL §10). Expect it to look quiet; do not strengthen it.
- [ ] Intents public, mapping sealed: the brief publishes defect classes
      only; rows, MUST-STAY-GREEN columns, and messages are sealed.
- [ ] Denominator counted in the seal; no row additions mid-campaign.
- [ ] Allowlist complete — including root-level build-configuration files
      (an item omitted by oversight is a defect in the list).
- [ ] Process bars in the brief: all diffs before any run; no post-result
      revision except disclosed build repairs; private scratch; tree copies
      exclude out-of-bounds paths; allowlist binds every git subcommand.
- [ ] Where a spec rule could collide with an intent, the standing clause is
      in the brief: preserve the spec rule, disclose the collision.

## Seeder conduct checklist (auditor)

- [ ] Read nothing outside the allowlist; asked through the orchestrator
      when in doubt rather than reading.
- [ ] All diffs authored before any run; minimality and fidelity argued per
      diff; substitutions declined and said plainly.
- [ ] Marker comment in every hunk; diffs apply cleanly to the base pin.
- [ ] Scope statement + ambient-exposure disclosure in the report; journal
      `Inputs` lists every read.

## Information hygiene (everyone)

Campaign-adjacent commit subjects are deliberately thin. A review verdict
that describes bench internals is part of the next campaign's sealed
surface. Rulings made mid-campaign ("for the next template…") propagate by
editing the template the next campaign starts from
([`packet-splitting.md`](packet-splitting.md), rule propagation).
