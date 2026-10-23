# 產生 S4 每一發的快照 repo、diff 檔與 prompt 檔。
# 用法：python3 -I prepare.py <claude-dd repo> <s4 工作目錄> <發代號>...
# 發代號：G2-new-1、G3-old-2、G2-hk-1、G4-new-1 這種（段-組-序）
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
RANGES = {"G2": ("639bde7", "b66d8ae"), "G3": ("08b2576", "8514fb2"), "G4": ("48de43f~1", "48de43f")}

def sh(*a, cwd=None, inp=None):
    return subprocess.run(a, cwd=cwd, input=inp, capture_output=True, check=True).stdout

def sections(path):
    # 「### 名稱」切成 dict
    out, cur = {}, None
    for ln in open(os.path.join(HERE, path), encoding="utf-8"):
        m = re.match(r"### (\S+)\n", ln)
        if m: cur = m.group(1); out[cur] = ""
        elif cur: out[cur] += ln
    return {k: v.strip() + "\n" for k, v in out.items()}

def put_tree(repo, rev, snap):
    # 清掉工作目錄（留 .git），放進 rev 的樹，拿掉 docs/reviews/ 底下除了 CLAUDE.md 以外的檔
    for name in os.listdir(snap):
        if name != ".git": subprocess.run(["rm", "-rf", os.path.join(snap, name)], check=True)
    tar = sh("git", "-C", repo, "archive", rev)
    sh("tar", "-x", "-C", snap, inp=tar)
    rv = os.path.join(snap, "docs", "reviews")
    for root, _, files in os.walk(rv):
        for f in files:
            if os.path.relpath(os.path.join(root, f), rv) != "CLAUDE.md":
                os.remove(os.path.join(root, f))

def make_snapshot(repo, base, end, snap):
    os.makedirs(snap)
    sh("git", "init", "-q", snap)
    for rev, msg in ((base, "base"), (end, "change")):
        put_tree(repo, rev, snap)
        sh("git", "-C", snap, "add", "-A")
        sh("git", "-C", snap, "-c", "user.name=s4", "-c", "user.email=s4@example.invalid",
           "commit", "-q", "--no-verify", "-m", msg)
    n = len(sh("git", "-C", snap, "log", "--oneline").splitlines())
    assert n == 2, f"{snap} 有 {n} 個 commit"

def make_diff(snap, out):
    d = sh("git", "-C", snap, "-c", "core.quotePath=false", "diff", "HEAD~1", "HEAD").decode()
    names = sh("git", "-C", snap, "-c", "core.quotePath=false", "diff", "--name-only", "--diff-filter=d",
               "HEAD~1", "HEAD").decode().split("\n")
    parts = ["===== 第一段：git diff HEAD~1 HEAD =====\n", d, "\n===== 第二段：被改到檔案的整檔內容（HEAD 版，帶行號） =====\n"]
    for n in filter(None, names):
        body = sh("git", "-C", snap, "show", f"HEAD:{n}").decode()
        parts.append(f"\n----- {n} -----\n")
        parts += [f"{i:5d}\t{l}\n" for i, l in enumerate(body.split("\n"), 1)]
    open(out, "w", encoding="utf-8").write("".join(parts))

def main():
    repo, s4 = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    briefs, parents = sections("briefs.txt"), sections("parent.txt")
    judge = open(os.path.join(HERE, "judge.txt"), encoding="utf-8").read()
    old = open(os.path.join(HERE, "old-reviewer.txt"), encoding="utf-8").read()
    os.makedirs(os.path.join(s4, "prompts"), exist_ok=True)
    os.makedirs(os.path.join(s4, "logs"), exist_ok=True)
    for run in sys.argv[3:]:
        g, grp, _ = run.split("-")
        snap = os.path.join(s4, run)
        make_snapshot(repo, *RANGES[g], snap)
        gdir = os.path.join(s4, g)
        os.makedirs(gdir, exist_ok=True)
        diff = os.path.join(gdir, "diff.txt")
        if not os.path.exists(diff): make_diff(snap, diff)
        self_ = os.path.join(s4, "prompts", run + ".txt")
        rep = {"{SNAP}": snap, "{DIFF}": diff, "{SELF}": self_, "{S4}": s4, "{BRIEF}": briefs[g].rstrip()}
        if grp == "old":
            body = old
        else:
            rep["{REVIEWER}"] = ('`subagent_type: "code-reviewer"`，不帶 model 參數' if grp == "new"
                                 else '`subagent_type: "code-reviewer"`、`model: "haiku"`')
            body = judge
        for k, v in rep.items(): body = body.replace(k, v)
        left = [k for k in ("{SNAP}", "{DIFF}", "{SELF}", "{S4}", "{BRIEF}", "{REVIEWER}") if k in body]
        assert not left, f"{run} 還有沒換掉的佔位：{left}"
        open(self_, "w", encoding="utf-8").write(body)
        par = parents["old" if grp == "old" else "new"].replace("{RUN}", run).replace("{SELF}", self_)
        open(os.path.join(s4, "prompts", run + ".parent.txt"), "w", encoding="utf-8").write(par)
        print(run, snap)

main()
