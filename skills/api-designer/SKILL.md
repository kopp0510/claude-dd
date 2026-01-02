---
name: api-designer
description: API 設計專家，專注 REST/GraphQL API 設計、版本策略、錯誤處理、文件規範。當需要設計 API、定義契約、撰寫 API 規格時自動啟用。透過結構化工作流程引導完成 API 設計。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# API Designer

專注於 API 設計與規範的專家技能，透過結構化工作流程協助設計一致、易用、可擴展的 API。

## 觸發條件

**自動觸發時機：**
- 使用者提到設計 API：「設計 API」、「定義端點」、「API 規格」
- 使用者提到特定格式：「REST API」、「GraphQL」、「OpenAPI」、「Swagger」
- 使用者需要審查現有 API 設計
- 討論 API 版本策略或錯誤處理

**初始互動：**
詢問 API 類型（REST/GraphQL）和主要用途，提供結構化設計流程選項。

## 工作流程

### Stage 1: 需求分析

**目標：** 理解 API 用途、使用者、約束條件

#### 初始問題
1. 這個 API 的主要用途是什麼？
2. API 的使用者是誰？（內部服務 / 外部開發者 / 前端應用）
3. 預期的請求量級？（低 / 中 / 高）
4. 有沒有現有的 API 需要相容？
5. 有沒有特定的技術約束？（框架、協議）

#### 資源識別
根據業務需求，識別核心資源：
- 列出主要的業務實體
- 識別資源之間的關係
- 確定哪些資源需要 CRUD 操作
- 識別需要的特殊操作（批次、搜尋）

**退出條件：** 已識別所有核心資源和操作。

### Stage 2: API 架構設計

**目標：** 設計整體 API 結構

#### Step 1: 選擇 API 風格

**REST API 適用場景：**
- 資源導向的 CRUD 操作
- 需要 HTTP 快取
- 簡單的請求/回應模式

**GraphQL 適用場景：**
- 複雜的關聯查詢
- 前端需要靈活取得資料
- 需要減少請求次數

#### Step 2: 定義基礎架構

**REST 基礎架構：**
```
Base URL: /api/v1
認證: Bearer Token / API Key
格式: JSON
```

**GraphQL 基礎架構：**
```
Endpoint: /graphql
認證: Bearer Token in Header
格式: JSON
```

#### Step 3: 版本策略

詢問使用者偏好的版本策略：

| 策略 | 範例 | 適用場景 |
|------|------|----------|
| URL 版本 | `/api/v1/users` | 明確、易理解 |
| Header 版本 | `Accept-Version: v1` | 保持 URL 簡潔 |
| Query 版本 | `/api/users?version=1` | 快速切換測試 |

**建議：** 對外 API 使用 URL 版本，內部 API 可用 Header 版本。

### Stage 3: 端點設計

**目標：** 設計每個資源的端點

對每個資源執行以下步驟：

#### Step 1: 列出操作

對於資源 `{resource}`，確認需要的操作：
- [ ] 列表查詢 `GET /{resources}`
- [ ] 單一查詢 `GET /{resources}/:id`
- [ ] 建立 `POST /{resources}`
- [ ] 完整更新 `PUT /{resources}/:id`
- [ ] 部分更新 `PATCH /{resources}/:id`
- [ ] 刪除 `DELETE /{resources}/:id`
- [ ] 其他特殊操作

#### Step 2: 設計請求/回應

對每個端點定義：

**請求：**
- URL 參數
- Query 參數
- Request Body Schema
- 必填/選填欄位

**回應：**
- 成功回應 Schema
- 分頁格式（如適用）
- 錯誤回應格式

#### Step 3: 命名規範檢查

確保符合 RESTful 命名規範：
- ✅ 使用複數名詞：`/users`、`/orders`
- ✅ 使用小寫和連字號：`/user-profiles`
- ❌ 避免動詞：`/getUsers`、`/createOrder`
- ❌ 避免深層巢狀：`/users/:id/orders/:id/items/:id`

### Stage 4: 錯誤處理設計

**目標：** 定義一致的錯誤處理機制

#### 錯誤回應格式
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
    "requestId": "req_abc123"
  }
}
```

#### 錯誤碼設計原則
- 使用大寫蛇形命名：`VALIDATION_ERROR`
- 分類前綴：`AUTH_`、`VALIDATION_`、`RESOURCE_`
- 提供文件對照表

#### HTTP 狀態碼對照
| 狀態碼 | 用途 | 錯誤碼範例 |
|--------|------|-----------|
| 400 | 請求格式錯誤 | `INVALID_REQUEST` |
| 401 | 未認證 | `AUTH_REQUIRED` |
| 403 | 無權限 | `PERMISSION_DENIED` |
| 404 | 找不到資源 | `RESOURCE_NOT_FOUND` |
| 409 | 資源衝突 | `RESOURCE_CONFLICT` |
| 422 | 驗證失敗 | `VALIDATION_ERROR` |
| 429 | 請求過多 | `RATE_LIMIT_EXCEEDED` |
| 500 | 伺服器錯誤 | `INTERNAL_ERROR` |

### Stage 5: 進階設計

**目標：** 處理進階需求

#### 分頁設計

**Offset 分頁：**
```
GET /users?page=1&limit=20

Response:
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

**Cursor 分頁（大量資料推薦）：**
```
GET /users?cursor=abc123&limit=20

Response:
{
  "data": [...],
  "pagination": {
    "nextCursor": "def456",
    "hasNext": true
  }
}
```

#### 認證設計

詢問使用者認證需求，提供建議：

| 方式 | 適用場景 |
|------|----------|
| API Key | 簡單場景、內部服務 |
| JWT | 無狀態、跨服務 |
| OAuth 2.0 | 第三方授權 |

#### 限流設計

建議加入限流 Header：
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

#### 冪等性設計

對於 POST 請求，建議使用 Idempotency Key：
```
POST /orders
Idempotency-Key: order_abc123
```

### Stage 6: 文件產出

**目標：** 產出 OpenAPI 規格

#### OpenAPI 3.0 範本
```yaml
openapi: 3.0.0
info:
  title: API 名稱
  version: 1.0.0
  description: API 描述
servers:
  - url: https://api.example.com/v1
paths:
  /users:
    get:
      summary: 取得用戶列表
      parameters:
        - name: page
          in: query
          schema:
            type: integer
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
```

### Stage 7: 設計審查

**目標：** 確保 API 設計品質

#### 審查清單
- [ ] 命名一致且符合規範
- [ ] 所有端點都有適當的 HTTP 方法
- [ ] 錯誤處理完整
- [ ] 分頁設計合理
- [ ] 認證機制安全
- [ ] 向後相容性考量
- [ ] 文件完整

#### 常見問題檢查
1. 有沒有過深的 URL 巢狀？
2. 有沒有使用動詞命名資源？
3. 錯誤回應格式是否一致？
4. 是否考慮了版本升級路徑？

## 最佳實踐

### 設計原則
- 一致性優先：相似功能用相似的設計
- 以使用者角度設計：API 是產品
- 簡單直覺的命名
- 完整的錯誤資訊

### 安全原則
- HTTPS 強制
- 輸入驗證
- 輸出編碼
- 適當的 CORS 設定
- 敏感資料不放 URL

### 效能原則
- 支援欄位篩選
- 支援資源展開
- 適當的快取策略
- 批次操作支援

## 互動原則

- 逐步引導設計過程
- 對每個決策提供選項和建議
- 解釋為什麼某個設計更好
- 在關鍵決策點確認使用者意見
- 最終產出完整的 OpenAPI 規格
