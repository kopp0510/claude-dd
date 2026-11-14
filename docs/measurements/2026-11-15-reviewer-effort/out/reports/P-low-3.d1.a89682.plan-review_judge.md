【派工】
派了 4 個審查者，全部用 general-purpose、haiku、effort low，沒有重派也沒有補派。計畫跨兩個段落，牽涉安裝腳本、測試、CI 與兩份 README，所以按方向分 4 路：
- 輪1-R1：前提成不成立（S1 對安裝腳本各函式的描述，以及修法本身會不會引入新錯）
- 輪1-R2：漏掉的同步點（各層 CLAUDE.md 的同批規則）
- 輪1-R3：範圍與驗證（段落切法、T1–T9 抓不抓得到錯、有沒有違反使用者決定）
- 輪1-R4：S2 README 要寫的內容與前提，以及會不會撞到 CI 檢查

【讀檔檢查】
- 輪1-R1：過。抽查 `install-dd-pipeline.sh:187-195`，是 `backup_before_overwrite`，`local category="$1" target="$2"`、`[ -e "$target" ] || return 0`、`cp -r`，對得上。
- 輪1-R2：過。抽查 `DD_PIPELINE_ARCHITECTURE.md:12` 是「全域 CLAUDE.md 那步…預設不安裝」，`README.md:82` 是 `--force` 覆蓋全域 CLAUDE.md 並備份那段，都對得上。
- 輪1-R3：過。抽查 `skills/task-planner/SKILL.md:108-109` 是指路句規定，`scripts/check-claude-md.sh:13-15` 是 docs/reviews 規則，都對得上。
- 輪1-R4：過。抽查 `skills/self-improving-agent/hooks/hooks.json` 是 PostToolUse、matcher Bash、error-capture.sh；`skills/dd-loop/SKILL.md` 的「最少 3 個」與 5.13 美元那句（含「n 小…只是方向」）都對得上。

【採納（重大）】
無。

【採納（小事）】
1. 輪1-R1-1、輪1-R2-1、輪1-R3-1｜計畫沒寫要在根目錄 CLAUDE.md 加指路句｜開頭那段補一句：寫設計文件時，同一個 commit 在根目錄 CLAUDE.md 第一個 `##` 之前加「進度以 docs/designs/2026-11-14-installer-hardening-design.md 的「進度表」為準…」。
   - 降為小事的理由：task-planner 步驟 5 本來就有這條指示（已讀 `skills/task-planner/SKILL.md:108-109`），照流程做不會漏，所以不符合 ②。但草稿明寫「現在沒有這句」卻沒寫要加，讀起來會誤會。
2. 輪1-R1-3｜S1-4 寫成 `backup_before_overwrite "commands"`，少了第二個參數｜改成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`。
   - 依據：函式第二個參數是空字串時，`[ -e "" ]` 不成立，會直接 `return 0`，不備份也不報錯（已讀 `install-dd-pipeline.sh:188-189`）。同檔 `create_commands` 既有的呼叫點寫的是兩個參數（`:921`）。
3. 輪1-R1-4｜`jq_inplace` 的型別預檢若寫成單獨一行，失敗時不會中止｜寫明形式為 `if ! jq -e 'type == "object"' "$file" >/dev/null 2>&1; then return 1; fi`。
   - 依據：呼叫端是 `json_edit … || settings_ok=false`，在 `||` 底下 `set -e` 不生效（已讀 `install-dd-pipeline.sh:205-206` 的註解）。
4. 輪1-R1-2｜T2 把 `plugin_enabled_state` 列為受測函式，而 S1-2 的定案表寫「頂層不是物件 → 兩條路徑都算失敗」，兩處讀起來衝突｜S1-2 定案表註明不含 `plugin_enabled_state`（照 A4 維持回 `none`）。T2 對它只比兩條路徑一致，不套定案表的結論。
5. 輪1-R1-5、輪1-R4-1｜S2-1 第 6 項的成本數字少了限定條件｜README 要一起寫明：
   - 2026-10-23 那份量的是單個 code-reviewer subagent 的耗時，來源是一台機器約 30 天的 session 紀錄，不是費用，也不是一整段的成本；
   - 5.13 / 3.83 美元是 2026-10-24 的小樣本，原文自己寫「只是方向」；
   - 「每段至少 3 個」有 dd-loop 的跳過例外（SKIP.md）。
   逐句核對表要連這些限定條件一起核。
6. 輪1-R1-6、輪1-R3-5｜T1 這支測試本身從來沒被看到紅過：macOS 上修前修後都綠，docker 實驗直接呼叫函式、沒跑 T1｜S1-1 加一步：在 macOS 上把複製那行暫時改成 `cp -RP`，模擬 GNU 複製連結本身的行為，確認 T1 紅在斷言上，再改回來並 `grep` 確認已還原。
7. 輪1-R1-8、輪1-R3-7｜CI runner 上沒有 jq 時，T2 兩邊都會走 python3，等價斷言會空通過｜T2 開頭斷言 `command -v jq` 與 `command -v python3` 都成功，缺任一個就紅燈，不能默默只測一條路徑。
   - 依據：`ci.yml` 沒有安裝 jq 的 step（`grep -n jq .github/workflows/ci.yml` 沒有安裝指令）。
8. 輪1-R3-6｜T2 的「代表案例」沒寫是哪幾例｜寫明至少三例：
   - 空的 settings.json 走 install：印更新失敗、檔案仍是 0 bytes；
   - `{"enabledPlugins":null}` 走 install：照常寫入；
   - `{"plugins":{"<key>":[null]}}` 走 install：失敗、檔案不動。
9. 輪1-R3-4｜S1-4 把兩個互不相關的修正放進同一個 commit，違反全域 §5.2｜拆成 S1-4（清舊指令前備份，配 T8）與 S1-5（完成訊息，配 T9），各自 commit。
10. 輪1-R2-3｜S2-1 第 2 項的 `--force` 部分與 `README.md:82` 已有的說明重複｜第 2 項只補「不帶 `--force` 也會覆蓋差異檔」，接在 `:82` 那段旁邊；`--force` 的部分沿用既有句子，不另寫一份。
11. 輪1-R2-4｜驗證沒寫用 `/bin/bash` 跑｜S1 驗收寫明 `tests/test-install.sh` 也要用 `/bin/bash tests/test-install.sh`（bash 3.2）跑一次，對齊 `ci.yml:594`。
12. 輪1-R4-3、輪1-R4-4｜開工前提 3 只讀 hooks.json，沒確認這個 hook 真的會被載入｜開工前提 3 加一項：確認 self-improving-agent 透過 skills-dir 被載入（它和 gate-guard 一樣有 `.claude-plugin/`，gate-guard 用 `claude -p` 實測過）。拿不到證據，README 就不寫「會掛」。

【駁回】
- 輪1-R1-1（後半）｜進度表沒寫 `--start-segment`、`IN_PROGRESS`、commits 起點｜這些在照抄的規則區塊裡，開工時才填，草稿的 TODO 狀態是對的。
- 輪1-R1-7｜S1-4 含刪檔，應獨立成段｜S1-4 是在既有的刪除前加備份，降低風險，不是新增的刪除工作，§4.1 那條不適用。
- 輪1-R1-9｜jq 1.6 與 1.7 的 `-e` exit code 可能不同｜計畫只需要「非 0」，T2 會驗結果，不依賴特定的 exit code。
- 輪1-R2-2｜`DD_PIPELINE_ARCHITECTURE.md:12` 漏列｜那句講全域 CLAUDE.md 預設不安裝，和「don't install the gate」不是同一件事。
- 輪1-R3-2｜計畫沒排步驟 3–8｜照抄的進度表規則區塊已規定小任務 commit 完再對整段跑 3–8。
- 輪1-R3-3｜使用者沒選過測試清單｜task-planner 步驟 4 的測試清單題排在審查之後才問，流程已安排。而且 S1-1、S1-2 與 S1-4 的備份那半是修 bug，本來就屬於 §3.5 的例外。
- 輪1-R3-8｜macos-latest 是否仍是 bash 3.2 要外部查證｜`ci.yml:572-576` 有「確認 /bin/bash 是 3.2」step，不是 3.2 就紅燈，CI 自己會擋。
- 輪1-R4-2｜S2 的驗證抓不到 README 寫錯的事實｜計畫有逐句核對表，後面還有步驟 4 至少 3 個 reviewer 審 README 的 diff，審查者也沒提出更好的機械檢查。

【需使用者決定】
無。

【需要外部查證】
- 輪1-R1-8、輪1-R3-7｜小事｜GitHub 的 ubuntu-latest 與 macos-latest runner 是否預裝 jq。不管查出來是什麼，採納第 7 條的護欄都會讓結果變成看得見的紅燈，不會空通過。

【結論】
通過
