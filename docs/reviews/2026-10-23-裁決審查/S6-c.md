# S6-c — 步驟 4 改成 A（審查者 c：rev 跳號、CHANGELOG、設計文件）

## 派工

主對話給它的派工 prompt（逐字；路徑換成 `<scratchpad>`）。三個審查者在同一則訊息平行派出（`subagent_type: "code-reviewer"`，不帶 model；紀錄檔 agentType code-reviewer、spawnDepth 1）。

````text
8 步迴圈步驟 4 的審查者（代號 c）。repo：/Users/danlio/project/my_project/claude-dd（專案規則在根目錄與各層 CLAUDE.md）。
這段（S6）把步驟 4 的 code-review 從「另派裁決者，由它派審查者」改成「主對話直接派審查者、自己查證」，依據是 docs/measurements/2026-10-23-reviewer-real-sessions.md「拿掉裁決者的對照」。計畫與小任務在 docs/designs/2026-10-23-裁決審查-design.md 的「### S6」。

diff 檔：<scratchpad>/S6-review-diff.txt（共 4517 行）。
- Read 一次讀太多會靜靜截斷、不報錯（約 47 KB 就停）。一律用 Read 的 offset／limit 每次 300 行讀；第 1–360 行（① 整段 diff 與 ② simplifier 的改動）一定要全讀；第 361 行以後是被改到檔案的整檔內容（帶行號），照需要讀；第 4511 行以後是 ④ 已跑過的驗證。
- 被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。
- ④ 列的驗證已確認，不要重跑。

你的方向：rev 跳號、升級說明、CHANGELOG、設計文件。根 CLAUDE.md「動到 commands/dd-init.md 的蓋章區塊就必須同步跳 dd-loop-rev」那條列了必改的幾處（兩處 dd-loop-rev、兩檔的「rev 比 N 舊」、「列出與現行版的差異」串、UPGRADING.md 寫死的 rev、CHANGELOG 未發布），逐處核；CHANGELOG 新條目與改寫的舊條目講的對不對（rev 10 沒發布過）、數字與量測文件是否一致；設計文件 S6 的進度表列、設計決策新列、S6 節的驗收寫法，跟實際做的對不對得上、照它驗會不會抓得到錯。

職責：找漏洞、證明這次改動有錯。每條附證據（diff 檔行號、或 repo 檔案行、grep 結果），沒證據的不算。只用手上的資料判斷，需要外部查證的列出來交回、不要自己去抓。不要改任何檔、不 commit。
交回：分級 Critical / Important / Smells，每條附證據；另列 Not reported（看到但判為不報的，附理由）與 What I ran（跑過的指令）。
````

## 發現

審查者交回的原文（逐字，從 subagent 紀錄檔的交回訊息取出）：

````text
Critical 0 / Important 3 / Smells 0. 範圍是 S6 整段，也就是 diff 檔 1–360 行（git diff fb6f816 加上 simplifier 自己改的部分）。對照的資料：repo 的 v1.6.5 tag、docs/measurements/2026-10-23-reviewer-real-sessions.md、docs/designs/2026-10-23-裁決審查-design.md。

[Important] commands/dd-init.md:46，「列出與現行版的差異」那一串還寫著舊的裁決結構，沒有改。
  失敗情境：已發布的 v1.6.5 是 rev 9（`git show v1.6.5:commands/dd-init.md` 的第 39、54 行都是 `dd-loop-rev: 9`），所以實際會遇到升級的專案都是 rev 9 以前的。升級對話框會告訴它們「rev 9 … 缺『先備 diff 檔、由裁決者派最少 3 個審查者並逐條查證』」，rev 5 那條也還附著「（rev 10 已由裁決結構取代）」。但現行的 rev 11 已經不用裁決者了，使用者看到的是一個已經不存在的版本差異。
  證據：diff 檔第 91 行。這次只在串尾補了 rev 10 那一句，rev 9 和 rev 5 的描述原封不動。house 的前例是，條目被後來的 rev 取代時要補括號註記，例如 rev 5、rev 6 的「（rev 10 已…）」；CHANGELOG 的 rev 10 條目這次也補了「（同一版內已由下一條 rev 11 取代…）」（diff 檔第 12 行）。dd-init 的 rev 9、rev 5 兩條卻沒有跟著補。

[Important] 「審查者補不了」的處理在兩行之間前後矛盾：templates/global/CLAUDE.md:282 對 :287（diff 檔第 282 行對第 287 行），dd-init 蓋章版對應的是 diff 檔第 112 行對第 113 行。
  失敗情境：審查者完全沒回來時，規則是「補派，補不了就照實寫進報告，不能當作它沒有發現」，也就是可以續行；審查者回來了、但報告不完整時，規則卻是「不算跑過步驟 4，照實說，不續行」。結果是比較嚴重的情況（完全沒回來）可以續行，比較輕的情況（報告不完整）反而要停下來。
  原因：舊版「報告不完整 → 不算跑過」講的是裁決者的報告（diff 檔第 278 行「裁決者沒回來或報告不完整」）。這次把主詞直接換成審查者，就跟上一條撞在一起。這也跟設計文件不一致：S6-1 那段（diff 檔第 165 行）寫的是「有審查者沒回來或報告不完整 → 補派，補不了照實寫，不能當作它沒有發現」，兩種情況同一個處置。

[Important] 設計文件 S6 的驗收條件，照字面執行會在正確的內容上失敗。換句話說，這些驗收要嘛沒有照字面跑過，要嘛照著跑會讓人去刪掉該留的說明。
  失敗情境：進度表 S6 那一列（diff 檔第 136 行）要求 `git grep -E '裁決|judge'` 只剩白名單；S6-1 要求只剩 `-judge.md` 檔名那幾行（第 169 行）；S6-2 同樣只准剩 `-judge.md` 檔名（第 173 行）；S6-4 要求兩份 README 只剩 plan-review 那一列（第 181 行）。但這次刻意新增的說明句會命中，而且不在第 184 行的白名單裡。
  證據：`git grep -n -E '裁決|judge' … | grep -v -- '-judge\.md'` 會命中這幾處：
  - templates/global/CLAUDE.md:297–300「為什麼不另派裁決者」
  - commands/dd-init.md:86「不另派裁決者：…」（在蓋章區塊內）
  - README.zh-TW.md:130「中間不另派裁決者…」
  另外兩處因為同一行有 `-judge.md`，被上面的過濾排除了，人工看過也屬同類：docs/reviews/CLAUDE.md 的「當時另派的裁決者寫的」，以及 scripts/CLAUDE.md 的「改成裁決式，同日 S6 拿掉裁決者」。
  反方向也有漏洞：英文 README 用的是 `adjudicator`，不是 `judge`（README.md:125、:194），所以 S6-4 對 README.md 的 grep 永遠是 0 筆。就算英文段落留著舊的裁決者描述，這條驗收也抓不到；而它說會留下的「plan-review 那一列」在 README.md 根本命中不到。

逐處核過、沒問題的部分：
- 規則要求必改的幾處 rev 都已跳到 11：dd-loop-rev 兩處（dd-init.md 的第 39、54 行）、「rev 比 11」兩檔各一處（dd-init.md:40、UPGRADING.md:82）、UPGRADING 唯一寫死的 rev 值。
- CHANGELOG 的條目都寫在 `## 未發布`，說「rev 10 沒發布過」也正確，已用 v1.6.5 tag 核過。
- CHANGELOG、模板、蓋章版、設計決策列裡的數字（269s／US$5.13／4/6 對 350s／US$3.83／3/6，3024 行只回 544 行，約 47 KB）都跟量測文件「五組並排」那張表和 S4 第 209–210 行一致。

What I ran：
- Read diff 檔第 1–364 行，再用 tail 看第 4505 行以後 → 讀到 ① ② 的全部內容和 ④
- `git status --short; git log --oneline fb6f816..HEAD` → 4 個 S6 commit，另有 2 個工作目錄的修改
- `git show v1.6.5:commands/dd-init.md | grep -n dd-loop-rev` → 第 39、54 行都是 rev 9
- `git grep -n 'rev 1[01]|…' -- CHANGELOG.md UPGRADING.md commands/ .github/` → rev 必改的幾處都已更新
- `git grep -n -E '裁決|judge' -- <7 檔> | grep -v -- '-judge\.md'` → 命中 README.zh-TW:130、:219、dd-init:86、模板 :297–300、:321
- `grep -n -i 'judge\|adjudic' README.md` → 只有 :125、:194 的 adjudicator
- `sed -n '274,360p'`，以及讀 S5「結論／限制」那兩節（docs/measurements/2026-10-23-reviewer-real-sessions.md）→ 數字吻合
- `grep -n '3024\|544\|47 KB'`（同一份量測文件）→ 吻合第 207–210 行
- `grep -n -E '裁決|judge|rev' UPGRADING.md`；`sed -n '30,60p' CHANGELOG.md` → 沒有其他殘留

Not reported：
- 模板 :299 只把命中的差距註明「只是方向」，速度的比較沒有一起加上量測文件限制裡寫的「S4 一批三發、S5 一批兩發，不同時段跑」。但模板有附「數字與限制見…」的指向，不構成錯誤。
- 量測文件 S5 記錄 G3 的 15 個審查者裡 13 個即使被要求讀完全檔，第二段仍沒讀完。這次新規則只說要讀到最後一行，沒有宣稱這樣做有效，所以不報。
- dd-init 的差異串本來就沒有 rev 7 的條目，這是既有問題，不是這次引入的。
- 設計文件提到「計畫審查第 1 輪通過、小事 13 條」，手上的資料無從查證，需要的話去看 S6 計畫審查的原始報告核對。
````

## 處置

- **C1 dd-init:46 差異串過期**（同 b-1）：採納，處置見 `S6-b.md` B1
- **C2 補不了的處置前後矛盾**（同 a-1）：採納，處置見 `S6-a.md` A1
- **C3 設計文件驗收照字面不成立、英文 README 用 adjudicator**（同 a-2）：採納，處置見 `S6-a.md` A2
