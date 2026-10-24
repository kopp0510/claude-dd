三位審查者都回來了，每條發現我都讀過程式碼或重跑過。結論是 Critical 0、Important 4、Smells 1，最大的問題是新寫的「假紅」規則和同一份模板的 §3.9 互相矛盾。全程沒有改任何檔、沒有 commit；變異實驗都在 `/tmp/mutG3.aS32` 這個拋棄式目錄裡跑。

【派工】
派了 3 個 `code-reviewer`，三個都審整段 diff，各自有一個主攻方向：
- **A**：`tests/test-gate.sh` 新區塊跟 gate 的關係，看新測試是不是空通過、改壞 gate 會不會紅、`set -e` 陷阱。
- **B**：`verification-gate`、`worktree-manager` 和全域模板 §3.5 的文案。
- **C**：跨檔一致性，包括 CHANGELOG、各份 CLAUDE.md 引用別處的說法、識別符 grep、§3.10 的寫作判準。

只派 3 個：diff 只有 124 行，正好分成三塊。讓三個都看全部、只是重點不同，是因為單一審查者每次只會挖到一部分，範圍重疊才補得起來。

【採納】
1. **A｜Important｜「繞過①」那則測試抓不到它自己點名的變異**
   - 查證：check-claude-md.sh:165 有一行 `[ "$base" = "$head_sha" ] && return 1`（起點等於 HEAD 就不擋）。test-gate.sh 在 by1 之前剛跑完 `--start-segment`，起點就等於 HEAD，所以就算 pre-commit 也查報告，by1 照樣放行。
   - 我自己重跑了一次：讓「pre-commit 也查報告」的變異從繞過①那一刻才生效，結果 `✅ 繞過①:段落內零報告的正常 commit 放行` 還是綠的，紅的全落在 by2 以後。
   - 照文件寫法從頭就生效時它確實會紅，但那是前面那串連鎖失敗留下的壞狀態造成的，不是它自己的斷言在抓。所以 `scripts/CLAUDE.md` 變異表第一列說它是「具名的那一則」，不成立。
   - 建議改法：by1 之前先在同一段多做一個 commit，讓起點不等於 HEAD，再斷言；變異表那一列跟著改。
2. **B/C 都報（我也獨立發現）｜Important｜§3.5 新規則跟 §3.9 鑑別力那條矛盾**
   - 查證：templates/global/CLAUDE.md:193-195 要求紅要「對得上它應該怎麼紅」，修 bug 時就是那個錯的值。
   - 但 :364-367 寫「不要斷言某個預期的壞結果」，舊碼可能掉進第三種狀態。
   - 修 bug 時新測試第一次就是跑在舊碼上，正好落在 §3.9 那個情境。
   - :195 括號裡寫的「不等於固定版就算紅」又把變異版整個排除在「假紅」檢查之外。變異讓檔案載入失敗時也是「不等於」，於是被算成抓到了。
   - verification-gate SKILL.md:36 寫 stash 後「紅的是原本那個 bug」，:57-59 的紅旗也是同一個口徑。照它走的 agent 會把有鑑別力的紅判成無效，回頭去改一個正常的測試，正是 §3.9 記下的那次事故。
   - 建議改法：判準改成「被測的東西真的跑到了、而且給了錯的結果」，錯的值不必是預期的那一個。變異版的「不等於」也加上同一個限定。SKILL.md:36、:58 和 CHANGELOG:23-26 照同一個口徑改。
3. **B｜Important｜§3.5 沒交代新功能的測試第一次跑時怎麼判**
   - 查證：:193-195 只講修 bug 的情況。新功能還沒寫時，第一次紅一定是「找不到函式」，長得跟它點名的「拼錯字」一樣。照字面，agent 不是永遠拿不到合格的紅，就是把沒跑到斷言的紅當成合格放行。
   - 建議改法：寫明先放一個回錯值的空殼，讓測試真的跑到斷言。
4. **B/C 都報｜Important｜worktree-manager 借了 pstack-claude 的概念，skill 本體卻沒寫出處**
   - 查證：`git grep -i pstack` 只在 CHANGELOG.md:39 有 worktree-manager 的出處，skill 本身零命中。根目錄 CLAUDE.md:353 寫「只借概念時授權仍要處理，歸屬精確到段落」；同一批的 verification-gate:9 有補，design-brainstorm:9 也是這樣寫。
   - 模板 §3.5 同樣借了 pstack-claude 的 `tdd`，也沒標出處。
   - 建議改法：在 worktree-manager 的 `## 收尾` 補一行出處，範圍寫到收尾步驟 1；模板 §3.5 要不要標，見下面「需使用者決定」第 1 題。
5. **B｜Smells（從 Important 降級）｜worktree-manager 判斷 `.env` 有沒有改過的方式可能讓 agent 把內容印出來**
   - 查證：SKILL.md:35-36 只寫「跟 `.env.example` 不一樣就是改過」，沒說怎麼比；模板 §3.7 規定 `.env` 不輸出值。
   - 降級理由：skill 沒有叫 agent 跑 `diff`，要 agent 自己選了印內容的比法才會出事。
   - 建議改法：明寫用 `cmp -s .env .env.example`，只看 exit code。

【駁回】
- **A／C 列為既有問題的寫死數字和過期註解**：`tests/CLAUDE.md:20` 的「第 153 行」、`test-gate.sh:406` 的「90 項」、`:420` 的「上面那行 `rm -rf`」。我查過，這幾行都不在本次 diff 裡（diff 對「153」的命中是 0），本次也沒有把同樣的錯寫法複製進新程式碼。這次不採納，另外記成待清的舊債。
- **變異表第 2、3 列**：A、C 和我各自實跑，結果一致：兩列各只紅一則，紅的就是表上寫的那一則；判定行數都是 105，跟固定版一樣。宣稱成立，不構成發現。

【需使用者決定】
1. **模板 §3.5 要不要也標 pstack-claude 的出處？** 全域模板目前沒有任何一處「借鑑」行的前例。
   - A：在 §3.5 補出處。
   - B：模板不標，只留在 CHANGELOG。
   - 建議 B：模板是規則文件、不是 skill，出處留在 CHANGELOG 加 verification-gate:9 就夠了。worktree-manager 則照第 4 條補上。

【需要外部查證】
- pstack-claude 的 LICENSE，以及擁有者是不是 `michael-denyer`。結果決定出處要怎麼寫。
- 根目錄 CLAUDE.md:335-337 說它的 SessionStart hook 在 startup、resume、clear、compact 都會觸發並注入 `<EXTREMELY_IMPORTANT>`；CHANGELOG:29-30 說寫法借鑑它的 `reflect` 和 `poteto-mode`。這兩處要讀上游 repo 確認。
- worktree-manager 說「git 2.42.0 與 2.54.0 實測」以及 `worktree remove` 拒絕訊息的原文，要在兩個 git 版本實跑才能確認。
- verification-gate 這次改寫有沒有照根目錄 CLAUDE.md「新增 Skill 步驟 3」做乾跑（那條寫「新增或改寫都要」）。CHANGELOG 只看得到 worktree-manager 的乾跑紀錄。

【結論】Critical 0 / Important 4 / Smells 1（採納數）