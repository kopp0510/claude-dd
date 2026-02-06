# DD Pipeline

> 基於多種 Driven Development 方法論的 Claude Code 自動化開發流程系統

DD Pipeline 是一套專為 Claude Code 設計的開發流程工具，整合了多種驅動開發方法論，提供結構化的 AI 輔助軟體開發體驗。

## 特色

- **Skills 自動觸發** - 專家知識在對話中自動載入，無需手動呼叫
- **Commands 手動控制** - 開發流程由使用者明確控制
- **驅動開發整合** - 結合 RDD、SDD、DDD、ADD、EDD、DbC、CDD、TDD、PDD、SADD 等方法論
- **人工審核機制** - 在關鍵節點設置 Checkpoint，確保開發品質
- **自動化流程** - 批准後自動執行開發、測試、驗證流程
- **微任務拆解** - 自動將架構拆分為最小可執行任務
- **Subagent 驅動** - 逐任務分派 subagent 執行，兩階段審查確保品質

## 支援的開發方法論

| 縮寫 | 全名 | 說明 |
|------|------|------|
| RDD | Requirements-Driven Development | 需求驅動開發 |
| SDD | Structure-Driven Development | 系統結構設計 |
| DDD | Domain-Driven Design | 領域模型設計 |
| ADD | Architecture Decision Records | 架構決策記錄 |
| EDD | Example-Driven Development | 範例驅動設計 |
| DbC | Design by Contract | 契約驅動開發 |
| CDD | Component-Driven Development | 元件驅動開發 |
| TDD | Test-Driven Development | 測試驅動開發 |
| PDD | Prompt-Driven Development | 提示驅動開發 |
| SADD | Subagent-Driven Development | 子代理驅動開發 |

## 安裝

### 首次安裝

```bash
chmod +x install-dd-pipeline.sh
./install-dd-pipeline.sh
```

安裝程式會：
1. 安裝內建 Skills 到 `~/.claude/skills/`（自動觸發專家知識）
2. 安裝 DD Pipeline 指令到 `~/.claude/commands/`
3. 安裝文件模板到 `~/.claude/templates/dd/`
4. 檢查可選的外部 Skills（提示安裝方式）

### 更新安裝

安裝腳本支援**自動偵測變更**，重複執行時會自動更新有變更的檔案：

```bash
# 自動偵測並更新有變更的檔案
./install-dd-pipeline.sh
```

執行後會顯示每個檔案的狀態：
- `已安裝（新）` - 新安裝的檔案
- `已更新` - 偵測到變更，已自動更新
- `已是最新` - 內容相同，無需更新

### 安裝選項

```bash
# 顯示幫助
./install-dd-pipeline.sh --help

# 只檢查環境（不安裝）
./install-dd-pipeline.sh --check

# 強制重新安裝（覆蓋所有檔案）
./install-dd-pipeline.sh --force

# 只安裝 DD Commands（跳過 Skills 安裝）
./install-dd-pipeline.sh --commands-only

# 解除安裝
./install-dd-pipeline.sh --uninstall

# 更新內建 Skills 到最新版
./install-dd-pipeline.sh --update
```

## 指令一覽

| 指令 | 說明 |
|------|------|
| `/dd-init` | 初始化專案，建立 `claude_docs/` 目錄與專案設定（支援自動偵測現有專案） |
| `/dd-docs` | 為現有程式碼分析並產生 DD 文檔 |
| `/dd-start` | 啟動需求分析階段 (RDD) |
| `/dd-arch` | 執行架構設計階段 (SDD + DDD + ADD + EDD) |
| `/dd-approve` | 批准架構設計，進入開發階段 |
| `/dd-revise` | 修改架構設計 |
| `/dd-dev` | 執行開發實作階段 (SADD + DbC + CDD + PDD) |
| `/dd-test` | 執行測試驗證階段 (TDD) |
| `/dd-status` | 查看專案開發狀態 |
| `/dd-stop` | 暫停開發流程 |
| `/dd-help` | 顯示幫助資訊 |

## 開發模式

| 模式 | 觸發方式 | 說明 |
|------|----------|------|
| **預設 (SADD)** | `/dd-dev` | 微任務拆解 → Subagent 逐任務執行 → 兩階段審查 |
| **Worktree** | `/dd-dev --worktree` | 在 Git Worktree 隔離環境中執行預設模式 |
| **批次** | `/dd-dev --batch` | 每 3 個任務暫停等待人工回饋 |
| **經典** | `/dd-dev --classic` | 舊版一次性實作模式（PDD + 整體實作） |

## 開發流程

### 新專案流程

```
用戶輸入需求
      │
      ▼
   /dd-init ─────────► 初始化專案結構
      │
      ▼
   /dd-start ────────► 需求分析 (REQUIREMENTS.md)
      │
      ▼
   /dd-arch ─────────► 架構設計 (ARCHITECTURE.md, ADR-XXX.md, EXAMPLES.md)
      │
      ▼
┌─────────────────────────┐
│  🔒 人工審核 Checkpoint  │
│  /dd-approve 批准       │
│  /dd-revise 修改        │
└──────────┬──────────────┘
           │
           ▼
   /dd-dev ──────────► 微任務拆解 → Subagent 逐任務執行
      │                 ├── task-planner: 架構 → 微任務清單
      │                 ├── subagent-orchestrator:
      │                 │   ├── 實作者 subagent (TDD)
      │                 │   ├── 規格審查 subagent
      │                 │   └── 品質審查 subagent
      │                 └── 效能/安全/重構/文檔 檢查
      │
      ▼
   /dd-test ─────────► 測試驗證
      │
      ▼
     完成
```

### 現有專案流程

```
現有專案（已有程式碼）
      │
      ▼
   /dd-init ─────────► 自動偵測技術棧，補充 DD 設定
      │
      ▼
   /dd-docs ─────────► 分析程式碼，產生 DD 文檔
      │                 ├── REQUIREMENTS.md
      │                 ├── ARCHITECTURE.md
      │                 ├── API_CONTRACT.md
      │                 ├── ADR-XXX.md
      │                 └── EXAMPLES.md
      ▼
   /dd-start ────────► 定義新功能需求
      │
      ▼
   (後續流程相同)
```

## 產出文件

DD Pipeline 會在專案中建立 `claude_docs/` 目錄，包含：

- `CLAUDE.md` - 專案設定與規範
- `PROJECT_STATE.md` - 專案狀態追蹤
- `REQUIREMENTS.md` - 需求規格文件
- `ARCHITECTURE.md` - 系統架構文件
- `ADR-XXX.md` - 架構決策記錄
- `EXAMPLES.md` - 使用範例文件
- `API_CONTRACT.md` - API 契約文件
- `plans/<feature>.md` - 微任務計畫（SADD 模式）

## 依賴需求

### 內建 Skills（DD Pipeline 安裝）

安裝腳本會自動安裝以下 Skills 到 `~/.claude/skills/`，這些 Skills 會在對話中自動觸發：

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| systems-architect | 系統架構師 | 討論系統設計、架構決策時 |
| test-engineer | 測試工程師 | 需要撰寫測試、測試策略時 |
| security-auditor | 安全審計員 | 安全審查、漏洞分析時 |
| docs-writer ⭐ | 文件撰寫專家 | 撰寫技術文件時（4 階段結構化工作流程） |
| refactor-expert | 重構專家 | 程式碼重構、技術債處理時 |
| performance-tuner | 效能調校專家 | 效能優化、瓶頸分析時 |
| root-cause-analyzer | 根因分析專家 | 除錯、問題調查時 |
| config-safety-reviewer | 配置安全審查員 | 審查設定檔、生產環境配置時 |
| senior-database ⭐ | 資料庫專家 | Schema 設計、查詢優化、索引策略（4 情境工作流程） |
| api-designer ⭐ | API 設計專家 | REST/GraphQL 設計、OpenAPI 規格（7 階段工作流程） |
| i18n-expert ⭐ | 國際化專家 | 多語言架構、RTL 支援、翻譯管理（5 情境工作流程） |
| task-planner ⭐ | 微任務規劃專家 | dd-dev 自動調用，架構 → 微任務清單（4 階段工作流程） |
| worktree-manager ⭐ | Git Worktree 管理 | dd-dev --worktree 時，隔離環境建立（3 階段工作流程） |
| subagent-orchestrator ⭐ | Subagent 調度專家 | dd-dev 自動調用，逐任務 subagent 執行+審查（3 階段工作流程） |
| code-simplifier ⭐ | 程式碼簡化專家 | 簡化程式碼、降低複雜度時（3 階段包裝器工作流程） |

### 可選 Skills（外部安裝）

來源：[claude-skills](https://github.com/alirezarezvani/claude-skills)

這些 Skills 為可選，可依需求自行安裝：

| Skill | 說明 |
|-------|------|
| senior-architect | 資深架構師 |
| senior-backend | 資深後端工程師 |
| senior-frontend | 資深前端工程師 |
| senior-fullstack | 資深全端工程師 |
| senior-qa | 資深品質保證工程師 |
| senior-devops | 資深 DevOps 工程師 |
| senior-secops | 資深安全運維工程師 |
| senior-security | 資深安全工程師 |
| senior-prompt-engineer | 資深提示工程師 |
| senior-data-engineer | 資深資料工程師 |
| senior-data-scientist | 資深資料科學家 |
| senior-ml-engineer | 資深機器學習工程師 |
| senior-computer-vision | 資深電腦視覺工程師 |
| code-reviewer | 程式碼審查員 |
| ui-design-system | UI 設計系統專家 |
| ux-researcher-designer | UX 研究設計師 |

### 必要 MCP

| MCP | 說明 | 來源 |
|-----|------|------|
| playwright | 瀏覽器自動化測試 | [playwright-mcp](https://github.com/anthropics/anthropic-quickstarts/tree/main/mcp-servers/playwright) |

### 可選 MCP

| MCP | 說明 | 來源 |
|-----|------|------|
| sequential-thinking | 循序思考推理 | [@modelcontextprotocol/server-sequential-thinking](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking) |
| serena | 智能程式碼助手 | [serena](https://github.com/oraios/serena) |
| cipher | AI 程式碼記憶層 | [@byterover/cipher](https://github.com/campfirein/cipher) |
| zeabur | 雲端部署平台 | [zeabur-mcp](https://zeabur.com/docs/en-US/mcp) |
| google-docs | Google 文件整合 | [google-docs-mcp](https://github.com/a-bonus/google-docs-mcp) |
| googleDrive | Google 雲端硬碟整合 | [gdrive-mcp-server](https://github.com/felores/gdrive-mcp-server) |
| claude-mem | 跨對話記憶系統 | [claude-mem](https://github.com/thedotmack/claude-mem) |

## 授權

MIT License

## 貢獻

歡迎提交 Issue 和 Pull Request！
