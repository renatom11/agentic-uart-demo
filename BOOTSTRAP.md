# BOOTSTRAP — from cloned shell to running program

## What you get

This repository is a complete agent organization with the project left as a
slot. At the end of this walkthrough: the org is ratified and
branch-protected; the project's scope, phases, and success criteria are
recorded in [`README.md`](README.md)'s phase table and on
[`tasks/BOARD.md`](tasks/BOARD.md); the toolchain is decided by ADR; the
build CI is live; and work orders issue under the same enforcement machinery
that was proven in the source program — every commit coupled to its author's
journal entry, verified locally and re-verified over full history in CI.

Two people walk it: the **sponsor** (a human — your side of the org is
[`docs/SPONSOR.md`](docs/SPONSOR.md)) and the **orchestrator** (a fresh
Claude session in this repository, which boots from
[`CLAUDE.md`](CLAUDE.md)). The live checklist both are filling is
[`docs/gates/G0-checklist.md`](docs/gates/G0-checklist.md).

## Stage 1 — G0: ratify the org, fill the project slot

### Section A — org ratification

**Orchestrator first.** Confirm the seeded rows (G0 items A1–A5) still hold
at your HEAD — each row carries its verify command; run them
(`bash scripts/test_protocol.sh`, `bash scripts/check_journals.sh --all`,
Actions tab green). These were satisfied at seeding under
J-orchestrator-0001/0002; you are re-verifying, not re-doing.

**Sponsor next, two duties in order:**

1. **A6 — charter critique.** Read [`ORG_CHART.md`](ORG_CHART.md) and the
   nine charters in [`agents/charters/`](agents/charters/). Ratify, or ask
   the orchestrator for amendments — amendments before ratification are
   ADRs like any other (PROTOCOL §11). Your approval is recorded in an
   orchestrator journal entry and transcribed onto the checklist.
2. **A7 + A8 — branch protection and branch topology.** Decide A8 first
   (single-branch on `main`, or working branch + milestone PRs — the
   checklist explains what each costs); the orchestrator records the
   decision on the BOARD. Then configure the rulesets per the A7 click-path
   in the checklist. The orchestrator verifies rejection by live fire (an
   attempted force-push that bounces) and journals the result.

### Section B — project intake

Two ways to fill it — the recorded outcome is identical:

**Path A — questionnaire.** The sponsor answers the five rows (G0 items
B1–B5) directly, interview-style.

**Path B — brain dump plus resources (the expected path).** The sponsor
provides whatever exists, in two forms, freely mixed:

- **Prose**, pasted into the session — ideas, constraints, goals,
  half-formed thoughts.
- **Files**, dropped into an `intake/` directory — documentation about
  what is being built, rough requirement drafts, reference specs,
  datasheets, links files, prior-art notes. Anything goes; sorting it is
  the org's work, not the sponsor's.

The orchestrator digests all of it into PROPOSED answers for the five
rows — a draft phase table, candidate toolchains with trade-offs,
proposed license classes for every reference found in the material, a
proposed simulation boundary and per-phase success criteria — and
presents the whole proposal for sponsor sign-off in one round, asking
questions only where the material genuinely underdetermines an answer.
The sponsor edits and signs; nothing is binding until signed.

**Intake resources outlive the intake.** Files in `intake/` are not
consumed and discarded: they are recorded on the BOARD with their
license class and remain the org's project reference material — rough
requirement drafts feed the architect's real REQ-### requirements work
in the first spec milestone; reference designs feed the DV lead's
external-anchor planning (free-use) or design study (consult-only). The
sponsor may prune `intake/` at any time; what the org relies on gets
cited into specs and ADRs by then, under each file's license class.

Either way, the orchestrator records every signed answer into README's
phase table and onto the BOARD in the same commit, then transcribes
signatures:

1. **B1** — the project, decomposed into phases.
2. **B2** — scope parameters and performance criteria, as numbers.
3. **B3** — external references, each classed free-use or consult-only.
4. **B4** — the simulation-first boundary.
5. **B5** — success criteria per phase (these become the
   `P<n>-phase-accept` acceptance rows later, via
   [`docs/gates/templates/`](docs/gates/templates/)).

Intake fills the project slot; it never amends the protocol (PROTOCOL §1).
Until intake is on the BOARD, the orchestrator spawns no agent.

### Closing Stage 1

**A9 — the retro-audit, the org's first spawn.** With intake recorded, the
orchestrator spawns the auditor to retro-audit the seed commit range
(baseline SHA pinned in the spawn packet, PROTOCOL §3). Its report lands in
`docs/reports/audit/` (conventions:
[`docs/reports/audit/README.md`](docs/reports/audit/README.md)). Findings
are dispositioned; a CRITICAL blocks the gate until ADR'd and re-verified.

**The gate flip.** All rows signed → the orchestrator declares G0 passed in
its journal, flips the BOARD (milestone → M1), and Stage 2 opens.

## Stage 2 — M1: toolchain, build CI, spec regime

### 2.1 The toolchain ADR (escalation class E3)

The orchestrator prepares the decision **decision-ready** and escalates E3.
Skeleton (modeled on the source program's toolchain ADR):

```markdown
# ADR-NNNN: Toolchain lane — <decision>

- **Status**: Accepted (sponsor decision, E3, <date>)
- **Deciders**: sponsor, on orchestrator escalation with options +
  recommendation + cost (PROTOCOL §8)

## Context
Every M1+ artifact — build project, CI, the specs' §4.1 interface regime,
all RTL and tests — binds to one toolchain lane. Candidate lanes and their
license classes were recorded at the B3 intake.

## Options
| Lane | For | Against | Cost / risk |
|---|---|---|---|

## Decision
<the lane; where exact version pins live (committed project files, not CI
steps); recommendation and cost as escalated>

## Consequences
- The interface-record regime for SPEC-TEMPLATE §4.1 (see 2.3).
- CI instantiation proceeds (see 2.2).
- New write-scope lanes for PROTOCOL §6's table, if any (see 2.4).
- A needed capability missing from the lane is a NEW E3 — named gap,
  raised before the affected gate — not a quiet re-pin.
```

### 2.2 Instantiate the build CI

After the ADR is accepted, the orchestrator runs:

```sh
git mv .github/workflows/build.yml.template .github/workflows/build.yml
```

and fills every `<SLOT>` (setup toolchain / install deps / build / test)
for the chosen lane, keeping or deleting the two ready-made blocks — the
promotion-block failure handler and the staged-diff determinism gate — per
their "delete if not applicable" notes. Recipes and the R-CI rules for any
later simulator lanes: [`docs/playbooks/ci-evidence.md`](docs/playbooks/ci-evidence.md).
This is an orchestrator commit citing the toolchain ADR.

### 2.3 Instantiate SPEC-TEMPLATE §4.1

Record in the ADR (and from then on in every spec) which interface regime
the program runs: **compile-checked interface records** where the M1
toolchain supports them — wiring the interface-check lane the ADR names —
or the stated fallback, **reviewed port tables** graded line-by-line at the
dv_lead countersignature
([`docs/specs/SPEC-TEMPLATE.md`](docs/specs/SPEC-TEMPLATE.md), how-to-use
item 6 and §12).

### 2.4 Lane amendments, if the ADR adds any

If the toolchain decision creates new write-scope lanes (new top-level
paths, new worker roles), those are amendments to PROTOCOL §6's table —
made via §11: numbered ADR, orchestrator journal entry, and an updated
enforcement self-test case if commit semantics change.

## The org runs as proven

From here the loop is the one the source program practiced — five lines:

1. A lead drafts a `WO-` from
   [`agents/handoffs/templates/WO-template.md`](agents/handoffs/templates/WO-template.md);
   the orchestrator allocates its number and commits it (PROTOCOL §3).
2. The orchestrator spawns the worker with the packet — spawn short-id in
   the prompt, check-in expectation armed at spawn.
3. The worker returns; the orchestrator lands its layer and journal
   (splitting shared files per
   [`docs/playbooks/packet-splitting.md`](docs/playbooks/packet-splitting.md)).
4. The owning lead reviews against the packet's spec basis
   ([`docs/playbooks/review.md`](docs/playbooks/review.md)) — ACCEPT, or
   BOUNCE with the RV- defect list; benches are qualified by freeze-first
   mutation campaigns
   ([`docs/playbooks/mutation-campaign.md`](docs/playbooks/mutation-campaign.md))
   before any `SO-` PASS.
5. Gates close by signed checklists instantiated from
   [`docs/gates/templates/`](docs/gates/templates/); the sponsor sees only
   E1–E6, batched and decision-ready, on the BOARD.
