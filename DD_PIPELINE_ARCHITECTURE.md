# claude-dd 架構 — Portable Claude Code Profile

> 本文件描述現行架構（2026-08-04 重寫，取代舊多階段 DD Pipeline 版本；
> 舊版流程圖、agent/命令表與對應實作均見 git 歷史）。

## 定位

這個 repo 有兩個目標：

1. **跨機恢復**：換電腦時 `git clone` + 一支腳本，完整重建 `~/.claude/` 的
   skills / agents / commands / scripts / 全域 CLAUDE.md。
2. **分享用法**：別人 clone 後跑同一支腳本，就能取得同一套工作法
   （6 步開發迴圈 + CLAUDE.md gate + 使用率盤點後的精選元件）。

兩個目標共用**同一條安裝路線**（曾評估 plugin marketplace 分發，因無法交付
全域 CLAUDE.md 與 gate、只能給元件子集而不採用，維持單一路線；見 git 歷史）。

設計約束由此而來：**冪等**（重跑結果一致）、**跨平台**（macOS bash 3.2 與
ubuntu CI 都要過）、**不塞二進制 / 不加 runtime 依賴**（只用 bash + jq 或
python3 擇一）、**設定與狀態分離**（repo 只放設定，執行期產物不進版控）。

## 三層架構

```
┌────────────────────────────────────────────────────────┐
│  claude-dd repo（source of truth，git 版控）             │
│  skills/  agents/  commands/  templates/  scripts/      │
└───────────────────────┬────────────────────────────────┘
                        │  ./install-dd-pipeline.sh
                        │  （依部署清單複製，非 symlink）
                        ▼
┌────────────────────────────────────────────────────────┐
│  ~/.claude/（部署目標，可隨時由 repo 重建）               │
│  skills/  agents/  commands/  scripts/                  │
│  CLAUDE.md（全域，互動比對安裝）  settings.json（plugin） │
│  backups/pre-install-*/（覆蓋前自動備份）                │
└───────────────────────┬────────────────────────────────┘
                        │  /dd-init（逐專案蓋章）
                        ▼
┌────────────────────────────────────────────────────────┐
│  各專案（專案 CLAUDE.md + .git/hooks/pre-commit gate）   │
└────────────────────────────────────────────────────────┘
```

修改一律改 repo 再重新部署；直接改 `~/.claude/` 的內容會在下次安裝時
被覆蓋（覆蓋前自動備份到 `~/.claude/backups/`）。

## 安裝腳本（install-dd-pipeline.sh）

7 個步驟：環境檢查 → hook 路徑驗證（前置）→ Skills → Agents → MCP 檢查 →
官方 Plugins → Commands + 輔助腳本 → 全域 CLAUDE.md（互動比對）。

行為保證：

- **冪等**：所有部署點（skills / agents / commands / scripts / 全域 CLAUDE.md）
  內容相同報「已是最新」不重寫（含 `--force`）；重跑不產生備份。
- **非互動安全**：無 TTY（CI、`curl | bash`）時互動詢問一律採預設值，
  不會中止；破壞性操作（`--uninstall`）預設取消，自動化用 `--yes`。
- **失敗不半套**：JSON 讀寫失敗（settings.json 損毀等）警告後跳過該項，
  不在 `set -e` 下炸掉整個安裝；JSON 就地改寫保留 inode / symlink / 權限
  （`jq_inplace` / `py_inplace` / `json_edit`，jq 優先、python3 後備）。
- **可回復**：覆蓋差異檔前備份到 `~/.claude/backups/pre-install-<時間>/`，
  完成訊息顯示位置；`--uninstall` 只移除本 repo 部署過的項目。

## 部署清單（使用率盤點制）

依全 transcript 使用率盤點，repo 只保留有實證使用紀錄的元件並全數預設部署
（清單 = 腳本頂部 `PROMOTED_*` 陣列：10 skills、4 agents、dd-init、workflow-review；
2026-08-04 盤點留存 9 skills，2026-08-10 新增自製 tech-diagram-gif）。
零使用的 misc 桶與 deprecated 桶已於 2026-08-04 刪除，git 歷史可回溯。

目的：控制每個 session 的 context 稅（skill 清單載入 system prompt 有
預算上限）；需要時自 git 歷史取回並加回陣列即可重新部署。

## 核心工作法：6 步開發迴圈

```
實作+測試 → commit → code-simplifier → code-review → 再測 → commit
```

定義於 `templates/global/CLAUDE.md` §3.9，專案具體版由 `/dd-init` 蓋章。
配套：巢狀 CLAUDE.md 堆疊維護，由 **pre-commit gate**
（`scripts/check-claude-md.sh`）強制 — 改碼目錄缺 CLAUDE.md 或未同批更新
即擋 commit；檢查點 commit 逃生口 `SKIP_DOC_CHECK=1`。

本 repo 自身也掛同一個 gate（dogfood），啟用方式見根目錄 CLAUDE.md
「開發本 repo」一節。

## CI 防線（.github/workflows/ci.yml）

| 檢查 | 防什麼 |
|---|---|
| bash -n（安裝腳本）+ shellcheck（warning 級，4 支腳本） | 語法與常見 bash 陷阱 |
| 陣列 ↔ 目錄一致性（ALL_* = 部署清單） | 陣列漏列 / 目錄改名未同步 |
| README / CLAUDE.md 數字宣稱 ↔ 陣列 | 文件數字過期 |
| §7.2 觸發目標部署驗證 | 全域模板指向未部署元件 |
| Sandbox 端到端非互動安裝 | 只有執行期才會出現的安裝 bug |

CI 直接 `source` 安裝腳本取用陣列（腳本尾端有 source guard）。

## 授權

Root MIT（LICENSE）。vendored 內容各自附上游授權
（`skills/writing-great-skills/LICENSE.txt`、`skills/frontend-design/LICENSE.txt`），
收編規則見根目錄 CLAUDE.md「第三方 Skill / Agent 收編檢查清單」。
