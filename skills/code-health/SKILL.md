---
name: code-health
description: 程式碼健康度評估包裝器，調用 quality-code-health 命令。當提到程式碼健康、可維護性、品質指標、codebase health 時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Code Health

程式碼健康度評估 Skill，透過調用 quality-code-health 命令評估程式碼庫的整體健康狀況。

## Skill 定位

**這是 quality-code-health:code-health 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="quality-code-health:code-health")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行程式碼健康度評估（品質指標、測試覆蓋、可維護性）

## 觸發條件

**關鍵詞：**
- 「程式碼健康」、「codebase health」
- 「可維護性」、「maintainability」
- 「品質指標」、「quality metrics」

**場景觸發：**
- 評估程式碼庫整體健康狀況
- 專案接手前的品質評估
- 定期品質檢查

## 工作流程

### Stage 1: 需求確認
詢問使用者要評估的範圍和重點指標。

### Stage 2: 調用 Skill 命令
```
Skill(skill="quality-code-health:code-health")
```

### Stage 3: 結果報告
整理命令輸出，產出健康度評估報告。
