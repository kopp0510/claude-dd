---
name: debt-analysis
description: 技術債盤點與規劃包裝器，調用 quality-debt-analysis 命令。當需要技術債盤點、債務優先排序、重構路線圖規劃、技術債務量化評估時自動啟用。不適用於實際重構執行（用 refactor-expert）或程式碼健康指標（用 code-health）。
allowed-tools: Skill, Read, Grep, Glob
---

# Debt Analysis

技術債分析 Skill，透過調用 quality-debt-analysis 命令識別技術債並產出重構路線圖。

## Skill 定位

**這是 quality-debt-analysis:debt-analysis 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="quality-debt-analysis:debt-analysis")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行技術債識別、優先排序、工時估算

## 觸發條件

**關鍵詞：**
- 「技術債」、「technical debt」
- 「債務分析」、「debt analysis」
- 「重構路線圖」、「refactoring roadmap」

**場景觸發：**
- 評估程式碼庫的技術債狀況
- 規劃重構優先順序
- 估算技術債償還工時

## 工作流程

### Stage 1: 需求確認
詢問使用者要分析的範圍和關注領域。

### Stage 2: 調用 Skill 命令
```
Skill(skill="quality-debt-analysis:debt-analysis")
```

### Stage 3: 結果報告
整理命令輸出，產出技術債分析報告與重構路線圖。
