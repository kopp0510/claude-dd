# 一件兩段的工作實際花了什麼（2026-11-14，單一 session）

起因：使用者問這個 repo 的流程合不合理、效益與執行速度。量的是同一個 session 裡的一件工作：
修 `/dd-init` 的 symlink 寫出（S1）加收編 security-audit（S2），從使用者下指令到做完
（`docs/designs/2026-11-14-security-audit-intake-design.md`）。

## 方法

- 來源：那個 session 的 transcript jsonl（Claude Code 存在本機的對話紀錄，`~/.claude/projects/<專案目錄的編碼>/<session id>.jsonl`），
  只算主對話（`isSidechain` 的不算），時間範圍 `2026-11-13T17:42:47Z` → `2026-11-14T10:30:08Z`。
  找是哪一份：`grep -l '2026-11-13T17:42:47' ~/.claude/projects/*/*.jsonl`（當天只命中一份）
- 指令：`python3 -I session_cost.py <transcript>.jsonl 2026-11-13T17:42:47 2026-11-14T10:30:08`（腳本在下面）
- 行數另外用 `git diff --numstat dd8b5a9..139bc41` 依路徑分類
- session 一開始的輸入量（**不套上面的時間範圍**，取的是整份 transcript 的第一個請求，時間是 `2026-11-13T12:54:31Z`）：`jq -r 'select(.type=="assistant" and (.isSidechain|not)) | (.message.usage | (.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens))' <transcript>.jsonl | head -1`
- 引用數字前先重跑。transcript 只在本機、會被清掉；清掉之後這些數字就重算不了

```python
import json, sys, collections
from datetime import datetime

# 用法：python3 -I session_cost.py <transcript>.jsonl <開始 ISO 時間> <結束 ISO 時間>
path, start, end = sys.argv[1:4]
def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00"))

tool_name, tool_ts, ask = {}, {}, []
agents = collections.Counter()
dry = 0
usage, order = {}, []
res_len, res_n = collections.Counter(), collections.Counter()
res_ts = {}
compacts, qc = [], collections.defaultdict(list)

for line in open(path):
    try: r = json.loads(line)
    except ValueError: continue
    t = r.get("timestamp")
    if not t or t < start or t > end or r.get("isSidechain"): continue
    typ = r.get("type")
    if typ == "assistant":
        m = r["message"]
        u = m.get("usage") or {}
        if m.get("id") not in usage: order.append(m.get("id"))
        usage[m.get("id")] = (t, sum(u.get(k, 0) or 0 for k in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens")), u.get("output_tokens", 0) or 0)
        for b in m.get("content") or []:
            if b.get("type") != "tool_use": continue
            tool_name[b["id"]] = b["name"]; tool_ts[b["id"]] = t
            if b["name"] == "Agent":
                agents["%s/%s" % (b["input"].get("subagent_type", "general-purpose"), b["input"].get("model", "-"))] += 1
                if "dry-run" in b["input"].get("description", "").lower(): dry += 1
            if b["name"] == "AskUserQuestion":
                ask.append((b["id"], "／".join(q.get("header", "") for q in b["input"].get("questions", []))))
    elif typ == "user":
        c = r["message"].get("content")
        if isinstance(c, list):
            for b in c:
                if b.get("type") == "tool_result":
                    res_ts[b["tool_use_id"]] = t
                    n = tool_name.get(b["tool_use_id"], "?")
                    res_len[n] += len(json.dumps(b.get("content"), ensure_ascii=False)); res_n[n] += 1
    elif typ == "system" and r.get("subtype") == "compact_boundary":
        compacts.append((t, (r.get("compactMetadata") or {}).get("preTokens")))
    elif typ == "attachment" and (r.get("attachment") or {}).get("type") == "queued_command":
        a = r["attachment"]; p = a.get("prompt") or ""
        kind = "完成通知" if "usage" in a else ("交回訊息" if a.get("isMeta") else "其他")
        qc[kind].append(len(p if isinstance(p, str) else json.dumps(p, ensure_ascii=False)))

print("## 範圍", start, "→", end, "共 %.0f 分鐘" % ((ts(end) - ts(start)).total_seconds() / 60))
print("## 主對話派出的 agent", sum(agents.values())); [print("  %4d %s" % (v, k)) for k, v in agents.most_common()]
print("  其中 description 含 dry-run 的 %d 個" % dry)
print("## AskUserQuestion"); tot = 0
for i, h in ask:
    if i in res_ts:
        w = (ts(res_ts[i]) - ts(tool_ts[i])).total_seconds() / 60; tot += w
        print("  %6.1f 分｜%s" % (w, h))
print("  合計 %.1f 分，%d 次" % (tot, len(ask)))
print("## 自動壓縮 %d 次" % len(compacts))
for t, pre in compacts:
    after = next((usage[i][1] for i in order if usage[i][0] > t), None)
    print("  %s 壓縮前 %s，壓縮後第一個請求 %s" % (t[:16], pre, after))
print("## 進到主對話的字元數")
for k, v in res_len.most_common(4): print("  %s 的結果：%d 次，%d 字元" % (k, res_n[k], v))
for k, v in qc.items(): print("  %s：%d 則，%d 字元，平均 %d" % (k, len(v), sum(v), sum(v) // len(v)))
print("## 主對話 token（依 message.id 去重）請求 %d 次，輸出 %d" % (len(usage), sum(v[2] for v in usage.values())))
```

## 當天輸出

```text
## 範圍 2026-11-13T17:42:47 → 2026-11-14T10:30:08 共 1007 分鐘
## 主對話派出的 agent 171
   157 general-purpose/sonnet
     8 code-reviewer/-
     4 general-purpose/opus
     2 code-simplifier:code-simplifier/-
  其中 description 含 dry-run 的 21 個
## AskUserQuestion
     2.2 分｜乾跑方式
   519.9 分｜範圍
    52.5 分｜S1 範圍
    37.8 分｜下一步
     3.1 分｜Q1 已存在
    27.5 分｜測試清單
     2.0 分｜步驟 7／.screenshots
    24.8 分｜D11c
     3.6 分｜步驟 7
  合計 673.4 分，9 次
## 自動壓縮 12 次
  2026-11-13T17:46 壓縮前 366594，壓縮後第一個請求 132602
  2026-11-14T05:46 壓縮前 378134，壓縮後第一個請求 178268
  2026-11-14T06:32 壓縮前 367204，壓縮後第一個請求 171515
  2026-11-14T06:51 壓縮前 385382，壓縮後第一個請求 189773
  2026-11-14T07:03 壓縮前 371563，壓縮後第一個請求 180782
  2026-11-14T07:18 壓縮前 367752，壓縮後第一個請求 182040
  2026-11-14T08:09 壓縮前 367000，壓縮後第一個請求 159952
  2026-11-14T08:19 壓縮前 374559，壓縮後第一個請求 186686
  2026-11-14T08:32 壓縮前 370151，壓縮後第一個請求 171502
  2026-11-14T08:48 壓縮前 367179，壓縮後第一個請求 182155
  2026-11-14T09:23 壓縮前 370064，壓縮後第一個請求 185625
  2026-11-14T10:08 壓縮前 369523，壓縮後第一個請求 182655
## 進到主對話的字元數
  Bash 的結果：529 次，717583 字元
  Read 的結果：32 次，247975 字元
  Agent 的結果：171 次，181512 字元
  Write 的結果：56 次，13037 字元
  完成通知：162 則，140225 字元，平均 865
  交回訊息：148 則，463196 字元，平均 3129
  其他：1 則，416 字元，平均 416
## 主對話 token（依 message.id 去重）請求 650 次，輸出 933805
```

## 整理

- 時間：全程 1007 分鐘，其中等使用者回答 673.4 分鐘（9 次提問，最長一次 519.9 分鐘），其餘約 334 分鐘
- agent：主對話派了 171 個。sonnet 的 157 個裡，21 個是 security-audit 的乾跑，其餘 136 個是照 `commands/dd-init.md` 新舊文字實跑的沙盒臂
  （含使用者同意的範圍擴大、以及重複跑的基準臂）。同一件工作裡腳本層的檢查（`scripts/dd-init-upgrade.sh --apply` exit 6）
  靠 `tests/test-dd-init-upgrade.sh` 的 exit 6 那組測試驗（`grep -n 'exit 6' tests/test-dd-init-upgrade.sh`）
- context：自動壓縮 12 次，其中 11 次在 `2026-11-14T05:46` 起的 4.4 小時內。壓縮前 36.7–38.5 萬 token，壓縮後第一個請求 13.3–19.0 萬
- 進到主對話的字元：Bash 的結果 717,583、subagent 的交回訊息 463,196（148 則，平均 3,129）、Read 的結果 247,975、
  Agent 的啟動回覆 181,512、完成通知 140,225
- 整個 session 的第一個請求（還沒做任何事，`2026-11-13T12:54`，在上面的時間範圍之前）輸入 97,571 token。
  這個數字來自「方法」節那條 jq，不在「當天輸出」裡；這件工作開始時 context 已經不是空的（3 分多鐘後就第一次壓縮）
- 行數（`dd8b5a9..139bc41`，來自「方法」節的 `git diff --numstat`，不在「當天輸出」裡）：`scripts/`、`commands/`、`tests/`、`agents/`、安裝腳本合計 +101／−13；`docs/reviews/` +1,626；
  `docs/measurements/` +860；`docs/designs/` +229；`skills/security-audit/CLAUDE.md` +189；其他文件 +76／−10；照抄上游的檔 +5,300。
  審查報告是逐字存的，行數不等於花的工夫

## 限制

- 只有一個 session、一件工作。那次的產品碼大半是指令文字，所以沙盒臂特別多，不算典型
- 字元數不是 token 數；中文一個字是多少 token 沒量
- 「136 個沙盒臂」是 157 減掉 description 含 `dry-run` 的 21 個，沒有逐個核對；「那 21 個是 security-audit 的乾跑」「其餘是沙盒臂」這兩個歸類
  來自那次的設計文件（`docs/designs/2026-11-14-security-audit-intake-design.md`），腳本只數得出 description 的字樣。
  步驟 4 的審查之後補查過一次：157 個裡不含 `dry-run` 的 description 全都是臂的名字（arm、docker、control、baseline、final-text、`v3…`）
- 腳本用字串比時間，結束那一秒裡帶毫秒的紀錄會被排除；當天查過，那一秒沒有紀錄
- 「交回訊息」是 `queued_command` 且 `isMeta` 的那一類；當天抽看開頭，都是 `[Subagent hand-back`
- subagent 自己用掉的 token 不在這支腳本裡（要讀各 agent 自己的紀錄檔）
- 等待時間含使用者不在電腦前的時間（最長那次跨夜）
- 同一個 session 之後的一段（換了模型、那個模型沒設自動壓縮視窗）量在 `2026-11-15-main-session-context.md`；兩份的時間範圍不重疊
