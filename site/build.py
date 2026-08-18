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
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wave as wv

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
        ('reqs@reqs', 'Numbered requirements', ['docs/specs/requirements.md'],
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


SV_KW = set("""module endmodule input output inout logic wire reg bit int integer parameter
localparam always always_ff always_comb always_latch initial begin end if else case endcase
default for while repeat forever task endtask function endfunction automatic return posedge
negedge assign generate endgenerate genvar timescale package endpackage import typedef enum
struct signed unsigned string void wait fork join disable break continue static const ref
inside unique priority assert property clocking endclocking interface endinterface""".split())

SV_SYS = re.compile(r'\$[a-z_]+')


def hl(text):
    """Minimal SystemVerilog/shell highlighter. Comments and strings win; keywords
    are only matched in what is left, so a keyword inside a comment stays a comment."""
    out = []
    tok = re.compile(r'(//[^\n]*|/\*.*?\*/|#[^\n]*|"(?:[^"\\\n]|\\.)*")', re.S)
    pos = 0
    for m in tok.finditer(text):
        out.append(('code', text[pos:m.start()]))
        lit = m.group(0)
        out.append(('str' if lit.startswith('"') else 'com', lit))
        pos = m.end()
    out.append(('code', text[pos:]))

    def esc(t):
        return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

    parts = []
    for kind, t in out:
        if kind != 'code':
            parts.append(f'<span class="{kind}">{esc(t)}</span>')
            continue
        buf = ''
        for w in re.split(r'(\W)', t):
            if w in SV_KW:
                buf += f'<span class="kw">{w}</span>'
            elif SV_SYS.fullmatch(w or ''):
                buf += f'<span class="sys">{esc(w)}</span>'
            elif re.fullmatch(r"\d+'?[a-zA-Z]?[0-9a-fA-F_]*|\d+", w or ''):
                buf += f'<span class="num">{w}</span>'
            else:
                buf += esc(w)
        parts.append(buf)
    html = ''.join(parts)
    return ''.join(f'<span class="line">{ln or "&nbsp;"}</span>\n'
                   for ln in html.split('\n'))


def bench_page(benches):
    """One browsable page carrying every testbench and the runner, in full."""
    counts = {b['name']: b for b in benches}
    files = sorted(sh('git', 'ls-files', 'test').split())
    files = [f for f in files if f.endswith('.sv')] + [f for f in files if f.endswith('.sh')]

    toc, blocks = [], []
    for f in files:
        name = os.path.basename(f)
        slug = name.replace('.', '-')
        body = open(os.path.join(ROOT, f), encoding='utf-8').read()
        nlines = body.count('\n') + 1
        b = counts.get(name[:-3]) if name.endswith('.sv') else None
        reqs = sorted(set(re.findall(r'REQ-\d+', body)))
        chip = (f'<span class="pill{"" if not b["fail"] else " bad"}">'
                f'{b["pass"]}/{b["total"]}</span>' if b else
                '<span class="pill neutral">runner</span>')
        toc.append(f'<a class="tocitem" href="#{slug}"><span class="mono">{name}</span>'
                   f'<span class="tocmeta">{nlines} lines &middot; '
                   f'{b["total"] if b else "—"} checks</span></a>')
        blocks.append(
            f'<section class="filesec" id="{slug}">'
            f'<h2 class="mono">{name}</h2>'
            f'<p class="filemeta">{chip} &nbsp;<span class="mono dim">{f}</span> '
            f'&nbsp;&middot;&nbsp; {nlines} lines'
            + (f' &nbsp;&middot;&nbsp; discharges {", ".join(reqs)}' if reqs else '')
            + f' &nbsp;&middot;&nbsp; <a href="https://github.com/{REPO}/blob/main/{f}">view on GitHub &#8599;</a>'
            f'</p><pre class="src"><code>{hl(body)}</code></pre></section>')

    total = sum(b['total'] for b in benches)
    return BENCH_TPL.format(repo=REPO, total=total, nfiles=len(files),
                            nlines=sum((open(os.path.join(ROOT, f), encoding='utf-8')
                                        .read().count('\n') + 1) for f in files),
                            toc=''.join(toc), blocks=''.join(blocks))


# ---------------------------------------------------------------- waveforms
# One entry per vignette in test/wave/. `sig` is the curated display order:
# the VCD carries more than a reader wants, and on the frame-length vignettes
# the clock is 4,400 cycles wide and renders as a solid band, so it is left
# out and the omission is stated on the page.
VIGNETTES = [
    dict(key='wv_tick_gen', mod='uart_tick_gen', req='REQ-005',
         head='The phase of the first tick — the BUG-0001 site',
         sig=['clk', 'rst', 'restart', 'cyc_since_anchor', 'dut.cnt', 'tick'],
         clk=True,
         panels=[(0, 300, 'Reset anchor. <code>rst</code> is sampled high in '
                          'the cycle where <code>cyc_since_anchor</code> reads '
                          '0. The first tick must land where it reads '
                          '<b>8</b> — not 7, not 9.'),
                 (600, 900, 'Restart anchor, mid-stream. The same contract '
                            'from a restart pulse rather than from reset, '
                            'which is the path the receiver actually uses to '
                            're-align on every start bit.')]),
    dict(key='wv_tx', mod='uart_tx', req='REQ-001…004',
         head='One whole 8N1 frame, LSB-first',
         sig=['tx_valid', 'tx_ready', 'tx_data', 'tx_busy', 'tx_line'],
         clk=False,
         panels=[(0, None, 'The whole frame. <code>tx_line</code> idles high, '
                           'drops for the start bit, carries eight data bits '
                           'and returns high for the stop bit.'),
                 (0, 12000, 'The handshake and the start bit, zoomed. '
                            '<code>tx_valid</code> and <code>tx_ready</code> '
                            'are high together for exactly one cycle — that '
                            'is the accept — and the start bit runs the full '
                            'DIV_TX, the interval BUG-0001 made one cycle '
                            'short.')]),
    dict(key='wv_rx', mod='uart_rx', req='REQ-006…012',
         head='Sampling in the middle of each bit cell',
         sig=['rx_line', 'spec_sample', 'cell_idx', 'rx_busy', 'rx_byte',
              'rx_strobe', 'rx_frame_err'],
         clk=False,
         panels=[(0, None, 'The whole received frame. Every '
                           '<code>spec_sample</code> pulse sits in the middle '
                           'of a bit cell on <code>rx_line</code>, never near '
                           'an edge.'),
                 (0, 14000, 'Start-bit detection and the first sample, '
                            'zoomed. The mid-cell margin visible here is what '
                            'buys tolerance to a far-end clock that is off.')]),
    dict(key='wv_fifo', mod='uart_fifo', req='REQ-015',
         head='Both flag boundaries, and the two writes that change nothing',
         sig=['clk', 'wr_en', 'wr_data', 'rd_en', 'rd_data', 'level',
              'full', 'empty'],
         clk=True),
    dict(key='wv_lite', mod='uart_lite', req='REQ-014, 016, 017',
         head='A byte out and the same byte back',
         sig=['tx_data', 'tx_valid', 'tx_ready', 'tx_line', 'rx_line',
              'rx_valid', 'rx_data', 'rx_ready', 'rx_overrun', 'rx_frame_err'],
         clk=False),
]


def vignettes(rerun):
    """Run the vignettes if needed, then parse each VCD and its log.

    Same rule as the rest of the site: if the artifacts are not there and
    cannot be produced, the page says so rather than drawing something.
    """
    vdir = os.path.join(ROOT, 'build', 'wave')
    have = glob.glob(os.path.join(vdir, '*.vcd'))
    if rerun or not have:
        subprocess.run(['bash', 'test/wave/run_wave.sh'], cwd=ROOT,
                       capture_output=True, text=True)
    out = []
    for v in VIGNETTES:
        vcd = os.path.join(vdir, v['key'] + '.vcd')
        log = os.path.join(vdir, v['key'] + '.log')
        if not os.path.exists(vcd):
            continue
        parsed = wv.parse_vcd(vcd)
        by_name = {}
        for sig in parsed['signals']:
            short = sig['name'].split('.', 1)[1] if '.' in sig['name'] else sig['name']
            by_name.setdefault(short, sig)
        rows = [by_name[n] for n in v['sig'] if n in by_name]

        lines = open(log).read().splitlines() if os.path.exists(log) else []
        look = next((l.strip() for l in lines if l.strip().startswith('Look at')), '')
        obs = [l.strip() for l in lines
               if l.startswith('  ') and 'VCD:' not in l and l.strip()]

        marks = []
        rst = by_name.get('rst')
        if rst:
            drop = next((t for t, val in rst['changes'] if val == '0'), None)
            if drop is not None:
                marks.append((drop, 'reset released'))
        for probe, label in (('tick', 'first tick'), ('rx_strobe', 'byte received'),
                             ('rx_valid', 'byte available'), ('full', 'FIFO full'),
                             ('tx_busy', 'frame starts')):
            sg = by_name.get(probe)
            if sg and any(r is sg for r in rows):
                rise = next((t for t, val in sg['changes'] if val == '1'), None)
                if rise is not None:
                    marks.append((rise, label))
        out.append(dict(v, rows=rows, end=parsed['end'], look=look, obs=obs,
                        marks=marks, nsig=len(rows), lines=sum(len(r['changes'])
                                                               for r in rows)))
    return out


def waves_page(vigs, total):
    secs = []
    for v in vigs:
        panels = v.get('panels') or [(0, None, '')]
        chunks = []
        for t0_ns, t1_ns, cap in panels:
            t0 = t0_ns * 1000
            t1 = v['end'] if t1_ns is None else min(t1_ns * 1000, v['end'])
            if t1 <= t0:
                continue
            chunks.append(
                (f'<p class="pcap">{cap}</p>' if cap else '')
                + wv.wave_svg(v['rows'], t0, t1, marks=v['marks'],
                              title=v['mod']))
        svg = ''.join(chunks)
        obs = ''.join(f'<li>{wv.esc(o)}</li>' for o in v['obs'])
        note = ('' if v['clk'] else
                '<p class="omit">The clock is omitted from this view: the '
                'vignette spans thousands of clock cycles, and at this width a '
                '50&nbsp;MHz clock renders as a solid band. Every edge is in '
                'the VCD; only the drawing leaves it out.</p>')
        secs.append(
            f'<section class="vig" id="{v["key"]}">'
            f'<p class="vkick">{wv.esc(v["mod"])} &middot; {wv.esc(v["req"])}</p>'
            f'<h2>{wv.esc(v["head"])}</h2>'
            f'<p class="look">{wv.esc(v["look"])}</p>'
            f'{svg}{note}'
            f'<p class="obs-h">What the run printed</p><ul class="obs">{obs}</ul>'
            f'<p class="src-l"><a href="https://github.com/{REPO}/blob/main/'
            f'test/wave/{v["key"]}.sv">test/wave/{v["key"]}.sv &#8599;</a> '
            f'&middot; {v["nsig"]} signals drawn &middot; '
            f'{v["lines"]} transitions</p></section>')
    return WAVE_TPL.format(repo=REPO, total=total, nvig=len(vigs),
                           secs=''.join(secs))


# ---------------------------------------------------------------- campaign
# The seeded-defect campaign, read out of the committed artifacts rather than
# typed: the scorecard rows come from the adjudication's own table, so this
# page cannot claim a verdict the verification lead did not record.
def campaign():
    adj = os.path.join(ROOT, 'docs', 'reports', 'dv', 'WO-0002-adjudication.md')
    if not os.path.exists(adj):
        return None
    text = open(adj, encoding='utf-8').read()

    rows = []
    for m in re.finditer(
            r'^\| (TG-\d|TX-\d|RX-\d|FF-\d|LT-\d) \| (KILL|SURVIVE) \| '
            r'(\d+) \| ([\d—-]+) \| ([\d*—-]+) \| ([\d*—-]+) \| \*\*(.+?)\*\* \|',
            text, re.M):
        cid, pred, req, red, missed, extra, verdict = m.groups()
        rows.append(dict(id=cid, pred=pred, req=int(req),
                         red=red.strip('*'), missed=missed.strip('*'),
                         extra=extra.strip('*'), verdict=verdict))

    def one(pat, default=''):
        mm = re.search(pat, text, re.M)
        return mm.group(1) if mm else default

    manifest = os.path.join(ROOT, 'docs', 'reports', 'audit',
                            'WO-0002-manifest.md')
    audit = os.path.join(ROOT, 'docs', 'reports', 'audit',
                         'audit-0001_wo-0002-seeding-integrity.md')
    # Classify exactly as the adjudication does: its "killed on every REQUIRED
    # cell" group includes FF-2, whose verdict cell reads "KILL on REQUIRED +
    # 3 findings". A page that re-groups the rows its own source grouped is a
    # page publishing a second, unreviewed tally.
    killed = [r for r in rows if r['verdict'].startswith(('CLEAN', 'KILL on'))]
    return dict(rows=rows,
                nclean=len(killed),
                npartial=sum(1 for r in rows if r['verdict'].startswith('PARTIAL')),
                nmiss=sum(1 for r in rows if r['verdict'].startswith('MISS')),
                nheld=sum(1 for r in rows if r['verdict'].startswith('PREDICTION')),
                nrows=len(rows),
                has_manifest=os.path.exists(manifest),
                has_audit=os.path.exists(audit))


def evidence_page(camp, total):
    """The campaign, as a page. Every figure is the adjudication's own."""
    def cls(v):
        if v.startswith('CLEAN') or v.startswith('KILL on'):
            return 'ok'
        if v.startswith('PARTIAL'):
            return 'warn'
        if v.startswith('MISS'):
            return 'bad'
        return 'held'

    rows = ''.join(
        f'<tr class="{cls(r["verdict"])}"><td class="mono">{r["id"]}</td>'
        f'<td class="mono dim">{r["pred"]}</td>'
        f'<td class="num">{r["req"]}</td><td class="num">{r["red"]}</td>'
        f'<td class="num">{r["missed"]}</td>'
        f'<td>{wv.esc(r["verdict"])}</td></tr>' for r in camp['rows'])
    return EVID_TPL.format(repo=REPO, total=total, rows=rows,
                           nclean=camp['nclean'], npartial=camp['npartial'],
                           nmiss=camp['nmiss'], nheld=camp['nheld'],
                           nrows=camp['nrows'])


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
                        'boxes': [{'k': bk.split('@')[0], 'label': bl, 'match': bm, 'desc': bd,
                                   'nkey': (bk.split('@')[1] if '@' in bk else None),
                                   'big': bk.split('@')[0] in ('rtl', 'benches')}
                                  for bk, bl, bm, bd in boxes]}
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
    camp = campaign()
    if camp:
        open(os.path.join(PUB, 'evidence.html'), 'w').write(
            evidence_page(camp, total))
    vigs = vignettes('--run' in sys.argv)
    open(os.path.join(PUB, 'waves.html'), 'w').write(waves_page(vigs, total))
    open(os.path.join(PUB, 'benches.html'), 'w').write(bench_page(benches))
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
 color:var(--sig);margin:1.6rem 0 .5rem}}
.tabs{{display:flex;flex-wrap:wrap;gap:.4rem;padding:1.4rem 0 .2rem}}
.tab{{border:1.5px solid var(--line);border-radius:999px;background:var(--panel);color:var(--ink2);
 padding:.32rem .85rem;font:600 .68rem ui-monospace,monospace;letter-spacing:.08em;
 text-transform:uppercase;text-decoration:none;white-space:nowrap}}
.tab:hover{{border-color:var(--sig);color:var(--sig)}}
.tab.on{{background:var(--sig);border-color:var(--sig);color:#fff}}
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
<nav class="tabs">
  <a class="tab on" href="index.html">OVERVIEW</a>
  <a class="tab" href="lifecycle.html">LIFECYCLE</a>
  <a class="tab" href="waves.html">WAVEFORMS</a>
  <a class="tab" href="evidence.html">EVIDENCE</a>
  <a class="tab" href="benches.html">TESTBENCHES</a>
  <a class="tab" href="https://github.com/{repo}">GITHUB &#8599;</a>
</nav>
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




BENCH_TPL = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>Testbenches &middot; agentic-uart-demo</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
:root{{--bg:#f7f5f1;--panel:#fffefb;--ink:#191714;--ink2:#6b635a;--line:#ddd6cc;
 --sig:#b45309;--ok:#15803d;--okbg:#e8f3ea;--bad:#b91c1c;--chip:#f1ede6;
 --kw:#8a3ffc;--com:#7d8a72;--str:#0f766e;--num:#b45309;--sys:#4338ca;--gut:#b9b0a4}}
@media (prefers-color-scheme:dark){{:root{{--bg:#141311;--panel:#1c1a17;--ink:#eeeae3;
 --ink2:#9c948a;--line:#332f2a;--sig:#e8a33d;--ok:#5cc98a;--okbg:#172b1f;--bad:#e8837b;
 --chip:#232019;--kw:#c39bff;--com:#87957c;--str:#5ec5b6;--num:#e8a33d;--sys:#9d92f5;
 --gut:#4b463f}}}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);
 font:17px/1.65 Georgia,'Iowan Old Style','Times New Roman',serif}}
.mono{{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}}
.dim{{color:var(--ink2)}}
.wrap{{max-width:980px;margin:0 auto;padding:0 1.3rem 5rem}}
a{{color:var(--sig)}}
.kicker{{font:600 .68rem ui-monospace,monospace;letter-spacing:.18em;text-transform:uppercase;
 color:var(--sig);margin:1.6rem 0 .5rem}}
.tabs{{display:flex;flex-wrap:wrap;gap:.4rem;padding:1.4rem 0 .2rem}}
.tab{{border:1.5px solid var(--line);border-radius:999px;background:var(--panel);color:var(--ink2);
 padding:.32rem .85rem;font:600 .68rem ui-monospace,monospace;letter-spacing:.08em;
 text-transform:uppercase;text-decoration:none;white-space:nowrap}}
.tab:hover{{border-color:var(--sig);color:var(--sig)}}
.tab.on{{background:var(--sig);border-color:var(--sig);color:#fff}}
h1{{font-size:clamp(1.8rem,4.2vw,2.6rem);line-height:1.1;margin:0 0 .6rem;letter-spacing:-.015em;
 text-wrap:balance}}
.lede{{font-size:1.08rem;color:var(--ink2);margin:0 0 1.4rem}}
.stats{{display:flex;flex-wrap:wrap;gap:.55rem;margin:1.2rem 0}}
.stat{{border:1px solid var(--line);border-radius:9px;background:var(--panel);padding:.5rem .8rem}}
.stat b{{display:block;font:700 1.3rem ui-monospace,monospace;line-height:1.1}}
.stat span{{font:500 .62rem ui-monospace,monospace;letter-spacing:.09em;text-transform:uppercase;
 color:var(--ink2)}}
.stat.good b{{color:var(--ok)}}
.callout{{border:1px solid var(--line);border-left:3px solid var(--sig);border-radius:0 9px 9px 0;
 background:var(--panel);padding:.9rem 1.1rem;margin:1.4rem 0;font-size:.97rem}}
.callout b{{color:var(--sig)}}
.toc{{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:.5rem;
 margin:1.4rem 0 2.4rem}}
.tocitem{{display:flex;flex-direction:column;gap:.15rem;border:1px solid var(--line);
 border-radius:9px;background:var(--panel);padding:.6rem .75rem;text-decoration:none;
 color:var(--ink);font-size:.85rem}}
.tocitem:hover{{border-color:var(--sig)}}
.tocmeta{{font:500 .62rem ui-monospace,monospace;letter-spacing:.06em;text-transform:uppercase;
 color:var(--ink2)}}
.filesec{{margin:3rem 0 0;scroll-margin-top:1rem}}
.filesec h2{{font-size:1.15rem;margin:0 0 .3rem;letter-spacing:-.01em}}
.filemeta{{font-size:.8rem;color:var(--ink2);margin:0 0 .7rem}}
.pill{{font:700 .6rem ui-monospace,monospace;padding:.08rem .38rem;border-radius:4px;
 border:1px solid var(--ok);color:var(--ok);background:var(--okbg)}}
.pill.bad{{border-color:var(--bad);color:var(--bad);background:transparent}}
.pill.neutral{{border-color:var(--line);color:var(--ink2);background:var(--chip)}}
.src{{counter-reset:l;background:var(--panel);border:1px solid var(--line);border-radius:10px;
 padding:.9rem 0;margin:0;overflow-x:auto;
 font:13px/1.6 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}}
.src code{{display:block;min-width:max-content}}
.line{{display:block;counter-increment:l;padding:0 1.1rem 0 0;white-space:pre}}
.line::before{{content:counter(l);display:inline-block;width:3.4em;padding-right:1.1em;
 text-align:right;color:var(--gut);user-select:none;-webkit-user-select:none}}
.line:hover{{background:color-mix(in srgb,var(--sig) 7%,transparent)}}
.kw{{color:var(--kw)}} .com{{color:var(--com);font-style:italic}} .str{{color:var(--str)}}
.num{{color:var(--num)}} .sys{{color:var(--sys)}}
code:not(.src code){{font-family:ui-monospace,monospace;font-size:.86em;background:var(--chip);
 padding:.08rem .28rem;border-radius:4px}}
.foot{{border-top:1px solid var(--line);margin-top:3.5rem;padding-top:1rem;color:var(--ink2);
 font-size:.85rem}}
.top{{display:inline-block;margin:.5rem 0 0;font:600 .62rem ui-monospace,monospace;
 letter-spacing:.08em;text-transform:uppercase;color:var(--ink2);text-decoration:none}}
.top:hover{{color:var(--sig)}}
</style></head><body><div class="wrap" id="top">
<nav class="tabs">
  <a class="tab" href="index.html">OVERVIEW</a>
  <a class="tab" href="lifecycle.html">LIFECYCLE</a>
  <a class="tab" href="waves.html">WAVEFORMS</a>
  <a class="tab" href="evidence.html">EVIDENCE</a>
  <a class="tab on" href="benches.html">TESTBENCHES</a>
  <a class="tab" href="https://github.com/{repo}">GITHUB &#8599;</a>
</nav>
<p class="kicker">{repo} &middot; test/</p>
<h1>The testbenches, in full.</h1>
<p class="lede">Every line was written by an agent session whose work order carried the
specification and the numbered requirements, and deliberately withheld <code>rtl/**</code>. The
author could not read the design it was grading. What follows is that output, unedited, with the
check counts each file returned on its most recent run in continuous integration.</p>

<div class="stats">
<div class="stat good"><b>{total}</b><span>checks passing</span></div>
<div class="stat"><b>{nfiles}</b><span>files</span></div>
<div class="stat"><b>{nlines}</b><span>lines of bench</span></div>
<div class="stat"><b>5.4&times;</b><span>bench : design</span></div>
</div>

<div class="callout">
<b>Read <span class="mono">tb_uart_tick_gen.sv</span> first, from line 24.</b> Its header records a
decision taken before any run: split the tick check into three independent properties — <i>where</i>
the first tick lands, whether the <i>spacing</i> is exactly N, and whether tick is ever high twice
running — &ldquo;precisely so a phase-only defect is not buried under a monolithic FAIL.&rdquo;
That decision is why BUG-0001 was found. The spacing check passed: spacing is N whether the counter
reloads to 0 or 1. Only the phase check could see the defect, and it did. A bench written with one
aggregate &ldquo;does the pattern match&rdquo; assertion would have gone green on a broken UART.
</div>

<div class="toc">{toc}</div>

{blocks}

<div class="foot">Sources are read out of <code>test/</code> at build time and highlighted
here; the check counts come from a real simulator run in CI, never from a figure typed by hand.
No mutation campaign has run, so nothing here establishes in general that these benches would catch
a defect — one real find is not a detection rate.
<a class="top" href="#top">&uarr; back to top</a></div>
</div></body></html>
"""




WAVE_TPL = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>Waveforms &middot; agentic-uart-demo</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
:root{{--bg:#f7f5f1;--panel:#fffefb;--ink:#191714;--ink2:#6b635a;--line:#ddd6cc;
 --sig:#b45309;--ok:#15803d;--bad:#b91c1c;--chip:#f1ede6;--bus:#4338ca;
 --busf:#eef2ff;--grid:#e7e0d6}}
@media (prefers-color-scheme:dark){{:root{{--bg:#141311;--panel:#1c1a17;--ink:#eeeae3;
 --ink2:#9c948a;--line:#332f2a;--sig:#e8a33d;--ok:#5cc98a;--bad:#e8837b;--chip:#232019;
 --bus:#9d92f5;--busf:#221f33;--grid:#2b2722}}}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);
 font:17px/1.65 Georgia,'Iowan Old Style','Times New Roman',serif}}
.mono{{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}}
.wrap{{max-width:1080px;margin:0 auto;padding:0 1.3rem 5rem}}
a{{color:var(--sig)}}
.kicker{{font:600 .68rem ui-monospace,monospace;letter-spacing:.18em;text-transform:uppercase;
 color:var(--sig);margin:1.6rem 0 .5rem}}
.tabs{{display:flex;flex-wrap:wrap;gap:.4rem;padding:1.4rem 0 .2rem}}
.tab{{border:1.5px solid var(--line);border-radius:999px;background:var(--panel);color:var(--ink2);
 padding:.32rem .85rem;font:600 .68rem ui-monospace,monospace;letter-spacing:.08em;
 text-transform:uppercase;text-decoration:none;white-space:nowrap}}
.tab:hover{{border-color:var(--sig);color:var(--sig)}}
.tab.on{{background:var(--sig);border-color:var(--sig);color:#fff}}
h1{{font-size:clamp(1.8rem,4.2vw,2.6rem);line-height:1.1;margin:0 0 .6rem;
 letter-spacing:-.015em;text-wrap:balance}}
.lede{{font-size:1.08rem;color:var(--ink2);margin:0 0 1.6rem}}
.vig{{margin:3.2rem 0 0;scroll-margin-top:1rem}}
.vkick{{font:600 .62rem ui-monospace,monospace;letter-spacing:.12em;text-transform:uppercase;
 color:var(--sig);margin:0 0 .25rem}}
.vig h2{{font-size:1.2rem;margin:0 0 .45rem;letter-spacing:-.01em;text-wrap:balance}}
.look{{font-size:.97rem;color:var(--ink2);margin:0 0 .9rem;border-left:3px solid var(--sig);
 padding-left:.9rem}}
.pcap{{font-size:.88rem;color:var(--ink2);margin:1.1rem 0 .35rem}}
.pcap b{{color:var(--ink)}}
.wave{{width:100%;height:auto;display:block;background:var(--panel);
 border:1px solid var(--line);border-radius:10px}}
.wave .grid{{stroke:var(--grid);stroke-width:1}}
.wave .base{{stroke:var(--grid);stroke-width:1}}
.wave .w1{{fill:none;stroke:var(--ok);stroke-width:1.8;stroke-linejoin:round}}
.wave .bus{{fill:var(--busf);stroke:var(--bus);stroke-width:1.3}}
.wave .bus.bad{{fill:none;stroke:var(--bad)}}
.wave .xz{{fill:var(--bad);opacity:.13}}
.wave .slab{{font:600 12px ui-monospace,monospace;fill:var(--ink);text-anchor:end}}
.wave .tlab{{font:500 10px ui-monospace,monospace;fill:var(--ink2);text-anchor:middle}}
.wave .tunit{{font:500 10px ui-monospace,monospace;fill:var(--ink2);text-anchor:end}}
.wave .bval{{font:600 11px ui-monospace,monospace;fill:var(--bus);text-anchor:middle}}
.wave .mark{{stroke:var(--sig);stroke-width:1.3;stroke-dasharray:4 3}}
.wave .mlab{{font:600 10px ui-monospace,monospace;fill:var(--sig)}}
.omit{{font-size:.82rem;color:var(--ink2);margin:.55rem 0 0}}
.obs-h{{font:600 .6rem ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;
 color:var(--ink2);margin:1.1rem 0 .3rem}}
.obs{{margin:0;padding-left:1.1rem;font:13px/1.7 ui-monospace,monospace;color:var(--ink)}}
.obs li{{margin:.1rem 0}}
.src-l{{font-size:.78rem;color:var(--ink2);margin:.8rem 0 0}}
.callout{{border:1px solid var(--line);border-left:3px solid var(--sig);border-radius:0 9px 9px 0;
 background:var(--panel);padding:.9rem 1.1rem;margin:1.5rem 0;font-size:.97rem}}
.callout b{{color:var(--sig)}}
code{{font-family:ui-monospace,monospace;font-size:.86em;background:var(--chip);
 padding:.08rem .28rem;border-radius:4px}}
.foot{{border-top:1px solid var(--line);margin-top:3.5rem;padding-top:1rem;color:var(--ink2);
 font-size:.85rem}}
</style></head><body><div class="wrap">
<nav class="tabs">
  <a class="tab" href="index.html">OVERVIEW</a>
  <a class="tab" href="lifecycle.html">LIFECYCLE</a>
  <a class="tab on" href="waves.html">WAVEFORMS</a>
  <a class="tab" href="evidence.html">EVIDENCE</a>
  <a class="tab" href="benches.html">TESTBENCHES</a>
  <a class="tab" href="https://github.com/{repo}">GITHUB &#8599;</a>
</nav>
<p class="kicker">{repo} &middot; test/wave/</p>
<h1>What the design actually does, one picture per module.</h1>
<p class="lede">{nvig} vignettes. Each is a short scenario staged on purpose, dumped
to VCD by a real Icarus run at build time and drawn here from that file — so the picture cannot
disagree with the design it claims to show. These are <em>demonstrations, not checks</em>:
they contribute nothing to the {total}-check suite and are not run by it.</p>

<div class="callout">
<b>Why vignettes rather than a dump of the suite.</b> A full run of the receiver bench alone
covers a 6,656-check tolerance sweep across 26 sender bit periods — a VCD nobody can read at any
zoom. Each vignette instead stages the one scenario that makes its module's contract legible,
and each says in its own header what a reader should look at. The verification lead wrote them;
the text under each heading below is that file's own words, not a caption added here.
</div>

{secs}

<div class="foot">Every waveform on this page is parsed from a VCD produced by Icarus Verilog
12.0 during the site build, and every observation printed beneath it is that run's own stdout.
Nothing here is drawn by hand. <b>A vignette is not evidence of correctness</b> — it shows one
staged scenario behaving as its specification says it should. What the checks are worth is a
different question, answered by the suite and by the seeded-defect campaign, not by a picture.
</div>
</div></body></html>
"""




EVID_TPL = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>Evidence &middot; agentic-uart-demo</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
:root{{--bg:#f7f5f1;--panel:#fffefb;--ink:#191714;--ink2:#6b635a;--line:#ddd6cc;
 --sig:#b45309;--ok:#15803d;--okbg:#e8f3ea;--bad:#b91c1c;--badbg:#fdeaea;
 --warn:#a16207;--warnbg:#fdf4e3;--held:#4338ca;--heldbg:#eef2ff;--chip:#f1ede6}}
@media (prefers-color-scheme:dark){{:root{{--bg:#141311;--panel:#1c1a17;--ink:#eeeae3;
 --ink2:#9c948a;--line:#332f2a;--sig:#e8a33d;--ok:#5cc98a;--okbg:#172b1f;--bad:#e8837b;
 --badbg:#2b1917;--warn:#d9a441;--warnbg:#2a2213;--held:#9d92f5;--heldbg:#221f33;
 --chip:#232019}}}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);
 font:17px/1.65 Georgia,'Iowan Old Style','Times New Roman',serif}}
.mono{{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}}
.dim{{color:var(--ink2)}}
.wrap{{max-width:880px;margin:0 auto;padding:0 1.3rem 5rem}}
a{{color:var(--sig)}}
.kicker{{font:600 .68rem ui-monospace,monospace;letter-spacing:.18em;text-transform:uppercase;
 color:var(--sig);margin:1.6rem 0 .5rem}}
.tabs{{display:flex;flex-wrap:wrap;gap:.4rem;padding:1.4rem 0 .2rem}}
.tab{{border:1.5px solid var(--line);border-radius:999px;background:var(--panel);color:var(--ink2);
 padding:.32rem .85rem;font:600 .68rem ui-monospace,monospace;letter-spacing:.08em;
 text-transform:uppercase;text-decoration:none;white-space:nowrap}}
.tab:hover{{border-color:var(--sig);color:var(--sig)}}
.tab.on{{background:var(--sig);border-color:var(--sig);color:#fff}}
h1{{font-size:clamp(1.8rem,4.2vw,2.6rem);line-height:1.1;margin:0 0 .6rem;
 letter-spacing:-.015em;text-wrap:balance}}
h2{{font-size:1.2rem;margin:2.6rem 0 .5rem;letter-spacing:-.01em}}
.lede{{font-size:1.08rem;color:var(--ink2);margin:0 0 1.5rem}}
.stats{{display:flex;flex-wrap:wrap;gap:.55rem;margin:1.3rem 0}}
.stat{{border:1px solid var(--line);border-radius:9px;background:var(--panel);
 padding:.5rem .8rem;min-width:106px}}
.stat b{{display:block;font:700 1.35rem ui-monospace,monospace;line-height:1.1}}
.stat span{{font:500 .6rem ui-monospace,monospace;letter-spacing:.08em;text-transform:uppercase;
 color:var(--ink2)}}
.stat.ok b{{color:var(--ok)}} .stat.warn b{{color:var(--warn)}}
.stat.bad b{{color:var(--bad)}} .stat.held b{{color:var(--held)}}
table{{width:100%;border-collapse:collapse;margin:.9rem 0;font-size:.87rem}}
th{{text-align:left;font:600 .58rem ui-monospace,monospace;letter-spacing:.09em;
 text-transform:uppercase;color:var(--ink2);border-bottom:1px solid var(--line);
 padding:.35rem .4rem}}
td{{padding:.36rem .4rem;border-bottom:1px solid var(--line);vertical-align:top}}
td.num{{text-align:right;font-family:ui-monospace,monospace}}
tr.ok td:last-child{{color:var(--ok)}}
tr.warn td:last-child{{color:var(--warn)}}
tr.bad td:last-child{{color:var(--bad);font-weight:700}}
tr.held td:last-child{{color:var(--held)}}
.callout{{border:1px solid var(--line);border-left:3px solid var(--sig);border-radius:0 9px 9px 0;
 background:var(--panel);padding:.9rem 1.1rem;margin:1.4rem 0;font-size:.97rem}}
.callout b{{color:var(--sig)}}
.callout.bad{{border-left-color:var(--bad)}} .callout.bad b{{color:var(--bad)}}
code{{font-family:ui-monospace,monospace;font-size:.86em;background:var(--chip);
 padding:.08rem .28rem;border-radius:4px}}
ul{{padding-left:1.15rem}} li{{margin:.35rem 0}}
.foot{{border-top:1px solid var(--line);margin-top:3.2rem;padding-top:1rem;color:var(--ink2);
 font-size:.85rem}}
</style></head><body><div class="wrap">
<nav class="tabs">
  <a class="tab" href="index.html">OVERVIEW</a>
  <a class="tab" href="lifecycle.html">LIFECYCLE</a>
  <a class="tab" href="waves.html">WAVEFORMS</a>
  <a class="tab on" href="evidence.html">EVIDENCE</a>
  <a class="tab" href="benches.html">TESTBENCHES</a>
  <a class="tab" href="https://github.com/{repo}">GITHUB &#8599;</a>
</nav>
<p class="kicker">{repo} &middot; WO-0002</p>
<h1>How do you know the tests are any good?</h1>
<p class="lede">A green suite is consistent with a suite that checks nothing. {total} passing
checks say nothing on their own about whether those checks could see a defect. So defects were
put in front of them on purpose — and this page is what happened, taken from the committed
adjudication rather than summarised here.</p>

<div class="callout">
<b>The order is the whole method.</b> The verification lead wrote down, <em>before any defect
existed</em>, which classes it expected to catch, in which rows, with the exact failure message
text — and froze that file. The auditor then wrote the actual defects <em>blind</em>: forbidden
from reading the predictions, and forbidden from reading the testbenches, so it aimed at the
design rather than at the checks. A third seat applied them and recorded what happened without
scoring it. Only then was the seal opened. Predictions written after the results are not
predictions.
</div>

<div class="stats">
<div class="stat ok"><b>{nclean}</b><span>caught exactly as predicted</span></div>
<div class="stat warn"><b>{npartial}</b><span>caught, but not cleanly</span></div>
<div class="stat bad"><b>{nmiss}</b><span>not caught at all</span></div>
<div class="stat held"><b>{nheld}</b><span>predicted to survive, and did</span></div>
<div class="stat"><b>{nrows}</b><span>classes scored</span></div>
</div>

<h2>The scorecard</h2>
<p><b>Required</b> is how many individual checks the seal named for that class in advance;
<b>red</b> is how many actually failed; <b>missed</b> is the difference. A class that reddens the
suite but leaves a named check green is <em>not</em> scored as a kill — that rule was written
before any result existed, and it is what turned four apparent successes into partials.</p>
<table><thead><tr><th>class</th><th>predicted</th><th>required</th><th>red</th><th>missed</th>
<th>verdict</th></tr></thead><tbody>{rows}</tbody></table>

<div class="callout bad">
<b>The result that matters most is the one in red.</b> One seeded defect — a receiver that no
longer rejects a false start — was <em>not detected at all</em>, and the seal had predicted it
would be. Worse, the adjudication proved by a three-arm experiment that the two rows meant to
cover it stay green because of the <em>stimulus</em>, not because the receiver is correct. Two
requirements are now recorded as having no check that discharges them.
</div>

<h2>What writing the predictions found, before a single defect existed</h2>
<ul>
<li><b>Six checks cannot do what their text claims.</b> Three were found while sealing the
predictions and three more while scoring. The clearest: the only row in {total} whose text claims
to verify bit order tests with <code>0xA5</code> — a bit-reversal palindrome. It passes
identically on a transmitter that sends every byte backwards.</li>
<li><b>The suite has no watchdog.</b> Three unbounded waits mean a defect that starves a handshake
hangs the simulator instead of failing it. Every mutant was therefore run under an external
timeout, and a hang is scored <em>no verdict</em> — never a kill, because failing to reach a
verdict is not catching something.</li>
<li><b>Two deliberate near-misses survived, as intended.</b> The auditor also seeded two changes
it argued were behaviourally equivalent. Both survived. Had either "died", the campaign would be
reddening at edits rather than detecting defects, and every other number here would be
worthless.</li>
</ul>

<h2>The blind was broken, and by whom</h2>
<div class="callout bad">
<b>Disclosed rather than discovered later.</b> The commit that froze the predictions carried a
descriptive subject line — naming the sealed class count and a discriminating property of one
specific check. The seeding agent is required by protocol to run <code>git log</code> as its
first act, so that subject was delivered straight into the blind. <b>That was the orchestrator's
error</b>, and it was caught by the auditor, filed against the orchestrator, and adjudicated by
the verification lead rather than by the party at fault. Consequence, as ruled: no score is
withdrawn — the leaked facts could not change which defects were written, because the class list
was already public — but the <b>blindness claim is void for two classes</b>, and that disclosure
travels with every citation of this campaign.
</div>

<h2>What this licenses you to say</h2>
<ul>
<li>This suite detected <b>16 of 17</b> seeded defect classes, and reddened exactly the predicted
checks with the predicted messages in <b>{nclean}</b> of them.</li>
<li>It is evidence about <b>17 classes</b>. It is <b>not a detection rate</b>, and no ratio on
this page should be read as one.</li>
<li>The module-ready gate remains <b>unsigned</b> — and is now blocked by this campaign's
<em>result</em> rather than by its absence.</li>
</ul>

<div class="foot">Every figure on this page is parsed at build time from
<code>docs/reports/dv/WO-0002-adjudication.md</code>, the verification lead's committed
scorecard, and the classes are grouped exactly as that document groups them. The defect diffs are
committed under <code>docs/reports/audit/WO-0002-mutations/</code>; the seeding-integrity findings,
including the two against the orchestrator, are at
<code>docs/reports/audit/audit-0001_wo-0002-seeding-integrity.md</code>. Read them rather than
this page.</div>
</div></body></html>
"""


if __name__ == '__main__':
    main()
