#!/usr/bin/env bash
# policy.sh — shared policy + helpers for the journal/commit protocol.
# Sourced by agent_commit.sh and check_journals.sh. See agents/PROTOCOL.md §5-6.

KNOWN_AGENTS="orchestrator architect_docs_lead rtl_lead dv_lead auditor rtl_module_dev tb_writer"
WORKER_AGENTS="rtl_module_dev tb_writer"

is_known_agent() {
  local a
  for a in $KNOWN_AGENTS; do [ "$a" = "$1" ] && return 0; done
  return 1
}

is_worker_agent() {
  local a
  for a in $WORKER_AGENTS; do [ "$a" = "$1" ] && return 0; done
  return 1
}

# ---- Journal volume chains (PROTOCOL §4.3) ----------------------------------
# A journal is a CHAIN of volume files. Volume 1 is the base path; volume k
# (k >= 2) is the base path with `.md` replaced by `.v<k>.md`. No gaps: volume
# k+1 may exist only if volume k exists. The ACTIVE volume is the
# highest-numbered existing volume; all lower volumes are FROZEN (R10).

# Base (volume-1) journal path for an agent identity.
journal_base_path_for() {
  if is_worker_agent "$1"; then
    echo "agents/journals/workers/claude_$1_agent.md"
  else
    echo "agents/journals/claude_$1_agent.md"
  fi
}

# Path of volume $2 in the chain rooted at base path $1.
journal_volume_path() {
  local base="$1" k="$2"
  if [ "$k" -le 1 ]; then
    echo "$base"
  else
    echo "${base%.md}.v${k}.md"
  fi
}

# Base (volume-1) path of any volume path: strip a trailing .v<k> suffix.
journal_base_of() {
  echo "$1" | sed -E 's/\.v[0-9]+\.md$/.md/'
}

# Volume number of a journal path (1 for the base volume).
journal_volume_num() {
  local n
  n=$(echo "$1" | grep -oE '\.v[0-9]+\.md$' | grep -oE '[0-9]+' | head -n 1 || true)
  if [ -z "$n" ]; then echo 1; else echo "$n"; fi
}

# List the existing volume paths of <agent>'s chain, volume 1 first, stopping
# at the first gap. Tree-ish $2 selects where "existing" is evaluated:
# "" (or omitted) = the staged index; otherwise a commit/tree-ish (e.g. HEAD).
journal_volumes_for() {
  local agent="$1" tree="${2:-}"
  local base k
  base=$(journal_base_path_for "$agent")
  k=1
  while git cat-file -e "${tree}:$(journal_volume_path "$base" "$k")" 2>/dev/null; do
    journal_volume_path "$base" "$k"
    k=$((k + 1))
  done
  return 0
}

# Journal file path for an agent identity: the ACTIVE (highest existing)
# volume of its chain in tree-ish $2 ("" = the staged index). Falls back to
# the base volume when no volume exists yet (brand-new journal).
journal_path_for() {
  local agent="$1" tree="${2:-}"
  local active
  active=$(journal_volumes_for "$agent" "$tree" | tail -n 1)
  if [ -n "$active" ]; then
    echo "$active"
  else
    journal_base_path_for "$agent"
  fi
}

# Is this path a journal file (any volume)? (INDEX.md and other files under
# agents/journals/ are ordinary work products.)
is_journal_path() {
  case "$1" in
    agents/journals/claude_*_agent.md) return 0 ;;
    agents/journals/claude_*_agent.v[0-9]*.md) return 0 ;;
    agents/journals/workers/claude_*_agent.md) return 0 ;;
    agents/journals/workers/claude_*_agent.v[0-9]*.md) return 0 ;;
    *) return 1 ;;
  esac
}

# From a continuation volume's content on stdin, print the back-link hash its
# frozen header declares (`- **Previous-volume-sha256**: <hex>`); empty if
# absent. Only the header block (before the first ---) is consulted.
volume_backlink_sha() {
  awk '/^---$/ { exit } /^- \*\*Previous-volume-sha256\*\*: / { sub(/^- \*\*Previous-volume-sha256\*\*: /, ""); print; exit }'
}

# From a continuation volume's content on stdin, print the `Volume:` number
# its frozen header declares; empty if absent.
volume_header_num() {
  awk '/^---$/ { exit } /^- \*\*Volume\*\*: / { sub(/^- \*\*Volume\*\*: /, ""); print; exit }'
}

# sha256 hex digest of stdin.
sha256_hex() {
  sha256sum | awk '{print $1}'
}

# Path isolation (PROTOCOL §6): may <agent> stage <path> as a work product?
# This case block is PROTOCOL §6 as bash. Change only via ADR with a
# test_protocol.sh scenario (§11).
agent_may_write() {
  local agent="$1" path="$2"
  case "$agent" in
    orchestrator)
      return 0 ;;
    architect_docs_lead)
      case "$path" in
        docs/reports/audit/*|docs/reports/dv/*) return 1 ;;
        docs/*|README.md|ORG_CHART.md|agents/handoffs/*) return 0 ;;
        *) return 1 ;;
      esac ;;
    rtl_lead|rtl_module_dev)
      case "$path" in
        rtl/*|agents/handoffs/*) return 0 ;;
        *) return 1 ;;
      esac ;;
    dv_lead)
      case "$path" in
        test/*|tools/*|docs/reports/dv/*|agents/handoffs/*) return 0 ;;
        *) return 1 ;;
      esac ;;
    auditor)
      case "$path" in
        docs/reports/audit/*) return 0 ;;
        *) return 1 ;;
      esac ;;
    tb_writer)
      case "$path" in
        test/*|agents/handoffs/*) return 0 ;;
        *) return 1 ;;
      esac ;;
    *)
      return 1 ;;
  esac
}

# Print the last (highest) 4-digit entry number found in journal content on
# stdin, for the given agent; prints 0000 if none. Single-volume primitive —
# for chain-wide answers use chain_last_entry_num.
last_entry_num() {
  local agent="$1"
  local last
  last=$(grep -oE "^## \[J-${agent}-[0-9]{4}\]" | grep -oE '[0-9]{4}' | tail -n 1 || true)
  if [ -z "$last" ]; then echo "0000"; else echo "$last"; fi
}

# Count entry headers for the given agent in content on stdin. Single-volume
# primitive — for chain-wide answers use chain_count_entries.
count_entries() {
  local agent="$1"
  grep -cE "^## \[J-${agent}-[0-9]{4}\]" || true
}

# Chain-aware last entry number: the highest entry number across ALL volumes
# of <agent>'s chain in tree-ish $2 ("" = the staged index); 0000 if none.
chain_last_entry_num() {
  local agent="$1" tree="${2:-}"
  local p last best="0000"
  for p in $(journal_volumes_for "$agent" "$tree"); do
    last=$(git show "${tree}:$p" | last_entry_num "$agent")
    if [ "$((10#$last))" -gt "$((10#$best))" ]; then best="$last"; fi
  done
  echo "$best"
}

# Chain-aware entry count: total entry headers across ALL volumes of
# <agent>'s chain in tree-ish $2 ("" = the staged index).
chain_count_entries() {
  local agent="$1" tree="${2:-}"
  local p n total=0
  for p in $(journal_volumes_for "$agent" "$tree"); do
    n=$(git show "${tree}:$p" | count_entries "$agent")
    total=$((total + ${n:-0}))
  done
  echo "$total"
}

# From appended journal text on stdin, print the Files-in-this-commit list
# (one path per line; empty output means the list was `- (none)` or absent).
extract_files_list() {
  awk '
    /^### Files-in-this-commit[[:space:]]*$/ { grab = 1; next }
    grab && /^#/ { grab = 0 }
    grab && /^- / {
      p = substr($0, 3)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", p)
      if (p != "(none)") print p
    }
  '
}

# Does the appended journal text on stdin contain a Files-in-this-commit
# section at all?
has_files_section() {
  grep -qE '^### Files-in-this-commit[[:space:]]*$'
}

# Byte-prefix check: is file $1 a byte-prefix of file $2?
is_byte_prefix() {
  local old="$1" new="$2"
  local old_size new_size
  old_size=$(wc -c < "$old")
  new_size=$(wc -c < "$new")
  [ "$old_size" -le "$new_size" ] || return 1
  head -c "$old_size" "$new" | cmp -s - "$old"
}

fail() {
  echo "PROTOCOL VIOLATION: $*" >&2
  exit 1
}
