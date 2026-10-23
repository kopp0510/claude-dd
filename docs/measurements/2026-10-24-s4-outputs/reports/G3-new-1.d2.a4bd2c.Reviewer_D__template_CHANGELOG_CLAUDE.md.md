Critical 0 / Important 2 / Smells 0。範圍是快照的 `git diff HEAD~1 HEAD`(8 檔),讀的是 diff 檔與快照。

**[Important] templates/global/CLAUDE.md:193–195(diff.txt:142–144)、skills/verification-gate/SKILL.md:36 與 :57–59(diff.txt:91、:99–101)、CHANGELOG.md:25–26**
- 內容:§3.5 新條文把「修 bug 時紅的要是那個錯的值」和 §3.9 鑑別力測試劃成兩件事。前者管「新測試第一次跑」,後者管「變異版」。但修 bug 時把修復藏起來或改回舊版再跑,正是 §3.9 那條括號講的「改回舊版確認會紅」。verification-gate 的 `git stash -u` 迴歸模式也新寫了「紅的是原本那個 bug」。結果同一件事有兩條相反的判準:
  - §3.9 要求「不要斷言某個預期的壞結果」,舊碼可能掉進第三種狀態,只要「不等於」固定版的輸出就算紅。
  - §3.5 與 verification-gate 要求紅的內容對得上那個錯的值。
- 證據:diff.txt:2065–2068(§3.9 原文:「判定式要比對『固定版的完整輸出』,不要斷言某個預期的壞結果……變異版掉進**第三種**狀態……先記下固定版的輸出字串,變異版只要『不等於它』就算紅」)。diff.txt:143「修 bug 時就是那個錯的值(例如『預期 3、實際 2』)」。diff.txt:91「看到失敗,而且紅的是原本那個 bug」。
- 另一個方向也有洞:新括號說變異版的判定「仍照 §3.9……不等於固定版的輸出就算紅」。§3.9 原文確實這樣寫,沒有附帶條件。但這等於明文把變異版排除在新的假紅防線之外。若某個變異讓 import 壞掉或測試資料建不起來,輸出也是「不等於」,照這句就算抓到了,而這正是本次要擋的假紅。
- 失敗情境:
  - 修 bug 時 `git stash -u` 後舊碼回傳的是 C,不是使用者回報的 B。照 §3.5 與 verification-gate,這不算對得上,agent 會判定測試沒鑑別力、回頭去改一個正常的測試。這就是 §3.9 記載的 2026-10-07 事故。
  - 反過來,一個語法壞掉的變異照 §3.5 括號會被算成「抓到了」。
- 建議改法:
  - §3.5 改寫成:被測物真的跑到、而且給了錯的結果才算紅;錯的值不必是預期那一個。
  - §3.9 那句「不等於」補上同一個但書:不等於要來自被測物給的錯誤結果,載入失敗或資料沒建好的「不等於」不算。
  - verification-gate 的 stash 模式與 CHANGELOG 的「修 bug 時就是那個錯的值」一起改。

**[Important] skills/worktree-manager/SKILL.md:27–41(diff.txt:115–129)**
- 內容:CHANGELOG.md:38 寫明這段「借鑑 pstack-claude 的 worktree-cleanup playbook」,但 SKILL.md 裡沒有任何歸屬。同一批的 verification-gate 有在檔頭補上「『假紅』那條紅旗借鑑 michael-denyer/pstack-claude 的 `tdd`」(diff.txt:82)。
- 依據:根 CLAUDE.md「只借概念、不抄檔案時……授權仍要處理:歸屬範圍**精確到段落/項目**」。repo 對只借概念的前例是寫在檔內(`skills/design-brainstorm/SKILL.md:9`、`skills/verification-gate/SKILL.md:9`,grep 結果)。
- 失敗情境:部署出去的 worktree-manager 讀者看不出收尾那段的來源。CHANGELOG 不部署,而且會隨版本沉下去,同一批改動裡兩個 skill 的歸屬處理也不一致。
- 建議改法:在 SKILL.md 收尾那段或檔頭加一行借鑑來源,精確到「收尾步驟 1 對 `!!` 被 ignore 檔的處理」。根 CLAUDE.md 總則借鑑 `reflect` / `poteto-mode` 的寫法要不要比照,也一併決定。根 CLAUDE.md 不部署,可接受只記在 CHANGELOG。

**需要外部查證(列出交回,未自行查):**
- pstack-claude 的 LICENSE 是否存在、是否相容(收編清單 #1;只借概念時「授權仍要處理」)。上游 repo 的 LICENSE 檔可以確認。
- 上游 owner 是不是 `michael-denyer`。根 CLAUDE.md 只寫 `pstack-claude`,沒有 owner。
- pstack-claude 的 SessionStart hook 是否真的在 startup、resume、clear、compact 都觸發,以及注入內容是否含 `<EXTREMELY_IMPORTANT>`、要求叫 `pstack:poteto-mode`。上游的 `hooks/hooks.json` 可以確認。
- `git worktree remove` 的繁中錯誤訊息「包含修改或未追蹤的檔案,使用 --force 刪除」是否與 git 的 zh_TW 翻譯一致。在 zh_TW locale 下實跑一次可以確認。

**Not reported(看過但不報):**
- CHANGELOG 的 `## 未發布` 放在 `## 1.6.4` 之上,格式為 `### Changed`。diff 只在標題之上新增行,沒動已發布區塊。快照裡沒有任何 `v*` tag,CI 那道「已發布區塊不可改動」檢查無法在快照重現,只確認了 diff 範圍。
- CHANGELOG 對其他改動的描述都和 diff 吻合:日期、git 2.42.0 與 2.54.0、`WORKTREE_INFO.md`、`.env`、⑦ 那行(⑦ 在 test-gate.sh:276,amend 在其區塊內)、三條繞過路徑、「放在 ⑧ 與 ⑨ 之間」。
- dd-init 蓋章區塊和 `dd-loop-rev`:`commands/dd-init.md` 沒有 §3.5 或「失敗案例」相關文字,不必跳 rev。
- README 與 ARCHITECTURE 的手動同步區塊:收編清單在兩份 README 只有連結,verification-gate 與 worktree-manager 的表格描述沒有過期,不用跟改。
- scripts/CLAUDE.md 變異表裡的行號描述:`staged=` 在 check-claude-md.sh:238;`head_or_empty > "$BASE_FILE"` 有 :215 與 :232 兩處,「它那一支」指明是 `--start-segment` 那處;`reviews_missing` 缺報告時 return 0(:187)。三者都和表上寫的對得上。
- tests/CLAUDE.md 的驗證 grep 和 `expect` 的 ✅/❌ 格式(test-gate.sh:34–39)對得上。
- 繞過③ 的對照只用 `said` 驗到欠帳那一關。報告那一關被 owed 檢查(:194–199)搶先 exit,在對照裡沒有獨立顯示。這已由變異表第二列覆蓋,不構成失敗情境。
- 既有問題:scripts/CLAUDE.md 寫「前 61 項」的數字宣稱已過期,不在本次 diff 內。

**What I ran:**
- `Read diff.txt 1–250`:讀完整段 diff
- `Grep 鑑別力|不等於|第三種|固定版` 對 diff.txt:找到 §3.9 原文 diff.txt:2065–2070
- `git tag --sort=-v:refname`:沒有輸出(沒有 tag)
- `git show HEAD~1:CHANGELOG.md | grep '^## '`:1.6.4 為第一個版本標題
- `git grep 'superpowers|pstack|mattpocock'`:借概念前例都是檔內一行,LICENSE 表沒有列只借概念的來源
- `git grep '確認會失敗|失敗案例|假紅|讀紅'`:dd-init 沒有命中
- `grep` README/ARCHITECTURE 的收編、worktree-manager、verification-gate:只有連結與表格描述,不用同步
- `grep` check-claude-md.sh 的 `staged=`、`head_or_empty`、`reviews_missing` 並讀 :185–244:變異表的描述對得上
- `grep` test-gate.sh 的情境標題與 `expect`/`said` 定義:⑦ 在 :276,繞過區塊在 ⑧(:297)與 ⑨(:358)之間