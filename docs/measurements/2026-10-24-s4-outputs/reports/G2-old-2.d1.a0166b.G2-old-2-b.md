Critical 0 / Important 1 / Smells 0。審查範圍是快照的 `git diff HEAD~1 HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）。

[Important] tests/test-gate.sh:340、348–349：情境 ⑪ 宣稱「兩處都要放行但講出來」，實際只驗到 `owed_dirs` 一處，`reviews_missing` 那條「連共同祖先都沒有」的分支（check-claude-md.sh:162–168）根本沒有跑到。
  Failure：第 340 行 `rm -rf … docs` 把 `docs/reviews` 刪了，`reviews_missing` 在第 151 行 `[ -d docs/reviews ] || return 1` 就提早返回。第 349 行的 `said "找不到共同祖先"` 其實是被 `owed_dirs` 第 108 行那句「也找不到共同祖先」滿足的。這正是 tests/CLAUDE.md 這次新寫的地雷 ①（「為了錯的理由而通過」）；tests/CLAUDE.md 的「兩處放行但必須印出警告」、scripts/CLAUDE.md 表格裡 `reviews_missing` 那列的「放行，但印警告」，也都沒有測試在撐。
  Evidence：變異 A 刪掉第 165–166 行的警告，結果 90 ✅、exit 0。變異 B 把第 167 行 `return 1` 改成 `return 0`（無祖先時改成擋），結果同樣 90 ✅、exit 0。兩種變異都沒有任何一則轉紅。
  修法提示：⑪ 要在 orphan 線上重建 `docs/reviews/`（只放非 `S*.md` 的檔），再斷言 `reviews_missing` 自己的那句「這次跳過 review 報告檢查」。

What I ran
- `git diff HEAD~1 HEAD`，以及用 `git show HEAD:` 讀 check-claude-md.sh、test-gate.sh 的相關段落 → 讀碼
- 在 mktemp 拋棄式目錄做三個變異，各跑一次 `/bin/bash tests/test-gate.sh <變異 gate>`：
  - 變異 A（刪第 165–166 行）→ exit 0、90 ✅、0 ❌
  - 變異 B（第 167 行 return 0）→ exit 0、90 ✅、0 ❌
  - 變異 C（刪第 89 行 `resolve_fork_base` 的警告）→ exit 1、2 ❌（「不在目前分支的歷史裡」「改從共同祖先」），和 scripts/CLAUDE.md 寫的「2 紅」一致
- 未改動的 gate 跑同一支測試 → exit 0、90 ✅，只拿來當對照基準，不是重跑你的驗證

Not reported：⑩ 的 `said "改從共同祖先"` 同樣可以被 `owed_dirs` 的警告滿足，但同一則還斷言了「沒有新增任何 docs/reviews/S*.md」，確實證明 `reviews_missing` 有跑而且擋下，所以不構成缺陷。scripts/CLAUDE.md 新段落中全形與半形標點混用屬於風格問題，未列。