# -*- coding: utf-8 -*-
"""claude-dd 使用流程圖 — Style 8 Dark Luxury，1440x1080，總循環 7.2s"""
import io

SERIF = "Georgia,'Times New Roman','Songti TC','Noto Serif CJK TC',serif"
SANS = "-apple-system,'Helvetica Neue','PingFang TC','Noto Sans CJK TC',sans-serif"

BG, SURF = "#0a0a0a", "#111111"
GOLD, GOLD_DIM = "#d4a574", "#c9a96e"
T1, T2, T3 = "#f5f0eb", "#a39787", "#6b5f53"
GREEN, VIOLET, BLUE, ROSE, AMBER = "#5a9e6f", "#a78bfa", "#38bdf8", "#f87171", "#fbbf24"
MINT = "#6ee7b7"

ZH = dict(
    title="claude-dd 使用流程",
    sub="從零到日常 · 裝一次、每個專案蓋章一次、之後每個功能段落走同一個迴圈",
    steps=["STEP 1 · 首次安裝（一次性）",
           "STEP 2 · 專案初始化（每個專案一次）",
           "STEP 3 · 日常開發（每個功能段落）"],
    boxes=[
        ("① git clone", "取得 repo（source of truth）", "github.com/kopp0510/claude-dd", GREEN),
        ("② ./install-dd-pipeline.sh", "安裝 7 個步驟，部署到 ~/.claude/",
         "skills · agents · MCP · plugin · commands · 全域 CLAUDE.md", AMBER),
        ("③ cd 你的專案", "任何 git 專案，新舊皆可", "現有專案會先派 agent 分析技術棧", BLUE),
        ("④ /dd-init", "蓋章 8 步迴圈到專案 CLAUDE.md",
         "掛 pre-commit gate · 建 .screenshots/ · 檢查 plugin 依賴", VIOLET),
        ("⑤ 8 步開發迴圈", "實作+測試 → commit → 簡化 → 審查",
         "→ 再測（curl/playwright）→ commit → 沉澱 → 評分", GREEN),
        ("⑥ pre-commit gate", "改碼目錄 CLAUDE.md 未同批更新",
         "→ 擋下 commit，訊息內含 AI 自主修復指令", ROSE),
        ("⑦ 換機器 / 新電腦", "clone + 一支腳本，整套工作法回來",
         "這就是「可攜」的意思 — 回到 ①", GOLD_DIM),
    ],
    notes=[
        ("全域 CLAUDE.md 走互動比對", ["已有自己的規則時可先看 diff", "再決定要不要覆蓋"]),
        ("已有 ## 開發流程 區塊時", ["列出與現行版差異並詢問", "是否升級，保留在地內容"]),
        ("gate 的逃生口", ["檢查點 commit（步驟 2）：", "SKIP_DOC_CHECK=1 git commit",
                          "最終 commit（步驟 6）必須全過"]),
    ],
    legend=[("主流程", GOLD, False), ("gate 擋下 → 修完重試", ROSE, True),
            ("可攜：換機器重建 → 回到 ①", MINT, False)],
    foot="Style 8 · Dark Luxury · claude-dd 使用流程 · 依 README 安裝章節與 dd-init 實際 Phase 繪製",
)

EN = dict(
    title="claude-dd usage flow",
    sub="From zero to daily use · install once, stamp each project once, then every feature increment runs the same loop",
    steps=["STEP 1 · First-time install (once)",
           "STEP 2 · Project setup (once per project)",
           "STEP 3 · Daily development (every increment)"],
    boxes=[
        ("① git clone", "get the repo (source of truth)", "github.com/kopp0510/claude-dd", GREEN),
        ("② ./install-dd-pipeline.sh", "7 install steps, deploys into ~/.claude/",
         "skills · agents · MCP · plugin · commands · CLAUDE.md", AMBER),
        ("③ cd your-project", "any git project, new or existing",
         "existing ones get an agent to analyse the stack", BLUE),
        ("④ /dd-init", "stamps the 8-step loop into CLAUDE.md",
         "hooks the gate · creates .screenshots/ · checks plugins", VIOLET),
        ("⑤ 8-step development loop", "implement + test → commit → simplify → review",
         "→ re-verify (curl/playwright) → commit → capture → score", GREEN),
        ("⑥ pre-commit gate", "code dir CLAUDE.md not updated in same batch",
         "→ commit blocked; message tells the AI how to fix it", ROSE),
        ("⑦ New machine", "clone + one script, the whole method is back",
         'that is what "portable" means — back to ①', GOLD_DIM),
    ],
    notes=[
        ("global CLAUDE.md: interactive diff", ["already have your own rules? see the diff",
                                                "then decide whether to overwrite"]),
        ("if a workflow section already exists", ["differences are listed and you are asked",
                                                  "local content is preserved"]),
        ("gate escape hatch", ["checkpoint commit (step 2):", "SKIP_DOC_CHECK=1 git commit",
                               "final commit (step 6) must pass cleanly"]),
    ],
    legend=[("main flow", GOLD, False), ("gate blocks → fix → retry", ROSE, True),
            ("portable: rebuild on a new machine → back to ①", MINT, False)],
    foot="Style 8 · Dark Luxury · claude-dd usage flow · drawn from the README install section and dd-init's actual phases",
)

# ── 版面座標 ──
BW, BH = 340, 78
COL_L, COL_R = 208, 628
GRP = [(180, 168, 860, 162), (180, 378, 860, 162), (180, 588, 860, 186)]
ROWS = [204, 414, 624]           # ①③⑤ 與 ②④⑥ 的 y
Y7 = 822                          # ⑦
NOTE_X = 1080
NOTE_Y = [227, 437, 635]


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def box(x, y, name, l1, l2, color):
    return f'''  <g>
    <rect x="{x}" y="{y}" width="{BW}" height="{BH}" rx="6" fill="{SURF}" stroke="{color}" stroke-width="1.5"/>
    <text x="{x+18}" y="{y+25}" class="nm" fill="{color}">{esc(name)}</text>
    <text x="{x+18}" y="{y+47}" class="sm">{esc(l1)}</text>
    <text x="{x+18}" y="{y+65}" class="xs">{esc(l2)}</text>
  </g>
'''


def ball(pid, color, dur, begin):
    return (f'  <circle r="8" fill="{color}" opacity="0.22">'
            f'<animateMotion dur="{dur}s" begin="{begin}s" repeatCount="indefinite">'
            f'<mpath href="#{pid}"/></animateMotion></circle>\n'
            f'  <circle r="4" fill="{color}">'
            f'<animateMotion dur="{dur}s" begin="{begin}s" repeatCount="indefinite">'
            f'<mpath href="#{pid}"/></animateMotion></circle>\n')


def build(L):
    o = []
    o.append(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
             f'viewBox="0 0 1440 1080" width="1440" height="1080">\n')
    o.append(f'''<style>
  text {{ font-family: {SANS}; }}
  .ttl {{ font-family: {SERIF}; font-size: 40px; font-weight: 700; fill: {T1}; }}
  .sub {{ font-size: 13px; fill: {T2}; }}
  .grp {{ font-family: {SERIF}; font-size: 16px; font-weight: 700; fill: {GOLD_DIM}; }}
  .nm  {{ font-size: 15px; font-weight: 600; }}
  .sm  {{ font-size: 12px; fill: {T2}; }}
  .xs  {{ font-size: 10.5px; fill: {T3}; }}
  .nh  {{ font-size: 12px; fill: {T2}; }}
  .nb  {{ font-size: 11px; fill: {T3}; }}
  .lg  {{ font-size: 11px; fill: {T2}; }}
  .ft  {{ font-size: 10.5px; fill: {T3}; }}
</style>
<defs>
  <radialGradient id="glow" cx="50%" cy="46%" r="42%">
    <stop offset="0%" stop-color="{GOLD}" stop-opacity="0.045"/>
    <stop offset="100%" stop-color="{GOLD}" stop-opacity="0"/>
  </radialGradient>
  <marker id="ag" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0,10 3.5,0 7" fill="{GOLD}"/></marker>
  <marker id="am" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0,10 3.5,0 7" fill="{MINT}"/></marker>
  <marker id="ar" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto">
    <polygon points="0 0,8 3,0 6" fill="{ROSE}"/></marker>
  <marker id="ax" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto">
    <polygon points="0 0,8 3,0 6" fill="{T3}"/></marker>
''')
    # 小球路徑（隱形定義）
    y1, y2, y3 = [r + BH / 2 for r in ROWS]
    paths = {
        "p12": f"M {COL_L+BW} {y1} H {COL_R-12}",
        "p23": f"M {COL_R+BW/2} {ROWS[0]+BH} V 352 H {COL_L+BW/2} V {ROWS[1]-12}",
        "p34": f"M {COL_L+BW} {y2} H {COL_R-12}",
        "p45": f"M {COL_R+BW/2} {ROWS[1]+BH} V 562 H {COL_L+BW/2} V {ROWS[2]-12}",
        "p56": f"M {COL_L+BW} {y3} H {COL_R-12}",
        "p65": f"M {COL_R+BW/2} {ROWS[2]+BH} V 790 H {COL_L+BW/2} V {ROWS[2]+BH+12}",
        "p67": f"M {COL_R+BW*0.75} {ROWS[2]+BH} V {Y7-12}",
        "p71": f"M {COL_R} {Y7+BH/2} H 140 V {y1} H {COL_L-12}",
    }
    for k, d in paths.items():
        o.append(f'  <path id="{k}" d="{d}" fill="none"/>\n')
    o.append('</defs>\n')
    o.append(f'<rect width="1440" height="1080" fill="{BG}"/>\n')
    o.append('<rect width="1440" height="1080" fill="url(#glow)"/>\n')

    # 標題
    o.append(f'<text x="180" y="90" class="ttl">{esc(L["title"])}</text>\n')
    o.append(f'<text x="180" y="130" class="sub">{esc(L["sub"])}</text>\n')

    # 分組容器
    for (gx, gy, gw, gh), lbl in zip(GRP, L["steps"]):
        o.append(f'<rect x="{gx}" y="{gy}" width="{gw}" height="{gh}" rx="8" fill="none" '
                 f'stroke="{GOLD}" stroke-width="0.5" stroke-dasharray="6,4" opacity="0.4"/>\n')
        o.append(f'<text x="{gx+24}" y="{gy+27}" class="grp">{esc(lbl)}</text>\n')

    # 可見連線（淡）
    style_solid = f'stroke="{GOLD}" stroke-width="1.6" opacity="0.32" fill="none"'
    for k in ("p12", "p23", "p34", "p45", "p56"):
        o.append(f'  <use href="#{k}" {style_solid} marker-end="url(#ag)"/>\n')
    o.append(f'  <use href="#p65" stroke="{ROSE}" stroke-width="1.4" stroke-dasharray="6,4" opacity="0.32" fill="none" marker-end="url(#ar)"/>\n')
    o.append(f'  <use href="#p71" stroke="{MINT}" stroke-width="1.6" opacity="0.34" fill="none" marker-end="url(#am)"/>\n')

    # 節點
    for i, (n, a, b, c) in enumerate(L["boxes"][:6]):
        x = COL_L if i % 2 == 0 else COL_R
        o.append(box(x, ROWS[i // 2], n, a, b, c))
    n, a, b, c = L["boxes"][6]
    o.append(box(COL_R, Y7, n, a, b, c))

    # 右側註解
    for (head, lines), ny in zip(L["notes"], NOTE_Y):
        o.append(f'<text x="{NOTE_X}" y="{ny}" class="nh">{esc(head)}</text>\n')
        for j, ln in enumerate(lines):
            o.append(f'<text x="{NOTE_X}" y="{ny+25+j*19}" class="nb">{esc(ln)}</text>\n')

    # 小球（dur 皆整除 7.2）
    o.append(ball("p12", GOLD, 3.6, -0.6))  # 避開 dur 整數倍，否則跳躍落在循環接點
    o.append(ball("p34", GOLD, 3.6, -1.2))
    o.append(ball("p56", GOLD, 3.6, -2.4))
    o.append(ball("p23", GOLD, 7.2, -0.6))
    o.append(ball("p45", GOLD, 7.2, -3.0))
    o.append(ball("p65", ROSE, 3.6, -1.8))
    o.append(ball("p71", MINT, 7.2, -4.2))

    # legend
    lx = 180
    for text, col, dash in L["legend"]:
        da = ' stroke-dasharray="6,4"' if dash else ''
        mk = 'url(#ax)' if col == T3 else ('url(#ar)' if col == ROSE else
                                           ('url(#am)' if col == MINT else 'url(#ag)'))
        o.append(f'<line x1="{lx}" y1="980" x2="{lx+56}" y2="980" stroke="{col}" '
                 f'stroke-width="2"{da} marker-end="{mk}"/>\n')
        o.append(f'<text x="{lx+70}" y="984" class="lg">{esc(text)}</text>\n')
        lx += 380
    o.append(f'<text x="180" y="1026" class="ft">{esc(L["foot"])}</text>\n')
    o.append('</svg>\n')
    return "".join(o)


for lang, L in (("zh-TW", ZH), ("en", EN)):
    svg = build(L)
    io.open(f"usage-{lang}.svg", "w", encoding="utf-8").write(svg)
    io.open(f"usage-{lang}.html", "w", encoding="utf-8").write(
        '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;'
        'overflow:hidden;background:#0a0a0a}svg{display:block}</style>' + svg)
    print("wrote usage-" + lang)
