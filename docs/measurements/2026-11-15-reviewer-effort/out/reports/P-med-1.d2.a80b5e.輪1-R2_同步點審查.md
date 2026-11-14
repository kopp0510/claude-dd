【我查了什麼】
- 讀 `CLAUDE.md`、`skills/task-planner/SKILL.md`、`install-dd-pipeline.sh`、`.github/workflows/ci.yml`、`DD_PIPELINE_ARCHITECTURE.md`、`tests/CLAUDE.md`、`README.md`、`README.zh-TW.md`。
- `grep -n '進度以' CLAUDE.md`：無輸出。計畫的前提成立，根目錄 CLAUDE.md 目前沒有指路句。
- `ls docs/designs | wc -l`：7，與計畫一致。
- `grep -n -A12 '進度表格式' skills/task-planner/SKILL.md`：第 121 行「規則區塊整段照抄：接手的 session 只讀文件、沒載入本 skill，也要照得做」。
- `grep -n -E 'runs-on' .github/workflows/ci.yml`：`lint` 在 ubuntu-latest（第 12 行），macOS job 在第 564 行。
- `grep -n 'cp -r' install-dd-pipeline.sh`：第 194 行 `backup_before_overwrite` 用 `cp -r`，與計畫一致。
- `grep -n 'FORCE' install-dd-pipeline.sh`：agents、commands、scripts、output-styles 的覆寫都有 `$FORCE` 只影響印出的字樣，README 第 2 項的說法成立。
- `grep -n 'uninstall' install-dd-pipeline.sh` 與 `grep -n backups`：uninstall 不碰 `backups`、不碰 `CLAUDE.md`，README 第 1 項的說法成立。
- `grep -n '未發布' CHANGELOG.md`：第 19 行有，計畫的 CHANGELOG 位置成立。
- `grep -n '可回復\|inode' DD_PIPELINE_ARCHITECTURE.md`：第 72、74 行，計畫說要補 symlink 的那條存在。
- `grep -n -E 'test-install' DD_PIPELINE_ARCHITECTURE.md`：第 137 行的 CI 防線表列存在。
- `grep -rn -E '已啟用的 Plugin|已安裝的內建 Agents' .github tests`：無輸出，完成訊息的改動不會被 CI 字串比對擋住。
- `CLAUDE.md` 第 220 行：`~/.claude/` 路徑掃描範圍包含 `tests/`。
- `ci.yml` 第 370–402 行：路徑存在性檢查的邏輯，`commands/dd-*.md` 與 `commands/?*` 都會要求 repo 裡有該檔。
- `ls commands/`：只有 `dd-init.md`、`workflow-review`，沒有 `dd-help.md`。

【批評】
輪1-R2-1｜重大｜計畫沒有在開表時加根目錄 CLAUDE.md 指路句。全域 §4.4 規定「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，計畫的前提也寫明根目錄沒有這句，但 S1 的根目錄 CLAUDE.md 只列「只補這次留下的坑，不改既有規則」，沒有指路句。照計畫做，之後的 session 只會讀根目錄 CLAUDE.md，看不到 `docs/designs/2026-11-14-installer-hardening-design.md` 的進度表，會依 §4.1 重估段落數、另開第二張表，S1 的 DONE 與 commit 範圍就這樣遺失。證據：`grep -n '進度以' CLAUDE.md` 無輸出；全域 §4.4 原文；計畫 S1 的「根目錄 CLAUDE.md」條目。理由：只要工作跨 session 就會發生（S1 與 S2 各要走完 8 步，本來就可能跨 session）；沒有 gate、CI、測試會檢查指路句是否存在；後果是下一個 session 靜默地重做規劃，不會報錯。

輪1-R2-2｜中｜設計文件的四節（來源、假設、進度表、段落與小任務）沒有「規則區塊」。`skills/task-planner/SKILL.md:121` 規定規則區塊「整段照抄：接手的 session 只讀文件、沒載入本 skill，也要照得做」。計畫沒寫要照抄，接手的 session 讀不到「狀態只有 TODO/IN_PROGRESS/BLOCKED/DONE」、「同時最多一段 IN_PROGRESS」、「DONE 補 commit 範圍」、「全部 DONE 時刪指路」這些規則，會照錯的格式改表。證據：`skills/task-planner/SKILL.md:121`；計畫「進度表草稿」與「假設」的結構。理由：每次開表都會遇到（常走）；照計畫寫出的文件會讓接手者照錯的方式改（照做會錯）；沒有任何機械檢查會抓到（③）。

輪1-R2-3｜中｜S1 的驗證只在本機跑，抓不到 Linux 那一支的錯。`ci.yml:12` 的 ubuntu lint job 用 GNU cp 與 ubuntu 的 jq；`ci.yml:564` 的 macOS job 用 `/bin/bash` 3.2。計畫 A6 規定不 push，所以 CI 本身在 S1 完成前不會跑。計畫的 T1 在 GNU 上變紅，只靠 `docker run debian:bullseye` 裡臨時 source 再呼叫 `backup_before_overwrite` 的實驗，沒有讓 `tests/test-install.sh` 在 GNU 上跑過；T2 的 16 例 jq/python 不一致也只在本機 macOS 的 jq 版本上量過。證據：`ci.yml:12`、`ci.yml:564`；計畫 S1-1 驗證、S1 驗收「本機 ci.yml 20 個 step 全過」。理由：這不是靜默失敗（push 後 CI 會紅），所以只列為中。但計畫的驗收把「本機全過」寫成完成條件，等於在沒跑 GNU 的情況下宣稱完成。

輪1-R2-4｜小｜T8 的路徑寫法有 CI 風險。`tests/` 在 `~/.claude/` 掃描範圍內（`CLAUDE.md:220`）。`ci.yml` 的檢查會擋 `~/.claude/commands/dd-help.md`，因為 repo 的 `commands/` 沒有 `dd-help.md`，且 `dd-*.md` 會被要求存在。計畫 T8 的描述寫的是 `~/.claude/commands/dd-help.md`，如果測試檔照字面寫成 `$HOME/.claude/...`，CI 會紅。證據：`ci.yml` 第 370–402 行；`ls commands/`；計畫 T8。這會紅，不是靜默，所以列為小。

輪1-R2-5｜小｜S1 的驗收引用了 repo 外的探針。「等價表探針 92 例不一致數從 16 變 0」的探針在 scratchpad，不在 repo（事實 F6 自己也寫「腳本在 scratchpad，不在 repo」）。設計文件寫進驗收後，之後的 session 無法重跑這個數字。應該把案例表搬進 `tests/test-install.sh`（T2 本來就是這樣做），驗收改指向 T2。證據：計畫 S1 驗收與 T2；事實 F6。

【需要外部查證】
輪1-R2-3｜中｜ubuntu 上的 jq（`jq -e` 的退出碼、`type` 的行為）與 macOS 的 jq 版本是否一致，會不會讓 T2 在 CI 上有不同結論。為什麼需要：需要在 ubuntu-latest 的 jq 版本上實跑，我沒有執行權限，這一點只能 push 後從 CI 看。
