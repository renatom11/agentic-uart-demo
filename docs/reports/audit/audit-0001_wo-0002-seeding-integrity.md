# audit-0001 — seeding-round integrity, WO-0002 mutation campaign

- **Auditor**: auditor (first spawn on this program)
- **Baseline pin**: `c7762b0`, working tree as found at spawn
- **Window**: the WO-0002 seeding round only — the authoring of the defect
  manifest. This is **not** a commit-range audit of R1–R10, not a spec-drift
  audit, and not a phase-gate audit; those are owed and unperformed, see §4.
- **Journal**: `J-auditor-0001`
- **Companion**: `WO-0002-manifest.md` and `WO-0002-mutations/`

> **Information hygiene notice.** `docs/reports/audit/**` is row 4 of the
> seeder allowlist in `WO-0002-mutation-campaign.md` §1 — a future campaign's
> blinded seeder may read this file. Finding F-01 therefore **cites** leaked
> sealed material by SHA and describes its shape; it does not reproduce it. The
> verbatim text is quoted once, in `J-auditor-0001`, which §1 places out of
> bounds to seeders. This is deliberate: a findings report that propagates the
> leak it reports is worse than the leak.

---

## 1. Summary

Six findings. **No CRITICAL.** The seeding round completed with all 19 diffs
authored, applying cleanly and compiling before any run executed, and with the
seal, the DV journal and `test/**` unopened.

| id | severity | subject | concerns |
|---|---|---|---|
| F-01 | **MAJOR** | Freeze commit's subject line leaks sealed material to the seeder | dv_lead + orchestrator |
| F-02 | **MAJOR** | Spawn dispatch widened the seeder's allowlist beyond the brief | orchestrator |
| F-03 | MINOR | The §4.1 precheck is the delivery mechanism for F-01 — the two rules collide by construction | protocol |
| F-04 | MINOR | Playbook cites a shape reference that does not exist | docs |
| F-05 | MINOR | Working tree not clean at the campaign's base pin | orchestrator |
| F-06 | **REQUEST** (not a block) | The near-miss controls sit outside the sealed surface and need a disposition before the runs | dv_lead |

**Two of these concern the party that relays them.** F-02 and F-05 are findings
about the orchestrator, which is also the sole committer and the channel through
which this report reaches the sponsor. Charter §7 requires me to say so in
terms: *this report contains findings about the relaying party.* The
compensating control is structural — this is a committed file under
`docs/reports/audit/`, which gate procedure obliges the sponsor to read
unmediated.

---

## 2. Findings

### F-01 — MAJOR — the freeze commit's subject line leaks sealed material into the seeder's ambient exposure

**What.** The subject line of commit `c7762b0` — the freeze commit that stages
the campaign brief and its sealed companion — states three things about the
sealed predictions: the number of classes sealed, the number of rows its author
judged **unable to fail**, and a **discriminating property of one specific
predicted check**, named by kind. That last item is precisely the sort of
material §0 seals: it bears on whether a named defect class can be caught at all.

**Falsifiable.** `git log -1 c7762b0` renders it. Verbatim text in
`J-auditor-0001`, not reproduced here (see the hygiene notice above).

**Rule breached.** Three, all saying the same thing:

- `WO-0002-mutation-campaign.md` §0, *Commit-subject hygiene*: "campaign-adjacent
  commit subjects are deliberately thin — a subject line that names a predicted
  row or message is a leak into the seeder's ambient exposure." The breached
  rule is in the breaching commit's own packet.
- `PROTOCOL.md` §10, *Information hygiene*: "Campaign-adjacent commit subjects
  are deliberately thin."
- `docs/playbooks/mutation-campaign.md` §*Information hygiene*, same words.

**Responsibility.** The commit carries dv_lead's freeze (the packet's Return log
records the freeze as dv_lead's, `J-dv_lead-0002`) and was created by the
orchestrator, which is the sole committer and holds §0's relay restriction. I do
not adjudicate between them; both had a duty the subject line defeats, and the
subject line is a single artifact.

**Effect on this campaign — stated precisely, neither minimised nor inflated.**

- It **cannot** have steered *which* defects were seeded. The seeder has no
  discretion there: dv_lead published all 17 intents in §2 of the brief, and the
  manifest authors those 17 and nothing else.
- It **could** in principle have steered *where within a class* a diff lands. It
  did not, and the claim is checkable: the placement rule used throughout was
  "the smallest edit at the site the cited spec text points to", and every diff
  in the manifest can be checked against it.
- **One adjacency I am flagging rather than letting it surface at
  adjudication**: the manifest's detectability note for M-04 / `TX-1` observes
  that 16 of the 256 byte values are bit-palindromes and emit an identical
  waveform under a bit-reversal mutation. That is a fact about the design, is
  independently derivable from `rtl/uart_tx.sv` and SPEC §3, and any careful
  seeder would state it — **and** it is adjacent to the leaked material. I state
  the adjacency so dv_lead can discount the sentence, rather than discover the
  adjacency later and have to wonder.

**Severity: MAJOR, not CRITICAL, and why.** The exposure is disclosed before any
run, the campaign's aim-independence is structurally protected by the
published-intent design, and the remedy is available and cheap: dv_lead rules on
whether the exposure voids any mutant. It becomes CRITICAL if the adjudication
relies on the leaked property without recording that the seeder had been exposed
to it.

**Disposition is dv_lead's, not mine** (charter L-C15, PROTOCOL §10): the call on
whether an ambient exposure voids a mutation belongs to dv, never to the seeder.

---

### F-02 — MAJOR — the spawn dispatch widened the seeder's allowlist beyond the brief

**What.** The dispatch that spawned this round enumerated an "IN BOUNDS" list
including `tasks/BOARD.md` and `docs/adr/**`, and listed reading the board as a
mandatory first action. `WO-0002-mutation-campaign.md` §1 places both out of
bounds in terms: "`tasks/BOARD.md` and `docs/` outside `docs/specs/**`,
`docs/playbooks/mutation-campaign.md` and `docs/reports/audit/**` — the board
narrates which checks caught what."

**Falsifiable.** The brief's §1 table and its out-of-bounds list; the dispatch's
own IN BOUNDS list.

**Rule breached.** PROTOCOL §10: the seeder works "blinded under an **ALLOWLIST**
of readable paths **stated in the brief**". The allowlist is dv_lead's
instrument. The orchestrator relays the brief; it is not a party that may widen
it, and a widening at spawn time defeats the design property the brief states in
its own words — "an allowlist cannot be defeated by a document the author forgot
to enumerate".

**Consequence, disclosed.** I read `tasks/BOARD.md` before reaching the brief
that forbids it, because the dispatch ordered it as a mandatory first action.
What it carries that a seeder should not have: per-bench check counts, the
mapping of benches to REQ ids, and a narrative paragraph about a requirement a
defective transmitter formerly satisfied. **I have grounded no finding and no
detectability judgement on any of it**, and I declined `docs/adr/**` outright
once the conflict was visible — a voluntary refusal, recorded because the
charter says my conduct may exceed my instructions (L-F06).

**Recommendation.** A seeding spawn prompt should not restate the allowlist at
all. It should name the brief and stop, so there is exactly one allowlist and one
author of it.

---

### F-03 — MINOR — the §4.1 precheck is the delivery mechanism for F-01

**What.** The dispatch requires `git log --oneline -1` as part of the §4.1
precheck. `--oneline` renders the subject line. When the immediately preceding
commit is a campaign freeze, **the mandated precheck is exactly what delivers the
leak to the blinded seeder.** F-01 would not have reached me by any other route
this round: the brief forbids unscoped `git log` (§1 bar 11), and I ran no other
git command.

**Why it is a finding and not an excuse.** Two rules that cannot both be honoured
as written is a defect in the rules, and it is cheap to fix.

**Recommendation.** For seeding rounds, pin the baseline with
`git log -1 --format=%H` — SHA only. That satisfies everything the precheck
exists for (recording the pin) and renders no subject line. If the precheck's
wording is changed, PROTOCOL §11 applies.

---

### F-04 — MINOR — the playbook cites a shape reference that does not exist

**What.** `docs/playbooks/mutation-campaign.md:55` directs the seeder to stage
diffs and report to `docs/reports/audit/WO-NNNN-mutations/` "(shape:
`../reports/audit/README.md`)". No such file exists at `c7762b0`; the tree holds
only `docs/reports/audit/.gitkeep`. A seeder following the playbook finds a
dangling link where the normative shape should be.

**Falsifiable.** The playbook line, and the contents of `docs/reports/audit/`.

**Not fixed by me this round, deliberately.** The path is inside my write scope
and nobody else may write it, so it is mine to create — but authoring a normative
shape document is not what this round was dispatched to do, and quietly inventing
one inside a seeding commit would be scope creep in the one tree nobody else can
review by diff against a spec. Flagged for disposition. I created
`WO-0002-mutations/README.md` as this campaign's directory index, which is the
artifact the playbook's step 8 actually asks for; it is not offered as the
missing normative shape.

---

### F-05 — MINOR — the working tree was not clean at the campaign's base pin

**What.** `git status --short` at spawn returned two untracked entries:
`site/wave.py` and `site/__pycache__/`. The dispatch declared `site/wave.py` as a
concurrent orchestrator-lane file, so it is disclosed rather than unexplained.
`site/__pycache__/` is not declared — and is the more interesting of the two,
because `.gitignore:15` contains `__pycache__/`, a pattern that should match a
directory of that name at any depth. An untracked path that an ignore rule
appears to cover is worth someone's attention.

**Bounded investigation, stated as such.** I did not investigate further. This
round caps git use at the two precheck reads, and §1 bar 11 binds every git
subcommand to the allowlist. I therefore report the two observations and
**assert no cause** — an auditor limited to two git reads cannot resolve a tree
anomaly, and guessing at one would be exactly the unfalsifiable claim my own DoD
forbids.

**Why it matters here at all.** The campaign's discipline is
`[frozen base SHA + exactly one diff]`. That is cleanest when the tree at the
pin is clean, and every untracked file at the pin is one more thing a branch
operator must remember not to carry onto a mutant branch.

**The related positive finding, recorded because it supports the campaign.** A
concurrent orchestrator-lane was declared to me at spawn (`site/wave.py`), which
raises the fair question of whether the tree moved under the seeder while the
diffs were being authored. It did not. By filesystem mtime — not git evidence,
and stated as such — every file in the repository outside `docs/reports/audit/**`
and my own journal carries an mtime at or before 19:17:52 UTC, while my first
action of the round was at 19:19 UTC and my first write at 19:35 UTC. In
particular `rtl/**` is unchanged since 18:16 UTC. **Every diff in this campaign
was authored against a static tree**, and the concurrent lane touched nothing
during the round.

---

### F-06 — REQUEST (explicitly not a block) — the near-miss controls need a disposition before the runs

**What.** The seeding dispatch required at least one deliberate near-miss control
— an edit to `rtl/**` that leaves observable behaviour unchanged — as the control
showing the campaign measures behaviour rather than reddening at any edit. I
authored two: `NM-1` and `NM-2` (manifest M-18, M-19), argued equivalent over the
whole legal stimulus space and measured byte-identical under the seeder's own
probe.

**The tension.** The brief's §2 fixes exactly 17 intents, and the seal classifies
the scoring surface for those. The controls are not among them, **so the sealed
predictions cannot name them and they have no predicted cells.** The denominator
was fixed at freeze and does not move mid-campaign.

**The request.** Rule on the controls before the runs — as out-of-scoring
controls, or declined. Scoring them against a seal that does not name them would
manufacture exactly the "red cell outside the prediction" case the playbook calls
a finding, and would do it for a mutant the seal never had the chance to predict.

**This is a request and not a block.** It is dv_lead's call, it does not block a
gate, and I am not entitled to make it. Recorded here so the ruling lands *beside*
the seal in the packet's Return log, before results exist, rather than after.

---

## 3. What was verified this round

| check | result |
|---|---|
| Blind held on the seal (`WO-0002-SEALED-predictions.md`) | **Never opened** |
| Blind held on `agents/journals/claude_dv_lead_agent.md` | **Never opened** |
| Blind held on `test/**` in its entirety | **Never opened, never copied into a build tree** |
| Diffs authored before any run executed | Yes — no mutant branched, no suite invoked, no result exists |
| All diffs apply cleanly to the base pin | 19/19 via `patch -p1` on fresh `rtl/`-only copies |
| All diffs compile | 19/19 under `iverilog -g2012 -f rtl/uart_lite.f`, zero warnings |
| Build-only repairs needed | **None** — nothing to disclose under §1 bar 8 |
| Greppable marker in every hunk | 19/19 patches, every hunk, `<id> MUTATION (WO-0002)` |
| Silently-always-pass class present | Yes — M-07 / `TX-4`, left deliberately quiet |
| All five modules spanned | Yes — by file edited: 4 / 5 / 4 / 3 / 3 across `uart_tick_gen.sv`, `uart_tx.sv`, `uart_rx.sv`, `uart_fifo.sv`, `uart_lite.sv` |
| Tree copies excluded out-of-bounds paths at copy time | Yes — copies contain `rtl/` only |
| Git write commands run | **None** |
| Staged outside `docs/reports/audit/**` | **Nothing** |

---

## 4. Scope limits of this report — stated, not implied

This was a seeding round, and this report covers the seeding round. The
following audit duties my charter makes mandatory are **owed and unperformed**,
and no reader should take this file as evidence about any of them:

- **No commit-range audit.** R1–R10 have not been checked over any window; no
  journal was sampled for vacuity; `Files-in-this-commit` set-equality was not
  verified for any commit but my own. The round's two-git-read cap and the
  allowlist's exclusion of `agents/**` make that work impossible in this round
  by construction — it needs its own spawn, with a commit range and no blind.
- **No Evidence re-execution.** Charter §6 requires ≥ 10 % of a phase's journal
  Evidence claims re-executed at their recorded SHAs. None were: the journals
  are out of bounds this round.
- **No spec-drift audit**, beyond what reading `rtl/**` against `docs/specs/**`
  for seeding incidentally exposed. I found no deviation between the five
  modules and the SPEC/REQ text while authoring against them, which is an
  observation from a sample of one purpose, not a drift audit.
- **No independence audit, no relay-fidelity sample, no DV-escape ledger.**
  `docs/reports/audit/dv_escapes.md` does not exist yet; nothing has escaped a
  sign-off, because no `SO-` has issued.
- **No campaign result.** I do not run these diffs and do not see the results
  (WO-0002 §3). Nothing here says whether the suite has teeth. That is what the
  campaign is for, and its answer belongs to dv_lead's adjudication.

`tasks/BOARD.md` records the auditor's absence as a stated limitation. This round
narrows it and does not close it.

---

*Findings reach the human sponsor unedited (PROTOCOL §3, §8 E4). F-02 and F-05
concern the orchestrator, which relays this report.*
