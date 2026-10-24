# S6-b — 步驟 4 改成 A（審查者 b：跨檔一致與殘留）

## 派工

主對話給它的派工 prompt（逐字；路徑換成 `<scratchpad>`）。三個審查者在同一則訊息平行派出（`subagent_type: "code-reviewer"`，不帶 model；紀錄檔 agentType code-reviewer、spawnDepth 1）。

````text
8 步迴圈步驟 4 的審查者（代號 b）。repo：/Users/danlio/project/my_project/claude-dd（專案規則在根目錄與各層 CLAUDE.md）。
這段（S6）把步驟 4 的 code-review 從「另派裁決者，由它派審查者」改成「主對話直接派審查者、自己查證」，依據是 docs/measurements/2026-10-23-reviewer-real-sessions.md「拿掉裁決者的對照」與實測用的任務說明 docs/measurements/2026-10-24-s5-inputs/direct.txt。計畫與小任務在 docs/designs/2026-10-23-裁決審查-design.md 的「### S6」。

diff 檔：<scratchpad>/S6-review-diff.txt（共 4517 行）。
- Read 一次讀太多會靜靜截斷、不報錯（約 47 KB 就停）。一律用 Read 的 offset／limit 每次 300 行讀；第 1–360 行（① 整段 diff 與 ② simplifier 的改動）一定要全讀；第 361 行以後是被改到檔案的整檔內容（帶行號），照需要讀；第 4511 行以後是 ④ 已跑過的驗證。
- 被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。
- ④ 列的驗證已確認，不要重跑。

你的方向：跨檔一致與殘留。scripts/check-claude-md.sh 的 echo、scripts/CLAUDE.md、docs/reviews/CLAUDE.md、README.md、README.zh-TW.md。查：repo 裡還有沒有描述 code-review 步驟 4 是「裁決者」結構、卻沒被改到的地方（自己 `git grep -n -i -E '裁決|judge|adjudicat'` 全 repo 掃，排除 plan-review 相關、docs/measurements/、docs/reviews/ 下的既有報告、CHANGELOG 已發布區塊）；根 CLAUDE.md「CI 不驗、只能手動同步的區塊」那條列的區塊（README 核心工作法段、CLAUDE.md 維護規則、DD_PIPELINE_ARCHITECTURE.md 等）有沒有該改沒改；英文與中文 README 講的是不是同一件事；新加的宣稱（例如「實測另派裁決者比較慢、也沒有多抓到錯」）跟量測文件對不對得上。

職責：找漏洞、證明這次改動有錯。每條附證據（diff 檔行號、或 repo 檔案行、grep 結果），沒證據的不算。只用手上的資料判斷，需要外部查證的列出來交回、不要自己去抓。不要改任何檔、不 commit。
交回：分級 Critical / Important / Smells，每條附證據；另列 Not reported（看到但判為不報的，附理由）與 What I ran（跑過的指令）。
````

## 發現

審查者交回的原文（逐字，從 subagent 紀錄檔的交回訊息取出）：

````text
Critical 0 / Important 2 / Smells 0 — 審查範圍：S6 整段（diff 檔第 1–360 行與 ④），方向是跨檔一致與殘留

[Important] commands/dd-init.md:46（蓋章區塊外的「列出與現行版的差異」那串）有兩句仍把裁決者寫成現行版的內容：
  - `rev 5 缺…「派兩個 reviewer 取聯集」…（rev 10 已由裁決結構取代）`
  - `rev 9 的步驟 4 是…，缺「先備 diff 檔、由裁決者派最少 3 個審查者並逐條查證、報告加 -judge.md」`
  Failure：rev ≤9 的專案跑 `/dd-init` 時，AskUserQuestion 的升級說明會同時列出「缺：由裁決者派」（rev 9 那句）和「rev 10 缺：主對話直接派」（diff 檔第 91 行新加的那句）。使用者會被告知現行版「有裁決者」，同一份清單又說「拿掉了裁決者」，兩句互相矛盾。S6-2 的驗收只 grep 蓋章區塊，所以這一行沒被抓到。
  Evidence：`sed -n '46p' commands/dd-init.md | grep -o …`，輸出就是上面兩段原文。

[Important] README.md:125、README.zh-TW.md:130 的新結尾句（diff 檔第 43、56 行）把結論講成定論：「measured, adding one was slower and caught no more defects」／「實測另派一個裁決者比較慢、也沒有多抓到錯」。同一段改動的其他三處都寫了「同時改了三件事、分不出是哪個的功勞、n 小只是方向」（模板第 299 行、CHANGELOG 第 16 行、dd-init 第 114 行）。另外兩份 README 和 dd-init 蓋章版第 114 行都沒提費用：直接派較貴，US$5.13 對 US$3.83。
  Failure：讀 README 的人會把「慢」整個歸給裁決者，也以為改了沒有代價。但量測文件寫的是 A 組同時拿掉裁決者、改成分段讀、改成先派工再讀，所以「慢」不能單獨歸因給裁決者。模板第 290 行也明寫「分不出是哪個的功勞」，跟 README 直接衝突。
  Evidence：docs/measurements/2026-10-23-reviewer-real-sessions.md「五組並排」表：A 269s／5.13／4，S4 新 350s／3.83／3。設計文件 diff 第 144 行寫「三件事，分不開」。

已核對、站得住的：
- 模板、CHANGELOG、dd-init 引用的數字都跟量測文件「拿掉裁決者的對照」一致：269s、5.13、K1 2/2、K5 2/2、K4 0/2，合計 4/6；350s、3.83、3/6。
- 「3024 行只回 544 行、約 47 KB」對得上量測文件第 209–210 行。
- docs/reviews/CLAUDE.md 說「`2026-10-23-裁決審查/` 裡 S3–S5 的 `-judge.md` 是裁決者寫的」：這三份檔都存在，檔頭的派工節也都寫明派的是裁決者。
- check-claude-md.sh 的 echo、scripts/CLAUDE.md:76、docs/reviews/CLAUDE.md 開頭與格式表三者用詞一致。
- 中英兩份 README 內容一一對應（同一則訊息派工、分段讀、數量由主對話決定、讀程式碼判定不表決）。
- 全 repo 殘留掃描：排除 plan-review、量測文件、設計文件與既有報告後，剩下的命中只有歷史敘述、設計文件檔名、`-judge.md` 檔名，以及其他語意的「裁決」（verification-gate、tech-diagram-gif、design-brainstorm 的 plan-review 裁決者、code-reviewer 的 "judgement"）。只有上面 dd-init:46 那一行是語意過期。
- DD_PIPELINE_ARCHITECTURE.md 只有第 91 行一行式迴圈摘要提到步驟 4，不需要改。
- UPGRADING.md 的 rev 只有 diff 第 69 行那一處，已跳到 11。

What I ran
- Read 了 diff 檔第 1–364 行、第 4505–4518 行 → 讀完 ① ② ④
- `git grep -n -i -E '裁決|judge|adjudicat'`，排除 docs/measurements、docs/reviews/2*、docs/designs，再 `grep -v plan-review` → 命中清單如上
- `awk '/拿掉裁決者的對照/{f=1} f' docs/measurements/2026-10-23-reviewer-real-sessions.md` → 數字與限制一致
- `grep -n -E '544|3024|47 ?KB'` 量測文件 → 第 207–213 行
- 在 skills/plan-review/SKILL.md、DD_PIPELINE_ARCHITECTURE.md 裡 grep 裁決、judge、步驟 4 → 都不需要改
- 在 README、架構文件、CLAUDE.md、UPGRADING、commands、skills、agents、scripts、templates 裡 grep `docs/reviews|S<段落>|-a\.md|兩個 reviewer|取聯集|union` → 沒有新的殘留
- `ls docs/reviews/2026-10-23-裁決審查/`，再對 S3–S5 的 `-judge.md` 跑 `git log` 和 `sed -n 1,12p` → 都是裁決者寫的，日期 2026-10-24
- `grep -n -E 'rev ?1[01]|dd-loop-rev'`（UPGRADING、README、架構文件、CLAUDE.md、dd-init、模板），加上 `sed -n 36,48p CHANGELOG.md` → rev 一致
- `sed -n 46p commands/dd-init.md | grep -o …` → 抽出上面兩句過期描述

Not reported
- dd-init 蓋章版第 113 行少了模板第 284 行的「預設『這條可能是錯的』」：屬於措辭精簡，不影響行為。
- 子目錄裡的 `S1-judge-plan-S2.md` 是 plan-review 的裁決報告，「S3–S5」那句沒涵蓋它也不會誤導，不報。
- ④ 列的 shellcheck、test-gate、CI 本機照跑、拋棄式 repo 的 gate 輸出都已確認，沒有重跑。
- 相關檔案（都在 /Users/danlio/project/my_project/claude-dd 底下）：commands/dd-init.md、README.md、README.zh-TW.md、docs/measurements/2026-10-23-reviewer-real-sessions.md。
````

## 處置

- **B1 dd-init:46 差異串的 rev 5、rev 9 仍把裁決者寫成現行**（同 c-1）：採納、Important。rev 5 括號補「rev 11 再拿掉裁決者」；rev 9 改成「缺先備 diff 檔、最少 3 個審查者…（rev 10 是由裁決者派，rev 11 改成主對話直接派）」
- **B2 README 把結論講成定論、沒提費用**：採納、Important。兩份 README 改成「直接派比較快、命中沒有比較少，但比較貴；同時改了三件事、次數少，只是方向」
