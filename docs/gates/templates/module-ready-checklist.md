# Gate: P<n>-module-ready

<!-- Copy to docs/gates/P<n>-module-ready-checklist.md when the phase's
     first SO- packet is in sight. Only the orchestrator stages
     docs/gates/** (PROTOCOL §6); signatures are transcribed from the
     signing agent's journal per PROTOCOL §7. Delete these comments when
     instantiating. -->

Closes when every Phase-<n> module carries a PASS DV sign-off packet
(`SO-<module>.md`), and each PASS carries a completed freeze-first mutation
campaign adjudicated against its sealed predictions (PROTOCOL §7, §10).
No `SO-` PASS issues on an unqualified bench.

## Per-module readiness record

<!-- Every cell is a packet path, a SHA, a run id, or a journal ref.
     "Campaign" cites the campaign WO and its adjudicated score in the form
     kills/seeded (REQUIRED r/r, MUST-STAY-GREEN g/g, findings n) — the
     scorecard lives under docs/reports/audit/WO-NNNN-mutations/. -->

| Module | Spec (frozen at) | SO- packet | Verdict | Campaign (WO · kills · findings) | Signed |
|---|---|---|---|---|---|
| M<nn> `<name>` | SPEC-M<nn> (`<sha>`) | `agents/handoffs/SO-<module>.md` | PASS / FAIL | WO-NNNN · <k>/<k> · <n> | `J-dv_lead-NNNN` |

### Module countersignatures (transcribed)

> "I sign gate P<n>-module-ready, row M<nn>, at `<sha>`." — dv_lead,
> journal `J-dv_lead-NNNN` (SO-<module>), transcribed by the orchestrator
> <UTC date>.

## Campaign adjudication record

| Campaign | Base SHA | Sealed at (commit) | Unsealed at (commit) | Verdict | Scorecard |
|---|---|---|---|---|---|
| WO-NNNN | `<sha>` | `<sha>` | `<sha>` | PASS / FAIL | `docs/reports/audit/WO-NNNN-mutations/README.md` |

## Carry-forward ledger

<!-- Same device and same rules as the spec-freeze template: permanent C-nn
     ids, named landing sites, closure recorded in place. Rows inherited
     from P<n>-spec-freeze whose landing site was "first SO- packet" or a
     bench are discharged HERE and their closure transcribed back to the
     originating ledger row. -->

| id | Item | Must land before | Status |
|---|---|---|---|
| C-nn | <inherited or new obligation> | <SO- packet / bench / gate row> | OPEN / CLOSED (WO-NNNN at `<sha>`) |

## Sponsor items

| # | Item | Status | Signature |
|---|---|---|---|
| S1 | Sponsor informed of the module-ready summary (modules, campaign scores, open BUG- packets) — sign-off here is informational unless the phase plan says otherwise; the accepting decision is P<n>-phase-accept's E1 | OPEN | <recorded in J-orchestrator-NNNN> |

## Exit

Every module row PASS with an adjudicated campaign, carry-forwards
dispositioned, sponsor row recorded → the orchestrator declares the gate
passed in its journal and updates `tasks/BOARD.md`. This opens **P<n>
hardening** — the window between this gate and P<n>-phase-accept, and the
activation window for `formal_dv` and any contingent roles the org chart
marks for overlap (PROTOCOL §7).
