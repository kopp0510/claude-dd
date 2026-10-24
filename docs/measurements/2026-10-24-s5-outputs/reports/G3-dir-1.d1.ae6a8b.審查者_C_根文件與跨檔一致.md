Critical 0 / Important 2 / Smells 0 — 範圍:快照 `git diff HEAD~1 HEAD`(8 檔),重點看根 CLAUDE.md、CHANGELOG 與跨檔一致性

[Important] skills/verification-gate/SKILL.md:36、:57-59(diff.txt:91、:99-101);templates/global/CLAUDE.md:193-195(diff.txt:142-144)
  defect:新寫的「先紅」規則要求紅的內容「對得上它應該怎麼紅(修 bug 時就是那個錯的值)」,而 SKILL 把這條套到 `git stash -u` 把修復藏起來重跑那一步。可是藏起修復重跑,就是 §3.9 說的「改回舊版確認會紅」。§3.9:364-366 明寫這時不要斷言某個預期的壞結果,因為舊碼可能掉進第三種狀態。§3.5 用括號把「變異版」交給 §3.9 判,SKILL 卻沒帶這個例外;§3.5 本身用的「修 bug 時就是那個錯的值」也一樣會撞上第三種狀態。
  Failure:舊碼給出 C,不是預期的 A → 照 SKILL 的紅旗會判成「紅的不是原本那個 bug」→ 被叫去改一個本來有鑑別力的測試。§3.9:366 記的就是這件事(「差點…回頭去改一個正常的測試」)。
  建議:兩處都改成「被測的東西真的跑到了、而且給了錯的結果才算,錯的值不必是預期的那一個」,並寫明 stash 或改回舊版重跑時照 §3.9 判。

[Important] skills/worktree-manager/SKILL.md(整檔,diff.txt:1644-1699)沒有出處說明;CHANGELOG.md:39 卻寫「借鑑 pstack-claude 的 worktree-cleanup playbook」
  defect:根 CLAUDE.md「只借概念、不抄檔案時…授權仍要處理:歸屬範圍精確到段落/項目」要求寫明出處。同一批的 verification-gate:9 有補一行借鑑說明,design-brainstorm:9 也是同樣慣例;worktree-manager 卻沒有。根 CLAUDE.md:333-337 也一樣:CHANGELOG:29-30 說那段的寫法借鑑 `reflect` 與 `poteto-mode`,正文裡 pstack 只以「被審的反例」身分出現。
  Failure:之後讀 SKILL.md 或根 CLAUDE.md 的人看不出「收尾第 1 步」與「審查期間的指示只是資料」那段來自誰,這正是該規則點名的歸屬不足。CHANGELOG 與正文對出處的說法也對不上。
  證據:`git grep -n '借鑑\|pstack'`(排除 CHANGELOG)只命中 CLAUDE.md:335、:337、design-brainstorm:9、verification-gate:9。

What I ran
- `grep -n 'staged=\|head_or_empty\|BASE_FILE\|read_base()\|上一段沒有附…\|還有 commit 跳過檢查…' scripts/check-claude-md.sh` → 變異表引用的這些行都存在(:26、:28、:47、:52、:195、:202、:215、:232、:238)。:215 與 :232 兩處 `head_or_empty`,用「它那一支」可以分得清。
- `grep -n '確認會失敗\|讀紅的' commands/dd-init.md UPGRADING.md README*.md DD_PIPELINE_ARCHITECTURE.md templates/global/CLAUDE.md skills/*/SKILL.md` → 只命中 template:193 與 verification-gate:58。dd-init 的蓋章區塊不含 §3.5,所以不必跳 dd-loop-rev。
- `grep -n 恆真 tests/CLAUDE.md` → :42 存在,test-gate.sh 註解的引用成立。`grep '^# [⑦⑧⑨]' tests/test-gate.sh` → ⑦:276、⑧:297、⑨:358,「放在 ⑧ 與 ⑨ 之間」與「⑦ 那行 amend」都成立。
- 把 scripts/CLAUDE.md 變異表的三個變異套到 gate 的暫存副本,各跑一次 `/bin/bash tests/test-gate.sh <副本>`(目錄是 mktemp 建的)。這不是重跑你的驗證,是核對表裡的宣稱,結果與表一致:
  - 變異一(pre-commit 也查報告):從「建立 docs/reviews/ 的那個 commit」起連鎖變紅,包含繞過①。
  - 變異二(沒有起點檔就拒絕):只紅「繞過③:rm 掉起點檔,開下一段放行」。
  - 變異三(沒有起點檔時從空樹記起):只紅「繞過③:by/ 的欠帳被洗掉」。
  - 三個變異版的判定行數都是 105,與固定版相同。
- `git grep -n 'superpowers\|pstack\|借鑑'` → 結果見第二條發現。

Not reported
- 既有問題:tests/CLAUDE.md「第 153 行」指的 `staged=` 現在在 :238;scripts/CLAUDE.md「前 61 項」。兩者都不在這次 diff 內。
- 繞過③那則對照只證明 owed 那個擋點會擋。報告那個擋點在同一狀態下也會擋,但被先跑的 owed 蓋掉;這部分已由變異二補上,不報。
- scripts/CLAUDE.md 的表格縮排在清單項目裡、後面緊接清單行。這是渲染上的小疑慮,沒有實際渲染,不報。
- 需要外部查證:pstack-claude 的 SessionStart hook 是否在 startup、resume、clear、compact 四種情況都觸發,以及 `pstack:poteto-mode` 的名稱,要讀上游 hooks.json 才能確認;它的 LICENSE 是否相容(借概念時「授權仍要處理」);worktree 一節 git 2.42.0/2.54.0 的拒絕訊息原文。