# code-reviewer 的時間花在哪（2026-10-23，真實 session 紀錄）

起因：使用者反映每次等 8 步迴圈步驟 4 都超過半小時。2026-10-05 那份（`2026-10-05-reviewer-overhead.md`）
是基準台 n=2；這份改讀**真實 session** 裡每個 code-reviewer subagent 自己的紀錄檔。

## 方法

- 來源：`~/.claude/projects/**/agent-*.meta.json`（`agentType == "code-reviewer"`）與同名 `.jsonl`
- 耗時 = 該 subagent jsonl 裡最晚與最早 `timestamp` 的差；工具 = 其中每個 `tool_use`
- 排除公司專案（路徑含 `-SRE`）。紀錄只保留到約 30 天前，所以這是近期樣本、不是全部歷史
- ⚠️ **不要改用父 session 的 `<task-notification>` 裡的 `duration_ms`**：同一天先用那個算，
  只抓到 98 次、中位數 2 分鐘 —— 大部分派工的通知沒被比對到，結論整個相反

引用下面的數字前先重跑（數字是當天的快照）：

```bash
python3 -I <下面這支腳本存成的檔> ~/.claude/projects
```

```python
import json, glob, os, re, sys, collections
from datetime import datetime

# 用法：python3 -I reviewer_stats.py ~/.claude/projects
root = sys.argv[1]
def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()

def cat(b):
    n = b["name"]
    if n != "Bash": return n
    c = b.get("input", {}).get("command", "")
    if re.search(r"\bgit (-C \S+ )?(diff|show|log)", c): return "Bash: git diff/show/log"
    if re.search(r"\b(grep|rg)\b", c): return "Bash: grep"
    if re.search(r"\b(sed -n|cat|head|tail|awk)\b", c): return "Bash: 印檔案內容"
    if re.search(r"test|jest|vitest|pytest|npm|node |tsc|bash .*\.sh|docker", c): return "Bash: 跑測試/程式/docker"
    return "Bash: 其他"

runs = []
for m in glob.glob(os.path.join(root, "**/agent-*.meta.json"), recursive=True):
    if "-SRE" in m: continue          # 公司專案不讀
    meta = json.load(open(m))
    if meta.get("agentType") != "code-reviewer": continue
    t, tools = [], []
    for ln in open(m.replace(".meta.json", ".jsonl"), errors="ignore"):
        try: o = json.loads(ln)
        except ValueError: continue
        if o.get("timestamp"): t.append(ts(o["timestamp"]))
        for b in ((o.get("message") or {}).get("content") or []):
            if isinstance(b, dict) and b.get("type") == "tool_use": tools.append(cat(b))
    if len(t) < 2: continue
    runs.append(((max(t) - min(t)) / 60, tools, meta.get("description", "")))

d = sorted(r[0] for r in runs); n = len(d)
print(f"code-reviewer 次數={n} 中位={d[n//2]:.1f} 分 第90百分位={d[int(n*.9)]:.1f} 分 >=10分={sum(x>=10 for x in d)}")

print("\n工具次數 vs 耗時（排除 >200 分的離群值，多半是事後被喚醒續跑）")
B = collections.defaultdict(list)
for dur, tl, _ in runs:
    if dur > 200: continue
    k = len(tl); B["0-10" if k <= 10 else "11-20" if k <= 20 else "21-30" if k <= 30 else "31+"].append(dur)
for k in ["0-10", "11-20", "21-30", "31+"]:
    v = sorted(B[k]); print(f"  工具 {k:6s} 次數={len(v):3d} 中位={v[len(v)//2]:5.1f} 分")

C = collections.Counter(x for _, tl, _ in runs for x in tl); tot = sum(C.values())
print(f"\n工具種類（共 {tot} 次）")
for k, v in C.most_common(6): print(f"  {100*v/tot:4.0f}%  {k}")

fast = [r for r in runs if r[0] <= 5]; slow = [r for r in runs if 15 <= r[0] <= 200]
print(f"\n每次平均：快的(<=5分, {len(fast)} 次) vs 慢的(15–200分, {len(slow)} 次)")
for k in ["Bash: git diff/show/log", "Bash: grep", "Bash: 印檔案內容"]:
    f = sum(r[1].count(k) for r in fast) / len(fast); s = sum(r[1].count(k) for r in slow) / len(slow)
    print(f"  {f:5.1f} vs {s:5.1f}  {k}")
```

## 當天輸出（2026-10-23）

```
code-reviewer 次數=309 中位=12.0 分 第90百分位=27.9 分 >=10分=167

工具次數 vs 耗時（排除 >200 分的離群值，多半是事後被喚醒續跑）
  工具 0-10   次數= 70 中位=  3.0 分
  工具 11-20  次數=115 中位= 10.9 分
  工具 21-30  次數= 88 中位= 16.6 分
  工具 31+    次數= 34 中位= 24.6 分

工具種類（共 5761 次）
    66%  Bash: git diff/show/log
    19%  Bash: grep
     6%  Bash: 印檔案內容
     5%  SubagentHandback
     1%  Read
     1%  Bash: 跑測試/程式/docker

每次平均：快的(<=5分, 112 次) vs 慢的(15–200分, 127 次)
    7.7 vs  16.9  Bash: git diff/show/log
    2.4 vs   4.7  Bash: grep
    0.7 vs   1.6  Bash: 印檔案內容
```

## 結論

1. **時間跟工具次數走**：0–10 次約 3 分鐘，31 次以上約 25 分鐘（與 2026-10-05 結論 3 一致，這次樣本大很多）
2. **工具次數主要花在「撈改了什麼」**：`git diff/show/log` 佔全部工具呼叫的大宗；快的與慢的審查差最多的也是這一項，
   grep（真正在查證別處）差得少。現行 §3.9 步驟 4「並行時用 `git show HEAD:<路徑>` 取檔」會逼它逐檔撈
3. 所以加速方向是**派工前把整段 diff 準備成一個檔交給它**，而不是砍工具上限（砍上限會連查證一起砍）

## 限制

- 耗時是 wall（含模型思考與工具執行），沒有拆出 api 時間
- 工具分類用指令字串的正規式，`git -c … diff` 這種寫法不會被歸進 git 那類（只會低估）
- 「先交 diff 會快多少」本檔沒有量；要等實作後拿舊 diff 重跑比較
