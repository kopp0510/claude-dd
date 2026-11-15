【我查了什麼】

- 讀過的檔：`install-dd-pipeline.sh` 的 ask（173–181）、backup_before_overwrite（187–196）、jq_inplace（209–221）、py_inplace（228–245）、json_edit、mcp_scope（630–690）、install_plugins（730–）、create_commands（879–）、show_completion（1241–）、uninstall 的 plugin 清理（1112–1150）、create_global_claude_md（1156–1235）、agents 安裝（598–618）、scripts／output-styles／commands 的覆蓋分支、plugin_enabled_state（393–430）、`skills/self-improving-agent/hooks/hooks.json`、`skills/self-improving-agent/hooks/error-capture.sh`、`skills/dd-loop/SKILL.md:66`、`docs/measurements/2026-10-23-reviewer-real-sessions.md`、`README.md:19,84–85,104`、`agents/code-reviewer.md`、`templates/global/CLAUDE.md:251`。
- 跑過的指令：`grep -n 'backup_before_overwrite()\|jq_inplace()\|py_inplace()\|jq_register()\|py_register()\|mcp_scope()\|^uninstall()\|create_commands()\|show_completion()\|^ask()\|install_plugins()\|validate_skill_hooks()'`；`grep -n 'backup_before_overwrite\|FORCE' install-dd-pipeline.sh`；`grep -n 'CLAUDE.md' install-dd-pipeline.sh`；`grep -n '進度以' CLAUDE.md`（無輸出）；`ls docs/designs`（7 份，與計畫相符）；`grep -c '美元\|\$\|cost\|費用' docs/measurements/2026-10-23-reviewer-real-sessions.md`（14）。
- 查證結果、與計畫相符的部分：`ask` 非 TTY 採預設值；backup 只用 `cp -r`；`uninstall` 不碰 CLAUDE.md 與 backups；全域 CLAUDE.md 非互動預設保留本機版；`--force` 才靜默覆蓋全域 CLAUDE.md；`--yes` 存在；`docs/designs` 7 份、根目錄 CLAUDE.md 無「進度以」句。

【批評】

輪1-R1-1｜小｜S1-1 的理由寫錯。計畫說「不對所有情況都加 `-L`：GNU `cp -RL` 遇到懸空連結回 1，腳本有 `set -e`」。但 backup_before_overwrite 第一行就是 `[ -e "$target" ] || return 0`，懸空連結根本走不到 cp。修法本身仍成立，但理由會誤導實作者去加懸空連結的特殊處理。證據：install-dd-pipeline.sh:187–196（第 190 行 `[ -e "$target" ] || return 0`，第 194 行 `cp -r "$target" "$BACKUP_ROOT/$category/"`）。

輪1-R1-2｜中｜S1-1 的「先紅」沒有在測試本身上取得。計畫自己承認 macOS 的 `cp -r` 本來就複製內容，所以 T1 在本機修之前就是綠的。紅的證據改用 docker 裡 source 腳本、手動呼叫函式，那不是跑 `tests/test-install.sh` 的 T1。因此本機「`tests/test-install.sh` 全過」的驗收條件對 T1 沒有鑑別力，與全域 §3.5「新測試先寫失敗案例，確認會失敗」不符。計畫也沒寫怎麼在 debian 容器內跑整支 test-install.sh（容器裡沒有 jq、python3，見事實 F5 與環境說明）。證據：計畫 S1-1 驗證段；事實 F5；全域 CLAUDE.md §3.5。此條在 push 後的 ubuntu CI 會抓到，所以不算重大。

輪1-R1-3｜中｜S1-2 的定案與 A4 互相矛盾。定案寫「頂層不是物件 → 兩條路徑都算失敗、不改檔」，A4 卻保留 plugin_enabled_state 對頂層非物件回 `none`。證據：install-dd-pipeline.sh:403–404（jq 分支 `if type != "object" then "none"`）與 421–422（python 分支 `enabled = ... if isinstance(data, dict) else None`）。根目錄 CLAUDE.md 的「檢查類輸出的鐵則」要求「不確定就說不確定」，回 `none` 會讓一個壞掉或型別錯的 settings.json 被當成「未啟用」。T2 只斷言兩條路徑相等（都是 none），會把錯誤結論鎖進測試。此為罕見路徑，所以不列為重大。

輪1-R1-4｜重大｜S2-1 第 6 點「迴圈的時間與費用」沒有指定用哪組數字，而檔內有口徑不同的數字，寫進 README 會誤導。(a) `docs/measurements/2026-10-23-reviewer-real-sessions.md:86` 是單一 code-reviewer subagent 的中位數 11.8 分；(b) 同檔 `:195` 是 G2／G3 整發 335s、365s，費用 3.6 倍與 2.5 倍；(c) `skills/dd-loop/SKILL.md:66` 是 2026-10-24 直接派與裁決者的對照，269s、5.13 美元，n=6，文件自己寫「n 小、同時改了三件事」。計畫只要求「附量測日期、樣本數與檔名」，不會擋住把不同口徑的數字並排。計畫的逐句核對表會判它「對得上檔案」而通過，所以抓不到。依三條判準：S2 的 README 必然經過這段；寫錯的數字不報錯；之後的 code-review、CI 都不檢查散文裡的數字。`README.md:104` 已經有「至少三個審查者」段落並引用同一份量測，計畫沒有說明要改寫還是補充。

輪1-R1-5｜小｜S2-1 第 1 點的措辭會被讀錯：「會把 OFFICIAL_PLUGINS 列的官方 plugin … 拿掉（你自己裝的也一樣）」。uninstall 只迴圈 OFFICIAL_PLUGINS 的 key，不會拿掉其他 plugin。證據：install-dd-pipeline.sh:1126–1146（`for plugin in "${OFFICIAL_PLUGINS[@]}"`，`del(.enabledPlugins[$key])`、`del(.plugins[$key])`）。應寫成「只限 OFFICIAL_PLUGINS 列出的 key，包含你手動裝過的同名 plugin」。

輪1-R1-6｜小｜S2-1 第 5 點把 self-improving-agent 的 hook 寫成無條件結論，但計畫自己把它列為開工前提 3。證據：`skills/self-improving-agent/hooks/hooks.json` 掛在 PostToolUse、matcher `Bash`；`error-capture.sh:145–147` 顯示只有比對到錯誤行時才回 additionalContext 提醒。README 應寫成「Bash 輸出含錯誤樣式時」，而不是泛稱「全域會掛」。

【需要外部查證】

輪1-R1-7｜中｜self-improving-agent 的 hook 是否真的全域載入：計畫說「全域會掛的 hook」，但 `skills/self-improving-agent/hooks/hooks.json` 只是檔案，要確認 skills-dir 部署後 Claude Code 是否真的載入它（需實跑 `claude -p` 或看 plugin 登記）。為什麼需要：這是 README 的事實宣稱，只讀 repo 無法確認。

輪1-R1-8｜小｜`jq -e 'type == "object"'` 對空輸入回 4、對 `null` 回 1 的假設，計畫未在 S1-2 驗證段實跑確認。為什麼需要：要在本機 jq 版本上執行 `jq -e` 才能確認退出碼，我沒有執行任何指令。
