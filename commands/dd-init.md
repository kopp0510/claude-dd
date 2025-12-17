# DD Pipeline 初始化

初始化專案的 DD Pipeline 結構，建立必要的目錄和設定檔。
支援**新專案**（空目錄）和**現有專案**（已有程式碼）兩種模式。

---

## 執行步驟

### Phase 0: 專案類型判斷

1. **掃描目錄內容**，檢查是否為現有專案：

   使用 **Glob** 工具檢查以下檔案：
   - `package.json` → Node.js 專案
   - `go.mod` → Go 專案
   - `requirements.txt` / `pyproject.toml` / `setup.py` → Python 專案
   - `Cargo.toml` → Rust 專案
   - `pom.xml` / `build.gradle` → Java 專案
   - `composer.json` → PHP 專案
   - `Gemfile` → Ruby 專案

   使用 **Bash** `ls` 列出頂層目錄結構。

2. **檢查是否已有 CLAUDE.md**：

   使用 **Glob** 檢查 `CLAUDE.md` 是否存在。
   - 如果存在 → 記錄 `HAS_CLAUDE_MD = true`，後續將採用「補充模式」
   - 如果不存在 → 記錄 `HAS_CLAUDE_MD = false`，後續將採用「建立模式」

3. **判斷結果**：
   - 如果沒有發現任何程式碼或設定檔 → **新專案**，跳到 Phase 1
   - 如果發現現有專案指標 → **現有專案**，進入 Phase A

---

### Phase A: 現有專案分析（僅限現有專案）

1. **啟動 Explore Agent 分析專案**：

   使用 **Task** 工具（subagent_type: `Explore`）：
   ```
   分析此專案並提供以下資訊，以結構化格式回報：

   1. 技術棧
      - 主要語言
      - 後端框架（如有）
      - 前端框架（如有）
      - 資料庫（如有）

   2. 專案類型
      - 純後端 API / 純前端 SPA / 全端應用 / CLI 工具 / 函式庫

   3. 目錄結構
      - 列出主要目錄及其用途
      - 識別後端/前端程式碼位置

   4. 現有功能概覽
      - API 端點數量和路徑
      - 頁面/路由數量
      - 主要組件數量

   5. 測試設定
      - 測試框架
      - 測試目錄位置

   6. 程式碼規範
      - Linter（ESLint, Prettier, etc.）
      - 格式化工具

   7. 主要依賴
      - 列出 5-10 個核心依賴套件
   ```

2. **整理偵測結果**，格式化為易讀的摘要。

3. **顯示偵測結果並請求確認**：

   使用 **AskUserQuestion** 工具：
   ```
   我分析了你的專案，發現以下內容：

   📦 專案類型: [偵測結果]

   🛠️ 技術棧:
   - 後端: [偵測結果]
   - 前端: [偵測結果]
   - 資料庫: [偵測結果]
   - 測試框架: [偵測結果]

   📁 目錄結構:
   - [目錄1] - [用途]
   - [目錄2] - [用途]
   ...

   📊 現有功能:
   - [X] 個 API 端點
   - [Y] 個頁面/組件
   ...

   請確認以上資訊是否正確？

   選項：
   1. 確認正確，繼續初始化
   2. 修改專案類型
   3. 修改技術棧
   4. 補充其他資訊
   ```

4. **處理用戶回饋**：
   - 如果選擇「確認正確」→ 跳到 Phase 2
   - 如果選擇「修改」→ 使用 **AskUserQuestion** 詢問正確的值，更新偵測結果
   - 如果選擇「補充其他」→ 詢問要補充的內容

---

### Phase 1: 詢問專案類型（僅限新專案）

使用 **AskUserQuestion** 詢問：

1. **專案類型**：
   - 純後端 API
   - 純前端 SPA
   - 全端應用
   - CLI 工具

2. **技術棧**（根據專案類型）：
   - 後端：Node.js / Go / Python / 其他
   - 前端：React / Vue / Svelte / 其他
   - 資料庫：PostgreSQL / MongoDB / MySQL / 無

3. **專案名稱和描述**

---

### Phase 2: 建立目錄結構

使用 **Bash** 建立目錄：

```
./
├── CLAUDE.md                    # 專案設定
├── PROJECT_STATE.md             # 流程狀態追蹤
└── claude_docs/
    ├── requirements/            # 需求文檔 (RDD)
    ├── architecture/            # 架構文檔 (SDD/DDD)
    ├── contracts/               # API 契約 (DbC)
    ├── decisions/               # 架構決策記錄 (ADD)
    ├── examples/                # 行為範例 (EDD)
    ├── design/                  # UI/UX 設計
    └── reports/                 # 測試報告
```

**注意**：如果是現有專案，使用偵測到的目錄名稱填入 CLAUDE.md（例如：`server/` 而非 `backend/`）。

---

### Phase 3: 處理 CLAUDE.md

根據 Phase 0 的檢查結果，分兩種模式處理：

#### 模式 A: 建立模式（HAS_CLAUDE_MD = false）

使用 **Write** 工具，根據模板產生全新的 `CLAUDE.md`：

填入以下資訊（來自偵測結果或用戶輸入）：
- 專案名稱和概述
- 技術棧設定
- DD 流程設定（預設全部啟用）
- 開發模式（根據專案類型）
- 目錄結構說明（使用實際目錄名稱）
- 程式碼規範（使用偵測到的 Linter 設定）
- 排除項目（node_modules、.env 等）

#### 模式 B: 補充模式（HAS_CLAUDE_MD = true）

1. 使用 **Read** 工具讀取現有的 `CLAUDE.md` 內容

2. 檢查是否已包含 DD Pipeline 設定（搜尋 `## DD 流程設定` 或 `DD Pipeline`）：
   - 如果已存在 → 顯示訊息「DD Pipeline 已初始化」，跳過此步驟
   - 如果不存在 → 繼續補充

3. 使用 **Edit** 工具，在 `CLAUDE.md` 末尾補充 DD Pipeline 區塊：

```markdown
---

## DD Pipeline 設定

> 此區塊由 `/dd-init` 自動產生

### 開發模式
{{DEV_MODE}}
<!-- 可選值：純後端 | 純前端 | 全端應用 | CLI 工具 -->

### 啟用的 DD 方法論
- [x] RDD - 需求驅動開發
- [x] SDD - 系統結構設計
- [x] DDD - 領域模型設計
- [x] ADD - 架構決策記錄
- [x] EDD - 範例驅動設計
- [x] DbC - 契約驅動開發
- [x] CDD - 元件驅動開發
- [x] TDD - 測試驅動開發
- [x] PDD - 提示驅動開發

### 測試設定
- 最大重試次數：3
- 需要 E2E 測試：{{NEED_E2E}}
- 需要 UI/UX 審查：{{NEED_UX_REVIEW}}

### DD 文檔目錄
```
claude_docs/
├── requirements/    # 需求文檔 (RDD)
├── architecture/    # 架構文檔 (SDD/DDD)
├── contracts/       # API 契約 (DbC)
├── decisions/       # ADR 決策記錄 (ADD)
├── examples/        # 行為範例 (EDD)
├── design/          # UI/UX 設計
└── reports/         # 測試報告
```

### Agent/Skill 偏好
- 架構設計：systems-architect, senior-architect
- 後端開發：senior-backend
- 前端開發：senior-frontend
- 測試驗證：test-engineer, senior-qa
- 安全審計：security-auditor

### DD 排除項目
<!-- DD 流程不應修改的檔案或目錄 -->
- node_modules/
- .env
- .env.local
- dist/
- build/
```

4. 顯示補充完成訊息：
   ```
   ✅ 已在現有 CLAUDE.md 中補充 DD Pipeline 設定
   ```

---

### Phase 4: 產生 PROJECT_STATE.md

使用 **Write** 工具，根據模板產生 `PROJECT_STATE.md`：

- 所有階段設為「待開始」
- 記錄初始化時間
- 設定下一步為 `/dd-start`

---

### Phase 5: Git commit

如果在 git repo 中，使用 **Bash** 執行：

```bash
git add CLAUDE.md PROJECT_STATE.md claude_docs/
git commit -m "chore: 初始化 DD Pipeline 專案結構"
```

---

### Phase 6: 顯示完成訊息

根據專案類型和 CLAUDE.md 狀態顯示適當的訊息：

**情況 1: 新專案（無 CLAUDE.md）**：
```
✅ DD Pipeline 初始化完成！

已建立：
├── CLAUDE.md
├── PROJECT_STATE.md
└── claude_docs/ (7 個子目錄)

📌 下一步：
/dd-start <需求描述>

範例：
/dd-start 建立一個待辦事項管理系統，支援新增、編輯、刪除和標記完成
```

**情況 2: 現有專案（無 CLAUDE.md）**：
```
✅ DD Pipeline 初始化完成！

已分析現有專案並建立：
├── CLAUDE.md（已填入偵測到的技術棧）
├── PROJECT_STATE.md
└── claude_docs/ (7 個子目錄)

📊 專案概覽：
- 類型：[專案類型]
- 技術棧：[技術棧摘要]
- 現有功能：[功能數量]

📌 下一步：
/dd-start <新功能需求> 或 /dd-start --analyze（分析現有功能產生需求文檔）
```

**情況 3: 現有專案（已有 CLAUDE.md）**：
```
✅ DD Pipeline 初始化完成！

已在現有 CLAUDE.md 中補充 DD Pipeline 設定：
├── CLAUDE.md（已補充 DD 設定區塊）
├── PROJECT_STATE.md（新建立）
└── claude_docs/ (7 個子目錄)

📊 專案概覽：
- 類型：[專案類型]
- 技術棧：[技術棧摘要]
- 現有功能：[功能數量]

💡 提示：
原有的 CLAUDE.md 內容已保留，DD Pipeline 設定已補充至檔案末尾。
如需調整 DD 設定，請編輯 CLAUDE.md 中的「DD Pipeline 設定」區塊。

📌 下一步：
/dd-start <新功能需求> 或 /dd-start --analyze（分析現有功能產生需求文檔）
```

---

## 模板位置

模板檔案位於：`~/.claude/templates/dd/`

- `CLAUDE.md.template`
- `PROJECT_STATE.md.template`

---

## 使用的工具

| 工具 | 用途 |
|------|------|
| **Glob** | 檢查專案設定檔、CLAUDE.md 是否存在 |
| **Bash** | 列出目錄、建立資料夾、執行 git |
| **Task** (Explore) | 分析現有專案結構和程式碼 |
| **AskUserQuestion** | 顯示偵測結果、詢問確認、收集輸入 |
| **Read** | 讀取現有的 CLAUDE.md 內容 |
| **Write** | 建立新的 CLAUDE.md、PROJECT_STATE.md |
| **Edit** | 在現有 CLAUDE.md 中補充 DD 設定 |

---

## 流程圖

```
/dd-init
    │
    ▼
┌───────────────────────────────┐
│ Phase 0: 掃描目錄              │
│ - 檢查是否有程式碼檔案          │
│ - 檢查是否已有 CLAUDE.md       │
└──────────────┬────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
   [空目錄]       [有程式碼]
        │             │
        ▼             ▼
   Phase 1        Phase A
   詢問類型       Explore 分析
        │             │
        │             ▼
        │        顯示偵測結果
        │        請求用戶確認
        │             │
        └──────┬──────┘
               │
               ▼
        Phase 2: 建立目錄
               │
               ▼
┌───────────────────────────────┐
│ Phase 3: 處理 CLAUDE.md       │
│                               │
│  ┌─────────┬─────────┐        │
│  │         │         │        │
│  ▼         ▼         ▼        │
│ 新建     新建      補充       │
│ (新專案) (現有專案) (已有檔案) │
└──────────────┬────────────────┘
               │
               ▼
        Phase 4: 產生 PROJECT_STATE.md
               │
               ▼
        Phase 5: Git commit
               │
               ▼
        Phase 6: 顯示完成訊息
               │
        ┌──────┼──────┐
        │      │      │
        ▼      ▼      ▼
      情況1  情況2  情況3
      新專案 現有   現有+已有
             專案   CLAUDE.md
```
