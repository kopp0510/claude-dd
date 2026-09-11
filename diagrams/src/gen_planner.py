# -*- coding: utf-8 -*-
"""claude-dd 大工作怎麼跑（task-planner）— Style 8 Dark Luxury，1440x1080，總循環 7.2s"""
import io

SERIF = "Georgia,'Times New Roman','Songti TC','Noto Serif CJK TC',serif"
SANS = "-apple-system,'Helvetica Neue','PingFang TC','Noto Sans CJK TC',sans-serif"
BG, SURF = "#0a0a0a", "#111111"
GOLD, GOLD_DIM = "#d4a574", "#c9a96e"
T1, T2, T3 = "#f5f0eb", "#a39787", "#6b5f53"
GREEN, AMBER, GRAY, MINT = "#5a9e6f", "#fbbf24", "#94a3b8", "#6ee7b7"

ZH = dict(
    title="claude-dd 大工作怎麼跑",
    sub="要跨好幾段的工作 · 動手前先估段落數，兩段以上交給 task-planner · 小任務只走步驟 1、2，整段才跑 3–8",
    groups=["動手前 · 先估段落數", "進度表 · 寫進 docs/designs/", "每一段 · 照表由上往下做"],
    nodes=dict(
        ask=("交代工作", ["你說要做什麼", "例如一次交代三個功能"]),
        count=("估段落數", ["預估 N 個功能段落"]),
        loop=("照一般 8 步迴圈", ["一圈做得完，不用拆"]),
        plan=("task-planner 出草稿", ["段落、小任務、要加的測試", "你批准了才寫檔"]),
        table=("進度表", ["跨 session 留著，也進 git", "S1、S2… 由上往下做"]),
        resume=("換 session 或 /compact", ["先讀進度表", "從做到的地方接著做"]),
        tasks=("小任務 S2-1、S2-2…", ["一個一個做：實作、驗證、commit", "只走迴圈的步驟 1、2"]),
        whole=("整段跑步驟 3–8", ["小任務全部 commit 完才跑", "簡化、審查、再測、commit…"]),
        done=("標 DONE", ["3–8 跑完才標，寫回進度表", "全部 DONE 就收工"]),
    ),
    one="1 段", many="2 段以上", next="還有下一段",
    notes=[("怎麼估段落數", ["照功能數算，不照分層數算", "同一個功能的資料、API、畫面算一段",
                           "產生帳款、改權限規則這類高風險工作，", "不跟其他功能算同一段"]),
           ("小任務 commit 了，不等於這段做完", ["步驟 3、4、8 看的是整段的改動",
                                         "所以小任務全部做完，整段才跑 3–8"])],
    legend=[("主流程", GOLD, False), ("下一段：回到小任務", GOLD_DIM, True),
            ("換 session：讀進度表接手", MINT, False)],
    foot="Style 8 · Dark Luxury · claude-dd 大工作怎麼跑 · 依全域 CLAUDE.md §4.1、§3.9 與 task-planner 繪製",
)

EN = dict(
    title="claude-dd: how big work runs",
    sub="work that spans several increments · count increments first; at two or more, task-planner takes over · small tasks run only steps 1–2, the whole increment runs 3–8",
    groups=["Before starting · count increments", "Progress table · in docs/designs/", "Each increment · follow the table"],
    nodes=dict(
        ask=("Hand over the work", ["say what should be built", "e.g. three features at once"]),
        count=("Count increments", ["estimate N"]),
        loop=("Normal 8-step loop", ["fits in one loop, no split"]),
        plan=("task-planner drafts", ["increments, small tasks, tests", "files written after you approve"]),
        table=("Progress table", ["survives sessions, lives in git", "S1, S2… top to bottom"]),
        resume=("New session or /compact", ["reads the progress table first", "resumes where it stopped"]),
        tasks=("Small tasks S2-1, S2-2…", ["one by one: build, verify, commit", "loop steps 1–2 only"]),
        whole=("Whole increment: 3–8", ["after every small task is in", "simplify, review, re-verify…"]),
        done=("Mark DONE", ["after 3–8, written to the table", "all DONE: the work is finished"]),
    ),
    one="just 1", many="2 or more", next="next increment",
    notes=[("How increments are counted", ["by feature, not by layer", "a feature's data, API and UI = one",
                                           "high-risk work, e.g. generating bills or",
                                           "changing permission rules: own increment"]),
           ("A committed small task is not a done increment", ["steps 3, 4 and 8 read the whole increment's diff",
                                                               "so 3–8 run once, after every small task"])],
    legend=[("main flow", GOLD, False), ("next increment: back to small tasks", GOLD_DIM, True),
            ("new session: resume from the table", MINT, False)],
    foot="Style 8 · Dark Luxury · claude-dd: how big work runs · drawn from global CLAUDE.md §4.1, §3.9 and task-planner",
)

# ── 版面座標 ──
BW, BH = 250, 100
XS = [100, 430, 760, 1090]
YS = [186, 386, 586, 766]
# 三個分組，每個節點都要在某個容器裡：verify-geometry.py 把容器外的節點記成未通過
GROUPS = [(76, 146, 958, 164), (406, 346, 958, 164), (736, 546, 628, 344)]
# 節點落在哪一欄、哪一列；count 是菱形，其餘是矩形。
# 強調色只給兩個焦點（決策與進度表），岔出去的 loop 用灰，其餘同一個金色
PLACE = dict(ask=(0, 0, GOLD_DIM), count=(1, 0, AMBER), loop=(2, 0, GRAY),
             plan=(1, 1, GOLD_DIM), table=(2, 1, GREEN), resume=(3, 1, GOLD_DIM),
             tasks=(2, 2, GOLD_DIM), whole=(3, 2, GOLD_DIM), done=(3, 3, GOLD_DIM))


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def poly(*pts):
    # 正交折線只用 M/L 絕對座標：verify-geometry.py 不認 H/V 簡寫
    return "M " + " L ".join(f"{x:g} {y:g}" for x, y in pts)


def text_width(s, size):
    # 與 verify-geometry.py 同一套估法：CJK 1em，其餘 0.55em
    return sum(size if ord(c) > 0x2E80 else size * 0.55 for c in s)


def box(x, y, name, lines, color):
    # 節點文字的字級只寫在 font-size 屬性，CSS 的 .nm/.sm 不設：verify-geometry.py 讀屬性，沒寫就依 class
    # 猜（nm→20、sm→15）而誤報溢出；CSS 又會蓋過屬性，兩邊各寫一份的話，只改 CSS 檢查仍照舊數字估
    o = [f'  <g><rect data-role="node" x="{x}" y="{y}" width="{BW}" height="{BH}" rx="6" fill="{SURF}" '
         f'stroke="{color}" stroke-width="1.5"/>\n',
         f'    <text x="{x+16}" y="{y+28}" class="nm" font-size="15" fill="{color}">{esc(name)}</text>\n']
    for i, ln in enumerate(lines):
        o.append(f'    <text x="{x+16}" y="{y+54+i*21}" class="sm" font-size="11.5">{esc(ln)}</text>\n')
    o.append('  </g>\n')
    return "".join(o)


def diamond(x, y, name, lines, color):
    cx, cy = x + BW // 2, y + BH // 2
    pts = f"{cx},{y} {x+BW},{cy} {cx},{y+BH} {x},{cy}"
    o = [f'  <g><polygon data-role="node" points="{pts}" fill="{SURF}" stroke="{color}" stroke-width="1.5"/>\n',
         f'    <text x="{cx}" y="{cy-4}" class="nm" font-size="15" text-anchor="middle" fill="{color}">'
         f'{esc(name)}</text>\n']
    for i, ln in enumerate(lines):
        o.append(f'    <text x="{cx}" y="{cy+20+i*20}" class="sm" font-size="11.5" text-anchor="middle">'
                 f'{esc(ln)}</text>\n')
    o.append('  </g>\n')
    return "".join(o)


def label(x, y, text, anchor):
    # 底下墊一塊底色遮罩並標 data-role="mask"，幾何檢查才量得到它與連線的間隙（要 ≥6px，這裡留 8）
    w = text_width(text, 11)
    left = x if anchor == "start" else x - w / 2
    return (f'<rect data-role="mask" x="{left-5:g}" y="{y-13}" width="{w+10:g}" height="17" fill="{BG}"/>\n'
            f'<text x="{x}" y="{y}" class="el" text-anchor="{anchor}">{esc(text)}</text>\n')


def note(x, y, head, lines):
    o = [f'<text x="{x}" y="{y}" class="nh">{esc(head)}</text>\n']
    for i, ln in enumerate(lines):
        o.append(f'<text x="{x}" y="{y+26+i*21}" class="nb">{esc(ln)}</text>\n')
    return "".join(o)


def ball(pid, color, dur, begin):
    return (f'  <circle r="8" fill="{color}" opacity="0.22"><animateMotion dur="{dur}s" '
            f'begin="{begin}s" repeatCount="indefinite"><mpath href="#{pid}"/></animateMotion></circle>\n'
            f'  <circle r="4" fill="{color}"><animateMotion dur="{dur}s" begin="{begin}s" '
            f'repeatCount="indefinite"><mpath href="#{pid}"/></animateMotion></circle>\n')


def build(L):
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 1080" width="1440" height="1080">\n']
    o.append(f'''<style>
  text {{ font-family: {SANS}; }}
  .ttl {{ font-family: {SERIF}; font-size: 40px; font-weight: 700; fill: {T1}; }}
  .sub {{ font-size: 13px; fill: {T2}; }}
  .grp {{ font-family: {SERIF}; font-size: 16px; font-weight: 700; fill: {GOLD_DIM}; }}
  .nm  {{ font-weight: 600; }}
  .sm  {{ fill: {T2}; }}
  .el  {{ font-size: 11px; fill: {T2}; }}
  .nh  {{ font-size: 12.5px; fill: {T2}; }}
  .nb  {{ font-size: 11px; fill: {T3}; }}
  .lg  {{ font-size: 11px; fill: {T2}; }}
  .ft  {{ font-size: 10.5px; fill: {T3}; }}
</style>
<defs>
  <radialGradient id="glow" cx="50%" cy="48%" r="44%">
    <stop offset="0%" stop-color="{GOLD}" stop-opacity="0.045"/>
    <stop offset="100%" stop-color="{GOLD}" stop-opacity="0"/></radialGradient>
  <marker id="ag" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0,10 3.5,0 7" fill="{GOLD}"/></marker>
  <marker id="ad" markerWidth="9" markerHeight="6.5" refX="8" refY="3.25" orient="auto">
    <polygon points="0 0,9 3.25,0 6.5" fill="{GOLD_DIM}"/></marker>
  <marker id="am" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0,10 3.5,0 7" fill="{MINT}"/></marker>
''')
    o.append('</defs>\n')
    o.append(f'<rect width="1440" height="1080" fill="{BG}"/>\n<rect width="1440" height="1080" fill="url(#glow)"/>\n')
    o.append(f'<text x="100" y="86" class="ttl">{esc(L["title"])}</text>\n')
    o.append(f'<text x="100" y="122" class="sub">{esc(L["sub"])}</text>\n')

    # 分組標題靠右：◇ 往下、進度表往下的連線從容器上緣左半邊進來，標題靠左會壓在線上
    for (gx, gy, gw, gh), lbl in zip(GROUPS, L["groups"]):
        o.append(f'<rect data-role="container" x="{gx}" y="{gy}" width="{gw}" height="{gh}" rx="8" fill="none" '
                 f'stroke="{GOLD}" stroke-width="0.5" stroke-dasharray="6,4" opacity="0.4"/>\n')
        o.append(f'<text x="{gx+gw-24}" y="{gy+26}" class="grp" text-anchor="end">{esc(lbl)}</text>\n')

    # 連線從來源框邊出發、停在目標框前 12px 留給箭頭；畫在 <defs> 外並標 data-role="edge"，
    # 小球的 <mpath> 直接指向它（放進 defs 用 <use> 引用的話，幾何檢查數到的連線是 0）
    c0, c1, c2, c3 = [y + BH // 2 for y in YS]
    mid = [x + BW // 2 for x in XS]
    paths = {
        "ask":    poly((XS[0]+BW, c0), (XS[1]-12, c0)),
        "one":    poly((XS[1]+BW, c0), (XS[2]-12, c0)),
        "many":   poly((mid[1], YS[0]+BH), (mid[1], YS[1]-12)),
        "write":  poly((XS[1]+BW, c1), (XS[2]-12, c1)),
        "resume": poly((XS[3], c1), (XS[2]+BW+12, c1)),
        "start":  poly((mid[2], YS[1]+BH), (mid[2], YS[2]-12)),
        "whole":  poly((XS[2]+BW, c2), (XS[3]-12, c2)),
        "done":   poly((mid[3], YS[2]+BH), (mid[3], YS[3]-12)),
        # 標 DONE 回到小任務、做下一段。小任務做完一個接下一個，不畫成繞回自己的線 —— 起訖點太近，
        # 繞路比會爆表；改在小任務框裡寫「一個一個做」
        "next":   poly((XS[3], c3), (mid[2], c3), (mid[2], YS[2]+BH+12)),
    }
    def edge(k, style):
        return f'  <path id="{k}" data-role="edge" d="{paths[k]}" fill="none" {style}/>\n'
    for k in ("ask", "one", "many", "write", "start", "whole", "done"):
        o.append(edge(k, f'stroke="{GOLD}" stroke-width="1.6" opacity="0.32" marker-end="url(#ag)"'))
    o.append(edge("resume", f'stroke="{MINT}" stroke-width="1.6" opacity="0.34" marker-end="url(#am)"'))
    o.append(edge("next", f'stroke="{GOLD_DIM}" stroke-width="1.4" stroke-dasharray="6,4" opacity="0.45" '
                          f'marker-end="url(#ad)"'))

    for key, (col, row, color) in PLACE.items():
        name, lines = L["nodes"][key]
        draw = diamond if key == "count" else box
        o.append(draw(XS[col], YS[row], name, lines, color))

    o.append(note(XS[3], YS[0]+20, *L["notes"][0]))
    o.append(note(XS[0], YS[2]+20, *L["notes"][1]))

    # 邊標籤在節點之後畫：先畫的話會被節點蓋掉
    o.append(label((XS[1]+BW+XS[2]) // 2, c0-12, L["one"], "middle"))
    o.append(label(mid[1]+13, YS[0]+BH+47, L["many"], "start"))
    o.append(label((mid[2]+XS[3]) // 2, c3-12, L["next"], "middle"))

    # dur 大致與路徑長成正比（68px→1.44、88px→1.8、323px→7.2），全部整除 7.2；
    # begin 避開 dur 的整數倍，否則小球跳回起點的那一格剛好落在 GIF 的循環接點
    o.append(ball("ask", GOLD, 1.44, -0.3))
    o.append(ball("one", GOLD, 1.44, -1.0))
    o.append(ball("many", GOLD, 1.8, -0.6))
    o.append(ball("write", GOLD, 1.44, -0.9))
    o.append(ball("resume", MINT, 1.44, -0.2))
    o.append(ball("start", GOLD, 1.8, -1.3))
    o.append(ball("whole", GOLD, 1.44, -0.7))
    o.append(ball("done", GOLD, 1.44, -1.2))
    o.append(ball("next", GOLD_DIM, 7.2, -2.5))

    lx = 100
    for text, col, dash in L["legend"]:
        da = ' stroke-dasharray="6,4"' if dash else ''
        mk = 'url(#am)' if col == MINT else ('url(#ad)' if col == GOLD_DIM else 'url(#ag)')
        o.append(f'<line x1="{lx}" y1="946" x2="{lx+56}" y2="946" stroke="{col}" stroke-width="2"{da} '
                 f'marker-end="{mk}"/>\n')
        o.append(f'<text x="{lx+70}" y="950" class="lg">{esc(text)}</text>\n')
        lx += 400
    o.append(f'<text x="100" y="992" class="ft">{esc(L["foot"])}</text>\n</svg>\n')
    return "".join(o)


for lang, L in (("zh-TW", ZH), ("en", EN)):
    svg = build(L)
    io.open(f"planner-{lang}.svg", "w", encoding="utf-8").write(svg)
    io.open(f"planner-{lang}.html", "w", encoding="utf-8").write(
        '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;'
        'overflow:hidden;background:#0a0a0a}svg{display:block}</style>' + svg)
    print("wrote planner-" + lang)
