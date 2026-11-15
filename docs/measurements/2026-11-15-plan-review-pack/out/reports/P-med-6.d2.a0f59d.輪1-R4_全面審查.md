【我查了什麼】
- 讀完審查包 `prompts/P-med-6.pack.md`（166 行，一次讀完）。以下路徑都相對於 `<暫存區>/s3/work6/P-med-6`。
- `grep -n 'translating the global\|--force\|--uninstall\|don.t install the gate\|claude-md-management\|skill-creator@' README.md`：README 第 19、38、67、70、71、156、191 行的原文與計畫 F16 一致。
- `grep -n '已啟用\|已安裝的內建\|開發：\|Plugin' install-dd-pipeline.sh`：完成訊息在 1249–1254 行，與 F10 一致。
- `grep -rn '已啟用的 Plugin\|已安裝的內建\|commands-only' .github tests README*.md DD_PIPELINE_ARCHITECTURE.md scripts`：CI 沒有讀完成訊息字串，只有 `--commands-only` 的 flag 對照。
- 讀 `.github/workflows/ci.yml`：`lint` job（10–561 行）的 step 數經 awk 數過是 20；另有 `bash32` job（562–593 行，`runs-on: macos-latest`）有 8 個 step。
- 讀 `install-dd-pipeline.sh` 187–194（`backup_before_overwrite(category, target)`）、209–245（`jq_inplace`、`py_inplace`）、1241–1262（`show_completion`）、1060–1110（`uninstall`）。
- 讀 `skills/task-planner/SKILL.md` 119–150：進度表格式與「開工：`--start-segment` 記起點、標 IN_PROGRESS」「小任務 commit 帶編號」等規則。
- 讀 `scripts/check-claude-md.sh` 11–20：`--start-segment` 與 `--segment-base` 的語意；`docs/reviews/` 存在時要求上一段有 `S*.md` 報告。
- `grep -n '進度' CLAUDE.md`：只命中第 187 行（核心工作法段），沒有「進度以…為準」的指路句。根目錄 CLAUDE.md 第一個 `##` 在第 5 行。
- 讀 `commands/dd-init.md` 252–269：使用者不裝 gate 時跳過第 4 步、第 5 步改講「這個 repo 沒裝 gate」。
- 讀 `skills/self-improving-agent/hooks/hooks.json`：PostToolUse（Bash）掛 `error-capture.sh`。該目錄有 `.claude-plugin/`。
- 讀 `docs/measurements/2026-10-23-reviewer-real-sessions.md` 1–12 與 86 行：數字（311／11.8／27.7）與計畫一致，但這份是 30 天 session 時間分布，不含費用。`skills/dd-loop/SKILL.md:66`：2026-10-24 的費用數字，文字自己註明「n 小」。
- `ls docs/reviews`：有 `2026-10-07-review-followups` 等子目錄，表示專案採用了審查報告慣例。
- `grep -n 'set -' install-dd-pipeline.sh tests/test-install.sh`：只有 `set -e`，沒有 `set -u`。

【批評】
- 輪1-R4-1｜重大｜計畫沒有安排在根目錄 CLAUDE.md 加進度表的指路句。全域 §4.4 規定：環境沒有 Task 工具時退化成檔案式追蹤，開表的同時要在根目錄 CLAUDE.md 第一個 `##` 之前加指路句。計畫第 162 行正說明沒有 Task 工具，但 S1 文件同步（第 54 行）只寫「只補這次留下的坑，不改既有規則」。下一個 session 只讀 CLAUDE.md 就看不到表，依 §4.4 會重估段落、另開第二張表，先前的 commit 範圍就遺失。這每次開新 session 都會經過（①）；照做後接手者找不到表（②）；沒有任何檢查抓得到（③），gate 與 CI 都不驗指路句。證據：計畫第 6、54、162 行；`grep -n '進度' CLAUDE.md` 只有第 187 行；根目錄 CLAUDE.md 第 5 行是第一個 `##`。
- 輪1-R4-2｜中｜開工程序漏掉 `--start-segment` 與 IN_PROGRESS。全域 §3.9 規定段落開始前要記起點（印出「段落起點」才算記好），task-planner 規定開工時把該段標 IN_PROGRESS。計畫的進度表全是 TODO，沒有任何一處寫這兩步。不記起點時，步驟 8 的 `--segment-base` 會失敗，步驟 3、4 的範圍也算不出來。這會報錯，所以不算靜默（③ 不成立）。證據：計畫第 12–13 行；`scripts/check-claude-md.sh:13-14`；`skills/task-planner/SKILL.md` 第 119–150 行「開工」條目。
- 輪1-R4-3｜中｜計畫完全沒有寫步驟 3、4、6、7、8。全域 §3.9 與 dd-loop 規定每段都要 code-simplifier、至少 3 個 code-reviewer，並把報告落地成 committed 的 `docs/reviews/S<段落>-*.md`。`check-claude-md.sh:15-17` 規定：專案有 `docs/reviews/` 時，`--start-segment` 要求上一段範圍內有新增報告。計畫只在進度表欄位寫「驗收（步驟 5 要看到什麼）」，所以執行者可能跳過步驟 4 而不自知。gate 會在下一段開工時擋下，所以不算靜默（③ 不成立），定為中。證據：計畫第 12 行表頭；`scripts/check-claude-md.sh:15-17`；`ls docs/reviews`。
- 輪1-R4-4｜中｜S1-4 的呼叫簽章寫錯。計畫寫 `backup_before_overwrite "commands"`，缺第二個參數 target。函式第 187–194 行先做 `[ -e "$target" ] || return 0`，target 為空時直接 return 0，不備份，之後 `rm` 照刪。T8 會變紅，所以不算靜默，但照字面寫會一路紅到執行者查出來為止。證據：`install-dd-pipeline.sh:187-194`（函式簽章 `local category="$1" target="$2"`）；計畫第 47 行。
- 輪1-R4-5｜中｜S2 第 1 項要寫進 README 的「不動…各專案的 hook」會誤導讀者。安裝腳本自己在 uninstall 時印「含 pre-commit gate — 移除後各專案掛著的 hook 會失效」（`install-dd-pipeline.sh:1067`），而 `commands/dd-init.md:254` 寫明沒有 gate 腳本時 hook 放行並印警告。README 只寫「不動 hook」，讀者會以為 gate 仍在擋，實際上已經沒有強制力。證據：計畫第 71 行；`install-dd-pipeline.sh:1067、1099`；`commands/dd-init.md:254`。
- 輪1-R4-6｜中｜驗證只覆蓋 lint job。S1 寫「本機 ci.yml 20 個 step 全過」，但 `bash32` job（`.github/workflows/ci.yml:562-593`）另有 8 個 step，包含「確認 /bin/bash 是 3.2」與「Sandbox 端到端安裝測試」。S1 改的安裝腳本與新測試正是在 bash 3.2 上跑。S2 又寫「本機重跑 ci.yml 全部 step」，與 S1 的 20 不一致。證據：`.github/workflows/ci.yml:10`（lint）與 `:562-593`（bash32）。
- 輪1-R4-7｜小｜F20 的前提錯誤：計畫寫「don't install the gate 在 repo 裡沒有對應做法」，但 `commands/dd-init.md:264-269` 寫了使用者不裝就跳過第 4 步。S2 第 2 項會查到，但若照 F20 的說法改寫 README 第 156 行，會把一句大致正確的話改錯。證據：計畫第 158 行；`commands/dd-init.md:254、264-269`。
- 輪1-R4-8｜小｜A4 保留 `plugin_enabled_state` 對頂層不是物件回 `none`，同一份計畫第 30 行卻定案頂層非物件「兩條都算失敗」，`mcp_scope` 回 `unparseable`。`none` 是「確定未啟用」的斷言，與根目錄 CLAUDE.md「注意事項」的「檢查類輸出的鐵則：不確定就說不確定」衝突。證據：計畫第 30、102 行；`install-dd-pipeline.sh:393-397`。
- 輪1-R4-9｜小｜S2 第 6 項的費用數字只有一次量測。`skills/dd-loop/SKILL.md:66` 的 5.13 美元與 3.83 美元是 n 小、同時改了三件事的單次結果；計畫只說要「附樣本數」，沒寫明是 n=1。2026-10-23 的檔案只有時間，不含費用。證據：`skills/dd-loop/SKILL.md:66`；`docs/measurements/2026-10-23-reviewer-real-sessions.md:1-12`。

【需要外部查證】
- 輪1-R4-10｜中｜self-improving-agent 的 hook 是否在使用者安裝後真的全域生效。計畫第 75 行寫「全域會掛」，但依據只有 `hooks.json` 的存在；載入方式取決於 Claude Code 如何把 `~/.claude/skills/<名字>` 當 plugin 讀（目錄有 `.claude-plugin/`）。這需要在乾淨 HOME 裝後實測 hook 是否觸發，或查 Claude Code plugin 載入文件。
- 輪1-R4-11｜小｜`jq -e 'type == "object"'` 對空輸入回 4 這件事，以及 jq 1.6／1.7 的差異，計畫第 33 行沒有實測依據。CI 的 ubuntu 與 macOS 的 jq 版本不同，需要在兩邊各跑一次確認。
- 輪1-R4-12｜小｜`cp -RL` 對 symlink 的行為在 GNU（debian:bullseye）與 BSD（macOS）是否如計畫第 24 行所說。計畫還沒實跑，F5 只有 `cp -r` 的結果。
