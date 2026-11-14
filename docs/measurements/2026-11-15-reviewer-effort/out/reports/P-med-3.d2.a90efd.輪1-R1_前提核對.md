【我查了什麼】
根目錄 `<WORK>/P-med-3`（以下路徑皆相對此根）。只讀，沒跑測試或安裝。

- 讀過：`install-dd-pipeline.sh` 的 `ask`（173–182）、`backup_before_overwrite`（187–195）、`jq_inplace`／`py_inplace`／`json_edit`（209–260）、`plugin_enabled_state`（397–433）、`check_plugins`（449–454）、`validate_skill_hooks`（463–501）、`install_builtin_skills`／`install_builtin_agents`（504–628，可見的部分）、`mcp_scope`（630–673）、`install_plugins`（730–876）、`create_commands`（879–976）、`create_scripts`／`create_output_styles`（979–1052，可見的部分）、`uninstall` 的 plugin 段（1095–1145）、`create_global_claude_md`（1157–1238）、`show_completion`（1241–1284）；`tests/test-install.sh` 全 87 行；`.github/workflows/ci.yml` 的 step 清單與 `tests/` 掃描範圍（359 起）；`CLAUDE.md` 前 12 行；`README.md` 的 Prerequisites、安裝步驟與 `--uninstall`／`--force` 相關行；`skills/self-improving-agent/hooks/hooks.json`；`docs/measurements/2026-10-23-reviewer-real-sessions.md` 的費用表（第 143–163 行有 US$ 欄）。
- `grep` 指令：`grep -n -E '^set ' install-dd-pipeline.sh`（只有 `set -e`，沒有 `set -u`）；`grep -n -E 'declare -A|\$\{[A-Za-z_]+,,\}' install-dd-pipeline.sh`（無）；`ls docs/designs/`（7 份，與計畫相符）；`grep -n '進度以' CLAUDE.md`（無）。
- 核對結果，計畫前提成立的部分：沒有 `set -u`；`create_commands` 的舊指令清理（889–895）沒有備份；`uninstall` 沒碰 `~/.claude/CLAUDE.md`；`backup_before_overwrite` 在 skills／agents／commands／scripts／output-styles 的覆寫路徑都沒有 `$FORCE` 判斷，所以 README 第 2 點「不帶 `--force` 也會換成 repo 版」成立；`ask` 非 TTY 走預設值；`install_plugins` 的 settings 寫入（843–851）在 installed_plugins 寫入（860–870）之前；`README.md` 第 38 行已有 claude-md-management 以外的 plugin 安裝指令、沒有 claude-md-management 的指令。

【批評】

輪1-R1-1｜重大｜計畫開出進度表卻沒加 §4.4 要求的根目錄「指路」句。全域 §4.4 寫明開表的同時要在根目錄 CLAUDE.md 第一個 `##` 之前加一段「進度以 docs/designs/… 為準」。計畫第一段明寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，S1 文件同步清單也沒有加它。下一個 session 不會看到這張表，之後重估段落數、另開第二張，進度與 commit 範圍會遺失。這種遺失沒有測試或 gate 會報錯，code-review 也不會看到。證據：`CLAUDE.md:1-5`（第一個 `##` 是第 5 行 `## 安裝 / 更新`，前面沒有指路句）；計畫「進度表草稿」與「S1 的文件同步」兩節都沒有這一項。

輪1-R1-2｜重大｜計畫沒有排 §3.9 的步驟 3、4、7、8。兩段都只寫了步驟 1、2、5、6 相關的驗收與 commit。全域 §3.9 規定每個功能段落都要走 8 步：步驟 3 code-simplifier；步驟 4 派至少 3 個 code-reviewer 並把報告落地成 committed 檔；步驟 7 沉澱；步驟 8 評分與修正本輪動過的 CLAUDE.md。跳過步驟 4 不會報錯，之後也沒有關卡會補抓，屬於會漏掉的錯。證據：計畫「S1 的小任務」「S2 的小任務」與 S1、S2 的驗收欄只出現步驟 5；`~/.claude/CLAUDE.md` §3.9 的 8 步清單（全域規則，系統提示中可見）。

輪1-R1-3｜小｜S1-4 的寫法會讓備份靜默失效。計畫寫 `backup_before_overwrite "commands"`，只給一個參數。函式簽名是 `local category="$1" target="$2"`，第 189 行 `[ -e "$target" ] || return 0` 會直接返回，所以不會備份也不報錯。現有呼叫點（第 921 行）是 `backup_before_overwrite "commands" "$target"`。T8 會抓到這個錯，但計畫把這一行寫成規格，照抄就會中招。證據：`install-dd-pipeline.sh:187-189`、`:921`、`:889-895`（清理舊指令檔現在沒有備份）。

輪1-R1-4｜小｜計畫對 `plugin_enabled_state` 的定案與 A4 互相矛盾。「定案」寫「頂層不是物件 → 兩條路徑都算失敗、不改檔」，但 `plugin_enabled_state` 的 jq 與 python 兩條都對非物件頂層回 `none`（第 403–404、第 421 行），A4 也明寫保留這個 `none`。`check_plugins` 會把這種損毀的 settings.json 印成「未啟用」（第 454 行）。計畫沒說 T2 對這一支應該斷言什麼值，兩條路徑的結論相同會讓測試過，但「失敗」這個定案並沒有被實作。證據：`install-dd-pipeline.sh:397-433`、`:449-454`；計畫「S1-2 的定案」第一條與「A4」。

輪1-R1-5｜小｜「不改檔」只對失敗的那一個檔成立。`install_plugins` 先寫 settings.json 的 `enabledPlugins`（第 843–851 行），之後才寫 installed_plugins.json（第 860–870 行）。若 installed_plugins.json 是空檔，結果是 settings.json 已經寫入 `enabledPlugins`、installed_plugins.json 沒有登記，安裝訊息只說「跳過」。計畫的定案和 S2 README 都沒有講這種部分寫入。證據：`install-dd-pipeline.sh:839-870`。

輪1-R1-6｜小｜驗收沒有在 /bin/bash 3.2 上跑 `tests/test-install.sh`。CI 的 macOS job 用 `/bin/bash` 跑它（`.github/workflows/ci.yml` 第 593–594 行），而這台機器的 `/bin/bash` 就是 3.2。計畫的驗收只寫「本機 ci.yml 20 個 step 全過」，那是 ubuntu lint job 的 step，不含 macOS job。S1 新增的陣列與 `set -e` 下的分支在 3.2 上是否會出錯，要 push 後才由 CI 發現。可在驗收中加一行 `/bin/bash tests/test-install.sh`。

輪1-R1-7｜小｜T8 的測試字串若寫成 `~/.claude/commands/dd-help.md`，會被 CI 的「部署內容裡的 ~/.claude/ 路徑要指得到東西」擋下。該 step 掃描 `tests/`（`ci.yml:369` 附近的 `grep -noE` 範圍包含 `tests/`），而 `commands/dd-help.md` 不在 repo 裡。計畫的驗收是本機跑完 ci.yml 全部 step，所以本機會抓到；計畫應寫明測試裡要用 `$SANDBOX/.claude/...` 形式。

【需要外部查證】

輪1-R1-8｜小｜計畫說 `jq -e 'type == "object"'` 對空輸入回 4。我沒有跑 jq，無法確認。jq 版本不同，空輸入的 exit code 也可能不同。計畫要在動手前在 macOS 的 jq 與 debian 容器的 jq 各跑一次（`: | jq -e 'type == "object"'; echo $?`）。實際上 jq_inplace 只需要非零，所以即使數字不是 4 也不影響結論，但計畫的寫法不該寫死這個數字。

輪1-R1-9｜小｜計畫說 §3.5 的測試清單是使用者在 task-planner 步驟 4 選定的。本輪事實區列出的使用者原話裡沒有這個答案。`docs/designs/2026-11-14-loop-tuning-design.md` 有提到「測試清單題」的回答，但那是另一個文件的脈絡。計畫應該附上來源，否則 T1 到 T9 是否合乎 §3.5 無法驗證。
