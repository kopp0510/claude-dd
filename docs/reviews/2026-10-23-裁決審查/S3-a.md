# S3-a — code-review 改裁決結構

## 派工

裁決者給審查者 a 的派工 prompt（共用部分逐字，加上方向句）。範圍：`git diff 6e9aaf0 92eea63`。

方向：模板 §3.9 步驟 4 和 dd-init 蓋章版步驟 4 的語意一致性與自洽，以及和 `agents/code-reviewer.md` 對不對得上（184s／12 次工具）

```text
你是 claude-dd repo（/Users/danlio/project/my_project/claude-dd）段落 S3「code-review 改裁決結構」的審查者。

## 範圍與取檔
- diff 檔：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S3_review_bundle.txt
  （約 4150 行；第 1–443 行是 `git diff 6e9aaf0 HEAD`，第 444 行起是每個被改到檔案的整檔內容，帶行號，以 `----- FILE: <路徑>` 分隔）。
- **被改到的檔一律讀 diff 檔裡那一份，不讀工作目錄**。沒被改到的檔（例如 .github/workflows/ci.yml、tests/、skills/、agents/code-reviewer.md、DD_PIPELINE_ARCHITECTURE.md、diagrams/src/）照常讀 repo。
- 專案規則：repo 根目錄 CLAUDE.md、scripts/CLAUDE.md、docs/reviews/CLAUDE.md（後兩份被改到，讀 diff 檔那份）。
- 計畫與三輪計畫審查：docs/designs/2026-10-23-裁決審查-design.md 的 S3 一節（在 diff 檔裡）。

## 你的職責
找漏洞、證明這次改動有錯。每條附證據（diff 檔行號或 repo 檔案:行、grep 結果原文），**沒證據的不算**。
分級 Critical / Important / Smells；判成「既有問題、不是這次引入的」也要列出來（放 Not reported 並附行號），由裁決者判。
只用手上的資料判斷；需要外部查證的（例如實際派 agent 跑、上網查）列出來交回、不要自己去做。不設工具次數上限。不准改 repo 任何檔、不 commit。

## 已確認，不要重跑（2026-10-24 本輪實跑）
- 本機照跑 ci.yml 的「迴圈步數四方一致」「迴圈步數第五方」「CHANGELOG 已發布區塊不可改動」三個 step（指令用 ruby -ryaml 從 ci.yml 原文取出）：都 exit 0；四方輸出「全域模板 §3.9=8 dd-init 蓋章版=8 README.md=8 README.zh-TW=8 標記=8step」「✅ 四方一致，版本標記與 dd-loop-rev（含舊版判定線的 rev）都對得上」
- `shellcheck -S warning scripts/check-claude-md.sh` 通過；`bash tests/test-gate.sh` exit 0
- 舊句逐句 `grep -cF` 都回 0：
  - 模板步驟 4 範圍（`sed -n '/^### 3\.9/,/^> 步驟 1/p' templates/global/CLAUDE.md`）：派兩個 reviewer 跑同一份 prompt／兩份報告對同一處講不一樣時／最多做一次重現實驗／git show／兩份報告一律落地成 committed 檔／S<段落>-{a,b}.md／13–17 分鐘 ×2 發／成本 ×2
  - dd-init 蓋章區塊（第一、二個 ^``` 之間）：派兩個 reviewer 跑同一份 prompt／兩份報告講不一樣時／最多做一次重現實驗／git show／兩份報告落地成 committed 檔／S<段落>-{a,b}.md／成本 ×2／781s 與 1007s／13–17 分鐘 ×2
  - scripts/check-claude-md.sh、docs/reviews/CLAUDE.md、兩份 README 各自的舊句清單
- 保留項還在：模板步驟 4 範圍的 2.3/3、1.8/3；`grep -cF '同時打兩發' templates/global/CLAUDE.md` = 1；蓋章區塊的 2.3/3 與「兩個 reviewer 抓出 2 個 Critical」；S6-{a,b}.md 兩處

## 交回格式
- Critical / Important / Smells：每條「位置（diff 檔行號或 檔:行）｜內容｜證據原文｜失敗情境｜建議改法」
- Not reported（含判成既有問題的，附行號與理由）
- 需要外部查證
- What I ran（你實際跑過的指令）
```

## 發現

（裁決者交回的逐字原文）

Critical 1 / Important 4 / Smells 0。審查範圍：S3 diff（`git diff 6e9aaf0 HEAD`，bundle 第 1–443 行），重點看全域模板 §3.9 步驟 4 與 dd-init 蓋章區塊步驟 4 這兩份。下文的行號都是 HEAD 版本，對應 bundle 裡的整檔內容。

## Critical

**C1**
- 位置：`templates/global/CLAUDE.md:280`
- 內容：寫了一句「實測」宣稱，但手上的量測不支持，量測文件還明說證明不了。
- 原文：「實測慢的審查時間大多花在一個檔一個檔撈 git,先備好就省掉這段」
- 證據有三處，都說這件事沒證實：
  - `docs/measurements/2026-10-23-reviewer-real-sessions.md:112–115`：「所以這份數據**證明不了**『慢是因為逐檔撈 diff』」；「『派工前把整段 diff 準備成一個檔交給它』是根據結論 2 的**推論**…效果要等 S4…才算數」
  - 設計文件（bundle 2302 起）第 38–39 行：「『先交 diff 能加速』是推論，S4 才驗」
  - 設計文件第 117 行：「先交 diff 能快多少…實作後拿舊 diff 量（S4 的驗收）」
- 失敗情境：
  - 這句是在替「先備 diff 檔」辯護，套全域模板 §3.10「辯護性的註解…最危險」那條。讀的人會把 S4 要驗的假設當成已經證實。
  - S4 量出來不快的話，模板已經把相反的結論部署到每個專案。
  - 這句違反 §2.4「禁止把推論包裝成事實」。
  - dd-init 蓋章版與兩份 README 沒有這句，所以兩份也不一致。
- 建議：改成「推論：git 類工具佔大宗，先備好至少省掉撈 diff 那部分；效果待量測（見 docs/measurements/…）」，或整句刪掉。

## Important

**I1**
- 位置：`commands/dd-init.md:85`、`commands/dd-init.md:88`，對照 `templates/global/CLAUDE.md:287–288`、`templates/global/CLAUDE.md:300`
- 內容：蓋章版的裁決段比模板少了三個限定詞，而且主詞含糊。蓋章版會蓋進專案 CLAUDE.md，優先序比全域高（UPGRADING:54–55）。
- 模板原文：
  - 「完整報告(含 Not reported、What I ran)逐字寫進 scratchpad」
  - 「裁決者沒回來或報告不完整 → 不算跑過步驟 4,照實說,不續行」
  - 「(附選項與建議答案)」
- 蓋章版原文：
  - 「完整報告逐字寫進 scratchpad 檔並交回路徑；沒回來或報告不完整 → 不算跑過步驟 4，照實說」：沒有「不續行」，「沒回來」也沒有主詞。
  - 第 88 行只有「裁決者標成『需使用者決定』，由主對話問」。
- 失敗情境：
  - 已蓋章的專案照第 85 行做：裁決者沒回來時照實說了，但沒寫要停下，主對話可以照樣進步驟 5、6。模板明寫「不續行」。
  - 「沒回來」緊接在「裁決者把每個審查者的…報告」之後，也能讀成「某個審查者沒回來」。這樣講的是另一件事：有一個審查者失敗，整個步驟 4 就作廢。
- 建議：第 85 行補上「裁決者」「(含 Not reported、What I ran)」「不續行」；第 88 行補「附選項與建議答案」。

**I2**
- 位置：`templates/global/CLAUDE.md:277`、`templates/global/CLAUDE.md:279`；`commands/dd-init.md:83`
- 內容：「上面那條」指錯對象。
- 原文：模板第 277 行「內容:上面那條的整段 diff」、第 279 行「以及上面那條要附的驗證輸出」，兩處都寫「上面那條」，卻指兩個不同的子項。
- 實際情況：
  - 緊鄰的上一條是第 274–276 行「派工的 prompt 交事實」，裡面既沒有 diff 範圍，也沒有驗證輸出。
  - 範圍在第 262 行，往上數第四條；驗證輸出在第 265 行，往上數第三條。
  - dd-init 第 83 行「上面那條要附的驗證輸出」也一樣：上一條是第 80–82 行，驗證輸出那條在第 76 行。
- 失敗情境：照字面讀，「上面那條的整段 diff」會找到「交事實」那條，那裡沒有範圍。§3.10 對引用別處的敘述要求逐處核對。
- 建議：改成「步驟 4 第一條的範圍」「第二條要附的驗證輸出」，或直接寫出內容。dd-init 的 diff 範圍已經寫在行內，只需要改驗證輸出那半句。

**I3**
- 位置：`templates/global/CLAUDE.md:285–288`、`commands/dd-init.md:85`，對照 `templates/global/CLAUDE.md:266–267`、`templates/global/CLAUDE.md:293`、`commands/dd-init.md:86`
- 內容：審查者被要求把外部查證「列出來交回」，但裁決者只有三類可分，沒有地方放這種項目。
- 原文：
  - 模板第 293 行：「prompt 寫明『只用手上的資料判斷,需要外部查證的列出來交回』」
  - 第 266–267 行（沒改到的子項）：「需要你沒給的輸出時它會列出要查什麼交回來」。現在審查者交回的對象是裁決者，不是主對話。
  - 第 285 行：「分三類:採納 / 駁回 / 需使用者決定」
- 對照：plan-review 的裁決報告有第四類「需要外部查證」，見 bundle 第 311 行 plan-S3-r3「【需要外部查證】小事 1 條」。
- 失敗情境：審查者交回「要跑 X 才能確定」。裁決者照「沒證據不算」把它駁回，或者丟掉。主對話從頭到尾看不到這個待查項。這正是本段要求審查者「列出來交回」的那一種。
- 建議：三類後面補一句「審查者列的外部查證項，裁決者能查就查，查不了另列『需要外部查證』交回主對話」，兩份同改。

**I4**
- 位置：`templates/global/CLAUDE.md:278–279`、`commands/dd-init.md:83`
- 內容：「未追蹤的新檔放整檔」沒寫只適用於依序跑。
- 原文：「(依序跑時取工作目錄版本…;與步驟 3 並行時取 `HEAD` 版本,因為 simplifier 正在改工作目錄;未追蹤的新檔放整檔)」
- 為什麼有問題：
  - 並行時的範圍是 `git diff <起點> HEAD`，本來就不含未追蹤檔。
  - 步驟 2 已經 commit，並行時工作目錄裡的未追蹤檔只會是 simplifier 正在寫的。
- 失敗情境：並行跑時，simplifier 正在新建一個 helper 檔。照字面「未追蹤的新檔放整檔」，會把寫到一半的檔收進 diff 檔，跟同一句「simplifier 正在改工作目錄」的理由矛盾。
- 建議：改成「依序跑時另把未追蹤的新檔放整檔」。

## Not reported

- `docs/reviews/CLAUDE.md:31` 要求「審查者報告末尾加一節各審查者獨有項」，第 28 行要求「多個審查者抓到同一項要標出來」。但審查者是平行跑的，報告又是「照裁決者交回的完整報告落地」，而且第 39 行規定前兩節寫完不改。誰來寫這兩樣、寫在哪裡，沒有定義。這不在本輪重點，請裁決者判要不要升級。
- 審查者的 model：兩份都沒寫。設計 S3-1 寫的是「code-reviewer，Opus」。`agents/code-reviewer.md` 的 frontmatter 是 `model: opus`，裁決者不覆寫就會是 Opus。plan-S3-r1 已經駁回過「opus 覆寫」那條，所以不報。
- 某個審查者（不是裁決者）失敗或沒回來怎麼辦，兩份都沒定義。只有「等全部回來」這句。
- 採納的「需使用者決定」項擋不擋續行，沒寫。第 261 行的標題只說 Critical/Important。
- `CHANGELOG.md` 未發布條目（bundle 第 13–14 行）：「…詢問升級」和下一行「兩份 README…」之間沒有標點，Markdown 渲染時會黏成一句。只影響外觀。
- 既有問題：`commands/dd-init.md:46` 的 rev 差異清單沒有 rev 7。這不是本次引入的。
- 跟 agent 定義對得上：Critical / Important / Smells 三級、Not reported、What I ran、Scope Discipline 都存在（`agents/code-reviewer.md:14, 84–85, 76, 100, 109, 111`）。
- 沒有遺漏的舊指涉：在 diff 以外 grep 過 `兩個 reviewer`、`{a,b}`、`-b.md`、`取聯集`、`git show HEAD:`，只剩刻意保留的歷史句和 tests/ 的情境。`diagrams/src/gen_loop.py` 的步驟 4 沒寫審查者數量。

## 需要外部查證

- 無。

## What I ran

- `sed -n '1,443p' S3_review_bundle.txt` → 讀完整份 diff
- `grep -n '^----- FILE' S3_review_bundle.txt` → 拿到各檔在 bundle 裡的起始行
- `sed -n '1966,2140p'`（dd-init 整檔）、`awk 'NR>=3266' | sed -n '238,340p'`（模板 §3.9）→ 逐行比對兩份步驟 4
- `head -8 agents/code-reviewer.md` 加上 grep 級別名、Not reported、What I ran、Scope Discipline → 都在，`model: opus`
- 在設計文件那段 bundle 裡 grep `撈|上限|快多少` → 第 38–39、117 行寫「推論，S4 才驗」
- `sed -n 100,120p docs/measurements/2026-10-23-reviewer-real-sessions.md` → 第 112–115 行「證明不了」「推論」
- `git grep` 舊指涉（排除 docs/reviews、CHANGELOG、docs/designs）→ 只剩刻意保留的項目
- `grep -i review diagrams/src/*.py` → 步驟 4 的圖說沒寫審查者數量
- `sed -n '2690,2741p'`（docs/reviews/CLAUDE.md 整檔）→ 就是 Not reported 第一條

## 處置

- 採納，對應 `S3-judge.md` 的第 1（Critical）、2、3、4（Important）、5、6（降為 Smells）、11 條：全部照改
- Not reported「需使用者決定擋不擋續行」「dd-init 沒有 rev 7」：裁決者駁回
