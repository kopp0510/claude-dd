# DD Pipeline — Claude Code 自動化開發流程

可攜式 Claude Code 設定庫，透過 `install-dd-pipeline.sh` 安裝到 `~/.claude/` 全域。

## 安裝 / 更新

```bash
./install-dd-pipeline.sh          # 首次安裝
./install-dd-pipeline.sh --force  # 強制更新所有檔案
./install-dd-pipeline.sh --check  # 只檢查環境
```

## 目錄結構

- `skills/` — 53 個 Skills（每個子目錄含 SKILL.md 定義檔）
- `agents/` — 20 個 Agents（18 個自製補齊含 senior-* 全家族 + 2 個官方備份 code-simplifier/code-reviewer，部署到 `~/.claude/agents/`）
- `commands/` — 6 個 dd-* 指令（.md 平面檔） + 19 個命名空間 command 目錄
- `templates/` — 8 個文件模板
- `install-dd-pipeline.sh` — 安裝腳本（部署到 ~/.claude/）

## 新增 Skill 步驟

1. 在 `skills/<skill-name>/` 建立 `SKILL.md`
2. 在 `install-dd-pipeline.sh` 的 `BUILTIN_SKILLS` 陣列加入名稱
3. 執行 `./install-dd-pipeline.sh --force` 部署

## 新增 Agent 步驟

1. 在 `agents/` 建立 `<agent-name>.md`（frontmatter 含 `name`、`description`、`model: inherit`）
2. 在 `install-dd-pipeline.sh` 的 `BUILTIN_AGENTS` 陣列加入名稱
3. 執行 `./install-dd-pipeline.sh --force` 部署
4. 若 agent 被某個 wrapper skill 調用，確認該 skill 的 Task `subagent_type` 先試 `<name>:<name>`（plugin 命名空間）再 fallback `<name>`（本地）

## 新增 Command 步驟

- 平面指令：在 `commands/` 建立 `<name>.md`，並更新 `create_commands()` 的 `dd_commands` 陣列
- 命名空間指令：在 `commands/<namespace>/` 建立 `.md` 檔案，並更新 `create_commands()` 的 `ns_commands` 陣列

## DD Pipeline 流程

```
/dd-init → /dd-start(RDD) → /dd-arch(SDD/DDD/ADD/EDD)
→ [人工審核: /dd-approve，需修改時直接編輯 claude_docs/*.md 後重跑 /dd-approve]
→ /dd-dev(DbC/CDD/PDD) → /dd-test(TDD/BDD/ATDD/FDD)
```

## 注意事項

- 所有回應和註解使用繁體中文
- Commit message 使用繁體中文
- 此專案是 source of truth，全域 ~/.claude/ 的內容由安裝腳本從此專案部署
- 修改 skills/agents/commands 後務必同步更新 install-dd-pipeline.sh

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
