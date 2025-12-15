# DD Pipeline 測試審查 (TDD + BDD + ATDD + FDD)

執行測試審查階段，包含單元測試、行為測試、驗收測試和失敗情境測試。

---

## 參數

- `--backend`：只執行後端測試
- `--frontend`：只執行前端測試
- `--integrate`：執行整合測試（前後端都通過後）

---

## 後端測試流程

### 1. 讀取測試範例
- 讀取 `claude_docs/examples/EXAMPLES.md`
- 讀取 `claude_docs/contracts/API_CONTRACT.md`

### 2. 撰寫測試 (TDD + BDD)

**調用 Agent: `test-engineer`**

**單元測試：**
- 測試各個函數/方法
- 測試業務邏輯
- Mock 外部依賴

**整合測試：**
- 測試 API 端點
- 測試資料庫操作
- 測試中間件

**行為測試 (BDD)：**
- 根據 EXAMPLES.md 撰寫
- 測試完整使用者場景
- 使用 Given-When-Then 格式

### 3. 執行測試

**調用 Agent: `test-engineer`**
```bash
npm test
# 或
pytest
# 或
go test ./...
```

收集結果：
- 通過/失敗數量
- 覆蓋率報告
- 失敗詳細資訊

### 4. 失敗情境測試 (FDD)

**調用 Agent: `test-engineer`**
- 測試錯誤處理
- 測試邊界條件
- 測試無效輸入
- 測試資源不存在
- 測試權限不足

### 5. 程式碼審查

**調用 Skill: `code-reviewer`**
- 審查程式碼品質
- 檢查最佳實踐
- 檢查潛在問題
- 提出改進建議

### 6. QA 驗收 (ATDD)

**調用 Skill: `senior-qa`**
- 驗收測試
- 確認符合需求
- 確認符合驗收標準

### 7. 結果處理

**如果通過：**
```bash
git add .
git commit -m "test(backend): 後端測試通過 - 覆蓋率 87%"
```
更新狀態後等待前端測試或進入整合測試

**如果失敗：**
```
❌ 後端測試失敗（第 1/3 次）

失敗項目：
├── DELETE /api/todos/:id
│   └── 預期：404，實際：500
└── POST /api/todos (邊界測試)
    └── 空 title 應回傳 400

🔄 自動修正中...
```

- 記錄失敗原因到 `PROJECT_STATE.md`
- 自動執行 `/dd-dev --backend --fix`
- 重新測試（最多 3 次）

---

## 前端測試流程

### 1. 撰寫組件測試

**調用 Agent: `test-engineer`**
- 組件渲染測試
- Props 測試
- 事件處理測試
- 快照測試

### 2. E2E 測試

**調用 MCP: `Playwright`**

```javascript
// 自動執行的測試流程
await browser_navigate('http://localhost:3000');
await browser_snapshot(); // 檢查頁面載入

// 測試新增功能
await browser_type('輸入框', '買牛奶');
await browser_click('新增按鈕');
await browser_snapshot(); // 確認新增成功

// 測試完成功能
await browser_click('checkbox');
await browser_snapshot(); // 確認樣式變更

// 測試刪除功能
await browser_click('刪除按鈕');
await browser_snapshot(); // 確認項目消失
```

截圖保存到：`claude_docs/reports/screenshots/`

### 3. UI/UX 審查

**調用 Skill: `ux-researcher-designer`**
- 審查 E2E 截圖
- 檢查視覺一致性
- 檢查使用者體驗
- 提出改進建議（標記嚴重度）

### 4. QA 驗收

**調用 Skill: `senior-qa`**
- 驗收使用者流程
- 確認互動正確
- 確認視覺正確

### 5. 結果處理

同後端測試

---

## 整合測試流程 (--integrate)

當後端和前端測試都通過後自動執行：

### 1. 完整 E2E 測試

**調用 MCP: `Playwright`**
- 執行完整使用者流程
- 前後端整合測試
- 測試所有主要功能

### 2. 效能測試

**調用 Agent: `performance-tuner`**
- 頁面載入時間
- API 回應時間
- 資源大小檢查

### 3. 最終安全審計

**調用 Agent: `security-auditor`**
- 最終安全掃描
- 檢查敏感資料處理

### 4. 最終 QA 驗收

**調用 Skill: `senior-qa`**
- 完整流程驗收
- 確認所有需求

### 5. 產出測試報告

**調用 Agent: `docs-writer`**

產出 `claude_docs/reports/TEST_REPORT.md`：
```markdown
# 測試報告

## 摘要
- 總測試數：45
- 通過：45
- 失敗：0
- 覆蓋率：87%

## 後端測試
- 單元測試：20/20
- 整合測試：10/10
- 失敗情境測試：5/5

## 前端測試
- 組件測試：8/8
- E2E 測試：2/2

## 效能指標
- 首頁載入：1.2s
- API 平均回應：50ms

## 安全審計
- 高風險：0
- 中風險：0
- 低風險：1（建議事項）
```

### 6. 完成處理
```bash
git add .
git commit -m "test: 整合測試通過"
```

進入發布流程

---

## 使用的 Agent/Skill/MCP

| 類型 | 名稱 | 用途 |
|------|------|------|
| Agent | `test-engineer` | 撰寫和執行測試 |
| Agent | `root-cause-analyzer` | 分析失敗原因 |
| Agent | `performance-tuner` | 效能測試 |
| Agent | `security-auditor` | 安全測試 |
| Agent | `docs-writer` | 測試報告 |
| Skill | `senior-qa` | QA 驗收 |
| Skill | `code-reviewer` | 程式碼審查 |
| Skill | `ux-researcher-designer` | UI/UX 審查 |
| MCP | `Playwright` | E2E 網頁測試 |

---

## 重試機制

- 最大重試次數：3 次
- 每次失敗都會記錄到 `PROJECT_STATE.md`
- 超過 3 次後暫停並報告：
  ```
  ⚠️ 測試失敗超過 3 次，需要人工介入

  失敗歷史：
  ├── 第 1 次：DELETE API 錯誤處理
  ├── 第 2 次：DELETE API 仍有問題
  └── 第 3 次：新增了其他錯誤

  請檢查程式碼後執行：
  /dd-approve 繼續流程
  ```
