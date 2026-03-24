---
name: health-check
description: 系統健康檢查包裝器，調用 operations-health-check 命令。當提到系統健康檢查、health check、服務狀態驗證、運行狀態確認時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Health Check

系統健康檢查 Skill，透過調用 operations-health-check 命令執行系統健康驗證。

## Skill 定位

**這是 operations-health-check:health-check 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="operations-health-check:health-check")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行系統健康驗證、監控檢查、事件偵測

## 觸發條件

**關鍵詞：**
- 「系統健康」、「system health」
- 「監控」、「monitoring」
- 「health check」、「健康檢查」

**場景觸發：**
- 檢查系統運行狀態
- 生產環境監控
- 定期健康檢查

## 工作流程

### Stage 1: 需求確認
詢問使用者要檢查的系統和指標。

### Stage 2: 調用 Skill 命令
```
Skill(skill="operations-health-check:health-check")
```

### Stage 3: 結果報告
整理命令輸出，產出系統健康報告。
