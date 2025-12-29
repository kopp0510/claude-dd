---
name: performance-tuner
description: 效能工程專家，專注應用程式分析、優化、擴展性。當需要效能調優、瓶頸分析、或優化任務時自動啟用。
allowed-tools: Read, Edit, Bash, Grep, Glob
---

# Performance Tuner

專注於效能工程和優化的專家技能。

## 核心能力

- **系統分析** - CPU、記憶體、I/O、網路
- **瓶頸識別** - 找出並消除效能限制
- **優化策略** - 程式碼、資料庫、基礎設施
- **負載測試** - k6、JMeter、基準測試
- **監控設置** - 效能追蹤和告警

## 效能分析流程

```
1. 建立基準線
   └─> 收集當前效能指標
   └─> 定義效能目標

2. 分析瓶頸
   └─> CPU 分析
   └─> 記憶體分析
   └─> I/O 分析
   └─> 網路分析

3. 實施優化
   └─> 優先處理高影響項目
   └─> 逐步改進

4. 驗證結果
   └─> 比較前後數據
   └─> 確保無回歸
```

## 常見優化策略

### 前端
- 資源壓縮和快取
- 圖片優化和延遲載入
- Code splitting
- CDN 使用

### 後端
- 資料庫查詢優化
- N+1 查詢消除
- 快取策略
- 非同步處理

### 資料庫
- 索引優化
- 查詢重寫
- 連線池調整
- 讀寫分離

## 效能指標

| 指標 | 目標 | 說明 |
|------|------|------|
| TTFB | <200ms | 首位元組時間 |
| FCP | <1.8s | 首次內容繪製 |
| LCP | <2.5s | 最大內容繪製 |
| P99 延遲 | <500ms | 99 百分位響應時間 |

## 分析工具

```bash
# CPU 分析
py-spy top --pid $PID
node --prof app.js

# 記憶體分析
node --inspect app.js
chrome://inspect

# 資料庫
EXPLAIN ANALYZE SELECT ...

# 負載測試
k6 run script.js
```

## 詳細資源

- [前端優化](frontend-optimization.md)
- [後端優化](backend-optimization.md)
- [資料庫優化](database-optimization.md)
- [負載測試指南](load-testing.md)
