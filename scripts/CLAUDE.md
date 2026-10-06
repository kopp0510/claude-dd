# scripts/ — 輔助腳本

部署到 `~/.claude/scripts/` 的輔助腳本層（部署清單由 `install-dd-pipeline.sh`
頂部的 `DD_SCRIPTS` 陣列決定），加上本 repo 自用的 git hooks。

## 關鍵檔案

- `check-claude-md.sh` — CLAUDE.md pre-commit gate（block 版）。規則：staged
  變更含程式碼檔（副檔名見腳本內 `CODE_EXT`）的目錄，必須存在 CLAUDE.md 且
  同批 staged；逃生口 `SKIP_DOC_CHECK=1`（僅供迴圈檢查點 commit）。由
  `/dd-init` 掛進各專案的 `.git/hooks/pre-commit`。
  - **擋不到 `git commit --no-verify`／`-n`**：git 直接跳過 pre-commit，gate 整個不跑，
    SKIP 那種「沒起點就自動記」也不會發生。已經記過段落起點時，之後的正常 commit 會在欠帳裡補抓到；
    沒記起點、或繞過的就是最後一個 commit，就完全漏查。被擋時的訊息結尾會提醒別這樣繞；
    Claude 端由 `skills/gate-guard` 的 PreToolUse hook 在執行前 deny
  - **`--start-segment` 有兩個擋點，`reviews_missing()` 是第二個**（2026-10-07，S6）：
    專案**有 `docs/reviews/` 目錄時**（= opt-in），檢查「上一段的 commit 範圍內有沒有新增
    `docs/reviews/S*.md`」—— 沒有就 `exit 1`。擋點放在這裡而不是 pre-commit 的理由：
    **pre-commit 收到 0 個參數、拿不到 commit 訊息**，而「翻 `DONE`」那個 commit 不一定存在；
    `--start-segment` 是每段必經、而且天然就在「上一段剛結束」那個時點。
    - ⚠️ **`[ -d docs/reviews ] || return 1` 這行是 opt-in 的全部** —— 動它會讓
      **所有**沒採用這個慣例的專案（含 `test-gate.sh` 前 61 項用的拋棄式 repo）一起被擋。
    **變異測試的三組數字**(2026-10-07 實跑;⚠️ **第一版只寫了一組,而且量錯對象** ——
    reviewer 指出那組 7 紅全在新區塊,跟「opt-in 保護了前 61 項」這個宣稱無關):
    | 變異 | 紅 | 它證明的是 |
    |---|---|---|
    | 那行改成永遠 `return 1`(功能全關) | **12** | 新區塊的九個情境真的在測這個功能 |
    | **把那行整個拿掉**(檢查對所有 repo 生效) | **5**,其中 **4 在舊的 61 項** | ← **這組才是 opt-in 那句的佐證** |
    | `--diff-filter=A` 改回 `ACMR` | **2** | 「只改既有報告不算新增」有被釘住 |
    - ⚠️ **`--diff-filter=A`(只算「新增」)是刻意的**:gate 自己的訊息與五份文件都寫
      「有沒有**新增**」,而第一版用 `ACMR` —— 於是**上一段的 `S1-a.md` 改個錯字,
      這一段零報告也能開下一段**(reviewer 實跑抓到)。代價:報告的「處置」節如果要等
      下一段才寫得出來,那次補寫不算這一段的證據 —— 本專案的流程是在步驟 4 當場寫完,所以不衝突。
    - ⚠️ 比對用 `(^|/)S[^/]*\.md$`，所以 `docs/reviews/CLAUDE.md` 自然不算報告。
    - ⚠️ 它**不是閉環**：擋得住的只有「開下一段」這個時點，
      「跑完但永遠不開下一段」仍然繞得過。`templates/global/CLAUDE.md` 寫明了這點。
  - **SKIP 不是豁免**：段落起點記在 `git rev-parse --git-path dd-segment-base`
    （`--start-segment` 記下；忘了記時第一個 SKIP commit 自動記）。之後的正常 commit
    沿著 commit 的祖先關係結算起點以來的欠帳：改程式碼記帳，要由看得到那段程式碼的後代
    commit（含 merge commit 自己）更新該目錄 CLAUDE.md 才銷帳。所以舊起點不會讓 gate 變寬鬆，
    平行分支上的 CLAUDE.md 更新也抵不掉。起點被改寫（不在目前歷史）時改從共同祖先算；
    目錄在 index 裡已經沒有程式碼就不追討；還有欠帳時 `--start-segment` 拒絕重記；
    `--segment-base` 印出起點給迴圈步驟 3、4、8，起點失效就失敗
  - 列檔案的 git 指令都經過 `gitq`（`core.quotePath=false`）：git 預設把非 ASCII 路徑加引號跳脫，
    副檔名比對不到，中文目錄等於完全不檢查（原始版本就有這個洞）
  - 行為的回歸測試是 `tests/test-gate.sh`（CI 在 ubuntu 與 macOS `/bin/bash` 3.2 各跑一次）。本機跑：

    ```bash
    /bin/bash tests/test-gate.sh              # 測 repo 裡這份 gate
    /bin/bash tests/test-gate.sh /tmp/gate.sh # 測改壞的副本（變異測試）
    ```
- `githooks/pre-commit` — 本 repo 自用（dogfood），轉呼叫上面的 gate。
  **不部署**到 `~/.claude/`；啟用方式：`git config core.hooksPath scripts/githooks`。
  注意 `core.hooksPath` 設定後 git 會完全忽略 `.git/hooks/`，與 `/dd-init` 的
  預設掛載點互斥（dd-init Phase 3 會偵測並改掛到 hooksPath 目錄）。

## 此層慣例

- 新增要部署的腳本：檔案放這裡 + 加入 `DD_SCRIPTS` 陣列 + `--force` 重新部署
- 腳本必須通過 `shellcheck -S warning` 且可在 macOS bash 3.2 執行。CI 的 ShellCheck step
  是逐檔列出的（`.github/workflows/ci.yml`），新增腳本要自己加進清單，否則 CI 根本不會檢查它。
  3.2 相容性由 CI 的 macOS job（`bash32`）用 `/bin/bash` 實跑行為測試來驗 —— 它只抓得到行為測試碰得到的程式碼，
  新腳本要有行為測試並加進那個 job，才算有驗 3.2
- 變數後面緊接全形字（`）`、`：`）一律寫 `${var}`。`$var）` 在 macOS bash 3.2 會把全形字吃掉一半：
  變數值不見、只剩亂碼。實測 `zh_TW.UTF-8`、`en_US.UTF-8` 都會，macOS 的 `C.UTF-8` 與 Linux bash 5.2
  （`C.UTF-8`）不會；不報錯，shellcheck 連 style 級都不警告（2026-09-11，gate 的 `rm ${BASE_FILE}）` 踩過）
- gate 的檢查邏輯或輸出改動時，同步檢視全域模板 §3.9 對 gate 行為的描述，以及 `skills/task-planner/SKILL.md`
  進度表規則區塊依賴的 gate 行為：`--start-segment` 印出的起點（完整 SHA，還沒有 commit 時是空樹）、有欠帳時拒絕重記、
  SKIP 記帳、只查 CLAUDE.md 有沒有一起 staged 而不查內容
- 改了 gate 或它的情境測試，要故意把 gate 改壞一行（例如拿掉 `grep -qxF "$md"` 的 `-x`）存成副本，
  用上面的第二種跑法確認會出現 ❌。全綠不代表有在檢查：2026-09-11 拿掉 `-x`、讓 staged 清單被空白拆開，這兩種改壞法
  在當時的 57 個情境下照樣全過，補到 61 個才抓到

## 與上層的關係

安裝腳本的 `create_scripts()` 負責部署（覆蓋前有差異備份）；gate 的使用情境
定義在 `templates/global/CLAUDE.md` §3.9 與根目錄 CLAUDE.md「核心工作法」。
