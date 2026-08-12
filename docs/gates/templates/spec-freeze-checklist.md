# Gate: P<n>-spec-freeze

<!-- Copy to docs/gates/P<n>-spec-freeze-checklist.md when the phase's spec
     work begins. Only the orchestrator stages docs/gates/** (PROTOCOL §6);
     every signature below is transcribed from the signing agent's journal
     under PROTOCOL §7's transcription rule. Delete these comments when
     instantiating. -->

Closes when all Phase-<n> module specifications are FROZEN and the sponsor
signs. A spec is FROZEN only with (a) interface-check evidence per the
regime the M1 toolchain ADR recorded — a green interface-compile CI run
citing the freeze SHA where the toolchain supports compile-checked records,
a line-by-line reviewed port table where it does not (SPEC-TEMPLATE §4.1) —
and (b) a dv_lead testability countersignature for that spec (PROTOCOL §7).

## Prerequisites

| # | Item | Evidence |
|---|---|---|
| 1 | <toolchain/lane prerequisite — e.g. the interface-check lane wired into CI> | <run id + SHA> |
| 2 | <dv_lead testability review of the requirements corpus, before this checklist opened> | <WO id → findings → disposition> |

## Requirements testability countersignature

<!-- The countersignature device: the signer's authority is its own journal
     entry, which must itself state the act in the authority formula —
     "I sign gate <X> item <Y>" — at a named SHA. The orchestrator
     transcribes; the transcription is clerical. -->

> "I sign gate P<n>-spec-freeze, requirements testability precondition, at
> `<sha>`." — dv_lead, journal `J-dv_lead-NNNN` (WO-NNNN), transcribed by
> the orchestrator <UTC date>.

## Per-batch freeze record

<!-- Specs freeze in reviewable batches. Every cell is a SHA or a run id —
     a freeze row with no SHA froze nothing. A withheld countersignature is
     recorded here as WITHHELD with its contested items named; the batch
     re-enters at the next revision. -->

| Batch | Specs | Drafted at | Interface-check evidence | dv countersign | FROZEN at |
|---|---|---|---|---|---|
| A | SPEC-M<nn>, … | `<sha>` (WO-NNNN) | run `<id>` green / reviewed table `J-dv_lead-NNNN` | **SIGNED** (`J-dv_lead-NNNN`) / **WITHHELD** (items…) | **FROZEN at `<sha>`** |

### Batch countersignatures (transcribed)

> "I countersign batch <A> (<spec list>) for P<n>-spec-freeze at `<sha>`."
> — dv_lead, journal `J-dv_lead-NNNN` (WO-NNNN), transcribed by the
> orchestrator <UTC date>.

## Carry-forward ledger

<!-- Defects and obligations discovered during freeze review that do not
     block the batch but MUST land somewhere named. Ids C-nn are permanent:
     a closed row keeps its number and its row, closure recorded in place —
     countersignatures and work-order logs cite these numbers, and a
     renumbered table makes those citations lie. "Must land before" names a
     spec, gate, packet, or bench — never "later". -->

| id | Item | Must land before | Status |
|---|---|---|---|
| C-1 | <the defect/obligation, stated so its closure is checkable> | <SPEC-M<nn> / first SO- packet / gate row> | OPEN / CLOSED (WO-NNNN at `<sha>`) / SEALED (decision finalised, WO-NNNN) |

## Sponsor items

| # | Item | Status | Signature |
|---|---|---|---|
| S1 | Sponsor reviews the freeze summary (batches, carry-forwards, post-freeze change policy) and signs the gate (escalation class E1) | OPEN | <sponsor approval date, recorded in J-orchestrator-NNNN> |

## Exit

All batches FROZEN, all countersignatures transcribed, every carry-forward
row carrying a named landing site, sponsor signed → the orchestrator declares
the gate passed in its journal and updates `tasks/BOARD.md`. Post-freeze
changes to any frozen §4/§6/§7 are a spec diff plus an ADR, recorded in the
spec's §13 (SPEC-TEMPLATE).
