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

**Status: RETURNED by tb_writer.** Full reasoning and evidence in
`agents/journals/workers/claude_tb_writer_agent.md`, entry `J-tb_writer-0001`.
Summary:

**Deliverables.** `test/tb_uart_lite.sv` (REQ-014, REQ-016, REQ-017;
REQ-013 explicitly skipped as inspection-only), `test/tb_uart_tick_gen.sv`
(REQ-005), `test/tb_uart_fifo.sv` (REQ-015), `test/tb_uart_tx.sv`
(REQ-001..REQ-004), `test/tb_uart_rx.sv` (REQ-006..REQ-012), `test/run.sh`.
`bash test/run.sh` compiles and runs all five with Icarus Verilog 12.0.

**Results:** 609 checks total, 601 pass, 8 fail. Per bench: tb_uart_lite
12/12, tb_uart_tick_gen 20/28 (8 FAIL, see below), tb_uart_fifo 13/13,
tb_uart_tx 265/265, tb_uart_rx 291/291 (includes REQ-011's full 6656-check
P=422..447 x 256-byte sweep, 0 mismatches, driven entirely by an
independent bench-model transmitter that never instantiates uart_tx, per
this packet's constraint #1). `bash test/run.sh` exits 1 because of the
tick_gen failures below.

**Suspected design defect (REQ-005, uart_tick_gen) -- left red, not
adjusted.** The first tick after both a reset release and a restart pulse
lands at cycle N-2, not cycle N as REQ-005's "the k-th tick is high during
cycle N.k" (k=1,2,...) requires -- reproducible and exact across N=2,3,27,
434 and both trigger types; the spacing between consecutive ticks (exactly
N cycles) and the never-two-consecutive property both check out fine, so
the defect is isolated to phase/anchor, not rate. Exact FAIL lines and the
derivation are in the journal entry's Evidence section. Recommend dv_lead
triage into a BUG- packet if confirmed.

**Spec-wording tension (not adjudicated by this bench):** REQ-005 says
"cycle after ... a restart pulse" is cycle 0; SS5.3 says of the same
mechanism "that cycle is cycle 0 of the frame" (the pulse cycle itself).
This bench tested REQ-005's literal wording only. Recommend
architect_docs_lead reconcile.

**REQ-006 coverage gap, declared, not silent:** this bench could not
reliably isolate the individual per-bit sample-cycle claims (216, 648, ...,
4104) via black-box bracketing -- three different bracketing techniques
produced three mutually inconsistent apparent boundaries, read as a
methodological confound (not three separate timing facts), so no per-cycle
verdict is asserted rather than guessing which one to trust. What IS
asserted and passes: an end-to-end elapsed-cycle bound from the falling
edge to rx_strobe/rx_frame_err, tight enough to catch a grossly wrong
sample grid, plus REQ-007/REQ-011's exhaustive sweeps corroborating correct
per-cell sampling order and content. See journal for the full account and a
recommendation (possible debounce/hysteresis in the confirm/false-start
path that this bench's bracketing didn't model) for whoever investigates
further with RTL access.

**REQ-007 ambiguity:** "nominal sender bit period" is not defined in either
spec file. This bench used DIV_TX=434 (the transmit divider). SPEC-
uart_lite.md SS2 also computes a distinct 432-cycle receive bit period and
never says which applies here. Recommend architect_docs_lead clarify.

**Independence disclosure:** during pre-charter orientation (before this
worker had located the WO- or charter), an `ls -la` across the workspace
listed `rtl/`'s filenames, byte sizes, and mtimes (no content read). Full
disclosure and this worker's reasoning for treating it as low-severity and
continuing are in the journal entry's Inputs section. Flagged per charter
SS7 for dv_lead/the auditor to disposition -- not this worker's call.

**Confirmed:** no RTL source content was read at any point (see disclosure
above for the one filenames/sizes/mtimes exposure). All expected values in
all five bench files trace to SPEC-uart_lite.md / requirements.md citations
in each file's own header comment.
