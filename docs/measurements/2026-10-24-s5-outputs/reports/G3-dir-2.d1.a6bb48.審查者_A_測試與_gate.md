Critical 0 / Important 1 / Smells 0 — 審查範圍：快照 `git diff HEAD~1 HEAD`（8 個檔），重點看 `tests/test-gate.sh` 新增的「三條繞過路徑」區塊與 `scripts/check-claude-md.sh` 的關係

[Important] `tests/test-gate.sh:319-320`（快照行號；diff 檔第 2903-2904 行）與 `scripts/CLAUDE.md` 變異表第一列（diff 檔第 66 行）：「繞過①」那則單獨看抓不到「pre-commit 也查報告」這個變異。它在變異下變紅，是前面連鎖失敗留下的壞狀態造成的，不是因為它自己的斷言。
  Failure：第 313 行剛跑完 `--start-segment`，起點等於 HEAD，接著第 320 行做 by1 commit。pre-commit 執行的當下，HEAD 還是 by0，`reviews_missing` 會先走 `check-claude-md.sh:165` 的 `[ "$base" = "$head_sha" ] && return 1`，直接判定不擋。所以就算 gate 改成 pre-commit 也呼叫 `reviews_missing`，這一則照樣放行、維持綠燈。文件說它是「具名的那一則」哨兵，但它只靠第 233 行起的連鎖紅才會紅。哪天有人把前面那串連鎖紅修好，這則就會靜靜地綠著（這是全域 §3.5 說的「為了錯的理由而紅」）。
  Evidence：我做了一個 gate 副本，只在 `staged=` 那行下面加 `[ -f .git/m1on ] && reviews_missing && exit 1`，測試副本在第 319 行前加 `touch .git/m1on`，讓變異從繞過①那一刻才生效、前面狀態保持正確。結果是 `✅ 繞過①:段落內零報告的正常 commit 放行` 仍然綠，紅的全落在後面的 by2、by3、繞過②、by6、r6c。文件原寫法的變異（從頭就生效）下，這一則會紅，但它前面已經紅了 19 行 ❌。
  建議改法：by1 之前先在同一段做一個 commit，讓起點不等於 HEAD 再斷言；或者改成「有效範圍不是空的」那種狀態。同時修正 `scripts/CLAUDE.md` 變異表那一列的說法。

其餘已逐條核對、站得住的：
- 變異表第 2、3 列寫的「只有繞過③的那一則變紅」，實跑確認各 1 紅，而且紅的正是表上寫的那一則。
- tests/CLAUDE.md 說「變異版與固定版的判定行數要一樣」，用第一列變異跑，判定行數是 105 / 105，對得上。
- 繞過③ 註解說「先補完再記新起點」兩個擋點的訊息都有，對照 `check-claude-md.sh` 第 195、202 行，屬實。
- 「放在 ⑧ 與 ⑨ 之間」、說明以「繞過①②③」開頭，都與程式碼一致。

What I ran
- 把快照的 `scripts/` 與 `tests/` 複製到 `/tmp/revA.tyn8`，用 awk 做三個 gate 副本：m1（pre-commit 也查報告）、m2（不小心連 SKIP 那一支也改到，下面重做）、m3（沒起點檔時從空樹記起）。
- `/bin/bash tests/test-gate.sh <各副本>` → 未改的那份 exit 0、105 判定、0 紅；m1 exit 1、105 判定、27 行 ❌（含繞過①）；m2、m3 各 1 紅。
- m2b（只改 `--start-segment` 那一支）→ 1 紅：「繞過③:rm 掉起點檔,開下一段放行」。m3 的 1 紅是「繞過③:by/ 的欠帳被洗掉」。
- m1g 加 t1g（變異從第 319 行才生效）→ 繞過① 仍 ✅，紅在 by2 之後的情境。

Not reported
- `scripts/CLAUDE.md` 與 `tests/test-gate.sh` 第 228、406 行寫死的「61 項」「90 項」：既有內容，不是這次 diff 引入的。
- worktree-manager 宣稱的 git 2.42.0 / 2.54.0 行為：沒有實跑兩個 git 版本驗證，需要的話跑 `git worktree remove` 搭配被 gitignore 的 `.env` 確認。
- CHANGELOG、`verification-gate`、`templates/global` §3.5 的文字改動：讀過，沒有找到夠得上門檻的問題。