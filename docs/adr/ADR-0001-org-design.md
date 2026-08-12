# ADR-0001: Org design — "Lean Five" with enforcement grafts

- **Status**: **ACCEPTED (pre-adopted at seeding)** — adopted as part of the
  shell's constitution; provenance below; amendable only via PROTOCOL §11.
- **Deciders**: pre-adopted from the source program's ratified design
  (agentic-fpga ADR-0001/ADR-0002 and the two G0 audits); the sponsor
  re-ratifies the whole constitution at this shell's G0.
- **Scope**: the roster, the spawning and commit topology, the gate ladder,
  the rehydration artifacts, and the contingent-role pattern. The shared rules
  themselves live in `agents/PROTOCOL.md`; this ADR records why the org is
  shaped the way it is.

## Context

This shell packages an agent organization for a full engineering lifecycle
(architecture → implementation → verification/validation → docs → audit)
executed entirely by Claude agents under one orchestrator session, with a
project slot filled at G0 intake. Two mechanical constraints shape every
structural choice, established empirically in the source program: subagents
cannot spawn subagents, and concurrent agents share one working directory.
Any design assuming nested spawning or parallel per-agent branches cannot
execute as written.

The source program ran a 7-agent design workflow (three independent org
designs, adversarially judged), operated the winner for a full milestone
arc, then audited its own bootstrap twice (AUD-0001, AUD-0002). What is
pre-adopted here is the judged design *plus* everything those audits and that
operation forced onto it.

## Decision

1. **Roster — "Lean Five".** Five long-lived minds — orchestrator,
   architect_docs_lead, rtl_lead, dv_lead, auditor — plus worker templates
   (rtl_module_dev, tb_writer, data_wrangler, formal_dv). Architecture and
   docs are one role (eliminates spec/doc drift); verification and validation
   are one role (one owner for stimulus, golden models, and replay). The
   merged-DV self-grading hole is closed structurally: the auditor — never DV
   — owns the DV-escape ledger, golden models need an external anchor before
   they may judge, and every sign-off requires a completed mutation campaign
   (PROTOCOL §10, ADR-0006).
2. **Sole spawner, sole committer.** The orchestrator is the only agent that
   spawns agents and the only agent that operates git (PROTOCOL §2). The
   lead → worker hierarchy is honored logically through versioned packets;
   the chain is reconstructible from packets, journals, and commit trailers.
3. **Mechanical journal↔diff binding.** Commits happen only via
   `scripts/agent_commit.sh` enforcing R1–R10 (PROTOCOL §5): one agent per
   commit, work coupled to a pure EOF-append journal entry, byte-prefix
   append-only, `Files-in-this-commit` set-equality, monotonic entry IDs,
   binding trailers, path isolation per agent (§6), foreign-journal seeding
   only, serialized history, and volume-chain integrity. CI re-verifies the
   whole pushed range and the full history on every push.
4. **Evidence falsifiability.** Journal Evidence sections carry exact
   reproducible commands or externally verifiable run references; the auditor
   re-executes samples at the recorded SHA. Unreproducible claims are audit
   findings (PROTOCOL §4.1).
5. **Minimal gate ladder.** G0 once, then three committed gate checklists per
   phase — spec-freeze → module-ready → phase-accept — whose signatures are
   journal-entry references stating "I sign gate X item Y" in the signer's
   own journal; the checklist edit is clerical, orchestrator-transcribed
   (PROTOCOL §7).
6. **Attack-plan obligation.** Every module under verification carries a
   committed, canonical attack plan enumerating rows, observables, and — per
   row — what defect kills it. A kills cell reading "a broken design" is a
   row that was not thought about; the plan is the campaign's scoring
   surface and the sign-off's coverage argument.
7. **Rehydration artifacts.** `tasks/BOARD.md` (live program state, updated
   in the same commit as the state change it describes) and
   `agents/journals/INDEX.md` (regenerable directory, never trusted over the
   journal tails). A fresh-orchestrator resume drill is scheduled once
   mid-program (PROTOCOL §9).
8. **The contingent-role pattern.** A role the org may need but does not yet
   staff (a second implementation lead for phase overlap, a formal-methods
   worker) exists from day zero as: a dormant org-chart entry with a full
   charter, activated only by the conjunction of (a) a sponsor E2 decision
   (roles are scope), (b) an ADR recording the activation and its
   partition, (c) a journal seeded under R8 (header, zero entries), and
   (d) a committed scope-partition work order dividing write paths before
   the first spawn. Activation without all four is a protocol violation, not
   an expedient.

## Alternatives considered

Condensed honestly from the source design round:

- **"Silicon-Team Mirror"** — 18 agents mirroring a real silicon org, six
  sign-off gates. Rejected: ceremony disproportionate to the program size, a
  lone sponsor cannot track 18 agents, and its parallel-branch mechanics do
  not survive a shared working directory. Its REQ-### traceability and its
  gate idea were adopted, the gates reduced from six to three.
- **"Twin-Ladder"** — verification-sovereign twin hierarchies meeting only at
  the orchestrator, ~19 agents, universal verbatim relay. Rejected as a
  whole: the relay tax consumes the orchestrator and its parallel-branch git
  model is internally incoherent. Its enforcement core (journal↔diff
  binding) and its evidence-falsifiability discipline are grafts 3–4 above.
- **Single do-everything agent per phase** — rejected: no independence
  between design and verification, and no audit surface.
- **Extending the auditor's write scope for convenience** (revisited twice in
  the source, AUD-0001 F17): rejected both times. The auditor stages its own
  report tree and nothing else, ever, so it can never modify an artifact it
  audits; its packet-lifecycle updates are orchestrator-transcribed. The
  source's first audit found a bootstrap defect precisely in the one role
  the adversarial review had not covered — the argument for keeping the
  auditor's scope narrow rather than symmetric.

## Consequences

- An org one human can hold in their head, with git mechanics that actually
  execute under the two constraints, and the strongest available guarantee
  that any commit range carries its reasoning.
- The orchestrator is a single point of failure — mitigated by the
  rehydration artifacts and drill, not eliminated.
- Serialized commits limit parallel file mutation; parallel lanes are run on
  disjoint paths and disjoint journals or not at all.
- One out-of-repo dependency, inherited deliberately: sponsor-configured
  branch protection on `main` **and the working branch** (G0 checklist).
  Without it the append-only guarantee is voidable by force push.

## Provenance

Source program, pinned at commit `1799e10a37f19059ac3337982af4b6d035e14d0c`:

- Org design and grafts: [docs/adr/ADR-0001-org-design.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0001-org-design.md)
- Pre-G0 adversarial review (26 findings; worker-scope fix, trivial-merge
  rule, honesty corrections, contingent-role rulings):
  [docs/adr/ADR-0002-adversarial-review-fixes.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0002-adversarial-review-fixes.md)
- The two G0 audits:
  [docs/reports/audit/AUD-0001-g0-retro.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/reports/audit/AUD-0001-g0-retro.md)
  and [docs/reports/audit/AUD-0002-g0-reverification.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/reports/audit/AUD-0002-g0-reverification.md),
  dispositioned in
  [docs/adr/ADR-0003-aud-0001-disposition.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0003-aud-0001-disposition.md)
- Journal entries: `J-orchestrator-0009`, `J-orchestrator-0012` (gate
  re-signing in the required form), `J-auditor-0002`, `J-auditor-0003`
  (audit corrections and re-verification), in
  [agents/journals/claude_orchestrator_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_orchestrator_agent.md)
  and [agents/journals/claude_auditor_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_auditor_agent.md)
