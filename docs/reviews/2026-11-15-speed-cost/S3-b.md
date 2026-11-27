# S3 步驟 4：審查者 B（量測文件的宣稱對不對得上原始輸出）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數），同時派 code-simplifier 跑步驟 3。派工用一句話：「先用 Read 讀完 `<scratchpad>/s3/review/prompt-b.txt`（25 行），它就是你的完整任務說明，照裡面做。」下面是那個檔的全文（路徑已去識別：`<repo>`、`<scratchpad>`；回報裡引用的掃描樣式若含使用者名稱或 uid，也換成 `<USER>`、`<UID>`）。
diff 檔（1269 行）的組成：①`git diff c772d96 HEAD`（HEAD = d3f995c；不含 `out/reports/` 底下 15 份報告，只列檔名，要看就讀 repo）②被改到檔案在 HEAD 的整檔內容（帶行號；與步驟 3 並行，所以取 HEAD 版）③已跑過的驗證與預期值 8 條。步驟 3 的改動在派工當下是空的。

```text
你是 code-reviewer。你的職責：找漏洞。每一條發現都要附證據（檔名與行號、原文、或你跑的指令與輸出）；沒有證據的不算。不寫優點。

範圍：repo <repo> 的一個功能段落（S3），起點 c772d96 到 HEAD（5 個 commit）。
這一段做的事：skills/plan-review/SKILL.md 改成「主對話把計畫與事實寫成一個檔（審查包），裁決者與審查者的 prompt 只給路徑」，寫不了檔時照舊貼；
並用三發 claude -p 真跑、幾個 subagent 乾跑驗證，結果寫在 docs/measurements/2026-11-15-plan-review-pack.md。

先讀 diff 檔：<scratchpad>/s3/review/S3-diff.txt（共 1269 行）。Read 一次讀太多會靜靜截斷、不報錯，用 offset／limit 每次 300 行讀到最後一行。
- 第一段是整段 diff，第二段是被改到檔案在 HEAD 的整檔（帶行號），第三段是已經跑過的驗證與輸出 —— 第三段列的已確認，不要重跑
- 被改到的檔一律讀 diff 檔裡那一份，不要讀工作目錄（另一個 agent 正在同時整理 fill.py、readcheck.py）；沒被改到的檔照常從 repo 讀
- 行號以 diff 檔第二段的行號為準；引用時連同原文一起貼（行號可能對不準，我會拿原文去找）

規則：
- 唯讀：不改檔、不 commit、不跑 claude -p、不跑安裝腳本（install-dd-pipeline.sh）、不跑 CI
- 只用手上的資料判斷；需要外部查證的（要翻家目錄的紀錄、要上網、要重跑實驗）列在「需要外部查證」交回，不要自己去做
- 專案規則在 repo 根目錄與各層的 CLAUDE.md；全域規則在你的 context 裡（§3.10 寫文件的判準特別相關）
- 每條標級別：Critical／Important／Smell。真的沒找到就照實寫，不要硬湊
- 用文字交回，不要另外寫報告檔。交回的內容要有：發現（每條：級別｜位置與原文｜問題｜證據｜建議）、Not reported（看過但判定不是問題的）、What I ran、需要外部查證

你的重點（其他地方看到問題也照報）：量測文件 docs/measurements/2026-11-15-plan-review-pack.md 的每一個宣稱對不對得上原始輸出。
- 表格與內文的每個數字，對 out/timeline.md、out/readcheck.txt、out/stats.jsonl（repo 裡，stats.jsonl 每行一個 JSON）與基準 docs/measurements/2026-11-15-reviewer-effort/out/ 逐個核對
- 「命中」的判定：M1 的定義在 docs/measurements/2026-11-15-reviewer-effort.md「正確答案」。去讀量測文件引用的那幾份報告的那幾行（docs/measurements/2026-11-15-plan-review-pack/out/reports/），判斷它們是不是真的講到機制 (a) 或 (b)；也掃一遍其他審查者報告有沒有被漏記或誤記的
- 「判定：採用」是不是真的照文件自己在跑之前寫死的判準走（「判準」與「第一次修正」兩節）；commit 順序對不對得上「跑之前寫死」的說法（git log、git show --stat 可以看；P-med-6 的紀錄時間要外部查證就列出來）
- 「限制」有沒有漏掉會改變結論的事；有沒有哪一句把 n=1 或 n=2 的結果寫得比證據強；有沒有把推測寫成事實
- 洩題檢查那一段的逐筆判定站不站得住（stats.jsonl 的 notes 欄有被截斷的原文）
- CHANGELOG.md 與 docs/designs/2026-11-15-speed-cost-design.md 裡關於這次結果的句子，跟量測文件一不一致
```

## 發現

審查者交回的全文（逐字；路徑已去識別）：

```text
Critical 0 / Important 3 / Smell 3 — S3（c772d96..d3f995c），重點核對量測文件 docs/measurements/2026-11-15-plan-review-pack.md

## 發現

1. Important｜docs/designs/2026-11-15-speed-cost-design.md 第 216–217 行（diff 檔第二段 1186–1187 行）
   原文：「第 2 步：寫了審查包時，範本裡兩組標記那一整段換成一句讀檔指示…」「裁決者範本「派審查者」那條加一句：上面是讀檔指示時，《計畫與事實》貼那一句、不貼檔案內容。貼的那條路的字不改」
   問題：「改法」清單寫的還是第一版的做法。範本裡那條條件句已在 a64b6c7 拿掉，範本回到跟 23429eb 逐字相同，現在第 2 步要換兩處。同一節第 232 行雖然補了「中途改成換兩處」，但「改法」清單本身沒改，讀到這份清單的人會照它在範本裡加一句。這正是 §3.10「補了一句限定之後，整段從頭讀到尾」那類的自相矛盾。
   證據：`git diff 505df35 a64b6c7 -- skills/plan-review/SKILL.md` 有 `-- 上面沒有那兩組標記、只有一句「材料在這個檔：…」時…`；第三段第 4 項說範本與 23429eb 逐字相同。
   建議：改法清單改成兩處替換，或標明「第一版，已被 a64b6c7 取代」。

2. Important｜量測文件第 149 行（限制第 1 條）
   原文：「第二版把裁決者 prompt 裡「貼標記之間的內容」那半句整個拿掉，所以這不只靠那一發：`fill.py` 與乾跑 e 臂填出來的 prompt 裡那半句都是 0 處」
   問題：把證據寫得比實際強。「那半句是 0 處」只是機械檢查，證明的是 prompt 寫對了，證明不了裁決者會照做。P-med-5 為什麼沒照做，第 64 行自己寫「下面是我的推測」。拿掉那半句能不能修好，取決於這個推測對不對，所以第二版會不會被照做，證據仍然只有 P-med-6 一發（n=1）。
   證據：第 64 行「裁決者的思考沒有留在紀錄檔，下面是我的推測」；readcheck.txt 第二版只有 P-med-6 那 5 行。
   建議：刪掉「所以這不只靠那一發」，改寫成「prompt 層面已排除那半句；裁決者照不照做仍只有 1 發」。

3. Important（影響小）｜量測文件第 103 行，以及 CHANGELOG 第 15 行（diff 行號）
   原文：「最後一個審查者第 56 秒開始」；CHANGELOG「第 56 秒全部開跑」
   問題：56 是 Agent 呼叫出現在紀錄檔的秒數，不是審查者開始的秒數。關卡 ① 的定義是「最後一個審查者開始的秒數」（第 28 行）。P-med-6 最後一個審查者其實是第 57 秒開始。結論不受影響（≤150），但這句跟它引的原始輸出對不上。
   證據：out/timeline.md P-med-6 那列：`22→307、33→119、45→185、57→254`。
   建議：改成「第 56–57 秒」，或明說是「Agent 呼叫出現的秒數」。

4. Smell｜量測文件第 19 行（方法）
   原文：「計畫與事實那一段換成 SKILL.md 第 2 步的那一句讀檔指示」
   問題：這只描述 P-med-4、P-med-5 那一版。P-med-6 還換了「派審查者」那半句，方法這一節沒有跟著補（目錄 CLAUDE.md 第 9 行有寫）。
   證據：fill.py 第 104–105 行 `t = t.replace(HALF, half_sentence(skill))`。

5. Smell｜量測文件第 115–118 行（洩題的 leaky 細目）
   原文：「`P-med-4` 3 筆、`P-med-6` 1 筆…讀已安裝的 `~/.claude/skills/task-planner`（3 筆）、一個 grep 樣式字串裡的 `~/.claude/scripts`（1 筆）」
   問題：stats.jsonl 裡看得到的那一筆（P-med-6 的輪1-R1 Bash）是 task-planner。P-med-4 的 3 筆 Bash（R2 一筆、R4 兩筆）在 notes 裡都截斷在家目錄路徑出現之前，所以「2 筆 task-planner + 1 筆 scripts」這個拆法從 repo 裡的資料核不到。P-med-4 的 R4 那筆在 grep `docs/measurements` 的 `269|5\.13`，截斷之後還有一段 `grep -rn … docs` 看不到。另外「那份已安裝的 skill 沒有講到 M1」讀的是部署版，不在快照裡，repo 裡沒有佐證。
   證據：stats.jsonl 第 1 行 notes 末三筆以 `…| head -30; echo ----; gre`、`…grep -rn -E '5\\.13|269' docs`、`…cut -c1-160; echo ...; grep` 結尾。

6. Smell｜out/stats.jsonl 第 1、3 行
   原文：`材料在這個檔：/private/t`
   問題：去識別沒處理這兩筆。截斷正好落在路徑中間，deid 沒取代，寫死的掃描 `/private/tmp` 也比對不到 `/private/t`，所以第三段第 6 項那個「0 筆」是因為掃描樣式比對不到，不代表真的乾淨。這兩筆不含使用者名稱，沒有實害。但同檔其他筆都寫成 `<暫存路徑，被截斷>`，這兩筆跟它們不一致，也證明掃描樣式有洞。
   證據：`grep -rnoE '/private/t[a-z]*' docs/measurements/2026-11-15-plan-review-pack*` 回 stats.jsonl 第 1、3 行各 `/private/t`。

## Not reported（看過、判定不是問題）

- 表格數字都對得上原始輸出：timeline.md 三發的秒數、字元範圍（1489–1503、14610–14749、1491–1688），最後一個審查者結束 288/407/307，裁決者結束 393/505/417；費用 1.61/2.76/1.77，合計 6.14；基準 P-med-2/3 的秒數、字元範圍、466/426、614/542、3.05/3.11；起因那句的 83–86、158–161、234–236、312–313 與 14,653–14,862；舊實驗 rev_s 38–229；這三發 rev_s 85–285；「約 4 分鐘」是 312−56=256 秒；leaky 筆數 7/4/12。
- 4.38 美元（1.61+2.76 顯示成 4.37）：文件註明是原始值相加後才四捨五入，算得通。
- 命中：P-med-4.d2.a6f26f 第 28 行、P-med-6.d2.a28e9c 第 22 行、P-med-6.d2.ac3a83 第 31 行，都明講「不是每段步驟 4 的時間」「另一種派工方式」，屬於機制 (b)。P-med-5.d2.a95c45 第 15 行講口徑不同，接近 (b)，文件也只列它、不計分。沒找到漏記的：P-med-4 R4-7 與 P-med-6 R4-9 只講樣本數 n，不算命中；全部報告都沒有人講到 (a)。
- 判準時序：判準那一節從 041bd22 到 HEAD 只刪了「還沒跑。」一行，沒有事後改動；「第一次修正」在 a64b6c7（09:46:25），結果在 d3f995c（09:57:57）。③ 改成只算從檔讀的發，是把 P-med-5 的命中排除掉，判準變嚴，不是放寬。
- readcheck.txt 與文件「讀到結尾」那一欄一致（P-med-5 四個審查者 0 次）。

## What I ran

- Read prompt-b.txt、S3-diff.txt（1–1269 行分 4 段）→ 讀完
- grep reviewer-effort.md「正確答案」、M1 命中表；cat 舊實驗 out/timeline.md；python 讀舊實驗 stats.jsonl → 基準數字一致
- grep out/reports 的 F17/每段/時間與費用等關鍵字 → 列出各報告的候選行
- git log 作者與 committer 時間、git show --stat 五個 commit → 時序如上
- git diff 041bd22 a64b6c7 與 a64b6c7 d3f995c（量測文件）→ 判準沒被改
- git diff 505df35 a64b6c7 -- SKILL.md → 條件句被刪、四處說明在 a64b6c7 才加
- grep -rnoE '<USER>|claude-<UID>|/private/t[a-z]*|/var/folders|/Users' → 只有 stats.jsonl 的兩筆 `/private/t`

## 需要外部查證

- P-med-6 父 session log 的第一個時間戳要晚於 09:46:25（a64b6c7），「第一次修正在開跑前寫的」才成立；P-med-4、P-med-5 要晚於 09:29:51（505df35）。兩發約 914 秒，夾在 994 秒的窗裡，偏緊，要確認是不是並行跑的。
- P-med-4 那 3 筆 Bash 的完整 command（在 ~/.claude/projects/ 的 subagent 紀錄裡），用來核對「task-planner 2 筆 + scripts 1 筆」的拆法，以及 R4 那筆 `grep … docs` 讀到了什麼。
- 部署版 ~/.claude/skills/task-planner/SKILL.md 有沒有講到 M1（F17 或「每段」的費用）。
- 審查包 166 行、22,516 位元組，V3 的 1202 行/68,520、42 行/71,055，V4 的 77/134/74 行與 3,320/3,323 字元：原始輸出都不在 repo，要拿暫存區的檔核對。
- V4 d 臂用的「補了四處說明之後」那一版 SKILL.md 是 505df35 與 a64b6c7 之間沒有 commit 的中間狀態，要確認它的內容。
```

## 處置

六條都採納，級別照審查者標的。修正在 `7344704`（CHANGELOG 那一句在這一段的最後一個 commit）。

| # | 級別 | 發現 | 查證 | 做了什麼 |
|---|---|---|---|---|
| 1 | Important | 設計文件「改法」清單還是第一版 | 屬實 | 清單改寫（同審查者 A 第 5 條） |
| 2 | Important | 「所以這不只靠那一發」把機械檢查寫成行為的證據 | 屬實：`P-med-5` 為什麼沒照做是我的推測，拿掉那半句之後會不會被照做，證據只有 `P-med-6` 一發 | 「限制」第一條改寫。我在對話裡也對使用者講過同一句，收尾回報時更正 |
| 3 | Important（影響小） | 「第 56 秒開始」是 Agent 呼叫出現的秒數，`P-med-6` 最後一個審查者第 57 秒開始 | 屬實（`out/timeline.md` 起→訖欄：`P-med-4` 56、`P-med-6` 57） | 量測文件結果一節與 CHANGELOG 改成 56、57；對使用者講過的「第 56 秒全部開跑」一併更正 |
| 4 | Smell | 「方法」只描述第一版的替換 | 屬實 | 「方法」是跑之前寫的，不動；在結果一節註明 `fill.py make … pack` 從 `P-med-6` 起換兩處 |
| 5 | Smell | 洩題檢查那幾筆的拆法從 repo 核不到 | 用完整的工具輸入重判：審查者的 4 筆是 3 筆碰已安裝的 task-planner（1 筆只有 `ls`、2 筆 grep）加 1 筆樣式字串，拆法屬實；`P-med-4` 輪1-R4 那筆 grep 的 `docs/measurements` 是它自己快照裡的；已安裝的那份 SKILL.md `grep -cE`（樣式 F17、時間與費用、11.8、5.13 四個擇一）回 0 | 量測文件那一段重寫，寫明完整輸入在家目錄的紀錄裡、不在 repo；Agent 那幾筆的歸因另照審查者 C 第 4 條改 |
| 6 | Smell | `out/stats.jsonl` 兩處 `/private/t` | 屬實 | `pubstats.py`（同審查者 A 第 6 條） |

需要外部查證的五項：

- 開跑時間對 commit 時間：查了父 session 紀錄的第一個時間戳。`P-med-4`、`P-med-5` 是 09:31:44、09:31:45（並行跑；`505df35` 09:29:51、`9c3d7a6` 09:31:20），`P-med-6` 是 09:46:54（`a64b6c7` 09:46:25，晚 29 秒）。都在對應的 commit 之後，寫進量測文件
- `P-med-4` 三筆 Bash 的完整指令：查了，見上表第 5 條
- 已安裝的 task-planner 有沒有講到 M1：查了，0 筆
- 行數與位元組數：審查包 166 行、22,516 位元組；大檔 1202 行、68,520 與 42 行、71,055；乾跑 a、c、d 臂的審查包 77、134、74 行，都對。a、c 臂的裁決者 prompt 字元數（3,320、3,323）當時是對回報裡的 prompt 算的，prompt 沒有另存成檔，這次沒有重算
- 乾跑 d 臂用的那一版 SKILL.md：是 `505df35` 加上第 1 步那四處說明、還沒改第 2 步的工作目錄狀態，沒有 commit、沒有留檔，還原不了。量測文件表格裡寫的「補了四處說明之後」就是指它
