Critical 0 / Important 4 / Smells 0 — 審查範圍：快照 `git diff HEAD~1 HEAD`，共 3 個檔：ci.yml、CHANGELOG.md、scripts/check-claude-md.sh

[Important] scripts/check-claude-md.sh（diff 檔第 125 行起）：這次改了 `.sh`，但同目錄的 `scripts/CLAUDE.md` 沒有一起改，等於違反 gate 自己的規則；`scripts/CLAUDE.md` 對 gate 的描述也因此過期。
  Failure：把 HEAD 的改動 apply 到 HEAD~1 的 clone 上，再跑 gate，結果 exit 1，訊息是「scripts/CLAUDE.md（該目錄有程式碼變更，但 CLAUDE.md 未一起 staged）」。`scripts/CLAUDE.md` 第 8–10 行仍寫「規則：staged 變更含程式碼檔的目錄…同批 staged」，沒提到段落起點、欠帳結算、`--start-segment`、`--segment-base`。
  Evidence：`git show --stat HEAD` 只列出 3 個檔；實驗 D 的 gate exit=1。
  建議：補上 `scripts/CLAUDE.md` 的規則描述和兩個新參數。

[Important] scripts/check-claude-md.sh:11 和 CHANGELOG.md（diff 第 120 行）：兩處都寫 `--segment-base`「給迴圈步驟 3、4、8 算整段範圍」，但現在沒有任何地方用到它。scripts/CLAUDE.md 第 21 行規定「gate 的檢查邏輯改動時，同步檢視全域模板 §3.9」，這次也沒做。
  Failure：templates/global/CLAUDE.md 第 227–250 行裡，步驟 3、4 沒有指定範圍指令，步驟 8 用的是 `git show --name-only --pretty=format: HEAD`，只看最後一個 commit。全 repo 用 `git grep` 找 `segment-base` 和 `start-segment`，除了這 3 個檔以外沒有任何結果，dd-init 也沒有。所以這是一句在註解和文件裡承諾的、別處根本不存在的行為。另外，模板第 273 行和 dd-init.md 第 124–125 行仍把 SKIP 寫成單純的逃生口，沒提「SKIP 會留欠帳，之後即使沒改程式碼的正常 commit 也會被擋」，也沒提段落開始前要跑 `--start-segment`。
  Evidence：`git grep -n -E 'start-segment|segment-base|dd-segment-base'` 在這 3 檔以外是 0 筆；模板第 247 行是 `git show ... HEAD`。
  建議：同批更新模板 §3.9 的步驟 3、4、8，加上 dd-init Phase 3 第 4 點。如果這段不打算改模板，就把「給迴圈步驟 3、4、8」這句刪掉。

[Important] scripts/check-claude-md.sh:81 和 :136：目錄名稱含非 ASCII 字元時，SKIP 留下的欠帳會被靜默放行，CHANGELOG 說「SKIP 不是豁免」的保證在這種情況下不成立。
  Failure：`git log --name-only` 預設會把非 ASCII 路徑加上引號並跳脫（core.quotePath），所以 `dirname` 拿到的是 `"\344...` 這種字串。第 136 行 `[ ! -d "$d" ] && continue` 把它當成「已刪除的目錄」跳過。實測流程：`--start-segment` → 在 `中文/a.js` 做 SKIP commit → 只改 README 的正常 commit，結果 exit=0，沒有擋。
  Evidence：實驗 A 輸出 `normal commit exit=0`。
  建議：git log 和 git diff 都加上 `-c core.quotePath=false`。不過含空白或換行的路徑仍會被引號包起來，最好改用 `-z`。

[Important] scripts/check-claude-md.sh:88–95：`--start-segment` 判斷欠帳的方式和正常 commit 不一致。正常 commit 會跳過已經整個刪掉的目錄（第 136 行），`--start-segment` 用的是沒過濾的 `owed_dirs`。
  Failure：起點記好後，SKIP 新增 `tmpx/a.js`，接著 `git rm -r tmpx` 做正常 commit，這個 commit 放行（exit 0）。但之後跑 `--start-segment` 會被拒絕（exit 1），要求補 `tmpx/CLAUDE.md`，而那個目錄已經不存在。要解開只能 `rm` 起點檔，或重建目錄。
  Evidence：實驗輸出 `normal commit after deleting dir exit=0`、`start-segment exit=1`，並列出 `tmpx/CLAUDE.md`。
  建議：在 `--start-segment` 分支用同一個 `-d` 條件過濾，或把過濾移進 `owed_dirs`。

What I ran
- `Read diff.txt` 第 1–312 行、第 971 行之後 → 讀完 diff 和整份 gate
- `git grep -n -E 'start-segment|segment-base|dd-segment-base|SKIP_DOC_CHECK'`（排除這 3 個檔）→ 新參數 0 筆；SKIP 的描述在 README 兩份、模板第 273 行、dd-init.md 第 125 行、scripts/CLAUDE.md 第 10 行
- 讀 `scripts/CLAUDE.md`、模板 §3.9 第 225–275 行、dd-init.md 第 118–128 行 → 都沒有段落起點的描述
- 暫存 repo 實驗 A（非 ASCII 目錄的欠帳）→ 正常 commit exit=0，漏擋
- 實驗 B（worktree）→ 起點檔在 `.git/worktrees/wt/dd-segment-base`，和腳本註解「worktree 各自一份」一致
- 實驗 C（SKIP 新增的檔案之後刪掉、目錄還在）→ 擋下。我判斷這是可接受的設計，所以沒報
- 實驗 D（把 HEAD 的改動 apply 到 HEAD~1 後跑 gate）→ exit 1，要求 `scripts/CLAUDE.md`
- `shellcheck -S warning` 檢查 gate → 0 個警告；`/bin/bash`（3.2.57）`-n` → 語法通過
- 從 ci.yml 抽出新增的 step，用 `bash -e` 跑 → exit 0，共 22 個 ✅。CHANGELOG 寫的「22 個情境檢查」和 22 個 `expect` 對得上
- 刪目錄實驗 → 正常 commit exit 0，`--start-segment` exit 1

Not reported
- 非 ASCII 路徑出現在 staged 檔案時，gate 會永遠回報 missing。這是改動前就有的問題，這次只是把同一個跳脫問題帶進新的 owed 路徑，已報在第 3 條。
- 起點不在目前分支歷史裡時，gate 退回只查 staged，會比較寬鬆。CI 情境 7 明確測了這條，也有警告訊息，我判斷是刻意的設計。
- CHANGELOG 寫「記在 `.git/dd-segment-base`」，沒提 worktree 底下的實際路徑不同。屬於措辭層級，沒有失敗情境。
- 起點一直停在空樹時，每個 commit 都會掃整段歷史，有效能疑慮，但沒量測、沒證據。

需要外部查證
- CHANGELOG 的「rental-line 段落 1…4 個沒有 CLAUDE.md 的程式碼目錄」、「13 段裡有 8 段」、「約一小時後才手動補上」：要到 rental-line repo 用新 gate 重算 commit 歷史才能確認，我沒有那份資料。