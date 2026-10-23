Critical 1 / Important 2 / Smells 0 — 範圍：`HEAD~1..HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）

[Critical] scripts/CLAUDE.md:59-62 變異結果（「3 紅」「7 紅」「2 紅」）沒有註明插在哪一行；表格 25-29 行的「那行改成永遠 `return 1`」也沒有行號。
  Failure: 讀者照「`--segment-base` 改成軟退化」去改，會有多種改法，得到的紅數可能不同，無法重現 3 紅。
  Evidence: 根目錄 CLAUDE.md:307 規定「寫進文件的變異結果要註明插在哪一行」；scripts/CLAUDE.md:59-62 只寫函式名與紅數。

[Important] scripts/CLAUDE.md:55-58 與 scripts/check-claude-md.sh:78、80 歸因「S6 的 review 抓到這兩處已經漂移」「S6 的 reviewer 預言過」，但 repo 裡沒有那份報告。
  Failure: 下一個人會因為「有人審過」而不再重估；那份報告實際上不在這個 repo 裡，無從核對。
  Evidence: `ls docs/reviews` 只有 CLAUDE.md；`git grep -n -E '預言|S6'` 只命中這次 diff 自己的新註解；`git log --all` 只有 85d416f、e0177bd 兩個 commit。根目錄 CLAUDE.md §3.10 要求引用前先 grep 那份文件的內文。

[Important] tests/test-gate.sh:283 的註解「上面那句註解原本寫『起點 commit 被改寫』」指錯位置。
  Failure: 讀者往上看，緊鄰的那一行（HEAD~1 的 282 行）是「改寫 HEAD(起點之後),起點本身仍在」，沒有這句話；這句話其實在 HEAD~1 的 273 行段落標題「⑦ 起點 commit 被改寫(amend / rebase)之後」。
  Evidence: `git show HEAD~1:tests/test-gate.sh | sed -n '273p;282p'`（HEAD~1 的 273 行是標題、282 行是 amend 註解）。

What I ran
- `sed -n '1,260p' …/G2/diff.txt` → 讀完 diff 前段與 scripts/CLAUDE.md 的 HEAD 版
- `git grep -n` 查 resolve_fork_base、range_base、--segment-base、owed_dirs、reviews_missing（排除兩支被改的腳本）→ 只有 CLAUDE.md 與各層文件的既有敘述，沒有任何文件描述 resolve_fork_base 的行為
- `git grep` 查「變異」「插在哪一行」→ 根目錄 CLAUDE.md:307 有規則，scripts/CLAUDE.md 與 tests/CLAUDE.md 的新變異數字沒有行號
- `sed -n '150,190p'`、`grep -n -A25 'segment-base)'`、`sed -n '93,125p'` 讀 check-claude-md.sh → reviews_missing、--segment-base、owed_dirs 三處的退化行為與表格（scripts/CLAUDE.md:46-50）一致，沒有發現行為錯誤
- `git show HEAD~1:tests/test-gate.sh | grep -n -B2 'amend 段落內的 commit'`、`sed -n '273p;282p'` → 確認註解位置
- `git grep -n -E '預言|S6'`、`ls docs/reviews`、`git log --all` → 找不到 S6 報告
- `git show HEAD~1:scripts/CLAUDE.md | grep -c '，'`（27）與 `grep -c ', '`（0）→ 標點慣例是全形
- `sed -n '1,20p' CHANGELOG.md`；`git grep resolve_fork_base` 在 CHANGELOG 無命中 → 行為未變（既有 owed/review 的放行、硬失敗規則都保留），不要求 CHANGELOG 條目

Not reported
- 未重跑變異數字（3/7/2、12/5/2）。需要外部驗證：對每個變異跑 `bash tests/test-gate.sh <改壞的 gate>`，數紅數並記下插入的行號。
- S6 報告是否存在於其他 worktree 或 scratchpad，這個 repo 外查不到，交回給主對話確認。
- 「前 61 項」「4 在舊的 61 項」是位置式的計數，目前看不出會過期，不列為發現；但它與 tests/CLAUDE.md 自己寫的「不要寫 N 項」有衝突。
- 中文標點混用（如 scripts/CLAUDE.md:59 的「,」）是風格問題，沒有可描述的失敗情境，不列入。
- CHANGELOG 未發布沒有 S4 條目：這次沒有使用者可見的行為變更，不需要。
- resolve_fork_base 三個呼叫點、test ⑩⑪ 的 said 字串比對，我讀過都與程式碼吻合，沒有發現錯誤。