Critical 0 / Important 0 / Smells 0 — 範圍：快照 `git diff HEAD~1 HEAD` 的 8 檔，重點 `tests/test-gate.sh` 新增的「已知的三條繞過路徑」區塊（diff 檔第 2584–3024 行）。

沒有找到會讓測試假綠、假紅，或讓文件與程式碼對不上的問題。

已對照程式碼確認的部分：
- 繞過①：`scripts/check-claude-md.sh:229–242` 的 pre-commit 路徑（`$#`=0）完全沒有呼叫 `reviews_missing`，只有 `--start-segment`（`:201`）會擋，測試 `:320` 的放行判定與文件一致。
- 繞過③：`:231` 沒有起點檔時 `read_base` 失敗，`reviews_missing`（`:162`）回 1、`owed_dirs` 也不跑，所以 `rm` 起點檔後 `--start-segment` 放行，與 `:353` 的預期一致。
- 繞過②：`:337` 的放行與 `:333–334` 的對照，依 `reviews_missing` 的 `base..HEAD` 範圍（`:185`）推得結果相反，斷言成立。
- 所有 `said` 字串在閘門裡都有對應輸出：「上一段沒有附 review 報告」（`:202`）、「還有 commit 跳過檢查」（`:195`）、「先補完再記新起點」（`:196`）、「沒有新增任何 docs/reviews/S*.md」（`:203`）。
- 暫存目錄由 `trap` 清除（`:17`）；新增的 `expect` 都有包住，沒有裸跑會非零回傳的指令（`:183` 的 amend 已包）；沒有 bash 3.2 不相容語法（`bash -n` 通過）。

What I ran
- `bash -n tests/test-gate.sh` → 無輸出，SYNTAX_OK
- `grep -n` 於快照 `scripts/check-claude-md.sh` 的 review、起點、訊息字串 → 行號見上
- `grep -n 'WORKTREE_INFO\|\.env' skills/worktree-manager/SKILL.md` → `:20`、`:23`、`:35–38` 與 diff 的敘述一致
- `sed` 讀 diff 檔全部區段（`offset`/`limit` 每次 300 行）→ 讀完全部 3024 行

Not reported
- 我沒有重跑 `tests/test-gate.sh`，也沒有跑任何變異實驗；`scripts/CLAUDE.md` 與 `tests/CLAUDE.md` 裡的變異表與紅數（如「2026-10-19 實測」）只是讀過，未獨立驗證。
- `skills/worktree-manager/SKILL.md` 的 git 行為（`git worktree remove` 對 untracked／ignored 檔的拒絕與刪除行為、英文錯誤訊息原文）是 git 的外部行為，我沒有查證。

需要外部查證（交回主對話）
- 在 git 2.42.0 與 2.54.0 上實跑 `git worktree remove`，確認：有 untracked 或 modified 時會拒絕並給出該英文訊息；`!!` 被 ignore 的檔會被直接刪掉。
- 在 bash 3.2 與 bash 5 下各跑一次 `tests/test-gate.sh`，確認預期 105 ✅ / 0 ❌ 的數字（CI 的 ubuntu 與 macOS job 會跑）。
- 依 `scripts/CLAUDE.md` 的變異表，對「pre-commit 也查報告」「`--start-segment` 無起點檔時拒絕」「無起點檔時從空樹記起」三個變異各跑一次，確認宣稱的變紅情境。