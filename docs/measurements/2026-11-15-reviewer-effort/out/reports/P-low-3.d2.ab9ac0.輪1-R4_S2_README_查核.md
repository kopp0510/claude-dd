【我查了什麼】
- `agents/code-reviewer.md:4` 與 `agents/code-simplifier.md:4` 是 `model: opus`。
- `skills/dd-loop/SKILL.md:61` 寫「最少 3 個」，`:93` 寫跳過時建 `SKIP.md`，`:66` 的 5.13 美元／3.83 美元數字，註明「n 小…只是方向」。
- `docs/measurements/2026-10-23-reviewer-real-sessions.md` 開頭量的是 subagent 耗時（時間），不是費用。
- `skills/self-improving-agent/hooks/hooks.json`：PostToolUse、matcher Bash，指令是 `$HOME/.claude/skills/self-improving-agent/hooks/error-capture.sh`。`error-capture.sh:3` 寫「Fires on PostToolUse (Bash) to detect command failures」。
- `install-dd-pipeline.sh:43,47` 只把 gate-guard 與 self-improving-agent 列在陣列裡。`grep -n 'skills-dir\|self-improving\|gate-guard'` 只有這兩行，沒有任何程式碼登記 `hooks.json`。
- `install-dd-pipeline.sh` 的 `uninstall()`（:1059）與 `backup_before_overwrite`（:187）呼叫點 :528、:604、:921、:957、:1006、:1046。我沒讀每個呼叫點的條件，只確認它們存在。
- README 行號：`README.md:19`、`:38`、`:67`、`:70` 與計畫引的原文一致。`README.md:82` 已經寫了「`--force` 不問直接覆蓋全域 CLAUDE.md」，計畫 S2-1 第 2 項與它重複。`README.md:141` 的「What it costs」段存在。`README.md:156` 沒核對。
- `.github/workflows/ci.yml:239-263`（flag 三方對照，只抓 `./install-dd-pipeline.sh` 後面的 flag）、`:304-322`（迴圈步數，只數編號清單）。沒有任何 step 檢查 README 的散文宣稱。
- `commands/dd-init.md` 的 commit 語言沒有核對。`UPGRADING.md` 與 `CHANGELOG.md` 沒有讀。

【批評】
輪1-R4-1｜中｜計畫 S2-1 第 6 項要寫「每段至少 3 個 opus 審查者」，缺跳過條款，而且費用數字沒有一致的來源。`dd-loop` 的 SKIP 路徑（`SKILL.md:93`）會讓「每段」不成立。`2026-10-23` 量測檔量的是時間，計畫把它和「費用」並列。費用的 5.13／3.83 美元來自 `SKILL.md:66`，樣本只有 6 個、作者自己寫「只是方向」。README 寫成無條件的數字，會誤導讀者。
證據：`skills/dd-loop/SKILL.md:61`、`:66`、`:93`；`docs/measurements/2026-10-23-reviewer-real-sessions.md:1-3`。

輪1-R4-2｜中｜S2 的驗收抓不到 README 寫錯的事實。CI 早就全綠（F1），而且沒有任何 step 檢查 README 的散文。唯一的「逐句核對」表由同一個寫文件的 agent 產生。計畫列的「本機重跑 ci.yml 全部 step」對 README 內容沒有鑑別力。若某句宣稱錯了（例如第 2 項的 `--force` 範圍、第 6 項的費用），CI 與 gate 都不會攔，後面的 code-review 也未必看得出來。
證據：`.github/workflows/ci.yml:239-263`、`:304-322`（只驗 flag 名稱與數字）；`README.md:82` 與計畫第 2 項的重複也說明沒有任何機制對照它們。

輪1-R4-3｜小｜計畫第 5 項說 self-improving-agent 的 hook 是「全域會掛的 hook」，但安裝腳本沒有任何讓它生效的路徑。它在 `PROMOTED_SKILLS` 裡，只代表檔案會被複製到 `~/.claude/skills/`。hook 生效與否，我沒證據支持。計畫的 README 寫法會把這句當成事實。
證據：`install-dd-pipeline.sh:47`，以及 `grep -n 'skills-dir\|self-improving\|gate-guard' install-dd-pipeline.sh` 的結果（只有 :43、:47）。

【需要外部查證】
輪1-R4-4｜中｜Claude Code 是否會從 `~/.claude/skills/<名字>/hooks/hooks.json` 載入 hook。計畫的 README 第 5 項與 CLAUDE.md 寫的 `<名字>@skills-dir` 載入方式，在安裝腳本裡找不到對應程式。要驗證就得在乾淨的 HOME 裝一次並看 `/hooks` 或 `claude -p` 的輸出，這需要跑安裝與 Claude Code，我這次沒做。

【未核對、計畫應補】
- 計畫第 4 項「會用繁體中文回覆與寫 commit」與「`/dd-init` Phase 5 寫一筆中文訊息」，我沒讀 `commands/dd-init.md` 的 Phase 5 指令與全域 §1.1 的條件，不確定。
- 計畫第 1 項「不動各專案的 hook 與蓋章區塊」，`uninstall()` 內沒有 `CLAUDE.md`、`backups`（F11 已確認），但我沒核對它是否碰專案 hook。
