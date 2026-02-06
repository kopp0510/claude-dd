# DD Pipeline 開發實作 (DbC + CDD + PDD)

執行開發實作階段，依照契約進行組件化開發。

---

## 參數

- `--backend`：只執行後端開發
- `--frontend`：只執行前端開發
- `--fix`：修正模式（讀取失敗原因並修正）
- `--worktree`：建立 Git Worktree 隔離環境（可選）
- `--batch`：批次模式，每 3 個任務暫停等人工回饋（可選）
- `--classic`：使用舊版一次性實作模式（向後相容）

---

## 預設模式：微任務 + Subagent 驅動 (SADD)

預設使用微任務拆解 + Subagent 逐任務執行 + 兩階段審查。

### 後端開發流程

#### 0. Worktree 設定（僅 --worktree 時）

**調用 Skill: `worktree-manager`**
- 建立功能分支和隔離 worktree
- 安裝依賴、驗證基線測試
- 後續所有操作在 worktree 中進行

#### 1. 讀取架構和契約
- 讀取 `claude_docs/architecture/ARCHITECTURE.md`
- 讀取 `claude_docs/contracts/API_CONTRACT.md`
- 讀取 `claude_docs/examples/EXAMPLES.md`

#### 2. 微任務規劃

**調用 Skill: `task-planner`**
- 分析架構設計，拆分為最小可執行任務
- 建立依賴關係和拓撲排序
- 為每個任務撰寫 TDD 五步驟
- 產出 `claude_docs/plans/YYYY-MM-DD-<feature>.md`

#### 3. 執行策略

**預設 → 調用 Skill: `subagent-orchestrator`**
- 逐任務分派 subagent 執行
- 每個任務：實作 → 規格審查 → 品質審查
- 修復迴圈（最多 3 次）
- 每個任務通過後自動 git commit

**--batch → 批次模式**
- 同樣使用 subagent-orchestrator
- 每完成 3 個任務暫停等待人工回饋
- 使用者可在暫停點提出修改意見

**--classic → 舊版模式（見下方「經典模式」章節）**

#### 4. 效能優化

**調用 Agent: `performance-tuner`**
- 檢查 N+1 查詢問題
- 優化資料庫查詢
- 檢查記憶體使用
- 建議快取策略

#### 5. 安全檢查

**調用 Agent: `security-auditor`**
- 檢查 SQL Injection
- 檢查 XSS 漏洞
- 驗證輸入處理
- 檢查認證授權

#### 6. 程式碼重構

**調用 Agent: `refactor-expert`**
- 優化程式碼結構
- 移除重複程式碼
- 提升可維護性
- 確保命名一致性

#### 7. 產出文檔

**調用 Agent: `docs-writer`**
- 產出 API 文檔
- 更新技術文檔
- 加入程式碼註解

#### 8. Git commit
```bash
git add .
git commit -m "feat(backend): 實作後端功能"
```

如果使用 `--worktree`，commit 在 worktree 分支上。

#### 9. 自動進入測試
自動執行 `/dd-test --backend`

---

### 前端開發流程

#### 0. Worktree 設定（僅 --worktree 時）

**調用 Skill: `worktree-manager`**

#### 1. 讀取設計規格
- 讀取 `claude_docs/design/DESIGN_SPEC.md`
- 讀取 `claude_docs/contracts/API_CONTRACT.md`
- 讀取 `claude_docs/examples/EXAMPLES.md`

#### 2. 微任務規劃

**調用 Skill: `task-planner`**
- 拆分前端組件為微任務
- 產出 `claude_docs/plans/YYYY-MM-DD-<feature>.md`

#### 3. 執行策略

**預設 → 調用 Skill: `subagent-orchestrator`**

**--batch → 批次模式**

**--classic → 舊版模式（見下方「經典模式」章節）**

#### 4. 設計一致性檢查

**調用 Skill: `ui-design-system`**
- 檢查設計一致性
- 套用 Design Token
- 確保響應式設計
- 檢查無障礙設計

#### 5. UX 審查

**調用 Skill: `ux-researcher-designer`**
- 審查使用者體驗
- 檢查互動流程
- 提出改進建議

#### 6. 程式碼重構

**調用 Agent: `refactor-expert`**

#### 7. 產出文檔

**調用 Agent: `docs-writer`**
- 產出組件文檔
- 加入 Props 說明

#### 8. Git commit
```bash
git add .
git commit -m "feat(frontend): 實作前端功能"
```

#### 9. 自動進入測試
自動執行 `/dd-test --frontend`

---

## 經典模式 (--classic)

使用舊版一次性實作模式，不拆分微任務、不使用 subagent。

### 後端經典流程

1. **讀取架構和契約**（同上）

2. **優化開發 Prompt (PDD)**

   **調用 Skill: `senior-prompt-engineer`**
   - 分析開發任務
   - 優化開發指令
   - 確保 AI 準確理解任務

3. **後端實作 (DbC + CDD)**

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

4-9. 效能/安全/重構/文檔/Git/測試（同預設模式步驟 4-9）

### 前端經典流程

1. **讀取設計規格**（同上）

2. **優化開發 Prompt (PDD)**

   **調用 Skill: `senior-prompt-engineer`**

3. **前端實作 (CDD)**

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

4-9. 設計/UX/重構/文檔/Git/測試（同預設模式步驟 4-9）

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

| 類型 | 名稱 | 用途 | 模式 |
|------|------|------|------|
| Skill | `task-planner` | 微任務規劃 | 預設/批次 |
| Skill | `subagent-orchestrator` | Subagent 分派執行 | 預設/批次 |
| Skill | `worktree-manager` | Git Worktree 隔離 | --worktree |
| Skill | `senior-prompt-engineer` | Prompt 優化 | 經典 |
| Skill | `senior-backend` | 後端開發 | 經典 |
| Skill | `senior-frontend` | 前端開發 | 經典 |
| Skill | `ui-design-system` | 設計一致性 | 所有 |
| Skill | `ux-researcher-designer` | UX 審查 | 所有 |
| Agent | `performance-tuner` | 效能優化 | 所有 |
| Agent | `security-auditor` | 安全檢查 | 所有 |
| Agent | `refactor-expert` | 程式碼重構 | 所有 |
| Agent | `root-cause-analyzer` | 問題分析 | --fix |
| Agent | `docs-writer` | 文檔產出 | 所有 |

---

## 狀態更新

開發過程中持續更新 `PROJECT_STATE.md`：
```markdown
- [x] 後端開發 (DbC/CDD/PDD) - 完成
- [ ] 後端測試 - 進行中
```
