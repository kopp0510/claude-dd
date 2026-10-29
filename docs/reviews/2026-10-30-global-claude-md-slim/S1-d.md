# S1-d：審查者 D（全面：新規則會不會讓迴圈做錯）

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

> 你是審查者 D，方向：**全面**，特別是「新規則本身會不會讓迴圈做錯」：全域 §3.9 新寫的呼叫時機、<起點> 規則、退路句、§7.4 新加那條，與 §4.1、§4.4、§7.1–7.3、task-planner 規則區塊、skills/code-simplifier/SKILL.md、/dd-init 蓋章區塊（commands/dd-init.md，這次沒改，但已蓋章的專案同時載入全域與區塊）有沒有衝突；SKILL.md 的 frontmatter 與 description 是否符合 repo 其他 skill 的慣例；install-dd-pipeline.sh 的陣列改動與註解。

## 發現

（逐字原文）

Critical 0 / Important 3 / Smells 0 — 範圍：`git diff f46d4de HEAD`（a30dc1a、f0e80ab、a542817），讀的是 S1-diff.txt 裡的 ① 和 ④，再加上 repo 裡沒被改到的 commands/dd-init.md、skills/task-planner/SKILL.md、skills/code-simplifier/SKILL.md 與其他 skill 的 frontmatter

[Important] skills/dd-loop/SKILL.md:95（diff 檔第 504 行）與 templates/global/CLAUDE.md 新增的 `<起點>` 那行（diff 檔第 565 行）｜「commits 欄要去掉 `..`」這條只寫在步驟 8，但全域對 `<起點>` 的定義是整欄照填，步驟 3、4 用 `<起點>` 的地方都沒有這條
  Failure：task-planner 規則區塊（skills/task-planner/SKILL.md:133）規定 commits 欄填 `<起點>..`。照全域定義代入步驟 4 時：依序跑的 `git diff f46d4de..` 等同 `f46d4de..HEAD`，會**靜靜漏掉工作目錄裡步驟 3 simplifier 還沒 commit 的改動**，exit 0；並行跑的 `git diff f46d4de.. HEAD` 會 exit 129。這次 diff 只在步驟 8 修了，屬於 §3.10 講的「只改一半」
  Evidence：在拋棄式 repo 實測，commit a→b，工作目錄再加 c。`git diff $b..` 只印 `+b`，exit 0；`git diff $b` 印 `+b +c`；`git diff $b.. HEAD` 印 usage，exit=129
  建議：把「只取 `..` 前面」移到全域那行 `<起點>` 定義，或移到 SKILL.md「段落起點與 `<起點>`」節，讓步驟 3、4、8 都套用

[Important] CHANGELOG.md `## 未發布` 那條（diff 檔第 16–17 行）｜寫「每個專案、每個 session 都少載這一塊；跑迴圈時多載一次 skill」，和規則、實測都不符
  Failure：全域 §3.9（diff 檔第 549 行）規定段落開始時、步驟 3、4、8 前「每次都叫」，一段是 4 次。measurements README.md:30–32 寫的是「最多約 24.8k 字元，**比全域省下的多** —— 跑迴圈的 session 總量會增加」。只讀 CHANGELOG 的人會以為跑迴圈的 session 也比較省。設計文件 S1-2 驗收原文明說超過時要「如實寫出、不再宣稱 context 有好處」
  Evidence：上述三處原文；`awk` 量出 SKILL.md 本文 6,159 字元，×4 ≈ 24.6k，大於省下的 5,042

[Important] docs/measurements/2026-10-30-dd-loop-trigger/check.sh:2、:8 與 results.tsv｜`inject_chars` 量到的不是注入量；README 的 6,188 在 repo 裡沒有能重跑的來源
  Failure：check.sh 註解寫「dd-loop 注入長度」。它算的是含 "dd-loop" 的 tool_result 長度，results.tsv 8 個正例全是 `inject_chars=24`，也就是 "Launching skill: dd-loop" 這個字串的長度，skill 本文不在 tool_result 裡。README:31 寫「每叫一次注入 6,188 字元（p1-start-1 的 jsonl 量到的）」，但原始 jsonl 不進 repo，也沒附量測指令。下一個人重跑 check.sh 會得到 24，接著推出「注入很小、context 淨省」，和 README 的結論相反。設計文件 S1-2 指定的量法（「從 Skill tool_result 內容長度取」）正是這個錯的量法
  Evidence：results.tsv 第 2–9 行都是 `inject_chars=24`；check.sh:8 的 `select(.type=="tool_result")|(.content|tostring)|select(test("dd-loop"))|length`

What I ran
- `git diff --stat f46d4de HEAD` → 21 個檔
- `git grep -n '3\.9' -- skills commands agents` → 只有 dd-init.md:323 和 verification-gate:56，兩處都還成立
- `sed -n 40,155p commands/dd-init.md`（蓋章區塊 52–149 行）→ 自成一體，沒有指向被搬走的全域文字；和 dd-loop 對照沒有直接矛盾
- `grep` task-planner 與 code-simplifier SKILL.md 的起點和 § 引用 → code-simplifier:14–17 有自己的 `<起點>` 與進度表例外，和全域一致；task-planner:133 規定填 `<起點>..`（第一條發現的來源）
- `head -8 skills/*/SKILL.md` → dd-loop 的 frontmatter（name + description，不帶 allowed-tools，有「不適用於」）和 frontend-design、writing-great-skills 同一種格式
- 拋棄式 repo 跑 `git diff $b..`、`git diff $b`、`git diff $b.. HEAD` → 輸出與 exit 碼見第一條
- `wc -m` 加 `awk` 抽 SKILL.md 本文 → 6,159 字元
- 用 `git grep` 找 README 和 remote 裡的 repo 網址 → 都是 kopp0510/claude-dd，退路句的網址正確
- `sed` 抽全域 §3.9 裡「見下、上一條、那條」這類指標 → 沒有懸空的
- `grep` install-dd-pipeline.sh、tests、ci.yml 裡列出的 skill 名 → 只有 PROMOTED_SKILLS 要改，已按字母序加入

Not reported
- §7.4 新條和 §7.1 第 3 點、§7.5 的字面張力：第 3 點要求命中 §7.2 時第一個 tool_use 是那個 Skill，現在會先叫 dd-loop；但 dd-loop 本身也是 Skill，而且 §7.4 已明寫先後，判為不會做錯
- 已蓋章的專案同時載入 rev 12 區塊和 dd-loop，一段多付約 25k 字元：設計文件把這件事排在 S2，屬已知取捨
- 退路句「沒裝 claude-dd」那個分支幾乎碰不到（沒裝就不會有這份全域模板），不會造成錯誤行為
- skill 清單裡 description 的 `<起點>` 顯示成 `&lt;起點&gt;`：這是平台的跳脫，zeabur-file 也一樣
- 設計文件 S1-1「沒處理、留給之後」列的既有問題：作者已經申報

需要外部查證
- `claude -p` 實際拿到的 dd-loop 注入字元數（要讀未進 repo 的 p1-start-1 jsonl 才能核對 README 的 6,188，以及注入到底在哪個欄位）


## 處置

- Important 1（`..` 規則只在步驟 8，依序跑時 `git diff X..` 靜靜漏掉工作目錄改動）→ 採納，見 S1-a 處置；SKILL.md 定義處同時寫進這兩種壞法
- Important 2（CHANGELOG）→ 採納，見 S1-b 處置
- Important 3（`inject_chars` 與設計文件指定的量法）→ 採納，見 S1-b 處置；設計文件 S1-2 量法那句補上「實作時發現本文在下一則 user 訊息、check.sh 改量那則」
