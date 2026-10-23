Critical 0 / Important 2 / Smells 0。審查範圍是快照的 `git diff HEAD~1 HEAD`（8 個檔），重點看 worktree-manager 與 verification-gate 這兩份 SKILL.md。

**[Important] skills/verification-gate/SKILL.md:36（diff 檔第 1595 行）—— 新加的「紅的是原本那個 bug」跟 §3.9 的鑑別力測試互相矛盾**
- 內容：`git stash -u` 把修復藏起來，等於「改回舊版確認會紅」。這一行現在要求紅的必須是原本那個 bug，也就是先寫好「它應該怎麼壞」再去比對。
- 證據：全域模板 §3.9（diff 檔第 2065–2066 行，模板第 364 行）明寫鑑別力測試「不要斷言某個預期的壞結果」，舊碼可能掉進第三種狀態。這次 diff 自己在 §3.5 也加了例外（diff 檔第 144 行）：判定變異版有沒有被抓到，仍照 §3.9「不等於固定版的輸出就算紅」。verification-gate 這一行沒跟著加這個例外。
- 失敗情境：舊碼在新測試下掉進第三種狀態，例如預期「實際 2」、拿到的卻是一個例外。這個測試其實有鑑別力，但照這一行的字面意思會判成「紅錯了」，agent 會回頭去改一個正常的測試。另外，回歸測試本身也是還沒 commit 的新檔時，`stash -u` 會連測試一起藏掉，紅的永遠是「找不到測試」，這個條件永遠達不到。
- 建議改法：這一行改用 §3.9 的判準（不等於修好那一版的完整輸出，而且紅的原因是被測的東西給錯了值，不是載入失敗）。並註明回歸測試必須先 commit，或者只把修復本身藏起來。

**[Important] skills/worktree-manager/SKILL.md:34–37（diff 檔第 1678–1681 行）—— `.env` 被歸在錯的那一類，而且問使用者的選項裡有「commit」**
- 內容：新流程只拿 `.env` 當 `!!`（被 gitignore 的檔）的例子。但步驟 4 複製出來的 `.env`，只有在專案的 `.gitignore` 有列它時才會落在 `!!`；沒列的話它是 `??`，會跟 `WORKTREE_INFO.md` 擺在一起。第 37 行接著叫 agent 用 AskUserQuestion 問「commit、搬到哪、還是刪掉」，沒有任何地方提醒 `.env` 可能含 secret。
- 證據：在拋棄式 repo 實跑（git 2.42.0，`.gitignore` 只有 `node_modules/`），輸出是 ` M t.txt` / `?? .env` / `?? WORKTREE_INFO.md` / `!! node_modules/`。
- 失敗情境：專案有 `.env.example`，但 `.gitignore` 沒列 `.env`。收尾時 `.env` 出現在 `??`，agent 不認得它是步驟 4 複製出來的檔，把它當一般未追蹤檔列進選項。使用者選了 commit，secret 就進了 feature 分支的歷史，違反全域 §3.7「不把 secret 寫進 commit」。
- 建議改法：寫明 `.env` 視 `.gitignore` 而定，可能出現在 `??` 或 `!!`。並且對 `.env` 這類檔不提供 commit 選項，或至少附上警告。

**Not reported**
- frontmatter 的 `allowed-tools` 沒列 AskUserQuestion：根目錄 CLAUDE.md 寫明 `allowed-tools` 只是免確認預授權、不是白名單，而這份 SKILL.md 沒寫「不詢問、直接執行」，所以不算矛盾。建立流程步驟 2 本來就這樣用，是既有寫法。
- worktree-manager 引用的步驟編號都對得上：「步驟 4 複製 `.env`」對到第 20 行，「步驟 6 寫 `WORKTREE_INFO.md`」對到第 23 行。
- 收尾流程裡對 git 行為的描述，實跑全部成立：` M`、`A `、`??`、`!!` 的意思；`git worktree remove` 遇到修改或未追蹤檔會拒絕；只剩被 ignore 的檔時會連目錄直接刪掉；拒絕時的中文錯誤訊息。
- 「`!!` 處理完還是會留在輸出裡」：檔案刪掉或搬走之後就不在了，留在原地的（例如 `node_modules/`）才會留著，可以當成合理的提醒，不報。
- 「`WORKTREE_INFO.md` 每次都會出現在 `??`」：開發途中被 `git add -A` commit 進分支的話就不會出現，這屬於小幅誇大，沒有失敗情境，不報。
- tests/test-gate.sh 新加的那一段：照 `expect`、`said`、`base_is` 的定義（test-gate.sh 第 27–45 行）讀過，三組繞過與對照的邏輯一致，起點檔的狀態轉移也對，沒找到問題。測試本身沒重跑，你們已經跑過。

**What I ran**
- `git --version` → 2.42.0
- 拋棄式 repo（`/tmp/wtexp.XXXX`）：建 worktree，`cp .env.example .env`，加 `WORKTREE_INFO.md`、`node_modules/`，再改一個已追蹤的檔 → `git status --porcelain --ignored` 印出 ` M t.txt` / `?? .env` / `?? WORKTREE_INFO.md` / `!! node_modules/`
- 同一個 repo 跑 `git worktree remove ../w` → `致命錯誤: '../w' 包含修改或未追蹤的檔案，使用 --force 刪除`，exit 128
- 還原修改、刪掉未追蹤檔，只剩 `!! node_modules/` 時再跑 `git worktree remove` → exit 0，目錄消失
- 在 diff 檔裡 grep `鑑別力測試|第三種|它應該怎麼紅` → 命中第 1617、1894–1896、2065–2066 行
- `grep -nE '^(expect|said|base_is|commit|skip_commit)\(\)'` 查 tests/test-gate.sh → 讀到第 27–45 行的 helper 定義