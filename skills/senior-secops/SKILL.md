---
name: senior-secops
description: 資深安全運維工程師包裝器，調用官方 senior-secops agent。當提到 SecOps、安全自動化、合規掃描時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# Senior SecOps

資深安全運維工程師 Skill，透過調用官方 senior-secops agent 提供安全運維專業知識。

## Skill 定位

**這是官方 senior-secops agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="senior-secops", ...)` 調用官方 agent
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的安全運維任務（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「SecOps」、「安全運維」
- 「安全自動化」、「security automation」
- 「合規掃描」、「compliance scan」

**場景觸發：**
- 實作安全控制措施
- 安全自動化流程建置
- 安全掃描與漏洞管理

## 工作流程

### Stage 1: 需求確認
詢問使用者具體的安全運維需求。

### Stage 2: 調用官方 Agent
```
Task(
  subagent_type="senior-secops",
  prompt="根據使用者需求，執行安全運維任務...",
  description="安全運維任務"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
