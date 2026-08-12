#!/usr/bin/env bash
# check_journals.sh — re-verifies the commit protocol (agents/PROTOCOL.md §5)
# over a commit range. Run by CI on every push; also runnable locally.
#
# Usage:
#   scripts/check_journals.sh --all            # every commit reachable from HEAD
#   scripts/check_journals.sh --range A..B     # commits in A..B
#
# Exits nonzero on the first violating commit, naming the rule broken.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# shellcheck source=policy.sh
. "$(dirname "$0")/policy.sh"

MODE="" RANGE=""
case "${1:-}" in
  --all) MODE=all ;;
  --range) MODE=range; RANGE="${2:-}"; [ -n "$RANGE" ] || fail "--range needs A..B" ;;
  *) fail "usage: check_journals.sh --all | --range A..B" ;;
esac

if [ "$MODE" = all ]; then
  COMMITS=$(git rev-list --reverse HEAD)
else
  COMMITS=$(git rev-list --reverse "$RANGE")
fi
[ -n "$COMMITS" ] || { echo "no commits to check"; exit 0; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

checked=0
for C in $COMMITS; do
  short=$(git rev-parse --short "$C")

  # Merge commits (R9): constituent commits are checked individually, so a
  # merge itself must be TRIVIAL — its tree must equal one parent's tree,
  # proving it introduces no content of its own (no conflict resolutions).
  nwords=$(git rev-list --parents -n 1 "$C" | wc -w)   # 1 + parent count
  if [ "$nwords" -gt 3 ]; then
    fail "$short: octopus merge commits are forbidden (R9)"
  fi
  if [ "$nwords" -eq 3 ]; then
    t=$(git rev-parse "$C^{tree}")
    p1=$(git rev-parse "$C^1^{tree}")
    p2=$(git rev-parse "$C^2^{tree}")
    if [ "$t" = "$p1" ] || [ "$t" = "$p2" ]; then
      echo "OK: merge $short is content-free (tree equals a parent); constituents checked individually (R9)"
      checked=$((checked + 1))
      continue
    fi
    fail "$short: merge commit introduces content found in neither parent (conflict resolution or divergent auto-merge) (R9)"
  fi

  git show -s --format=%B "$C" > "$TMP/msg"
  # Trailer parsing: only the message's final trailer block counts, and the
  # protected keys must be unique — a crafted body line or duplicate trailer
  # cannot shadow the real one (R6).
  git interpret-trailers --parse < "$TMP/msg" > "$TMP/trailers"
  for key in Agent Journal-Entry Work-Order Journal-Only; do
    n=$(grep -cE "^$key: " "$TMP/trailers" || true)
    [ "$n" -le 1 ] || fail "$short: duplicate '$key:' trailer (R6)"
  done
  get_trailer() { grep -E "^$2: " "$1" | sed -E "s/^$2: //" || true; }
  AGENT=$(get_trailer "$TMP/trailers" Agent)
  ENTRY=$(get_trailer "$TMP/trailers" Journal-Entry)
  WORK_ORDER=$(get_trailer "$TMP/trailers" Work-Order)
  JOURNAL_ONLY=$(get_trailer "$TMP/trailers" Journal-Only)

  [ -n "$AGENT" ] || fail "$short: missing 'Agent:' trailer (R6)"
  is_known_agent "$AGENT" || fail "$short: unknown agent '$AGENT' (R6)"
  [ -n "$ENTRY" ] || fail "$short: missing 'Journal-Entry:' trailer (R6)"
  [ -n "$WORK_ORDER" ] || fail "$short: missing 'Work-Order:' trailer (R6)"
  echo "$ENTRY" | grep -qE "^J-${AGENT}-[0-9]{4}$" \
    || fail "$short: Journal-Entry '$ENTRY' malformed for agent $AGENT (R6)"

  # The agent's journal is a volume CHAIN (PROTOCOL §4.3); the ACTIVE volume
  # is the highest volume present in this commit's tree.
  JOURNAL="$(journal_path_for "$AGENT" "$C")"
  BASE_JOURNAL="$(journal_base_path_for "$AGENT")"
  ACTIVE_VOL="$(journal_volume_num "$JOURNAL")"

  if [ "$nwords" -eq 2 ]; then
    PARENT=$(git rev-parse "$C^")
    git diff-tree -r --no-renames --no-commit-id --name-status "$PARENT" "$C" > "$TMP/changes"
  else
    PARENT=""
    git diff-tree --root -r --no-renames --no-commit-id --name-status "$C" > "$TMP/changes"
  fi

  OWN_JOURNAL=0
  : > "$TMP/work_paths"
  : > "$TMP/seeds"
  while IFS=$'\t' read -r status path; do
    [ -n "$path" ] || continue
    if is_journal_path "$path"; then
      case "$status" in
        D) fail "$short: journal deleted: $path (R3)" ;;
        R*|C*) fail "$short: journal renamed/copied: $path (R3)" ;;
      esac
      if [ "$path" = "$JOURNAL" ]; then
        OWN_JOURNAL=1
      elif [ "$(journal_base_of "$path")" = "$BASE_JOURNAL" ]; then
        # Own chain, but not the active volume: frozen (R10).
        fail "$short: modifies frozen journal volume: $path (R10 — only the active volume $JOURNAL may change)"
      else
        [ "$status" = "A" ] || fail "$short: modifies another agent's journal: $path (R8)"
        seed_agent=$(basename "$path" | sed -E 's/^claude_(.*)_agent\.md$/\1/')
        is_known_agent "$seed_agent" || fail "$short: seed journal for unknown agent: $path"
        [ "$(journal_path_for "$seed_agent" "$C")" = "$path" ] \
          || fail "$short: seed journal at wrong location: $path"
        n=$(git show "$C:$path" | count_entries "$seed_agent")
        [ "${n:-0}" -eq 0 ] || fail "$short: foreign journal seed contains entries: $path (R8)"
        echo "$path" >> "$TMP/seeds"
      fi
    else
      echo "$path" >> "$TMP/work_paths"
    fi
  done < "$TMP/changes"

  [ "$OWN_JOURNAL" -eq 1 ] || fail "$short: no append to $JOURNAL (R2)"

  if [ "$JOURNAL_ONLY" = "true" ]; then
    [ ! -s "$TMP/work_paths" ] \
      || fail "$short: Journal-Only commit stages work products (R2)"
  else
    [ -s "$TMP/work_paths" ] || [ -s "$TMP/seeds" ] \
      || fail "$short: work-less commit lacks 'Journal-Only: true' trailer (R2)"
  fi

  # R10: volume-chain integrity re-verified on any commit that creates a new
  # active volume (a rollover).
  if [ "$ACTIVE_VOL" -ge 2 ] && { [ -z "$PARENT" ] || ! git cat-file -e "$PARENT:$JOURNAL" 2>/dev/null; }; then
    prev_path=$(journal_volume_path "$BASE_JOURNAL" "$((ACTIVE_VOL - 1))")
    if [ -z "$PARENT" ] || ! git cat-file -e "$PARENT:$prev_path" 2>/dev/null; then
      fail "$short: rollover creates $JOURNAL but $prev_path does not exist at parent (R10 — no gaps in the volume chain)"
    fi
    [ "$(git rev-parse "$PARENT:$prev_path")" = "$(git rev-parse "$C:$prev_path")" ] \
      || fail "$short: rollover commit alters $prev_path (R10 — the previous volume freezes at rollover)"
    prev_sha=$(git show "$PARENT:$prev_path" | sha256_hex)
    declared_sha=$(git show "$C:$JOURNAL" | volume_backlink_sha)
    [ "$declared_sha" = "$prev_sha" ] \
      || fail "$short: $JOURNAL Previous-volume-sha256 '${declared_sha:-missing}' does not match sha256 of $prev_path at parent ($prev_sha) (R10)"
    declared_vol=$(git show "$C:$JOURNAL" | volume_header_num)
    [ "$declared_vol" = "$ACTIVE_VOL" ] \
      || fail "$short: $JOURNAL declares Volume: '${declared_vol:-missing}', expected $ACTIVE_VOL (R10)"
    first_new=$(git show "$C:$JOURNAL" | grep -oE "^## \[J-${AGENT}-[0-9]{4}\]" | head -n 1 | grep -oE '[0-9]{4}' || true)
    chain_last=$(chain_last_entry_num "$AGENT" "$PARENT")
    expected_first=$(printf '%04d' "$((10#$chain_last + 1))")
    [ "${first_new:-}" = "$expected_first" ] \
      || fail "$short: new volume first entry '${first_new:-none}' breaks chain continuity (last across chain was $chain_last, expected $expected_first) (R10)"
  fi

  # R3: pure EOF-append relative to parent (active volume).
  git show "$C:$JOURNAL" > "$TMP/new"
  if [ -n "$PARENT" ] && git cat-file -e "$PARENT:$JOURNAL" 2>/dev/null; then
    git show "$PARENT:$JOURNAL" > "$TMP/old"
  else
    : > "$TMP/old"
  fi
  is_byte_prefix "$TMP/old" "$TMP/new" \
    || fail "$short: $JOURNAL is not a pure EOF-append (R3)"
  old_size=$(wc -c < "$TMP/old")
  tail -c +"$((old_size + 1))" "$TMP/new" > "$TMP/appended"
  [ -s "$TMP/appended" ] || fail "$short: journal staged with no appended content (R2)"

  # R5: exactly one new entry, matching trailer, monotonic across the chain.
  new_headers=$(grep -cE "^## \[J-${AGENT}-[0-9]{4}\]" "$TMP/appended" || true)
  [ "$new_headers" -eq 1 ] \
    || fail "$short: appended region has $new_headers entry headers, expected 1 (R5)"
  grep -qF "## [$ENTRY]" "$TMP/appended" \
    || fail "$short: appended entry does not match trailer $ENTRY (R6)"
  if [ -n "$PARENT" ]; then
    last=$(chain_last_entry_num "$AGENT" "$PARENT")
  else
    last="0000"
  fi
  expected=$(printf '%04d' "$((10#$last + 1))")
  actual=$(echo "$ENTRY" | grep -oE '[0-9]{4}$')
  [ "$actual" = "$expected" ] \
    || fail "$short: entry $actual not monotonic (last $last, expected $expected) (R5)"

  # R4: Files-in-this-commit set-equality (work paths + foreign seeds).
  has_files_section < "$TMP/appended" \
    || fail "$short: entry lacks '### Files-in-this-commit' (R4)"
  extract_files_list < "$TMP/appended" | LC_ALL=C sort -u > "$TMP/claimed"
  cat "$TMP/work_paths" "$TMP/seeds" | LC_ALL=C sort -u > "$TMP/actual_list"
  if ! diff -u "$TMP/claimed" "$TMP/actual_list" > "$TMP/files_diff"; then
    cat "$TMP/files_diff" >&2
    fail "$short: Files-in-this-commit != changed non-journal set (R4)"
  fi

  # R7: path isolation.
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    agent_may_write "$AGENT" "$p" \
      || fail "$short: path outside $AGENT's write scope: $p (R7)"
  done < "$TMP/work_paths"

  # WARN-SEAL advisory (gating only with STRICT_SEALS=1): seal vocabulary AND
  # a first-person holding claim on the same ADDED line, with no *SEALED*.md
  # artifact anywhere in this commit's changed set.
  sealed_artifact=0
  while IFS=$'\t' read -r _status path; do
    [ -n "$path" ] || continue
    case "$path" in
      *SEALED*.md) sealed_artifact=1 ;;
    esac
  done < "$TMP/changes"
  if [ "$sealed_artifact" -eq 0 ]; then
    if [ -n "$PARENT" ]; then
      git diff --no-renames "$PARENT" "$C" > "$TMP/patch"
    else
      git diff-tree --root -p --no-commit-id --no-renames "$C" > "$TMP/patch"
    fi
    seal_lines=$(grep -E '^\+' "$TMP/patch" | grep -vE '^\+\+\+' | sed -E 's/^\+//' \
      | grep -E 'sealed|seal(ed)? (file|prediction|sweep|mapping)|withheld|withholding' \
      | grep -E 'I (have|hold|am withholding|sealed)' || true)
    if [ -n "$seal_lines" ]; then
      while IFS= read -r line; do
        echo "WARN-SEAL: $line"
      done <<< "$seal_lines"
      if [ "${STRICT_SEALS:-0}" = "1" ]; then
        fail "$short: seal-style claim without a *SEALED*.md artifact (WARN-SEAL, STRICT_SEALS=1)"
      fi
    fi
  fi

  checked=$((checked + 1))
done

# ---- R10 tree-wide chain verification at the range head ---------------------
# Every journal chain in the head tree must be gap-free, every back-link hash
# must match the actual bytes of its predecessor volume in that tree, and
# entry IDs must be contiguous across the concatenated chain.
HEADC=$(printf '%s\n' "$COMMITS" | tail -n 1)
git ls-tree -r --name-only "$HEADC" > "$TMP/head_files"
for agent in $KNOWN_AGENTS; do
  base=$(journal_base_path_for "$agent")
  stem="${base%.md}"
  present=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      "$base"|"$stem".v[0-9]*.md) present=$((present + 1)) ;;
    esac
  done < "$TMP/head_files"
  [ "$present" -gt 0 ] || continue
  vols=$(journal_volumes_for "$agent" "$HEADC")
  contig=0
  if [ -n "$vols" ]; then contig=$(printf '%s\n' "$vols" | wc -l); fi
  [ "$present" -eq "$contig" ] \
    || fail "journal chain for $agent has a gap or stray volume at range head ($present volume file(s) present, $contig contiguous from volume 1) (R10)"
  if [ "$contig" -ge 2 ]; then
    prev="$base"
    k=2
    while [ "$k" -le "$contig" ]; do
      p=$(journal_volume_path "$base" "$k")
      want=$(git show "$HEADC:$prev" | sha256_hex)
      got=$(git show "$HEADC:$p" | volume_backlink_sha)
      if [ "$got" != "$want" ]; then
        fail "chain back-link mismatch at range head: $p declares Previous-volume-sha256 '${got:-missing}', $prev hashes to $want (R10)"
      fi
      vnum=$(git show "$HEADC:$p" | volume_header_num)
      if [ "$vnum" != "$k" ]; then
        fail "volume header mismatch at range head: $p declares Volume: '${vnum:-missing}', expected $k (R10)"
      fi
      prev="$p"
      k=$((k + 1))
    done
  fi
  for p in $vols; do git show "$HEADC:$p"; done \
    | grep -oE "^## \[J-${agent}-[0-9]{4}\]" | grep -oE '[0-9]{4}' > "$TMP/chain_nums" || true
  n=0
  while IFS= read -r num; do
    [ -n "$num" ] || continue
    n=$((n + 1))
    if [ "$num" != "$(printf '%04d' "$n")" ]; then
      fail "chain for $agent: entry $num at position $n — IDs not contiguous across volumes at range head (R10)"
    fi
  done < "$TMP/chain_nums"
done
echo "OK: journal volume chains verified at range head (R10)"

echo "OK: $checked commit(s) satisfy the journal/commit protocol"
