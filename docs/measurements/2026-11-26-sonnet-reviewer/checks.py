# S5 的補充檢查（S4 是審查後才補在 s4-outputs/extra_checks.py，這次跑之前就寫好）：
#   read  —— 每個讀者（父 session 與每個審查者）用 Read 讀 diff 檔，實際回傳的行號聯集缺了幾行；另記用 Bash 碰 diff 檔幾次（那種讀法這裡算不到行號）
#   order —— 父 session 最後一則文字晚於所有審查者結束（中間那層先交報告的情況 S1 碰過）
#   res   —— 所有層的工具結果裡，換掉 s5 工作目錄與該發自己的 projects 目錄後，還剩哪些 /Users/ 路徑
#   cross —— 所有層的工具輸入有沒有碰到別發的快照、別發的 prompt、logs/
# 加 --dump <目錄> 會把父 session 最後的報告（父 log 最後一筆有文字的 result）存成 <發代號>.d0.parent.md
# 用法：python3 -I checks.py <s5 工作目錄> <發代號>... [--dump <目錄>]
import glob, json, os, re, sys, collections
from datetime import datetime

def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()

def rows(path):
    for ln in open(path, errors="ignore"):
        try: yield json.loads(ln)
        except ValueError: pass

def items(path, kind):
    for o in rows(path):
        c = (o.get("message") or {}).get("content")
        if isinstance(c, list):
            for b in c:
                if isinstance(b, dict) and b.get("type") == kind: yield b

def text(b):
    t = b.get("content"); return t if isinstance(t, str) else json.dumps(t, ensure_ascii=False)

args = sys.argv[1:]
dump = None
if "--dump" in args:
    i = args.index("--dump"); dump = args[i + 1]; del args[i:i + 2]
s5 = args[0]; s5p = os.path.realpath(s5)
for run in args[1:]:
    g = run.split("-")[0]
    total = sum(1 for _ in open(os.path.join(s5, g, "diff.txt")))
    pdir = os.path.expanduser("~/.claude/projects/") + re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(os.path.join(s5, run)))
    parents = glob.glob(pdir + "/*.jsonl"); subs = sorted(glob.glob(pdir + "/*/subagents/agent-*.jsonl"))
    reads = []
    for j in parents + subs:
        who = "parent" if j in parents else os.path.basename(j)[6:12]
        want = {b["id"] for b in items(j, "tool_use") if b["name"] == "Read" and "diff.txt" in b["input"].get("file_path", "")}
        bash = sum(1 for b in items(j, "tool_use") if b["name"] == "Bash" and "diff.txt" in b["input"].get("command", ""))
        got = set()
        for b in items(j, "tool_result"):
            if b.get("tool_use_id") in want: got |= {int(x) for x in re.findall(r"(?m)^\s*(\d+)\t", text(b))}
        miss = total - len(got & set(range(1, total + 1)))
        reads.append(f"{who} Read{len(want)}次 缺{miss}/{total}行 Bash碰{bash}次")
    # order：父 session 最後一則 assistant 文字的時間 vs 每個審查者最後一個時間戳
    last_txt = max((ts(o["timestamp"]) for p in parents for o in rows(p) if o.get("type") == "assistant" and o.get("timestamp")
                    and any(isinstance(b, dict) and b.get("type") == "text" and b.get("text", "").strip()
                            for b in (o.get("message") or {}).get("content") or [] if isinstance(b, dict))), default=0)
    rev_end = max((ts(o["timestamp"]) for j in subs for o in rows(j) if o.get("timestamp")), default=0)
    order = "ok" if last_txt > rev_end > 0 else f"父報告 {last_txt:.0f} 不晚於審查者結束 {rev_end:.0f}"
    res = collections.Counter(); cross = []
    others = [r for r in os.listdir(s5) if re.fullmatch(r"G\d-\w+-\d", r) and r != run]
    for f in parents + subs:
        for b in items(f, "tool_result"):
            t = text(b).replace(s5p, "<S5>").replace(s5, "<S5>").replace(pdir, "<OWN>")
            for m in re.finditer(r"/Users/[^\s\"'`:)\]\\]*", t): res[m.group()[:60]] += 1
        for b in items(f, "tool_use"):
            i = json.dumps(b["input"], ensure_ascii=False).replace(s5p, "<S5>").replace(s5, "<S5>")
            bad = [o for o in others if f"<S5>/{o}" in i or f"prompts/{o}." in i] + (["logs/"] if "<S5>/logs" in i else [])
            if bad: cross.append(bad)
    if dump:
        os.makedirs(dump, exist_ok=True)
        rs = [o.get("result", "") for o in rows(os.path.join(s5, "logs", run + ".jsonl")) if o.get("type") == "result"]
        rs = [r for r in rs if r and r.strip()]
        open(os.path.join(dump, f"{run}.d0.parent.md"), "w").write(rs[-1] if rs else "")
    print(run, "read:", reads, "order:", order, "res:", dict(res), "cross:", cross)
