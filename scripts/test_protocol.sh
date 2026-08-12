#!/usr/bin/env bash
# test_protocol.sh — scenario suite proving agent_commit.sh and
# check_journals.sh enforce the commit protocol (agents/PROTOCOL.md §5).
# Builds a scratch repo in a temp dir; never touches the real repo.
#
# Usage: scripts/test_protocol.sh

set -euo pipefail
REPO_ROOT=$(git rev-parse --show-toplevel)
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

PASS=0 FAIL=0

say()  { printf '%s\n' "$*"; }
ok()   { PASS=$((PASS + 1)); say "  PASS: $*"; }
bad()  { FAIL=$((FAIL + 1)); say "  FAIL: $*"; }

# expect_ok / expect_fail run a command and check its exit status.
expect_ok()   { local d="$1"; shift; if "$@" > /dev/null 2>&1; then ok "$d"; else bad "$d (unexpectedly rejected)"; fi; }
# expect_fail asserts BOTH that the command failed AND that it failed for the
# named reason — a non-zero exit alone would let a scenario pass on an
# unrelated rejection (AUD-0001-F1).
expect_fail() {
  local d="$1" pat="$2"; shift 2
  local out
  if out=$("$@" 2>&1); then
    bad "$d (unexpectedly accepted)"
  elif [ -n "$pat" ] && ! printf '%s\n' "$out" | grep -qE "$pat"; then
    bad "$d (rejected, but for the wrong reason: $(printf '%s\n' "$out" | grep -i 'VIOLATION\|fatal' | tail -1))"
  else
    ok "$d"
  fi
}

# ---- scratch repo -----------------------------------------------------------
cd "$SANDBOX"
git init -q -b scratch .
git config user.email test@example.invalid
git config user.name protocol-test
mkdir -p scripts
cp "$REPO_ROOT"/scripts/policy.sh "$REPO_ROOT"/scripts/agent_commit.sh \
   "$REPO_ROOT"/scripts/check_journals.sh scripts/
chmod +x scripts/*.sh
mkdir -p agents/journals/workers agents/handoffs rtl docs/reports/audit test

seed_journal() { # path agent
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<EOF
# Journal: claude_$2_agent
Charter: agents/charters/$2.md
Format: v1 (agents/PROTOCOL.md §4). Append-only below the --- line.
---
EOF
}

seed_volume() { # path agent volnum prevpath prevsha
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<EOF
# Journal: claude_$2_agent
Charter: agents/charters/$2.md
Format: v1 (agents/PROTOCOL.md §4). Append-only below the --- line.
- **Volume**: $3
- **Continues-from**: $4
- **Previous-volume-sha256**: $5
---
EOF
}

entry() { # agent NNNN title files...
  local agent="$1" num="$2" title="$3"; shift 3
  cat <<EOF

## [J-$agent-$num] 2026-08-01T00:00:00Z | task:none | $title
### Trigger
test scenario
### Inputs
none
### Reasoning
test reasoning
### Actions
test actions
### Evidence
none
### Outcome
done
### Open-questions
none
### Files-in-this-commit
EOF
  if [ $# -eq 0 ]; then
    echo "- (none)"
  else
    local f; for f in "$@"; do echo "- $f"; done
  fi
}

J_ORCH=agents/journals/claude_orchestrator_agent.md
J_RTL=agents/journals/claude_rtl_lead_agent.md
J_AUD=agents/journals/claude_auditor_agent.md

# ---- S1: bootstrap commit (work + own entry + foreign seeds) ----------------
say "S1: bootstrap commit with foreign journal seeds"
seed_journal "$J_ORCH" orchestrator
seed_journal "$J_RTL" rtl_lead
seed_journal "$J_AUD" auditor
echo hello > README.md
entry orchestrator 0001 "bootstrap" README.md \
  scripts/agent_commit.sh scripts/check_journals.sh scripts/policy.sh \
  "$J_RTL" "$J_AUD" >> "$J_ORCH"
git add -A
expect_ok "bootstrap commit accepted" \
  scripts/agent_commit.sh --agent orchestrator --entry J-orchestrator-0001 --work-order none -m "bootstrap"

# ---- S2: work without journal -----------------------------------------------
say "S2: work without journal append"
echo x > rtl/mod.sv
git add rtl/mod.sv
expect_fail "work-only commit rejected (R2)" "R2" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0001 --work-order WO-0001 -m "no journal"
git reset -q

# ---- S3: valid rtl_lead commit ----------------------------------------------
say "S3: valid rtl_lead commit"
entry rtl_lead 0001 "add module" rtl/mod.sv >> "$J_RTL"
git add rtl/mod.sv "$J_RTL"
expect_ok "rtl_lead commit accepted" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0001 --work-order WO-0001 -m "add module"

# ---- S4: journal tamper (edit above EOF) ------------------------------------
say "S4: tampering with an existing journal entry"
sed -i 's/test reasoning/REVISED HISTORY/' "$J_RTL"
entry rtl_lead 0002 "tamper attempt" rtl/mod.sv >> "$J_RTL"
echo y >> rtl/mod.sv
git add rtl/mod.sv "$J_RTL"
expect_fail "non-append journal edit rejected (R3)" "R3" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0002 --work-order WO-0001 -m "tamper"
git reset -q; git checkout -q HEAD -- "$J_RTL" rtl/mod.sv

# ---- S5: files-list mismatch ------------------------------------------------
say "S5: Files-in-this-commit mismatch"
echo y >> rtl/mod.sv
echo z > rtl/other.sv
entry rtl_lead 0002 "claims one file, stages two" rtl/mod.sv >> "$J_RTL"
git add rtl/mod.sv rtl/other.sv "$J_RTL"
expect_fail "files-list mismatch rejected (R4)" "R4" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0002 --work-order WO-0001 -m "mismatch"
git reset -q; git checkout -q -- "$J_RTL" rtl/mod.sv; rm -f rtl/other.sv

# ---- S6: path isolation -----------------------------------------------------
say "S6: rtl_lead staging a test file"
echo t > test/mod_test.sv
entry rtl_lead 0002 "rtl touches tests" test/mod_test.sv >> "$J_RTL"
git add test/mod_test.sv "$J_RTL"
expect_fail "rtl_lead writing test/ rejected (R7)" "R7" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0002 --work-order WO-0001 -m "cross-scope"
git reset -q; git checkout -q -- "$J_RTL"; rm -f test/mod_test.sv

say "S6b: auditor staging outside docs/reports/audit/"
echo a > rtl/hack.sv
entry auditor 0001 "auditor fixes code" rtl/hack.sv >> "$J_AUD"
git add rtl/hack.sv "$J_AUD"
expect_fail "auditor writing rtl/ rejected (R7)" "R7" \
  scripts/agent_commit.sh --agent auditor --entry J-auditor-0001 --work-order none -m "auditor-fix"
git reset -q; git checkout -q -- "$J_AUD"; rm -f rtl/hack.sv

# ---- S7: non-monotonic entry id ---------------------------------------------
say "S7: non-monotonic entry number"
echo w >> rtl/mod.sv
entry rtl_lead 0005 "skips ahead" rtl/mod.sv >> "$J_RTL"
git add rtl/mod.sv "$J_RTL"
expect_fail "entry 0005 after 0001 rejected (R5)" "R5" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0005 --work-order WO-0001 -m "skip"
git reset -q; git checkout -q -- "$J_RTL" rtl/mod.sv

# ---- S8: modifying another agent's journal ----------------------------------
say "S8: commit touching a foreign journal with entries"
echo w >> rtl/mod.sv
entry rtl_lead 0002 "also edits orchestrator journal" rtl/mod.sv >> "$J_RTL"
echo "sneaky line" >> "$J_ORCH"
git add rtl/mod.sv "$J_RTL" "$J_ORCH"
expect_fail "foreign journal modification rejected (R8)" "R8" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0002 --work-order WO-0001 -m "sneak"
git reset -q; git checkout -q -- "$J_RTL" "$J_ORCH" rtl/mod.sv

# ---- S9: journal-only commit ------------------------------------------------
say "S9: journal-only commit"
entry rtl_lead 0002 "investigation notes, no work" >> "$J_RTL"
git add "$J_RTL"
expect_ok "journal-only commit accepted" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0002 --work-order none -m "notes" --journal-only

# ---- S10: range checker over accumulated history ----------------------------
say "S10: check_journals.sh over the whole scratch history"
expect_ok "range check passes on protocol-compliant history" \
  scripts/check_journals.sh --all

# ---- S11: range checker catches a hand-made bad commit ----------------------
say "S11: hand-made non-compliant commit is caught by CI checker"
echo bad > rtl/bad.sv
git add rtl/bad.sv
git commit -q -m "raw commit, no protocol"
expect_fail "raw git commit caught by check_journals.sh" "R2|R6" \
  scripts/check_journals.sh --all
git reset -q --hard HEAD~1

# ---- S12: history rewrite of a journal is caught ----------------------------
say "S12: rewriting journal history is caught by range check"
git checkout -q -b rewrite
sed -i 's/test reasoning/SCRUBBED/' "$J_ORCH"
entry orchestrator 0002 "well-formed entry riding a scrubbed journal" >> "$J_ORCH"
git add "$J_ORCH"
# Trailers are deliberately well-formed so R6 cannot fire first — this must be
# caught by the append-only byte-prefix check (R3) and nothing else.
git commit -q -F - <<'MSG'
scrub with valid trailers

Agent: orchestrator
Work-Order: none
Journal-Entry: J-orchestrator-0002
Journal-Only: true
MSG
expect_fail "journal rewrite caught by append-only check (R3)" "R3" scripts/check_journals.sh --all
git checkout -q scratch
git branch -q -D rewrite

# ---- S13: foreign journal seed that already contains entries ----------------
say "S13: foreign seed containing entries"
J_DV=agents/journals/claude_dv_lead_agent.md
seed_journal "$J_DV" dv_lead
entry dv_lead 0001 "smuggled entry inside a seed" >> "$J_DV"
echo n1 > docs/reports/audit/note.md
entry auditor 0001 "audit note with dirty seed" docs/reports/audit/note.md "$J_DV" >> "$J_AUD"
git add docs/reports/audit/note.md "$J_DV" "$J_AUD"
expect_fail "entry-bearing foreign seed rejected (R8)" "R8" \
  scripts/agent_commit.sh --agent auditor --entry J-auditor-0001 --work-order none -m "dirty seed"
git reset -q; git checkout -q -- "$J_AUD"; rm -f "$J_DV" docs/reports/audit/note.md

# ---- S14: journal deletion --------------------------------------------------
say "S14: staged journal deletion"
git rm -q -f "$J_RTL"
entry orchestrator 0002 "delete a journal" "$J_RTL" >> "$J_ORCH"
git add "$J_ORCH"
expect_fail "journal deletion rejected (R3)" "R3" \
  scripts/agent_commit.sh --agent orchestrator --entry J-orchestrator-0002 --work-order none -m "delete"
git reset -q --hard HEAD

# ---- S15: two entry headers in one append -----------------------------------
say "S15: two entries appended in one commit"
echo m >> rtl/mod.sv
entry rtl_lead 0003 "first of two" rtl/mod.sv >> "$J_RTL"
entry rtl_lead 0004 "second of two" >> "$J_RTL"
git add rtl/mod.sv "$J_RTL"
expect_fail "multi-entry append rejected (R5)" "exactly one new entry" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0003 --work-order WO-0001 -m "two entries"
git reset -q; git checkout -q -- "$J_RTL" rtl/mod.sv

# ---- S16: --entry does not match the appended header ------------------------
say "S16: trailer/entry vs appended-header mismatch"
echo m >> rtl/mod.sv
entry rtl_lead 0003 "header says 0003" rtl/mod.sv >> "$J_RTL"
git add rtl/mod.sv "$J_RTL"
expect_fail "mismatched --entry rejected (R6)" "does not match --entry" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0004 --work-order WO-0001 -m "mismatch"
git reset -q; git checkout -q -- "$J_RTL" rtl/mod.sv

# ---- S17: --journal-only with staged work products --------------------------
say "S17: journal-only flag with work staged"
echo m >> rtl/mod.sv
entry rtl_lead 0003 "claims journal-only" >> "$J_RTL"
git add rtl/mod.sv "$J_RTL"
expect_fail "journal-only with work rejected (R2)" "journal-only" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0003 --work-order none -m "jo" --journal-only
git reset -q; git checkout -q -- "$J_RTL" rtl/mod.sv

# ---- S18: entry missing Files-in-this-commit section ------------------------
say "S18: entry without Files-in-this-commit"
echo m >> rtl/mod.sv
cat >> "$J_RTL" <<'EOF'

## [J-rtl_lead-0003] 2026-08-01T00:00:00Z | task:none | no files section
### Trigger
x
### Reasoning
x
EOF
git add rtl/mod.sv "$J_RTL"
expect_fail "missing files section rejected (R4)" "R4" \
  scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0003 --work-order none -m "nofiles"
git reset -q; git checkout -q -- "$J_RTL" rtl/mod.sv

# ---- S19: architect deny-inside-allow ordering ------------------------------
say "S19: architect_docs_lead staging docs/reports/audit/"
J_ARCH=agents/journals/claude_architect_docs_lead_agent.md
seed_journal "$J_ARCH" architect_docs_lead
echo x > docs/reports/audit/fake.md
entry architect_docs_lead 0001 "architect writes into audit dir" docs/reports/audit/fake.md >> "$J_ARCH"
git add docs/reports/audit/fake.md "$J_ARCH"
expect_fail "architect blocked from docs/reports/audit (R7)" "R7" \
  scripts/agent_commit.sh --agent architect_docs_lead --entry J-architect_docs_lead-0001 --work-order none -m "deny-order"
git reset -q; rm -f "$J_ARCH" docs/reports/audit/fake.md

# ---- S20: worker may stage its WO- Return log -------------------------------
say "S20: worker commit touching agents/handoffs/"
J_TBW=agents/journals/workers/claude_tb_writer_agent.md
seed_journal "$J_TBW" tb_writer
echo bench > test/bench.sv
echo "RETURNED" > agents/handoffs/WO-0002_bench.md
entry tb_writer 0001 "bench + WO return log" test/bench.sv agents/handoffs/WO-0002_bench.md >> "$J_TBW"
git add test/bench.sv agents/handoffs/WO-0002_bench.md "$J_TBW"
expect_ok "tb_writer WO- return accepted (COH-1 fix)" \
  scripts/agent_commit.sh --agent tb_writer --entry J-tb_writer-0001 --work-order WO-0002 -m "bench return"

# ---- S21: protected key via --extra-trailer ---------------------------------
say "S21: --extra-trailer with protected key"
entry orchestrator 0002 "extra trailer abuse" >> "$J_ORCH"
git add "$J_ORCH"
expect_fail "protected extra trailer rejected (R6)" "R6" \
  scripts/agent_commit.sh --agent orchestrator --entry J-orchestrator-0002 --work-order none \
    -m "abuse" --journal-only --extra-trailer "Agent: auditor"
git reset -q; git checkout -q -- "$J_ORCH"

# ---- S22: merge commits — trivial passes, content-bearing fails --------------
say "S22: merge-commit handling in range check"
git checkout -q -b side
echo side > rtl/side.sv
entry rtl_lead 0003 "side branch work" rtl/side.sv >> "$J_RTL"
git add rtl/side.sv "$J_RTL"
scripts/agent_commit.sh --agent rtl_lead --entry J-rtl_lead-0003 --work-order WO-0001 -m "side work" > /dev/null
git checkout -q scratch
git merge -q --no-ff side -m "milestone merge" > /dev/null 2>&1
expect_ok "trivial (content-free) merge accepted (R9)" scripts/check_journals.sh --all
git cat-file blob "HEAD:rtl/side.sv" > /dev/null   # sanity: merged content present
echo sneak > rtl/sneak.sv
git add rtl/sneak.sv
git commit -q --amend --no-edit
expect_fail "content-bearing merge rejected (R9)" "R9" scripts/check_journals.sh --all
git reset -q --hard HEAD~1
git branch -q -D side

# ---- S23: duplicate protected trailer (AUD-0001-F2) -------------------------
say "S23: duplicate Agent: trailer in a hand-made commit"
echo dup > rtl/dup.sv
entry rtl_lead 0004 "dup trailer" rtl/dup.sv >> "$J_RTL"
git add rtl/dup.sv "$J_RTL"
git commit -q -F - <<'MSG'
duplicate agent trailer

Agent: rtl_lead
Agent: auditor
Work-Order: none
Journal-Entry: J-rtl_lead-0004
MSG
expect_fail "duplicate protected trailer rejected (R6)" "duplicate" \
  scripts/check_journals.sh --all
git reset -q --hard HEAD~1

# ---- S24: octopus merge is refused outright (AUD-0001-F2) -------------------
say "S24: octopus merge commit"
# Two branches touching DIFFERENT journals so the merge itself is conflict-free
# and an actual 3-parent commit gets created for the checker to reject.
RL_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL" | grep -oE "[0-9]{4}" | tail -1)
RL_NEXT=$(printf "%04d" $((10#$RL_LAST + 1)))
OR_LAST=$(grep -oE "^## \[J-orchestrator-[0-9]{4}\]" "$J_ORCH" | grep -oE "[0-9]{4}" | tail -1)
OR_NEXT=$(printf "%04d" $((10#$OR_LAST + 1)))
git checkout -q -b oct1
echo o1 > rtl/o1.sv
entry rtl_lead "$RL_NEXT" "oct1" rtl/o1.sv >> "$J_RTL"
git add rtl/o1.sv "$J_RTL"
scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$RL_NEXT" --work-order none -m "oct1" > /dev/null
git checkout -q scratch
git checkout -q -b oct2
echo o2 > rtl/o2.sv
entry orchestrator "$OR_NEXT" "oct2" rtl/o2.sv >> "$J_ORCH"
git add rtl/o2.sv "$J_ORCH"
scripts/agent_commit.sh --agent orchestrator --entry "J-orchestrator-$OR_NEXT" --work-order none -m "oct2" > /dev/null
git checkout -q scratch
if git merge -q --no-ff oct1 oct2 -m "octopus" > /dev/null 2>&1; then
  expect_fail "octopus merge rejected (R9)" "octopus" scripts/check_journals.sh --all
  git reset -q --hard HEAD~1
else
  bad "octopus merge could not be created (scenario setup failed)"
  git merge --abort 2>/dev/null || true
fi
git branch -q -D oct1 oct2 2>/dev/null || true

# ---- S25: auditor denied on agents/handoffs (AUD-0002 N4a) ------------------
say "S25: auditor staging a handoff packet"
AUD_NEXT=$( { grep -oE "^## \\[J-auditor-[0-9]{4}\\]" "$J_AUD" || true; } | { grep -oE "[0-9]{4}" || true; } | tail -1 )
AUD_NEXT=$(printf "%04d" $((10#${AUD_NEXT:-0} + 1)))
echo "sneaky verdict edit" >> agents/handoffs/WO-0002_bench.md 2>/dev/null || echo "sneak" > agents/handoffs/WO-0002_bench.md
entry auditor "$AUD_NEXT" "auditor edits a packet" agents/handoffs/WO-0002_bench.md >> "$J_AUD"
git add agents/handoffs/WO-0002_bench.md "$J_AUD"
expect_fail "auditor writing agents/handoffs rejected (R7)" "R7" \
  scripts/agent_commit.sh --agent auditor --entry "J-auditor-$AUD_NEXT" --work-order none -m "packet edit"
git reset -q; git checkout -q HEAD -- "$J_AUD" agents/handoffs/WO-0002_bench.md 2>/dev/null || git checkout -q HEAD -- "$J_AUD"

# ---- S26: body text cannot shadow the final trailer block (AUD-0002 N4b) ----
say "S26: trailer parsing uses the final block only"
OR_LAST=$(grep -oE "^## \\[J-orchestrator-[0-9]{4}\\]" "$J_ORCH" | grep -oE "[0-9]{4}" | tail -1)
OR_NEXT=$(printf "%04d" $((10#$OR_LAST + 1)))
echo trailertest > rtl/trailertest.sv
entry orchestrator "$OR_NEXT" "body-line decoy" rtl/trailertest.sv >> "$J_ORCH"
git add rtl/trailertest.sv "$J_ORCH"
git commit -q -F - <<MSG
decoy commit body mentions
Agent: auditor
mid-message, which must NOT shadow the real trailers below

Agent: orchestrator
Work-Order: none
Journal-Entry: J-orchestrator-$OR_NEXT
MSG
expect_ok "final trailer block wins over body decoy" scripts/check_journals.sh --all

# ---- S27: blob gate (ADR-0002 debt) -----------------------------------------
say "S27: oversized staged file"
OR_LAST=$(grep -oE "^## \\[J-orchestrator-[0-9]{4}\\]" "$J_ORCH" | grep -oE "[0-9]{4}" | tail -1)
OR_NEXT=$(printf "%04d" $((10#$OR_LAST + 1)))
head -c 1500000 /dev/zero > rtl/big.bin
entry orchestrator "$OR_NEXT" "big blob" rtl/big.bin >> "$J_ORCH"
git add rtl/big.bin "$J_ORCH"
expect_fail "1.5MB staged file rejected (blob gate)" "blob threshold" \
  scripts/agent_commit.sh --agent orchestrator --entry "J-orchestrator-$OR_NEXT" --work-order none -m "big"
git reset -q; git checkout -q HEAD -- "$J_ORCH"; rm -f rtl/big.bin

# ---- S28: valid journal rollover (R10) --------------------------------------
say "S28: valid rollover to volume 2"
J_RTL2=agents/journals/claude_rtl_lead_agent.v2.md
RL_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL" | grep -oE "[0-9]{4}" | tail -1)
RL_NEXT=$(printf "%04d" $((10#$RL_LAST + 1)))
PREV_SHA=$(git show "HEAD:$J_RTL" | sha256sum | awk '{print $1}')
seed_volume "$J_RTL2" rtl_lead 2 "$J_RTL" "$PREV_SHA"
echo r > rtl/roll.sv
entry rtl_lead "$RL_NEXT" "rollover to volume 2" rtl/roll.sv >> "$J_RTL2"
git add rtl/roll.sv "$J_RTL2"
expect_ok "rollover commit accepted (R10)" \
  scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$RL_NEXT" --work-order none -m "rollover"
expect_ok "range check passes after rollover (R10 chain verification)" \
  scripts/check_journals.sh --all

# ---- S29: rollover with wrong back-link hash (R10) --------------------------
say "S29: rollover with wrong Previous-volume-sha256"
J_RTL3=agents/journals/claude_rtl_lead_agent.v3.md
R2_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL2" | grep -oE "[0-9]{4}" | tail -1)
R2_NEXT=$(printf "%04d" $((10#$R2_LAST + 1)))
BOGUS_SHA=0000000000000000000000000000000000000000000000000000000000000000
seed_volume "$J_RTL3" rtl_lead 3 "$J_RTL2" "$BOGUS_SHA"
echo r2 > rtl/roll2.sv
entry rtl_lead "$R2_NEXT" "bad rollover" rtl/roll2.sv >> "$J_RTL3"
git add rtl/roll2.sv "$J_RTL3"
expect_fail "wrong back-link hash rejected (R10)" "R10" \
  scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$R2_NEXT" --work-order none -m "bad roll"
git reset -q; rm -f "$J_RTL3" rtl/roll2.sv

# ---- S30: append to a frozen volume (R10) -----------------------------------
say "S30: append to a frozen volume"
R2_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL2" | grep -oE "[0-9]{4}" | tail -1)
R2_NEXT=$(printf "%04d" $((10#$R2_LAST + 1)))
entry rtl_lead "$R2_NEXT" "write into frozen volume 1" >> "$J_RTL"
git add "$J_RTL"
expect_fail "append to frozen volume rejected (R10)" "R10" \
  scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$R2_NEXT" --work-order none -m "frozen" --journal-only
git reset -q; git checkout -q HEAD -- "$J_RTL"

# ---- S31: rollover that also touches the frozen volume (R10) ----------------
say "S31: rollover commit also modifying volume 1"
R2_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL2" | grep -oE "[0-9]{4}" | tail -1)
R2_NEXT=$(printf "%04d" $((10#$R2_LAST + 1)))
PREV_SHA2=$(git show "HEAD:$J_RTL2" | sha256sum | awk '{print $1}')
seed_volume "$J_RTL3" rtl_lead 3 "$J_RTL2" "$PREV_SHA2"
echo r3 > rtl/roll3.sv
entry rtl_lead "$R2_NEXT" "roll to volume 3" rtl/roll3.sv >> "$J_RTL3"
echo "late edit to a frozen volume" >> "$J_RTL"
git add rtl/roll3.sv "$J_RTL3" "$J_RTL"
expect_fail "rollover touching frozen volume 1 rejected (R10)" "R10" \
  scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$R2_NEXT" --work-order none -m "roll+tamper"
git reset -q; git checkout -q HEAD -- "$J_RTL"; rm -f "$J_RTL3" rtl/roll3.sv

# ---- S32: seal-style claim without a SEALED artifact (WARN-SEAL) ------------
say "S32: seal claim with no SEALED artifact staged"
R2_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL2" | grep -oE "[0-9]{4}" | tail -1)
R2_NEXT=$(printf "%04d" $((10#$R2_LAST + 1)))
echo "// I have sealed my prediction for this sweep." > rtl/seal_note.sv
entry rtl_lead "$R2_NEXT" "seal note" rtl/seal_note.sv >> "$J_RTL2"
git add rtl/seal_note.sv "$J_RTL2"
if out=$(scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$R2_NEXT" --work-order none -m "seal note" 2>&1); then
  if printf '%s\n' "$out" | grep -q "WARN-SEAL:"; then
    ok "seal claim accepted with WARN-SEAL advisory"
  else
    bad "seal claim accepted but no WARN-SEAL printed"
  fi
else
  bad "seal claim unexpectedly rejected (advisory must not gate by default)"
fi

# ---- S33: STRICT_SEALS=1 makes the seal advisory gating ---------------------
say "S33: STRICT_SEALS=1 turns WARN-SEAL into a refusal"
R2_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL2" | grep -oE "[0-9]{4}" | tail -1)
R2_NEXT=$(printf "%04d" $((10#$R2_LAST + 1)))
echo "// I am withholding the sealed mapping until reveal." > rtl/seal2.sv
entry rtl_lead "$R2_NEXT" "strict seal" rtl/seal2.sv >> "$J_RTL2"
git add rtl/seal2.sv "$J_RTL2"
expect_fail "strict mode refuses unsealed claim (STRICT_SEALS)" "STRICT_SEALS" \
  env STRICT_SEALS=1 scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$R2_NEXT" --work-order none -m "strict"
git reset -q; git checkout -q HEAD -- "$J_RTL2"; rm -f rtl/seal2.sv
expect_fail "strict mode CI check refuses the S32 claim (STRICT_SEALS)" "STRICT_SEALS" \
  env STRICT_SEALS=1 scripts/check_journals.sh --all

# ---- S34: seal claim + SEALED artifact under a DIFFERENT WO -----------------
say "S34: seal claim with a SEALED artifact staged under another WO number"
R2_LAST=$(grep -oE "^## \[J-rtl_lead-[0-9]{4}\]" "$J_RTL2" | grep -oE "[0-9]{4}" | tail -1)
R2_NEXT=$(printf "%04d" $((10#$R2_LAST + 1)))
echo "// I have sealed my prediction for this sweep." > rtl/seal3.sv
echo "sealed packet body" > agents/handoffs/WO-0009_SEALED_prediction.md
entry rtl_lead "$R2_NEXT" "seal claim + cross-numbered artifact" \
  rtl/seal3.sv agents/handoffs/WO-0009_SEALED_prediction.md >> "$J_RTL2"
git add rtl/seal3.sv agents/handoffs/WO-0009_SEALED_prediction.md "$J_RTL2"
if out=$(scripts/agent_commit.sh --agent rtl_lead --entry "J-rtl_lead-$R2_NEXT" --work-order WO-0004 -m "sealed packet" 2>&1); then
  if printf '%s\n' "$out" | grep -q "WARN-SEAL:"; then
    bad "WARN-SEAL printed despite a staged SEALED artifact (cross-numbered-seal regression)"
  else
    ok "no warning when any SEALED artifact is staged (presence, not WO-number matching)"
  fi
else
  bad "sealed-artifact commit unexpectedly rejected"
fi

# ---- summary ----------------------------------------------------------------
say ""
say "protocol self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
