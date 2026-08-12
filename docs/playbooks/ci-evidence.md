# Playbook — CI evidence

CI is the authoritative build environment: no gate signature rests on a
local build, and evidence cites commands runnable from a checkout or
externally verifiable run ids (PROTOCOL §10). This playbook is how the org
gets evidence **out** of CI reliably, and how lanes are added without
eroding that authority. The workflow skeleton these recipes plug into is
[`.github/workflows/build.yml.template`](../../.github/workflows/build.yml.template).

## 1. The promotion-block recipe

**Problem**: when a test failure's evidence is the *content* of changed or
produced files (a snapshot diff, an expected-output correction), that
content must reach whoever repairs it — but CI log fetches are windowed
(the practiced failure: a several-thousand-line diff truncated by the log
API's fetch window, unrecoverable after artifact expiry).

**Recipe**: on failure, print every relevant file **at the log tail** in a
compact, byte-exact form:

```sh
echo '=== PROMOTION BLOCK: sha256 + base64 -w 400 of every affected path ==='
<produce the file list> | while read -r f; do
  if [ -f "$f" ]; then
    echo "--- FILE $f"
    sha256sum "$f"
    base64 -w 400 "$f"
    echo "--- END $f"
  else
    echo "--- DELETED $f"
  fi
done
echo '=== END PROMOTION BLOCK ==='
exit 1
```

Why each piece: `base64 -w 400` survives log transport byte-exactly where a
diff does not (whitespace, encoding, truncated context); the `sha256sum`
makes the promotion **byte-verifiable at apply time**; printing at the log
*tail* keeps it inside every log-fetch window, because tails are fetched
last-N-lines. The consumer decodes, checks the hash, and applies — no
artifact download, no expiry race.

## 2. The staged-diff determinism gate

One check that catches three failures — an output that changed but was
never promoted; generation that is not byte-reproducible; a produced file
that was never committed (plain `git diff` ignores untracked files, so
stage everything first):

```sh
git add -A
git diff --cached --exit-code || { <promotion block over staged paths>; }
```

Any drift fails the job, and the printed block **is** the repair source.
This gate is why simulator lanes must keep their artifacts out of the
checkout (rule R-CI-e below): a lane that litters the tree fails this gate
for someone else.

## 3. Self-tests first: an instrument must prove it can still fail

Every checking instrument — mechanical checks, comparators, emitted-output
scanners — runs its **negative fixtures first**: cases a clean tree can
never exercise, proving the check still fires. A comparator that has never
been seen to fail is not evidence; it is decoration. This is the CI-level
form of review rule 4 ([`review.md`](review.md)), and it is why a new lane
lands with a deliberate-mismatch check in its bring-up plan.

## 4. Report vs check

A line that *reports* is not a check that *gates*. PENDING, SKIPPED, and
OBLIGATION-OPEN lines never count as coverage, and no sign-off packet may
cite one. Where strictness legitimately differs by environment (a fetch
that is routine noise locally but news on the runner), the script prints
**why** it is standing down, visibly, rather than taking a flag that lets a
reader mistake "could not check" for "checked and fine".

## 5. The NO-VERDICT class recipe

A broken harness is never reportable as a finding about the thing under
test, and a skipped lane is never a PASS (PROTOCOL §10). Mechanically:

- distinct exit codes / printed classes for "checked and failed" vs "could
  not check" (harness error, missing dependency, blocked egress);
- the runner maps "could not check" to a **red job with a NO-VERDICT
  marker in the log** — red so nobody ships on it, marked so nobody files
  it as a defect against the subject;
- adjudication treats NO-VERDICT as "the question is still open", never as
  evidence in either direction.

## 6. A lane's own seam into CI

Each verification lane gets **one wrapper script in its own write scope**
(e.g. `tools/<lane>_checks.sh`, dv-owned) that the workflow calls as a
single step. The lane then adds, reorders, and gates its checks by editing
its own script — no `.github/**` edit, no orchestrator round trip (R7: only
the orchestrator stages `.github/**`) — and the auditor re-executes the
whole lane with one command at any SHA. The workflow stays a thin list of
seams; the checks live with the lane that owns them.

## 7. The R-CI checklist walk (adding a simulator or external-tool lane)

Walk every new lane through this list; each rule exists because its absence
was once paid for. Record the walk in the lane's ADR.

- **R-CI-a — own job, not a step.** A lane failure must be attributable to
  the lane, the main suite must not wait on the lane's dependencies, and
  the lane's artifacts must not reach the main job's determinism gate.
- **R-CI-b — distribution install.** Dependencies come from the runner
  distribution's archive (`apt-get install -y <pkg>`) — no third-party
  archives, no source builds. A failed install fails the job, never a
  silent skip.
- **R-CI-c — version sidecar.** The lane records tool versions **into its
  output artifacts** (a `.meta` sidecar), not only into the log: a
  reproducibility guarantee whose condition is not in the record is not
  checkable. Never inside the compared file itself — that would make the
  comparison fail on version churn.
- **R-CI-d — written de-gating condition.** A lane may land
  non-blocking (`continue-on-error: true`), but the condition under which
  the gate comes off is **written down at landing** (e.g. "after the
  deliberate-mismatch check has demonstrated the comparator fires"), and
  the de-gating is its own later commit citing that condition. A
  permanently non-blocking lane is decoration.
- **R-CI-e — artifacts outside the checkout.** Everything the lane writes
  goes outside the checkout (e.g. `$RUNNER_TEMP`) or to a path
  `.gitignore`d in the same change — protecting the determinism gate and
  every agent's `git status`.
- **R-CI-f — evidence to the log.** On failure, the adjudication evidence
  (stimulus, both compared outputs, the diff) is printed to the log —
  promotion-block form for anything long — or uploaded as a workflow
  artifact **with the journal citing it as ephemeral** (PROTOCOL §4.1).
  A finding that cannot be adjudicated from the record is not a finding.
- **R-CI-g — same trigger as the build.** The lane runs on the same push
  events, not a schedule: a scheduled lane produces failures attributable
  to no commit.
- **R-CI-h — no fetch step.** Reference inputs live in the checkout; a
  lane that fetches at run time has an unrecorded dependency. State the
  exception explicitly if one is ever taken, so its absence is a decision
  rather than an omission.
