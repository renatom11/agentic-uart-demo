#!/usr/bin/env bash
# test/run.sh -- compiles and runs the uart_lite DV suite.
#
# Runnable from the repository root as: bash test/run.sh
#
# Deliverable #1 (tb_uart_lite.sv) is compiled with exactly the command
# WO-0001 specifies. The satellite benches (tb_uart_tick_gen.sv,
# tb_uart_fifo.sv, tb_uart_tx.sv, tb_uart_rx.sv) are compiled and run the
# same way, each to its own build/ output, per WO-0001 deliverable #3
# ("Separate small testbenches are fine if that is cleaner ... driven by the
# same runner").
#
# Exits nonzero if any simulation reports a failure (each bench's own
# $fatal already sets vvp's exit code on a FAIL; this script also verifies
# that with a final grep-based check so a silently-crashed run cannot pass).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

IVERILOG="iverilog -g2012 -f rtl/uart_lite.f"

overall_status=0

run_bench() {
  local name="$1"
  local src="$2"
  local out_name="${3:-${name}.out}"
  local out="$BUILD_DIR/${out_name}"
  local log="$BUILD_DIR/${name}.log"

  echo "==== compiling ${name} (${src}) ===="
  if ! $IVERILOG "$src" -o "$out" 2>&1 | tee "$BUILD_DIR/${name}.compile.log"; then
    echo "!! compile failed for ${name}"
    overall_status=1
    return
  fi
  if [ ! -s "$out" ]; then
    # iverilog with no errors still exits 0 even if it printed nothing to
    # stderr; guard against a missing output file just in case.
    if [ ! -f "$out" ]; then
      echo "!! compile did not produce ${out}"
      overall_status=1
      return
    fi
  fi

  echo "==== running ${name} ===="
  vvp "$out" | tee "$log"
  local vvp_status=${PIPESTATUS[0]}

  if [ "$vvp_status" -ne 0 ]; then
    echo "!! ${name}: vvp exited nonzero (${vvp_status})"
    overall_status=1
  fi
  if grep -q "FAIL" "$log"; then
    echo "!! ${name}: at least one FAIL line in output"
    overall_status=1
  fi
  if ! grep -q "ALL CHECKS PASSED" "$log"; then
    echo "!! ${name}: did not print ALL CHECKS PASSED (crashed or never finished?)"
    overall_status=1
  fi
}

# tb_uart_lite.sv compiles to build/tb.out -- exactly the path WO-0001
# specifies for the primary deliverable's compile command.
run_bench "tb_uart_lite"     "test/tb_uart_lite.sv"      "tb.out"
run_bench "tb_uart_tick_gen" "test/tb_uart_tick_gen.sv"
run_bench "tb_uart_fifo"     "test/tb_uart_fifo.sv"
run_bench "tb_uart_tx"       "test/tb_uart_tx.sv"
run_bench "tb_uart_rx"       "test/tb_uart_rx.sv"

echo
echo "==== overall status: $([ $overall_status -eq 0 ] && echo PASS || echo FAIL) ===="
exit $overall_status
