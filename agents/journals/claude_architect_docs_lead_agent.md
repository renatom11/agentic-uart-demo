# Journal: claude_architect_docs_lead_agent

- **Agent**: architect_docs_lead (Opus-class lead)
- **Charter**: agents/charters/architect_docs_lead.md
- **Format**: v2 — entry grammar in agents/PROTOCOL.md §4

This file is APPEND-ONLY. Content may only ever be added after the last line;
nothing above it is ever edited. Enforced by scripts/agent_commit.sh and CI.

---

---
## [J-architect_docs_lead-0001] 2026-08-12T23:35:00Z | task:none | uart_lite specified: five modules, seventeen numbered requirements, and one requirement written to say what it cannot prove

### Trigger
Orchestrator commission: specify uart_lite — a fixed-rate 115200 baud 8N1 UART
for a 50 MHz board — before any RTL exists, so that implementation and
verification can be commissioned independently against one frozen contract.

### Inputs
Sponsor's scope: a small, real, demonstrable design. No prior artifacts in this
repository; this is the first specification it has.

### Reasoning
- **The divisor arithmetic is the spine, so it goes in its own section with its
  derivations shown.** 50e6/115200 = 434.0278 and 50e6/(115200x16) = 27.1267 —
  neither is an integer, so a rounding decision has to be made and defended
  rather than assumed. DIV_TX = 434 gives +0.0064 %; DIV_OS = 27 with 16x
  oversampling gives a receive bit period of 432 and +0.4694 %. Every later
  number on the project derives from these two, so a reader who disagrees with
  the design can find the exact line to disagree with.
- **The transmit and receive bit periods are deliberately unequal** (434 vs
  432). Each is the best integer its own divider structure allows. Stating this
  explicitly in §2 stops a later reader treating the difference as a bug.
- **Sample points are specified in clock cycles, not in oversample ticks.**
  216 + 432n, tabulated for all ten samples. A specification that said "sample
  at tick 8" would be satisfied by a receiver whose tick period was wrong,
  because both the stimulus and the check would be denominated in the design's
  own broken unit. Requiring the count in clock cycles is what makes REQ-005
  and REQ-006 able to fail.
- **REQ-011's window is derived in the requirement itself**, with the rounding
  rule pinned: 3 % of 434.0278 is 13.0208, so 421.007…447.049, rounded inward
  to 422…447, twenty-six integer periods. Deriving it from the receiver's own
  432 would give a different window; a plan or a bench that re-derives it from
  432 is wrong, and the arithmetic is written here so that can be checked.
- **REQ-017 is written to state its own weakness.** A loopback test is the
  obvious demonstration and the one a reader will ask for, but transmitter and
  receiver take their timing from the same clock, so passing it is evidence
  about self-consistency, not about agreement with any real far end. The
  requirement says so in its own text and says it never discharges REQ-011. A
  requirement that overstates what its pass means is a requirement that will be
  cited later to close something it cannot close.
- Overrun policy placed at the top level rather than inside `uart_fifo` or
  `uart_rx`. The receiver cannot stall a serial line — the byte is arriving
  whether or not anyone is ready — so a `ready` on the receiver would be a
  signal that can never legitimately be low. The FIFO drops silently; the top
  level owns the sticky flag.

### Actions
Wrote docs/specs/SPEC-uart_lite.md (scope, divisor table, frame format, module
decomposition, five interface contracts, reset state) and
docs/specs/requirements.md (17 numbered rows, each with a verification method).

### Evidence
Not yet verified by execution — this is a specification, and nothing it
describes exists. Its claims become checkable when the benches cite them.

### Files-in-this-commit
- docs/specs/SPEC-uart_lite.md
- docs/specs/requirements.md

---
## [J-architect_docs_lead-0002] 2026-08-13T00:30:00Z | task:none | ADR-0008 fixes the toolchain at SystemVerilog and Icarus, and records the two things that choice gives up

### Trigger
CI cannot be written against an undecided toolchain, and CI is the authoritative
build environment under PROTOCOL §10. The decision is needed before the
simulation lane can land.

### Reasoning
- SystemVerilog directly, not Hardcaml. The sponsor asked for it, and for this
  repository the request is the point: the shell claims to be language-agnostic,
  and a demonstration that reuses the source program's language demonstrates
  nothing about that claim.
- Icarus over Verilator, and not on quality. Verilator is faster and lints
  harder, but its normal mode wants a C++ harness, which splits the bench across
  two languages and puts a layer between the specification and the checks that a
  reader would have to learn before auditing a single assertion. For a design
  this size that cost is not worth paying. Recorded with the condition that
  would reopen it: the design growing, or lint-grade static checking becoming a
  gate requirement.
- Vendor simulators rejected on licence: CI could not run one, so no gate
  signature could rest on it.

### The consequences are written down as limitations, not omitted
- **No synthesis.** Icarus does not synthesise. REQ-017's area and timing claims
  are not dischargeable under this toolchain at all. The sign-off must say so
  rather than counting the row.
- **Partial SystemVerilog support.** Icarus ignores `unique`/`priority` case
  qualities — it says so, which is how it was found — so the FIFO carries a
  plain `case`.

### Files-in-this-commit
- docs/adr/ADR-0008-toolchain.md

---
## [J-architect_docs_lead-0003] 2026-08-13T01:20:00Z | task:none | The blind bench found the specification wrong, not the design: §5.1's anchor was off by one cycle, and REQ-002 could be discharged by a transmitter with a wrong first bit

### Trigger
tb_writer returned WO-0001 with 8 of 609 checks failing, all REQ-005, all in
`uart_tick_gen`, reproducible across N = 2, 3, 27 and 434 and across both the
reset and restart paths. The finding was left red rather than adjusted to pass,
as the packet required.

### Investigation, before deciding whose fault it was
The orchestrator instrumented the design directly rather than accepting either
side's account. Measuring the transmitter — the only consumer whose requirement
fixes an absolute number — over nine low bit intervals of an all-zero byte:

| tick_gen reload value | 9 bit intervals span | 9 x 434 |
|---|---|---|
| 1 (as implemented) | **3906 cycles** | 3906 |
| 0 (the "fix" tried first) | 3907 cycles | 3906 |

The implemented design is exactly right and the attempted correction was wrong;
it added one cycle to the start bit and nothing else. That measurement decides
the question: **the RTL is correct and neither of the two defects here is in it.**

### Defect 1 — this specification, §5.1
§5.1 said "counting the cycle after reset release (or after a `restart` pulse)
as cycle 0, the k-th tick is high during cycle N·k". Measured, the design's
first tick lands at cycle N-1 under that anchor and at cycle N when cycle 0 is
the cycle in which `restart` is *sampled high*. The design is right; the
sentence was off by one. Amended to state the anchor as the sampled-high cycle,
with a note explaining why the anchor is worth a paragraph: the spacing between
ticks is N under either convention, so only a measurement taken from the restart
to the FIRST tick can tell them apart, and getting it wrong makes the first
transmit bit interval 435 cycles while every later one stays correct.

### Defect 2 — REQ-002 was dischargeable by a wrong transmitter
Found while investigating the first. REQ-002 said each of the ten bit intervals
shall be 434 cycles, "measured as the cycle count between successive `tx_line`
value-decision points". A check written to that wording measures only the
spacing between boundaries — and passes a transmitter whose first interval is
435. That is exactly the defect the reload-0 variant introduces, and the bench,
faithfully implementing the row as written, passed it 265/265. Amended to
require the first interval measured from acceptance, and to say in the row
itself that a spacing-only check does not discharge it.

### What this round is evidence of
A bench written from the specification by a session that could not read the
design found an error in the specification. That is the blinding regime doing
the thing it exists to do, on the first module, without anyone planning it.

### Files-in-this-commit
- docs/specs/SPEC-uart_lite.md
- docs/specs/requirements.md

---
## [J-architect_docs_lead-0004] 2026-08-13T02:05:00Z | task:none | Correcting J-architect_docs_lead-0003: it claimed the RTL was correct and the specification alone was at fault. The RTL was defective, and the bench that said so was right

### Trigger
Direct measurement of the transmitter's start bit, taken after 0003 was
committed.

### The correction
J-architect_docs_lead-0003 stated, in its own words: *"The implemented design is
exactly right and the attempted correction was wrong... **the RTL is correct and
neither of the two defects here is in it.**"*

**That is false.** The RTL was defective. `uart_tick_gen` reloaded its counter
to 1 instead of 0, and the transmitter's start bit was 433 clock cycles where
REQ-002 requires 434. tb_writer's eight red REQ-005 checks were correct on the
first return, and the fix landed at 27104a8.

Per PROTOCOL §5 R3 this journal is append-only: 0003 stays exactly as written,
wrong, and this entry is the correction. An entry that could be edited would
leave no evidence that the wrong conclusion was ever held, and the wrong
conclusion is the useful part of this record.

### How the error was made, since that is the transferable part
0003's measurement used byte 0x00 over nine low bit intervals and found the
total span was exactly 9 x 434 = 3906 cycles. That looked decisive. It was not:
with an all-zero byte the start bit and d0 are both low, so **there is no
transition at the boundary between them**, and the measurement constrains only
the SUM of the intervals. The defect moves one cycle from the start bit into
d0's interval, which any sum-based measurement is blind to by construction.

Re-measured with byte 0x01, where d0 = 1 forces a transition at that boundary,
the start bit is 433 cycles and every following interval is 434. That is the
whole defect, visible in one line of output.

A second error compounded it: changing the reload to 0 made the transmitter
bench go red, and 0003 read that as evidence the change was wrong. The
transmitter bench went red for an unrelated reason — its own boundary grid was
anchored on the acceptance cycle, which a registered output cannot satisfy
(adjudicated at 0801a2d). One defect's symptom was read as evidence about a
different defect.

### What survives from 0003
Its two amendments were right and stand: §5.1's anchor genuinely was off by one,
and REQ-002 genuinely was dischargeable by a transmitter with a wrong first bit
— indeed the bench passed it 265/265 against the defective design, which is that
row's own coverage gap and is now closed. What 0003 got wrong is the conclusion
it drew about where the fault lay, not the amendments it made.

### This round's amendment
§5.2 now states where the frame begins relative to acceptance: `tx_line` is
registered, so the start bit begins the cycle **after** `tx_valid & tx_ready`,
bit interval i occupies cycles `1 + i·DIV_TX` through `i·DIV_TX + DIV_TX`, and
`tx_ready` rises again at `1 + 10·DIV_TX`. That is the same class of ambiguity
as §5.1's, in the one place it had not yet been fixed, and it is what the
transmitter bench's boundary grid had guessed wrong.

### Files-in-this-commit
- docs/specs/SPEC-uart_lite.md
