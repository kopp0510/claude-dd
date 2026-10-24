Critical 0 / Important 2 / Smells 2：審查範圍是快照的 `git diff HEAD~1 HEAD`(scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh)

[Important] tests/test-gate.sh:335-349(diff 檔 185-199 / 992-1006)：情境 ⑪ 宣稱「兩處都要放行但講出來」,實際只測到 `owed_dirs` 那一處。`reviews_missing` 的「沒有共同祖先」分支根本沒跑到。
  Failure：第 340 行 `rm -rf … docs …` 把 `docs/reviews` 刪掉了,`reviews_missing` 在 `[ -d docs/reviews ] || return 1`(check-claude-md.sh:151)就直接放行。`said "找不到共同祖先"` 吃到的是 `owed_dirs` 的警告:「…也找不到共同祖先，這次只檢查 staged」(:108)也含這個子字串。所以就算 `reviews_missing` 退回「靜默放行」,測試還是全綠。這正是 diff 自己在 tests/CLAUDE.md ① 警告的那種「為了錯的理由而通過」(opt-in 看的是工作目錄)。同一個錯誤宣稱也寫在 tests/CLAUDE.md:11(「連共同祖先都沒有時:兩處放行**但必須印出警告**」),以及 scripts/CLAUDE.md:49 表格隱含的「有測試保護」。
  Evidence：變異把 check-claude-md.sh:165 的警告換成別的字串後,`test-gate.sh` 結果是 exit=0、90 ✅ / 0 ❌(見下方 What I ran)。

[Important] tests/test-gate.sh:273-276(diff 檔 930-933,這次沒改到的行)和 :283-285(新增)互相矛盾。新註解說「上面那句註解原本寫『起點 commit 被改寫』…(2026-10-07 S4 修正)」,但上面那句其實沒修。
  Failure：⑦ 的段頭仍然寫「⑦ **起點 commit 被改寫(amend / rebase)之後**…現在退到共同祖先繼續算」,而緊接著的新註解說這一則「**沒有**跑到 fork-point 退化」、而且已經修正了。讀的人看到上一行說這則在測 fork 退化,下一行又被告知「已修正」。這是 §3.10「補了一句限定之後，把那一段從頭讀到尾」那類自造矛盾。另外「原本寫」指的對象不存在:舊的 expect 描述是「amend 段落內的 commit:仍然照擋(零報告)」(diff 檔 138),從來不含「起點 commit 被改寫」。

Smells
- [Smells] check-claude-md.sh:70-72、82-84 有一處可能的隱藏耦合:`resolve_fork_base` 隱式讀全域 `$base`(由 `read_base` 設定),但參數說明只列了 `$1`/`$2`。哪天有呼叫端沒先跑 `read_base`,或在 subshell 裡改了 `base`,會拿到前一次的值,錯了也不報錯。
- [Smells] tests/test-gate.sh:340 刪除清單裡的路徑名稱名不副實。`'api server'` 這個目錄在測試裡從沒建過(建的是 `"my dir"`,:196)。p、r、w、keep、feat、feat2、功能、模組、my dir、top.js 都沒刪,`commit r7` 的 `git add -A` 會把它們全部加回去,所以 r7 並不是「lone」單一目錄的 commit。現在剛好都有 CLAUDE.md 才放行;以後新增情境如果留下沒有 CLAUDE.md 的程式碼目錄,⑪ 會因為無關的原因變紅。

需要外部查證
- scripts/CLAUDE.md:55、58 和 check-claude-md.sh:78、80 寫「S6 的 reviewer 預言過」「S6 的 review 抓到這兩處已經漂移」。快照的 `docs/reviews/` 只有 CLAUDE.md,沒有 S6 報告,在範圍內無從核對(§3.10「把自己的判斷掛到別人頭上」)。要查的是 S6 審查報告的原文。

What I ran
- `git grep -n -e resolve_fork_base -e 共同祖先 -e 'api server' -e fork-point -e 預言` → 只在 diff 的 4 檔與 CHANGELOG.md:413(歷史敘述)、templates/global/CLAUDE.md:366(無關)出現;`ls docs/reviews` → 只有 CLAUDE.md
- 變異 a(check-claude-md.sh:165 的警告換成別的字串),跑 `test-gate.sh` → exit=0、90 ✅ / 0 ❌(沒被抓到)
- 變異 d(刪掉 :89 的 fork 警告),跑 `test-gate.sh` → exit=1、2 ❌(「不在目前分支的歷史裡」「改從共同祖先」),和 scripts/CLAUDE.md:62 寫的「2 紅」一致

Not reported
- 「3 紅」「7 紅」這兩個數字沒驗:文件沒寫變異的具體寫法,我造的變異跟原作者不一定同一種。
- 既有問題,不在 diff 內:check-claude-md.sh:170 寫「四份文件」,test-gate.sh:264 和 scripts/CLAUDE.md:30 寫「五份文件」;「前 61 項」這個數字沒重新數。
- 情境 ⑩ 的 `said "改從共同祖先"` 也會被 `owed_dirs` 的同一句警告滿足,但那一則的 block 結果已經證明 `reviews_missing` 走到了 fork 退化,所以沒報。