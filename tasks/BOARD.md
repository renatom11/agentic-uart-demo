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
| 4 | **OPEN** | WO-0001 — benches written blind by tb_writer, RTL withheld |
| 5 | OPEN | Run the suite; adjudicate every failure as test-fault or design-fault |
| 6 | OPEN | CI: run the suite on every push alongside the journal check |

## Open work orders

| ID | Assignee | State | Summary |
|---|---|---|---|
| WO-0001 | tb_writer | ISSUED | Self-checking benches for uart_lite from the spec alone; `rtl/**` withheld |

## Gates

| Gate | State |
|---|---|
| G0 — org ratification | Compressed by sponsor direction: the sponsor commissioned the work directly and delegated all calls to the orchestrator. Branch protection **not** configured; the append-only journal therefore holds by convention plus CI, not by server-side rule. Recorded here rather than claimed as satisfied. |
| Module-ready — uart_lite | NOT OPEN. Requires the suite green at a stated SHA with every failure adjudicated. |

## Pending sponsor decisions

None. The sponsor's standing direction is "you make all the calls", with one
stated outcome: a working testbench worth showing.

## Known limitations, stated rather than discovered later

- **No mutation campaign has been run.** Nothing yet establishes that these
  benches would catch a defect; a green suite is evidence the design meets the
  checks written, not that the checks are searching.
- **No synthesis.** The design has been elaborated and simulated only. REQ-017's
  area and timing claims are unverified; no vendor tool has seen this code.
- **One seat, many hats.** The specification, the RTL and the orchestration were
  authored in a single session under separate seat identities and separate
  journals. Only the benches were written under genuine blinding, by a spawned
  session that could not read `rtl/`. That is the one separation this program
  actually enforces at the session level, and it is the one that matters most.
