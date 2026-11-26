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

（跑完填）
