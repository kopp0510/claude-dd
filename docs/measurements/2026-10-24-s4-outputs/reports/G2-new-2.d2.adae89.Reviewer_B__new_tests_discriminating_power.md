Critical 0 / Important 2 / Smells 0。範圍是快照的 `git diff HEAD~1 HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）。

gate 本身的重構我沒有找到行為錯誤（已讀 diff.txt:376-484）。兩則發現都在測試的鑑別力：⑪ 沒有測到 `reviews_missing`，⑩ 也沒有測到「退到共同祖先」這件事。

**[Important] tests/test-gate.sh:340, 348-349 — ⑪ 完全沒有跑到 `reviews_missing` 的「沒有共同祖先」分支，它是為了錯的理由通過**
- 原因有兩層：
  1. 第 340 行的 `rm -rf … docs …` 把 `docs/reviews` 刪掉了，於是 `reviews_missing` 在 gate 的 `[ -d docs/reviews ] || return 1`（diff.txt:457，gate 第 151 行）就直接放行，根本走不到後面。
  2. `said "找不到共同祖先"` 這個子字串，`owed_dirs` 的警告「…也找不到共同祖先，這次只檢查 staged」（gate 第 108 行）同樣會命中。
- 這正是 tests/CLAUDE.md 新加那段的第 ① 點警告過的錯，而 tests/CLAUDE.md:126 宣稱「連共同祖先都沒有時：兩處放行但必須印出警告」，實際上這個情境沒有被覆蓋。
- 失敗情境：把第 165-166 行的警告刪掉（又變回 S6 抓到的「靜默通過」繞過路徑），或改成 `return 0`，測試照樣全綠。
- 證據（拋棄式副本實跑）：
  - M1「刪掉 `reviews_missing` 的兩行警告」→ 90 ✅ / 0 ❌，exit 0
  - M2「該分支改成 `return 0`」→ 90 ✅ / 0 ❌
  - MD「只刪 `owed_dirs` 第 108 行的警告」→ 唯一的紅是 `❌ 輸出沒提到：找不到共同祖先`，證明 ⑪ 的 `said` 只靠 `owed_dirs` 的那句過關。

**[Important] tests/test-gate.sh:331-333 — ⑩「reviews_missing 退到共同祖先，照樣擋」分不出「退到共同祖先」和「直接拿失效的起點算」**
- 這裡兩種算法擋下的結果一樣：`r6a..r6c` 的 diff 裡 S9-a.md 是刪除、不是新增，`r6a^..r6c` 也沒有新增 S*.md，兩邊都擋。
- `said "改從共同祖先"` 也會被 `owed_dirs` 先印的那句 fork 警告命中（`--start-segment` 先跑 gate 第 183 行的 `owed_dirs`）。所以就算 `reviews_missing` 那次呼叫的 stderr 被吞掉，這則照樣綠。
- 失敗情境：`reviews_missing` 改成不經 `resolve_fork_base`、直接 `range_base=$base`，測試全綠。
- 證據：M3「`range_base=$base; if false; then`」→ 90 ✅ / 0 ❌，exit 0。

**scripts/CLAUDE.md:32-34 的三個變異數字都站得住**（拋棄式副本實跑）：
- `--segment-base` 改成退到共同祖先 → 3 紅：第 120、328 行的 block，加上第 329 行的 `said`。
- 拿掉 fork-point → 7 紅：第 122 行、第 124 行的 `said`、第 125、331 行、第 332-333 行的兩個 `said`，加上第 345 行的 `base_is`。
  - 第 345 行那一紅是連鎖造成的：⑩ 的 `--start-segment` 變成放行，起點檔被覆寫。所以「同時打破兩個呼叫端」的 7 紅裡，有 1 紅不是直接證據。
- `resolve_fork_base` 不印警告 → 2 紅：第 123 行與第 332 行的 `said`。

**What I ran**
- `git archive HEAD | tar -x` 到 `/tmp/revB.*`，在副本裡用 perl 做出 M0/M1/M2/M3/MA/MB/MC/MD 八個 gate 變異，各跑一次 `bash tests/test-gate.sh <變異>`，結果：
  - M0（原版）：90 ✅ / 0 ❌
  - M1：90 / 0
  - M2：90 / 0
  - M3：90 / 0
  - MA：3 ❌
  - MB：7 ❌
  - MC：2 ❌
  - MD：1 ❌
- `rm -rf /tmp/revB.*` → 已清除，殘留 0。

**Not reported**
- ⑪ 的 `rm -rf` 清單沒有清掉 p/、r/、w/、keep/、feat/、feat2/、功能/、模組/、my dir/、top.js，而且 `'api server'` 在整支測試裡從來沒建過。r7 的 `git add -A` 會把它們全部加回去。我沒列為發現，因為每個目錄都帶著自己的 CLAUDE.md，不改變任何一則的結果；但它讓「無關歷史只有 lone/」這個前提不成立。
- `--start-segment` 會讓 `owed_dirs` 和 `reviews_missing` 各印一次 fork 警告：這次 diff 之前就是這樣，是既有行為。