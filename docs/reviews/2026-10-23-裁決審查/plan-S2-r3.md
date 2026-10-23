# S2 計畫審查 第 3 輪（plan-review，最後一輪）

檔名不用 `S` 開頭的理由同 `plan-S2-r2.md`。

## 派工

- 派工單：scratchpad 的 `judge_prompt_r3.txt`（由第 2 輪那份改出：輪次 3、計畫換成照第 2 輪改寫後的 S2 一節與 S2 驗收列、
  事實補上使用者第 2 輪的決定、「這輪改了哪裡」、第 1 輪報告改成路徑、第 2 輪報告全文）
- 裁決者：`general-purpose`、`model: opus`，背景執行；約 7.7 分鐘（`duration_ms` 460904）、12 次工具
- 4 個 haiku 審查者，裁決者要它們 Read 派工單第 6–176 行

## 發現（裁決者報告重點）

**結論：`不通過（2 條重大）`**；需使用者決定：無

- 【採納（重大）】1 條：輪3-R4-2(b)、輪3-R1-3 —— task-planner 的決策題與測試清單題錨在 plan-review 第 4 步，
  但「第 3 輪仍不通過」（plan-review SKILL.md:67–68）與「沒跑成 → 不審直接交」（:84–86）兩條路走不到第 4 步，
  計畫沒寫這兩條路上要不要問；完成條件「plan-review 通過」在後者永遠達不到
- 【需要外部查證】標重大 1 條：輪3-R4-E1 —— plan mode 裡能不能派裁決者、裁決者再派審查者並拿回結果。
  裁決者讀 session 紀錄，證明第 2 輪處置「本 session 在 plan mode 裡派過 subagent」不成立
  （14:50:34Z、14:50:56Z 的 Agent 在 14:51:29Z EnterPlanMode 之前；plan mode 期間沒有 Agent 呼叫）
- 【採納（小事）】5 條：分批只留一個門檻（決策題＋測試清單題＋需使用者決定合計 >4 才分批）；headless 驗收加 `--forward-subagent-text`、
  兩筆 result 都讀；根目錄 CLAUDE.md 觸發測試配方要補「放行 Agent」並改掉「批准之後的步驟」；`diagrams/src/CLAUDE.md:14` 點名補 plan-review；
  架構文件改成「已核對不需改」；以及上面那句第 2 輪處置的事實更正
- 【駁回】11 條（決策題接不上第 4 步、`無法判定` 假綠、headless 沒 AskUserQuestion、拋棄式 repo 怎麼回答、
  design-brainstorm :13/:67、步驟 4 標題、只重出兩張、grep 回 0、雜湊抓不到文字、記起點、規則區塊逐句）——多數是前兩輪駁回過、沒有新證據
- 【需要外部查證】小事 2 條：headless 下裁決者／審查者拿不拿得到 Read、Grep；playwright 能不能跑

（完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 重大第 1 條：照改。task-planner 步驟 4 寫明三條路徑都要問決策題與測試清單題；完成條件改成
  「plan-review 通過，或使用者在第 3 輪不通過／沒跑成時選了繼續；而且決策題與測試清單題都問過」；乾跑多跑「沒跑成 → 不審直接交」分支
- 外部查證重大（plan mode 巢狀派工）：**實測成立**。拋棄式專案裡跑
  `claude -p "<prompt>" --output-format stream-json --verbose --forward-subagent-text --permission-mode plan --allowedTools "Agent Read Glob Grep"`，
  prompt 存在 scratchpad 的 `trig/planmode.prompt.txt`：
  - init 的 `permissionMode` 是 `plan`
  - 兩個 Agent 呼叫：`toolu_01F8nWdBSQHYJh3WpZ4gqp4h`（parent null，主 session 派第一層）→ `toolu_01G7fEzYRCY4K8B6JMjhSXA4`（parent 是前者，第一層派第二層）
  - 最後 result 第一行是 `NESTED_OK`，`permission_denials` 空
  - 注意：plan mode 的系統提示說「規劃階段只用 Explore subagent」，這是文字指示、不是擋；主 session 照樣派了 general-purpose。
    但它是會讓模型猶豫的軟限制，design-brainstorm 的 plan-review 插入點要明寫「plan mode 裡照樣派 general-purpose 裁決者」
- 小事 5 條：全部寫進設計文件 S2 一節與 S2 驗收列；第 2 輪處置那句已在 `plan-S2-r2.md` 更正
- 外部查證小事：留給 S2 驗收實跑
- 第 3 輪仍不通過 → 照 plan-review 第 3 步停下，由使用者決定要不要照現稿開工
