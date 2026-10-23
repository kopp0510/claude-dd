# S3-b — code-review 改裁決結構

## 派工

裁決者給審查者 b 的派工 prompt（共用部分逐字，加上方向句）。範圍：`git diff 6e9aaf0 92eea63`。

方向：rev 跳號、dd-init／UPGRADING／CHANGELOG 的同步規則，以及全 repo 手動同步區塊有沒有漏改（144s／10 次工具）

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

Critical 0 / Important 3 / Smells 0。範圍：`git diff 6e9aaf0 HEAD`（S3，HEAD=92eea63）。重點看了 rev 跳號、同步規則，也掃了整個 repo 有沒有手動同步區塊漏改。

**rev 跳號機械項全部到位**：
- `dd-loop-rev` 兩處都改成 10（bundle 第 67、84 行）。
- 「rev 比 10 舊」在 `commands/dd-init.md` 一處（bundle 第 68 行）、`UPGRADING.md` 一處（bundle 第 53 行）。
- `UPGRADING.md` 寫死 rev 值的只有那一行，`git grep` 確認過。
- CHANGELOG 只在 `## 未發布` 加了行，沒動到 `## 1.6.5`（bundle 第 10–14 行，hunk 結尾就是 1.6.5 標題）。

**[Important] templates/global/CLAUDE.md:280（bundle 第 397 行）把量測文件明說「證明不了」的推論寫成「實測」**
- 內容：新句「實測慢的審查時間大多花在一個檔一個檔撈 git,先備好就省掉這段」。
- 證據：
  - `docs/measurements/2026-10-23-reviewer-real-sessions.md` 結論 2 原文：「這份數據**證明不了**『慢是因為逐檔撈 diff』」。結論 3 原文：「『派工前把整段 diff 準備成一個檔交給它』是根據結論 2 的**推論**…效果要等 S4…才算數」。
  - 設計文件第 39 行：「『先交 diff 能加速』是推論，S4 才驗」。
  - `docs/reviews/2026-10-23-裁決審查/S1-a.md:32` 的處置：「『逐檔撈』改標推論」。這句宣稱 S1 已經撤回過，這次又以「實測」寫回來。
- 失敗情境：這句會經 `--force` 部署到每台機器的 `~/.claude/CLAUDE.md`。讀者會把「先備 diff 能加速」當成已驗證，S4 的新舊對照就失去被質疑的動機。這正是 §3.10「歸因要能被反證」與 §2 不可捏造要擋的情況。
- 建議：改成「推論：git 類佔工具呼叫大宗，先備好至少省掉撈 diff 那部分；效果待 S4 量」，或整句刪掉。`dd-init` 蓋章版沒有這句，不用改。

**[Important] commands/dd-init.md:46（bundle 第 75 行）：「列出與現行版的差異」裡較早的 rev 條目，在 rev 10 下已經跟現行版矛盾；新補的 rev 9 句也不準**
- rev 5／rev 6 條目的問題：
  - rev 5 條目仍寫「缺步驟 4 的『派兩個 reviewer 取聯集』」。rev 6 條目仍寫缺「界定探索預算」、「並行 wall 寫成未實測的推論」。
  - 這三樣現行版都沒有了：取聯集被裁決者取代，「界定探索預算」改名成「時間花在哪」，並行 wall 那句已刪（bundle 第 92–99 行）。
  - 同一串裡的 rev 9 句又寫「rev 9 的步驟 4 是『派兩個 reviewer 取聯集』」。
  - 失敗情境：rev ≤5 的專案跑 `/dd-init`，AskUserQuestion 的差異清單會同時說「你缺『派兩個取聯集』」和「rev 9 的取聯集已被取代」，使用者是在互相矛盾的說明下決定要不要升級。
  - 計畫第 164 行只決定保留「界定探索預算」這幾個字，沒處理語意上的矛盾。§3.9 有一條「diff 動到的每一個識別符…核『這句話在 HEAD 還成立嗎』」，這裡沒做到。
- rev 9 句本身的兩個問題：
  - 「還要求 prompt 寫『最多做一次重現實驗』」說過頭了。rev 9 原文是「prompt 寫明『最多做一次重現實驗』，**或**『需要外部查證的列出來交回…』」（bundle 第 93 行），是二選一，不是要求。
  - 漏了「並行時用 `git show HEAD:<路徑>` 取檔改成讀 diff 檔」這條差異（bundle 第 95 行被刪）。
- 建議改法（提案）：rev 5、rev 6 條目各補一句「（rev 10 已由裁決結構取代）」。rev 9 句的「要求」改成「建議」，並補上 `git show` 那條。

**[Important] CHANGELOG.md `## 未發布`（bundle 第 13–14 行）：新條目最後兩行接在一起、沒有斷句；升級前提也沒交代**
- 證據：「已蓋章的專案跑 `/dd-init` 會被判為舊版並詢問升級」後面沒有句號或分號，下一行「兩份 README『核心工作法』的步驟 4 說明同步改寫」是同一個 list item 的續行。渲染出來是「詢問升級 兩份 README…」，連成一句。
- 少了的升級前提：
  - 同一節的 plan-review 條目有寫「全域 CLAUDE.md 要 `./install-dd-pipeline.sh --force` 才會更新」，這條沒寫。可是步驟 4 改的正是全域模板、`/dd-init`、gate，三者都要 `--force` 才會到使用者手上。
  - 不先 `--force` 的話，跑 `/dd-init` 用的是部署版，會判定「已是現行版」（根目錄 CLAUDE.md 2026-10-02 踩過同一種情況）。
  - gate 阻擋訊息的改動（`scripts/check-claude-md.sh`，使用者看得到）也沒記。
- 建議：把「詢問升級」改成「詢問升級（要先 `./install-dd-pipeline.sh --force`）；gate 擋下時印的報告檔名同步改成 `-a/-b/-c…` 加 `-judge.md`；兩份 README…同步改寫」。

**手動同步區塊掃描：沒有漏改。**
- 掃的舊說法：兩個 reviewer、two reviewers、聯集、`{a,b}`、最多做一次重現、`13–17 分鐘 ×2`、成本 ×2、git show。
- 剩下的命中都是刻意保留，或是歷史紀錄：
  - `commands/dd-init.md:99`「兩個 reviewer 抓出 2 個 Critical」
  - `templates/global/CLAUDE.md:469`
  - `S6-{a,b}.md` 的歷史檔名
  - `docs/designs/2026-10-05-…:140`
- 這幾處描述的是步驟 4 本身，沒寫 reviewer 數量，不用改：
  - `diagrams/src/gen_loop.py:26,62`（步驟 ④ 文案：「本段 diff 全量跑／管正確性與合規／修掉才續行」）
  - `DD_PIPELINE_ARCHITECTURE.md:91`（只有箭頭摘要）
  - `skills/plan-review/SKILL.md`（講的是 plan-review 自己）
  - 兩份 README 的步驟 4 清單項（README.md:116、README.zh-TW.md:121）

**Not reported**
- `commands/dd-init.md:46` 的 rev 清單從 rev 6 直接跳到 rev 8，沒有 rev 7。這是既有問題，不是這次引入的。
- `tests/test-gate.sh:254` 的註解「補上 S<N>-a.md / -b.md」是測試 fixture。gate 判定樣式沒變，不算漏同步。
- `docs/reviews/CLAUDE.md` 新格式（bundle 第 338、348 行）有兩處沒寫清楚。這不在我這次的重點範圍內，留給其他審查者或裁決者判：
  - 審查者報告要「逐字落地」，卻又要有「派工／發現／處置」三節、末尾加「各審查者獨有項」，沒寫誰來補。
  - 審查者彼此看不到對方的報告，只能由主對話補。

**需要外部查證**：無。

**What I ran**
- Read `S3_reviewer_common.txt` → 讀完任務說明
- `sed -n '1,443p' S3_review_bundle.txt` → 讀完整份 diff
- `git grep -nE '兩個 reviewer|two reviewers|聯集|{a,b}|最多做一次重現|13–17 分鐘 ×2|成本 ×2|git show HEAD:<|界定探索預算…'`（排除 `docs/reviews`、CHANGELOG、本設計文件）→ 只剩上面列的刻意保留項
- `git grep -nE 'reviewer|審查者|code-review' -- skills diagrams/src DD_PIPELINE_ARCHITECTURE.md UPGRADING.md agents/code-reviewer.md tests .github` → 沒有講 reviewer 數量、需要同步的地方
- `sed -n` 看 `gen_loop.py` 第 24–30、60–66 行，加 grep README 步驟清單、grep `UPGRADING.md` 的 rev → `UPGRADING.md` 只有第 82 行一處，已改成 10
- `git grep -nE '撈 git|一個檔一個檔…'`，加 `sed -n 105,115p docs/measurements/2026-10-23-reviewer-real-sessions.md` → 找到第一條 Important 的反證
- `sed -n '1,60p' CHANGELOG.md` → 確認 `## 未發布` 的條目格式，沒動到 1.6.5
- `git grep -nE 'S<段落>-a|-a\.md|-b\.md…'` → 沒有漏改的報告檔名說明
- `sed -n '70,100p' commands/dd-init.md`，加 `git diff 6e9aaf0 HEAD --stat` → 蓋章區塊步驟 4 前後文正常

相關檔案：
- /Users/danlio/project/my_project/claude-dd/templates/global/CLAUDE.md
- /Users/danlio/project/my_project/claude-dd/commands/dd-init.md
- /Users/danlio/project/my_project/claude-dd/CHANGELOG.md
- /Users/danlio/project/my_project/claude-dd/docs/measurements/2026-10-23-reviewer-real-sessions.md

## 處置

- 採納，對應 `S3-judge.md` 的第 1（b 標 Important，裁決者升 Critical）、7、8（降為 Smells）條：全部照改
- 「rev 差異清單漏了 git show 那條」「dd-init 沒有 rev 7」：裁決者駁回
- 「手動同步區塊沒有漏改」：與 c 一致，不必處理
