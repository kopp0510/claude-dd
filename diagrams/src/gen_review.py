# -*- coding: utf-8 -*-
"""claude-dd 計畫怎麼審（plan-review）— Style 8 Dark Luxury，1440x1080，總循環 7.2s"""
import io

SERIF = "Georgia,'Times New Roman','Songti TC','Noto Serif CJK TC',serif"
SANS = "-apple-system,'Helvetica Neue','PingFang TC','Noto Sans CJK TC',sans-serif"
BG, SURF = "#0a0a0a", "#111111"
GOLD, GOLD_DIM = "#d4a574", "#c9a96e"
T1, T2, T3 = "#f5f0eb", "#a39787", "#6b5f53"
GREEN, AMBER, GRAY = "#5a9e6f", "#fbbf24", "#94a3b8"

# 每一句都對過 skills/plan-review/SKILL.md 的原文（開頭說明、第 1–5 步、裁決者範本）
ZH = dict(
    title="claude-dd 計畫怎麼審（plan-review）",
    sub="複雜工作的計畫交出去之前 · 腦袋全新的裁決者派人猛攻，再逐條查證，只把站得住的批評交回來",
    groups=["主對話", "裁決者（Opus，腦袋全新）· 全程唯讀", "結論"],
    nodes=dict(
        plan=("計畫寫好", ["附查到的事實", "推測要標明是推測"]),
        send=("派 ≥3 個審查者", ["haiku，同一則訊息平行派", "可分工，也可都做全面"]),
        check=("讀檔檢查", ["每人抽一處它引用的行來讀", "對不上就重派"]),
        verify=("逐條查證", ["預設「這條批評可能是錯的」", "採納／駁回／需使用者決定"]),
        ok=("通過 → 開工", ["只問「需使用者決定」的題", "不再問「計畫可以嗎」"]),
        fail=("不通過 → 改計畫", ["照採納的重大缺失逐條改", "改好的全文再送一輪"]),
        stop=("第 3 輪還不過 → 停下", ["改好計畫後停下回報", "你選確認輪／繼續／停下"]),
        none=("無法判定／沒跑成", ["照實告訴你", "問要重跑還是不審直接交"]),
    ),
    retry="重派", short="有效審查者不足 3 個", again="再送一輪（最多 3 輪）", third="已是第 3 輪",
    notes=[("什麼時候跑", ["複雜任務的計畫交出去之前", "task-planner 的草稿出好之後",
                         "design-brainstorm 的設計（不論大小）", "簡單、中等任務不跑"]),
           ("什麼算重大", ["三個條件都符合才算：", "常走的路、照做會錯、", "後面的關卡也抓不到"])],
    legend=[("主流程", GOLD, False), ("再送一輪：改好的計畫回到開頭", GOLD_DIM, True),
            ("重派：讀檔檢查沒過的審查者", GRAY, True)],
    foot="Style 8 · Dark Luxury · claude-dd 計畫怎麼審 · 依 skills/plan-review/SKILL.md 繪製",
)

EN = dict(
    title="claude-dd: how a plan gets reviewed",
    sub="before a complex plan goes out · a fresh adjudicator sends reviewers to attack it, then checks every criticism and keeps only what holds",
    groups=["Main session", "Adjudicator (Opus, fresh context) · read-only", "Verdict"],
    nodes=dict(
        plan=("Plan written", ["with the facts found", "guesses marked as guesses"]),
        send=("Send 3+ reviewers", ["haiku, all in one message", "split angles or all-round"]),
        check=("Read-the-file check", ["one cited line per reviewer", "mismatch: send again"]),
        verify=("Check each criticism", ["assume it may be wrong", "adopt / reject / ask the user"]),
        ok=("Pass → start work", ["asks only user-decision items", "never \"is this plan OK?\""]),
        fail=("Fail → revise the plan", ["fix each adopted major issue", "send the full plan again"]),
        stop=("Round 3 fails → stop", ["revise, then stop and report", "you pick: confirm / go on / stop"]),
        none=("Undecided / didn't run", ["you are told plainly", "rerun, or hand over unreviewed"]),
    ),
    retry="again", short="under 3 valid reviewers", again="next round (max 3)", third="already round 3",
    notes=[("When it runs", ["a complex task's plan, before it goes out", "a task-planner draft, once it's ready",
                             "a design-brainstorm design (any size)", "not for simple or medium tasks"]),
           ("What counts as major", ["all three must hold:", "a common path, doing it goes wrong,",
                                     "and later gates won't catch it"])],
    legend=[("main flow", GOLD, False), ("next round: the revised plan starts over", GOLD_DIM, True),
            ("send again: a reviewer failed the check", GRAY, True)],
    foot="Style 8 · Dark Luxury · claude-dd: how a plan gets reviewed · drawn from skills/plan-review/SKILL.md",
)

# ── 版面座標 ──
BW, BH = 250, 100
XS = [100, 430, 760, 1090]
YS = [186, 386, 626, 806]
# 三個分組，每個節點都要在某個容器裡：verify-geometry.py 把容器外的節點記成未通過
GROUPS = [(76, 140, 298, 170), (76, 346, 958, 180), (406, 586, 958, 340)]
# 強調色只給兩個焦點（通過、不通過），例外出口用灰，其餘同一個金色
PLACE = dict(plan=(0, 0, GOLD_DIM), send=(0, 1, GOLD_DIM), check=(1, 1, GOLD_DIM), verify=(2, 1, GOLD_DIM),
             none=(1, 2, GRAY), ok=(2, 2, GREEN), fail=(3, 2, AMBER), stop=(3, 3, GRAY))


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def poly(*pts):
    # 正交折線只用 M/L 絕對座標：verify-geometry.py 不認 H/V 簡寫
    return "M " + " L ".join(f"{x:g} {y:g}" for x, y in pts)


def text_width(s, size):
    # 與 verify-geometry.py 同一套估法：CJK 1em，其餘 0.55em
    return sum(size if ord(c) > 0x2E80 else size * 0.55 for c in s)


def box(x, y, name, lines, color):
    # 節點文字的字級只寫在 font-size 屬性、CSS 的 .nm/.sm 不設 —— 只寫一邊，人才不會改錯邊。
    # 2026-09-12 起 verify-geometry.py 的取值順序與瀏覽器一致（<style> > font-size 屬性 > 內建表），
    # 所以「只改 CSS 檢查仍照舊數字估」已經不成立了；照舊表猜而誤報溢出的問題也一併沒了
    o = [f'  <g><rect data-role="node" x="{x}" y="{y}" width="{BW}" height="{BH}" rx="6" fill="{SURF}" '
         f'stroke="{color}" stroke-width="1.5"/>\n',
         f'    <text x="{x+16}" y="{y+28}" class="nm" font-size="15" fill="{color}">{esc(name)}</text>\n']
    for i, ln in enumerate(lines):
        o.append(f'    <text x="{x+16}" y="{y+54+i*21}" class="sm" font-size="11.5">{esc(ln)}</text>\n')
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
  <marker id="ay" markerWidth="9" markerHeight="6.5" refX="8" refY="3.25" orient="auto">
    <polygon points="0 0,9 3.25,0 6.5" fill="{GRAY}"/></marker>
''')
    o.append('</defs>\n')
    o.append(f'<rect width="1440" height="1080" fill="{BG}"/>\n<rect width="1440" height="1080" fill="url(#glow)"/>\n')
    o.append(f'<text x="100" y="86" class="ttl">{esc(L["title"])}</text>\n')
    o.append(f'<text x="100" y="122" class="sub">{esc(L["sub"])}</text>\n')

    # 分組標題靠右：計畫往下、讀檔檢查往下的連線都從容器左半邊進出，標題靠左會壓在線上
    for (gx, gy, gw, gh), lbl in zip(GROUPS, L["groups"]):
        o.append(f'<rect data-role="container" x="{gx}" y="{gy}" width="{gw}" height="{gh}" rx="8" fill="none" '
                 f'stroke="{GOLD}" stroke-width="0.5" stroke-dasharray="6,4" opacity="0.4"/>\n')
        o.append(f'<text x="{gx+gw-24}" y="{gy+26}" class="grp" text-anchor="end">{esc(lbl)}</text>\n')

    # 連線從來源框邊出發、停在目標框前 12px 留給箭頭；畫在 <defs> 外並標 data-role="edge"，
    # 小球的 <mpath> 直接指向它（放進 defs 用 <use> 引用的話，幾何檢查數到的連線是 0）
    c0, c1, c2, c3 = [y + BH // 2 for y in YS]
    mid = [x + BW // 2 for x in XS]
    paths = {
        "start":  poly((mid[0], YS[0]+BH), (mid[0], YS[1]-12)),
        # 派出去與重派共用同一個 80px 間隙，上下錯開 30px 各用自己的 port
        "send":   poly((XS[0]+BW, c1-15), (XS[1]-12, c1-15)),
        "retry":  poly((XS[1], c1+15), (XS[0]+BW+12, c1+15)),
        "verify": poly((XS[1]+BW, c1), (XS[2]-12, c1)),
        "short":  poly((mid[1], YS[1]+BH), (mid[1], YS[2]-12)),
        "ok":     poly((mid[2], YS[1]+BH), (mid[2], YS[2]-12)),
        "fail":   poly((XS[2]+BW, c1), (mid[3], c1), (mid[3], YS[2]-12)),
        "third":  poly((mid[3], YS[2]+BH), (mid[3], YS[3]-12)),
        # 再送一輪：從「不通過」右邊出去，沿結論容器外側往上，再沿第一列上方回到計畫
        "again":  poly((XS[3]+BW, c2), (1390, c2), (1390, c0), (XS[0]+BW+12, c0)),
    }
    def edge(k, style):
        return f'  <path id="{k}" data-role="edge" d="{paths[k]}" fill="none" {style}/>\n'
    for k in ("start", "send", "verify", "short", "ok", "fail", "third"):
        o.append(edge(k, f'stroke="{GOLD}" stroke-width="1.6" opacity="0.32" marker-end="url(#ag)"'))
    o.append(edge("retry", f'stroke="{GRAY}" stroke-width="1.4" stroke-dasharray="6,4" opacity="0.45" '
                           f'marker-end="url(#ay)"'))
    o.append(edge("again", f'stroke="{GOLD_DIM}" stroke-width="1.4" stroke-dasharray="6,4" opacity="0.45" '
                           f'marker-end="url(#ad)"'))

    for key, (col, row, color) in PLACE.items():
        name, lines = L["nodes"][key]
        o.append(box(XS[col], YS[row], name, lines, color))

    o.append(note(XS[0], YS[2]+14, *L["notes"][0]))
    o.append(note(XS[0], YS[3]+4, *L["notes"][1]))

    # 邊標籤在節點之後畫：先畫的話會被節點蓋掉
    o.append(label((XS[0]+BW+XS[1]) // 2, c1+40, L["retry"], "middle"))
    o.append(label(mid[1]+14, YS[2]-56, L["short"], "start"))
    o.append(label(mid[3]+14, YS[3]-22, L["third"], "start"))
    o.append(label((XS[1]+XS[2]) // 2, c0-12, L["again"], "middle"))

    # dur 大致與路徑長成正比（68px→1.44、88px→1.8、128px→2.4），全部整除 7.2；
    # 兩條長路徑用 7.2，最長的那條放兩顆、錯開半週期；begin 避開 dur 的整數倍
    o.append(ball("start", GOLD, 1.8, -0.6))
    o.append(ball("send", GOLD, 1.44, -1.0))
    o.append(ball("retry", GRAY, 1.44, -0.5))
    o.append(ball("verify", GOLD, 1.44, -0.9))
    o.append(ball("short", GRAY, 2.4, -1.3))
    o.append(ball("ok", GOLD, 2.4, -0.7))
    o.append(ball("fail", GOLD, 7.2, -2.5))
    o.append(ball("third", GOLD, 1.2, -0.4))
    o.append(ball("again", GOLD_DIM, 7.2, -0.3))
    o.append(ball("again", GOLD_DIM, 7.2, -3.9))

    lx = 100
    for text, col, dash in L["legend"]:
        da = ' stroke-dasharray="6,4"' if dash else ''
        mk = 'url(#ay)' if col == GRAY else ('url(#ad)' if col == GOLD_DIM else 'url(#ag)')
        o.append(f'<line x1="{lx}" y1="946" x2="{lx+56}" y2="946" stroke="{col}" stroke-width="2"{da} '
                 f'marker-end="{mk}"/>\n')
        o.append(f'<text x="{lx+70}" y="950" class="lg">{esc(text)}</text>\n')
        lx += 400
    o.append(f'<text x="100" y="992" class="ft">{esc(L["foot"])}</text>\n</svg>\n')
    return "".join(o)


for lang, L in (("zh-TW", ZH), ("en", EN)):
    svg = build(L)
    io.open(f"review-{lang}.svg", "w", encoding="utf-8").write(svg)
    io.open(f"review-{lang}.html", "w", encoding="utf-8").write(
        '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;'
        'overflow:hidden;background:#0a0a0a}svg{display:block}</style>' + svg)
    print("wrote review-" + lang)
