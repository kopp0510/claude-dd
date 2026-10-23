Critical 0 / Important 1 / Smells 0 — 範圍：快照的 `git diff HEAD~1 HEAD`（scripts/check-claude-md.sh、scripts/CLAUDE.md、tests/test-gate.sh、tests/CLAUDE.md）

[Important] tests/test-gate.sh 情境 ⑪（`rm -rf r.js README.md src docs 'api server'` 那一行，到 `said "找不到共同祖先"`）：這個情境號稱驗證「沒有共同祖先時，`reviews_missing` 放行但印出警告」，但其實根本跑不到那段程式碼。
  Failure: ⑪ 先刪掉 `docs`，所以 `reviews_missing` 在第一行 `[ -d docs/reviews ] || return 1` 就直接回傳，到不了 `resolve_fork_base` 失敗那一支（check-claude-md.sh 的 `if ! range_base=$(resolve_fork_base "review 檢查" ...)`）。`said "找不到共同祖先"` 能通過，是吃到 `owed_dirs` 印的「也找不到共同祖先」，不是 `reviews_missing` 的警告。這正是 tests/CLAUDE.md 這次自己寫下的地雷「opt-in 目錄不在 → 為了錯的理由而通過」。
  Evidence: 用 `sed '165,166d'` 刪掉 `reviews_missing` 那兩行警告做成變異 gate，跑 `test-gate.sh <變異>` 的結果是 exit=0、90 ✅、0 ❌，⑪ 的四則全綠。所以 tests/CLAUDE.md 與 scripts/CLAUDE.md 表格裡「連共同祖先都沒有：放行，但印警告」這一列，對 `reviews_missing` 來說沒有測試保護。⑪ 的註解「必須斷言那句警告真的印出來」同樣與事實不符。
  修法提示：要在無關歷史的那條線上重建 `docs/reviews/`（同 ⑩ 的做法），並改成斷言 `reviews_missing` 才會印的字串，例如「跳過 review 報告檢查」。

What I ran
- `git diff HEAD~1 HEAD` → 4 檔 diff
- `git show HEAD:scripts/check-claude-md.sh`（1–66、95–260 行）、`git show HEAD:tests/test-gate.sh`（1–80 行）→ 讀完函式與測試 helper
- 在拋棄式目錄執行：`git show HEAD:...check-claude-md.sh | sed '165,166d' > mut.sh`；`/bin/bash test-gate.sh mut.sh` → 先確認變異生效（`grep -c '跳過 review 報告檢查'` 回 0），測試結果 exit=0、90 ✅、0 ❌

Not reported
- ⑩ 的 `said "改從共同祖先"` 同樣可以被 `owed_dirs` 的警告滿足。但同一則的 block 結果加上 `said "沒有新增任何 docs/reviews/S*.md"`，已經證明 `reviews_missing` 確實拿到範圍，所以沒有列為發現。
- scripts/CLAUDE.md 寫的變異紅數（「3 紅 / 7 紅 / 2 紅」）沒有逐一重現（受一次實驗的預算限制）。其中「退化時不印警告 → 2 紅」這一項，在上面的發現之下，不可能有任何一紅來自 `reviews_missing` 的警告。要核對的話跑 `bash tests/test-gate.sh <對應變異>`，看紅的是哪幾則。