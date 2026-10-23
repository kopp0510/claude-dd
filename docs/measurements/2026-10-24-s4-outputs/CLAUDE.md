# docs/measurements/2026-10-24-s4-outputs

裁決審查 S4 量測的**結果**（輸入在旁邊的 `2026-10-24-s4-inputs/`，解讀在上一層 `2026-10-23-reviewer-real-sessions.md`「新做法對照」一節）。

## 檔案

- `stats.jsonl` —— `../2026-10-24-s4-inputs/stats.py` 對 14 發的輸出，一發一列（耗時、工具次數、費用、作廢理由）
- `reports/` —— 每個 agent 的最後一則文字，檔名 `<發代號>.d<層>.<agent id 前 6 碼>.<description>.md`（`d1` 是裁決者或舊組審查者、`d2` 是新組與 haiku 組的審查者）。量測文件的命中表用「檔名前綴 + 行號」指到這裡
- `extra_checks.py` —— 步驟 4 審查後補的三道檢查（Read 請求與實際回傳、工具結果裡的 `/Users/` 路徑、跨發存取）；`stats.py` 是凍結輸入，所以補在這裡
- `extra_checks.out` —— 它對 14 發的輸出

## 約束

- 這是當時的輸出，不要手改；工作目錄路徑已換成 `<s4>`
- 重跑任何腳本都要 session 暫存目錄裡的快照、`logs/` 與 `~/.claude/projects/` 底下各快照的紀錄；session 清掉就重跑不了
