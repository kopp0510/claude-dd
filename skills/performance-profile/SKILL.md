---
name: performance-profile
description: 效能分析包裝器，調用 performance-profile 命令。當提到效能分析、profiling、瓶頸定位時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Performance Profile

效能分析 Skill，透過調用 performance-profile 命令執行綜合效能分析。

## Skill 定位

**這是 performance-profile:profile 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="performance-profile:profile")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行效能分析、瓶頸識別、優化建議

## 觸發條件

**關鍵詞：**
- 「效能分析」、「performance profiling」
- 「profiling」、「效能瓶頸」
- 「瓶頸定位」、「bottleneck」

**場景觸發：**
- 應用程式效能分析
- 識別效能瓶頸
- 效能優化前的數據收集

## 工作流程

### Stage 1: 需求確認
詢問使用者要分析的目標和效能指標。

### Stage 2: 調用 Skill 命令
```
Skill(skill="performance-profile:profile")
```

### Stage 3: 結果報告
整理命令輸出，產出效能分析報告。

## 與 performance-tuner 的差異

| 特性 | performance-profile | performance-tuner |
|-----|-------------------|------------------|
| **重點** | 分析與診斷 | 優化與調校 |
| **適用場景** | 找出瓶頸在哪 | 已知瓶頸後優化 |
