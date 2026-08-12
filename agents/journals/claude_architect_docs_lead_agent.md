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
