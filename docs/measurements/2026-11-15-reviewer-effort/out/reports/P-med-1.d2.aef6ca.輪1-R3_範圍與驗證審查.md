【我查了什麼】
- 讀 `install-dd-pipeline.sh`：156–163（`command_exists`）、187–196（`backup_before_overwrite`，複製行是 `cp -r`）、209–222（`jq_inplace`）、730–734（`install_plugins` 的 jq/python3 檢查）、889–921（`deprecated_dd` 刪除與備份）、1059–1070（`uninstall` 印的清單）、1241–1262（`show_completion`）。`print_step` 的實際標籤見 731（`print_step "5/7" "啟用官方 Plugins"`）。
- 讀 `tests/test-install.sh` 全 87 行：沒有任何 plugin、`~/.claude.json`、覆蓋前備份或全域 CLAUDE.md 相關的斷言；只有 `--help`、`--check`、首次安裝、冪等、`--force`、`--update`、`--commands-only`、`--uninstall` 的斷言。
- 讀 `.github/workflows/ci.yml`：lint job（ubuntu-latest）共 20 個 `- name:`；macOS job 在 563 起，含 `/bin/bash` 3.2 檢查與 gate／hook 測試；「迴圈步數第五方」在 496–546，掃全部 `*.sh`、`*.md` 裡箭頭 ≥3 且同時含 commit 與 review 的段落。
- 讀 `skills/self-improving-agent/hooks/hooks.json`：PostToolUse、matcher Bash，指令是 `$HOME/.claude/skills/self-improving-agent/hooks/error-capture.sh`。
- 讀 `tests/CLAUDE.md` 第 11 列（`test-gate.sh`）與 `test-install.sh` 那一列；`DD_PIPELINE_ARCHITECTURE.md` 的「可回復」「JSON 就地改寫保留 inode」（72–74）與 CI 防線表（137）；`CHANGELOG.md` 有 `## 未發布`；`agents/code-reviewer.md:4` 是 `model: opus`；`docs/measurements/2026-10-23-reviewer-real-sessions.md` 有費用欄（143、163，合計約 US$34.7，14 發）。
- grep `grep -rn '新增\|同時改\|同批\|要一起\|同步' --include=CLAUDE.md .`：與本計畫相關的規則是根目錄 CLAUDE.md 的「新增 Script 步驟」（144–156）、「新增 Output Style」（158–165，要求 `show_completion()` 的 case 同批補）、「修改 scripts 後務必同步更新 DD_* 陣列」（236）、「README 內容須同批更新」（243）。計畫沒有違反這些，但 S1 沒有列出 `DD_PIPELINE_ARCHITECTURE.md` 的「可回復」與 `scripts/` 以外的同步點以外的檢查。
- 沒有跑任何測試、安裝或容器。

【批評】
輪1-R3-1｜重大｜計畫以「使用者先前講定」為依據新增 T1–T9（9 組測試），但事實段落的逐字使用者發言只有兩則，沒有任何「測試清單題」的選定紀錄。全域 §3.5 規定「不主動新增測試」。如果這個授權是計畫作者推斷的，照做就是違反使用者規則，而且 code-review 與 gate 都不會檢查「這些測試是不是使用者要的」。證據：事實段落「使用者講過的話（逐字，依序）」只列兩則；「使用者先前在這個 repo 講定的事」一行的依據沒有對應的逐字紀錄；全域 `templates/global/CLAUDE.md:197`「不主動新增測試」。（只有在使用者確實選過清單時這條不成立；計畫要先附那則原文。）

輪1-R3-2｜一般｜S1-4 的完成訊息文字寫「原因見上方步驟 5」，但安裝腳本印出的標籤是「5/7」（`install-dd-pipeline.sh:731`），而且 `--commands-only` 時步驟 5 根本不印。文字與實際輸出對不上，T9 也沒有斷言這句話。證據：`install-dd-pipeline.sh:731`；`:1251-1254` 的 agent 與 plugin 段目前無條件印出。

輪1-R3-3｜一般｜T2 要在 macOS runner 上同時走 jq 與 python3 兩條路徑，計畫假設 `macos-latest` 有 jq。若沒有，jq 那條會在 CI 直接紅（報錯，不會靜默），但計畫沒有寫這個前提，也沒有寫「macOS job 沒有 jq 時的處置」。證據：`install-dd-pipeline.sh:402`、`:635`（jq 分支）；`.github/workflows/ci.yml:563` 起的 macOS job 沒有安裝 jq 的 step。

輪1-R3-4｜一般｜S1 的驗證只寫「本機 ci.yml 20 個 step 全過」。ubuntu job 的 `test-install.sh` 在 bash 5 + GNU coreutils 下的完整執行，計畫沒有本機對應的驗證（F15 也說 ubuntu job 的 34 個 commit 從未跑過）。T1 的 GNU 紅綠只在 debian 容器裡做單函式重現，沒有跑整支測試。證據：`.github/workflows/ci.yml:556`（ubuntu job 的 test-install step）；計畫 S1 驗收條款。

輪1-R3-5｜一般｜A1 選了弱項 4 與 5，但使用者的原話是「請你優化改善」，前一則評分明確寫「挑一個弱項叫我修。我建議先修第 4 項」。使用者沒有指定，計畫自行決定做兩項，並把 S2（README）列為可做。這是範圍擴大、且跳過了使用者「挑一個」的決定。證據：事實段落第 2 則使用者發言與前一則評分的結尾句。

輪1-R3-6｜一般｜S1-2 的規則寫「頂層不是物件 → 兩條路徑都算失敗」，但 A4 又保留 `plugin_enabled_state` 對頂層非物件回 `none`。計畫對同一類輸入給了兩個不同的結論，T2 的「三類定案」斷言沒有寫清楚 `plugin_enabled_state` 屬於哪一類。證據：`install-dd-pipeline.sh:397–413`（`plugin_enabled_state`）；計畫 A4 與 S1-2 的定案段。

輪1-R3-7｜一般｜T9 與「迴圈步數第五方」的關係：計畫說「開發：實作+測試 → …」那行不動，這是對的（`install-dd-pipeline.sh:1247`）。但第五方掃的是所有 `*.sh`，若 T9 或新加的測試字串含 3 個以上 `→` 且同時含 commit 與 review，會被當成迴圈摘要而讓 CI 紅。計畫沒有檢查新測試字串。證據：`.github/workflows/ci.yml:517–525`。

【需要外部查證】
輪1-R3-8｜一般｜`macos-latest` runner 預設是否有 `jq` 與 `python3`（影響 T2 在 macOS job 的兩條路徑是否都跑得到）。需要查 GitHub runner-images 的軟體清單，我沒有上網查證。

輪1-R3-9｜一般｜T1 在 GNU 上的紅綠結論（F5）依賴 debian:bullseye 的 coreutils 8.32；計畫說 CI ubuntu runner 也是 GNU，但沒有確認 ubuntu-latest 的 coreutils 版本是否會讓 `cp -r` 對 symlink 的行為不同。需要查 ubuntu-latest 映像的 coreutils 版本。
