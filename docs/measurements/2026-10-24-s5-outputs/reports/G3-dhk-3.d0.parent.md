【派工】
共派 4 個審查者（code-reviewer，haiku），在同一則訊息裡平行派出：
- A：`tests/test-gate.sh`、`tests/CLAUDE.md`、`scripts/CLAUDE.md`。看新的「繞過①②③」測試有沒有鑑別力、變異表對不對。
- B：`templates/global/CLAUDE.md`、`verification-gate`、`worktree-manager` 兩份 SKILL.md。看新寫的規則能不能照做、會不會和既有規則打架。
- C：`CHANGELOG.md`、根目錄 `CLAUDE.md`。看條目位置、同步規則（README、dd-loop-rev 這類）。
- D：不分檔，查跨檔一致性（每個識別符都 `git grep` 一次）。

為什麼是 4 個：這次 diff 其實是三類東西（測試＋gate 文件、全域規則與 skill、changelog 與收編清單），而且它們互相引用很多，所以再加一個專查跨檔引用的。4 個全部回來了，不用補派。

【採納】
1. 主（我自己查到；4 個審查者都沒提，B 還判為「無衝突」）｜Important｜新寫的「紅了要對得上它應該怎麼紅（修 bug 時就是那個錯的值）」和 §3.9 的鑑別力測試規則互相矛盾，而且 `verification-gate` 把矛盾寫成了操作步驟。
   - 我的查證：`verification-gate/SKILL.md:36`（diff.txt:1595）的 `git stash -u && <測試>` 就是把修復拿掉、改回舊版再跑，正是 §3.9 說的「鑑別力測試（改回舊版確認會紅）」（diff.txt:2065）。§3.9 明寫「不要斷言某個預期的壞結果」，因為舊碼可能落在第三種狀態，判準是「不等於固定版的輸出」（diff.txt:2065–2068）。
   - 但新文字要求「紅的是原本那個 bug」。§3.5 自己的括號也寫「判定變異版仍照 §3.9」（diff.txt:1896），那 stash 這一步到底照哪條，讀者無從判斷。
   - §3.5 的「新測試第一次跑、修 bug 時就是那個錯的值」也一樣：修 bug 時新測試第一次跑，就是跑在還沒修的舊碼上，等於同一個鑑別力實驗。CHANGELOG 第 25 行重複了這個說法。
   - 會怎麼出錯：舊碼掉進第三種狀態，例如預期回錯的值，結果是丟例外。照新規則，agent 會判定「紅的不對、測試沒抓到」，回頭去改一支其實正常的測試。§3.9 記錄的 2026-10-07 那次就差點這樣。
   - 建議改法：§3.5、`verification-gate:36` 與紅旗、CHANGELOG 三處改成「被測的東西真的跑到了、而且給了錯的結果才算；錯的值不必是你預期的那一個（判準見 §3.9 鑑別力）」，不要再寫「就是那個錯的值」或「紅的是原本那個 bug」。
2. 主｜Smells｜`test-gate.sh:343` 寫「tests/CLAUDE.md 的『恆真斷言』那條」，但 tests/CLAUDE.md 裡的原文是「一個『恆真』的斷言」（`tests/CLAUDE.md:42`）。
   - 我的查證：`git grep -n '恆真' HEAD -- tests/` 的結果，「恆真斷言」這四個字只出現在 test-gate.sh 自己身上，照引號去 grep 找不到被引的那條。
   - 建議改法：引號裡改成原文「一個『恆真』的斷言比沒有斷言更糟」，或拿掉引號。
3. 主｜Smells｜§3.5 新規則把「import 錯、拼錯字」這類紅一律算成「測試自己壞了」，但沒寫新功能該怎麼辦。
   - 我的查證：寫新功能的測試時，第一次紅幾乎一定是「函式不存在」。照 diff.txt:1894–1896 的寫法，這條路沒有任何合格的紅。
   - 建議改法：補一句「新功能還沒寫時，先放一個回錯值的空殼，讓測試跑到斷言」。
4. 主｜Smells｜繞過③ 的對照只證明了一半。
   - 我的查證：test-gate.sh:350–351 那則「rm 之前開下一段也擋」，是被欠帳那一關（:195）擋下並 exit 的，沒有走到 review 那一關（:201）。所以「兩個擋點一起關掉」裡的 review 那一半，沒有任何「同一個狀態、只差 rm」的對照。目前只有變異 2 間接釘住它。
   - 建議改法：要嘛補一則「欠帳結清之後、rm 之前，開下一段會被 review 擋」的對照，要嘛把說明改成只宣稱欠帳那一關。

【駁回】
- D｜`verification-gate` 引用的「0 紅的第一個嫌疑人永遠是實驗本身」和模板原文對不上｜不是這次 diff 引入的：那行在 diff 裡是沒有 `+` 的上下文行（diff.txt:98），`git show HEAD~1:skills/verification-gate/SKILL.md` 第 56 行本來就這樣寫。內容屬實，可以另外修，但不擋這一段。
- B｜「§3.5 和 §3.9 不衝突、stash 那行與紅旗一致」｜駁回，理由見採納 1：stash 那步就是改回舊版的實驗，§3.9 對這種實驗明文禁止斷言某個預期的壞結果。
- A、C 都是 0 發現。A 的變異結論我已經用 gate 原始碼對過，採納為佐證：
  - 變異 1 會讓 pre-commit 在 review 區塊裡，只要範圍內沒有新報告就擋（`check-claude-md.sh:159–187`、`:238`）。
  - 變異 2 擋下之後，下一則 README commit 因為讀不到起點檔，欠帳是空的，照樣放行（`:241–242`），所以只紅 1 則。
  - 變異 3 把起點改成空樹，`owed_dirs` 會掃整段歷史（`:113–114`），所以 by5 會被擋。
  - 三條都符合 `scripts/CLAUDE.md` 的變異表。
  - 注意：這三個變異只有 A 實跑過（它的數字是 84 / 104 / 104 ✅），我只對了原始碼、沒有重跑。另外 A 也重跑了 test-gate.sh，得到同樣的 105 ✅，這一步多跑了。

【需使用者決定】
無。採納 1 該選哪邊，模板已經寫明（改回舊版的實驗照 §3.9），所以不是語意不明，是新文字沒照模板寫。

【需要外部查證】
- `git worktree remove` 在 git 2.42.0 與 2.54.0 的行為：遇到 ` M`、`A `、`??` 會拒絕；被 gitignore 的檔會不提示就直接刪；加 `--force` 會全部一起刪。另外 zh_TW 的拒絕訊息是不是「包含修改或未追蹤的檔案，使用 --force 刪除」。
- pstack-claude 的歸屬與描述是否屬實：repo 是否就是 `michael-denyer/pstack-claude`；`tdd`、`reflect`、`poteto-mode`、`worktree-cleanup` playbook 的內容；SessionStart hook 是否在 startup、resume、clear、compact 都觸發，並注入 `<EXTREMELY_IMPORTANT>`、要求叫 `pstack:poteto-mode`。
- 根目錄 CLAUDE.md 規定「只借概念也要處理授權」。這次借了 pstack-claude 三處概念（tdd、reflect、worktree-cleanup），有沒有需要的歸屬檔，要看對方的 LICENSE 才知道。

【結論】
Critical 0 / Important 1 / Smells 3（採納數）。Important 那條要修掉才能往下走。我沒有改任何檔、也沒有 commit。