# 全域 §3.9「規則」改成指路句之後，碰到併發 race 會不會去讀 `lessons.md`（2026-11-26）

`cd46c74` 把 §3.9「規則」的 8 條驗證教訓搬到 `skills/dd-loop/lessons.md`，原位置留一句「改併發 / 資料庫鎖…時:先用 Read 讀 `~/.claude/skills/dd-loop/lessons.md` 對應的那一條」。
題目沿用 `2026-11-20-domain-traps-pointer.md`（同一個 prompt、同樣結構的 `src/orders.js`），那次量的是指向 dd-loop SKILL.md 的指路。

## 做法（跑之前寫死）

- 部署版與 repo 相同；拋棄式專案開在 scratchpad 底下，`package.json` 與 `src/orders.js`（`reserveStock`：`BEGIN` → `SELECT available` → 不夠就 `ROLLBACK` → `INSERT … ON CONFLICT (sku) DO UPDATE SET available = $2` → `COMMIT`，沒有鎖）
- prompt：「src/orders.js 的 reserveStock,兩個請求同時進來會超賣。請告訴我要怎麼改(先不要改檔),以及改完要怎麼驗證真的修好了。」
- `claude -p "<prompt>" --model <opus|sonnet> --output-format stream-json --verbose --max-budget-usd 2 --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}' --allowedTools "Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent Skill" < /dev/null`
- 兩臂：opus 3 發、sonnet 3 發，6 發同時跑，各自一份拋棄式專案
- 一發有效：`subtype` 是 `success`、`permission_denials` 是空的
- 一發算「讀到」：有 Read，`file_path` 以 `skills/dd-loop/lessons.md` 結尾。另記回答裡有沒有「隔離級別」（只記、不當判準）
- 每臂各自判：讀到的過半 → 那個模型這句指路有效；沒過半 → 停下回報

## 結果

6 發都有效。**opus 3／3 讀到 ⇒ 有效；sonnet 0／3 ⇒ 沒過半，停下回報。**

| 臂 | 讀到 `lessons.md` | 回答有「隔離級別」 | 每發費用 |
|---|---|---|---|
| opus | 3／3（都在讀完 `orders.js`、`package.json` 之後） | 3／3 | 0.39–0.43 美元 |
| sonnet | 0／3（只讀 `orders.js`，有一發多讀 `package.json`） | 0／3 | 0.16–0.18 美元 |

`message.model` 各臂只有 `claude-opus-5-5`／`claude-sonnet-5-5`。與 `2026-11-26-writing-pointer.md` 第一批同型：同一句指路，opus 會照做、sonnet 不會。
