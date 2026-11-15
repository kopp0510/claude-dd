【我查了什麼】
讀完 pack（166 行，分兩段 300 行讀取）。repo 根目錄：`<WORK>/P-med-4`。以下路徑都相對於它。

- `find . -name CLAUDE.md`：列出各層 CLAUDE.md。計畫會動的是根目錄與 `tests/CLAUDE.md`。
- `grep -rn 'uninstall'`、`'翻譯'`、`"don't install"`、`'test-install'` 於 `*.md`：`README.md:70`、`README.zh-TW.md:71`、`DD_PIPELINE_ARCHITECTURE.md:70,75`、`tests/CLAUDE.md:10`、`DD_PIPELINE_ARCHITECTURE.md:137`。翻譯句與「don't install the gate」句在 `README.md:19,156` 與 `README.zh-TW.md:20,167`，計畫有列。
- `grep -n '進度以' CLAUDE.md` 無結果，根目錄沒有指路段。
- `grep -n '已啟用的 Plugin|enabledPlugins|dd-help'`：沒有其他文件引用計畫要改的完成訊息文字。
- `install-dd-pipeline.sh`：`backup_before_overwrite` 在 187–195 行；`create_commands` 的 `deprecated_dd` 在 889 行；`create_global_claude_md` 在 1160–1230 行（非互動預設 `k`，見 1211 行）；`validate_skill_hooks` 在 463–491 行；`command_exists` 在 156 行。
- `skills/task-planner/SKILL.md` 17、109、131–137 行；`scripts/CLAUDE.md` 7–10 行；`templates/global/CLAUDE.md` 446、511 行。
- `.github/workflows/ci.yml`：shellcheck 清單與 `/bin/bash tests/test-install.sh` 在 594 行（只在 macOS job）。
- `agents/code-reviewer.md:4` 是 `model: opus`。
- `docs/measurements/2026-10-23-reviewer-real-sessions.md` 方法段與第 86 行。

【批評】

輪1-R2-1｜重大｜計畫建立進度表，卻沒寫「根目錄 CLAUDE.md 第一個 `##` 之前加指路段」，也沒寫指路段的移除與對應 commit。根目錄 CLAUDE.md 只被交代「只補這次留下的坑、不改既有規則」。下一個 session 讀根目錄 CLAUDE.md 會看不到進度表，可能重估段落數、另開第二張表，進度與 commit 範圍就這樣丟掉。這條規則明說是 task-planner 步驟 5 的必做項，所以不是計畫的選擇。gate、code-review、測試都不檢查指路段是否存在。｜證據：`skills/task-planner/SKILL.md:109` 原文 `` `進度以 docs/designs/<檔名>.md 的「進度表」為準：開工先讀表，照表下方的規則做。` ``；`SKILL.md:136` 規定全部 DONE 後要刪掉這段；`grep -n '進度以' CLAUDE.md` 無結果；計畫第 54 行只寫「只補這次留下的坑」。

輪1-R2-2｜小｜計畫的進度表全部是 `TODO`、commits 欄空白，沒有寫開工時的 `--start-segment`、把段落標 `IN_PROGRESS`、commits 欄填 `<起點>..`，也沒寫「標 DONE 時補終點」。step 8 的範圍與接手都靠這些欄位。｜證據：`SKILL.md:133`（開工）、`SKILL.md:136`（標 DONE）；計畫第 12–13 行表格。

輪1-R2-3｜小｜S1-4 的做法寫 `backup_before_overwrite "commands"`，少了第二個參數。函式先檢查 `[ -e "$target" ] || return 0`，target 空字串時直接回 0，不備份也不報錯。現有呼叫點（921、957 行）都有傳 target。T8 會抓到，所以不是靜默通過，但照計畫字面寫會寫錯。｜證據：`install-dd-pipeline.sh:187-195`（`local category="$1" target="$2"`；`[ -e "$target" ] || return 0`）；計畫第 47 行。

輪1-R2-4｜小｜S1-1 說「T1 在本機修之前就是綠的」，所以真正的紅燈只能在 GNU 上取得。計畫的 GNU 紅燈是手抄呼叫點重現（第 24 行），不是跑 T1 本身。ubuntu CI job 不在本機跑，所以 `tests/test-install.sh` 的 T1 在 GNU 上從未被證明會紅。計畫也沒有說明 debian:bullseye 能不能跑完整的 test-install（事實第 163 行：映像沒有 node、jq、python3；README 第 33 行寫 Node.js 是硬需求、安裝腳本會因缺少而退出，`install-dd-pipeline.sh:320` 有 node 檢查）。｜證據：計畫第 23–24 行與事實第 163 行；`README.md:33`；`install-dd-pipeline.sh:320`。

輪1-R2-5｜小｜S1-1、S1-2、S1-3、S1-4 的四個小任務 commit 都會改到根目錄的 `install-dd-pipeline.sh` 與 `tests/test-install.sh`，gate 要求同批 staged 對應目錄的 CLAUDE.md。計畫的 commit 訊息沒寫 `SKIP_DOC_CHECK=1`，也沒寫 CLAUDE.md 要不要同批 stage。另外兩份規則互相矛盾：`scripts/CLAUDE.md:10` 寫 SKIP 只供「迴圈檢查點 commit」，`skills/task-planner/SKILL.md:134` 卻允許每個小任務用 SKIP。計畫應該明確選一條。｜證據：`scripts/CLAUDE.md:7-10`；`SKILL.md:134`。

輪1-R2-6｜小｜計畫沒有寫每段要走步驟 3–8（code-simplifier、≥3 個 code-reviewer、再測、commit、沉澱、評分並修正 CLAUDE.md）。S1 驗收只提步驟 5，S2 也沒寫。全域 §3.9 與 task-planner 都要求段落標 DONE 前全部跑完。跳過步驟 4 不會報錯，後面的關卡也抓不到。｜證據：`templates/global/CLAUDE.md` §3.9（8 步清單）；`SKILL.md:17`、`SKILL.md:136`；計畫第 12–13 行驗收欄。

輪1-R2-7｜小｜S2 第 6 項要寫給陌生人看的「每段時間與費用」，拿來當依據的 `2026-10-23` 量測是單一機器、約 30 天內 session 的 subagent 耗時，會排除公司專案，中位數 11.8 分是「單一 code-reviewer 次數」的統計，不是「每段步驟 4 的時間」。`2026-10-24` 的 5.13 美元數字是另一種派工方式（主對話直接派、n=6）。計畫把兩者併在同一句裡，讀者會把單次 reviewer 時間當成每段的時間。｜證據：`docs/measurements/2026-10-23-reviewer-real-sessions.md` 方法段（「排除公司專案（路徑含 `-SRE`）。紀錄只保留到約 30 天前」）與第 86 行；`skills/dd-loop/SKILL.md:66`；計畫事實 F17 與 S2 第 6 項。

輪1-R2-8｜小｜驗證只寫「本機 ci.yml 20 個 step 全過」，那 20 個是 lint job（ubuntu）的 step。`/bin/bash tests/test-install.sh`（bash 3.2）只在 macOS job 跑，本機沒有驗。新加的 T2 大量使用 bash 3.2 的語法面，計畫沒有要求用 `/bin/bash` 跑一次。｜證據：`.github/workflows/ci.yml:594`；計畫第 12–13 行驗收欄；事實 F1、F14。

【需要外部查證】

輪1-R2-9｜小｜S1-2 依賴「`jq -e 'type == "object"'` 對空輸入回 4」，這是 jq 版本相關的退出碼。計畫的 T2 也依賴它。目前只有計畫的探針結果，沒有在 pack 裡找到 jq 手冊。｜為什麼需要：要用本機實際的 `jq --version` 跑一次空輸入，確認退出碼，否則不能保證 S1-2 的設計成立。

輪1-R2-10｜小｜計畫的 A7 把兩個 agent 備份檔的上游授權留給使用者。repo 裡只有 `LICENSE` 類檔案的存在與否（`agents/` 下），沒有上游原文。｜為什麼需要：要在 GitHub 上確認 `code-reviewer` 與 `code-simplifier` 的上游授權，計畫才能判斷 A7 是否真的只是措辭問題。
