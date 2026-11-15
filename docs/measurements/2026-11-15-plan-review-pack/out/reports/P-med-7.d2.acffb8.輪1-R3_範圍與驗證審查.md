【我查了什麼】
- 讀完審查包 `P-med-7.pack.md` 全文（166 行，一次讀完，最後一行是 `<<<審查包結束>>>`）。
- 讀 `install-dd-pipeline.sh`：150–260（`command_exists`、`ask`、`backup_before_overwrite`、`jq_inplace`、`py_inplace`、`json_edit`）、380–470（`plugin_enabled_state`）、625–690（`mcp_scope` 與 `--check` 輸出字串）、725–850（`install_plugins`）、1059–1150（`uninstall`）、1155–1262（全域 CLAUDE.md 四種情境、`show_completion`）、1290–1400（main）。
- 讀 `tests/test-install.sh` 全 87 行。
- 指令與結果：
  - `grep -n 'command_exists\|BASH_SOURCE\|SCRIPT_DIR=' install-dd-pipeline.sh`
  - `grep -n 'backup_before_overwrite' install-dd-pipeline.sh`：9 個呼叫點，全部傳兩個參數
  - `grep -n -i jq .github/workflows/ci.yml`：無結果，CI 沒有安裝 jq 的步驟
  - `grep -n '進度' CLAUDE.md`：沒有「進度以…為準」的指路句；第一個 `##` 在第 5 行
  - `ls docs/designs/`：7 份設計文件，目錄下沒有 CLAUDE.md
  - `grep -n 'deprecated_dd\|已啟用的 Plugin\|僅 \|無法判定'`：計畫引用的字串都存在（行 889、1254、683、685）
- 沒有跑任何測試、安裝或容器。

【批評】

輪1-R3-1｜重大｜T2 呼叫真的 `uninstall` 時，若沒設 `ASSUME_YES=true`，移除 JSON 的那段根本不會執行，兩條路徑都「沒動檔」，結論行與 JSON 必然相等，T2 會綠。計畫要比對的 uninstall 不一致（空檔、`null`、`{"enabledPlugins":null}` 等，見事實 F6）全部被遮住，S1-2 宣稱的「紅在那 16 例」與改碼後的 uninstall 分支都沒有任何一處會紅。① T2 是 S1-2 的主要驗證，每次都會跑；② 計畫的驗收條件（pack 34、86）指定「呼叫真的 uninstall」，卻沒寫要設 ASSUME_YES；③ 錯的 uninstall 修法會綠燈通過，code-review 與 gate 只看 diff，抓不到。
證據：`install-dd-pipeline.sh:1082-1088`：`if [ "${ASSUME_YES:-false}" = true ]; then REPLY="y" else ask "確定要移除嗎？[y/N] " "N"; fi`，接著 `if [[ $REPLY =~ ^[Yy]$ ]]` 才進入移除（含 settings.json 與 installed_plugins.json 的 `json_edit`，行 1122–1145）。非互動 stdin 下 `ask` 採預設 N（行 225–233）。pack 86 寫「呼叫真的 `uninstall`」，pack 34 未提 ASSUME_YES。

輪1-R3-2｜重大｜計畫開了進度表，卻沒有在根目錄 CLAUDE.md 第一個 `##` 之前加指路句。全域 CLAUDE.md §4.4 明文規定「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，並說明少了這句，下一個 session 會看不到表、重估段落數、另開第二張，先前的進度與 commit 範圍就靜靜遺失。① 每次開表都會經過；② 計畫的「S1 的文件同步」（pack 52–57）與段落內容都沒有這一項，事實也已確認根 CLAUDE.md 沒有這句（pack 6；`grep -n '進度' CLAUDE.md` 只命中無關的第 41、187、352 行）；③ gate 與 CI 都不檢查這句。

輪1-R3-3｜中｜S1-4 要求 `backup_before_overwrite "commands"`，只給一個參數。函式簽名是 `local category="$1" target="$2"`，接著 `[ -e "$target" ] || return 0`（`install-dd-pipeline.sh:187-190`）。target 為空時會靜默返回、不備份，之後的 `rm` 照跑。③ 不成立，因為 T8（pack 92）會要求備份目錄裡有 `dd-help.md`，所以這是寫錯但有測試接住的缺陷。計畫應該寫成傳入每個要刪的檔案路徑。證據：pack 47；installer 187–190。

輪1-R3-4｜中｜T1 的紅燈證據沒有落在 `tests/test-install.sh` 本身，而是 pack 24 的 debian 容器手寫片段。這個容器沒有 jq 與 python3（pack 163），跑不了 `test-install.sh`；本機 macOS 上 `cp -r` 本來就是綠的（pack 24）；ubuntu CI 對這 34 個 commit 從未跑過（pack 147）。所以「T1 在 ubuntu 上的測試會紅」從來沒被看過。如果 T1 的沙盒設置有誤（例如 symlink 建錯、沒有走到 `--force` 分支），它修前修後都會綠，後面沒有任何關卡能發現。③ 成立，這是驗證方式缺口。證據：pack 24、147、163；installer 1194（`--force` 情境 3 的 `backup_before_overwrite "global"`）。

輪1-R3-5｜中｜S1-4 把兩個不相干的修正（清舊指令檔前備份、完成訊息只報實際做了的）放進同一個 commit（pack 50）。全域 CLAUDE.md §5.2 規定「不合併多個邏輯變更為單一 commit」。③ 不成立（沒有隱藏的錯），但這是違反使用者既定規則。

輪1-R3-6｜小｜T7 要求「SCRIPT_DIR 指到假目錄」（pack 91）。但 `install-dd-pipeline.sh:26` 在 source 時會重新計算 `SCRIPT_DIR`。若測試先設 SCRIPT_DIR 再 source，`validate_skill_hooks` 掃的是真實 repo、exit 0，T7 會紅但紅在錯的地方。計畫要寫明必須在 source 之後覆寫。證據：installer 26、491。

輪1-R3-7｜小｜S2 第 2 條（不帶 `--force` 也會換掉 skill／agent／指令／腳本／風格的內容）的依據是 T5（pack 89），但 T5 的寫法沒說要「不帶 `--force`」重裝。若 T5 用 `--force` 跑，證據就不支撐 README 的說法。另外 S2 的驗證是自己寫的「逐句核對表」，沒有機械檢查。

輪1-R3-8｜小｜S1 驗收條件「等價表探針 92 例不一致數從 16 變 0」與 debian symlink 重現，都依賴 scratchpad 裡的探針腳本（pack 131 明寫「腳本在 scratchpad，不在 repo」）。這些驗收無法在 repo 內重跑，之後的 session 也無法核對。

【需要外部查證】

輪1-R3-9｜中｜CI 沒有安裝 jq（`grep -i jq ci.yml` 無結果）。若 `macos-latest` runner 沒有 jq，macOS job 上 T2 的 jq 分支永遠走不到，兩條路徑的比對會變成 python 對 python，全綠也沒有鑑別力。若成立，T2 在 macOS 上的 jq 比對就失效。需要查 GitHub 的 `macos-latest` 與 `ubuntu-latest` runner image 文件，確認內建 jq 與 python3 的版本。離線無法確認。

輪1-R3-10｜小｜計畫依賴「空輸入時 `jq -e` 回 4」（pack 33）。這個 exit code 在 ubuntu 與 macOS 上的 jq 版本是否一致，需要查 jq 各版本的文件或實測；離線無法確認。
