# Handoff Packets

All inter-agent transfers are versioned files in this directory, never
chat-only ([`agents/PROTOCOL.md`](../PROTOCOL.md) §3). A packet is the unit of
delegation and the unit of return: what an agent owes, and what it is owed, is
always reconstructible from the packet file plus the journals it references.

## Packet types and relay classes

| Prefix | Name | Written by | Consumed by | Relay class |
|---|---|---|---|---|
| `WO-NNNN_<slug>.md` | Work order | A lead (or orchestrator) | A worker or lead | Summarizable |
| `SO-<module>.md` | DV sign-off packet (PASS/FAIL) | dv_lead | Orchestrator (merge precondition) | **Verbatim** |
| `BUG-NNNN_<slug>.md` | Bug packet | dv_lead | rtl_lead | **Verbatim** |
| `RV-NNNN_<slug>.md` | Review verdict (accept / defect list) | Reviewing lead | Worker (via orchestrator) | Summarizable |

**Relay rule** (PROTOCOL §3): the orchestrator may summarize *Summarizable*
traffic when routing it, but must relay *Verbatim*-class packets and all
auditor findings unedited — fidelity is load-bearing there. The auditor
spot-checks relay fidelity on the protected classes. A packet may tighten its
own relay class for a specific section (a mutation-campaign brief typically
does, in its §0); it may never loosen it.

## Lifecycle

`DRAFT → ISSUED → RETURNED → ACCEPTED | BOUNCED`

State is recorded in the packet header. A BOUNCED packet carries the defect
list and respawns as a new ISSUED revision. Participants update their packet's
Return log directly — `agents/handoffs/` is inside every agent's write scope
(PROTOCOL §6) **except the auditor's**: the auditor's verdicts live in its own
committed reports and journal, and the orchestrator transcribes them into the
Return log under its own trailer (PROTOCOL §3, auditor exception).

## Numbering authority

Numbers are zero-padded and monotonic per prefix. The **orchestrator — as sole
committer — allocates** the next `NNNN` when a packet is first committed;
drafts circulating before commit use a placeholder id (PROTOCOL §3). Nobody
else numbers anything; that is what makes monotonic-per-prefix enforceable by
a single authority.

## Templates

Every new packet starts from its type's skeleton in
[`templates/`](templates/):

- [`WO-template.md`](templates/WO-template.md) — work orders
- [`SO-template.md`](templates/SO-template.md) — DV sign-off packets
- [`BUG-template.md`](templates/BUG-template.md) — bug packets
- [`RV-template.md`](templates/RV-template.md) — review verdicts
- [`CAMPAIGN-template.md`](templates/CAMPAIGN-template.md) — mutation-campaign
  briefs (a specialised `WO-`, PROTOCOL §10)
- [`SEALED-predictions-template.md`](templates/SEALED-predictions-template.md)
  — the sealed companion a campaign brief ships with

Rule changes propagate through these templates: a ruling made inside one
packet's arc becomes standing practice by being edited into the template the
next packet starts from, never by memory (see
[`docs/playbooks/packet-splitting.md`](../../docs/playbooks/packet-splitting.md)).

## Sealed companions

A packet that says it is holding a withheld result — sealed predictions, a
sealed sweep, an undisclosed mapping — must ship that seal as a file in the
same commit: **R-SEAL-1**, PROTOCOL §10. Sealed companions are named
`WO-NNNN_<slug>-SEALED-<what>.md`, live beside their packet, and are opened
only when the packet's own unseal condition is met. A withheld result that is
not a committed artifact is not a seal, it is a claim.
