---
name: code-reviewer
description: PR 級別程式碼審查專家包裝器，調用官方 code-reviewer agent。當需要審查 PR、review pull request、檢測 code smell、SOLID 違規檢查時自動啟用。不適用於跨維度綜合審查（用 review）或程式碼簡化（用 code-simplifier）。
allowed-tools: Task, Read, Grep, Glob
---

# Code Reviewer

程式碼審查專家 Skill，透過調用官方 code-reviewer agent 提供自動化程式碼審查。

## Skill 定位

**這是官方 code-reviewer agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="code-reviewer:code-reviewer" 或 "code-reviewer", ...)` 調用官方 agent（優先 plugin 命名空間，失敗 fallback 本地 `~/.claude/agents/code-reviewer.md`，若皆不存在則 marketplace 的其他 plugin 也可能提供此 agent）
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

**Agent 調用策略**：先試 plugin 命名空間 `subagent_type="code-reviewer:code-reviewer"`，若收到 `Agent type '...' not found` 錯誤則 fallback 短名稱 `subagent_type="code-reviewer"`（從 `~/.claude/agents/code-reviewer.md` 讀取；marketplace 多個 plugin 也可能提供此 agent）。兩者皆失敗時停下，告訴使用者執行 `./install-dd-pipeline.sh` 或安裝對應 plugin。

```
Task(
  subagent_type="code-reviewer",
  prompt="根據使用者需求，執行程式碼審查...",
  description="程式碼審查"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化審查報告。
