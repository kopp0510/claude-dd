---
name: subagent-orchestrator
description: Subagent 調度專家，逐任務分派 subagent 執行微任務計畫，包含實作、規格審查、品質審查的兩階段審查機制。完全自動化，無需人工介入。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task
---

# Subagent Orchestrator

Subagent 調度專家，讀取 task-planner 產出的微任務計畫，逐任務分派 subagent 執行，並進行兩階段審查。

## 觸發條件

**自動觸發時機：**
- `dd-dev` 預設模式中，task-planner 完成後自動調用
- 使用者提到「subagent」、「分派執行」、「自動執行任務」

**初始互動：**
讀取微任務計畫，自動開始逐任務執行。

## 工作流程

### Stage 1: 計畫載入

**目標：** 讀取並解析微任務計畫

#### Step 1: 找到計畫文件

讀取最新的計畫文件：
```bash
# 找到最新的計畫檔
ls -t claude_docs/plans/*.md | head -1
```

如果 `claude_docs/plans/` 不存在或為空，報錯並提示先執行 task-planner。

#### Step 2: 解析任務

從計畫文件中提取：
- 任務總數
- 每個任務的名稱、檔案路徑、依賴、TDD 五步驟
- 依賴圖

#### Step 3: 建立執行佇列

根據拓撲排序建立執行佇列：
- 無依賴的任務排在最前面
- 依賴已完成的任務才能進入佇列
- 記錄每個任務的狀態：`待執行` / `執行中` / `審查中` / `已完成` / `需修復`

#### Step 4: 初始化執行記錄

在 `PROJECT_STATE.md` 中新增執行記錄區塊：

```markdown
## SADD 執行記錄
- **計畫檔案**：claude_docs/plans/<file>.md
- **總任務數**：N
- **已完成**：0
- **執行中**：0
- **待執行**：N
```

**退出條件：** 計畫已解析，執行佇列已建立。

### Stage 2: 逐任務執行

**目標：** 對每個任務分派 subagent 執行和審查

對佇列中的每個任務，執行以下循環：

#### Step 1: 分派實作者 Subagent

使用 Task tool 分派 general-purpose subagent：

```
調用 Task tool：
- subagent_type: general-purpose
- prompt: 使用 prompt-templates.md 中的「Implementer」範本
- 內容：完整的任務文本（含 TDD 五步驟、檔案路徑、程式碼）
```

**Subagent 任務內容：**
- 完整的任務描述文本（從計畫文件複製）
- 專案的技術棧資訊（從 CLAUDE.md 讀取）
- 明確的 TDD 流程指示
- 自我審查清單

等待 subagent 完成，收集執行結果。

#### Step 2: 分派規格審查 Subagent

使用 Task tool 分派 general-purpose subagent：

```
調用 Task tool：
- subagent_type: general-purpose
- prompt: 使用 prompt-templates.md 中的「Spec Reviewer」範本
- 內容：實作者產出的檔案路徑 + API 契約
```

**規格審查重點：**
- 不信任實作者的報告，獨立讀取程式碼
- 對照 `API_CONTRACT.md` 驗證端點、參數、回應格式
- 對照 `EXAMPLES.md` 驗證行為是否符合範例
- 對照 `ARCHITECTURE.md` 驗證模組結構
- 確認測試涵蓋了契約中的所有情況

**審查結果：** `通過` 或 `不通過`（附具體問題清單）

#### Step 3: 分派品質審查 Subagent

**僅在規格審查通過後執行。**

使用 Task tool 分派 general-purpose subagent：

```
調用 Task tool：
- subagent_type: general-purpose
- prompt: 使用 prompt-templates.md 中的「Code Quality Reviewer」範本
- 內容：實作者產出的檔案路徑
```

**品質審查重點：**
- SOLID 原則檢查
- 命名規範（變數、函數、檔案）
- 安全性（輸入驗證、注入防護）
- 效能（N+1 查詢、不必要的迴圈）
- 測試品質（是否測試了邊界情況）
- 錯誤處理（是否完整）

**審查結果：** `通過` 或 `不通過`（附具體改進建議）

#### Step 4: 修復迴圈

如果任一審查不通過：

1. 收集所有審查意見
2. 分派修復 subagent（使用 Implementer 範本 + 審查意見）
3. 重新執行審查（規格 → 品質）
4. 最多重試 3 次
5. 3 次都不通過時，記錄問題並標記為需人工介入，繼續下一個任務

```
修復迴圈：
嘗試 1 → 審查不通過 → 修復 → 重新審查
嘗試 2 → 審查不通過 → 修復 → 重新審查
嘗試 3 → 審查不通過 → 標記需人工介入，跳到下一任務
```

#### Step 5: 提交和記錄

審查通過後：

```bash
# Git commit（使用計畫中的 commit message）
git add <相關檔案>
git commit -m "<commit message>"
```

更新 `PROJECT_STATE.md`：

```markdown
### 任務 N: <任務名稱>
- **狀態**：✅ 完成
- **實作嘗試**：1 次
- **規格審查**：通過
- **品質審查**：通過
```

#### 批次模式（--batch）

如果啟用批次模式：
- 每完成 3 個任務後暫停
- 顯示已完成任務的摘要
- 等待使用者確認後繼續
- 使用者可在此時提出修改意見

**退出條件：** 所有任務都已完成（或標記為需人工介入）。

### Stage 3: 最終審查

**目標：** 確保所有任務的整體一致性

#### Step 1: 整體一致性檢查

分派 general-purpose subagent 進行整體審查：
- 所有模組間的介面是否一致
- import/export 是否正確
- 型別定義是否一致
- 沒有遺漏的功能
- 所有測試可以一起執行

#### Step 2: 執行完整測試

```bash
# 執行所有測試
<test-command>
```

如果有測試失敗：
1. 識別失敗的測試
2. 分派修復 subagent
3. 重新執行測試
4. 最多重試 3 次

#### Step 3: 產出執行報告

更新 `PROJECT_STATE.md` 的 SADD 執行記錄：

```markdown
## SADD 執行記錄
- **計畫檔案**：claude_docs/plans/<file>.md
- **總任務數**：N
- **已完成**：M
- **需人工介入**：K
- **修復迴圈次數**：X
- **最終測試**：通過/失敗
- **Git commits**：Y 個
```

**退出條件：** 最終審查完成，執行報告已產出。

## Subagent 分派策略

### 並行 vs 序列

- **預設序列執行**：逐任務執行，確保依賴正確
- **同層級可並行**：無依賴關係的任務可以使用多個 Task tool 並行分派
- **審查序列執行**：規格審查 → 品質審查必須依序

### Subagent 超時處理

- 單個 subagent 最長執行時間：5 分鐘
- 超時後重試一次
- 二次超時標記為需人工介入

### 錯誤恢復

- Subagent 失敗（非審查不通過）→ 重試
- 連續 3 個任務失敗 → 暫停並報告
- 依賴的前置任務失敗 → 跳過所有依賴該任務的後續任務

## 互動原則

- 預設完全自動化，不需要使用者介入
- 批次模式（--batch）每 3 個任務暫停一次
- 每個任務完成時輸出簡短進度報告
- 需人工介入時明確標示問題
- 最終報告包含所有執行細節
