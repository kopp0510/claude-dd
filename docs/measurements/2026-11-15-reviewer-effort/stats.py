# 每一發的耗時、token、工具次數、費用、操作檢查與作廢檢查（從 ../2026-10-24-s5-inputs/stats.py 改來）。
# 用法：python3 -I stats.py <工作目錄> <發代號>...   （加 --dump <目錄> 會把每個 subagent 交回的報告存成檔）
# 只讀各發快照自己的 projects 目錄，不掃整個 ~/.claude/projects。
import glob, json, os, re, sys
from datetime import datetime

EFFORT = {"med": "medium", "low": "low"}

def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
def enc(p): return re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(p))

def read_jsonl(p):
    for ln in open(p, errors="ignore"):
        try: yield json.loads(ln)
        except ValueError: pass

def scan(path):
    t, tools, models, efforts, inputs, usage, hand, last_text = [], {}, set(), set(), [], {}, None, ""
    for o in read_jsonl(path):
        if o.get("timestamp"): t.append(ts(o["timestamp"]))
        if o.get("type") != "assistant": continue
        if "effort" in o: efforts.add(str(o["effort"]))
        m = o.get("message") or {}
        if m.get("model"): models.add(m["model"])
        u = m.get("usage") or {}
        if m.get("id") and u:
            # 同一則訊息會分好幾筆紀錄、usage 重複出現：每個訊息 id 取最大的那筆
            out = u.get("output_tokens") or 0
            think = (u.get("output_tokens_details") or {}).get("thinking_tokens") or 0
            old = usage.get(m["id"], (0, 0))
            usage[m["id"]] = (max(old[0], out), max(old[1], think))
        c = m.get("content")
        if not isinstance(c, list): continue
        txt = "".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
        if txt.strip(): last_text = txt
        for b in c:
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("id") not in tools:
                tools[b["id"]] = b.get("name")
                inputs.append((b.get("name"), json.dumps(b.get("input"), ensure_ascii=False)))
                if b.get("name") == "SubagentHandback":
                    i = b.get("input") or {}
                    hand = max((v for v in i.values() if isinstance(v, str)), key=len, default=None) or json.dumps(i, ensure_ascii=False)
    if len(t) < 2: raise SystemExit(f"{path} 時間戳不足")
    return {"t0": min(t), "t1": max(t), "sec": max(t) - min(t), "tools": sum(1 for n in tools.values() if n != "SubagentHandback"),
            "models": models, "efforts": efforts, "inputs": inputs, "text": hand or last_text,
            "out": sum(v[0] for v in usage.values()), "think": sum(v[1] for v in usage.values())}

LEAK = re.compile(r"/Users/|~/|\$HOME|\$\{HOME\}|\.\./|my_project|\.claude/")
# 從根目錄開始搜的指令（find / 這種）；只查 Bash。不比對裸的「 / 」：echo 字串與 # 註解裡常有
ROOT_ARG = re.compile(r"\b(find|ls|cd|du|tree)\s+/(\s|$)|\b(grep|rg)\b[^|;&\n]*\s/(\s|$)")

def leaky(w, run, name, i, own):
    # 先把這一發自己可以讀的路徑換掉：自己的 projects 目錄（大輸出落在它的 tool-results/）、自己的快照、
    # 自己的 prompt 檔、同素材的 diff 目錄；剩下還出現工作目錄就是讀到別發的東西
    g = run.split("-")[0]
    roots = {w, os.path.realpath(w)}
    i = i.replace(own, "<OWN>")
    for r in roots:
        snap = os.path.join(r, run)
        # 結尾帶分隔字元再比：G2/ 不可以吃掉 G2-low-1 的開頭
        for p, tag in ((snap + "/", "<SNAP>/"), (snap + '"', '<SNAP>"'), (snap + " ", "<SNAP> "),
                       (os.path.join(r, "prompts", run + "."), "<PROMPT>."), (os.path.join(r, g) + "/", "<DIFF>/")):
            i = i.replace(p, tag)
    if any(r in i for r in roots): return True
    # 說明檔裡禁區那句本身含這兩個字串，審查者引用它不算
    i = i.replace("`~/.claude/projects/`", "").replace("`/Users/`", "")
    hit = LEAK.search(i)
    # `../` 在拋棄式目錄裡（同一個指令有 mktemp 或 /tmp/）是 worktree 實驗的正常寫法，不算往快照外爬
    if hit and not (hit.group() == "../" and re.search(r"mktemp|/tmp/", i)
                    and not LEAK.search(i.replace("../", ""))): return True
    return name == "Bash" and bool(ROOT_ARG.search(json.loads(i).get("command", "")))

def run_stats(w, run, dump):
    g, arm, _ = run.split("-")
    snap = os.path.join(w, run)
    pdir = os.path.join(os.path.expanduser("~/.claude/projects"), enc(snap))
    errs, notes = [], []
    log = os.path.join(w, "logs", run + ".jsonl")
    res = [o for o in read_jsonl(log) if o.get("type") == "result"]
    if not res: errs.append("父 log 沒有 result")
    # 步驟 4 審查之後加的：claude -p 把背景 subagent 停掉時 stderr 印這句（run.sh 把 stderr 併進父 log），父 log 照樣有 success 的 result
    if any("Background tasks still running" in l for l in open(log, encoding="utf-8", errors="replace") if not l.startswith("{")):
        errs.append("父 log 有「Background tasks still running」：背景 subagent 被停掉")
    for r in res:
        if r.get("permission_denials"): errs.append(f"permission_denials：{json.dumps(r['permission_denials'], ensure_ascii=False)[:300]}")
    last = res[-1] if res else {}
    if res and (last.get("is_error") or last.get("subtype") != "success"):
        errs.append(f"最後一筆 result：subtype={last.get('subtype')} is_error={last.get('is_error')}")
    agents = []
    for m in glob.glob(os.path.join(pdir, "*", "subagents", "agent-*.meta.json")):
        meta = json.load(open(m)); j = m.replace(".meta.json", ".jsonl")
        if not os.path.exists(j): errs.append(f"找不到 {os.path.basename(j)}"); continue
        a = scan(j); a["path"] = j; a["meta"] = meta; a["id"] = os.path.basename(m)[6:-10]; agents.append(a)
    d1 = [a for a in agents if a["meta"].get("spawnDepth") == 1]
    d2 = [a for a in agents if a["meta"].get("spawnDepth") == 2]
    other = [a for a in agents if a["meta"].get("spawnDepth") not in (1, 2)]
    if other: errs.append(f"有第 1、2 層以外的 subagent {len(other)} 個")
    def short(ms): return ",".join(sorted(x.replace("claude-", "") for x in ms)) or "-"
    want = EFFORT[arm]
    if g == "P":
        # 甲：第 1 層是裁決者（general-purpose、opus、medium）一個，第 2 層是它派的審查者（haiku、該臂的強度）
        if len(d1) != 1: errs.append(f"裁決者要剛好 1 個，實際 {len(d1)}")
        for a in d1:
            if not a["models"] or not all("opus" in x for x in a["models"]): errs.append(f"裁決者模型 {short(a['models'])}，要 opus")
            if a["efforts"] != {"medium"}: errs.append(f"裁決者 effort {sorted(a['efforts'])}，要 medium")
        revs, rev_model = d2, "haiku"
        if len(revs) < 3: errs.append(f"審查者不到 3 個（{len(revs)}）")
        for a in d1:
            if "【結論】" not in a["text"]: errs.append("裁決者的報告沒有【結論】（沒寫完或沒交回）")
    else:
        # 乙：第 1 層是 3 個 code-reviewer（定義檔的 opus、該臂的強度），沒有第 2 層
        if len(d1) != 3 or d2: errs.append(f"要剛好 3 個第 1 層、0 個第 2 層，實際 {len(d1)}／{len(d2)}")
        for a in d1:
            if a["meta"].get("agentType") != "code-reviewer": errs.append(f"審查者類型 {a['meta'].get('agentType')}，要 code-reviewer")
        revs, rev_model = d1, "opus"
    for a in revs:
        if not a["models"] or not all(rev_model in x for x in a["models"]): errs.append(f"審查者 {a['meta'].get('description')} 模型 {short(a['models'])}，要 {rev_model}")
        if a["efforts"] != {want}: errs.append(f"審查者 {a['meta'].get('description')} effort {sorted(a['efforts'])}，要 {want}")
    sess = glob.glob(os.path.join(pdir, "*.jsonl"))
    sess_scans = [scan(s) for s in sess]
    pm = set().union(*[x["models"] for x in sess_scans] or [set()])
    if not pm or not all("haiku" in x for x in pm): errs.append(f"父 session 模型 {short(pm)}，要 haiku")
    mu = sorted((last.get("modelUsage") or {}).keys())
    if any(not ("haiku" in k or "opus" in k) for k in mu): errs.append(f"modelUsage 有別的模型：{mu}")
    # 洩題：所有層的工具輸入。命中的要人工逐筆看（真的讀到外面才算），所以全部列出
    allin = [(a["meta"].get("description", "?"), n, i) for a in agents for n, i in a["inputs"]] + [("父", n, i) for x in sess_scans for n, i in x["inputs"]]
    leaks = [f"{who}｜{n}｜{i[:200]}" for who, n, i in allin if leaky(w, run, n, i, pdir)]
    if leaks: notes.append({"洩題檢查命中（待人工判定）": leaks})
    if dump:
        os.makedirs(dump, exist_ok=True)
        for a in agents:
            name = re.sub(r"[^\w.-]", "_", a["meta"].get("description", "?"))
            open(os.path.join(dump, f"{run}.d{a['meta'].get('spawnDepth')}.{a['id'][:6]}.{name}.md"), "w", encoding="utf-8").write(a["text"])
    stamps = [ts(o["timestamp"]) for f in sess + [a["path"] for a in agents] for o in read_jsonl(f) if o.get("timestamp")]
    t0 = min(ts(o["timestamp"]) for f in sess for o in read_jsonl(f) if o.get("timestamp"))
    out = {"run": run, "whole_s": round(max(stamps) - t0), "api_s": round(last.get("duration_api_ms", 0) / 1000),
           "cost": round(last.get("total_cost_usd", 0), 2), "n_result": len(res), "modelUsage": [k.replace("claude-", "") for k in mu],
           "n_rev": len(revs), "rev_desc": [a["meta"].get("description") for a in revs],
           "rev_s": [round(a["sec"]) for a in revs], "rev_max_s": round(max((a["sec"] for a in revs), default=0)),
           "rev_tools": [a["tools"] for a in revs], "rev_out": [a["out"] for a in revs], "rev_think": [a["think"] for a in revs],
           "rev_effort": sorted(set().union(*[a["efforts"] for a in revs] or [set()]))}
    if g == "P" and d1:
        judge = d1[0]
        # 裁決者整發秒數：裁決者紀錄檔第一筆，到它與所有審查者最後一筆（主對話實際在等的時間）
        out.update({"judge_s": round(max([judge["t1"]] + [a["t1"] for a in revs]) - judge["t0"]), "judge_tools": judge["tools"],
                    "judge_out": judge["out"], "judge_think": judge["think"]})
    out["errors"] = errs
    out["notes"] = notes
    return out

args = sys.argv[1:]
dump = None
if "--dump" in args:
    i = args.index("--dump"); dump = args[i + 1]; del args[i:i + 2]
for run in args[1:]:
    print(json.dumps(run_stats(args[0], run, dump), ensure_ascii=False))
