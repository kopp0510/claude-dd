Critical 0 / Important 3 / Smells 0。審查範圍：快照的 `git diff HEAD~1 HEAD`，共 8 檔；被改到的檔讀的是 diff 檔裡的那一份。

[Important] skills/verification-gate/SKILL.md:36、:58 這條新紅旗要求「紅的是原本那個 bug」，和全域模板 §3.9 的鑑別力測試正面衝突
  Failure: 修 bug 時用 `git stash -u && <測試>` 把修復藏起來重跑，這就是 §3.9 定義的「改回舊版確認會紅」。§3.9:364–367 明寫「不要斷言某個預期的壞結果」，舊碼可能掉進第三種狀態 C。照 SKILL.md:36「紅的是原本那個 bug」和 :58「修 bug 時就是那個錯的值」去判，會把一則有鑑別力的測試判成「測試自己壞了」，然後回頭去改一個正常的測試，也就是 §3.9 記錄過、差點發生的那個錯。§3.5:193–194 新增的那句也有同樣的問題：修 bug 的新測試第一次跑時，對象本來就是舊碼。
  Evidence: diff 檔 1595 行（SKILL.md:36）、1617–1618 行（:57–58）；diff 檔模板段 §3.5:193–195 與 §3.9:364–367。CHANGELOG 未發布條目（diff 檔 16 行）也寫「修 bug 時就是那個錯的值」。
  建議改法：§3.5 和 SKILL.md 都改成「紅的原因要來自被測物給了錯的結果，錯的值不必是你預期的那一個」，SKILL.md:36 改為指向 §3.9。

[Important] templates/global/CLAUDE.md:195 的括號把判定變異版的工作交給 §3.9 的「不等於固定版的輸出就算紅」，等於讓變異版不受這次新規則管
  Failure: 這次要擋的假紅（import 寫錯、資料沒建好）一樣會讓變異版的輸出「不等於固定版」。照這個括號判，變異版載入失敗也算抓到，這次補的「讀紅的內容」在變異測試上不生效。§3.9:364–370 本身沒有「不等於要來自被測物」這個限定。
  Evidence: diff 檔 144 行 / 模板 :195「判定變異版有沒有被抓到仍照 §3.9 鑑別力測試那條:不等於固定版的輸出就算紅」；§3.9:367「變異版只要『不等於它』就算紅」，後面沒有排除條件。CHANGELOG:17 照抄了這個說法。
  建議改法：在 §3.9 那條補一句「不等於要來自被測的東西給了錯的結果，載入失敗、import 壞掉不算」，§3.5 的括號再指向它。

[Important] skills/worktree-manager/SKILL.md:9 缺少借鑑出處，CHANGELOG 卻寫明這段借鑑了 pstack-claude
  Failure: CHANGELOG:30 寫「借鑑 pstack-claude 的 worktree-cleanup playbook」。根目錄 CLAUDE.md「只借概念、不抄檔案時…授權仍要處理：歸屬範圍精確到段落」要求標出處，而同一批的 verification-gate:9 有補「『假紅』那條紅旗借鑑 … `tdd`」，worktree-manager 整檔一句都沒有，屬於不足歸屬。根目錄 CLAUDE.md:333–337 的收編總則也一樣：CHANGELOG:20–21 說寫法借鑑了 `reflect` 和 `poteto-mode`，正文沒有標。
  Evidence: `git grep -n 'pstack\|借鑑'` 只命中 verification-gate:9 與 CLAUDE.md:335/337 兩行（兩行都是在講事件實例，不是在標出處）；diff 檔 1644–1699 行是 worktree-manager 整檔，裡面沒有出處行。

逐條核過、確認成立的：
- tests/CLAUDE.md 的「放在 ⑧ 與 ⑨ 之間」成立。
- 「⑦ 那行裸跑的 amend」成立。
- test-gate.sh 引用的 tests/CLAUDE.md「恆真斷言」那條存在（:42）。
- `said` 用的三個字串與 gate 實際訊息一致（check-claude-md.sh:195、:202）。
- 「先補完再記新起點」兩個擋點都會印，所以改挑「還有 commit 跳過檢查」這個理由成立。
- scripts/CLAUDE.md 變異表三列的實際結果，與「應該變紅的情境」那欄一致。
- 「判定行數一樣」這個驗法成立：三個變異版都是 105 行。
- dd-init、README 與 DD_PIPELINE_ARCHITECTURE.md 都沒有被這次改動的文字副本，這次不需要同步，也不用跳 dd-loop-rev。

What I ran
- `git grep`/`grep` 查 check-claude-md.sh 的 `staged=`、`head_or_empty > "$BASE_FILE"`（:215 與 :232，「它那一支」指 :215）、`EMPTY_TREE`、`read_base` 與兩則擋下訊息 → 都存在
- 依 scripts/CLAUDE.md 變異表做 3 份變異 gate，各跑 `bash tests/test-gate.sh <變異>` → 每份都 exit 1，判定行數都是 105。m1 第一則紅在「建立 docs/reviews/ 的那個 commit」，一路連鎖紅到「繞過①」等；m2 只紅「繞過③:rm 掉起點檔,開下一段放行」；m3 只紅「繞過③:by/ 的欠帳被洗掉」
- `git grep -n 'pstack\|superpowers\|借鑑'` → 出處行只有 verification-gate:9 和 design-brainstorm:9
- `git grep` 查「失敗案例 / 確認會失敗 / 假紅 / stash -u / WORKTREE_INFO」→ 只出現在被改到的檔裡，沒有別的副本要同步

Not reported
- worktree-manager:38 寫 WORKTREE_INFO.md「只記分支、路徑與基線結果」，漏了步驟 6 寫的 base。這是小的不準確，找不出它造成實際失敗的情境。
- 需要外部查證、我沒有去查的幾項：
  - `git worktree remove` 遇到被 ignore 的檔和沒追蹤的檔時，在 2.42.0 與 2.54.0 的實際行為，以及中文訊息的原文 → 在兩個版本實跑一次
  - pstack-claude 的 SessionStart matcher 是否涵蓋 startup、resume、clear、compact，它的 LICENSE，以及 owner 是不是 `michael-denyer` → 讀上游 `hooks.json` 與 LICENSE