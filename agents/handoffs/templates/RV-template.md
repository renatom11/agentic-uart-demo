# RV-NNNN: ACCEPT | BOUNCE (re: WO-NNNN)

<!-- Review verdict — reviewing lead → worker, via orchestrator.
     Summarizable relay class (PROTOCOL §3), but note the information-hygiene
     rule: a verdict that describes bench internals is part of the next
     mutation campaign's sealed surface (PROTOCOL §10) — keep such content
     out of commit subjects and out of campaign-readable paths.
     Delete these comments when instantiating. -->

- **Reviewed**: <files at SHA; the WO whose return this grades>
- **Review basis**: <the spec sections and REQ-### ids the work was graded
  against — read before the work, not after (docs/playbooks/review.md)>

## Defects

### BLOCKING

<!-- Defects that force a BOUNCE: the deliverable is wrong against its spec
     basis. Numbered, each with file:line and the clause violated. -->

1. <file:line — what is wrong — spec clause violated>

### REQUIRED

<!-- Defects that do not force a bounce on their own but must be fixed
     before a named gate or packet (name it) — carried in the Return log
     and, where they outlive this packet, in the gate's carry-forward
     ledger (docs/gates/templates/). -->

1. <file:line — what must change — fix-by: <gate / packet id>>

## Nits

<!-- Non-normative observations. No bounce power; the worker may decline
     with one line of reasoning. -->

- <observation>

## Verdict

**ACCEPT | BOUNCE** — <one line: the basis, e.g. "no BLOCKING defects;
2 REQUIRED carried to P1-module-ready" or "BLOCKING 1–3; revision 2 issues
under the same WO">

- **Signed**: `J-<agent>-NNNN`
