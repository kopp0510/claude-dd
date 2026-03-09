---
name: senior-devops
description: 資深 DevOps 工程師包裝器，調用官方 senior-devops agent。當提到 CI/CD、Docker、Kubernetes、部署、infrastructure 時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# Senior DevOps

資深 DevOps 工程師 Skill，透過調用官方 senior-devops agent 提供 DevOps 專業知識。

## Skill 定位

**這是官方 senior-devops agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="senior-devops", ...)` 調用官方 agent
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的 DevOps 任務（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「CI/CD」、「pipeline」
- 「Docker」、「容器化」、「Dockerfile」
- 「Kubernetes」、「K8s」、「Helm」
- 「部署」、「deployment」
- 「infrastructure」、「基礎設施」

**場景觸發：**
- 設定 CI/CD 流水線
- 容器化應用程式
- 部署自動化與基礎設施管理

## 工作流程

### Stage 1: 需求確認
詢問使用者具體的 DevOps 需求。

### Stage 2: 調用官方 Agent
```
Task(
  subagent_type="senior-devops",
  prompt="根據使用者需求，執行 DevOps 任務...",
  description="DevOps 任務"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
