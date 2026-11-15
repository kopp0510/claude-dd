【我查了什麼】
- 讀完審查包 `P-med-4.pack.md` 全部 166 行（offset 0、limit 300，最後一行是 `<<<審查包結束>>>`）。
- 讀 `install-dd-pipeline.sh` 第 180–442 行（`backup_before_overwrite`、`jq_inplace`、`py_inplace`、`json_edit`、`plugin_enabled_state`）、第 730–830 行（`install_plugins` 前段）、第 878–900 行（`create_commands` 的 `deprecated_dd`）、第 1241–1290 行（`show_completion`）。
- 讀 `tests/test-install.sh` 全部 87 行。
- 讀 `scripts/check-claude-md.sh` 第 240–321 行（SKIP 分支與 pre-commit 檢查）。
- 讀 `scripts/CLAUDE.md`，其中「SKIP 不是豁免」與 `reviews_missing` 的說明。
- grep 與結果：
  - `grep -n backup_before_overwrite install-dd-pipeline.sh` → 定義在 187，9 處呼叫都是兩參數（`"skills" "$target"` 等）。
  - `grep -n -E 'reviews_missing|diff-filter' scripts/check-claude-md.sh` → 178 定義、204 用 `--diff-filter=A -- docs/reviews`、220 `if reviews_missing; then`。
  - `ls docs/reviews` → 存在，有 10 個子目錄（`2026-10-07-review-followups` 等）。
  - `grep -n 'translating the global\|claude-md-management' README.md` → README.md:19 與 :38 的文字與計畫引用一致。
  - `grep -n '11\.8|27\.7' docs/measurements/2026-10-23-reviewer-real-sessions.md` → 第 86 行，數字與計畫 F17 一致。
  - `grep -n '269|5\.13|3\.83' skills/dd-loop/SKILL.md` → 第 66 行，數字一致。
  - `grep -n '可回復' DD_PIPELINE_ARCHITECTURE.md` → 第 74 行（計畫 F18 一致）。
  - `skills/self-improving-agent/hooks/hooks.json` → 掛的是 PostToolUse、matcher `Bash`、指令 `error-capture.sh`。
  - `CHANGELOG.md` 的 `## 未發布` 在第 19 行。
- 未核對：`uninstall()`（計畫 F11）與 `validate_skill_hooks`（F13）的內文我沒讀，那些陳述只有計畫自己的說法。

【批評】
輪1-R1-1｜重大｜計畫的兩個段落都沒排入 §3.9 的 8 步迴圈中的步驟 3（code-simplifier）、步驟 4（code-review）、步驟 5（再測）、步驟 7（沉澱）、步驟 8（CLAUDE.md 評分）。S1、S2 的流程只有小任務的 commit、驗收用的 `ci.yml` 與文件同步。照計畫做，code-review 不會跑，而且沒有任何關卡會發現。依 §3.9 步驟 4 規定，主對話要派 ≥3 個審查者，並把報告落地成 committed 檔。另外 `docs/reviews/` 目錄存在，意思是採用了報告慣例（見 scripts/check-claude-md.sh:15 的註解）。
證據：計畫 第 12 行（S1 驗收）、第 13 行（S2 驗收）、第 52–57 行（S1 文件同步）、第 80 行（S2 驗證）都沒有步驟 3、4、5、7、8；`~/.claude/CLAUDE.md` §3.9 規定這些步驟。
（③ 理由：pre-commit gate 只查 CLAUDE.md 有沒有一起 staged，不查 review；之後的 plan-review 不算。）

輪1-R1-2｜重要（非重大）｜`docs/reviews/` 存在，所以 gate 會要求 `--start-segment` 前一段在 commit 範圍內有新增 `docs/reviews/S*.md`。計畫完全沒提報告檔，S2 開工時 `--start-segment` 會 exit 1 擋下。
證據：`ls docs/reviews` 有 10 個子目錄；scripts/check-claude-md.sh:178–220（`reviews_missing` 用 `--diff-filter=A -- docs/reviews`，220 行 `if reviews_missing; then`）。
（它會報錯，所以不是 ③；但 S2 每次都會走到這裡，是 ①②。）

輪1-R1-3｜重要（非重大）｜S1-4 寫 `backup_before_overwrite "commands"` 只給一個參數。函式簽名是 `category target`（install-dd-pipeline.sh:187–188）。目標為空時 `[ -e "" ]` 為假，回 0，**靜默不備份**。現有 9 處呼叫都是兩參數（例如第 921 行 `backup_before_overwrite "commands" "$target"`）。T8 會因為備份目錄沒有 dd-help.md 而變紅，所以它不是 ③，但計畫的做法寫錯了。
證據：install-dd-pipeline.sh:187–189；計畫第 47 行。

輪1-R1-4｜重要（非重大）｜S1-1 到 S1-4 四個 commit 都是 `fix:`／`test:`，只改了 `install-dd-pipeline.sh`（根目錄，有 CLAUDE.md）與 `tests/test-install.sh`（tests/，有 CLAUDE.md）。pre-commit gate 會擋（scripts/check-claude-md.sh:259–293），除非用 `SKIP_DOC_CHECK=1`。計畫只在最後才同步文件，但中間四個 commit 沒有寫明要用 SKIP。
證據：計畫第 25、35、42、50 行的 commit 訊息與第 52 行「文件同步跟最後一個小任務一起 commit」；scripts/check-claude-md.sh:250–257（SKIP 只給檢查點 commit 用）、:319。

輪1-R1-5｜重要（非重大）｜S1-2 的定案與假設 A4 矛盾。第 30 行說「頂層不是物件 → 兩條路徑都算失敗、不改檔」，但 A4（第 102 行）要求保留 `plugin_enabled_state` 對頂層不是物件回 `none` 的既有設計。`plugin_enabled_state` 的 jq 分支在頂層非物件時回 `none`（install-dd-pipeline.sh:402–411，註解「刻意的」）。執行的人會面對兩條互相衝突的規則。
證據：計畫第 30 行與第 102 行；install-dd-pipeline.sh:403–411。

【需要外部查證】
輪1-R1-6｜小｜計畫第 33 行說 `jq -e 'type == "object"'` 在空輸入時回 exit 4。這個數字依 jq 版本而定，我沒有執行 jq（依規定不跑）。需要在 macOS jq 與 debian 的 jq 上各跑一次空檔案確認。
輪1-R1-7｜小｜計畫 S2-1 第 1 點說 `--uninstall` 不動 `~/.claude/backups/`、全域 CLAUDE.md 與各專案 hook。我沒讀 `uninstall()`（install-dd-pipeline.sh:1059 起），只有計畫的 F11 說法。寫進 README 前需要讀完那個函式核對。
