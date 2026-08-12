# ADR-0007: The blinding regime — disclosure, not enforcement

- **Status**: **ACCEPTED (pre-adopted at seeding)** — adopted as part of the
  shell's constitution; provenance below; amendable only via PROTOCOL §11.
- **Deciders**: pre-adopted from the bar-list evolution across the source
  program's four blinded campaigns and its auditor's conduct under them.
- **Scope**: how a seeder is kept blind, what the bars can and cannot
  guarantee, and who owns which call when blindness is imperfect.

## Context

A blinded seeder is what keeps a campaign's informative outcome — a
mutation that reddens the *wrong* row, or none — reachable. The source ran
its blinding on honesty rather than tooling, stated in the first brief and
held ever after: the bar is stated, the blinded party's journal `Inputs`
discloses what it actually read, and "there is no script standing behind
it." The symmetry was named in the same brief: the seeder is to the bench
what the verification lead is to the design under test — "Neither of us is
prevented by a tool — both of us are accountable in the journal." Across
four campaigns the regime held, every breach was self-reported by the
blinded party, and the bar list itself evolved from a growing deny list
into an allowlist. Each decision below is one step of that evolution, with
the incident that forced it.

## Decision

1. **Blinding runs on disclosure, not enforcement.** Bars are stated in the
   brief; compliance is the blinded party's journaled disclosure of what it
   read; the auditor's `Inputs` section is the evidence surface. No script
   stands behind the bars, and the org says so in the brief rather than
   implying a control it does not have (ADR-0002). Prior exposure is
   disclosed and ruled on, not hidden: the brief states what is already
   public, and what is barred is reading it *now*.
2. **Intents are published; the mapping is sealed.** The seeder (and, when
   classes are pre-published, the bench author) receives behavioural defect
   *classes*; what stays sealed is which units redden, which must stay
   green, and the exact failure messages. The source learned this by doing
   it wrong once: publishing a mutation→row kill table to the bench author
   structurally weakened the next campaign before it ran. A brief states
   explicitly which classes were pre-published and which are new and never
   shown.
3. **The readable set is an allowlist, not a deny list.** The deny list grew
   with every packet the campaign lead wrote and had to be swept correctly
   forever; it failed exactly the way that predicts. The rationale of
   record, quoted from the brief that made the change: "That list has grown
   with every packet I write — nine items by the last round — and it
   decays: it must be swept correctly each time, and it failed once
   already"; and: "An allowlist cannot be defeated by a document I forgot
   to enumerate." The standing shape: this packet, the specs, the decision
   record, the design under mutation, the seeder's own tree, and root-level
   build configuration; everything else — the whole bench tree and the
   whole agent-records tree — is out of bounds **by construction rather
   than by enumeration**. Anything needed beyond it is asked for through
   the orchestrator rather than read.
4. **A bar list is a floor, not a proof of blindness.** The seeder discloses
   *ambient* exposure beyond the enumerated bars (shared scratch listings,
   sibling artifacts, path-scoped history), and the call on whether an
   exposure voids a mutation belongs to the campaign lead, not the seeder.
5. **The seeder is a no-stake third party.** The verification lead refuses
   to self-seed (taint would be unrecoverable for unwritten families); the
   auditor — with no stake in the verdict — authors diffs in its own tree,
   the orchestrator applies them, CI executes, and the lead adjudicates.
   Four parties, four different incentives, one result.
6. **Reviewer artifacts are a side channel, by construction.** A review
   verdict that proves its checks by describing bench internals is part of
   the sealed surface for the next campaign — which verdicts need barring
   is checked **when the campaign is designed**, not after. The same holds
   for the lead's journal, scratch files, and commit subjects.
7. **Campaign-adjacent commit subjects are deliberately thin** — on the
   sealed packet and its companion — because a rich subject line is an
   unusually large log surface. Stated as a bar on the seeder, "not as a
   guarantee": thin subjects reduce the channel; the bar on reading it is
   what closes it.
8. **Process bars that earned their place:** all diffs authored before any
   run; no revision after a test result (build-only repair excepted,
   disclosed, and produced by the formatter/toolchain itself, never by
   hand); a private scratch subdirectory; out-of-bounds paths excluded from
   any tree copy at copy time rather than trusting the build to fail first;
   and **no unscoped history commands — a path outside the allowlist is out
   of bounds to every version-control subcommand**, not merely to opening
   the file. The history bar is total rather than flag-scoped because "a
   rule whose safe application depends on per-invocation expertise is a
   rule that will eventually be applied wrong."
9. **Campaign-adjacent subjects and artifacts are kept thin at the source
   too.** Where a document must exist near a campaign (a packet, a verdict,
   an addendum), it is written knowing it may become barred surface —
   observables stated behaviourally, mechanisms left to the party with
   legitimate sight (ADR-0006 decision 11).

## Alternatives considered

- **Mechanically enforced read denial.** Not available in the execution
  environment (no native per-path read denial for a spawned agent), and the
  org's honesty rules forbid pretending otherwise; the disclosure regime is
  the honest version and it measurably held — four campaigns, every breach
  self-reported by the party it burdened.
- **Keeping the deny list and sweeping harder.** Rejected by the failure it
  already produced: the lead's own adjudication put a round's predicted
  kill into a brief the seeder read. A list that must be swept correctly
  forever eventually is not.
- **Sealing the intents too (a fully blind seeder).** Rejected: the seeder
  must author faithful minimal diffs, which requires the defect classes;
  blinding covers what protects the test's meaning — the mapping and the
  messages — not what the seeder needs to do its job.
- **dv self-seeding (no third party).** Rejected at escalation: the
  adjudicator would know the answers, and the taint is unrecoverable for
  every family not yet written.
- **Barring the seeder's history access only for sensitive flags.**
  Rejected for the expertise argument quoted in decision 8 — the bar
  became total rather than clever.

## Consequences

- The org can state exactly what each campaign's blindness protected and
  what was already public — and a campaign run with a disclosed
  imperfection is scoreable, with a discount ruled by the lead, rather
  than void.
- Two recorded costs, kept on the record rather than hidden: "tightening a
  bar can remove the evidence that would discharge a disclosure made under
  it", and thin subjects trade log ergonomics for channel narrowing.
- The regime's load-bearing surprise, worth preserving: the no-stake third
  party **given a floor rather than a ceiling outperformed the
  rule-writer** — the auditor's voluntary refusals (an unscoped history
  command it did not run; ambient exposure it disclosed unprompted) caught
  what the enumerated bars missed, three rounds running.

## Provenance

Source program, pinned at commit `1799e10a37f19059ac3337982af4b6d035e14d0c`
— the §0/§1 evolution across the four blinded campaign briefs:

- [agents/handoffs/WO-0039_m03-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0039_m03-mutation-campaign.md)
  — §0 relay restriction ("There is no script standing behind it"), §1's
  five bars, the symmetry sentence ("you are to M03's bench what I am to
  M03's RTL").
- [agents/handoffs/WO-0041_family-d-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0041_family-d-mutation-campaign.md)
  — the deny list at ten items, task-scoped journal bars with the
  ask-through-the-orchestrator escape, explicit prior-exposure disclosure,
  §0's honest accounting of what was no longer secret (the published
  D-M1..D-M4 row table, from
  [agents/handoffs/WO-0040_tb-m03-family-d-fcs.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0040_tb-m03-family-d-fcs.md)
  §9).
- [agents/handoffs/WO-0045_family-e-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0045_family-e-mutation-campaign.md)
  — §0 first intents-public/mapping-sealed run; §1 the allowlist inversion
  with both rationale quotes; bars 8–10 (private scratch, copy-time
  exclusion, the total history bar).
- [agents/handoffs/WO-0050_family-f-mutation-campaign.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0050_family-f-mutation-campaign.md)
  — the allowlist standing plus root build configuration; §0 naming
  pre-published vs never-shown classes; bar 11's thin-subjects sentence
  ("treat that as a bar on you, not as a guarantee").
- Journal arc: `J-dv_lead-0035` (self-seed refusal), `-0040`
  (verdicts-are-sealed-surface; intents-public proposal), `-0043` (thin
  subjects; the git-bar expertise argument; spec-collision disclosures),
  `-0045`/`-0046` (self-reported subject breach; bar-tightening cost),
  `-0051` (allowlist) in
  [agents/journals/claude_dv_lead_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_dv_lead_agent.md);
  `J-auditor-0004`/`-0005` (ambient-exposure disclosures; bar-list-is-a-
  floor) in
  [agents/journals/claude_auditor_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_auditor_agent.md);
  `J-orchestrator-0111` (the option-C seeding ruling), `-0113` (marker
  duty), `-0115` (bar list relayed verbatim) in
  [agents/journals/claude_orchestrator_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_orchestrator_agent.md).
