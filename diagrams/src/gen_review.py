# -*- coding: utf-8 -*-
"""claude-dd 計畫怎麼審（plan-review）— Style 8 Dark Luxury，1440x1080，總循環 7.2s"""
import io

SERIF = "Georgia,'Times New Roman','Songti TC','Noto Serif CJK TC',serif"
SANS = "-apple-system,'Helvetica Neue','PingFang TC','Noto Sans CJK TC',sans-serif"
BG, SURF = "#0a0a0a", "#111111"
GOLD, GOLD_DIM = "#d4a574", "#c9a96e"
T1, T2, T3 = "#f5f0eb", "#a39787", "#6b5f53"
GREEN, AMBER, GRAY = "#5a9e6f", "#fbbf24", "#94a3b8"

# 一排是一個角色（主對話／裁決者／審查者），只畫通過、不通過、第 3 輪還不過這三條路；重派、沒跑成、要你批准寫在「例外」小字。
# 每一句都對過 skills/plan-review/SKILL.md 的原文（開頭說明、第 1–5 步、裁決者範本）
ZH = dict(
    title="claude-dd 計畫怎麼審（plan-review）",
    sub="複雜任務的計畫、task-planner 草稿、design-brainstorm 的設計（不論大小）交出去之前 · 腦袋全新的裁決者派人猛攻，再逐條查證，只把站得住的批評交回來",
    groups=["主對話", "裁決者（Opus，腦袋全新）· 全程唯讀", "審查者（haiku，≥3 個）"],
    nodes=dict(
        plan=("① 計畫寫好", ["附查到的事實，推測要標明是推測"]),
        ok=("⑥ 通過 → 開工", ["先改小事、問你要決定的題"]),
        fail=("⑤ 不通過 → 改計畫", ["照站得住的重大缺失逐條改"]),
        stop=("⑦ 停下來問你", ["你選確認輪／繼續／停下"]),
        send=("② 派 ≥3 個審查者", ["haiku，同一則訊息平行派"]),
        verify=("④ 查證每條批評", ["預設批評可能是錯的，判通不通過"]),
        attack=("③ 各自猛攻計畫", ["只找漏洞，每條批評都附證據（檔案行號或 grep 結果）；互相看不到對方"]),
    ),
    again="再審：新的裁決者（最多 3 輪）", pass_="通過", fail_="不通過", third="第 3 輪還不過", back="附證據回報",
    notes=[("什麼算重大", ["三個條件都符合才算：", "常走的路（金額、權限、刪資料一律算）、",
                         "照做會錯或跳過你的決定、", "後面的關卡也抓不到"]),
           ("例外", ["審查者沒真的讀檔或回錯誤：重派，最多一次",
                   "裁決者回錯誤、報告缺結論或自相矛盾、補派後湊不到 3 個有效審查者、你說不等了：",
                   "審查沒跑成，照實告訴你，問要重跑還是不審直接交",
                   "你的規則寫了要你批准：通過之後照樣先問你"])],
    legend=[("實線：往下一步走（交出去、回報、判完之後）", GOLD, False), ("再審：改好的計畫交給新的裁決者", GOLD_DIM, True)],
    foot="Style 8 · Dark Luxury · claude-dd 計畫怎麼審 · 依 skills/plan-review/SKILL.md 繪製",
)

EN = dict(
    title="claude-dd: how a plan gets reviewed",
    sub="before a complex plan, a task-planner draft or a design-brainstorm design (any size) goes out · a fresh adjudicator has reviewers attack it and keeps only criticism that holds",
    groups=["Main session", "Adjudicator (Opus, fresh context) · read-only", "Reviewers (haiku, 3+)"],
    nodes=dict(
        plan=("① Plan written", ["facts attached, guesses marked"]),
        ok=("⑥ Pass → start work", ["fix minor items, ask your calls"]),
        fail=("⑤ Fail → revise the plan", ["fix each upheld major issue"]),
        stop=("⑦ Stop and ask you", ["you pick: confirm / go on / stop"]),
        send=("② Send 3+ reviewers", ["haiku, all in one message"]),
        verify=("④ Check each criticism", ["assume it may be wrong; pass or fail"]),
        attack=("③ Each attacks the plan", ["holes only; each criticism shows proof (file:line or grep); they can't see each other"]),
    ),
    again="review again: fresh adjudicator (max 3 rounds)", pass_="pass", fail_="fail", third="round 3 fails",
    back="report with proof",
    notes=[("What counts as major", ["all three must hold:", "a common path (money, access, deletes: always),",
                                     "doing it goes wrong or skips your decision,", "and later gates won't catch it"]),
           ("Exceptions", ["a reviewer didn't read the files or errored: resend, once at most",
                           "adjudicator errored, verdict missing or contradictory, under 3 valid",
                           "reviewers, or you stop waiting: the review didn't run; rerun or skip it",
                           "your rules require approval: you're still asked after a pass"])],
    legend=[("solid: on to the next step (hand off, report back, after the verdict)", GOLD, False), ("review again: the revised plan goes to a fresh adjudicator", GOLD_DIM, True)],
    foot="Style 8 · Dark Luxury · claude-dd: how a plan gets reviewed · drawn from skills/plan-review/SKILL.md",
)

# ── 版面座標 ──
BW, BH = 250, 80
XS = [100, 430, 760, 1110]
YS = [196, 380, 620]          # 主對話／裁決者／審查者
WIDE = 580                    # ③ 橫跨前兩欄：② 往下進它左邊、它往上回 ④
# 三個分組＝三個角色，每個節點都要在某個容器裡：verify-geometry.py 把容器外的節點記成未通過
GROUPS = [(76, 140, 1308, 160), (76, 350, 958, 210), (76, 590, 628, 170)]
# 強調色只給兩個焦點（通過、不通過），停下來問你用灰，其餘同一個金色
PLACE = dict(plan=(0, 0, GOLD_DIM), ok=(1, 0, GREEN), fail=(2, 0, AMBER), stop=(3, 0, GRAY),
             send=(0, 1, GOLD_DIM), verify=(1, 1, GOLD_DIM))


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def poly(*pts):
    # 正交折線只用 M/L 絕對座標：verify-geometry.py 不認 H/V 簡寫
    return "M " + " L ".join(f"{x:g} {y:g}" for x, y in pts)


def text_width(s, size):
    # 與 verify-geometry.py 同一套估法：CJK 1em，其餘 0.55em
    return sum(size if ord(c) > 0x2E80 else size * 0.55 for c in s)


def box(x, y, name, lines, color, w=BW):
    # 節點文字的字級只寫在 font-size 屬性、CSS 的 .nm/.sm 不設 —— 只寫一邊，人才不會改錯邊。
    # 2026-09-12 起 verify-geometry.py 的取值順序與瀏覽器一致（<style> > font-size 屬性 > 內建表），
    # 所以「只改 CSS 檢查仍照舊數字估」已經不成立了；照舊表猜而誤報溢出的問題也一併沒了
    o = [f'  <g><rect data-role="node" x="{x}" y="{y}" width="{w}" height="{BH}" rx="6" fill="{SURF}" '
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
''')
    o.append('</defs>\n')
    o.append(f'<rect width="1440" height="1080" fill="{BG}"/>\n<rect width="1440" height="1080" fill="url(#glow)"/>\n')
    o.append(f'<text x="100" y="86" class="ttl">{esc(L["title"])}</text>\n')
    o.append(f'<text x="100" y="122" class="sub">{esc(L["sub"])}</text>\n')

    # 主對話的組名放右上（右上角沒有線）；裁決者、審查者的上緣從左到右都有線穿過（fail 在 x=885、back 在 x=555），組名改放右下
    for i, ((gx, gy, gw, gh), lbl) in enumerate(zip(GROUPS, L["groups"])):
        o.append(f'<rect data-role="container" x="{gx}" y="{gy}" width="{gw}" height="{gh}" rx="8" fill="none" '
                 f'stroke="{GOLD}" stroke-width="0.5" stroke-dasharray="6,4" opacity="0.4"/>\n')
        ty = gy + 26 if i == 0 else gy + gh - 12
        o.append(f'<text x="{gx+gw-24}" y="{ty}" class="grp" text-anchor="end">{esc(lbl)}</text>\n')

    # 連線從來源框邊出發、停在目標框前 12px 留給箭頭；畫在 <defs> 外並標 data-role="edge"，
    # 小球的 <mpath> 直接指向它（放進 defs 用 <use> 引用的話，幾何檢查數到的連線是 0）
    top, mid_y = YS[0] + BH // 2, YS[1] + BH // 2
    mid = [x + BW // 2 for x in XS]
    loop_y = YS[0] - 36
    paths = {
        "start":  poly((mid[0], YS[0]+BH), (mid[0], YS[1]-12)),
        "send":   poly((mid[0], YS[1]+BH), (mid[0], YS[2]-12)),
        "back":   poly((mid[1], YS[2]), (mid[1], YS[1]+BH+12)),
        "pass":   poly((mid[1], YS[1]), (mid[1], YS[0]+BH+12)),
        "fail":   poly((XS[1]+BW, mid_y), (mid[2], mid_y), (mid[2], YS[0]+BH+12)),
        "third":  poly((XS[2]+BW, top), (XS[3]-12, top)),
        # 再審：從「不通過」頂上出去，沿主對話這排上方往左，回到計畫頂上
        "again":  poly((mid[2], YS[0]), (mid[2], loop_y), (mid[0], loop_y), (mid[0], YS[0]-12)),
    }
    def edge(k, style):
        return f'  <path id="{k}" data-role="edge" d="{paths[k]}" fill="none" {style}/>\n'
    for k in ("start", "send", "back", "pass", "fail", "third"):
        o.append(edge(k, f'stroke="{GOLD}" stroke-width="1.6" opacity="0.32" marker-end="url(#ag)"'))
    o.append(edge("again", f'stroke="{GOLD_DIM}" stroke-width="1.4" stroke-dasharray="6,4" opacity="0.45" '
                           f'marker-end="url(#ad)"'))

    for key, (col, row, color) in PLACE.items():
        name, lines = L["nodes"][key]
        o.append(box(XS[col], YS[row], name, lines, color))
    o.append(box(XS[0], YS[2], *L["nodes"]["attack"], GOLD_DIM, w=WIDE))

    o.append(note(XS[0], 806, *L["notes"][0]))
    o.append(note(XS[2], 806, *L["notes"][1]))

    # 邊標籤在節點之後畫：先畫的話會被節點蓋掉
    o.append(label((mid[0]+mid[2]) // 2, loop_y+22, L["again"], "middle"))
    o.append(label(mid[1]+14, (YS[0]+BH+YS[1]) // 2 + 4, L["pass_"], "start"))
    o.append(label((XS[1]+BW+mid[2]) // 2, mid_y-12, L["fail_"], "middle"))
    o.append(label((XS[2]+BW+XS[3]) // 2, top-12, L["third"], "middle"))
    # 回報的標籤放在兩個容器之間的縫：放裁決者容器裡會撞到右下的組名
    o.append(label(mid[1]+14, YS[2]-40, L["back"], "start"))

    # dur 大致與路徑長成正比（88–92px→1.8、148px→2.4、337px→7.2），全部整除 7.2；
    # 「再審」約 720px，dur 最長只能到總循環 7.2，所以這條的球比別條快約一倍，放兩顆、錯開半週期；
    # 球色跟所在的線同色（legend 只講線色）；begin 避開 dur 的整數倍
    o.append(ball("start", GOLD, 1.8, -0.6))
    o.append(ball("send", GOLD, 2.4, -1.0))
    o.append(ball("back", GOLD, 2.4, -0.5))
    o.append(ball("pass", GOLD, 1.8, -0.9))
    o.append(ball("fail", GOLD, 7.2, -2.5))
    o.append(ball("third", GOLD, 1.8, -0.4))
    o.append(ball("again", GOLD_DIM, 7.2, -0.3))
    o.append(ball("again", GOLD_DIM, 7.2, -3.9))

    lx = 100
    for text, col, dash in L["legend"]:
        da = ' stroke-dasharray="6,4"' if dash else ''
        mk = 'url(#ad)' if col == GOLD_DIM else 'url(#ag)'
        o.append(f'<line x1="{lx}" y1="946" x2="{lx+56}" y2="946" stroke="{col}" stroke-width="2"{da} '
                 f'marker-end="{mk}"/>\n')
        o.append(f'<text x="{lx+70}" y="950" class="lg">{esc(text)}</text>\n')
        lx += 560  # 第一項的英文較長，400 會撞到第二項
    o.append(f'<text x="100" y="992" class="ft">{esc(L["foot"])}</text>\n</svg>\n')
    return "".join(o)


for lang, L in (("zh-TW", ZH), ("en", EN)):
    svg = build(L)
    io.open(f"review-{lang}.svg", "w", encoding="utf-8").write(svg)
    io.open(f"review-{lang}.html", "w", encoding="utf-8").write(
        '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;'
        'overflow:hidden;background:#0a0a0a}svg{display:block}</style>' + svg)
    print("wrote review-" + lang)
