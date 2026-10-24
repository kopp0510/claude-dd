Critical 1 / Important 2 / Smells 1 — 審查範圍：快照 `git diff HEAD~1 HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）

[Critical] tests/test-gate.sh:340（diff.txt:997）情境 ⑪ 的 `rm -rf … docs …` 把 `docs/reviews/` 刪掉了。之後 `reviews_missing` 在 opt-in 守門 `[ -d docs/reviews ] || return 1`（check-claude-md.sh:151）就直接回傳，根本跑不到「連共同祖先都沒有」那一支（check-claude-md.sh:162-167）。
  失敗情境：把那一支的警告刪掉（M2），或把它改成直接擋下（M3），兩種變異都是 90 ✅、exit 0。:349 的 `said "找不到共同祖先"` 能過，是因為 `owed_dirs` 的「也找不到共同祖先，這次只檢查 staged」（:108）裡剛好有這幾個字。這正是 test-gate.sh:319-321 和 tests/CLAUDE.md:11 自己警告過的「為了錯的理由而通過」。tests/CLAUDE.md:11 寫「兩處放行**但必須印出警告**」、scripts/CLAUDE.md:49 那列「放行，但印警告」，其中 `reviews_missing` 這半句沒有任何測試在守。
  證據：見下方「What I ran」的 M2、M3。

[Important] tests/test-gate.sh:304（diff.txt:961）宣稱「沒有這一段的話，把 `--segment-base` 也改成『退到共同祖先』的變異**不會有任何測試變紅**」，這是假的。
  失敗情境：M1 讓舊情境 7 的「起點失效時 --segment-base 要失敗」（:120）也變紅。scripts/CLAUDE.md:60 寫的「3 紅」本身就包含這一則，同一份變更裡自相矛盾。後人會照這句以為 ⑩ 是唯一防線。
  證據：M1 → 88 ✅，3 個 ❌：「起點失效時 --segment-base 要失敗」、「起點不是祖先:--segment-base 必須硬失敗」、「輸出沒提到：沒有可用的段落起點」。

[Important] tests/test-gate.sh:283-285（diff.txt:940-942）新註解說「上面那句註解原本寫『起點 commit 被改寫』……(2026-10-07 S4 修正)」，但上面 ⑦ 的標頭註解 :273-276 沒有被改，仍寫「**起點 commit 被改寫(amend / rebase)之後**……`git commit --amend` 掉起點那個 commit」。
  失敗情境：讀者先讀 :273，以為 ⑦ 在測「改寫起點」；往下 10 行又被告知那句已經修正。這次 diff 實際改的是 expect 名稱，而舊名稱「amend 段落內的 commit」本來就是對的。
  證據：diff hunk `@@ -280,7 +280,10 @@` 只改了 :286 的 expect 那行並加了 :283-285 的註解，:273-276 在 diff 裡沒有變動。

Smells
- 隱藏輸入（Mysterious Name 類），check-claude-md.sh:71-72、:84：`resolve_fork_base` 的註解只寫了 `$1`、`$2`，實際還隱含讀全域的 `$base`（由 `read_base` 設定）。哪天有呼叫端沒先跑 `read_base`，`merge-base` 會拿空字串或舊值去比，錯誤又被 `2>/dev/null` 吞掉，最後變成「找不到共同祖先 → 放行」。
- 變異結果只記紅數，沒記哪幾則紅，scripts/CLAUDE.md:60-62：全域 §3.9 寫明「紅數本身不是證據……要記哪個變異 → 哪幾個情境變紅」。這裡只寫「3 紅 / 7 紅 / 2 紅」。單看 3 個數字，讀者看不出「--segment-base 軟退化 → 3 紅」那 3 則裡有一則是舊情境 7（M1 顯示有），所以也無從發現 :304 那句是錯的。

What I ran
- `git grep -n -e resolve_fork_base -e 共同祖先 -e fork-point`（排除被改的兩支腳本）→ 只命中 CHANGELOG.md:413（已發布區塊的歷史敘述，仍成立）和 scripts/CLAUDE.md、tests/CLAUDE.md 這次新增的段落。
- M1（把 `--segment-base` 改成退到 `merge-base`）`bash tests/test-gate.sh <m1>` → exit 1，88 ✅，3 ❌（如上）。
- M2（刪掉 `reviews_missing` 無共同祖先時那兩行警告）→ exit 0，90 ✅。
- M3（`reviews_missing` 無共同祖先時改 `return 0` 擋下）→ exit 0，90 ✅。

Not reported
- test-gate.sh:340 的 `rm` 清單裡有不存在的 `'api server'`，又漏了 p/、r/、w/、feat/ 等目錄。那些殘留檔各自都有 CLAUDE.md，所以 r7 照樣通過，不影響結果。
- scripts/CLAUDE.md:22、tests/CLAUDE.md:44-46 的「前 61 項」是既有寫法；新區塊排在後面，前 61 項沒被動到，這句仍然成立。
- 「fork-point 拿掉 → 7 紅」「不印警告 → 2 紅」兩個數字我沒有重跑核對。