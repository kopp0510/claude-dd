#!/usr/bin/env python3
"""甲各發在時間軸上的位置：裁決者第一筆紀錄當 0 秒，印每個審查者的起訖與裁決者派工的時間點。

用法：python3 -I timeline.py <工作目錄> <P 開頭的發代號>…
步驟 4 的審查之後才加的（2026-11-15）：stats.py 的 rev_s 是每個審查者自己紀錄檔的首尾差，
看不出它在整發裡什麼時候開始；要拆「等的時間花在哪」得看這裡。讀的是 ~/.claude/projects/ 的 subagent 紀錄檔（不在 repo）。
"""
import glob, json, os, re, sys
from datetime import datetime

def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()

def scan(path):
    """回傳（所有紀錄的時間戳、Agent 呼叫的〔時間戳、訊息 id、prompt 字元數〕）。"""
    t, calls = [], []
    for line in open(path, encoding="utf-8", errors="replace"):
        try: r = json.loads(line)
        except ValueError: continue
        if not r.get("timestamp"): continue
        t.append(ts(r["timestamp"]))
        msg = r.get("message") or {}
        content = msg.get("content")
        for b in content if isinstance(content, list) else []:
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Agent":
                calls.append((t[-1], msg.get("id", ""), len((b.get("input") or {}).get("prompt", ""))))
    return t, calls

w, runs = sys.argv[1], sys.argv[2:]
print("| 發 | 派工的訊息數 | 每個 Agent 呼叫出現在紀錄檔的秒數 | 每個 prompt 字元數 | 審查者起→訖（照開始順序） | 最後一個審查者結束 | 裁決者結束 | 最後一個審查者結束之後 |")
print("|---|---|---|---|---|---|---|---|")
for run in runs:
    pdir = os.path.join(os.path.expanduser("~/.claude/projects"), re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(os.path.join(w, run))))
    judge, revs = None, []
    for m in glob.glob(os.path.join(pdir, "*", "subagents", "agent-*.meta.json")):
        depth = json.load(open(m)).get("spawnDepth")
        t, calls = scan(m.replace(".meta.json", ".jsonl"))
        if depth == 1: judge = (min(t), max(t), calls)
        elif depth == 2: revs.append((min(t), max(t)))
    t0, t1, calls = judge
    revs.sort()
    last = max(e for _, e in revs)
    def rel(x): return round(x - t0)
    print("| `%s` | %d | %s | %s | %s | %d | %d | %d |" % (
        run, len({c[1] for c in calls}), "、".join(str(rel(c[0])) for c in calls), "、".join(str(c[2]) for c in calls),
        "、".join("%d→%d" % (rel(s), rel(e)) for s, e in revs), rel(last), rel(t1), round(t1 - last)))
