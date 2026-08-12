# WO-0001 — benches for uart_lite, written blind

| Field | Value |
|---|---|
| Status | ISSUED |
| Issued by | orchestrator |
| Assigned to | tb_writer |
| Read scope | `docs/specs/SPEC-uart_lite.md`, `docs/specs/requirements.md` |
| Write scope | `test/**` |
| Blocked read | **`rtl/**` — deliberately withheld** |

## Deliverable

A self-checking SystemVerilog testbench under `test/`, plus `test/run.sh`,
discharging as many of REQ-001…REQ-017 as simulation can reach.

## Why the RTL is withheld

This packet omits the design under test by design. A bench written by a seat
that has read the implementation tends to assert what the implementation does
rather than what the specification requires, and a suite built that way passes
whether or not the design is correct. The blinding is the only thing that makes
a green suite mean something.

The design exists and is committed at 06c73d3. It is withheld from the
assignee, not absent.

## Specific constraints carried into the packet

1. **REQ-011 stimulus must be independent.** The far-end tolerance sweep must be
   driven by a bench-model transmitter the assignee writes from the
   specification, parameterised on the sender bit period P. It must **not** use
   the DUT's own transmitter: a receiver checked against its own transmitter
   shares a time base with its stimulus and can only demonstrate that the design
   agrees with itself.
2. **REQ-005 must be checked in clock cycles, never in oversample ticks.** A
   check denominated in the design's own tick is satisfied by a design whose
   tick period is wrong.
3. **A failing check is a legitimate return.** The assignee is instructed not to
   adjust an expected value to make a check pass. If a check fails, either the
   test is wrong against the specification — fix the test, and say what was
   wrong — or the design is wrong, in which case the test stays red and the
   failure is reported with expected vs actual.

## Return log

*(pending)*
