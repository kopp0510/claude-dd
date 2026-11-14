【派工】
派了 4 個審查者，沒有重派也沒有補派。輪1-R1 查前提：安裝腳本裡各函式的實際行為，以及 S1-2 的修法在 jq、bash 3.2 下做不做得到。輪1-R2 查漏掉的同步點：各層 CLAUDE.md 的同批規則、進度表、指路句。輪1-R3 查範圍與驗證：T1–T9 有沒有鑑別力、`set -e`、子 shell。輪1-R4 查 S2 要寫進 README 的 8 項對不對，以及會不會撞上 CI。計畫有兩段，同時改安裝腳本、測試和兩份 README，所以比下限多派一個，讓 README 的事實核對單獨一路。

【讀檔檢查】
- 輪1-R1：過。抽查 `install-dd-pipeline.sh:635-637`，mcp_scope 的註解「而不是讓整條 filter 報錯（報錯會被誤讀成「沒安裝」）」對得上。另抽 `:395-410` 的 plugin_enabled_state 型別護欄，也對得上。
- 輪1-R2：過。抽查 `skills/task-planner/SKILL.md:108-109` 的指路句樣式，以及 `docs/reviews/CLAUDE.md` 開頭的「目錄存在就是開關」，都對得上。
- 輪1-R3：過。抽查 `install-dd-pipeline.sh:187-195`（`local category="$1" target="$2"`、`[ -e "$target" ] || return 0`）與 `:921`、`:957`（呼叫時都帶兩個參數），都對得上。
- 輪1-R4：過。抽查 `skills/dd-loop/SKILL.md:45`（沒有人工寫的程式碼就不派 agent）、`:66`（269s、5.13 美元，「n 小、同時改了三件事」），以及 `docs/measurements/2026-10-23-reviewer-real-sessions.md:13-16`（「引用下面的數字前先重跑」），都對得上。

【採納（重大）】
- 輪1-R3-3（輪1-R1-3 同義，一併併入）｜T1 本身在任何環境都沒有看到紅過。計畫自己承認 macOS 的 `cp -r` 會跟著連結，所以 T1 在修之前就是綠的；也就是說，在 macOS CI job 上它永遠不可能變紅。計畫在 GNU 上取紅、取綠，用的是 docker 裡手寫的片段（source 安裝腳本、呼叫 `backup_before_overwrite`、再 `cp`），不是 T1。ubuntu job 又從來沒跑過本機多出的 commit（F15）。結果是：這條回歸測試在它唯一可能變紅的環境裡有沒有鑑別力，沒有任何驗收看得到。舉例：「備份是一般檔」如果只用 `[ -f ]` 斷言，symlink 照樣會過。這三個條件都成立：S1-1 每次都要驗；計畫明文用片段取代測試自己的紅，違反全域 §3.5「紅了要讀紅的內容」；CI、review 都照計畫檢查，所以抓不到。｜查證：`install-dd-pipeline.sh:194` 是 `cp -r "$target" "$BACKUP_ROOT/$category/"`；`tests/test-install.sh` 全檔沒有 symlink 情境；`.github/workflows/ci.yml` 只有 ubuntu-latest 與 macos-latest 兩個 job。｜計畫要怎麼改：S1-1 的驗證改成在 GNU 容器裡跑 `tests/test-install.sh` 的 T1 本身。修前的安裝腳本要看到 T1 紅在「備份內容等於新內容」那條斷言，修後要轉綠。紅的那一行原文附在回報。斷言要明寫成 `[ ! -L <備份> ]` 加上內容比對，不能只寫 `[ -f ]`。另外注意：安裝腳本的環境檢查要求 git（`install-dd-pipeline.sh:330-356`，缺了就 `exit 1`），容器要先補上 git，或改用一個有 git 的 GNU 映像檔。計畫裡也要寫明 T1 在 macOS job 上沒有鑑別力。

【採納（小事）】
- 輪1-R1-4／輪1-R3-1｜S1-4 寫的 `backup_before_overwrite "commands"` 少了 target 參數，target 是空字串時函式會直接 `return 0`，什麼都不做｜改成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`，與 `:921` 的寫法一致。
- 輪1-R1-5｜S1-2 的第一類寫「頂層不是物件 → 失敗」，但 A4 要保留 plugin_enabled_state 對這種情況回 `none`｜第一類加一句「plugin_enabled_state 除外（A4）」，T2 的代表案例斷言也照這個排除。
- 輪1-R1-6｜`mcp_scope` 的 jq 註解（`:636-637`）寫的是「不要讓 filter 報錯」，S1-2 要讓頂層不是物件時報錯｜改碼時同批改寫這段註解。報錯後實際落到的是 `unparseable`（`:671-672`），不是「沒安裝」，註解照這個寫。
- 輪1-R1-7｜S1-3 開新沙盒的理由寫錯了：install_plugins（`:730-878`）沒有任何 `backup_before_overwrite` 呼叫，9 個呼叫點在 528、604、921、957、1006、1046、1194、1216、1227｜理由改成「不讓假 marketplace 與假設定檔干擾既有斷言」。新開沙盒這個做法本身不變。
- 輪1-R1-9｜「你自己裝的也一樣」讀起來像會拿掉使用者所有的 plugin｜改寫成「只拿掉 `OFFICIAL_PLUGINS` 列的那幾個 key（就算是你自己另外裝的）」。
- 輪1-R1-2／輪1-R4-5｜驗收寫的「本機 ci.yml 20 個 step」只是 lint job，本機是 macOS，ubuntu 那一側從來沒驗過｜驗收改寫成「本機（macOS、/bin/bash 3.2）跑 lint 的 20 個 step 加上 `tests/test-install.sh`」，並明寫 GNU 的行為在 push 之前只有容器驗得到，ubuntu job 在 push 前算未驗證。
- 輪1-R3-4｜T7 要在 source 之後才覆寫 `SCRIPT_DIR`（`:26` 在 source 時就由 `BASH_SOURCE` 算出來）｜T7 寫明這個順序。
- 輪1-R3-5｜T3–T7 的變異沒有寫要改哪一行｜每一組寫出變異的位置和預期紅在哪條斷言，避免挑到一改整個功能就消失的地方。
- 輪1-R2-5｜英文 README 連到只有中文的檔要標 *(Traditional Chinese)*（根目錄 CLAUDE.md「注意事項」）｜S2-1 補上：連到 CHANGELOG、UPGRADING 或 `docs/measurements/` 的量測檔時都標。
- 輪1-R4-1｜第 6 項只要求附日期、樣本數、檔名，沒有要求說明每個數字量的是什麼。11.8 分是單一 code-reviewer subagent 的耗時（量測檔 `:13`、`:86`），不是整個步驟 4。269s、5.13 美元是 n=2、同時改了三件事的對照實驗。量測檔本身還規定「引用下面的數字前先重跑」（`:16`），計畫的開工前提 5 只寫了讀｜第 6 項加三點：每個數字量的是什麼、限制（n 小、只看方向）、引用前先重跑，或標明是哪一天的快照。逐句核對表也要核這三點。
- 輪1-R4-2｜「步驟 4 每段至少 3 個 opus 審查者」漏了例外（dd-loop `:45`：沒有人工寫的程式碼就不派）｜補上這個例外。
- 輪1-R4-3｜`--uninstall` 會刪掉 `~/.claude/scripts/check-claude-md.sh`，安裝腳本移除前印的是「移除後各專案掛著的 hook 會失效」（`:1067`）｜README 的 `--uninstall` 那句補上這個後果。

【駁回】
- 輪1-R2-1｜計畫沒列在根目錄 CLAUDE.md 加指路句｜task-planner 步驟 5（`SKILL.md:108-109`）本來就規定寫設計文件時一併加，計畫是 task-planner 的草稿，會在那一步做。
- 輪1-R2-2｜沒提 `docs/reviews/` 的報告怎麼放、子目錄怎麼取名｜dd-loop `:85-93` 寫了「多張進度表時放子目錄、寫之前先 `ls`」，步驟 4 開始前本來就要叫 dd-loop。漏了的話 gate 會 `exit 1`，不會靜默。
- 輪1-R2-3｜沒排步驟 3–8｜進度表規則區塊（task-planner `:135`）規定小任務做完後整段跑 3–8。
- 輪1-R2-4｜沒對照「CI 不驗、只能手動同步的區塊」｜S2 本身就是同批改兩份 README，觸發清單列的項目（部署陣列、MCP、CI step、gate、迴圈步數）S1 都沒動。
- 輪1-R2-6｜`--start-segment` 會不會誤擋｜dd-loop `:14-17` 有出路，gate 擋下時會報錯，不會靜默。
- 輪1-R1-1｜小任務的 commit 會被 gate 擋｜規則區塊（task-planner `:134`）允許小任務用 `SKIP_DOC_CHECK=1`，最後一個用正常 commit。
- 輪1-R3-2｜子 shell 帶 `set -e` 會讓等價斷言全綠｜計畫要求「先確認在現行程式碼上紅在那 16 例」，harness 如果中止了就湊不出 16 紅，會被這一步發現。
- 輪1-R1-8｜`null` 是合法 JSON，「可能損毀」講錯原因｜python3 那條現在就是印這句，計畫只是統一成既有訊息，而且句子裡有「可能」。
- 輪1-R1-12｜「settings.json 可能放 token」沒有依據｜settings.json 支援 `env` 鍵，可以放環境變數（通用知識）。理由只是 A2 的旁證，不影響做法。
- 輪1-R4-4｜self-improving-agent 的 hook 會誤報｜開工前提 3 已經安排去讀它掛了什麼、什麼時候插提醒。審查者舉的證據是 session 內的觀察，沒有附檔案行號。

【需使用者決定】
無

【需要外部查證】
- 輪1-R1-10｜小事｜被 symlink 的目錄裡含有懸空的內層連結時，GNU `cp -RL` 會不會回非 0、讓 `set -e` 中止安裝。這條路少見，而且中止時會報錯。
- 輪1-R1-11｜小事｜`jq -e 'type == "object"'` 遇到空輸入時，在 jq 1.6 與 macOS 那版上的 exit code 是不是 4。
- 輪1-R3-6｜小事｜macos-latest runner 有沒有預裝 jq，這決定 CI 上兩條路徑各走到哪條。
- 輪1-R4-6｜小事｜self-improving-agent 的 hook 是不是真的透過 skills-dir 在全域生效，要用 `claude -p` 實測。
- 輪1-R4-7｜小事｜`/dd-init` Phase 5 的中文 commit 在 hooksPath、husky、升級等各條路徑上是不是都會出現。

【結論】
不通過（1 條重大）
