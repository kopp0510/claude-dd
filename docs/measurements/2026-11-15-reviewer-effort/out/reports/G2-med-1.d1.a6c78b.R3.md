Critical 1 / Important 2 / Smells 0 — 範圍是快照的 `git diff HEAD~1 HEAD`(4 個檔)

[Critical] tests/test-gate.sh:340(diff.txt:997)情境 ⑪ 把 `docs` 也一起刪了,之後沒有重建,所以 `reviews_missing` 的「連共同祖先都沒有」那一支一次都沒跑到。
  Failure:orphan 線上沒有 `docs/reviews/`,`reviews_missing` 在 `[ -d docs/reviews ] || return 1`(check-claude-md.sh:151)就直接回 1。第 349 行 `said "找不到共同祖先"` 能過,是因為 `owed_dirs` 印了「也找不到共同祖先,這次只檢查 staged」(check-claude-md.sh:108)。這正是同檔第 319–321 行註解自己點名的「為了錯的理由而通過」。
  Evidence:三個變異版各跑一次,全都是 90 ✅ / 0 ❌:M1 把第 165 行的警告改成 `:`;M2 把第 167 行的 `return 1` 改成 `return 0`(無共同祖先時改成擋下);M3 是下一條的變異。也就是說,tests/CLAUDE.md:11 的「連共同祖先都沒有時:兩處放行但必須印出警告」、scripts/CLAUDE.md:49 那張表的 `reviews_missing` 那一列、test-gate.sh:335–337 的註解,三者寫的事情都沒有測試在守。

[Important] tests/test-gate.sh:332 `said "改從共同祖先"` 分不出警告是哪一處印的。
  Failure:`--start-segment` 會先跑 `owed_dirs`(check-claude-md.sh:183),它的 `resolve_fork_base ""` 已經印過「改從共同祖先」。所以就算 `reviews_missing` 的退化警告被吞掉或改壞,這則照樣綠。`$1` 那個 prefix(「review 檢查」)沒有任何斷言釘住。
  Evidence:M3 在 check-claude-md.sh:162 的呼叫後面加 `2>/dev/null`,結果 90 ✅ / 0 ❌。要釘住就斷言完整片段「review 檢查改從共同祖先」。

[Important] tests/test-gate.sh:340 這行看起來是在清空 worktree,實際沒有;`'api server'` 也指向不存在的目錄。
  Failure:`git rm --cached .` 之後,`top.js`、`my dir/`、`功能/`、`模組/`、`p/`、`r/`、`w/`、`keep/`、`mv/`、`feat*/` 都還留在工作目錄,第 342 行的 `commit`(`git add -A`)會把它們全部加回 r7。所以「無關歷史上的第一個 commit」並不是只有 `lone/`。現在剛好每個目錄都有自己的 CLAUDE.md 才放行;之後只要前面的情境留下一個沒有 CLAUDE.md 的程式碼目錄,這則就會因為跟情境無關的原因變紅。
  Evidence:Grep `api server` 在 test-gate.sh 只有第 340 行這一處;第 338–342 行沒有任何清除未追蹤檔的動作。

What I ran
- 分段 Read 讀完 diff.txt 第 1–1010 行 → 整段讀完
- Grep `api server|docs/reviews` tests/test-gate.sh → 只有 :340 提到 `'api server'`;`docs` 在 :340 被刪,之後沒有重建
- 在 mktemp 目錄做 M1(:165 警告改成 `:`)、M2(:167 `return 1` 改成 `return 0`)、M3(:162 加 `2>/dev/null`),各跑 `/bin/bash tests/test-gate.sh <變異版>` → 三者都是 exit 0,90 ✅ / 0 ❌

Not reported
- `resolve_fork_base` 讀的是全域 `$base`,沒有當參數傳進去:這是既有寫法,目前兩個呼叫端都先跑過 `read_base`,不會出錯。
- `BASE_BEFORE` 這個名字其實是 `--start-segment` 跑完之後的值:用途符合預期,不構成錯誤。
- 走「起點不是祖先」那條路的 `--start-segment` 會印兩次同樣的 fork 警告:改動前就是這樣。
- scripts/CLAUDE.md 的段落裡混用半形與全形標點:只是風格問題。

需要外部查證
- scripts/CLAUDE.md:60–62 寫的變異紅數(3 / 7 / 2):要用當次的變異寫法重跑才能核對。我沒有那三份變異的確切改法,沒辦法重現。修掉上面的 Critical 之後,「退化時不印警告」那組的紅數會變,需要重量。
