# S1 步驟 4：審查者 B（測試（T1–T9））

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數）與步驟 3 的 code-simplifier。
給審查者的 prompt 只有一句「完整派工在 `<scratchpad>/imp/review/prompt-b.txt`，先讀完再照做」加三句防漏；下面是那個檔的全文（路徑已去識別）。
diff 檔 `<scratchpad>/imp/review/diff.txt`（2940 行）的組成：①`git diff f6179b2 HEAD`（HEAD = 072615e）②步驟 3 與審查同時進行的說明
③`install-dd-pipeline.sh`、`tests/test-install.sh`、`tests/CLAUDE.md` 在 HEAD 的整檔內容 ④已跑過的驗證 V1–V10 與預期值。

````text
你是 8 步開發迴圈步驟 4 的審查者 B。職責：找漏洞。每一條發現都要附證據（diff 檔的行、或你實際跑的指令與輸出）；沒有證據的不算。不寫優點。

## 範圍與資料

- 審查範圍：repo <repo> 的 `git diff f6179b2 HEAD`（一個功能段落，4 個 commit：20680b1、cd1b1c7、3155dfb、072615e）
- diff 檔：<scratchpad>/imp/review/diff.txt（2940 行，四部分：整段 diff／步驟 3 的說明／被改到的檔在 HEAD 的整檔內容／已經跑過的驗證）
- **diff 檔用 Read 的 offset／limit 每次 300 行讀到最後一行**。Read 一次讀太多會靜靜截斷、不報錯
- 被改到的檔（install-dd-pipeline.sh、tests/test-install.sh、tests/CLAUDE.md）一律讀 diff 檔第 3 部分那一份，**不要讀工作目錄**：另一個 agent（code-simplifier）正在同時改工作目錄。其餘被改到的大份文件用 `git show HEAD:<路徑>`。沒被改到的檔照常讀
- diff 檔第 4 部分的驗證已經跑過、結果已確認，**不要重跑**；但「跑過」不代表結果對，預期值寫在旁邊，覺得預期本身有問題就報

## 硬性限制

- 不要執行、也不要 source install-dd-pipeline.sh（任何參數都不要）——它會改到真實的 ~/.claude。不要跑 tests/test-install.sh（工作目錄正在被改）
- 唯讀：不改 repo 裡任何檔、不 commit、不把報告寫成檔（直接在最終訊息交回完整報告）
- 需要小型重現時，只能在 <scratchpad>/imp/review/b/ 底下建檔（把要驗的那幾行邏輯抄成獨立的小腳本，對該目錄下的假檔案跑；可以用 /bin/bash（macOS 內建 3.2）、jq、python3），重現腳本不得呼叫或 source 安裝腳本本體
- 只用手上的資料判斷；需要外部查證的（上游文件、別的平台的行為）列出來交回，不要猜
- repo 的 CLAUDE.md 裡寫的 8 步迴圈與報告落地流程由主對話負責，你只做這一次審查

## 這段做了什麼（事實，不含判斷）

- backup_before_overwrite：目標是指向檔案的 symlink 時改用 `cp -L`，其餘維持 `cp -r`
- jq_inplace 開頭加 `jq -e 'type == "object"'`；py_inplace 載入後加 `isinstance(data, dict)` 檢查
- install_plugins：settings 那句 python、py_register、jq_register 改寫（鍵是 null 當成沒有；登記項第一筆不是物件就報錯）；啟用成功的 plugin 記進全域陣列 ENABLED_PLUGINS
- uninstall：兩句 python 改成鍵是 null 時不報錯
- mcp_scope：jq 與 python3 兩段都加「頂層不是物件 → 失敗」，落到既有的 unparseable；print_mcp_line 的字樣跟著改
- create_commands：清 deprecated_dd 列的舊指令檔之前先 backup_before_overwrite
- show_completion：agent 與 plugin 兩段只在 COMMANDS_ONLY=false 時印；plugin 只列 ENABLED_PLUGINS
- tests/test-install.sh：新增 T1–T9（原有的 10 個檢查沒有動）
- 文件：tests/CLAUDE.md、根目錄 CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、README.md、README.zh-TW.md、CHANGELOG.md、設計文件

## 你的方向：測試（tests/test-install.sh 的 T1–T9）

1. 空通過：哪些斷言在被測行為壞掉時照樣會綠（恆真、比到自己、grep 對空輸入、管線裡的 while 子 shell 把失敗吃掉、`|| true`、被前一個斷言蓋住）。第 4 部分 V6 列了哪些變異做過、哪些沒做
2. T2 的 92 列：每一列寫死的預期（第 6、第 7 個參數）是不是那個函式該有的行為；有沒有哪一列的預期其實是把錯的行為定成對的
3. 可攜性：bash 3.2 與 bash 5、BSD 與 GNU 的 sed／find／mktemp／iconv／cp、GitHub 的 ubuntu 與 macOS runner（$BASH、PATH、locale 是 C 或 POSIX 時）會不會行為不同
4. 安全：有沒有任何一條路徑會寫到真實的 HOME（測試檔第 37 行附近那行 source 是在真實 HOME 下跑的）；暫存目錄有沒有清乾淨
5. TEST_ONLY：只跑一組時，後面的組用到的函式或變數還在不在；不設時行為有沒有變
6. 測試裡的註解講的事跟實際一不一樣

照你平常的報告格式交回（分級、每條附證據與具體失敗情境、Not reported、What I ran）。用繁體中文。
````

## 發現

審查者交回的完整報告（逐字；只把本機路徑換成 `<scratchpad>`、`<repo>`）：

````text
Critical 0 / Important 4 / Smells 0 — 範圍：`git diff f6179b2 HEAD`（20680b1、cd1b1c7、3155dfb、072615e），方向是 tests/test-install.sh 的 T1–T9

[Important] install-dd-pipeline.sh:220（jq_inplace 的護欄）、:651（mcp_scope 的 jq 段）：一個檔裡有好幾個 JSON 值時，jq 與 python3 兩條路徑結論不同，T2 的 92 例沒有涵蓋這一類
  Failure：settings.json 或 installed_plugins.json 的內容是 `null {}` 或 `{} {}`。`jq -e 'type == "object"'` 的回傳碼只看最後一個輸出，所以護欄放行，接著把兩份物件都寫回檔案並印「已啟用」；python3 那條在 json.load 報 Extra data 而失敗。`null {}` 這種輸入正是這段說「已經擋掉」的「頂層是 null 被改寫成物件」。~/.claude.json 是 `{"mcpServers":{"playwright":{}}} {}` 時，jq 回 `global\nnone`，落進 print_mcp_line 的 `*)` 分支印「未安裝」；python3 回 unparseable。
  Evidence：b/repro.sh（從 HEAD 抄 jq_register、py_register、mcp_scope 的邏輯，沒有 source 安裝腳本）的輸出是 `installed=null {}` → `jq: OK -> {…}{…}`、`py: FAIL`；`claude.json={"mcpServers":{"playwright":{}}} {}` → `jq mcp: [global\nnone]`、`py mcp: [unparseable]`。設計文件寫「兩條路徑對同一份檔案的結論相同」，這個宣稱在這裡不成立。

[Important] tests/test-install.sh:640（T2 install.p-entry-valid）與 :694（T3 重跑）：「已存在就只更新三個欄位」被改成「一律整筆新建」時，兩組都照樣綠
  Failure：把 jq_register 與 py_register 都改成一律走 else 分支，舊登記的 installedAt 和 Claude Code 自己加的其他欄位會被丟掉。t2_canon 把 installedAt、lastUpdated 都換成 TS，fixture 只有四個欄位，T2_OK_INSTALLED 只錨定 installPath，$7 也只禁止 `/old`。所以「更新」與「新建」兩種結果都會通過。T3 第二次跑時兩種結果的 canon 也一樣。
  Evidence：b/repro.sh 把兩種結果各做一次 canon 再比對 T2_OK_INSTALLED，`upd` 與 `rep` 都印 `matches T2_OK_INSTALLED`，兩個都沒有 `/old`。fixture 多放一個不在 entry 模板裡的欄位、把 installedAt 留成 "A" 不換掉並斷言它，就能鎖住這個行為。

[Important] tests/test-install.sh:578–589（T2 的 state.s-null、s-array、s-string、s-number、s-ep-string、s-ep-array，預期都是 `'^none$'`）：這幾列把「把不確定講成確定」定成了正確答案
  Failure：settings.json 是 `[]` 時，`--check` 印「claude-md-management: 未啟用」，像是確定的結論；同一份檔案在 install 那邊印「settings.json 更新失敗（檔案可能損毀）」。這次在 mcp_scope 的註解裡寫了相反的理由（HEAD 第 648–650 行：「整個檔不是設定檔的形狀時，講『沒安裝』是把不確定講成確定」），根目錄 CLAUDE.md 也有「不確定就說不確定」這條鐵則。同一個理由，套在 mcp_scope 得到 unparseable、套在 plugin_enabled_state 得到 none，T2 把這個不一致釘死了。
  Evidence：CHANGELOG diff 第 18 行「`plugin_enabled_state` 對頂層不是物件回 `none` 的既有設計不動」；HEAD install-dd-pipeline.sh 第 417 行 `if type != "object" then "none"`。這是不是要維持，請主對話決定。

[Important] tests/test-install.sh:426（`want()`）：TEST_ONLY 打錯時一組都不跑，仍然 rc=0
  Failure：寫成 `TEST_ONLY=t5` 或 `TEST_ONLY=T05` 時，T2–T9 全部跳過，只印原有 10 行加 T1 共 11 個 ✅，exit 0。tests/CLAUDE.md 的寫法是修完用 TEST_ONLY 確認轉綠，打錯字就會在被測的那組根本沒跑的情況下看到綠燈。
  Evidence：第 426 行 `[ -z "${TEST_ONLY:-}" ] || [ "$TEST_ONLY" = "$1" ]`，結尾沒有檢查 TEST_ONLY 有沒有對到任何一組。另外第 456–458 行（要求 jq 與 python3、建 T2_DIR）不在 `want T2` 裡，所以 `TEST_ONLY=T5` 在沒有 jq 的機器上會紅在 T2 的前置檢查。

What I ran
- Read diff.txt 第 1–1200 行（每次 300 行）、第 2298–2397 行、第 2900–2940 行 → 讀到第 1 部分整段 diff、test-install.sh HEAD 第 1–99 行、第 4 部分 V1–V10
- `grep -n '^========\|^########' diff.txt` → 各部分起訖行：855、2298、2821、2907
- `sed -n '855,2297p' diff.txt > b/install.txt`，再 `sed -n` 讀出 plugin_enabled_state、validate_skill_hooks、install_*、mcp_scope、check_mcp、install_plugins、create_*、uninstall、create_global_claude_md、show_completion、main → HEAD 版內容（中途誤把暫存檔寫在 review/ 底下，已馬上 mv 進 b/）
- `/bin/bash b/repro.sh`（抄出的 jq、py 邏輯，對 b/w/ 裡的假檔跑）→ 結果見上面兩條；腳本最後那個 grep 沒命中所以 rc=1，是預期的結果，不是腳本錯誤

Not reported
- 讀了推論、沒有回報的：
  - T5 在管線裡的 while 用 `exit 1` 不會空通過（管線取 while 的狀態，set -e 會中止）
  - T2 的 sed 沒加 LC_ALL=C，遇到壞的位元組會變紅、不會空通過
  - 所有呼叫安裝腳本的地方都先換掉 HOME，T2、T7 的 drive.sh 在 source 之前就 export HOME
  - 暫存目錄都在 $WORK 底下，由 trap 清掉
  - `{"plugins":{K:false}}` 兩條路徑結果一樣（我原本以為會不同，實跑後排除）
- 既有問題，不在這段 diff 裡：install_plugins 先寫 settings.json、再寫 installed_plugins.json，後者失敗時（例如 p-entry-str）前者已經啟用了，留下半套狀態
- 沒有跑：GitHub runner 實機、GNU 容器。照限制，也沒有讀工作目錄、沒有跑 test-install.sh
- 檔案：<scratchpad>/imp/review/b/repro.sh、<scratchpad>/imp/review/b/install.txt
````

## 處置

- **多個 JSON 值時兩條路徑結論不同**（Important）→ 採納，與 S1-a 的第一條是同一件事；這份多給了 `null {}` 這個輸入，已收進 T2（`s-nullobj`）。處置見 S1-a
- **`p-entry-valid` 與 T3 重跑分不出「更新三個欄位」與「整筆新建」**（Important）→ 採納。fixture 多放 `"keepme":1`；`t2_canon` 改成只把長得像時間戳的值換成 `TS`，`"installedAt":"A"` 因此留著；
  `p-entry-valid` 另外斷言 `"installedAt": "A"` 與 `"keepme": 1`。把 `jq_register` 與 `py_register` 都改成一律走新建那一支實跑：這一例變紅（兩臂都少了這兩個欄位），還原後綠。T3 沒有另外加（這個行為由 T2 那一例守）
- **`plugin_enabled_state` 對頂層不是物件回 `none`，被 T2 釘成正確答案**（Important）→ 採納。讀了引入它的 commit 3547796：當時是為了讓兩條路徑對齊才回 `none`。
  根目錄 CLAUDE.md 的鐵則「不確定就說不確定」與這一段給 `mcp_scope` 寫的理由都指向 `unparseable`，所以改成：頂層不是物件（或不只一個 JSON 值）→ `unparseable`；`enabledPlugins` 這個鍵型別不對 → 仍是 `none`。
  T2 的 `state.s-null`、`s-array`、`s-string`、`s-number` 預期改成 `unparseable`（改碼前紅、改碼後綠）；設計文件的假設 A4 跟著改；CHANGELOG 記下 `--check` 的畫面變化
- **`TEST_ONLY` 打錯時一組都沒跑卻 rc=0**（Important）→ 採納。開頭加 `case` 驗值，不是 T2–T9 其中一個就 exit 2（實跑 `TEST_ONLY=t5` → rc=2）；jq 的前置檢查搬進 `want T2`，python3 的留在外面（T3 之後各組的 `t2_canon` 也要它）
- Not reported 的「先寫 settings、後寫 installed 留下半套狀態」：審查者 A 把它列成 Important，已處理（見 S1-a）
