# ADR-0005: A journal is a chain of volumes, not a file

- **Status**: **ACCEPTED (pre-adopted at seeding)** — adopted as part of the
  shell's constitution; provenance below; amendable only via PROTOCOL §11.
- **Deciders**: pre-adopted from the source program's ADR-0017 as accepted
  (proposed by architect_docs_lead, countersigned by dv_lead, accepted by
  the orchestrator). This shell adopts the design natively — PROTOCOL §4.3
  and R10 exist from the shell's first commit, so rotation is a birthright
  here, not a retrofit.
- **Scope**: journal growth: how an append-only record rolls over, what the
  chain proves, and what it deliberately does not prove.

## Context

The source program's blob gate — built to keep multi-megabyte data out of
history — fired on the org's own prose record: its busiest lead's journal
crossed 1,000,000 bytes and every future commit by that agent was blocked.
The gate's stated remedy ("large data ships as fetch script plus checksum
manifest") is structurally inapplicable to journals: R2 requires a journal
append in every work commit and R3 requires the staged bytes to continue the
file's own previous bytes — a journal shipped as a fetch script has nothing
to append to and nothing to byte-prefix. The one artifact class the protocol
*requires* in every commit was the one class the gate's remedy could not
serve. The interim was a bounded, counted override; the durable answer is
this design.

Five facts about the enforcement machinery force the shape (all verified
against the source scripts, and true of this shell's by construction):
journal files can never be deleted or renamed, so nothing existing can move;
R3 already accepts a brand-new file trivially, so a new volume needs no
exception and no "rotation mode"; R5's monotonic entry IDs are the one thing
that genuinely breaks, so they must be read across the chain; the journal
path predicates are jointly constrained by the naming scheme; and the blob
gate applied to journals only by accident of universality — no one ever
decided it should.

## Decision

1. **A journal is a chain of volume files** (PROTOCOL §4.3). Volume 1 is the
   base path and keeps it forever — every historic citation stays
   resolvable. Volume k ≥ 2 is the same path with `.md` replaced by
   `.v<k>.md`. No gaps: volume k+1 may exist only if volume k exists.
2. **Only the active volume grows.** The active volume is the
   highest-numbered one; all appends target it; every lower volume is
   frozen — byte-identical in every commit, refused for modification,
   deletion, and rename. R3's byte-prefix check applies to the active
   volume; a volume new in the commit passes trivially, as any new file
   does — deliberately, so there is no rotation mode to abuse.
3. **Entry IDs continue across volumes** and are never restarted: an ID
   identifies an entry in an agent's whole record, not in one file. Entry
   IDs are the org's citation namespace (gate signatures, countersignatures,
   ADR references); per-volume renumbering would make historic citations
   ambiguous and would destroy the cheapest drop-detector there is —
   contiguity.
4. **Back-links make append-only a property of the tree, not only of
   history.** A continuation volume's frozen header carries `Volume`,
   `Continues-from`, and `Previous-volume-sha256` (the predecessor's full
   committed bytes at the rollover commit's parent). Rewriting one byte of
   a frozen volume forces rewriting every successor's back-link — visible in
   a single checkout, with no history at all — and a dropped entry leaves an
   ID gap even in a chain whose hashes were all re-forged consistently.
   This *strengthens* the append-only guarantee relative to the single-file
   design, whose ultimate backstop is out-of-repo branch protection.
   **R10** (PROTOCOL §5) machine-enforces chain integrity per commit, and CI
   re-verifies completeness, back-link hashes, and cross-volume ID
   contiguity tree-wide at the range head.
5. **The chain does not certify the active volume.** The source's accepted
   caveat — the one sentence its dv_lead contested and replaced, applied
   verbatim there — is adopted as this shell's reading too:

   > **It does not certify the active volume**, which has no successor to
   > link back to it and whose append-only property still rests on R3 and on
   > history exactly as it does today. A green chain is not a clearance for
   > the volume currently being written.

6. **Thresholds: an 800000-byte advisory rollover warning, with the
   1000000-byte blob gate as the ceiling.** When the active volume exceeds
   800000 bytes post-append, the commit script prints a WARNING
   recommending rollover; the blob gate (PROTOCOL §5) still refuses at its
   own threshold, and for journals the recorded remedy is a volume rollover
   (§4.3), not an override.

   **Where and why this differs from the source.** The source ADR set a
   tighter dedicated pair — 256 KiB warn / 512 KiB refuse — and carved
   journals out of the blob gate entirely. Both choices were retrofit
   responses: rotation arrived mid-program with one journal already at
   1.9× the new ceiling, so journals needed their own gate the moment they
   left the blob gate's; and the soft number was anchored to a measured
   session-tool read limit the source itself marked as "the *reason* for
   the number, not the number itself" — an environment property, explicitly
   parameterized. In this shell rotation exists from birth: no journal can
   ever reach the ceiling unwarned, so one hard ceiling — the blob gate,
   which already applies to every staged file — suffices, and the advisory
   threshold sits 20% under it (roughly fifteen entries of headroom at the
   source's measured per-entry mean). One mechanism instead of two, no
   journal carve-out for CI to disagree with the commit script about, and
   the incident that motivated the source's design — the gate firing with
   no warning and no remedy but an override — is unreachable here: the
   warning always fires first, and the remedy is named in the rule.
7. **Rollover mechanics are ordinary commit mechanics.** The rollover commit
   is a normal journal-append commit by the same agent whose journal it is,
   staged as the new volume only; its first entry explains the rollover; the
   frozen volume is not touched. Rehydration reads the **active** volume of
   agents with open work; earlier volumes are the archive (PROTOCOL §9).

## Alternatives considered

Condensed from the source ADR:

- **Raise the ceiling and stop.** Rejected: it buys a handful of entries,
  and the next raise has the same argument behind it and less credibility —
  the incident-measure-becomes-policy failure this shell's ADR-0002 names.
- **Truncate the active file and archive its content.** Unimplementable
  (journal deletion and rename are refused; truncation is not an
  EOF-append) — and it would require a conditional "rotation mode" in R3,
  a mode whose existence is itself the rewrite vector the design forbids.
- **Per-agent volume directories.** Rejected: the existing file cannot move,
  so the scheme could only describe future volumes, leaving two layouts.
- **Per-volume entry renumbering.** Rejected: destroys the citation
  namespace and the contiguity drop-detector (decision 3).
- **Compact, squash, or summarize old entries.** Rejected outright: the
  org's first non-negotiable is that `git diff A..B` contains the
  reasoning; a summary is not the reasoning, and the deleted text is
  exactly what the auditor samples.
- **Ship journals as fetch script + checksum manifest** (the blob gate's own
  remedy). Incompatible with R2 and R3 by construction.
- **The source's dedicated soft/hard journal pair, verbatim.** Considered
  and not taken — see decision 6. Its readability anchor is real, and a
  future amendment may reintroduce a tighter advisory threshold if volumes
  prove unwieldy to read; that is a parameter change plus a recorded
  rationale, per the source's own treatment of the constants.

## Consequences

- No journal can block its own agent: the ceiling has a named, in-protocol
  remedy in the author's own hands, warned about 200000 bytes in advance.
- The append-only guarantee is verifiable from a bare checkout (back-links
  + contiguity), not only from history plus branch protection.
- CI's full-history re-verification stays bounded per commit by the ceiling
  instead of growing with total program length.
- Ongoing cost: one rollover per few hundred KiB of prose per agent, and a
  header block written once per volume.

## Provenance

- Source design, rationale, forcing facts, thresholds, and the contested
  active-volume sentence:
  [docs/adr/ADR-0017-a-journal-is-a-chain-not-a-file.md](https://github.com/renatom11/agentic-fpga/blob/acc814589c156e89e0ef70537bf8b22f3866dec3/docs/adr/ADR-0017-a-journal-is-a-chain-not-a-file.md)
  — landed past the seeding pin; cited at its landing commit
  (`acc814589c156e89e0ef70537bf8b22f3866dec3`, where it is ACCEPTED:
  proposed `J-architect_docs_lead-0019`, countersigned `J-dv_lead-0066`,
  accepted `J-orchestrator-0140`).
- The 1 MB incident and the bounded override (`AGENT_COMMIT_BLOB_MAX`, uses
  counted, end condition pinned to the carve-out commit):
  `J-orchestrator-0137` in
  [agents/journals/claude_orchestrator_agent.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/agents/journals/claude_orchestrator_agent.md)
  — recorded at the seeding pin itself, which is the incident commit.
- The blob gate's origin as accepted debt:
  [docs/adr/ADR-0002-adversarial-review-fixes.md](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/docs/adr/ADR-0002-adversarial-review-fixes.md)
  (decision 6, Consequences), implementation at `J-orchestrator-0015` in
  [scripts/agent_commit.sh](https://github.com/renatom11/agentic-fpga/blob/1799e10a37f19059ac3337982af4b6d035e14d0c/scripts/agent_commit.sh).
