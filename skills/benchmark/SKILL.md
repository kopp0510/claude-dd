---
name: benchmark
description: 負載測試與壓力測試包裝器，調用 performance-benchmark 命令。當需要負載測試、壓力測試、基準測試數據收集、併發量測試、throughput 測量時自動啟用。不適用於 profiling 分析（用 performance-profile）或程式碼調優（用 performance-tuner）。
allowed-tools: Skill, Read, Grep, Glob
---

# Benchmark

負載測試與基準測試 Skill，透過調用 performance-benchmark 命令執行效能基準測試。

## Skill 定位

**這是 performance-benchmark:benchmark 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="performance-benchmark:benchmark")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行負載測試、基準測試、智慧場景產生

## 觸發條件

**關鍵詞：**
- 「負載測試」、「load testing」
- 「benchmark」、「基準測試」
- 「壓力測試」、「stress test」

**場景觸發：**
- API 或服務的負載測試
- 效能基準建立
- 上線前壓力測試

## 工作流程

### Stage 1: 需求確認
詢問使用者要測試的目標和場景。

### Stage 2: 調用 Skill 命令
```
Skill(skill="performance-benchmark:benchmark")
```

### Stage 3: 結果報告
整理命令輸出，產出基準測試報告。
