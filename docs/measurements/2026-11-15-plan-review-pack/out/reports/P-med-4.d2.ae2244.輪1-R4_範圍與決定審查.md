【我查了什麼】
- 讀完審查包 `P-med-4.pack.md` 全部 166 行（offset 0，limit 300，讀到 `<<<審查包結束>>>`）。
- 讀檔：`install-dd-pipeline.sh`（`backup_before_overwrite` 187、`jq_inplace` 209、`py_inplace` 228、`json_edit` 250、`plugin_enabled_state` 397、`validate_skill_hooks` 463、`mcp_scope` 630、`install_plugins` 730–880、`create_commands` 889、`uninstall` 1059–1150、`show_completion` 1241、`main` 1340–1397、全域 CLAUDE.md 區段 1160–1240）、`CLAUDE.md`（第 5 行是第一個 `##`）、`tests/test-install.sh`（87 行）、`tests/CLAUDE.md`、`commands/dd-init.md:203`、`skills/dd-loop/SKILL.md:55–66`、`skills/task-planner/SKILL.md:119–145`（已用 `~/.claude/skills/task-planner/SKILL.md` 核對一致）、`.github/workflows/ci.yml`、`docs/measurements/2026-10-23-reviewer-real-sessions.md`、`skills/self-improving-agent/CLAUDE.md:78`。
- grep 指令與結果：
  - `grep -rn -E '新增|同時改|同批|要一起|同步' CLAUDE.md tests/CLAUDE.md scripts/CLAUDE.md …`：找到的規則都已在計畫範圍內（部署陣列、兩份 README、`dd-loop-rev` 等），計畫未涉及的只有下面 1 條（§4.4 指路句）。
  - `grep -n '^## ' CLAUDE.md` 首個 `##` 在第 5 行；`grep -n '進度以|docs/designs' CLAUDE.md` 無結果。
  - `grep -c -E 'settings\.json|\.claude\.json|installed_plugins' tests/test-install.sh` 回 0。
  - `grep -n 'FORCE' install-dd-pipeline.sh`：skills、agents、commands、scripts、output-styles 的覆蓋都不看 `$FORCE`，事實 F12 與 S2-1 第 2 點成立。
  - ci.yml 命名 step：`lint` job（10–563 行）正好 20 個；`macos-latest` job（564 行起）另有 6 個。
  - `git rev-list --count HEAD` 回 1，`git cat-file -t b1935bb` 失敗；`git branch -a` 只有 `master`。
- 已確認成立的計畫事實：README 第 19、70、152/156 行原文逐字相符；`DD_PIPELINE_ARCHITECTURE.md` 第 74–75 行「可回復」句存在；`tests/CLAUDE.md` 第 10 行 test-install 那列存在；2026-10-23 量測檔含 311 次／中位 11.8 分；2026-10-24 的 269s、5.13 美元、3.83 美元數字在同一量測檔第 317–319 行；`code-reviewer` 定義是 `model: opus`；`deprecated_dd` 清單（889 行）與 F9 相符；`show_completion` 無條件印 agent 與 plugin 段（F10）相符。

【批評】

輪1-R4-1｜重大｜開表時漏了根目錄 CLAUDE.md 的指路句，下一個 session 會看不到進度表、重估段落、另開第二張表。全域規則 §4.4 寫明「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，計畫的文件同步清單（第 52–57 行）與 S1、S2 的做法都沒有這一步，事實第 6 行也承認根目錄目前沒有這句。｜①每次開表都會經過 ②下個 session 依 §4.1 重估，進度與 commit 範圍會遺失 ③gate 只檢查改碼目錄的 CLAUDE.md，CI 與 code-review 不驗這句，所以不會報錯。｜證據：`CLAUDE.md:5` 是第一個 `##`（`## 安裝 / 更新`），`grep -n '進度以' CLAUDE.md` 無結果；計畫 `:52-57` 無此項；全域 §4.4 原文（系統提供的全域 CLAUDE.md）。

輪1-R4-2｜重大｜進度表沒有記段落起點，狀態與 commits 欄照 task-planner 規則都不對。計畫表 S1、S2 的狀態都是 `TODO`、commits 欄空白，也沒提 `check-claude-md.sh --start-segment`。依規則，開工要標 `IN_PROGRESS`、commits 欄填 `<起點>..`；之後 §3.9 步驟 3、4、8 的 `<起點>` 都從這裡取。起點錯了，code-review 看到的 diff 範圍就不完整，而且不會報錯。｜①每段都會經過 ②步驟 4 與 8 拿到錯的範圍 ③`code-review` 只審到部分 diff，後面的 gate 與測試抓不到。｜證據：`skills/task-planner/SKILL.md:133`（開工標 `IN_PROGRESS`、commits 欄填 `<起點>..`）、`:136`（標 `DONE` 補終點）；計畫 `:10-13`（S1、S2 狀態 `TODO`、commits 空）。

輪1-R4-3｜小事｜`install_plugins` 先寫 settings.json 才寫 installed_plugins.json。若 installed_plugins.json 是空檔（S1-2 定案會讓它失敗），settings.json 的 `enabledPlugins` 已經被寫成 `true`，但訊息印「installed_plugins.json 更新失敗，跳過」。計畫定案寫「兩條路徑都算失敗、不改檔」、S1-4 寫「只列真的啟用成功的」，這兩點在這個情境都不成立，而且 T2 比的是兩條路徑彼此一致，抓不到這個錯。｜證據：`install-dd-pipeline.sh:843`（settings 的 `json_edit`）先於 `:863`（installed 的 `json_edit`），失敗訊息在 `:849`、`:868`。

輪1-R4-4｜小事｜計畫的定案與 A4 互相矛盾。定案第一條說「頂層不是物件 → 兩條路徑都算失敗」，但 A4 說 `plugin_enabled_state` 對非物件回 `none` 是刻意設計，而且程式註解寫明了。計畫沒說 check_plugins 之後該印什麼。｜證據：`install-dd-pipeline.sh:403-404`（jq 分支對非物件回 `none`，註解寫「刻意」），計畫 `:30` 與 `:102`。

輪1-R4-5｜小事｜S2-1 第 1 點寫「不動…各專案的 hook」，會讓讀者以為 uninstall 後專案 gate 照常運作。實際上腳本被移除後，project hook 只印警告、然後放行，整個 gate 停止檢查。計畫的逐句核對表只會對 uninstall 的程式碼，抓不到這個退化。｜證據：`commands/dd-init.md:203`（`if [ -x … ]; then … else echo "⚠️ CLAUDE.md gate 沒執行…" >&2; fi`，沒有 exit）、`install-dd-pipeline.sh:1142` 附近 uninstall 會刪 `DD_SCRIPTS`（含 check-claude-md.sh）。

輪1-R4-6｜小事｜驗證只寫「本機 ci.yml 20 個 step 全過」，那是 `lint` job 的數量（10–563 行）。`macos-latest` job（564 行起）另外 6 個 step，包括「確認 /bin/bash 是 3.2」、gate 情境測試與 test-install。S1-2 的 bash 3.2 相容性只能靠這些 step，計畫沒把它們列進驗收。｜證據：`.github/workflows/ci.yml:20-556`（20 個 named step）、`:572-593`（6 個 named step）。

輪1-R4-7｜小事｜S2-1 第 6 點要求 README 寫迴圈的時間與費用，但計畫沒規定寫樣本數 n=2，也沒要寫「分不出差異」。269s、5.13 美元那組是 n=2、3 個可計分錯誤，量測檔自己說「分不出是不是真的比較準」；11.8 分中位數來自一台機器、排除公司專案、近 30 天樣本，量測檔也有自己的註記。直接寫進 README 會把不確定的數字當成結論。｜證據：`docs/measurements/2026-10-23-reviewer-real-sessions.md:4`（近期樣本）、`:198`（n=2、分不出差異）、`:225`（每格 n=2）、`:361`（差 1 個分不出是不是真的比較準）。

輪1-R4-8｜小事｜A2 的理由「settings.json 可能放 token」沒有證據，也沒標註來源，違反全域 §2.2。｜證據：計畫 `:100`；沒有任何檔案或量測支持這句。

輪1-R4-9｜小事｜範圍縮到 2 項（4、5）是計畫自己選的。使用者只說「請你優化改善」，事實 `:117` 也寫「使用者沒有指定要改哪幾項」。這不算重大（不符合 ③），但 §6.1 要改變範圍時該先問。見下方外部查證項。

【需要外部查證】

輪1-R4-10｜小事｜計畫新增 T3–T9 七組測試，事實 `:122` 聲稱「task-planner 步驟 4 的測試清單題選定的清單就是使用者要求加的測試」。計畫引用的使用者原話（`:113-114`）裡沒有這句。全域 §3.5 只允許使用者要求或修 bug 時新增測試。為什麼需要查證：要看當初的對話紀錄，確認使用者真的在那題選了這份清單；如果沒有，T3–T9 就違反 §3.5。

輪1-R4-11｜小事｜審查包說 repo 在 HEAD `b1935bb`、本機比 origin/main 多 34 個 commit（F1、F15）。這個工作目錄的 HEAD 是 `f57cde6 base`，只有一個 commit，`git cat-file -t b1935bb` 失敗，`git branch -a` 只有 `master`。行號與檔案內容都對得上，但 commit 數、ubuntu job 沒跑過那 34 個 commit 這些事實，我在這裡無法重現，需要在原始環境核對。
