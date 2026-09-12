---
description: 初始化專案的 8 步開發迴圈 — 蓋章專案 CLAUDE.md、掛 pre-commit gate、建截圖目錄、確認 plugin 依賴
---

# DD 初始化 — 8 步開發迴圈

初始化專案的開發慣例：蓋章「8 步開發迴圈」到專案 CLAUDE.md、建立截圖目錄、
確認巢狀 CLAUDE.md 維護依賴。支援**新專案**（空目錄）和**現有專案**（已有程式碼）。

> 2026-07 重整：原多階段 DD Pipeline（dd-start/arch/approve/dev/test）已封存、
> 2026-08-04 刪除（見 git 歷史）。本指令改為部署經實際專案實戰驗證的輕量開發迴圈。

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

- **建立模式**：用 **Write** 寫入下方區塊
- **補充模式**（CLAUDE.md 已存在）：
  - 無 `## 開發流程` 區塊 → 用 **Edit** 在末尾加入
  - 已含區塊 → **版本檢查**：
    - 含 `dd-loop-version: 8step` 且含 `dd-loop-rev: 2` → 已是現行版，跳過並告知
    - 含 `6step` / `7step` 標記、有 `8step` 但沒有 `dd-loop-rev: 2`，或無標記、或缺 code-review 步驟 → 舊版/手寫版：
      列出與現行版的差異（6step 缺步驟 7、8；7step 缺步驟 8；8step 沒有 rev 缺「段落起點」，
      步驟 3、4、8 只看最後一個 commit），
      **AskUserQuestion 詢問是否升級**。同意 → 升級為現行版但**保留在地內容**
      （專案特有註記、具體驗證指令、額外規則行），補上版本標記；拒絕 → 保留原樣

**依 Phase 0 偵測結果填入具體驗證指令**，不留模板變數：

```markdown
## 開發流程（每個功能段落依序走）
<!-- dd-loop-version: 8step；dd-loop-rev: 2；供 /dd-init 判斷是否提議升級，勿刪 -->

段落開始前先記起點：`~/.claude/scripts/check-claude-md.sh --start-segment`，印出「段落起點：…」才算記好。
沒印出這行就是沒記好；若是舊版 gate（grep 不到 `--start-segment`），它會照常檢查 staged，印出「commit 已擋下」也不要照著補檔或 commit，
先到 claude-dd repo 跑 `git pull && ./install-dd-pipeline.sh --force`。
一段常有好幾個 commit，步驟 3、4、8 都看「起點到現在」的整段；`<起點>` = `~/.claude/scripts/check-claude-md.sh --segment-base` 的輸出
（exit 非 0 或輸出是空的 = 範圍沒算出來，不是範圍為空）。忘了記下一段的起點時，範圍會連上一段一起算——只會多審，不會漏。

1. **實作功能 + 首輪測試通過**（相關既有測試跑綠 + 基本手動驗證，不可帶紅燈進 commit）
2. **commit**（第一次 — 保留簡化前還原點）
3. 跑 **code-simplifier**（對該段新增/修改的程式碼：`git diff <起點>`，官方 agent）
4. 跑 **code-review**（該段 diff；每段全量跑；修掉 Critical/Important 才續行）
   - 範圍要明講給 reviewer：依序跑時 `git diff <起點>` 加上 `git ls-files --others --exclude-standard`（步驟 3 新增、還沒 commit 的檔案 `git diff` 看不到）
   - 與步驟 3 並行時用 `git diff <起點> HEAD`，並要求 reviewer 一律用 `git show HEAD:<路徑>` 取檔案、不讀工作目錄（simplifier 正在改，讀到一半會被換掉）
5. **再測一次** — 確認步驟 3、4 沒破壞行為，不可只跑單元測試：
   - 重跑步驟 1 的相關測試
   - <依偵測結果填入：curl 打真實 API 驗證後端邏輯（登入/CRUD/權限…）>
   - <依偵測結果填入：playwright 真的開瀏覽器登入、操作 UI、截圖驗證前端可用>
     - 截圖一律存 `.screenshots/`（已 gitignore）；勿丟專案根目錄
     - ⚠️ **React 專案**：`browser_click` / `browser_fill_form` 常常不觸發 onClick 與
       受控輸入（工具回報成功但畫面 state 沒變，照著它的回報就會宣稱「測過了」其實沒點到）。
       改用 `browser_evaluate` 直接操作 DOM；填欄位要用 native value setter 再 dispatch
       `input`，否則 React 讀不到值：
       ```js
       const set = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
       set.call(el, v); el.dispatchEvent(new Event('input', { bubbles: true }));
       ```
       表單送不出去時（後端零請求）改用 `form.requestSubmit()`。
       **判斷有沒有真的送出，看後端有沒有收到請求，不是看畫面。** 拿不到後端 log 時，
       在瀏覽器裡數請求數也算數（驗「前端擋下來、根本沒送出」特別好用）：
       `performance.getEntriesByType('resource').filter(r => r.name.includes('/api/x')).length`
6. **再 commit**（最終版本）
7. **沉澱本輪所學**（有才做）— 本輪若留下踩雷、指令或慣例，用
   claude-md-management plugin 的 /revise-claude-md 寫進 CLAUDE.md；
   它會先列出建議、等你同意才寫檔。沒有值得留的就跳過
8. **評分 & 修正本輪動過的 CLAUDE.md** — 第一個動作是算範圍，不是開始審：
   `base=$(~/.claude/scripts/check-claude-md.sh --segment-base) && [ -n "$base" ] && { git -c core.quotePath=false diff --name-only "$base" HEAD; git -c core.quotePath=false status --porcelain -uall | awk '{print $NF}'; } | grep 'CLAUDE\.md$' | sort -u`
   算出幾份就只審那幾份（用 claude-md-improver）。該 skill 預設會 find 全部，
   不先算範圍會全 repo 掃。範圍是空的才跳過（指令 exit 非 0 是範圍沒算出來，不算空）

驗證不過 → 修完重跑步驟 5，不可帶著紅燈進步驟 6。

## CLAUDE.md 維護

- 每個有程式碼的資料夾都要有 CLAUDE.md（說明該層職責與慣例）
- 功能落地後，受影響目錄的 CLAUDE.md 逐層堆疊更新（程式碼改了 → 文件跟著改，pre-commit gate 會擋）
- 步驟 7 處理的是「本輪學到什麼」，與上一條的「程式碼改了所以文件要同步」是兩件事
- **步驟 7 跳過不代表步驟 8 跳過**：步驟 2、6 被 gate 逼著更新的 CLAUDE.md
  也要進步驟 8 的範圍 — gate 只確認「有寫」、不確認「寫得對」
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

1. 檢查 `~/.claude/scripts/check-claude-md.sh` 存在（不存在 → 提示跑 `./install-dd-pipeline.sh --force`，跳過本 Phase）；
   存在但 `grep -q -- '--start-segment' ~/.claude/scripts/check-claude-md.sh` 找不到 → 是舊版 gate
   （不認得段落起點參數：沒有 staged 時什麼都不印，有 staged 程式碼時照常擋 commit），
   提示到 claude-dd repo 跑 `git pull && ./install-dd-pipeline.sh --force` 更新，掛載照常進行
2. 先查 `git config --get core.hooksPath`：有值時 git 會**完全忽略** `.git/hooks/`，
   gate 掛載點改為該目錄下的 `pre-commit`（該檔已含 `check-claude-md.sh` 呼叫
   → 跳過並告知；如 claude-dd repo 自身的 `scripts/githooks` 即此情況）；
   無值時掛載點為 `.git/hooks/pre-commit`
3. 檢查掛載點的 `pre-commit`：
   - 不存在 → 用 **Write** 建立：

     ```bash
     #!/bin/sh
     # CLAUDE.md gate — 由 /dd-init 安裝；規則：改碼目錄需有 CLAUDE.md 且同批更新
     "$HOME/.claude/scripts/check-claude-md.sh" || exit 1
     ```

     然後對掛載點檔案 `chmod +x`
   - 已存在且未含 `check-claude-md.sh` → 在檔尾 **Edit** 追加上面的呼叫行（保留既有內容）
   - 已含 → 跳過並告知
4. 告知使用者 gate 行為：缺 CLAUDE.md 或改碼未同步更新 → commit 被擋；
   檢查點 commit（迴圈步驟 2）可用 `SKIP_DOC_CHECK=1 git commit`，最終 commit（步驟 6）必須全過；
   SKIP 過的目錄會記帳，之後第一個正常 commit（就算沒改程式碼）一樣要補上它們的 CLAUDE.md

### Phase 4: 檢查巢狀 CLAUDE.md 依賴

1. 檢查 `claude-md-management` plugin 是否已啟用（讀 `~/.claude/settings.json` 的
   `enabledPlugins` 是否含 `claude-md-management@claude-plugins-official`）：
   - 未啟用 → 提示執行 `./install-dd-pipeline.sh --force`（腳本會裝）或
     `claude plugin install claude-md-management@claude-plugins-official`
2. 現有專案且尚無巢狀 CLAUDE.md → 提示：可對主要目錄（如 `backend/`、`frontend/`）
   逐步補 CLAUDE.md，不強制一次補齊

### Phase 5: Git commit

在 git repo 中時：

```bash
git add CLAUDE.md
[ -f .gitignore ] && git add .gitignore
git diff --cached --quiet || git commit -m "chore: 初始化 8 步開發迴圈慣例"
```

⚠️ **不可寫成 `git add CLAUDE.md .gitignore`**：`git add` 是全有全無，純後端/CLI 專案沒有
`.gitignore`（Phase 2 只在有前端時建），整條會以 exit 128 失敗、**連 CLAUDE.md 也不會被 stage**，
蓋章好的檔案就這樣留在 untracked。加 `2>/dev/null || true` 只是把錯誤吞掉，Phase 6 照樣印「✅ 初始化完成」。
最後一行的 `git diff --cached --quiet ||` 是給「Phase 1 判定已是現行版、零 staged」的情況用的，
沒有它 `git commit` 會以「沒有要提交的檔案」失敗。

> 註：`.git/hooks/` 不入版控，pre-commit gate 不需 add。
>
> **gate 看的是整個 index，不是只看這次新 add 的檔案**。使用者原本就有 staged 的程式碼變更時，
> 這個 commit 一樣會被擋（那些目錄缺 CLAUDE.md 或沒同批更新）。被擋時不要用 `SKIP_DOC_CHECK=1` 繞過 —— 那會記一筆欠帳；
> 先 `git status` 看是誰的變更，把不屬於初始化的先 `git restore --staged`，或照 gate 的訊息補上該目錄的 CLAUDE.md。

### Phase 6: 完成訊息

```
✅ 初始化完成！

已設定：
├── CLAUDE.md — 8 步開發迴圈（驗證方式：<偵測結果>）
├── .screenshots/ + .gitignore（有前端時）
├── pre-commit gate — 改碼目錄缺 CLAUDE.md 或未同步更新會擋 commit
└── claude-md-management plugin 檢查

📌 開始開發：
實作+測試 → commit → code-simplifier → code-review → 再測(curl/playwright) → commit
  → 沉澱本輪所學 → 評分&修正
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
