# The Sponsor's Guide

You are the program's final authority. Everything else runs itself; this page
is the complete list of what is genuinely yours, written for an evening
check-in, not a process manual.

## Your to-do list lives in one place

Open [`tasks/BOARD.md`](../tasks/BOARD.md) → **"Pending escalations to
sponsor"**. If that section is empty, nothing needs you. The orchestrator
batches; it does not dribble.

## The six things that can reach you

Every contact from the orchestrator belongs to exactly one class
(anything else is a process violation worth calling out):

| Class | In plain language | Your move |
|---|---|---|
| **E1** | "A phase gate is ready — approve it?" | Read the evidence bundle, approve or ask |
| **E2** | "Scope change proposed" (add/drop a requirement, phase, or role) | Decide |
| **E3** | "Toolchain or licensing decision needed" | Decide |
| **E4** | "The auditor found something CRITICAL" — relayed to you word-for-word, never softened | Read it directly; the orchestrator may not summarize it |
| **E5** | "Two leads deadlocked after one written round" | Break the tie |
| **E6** | "A phase is running >2× its estimate" | Re-scope, accept, or stop |

Every escalation arrives decision-ready: options, a recommendation, and cost.
If one doesn't, bounce it back.

## Your one-time setup duty

**Branch protection** — G0 Section A, item A7 (exact click-path in
[`docs/gates/G0-checklist.md`](gates/G0-checklist.md)). Until you do this,
the append-only journal guarantee is enforced only by convention: an admin
force-push could rewrite history. Five minutes, once. Item A8 (same
checklist) is the one accompanying decision: whether the org works on `main`
directly or through a working branch with milestone PRs.

## Your standing (optional) power: canaries

You may occasionally plant a deliberate process violation — e.g. hand-edit a
journal line in a commit, or ask the orchestrator to relay an altered packet —
to test whether the auditor catches it. Tell no one in advance, including the
auditor (its charter tells it canaries exist but never when). A missed canary
is a CRITICAL finding against the auditor. This page documents the mechanism;
never document the instances.

## How to spot-check the org yourself (any time)

- `git log --oneline` — every commit title, one agent each.
- `git log --grep 'Agent: rtl_lead'` — one agent's entire thread.
- `git show <commit>` — any change plus the reasoning that produced it,
  in the same diff. That's the core guarantee; if you ever see a work change
  without its journal entry, the machinery failed — say so.
- [`ORG_CHART.md`](../ORG_CHART.md) → any charter → that agent's journal tail.
- CI tab: `journal-check` must be green on every push.

## What is deliberately NOT yours

Module design choices, test adequacy, work-order routing, bounce/accept
verdicts, and schedule micro-management all stay inside the org — they reach
you only if they escalate into one of the six classes above. If you want to
change how the org itself works, ask the orchestrator for an ADR (protocol
and charters change only that way, PROTOCOL §11).
