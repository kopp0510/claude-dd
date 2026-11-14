# tests/ — CI 跑的情境測試

放「不屬於任何一支部署腳本、但 CI 要跑」的測試。**不部署**：不在 `scripts/` 底下，
所以 `DD_SCRIPTS ↔ scripts/*.sh` 那道一致性檢查不會把它當成要部署的腳本。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `test-install.sh` | 安裝腳本的端到端測試：拋棄式 HOME 裡非互動安裝，驗部署內容等於部署清單、重跑冪等、`--force` 內容相同不重寫、`--update`、`--commands-only`（另在乾淨 HOME 驗它不部署 output style）、`--uninstall` 非互動預設取消、`--uninstall --yes` 移除 `adhd.md` 但不動使用者自己的風格檔、`--check` 不寫入、`--help` 可執行。跑完清掉暫存目錄。**2026-11-14 補上 T1–T9**（每組開自己的沙盒 HOME，斷言失敗時印「組名＋斷言名」）：T1 全域 CLAUDE.md 是 symlink 時 `--force` 的備份是它指到的內容；T2 jq 與 python3 等價表（`install_plugins`、`uninstall`、`plugin_enabled_state`、`mcp_scope`、`autocompact_state` × 假設定檔，兩臂的輸出、回傳碼、改完的 JSON 要相同，定案的結論另外直接斷言；案例數它自己會印）；T3 plugin 登記端到端（假 marketplace）；T4 `--check` 對 `~/.claude.json` 的輸出；T5 改過的部署檔重裝時先備份再換回；T6 全域 CLAUDE.md 三種情境；T7 hook 相對路徑中止；T8 舊指令檔刪除前備份；T9 完成訊息只報真的做了的（另含：登記失敗時 `settings.json` 沒被寫成啟用；沒有 jq 與 python3 時 uninstall 的手動清理提示兩個檔都講到）。**2026-11-15 補上 T10**：環境檢查（步驟 1，`--check` 也跑）最後一行「自動壓縮視窗」—— 真的跑 `--check`，最上層有設、最上層的值不是有效值、只設在個別模型、都沒設、沒有檔、檔案壞掉、環境變數是有效值、環境變數不是有效值（`5`、`0400000`、一長串數字）各比對那一行獨有的一段字，同時斷言 ffmpeg 那一行是 `├──`、輸出沒有 shell 錯誤；另用 `nojson.sh` 遮掉 jq 與 python3 驗 `unknown`／`none`。**測不到**：全域 CLAUDE.md 的互動選單（`ask` 用 `[ -t 0 ]` 判斷，管線餵 stdin 一律走預設值） |
| `test-gate.sh` | CLAUDE.md gate（`scripts/check-claude-md.sh`）的情境測試：段落起點、SKIP 欠帳、merge、改寫過的歷史、中文與含空白的路徑。在拋棄式 repo 裡掛上 gate 實際 commit，逐案印 ✅／❌，有 ❌ 就 exit 1。第一個參數可以換成別的 gate 路徑，做「改壞一行、確認會出現 ❌」的變異測試。**2026-10-07（S6）新增 review 報告強制的情境**（導入路徑被擋 / SKIP 申報放行 / 沒報告擋下 / 兩份報告放行 / `CLAUDE.md` 不算 / **只改既有報告不算新增** / **amend 過的歷史仍照擋** / `SUMMARY.md` 不算 / 刪目錄退出）。**2026-10-07（S4）又加了「三處退化政策各自的行為」**（起點不是祖先時:`--segment-base` 硬失敗、`reviews_missing` 退到共同祖先照樣擋;連共同祖先都沒有時:兩處放行**但必須印出警告**）—— ⚠️ 這幾則有**三個**容易寫成空洞斷言的地方:**①`docs/reviews/` 是 opt-in、判準是工作目錄裡有沒有那個目錄**,切分支或 `rm -rf docs` 之後沒重建就整個檢查不啟用,測試會「為了錯的理由而通過」(⑩第一版、⑪前一版都踩過 —— ⑪那次實測:把 `reviews_missing` 的「沒有共同祖先」那一支改成擋、或拿掉它的警告,**全綠零紅**);**②`--start-segment` 通過時會寫入新起點**,所以 `base_is` 只能放在它之前;**③兩處共用 `resolve_fork_base` 之後,警告句的共同部分(「改從共同祖先」「找不到共同祖先」)誰印都算過關** —— `said` 一律挑「只有一處會印的字串」(`review 檢查改從共同祖先` / `只檢查 staged` / `跳過 review 報告檢查`)。**2026-10-16 又加了 ⑫「記憶檔名可設」**（`git config dd.docfile GEMINI.md`：只有 GEMINI.md 也過關 / CLAUDE.md 不算 / 欠帳認 GEMINI.md / 非法值拒絕 / unset 回到預設）—— 它自己開一個乾淨 repo，不碰 ⑩⑪ 收尾的狀態。⚠️ **這一段有一個「同批 staged 蓋掉銷帳」的陷阱**：測「欠帳銷掉了」時若只寫「補上該目錄的記憶檔 → 放行」，放行的理由會是**這次一起 staged**（`[ -f "$md" ] && grep -qxF "$md" && continue` 的短路）—— `owed_dirs` 照樣跑、也確實把該目錄算成欠帳，**只是結果被那條短路蓋掉**，所以把 awk 那行改回寫死 `CLAUDE.md` 時**全綠零紅**。要釘住銷帳必須**再加一個完全不碰該目錄的 commit**。**2026-10-19 加了「已知的三條繞過路徑」的特性測試**(放在 ⑧ 與 ⑨ 之間;說明以「繞過①」「繞過②」「繞過③」開頭,對應 `scripts/CLAUDE.md` 那三句,各配一則對照;區塊開頭另有一則「正常流程」:報告 commit 之後還有步驟 6 的 commit,開下一段要放行)—— 變紅時怎麼判、變異實測,都記在 `scripts/CLAUDE.md` 那條底下(⚠️ ②跟正常流程是同一個形狀,②變紅多半是回歸)。⚠️ **寫這類對照時,放行那則不能用 `--start-segment` 之後的第一個 commit**:那時 HEAD 就是起點、範圍是空的,`reviews_missing` 裡的 `[ "$base" = "$head_sha" ] && return 1` 直接放行,斷言什麼都釘不住(`docs/reviews/2026-10-18-pstack-gaps/S1-b.md` 的 B1,實測)。⚠️ **不要在這裡寫「N 項」** —— 本檔寫過「61 → 73」，收 review 時又加了三個情境就過期了；項數自己跑 `bash tests/test-gate.sh | grep -c "^✅"`。 |
| `test-dd-init-upgrade.sh` | `/dd-init` 升級分類腳本（`scripts/dd-init-upgrade.sh`）的情境測試：fixture 從 `v1.6.12`、`v1.6.4`、`6a9addd`、`v1.1.0` 用 `git show <tag>:` 抽各版蓋章區塊，插入自編的 `LOCAL*` 在地行（步驟 1 之前、步驟 4、5 的圍欄、8 底下、驗證不過之後、一行 `---`、維護小節、區塊外小節），斷言在地行各剩一次且落在原錨點之間、該版有而現行區塊沒有的範本行在輸出裡 0 次、標記與 `## 開發流程` 各一個；另有純範本、rental-management 型（在地 `###`）、在地 `##` 截斷、後段在地內容、`--plan` 各節與行號、React 圍欄改一行、exit 2–6（exit 6 另核檔案狀態：symlink 指到的外部檔不變、symlink 還在、懸空 symlink 指的檔沒被建立、既有一般檔不被蓋掉）。**斷言不讀腳本的清單**（獨立於被測物）。**要 git 歷史**：兩個 CI job 的 checkout 都設了 `fetch-depth: 0`。另斷言輸出的標記是現行區塊那一行（rev 13）、現行區塊自己跑一次輸出不變、rental 型升級過再升一次輸出不變、步驟 1 之前的在地行（LOCALP）留在標記與步驟 1 之間、專案改寫過步驟 5 那一行時底下的指令仍列在「步驟 5 既有的驗證指令行」。變異對照（2026-10-30 S2 審查修正後重跑，記「哪個變異 → 哪幾則紅」；空殼那一則 2026-11-14 S1-1 加了 exit 6 之後重跑）：空殼腳本（只 `exit 0`）→ 40 ❌，紅在「沒有產生輸出檔」、各斷言的錯值與四則 exit 6 的 exit 碼（它不寫檔，所以 exit 6 的檔案狀態斷言照樣綠）；拿掉 exit 6 那段檢查 → 只有 exit 6 那七則紅（四則 exit 碼、外部檔被改、懸空 symlink 指的檔被建立、既有一般檔被蓋掉；「symlink 還在」照樣綠）；圍欄一律算範本（`tpl[nu] = 1`）→ 9 ❌，四版的 LOCAL5 圍欄內容不見、React 圍欄沒列；終點遇同級標題就停（拿掉 `!inL(trim(F[i]))`）→ 10 ❌，四版 LOCALV 落到 `## CLAUDE.md 維護` 之後、四版各留 3–4 行舊範本、純範本與現行區塊不等於預期；單行判範本不看降級標題（`inL(t)` 改回 `(t in L)`）→ 1 ❌，rental 型第二次升級輸出改變；改寫過的步驟行不更新錨點 → 2 ❌，LOCALS5 沒列進步驟 5 那一節、落在新的步驟 5 之前；拿掉「步驟 1 之前」的插入 → 8 ❌，四版 LOCALP 不見。⚠️ 寫 `count_is` 時挑**只出現在那一行**的字串：`LOCAL5` 也出現在圍欄裡的 curl 那行，第一版因此每版都報「出現 2 次」 |

## 此層約束

- **CI 在兩種 bash 上各跑一次**：ubuntu（bash 5）與 macOS 的 `/bin/bash` 3.2（`.github/workflows/ci.yml`）。
  gate 與它的 hook 都靠 shebang `#!/bin/bash` 執行，所以在 macOS 上測到的就是使用者機器上的那個 bash
- **`test-gate.sh` 在 gate 的輸出裡看到 shell 錯誤就判失敗**（`bad substitution`、`syntax error`、`command not found`、
  `invalid option`、`unbound variable`，以及 bash 報腳本錯誤固定的「`: line N: `」前綴）：bash 3.2 不支援的寫法常常
  只印一行錯誤、判斷結果照舊，只看 pass／block 的話 macOS job 照樣全綠。2026-10-01 實測：在 gate 的
  `staged=$(…)` 下一行加 `lc=${staged,,}`，3.2 下 36 個 ❌、bash 5 全過；`shopt -s lastpipe`、
  `${a[-1]}` 這類清單外的錯誤，是加了「`: line N: `」前綴才抓到的。`test-install.sh` 大部分靠 `set -e`
  （3.2 在 `set -e` 下遇到這類錯誤會直接中止）；只有 T2 用同一組樣式另外看 stderr，因為它的回傳碼被 `|| rc=$?` 接住了
- 兩支都在暫存目錄裡跑、`trap` 跑完清掉（本機會拿來重跑與做變異測試）
- 腳本開頭是 `set -e`（2026-10-01 從 ci.yml 內嵌 step 搬出來時照 GitHub Actions 預設的 `bash -e` 保留）：
  預期會被擋的 commit 一律包在 `expect` 的 `if` 裡，新增情境時別讓會回非 0 的指令裸跑
  - ⚠️ **預期放行、但會觸發 hook 的指令（`git commit --amend` 這類）也要包進 `expect`**：裸跑的話，
    變異版 gate 擋下它時 `set -e` 中止整支，後面的情境一則都沒跑，看起來像「只紅了前面幾則」。
    2026-10-19 實測：拿「pre-commit 也查報告」的變異跑，整支停在 ⑦ 那行裸跑的 amend，新加的繞過①根本沒跑到；
    包進 `expect` 後才跑完。驗法：變異版與固定版的判定行數（`grep -cE '^(✅|❌ .*：(預期 |輸出裡有 shell 錯誤))'`）要一樣
- ⚠️⚠️ **變異測試要選對「變異方向」,否則它證明的不是你以為的那件事**。曾把 opt-in 守門 `[ -d docs/reviews ] || return 1` 改成**永遠 `return 1`**
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
- ⚠️⚠️ **一個「恆真」的斷言比沒有斷言更糟**。
  情境 ① 曾寫 `BEFORE_BASE=$(cat "$BASE_FILE")` 然後 `base_is "$BEFORE_BASE"`,
  但那行讀檔是在 `expect … --start-segment` **跑完之後** —— 等於拿檔案跟自己比,**永遠綠**。
  實測:對變異版,①的起點**確實被搬動了**而斷言照樣過;那個不變量**實際只有情境 ③ 在守**。
  **做法**:斷言「X 沒有被改動」時,快照一定要在**被測指令之前**取;
  而且**用變異測試檢查這個斷言本身會不會紅** —— 不會紅的斷言是裝飾品。
- ⚠️ **新增的 review 強制情境刻意跑在「有 `docs/reviews/` 目錄」的 repo 裡，而它之前的情境沒有**
  —— 那正是 opt-in 的證明：**加了新功能，既有情境一項都不用改**。
  寫新情境時不要把 `mkdir docs/reviews` 往上搬，會把前面那些情境的前提改掉。
- ⚠️ **「剛採用慣例時第一次 `--start-segment` 被擋」是情境 ①，不是待修的邊角** ——
  上一段本來就沒報告，那是真實的導入路徑，預期結果是擋下、不是 `pass`。
- 本機跑：`/bin/bash tests/test-gate.sh`（repo 根目錄或任何地方都可以，gate 路徑以腳本位置推算）
  - bash 5（CI 的 ubuntu 那份）要在 **repo 根目錄**跑（`"$PWD"` 掛成 `/repo`）：`docker run --rm -v "$PWD":/repo:ro bash:5 sh -c 'apk add --no-cache git >/tmp/apk.log 2>&1 || exit 3; ln -sf /usr/local/bin/bash /bin/bash; cd /tmp && bash /repo/tests/test-gate.sh'`
    —— 映像沒有 git，也沒有 `/bin/bash`（bash 在 `/usr/local/bin/bash`，gate 的 shebang 寫 `#!/bin/bash`），兩步都不能省。
    少裝 git，一則情境都沒跑就 `git: command not found`；少了 `ln`，gate 跑不起來 ——
    直接叫印 `/bin/bash: bad interpreter`，從 hook 叫印的卻是 `…/check-claude-md.sh: not found`（檔案明明在，缺的是直譯器；`apk add git` 也不會順便帶來 `/bin/bash`）
- 要通過 `shellcheck -S warning`（CI 的 ShellCheck 清單逐檔寫死，這支已列入）
- **`test-install.sh` 要直接呼叫安裝腳本的函式時，交給另一個 bash 行程**（T2、T7 的 `drive.sh`：先把 `HOME` 換成沙盒再 `source`）。兩個理由：
  ①測試檔上面那行 `source` 是在真實 HOME 下跑的，`CLAUDE_DIR` 當下就定死，主 shell 直接呼叫會寫進真的 `~/.claude`
  ②寫成 `函式 || rc=$?`（包成子 shell 也一樣）時，bash 會讓函式裡的 `set -e` 失效，測到的不是真的安裝行為。
  T2 的 python3 那一臂靠在行程裡重新定義 `command_exists`（對 `jq` 回 1）走到；每臂把實際走的路寫進 `arm.txt` 再斷言，
  開頭另外斷言 `jq` 與 `python3` 都在 —— 少一個時兩臂走同一條路，等價比對會空通過
- **`plain`（去顏色碼）用 `LC_ALL=C sed`**：輸出裡有壞的位元組時，UTF-8 locale 下的 BSD sed 印到那一行就失敗（rc=1），
  那一行之後的內容全部不見 —— 要找的字在它後面時，「不可以出現某字」的斷言空通過；在它前面時，「要出現某字」的斷言照樣綠。
  2026-11-14 實際踩到：安裝腳本新加的訊息寫了 `$old（刪除前已備份）`，bash 3.2 把變數名吃掉、印出壞的位元組，
  T8 紅在一個不相干的斷言上。現在 T8、T9、T10 另有 `utf8_ok`（`iconv`）直接斷言安裝輸出是合法的 UTF-8。
  ⚠️ `utf8_ok` 把轉出來的內容寫到 `$WORK` 的檔案，不可以改回 `> /dev/null`：macOS 的 `/usr/bin/iconv` 在輸出是 `/dev/null`、
  而某個多位元組字剛好跨過 1024 位元組邊界時，對合法的 UTF-8 回 1（`iconv(): Inappropriate ioctl for device`）。
  2026-11-15 在 macOS 27.0.1 踩到：環境檢查多印一行，後面的字整個往後移，T10 就紅在「不合法的 UTF-8」，而同一份輸出逐行檢查都合法。
  寫到檔案或管線就正常，真的壞位元組照樣回 1（在邊界前後各試過；管線是 `iconv … | cat`，55 個長度都回 0、內容相同，壞位元組回 1）
- **只跑一組**：`TEST_ONLY=T5 /bin/bash tests/test-install.sh`（原有的檢查與 T1 照跑；值不是 T2–T10 其中一個就 exit 2，
  免得打錯字時一組都沒跑卻 rc=0 —— 新增一組時那個 `case` 要跟著加）。變異對照（2026-11-14，
  把安裝腳本的一行改壞、只跑那一組；記「哪個變異 → 紅在哪個斷言」）：啟用寫成 `false` → T3「沒有啟用」；
  移除時不刪 `enabledPlugins` 的鍵 → T3「uninstall 之後…只剩原有的鍵」；`mcp_scope` 的 `local:N` 改回 `none` → T4「只設在一個專案底下」；
  拿掉 skills／scripts 的 `backup_before_overwrite` → T5 各自的「被換掉之前沒有備份」；全域 CLAUDE.md 的 `cmp -s` 改成 `false` → T6「內容相同時沒有印」；
  選單預設值改成 `o` → T6「本機版被改掉了」；`validate_skill_hooks` 的 `exit 1` 拿掉 → T7；舊指令檔不備份 → T8；
  `--commands-only` 也印兩段 → T9「沒裝 agent」；啟用數判斷改 `-ge 0` → T9「卻印了」；數量或清單改用 `OFFICIAL_PLUGINS` → T9 的數量與「卻列在」；
  訊息改回 `$old（` → T8「不合法的 UTF-8」；兩條登記敘述都改成「一律整筆新建」→ T2 的 `install.p-entry-valid`（`installedAt` 與 `keepme` 不見）。
  T2 的對照是修正前的程式碼：第一版 92 例紅 16 例；審查後再補「檔案裡不只一個 JSON 值」與「開頭有 BOM」共 17 例，17 例在當時的程式碼上兩臂結論都不同
  （見 `docs/designs/2026-11-14-installer-hardening-design.md` 與 `docs/reviews/2026-11-14-installer-hardening/`）。
  2026-11-15 `autocompact_state` 與 T10 的變異對照（腳本與輸出沒進 repo，這裡記「哪個變異 → 紅在哪」）：jq 或 python3 任一邊拿掉「值是整數」→ T2 `acw.a-top-frac`；
  jq 把最上層的 `null` 當成有值 → T2 `acw.a-top-null`；python3 放掉範圍上限 → T2 `acw.a-top-2m`；jq 不擋 `modelSettings` 不是物件 → T2 `acw.a-ms-array`；
  jq 不要求剛好一個頂層物件 → T2 `acw.a-multi`；環境變數不擋開頭的 0 → T10「環境變數是 0400000」；不擋長度 → T10「輸出裡有 shell 錯誤」；
  ffmpeg 那一行改回 `└──` → T10「ffmpeg 那一行應該以」；缺 jq 與 python3 時有字樣也回 `none` → T10「應該回 unknown」；解析失敗講成沒設 → T10「檔案壞掉」；
  環境變數有效也照讀檔 → T10「環境變數是 400000」。這台機器有裝 ffmpeg，「沒裝 ffmpeg」那個分支的樹狀符號只有沒裝的環境（ubuntu 容器）跑得到。
  同一天審查（`docs/reviews/2026-11-15-speed-cost/S1-a.md`）找到兩臂結論不同的輸入，補了四列，在修正前的程式碼上各紅各的：
  jq 沒先換成浮點數就比大小 → T2 `acw.a-top-edge-lo`、`acw.a-top-edge-hi`（jq 那一臂不是 `all`；jq 1.7、1.7.1、1.8.1 都是）；python3 遇到不合法的 UTF-8 位元組就報錯 → T2 `acw.a-badutf8`；
  python3 沒放寬整數位數上限 → T2 `acw.a-bigint`（後兩列是 python3 那一臂不是 `all`）。
  ⚠️ T2 只守它列的那幾類輸入（不存在、空檔、只有空白、壞 JSON、頂層型別不對、不只一個 JSON 值、BOM、鍵是 null 或型別不對、登記項格式不對；
  `acw` 那幾列另有：數字在範圍外、不是整數、字串、布林、`NaN`、`Infinity`、只設在個別模型、`modelSettings` 或某個模型的值不是物件、
  字面值比浮點數精確而四捨五入後落在邊界上、別處有不合法的 UTF-8 位元組、別處有幾千位的整數）。
  最後三類只有 `acw` 有列：其他幾支（`plugin_enabled_state`、`mcp_scope`、登記與移除）讀檔的寫法相同，這三類沒有測過。
  `acw` 已知沒對齊、也沒列的：小寫的 `nan`（jq 收、python3 不收）、幾千層的巢狀（兩邊的深度上限不同）。
  沒列的照樣可能不一致 —— 審查時補的兩類就是第一版沒想到的；jq 與 python3 對大整數、NaN 的**寫回**格式沒比過（`acw` 只讀不寫；
  讀的時候兩邊都把 `NaN`、`Infinity` 當數字，jq 1.7、1.7.1、1.8.1 實測）
- **T2 的 `j-*` 那幾列改的是 marketplace 裡的 `plugin.json`**（`T2_PLUGIN_JSON`）：`j-noversion` 走「`plugin.json` 沒有 version、改讀 `installed_plugins.json`」那條路 ——
  官方 skill-creator 就是這樣，使用者的機器實際走的是它；其他列的 `plugin.json` 都有 version，走不到。把 jq 那條 fallback 改成讀錯欄位 → 這一列紅（jq 那一臂印「取不到版本」）
- **`t2_canon` 只把長得像時間戳的 `installedAt`／`lastUpdated` 換成 `TS`**：fixture 裡的 `"A"` 要留著，
  否則「更新既有登記的三個欄位」與「整筆新建」正規化後長得一樣，`p-entry-valid` 就分不出來（審查抓到的：第一版兩種結果都綠）
- **T1 只有在 GNU 的 `cp` 上才會紅**（macOS 的 `cp -r` 本來就跟著連結）。它用 `# --- T1 開始`／`# --- T1 結束` 夾住、寫成自足的，
  要看紅就在 Linux 容器裡把那一段 `sed -n` 抽出來跑（PATH 上放假的 `claude`、`node`、`git`）。整支在 Linux 上跑（repo 根目錄）：
  `docker run --rm -v "$PWD":/repo:ro ubuntu:24.04 bash -c 'apt-get update -qq >/tmp/a.log 2>&1 && apt-get install -y -qq jq python3 git >>/tmp/a.log 2>&1 || exit 3; mkdir /fb && printf "#!/bin/sh\necho v0\n" > /fb/node && chmod +x /fb/node && PATH=/fb:$PATH bash /repo/tests/test-install.sh'`
  （2026-11-14 實跑：bash 5.2.21、jq 1.7、Python 3.12.3、GNU coreutils 9.4，全過。同一天 `debian:bullseye` 的 apt 對 jq、git 回 404，裝不起來）

## 與上層的關係

gate 本體的規則與「改了 gate 要做變異測試」的規定在 `scripts/CLAUDE.md`；CI 防線的總表在
根目錄的 `DD_PIPELINE_ARCHITECTURE.md`。
