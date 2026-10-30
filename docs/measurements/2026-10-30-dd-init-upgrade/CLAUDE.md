# docs/measurements/2026-10-30-dd-init-upgrade

`/dd-init` 升級蓋章區塊（rev 12 → 13）的沙盒實測：部署版 `/dd-init` 在全新 `claude -p` session 裡跑 Phase 0、1，
看它有沒有先 `--plan` 再問、只在同意時 `--apply`、在地內容有沒有留在原本那一步（全域 CLAUDE.md 瘦身 S2-2，測試清單第 4 項）。

## 檔案

- `setup.sh` —— 建 8 個拋棄式 repo（`OUT` 指定目錄，預設暫存目錄）：rev 12 區塊加在地行（同意／拒絕／React／CLI）、
  `### 工作流程` 底下的 6a9addd 區塊（rental 型）、步驟 6 前有 curl 指令的、已是 rev 13 的、沒有 CLAUDE.md 的
- `run.sh <案例> <同意|拒絕>` —— 跑 `claude -p "/dd-init …"`；沒有 AskUserQuestion，prompt 直接告訴它升級題的答案
- `check.sh` —— 從 jsonl 抽工具呼叫順序與最終 CLAUDE.md 的計數
- `results.txt` —— 2026-10-30 那一次的 `check.sh` 輸出（路徑換成 `<OUT>`）；8 例合計 US$5.08
- `results-after-review.txt` —— S2 步驟 4 修正後、重新部署再跑一次的 `check.sh` 輸出（步驟 5）；8 例合計 US$5.16，結果與第一次相同
- `*.prompt.txt` —— 每個案例的 prompt 原文

## 此層慣例

- 原始 stream-json 不進 repo（init 訊息有編碼過的本機路徑），只留 `check.sh` 抽出來的欄位
- 跑之前要先 `./install-dd-pipeline.sh --force`：headless session 載入的是 `~/.claude/` 的部署版
- 這種 session 答不了 AskUserQuestion，所以「問了沒」只看得到它有沒有先跑 `--plan`、拒絕時有沒有動檔，看不到問題本身

## 與上層的關係

引用它的是 `docs/designs/2026-10-30-global-claude-md-slim-design.md` 的 S2。
