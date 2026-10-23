Critical 1 / Important 3 / Smells 1。審查範圍是快照的 `git diff HEAD~1 HEAD`（4 檔），主攻 `tests/test-gate.sh` 的 ⑦⑩⑪。

[Critical] tests/test-gate.sh:190（diff.txt:190）⑪ 的清場指令 `rm -rf ... docs ...` 把 `docs/reviews/` 一起刪了。之後的 `--start-segment` 在 `reviews_missing` 的第一行 `[ -d docs/reviews ] || return 1` 就直接回傳（已讀 scripts/check-claude-md.sh:151），根本走不到「連共同祖先都沒有」那一支（:162-167）。
  Failure：把 `reviews_missing` 那兩行 `echo`（「這次跳過 review 報告檢查」與下一行）刪掉，整份測試仍然 exit 0，0 個 ❌。⑪ 那句 `said "找不到共同祖先"` 是被 `owed_dirs` 的「也找不到共同祖先，這次只檢查 staged」滿足的。這正是 tests/CLAUDE.md 新增的警告①點名的「為了錯的理由而通過」；註解 :186-187 宣稱守住的「靜默放行」也沒有被測到。scripts/CLAUDE.md 那張表把 `reviews_missing` 的「放行，但印警告」列為有測，實際沒有任何測試覆蓋。
  Evidence：實際印出 ⑪ 的 `$OUT`，只有 owed_dirs 那句警告和「段落起點：…」；當下 `ls -a` 看不到 `docs`。刪掉那兩行的變異跑 `/bin/bash t.sh m1.sh`，exit 0。
  建議改法：清場時保留或重建 `docs/reviews/CLAUDE.md`，`said` 改成比對「這次跳過 review 報告檢查」。

[Important] tests/test-gate.sh:182（diff.txt:182）⑩ 的 `said "改從共同祖先"` 被 `owed_dirs` 的警告滿足了。`owed_dirs` 傳給 `resolve_fork_base` 的 prefix 是空字串，印出的就是「…，改從共同祖先 X 算起」，每次 `--start-segment` 都會先印這句。所以這個斷言證明不了 `reviews_missing` 的警告有印出來。
  Failure：把 :162 改成 `range_base=$(resolve_fork_base "review 檢查" "$head_sha" 2>/dev/null)`，讓 review 那句警告消失，測試照樣 exit 0。
  Evidence：⑩ 的 `$OUT` 實際有兩句警告，一句不帶前綴、一句帶「review 檢查」；上面那個變異跑 `t.sh m2.sh`，exit 0。
  建議改法：改成 `said "review 檢查改從共同祖先"`。

[Important] tests/test-gate.sh:154（diff.txt:154）註解寫「沒有這一段的話，把 `--segment-base` 也改成『退到共同祖先』的變異不會有任何測試變紅」，這句話是錯的。情境 7 的「起點失效時 --segment-base 要失敗」（HEAD 版 test-gate.sh 第 120 行附近）本來就涵蓋「起點不是祖先、但有共同祖先」。
  Failure：這段是整個區塊的存在理由，會讓後人誤以為情境 7 不承重。scripts/CLAUDE.md 寫的「3 紅」其實包含情境 7 那一則。
  Evidence：做了一個 `--segment-base` 改成軟退化的變異，只跑到 ⑩ 之前的截斷版測試，已經出現「❌ 起點失效時 --segment-base 要失敗：預期 block，實際 pass」；完整版共 3 紅（情境 7 一則加 ⑩ 兩則）。

[Important] tests/test-gate.sh 的 ⑦ 標頭註解（`grep -n '⑦ \*\*起點 commit 被改寫' tests/test-gate.sh`）沒有改。新加的註解（diff.txt:139-141）卻寫「上面那句註解原本寫『起點 commit 被改寫』……(2026-10-07 S4 修正)」。
  Failure：標頭仍寫「起點 commit 被改寫(amend / rebase)之後……現在退到共同祖先繼續算」，與下面那則「起點仍是祖先、沒有跑到 fork-point」直接矛盾。讀者會被新註解告知「已修正」，實際上沒修。這就是 §3.10 說的「只改一半」。
  Evidence：HEAD 版 `git show HEAD:tests/test-gate.sh` 裡 ⑦ 的標頭三行原樣保留。

Smells
[Smell] tests/test-gate.sh:189-191（diff.txt:189-191）這裡可能有 Mysterious/misleading intent。`rm -rf` 列的 `'api server'` 在整份測試裡從來沒建過，實際的目錄叫 `my dir`。p、r、w、mv、keep、feat、feat2、功能、模組、top.js、`my dir` 都留在工作目錄，被 r7 的 `git add -A` 重新收進「無關歷史的第一個 commit」，所以 r7 根本不是只有 `lone/` 的 commit。現在能 pass，只是因為這些目錄剛好都有 CLAUDE.md；前面任何情境哪天留下一個沒有 CLAUDE.md 的程式碼目錄，⑪ 就會擋在無關的理由上。
  Evidence：⑪ 當下的 `ls -a` 輸出就是上面那份清單。

What I ran
- 讀 diff.txt:1-210，以及 `git show HEAD:tests/test-gate.sh` 全檔、`scripts/check-claude-md.sh` 全檔 → 逐步追蹤 ⑩⑪ 的狀態
- 在拋棄式目錄跑插了 `cat $OUT; ls -a` 的測試版本 `/bin/bash ti.sh g0.sh` → 90 ✅，取得 ⑩⑪ 的實際輸出
- 變異 m1（刪掉 `reviews_missing` 無共同祖先時的兩行 echo）跑 `t.sh m1.sh` → exit 0，沒有 ❌
- 變異 m2（review 那支 `resolve_fork_base` 加 `2>/dev/null`）跑 `t.sh m2.sh` → exit 0，沒有 ❌
- 變異 m3（`--segment-base` 軟退化）跑截斷到 ⑩ 之前的版本 → 1 ❌（情境 7）；跑完整版 → 3 ❌

Not reported
- ⑩ 的 `base_is`、`said "沒有可用的段落起點"`、`said "沒有新增任何…"` 都追過一遍，成立。
- ⑩ 的 block 斷言分不出「退到共同祖先」和「直接拿原起點 r6a 算」：在這份資料下兩者都會擋，但沒有規格說後者錯，所以不報。
- `resolve_fork_base` 讀全域 `$base` 是沿用既有寫法。
- 拋棄式目錄 `/var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.lrVFIBXEfv` 沒有刪（§4.2 規定 rm -rf 要先確認），可以自行清掉。