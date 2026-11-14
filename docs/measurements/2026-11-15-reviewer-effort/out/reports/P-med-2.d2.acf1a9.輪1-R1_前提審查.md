【我查了什麼】

讀過的檔（repo 根目錄 `<WORK>/P-med-2`）：
- `install-dd-pipeline.sh`：8（`set -e`）、26–27、156–160、187–196（`backup_before_overwrite`）、208–262（`jq_inplace`／`py_inplace`／`json_edit`）、386–460（`plugin_enabled_state`、`check_plugins`）、463–520（`validate_skill_hooks`）、523–620（skills、agents 覆寫邏輯）、625–720（`mcp_scope`、`check_mcp`）、730–878（`install_plugins`）、879–955（`create_commands`）、1000–1060（scripts、output styles）、1059–1180（`uninstall` 與全域 CLAUDE.md）、1241–1300（`show_completion`）、1340–1404（`main`）
- `tests/test-install.sh`（全 87 行）、`tests/CLAUDE.md` 第 1 列段、`scripts/CLAUDE.md`、`CLAUDE.md` 的 `## 新增 …` 與 §「開發本 repo」段、`scripts/check-claude-md.sh`（:39、:250–290）、`.github/workflows/ci.yml`、`README.md`（:19、:38、:70、:126、:156）、`DD_PIPELINE_ARCHITECTURE.md`（:72–74）、`CHANGELOG.md`（:19）
- 跑過的 grep：
  - `grep -n -E 'backup_before_overwrite|cp -r|jq_inplace|py_inplace|jq_register|py_register|mcp_scope|plugin_enabled_state|show_completion|create_commands|^uninstall|install_plugins\(\)' install-dd-pipeline.sh`
  - `grep -n 'FORCE' install-dd-pipeline.sh`
  - `grep -n -E 'runs-on|- name:' .github/workflows/ci.yml`（lint 20 個、macOS 6 個）
  - `grep -n 'CODE_EXT=' scripts/check-claude-md.sh`
  - `grep -n '而不是讓整條 filter 報錯' install-dd-pipeline.sh`（:13、:637）
  - `grep -n 'backup_before_overwrite "commands"' install-dd-pipeline.sh`（:921、:957，皆帶 target）
- 核對成立的前提：backup 呼叫點 9 個，其中 7 個接 `cp "$source" "$target"`、2 個（skills、命名空間指令）接 `rm -rf` + `cp -r`；`backup_before_overwrite` 的 `cp -r` 在 :194；skills、agents、指令、scripts、output styles 不帶 `--force` 也會備份後覆蓋（:528–530、:604–606、:921–923、:1006–1011、:1046–1051）；`show_completion` 無條件印 Agents 與 Plugin 段；`create_commands` 刪舊指令前沒備份；lint job 20 個 step、macOS job 6 個 step；README.md:38 只有 skill-creator 的安裝指令；CHANGELOG.md:19 有 `## 未發布`。
- 未執行任何測試、安裝、容器、網路查詢。

【批評】

整份計畫沒有達到「重大」三條件（常走、會錯、後面關卡抓不到）的項目。下列都不是重大，但有些會讓執行者照計畫做時踩到。

- 輪1-R1-1｜中｜②｜S1-1、S1-2、S1-4 的 commit 會被 pre-commit gate 擋下。它們改到根目錄的 `install-dd-pipeline.sh` 與 `tests/test-install.sh`，gate 對含 `.sh` 的目錄要求該目錄的 CLAUDE.md 同批 staged。計畫把根目錄與 `tests/` 的 CLAUDE.md 排在「S1 的文件同步」，要跟最後一個小任務或步驟 6 一起 commit。SKIP 逃生口只給步驟 2 檢查點，而且跳過的目錄會擋之後每個正常 commit。計畫沒提這個順序衝突。｜證據：`scripts/check-claude-md.sh:39`（CODE_EXT 含 `sh`）、`:271–279`（同批未 staged 即擋）；`scripts/CLAUDE.md:8–10`；`README.md:126`；計畫「S1 的文件同步」段。

- 輪1-R1-2｜中｜②｜驗收寫「本機 ci.yml 20 個 step 全過」，但這 20 個只是 lint job（`ci.yml:10–559`）。macOS job（`ci.yml:564–595`，6 個 step）含「確認 /bin/bash 是 3.2」與 bash 3.2 下的 `test-install.sh`，計畫沒把它們列進驗收，所以新程式碼在 bash 3.2 上的相容性沒有被驗。另外，計畫自己說 debian 容器裡沒有 jq 與 python3，因此 `test-install.sh` 全檔在 GNU 環境從未跑過，T1–T9 在 GNU 上的行為只能等 push 後由 CI 發現。｜證據：`ci.yml` 的 job 與 step 清單；計畫 S1 驗收與 S1-1 驗證段。

- 輪1-R1-3｜中｜②｜T1 的「先紅」證據不在測試檔裡。計畫只在 debian 容器裡手打片段驗證 `cp -r` 的行為，而 T1 本身在 macOS 修之前就是綠的（計畫自己寫的）。§3.5 要求新測試要先看到紅，且紅的內容要讀過。目前 `tests/test-install.sh` 裡沒有任何 symlink 情境，T1 在 GNU 上沒被看到紅過。｜證據：`tests/test-install.sh` 全檔（87 行）無 symlink 情境；計畫 S1-1 驗證段。

- 輪1-R1-4｜小｜②｜S1-4 字面寫的 `backup_before_overwrite "commands"` 缺 target 參數。函式第一行 `[ -e "$target" ] || return 0`（`install-dd-pipeline.sh:189–190`）在 target 為空時會靜默 return 0：不備份、不報錯。T8 會抓到，所以不是無聲錯誤，但照字面做會先紅再修。｜證據：`install-dd-pipeline.sh:187–195`；計畫 S1-4 做法第一點。

- 輪1-R1-5｜小｜②｜S1-2 的規則與 A4 衝突。S1-2 寫「頂層不是物件 → 兩條路徑都算失敗、不改檔」，但 `plugin_enabled_state` 對頂層非物件本來就回 `none`（jq 端 `if type != "object" then "none"`，python 端 `isinstance(data, dict)`）。A4 要保留這個設計。照 S1-2 字面執行，會把它改成失敗。｜證據：`install-dd-pipeline.sh:397–410`；計畫 S1-2 與 A4。

- 輪1-R1-6｜小｜②｜`mcp_scope` 的 jq filter 刻意不報錯，檔內註解寫明「而不是讓整條 filter 報錯（報錯會被誤讀成「沒安裝」）」。S1-2 要改成頂層非物件就報錯，等於反轉這條既有設計，但計畫的假設清單只保護 `plugin_enabled_state`（A4），沒有提到這條註解。｜證據：`install-dd-pipeline.sh:637`（與 :13 同句）。

- 輪1-R1-7｜小｜②｜S1-3 的理由不成立。計畫說新開沙盒是因為現有 SANDBOX 的「無備份產生」斷言「靠 plugin 步驟被跳過才成立」。但 `install_plugins`（`install-dd-pipeline.sh:730–878`）沒有任何 `backup_before_overwrite` 呼叫，所有呼叫點都在別的函式（見上方 grep）。plugin 步驟跑不跑，不影響那個斷言。開新沙盒仍可以，但寫進計畫的理由是錯的。

- 輪1-R1-8｜小｜②｜S1-2 把移除路徑上頂層 `null` 的 settings.json 寫成「解析失敗，請手動移除」，安裝路徑寫成「檔案可能損毀」。但檔案是合法 JSON（`null`），這兩句都會講錯原因。｜證據：計畫 S1-2 第一條；`install-dd-pipeline.sh` 內 uninstall 的 `json_edit` 失敗訊息與 `install_plugins` 的「更新失敗（檔案可能損毀）」。

- 輪1-R1-9｜小｜②｜S2-1 第 1 點寫「會把 OFFICIAL_PLUGINS 列的官方 plugin … 拿掉（你自己裝的也一樣）」，容易被讀成會拿掉使用者其他 plugin。實際 `uninstall()` 只迴圈 `OFFICIAL_PLUGINS` 那兩個 key。README 文字要寫清楚「只限這兩個」。｜證據：`install-dd-pipeline.sh` 的 `uninstall()` 內 `for plugin in "${OFFICIAL_PLUGINS[@]}"`（`uninstall()` 自 :1059 起）。

【需要外部查證】

- 輪1-R1-10｜中｜S1-1 的 `cp -RL` 修法只處理頂層懸空連結（`[ -e ]` 已擋掉），沒處理「symlink 目錄裡含懸空的內層連結」的情況。若 GNU `cp -RL` 對這種情況回非零，`set -e`（`install-dd-pipeline.sh:8`）會讓整支安裝中止。需要：在 debian 容器裡實跑一次這個情境。本次未執行。

- 輪1-R1-11｜小｜S1-2 依賴 `jq -e 'type == "object"'` 對空輸入回 exit 4。這在 jq 1.6 與 1.7 的文件裡是這樣寫的，但 debian bullseye（jq 1.6）與 macOS（Homebrew jq）的實際行為沒查證。需要：在對應版本的 jq 上跑一次空檔案與 `null` 檔案。

- 輪1-R1-12｜小｜計畫 A2 說 `settings.json` 「可能放 token」，作為不備份的理由。本次沒有查到依據，需要查 Claude Code 設定檔格式或文件後再寫進計畫。
