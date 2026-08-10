# DD Pipeline

> 可攜式 Claude Code 設定庫 — 以「6 步開發迴圈」為骨幹的輕量開發工作法

claude-dd 是跨機器可攜的 Claude Code profile（skills / agents / commands / 全域 CLAUDE.md），
由安裝腳本部署到 `~/.claude/`。此 repo 是 source of truth。

> **2026-07-23 大改版**：原多階段 DD Pipeline（dd-start → dd-arch → dd-approve → dd-dev → dd-test）
> 依實際使用率盤點後封存、2026-08-04 自 repo 刪除（見 git 歷史）；骨幹改為經實戰驗證的 6 步開發迴圈。
> 舊版說明見 git 歷史（tag 前版本的 README）。

## 特色

- **6 步開發迴圈** — 實作+測試 → commit → code-simplifier → code-review → 再測（curl/playwright 真實環境）→ commit
- **CLAUDE.md pre-commit gate** — 改碼目錄缺 CLAUDE.md 或未同批更新即擋 commit（block 版），錯誤訊息內建 AI 自主修復指令
- **使用率盤點制** — 只保留有實證使用紀錄的元件並全數預設部署，避免閒置 skill 吃 context；零使用的 misc / deprecated 桶已於 2026-08-04 刪除（git 歷史可回溯）
- **全域 CLAUDE.md 模板** — 零幻覺政策、最小修改、Skill 觸發規則等通用守則，互動式比對部署

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
6. 安裝文件模板到 `~/.claude/templates/dd/`
7. **互動式比對全域 CLAUDE.md**（`~/.claude/CLAUDE.md`）：若與 repo 模板不同，顯示 diff 並詢問是否覆蓋（預設保留本地）

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

安裝方式只有一種（含完整工作法：全域規則、6 步迴圈、pre-commit gate、模板與精選元件）：

```bash
git clone https://github.com/kopp0510/claude-dd && cd claude-dd && ./install-dd-pipeline.sh
```

全域 CLAUDE.md 走互動 diff，對方已有自己的全域規則時可先看差異再決定。

> 曾評估過 plugin marketplace 分發路線（2026-08-04 實測可行後移除）：plugin 機制
> 無法部署全域 CLAUDE.md 與 pre-commit gate，只能交付元件子集，與「完整工作法」
> 的定位不符，為維持單一路線而不採用。實作見 git 歷史。

## 升級指南

### 從舊版部署（全量 / 分桶時期）升級

舊版會把 53 個 skills / 21 個 agents / 7 個 dd 指令全部裝進 `~/.claude/`。
misc / deprecated 桶已於 2026-08-04 自 repo 刪除，現行腳本已無 `--prune`（單一部署
清單後無桶可清）— 從全量或分桶時期部署升級時，先暫時取回含完整名單與 `--prune` 的
舊版腳本做清理，再換回最新版：

```bash
git pull
git checkout 9a16629 -- install-dd-pipeline.sh   # 暫取含 deprecated 名單的腳本
./install-dd-pipeline.sh --force --prune          # 清掉不再部署的舊檔（逐項確認）
git checkout HEAD -- install-dd-pipeline.sh      # 還原最新版腳本（git status 應乾淨）
./install-dd-pipeline.sh --force
```

- 全域 CLAUDE.md 會出互動 diff，選「覆蓋」取得新版；有本地客製就選「看完整 diff」再決定
- 被清掉的內容需要時自 git 歷史取回（`git checkout 9a16629 -- skills/<名字>` 後加回部署陣列）
- `--uninstall` 同樣只認得現行部署清單 — 舊部署請先完成上述清理再解除安裝

### 既有專案升級到 6 步迴圈

已在跑舊版（或手寫 5 步版）開發流程的專案：

1. 到該專案跑一次 `/dd-init` — 會補上缺的部分（pre-commit gate、`.screenshots/`、plugin 檢查）
2. **注意**：專案 CLAUDE.md 若已有 `## 開發流程` 區塊，`/dd-init` 會跳過不覆蓋 —
   要升級成 6 步版（新增 code-review 步驟、顯性化首輪測試），請手動編輯該區塊，
   或刪掉舊區塊後重跑 `/dd-init` 重蓋
3. 舊 DD Pipeline 專案的 `claude_docs/`、`PROJECT_STATE.md` 不受影響，可保留或自行清理

### 日常更新

```bash
git pull && ./install-dd-pipeline.sh --force
```

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

### 必要

| MCP | 說明 | 來源 |
|-----|------|------|
| playwright | 瀏覽器自動化（迴圈步驟 5 前端驗證） | [playwright-mcp](https://github.com/microsoft/playwright-mcp) |

### 可選

| MCP | 說明 | 來源 |
|-----|------|------|
| sequential-thinking | 循序思考推理 | [@modelcontextprotocol/server-sequential-thinking](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking) |
| serena | 智能程式碼助手 | [serena](https://github.com/oraios/serena) |
| cipher | AI 程式碼記憶層 | [@byterover/cipher](https://github.com/campfirein/cipher) |
| zeabur | 雲端部署平台 | [zeabur-mcp](https://zeabur.com/docs/en-US/mcp) |
| google-docs | Google 文件整合 | [google-docs-mcp](https://github.com/a-bonus/google-docs-mcp) |
| googleDrive | Google 雲端硬碟整合 | [gdrive-mcp-server](https://github.com/felores/gdrive-mcp-server) |
| claude-mem | 跨對話記憶系統 | [claude-mem](https://github.com/thedotmack/claude-mem) |

## 清理外部殘留（手動）

安裝腳本只管理**本 repo 部署過**的項目；其他來源（如 tresor、舊版安裝包）寫進
`~/.claude/skills/` 的殘留需手動清理，型態與排查指令見
[CLAUDE.md「殘留清理（手動）」](CLAUDE.md#殘留清理手動)（單一維護來源，避免兩份文件各自過期）。

## 授權

MIT License

vendored 內容：`skills/writing-great-skills/`（來自 [mattpocock/skills](https://github.com/mattpocock/skills)，MIT）；
`agents/code-reviewer.md` 的 Fowler smell baseline 章節改編自同一來源。

## 貢獻

歡迎提交 Issue 和 Pull Request！
