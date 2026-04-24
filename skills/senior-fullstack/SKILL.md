---
name: senior-fullstack
description: 資深全端工程師包裝器，調用官方 senior-fullstack agent。當提到全端開發、前後端整合、tech stack 選擇、全端 scaffold 時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# Senior Fullstack

資深全端工程師 Skill，透過調用官方 senior-fullstack agent 提供全端開發專業知識。

## Skill 定位

**這是官方 senior-fullstack agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="senior-fullstack:senior-fullstack" 或 "senior-fullstack", ...)` 調用官方 agent（優先 plugin 命名空間，失敗 fallback 本地 `~/.claude/agents/senior-fullstack.md`）
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的全端開發任務（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「全端」、「fullstack」、「full-stack」
- 「scaffold 專案」、「專案初始化」
- 「tech stack」、「技術選型」

**場景觸發：**
- 全端專案建構與初始化
- 技術棧選擇與評估
- 前後端整合開發

## 工作流程

### Stage 1: 需求確認
詢問使用者具體的全端開發需求。

### Stage 2: 調用官方 Agent

**Agent 調用策略**：先試 plugin 命名空間 `subagent_type="senior-fullstack:senior-fullstack"`，若收到 `Agent type '...' not found` 錯誤則 fallback 短名稱 `subagent_type="senior-fullstack"`（從 `~/.claude/agents/senior-fullstack.md` 讀取，由 `install-dd-pipeline.sh` 部署）。兩者皆失敗時停下，告訴使用者執行 `./install-dd-pipeline.sh` 補齊本地 agent。

```
Task(
  subagent_type="senior-fullstack",
  prompt="根據使用者需求，執行全端開發任務...",
  description="全端開發任務"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
