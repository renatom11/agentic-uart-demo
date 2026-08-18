#!/usr/bin/env python3
"""VCD parsing and waveform rendering for the site.

The waveforms published on the site are drawn from VCD files produced by a
real Icarus run at build time — the same rule the rest of the site obeys:
nothing on the page is typed by hand, so the picture cannot drift from the
design it claims to show.

Two entry points:

    parse_vcd(path) -> {'timescale': str, 'end': int, 'signals': [Signal]}
    wave_svg(sig_rows, t0, t1, ...) -> str   # standalone <svg> markup

A Signal is {'name', 'width', 'changes': [(time, value_str)]}, where
value_str is a binary string for vectors ('10100011'), '0'/'1' for scalars,
and may be 'x'/'z' or contain them.
"""
import re


# ---------------------------------------------------------------- parsing

def parse_vcd(path):
    """Parse a VCD into per-signal change lists.

    Handles the constructs Icarus emits: nested $scope, aliased identifiers
    (one id shared by several hierarchical names), vectors with bit ranges,
    $dumpall/$dumpvars blocks, $comment, and real values (kept as strings).
    """
    text = open(path, encoding='utf-8', errors='replace').read()

    head, _, body = text.partition('$enddefinitions')
    timescale = '1ns'
    m = re.search(r'\$timescale\s+(.*?)\s*\$end', head, re.S)
    if m:
        timescale = ' '.join(m.group(1).split())

    # $var <type> <width> <id> <name> [range] $end, tracked through scopes
    by_id, scope = {}, []
    for tok in re.finditer(r'\$(scope|upscope|var)\b(.*?)\$end', head, re.S):
        kind, rest = tok.group(1), tok.group(2).split()
        if kind == 'scope':
            scope.append(rest[1] if len(rest) > 1 else '?')
        elif kind == 'upscope':
            if scope:
                scope.pop()
        else:
            if len(rest) < 4:
                continue
            vtype, width, vid, name = rest[0], rest[1], rest[2], rest[3]
            if vtype == 'parameter':          # constants, not waveforms
                continue
            full = '.'.join(scope + [name])
            e = by_id.setdefault(vid, {'names': [], 'width': int(width),
                                       'changes': []})
            e['names'].append(full)

    # value changes
    t = 0
    end_t = 0
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith('$'):
            continue
        if line[0] == '#':
            try:
                t = int(line[1:])
            except ValueError:
                continue
            end_t = max(end_t, t)
            continue
        if line[0] in 'bB':
            val, _, vid = line[1:].partition(' ')
            vid = vid.strip()
        elif line[0] in 'rR':
            val, _, vid = line[1:].partition(' ')
            vid = vid.strip()
        else:
            val, vid = line[0], line[1:].strip()
        e = by_id.get(vid)
        if e is None or not vid:
            continue
        if e['changes'] and e['changes'][-1][0] == t:
            e['changes'][-1] = (t, val)     # last write at a timestamp wins
        else:
            e['changes'].append((t, val))

    signals = []
    for vid, e in by_id.items():
        # Prefer the shallowest name: the vignette's own view of the signal.
        name = min(e['names'], key=lambda n: (n.count('.'), len(n)))
        signals.append({'id': vid, 'name': name, 'aliases': e['names'],
                        'width': e['width'], 'changes': e['changes']})
    return {'timescale': timescale, 'end': end_t, 'signals': signals}


def value_at(sig, t):
    """The signal's value at time t, or None before its first change."""
    v = None
    for ct, cv in sig['changes']:
        if ct > t:
            break
        v = cv
    return v


def fmt(val, width):
    """Display form: scalars as-is, vectors as hex unless they carry x/z."""
    if val is None:
        return '?'
    if width == 1:
        return val
    if any(c in 'xzXZ' for c in val):
        return val.lower()
    try:
        return format(int(val, 2), 'X').rjust((width + 3) // 4, '0')
    except ValueError:
        return val


# --------------------------------------------------------------- drawing

W, GUT, ROW, PAD = 1180, 168, 30, 9   # canvas, label gutter, row pitch, inset


def wave_svg(signals, t0, t1, marks=(), unit='ns', divisor=1000, title=''):
    """Render signals over [t0, t1] as standalone SVG markup.

    marks: iterable of (time, label) — annotations drawn as dashed verticals.
    divisor: VCD ticks per display unit (Icarus emits ps; 1000 -> ns).
    """
    span = max(1, t1 - t0)
    h = len(signals) * ROW + 56
    x = lambda t: GUT + (t - t0) / span * (W - GUT - 14)

    out = [f'<svg class="wave" viewBox="0 0 {W} {h}" '
           f'preserveAspectRatio="xMinYMin meet" role="img" '
           f'aria-label="waveform: {esc(title)}">']

    # time grid + axis
    nticks = 10
    for i in range(nticks + 1):
        t = t0 + span * i / nticks
        gx = round(x(t), 1)
        out.append(f'<line class="grid" x1="{gx}" y1="18" x2="{gx}" y2="{h - 26}"/>')
        out.append(f'<text class="tlab" x="{gx}" y="12">'
                   f'{t / divisor:.0f}</text>')
    out.append(f'<text class="tunit" x="{GUT - 8}" y="12">{unit}</text>')

    for row, sig in enumerate(signals):
        y = 26 + row * ROW
        mid, top, bot = y + ROW / 2, y + 5, y + ROW - 10
        out.append(f'<text class="slab" x="{GUT - 10}" y="{mid + 4}">'
                   f'{esc(sig["name"].split(".")[-1])}</text>')
        out.append(f'<line class="base" x1="{GUT}" y1="{bot}" '
                   f'x2="{W - 14}" y2="{bot}"/>')

        # change points clipped to the window, with the value carried in
        pts = [(t0, value_at(sig, t0))]
        pts += [(ct, cv) for ct, cv in sig['changes'] if t0 < ct <= t1]
        pts.append((t1, pts[-1][1]))

        if sig['width'] == 1:
            d, prev = [], None
            for i, (ct, cv) in enumerate(pts[:-1]):
                nt = pts[i + 1][0]
                lvl = bot if cv in ('0', '') else top if cv == '1' else (top + bot) / 2
                x1, x2 = x(ct), x(nt)
                bad = cv not in ('0', '1')
                if prev is not None and abs(prev - lvl) > 0.5:
                    d.append(f'L{x1:.1f},{lvl:.1f}')
                else:
                    d.append(f'{"M" if prev is None else "L"}{x1:.1f},{lvl:.1f}')
                d.append(f'L{x2:.1f},{lvl:.1f}')
                if bad:
                    out.append(f'<rect class="xz" x="{x1:.1f}" y="{top:.1f}" '
                               f'width="{max(0.6, x2 - x1):.1f}" '
                               f'height="{bot - top:.1f}"/>')
                prev = lvl
            out.append(f'<path class="w1" d="{"".join(d)}"/>')
        else:
            for i, (ct, cv) in enumerate(pts[:-1]):
                nt = pts[i + 1][0]
                x1, x2 = x(ct), x(nt)
                if x2 - x1 < 0.5:
                    continue
                k = min(4.0, (x2 - x1) / 2, max(0.0, (x2 - x1) / 2 - 0.5))
                bad = cv is not None and any(c in 'xzXZ' for c in cv)
                cls = 'bus bad' if bad else 'bus'
                out.append(
                    f'<path class="{cls}" d="M{x1:.1f},{mid:.1f} '
                    f'L{x1 + k:.1f},{top:.1f} L{x2 - k:.1f},{top:.1f} '
                    f'L{x2:.1f},{mid:.1f} L{x2 - k:.1f},{bot:.1f} '
                    f'L{x1 + k:.1f},{bot:.1f} Z"/>')
                label = fmt(cv, sig['width'])
                if x2 - x1 > 26:
                    out.append(f'<text class="bval" x="{(x1 + x2) / 2:.1f}" '
                               f'y="{mid + 4:.1f}">{esc(label)}</text>')

    # Labels are staggered onto two rows when they would otherwise overlap:
    # a legend that collides is a legend that has to be guessed at.
    vis = sorted(((t, l) for t, l in marks if t0 <= t <= t1), key=lambda m: m[0])
    last_x, row = -1e9, 0
    for t, label in vis:
        mx = round(x(t), 1)
        row = (row + 1) % 2 if (mx - last_x) < 130 else 0
        last_x = mx
        ly = h - 26 - (0 if row == 0 else 13)
        out.append(f'<line class="mark" x1="{mx}" y1="18" x2="{mx}" '
                   f'y2="{h - 30}"/>')
        anchor = 'end' if mx > W * 0.7 else 'start'
        dx = -6 if anchor == 'end' else 6
        out.append(f'<text class="mlab" x="{mx + dx}" y="{ly + 24}" '
                   f'text-anchor="{anchor}">{esc(label)}</text>')

    out.append('</svg>')
    return ''.join(out)


def esc(t):
    return (str(t).replace('&', '&amp;').replace('<', '&lt;')
            .replace('>', '&gt;').replace('"', '&quot;'))
