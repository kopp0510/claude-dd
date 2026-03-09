---
name: senior-qa
description: 資深品質保證工程師包裝器，調用官方 senior-qa agent。當提到 QA、E2E 測試、Jest 設定、Playwright 測試時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# Senior QA

資深品質保證工程師 Skill，透過調用官方 senior-qa agent 提供 QA 專業知識。

## Skill 定位

**這是官方 senior-qa agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="senior-qa", ...)` 調用官方 agent
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的 QA 任務（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「QA」、「品質保證」
- 「E2E 測試」、「端對端測試」
- 「Jest 設定」、「Jest config」
- 「Playwright 測試」

**場景觸發：**
- 建立測試策略與框架
- E2E 測試設計與實作
- 測試品質改善

## 工作流程

### Stage 1: 需求確認
詢問使用者具體的 QA 需求。

### Stage 2: 調用官方 Agent
```
Task(
  subagent_type="senior-qa",
  prompt="根據使用者需求，執行 QA 任務...",
  description="QA 任務"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
