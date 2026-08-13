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

---
## [J-orchestrator-0004] 2026-08-13T02:15:00Z | task:none | The suite is green at 609/609 and the module-ready gate is recorded UNSIGNED, because green was never the whole precondition

### Trigger
WO-0001 closed: benches returned (6c8d65c), design defect fixed (27104a8), bench
defects adjudicated (0801a2d), specification amended and a false conclusion
corrected (7923ab8).

### The result
609 checks, 609 pass, 0 fail, `bash test/run.sh` exit 0 under Icarus 12.0. The
largest single check is REQ-011's far-end tolerance sweep: sender bit periods
422 through 447, all 256 byte values at each, 6656 checks, driven by a bench
model the blind seat wrote from the specification rather than by the design's
own transmitter.

### Why the gate is not signed
The board's stated precondition was "the suite green at a stated SHA with every
failure adjudicated". Both hold. I am still recording the module-ready gate as
NOT SIGNED, because that precondition was incomplete when I wrote it and signing
now would be signing to a bar I set before I knew what this round would surface:

- No mutation campaign has run, so nothing establishes in general that these
  benches would catch a defect. There is exactly one real data point — the suite
  caught BUG-0001 on its first execution — and one found defect is not a
  measured detection rate.
- REQ-002 was dischargeable by a defective transmitter until this round, and the
  bench passed it 265/265 against the buggy design. A row that goes green
  against a design known to be wrong is not evidence, and I only know that
  because something made it red.

Both are now on the board as limitations rather than left for a reader to find.

### What this round demonstrates about the framework, stated plainly
A session that could not read the design wrote checks from the specification and
found a real one-line defect in that design on the first run. Nobody planned the
defect and nobody seeded it. That is the blinding regime doing exactly the thing
it exists to do, and it is the single strongest piece of evidence this repository
contains.

The append-only journal did the second thing: J-architect_docs_lead-0003
published a wrong conclusion — that the RTL was correct and the specification
alone was at fault — and it is still there, unedited, with 0004 correcting it.
The wrong turn is the useful part of that record.

The enforcement caught me three times in this session: the genesis commit
carrying another repository's journal history, a missing commit trailer, and an
undeclared set of foreign journal seeds. The one thing it did NOT catch is the
one I had to catch myself — staging my own bench corrections under tb_writer's
name, which would have misrepresented what the blind session produced. No script
can tell whose keystrokes made an edit. That residue belongs on the record.

### Files-in-this-commit
- tasks/BOARD.md

---
## [J-orchestrator-0005] 2026-08-13T02:40:00Z | task:none | The site is generated from the repository and built by CI from a live suite run, so it cannot claim a number the program does not have

### Trigger
Sponsor asked for a website for this program, kept separate from the NIC
program's site.

### Reasoning
- **Nothing on the site is typed by hand.** `site/build.py` reads the commit
  list, the per-commit file sets, the requirement rows, the journal entries and
  the simulation results out of the repository. The lifecycle page's twelve
  steps are the twelve real commits, the files that appear are the files those
  commits actually added, and the seat that lights up is the seat named in the
  commit trailer. A site that restates the program in prose can drift from it;
  one that derives from it cannot.
- **`site/public/` is not committed, and that is the point.** It is
  .gitignore'd and built in CI, which installs the simulator and runs the suite
  before generating the pages. The alternative — committing the built site —
  publishes whatever numbers were true when someone last remembered to rebuild.
  Under PROTOCOL §10 CI is the authoritative build environment, and the figures
  on a page making claims about test results should come from there.
- `build.py` exits non-zero rather than guessing if it cannot parse a suite
  result. A site build that silently published "0 checks" would be worse than a
  failed build.
- The page states what the program has not done, in the same type size as what
  it has: no mutation campaign, no synthesis, only the benches written blind,
  gate unsigned. Those four sentences are on both pages.

### Actions
- `site/build.py`, `site/lifecycle_src.html` (the template the data is spliced
  into), `.github/workflows/pages.yml`, and a .gitignore entry for the output.

### Evidence
- `python3 site/build.py` → "site built · 12 commits · 78 files · 609 checks ·
  17 requirements · 12 journal entries", all read from the repository.
- Both pages render with no console errors in Chromium at 1460px and 900px, in
  light and dark, and neither scrolls horizontally.

### Not yet true
GitHub Pages is not enabled on this repository; that is a sponsor action in the
repository settings (Pages → source: GitHub Actions). Until it is, this workflow
builds and uploads the artifact but has nothing to deploy to.

### Files-in-this-commit
- .github/workflows/pages.yml
- .gitignore
- site/build.py
- site/lifecycle_src.html

---
## [J-orchestrator-0006] 2026-08-13T02:55:00Z | task:none | The pages job enables Pages itself, so publishing needs no click; the build step it failed after had already succeeded

### Trigger
The `pages` workflow failed on its first run at f7712ff. The build step it ran
first did not fail: it printed "site built · 13 commits · 81 files · 609 checks ·
17 requirements · 13 journal entries" after installing the simulator and running
the suite. The failure was `actions/configure-pages@v5` reporting "Get Pages site
failed. Please verify that the repository has Pages enabled".

### Reasoning
The action takes an `enablement` parameter that turns Pages on through the API
using the `pages: write` permission the workflow already requests. Using it
removes the one manual step between a push and a published site. The repository
is already public, so this changes how its existing content is served rather
than what is exposed.

Recorded because the distinction matters when reading the run history: the first
`pages` run is red, and it is red for a configuration reason after the work
succeeded, not because the site failed to build. The `sim` and `journal-check`
lanes were green on the same commit.

### A detail worth noting about the numbers
The CI build reports 13 commits and 13 journal entries where the local build
reported 12 — because CI builds at the commit that adds the site, so the site
includes the commit that created it. The page describes the repository as it
stands at the SHA it was built from, which is the property I wanted.

### Files-in-this-commit
- .github/workflows/pages.yml

---
## [J-orchestrator-0007] 2026-08-13T03:20:00Z | task:none | The lifecycle page is rebuilt to the NIC program's treatment, with the twelve beats replaced by the fourteen real commits

### Trigger
Sponsor compared the demo's lifecycle page against the NIC program's and said it
should be exactly like that one: the org tree with its reporting lines, the
repository as artifact boxes with live counts, the gate and CI rails, phases on
the scrubber, the legend, and the annotation rail.

### Reasoning
- **Rebuilt rather than copied.** The NIC page's source is not reachable from
  this machine: its commits are absent from the checkout available here, no copy
  survives on disk, and the deployed page cannot be fetched — the sandbox proxy
  refuses both the site and the Pages API. So the treatment was rebuilt from the
  design rather than ported. Recorded because "the same as the other one" is a
  claim a later reader might check.
- **The beats are the commits.** The NIC page animated a scripted story. This one
  has no script: each beat is a real commit, its title is that commit's subject,
  its annotation is the first sentences of the journal entry its author wrote,
  its token flies from the seat named in the commit's own trailer to the groups
  that commit actually touched, and the artifact counts are the files it really
  added. There is nothing on the page to keep in sync with the program, because
  the page is generated from it.
- The blind seat is drawn differently on purpose — dashed, in the audit colour —
  because it is the one seat whose separation this program actually enforced at
  the session level, and the page should not flatter the rest.

### A defect caught by running it rather than by reading it
The first build produced a page that threw `Cannot read properties of undefined
(reading 'forEach')` on every frame: the generator computed each beat's token
list and then never put it in the beat. The page still rendered statically and
every click target still worked, so a screenshot looked correct — only pressing
play exposed it. The harness now asserts the scrubber advances after a play
click, which is what caught it.

### Files-in-this-commit
- site/build.py
- site/lifecycle_src.html
