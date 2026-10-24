Critical 0 / Important 4 / Smells 0。審查範圍：快照 `git diff HEAD~1 HEAD`，重點看 templates/global/CLAUDE.md §3.5、skills/verification-gate/SKILL.md、skills/worktree-manager/SKILL.md。

[Important] skills/verification-gate/SKILL.md:36、:57-59（diff 91、99-101）：新規則要舊碼紅出「原本那個錯的值」。§3.9 的鑑別力規則明文禁止這樣判。
  Failure：修 bug 後跑 `git stash -u && <測試>`，舊碼沒停在預期的錯值，掉進第三種狀態（例如 throw）。照新紅旗會判「紅的不是原本那個 bug」，結論是測試沒用。這正是 templates/global/CLAUDE.md:364-367 記的 2026-10-07 誤判。另外，紅旗寫「判準見全域 §3.5」，可是 §3.5:195 自己說它只管「新測試第一次跑」，變異版要照 §3.9。stash 把修復藏起來重跑，就是 §3.9:364 定義的「改回舊版確認會紅」，所以這處引用指錯了節。
  Evidence：SKILL.md:36「紅的是原本那個 bug」、:58「修 bug 時就是那個錯的值」；template:364「不要斷言某個預期的壞結果」、:367「不等於它就算紅」；template:195 的括號。
  建議：紅旗與 :36 改指 §3.9 鑑別力那條，例如寫成「被測的東西真的跑到、給了不同於修復版的結果」，不要求一定是預期的那個錯值。CHANGELOG:25 的同一句一起改。

[Important] templates/global/CLAUDE.md:194（diff 143）：§3.5 把「修 bug 時就是那個錯的值」當成判準，在修 bug 的情境下跟 §3.9:364-366 撞在一起。
  Failure：修 bug 時新測試第一次跑，對象就是舊碼（有 bug 的那份）。舊碼掉進第三種狀態時，照 §3.5 會判成「測試自己壞了」，回頭去改一則其實正常的測試。新功能的情境也沒交代：函式還不存在時，紅的內容必然是「找不到」。按字面這算「import 寫錯」那類，等於永遠無法合格；不算的話，又沒說什麼紅才算。
  Evidence：template:193-195 只舉了「預期 3、實際 2」一個樣子，沒處理第三種狀態，也沒處理新功能的情況。
  建議：錯的值不必是預期那一個，只要是被測物真的跑到後給出的錯結果就算。新功能先放一個回錯值的空殼，讓測試跑到斷言再判。

[Important] templates/global/CLAUDE.md:195（diff 144）：§3.5 的括號把假紅的判定整個交給 §3.9，並把 §3.9 摘成「不等於固定版的輸出就算紅」。可是 §3.9:364-370 沒有任何擋假紅的條件。
  Failure：做變異或改回舊版的實驗時，如果是變異讓檔案 import 失敗、或測試資料沒建好，輸出也「不等於」固定版。照括號這就算紅、算有鑑別力。這次要堵的假紅，在變異實驗這條路上整個沒堵到。
  Evidence：template:367「變異版只要「不等於它」就算紅」，後面 :368-370 只補了「有牙不證明該發生、清單不證明是全的」，沒有排除載入失敗。
  建議：在 §3.9:367 後面補一句：「不等於」必須來自被測物給了錯的結果，載入失敗、import 壞掉不算（見 §3.5）。

[Important] skills/verification-gate/SKILL.md:36：stash 模式碰到「修復和新測試都還沒 commit」這個常見情況時，新加的條件根本做不到。
  Failure：§3.5:192 規定修 bug 時要新增測試。測試檔還沒 commit 時，`git stash -u` 會把修復和測試一起藏起來。如果測試是新檔，就跑不到這個檔（紅的是「找不到」）；如果改在既有的測試檔裡，就只剩舊測試，結果是全綠。兩種都不是「紅的是原本那個 bug」，照這行做的人無路可走。舊寫法只寫「看到失敗」，會把前一種當成通過；新加的條件把矛盾變得明顯，卻沒給出路。
  Evidence：SKILL.md:36 的模式本身；:44-45 只處理「已經 commit」的情況。git stash 會同時收已追蹤的修改和 `-u` 收的未追蹤檔，這是通用知識，我沒有在本輪實跑。
  建議：改成只藏修復的檔，例如 `git stash push -u -- <修復的路徑>`；或者寫明測試要先單獨 commit。

What I ran
- 用 Read 分段讀 diff.txt：1-300、1885-1904、2062-2081，以及 Grep 找出各檔整檔內容的起始行 → 拿到 diff 本體、§3.5 與 §3.9 的整檔內容
- `cat skills/worktree-manager/SKILL.md; sed -n 1,80p skills/verification-gate/SKILL.md` → 讀到兩份 skill 的現行內容
- `git grep -n -E '確認會失敗|先寫失敗|假紅|failing test|看到失敗'`（排除 CHANGELOG）→ 只在 verification-gate:9、36、57 和 template:181、183、193 出現；commands/dd-init.md 沒命中，所以這次改 §3.5 不必跳 dd-loop-rev
- `git grep -n -E 'worktree remove|--ignored|WORKTREE_INFO'` → 只在 CHANGELOG 與 worktree-manager 內，沒有別處的同一宣稱要跟著改
- `git grep -n 'stash -u'` → 只在 verification-gate:36、41
- `git grep -n -i -E 'superpowers|pstack'` 加 `ls skills/verification-gate skills/worktree-manager` → 借鑑都寫在行內（design-brainstorm 也是這個寫法），兩個 skill 目錄裡都只有 SKILL.md

Not reported：
- worktree-manager 沒有像 verification-gate:9 那樣標出借鑑 pstack-claude 的 worktree-cleanup playbook（出處只寫在 CHANGELOG:39）。根 CLAUDE.md 要求「只借概念時授權仍要處理」，但我手上沒有失敗情境。pstack-claude 的授權沒查，查法是看該 repo 的 LICENSE，能確定借了要不要附授權。
- worktree-manager:31 引用的 git 錯誤訊息原文，和「被 ignore 的檔會被直接刪掉」的行為，要用 git 2.42/2.54 實跑才能核對，我沒有跑。以通用知識看，兩點都和 git 原始碼一致。
- worktree-manager:38 寫 WORKTREE_INFO.md 只記「分支、路徑與基線結果」，比步驟 6 少了 base，太小不報。
- scripts/CLAUDE.md 新表格和 tests/test-gate.sh 新區塊不在我的重點方向，只確認了 Markdown 結構（表格前有空行、儲存格裡沒有 `|`）。
- 已確認的 test-gate 105 ✅、shellcheck、CI lint 都沒有重跑。