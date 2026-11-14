【我查了什麼】

- 讀過的檔：`install-dd-pipeline.sh`（backup_before_overwrite、jq_inplace、py_inplace、plugin_enabled_state、install_builtin_skills/agents、create_commands、create_scripts、create_output_styles、install_plugins、uninstall、create_global_claude_md、check_plugins、show_completion、main）、`tests/test-install.sh` 全檔、`.github/workflows/ci.yml`、`skills/self-improving-agent/hooks/{hooks.json,error-capture.sh}`、`skills/dd-loop/SKILL.md`（55–93 行）、`docs/measurements/2026-10-23-reviewer-real-sessions.md`（11、86、364 行附近）、`agents/code-reviewer.md`、`commands/dd-init.md`（317 行附近）、`README.md` / `README.zh-TW.md` 的相關段、`DD_PIPELINE_ARCHITECTURE.md`（71–74 行）。
- grep 指令（節選）：
  - `grep -n 'hooks\|settings.json' install-dd-pipeline.sh`：只有 enabledPlugins 的寫入（439、740、836–858、1119–1140），沒有任何把 hooks 寫進 settings.json 的程式碼。
  - `grep -c '^      - name:' .github/workflows/ci.yml` 回 26；`awk 'NR<564'` 回 20（lint job 20 個，macOS job 6 個）。
  - `grep -n 'jq' .github/workflows/ci.yml` 沒有安裝 jq 的 step。
  - `grep -n '2026-10-23\|2026-10-24' docs/measurements/ skills/dd-loop/SKILL.md`。
- 查過且成立的計畫內容：README 第 3 項（就地改寫、不備份）、第 2 項（不帶 `--force` 時 skill／agent／指令／腳本／輸出風格內容不同就備份後覆蓋，與 `--force` 無關）、第 4 項（`/dd-init` 的 commit 訊息是中文）、第 7 項（CI 平台 ubuntu-latest 與 macos-latest）、`--uninstall` 不碰 `~/.claude/CLAUDE.md` 與 `~/.claude/backups/`、S1-2 的「失敗不半套」與 DD_PIPELINE_ARCHITECTURE.md:71–72 不衝突。

【批評】

輪1-R4-1｜重大｜README 第 5 項把 self-improving-agent 的 hook 寫成「全域會掛」，但安裝器不會把它掛上去。安裝器只寫 `enabledPlugins`，沒有任何 hooks 註冊；error-capture.sh 自己的檔頭寫的是要手動加進 `.claude/settings.json`。計畫把它列為 README 的既成事實，沒有任何檢查會驗這句。｜證據：`install-dd-pipeline.sh` 的 hooks 相關只有 `validate_skill_hooks`（463–491、1346）；`grep -n 'settings.json' install-dd-pipeline.sh` 只有 enabledPlugins 的讀寫（439、740、836–858、1119–1140）；`skills/self-improving-agent/hooks/error-capture.sh` 第 19–30 行「Install: Add to .claude/settings.json」。同樣的「全域安裝」說法已經寫在 `README.zh-TW.md:133`（gate-guard），機制一樣沒有在安裝器裡找到，見外部查證 1。

輪1-R4-2｜小｜S1-4 寫的 `backup_before_overwrite "commands"` 只傳一個參數。函式第二個參數才是目標路徑，目標為空時 `[ -e "" ]` 不成立，直接 `return 0`，不備份也不報錯。T8 會抓到，所以不算重大，但這是計畫照做就會錯的寫法，應改成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`。｜證據：`install-dd-pipeline.sh:187–195`（函式簽名與 `[ -e "$target" ] || return 0`）；計畫 S1-4 的文字。

輪1-R4-3｜小｜定案的「頂層不是物件 → 兩條路徑都算失敗」沒有涵蓋 `plugin_enabled_state`，而 A4 又保留它回 `none`。`check_plugins` 把 `none` 印成「未啟用」，所以 settings.json 是 `null` 或陣列時，安裝會報失敗、`--check` 卻說「未啟用」，兩個輸出互相矛盾。計畫沒有定案這一格。｜證據：`install-dd-pipeline.sh:397–430`（非物件回 `none`，註解寫「刻意的」）；`install-dd-pipeline.sh` `check_plugins` 的 `case` 內 `*) … 未啟用`；計畫 A4 與 S1-2 第一條定案。

輪1-R4-4｜小｜S1 與 S2 的驗收寫「本機 ci.yml 20 個 step」「全部 step」，但 ci.yml 實際有 26 個 step，其中 macOS job 的 6 個（含 `/bin/bash` 3.2 檢查與 bash32 相關測試）沒有被計入。S2-1 寫「全部」與 20 矛盾。｜證據：`grep -c '^      - name:' .github/workflows/ci.yml` = 26；ci.yml:564 起是 macOS job。

輪1-R4-5｜小｜README 第 1 項「你自己裝的也一樣」會讓人以為 `--uninstall` 會清掉使用者自己裝的所有 plugin。實際只刪 `OFFICIAL_PLUGINS` 那兩個 key（claude-md-management、skill-creator）。應寫明是這兩個 key。｜證據：`install-dd-pipeline.sh:1119–1140`（`for plugin in "${OFFICIAL_PLUGINS[@]}"` 只對這兩個 key 做 `del`）。

輪1-R4-6｜小｜README 第 6 項寫「步驟 4 每段至少 3 個 opus 審查者」，漏掉 dd-loop 的跳過條款（SKIP 檔）。費用數字 5.13 與 3.83 來自 n 很小的兩組、dd-loop 自己註明「n 小、同時改了三件事，只是方向」；「311 次、中位 11.8 分」來自作者一台機器、排除公司專案、只保留約 30 天。計畫要求「附樣本數」，但沒要求把這些限定寫進 README。｜證據：`skills/dd-loop/SKILL.md:61–63`（最少 3 個）、`:66`（n 小的註記）、`:81–93`（跳過條款）；`docs/measurements/2026-10-23-reviewer-real-sessions.md:11`（排除公司專案、近期樣本）、`:364`（n 小）。

【需要外部查證】

輪1-R4-7｜重大｜README 第 5 項與既有的 gate-guard「全域安裝」說法（`README.zh-TW.md:133`）都假設 `skills/*/hooks/hooks.json` 會自動生效。安裝器沒有註冊機制（見 R4-1）。需要實際確認 Claude Code 是否會自動載入 `~/.claude/skills/*/hooks/hooks.json`；若不會，兩處 README 都要改。這需要在乾淨環境跑 `claude -p` 或查 Claude Code 官方文件，我沒有執行。

輪1-R4-8｜小｜T2 的 jq 分支依賴 CI runner 有裝 jq。ci.yml 沒有安裝 jq 的 step；若某個 runner 沒有 jq，計畫中的「jq vs python」比較會變成 python 對 python，恆等、永遠綠，而 T2 本身不會報錯。需要確認 ubuntu-latest 與 macos-latest 的預裝內容，並在測試裡加 `command -v jq` 的斷言。另外計畫依賴 `jq -e 'type == "object"'` 對空輸入回傳 4，這點需要對 jq 版本查證，我沒有執行 jq。
