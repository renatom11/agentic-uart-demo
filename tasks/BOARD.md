# Program Board

**Live program state.** The orchestrator updates this file in the same commit
as any state change it describes. A fresh orchestrator session rehydrates by
reading: this board → `agents/PROTOCOL.md` → `ORG_CHART.md` → journal tails of
agents with open work.

## The project

**uart_lite** — a fixed-rate 115200 baud 8N1 UART for a 50 MHz FPGA board.
Five modules, seventeen numbered requirements. Written in SystemVerilog,
simulated with Icarus Verilog 12.0.

This repository is a **proof of concept for the framework itself**: the point is
not the UART, which is deliberately small and well understood, but the record of
how it was built — specification before implementation, benches written by a
seat that could not read the design, every commit paired with its author's
journal entry and refused by a script if it is not.

Working branch: `main`. Origin: renatom11/agentic-uart-demo.
Shell provenance: renatom11/generic-agentic-fpga-org @
295f26891e60d092075bbfa97eee07881de2d5db.

## Current milestone

**M1 — first module through the loop.**

| # | State | Item |
|---|---|---|
| 1 | **DONE** | Shell seeded, two dormant seats dropped, enforcement self-test 38/38 (`fc13bb9`) |
| 2 | **DONE** | `SPEC-uart_lite.md` + 17 numbered requirements (`9d980e1`) |
| 3 | **DONE** | RTL implemented, elaborates clean under Icarus (`06c73d3`) |
| 4 | **DONE** | WO-0001 — benches written blind by tb_writer, RTL withheld (`6c8d65c`) |
| 5 | **DONE** | Suite run; all 8 failures adjudicated (`0801a2d`): 1 design defect, 2 bench defects |
| 6 | **DONE** | Blocking sim lane in CI alongside the journal check (`819ce07`) |

## Result

**609 checks, 609 pass, 0 fail.** `bash test/run.sh`, Icarus Verilog 12.0.

| bench | checks | discharges |
|---|---|---|
| tb_uart_tick_gen | 28 | REQ-005 |
| tb_uart_fifo | 13 | REQ-015 |
| tb_uart_tx | 265 | REQ-001, 002, 003, 004 |
| tb_uart_rx | 291 | REQ-006…012 incl. the 6656-check tolerance sweep |
| tb_uart_lite | 12 | REQ-014, 016, 017 |

**BUG-0001, found by a bench that had never seen the design.** `uart_tick_gen`
reloaded its counter to 1 instead of 0, so the transmitter's start bit was 433
cycles while all nine following intervals were 434. The tick *spacing* is N under
either reload value, so no interval-based check can see it — only a measurement
from the restart to the first tick. Fixed at `27104a8`.

## Open work orders

| ID | Assignee | State | Summary |
|---|---|---|---|
| WO-0001 | tb_writer | ISSUED | Self-checking benches for uart_lite from the spec alone; `rtl/**` withheld |

## Gates

| Gate | State |
|---|---|
| G0 — org ratification | Compressed by sponsor direction: the sponsor commissioned the work directly and delegated all calls to the orchestrator. Branch protection **not** configured; the append-only journal therefore holds by convention plus CI, not by server-side rule. Recorded here rather than claimed as satisfied. |
| Module-ready — uart_lite | **NOT SIGNED.** The suite is green at `7923ab8` with every failure adjudicated, which was the stated precondition — but signing also requires the two limitations below to be dispositioned, and neither is. Recorded as unsigned rather than waved through. |

## Pending sponsor decisions

None. The sponsor's standing direction is "you make all the calls", with one
stated outcome: a working testbench worth showing.

## Known limitations, stated rather than discovered later

- **No mutation campaign has been run.** Nothing establishes in general that
  these benches would catch a defect. One data point exists and it is real
  rather than seeded: the suite caught BUG-0001, a one-line off-by-one in the
  design, on its first run. That is one defect found, not a measured detection
  rate, and it is not a substitute for a campaign.
- **REQ-002 was dischargeable by a defective transmitter until this round.** The
  bench passed it 265/265 against the buggy design, because the row as written
  asked only for correct spacing between bit boundaries. A green row is not
  evidence until something has tried to make it red.
- **No synthesis.** The design has been elaborated and simulated only. REQ-017's
  area and timing claims are unverified; no vendor tool has seen this code.
- **One seat, many hats.** The specification, the RTL and the orchestration were
  authored in a single session under separate seat identities and separate
  journals. Only the benches were written under genuine blinding, by a spawned
  session that could not read `rtl/`. That is the one separation this program
  actually enforces at the session level, and it is the one that matters most.
