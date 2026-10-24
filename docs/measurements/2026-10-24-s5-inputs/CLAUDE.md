# docs/measurements/2026-10-24-s5-inputs

裁決審查 S5（`docs/designs/2026-10-23-裁決審查-design.md`）量測用的**凍結實驗輸入**：拿掉裁決者的兩組（A `dir`：Opus 審查者；B `dhk`：haiku 審查者），
父 session 就是主對話、自己查證。結果寫在上一層 `2026-10-23-reviewer-real-sessions.md`「拿掉裁決者的對照」一節，跟 S4 三組並排比。

## 檔案

- `direct.txt` —— 父 session 的完整任務說明：先派 ≥3 個審查者、派完才讀 diff 檔、等全部回來後逐條查證；Read 每次 300 行讀到最後一行；`{REVIEWER}` 決定審查者帶不帶 `model: "haiku"`
- `prepare.py` —— 從 S4 那份改來：快照與 diff 檔做法不變，brief 直接讀 `../2026-10-24-s4-inputs/briefs.txt`（跟 S4 逐字共用），prompt 換成 `direct.txt`
- `run.sh` —— 從 S4 那份改來：父 session 用 `--model opus`（它要查證），`--max-budget-usd 20`
- `stats.py` —— 從 S4 那份改來：沒有裁決者那一層（審查者是 `spawnDepth` 1），斷言父 session 是 opus；另記 `pre_s`（派工前）與 `post_s`（審查者都回來之後）
- `checks.py` —— 跑之前就寫好的補充檢查：每個讀者讀 diff 檔回傳的行號聯集缺幾行、父報告晚於審查者結束、工具結果裡的 `/Users/` 路徑、跨發存取；`--dump` 存父 session 的最後報告

## 約束

- **凍結**：量測文件的數字是用這一版輸入跑出來的；要改實驗就另開新目錄。唯一的例外：跑完後步驟 3 拿掉 `stats.py` 裡沒人讀的 `judge` 變數（`revs = d1`，輸出不變）
- 發代號是 `<段>-<組>-<序>`（例如 `G3-dhk-2`），組只有 `dir`、`dhk`
- `stats.py`、`checks.py` 只讀各發快照自己的 projects 目錄，不掃整個 `~/.claude/projects`
- `stats.py` 的洩題判定 `leaky()` 跟 S4 那份相同，負面測試用 `../2026-10-24-s4-inputs/test_leaky.py`（它讀的是 S4 那份 `stats.py`）
