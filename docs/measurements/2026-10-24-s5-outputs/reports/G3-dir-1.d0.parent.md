四個審查者都已回來，下面是查證後的結果。全程沒有改檔，也沒有 commit。

**【派工】**
派了 4 個 code-reviewer，在同一則訊息裡平行派出。
- **A**：`tests/test-gate.sh` 新區塊、`tests/CLAUDE.md`、`scripts/CLAUDE.md`。
- **B**：全域模板 §3.5、verification-gate、worktree-manager。
- **C**：根 CLAUDE.md、CHANGELOG，以及跨檔一致性。
- **D**：不分檔，從頭到尾通讀整份 diff。

為什麼是 4 個：專案的對照實驗顯示，單發只命中隨機的一部分。前 3 個按檔案方向分，讓每塊都有人專看；第 4 個通讀全文，專抓跨檔矛盾，也讓前 3 個的重點區有第二個人看到。結果確實有重疊：A 與 D 各自抓到同一個測試缺口；B、C、D 加上我自己，四方各自抓到同一個規則矛盾。

**【採納】**

1. B／C／D（我讀 diff 時也獨立發現）｜**Important**｜新的「先紅要對得上那個錯的值」與 §3.9 的鑑別力規則互相矛盾。
   - 查證：
     - 修 bug 時，新測試第一次跑本來就是跑在舊碼上。verification-gate 的 `git stash -u && <測試>` 也是同一件事：把修復藏起來重跑。
     - 這正是 §3.9 說的「改回舊版確認會紅」。§3.9 明寫不要斷言某個預期的壞結果，只要不等於固定版的輸出就算紅，並記了 2026-10-07 舊碼掉進「第三種狀態」的實例（diff.txt 2065–2068）。
     - 新條文要求「修 bug 時就是那個錯的值」（diff.txt 142–144、91、99–101）。照它判，會把一則有鑑別力的測試判成「紅錯了」，然後回頭去改它。
     - §3.5 括號裡的「這條管新測試第一次跑」擋不住這個情況，因為兩者在修 bug 時是同一個動作。
   - 改法：
     - 判準改成「被測的東西真的跑到了、而且給了錯的結果才算；錯的值不必是你預期的那一個」。
     - 新功能還沒寫時，先放一個回錯值的空殼，讓測試跑到斷言再判。
     - 同批改 §3.5、verification-gate 第 36 行與第 58 行、CHANGELOG 第 25 行。

2. A／D｜**Important**｜「繞過①」那則特性測試本身沒有鑑別力；`scripts/CLAUDE.md` 變異表說它是「具名的那一則」，這句不成立。
   - 查證：
     - `by1` 是 `--start-segment` 記下 by0 之後的第一個 commit。pre-commit 跑時 HEAD 還是 by0。
     - `check-claude-md.sh:165` 的 `[ "$base" = "$head_sha" ] && return 1` 會直接放行。所以就算 pre-commit 真的開始查報告，這一則也擋不到。
     - A 與 D 各自實跑：把變異改成不連鎖的版本後，繞過① 維持 ✅。照文件寫的變異跑時它會紅，但只是因為 r0 被擋之後一路連鎖失敗。
   - 改法：起點之後先放一個零報告的 commit，把具名斷言改放在第二個（base ≠ HEAD）commit 上。在沒有連鎖的狀態下重驗一次變異，再改變異表那一列。

3. B｜**Important**｜§3.5 的括號把變異版的判定交給 §3.9，並摘成「不等於固定版的輸出就算紅」。但 §3.9 那條沒有排除「載入失敗、import 壞掉」。
   - 查證：§3.9:367–370 只補了「有牙不證明該發生、清單不證明是全的」兩句，沒有任何擋假紅的條件。這次說要「補上假紅」，可是在變異實驗這條路上整個沒堵到。
   - 改法：§3.9 鑑別力那條補一句：「不等於」必須來自被測物給了錯的結果；變異讓檔案載入不了、import 壞掉、測試資料建不起來都不算（見 §3.5）。

4. B｜**Smells**（B 標 Important）｜修復與新測試都還沒 commit 時，`git stash -u` 會連測試一起藏起來。這時紅的是「找不到測試」，新加的「紅的是原本那個 bug」照字面做不到。
   - 查證：verification-gate:36、:44–45 只處理了「修復已經 commit」的情況。
   - 降級理由：這是 stash 模式本來就有的問題，舊寫法在這種情況會得到假的 PASS。新條文沒有讓結果變糟，只是把問題暴露出來。這次 diff 改的正是這一行，值得同批修。
   - 改法：改成只藏修復的檔：`git stash push -u -- <修復的路徑>`，或寫明新測試要先單獨 commit。

5. C（B 列在 Not reported，我也查到）｜**Smells**（C 標 Important）｜worktree-manager 沒有寫出處。
   - 查證：`git grep pstack` 只命中 CHANGELOG、根 CLAUDE.md:335/337、verification-gate:9。CHANGELOG:39 寫了「借鑑 pstack-claude 的 worktree-cleanup playbook」，SKILL.md 本體沒寫。同批的 verification-gate 與既有的 design-brainstorm 都在第 9 行寫了一行借鑑說明。
   - 降級理由：不影響行為。只借概念的前例（design-brainstorm）就是一行出處，沒有附 LICENSE，所以修起來是一行字。
   - 改法：在 SKILL.md「收尾」那節補一行借鑑說明。根 CLAUDE.md:333 那段，CHANGELOG 說寫法借鑑 `reflect` 與 `poteto-mode`，要不要在正文補出處，可一併考慮。

**【駁回】**
- 我自己、A、C、D｜繞過③ 的對照只斷言了欠帳那個擋點，沒斷言 review 那個擋點在 rm 之前也會擋。不採納：從 `by3..by4` 範圍沒有新增報告推得出那個擋點確實開著。只要有變異讓 `reviews_missing` 在沒有起點檔時改成擋，「rm 掉起點檔，開下一段放行」那一則就會紅，所以「一起關掉」有被釘住。
- C｜`tests/CLAUDE.md:20` 寫「第 153 行」，但 `staged=` 現在在第 238 行；還有 `scripts/CLAUDE.md` 的「前 61 項」、`test-gate.sh:228/406` 寫死的「61 項」「90 項」。不採納為本次發現：都是既有問題，不在這次 diff 的 hunk 裡。但 `tests/CLAUDE.md` 這次有改，那個過期行號就在改動處上方幾行，照 §3.10 可以順手修。
- D｜使用者的全域 gitignore 若忽略 `WORKTREE_INFO.md`，它會出現在 `!!` 而不是 `??`。不採納：沒有具體會發生的證據，屬於邊角情況。
- 我自己｜`scripts/CLAUDE.md` 新表格放在清單項目裡、後面緊接清單行，擔心渲染出錯。不採納：表格前有空行，縮排 6 格，對到「- ⚠️⚠️」那項的內容縮排，在 GFM 下屬於該清單項；儲存格裡也沒有 `|`。

**【需使用者決定】**
無。第 1、3 條「哪個才是預期」，§3.9 已經寫明，不屬於無從判定。

**【需要外部查證】**
- pstack-claude 的 SessionStart hook 是否在 startup、resume、clear、compact 四種情況都觸發，`pstack:poteto-mode` 這個名稱對不對（根 CLAUDE.md:335–337）。要讀上游的 hooks.json。
- pstack-claude 的 LICENSE 是否相容。只借概念時，專案規則仍要求處理授權。
- `git worktree remove` 的拒絕訊息原文，以及「被 gitignore 的檔會跟著目錄直接刪掉、不提示」，在 git 2.42.0 與 2.54.0 下是否屬實（worktree-manager:31–34）。沒有人在本輪實跑過。

**【結論】** 採納 Critical 0 / Important 3 / Smells 2。

另外，審查者 A 與 D 跑變異實驗時留下了拋棄式目錄 `/tmp/revA.9UL7` 與 `/tmp/revD.anan`，沒有刪，要不要清由你決定。