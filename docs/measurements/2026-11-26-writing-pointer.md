# 全域 §3.10 改成指路句之後，寫註解時會不會去讀 `writing.md`（2026-11-26）

`887661d` 把全域 CLAUDE.md §3.10 的內容搬到 `skills/dd-loop/writing.md`，原位置只留一句「動筆或縮短既有文字之前,先用 Read 讀 `~/.claude/skills/dd-loop/writing.md` 整份」。
問：迴圈外、一個單純的「加註解」請求，全新的 session 會不會去讀它。

> 量測當時部署的是維護者本機分支的全域模板：比這個 repo 的 `templates/global/CLAUDE.md` 在 §3.9「規則」與 §3.10 多幾段本機規則（因此 `writing.md` 多兩條重點）。兩臂之間的差別只有下面寫的那幾處。

## 做法（跑之前寫死）

- 部署版與 repo 相同（`cmp templates/global/CLAUDE.md ~/.claude/CLAUDE.md`）
- 拋棄式專案開在 scratchpad 底下（cwd 的 CLAUDE.md 不載入，使用者層的會），只有 `src/price.js` 一個檔
- prompt：「幫 src/price.js 的 calcTotal 加一段註解，說明它怎麼處理折扣與運費，直接改檔。」
- `claude -p "<prompt>" --model sonnet --output-format stream-json --verbose --max-budget-usd 2 --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}' --allowedTools "Read Edit Glob Grep" --disallowedTools "Write NotebookEdit Bash Agent Skill" < /dev/null`，3 發同時跑，各自一份拋棄式專案
- 一發有效：`result` 的 `subtype` 是 `success`、`permission_denials` 是空的
- 一發算「讀到」：第一個 Edit 之前有 Read，`file_path` 以 `skills/dd-loop/writing.md` 結尾
- 結論：有效的發裡讀到的過半 → 指路句留著；沒過半 → 停下回報，由使用者決定（改寫指路句或把內容搬回）

## 結果

**3 發有效、0 發讀到 ⇒ 沒過半，停下回報。** 三發都是 Read `src/price.js` 一次、接著 Edit，總共兩個工具呼叫；每發 0.22–0.23 美元。

前置檢查（跑完才補的，不是事先寫死的）：同一個拋棄式專案裡一發 haiku、不給任何工具，照貼 context 裡含「writing.md」的那一行，貼出來的與部署版 §3.10 那一句相同 ⇒ 指路句有載入，是沒被照做。

沒驗證：主對話平常用的 opus 會不會照做（這三發是 sonnet）；§3.9 那句教訓指路這次沒量。

## 補量：opus（sonnet 那批跑完之後、這批開跑之前寫的）

同一個 prompt、同樣的檔、同樣的旗標，只把 `--model sonnet` 換成 `--model opus`，3 發同時跑、各自新的拋棄式專案。判定式與結論規則同上；
沒過半 → 停下回報，由使用者決定要不要把 §3.10 搬回全域。

**3 發有效、3 發讀到 ⇒ 過半，指路句留著。** 三發都在第一個 Edit 之前 Read 了 `writing.md`（兩發先讀它、一發先讀 `price.js`），`message.model` 與 `modelUsage` 都只有 `claude-opus-5-5`；每發 0.39–0.42 美元。

所以這句指路對 opus 有效、對 sonnet 無效（各 3 發）。2026-11-26 起四個 agent 都是 sonnet：會改註解的 `code-simplifier` 沒有實測，照 sonnet 那批推測它不會去讀。

## 第二版指路句與 code-simplifier 派工句（opus 那批之後、這兩批開跑之前寫的）

改了兩處：全域 §3.10 的指路句改成「第一個 Edit / Write 之前必須先用 Read 讀 … 整份 —— 只加一行註解也算」；
`skills/code-simplifier/SKILL.md` 的 Prompt 模板「約束：」加一句「要改或新增註解時，第一個 Edit 之前先用 Read 讀 `~/.claude/skills/dd-loop/writing.md` 整份」。

- **甲（指路句，sonnet）**：部署後照第一批的做法再跑 3 發 sonnet，判定式與結論規則同上
- **乙（派工句）**：主對話用 Agent 工具派 `code-simplifier`（agent 定義 sonnet）3 發，prompt 是模板照填（範圍：拋棄式目錄裡的 `price.js`，檔案內容同上，另加一句「這個函式沒有註解，順手補上說明折扣與運費的註解」）；
  讀 subagent 紀錄檔，第一個 Edit 之前有 Read `skills/dd-loop/writing.md` 才算讀到，`message.model` 要是 sonnet
- 甲、乙各自過半才算過；沒過就停下回報

**甲：3 發有效、2 發讀到 ⇒ 過半。** 讀到的兩發都是先 Read `price.js`、再 Read `writing.md`、第三個工具呼叫才 Edit；沒讀到的那一發 Read `price.js` 後直接 Edit。全是 `claude-sonnet-5-5`，每發 0.16–0.19 美元。
同一個 prompt 的第一版指路句是 0／3（上面第一批）。

**乙：3 發、3 發讀到 ⇒ 過半。** 三個 `code-simplifier` subagent 的 `message.model` 都是 `claude-sonnet-5-5`；兩發先讀 `writing.md`、一發先讀 `price.js`，都在第一個寫檔動作之前。
它們改檔用的是 Write（不是 Edit），判定式寫的是 Edit；照「第一個寫檔動作之前」判，三發都算讀到。查第三發的時候它還沒寫檔，Read `writing.md` 已經發生。
