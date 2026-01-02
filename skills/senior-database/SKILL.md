---
name: senior-database
description: 資料庫專家，專注 SQL 優化、Schema 設計、索引策略、效能調校、資料遷移。當需要資料庫設計、查詢優化、效能分析時自動啟用。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Senior Database

專注於資料庫設計與優化的專家技能。

## 核心能力

### Schema 設計
- **正規化設計** - 1NF/2NF/3NF/BCNF 正規化
- **反正規化** - 效能導向的適度反正規化
- **關聯設計** - 一對一/一對多/多對多關係
- **約束設計** - PK/FK/UNIQUE/CHECK 約束

### 索引策略
- **索引類型** - B-tree、Hash、GIN、GiST、BRIN
- **複合索引** - 欄位順序、選擇性分析
- **覆蓋索引** - 減少回表查詢
- **部分索引** - 條件式索引優化

### SQL 優化
- **執行計畫分析** - EXPLAIN/EXPLAIN ANALYZE 解讀
- **查詢重寫** - 子查詢優化、JOIN 順序
- **慢查詢分析** - 識別效能瓶頸
- **統計資訊** - ANALYZE、基數估算

### 交易處理
- **ACID 原則** - 原子性/一致性/隔離性/持久性
- **隔離等級** - READ UNCOMMITTED/COMMITTED/REPEATABLE READ/SERIALIZABLE
- **鎖定機制** - 行鎖/表鎖/死鎖處理
- **MVCC** - 多版本並發控制

### 資料遷移
- **Migration 設計** - 版本控制、可逆遷移
- **零停機遷移** - 漸進式變更策略
- **資料轉換** - ETL 流程設計
- **回滾策略** - 安全回滾機制

### 效能調校
- **連線池** - 連線管理、池大小設定
- **快取策略** - 查詢快取、應用層快取
- **分區策略** - Range/List/Hash 分區
- **分片設計** - 水平分割、Shard Key 選擇

## 最佳實踐

### 設計原則
- 先理解業務需求再設計
- 適度正規化，避免過度設計
- 考慮讀寫比例決定結構
- 預留擴展空間

### 效能原則
- 測量優先，數據說話
- 優化熱點查詢
- 避免 SELECT *
- 使用參數化查詢

### 安全原則
- 最小權限原則
- 參數化防注入
- 敏感資料加密
- 定期備份驗證

## 常用診斷

```sql
-- 查看慢查詢（PostgreSQL）
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;

-- 查看索引使用情況
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- 查看表膨脹
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## 支援的資料庫

- **關聯式** - PostgreSQL、MySQL、SQLite、SQL Server
- **NoSQL** - MongoDB、Redis、Cassandra
- **時序** - TimescaleDB、InfluxDB
- **搜尋** - Elasticsearch
