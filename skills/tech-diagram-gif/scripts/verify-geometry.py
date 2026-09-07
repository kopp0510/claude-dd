#!/usr/bin/env python3
"""驗證 SVG 是否符合 Taste Gate「版面幾何」組 — 純標準庫，無 pip 依賴。

用法：python3 verify-geometry.py <diagram.svg> [--cycle 8.0]

這組檢查項的判定手段是「讀座標算術」，不是看截圖 —— ≥6px 的標籤間隙、
1.35 的繞路比、菱形斜邊上的文字溢出，縮到瀏覽器視窗後肉眼都分辨不出來。

辨識元素優先用 data-role 標記（`node` / `container` / `edge`），
沒有標記時退化用 Style 8 的畫法猜（rx=6 實心 rect / polygon 為節點、
rx=8 fill=none 為容器、id=e* 的 path 為連線）並印出警告 —— 猜錯會靜默漏檢。

無 python3 的環境退化為人工計算，不阻擋出圖。
"""
import itertools
import re
import sys
from pathlib import Path
from typing import NamedTuple, Optional

LIMITS = dict(nodes=9, edges=12, containers=4, notes=2,
              bends=2, detour=1.35, node_gap=80, gutter=20, port_gap=12,
              label_gap=6,   # 下限，不是區間：擁擠時加大到 8–10px 是建議不是上限
              accents=2,     # 只用於 print_not_covered 的提示文字（無法通用判定）
              port_gap_small=8)   # contract 的例外：小節點（邊長 < 100px）放寬到 8px

# class 名稱對應的預設字級；沒有 class 也沒有 font-size 時用 DEFAULT_FONT_SIZE
FONT_SIZES = {'nm': 20, 'sm': 15, 'al': 15, 'ttl': 31, 'lbl': 16, 'sub': 16}
DEFAULT_FONT_SIZE = 15


class Box(NamedTuple):
    """容器框，座標一律左上 (x1,y1) 到右下 (x2,y2)。"""
    x1: float
    y1: float
    x2: float
    y2: float


class Node(NamedTuple):
    """節點框；points 只有多邊形節點才有（用來算斜邊上的可用寬度）。"""
    x1: float
    y1: float
    x2: float
    y2: float
    points: Optional[tuple] = None


class Text(NamedTuple):
    x: float
    y: float
    body: str
    size: float
    anchor: str


class Diagram(NamedTuple):
    nodes: list
    containers: list
    edges: dict          # 連線 id -> 折線頂點 [(x, y), ...]
    texts: list
    tagged: bool         # 是否有 data-role 標記（沒有就是退化猜法）
    skipped_edges: list  # 無法做正交判定而略過的連線 [(id, 理由)]
    slanted: list        # 非正交線段 [(id, 段序)]；正交判定對它們無效


# ---------------------------------------------------------------- 幾何工具

def text_width(s, font_size):
    """估算文字寬度：CJK/全形 ≈ 1.0em，其餘 ≈ 0.55em。只用來抓明顯溢出，
    精確值要在渲染時用 getBBox() 複驗（見 SKILL.md 第 4 步）。"""
    return sum(font_size if ord(c) > 0x2E80 else font_size * 0.55 for c in s)


def polygon_x_span(points, y):
    # 限制：凸多邊形才準。凹形狀回傳的是外框跨度，中間的缺口會被當成可用空間
    # （目前 icons.md 的菱形／六角形都是凸的）。三點共線的退化多邊形回 None。
    """多邊形在高度 y 這條水平線上的可用 x 區間（掃描線求交）。"""
    xs = []
    for (x1, y1), (x2, y2) in zip(points, points[1:] + points[:1]):
        if y1 == y2:
            if abs(y - y1) < 1e-9:
                xs += [x1, x2]
            continue
        if min(y1, y2) <= y <= max(y1, y2):
            xs.append(x1 + (x2 - x1) * (y - y1) / (y2 - y1))
    return (min(xs), max(xs)) if xs else None


def segments(points):
    """把折線頂點拆成一段一段的線段。"""
    return list(zip(points, points[1:]))


def straight_distance(points):
    """頭尾兩點的曼哈頓距離 —— 不繞路時的理想長度。"""
    return abs(points[-1][0] - points[0][0]) + abs(points[-1][1] - points[0][1])


def path_length(points):
    """折線實際走過的長度。"""
    return sum(abs(b[0] - a[0]) + abs(b[1] - a[1]) for a, b in segments(points))


def segments_cross(s1, s2):
    """兩條正交線段是否交叉（同向的不算，只判一橫一豎）。"""
    (x1, y1), (x2, y2) = s1
    (x3, y3), (x4, y4) = s2
    if (y1 == y2) == (y3 == y4):
        return False
    if y3 == y4:                       # 統一成「s1 水平、s2 垂直」再判
        (x1, y1), (x2, y2), (x3, y3), (x4, y4) = (x3, y3), (x4, y4), (x1, y1), (x2, y2)
    return min(x1, x2) < x3 < max(x1, x2) and min(y3, y4) < y1 < max(y3, y4)


def segment_hits_node(seg, node):
    """線段是否壓到節點框（水平段看 y 落在框內、垂直段看 x）。"""
    (x1, y1), (x2, y2) = seg
    if y1 == y2:
        return (node.y1 < y1 < node.y2
                and max(min(x1, x2), node.x1) < min(max(x1, x2), node.x2))
    return (node.x1 < x1 < node.x2
            and max(min(y1, y2), node.y1) < min(max(y1, y2), node.y2))


def edge_ends_at(node, points):
    """連線的頭或尾是否落在這個節點框內 —— 是的話它是端點，不算穿過。"""
    return any(node.x1 <= x <= node.x2 and node.y1 <= y <= node.y2
               for x, y in (points[0], points[-1]))


def box_gap(a, b):
    """兩個框之間的最短距離；斜角相鄰時取對角線，重疊時為 0。"""
    dx = max(a.x1 - b.x2, b.x1 - a.x2, 0)
    dy = max(a.y1 - b.y2, b.y1 - a.y2, 0)
    return (dx * dx + dy * dy) ** 0.5 if dx and dy else max(dx, dy)


def is_inside(node, container):
    """節點是否完全被容器框包住。"""
    return (node.x1 >= container.x1 and node.y1 >= container.y1
            and node.x2 <= container.x2 and node.y2 <= container.y2)


def inner_margin(node, container):
    """節點四邊離容器內緣最近的距離，就是這個節點吃掉的 gutter。"""
    return min(node.x1 - container.x1, node.y1 - container.y1,
               container.x2 - node.x2, container.y2 - node.y2)


def near_node(node, point):
    """點是否落在節點框上（含 1px 容差），用來判斷它是不是這個節點的 port。"""
    return (node.x1 - 1 <= point[0] <= node.x2 + 1
            and node.y1 - 1 <= point[1] <= node.y2 + 1)


def port_side(point, node):
    """port 落在節點的哪一邊：上 T / 下 B / 左 L / 右 R。"""
    if abs(point[1] - node.y1) < 1:
        return 'T'
    if abs(point[1] - node.y2) < 1:
        return 'B'
    if abs(point[0] - node.x1) < 1:
        return 'L'
    return 'R'


def text_x_range(text):
    """依 text-anchor 換算這段文字實際佔用的 x 區間。"""
    width = text_width(text.body, text.size)
    if text.anchor == 'start':
        left = text.x
    elif text.anchor == 'middle':
        left = text.x - width / 2
    else:
        left = text.x - width
    return left, left + width


# -------------------------------------------------------------------- 解析

ATTR_RE = re.compile(r'([\w:-]+)\s*=\s*"([^"]*)"')
NUM_RE = re.compile(r'^\s*(-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)\s*$')


def attrs_of(tag):
    """把一個開頭標籤拆成屬性字典。屬性順序在 SVG 規格上無意義，不可寫死。"""
    return {k: v for k, v in ATTR_RE.findall(tag)}


def num(attrs, key):
    """讀一個數值屬性；不是純數字（含百分比、單位、運算式）就回 None。"""
    m = NUM_RE.match(attrs.get(key, ''))
    return float(m.group(1)) if m else None


def box_of(attrs):
    """從 x/y/width/height 組出 Box；缺任一個或不是數字就回 None。"""
    x, y, w, h = (num(attrs, k) for k in ('x', 'y', 'width', 'height'))
    if None in (x, y, w, h):
        return None
    return Box(x, y, x + w, y + h)


def points_of(attrs, key='points'):
    """points / d 的座標對；同時吃 "x,y x,y" 與 "x y x y"。"""
    return [(float(a), float(b)) for a, b in
            re.findall(r'(-?[\d.]+)[,\s]+(-?[\d.]+)', attrs.get(key, ''))]


def scan(svg, name):
    """掃出某種標籤，回傳 [(attrs, 文件位置)]，文件位置供 z-order 判定用。"""
    return [(attrs_of(m.group(0)), m.start())
            for m in re.finditer(rf'<{name}\b[^>]*>', svg)]


def looks_like_node(a):
    """退化猜法：圓角實心框就是節點。不綁特定 rx 值或色票 ——
    icons.md 用 rx=10、style-2 用另一套 fill，寫死任何一個都會讓節點靜默消失。"""
    return 'rx' in a and a.get('fill', 'none') != 'none'


def looks_like_container(a):
    return 'rx' in a and a.get('fill', 'none') == 'none'


def parse_rects(svg, tagged):
    """矩形節點與容器（同一輪掃描，回傳 (nodes, containers)）。"""
    nodes, containers = [], []
    for a, _ in scan(svg, 'rect'):
        box = box_of(a)
        if not box:
            continue                                    # 畫布那種沒有 x/y 的整面 rect
        role = a.get('data-role')
        if role == 'node':
            nodes.append(Node(*box))
        elif role == 'container':
            containers.append(box)
        elif role is None and not tagged:
            if looks_like_node(a):
                nodes.append(Node(*box))
            elif looks_like_container(a):
                containers.append(box)
    return nodes, containers


def parse_polygons(svg, tagged):
    """多邊形節點（菱形等）。"""
    nodes = []
    for a, _ in scan(svg, 'polygon'):
        role = a.get('data-role')
        if tagged and role != 'node':
            continue
        if not tagged and role is None and not a.get('fill', '').startswith('#'):
            continue                                    # 箭頭 marker 的 polygon
        if role not in (None, 'node'):
            continue
        points = points_of(a)
        if len(points) < 3:
            continue
        xs = [q[0] for q in points]
        ys = [q[1] for q in points]
        nodes.append(Node(min(xs), min(ys), max(xs), max(ys), tuple(points)))
    return nodes


def circle_points(cx, cy, rx, ry, sides=24):
    """把圓／橢圓近似成多邊形，好讓掃描線（polygon_x_span）能算斜邊上的可用寬度。"""
    import math
    return tuple((cx + rx * math.cos(2 * math.pi * i / sides),
                  cy + ry * math.sin(2 * math.pi * i / sides)) for i in range(sides))


def parse_round_nodes(svg, tagged):
    """圓形與橢圓節點（Style 11 的 junction、圓柱端蓋等）。

    先前只認 rect 與 polygon，`<circle data-role="node">` 整個不算節點 ——
    該節點的間距、溢出、穿越全都沒驗到，而輸出照樣印「全部通過」。
    """
    nodes = []
    for name in ('circle', 'ellipse'):
        for a, _ in scan(svg, name):
            role = a.get('data-role')
            if role != 'node':
                continue                            # 圓形太常當裝飾，一律要顯式標記
            cx, cy = num(a, 'cx'), num(a, 'cy')
            if name == 'circle':
                rx = ry = num(a, 'r')
            else:
                rx, ry = num(a, 'rx'), num(a, 'ry')
            if None in (cx, cy, rx, ry):
                continue
            nodes.append(Node(cx - rx, cy - ry, cx + rx, cy + ry,
                              circle_points(cx, cy, rx, ry)))
    return nodes


def parse_edges(svg, tagged):
    """連線折線，回傳 ({id: [(x, y), ...]}, 略過清單)。

    只認由 M/L 絕對座標組成的正交折線。曲線與簡寫指令（h/v/a/c/s/q/t）**不靜默跳過** ——
    略過的連線等於少驗一條，會回傳理由讓呼叫端印出來。
    """
    edges, skipped = {}, []
    for a, _ in scan(svg, 'path'):
        role = a.get('data-role')
        if role is not None and role != 'edge':
            continue
        eid = a.get('id')
        if not eid or (not tagged and role is None and not re.match(r'^e\d+$', eid)):
            continue
        d = a.get('d', '')
        bad = set(re.findall(r'[A-Za-z]', d)) - {'M', 'L'}
        if bad:
            skipped.append((eid, f'含非直線指令 {sorted(bad)}'))
            continue
        points = [(float(x), float(y)) for x, y in
                  re.findall(r'(-?[\d.]+)[,\s]+(-?[\d.]+)', d)]
        if len(points) < 2:
            skipped.append((eid, '座標少於兩點'))
            continue
        if eid in edges:
            skipped.append((eid, 'id 重複，後者覆蓋前者'))
        edges[eid] = points
    return edges, skipped


def parse_texts(svg):
    """文字錨點、內容、字級與對齊方式；<tspan> 等子元素的文字一併取出。"""
    texts = []
    for m in re.finditer(r'<text\b([^>]*)>(.*?)</text>', svg, re.S):
        a = attrs_of('<text ' + m.group(1) + '>')
        body = re.sub(r'<[^>]*>', '', m.group(2)).strip()
        x, y = num(a, 'x'), num(a, 'y')
        if x is None or y is None or not body:
            continue
        size = num(a, 'font-size')
        if size is None:
            size = FONT_SIZES.get(a.get('class', ''), DEFAULT_FONT_SIZE)
        texts.append(Text(x, y, body, size, a.get('text-anchor', 'start')))
    return texts


def parse_masks(svg):
    """邊標籤底下的遮罩 rect：優先 data-role="mask"，退化用「無圓角的實心色塊」猜。

    回傳 ([(Box, 文件位置)], 是否為退化猜法) —— 位置用來判 z-order。
    退化猜法不綁畫布底色：漸層畫布（style-2 / style-8 都有）會讓底色比對整組失效，
    兩項遮罩檢查一起變空轉還印「沒有偵測到遮罩」，看起來像正常結果。
    """
    body = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)
    tagged = 'data-role="mask"' in body
    masks = []
    for a, pos in scan(body, 'rect'):
        if tagged:
            if a.get('data-role') != 'mask':
                continue
        else:
            if a.get('data-role') is not None or 'rx' in a:
                continue
            if not a.get('fill', '').startswith('#'):
                continue
        box = box_of(a)
        if box:
            masks.append((box, pos))
    return masks, not tagged


def node_boxes_in_order(svg):
    """節點框 + 文件位置 + 多邊形頂點，供 z-order 判定用（parse 出來的 Node 不帶位置）。

    多邊形一定要帶頂點：只用外框判會誤報 —— 菱形右上角那一大片外框內、
    形狀外的空白，放遮罩是安全的（實測踩過一次假陽性）。
    """
    body = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)
    tagged = 'data-role=' in svg
    out = []
    for a, pos in scan(body, 'rect'):
        role = a.get('data-role')
        is_node = role == 'node' if tagged else looks_like_node(a)
        box = box_of(a) if is_node else None
        if box:
            out.append((box, pos, None))
    for a, pos in scan(body, 'polygon'):
        role = a.get('data-role')
        if tagged and role != 'node':
            continue
        if not tagged and not a.get('fill', '').startswith('#'):
            continue
        points = points_of(a)
        if len(points) >= 3:
            xs = [q[0] for q in points]
            ys = [q[1] for q in points]
            out.append((Box(min(xs), min(ys), max(xs), max(ys)), pos, tuple(points)))
    for name in ('circle', 'ellipse'):
        for a, pos in scan(body, name):
            if a.get('data-role') != 'node':
                continue
            cx, cy = num(a, 'cx'), num(a, 'cy')
            rx = ry = num(a, 'r') if name == 'circle' else None
            if name == 'ellipse':
                rx, ry = num(a, 'rx'), num(a, 'ry')
            if None in (cx, cy, rx, ry):
                continue
            out.append((Box(cx - rx, cy - ry, cx + rx, cy + ry), pos,
                        circle_points(cx, cy, rx, ry)))
    return out


def count_unmarked(svg):
    """標記模式下，看起來像節點／容器卻沒標 data-role 的元素數。

    只要 SVG 裡出現任何一個 data-role，整份就切換成標記模式，沒標的元素會被
    整批略過 —— 而略過是靜默的，輸出照樣是「✅ 全部通過」。實測踩過：在未標記的
    圖上加一個 data-role="decoration" 的箭頭，節點與容器立刻歸零。
    """
    body = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)
    unmarked = 0
    for name in ('rect', 'polygon'):
        for a, _ in scan(body, name):
            if a.get('data-role') is not None:
                continue
            if name == 'rect' and (looks_like_node(a) or looks_like_container(a)) and box_of(a):
                unmarked += 1
            elif name == 'polygon' and a.get('fill', '').startswith('#') and len(points_of(a)) >= 3:
                unmarked += 1
    return unmarked


def parse(svg):
    """把一份 SVG 拆成幾何元素。"""
    tagged = 'data-role=' in svg
    body = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)   # marker 的 polygon 不是節點
    nodes, containers = parse_rects(body, tagged)
    nodes += parse_polygons(body, tagged)
    nodes += parse_round_nodes(body, tagged)
    edges, skipped = parse_edges(body, tagged)
    slanted = [(eid, i) for eid, pts in edges.items()
               for i, ((x1, y1), (x2, y2)) in enumerate(segments(pts))
               if x1 != x2 and y1 != y2]
    return Diagram(nodes, containers, edges, parse_texts(body), tagged, skipped, slanted)


# -------------------------------------------------------------------- 檢查

class Report:
    """每項都印出實際數值（不只 pass/fail），並累積未通過與警告清單。"""

    def __init__(self):
        self.fails = []
        self.warns = []

    def say(self, ok, msg):
        print(f'  {"✅" if ok else "❌"} {msg}')

    def fail(self, msg):
        self.fails.append(msg)

    def warn(self, msg):
        self.warns.append(msg)

    def check(self, ok, msg, fail_msg):
        """印一行帶數值的結果；沒過就記進 fails。"""
        self.say(ok, msg)
        if not ok:
            self.fails.append(fail_msg)


def check_budget(report, diagram):
    print('[數量預算]')
    for name, got, limit in (('節點', len(diagram.nodes), LIMITS['nodes']),
                             ('連線', len(diagram.edges), LIMITS['edges']),
                             ('容器/分組', len(diagram.containers), LIMITS['containers'])):
        report.check(got <= limit, f'{name} {got}（上限 {limit}）', f'{name} {got} > {limit}')


def check_bends_and_detour(report, edges):
    """一條線兩個指標，所以不用 check()：印一行、可能記兩筆 fail。"""
    print('[折數 / 繞路比]')
    for eid, points in sorted(edges.items()):
        bends = len(points) - 2
        straight = straight_distance(points)
        detour = path_length(points) / straight if straight else 1.0
        report.say(bends <= LIMITS['bends'] and detour <= LIMITS['detour'],
                   f'{eid}: {bends} 折（上限 {LIMITS["bends"]}）'
                   f'· 繞路比 {detour:.2f}（上限 {LIMITS["detour"]}）')
        if bends > LIMITS['bends']:
            report.fail(f'{eid} {bends} 折')
        if detour > LIMITS['detour']:
            report.fail(f'{eid} 繞路比 {detour:.2f}')


def check_crossings(report, edges):
    all_segments = [(eid, seg) for eid, points in edges.items() for seg in segments(points)]
    crossings = [(a, b) for i, (a, sa) in enumerate(all_segments)
                 for b, sb in all_segments[i + 1:] if a != b and segments_cross(sa, sb)]
    print('[交叉]')
    report.check(not crossings,
                 f'{len(crossings)} 處（上限 0）' + (f' → {crossings}' if crossings else ''),
                 f'交叉 {crossings}')


def check_pass_through(report, edges, nodes):
    through = [(eid, node) for eid, points in edges.items()
               for seg in segments(points) for node in nodes
               if segment_hits_node(seg, node) and not edge_ends_at(node, points)]
    print('[穿過非端點節點]')
    report.check(not through,
                 f'{len(through)} 處' + (f' → {through}' if through else ''),
                 f'穿過節點 {through}')


def check_node_gap(report, nodes):
    print('[節點間距]')
    if len(nodes) < 2:
        return
    closest = min(box_gap(a, b) for a, b in itertools.combinations(nodes, 2))
    report.check(closest >= LIMITS['node_gap'],
                 f'最小 {closest:.0f}px（下限 {LIMITS["node_gap"]}）',
                 f'節點間距 {closest:.0f}px')


def _overlaps(a, b):
    return a.x1 < b.x2 and b.x1 < a.x2 and a.y1 < b.y2 and b.y1 < a.y2


def check_containers(report, nodes, containers):
    print(f'[容器 gutter · 下限 {LIMITS["gutter"]}px]')
    if not containers:
        print('  （沒有容器）')
        return
    for i, container in enumerate(containers):
        # 用「相交」而非「完全包住」挑成員：節點戳出容器邊界時，
        # 若只算完全包住的，它會整個退出 gutter 檢查 —— 越壞越通過。
        members = [n for n in nodes if _overlaps(n, container)]
        if not members:
            continue
        outside = [n for n in members if not is_inside(n, container)]
        if outside:
            where = ', '.join(f'({n.x1:.0f},{n.y1:.0f})' for n in outside)
            report.check(False,
                         f'容器{i} 有 {len(outside)} 個節點越過邊界 → {where}',
                         f'容器{i} 有節點越界 {where}')
            continue
        gutter = min(inner_margin(n, container) for n in members)
        report.check(gutter >= LIMITS['gutter'],
                     f'容器{i} 含 {len(members)} 節點，最小 {gutter:.0f}px',
                     f'容器{i} gutter {gutter:.0f}px')
    orphans = [n for n in nodes
               if not any(_overlaps(n, c) for c in containers)]
    report.check(not orphans,
                 f'完全在所有容器外的節點 {len(orphans)} 個'
                 + (f' → {[(f"{n.x1:.0f},{n.y1:.0f}") for n in orphans]}' if orphans else ''),
                 f'{len(orphans)} 個節點在所有容器外')


def check_ports(report, edges, nodes):
    """同一個節點同一邊接多條線時，port 之間要留得下箭頭。"""
    print('[同邊多 port 間距]')
    ports = {}
    for points in edges.values():
        for point in (points[0], points[-1]):
            for i, node in enumerate(nodes):
                if near_node(node, point):
                    ports.setdefault((i, port_side(point, node)), []).append(point)
    shared = {key: pts for key, pts in ports.items() if len(pts) > 1}
    if not shared:
        print('  （無同邊多線）')
        return
    for (index, side), pts in sorted(shared.items()):
        node = nodes[index]
        coords = sorted(pt[0] if side in 'TB' else pt[1] for pt in pts)
        closest = min(b - a for a, b in zip(coords, coords[1:]))
        # contract 的例外：小節點（該邊長度 < 100px）下限放寬到 8px
        edge_len = (node.x2 - node.x1) if side in 'TB' else (node.y2 - node.y1)
        limit = LIMITS['port_gap'] if edge_len >= 100 else LIMITS['port_gap_small']
        report.check(closest >= limit,
                     f'節點{index} {side} 邊 {len(pts)} 條線，最小 {closest:.0f}px'
                     f'（下限 {limit}，邊長 {edge_len:.0f}px）',
                     f'節點{index}{side} port {closest:.0f}px < {limit}px')


def check_animation(report, svg, cycle):
    print(f'[動畫週期 · 總循環 {cycle}s]')
    durs = sorted(set(re.findall(r'dur="([\d.]+)s"', svg)), key=float)
    begins = sorted(set(re.findall(r'begin="(-?[\d.]+)s"', svg)), key=float)
    if not durs:
        print('  （靜態圖，無動畫）')
        return
    indivisible = [d for d in durs
                   if abs(cycle / float(d) - round(cycle / float(d))) > 1e-9]
    positive = [b for b in begins if float(b) > 0]
    report.check(not indivisible,
                 f'dur={durs} 整除總循環' + (f' → 不整除：{indivisible}' if indivisible else ''),
                 f'dur 不整除 {indivisible}')
    report.check(not positive,
                 f'begin={begins} 全為負值或 0'
                 + (f' → 正值會讓球停在 (0,0)：{positive}' if positive else ''),
                 f'正值 begin {positive}')


def check_text_overflow(report, nodes, texts):
    print('[文字溢出節點（估算寬度，斜邊按線性收窄）]')
    overflow = []
    for text in texts:
        x1, x2 = text_x_range(text)
        for node in nodes:
            if not (node.x1 <= text.x <= node.x2 and node.y1 <= text.y <= node.y2):
                continue
            span = polygon_x_span(node.points, text.y) if node.points else (node.x1, node.x2)
            if span is None:
                continue
            lo, hi = span
            if x1 < lo - 0.5 or x2 > hi + 0.5:
                overflow.append((text.body[:24], f'{x1:.0f}..{x2:.0f}',
                                 f'可用 {lo:.0f}..{hi:.0f}',
                                 '多邊形' if node.points else '矩形'))
    report.check(not overflow,
                 f'{len(overflow)} 處溢出'
                 + (''.join(f'\n       {o}' for o in overflow) if overflow else ''),
                 f'文字溢出 {len(overflow)} 處')
    print('  ℹ️  寬度為估算；判定臨界時在渲染階段用 getBBox() 複驗')


def check_parallel_edges(report, edges):
    print(f'[平行同向連線的全程間距 · 下限 {LIMITS["port_gap"]}px]')
    flat = [(eid, seg) for eid, pts in edges.items() for seg in segments(pts)]
    too_close = []
    for i, (id_a, seg_a) in enumerate(flat):
        for id_b, seg_b in flat[i + 1:]:
            if id_a == id_b:
                continue
            (ax1, ay1), (ax2, ay2) = seg_a
            (bx1, by1), (bx2, by2) = seg_b
            if ay1 == ay2 and by1 == by2:                       # 兩段都水平
                overlap = min(max(ax1, ax2), max(bx1, bx2)) - max(min(ax1, ax2), min(bx1, bx2))
                distance = abs(ay1 - by1)
            elif ax1 == ax2 and bx1 == bx2:                     # 兩段都垂直
                overlap = min(max(ay1, ay2), max(by1, by2)) - max(min(ay1, ay2), min(by1, by2))
                distance = abs(ax1 - bx1)
            else:
                continue
            if overlap > 0 and distance < LIMITS['port_gap']:
                too_close.append((id_a, id_b, f'{distance:.0f}px'))
    report.check(not too_close,
                 f'{len(too_close)} 對平行線太近' + (f' → {too_close}' if too_close else ''),
                 f'平行線間距不足 {too_close}')


def _mask_to_segment_gap(box, segment):
    """遮罩與一段正交線的可見間隙；負值代表遮罩壓在線上。"""
    (x1, y1), (x2, y2) = segment
    if y1 == y2:                                   # 水平線 → 量垂直間隙
        if not (min(x1, x2) < box.x2 and box.x1 < max(x1, x2)):
            return None
        if box.y2 <= y1:
            return y1 - box.y2
        if y1 <= box.y1:
            return box.y1 - y1
        return -1.0
    if not (min(y1, y2) < box.y2 and box.y1 < max(y1, y2)):
        return None
    if box.x2 <= x1:
        return x1 - box.x2
    if x1 <= box.x1:
        return box.x1 - x1
    return -1.0


def check_label_clearance(report, svg, edges):
    # 限制：量的是「距離最近的任何一條線」，不是「標籤自己那條線」。
    # contract 對無關幾何的淨空下限是 4px，比這裡的 6px 鬆，所以本檢查偏嚴不偏鬆。
    print(f'[邊標籤遮罩與連線的可見間隙 · 下限 {LIMITS["label_gap"]}px]')
    masks, guessed = parse_masks(svg)
    if not masks:
        report.warn('沒有偵測到標籤遮罩 —— 若圖上有邊標籤，這兩項檢查等於空轉；'
                    '請在遮罩 rect 標 data-role="mask"')
        print('  ⚠️  沒有偵測到標籤遮罩（見結尾警告）')
        return
    if guessed:
        print(f'  ℹ️  {len(masks)} 個遮罩靠畫法猜出（無 data-role="mask"）')
    measured = 0
    for box, _ in masks:
        nearest = None
        for edge_id, points in edges.items():
            for segment in segments(points):
                gap = _mask_to_segment_gap(box, segment)
                if gap is None:
                    continue
                if nearest is None or abs(gap) < abs(nearest[0]):
                    nearest = (gap, edge_id)
        if nearest is None:
            continue
        gap, edge_id = nearest
        measured += 1
        where = f'遮罩 ({box.x1:.0f},{box.y1:.0f}) ↔ {edge_id}'
        if gap < 0:
            report.check(False, f'{where} 遮罩壓在線上', f'{where} 遮罩壓線')
        else:
            report.check(gap >= LIMITS['label_gap'],
                         f'{where} 間隙 {gap:.0f}px',
                         f'{where} 間隙 {gap:.0f}px < {LIMITS["label_gap"]}px')
    if not measured:
        print('  （遮罩都沒有對應到連線）')


def _polygon_overlaps_box(points, box):
    """多邊形在 box 的高度範圍內，實際 x 跨度是否與 box 重疊。"""
    for y in (box.y1, (box.y1 + box.y2) / 2, box.y2):
        span = polygon_x_span(points, y)
        if span and span[0] < box.x2 and box.x1 < span[1]:
            return True
    return False


def check_mask_zorder(report, svg):
    print('[標籤遮罩的 z-order]')
    masks, _ = parse_masks(svg)
    nodes = node_boxes_in_order(svg)
    if not masks or not nodes:
        print('  （沒有遮罩或沒有節點，這項未實際判定）')
        return
    covered = []
    for mask, mask_pos in masks:
        for node, node_pos, points in nodes:
            if node_pos <= mask_pos:
                continue                            # 先畫的節點不會蓋住後畫的遮罩
            if not _overlaps(mask, node) or is_inside(mask, node):
                continue                            # 邊緣剛好相接不算蓋住
            if points and not _polygon_overlaps_box(points, mask):
                continue                            # 外框重疊但形狀沒碰到（菱形的角落空白）
            covered.append((f'({mask.x1:.0f},{mask.y1:.0f})',
                            f'節點({node.x1:.0f},{node.y1:.0f})'))
    report.check(not covered,
                 f'{len(covered)} 個遮罩被之後才畫的節點蓋到'
                 + (f' → {covered}' if covered else ''),
                 f'遮罩被節點蓋掉 {covered}')
    print('  ℹ️  遮罩完全落在節點內部視為徽章，不算蓋掉')


def print_not_covered():
    print('[本腳本未涵蓋 · 需人工或渲染判定]')
    print(f'  · 強調色元素 ≤{LIMITS["accents"]}、註解框 ≤{LIMITS["notes"]}'
          ' —— 哪個顏色算 accent 無法通用判定，人工數')
    print('  · port 落點公式 L*k/(N+1)（contract）—— 只驗間距，不驗是否等距分佈')
    print('  · 文字擠成兩行、假捲軸、小球是否真的有位移 —— 看截圖（Taste Gate「渲染實況」組）')


def run(path, cycle):
    svg = Path(path).read_text(encoding='utf-8')
    diagram = parse(svg)
    report = Report()

    print(f'== {path} ==')
    print(f'辨識方式：{"data-role 標記" if diagram.tagged else "⚠️  無 data-role，用畫法猜（可能漏檢）"}')
    if not diagram.tagged:
        report.warn('SVG 未標 data-role，本次為啟發式辨識')
    else:
        unmarked = count_unmarked(svg)
        if unmarked:
            print(f'  ⚠️  另有 {unmarked} 個元素看起來是節點／容器但沒標 data-role，已被略過')
            report.warn(f'{unmarked} 個疑似節點／容器沒標 data-role，未參與檢查 —— '
                        '部分標記比完全不標更危險，補齊或全部拿掉')
    print(f'元素：節點 {len(diagram.nodes)} · 連線 {len(diagram.edges)} '
          f'· 容器 {len(diagram.containers)} · 文字 {len(diagram.texts)}')
    for eid, why in diagram.skipped_edges:
        print(f'  ⚠️  連線 {eid} 略過：{why}')
        report.warn(f'連線 {eid} 未參與幾何判定（{why}）')
    if diagram.slanted:
        ids = sorted({eid for eid, _ in diagram.slanted})
        print(f'  ⚠️  {len(diagram.slanted)} 個非正交線段（{ids}）—— 正交判定對它們無效')
        report.warn(f'非正交線段 {ids}：交叉/穿越/間距判定不適用，需人工確認')
    print()

    check_budget(report, diagram)
    check_bends_and_detour(report, diagram.edges)
    check_crossings(report, diagram.edges)
    check_pass_through(report, diagram.edges, diagram.nodes)
    check_node_gap(report, diagram.nodes)
    check_containers(report, diagram.nodes, diagram.containers)
    check_ports(report, diagram.edges, diagram.nodes)
    check_parallel_edges(report, diagram.edges)
    check_label_clearance(report, svg, diagram.edges)
    check_mask_zorder(report, svg)
    check_animation(report, svg, cycle)
    check_text_overflow(report, diagram.nodes, diagram.texts)
    print_not_covered()

    print()
    for warning in report.warns:
        print(f'⚠️  {warning}')
    if report.fails:
        print('❌ 版面幾何組未通過：')
        for failure in report.fails:
            print('  -', failure)
        return 1
    print('✅ 版面幾何組全部通過')
    return 0


def parse_argv(argv):
    """回傳 (檔案清單, 總循環秒數)；--cycle 放在檔名前後都要能用。"""
    paths, cycle, i = [], 8.0, 0
    while i < len(argv):
        if argv[i] == '--cycle':
            if i + 1 >= len(argv):
                raise SystemExit('❌ --cycle 後面要接秒數，例如 --cycle 8.0')
            try:
                cycle = float(argv[i + 1])
            except ValueError:
                raise SystemExit(f'❌ --cycle 的值不是數字：{argv[i + 1]}')
            i += 2
            continue
        if argv[i].startswith('--'):
            raise SystemExit(f'❌ 不認得的選項：{argv[i]}')
        paths.append(argv[i])
        i += 1
    return paths, cycle


if __name__ == '__main__':
    files, total_cycle = parse_argv(sys.argv[1:])
    if not files:
        print(__doc__)
        sys.exit(2)
    if not Path(files[0]).is_file():
        raise SystemExit(f'❌ 找不到檔案：{files[0]}')
    sys.exit(run(files[0], total_cycle))
