---
name: playwright-pro
description: Playwright 測試專家包裝器，調用官方 playwright-pro agent。當提到 Playwright、瀏覽器自動化、E2E 腳本、Cypress 遷移、page object 時自動啟用。
allowed-tools: Task, Read, Grep, Glob
---

# Playwright Pro

Playwright 測試專家 Skill，透過調用官方 playwright-pro agent 提供 Playwright 測試專業知識。

## Skill 定位

**這是官方 playwright-pro agent 的包裝器 (Wrapper)**

- **實作方式**：透過 `Task(subagent_type="playwright-pro:playwright-pro" 或 "playwright-pro", ...)` 調用官方 agent（優先 plugin 命名空間，失敗 fallback 本地 `~/.claude/agents/playwright-pro.md`）
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **Agent 職責**：執行 Playwright 測試任務（由外部 Skill 維護）

## 觸發條件

**關鍵詞：**
- 「Playwright」、「Playwright 測試」
- 「瀏覽器測試」、「browser testing」
- 「E2E 自動化」、「E2E automation」
- 「Cypress 遷移」、「migrate from Cypress」

**場景觸發：**
- 產生 Playwright 測試程式碼
- 修復不穩定的測試
- 從 Cypress/Selenium 遷移到 Playwright
- 整合 TestRail 或 BrowserStack

## 工作流程

### Stage 1: 需求確認
詢問使用者具體的 Playwright 測試需求。

### Stage 2: 調用官方 Agent

**Agent 調用策略**：先試 plugin 命名空間 `subagent_type="playwright-pro:playwright-pro"`，若收到 `Agent type '...' not found` 錯誤則 fallback 短名稱 `subagent_type="playwright-pro"`（從 `~/.claude/agents/playwright-pro.md` 讀取，由 `install-dd-pipeline.sh` 部署）。兩者皆失敗時停下，告訴使用者執行 `./install-dd-pipeline.sh` 補齊本地 agent。

```
Task(
  subagent_type="playwright-pro",
  prompt="根據使用者需求，執行 Playwright 測試任務...",
  description="Playwright 測試任務"
)
```

### Stage 3: 結果報告
整理 agent 輸出，產出結構化報告。
