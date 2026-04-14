# DD Pipeline — Claude Code 自動化開發流程

可攜式 Claude Code 設定庫，透過 `install-dd-pipeline.sh` 安裝到 `~/.claude/` 全域。

## 安裝 / 更新

```bash
./install-dd-pipeline.sh          # 首次安裝
./install-dd-pipeline.sh --force  # 強制更新所有檔案
./install-dd-pipeline.sh --check  # 只檢查環境
```

## 目錄結構

- `skills/` — 63 個 Skills（每個子目錄含 SKILL.md 定義檔）
- `commands/` — 6 個 dd-* 指令（.md 平面檔） + 19 個命名空間 command 目錄
- `templates/` — 8 個文件模板
- `install-dd-pipeline.sh` — 安裝腳本（部署到 ~/.claude/）

## 新增 Skill 步驟

1. 在 `skills/<skill-name>/` 建立 `SKILL.md`
2. 在 `install-dd-pipeline.sh` 的 `BUILTIN_SKILLS` 陣列加入名稱
3. 執行 `./install-dd-pipeline.sh --force` 部署

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
- 修改 skills/commands 後務必同步更新 install-dd-pipeline.sh
