# scripts/ — 輔助腳本

部署到 `~/.claude/scripts/` 的輔助腳本層（部署清單由 `install-dd-pipeline.sh`
頂部的 `DD_SCRIPTS` 陣列決定），加上本 repo 自用的 git hooks。

## 關鍵檔案

- `check-claude-md.sh` — CLAUDE.md pre-commit gate（block 版）。規則：staged
  變更含程式碼檔（副檔名見腳本內 `CODE_EXT`）的目錄，必須存在 CLAUDE.md 且
  同批 staged；逃生口 `SKIP_DOC_CHECK=1`（僅供迴圈檢查點 commit）。由
  `/dd-init` 掛進各專案的 `.git/hooks/pre-commit`。
  - **SKIP 不是豁免**：段落起點記在 `git rev-parse --git-path dd-segment-base`
    （`--start-segment` 記下；忘了記時第一個 SKIP commit 自動記）。之後的正常 commit
    沿著 commit 的祖先關係結算起點以來的欠帳：改程式碼記帳，要由看得到那段程式碼的後代
    commit（含 merge commit 自己）更新該目錄 CLAUDE.md 才銷帳。所以舊起點不會讓 gate 變寬鬆，
    平行分支上的 CLAUDE.md 更新也抵不掉。起點被改寫（不在目前歷史）時改從共同祖先算；
    目錄在 index 裡已經沒有程式碼就不追討；還有欠帳時 `--start-segment` 拒絕重記；
    `--segment-base` 印出起點給迴圈步驟 3、4、8，起點失效就失敗
  - 列檔案的 git 指令都經過 `gitq`（`core.quotePath=false`）：git 預設把非 ASCII 路徑加引號跳脫，
    副檔名比對不到，中文目錄等於完全不檢查（原始版本就有這個洞）
  - 行為的回歸測試是 `.github/workflows/ci.yml` 的「gate 段落起點」step。本機照 CI 的方式跑
    （沒指定 `shell:` 的 step，GitHub Actions 用 `bash -e`；抽出來執行的就是 commit 進去的那份）：

    ```bash
    awk '/^      - name: gate 段落起點/{f=1; next} f && /^      - name:/{exit} f && /^        run: \|/{r=1; next} r' \
      .github/workflows/ci.yml | sed 's/^          //' > /tmp/gate-test.sh
    /bin/bash --noprofile --norc -e /tmp/gate-test.sh
    ```
- `githooks/pre-commit` — 本 repo 自用（dogfood），轉呼叫上面的 gate。
  **不部署**到 `~/.claude/`；啟用方式：`git config core.hooksPath scripts/githooks`。
  注意 `core.hooksPath` 設定後 git 會完全忽略 `.git/hooks/`，與 `/dd-init` 的
  預設掛載點互斥（dd-init Phase 3 會偵測並改掛到 hooksPath 目錄）。

## 此層慣例

- 新增要部署的腳本：檔案放這裡 + 加入 `DD_SCRIPTS` 陣列 + `--force` 重新部署
- 腳本必須通過 `shellcheck -S warning` 且可在 macOS bash 3.2 執行。CI 的 ShellCheck step
  是逐檔列出的（`.github/workflows/ci.yml`），新增腳本要自己加進清單，否則 CI 根本不會檢查它
- 變數後面緊接全形字（`）`、`：`）一律寫 `${var}`。`$var）` 在 macOS bash 3.2 會把全形字吃掉一半：
  變數值不見、只剩亂碼。實測 `zh_TW.UTF-8`、`en_US.UTF-8` 都會，macOS 的 `C.UTF-8` 與 Linux bash 5.2
  （`C.UTF-8`）不會；不報錯，shellcheck 連 style 級都不警告（2026-09-11，gate 的 `rm ${BASE_FILE}）` 踩過）
- gate 的檢查邏輯或輸出改動時，同步檢視全域模板 §3.9 對 gate 行為的描述，以及 `skills/task-planner/SKILL.md`
  進度表規則區塊依賴的 gate 行為：`--start-segment` 印出的起點（完整 SHA，還沒有 commit 時是空樹）、有欠帳時拒絕重記、
  SKIP 記帳、只查 CLAUDE.md 有沒有一起 staged 而不查內容
- 改了 gate 或它的 CI 情境，要故意把 gate 改壞一行（例如拿掉 `grep -qxF "$md"` 的 `-x`），用上面的本機跑法
  確認會出現 ❌。全綠不代表有在檢查：2026-09-11 拿掉 `-x`、讓 staged 清單被空白拆開，這兩種改壞法
  在當時的 57 個情境下照樣全過，補到 61 個才抓到

## 與上層的關係

安裝腳本的 `create_scripts()` 負責部署（覆蓋前有差異備份）；gate 的使用情境
定義在 `templates/global/CLAUDE.md` §3.9 與根目錄 CLAUDE.md「核心工作法」。
