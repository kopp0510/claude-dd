Critical 0 / Important 1 / Smells 0。審查範圍是 `git diff HEAD~1 HEAD`,共 8 檔:CHANGELOG.md、CLAUDE.md、scripts/CLAUDE.md、兩份 SKILL.md、templates/global/CLAUDE.md、tests/CLAUDE.md、tests/test-gate.sh。

[Important] templates/global/CLAUDE.md:193-195 新規則要求「修 bug 時,紅的必須是那個錯的值」,跟同一檔 §3.9 的鑑別力規則互相衝突。skills/verification-gate/SKILL.md 的 stash 那行與新加的紅旗有同樣問題,CHANGELOG 的條目也照抄了這句。
  Failure: 修 bug 時拿新測試去跑 `git stash -u` 之後的舊碼,這本身就是「改回舊版確認會紅」。如果舊碼掉進第三種狀態(例如回報的是「預期 3、實際 2」,舊碼卻在別處丟例外,或回傳 C),照新規則就會判成「紅得不對、測試不算數」,然後回頭改一個其實正常的測試。這正是 §3.9 記下的 2026-10-07 事故。括號裡的但書「這條管新測試第一次跑」分不開這兩種情況,因為修 bug 時新測試的第一次跑就是在舊碼上跑。
  Evidence: 新文字寫「對得上『它應該怎麼紅』才算:修 bug 時就是那個錯的值」(templates/global/CLAUDE.md:193-194)。§3.9 寫「不要斷言某個預期的壞結果……變異版掉進第三種狀態」(templates/global/CLAUDE.md:364-366)。SKILL.md 寫「git stash -u && <測試>(看到失敗,而且紅的是原本那個 bug)」。

需要外部查證(我沒去查):
- worktree-manager 引用的中文錯誤訊息「包含修改或未追蹤的檔案，使用 --force 刪除」:要對照 git zh_TW 的 po 檔,確認譯文逐字相同。
- 「`!!` 那類被 gitignore 的檔會跟著目錄刪掉、不提示」:要在 git 2.42 / 2.54 跑一次 `git worktree remove`,才能確認(diff 宣稱實測過)。

What I ran
- `git diff HEAD~1 HEAD`、`git show HEAD:tests/test-gate.sh`、`git show HEAD:scripts/check-claude-md.sh` 以及其他 `git show HEAD:<檔>` / `grep` → 讀過 diff、gate 腳本與測試的 helper
- 把 `git archive HEAD scripts tests` 解到暫存目錄,依 scripts/CLAUDE.md 新增的變異表做出 3 支變異 gate(各只差 1 行,已用 diff 確認),再把固定版和 3 支變異版各跑一次 `bash tests/test-gate.sh` → 固定版 exit 0,判定行 105,0 紅
  - 變異 1(pre-commit 也查報告)→ 判定行 105,從「建立 docs/reviews/ 的那個 commit」起一路連鎖變紅,其中包含「繞過①」那則
  - 變異 2(沒有起點檔就拒絕)→ 判定行 105,只紅「繞過③:rm 掉起點檔,開下一段放行」
  - 變異 3(沒有起點檔就從空樹記起)→ 判定行 105,只紅「繞過③:by/ 的欠帳被洗掉」
  - 結論:變異表的三列宣稱,以及 tests/CLAUDE.md「判定行數要一樣」那條,都和實測相符

Not reported:沒有新的函式或類別結構,所以沒跑 Fowler smell 檢查。實驗留下一個暫存目錄 `/var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.mLF0iHvXyG`;刪除檔案要先經使用者同意,所以我沒刪。