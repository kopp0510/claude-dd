# scripts/ — 輔助腳本

部署到 `~/.claude/scripts/` 的輔助腳本層（部署清單由 `install-dd-pipeline.sh`
頂部的 `DD_SCRIPTS` 陣列決定），加上本 repo 自用的 git hooks。

## 關鍵檔案

- `check-claude-md.sh` — CLAUDE.md pre-commit gate（block 版）。規則：staged
  變更含程式碼檔（副檔名見腳本內 `CODE_EXT`）的目錄，必須存在 CLAUDE.md 且
  同批 staged；逃生口 `SKIP_DOC_CHECK=1`（僅供迴圈檢查點 commit）。由
  `/dd-init` 掛進各專案的 `.git/hooks/pre-commit`。
- `githooks/pre-commit` — 本 repo 自用（dogfood），轉呼叫上面的 gate。
  **不部署**到 `~/.claude/`；啟用方式：`git config core.hooksPath scripts/githooks`。
  注意 `core.hooksPath` 設定後 git 會完全忽略 `.git/hooks/`，與 `/dd-init` 的
  預設掛載點互斥（dd-init Phase 3 會偵測並改掛到 hooksPath 目錄）。

## 此層慣例

- 新增要部署的腳本：檔案放這裡 + 加入 `DD_SCRIPTS` 陣列 + `--force` 重新部署
- 腳本必須通過 `shellcheck -S warning`（CI 強制）且可在 macOS bash 3.2 執行
- gate 的檢查邏輯改動時，同步檢視全域模板 §3.9 對 gate 行為的描述

## 與上層的關係

安裝腳本的 `create_scripts()` 負責部署（覆蓋前有差異備份）；gate 的使用情境
定義在 `templates/global/CLAUDE.md` §3.9 與根目錄 CLAUDE.md「核心工作法」。
