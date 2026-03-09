---
name: tdd-guide
description: TDD 引導專家包裝器，調用官方 tdd-guide agent。當提到 TDD、測試驅動開發、紅綠重構時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# TDD Guide

TDD 引導專家 Skill，透過調用官方 tdd-guide agent 提供測試驅動開發引導。

## Skill 定位

**這是官方 tdd-guide agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="tdd-guide", ...)` 調用官方 agent
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的 TDD 引導工作（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「TDD」、「測試驅動」
- 「紅綠重構」、「Red-Green-Refactor」
- 「先寫測試」、「test first」

**場景觸發：**
- 採用 TDD 方法開發新功能
- 學習或實踐 TDD 流程
- 需要 TDD 工作流程引導

## 工作流程

### Stage 1: 需求確認
詢問使用者要用 TDD 方式開發的功能。

### Stage 2: 調用官方 Agent
```
Task(
  subagent_type="tdd-guide",
  prompt="根據使用者需求，引導 TDD 開發流程...",
  description="TDD 引導"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
