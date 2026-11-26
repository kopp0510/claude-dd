【我查了什麼】
- 完整讀過材料檔 `<WORK>/prompts/P-med-9.pack.md`（0–165 行，末行 `<<<審查包結束>>>`）。
- 讀專案 `install-dd-pipeline.sh`：180–260（`ask`、`backup_before_overwrite`、`jq_inplace`、`py_inplace`、`json_edit`）、397–420、463–503（`validate_skill_hooks`）、504–540（`install_builtin_skills`）、630–727（`mcp_scope`、`print_mcp_line`、`check_mcp`）、730–876（`install_plugins`）、879–960（`create_commands`）、1059–1150（`uninstall`）、1160–1238（`create_global_claude_md`）、1241–1284（`show_completion`）、1287–1400（`main`）。
- 讀 `tests/test-install.sh` 全檔（87 行）。確認其中沒有 `settings.json`／`.claude.json`／`installed_plugins` 字串。
- 讀 `DD_PIPELINE_ARCHITECTURE.md` 50–76 行（安裝行為保證）、`CLAUDE.md` 的注意事項與 Script／Command 步驟、`tests/CLAUDE.md` 第 11 行附近、`CHANGELOG.md` 前 20 行、`.github/workflows/ci.yml` 的 jq／python／runs-on 相關行。
- 跑過的 grep：
  - `grep -n 'backup_before_overwrite\|^jq_inplace\|^py_inplace\|^jq_register\|^py_register\|^install_plugins\|^uninstall\|^mcp_scope\|^show_completion\|^create_commands\|^install_builtin_skills\|^validate_skill_hooks\|^plugin_enabled_state\|^install_builtin_agents\|--commands-only\|install_plugins$\|show_completion$' install-dd-pipeline.sh`
  - `grep -n 'json_edit\|jq_inplace\|py_inplace\|check_plugins()\|plugin_enabled_state "' install-dd-pipeline.sh`
  - `grep -rn -E '新增|同時改|同批|要一起|同步|手動同步' --include=CLAUDE.md .`（逐條對 S1 範圍，相關的是根 CLAUDE.md 的「新增 Script／Command／Output Style 步驟」與「注意事項」中 `jq`／`python3` 等價規則，行 252–258；計畫都有涵蓋）
  - `grep -n 'jq\|python\|brew\|runs-on' .github/workflows/ci.yml`
  - `grep -n 'REQUIRED_MCP=\|OPTIONAL_MCP=\|OFFICIAL_PLUGINS='`、`grep -n '^## ' CHANGELOG.md`
- 實證核對的計畫事實：
  - F4：`backup_before_overwrite` 共 9 個呼叫點（528, 604, 921, 957, 1006, 1046, 1194, 1216, 1227），定義在 187 行，簽名是 `(category, target)`。
  - F9：`deprecated_dd` 在 889–895 行，前面沒有備份。
  - F10：`show_completion` 1251 與 1254 行無條件印 Agents 與 Plugin；1268 行才判斷 `COMMANDS_ONLY`。
  - F12：`install_builtin_skills` 528 行在內容不同時備份並覆蓋，不看 `$FORCE`。
  - F3：`ask` 在非 tty 時採預設值。
  - F2：`test-install.sh` 無 settings／claude.json 相關字串。
  - `plugin.json` 路徑在 782 行。
  - 「開發：…」那行在 `install-dd-pipeline.sh:1249`，`ci.yml` 的迴圈步數第五方會讀它，計畫有保留。
  - `CHANGELOG.md` 有 `## 未發布`（19 行）。
  - `ci.yml` 沒有 `jq` 或 `brew` 安裝步驟。

【批評】
輪1-R1-1｜小｜S1-4 寫的 `backup_before_overwrite "commands"` 只給一個參數，但函式簽名是 `(category, target)`。照字面做時 `target` 為空，`[ -e "" ]` 為假，函式直接 `return 0`，不備份也不報錯。這正是「靜默無效」的寫法；不過計畫已安排 T8 斷言備份目錄裡有 `dd-help.md`，所以會被測試抓到，不符合重大的第 ③ 條。計畫第 47 行應改寫成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`。｜證據：`install-dd-pipeline.sh:187-189`（簽名與 `[ -e "$target" ] || return 0`）；`install-dd-pipeline.sh:889-892`（deprecated 迴圈）；計畫 `P-med-9.pack.md:47`。

輪1-R1-2｜小｜S1-3 第 40 行的理由與程式不符。計畫說 `SANDBOX` 的「無備份產生」斷言「靠 plugin 步驟被跳過」才成立，但 `install_plugins` 寫 settings／installed_plugins 只走 `json_edit`，不呼叫 `backup_before_overwrite`。因此就算 plugin 真的登記成功，`[ ! -d "$SANDBOX/.claude/backups" ]` 照樣成立。改用新沙盒的決定仍然安全，但計畫寫下的前提是錯的，之後有人照這個前提判斷 `SANDBOX` 能不能復用就會出錯。應改成實際理由，例如「避免共用狀態」，並移除「靠 plugin 被跳過」這句。｜證據：`install-dd-pipeline.sh:839-864`（json_edit 寫入，無備份）；`grep -n backup_before_overwrite install-dd-pipeline.sh` 的 9 個呼叫點都不在 `install_plugins` 內；`tests/test-install.sh:50,55`。

輪1-R1-3｜小｜S1 的驗收只看「本機 macOS 跑 `ci.yml` 20 個 step」。但 S1-1 的 GNU 行為（`cp -RL`、懸空連結）只有 ubuntu job 會真的跑到；計畫自己也寫了「macOS 的 `cp -r` 本來就會跟著連結，T1 在本機修之前就是綠的」。計畫用 docker debian 補了 T1 的紅綠證據，但 T2–T9 在 ubuntu job 的結果沒有列入驗收。計畫應加一條「push 後 ubuntu 與 macOS 兩個 job 的 `test-install.sh` 都綠」，或明寫這是使用者的 push 之後步驟。｜證據：計畫 `P-med-9.pack.md:12`（驗收欄只寫本機）與 `:24`（T1 只靠 docker 取紅綠）；`ci.yml` 的 `ubuntu-latest` 與 `macos-latest` 兩個 job 都跑 `tests/test-install.sh`（`ci.yml:557`、`:594`）。

【需要外部查證】
輪1-R1-4｜小｜T2 的 jq 與 python3 等價比較，在 macOS CI job 上可能變成 python 比 python。`ci.yml` 沒有 `brew install jq`，所以要看 `macos-latest` runner 預裝有沒有 jq。沒有的話，`command_exists "jq"` 恆為假，該 job 的 T2 不會比較任何兩條路徑。ubuntu job 仍有真的比較，所以整體不會漏掉，但這樣寫的斷言在 macOS 上是空通過。計畫應在 T2 加一則斷言「jq 分支確實有跑」（例如先斷言 `command_exists jq` 為真，或在測試開頭印出來）。需要查證的是 GitHub 官方 macOS runner 映像預裝哪些工具。｜為什麼需要：我只能讀本機與 repo 的檔案，無法看到 GitHub runner 的映像內容。

輪1-R1-5｜小｜T2 要求兩條路徑「改完的 JSON（時間戳換掉後）」逐字相同。jq 與 python `json.dump(indent=2, ensure_ascii=False)` 的縮排、跳脫與數字格式，在不同 jq 版本（ubuntu 的 jq 與本機 Homebrew 的 jq）之間是否一致，我無法在本機確認。若 ubuntu 的 jq 版本不同，這條比較可能在 CI 才紅。需要查證 `ubuntu-latest` 預裝 jq 的版本，並比對本機版本。｜為什麼需要：版本細節屬於外部環境，無法從 repo 內容判斷。

整體結論：照我的檢查，計畫的前提大致成立。我逐項核對了 F4、F9、F10、F12、F3、F2 與 9 個呼叫點，都對。找不到會「照做會壞」且「後面的關卡都抓不到」的重大缺陷，所以不硬湊。上面 3 條小問題與 2 條外部查證都是可以直接修進計畫文字的。
