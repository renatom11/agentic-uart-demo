# WO-0002 mutation diffs

One applyable patch per mutant, for the campaign's throwaway branches. The
reasoning, fidelity arguments, detectability judgements and scope statement are
in [`../WO-0002-manifest.md`](../WO-0002-manifest.md) — this directory is the
mechanical half.

- **Base pin**: `c7762b0`. Every patch applies to that tree's `rtl/`.
- **Authored before any run executed.** No result exists for any of these.
- **Never merged.** Each patch is `[base SHA + exactly one diff]` on a throwaway
  branch `mut/wo-0002-<id>`, and every hunk carries the greppable marker
  `<id> MUTATION (WO-0002)` so a mutant can never sit unnoticed on a mergeable
  branch.

## Applying one

```
git checkout -b mut/wo-0002-TG-1 c7762b0
git apply docs/reports/audit/WO-0002-mutations/TG-1.patch    # or: patch -p1 < ...
```

## Index

| M | patch | module | file | one line |
|---|---|---|---|---|
| M-01 | `TG-1.patch` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | first tick one cycle early |
| M-02 | `TG-2.patch` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | first tick one cycle late |
| M-03 | `TG-3.patch` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | `restart` no longer suppresses `tick` |
| M-04 | `TX-1.patch` | `uart_tx` | `rtl/uart_tx.sv` | data bits MSB-first |
| M-05 | `TX-2.patch` | `uart_tx` | `rtl/uart_tx.sv` | no stop interval emitted |
| M-06 | `TX-3.patch` | `uart_tx` | `rtl/uart_tx.sv` | bit period 433 |
| M-07 | `TX-4.patch` | `uart_tx` | `rtl/uart_tx.sv` | `tx_busy` never asserts — **silently-always-pass** |
| M-08 | `RX-1.patch` | `uart_rx` | `rtl/uart_rx.sv` | sampling at the cell boundary |
| M-09 | `RX-2.patch` | `uart_rx` | `rtl/uart_rx.sv` | oversample divisor 26 |
| M-10 | `RX-3.patch` | `uart_rx` | `rtl/uart_rx.sv` | false start not rejected |
| M-11 | `RX-4.patch` | `uart_rx` | `rtl/uart_rx.sv` | one synchroniser flop |
| M-12 | `FF-1.patch` | `uart_fifo` | `rtl/uart_fifo.sv` | `full` one entry early |
| M-13 | `FF-2.patch` | `uart_fifo` | `rtl/uart_fifo.sv` | write while full overwrites oldest |
| M-14 | `LT-1.patch` | `uart_lite` | `rtl/uart_lite.sv` | `rx_overrun` not sticky |
| M-15 | `LT-2.patch` | `uart_lite` | `rtl/uart_lite.sv` | framing error writes the FIFO |
| M-16 | `LT-3.patch` | `uart_lite` | `rtl/uart_lite.sv` | `rx_valid` inverted |
| M-17 | `LT-4.patch` | `uart_lite` | `rtl/uart_tx.sv` | `tx_line` resets low |
| M-18 | `NM-1.patch` | `uart_fifo` | `rtl/uart_fifo.sv` | **near-miss control — not a defect** |
| M-19 | `NM-2.patch` | `uart_tick_gen` | `rtl/uart_tick_gen.sv` | **near-miss control — not a defect** |

## Two of these are controls, and they are not scoreable

`NM-1` and `NM-2` are equivalence-preserving edits: a local rename, and two
restructured expressions. They are argued equivalent over the whole legal
stimulus space in the manifest §4 and measured byte-identical under the seeder's
own probe. They exist so the campaign can demonstrate that it measures behaviour
rather than reddening at any edit to `rtl/**`.

**They are not among the brief's 17 intents, so the sealed predictions cannot
name them and they carry no predicted cells.** Disposition them as out-of-scoring
controls or decline to run them; scoring them against a seal that does not name
them would manufacture a "red cell outside the prediction" that means nothing.
That call is dv_lead's.

## Verification the seeder ran

All 19 patches were applied with `patch -p1` to fresh copies of the base `rtl/`
tree — copies containing `rtl/` only, never `test/` — and elaborated with
`iverilog -g2012 -f rtl/uart_lite.f` against a throwaway stub of the seeder's
own. **19/19 apply clean and compile, zero warnings, and no build-only repair was
needed by any of them.** Fidelity was checked separately against a seeder-written
probe; see the manifest §2. None of that is a suite result, and none of it is a
prediction about `test/**`.
