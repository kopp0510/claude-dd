【派工】派了 4 個審查者，沒有重派也沒有補派。
- 輪1-R1：前提成不成立
- 輪1-R2：漏掉的同步點
- 輪1-R3：驗證抓不抓得到錯
- 輪1-R4：全面，偏重範圍、順序與使用者決定

計畫有兩段，動到安裝腳本、測試、兩份 README 和多份文件，牽涉面廣，所以比最低 3 個多派 1 個。

【讀檔檢查】
- 輪1-R1：過。抽查 install-dd-pipeline.sh:187–189，`local category="$1" target="$2"`／`[ -e "$target" ] || return 0` 對得上。
- 輪1-R2：過。抽查 skills/task-planner/SKILL.md:109，指路句原文對得上。
- 輪1-R3：過。抽查 install-dd-pipeline.sh:187–189，對得上。
- 輪1-R4：過。抽查 skills/task-planner/SKILL.md:133（開工標 `IN_PROGRESS`）與 install-dd-pipeline.sh:843／:863 的寫入順序，都對得上。
- 沒有重派、補派。

【採納（重大）】
（無）

【採納（小事）】
- 輪1-R1-3／輪1-R2-3／輪1-R3-2｜S1-4 寫的 `backup_before_overwrite "commands"` 只傳一個參數，target 是空字串時函式直接 return 0，不會備份（已讀 install-dd-pipeline.sh:187–189）。T8 會變紅，所以不算靜默｜改成在迴圈裡、`rm` 之前逐檔呼叫 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`
- 輪1-R2-5（部分）｜「S1 的文件同步跟最後一個小任務或步驟 6 一起 commit」，其中「或步驟 6」和規則區塊衝突。規則要求 SKIP 欠下的 CLAUDE.md 補完才跑步驟 3–8，最後一個小任務要用正常 commit（已讀 skills/task-planner/SKILL.md:134–135）｜刪掉「或步驟 6」。寫明 S1-1～S1-3 用 `SKIP_DOC_CHECK=1`，S1-4 用正常 commit，連同根目錄與 `tests/CLAUDE.md` 一起送
- 輪1-R2-4／輪1-R3-4｜GNU 那一側的紅和綠來自 docker 裡手抄呼叫點的重現，T1 本身在 GNU 上從沒紅過。debian 映像沒有 node，完整安裝過不了環境檢查（已讀 install-dd-pipeline.sh:319–325）。ubuntu CI 要等 push 才會跑｜驗證裡註明「T1 本身的 GNU 紅綠要等 ubuntu CI」；或在 T1 裡加一則函式層的子測試（source 腳本後直接呼叫 `backup_before_overwrite`），讓它能在 debian 容器裡原樣跑出紅和綠
- 輪1-R3-9（外部查證項，查證後轉採納）｜S1-1 只修備份。之後的 `cp "$source" "$target"` 遇到 target 是 symlink 時，照樣把連結指到的外部檔（例如 dotfiles 裡那份）蓋成模板（通用知識：cp 寫入目的地 symlink 時會跟著連結寫）｜S2-1 第 2、3 項補一句：全域 `CLAUDE.md` 是 symlink 時，被改寫的是它指到的檔，原內容在備份目錄。`DD_PIPELINE_ARCHITECTURE.md`「可回復」那條也照這個意思寫
- 輪1-R3-7｜S2-1 第 1 項「（你自己裝的也一樣）」容易讓人讀成第三方 plugin 也會被移除，實際上只動 `OFFICIAL_PLUGINS` 列的 key｜改成「這兩個官方 plugin 就算是你自己先裝的，也一樣會被拿掉；其他 plugin 不動」
- 輪1-R4-5｜S2-1 第 1 項寫「不動各專案的 hook」，沒講 uninstall 會刪掉 `check-claude-md.sh`。之後專案 hook 只印警告就放行，gate 等於停了（已讀 commands/dd-init.md:203）｜補一句：移除後各專案的 pre-commit 會印「CLAUDE.md gate 沒執行」，然後照樣放行 commit
- 輪1-R2-7／輪1-R4-7｜成本數字的單位和限制容易寫錯。11.8 分是「單次 code-reviewer subagent」的中位數，來源是一台機器約 30 天的紀錄，不是「每段步驟 4」的時間。269s、5.13 美元那組每格 n=2，量測檔自己寫「分不出差異」（已讀 docs/measurements/2026-10-23-reviewer-real-sessions.md:4、86、198、319、361）｜S2-1 第 6 項規定：每個數字都寫明單位（每次 reviewer 還是每發），附機器範圍與 n，並照搬量測檔的限制句
- 輪1-R4-3｜`install_plugins` 先寫 settings.json 再寫 installed_plugins.json（已讀 install-dd-pipeline.sh:843、:863）。照 S1-2 讓 installed_plugins.json 是空檔的案例失敗時，settings.json 已經寫成 `enabledPlugins[key]=true`，但印的是「跳過」。這和定案的「不改檔」、S1-4 的「只列真的成功的」字面不符｜S1-2 定案寫明這個情況下 settings.json 最後長什麼樣（維持現況或先驗兩檔再寫），T2 的代表案例直接斷言它

【駁回】
- 輪1-R1-1／輪1-R2-6｜計畫沒列步驟 3–8｜照抄進設計文件的規則區塊已經規定每段要跑完步驟 3–8 才能標 DONE（SKILL.md:135–136），驗收欄也是寫「步驟 5 要看到什麼」，計畫已安排。
- 輪1-R1-2｜docs/reviews/ 存在，S2 的 `--start-segment` 會要求先有上一段的報告｜這就是步驟 4 落地報告的規定，規則已涵蓋；而且缺了會被大聲擋下。
- 輪1-R1-4／輪1-R3-3｜中間的小任務 commit 會被 gate 擋｜規則區塊允許小任務用 `SKIP_DOC_CHECK=1`（SKILL.md:134），被擋也會報錯。真正的缺口已經收在 R2-5 那條。
- 輪1-R2-5（其餘部分）｜scripts/CLAUDE.md:10 和 task-planner 對 SKIP 的說法矛盾｜那是範圍外的既有文件，這份計畫照 task-planner 規則走就行。
- 輪1-R2-1／輪1-R3-1／輪1-R4-1｜進度表沒寫根目錄 CLAUDE.md 的指路句｜這份是 task-planner 步驟 4 的草稿（SKILL.md:74）。步驟 5 寫設計文件時規定一定要加指路句（SKILL.md:108–109、115），計畫的流程已經安排；計畫裡「不改既有規則」那句只管 S1 的文件同步。
- 輪1-R2-2／輪1-R4-2｜進度表全是 TODO、commits 欄空白｜這是骨架的正確初始狀態（SKILL.md 的範例也是 TODO、空白）。開工時記起點、標 IN_PROGRESS 寫在規則區塊（SKILL.md:133）。
- 輪1-R1-5／輪1-R3-6／輪1-R4-4｜A4 和 S1-2 的定案矛盾｜S1-2 只列安裝、移除、`mcp_scope` 三者的結論，沒有包含 `plugin_enabled_state`。事實 F6 寫它 15 例本來就一致，T2 的等價比對照樣涵蓋它，兩者不衝突。
- 輪1-R3-5｜92 例的探針重現不了｜計畫寫明 T2 就是「把探針的案例表搬進 tests/test-install.sh」，搬完之後在 repo 裡重現得了。
- 輪1-R3-8｜逐句核對表沒有機械檢查｜這是文件驗證本身的限制，計畫已經用人工核對表加兩份 README 並排比對來處理，不算缺失。
- 輪1-R2-8／輪1-R4-6｜本機那 20 個 step 沒驗到 bash 3.2｜tests/test-install.sh 和 install-dd-pipeline.sh 的 shebang 都是 `#!/bin/bash`（已讀兩檔第 1 行），在 macOS 本機跑 ci.yml:557 的 `tests/test-install.sh` 用的就是 3.2。
- 輪1-R4-8｜A2「settings.json 可能放 token」沒附來源｜settings.json 可以帶 `env` 等含祕密的設定，這是通用知識；而且這句只是不加備份的理由，不影響執行。
- 輪1-R4-9｜範圍是自己選的、沒問使用者｜A1 已經明寫這個假設和理由。使用者說「請你優化改善」之前，上一則剛建議先修第 4 項；而且使用者可以隨時喊停。
- 輪1-R4-10｜T3–T9 違反 §3.5（不主動新增測試）｜task-planner 步驟 4 會把測試清單當題目問使用者（SKILL.md:74、96、99），使用者選了才算要求加，流程已經安排；事實也寫明這一點。
- 輪1-R4-11｜HEAD 和 commit 數對不上｜這個工作目錄是拋棄式副本，檔案內容和行號都對得上，那些 commit 數的事實不影響計畫怎麼做。
- 輪1-R1-6／輪1-R2-9｜`jq -e` 對空輸入回 4 需要查證｜jq 手冊寫明沒產生任何結果時 `-e` 回 4（通用知識）；何況設計只靠「非 0」，確切數字不承重。
- 輪1-R1-7｜uninstall 的範圍沒核對｜我用 `awk '/^uninstall\(\)/,/^}/' install-dd-pipeline.sh | grep -n 'CLAUDE.md\|backups'` 查，回 1、沒有命中，和 F11 一致；計畫也安排了逐句核對表。
- 輪1-R2-10／輪1-R3-10｜agent 備份檔的上游授權｜A7 已經把這件事交給使用者決定。

【需使用者決定】
（無）

【需要外部查證】
（無）

【結論】
通過
