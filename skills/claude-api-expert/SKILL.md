---
name: claude-api-expert
description: Claude API 整合專家，提供結構化需求確認與報告產出，調用官方 claude-api agent。當需要以結構化流程整合 Claude API、建立 Anthropic SDK 應用、設計 Agent SDK 架構時自動啟用。不適用於簡單 API 查詢（由內建 claude-api 處理）。
allowed-tools: Task, Read, Grep, Glob
---

# Claude API

Claude API 專家 Skill，透過調用官方 claude-api agent 提供 Claude API 與 SDK 開發專業知識。

## Skill 定位

**這是官方 claude-api agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="claude-api", ...)` 調用官方 agent
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的 API 整合任務（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 引用 `anthropic` SDK、`@anthropic-ai/sdk`
- 「Claude API」、「Anthropic API」
- 「Agent SDK」、`claude_agent_sdk`

**場景觸發：**
- 整合 Claude API 到應用程式
- 使用 Anthropic SDK 開發
- 建立基於 Claude 的 Agent

## 工作流程

### Stage 1: 需求確認
詢問使用者具體的 API 整合需求。

### Stage 2: 調用官方 Agent
```
Task(
  subagent_type="claude-api",
  prompt="根據使用者需求，執行 Claude API 整合任務...",
  description="Claude API 整合"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
