# DD 初始化 — 6 步開發迴圈

初始化專案的開發慣例：蓋章「6 步開發迴圈」到專案 CLAUDE.md、建立截圖目錄、
確認巢狀 CLAUDE.md 維護依賴。支援**新專案**（空目錄）和**現有專案**（已有程式碼）。

> 2026-07 重整：原多階段 DD Pipeline（dd-start/arch/approve/dev/test）已封存至
> deprecated 桶。本指令改為部署經 lawdesk-ai 實戰驗證的輕量開發迴圈。

---

## 執行步驟

### Phase 0: 專案偵測

1. **掃描目錄內容**，用 **Glob** 檢查專案類型指標：
   - `package.json` → Node.js、`go.mod` → Go、`pyproject.toml`/`requirements.txt` → Python
   - `Cargo.toml` → Rust、`pom.xml`/`build.gradle` → Java、`composer.json` → PHP、`Gemfile` → Ruby
   - 前端框架：偵測 `next.config.*`、`vite.config.*`、`src/App.*` 等

2. **判斷驗證方式**（填入迴圈步驟 5 的具體指令）：
   - 有 HTTP API（後端/全端）→ 驗證含 **curl 打真實 API**
   - 有前端 UI → 驗證含 **playwright 開真實瀏覽器**（截圖存 `.screenshots/`）
   - 純 CLI / 函式庫 → 驗證退化為「跑真實指令 / 消費端範例」

3. **檢查 CLAUDE.md 是否存在**：
   - 存在 → 補充模式（在末尾加區塊）
   - 不存在 → 建立模式（現有專案先派 **Task**（subagent_type: `Explore`）分析技術棧與目錄結構，新專案用 **AskUserQuestion** 問專案類型/技術棧/名稱）

### Phase 1: 蓋章開發迴圈到專案 CLAUDE.md

用 **Write**（建立模式）或 **Edit**（補充模式；若已含 `## 開發流程` 區塊則跳過並告知）寫入。
**依 Phase 0 偵測結果填入具體驗證指令**，不留模板變數：

```markdown
## 開發流程（每個功能段落必走，不可省略）

1. **實作功能 + 首輪測試通過**（相關既有測試跑綠 + 基本手動驗證，不可帶紅燈進 commit）
2. **commit**（第一次 — 保留簡化前還原點）
3. 跑 **code-simplifier**（對該段新增/修改的程式碼，官方 agent）
4. 跑 **code-review**（該段 diff，每段全量跑；修掉 Critical/Important 才續行）
5. **再測一次** — 確認步驟 3、4 沒破壞行為，不可只跑單元測試：
   - 重跑步驟 1 的相關測試
   - <依偵測結果填入：curl 打真實 API 驗證後端邏輯（登入/CRUD/權限…）>
   - <依偵測結果填入：playwright 真的開瀏覽器登入、操作 UI、截圖驗證前端可用>
     - 截圖一律存 `.screenshots/`（已 gitignore）；勿丟專案根目錄
6. **再 commit**（最終版本）

驗證不過 → 修完重跑步驟 5，不可帶著紅燈進步驟 6。

## CLAUDE.md 維護

- 每個有程式碼的資料夾都要有 CLAUDE.md（說明該層職責與慣例）
- 功能落地後，受影響目錄的 CLAUDE.md 逐層堆疊更新（用 claude-md-management plugin 的 /revise-claude-md 或手動）
```

建立模式時，區塊前面先寫入標準專案資訊（專案名稱、技術棧、目錄結構 — 來自偵測或詢問結果）。

### Phase 2: 建立截圖目錄與 gitignore

僅在專案有前端 UI 時執行（純後端/CLI 跳過）：

```bash
mkdir -p .screenshots
grep -qxF '.screenshots/' .gitignore 2>/dev/null || echo '.screenshots/' >> .gitignore
```

### Phase 3: 安裝 CLAUDE.md pre-commit gate（block 版）

在 git repo 中時，把 `~/.claude/scripts/check-claude-md.sh` 掛進專案 pre-commit：

1. 檢查 `~/.claude/scripts/check-claude-md.sh` 存在（不存在 → 提示跑 `./install-dd-pipeline.sh --force`，跳過本 Phase）
2. 檢查 `.git/hooks/pre-commit`：
   - 不存在 → 用 **Write** 建立：

     ```bash
     #!/bin/sh
     # CLAUDE.md gate — 由 /dd-init 安裝；規則：改碼目錄需有 CLAUDE.md 且同批更新
     "$HOME/.claude/scripts/check-claude-md.sh" || exit 1
     ```

     然後 `chmod +x .git/hooks/pre-commit`
   - 已存在且未含 `check-claude-md.sh` → 在檔尾 **Edit** 追加上面的呼叫行（保留既有內容）
   - 已含 → 跳過並告知
3. 告知使用者 gate 行為：缺 CLAUDE.md 或改碼未同步更新 → commit 被擋；
   檢查點 commit（迴圈步驟 2）可用 `SKIP_DOC_CHECK=1 git commit`，最終 commit（步驟 6）必須全過

### Phase 4: 檢查巢狀 CLAUDE.md 依賴

1. 檢查 `claude-md-management` plugin 是否已啟用（讀 `~/.claude/settings.json` 的
   `enabledPlugins` 是否含 `claude-md-management@claude-plugins-official`）：
   - 未啟用 → 提示執行 `./install-dd-pipeline.sh --force`（腳本會裝）或
     `claude plugin install claude-md-management@claude-plugins-official`
2. 現有專案且尚無巢狀 CLAUDE.md → 提示：可對主要目錄（如 `backend/`、`frontend/`）
   逐步補 CLAUDE.md，不強制一次補齊

### Phase 5: Git commit

在 git repo 中時（`|| true` 容錯）：

```bash
git add CLAUDE.md .gitignore 2>/dev/null || true
git commit -m "chore: 初始化 6 步開發迴圈慣例"
```

> 註：`.git/hooks/` 不入版控，pre-commit gate 不需 add。此 commit 只動 CLAUDE.md/.gitignore，會通過 gate。

### Phase 6: 完成訊息

```
✅ 初始化完成！

已設定：
├── CLAUDE.md — 6 步開發迴圈（驗證方式：<偵測結果>）
├── .screenshots/ + .gitignore（有前端時）
├── pre-commit gate — 改碼目錄缺 CLAUDE.md 或未同步更新會擋 commit
└── claude-md-management plugin 檢查

📌 開始開發：
實作+測試 → commit → code-simplifier → code-review → 再測(curl/playwright) → commit
每個功能段落走一圈；CLAUDE.md 堆疊更新由 pre-commit gate 把關。
```

---

## 使用的工具

| 工具 | 用途 |
|------|------|
| **Glob** | 偵測專案類型與 CLAUDE.md 存在性 |
| **Task** (Explore) | 現有專案的技術棧與結構分析 |
| **AskUserQuestion** | 新專案的類型/技術棧詢問 |
| **Read / Write / Edit** | 讀寫 CLAUDE.md、.gitignore |
| **Bash** | 建目錄、git commit、plugin 檢查 |
