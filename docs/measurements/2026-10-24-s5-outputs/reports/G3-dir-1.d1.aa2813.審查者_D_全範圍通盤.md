Critical 0 / Important 2 / Smells 0：審查範圍是快照 `git diff HEAD~1 HEAD`（8 檔），以 diff 檔第 1–3024 行為準。

**[Important] 繞過① 那則特性測試，在它自己的狀態下抓不到它宣稱要釘的變異。它會變紅，全是因為前面情境連鎖失敗。**
- 位置：`tests/test-gate.sh:319-320`（diff.txt 2903-2904）；`scripts/CLAUDE.md` 變異表第一列（diff.txt 66）。
- 原因：`by1` 是 `--start-segment`（diff.txt 2897）之後的第一個 commit。pre-commit 跑的時候 HEAD 還是 by0，等於 base，所以 `reviews_missing` 在 `check-claude-md.sh:165` 的 `[ "$base" = "$head_sha" ] && return 1` 就放行了。結果是，「`staged=` 下面加 `reviews_missing && exit 1`」這個變異不會擋 by1。
- 實測：用這個變異跑整支測試。⑩ 段落內的第一個 commit「段落內再一個 commit(零報告)」是 ✅，同一段的第二個 commit「新線上的正常 commit」才變 ❌。繞過① 在整支跑時會是 ❌，只是因為 r0 被擋之後起點一路卡在 `c07c06…`：輸出依序印出「起點應為 fb3a…，實際是 c07c06…」，接著才是「❌ 繞過①…」。
- 失敗情境：哪天前面的 review 情境被重排、拿掉，或 gate 改成在 pre-commit 認得 staged 的報告，連鎖就斷了。這時繞過① 會在變異版下維持綠燈，而文件表格還寫著「繞過①是具名的那一則」。
- 建議改法：繞過① 改斷言「段落內第二個 commit（base ≠ HEAD）」放行。改完在沒有連鎖的狀態下重驗一次變異，再更新變異表那一列。

**[Important] 「紅要對得上那個錯的值」和 §3.9 鑑別力測試那條互相矛盾，verification-gate 把它直接套在「改回舊版」上。**
- 位置：`skills/verification-gate/SKILL.md:36`（diff.txt 91，「紅的是原本那個 bug」）與 `:58`（diff.txt 100）；`templates/global/CLAUDE.md:193-195`（diff.txt 142-144）。
- 矛盾在哪：`git stash -u && <測試>` 就是 §3.9「鑑別力測試(改回舊版確認會紅)」那個動作。§3.9 在 diff.txt 2065-2066 明寫「不要斷言某個預期的壞結果」，並記了 2026-10-07 變異版掉進「第三種」狀態的實例。
- §3.5 的但書「這條管新測試第一次跑」擋不住：修 bug 時，新測試第一次跑本來就是跑在舊碼上，和「改回舊版」是同一件事。
- 失敗情境：舊碼對新測試給出 C，而 bug 回報寫的是 A。照新條文，agent 會判定「紅的不是原本那個 bug」，回頭去改一個其實有鑑別力的測試。這正是 §3.9 記錄過、差點發生的那次。
- 建議改法：把判準改成「紅在被測物給錯值的那個斷言上（不是 import、拼字、資料沒建好），錯的值不必是預期的那一個」。三處同批改：§3.5、verification-gate 第 36 行與第 58 行，以及 CHANGELOG 第 25 行「修 bug 時就是那個錯的值」。

**我核對過、成立的部分**
- 變異表第二、三列各自只讓宣稱的那一則變紅。
- 繞過② 的對照確實只差起點檔，HEAD 相同。
- 繞過③ 用的 `said "還有 commit 跳過檢查"` 只有 owed 那個擋點會印（`check-claude-md.sh:195`）；「先補完再記新起點」兩個擋點都會印（195 與 202 行），和註解說的一致。
- 「恆真斷言」那條引用存在（`tests/CLAUDE.md:42`）。

**What I ran**
- `grep -n` 查 `check-claude-md.sh` 的關鍵符號，再讀整檔 → 確認 165 行的 base==HEAD 提前放行、195 與 202 行的訊息。
- 變異一（`staged=` 下加 `reviews_missing && exit 1`）跑 `test-gate.sh` → exit 1。⑩ 的 r6b ✅、r6c ❌；繞過① 的 ❌ 出現在起點卡在 c07c06 之後。
- 變異二跑 `test-gate.sh` → exit 1，只有「繞過③:rm 掉起點檔,開下一段放行」❌。
- 變異三跑 `test-gate.sh` → exit 1，只有「繞過③:by/ 的欠帳被洗掉…」❌。
- `grep` 恆真、61 項、90 項、`WORKTREE_INFO` 與 `.env` → 交叉引用都存在。
- 實驗留在 `/tmp/revD.anan`（拋棄式，未刪除）。

**Not reported**
- 繞過③ 的對照只證明了 owed 那個擋點在 rm 之前會擋，review 那個擋點在該狀態下沒有獨立對照。實際上那個狀態也會擋，而且變異二有釘住，所以不算缺口。
- worktree-manager 寫「`WORKTREE_INFO.md` 每次都會出現在 `??`」：如果使用者的全域 gitignore 忽略了它，就會改成出現在 `!!`。這是邊角情況，沒有具體證據會發生。
- `test-gate.sh:228` 與 `:406` 寫死的「61 項」「90 項」是既有的歷史敘述，不是這次 diff 引入的。