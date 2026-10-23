Critical 1 / Important 4 / Smells 0。審查範圍是快照的 `git diff HEAD~1 HEAD`（2f57e30），重點是 `scripts/check-claude-md.sh` 怎麼結算欠帳。

[Critical] scripts/CLAUDE.md:8 這次改了 gate 腳本，同一個 commit 卻沒有更新 `scripts/CLAUDE.md`，違反本 repo 自己的 gate 規則。
  Failure: 第 8–11 行還寫著「必須存在 CLAUDE.md 且同批 staged；逃生口 `SKIP_DOC_CHECK=1`」，完全沒提段落起點、欠帳結算、`--start-segment`、`--segment-base`、`.git/dd-segment-base`。這個 commit 本身只能靠跳過檢查才進得去（gate 會擋「改 .sh 但 CLAUDE.md 沒同批 staged」）。第 21 行要求「同步檢視全域模板 §3.9」也沒照做：在快照裡 `git grep` 新參數名，只命中 ci.yml 和腳本本身。
  Evidence: `git show --stat HEAD` 只列出 ci.yml、CHANGELOG.md、scripts/check-claude-md.sh 三個檔；根目錄 CLAUDE.md「開發本 repo」寫明「改 `.sh` 等程式碼檔時，該目錄的 CLAUDE.md 必須同批更新」。

[Important] scripts/check-claude-md.sh:76（diff 檔 209 行 `git log ... --name-only`）路徑含中文的目錄，SKIP 跳過的欠帳完全追不到。
  Failure: git 預設 `core.quotePath=true`，中文路徑會被輸出成 `"src/\351\240\201..."` 這種帶引號的形式，結尾是 `"`，所以 `code_dirs_of` 的 `\.(js|...)$` 比對不到。結果：SKIP 新增 `src/頁面/a.js` 之後，下一個只改 README 的正常 commit 直接放行。staged 那條路一樣有這個問題（原本就存在），這次 diff 等於把同一個盲點複製進了新的欠帳路徑。
  Evidence: 實跑 S1，`[c1] skip-pass` 之後 `[c2] pass`、`[c3] pass`。對照組 S1b（路徑含空白）會正確擋下 `my src/CLAUDE.md`。修法是 git 指令都加 `-c core.quotePath=false`；全域模板 §3.9 步驟 8 就是這樣寫的。

[Important] scripts/check-claude-md.sh:57-60, 151 欠帳把「起點之後所有沒同批更新 CLAUDE.md 的 commit」都算進去，包括從沒經過 gate 的別人的 commit，而且錯誤訊息斷言它們「跳過檢查」。
  Failure: 起點記下之後，`git merge` 或 `git pull` 拉進隊友的 commit（他們沒裝 gate，改了 `lib/l.js` 沒改 `lib/CLAUDE.md`）。接著自己只改 README 的 commit 被擋，訊息寫「段落起點之後有 commit 跳過檢查改了這裡的程式碼」，這是錯的斷言，違反專案的「不確定就說不確定」。而且有欠帳時 `--start-segment` 會拒絕重記起點，唯一出路是去補別人目錄的 CLAUDE.md，或照提示 `rm` 掉起點檔。
  Evidence: 實跑 S2，`[mine] BLOCK`，訊息是 `lib/CLAUDE.md（段落起點之後有 commit 跳過檢查改了這裡的程式碼…）`。

[Important] scripts/check-claude-md.sh:76 merge commit 自己帶進的程式碼不會記成欠帳。
  Failure: 解 merge 衝突時順手新增 `newdir/n.js`，用 `SKIP_DOC_CHECK=1` commit。因為 `git log --name-only` 不帶 `-m`/`--cc` 時，merge commit 不列任何檔案，這筆改動就沒記帳，之後的正常 commit 照樣放行。
  Evidence: 實跑 S3，merge commit 的 log 只輸出 `^A`、沒有檔名，`[after] pass`。

[Important] scripts/check-claude-md.sh:36-43, 123 起點檔存在、但內容指向不存在的物件時（例如改寫歷史後 gc 掉了），gate 靜默停用欠帳追蹤，`--segment-base` 還報錯成「沒記過」。
  Failure: `read_base` 失敗時，主流程（第 123 行 `read_base && owed=...`）不印任何訊息，SKIP 欠下的 `src` 被放行。`--segment-base` 印「還沒記段落起點」，但實際是「記了，只是讀不懂」，屬於把不確定退化成確定的錯誤訊息。下一個 SKIP commit 還會悄悄改寫這個起點。
  Evidence: 實跑 S4，把起點檔寫成一個不存在的 sha，`[c2] pass`，`--segment-base` 輸出「❌ 還沒記段落起點」、exit=1。

[Important] scripts/check-claude-md.sh:51-53 起點記成空樹時 `range=HEAD`，等於把整段歷史都算進來。
  Failure: 空 repo 先跑 `--start-segment`（記成空樹），再 `git fetch` 加 `reset` 拉進既有的遠端歷史。第一個本地正常 commit 會因為遠端歷史裡的舊目錄 `old/CLAUDE.md` 被擋，`--start-segment` 也會因為這些「欠帳」拒絕重記。
  Evidence: 實跑 S5，`[first_local] BLOCK`，列出 `old/CLAUDE.md`。

What I ran
- 讀 diff.txt 1–314 行、快照的 `scripts/CLAUDE.md` → 第 8–11 行只描述 staged 規則
- `git -C <快照> show --stat HEAD` → 只改了 3 個檔，沒有 scripts/CLAUDE.md
- `git -C <快照> grep -n -e start-segment -e segment-base -- ':!CHANGELOG.md'` → 只命中 ci.yml 和腳本本身
- `/bin/bash --version`、`grep runs-on ci.yml` → 本機是 bash 3.2.57；CI 只跑 ubuntu-latest
- `/bin/bash /tmp/gate_exp_A.sh <快照>/scripts/check-claude-md.sh`（在 mktemp 建的拋棄式 repo 跑，hook 直接呼叫快照裡的 gate 腳本）：
  - S0：bash 3.2 下 `\001` 切分正常，SKIP 後擋下 `src/CLAUDE.md`
  - S1：中文目錄，SKIP 後 pass，staged 也 pass（錯）
  - S1b：路徑含空白，正確擋下
  - S2：隊友 commit merge 進來 → 被擋，訊息寫「跳過檢查」（錯）
  - S3：merge 時用 SKIP 加的程式碼 → 放行（錯）
  - S4：起點檔指向不存在的物件 → 靜默放行，`--segment-base` 寫「還沒記」
  - S5：空樹起點加上拉進的歷史 → 擋下 `old/CLAUDE.md`
  - S6：同一個 commit 補兩份 CLAUDE.md（`grep -vxF` 多行 pattern）→ 兩筆都銷帳，正確

Not reported:
- `git log` 預設不是拓撲排序，時鐘偏差可能讓順序錯亂：只是推論，沒有重現。
- 起點檔寫成 `HEAD` 這類 ref 名稱也會被 `read_base` 接受：屬於人為竄改，不報。
- 長歷史下每個 commit 都要開多個子程序的效能問題：沒有量測。
- `templates/global/CLAUDE.md` §3.9 是否需要同步：屬於方向 A 以外的文件審查，只在 Critical 那條附帶提到。
- 要確認原作者是否用 SKIP 或 `--no-verify` 提交 2f57e30：查 `git -C <快照> log -1 --format=%B HEAD` 看有沒有 SKIP 相關 trailer，或問作者。