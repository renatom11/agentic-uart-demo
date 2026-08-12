# BUG-NNNN: <title>

<!-- Bug packet — dv_lead → rtl_lead. VERBATIM relay class (PROTOCOL §3).
     Delete these comments when instantiating. -->

- **Module / severity**: <rtl path> | CRITICAL / MAJOR / MINOR
- **Reproduction**: <exact command, runnable from a repo checkout, at a named
  SHA — a reproduction that names no SHA is not a reproduction>
- **Observed vs expected**: <what happened; what the spec requires, with the
  clause cited — the spec clause, not the golden model's opinion, is the
  authority (if the golden model itself is suspect, say so: that is a
  different packet)>
- **Provenance**: <measured / derived / relayed, per PROTOCOL §10, for every
  quantity claimed above>

## Fix verdict log

<!-- Appended by dv_lead after re-test. A fix entry must contain a
     **Root-cause** section before the fix description: a fix that cannot
     name its root cause is a symptom patch and is bounced as such. -->

- <UTC date> — `J-dv_lead-NNNN`: **Root cause**: <the defect's mechanism, in
  the designer's own journaled words or contested here>. **Fix**: <commit
  SHA, what changed>. **Re-test**: <same reproduction command, new result,
  CI run id>. **Verdict**: CLOSED | REOPENED.
