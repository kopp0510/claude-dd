# DD Pipeline — Claude Code 自動化開發流程

可攜式 Claude Code 設定庫，透過 `install-dd-pipeline.sh` 安裝到 `~/.claude/` 全域。

## 安裝 / 更新

```bash
./install-dd-pipeline.sh                    # 首次安裝
./install-dd-pipeline.sh --force            # 更新：差異檔覆蓋（內容相同不重寫）；全域 CLAUDE.md 跳過詢問直接覆蓋（先備份）
./install-dd-pipeline.sh --check            # 只檢查環境
./install-dd-pipeline.sh --uninstall --yes  # 免確認解除安裝（自動化；非互動環境的詢問一律採預設值）
```

> 從舊版（全量部署 / 分桶時期）升級、既有專案升級到 8 步迴圈：見 [UPGRADING.md](UPGRADING.md)。

環境檢查（步驟 1 / `--check`）除必要工具外含**可選項 ffmpeg**：tech-diagram-gif 的
GIF 匯出用，缺少時警示並附安裝指令（brew / apt），該 skill 退化交付 SVG。
只偵測提示、不代裝系統套件。

## 部署清單（使用率盤點制）

repo 只保留**有實證使用紀錄**的元件（2026-08-04 盤點留存 9 skills、4 agents、
dd-init、workflow-review；2026-08-10 新增自製 tech-diagram-gif，實證來源為當次
對話的完整管線驗證），全部預設部署；清單定義在 `install-dd-pipeline.sh` 頂部的
`PROMOTED_*` 陣列。

- 歷次盤點刪除（git 歷史可回溯）：deprecated 桶（全歷史 0 次使用的 34 skills /
  17 agents / 6 dd 指令 / 13 NS commands）與 misc 桶（SRE 備援性質但零實際調用的
  11 skills / 5 NS commands）均於 2026-08-04 刪除；取回方式
  `git checkout pre-prune-2026-08-04 -- skills/<名字>` 後加回陣列

## 目錄結構

- `skills/` — 10 個 Skills（每個子目錄含 SKILL.md 定義檔，全數部署；writing-great-skills 為 vendored 自 mattpocock/skills 的 skill 撰寫參考、tech-diagram-gif 的風格規範 vendored 自 fireworks-tech-graph）
- `agents/` — 4 個 Agents（code-simplifier、code-reviewer 官方備份 + senior-devops、security-auditor）
- `commands/` — 1 個 dd-* 指令（dd-init，.md 平面檔） + 1 個命名空間 command 目錄（workflow-review）
- `templates/global/` — 全域 CLAUDE.md 模板（經互動比對部署到 `~/.claude/CLAUDE.md`）
- `scripts/` — 輔助腳本（部署到 `~/.claude/scripts/`；含 check-claude-md.sh pre-commit gate 與本 repo 自用的 `githooks/`，後者不部署）
- `diagrams/` — 兩份 README 嵌的 6 張 GIF（三層架構、使用流程、8 步迴圈 × 中英）；
  來源腳本在 `diagrams/src/`（改圖改腳本再重出，勿手改 GIF）
- `install-dd-pipeline.sh` — 安裝腳本（部署到 ~/.claude/；唯一安裝路線，分享亦同）

## 新增 Skill 步驟

1. 在 `skills/<skill-name>/` 建立 `SKILL.md`
2. 在 `install-dd-pipeline.sh` 的 `PROMOTED_SKILLS` 陣列加入名稱
3. 執行 `./install-dd-pipeline.sh --force` 部署

### Skill hook 路徑規範（強制）

skill 若含 `hooks/hooks.json`，其中 `command` **必須**用可在任意 cwd 解析的路徑：

- ✅ `$HOME/.claude/skills/<skill-name>/hooks/xxx.sh`
- ❌ `./hooks/xxx.sh`（hook 以「當前工作目錄」為基準執行，換到別的專案就找不到腳本）

安裝腳本的 `validate_skill_hooks()` 會在部署前掃描所有 `hooks.json`，發現相對路徑即**中止部署**。
引入第三方 skill（vendor）時尤其注意：上游常用相對路徑，併入前先改寫（完整收編流程見下方「第三方 Skill / Agent 收編檢查清單」）。

## 新增 Agent 步驟

1. 在 `agents/` 建立 `<agent-name>.md`（frontmatter 含 `name`、`description`、`model` —
   自製 agent 用 `inherit`；官方備份（code-reviewer / code-simplifier）維持上游的 `opus`，不要改齊）
2. 在 `install-dd-pipeline.sh` 的 `PROMOTED_AGENTS` 陣列加入名稱
3. 執行 `./install-dd-pipeline.sh --force` 部署
4. 若 agent 被某個 wrapper skill 調用，確認該 skill 的 Task `subagent_type` 先試 `<name>:<name>`（plugin 命名空間）再 fallback `<name>`（本地）

## 新增 Command 步驟

- 平面指令：在 `commands/` 建立 `<name>.md`，並更新 `install-dd-pipeline.sh` 頂層的 `DD_COMMANDS` 陣列
- 命名空間指令：在 `commands/<namespace>/` 建立 `.md` 檔案，並更新 `install-dd-pipeline.sh` 頂層的 `NS_COMMANDS` 陣列

## 核心工作法：8 步開發迴圈

骨幹是經實際專案實戰驗證的功能段落迴圈
（定義於 `templates/global/CLAUDE.md` §3.9，專案具體版由 `/dd-init` 蓋章）：

```
實作+測試 → commit → code-simplifier → code-review → 再測(curl/playwright) → commit
  → 沉澱本輪所學 → 評分&修正
```

第 7、8 步的細則（範圍怎麼算、發現怎麼分類、何時可跳過）見全域模板 §3.9。
本 repo 是這兩步的 dogfood 來源：2026-08-31 先在這裡實跑 4 次，抓到 2 個真錯誤
（`diagrams/src/CLAUDE.md` 漏寫 `gen_usage.py` 不產 html、第 8 步條文自己用了
在該時機為空的 `git diff --cached`），驗證可行後才推進全域模板與 `/dd-init`。

搭配巢狀 CLAUDE.md 堆疊維護（依賴 `claude-md-management` plugin，安裝腳本管理），
並由 **pre-commit gate 強制**（block 版）：`scripts/check-claude-md.sh` 部署到
`~/.claude/scripts/`，`/dd-init` 掛進專案 `.git/hooks/pre-commit`（專案設有
`core.hooksPath` 時改掛該目錄，見下方「開發本 repo」）— 改碼目錄缺
CLAUDE.md 或未同批更新即擋 commit；檢查點 commit 逃生口 `SKIP_DOC_CHECK=1`。

> **舊 DD Pipeline（已刪除）**：`/dd-start → /dd-arch → /dd-approve → /dd-dev → /dd-test`
> 多階段流程於 2026-07-23 依使用率盤點（全歷史 0 次使用）封存、2026-08-04 刪除，
> 檔案與舊版 dd-init 見 git 歷史（如 `git show pre-prune-2026-08-04:commands/dd-dev.md`）。

## 開發本 repo

- clone 後啟用 CLAUDE.md gate（dogfood，本 repo 吃自己的 pre-commit）：
  ```bash
  git config core.hooksPath scripts/githooks
  ```
  （`core.hooksPath` 設定後 `.git/hooks/` 會被 git 忽略；`/dd-init` Phase 3
  會偵測此設定並改掛到 hooksPath 目錄，兩者不衝突）
- gate 規則與逃生口（`SKIP_DOC_CHECK=1`）同各專案：改 `.sh` 等程式碼檔時，
  該目錄的 CLAUDE.md 必須同批更新
- 架構總覽（分層、部署清單、安裝行為保證、CI 防線）見 `DD_PIPELINE_ARCHITECTURE.md`

## 注意事項

- 所有回應和註解使用繁體中文
- Commit message 使用繁體中文
- 此專案是 source of truth，全域 ~/.claude/ 的內容由安裝腳本從此專案部署
- 修改 skills/agents/commands 後務必同步更新 install-dd-pipeline.sh 的部署陣列（CI 會擋不一致）
- README 有英文（`README.md`，GitHub 預設顯示）與繁中（`README.zh-TW.md`）兩份，**內容須同批更新**。
  CI 對兩份都驗數字宣稱與 Promoted Skills 表格，正規式為語言無關（`.github/workflows/ci.yml`）。
  CHANGELOG.md 與 UPGRADING.md 維持純繁中，英文 README 連向它們時須標註 *(Traditional Chinese)*。
  README 變英文不改變本專案的註解語言 — 專案 CLAUDE.md（衝突順序第 3 位）優先於
  全域模板 §1.1 程式碼註解列的「跟隨 README 語言」（第 5 位）；回應語言在 §1.1
  本就固定繁中，與 README 語言無關
- 查 `~/.claude.json` 的內容（MCP 等）務必真正解析 JSON 判斷 scope，**不可用字串 grep** —
  該檔同時存放所有專案的 scoped 設定，純比對會把別的專案的設定誤判為已安裝
  （`mcp_scope()` 為此而寫：jq → python3 → 退化標示無法判定）
- 檢查類輸出的鐵則：**不確定就說不確定，不可退化成有把握的斷言**。`mcp_scope()`
  區分 `none`（確定沒有）／`unparseable`（檔案損毀，無從判定）／`unknown`（缺 jq
  與 python3，只有字串證據）；jq 與 python3 兩條路徑須逐項等價（型別護欄要對齊），
  否則同一台機器裝不裝 jq 會得到不同結論
- `~/.claude.json` 只涵蓋官方 `user` 與 `local` 兩種 scope；`project` scope
  （專案根目錄 `.mcp.json`）不在其中，任何以此檔為據的檢查都會低報，文件須註明
- 增刪 `REQUIRED_MCP` / `OPTIONAL_MCP` 時要**手動**同步**兩份** README 的 MCP 表格 —
  CI 只驗 skills / agents / commands 的陣列與數字，MCP 表格會靜靜過期。
  CI 不驗的手動同步區塊共 6 類（安裝步驟清單、指令一覽、官方 Plugins、
  第三方 Plugin 推薦、MCP 必要表、MCP 可選表），雙語化後 × 兩份 README = 12 處
- **安裝選項**已有 CI 防線：flag 三方對照驗「腳本 case 分支 ↔ `--help` 輸出 ↔
  兩份 README 指令範例」名稱完全一致，新增/刪除 flag 忘了同步文件會被擋。
  只驗 flag **名稱**，各 flag 的**語意描述**仍是手動維護
- **迴圈步數**已有 CI 防線：驗「全域模板 §3.9 ↔ `/dd-init` 蓋章版 ↔ 兩份 README 清單
  ↔ `dd-loop-version` 標記」四方一致。2026-08-31 迴圈 6→7→8 時，README 清單漏補一項、
  標記停在 `6step`（會讓舊專案跑 `/dd-init` 被誤判為最新），兩者都靜默失效不報錯
- `OPTIONAL_MCP` 只收 **MCP server**（會註冊進 `~/.claude.json` `mcpServers` 的東西）；
  plugin 形式的工具（如 claude-mem，`npx claude-mem install` 走 hooks + plugin 系統）
  列進去檢查會**永遠回報未安裝**，應改列 README 的「推薦第三方 Plugin」段落
- 可選 MCP 推薦名單比照使用率盤點制：上游 deprecated／改名（如 cipher → byterover-cli，
  2026-08-11 移除）或本機實際使用紀錄已斷即移除；後繼品未經實證使用不自動遞補

## 第三方 Skill / Agent 收編檢查清單（vendor intake）

> 引入任何**非自製來源**（GitHub repo、Claude marketplace、舊版安裝包）的 skill/agent 前，逐項過。**任一項不過 → 先改寫或不收**，不得直接併入部署陣列。

| # | 檢查項 | 怎麼驗 | 不過的處置 |
|---|---|---|---|
| 1 | **授權相容** | LICENSE 存在且相容（MIT/Apache 可；GPL/未標需評估）。frontmatter 若寫 `license: … LICENSE.txt`，該檔**必須同目錄存在** | 補齊 LICENSE 或移除懸空 frontmatter |
| 2 | **hook 路徑絕對化** | grep `hooks/hooks.json`，`command` 路徑須以 `/`、`$HOME/`、`~/` 或 `${CLAUDE_PLUGIN_ROOT}` 開頭（validator 會先剝掉 `bash`/`node` 等直譯器前綴再判斷）；相對路徑（`./`）不合格。詳見上方「Skill hook 路徑規範」 | 併入前改寫（`validate_skill_hooks()` 也會擋） |
| 3 | **CLI / pkg 事實驗證** | 任何 `npm install` / CLI args / 套件名，先 `npm view <pkg>` 或讀官方 README 證實，**不靠名稱推論** | 無法證實 → 不收 |
| 4 | **runtime 依賴** | 讀 SKILL.md / scripts，確認是否需 Python / Node / 全域 binary | 需額外 runtime → 違反「不塞二進制」，不收或改純設定 |
| 5 | **跨平台冪等** | 無硬編碼絕對路徑、無單一 OS 假設，重跑安裝結果一致；設定與狀態分離 | 不冪等 → 改寫 |
| 6 | **撞名 / 重疊** | 與既有 skill 比 `description`，功能不重複、命名不衝突（避免污染如下節「殘留清理」所述） | 重疊 → 評估取代或不收 |
| 7 | **納管** | 全過後：加進 `install-dd-pipeline.sh` 的 `PROMOTED_*` 部署陣列 → 跑 `--force` → 納入 source of truth | — |

> **典型踩雷**（實際評估）：某第三方 UI/UX skill 號稱 9 萬星但建立僅半年、forks 為整數 → 採用度存疑；且需 `npm -g` binary + Python runtime → 第 3、4 項直接擋下。

## 殘留清理（手動）

`install-dd-pipeline.sh` 只「部署」`BUILTIN_SKILLS`，**不會清掉**外部來源（如 tresor、舊版安裝包）放進 `~/.claude/skills/` 的殘留。已知會污染目錄的型態：

| 類型 | 範例 | 風險 |
|---|---|---|
| 安裝包 zip | `~/.claude/skills/*.zip` | 純垃圾，不會載入但佔空間 |
| 分類子目錄 | `~/.claude/skills/{communication,development,documentation,git,security}/` | 內含同名 skill（如 `code-reviewer`、`security-auditor`），與 DD wrapper 撞名 |

排查指令：

```bash
find ~/.claude/skills -maxdepth 1 -name '*.zip'                    # 查 zip 殘留（zsh 下 glob 無匹配會直接報錯，故用 find）
ls -d ~/.claude/skills/{communication,development,documentation,git,security} 2>/dev/null  # 查分類目錄殘留
```

確認非 DD pipeline 內容後手動 `rm` / `rm -rf` 清掉。
