# Journal: claude_dv_lead_agent

- **Agent**: dv_lead (Opus-class lead)
- **Charter**: agents/charters/dv_lead.md
- **Format**: v2 — entry grammar in agents/PROTOCOL.md §4

This file is APPEND-ONLY. Content may only ever be added after the last line;
nothing above it is ever edited. Enforced by scripts/agent_commit.sh and CI.

---

---
## [J-dv_lead-0001] 2026-08-13T01:55:00Z | task:none | Adjudicating WO-0001's eight red checks: one design defect, two bench defects, all three the same anchor ambiguity

### Trigger
tb_writer returned WO-0001 with 609 checks, 601 passing and 8 failing, and did
not adjust any expected value to make them pass. Adjudication is this seat's.

### Verdict on each failure
All eight failures were REQ-005 in `uart_tick_gen`, and they were **correct**:
BUG-0001 is real, and the fix landed at 27104a8. The bench was right and the
design was wrong.

Investigating it surfaced two further defects **in the benches**, both the same
mistake as the one in the specification: an event-relative anchor stated or
assumed one cycle off.

1. **`tb_uart_tick_gen`, both anchors.** `observe_tick_pattern()` labels its
   first observed posedge as cycle 0, and that posedge is the one *after* the
   reset/restart anchor. The checks compared that observation directly against
   N. Corrected by converting observation cycles into spec cycles explicitly
   (`first_tick + 1`) rather than by moving the expected value, so the anchor
   stays visible to a reader instead of being folded into a constant.
2. **`tb_uart_tx`, REQ-002 and REQ-004.** The boundary grid was anchored at
   `i * DIV_TX` from the acceptance cycle, which requires the start bit to be
   low *during* acceptance. `tx_line` is a registered output and cannot change
   in the same cycle as the input that causes it, so that anchor is
   unsatisfiable by any conforming design. Corrected to `1 + i * DIV_TX`, and
   the REQ-004 ready-rise check moved by the same one cycle.

### The finding worth keeping
One ambiguity — where cycle 0 sits relative to an event — produced three
defects, in three different artifacts, written by three different seats: the
specification's §5.1 anchor, the RTL's reload value, and the bench's boundary
grid. Each was individually plausible. None was catchable by an interval-based
check, because every one of them preserves the spacing and moves only the phase.

The rule this earns: **a timing requirement anchored to an event must state
which cycle is cycle 0 in the requirement itself, and at least one check must
measure from the anchor to the first event rather than between events.**

### A coverage gap in the suite as returned, now closed
As returned, REQ-002 measured only the interval between successive bit
boundaries. That check passes a transmitter whose first interval is wrong and
whose spacing is right — which is exactly BUG-0001. The bench passed REQ-002
265/265 against the defective design. The requirement has been amended to
require the first interval measured from acceptance, and the bench's boundary
grid now starts at the acceptance anchor, so the row is discharged by a check
that can actually fail it.

### Evidence
Full suite after all three corrections: **609 checks, 609 pass, 0 fail**,
`bash test/run.sh` exit 0, Icarus 12.0.

| bench | checks | result |
|---|---|---|
| tb_uart_tick_gen | 28 | pass (was 20/28) |
| tb_uart_fifo | 13 | pass |
| tb_uart_tx | 265 | pass |
| tb_uart_rx | 291 | pass, incl. REQ-011 sweep P=422..447 x 256 bytes = 6656 checks |
| tb_uart_lite | 12 | pass |

### Note on who wrote what
The corrections in this commit are mine, not tb_writer's. They were made by a
seat that has read the RTL, so they are not blind work and are not committed
under the blind seat's name. tb_writer's return is committed unmodified at
6c8d65c; this commit is the adjudication on top of it. An earlier attempt staged
both together under tb_writer, which would have misrepresented what the blind
session produced; it was reset before it was pushed.

### Files-in-this-commit
- test/tb_uart_tick_gen.sv
- test/tb_uart_tx.sv
