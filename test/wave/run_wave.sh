#!/usr/bin/env bash
# test/wave/run_wave.sh -- compiles and runs the five waveform vignettes.
#
# Runnable from the repository root as: bash test/wave/run_wave.sh
#
# THESE ARE NOT TESTS. Each vignette stages one short, deliberately chosen
# scenario and dumps a reader-sized VCD to build/wave/. They contribute ZERO
# checks to the DV suite, they are not compiled by test/run.sh, and a green run
# here is not evidence about the design. The suite is:
#
#     bash test/run.sh            # 609 checks, the thing that judges the RTL
#
# and it is deliberately kept separate from this script. If a vignette ever
# starts asserting, it belongs in test/ as a bench and in the suite's count,
# not here.
#
# Structure mirrors test/run.sh (same compile line, same per-bench log layout)
# so the two are recognisably the same shape to a reader. The differences are
# deliberate: no FAIL/ALL-CHECKS-PASSED grep, because there is nothing to pass
# or fail; and a size report, because VCD size is the constraint that keeps a
# vignette readable.
#
# Outputs, ALL generated and ALL gitignored (.gitignore covers build/ and
# *.vcd -- verify with `git check-ignore -v build/wave/wv_tx.vcd`):
#   build/wave/<name>.out          compiled simulation
#   build/wave/<name>.log          the vignette's own description lines
#   build/wave/<name>.vcd          the waveform, for GTKWave or any VCD viewer
#
# Viewing:  gtkwave build/wave/wv_tx.vcd

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

WAVE_DIR="build/wave"
mkdir -p "$WAVE_DIR"

IVERILOG="iverilog -g2012 -f rtl/uart_lite.f"

# Advisory ceiling. A vignette that outgrows this has stopped being a vignette:
# the remedy is to cut the scenario, never to cut the signals a reader needs.
SIZE_WARN_BYTES=204800   # 200 KiB

overall_status=0

run_vignette() {
  local name="$1"
  local src="test/wave/${name}.sv"
  local out="$WAVE_DIR/${name}.out"
  local log="$WAVE_DIR/${name}.log"
  local vcd="$WAVE_DIR/${name}.vcd"

  echo "==== compiling ${name} (${src}) ===="
  if ! $IVERILOG "$src" -o "$out" 2>&1 | tee "$WAVE_DIR/${name}.compile.log"; then
    echo "!! compile failed for ${name}"
    overall_status=1
    return
  fi
  if [ ! -f "$out" ]; then
    echo "!! compile did not produce ${out}"
    overall_status=1
    return
  fi

  echo "==== running ${name} ===="
  vvp "$out" | tee "$log"
  local vvp_status=${PIPESTATUS[0]}
  if [ "$vvp_status" -ne 0 ]; then
    echo "!! ${name}: vvp exited nonzero (${vvp_status})"
    overall_status=1
    return
  fi

  if [ ! -s "$vcd" ]; then
    echo "!! ${name}: no VCD written to ${vcd}"
    overall_status=1
    return
  fi

  local bytes
  bytes=$(wc -c < "$vcd" | tr -d ' ')
  printf '     %-14s %8s bytes  %s\n' "$name" "$bytes" "$vcd"
  if [ "$bytes" -gt "$SIZE_WARN_BYTES" ]; then
    echo "!! ${name}: VCD is ${bytes} bytes, over the ${SIZE_WARN_BYTES}-byte readability ceiling"
    echo "   -- cut the scenario, not the signal list."
    overall_status=1
  fi
}

run_vignette "wv_tick_gen"
run_vignette "wv_tx"
run_vignette "wv_rx"
run_vignette "wv_fifo"
run_vignette "wv_lite"

echo
echo "==== VCD sizes ===="
ls -l "$WAVE_DIR"/*.vcd 2>/dev/null | awk '{printf "     %8s bytes  %s\n", $5, $9}'
echo
echo "==== vignettes: $([ $overall_status -eq 0 ] && echo OK || echo PROBLEM) ===="
echo "     These are demonstrations, not checks. The suite is: bash test/run.sh"
exit $overall_status
