Critical 2 / Important 2 / Smells 1。審查範圍是快照的 `git diff HEAD~1 HEAD`，共 3 個檔：.github/workflows/ci.yml、CHANGELOG.md、scripts/check-claude-md.sh。

[Critical] diff.txt:209 與 :275（scripts/check-claude-md.sh 的 `owed_dirs` 和主迴圈）：目錄名含非 ASCII 字元時，SKIP 留下的欠帳會被靜默丟掉。
  Failure: git 預設 `core.quotePath=true`，所以 `git log --name-only` 會把 `前端/a.js` 印成 `"\345\211\215\347\253\257/a.js"`。`dirname` 取出的目錄名開頭多了一個引號，`[ ! -d "$d" ] && continue` 把它當成「目錄已刪除」而跳過。結果是：之後只改 README 的正常 commit 會放行，`--start-segment` 也會照常重記起點，欠帳就這樣洗掉了。這正好違反 CHANGELOG 寫的「SKIP 不是豁免」。舊版只看 staged，遇到同樣情況是擋下（只是路徑顯示成亂碼）；新加的 continue 把它變成放行。
  Evidence: 同一組操作（init、--start-segment、SKIP 新增 `前端/a.js`、正常 commit 只改 README）在 `quotePath=true` 時結果是 PASS，在 `quotePath=false` 時是 BLOCK，並列出 `前端/CLAUDE.md`。CI 只用 `src` 當目錄，測不到這個情況。建議 git log 和 diff --cached 都加上 `-c core.quotePath=false`。

[Critical] scripts/check-claude-md.sh 改了，同一個 commit 卻沒有更新 scripts/CLAUDE.md。這違反專案的 gate 規則（根目錄 CLAUDE.md「開發本 repo」寫明改 `.sh` 時同目錄的 CLAUDE.md 要同批更新）。
  Failure: 照本 repo 自己的 dogfood hook，這個 commit 會被擋。scripts/CLAUDE.md:8-10 仍然只描述「staged 變更含程式碼的目錄」，完全沒提 `--start-segment`、`--segment-base` 和 `.git/dd-segment-base`。
  Evidence: `git diff --stat HEAD~1 HEAD` 只有 3 個檔。對 `start-segment|segment-base|dd-segment-base` 跑 `git grep`（排除腳本本身、.github、CHANGELOG），結果是 0 筆。

[Important] CHANGELOG.md diff.txt:120 寫 `--segment-base`「給迴圈步驟 3、4、8 算整段範圍」，但 templates/global/CLAUDE.md 在 HEAD 版完全沒有提到這個參數。
  Failure: 這句話在描述一個不存在的用法。scripts/CLAUDE.md 也規定「gate 的檢查邏輯改動時，同步檢視全域模板 §3.9」，這次沒有同步。
  Evidence: 同上的 `git grep` 回 0 筆。templates/global/CLAUDE.md:273 對 gate 的描述仍是舊的「只看這次 commit」語意。

[Important] diff.txt:75-78 與 :89-96：CI 情境 5 和情境 7 的名稱宣稱了某個行為，斷言卻沒有驗那個行為。
  Failure: 有三處。
  - 變異 M2：把 `--segment-base` 改成印空字串、exit 0。CI 全綠。步驟註解寫的是「不能印空字串給 git diff 吃」，測的卻只有 exit code。
  - 變異 M4：起點失效時，gate 直接 exit 0、完全不查 staged。CI 全綠。原因是情境 7 只 staged 了 README，「只查 staged」的那一半從沒被執行到。
  - 情境 1 的「還沒有 HEAD 也能記起點」和情境 5 的「有起點時印得出來」，換成 HEAD~1 舊版腳本也會過。舊版會忽略參數，在沒有 staged 時 exit 0。
  Evidence: 鑑別力實驗的結果附在下方「What I ran」。

[Smell] diff.txt:65、:71、:85：判 block 的情境（z、n1、auto2）都沒有接 `said`。gate 不管因為什麼原因 exit 非 0（例如「不在 git repo 內」或執行時錯誤），這幾個情境都會判綠。情境 2 的 `said "src"` 比對字串太寬，無法區分是哪一條訊息。另外沒有任何情境涵蓋 merge 和根目錄 `.`（我手動跑過根目錄，會正確擋下）。

What I ran
- 用 awk 從 ci.yml 抽出「gate 段落起點」這一步，用 `bash -e` 在 mktemp 目錄裡跑，GATE 指向 HEAD 版腳本。另外確認過：腳本內容與 diff 檔第二段、快照工作目錄都相同 → 22 個 ✅，exit 0。本機是 macOS bash 3.2.57、git 2.42.0。
- 換成 HEAD~1 版腳本跑同一段 → exit 1。變紅的有：c2 block 與 said "src/CLAUDE.md"、「有欠帳時拒絕重記起點」與 said "src"、Z、「沒有起點時要失敗」、「SKIP 沒有自動記下起點」、auto2、said "不在目前分支的歷史裡"。仍為綠的：「還沒有 HEAD 也能記起點」「有起點時印得出來」「起點失效時只查 staged 並放行」。
- 各變異的結果如下。每個變異都先用 `diff` 確認改動已生效。
  - M1：欠帳結算不照 commit 先後 → 只有 Z 變紅。
  - M2：`--segment-base` 印空字串 → 0 紅。
  - M4：起點失效時直接 exit 0 → 0 紅。
  - M6：刪掉「目錄已刪除就跳過」那一行 → 0 紅。
  - M7：`--start-segment` 不檢查欠帳 → 只有「有欠帳時拒絕重記起點」變紅。
- 非 ASCII 目錄探測 → quotePath=true 時 PASS，quotePath=false 時 BLOCK（見第一條 Critical）。
- 根目錄 `a.js` 用 SKIP 提交後再做正常 commit → BLOCK，列出 `CLAUDE.md`，行為正確。
- worktree：起點寫到 `.git/worktrees/<名稱>/dd-segment-base`，SKIP 後的正常 commit 會被擋，行為正確。
- `shellcheck -S warning` 檢查 HEAD 版腳本 → exit 0。
- 計數：`expect "` 有 22 個，`said` 有 3 個，`[ -f` 有 1 個，斷言共 26 個。

Not reported
- CHANGELOG 寫的「22 個情境檢查」與 expect 的數量一致，所以不報。
- merge commit 不列檔案時的欠帳結算順序，沒有實跑驗證。
- 舊版 staged 路徑同樣有非 ASCII 被加引號的問題，這是既有問題，這次沒動到。

暫存目錄：/var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.dWbC7A6VeK（ci_step.sh、各版本與變異的腳本、*.out）