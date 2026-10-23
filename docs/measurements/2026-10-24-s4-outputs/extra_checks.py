# S4 步驟 4 審查後補的三道檢查（stats.py 是凍結的輸入，不改它；補在這裡）：
#   read  —— 每個審查者用 Read 讀 diff 檔：請求到第幾行、實際回到第幾行（配對 tool_use 與 tool_result）
#   res   —— 所有層的工具結果裡，換掉 s4 工作目錄與該發自己的 projects 目錄後，還剩哪些 /Users/ 路徑
#   cross —— 所有層的工具輸入有沒有碰到別發的快照、別發的 prompt、logs/；舊組有沒有碰 diff 檔
# 用法：python3 -I extra_checks.py <s4 工作目錄> <發代號>...
import glob, json, os, re, sys, collections

def items(path, kind):
    for ln in open(path, errors="ignore"):
        try: o = json.loads(ln)
        except ValueError: continue
        c = (o.get("message") or {}).get("content")
        if isinstance(c, list):
            for b in c:
                if isinstance(b, dict) and b.get("type") == kind: yield b

def text(b):
    t = b.get("content"); return t if isinstance(t, str) else json.dumps(t, ensure_ascii=False)

s4 = sys.argv[1]; s4p = os.path.realpath(s4); runs = sys.argv[2:]
for run in runs:
    g, grp, _ = run.split("-")
    total = sum(1 for _ in open(os.path.join(s4, g, "diff.txt")))
    pdir = os.path.expanduser("~/.claude/projects/") + re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(os.path.join(s4, run)))
    subs = sorted(glob.glob(pdir + "/*/subagents/agent-*.jsonl")); files = glob.glob(pdir + "/*.jsonl") + subs
    reads = []
    for j in subs:
        if grp != "old" and json.load(open(j.replace(".jsonl", ".meta.json"))).get("spawnDepth") != 2: continue
        req = {}
        for b in items(j, "tool_use"):
            i = b["input"]
            if b["name"] == "Read" and "diff.txt" in i.get("file_path", ""):
                req[b["id"]] = min(total, (i.get("offset") or 1) + (i.get("limit") or 2000) - 1)
        got = {b["tool_use_id"]: max([int(x) for x in re.findall(r"(?m)^\s*(\d+)\t", text(b))] or [0])
               for b in items(j, "tool_result") if b.get("tool_use_id") in req}
        reads.append(f"{os.path.basename(j)[6:12]} 請求{max(req.values(), default=0)}/實得{min(total, max(got.values(), default=0))}")
    res = collections.Counter()
    cross = []
    others = [r for r in os.listdir(s4) if re.fullmatch(r"G\d-\w+-\d", r) and r != run]
    for f in files:
        for b in items(f, "tool_result"):
            t = text(b).replace(s4p, "<S4>").replace(s4, "<S4>").replace(pdir, "<OWN>")
            for m in re.finditer(r"/Users/[^\s\"'`:)\]\\]*", t): res[m.group()[:60]] += 1
        for b in items(f, "tool_use"):
            i = json.dumps(b["input"], ensure_ascii=False).replace(s4p, "<S4>").replace(s4, "<S4>")
            bad = [o for o in others if f"<S4>/{o}" in i or f"prompts/{o}." in i] + (["logs/"] if "<S4>/logs" in i else [])
            if grp == "old" and "diff.txt" in i: bad.append("diff.txt")
            if bad: cross.append(bad)
    print(run, "read:", reads, "res:", dict(res), "cross:", cross)
