## 【派工】

派了 3 個 `code-reviewer`（haiku），在同一則訊息裡平行派出。三個都回來了，沒有失敗，不用補派。

- **A**：`tests/test-gate.sh`、`tests/CLAUDE.md`、`scripts/CLAUDE.md`。看測試有沒有真的測到 gate 的行為、有沒有空通過。
- **B**：`templates/global/CLAUDE.md`、`skills/verification-gate/SKILL.md`、`skills/worktree-manager/SKILL.md`。看條文和同檔其他段有沒有矛盾、引用的東西存不存在。
- **C**：`CHANGELOG.md`、根目錄 `CLAUDE.md`、跨檔一致性。

**為什麼是 3 個**：這次 diff 只有一塊算是人工寫的程式碼（`test-gate.sh` 新增的區塊），其餘都是規則文件，照性質剛好分成三塊，所以取下限 3 個。每個人主攻一塊，但都被要求讀完整份 diff，不同人的盲點可以互相補。

## 【採納】

1. **B｜Important**｜§3.5 新加的括號說，判斷變異版有沒有被抓到要照 §3.9 的「不等於固定版的輸出就算紅」。但 §3.9 那條沒有排除「假紅」（import 壞掉、載入失敗、測試資料沒建好）。等於同一個 bullet 前半句說這種紅不算，後半句又把它導回「算」。
   - 查證：`templates/global/CLAUDE.md:193-195`（diff 檔 1894-1896）、`:364-367`（diff 檔 2065-2068）。§3.9 那段在 HEAD~1 就是這樣寫，這次沒改；但這次的括號把它明確指定成判準，矛盾是這次造出來的。
   - 建議：§3.9 鑑別力那條補一句「『不等於』要來自被測的東西給了錯的結果；載入失敗、import 壞掉不算」。

2. **主對話｜Important**｜`verification-gate` 的 stash 驗證步驟要求「紅的是原本那個 bug」，§3.5 也寫「修 bug 時就是那個錯的值」，這兩處跟 §3.9 打架。
   - `git stash -u` 把修復藏起來跑測試，跑的就是舊碼，正是 §3.9「改回舊版確認會紅」那種鑑別力測試。§3.9 明寫舊碼可能掉進第三種狀態（`:365-367` 的 2026-10-07 實例），那時測試照樣有鑑別力。
   - 照新寫法，掉進第三種狀態的測試會被判成「沒抓到」，重演 §3.9 記下的那次誤判（差點回頭去改一個正常的測試）。
   - 而 §3.5 的括號又說變異版照 §3.9 判，所以 stash 這個步驟同時受兩條相反的規則管。
   - 查證：`skills/verification-gate/SKILL.md:36` 與 `:57-59`（diff 檔 1595、1616-1618），對照 `templates/global/CLAUDE.md:193-195` 與 `:364-367`。
   - 建議：兩處改成「錯的值不必是你預期的那一個，舊碼可能掉進第三種狀態；但要是被測的東西真的跑到、給了錯的結果才算」，和第 1 條一起修。

3. **C｜Smells（從 Important 降級）**｜`worktree-manager/SKILL.md` 收尾段借了 pstack-claude 的 worktree-cleanup playbook 的概念，SKILL.md 裡卻沒寫來源。同一批 `verification-gate` 有寫（`:9`），全域 §3.5 借 `tdd` 也沒寫。
   - 查證：用 `git grep -i pstack HEAD` 搜，只在 CHANGELOG、根目錄 CLAUDE.md 和 verification-gate 出現；`skills/worktree-manager/` 底下只有 SKILL.md。
   - 降級理由：只借概念、沒抄檔案，CHANGELOG 有記來源，沒有授權或執行上的後果。但根目錄 `CLAUDE.md:353-357` 把「不足歸屬」列為一種錯，所以還是要補。
   - 建議：在收尾段補一句概念來源；§3.5 要不要也補，一併決定。

4. **主對話｜Smells**｜`worktree-manager/SKILL.md:38` 說 `WORKTREE_INFO.md`「每次都會出現在 `??`」，這句說太滿。
   - 步驟 6 把它寫在 worktree 根目錄，流程裡沒有任何東西擋它被 commit（例如在 worktree 裡 `git add -A`）。被 commit 進分支的話，它就不會出現在 `??`，還可能跟著 merge 進主線。同一處 `:30` 的「`!!` 處理完還是會留在輸出裡」也只對「決定留著不動」的那些成立，搬走的就不會留。
   - 建議：改成「沒被 commit 的話會出現在 `??`」；要不要在建立流程把它加進 `info/exclude`，可以另外考慮。

5. **主對話｜Smells**｜繞過③那則的說明寫「兩個擋點一起關掉」，但 rm 之前的對照只證明了欠帳那一關是開著的。
   - gate 在 `check-claude-md.sh:194-199` 被欠帳擋下就 `exit 1`，根本走不到 `:201` 的 `reviews_missing`，所以報告那一關在 rm 之前有沒有開著，沒有被斷言到。
   - rm 之後放行，靠的是 `:162` 的 `read_base || return 1`。這一半由 `scripts/CLAUDE.md` 變異表第 2 列間接釘住。
   - 建議：在說明或 `scripts/CLAUDE.md` 註明「報告那一關的『之前』由變異表第 2 列證明」，或者另做一組沒有欠帳、只差 rm 的對照。

## 【駁回】

- **A**｜`tests/CLAUDE.md` 的驗法 grep 不算 `said`／`base_is` 的 ❌ 行，所以只弄壞 `said` 的變異會被判成「一樣」。
  - 駁回理由：那個驗法的目的是確認 `set -e` 沒有中途中止整支、每則 `expect` 都跑到了，不是判定有沒有變紅。`said`／`base_is` 的 ❌ 行在固定版和變異版之間本來就會合理地不同，排除掉才對；`said`、`base_is` 都用 `||` 寫，不會觸發 `set -e`（`tests/test-gate.sh:44-45`）。審查者 C 在 Not reported 裡也是這樣判斷的。

- **C**｜根目錄 CLAUDE.md 點名 pstack-claude、描述它的 hook，違反「不要評論別人專案的人氣、品質或維護者」（`CLAUDE.md:349-351`）。
  - 駁回理由：那條規則限定的是人氣、品質、維護者這類讀者無法查證的評價。描述一個 hook 會注入什麼內容是行為事實，可以去上游查證，而且是這條總則的實例。真假列入外部查證。

- **C**｜改寫了兩份 SKILL.md，卻沒有照「新增 Skill 步驟 3」乾跑。
  - 不採納理由：CHANGELOG 第 38 行寫了「乾跑時 agent 卡在『搬去哪』『選哪一種』」，表示有乾跑過；至於乾跑的是不是最終版文字，快照裡判斷不出來。這是流程有沒有做到的問題，不是 diff 本身的錯，改列外部查證。

## 【需使用者決定】

無。採納第 2 條看起來像語意選擇，但 §3.9 有實測依據，第 1、2 條的建議改法同時保住了兩邊的意圖，不用使用者二選一。

## 【需要外部查證】

1. pstack-claude 的 SessionStart hook：觸發事件是不是 startup、resume、clear、compact 四種，注入的是不是 `<EXTREMELY_IMPORTANT>`，內容是不是要求先叫 `pstack:poteto-mode`（`CLAUDE.md:333-337`）。
2. pstack-claude 的 repo 擁有者是不是 `michael-denyer`（`verification-gate/SKILL.md:9`）。其他地方只寫「pstack-claude」，沒有擁有者可以對照。
3. git 2.42.0 與 2.54.0 下的 `git worktree remove`：遇到 `??` 和 ` M` 會拒絕、遇到 `!!` 會直接刪掉；以及中文拒絕訊息的原文。我依通用知識判斷方向是對的，但沒有實跑過這兩個版本。
4. `scripts/CLAUDE.md` 新變異表的三列「應該變紅的情境」。我對照 gate 原始碼（`:162`、`:193-215`、`:238-241`）手推過一遍，每列都說得通，但沒有實跑變異，依指示也沒重跑測試。
5. 兩份改寫過的 SKILL.md，是不是照最終版文字乾跑過。

## 【結論】

Critical 0 / Important 2 / Smells 3（採納數）。兩個 Important 都在同一對條文上（§3.5 新括號和 verification-gate 的寫法，對上 §3.9 鑑別力那條），建議一起修。依指示沒改任何檔、沒 commit。