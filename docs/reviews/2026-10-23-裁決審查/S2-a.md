# S2-a — 接上三個插入點

## 派工

- 範圍：`git diff c1c45d1 0f2be2b`（16 檔；commit 5fdd67e、77aea78、dfa7a77、0f2be2b）
- 取檔方式：整段 diff（GIF 排除）存成 scratchpad 的 `S2.diff`（567 行）交給它，前後文讀工作目錄；派工單 `S2_review_prompt.txt`，a、b 同一份
- 已給、標明不要重跑：本機 ci.yml 七個 step 全部 exit 0、`tests/test-install.sh` exit 0、verify-geometry 兩版通過（英文第一版溢出已縮短）、
  GIF 重出且第 0／40 幀雜湊不同、gate 放行 0f2be2b、dfa7a77 前兩個乾跑 subagent 的發現已修但**沒有再乾跑**
- 重點：三份 SKILL.md 與 §4.1 的交接矛盾、舊說法殘留、引別處的宣稱、進度表規則區塊；只讀，最多一次重現實驗
- a 實際約 2.8 分鐘、13 次工具（task-notification 的 `duration_ms` 167921）

## 發現

**Critical 0 / Important 1 / Minor 7**

- **A1** [Important] task-planner 測試清單題選「要修改」之後沒有路徑；完成條件照字面選「要修改」也算完成，步驟 5 寫進一份沒人選定的清單
- **A2** [Minor] 「沒跑成」路徑先問「重跑／不審」再問決策題，跟 plan-review 分批規則「接下來怎麼做放最後一批」對不上；第 3 輪路徑寫「同時問」也對不上
- **A3** [Minor] design-brainstorm 第 5 步要求「照第 6 步結構組好（含預估 N）」，第 6 步的結構沒有 N。**與 B7 重疊**
- **A4** [Minor] 兩份 README 寫「只問決策題與要加哪些測試」，漏了 plan-review 的「需使用者決定」
- **A5** [Minor] 設計文件 S2 驗收列「沒有『批准／要修改』那題」，但新的測試清單題本來就有「要修改」。**與 B4 重疊**
- **A6** [Minor] 設計文件寫「照現稿開工」、英文「files written after plan-review passes」，實作是「照現稿寫進設計文件」、「written after plan-review passes」。**與 B5 重疊**
- **A7** [Minor] task-planner「只切出 1 段」那條沒接 plan-review，§4.1 卻規定 N = 1 要審
- **A8** [Minor] plan-review「什麼時候跑」第 1 列沒排除 N ≥ 2，可能審兩次
- 需要外部查證：再乾跑一次（特別是「沒跑成 → 不審直接交」「測試清單選要修改」）；headless 下裁決者／審查者拿不拿得到 Bash；「題目會印成文字」的佐證

## 處置

- A1：task-planner 補「選『要修改』就照改再問，直到選『照這份清單加』；只改清單不算改到草稿、不再送審」；完成條件改成「對著最終草稿的測試清單選了『照這份清單加』」
- A2：plan-review 分批一節補「呼叫端寫明要等『接下來怎麼做』選完才問的題，放在它之後」；task-planner「沒跑成」那條改成「選『不審直接交』之後才問」
- A3：design-brainstorm 第 6 步結構補「預估 N 個功能段落」
- A4：兩份 README 補上「審查判定只有你能決定的題目」
- A5：驗收列改成「沒有整份計畫的批准題（舊版的『批准：寫進設計文件並 commit』；測試清單題自己的『要修改』不算）」
- A6：設計文件兩處字樣改成實作的字串（替換時一度把「使用者決定照現稿開工」誤換，已還原）
- A7：task-planner 1 段那句補「它仍是 §4.1 的複雜任務，計畫先交 plan-review」
- A8：plan-review 第 1 列改成「N = 1；N ≥ 2 等 task-planner 出草稿時再跑」
- 外部查證：再乾跑與 headless 實跑放在步驟 5，結果見設計文件 S2 底下的「步驟 3–8 紀錄」；「題目會印成文字」的佐證是 S1 驗收那發正向測試的 result（設計文件 S1「驗收結果」）
