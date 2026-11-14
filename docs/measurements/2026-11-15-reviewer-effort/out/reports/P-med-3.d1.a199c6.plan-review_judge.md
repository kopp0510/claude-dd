【派工】
派了 4 個審查者，都是 general-purpose、haiku、effort medium，沒有重派，也沒有補派。計畫跨兩個段落，又牽涉安裝腳本、測試、CI 和兩份 README，所以按方向分成四份：
- 輪1-R1：前提成不成立，核對安裝腳本各函式與 `tests/test-install.sh` 的現況
- 輪1-R2：漏掉的同步點，搜各層 CLAUDE.md 的「同批」「同步」類規則
- 輪1-R3：範圍與驗證，看各測試會不會真的變紅、兩個 CI job 的環境差異
- 輪1-R4：S2 要寫進 README 的八項是否屬實，以及會不會誤觸 CI 對 README 的檢查

【讀檔檢查】
- 輪1-R1：過。抽 `install-dd-pipeline.sh:187-189`，`local category="$1" target="$2"` 與 `[ -e "$target" ] || return 0` 對得上；抽 `:921`，`backup_before_overwrite "commands" "$target"` 對得上。
- 輪1-R2：過。抽 `templates/global/CLAUDE.md:510-511`，「開表的同時…加一段指路」對得上。
- 輪1-R3：過。抽 `.github/workflows/ci.yml:594`，`run: /bin/bash tests/test-install.sh` 對得上；它列的 `backup_before_overwrite` 呼叫點（528、604、921、957、1006、1046、1194、1216、1227）與 grep 結果一致。
- 輪1-R4：過。抽 `docs/measurements/2026-10-23-reviewer-real-sessions.md:86`（`code-reviewer 次數=311 中位=11.8 分`）、`:317`（3.83）、`:319`（5.13），以及 `install-dd-pipeline.sh:1067`（「含 pre-commit gate — 移除後各專案掛著的 hook 會失效」），都對得上。

【採納（重大）】
無。

【採納（小事）】
- 輪1-R1-3｜S1-4 把呼叫寫成 `backup_before_overwrite "commands"`，只給一個參數。照抄的話 `target` 是空字串，第 189 行直接 return，不備份也不報錯｜計畫要怎麼改：寫成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`。
- 輪1-R1-4、輪1-R3-2｜S1-2 的定案「頂層不是物件 → 算失敗」沒寫清楚它不適用 `plugin_enabled_state`。A4 保留這一支回 `none`，T2 的「代表案例」可能被寫成斷言「失敗」｜計畫要怎麼改：T2 明寫 `plugin_enabled_state` 在這類案例斷言回 `none`。
- 輪1-R1-5｜`install_plugins` 先寫 settings.json（`:843-851`），之後才寫 installed_plugins.json（`:860-870`）。後者損毀時，前者已經寫進 `enabledPlugins`，只有登記被跳過，所以「不改檔」只對失敗的那個檔成立｜計畫要怎麼改：定案註明這種部分寫入；S2 第 3 項的 README 說法一起交代，或在 S1-2 決定先驗兩個檔再寫。
- 輪1-R1-6、輪1-R3-7｜驗收「本機 ci.yml 20 個 step 全過」沒涵蓋 macOS job 用 `/bin/bash` 3.2 跑 `test-install.sh`（`ci.yml:594`）｜計畫要怎麼改：S1 驗收加一條 `/bin/bash tests/test-install.sh` 全過。
- 輪1-R1-7｜T8 若在 `tests/` 裡寫字面上的 `~/.claude/commands/dd-help.md`，會撞上 CI「部署內容裡的 ~/.claude/ 路徑要指得到東西」（`ci.yml:369` 掃 `tests/`），而 repo 沒有 `commands/dd-help.md`｜計畫要怎麼改：T8 一律用 `$<沙盒>/.claude/...` 的寫法。
- 輪1-R3-4｜S1-3 說現有 SANDBOX 的「無備份產生」斷言「靠 plugin 步驟被跳過才成立」，這個理由不成立：`install_plugins`（`:730-876`）完全不呼叫 `backup_before_overwrite`｜計畫要怎麼改：另開沙盒的做法保留，理由改成實際的理由（例如不讓 plugin 登記的副作用混進既有斷言），免得把錯的理由寫進設計文件或註解。
- 輪1-R3-5｜S1-1 的理由「GNU `cp -RL` 遇到懸空連結回 1」在這個函式裡走不到：第 189 行的 `[ -e "$target" ]` 會跟著連結判斷，懸空連結在 `cp` 之前就 return 了｜計畫要怎麼改：這句理由不要寫進程式碼註解，改寫成實際成立的理由，或重新評估是否統一用 `-L`。
- 輪1-R3-6｜T1、T5、T8 沒寫怎麼找備份目錄。目錄名精度到秒（`:191`），用萬用字元取第一個可能撈到別次執行的目錄｜計畫要怎麼改：每組用自己的沙盒，並斷言 `backups/` 底下只有一個 `pre-install-*`。
- 輪1-R2-3｜S2-1 只寫「`DD_PIPELINE_ARCHITECTURE.md` 有同一句時一起改」，但那一句寫的是中文同義句：`DD_PIPELINE_ARCHITECTURE.md:75`「`--uninstall` 只移除本 repo 部署過的項目」，`README.zh-TW.md:71` 的註解「本 repo 部署過的項目」也是同一個說法，都跟「連使用者自己裝的官方 plugin 也拿掉」矛盾｜計畫要怎麼改：把這兩處明列進 S2-1 的檔案清單。
- 輪1-R4-1｜S2-1 第 6 項的成本數字，量的對象要寫清楚：11.8 分是單一 code-reviewer 的耗時中位數（311 次）；269s／5.13 美元、350s／3.83 美元是 2026-10-24 對固定 diff 的實驗，每臂 n=2，費用是父 session 累計值（`:143`、`:317-319`、`:364`）。照字面寫容易被讀成「每段步驟 4 的成本」｜計畫要怎麼改：第 6 項要求每個數字註明量的是什麼（單一審查者還是整發）、素材、n，以及檔名（2026-10-24 那組也記在 `2026-10-23-reviewer-real-sessions.md`，原始資料在 `2026-10-24-s4-outputs/`）。
- 輪1-R4-2｜S2-1 第 1 項沒寫 uninstall 會刪掉 `check-claude-md.sh`，之後各專案的 pre-commit hook 找不到腳本，gate 等於失效（`:1067`）｜計畫要怎麼改：第 1 項補上這個後果，並照 README 現有的說法寫明腳本不在時 commit 會怎樣。

【駁回】
- 輪1-R1-1、輪1-R2-1、輪1-R3-1｜沒在根目錄 CLAUDE.md 加「進度以…為準」指路句｜這份是 task-planner 的草稿，它的步驟 5 寫設計文件時就會加指路（`skills/task-planner/SKILL.md:108-109`）。
- 輪1-R1-2｜沒排 §3.9 的步驟 3、4、7、8｜進度表規則區塊會照抄進設計文件，裡面規定小任務 commit 完再對整段跑步驟 3–8（`SKILL.md:135`）。
- 輪1-R2-2｜沒記 `--start-segment` 起點｜規則區塊的「開工」那條規定了（`SKILL.md:133`）。
- 輪1-R2-4｜中間 commit 會被 gate 擋，計畫沒寫 SKIP｜規則區塊已寫明小任務可用 `SKIP_DOC_CHECK=1`、最後一個小任務用正常 commit 補欠帳（`SKILL.md:134-135`）。
- 輪1-R1-9｜測試清單沒有使用者選定的來源｜草稿還沒到 task-planner 步驟 4 的測試清單題，那題選定的才是使用者要求加的測試（`SKILL.md:96-97`）。
- 輪1-R3-3｜`set -e` 下中途中止會被誤讀成紅｜計畫已要求 S1-2「紅在那 16 例」、S1-3「紅在斷言而不是載入失敗」，中途中止過不了這兩條判準。
- 輪1-R3-8｜逐句核對表是自己寫自己核｜S2 一樣要走步驟 4，由獨立的 code-reviewer 審 diff；計畫另要求逐句附依據原文。
- 輪1-R3-11｜92 例探針不在 repo，16 這個數字無法重核｜S1-2 已安排把案例表搬進 `tests/test-install.sh`，並在現行程式碼上確認紅在那 16 例，重核就在那一步。
- 輪1-R4-3｜沒交代 self-improving-agent hook 的實際觸發行為｜S2 開工前提 3 已排定查「什麼時候會插提醒」，S2-1 只寫查得到的事實。
- 輪1-R4-4｜不確定 skill 目錄裡的 hooks 會不會被載入｜根目錄 CLAUDE.md「新增 Skill 步驟」第 6 條記了 skill 目錄以 `<名字>@skills-dir` 載入，有 2026-09-30 的 `claude -p` 實測；`skills/self-improving-agent/.claude-plugin/plugin.json` 存在（已 ls），走的是同一套機制。

【需使用者決定】
無。

【需要外部查證】
- 輪1-R1-8、輪1-R3-10｜小｜`jq -e 'type == "object"'` 對空輸入的 exit code 在各平台的 jq 版本是否都是 4。修法只需要非 0，所以計畫不要寫死「4」。
- 輪1-R3-9｜小｜GitHub `macos-latest` runner 有沒有預裝 jq。沒有的話，T2 的 jq 分支在 macOS job 跑不到，只有 ubuntu 驗得到。ci.yml 裡沒有安裝 jq 的 step。

【結論】
通過
