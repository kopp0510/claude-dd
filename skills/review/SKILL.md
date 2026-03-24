---
name: review
description: 多維度綜合審查包裝器，調用 workflow-review 命令同時執行安全、效能、配置審查。當提到全面審查、comprehensive review、多維度審查、安全+效能審查時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Review

綜合程式碼審查 Skill，透過調用 workflow-review 命令執行包含安全、效能、配置安全的多維度審查。

## Skill 定位

**這是 workflow-review:review 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="workflow-review:review")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行實際的多維度程式碼審查

## 觸發條件

**關鍵詞：**
- 「審查程式碼」、「程式碼審查」
- 「comprehensive review」、「全面審查」
- 「code review」

**場景觸發：**
- 需要全面的程式碼審查（含安全、效能分析）
- 合併前的最終審查
- 重大功能的品質確認

## 工作流程

### Stage 1: 需求確認
詢問使用者要審查的範圍和重點。

### Stage 2: 調用 Skill 命令
```
Skill(skill="workflow-review:review")
```

### Stage 3: 結果報告
整理命令輸出，產出結構化審查報告。

## 與 code-reviewer 的差異

| 特性 | review | code-reviewer |
|-----|--------|---------------|
| **審查範圍** | 多維度（安全+效能+配置） | 程式碼品質為主 |
| **調用方式** | Skill 命令 | Agent subagent |
| **適用場景** | 合併前全面審查 | 日常 PR 審查 |
