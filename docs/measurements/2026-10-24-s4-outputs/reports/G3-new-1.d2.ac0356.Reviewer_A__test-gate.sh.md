Critical 0 / Important 1 / Smells 0。範圍是快照的 `git diff HEAD~1 HEAD`，重點看 `tests/test-gate.sh` 新增的繞過①②③區塊與 ⑦ 的 amend 改寫。

**[Important] tests/test-gate.sh 第 320 行（diff.txt 第 2904 行）：「繞過①」那一則對它要釘的變異沒有鑑別力，會紅只是被前面的失敗牽連。**
- 原因：pre-commit 跑的時候 HEAD 還是父 commit。by1 是 by0 重記起點之後的第一個 commit，所以那一刻 HEAD == base == by0。gate 的 `reviews_missing` 第 165 行 `[ "$base" = "$head_sha" ] && return 1` 會直接不擋。所以就算加上「`staged=` 那行下面加 `reviews_missing && exit 1`」這個變異，by1 在乾淨的狀態下照樣放行。
- 現在的測試裡它會紅，是因為變異先擋了 by0：起點留在 r4b，`git add -A` 又把 S3-a.md 帶進 by1，範圍變成 r4b..r4d、裡面零報告，才擋下 by1。
- 失敗情境：哪天前面情境的狀態改了（例如 by0 前面先 `--start-segment`，或連鎖斷了），繞過①在這個變異下就會變綠。scripts/CLAUDE.md 變異表那一列寫「繞過①是具名的那一則」，也就跟著不成立。這正是 tests/CLAUDE.md 警告的「為了錯的理由而通過」。
- 證據：
  - 拋棄式 repo 裡，變異版 gate 加上 `docs/reviews/`，`--start-segment` 之後：段內第一個 commit 放行（`b(first in seg, HEAD==base) PASS under mutation`），第二個才擋（`c(second in seg) BLOCK under mutation`）。
  - 整支測試在這個變異下，`補報告,結清 ⑧ 那一段`（by0）、`重記起點(起點 = by0)` 先紅，接著繞過①才紅。
- 建議改法：在 by1 之後、對照之前，再加一則段內第二個零報告的正常 commit 當具名的「繞過①」（HEAD ≠ base），讓它不靠連鎖也會紅。同批修正 scripts/CLAUDE.md 變異表那一列的說法。

### 逐則核對過、成立的部分（不報）
- **繞過①的對照**：被擋的是 `reviews_missing`（by0..by1 零報告，owed 是空的）。`上一段沒有附 review 報告` 只有第 202 行會印，`said` 只會被這一處滿足。
- **繞過②**：兩則的 HEAD 與檔案完全相同，只差起點檔。by2 版本被擋是因為 by2..by3 零報告；by0 版本放行是因為 by0..by3 含 S4-a.md。`base_is "$BY0"` 位置正確（繞過①的對照被擋，擋下不寫入），通過後 `base_is HEAD` 也正確。
- **繞過③的對照**：`--start-segment` 是被 owed 那一關（第 195 行）擋下，`said "還有 commit 跳過檢查"` 也只有那一處會印，和註解一致。
- **繞過③對照的弱點**：`reviews_missing` 被 owed 那一關蓋住，rm 之前沒有單獨證明它也會擋。不過 by3..by4 確實零報告，所以 rm 之後的 pass 仍能證明兩關都關了。
- **scripts/CLAUDE.md 變異表的第 2、3 列**：實跑確認，兩個變異各只紅宣稱的那一則。判定行數用 tests/CLAUDE.md 寫的 grep 算，三個變異版都是 105，和已確認的固定版 105 一致。
- **對後面情境的污染**：by6 補了 by/CLAUDE.md，⑨ 刪目錄的 commit 與 ⑩ 重記起點都不受影響，⑪ 的 `git clean` 也會清掉 by/。
- **⑦ 的 amend 包進 `expect`**：固定版下 amend 時沒有 staged、也沒有欠帳，所以放行。在 m1 變異下，整支已能跑完。

### 我跑過的指令
- 讀 diff.txt 第 1–249 行與 test-gate.sh、worktree-manager SKILL.md 的整檔段落，以及快照的 `scripts/check-claude-md.sh`。
- `/bin/bash t.sh m1.sh`（m1 = `staged=` 那行下面加 `reviews_missing && exit 1`）→ by0、重記起點(by0)、繞過①、by2、by3、by2 對照、收尾都是 ❌；繞過②、③ 是 ✅。
- 拋棄式 repo，用 m1 當 pre-commit，做段內第一與第二個 commit → 第一個 PASS、第二個 BLOCK。
- m2（`[ -d docs/reviews ] && ! read_base && exit 1`）→ 只有「繞過③:rm 掉起點檔,開下一段放行」❌。
- m3（沒有起點檔時記成空樹）→ 只有「繞過③:by/ 的欠帳被洗掉」❌。
- 對 m1、m2、m3 的輸出算判定行數（`grep -cE` 那條）→ 都是 105。
- 我也想用複製到 /tmp 的 t.sh 跑固定版，但 ROOT 從複製位置推算，找不到 gate，exit 2。這是我的實驗造成的，不代表測試有問題；固定版的結果沿用你們已確認的 105 ✅。

### 沒報的
- CHANGELOG、verification-gate、worktree-manager、templates §3.5 的文字改動：讀過，沒找到有證據的錯。
- worktree-manager 宣稱的「git 2.42.0 / 2.54.0 實測」我沒重跑，那需要外部環境。

### 其他
- 實驗目錄 `/tmp/g3rev.8XoG` 還留著（刪除屬破壞性操作，需要你同意才會刪）。