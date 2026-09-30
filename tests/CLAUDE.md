# tests/ — CI 跑的情境測試

放「不屬於任何一支部署腳本、但 CI 要跑」的測試。**不部署**：不在 `scripts/` 底下，
所以 `DD_SCRIPTS ↔ scripts/*.sh` 那道一致性檢查不會把它當成要部署的腳本。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `test-gate.sh` | CLAUDE.md gate（`scripts/check-claude-md.sh`）的情境測試：段落起點、SKIP 欠帳、merge、改寫過的歷史、中文與含空白的路徑。在拋棄式 repo 裡掛上 gate 實際 commit，逐案印 ✅／❌，有 ❌ 就 exit 1。第一個參數可以換成別的 gate 路徑，做「改壞一行、確認會出現 ❌」的變異測試 |

## 此層約束

- **CI 在兩種 bash 上各跑一次**：ubuntu（bash 5）與 macOS 的 `/bin/bash` 3.2（`.github/workflows/ci.yml`）。
  gate 與它的 hook 都靠 shebang `#!/bin/bash` 執行，所以在 macOS 上測到的就是使用者機器上的那個 bash
- **輸出裡出現 shell 錯誤就判失敗**（`bad substitution`、`syntax error`、`command not found`、`invalid option`、
  `unbound variable`）：bash 3.2 不支援的寫法常常只印一行錯誤、判斷結果照舊，只看 pass／block 的話 macOS job 照樣全綠。
  2026-10-01 實測：在 gate 裡加一行 `${staged,,}`，3.2 下 49 個 ❌、bash 5 下全過 —— 這正是那個 job 要抓的
- 腳本開頭是 `set -e`（2026-10-01 從 ci.yml 內嵌 step 搬出來時照 GitHub Actions 預設的 `bash -e` 保留）：
  預期會被擋的 commit 一律包在 `expect` 的 `if` 裡，新增情境時別讓會回非 0 的指令裸跑
- 本機跑：`/bin/bash tests/test-gate.sh`（repo 根目錄或任何地方都可以，gate 路徑以腳本位置推算）
- 要通過 `shellcheck -S warning`（CI 的 ShellCheck 清單逐檔寫死，這支已列入）

## 與上層的關係

gate 本體的規則與「改了 gate 要做變異測試」的規定在 `scripts/CLAUDE.md`；CI 防線的總表在
根目錄的 `DD_PIPELINE_ARCHITECTURE.md`。
