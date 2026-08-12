# A reusable AI-agent organization for FPGA programs

This repository is a cloned shell, not a finished project. It contains a
complete agent organization for running an FPGA program — charters, an
operating protocol, commit-enforcement machinery, spawn launchers, and seeded
journals — with the project itself left as an explicit slot. A human sponsor
and an orchestrator session fill that slot at the G0 intake, and the org then
designs, verifies, validates, documents, and audits the program around it.
The org design and its enforcement machinery were distilled from the
[agentic-fpga program](https://github.com/renatom11/agentic-fpga), where they
were proven in operation.

## The project

Filled at G0 intake — see [BOOTSTRAP.md](BOOTSTRAP.md). The table below is the
canonical statement of scope, phases, and success criteria (PROTOCOL §1);
it changes only by sponsor decision (E2).

| Phase | Scope | Success criteria |
|---|---|---|
| _—_ | _recorded at G0 intake_ | _recorded at G0 intake_ |

## The org

**Start at [`ORG_CHART.md`](ORG_CHART.md).** Every agent has a
version-controlled charter in [`agents/charters/`](agents/charters/) defining
its responsibilities, interfaces, definition of done, evaluation criteria, and
escalation rules. Shared rules live in
[`agents/PROTOCOL.md`](agents/PROTOCOL.md). Live program state is in
[`tasks/BOARD.md`](tasks/BOARD.md).

## The journaling guarantee

Every agent keeps an **append-only journal**
(`agents/journals/claude_<name>_agent.md`, a volume chain per PROTOCOL §4.3)
and every commit couples one agent's work with that agent's journal entry
explaining it — mechanically enforced by
[`scripts/agent_commit.sh`](scripts/agent_commit.sh) and re-verified over
every pushed range by CI
([`.github/workflows/journal-check.yml`](.github/workflows/journal-check.yml)).

Consequences you can rely on:

- `git diff A..B` — for *any* two commits — shows both what changed and the
  reasoning that produced it, side by side in the same diff.
- `git log --grep 'Agent: rtl_lead'` reconstructs any one agent's entire
  thread of work.
- Journal history cannot be quietly rewritten: the append-only property is
  re-checked over the FULL history on every push (an incremental range check
  cannot detect a rewrite), backstopped by branch protection on `main` and the
  working branch (a one-time sponsor setup, G0 checklist item), and journal
  `Evidence` sections are falsifiable — the auditor re-executes them at the
  recorded SHA.

Run the enforcement self-test: `bash scripts/test_protocol.sh`.

## Getting started

**To start a project with this shell:**

1. **Fork this repository** (or clone it and push to a new empty repo of
   your own) — one fork per project. Do **not** use GitHub's "Use this
   template" button: it squashes history into a single commit, and this
   repository's commit history is load-bearing — the journal-check CI
   verifies the whole chain, and a squashed history fails it by design.
2. Open a Claude Code session on your fork, on any machine, and say:
   *"Read CLAUDE.md — you are this repository's orchestrator. Walk me
   through G0."*
3. Give it your material: paste prose, and/or drop files — docs about
   what you're building, rough requirement drafts, reference specs,
   datasheets — into an `intake/` directory. The org digests everything
   into one proposal for your signature ([BOOTSTRAP.md](BOOTSTRAP.md)
   Section B, Path B); your resources then remain its project reference
   material.
4. Do the two sponsor-only duties when the checklist reaches them:
   ratify the charters and set branch protection (a GitHub settings
   action).

The sponsor and the fresh orchestrator session walk G0 together;
[BOOTSTRAP.md](BOOTSTRAP.md) is the script. G0 covers: org ratification (or
amendment before ratification), branch protection on `main` and the working
branch, a green enforcement self-test, and the project intake that fills the
phase table above and records the toolchain candidates, external references,
and their license classes. Until the intake is recorded on
[`tasks/BOARD.md`](tasks/BOARD.md), the orchestrator spawns no agent.

## Repository map

```
BOOTSTRAP.md          the G0 walk-through: sponsor + orchestrator fill the project slot
CLAUDE.md             orchestrator session bootstrap (rehydration order, iron rules)
ORG_CHART.md          the org: chart, roster, execution model
agents/
  PROTOCOL.md         shared operating constitution (journals, commits, gates)
  charters/           per-agent instruction files — open any of them
  journals/           append-only reasoning logs, one volume chain per agent
  handoffs/           versioned work orders, sign-offs, bug packets (+ templates/)
docs/
  adr/                architecture decision records (constitution ADRs seeded)
  gates/              committed gate checklists (signatures = journal refs)
  specs/              module specs and REQ-### requirements (fills after intake)
  reports/audit/      auditor findings, DV-escape ledger
  reports/dv/         DV validation and performance reports
scripts/              protocol enforcement + self-test
tasks/BOARD.md        live program state
.claude/agents/       thin spawn launchers (charters remain the truth)
rtl/ test/ tools/     created as the program builds (M1+)
```
