# 產生每一發的快照 repo、diff 檔與 prompt 檔（乙部分的快照與 diff 檔做法照 ../2026-10-24-s5-inputs/prepare.py）。
# 用法：python3 -I prepare.py <claude-dd repo> <工作目錄> <發代號>...
# 發代號：<素材>-<臂>-<序>。素材 P = 甲部分（計畫審查，快照 23429eb）；G2、G3 = 乙部分（步驟 4 的兩段舊 diff）。臂 med／low。
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
BRIEFS = os.path.join(HERE, "..", "2026-10-24-s4-inputs", "briefs.txt")  # 範圍說明跟 2026-10-24 那兩次逐字共用
READ1 = "先用 Read 讀完 {SELF}，它就是你的完整任務說明，照裡面做。"
PLAN_REV = "23429eb"   # 甲：2026-11-14 那份計畫送審時的 HEAD
RANGES = {"G2": ("b1d28bd", "40b3f0a"), "G3": ("96e930e", "720f1b3")}
EFFORT = {"med": "medium", "low": "low"}

def sh(*a, cwd=None, inp=None):
    return subprocess.run(a, cwd=cwd, input=inp, capture_output=True, check=True).stdout

def sections(path):
    out, cur = {}, None
    for ln in open(path, encoding="utf-8"):
        m = re.match(r"### (\S+)\n", ln)
        if m: cur = m.group(1); out[cur] = ""
        elif cur: out[cur] += ln
    return {k: v.strip() + "\n" for k, v in out.items()}

def put_tree(repo, rev, snap, drop_reviews):
    # 清掉工作目錄（留 .git），放進 rev 的樹。乙：拿掉 docs/reviews/ 底下除了 CLAUDE.md 以外的檔（跟 2026-10-24 一樣）
    for name in os.listdir(snap):
        if name != ".git": subprocess.run(["rm", "-rf", os.path.join(snap, name)], check=True)
    sh("tar", "-x", "-C", snap, inp=sh("git", "-C", repo, "archive", rev))
    if not drop_reviews: return
    rv = os.path.join(snap, "docs", "reviews")
    for root, _, files in os.walk(rv):
        for f in files:
            if os.path.relpath(os.path.join(root, f), rv) != "CLAUDE.md":
                os.remove(os.path.join(root, f))

def make_snapshot(repo, revs, snap, drop_reviews):
    os.makedirs(snap)
    sh("git", "init", "-q", snap)
    for rev, msg in zip(revs, ("base", "change")):
        put_tree(repo, rev, snap, drop_reviews)
        sh("git", "-C", snap, "add", "-A")
        sh("git", "-C", snap, "-c", "user.name=exp", "-c", "user.email=exp@example.invalid",
           "commit", "-q", "--no-verify", "-m", msg)
    n = len(sh("git", "-C", snap, "log", "--oneline").splitlines())
    assert n == len(revs), f"{snap} 有 {n} 個 commit"

def changed(snap):
    return [n for n in sh("git", "-C", snap, "-c", "core.quotePath=false", "diff", "--name-only", "--diff-filter=d",
                          "HEAD~1", "HEAD").decode().split("\n") if n]

def make_diff(snap, out):
    d = sh("git", "-C", snap, "-c", "core.quotePath=false", "diff", "HEAD~1", "HEAD").decode()
    parts = ["===== 第一段：git diff HEAD~1 HEAD =====\n", d, "\n===== 第二段：被改到檔案的整檔內容（HEAD 版，帶行號） =====\n"]
    for n in changed(snap):
        body = sh("git", "-C", snap, "show", f"HEAD:{n}").decode()
        parts.append(f"\n----- {n} -----\n")
        parts += [f"{i:5d}\t{l}\n" for i, l in enumerate(body.split("\n"), 1)]
    open(out, "w", encoding="utf-8").write("".join(parts))

def split3(names):
    # 照 git diff --name-only 的順序平均切三份（除不盡時前面的多一個），不看已知錯誤在哪個檔
    k, m = divmod(len(names), 3)
    out, i = [], 0
    for j in range(3):
        n = k + (1 if j < m else 0)
        out.append(names[i:i + n]); i += n
    assert i == len(names) and all(out), f"切不出三份：{names}"
    return out

def fill(body, rep, tag):
    for k, v in rep.items(): body = body.replace(k, v)
    left = re.findall(r"\{[A-Z0-9]+\}", body)
    assert not left, f"{tag} 還有沒換掉的佔位：{left}"
    return body

def write(path, s):
    open(path, "w", encoding="utf-8").write(s)

def main():
    repo, w = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    P = os.path.join(w, "prompts")
    os.makedirs(P, exist_ok=True)
    os.makedirs(os.path.join(w, "logs"), exist_ok=True)
    for run in sys.argv[3:]:
        g, arm, _ = run.split("-")
        snap = os.path.join(w, run)
        eff = EFFORT[arm]
        if g == "P":
            make_snapshot(repo, (PLAN_REV,), snap, False)
            judge = os.path.join(P, run + ".judge.txt")
            # 裁決者範本裡的 {輪次}、《…》是原 prompt 的字面內容，不是這裡的佔位，所以不用 fill()
            body = open(os.path.join(HERE, "judge.txt"), encoding="utf-8").read()
            assert body.count("{ROOT}") == 1 and body.count("{EFFORT}") == 1
            body = body.replace("{ROOT}", snap).replace("{EFFORT}", eff)
            write(judge, body)
            parent = fill(open(os.path.join(HERE, "parent-a.txt"), encoding="utf-8").read(),
                          {"{JUDGE}": judge, "{LINES}": str(body.count("\n"))}, run)
        else:
            make_snapshot(repo, RANGES[g], snap, True)
            gdir = os.path.join(w, g)
            os.makedirs(gdir, exist_ok=True)
            diff = os.path.join(gdir, "diff.txt")
            if not os.path.exists(diff): make_diff(snap, diff)
            lines = sum(1 for _ in open(diff, encoding="utf-8"))
            brief = sections(BRIEFS)[g].rstrip()
            tmpl = open(os.path.join(HERE, "reviewer-b.txt"), encoding="utf-8").read()
            rep = {"{EFFORT}": eff}
            for i, files in enumerate(split3(changed(snap)), 1):
                self_ = os.path.join(P, f"{run}.R{i}.txt")
                write(self_, fill(tmpl, {"{NAME}": f"R{i}", "{SNAP}": snap, "{DIFF}": diff, "{SELF}": self_, "{WORK}": w,
                                         "{LINES}": str(lines), "{FOCUS}": "\n".join("- " + f for f in files), "{BRIEF}": brief}, run))
                rep[f"{{R{i}}}"] = self_
            parent = fill(open(os.path.join(HERE, "parent-b.txt"), encoding="utf-8").read(), rep, run)
        write(os.path.join(P, run + ".parent.txt"), parent)
        print(run, snap)

main()
