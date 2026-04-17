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
1. 安裝 63 個內建 Skills 到 `~/.claude/skills/`（自動觸發專家知識）
2. 啟用官方 Plugins（claude-md-management）
3. 安裝 DD Pipeline 指令 + 命名空間 Commands 到 `~/.claude/commands/`
4. 安裝文件模板到 `~/.claude/templates/dd/`
5. **互動式比對全域 CLAUDE.md**（`~/.claude/CLAUDE.md`）：若與 repo 模板不同，顯示 diff 並詢問是否覆蓋（預設保留本地）

### 全域 CLAUDE.md（新增 2026-04）

`templates/global/CLAUDE.md` 是一份可攜的全域設定模板，包含零幻覺政策、Karpathy 四原則等通用開發守則。install 時會比對本機版本：

- **首次安裝**（本機無檔）：詢問是否套用
- **已存在且相同**：跳過
- **已存在但不同**：顯示 diff 摘要，提供 [覆蓋 / 保留 / 看完整 diff] 選單（預設保留）
- **`--force`**：靜默覆蓋，本地版本自動備份為 `~/.claude/CLAUDE.md.backup.YYYY-MM-DD-HHMMSS`
- **`--commands-only`**：跳過此步驟

**客製化個人偏好**：選擇「保留」即可，本地修改不會被自動推送。

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
| `/dd-start` | 啟動需求分析階段 (RDD) |
| `/dd-arch` | 執行架構設計階段 (SDD + DDD + ADD + EDD) |
| `/dd-approve` | 批准架構設計，進入開發階段 |
| `/dd-dev` | 執行開發實作階段 (SADD + DbC + CDD + PDD) |
| `/dd-test` | 執行測試驗證階段 (TDD) |

> **2026-04 精簡**：`/dd-revise`、`/dd-stop`、`/dd-status`、`/dd-help`、`/dd-docs` 已移除，改用原生能力替代。

### 已精簡命令遷移指引

| 舊命令 | 替代方案 |
|---|---|
| `/dd-revise` | 直接編輯 `claude_docs/*.md` 後重跑 `/dd-approve` |
| `/dd-stop` | `git add . && git commit -m "wip: <階段>"` 手動保存進度 |
| `/dd-status` | `cat claude_docs/PROJECT_STATE.md` + `git log` 檢視進度 |
| `/dd-help` | 閱讀 `README.md`（本檔） |
| `/dd-docs` | 改用 `/docs-gen` skill（自動產生）或 `/docs-writer` skill（手動撰寫） |

**為何精簡**：這 5 個命令功能已被 Claude Code 原生能力（Plan 模式、git、內建 skills）完全覆蓋，移除後降低維護負擔與使用者選擇困惑。舊安裝執行 `./install-dd-pipeline.sh --force` 會自動清理 `~/.claude/commands/` 中的殘留檔案。

## 命名空間 Commands

除了 DD Pipeline 指令外，還包含 19 個可直接呼叫的命名空間 Commands：

#### 安全類

| 指令 | 說明 |
|------|------|
| `/audit` | 全面安全審計 |
| `/vulnerability-scan` | 深度漏洞掃描與 CVE 分析 |
| `/compliance-check` | 法規合規驗證（GDPR、SOC2、HIPAA、PCI-DSS） |

#### 效能類

| 指令 | 說明 |
|------|------|
| `/profile` | 效能分析與瓶頸識別 |
| `/benchmark` | 負載測試與效能基準 |

#### 品質類

| 指令 | 說明 |
|------|------|
| `/code-health` | 程式碼健康度評估 |
| `/debt-analysis` | 技術債識別與重構路線圖 |
| `/review` | 綜合程式碼審查（安全、效能、配置） |

#### 維運類

| 指令 | 說明 |
|------|------|
| `/incident-response` | 生產事件協調與 RCA |
| `/deploy-validate` | 部署前驗證 |
| `/health-check` | 系統健康檢查 |

#### 開發與測試類

| 指令 | 說明 |
|------|------|
| `/test-gen` | 自動產生測試案例 |
| `/docs-gen` | 自動產生文件 |

#### 工作流程類

| 指令 | 說明 |
|------|------|
| `/handoff-create` | 建立交接文件 |
| `/prompt-create` | 建立最佳化提示 |
| `/prompt-run` | 委派提示到子任務執行 |
| `/todo-add` | 新增待辦事項 |
| `/todo-check` | 檢視待辦事項 |

## 開發模式

| 模式 | 觸發方式 | 說明 |
|------|----------|------|
| **預設 (SADD)** | `/dd-dev` | 微任務拆解 → Subagent 逐任務執行 → 兩階段審查 |
| **Worktree** | `/dd-dev --worktree` | 在 Git Worktree 隔離環境中執行預設模式 |
| **批次** | `/dd-dev --batch` | 每 3 個任務暫停等待人工回饋 |
| **經典** | `/dd-dev --classic` | 舊版一次性實作模式（PDD + 整體實作） |

## 模型策略

DD Pipeline 主 session 使用使用者當下設定的模型（預設 Sonnet），但在**委派 subagent / Agent 時**建議依任務性質切換以優化成本/品質：

| 階段 / Agent | 建議 model | 理由 |
|---|---|---|
| `/dd-init` Explore subagent | **haiku** | 檔案搜尋、技術棧偵測，低推理 |
| `/dd-arch` systems-architect | **opus** | 系統架構決策，錯誤會讓後續全歪 |
| `/dd-arch` senior-architect（ADR/DDD） | **opus** | 技術選型權衡與領域建模需深度推理 |
| `/dd-dev` 失敗修復 root-cause-analyzer | **opus** | 根因分析需深度推理，避免 workaround 掩蓋真因 |
| `/dd-dev` subagent-orchestrator worker | **sonnet** | 實作任務量大，批量用 Opus 成本高 |
| 其他 Agent/Skill（test/QA/審查/文件） | **sonnet**（預設） | 中等推理，品質與成本平衡 |

**為何不寫在 command frontmatter？** 避免覆蓋使用者手動 `/model` 設定。模型建議內嵌在 command 的 Agent 調用段落（如「建議 `model: "opus"`」），由 Claude 在委派時決定是否傳入，使用者可隨時覆蓋。

**為何只用泛稱而不寫版本？** 用 `opus` / `sonnet` / `haiku` 泛稱，會自動跟著 Claude Code 升級到當前最新版本（如 Opus 4.7 / Sonnet 4.6 / Haiku 4.5），不需逐版維護。

**長 context 變體**：Opus 4.7 提供 1M context 變體（`claude-opus-4-7[1m]`），適合 `/dd-arch` 大型專案的架構決策（一次容納整個 codebase）。可在當下 session 透過 `/model` 切換。

**成本參考**：定價會隨模型版本與 context 規模調整，請以 [Anthropic 官方定價頁](https://www.anthropic.com/pricing) 為準。粗略原則：Opus 約為 Sonnet 的 5 倍、Sonnet 約為 Haiku 的 4 倍 — 因此 `/dd-dev` 批量 subagent 用 Sonnet 比 Opus 顯著省成本。

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
┌─────────────────────────────────────┐
│  🔒 人工審核 Checkpoint              │
│  /dd-approve 批准                   │
│  （需修改時：直接編輯 claude_docs/   │
│   *.md，再重跑 /dd-approve）         │
└──────────┬──────────────────────────┘
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
   /docs-gen ────────► 分析程式碼，產生 DD 文檔
      │                 （改用內建 skill 取代 /dd-docs）
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

### 核心 Skills（DD Pipeline 安裝，19 個）

安裝腳本會自動安裝以下 Skills 到 `~/.claude/skills/`，這些 Skills 會在對話中自動觸發：

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| systems-architect | 系統架構師 | 討論系統設計、架構決策時 |
| test-engineer | 測試工程師 | 測試架構、框架選型（非 QA 策略用 senior-qa；非自動產生用 test-gen） |
| security-auditor | 安全審計員 | 安全審查、漏洞分析時 |
| docs-writer ⭐ | 文件撰寫專家 | 手動撰寫技術文件（非批量產生用 docs-gen；4 階段工作流程） |
| refactor-expert | 重構專家 | 程式碼重構、技術債處理時 |
| performance-tuner | 效能調校專家 | 效能優化、瓶頸分析時 |
| root-cause-analyzer | 根因分析專家 | 除錯、複雜 bug 調查（非生產事件用 incident-response） |
| config-safety-reviewer | 配置安全審查員 | 審查設定檔、生產環境配置時 |
| senior-database ⭐ | 資料庫專家 | Schema 設計、查詢優化、索引（非資料管線用 senior-data-engineer；4 情境工作流程） |
| api-designer ⭐ | API 設計專家 | REST/GraphQL 設計、OpenAPI 規格（7 階段工作流程） |
| i18n-expert ⭐ | 國際化專家 | 多語言架構、RTL 支援、翻譯管理（5 情境工作流程） |
| task-planner ⭐ | 微任務規劃專家 | dd-dev 自動調用，架構 → 微任務清單（4 階段工作流程） |
| worktree-manager ⭐ | Git Worktree 管理 | dd-dev --worktree 時，隔離環境建立（3 階段工作流程） |
| subagent-orchestrator ⭐ | Subagent 調度專家 | dd-dev 自動調用，逐任務 subagent 執行+審查（3 階段工作流程） |
| code-simplifier ⭐ | 程式碼簡化專家 | 簡化程式碼、降低複雜度時（3 階段包裝器工作流程） |
| frontend-design | 前端視覺設計專家 | 視覺風格、頁面視覺設計（非 React 實作用 senior-frontend；非 Design Token 用 ui-design-system） |

### 整合包裝器 Skills（DD Pipeline 安裝，23 個）

透過包裝外部 Agent 或 Skill 命令，提供關鍵詞自動觸發能力：

#### 開發類

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| senior-backend | 資深後端工程師 | Express、Fastify、Node.js API、後端、認證 |
| senior-frontend | 資深前端工程師 | React 元件實作、Next.js、Tailwind（非視覺設計用 frontend-design） |
| senior-devops | 資深 DevOps 工程師 | CI/CD、Docker、Kubernetes、部署 |
| senior-fullstack | 資深全端工程師 | 全端、scaffold 專案、tech stack |
| tdd-guide | TDD 引導專家 | TDD、測試驅動、紅綠重構 |
| claude-api | Claude API 專家 | anthropic SDK、Claude API、Agent SDK |

#### 品質與審查類

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| code-reviewer | 程式碼審查員 | review PR、程式碼品質、SOLID 違規、code smell |
| review | 綜合程式碼審查 | 審查程式碼、comprehensive review、code review |
| code-health | 程式碼健康度 | 程式碼健康、可維護性、品質指標 |
| debt-analysis | 技術債分析 | 技術債、債務分析、重構路線圖 |
| test-gen | 測試產生器 | 自動產生測試案例（非測試架構用 test-engineer） |

#### 安全類

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| vulnerability-scan | 漏洞掃描 | 漏洞掃描、CVE、依賴安全 |
| security-audit | 全面安全審計 | 全面安全審計、security audit |
| compliance-check | 合規檢查 | GDPR、SOC2、HIPAA、PCI-DSS、合規 |
| senior-secops | 資深安全運維 | SecOps、安全自動化、合規掃描 |

#### 效能類

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| performance-profile | 效能分析 | 效能分析、profiling、瓶頸定位 |
| benchmark | 負載測試 | 負載測試、benchmark、壓力測試 |

#### 維運類

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| deploy-validate | 部署驗證 | 部署驗證、上線前檢查、pre-deploy |
| health-check | 系統健康檢查 | 系統健康、監控、health check |
| incident-response | 生產事件回應 | 生產事件、緊急 triage（非事後檢討用 incident-commander；非一般 bug 用 root-cause-analyzer） |

#### 測試類

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| senior-qa | 資深 QA 工程師 | QA 策略、測試計畫、覆蓋率（非架構設計用 test-engineer） |
| playwright-pro | Playwright 測試專家 | Playwright、瀏覽器測試、E2E 自動化 |

#### 文件類

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| docs-gen | 自動文件產生 | 自動產生文件、JSDoc（非手動撰寫用 docs-writer） |

### 官方 Plugins（DD Pipeline 安裝）

安裝腳本會自動啟用以下 Anthropic 官方 Plugins：

| Plugin | 說明 | 功能 |
|--------|------|------|
| claude-md-management | CLAUDE.md 管理工具 | 審計 CLAUDE.md 品質、捕捉工作階段學習內容 |

提供的工具：
- **claude-md-improver** (Skill) — 審計 CLAUDE.md 是否與程式碼庫同步
- **/revise-claude-md** (Command) — 在工作階段結束時捕捉學習內容並更新 CLAUDE.md

### 工程團隊 Skills（DD Pipeline 安裝）

進階工程專家角色，涵蓋架構、安全、AI/ML、設計等領域：

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| senior-architect | 系統架構設計 | 設計架構、評估微服務、架構圖表 |
| senior-security | 安全工程 | 威脅建模、STRIDE 分析、安全架構 |
| senior-prompt-engineer | 提示工程 | Prompt 優化、LLM 評估、RAG prompt（非 RAG 基礎設施用 senior-ml-engineer） |
| senior-data-engineer | 資料工程 | 資料管線、ETL/ELT、Spark、Airflow（非 SQL 優化用 senior-database；非 MLOps 用 senior-ml-engineer） |
| senior-data-scientist | 資料科學 | 統計建模、A/B 測試、因果推論（非 MLOps 用 senior-ml-engineer） |
| senior-ml-engineer | 機器學習工程 | MLOps、RAG 基礎設施、模型部署（非 prompt 設計用 senior-prompt-engineer） |
| senior-computer-vision | 電腦視覺 | 物件偵測、影像分割、YOLO、SAM |
| ui-design-system | UI 設計系統 | Design Token、元件文件、響應式設計(非視覺設計用 frontend-design) |
| ux-researcher-designer | UX 研究設計 | 使用者研究、Persona、旅程地圖 |

### 產品與商業 Skills（DD Pipeline 安裝）

產品管理、商業策略與專業整合工具：

| Skill | 說明 | 自動觸發時機 |
|-------|------|-------------|
| agile-product-owner | Agile 產品負責人 | user story、Sprint、Backlog（非 PRD/RICE 用 product-manager-toolkit；非 OKR 用 product-strategist） |
| aws-solution-architect | AWS 架構師 | 無伺服器架構、CloudFormation、成本優化 |
| competitive-teardown | 競品分析 | 競品拆解、市場定位分析 |
| email-template-builder | Email 範本建置 | Email 設計、範本產生 |
| incident-commander | 事件指揮官 | SRE 事件管理、PIR、Runbook（非即時回應用 incident-response） |
| landing-page-generator | Landing Page 產生 | 著陸頁設計與產生 |
| product-manager-toolkit | 產品經理工具箱 | RICE、PRD、客戶訪談（非 Sprint/story 用 agile-product-owner；非 OKR 用 product-strategist） |
| product-strategist | 產品策略 | OKR、市場分析、產品願景（非 PRD 用 product-manager-toolkit；非競品拆解用 competitive-teardown） |
| saas-scaffolder | SaaS 腳手架 | SaaS 專案快速建置 |
| self-improving-agent | 自動記憶管理 | 記憶審計、知識提升、規則畢業 |
| stripe-integration-expert | Stripe 整合 | 支付整合、訂閱管理 |
| tech-stack-evaluator | 技術棧評估 | TCO 分析、框架比較、生態評分 |

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
