# S2 計畫審查 第 2 輪（plan-review）

檔名刻意不用 `S` 開頭：gate 把 `S<數字>*.md` 當成「這段的 code-review 報告」，計畫審查的報告不該替步驟 4 頂帳。

## 派工

- 派工單：scratchpad 的 `judge_prompt_r2.txt`（由第 1 輪那份改出：輪次 2、計畫換成照第 1 輪改寫後的 S2 一節與 S2 驗收列、
  事實補上 `--force` 已部署、S1 觸發測試結果、使用者第 1 輪的決定、ffmpeg／playwright 查到的狀態、「這輪改了哪裡」、第 1 輪報告全文）
- 裁決者：`general-purpose`、`model: opus`，背景執行；約 5.7 分鐘（`duration_ms` 341041）、12 次工具
- 裁決者自己的改動：《計畫與事實》沒有逐字貼給審查者，改成要審查者 Read 派工單第 6–190 行

## 發現（裁決者報告原文）

【派工】
派了 4 個審查者，都用 haiku，同一則訊息裡平行派出。沒有重派，也沒有補派。
- 輪2-R1：前提成不成立，以及 plan-review SKILL.md 跟改寫後的三個插入點接不接得上
- 輪2-R2：漏掉的同步點，範圍是全 repo 的批准類敘述與各層 CLAUDE.md 的同批規則
- 輪2-R3：範圍與驗證，看驗證指令與驗收判定抓不抓得到錯、順序，以及重出 GIF 的流程
- 輪2-R4：全面，特別看第 1 輪改寫後新寫的句子跟三份 SKILL.md 有沒有矛盾，以及進度表規則區塊
為什麼派 4 個：這一輪的計畫是第 1 輪改寫的結果，新寫的句子集中在 task-planner 和 plan-review 的交接，所以在三個專攻方向之外多派一個專看新句子的。

【讀檔檢查】
- 輪2-R1：過。抽查 skills/plan-review/SKILL.md:72。
- 輪2-R2：過。抽查 skills/task-planner/SKILL.md:79。
- 輪2-R3：過。抽查 scripts/check-claude-md.sh 的 CODE_EXT（含 `py`），以及 diagrams/src/CLAUDE.md:105–106。
- 輪2-R4：過。抽查根目錄 CLAUDE.md:66。
- 重派、補派：無。

【採納（重大）】
1. 來源：輪2-R2-1、輪2-R4-1、輪2-R1-1｜S2-2 留下 task-planner 的決策題（「併進 plan-review 第 4 步一起問」），S2 驗收列卻寫「（只問測試清單那題）」，互相矛盾；計畫也沒寫哪些決策題要留。執行者可能為了讓驗收轉綠把決策題刪掉。｜查證：skills/task-planner/SKILL.md:79、:82；skills/plan-review/SKILL.md:72；設計文件第 12 行。｜等需使用者決定第 1 題，在 S2-2 寫明留下哪幾類決策題、怎麼併問、分批規則；驗收改成「沒有問整份計畫的批准題；只出現測試清單題與留下的決策題」。
2. 來源：輪2-R1-2、輪2-R4-2、輪2-R3-4｜S2 驗收用 `claude -p`，照專案寫法 `Agent` 被擋，plan-review 派不出裁決者，「沒有再問批准題」會自動成立而假綠；headless 也沒有 AskUserQuestion。｜查證：根目錄 CLAUDE.md:66、:70；skills/plan-review/SKILL.md:4、:40、:84–86。｜驗收寫明放行 `Agent` 並確認 `permission_denials` 沒有它；jsonl 要看到裁決者回來、結論三選一；寫明怎麼從輸出文字判；「通過後寫檔並 commit」另在拋棄式 repo 實跑、`git log -1` 核對。

【採納（小事）】
- 輪2-R3-1｜改 `gen_planner.py`（`.py` 在 CODE_EXT）要同批 staged `diagrams/src/CLAUDE.md`，否則被 gate 擋。
- 輪2-R3-2、R3-3、R3-5、R4-5｜重出 GIF：暫存目錄跑、只覆蓋 task-planner 兩張、雜湊檢查、看分組標題有沒有壓線。
- 輪2-R1-4｜design-brainstorm 步驟 8 標題與硬閘門第 16 行會過期，`grep -n '批准'` 抓不到。
- 輪2-R1-6、R3-6｜併題後「一次最多 4 題」「批准題放最後一批」要改還是刪，計畫沒寫。

【駁回】
- 輪2-R1-3｜部署前跑 `claude -p` 讀到舊句｜驗收已寫部署後；乾跑讀的是 repo 版。
- 輪2-R1-5｜task-planner「冒出新工作，同意才加一列」是另一個批准點｜那是問要不要加新工作，不是批准計畫。
- 輪2-R2-2｜沒點名 design-brainstorm :13｜`grep -n '批准'` 會命中。
- 輪2-R2-3｜沒寫 gen_planner.py 換成什麼字｜實作細節，驗證已有 grep、幾何檢查、看 GIF。
- 輪2-R2-4｜S2-2 與 S2-3 之間 README 暫時落後｜同輪1-R3-8，無新證據。
- 輪2-R2-5｜grep 抓不到「同意」型的批准｜命中處是計畫明寫要保留的；會漏的已另外採納。
- 輪2-R4-3｜task-planner :80、:82 與 design-brainstorm :67 沒逐句列｜都含「批准」，grep 會命中。
- 輪2-R4-4｜沒寫標 IN_PROGRESS、記起點｜進度表規則區塊已規定。

【需使用者決定】
1. 來源：輪2-R2-1、輪2-R4-1｜task-planner 步驟 4 原本的決策題還要不要問？｜(a) 全部保留，跟測試清單題一起問 (b) 只留語意題與測試清單題 (c) 都不問｜建議 (a)｜卡住採納（重大）第 1 條。

【需要外部查證】
- 輪2-R3-7｜小事｜plan mode 下能不能派 Agent subagent。
- 輪2-R3-8、輪2-R1-7｜小事｜本機 playwright 能不能照重出流程跑起來。

【結論】
不通過（2 條重大）

（【採納（小事）】【駁回】【需使用者決定】的理由欄為節錄；完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 需使用者決定第 1 題：使用者選 (a)「照樣問」
- 2 條重大、4 條小事全部寫進設計文件 S2 一節與 S2 驗收列
- 外部查證：plan mode 派 subagent —— 原本寫「本 session 設計討論期間就在 plan mode 裡派過」，**這句是錯的**（第 3 輪裁決者讀 session 紀錄：
  14:50 的兩次巢狀測試在 14:51:29 EnterPlanMode 之前，plan mode 期間沒有任何 Agent 呼叫）；改成實測，結果見 `plan-S2-r3.md`。playwright 留在 S2 開工前提
- 第 3 輪（最後一輪）照改寫後的 S2 送審
