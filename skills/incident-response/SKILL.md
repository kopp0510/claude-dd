---
name: incident-response
description: 生產事件回應包裝器，調用 operations-incident-response 命令。當提到生產事件、incident、緊急回應、RCA 時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Incident Response

生產事件回應 Skill，透過調用 operations-incident-response 命令協調事件處理。

## Skill 定位

**這是 operations-incident-response:incident-response 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="operations-incident-response:incident-response")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行事件分流、根因分析、事後檢討產出

## 觸發條件

**關鍵詞：**
- 「生產事件」、「production incident」
- 「incident」、「事件回應」
- 「緊急回應」、「emergency response」
- 「RCA」、「root cause analysis」

**場景觸發：**
- 生產環境出現問題
- 事件回應與處理
- 事後檢討（postmortem）產出

## 工作流程

### Stage 1: 需求確認
詢問使用者事件的描述、嚴重程度和影響範圍。

### Stage 2: 調用 Skill 命令
```
Skill(skill="operations-incident-response:incident-response")
```

### Stage 3: 結果報告
整理命令輸出，產出事件回應報告。
