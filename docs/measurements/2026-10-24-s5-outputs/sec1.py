# 每個讀者對 diff 檔「第一段（git diff 本體）」的行號覆蓋：用 Read 回傳的行號算
import glob, json, os, re, sys
def items(p, k):
    for l in open(p, errors="ignore"):
        try: o = json.loads(l)
        except ValueError: continue
        for b in (o.get("message") or {}).get("content") or []:
            if isinstance(b, dict) and b.get("type") == k: yield b
d = sys.argv[1]
for run in sys.argv[2:]:
    g = run.split("-")[0]; L = open(os.path.join(d, g, "diff.txt")).read().split("\n")
    end = next(i for i, x in enumerate(L, 1) if x.startswith("===== 第二段")) - 1
    pdir = os.path.expanduser("~/.claude/projects/") + re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(os.path.join(d, run)))
    out = []
    for j in glob.glob(pdir + "/*.jsonl") + sorted(glob.glob(pdir + "/*/subagents/*.jsonl")):
        if "subagents" in j:
            m = json.load(open(j.replace(".jsonl", ".meta.json")))
            if m.get("agentType") != "code-reviewer": continue
        want = {b["id"] for b in items(j, "tool_use") if b["name"] == "Read" and "diff.txt" in b["input"].get("file_path", "")}
        got = set()
        for b in items(j, "tool_result"):
            if b.get("tool_use_id") in want:
                t = b.get("content"); t = t if isinstance(t, str) else json.dumps(t, ensure_ascii=False)
                got |= {int(x) for x in re.findall(r"(?m)^\s*(\d+)\t", t)}
        miss = end - len(got & set(range(1, end + 1)))
        out.append(("P" if "subagents" not in j else "r") + f"缺{miss}")
    print(run, f"第一段 1–{end}", " ".join(out))
