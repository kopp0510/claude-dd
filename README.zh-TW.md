[English](README.md) | [繁體中文](README.zh-TW.md)

# DD Pipeline（claude-dd）

> 可攜式 Claude Code 設定庫 — 把「AI 有沒有照規矩做」變成看得見、擋得住的輸出

**是什麼**：跨機器可攜的 Claude Code profile（skills / agents / commands / scripts / output styles / 全域 CLAUDE.md）。
`git clone` 後跑一支 bash，整套工作習慣就裝進 `~/.claude/`；此 repo 是 source of truth。

**實際做了什麼**：三件事，強度誠實地不一樣。

1. **一個會擋 commit 的 pre-commit hook** — 改碼目錄沒有 `CLAUDE.md`、或有但沒跟這次 commit 一起 staged，就擋下。這條是真的強制：一支 shell 腳本 `exit 1`，跟 AI 怎麼想無關。
2. **一份全域 `CLAUDE.md`** — 要求涉及 API 簽名、版本號、專案事實時標註來源，並把「應該是」「大概」列為禁用詞。
3. **一個 8 步迴圈** — 由 `/dd-init` 蓋章進各專案的 `CLAUDE.md`，每個功能段落都要走簡化 → 審查 → 再驗證才進最終 commit。

**只有第 1 條是強制**：Claude Code 把 `CLAUDE.md` 當 context 載入、不是設定（[官方文件](https://code.claude.com/docs/en/memory)："Claude treats them as context, not enforced configuration"），所以第 2、3 條只能抬高下限、留下可稽核的紀錄。必須每次都發生的事得寫成 hook。

**適合誰**：每天用 Claude Code、一直在重打同樣的糾正、希望換台機器後這些還在，而且寧可被擋下 commit 也不要文件跟程式碼對不上的個人或小團隊。

**不適合誰**：想要輕量設定的人（gate 會擋你，有時得為一個小改動補寫 `CLAUDE.md`）、還沒有「文件過期是真問題」共識的團隊。另外規則本文、skill 定義與安裝腳本輸出都是繁體中文，要給英語系團隊用得先翻譯全域模板（機制本身與語言無關）。

## 特色

- **少停下來問** — 能復原的步驟直接做（含本機 commit、跑既有測試），只在破壞性操作、改變範圍、缺你才能給的資訊時才停；push 一律留給你
- **寫文件與註解的判準** — 全域 CLAUDE.md §3.10，沒跑迴圈的專案也適用：能列舉就不要寫數字、引用行號要把那一行印出來比對、修「同一件事講過 N 處」要拿判準去掃而不是拿第一處的句子
- **Skill 觸發顯性化** — 該觸發卻不觸發時要寫出一行具體理由，「跳過」變成可稽核的紀錄
- **使用率盤點制** — 只保留有實證使用紀錄的元件，全數預設部署
- **全域 CLAUDE.md 模板** — 上述守則的單一來源，互動比對後部署到 `~/.claude/CLAUDE.md`

## 安裝

### 前置需求

- [Claude Code CLI](https://claude.com/claude-code)、Node.js、Git、Bash — 四者皆為硬性需求，缺一安裝腳本會中止
- 必要 MCP：`playwright`（腳本只檢查不安裝，請先[安裝 playwright MCP](https://github.com/microsoft/playwright-mcp)）
- **`jq` 或 `python3`（擇一）** — 軟性依賴。兩者皆缺時 plugin 步驟整步跳過、MCP 檢查退化成字串比對，而安裝照樣成功
- 可選：`ffmpeg`（tech-diagram-gif 的 GIF 匯出用；缺少時該 skill 退化交付 SVG。macOS `brew install ffmpeg`）
- claude-md-management 與 skill-creator plugin 需已透過官方 marketplace 存在於本機。安裝腳本只登記「已在磁碟上找得到」的 plugin，不會下載。`skill-creator` 要先自己裝過一次：`claude plugin install skill-creator@claude-plugins-official`

### 首次安裝

```bash
git clone https://github.com/kopp0510/claude-dd.git
cd claude-dd
./install-dd-pipeline.sh
```

> 若 `install-dd-pipeline.sh` 沒有執行權限，先 `chmod +x install-dd-pipeline.sh`。

安裝腳本的進度顯示為 7 步（`1/7` … `7/7`）：

1. 檢查基礎環境（上述硬性需求，缺一即中止）
2. 安裝 12 個 promoted Skills 到 `~/.claude/skills/`
3. 安裝 4 個 promoted Agents 到 `~/.claude/agents/`（code-simplifier / code-reviewer 官方備份 + senior-devops / security-auditor）
4. 檢查 MCP（唯讀 — 只回報 scope，不安裝任何東西）
5. 登記官方 Plugin（claude-md-management — 巢狀 CLAUDE.md 維護依賴；skill-creator — skill 撰寫與 eval 測試）。plugin 不在磁碟上時印「Plugin 檔案不存在」後跳過；讀不到版本時跳過，並印出該跑的 `claude plugin install` 指令
6. 安裝 `/dd-init` + `workflow-review` 命名空間 Command 到 `~/.claude/commands/`
7. **比對全域 CLAUDE.md**（`~/.claude/CLAUDE.md`）：若與 repo 模板不同，顯示 diff 並詢問是否覆蓋（預設保留本地）。**全新機器上本機還沒有全域 CLAUDE.md 時，這步是詢問是否安裝且預設「否」**（非互動環境同樣採預設值）— 要拿到完整 profile 得答 `y` 或帶 `--force`。`--force` 同時會跳過 diff 詢問直接覆蓋，見[升級](#升級)

另有不編號的附加步驟：步驟 2 之前檢查每個 skill 的 `hooks.json` 指令路徑（有相對路徑就中止），步驟 6、7 之間部署 `check-claude-md.sh`（gate 本體）到 `~/.claude/scripts/`、`adhd.md`（ADHD 回覆風格）到 `~/.claude/output-styles/`。

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

## 升級

日常更新：

```bash
git pull && ./install-dd-pipeline.sh --force
```

> **`--force` 會直接覆蓋你的全域 `CLAUDE.md`，不會問。** 上面說的互動 diff 只在**沒有** `--force` 時才走。
> 舊版會備份到 `~/.claude/backups/pre-install-<時間戳>/`，路徑印在完成訊息裡，所以救得回來 —
> 但若你的全域規則有在地修改想保留，先不帶 `--force` 跑一次、選 `k`（保留本地）。

從舊版部署升級、既有專案升級到 8 步迴圈：見 [UPGRADING.md](UPGRADING.md)。
歷次結構性變更見 [CHANGELOG.md](CHANGELOG.md)。

## 核心工作法：8 步開發迴圈

每個**功能段落**必走（定義於全域 CLAUDE.md §3.9，專案具體版由 `/dd-init` 蓋章）：

```
1. 實作功能 + 首輪測試通過（不可帶紅燈進 commit）
2. commit（第一次 — 保留簡化前還原點）
3. code-simplifier（該段 diff）
4. code-review（該段 diff，全量跑，例外見下；修掉 Critical/Important 才續行）
5. 再測一次 — 重跑測試 + curl 打真實 API / playwright 真實瀏覽器操作（截圖存 .screenshots/）
6. commit（最終版本）
7. 沉澱本輪所學（有才做）— 踩雷、指令、慣例用 `/revise-claude-md` 寫進 `CLAUDE.md`
8. 評分 & 修正本輪動過的 `CLAUDE.md` — 先算範圍，再讓 `claude-md-improver` 只審那幾份
```

步驟 7 是「加」、步驟 8 是「整理」，順序不可反 —— 先跑 8 的話，7 會立刻把新東西塞進剛整理好的檔案。**步驟 7 跳過不代表步驟 8 跳過**：gate 逼著更新的 `CLAUDE.md` 一樣要審，gate 只確認「有寫」、不確認「寫得對」。步驟 3、4、8 都從段落起點算整段（步驟 1 之前用 `~/.claude/scripts/check-claude-md.sh --start-segment` 記下、`--segment-base` 取出；有 `task-planner` 進度表時以表上記的起點為準），只看最後一個 commit 會漏掉大半。

三個品質機制各管一軸：simplifier 管可讀性、code-review 管正確性/合規（另有 12 項 Fowler 壞味道基準，只在該次變更有新增或重構程式碼時掛）、真實環境驗證管行為。步驟 4 有一個例外：該段 diff 全是資料、設定、註解或文件，或改動已被專案的機械檢查完全覆蓋時，不派 agent，改成自己逐條核對、在回報附證據。要派時，主對話在同一則訊息裡**直接平行派最少 3 個審查者**（一發只挖到一部分，五發實驗見 [CHANGELOG.md](CHANGELOG.md)，搜「兩發聯集平均」），全部回來後逐條讀程式碼查證；中間不另派裁決者（比較見 `docs/measurements/2026-10-23-reviewer-real-sessions.md`）。派工要附什麼、報告怎麼落地，見 `templates/global/CLAUDE.md` §3.9 步驟 4。

**要跨好幾段的工作**先交給 `task-planner`：拆成依序執行的段落，段落裡再列小任務，進度表寫進 `docs/designs/` 的設計文件。小任務只走步驟 1、2，全部 commit 完整段才跑步驟 3–8；草稿先交 `plan-review` 審過才寫檔，換 session 或 `/compact` 之後照表接手。不用你開口：複雜工作動手前要先估段落數，兩段以上就自己叫 `task-planner`（規則見 `templates/global/CLAUDE.md` §4.1 與 `skills/task-planner/SKILL.md`）。

![claude-dd 大工作怎麼跑](diagrams/claude-dd-task-planner.zh-TW.gif)

![claude-dd 8 步開發迴圈](diagrams/claude-dd-dev-loop.zh-TW.gif)

步驟 1 的測試證明「做出來是對的」，步驟 5 證明「簡化與修 review 沒把對的改壞」—— 目的不同，缺一不可。

從零到日常的完整路徑（裝一次、每個專案蓋章一次、複雜工作的計畫先過 `plan-review`、每個功能段落走同一個迴圈）：

![claude-dd 使用流程](diagrams/claude-dd-usage-flow.zh-TW.gif)

### CLAUDE.md 維護規則（pre-commit gate 強制）

- 每個含程式碼的資料夾都要有 CLAUDE.md；改碼時同批更新。逐層堆疊更新上層是 §3.9 的規則，**gate 不檢查** —— 它只看改到程式碼的那一層，上層過期不會有任何訊號
- gate 本體是 `~/.claude/scripts/check-claude-md.sh`，由 `/dd-init` 掛到 `.git/hooks/pre-commit`；專案設了 `core.hooksPath` 時改掛到那個目錄（本 repo 就是）。
  用 pre-commit 套件或 lefthook 管 hook 的專案，`/dd-init` 不會自動把 gate 加進去，而是給你一段設定，要你自己加進 `.pre-commit-config.yaml`／`lefthook.yml`；husky v9 則由 `/dd-init` 直接寫進 `.husky/pre-commit`。
  gate 腳本不在時（協作者沒裝 claude-dd）只印警告、不擋 commit；擋下時的錯誤訊息會告訴 AI 怎麼補
- **記憶檔名可設**：預設 `CLAUDE.md`，`git config --local dd.docfile GEMINI.md` 讓 gate 改認那個檔名，給只准放特定檔名的 repo 用。
  只讀 `--local`（存在 `.git/config`、不進版控，每個 clone 要各自設）：設成 global、`-c dd.docfile=…`、`GIT_CONFIG_PARAMETERS` 都不生效。只接受單純檔名（不能帶路徑或空白、不以 `-` 開頭），否則每次 commit 都 `exit 1`
- 只對程式碼副檔名（`js|ts|py|go|rs|sh|…`）觸發，並排除 `node_modules`、`dist`、`.screenshots`、`migrations` 等目錄。只改 markdown 或設定檔**本身**不會觸發 —— 但見下一條：有 SKIP 欠帳時照樣擋
- 檢查點 commit（步驟 2）逃生口：`SKIP_DOC_CHECK=1 git commit`；最終 commit（步驟 6）必須全過。SKIP 不是豁免：gate 會追查段落起點以來跳過的目錄，之後第一個正常 commit（就算沒改程式碼）沒補上它們的 CLAUDE.md 一樣擋
- `git commit --no-verify`／`-n` 會讓 gate 整個不跑。Claude 這樣下指令時，`gate-guard` 會擋下並指向 `SKIP_DOC_CHECK=1`。它只擋 Claude，你自己在終端機打 `--no-verify` 擋不到；它是全域安裝，沒裝 gate 的專案也會擋

## 為什麼要巢狀 CLAUDE.md

gate 要求的是「每個含程式碼的目錄一份 `CLAUDE.md`」，而不是根目錄放一份大的。這是刻意的取捨，而且有代價。

**機制**（依[官方文件](https://code.claude.com/docs/en/memory)）：工作目錄**往上**的 `CLAUDE.md` 會在啟動時全部載入
（"loaded in full at launch"），**子目錄**的則是按需載入 —「當 Claude 讀取該目錄下的檔案時」才進 context。
所有找到的檔案是**串接**而非互相覆蓋，順序由檔案系統根目錄往下，所以離你工作位置最近的那份最後被讀。

**為什麼值得**

- **context 才是稀缺資源。** 官方建議單一 `CLAUDE.md` 控制在 200 行以內，因為「更長的檔案吃更多 context 且降低遵循度」。
  一個 monorepo 不可能用 200 行講完所有子系統。巢狀讓 `src/api/CLAUDE.md` 在 Claude 真的打開 `src/api/` 裡的東西之前，成本是零。
- **`@import` 解決不了這件事。** 這是最直覺的替代方案，但對 context 無效：被匯入的檔案「仍會在啟動時載入並進入 context window」。
  拆成 import 買到的是組織性，不是預算。真正的子目錄檔案才是唯一能延後載入的機制。
- **文件跟著改動走。** 講 API 層的規則就放在 API 層旁邊，那一層改動時比較可能被一起更新 — 這正是 gate 用「同批更新」強制的事。

**代價、已有的對策、以及剩下的風險**

- **文件形式主義。** gate 只驗檔案存在且有被 staged，**驗不到內容是否屬實**。
  *對策*：gate 擋下時印的訊息規定了修復格式（讀完該目錄再寫職責、關鍵檔案、慣例、與上層的關係），全域模板 §3.9 要求寫實際讀到的內容。
  *殘餘*：那是 context 規則不是強制，想敷衍還是過得了；gate 提高的是造假的成本。
- **小改動的摩擦。** 為了一個只想順手改一下的目錄補寫 `CLAUDE.md`，確實是額外成本。
  *對策*：只對程式碼副檔名觸發；檢查點 commit 有 `SKIP_DOC_CHECK=1`，但只是延後，之後的正常 commit 一樣要補。
  *殘餘*：新開一個放程式碼的目錄，第一次 commit 就得寫一份。
- **檔案越多，矛盾越多。** 官方原文：「兩條規則互相牴觸時，Claude 可能任選一條」。
  *對策*：迴圈步驟 8 用 `claude-md-improver` 稽核本輪動過的檔，§3.9 也要求逐層檢查上層。
  *殘餘*：沒有東西會**偵測**矛盾，定期檢視仍是人的責任。
- **巢狀檔撐不過 `/compact`。** 依官方文件，根目錄 `CLAUDE.md` 壓縮後會重新注入，巢狀檔則
  「不會自動重新注入；要等下次 Claude 讀到該子目錄的檔案時才重新載入」。
  *對策*：要改那個目錄的程式碼就得先讀檔，一讀就重新載入。
  *殘餘*：只剩 compact 後完全沒讀檔就憑記憶改碼這種情況。

如果這些取捨聽起來仍比你手上的問題更糟，那就用單一根目錄 `CLAUDE.md`、不要裝 gate。8 步迴圈沒有它一樣能跑。

## 指令一覽

| 指令 | 說明 |
|------|------|
| `/dd-init` | 初始化專案：蓋章 8 步迴圈到 CLAUDE.md、掛 pre-commit gate、建 `.screenshots/`（僅在專案有前端時；純後端/CLI 跳過）、檢查 plugin 依賴 |
| `/workflow-review:review` | 綜合程式碼審查（安全、效能、配置）。這是命名空間指令，冒號形式才是可呼叫的名稱 |
| `/output-style ADHD` | 開啟 ADHD 回覆風格（第一句是動作、步驟編號、每輪講進度、清單短、無開場收尾、繁中白話）；`/output-style default` 關閉。Claude Code 啟動時才讀風格檔，裝好要重開。只對目前專案生效（寫進 `.claude/settings.local.json`）；要全專案預設，在 `~/.claude/settings.json` 設 `"outputStyle": "ADHD"` —— 但專案層 `.claude/settings*.json` 的 `outputStyle` 會蓋過它 |

## Promoted Skills（預設部署，12 個）

> 「Promoted」指該元件有實證使用紀錄，因此預設部署。唯一的例外是 `gate-guard`：它是 gate 的防護，不是「用過才收」的 skill。

| Skill | 說明 |
|-------|------|
| code-simplifier | 程式碼簡化（迴圈步驟 3 的 wrapper） |
| design-brainstorm | 蘇格拉底式設計對話（事實自己查、決策才問人） |
| frontend-design | 前端視覺設計 |
| gate-guard | 只有 hook、沒有 skill 的 plugin：擋 Claude 用 `git commit --no-verify`／`-n`／`-c core.hooksPath=` 繞過 CLAUDE.md gate（先用 `git config core.hooksPath` 把 hook 關掉的擋不到） |
| plan-review | 計畫的對抗式審查：裁決者（Opus）派至少 3 個審查者（haiku）猛攻，只留查證屬實的批評 |
| review | 綜合審查 wrapper |
| self-improving-agent | 記憶審計與知識沉澱 |
| task-planner | 功能段落規劃，進度表寫進設計文件 |
| tech-diagram-gif | 技術圖表繪製與 GIF 匯出（風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)） |
| verification-gate | 完成前驗證閘門（宣稱完成須附新鮮證據） |
| worktree-manager | Git worktree 隔離 |
| writing-great-skills | skill 撰寫參考（vendored 自 [mattpocock/skills](https://github.com/mattpocock/skills)，user-invoked） |

## 官方 Plugins（安裝腳本管理）

| Plugin | 功能 |
|--------|------|
| claude-md-management | 巢狀 CLAUDE.md 稽核與更新（`claude-md-improver` skill + `/revise-claude-md`）— 8 步迴圈的文件維護依賴 |
| skill-creator | skill 撰寫與量測：訪談 → 草稿 → 同一批測試題跑「有 skill / 無 skill」兩組 → 評分 → 迭代。與 `writing-great-skills`（純寫作參考）互補。其 `scripts/quick_validate.py` 需要 PyYAML（`pip3 install pyyaml`），其餘功能不受影響 |

### 推薦第三方 Plugin（安裝腳本不管理）

| Plugin | 功能 | 安裝方式 |
|--------|------|----------|
| [claude-mem](https://github.com/thedotmack/claude-mem) | 跨對話記憶（以 lifecycle hooks 自動記錄 session，內附檢索工具） | `npx claude-mem install` |

> claude-mem 是 plugin、不是 MCP server，安裝腳本的 MCP 檢查不會看到它。

## MCP

安裝腳本只檢查不安裝，且會**區分設定範圍**：設在 `~/.claude.json` 根層 `mcpServers`
（官方 scope 名稱 `user`，所有專案可用）才顯示 ✅；只設在個別專案下（官方 `local`）
標示「僅 N 個專案設定」— 那在其他專案用不到，對「跨機器可攜的工作法」而言等同未安裝。

退化狀態分開回報，讓「無從判定」不會退化成有把握的斷言：

| 情況 | 回報為 |
|---|---|
| `~/.claude.json` 解析失敗（檔案損毀） | 無法判定 |
| 無 jq 也無 python3，字串比對命中 | 疑似已設定…範圍未知 |
| 無 jq 也無 python3，字串比對未命中 | 未安裝（必要 MCP 另印 ❌） |

最後一列是誠實的但書：字串比對沒命中就報未安裝，但它其實證明不了沒裝。

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
| zeabur | 雲端部署平台 | [zeabur-mcp](https://zeabur.com/docs/en-US/mcp) |
| google-docs | Google 文件整合 | [google-docs-mcp](https://github.com/a-bonus/google-docs-mcp) |
| googleDrive | Google 雲端硬碟整合 | [gdrive-mcp-server](https://github.com/felores/gdrive-mcp-server) |

## 清理外部殘留（手動）

安裝腳本只管理**本 repo 部署過**的項目；其他來源（第三方 skill 安裝器、舊版安裝包）寫進
`~/.claude/skills/` 的殘留需手動清理，型態與排查指令見
[CLAUDE.md「殘留清理（手動）」](CLAUDE.md#殘留清理手動)（單一維護來源，避免兩份文件各自過期）。

## 授權

MIT License

vendored 內容，各自附上游授權檔：

| 路徑 | 授權 | 上游 |
|------|------|------|
| `skills/writing-great-skills/LICENSE.txt` | MIT | [mattpocock/skills](https://github.com/mattpocock/skills) — `agents/code-reviewer.md` 的 Fowler smell baseline 章節改編自同一來源 |
| `skills/frontend-design/LICENSE.txt` | Apache-2.0 | 有歸屬／NOTICE 要求 |
| `skills/tech-diagram-gif/LICENSE.txt` | MIT | fireworks-tech-graph contributors（只借風格規範，借了哪幾條見該檔） |
| `skills/self-improving-agent/LICENSE` | MIT | Reza Rezvani |
| `output-styles/LICENSE.txt` | MIT | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd)（只借規則，逐節去向見該檔） |
| `commands/workflow-review/` | **未標示** | Alireza Rezvani —— 於 `7248a15` 收編。未隨附 LICENSE、上游 repo 從未記錄，因此不可假設其授權。歸屬記在 `review.md` 檔頭 |

收編規則見 [CLAUDE.md「第三方 Skill / Agent 收編檢查清單」](CLAUDE.md)。

## 貢獻

歡迎提交 Issue 和 Pull Request！
