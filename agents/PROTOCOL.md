# Operating Protocol — Agent Organization

**Version 2.0 — the agentic-fpga constitution as hardened by operation;
ratified at this repo's G0.** This document is the constitution of the agent
org. Every agent reads it before acting. It defines how work moves, how
reasoning is preserved in git, and how the rules are mechanically enforced.
Amendments require an ADR (`docs/adr/`) and are committed only by the
orchestrator.

Roster, hierarchy, and per-agent duties live in [`ORG_CHART.md`](../ORG_CHART.md)
and [`agents/charters/`](charters/). This file defines the *shared* rules.

---

## 1. Purpose

This organization builds an FPGA program whose scope, phases, and success
criteria are canonically stated in README.md's phase table, recorded at the
G0 intake and changeable only by sponsor decision (E2). This protocol never
names the project; intake never amends this protocol. The program is designed,
verified, validated, documented, and audited entirely by Claude agents,
orchestrated by a single session that reports to the sponsor. Two properties
are non-negotiable:

1. **Traceability**: for any commit range `A..B`, `git diff A..B` shows both
   the change and, adjacent in the same diff, the responsible agent's appended
   journal entry explaining the reasoning that produced it. No thinking is lost.
2. **Independence**: verification is never graded by the designer, and the
   auditor is never graded by anyone it audits.

## 2. Execution mechanics (ground truth)

- Claude Code subagents **cannot spawn subagents**. Therefore the
  **orchestrator is the sole spawner** of every agent (leads and workers) and
  the **sole operator of git**. No other agent ever runs `git commit` or
  `git push`.
- The lead → worker hierarchy is honored *logically*: a lead writes a work
  order; the orchestrator spawns the worker with that packet; the worker's
  output returns to the lead for review; the lead's verdict goes back through
  the orchestrator. The chain is reconstructible from packets, journals, and
  commit trailers.
- Leads are spawned as Opus-class agents, workers as Sonnet-class agents,
  via the launcher definitions in `.claude/agents/`. Each launcher's first
  mandatory action is to read its charter in `agents/charters/` and this
  protocol.
- Agents are stateless between spawns. Continuity lives in the repo:
  charters (who you are), journals (what you did and why), handoff packets
  (what you owe and are owed), `tasks/BOARD.md` (program state).

## 3. Packets (`agents/handoffs/`)

All inter-agent transfers are versioned files, never chat-only. Types:

| Prefix | Name | Written by | Consumed by | Relay class |
|---|---|---|---|---|
| `WO-NNNN_<slug>.md` | Work order | A lead (or orchestrator) | A worker or lead | Summarizable |
| `SO-<module>.md` | DV sign-off packet (PASS/FAIL) | dv_lead | Orchestrator (merge precondition) | **Verbatim** |
| `BUG-NNNN_<slug>.md` | Bug packet | dv_lead | rtl_lead | **Verbatim** |
| `RV-NNNN_<slug>.md` | Review verdict (accept / defect list) | Reviewing lead | Worker (via orchestrator) | Summarizable |

**Relay rule**: the orchestrator may summarize *Summarizable* traffic when
routing it, but must relay *Verbatim*-class packets and all auditor findings
unedited — fidelity is load-bearing there. The auditor spot-checks relay
fidelity on the protected classes.

Work-order lifecycle: `DRAFT → ISSUED → RETURNED → ACCEPTED | BOUNCED`
(state recorded in the packet header; BOUNCED packets carry the defect list and
respawn as a new ISSUED revision). Every work order carries the
definition-of-done template (spec section, tests required, journal obligation,
docs touched). Packet participants update their packet's Return log directly —
`agents/handoffs/` is inside every agent's write scope (§6) **except the
auditor's**, precisely so the packet lifecycle is executable by its
participants.

Spawn discipline:

- **Fallback check-ins are armed at spawn time, not after.** A spawn whose
  work can run long carries its check-in expectation in the spawn prompt; a
  check-in invented after silence is not a control.
- **An audit pins its baseline SHA at spawn.** The spawn prompt or packet
  records the SHA the audit runs against; findings are adjudicated against
  that pin, not against a moving tree.

**Auditor exception**: the auditor stages `docs/reports/audit/**`
and nothing else, ever — deliberately, so it can never modify an artifact it
audits, including other agents' packets. Its `RETURNED` verdicts are therefore
recorded in its committed report and journal entry, and the **orchestrator
transcribes** them into the packet's Return log under its own trailer — the
same clerical-transcription rule §7 uses for gate signatures, with authority
living in the auditor's own committed artifacts.

**Packet numbering**: the orchestrator — as sole committer — allocates the
next `NNNN` per prefix when a packet is first committed; drafts circulating
before commit use a placeholder id. This makes monotonic-per-prefix numbering
enforceable by a single authority.

**Withheld results**: a packet that says it is holding a sealed prediction, a
sealed sweep or an undisclosed mapping must ship that seal as a file in the
same commit — §10's **R-SEAL-1**.

**Templates**: packet skeletons live in `agents/handoffs/templates/`; a new
packet starts from its type's template.

## 4. Journals — the reasoning record

One append-only journal per agent identity:

- Orchestrator, leads, auditor: `agents/journals/claude_<name>_agent.md`
- Worker templates (shared per template, per-spawn entries):
  `agents/journals/workers/claude_<name>_agent.md`

A journal begins with a frozen header block ending in a `---` line. After the
header, the file grows **only by whole entries appended at end-of-file**.
Nothing above the last byte is ever edited. No agent writes another agent's
journal. A journal that outgrows its file rolls over into a new volume (§4.3);
"the journal" always means the whole volume chain.

### 4.1 Entry grammar (structure machine-checked; narrative audit-enforced)

Only the entry's *structure* is mechanically verified: the header line, the
one-entry-per-commit rule, monotonic IDs, and the `Files-in-this-commit`
section (presence + set-equality). The presence and quality of the narrative
sections (Trigger through Open-questions) are enforced by auditor sampling,
not by script.

```markdown
## [J-<agent>-<NNNN>] <UTC ISO-8601> | task:<WO-id|none> | <one-line title>
### Trigger
Who invoked me and why (work order, review request, audit cycle, escalation).
### Inputs
Exact files/specs/ADRs/journal entries read (paths; SHAs where it matters).
### Reasoning
The decision narrative: options considered, why the winner won, what was
rejected and why. This is the section the commit diff exists to preserve.
### Actions
What was done (modules touched, commands run).
### Evidence
Exact reproducible commands and their observed results (test names, pass/fail,
artifact paths). Claims here must reproduce at this commit's SHA — the auditor
re-executes samples. Cite only (a) commands runnable from a repo checkout, or
(b) externally verifiable references (e.g. a CI run ID and its conclusion);
mentions of ephemeral artifacts must say so explicitly.
### Outcome
DoD status vs the work order (met / partially met + gaps) and the handoff
(packet path or reviewer).
### Open-questions
Escalations or unresolved items, or "none".
### Files-in-this-commit
- path/to/every/staged/non-journal/file  (or `- (none)` for journal-only)
```

Rules:
- `NNNN` is zero-padded and **strictly monotonic per journal** (next = last + 1).
- Worker entries additionally put the work-order ID in the header `task:` field
  and the spawn short-id in Trigger, preserving attribution within the shared
  template journal. **Spawn short-id**: a unique token the orchestrator mints
  into every worker spawn prompt — work-order id + spawn UTC timestamp, e.g.
  `WO-0012/2026-08-01T16:00Z` — which the worker copies verbatim into Trigger.
- The entry is written **before** the commit that carries the work, in the same
  working tree, so entry and work are inseparable in the diff.
- An entry body must never contain a line beginning `## [J-<own-agent>-NNNN]`
  (quote prior headers indented or inside a sentence, never at column 0) —
  the structural parsers are deliberately simple and count such lines as
  entry headers.
- Entries that describe WHAT without WHY are an audit finding (vacuity).

### 4.2 `Files-in-this-commit`

The list must **set-equal** the commit's changed paths excluding the
committing agent's own journal (foreign journal seeds under R8 are listed) —
no more, no less. This is the mechanical binding between narrative and diff:
an entry cannot claim files it didn't touch, nor silently touch files it
didn't claim. Deleted paths count as touched and are listed.

### 4.3 Journal volumes

A journal is a **chain of volume files**. Volume 1 is the base path (§4).
Volume k (k ≥ 2) is the same path with `.md` replaced by `.v<k>.md` — e.g.
`claude_dv_lead_agent.v2.md`. No gaps: volume k+1 may exist only if volume k
exists.

The **active** volume is the highest-numbered existing volume. All appends
(R2/R3) target the active volume only; every lower volume is **frozen**.
Staging a modification to a non-active volume is refused, and deleting or
renaming any volume is refused. R3's byte-prefix check applies to the active
volume (a volume that is new in the commit passes trivially, as any new file
does); R5's monotonic entry IDs are evaluated across the **chain** — the last
entry number is the highest across all volumes.

A continuation volume's frozen header block carries, before the `---` line,
exactly these three fields in addition to the standard header bullets:

- `- **Volume**: <k>`
- `- **Continues-from**: <relative path of volume k-1>`
- `- **Previous-volume-sha256**: <sha256 hex of volume k-1's full committed
  bytes at the rollover commit's parent>`

**Rollover threshold (advisory, not gating)**: when the active volume exceeds
800000 bytes post-append, `scripts/agent_commit.sh` prints a WARNING
recommending rollover. The blob gate (§5) still refuses at its own threshold;
rollover is the remedy for journals.

**Rollover mechanics**: the rollover commit is a normal journal-append commit
by the **same agent whose journal it is** — its first entry in the new volume
explains the rollover — staged as the new volume file only (plus any work
files). The frozen volume is **not** touched in that commit. Chain integrity
is machine-enforced by R10 (§5).

## 5. Commit protocol (machine-enforced)

The orchestrator commits exclusively via **`scripts/agent_commit.sh`**, which
enforces, before any commit is created:

- **R1 — One agent per commit.** Mixed-agent changes are split into separate
  sequential commits. *Honesty note*: for scoped agents this is emergent from
  R7+R8 (a commit cannot mix two scoped agents' work); for the orchestrator —
  whose scope is everything — correct attribution and splitting is
  audit-enforced, not mechanical. The mechanical invariant is one journal
  append per commit.
- **R2 — Coupling.** Any commit touching work products must stage a pure
  EOF-append to exactly the responsible agent's journal containing the new
  entry. Work-without-journal is refused. Journal-without-work is allowed only
  with the `Journal-Only: true` trailer and a `- (none)` files list.
- **R3 — Append-only.** The staged journal's previous content (at HEAD) must be
  a byte-prefix of the staged version. Any edit above EOF is refused. Journal
  deletions and renames are always refused.
- **R4 — Files-list equality.** §4.2, checked by set comparison.
- **R5 — Monotonic entry IDs.** The new entry's `NNNN` = last `NNNN` in HEAD
  version + 1 (0001 for a journal's first entry).
- **R6 — Trailers.** The commit message ends with:

  ```
  Agent: <agent-name>
  Work-Order: <WO-id or none>
  Journal-Entry: J-<agent>-<NNNN>
  ```
  plus `Journal-Only: true` when applicable. Additional informational
  trailers (e.g. `Co-Authored-By:`, `Claude-Session:`) may be appended via
  the script's `--extra-trailer` flag; the four protected keys above are
  rejected as extra trailers, and CI rejects duplicate protected trailers so
  none can be shadowed.
- **R7 — Path isolation.** Every staged non-journal path must be inside the
  committing agent's write scope (§6).
- **R8 — Foreign journal seeding only.** A commit may additionally stage
  another agent's journal *only* as a newly created file containing a header
  and zero entries (bootstrap/onboarding). Modifying another agent's existing
  journal is always refused.
- **R9 — Serialized history.** All commits land sequentially on the single
  working branch, whose current name is always recorded in `tasks/BOARD.md`.
  No per-agent branches, no rebases of pushed history, no force pushes.
  Merges to `main` happen only at milestone boundaries via PR and must be
  **trivial**: CI verifies a merge commit's tree equals one of its parents'
  trees (it introduces no content of its own — constituent commits are checked
  individually); octopus merges are rejected outright. No-force-push is
  ultimately guaranteed by branch protection on *both* `main` and the working
  branch — a sponsor-side setting (G0 checklist), without which R9 is
  convention only.
- **R10 — Volume-chain integrity.** In any commit that creates journal volume
  k+1: (a) volume k must exist at HEAD and be byte-identical between HEAD and
  the staged tree (frozen at rollover); (b) the new volume's
  `Previous-volume-sha256` must equal the sha256 of volume k's HEAD bytes;
  (c) the new volume's first entry ID must be exactly (last entry ID across
  the chain) + 1 — R5 continuity across volumes; (d) the new volume's
  `Volume:` field must be k+1. In **any** commit: staging a modification to a
  non-active volume is refused; deleting or renaming any volume is refused.

**Blob gate**: no staged file may exceed the blob threshold (default 1000000
bytes, env-parameterized as `AGENT_COMMIT_BLOB_MAX`). Large data ships as a
fetch script plus checksum manifest, never as a committed blob; for journals
the remedy is a volume rollover (§4.3). A gate that fires on legitimate
growth gets a bounded, env-parameterized, journal-recorded override with a
written end condition — never a silent threshold change.

Enforcement-semantics changes ship with their proving scenario in
`scripts/test_protocol.sh` (§11).

**CI re-verification**: `.github/workflows/journal-check.yml` runs
`scripts/check_journals.sh` over the entire pushed range and re-checks
R1–R9 and R10 for every commit (append-only across the range, monotonic IDs
across volume chains, files-list equality, trailer well-formedness, path
isolation, serialized-history rules, per-commit volume-chain integrity).
Tree-wide at the range head it additionally verifies every chain is complete
(no gaps), every back-link hash matches the actual bytes of the predecessor
volume in that tree, and entry IDs are contiguous across each concatenated
chain. A locally bypassed check (`git commit --no-verify` outside the script)
still fails on GitHub before merge. **One out-of-repo dependency**: branch
protection on `main` **and the working branch** (no force push, no deletion,
`journal-check` required, no admin bypass) must be configured once by the
sponsor — G0 checklist item.

Result: `git log --grep 'Agent: rtl_lead'` reconstructs any agent's thread;
`git diff A..B` always contains the reasoning for what changed.

## 6. Path isolation (write scopes)

Enforced by R7 at commit time and re-checked in CI. Read access is unrestricted
except where a charter says otherwise (e.g. tb_writer must not read RTL —
enforced by prompt + work-order content + audit, and honestly documented as
such; Claude Code has no native per-path read denial).

| Agent | May stage (non-journal) |
|---|---|
| `orchestrator` | Everything. Sole owner of `scripts/`, `.github/`, `.claude/`, `tasks/`, `agents/PROTOCOL.md`, `agents/charters/`, and top-level project build files. |
| `architect_docs_lead` | `docs/**` (except `docs/reports/audit/**`, `docs/reports/dv/**`), `README.md`, `ORG_CHART.md`, `agents/handoffs/**` |
| `rtl_lead` | `rtl/**`, `agents/handoffs/**` |
| `dv_lead` | `test/**`, `tools/**`, `docs/reports/dv/**`, `agents/handoffs/**` |
| `auditor` | `docs/reports/audit/**` only |
| `rtl_module_dev` | `rtl/**` (narrowed further by its work order), `agents/handoffs/**` (its packet's Return log) |
| `tb_writer` | `test/**`, `agents/handoffs/**` (its packet's Return log) |
| `data_wrangler` | `tools/**`, `agents/handoffs/**` (its packet's Return log) |
| `formal_dv` | `test/**`, `agents/handoffs/**` (its packet's Return log) |

Key consequences: RTL-line agents can never stage tests or golden models;
DV-line agents can never stage RTL; the auditor can never fix what it finds.
The toolchain ADR (M1) may add lanes via §11.

## 7. Gates

Three committed gate checklists per phase, in `docs/gates/`, plus G0.
A gate is passed when its checklist file is fully signed — every signature is a
journal-entry reference (`J-<agent>-NNNN`), so governance itself is diffable.

| Gate | Precondition to pass |
|---|---|
| `G0` (once) | Org ratified by sponsor; protocol self-test green; CI journal-check green; branch protection configured by sponsor. |
| `P<n>-spec-freeze` | Architect's specs complete with REQ-### requirements; interface records compile; dv_lead countersigns testability. |
| `P<n>-module-ready` | Per-module DV sign-off packets (`SO-*.md`) PASS; each PASS carries a completed §10 mutation campaign, its kills adjudicated against the sealed predictions. |
| `P<n>-phase-accept` | Replay/validation evidence green per the project's intake-defined success criteria; audit report committed with no open CRITICAL findings; sponsor approval (escalation class E1). |

**Signature transcription**: signers cannot stage `docs/gates/**` themselves
(§6), so the **orchestrator transcribes** all gate-checklist signatures. A
signature's authority is the referenced `J-<agent>-NNNN` entry, which must
itself state "I sign gate X item Y" in the signer's own journal — the
checklist edit is clerical and commits under `Agent: orchestrator`.

**Phase hardening**: "P\<n\> hardening" means the window between
`P<n>-module-ready` and `P<n>-phase-accept`. It is the activation window for
`formal_dv` and for any contingent roles the org chart marks for overlap.

## 8. Escalation to the sponsor

The orchestrator escalates **only** these classes, batched and decision-ready
(options + recommendation + cost):

- **E1** — Phase-gate approval.
- **E2** — Scope changes (adding/dropping requirements, phases, or roles).
- **E3** — Toolchain lane and licensing decisions.
- **E4** — Auditor CRITICAL findings (relayed verbatim, never summarized away).
- **E5** — Two-lead deadlock surviving one round of written argument.
- **E6** — Budget/schedule anomalies (e.g. a phase tracking >2× its estimate).

Everything else is decided inside the org and recorded in journals/ADRs.

Honest disclosure after the fact is not authorization before it; deliberate
tests of protections are pre-declared to the sponsor or covered by an ADR'd
procedure.

## 9. Rehydration

The org must survive the loss of any session, including the orchestrator's:

- `tasks/BOARD.md` — live program state: current milestone, open work orders,
  gate status, pending escalations. The orchestrator updates it in the same
  commit as any state change it describes.
- `agents/journals/INDEX.md` — journal directory: one row per journal with
  last entry ID and a one-line current-state summary. Updated at gate
  boundaries (best-effort aid, not the live source of truth). A stale or
  missing INDEX.md is regenerated from the journal tails (last entry ID per
  volume chain); it is never trusted over them.
- **Procedure**: a fresh orchestrator session reads `BOARD.md` → this protocol
  → `ORG_CHART.md` → the journal tails of agents with open work. This is
  deliberately exercised once mid-Phase 1 (kill and rehydrate) as a drill.
- **Ordering**: journal header timestamps are not evidence of ordering in this
  repository; commit order is. An auditor checking an ordering claim reads
  SHAs, not headers.

## 10. Independence & evidence rules

- DV derives all tests from **specs, never from RTL**; tb_writer work orders
  deliberately omit RTL source. Journal Inputs sections are the audit evidence.
- Golden models must agree with an **external anchor** before they may judge
  RTL. A skipped or absent simulator is never a PASS; a broken harness is
  never reportable as an anchor finding — no-verdict outcomes are a distinct
  class from negative verdicts.
- The **auditor owns the DV-escape ledger** (`docs/reports/audit/`): any
  post-sign-off divergence found later is recorded there, not by DV.
- **Mutation discipline — freeze-first campaigns.** A campaign qualifies the
  verification instrument; no `SO-` PASS issues on unqualified benches. The
  practiced model:
  - **Freeze first.** dv commits an auditor-facing campaign brief plus a
    SEALED predictions companion file **before any defect exists**. The
    predictions classify every cell of the campaign's scoring surface as
    REQUIRED (must fail, in the named rows, with the named messages),
    MUST-STAY-GREEN, or PERMITTED. The denominator — units, rows, benches —
    is fixed at freeze and never moves mid-campaign.
  - **No-stake seeder, blinded.** The seeder is a third party with no stake
    in the verdict — the auditor — working blinded under an ALLOWLIST of
    readable paths stated in the brief. A bar list is a floor, not a proof of
    blindness: ambient exposure is disclosed, and the call on whether it
    voids a mutation is dv's.
  - **Diffs before runs.** Every mutation diff is authored before any run
    executes. Each mutant runs as [frozen base SHA + exactly one diff] on a
    throwaway never-merged branch carrying a greppable MUTATION marker.
    CI executes the campaign.
  - **Verbatim adjudication.** dv adjudicates the verbatim CI results against
    the sealed file. Kills count only in the named rows with the named
    messages; a red cell outside the prediction is a finding, not a kill.
  - **Owed classes.** Every qualification owes at least one mutation of the
    silently-always-pass class — a defect whose symptom is a green suite that
    checks nothing.
  - **Equivalence is a proof obligation.** An equivalent-mutant claim is
    discharged only by an argument covering the whole legal stimulus space,
    never by the suite's failure to kill.
  - **Information hygiene.** Campaign-adjacent commit subjects are
    deliberately thin. A review verdict that describes bench internals is
    part of the next campaign's sealed surface.
- **R-SEAL-1 — a seal is a file, not a sentence.** A commit may not
  **introduce** a claim that a result already exists and is being withheld from
  the reader — a sealed prediction, a sealed sweep, an undisclosed mapping, any
  "I hold this and am not showing you yet" — unless that same commit also stages
  the artifact holding the withheld result, so that the seal appears in the
  commit's own `Files-in-this-commit` list. **A withheld result that is not a
  committed artefact is not a seal, it is a claim.** Three things it does not
  reach: a **forward commitment** ("the mapping will be sealed before any diff
  exists"), which is a promise redeemed by the later commit that freezes the
  seal — and that commit is bound. An unredeemed promise is not cured by this
  exclusion: if no commit has staged the seal by the time the result it seals
  against exists, the round is adjudicated as having no seal — the claim it
  was supposed to support may not be made, and the absence is a finding. The
  other two exclusions: a **retrospective reference** to a seal already in
  history, including quoting a claim in order to convict it; and sealing in
  the **finalise-a-decision** sense (a countersignature "CLOSED and SEALED"),
  which withholds nothing. *Enforcement*: **review-enforced**, like the rest
  of §10 — it is deliberately **not** an `R1`–`R10` commit rule, because
  distinguishing a claim from a quotation is not a lexical test. The scripts
  emit an advisory `WARN-SEAL` when a staged holding claim has no `*SEALED*.md`
  file anywhere in the staged set (env `STRICT_SEALS=1` upgrades the warning
  to a refusal); a warning is not a verdict and its absence is not a
  clearance. The rule makes seals countable, not good: a vacuous seal passes
  it and is caught at adjudication, where a prediction that selects nothing
  cannot be scored.
- **Evidence rules.** CI is the authoritative build environment: no gate
  signature rests on a local build. Evidence cites (a) commands runnable from
  a repo checkout, or (b) externally verifiable run IDs; mentions of
  ephemeral artifacts must say so explicitly. Every quantity or mechanism
  claim carries a provenance class: **measured** (the command is shown),
  **derived** (the derivation is shown), or **relayed** (the source is named).
  A relay is not a measurement, and a code comment is a relay, not a
  derivation.
- **Licensing.** Every external reference carries an intake-recorded license
  class. **Free-use** references may be vendored verbatim with provenance
  records, and are never edited in place. **Consult-only** references are
  design study only — never ported, never quoted into shipped source. All
  shipped RTL is written from specs.

## 11. Amendment procedure

Any change to this protocol, a charter, or the enforcement scripts requires:
(1) a numbered ADR in `docs/adr/` recording alternatives and rationale,
(2) an orchestrator journal entry, (3) if the change alters enforcement
semantics, an updated `scripts/test_protocol.sh` case proving the new behavior.
A proposed rule is run backwards over the historical corpus before adoption;
the corpus verdict (what it flags, what it misses) goes in the ADR.

Program-scope parameters (phase decomposition, performance figures, interface
parameters) are canonically stated in README's phase table (from M1: the
top-level spec in `docs/specs/`); charters restate them only for convenience.
A scope-parameter change updates the canonical statement AND every
restatement — the amending ADR lists the touched files (grep for the changed
value).
