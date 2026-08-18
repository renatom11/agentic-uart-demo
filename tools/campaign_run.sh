#!/usr/bin/env bash
# tools/campaign_run.sh -- the operator's half of a mutation campaign.
#
#   bash tools/campaign_run.sh [outdir]
#
# For each patch in docs/reports/audit/WO-0002-mutations/, this script:
#
#   1. copies rtl/ and test/ into a THROWAWAY directory outside the tree,
#   2. applies that patch UNMODIFIED,
#   3. compiles and runs the suite there under a wall-clock timeout,
#   4. records the verdict and the first FAIL line of every bench that failed.
#
# Three disciplines are wired in rather than remembered:
#
# * The mutated source never enters the repository. It is built in a scratch
#   directory and deleted; nothing here can leave a defect on a mergeable
#   branch.
# * Every run is bounded by `timeout`. The suite has three unbounded wait
#   loops, so a defect that starves a handshake HANGS instead of failing, and
#   an unbounded runner would sit there forever. A timeout is recorded as
#   NO-VERDICT (HANG) and is never scored as a kill: the suite did not catch
#   that defect, it failed to reach a verdict about it.
# * The operator applies a table it did not compose and predicts nothing. The
#   verdicts here are raw observations; scoring them against the sealed
#   predictions is the verification lead's act, in a later round.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUT_DIR="$ROOT/docs/reports/audit/WO-0002-mutations"
OUT="${1:-$ROOT/build/campaign}"
SCRATCH="${CAMPAIGN_SCRATCH:-/tmp/wo0002-campaign}"

# Clean run measured at 69 s; 240 s is generous enough that a legitimately
# slower mutant is not mistaken for a hang, and a false HANG costs a data
# point rather than producing a wrong kill.
TIMEOUT="${CAMPAIGN_TIMEOUT:-240}"
JOBS="${CAMPAIGN_JOBS:-4}"

mkdir -p "$OUT"
rm -rf "$SCRATCH"
mkdir -p "$SCRATCH"

run_one() {
  local patch="$1"
  local id
  id="$(basename "$patch" .patch)"
  local dir="$SCRATCH/$id"
  local log="$OUT/$id.log"
  local res="$OUT/$id.result"

  mkdir -p "$dir"
  cp -r "$ROOT/rtl" "$ROOT/test" "$dir/" 2>/dev/null

  if ! (cd "$dir" && patch -p1 --batch --silent < "$patch") 2>>"$log"; then
    printf '%s\tPATCH-FAIL\t\t\n' "$id" > "$res"
    return
  fi

  # A mutant that changes nothing observable is still a mutant; record the
  # fact that its source differs, so an "identical tree" cannot masquerade
  # as a clean apply.
  local changed
  changed="$(cd "$dir" && diff -rq rtl "$ROOT/rtl" 2>/dev/null | wc -l)"

  timeout --kill-after=20 "$TIMEOUT" bash -c "cd '$dir' && bash test/run.sh" \
      > "$log" 2>&1
  local rc=$?

  local verdict benches msgs
  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    verdict="HANG"
  elif grep -q "compile failed" "$log"; then
    verdict="COMPILE-FAIL"
  elif grep -q "FAIL" "$log"; then
    verdict="KILLED"
  elif [ "$rc" -eq 0 ] && grep -q "overall status: PASS" "$log"; then
    verdict="SURVIVED"
  else
    verdict="NO-VERDICT"
  fi

  # which benches reddened, and the first failing check message in each
  benches="$(grep -oE '^!! tb_[a-z_]+' "$log" | sed 's/^!! //' | sort -u | paste -sd, -)"
  msgs="$(grep -m3 -E '^\[REQ-[0-9]+\] FAIL' "$log" | tr '\n' '|' | sed 's/|$//')"

  printf '%s\t%s\t%s\t%s\trtl_files_changed=%s\n' \
      "$id" "$verdict" "${benches:-}" "${msgs:-}" "$changed" > "$res"
  rm -rf "$dir"
}

echo "==== WO-0002 campaign: operator run ===="
echo "base:     $(cd "$ROOT" && git rev-parse --short HEAD)"
echo "timeout:  ${TIMEOUT}s per mutant, ${JOBS} at a time"
echo "scratch:  $SCRATCH (deleted per mutant)"
echo

n=0
for patch in "$MUT_DIR"/*.patch; do
  run_one "$patch" &
  n=$((n + 1))
  if [ "$((n % JOBS))" -eq 0 ]; then wait; fi
done
wait

echo "==== results ===="
printf '%-6s %-13s %s\n' ID VERDICT "BENCHES REDDENED"
for r in "$OUT"/*.result; do
  IFS=$'\t' read -r id verdict benches _ _ < "$r"
  printf '%-6s %-13s %s\n' "$id" "$verdict" "${benches:-—}"
done

echo
echo "Counts:"
cut -f2 "$OUT"/*.result | sort | uniq -c | sort -rn
echo
echo "Raw logs: $OUT/<id>.log — the scoring round reads these, not this summary."
