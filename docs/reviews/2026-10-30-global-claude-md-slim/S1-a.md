# S1-a：審查者 A（搬移前後條件與指向有沒有掉）

## 派工

`subagent_type: code-reviewer`，與其他審查者同一則訊息平行派出。共用派工說明（逐字）：

> 你是 code-review 審查者。審查範圍：claude-dd repo（/Users/danlio/project/my_project/claude-dd）段落 S1 的整段改動 = `git diff f46d4de HEAD`（3 個 commit：a30dc1a、f0e80ab、a542817；工作目錄乾淨）。
> 段落目標：把全域模板 templates/global/CLAUDE.md §3.9 的 8 步迴圈做法細則，原文搬進新 skill skills/dd-loop/SKILL.md，全域只留 8 步清單、關卡、驗證教訓，並明寫「段落開始時、步驟 3、4、8 開始前呼叫 dd-loop」；同批改部署陣列、README×2、根 CLAUDE.md、架構文件、CHANGELOG、引用處；新增觸發實測 docs/measurements/2026-10-30-dd-loop-trigger/。設計文件：docs/designs/2026-10-30-global-claude-md-slim-design.md。
> 
> 資料：diff 檔 /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/S1-diff.txt（①整段 diff ②步驟 3 改動：無 ③被改到檔案的 HEAD 整檔（帶行號）④已跑過的驗證與預期值 —— ④ 已確認，不要重跑）。
> **diff 檔用 Read 的 offset/limit 每次 300 行讀到最後一行（共 5593 行）**：Read 一次讀太多會靜靜截斷、不報錯。被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。舊版可用 `git show f46d4de:<path>`。
> 
> 你的職責：找漏洞，每條附證據（路徑:行號 + 原文，或指令與輸出），沒證據不算。只用手上的資料判斷，需要外部查證（上網、跑 claude -p 等）的列出來交回。專案規則在各層 CLAUDE.md 與全域模板 §3.10。
> 輸出：Critical / Important / Smells 三級，每條「位置｜問題｜失敗情境｜證據｜建議」；另列 Not reported（看到但判為不報的，附理由）、What I ran（跑過的指令）、需要外部查證。

派工 prompt 的其餘部分（逐字）：「先讀這份共用派工說明並照做：<上面那份的路徑>」，接著：

> 你是審查者 A，方向：**搬移前後條件與指向有沒有掉**。拿 `git show f46d4de:templates/global/CLAUDE.md` 的 §3.9 逐句對「HEAD 全域 §3.9 ∪ skills/dd-loop/SKILL.md」：哪句的條件（「有…時」「除了」「或」「exit 非 0」）被改掉或拆壞、哪個指標（「見下方」「上一條」「下文」「這條」）搬家後指到錯的地方或懸空、全域留下的和 skill 裡的有沒有互相矛盾；以及全域還留著的句子（§3.5、§3.10、§4.x、§6.x、§7.x）有沒有引用已經搬走的內容。

## 發現

（逐字原文）

Critical 0 / Important 2 / Smells 0。審查範圍是 `git diff f46d4de HEAD`（S1，搬移前後的條件與指向）。

[Important] /Users/danlio/project/my_project/claude-dd/templates/global/CLAUDE.md:250。全域步驟 4 的「最少 3 個、收回少於 3 份 → 不算跑過步驟 4，不續行」搬上來後，丟掉了「要派 agent 時」這個前提。skill 又規定兩邊講法不同時以全域的關卡為準，這兩句合起來就把「不派 agent」的例外蓋掉了。
  失敗情境：某段 diff 全是文件或設定。照 SKILL.md:33「沒有人工寫的程式碼就不要派 agent」做，手上 0 份報告，撞上全域:250 的無條件關卡，再加上 SKILL.md:8「兩邊講法不同時，以全域 §3.9 的關卡為準」，結論是不准續行，例外失效。另一種讀法剛好相反：把它當成兩句矛盾，自己挑一邊。
  證據：舊版這句寫在「主對話直接派審查者」那個子項裡，排在「沒有人工寫的程式碼就不要派 agent」子項之後，前提是隱含的（`git show f46d4de:templates/global/CLAUDE.md` §3.9 步驟 4）。新版全域:249–250 把「例外見 `dd-loop`」綁在「每段全量跑」上，下一行的 ≥3 關卡沒有條件。全域:251「跳過要申報」只能間接緩和。
  建議：全域:250 開頭補「要派時」或「有派 agent 時」，與舊版的位置語意對齊。

[Important] /Users/danlio/project/my_project/claude-dd/skills/dd-loop/SKILL.md:95。「只取 `..` 前面那段」這條限定只寫在步驟 8。`<起點>` 在兩處被定義為「表上這段 commits 欄的起點」（全域:243、SKILL.md:21–22），這兩處都沒寫這條，所以步驟 4 並行模式仍然踩得到同一個陷阱。
  失敗情境：進度表 commits 欄照設計文件的格式寫成 `f46d4de..`。步驟 4 與步驟 3 並行時照 SKILL.md:31 跑 `git diff <起點> HEAD`，展開成 `git diff f46d4de.. HEAD`，回 exit 129。如果還寫成管線（例如 `| tee` 進 diff 檔），審查者拿到的就是空 diff 檔。
  證據：`git -c core.quotePath=false diff --name-only "f46d4de.." HEAD` → exit=129（用法說明）。設計文件:83 記錄乾跑只在步驟 8 抓到這件事，修補也只落在步驟 8。
  建議：把「只取 `..` 前面」移到 `<起點>` 的定義處（全域:243 與 SKILL.md:22），步驟 8 那句改成引用定義。

What I ran
- 從 `git show f46d4de:templates/global/CLAUDE.md` 抽出舊 §3.9（193 行），HEAD 新 §3.9（98 行），`skills/dd-loop/SKILL.md`（127 行）→ 都已存進 scratchpad
- python 正規化逐行比對「舊 §3.9 每個非空行在新 §3.9 ∪ SKILL.md 裡找不找得到」→ 找不到 5 行：依序走、步驟 4「例外見下」、步驟 8 標題、步驟 8「有進度表時 base 改填」（被延伸改寫）、步驟 7「上一條」（a542817 已改成指名）。逐條對過，條件沒掉，只剩上面兩項。
- `git grep -nE '§3\.9|全域模板|全域 CLAUDE'`，範圍 scripts、skills、commands、tests、templates、UPGRADING、docs/reviews/CLAUDE.md → 沒有指向已搬走內容的懸空引用。§3.5:200 與 §3.10:401、:412 引的「鑑別力測試」「0 紅」「識別符 git grep」三條都還在全域 §3.9；§4.1、§4.4、§6.1、§7.3、§7.4 都成立。
- `git grep -nE '報告一律落地|範圍要明講|派工前先準備|-judge\.md|SKIP-REVIEW|步驟 4|segment-base'`，範圍 gate 腳本、docs/reviews/CLAUDE.md、task-planner、plan-review、commands、UPGRADING → 都是講 gate 或蓋章區塊自己的內容，沒有引用全域 §3.9 被搬走的句子
- `git diff --name-only "f46d4de.." HEAD` → exit 129

Not reported
- SKILL.md:96 寫「輸出空白」不夠精確：另外兩條（`diff HEAD`、`ls-files`）照樣會印出未 commit 的 CLAUDE.md，結果是「不完整」而不是「空白」。這更難察覺，但修法相同，所以併進第 2 條，不另報。
- 設計文件:59 寫 4 條一行規則「搬走」，實際留在全域。:68 已在實作紀錄裡更正，不算漏。
- 全域:243 與 SKILL.md:13–15、:21–24 重複定義 `<起點>`：設計文件:83 有記錄這是刻意放回全域的，不報。
- `commands/dd-init.md` 蓋章區塊與它的 :323 歸 S2，不在本段範圍。

需要外部查證
- 全域:240 的退路網址 https://github.com/kopp0510/claude-dd 是否公開、能不能打開 `skills/dd-loop/SKILL.md`：用瀏覽器或 `curl -sI` 查一次就能確定。

## 處置

- Important 1（步驟 4 的 ≥3 關卡丟了「要派 agent 時」前提）→ 採納。全域 §3.9 步驟 4 改成「要派 agent 時(不派的例外見 `dd-loop`),主對話平行派…」
- Important 2（`..` 只在步驟 8）→ 採納，與 D-1 重疊。規則移到 `<起點>` 定義處（全域 §3.9 那行、SKILL.md「段落起點與 `<起點>`」節），步驟 8 改成引用；Not reported 那條「輸出空白不精確」一併改成「只列出還沒 commit 的那幾份」
- 外部查證（退路網址）→ 查了：`curl -sI https://github.com/kopp0510/claude-dd` 回 200；`…/blob/main/skills/dd-loop/SKILL.md` 回 404，因為 S1 還沒 push。push 後才成立，記進 judge
