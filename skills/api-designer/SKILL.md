---
name: api-designer
description: API 設計專家，專注 REST/GraphQL API 設計、版本策略、錯誤處理、文件規範。當需要設計 API、定義契約、撰寫 API 規格時自動啟用。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# API Designer

專注於 API 設計與規範的專家技能。

## 核心能力

### REST API 設計

#### 資源命名
```
# 正確
GET  /users              # 集合
GET  /users/:id          # 單一資源
GET  /users/:id/orders   # 子資源

# 避免
GET  /getUsers           # 動詞命名
GET  /user/:id           # 單複數不一致
GET  /users/:id/getOrders
```

#### HTTP 動詞
| 動詞 | 用途 | 冪等性 |
|------|------|--------|
| GET | 讀取資源 | 是 |
| POST | 建立資源 | 否 |
| PUT | 完整更新 | 是 |
| PATCH | 部分更新 | 否 |
| DELETE | 刪除資源 | 是 |

#### 狀態碼規範
| 狀態碼 | 用途 |
|--------|------|
| 200 | 成功 |
| 201 | 建立成功 |
| 204 | 成功無內容 |
| 400 | 請求錯誤 |
| 401 | 未認證 |
| 403 | 無權限 |
| 404 | 找不到 |
| 409 | 衝突 |
| 422 | 驗證失敗 |
| 429 | 請求過多 |
| 500 | 伺服器錯誤 |

### GraphQL 設計

#### Schema 設計原則
- 以領域模型為基礎
- 避免過深的巢狀
- 使用 Connection 模式分頁
- 區分 Query/Mutation/Subscription

#### N+1 問題處理
- 使用 DataLoader 批次載入
- 設計適當的 Resolver
- 限制查詢深度

### 版本策略

#### URL 版本
```
/api/v1/users
/api/v2/users
```

#### Header 版本
```
Accept: application/vnd.api+json;version=1
```

#### 向後相容原則
- 新增欄位不破壞相容
- 棄用欄位先標記再移除
- 提供遷移指南

### 分頁設計

#### Offset 分頁
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

#### Cursor 分頁（推薦大量資料）
```json
{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTAwfQ==",
    "hasNext": true,
    "hasPrev": false
  }
}
```

### 錯誤處理

#### 標準錯誤格式
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "驗證失敗",
    "details": [
      {
        "field": "email",
        "message": "格式不正確"
      }
    ],
    "requestId": "req_123abc"
  }
}
```

#### 錯誤碼設計
- 使用大寫蛇形命名
- 分類前綴（AUTH_、VALIDATION_、RESOURCE_）
- 提供文件對照表

### 認證授權

#### 認證方式
- **API Key** - 簡單場景、內部服務
- **JWT** - 無狀態、跨服務
- **OAuth 2.0** - 第三方授權

#### 授權模式
- **RBAC** - 角色權限控制
- **ABAC** - 屬性權限控制
- **Scope** - API 範圍限制

### 限流設計

#### Rate Limiting
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

#### 策略選擇
- 固定視窗
- 滑動視窗
- 令牌桶
- 漏桶

### 冪等性設計

#### Idempotency Key
```
POST /orders
Idempotency-Key: order_abc123

# 重複請求返回相同結果
```

## 文件規範

### OpenAPI/Swagger
```yaml
openapi: 3.0.0
info:
  title: API 名稱
  version: 1.0.0
paths:
  /users:
    get:
      summary: 取得用戶列表
      responses:
        '200':
          description: 成功
```

### 文件要素
- 端點描述
- 參數說明
- 請求/回應範例
- 錯誤碼對照
- 認證說明

## 最佳實踐

### 設計原則
- 一致性優先
- 以使用者角度設計
- 簡單直覺的命名
- 完整的錯誤資訊

### 安全原則
- HTTPS 強制
- 輸入驗證
- 輸出編碼
- 適當的 CORS 設定
