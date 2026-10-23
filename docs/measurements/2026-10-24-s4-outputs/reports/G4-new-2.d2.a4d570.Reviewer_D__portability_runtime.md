Critical 0 / Important 3 / Smells 0 — 審查範圍：快照 `git diff HEAD~1 HEAD`，偏重 `scripts/check-claude-md.sh` 的可攜性與執行環境

[Important] scripts/check-claude-md.sh:209 和 :275（diff.txt:209、:275）`git log --name-only` 會把非 ASCII 路徑加引號輸出，之後 `[ ! -d "$d" ] && continue` 又把這種目錄當成「已刪除」跳過，所以欠帳被靜靜放行。
  Failure: 起點之後用 SKIP commit 了 `中文/a.js`，下一個只改 README 的正常 commit 回 exit 0，`中文/CLAUDE.md` 的欠帳就此消失。舊版遇到 staged 的非 ASCII 目錄時，至少還會用錯誤的引號路徑擋下來。
  Evidence: 實跑情境 D 輸出 `exit=0`。對照的空白目錄情境 D2 是 `exit=1`，會擋下 `a b/CLAUDE.md`。建議 `git log` 與 `git diff --cached` 都加上 `-c core.quotePath=false`。

[Important] scripts/check-claude-md.sh:187-192（diff.txt:187-192）起點 commit 一旦被 rebase 改寫（例如起點是還沒 push 的本地 commit，之後跑 `git pull --rebase`），欠帳整筆作廢。gate 只往 stderr 印一行警告就放行，而 `--start-segment` 也會因為 `owed_dirs` 回空而允許重記起點。
  Failure: 本地 commit L 之後跑 `--start-segment`，再 SKIP commit `src/a.js`，然後 `git rebase up`。之後只改 README 的正常 commit 回 exit 0，`src/` 沒有 CLAUDE.md 也照樣進去。
  Evidence: 實跑輸出 `⚠️ 段落起點 6d1f… 不在目前分支的歷史裡…` 加上 `rebased-local-base exit=0`，`ls src` 仍只有 `a.js`。CI 情境 7 只涵蓋換分支，沒涵蓋 rebase 這條常見路徑。scripts/CLAUDE.md 用 `grep rebase` 找也是 0 筆，這個盲點沒有寫進文件。

[Important] scripts/check-claude-md.sh:195-210（diff.txt:195-210）`owed_dirs` 每個 commit 會 fork 約 10 個以上的 subshell 或 grep/sort，範圍又是「起點到 HEAD」，會無上限地變長。起點在第一次 SKIP 時自動記下後，只有手動跑 `--start-segment` 才會往前推，忘了跑的專案每個 commit 都會越來越慢。
  Failure: 起點後累積 1000 個 commit 時，每次 pre-commit 要 10.5 秒。起點是空樹時，`range=HEAD` 會掃整段歷史，情況相同。
  Evidence: 在 1000 個 commit 的拋棄式 repo 跑 `time /bin/bash gate.sh`，結果是 `10.520 total`、exit 0。

What I ran
- `shellcheck -S warning scripts/check-claude-md.sh` → 沒有輸出，exit 0
- 抽出 diff.txt:11-98 的 CI 情境，用 /bin/bash 3.2.57 跑 → 22 個 expect 全部 ✅。可見 `$'\001'` 當 case pattern、here-doc 裡的 `$(...)` 帶 \001、`local` 在 bash 3.2 都正常。
- worktree 跑 `--start-segment` → 起點檔寫到 `.git/worktrees/<n>/dd-segment-base`，主 repo 的 `.git/dd-segment-base` 不存在，確實每個 worktree 各一份。
- 在 repo 子目錄 `sub/` 跑 `--start-segment` 和 `--segment-base` → 正常印出同一個 sha
- 起點是上游共同祖先時 rebase → 仍擋 `src/CLAUDE.md`，exit 1
- 起點是本地 commit 時 rebase → 只印警告，exit 0（第 2 條發現）
- SKIP commit 之後 `--amend` → 仍擋，exit 1
- 非 ASCII 目錄 → exit 0（第 1 條發現）；含空白的目錄 → 擋下，exit 1
- `git init --object-format=sha256` → 空樹起點是 64 碼雜湊，之後正常擋下，exit 1
- 不在 repo 裡跑 `--segment-base` → 印「不在 git repo 內」，exit 1
- 側分支上的 SKIP commit 被 merge 回來 → 擋下，exit 1
- 1000 個 commit 的效能測試 → 10.52 秒（第 3 條發現）

Not reported：
- `cd "$top"` 和 `BASE_FILE` 的相對路徑處理實測沒問題：githooks/pre-commit 本來就用 toplevel 的絕對路徑 exec，hook 也是在 toplevel 執行。
- bare repo 不會觸發 pre-commit。
- merge 衝突解決時那次 commit 的 staged 會含整批 merge 進來的檔，這是舊行為，不是這次 diff 引入的。
- `git rebase --continue` 會不會跑 pre-commit 沒有實測。要查證的話，用真的 `git rebase` 製造衝突，在 hook 裡印一個標記即可確認。
- CHANGELOG 說「22 個情境」，我數了 diff 裡的 expect 正好 22 個，屬實。