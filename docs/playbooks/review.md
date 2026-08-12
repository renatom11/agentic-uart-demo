# Playbook — review

How this org grades work: a lead reviewing a worker's return, dv_lead
reviewing a bench, the auditor sampling anything. The verdict form is
[`RV-template.md`](../../agents/handoffs/templates/RV-template.md); this
playbook is the method. Every rule here was paid for once.

## 1. Read the governing REQ first

Before opening the deliverable, read the requirement and spec sections it
claims to satisfy — the packet's **Spec basis** — in their own text. A
review that learns the requirement *from the deliverable* inherits the
deliverable's misreadings. The order is: REQ text → spec section → the work
→ the claim.

## 2. Provenance: measured, derived, or relayed

Every quantity or mechanism claim you accept — and every one you write in
your verdict — carries a provenance class (PROTOCOL §10):

- **measured** — the command is shown, runnable from a checkout;
- **derived** — the derivation is shown, checkable on paper;
- **relayed** — the source is named.

A relay is not a measurement. **A code comment is a relay, not a
derivation** — code claiming its own correctness is the thing under review,
not evidence for it. Verdicts that repeat an unclassified claim launder it.

## 3. Verify against the tree, not the claim

"Untouched files confirmed per git, not per claim": every assertion about
what a change did or did not touch is checked against `git diff` / `git
status` output, not against the return's narrative. The same applies to
line counts, file lists, and "I only changed X" statements — the tree is
the datum; the narrative is the hypothesis.

## 4. Run a guard against the defect it names

When accepting a new check, lint rule, assertion, or self-test, run it
against a reproduction of the defect it was created to catch and watch it
fire. A guard accepted on green-only evidence is decoration: an instrument
must prove it can still fail
([`ci-evidence.md`](ci-evidence.md), self-tests-first).

## 5. Verify a stimulus at both failure sites

When a rule pins an observable at more than one site — two enforcement
points, two alignment cases, a condition with a normal-path and an
error-path consequence — a stimulus claimed to exercise the rule is
verified at **each** site, not verified at one and asserted at the other by
symmetry. Where a suite fails fast, note *which* case actually speaks: a
kill or a pass demonstrates the first failing case, not the whole sweep,
and the review records that bound.

## 6. The repair-vs-fit stop condition

A fix must be **derived from a stated root cause** (the BUG- template
requires the Root-cause section before the fix description). The stop
condition: the moment a proposed repair is being adjusted to make the
observed failure disappear — rather than derived from the named root cause
— stop. You are no longer repairing; you are fitting the artifact to the
test. Bounce with the distinction named. The same condition binds the other
direction: a test amended until the implementation passes is fitting too,
and needs its own spec-based justification.

## 7. Specify the observable

Acceptance criteria, predictions, and defect reports state **what will be
observed** — the message, the count, the cycle, the file — not how the
mechanism will produce it. A criterion grounded in the observable is robust
to mechanism details the author got wrong; a criterion grounded in an
unverified mechanism is not. (This is the same rule that governs sealed
predictions: predict from what the row asserts, not from how you guess the
diff was written.)

## 8. Backtest a proposed rule over the corpus

A proposed new rule — protocol amendment, lint gate, review convention — is
run **backwards over the historical corpus** before adoption: what it would
have flagged, what it would have missed. The corpus verdict goes in the ADR
(PROTOCOL §11). A rule adopted without a backtest is a guess with
enforcement powers.

## 9. Hunk-level staging review before shared-packet commits

Before the orchestrator commits any file that more than one agent has
touched — packet Return logs above all — review the staged diff **at hunk
level** and assign every hunk to an identity. One agent per commit (R1) is
mechanical for scoped agents but attribution inside shared paths is the
orchestrator's judgement, exercised per hunk, before the commit — not
reconstructed after. The split procedure is
[`packet-splitting.md`](packet-splitting.md).

## 10. Verdict hygiene

- Defects are numbered, each with file:line and the clause violated —
  BLOCKING vs REQUIRED vs Nits per the RV- template.
- A verdict that describes bench internals joins the next mutation
  campaign's sealed surface (PROTOCOL §10) — write the verdict knowing it
  may need to be quarantined from a future seeder's allowlist.
- No verdict on evidence that could not execute: a broken harness or
  skipped lane is a **NO-VERDICT** outcome, a distinct class from a
  negative verdict, and never an accept (PROTOCOL §10).
