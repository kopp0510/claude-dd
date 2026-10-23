# code-reviewer 的時間花在哪（2026-10-23，真實 session 紀錄）

起因：使用者反映每次等 8 步迴圈步驟 4 都超過半小時。2026-10-05 那份（`2026-10-05-reviewer-overhead.md`）
是基準台 n=2；這份改讀**真實 session** 裡每個 code-reviewer subagent 自己的紀錄檔。

## 方法

- 來源：`~/.claude/projects/**/agent-*.meta.json`（`agentType == "code-reviewer"`）與同名 `.jsonl`
- 耗時 = 該 subagent jsonl 裡最晚與最早 `timestamp` 的差；工具 = 其中每個 `tool_use`，**用 id 去重**
  （同一個 tool_use 會在多行重複出現；第一版沒去重，工具數高估約 7%，S1 的 review 抓到）
- 排除公司專案（路徑含 `-SRE`）。紀錄只保留到約 30 天前，所以這是近期樣本、不是全部歷史
- ⚠️ **不要改用父 session 的 `<task-notification>` 裡的 `duration_ms`**：同一天先用那個算，
  只抓到 98 次、中位數 2 分鐘 —— 大部分派工的通知沒被比對到，結論整個相反

引用下面的數字前先重跑（數字是當天的快照，之後的審查也會算進去）：

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
    j = m.replace(".meta.json", ".jsonl")
    if not os.path.exists(j): continue
    t, tools, seen = [], [], set()
    for ln in open(j, errors="ignore"):
        try: o = json.loads(ln)
        except ValueError: continue
        if o.get("timestamp"): t.append(ts(o["timestamp"]))
        for b in ((o.get("message") or {}).get("content") or []):
            # 同一個 tool_use 會在多行重複出現（2026-10-23 實測全部 code-reviewer 紀錄有數百筆重複），用 id 去重
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("id") not in seen:
                seen.add(b.get("id")); tools.append(cat(b))
    if len(t) < 2: continue
    runs.append(((max(t) - min(t)) / 60, tools, meta.get("description", "")))

d = sorted(r[0] for r in runs); n = len(d)
if n == 0: sys.exit("沒有任何 code-reviewer 紀錄")
print(f"code-reviewer 次數={n} 中位={d[n//2]:.1f} 分 第90百分位={d[int(n*.9)]:.1f} 分 >=10分={sum(x>=10 for x in d)}")

print("\n工具次數 vs 耗時（排除 >200 分的離群值，多半是事後被喚醒續跑）")
B = collections.defaultdict(list)
for dur, tl, _ in runs:
    if dur > 200: continue
    k = len(tl); B["0-10" if k <= 10 else "11-20" if k <= 20 else "21-30" if k <= 30 else "31+"].append(dur)
for k in ["0-10", "11-20", "21-30", "31+"]:
    v = sorted(B[k])
    print(f"  工具 {k:6s} 次數={len(v):3d} 中位={v[len(v)//2]:5.1f} 分" if v else f"  工具 {k:6s} 次數=  0")

C = collections.Counter(x for _, tl, _ in runs for x in tl); tot = sum(C.values())
print(f"\n工具種類（共 {tot} 次）")
for k, v in C.most_common(6): print(f"  {100*v/tot:4.0f}%  {k}")

fast = [r for r in runs if r[0] <= 5]; slow = [r for r in runs if 15 <= r[0] <= 200]
print(f"\n每次平均：快的(<=5分, {len(fast)} 次) vs 慢的(15–200分, {len(slow)} 次)")
for k in ["Bash: git diff/show/log", "Bash: grep", "Bash: 印檔案內容"]:
    if not fast or not slow: print("  （快或慢的樣本是 0，不比）"); break
    f = sum(r[1].count(k) for r in fast) / len(fast); s = sum(r[1].count(k) for r in slow) / len(slow)
    print(f"  {f:5.1f} vs {s:5.1f}  {k}（{s/f if f else float('inf'):.1f} 倍）")
```

## 當天輸出（2026-10-23，含本 repo S1 那兩發新做法的審查）

```
code-reviewer 次數=311 中位=11.8 分 第90百分位=27.7 分 >=10分=167

工具次數 vs 耗時（排除 >200 分的離群值，多半是事後被喚醒續跑）
  工具 0-10   次數=100 中位=  2.4 分
  工具 11-20  次數=102 中位= 12.0 分
  工具 21-30  次數= 73 中位= 17.3 分
  工具 31+    次數= 34 中位= 24.6 分

工具種類（共 5377 次）
    65%  Bash: git diff/show/log
    19%  Bash: grep
     7%  Bash: 印檔案內容
     6%  SubagentHandback
     1%  Read
     1%  Bash: 跑測試/程式/docker

每次平均：快的(<=5分, 114 次) vs 慢的(15–200分, 127 次)
    5.2 vs  16.7  Bash: git diff/show/log（3.2 倍）
    1.9 vs   4.6  Bash: grep（2.5 倍）
    0.6 vs   1.6  Bash: 印檔案內容（2.9 倍）
```

## 結論

1. **時間跟工具次數走**：0–10 次約 2–3 分鐘，31 次以上約 25 分鐘（與 2026-10-05 結論 3 一致，這次樣本大很多）
2. **git 類（`git diff/show/log`）佔全部工具呼叫的大宗**，但慢的審查是**每一類都多好幾倍**（git、grep、印檔案的倍數接近），
   不是只有 git 變多。所以這份數據**證明不了**「慢是因為逐檔撈 diff」—— 也可能只是 diff 大、檔案多，每類都跟著變多。
   指令字串的分類也分不出「逐檔撈」與「整段看一次」
3. 「派工前把整段 diff 準備成一個檔交給它」是根據結論 2 的**推論**（git 類最多，先交 diff 至少省掉撈 diff 那部分），
   效果要等 S4 拿同一批舊 diff 新舊對照才算數。另外，全域 §3.9 步驟 4 的「`git show <commit>:<路徑>` 取檔」
   只在與 simplifier 並行時適用，不是所有審查都會逐檔撈

## 限制

- 耗時是 wall（含模型思考與工具執行），沒有拆出 api 時間；被 SendMessage 喚醒續跑過的審查會把中間閒置算進去，
  分桶只排除 >200 分的，整體中位數與第 90 百分位沒有排除
- 工具分類用指令字串的正規式，`git -c … diff` 這種寫法不會被歸進 git 那類（只會低估）
