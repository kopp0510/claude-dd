# S4 每一發的耗時、工具次數、模型、費用、作廢檢查。
# 用法：python3 -I stats.py <s4 工作目錄> <發代號>...   （加 --dump <目錄> 會把每個 agent 的最後一則文字存成檔）
import glob, json, os, re, sys
from datetime import datetime

def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
def enc(p): return re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(p))

def read_jsonl(p):
    for ln in open(p, errors="ignore"):
        try: yield json.loads(ln)
        except ValueError: pass

def scan(path):
    t, tools, models, inputs, last_text = [], {}, set(), [], ""
    for o in read_jsonl(path):
        if o.get("timestamp"): t.append(ts(o["timestamp"]))
        m = o.get("message") or {}
        if o.get("type") == "assistant":
            if m.get("model"): models.add(m["model"])
            c = m.get("content")
            if isinstance(c, list):
                txt = "".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
                if txt.strip(): last_text = txt
                for b in c:
                    if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("id") not in tools:
                        tools[b["id"]] = b.get("name")
                        inputs.append((b.get("name"), json.dumps(b.get("input"), ensure_ascii=False)))
    if len(t) < 2: raise SystemExit(f"{path} 時間戳不足")
    return {"sec": max(t) - min(t), "tools": len(tools), "models": models, "inputs": inputs, "text": last_text}

LEAK = re.compile(r"/Users/|~/|\$HOME|\$\{HOME\}|\.\./|my_project|\.claude/")
# 從根目錄開始搜的指令（find / 這種）；只查 Bash。不比對裸的「 / 」：echo 字串與 # 註解裡常有（實測誤報 G3-new-2、G3-hk-2）
ROOT_ARG = re.compile(r"\b(find|ls|cd|du|tree)\s+/(\s|$)|\b(grep|rg)\b[^|;&\n]*\s/(\s|$)")

def leaky(s4, name, i, own=""):
    # own = 這一發自己的 projects 目錄（大輸出會落在它的 tool-results/，讀回來不算外流）
    if own: i = i.replace(own, "<OWN>")
    i = i.replace(s4, "<S4>").replace("`~/.claude/projects/`", "").replace("`/Users/`", "")
    hit = LEAK.search(i)
    # `../` 在拋棄式目錄裡（同一個指令有 mktemp 或 /tmp/）是 worktree 實驗的正常寫法，不算往快照外爬
    if hit and not (hit.group() == "../" and re.search(r"mktemp|/tmp/", i)
                    and not LEAK.search(i.replace("../", ""))): return True
    return name == "Bash" and bool(ROOT_ARG.search(json.loads(i).get("command", "")))

def run_stats(s4, run, dump):
    g, grp, _ = run.split("-")
    snap = os.path.join(s4, run)
    pdir = os.path.join(os.path.expanduser("~/.claude/projects"), enc(snap))
    errs = []
    # 父 session 的 stdout：全部 result
    res = [o for o in read_jsonl(os.path.join(s4, "logs", run + ".jsonl")) if o.get("type") == "result"]
    if not res: errs.append("父 log 沒有 result")
    for r in res:
        if r.get("permission_denials"): errs.append(f"permission_denials：{r['permission_denials']}")
    if res and (res[-1].get("is_error") or res[-1].get("subtype") != "success"):
        errs.append(f"最後一筆 result：subtype={res[-1].get('subtype')} is_error={res[-1].get('is_error')}")
    last = res[-1] if res else {}
    # 子代理
    metas = glob.glob(os.path.join(pdir, "*", "subagents", "agent-*.meta.json"))
    agents = []
    for m in metas:
        meta = json.load(open(m)); j = m.replace(".meta.json", ".jsonl")
        if not os.path.exists(j): errs.append(f"找不到 {j}"); continue
        a = scan(j); a["path"] = j; a["meta"] = meta; a["id"] = os.path.basename(m)[6:-10]; agents.append(a)
    d1 = [a for a in agents if a["meta"].get("spawnDepth") == 1]
    d2 = [a for a in agents if a["meta"].get("spawnDepth") == 2]
    def short(ms): return ",".join(sorted(x.replace("claude-", "") for x in ms))
    if grp == "old":
        if len(d1) != 2 or d2: errs.append(f"舊做法要 2 個第 1 層、0 個第 2 層，實際 {len(d1)}／{len(d2)}")
        for a in d1:
            if a["meta"].get("agentType") != "code-reviewer": errs.append("第 1 層不是 code-reviewer")
            if not all("opus" in x for x in a["models"]): errs.append(f"舊審查者模型 {short(a['models'])}")
        judge, revs = None, d1
    else:
        if len(d1) != 1: errs.append(f"第 1 層要 1 個裁決者，實際 {len(d1)}")
        judge = d1[0] if d1 else None
        revs = [a for a in d2 if judge and a["meta"].get("parentAgentId") == judge["id"]]
        if len(revs) != len(d2): errs.append("有第 2 層的 parentAgentId 不是裁決者")
        if len(revs) < 3: errs.append(f"審查者少於 3 個：{len(revs)}")
        if judge and not all("opus" in x for x in judge["models"]): errs.append(f"裁決者模型 {short(judge['models'])}")
        want = "opus" if grp == "new" else "haiku"
        for a in revs:
            if a["meta"].get("agentType") != "code-reviewer": errs.append("審查者不是 code-reviewer")
            if not a["models"] or not all(want in x for x in a["models"]): errs.append(f"審查者模型 {short(a['models'])}，要 {want}")
    # 洩題：所有層的工具輸入
    sess = glob.glob(os.path.join(pdir, "*.jsonl"))
    allin = [i for a in agents for i in a["inputs"]] + [i for s in sess for i in scan(s)["inputs"]]
    # 裁決者轉達給審查者的禁區那句本身含 `~/.claude/projects/`、`/Users/`，先拿掉再比對
    leaks = [i[:160] for n, i in allin if leaky(s4, n, i, pdir)]
    if leaks: errs.append(f"洩題檢查命中 {len(leaks)} 筆：{leaks[:3]}")
    if dump:
        os.makedirs(dump, exist_ok=True)
        for a in agents:
            name = re.sub(r"[^\w.-]", "_", a["meta"].get("description", "?"))  # description 可能含 /
            open(os.path.join(dump, f"{run}.d{a['meta'].get('spawnDepth')}.{a['id'][:6]}.{name}.md"), "w").write(a["text"])
    rmax = max((a["sec"] for a in revs), default=0)
    # 整發 wall：父 session 紀錄的第一個時間戳到所有層最後一個時間戳。
    # 不用 result.duration_ms —— 裁決者在背景跑時父層有兩筆 result，各自只算自己那一輪（實測 G2-new-2 是 6s 與 12s）
    stamps = [ts(o["timestamp"]) for f in sess + [a["path"] for a in agents] for o in read_jsonl(f) if o.get("timestamp")]
    t0 = min(ts(o["timestamp"]) for f in sess for o in read_jsonl(f) if o.get("timestamp"))
    return {"run": run, "whole_s": round(max(stamps) - t0), "api_s": round(last.get("duration_api_ms", 0) / 1000),
            "cost": round(last.get("total_cost_usd", 0), 2), "n_result": len(res),
            "judge_s": round(judge["sec"]) if judge else None, "judge_tools": judge["tools"] if judge else None,
            "n_rev": len(revs), "rev_max_s": round(rmax), "rev_tools": [a["tools"] for a in revs],
            "rev_s": [round(a["sec"]) for a in revs], "errors": errs}

args = sys.argv[1:]
dump = None
if "--dump" in args:
    i = args.index("--dump"); dump = args[i + 1]; del args[i:i + 2]
for run in args[1:]:
    print(json.dumps(run_stats(args[0], run, dump), ensure_ascii=False))
