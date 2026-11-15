【我查了什麼】
- 讀完 `prompts/P-med-7.pack.md` 全部 166 行。
- F16 逐字核對：`README.md:19`、`:38`、`:67`、`:70`、`:156` 與計畫引文一致；`README.zh-TW.md:20` 有同一句「翻譯全域模板」，計畫有列。`grep -c -i -E 'windows|linux|wsl' README.md` 回 0。
- F17 核對：`docs/measurements/2026-10-23-reviewer-real-sessions.md:86` 有「次數=311 中位=11.8 分 第90百分位=27.7 分」；`:143` 寫耗時與費用的算法；`:319` 寫 A 組 269s、5.13、n=2；`:143` 寫費用「會偏低」；`:221`、`:364` 寫 n 小、四件事同時變。`skills/dd-loop/SKILL.md:66` 的數字與 caveat 原樣。
- uninstall：`install-dd-pipeline.sh:1059–1150`。只刪 `OFFICIAL_PLUGINS` 的登記，沒有 `CLAUDE.md` 與 `backups`，無 jq 也無 python3 時整段跳過（`:1121–1124`），`:1067` 印「移除後各專案掛著的 hook 會失效」。
- 備份：`backup_before_overwrite` `:187–195`；skills `:520–535`、agents `:595–611`、commands `:921/957`、scripts `:1006`、output-styles `:1046` 都在不帶 `--force` 時備份後覆蓋，只有標籤不同。全域 CLAUDE.md `:1170–1230`。`--update` `:1358–1364` 會把 FORCE 設為 true。
- 設定檔：`install-dd-pipeline.sh:844–863` 就地寫 `enabledPlugins` 與 `installed_plugins.json`，沒有經過備份。
- hook：`skills/self-improving-agent/hooks/hooks.json`、`skills/self-improving-agent/hooks/CLAUDE.md:67`、`skills/self-improving-agent/CLAUDE.md:78`、`skills/self-improving-agent/hooks/error-capture.sh` 檔頭（只在輸出命中錯誤樣式時才出聲）。`skills/gate-guard/hooks/CLAUDE.md:48` 只有 gate-guard 有過 `claude -p` 實測。
- CI：`.github/workflows/ci.yml:12`（ubuntu-latest）、`:564`（macos-latest，bash 3.2）、`:250–262`（flag 比對用 `sort -u`）、`:314` 與 `:501`（模板錨點 `^### 3\.9`、`^> 步驟 1`）、`:517–530`（一行式箭頭摘要掃 README）。
- 其他：`install-dd-pipeline.sh:120`（`PLUGINS_MARKETPLACE`）、`:832`（plugin install 指令格式）；`agents/code-reviewer.md:4` 為 `model: opus`；`commands/dd-init.md:317/320`（commit 訊息為中文）；`commands/dd-init.md:196–236`（Phase 3 的跳過路徑）；`templates/global/CLAUDE.md:28–29`（§1.1 語言）；`DD_PIPELINE_ARCHITECTURE.md:75`。
- 指令：`git status --short`（乾淨）、`grep -c` 與 `sed -n` 等逐行核對，以及上述 Grep 查 `skills-dir`。

沒有發現重大缺失。以下三條都不同時符合「常走的路 + 錯了 + 後面關卡抓不到」。

【批評】
輪1-R4-1｜小｜uninstall 的 plugin 清理在沒有 jq 也沒有 python3 時整段跳過，計畫 S2 第 1 項寫成無條件「會把…拿掉」。README 要補「但注意」這個條件。｜`install-dd-pipeline.sh:1121–1124`（`if ! command_exists "jq" && ! command_exists "python3"` 印「跳過 Plugin 設定清理」）

輪1-R4-2｜小｜計畫說 uninstall「不動…各專案的 hook」，這句字面正確，但漏了後果：`~/.claude/scripts/check-claude-md.sh`（gate 本體）會被刪，各專案 hook 只剩警告、不擋。卸載時 uninstall 自己也這樣印。README 應寫明這個後果。｜`install-dd-pipeline.sh:1067`；`README.md:123`（gate 缺失時「只警告、commit 照過」）

輪1-R4-3｜小｜第 6 項「迴圈的時間與費用」沒有指定用哪個數字，也沒寫明單位，照 F17 寫會被誤讀。（a）「中位 11.8 分」是每個 code-reviewer subagent 的 jsonl 首尾時間戳差，不是步驟 4 整段時間，且排除 >200 分的離群值，樣本來自單一作者的機器。（b）「5.13 美元」是 n=2 的 fixture 整發費用平均，費用是父 log 累計值且會偏低，而 A 組的審查者數「父 session 自己決定（≥3）」。（c）`dd-loop` 自己寫「n 小、同時改了三件事，只是方向」。計畫只說「附量測日期、樣本數與檔名」，沒把這三條 caveat 列進來。｜`docs/measurements/2026-10-23-reviewer-real-sessions.md:143`、`:221`、`:283`、`:319`；`skills/dd-loop/SKILL.md:66`

輪1-R4-4｜小｜計畫 F20/第 1 項列的「中文還寫死的地方」只有 4 處，漏了 CI 的模板錨點。`ci.yml` 用 `^### 3\.9` 與 `^> 步驟 1` 定位全域模板的步驟區塊，翻譯模板會讓「迴圈步數四方一致」與「第五方」失效。CI 會擋下，所以不算重大，但 README 句子要改成「翻譯模板還要同步 CI 錨點」，計畫現在的寫法會讓讀者以為只改模板。｜`.github/workflows/ci.yml:314`、`:501`；`README.md:19`

輪1-R4-5｜小｜第 5 項說「全域會掛的 hook：self-improving-agent」。repo 文件自己這樣寫（`skills/self-improving-agent/hooks/CLAUDE.md:67`、`skills/self-improving-agent/CLAUDE.md:78`），但實測只做過 gate-guard（`CLAUDE.md:83`）。另外 README 要寫的觸發條件（只有輸出命中 `error:`、`failed` 等樣式才提醒）計畫沒寫。｜`skills/self-improving-agent/hooks/error-capture.sh` 檔頭「Zero output unless an error PATTERN matches」

輪1-R4-6｜小｜第 4 項「裝了全域模板之後 Claude 會用繁體中文回覆」寫成「會」，但這是 CLAUDE.md 裡的規則，模型依規則行事，沒有機械強制。另外全域 CLAUDE.md 在新機器上預設是「No」（`README.md:56`），計畫寫的「裝了之後」只有條件，沒寫預設值。｜`templates/global/CLAUDE.md:28–29`；`README.md:56`

【需要外部查證】
輪1-R4-7｜小｜`claude plugin install claude-md-management@claude-plugins-official` 這條指令是否可用，取決於官方 marketplace 有沒有這個 plugin，以及它的 `plugin.json` 有沒有 `version` 欄位。repo 內查不到，需要在 marketplace 或 `claude plugin` 實際驗證。｜`install-dd-pipeline.sh:832` 只證明指令格式，不證明 plugin 存在

輪1-R4-8｜小｜self-improving-agent 的 hook 是否在使用者機器上全域生效（skills-dir plugin 載入、是否需要 enabledPlugins 項目）。需要在拋棄式專案用 `claude -p` 讓 Bash 輸出含 `error:`，確認 `additionalContext` 出現。這項實測不在計畫的驗證裡，也不在我的權限內跑。｜`skills/gate-guard/hooks/CLAUDE.md:48` 只對 gate-guard 做過

輪1-R4-9｜小｜本機跑 ci.yml 的 lint 步驟（macOS）不等於 ubuntu-latest 的結果。S2 只動 README，但 ubuntu 的數字比對與 flag 比對要 push 後才能真正確認，而 push 由使用者按。｜`.github/workflows/ci.yml:12`
