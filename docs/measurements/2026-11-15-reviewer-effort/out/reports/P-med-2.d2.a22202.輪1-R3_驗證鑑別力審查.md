【我查了什麼】

- 讀 `install-dd-pipeline.sh`：第 8 行 `set -e`；第 26–27 行 `SCRIPT_DIR`、`CLAUDE_DIR` 在 source 時由 `BASH_SOURCE`、`$HOME` 算出；第 156–158 行 `command_exists`；第 187–195 行 `backup_before_overwrite(category, target)`，開頭 `[ -e "$target" ] || return 0`；第 402、413、635、646、734、798、813、1122 行的 jq／python3 分支全部經過 `command_exists`；第 921 行與第 957 行的呼叫都是兩個參數；第 1194–1227 行全域 CLAUDE.md 的非互動預設是 `k`（保留本機版）；第 742 行 plugin 目錄在 `$CLAUDE_DIR/plugins/marketplaces/...`；第 1402 行 source guard。
- 讀 `tests/test-install.sh` 全檔（87 行）：第 8 行 `set -e`；`SANDBOX` 的「無備份」斷言在第 50、55 行。
- 讀 `.github/workflows/ci.yml`：`lint` 在 ubuntu-latest（第 12 行），`tests/test-install.sh` 在 ShellCheck 清單（第 36 行）與 ubuntu 的跑測試 step（第 557 行）；macOS job 在第 564 行、第 594 行。
- 讀 `tests/CLAUDE.md` 第 10 行 `test-install.sh` 那一列。
- grep：`grep -n 'backup_before_overwrite' install-dd-pipeline.sh`、`grep -n 'command_exists\|command -v\|which ' install-dd-pipeline.sh`、`grep -n 'set -e' tests/test-install.sh`。
- 計畫的 F1–F20 事實，我只重驗了與測試設計直接相關的部分（上面列的）；F6 的 92 例探針與 F15 的 CI 紀錄沒有重跑。
- 沒有跑任何測試、安裝或容器。

沒有找到符合三條件（常走、會錯、錯了沒有後續關卡抓）的重大缺失。下面三條是中等，第一條是計畫文字會寫出錯誤呼叫。

【批評】

輪1-R3-1｜中｜S1-4 寫「清 `deprecated_dd` 那 5 個舊指令檔之前先 `backup_before_overwrite "commands"`」，只給一個參數。函式的第二個參數是 target，這裡會是空字串，`[ -e "" ]` 為假，函式直接 `return 0`，什麼都不備份也不報錯。計畫的 T8 會抓到（它斷言備份裡有 `dd-help.md`），所以不是靜默通過，但照計畫文字寫出來的程式碼是錯的。應改寫成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`，與第 957 行的用法一致。
證據：`install-dd-pipeline.sh:187-195`（`local category="$1" target="$2"`；`[ -e "$target" ] || return 0`）；`install-dd-pipeline.sh:921` 與 `:957`（兩個參數）；計畫 S1-4 文字。

輪1-R3-2｜中｜T2 在 `tests/test-install.sh` 裡於子 shell source 安裝腳本。測試檔第 8 行與安裝腳本第 8 行都是 `set -e`，子 shell 會繼承。計畫要測的「失敗路徑」（空檔、`null`、`[null]`）會讓函式回非 0，子 shell 就在那裡中止。計畫沒寫 `|| true` 或怎麼收 rc。如果 harness 是 `out=$(...)` 然後比兩條路徑的輸出與檔案，兩邊都在同一處中止、檔案都沒變，等價斷言會全綠。只有計畫另外寫的「三類代表案例直接斷言結論文字」能抓到，所以這條是中，不是重大。
證據：`tests/test-install.sh:8`、`install-dd-pipeline.sh:8`；計畫 T2 與 S1-2 驗證文字。

輪1-R3-3｜中｜T1 的紅綠證據不是它自己的測試。計畫的 GNU 紅綠是在 debian 容器裡手寫一段「source 安裝腳本、呼叫 `backup_before_overwrite`、再 `cp`」，沒有跑 `tests/test-install.sh` 裡的 T1。T1 在 ubuntu CI job 上的紅，只能 push 後才看得到；計畫的 S1 驗收是「本機 ci.yml 20 個 step 全過」，本機是 macOS，計畫自己承認 T1 在 macOS 上修之前就是綠的。F15 說本機多出的 34 個 commit 從來沒在 ubuntu job 上跑過。結果是：T1 在它真正執行的環境裡，修之前是不是紅，沒有任何驗收會看到。
證據：計畫 S1-1 驗證段；`.github/workflows/ci.yml:12`（ubuntu-latest）與 `:564`（macos-latest）；計畫 F15。

輪1-R3-4｜小｜T7 要讓 `SCRIPT_DIR` 指到假目錄。`SCRIPT_DIR` 在 source 當下由 `BASH_SOURCE` 算出（`install-dd-pipeline.sh:26`），所以測試必須在 source 之後才覆寫，計畫沒寫順序。`validate_skill_hooks` 用的是 `find "$SCRIPT_DIR/skills"`（F13）。

輪1-R3-5｜小｜T3–T7 的變異驗證寫「改那一行、確認那一組變紅、紅在斷言」，但沒指定每組要改哪一行。計畫 S1-3 其實是在檢查「改回舊版會紅」這件事，應該逐組寫出變異位置，否則執行的人可能選到一個會讓整個功能消失的地方（tests/CLAUDE.md 的「變異方向」一節就是這個陷阱）。

【需要外部查證】

輪1-R3-6｜小｜T2 的 python3 路徑靠 `command_exists` 覆寫來走到，前提是 jq 與 python3 在 ubuntu-latest 與 macos-latest 的 runner 上都預裝。我的判斷是 ubuntu-latest 有 jq 與 python3，macos-latest 的 jq 是否預裝我不確定。為什麼需要外部查證：這決定計畫說的「CI 上兩條路徑都會跑到」在 macOS job 上是否成立，只能看 GitHub runner 的映像清單，本機查不到。
