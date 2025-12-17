# DD Pipeline 文檔產生

為現有程式碼分析並產生 DD Pipeline 文檔。
適用於已有程式碼但尚未建立完整文檔的專案。

---

## 使用方式

```bash
# 產生所有文檔
/dd-docs

# 產生特定類型文檔
/dd-docs --requirements    # 需求文檔
/dd-docs --architecture    # 架構文檔
/dd-docs --api             # API 契約文檔
/dd-docs --examples        # 行為範例文檔
/dd-docs --design          # UI/UX 設計文檔

# 組合使用
/dd-docs --api --examples
```

---

## 執行步驟

### Phase 0: 前置檢查

1. **檢查 DD Pipeline 是否已初始化**：
   - 檢查 `CLAUDE.md` 是否包含 DD Pipeline 設定
   - 檢查 `claude_docs/` 目錄是否存在
   - 如果未初始化 → 提示用戶先執行 `/dd-init`

2. **讀取專案設定**：
   - 從 `CLAUDE.md` 讀取技術棧、專案類型、目錄結構
   - 從 `PROJECT_STATE.md` 讀取當前狀態

3. **判斷要產生的文檔**：
   - 如果有指定參數 → 只產生指定的文檔
   - 如果沒有參數 → 進入 Phase 1 詢問用戶

---

### Phase 1: 選擇文檔類型（無參數時）

使用 **AskUserQuestion** 詢問要產生哪些文檔：

```
請選擇要產生的文檔類型（可多選）：

□ 需求文檔 (REQUIREMENTS.md)
  - 分析現有功能，產生需求規格

□ 架構文檔 (ARCHITECTURE.md)
  - 分析程式碼結構，產生系統架構說明

□ API 契約 (API_CONTRACT.md)
  - 掃描 API 端點，產生完整的 API 文檔

□ 架構決策記錄 (ADR-XXX.md)
  - 根據技術選型，產生架構決策記錄

□ 行為範例 (EXAMPLES.md)
  - 分析現有測試/使用方式，產生行為範例

□ UI/UX 設計 (DESIGN_SPEC.md)
  - 分析前端組件，產生設計規格

□ 全部產生
  - 產生以上所有文檔
```

---

### Phase 2: 程式碼分析

根據選擇的文檔類型，啟動對應的分析流程：

#### 2.1 需求分析（REQUIREMENTS.md）

使用 **Task** 工具（subagent_type: `Explore`）：
```
分析此專案的現有功能，提供以下資訊：

1. 核心功能列表
   - 功能名稱
   - 功能描述
   - 相關檔案

2. 使用者故事推導
   - 作為 [角色]
   - 我想要 [功能]
   - 以便 [目的]

3. 功能性需求
   - 輸入/輸出規格
   - 業務邏輯規則

4. 非功能性需求（從程式碼推導）
   - 效能考量
   - 安全性考量
```

使用 **Skill**：`ux-researcher-designer`、`senior-prompt-engineer`

---

#### 2.2 架構分析（ARCHITECTURE.md）

使用 **Task** 工具（subagent_type: `systems-architect`）：
```
分析此專案的系統架構，提供以下資訊：

1. 系統概覽
   - 架構風格（Monolith/Microservices/Serverless）
   - 主要模組和職責

2. 技術架構
   - 分層架構圖
   - 資料流圖
   - 部署架構

3. 模組說明
   - 各模組職責
   - 模組間依賴關係

4. 資料模型
   - Entity/Schema 定義
   - 關聯關係

5. 第三方整合
   - 外部服務
   - API 整合
```

使用 **Skill**：`senior-architect`、`senior-fullstack`

---

#### 2.3 API 契約分析（API_CONTRACT.md）

使用 **Task** 工具（subagent_type: `Explore`）：
```
掃描此專案的所有 API 端點，提供以下資訊：

1. API 端點列表
   - HTTP Method
   - 路徑
   - 說明

2. 每個端點的詳細規格
   - Request 格式（Headers, Body, Query Params）
   - Response 格式（成功/錯誤）
   - 認證需求

3. 資料模型
   - Request/Response DTO
   - 欄位說明和驗證規則

4. 錯誤碼定義
   - HTTP Status Code
   - 業務錯誤碼
```

使用 **Skill**：`senior-backend`

---

#### 2.4 架構決策記錄（ADR-XXX.md）

使用 **Task** 工具（subagent_type: `systems-architect`）：
```
分析此專案的技術選型，為每個重大決策產生 ADR：

1. 識別架構決策
   - 使用的框架和原因
   - 資料庫選擇
   - 認證方案
   - 狀態管理方案
   - 部署方案

2. 每個決策包含
   - 標題
   - 狀態（已採用）
   - 背景
   - 決策
   - 後果
```

使用 **Skill**：`senior-architect`

---

#### 2.5 行為範例分析（EXAMPLES.md）

使用 **Task** 工具（subagent_type: `Explore`）：
```
分析此專案的使用方式和測試案例，產生行為範例：

1. 掃描現有測試
   - 單元測試
   - 整合測試
   - E2E 測試

2. 提取使用範例
   - Given（前置條件）
   - When（操作）
   - Then（預期結果）

3. API 使用範例
   - cURL 範例
   - SDK 使用範例

4. 邊界情況
   - 錯誤處理範例
   - 異常情況
```

使用 **Skill**：`senior-qa`

---

#### 2.6 UI/UX 設計分析（DESIGN_SPEC.md）

使用 **Task** 工具（subagent_type: `Explore`）：
```
分析此專案的前端組件和 UI 設計，提供以下資訊：

1. 組件清單
   - 組件名稱
   - 用途
   - Props/State

2. 頁面結構
   - 路由列表
   - 頁面組成

3. 設計系統
   - 顏色定義
   - 字型設定
   - 間距規則

4. 互動模式
   - 表單處理
   - 錯誤提示
   - 載入狀態
```

使用 **Skill**：`senior-frontend`、`ui-design-system`

---

### Phase 3: 文檔產生

根據分析結果，使用對應的 Agent/Skill 產生文檔：

| 文檔 | Agent | Skill | 模板 |
|------|-------|-------|------|
| REQUIREMENTS.md | docs-writer | senior-prompt-engineer | `templates/REQUIREMENTS.md.template` |
| ARCHITECTURE.md | systems-architect | senior-architect | `templates/ARCHITECTURE.md.template` |
| API_CONTRACT.md | docs-writer | senior-backend | `templates/API_CONTRACT.md.template` |
| ADR-XXX.md | systems-architect | senior-architect | `templates/ADR.md.template` |
| EXAMPLES.md | docs-writer | senior-qa | `templates/EXAMPLES.md.template` |
| DESIGN_SPEC.md | docs-writer | ui-design-system | （無模板，自由格式） |

使用 **Write** 工具將文檔寫入 `claude_docs/` 對應子目錄。

---

### Phase 4: 用戶確認

產生文檔後，顯示摘要讓用戶確認：

```
📝 文檔產生完成！

已產生以下文檔：
├── claude_docs/requirements/REQUIREMENTS.md
│   └── 識別 12 個功能需求、8 個使用者故事
├── claude_docs/architecture/ARCHITECTURE.md
│   └── 3 層架構、5 個核心模組
├── claude_docs/contracts/API_CONTRACT.md
│   └── 記錄 15 個 API 端點
├── claude_docs/decisions/ADR-001-framework.md
├── claude_docs/decisions/ADR-002-database.md
│   └── 產生 2 個架構決策記錄
└── claude_docs/examples/EXAMPLES.md
    └── 從 23 個測試案例提取範例

請檢視產生的文檔，如有需要修改：
- 直接編輯文檔檔案
- 使用 /dd-docs --api 重新產生特定文檔
```

---

### Phase 5: 更新狀態

1. **更新 PROJECT_STATE.md**：
   - 記錄已產生的文檔
   - 更新文檔狀態 checkbox

2. **Git commit**：
   ```bash
   git add claude_docs/
   git commit -m "docs: 為現有程式碼產生 DD Pipeline 文檔"
   ```

---

## 文檔輸出位置

```
claude_docs/
├── requirements/
│   └── REQUIREMENTS.md          # 需求文檔
├── architecture/
│   └── ARCHITECTURE.md          # 架構文檔
├── contracts/
│   └── API_CONTRACT.md          # API 契約
├── decisions/
│   ├── ADR-001-xxx.md           # 架構決策記錄
│   ├── ADR-002-xxx.md
│   └── ...
├── examples/
│   └── EXAMPLES.md              # 行為範例
└── design/
    └── DESIGN_SPEC.md           # UI/UX 設計（前端專案）
```

---

## 使用的工具

| 工具 | 用途 |
|------|------|
| **Glob** | 檢查 DD Pipeline 初始化狀態 |
| **Read** | 讀取 CLAUDE.md、PROJECT_STATE.md |
| **Task** (Explore) | 分析程式碼結構和功能 |
| **Task** (systems-architect) | 分析系統架構 |
| **AskUserQuestion** | 詢問要產生的文檔類型 |
| **Skill** | 調用專業技能產生文檔 |
| **Write** | 寫入文檔檔案 |
| **Bash** | 執行 git 命令 |

---

## 使用的 Agents

| Agent | 職責 |
|-------|------|
| `docs-writer` | 撰寫各類文檔 |
| `systems-architect` | 架構分析和 ADR 產生 |

---

## 使用的 Skills

| Skill | 用於文檔 |
|-------|---------|
| `senior-architect` | ARCHITECTURE.md, ADR |
| `senior-backend` | API_CONTRACT.md |
| `senior-frontend` | DESIGN_SPEC.md |
| `senior-fullstack` | ARCHITECTURE.md |
| `senior-qa` | EXAMPLES.md |
| `senior-prompt-engineer` | REQUIREMENTS.md |
| `ux-researcher-designer` | REQUIREMENTS.md |
| `ui-design-system` | DESIGN_SPEC.md |

---

## 流程圖

```
/dd-docs [--options]
        │
        ▼
┌─────────────────────────┐
│ Phase 0: 前置檢查        │
│ - DD Pipeline 已初始化？ │
│ - 讀取專案設定           │
└───────────┬─────────────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
[有參數]       [無參數]
     │             │
     │             ▼
     │      Phase 1: 詢問
     │      要產生哪些文檔
     │             │
     └──────┬──────┘
            │
            ▼
┌─────────────────────────┐
│ Phase 2: 程式碼分析      │
│                         │
│ ┌─────┬─────┬─────┐     │
│ │     │     │     │     │
│ ▼     ▼     ▼     ▼     │
│需求  架構  API  範例    │
│分析  分析  分析  分析    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Phase 3: 文檔產生        │
│ 使用 docs-writer Agent  │
│ 寫入 claude_docs/       │
└───────────┬─────────────┘
            │
            ▼
     Phase 4: 顯示摘要
            │
            ▼
     Phase 5: 更新狀態
     Git commit
```

---

## 注意事項

1. **不會覆蓋現有文檔**：如果文檔已存在，會詢問用戶是否要覆蓋或合併
2. **增量更新**：可多次執行，每次只更新選擇的文檔
3. **人工審核建議**：自動產生的文檔建議人工審核後再使用
4. **程式碼註解優先**：如果程式碼有良好的註解，會優先使用註解內容
