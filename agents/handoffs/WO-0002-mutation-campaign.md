# WO-0002: Mutation campaign — the uart_lite bench suite (17 seeded defects)

- **State**: `ISSUED`
- **From** / **To**: dv_lead → auditor (the no-stake seeder), via orchestrator.
  *Summarizable*, **with the relay restriction in §0**.
- **Spec basis**: `docs/specs/SPEC-uart_lite.md` §2, §3, §5.1–§5.5, §6;
  `docs/specs/requirements.md` REQ-001 … REQ-017.
- **Subject under test**: **not the design.** The five benches under `test/`
  — `tb_uart_tick_gen`, `tb_uart_fifo`, `tb_uart_tx`, `tb_uart_rx`,
  `tb_uart_lite`, 609 checks — and whether they have teeth.
- **Base SHA**: the freeze commit that stages this packet and its sealed
  companion. Its parent is `509173a`. The orchestrator records the freeze SHA
  in §Return below when it spawns the seeder. Every diff applies to that tree
  and to nothing else.

## Why this campaign exists

`tasks/BOARD.md` states the program's honest position in terms: **"No mutation
campaign has been run. Nothing establishes in general that these benches would
catch a defect."** The suite is 609 green checks and one real caught defect
(BUG-0001). One defect found is not a detection rate.

This campaign is the first measurement. Its result is evidence rather than
hindsight **only because the predictions were frozen before any defect
existed** — the seal was committed in this packet's own commit, and this
sentence is the forward commitment PROTOCOL §10 R-SEAL-1 requires to be
redeemed by that same commit.

## 0. What is sealed, and what is published on purpose

Predictions live in `agents/handoffs/WO-0002-SEALED-predictions.md`.
**Do not open it. Not now, not after the diffs are written, not after the runs
— the seeder never opens it in any state, and the orchestrator relays nothing
from it to anyone before adjudication.**

This campaign **publishes the defect classes** (§2) and seals the rest: which
units must redden, which must stay green, and **the exact expected failure
messages**. Row sets rarely discriminate between defect classes; messages do.
Sealing the messages is the part that matters.

**Relay restriction**: the orchestrator may summarize routing chatter, but
relays §2's intents to the seeder verbatim and relays every run result verbatim
(§4). **Commit-subject hygiene**: campaign-adjacent commit subjects are
deliberately thin — a subject line that names a predicted row or message is a
leak into the seeder's ambient exposure.

The informative outcome remains a mutation that reddens the **wrong** unit, or
none.

## 1. What the seeder may read — an ALLOWLIST

**This is the complete set of repository paths you may read for this campaign.
Everything else in the repository is out of bounds.** An allowlist cannot be
defeated by a document the author forgot to enumerate — which is the failure
mode bar lists actually have.

| | readable |
|---|---|
| 1 | **this packet** |
| 2 | **`docs/specs/**`** — SPEC-uart_lite.md and requirements.md; what you need to author faithful intents |
| 3 | **`rtl/**`** — the design you are mutating, including `rtl/uart_lite.f` |
| 4 | **`docs/reports/audit/**`** — your own tree |
| 5 | **`agents/charters/auditor.md`**, **`agents/PROTOCOL.md`**, **`docs/playbooks/mutation-campaign.md`** — your own operating rules |
| 6 | **root-level build-configuration files** (`.gitignore`, `CLAUDE.md`, `README.md`) — they carry no bench, prediction or verdict content, and reverse-engineering build names from error text is friction with no blinding benefit |

**Out of bounds, by construction rather than by enumeration:**

- **all of `test/**`** — the benches under qualification. You must not read the
  benches you are trying to defeat, or you will aim at them rather than at the
  design, and the campaign will measure your aim instead of their coverage.
  This is the single most important line in this packet.
- **all of `agents/**` other than the four files named at rows 1 and 5** —
  every other packet, every verdict, every journal, and above all
  `agents/handoffs/WO-0002-SEALED-predictions.md` and
  `agents/journals/claude_dv_lead_agent.md`, whose entry `J-dv_lead-0002`
  restates the sealed mapping.
- **`tasks/BOARD.md`** and `docs/` outside `docs/specs/**`,
  `docs/playbooks/mutation-campaign.md` and `docs/reports/audit/**` — the board
  narrates which checks caught what.

If you believe you need something outside the list, **ask through the
orchestrator rather than read.**

**Process bars — standing practice:**

7. Author all 17 diffs **before any of them is run**.
8. **Do not revise a diff after seeing any run result.** Sole exception: a diff
   that fails to *build* — repair it to build, change nothing else, disclose
   the repair.
9. Work in a **private scratch subdirectory**; stage nothing outside
   `docs/reports/audit/**`.
10. **Exclude out-of-bounds paths from any tree copy** you make to check that a
    diff builds — exclude at copy time; do not rely on the build failing before
    it reaches them. In particular, a copy made to run `iverilog` must not
    contain `test/`.
11. **No unscoped `git log`**, and a path outside the allowlist is out of
    bounds to **every git subcommand**, not merely to opening the file.

**Disclosure:** your journal `Inputs` lists what you read, including ambient
exposure from prior spawns. Known exposure is disclosed, not disqualifying; the
call on whether it voids a mutation is dv_lead's (PROTOCOL §10).

## 2. The mutation intents

Behavioural specifications, not diffs. **Minimality** — the smallest change
producing the described behaviour — and **fidelity** — behaves *as described*,
not merely broken nearby — matter more than elegance. If a faithful minimal
diff is not achievable, say so rather than substituting.

**Standing clause**: when a spec rule collides with an intent, **preserve the
spec rule and disclose the collision.** An intent describes one defect and is
never a licence to break a second rule on the way to it.

| id | module | class | one-line intent |
|---|---|---|---|
| TG-1 | `uart_tick_gen` | anchor phase, early | first tick lands one cycle *before* the spec's cycle N·k |
| TG-2 | `uart_tick_gen` | anchor phase, late | first tick lands one cycle *after* the spec's cycle N·k |
| TG-3 | `uart_tick_gen` | restart suppression | `restart` zeroes the counter but does not suppress `tick` in that cycle |
| TX-1 | `uart_tx` | bit order | data bits are transmitted MSB-first |
| TX-2 | `uart_tx` | frame length | the frame is one full bit period short — no stop interval is emitted |
| TX-3 | `uart_tx` | bit period | each bit interval is 433 cycles instead of 434 |
| TX-4 | `uart_tx` | **silently-always-pass** | `tx_busy` never asserts |
| RX-1 | `uart_rx` | sample position | the receiver samples at the bit boundary rather than mid-bit |
| RX-2 | `uart_rx` | oversample rate | `DIV_OS` is 26 instead of 27 |
| RX-3 | `uart_rx` | false start | a high sample at the confirmation point does not abandon the frame |
| RX-4 | `uart_rx` | synchroniser depth | `rx_line` passes through one flip-flop instead of two |
| FF-1 | `uart_fifo` | full flag | `full` asserts one entry early, at `level` = DEPTH−1 |
| FF-2 | `uart_fifo` | write while full | a write while full is accepted and overwrites the oldest entry |
| LT-1 | `uart_lite` | overrun stickiness | `rx_overrun` is a one-cycle strobe instead of sticky |
| LT-2 | `uart_lite` | framing error | a framing error writes the received byte into the FIFO |
| LT-3 | `uart_lite` | valid polarity | `rx_valid` is asserted when the FIFO is empty |
| LT-4 | `uart_lite` | reset state | `tx_line` resets low instead of high |

### TG-1 — tick anchor one cycle early

**Intent.** SPEC §5.1 anchors cycle 0 at the cycle in which `rst` or `restart`
is *sampled high*, and puts the k-th `tick` in cycle N·k. Make the divider
reach terminal count one cycle early, so the first tick after either anchor
lands at cycle N−1. **Unaffected**: the spacing between successive ticks stays
exactly N, `tick` is still one cycle wide, and it is still never high in two
consecutive cycles. This is the historical BUG-0001 restored.

### TG-2 — tick anchor one cycle late

**Intent.** The opposite sign to TG-1: the first tick after either anchor lands
at cycle N+1. **Unaffected**: spacing stays exactly N, width stays one cycle.
TG-1 and TG-2 are a deliberate pair; author them as two independent diffs and
do not make them symmetric edits of the same line if fidelity is better served
otherwise.

### TG-3 — `restart` does not suppress `tick`

**Intent.** SPEC §5.1's port table says that while `restart` is high "the
counter is forced to 0 for that cycle and `tick` is suppressed". Keep the
counter forcing; remove only the suppression, so a `tick` that would otherwise
have fired in the restart cycle fires. **Unaffected**: the post-restart
schedule (first tick at N), the reset schedule, and the spacing.

### TX-1 — data bits MSB-first

**Intent.** SPEC §3 requires eight data bits **least significant first**. Emit
them d7…d0. **Unaffected**: the start bit is still low for one interval, the
stop bit still high for one interval, every interval is still 434 cycles, and
the handshake is untouched.

### TX-2 — the frame is one bit period short

**Intent.** SPEC §5.2 requires ten bit intervals of 434 cycles and `tx_ready`
rising at cycle `1 + 10·DIV_TX` from acceptance. Make the transmitter finish
after nine intervals — start plus eight data bits — and return to idle, so no
stop interval is emitted at all. Because idle and stop are the same level, the
line's *value* where the stop bit belongs is unchanged; what moves is when the
transmitter declares itself done. **Unaffected**: bit order, bit period, byte
value, the start bit.

Read the intent precisely: *one full bit period*, not one clock cycle. A stop
interval shortened by one cycle is a different class and is not this one.

### TX-3 — bit period 433

**Intent.** SPEC §2 fixes `DIV_TX` = 434. Make every one of the ten intervals
433 cycles. **Unaffected**: bit order, frame structure, byte value, the number
of intervals.

### TX-4 — `tx_busy` never asserts *(silently-always-pass)*

**Intent.** SPEC §5.2 says `tx_busy` is "high from acceptance until the stop
bit completes". Make it never assert. **Unaffected**: absolutely everything
else — frame, period, bit order, `tx_ready`, `tx_line`.

> **Expect this mutant to look quiet, and do not strengthen it.** A correct
> implementation of this intent has a very small observable footprint. That is
> the defect class, not a weak diff. Every qualification owes one mutant of
> this class (PROTOCOL §10); making it louder destroys the measurement it
> exists to take.

### RX-1 — sampling at the bit boundary, not mid-bit

**Intent.** SPEC §5.3 requires sampling at oversample ticks 8, 24, …, 152 — the
middle of each bit cell. Move the sample points to ticks 0, 16, …, 144, the
leading edge of each cell. **Unaffected**: the oversample rate (still 27
cycles), the number of samples (still 10), the start-edge detection and the
`restart` pulse it produces, and the mutual exclusivity of `rx_strobe` and
`rx_frame_err`.

### RX-2 — oversample divisor 26

**Intent.** SPEC §2 fixes `DIV_OS` = 27 (and `OS` = 16, receive bit period
432). Make `DIV_OS` = 26. **Unaffected**: `OS` stays 16, sampling stays at tick
8 of each cell (mid-bit), the frame structure and sample count are unchanged.
Only the rate is wrong.

### RX-3 — false start not rejected

**Intent.** SPEC §5.3's "False start" clause: if the sample at oversample tick
8 reads high, the frame is abandoned and the receiver returns to idle,
asserting neither `rx_strobe` nor `rx_frame_err`. Take the sample as before but
do not act on it — let the frame proceed regardless. **Unaffected**: sample
timing, the stop-bit check, `rx_frame_err` on a genuinely low stop bit.

### RX-4 — one synchroniser flop instead of two

**Intent.** SPEC §5.3 and REQ-013 require `rx_line` to pass through **two**
flip-flops in the `clk` domain before any logic reads it. Reduce it to one.
**Unaffected**: the design still functions in simulation; REQ-013's "exactly
one reader" property is preserved. What is lost is the metastability margin,
and everything downstream happens one cycle earlier.

### FF-1 — `full` off by one entry

**Intent.** SPEC §5.4 and REQ-015 require `full` asserted **exactly** when
`level` = DEPTH. Assert it at `level` = DEPTH−1, so the FIFO stores at most 15
entries. **Unaffected**: `empty` is still exact, ordering is preserved,
first-word fall-through still works, a write while `full` is still ignored, a
pop while empty is still ignored.

### FF-2 — write while full overwrites the oldest entry

**Intent.** SPEC §5.4: "A write while `full` is **silently ignored**: stored
entries are unchanged and no flag is raised by this module." Accept the write
instead: drop the oldest entry and advance the head, keeping `level` at DEPTH.
**Unaffected**: `full` still asserts exactly at `level` = DEPTH, `empty` is
still exact, `level` still reports the number of entries stored, a pop while
empty is still ignored, and no flag is raised by the FIFO.

### LT-1 — `rx_overrun` is a strobe, not sticky

**Intent.** SPEC §5.5 and REQ-014 make `rx_overrun` **sticky**: set when a byte
completes while the FIFO is full, and it "stays set until `rx_ovr_clr`". Make
it a one-cycle pulse that self-clears. **Unaffected**: the arriving byte is
still dropped, the 16 stored bytes are still unchanged and still read out in
order, `rx_ovr_clr` still exists and still acts on the flag.

### LT-2 — a framing error writes the FIFO

**Intent.** SPEC §5.5: "A framing error does **not** write the FIFO." Make a
completed frame whose stop bit sampled low push its byte into the FIFO as if it
were valid. **Unaffected**: `rx_frame_err` is still asserted for one cycle,
`rx_strobe` is still withheld, exclusivity holds, and the overrun rule is
unchanged.

### LT-3 — `rx_valid` inverted

**Intent.** SPEC §5.5 defines `rx_valid` as "FIFO not empty". Drive it from the
FIFO's `empty` flag directly, so it is high exactly when there is nothing to
read. **Unaffected**: `rx_data` still presents the FIFO head, the FIFO itself
is untouched, `rx_ready` still pops on `rx_valid & rx_ready` as wired.

### LT-4 — `tx_line` resets low

**Intent.** SPEC §6 requires that one cycle after `rst` deasserts,
`tx_line` = 1. Make it reset to 0 and stay low until the first frame is
requested, after which the transmitter behaves normally. **Unaffected**:
`tx_ready` = 1 out of reset, the FIFO empty, `rx_overrun` = 0, the receiver
idle, and every frame the transmitter subsequently sends.

## 3. What the seeder produces

A report under `docs/reports/audit/WO-0002-mutations/`: each diff in full,
applying cleanly to the base SHA; the file and always-block touched; a
one-paragraph fidelity argument per diff, stating explicitly what the diff does
**not** change; any build-only repair and why; and anything you could not do
faithfully, said plainly. Plus a scope statement listing what you read, checked
against §1's allowlist, and your ambient-exposure disclosure.

Every hunk carries the greppable marker comment `<id> MUTATION (WO-0002)`.

**You do not run the diffs and you do not see the results.**

## 4. Mechanics and return — the orchestrator's part

One throwaway branch per mutant: `mut/wo-0002-<id>` = frozen base SHA + exactly
one diff, nothing else. **Never merged**, never rebased onto.

The suite is `bash test/run.sh` (Icarus Verilog 12.0); the unmutated control
takes about 70 seconds. **Every mutant run must carry an external wall-clock
timeout** — no bench in this suite arms a simulation watchdog, so a mutant that
starves a wait loop runs forever rather than failing. A run killed by the
timeout is relayed as such, with its partial output, and is **never** reported
as a pass or as a kill; the sealed companion's §5.6 dispositions it.

Per run, the relay to dv_lead states: the parent SHA, the mutation id, the run
id, build state, and the test step's **verbatim** output — every
`[REQ-nnn] FAIL  …` line in full, every bench's `Total: / Pass: / Fail:`
summary, and whether each bench printed `ALL CHECKS PASSED`. Not a summary: the
adjudicator scores the text, so the text is the artifact, and paraphrase
destroys the by-message discrimination this campaign is built on.

**A green run on any mutant is a campaign failure** and must be relayed
prominently, never buried in a batch summary.

## 5. Pass criteria

1. The suite goes red under every mutant that is predicted to be caught.
2. Red **in the units dv_lead named in advance, with the expected message** —
   the sealed companion's REQUIRED cells. An unnamed unit reddening, or a named
   unit reddening with the wrong message, is a **finding**, not a kill.
3. The unmutated control is green at the base SHA. **Verified, not assumed**:
   `bash test/run.sh` is green at `509173a` (609/609, exit 0, measured), and
   the freeze commit changes no compiled file —

   ```
   git diff 509173a <freeze-sha> -- rtl/ test/run.sh \
       test/tb_uart_lite.sv test/tb_uart_tick_gen.sv test/tb_uart_fifo.sv \
       test/tb_uart_tx.sv test/tb_uart_rx.sv
   ```

   must be empty. `test/wave/**`, added in the freeze commit, is not compiled
   by `test/run.sh`.

**Prediction classes** (fixed in the sealed companion at freeze; the
denominator — 609 units across five benches — never moves mid-campaign):
**REQUIRED** (must fail, in the named rows, with the named messages),
**MUST-STAY-GREEN** (any red here is a finding), **PERMITTED** (may go either
way; carries no score).

Not every class in §2 is predicted to be caught. **A class that survives is a
result, not a failure of the campaign** — it is the measurement of a gap, and
the seal names the ground for each in advance. The qualified rows cannot carry
a sign-off until the campaign is adjudicated, and `SO-uart_lite` does not issue
on one campaign alone: coverage arithmetic is the SO- packet's job.

---

## Return / verdict log

<!-- Pre-result rulings are appended here as an ADDENDUM, journal-referenced.
     The frozen seal is never edited — rulings are issued beside it. The
     unsealing itself is recorded here, not by editing the seal. -->

| round | date | event | by | ref |
|---|---|---|---|---|
| — | — | freeze: brief + seal committed, no defect exists | dv_lead | `J-dv_lead-0002` |
| 1 | 2026-08-18 | **seeding: 19 diffs authored blind** (17 sealed intents + 2 near-miss controls), all applying clean and compiling; six findings filed, two against the orchestrator, none CRITICAL | auditor | `J-auditor-0001` · `4fe6014` |
| 2 | 2026-08-18 | **operator run: 19 of 19 executed. 13 KILLED, 6 SURVIVED, 0 HANG, 0 COMPILE-FAIL.** Raw observations only — no scoring, no comparison against the seal, which this seat has not opened for this purpose | orchestrator | `J-orchestrator-0011` |

### Round 2 — the operator's raw record

Every patch applied **unmodified** to a scratch copy of `rtl/` + `test/`
outside the tree, built and run there under a 240 s wall-clock timeout, and
the scratch deleted. No mutated source was committed, and no branch carries
one. The runner is `tools/campaign_run.sh`; per-mutant logs are regenerated
by re-running it.

| id | verdict | benches reddened |
|---|---|---|
| TG-1 | KILLED | `tb_uart_tick_gen`, `tb_uart_tx` |
| TG-2 | KILLED | `tb_uart_tick_gen`, `tb_uart_tx` |
| TG-3 | KILLED | `tb_uart_tick_gen` |
| TX-1 | KILLED | `tb_uart_lite`, `tb_uart_tx` |
| TX-2 | KILLED | `tb_uart_tx` |
| TX-3 | KILLED | `tb_uart_tx` |
| TX-4 | **SURVIVED** | — |
| RX-1 | KILLED | `tb_uart_lite`, `tb_uart_rx` |
| RX-2 | KILLED | `tb_uart_rx` |
| RX-3 | **SURVIVED** | — |
| RX-4 | **SURVIVED** | — |
| FF-1 | KILLED | `tb_uart_fifo`, `tb_uart_lite` |
| FF-2 | KILLED | `tb_uart_fifo`, `tb_uart_lite` |
| LT-1 | KILLED | `tb_uart_lite` |
| LT-2 | **SURVIVED** | — |
| LT-3 | KILLED | `tb_uart_lite` |
| LT-4 | KILLED | `tb_uart_lite`, `tb_uart_tx` |
| NM-1 | **SURVIVED** | — (near-miss control) |
| NM-2 | **SURVIVED** | — (near-miss control) |

**What this table is not.** It is not a score. Which of the six survivors is
a coverage gap, which is an equivalent design the suite could not have caught,
and which was predicted to survive on a stated ground, are all questions the
sealed predictions answer — and the seat that froze them adjudicates, in round
3. A ratio computed from this table would be exactly the fold the campaign
brief forbids.

**Both near-miss controls survived**, which is the result they were authored
to produce: the campaign measures behaviour rather than reddening at any edit
to `rtl/`. Had either killed, the instrument would be the finding.

**Two items owed to the adjudicating round**, carried here so they are not
lost: the auditor's **F-06** asks for a disposition of the near-miss controls,
which sit outside the sealed surface and so have no predicted cells; and its
**F-01/F-02** (both MAJOR, both concerning the orchestrator) bear on whether
the blind held, which is a question about this campaign's validity and is
dv_lead's to rule on, not the party the findings name.
