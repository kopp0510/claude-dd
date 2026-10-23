# S1-a — 新增 plan-review skill

## 派工

- 範圍：`git diff def4db0 3a5c718`（9 檔：plan-review SKILL.md、設計文件、量測文件、部署陣列、README×2、CLAUDE.md、架構文件、CHANGELOG）
- **取檔方式（新做法試跑）**：整段 diff 先存成一個檔（scratchpad 的 `S1.diff`，646 行）交給它，要它先讀這個檔、不要逐檔撈 diff；
  前後文讀工作目錄（乾淨，等於 HEAD）
- 已給、標明不要重跑：`tests/test-install.sh` exit 0；本機照 ci.yml 跑陣列一致性、數字宣稱一致性（skills 12 全對上）、
  CHANGELOG 已發布區塊、Skill hook 路徑、§7.2、迴圈步數四方與第五方，全部 exit 0；SKILL.md 已兩次乾跑
- 重點：新增句子裡引用別處的宣稱在 HEAD 成立嗎、SKILL.md 與設計文件互相矛盾嗎、新增 skill 的同步點、量測腳本會讓數字錯的邏輯錯誤；
  只用讀檔、grep、git，外部查證交回
- a、b 同一份 prompt。a 實際耗時約 2.4 分鐘、6 次工具（從它的 subagent 紀錄檔讀）

## 發現

**Critical 0 / Important 1 / Minor 5**

- **A1** [Important] `DD_PIPELINE_ARCHITECTURE.md` 部署歷史那句（「2026-08-04 盤點留存 9 skills…新增 gate-guard」）沒補 plan-review；
  前一行已改成 12，CI 只比對數字、不看這句。**與 B5 重疊**
- **A2** [Minor] 量測文件結論 2 引 §3.9 步驟 4 寫成 `git show HEAD:<路徑>`，模板原文是 `git show <commit>:<路徑>`；
  而且那條只在與 simplifier 並行時適用，「會逼它逐檔撈」是推論。**與 B2 重疊**
- **A3** [Minor] 設計文件「最慢一成超過 28 分鐘」，量測輸出第 90 百分位是 27.9。**與 B3 重疊**
- **A4** [Minor] 設計文件「插入點」與 S2-1 引的 §4.1 原句少了 `task-planner` 的反引號，照它 grep 或替換會找不到
- **A5** [Minor] CLAUDE.md「部署清單」新句寫「實證來源為 S1 驗收的實跑」，S1 還沒驗收。**與 B4 重疊**
- **A6** [Minor] 量測腳本在空樣本（某桶 0 筆、沒有快或慢的審查、meta 沒有對應 jsonl）會丟例外。
  a 自己抽了一份 jsonl 說 tool_use 沒有重複（dup 0）
- 需要外部查證：巢狀派工（裁決者等不等得到 3 個審查者都回來）repo 裡沒有實測紀錄

## 處置

- A1：補上（「2026-10-23 新增自製 plan-review，實證來源為…S1 驗收的實跑」）
- A2：量測文件結論 2、3 重寫：引文改成 `<commit>`，「逐檔撈」改標推論；結論改成「git 類佔大宗，但慢的審查每類都多好幾倍，
  證明不了『先交 diff 能加速』，留給 S4」（這條主要來自 B1）
- A3：設計文件改成「約 28 分鐘以上」
- A4：設計文件兩處補上反引號
- A5：S1 驗收實跑後成立 —— 見 `S1-judge-plan-S2.md`（裁決者實跑 S2 計畫：派 4 個審查者、全部回來才判、讀檔抽查 4 處都過、
  結論 `不通過（5 條重大）`）；`claude -p` 觸發測試見本段步驟 5 的紀錄
- A6：腳本補上空樣本防護。**a 的「dup 0」只抽一份**；全部 code-reviewer 紀錄掃一次有數百筆同 id 重複，腳本改成用 id 去重，
  重跑後數字更新（工具數原本高估約 7%）
- 巢狀派工：S1 驗收實跑已證實（見 A5）
