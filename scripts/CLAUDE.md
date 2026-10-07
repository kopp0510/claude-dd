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
    平行分支上的 CLAUDE.md 更新也抵不掉。
    目錄在 index 裡已經沒有程式碼就不追討；還有欠帳時 `--start-segment` 拒絕重記
  - ⚠️⚠️ **「記下的起點 → 這次實際要用的起點」有三處在解析，而退化政策刻意不同**
    （2026-10-07，S4 把機制抽成 `resolve_fork_base`）：

    | 處 | 產出 | 起點不是祖先 | 連共同祖先都沒有 |
    |---|---|---|---|
    | `owed_dirs` | range（`A..B`，空樹時是裸 `head`） | 退到共同祖先 | **放行，但印警告**（只檢查 staged） |
    | `reviews_missing` | base sha | 退到共同祖先 | **放行，但印警告**（跳過 review 檢查） |
    | `--segment-base` | base sha | **硬失敗** | **硬失敗** |

    ⚠️ **`--segment-base` 有一個例外沒寫在表上**(2026-10-07 S4 的 review 抓到):
    **起點是空樹時它印出空樹 sha 並 exit 0**(`[ "$base" = "$EMPTY_TREE" ] ||` 那一段)——
    因為「段落從第一個 commit 之前開始」是合法狀態,步驟 3、4、8 拿空樹 sha 去 `git diff` 是對的。
    實跑確認:全新 repo `--start-segment` → `--segment-base` 印 `4b825dc…`、exit 0。
    ⚠️ **而「空樹起點 + `--segment-base`」目前沒有任何測試覆蓋**(既有缺口,不是 S4 引入;
    五處 `--segment-base` 斷言的 base 都是真 commit 或不存在)。

    **前兩處「往寬退」是刻意的** —— 退窄會把欠帳 / review 要求洗掉，而那正是這兩個檢查要擋的事。
    **`--segment-base` 必須硬失敗**：它的輸出要餵 `git diff`，印空字串或錯的 base 是文件點名的地雷。
    ⚠️ **所以 `resolve_fork_base` 只抽「機制」不抽「政策」** —— 共用的是
    `merge-base --is-ancestor` + fork-point + 那句警告（**S6 的 review 抓到這兩處已經漂移**：
    一處退到共同祖先、另一處直接放行）；「連共同祖先都沒有」的後續處置留在呼叫端，
    因為兩處的後果不同。`--segment-base` **刻意不用這支**：硬套進來就得加一個關掉 fallback 的
    mode 參數，那只是把同一個決策搬進函式裡（**我與 S6 的 simplifier 在 S4 規劃時就這樣預判**，
    S4 實作時確認了）。⚠️ **原本這裡寫「S6 的 reviewer 預言過」是錯的歸屬** ——
    S4 的 review 去 grep `docs/reviews/S6-{a,b}.md`，**裡面沒有**關於抽共用函式或 mode 參數的段落。
    S6 的 review 真的抓到的是「**這兩處的退化規則已經漂移**」（S6-a 的 A2 / S6-b 的 B2），那一句有據。
    ⚠️ **改這三處任何一處,先跑變異測試**:`bash tests/test-gate.sh <改壞的 gate>`。
    ⚠️⚠️ **下面記的是「哪個變異 → 哪幾個情境變紅」,刻意不記紅數**(2026-10-07 S4 的 review 要求):
    紅數同時綁「斷言集合」與「變異的具體寫法」兩個會變的東西,而文件通常只記得住數字 ——
    加任何一條碰到該路徑的斷言,紅數就過期。這與本 repo `tests/CLAUDE.md` 禁止寫「N 項」是同一類,
    **而且更糟:變異的定義本身沒被記下來**。實例:「`--segment-base` 改成軟退化」有兩種合理讀法
    (只退到共同祖先 / 再加上「沒祖先時仍印記下的 base」),review 實測各給 **3 紅與 4 紅** ——
    光看數字分不出是 gate 壞了還是變異寫法不同。

    | 變異(要寫清楚改了哪幾行) | 應該變紅的情境 |
    |---|---|
    | `--segment-base` 不再硬失敗(退到共同祖先) | 既有「起點失效時 --segment-base 要失敗」+ ⑩ 的「必須硬失敗」 |
    | `resolve_fork_base` 的 fork-point 整支拿掉 | 情境 7 的三則(`owed_dirs`)**與** ⑩ 的三則(`reviews_missing`)**各自獨立** —— 這才是「共用函式對兩個呼叫端都承重」的證據(3 + 3,不是「總共 N 紅」) |
    | 只拿掉 `resolve_fork_base` 共用那句警告 | 情境 7 與 ⑩ 的 `said` 各一則 ⚠️ **它只證明共用那句被釘住,不證明各呼叫端自己那句被釘住** |
    | 只打 `reviews_missing` 的「沒有共同祖先」那一支(改成擋 / 拿掉它的警告) | ⑪ 的兩則。⚠️ **修正前這兩個變異各 0 紅** —— ⑪ 把 `docs/reviews` 連目錄刪了,opt-in 判準不成立、那一支根本沒執行到;而 `said "找不到共同祖先"` 是被 `owed_dirs` 的訊息頂掉的 |
    ⚠️ 另外兩個**只打 `reviews_missing` 的「連共同祖先都沒有」那一支**的變異
    (改成擋 / 拿掉它的警告)原本**各 0 紅** —— `tests/test-gate.sh` 的 ⑪ 把 `docs/reviews`
    連目錄刪了,opt-in 判準不成立、那一支根本沒執行到。⑪ 補上重建目錄、並把 `said`
    換成「只有一處會印」的字串之後,兩個變異各 1 紅(詳見 `tests/CLAUDE.md` 的三個空洞斷言陷阱)。
  - `--segment-base` 印出起點給迴圈步驟 3、4、8，起點失效就失敗
  - ⚠️ **`shellcheck -S warning` clean 不代表變數有局部化**(2026-10-07 S4 的 review 指出):
    重構前 `reviews_missing` 宣告了**死的** `local range`,而真正用的 `range_base`
    是**漏宣告的全域** —— shellcheck 乾淨,一個字都沒說。
    要查局部化只能自己對 `local` 清單與函式內實際用到的變數名。
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
