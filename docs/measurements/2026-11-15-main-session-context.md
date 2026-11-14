# 主對話的 context 長多大、時間花在哪（2026-11-15 量，單一 session）

起因：使用者說「請你改善速度與費用」。量的是同一個 session 裡的一件工作：安裝腳本補強與 README 揭露兩段
（`docs/designs/2026-11-14-installer-hardening-design.md`），從開工到做完 104 分鐘。
同一個 session 較早的一段（到 `2026-11-14T10:30:08Z` 為止）量在 `2026-11-14-session-cost.md`；兩份的時間範圍不重疊，請求數不能相加比較。

## 方法

- 來源：那個 session 的 transcript jsonl（Claude Code 存在本機的對話紀錄，`~/.claude/projects/<專案目錄的編碼>/<session id>.jsonl`），
  只算主對話（`isSidechain` 的不算）。請求數、token、時間分配只看 `2026-11-14T14:16:04Z` → `2026-11-14T16:04:35Z`；
  模型切換與壓縮紀錄看整份檔案（所以也列得到 `2026-11-14-session-cost.md` 那 12 次）
- 指令：`python3 -I main_session.py <transcript>.jsonl 2026-11-14T14:16:04 2026-11-14T16:04:35`（腳本在下面）
- 「每次請求帶的 context」= 那次請求 `usage` 的 `input_tokens`＋`cache_read_input_tokens`＋`cache_creation_input_tokens`。
  `usage.iterations` 長度大於 1 的請求（那次回合裡另外叫了 advisor）數字是幾次迭代的合計，另外列、不算進 context 大小
- 壓縮紀錄 = `type` 是 `system`、`subtype` 是 `compact_boundary` 的那幾筆，取 `compactMetadata` 的 `trigger` 與 `preTokens`
- 那台機器當時的 `~/.claude/settings.json`（用 jq 讀）：最上層沒有 `autoCompactWindow`；`modelSettings` 裡 `claude-opus-5-5` 有 `autoCompactWindow: 400000`，
  `claude-fable-5-2` 那一格沒有這個鍵。使用者在 `2026-11-14T16:25:48Z` 對 `claude-fable-5-2` 下了 `/autocompact 400000`（transcript 裡有指令的回覆「Auto-compact window for Fable 5.2 set to 400k tokens」）
- 引用數字前先重跑。transcript 只在本機、會被清掉；清掉之後這些數字就重算不了。那個 session 在量測之後還繼續用，
  重跑時「壓縮紀錄」會多出 `2026-11-14T17:17:38` 之後的列，其他段落的數字不受影響（時間範圍固定）

```python
import json, sys, collections
from datetime import datetime

# 用法：python3 -I main_session.py <transcript>.jsonl <開始 ISO 時間> <結束 ISO 時間>
# 只算主對話（isSidechain 的不算）。模型時間線與壓縮紀錄看整份檔案，其餘只看時間範圍內。
path, start, end = sys.argv[1:4]
def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00"))

models, last = [], None          # 模型切換時間線（整份）
compacts = []                    # 壓縮紀錄（整份）
usage, order = {}, []            # 範圍內每個請求（依 message.id 去重，取最後一筆）
ev, tool = [], {}                # 範圍內的事件、tool_use 的名稱與開始時間
bash = []
for line in open(path):
    try: r = json.loads(line)
    except ValueError: continue
    t = r.get("timestamp")
    if not t or r.get("isSidechain"): continue
    typ = r.get("type")
    if typ == "system" and r.get("subtype") == "compact_boundary":
        m = r.get("compactMetadata") or {}
        compacts.append((t[:19], m.get("trigger"), m.get("preTokens"), last))
    if typ == "assistant":
        m = r["message"]
        if m.get("model") != last:
            last = m.get("model"); models.append((t[:19], last))
    if not (start <= t <= end): continue
    if typ == "assistant":
        m = r["message"]; u = m.get("usage") or {}
        if m.get("id") not in usage: order.append(m.get("id"))
        usage[m.get("id")] = (
            sum(u.get(k, 0) or 0 for k in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens")),
            u.get("output_tokens", 0) or 0,
            (u.get("output_tokens_details") or {}).get("thinking_tokens", 0) or 0,
            u.get("cache_read_input_tokens", 0) or 0,
            len(u.get("iterations") or []))
        for b in m.get("content") or []:
            if b.get("type") == "tool_use": tool[b["id"]] = (b["name"], t)
        ev.append((t, "等模型（思考＋輸出）"))
    elif typ == "user":
        c = r["message"].get("content")
        if isinstance(c, list) and any(b.get("type") == "tool_result" for b in c):
            for b in c:
                if b.get("type") != "tool_result": continue
                name, t0 = tool.get(b["tool_use_id"], ("?", t))
                ev.append((t, "跑工具：" + name))
                if name == "Bash": bash.append((ts(t) - ts(t0)).total_seconds())
        else:
            s = c if isinstance(c, str) else " ".join((b.get("text") or "") for b in c if isinstance(b, dict))
            if "task-notification" in s or "Subagent" in s[:200]: k = "等 agent 交回"
            elif s.startswith("Base directory for this skill"): k = "skill 注入"
            else: k = "使用者或系統訊息"
            ev.append((t, k))
    elif typ == "attachment" and (r.get("attachment") or {}).get("type") == "queued_command":
        ev.append((t, "等 agent 交回（排隊的通知）"))

print("## 模型切換（整份紀錄）")
for x in models: print("  %s %s" % x)
print("## 壓縮紀錄（整份紀錄；最後一欄是當時的模型）")
for x in compacts: print("  %s %-6s %7s %s" % x)
rows = [usage[i] for i in order]
single = [x[0] for x in rows if x[4] <= 1]
print("## 範圍 %s → %s 的主對話請求：%d 次" % (start, end, len(rows)))
print("  每次請求帶的 context（input＋cache_read＋cache_creation；只看單次迭代的 %d 次）：第一次 %d，最後一次 %d，最大 %d"
      % (len(single), single[0], single[-1], max(single)))
print("  多次迭代的請求 %d 次（usage 是幾次迭代的合計，不是 context 大小）：%s"
      % (len(rows) - len(single), [x[0] for x in rows if x[4] > 1]))
print("  cache_read 合計 %d；output 合計 %d，其中 thinking %d" % (sum(x[3] for x in rows), sum(x[1] for x in rows), sum(x[2] for x in rows)))
ev.sort(key=lambda x: x[0])
bucket, n = collections.Counter(), collections.Counter()
for a, b in zip(ev, ev[1:]):
    bucket[b[1]] += (ts(b[0]) - ts(a[0])).total_seconds(); n[b[1]] += 1
print("## 時間分配（相鄰事件的間隔，算給後面那個事件；合計 %.1f 分）" % (sum(bucket.values()) / 60))
for k, v in bucket.most_common(): print("  %6.1f 分 %4d 段 %s" % (v / 60, n[k], k))
long = [x for x in bash if x > 30]
print("## Bash：%d 次、從送出到結果回來合計 %.1f 分；超過 30 秒的 %d 次、合計 %.1f 分" % (len(bash), sum(bash) / 60, len(long), sum(long) / 60))
```

## 當天輸出

```
## 模型切換（整份紀錄）
  2026-11-13T12:54:31 claude-opus-5-5
  2026-11-14T10:35:55 claude-fable-5-2
## 壓縮紀錄（整份紀錄；最後一欄是當時的模型）
  2026-11-13T17:46:24 auto    366594 claude-opus-5-5
  2026-11-14T05:46:03 auto    378134 claude-opus-5-5
  2026-11-14T06:32:11 auto    367204 claude-opus-5-5
  2026-11-14T06:51:22 auto    385382 claude-opus-5-5
  2026-11-14T07:03:40 auto    371563 claude-opus-5-5
  2026-11-14T07:18:15 auto    367752 claude-opus-5-5
  2026-11-14T08:09:33 auto    367000 claude-opus-5-5
  2026-11-14T08:19:43 auto    374559 claude-opus-5-5
  2026-11-14T08:32:04 auto    370151 claude-opus-5-5
  2026-11-14T08:48:12 auto    367179 claude-opus-5-5
  2026-11-14T09:23:29 auto    370064 claude-opus-5-5
  2026-11-14T10:08:32 auto    369523 claude-opus-5-5
  2026-11-14T13:43:36 auto    969715 claude-fable-5-2
  2026-11-14T16:12:25 manual  779930 claude-fable-5-2
  2026-11-14T17:17:38 auto    371343 claude-fable-5-2
## 範圍 2026-11-14T14:16:04 → 2026-11-14T16:04:35 的主對話請求：124 次
  每次請求帶的 context（input＋cache_read＋cache_creation；只看單次迭代的 122 次）：第一次 244546，最後一次 759029，最大 759029
  多次迭代的請求 2 次（usage 是幾次迭代的合計，不是 context 大小）：[601180, 1498565]
  cache_read 合計 63481446；output 合計 321419，其中 thinking 136430
## 時間分配（相鄰事件的間隔，算給後面那個事件；合計 104.0 分）
    55.6 分  254 段 等模型（思考＋輸出）
    22.5 分   93 段 跑工具：Bash
    21.9 分    8 段 等 agent 交回
     3.2 分    1 段 跑工具：AskUserQuestion
     0.3 分   10 段 跑工具：Agent
     0.2 分   10 段 等 agent 交回（排隊的通知）
     0.1 分    9 段 跑工具：Read
     0.0 分    9 段 跑工具：Skill
     0.0 分    4 段 跑工具：Write
     0.0 分    9 段 使用者或系統訊息
     0.0 分    2 段 跑工具：Edit
     0.0 分    9 段 skill 注入
## Bash：93 次、從送出到結果回來合計 22.9 分；超過 30 秒的 17 次、合計 17.0 分
```

## 整理

- **自動壓縮發生在多少 token**（`trigger` 是 `auto` 的）：有 400000 個別設定的 `claude-opus-5-5` 12 次，366,594–385,382；
  換成沒有設定的 `claude-fable-5-2` 之後 1 次，969,715；對它下了 `/autocompact 400000` 之後的下一次，371,343。
  中間那筆 `manual` 779,930 是使用者自己打的 `/compact`
- **那件 104 分鐘的工作**：主對話 124 次請求，每次帶的 context 從 244,546 長到 759,029 token；`cache_read` 合計 63,481,446
- **時間**：等模型 55.6 分、跑 Bash 22.5 分（93 次裡超過 30 秒的 17 次佔 17.0 分）、等 agent 交回 21.9 分、等使用者回答一次選單 3.2 分。
  輸出 321,419 token 裡 thinking 佔 136,430

## 最上層的鍵有沒有作用（另外做的一次對照）

官方文件寫最上層的 `autoCompactWindow` 對每個模型生效（原文抄在 `docs/designs/2026-11-15-speed-cost-design.md` 的 F15）。
2026-11-15 在 Claude Code 2.1.325 各跑一發確認：兩臂只差 `--settings` 裡有沒有這個鍵；用的模型（haiku）在那台機器的 `modelSettings` 沒有個別設定，
環境變數 `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 沒設。

```bash
# 素材：兩個目錄 T、C，各放 f01.txt–f10.txt，每個 1200 行、78,870 bytes 的隨機單字（python3 的 random.seed(7) 產的）
# 用法：run.sh <臂目錄> <--settings 的 JSON>
cd "$1" || exit 1
perl -e 'alarm 900; exec @ARGV or exit 127' claude -p "這個目錄有 f01.txt 到 f10.txt。請依序處理：一次只用 Read 讀一個檔（整個檔讀完，不要平行讀、不要用 offset 跳過），讀完回一行「fNN 最後一行的編號是 XXXX」，再讀下一個。十個都讀完後回覆 DONE。" \
  --model haiku --output-format stream-json --verbose --permission-mode dontAsk --allowedTools "Read" \
  --disallowedTools "Bash Edit Write Agent" --settings "$2" --max-budget-usd 3 < /dev/null > out.jsonl 2> err.txt
# 有設那一臂：run.sh T '{"autoCompactWindow":100000,"advisorModel":""}'
# 沒設那一臂：run.sh C '{"advisorModel":""}'
```

| 臂 | stream-json 裡的 `compact_boundary` | 每次請求帶的 context 最大值 | 結束時 |
|---|---|---|---|
| 有設 100000 | 3 筆，都是 `trigger: auto`，`pre_tokens` 81,120、80,113、63,356 | 71,565 | 沒讀完十個檔（Read 4 次；最後一則回覆在問要不要接著做） |
| 沒設 | 0 筆 | 448,638 | 十個檔讀完，回覆 `DONE` |

兩臂的 `permission_denials` 都是 0，`modelUsage` 的鍵都只有 `claude-haiku-5-5`。原始 jsonl 沒進 repo。

## 限制

- 一個 session、一件工作；壓縮門檻那三組的次數是 12、1、1
- 「沒有設定的模型到 969,715 才壓縮」只看到 `claude-fable-5-2` 這一次，不能推到別的模型；官方文件對沒設時的說法是
  `Default: unset, so Claude Code picks a window tuned for your model`，沒有給數字
- 沒有換算成錢：`cache_read` 的單價沒有查證
- 時間分配是相鄰兩筆紀錄的間隔，算給後面那一筆；同一則訊息裡平行的工具呼叫會被拆成好幾段，各段的歸屬不精確，合計不受影響。
  「跑工具：Bash」22.5 分是這種算法；最後一行的 22.9 分是每個 Bash 呼叫從送出到結果回來的時間，兩個數字差在平行呼叫
- 「等 agent 交回」含 agent 完成通知進來之前主對話閒著的時間；subagent 自己用掉的 token 不在這支腳本裡
- 腳本用字串比時間，結束那一秒裡帶毫秒的紀錄會被排除
- 對照那一次各只有一發；鍵是用 `--settings` 給的，不是寫在 `~/.claude/settings.json`；有設那一臂被壓縮打斷後沒做完，所以兩臂的費用不能比
- 提早壓縮會不會讓後面的工作品質變差，沒有量
