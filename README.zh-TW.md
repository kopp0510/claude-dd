[English](README.md) | [繁體中文](README.zh-TW.md)

# DD Pipeline（claude-dd）

> 可攜式 Claude Code 設定庫 — 把「AI 有沒有照規矩做」變成看得見、擋得住的輸出

![claude-dd 三層架構](diagrams/claude-dd-architecture.zh-TW.gif)

**是什麼**：跨機器可攜的 Claude Code profile（skills / agents / commands / 全域 CLAUDE.md）。
`git clone` 後跑一支 bash，整套工作習慣就裝進 `~/.claude/`；此 repo 是 source of truth。

**解決什麼**：用 AI 寫程式最難的不是寫不出來，是你不知道它有沒有跳步驟 —
測試跑了嗎？文件同步了嗎？剛才那句話是查證過還是編的？
這套設定把這些原本靠默契的環節，變成強制執行、留得下紀錄的輸出。

**適合誰**：已經在用 Claude Code，想把個人工作習慣固定下來、換機器也帶得走的開發者。

```bash
git clone https://github.com/kopp0510/claude-dd.git
cd claude-dd && ./install-dd-pipeline.sh
```

## 特色

- **6 步開發迴圈** — 每個功能段落必走：實作+測試 → commit → code-simplifier → code-review → 再測（curl/playwright 真實環境）→ commit
- **CLAUDE.md pre-commit gate** — 改碼目錄缺 CLAUDE.md 或未同批更新即擋 commit（block 版），錯誤訊息內建 AI 自主修復指令
- **零幻覺政策** — 涉及 API 簽名、版本號、專案事實時必須標註來源；「應該是」「大概」等模糊詞列為禁用
- **Skill 觸發顯性化** — 該觸發卻不觸發時必須寫出一行具體理由，讓「跳過」從黑箱變成可稽核紀錄
- **使用率盤點制** — 只保留有實證使用紀錄的元件並全數預設部署，避免閒置 skill 吃 context
- **全域 CLAUDE.md 模板** — 上述守則的單一來源，互動式比對部署到 `~/.claude/CLAUDE.md`

## 安裝

### 前置需求

- [Claude Code CLI](https://claude.com/claude-code)、Node.js、Git、Bash
- 必要 MCP：`playwright`（腳本只檢查不安裝，請先[安裝 playwright MCP](https://github.com/microsoft/playwright-mcp)）
- 可選：`ffmpeg`（tech-diagram-gif 的 GIF 匯出用；缺少時該 skill 退化交付 SVG。macOS `brew install ffmpeg`）

### 首次安裝

```bash
git clone https://github.com/kopp0510/claude-dd.git
cd claude-dd
./install-dd-pipeline.sh
```

> 若 `install-dd-pipeline.sh` 沒有執行權限，先 `chmod +x install-dd-pipeline.sh`。

安裝程式會：

1. 安裝 10 個 promoted Skills 到 `~/.claude/skills/`
2. 安裝 4 個 promoted Agents 到 `~/.claude/agents/`（code-simplifier / code-reviewer 官方備份 + senior-devops / security-auditor）
3. 啟用官方 Plugin（claude-md-management — 巢狀 CLAUDE.md 維護依賴）
4. 安裝 `/dd-init` + `workflow-review` 命名空間 Command 到 `~/.claude/commands/`
5. 部署 `check-claude-md.sh`（pre-commit gate 本體）到 `~/.claude/scripts/`
6. **互動式比對全域 CLAUDE.md**（`~/.claude/CLAUDE.md`）：若與 repo 模板不同，顯示 diff 並詢問是否覆蓋（預設保留本地）

### 安裝選項

```bash
./install-dd-pipeline.sh --help              # 顯示幫助
./install-dd-pipeline.sh --check             # 只檢查環境（不安裝）
./install-dd-pipeline.sh --force             # 強制重新安裝（覆蓋現有檔案）
./install-dd-pipeline.sh --commands-only     # 只安裝 Commands
./install-dd-pipeline.sh --update            # 更新 skills/agents
./install-dd-pipeline.sh --uninstall         # 解除安裝（本 repo 部署過的項目）
./install-dd-pipeline.sh --uninstall --yes   # 免確認解除安裝（自動化用；非互動環境的互動詢問一律採預設值）
```

### 分享給別人

安裝方式只有一種（含完整工作法：全域規則、6 步迴圈、pre-commit gate 與精選元件）：

```bash
git clone https://github.com/kopp0510/claude-dd && cd claude-dd && ./install-dd-pipeline.sh
```

全域 CLAUDE.md 走互動 diff，對方已有自己的全域規則時可先看差異再決定。

> 曾評估過 plugin marketplace 分發路線（2026-08-04 實測可行後移除）：plugin 機制
> 無法部署全域 CLAUDE.md 與 pre-commit gate，只能交付元件子集，與「完整工作法」
> 的定位不符，為維持單一路線而不採用。實作見 git 歷史。

## 升級

日常更新：

```bash
git pull && ./install-dd-pipeline.sh --force
```

從舊版部署（全量 / 分桶時期）升級、既有專案升級到 6 步迴圈：見 [UPGRADING.md](UPGRADING.md)。
歷次結構性變更見 [CHANGELOG.md](CHANGELOG.md)。

## 核心工作法：6 步開發迴圈

每個**功能段落**必走（定義於全域 CLAUDE.md §3.9，專案具體版由 `/dd-init` 蓋章）：

```
1. 實作功能 + 首輪測試通過（不可帶紅燈進 commit）
2. commit（第一次 — 保留簡化前還原點）
3. code-simplifier（該段 diff）
4. code-review（該段 diff，全量跑；修掉 Critical/Important 才續行）
5. 再測一次 — 重跑測試 + curl 打真實 API / playwright 真實瀏覽器操作（截圖存 .screenshots/）
6. commit（最終版本）
```

三個品質機制各管一軸：simplifier 管可讀性、code-review 管正確性/合規（含 12 項 Fowler 壞味道基準）、真實環境驗證管行為。

從零到日常的完整路徑（裝一次、每個專案蓋章一次、之後每個功能段落走同一個迴圈）：

![claude-dd 使用流程](diagrams/claude-dd-usage-flow.zh-TW.gif)

### CLAUDE.md 維護規則（pre-commit gate 強制）

- 每個含程式碼的資料夾都要有 CLAUDE.md；改碼時同批更新，並逐層堆疊更新上層
- gate（`~/.claude/scripts/check-claude-md.sh`，由 `/dd-init` 掛進專案 `.git/hooks/pre-commit`）擋下不合規 commit，錯誤訊息直接指示 AI agent 讀目錄自行產生/更新後重試
- 檢查點 commit（步驟 2）逃生口：`SKIP_DOC_CHECK=1 git commit`；最終 commit（步驟 6）必須全過

## 指令一覽

| 指令 | 說明 |
|------|------|
| `/dd-init` | 初始化專案：蓋章 6 步迴圈到 CLAUDE.md、掛 pre-commit gate、建 `.screenshots/`、檢查 plugin 依賴 |
| `/review`（workflow-review） | 綜合程式碼審查（安全、效能、配置） |

## Promoted Skills（預設部署，10 個）

| Skill | 說明 |
|-------|------|
| code-simplifier | 程式碼簡化（迴圈步驟 3 的 wrapper） |
| design-brainstorm | 蘇格拉底式設計對話（事實自己查、決策才問人） |
| frontend-design | 前端視覺設計 |
| review | 綜合審查 wrapper |
| self-improving-agent | 記憶審計與知識沉澱 |
| task-planner | 微任務拆解 |
| tech-diagram-gif | 技術圖表繪製與 GIF 匯出（風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)） |
| verification-gate | 完成前驗證閘門（宣稱完成須附新鮮證據） |
| worktree-manager | Git worktree 隔離 |
| writing-great-skills | skill 撰寫參考（vendored 自 [mattpocock/skills](https://github.com/mattpocock/skills)，user-invoked） |

## 官方 Plugins（安裝腳本管理）

| Plugin | 功能 |
|--------|------|
| claude-md-management | 巢狀 CLAUDE.md 稽核與更新（`claude-md-improver` skill + `/revise-claude-md`）— 6 步迴圈的文件維護依賴 |

## MCP

安裝腳本只檢查不安裝，且會**區分設定範圍**：設在 `~/.claude.json` 根層 `mcpServers`
（官方 scope 名稱 `user`，所有專案可用）才顯示 ✅；只設在個別專案下（官方 `local`）
標示「僅 N 個專案設定」— 那在其他專案用不到，對「跨機器可攜的工作法」而言等同未安裝。
解析不了 `~/.claude.json`（檔案損毀）或機器上無 jq / python3 時，回報「無法判定」而非「未安裝」。

> **限制**：官方第三種 scope（`project` — 專案根目錄的 `.mcp.json`）不在 `~/.claude.json` 內，
> 本檢查看不到，該情況會低報。要看完整實況以 `claude mcp list` 為準（三種 scope 都會列出）。

安裝 MCP 時建議指定 user scope，才是所有專案可用：

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
```

### 必要

| MCP | 說明 | 來源 |
|-----|------|------|
| playwright | 瀏覽器自動化（迴圈步驟 5 前端驗證） | [playwright-mcp](https://github.com/microsoft/playwright-mcp) |

### 可選

| MCP | 說明 | 來源 |
|-----|------|------|
| context7 | 取版本正確的函式庫官方文件（支撐全域 CLAUDE.md §2.5「禁止從名稱推論 API」） | [@upstash/context7-mcp](https://github.com/upstash/context7) |
| sequential-thinking | 循序思考推理 | [@modelcontextprotocol/server-sequential-thinking](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking) |
| serena | 智能程式碼助手 | [serena](https://github.com/oraios/serena) |
| cipher | AI 程式碼記憶層 | [@byterover/cipher](https://github.com/campfirein/cipher) |
| zeabur | 雲端部署平台 | [zeabur-mcp](https://zeabur.com/docs/en-US/mcp) |
| google-docs | Google 文件整合 | [google-docs-mcp](https://github.com/a-bonus/google-docs-mcp) |
| googleDrive | Google 雲端硬碟整合 | [gdrive-mcp-server](https://github.com/felores/gdrive-mcp-server) |
| claude-mem | 跨對話記憶系統 | [claude-mem](https://github.com/thedotmack/claude-mem) |

## 清理外部殘留（手動）

安裝腳本只管理**本 repo 部署過**的項目；其他來源（第三方 skill 安裝器、舊版安裝包）寫進
`~/.claude/skills/` 的殘留需手動清理，型態與排查指令見
[CLAUDE.md「殘留清理（手動）」](CLAUDE.md#殘留清理手動)（單一維護來源，避免兩份文件各自過期）。

## 授權

MIT License

vendored 內容：`skills/writing-great-skills/`（來自 [mattpocock/skills](https://github.com/mattpocock/skills)，MIT）；
`agents/code-reviewer.md` 的 Fowler smell baseline 章節改編自同一來源。

## 貢獻

歡迎提交 Issue 和 Pull Request！
