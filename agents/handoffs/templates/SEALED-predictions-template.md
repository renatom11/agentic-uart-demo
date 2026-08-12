# WO-NNNN sealed predictions — <bench family / module>

<!-- The sealed companion of a mutation-campaign brief. MECHANICS ONLY live
     in this template: the predictions themselves are authored fresh by
     dv_lead for each campaign and committed IN THE SAME COMMIT as the brief,
     before any defect exists (R-SEAL-1, PROTOCOL §10). Save as
     agents/handoffs/WO-NNNN_<slug>-SEALED-predictions.md.
     Delete these comments when instantiating. -->

> **SEALED. Do not open this file until every campaign diff is committed and
> every run has executed.** The seeder never reads it, in any state. The
> orchestrator relays nothing from it before adjudication. Opening it early
> voids the campaign's blinding and is a finding against whoever opened it.

- **State**: SEALED
  <!-- Flip convention: dv_lead flips this single line to
       `UNSEALED at adjudication — J-dv_lead-NNNN, <UTC date>` in the
       adjudication commit. Nothing below the header is ever edited, before
       a result or after: a frozen prediction is not amended, it is
       adjudicated — corrections and rulings are issued beside it in the
       campaign packet's Return log, where a wrong prediction dies on the
       record. -->
- **Campaign**: `WO-NNNN_<slug>.md` · **Base SHA**: `<sha>`
- **Frozen at**: <commit SHA of the freeze commit — same commit as the
  brief>
- **Integrity**: at unsealing, quote this file's sha256 as committed at the
  freeze SHA (`git show <freeze-sha>:<path> | sha256sum`) beside the same
  command's output at the adjudication SHA — byte equality is the seal's
  integrity argument, and it is checkable by anyone.

## Scoring surface — the three-way classification

<!-- Every cell of the campaign's scoring surface — every (mutant × unit)
     pair over the frozen denominator — is classified into exactly one of
     the three classes. The denominator (units, rows, benches) is fixed
     here and never moves mid-campaign; a coverage gap discovered mid-flight
     is recorded as an obligation and acted on after adjudication. -->

### Denominator

<The complete unit/row list this campaign is scored against, counted.>

### <X>-c1

- **REQUIRED**: <named row(s)> — failing with: `<the expected failure
  message, verbatim — the message, not just the row, is the prediction>`
  <!-- Where two messages are admissible (e.g. an assertion-order fork),
       name both, mark the primary, and say why both are admissible. -->
- **MUST-STAY-GREEN**: <named rows, counted — "the remaining n units">
- **PERMITTED**: <cells that may go either way, or "none">

<!-- Repeat per mutant. -->

## What the seeder must not be told

<!-- Enumerate the sealed surface explicitly, so the public brief can be
     checked against this list before issue — the brief author sweeps the
     brief, the commit subjects, and any relayed text against every item
     here. Typical entries: -->

- The mutation-id → row mapping (which units each mutant reddens).
- The MUST-STAY-GREEN columns.
- The expected failure messages.
- <Anything else this campaign's blinding depends on.>
