# docs/measurements/2026-11-26-sonnet-reviewer

code-reviewer 改成 sonnet（加上只給 4 個工具）之後，步驟 4 的命中跟 2026-10-24 的 opus 審查者比。結果寫在上一層 `2026-11-26-sonnet-reviewer.md`。

## 檔案

- `prepare.py`、`stats.py`、`checks.py`、`direct.txt` —— 從 `../2026-10-24-s5-inputs/` 複製（那邊是凍結輸入）。多兩組 `son` 與 `mix`（2026-11-26 後加，派 1 個 opus 審查者負責最需要推理的部分、其餘 sonnet；`stats.py` 斷言剛好 1 個 opus）。`son`：`prepare.py` 給它的派工句跟 `dir` 逐字相同（不帶 model 參數，所以吃 agent 定義的 sonnet），`stats.py` 斷言審查者是 sonnet；`direct.txt` 與原檔 `diff` 相同
- `run.sh` —— 同 `../2026-10-24-s5-inputs/run-noadvisor.sh`，多設 `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0`

## 約束

- 發代號 `<段>-son-<序>`、`<段>-mix-<序>`；`prepare.py` 讀 `../2026-10-24-s4-inputs/briefs.txt`（相對路徑，別搬這個目錄）
- 一次最多同時跑 2 發
- 2026-11-28 git 歷史改寫（作者身分統一）後，`prepare.py` 的 `RANGES` 換成新的 commit 編號：每個 commit 的內容樹與改寫前相同，產生的快照與 diff 檔不變
