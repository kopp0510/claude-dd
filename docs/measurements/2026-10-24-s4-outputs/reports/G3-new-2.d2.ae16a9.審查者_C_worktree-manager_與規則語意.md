Critical 0 / Important 2 / Smells 0 — 範圍是快照的 `git diff HEAD~1 HEAD`。主力審了 skills/worktree-manager/SKILL.md 的收尾流程,也看了 §3.5 和 verification-gate 新加的「假紅」條文。

worktree-manager 收尾流程講到 git 行為的部分,我在 git 2.42.0 上逐一實跑,全部成立。步驟 4 的 `.env` 和步驟 6 的 `WORKTREE_INFO.md` 在同一份檔案裡都找得到出處(diff.txt:1664、1667)。這一塊我沒有要報的。兩條發現都出在「假紅」那組條文。

[Important] skills/verification-gate/SKILL.md:36、57–58(diff.txt:1595、1616–1617)。這裡要求「紅的是原本那個 bug」「修 bug 時就是那個錯的值」,跟同一套規則裡的 §3.9 鑑別力測試條文衝突(diff.txt:2065–2067)。
  Failure: `git stash -u && <測試>` 本身就是「改回舊版確認會紅」。舊碼可能掉進第三種狀態,例如回報裡說回 2,實際卻丟例外或回 5。照 SKILL.md 這兩處,agent 會判定測試無效、回頭改一個其實正常的測試,也就是 §3.9 記載的 2026-10-07 那次差點發生的事。§3.5 有加括號例外「判定變異版仍照 §3.9」(diff.txt:144),但 verification-gate 的兩處都沒帶這個例外。CHANGELOG 第 17 行宣稱「仍照 §3.9」,對這支 skill 不成立。
  Evidence: diff.txt:1595 寫「看到失敗,而且紅的是原本那個 bug」;diff.txt:2065 寫「不要斷言某個預期的壞結果……變異版掉進第三種狀態」。

[Important] templates/global/CLAUDE.md:193–195(diff.txt:1894–1896)。這條管所有「新測試先寫失敗案例」,卻只給了修 bug 的判準,沒說新功能的紅該長什麼樣子,而且用來舉例的反例跟新功能的紅分不出來。
  Failure: TDD 寫新功能時,實作還沒寫,第一次紅通常是 `ImportError: cannot import name foo` 或 `foo is not defined`。這跟條文說「只證明測試自己壞了」的「import 路徑寫錯、拼錯字」是同一類訊息。讀者可能拒收這個合法的紅,也可能照收,而照收時連真正打錯字的 import 也放過了,兩種讀法都能從字面上推出來。
  Evidence: diff.txt:195 只寫「修 bug 時就是那個錯的值」,沒有新功能的分支。這次對話開頭載入的全域 CLAUDE.md §3.5 已經是後來修過的版本,多了「新功能還沒寫時,『找不到這個函式』也不算:先放一個回錯值的空殼,讓它跑到斷言」和「錯的值不必是你預期的那一個」兩句,剛好補上這兩處缺口。我沒讀快照以外的路徑去比對,這個佐證只來自已經在我上下文裡的那份。

What I ran
- `git --version` → git version 2.42.0(macOS)
- 在 mktemp -d 的拋棄式 repo 裡,`.gitignore` 寫 `.env` 和 `node_modules/`,分別建了 wt1–wt4 四個 worktree:
  - 只有被 gitignore 的檔時,status 輸出 `!! .env`、`!! node_modules/`(被忽略的目錄只列一行目錄名)。`git worktree remove` exit 0、沒有提示,目錄直接消失。
  - 同時有修改、暫存、未追蹤時,status 輸出 ` M a.txt`、`A  st.txt`、`?? new.txt`、`!! .env`。remove 回 128,訊息是「致命錯誤: '../wt2' 包含修改或未追蹤的檔案，使用 --force 刪除」,跟 SKILL.md 寫的原文一致。
  - 只剩暫存的檔時 remove 回 128;只剩 `WORKTREE_INFO.md` 這個未追蹤檔時也回 128。
  - `remove --force` exit 0,目錄連同被忽略的 `.env` 一起刪掉。
  - lock 過的 worktree,remove 回 128,訊息是「無法刪除一個鎖定的工作區，使用 'remove -f -f' 覆蓋或先解鎖」。
  - 未追蹤目錄裡放一個被忽略的檔時,status 輸出 `?? cfg/` 和 `!! cfg/.env`。

Not reported
- 開頭提示要我判斷的 `allowed-tools` 缺 AskUserQuestion:不報。根目錄 CLAUDE.md 寫明 `allowed-tools` 只是免確認預授權,漏列只會多一次權限詢問;而且舊有的建立流程第 2 步本來就用 AskUserQuestion。
- 收尾流程沒涵蓋 locked worktree 和 submodule:既有缺口,不是這次 diff 引入的。這個 skill 自己不會 lock worktree,submodule 則已寫在「限制備忘」。
- 未 push 的 commit 和 stash:remove 後分支與 stash 都還在,不構成資料遺失。
- 小措辭:diff.txt:1682 說 `WORKTREE_INFO.md`「只記分支、路徑與基線結果」,比第 6 步少了 base;diff.txt:1674 說「`!!` 處理完還是會留在輸出裡」,但已刪除或搬走的檔其實不會再出現。兩處都沒有具體的失敗情境。
- tests/test-gate.sh 新加的區塊和 scripts/CLAUDE.md 的變異對照表只讀過、沒有實跑變異。
- 2.54.0 那一半的實測沒驗,手上只有 2.42.0。