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
              label_gap=6)   # 下限，不是區間：擁擠時加大到 8–10px 是建議不是上限

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


# ---------------------------------------------------------------- 幾何工具

def text_width(s, font_size):
    """估算文字寬度：CJK/全形 ≈ 1.0em，其餘 ≈ 0.55em。只用來抓明顯溢出，
    精確值要在渲染時用 getBBox() 複驗（見 SKILL.md 第 4 步）。"""
    return sum(font_size if ord(c) > 0x2E80 else font_size * 0.55 for c in s)


def polygon_x_span(points, y):
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

def parse_rects(svg, tagged):
    """矩形節點與容器（同一輪掃描，回傳 (nodes, containers)）。"""
    nodes, containers = [], []
    for m in re.finditer(r'<rect\b[^>]*>', svg):
        tag = m.group(0)
        box = re.search(r'x="([\d.]+)"\s+y="([\d.]+)"\s+width="([\d.]+)"\s+height="([\d.]+)"', tag)
        if not box:
            continue
        x, y, w, h = map(float, box.groups())
        role = re.search(r'data-role="(\w+)"', tag)
        if role:
            if role.group(1) == 'node':
                nodes.append(Node(x, y, x + w, y + h))
            elif role.group(1) == 'container':
                containers.append(Box(x, y, x + w, y + h))
        elif not tagged:                                    # 退化猜法：靠畫法認
            if 'rx="6"' in tag and 'fill="none"' not in tag:
                nodes.append(Node(x, y, x + w, y + h))
            elif 'rx="8"' in tag and 'fill="none"' in tag:
                containers.append(Box(x, y, x + w, y + h))
    return nodes, containers


def parse_polygons(svg, tagged):
    """多邊形節點（菱形等）。"""
    nodes = []
    for m in re.finditer(r'<polygon\b[^>]*points="([\d,.\s]+)"[^>]*>', svg):
        tag = m.group(0)
        if 'marker' in tag or ('data-role=' in tag and 'node' not in tag):
            continue
        if tagged and 'data-role="node"' not in tag:
            continue
        if not tagged and 'fill="#' not in tag:      # 箭頭 marker 的 polygon 沒有座標框
            continue
        # points 可能寫成 "x,y x,y" 或 "x y x y"，一律用數字對抓
        points = [(float(a), float(b)) for a, b in
                  re.findall(r'(-?[\d.]+)[,\s]+(-?[\d.]+)', m.group(1))]
        if len(points) < 3:
            continue
        xs = [p[0] for p in points]
        ys = [p[1] for p in points]
        nodes.append(Node(min(xs), min(ys), max(xs), max(ys), tuple(points)))
    return nodes


def parse_edges(svg, tagged):
    """連線折線，回傳 {id: [(x, y), ...]}。曲線不做正交幾何判定，直接跳過。"""
    edges = {}
    for m in re.finditer(r'<path\b[^>]*>', svg):
        tag = m.group(0)
        if 'data-role=' in tag and 'edge' not in tag:
            continue
        eid = re.search(r'id="(\w+)"', tag)
        if not eid or (not tagged and not re.match(r'^e\d+$', eid.group(1))):
            continue
        d = re.search(r'\sd="([^"]+)"', tag)
        if not d or 'C' in d.group(1) or 'Q' in d.group(1):
            continue
        points = [(float(a), float(b)) for a, b in
                  re.findall(r'(-?[\d.]+),(-?[\d.]+)', d.group(1))]
        if len(points) >= 2:
            edges[eid.group(1)] = points
    return edges


def parse_texts(svg):
    """文字錨點、內容、字級與對齊方式。"""
    texts = []
    for m in re.finditer(r'<text\b([^>]*)>([^<]*)</text>', svg):
        attrs, body = m.groups()
        pos = re.search(r'x="([\d.]+)"\s+y="([\d.]+)"', attrs)
        if not pos or not body.strip():
            continue
        font_size = re.search(r'font-size="([\d.]+)"', attrs)
        cls = re.search(r'class="(\w+)"', attrs)
        if font_size:
            size = float(font_size.group(1))
        else:
            size = FONT_SIZES.get(cls.group(1) if cls else '', DEFAULT_FONT_SIZE)
        if 'text-anchor="middle"' in attrs:
            anchor = 'middle'
        elif 'text-anchor="end"' in attrs:
            anchor = 'end'
        else:
            anchor = 'start'
        texts.append(Text(float(pos.group(1)), float(pos.group(2)), body, size, anchor))
    return texts


def parse_masks(svg):
    """邊標籤底下的遮罩 rect：優先 data-role="mask"，退化用「填畫布底色、無圓角」猜。

    回傳 [(Box, 文件位置)] —— 位置用來判 z-order（後畫的節點會蓋掉先畫的遮罩）。
    """
    body = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)
    canvas = re.search(r'<rect width="[\d.]+" height="[\d.]+" fill="(#[0-9a-fA-F]{3,8})"', body)
    background = canvas.group(1).lower() if canvas else None
    masks = []
    for m in re.finditer(r'<rect\b[^>]*>', body):
        tag = m.group(0)
        if 'data-role="mask"' not in tag:
            if 'data-role=' in tag or 'rx=' in tag:
                continue
            if not background or f'fill="{background}"' not in tag.lower():
                continue
        box = _rect_box(tag)
        if box:
            masks.append((box, m.start()))
    return masks


def node_boxes_in_order(svg):
    """節點框 + 文件位置 + 多邊形頂點，供 z-order 判定用（parse 出來的 Node 不帶位置）。

    多邊形一定要帶頂點：只用外框判會誤報 —— 菱形右上角那一大片外框內、
    形狀外的空白，放遮罩是安全的（實測踩過一次假陽性）。
    """
    body = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)
    tagged = 'data-role=' in svg
    out = []
    for m in re.finditer(r'<rect\b[^>]*>', body):
        tag = m.group(0)
        is_node = 'data-role="node"' in tag if tagged else (
            'rx="6"' in tag and 'fill="none"' not in tag)
        box = _rect_box(tag) if is_node else None
        if box:
            out.append((box, m.start(), None))
    for m in re.finditer(r'<polygon\b[^>]*points="([\d,.\s]+)"[^>]*>', body):
        tag = m.group(0)
        if tagged and 'data-role="node"' not in tag:
            continue
        if not tagged and 'fill="#' not in tag:
            continue
        pts = [(float(a), float(b)) for a, b in
               re.findall(r'(-?[\d.]+)[,\s]+(-?[\d.]+)', m.group(1))]
        if len(pts) >= 3:
            xs = [q[0] for q in pts]
            ys = [q[1] for q in pts]
            out.append((Box(min(xs), min(ys), max(xs), max(ys)), m.start(), tuple(pts)))
    return out


def _rect_box(tag):
    g = re.search(r'x="([\d.]+)"\s+y="([\d.]+)"\s+width="([\d.]+)"\s+height="([\d.]+)"', tag)
    if not g:
        return None
    x, y, w, h = map(float, g.groups())
    return Box(x, y, x + w, y + h)


def parse(svg):
    """把一份 SVG 拆成幾何元素。"""
    tagged = 'data-role=' in svg
    body = re.sub(r'<defs\b.*?</defs>', '', svg, flags=re.S)   # marker 的 polygon 不是節點
    nodes, containers = parse_rects(body, tagged)
    nodes += parse_polygons(body, tagged)
    return Diagram(nodes, containers, parse_edges(body, tagged), parse_texts(body), tagged)


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


def check_containers(report, nodes, containers):
    print('[容器 gutter]')
    for i, container in enumerate(containers):
        inside = [n for n in nodes if is_inside(n, container)]
        if not inside:
            continue
        gutter = min(inner_margin(n, container) for n in inside)
        report.check(gutter >= LIMITS['gutter'],
                     f'容器{i} 含 {len(inside)} 節點，最小 {gutter:.0f}px'
                     f'（下限 {LIMITS["gutter"]}）',
                     f'容器{i} gutter {gutter:.0f}px')
    if not containers:
        return
    orphans = [n for n in nodes if not any(is_inside(n, c) for c in containers)]
    report.say(not orphans,
               f'未被容器包住的節點 {len(orphans)} 個' + (f' → {orphans}' if orphans else ''))
    if orphans:
        report.warn(f'{len(orphans)} 個節點在所有容器外')


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
        coords = sorted(pt[0] if side in 'TB' else pt[1] for pt in pts)
        closest = min(b - a for a, b in zip(coords, coords[1:]))
        report.check(closest >= LIMITS['port_gap'],
                     f'節點{index} {side} 邊 {len(pts)} 條線，最小 {closest:.0f}px'
                     f'（下限 {LIMITS["port_gap"]}）',
                     f'節點{index}{side} port {closest:.0f}px')


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
    print(f'[邊標籤遮罩與連線的可見間隙 · 下限 {LIMITS["label_gap"]}px]')
    masks = parse_masks(svg)
    if not masks:
        print('  （沒有偵測到標籤遮罩）')
        return
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
    masks = parse_masks(svg)
    nodes = node_boxes_in_order(svg)
    if not masks or not nodes:
        print('  （沒有遮罩或沒有節點）')
        return
    covered = []
    for mask, mask_pos in masks:
        for node, node_pos, points in nodes:
            if node_pos <= mask_pos:
                continue                            # 先畫的節點不會蓋住後畫的遮罩
            if box_gap(mask, node) != 0 or is_inside(mask, node):
                continue
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
    print(f'  · 強調色元素 ≤2、註解框 ≤{LIMITS["notes"]} —— 哪個顏色算 accent 無法通用判定，人工數')
    print('  · 文字擠成兩行、假捲軸、小球是否真的有位移 —— 看截圖（Taste Gate「渲染實況」組）')


def run(path, cycle):
    svg = Path(path).read_text(encoding='utf-8')
    diagram = parse(svg)
    report = Report()

    print(f'== {path} ==')
    print(f'辨識方式：{"data-role 標記" if diagram.tagged else "⚠️  無 data-role，用畫法猜（可能漏檢）"}')
    if not diagram.tagged:
        report.warn('SVG 未標 data-role，本次為啟發式辨識')
    print(f'元素：節點 {len(diagram.nodes)} · 連線 {len(diagram.edges)} '
          f'· 容器 {len(diagram.containers)} · 文字 {len(diagram.texts)}\n')

    check_budget(report, diagram)
    check_bends_and_detour(report, diagram.edges)
    check_crossings(report, diagram.edges)
    check_pass_through(report, diagram.edges, diagram.nodes)
    check_node_gap(report, diagram.nodes)
    check_containers(report, diagram.nodes, diagram.containers)
    check_ports(report, diagram.edges, diagram.nodes)
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


if __name__ == '__main__':
    paths = [a for a in sys.argv[1:] if not a.startswith('--')]
    cycle = 8.0
    if '--cycle' in sys.argv:
        cycle = float(sys.argv[sys.argv.index('--cycle') + 1])
    if not paths:
        print(__doc__)
        sys.exit(2)
    sys.exit(run(paths[0], cycle))
