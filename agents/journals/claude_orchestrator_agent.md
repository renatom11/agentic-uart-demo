# Journal: claude_orchestrator_agent

- **Agent**: orchestrator (main session)
- **Charter**: agents/charters/orchestrator.md
- **Format**: v2 — entry grammar in agents/PROTOCOL.md §4

This file is APPEND-ONLY. Content may only ever be added after the last line;
nothing above it is ever edited. Enforced by scripts/agent_commit.sh and CI.

---
## [J-orchestrator-0001] 2026-08-12T23:20:00Z | task:none | Shell seeded into agentic-uart-demo: seven seats, two dormant seats dropped, self-test green at 38/38

### Trigger
Sponsor commission (2026-08-12): build a real, working proof of concept of
this framework end to end — real SystemVerilog RTL, a real testbench, real
simulation runs — on a small design, in a repository of its own, so the NIC
program and this demonstration stay separate. The example design is uart_lite:
115200 baud 8N1 on a 50 MHz clock. Sponsor direction was "you make all the
calls", with one stated outcome: a working testbench worth showing off.

### Inputs
- Source shell: renatom11/generic-agentic-fpga-org at pinned SHA
  295f26891e60d092075bbfa97eee07881de2d5db.
- Target: renatom11/agentic-uart-demo, created empty by the sponsor.

### Reasoning
- **Copied by file rather than by fork.** The shell's README documents forking
  from a hosted upstream, which is the right pattern for an enterprise install:
  host the shell once internally, fork per project. For one demo repository the
  sponsor had already created, a file copy is the same result without the
  ceremony. The shell's own docs were left unedited.
- **Two seats dropped rather than carried dormant.** data_wrangler exists to
  fetch and packetize external market data; formal_dv exists to drive SAT-based
  equivalence proofs. A UART peripheral will wake neither. Carrying them would
  leave ORG_CHART.md advertising seats this program will never spawn, and a
  roster that overstates the organization is a roster that lies.
- **The inherited journal history was NOT carried, and that reversed my first
  decision.** I initially copied the shell's thirteen seeding entries into this
  repository's journals as provenance. That was wrong, and the enforcement
  caught it: check_journals.sh refused the genesis commit with "appended region
  has 14 entry headers, expected 1 (R5)". The rule was right on a deeper ground
  than the one it states. Those entries describe commits made in
  generic-agentic-fpga-org, by a session working on that repository. Carrying
  them here would make this repository's journal assert work that was never
  done here — precisely the dishonesty the journal rule exists to prevent. The
  shell's provenance belongs in this entry, as a pinned SHA, and it is above.
- **The path lanes needed no change.** The shell already lanes RTL to rtl/** and
  benches to test/**; it never assumed a language, so moving from the source
  program's Hardcaml to SystemVerilog touches no enforcement. That is the shell
  doing its job.
- Toolchain choice deferred to its own ADR rather than settled here.

### Actions
- Copied the shell tree excluding .git and the two dormant seats.
- Removed the dormant seats from ORG_CHART.md (graph nodes, activation edges,
  style lines, roster rows), agents/journals/INDEX.md, and the KNOWN_AGENTS /
  WORKER_AGENTS / write-scope tables in scripts/policy.sh.
- Truncated every journal to its header, so this journal starts at entry 0001.
- Restored an empty docs/reports/audit/ with a .gitkeep; made scripts executable.

### Evidence
- `bash -n scripts/policy.sh` — clean after the roster edit.
- `bash scripts/test_protocol.sh` → **38 passed, 0 failed**, run in this
  repository against the edited policy.sh, not inherited from the source.
- `grep -c "data_wrangler\|formal_dv"` → 0 in ORG_CHART.md, INDEX.md, policy.sh.
- `iverilog -V` → Icarus Verilog version 12.0 (stable), installed this session.

### Enforcement note — the one commit that cannot pass the gate
This is the repository's genesis commit: there is no HEAD for R3's append-only
check to diff against, so `agent_commit.sh` cannot run on it. It is made with
plain `git commit`, and it is the only commit in this repository's history that
will ever be made that way. Every commit after it goes through
`scripts/agent_commit.sh`, and `scripts/check_journals.sh --all` re-verifies the
whole history including this one.

### Files-in-this-commit
- .claude/agents/architect_docs_lead.md
- .claude/agents/auditor.md
- .claude/agents/dv_lead.md
- .claude/agents/rtl_lead.md
- .claude/agents/rtl_module_dev.md
- .claude/agents/tb_writer.md
- .github/workflows/build.yml.template
- .github/workflows/journal-check.yml
- .gitignore
- BOOTSTRAP.md
- CLAUDE.md
- ORG_CHART.md
- README.md
- agents/PROTOCOL.md
- agents/charters/architect_docs_lead.md
- agents/charters/auditor.md
- agents/charters/dv_lead.md
- agents/charters/orchestrator.md
- agents/charters/rtl_lead.md
- agents/charters/rtl_module_dev.md
- agents/charters/tb_writer.md
- agents/handoffs/README.md
- agents/handoffs/templates/BUG-template.md
- agents/handoffs/templates/CAMPAIGN-template.md
- agents/handoffs/templates/RV-template.md
- agents/handoffs/templates/SEALED-predictions-template.md
- agents/handoffs/templates/SO-template.md
- agents/handoffs/templates/WO-template.md
- agents/journals/INDEX.md
- agents/journals/claude_architect_docs_lead_agent.md
- agents/journals/claude_auditor_agent.md
- agents/journals/claude_dv_lead_agent.md
- agents/journals/claude_rtl_lead_agent.md
- agents/journals/workers/claude_rtl_module_dev_agent.md
- agents/journals/workers/claude_tb_writer_agent.md
- docs/LESSONS.md
- docs/SPONSOR.md
- docs/adr/ADR-0001-org-design.md
- docs/adr/ADR-0002-enforcement-honesty.md
- docs/adr/ADR-0003-ci-authority-and-evidence.md
- docs/adr/ADR-0004-a-seal-is-a-file-not-a-sentence.md
- docs/adr/ADR-0005-journal-volume-chain.md
- docs/adr/ADR-0006-mutation-campaign-discipline.md
- docs/adr/ADR-0007-blinding-regime.md
- docs/gates/G0-checklist.md
- docs/gates/templates/module-ready-checklist.md
- docs/gates/templates/phase-accept-checklist.md
- docs/gates/templates/spec-freeze-checklist.md
- docs/playbooks/ci-evidence.md
- docs/playbooks/mutation-campaign.md
- docs/playbooks/packet-splitting.md
- docs/playbooks/review.md
- docs/reports/audit/.gitkeep
- docs/specs/SPEC-TEMPLATE.md
- scripts/agent_commit.sh
- scripts/check_journals.sh
- scripts/policy.sh
- scripts/test_protocol.sh
- tasks/BOARD.md

---
## [J-orchestrator-0002] 2026-08-13T00:20:00Z | task:none | WO-0001 issued with the RTL deliberately withheld, and the board states what this program has not done

### Trigger
The specification is committed (9d980e1) and the RTL is committed (06c73d3).
The benches that will grade the design can now be commissioned.

### Reasoning
- **The packet withholds `rtl/**` on purpose, and says so in its own text.** The
  design exists and is committed; it is withheld from the assignee, not absent.
  A bench written by a seat that has read the implementation tends to assert
  what the implementation does rather than what the specification requires, and
  a suite built that way is green whether or not the design is correct. This is
  the one separation this program enforces at the session level: the assignee is
  a spawned session with its own context, instructed not to open the directory.
- **Two constraints are carried into the packet because the specification alone
  would not force them.** REQ-011's sweep must be driven by a bench model the
  assignee writes, not by the DUT's own transmitter — a receiver checked against
  its own transmitter shares a time base with its stimulus and can demonstrate
  only self-consistency. REQ-005 must be checked in clock cycles, because a
  check denominated in the design's own tick is satisfied by a design whose tick
  period is wrong.
- **The assignee is instructed that a failing check is a legitimate return**, and
  explicitly told not to adjust an expected value to make a check pass. Without
  that instruction the incentive runs the other way: the seat is graded on
  delivering a suite, and the cheapest green suite is one fitted to the design.

### The board now records three things this program has NOT done
Written down now, while they are true, rather than discovered by a reader later:
- No mutation campaign. Nothing yet establishes these benches would catch a
  defect. A green suite is evidence the design meets the checks written — not
  that the checks are searching for anything.
- No synthesis. Elaboration and simulation only; no vendor tool has seen this
  code, so any area or timing claim is unverified.
- One session wearing several hats. Specification, RTL and orchestration were
  authored in one session under separate seat identities and separate journals.
  Only the benches are written under genuine session-level blinding. Claiming
  the full organizational separation here would be false.

G0 is recorded as compressed rather than as satisfied: the sponsor delegated all
calls to the orchestrator, and branch protection is not configured, so the
append-only journal holds by convention plus CI rather than by server-side rule.

### Files-in-this-commit
- agents/handoffs/WO-0001-uart-lite-benches.md
- tasks/BOARD.md

---
## [J-orchestrator-0003] 2026-08-13T00:35:00Z | task:none | The simulation lane lands blocking, because a suite that is allowed to be red is not a gate

### Trigger
ADR-0008 fixes the toolchain (d16f4f8). CI is the authoritative build
environment under PROTOCOL §10, so the lane is written now rather than after the
benches land, to remove the temptation to shape the lane around a known result.

### Reasoning
- **Blocking from the first day, with no de-gating condition.** The build CI
  template's R-CI-d allows a lane to land non-blocking provided the condition
  for removing the gate is written down at landing. I am not using that
  allowance. A simulation lane that is permitted to be red does not gate
  anything, and the de-gating clause is the mechanism by which a lane stays
  advisory forever. The lane blocks now, before any bench exists to be green.
- Elaboration is a separate step from the suite, so a syntax break and a failing
  assertion are distinguishable in the job log without opening the run.
- Tool versions go to a sidecar artifact and not only the log (R-CI-c): a log is
  rotated and a claim about "which simulator produced this result" outlives it.
- `build/` is .gitignore'd in this same commit rather than in a later one
  (R-CI-e).
- The `journal-check` workflow is untouched. It re-walks the whole history on
  every push, which is the check that cannot be done incrementally.

### Files-in-this-commit
- .github/workflows/sim.yml
- .gitignore
