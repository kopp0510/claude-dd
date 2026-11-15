【我查了什麼】

- 讀完審查包 166 行（`prompts/P-med-6.pack.md`）。
- 讀 `install-dd-pipeline.sh` 的 `command_exists`、`ask`、`backup_before_overwrite`（187-195）、`jq_inplace`、`py_inplace`、`json_edit`（209-260）、`plugin_enabled_state`（397-433）、`check_plugins`、`validate_skill_hooks`（463-501）、`install_builtin_skills`（504-543）、`mcp_scope`、`print_mcp_line`、`check_mcp`、`install_plugins`（730-876）、`create_commands` 開頭與 namespace 分支（879-935、950-961）、`uninstall`（1059-1154）、`create_global_claude_md`（1157-1238）、`show_completion`（1241-1284）、`main`（1287-1398）。
- 讀 `tests/test-install.sh` 全檔（87 行）與 `tests/CLAUDE.md`。
- 讀 `README.md` 的 19、38、67、70、71、82、156 行。
- 讀 `DD_PIPELINE_ARCHITECTURE.md` 的 72-74 行，`CHANGELOG.md` 的 `## 未發布`。
- 讀 `docs/measurements/2026-10-23-reviewer-real-sessions.md` 開頭（方法段）、`skills/dd-loop/SKILL.md:66`。
- 讀 `skills/self-improving-agent/hooks/CLAUDE.md:67`、`skills/self-improving-agent/.claude-plugin/plugin.json`、`skills/self-improving-agent/hooks/hooks.json`。
- 讀 `scripts/CLAUDE.md:55-70`（`docs/reviews/` opt-in 規則）、`agents/code-reviewer.md`（model: opus）、`templates/global/CLAUDE.md:444-446、505-512`、`skills/task-planner/SKILL.md:75、108-109`。
- 讀 `.github/workflows/ci.yml` 的 test-install 呼叫（557、594）與 runner 設定。
- 跑過的 grep（節錄）：
  - `grep -n -E '^[a-z_]+\(\) *\{' install-dd-pipeline.sh`
  - `grep -n -E 'backup_before_overwrite|jq_inplace|...' install-dd-pipeline.sh`（確認 9 個 backup 呼叫點：528、604、921、957、1006、1046、1194、1216、1227）
  - `grep -n -E '進度以|^## ' CLAUDE.md`（根目錄沒有「進度以…為準」那句）
  - `grep -n -E '新增|同時改|同批|要一起|同步' CLAUDE.md tests/CLAUDE.md scripts/CLAUDE.md`
  - `grep -rn -E 'skills-dir|gate-guard@' . --exclude-dir=docs --exclude-dir=.git`（安裝腳本本身沒有註冊 skills-dir，只有 hooks/CLAUDE.md 的說明）
  - `grep -n -i -E 'overwrit|覆蓋|--force|backup|備份' README.md README.zh-TW.md`
- 計畫前提的核對結果：
  - 92 例、16 個不一致、三類 settings/installed/.claude.json 的分項，與計畫描述一致。
  - F4 的 9 個呼叫點、7 個 cp 寫入、2 個 rm -rf（528、957）一致。
  - F9、F10、F11、F12、F13 與原始碼一致。
  - 9 個新測試 T1–T9 所依賴的函式行為，除下列批評外，與原始碼一致。

【批評】

輪1-R1-1｜重大｜計畫開了進度表卻沒加根目錄指路句，下個 session 會看不到表，段落與 commit 範圍會靜默遺失。計畫的 S1 文件同步清單也沒有這一項。｜證據：`templates/global/CLAUDE.md:510-512` 規定「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，並說明「少了這句，下一個 session 走 §4.1 那條判斷會看不到這張表」；`skills/task-planner/SKILL.md:108-109` 同樣規定。`CLAUDE.md` 的 `##` 從第 5 行起，`grep -n '進度以' CLAUDE.md` 無結果。計畫只寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」就略過。失敗情境：下一個 session 讀 CLAUDE.md 看不到表，重估段落數並另開第二張表，S1 的 commit 範圍就對不上了。③ 成立，理由同此。

輪1-R1-2｜重大｜計畫完全沒排 §3.9 的步驟 3–8（code-simplifier、code-review 至少 3 個審查者並落地報告、再測、沉澱、評分），也沒排段落起點 `check-claude-md.sh --start-segment`。段落 S1、S2 因此都沒有獨立審查，S2 開工還會被 gate 擋。｜證據：計畫全文只在第 52–57、80 行提到文件同步與 ci.yml，沒有 code-review 或 simplifier（`grep -n -E 'simplif|code-review|--start-segment' <計畫>` 無結果）。全域 §3.9 要求每段走 3–8（`CLAUDE.md` 第 244–258 行的 dd-loop 摘要）。`ls docs/` 顯示 `docs/reviews` 存在，`scripts/CLAUDE.md:62-64` 寫明「有 `docs/reviews/` 時是 opt-in，`--start-segment` 檢查上一段範圍內有沒有新增 `docs/reviews/S*.md`，沒有就 exit 1」。S1 沒有報告，S2 開工時 `--start-segment` 會 exit 1。②、③ 成立：S1 的 S1-1 至 S1-4 沒有任何獨立審查，錯了也沒有關卡會抓到。

輪1-R1-3｜重大｜README 的「迴圈時間與費用」（計畫 S2-1 第 6 點與開工前提第 5 點）指定的依據不能用來支撐那段宣稱。`docs/measurements/2026-10-23-reviewer-real-sessions.md` 量的是每個 code-reviewer subagent 的耗時（首尾 timestamp 差），不是步驟 4 整段時間或費用，而且只涵蓋一台機器近 30 天、排除 `-SRE` 專案。`skills/dd-loop/SKILL.md:66` 的 269s、5.13 美元、命中 4/6 是 n=6、作者自述「n 小、同時改了三件事」。計畫沒指定要用哪個數字，只要求「附量測日期、樣本數與檔名」。失敗情境：README 寫出「步驟 4 每段約 X 分鐘、Y 美元」，這個數字不是它宣稱的量，而 gate、CI、code-review 都不檢查 README 的散文數字，只剩作者自己的逐句核對表。③ 成立。

輪1-R1-4｜中｜計畫宣稱 T1–T9 的新測試是使用者要求的（依據是「測試清單題」的選定），但事實段裡逐字列出的使用者發言只有兩則，都不是關於測試的。全域 §3.5 預設不主動新增測試，依據不成立就等於跳過了使用者的決定。｜證據：審查包第 111–117 行（使用者逐字發言只有兩則：「你認為現在這份 repo 分數多少…」與「請你優化改善」）；第 122 行的「task-planner 步驟 4 的『測試清單題』選定的清單就是使用者要求加的測試」沒有對應的逐字發言。全域 §3.5 原文：「不主動新增測試；使用者要求或修 bug 時例外」。

輪1-R1-5｜中｜範圍由計畫自行擴大到第 4 與第 5 項，並宣稱「審查通過就動手，不再等使用者批准」。使用者沒有指定要改哪幾項，助理自己建議先修第 4 項，使用者回「請你優化改善」。全域 §6.1 把「要改變範圍」列為停下來問的情況。｜證據：審查包第 113–117 行（「使用者沒有指定要改哪幾項。這份計畫選 4 與 5，是我的選擇」）；`CLAUDE.md` 全域規則 §6.1 的「只在這三種情況停下來問：…要改變範圍」。

輪1-R1-6｜中｜T1（symlink 備份）的「先紅」只在 docker 探針裡取得，沒有在 `tests/test-install.sh` 本身於 GNU 上跑過紅。在 macOS 上 T1 修之前就是綠的（計畫第 24 行自己寫的），本機跑不出鑑別力；ubuntu 的 CI job 要 push 後才跑，計畫不 push。違反 §3.5「紅要是被測物跑出錯的結果」的要求，這個紅沒有被「測試本身」證明。｜證據：計畫第 23–24 行；`.github/workflows/ci.yml:557` 的 ubuntu job 跑 `tests/test-install.sh`。

輪1-R1-7｜中｜T7 的 fixture 寫「SCRIPT_DIR 指到假目錄」。`validate_skill_hooks` 只掃 `$SCRIPT_DIR/skills` 下的 hooks.json（`install-dd-pipeline.sh:491`），假目錄若沒有壞的 hooks.json，函式回 0，斷言 exit 1 失敗的原因是 fixture 錯，不是被測行為。計畫沒說要在假目錄裡放一份含相對路徑的 hooks.json。｜證據：`install-dd-pipeline.sh:490-491`。

輪1-R1-8｜小｜計畫 S1-2 的通用規則寫「頂層不是物件 → 兩條路徑都算失敗、不改檔」，但 A4 又保留 `plugin_enabled_state` 對頂層非物件回 `none`。同一份 settings.json 在安裝時會印「更新失敗」，在 `check_plugins` 會印「未啟用」，兩處結論互相矛盾，而計畫沒說明。｜證據：計畫第 30 行與第 102 行；`install-dd-pipeline.sh:402-412`（jq 分支對非物件回 none）。

輪1-R1-9｜小｜S1-1 只處理 `[ -L "$target" ]` 的情況，但 `backup_before_overwrite` 第 189 行的 `[ -e "$target" ] || return 0` 會先跳過懸空連結。懸空連結不被備份，之後的 `cp "$source" "$target"` 會透過它建立 referent 檔案，這個行為計畫沒有提到。｜證據：`install-dd-pipeline.sh:187-195`。

輪1-R1-10｜小｜計畫 S1-2 的「空檔 → 安裝印更新失敗、不改檔」是設計取捨，計畫直接定案，沒有回問。結果是使用者的 0 位元組 settings.json 永遠裝不成 plugin，訊息卻一直說「檔案可能損毀」，計畫沒寫修復路徑。｜證據：計畫第 30 行；`install-dd-pipeline.sh:848-851`。

【需要外部查證】

輪1-R1-11｜中｜「全域會掛的 hook」（計畫 S2-1 第 5 點）依賴 self-improving-agent 的 hooks 會被 Claude Code 自動以 skills-dir plugin 載入。repo 內只有 `skills/self-improving-agent/hooks/CLAUDE.md:67` 的文字說明，安裝腳本沒有註冊任何 skills-dir。需要在乾淨的 HOME 裡確認 Claude Code 真的會載入 `~/.claude/skills/<名字>/.claude-plugin/plugin.json`，才能寫進 README。

輪1-R1-12｜小｜計畫 S1-2 的「jq -e 空輸入回 4」是未經驗證的版本行為。CI ubuntu 與 macOS 的 jq 版本不同。T2 的空檔案例會在 CI 抓到，但計畫沒有在本機或 CI 版本上實測。

輪1-R1-13｜中｜S1 的 T1 在 ubuntu（GNU cp 8.32、bash 5）上的紅與綠，只能在 push 後的 CI 看到。計畫不 push，所以這一項在使用者 push 前無法確認。
