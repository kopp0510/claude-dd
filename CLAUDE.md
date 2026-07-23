# DD Pipeline — Claude Code 自動化開發流程

可攜式 Claude Code 設定庫，透過 `install-dd-pipeline.sh` 安裝到 `~/.claude/` 全域。

## 安裝 / 更新

```bash
./install-dd-pipeline.sh                    # 首次安裝（只裝 promoted 桶）
./install-dd-pipeline.sh --force            # 強制更新所有檔案
./install-dd-pipeline.sh --force --prune    # 更新並清掉 ~/.claude 中未部署桶位的舊檔（需確認）
./install-dd-pipeline.sh --with-misc        # 連同 misc 桶（SRE / 備援項目）
./install-dd-pipeline.sh --with-deprecated  # 連同 deprecated 桶（0 使用率封存）
./install-dd-pipeline.sh --check            # 只檢查環境
```

## 分桶制（2026-07-23 依全 transcript 使用率盤點）

所有 skills/agents/commands 檔案保留於 repo，**部署與否由安裝腳本的桶陣列決定**（不搬目錄）：

| 桶 | 定義 | 部署條件 |
|---|---|---|
| **promoted** | 實證常用（8 skills、4 agents、dd-init、workflow-review） | 預設部署 |
| **misc** | 低頻但屬 SRE / 備援性質（11 skills、5 NS commands） | `--with-misc` |
| **deprecated** | 全歷史 0 次使用（34 skills、17 agents、6 dd commands、13 NS commands） | `--with-deprecated`；觀察期後可評估刪除 |

桶陣列定義在 `install-dd-pipeline.sh` 頂部（`PROMOTED_*` / `MISC_*` / `DEPRECATED_*`）。

## 目錄結構

- `skills/` — 53 個 Skills（每個子目錄含 SKILL.md 定義檔；部署依分桶）
- `agents/` — 21 個 Agents（部署依分桶；promoted：code-simplifier、code-reviewer 官方備份 + senior-devops、security-auditor）
- `commands/` — 7 個 dd-* 指令（.md 平面檔；僅 dd-init 預設部署） + 19 個命名空間 command 目錄（僅 workflow-review 預設部署）
- `templates/` — 7 個文件模板（`.template`，部署到 `~/.claude/templates/dd/`）+ 1 份全域 CLAUDE.md 模板（`templates/global/`，另經互動比對部署到 `~/.claude/CLAUDE.md`）
- `install-dd-pipeline.sh` — 安裝腳本（部署到 ~/.claude/）

## 新增 Skill 步驟

1. 在 `skills/<skill-name>/` 建立 `SKILL.md`
2. 在 `install-dd-pipeline.sh` 依定位加入 `PROMOTED_SKILLS` / `MISC_SKILLS` 陣列（新 skill 不進 deprecated）
3. 執行 `./install-dd-pipeline.sh --force` 部署

### Skill hook 路徑規範（強制）

skill 若含 `hooks/hooks.json`，其中 `command` **必須**用可在任意 cwd 解析的路徑：

- ✅ `$HOME/.claude/skills/<skill-name>/hooks/xxx.sh`
- ❌ `./hooks/xxx.sh`（hook 以「當前工作目錄」為基準執行，換到別的專案就找不到腳本）

安裝腳本的 `validate_skill_hooks()` 會在部署前掃描所有 `hooks.json`，發現相對路徑即**中止部署**。
引入第三方 skill（vendor）時尤其注意：上游常用相對路徑，併入前先改寫（完整收編流程見下方「第三方 Skill / Agent 收編檢查清單」）。

## 新增 Agent 步驟

1. 在 `agents/` 建立 `<agent-name>.md`（frontmatter 含 `name`、`description`、`model: inherit`）
2. 在 `install-dd-pipeline.sh` 的 `PROMOTED_AGENTS` 陣列加入名稱
3. 執行 `./install-dd-pipeline.sh --force` 部署
4. 若 agent 被某個 wrapper skill 調用，確認該 skill 的 Task `subagent_type` 先試 `<name>:<name>`（plugin 命名空間）再 fallback `<name>`（本地）

## 新增 Command 步驟

- 平面指令：在 `commands/` 建立 `<name>.md`，並更新 `install-dd-pipeline.sh` 頂層的 `DD_COMMANDS` 陣列
- 命名空間指令：在 `commands/<namespace>/` 建立 `.md` 檔案，並更新 `install-dd-pipeline.sh` 頂層的 `NS_COMMANDS` 陣列（或依定位放 `MISC_NS_COMMANDS`）

## 核心工作法：5 步開發迴圈

骨幹已從多階段 DD Pipeline 換成 lawdesk-ai 實戰驗證的功能段落迴圈
（定義於 `templates/global/CLAUDE.md` §3.9，專案具體版由 `/dd-init` 蓋章）：

```
實作 → commit → code-simplifier → 真實環境驗證(curl / playwright) → commit
```

搭配巢狀 CLAUDE.md 堆疊維護（依賴 `claude-md-management` plugin，安裝腳本管理）。

> **舊 DD Pipeline（deprecated 桶封存）**：`/dd-start → /dd-arch → /dd-approve → /dd-dev → /dd-test`
> 多階段流程於 2026-07-23 依使用率盤點（全歷史 0 次使用）移入 deprecated 桶，
> 檔案保留於 `commands/`，`--with-deprecated` 可重新部署。舊版 dd-init 見 git 歷史。

## 注意事項

- 所有回應和註解使用繁體中文
- Commit message 使用繁體中文
- 此專案是 source of truth，全域 ~/.claude/ 的內容由安裝腳本從此專案部署
- 修改 skills/agents/commands 後務必同步更新 install-dd-pipeline.sh

## 第三方 Skill / Agent 收編檢查清單（vendor intake）

> 引入任何**非自製來源**（GitHub repo、Claude marketplace、舊版安裝包）的 skill/agent 前，逐項過。**任一項不過 → 先改寫或不收**，不得直接併入 `BUILTIN_*` 陣列。

| # | 檢查項 | 怎麼驗 | 不過的處置 |
|---|---|---|---|
| 1 | **授權相容** | LICENSE 存在且相容（MIT/Apache 可；GPL/未標需評估）。frontmatter 若寫 `license: … LICENSE.txt`，該檔**必須同目錄存在** | 補齊 LICENSE 或移除懸空 frontmatter |
| 2 | **hook 路徑絕對化** | grep `hooks/hooks.json`，`command` 必為 `$HOME/.claude/…`，無相對路徑（`./`）。詳見上方「Skill hook 路徑規範」 | 併入前改寫（`validate_skill_hooks()` 也會擋） |
| 3 | **CLI / pkg 事實驗證** | 任何 `npm install` / CLI args / 套件名，先 `npm view <pkg>` 或讀官方 README 證實，**不靠名稱推論** | 無法證實 → 不收 |
| 4 | **runtime 依賴** | 讀 SKILL.md / scripts，確認是否需 Python / Node / 全域 binary | 需額外 runtime → 違反「不塞二進制」，不收或改純設定 |
| 5 | **跨平台冪等** | 無硬編碼絕對路徑、無單一 OS 假設，重跑安裝結果一致；設定與狀態分離 | 不冪等 → 改寫 |
| 6 | **撞名 / 重疊** | 與既有 skill 比 `description`，功能不重複、命名不衝突（避免污染如下節「殘留清理」所述） | 重疊 → 評估取代或不收 |
| 7 | **納管** | 全過後：加進 `install-dd-pipeline.sh` 的 `BUILTIN_*` → 跑 `--force` → 納入 source of truth | — |

> **典型踩雷**（實際評估）：某第三方 UI/UX skill 號稱 9 萬星但建立僅半年、forks 為整數 → 採用度存疑；且需 `npm -g` binary + Python runtime → 第 3、4 項直接擋下。

## 殘留清理（手動）

`install-dd-pipeline.sh` 只「部署」`BUILTIN_SKILLS`，**不會清掉**外部來源（如 tresor、舊版安裝包）放進 `~/.claude/skills/` 的殘留。已知會污染目錄的型態：

| 類型 | 範例 | 風險 |
|---|---|---|
| 安裝包 zip | `~/.claude/skills/*.zip` | 純垃圾，不會載入但佔空間 |
| 分類子目錄 | `~/.claude/skills/{communication,development,documentation,git,security}/` | 內含同名 skill（如 `code-reviewer`、`security-auditor`），與 DD wrapper 撞名 |

排查指令：

```bash
ls ~/.claude/skills/*.zip 2>/dev/null                              # 查 zip 殘留
ls -d ~/.claude/skills/{communication,development,documentation,git,security} 2>/dev/null  # 查分類目錄殘留
```

確認非 DD pipeline 內容後手動 `rm` / `rm -rf` 清掉。
