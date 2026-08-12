#!/usr/bin/env bash
# agent_commit.sh — the orchestrator's ONLY path to `git commit`.
# Enforces the commit protocol (agents/PROTOCOL.md §5) mechanically, then
# creates the commit with the required trailers.
#
# Usage:
#   scripts/agent_commit.sh --agent NAME --entry J-NAME-NNNN \
#       --work-order WO-NNNN|none -m "commit title" [--journal-only]
#
# Stage everything for the commit first (git add ...), then run this script.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# shellcheck source=policy.sh
. "$(dirname "$0")/policy.sh"

AGENT="" ENTRY="" WORK_ORDER="" TITLE="" JOURNAL_ONLY=0
EXTRA_TRAILERS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --entry) ENTRY="$2"; shift 2 ;;
    --work-order) WORK_ORDER="$2"; shift 2 ;;
    -m) TITLE="$2"; shift 2 ;;
    --journal-only) JOURNAL_ONLY=1; shift ;;
    --extra-trailer) EXTRA_TRAILERS+=("$2"); shift 2 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

[ -n "$AGENT" ] && [ -n "$ENTRY" ] && [ -n "$WORK_ORDER" ] && [ -n "$TITLE" ] \
  || fail "usage: agent_commit.sh --agent NAME --entry J-NAME-NNNN --work-order WO-NNNN|none -m TITLE [--journal-only]"
for t in ${EXTRA_TRAILERS[@]+"${EXTRA_TRAILERS[@]}"}; do
  case "$t" in
    Agent:*|Work-Order:*|Journal-Entry:*|Journal-Only:*)
      fail "--extra-trailer may not use protected key: $t (R6)" ;;
  esac
done
is_known_agent "$AGENT" || fail "unknown agent '$AGENT'"
echo "$ENTRY" | grep -qE "^J-${AGENT}-[0-9]{4}$" \
  || fail "entry '$ENTRY' does not match J-${AGENT}-NNNN"

# The agent's journal is a volume CHAIN (PROTOCOL §4.3); appends go to the
# ACTIVE volume — the highest volume present in the staged index.
JOURNAL="$(journal_path_for "$AGENT")"
BASE_JOURNAL="$(journal_base_path_for "$AGENT")"
ACTIVE_VOL="$(journal_volume_num "$JOURNAL")"

# ---- Gather staged state -----------------------------------------------------
STATUS_LIST=$(git diff --cached --name-status --no-renames)
[ -n "$STATUS_LIST" ] || fail "nothing staged"

OWN_JOURNAL_STAGED=0
FOREIGN_JOURNAL_SEEDS=()
WORK_PATHS=()
while IFS=$'\t' read -r status path; do
  [ -n "$path" ] || continue
  if is_journal_path "$path"; then
    case "$status" in
      D) fail "journal deletion staged: $path (R3 — journals are never deleted)" ;;
      R*|C*) fail "journal rename/copy staged: $path (R3)" ;;
    esac
    if [ "$path" = "$JOURNAL" ]; then
      OWN_JOURNAL_STAGED=1
    elif [ "$(journal_base_of "$path")" = "$BASE_JOURNAL" ]; then
      # Own chain, but not the active volume: frozen (R10).
      fail "staged change to frozen journal volume: $path (R10 — only the active volume $JOURNAL may be appended)"
    else
      # R8: foreign journals only as brand-new, header-only seeds.
      [ "$status" = "A" ] \
        || fail "commit modifies another agent's journal: $path (R8)"
      FOREIGN_JOURNAL_SEEDS+=("$path")
    fi
  else
    WORK_PATHS+=("$path")
  fi
done <<< "$STATUS_LIST"

# ---- R2: coupling ------------------------------------------------------------
[ "$OWN_JOURNAL_STAGED" -eq 1 ] \
  || fail "no staged append to $JOURNAL (R2 — work without journal)"
if [ "$JOURNAL_ONLY" -eq 1 ]; then
  [ "${#WORK_PATHS[@]}" -eq 0 ] \
    || fail "--journal-only but work products are staged: ${WORK_PATHS[*]}"
else
  [ "${#WORK_PATHS[@]}" -gt 0 ] || [ "${#FOREIGN_JOURNAL_SEEDS[@]}" -gt 0 ] \
    || fail "journal staged with no work products — use --journal-only if intended (R2)"
fi

# ---- R8: validate foreign seeds ---------------------------------------------
for seed in ${FOREIGN_JOURNAL_SEEDS[@]+"${FOREIGN_JOURNAL_SEEDS[@]}"}; do
  seed_agent=$(basename "$seed" | sed -E 's/^claude_(.*)_agent\.md$/\1/')
  is_known_agent "$seed_agent" || fail "seed journal for unknown agent: $seed"
  [ "$(journal_path_for "$seed_agent")" = "$seed" ] \
    || fail "seed journal at wrong location: $seed"
  n=$(git show ":$seed" | count_entries "$seed_agent")
  [ "${n:-0}" -eq 0 ] || fail "foreign journal seed contains entries: $seed (R8)"
done

# ---- R10: volume-chain integrity on rollover --------------------------------
# A commit whose active volume is new (volume k+1) is a ROLLOVER: volume k
# must be frozen byte-identical, the new volume's back-link must hash volume
# k's committed bytes, entry IDs must continue across the chain, and the
# declared Volume: number must be k+1.
if [ "$ACTIVE_VOL" -ge 2 ] && ! git cat-file -e "HEAD:$JOURNAL" 2>/dev/null; then
  PREV_VOL_PATH=$(journal_volume_path "$BASE_JOURNAL" "$((ACTIVE_VOL - 1))")
  git cat-file -e "HEAD:$PREV_VOL_PATH" 2>/dev/null \
    || fail "rollover creates $JOURNAL but $PREV_VOL_PATH does not exist at HEAD (R10 — no gaps in the volume chain)"
  head_oid=$(git rev-parse "HEAD:$PREV_VOL_PATH")
  idx_oid=$(git rev-parse ":$PREV_VOL_PATH" 2>/dev/null || echo missing)
  [ "$head_oid" = "$idx_oid" ] \
    || fail "rollover commit alters $PREV_VOL_PATH (R10 — the previous volume freezes at rollover)"
  prev_sha=$(git show "HEAD:$PREV_VOL_PATH" | sha256_hex)
  declared_sha=$(git show ":$JOURNAL" | volume_backlink_sha)
  [ "$declared_sha" = "$prev_sha" ] \
    || fail "$JOURNAL Previous-volume-sha256 '${declared_sha:-missing}' does not match sha256 of $PREV_VOL_PATH at HEAD ($prev_sha) (R10)"
  declared_vol=$(git show ":$JOURNAL" | volume_header_num)
  [ "$declared_vol" = "$ACTIVE_VOL" ] \
    || fail "$JOURNAL declares Volume: '${declared_vol:-missing}', expected $ACTIVE_VOL (R10)"
  first_new=$(git show ":$JOURNAL" | grep -oE "^## \[J-${AGENT}-[0-9]{4}\]" | head -n 1 | grep -oE '[0-9]{4}' || true)
  chain_last=$(chain_last_entry_num "$AGENT" HEAD)
  expected_first=$(printf '%04d' "$((10#$chain_last + 1))")
  [ "${first_new:-}" = "$expected_first" ] \
    || fail "$JOURNAL first entry '${first_new:-none}' breaks chain continuity (last across chain was $chain_last, expected $expected_first) (R10)"
fi

# ---- R3: pure EOF-append on own journal (active volume) ---------------------
TMPDIR_P=$(mktemp -d)
trap 'rm -rf "$TMPDIR_P"' EXIT
git show ":$JOURNAL" > "$TMPDIR_P/staged"
if git cat-file -e "HEAD:$JOURNAL" 2>/dev/null; then
  git show "HEAD:$JOURNAL" > "$TMPDIR_P/head"
else
  : > "$TMPDIR_P/head"   # journal volume is new in this commit
fi
is_byte_prefix "$TMPDIR_P/head" "$TMPDIR_P/staged" \
  || fail "$JOURNAL is not a pure EOF-append of its previous content (R3)"
head_size=$(wc -c < "$TMPDIR_P/head")
tail -c +"$((head_size + 1))" "$TMPDIR_P/staged" > "$TMPDIR_P/appended"
[ -s "$TMPDIR_P/appended" ] || fail "no appended journal content (R2)"

# Advisory (non-gating): recommend a rollover before the blob gate bites.
staged_bytes=$(wc -c < "$TMPDIR_P/staged")
if [ "$staged_bytes" -gt 800000 ]; then
  echo "WARNING: $JOURNAL is ${staged_bytes} bytes (> 800000) — roll over to volume $((ACTIVE_VOL + 1)) soon (PROTOCOL §4.3); the ${AGENT_COMMIT_BLOB_MAX:-1000000}-byte blob gate will refuse it outright."
fi

# ---- R5: exactly one new entry, monotonic across the chain ------------------
new_headers=$(grep -cE "^## \[J-${AGENT}-[0-9]{4}\]" "$TMPDIR_P/appended" || true)
[ "$new_headers" -eq 1 ] \
  || fail "appended region must contain exactly one new entry header, found $new_headers"
grep -qF "## [$ENTRY]" "$TMPDIR_P/appended" \
  || fail "appended entry header does not match --entry $ENTRY"
last=$(chain_last_entry_num "$AGENT" HEAD)
expected=$(printf '%04d' "$((10#$last + 1))")
actual=$(echo "$ENTRY" | grep -oE '[0-9]{4}$')
[ "$actual" = "$expected" ] \
  || fail "entry number $actual is not monotonic (last was $last, expected $expected) (R5)"

# ---- R4: Files-in-this-commit set-equality ----------------------------------
has_files_section < "$TMPDIR_P/appended" \
  || fail "new entry lacks a '### Files-in-this-commit' section (R4)"
extract_files_list < "$TMPDIR_P/appended" | LC_ALL=C sort -u > "$TMPDIR_P/claimed"
{
  printf '%s\n' ${WORK_PATHS[@]+"${WORK_PATHS[@]}"}
  printf '%s\n' ${FOREIGN_JOURNAL_SEEDS[@]+"${FOREIGN_JOURNAL_SEEDS[@]}"}
} | grep -v '^$' | LC_ALL=C sort -u > "$TMPDIR_P/staged_list" || true
if ! diff -u "$TMPDIR_P/claimed" "$TMPDIR_P/staged_list" > "$TMPDIR_P/files_diff"; then
  echo "--- claimed vs staged ---" >&2
  cat "$TMPDIR_P/files_diff" >&2
  fail "Files-in-this-commit list does not equal the staged non-journal set (R4)"
fi

# ---- Blob gate (ADR-0002 accepted debt, closed in M1) ------------------------
BLOB_MAX="${AGENT_COMMIT_BLOB_MAX:-1000000}"
while IFS=$'\t' read -r status path; do
  [ -n "$path" ] || continue
  [ "$status" = "D" ] && continue
  sz=$(git cat-file -s ":$path" 2>/dev/null || echo 0)
  [ "$sz" -le "$BLOB_MAX" ] \
    || fail "staged file exceeds blob threshold: $path (${sz} > ${BLOB_MAX} bytes; large data ships as fetch script + checksum manifest — blob gate, ADR-0002)"
done <<< "$STATUS_LIST"

# ---- R7: path isolation ------------------------------------------------------
for p in ${WORK_PATHS[@]+"${WORK_PATHS[@]}"}; do
  agent_may_write "$AGENT" "$p" \
    || fail "path outside $AGENT's write scope: $p (R7)"
done

# ---- WARN-SEAL advisory (gating only with STRICT_SEALS=1) --------------------
# Two-stage grep over the staged diff's ADDED lines: seal vocabulary AND a
# first-person holding claim on the same line, with no *SEALED*.md artifact
# anywhere in the staged set.
SEALED_ARTIFACT=0
while IFS=$'\t' read -r _status path; do
  [ -n "$path" ] || continue
  case "$path" in
    *SEALED*.md) SEALED_ARTIFACT=1 ;;
  esac
done <<< "$STATUS_LIST"
if [ "$SEALED_ARTIFACT" -eq 0 ]; then
  SEAL_LINES=$(git diff --cached --no-renames \
    | grep -E '^\+' | grep -vE '^\+\+\+' | sed -E 's/^\+//' \
    | grep -E 'sealed|seal(ed)? (file|prediction|sweep|mapping)|withheld|withholding' \
    | grep -E 'I (have|hold|am withholding|sealed)' || true)
  if [ -n "$SEAL_LINES" ]; then
    while IFS= read -r line; do
      echo "WARN-SEAL: $line"
    done <<< "$SEAL_LINES"
    if [ "${STRICT_SEALS:-0}" = "1" ]; then
      fail "staged seal-style claim without a *SEALED*.md artifact (WARN-SEAL, STRICT_SEALS=1)"
    fi
  fi
fi

# ---- Commit ------------------------------------------------------------------
{
  echo "$TITLE"
  echo
  echo "Agent: $AGENT"
  echo "Work-Order: $WORK_ORDER"
  echo "Journal-Entry: $ENTRY"
  [ "$JOURNAL_ONLY" -eq 1 ] && echo "Journal-Only: true"
  for t in ${EXTRA_TRAILERS[@]+"${EXTRA_TRAILERS[@]}"}; do echo "$t"; done
} > "$TMPDIR_P/msg"

git commit -F "$TMPDIR_P/msg" --quiet
echo "OK: committed $(git rev-parse --short HEAD) as $AGENT ($ENTRY)"
