# tests/ — CI 跑的情境測試

放「不屬於任何一支部署腳本、但 CI 要跑」的測試。**不部署**：不在 `scripts/` 底下，
所以 `DD_SCRIPTS ↔ scripts/*.sh` 那道一致性檢查不會把它當成要部署的腳本。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `test-install.sh` | 安裝腳本的端到端測試：拋棄式 HOME 裡非互動安裝，驗部署內容等於部署清單、重跑冪等、`--force` 內容相同不重寫、`--update`、`--commands-only`、`--uninstall` 非互動預設取消、`--check` 不寫入、`--help` 可執行。跑完清掉暫存目錄 |
| `test-gate.sh` | CLAUDE.md gate（`scripts/check-claude-md.sh`）的情境測試：段落起點、SKIP 欠帳、merge、改寫過的歷史、中文與含空白的路徑。在拋棄式 repo 裡掛上 gate 實際 commit，逐案印 ✅／❌，有 ❌ 就 exit 1。第一個參數可以換成別的 gate 路徑，做「改壞一行、確認會出現 ❌」的變異測試。**2026-10-07（S6）新增 review 報告強制的情境**（導入路徑被擋 / SKIP 申報放行 / 沒報告擋下 / 兩份報告放行 / `CLAUDE.md` 不算 / **只改既有報告不算新增** / **amend 過的歷史仍照擋** / `SUMMARY.md` 不算 / 刪目錄退出）。**2026-10-07（S4）又加了「三處退化政策各自的行為」**（起點不是祖先時:`--segment-base` 硬失敗、`reviews_missing` 退到共同祖先照樣擋;連共同祖先都沒有時:兩處放行**但必須印出警告**）—— ⚠️ 這幾則有兩個容易寫成空洞斷言的地方:**①`docs/reviews/` 是 opt-in、判準是工作目錄裡有沒有那個目錄**,切到不含它的分支就整個檢查不啟用,測試會「為了錯的理由而通過」(第一版就是);**②`--start-segment` 通過時會寫入新起點**,所以 `base_is` 只能放在它之前。⚠️ **不要在這裡寫「N 項」** —— 本檔寫過「61 → 73」，收 review 時又加了三個情境就過期了；項數自己跑 `bash tests/test-gate.sh | grep -c "^✅"`。 |

## 此層約束

- **CI 在兩種 bash 上各跑一次**：ubuntu（bash 5）與 macOS 的 `/bin/bash` 3.2（`.github/workflows/ci.yml`）。
  gate 與它的 hook 都靠 shebang `#!/bin/bash` 執行，所以在 macOS 上測到的就是使用者機器上的那個 bash
- **`test-gate.sh` 在 gate 的輸出裡看到 shell 錯誤就判失敗**（`bad substitution`、`syntax error`、`command not found`、
  `invalid option`、`unbound variable`，以及 bash 報腳本錯誤固定的「`: line N: `」前綴）：bash 3.2 不支援的寫法常常
  只印一行錯誤、判斷結果照舊，只看 pass／block 的話 macOS job 照樣全綠。2026-10-01 實測：在 gate 的
  `staged=$(…)` 下一行（第 153 行）加 `lc=${staged,,}`，3.2 下 36 個 ❌、bash 5 全過；`shopt -s lastpipe`、
  `${a[-1]}` 這類清單外的錯誤，是加了「`: line N: `」前綴才抓到的。`test-install.sh` 不做這層檢查，靠 `set -e`：
  3.2 在 `set -e` 下遇到這類錯誤會直接中止
- 兩支都在暫存目錄裡跑、`trap` 跑完清掉（本機會拿來重跑與做變異測試）
- 腳本開頭是 `set -e`（2026-10-01 從 ci.yml 內嵌 step 搬出來時照 GitHub Actions 預設的 `bash -e` 保留）：
  預期會被擋的 commit 一律包在 `expect` 的 `if` 裡，新增情境時別讓會回非 0 的指令裸跑
- ⚠️⚠️ **變異測試要選對「變異方向」,否則它證明的不是你以為的那件事**(2026-10-07,S6,
  兩份 reviewer 都抓到)。我把 opt-in 守門 `[ -d docs/reviews ] || return 1` 改成**永遠 `return 1`**
  (= 功能全關),拿到的紅**全部落在新區塊** —— 那證明「新情境在測這個功能」,
  **跟「opt-in 保護了沒採用的專案」完全無關**。對應後者的變異是**把那行整個拿掉**
  (檢查對所有 repo 生效),紅的才會落在**舊的那批**。三組實測:
  | 變異 | 紅 | 證明的是 |
  |---|---|---|
  | 那行 → 永遠 `return 1` | 12 | 新情境真的在測這個功能 |
  | **那行整個拿掉** | 5,其中 4 在舊的那批 | ← opt-in 那句的佐證 |
  | `--diff-filter=A` → `ACMR` | 2 | 「只改既有報告不算新增」有被釘住 |
  **做法**:寫「變異測試證明了 X」之前,先問「**把 X 弄壞的最小改動是哪一行**」,
  然後改那一行 —— 不是改一個會讓整個功能消失的地方。
- ⚠️⚠️ **一個「恆真」的斷言比沒有斷言更糟**(同一輪,reviewer 插 DBG 證明)。
  我在情境 ① 寫 `BEFORE_BASE=$(cat "$BASE_FILE")` 然後 `base_is "$BEFORE_BASE"`,
  但那行讀檔是在 `expect … --start-segment` **跑完之後** —— 等於拿檔案跟自己比,**永遠綠**。
  實測:對變異版,①的起點**確實被搬動了**而斷言照樣過;那個不變量**實際只有情境 ③ 在守**。
  **做法**:斷言「X 沒有被改動」時,快照一定要在**被測指令之前**取;
  而且**用變異測試檢查這個斷言本身會不會紅** —— 不會紅的斷言是裝飾品。
- ⚠️ **新增的 review 強制情境刻意跑在「有 `docs/reviews/` 目錄」的 repo 裡，而前 61 項沒有**
  —— 那正是 opt-in 的證明：**加了新功能，既有 61 項一項都不用改**。
  寫新情境時不要把 `mkdir docs/reviews` 往上搬，會把前面 61 項的前提改掉。
- ⚠️ **「剛採用慣例時第一次 `--start-segment` 被擋」是情境 ①，不是待修的邊角** ——
  上一段本來就沒報告，那是真實的導入路徑；我第一版把它寫成 `pass`，跑出來才發現寫錯了。
- 本機跑：`/bin/bash tests/test-gate.sh`（repo 根目錄或任何地方都可以，gate 路徑以腳本位置推算）
- 要通過 `shellcheck -S warning`（CI 的 ShellCheck 清單逐檔寫死，這支已列入）

## 與上層的關係

gate 本體的規則與「改了 gate 要做變異測試」的規定在 `scripts/CLAUDE.md`；CI 防線的總表在
根目錄的 `DD_PIPELINE_ARCHITECTURE.md`。
