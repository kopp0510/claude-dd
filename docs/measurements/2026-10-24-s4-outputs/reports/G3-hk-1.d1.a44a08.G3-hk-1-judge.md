結論：Critical 0、Important 2、Smells 2，另駁回 4 條。三個審查者都回來了，沒有要補派的。我沒有改任何檔、沒有 commit，也沒有把報告寫進 scratchpad（任務說明第 5 點寫明不准改檔）。

【派工】
- 派了 3 個（`code-reviewer`，`model: "haiku"`），在同一則訊息裡平行派出。3 是下限。這次 diff 剛好分成三塊互不重疊的內容，各給一個人：
  - A：`tests/test-gate.sh` 新增的繞過區塊與 amend 那行，逐則對照 `scripts/check-claude-md.sh` 的實際程式碼
  - B：文件裡的事實宣稱是否與程式碼相符（`scripts/CLAUDE.md` 的變異表、`tests/CLAUDE.md`、CHANGELOG），可在 /tmp 實跑變異
  - C：worktree-manager、verification-gate、全域模板 §3.5、根目錄收編總則，含 git worktree 實跑與交叉引用
- 三份 prompt 共用同一個本文：任務說明要求的「只准讀這些路徑」整節原樣轉達、diff 檔路徑與「被改到的檔讀 diff 檔那份」、「範圍與已跑過的驗證」整段、CLAUDE.md 清單、審查者職責、交回格式。差別只在「重點方向」那一段。
- agent ID：A `a3d3dcea81fddcabb`、B `ae9ad9a1532991bf7`、C `aad426e560b00c45b`。要逐字報告可以用 SendMessage 向它們取。

【採納】
1. A＋B（兩人各自命中）｜Important（維持原級）｜`scripts/CLAUDE.md` 變異表第 2、3 列用 `head_or_empty > "$BASE_FILE"` 定位要改的行，但這串字在 gate 裡出現兩次。
   - 查證：`grep -n` 回 `scripts/check-claude-md.sh:215`（`--start-segment` 那一支）與 `:232`（SKIP 自動記起點那一支）。
   - 實際後果：A 照字串全域替換，第 3 列的變異兩處都改到，多紅一則 `base_is`，與表上寫的「只有繞過③」不符。B 只改 215 行，結果與表一致。
   - 不降級的理由：表上雖然有「它那一支的」限定，A 照著做還是套錯，紅的情境就不是表上預測的那幾則，而這張表存在的目的正是防這種錯。
   - 建議改法：錨點改成唯一的上下文，例如「`--start-segment)` 那一支裡、`echo "段落起點：` 的上一行」。附上證明唯一的 grep，並明寫「裸字串會命中兩處」。
2. 裁決者（C 的 Not reported 提過一半）｜Important｜新規則「對得上它應該怎麼紅」與 §3.9 鑑別力測試互相衝突，而且兩者適用的情境重疊。
   - §3.9（diff 檔 2065–2066 行，模板 364–366 行）說：「改回舊版確認會紅」時不要斷言某個預期的壞結果，舊碼可能掉進第三種狀態。
   - 新的 verification-gate 第 36 行在 `git stash -u` 的步驟要求「紅的是原本那個 bug」。但 `stash -u` 把修復藏起來，正是「改回舊版」，等於叫人斷言預期的壞結果。
   - §3.5（模板 193–195 行）把自己的範圍限在「新測試第一次跑」。可是修 bug 先寫的測試，第一次跑的也是舊碼，同樣可能掉進第三種狀態，照「對得上預期」去判會把有效的紅判成無效。反過來，§3.9 的「不等於固定版就算紅」沒有擋假紅：import 壞掉也會「不等於」。
   - 建議改法：三處統一判準，紅要來自「被測的東西真的跑到了、給了錯的結果」，錯的值不必是預期的那一個。`stash -u` 那步照這條判；§3.9 補一句「不等於」也要來自被測物。
3. 裁決者｜Smells｜worktree-manager 第 37 行對「上面兩種」一律給「commit、搬到哪、還是刪掉」三個選項，而兩行之前（第 35 行）點名的例子就是 gitignore 的 `.env`。
   - 查證：對祕密檔提供「commit」選項，與全域模板 §3.7「不把 secret 寫進 commit」（`templates/global/CLAUDE.md:218`）衝突。
   - 建議改法：`!!` 類只給「搬到哪 / 刪掉」，或在 `.env` 那裡註明「不要提供 commit」。
4. C（Not reported 裡的項目）｜Smells｜新的 verification-gate 紅旗（diff 99–101 行）沒有帶 §3.5 那段「只管新測試第一次跑、變異照 §3.9」的範圍限定，只寫了「判準見 §3.5」。
   - 這條會隨第 2 條一起解掉，修第 2 條時順便處理即可。

【駁回】
- A｜Smells：「test-gate.sh 的註解說『先補完再記新起點』兩個擋點都有，實際只有一處會印」。
  - 理由：A 把那句讀反了。gate 第 195 行（欠帳）與第 202 行（缺報告）兩則訊息都以「先補完再記新起點：」結尾，只有 195 行含「還有 commit 跳過檢查」。註解說的「兩個擋點」是 `--start-segment` 裡的兩個 `exit 1` 分支，所以它挑「還有 commit 跳過檢查」才抓得到是哪一關擋的。註解正確。
- C（Not reported）：verification-gate 引用「0 紅的第一個嫌疑人」與模板原句不逐字相同。
  - 理由：那是 diff 第 98 行，無 `+` 的上下文行，既有問題，不是這次引入，也沒有被複製進新的程式碼路徑。可以另外修。
- C（Not reported）：worktree-manager 的 frontmatter `allowed-tools` 沒列 AskUserQuestion。
  - 理由：根目錄 CLAUDE.md:195 起寫明 `allowed-tools` 是預授權、不是白名單，漏列最多是 minor。建立流程第 2 步本來就在用它，不是這次引入。
- C（Not reported）：worktree-manager 的借鑑來源只寫在 CHANGELOG。
  - 理由：根目錄「只借概念、不抄檔案」那條規則要求的是歸屬寫得精確，不是要求寫在正文。這次沒動 LICENSE，也沒有過度或不足歸屬的證據。

【需使用者決定】無

【需要外部查證】
- 「git 2.54.0 實測」：本機只有 2.42.0（B、C 都在 2.42.0 上實跑確認了 remove 的拒絕與直接刪除行為，2.54.0 沒有驗到）。
- pstack-claude 的各項宣稱：SessionStart hook 注入 `<EXTREMELY_IMPORTANT>`、`pstack:poteto-mode`，以及 `tdd`、`reflect`、worktree-cleanup playbook 的內容與借鑑對象。

【結論】採納 Critical 0 / Important 2 / Smells 2

已驗證成立、沒有問題的部分：
- B 實跑三組變異，結果與變異表相符：第 1 列 27 則變紅、含繞過①；第 2、3 列各只紅 1 則（B 是只改 215 行）。
- amend 裸跑會讓整支在第 76 則判定行中止，包進 `expect` 的理由屬實。
- `tests/CLAUDE.md` 寫的判定行 grep 在固定版與三組變異都回 105。
- 「放在 ⑧ 與 ⑨ 之間」屬實；CHANGELOG 的 `## 未發布` 位置正確。
- worktree 的四種狀態碼、remove 的中英文拒絕訊息、`--force` 會連 gitignore 的檔一起刪，都經實跑確認。