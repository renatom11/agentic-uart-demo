# WO-NNNN: Mutation campaign — <bench family / module> (<N> seeded defects)

<!-- Mutation-campaign brief — dv_lead → auditor (the no-stake seeder), via
     orchestrator. This is a specialised WO- packet implementing PROTOCOL
     §10's freeze-first campaign model; the procedure it drives is
     docs/playbooks/mutation-campaign.md. Commit this brief AND its sealed
     companion (SEALED-predictions-template.md) in the same commit, before
     any defect exists (R-SEAL-1). Delete these comments when
     instantiating. -->

- **State**: DRAFT <!-- → ISSUED → RETURNED → ACCEPTED | BOUNCED -->
- **From** / **To**: dv_lead → auditor (via orchestrator; *Summarizable*,
  **with the restriction in §0**)
- **Spec basis**: <the spec sections and REQ-### ids the seeded defect
  classes violate>
- **Subject under test**: **not the design.** <The bench family under
  qualification — e.g. `test/<module>/**`> — and whether it has teeth.
- **Base SHA**: `<sha>` — every diff applies to this tree and nothing else.
  **Verified rather than assumed**: state the check proving the compiled
  surface at the base equals the surface of the named green control run
  (e.g. `git diff <base> <control> -- test/ rtl/` is empty), so pass
  criterion 3 is met before the campaign starts.

## 0. What is sealed, and what was published on purpose

Predictions live in
`agents/handoffs/WO-NNNN_<slug>-SEALED-predictions.md`.
**Do not open it until all <N> diffs are committed.**

This campaign publishes the **defect classes** (§2) to the seeder and seals
the rest: **which units must redden, which must stay green, and the exact
failure messages**. Row sets rarely discriminate between defect classes;
messages do — sealing the messages is the part that matters.

**Relay restriction**: the orchestrator may summarize routing chatter, but
relays §2's intents to the seeder verbatim and relays every run result
verbatim (§4). Nothing from the sealed companion is relayed to anyone before
adjudication.

The informative outcome remains a mutation that reddens the **wrong** unit,
or none.

## 1. What the seeder may read — an ALLOWLIST

**This is the complete set of repository paths you may read for this
campaign. Everything else in the repository is out of bounds.** An allowlist
cannot be defeated by a document the author forgot to enumerate — which is
the failure mode bar-lists actually have.

| | readable |
|---|---|
| 1 | **this packet** |
| 2 | **`docs/specs/**`** — what you need to author faithful intents |
| 3 | **`rtl/**`** — the design you are mutating |
| 4 | **`docs/reports/audit/**`** — your own tree |
| 5 | **root-level build-configuration files** — they carry no bench, prediction, or verdict content, and reverse-engineering build names from error text is friction with no blinding benefit |

**Out of bounds, by construction rather than by enumeration:** all of
`test/**` (the bench under test, the attack plan, the comparison domain);
all of `agents/**` other than this packet (every other packet, every
verdict, every journal — including this campaign's sealed companion). If you
believe you need something outside the list, **ask through the orchestrator
rather than read.**

**Process bars — standing practice:**

6. Author all <N> diffs **before any of them is run**.
7. **Do not revise a diff after seeing any run result.** Sole exception: a
   diff that fails to *build* — repair it to build, change nothing else,
   disclose the repair. Where the build enforces formatting, the formatter's
   own output counts as a build repair; hand reformatting does not.
8. Work in a **private scratch subdirectory**; nothing you stage outside
   `docs/reports/audit/**`.
9. **Exclude out-of-bounds paths from any tree copy** you make to test that
   a diff builds — exclude at copy time, not reliance on the build failing
   before it reaches them.
10. **No unscoped `git log`**, and a path outside the allowlist is out of
    bounds to **every git subcommand**, not merely to opening the file.

**Disclosure:** your journal `Inputs` lists what you read, including ambient
exposure from prior spawns — known exposure is disclosed, not disqualifying;
the call on whether it voids a mutation is dv_lead's (PROTOCOL §10).

## 2. The mutation intents

Behavioural specifications, not diffs. **Minimality** — the smallest change
producing the described behaviour — and **fidelity** — behaves *as
described*, not merely broken nearby — matter more than elegance. If a
faithful minimal diff is not achievable, say so rather than substituting.

**Standing clause**: when a spec rule collides with an intent, **preserve
the spec rule and disclose the collision.** An intent describes one defect
and is never a licence to break a second rule on the way to it.

| id | class | one-line intent |
|---|---|---|
| <X>-c1 | <defect class> | <what the mutant does wrong> |
| <X>-c2 | … | … |
| <X>-cN | **silently-always-pass** | <a defect whose symptom is a green suite that checks nothing — every qualification owes at least one (PROTOCOL §10)> |

### <X>-c1 — <title>

**Intent.** <The wrong behaviour, precisely: which rule is violated, what is
observably different, and what is explicitly unaffected ("frames closed
normally are unaffected"-style bounds make fidelity checkable.>

<!-- Repeat per intent. For the quiet class, keep the warning: -->

> **Expect the silently-always-pass mutant to look quiet, and do not
> strengthen it.** A correct implementation of this intent has a small
> observable footprint; that is the defect class, not a weak diff.

## 3. What the seeder produces

A report under `docs/reports/audit/WO-NNNN-mutations/` (shape:
`docs/reports/audit/README.md`): each diff in full, applying cleanly to the
base SHA; file and function touched; a one-paragraph fidelity argument per
diff; any build-only repair and why; anything you could not do faithfully,
said plainly. Plus a scope statement listing what you read against §1's
allowlist.

**You do not run the diffs and you do not see the results.**

## 4. Mechanics and return — the orchestrator's part

Throwaway branch per mutant: `mut/wo-NNNN-<id>` = base SHA + exactly one
diff, nothing else; **never merged**; every hunk carries the greppable
marker comment `<id> MUTATION (WO-NNNN)`. CI executes the campaign; nobody
reruns locally.

Per run, the relay to dv_lead states: the parent SHA, the mutation id, the
CI run id, build state, and the test step's **verbatim** output — the
complete failure message and **the name of every test that failed**, not a
summary.

**A green run on any mutant is a campaign failure** and must be relayed
prominently — never buried in a batch summary.

**Generated-artifact drift at the determinism step is expected under every
design mutation, is never an unnamed-unit finding, and is never harvested**
— it sits outside the unit matrix by construction.

## 5. Pass criteria

1. The suite goes red under every mutant.
2. Red **in the units dv_lead named in advance, with the expected message**
   (the sealed companion's REQUIRED cells). An unnamed unit reddening, or a
   named unit reddening with the wrong message, is a **finding**, not a
   kill.
3. The unmutated control is green at the base SHA (established in the
   header).

**Prediction classes** (fixed in the sealed companion at freeze; the
denominator — units, rows, benches — never moves mid-campaign):

- **REQUIRED** — must fail, in the named rows, with the named messages.
- **MUST-STAY-GREEN** — any red here is a finding.
- **PERMITTED** — may go either way; carries no score.

The qualified rows cannot carry a sign-off until all mutants kill, and the
module's `SO-` does not issue on one campaign alone — coverage arithmetic is
the SO- packet's job.

**Commit-subject hygiene**: campaign-adjacent commit subjects are
deliberately thin — a subject line that names a predicted row or message is
a leak into the seeder's ambient exposure (PROTOCOL §10).

---

## Return / verdict log

<!-- Pre-result rulings (adjudication questions answered before runs
     complete) are appended here as an ADDENDUM, journal-referenced; the
     frozen seal is never edited — rulings are issued beside it.
     The final entry is the adjudication verdict: -->

## RV-NNNN-VERDICT: <n>/<N> killed — dv_lead, `J-dv_lead-NNNN`

**Branches** `mut/wo-NNNN-<id>…` at <SHAs>, each base + one diff; control
green at <run id>. Criterion 3 met.

| | REQUIRED | MUST-STAY-GREEN | message | verdict |
|---|---|---|---|---|
| <X>-c1 | n/n <rows> | n/n | sealed text / finding | KILL / MISS / FINDING |
| … | | | | |

<Campaign verdict: PASS/FAIL, findings list, what this campaign licenses for
its REQ ids — with its bounds attached, and what it does NOT license.>
