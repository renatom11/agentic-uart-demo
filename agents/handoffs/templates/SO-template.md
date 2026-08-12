# SO-<module>: PASS | FAIL

<!-- DV sign-off packet — dv_lead → orchestrator. VERBATIM relay class
     (PROTOCOL §3): the orchestrator relays this packet unedited, always.
     A PASS is a merge precondition for the module and a row in
     P<n>-module-ready. Delete these comments when instantiating. -->

- **Module / spec**: <rtl path; spec file and sections; REQ-### covered>
- **Suite**: <test names and how to run them — exact commands from a repo
  checkout, plus the CI run id that executed them (PROTOCOL §10: no gate
  signature rests on a local build)>
- **Coverage vs spec**: <requirement → test mapping; gaps declared explicitly
  — an undeclared gap found later is a DV escape>
- **Performance stress**: <result of the §8 stress bench against the
  intake-recorded performance invariant (SPEC-TEMPLATE §8), or "not
  applicable" with the spec's own one-sentence reason>
- **Mutation qualification**: <campaign WO-id; kills N/N adjudicated against
  the sealed predictions, in the named rows with the named messages; the
  scorecard's location under docs/reports/audit/WO-NNNN-mutations/. No SO-
  PASS issues on an unqualified bench (PROTOCOL §10)>
- **Open defects**: <BUG-NNNN refs, each with severity and disposition — or
  "none">
- **No-verdict disclosures**: <any check that could not run — skipped
  simulator, broken harness, blocked fetch. A no-verdict outcome is a
  distinct class from a negative verdict and never counts as coverage
  (PROTOCOL §10); "none" if everything executed>
- **Signed**: `J-dv_lead-NNNN`
