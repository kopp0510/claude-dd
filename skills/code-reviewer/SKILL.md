---
name: code-reviewer
description: 程式碼審查專家包裝器，調用官方 code-reviewer agent。當提到 review PR、程式碼品質、SOLID 違規、code smell 時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# Code Reviewer

程式碼審查專家 Skill，透過調用官方 code-reviewer agent 提供自動化程式碼審查。

## Skill 定位

**這是官方 code-reviewer agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="code-reviewer", ...)` 調用官方 agent
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的程式碼審查（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「review PR」、「PR 審查」
- 「程式碼品質」、「code quality」
- 「SOLID 違規」、「SOLID principles」
- 「code smell」、「壞味道」

**場景觸發：**
- 審查 Pull Request
- 分析程式碼品質問題
- 識別 code smell 和設計違規

## 工作流程

### Stage 1: 需求確認
詢問使用者要審查的範圍（PR、檔案、目錄）。

### Stage 2: 調用官方 Agent
```
Task(
  subagent_type="code-reviewer",
  prompt="根據使用者需求，執行程式碼審查...",
  description="程式碼審查"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化審查報告。
