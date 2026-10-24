# docs/measurements/2026-10-24-s5-outputs

裁決審查 S5 量測的**結果**（輸入在旁邊的 `2026-10-24-s5-inputs/`，解讀在上一層 `2026-10-23-reviewer-real-sessions.md`「拿掉裁決者的對照」一節）。

## 檔案

- `stats.jsonl` —— `../2026-10-24-s5-inputs/stats.py` 對 8 發的輸出，一發一列（耗時、派工前 `pre_s`、收尾 `post_s`、工具次數、費用、作廢理由）
- `checks.out` —— `../2026-10-24-s5-inputs/checks.py` 的輸出（每個讀者讀 diff 檔全檔缺幾行、父報告晚於審查者、工具結果裡的 `/Users/`、跨發存取）
- `sec1.py` —— 跑完才補的檢查：每個讀者對 diff 檔「第一段」（`git diff` 本體）缺幾行。`checks.py` 算的是全檔；`direct.txt` 要求讀完全檔，實際多數讀者沒讀完第二段（整檔內容），所以另外用第一段當比較基準。S4 那 12 發也一起算
- `sec1.out` —— 它對 S5 8 發與 S4 12 發的輸出（`P` 是父 session，`r` 是審查者；S4 的裁決者是 general-purpose，不列）
- `reports/` —— 每個審查者的最後一則文字（`d1`）與父 session 的最後報告（`d0.parent`），檔名 `<發代號>.d<層>.<agent id 前 6 碼>.<description>.md`

## 約束

- 這是當時的輸出，不要手改；工作目錄路徑已換成 `<s5>`
- 重跑任何腳本都要 session 暫存目錄裡的快照、`logs/` 與 `~/.claude/projects/` 底下各快照的紀錄；session 清掉就重跑不了
