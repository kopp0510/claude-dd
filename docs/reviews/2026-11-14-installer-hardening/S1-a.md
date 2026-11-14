# S1 步驟 4：審查者 A（安裝腳本的邏輯）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數）與步驟 3 的 code-simplifier。
給審查者的 prompt 只有一句「完整派工在 `<scratchpad>/imp/review/prompt-a.txt`，先讀完再照做」加三句防漏；下面是那個檔的全文（路徑已去識別）。
diff 檔 `<scratchpad>/imp/review/diff.txt`（2940 行）的組成：①`git diff 28663da HEAD`（HEAD = 1a05146）②步驟 3 與審查同時進行的說明
③`install-dd-pipeline.sh`、`tests/test-install.sh`、`tests/CLAUDE.md` 在 HEAD 的整檔內容 ④已跑過的驗證 V1–V10 與預期值。

````text
你是 8 步開發迴圈步驟 4 的審查者 A。職責：找漏洞。每一條發現都要附證據（diff 檔的行、或你實際跑的指令與輸出）；沒有證據的不算。不寫優點。

## 範圍與資料

- 審查範圍：repo <repo> 的 `git diff 28663da HEAD`（一個功能段落，4 個 commit：89dd118、4995b0d、61585a4、1a05146）
- diff 檔：<scratchpad>/imp/review/diff.txt（2940 行，四部分：整段 diff／步驟 3 的說明／被改到的檔在 HEAD 的整檔內容／已經跑過的驗證）
- **diff 檔用 Read 的 offset／limit 每次 300 行讀到最後一行**。Read 一次讀太多會靜靜截斷、不報錯
- 被改到的檔（install-dd-pipeline.sh、tests/test-install.sh、tests/CLAUDE.md）一律讀 diff 檔第 3 部分那一份，**不要讀工作目錄**：另一個 agent（code-simplifier）正在同時改工作目錄。其餘被改到的大份文件用 `git show HEAD:<路徑>`。沒被改到的檔照常讀
- diff 檔第 4 部分的驗證已經跑過、結果已確認，**不要重跑**；但「跑過」不代表結果對，預期值寫在旁邊，覺得預期本身有問題就報

## 硬性限制

- 不要執行、也不要 source install-dd-pipeline.sh（任何參數都不要）——它會改到真實的 ~/.claude。不要跑 tests/test-install.sh（工作目錄正在被改）
- 唯讀：不改 repo 裡任何檔、不 commit、不把報告寫成檔（直接在最終訊息交回完整報告）
- 需要小型重現時，只能在 <scratchpad>/imp/review/a/ 底下建檔（把要驗的那幾行邏輯抄成獨立的小腳本，對該目錄下的假檔案跑；可以用 /bin/bash（macOS 內建 3.2）、jq、python3），重現腳本不得呼叫或 source 安裝腳本本體
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

## 你的方向：安裝腳本的邏輯

1. jq 與 python3 兩條路徑：除了測試表列的 92 例，還有沒有輸入會讓兩條路徑結論不同、或兩條一起做錯（例如鍵的值是 false、0、空字串、數字；頂層物件裡有其他型別；兩處讀版本號的地方；plugin key 或路徑含特殊字元）。每條改過的 python 敘述與 jq filter 逐句對
2. backup_before_overwrite 的新條件對它的每一個呼叫點（diff 檔第 3 部分的整檔裡找）：哪些組合仍會弄丟內容、備份成錯的東西、或在 set -e 下中止（連結指向目錄、相對連結、懸空連結、目標是目錄且裡面有連結）
3. ENABLED_PLUGINS 與 show_completion 在各種模式下（一般安裝、--force、--update、--commands-only、--check、--uninstall）有沒有印錯、漏印、或用到沒定義的東西
4. 新加的每一行在 macOS bash 3.2 與 set -e 下會不會出錯；訊息裡有沒有變數緊貼全形字（要寫成 ${var}）
5. 安裝腳本裡新加或改過的註解，講的事跟程式碼實際做的一不一樣

照你平常的報告格式交回（分級、每條附證據與具體失敗情境、Not reported、What I ran）。用繁體中文。
````

## 發現

審查者交回的完整報告（逐字；只把本機路徑換成 `<scratchpad>`、`<repo>`）：

````text
Critical 0 / Important 2 / Smells 0。範圍是 `git diff 28663da HEAD`（89dd118、4995b0d、61585a4、1a05146）。安裝腳本讀的是 diff 檔第 3 部分的 HEAD 整檔，沒有讀工作目錄。

[Important] install-dd-pipeline.sh:220（jq_inplace 的前置檢查）與 :651（mcp_scope 的 jq filter）：設定檔裡接連放兩個 JSON 值時（例如 `{} {}`），jq 與 python3 兩條路徑結論不同。這一段宣稱已經把這類情況修成一致，T2 的 92 例沒有這一例。
  Failure：`~/.claude.json` 是 `{"mcpServers":{"playwright":{}}} {}` 時，jq 那條印 `global` 與 `none` 兩行，進不了 print_mcp_line 的任何一個 case，落到 `*` 印「未安裝」（把不確定講成確定）；python3 那條回 unparseable。settings.json 是 `{} {}` 時，jq_inplace 的 `jq -e 'type == "object"'` 兩個值都印 true，exit 0，前置檢查放行；接著 filter 兩份都改、寫回兩個物件，回報成功並印「已啟用」。python3 那條 json.load 報 Extra data，回報更新失敗。jq_register 也是這樣。
  Evidence：重現腳本只抄了 filter 與 python 敘述，跑出來：`MCP [{"mcpServers":{"playwright":{}}} {}] jq=global|none py=unparseable`、`SET [{} {}] jq rc=0 -> {"enabledPlugins":{…:true}}{"enabledPlugins":{…:true}} | py rc=1 -> {}{}`。jq 的 `-e` 只看最後一個輸出值，所以 `[] {}` 也會通過前置檢查（不過後面的 filter 會報錯）。一個可行的修法：前置檢查改成 `jq -se 'length == 1 and (.[0] | type) == "object"'`，mcp_scope 也比照。

[Important] install-dd-pipeline.sh:870-897（install_plugins）配 :1286-1302（show_completion）：settings.json 寫入成功、installed_plugins.json 寫入失敗時，`continue` 之前沒有把 enabledPlugins 撤回。完成訊息卻印「這次沒有啟用任何官方 Plugin」。
  Failure：installed_plugins.json 是空檔、`[]` 或 `{"plugins":"x"}`。兩個 plugin 都先在 settings.json 寫進 `enabledPlugins[key] = true`（第 870 行），再在第 894 行走「installed_plugins.json 更新失敗，跳過」，ENABLED_PLUGINS 是空的。結果 settings.json 記成已啟用，完成訊息說一個都沒啟用。S1-4 的目標是「只報這次真的做了的」，這裡跟實際寫出的內容相反。
  Evidence：第 870-878 行先跑 json_edit 改 settings_file，第 890-897 行失敗時只 echo 再 `continue`，沒有還原。T2 的 p-empty、p-array 等案例只斷言輸出裡沒有「已啟用」，沒有斷言 settings 那一行。

What I ran
- Read diff.txt 的第 1–2100 行，每次 300 行 → 讀完第 1–3 部分（安裝腳本整檔，以及 test-install.sh 的前段）
- `sed -n '2401,2940p' diff.txt | grep 分節標題` 加 `sed -n '2840,2940p'` → 讀到 tests/CLAUDE.md 的尾段與第 4 部分 V1–V10
- `/bin/bash scratchpad/imp/review/a/repro.sh`（只抄 jq_inplace、py_inplace、mcp_scope 的 jq 與 python、settings 的 set 與 del 兩句；沒有 source 安裝腳本；jq-1.7.1、Python 3.13.2）→ 接連放兩個值的情況兩臂結論不同。enabledPlugins 是 false、0、true 時，set 與 del 兩臂都失敗、都不改檔，結論一致

Not reported
- 我逐句對過、結論一致，不是缺陷的：plugins[key] 是 0、false、""、負數、true、非空物件、字串時的 jq_register 與 py_register；兩處讀版本號的地方遇到非物件或非字串；mcp_scope 的 mcpServers 或 projects 是 false、0、""、字串、陣列。
- 既有問題，不在 diff 內：目標是懸空 symlink 時，backup_before_overwrite 會直接 return（`[ -e ]` 不成立），呼叫端接著 `cp source target`。GNU cp 遇到這種情況會拒絕寫入，在 set -e 下中止安裝（V9 也觀察到 `cp -RL` 對懸空連結回 1）。
- 指向目錄的 symlink（skills、命名空間指令）走 `cp -r` 那一支。在 GNU 上備份裡只留連結本身，但 `rm -rf` 只刪連結，所以原內容沒丟。這不算資料遺失，沒有列為發現。
- 沒有查證的，需要另外驗：jq 1.6 與 1.7 對大整數、NaN、UTF-8 BOM 的解析差異，跟 python3 是否一致（拿這三種輸入在兩種版本各跑一次 jq 與 python3 就能確定）。
- 依指示沒有跑：安裝腳本本體、tests/test-install.sh。
````

## 處置

- **多個 JSON 值時兩條路徑結論不同**（Important）→ 採納。自己重跑確認：`jq -e 'type == "object"'` 對 `{} {}`、`[] {}` 都 rc=0；改成 `jq -e -s 'length == 1 and (.[0] | type) == "object"'` 後兩者 rc=1（本機 jq 1.7.1 與 Ubuntu 的 jq 1.7 都跑過）。
  修法：`jq_inplace` 的前置檢查、`mcp_scope`、`plugin_enabled_state`、兩處讀版本號的 jq 都加 `-s`。T2 補 `s-multi`、`s-nullobj`、`p-multi`、`c-multi`、`j-multi`；補上之後、改碼之前這幾例都紅（兩臂結論不同），改碼後綠
- **登記失敗時 `settings.json` 已經寫成啟用，完成訊息卻說沒啟用**（Important）→ 採納。`install_plugins` 改成先登記（`installed_plugins.json`）、再啟用（`settings.json`），登記失敗就跳過、不動 `settings.json`。
  T2 的登記失敗各列加「`settings.json` 沒被建立／沒有那個鍵」的斷言，T9 加 (d)；改碼之前這些都紅，改碼後綠
- Not reported 的「目標是懸空 symlink 時 GNU `cp` 會中止安裝」：既有行為、不在這段 diff 裡，沒有實跑確認，這次不處理；記在設計文件 S1 的「已知、這次沒處理」
- Not reported 的「jq 版本對大整數、NaN、BOM 的差異」：BOM 這次處理了（見 S1-c 的處置）；大整數與 NaN 沒比，寫進 `tests/CLAUDE.md` T2 的限制
