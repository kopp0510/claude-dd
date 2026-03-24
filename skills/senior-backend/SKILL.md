---
name: senior-backend
description: 資深後端工程師包裝器，調用官方 senior-backend agent。當提到 Express、Fastify、Node.js API、後端開發、認證機制、middleware 時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# Senior Backend

資深後端工程師 Skill，透過調用官方 senior-backend agent 提供後端開發專業知識。

## Skill 定位

**這是官方 senior-backend agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="senior-backend", ...)` 調用官方 agent
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的後端開發任務（由外部 Skill 維護）

## 觸發條件

**自動觸發時機：**

**關鍵詞：**
- 「Express」、「Fastify」、「Node.js API」
- 「後端」、「後端開發」、「backend」
- 「認證」、「authentication」、「JWT」
- 「GraphQL backend」
- 「REST API 設計」、「微服務」

**場景觸發：**
- 設計或實作後端 API
- 資料庫查詢整合與認證流程
- Node.js 後端架構設計

## 工作流程

### Stage 1: 需求確認

詢問使用者具體的後端開發需求：
- 要實作的功能或 API
- 使用的框架（Express/Fastify/其他）
- 資料庫和認證需求

### Stage 2: 調用官方 Agent

```
Task(
  subagent_type="senior-backend",
  prompt="根據使用者需求，執行後端開發任務...",
  description="後端開發任務"
)
```

### Stage 3: 結果報告

整理 agent 輸出，產出結構化報告：
- 實作摘要
- 關鍵程式碼變更
- API 端點清單（如適用）
- 建議的後續步驟
