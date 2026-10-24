Critical 0 / Important 3 / Smells 0. 審查範圍是快照的 `git diff HEAD~1 HEAD`,共 4 檔。

[Important] diff.txt:997(tests/test-gate.sh:340)情境 ⑪ 用 `rm -rf … docs …` 把 `docs/reviews/` 刪掉了。所以 `reviews_missing` 在 opt-in 守門 `[ -d docs/reviews ] || return 1`(check-claude-md.sh:151)就直接回傳,根本走不到「連共同祖先都沒有」那一支(:162–167)。`said "找不到共同祖先"`(test-gate.sh:349)之所以會過,是因為 `owed_dirs` 的警告剛好也含這幾個字。這正是 tests/CLAUDE.md ①警告過的「為了錯的理由而通過」。
  Failure: 把 :165–167 改成 `return 0`,也就是靜默擋下、不印警告。測試結果是 exit=0,90 ✅ / 0 ❌。改成吞掉警告,同樣抓不到。
  Evidence: 我在 ⑪ 插了 DBG。輸出是 `docs_reviews=n`,gate 輸出只有一行 `…也找不到共同祖先，這次只檢查 staged`(owed_dirs:108),沒有 `這次跳過 review 報告檢查`。
  連帶失真的宣稱有兩處。一是 tests/CLAUDE.md:11(diff.txt:610)的「連共同祖先都沒有時:兩處放行**但必須印出警告**」,實際上只有 owed_dirs 那一處被測到。二是 test-gate.sh:335–337 的註解。

[Important] diff.txt:989(tests/test-gate.sh:332)`said "改從共同祖先"` 分不出是哪個呼叫端印的。在 ⑩ 裡,`--start-segment` 會先跑 `owed_dirs`(check-claude-md.sh:183)。它用空 prefix 呼叫 `resolve_fork_base`,本身就會印出 `…），改從共同祖先 … 算起`。所以 `reviews_missing` 有沒有印警告,這條斷言都會過。
  Failure: 把 check-claude-md.sh:162 改成 `resolve_fork_base "review 檢查" "$head_sha" 2>/dev/null`,review 那一路就變成靜默退化。測試結果是 exit=0,90 ✅ / 0 ❌。
  Evidence: 上面那個 m2 變異的實跑結果。要分得出來,斷言要寫成 `review 檢查改從共同祖先`。

[Important] tests/test-gate.sh:273–276(diff.txt:930–933)⑦ 的標題註解還寫著「起點 commit 被改寫(amend / rebase)… `git commit --amend` 掉起點那個 commit … 現在退到共同祖先繼續算」。但這次新加的 :283–285 自己說這一則 amend 的是 HEAD、起點仍是祖先,還寫「上面那句註解原本寫…(S4 修正)」。實際上只改了 `expect` 的說明字串,標題沒改。
  Failure: 讀者照標題以為 ⑦ 有測到「起點被 amend」的 fork-point 退化。新註解又說已經修正,兩段在同一個情境裡互相矛盾。這是 §3.10「只修一半」的情形。
  Evidence: diff 只動了 :283–286,:273–276 原文沒變。

逐分支對照(新程式碼的每一支由哪則測試蓋到):
- `resolve_fork_base` 起點是祖先:⑦ 與之前所有情境
- `resolve_fork_base` 退到共同祖先:owed_dirs 由 :122–123 蓋到,reviews_missing 由 :331(block)蓋到,但警告是哪一路印的分不出來(第 2 條)
- `resolve_fork_base` 回傳 1:owed_dirs 由 :348–349 蓋到;reviews_missing 沒蓋到(第 1 條)
- `--segment-base` 起點不是祖先::328;沒有共同祖先::347

What I ran
- `grep -n "api server" tests/test-gate.sh` → 只有 :340 一處(這個目錄在測試裡從沒建過,rm 它沒有作用)
- 第一次 m1 用 `sed '165,167c\ …'` 產生變異 → sed 報錯,產出的 gate 是壞的(33 ❌ 全是 shell 錯誤),這次實驗無效、不採計
- m2(:162 加 `2>/dev/null`)跑 `/bin/bash tests/test-gate.sh <m2>` → exit=0,90 ✅ / 0 ❌
- m1 改用 perl 重做(:165–167 → `return 0`),`bash -n` 通過,跑 test-gate → exit=0,90 ✅ / 0 ❌
- 在 ⑪ 插 DBG 跑原版 gate → `docs_reviews=n`,輸出只有 owed_dirs 的警告

Not reported:
- `resolve_fork_base` 偷讀全域 `$base`,不經參數傳入。兩個呼叫端都先跑過 `read_base`,我找不到具體會壞的情境。
- ⑪ 的 orphan commit 會用 `git add -A` 把殘留的 p/、r/、w/、feat/ 等目錄一起收進去。每個目錄都有 CLAUDE.md,所以照樣放行,不影響斷言。
- 我沒有核對 scripts/CLAUDE.md:60–62 寫的「3 紅 / 7 紅 / 2 紅」。要核對得重做那三個變異,文件沒寫清楚變異改在哪一行。不過可以確定一件事:「不印警告 → 2 紅」只在「刪掉 `resolve_fork_base` 裡的 echo」時才可能成立;刪 reviews_missing:165 那行是 0 紅。
- 重構前後兩條警告句我逐字比過,一致。owed_dirs 用空 prefix,和舊措辭相同。