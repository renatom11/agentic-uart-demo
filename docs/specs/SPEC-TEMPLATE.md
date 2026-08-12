# Per-module specification template

- **Status**: normative form for every module specification in this program
- **Owner**: architect_docs_lead
- **Applies to**: every module in the phase's architecture inventory, written
  to `docs/specs/modules/<snake_case_name>.md`

---

## How to use this template

1. Copy everything below the horizontal rule marked **TEMPLATE BEGINS** into
   `docs/specs/modules/<module>.md` and fill every section. A section that
   does not apply is answered with "not applicable" **and one sentence of
   why** — never deleted, because the auditor checks the form against this
   file.
2. **A specification is written before its RTL exists.** No module may be
   implemented against a DRAFT spec; the freeze record at the bottom is what
   makes it implementable (PROTOCOL §7).
3. **Write for two readers who never speak to each other**: an implementer
   who will produce HDL in the M1 toolchain from this text alone, and a test
   writer who will receive spec *excerpts* with the RTL deliberately withheld
   (PROTOCOL §10). If a sentence only makes sense to someone who has seen the
   code, rewrite it.
4. **Every behavioural claim traces to a REQ** in
   `docs/specs/requirements.md`. A behaviour with no REQ is either a missing
   requirement — raise it, do not invent it locally — or an implementation
   choice that belongs in §6.3 as explicitly unconstrained.
5. **Banned phrasing**: "as needed", "appropriately", "should normally",
   "obviously", "TBD" outside §11, and any behaviour described only by
   reference to another module's implementation. Each is an ambiguity a test
   writer cannot resolve.
6. **The §4.1 interface block is this template's toolchain slot.** Where the
   M1 toolchain supports compile-checked interface records, the block is
   lifted verbatim into the interface-check lane the M1 ADR names (e.g.
   `docs/specs/ifc_check/`) and must compile against the pinned toolchain in
   CI before freeze. Where it does not, the stated fallback is the §4.2 port
   table, reviewed line-by-line at the dv_lead countersignature. The M1 ADR
   records which regime this program runs under; each spec's §12 freeze
   record says which regime it froze under.
7. After freeze, any change to §4, §6 or §7 is a **spec diff plus an ADR**;
   §13 records it. Editorial changes elsewhere need only a journal entry.

---

**TEMPLATE BEGINS**

---

# SPEC-M<nn> — `<Module_name>`

- **Status**: DRAFT | FROZEN (`P<n>-spec-freeze`, SHA `<sha>`)
- **Inventory id**: M<nn> (architecture inventory) · **Path**:
  `rtl/<path>/<snake_case_name>.<ext>`
- **Datapath role**: <e.g. receive | transmit | shared/structural — the
  program's own chain vocabulary from the architecture document>
- **Owns REQs**: REQ-###, REQ-### …
- **Prior-art counterpart**: <reference module, with its intake-recorded
  license class> — consulted for decomposition and port naming only;
  behaviour below is stated independently and no source was copied. For a
  **consult-only** reference this sentence is load-bearing (PROTOCOL §10).
- **Depends on specs**: SPEC-M<nn> …
- **Author**: architect_docs_lead, journal `J-architect_docs_lead-NNNN`

## 1. Purpose

Two to five sentences: what this module turns into what, and why it exists as
a separate module. State its position in the datapath by naming its immediate
upstream and downstream modules.

## 2. Scope

- **In scope**: the behaviours this module is solely responsible for.
- **Not this module's job**: behaviours a reader might reasonably expect
  here, with the module that does own them. This section prevents duplicated
  or orphaned requirements at module boundaries.

## 3. Programme invariants that bind this module

List the programme-wide REQ invariants that apply, one line each, with the
module-specific consequence. Do not paraphrase the requirement text — cite
the id and state what it forces here. Whether an invariant binds this module
— and for which of its ports — is decided by `requirements.md`'s own
applicability rules, not by judgement: a structural module is on a
constrained path only with respect to the ports that lie on that chain.

## 4. Interface

### 4.1 Interface records (toolchain slot — how-to-use item 6)

```
<The module's complete interface as compile-checked interface records in the
 M1 toolchain: declarations only — records/types and entry-point signatures,
 no logic, no implementation. Lifted verbatim into the interface-check lane
 and compiled in CI before freeze.

 Where the M1 toolchain supports no compile-checked records, this block
 states: "Fallback regime per the M1 ADR: the §4.2 port table is the
 normative interface, reviewed line-by-line at countersignature." >
```

Rules for this block:

- Every field states its width; one-bit fields may rely on the record type's
  default.
- Where a programme invariant is structural, encode it structurally: a
  module that must never exert backpressure exposes **no** ready/backpressure
  signal in its record — a design that needs one cannot be written without a
  spec diff, which is the point.
- Shared programme-wide types are defined once, in the module that owns them,
  and referenced — never restated — by every other spec.
- Every module exposes both a flat entry point and a hierarchical/wrapped
  form where the toolchain distinguishes them, per the M1 ADR's conventions.

### 4.2 Port table

| Port | Dir | Width | Meaning | REQ |
|---|---|---|---|---|
| `clock` | in | 1 | <the clock domain, with its intake-recorded frequency> | REQ-### |
| `clear` | in | 1 | synchronous clear | REQ-### |
| `<port>` | in/out | n | one sentence, stating the units and the encoding | REQ-### |

Every port in §4.1 appears in this table exactly once. Reserved or unused
fields say so and name the REQ that permits them.

### 4.3 Configuration inputs

Fields of any configuration record this module reads, their effect, and when
a change takes effect. "None" is a valid answer.

## 5. Parameters

Compile-time parameters, with default, permitted range, and the reason a
test might override it. Timeouts and ageing intervals **must** be parameters
so tests can use short values.

| Parameter | Type | Default | Range | Why a test overrides it |
|---|---|---|---|---|

## 6. Behaviour

### 6.1 Normal path

Prose plus, where there is sequencing, a cycle-by-cycle table for one
representative transaction. Name every field of every header or record this
module reads or writes, with its offset and its width, so a test writer can
build the stimulus without a protocol reference open.

### 6.2 State machine

| State | Entered when | Does | Leaves to |
|---|---|---|---|

Include the reset state and state on `clear`. If the module is
combinational, say so and cite the REQ that permits statelessness.

### 6.3 Deliberately unconstrained

Behaviour the implementer may choose freely (internal encodings, pipeline
placement within the stated latency, which of several legal orderings is
used). Anything not listed here is constrained by this specification, and a
test may rely on it.

## 7. Timing contract

- **Latency**: stated in the unit `requirements.md` defines for this
  program, as an exact figure — not a bound — wherever the programme
  invariants require constant latency, with the measurement events named
  explicitly at both ends. Do not state latency between events that are not
  single, well-defined observables; if the figure varies by input alignment,
  pin one constant per alignment case and bound their difference.
- **Throughput**: units accepted per cycle, and any cycle in which the
  module cannot accept input — with the REQ that permits or forbids such
  cycles.
- **Handshake rules**: when `valid`-class signals may assert and deassert,
  how long fields stay stable, the permitted relationship between a header's
  validity and its payload, and behaviour on idle gaps.
- **Reset**: what is true within one cycle of `clear` deasserting, and what
  happens to a transaction in flight when `clear` asserts.
- **Configuration sampling**: when configuration inputs are latched.

## 8. Performance stress obligation

**Mandatory for every module on the stress-bench list `requirements.md`
derives from the intake-recorded performance criteria (G0 Section B). Every
other module states "not applicable" with one sentence of why — for a
structural wrapper, that its children's benches cover it and it adds no
datapath logic of its own.**

The module SHALL be exercised by a bench that:

1. drives the **worst-case legal stimulus** for the intake-recorded
   performance invariant — minimum-size transactions at minimum legal
   spacing, covering every input-alignment case this module can see, derived
   by construction from the programme-level stimulus definition in
   `requirements.md` and never re-invented here;
2. runs for a sustained transaction count `requirements.md` fixes
   programme-wide, every transaction of which this module accepts and
   forwards, so that conservation (out equals in) is well defined even for a
   module that legitimately discards;
3. checks conservation, payload equality, no dropped units, and that the §7
   latency contract holds under stress;
4. records which of its guarantees are structural (encoded in the §4.1
   record, not assertable by a bench) and which the bench asserts.

State here the exact stimulus this module needs (transaction contents,
header field values, error injection rate) so the bench can be written from
this section alone.

## 9. Errors and discards

Every abnormal condition, its report strobe, and its effect on the output
stream. Strobe names are normative and come from `requirements.md`.

State also, below the table, **which of these conditions can co-occur on one
transaction and which strobes then pulse**, and for each condition whether
the transaction is marked-and-forwarded or discarded before any unit is
emitted. The general precedence and multiplicity rules live in
`requirements.md`; this section says how they land for this module, because
that is what a bench asserts.

| Condition | Strobe (one cycle) | Stream effect | REQ |
|---|---|---|---|
| … | `error_…` | forwarded-marked / not forwarded / truncated at unit n | REQ-### |

Silent discard is prohibited where `requirements.md` says so: every row has
a strobe, or names the REQ that exempts it.

## 10. REQ coverage

Every REQ this module owns, plus every programme invariant from §3.

| REQ | How this module satisfies it | Section | Verification hook for DV |
|---|---|---|---|
| REQ-### | one sentence | §6.1 | directed test / stress bench / co-simulation / property |

This table is the source of the module's rows in the traceability matrix;
update the matrix in the same commit.

## 11. Deferred items

Numbered, each with an owner and the gate or work order it closes by. "None"
is a valid answer. Item numbers are **permanent**: a closed item keeps its
number and its row, with the closure recorded in place, because
countersignatures and work-order logs cite these numbers and a renumbered
table makes those citations lie.

**DRAFT versus FROZEN.** A DRAFT spec may carry an *open question* — an item
whose answer is not yet known and which something downstream cannot be built
without. **A FROZEN spec SHALL carry no open question.** It MAY carry a
*deferred item*, which is a different thing: a decision this specification
has already made and stated in its own normative sections, whose remaining
work (a script, a compile run, a wording fix in another file) is tracked
elsewhere. Every deferred item in a FROZEN spec SHALL state, in this order:

1. **Where it is tracked** — a carry-forward ledger row (`C-nn` in the
   phase's spec-freeze checklist) or a work-order id — so the item cannot be
   closed silently or forgotten;
2. **What a reader assumes meanwhile** — one sentence an implementer or a
   test writer can act on today, without waiting for the item and without
   asking anyone. A frozen specification that leaves a reader blocked is not
   frozen;
3. **Owner and closing gate.**

An item that cannot state (2) is an open question, whatever it is called,
and a spec carrying one may not be frozen. That is the whole force of this
rule: freezing means nobody downstream is blocked — not that nothing is left
to do.

Recommended form (Status is `OPEN`, `DEFERRED` or `CLOSED`):

| # | Item | Status · what a reader assumes meanwhile | Tracked as | Owner | Closes by |
|---|---|---|---|---|---|

## 12. Freeze record

Filled in at `P<n>-spec-freeze`. All four rows are required.

| Item | Value |
|---|---|
| Interface check | Compile-check regime: CI run `<id>`, conclusion `<success>`, SHA `<sha>` — a local build is not acceptable evidence (PROTOCOL §10). Fallback regime: reviewed port table, `J-dv_lead-NNNN` |
| Architect signature | `J-architect_docs_lead-NNNN` |
| dv_lead testability countersignature | `J-dv_lead-NNNN` |
| Frozen at | SHA `<sha>`, gate `docs/gates/P<n>-spec-freeze-checklist.md` |

## 13. Change log

Post-freeze changes only. Each row cites the ADR that authorised it; a
breaking interface change is counted against post-freeze churn.

| Date | Change | Breaking? | ADR | Journal |
|---|---|---|---|---|
