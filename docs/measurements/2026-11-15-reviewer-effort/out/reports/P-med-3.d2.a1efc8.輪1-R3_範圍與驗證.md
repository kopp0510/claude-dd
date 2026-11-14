【我查了什麼】
- 讀 `install-dd-pipeline.sh` 的 `command_exists`／`ask`／`backup_before_overwrite`（150–260 行）、`plugin_enabled_state`（397 行起）、`mcp_scope`（630 行起）、`install_plugins`（730–870 行）、`create_commands`（879 行起）、`install_global_claude_md`（1160–1240 行）、`show_completion`（1241 行起）、檔尾 source guard。
- 讀 `tests/test-install.sh` 全檔（87 行，第 7 行 `set -e`），`tests/CLAUDE.md` 第 10 行那一列。
- `grep -n 'backup_before_overwrite' install-dd-pipeline.sh`：定義在 187，呼叫點在 528、530、604、921、957、1006、1046、1194、1216、1227，730–870 之間沒有呼叫。
- `grep -n 'jq\|python3' .github/workflows/ci.yml`：只有 47–49 行的 python3 一處，沒有安裝 jq 或 python3 的 step。`ci.yml` 557 行是 ubuntu job 跑 `tests/test-install.sh`，594 行是 `/bin/bash tests/test-install.sh`。
- `grep -n '^## ' CLAUDE.md`：第一個 `##` 在第 5 行；`grep -n '進度以' CLAUDE.md`：沒有「進度以…為準」那句。
- `grep -n '新增\|同時改\|同批\|要一起\|手動同步' CLAUDE.md tests/CLAUDE.md scripts/CLAUDE.md`：與本計畫相關的規則是 CLAUDE.md 273 行那段「CI 不驗、只能手動同步的區塊」，以及 `DD_PIPELINE_ARCHITECTURE.md` 的 CI 防線表（119–137 行）。
- `ls docs/designs`：7 份，計畫的數字正確。`CHANGELOG.md` 有 `## 未發布`。
- 計畫引的 README 句子（第 19、67、70、156 行）在檔案中存在。
- 找不到計畫 F6 所說的 92 例探針腳本；`<暫存區>/s2/probe` 下只有 p1–p3 的 jsonl 執行產物，無法重核「16 例」。

【批評】

輪1-R3-1｜重大｜進度表開了，但計畫沒有在根目錄 CLAUDE.md 加指路句。全域 §4.4 規定開表的同時要在根目錄 CLAUDE.md 第一個 `##` 之前加「進度以 docs/designs/<檔名>.md 的「進度表」為準」。計畫的 S1 文件同步只寫「只補這次留下的坑」，沒有這一句。之後的 session 會看不到這張表，可能重估段落數、另開第二張表。沒有任何 gate 或測試會檢查這句是否存在。證據：根目錄 CLAUDE.md 第 5 行是第一個 `##`（`grep -n '^## ' CLAUDE.md`），內文沒有「進度以」一句（`grep -n '進度以' CLAUDE.md` 無結果）；全域 CLAUDE.md §4.4 的「建立指路」條文（系統提供的全域規則）。

輪1-R3-2｜小｜S1-2 的定案與 A4 互相矛盾。S1-2 寫「頂層不是物件 → 兩條路徑都算失敗、不改檔」，但 A4 說保留 `plugin_enabled_state` 對「頂層不是物件」回 `none` 的設計。現行碼是 `if type != "object" then "none"`（`install-dd-pipeline.sh` 約 402–405 行）。T2 的「兩條路徑結論相同」斷言兩邊都會過，所以如果照 S1-2 的文字去斷言「失敗」，會寫進錯的結論，而且不會紅。需要在計畫裡把這個函式的定案寫清楚。

輪1-R3-3｜小｜紅燈的判讀方式沒考慮 `set -e`。`tests/test-install.sh` 第 7 行是 `set -e`。T2 要跑 92 個案例，如果某個被呼叫的函式在某個案例回非零，又沒有包進 `if` 或 `|| true`，整支測試會在中途結束，只印 exit 1，沒有任何斷言訊息。這種紅看起來像「紅了」，但不是 §3.5 要求的「紅在錯的結果」。計畫的變異測試（S1-3）也有同樣問題，而且沒有寫每一組變異要改哪一行。

輪1-R3-4｜小｜S1-3 的理由寫錯了。計畫說 SANDBOX 的「無備份產生」斷言「靠 plugin 步驟被跳過才成立」。實際上 `install_plugins`（730–870 行）沒有呼叫 `backup_before_overwrite`，所以跟 plugin 步驟是否跳過無關。另開新沙盒的做法仍可以，但理由應該改寫，否則下一個人照理由判斷會判錯。

輪1-R3-5｜小｜S1-1 對 `cp -RL` 的理由在這個呼叫點不可達。`backup_before_overwrite` 第 189 行是 `[ -e "$target" ] || return 0`，懸空連結在 `cp` 之前就返回，所以「`cp -RL` 遇懸空連結回 1、腳本有 set -e」這個情況走不到。計畫的做法本身沒問題，但如果把這個理由寫進程式碼註解，就會留下一句不成立的說明。

輪1-R3-6｜小｜T5、T8、T1 找備份目錄的方式沒有寫。備份目錄名是 `pre-install-$(date +%Y-%m-%d-%H%M%S)`（第 191 行），精度到秒。如果測試用 `ls` 通配、取第一個，可能撈到前一次執行的備份而仍然通過。計畫應該寫明用哪個路徑，並斷言只有一個目錄。

輪1-R3-7｜小｜驗證只在本機 macOS 和 debian 的 T1 上做，T2–T9 的 GNU 行為和 jq／python3 版本差異要到 push 後 CI 才看得到。計畫的驗收寫「本機 ci.yml 20 個 step 全過」，但沒寫要用 `/bin/bash`（3.2）跑 `tests/test-install.sh`，也沒寫要在有 jq 與 python3 的 GNU 環境跑。`ci.yml` 沒有安裝 jq 與 python3 的 step（`grep -n 'jq\|python3' .github/workflows/ci.yml` 只有 47–49 行），所以兩個 job 能否跑 jq 分支取決於 runner 映像。這一點需要外部查證（見下）。

輪1-R3-8｜小｜S2 的文字正確性只靠計畫自己寫的「逐句核對表」。根目錄 CLAUDE.md 273 行那段列的是「CI 不驗、只能手動同步」的區塊，README 的安裝步驟、指令一覽、前置需求都在裡面，沒有機械檢查會抓錯。如果核對表是同一個 agent 寫的，錯誤句子可能一路過到 push。建議核對表交給另一個讀者，或至少把每一句的依據行號貼在 README 的 commit 說明裡。

【需要外部查證】

輪1-R3-9｜小｜macOS runner（`macos-latest`）上是否預裝 jq 與 python3。`ci.yml` 沒有安裝 step。如果 jq 不在，T2 的 jq 分支在 macOS job 不會被執行，`jq -e` 的修法只在 ubuntu 被驗到。需要查 GitHub runner 映像清單。

輪1-R3-10｜小｜`jq -e 'type == "object"'` 對空輸入回 exit 4，計畫的 S1-2 依賴這個行為來判定「空檔失敗」。需要在 ubuntu 的 jq 版本（目前 1.7 系列）和 macOS 的 jq 版本上實測一次，確認 exit code 相同。

輪1-R3-11｜小｜計畫 F6 的 92 例探針與「16 例不一致」，探針腳本在 scratchpad 中找不到，無法重核。需要作者提供腳本路徑或直接把案例表搬進 repo 後重跑，再確認 16 這個數字。
