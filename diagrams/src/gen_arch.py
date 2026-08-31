# -*- coding: utf-8 -*-
"""claude-dd 三層架構圖 — Style 8 Dark Luxury，1440x1080，總循環 7.2s"""
import io

SERIF = "Georgia,'Times New Roman','Songti TC','Noto Serif CJK TC',serif"
SANS = "-apple-system,'Helvetica Neue','PingFang TC','Noto Sans CJK TC',sans-serif"
BG, SURF = "#0a0a0a", "#111111"
GOLD, GOLD_DIM = "#d4a574", "#c9a96e"
T1, T2, T3 = "#f5f0eb", "#a39787", "#6b5f53"
GREEN, VIOLET, BLUE, ROSE, AMBER, GRAY = "#5a9e6f", "#a78bfa", "#38bdf8", "#f87171", "#fbbf24", "#94a3b8"

ZH = dict(
    title="claude-dd 三層架構",
    sub="source of truth → 部署目標 → 各專案 · 單向流動，修改一律回到最上層",
    layers=["L1 · claude-dd repo（source of truth，git 版控）",
            "L2 · ~/.claude/（部署目標，可隨時由 repo 重建）",
            "L3 · 各專案（逐專案蓋章，內容依專案偵測結果客製）"],
    l1=[("skills/", "10 個（每個含 SKILL.md）", "2 個 vendored，附上游授權", GREEN),
        ("agents/", "4 個 · code-simplifier", "code-reviewer / devops / secops", VIOLET),
        ("commands/", "dd-init（平面）", "workflow-review（命名空間）", AMBER),
        ("templates/global/", "全域 CLAUDE.md 模板", "零幻覺 · 8 步迴圈 · skill 觸發", BLUE),
        ("scripts/", "check-claude-md.sh", "githooks/（本 repo 自用）", ROSE)],
    l1foot="install-dd-pipeline.sh（安裝腳本，唯一路線）· 部署清單定義於頂部 PROMOTED_* 陣列 · CI 驗陣列↔目錄↔文件數字一致",
    l2=[("skills/ · agents/", "10 + 4，內容相同報「已是最新」", "複製而非 symlink", GREEN),
        ("commands/", "/dd-init · /review", "任何專案都叫得到", AMBER),
        ("CLAUDE.md", "全域規則（互動比對安裝）", "每個 session 載入", BLUE),
        ("scripts/ · settings.json", "gate 本體 · plugin 設定", "JSON 就地改寫保留 inode", ROSE),
        ("backups/", "pre-install-<時間>/", "覆蓋差異檔前自動備份", GRAY)],
    l2foot="冪等：重跑內容相同不重寫、不產生備份 · 非互動環境（CI | curl | bash）互動詢問一律採預設值",
    l3=[("專案 CLAUDE.md", "8 步迴圈 + 專案專屬驗證指令", "巢狀，每個含程式碼的目錄一份", BLUE),
        (".git/hooks/pre-commit", "CLAUDE.md gate（block 版）", "未同批更新即擋 commit", ROSE),
        (".screenshots/", "迴圈步驟 5 的 playwright 存證", "gitignore，不進版控", AMBER)],
    l3note=("由 /dd-init 建立：", ["偵測技術棧 → 填入具體驗證指令", "已有區塊則詢問是否升級"]),
    legend=[("部署（單向、可重建）", GOLD, False),
            ("變更來源（直接改 ~/.claude 下次會被覆蓋）", VIOLET, True)],
    foot="Style 8 · Dark Luxury · claude-dd 三層架構 · 依 DD_PIPELINE_ARCHITECTURE.md 與現行腳本繪製",
)

EN = dict(
    title="claude-dd architecture",
    sub="source of truth → deploy target → your projects · one-way flow; every change goes back to the top layer",
    layers=["L1 · claude-dd repo (source of truth, under git)",
            "L2 · ~/.claude/ (deploy target, rebuildable from the repo at any time)",
            "L3 · your projects (stamped per project, tailored to what is detected)"],
    l1=[("skills/", "10, each with a SKILL.md", "2 vendored, license included", GREEN),
        ("agents/", "4 · code-simplifier", "code-reviewer / devops / secops", VIOLET),
        ("commands/", "dd-init (flat)", "workflow-review (namespace)", AMBER),
        ("templates/global/", "global CLAUDE.md template", "zero-hallucination · 8-step loop", BLUE),
        ("scripts/", "check-claude-md.sh", "githooks/ (this repo only)", ROSE)],
    l1foot="install-dd-pipeline.sh (the only install path) · deploy list lives in the PROMOTED_* arrays at the top · CI verifies arrays ↔ directories ↔ doc counts",
    l2=[("skills/ · agents/", '10 + 4; identical → "up to date"', "copied, not symlinked", GREEN),
        ("commands/", "/dd-init · /review", "callable from any project", AMBER),
        ("CLAUDE.md", "global rules (interactive diff)", "loaded every session", BLUE),
        ("scripts/ · settings.json", "the gate itself · plugin config", "JSON edited in place", ROSE),
        ("backups/", "pre-install-<timestamp>/", "auto-backup before overwrite", GRAY)],
    l2foot="Idempotent: rerunning with identical content rewrites nothing and creates no backup · in non-interactive environments (CI | curl | bash) every prompt takes its default",
    l3=[("project CLAUDE.md", "8-step loop + project-specific verify commands", "nested — one per directory containing code", BLUE),
        (".git/hooks/pre-commit", "CLAUDE.md gate (blocking)", "not updated in the same batch → blocked", ROSE),
        (".screenshots/", "playwright evidence from loop step 5", "gitignored, not under version control", AMBER)],
    l3note=("created by /dd-init:", ["detects the stack → fills in real commands",
                                     "asks before upgrading an existing block"]),
    legend=[("deploy (one-way, rebuildable)", GOLD, False),
            ("source of change (editing ~/.claude directly gets overwritten)", VIOLET, True)],
    foot="Style 8 · Dark Luxury · claude-dd architecture · drawn from DD_PIPELINE_ARCHITECTURE.md and the current script",
)

CONT = [(100, 172, 1240, 200), (100, 464, 1240, 200), (100, 756, 1240, 192)]
BW5, BH5 = 212, 78
X5 = [128, 372, 616, 860, 1104]
BW3 = 292
X3 = [128, 446, 764]
YB = [228, 520, 812]


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def box(x, y, w, name, l1, l2, color):
    return (f'  <g><rect x="{x}" y="{y}" width="{w}" height="{BH5}" rx="6" fill="{SURF}" '
            f'stroke="{color}" stroke-width="1.5"/>\n'
            f'    <text x="{x+16}" y="{y+25}" class="nm" fill="{color}">{esc(name)}</text>\n'
            f'    <text x="{x+16}" y="{y+47}" class="sm">{esc(l1)}</text>\n'
            f'    <text x="{x+16}" y="{y+65}" class="xs">{esc(l2)}</text></g>\n')


def ball(pid, color, dur, begin):
    return (f'  <circle r="8" fill="{color}" opacity="0.22"><animateMotion dur="{dur}s" '
            f'begin="{begin}s" repeatCount="indefinite"><mpath href="#{pid}"/></animateMotion></circle>\n'
            f'  <circle r="4" fill="{color}"><animateMotion dur="{dur}s" begin="{begin}s" '
            f'repeatCount="indefinite"><mpath href="#{pid}"/></animateMotion></circle>\n')


def build(L):
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 1080" width="1440" height="1080">\n']
    o.append(f'''<style>
  text {{ font-family: {SANS}; }}
  .ttl {{ font-family: {SERIF}; font-size: 40px; font-weight: 700; fill: {T1}; }}
  .sub {{ font-size: 13px; fill: {T2}; }}
  .grp {{ font-family: {SERIF}; font-size: 16px; font-weight: 700; fill: {GOLD_DIM}; }}
  .nm  {{ font-size: 14px; font-weight: 600; }}
  .sm  {{ font-size: 11px; fill: {T2}; }}
  .xs  {{ font-size: 10px; fill: {T3}; }}
  .nh  {{ font-size: 12px; fill: {T2}; }}
  .nb  {{ font-size: 11px; fill: {T3}; }}
  .lg  {{ font-size: 11px; fill: {T2}; }}
  .ft  {{ font-size: 10.5px; fill: {T3}; }}
</style>
<defs>
  <radialGradient id="glow" cx="50%" cy="50%" r="44%">
    <stop offset="0%" stop-color="{GOLD}" stop-opacity="0.045"/>
    <stop offset="100%" stop-color="{GOLD}" stop-opacity="0"/></radialGradient>
  <marker id="ag" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
    <polygon points="0 0,10 3.5,0 7" fill="{GOLD}"/></marker>
  <marker id="av" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto">
    <polygon points="0 0,8 3,0 6" fill="{VIOLET}"/></marker>
''')
    paths = {}
    for i, x in enumerate((234, 720, 1206)):
        paths[f"d1{i}"] = f"M {x} 372 V 452"
        paths[f"d2{i}"] = f"M {x} 664 V 744"
    paths["chg"] = "M 1380 830 V 286 H 1348"
    for k, d in paths.items():
        o.append(f'  <path id="{k}" d="{d}" fill="none"/>\n')
    o.append('</defs>\n')
    o.append(f'<rect width="1440" height="1080" fill="{BG}"/>\n<rect width="1440" height="1080" fill="url(#glow)"/>\n')
    o.append(f'<text x="100" y="92" class="ttl">{esc(L["title"])}</text>\n')
    o.append(f'<text x="100" y="132" class="sub">{esc(L["sub"])}</text>\n')

    for (cx, cy, cw, ch), lbl in zip(CONT, L["layers"]):
        o.append(f'<rect x="{cx}" y="{cy}" width="{cw}" height="{ch}" rx="8" fill="none" stroke="{GOLD}" '
                 f'stroke-width="0.5" stroke-dasharray="6,4" opacity="0.4"/>\n')
        o.append(f'<text x="{cx+24}" y="{cy+28}" class="grp">{esc(lbl)}</text>\n')

    for k in paths:
        if k.startswith("d"):
            o.append(f'  <use href="#{k}" stroke="{GOLD}" stroke-width="1.6" opacity="0.32" '
                     f'fill="none" marker-end="url(#ag)"/>\n')
    o.append(f'  <use href="#chg" stroke="{VIOLET}" stroke-width="1.3" stroke-dasharray="6,3" '
             f'opacity="0.42" fill="none" marker-end="url(#av)"/>\n')

    for (n, a, b, c), x in zip(L["l1"], X5):
        o.append(box(x, YB[0], BW5, n, a, b, c))
    for (n, a, b, c), x in zip(L["l2"], X5):
        o.append(box(x, YB[1], BW5, n, a, b, c))
    for (n, a, b, c), x in zip(L["l3"], X3):
        o.append(box(x, YB[2], BW3, n, a, b, c))

    o.append(f'<text x="124" y="345" class="xs">{esc(L["l1foot"])}</text>\n')
    o.append(f'<text x="124" y="637" class="xs">{esc(L["l2foot"])}</text>\n')
    head, lines = L["l3note"]
    o.append(f'<text x="1090" y="838" class="nh">{esc(head)}</text>\n')
    for j, ln in enumerate(lines):
        o.append(f'<text x="1090" y="{862+j*19}" class="nb">{esc(ln)}</text>\n')

    # begin 一律避開 dur 的整數倍，否則球「跑完一圈跳回起點」會剛好落在 GIF 的
    # 循環接點上，每次循環都看得到跳一下（2026-08-31 踩過）
    for i, b in enumerate((-0.6, -2.4, -4.8)):
        o.append(ball(f"d1{i}", GOLD, 3.6, b))
        o.append(ball(f"d2{i}", GOLD, 3.6, b - 1.8))
    o.append(ball("chg", VIOLET, 7.2, -1.8))

    lx = 100
    for text, col, dash in L["legend"]:
        da = ' stroke-dasharray="6,3"' if dash else ''
        mk = 'url(#av)' if dash else 'url(#ag)'
        o.append(f'<line x1="{lx}" y1="996" x2="{lx+56}" y2="996" stroke="{col}" stroke-width="2"{da} '
                 f'marker-end="{mk}"/>\n')
        o.append(f'<text x="{lx+70}" y="1000" class="lg">{esc(text)}</text>\n')
        lx += 330
    o.append(f'<text x="100" y="1040" class="ft">{esc(L["foot"])}</text>\n</svg>\n')
    return "".join(o)


for lang, L in (("zh-TW", ZH), ("en", EN)):
    svg = build(L)
    io.open(f"arch-{lang}.svg", "w", encoding="utf-8").write(svg)
    io.open(f"arch-{lang}.html", "w", encoding="utf-8").write(
        '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;'
        'overflow:hidden;background:#0a0a0a}svg{display:block}</style>' + svg)
    print("wrote arch-" + lang)
