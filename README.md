# DD Pipeline

> 基於多種 Driven Development 方法論的 Claude Code 自動化開發流程系統

DD Pipeline 是一套專為 Claude Code 設計的開發流程工具，整合了多種驅動開發方法論，提供結構化的 AI 輔助軟體開發體驗。

## 特色

- **多 Agent 協作** - 利用 Claude Code 的 Agent 系統進行專業分工
- **驅動開發整合** - 結合 RDD、SDD、DDD、ADD、EDD、DbC、CDD、TDD、PDD 等方法論
- **人工審核機制** - 在關鍵節點設置 Checkpoint，確保開發品質
- **自動化流程** - 批准後自動執行開發、測試、驗證流程

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

## 安裝

### 首次安裝

```bash
chmod +x install-dd-pipeline.sh
./install-dd-pipeline.sh
```

安裝程式會：
1. 檢查必要的 Agents 和 Skills
2. 安裝 DD Pipeline 指令到 `~/.claude/commands/`
3. 安裝文件模板到 `~/.claude/templates/dd/`

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

# 強制重新安裝（覆蓋所有檔案）
./install-dd-pipeline.sh --force

# 解除安裝
./install-dd-pipeline.sh --uninstall

# 更新 Agents/Skills 到最新版
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
| `/dd-dev` | 執行開發實作階段 (DbC + CDD + PDD) |
| `/dd-test` | 執行測試驗證階段 (TDD) |
| `/dd-status` | 查看專案開發狀態 |
| `/dd-stop` | 暫停開發流程 |
| `/dd-help` | 顯示幫助資訊 |

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
   /dd-dev ──────────► 開發實作 (並行前後端開發)
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

## 依賴需求

### 必要 Agents

來源：[claude-code-tresor](https://github.com/alirezarezvani/claude-code-tresor)

| Agent | 說明 |
|-------|------|
| systems-architect | 系統架構師 |
| test-engineer | 測試工程師 |
| security-auditor | 安全審計員 |
| docs-writer | 文件撰寫員 |
| refactor-expert | 重構專家 |
| performance-tuner | 效能調校專家 |
| root-cause-analyzer | 根因分析專家 |
| config-safety-reviewer | 配置安全審查員 |

### 必要 Skills

來源：[claude-skills](https://github.com/alirezarezvani/claude-skills)

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
