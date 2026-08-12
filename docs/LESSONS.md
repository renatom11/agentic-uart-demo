# LESSONS — the operating record this shell was distilled from

**Nothing here is normative.** Each entry names its normative home
(PROTOCOL §, ADR-000N of this shell, or a playbook) or says "narrative
only". Citations are permalinks into the public
[agentic-fpga program](https://github.com/renatom11/agentic-fpga), pinned at
commit `1799e10a37f19059ac3337982af4b6d035e14d0c` (the seeding pin; one
source document landed past the pin and is cited at its landing commit,
noted where it occurs). Journal entry IDs (`J-<agent>-NNNN`) locate entries
inside the linked journals.

Playbook references point at the four planned playbooks —
`docs/playbooks/mutation-campaign.md`, `docs/playbooks/review.md`,
`docs/playbooks/packet-splitting.md`, `docs/playbooks/ci-evidence.md` — not
yet created; that is expected.

Sections: **A** commit & journal discipline · **B** review discipline ·
**C** campaign & blinding discipline · **D** CI & evidence discipline ·
**E** communication & relay discipline · **F** org-topology lessons.

---

## A. Commit & journal discipline

### L-A01 — Stage a shared packet on notification, after hunk-level review
**Rule.** A shared packet is staged only after the responsible agent's
completion notification — never on the packet's RETURNED stamp — and only
after a hunk-by-hunk diff against HEAD confirms every hunk belongs to the
committing agent; known-concurrent actors on one packet are serialized.
**Incident.** Commit `6181781` swept dv's in-flight countersignature block
into a data_wrangler-attributed commit; R4 passed because content-level
authorship isn't machine-checked, and a `tail -2` glance had stood in for
review. A separate staging race nearly committed a packet before a late
Return-log fragment landed.
**Now lives in.** docs/playbooks/packet-splitting.md (planned).
**Provenance.** [J-orch] `J-orchestrator-0125`, `J-orchestrator-0052`.

### L-A02 — One lead at a time per journal
**Rule.** Only one spawn of a given lead is active at a time ("one dv
sitting at a time keeps its journal serial and its independence clean"),
and parallel lanes run only on disjoint paths with disjoint journals.
**Incident.** Adopted as standing orchestration practice early and
reaffirmed late; the serial journal is what makes R3/R5 attribution and the
one-entry-per-commit invariant workable.
**Now lives in.** docs/playbooks/packet-splitting.md (planned).
**Provenance.** [J-orch] `J-orchestrator-0084`, reaffirmed
`J-orchestrator-0127`.

### L-A03 — The split-commit procedure for two agents' uncommitted layers
**Rule.** A packet carrying two agents' uncommitted layers is committed by
reconstructing the earlier worker-era intermediate, verifying the later
layer is a pure insertion against HEAD, and committing each layer under its
own identity.
**Incident.** First worked out during the first bench round's
bounce-and-fix arc and reused for three later packets; it is the honest
alternative to attributing one agent's words to another.
**Now lives in.** docs/playbooks/packet-splitting.md (planned).
**Provenance.** [J-orch] `J-orchestrator-0104`, `J-orchestrator-0127`;
[WO-0038] (the arc).

### L-A04 — Corrections append; they never rewrite
**Rule.** A paperwork inconsistency is corrected by an appended, attributed
correction ("marked, not rewritten") — and a correction request that is
itself wrong may be refused by the record's author, with reasons, on the
record.
**Incident.** A header/state double-match and an audit tally error were
both left in place and marked. Separately, the orchestrator asked dv to
"correct" an entry after misreading a journal mid-append — the flag was
false, and dv refused it and said why; the refusal is part of the record.
**Now lives in.** ADR-0002 (decision 6); PROTOCOL §4 (append-only).
**Provenance.** [J-orch] `J-orchestrator-0085`, `J-orchestrator-0063` →
`-0064`; [ADR-0002-src] (correction footer); [J-dv] `J-dv_lead-0042`.

### L-A05 — Anchor a state flip on title + state, never on a bare state line
**Rule.** A scripted packet header/state flip matches on title plus state,
because a bare `- **State**: ISSUED` line also matches Return-log quotations
of it.
**Incident.** The flip script's FAIL 2: an ISSUED header sat under an
ACCEPTED block because the pattern matched the wrong occurrence.
**Now lives in.** docs/playbooks/packet-splitting.md (planned).
**Provenance.** [J-orch] `J-orchestrator-0085`.

### L-A06 — Journal-only commits are a first-class class
**Rule.** An incident goes on the record immediately as a journal-only
commit (`- (none)` files list, `Journal-Only: true` trailer) while lanes
keep working — the record does not wait for the next work commit.
**Incident.** First used to put a spawn kill on the record mid-flight;
ubiquitous thereafter.
**Now lives in.** PROTOCOL §5 (R2).
**Provenance.** [J-orch] `J-orchestrator-0063` onward.

### L-A07 — Commit order is the ordering evidence; header timestamps are not
**Rule.** Journal header timestamps are not evidence of ordering; commit
order is, and ordering claims are audited from SHAs.
**Incident.** dv's journal header dates drifted weeks ahead of the real
date while committing normally; nothing in the enforcement machinery reads
the header date, and an auditor who did would have been misled.
**Now lives in.** PROTOCOL §9 (Ordering).
**Provenance.** [J-dv] `J-dv_lead-0062`.

### L-A08 — Incremental writes for large spawns
**Rule.** A spawn producing large artifacts writes incrementally — small
writes plus edits, one module fully on disk before the next — so an
output-token cap kills at a module boundary, not mid-file.
**Incident.** The first RTL-lead spawn was killed by the 64,000-output-token
cap with work stranded in the transcript; the respawn instruction carried
the incremental-write discipline and it held thereafter.
**Now lives in.** Narrative only.
**Provenance.** [J-orch] `J-orchestrator-0063`; [J-rtl] `J-rtl_lead-0002`.

### L-A09 — The blob gate
**Rule.** No staged file exceeds the blob threshold; large data ships as a
fetch script plus checksum manifest, never as a committed blob.
**Incident.** The pre-G0 review flagged the honesty gap (a charter claimed a
size limit no script checked — COH-8); the gate was implemented with its
proving scenarios rather than left as a claim.
**Now lives in.** PROTOCOL §5 (blob gate).
**Provenance.** [ADR-0002-src] (§6, deferred debt); implemented at [J-orch]
`J-orchestrator-0015`; [agent-commit].

### L-A10 — The bounded, recorded, end-conditioned override
**Rule.** A gate that fires on legitimate growth gets a bounded,
journal-recorded override with a written end condition — never a policy
change by silent threshold bump — and each use is counted.
**Incident.** dv's journal hit 1,013,298 bytes and the blob gate blocked
every future dv commit; the response was `AGENT_COMMIT_BLOB_MAX=1100000`
scoped to dv's commits, uses counted in the journal, end condition pinned
to the rotation fix, and an ADR routed to the architect.
**Now lives in.** PROTOCOL §5 (blob gate paragraph); ADR-0002 (decision 5);
ADR-0005.
**Provenance.** [J-orch] `J-orchestrator-0137` (recorded at the seeding pin
itself); [ADR-0017-src] §1, §7 (landed past the seeding pin; cited at its
landing commit).

### L-A11 — Enforcement changes ship with their proving scenario
**Rule.** Any change to enforcement semantics lands with a
`test_protocol.sh` case proving the new behavior, and rejection tests
assert the refusal reason.
**Incident.** The first audit found semantics changed with no test (F2) and
three self-test scenarios passing for a rule other than the one they named
(F1); the suite has grown with every enforcement change since.
**Now lives in.** PROTOCOL §5 and §11(3); ADR-0002 (decision 4).
**Provenance.** [AUD-0001] via [ADR-0003-src] (F1, F2); [J-orch]
`J-orchestrator-0015`; [test-protocol].

## B. Review discipline

### L-B01 — Every claim carries a provenance class
**Rule.** Any quantity or mechanism claim in a verdict, freeze, or packet is
**measured** (the command shown), **derived** (the derivation shown), or
**relayed** (the source named) — a relay is not a measurement, and a code
comment is a relay, not a derivation.
**Incident.** "Fifteen units" originated in an orchestrator relay nobody had
counted, was re-signed by dv, then ordered as an "eighteen unit" freeze;
the real count was 12. Later, dv routed a worker around a trap in a way
that could not work because it reasoned from a comment instead of following
one call — "three-for-three against me".
**Now lives in.** PROTOCOL §10 (evidence rules).
**Provenance.** [J-dv] `J-dv_lead-0042` (verbatim block), `J-dv_lead-0058`,
`-0059`; [WO-0047] §6.9; [J-orch] `J-orchestrator-0115`.

### L-B02 — A rule is weaker than a tool; fix the file, not the journal
**Rule.** Where a rule's failure is structural (nothing prints the number),
build the instrument — and put the correction where the mistake is, not
where the reasoning lives, because a fix recorded only in a journal does
not protect the file it was made in.
**Incident.** dv reintroduced a counting bug in the very file where it had
fixed that bug one work order earlier; the journal knew, the file did not.
Named as the fourth instance of the same lesson.
**Now lives in.** ADR-0002 (decision 3); docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0042`.

### L-B03 — Verify against the tree, not the Return log's account of it
**Rule.** A reviewer verifies confinement and content against the diffs and
the tree, never against the Return log's description of them ("untouched
files confirmed per git, not per claim").
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0016`, `J-dv_lead-0024`.

### L-B04 — Prove a check against its target before relying on it
**Rule.** A guard is run against the defect it names before it ships, and a
stimulus is verified at both failure sites — its own construction, and
whether the bench actually drove it.
**Incident.** A guard dv prescribed to catch a reversed-schedule defect
turned out not to catch it, established by running dv's own text against
the original bug. Separately, a driven-word check caught an unwired hook
that the stimulus-side check could not — a gap in dv's own packet, closed
by the worker's instinct.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0028`, `J-dv_lead-0050`; [WO-0047] §6.7.

### L-B05 — A verbatim fix instruction owns the prose it falsifies
**Rule.** A verbatim fix instruction carries the obligation to repair any
prose the fix falsifies, as a standing rule, so scope is not re-litigated
per round.
**Incident.** A round-3 docstring deviation was ruled in scope on exactly
this ground.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0026`.

### L-B06 — Trace a change against the code it will run beside
**Rule.** A prescribed change is traced against the code it will actually
run beside before it is prescribed.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [WO-0047] §6.8; [J-dv] `J-dv_lead-0023` era.

### L-B07 — A repair that moves an observation point moves nothing else
**Rule.** When a repair moves an observation position, check that no
constant moved alongside it — otherwise a repair and a fit are
indistinguishable.
**Incident.** The round-6 sampling-edge shift was accepted only after
verifying every expected constant stayed put.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0033`.

### L-B08 — Promotions pass conformance review, and poison never promotes
**Rule.** No promotion enters the tree without the verification lead's
conformance review — a round that fills an existing expectation block is
routing around that rule — and a promotion payload carrying a crash or
uncaught error is held out of the tree, never adopted as an expectation.
**Incident.** During a bench/design disagreement round, promoted sources
carried uncaught-exception text; the standing rule kept them from ever
becoming expectations.
**Now lives in.** docs/playbooks/review.md (planned); ADR-0003 (decision 2).
**Provenance.** [J-dv] `J-dv_lead-0033`; [J-orch] `J-orchestrator-0106`.

### L-B09 — A committed model-vs-hand tripwire has three duties
**Rule.** A tripwire comparing a model against hand-computed values may live
in a committed test only if it raises (not prints), names its finding
class, and routes to the verification lead with an explicit bar on adopting
either side.
**Incident.** The third use of the idiom, in family E, was accepted on
exactly those three conditions; anything less converts a disagreement
detector into a silent tie-breaker.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0050`.

### L-B10 — The bench-surface budget bounds exports, not helpers
**Rule.** The bench's exported surface is budgeted; a row's own helpers are
not — and a worker who believes an export is needed returns the question
rather than adding it.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0050` (precedent); [WO-0047] §4.3.

### L-B11 — A convention retrofit is a change, stated and re-run
**Rule.** Where two valid conventions coexist, a retrofit to the newer one
is paired with a re-run and stated as a change — never folded quietly into
another packet's diff.
**Incident.** Two strobe-window conventions coexisted across three
mutation-qualified files; the ruling forbade a quiet harmonization inside
an unrelated diff.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0058` (ruling 2).

### L-B12 — Read the governing requirement before designing the artifact
**Rule.** The governing requirement is read before a verification artifact
is designed against it ("a rule I keep needing and keep relearning").
**Incident.** A comparison-domain draft reinvented four clauses of the
governing requirement and broke a fifth.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0052`.

### L-B13 — Precedent searches are scoped, and taint is recorded, not waved
**Rule.** A precedent search scopes to the tree it is about, and an exposure
it reveals is recorded as a taint against the affected module — binding on
future work — rather than waved off.
**Incident.** A precedent grep printed two lines of another module's
internals; no taint attached to the module under review, and a recorded
taint attached to the other, binding on any future sign-off for it.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0024`; [J-orch] `J-orchestrator-0104`.

### L-B14 — Commit the bounce as-is
**Rule.** A bounced return is committed as-is, so the bounce-and-fix arc
lives in the diff rather than being tidied out of history.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-orch] `J-orchestrator-0100`; [WO-0038] (RV-0038 BOUNCE).

### L-B15 — A proposed rule is backtested over the corpus before adoption
**Rule.** A rule proposed for adoption is run backwards over the historical
corpus first, and the corpus verdict (what it flags, what it misses) goes
in the adopting ADR.
**Incident.** dv's seal rule as first worded flagged nine commits in
history and was wrong about eight — including the verdict that discovered
the defect the rule exists to prevent. One word changed; all eight cleared;
the incident stayed caught.
**Now lives in.** PROTOCOL §11; ADR-0004 (decision 4).
**Provenance.** [J-arch] `J-architect_docs_lead-0018`; [ADR-0016-src] §2.1.

## C. Campaign & blinding discipline

### L-C01 — Freeze first, in a separate sealed companion, with three-way predictions
**Rule.** The campaign freeze — brief plus SEALED predictions companion
classifying every scoring cell REQUIRED / MUST-STAY-GREEN / PERMITTED — is
committed before any defect exists, and the seeder is spawned only
afterwards.
**Incident.** Predictions live in a separate sealed file, not a sealed
annex, because "a bar you can trip over by opening a file is not a bar". A
flat kill list scores every monitor surprise as a prediction failure and
gets quietly widened after the fact; committed MUST-STAY-GREEN is what
makes the test two-sided.
**Now lives in.** PROTOCOL §10 (mutation discipline); ADR-0006
(decisions 1–2).
**Provenance.** [J-dv] `J-dv_lead-0035`; [WO-0039] §0/§4/§5/§6.

### L-C02 — Mutant branch hygiene
**Rule.** Each mutant is known-green parent SHA plus exactly one diff, on a
throwaway never-merged branch carrying a greppable marker, and the frozen
base SHA is re-confirmed green at the campaign's first and last runs.
**Incident.** Remote branch deletion was refused by the push proxy, so the
markers plus an auditor marker-check duty became the cleanup guarantee —
the drift insurance held across all five campaigns.
**Now lives in.** PROTOCOL §10; ADR-0006 (decision 4).
**Provenance.** [WO-0039] §4; [J-orch] `J-orchestrator-0113`.

### L-C03 — Kills count in named rows with named messages, because messages discriminate
**Rule.** A kill counts only in the named rows with the named message — a
right row with the wrong message is a finding, not a pass — because row
sets do not discriminate between defects; messages do.
**Incident.** Three family-D mutants shared one row set and were separated
only by which assertion spoke; sealing messages is what bought the
discrimination, confirmed a third time in family E.
**Now lives in.** PROTOCOL §10; ADR-0006 (decisions 5–6).
**Provenance.** [WO-0039] §6; [J-dv] `J-dv_lead-0044`, `J-dv_lead-0054` §3.

### L-C04 — Results are relayed verbatim, and a green run is relayed prominently
**Rule.** Campaign results are relayed as verbatim test-runner output
including the name of every failing unit ("a paraphrase destroys it"), and
a green run is relayed prominently because a survived mutation is the
campaign's most important possible result.
**Incident.** The rationale of record: "a green run here is
indistinguishable from a suite that never executed a single check."
**Now lives in.** ADR-0006 (decision 5); PROTOCOL §3 (relay classes).
**Provenance.** [WO-0039] §5.4, §7; [J-dv] `J-dv_lead-0034`.

### L-C05 — A sealed prediction is never edited — after its result or before it
**Rule.** A freeze is never edited after its result (a falsified sealed
prediction stays as written and dies on the record), and a seal reasoning
from what a row asserts beats a correction reasoning from a second-hand
mechanism — verify the detail first or leave the prediction alone.
**Incident.** A pre-result ruling replaced a right prediction with a wrong
one ("more analysis made the answer worse"), compounded by iteration-order
blindness inside the very ruling that named assertion-order blindness. The
falsified text stayed in the freeze, as had a falsified prediction one
campaign earlier — "the fourth time that rule has bound me".
**Now lives in.** ADR-0006 (decision 7).
**Provenance.** [J-dv] `J-dv_lead-0044`, `J-dv_lead-0054`; [J-orch]
`J-orchestrator-0121`.

### L-C06 — An equivalent-mutant claim is a proof obligation
**Rule.** Equivalence is proven over the whole legal stimulus space — down
to the spec's floors, not the bench's habits — never conceded from the
suite's failure to kill.
**Incident.** D-M3 survived; dv computed the margin over every terminate
lane, start lane, length, and gap down to the spec's floor of 9 rather
than the benched 12, and recorded "EQUIVALENT MUTANT. Proven, not
conceded."
**Now lives in.** PROTOCOL §10; ADR-0006 (decision 9).
**Provenance.** [J-dv] `J-dv_lead-0044` §3; [WO-0041].

### L-C07 — Every qualification owes a silently-always-pass mutation
**Rule.** Each qualification seeds at least one mutation that makes the
design silently agree with every existing assertion — the class whose
symptom is a green suite that checks nothing.
**Incident.** A requirement's positive direction was unverified: a design
hardwiring the verdict *good* passed all fifteen tests. The class became
"the standing rule now owed to every qualification".
**Now lives in.** PROTOCOL §10; ADR-0006 (decision 8).
**Provenance.** [J-dv] `J-dv_lead-0037`; [J-orch] `J-orchestrator-0113`.

### L-C08 — The denominator never moves mid-campaign
**Rule.** No row, unit, or bench edit lands between a freeze and its
scoring; the denominator is measured at freeze and stays fixed.
**Incident.** The "eighteen units" that did not exist, and a later
"nineteen" corrected by the tool built to stop exactly that; honoured in
practice when a new row was scored first and added second.
**Now lives in.** PROTOCOL §10; ADR-0006 (decision 3).
**Provenance.** [J-dv] `J-dv_lead-0053`, `J-dv_lead-0054`,
`J-dv_lead-0061`.

### L-C09 — Assertion order and iteration order are part of the contract
**Rule.** Before sealing a message, read every unit's assertion order and
iteration order — fail-fast loops mean only the first case speaks — and
order assertions deliberately (structural first, specific after),
announcing any reorder prominently.
**Incident.** A sealed message was unreachable: the unit asserted word
count before delivered octets and iterated ascending, so the sealed text
could never be the one that spoke.
**Now lives in.** ADR-0006 (decision 6); docs/playbooks/mutation-campaign.md
(planned).
**Provenance.** [J-dv] `J-dv_lead-0053`; [WO-0047] §4.2.

### L-C10 — The reviewer's artifacts are sealed surface for the next campaign
**Rule.** A review verdict that describes bench internals, the lead's
scratch files, and campaign-adjacent commit subjects are all part of the
next campaign's sealed surface — checked when the campaign is designed,
not after — and campaign-adjacent subjects are kept deliberately thin.
**Incident.** A verdict described a bench file's internals line by line; a
commit subject named the prediction matrix's dimensions; a later subject
carried the campaign score and was caught only by the auditor's voluntary
refusal to run an unscoped `git log`. dv: "my rules keep arriving one
commit late."
**Now lives in.** PROTOCOL §10 (information hygiene); ADR-0007
(decisions 6–7).
**Provenance.** [J-dv] `J-dv_lead-0040`, `J-dv_lead-0043`,
`J-dv_lead-0045`/`-0046`; [WO-0050] §1 (bar 11).

### L-C11 — Publish intents; seal the mapping
**Rule.** Mutation intents (defect classes) are published to the party that
must build against them; the row mapping, the must-stay-green set, and the
exact messages stay sealed.
**Incident.** One brief published the mutation→row kill table to the bench
author, structurally weakening the next campaign before it ran; the
corrected protocol ("intents-public / mapping-sealed") held across the two
campaigns that followed.
**Now lives in.** ADR-0007 (decision 2).
**Provenance.** [J-dv] `J-dv_lead-0040` (proposal); [WO-0040] §9 (the
leak); [WO-0045] §0 (first run); [WO-0050] §0 ("has now held across two
campaigns").

### L-C12 — An intent is never a licence to break a second rule
**Rule.** When a spec rule collides with a mutation intent, the seeder
preserves the spec rule and discloses the collision.
**Incident.** Two auditor resolutions of ambiguous intents, both
spec-faithful and disclosed; the clause "earned its place three times" and
became standing text in the last two briefs.
**Now lives in.** ADR-0006 (decision 11).
**Provenance.** [J-dv] `J-dv_lead-0043`; [WO-0045] §2; [WO-0050] §2.

### L-C13 — A kills cell names a defect, or the row was not thought about
**Rule.** Every attack-plan row states what defect kills it; "a row whose
kill is 'a broken design' is a row that was not thought about".
**Now lives in.** ADR-0001 (decision 6);
docs/playbooks/mutation-campaign.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0013`; [J-orch] `J-orchestrator-0066`.

### L-C14 — Snapshot drift is not a unit
**Rule.** Snapshot/determinism drift is never scored as an unnamed-unit
finding and never harvested as an expectation.
**Incident.** A mutant survived the suite and failed only at determinism on
its own snapshot drift; scoring that as a kill would credit the bench with
teeth it does not have.
**Now lives in.** ADR-0006 (decision 10).
**Provenance.** [J-dv] `J-dv_lead-0046`; [WO-0042] (the mini-round it
bound).

### L-C15 — A bar list is a floor
**Rule.** The seeder discloses ambient exposure beyond the enumerated bars,
and the call on whether an exposure voids a mutation is the campaign
lead's, not the seeder's.
**Incident.** A shared scratchpad listing showed other agents' copies of
barred artifacts, and one path-scoped history command touched a barred
path; the auditor disclosed both unprompted and dv made the void calls.
**Now lives in.** PROTOCOL §10; ADR-0007 (decision 4).
**Provenance.** [J-aud] `J-auditor-0004`, `J-auditor-0005`.

### L-C16 — The seeder is a no-stake third party
**Rule.** The verification lead never self-seeds; seeding goes to a
third party with no stake in the verdict, authoring diffs in its own tree,
with the orchestrator applying, CI executing, and the lead adjudicating.
**Incident.** dv escalated its own conflict: self-seeded taint would be
unrecoverable for the families not yet written. The ruling chose the
auditor as seeder, and the four-party split held for all five campaigns.
**Now lives in.** PROTOCOL §10; ADR-0007 (decision 5).
**Provenance.** [J-dv] `J-dv_lead-0035`; [J-orch] `J-orchestrator-0111`.

### L-C17 — The readable set is an allowlist
**Rule.** The seeder's readable paths are an allowlist stated in the brief;
everything else is out of bounds by construction, and anything needed
beyond it is asked for through the orchestrator rather than read.
**Incident.** The deny list had grown to ten items and "it failed once
already", when dv's own adjudication put a round's predicted kill into a
brief the seeder read. The inversion's rationale of record: "An allowlist
cannot be defeated by a document I forgot to enumerate."
**Now lives in.** ADR-0007 (decision 3); PROTOCOL §10.
**Provenance.** [WO-0045] §1; [J-dv] `J-dv_lead-0051`; [WO-0050] §1
(standing, plus root build configuration).

### L-C18 — Blinding's costs are recorded, not hidden
**Rule.** A regime change records what it costs: tightening a bar can
remove the evidence that would discharge a disclosure made under it, and a
rule whose safe application depends on per-invocation expertise will
eventually be applied wrong — so such rules are made total instead of
clever.
**Incident.** Both sentences are the source's own, recorded when the
history bar became total rather than flag-scoped and when a tightened bar
stranded a disclosure.
**Now lives in.** ADR-0007 (decision 8, Consequences).
**Provenance.** [J-dv] `J-dv_lead-0046`, `J-dv_lead-0043`.

## D. CI & evidence discipline

### L-D01 — CI is the authoritative build environment, and its diff is the only promotion source
**Rule.** No gate signature or sign-off rests on a local build result;
evidence cites a CI run ID and conclusion, and machine-produced
expectations are promoted from CI's own diff output, never authored by
hand.
**Incident.** The source's container could not install its toolchain, so
the constraint was ruled into a regime: "writing a plausible-looking
waveform into an expect block would be fabricated evidence — the one thing
the journal protocol exists to prevent."
**Now lives in.** PROTOCOL §10 (evidence rules); ADR-0003 (decisions 1–2).
**Provenance.** [ADR-0005-src] (Decision, rules 1–2).

### L-D02 — The promotion-block pattern
**Rule.** When a run's diff is the promotion source, CI emits a checksum
plus a compact re-creatable encoding of every staged path **after** the
diff (so it sits at the log tail inside any bounded fetch window), and
evidence-producing steps run before any checker that could suppress them.
**Incident.** A log fetch capped at 5,000 lines against an ~11k-line diff
while the raw-log URL was blocked by egress policy — the promotion source
was unretrievable; separately, a checker failure before the promotion step
suppressed the diff that *is* the promotion source.
**Now lives in.** ADR-0003 (decision 3); docs/playbooks/ci-evidence.md
(planned).
**Provenance.** [J-orch] `J-orchestrator-0067`, `-0068`, `-0079`, `-0080`.

### L-D03 — Post-processing output to satisfy a checker is fabricating conformance
**Rule.** Generated output is never post-processed to satisfy a checker;
the honest repairs are a checker fix and a workflow fix.
**Incident.** A checker false-FAIL invited a "fix" that would have rewritten
the emitted artifact to pass; the implementation lead refused and named it,
and the orchestrator accepted the checker/workflow repairs instead.
**Now lives in.** ADR-0003 (Alternatives); docs/playbooks/ci-evidence.md
(planned).
**Provenance.** [J-rtl] `J-rtl_lead-0004`; [J-orch] `J-orchestrator-0067`.

### L-D04 — NO-VERDICT is a class of its own
**Rule.** A skipped, absent, or failed-to-install verification lane is
never a PASS, and a broken harness is never reportable as an anchor
finding — exit classes partition along *did the lane reach a verdict?*,
run summaries distinguish *ran and agreed* from *did not run*, and no
sign-off cites a run in which the lane did not execute.
**Incident.** The differential lane's run 1 exited DIFFERENTIAL for a
canonical-format rejection when no comparison had occurred; the repair
added a distinct NO-VERDICT exit class, also fixing an exit-code collision
with the language runtime's own failure code.
**Now lives in.** PROTOCOL §10; ADR-0003 (decision 4).
**Provenance.** [ADR-0015-src] D1 ("the rule that matters most"); [J-dv]
`J-dv_lead-0059`; [WO-0049] §8; [J-dw] `J-data_wrangler-0003`;
[run_cosim].

### L-D05 — Producers conform to the grammar
**Rule.** A comparator's fail-closed reader is never relaxed to accommodate
a producer: producers conform to the grammar; the grammar does not
accommodate producers.
**Incident.** Had the reader normalised a malformed field, the anchor lane
would have issued its first agreement on machinery that was not working.
**Now lives in.** ADR-0003 (decision 5).
**Provenance.** [J-dv] `J-dv_lead-0059`.

### L-D06 — Standing requirements on any new CI lane
**Rule.** A new lane lands as a separate job, installs from the
distribution archive, records tool versions into the run artifact (not
only the log), carries a written de-gating condition if it lands
non-blocking, writes artifacts outside the checkout, uploads failure
evidence (stimulus, both outputs, the diff), and triggers on push — "a
lane that runs on a schedule produces failures attributable to no commit."
**Incident.** The source's R-CI-4 (de-gating) was written at landing and
discharged much later — the written condition is what kept a non-blocking
lane from becoming decoration.
**Now lives in.** ADR-0003 (decisions 6–7).
**Provenance.** [ADR-0015-src] (D1 requirements table); [J-orch]
`J-orchestrator-0136`, `J-orchestrator-0127`; [J-dv] `J-dv_lead-0062`.

### L-D07 — Vendored third-party source is inviolate
**Rule.** Vendored third-party source is never edited in place
(configuration is a parameter, not a patch — a modified file bearing an
upstream SHA is a false provenance record), pin bumps land as their own
commit, and adding a reference tool does not enlarge what any existing
requirement means.
**Now lives in.** PROTOCOL §10 (licensing); docs/playbooks/ci-evidence.md
(planned).
**Provenance.** [ADR-0015-src] (D2, D3).

### L-D08 — A seal is a file, not a sentence, and its check is advisory
**Rule.** A commit may not introduce a withheld-result claim unless it
stages the artifact holding the withheld result — and the mechanical aid
stays an advisory warning, because distinguishing a claim from a quotation
is not a lexical test and "a gate that cannot tell a confession from a
crime must not be a gate".
**Incident.** A packet asserted a sealed sweep twice; it was never
committed, so the commissioned cross-check did not happen and could not be
manufactured after the fact. The proposed blocking check would have
refused the very commit carrying the verdict that discovered the defect,
at ~1-in-12 precision.
**Now lives in.** PROTOCOL §10 (R-SEAL-1) and §3 (withheld results);
ADR-0004.
**Provenance.** [ADR-0016-src] §2.5, §3, §5, §6.3; [WO-0049] §4; [J-dv]
`J-dv_lead-0062`, `-0063`.

### L-D09 — Evidence cites what a checkout can verify
**Rule.** Evidence cites (a) commands runnable from a repo checkout or
(b) externally verifiable references (run ID + conclusion), and any
mention of an ephemeral artifact says so explicitly.
**Incident.** Journal Evidence cited scratch artifacts unreachable from the
repo (audit finding F5); the auditor later noted "F5's standing rule is
nowhere an agent must read", and the rule was promoted into the protocol's
mandatory-reading path.
**Now lives in.** PROTOCOL §4.1 (Evidence).
**Provenance.** [ADR-0003-src] (F5, Corrections); [J-aud]
`J-auditor-0003`.

### L-D10 — A sign-off cites a run, and a check that stood down said nothing
**Rule.** A sign-off cites a run, not a script — and SKIPPED /
OBLIGATION-OPEN outcomes never count as coverage; the harness refuses to
print OK over a stood-down check.
**Incident.** An external anchor stayed open across twelve fetch attempts;
when evidence finally arrived it convicted the claim before confirming the
repair — "zero fabrications". The check harness's own contract enforces
the second half.
**Now lives in.** docs/playbooks/ci-evidence.md (planned); PROTOCOL §10
(no-verdict class).
**Provenance.** [rfc-anchor]; [J-orch] `J-orchestrator-0092`; [dv_checks]
(header and `run_and_label()`).

### L-D11 — Self-tests first: an instrument must prove it can still fail
**Rule.** Every instrument that judges a committed artifact proves it can
still fail before it is allowed to say anything passed — "a rule whose
teeth are never exercised can be blunted by a well-meaning simplification
without anything going red."
**Now lives in.** docs/playbooks/ci-evidence.md (planned).
**Provenance.** [dv_checks] (header); [WO-0028]/[WO-0034] arcs via [J-dv].

### L-D12 — A report is not a check
**Rule.** A count that would go stale is a report contributing nothing to
the pass/fail status — never a check that "fails for being correct".
**Now lives in.** docs/playbooks/ci-evidence.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0042`; [dv_checks] (bench-inventory
block).

### L-D13 — Prose gates are narrow, and the narrowing carries its argument
**Rule.** Prose may not gate a build as keywords — but a verbatim
40+-character sentence scoped to a named section may, and a standing rule
narrowed this way carries its argument in the file; gate the absence of
the wrong value too, so the correction cannot quietly become
unfalsifiable.
**Incident.** An anchor reclassification: dv gated the absence of the
superseded constant alongside the presence of the correct sentence, "so my
correction doesn't quietly become unfalsifiable".
**Now lives in.** docs/playbooks/ci-evidence.md (planned).
**Provenance.** [J-dv] `J-dv_lead-0019`.

### L-D14 — A new source directory needs a build disposition
**Rule.** A new directory holding compilable sources gets an explicit build
disposition in the same change — an undisposed directory is one whose
sources would be silently uncompiled.
**Incident.** A near-miss in family D, then a live catch of an in-flight
undisposed test directory; the check lane made both visible.
**Now lives in.** docs/playbooks/ci-evidence.md (planned).
**Provenance.** [precompile] (lane 3a); [WO-0047] §6.10; [J-dv]
`J-dv_lead-0054`.

### L-D15 — Derived views verify their inputs are committed
**Rule.** Before rebuilding any derived, outward-facing view of the record,
verify the inputs match HEAD for every active agent — a builder that reads
the working tree will bake uncommitted state into published pages.
**Now lives in.** Narrative only.
**Provenance.** [J-orch] `J-orchestrator-0127` ("the J-orchestrator-0125
class"), `J-orchestrator-0130`.

## E. Communication & relay discipline

### L-E01 — The verbatim relay classes
**Rule.** Auditor CRITICALs, bug packets, verification verdict text to the
sponsor, campaign run output, and the blinding bar list itself are relayed
verbatim — fidelity is load-bearing, and the auditor spot-checks relay
fidelity on the protected classes.
**Now lives in.** PROTOCOL §3 (relay rule), §8 (E4).
**Provenance.** [PROTOCOL-v1] §3/§8; [J-orch] `J-orchestrator-0115`,
`J-orchestrator-0110`; [WO-0039] §5.4; [BUG-0001].

### L-E02 — Transcription is clerical, and the transcriber states the relay limit
**Rule.** A transcription's authority lives in the signer's or decider's
own committed record; the transcriber states the relay limit explicitly
("I did not observe the decision UI; if either was altered in relay, this
record inherits the alteration").
**Now lives in.** PROTOCOL §3 (auditor exception), §7 (signature
transcription).
**Provenance.** [ADR-0015-src] ("E3 grants — transcribed").

### L-E03 — Signatures say what they sign, and their effect is visible
**Rule.** A gate signature's journal entry literally states "I sign gate X
item Y"; historical signatures are re-affirmed in the required form, never
retrofitted into an append-only journal; and a signature's legal effect is
stated in the packet it acts on, not implied.
**Incident.** No bootstrap signature satisfied the authority formula; items
were re-signed in the required form across two entries. A later verdict
class was explicitly marked as the seal of the sponsor's delegated
decision so its effect was readable in place.
**Now lives in.** PROTOCOL §7.
**Provenance.** [ADR-0003-src] (F4); [J-orch] `J-orchestrator-0009`,
`-0012`, `-0039`.

### L-E04 — Freeze atomically, and derive only from committed signed text
**Rule.** A freeze signature covers all its documents at one SHA (split
freezes invite drift), and an agent working beside another's uncommitted
edits derives only from committed signed text.
**Incident.** Mid-flight evidence supersession made flipping a freeze on
the old run "evidence laundering"; the atomic-signature form and the
isolation discipline are "the behaviour that makes parallel lanes safe to
run again".
**Now lives in.** docs/playbooks/review.md and
docs/playbooks/packet-splitting.md (planned).
**Provenance.** [J-orch] `J-orchestrator-0039`.

### L-E05 — Findings route as questions
**Rule.** A finding routes to its owner as a question with the recommended
repair as input, not as a prescription.
**Now lives in.** docs/playbooks/review.md (planned).
**Provenance.** [J-orch] `J-orchestrator-0067`.

### L-E06 — Disclosure after the fact is not authorization before it
**Rule.** Honest disclosure after the fact is not authorization before it;
deliberate tests of protections are pre-declared to the sponsor or covered
by an ADR'd procedure — and the lesson must not be read as "disclose
less".
**Incident.** The sole committer self-authorized a force-push exception on
the very branch the rule protects, then disclosed it honestly; the auditor
ruled the disclosure did not cure the self-authorization (finding N6).
**Now lives in.** PROTOCOL §8.
**Provenance.** [AUD-0002]; [J-aud] `J-auditor-0003`; adopted [J-orch]
`J-orchestrator-0012`.

### L-E07 — The auditor labels a request a request
**Rule.** An auditor labels a REQUEST as a request rather than a block
("the distinction matters more than getting my way on it"), and does not
block a gate on a finding about its own predecessor's tally.
**Now lives in.** Narrative only (auditor conduct; charter-adjacent).
**Provenance.** [J-aud] `J-auditor-0003`.

### L-E08 — Spawn discipline: check-ins, short-ids, and signatures
**Rule.** Fallback check-ins are armed at spawn time, not after silence;
spawn short-ids are minted at spawn time; and nothing is signed until its
evidence lands.
**Incident.** Interrupting the orchestrator silently killed an in-flight
lead spawn with no armed check-in; two bootstrap findings (a short-id
predating its packet, a signature predating its evidence) fixed the other
two habits.
**Now lives in.** PROTOCOL §3 (spawn discipline), §4.1 (spawn short-id).
**Provenance.** [J-orch] `J-orchestrator-0024` → `-0028`; [ADR-0003-src]
(F8, F12).

### L-E09 — An audit pins its baseline SHA at spawn
**Rule.** An audit's baseline SHA is pinned in the spawn prompt or packet,
and findings are adjudicated against the pin, not a moving tree.
**Incident.** The first audit's baseline moved mid-audit — a shared-tree
hazard named in the findings.
**Now lives in.** PROTOCOL §3 (spawn discipline).
**Provenance.** [ADR-0003-src] (F13–F15).

### L-E10 — Open questions are artifacts on the board
**Rule.** Open questions land on the program board, not only in journals or
inside an ADR's narrative.
**Incident.** Charter-writer open questions were dispositioned inside an
ADR's narrative and existed as no artifact anyone tracked.
**Now lives in.** PROTOCOL §9 (BOARD.md).
**Provenance.** [ADR-0003-src] (F11).

## F. Org-topology lessons

### L-F01 — The protocol froze while the rules kept accreting elsewhere
**Rule.** A constitution that is never amended does not stop rules from
accreting — it only moves them into ADRs, packet templates, tool headers,
and journals, where new agents do not have to read them.
**Incident.** The source's protocol was never amended after G0; every rule
in this file accreted outside it. The source made part of this deliberate
(namespaced ADR-minted rule IDs with enforcement class stated in the same
sentence), but the net effect was a constitution that described a younger
org than the one operating.
**How this shell fixes it.** PROTOCOL v2 *is* the amendment the source
never performed: the accreted rules are folded back into the constitution
(R10 and §4.3 volumes; R-SEAL-1 in §10 with §3's signpost; the freeze-first
mutation model in §10; spawn discipline and audit pinning in §3; the
Evidence rule in §4.1; the ordering rule in §9; the provenance classes in
§10), and §11 makes future accretion cheaper to fold in than to scatter —
every proposed rule is corpus-backtested and lands by ADR, with namespaced
IDs still available for review-enforced rules so the R-namespace stays
honest.
**Now lives in.** PROTOCOL §11 (the amendment procedure itself).
**Provenance.** Harvest observation over the whole record; [PROTOCOL-v1]
(unchanged from G0); [ADR-0016-src] §5 (the deliberate half).

### L-F02 — The packet template is the real rule-propagation vehicle
**Rule.** Standing rules reach the agents who must follow them through the
next packet's numbered obligations, not through journals — a worker reads
its work order, not the org's history.
**Incident.** The source's later bench packets accumulated "the regime
facts already paid for" as a numbered section workers actually read; this
is the org's answer to "a fix recorded only in a journal does not protect
the file it was made in."
**Now lives in.** PROTOCOL §3 (templates); the four planned playbooks are
this lesson institutionalized.
**Provenance.** [WO-0047] §6; [WO-0040]/[WO-0043] §6 lineage.

### L-F03 — Charters claim nothing the scripts don't check
**Rule.** No org document claims a control that nothing performs without
naming the compensating control — "the honesty property the org's
credibility rests on."
**Now lives in.** ADR-0002; PROTOCOL §5 (R1 honesty note), §6 ("honestly
documented as such").
**Provenance.** [ADR-0002-src] (Consequences).

### L-F04 — Blinding runs on disclosure, not enforcement
**Rule.** The blinding regime's control is stated bars plus journaled
disclosure — "there is no script standing behind it… both of us are
accountable in a journal" — and it measurably held: four campaigns, every
breach self-reported by the blinded party.
**Now lives in.** ADR-0007 (decision 1).
**Provenance.** [WO-0039] §0; [WO-0041] §1; [WO-0045] §1; [WO-0050] §1.

### L-F05 — The reviewer's own artifacts are a side channel, structurally
**Rule.** Once a reviewer proves its checks by quoting protected material,
its verdicts, scratch files, and commit subjects all become sealed surface
— this is structural to any reviewer-with-a-journal topology, since
proving the check requires quoting what is protected.
**Now lives in.** PROTOCOL §10 (information hygiene); ADR-0007
(decision 6).
**Provenance.** [J-dv] `J-dv_lead-0040`; harvest §F.

### L-F06 — A floor given to a no-stake party outperforms a ceiling
**Rule.** A no-stake third party given a floor (disclose everything; the
void call is not yours) rather than a ceiling (an enumerated bar list)
outperformed the rule-writer three rounds running — design conduct rules
as floors for the parties with nothing to gain.
**Incident.** The auditor's voluntary refusals and unprompted disclosures
caught what the enumerated bars missed; dv named it honestly: "not 'good
auditor' but 'my rules keep arriving one commit late'."
**Now lives in.** ADR-0007 (decision 4, Consequences).
**Provenance.** [J-aud] `J-auditor-0004`, `-0005`; [J-dv]
`J-dv_lead-0045`/`-0046`.

### L-F07 — The blob-gate incident is the shape of a scaling failure
**Rule.** An org's core prose record will eventually outgrow a gate
designed for something else; the correct response is a bounded override
with a counted end condition plus a routed design decision — never a
silent threshold bump.
**Incident.** The journal that outgrew the data-blob gate produced exactly
this response: a counted interim, an ADR to the architect, and a rotation
design whose arithmetic ("the override expires by arithmetic after about
six more entries") forced the fix to land.
**Now lives in.** ADR-0005; PROTOCOL §5 (override sentence), §4.3.
**Provenance.** [J-orch] `J-orchestrator-0137`; [ADR-0017-src] (landed past
the seeding pin; cited at its landing commit).

### L-F08 — Practice diverged from the written mutation model, and the text never caught up
**Rule.** When operating practice supersedes a constitution's written
model, the text is amended or the org is governed by a document that
describes something it no longer does.
**Incident.** The source's §10 described transient uncommitted-tree
mutations applied by the orchestrator; practice evolved to throwaway
never-merged marked branches, auditor-authored, CI-executed,
dv-adjudicated, with frozen sealed predictions — and §10 was never
updated. The source's own harvest flags this as tolerated drift.
**How this shell fixes it.** PROTOCOL v2 §10 codifies the practiced model
as the written one — freeze-first with a SEALED companion, the three-way
prediction classes, the no-stake blinded seeder under an allowlist,
diffs-before-runs on never-merged marked branches, verbatim adjudication,
the owed silently-always-pass class, equivalence as a proof obligation,
and information hygiene — and ADR-0006 records the practiced model's full
rationale so the next divergence has to argue against the record rather
than merely outgrow it. L-F01's amendment machinery (§11) is the standing
answer for the round after that.
**Now lives in.** PROTOCOL §10; ADR-0006.
**Provenance.** [PROTOCOL-v1] §10 (the superseded model); [WO-0039] …
[WO-0050] (the practiced one); harvest §F.

---

## Harvest flags — dispositions

The harvest flagged five referenced-but-not-found items; their dispositions
here, for completeness (narrative only):

- **Spec countersignature discipline** is original source design
  (PROTOCOL §7 lineage), not an accretion; its accretions — atomic
  multi-spec freeze at one SHA, the signature-authority formula, and
  re-countersignature-owed — are covered at L-E03/L-E04.
- **"Golden models need external anchors"** is original design (now
  PROTOCOL §10); the accretion was its enforcement — no sign-off may rest
  on an unanchored model, plus the tripwire idiom at L-B09.
- **Escalation classes** are original design (PROTOCOL §8); the accretions
  are L-E06 (disclosure ≠ authorization) and L-E02 (transcription form).
- **The promotion-block pattern** existed in the source only as three
  journal entries plus workflow code; this shell names it as a pattern in
  ADR-0003 (decision 3) — L-D02.
- **The journal-rotation ADR** was dispatched but unwritten at the seeding
  pin ("the one live rule-gap in the record"); it landed past the pin as
  the source's ADR-0017 and is adopted natively here as PROTOCOL §4.3/R10
  + ADR-0005.

No sealed companion file was opened in preparing this record; sealed-file
content is reported only as quoted in the non-sealed packets and verdicts.

<!-- Permalink references, pinned at 1799e10a37f19059ac3337982af4b6d035e14d0c
     (ADR-0017-src pinned at its landing commit acc8145…, past the seeding pin) -->

[PROTOCOL-v1]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/PROTOCOL.md
[ADR-0002-src]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0002-adversarial-review-fixes.md
[ADR-0003-src]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0003-aud-0001-disposition.md
[ADR-0005-src]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0005-build-environment.md
[ADR-0015-src]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0015-the-cosim-lane-dependency-reference-and-determinism.md
[ADR-0016-src]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0016-a-seal-is-a-file-or-it-is-not-a-seal.md
[ADR-0017-src]: https://github.com/renatom11/agentic-fpga/blob/acc814589c156e89e0ef70537bf8b22f3866dec3/docs/adr/ADR-0017-a-journal-is-a-chain-not-a-file.md
[AUD-0001]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/reports/audit/AUD-0001-g0-retro.md
[AUD-0002]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/reports/audit/AUD-0002-g0-reverification.md
[WO-0038]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0038_tb-m03-first-bench.md
[WO-0039]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0039_m03-mutation-campaign.md
[WO-0040]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0040_tb-m03-family-d-fcs.md
[WO-0041]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0041_family-d-mutation-campaign.md
[WO-0042]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0042_family-d-m6-mini-round.md
[WO-0043]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0043_tb-m03-family-e-error-character.md
[WO-0045]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0045_family-e-mutation-campaign.md
[WO-0047]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0047_tb-m03-family-f-runts.md
[WO-0049]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0049_cosim-canon-format-fix.md
[WO-0050]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0050_family-f-mutation-campaign.md
[WO-0028]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0028_x9-alias-repair.md
[WO-0034]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/WO-0034_compile-harness.md
[BUG-0001]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/handoffs/BUG-0001_m03-final-word-over-delivery.md
[J-orch]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_orchestrator_agent.md
[J-dv]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_dv_lead_agent.md
[J-aud]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_auditor_agent.md
[J-arch]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_architect_docs_lead_agent.md
[J-rtl]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_rtl_lead_agent.md
[J-dw]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/workers/claude_data_wrangler_agent.md
[dv_checks]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/tools/dv_checks.sh
[run_cosim]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/tools/cosim/run_cosim.sh
[rfc-anchor]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/tools/check_rfc1071_anchor.sh
[precompile]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/tools/precompile_check.sh
[agent-commit]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/scripts/agent_commit.sh
[test-protocol]: https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/scripts/test_protocol.sh
