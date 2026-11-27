# 全域 §3.9「規則」改成指路句之後，碰到併發 race 會不會去讀 `lessons.md`（2026-11-26）

`887661d` 把 §3.9「規則」的 8 條驗證教訓搬到 `skills/dd-loop/lessons.md`，原位置留一句「改併發 / 資料庫鎖…時:先用 Read 讀 `~/.claude/skills/dd-loop/lessons.md` 對應的那一條」。
題目沿用 `2026-11-20-domain-traps-pointer.md`（同一個 prompt、同樣結構的 `src/orders.js`），那次量的是指向 dd-loop SKILL.md 的指路。

> 量測當時部署的是維護者本機分支的全域模板：比這個 repo 的 `templates/global/CLAUDE.md` 在 §3.9「規則」與 §3.10 多幾段本機規則（因此 `writing.md` 多兩條重點）。兩臂之間的差別只有下面寫的那幾處。

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

## 第二版指路句與步驟 4 派工句（上面那批之後、這兩批開跑之前寫的）

改了兩處：全域 §3.9 的指路句改成「改檔、回答怎麼改或怎麼驗證之前,必須先用 Read 讀 … 整份 —— 只是問做法、還沒要改檔也算」；
`skills/dd-loop/SKILL.md` 步驟 4 加一條：diff 動到併發等幾類時，派工 prompt 另寫「審之前先用 Read 讀 `~/.claude/skills/dd-loop/lessons.md` 整份」。

- **甲（指路句，sonnet）**：部署後照上面 sonnet 臂再跑 3 發，判定式同上
- **乙（派工句）**：主對話用 Agent 工具派 `code-reviewer`（agent 定義 sonnet）3 發；prompt 給「把沒有交易的 `reserveStock` 改成 `BEGIN … COMMIT` 包起來」的 diff（改後就是上面那份 `orders.js`）、寫明審查者職責與那句派工句；
  讀 subagent 紀錄檔，有 Read `skills/dd-loop/lessons.md` 才算讀到，`message.model` 要是 sonnet。另記報告有沒有指出「包進交易擋不住 race／要先取鎖」（只記、不當判準）
- 甲、乙各自過半才算過；沒過就停下回報

**甲：3 發有效、0 發讀到 ⇒ 沒過，停下回報。** 三發都只讀 `orders.js`（兩發多讀 `package.json`），回答都沒有「隔離級別」；`claude-sonnet-5-5`，每發 0.16–0.18 美元。第二版指路句對 sonnet 主對話沒有效果。

**乙：3 發、3 發讀到 ⇒ 過。** 三個 `code-reviewer` subagent 都是 `claude-sonnet-5-5`，第一個工具呼叫都是 Read `lessons.md`、第二個 Read `orders.js`，之後交回。
三份報告都把「只包交易擋不住 race（read committed 下兩邊讀到同一份 pre-image）」列成 Critical，並引了 lessons.md 第 1 條；三份都另提「列不存在時要用 advisory lock」與「拉寬窗的可控實驗」。

結論：派工 prompt 裡寫明的一句，sonnet 會照做（這裡 3／3、`writing-pointer` 那份的 code-simplifier 也是 3／3）；只放在全域 CLAUDE.md 的指路句，sonnet 主對話兩版都是 0／3，opus 是 3／3。
