# 安裝腳本補強與 README 揭露

使用者要我替這個 repo 評分，看完弱項後說「請你優化改善」。這份文件有兩段（S1 安裝腳本、S2 兩份 README）：沒有 task 工具，照全域 §4.4 用進度表記進度。

## 來源

- 使用者的話（逐字，依序）：「你認為現在這份repo 分數多少? 可以做到什麼事情? 請你嚴格仔細檢查, 弱項在哪 強項在哪」、「請你優化改善」
- 我交出的評分列了 5 個弱項：1 慢、貴；2 核心流程靠文字，沒有自動回歸；3 文件比程式重，而且只增不減；4 安裝腳本碰設定檔的那一半沒測；5 陌生人上手差。使用者沒有指定要改哪幾項
- 兩個獨立審查者當天的回報（一個讀完整支安裝腳本找沒被測到的路徑，一個只拿英文 README 當陌生人查核），以及我自己重跑的部分，整理在下面「開工前查到的事實」

## 假設

- A1 範圍是上一則評分的弱項 4（安裝腳本）與弱項 5（README）。弱項 1–3 這次不動：速度與費用要動審查者數量這類規則，得先做對照實驗；行為回歸要另開一套會花錢的測試機制；文件只增不減依使用者先前的指示要逐條判必要性、交他選
- A2 `settings.json` 與 `installed_plugins.json` 不加備份：`settings.json` 可能放 token，備份等於多留一份；而且登記每次都會改 `lastUpdated`，加了備份會每跑一次多一個備份目錄。改在 README 講明這兩個檔會被就地改
- A3 `--uninstall` 取消登記官方 plugin 的行為不改（移除前的提示本來就列了），只改 README 的說法
- A4 不改 `plugin_enabled_state` 對「頂層不是物件」回 `none` 的既有設計（兩條路徑本來就一致，註解寫明是刻意的）
- A5 測試加在既有的 `tests/test-install.sh`，不另開檔（另開要同步兩個 CI job、ShellCheck 清單、目錄結構那行）
- A6 不動 `commands/dd-init.md` 的蓋章區塊，所以不跳 `dd-loop-rev`；不發版、不 push
- A7 兩件留給使用者：兩個 agent 備份檔的上游授權（要外部查證）、README「only components with an evidenced usage record are kept」這句的措辭
- A8 計畫審查（`plan-review`）兩輪：第 1 輪不通過（1 條重大），第 2 輪通過。紀錄在本檔最後一節
- A9 測試清單由使用者在 2026-11-14 選定「照這份清單加」

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | 安裝腳本：碰設定檔與備份的路徑補測試、修掉查到的缺陷 | TODO | — | `/bin/bash tests/test-install.sh` 全過（含新加的各組；`/bin/bash` 是 macOS 的 3.2）；GNU 容器裡 T1 那段斷言修前紅、修後綠；等價表 92 例不一致數從 16 變 0；本機 ci.yml 20 個 step 全過 | |
| S2 | 兩份 README：陌生人裝之前該知道的事 | TODO | S1 | 本機 ci.yml 20 個 step 全過（數字宣稱、flag 三方對照、迴圈步數）；逐句核對表每一列都附 `grep -n` 或 `sed -n` 的實際輸出；步驟 4 照樣派審查者拿新句對原始碼與量測檔 | |

- 狀態只有 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`；同一時間最多一段 `IN_PROGRESS`
- 下一段：由上往下第一個 `TODO`，而且它依賴的段落都已 `DONE`。有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段
- 開工：`~/.claude/scripts/check-claude-md.sh --start-segment` 記起點；這段標 `IN_PROGRESS`，commits 欄先填 `<起點>..`（短 SHA；起點是空樹時填它印出的完整 SHA；回頭做 `BLOCKED` 過的段落時，欄裡原本的起點保留不改）；該段有「開工前提」就先查完，結果寫進「段落與小任務」該段底下。這些改動跟第一個小任務的 commit 一起送
- 每個小任務：照「段落與小任務」列的做，實作、驗證、commit，commit 訊息第一行結尾帶編號（例如 `（S2-1）`）。可用 `SKIP_DOC_CHECK=1` 先跳過 CLAUDE.md 檢查，gate 會記帳。測試照文件裡的測試清單加；想加清單以外的測試，先問使用者
- 小任務 commit 了不等於段落完成。小任務全部 commit 完，而且 SKIP 欠下的 CLAUDE.md 都補上了，才對整段跑步驟 3–8，範圍從表上這段的起點算。最後一個小任務用正常 commit；補 SKIP 改過的目錄的 CLAUDE.md 時，用 `git diff <起點> -- <目錄>` 看整段改了什麼，不要只看這次 staged 的（gate 只查 CLAUDE.md 有沒有一起送，不查寫了什麼）。步驟 6、7、8 的 commit 訊息第一行結尾帶段落編號（例如 `（S2）`）
- 標 `DONE`：步驟 3–8 全部跑完才標；commits 欄補上終點（標 `DONE` 之前最後一個 commit 的短 SHA，所以標 `DONE` 的 commit 自己不在範圍內），跟步驟 7、8 的 commit 一起送，7、8 都沒改檔就單獨開一個 docs commit。標到表上每段都 `DONE` 的那個 commit，刪掉根目錄 CLAUDE.md 的指路那段
- 接手：`IN_PROGRESS` 那段就是目前這段。拿「段落與小任務」的清單對 `git log --oneline <表上這段的起點>..HEAD` 裡結尾帶 `（S2-` 的 commit（不加範圍會對到別份文件的同編號 commit）。
  **前綴是「這一段自己的 ID 加一個 `-`」**，不是固定字串：插隊進來的 `S2.5` 要找的是 `（S2.5-`，
  拿 `（S2-` 去比對不到它，拿 `（S2` 又會把 S2.5 的 commit 誤算成 S2 的，還沒 commit 的小任務先做完。小任務都做完了，再看同一範圍裡有沒有帶 `（S2）` 的 commit：有，代表步驟 6 之後的步驟做到一半；沒有就從步驟 3 開始
- `BLOCKED` 用在這段要先停：外部卡住（等使用者決定、環境壞了），或使用者要先做別的事（別段、臨時修 bug）。狀態格寫 `BLOCKED` 和原因，外部卡住時停下來問使用者。先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md（不然 `--start-segment` 會拒絕）；回頭做這段時，範圍一樣從表上這段的起點算。依賴還沒完成的段落維持 `TODO`
- 做到一半冒出新工作：先問使用者，同意才加一列 `TODO` 排進該在的位置；ID 不重編，插在中間用 `S2.5`。
  **同一批要在「段落與小任務」補上這一段的小任務**（名稱、要動的檔案、驗證方式、commit 訊息）——
  只加表上那一列的話，接手的 session 照上面「接手」那條去對 commit，清單本來就是空的，
  它會判定「小任務都做完了」而直接跳到步驟 3，整段程式碼從頭到尾沒人寫。
  沒有小任務條目的段落不得標 `IN_PROGRESS`
- 每列一行，細節寫進 commit 訊息

## 段落與小任務

### 開工前查到的事實（2026-11-14，HEAD b1935bb，本機 macOS）

- 安裝測試每一次安裝都是非互動、空的沙盒 HOME：`grep -c -E 'settings\.json|\.claude\.json|installed_plugins' tests/test-install.sh` 回 0；沙盒裡沒有 marketplace，`install_plugins` 對每個 plugin 都走「Plugin 檔案不存在」
- `ask()` 用 `[ -t 0 ]` 判斷，stdin 不是終端機時一律採用預設值
- `backup_before_overwrite` 用 `cp -r` 備份。它的呼叫點裡，接著 `cp "$source" "$target"` 寫入的是 agents、`dd-*.md` 指令、scripts、output-styles、全域 CLAUDE.md 的三處；接著 `rm -rf` 再 `cp -r` 的是 skills 與命名空間指令目錄
- GNU coreutils 8.32（debian:bullseye 容器）實跑：`cp -r link.md b/` 複製出來的是連結本身，之後 `cp src link.md` 寫穿連結，再讀備份得到新內容；`cp link.md a/`（不帶 `-r`）與 `cp -L` 複製出一般檔；`cp -RL` 對懸空連結回 1。macOS：`cp -r` 與 `cp -RL` 都複製出一般檔
- 等價探針：每個案例開一個沙盒 HOME、放假的 marketplace，在子 shell 裡 source 安裝腳本後呼叫真的函式；python3 那條靠重新定義 `command_exists`。92 個案例（settings.json 15 種 × install／uninstall／`plugin_enabled_state`，installed_plugins.json 16 種 × install／uninstall，`.claude.json` 15 種 × `mcp_scope`），一致 76、不一致 16：
  - 空檔、只有空白：install 時 jq 那條印「已啟用」而檔案仍是 0 bytes，python3 那條印「更新失敗」；uninstall 時 jq 不印、python3 印「解析失敗，請手動移除」（settings.json 與 installed_plugins.json 都是）
  - 內容是 `null`：install 時 jq 那條把檔案寫成物件並印「已啟用」，python3 印更新失敗；uninstall 同上面的差別；`~/.claude.json` 是 `null` 時 `mcp_scope` 的 jq 回 `none`、python3 回 `unparseable`
  - `{"enabledPlugins":null}`、`{"plugins":null}`：install 時 jq 成功、python3 失敗；uninstall 時 jq 不印、python3 印解析失敗
  - `{"plugins":{"<key>":[null]}}`：install 時 jq 把那筆寫成只有三個欄位的物件並印「已啟用」，python3 印更新失敗
  - 頂層是陣列、字串、數字，或鍵的值是字串、陣列：兩條路徑一致（都失敗）。`plugin_enabled_state` 15 例全部一致
- `install_plugins` 每次都改 settings.json 的 `enabledPlugins` 與 installed_plugins.json 的 `lastUpdated`，兩個檔都不經過 `backup_before_overwrite`
- `create_commands` 對 `deprecated_dd` 列的舊指令檔直接 `rm`；`show_completion` 無條件印「已安裝的內建 Agents」「已啟用的 Plugin」，`--commands-only` 時這兩件事都沒做
- GitHub runner（2026-11-14 讀 actions/runner-images 的說明）：`ubuntu-latest` 對應 Ubuntu 24.04，有 jq 1.7 與 Python 3.12.3；`macos-latest` 對應 macOS 26 Arm64，有 jq 1.8.2 與 Python3 3.15.2
- 公開版停在 2026-10-30 的 9584605（當時 CI 綠燈）；本機多出的 commit 還沒在 ubuntu job 跑過

### S1 安裝腳本：碰設定檔與備份的路徑補測試、修掉查到的缺陷

**S1-1 修 symlink 備份**
- 檔案：`install-dd-pipeline.sh` 的 `backup_before_overwrite`；`tests/test-install.sh`
- 做法：目標本身是指向檔案的 symlink（`[ -L "$target" ] && [ -f "$target" ]`）時用 `cp -L` 備份它指到的內容，其餘維持 `cp -r`。只改這一種情況：會寫穿連結的 7 個呼叫點目標都是單一檔案；目錄型目標（skills、命名空間指令目錄）是 `rm -rf` 再複製，不會寫穿連結，而且目錄裡若有懸空連結，GNU `cp -RL` 會回 1、腳本有 `set -e`
- 驗證：
  - 測試（新加 T1）：沙盒 HOME 裡 `~/.claude/CLAUDE.md` 是指向另一個檔的 symlink、內容與模板不同，跑 `--force`，斷言備份目錄裡那份是一般檔、內容等於原本的內容
  - macOS 的 `cp -r` 本來就會跟著連結，T1 在本機修之前就是綠的。紅與綠都要在 GNU 上取，而且跑的要是 T1 自己那段：T1 在測試檔裡用 `# --- T1 開始`／`# --- T1 結束` 兩行註解夾住，容器裡的小腳本（放 scratchpad，不進 repo）準備假的 `node`、`git`、`claude`，再用 `sed -n` 把那一段原樣抽出來跑；修之前紅在「備份內容等於原本的內容」那個斷言，修之後綠
  - 另外試一次在有 jq、python3、git、node 的 Linux 容器裡跑整支 `tests/test-install.sh`（要拉映像檔；拉不到就照實寫「Linux 上只跑過 T1 那段，整支要等 push 後的 ubuntu job」）
- commit：`fix: 備份 symlink 目標時備份它指到的內容（S1-1）`

**S1-2 jq 與 python3 兩條路徑逐項等價**
- 檔案：`install-dd-pipeline.sh` 的 `jq_inplace`、`py_inplace`、`install_plugins`（settings 那句 python、`jq_register`、`py_register`）、`uninstall`（兩句 python）、`mcp_scope`（jq 那段）；`tests/test-install.sh`
- 每一類定案的結論（先定結論再改碼）：
  - 檔案是空的、只有空白、或頂層不是物件 → 兩條路徑都算失敗、不改檔（安裝印「更新失敗…跳過」、移除印「解析失敗，請手動移除」、`mcp_scope` 回 `unparseable`）。這條只管 `install_plugins`、`uninstall`、`mcp_scope`；`plugin_enabled_state` 對頂層不是物件回 `none` 是既有的刻意設計（假設 A4），不改
  - `enabledPlugins` 或 `plugins` 的值是 `null` → 當成沒有這個鍵：安裝照常寫入，移除不做事也不報錯
  - `plugins[<key>]` 的第一筆不是物件（例如 `[null]`）→ 兩條路徑都算失敗、不改檔
- 做法：`jq_inplace` 開頭加 `jq -e 'type == "object"'` 的檢查（空輸入時 jq -e 回 4）；`py_inplace` 載入後加同樣的型別檢查；python 四句（settings 安裝那句、`py_register` 的 `plugins`、uninstall 兩句）改成 `None` 當空物件、其他型別照舊報錯；`jq_register` 對「第一筆不是物件」報錯；`mcp_scope` 的 jq filter 頂層不是物件時報錯（落到既有的 `unparseable`）
- 驗證（新加 T2）：把探針的案例表搬進 `tests/test-install.sh`。每個案例各開一個沙盒 HOME、在子 shell 裡 source 安裝腳本後呼叫真的 `install_plugins`／`uninstall`／`plugin_enabled_state`／`mcp_scope`；python3 那條靠重新定義 `command_exists`（對 `jq` 回 1）走到。斷言：兩條路徑印出的結論行、回傳碼與改完的 JSON（時間戳換掉後）相同；另外對上面三類各挑代表案例斷言結論本身（防兩條一起錯）。先加測試、確認在現行程式碼上紅在那 16 例，再改碼轉綠
  - T2 開頭先斷言 `command -v jq` 與 `command -v python3` 都在，不在就讓測試失敗（不靜默跳過）—— 少一個時兩臂會走同一條路，等價斷言就空通過；每臂印出實際走的是哪一條
  - 測試檔有 `set -e`，而這些函式的失敗路徑會回非 0：每個呼叫都用 `|| rc=$?` 接住；接住之後 `set -e` 對 shell 錯誤的保護也沒了，所以每次呼叫另外收 stderr，斷言裡面沒有 shell 錯誤字樣（bad substitution、syntax error、command not found 這類，照 `tests/test-gate.sh` 既有的寫法）
- commit：`fix: 設定檔是空的、頂層不是物件或鍵是 null 時，jq 與 python3 兩條路徑結論一致（S1-2）`

**S1-3 沒測到的路徑補測試**（預期不改安裝腳本；測出缺陷就在這個小任務修，超出「一兩行」的先停下來問）
- 檔案：`tests/test-install.sh`
- 新加的測試：T3（plugin 登記端到端）、T4（`--check` 對 `~/.claude.json` 的三種輸出）、T5（改過的部署檔重裝時先備份再換回）、T6（全域 CLAUDE.md 三種情境）、T7（hook 相對路徑中止）。內容見下方測試清單
- 這些路徑的假 marketplace、假 `~/.claude.json` 都放在**新開的**沙盒 HOME，不動現有那個 `SANDBOX`（它的「無備份產生」斷言靠 plugin 步驟被跳過才成立）
- 驗證：被測行為沒有改，沒有「先紅」可取；改成每一組各做一次變異（把安裝腳本對應的那一行改壞），確認那一組變紅、而且紅在斷言而不是載入失敗，再還原。新加的斷言失敗時一律印出「組名＋斷言名」再 exit 1（現有的裸 `[ … ]` 在 `set -e` 下失敗不印任何字），變異實驗就以那行訊息判定紅在哪裡
- commit：`test: 安裝腳本的 plugin 登記、MCP 檢查、覆蓋前備份、全域 CLAUDE.md 與 hook 驗證補上測試（S1-3）`

**S1-4 兩個小修**
- 檔案：`install-dd-pipeline.sh` 的 `create_commands`（清舊指令檔那段）、`install_plugins`、`show_completion`；`tests/test-install.sh`
- 做法：
  - 清 `deprecated_dd` 那 5 個舊指令檔之前，在迴圈裡先 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`
  - `install_plugins` 把這次真的啟用成功的 plugin 記進一個陣列；`show_completion` 的 plugin 那段只列這些，一個都沒有時印「這次沒有啟用任何官方 Plugin，原因見上方步驟 5」；`--commands-only` 時不印 plugin 與 agent 兩段（那次兩者都沒跑）。「開發：實作+測試 → …」那行不動（CI「迴圈步數第五方」讀它）
- 驗證：新加 T8、T9，先寫、確認在現行程式碼上紅，再改
- commit：`fix: 清舊指令檔前先備份；完成訊息只報這次真的做了的（S1-4）`

**S1 的文件同步**（跟最後一個小任務或步驟 6 一起 commit）
- `tests/test-install.sh` 檔頭說明、`tests/CLAUDE.md` 的 `test-install.sh` 那一列
- 根目錄 `CLAUDE.md`（安裝腳本在根目錄，gate 會要求同批更新）：只補這次留下的坑，不改既有規則
- `DD_PIPELINE_ARCHITECTURE.md`「安裝行為保證」：可回復那條補上「目標是指向檔案的 symlink 時，備份它指到的內容」（不泛寫 symlink：目錄型目標是連結時備份的仍可能是連結，只是 `rm -rf` 只刪連結、原內容不會遺失）與「刪舊指令檔前也備份」；CI 防線表 `test-install.sh` 那一列補上新涵蓋的範圍
- `mcp_scope` 上方 none／unparseable 的定義註解（現在寫 unparseable 是「JSON 解析失敗」）改成含「頂層不是物件」；根目錄 `CLAUDE.md` 寫 `unparseable` 定義的那句（`grep -n unparseable CLAUDE.md`）一起核、一起改；`print_mcp_line` 印的「~/.claude.json 解析失敗，檔案損毀？」字樣與兩份 README 的 MCP 退化狀態表那一列（`grep -n -E '無法判定|cannot determine' README.md README.zh-TW.md`）跟著改成涵蓋「內容不是物件」
- `CHANGELOG.md` 的 `## 未發布`
- 改到的識別符各跑一次 `git grep`，核對提到它的敘述還成立（`jq_inplace`、`py_inplace` 檔頭的「原檔不動」「保留 inode / symlink」等）

### S2 兩份 README：陌生人裝之前該知道的事

**開工前提**（每一項查完把結果寫進設計文件，README 只寫查得到的）
1. 「翻譯全域模板就能換語言」那句：中文還寫死在哪些地方（`commands/dd-init.md` 蓋章區塊與 commit 訊息、`scripts/dd-init-upgrade.sh` 的比對清單、`scripts/check-claude-md.sh` 的訊息、各 `SKILL.md` 的 description）—— 逐處 grep
2. 「don't install the gate」實際怎麼做：讀 `commands/dd-init.md` Phase 3、`skills/gate-guard/hooks/CLAUDE.md`、全域模板提到巢狀 CLAUDE.md 的地方
3. `skills/self-improving-agent/hooks/hooks.json` 掛了什麼、什麼時候會插提醒
4. 全域模板 §1.1 對回應語言與 commit 語言的規定；`/dd-init` Phase 5 的 commit 訊息
5. 迴圈成本的數字：`docs/measurements/2026-10-23-reviewer-real-sessions.md`、`skills/dd-loop/SKILL.md` 引的那組，連同日期與樣本數

**S2-1 README.md 與 README.zh-TW.md 同批改**
- 檔案：`README.md`、`README.zh-TW.md`、`CHANGELOG.md`（`## 未發布`）；`DD_PIPELINE_ARCHITECTURE.md` 有同一句時一起改；`install-dd-pipeline.sh` 的 `show_help`（`--force` 那一行的說明字樣）與因此要同批更新的根目錄 `CLAUDE.md`
- 要寫的（每一項都只寫查得到的事實）：
  1. 安裝選項：`--uninstall` 那行與下面補一句——它不動全域 `CLAUDE.md`、`~/.claude/backups/`、各專案的蓋章區塊；各專案掛的 hook 也留著，但 gate 腳本被刪了，之後 commit 只印警告、不再檢查；隨 skill 一起裝的兩個全域 hook（gate-guard、self-improving-agent）跟著 skill 一起移除；有 jq 或 python3、而且檔案解析得了時，claude-md-management、skill-creator 這兩個官方 plugin 的登記會從 `settings.json` 的 `enabledPlugins` 與 `installed_plugins.json` 拿掉，即使是你在裝這個 repo 之前就自己裝的，其他 plugin 不動（解析不了時只印「請手動移除」）
  2. 不帶 `--force` 的行為：同名的 skill、agent、指令、腳本、輸出風格內容不同時也會換成 repo 版，舊的備份到 `~/.claude/backups/pre-install-<時間>/`；`--force` 多的是全域 `CLAUDE.md` 不問直接蓋。三處 `--force` 的說明字樣（`README.md` 與 `README.zh-TW.md` 的安裝選項那行、`show_help`）一起改成講這個差別；flag 名稱不動（「安裝 flag 三方對照」只比名稱）。核對表加一列「`--force` 的說明 ↔ 實際覆蓋行為」
  3. 會就地改的兩個設定檔（`~/.claude/settings.json` 的 `enabledPlugins`、`~/.claude/plugins/installed_plugins.json`），不備份
  4. 語言：全域模板被寫入之後（全新機器在第 7 步答 y；本機已有不同版本時選 o，或選 s 之後答 y；或帶 `--force`），模板要求 Claude 用繁體中文回覆；commit 訊息也用繁體中文，但專案自己另有規定時照專案；`/dd-init` 會在專案裡 commit 一筆中文訊息
  5. 全域會掛的 hook：除了已經寫的 gate-guard，補上 self-improving-agent 的那一個
  6. 迴圈的時間與費用，分三句寫，不寫成「每段要花多少」：
     - 有人工寫的程式碼時，步驟 4 至少派 3 個審查者（本 repo 部署的 `agents/code-reviewer.md` 定義的 model 是 opus）；diff 全是資料、設定、註解、文件，或已被機械檢查完全覆蓋時不派
     - 單個審查者的耗時：2026-10-23 從維護者機器約 30 天的 session 紀錄算出，311 次、中位 11.8 分、第 90 百分位 27.7 分；限制照量測檔原文寫（wall time，含模型思考與工具執行；被喚醒續跑過的審查會把中間閒置算進去）（`docs/measurements/2026-10-23-reviewer-real-sessions.md`）
     - 一次審查的費用只有 2026-10-24 一組小樣本的對照（同一份量測檔的「新做法對照」一節：主對話直接派，整發平均 269 秒、5.13 美元，含父 session 與 3–4 個審查者，每組 n=2，而且同時改了三件事），只看得出方向。寫進 README 前把那一節的原文印出來逐字核
  7. CI 跑在哪些平台（ubuntu-latest、macos-latest 的 bash 3.2）；Windows 沒有測過
  8. 前置需求補 claude-md-management 的安裝指令；「翻譯模板就能換語言」與「don't install the gate」兩句照開工前提查到的改寫
- 不用圍欄內的編號清單，不增減 flag 行（避開「迴圈步數四方一致」「安裝 flag 三方對照」的誤判）
- 驗證：沒有程式碼，不寫測試。本機重跑 ci.yml 全部 step；另做逐句核對表（新寫的每一句 ↔ 它依據的程式碼或量測檔），每一列附 `grep -n` 或 `sed -n` 的實際輸出，不只寫出處；兩份 README 的同一段並排核對意思一致
- S2 的步驟 4 不跳過：diff 雖然全是文件，但每一句都在引別處的行為（`skills/dd-loop/SKILL.md` 的判準是「有沒有引別處」），照樣派至少 3 個審查者，專門拿 README 新句對原始碼與量測檔，派工方向另外加一條「找 README 該揭露卻漏掉的安裝或移除行為」
- commit：`docs: README 補上裝之前該知道的事（移除範圍、覆蓋行為、設定檔、語言、hook、成本、平台）（S2-1）`

### 要新增的測試

全部加在既有的 `tests/test-install.sh`（CI 的 ubuntu 與 macOS 兩個 job 本來就跑它）。使用者 2026-11-14 選定「照這份清單加」。

總規則：要直接呼叫安裝腳本函式的組（T2、T7），一律在子 shell 裡先把 `HOME` 設成新的沙盒再 `source` —— 測試檔現有的那一行 `source` 是在真實 HOME 下跑的，`CLAUDE_DIR` 在 source 當下就定死，主 shell 直接呼叫函式會寫進真的 `~/.claude`。其他組走 `HOME=<沙盒> ./install-dd-pipeline.sh` 子行程。T1 那段寫成自足的（自己開沙盒、建 symlink），容器裡的小腳本只提供 PATH 上的假指令。新斷言失敗時印「組名＋斷言名」。

- T1 全域 `CLAUDE.md` 是 symlink、帶 `--force` 覆蓋後，備份裡是原本的內容
- T2 jq 與 python3 等價表：對 `install_plugins`、`uninstall`、`plugin_enabled_state`、`mcp_scope` 餵同一批假設定檔（不存在、空檔、只有空白、壞掉的 JSON、頂層是 null／陣列／字串／數字、鍵是 null／字串／陣列、正常內容、登記項格式不對），兩條路徑的結論與改完的檔案要相同；三類定案的結論各有代表案例直接斷言
- T3 plugin 登記端到端：有假 marketplace 時，`settings.json` 加上 `enabledPlugins` 且原有的其他鍵還在；`installed_plugins.json` 有登記；重跑後除了時間戳內容不變；`--uninstall --yes` 拿掉這兩處、其他鍵還在
- T4 `--check` 對 `~/.claude.json`：playwright 在根層 `mcpServers` → ✅；只在某個專案底下 → 「僅 N 個專案設定」；檔案壞掉 → 「無法判定」
- T5 部署後改掉一個 skill 檔、一個 agent、`dd-init.md`、一支腳本、`adhd.md`，重裝後五個都換回 repo 版、改過的版本都在備份目錄
- T6 全域 `CLAUDE.md`：內容相同 → 不動、不產生備份；不同、不帶 `--force`、非互動 → 保留本機版；不同、帶 `--force` → 備份後換成模板
- T7 skill 的 `hooks.json` 用相對路徑時 `validate_skill_hooks` 以 exit 1 中止（`SCRIPT_DIR` 指到假目錄、在子 shell 裡跑）
- T8 `~/.claude/commands/dd-help.md` 存在時，安裝後它被清掉、備份目錄裡有它
- T9 完成訊息：`--commands-only` 不出現「已啟用的 Plugin」「已安裝的內建 Agents」；沒有任何 plugin 啟用成功時不出現「已啟用的 Plugin」；有假 marketplace 時列出啟用成功的那幾個

測不到、照實記下的：全域 `CLAUDE.md` 的互動選單（o／k／s）。`ask` 用 `[ -t 0 ]` 判斷，管線餵 stdin 一律走預設值，要真的終端機才走得到。

## 計畫審查紀錄

- 審了 2 輪。第 1 輪派 4 個審查者，結論「不通過（1 條重大）」；第 2 輪派 3 個，結論「通過」。兩輪都沒有「需使用者決定」
- 第 1 輪採納的重大：S2 原本要在 README 寫「步驟 4 每段至少 3 個 opus 審查者」並附量測數字 —— 「每段」不對（文件類的 diff 不派），兩組數字量的也不是同一件事。已改成三句分開寫
- 第 1 輪採納的小事（都已改進上面的小任務）：S1-4 的備份呼叫少了 target 參數；S1-1 的理由寫錯；等價定案沒排除 `plugin_enabled_state`；`mcp_scope` 的定義註解與根目錄 CLAUDE.md 那句要同步；README 對 `--uninstall`、語言兩句的說法太寬；架構文件「可回復」要補刪舊指令檔；T2 要斷言 jq 與 python3 都在、接住回傳碼；本機要用 `/bin/bash` 跑；T1 要在 GNU 上取紅綠；S2 的步驟 4 照樣派審查者
- 第 1 輪的外部查證（runner 有沒有 jq 與 python3）：查了，結果在「開工前查到的事實」
- 第 1 輪駁回（每條一句）：
  - 計畫沒安排根目錄的進度指路 —— 那是 task-planner 步驟 5 要做的事，不是小任務
  - 測試清單沒經使用者選定 —— 照規定在審查結束時才問
  - 範圍與「不備份 settings.json」沒有回問 —— 兩個都列成明示假設
  - 計畫沒列步驟 3–8 與記起點 —— 進度表的規則區塊已經規定
  - 小任務 commit 會被 gate 擋 —— 規則區塊已寫可用 `SKIP_DOC_CHECK=1`
  - 草稿的節序與設計文件不同 —— 只是送審的列法
  - macOS 的 `cp -r` 會不會跟著連結要外部查證 —— 已在本機實跑
  - `jq -e` 對空輸入回 4 要依版本查證 —— 行為不同的話 T2 會先紅
  - 兩個 agent 備份檔的上游授權沒查證 —— 已列為留給使用者的事
  - README 要說明 self-improving-agent 的 hook —— 已排在 S2 的開工前提
  - 設計文件可能誤觸「迴圈步數第五方」—— 推測，而且會是紅燈不是靜默
  - ci.yml 的 step 數是 20 還是 21 —— 計法不同，`- name:` 數 lint job 是 20
- 第 2 輪採納的小事（都已改進上面的小任務）：`--force` 的三處說明字樣要跟著改；成本那幾句的出處與限制要照量測檔原文；`--uninstall` 會連兩個全域 hook 一起移除、拿掉 plugin 登記有前提；語言那句的條件要含互動選單的兩條路；「審查者的 model」只對本 repo 部署的那份成立；S2 的審查要另外找「該寫沒寫」的；python 要改的是四句不是三句；`unparseable` 的畫面字樣與兩份 README 的退化表要同步；函式呼叫要在換過 HOME 的子 shell 裡；新斷言失敗要印名字；T2 要另外擋 shell 錯誤；T1 那段要自足；架構文件不泛寫 symlink
- 第 2 輪駁回（每條一句）：
  - 92 例只在探針裡、驗收數字無法重跑 —— 計畫已寫把案例表搬進測試檔
  - jq 1.7 與 1.8 行為可能不同 —— 同第 1 輪那條，沒有新證據
