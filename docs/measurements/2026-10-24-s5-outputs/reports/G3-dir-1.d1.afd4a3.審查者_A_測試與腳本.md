Critical 0 / Important 1 / Smells 0。範圍是快照的 `git diff HEAD~1 HEAD`，共 8 個檔，重點看 `tests/test-gate.sh` 新增的區塊、`tests/CLAUDE.md` 和 `scripts/CLAUDE.md`。

[Important] tests/test-gate.sh:320（diff 檔第 2904 行）「繞過①」這一則測試本身抓不到它要釘的行為。它變紅只是因為前面的情境先被擋、一路連帶紅下來。`scripts/CLAUDE.md` 變異表第一列寫「繞過①是具名的那一則」，這句話不成立。
  Failure：`by1` 是起點 `by0` 之後的第一個 commit。pre-commit 跑的時候 HEAD 還是 `by0`，`reviews_missing` 第 165 行的 `[ "$base" = "$head_sha" ] && return 1` 會直接放行。所以就算 pre-commit 真的開始查報告，這一則照樣是綠的。我把同一個變異改成只在 `by0` 之後才生效（`git cat-file -e HEAD:docs/reviews/S3-a.md && reviews_missing && exit 1`），結果「繞過①」維持 ✅。紅的是後面的 `by2`／`by3`／繞過②那幾則，它們的說明都不叫繞過①。
  Evidence：`check-claude-md.sh:165`；下面 What I ran 的 g2 那一行。
  修法：起點之後先放一個零報告的 commit，再測第二個零報告的正常 commit 會放行，具名斷言改放在第二個上面。變異表那一列跟著改寫。

What I ran
- 照文件寫的變異（`staged=` 那行下面加 `reviews_missing && exit 1`），存成 `/tmp/revA.9UL7/g1.sh` 跑 `test-gate.sh` → exit 1，判定行 105 行（和固定版一樣）。第一個紅的是「建立 docs/reviews/ 的那個 commit」，後面一路連帶紅，「繞過①」也在其中，和文件寫的一致。
- 同一個變異，但只在 HEAD 已經含 `S3-a.md` 之後才生效（`/tmp/revA.9UL7/g2.sh`）→ exit 1。「繞過①」維持 ✅；紅的是「這一段補上報告」「下一段零報告的 commit」「對照:有照規矩在 by2…」「繞過②」「收尾」，外加一則 said 和一則 base_is。
- 變異表第二列（`[ -d docs/reviews ] && ! read_base && exit 1`，`g3.sh`）→ 只紅「繞過③:rm 掉起點檔,開下一段放行」，和文件一致。
- 變異表第三列（沒有起點檔時從空樹記起，`g4.sh`）→ 只紅「繞過③:by/ 的欠帳被洗掉…」，和文件一致。
- 用 `diff` 確認 g3、g4 都只改了預期那一行；用 grep 確認 g1、g2 的變異確實插進去了（第 239 行）。
- 拋棄式目錄 `/tmp/revA.9UL7` 沒有刪，要不要清由你決定。

Not reported
- 繞過③的對照「rm 之前,開下一段也擋」只證明欠帳那一關在擋（said「還有 commit 跳過檢查」）。報告那一關在 rm 之前是開著的，我是從 `by3..by4` 沒有新增報告推出來的，測試沒有斷言。變異表第二列已經另外釘住「rm 之後報告那一關關掉」，所以沒有報。
- `scripts/CLAUDE.md` 裡的「`test-gate.sh` 前 61 項」和 `test-gate.sh:406` 的「90 項全綠」是寫死的數字，這兩處都是這次之前就有的。
- `tests/CLAUDE.md` 新寫的驗法 `grep -cE '^(✅|❌ .*：(預期 |輸出裡有 shell 錯誤))'` 我實際跑過，變異版和固定版都數出 105 行，可以用。
- ⑦ 的 amend 包進 `expect`，以及新增的 15 則（90 → 105），我都核對過，沒有問題。
- worktree-manager、verification-gate、全域模板、根目錄 CLAUDE.md、CHANGELOG 的改動我讀過，沒有找到夠格回報的問題。git 2.42 和 2.54 的實測宣稱需要外部查證，我沒有去驗。