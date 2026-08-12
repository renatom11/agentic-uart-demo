# Program Board

**Live program state.** The orchestrator updates this file in the same commit
as any state change it describes. A fresh orchestrator session rehydrates by
reading: this board → `agents/PROTOCOL.md` → `ORG_CHART.md` → journal tails of
agents with open work.

## Current milestone

**M0 — bring-up.** This shell was seeded from the agentic-fpga program
(reference: https://github.com/renatom11/agentic-fpga, source pin
1799e10a37f19059ac3337982af4b6d035e14d0c) by that program's orchestrator
session; **seeding is COMPLETE at C9** and the operating orchestrator session
takes over here. Working branch: `main`.

Seeding verification, recorded at C9: enforcement self-test 38/38 in a fresh
clone; `check_journals.sh --all` green over the full seed history (R10 chain
verified); journal-check CI green on every push; toolchain-term sweep clean;
the only SEALED-named file is the mechanics template; zero broken relative
links; all 35 provenance permalinks into the source program return HTTP 200;
the bootstrap dry-run (a toy project walked through Stage 1+2) passed.

**Open for the operating orchestrator, in order** (details:
`docs/gates/G0-checklist.md`): sponsor charter critique (A6); sponsor branch
protection + branch-flow decision (A7/A8); project intake questionnaire (B1-B5
→ README phase table + this board); the auditor retro-audit of the seed commit
range as the org's first spawn (A9); then Stage 2 (toolchain ADR via E3,
build-CI template activation).

## Milestone roadmap

| Milestone | Scope | Status |
|---|---|---|
| M0 | Bring-up: G0 intake, org ratification, branch protection, enforcement self-test green | **In progress** |
| M1+ | Set at G0 intake — recorded here and in README.md's phase table | Pending |

## Gates

| Gate | Status | Checklist |
|---|---|---|
| G0 | **OPEN** | [docs/gates/G0-checklist.md](../docs/gates/G0-checklist.md) |

## Open work orders

_None._

## Pending escalations to sponsor

- **G0 ratification** — the sponsor ratifies the org: this protocol, the
  roster, the charters (or amends them before ratifying).
- **Branch protection** — the sponsor configures branch protection on `main`
  and the working branch (no force push, no deletion, `journal-check`
  required, no admin bypass); without it PROTOCOL §5 R9 is convention only.
- **G0 intake** — the sponsor states the project: scope, phases, success
  criteria, and license classes for external references, recorded in
  README.md's phase table per PROTOCOL §1.

## Decisions on record

- Constitution ADR-0001..0007 pre-adopted at seeding (see each ADR's
  provenance).
