# ADR-0008 — Toolchain: SystemVerilog with Icarus Verilog

- **Status**: ACCEPTED
- **Date**: 2026-08-13
- **Proposed by**: architect_docs_lead
- **Accepted by**: orchestrator
- **Supersedes**: nothing

## Context

The shell is toolchain-agnostic: it lanes RTL to `rtl/**` and benches to
`test/**` and assumes no language. This program needs one decision made and
recorded before CI can exist, because CI is the authoritative build environment
(PROTOCOL §10) and cannot be written against an undecided toolchain.

The source program this shell was extracted from used Hardcaml, a hardware DSL
embedded in OCaml, elaborated to Verilog. That is not inherited here.

## Decision

**RTL is written directly in SystemVerilog-2012. Simulation is Icarus Verilog,
invoked as `iverilog -g2012`.**

Compile order is a committed artifact at `rtl/uart_lite.f`, because
`import uart_pkg::*` requires the package to precede every module that imports
it and an alphabetical glob does not.

## Alternatives considered

**Hardcaml, as the source program uses.** Rejected. The sponsor asked for
SystemVerilog explicitly, and for this repository the request is the whole
point: the shell's claim is that it is language-agnostic, and a demonstration
that reuses the source program's language demonstrates nothing about that claim.

**Verilator.** Rejected for this program, not on quality — it is faster and
lints harder. Verilator's normal mode requires a C++ harness around the design,
which means the testbench is partly C++ and partly SystemVerilog. That splits
the bench across two languages for a design this small, and it puts a layer
between the specification and the checks that a reader of this repository would
have to learn before they could audit a single assertion. Icarus runs a native
SystemVerilog testbench with no harness. Revisit if the design grows or if
lint-grade static checking becomes a gate requirement.

**A vendor simulator (Questa, VCS, Xcelium).** Rejected: licence-bound, so CI
could not run it, so no gate signature could rest on it (PROTOCOL §10).

## Consequences

- **Accepted limitation: no synthesis.** Icarus simulates; it does not
  synthesise. Any area, timing or resource claim in this program is unverified
  and must be recorded as such rather than asserted. REQ-017 of
  `docs/specs/requirements.md` is not dischargeable under this toolchain, and
  the sign-off must say so rather than quietly counting it.
- **Accepted limitation: Icarus's SystemVerilog support is partial.** It ignores
  `unique`/`priority` case qualities, which it reports and which is why the FIFO
  carries a plain `case`. Constructs that fail to elaborate must be worked
  around in the RTL rather than assumed supported.
- CI installs `iverilog` from the runner distribution's archive
  (`apt-get install -y iverilog`), per R-CI-b in the build CI template: no
  third-party archives, no source builds, and a failed install fails the job
  rather than silently skipping the lane.
- The simulation lane is its own job, not a step in another one (R-CI-a), and
  it is **blocking** from the day it lands: there is no de-gating condition to
  write, because a suite that is allowed to be red is not a gate.
