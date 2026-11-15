【我查了什麼】
- 讀完審查包（166 行）。
- 讀 `install-dd-pipeline.sh`：`backup_before_overwrite` 187–195、`create_commands` 888–895、`create_global_claude_md` 1156–1240、`ask` 173–181、`jq_inplace` 209–221、`mcp_scope` 630–700、`install_plugins` 730–870、skills/agents/commands/scripts/output-styles 的覆蓋分支（524–540、600–616、916–930、1000–1016、1040–1056）。
- 讀 `tests/test-install.sh` 全 87 行、`tests/CLAUDE.md`、`.github/workflows/ci.yml` 的 step 清單。
- 讀根目錄與全域 CLAUDE.md 的相關段落（gate 段、§4.4 進度表規則、§3.9 步驟 2 的 SKIP）。
- grep：`grep -n 'backup_before_overwrite' install-dd-pipeline.sh`、`grep -rn '指路\|進度以' templates CLAUDE.md commands skills`（無命中）、`grep -rn '新增' --include=CLAUDE.md`（只抓到 scripts/CLAUDE.md:184 等一般句子，沒有「新增 X 要同時改 N 處」類的明文規則落在本計畫會碰的路徑）、`grep -n 'FORCE' install-dd-pipeline.sh`。
- 確認的事實：ci.yml lint job 有 20 個 step（`ubuntu-latest`，:12），macOS job 另有 6 個具名 step（:564 起）。`REQUIRED_MCP` 只有 playwright。非 `--force` 的覆蓋對 skills、agents、commands、scripts、output-styles 都是無條件 backup+cp，`FORCE` 只影響印出的字樣，所以 T5 的前提與程式一致。`ask` 非 tty 走預設值，所以 T6 的「保留本機版」成立。

【批評】
輪1-R3-1｜重大｜進度表開表時沒有加指路句。計畫開了進度表（計畫第 8–15 行），但「S1 的文件同步」清單（第 52–57 行）與 S2 都沒有「在根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」。全域 §4.4 明文要求開表時同時加這句；它的理由寫在那條規則裡：下個 session 不會看到表，段落起點與 commit 範圍會靜默遺失。證據：計畫第 6 行說根目錄沒有該句；`grep -rn '指路\|進度以' templates CLAUDE.md commands skills` 無命中。符合三條：①每次用進度表都會走到；②照計畫做會違反明文規則、讓之後的 session 重估段落；③沒有任何機械檢查會抓到。

輪1-R3-2｜中｜S1-4 指定的呼叫 `backup_before_overwrite "commands"` 只傳一個參數。函式定義是 `local category="$1" target="$2"`，第一行就是 `[ -e "$target" ] || return 0`（install-dd-pipeline.sh:187–189）。target 為空時函式直接 return 0，不做備份。計畫第 47 行照這個寫法會讓備份靜默不發生。T8 若照計畫斷言「備份目錄裡有 dd-help.md」就會變紅，所以這個錯會被抓到，不算靜默。但計畫給的寫法本身是錯的，應改為逐檔呼叫 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`。

輪1-R3-3｜中｜提交順序與 gate 衝突。S1-1 到 S1-4 每個 commit 都改根目錄的 `install-dd-pipeline.sh` 與 `tests/` 的 `.sh`，但計畫把 CLAUDE.md 文件同步留到最後一個小任務才做（第 52–57 行）。根目錄 CLAUDE.md 的「搭配巢狀 CLAUDE.md 堆疊維護」段寫明：改碼目錄缺 CLAUDE.md 或未同批更新即擋 commit。計畫沒有寫要用 `SKIP_DOC_CHECK=1` 的檢查點 commit（全域 §3.9 步驟 2 允許），所以中間每個 commit 都會被擋，計畫沒有預留這一步。會大聲被擋，所以不算重大。

輪1-R3-4｜中｜S1-1 的「紅」沒有在被測的那支上取得。計畫要求 T1 紅綠都在 GNU 上取（第 24 行），但實際做的是 docker 裡 source 腳本、呼叫函式的片段，不是 `tests/test-install.sh` 裡的 T1。本機 ci.yml 跑的 20 個 step 是 macOS 上的 lint job，ubuntu（GNU、bash 5）那個 job 沒有在本機跑，F15 也說 ubuntu job 沒跑過本機多出的 34 個 commit。§3.5 要求新測試先紅、紅在被測物上，計畫沒有在 GNU 上讓 T1 本身紅過。

輪1-R3-5｜中｜S1 的驗收條件「等價表探針 92 例不一致數從 16 變 0」無法從 repo 重現，T2 也未必涵蓋同樣的 92 例。計畫第 127 行的探針腳本在 scratchpad、不在 repo。第 86 行的 T2 清單只是類別摘要（「空檔、只有空白、壞掉的 JSON、頂層是 null／陣列／字串／數字…」），沒有逐例對應到 92 例。第 163 行又說 debian 映像沒有 jq 與 python3，所以計畫第 12 行「debian 容器裡…」那段驗收無法同時包含等價表。驗收數字與可重跑的測試之間沒有對應。

輪1-R3-6｜小｜A4 與 S1-2 的規則對不上。S1-2 的定案（第 30 行）說「頂層不是物件 → 兩條路徑都算失敗」，列舉的是安裝、移除與 mcp_scope；A4（第 102 行）又說 `plugin_enabled_state` 保留回 `none` 的設計。T2 的「代表案例直接斷言結論本身」沒有寫 `plugin_enabled_state` 在頂層 null 時該斷言什麼，實作者會自己選。

輪1-R3-7｜小｜S2 的 README 第 71 行「會把官方 plugin 拿掉（你自己裝的也一樣）」容易被讀成第三方 plugin 也會被移除。`uninstall()` 只刪 `OFFICIAL_PLUGINS` 列的 key（計畫第 143 行的 F11），括號應改成「官方 plugin 本身就算是你自己裝的，也一樣被拿掉」。

輪1-R3-8｜小｜S2 的逐句核對表沒有機械檢查。它只能靠人工對照，README 的費用與時間數字（第 76 行）沒有 CI 會擋。

【需要外部查證】
輪1-R3-9｜中｜`cp "$source" "$target"`（install-dd-pipeline.sh:194 之後的各處寫入，以及 `create_global_claude_md` 的 `cp`）在 target 是 symlink 時，會寫進 symlink 指到的外部檔案。S1-1 只改備份，不改寫入，所以即使備份修好，`~/.claude/CLAUDE.md` 指到的外部檔（例如 dotfiles repo 裡的檔）照樣被覆蓋。計畫沒有提到這件事，也沒有決定要不要處理。需要在沙盒實跑確認：`ln -s` 一個外部檔到 `~/.claude/CLAUDE.md`，跑 `--force`，看外部檔內容是否變成模板。

輪1-R3-10｜小｜A7 寫的「兩個 agent 備份檔的上游授權」需要對照上游 LICENSE，這份審查包沒有提供它們的來源與授權，我無法判斷。
