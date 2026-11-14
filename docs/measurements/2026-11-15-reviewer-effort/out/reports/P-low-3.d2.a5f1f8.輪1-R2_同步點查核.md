【我查了什麼】
- 讀 `CLAUDE.md`、`tests/CLAUDE.md`、`scripts/CLAUDE.md`，以及 `.github/workflows/ci.yml`、`README.md`、`README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md` 的相關行。
- 跑了 `grep -n '進度以' CLAUDE.md`，無輸出。
- 跑了 `grep -rn -E '同批|同步|要一起|同時改' CLAUDE.md tests/CLAUDE.md scripts/CLAUDE.md docs/CLAUDE.md`，命中的規則已逐條對照計畫（PROMOTED 陣列、`DD_PIPELINE_ARCHITECTURE.md` CI 防線表、`tests/CLAUDE.md` 的 test-install 列、README 同批更新）。計畫都有涵蓋。
- 跑了 `grep -n -E 'shellcheck|tests/' .github/workflows/ci.yml`：`tests/test-install.sh` 在 ShellCheck 清單內（ci.yml:34-36），ubuntu 與 macOS 兩個 job 都跑它（ci.yml:557、594）。
- 跑了 `grep -n -E '不裝|don.t install' README.zh-TW.md README.md DD_PIPELINE_ARCHITECTURE.md`：「don't install the gate」在 README.md:156、README.zh-TW.md:167 各一處，計畫 S2 第 8 項有涵蓋；DD_PIPELINE_ARCHITECTURE.md:12 是「全域 CLAUDE.md 預設不安裝」的相關敘述，不是同一句。
- 跑了 `grep -n 'claude-md-management' README.md README.zh-TW.md`、`grep -n -E 'uninstall|backups' README.md README.zh-TW.md`、`grep -c '8 步'`、`grep -c '8-step'`（兩份各 8）、`grep -n '## 未發布' CHANGELOG.md`（有）。
- 計畫前提中「根目錄 CLAUDE.md 沒有進度指路句」「tests/CLAUDE.md 有 test-install 列」「README 的 `--uninstall` 行在 README.md:70、README.zh-TW.md:71」都成立。

【批評】
- 輪1-R2-1｜重大｜計畫建了一張新的進度表（`docs/designs/…-installer-hardening-design.md`），但沒有在根目錄 CLAUDE.md 加指路句。全域 CLAUDE.md §4.4 明文要求「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」。計畫開頭還自己寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，等於看見了缺口卻沒排進 S1 或 S2 的文件同步。證據：`grep -n '進度以' CLAUDE.md` 無輸出；全域 CLAUDE.md §4.4 的規定（系統提供的全域規則原文）。影響：下一個 session 讀根目錄 CLAUDE.md 時看不到這張表，§4.1 會重估段落數、另開第二張表，S1 的 commit 範圍與 IN_PROGRESS 狀態就這樣遺失。這不會被 gate、code-review 或測試抓到，屬於③。修法：S1 文件同步加一條「根目錄 CLAUDE.md 第一個 `##` 前加指路句」，並把 `grep -n '進度以' CLAUDE.md` 列為驗收。
- 輪1-R2-2｜小｜S1 文件同步沒列 `DD_PIPELINE_ARCHITECTURE.md:12`。那裡寫「全域 CLAUDE.md 那步預設不安裝」，與 S2 第 8 項要改寫的「don't install the gate」屬同一個安裝情境。計畫只寫「有同一句時一起改」，但這句不是同一句，會漏。證據：DD_PIPELINE_ARCHITECTURE.md:12。
- 輪1-R2-3｜小｜S2 第 2 項「覆蓋行為」與 `README.md:82`、`README.zh-TW.md:84` 已寫明的「舊版備份到 `~/.claude/backups/pre-install-<時間戳>/`」重複。計畫把它寫成新增內容，會造成兩段說法不同步。證據：README.md:82 原句「The previous version is backed up to `~/.claude/back…」。
- 輪1-R2-4｜小｜驗證只寫「本機重跑 ci.yml 全部 step」。ShellCheck 與 `tests/test-install.sh` 的 ubuntu job 在這份計畫的驗證裡只靠本機跑；計畫沒寫 bash 3.2（`/bin/bash`）要跑 T2，只寫「本機」。本機 macOS `/bin/bash` 是 3.2，所以實際會跑到，但計畫沒明寫 `/bin/bash` 這個前提。證據：ci.yml:587-594（macOS job 用 `/bin/bash`）。

【需要外部查證】
- 無。以上都可用本地 grep 與讀檔確認。
