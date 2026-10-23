Critical 1 / Important 3 / Smells 0。審查範圍是快照的 `git diff HEAD~1 HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）。

**[Critical] tests/test-gate.sh:338-350（diff.txt:188-199）情境 ⑪ 宣稱要守住「`reviews_missing` 沒有共同祖先時不可靜默放行」，實際上根本跑不到那個分支**
- 問題：第 190 行先 `rm -rf … docs`，所以 `reviews_missing` 在 `[ -d docs/reviews ] || return 1` 那一行就回傳了，走不到 `resolve_fork_base` 失敗後的那一支。`said "找不到共同祖先"` 能成立，是因為 `owed_dirs` 印了「…也找不到共同祖先，這次只檢查 staged」（check-claude-md.sh:108），這句剛好包含同一串字。這正是新寫進 tests/CLAUDE.md 的那個陷阱：「為了錯的理由而通過」。
- 失敗情境：有人把 check-claude-md.sh:165-166 的兩行警告刪掉，也就是註解自己點名的「第一版靜默通過」那個回歸，測試仍然 90 ✅ / 0 ❌。另一個變異是把那一支的 `return 1` 改成 `return 0`（改成擋下），結果也是 90 ✅。
- 波及的宣稱：tests/CLAUDE.md:11 說「連共同祖先都沒有時：兩處放行**但必須印出警告**」已有測試覆蓋，這句在 HEAD 不成立。scripts/CLAUDE.md:59-62 的變異表也漏了這一組，這組的紅數是 0。
- 證據：下方「我跑了什麼」的 M1、M3。

**[Important] tests/test-gate.sh:331-333 情境 ⑩ 驗不出「`reviews_missing` 退到共同祖先」**
- 問題：`--start-segment` 會先跑 `owed_dirs`（check-claude-md.sh:183），它的 `resolve_fork_base ""` 已經印出「…改從共同祖先 … 算起」。所以 `said "改從共同祖先"` 分不出這句是誰印的。正確的寫法應該斷言帶前綴的「review 檢查改從共同祖先」。
- 失敗情境：把 `reviews_missing` 改成不經 `resolve_fork_base`、直接用 `range_base=$base`，測試仍然 90 ✅。測試名稱「reviews_missing 退到共同祖先，照樣擋」因此不成立。
- 證據：M2。

**[Important] tests/test-gate.sh:283-285 新加的註解有三處和 HEAD 不符**
1. 「上面那句註解原本寫『起點 commit 被改寫』」暗示那句已經改掉，但它原封不動。第 273 行仍然是 `# ⑦ **起點 commit 被改寫(amend / rebase)之後…`，第 275 行也還寫著「現在退到共同祖先繼續算」。結果同一個情境的標題和隔幾行的新註解直接矛盾。證據：`git grep -n '起點 commit 被改寫'` 命中 273 和 284 兩行。
2. 「走的是 `range_base="$base"` 那一支」指的是這次 diff 剛刪掉的程式碼：HEAD~1 在第 139 行，HEAD 裡已經沒有了，現在是 `resolve_fork_base` 裡的 `echo "$base"`。證據：`git grep -n 'range_base='` 只剩 check-claude-md.sh:162 和這句註解本身。
3. 「真正把起點改寫掉的情境在最後面 ⑩」與 ⑩ 實際做的事不符。⑩ 是 `git checkout -q -b sideline "${BASE_BEFORE}^"`（diff.txt:168），也就是從起點的父 commit 切出新分支，起點 commit 本身沒有被 amend 或 rebase。整份測試裡沒有任何一則真的改寫起點 commit。

**[Important] scripts/CLAUDE.md:58、check-claude-md.sh:78 的「S6 的 reviewer 預言過」查不到依據**
- 問題：快照裡找不到任何 S6 審查報告提到「mode 參數」或「預言」。
- 失敗情境：§3.10 說的「把自己的判斷掛到別人頭上」。後人會以為這個設計取捨已經被第三方驗證過，不會再重新評估。
- 證據：`git grep -n -e '預言' -e 'mode 參數'` 只命中這次新加的兩處；`docs/reviews/` 只有 CLAUDE.md；`git log` 只有兩個 commit（base、change）。
- 對照：同一段的「S6 的 review 抓到這兩處已經漂移（一處退到共同祖先、另一處直接放行）」在快照裡有旁證，就是既有的 check-claude-md.sh:157-160、163-164 那兩段「第一版直接 return 1 放行／靜默通過」，所以那句不報。

**需要外部查證（交回）**
- S6 的原始審查報告（快照之外的 `docs/reviews/S6-*.md` 或當次對話紀錄）裡有沒有「加 mode 參數只是把決策搬進函式」這段原文。查到就能判定上面那條歸因能不能保留。

**Not reported**
- 全形和半形標點混用：scripts/CLAUDE.md:23-33、check-claude-md.sh:145-148、test-gate.sh:222 起的 S6 段落早就是半形，算既有的混用，不是這次引入的慣例違反。只有新段落內部前後不一致（scripts/CLAUDE.md 的 43-58 行用全形、59-62 行用半形），程度太輕。
- scripts/CLAUDE.md 新表格逐格對照程式碼都成立。前後有空行，縮排 4 格，留在清單項目裡，渲染結構沒問題。
- check-claude-md.sh:71 寫「exit 1」但實際是 `return 1`，措辭問題，不影響理解。
- 變異紅數「3／7／2 紅」沒有記「哪個變異讓哪幾則變紅」，也沒標插在哪一行，不符合全域模板 §3.9 那條；但 Critical 那條已經實證表格缺了一組，這裡不重複報。
- CHANGELOG.md:413 仍寫「起點被 amend／rebase 改寫時改從共同祖先算」：那是已發布區塊，不可以改，而且行為沒變。
- 這次警告字串逐字沒變，算重構、gate 行為沒改，所以不觸發根 CLAUDE.md 要求同步 README、ARCHITECTURE、CHANGELOG 的規則。

**我跑了什麼**
- 讀 diff.txt 全段 → 讀完
- `git log --oneline` → 2 個 commit
- `git ls-files | grep CLAUDE.md` → 10 份
- `ls docs/reviews` → 只有 CLAUDE.md
- `git grep` 這幾個字串：`resolve_fork_base`、`共同祖先`、`segment-base`、`被改寫`、`S6`、`漂移`、`預言`、`mode 參數`、`range_base=`、`起點 commit 被改寫` → 結果如上
- `git show HEAD~1:scripts/check-claude-md.sh | grep -n 'range_base="$base"'` → 在第 139 行
- 在 mktemp 拋棄式目錄做三個變異，每個都跑 `bash tests/test-gate.sh <變異 gate>`：
  - M1：刪掉 check-claude-md.sh:165-166 的警告 → exit 0，90 ✅ / 0 ❌
  - M2：把 `reviews_missing` 改成 `range_base=$base`、不走 `resolve_fork_base` → exit 0，90 ✅ / 0 ❌
  - M3：把沒有共同祖先那一支的 `return 1` 改成 `return 0` → exit 0，90 ✅ / 0 ❌