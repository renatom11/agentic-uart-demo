# WO-NNNN: <title>

<!-- Copy to agents/handoffs/WO-XXXX_<slug>.md. Drafts use a placeholder id;
     the orchestrator allocates the real NNNN at first commit (PROTOCOL §3).
     Delete these comments when instantiating. -->

- **State**: DRAFT <!-- DRAFT → ISSUED → RETURNED → ACCEPTED | BOUNCED -->
- **From** / **To**: <agent> → <agent>
- **Spec basis**: <docs/specs/… sections and REQ-### ids — the authority this
  packet acts under; a WO with no spec basis says why (e.g. process work)>
- **Deliverables**: <files to produce, every one inside the assignee's write
  scope (PROTOCOL §6)>
- **Definition of done**: <spec section satisfied | required tests and how to
  run them | journal entry appended | docs touched, or "no doc impact">
- **Context provided**: <the exact files/excerpts handed to the assignee —
  a tb_writer WO deliberately omits RTL source (PROTOCOL §10); state what was
  deliberately withheld, not only what was given>
- **Out of scope**: <explicit exclusions — what a reasonable assignee might
  do and must not>

## 1. Background

<Why this work exists now: the decision, defect, or gate row it serves.
Reference journal entries and prior packets by id.>

## 2. The task

<The ask, stated so the assignee can act from this packet plus the context
provided, without asking anyone. Numbered sub-items if separable.>

## 3. Constraints

<Standing rules that bind this work beyond the protocol: interfaces that may
not move, files that may not be read (with the enforcement stated honestly —
prompt + packet + audit, PROTOCOL §6), toolchain pins, check-in expectation
if the work can run long (armed here at issue time, PROTOCOL §3).>

## 4. What I expect back

<The shape of the return: files, the packet's Return-log entry, the journal
entry's required content (spawn short-id in Trigger for workers), and the
review that will grade it (which lead, against which criteria).>

---

## Return / verdict log

<!-- Appended on RETURNED / ACCEPTED / BOUNCED — newest at the bottom.
     Every entry cites its author's journal entry. The auditor's verdicts are
     transcribed here by the orchestrator (PROTOCOL §3). -->

- `RETURNED` <UTC date> — <assignee>, `J-<agent>-NNNN`: <one line — what came
  back, where it lives>
- `ACCEPTED | BOUNCED` <UTC date> — <reviewer>, `J-<agent>-NNNN`: <verdict
  basis; on BOUNCE, the RV- packet carrying the defect list>
