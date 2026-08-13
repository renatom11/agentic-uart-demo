# Journal: claude_rtl_lead_agent

- **Agent**: rtl_lead (Opus-class lead)
- **Charter**: agents/charters/rtl_lead.md
- **Format**: v2 — entry grammar in agents/PROTOCOL.md §4

This file is APPEND-ONLY. Content may only ever be added after the last line;
nothing above it is ever edited. Enforced by scripts/agent_commit.sh and CI.

---

---
## [J-rtl_lead-0001] 2026-08-13T00:05:00Z | task:none | uart_lite implemented in SystemVerilog from the frozen contract: six files, 249 lines, elaborating clean

### Trigger
Orchestrator commission: implement uart_lite to SPEC-uart_lite.md. The
specification and its seventeen numbered requirements were committed at 9d980e1
before this work began; no RTL existed in the repository until this commit.

### Inputs
- docs/specs/SPEC-uart_lite.md §2 (divisor arithmetic), §5 (five interface
  contracts), §6 (reset state).
- docs/specs/requirements.md REQ-001 … REQ-017.
- Toolchain: Icarus Verilog 12.0, installed this session.

### Reasoning
- **The tick generator reloads to 1, not 0, on restart.** This is the one piece
  of arithmetic in the design that is easy to get wrong by one and impossible to
  notice afterwards. With a reload to 0 the first tick lands N-1 cycles after
  the restart, which would put every receive sample one cycle early and every
  transmit bit interval one cycle short. Reloading to 1 puts the k-th tick at
  exactly cycle N·k measured from the restart cycle, which is what SPEC §5.1
  requires and what REQ-005 checks in clock cycles.
- **Every divisor lives in uart_pkg and nowhere else.** No module declares 434
  or 27 locally. A constant duplicated into two modules is a constant that can
  be changed in one of them.
- **The receiver samples on the synchronised line, never on the pin.** rx_line
  feeds s1 → s2, and only s2 is read by the sampling logic and the edge
  detector. The third flop s2_d exists solely to detect the falling edge; it is
  a delayed copy of s2, not a third synchroniser stage.
- **A framing error never writes the FIFO.** The FIFO's write enable is
  rx_strobe alone, and SPEC §5.3 makes rx_strobe and rx_frame_err mutually
  exclusive, so a bad frame cannot enter the queue.
- **The overrun flag is the top level's, not the FIFO's.** The FIFO drops a
  write while full and raises nothing; uart_lite latches rx_overrun on
  rx_strobe & full. A receiver cannot stall a serial line — the byte arrives
  whether or not anyone is ready — so there is no honest `ready` to give the
  receiver.
- **Compile order is a committed artifact.** `import uart_pkg::*` means the
  package must precede every module that imports it, and an alphabetical glob
  puts uart_lite.sv before uart_pkg.sv and fails. Discovered by doing exactly
  that. The order now lives in rtl/uart_lite.f rather than in a shell history.

### Actions
Wrote rtl/uart_pkg.sv, uart_tick_gen.sv, uart_tx.sv, uart_rx.sv, uart_fifo.sv,
uart_lite.sv and the compile-order list rtl/uart_lite.f.

### Evidence
`iverilog -g2012 -Wall -o /tmp/elab.out -f rtl/uart_lite.f` → exit 0, no
warnings. Elaboration only: nothing here has been simulated, and no claim about
behaviour is made by this commit. The benches that will grade it are being
written from the specification by a seat that cannot read these files.

### Files-in-this-commit
- rtl/uart_fifo.sv
- rtl/uart_lite.f
- rtl/uart_lite.sv
- rtl/uart_pkg.sv
- rtl/uart_rx.sv
- rtl/uart_tick_gen.sv
- rtl/uart_tx.sv

---
## [J-rtl_lead-0002] 2026-08-13T01:45:00Z | task:none | BUG-0001: the tick generator reloaded to 1 instead of 0, making the start bit 433 cycles while every following interval was 434

### Trigger
tb_writer returned WO-0001 with 8 of 609 checks failing, all REQ-005, all in
uart_tick_gen, reproducible across N = 2, 3, 27 and 434 and across both the
reset and the restart path. The bench left them red rather than adjusting the
expected values, as its packet required.

### The defect
`uart_tick_gen` reloaded its counter to 1 on `rst || restart`. The reload cycle
is itself consumed by the counter, so the first tick landed one cycle early;
every subsequent tick was correct. One line:

    if (rst || restart) begin cnt <= CW'(1);   // wrong
    if (rst || restart) begin cnt <= '0;       // right

### Why it survived until a bench measured it
The **spacing** between ticks is exactly N under both reload values. Only a
measurement taken from the restart to the FIRST tick can separate them, and no
interval-based check can. Measured on the transmitter with byte 0x01, so that
d0 = 1 forces a real transition at the start/d0 boundary:

| reload | start bit | d0 | d1 |
|---|---|---|---|
| 1 (defective) | **433 cycles** | 434 | 434 |
| 0 (fixed) | **434 cycles** | 434 | 434 |

An all-zero byte cannot see this at all: with start and d0 both low there is no
transition at the boundary, and the total low span is the SUM of the intervals,
which the defect leaves unchanged in aggregate. My first attempt to measure this
used 0x00 and concluded the design was correct. It was not.

### A wrong turn, recorded because the record is the point
On the first pass I changed the reload to 0, saw the transmitter bench go red,
and reverted it — concluding the RTL was right and the specification was wrong.
That conclusion was wrong and I published it in J-architect_docs_lead-0003. The
transmitter bench went red for an unrelated reason (its boundary grid was
anchored on the acceptance cycle, which a registered output cannot satisfy), and
I read a second defect's symptom as evidence about the first. What settled it
was measuring the start bit directly rather than reasoning about it.

### Evidence
- `iverilog -g2012 -Wall -f rtl/uart_lite.f` — elaborates clean.
- Start-bit width measured directly at 434 cycles; d0 and d1 at 434.
- Full suite after the fix: **609 checks, 609 pass, 0 fail**, exit 0.
- tb_uart_tick_gen alone: 28/28, where it was 20/28 before.

### Files-in-this-commit
- rtl/uart_tick_gen.sv
