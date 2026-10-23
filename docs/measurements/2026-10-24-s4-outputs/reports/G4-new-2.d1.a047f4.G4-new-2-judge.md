我派了 4 個審查者，全部有回來。採納 Critical 1、Important 7、Smells 3。最嚴重的一條是這個 commit 改了 gate 腳本，卻沒同批更新 `scripts/CLAUDE.md`。依任務說明我沒有改檔、沒有 commit，所以 4 份審查者報告的完整原文沒有落地成檔案，要原文得用下面的 agentId 向各審查者索取。

【派工】
派 4 個，各攻一個方向，因為這次 diff 同時有新邏輯、新 CI 測試、文件宣稱三類東西，再加上腳本必須在 macOS bash 3.2 與 worktree 下跑，多一個專看環境的方向。

- A（agentId a2b4c0dc2d2faab06）：`owed_dirs` 欠帳結算邏輯，涵蓋 merge、rename、多份 CLAUDE.md、空樹起點、起點檔損毀。
- B（agentId a652e39b17d7f4bbd）：CI 新步驟有沒有鑑別力，做了變異實驗。
- C（agentId a389ed5a785c2aa7d）：文件與宣稱的一致性，對 diff 動到的識別符做全 repo `git grep`。
- D（agentId a4d5701cf86173c67）：可攜性與執行環境，涵蓋 bash 3.2、shellcheck、worktree、rebase、SHA-256 repo、效能。

【採納】
1. A/B/C｜Critical｜這次改了 `scripts/check-claude-md.sh`，同一個 commit 卻沒動 `scripts/CLAUDE.md`。根目錄 CLAUDE.md「開發本 repo」規定改 `.sh` 時同目錄的 CLAUDE.md 要同批更新。
   - 查證：`git diff --stat HEAD~1 HEAD` 只有 3 檔；`scripts/CLAUDE.md:8-11` 仍只寫「staged 含程式碼的目錄…同批 staged」，第 21 行還要求同步檢視模板 §3.9。
   - 改法：`scripts/CLAUDE.md` 補上段落起點、欠帳結算、`--start-segment`、`--segment-base`、`.git/dd-segment-base`（每個 worktree 各一份）。
2. C/B｜Important｜CHANGELOG 和腳本檔頭說 `--segment-base`「給迴圈步驟 3、4、8 算整段範圍」，但被引用的那些地方沒有一處用到它，屬於「在註解裡承諾別處的行為」。
   - 查證：在 diff 那 3 檔之外 `git grep -e segment-base -e start-segment` 回 0 筆（exit=1）。
   - 連帶後果：沒有任何文件教使用者在段落開始前跑 `--start-segment`，起點只能靠第一個 SKIP 自動補記，落在段落中間。
   - 改法：同批更新 `templates/global/CLAUDE.md` §3.9 與 `commands/dd-init.md` 的步驟 3、4、8 範圍指令，或刪掉這句宣稱。
3. C｜Important｜好幾份文件寫「只改 markdown 不會被擋」，有欠帳時這句已不成立，因為主流程只在 `staged_dirs` 和 `owed` 都為空時才放行（diff.txt:258），CI 的 c2 情境也預期擋下。
   - 查證：`README.md:137,158`、`README.zh-TW.md:142,169`、`templates/global/CLAUDE.md:271`、`commands/dd-init.md:145`。
   - 改法：兩份 README 同批改，加上「有欠帳時例外」。
4. C｜Important｜其他描述 gate 的文件仍停在「只看這次 staged」：`templates/global/CLAUDE.md:273`、README 兩份、`commands/dd-init.md:124-125`、根目錄 `CLAUDE.md:93`、`DD_PIPELINE_ARCHITECTURE.md:96-97`（行號取自 C 的 grep，我只抽查了 2 和 3 那兩組）。
   - 後果：被擋的人照模板「比對本次變更」去修，會發現這次 staged 根本沒有程式碼。
   - 改法：加一句「SKIP 不是豁免，起點以來的欠帳會追討；看 `git diff <起點> -- <目錄>`」。
5. A/B/D｜Important｜目錄名含非 ASCII 字元時，SKIP 留下的欠帳會被靜默放過。原因是 git 預設 `core.quotePath=true`，`git log --name-only` 把路徑印成帶引號的八進位，結尾是 `"`，比對不到副檔名。
   - 我自己實跑：新版先 `--start-segment`，再 SKIP 新增 `前端/a.js`，之後只改 README 的正常 commit 回 exit=0；直接 staged `前端/b.js` 也是 exit=0。
   - 調級說明：B 說「舊版會擋、新版變放行」，但我跑 HEAD~1 舊版，staged 非 ASCII 目錄同樣 exit=0。所以這是既有 bug 被複製進新的欠帳路徑，不是新回歸，維持 Important、不升 Critical。
   - 改法：`git log` 和 `git diff --cached` 都加 `-c core.quotePath=false`（模板 §3.9 步驟 8 本來就這樣寫）。
6. A｜Important｜起點檔存在、但指向不存在的物件時（例如改寫歷史後被 gc），主流程那行 `read_base && owed=$(owed_dirs)` 什麼都不印就放行；`--segment-base` 還回報「還沒記段落起點」。這是把「讀不懂」說成「確定沒有」，違反專案「不確定就說不確定」的鐵則。
   - 查證：讀碼確認（diff 檔整檔 123、102-107 行）。
   - 我的實跑補充：損毀之後的下一個 SKIP 會靜默覆寫起點，所以只有損毀之前的欠帳會丟失。
   - 改法：起點檔存在但讀不懂時另印警告，`--segment-base` 給不同的錯誤訊息。
7. D｜Important｜`owed_dirs` 每個 commit 要開十幾個子程序，而範圍是「起點到 HEAD」。起點一旦由 SKIP 自動記下，就沒有任何文件叫人往前推（見第 2 條）。
   - D 的實測：1000 個 commit 時每次 pre-commit 要 10.5 秒。我只讀碼確認了每個 commit 跑一串 pipeline，沒重跑量測。
   - 改法：每個 commit 改用單一 awk 結算，或限制範圍。
8. B｜Important｜CI 有兩個情境的斷言沒驗到它名稱宣稱的行為。
   - 情境 5 只驗 exit code：B 把 `--segment-base` 改成印空字串、exit 0，0 紅。
   - 情境 7 只 staged 了 README：B 把「起點失效直接 exit 0、完全不查 staged」寫進去，0 紅。
   - 查證：讀 diff.txt:75-78、89-96 確認。
   - 改法：情境 5 斷言輸出非空且等於起點檔內容；情境 7 改成 staged 一個缺 CLAUDE.md 的程式碼目錄，預期擋下。
9. B｜Smells｜判 block 的情境（z、n1、auto2）沒接 `said`，gate 因為任何原因 exit 非 0 都會判綠；情境 2 的 `said "src"` 比對字串太寬。
10. A｜Smells（從 Important 調降，觸發條件罕見：merge 本身帶進新的程式碼目錄又用 SKIP）｜`git log --name-only` 不帶 `-m` 時，merge commit 不列檔案，merge commit 自己帶進的改動不會記成欠帳。側分支上的 SKIP commit 被 merge 回來則仍會被擋（D 實跑確認）。
11. A｜Smells（從 Important 調降，要先在空 repo 記起點再拉進既有歷史才會觸發）｜空樹起點用 `range=HEAD`，會把之後拉進來的整段歷史都算成欠帳。

【駁回】
- B 說非 ASCII 情況「舊版會擋、新版變放行，屬回歸」：我實跑舊版也是 exit=0，所以只有回歸這個框架被駁回，問題本身照第 5 條採納為 Important。
- C 說 CHANGELOG 寫的 `.git/dd-segment-base` 在 worktree 下路徑不精確：腳本檔頭第 8 行已寫「worktree 各自一份」，差異輕微，不報。

【需使用者決定】
1. 起點失效時要放行還是擋下（D 的 rebase 情境）。起點是還沒 push 的本地 commit，跑 `git pull --rebase` 後它就不在目前分支的歷史裡，欠帳整筆作廢，只印 stderr 警告就放行。CI 情境 7 明確預期放行，但全域模板 §3.10 規定「閘門類的輸入模稜兩可時一律 fail-closed」，兩者衝突。
   - A) 維持放行加警告（現行）
   - B) 改成擋下，要求重記起點，或改用起點與 HEAD 的 merge-base 繼續追
   - C) 維持放行，但把這個盲點寫進文件
   - 建議：B，改用 merge-base 追查，追不到才擋。
2. 沒經過 gate 的 commit 要不要算欠帳（A 的情境）。merge 或 pull 進隊友沒裝 gate 的 commit，也會被算成欠帳，訊息還斷言「跳過檢查」（diff.txt:285），而且有欠帳時 `--start-segment` 拒絕重記。
   - A) 照算，只把訊息改成「起點之後有 commit 改了程式碼、CLAUDE.md 沒跟上」
   - B) 只算作者是自己的 commit
   - 建議：A。訊息措辭不論選哪個都要改，因為「跳過檢查」這個斷言本身不成立。

【需要外部查證】
- CHANGELOG 與 CI 註解提到的 rental-line 數字：「`backend/src` 等 4 個目錄」、「13 段裡 8 段」、「約一小時後才手動補上」、「2026-09-11」。快照裡沒有 rental-line 的歷史，要拿該 repo 的 `git log --name-only` 照新規則重算才能核。
- 「CI 新增 22 個情境檢查」不需外查：B、C、D 都數到 22 個 `expect`，屬實。
- `git rebase --continue` 會不會觸發 pre-commit，沒有人實測。

【結論】採納 Critical 1 / Important 7 / Smells 3