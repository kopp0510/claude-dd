# docs/measurements/2026-11-15-reviewer-effort

審查者思考強度實驗（`docs/designs/2026-11-15-speed-cost-design.md` 的 S2）的**凍結實驗輸入**：審查者帶 `effort: "medium"` 對 `"low"`，
甲部分是計畫審查（裁決者派的 haiku 審查者），乙部分是步驟 4（主對話派的 opus `code-reviewer`）。方法、正確答案、判準與結果在上一層 `2026-11-15-reviewer-effort.md`。

## 檔案

- `judge.txt` —— 甲的裁決者任務說明：2026-11-14 那份計畫第 1 輪實際送出的裁決者 prompt，只改兩處 —— 專案根目錄換成 `{ROOT}`、派審查者那一句加上 `effort "{EFFORT}"`。
  裡面的 `{輪次}`、`《…》` 是原 prompt 的字面內容，不是佔位
- `parent-a.txt` —— 甲的父 session 說明：只派一個裁決者（general-purpose、opus、明寫 `effort "medium"`），叫它讀 `judge.txt` 填好的那份
- `parent-b.txt` —— 乙的父 session 說明：同一則訊息派剛好 3 個 `code-reviewer`、帶該臂的 `effort`，每個只給一句「先讀哪個檔」
- `reviewer-b.txt` —— 乙的審查者任務說明範本（職責、只准讀的路徑、讀 diff 檔的方法、重點檔案、範圍說明）
- `prepare.py` —— 產生每一發的快照 repo、diff 檔與 prompt 檔；乙的快照與 diff 檔做法照 `../2026-10-24-s5-inputs/prepare.py`，範圍說明讀 `../2026-10-24-s4-inputs/briefs.txt`
- `run.sh` —— 跑一發：父 session `--model haiku`、`--settings '{"advisorModel":""}'`、`--max-budget-usd 8`、硬逾時 40 分鐘、`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0`（不設的話父 session 最後一輪結束 10 分鐘後，還在跑的背景 subagent 會被停掉）
- `stats.py` —— 每一發的秒數、token、工具次數、費用、每個審查者紀錄檔裡的 `effort`、作廢檢查、洩題檢查命中清單；`--dump` 把每個 subagent 交回的報告存成檔

## 約束

- **凍結**：量測文件的數字是用這一版輸入跑出來的；要改實驗就另開新目錄。例外一個：`run.sh` 在第一次跑（`P-med-1`，作廢）之後加了 `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0`，算數的每一發都是用加了之後的版本跑的
- 發代號是 `<素材>-<臂>-<序>`：素材 `P`（甲）、`G2`、`G3`（乙）；臂 `med`、`low`（例如 `G3-low-2`）
- 工作目錄（快照、prompt 檔、stream-json）放 scratchpad，不進 repo；`prepare.py` 填好的 prompt 檔含本機絕對路徑，也不進 repo
- 乙的三個重點檔案由 `prepare.py` 的 `split3()` 照 `git diff --name-only` 的順序平均切，不看已知錯誤在哪個檔
- `stats.py` 只讀各發快照自己的 projects 目錄；審查者的強度讀紀錄檔 assistant 那幾筆的 `effort` 欄位，不讀 prompt
- `stats.py` 的洩題判定 `leaky()` 列出來的命中要人工逐筆判（真的讀到快照外才算）；比路徑前綴時結尾要帶分隔字元（`G2/` 不可以吃掉 `G2-low-1` 的開頭，2026-11-15 寫的時候錯過一次）
