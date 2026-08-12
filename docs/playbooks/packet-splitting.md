# Playbook — packet splitting and serialization

The orchestrator's mechanics for keeping **one agent per commit** (R1) true
on files that several agents legitimately touch — above all packet files in
`agents/handoffs/`, whose lifecycle (worker appends a Return, lead appends a
verdict and flips State) routinely leaves **two agents' uncommitted layers
on one file** in the working tree. Practiced repeatedly in the source
program; this is the distilled procedure.

## 1. The split-commit layering procedure

**Situation**: a packet file at HEAD carries state `ISSUED`. In the working
tree it now carries (a) the worker's Return-log append and (b) the lead's
verdict block plus the State flip — two identities, one file, and R2/R7
require each identity's commit to stage its own journal with its own layer.

**Procedure**:

1. **Identify the layer boundaries** by line numbers: HEAD's line count, the
   worker's appended region, the lead's appended region and its State-flip
   edit. Verify the boundaries with `sed -n '<a>,<b>p'` before cutting —
   never cut on assumption.
2. **Reconstruct the worker-era intermediate**: HEAD's content + the
   worker's pure append, with the header State **as the worker left it**
   (the lead's flip belongs to the lead's commit). Concretely: start from
   `git show HEAD:<packet>`, append the worker's region, or equivalently
   strip the lead's layer from the tree copy.
3. **Verify pure insertion**: `git diff HEAD -- <packet>` on the staged
   intermediate must show additions only (zero non-header deletions), and
   the line arithmetic must close: intermediate = HEAD lines + worker-region
   lines, exactly.
4. **Commit per identity, in causal order**: stage the intermediate + the
   worker's journal append → commit as the worker (via
   `scripts/agent_commit.sh`, `Agent: <worker>`); then restore the full
   file (lead's layer + State flip) + the lead's journal append → commit as
   the lead. History now shows the arc in order, each layer beside its own
   reasoning.

**Why the ceremony**: the packet's diff-adjacency guarantee (PROTOCOL §1) is
only worth having if each layer sits in the commit of the agent who wrote
it. A merged blob commit under either name misattributes the other's work.

## 2. Journal truncation staging (`head -n`)

**Situation**: one agent returns **two journal entries** whose work must
land as two commits (e.g. a ruling that must demonstrably precede a freeze
in history), but both entries are already appended to the journal file in
the tree.

**Procedure**:

1. Locate the entry boundary: the line where entry N ends and entry N+1's
   header begins. Verify with `sed -n` around the boundary — the parser's
   header grammar (`## [J-<agent>-NNNN]` at column 0) makes the boundary
   unambiguous.
2. For commit 1, stage the journal **truncated** to the end of entry N:
   `head -n <boundary> <journal> > <staged copy>`. R3 holds: HEAD's content
   is a byte-prefix of the truncation, and the truncation is a byte-prefix
   of the full file.
3. Commit 1 with entry N's work files; restore the full journal; commit 2
   with entry N+1's work files. R5's monotonic ids and R2's coupling hold
   in both commits.

Boundaries verified before cutting, always — a mis-cut journal stage is an
R3 refusal at best and a corrupted append at worst.

## 3. Serializing known-concurrent agents on one file

Two agents that both need to write one file in the same period are
**serialized, not double-dispatched**: dispatch one, land its layer through
the split procedure, then dispatch the other. The one-agent-one-journal
rule makes parallel dispatch onto a shared file unlandable — there is no
commit order in which both journals couple to their own layer without one
agent's work waiting uncommitted anyway. Parallel dispatch is safe **only**
on disjoint paths *and* disjoint journals; the orchestrator checks both
before spawning, and deliberately holds back the second task when they
collide (recorded in the spawn decision's journal entry).

## 4. Packet-as-rule-propagation

Rulings made inside one packet's arc become standing practice **by being
written into the template the next packet starts from** — never by memory,
never by "we did it last time":

- an adjudication ruling ("build-configuration files join the allowlist
  explicitly") is carried into
  [`CAMPAIGN-template.md`](../../agents/handoffs/templates/CAMPAIGN-template.md)
  in the same arc that produced it;
- a review convention that survives a bounce round is carried into
  [`RV-template.md`](../../agents/handoffs/templates/RV-template.md) or
  [`review.md`](review.md);
- template edits are normal work: committed with a journal entry explaining
  which packet's arc produced the rule, so the rule's provenance is one
  `git log` away.

A rule that lives only in a closed packet's Return log is not a rule; it is
an anecdote the next packet will re-litigate.
