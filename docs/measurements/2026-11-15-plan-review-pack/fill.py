#!/usr/bin/env python3
"""從 skills/plan-review/SKILL.md 的裁決者範本填出這次實驗要送的裁決者 prompt（不手改 judge.txt）。

用法：
  python3 -I fill.py check <claude-dd repo>
      拿 b1935bb 的範本照「貼」的填法填 2026-11-14 那份素材，跟 ../2026-11-15-reviewer-effort/judge.txt 逐位元組比。
      相同才代表下面的 make 填的是範本、不是我另外寫的 prompt。
  python3 -I fill.py make <claude-dd repo> <工作目錄> pack|paste <發代號>…
      先用 ../2026-11-15-reviewer-effort/prepare.py 建好快照。讀 repo 工作目錄現在這份 SKILL.md。
      pack：寫審查包 prompts/<發代號>.pack.md，照 SKILL.md 第 2 步換兩處：計畫與事實那一段換成讀檔指示，
            「派審查者」的「《計畫與事實》貼上面兩組標記之間的內容（連標記一起）」換成「貼那一段讀檔指示」
            （P-med-4、P-med-5 那一版只換第一處，範本裡另有一條條件句；那一版的 fill.py 在 2cf7aba）
      paste：照舊貼在標記之間
      兩種都重寫 prompts/<發代號>.judge.txt 與 .parent.txt

主對話填的東西（跟 2026-11-14 那次、與 reviewer-effort 實驗相同）：輪次 1、範圍「整份計畫」、根目錄是那一發的快照、
派審查者那句加上 effort（實驗才加的，為了讓強度有紀錄可查）。計畫與事實從 judge.txt 的標記之間切出來。
"""
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OLD = os.path.join(HERE, "..", "2026-11-15-reviewer-effort")
EFFORT_FROM = 'model "haiku"。'
EFFORT_TO = 'model "haiku"、effort "{EFFORT}"（每個審查者都要帶這個 effort 參數，重派、補派的也一樣）。'
END = "<<<審查包結束>>>"
HALF = "《計畫與事實》貼上面兩組標記之間的內容（連標記一起）"   # 範本「派審查者」裡要換掉的半句
EFFORT = {"med": "medium", "low": "low"}

def read(p): return open(p, encoding="utf-8").read()
def write(p, s): open(p, "w", encoding="utf-8").write(s)

def template(skill):
    """裁決者範本：「## 裁決者範本」之後第一組四個反引號圍欄之間。"""
    s = skill[skill.index("## 裁決者範本"):]
    a = s.index("````\n") + len("````\n")
    return s[a:s.index("\n````", a)] + "\n"

def material(judge):
    """計畫與事實：judge.txt 兩組標記之間的內容（不含標記）。"""
    def cut(a, b):
        i = judge.index(a + "\n") + len(a) + 1
        return judge[i:judge.index("\n" + b, i)]
    return cut("<<<計畫開始>>>", "<<<計畫結束>>>"), cut("<<<事實開始>>>", "<<<事實結束>>>")

def fill_common(t):
    for k, v in (("{輪次}", "1"), ("{範圍}", "整份計畫"), ("{絕對路徑}", "{ROOT}")):
        assert k in t, f"範本裡沒有 {k}"
        t = t.replace(k, v)
    assert t.count(EFFORT_FROM) == 1, "派審查者那一句不是剛好一處"
    return t.replace(EFFORT_FROM, EFFORT_TO)

def block(t):
    """範本裡 <<<計畫開始>>> 到 <<<事實結束>>> 那一整段的起訖。"""
    return t.index("<<<計畫開始>>>"), t.index("<<<事實結束>>>") + len("<<<事實結束>>>")

def paste(t, plan, facts):
    a, b = block(t)
    lines = t[a:b].split("\n")   # 標記、{計畫…}、標記、空行、標記、{事實…}、標記
    assert len(lines) == 7 and lines[1].startswith("{") and lines[5].startswith("{"), lines
    lines[1], lines[5] = plan, facts
    return t[:a] + "\n".join(lines) + t[b:]

def pack_sentence(skill, path, n):
    """SKILL.md 第 2 步那一句讀檔指示（整份檔裡以「材料在這個檔：」開頭的只能有一行）。"""
    hit = [l for l in skill.split("\n") if l.startswith("材料在這個檔：")]
    assert len(hit) == 1, f"「材料在這個檔：」開頭的行有 {len(hit)} 行"
    out = hit[0].replace("{審查包路徑}", path).replace("{N}", str(n))
    assert "{" not in out, out
    return out

def half_sentence(skill):
    """SKILL.md 第 2 步的第二處：換上去的那半句（整份檔裡這樣開頭的只能有一行）。"""
    hit = [l for l in skill.split("\n") if l.startswith("《計畫與事實》貼上面「材料在這個檔：」")]
    assert len(hit) == 1, f"第二處的替換句有 {len(hit)} 行"
    return hit[0]

def check(repo):
    old = subprocess.run(["git", "-C", repo, "show", "b1935bb:skills/plan-review/SKILL.md"], capture_output=True, check=True).stdout.decode()
    judge = read(os.path.join(OLD, "judge.txt"))
    got = paste(fill_common(template(old)), *material(judge))
    if got == judge:
        print(f"相同：{len(judge.encode())} 位元組、{judge.count(chr(10))} 行"); return 0
    g, j = got.split("\n"), judge.split("\n")
    print(f"不同：填出來 {len(g)} 行、judge.txt {len(j)} 行")
    for i, (x, y) in enumerate(zip(g, j), 1):
        if x != y: print(f"第 {i} 行\n  填出來：{x[:200]}\n  judge.txt：{y[:200]}")
    return 1

def make(repo, w, mode, runs):
    assert mode in ("pack", "paste"), mode
    skill = read(os.path.join(repo, "skills", "plan-review", "SKILL.md"))
    plan, facts = material(read(os.path.join(OLD, "judge.txt")))
    P = os.path.join(w, "prompts")
    for run in runs:
        snap = os.path.join(w, run)
        assert os.path.isdir(snap), f"沒有快照 {snap}：先跑 reviewer-effort/prepare.py"
        t = fill_common(template(skill))
        if mode == "pack":
            pk = os.path.join(P, run + ".pack.md")
            body = f"審查範圍：整份計畫\n\n<<<計畫開始>>>\n{plan}\n<<<計畫結束>>>\n\n<<<事實開始>>>\n{facts}\n<<<事實結束>>>\n{END}\n"
            write(pk, body)
            a, b = block(t)
            t = t[:a] + pack_sentence(skill, pk, body.count("\n")) + t[b:]
            assert t.count(HALF) == 1, f"範本裡要換掉的半句有 {t.count(HALF)} 處"
            t = t.replace(HALF, half_sentence(skill))
        else:
            t = paste(t, plan, facts)
        assert t.count("{ROOT}") == 1 and t.count("{EFFORT}") == 1
        t = t.replace("{ROOT}", snap).replace("{EFFORT}", EFFORT[run.split("-")[1]])
        judge = os.path.join(P, run + ".judge.txt")
        write(judge, t)
        parent = read(os.path.join(OLD, "parent-a.txt")).replace("{JUDGE}", judge).replace("{LINES}", str(t.count("\n")))
        assert not re.search(r"\{[A-Z]+\}", parent), parent
        write(os.path.join(P, run + ".parent.txt"), parent)
        print(run, mode, "裁決者 prompt", len(t), "字元", t.count("\n"), "行")

if sys.argv[1] == "check": sys.exit(check(os.path.abspath(sys.argv[2])))
elif sys.argv[1] == "make": make(os.path.abspath(sys.argv[2]), os.path.abspath(sys.argv[3]), sys.argv[4], sys.argv[5:])
else: sys.exit(__doc__)
