Critical 0 / Important 4 / Smells 0。審查範圍：快照 `git diff HEAD~1 HEAD`，共 4 檔。

[Important] tests/test-gate.sh:335-349（diff 檔 185-199）情境 ⑪ 宣稱同時驗證兩處「沒有共同祖先時放行但印警告」，其實完全沒跑到 `reviews_missing` 的那條路。
  Failure：第 340 行 `rm -rf … docs …` 把 `docs/reviews` 刪了，所以 `reviews_missing` 在 `[ -d docs/reviews ] || return 1`（check-claude-md.sh:151）就直接回傳，走不到 :162-167。第 349 行 `said "找不到共同祖先"` 比對到的是 `owed_dirs` 在 :108 印的「…也找不到共同祖先…」。把 :165 那句警告刪掉，測試照樣 90 ✅；把 :108 那句刪掉才會紅。
  這正是 tests/CLAUDE.md 自己點名的「為了錯的理由而通過」。受牽連的宣稱有 4 處：scripts/CLAUDE.md 表格 `reviews_missing` 列的「放行，但印警告」、test-gate.sh:336-337 的「必須斷言那句警告」，以及 tests/CLAUDE.md 的「兩處放行但必須印出警告」。
  Evidence：M1（刪 :165）→ rc=0 ok=90 bad=0；M4（刪 :108）→ 1 紅，紅的是「輸出沒提到：找不到共同祖先」。

[Important] tests/test-gate.sh:304（diff 檔 154）的反事實宣稱是假的。原文：「沒有這一段的話，把 `--segment-base` 也改成『退到共同祖先』的變異不會有任何測試變紅」。
  Failure：情境 7（:119-120）把起點設成 `side`，它和 HEAD 有共同祖先，所以這種變異在舊測試就會紅。scripts/CLAUDE.md:60 寫的「軟退化 → 3 紅」本身也包含這一紅，同一批文件自相矛盾。
  Evidence：M2（:210 改成 `git merge-base "$base" HEAD`）只跑到 ⑨（test 截到 :299）→ ok=80 bad=1，紅的是「❌ 起點失效時 --segment-base 要失敗」。跑全檔是 3 紅。

[Important] scripts/CLAUDE.md:27 與 tests/CLAUDE.md:33 的變異表第一列「那行 → 永遠 `return 1` | 12」，這次 diff 之後已經不成立。
  Failure：新加的 ⑩ 也被這個變異打紅，到 HEAD 實測是 15 紅。照表核對的人會以為測試少了東西，或以為變異沒有生效。兩份檔要一起改，或標成「S6 當時的快照」。
  Evidence：M3（:151 改成 `return 1`）→ ok=83 bad=15，多出的 3 紅都在 ⑩：「起點不是祖先:reviews_missing…」、`said`、:345 的 `base_is`。

[Important] tests/test-gate.sh:283-285（diff 檔 139-141）新註解說「上面那句註解原本寫『起點 commit 被改寫』…（S4 修正）」，但那句註解還留在原處，沒有改。
  Failure：:273-276 的 ⑦ 標頭仍寫「起點 commit 被改寫（amend / rebase）之後…」，和緊接在下面的更正互相矛盾。讀的人會以為 ⑦ 有涵蓋「起點被改寫」。
  Evidence：diff 檔 :273 原文沒有變動。這次只改了 `expect` 的說明字串（diff 檔 :138→:142）。

## What I ran
- 讀 diff 檔全文 → 4 檔的 diff 與整檔內容
- `git grep` 查 `resolve_fork_base`、`預言`、`改從共同祖先`、`起點被改寫`、`segment-base`、`mode 參數` → 找到的出現點只在 diff 本身、CHANGELOG 的歷史敘述與 `--segment-base` 的用法說明，沒有其他還在描述舊性質的地方
- `ls docs/reviews`、`git grep fork|S4|漂移 -- docs` → `docs/reviews` 只有 CLAUDE.md，設計文件裡沒有 S4/S6
- 暫存目錄跑變異（`/bin/bash test-gate.sh <變異 gate>`）：
  - baseline → 90 ✅ / 0 ❌
  - M1（刪 :165）→ 90 ✅ / 0 ❌
  - M2 只跑到 ⑨ → 80 ✅ / 1 ❌；M2 全檔 → 88 ✅ / 3 ❌
  - M3（:151 改成 `return 1`）→ 83 ✅ / 15 ❌
  - M4（刪 :108）→ 90 ✅ / 1 ❌

## Not reported
- 需要外部查證：「S6 的 review 抓到這兩處已經漂移」與「S6 的 reviewer 預言過（mode 參數）」這兩句歸因，快照裡找不到 S6 報告可以核對，要去讀 S6 的報告原文。
- 既有問題：check-claude-md.sh:193 的「範圍 ${base}..HEAD」，在退到共同祖先時印的是記下的起點，不是實際用的範圍；:284 的 `git diff $base` 在起點失效時同樣不準。兩處都是 diff 之前就有。
- 小問題，不報：test-gate.sh:340 的 `rm` 清單列了不存在的 `'api server'`，而 p、r、w 等目錄沒刪，被 `git add -A` 一起收進 r7；不影響結果。
- `resolve_fork_base` 偷讀全域 `$base`，函式註解沒寫；沒有具體失敗情境，不報。