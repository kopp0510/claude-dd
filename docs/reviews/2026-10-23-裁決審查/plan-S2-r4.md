# S2 計畫審查 第 4 輪（plan-review，使用者要求加跑）

檔名不用 `S` 開頭的理由同 `plan-S2-r2.md`。第 3 輪不通過後，使用者選「再審第 4 輪」。

## 派工

- 派工單：scratchpad 的 `judge_prompt_r4.txt`（輪次 4、照第 3 輪改寫後的 S2 一節與驗收列、事實補「使用者要求加跑」、plan mode 巢狀實測、第 3 輪報告）
- 裁決者：`general-purpose`、`model: opus`；約 11.5 分鐘（`duration_ms` 687951）、15 次工具；4 個 haiku 審查者

## 發現（裁決者報告重點）

**結論：`不通過（2 條重大）`**；需使用者決定：無

- 【採納（重大）】
  1. 輪4-R4-5：§4.1「N=1 的複雜任務不走 task-planner」那條路沒有行為驗收。**推翻輪1-R4-5 的駁回**：當時理由是「S1 驗收已含複雜需求會叫 plan-review」，
     但 S1 實測是沒叫、驗收移到 S2，而 S2 驗收列只測 task-planner 那條路
  2. 輪4-R4-2：「沒跑成 → 不審直接交」會把前幾輪留下的「需使用者決定」靜默丟掉（plan-review :61、:67、:72、:84–86）
- 【採納（小事）】8 條：完成條件用 plan-review 實際字眼（「不審直接交」、task-planner 自訂「照現稿開工」）；ExitPlanMode 被拒的路徑；
  design-brainstorm 驗到哪一層要寫明；headless 預算上限調高；task-planner／design-brainstorm 的 allowed-tools 補 Agent（design-brainstorm 加 AskUserQuestion）；
  流程圖副標點名 plan-review；配方寫法對齊；分批句只放 plan-review 第 4 步一次
- 【駁回】10 條（多數同前幾輪、無新證據；另含「plan mode 能不能用 AskUserQuestion」—— 裁決者讀 session 紀錄證實可以）
- 【需要外部查證】小事 1 條：plan mode 裡派 general-purpose 只測過 1 次，模型改派 Explore 的比例不知道

（完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 2 條重大、8 條小事全部寫進設計文件 S2 一節與 S2 驗收列（plan-review SKILL.md 的兩處補句列為 S2-2 的一部分，算 S1 產物修正、寫進 CHANGELOG）
- 外部查證小事：留著，不另外處理
- 第 4 輪仍不通過 → 停下，由使用者決定
- 觀察：四輪的重大條數 5 → 2 → 2 → 2，後兩輪抓的都是越來越邊角的路徑（沒跑成、第 3 輪停下、N=1）；
  每輪都找得到新東西，「全是小事」這個通過條件在跨三份規則檔的計畫上可能很難達到
