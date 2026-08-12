# ADR-0002: Enforcement honesty — the machine/review boundary, and what a charter may claim

- **Status**: **ACCEPTED (pre-adopted at seeding)** — adopted as part of the
  shell's constitution; provenance below; amendable only via PROTOCOL §11.
- **Deciders**: pre-adopted from the source program's adversarial-review
  round and its subsequent enforcement incidents.
- **Scope**: how this org talks about its own enforcement — which rules are
  machine-refused, which are review-enforced, and what any document is
  allowed to claim about either.

## Context

The source program's credibility rested, by its own account, on one property:
*"charters now claim nothing the scripts don't check without saying which
compensating control applies."* That property was not free. The pre-G0
adversarial review found honesty gaps (a charter claiming a size limit no
script checked; a rule described as machine-enforced that was only
audit-enforced); the first audit found enforcement-semantics changes landed
without tests and self-test scenarios that passed for the wrong rule; and
mid-program, a gate built for data blobs fired on the org's own prose record
and had to be overridden without becoming policy. Every decision below is the
generalization of one of those incidents.

## Decision

1. **The machine/review boundary is named, everywhere.** `R1`–`R10` means
   exactly one thing: *the commit script refuses this*. A rule that scripts
   do not refuse never takes an R-number; it takes a namespaced ID
   (`R-CI-n`, `R-SEAL-n`, …) minted by its ADR **with its enforcement class
   stated in the same sentence**. Adding an unenforced rule to the R-series
   would make every later reader learn which R-numbers are real.
2. **Honesty notes are part of the rule text.** Where a guarantee is partial,
   the constitution says so in place: R1's one-agent-per-commit is emergent
   for scoped agents and audit-enforced for the orchestrator; read bars are
   enforced by prompt + packet content + audit "and honestly documented as
   such" (PROTOCOL §5, §6). A charter or protocol section that claims a
   check nothing performs, without naming the compensating control, is a
   defect of the same severity as the missing check.
3. **A rule is weaker than a tool.** When a rule's failure mode is structural
   — nothing prints the number, nothing runs the check — the repair is an
   instrument, not a restatement of care. And the correction goes **where
   the mistake is, not where the reasoning lives**: a fix recorded only in a
   journal does not protect the file it was made in.
4. **Enforcement changes ship with their proving scenario.** Any change to
   enforcement semantics lands with a `scripts/test_protocol.sh` case
   proving the new behavior (PROTOCOL §5, §11). Rejection tests assert *why*
   a commit was refused, not merely that it was — the source's self-test had
   three scenarios passing for a rule other than the one they named.
5. **The bounded-recorded-override pattern.** A gate that fires on legitimate
   growth gets a bounded, env-parameterized, journal-recorded override with
   a **written end condition** — never a silent threshold change (PROTOCOL
   §5). Discipline of the pattern: each use is counted in the journal; the
   end condition is pinned to a named repair commit or gate, not a date; and
   when the arithmetic says the override will exhaust itself, the correct
   response is to land the repair, not to raise the number again with the
   same argument and less credibility.
6. **Corrections append; they never rewrite.** Paperwork found wrong is
   marked and corrected by an appended, attributed correction — "left in
   place, marked, per the no-silent-rewrite practice" — never silently
   fixed. A correction request that is itself wrong may be refused by the
   record's author, with reasons, in the record.

## Alternatives considered

- **Make everything machine-enforced.** Rejected in the source twice, with
  measurements: prose antecedents ("does this sentence assert a withheld
  result?") are not lexical tests, and a blocking gate at ~1-in-12 precision
  would have refused the very commit that discovered the defect it polices
  (see ADR-0004). Gates that count bytes gate; gates that judge prose warn.
- **Make nothing machine-enforced and rely on review.** Rejected: review is
  exactly what fails when an author believes their own claim. The commit
  machinery exists because content-level honesty cannot be reviewed into
  existence after the fact.
- **Silent threshold bumps for over-firing gates.** Rejected: an incident
  measure that is renewed without a record *is* the policy, unratified. The
  override pattern makes the interim visible, countable, and terminating.
- **Code-fence-aware journal parsers** (source ADR-0002 accepted debt):
  rejected in favor of deliberately simple structural parsers plus a
  documented no-fake-header rule — simplicity of the checker is itself an
  enforcement property.

## Consequences

- Every rule in this shell can be classified in one read: script-refused
  (R-number), review-enforced with a named advisory aid (namespaced ID), or
  audit/narrative (no ID). Ambiguity about enforcement class is a bug.
- The org pays an honesty tax in prose — honesty notes, compensating
  controls, correction footers — and buys the ability to trust its own
  documents at face value.
- Overrides are rare, loud, and self-terminating; the enforcement self-test
  grows monotonically with the rules it proves.

## Provenance

Source program, pinned at commit `1799e10a37f19059ac3337982af4b6d035e14d0c`:

- Honesty corrections and the charter-claim property:
  [docs/adr/ADR-0002-adversarial-review-fixes.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0002-adversarial-review-fixes.md)
  (decision 6 and Consequences), with the blob gate recorded there as
  deferred debt and implemented at `J-orchestrator-0015`.
- Proving-scenario obligation and wrong-reason test fixes:
  [docs/adr/ADR-0003-aud-0001-disposition.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0003-aud-0001-disposition.md)
  (F1, F2), enforced by
  [scripts/test_protocol.sh](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/scripts/test_protocol.sh)
- The R-namespace boundary:
  [docs/adr/ADR-0016-a-seal-is-a-file-or-it-is-not-a-seal.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0016-a-seal-is-a-file-or-it-is-not-a-seal.md)
  (§5, D5: "the R-namespace means *the script refuses this*").
- The blob-gate incident arc (gate fires on the org's own journal; bounded
  override `AGENT_COMMIT_BLOB_MAX=1100000`, uses counted, end condition
  pinned to the repair commit): `J-orchestrator-0137` in
  [agents/journals/claude_orchestrator_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_orchestrator_agent.md);
  resolution in the source's ADR-0017 (see this shell's ADR-0005).
- "A rule is weaker than a tool" and correction placement: `J-dv_lead-0042`
  in [agents/journals/claude_dv_lead_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_dv_lead_agent.md)
- No-silent-rewrite practice: the marked correction footers of source
  ADR-0002/ADR-0003 themselves, and `J-orchestrator-0085`.
