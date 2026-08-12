# ADR-0004: R-SEAL-1 — a seal is a file, not a sentence

- **Status**: **ACCEPTED (pre-adopted at seeding)** — adopted as part of the
  shell's constitution; provenance below; amendable only via PROTOCOL §11.
- **Deciders**: pre-adopted from the source program's ADR-0016 as accepted —
  proposed by dv_lead, drafted by architect_docs_lead, accepted by the
  orchestrator, countersigned (with one amendment) by dv_lead.
- **Scope**: withheld-result claims in any committed artifact — packet,
  journal entry, verdict, report — and the enforcement class of the rule
  that governs them.

## Context

A claim about a withheld thing is self-certifying in a way no other claim in
this org is: a claim about a test can be run, a claim about a spec can be
read, a claim about a commit can be diffed — a claim about a thing
deliberately not shown can only be believed. The source program paid for
this once: a packet asserted **twice** that its author had performed a sweep
and was withholding the result under seal; the author's own journal repeated
the claim a third time; and when the independent answer came back there was
nothing to open — the commit carrying the claim had staged the packet, the
journal append, and no sweep. The cross-check the packet commissioned did
not happen and could not be manufactured after the fact, and no reader — the
relaying orchestrator, the executing worker, the sampling auditor — had any
artifact to check the claim against. The forgetting was undetectable from
outside. That asymmetry is the defect class, and the repair is structural.

## Decision

1. **R-SEAL-1 is adopted as written in PROTOCOL §10.** The rule text,
   verbatim from the constitution:

   > **R-SEAL-1 — a seal is a file, not a sentence.** A commit may not
   > **introduce** a claim that a result already exists and is being withheld
   > from the reader — a sealed prediction, a sealed sweep, an undisclosed
   > mapping, any "I hold this and am not showing you yet" — unless that same
   > commit also stages the artifact holding the withheld result, so that the
   > seal appears in the commit's own `Files-in-this-commit` list. **A
   > withheld result that is not a committed artefact is not a seal, it is a
   > claim.** Three things it does not reach: a **forward commitment** ("the
   > mapping will be sealed before any diff exists"), which is a promise
   > redeemed by the later commit that freezes the seal — and that commit is
   > bound. An unredeemed promise is not cured by this exclusion: if no
   > commit has staged the seal by the time the result it seals against
   > exists, the round is adjudicated as having no seal — the claim it was
   > supposed to support may not be made, and the absence is a finding. The
   > other two exclusions: a **retrospective reference** to a seal already in
   > history, including quoting a claim in order to convict it; and sealing
   > in the **finalise-a-decision** sense (a countersignature "CLOSED and
   > SEALED"), which withholds nothing. *Enforcement*: **review-enforced**,
   > like the rest of §10 — it is deliberately **not** an `R1`–`R10` commit
   > rule, because distinguishing a claim from a quotation is not a lexical
   > test. The scripts emit an advisory `WARN-SEAL` when a staged holding
   > claim has no `*SEALED*.md` file anywhere in the staged set (env
   > `STRICT_SEALS=1` upgrades the warning to a refusal); a warning is not a
   > verdict and its absence is not a clearance. The rule makes seals
   > countable, not good: a vacuous seal passes it and is caught at
   > adjudication, where a prediction that selects nothing cannot be scored.

   The sentence beginning "An unredeemed promise is not cured by this
   exclusion" is dv_lead's amendment, added at countersignature of the
   source ADR: without it, the forward-commitment exclusion is a hole an
   unredeemed promise walks through — a promised seal that never lands
   would otherwise be neither a violation (it introduced no holding claim)
   nor a finding.

2. **The enforcement class is review-enforced with an advisory `WARN-SEAL`,
   and this is a designed choice, not timidity.** The dispositive measured
   fact from the source corpus: a blocking form of the check fires on the
   very commit carrying the verdict that discovered the missing seal —
   because that verdict *quotes* the claim in order to convict it. There is
   no lexical test that distinguishes a quotation from an assertion, and **a
   gate that cannot tell a confession from a crime must not be a gate**. At
   the measured ~1-in-12 precision, a blocking gate would train its only
   user to route around it. `STRICT_SEALS=1` exists so a blocking trial can
   be run over a range without a new ADR.

3. **The touch-gaming caveat is part of the rule's record.** R-SEAL-1 can be
   satisfied by an empty file; the rule *creates* that incentive, and it is
   named here so its first use is recognized as gaming rather than
   compliance. Deliberately, the rule carries no content requirement: a seal
   exists to be scored, a seal that selects nothing cannot be scored, and
   the scoring round exposes it in front of the one agent who cannot
   pretend otherwise. A content requirement would poison the rule's one
   property — that a path is in a list or it is not — and would make a green
   check look like a quality verdict. The rule makes seals countable, not
   good; anyone reading the check's silence as evidence a seal was worth
   sealing has made the original error one level up.

4. **The corpus backtest is the adoption standard for proposed rules.** The
   source rule as first worded was run backwards over the program's own
   history before adoption: it flagged nine commits, and eight of them were
   correct conduct (closure prose, pre-result rulings, forward commitments,
   scoring after the kill, and the convicting quotation). One word — the
   obligation attaches to the commit that **introduces** the claim, not to
   every commit carrying the file the claim lives in — cleared all eight
   while keeping the incident caught. This method is now constitutional:
   PROTOCOL §11 requires every proposed rule to be run backwards over the
   historical corpus, with the corpus verdict (what it flags, what it
   misses) recorded in the adopting ADR.

## Alternatives considered

Condensed from the source ADR's own alternatives:

- **Adopt the original one-sentence proposal verbatim** ("a packet may not
  assert a sealed prediction unless the seal is a file listed in that same
  commit's `Files-in-this-commit`"). Rejected on the backtest: wrong about
  89% of what it caught, its subject ("a packet") left the journal half of
  the founding incident uncovered, and "sealed prediction" reached the
  founding counterexample — a withheld *sweep* — only by analogy.
- **Make it a blocking commit rule (an R-number).** Rejected: it would be
  the first R-number the script does not truly enforce, or a gate that
  refused the commit that discovered the defect (decision 2).
- **No rule; rely on review.** Rejected: review is exactly what failed — the
  claim was reviewed by its own author three times in one commit and by the
  orchestrator in relay, and no one had an artifact to check.
- **Require the seal's substance duplicated in the journal / require a
  well-formed seal header.** Rejected as rules, kept as practice: both are
  content requirements nothing mechanical can check; the second-copy
  practice answers immutability, not existence, and a well-formedness rule
  would be a successor rule (`R-SEAL-2`) if a stub seal is ever committed.

## Consequences

- Withheld-result claims are non-backdatable relative to themselves: the
  seal is provably at least as old as the sentence asserting it, from one
  commit. The rule does **not** establish that the seal predates what it
  seals against (an SHA-ordering check, the auditor's), nor that the seal
  was never edited later (the journal second-copy practice and diff against
  the freeze commit cover that), nor that the seal is good.
- The auditor gains a cheap sampling handle: claims and seal files are both
  in the diff, and a claim without a file in its own commit is a finding to
  raise rather than an impression to form.
- Roughly one advisory warning per twenty commits, each dismissable by
  reading one quoted line — the recorded cost of catching the one claim no
  reader could check.

## Provenance

Source program, pinned at commit `1799e10a37f19059ac3337982af4b6d035e14d0c`:

- The rule, its four wording repairs, the corpus backtest, the enforcement
  analysis, and the touch-gaming caveat:
  [docs/adr/ADR-0016-a-seal-is-a-file-or-it-is-not-a-seal.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0016-a-seal-is-a-file-or-it-is-not-a-seal.md)
  (§1–§7, §11)
- The founding incident (the withheld-sweep claim asserted twice in the
  packet and twice more in the journal, with no staged artifact):
  [agents/handoffs/WO-0049_cosim-canon-format-fix.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0049_cosim-canon-format-fix.md)
  (§4 and RV-0049-VERDICT §1); `J-dv_lead-0059` (the claim),
  `J-dv_lead-0062` (the proposal), `J-dv_lead-0063` (the countersignature
  carrying the amendment), in
  [agents/journals/claude_dv_lead_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_dv_lead_agent.md)
- Drafting and analysis: `J-architect_docs_lead-0018` in
  [agents/journals/claude_architect_docs_lead_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_architect_docs_lead_agent.md)
