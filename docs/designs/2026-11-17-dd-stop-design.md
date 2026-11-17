# /dd-stop：用指令暫停／恢復 8 步迴圈與 CLAUDE.md gate

跑過 `/dd-init` 的專案，使用者下一個指令就能暫時關掉它帶來的兩樣東西（迴圈步驟 3–8、gate 擋 commit），再下一個指令開回來。一段（S1）：沒有 task 工具，照全域 §4.4 用進度表記進度。

## 來源

使用者的話（2026-11-17，逐字）：

- 「現在有執行過dd-init 的專案, 如果要他暫時性不要dd-init 步驟 該怎做?」（主對話回答沒有內建開關，建議在專案 CLAUDE.md 加一句）
- 「我想要透過command開關」
- 「指令名字 可以叫dd-stop 嗎？」

使用者的決定：

- U1 恢復之後，暫停期間改過程式碼的目錄**要補** CLAUDE.md（三個選項：免補／要補／恢復時再問）。題幹寫明新指令同時停掉迴圈步驟 3–8 與 gate 擋 commit
- U2 指令叫 `dd-stop`
- U3 有 `docs/reviews/` 的專案，恢復後下次記段落起點時 gate 照現行規則要 review 報告或 `S<段落>-SKIP.md` 申報；gate 不改，`off` 的輸出先告知（三個選項：維持現行規則／暫停期間的 commit 免審／`off` 時提示建 SKIP 申報）

腳本、設定鍵、標記的名字（`dd-stop.sh`、`dd.stopped`、`dd-stop:begin`／`dd-stop:end`）、聲明放 `CLAUDE.local.md`、狀態放 `git config`、不部署到 `~/.claude/` 是主對話定的。

## 動手前量到的

- `scripts/check-claude-md.sh`（起點 `925d0b8` 那一版）的 `owed_dirs` 算的是起點到 HEAD 之間所有改了程式碼而沒更新該目錄記憶檔的 commit，不分那個 commit 有沒有用 SKIP；`case "$1" in` 只有 `--start-segment`、`--segment-base` 兩支，沒有預設分支
- 拋棄式 repo 直接呼叫 repo 這份 gate（2026-11-17，macOS，`/bin/bash`；探針腳本在做這件事的 session 暫存區，沒進 repo）：
  - 沒有起點檔：一個改 `a/x.js` 不補文件的 commit 之後，staged 改 `b/`（有補 `b/CLAUDE.md`）→ rc=0、沒有輸出
  - 有起點檔（先跑 `--start-segment`）：同樣的事 → rc=1，「未同步更新：a/CLAUDE.md（段落起點之後有 commit 跳過檢查改了這裡的程式碼，CLAUDE.md 到現在還沒補）」；沒有任何 staged 時也是 rc=1；`--start-segment` rc=1
  - 接上一條，刪掉起點檔 → gate rc=0；`--start-segment` rc=0
  - 這一版 gate 收到不認得的參數（`--pause`、`--status`，沒有 staged）→ rc=0、沒有輸出
- `git grep -nE 'dd\.paused|dd\.pause|暫停迴圈|暫停 8 步' -- . ':!docs/reviews' ':!docs/measurements'` 在起點那一版是 0 筆：repo 裡沒有既有的暫停機制
- `dd-stop` 這個名字以前用過：`commands/dd-stop.md` 在 `30c8399` 加入、`c247c01`（2026-04 精簡）刪除；`install-dd-pipeline.sh` 的 `create_commands()` 把它列在 `deprecated_dd`，每次安裝先備份再刪 `~/.claude/commands/dd-stop.md`，兩份 README「同名的檔會被換掉」那一條也點名它（計畫審查第 2 輪查到）
- `wc -c CLAUDE.md` = 47014；`scripts/githooks/claude-md-max-bytes` 是 48000
- 官方文件（由 claude-code-guide subagent 讀 https://code.claude.com/docs/en/memory.md 後轉述，主對話沒有自己讀）：「For private per-project preferences that shouldn't be checked into version control, create a `CLAUDE.local.md` at the project root. It loads alongside `CLAUDE.md` and is treated the same way.」

## 開工前提的結果

- P1 **`CLAUDE.local.md` 會被全新的 session 載入**（2026-11-17，Claude Code 2.1.326，haiku，兩臂各 1 發）：`docs/measurements/2026-11-17-dd-stop/probe-local.sh`。
  有檔那一臂（檔列在 `.git/info/exclude`）回覆第一行是 `ZEBRA-7`，沒有檔的對照整則沒有 `ZEBRA-7`；兩發 `permission_denials` 都是 0、`modelUsage` 只有 haiku 一個鍵。
  只證明「會載入、照著寫了一行字」，不證明暫停聲明壓得過專案 CLAUDE.md 與全域 §3.9 的迴圈 —— 那是 S1-4 要驗的

## 設計

- D1 **狀態放 `git config --local dd.stopped true`**。只讀 `--local`（跟 `dd.docfile` 同一條規則：global 會一次關掉這台機器所有 repo 的 gate）。不改任何 hook 檔：husky、lefthook、pre-commit 套件各一種掛法，改 gate 腳本一次全蓋到
- D2 **gate（`scripts/check-claude-md.sh`）改兩處**：
  - pre-commit 那條路（沒有參數）：`dd.stopped` 是 `true` 時放行、exit 0，印「gate 暫停中（dd.stopped）；這次沒檢查，恢復後要補」。起點檔分三種：沒有起點檔 → 記下起點（跟 `SKIP_DOC_CHECK=1` 那一支一樣）；起點檔在、讀得出來 → 不動；起點檔在、內容讀不出來（`read_base` 失敗）→ 不覆寫，印警告。既有的 `SKIP_DOC_CHECK=1` 那一支不改
  - `--start-segment`：暫停中不查欠帳、不查 review 報告、不動起點檔，印「迴圈暫停中（dd.stopped）：沒有記新起點。這個工作只做步驟 1、2；恢復用 /dd-stop off」，exit 0。理由：暫停期間沒有人寫 review 報告，有 `docs/reviews/` 的專案照原本的檢查會 exit 1 要報告
  - `--segment-base` 不改。`dd.stopped` 的值不是 `true`（例如 `false`、`1`、空的）：一律當成沒暫停，不報錯
  - 檔頭的「逃生口」說明補上暫停；`scripts/CLAUDE.md`「已知的繞過路徑」加一條：暫停旗標也放行、Claude 自己就設得了它，但跟 SKIP 一樣記帳，恢復後 `owed_dirs` 照樣追
  - `skills/gate-guard` 兩處（`guard-no-verify.sh` 的 deny 理由、`hooks/CLAUDE.md`「兩邊的說法要一致」）**不改**：那句是告訴 Claude 被 gate 擋下時該用哪個逃生口，答案仍然只有 `SKIP_DOC_CHECK=1`；暫停是使用者下的開關，不是 Claude 被擋時的出路
- D3 **新腳本 `scripts/dd-stop.sh on|off|status`**（部署到 `~/.claude/scripts/`）。一律在 `git rev-parse --show-toplevel` 那一層做事：
  - `on`：①同目錄的 `check-claude-md.sh` 裡 `grep -q 'dd\.stopped'` 找不到（舊版 gate）就拒絕、exit 3，叫人重跑安裝 ②`CLAUDE.local.md` 是 symlink、或已經進版控（`git ls-files --error-unmatch`）就拒絕、exit 4，不設旗標 ③`git config --local dd.stopped true` ④`CLAUDE.local.md` 沒被 git 忽略（`git check-ignore -q` 非 0）就把 `/CLAUDE.local.md` 加進 `git rev-parse --git-path info/exclude`（不進版控、不動 `.gitignore`）⑤檔裡沒有標記段就在檔尾加上 ⑥印「8 步迴圈已暫停」。已經暫停時再跑：結果一樣、不重複加段
  - 標記段怎麼加、怎麼拿掉（`off` 之後原檔要逐位元組還原）：開頭那行註解記兩個旗標。`created=1`：這個檔是 `on` 建立的（原本不存在）；`sep=1`：原檔不是空的、而且結尾沒有換行，`on` 在標記段前面多補了一個換行。`off` 拿掉標記段的那幾行；`sep=1` 就連前面補的那個換行一起拿掉；`created=1` 而且拿掉之後檔案是 0 bytes 才刪檔。原本就存在的檔（含 0 bytes、只有空白的）一律不刪。暫停期間使用者在標記段前後自己加的字，`off` 之後原樣留著
  - `off`：①`git config --local --unset dd.stopped`（本來就沒有也算成功）②照上一條拿掉標記段。檔是 symlink 或進了版控時不動它：印「旗標已清除，但聲明還在 CLAUDE.local.md，手動處理後重跑」、exit 5，**不印「已恢復」** ③先印一行「以下是 gate 的欠帳檢查（這次沒有 commit 被擋）：」，再不帶參數跑一次同目錄的 gate，把它印的原樣印出來（它的 exit code 不當成 `off` 的失敗）。起點檔在而內容讀不出來（同目錄 gate 的 `--segment-base` 失敗、而且起點檔存在）時印「起點檔壞了，暫停期間的欠帳算不出來」；gate 沒有輸出、起點也沒壞才印「沒有要補的」④專案有 `docs/reviews/` 目錄時多印一行：「下次 `--start-segment` 之前，起點以來的 commit 要有 review 報告或 `S<段落>-SKIP.md` 申報」⑤印「8 步迴圈已恢復：從現在起照專案 CLAUDE.md 與全域 §3.9 跑完整 8 步。這個對話讀過的暫停聲明作廢；暫停期間開的、現在還開著的其他對話要重開」。`info/exclude` 加的那一行留著
  - `status`：印旗標（暫停中／沒有暫停）與標記段在不在；兩者不一致時照實各印一行，不自己修
  - 實作時跟上面幾條不一樣的地方（2026-11-17 S1-2，都有測試）：①`off` 遇到 symlink 或已進版控的檔，只有檔裡真的有標記段才 exit 5；沒有標記段就沒有聲明留著，照常恢復
    ②`CLAUDE.local.md` 存在而不是一般檔（例如目錄）也算 exit 4 ③標記段沒有結尾行時 `off` 不動檔、exit 5 ④`sep=1` 而標記段後面有使用者自己加的字時，`off` 留著補的那個換行（拿掉會把兩行黏在一起；這時本來就不可能逐位元組還原）
    ⑤「起點檔壞了」不看 `--segment-base` 的 exit code（它在起點不是祖先時也失敗、那時欠帳算得出來），改成直接看起點檔第一行是不是 commit 或 tree，跟 gate 的 `read_base` 同一個判法
    ⑥同目錄的 gate 不在或不能執行時 `off` 照樣恢復，欠帳那一段印「欠帳沒有查」⑦`off` 跑 gate 時把 `SKIP_DOC_CHECK` 清成空的 ⑧參數多於一個也是 exit 2
  - 沒有參數或不認得的參數：印用法、exit 2。不在 git repo：exit 1
  - 標記段（`<日期>` 是 `on` 當天）：

    ```
    <!-- dd-stop:begin created=<0|1> sep=<0|1> 由 /dd-stop on 寫入，/dd-stop off 會移除 -->
    **8 步開發迴圈暫停中**（<YYYY-MM-DD> 起，使用者用 `/dd-stop on` 開的）。恢復之前，這個專案只做步驟 1、2（實作與測試跑綠、commit）：
    不跑步驟 3–8，不呼叫 `dd-loop`，不跑 `--start-segment`，不開新段落、不動設計文件的進度表，改程式碼時不必同批更新 CLAUDE.md。commit 照平常下，不要加 `SKIP_DOC_CHECK=1`、不要用 `--no-verify`（gate 暫停中自己會放行並記帳，恢復後再補）。
    這一句優先於本專案 CLAUDE.md 的「開發流程」「CLAUDE.md 維護」、設計文件進度表的開工與標 DONE 規則、全域 CLAUDE.md §3.9 的迴圈；其他規則照舊（動手前的佐證、測試要跑綠、破壞性操作先確認）。恢復：`/dd-stop off`；看到 `dd-stop.sh off` 印出「8 步迴圈已恢復」之後，這一段作廢。
    <!-- dd-stop:end -->
    ```
- D4 **新指令 `commands/dd-stop.md`**（薄的一層，檢查都在腳本裡）：
  1. `~/.claude/scripts/dd-stop.sh` 不存在或不能執行 → 告訴使用者到 claude-dd repo 跑 `./install-dd-pipeline.sh --force`，停下
  2. 參數只收 `on`、`off`、`status`；沒給就跑 `status` 並說明三個用法
  3. 跑腳本，輸出整份原樣給使用者；exit 非 0 → 照它印的原因回報，停下
  4. `on` 之後：輸出裡要有「8 步迴圈已暫停」這串字才算成功（不只看 exit code）；告訴使用者這個對話從現在起照暫停聲明做、其他已經開著的對話要重開才讀得到
  5. `off` 之後：輸出裡要有「8 步迴圈已恢復」才算成功。接著：①這個對話從現在起照專案 CLAUDE.md 與全域 §3.9 跑完整 8 步，context 裡先前讀到的暫停聲明作廢 ②告訴使用者：暫停期間開的、現在還開著的其他對話要重開 ③把 gate 列出要補的目錄講給使用者（那段輸出裡的「commit 已擋下」是欠帳檢查的字樣，這次沒有 commit），問要不要現在補 ④輸出裡有 review 報告那一行就照樣轉述
  - 內文不出現 `$<數字>`；指令裡的 `cd` 一律 `(cd … && …)`
- D5 **模型層為什麼放 `CLAUDE.local.md`**：`.git/config` 不在 context 裡，Claude 看不到旗標；聲明要放在每個 session 一開始就載入、而且跟旗標一樣只在這個 clone 生效的地方。寫進專案 `CLAUDE.md` 會進版控，協作者看到「暫停中」而他們的 gate 照擋
- D6 **恢復之後**：欠帳由既有的 `owed_dirs` 追討（U1），review 報告照現行規則（U3），gate 不加新邏輯
- D7 **不做的**：不改全域模板 §3.9（每個 repo 每個 session 都要付那幾行的成本）；不改 `commands/dd-init.md`（蓋章區塊不動，`dd-loop-rev` 不跳）；不改 `skills/task-planner/SKILL.md` 的規則區塊（已經照抄進各專案設計文件的那份不會跟著變；改由暫停聲明寫明優先於進度表的開工與標 DONE 規則。這是照 `scripts/CLAUDE.md`「此層慣例」檢視 task-planner 依賴的 gate 行為之後的結論：暫停中 `--start-segment` 不印「段落起點：」，照規則區塊開工的人拿不到起點，聲明叫它不要開新段落）；不部署到 `~/.claude/`（那是專案外的檔，由使用者自己跑 `./install-dd-pipeline.sh --force`；根目錄 CLAUDE.md「新增 Script 步驟」「新增 Skill 步驟」的部署那一步因此留給使用者）
- D8 **已知限制**（寫進 `scripts/CLAUDE.md` 與 README）：①`git config --local` 在同一個 repo 的所有 worktree 共用，`CLAUDE.local.md` 每個 worktree 各一份 —— 在 A worktree 暫停，B worktree 的 gate 也停、但 B 的 Claude 讀不到聲明 ②暫停前就開著的其他對話要重開才讀得到聲明 ③暫停期間開的、恢復時還開著的其他對話，context 裡還留著暫停聲明，要重開才會恢復跑迴圈 ④使用者自己在終端機 commit 一樣被放行 ⑤`--commands-only` 更新的人拿到新指令、沒有新腳本：指令第 1 步會停下 ⑥對話中途 `CLAUDE.local.md` 被寫入或刪掉，已開的對話會不會重讀，沒有查；設計不依賴它 ⑦`dd-stop` 以前是另一個指令的名字（2026-04 刪除）：這次把它從安裝腳本的退場清單拿掉，手上還留著舊 `dd-stop.md` 的機器重跑安裝時會被新版覆蓋（先備份）

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | `/dd-stop` 指令、腳本與 gate 的暫停旗標 | IN_PROGRESS | — | `/bin/bash tests/test-gate.sh` 與 `/bin/bash tests/test-dd-stop.sh` 全綠、變異對照如表；`tests/test-install.sh` 全綠；`shellcheck -S warning` 過；CI lint job 本機逐 step 全過；S1-4 兩組的結果照實寫；根目錄 CLAUDE.md 不超過 48000 bytes | 925d0b8.. |

- 狀態只有 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`；同一時間最多一段 `IN_PROGRESS`
- 下一段：由上往下第一個 `TODO`，而且它依賴的段落都已 `DONE`。有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段
- 開工：`~/.claude/scripts/check-claude-md.sh --start-segment` 記起點；這段標 `IN_PROGRESS`，commits 欄先填 `<起點>..`（短 SHA；起點是空樹時填它印出的完整 SHA；回頭做 `BLOCKED` 過的段落時，欄裡原本的起點保留不改）；該段有「開工前提」就先查完，結果寫進「段落與小任務」該段底下。這些改動跟第一個小任務的 commit 一起送
- 每個小任務：照「段落與小任務」列的做，實作、驗證、commit，commit 訊息第一行結尾帶編號（例如 `（S2-1）`）。可用 `SKIP_DOC_CHECK=1` 先跳過 CLAUDE.md 檢查，gate 會記帳。測試照文件裡的測試清單加；想加清單以外的測試，先問使用者
- 小任務 commit 了不等於段落完成。小任務全部 commit 完，而且 SKIP 欠下的 CLAUDE.md 都補上了，才對整段跑步驟 3–8，範圍從表上這段的起點算。最後一個小任務用正常 commit；補 SKIP 改過的目錄的 CLAUDE.md 時，用 `git diff <起點> -- <目錄>` 看整段改了什麼，不要只看這次 staged 的（gate 只查 CLAUDE.md 有沒有一起送，不查寫了什麼）。步驟 6、7、8 的 commit 訊息第一行結尾帶段落編號（例如 `（S2）`）
- 標 `DONE`：步驟 3–8 全部跑完才標；commits 欄補上終點（標 `DONE` 之前最後一個 commit 的短 SHA，所以標 `DONE` 的 commit 自己不在範圍內），跟步驟 7、8 的 commit 一起送，7、8 都沒改檔就單獨開一個 docs commit。標到表上每段都 `DONE` 的那個 commit，刪掉根目錄 CLAUDE.md 的指路那段
- 接手：`IN_PROGRESS` 那段就是目前這段。拿「段落與小任務」的清單對 `git log --oneline <表上這段的起點>..HEAD` 裡結尾帶 `（S2-` 的 commit（不加範圍會對到別份文件的同編號 commit）。
  **前綴是「這一段自己的 ID 加一個 `-`」**，不是固定字串：插隊進來的 `S2.5` 要找的是 `（S2.5-`，
  拿 `（S2-` 去比對不到它，拿 `（S2` 又會把 S2.5 的 commit 誤算成 S2 的，還沒 commit 的小任務先做完。小任務都做完了，再看同一範圍裡有沒有帶 `（S2）` 的 commit：有，代表步驟 6 之後的步驟做到一半；沒有就從步驟 3 開始
- `BLOCKED` 用在這段要先停：外部卡住（等使用者決定、環境壞了），或使用者要先做別的事（別段、臨時修 bug）。狀態格寫 `BLOCKED` 和原因，外部卡住時停下來問使用者。先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md（不然 `--start-segment` 會拒絕）；專案有 `docs/reviews/` 目錄時，先停還要 commit 一份申報檔 `S<段落>-BLOCKED.md`（跟進度表標 `BLOCKED` 的改動、補的 CLAUDE.md 放同一個 commit）—— 這段還沒有 review 報告，少了它 `--start-segment` 一樣會拒絕。申報檔寫明停在哪個小任務、為什麼停、先停之前已經 commit 的範圍；放的位置照專案 `docs/reviews/CLAUDE.md` 的規定，專案有好幾張進度表時放這張表自己的子目錄、不要放進別張表的，寫之前先 `ls`（要的是新增的檔，蓋掉或改既有的不算）；同一段第二次先停另建 `S<段落>-BLOCKED-2.md`。回頭做這段時，範圍一樣從表上這段的起點算，步驟 4 照跑、報告照落地（`-BLOCKED.md` 只是申報，不算報告）。依賴還沒完成的段落維持 `TODO`
- 做到一半冒出新工作：先問使用者，同意才加一列 `TODO` 排進該在的位置；ID 不重編，插在中間用 `S2.5`。
  **同一批要在「段落與小任務」補上這一段的小任務**（名稱、要動的檔案、驗證方式、commit 訊息）——
  只加表上那一列的話，接手的 session 照上面「接手」那條去對 commit，清單本來就是空的，
  它會判定「小任務都做完了」而直接跳到步驟 3，整段程式碼從頭到尾沒人寫。
  沒有小任務條目的段落不得標 `IN_PROGRESS`
- 每列一行，細節寫進 commit 訊息

（本 repo 記起點用 repo 這份 `scripts/check-claude-md.sh --start-segment`，見根目錄 CLAUDE.md「開發本 repo」。）

## 段落與小任務

### S1 `/dd-stop` 指令、腳本與 gate 的暫停旗標

- S1-1 gate 認 `dd.stopped`。動：`scripts/check-claude-md.sh`（兩處加檔頭說明）、`tests/test-gate.sh`（加 ⑰，放在 ⑯ 之前，`exit $fail` 仍是最後一行）、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、`DD_PIPELINE_ARCHITECTURE.md` CI 防線表「gate 情境測試」那一列；本檔、根目錄 CLAUDE.md 的指路句、`docs/measurements/2026-11-17-dd-stop/` 的 P1 探針。
  ⑰ 的情境：暫停中改碼不補文件的 commit 放行並印「gate 暫停中」；沒有起點檔時自動記起點；起點檔內容壞掉時不覆寫、印警告、起點檔逐位元組不變；`--start-segment` 暫停中 exit 0、印「迴圈暫停中」、起點檔內容不變、有 `docs/reviews/` 而沒有報告時也不擋；`git config --local --unset` 之後下一個 commit 被擋、訊息列出暫停期間改的目錄；`dd.stopped=false` 不算暫停；只設 global 的 `dd.stopped` 不算暫停。
  變異對照（各記「哪個變異 → 哪幾則紅」；每個變異先確認 `grep -c '^✅ ⑰'` 不是 0、固定版與變異版的判定行數一樣）：拿掉 pre-commit 那一支、拿掉 `--start-segment` 那一支、`--local` 改 `--get`、暫停那一支不記起點、暫停那一支遇到壞起點檔照樣覆寫。
  commit 訊息結尾 `（S1-1）`
- S1-2 `scripts/dd-stop.sh` 與 `tests/test-dd-stop.sh`。動：這兩個新檔、`install-dd-pipeline.sh` 的 `DD_SCRIPTS`、`.github/workflows/ci.yml`（ShellCheck 清單加兩個檔；lint job 與 bash32 job 各加一個跑 `tests/test-dd-stop.sh` 的 step）、`DD_PIPELINE_ARCHITECTURE.md`（「12 支腳本」→ 14、CI 防線表加一列）、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、根目錄 CLAUDE.md「目錄結構」`tests/` 那行。
  測試用拋棄式 repo 配 repo 裡真的 gate：`on` 之後旗標在、標記段恰好一份、`info/exclude` 有那一行、`git status --porcelain` 看不到 `CLAUDE.local.md`；`on` 跑兩次標記段仍一份；`on` 再 `off` 之後 `CLAUDE.local.md` 與原本逐位元組相同（`cmp`），各一則：原本不存在（`off` 後檔不存在）、0 bytes、只有空白、有內容且結尾有換行、有內容且結尾沒有換行；暫停期間在標記段後面加一行字，`off` 之後那行還在、標記段沒了；`off` 之後旗標沒了；symlink 與已進版控：`on` 各拒絕、旗標沒設、連結目標沒被寫，`off` 各回非 0、不印「已恢復」；舊版 gate（沒有 `dd.stopped` 字樣的副本）拒絕；`off` 印出 gate 的欠帳清單與前面那一行說明；起點檔壞掉時 `off` 印「算不出來」而不印「沒有要補的」；有 `docs/reviews/` 時 `off` 多印 review 那一行、沒有時不印；`status` 四種組合；repo 路徑含空白與中文。第一個參數可換成改壞的 `dd-stop.sh` 做變異對照（第二個換 gate）。
  commit 訊息結尾 `（S1-2）`
- S1-3 `commands/dd-stop.md` 與同批文件。動：新檔、`install-dd-pipeline.sh`（`DD_COMMANDS`、`deprecated_dd` 拿掉 `dd-stop`、印「N 個 DD Command（dd-init：…）」的那句、`show_completion()` 的後續步驟）、`tests/test-install.sh`（比照 `dd-init.md` 加部署斷言）、根目錄 CLAUDE.md（「1 個 dd-* 指令（dd-init…」→ 2 個）、兩份 README（指令一覽、安裝步驟第 6 步與不編號附加步驟那句、「同名的檔會被換掉」那一條拿掉 `dd-stop.md`、「CLAUDE.md 維護規則」加一條暫停、「為什麼要巢狀」底下不掛 gate 那段、「核心工作法」迴圈說明段講 `--start-segment` 的那一句補上暫停時不記起點）、`DD_PIPELINE_ARCHITECTURE.md`（「核心工作法」講 gate 的段落；「部署清單」點名列 dd-init 的那一段加上 `/dd-stop` 與 `dd-stop.sh`、加入日期 2026-11-17、實證來源寫 S1-4 的結果）、`CHANGELOG.md` 新開 `## 未發布`（`## 1.6.15` 不動；註明 `dd-stop` 這個名字以前是退場的舊指令）、`skills/dd-loop/SKILL.md`「段落起點」加一句（`--start-segment` 印「迴圈暫停中」時不算記好起點、照它印的做）。
  commit 訊息結尾 `（S1-3）`
- S1-4 行為驗證。環境：不部署到真的 `~/.claude/`。
  ①指令乾跑：派 subagent（general-purpose）在 scratchpad 的拋棄式 repo 照 `commands/dd-stop.md` 做；scratchpad 另建一個假的 home 目錄、把 repo 版的 `scripts/` 兩支腳本放進它的 `.claude/scripts/`，派工 prompt 寫明「文中的 `~/.claude/scripts/` 一律換成這個路徑」（乾跑才有的替換：真的 `~/.claude/` 路徑沒有跑過）。拋棄式 repo 不掛 pre-commit（指令本身不 commit）。`on`、`off`、`status`、腳本不存在（指到空目錄）、腳本 exit 非 0（symlink 的 `CLAUDE.local.md`）各一臂；判定看指令核對的檔案與 git config 狀態，不看回報。另一臂照改過的 `skills/dd-loop/SKILL.md`「段落起點」那一節，在暫停中的拋棄式 repo 跑一次，逐條引原句回報哪裡卡住。
  ②模型層：全新的 `claude -p`，拋棄式專案有現行蓋章區塊的 `CLAUDE.md`，pre-commit 用絕對路徑呼叫 repo 這份 gate（不經過 `~/.claude/scripts/`）；三臂各 2 發：暫停臂（事先由腳本跑 repo 版 `dd-stop.sh on`）、對照臂（沒有暫停）、恢復臂（事先 `on`，prompt 開頭多一句先執行 repo 版 `dd-stop.sh off`）。模型、旗標、prompt 原文、回合或費用上限、每一臂的判定寫死在 `docs/measurements/2026-11-17-dd-stop/` 的腳本與 `CLAUDE.md` 裡，commit 之後才跑。判定的骨架：每一發都符合才算那一臂通過；每一發的 `permission_denials` 都是 0（`--allowedTools` 要放行 Skill、Agent、Bash）、advisor 用 `--settings` 關掉；暫停臂 —— 沒有 `Skill dd-loop`、沒有 `--start-segment`、沒有派 `code-simplifier`／`code-reviewer`，commit 成功而且指令沒帶 `SKIP_DOC_CHECK`、`--no-verify`；對照臂 —— 出現 `--start-segment` 或 `Skill dd-loop` 至少一樣（到上限還沒出現 = 這個實驗分不出差別，不算通過）；恢復臂 —— `off` 之後出現 `--start-segment` 或 `Skill dd-loop` 至少一樣。prompt 是一個明確的功能段落（不是一行小改動），免得被判成簡單級而兩臂都不跑迴圈。
  headless session 載入的是部署版的 `dd-loop`（這次不部署），所以模型層驗不到 `skills/dd-loop/SKILL.md` 新加的那一句。
  任何一臂沒通過 → 照實寫「模型層沒驗證通過（哪一臂）」，停下來問使用者，不改判定。
  commit 訊息結尾 `（S1-4）`

## 計畫審查紀錄

每輪派 1 個裁決者（opus）與 4 個審查者（haiku），讀檔檢查 8 人次都過。

- 第 1 輪：不通過（1 條重大）。`off` 沒有告訴模型恢復、暫停期間開的對話 context 裡還留著暫停聲明。改法：`off` 的輸出與指令第 5 步明講恢復與哪些對話要重開、D8 加 ③、模型層加恢復臂。另採納 10 條小事（`off` 的 gate 輸出前加說明、逐位元組還原、⑰ 的位置、部署清單、README 迴圈說明段、CI 防線表、每一發都符合、驗證環境、整個 lint job、壞起點檔不覆寫）
- 第 2 輪：通過。採納 11 條小事，都已改進本檔（`deprecated_dd`、task-planner 的檢視結果、dd-loop 那一節的乾跑臂、模型層的旗標與 `permission_denials`、上限寫死、變異先確認 ⑰ 有跑到、壞起點檔時 `off` 不說「沒有要補的」、prompt 寫成功能段落、`off` 拿不掉標記段時不印「已恢復」、gate 檔頭與繞過清單與 gate-guard 的決定、乾跑 repo 不掛 hook）
- 第 2 輪的「需要外部查證」（小事）：改安裝腳本印「N 個 DD Command」那一句會不會讓 CI「迴圈步數第五方」變紅 —— 驗收要在本機逐 step 跑 lint job，那時會看到

駁回的批評（每條一句）：

- 輪1-R1-2：說 `on` 不檢查 repo 有沒有掛 gate。全域 §3.9 的迴圈對每個 repo 都生效，沒掛 gate 的 repo 暫停只是停掉模型層
- 輪1-R4-2：說暫停期間沒 commit 的改動不在追討範圍。恢復後 commit 時走正常的 staged 檢查
- 輪1-R4-7：說 `info/exclude` 是所有 worktree 共用的。效果只是其他 worktree 也忽略 `CLAUDE.local.md`
- 輪1-R4-5、R4-6、R2-6、R3-7、R3-8、R1-7：說 `CLAUDE.local.md` 會不會載入、壓不壓得過 §3.9、2 發分不分得出差別沒有根據。計畫的 P1 與 S1-4 已經安排實測，沒過就停下來問
- 輪2-R3-4：說 ⑰ 留下的狀態會影響 ⑯。⑯ 自己開一個乾淨 repo，`dd.stopped` 是 `--local`，帶不過去
- 輪2-R4-4：說別的 session 跑 `off` 之後，還開著的對話會繼續跳過。同輪1-R1-1，已列成已知限制並提醒重開
- 輪2-R4-8、R4-9：對話中途 `CLAUDE.local.md` 變動會不會重讀。同輪1-R1-6，設計不依賴它
- 輪2-R4-10：說 `claude-fable-5-2` 這個模型 ID 可能不存在。本 repo 用它實測過
