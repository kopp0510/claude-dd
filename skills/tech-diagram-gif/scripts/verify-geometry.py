#!/usr/bin/env python3
"""驗證 SVG 是否符合 Taste Gate「版面幾何」組 — 純標準庫，無 pip 依賴。

用法：python3 verify-geometry.py <diagram.svg> [--cycle 8.0]

這組檢查項的判定手段是「讀座標算術」，不是看截圖 —— 6–10px 的間隙、
1.35 的繞路比、菱形斜邊上的文字溢出，縮到瀏覽器視窗後肉眼都分辨不出來。

辨識元素優先用 data-role 標記（`node` / `container` / `edge`），
沒有標記時退化用 Style 8 的畫法猜（rx=6 實心 rect / polygon 為節點、
rx=8 fill=none 為容器、id=e* 的 path 為連線）並印出警告 —— 猜錯會靜默漏檢。

無 python3 的環境退化為人工計算，不阻擋出圖。
"""
import re, sys, itertools
from pathlib import Path

LIMITS = dict(nodes=9, edges=12, containers=4, notes=2,
              bends=2, detour=1.35, node_gap=80, gutter=20, port_gap=12)
# 文字寬度估算：CJK/全形 ≈ 1.0em，其餘 ≈ 0.55em。只用來抓明顯溢出，
# 精確值要在渲染時用 getBBox() 複驗（見 SKILL.md 第 4 步）。
def text_width(s, fs):
    return sum(fs if ord(c) > 0x2E80 else fs * 0.55 for c in s)

def poly_span(pts, y):
    """多邊形在高度 y 這條水平線上的可用 x 區間（掃描線求交）。"""
    xs = []
    for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]):
        if y1 == y2:
            if abs(y - y1) < 1e-9:
                xs += [x1, x2]
            continue
        if min(y1, y2) <= y <= max(y1, y2):
            xs.append(x1 + (x2 - x1) * (y - y1) / (y2 - y1))
    return (min(xs), max(xs)) if xs else None


def parse(svg):
    """回傳 (nodes, containers, edges, texts, tagged)。座標一律 (x1,y1,x2,y2)。"""
    tagged = 'data-role=' in svg
    svg = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)   # marker 的 polygon 不是節點
    nodes, conts, edges, texts = [], [], {}, []

    for m in re.finditer(r'<rect\b[^>]*>', svg):
        t = m.group(0)
        role = re.search(r'data-role="(\w+)"', t)
        g = re.search(r'x="([\d.]+)"\s+y="([\d.]+)"\s+width="([\d.]+)"\s+height="([\d.]+)"', t)
        if not g:
            continue
        x, y, w, h = map(float, g.groups())
        box = (x, y, x + w, y + h)
        if role:
            r = role.group(1)
            if r == 'node':
                nodes.append(box + (None,))
            elif r == 'container':
                conts.append(box)
        elif not tagged:                       # 退化猜法
            if 'rx="6"' in t and 'fill="none"' not in t:
                nodes.append(box + (None,))
            elif 'rx="8"' in t and 'fill="none"' in t:
                conts.append(box)

    for m in re.finditer(r'<polygon\b[^>]*points="([\d,.\s]+)"[^>]*>', svg):
        t = m.group(0)
        if 'marker' in t or ('data-role=' in t and 'node' not in t):
            continue
        if tagged and 'data-role="node"' not in t:
            continue
        if not tagged and 'fill="#' not in t:   # 箭頭 marker 的 polygon 沒有座標框
            continue
        # points 可能寫成 "x,y x,y" 或 "x y x y"，一律用數字對抓
        pts = [(float(a), float(b)) for a, b in
               re.findall(r'(-?[\d.]+)[,\s]+(-?[\d.]+)', m.group(1))]
        if len(pts) < 3:
            continue
        xs, ys = [q[0] for q in pts], [q[1] for q in pts]
        nodes.append((min(xs), min(ys), max(xs), max(ys), tuple(pts)))

    for m in re.finditer(r'<path\b[^>]*>', svg):
        t = m.group(0)
        if 'data-role=' in t and 'edge' not in t:
            continue
        eid = re.search(r'id="(\w+)"', t)
        if not eid or (not tagged and not re.match(r'^e\d+$', eid.group(1))):
            continue
        d = re.search(r'\sd="([^"]+)"', t)
        if not d or 'C' in d.group(1) or 'Q' in d.group(1):
            continue                            # 曲線不做正交幾何判定
        pts = [(float(a), float(b)) for a, b in re.findall(r'(-?[\d.]+),(-?[\d.]+)', d.group(1))]
        if len(pts) >= 2:
            edges[eid.group(1)] = pts

    for m in re.finditer(r'<text\b([^>]*)>([^<]*)</text>', svg):
        attrs, body = m.groups()
        g = re.search(r'x="([\d.]+)"\s+y="([\d.]+)"', attrs)
        if not g or not body.strip():
            continue
        fs = re.search(r'font-size="([\d.]+)"', attrs)
        cls = re.search(r'class="(\w+)"', attrs)
        size = float(fs.group(1)) if fs else {'nm': 20, 'sm': 15, 'al': 15,
                                              'ttl': 31, 'lbl': 16, 'sub': 16}.get(
                                                  cls.group(1) if cls else '', 15)
        anchor = 'middle' if 'text-anchor="middle"' in attrs else (
                 'end' if 'text-anchor="end"' in attrs else 'start')
        texts.append((float(g.group(1)), float(g.group(2)), body, size, anchor))

    return nodes, conts, edges, texts, tagged

def run(path, cycle):
    svg = Path(path).read_text(encoding='utf-8')
    nodes, conts, edges, texts, tagged = parse(svg)
    fails, warns = [], []
    say = lambda ok, msg: print(f'  {"✅" if ok else "❌"} {msg}')

    print(f'== {path} ==')
    print(f'辨識方式：{"data-role 標記" if tagged else "⚠️  無 data-role，用畫法猜（可能漏檢）"}')
    if not tagged:
        warns.append('SVG 未標 data-role，本次為啟發式辨識')
    print(f'元素：節點 {len(nodes)} · 連線 {len(edges)} · 容器 {len(conts)} · 文字 {len(texts)}\n')

    print('[數量預算]')
    for name, got, lim in (('節點', len(nodes), LIMITS['nodes']),
                           ('連線', len(edges), LIMITS['edges']),
                           ('容器/分組', len(conts), LIMITS['containers'])):
        say(got <= lim, f'{name} {got}（上限 {lim}）')
        if got > lim:
            fails.append(f'{name} {got} > {lim}')

    segs = lambda p: list(zip(p, p[1:]))
    man = lambda p: abs(p[-1][0] - p[0][0]) + abs(p[-1][1] - p[0][1])
    plen = lambda p: sum(abs(b[0] - a[0]) + abs(b[1] - a[1]) for a, b in segs(p))

    print('[折數 / 繞路比]')
    for k, p in sorted(edges.items()):
        b, r = len(p) - 2, (plen(p) / man(p) if man(p) else 1.0)
        ok = b <= LIMITS['bends'] and r <= LIMITS['detour']
        say(ok, f'{k}: {b} 折（上限 {LIMITS["bends"]}）· 繞路比 {r:.2f}（上限 {LIMITS["detour"]}）')
        if b > LIMITS['bends']:
            fails.append(f'{k} {b} 折')
        if r > LIMITS['detour']:
            fails.append(f'{k} 繞路比 {r:.2f}')

    def crosses(s1, s2):
        (x1, y1), (x2, y2) = s1
        (x3, y3), (x4, y4) = s2
        if (y1 == y2) == (y3 == y4):
            return False
        if y3 == y4:
            (x1, y1), (x2, y2), (x3, y3), (x4, y4) = (x3, y3), (x4, y4), (x1, y1), (x2, y2)
        return min(x1, x2) < x3 < max(x1, x2) and min(y3, y4) < y1 < max(y3, y4)
    allsegs = [(k, s) for k, p in edges.items() for s in segs(p)]
    cross = [(a, b) for i, (a, sa) in enumerate(allsegs)
             for b, sb in allsegs[i + 1:] if a != b and crosses(sa, sb)]
    print('[交叉]')
    say(not cross, f'{len(cross)} 處（上限 0）' + (f' → {cross}' if cross else ''))
    if cross:
        fails.append(f'交叉 {cross}')

    def hits(seg, n):
        (x1, y1), (x2, y2) = seg
        a, b, c, d = n[:4]
        if y1 == y2:
            return b < y1 < d and max(min(x1, x2), a) < min(max(x1, x2), c)
        return a < x1 < c and max(min(y1, y2), b) < min(max(y1, y2), d)
    through = [(k, n) for k, p in edges.items() for s in segs(p) for n in nodes
               if hits(s, n) and not any(n[0] <= e[0] <= n[2] and n[1] <= e[1] <= n[3]
                                         for e in (p[0], p[-1]))]
    print('[穿過非端點節點]')
    say(not through, f'{len(through)} 處' + (f' → {through}' if through else ''))
    if through:
        fails.append(f'穿過節點 {through}')

    def gap(a, b):
        dx = max(a[0] - b[2], b[0] - a[2], 0)
        dy = max(a[1] - b[3], b[1] - a[3], 0)
        return (dx * dx + dy * dy) ** 0.5 if dx and dy else max(dx, dy)
    print('[節點間距]')
    if len(nodes) > 1:
        mn = min(gap(a, b) for a, b in itertools.combinations(nodes, 2))
        say(mn >= LIMITS['node_gap'], f'最小 {mn:.0f}px（下限 {LIMITS["node_gap"]}）')
        if mn < LIMITS['node_gap']:
            fails.append(f'節點間距 {mn:.0f}px')

    print('[容器 gutter]')
    orphan = [n for n in nodes if not any(n[0] >= c[0] and n[1] >= c[1]
                                          and n[2] <= c[2] and n[3] <= c[3] for c in conts)]
    for i, c in enumerate(conts):
        inside = [n for n in nodes if n[0] >= c[0] and n[1] >= c[1] and n[2] <= c[2] and n[3] <= c[3]]
        if not inside:
            continue
        g = min(min(n[0] - c[0], n[1] - c[1], c[2] - n[2], c[3] - n[3]) for n in inside)
        say(g >= LIMITS['gutter'], f'容器{i} 含 {len(inside)} 節點，最小 {g:.0f}px（下限 {LIMITS["gutter"]}）')
        if g < LIMITS['gutter']:
            fails.append(f'容器{i} gutter {g:.0f}px')
    if conts:
        say(not orphan, f'未被容器包住的節點 {len(orphan)} 個' + (f' → {orphan}' if orphan else ''))
        if orphan:
            warns.append(f'{len(orphan)} 個節點在所有容器外')

    print('[同邊多 port 間距]')
    ports = {}
    for k, p in edges.items():
        for pt in (p[0], p[-1]):
            for i, n in enumerate(nodes):
                if n[0] - 1 <= pt[0] <= n[2] + 1 and n[1] - 1 <= pt[1] <= n[3] + 1:
                    side = ('T' if abs(pt[1] - n[1]) < 1 else 'B' if abs(pt[1] - n[3]) < 1
                            else 'L' if abs(pt[0] - n[0]) < 1 else 'R')
                    ports.setdefault((i, side), []).append(pt)
    multi = {k: v for k, v in ports.items() if len(v) > 1}
    for (ni, side), lst in sorted(multi.items()):
        co = sorted(pt[0] if side in 'TB' else pt[1] for pt in lst)
        d = min(b - a for a, b in zip(co, co[1:]))
        say(d >= LIMITS['port_gap'], f'節點{ni} {side} 邊 {len(lst)} 條線，最小 {d:.0f}px（下限 {LIMITS["port_gap"]}）')
        if d < LIMITS['port_gap']:
            fails.append(f'節點{ni}{side} port {d:.0f}px')
    if not multi:
        print('  （無同邊多線）')

    print(f'[動畫週期 · 總循環 {cycle}s]')
    durs = sorted(set(re.findall(r'dur="([\d.]+)s"', svg)), key=float)
    begs = sorted(set(re.findall(r'begin="(-?[\d.]+)s"', svg)), key=float)
    if durs:
        bad = [d for d in durs if abs(cycle / float(d) - round(cycle / float(d))) > 1e-9]
        pos = [b for b in begs if float(b) > 0]
        say(not bad, f'dur={durs} 整除總循環' + (f' → 不整除：{bad}' if bad else ''))
        say(not pos, f'begin={begs} 全為負值或 0' + (f' → 正值會讓球停在 (0,0)：{pos}' if pos else ''))
        fails.extend([f'dur 不整除 {bad}'] if bad else [])
        fails.extend([f'正值 begin {pos}'] if pos else [])
    else:
        print('  （靜態圖，無動畫）')

    print('[文字溢出節點（估算寬度，斜邊按線性收窄）]')
    over = []
    for tx, ty, body, size, anchor in texts:
        w = text_width(body, size)
        x1 = tx if anchor == 'start' else tx - w / 2 if anchor == 'middle' else tx - w
        x2 = x1 + w
        for n in nodes:
            if not (n[0] <= tx <= n[2] and n[1] <= ty <= n[3]):
                continue
            span = poly_span(n[4], ty) if n[4] else (n[0], n[2])
            if span is None:
                continue
            lo, hi = span
            if x1 < lo - 0.5 or x2 > hi + 0.5:
                over.append((body[:24], f'{x1:.0f}..{x2:.0f}', f'可用 {lo:.0f}..{hi:.0f}',
                             '多邊形' if n[4] else '矩形'))
    say(not over, f'{len(over)} 處溢出' + (''.join(f'\n       {o}' for o in over) if over else ''))
    if over:
        fails.append(f'文字溢出 {len(over)} 處')
    print('  ℹ️  寬度為估算；判定臨界時在渲染階段用 getBBox() 複驗')

    print()
    for w in warns:
        print(f'⚠️  {w}')
    if fails:
        print('❌ 版面幾何組未通過：')
        for f in fails:
            print('  -', f)
        return 1
    print('✅ 版面幾何組全部通過')
    return 0

if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    cyc = 8.0
    if '--cycle' in sys.argv:
        cyc = float(sys.argv[sys.argv.index('--cycle') + 1])
    if not args:
        print(__doc__)
        sys.exit(2)
    sys.exit(run(args[0], cyc))
