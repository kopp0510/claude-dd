# DD Pipeline — Claude Code 自動化開發流程

可攜式 Claude Code 設定庫，透過 `install-dd-pipeline.sh` 安裝到 `~/.claude/` 全域。

## 安裝 / 更新

```bash
./install-dd-pipeline.sh                    # 首次安裝
./install-dd-pipeline.sh --force            # 強制更新所有檔案
./install-dd-pipeline.sh --check            # 只檢查環境
./install-dd-pipeline.sh --uninstall --yes  # 免確認解除安裝（自動化；非互動環境的詢問一律採預設值）
```

> 從舊版（全量部署 / 分桶時期）升級、既有專案升級到 6 步迴圈：見 README.md「升級指南」。

## 部署清單（使用率盤點制）

repo 只保留**有實證使用紀錄**的元件（2026-08-04 盤點留存 9 skills、4 agents、
dd-init、workflow-review；2026-08-10 新增自製 tech-diagram-gif，實證來源為當次
對話的完整管線驗證），全部預設部署；清單定義在 `install-dd-pipeline.sh` 頂部的
`PROMOTED_*` 陣列。

- 歷次盤點刪除（git 歷史可回溯）：deprecated 桶（全歷史 0 次使用的 34 skills /
  17 agents / 6 dd 指令 / 13 NS commands）與 misc 桶（SRE 備援性質但零實際調用的
  11 skills / 5 NS commands）均於 2026-08-04 刪除；取回方式
  `git checkout 9a16629 -- skills/<名字>` 後加回陣列

## 目錄結構

- `skills/` — 10 個 Skills（每個子目錄含 SKILL.md 定義檔，全數部署；writing-great-skills 為 vendored 自 mattpocock/skills 的 skill 撰寫參考、tech-diagram-gif 的風格規範 vendored 自 fireworks-tech-graph）
- `agents/` — 4 個 Agents（code-simplifier、code-reviewer 官方備份 + senior-devops、security-auditor）
- `commands/` — 1 個 dd-* 指令（dd-init，.md 平面檔） + 1 個命名空間 command 目錄（workflow-review）
- `templates/` — 7 個文件模板（`.template`，部署到 `~/.claude/templates/dd/`）+ 1 份全域 CLAUDE.md 模板（`templates/global/`，另經互動比對部署到 `~/.claude/CLAUDE.md`）
- `scripts/` — 輔助腳本（部署到 `~/.claude/scripts/`；含 check-claude-md.sh pre-commit gate 與本 repo 自用的 `githooks/`，後者不部署）
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

1. 在 `agents/` 建立 `<agent-name>.md`（frontmatter 含 `name`、`description`、`model: inherit`）
2. 在 `install-dd-pipeline.sh` 的 `PROMOTED_AGENTS` 陣列加入名稱
3. 執行 `./install-dd-pipeline.sh --force` 部署
4. 若 agent 被某個 wrapper skill 調用，確認該 skill 的 Task `subagent_type` 先試 `<name>:<name>`（plugin 命名空間）再 fallback `<name>`（本地）

## 新增 Command 步驟

- 平面指令：在 `commands/` 建立 `<name>.md`，並更新 `install-dd-pipeline.sh` 頂層的 `DD_COMMANDS` 陣列
- 命名空間指令：在 `commands/<namespace>/` 建立 `.md` 檔案，並更新 `install-dd-pipeline.sh` 頂層的 `NS_COMMANDS` 陣列

## 核心工作法：6 步開發迴圈

骨幹已從多階段 DD Pipeline 換成 lawdesk-ai 實戰驗證的功能段落迴圈
（定義於 `templates/global/CLAUDE.md` §3.9，專案具體版由 `/dd-init` 蓋章）：

```
實作+測試 → commit → code-simplifier → code-review → 再測(curl/playwright) → commit
```

搭配巢狀 CLAUDE.md 堆疊維護（依賴 `claude-md-management` plugin，安裝腳本管理），
並由 **pre-commit gate 強制**（block 版）：`scripts/check-claude-md.sh` 部署到
`~/.claude/scripts/`，`/dd-init` 掛進專案 `.git/hooks/pre-commit` — 改碼目錄缺
CLAUDE.md 或未同批更新即擋 commit；檢查點 commit 逃生口 `SKIP_DOC_CHECK=1`。

> **舊 DD Pipeline（已刪除）**：`/dd-start → /dd-arch → /dd-approve → /dd-dev → /dd-test`
> 多階段流程於 2026-07-23 依使用率盤點（全歷史 0 次使用）封存、2026-08-04 刪除，
> 檔案與舊版 dd-init 見 git 歷史（如 `git show 9a16629:commands/dd-dev.md`）。

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

## 第三方 Skill / Agent 收編檢查清單（vendor intake）

> 引入任何**非自製來源**（GitHub repo、Claude marketplace、舊版安裝包）的 skill/agent 前，逐項過。**任一項不過 → 先改寫或不收**，不得直接併入部署陣列。

| # | 檢查項 | 怎麼驗 | 不過的處置 |
|---|---|---|---|
| 1 | **授權相容** | LICENSE 存在且相容（MIT/Apache 可；GPL/未標需評估）。frontmatter 若寫 `license: … LICENSE.txt`，該檔**必須同目錄存在** | 補齊 LICENSE 或移除懸空 frontmatter |
| 2 | **hook 路徑絕對化** | grep `hooks/hooks.json`，`command` 必為 `$HOME/.claude/…`，無相對路徑（`./`）。詳見上方「Skill hook 路徑規範」 | 併入前改寫（`validate_skill_hooks()` 也會擋） |
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
ls ~/.claude/skills/*.zip 2>/dev/null                              # 查 zip 殘留
ls -d ~/.claude/skills/{communication,development,documentation,git,security} 2>/dev/null  # 查分類目錄殘留
```

確認非 DD pipeline 內容後手動 `rm` / `rm -rf` 清掉。
