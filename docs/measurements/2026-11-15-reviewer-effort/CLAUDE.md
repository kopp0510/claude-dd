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
- `outside.py` —— 補充的洩題掃描（跑完甲之後加的）：列出工具呼叫裡指到工作目錄以外暫存區、`/tmp`、`../` 的，人工判。`stats.py` 的 `leaky()` 抓不到這一類
- `deid.py` —— 把 `stats.py --dump` 存下的報告去識別後複製進 `out/reports/`；有殘留的那一份不寫、印出檔名
- `table.py` —— 從 `out/stats.jsonl` 印結果表與判準要比的數字
- `out/stats.jsonl` —— 算數的每一發一行（`stats.py` 的輸出；洩題命中只留筆數，原文含本機路徑）；`out/reports/` —— 每個 subagent 交回的報告（去識別後）。作廢的 `P-med-1` 只有審查者的報告、不在 `stats.jsonl`
- `timeline.py` —— 甲各發在時間軸上的位置（每個審查者相對裁決者的起訖秒數、Agent 呼叫出現的秒數與 prompt 字元數）；步驟 4 審查之後加的，輸出存在 `out/timeline.md`

## 約束

- **凍結**：量測文件的數字是用這一版輸入跑出來的；要改實驗就另開新目錄。例外兩個（另一個在本條最後）：`run.sh` 在第一次跑（`P-med-1`，作廢）之後加了 `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0`，算數的每一發都是用加了之後的版本跑的。分析用的 `stats.py`、`outside.py` 跑完之後改過（步驟 3 的簡化；`stats.py` 另補兩個作廢檢查），算數的 5 發重跑輸出逐位元組相同，細節在量測文件「限制」。
  另一個例外：2026-11-28 git 歷史改寫（作者身分統一）後，`prepare.py` 的 `PLAN_REV`、`RANGES` 與 `judge.txt` 裡的 commit 編號換成新編號：每個 commit 的內容樹與改寫前相同，產生的快照與 diff 檔不變；`judge.txt` 因此跟當時實際送出的 prompt 差在這個編號
- 發代號是 `<素材>-<臂>-<序>`：素材 `P`（甲）、`G2`、`G3`（乙）；臂 `med`、`low`（例如 `G3-low-2`）
- 工作目錄（快照、prompt 檔、stream-json）放 scratchpad，不進 repo；`prepare.py` 填好的 prompt 檔含本機絕對路徑，也不進 repo
- 乙的三個重點檔案由 `prepare.py` 的 `split3()` 照 `git diff --name-only` 的順序平均切，不看已知錯誤在哪個檔
- `stats.py` 只讀各發快照自己的 projects 目錄；審查者的強度讀紀錄檔 assistant 那幾筆的 `effort` 欄位，不讀 prompt
- `stats.py` 的洩題判定 `leaky()` 列出來的命中要人工逐筆判（真的讀到快照外才算）；比路徑前綴時結尾要帶分隔字元（`G2/` 不可以吃掉 `G2-low-1` 的開頭，2026-11-15 寫的時候錯過一次）。
  已知的誤報：自己的快照路徑後面接全形括號或換行（審查者範本的「專案根目錄：<快照>（規則在…」、Bash 的 `cd <快照>` 換行）不在放行的分隔字元裡，會被列出；
  判的時候拿完整的工具輸入看，不要看 `stats.py` 印的前 200 字元（會截在路徑中間）。要進 repo 的輸出用 `../2026-11-15-plan-review-pack/pubstats.py` 換成筆數
