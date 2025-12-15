# DD Pipeline 開發實作 (DbC + CDD + PDD)

執行開發實作階段，依照契約進行組件化開發。

---

## 參數

- `--backend`：只執行後端開發
- `--frontend`：只執行前端開發
- `--fix`：修正模式（讀取失敗原因並修正）

---

## 後端開發流程

### 1. 讀取架構和契約
- 讀取 `claude_docs/architecture/ARCHITECTURE.md`
- 讀取 `claude_docs/contracts/API_CONTRACT.md`
- 讀取 `claude_docs/examples/EXAMPLES.md`

### 2. 優化開發 Prompt (PDD)

**調用 Skill: `senior-prompt-engineer`**
- 分析開發任務
- 優化開發指令
- 確保 AI 準確理解任務

### 3. 後端實作 (DbC + CDD)

**調用 Skill: `senior-backend`**
- 依照 API 契約實作
- 建立資料模型
- 實作業務邏輯
- 組件化/模組化開發
- 實作錯誤處理

產出：
- 控制器 (Controllers)
- 服務層 (Services)
- 資料模型 (Models)
- 中間件 (Middleware)
- 工具函數 (Utils)

### 4. 效能優化

**調用 Agent: `performance-tuner`**
- 檢查 N+1 查詢問題
- 優化資料庫查詢
- 檢查記憶體使用
- 建議快取策略

### 5. 安全檢查

**調用 Agent: `security-auditor`**
- 檢查 SQL Injection
- 檢查 XSS 漏洞
- 驗證輸入處理
- 檢查認證授權

### 6. 程式碼重構

**調用 Agent: `refactor-expert`**
- 優化程式碼結構
- 移除重複程式碼
- 提升可維護性
- 確保命名一致性

### 7. 產出文檔

**調用 Agent: `docs-writer`**
- 產出 API 文檔
- 更新技術文檔
- 加入程式碼註解

### 8. Git commit
```bash
git add .
git commit -m "feat(backend): 實作後端功能"
```

### 9. 自動進入測試
自動執行 `/dd-test --backend`

---

## 前端開發流程

### 1. 讀取設計規格
- 讀取 `claude_docs/design/DESIGN_SPEC.md`
- 讀取 `claude_docs/contracts/API_CONTRACT.md`
- 讀取 `claude_docs/examples/EXAMPLES.md`

### 2. 優化開發 Prompt (PDD)

**調用 Skill: `senior-prompt-engineer`**

### 3. 前端實作 (CDD)

**調用 Skill: `senior-frontend`**
- 建立組件結構
- 實作 UI 組件
- 實作狀態管理
- 串接 API
- 實作路由

產出：
- 頁面組件 (Pages)
- UI 組件 (Components)
- 自定義 Hooks
- API 服務 (Services)
- 工具函數 (Utils)

### 4. 設計一致性檢查

**調用 Skill: `ui-design-system`**
- 檢查設計一致性
- 套用 Design Token
- 確保響應式設計
- 檢查無障礙設計

### 5. UX 審查

**調用 Skill: `ux-researcher-designer`**
- 審查使用者體驗
- 檢查互動流程
- 提出改進建議

### 6. 程式碼重構

**調用 Agent: `refactor-expert`**

### 7. 產出文檔

**調用 Agent: `docs-writer`**
- 產出組件文檔
- 加入 Props 說明

### 8. Git commit
```bash
git add .
git commit -m "feat(frontend): 實作前端功能"
```

### 9. 自動進入測試
自動執行 `/dd-test --frontend`

---

## 修正模式 (--fix)

當測試失敗需要修正時：

### 1. 讀取失敗原因
從 `PROJECT_STATE.md` 讀取：
```markdown
## 迭代記錄
### 後端測試 - 第 1 次
- 狀態：❌ 失敗
- 原因：DELETE /api/todos/:id 回傳 500
- 詳細：缺少錯誤處理，找不到資源時應回傳 404
```

### 2. 分析問題

**調用 Agent: `root-cause-analyzer`**
- 分析根本原因
- 識別問題範圍
- 制定修正方案

### 3. 執行修正

**調用對應 Skill**
- 後端問題：`senior-backend`
- 前端問題：`senior-frontend`

### 4. Git commit
```bash
git add .
git commit -m "fix(backend): 修正 DELETE API 錯誤處理"
```

### 5. 重新執行測試

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Skill | `senior-prompt-engineer` | Prompt 優化 |
| Skill | `senior-backend` | 後端開發 |
| Skill | `senior-frontend` | 前端開發 |
| Skill | `ui-design-system` | 設計一致性 |
| Skill | `ux-researcher-designer` | UX 審查 |
| Agent | `performance-tuner` | 效能優化 |
| Agent | `security-auditor` | 安全檢查 |
| Agent | `refactor-expert` | 程式碼重構 |
| Agent | `root-cause-analyzer` | 問題分析 |
| Agent | `docs-writer` | 文檔產出 |

---

## 狀態更新

開發過程中持續更新 `PROJECT_STATE.md`：
```markdown
- [x] 後端開發 (DbC/CDD/PDD) - 完成
- [ ] 後端測試 - 進行中
```
