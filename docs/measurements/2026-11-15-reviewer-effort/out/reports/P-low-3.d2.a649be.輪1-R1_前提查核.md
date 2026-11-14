【我查了什麼】
- 讀 `install-dd-pipeline.sh`：`backup_before_overwrite`（187–195）、`jq_inplace`（209–221）、`py_inplace`（228–245）、`json_edit`（248–260）、`plugin_enabled_state`（397–434）、`check_plugins` 印狀態（440–455）、`install_plugins`（730–870，含 json_edit 呼叫 843–847、863–865）、`mcp_scope`（630–669）、`create_commands` 開頭（879–893）、`uninstall` 的 JSON 清理（1125–1150）、`show_completion`（1241 起）、全域 CLAUDE.md 覆蓋分支（1185–1230）、agents／scripts／output-styles 覆蓋分支（596–612、1000–1012、1040–1050）。
- 讀 `tests/test-install.sh`（87 行，全部）。
- grep：`grep -n 'backup_before_overwrite\|jq_inplace\|py_inplace\|json_edit\|python3 -c' install-dd-pipeline.sh`；`grep -n 'set -o\|pipefail'`（無結果）；`grep -rn '新增\|同時改\|同批\|要一起\|同步\|手動同步' CLAUDE.md tests/CLAUDE.md scripts/CLAUDE.md`；`grep -n '進度以' CLAUDE.md`（無結果）；`grep -n 'TODO\|IN_PROGRESS\|指路' skills/task-planner/SKILL.md`。
- 讀 `skills/task-planner/SKILL.md` 第 100–145 行（指路句與進度表狀態規則）、`docs/measurements/2026-10-23-reviewer-real-sessions.md` 開頭、`skills/dd-loop/SKILL.md:66`。
- 核對 README 的四句引文（第 19、67、70、156 行）與第 38 行，與 F16 相符。`CHANGELOG.md` 有 `## 未發布`；`DD_PIPELINE_ARCHITECTURE.md` 有「可回復」與「JSON 就地改寫」兩句；`tests/CLAUDE.md:10` 與 `ci.yml:557, 594` 有 test-install。
- 未跑任何測試、未安裝、未開容器。

【批評】

輪1-R1-1｜重大｜進度表沒有「指路」句，計畫的 S1 開工後，下一個 session 會看不到進度表，重估段落數並另開第二張表，已記的段落起點與 commit 範圍會靜默遺失。計畫只在前提裡寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，之後沒有安排加入。全域 §4.4 與 task-planner 規則都要求開表時在根目錄 CLAUDE.md 第一個 `##` 前加指路句。另外計畫的進度表沒有寫 `--start-segment` 記起點、`IN_PROGRESS` 標記、commits 欄的 `<起點>..`，與 SKILL 的開工流程不一致。
證據：`skills/task-planner/SKILL.md:108-109`（指路句原文）；`skills/task-planner/SKILL.md:131-137`（狀態規則與開工步驟）；`CLAUDE.md` 全檔 `grep '進度以'` 無結果；計畫的進度表兩列 commits 欄皆空、狀態皆 TODO。

輪1-R1-2｜中｜`--check` 會把損壞的 settings.json 報成「未啟用」，計畫的 S1-2 沒有處理這一支，也沒有測試覆蓋。`plugin_enabled_state` 的 jq 分支在頂層不是物件時回 `none`，`check_plugins` 對 `none` 印的是確定的「未啟用」。計畫的 S1-2 表說「頂層不是物件 → 兩條路徑都算失敗」，但 A4 保留了 `none`，兩者互相矛盾。T4 只測 `~/.claude.json`，不測 settings.json。
證據：`install-dd-pipeline.sh:399-407`（`if type != "object" then "none"`）；`install-dd-pipeline.sh:449-455`（`*) ... 未啟用`）；計畫 A4 與 S1-2 的定案表。根目錄 CLAUDE.md「檢查類輸出的鐵則：不確定就說不確定」也與之衝突。

輪1-R1-3｜中｜S1-4 寫的是 `backup_before_overwrite "commands"`，只有一個參數。函式簽名是 `category target`，`target` 會是空字串，`[ -e "" ]` 為假，於是 `return 0`，不備份也不報錯，接著 `rm` 照跑。T8 會抓到，所以不算靜默，但計畫文字照抄就會錯。
證據：`install-dd-pipeline.sh:187-195`（`local category="$1" target="$2"`；`[ -e "$target" ] || return 0`）；計畫 S1-4 做法的字串。應改寫成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`。

輪1-R1-4｜中｜S1-2 的 `jq_inplace` 預檢如果寫成單獨一行的 `jq -e ...`，在失敗時不會中止，檔案仍會被改寫。原因是呼叫端 `json_edit ... || settings_ok=false` 位於 `||` 串中，`set -e` 在整個函式內失效。計畫沒寫出是 `if ! jq -e ...; then return 1; fi` 的形式。T2 會抓到分歧，所以不是靜默錯誤，但實作者照字面寫會白走一圈。
證據：`install-dd-pipeline.sh:205-206`（註解「呼叫端須用 `|| ...` 接住」）；`install-dd-pipeline.sh:843-847` 與 `:863-865`（`|| settings_ok=false`、`|| installed_ok=false`）。

輪1-R1-5｜中｜S2-1 第 6 項的成本數字會被讀成「每段步驟 4 要多久、多少錢」，但依據不是這個。2026-10-23 量測是某台機器約 30 天內的 code-reviewer subagent 耗時，且排除了公司專案，中位 11.8 分是單個 subagent 的時間，不是迴圈成本。dd-loop 那組 269s／5.13 美元只是 n=6 的方向性結果，SKILL 自己寫「n 小……只是方向」。計畫只說「附樣本數與檔名」，沒說要把這些限制寫進 README。
證據：`docs/measurements/2026-10-23-reviewer-real-sessions.md:1-10`（來源與排除條件）；`skills/dd-loop/SKILL.md:66`（「n 小……只是方向」）。

輪1-R1-6｜中｜S1-1 的驗收依賴 repo 外的 docker 手動實驗，而 repo 內的 T1 在本機（macOS）永遠是綠的，不論修或不修。計畫自己也寫「T1 在本機修之前就是綠的」。紅的驗證只在 `debian:bullseye` 的手動步驟裡做，`tests/test-install.sh` 本身在 GNU 上從來沒有被證明會紅。T1 唯一會紅的地方是 ubuntu CI，而計畫不 push，所以開 commit 前沒有人會跑它。
證據：計畫 S1-1 驗證段；F5（macOS `cp -r` 與 `cp -RL` 都複製出一般檔）；`tests/test-install.sh` 全檔沒有 symlink 的案例。CI 會在 push 後抓到，所以不算 ③。建議把 T1 的紅燈驗證放進 test 本身（在 `ci.yml` 的 ubuntu job 或 docker 裡跑 test-install）。

輪1-R1-7｜小｜S1 把四組互不相關的修補（symlink 備份、JSON 等價、測試補充、清舊指令與完成訊息）與九組測試塞進同一段，每段都要走完整 8 步。§3.9 要求「刪除這類高風險工作不跟其他功能算同一段」，S1-4 含刪檔（`deprecated_dd`）。計畫沒有評估這一點。

【需要外部查證】
- 輪1-R1-8｜中｜T2 在 CI 的 macOS job（`macos-latest`）是否有 `jq`？若沒有，T2 的 jq 分支在 macOS 上根本不會跑，而計畫的「兩條路徑等價」只在 ubuntu 上成立。需要查 GitHub 的 runner 映像清單，或在 `ci.yml` 裡加一句 `command -v jq`。為什麼需要：決定 T2 在兩個 job 是否都真的覆蓋兩條路徑。
- 輪1-R1-9｜小｜`jq -e 'type == "object"'` 在空輸入時回 4、在 `null` 時回 1，計畫 S1-2 依賴這個退出碼。需要用 jq 1.6 與 1.7 各跑一次確認；macOS 預設 jq 版本可能不同。為什麼需要：CI 的 ubuntu 與本機 macOS 版本不一定一樣。
