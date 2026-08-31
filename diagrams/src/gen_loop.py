# -*- coding: utf-8 -*-
"""claude-dd 8 步開發迴圈圖 — Style 8 Dark Luxury，1440x1080，總循環 7.2s"""
import io

SERIF = "Georgia,'Times New Roman','Songti TC','Noto Serif CJK TC',serif"
SANS = "-apple-system,'Helvetica Neue','PingFang TC','Noto Sans CJK TC',sans-serif"
BG, SURF = "#0a0a0a", "#111111"
GOLD, GOLD_DIM = "#d4a574", "#c9a96e"
T1, T2, T3 = "#f5f0eb", "#a39787", "#6b5f53"
GREEN, VIOLET, BLUE, ROSE, AMBER, GRAY = "#5a9e6f", "#a78bfa", "#38bdf8", "#f87171", "#fbbf24", "#94a3b8"

ZH = dict(
    title="claude-dd 8 步開發迴圈",
    sub="每個功能段落都走這一圈 · 1–6 一定要做；7 有東西才做；8 只要動過 CLAUDE.md 就要做",
    groups=["A · 做出來（證明它是對的）",
            "B · 整理它（證明沒把對的改壞）",
            "C · 留下來（沉澱，然後檢查）"],
    a=[("① 實作 + 首輪測試", ["相關既有測試跑綠", "加基本手動驗證", "不可帶紅燈進 commit"], GREEN),
       ("② commit（第一次）", ["保留簡化前的還原點", "被 gate 擋下時這一步",
                             "可用 SKIP_DOC_CHECK=1"], AMBER)],
    anote=("測兩次，目的不同", ["步驟 1 證明「做出來是對的」",
                             "步驟 5 證明「整理沒把對的改壞」",
                             "兩者缺一不可，不能互相取代"]),
    b=[("③ code-simplifier", ["只動本段新增/修改的碼", "官方 agent，管可讀性",
                             "不順手重構其他地方"], VIOLET),
       ("④ code-review", ["本段 diff 全量跑", "管正確性與合規",
                          "Critical / Important 修掉才續行"], BLUE),
       ("⑤ 再測一次", ["重跑步驟 1 的相關測試", "後端 curl 打真實 API",
                     "前端 playwright 開瀏覽器"], GREEN),
       ("⑥ commit（最終版）", ["gate 必須全過", "不可用 SKIP 繞過",
                             "缺文件由 AI 自己補齊"], AMBER)],
    bfoot="③④ 之後一定要回到 ⑤：簡化與修 review 都動了程式碼，沒重驗過就不算數 · 驗證不過就修完重跑 ⑤，不可帶紅燈進 ⑥",
    c=[("⑦ 沉澱本輪所學（有才做）", ["踩雷、指令、慣例",
                                "用 /revise-claude-md 寫進 CLAUDE.md",
                                "沒有值得留的就跳過"], GOLD_DIM),
       ("⑧ 評分 & 修正", ["先算範圍：只審本輪動過的",
                        "improver 審那幾份，不全 repo 掃",
                        "驗得出來的錯直接修，不問"], BLUE)],
    cnote=("步驟 7、8 的分工", ["7 是「加」— 把本輪學到的寫進去",
                            "8 是「整理」— 檢查那幾份寫得對不對",
                            "7 跳過不代表 8 跳過：gate 逼出來的改動也要審"]),
    legend=[("主流程", GOLD, False), ("⑤ 驗證不過 → 修完重跑 ⑤", ROSE, True),
            ("下一個功能段落 → 回到 ①", GOLD_DIM, True)],
    foot="Style 8 · Dark Luxury · claude-dd 8 步開發迴圈 · 依全域 CLAUDE.md §3.9 繪製",
)

EN = dict(
    title="claude-dd 8-step development loop",
    sub="every feature increment runs this once · 1–6 always; 7 only if you learned something; 8 whenever a CLAUDE.md changed",
    groups=["A · Build it (prove it is right)",
            "B · Clean it up (prove cleanup didn't break it)",
            "C · Keep it (capture, then check)"],
    a=[("① Implement + first tests", ["existing related tests go green", "plus a basic manual check",
                                      "never enter a commit with a red light"], GREEN),
       ("② commit (first one)", ["a restore point before simplification", "this is the step where",
                                 "SKIP_DOC_CHECK=1 is allowed"], AMBER)],
    anote=("Two test rounds, two purposes", ['step 1 proves "what you built is right"',
                                             'step 5 proves "cleanup didn\'t break it"',
                                             "neither substitutes for the other"]),
    b=[("③ code-simplifier", ["only this increment's new/changed code", "official agent, owns readability",
                              "no drive-by refactors elsewhere"], VIOLET),
       ("④ code-review", ["this increment's diff, run in full", "owns correctness and compliance",
                          "fix Critical / Important before moving on"], BLUE),
       ("⑤ Re-verify", ["rerun the tests from step 1", "backend: curl the real API",
                        "frontend: drive a real browser"], GREEN),
       ("⑥ commit (final)", ["the gate must pass cleanly", "SKIP_DOC_CHECK is not allowed here",
                             "missing docs get written by the AI"], AMBER)],
    bfoot="Always come back to ⑤ after ③④: both of them touched the code, and untested code does not count · if it fails, fix and rerun ⑤ — never enter ⑥ with a red light",
    c=[("⑦ Capture the learnings (if any)", ["gotchas, commands, conventions",
                                             "/revise-claude-md folds them in",
                                             "nothing worth keeping? skip it"], GOLD_DIM),
       ("⑧ Score & fix", ["first compute the scope",
                          "improver audits only those files",
                          "objective errors get fixed, no asking"], BLUE)],
    cnote=("How steps 7 and 8 divide the work", ["7 adds — this round's learnings go in",
                                                 "8 checks — are those files written correctly",
                                                 "skipping 7 does not skip 8: gate-forced edits count too"]),
    legend=[("main flow", GOLD, False), ("⑤ fails → fix, then rerun ⑤", ROSE, True),
            ("next feature increment → back to ①", GOLD_DIM, True)],
    foot="Style 8 · Dark Luxury · claude-dd 8-step development loop · drawn from global CLAUDE.md §3.9",
)

BW, BHX = 268, 108
XS = [112, 412, 712, 1012]
GA = (100, 164, 1240, 196)
GB = (100, 416, 1240, 220)
GC = (100, 692, 1240, 196)
YA, YB, YC = 214, 466, 742


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def box(x, y, name, lines, color):
    o = [f'  <g><rect x="{x}" y="{y}" width="{BW}" height="{BHX}" rx="6" fill="{SURF}" '
         f'stroke="{color}" stroke-width="1.5"/>\n',
         f'    <text x="{x+16}" y="{y+27}" class="nm" fill="{color}">{esc(name)}</text>\n']
    for i, ln in enumerate(lines):
        o.append(f'    <text x="{x+16}" y="{y+52+i*20}" class="sm">{esc(ln)}</text>\n')
    o.append('  </g>\n')
    return "".join(o)


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
    ca, cb, cc = YA + BHX / 2, YB + BHX / 2, YC + BHX / 2
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 1080" width="1440" height="1080">\n']
    o.append(f'''<style>
  text {{ font-family: {SANS}; }}
  .ttl {{ font-family: {SERIF}; font-size: 40px; font-weight: 700; fill: {T1}; }}
  .sub {{ font-size: 13px; fill: {T2}; }}
  .grp {{ font-family: {SERIF}; font-size: 16px; font-weight: 700; fill: {GOLD_DIM}; }}
  .nm  {{ font-size: 15px; font-weight: 600; }}
  .sm  {{ font-size: 11.5px; fill: {T2}; }}
  .xs  {{ font-size: 10.5px; fill: {T3}; }}
  .nh  {{ font-size: 12.5px; fill: {T2}; }}
  .nb  {{ font-size: 11px; fill: {T3}; }}
  .lg  {{ font-size: 11px; fill: {T2}; }}
  .ft  {{ font-size: 10.5px; fill: {T3}; }}
</style>
<defs>
  <radialGradient id="glow" cx="46%" cy="48%" r="44%">
    <stop offset="0%" stop-color="{GOLD}" stop-opacity="0.045"/>
    <stop offset="100%" stop-color="{GOLD}" stop-opacity="0"/></radialGradient>
  <marker id="ag" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0,10 3.5,0 7" fill="{GOLD}"/></marker>
  <marker id="ad" markerWidth="9" markerHeight="6.5" refX="8" refY="3.25" orient="auto">
    <polygon points="0 0,9 3.25,0 6.5" fill="{GOLD_DIM}"/></marker>
  <marker id="ar" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto">
    <polygon points="0 0,8 3,0 6" fill="{ROSE}"/></marker>
''')
    paths = {
        "p12": f"M {XS[0]+BW} {ca} H {XS[1]-12}",
        "p23": f"M {XS[1]+BW/2} {YA+BHX} V 388 H {XS[0]+BW/2} V {YB-12}",
        "p34": f"M {XS[0]+BW} {cb} H {XS[1]-12}",
        "p45": f"M {XS[1]+BW} {cb} H {XS[2]-12}",
        "p56": f"M {XS[2]+BW} {cb} H {XS[3]-12}",
        "p67": f"M {XS[3]+BW/2} {YB+BHX} V 664 H {XS[0]+BW/2} V {YC-12}",
        "back": f"M {XS[2]+BW-40} {YB+BHX} V 604 H {XS[2]+40} V {YB+BHX+12}",
        "p78": f"M {XS[0]+BW} {cc} H {XS[1]-12}",
        "next": f"M {XS[1]+BW/2} {YC+BHX} V 878 H 60 V {ca} H {XS[0]-12}",
    }
    for k, d in paths.items():
        o.append(f'  <path id="{k}" d="{d}" fill="none"/>\n')
    o.append('</defs>\n')
    o.append(f'<rect width="1440" height="1080" fill="{BG}"/>\n<rect width="1440" height="1080" fill="url(#glow)"/>\n')
    o.append(f'<text x="100" y="92" class="ttl">{esc(L["title"])}</text>\n')
    o.append(f'<text x="100" y="132" class="sub">{esc(L["sub"])}</text>\n')

    for (cx, cy, cw, ch), lbl in zip((GA, GB, GC), L["groups"]):
        o.append(f'<rect x="{cx}" y="{cy}" width="{cw}" height="{ch}" rx="8" fill="none" stroke="{GOLD}" '
                 f'stroke-width="0.5" stroke-dasharray="6,4" opacity="0.4"/>\n')
        o.append(f'<text x="{cx+24}" y="{cy+28}" class="grp">{esc(lbl)}</text>\n')

    for k in ("p12", "p23", "p34", "p45", "p56", "p67", "p78"):
        o.append(f'  <use href="#{k}" stroke="{GOLD}" stroke-width="1.6" opacity="0.32" fill="none" '
                 f'marker-end="url(#ag)"/>\n')
    o.append(f'  <use href="#back" stroke="{ROSE}" stroke-width="1.4" stroke-dasharray="6,4" opacity="0.34" '
             f'fill="none" marker-end="url(#ar)"/>\n')
    o.append(f'  <use href="#next" stroke="{GOLD_DIM}" stroke-width="1.4" stroke-dasharray="6,4" opacity="0.45" '
             f'fill="none" marker-end="url(#ad)"/>\n')

    for (n, ls, c), x in zip(L["a"], XS):
        o.append(box(x, YA, n, ls, c))
    for (n, ls, c), x in zip(L["b"], XS):
        o.append(box(x, YB, n, ls, c))
    for (n, ls, c), x in zip(L["c"], XS):
        o.append(box(x, YC, n, ls, c))

    o.append(note(748, YA + 30, *L["anote"]))
    o.append(note(748, YC + 30, *L["cnote"]))
    o.append(f'<text x="124" y="{GB[1]+GB[3]-14}" class="xs">{esc(L["bfoot"])}</text>\n')

    o.append(ball("p12", GOLD, 3.6, -0.0))
    o.append(ball("p23", GOLD, 7.2, -0.9))
    o.append(ball("p34", GOLD, 3.6, -1.8))
    o.append(ball("p45", GOLD, 3.6, -2.4))
    o.append(ball("p56", GOLD, 3.6, -3.0))
    o.append(ball("p67", GOLD, 7.2, -4.5))
    o.append(ball("p78", GOLD, 3.6, -3.6))
    o.append(ball("back", ROSE, 7.2, -2.1))
    o.append(ball("next", GOLD_DIM, 7.2, -6.0))

    lx = 100
    for text, col, dash in L["legend"]:
        da = ' stroke-dasharray="6,4"' if dash else ''
        mk = 'url(#ar)' if col == ROSE else ('url(#ad)' if col == GOLD_DIM else 'url(#ag)')
        o.append(f'<line x1="{lx}" y1="952" x2="{lx+56}" y2="952" stroke="{col}" stroke-width="2"{da} '
                 f'marker-end="{mk}"/>\n')
        o.append(f'<text x="{lx+70}" y="956" class="lg">{esc(text)}</text>\n')
        lx += 400
    o.append(f'<text x="100" y="1000" class="ft">{esc(L["foot"])}</text>\n</svg>\n')
    return "".join(o)


for lang, L in (("zh-TW", ZH), ("en", EN)):
    svg = build(L)
    io.open(f"loop-{lang}.svg", "w", encoding="utf-8").write(svg)
    io.open(f"loop-{lang}.html", "w", encoding="utf-8").write(
        '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;'
        'overflow:hidden;background:#0a0a0a}svg{display:block}</style>' + svg)
    print("wrote loop-" + lang)
