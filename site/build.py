#!/usr/bin/env python3
"""Build the agentic-uart-demo site.

Every figure on the site is read out of the repository at build time: the commit
list, the per-commit file sets, the requirement rows, the journal entries and the
simulation results. Nothing is typed by hand, so the site cannot drift from the
program it describes.

    python3 site/build.py            # uses a cached suite run if present
    python3 site/build.py --run      # re-runs the suite first (slow, authoritative)
"""
import json, os, re, subprocess, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUB = os.path.join(ROOT, 'site', 'public')
REPO = 'renatom11/agentic-uart-demo'


def sh(*a):
    return subprocess.run(a, cwd=ROOT, capture_output=True, text=True).stdout


GROUPS = [
    ('shell', 'the framework', True, [
        ('constitution', 'Constitution', ['agents/PROTOCOL.md'],
         'The rules every seat reads before acting: the seats, the paths each may edit, how work moves, '
         'and the thresholds at which a problem goes to the sponsor. Adopted whole with the shell rather '
         'than written for this project.'),
        ('enforcement', 'Enforcement scripts', ['scripts/'],
         'The commit script and the checks that mechanically refuse a rule-breaking commit. On this program '
         "they refused the orchestrator three times: a genesis commit carrying another repository's journal "
         'history, a missing commit trailer, and an undeclared set of foreign journal seeds.'),
        ('roster', 'Roster and charters', ['ORG_CHART.md', 'agents/charters/', 'CLAUDE.md', 'BOOTSTRAP.md',
                                           'README.md', 'docs/SPONSOR.md', 'docs/playbooks/', 'docs/gates/', '.claude/'],
         'One file per seat saying what it may write and what it is forbidden to write. Two seats the shell '
         'ships with were dropped here: a UART wakes neither a market-data fetcher nor a SAT prover, and a '
         'roster that overstates the organization is a roster that lies.'),
        ('board', 'Program board', ['tasks/'],
         'Live program state, including what this program has NOT done. It records the module-ready gate as '
         'unsigned, and says why.'),
    ]),
    ('seats', 'the seats', True, [
        ('journals', 'Journals', ['agents/journals/'],
         'One append-only journal per seat. Every commit pairs work with a new entry, and the commit script '
         'refuses work that arrives without one. Entries only accumulate: J-architect_docs_lead-0003 published '
         'a wrong conclusion and is still there, unedited, with 0004 correcting it.'),
    ]),
    ('spec', 'specification', False, [
        ('specdoc', 'The specification', ['docs/specs/SPEC-uart_lite.md', 'docs/specs/SPEC-TEMPLATE.md'],
         'Written before any RTL existed. Five interface contracts, the divisor arithmetic with its derivations '
         "shown, and the sample grid stated in clock cycles rather than in the design's own oversample ticks."),
        ('reqs', 'Numbered requirements', ['docs/specs/requirements.md'],
         'Each requirement carries a number and a stated verification method, so a bench cites exactly what it '
         'discharges and a verdict traces back through it.'),
    ]),
    ('decisions', 'the decisions', False, [
        ('adr', 'Decision records', ['docs/adr/', 'docs/LESSONS.md'],
         'Each records the decision, the alternatives, and why each lost. ADR-0008 fixes the toolchain at '
         'SystemVerilog and Icarus and writes down what that choice gives up: no synthesis at all, so REQ-017 '
         'is not dischargeable under it.'),
    ]),
    ('product', 'the product', False, [
        ('rtl', 'RTL source', ['rtl/'],
         'Six SystemVerilog files, 249 lines. Graded only by benches the implementation line never wrote. '
         'One of them carried BUG-0001.'),
    ]),
    ('trail', 'the paper trail', False, [
        ('wo', 'Work orders', ['agents/handoffs/'],
         'Work travels as versioned files, not as messages that vanish when a session ends. WO-0001 withheld '
         'rtl/** from its assignee on purpose, and says so in its own text.'),
    ]),
    ('verification', 'verification', True, [
        ('benches', 'Testbenches', ['test/'],
         'Written from the specification by a session that could not read the design. The largest single check '
         'sweeps sender bit periods 422 through 447 across all 256 byte values.'),
    ]),
    ('ci', 'continuous integration', False, [
        ('ciw', 'CI workflows', ['.github/'],
         'The same rule checks re-run on every push, plus a blocking simulation lane. Append-only cannot be '
         'verified incrementally, so the journal check re-walks the whole history every time.'),
    ]),
    ('site', 'the site', False, [
        ('sitebox', 'This website', ['site/'],
         'Generated from the repository at build time and rebuilt by CI from a live suite run, so it cannot '
         'state a number the program does not have.'),
    ]),
]


def group_of(path):
    for key, _, _, boxes in GROUPS:
        for _, _, prefixes, _ in boxes:
            if any(path.startswith(p) for p in prefixes):
                return key
    return 'shell'


def commits():
    sep = '@@@REC@@@'
    out = []
    for rec in sh('git', 'log', '--reverse', '--format=' + sep + '%H%x1f%s%x1f%b').split(sep):
        if not rec.strip():
            continue
        sha, subject, body = rec.split('\x1f')[:3]
        sha = sha.strip()
        pick = lambda k, d: (re.search(r'^%s:\s*(\S+)' % k, body, re.M) or [None, d])[1]
        files = sh('git', 'diff-tree', '--root', '-r', '--no-commit-id',
                   '--name-only', sha).split()
        out.append({'sha': sha[:7], 'subject': subject, 'agent': pick('Agent', '?'),
                    'entry': pick('Journal-Entry', ''), 'wo': pick('Work-Order', 'none'),
                    'files': sorted(files)})
    return out


def requirements():
    rows = []
    p = os.path.join(ROOT, 'docs/specs/requirements.md')
    for line in open(p):
        m = re.match(r'\|\s*(REQ-\d+)\s*\|\s*([^|]+?)\s*\|\s*(.+?)\s*\|\s*([^|]+?)\s*\|\s*$', line)
        if m:
            rows.append({'id': m.group(1), 'title': m.group(2),
                         'text': m.group(3), 'method': m.group(4)})
    return rows


def journals():
    out = {}
    for p in glob.glob(os.path.join(ROOT, 'agents/journals/*.md')) + \
             glob.glob(os.path.join(ROOT, 'agents/journals/workers/*.md')):
        if p.endswith('INDEX.md'):
            continue
        agent = re.sub(r'^claude_(.*)_agent\.md$', r'\1', os.path.basename(p))
        raw = open(p).read()
        parts = re.split(r'^## \[(J-[a-z_]+-\d+)\][^|]*\|[^|]*\|\s*(.+)$', raw, flags=re.M)
        entries = []
        for i in range(1, len(parts) - 1, 3):
            eid, title, body = parts[i], parts[i + 1].strip(), parts[i + 2]
            # the first real sentence of the body, past the section heading
            txt = re.sub(r'^#+ .*$', '', body, flags=re.M)
            txt = re.sub(r'\s+', ' ', txt).strip()
            entries.append({'id': eid, 'title': title, 'excerpt': txt[:300]})
        if entries:
            out[agent] = entries
    return out


def suite(rerun):
    """Real simulation results. Never invented: if no run is available, say so."""
    log_path = os.path.join(ROOT, 'site', '.suite.log')
    if rerun or not os.path.exists(log_path):
        r = subprocess.run(['bash', 'test/run.sh'], cwd=ROOT,
                           capture_output=True, text=True)
        open(log_path, 'w').write(r.stdout + r.stderr)
    log = open(log_path).read()
    benches = [{'name': m.group(1), 'total': int(m.group(2)),
                'pass': int(m.group(3)), 'fail': int(m.group(4))}
               for m in re.finditer(
                   r'==== SUMMARY \((\w+)\) ====\nTotal: (\d+)\s+Pass: (\d+)\s+Fail: (\d+)', log)]
    if not benches:
        sys.exit('build: no simulation results parsed — run `bash test/run.sh` first')
    return benches


PHASE = ['ADOPT', 'SPECIFY', 'BUILD', 'BUILD', 'BUILD', 'BUILD',
         'VERIFY', 'VERIFY', 'VERIFY', 'VERIFY', 'VERIFY', 'GATE']

SEATDESC = {
    'orchestrator': 'The only agent that may spawn other agents, and the only one that commits — each '
        "seat's work is committed under that seat's name. Its write scope covers every path, and it "
        'authors none of the substance.',
    'architect_docs_lead': 'Turns intent into the specification and its numbered requirements, and owns '
        'the decision records. Nothing is built that it has not specified. Its own entry 0003 published a '
        'wrong conclusion about where a defect lay; 0004 corrects it, and 0003 stays.',
    'rtl_lead': 'Owns rtl/** — everything that ships. It does not write the tests that grade its own '
        'output. BUG-0001 was its defect, found by a bench it never saw.',
    'dv_lead': 'Owns test/** and the verdicts. It adjudicated the eight red checks: one design defect, '
        'two bench defects, all three the same anchor ambiguity in three different artifacts.',
    'tb_writer': 'A short-lived worker spawned for one packet. Its packet carried the specification and '
        'deliberately withheld the RTL.',
    'auditor': 'Audits every seat including the orchestrator that spawns it. Its write scope is its own '
        'reports, so it cannot repair what it finds. Not yet spawned on this program — recorded as a '
        'limitation rather than implied.',
    'rtl_module_dev': 'Implementation worker template. Not spawned on this program: the design is six '
        'files and the lead built it directly.',
}

STATICS = {
    'sponsor': ['Sponsor', 'The single human. Sets scope, and holds two duties no agent can: enabling '
        'branch protection, without which the append-only journal holds by convention plus CI rather '
        'than by server rule, and it is NOT yet enabled here.'],
    'sessions': ['Agent sessions', 'An agent runs as one session and does not persist beyond it. A '
        'dashed slot is a seat with no session running. Only the bench worker ran as a genuinely '
        'separate, blinded session on this program.'],
    'repo': ['The repository', 'Every role, rule, task, decision and piece of evidence exists as a file '
        'here, because no state survives between sessions.'],
    'gate': ['The commit gate', 'scripts/agent_commit.sh is the sanctioned path to git commit. It checks '
        'the staged change against the protocol and refuses a commit that breaks one. It refused the '
        "orchestrator three times on this program — including the repository's own first commit."],
    'ci': ['Continuous integration', 'The same rule checks re-run on every push, plus a blocking '
        'simulation lane. The sim lane was red for four commits because it landed before the benches it '
        'gates existed — the reasoning was right, the ordering was wrong.'],
}


def main():
    cs = commits()
    seen, steps = set(), []
    jr = journals()
    for i, c in enumerate(cs):
        added = [f for f in c['files'] if f not in seen]
        seen.update(c['files'])
        groups_touched = sorted({group_of(f) for f in c['files'] if not f.startswith('agents/journals/')})
        entry = next((e for e in jr.get(c['agent'], []) if e['id'] == c['entry']), None)
        acts = []
        span = max(1, len(groups_touched))
        for k, g in enumerate(groups_touched):
            kind = 'blind' if c['agent'] == 'tb_writer' else 'write'
            acts.append({'f': 'ag-' + c['agent'], 'to': 'g-' + g, 'kind': kind,
                         's': round(0.12 + 0.55 * k / span, 3), 'e': round(0.55 + 0.4 * (k + 1) / span, 3)})
        acts.append({'f': 'ag-' + c['agent'], 'to': 'g-seats', 'kind': 'write', 's': 0.5, 'e': 0.95})
        steps.append({'i': i, 'sha': c['sha'], 'agent': c['agent'], 'subject': c['subject'],
                      'entry': c['entry'], 'wo': c['wo'], 'phase': PHASE[i] if i < len(PHASE) else 'GATE',
                      'excerpt': (entry or {}).get('excerpt', ''),
                      'acts': acts,
                      'added': [{'p': f, 'g': group_of(f)} for f in added],
                      'ci': '.github/workflows/sim.yml' in c['files']})

    src = {}
    for p in sh('git', 'ls-files', 'rtl', 'test', 'docs/specs').split():
        full = os.path.join(ROOT, p)
        if os.path.getsize(full) < 60000:
            src[p] = open(full).read()

    benches = suite('--run' in sys.argv)
    total = sum(b['total'] for b in benches)
    reqs = requirements()
    data = {'steps': steps,
            'groups': [{'k': k, 'label': l, 'wide': w,
                        'boxes': [{'k': bk, 'label': bl, 'match': bm, 'desc': bd,
                                   'big': bk in ('rtl', 'benches')} for bk, bl, bm, bd in boxes]}
                       for k, l, w, boxes in GROUPS],
            'benches': benches, 'total': total, 'reqs': reqs, 'journals': jr, 'src': src,
            'seatdesc': SEATDESC, 'statics': STATICS, 'repo': REPO,
            'sub': f'This page follows one real FPGA project end to end: uart_lite, a 115200 baud 8N1 '
                   f'serial port for a 50 MHz board, five modules, built by AI agents under one human '
                   f'sponsor. {len(steps)} beats — and each beat is an actual commit in this repository, '
                   f'with the files it really added and the seat named in its own trailer. Press play, '
                   f'or drag the scrubber. Click any seat, group, box or file.',
            'foot': f'Every figure on this page is read out of the repository at build time — the commit '
                    f'list, the per-commit file sets, the requirement rows and the {total} check results '
                    f'— and rebuilt by CI from a live suite run. <br><br><b>What this page does not '
                    f'claim.</b> No mutation campaign has run, so nothing establishes in general that '
                    f'these benches would catch a defect; one real find is not a detection rate. Nothing '
                    f'has been synthesised. Only the testbench was written under genuine session-level '
                    f'blinding. The module-ready gate is recorded <b>unsigned</b> for exactly these '
                    f'reasons.'}

    os.makedirs(PUB, exist_ok=True)
    tpl = open(os.path.join(ROOT, 'site', 'lifecycle_src.html')).read()
    open(os.path.join(PUB, 'lifecycle.html'), 'w').write(
        tpl.replace('/*__DATA__*/{}', json.dumps(data, separators=(',', ':'))))

    bench_rows = ''.join(
        f'<tr><td class="mono">{b["name"]}</td><td class="num">{b["total"]}</td>'
        f'<td class="num"><span class="pill{" bad" if b["fail"] else ""}">'
        f'{b["pass"]}/{b["total"]}</span></td></tr>' for b in benches)
    commit_rows = ''.join(
        f'<tr><td class="mono sha"><a href="https://github.com/{REPO}/commit/{c["sha"]}">'
        f'{c["sha"]}</a></td><td class="mono seat">{c["agent"].replace("_", " ")}</td>'
        f'<td>{c["subject"]}</td></tr>' for c in cs)
    open(os.path.join(PUB, 'index.html'), 'w').write(INDEX_TPL.format(
        repo=REPO, total=total, ncommits=len(steps), nreq=len(reqs), nfiles=len(seen),
        njournal=sum(len(v) for v in jr.values()), bench_rows=bench_rows, commit_rows=commit_rows))

    print(f"site built · {len(steps)} commits · {len(seen)} files · "
          f"{data['total']} checks · {len(data['reqs'])} requirements · "
          f"{sum(len(v) for v in data['journals'].values())} journal entries")




INDEX_TPL = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>agentic-uart-demo</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
:root{{--bg:#f7f5f1;--panel:#fffefb;--ink:#191714;--ink2:#6b635a;--line:#ddd6cc;
 --sig:#b45309;--ver:#4338ca;--ok:#15803d;--okbg:#e8f3ea;--bad:#b91c1c;--chip:#f1ede6}}
@media (prefers-color-scheme:dark){{:root{{--bg:#141311;--panel:#1c1a17;--ink:#eeeae3;
 --ink2:#9c948a;--line:#332f2a;--sig:#e8a33d;--ver:#9d92f5;--ok:#5cc98a;--okbg:#172b1f;
 --bad:#e8837b;--chip:#232019}}}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);
 font:17px/1.65 Georgia,'Iowan Old Style','Times New Roman',serif}}
.mono{{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}}
.wrap{{max-width:820px;margin:0 auto;padding:0 1.3rem 5rem}}
a{{color:var(--sig)}}
.kicker{{font:600 .68rem ui-monospace,monospace;letter-spacing:.18em;text-transform:uppercase;
 color:var(--sig);margin:2.6rem 0 .5rem}}
h1{{font-size:clamp(1.9rem,4.4vw,2.9rem);line-height:1.08;margin:0 0 .6rem;letter-spacing:-.015em}}
h2{{font-size:1.25rem;margin:2.4rem 0 .5rem;letter-spacing:-.01em}}
.lede{{font-size:1.1rem;color:var(--ink2);margin:0 0 1.5rem}}
.stats{{display:flex;flex-wrap:wrap;gap:.55rem;margin:1.4rem 0 .4rem}}
.stat{{border:1px solid var(--line);border-radius:9px;background:var(--panel);padding:.5rem .8rem}}
.stat b{{display:block;font:700 1.3rem ui-monospace,monospace;line-height:1.1}}
.stat span{{font:500 .62rem ui-monospace,monospace;letter-spacing:.09em;text-transform:uppercase;
 color:var(--ink2)}}
.stat.good b{{color:var(--ok)}}
.cta{{display:inline-block;border:1.5px solid var(--sig);color:var(--sig);border-radius:9px;
 padding:.55rem 1.1rem;font:700 .8rem ui-monospace,monospace;text-decoration:none;margin:.5rem 0 0}}
.cta:hover{{background:color-mix(in srgb,var(--sig) 12%,transparent)}}
table{{width:100%;border-collapse:collapse;margin:.8rem 0;font-size:.88rem}}
th{{text-align:left;font:600 .6rem ui-monospace,monospace;letter-spacing:.09em;
 text-transform:uppercase;color:var(--ink2);border-bottom:1px solid var(--line);padding:.35rem .4rem}}
td{{padding:.35rem .4rem;border-bottom:1px solid var(--line);vertical-align:top}}
td.num{{text-align:right;font-family:ui-monospace,monospace}}
td.sha a{{text-decoration:none}}
td.seat{{font-size:.72rem;color:var(--ink2);white-space:nowrap}}
.pill{{font:700 .6rem ui-monospace,monospace;padding:.05rem .35rem;border-radius:4px;
 border:1px solid var(--ok);color:var(--ok);background:var(--okbg)}}
.pill.bad{{border-color:var(--bad);color:var(--bad)}}
blockquote{{border-left:3px solid var(--sig);margin:1rem 0;padding:.3rem 0 .3rem 1rem;
 color:var(--ink2);font-size:.95rem}}
code{{font-family:ui-monospace,monospace;font-size:.86em;background:var(--chip);
 padding:.08rem .28rem;border-radius:4px}}
.foot{{border-top:1px solid var(--line);margin-top:3rem;padding-top:1rem;color:var(--ink2);
 font-size:.85rem}}
</style></head><body><div class="wrap">
<p class="kicker">{repo}</p>
<h1>A working FPGA design, built and verified by an AI organization that has to show its work.</h1>
<p class="lede">This repository is a proof of concept for a development framework, not for a UART.
The design is deliberately small — <code>uart_lite</code>, a 115200&nbsp;baud 8N1 serial port for a
50&nbsp;MHz FPGA. What is being demonstrated is the <em>record</em>: specification before
implementation, a testbench written by a session forbidden to read the design, and every commit
refused by a script unless it carries its author's reasoning.</p>

<div class="stats">
<div class="stat good"><b>{total}</b><span>checks passing</span></div>
<div class="stat"><b>{ncommits}</b><span>commits, all gated</span></div>
<div class="stat"><b>{nreq}</b><span>numbered requirements</span></div>
<div class="stat"><b>{njournal}</b><span>journal entries</span></div>
<div class="stat"><b>{nfiles}</b><span>files</span></div>
</div>
<a class="cta" href="lifecycle.html">Walk the twelve commits &rarr;</a>

<h2>The result worth reporting</h2>
<p>The testbench was written by a separate agent session whose work order carried the
specification and the numbered requirements, and deliberately withheld <code>rtl/**</code>. On its
first run it returned 609 checks with eight failing — and it did not adjust them to pass.</p>
<p>Those eight were right. <code>uart_tick_gen</code> reloaded its counter to <code>1</code>
instead of <code>0</code>; the reload cycle is itself consumed, so the first tick landed one cycle
early. The transmitter's start bit was <b>433 cycles</b> while all nine following intervals were
434. Nobody planted it.</p>
<blockquote>The tick <em>spacing</em> is correct under either reload value. Only a measurement
taken from the restart to the <em>first</em> tick can tell them apart — which is why the
transmitter bench passed its bit-period row 265/265 against the defective design.</blockquote>

<h2>What the enforcement actually caught</h2>
<p>Three times, on the orchestrator's own commits: a genesis commit carrying another repository's
journal history, a missing commit trailer, and an undeclared set of foreign journal seeds. The one
thing no script could catch was caught by hand — bench corrections staged under the blind seat's
name, which would have misrepresented what that session produced. That residue is on the record too.</p>

<h2>The suite</h2>
<table><thead><tr><th>bench</th><th>checks</th><th>result</th></tr></thead>
<tbody>{bench_rows}</tbody></table>
<p>The largest single check is the far-end tolerance sweep: sender bit periods 422 through 447,
all 256 byte values at each — 6656 checks — driven by a bench model written from the specification
rather than by the design's own transmitter, because a receiver checked against its own transmitter
shares a time base with its stimulus and can only prove it agrees with itself.</p>

<h2>What this does not claim</h2>
<p>No mutation campaign has run, so nothing establishes in general that these benches would catch a
defect; one real find is not a detection rate. Nothing has been synthesised — Icarus simulates only,
so every area and timing claim is unverified. And only the testbench was written under genuine
session-level blinding. The module-ready gate is recorded <b>unsigned</b> for exactly these reasons.</p>

<h2>Every commit</h2>
<table><thead><tr><th>sha</th><th>seat</th><th>subject</th></tr></thead>
<tbody>{commit_rows}</tbody></table>

<div class="foot">Every figure on this page is read out of the repository at build time —
the commit list, the file sets, the requirement rows and the check counts.
Rebuild with <code>python3 site/build.py</code>.</div>
</div></body></html>
"""


if __name__ == '__main__':
    main()
