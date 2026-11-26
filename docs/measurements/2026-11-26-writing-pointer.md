# 全域 §3.10 改成指路句之後，寫註解時會不會去讀 `writing.md`（2026-11-26）

`cd46c74` 把全域 CLAUDE.md §3.10 的內容搬到 `skills/dd-loop/writing.md`，原位置只留一句「動筆或縮短既有文字之前,先用 Read 讀 `~/.claude/skills/dd-loop/writing.md` 整份」。
問：迴圈外、一個單純的「加註解」請求，全新的 session 會不會去讀它。

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

（跑完填）
