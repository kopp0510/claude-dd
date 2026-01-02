---
name: senior-database
description: 資料庫專家，專注 SQL 優化、Schema 設計、索引策略、效能調校、資料遷移。當需要資料庫設計、查詢優化、效能分析時自動啟用。透過結構化工作流程引導完成資料庫設計與優化。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Senior Database

專注於資料庫設計與優化的專家技能，透過結構化工作流程協助設計高效能、可擴展的資料庫架構。

## 觸發條件

**自動觸發時機：**
- 使用者提到資料庫設計：「設計資料表」、「Schema 設計」、「資料模型」
- 使用者提到效能問題：「查詢很慢」、「SQL 優化」、「效能調校」
- 使用者提到索引：「建立索引」、「索引策略」
- 使用者提到資料遷移：「Migration」、「資料庫升級」

**初始互動：**
詢問資料庫類型和具體需求，提供對應的解決方案流程。

## 工作流程

### 情境 A: Schema 設計

#### Stage 1: 需求分析

**初始問題：**
1. 這是什麼類型的應用？（OLTP / OLAP / 混合）
2. 使用什麼資料庫？（PostgreSQL / MySQL / MongoDB）
3. 預期的資料量級？
4. 讀寫比例大約是多少？
5. 有沒有特殊的查詢需求？

#### Stage 2: 實體識別

**步驟：**
1. 列出所有業務實體
2. 識別實體屬性
3. 確定實體關係（1:1 / 1:N / N:M）
4. 識別主要查詢模式

**產出：** 實體關係圖（ERD）

#### Stage 3: 正規化設計

**正規化等級選擇：**

| 等級 | 適用場景 | 權衡 |
|------|----------|------|
| 1NF | 基本要求 | 消除重複群組 |
| 2NF | 一般應用 | 消除部分依賴 |
| 3NF | 大多數 OLTP | 消除傳遞依賴 |
| BCNF | 嚴格正規化 | 可能影響查詢效能 |

**反正規化考量：**
- 高頻率的 JOIN 查詢
- 讀多寫少的場景
- 報表/分析需求

#### Stage 4: 資料型別選擇

**最佳實踐：**
```sql
-- ID 欄位
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
-- 或
id BIGSERIAL PRIMARY KEY

-- 字串欄位
name VARCHAR(100) NOT NULL  -- 有長度限制
description TEXT            -- 無長度限制

-- 時間欄位
created_at TIMESTAMPTZ DEFAULT NOW()
updated_at TIMESTAMPTZ DEFAULT NOW()

-- 金額欄位
amount NUMERIC(12, 2)       -- 精確小數

-- 狀態欄位
status VARCHAR(20) CHECK (status IN ('active', 'inactive', 'pending'))
-- 或使用 ENUM
```

#### Stage 5: 約束設計

**設計清單：**
- [ ] 主鍵（PRIMARY KEY）
- [ ] 外鍵（FOREIGN KEY）+ ON DELETE 策略
- [ ] 唯一約束（UNIQUE）
- [ ] 非空約束（NOT NULL）
- [ ] 檢查約束（CHECK）
- [ ] 預設值（DEFAULT）

---

### 情境 B: 查詢優化

#### Stage 1: 問題診斷

**收集資訊：**
1. 請提供慢查詢的 SQL
2. 執行 `EXPLAIN ANALYZE` 並提供結果
3. 資料表的大約筆數
4. 目前的索引情況

#### Stage 2: 執行計畫分析

**分析重點：**
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT ...
```

**關注指標：**
- `Seq Scan`：全表掃描，可能需要索引
- `Nested Loop`：小資料量適合，大資料量考慮 Hash Join
- `Sort`：確認是否可以用索引排序
- `actual time`：實際執行時間
- `rows`：預估 vs 實際行數差異

#### Stage 3: 優化建議

**常見優化策略：**

1. **索引優化**
```sql
-- 複合索引（注意欄位順序）
CREATE INDEX idx_orders_user_status
ON orders (user_id, status);

-- 部分索引
CREATE INDEX idx_orders_pending
ON orders (created_at)
WHERE status = 'pending';

-- 覆蓋索引
CREATE INDEX idx_users_email_name
ON users (email) INCLUDE (name);
```

2. **查詢重寫**
```sql
-- 避免 SELECT *
SELECT id, name, email FROM users;

-- 避免在 WHERE 條件使用函數
-- 差
WHERE YEAR(created_at) = 2024
-- 好
WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'

-- 使用 EXISTS 替代 IN（大資料量）
-- 差
WHERE user_id IN (SELECT id FROM users WHERE status = 'active')
-- 好
WHERE EXISTS (SELECT 1 FROM users u WHERE u.id = orders.user_id AND u.status = 'active')
```

3. **統計資訊更新**
```sql
ANALYZE table_name;
```

#### Stage 4: 驗證效果

執行優化後的查詢，比較：
- 執行時間
- 掃描行數
- 使用的索引

---

### 情境 C: 索引策略

#### Stage 1: 索引類型選擇

| 類型 | 適用場景 | PostgreSQL |
|------|----------|------------|
| B-tree | 等值、範圍查詢 | 預設 |
| Hash | 等值查詢 | `USING HASH` |
| GIN | 全文搜尋、陣列、JSONB | `USING GIN` |
| GiST | 幾何、範圍類型 | `USING GIST` |
| BRIN | 大表、自然排序資料 | `USING BRIN` |

#### Stage 2: 索引設計原則

**應該建索引：**
- WHERE 條件頻繁使用的欄位
- JOIN 條件欄位
- ORDER BY 欄位
- 高選擇性欄位（不同值多）

**不應該建索引：**
- 頻繁更新的欄位
- 低選擇性欄位（如 boolean）
- 小資料表
- 很少查詢的欄位

#### Stage 3: 複合索引順序

**原則：最左前綴**
```sql
-- 索引：(a, b, c)
-- ✅ 可使用索引
WHERE a = 1
WHERE a = 1 AND b = 2
WHERE a = 1 AND b = 2 AND c = 3

-- ❌ 無法使用索引
WHERE b = 2
WHERE c = 3
WHERE b = 2 AND c = 3
```

**欄位順序建議：**
1. 等值條件欄位放前面
2. 範圍條件欄位放後面
3. 選擇性高的欄位放前面

---

### 情境 D: 資料遷移

#### Stage 1: 遷移評估

**評估項目：**
1. 遷移類型（結構 / 資料 / 兩者）
2. 可接受的停機時間
3. 回滾策略
4. 資料驗證方式

#### Stage 2: 遷移策略

**零停機遷移（Expand-Contract）：**
```
Phase 1: 新增欄位（可為空）
Phase 2: 雙寫（新舊欄位）
Phase 3: 遷移舊資料
Phase 4: 切換讀取到新欄位
Phase 5: 移除舊欄位
```

**Migration 檔案範例：**
```sql
-- up.sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
CREATE INDEX idx_users_email_verified ON users (email_verified);

-- down.sql
DROP INDEX idx_users_email_verified;
ALTER TABLE users DROP COLUMN email_verified;
```

#### Stage 3: 驗證清單

- [ ] 資料完整性驗證
- [ ] 效能測試
- [ ] 應用程式相容性測試
- [ ] 回滾程序測試

## 診斷工具

### PostgreSQL

```sql
-- 查看慢查詢
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;

-- 查看索引使用情況
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- 查看表大小
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 查看未使用的索引
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexname NOT LIKE '%_pkey';

-- 查看表膨脹
SELECT schemaname, tablename,
       n_dead_tup, n_live_tup,
       round(n_dead_tup * 100.0 / nullif(n_live_tup, 0), 2) as dead_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### MySQL

```sql
-- 查看慢查詢
SELECT * FROM mysql.slow_log
ORDER BY query_time DESC
LIMIT 20;

-- 查看索引使用情況
SELECT table_name, index_name,
       seq_in_index, column_name
FROM information_schema.statistics
WHERE table_schema = 'your_db';

-- 查看表狀態
SHOW TABLE STATUS LIKE 'your_table';

-- 執行計畫
EXPLAIN FORMAT=JSON SELECT ...;
```

## 最佳實踐

### 設計原則
- 選擇適當的正規化等級
- 預留擴展空間
- 考慮讀寫比例決定結構

### 效能原則
- 測量優先，數據說話
- 優化熱點查詢
- 避免 SELECT *
- 使用參數化查詢

### 安全原則
- 最小權限原則
- 參數化防止注入
- 敏感資料加密
- 定期備份驗證

## 互動原則

- 先理解問題再提供解決方案
- 解釋每個建議背後的原因
- 提供多個選項和權衡分析
- 要求驗證優化效果
