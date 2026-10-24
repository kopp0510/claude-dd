Critical 1 / Important 2 / Smells 1。審查範圍是快照的 `git diff HEAD~1 HEAD`，重點看 tests/test-gate.sh 新加的 ⑩⑪ 情境能不能抓到 check-claude-md.sh 的錯。

[Critical] tests/test-gate.sh:340、348-349（diff.txt 997、1005-1006）⑪ 要測的是 `reviews_missing` 在「連共同祖先都沒有」時放行並印警告，但這個分支一次都沒有跑到。
  Failure：第 340 行 `rm -rf … docs …` 把 `docs/reviews` 刪掉了，所以 `reviews_missing` 第一行 `[ -d docs/reviews ] || return 1` 就直接回傳。第 349 行 `said "找不到共同祖先"` 能過，是因為 `owed_dirs` 自己也印了「…也找不到共同祖先，這次只檢查 staged」。刪掉 gate 第 165-166 行的警告（回到第一版的靜默放行），或把第 167 行改成 `return 0`，測試照樣全綠。tests/CLAUDE.md 新寫的陷阱 ①「切到不含它的分支就整個檢查不啟用」，這一則正好踩中。
  Evidence：變異 M1（刪掉警告，並在該分支插一行標記）跑出 90✅/0❌，標記檔寫入 0 次；變異 M2（`return 0`）也是 90✅/0❌。

[Important] tests/test-gate.sh:304（diff.txt 961）註解寫「沒有這一段的話，把 `--segment-base` 也改成退到共同祖先的變異不會有任何測試變紅」，這句是錯的。
  Failure：舊的情境 7（第 120 行「起點失效時 --segment-base 要失敗」）本身就有共同祖先，同一個變異會讓它變紅。這句是在替新區塊辯護，卻給後人錯的前提。scripts/CLAUDE.md:60 寫的「3 紅」裡就含這一則舊測試。
  Evidence：變異 M3（第 210 行 `--is-ancestor` 改成 `merge-base`）有 3 紅：第 120 行、第 328 行，加上第 329 行的 `said`。

[Important] tests/test-gate.sh:332（diff.txt 989）`said "改從共同祖先"` 分不出是 `reviews_missing` 印的，還是 `owed_dirs` 印的。
  Failure：`--start-segment` 會先跑 `owed_dirs`，它用空前綴呼叫 `resolve_fork_base`，同樣會印出「改從共同祖先」。所以 review 檢查那句警告被吞掉，測試照樣綠。斷言應改比對「review 檢查改從共同祖先」。
  Evidence：變異 M5（gate 第 162 行的呼叫加上 `2>/dev/null`）是 0❌。

Smells
- tests/test-gate.sh:340 的清理清單不完整。`rm` 列了根本不存在的 `'api server'`，卻沒清 p/、r/、w/、feat/、feat2/、功能/、模組/、keep/、`my dir`、top.js 等目錄，`commit` 裡的 `git add -A` 會把它們全部加回 r7。現在結果沒受影響，因為各目錄的 CLAUDE.md 也一起加回去了。但「lone 是唯一內容」這個前提其實不成立，以後有人改這段時容易誤判。

What I ran
- `/bin/bash tests/test-gate.sh`（在 /tmp 的副本）→ 90✅ / 0❌，exit 0（基準）
- M1：刪掉 gate 第 165-166 行，並在該分支插標記 → 90✅ / 0❌，標記 0 次
- M2：gate 第 167 行 `return 1` 改成 `return 0` → 90✅ / 0❌
- M3：`--segment-base` 改成退到共同祖先 → exit 1，紅的是第 120、328、329 行
- M4：刪掉 `resolve_fork_base` 的警告（第 89 行）→ 2 紅（第 123、332 行的 `said`），跟 scripts/CLAUDE.md 寫的「2 紅」一致
- M5：第 162 行的呼叫加 `2>/dev/null` → 0❌
- `rm -rf` 我自己建的 /tmp/revB.a5ws 和 /tmp/revB_marker → 已清。/tmp 下另外還有 5 個 revB* 路徑不是這次的 mktemp 建的，我沒動。

Not reported：scripts/CLAUDE.md 和 tests/CLAUDE.md 的文字（不在 B 的方向內，但上面第一條 Important 那句錯的註解，scripts/CLAUDE.md:60 的「3 紅」也呼應了）；`resolve_fork_base` 本身的邏輯讀過沒問題；`base_is` 的快照時機正確，不是恆真斷言。