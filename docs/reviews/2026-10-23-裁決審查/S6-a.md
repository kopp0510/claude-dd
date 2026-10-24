# S6-a — 步驟 4 改成 A（審查者 a：模板與蓋章版）

## 派工

主對話給它的派工 prompt（逐字；路徑換成 `<scratchpad>`）。三個審查者在同一則訊息平行派出（`subagent_type: "code-reviewer"`，不帶 model；紀錄檔 agentType code-reviewer、spawnDepth 1）。

````text
8 步迴圈步驟 4 的審查者（代號 a）。repo：/Users/danlio/project/my_project/claude-dd（專案規則在根目錄與各層 CLAUDE.md）。
這段（S6）把步驟 4 的 code-review 從「另派裁決者，由它派審查者」改成「主對話直接派審查者、自己查證」，依據是 docs/measurements/2026-10-23-reviewer-real-sessions.md「拿掉裁決者的對照」與實測用的任務說明 docs/measurements/2026-10-24-s5-inputs/direct.txt。計畫與小任務在 docs/designs/2026-10-23-裁決審查-design.md 的「### S6」。

diff 檔：<scratchpad>/S6-review-diff.txt（共 4517 行）。
- Read 一次讀太多會靜靜截斷、不報錯（約 47 KB 就停）。一律用 Read 的 offset／limit 每次 300 行讀；第 1–360 行（① 整段 diff 與 ② simplifier 的改動）一定要全讀；第 361 行以後是被改到檔案的整檔內容（帶行號），照需要讀；第 4511 行以後是 ④ 已跑過的驗證。
- 被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。
- ④ 列的驗證已確認，不要重跑。

你的方向：templates/global/CLAUDE.md §3.9 步驟 4 與 commands/dd-init.md 蓋章區塊（第 52–149 行）。查：新規則是不是忠實表達 A（對照 direct.txt 與量測文件）、數字與量測文件對不對得上、拿掉裁決者後有沒有哪個原本由裁決者負責的動作沒人接（例如報告逐字落地、不完整就不續行、補派）、同一節前後有沒有自相矛盾、蓋章版與模板有沒有講不一樣。

職責：找漏洞、證明這次改動有錯。每條附證據（diff 檔行號、或 repo 檔案行、grep 結果），沒證據的不算。只用手上的資料判斷，需要外部查證的列出來交回、不要自己去抓。不要改任何檔、不 commit。
交回：分級 Critical / Important / Smells，每條附證據；另列 Not reported（看到但判為不報的，附理由）與 What I ran（跑過的指令）。
````

## 發現

審查者交回的原文（逐字，從 subagent 紀錄檔的交回訊息取出）：

````text
Critical 0 / Important 4 / Smells 0。審查範圍：S6 的 diff（git diff fb6f816，含工作目錄），重點看 templates/global/CLAUDE.md §3.9 步驟 4 與 commands/dd-init.md 蓋章區塊（52–149 行）。diff 全是規則文字、沒有新的程式結構，所以沒套 Fowler 壞味道清單。

[Important] templates/global/CLAUDE.md:291 對上 :296（diff 檔 3902、3907）。同一節對「某個審查者缺報告、又補派不回來」給了兩種結局。
  Failure：:291 寫「補不了就照實寫進報告，不能當作它沒有發現」，照這句是記一筆然後續行；:296 寫「有審查者的報告不完整又補不了 → 不算跑過步驟 4，照實說，不續行」。審查者沒回來，本身就等於報告不完整，讀的人判斷不了該續行還是停下。
  Evidence：direct.txt 第 3 步只寫「補不了就照實寫進報告」；S6-1 計畫（diff 檔 164–165）寫「補派，補不了照實寫」，兩處都沒有「不續行」。舊版的「不續行」是針對裁決者沒回來（diff 檔 278），現在已經沒有對應的角色，卻被移到每個審查者身上。蓋章版 dd-init.md:112 對上 :113（diff 檔 112–113）是同一個矛盾。

[Important] docs/designs/2026-10-23-裁決審查-design.md:169、:173（diff 檔 3016、3020）。S6 自己寫的驗收條件，照字面不成立。
  Failure：驗收寫的是 `grep -E '裁決|judge'` 只剩 `-judge.md` 檔名那幾行，進度表那列（:136）寫「只剩白名單」，但白名單（:184）沒有「為什麼不另派裁決者」這種理由句。照現況把 S6 標 DONE，就是 §3.9 ① 講的「自己填、等於自證」。
  Evidence：`sed -n '/^### 3\.9/,/^> 步驟 1/p' templates/global/CLAUDE.md | grep -nE '裁決|judge'` 命中模板 297–300 行（為什麼不另派裁決者、另派一個 Opus 裁決者、拿掉裁決者、「拿掉裁決者的對照」），都不是檔名行；`grep -nE '裁決|judge' commands/dd-init.md` 命中蓋章區塊 :86「不另派裁決者：…」。④ 的驗證沒有列這條 grep。

[Important] commands/dd-init.md:113–114（diff 檔 113–114）。蓋章版少了模板和 direct.txt 都有的兩樣東西。
  Failure：(a) :114 只寫 269s 對 350s、命中 4/6 對 3/6，把唯一變差的一軸費用拿掉了（US$5.13 對 3.83）；模板 :298、CHANGELOG（diff 檔 15）、設計文件 :144 都有寫費用。(b) :113 沒有「預設『這條可能是錯的』」（模板 :293、direct.txt 第 4 步都有）。拿掉裁決者以後，查證的人就是寫這段 diff 的主對話，這句是唯一壓住「作者自己驗收自己」的句子。而已蓋章的專案讀的是專案 CLAUDE.md（優先序第 3），會照少了這兩樣的版本做。
  Evidence：讀了 diff 檔 112–114，對照模板 3903–3911（:292–300）與 direct.txt。

[Important] templates/global/CLAUDE.md:292–293、:322（diff 檔 3903–3904、3933）。原本由裁決者負責的「保存派工 prompt」，拿掉裁決者後沒人接手。
  Failure：舊規則要裁決者把報告「連同它給審查者的派工 prompt」一起交回（diff 檔 277、110）。新規則只要求把審查者報告存進 scratchpad，理由是「context 被壓縮後也還在」，卻沒要求存派工 prompt。可是 `-a/-b/-c.md` 的「派工」一節要照給它的派工 prompt 寫（模板 :322、docs/reviews/CLAUDE.md 第 214 行），壓縮以後只能憑記憶重寫。
  Evidence：上面列的這幾行；`grep -n '派工 prompt'` 在新版模板 §3.9 與蓋章區塊都沒有「存檔」的指示。蓋章版 :113 同樣只存報告。

數字對照：量測文件 274–400 行裡的 269s/350s、US$5.13/3.83、命中 4/6 對 3/6、「G2、G3 兩段 diff 各 2 發」、「3 個可計分的已知錯誤 × 2 發 = 6 次機會」，以及量測文件第 209 行的 3024 行只回 544 行，模板與 CHANGELOG 都對得上。rev 11 在 dd-init.md 的 :83、:84、:100 和 UPGRADING.md:82 都一致。蓋章區塊與模板 §3.9 裡的「交回」一詞，剩下的都是審查者交回給主對話或交回給使用者，沒有暗示還有另一個代理。

What I ran
- Read diff 檔 1–180、180–360、4505–4519、3855–3974（模板 §3.9）、2743–3042 → 全讀完
- cat docs/measurements/2026-10-24-s5-inputs/direct.txt → 取得 A 的完整指示
- grep -n '拿掉裁決者的對照' 量測文件；sed -n '274,400p' 量測文件 → 數字逐項對上
- grep -n '^=====' 與 '^----- FILE' diff 檔 → 各區段的起始行
- grep -n '3024\|544 行\|47 KB' 量測文件 → 第 207–213 行
- sed -n '/^### 3\.9/,/^> 步驟 1/p' templates/global/CLAUDE.md | grep -nE '裁決|judge'；grep -nE '裁決|judge' templates/global/CLAUDE.md commands/dd-init.md → 命中 297–300、320–323；dd-init :46、:86、:90
- grep -n '^```' commands/dd-init.md | head -2 → 52、149
- grep -nE 'rev…|rev 比' UPGRADING.md → :82「rev 比 11」
- python3 算每個 300 行視窗的位元組數（diff 檔與 5 份檔）→ diff 檔最大 50089 B（從 2743 行起），從第 1 行起每 300 行一切都不超過 46584 B，有 99 個非對齊視窗超過 47065 B
- Read offset 2743 limit 300 → 完整回到 3042 行，沒有截斷
- 蓋章區塊與模板 §3.9 各 grep '交回' → 只剩合法用法

Not reported
- 「約 47 KB 就停」：我帶 limit 讀 300 行、50089 B 完整回來，表示 47 KB 管不到帶 limit 的讀法。但只有 n=1，量測文件也寫明上限的單位沒查，模板引的是不帶 limit 的實測，所以不算錯。
- README、gate echo、docs/reviews/CLAUDE.md、CHANGELOG 不在我的方向內，只順帶看過，沒有深查。DD_PIPELINE_ARCHITECTURE.md 等其他檔有沒有殘留的「裁決」沒有查：要查就跑 `git grep -nE '裁決|judge' -- ':!docs/measurements' ':!docs/reviews' ':!CHANGELOG.md'`。
- 「靠查證那一步才識破」把當年裁決者的實例改寫成泛稱，語意還準，不報。

相關檔案：<scratchpad>/S6-review-diff.txt、/Users/danlio/project/my_project/claude-dd/templates/global/CLAUDE.md、/Users/danlio/project/my_project/claude-dd/commands/dd-init.md、/Users/danlio/project/my_project/claude-dd/docs/measurements/2026-10-24-s5-inputs/direct.txt、/Users/danlio/project/my_project/claude-dd/docs/measurements/2026-10-23-reviewer-real-sessions.md
````

## 處置

- **A1 補不了續行 vs 不續行矛盾**（同 c-2）：採納、Important。模板與蓋章版統一成「沒回來或報告不完整 → 補派，補不了照實寫；收回的完整報告少於 3 份 → 不算跑過步驟 4、不續行」
- **A2 驗收照字面不成立**（同 c-3）：採納、Important。設計文件白名單補「為什麼不另派裁決者」這類理由句與歷史句，並註明英文 README 要 grep `adjudicat`
- **A3 蓋章版少了費用與「預設這條可能是錯的」**：採納、Important。蓋章版補 US$5.13 對 3.83 與「直接派比較貴」；查證那條補「預設這條可能是錯的；查證的人就是寫 diff 的人，要駁回就讀程式碼證明」。模板同步加一句 ⚠️
- **A4 派工 prompt 沒人保存**：採納、Important。模板與蓋章版改成「派工 prompt 派出時、每個審查者的報告一回來，都逐字存進 scratchpad」
