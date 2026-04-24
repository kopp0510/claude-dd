---
name: senior-frontend
description: 資深前端工程師包裝器，調用官方 senior-frontend agent。當提到 React 元件實作、Next.js、Tailwind、bundle size 優化、前端工程開發時自動啟用。不適用於視覺設計（用 frontend-design）或設計系統 Token（用 ui-design-system）。
allowed-tools: Task, Read, Grep, Glob
---

# Senior Frontend

資深前端工程師 Skill，透過調用官方 senior-frontend agent 提供前端開發專業知識。

## Skill 定位

**這是官方 senior-frontend agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="senior-frontend:senior-frontend" 或 "senior-frontend", ...)` 調用官方 agent（優先 plugin 命名空間，失敗 fallback 本地 `~/.claude/agents/senior-frontend.md`）
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行實際的前端開發任務（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「React 元件」、「React component」
- 「Next.js」、「Next.js 優化」
- 「Tailwind」、「Tailwind CSS」
- 「前端開發」、「frontend」
- 「bundle size」、「打包優化」

**場景觸發：**
- 建立或優化 React/Next.js 元件
- 前端效能優化與 bundle 分析
- 前端架構設計與最佳實踐

## 工作流程

### Stage 1: 需求確認
詢問使用者具體的前端開發需求。

### Stage 2: 調用官方 Agent

**Agent 調用策略**：先試 plugin 命名空間 `subagent_type="senior-frontend:senior-frontend"`，若收到 `Agent type '...' not found` 錯誤則 fallback 短名稱 `subagent_type="senior-frontend"`（從 `~/.claude/agents/senior-frontend.md` 讀取，由 `install-dd-pipeline.sh` 部署）。兩者皆失敗時停下，告訴使用者執行 `./install-dd-pipeline.sh` 補齊本地 agent。

```
Task(
  subagent_type="senior-frontend",
  prompt="根據使用者需求，執行前端開發任務...",
  description="前端開發任務"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
