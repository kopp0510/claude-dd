# S3 步驟 4：審查者 C（兩支腳本與它們撐住的結論）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數），同時派 code-simplifier 跑步驟 3。派工用一句話：「先用 Read 讀完 `<scratchpad>/s3/review/prompt-c.txt`（24 行），它就是你的完整任務說明，照裡面做。」下面是那個檔的全文（路徑已去識別：`<repo>`、`<scratchpad>`；回報裡引用的掃描樣式若含使用者名稱或 uid，也換成 `<USER>`、`<UID>`）。
diff 檔（1269 行）的組成：①`git diff dd570e7 HEAD`（HEAD = 447236c；不含 `out/reports/` 底下 15 份報告，只列檔名，要看就讀 repo）②被改到檔案在 HEAD 的整檔內容（帶行號；與步驟 3 並行，所以取 HEAD 版）③已跑過的驗證與預期值 8 條。步驟 3 的改動在派工當下是空的。

```text
你是 code-reviewer。你的職責：找漏洞。每一條發現都要附證據（檔名與行號、原文、或你跑的指令與輸出）；沒有證據的不算。不寫優點。

範圍：repo <repo> 的一個功能段落（S3），起點 dd570e7 到 HEAD（5 個 commit）。
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

你的重點（其他地方看到問題也照報）：兩支腳本與它們撐住的結論。
- docs/measurements/2026-11-15-plan-review-pack/readcheck.py：它印「讀到結尾：是」的時候，是不是真的代表那個 subagent 的 Read 結果裡有審查包的最後一行？有沒有會誤判成「是」或誤判成「否」的情況（例如 Read 的結果帶行號前綴、同一個 tool_use_id、Read 以外的工具讀檔、路徑的寫法不同、prompt 裡本來就有結尾那一行的字樣）
- docs/measurements/2026-11-15-plan-review-pack/fill.py：`check` 相同是不是真的能證明 `make` 填的是範本（兩條路共用了哪些函式、哪些沒被 check 蓋到）；`make … pack` 做的兩處替換跟 SKILL.md 第 2 步寫的是不是同一件事；它產生的審查包跟 SKILL.md 第 1 步規定的內容有沒有出入（出入會不會影響實驗的代表性）
- 關卡 ① 用的 timeline.py、作廢檢查用的 stats.py 在 docs/measurements/2026-11-15-reviewer-effort/（沒被改到，從 repo 讀）：拿它們判這三發有沒有站不住的地方（例如發代號、工作目錄不同、`leaky()` 的放行清單）
- docs/measurements/2026-11-15-plan-review-pack/CLAUDE.md 與量測文件「方法」一節講的用法、順序、檔名，照著做跑不跑得起來
- 腳本的註解與 docstring 裡的宣稱（引了哪個 commit、哪個檔、哪個行為）對不對
```

## 發現

審查者交回的全文（逐字；路徑已去識別）：

```text
Critical 0 / Important 4 / Smell 2。範圍是 S3（dd570e7..447236c）：兩支腳本、它們撐住的結論、reviewer-effort 的 timeline.py／stats.py 與方法文件。

結論：沒有任何一條會推翻「採用」的判定。四條 Important 裡，一條是關卡 ② 的判定力不夠，一條是代表性的限制沒寫，兩條是文件或去識別的宣稱不對。

## 發現

**[Important] readcheck.py:32-35，「讀到結尾：是」只能證明某次 Read 的結果裡有結尾那一行，不能證明整份讀完**
- 原文：`if b.get("type") == "tool_result" and b.get("tool_use_id") in reads and END in text(b.get("content")): seen = True`
- 問題：腳本沒記 offset／limit，也沒查開頭那一行。一個 subagent 只用 `offset:160, limit:10` 讀檔尾，一樣印「是」。可是量測文件把關卡 ② 叫「讀完」，結果表那一欄叫「把審查包讀到結尾」，docstring 寫「有沒有把審查包讀到最後一行」，三處都讀得像「讀完」。
- 證據：我在暫存區造了假的 HOME 與 subagent 紀錄跑 readcheck.py。只讀檔尾的那一筆印 `P-med-9｜第 2 層｜tailonly｜Read 審查包 1 次｜讀到結尾：是`。結果是一個 list 型 text block 的那一筆也印「是」，判對。用 Bash `cat` 讀的那一筆印「否」，是假陰性，但不影響這三發。
- 對這三發：審查包 166 行、每個 subagent 都只 Read 1 次，不帶 offset 就會整份讀到，所以實際風險低。但這只是推論，紀錄沒查過（見「需要外部查證」1）。
- 建議：每次 Read 印出 offset／limit，或同時要求結果裡有第一行 `審查範圍：`，用行號聯集算覆蓋。

**[Important] out/stats.jsonl 不是 stats.py 的原樣輸出，去識別是手工做的、沒有寫成步驟，還留了兩處 `/private/t`**
- 原文（目錄 CLAUDE.md:17）：「`out/` 只放 `stats.py`、`timeline.py`、`readcheck.py` 的輸出與 `deid.py` 處理過的報告」
- 問題：
  - stats.jsonl 裡有 `<暫存路徑，被截斷>`、`<WORK>`，stats.py 不會產生這些字，可見有一道沒寫下來的手工步驟。deid.py 只處理 reports/。
  - 去識別不一致：P-med-4 R4、P-med-6 R3 那兩筆，200 字元截斷剛好切在 `/private/t`。寫死的掃描樣式是 `/private/tmp`，所以回 0 筆照樣放行。
  - 舊實驗的慣例是洩題命中只留筆數，這次留了原文。
- 證據：`grep -o '/private/t[^"\\]*' out/stats.jsonl` 印兩行 `/private/t`。reviewer-effort/out/stats.jsonl 對應的欄位是 `"4 筆（都是 Agent 工具轉達的 prompt 文字，見結果文件）"`。
- 建議：照舊慣例只留筆數，或把去識別寫成腳本、寫進「方法」一節。同時改正 CLAUDE.md:17 那句。

**[Important] 代表性：run.sh 用 `--add-dir "$w/prompts"` 明確授權讀審查包，真實使用時沒有這一步，「限制」一節沒寫**
- 原文：reviewer-effort/run.sh:11 `dirs=("$w/prompts")`、:18 `--add-dir "${dirs[@]}"`。SKILL.md:40「沒有列就在系統暫存目錄下新開一個資料夾」。
- 問題：三發的裁決者與審查者能讀到審查包，前提是這個目錄被加進可讀目錄。真實 session 裡審查包放在 scratchpad，沒有 scratchpad 時放系統暫存目錄。背景跑的 haiku 審查者讀專案外的檔會不會被權限擋（被擋就拿不到材料），這三發量不到。限制一節只寫了「plan mode 擋不擋寫入」，沒寫「讀得到嗎」。
- 證據：上面兩行。量測文件限制一節（:147-155）沒有提到 add-dir 或讀取權限。
- 建議：限制一節補一句；或在互動 session 派一個 haiku 讀 scratchpad 裡的檔驗一次（見「需要外部查證」3）。

**[Important] 量測文件:116 對 Agent 那 4 筆洩題命中的歸因是錯的**
- 原文：「每發 4 筆是裁決者用 Agent 工具轉給審查者的 prompt 文字（裡面有審查包的路徑，或被審計畫自己寫的 `~/.claude/` 路徑）」
- 問題：
  - 審查包路徑會被 leaky() 換成 `<PROMPT>.`，不會觸發。
  - 放檔的兩發，審查者 prompt 裡沒有計畫內文，也就沒有計畫自己寫的 `~/.claude/` 路徑。
  - 我推測真正的原因是審查者範本那句「專案根目錄：《根目錄》（規則在…）」：快照路徑後面接全形「（」，不在 leaky() 認的分隔字元清單（`/`、`"`、空白）裡。這跟同一節 :118 寫的「換行沒算」是同一類。
  - 「不算洩題」的結論不受影響。
- 證據：用 exec 載入 stats.py 的 leaky() 實測：
  - `專案根目錄：/W/P-med-6（規則在根目錄與各層 CLAUDE.md）` → True
  - `材料在這個檔：/W/prompts/P-med-6.pack.md（共 166 行` → False
  - `專案根目錄：/W/P-med-6 。` → False

**[Smell] 量測文件:103「最後一個審查者第 56 秒開始」跟 out/timeline.md 對不上**
- 原文（timeline.md:5）：P-med-6 那列的起訖是 `22→307、33→119、45→185、57→254`。
- 問題：56 是 Agent 呼叫出現的秒數，審查者自己的紀錄從第 57 秒開始。關卡 ① 的定義是「最後一個審查者開始的秒數」。不影響判定（≤150），但數字指錯了東西。

**[Smell] SKILL.md:29-30 那句括號在放檔那條路上不成立了**
- 原文：「這句同時寫進「事實」開頭（「審查範圍」那一欄審查者看不到）」
- 問題：審查包第一行就是 `審查範圍：…`（SKILL.md:41），審查者讀檔時看得到。:42 補了「審查者認的是事實開頭那一句」，但沒回頭改 :30。這是全域 §3.10「補了限定之後，把那一段從頭讀到尾」那一類。目前不會造成做錯（兩處都要求寫範圍句）。

## Not reported（看過、判定不是問題）

- **readcheck 那幾個誤判情境**：
  - Read 結果帶行號前綴時，是用子字串比對，不受影響。
  - tool_use_id 每次唯一，tool_use 一定排在 tool_result 前面。
  - prompt 裡本來就有結尾那一行的字樣，但腳本只認 Read 的 tool_result，不會誤判（docstring 這句是對的）。
  - 路徑兩邊都過 realpath，`/tmp` 與 `/private/tmp` 的差別會被消掉。
  - 寫成 `~` 或用 Bash 讀檔會誤判成「否」，不會誤判成「是」。
- **fill.py 的 check**：`make … pack` 獨有的程式（block 替換讀檔指示、pack_sentence、half_sentence、HALF 替換、審查包內文、`{N}`、ROOT／EFFORT、parent 填寫）check 都沒蓋到。docstring「相同才代表 make 填的是範本」講過頭了，但這些是單純的字串操作，有 assert 剛好一處，加上對 P-med-6.judge.txt 的 0 處檢查與乾跑 e 臂的 diff，缺口有補上。
- **兩處替換**：fill.py 的兩處替換跟 SKILL.md 第 2 步是同一件事：block() 的起訖正好是 `<<<計畫開始>>>` 到 `<<<事實結束>>>`，HALF 逐字對得上範本 :162。
- **審查包內容**：順序跟第 1 步規定的一致。`{N}=body.count("\n")` 跟 `wc -l` 相同。
- **commit 引用**：fill.py 在這個範圍內只有 2cf7aba、8633574 兩個 commit 動過；SKILL.md 只有 e3c7fd1、8633574。docstring 與 CLAUDE.md 寫的「P-med-4、P-med-5 用 2cf7aba 的 fill.py 配 e3c7fd1 的 SKILL.md」對得上。
- **第一次修正沒列第 1 步那四處說明**：8633574 同時補了第 1 步那四處說明，「第一次修正」一節沒列。但那幾句不會進 fill.py 產生的 prompt，真跑的差別只有兩處替換與拿掉條件句，不影響比較。
- **使用順序**：CLAUDE.md 寫的順序（prepare.py → fill.py make → run.sh）跑得起來。prepare.py 會建 prompts/ 與 logs/，fill.py 會蓋掉它寫的 judge 與 parent。發代號要剛好三段（stats.py:74 會擋）。
- **數字核對**：
  - 結果表的秒數、字元範圍、裁決者結束時間，跟兩份 timeline.md 與 stats.jsonl 的 judge_s 都對得上。
  - 基準費用 3.05／3.11 對得上。
  - 洩題筆數 7／4／12 對得上 stats.jsonl。
  - 命中引的 4 處報告行號，內容確實講到機制 (b)。
- **報告去識別**：reports/ 裡 `scratchpad` 的命中都是計畫自己的文字（「探針在 scratchpad」），不是路徑殘留。
- **費用加總**：「1.61 + 2.76 = 4.38」照兩位小數相加是 4.37，文件說是原始值相加後四捨五入，原始值不在 repo，見「需要外部查證」4。
- **讀已安裝的 task-planner 算不算洩題**：M1 講的是步驟 4 與 F17，不是 task-planner，讀那份 skill 不算洩題。

## What I ran

- Read prompt-c.txt 與 S3-diff.txt（1–1269 行，分 4 段）→ 讀完
- `cat -n` reviewer-effort 的 timeline.py、stats.py、run.sh、parent-a.txt、outside.py、deid.py、CLAUDE.md、prepare.py → 讀完
- `grep -n '正確答案' -A25 docs/measurements/2026-11-15-reviewer-effort.md` → 取得 M1 的定義
- `git log --oneline dd570e7..HEAD -- fill.py readcheck.py SKILL.md`、`git diff 2cf7aba 8633574 -- fill.py`、`git diff e3c7fd1 8633574 -- SKILL.md` → 只有上面說的三個 commit；fill.py 只加了 HALF 替換
- `cat reviewer-effort/out/timeline.md`、grep 舊 stats.jsonl 的 cost 與洩題欄 → 基準數字對得上；舊慣例只留筆數
- `grep -o '/private/t…' out/stats.jsonl` → 2 筆 `/private/t`
- grep reports 找 `claude-<UID>|<USER>|/private/|scratchpad` → 3 個檔命中，都是計畫自己的文字；`sed -n` 印出 4 處命中行 → 都講到機制 (b)
- 暫存區探針（假 HOME 加 3 種 subagent 紀錄）跑 readcheck.py → tailonly 印「是」、listblocks 印「是」、bashcat 印「否」，rc=1
- 暫存區用 exec 載入 stats.py 的 leaky() 跑 3 個字串 → True／False／False（如上）

探針放在 <scratchpad>/s3/rc-probe/，沒有改 repo。

## 需要外部查證

1. 在家目錄 `.claude/projects/` 底下，三發共 15 個 subagent 紀錄裡，印出每次 Read 審查包的 `offset`／`limit`。可以確定每個 subagent 是不是真的整份讀完（第一條發現在這三發的實際影響）。
2. 用 stats.py 印 P-med-4 那 3 筆 Bash 命中的完整指令（不截 200 字）。可以確定量測文件 :117「2 筆讀 task-planner、1 筆 grep 樣式」的分類對不對（P-med-6 那筆看得出是 task-planner，P-med-4 三筆都被截斷了）。
3. 在互動 session 派一個背景 haiku subagent，讀 scratchpad 裡的檔、再讀系統暫存目錄新開資料夾裡的檔，看會不會被權限擋。可以確定第三條發現的缺口是不是真的。
4. 父 log 裡三發原始的 `result.total_cost_usd`。可以確定「4.38」「6.14」是四捨五入前相加的結果。
```

## 處置

六條都採納，級別照審查者標的。修正在 `fd3004b`。

| # | 級別 | 發現 | 查證 | 做了什麼 |
|---|---|---|---|---|
| 1 | Important | `readcheck.py` 只證明結果裡有結尾那一行，只讀檔尾也印「是」 | 屬實（讀程式碼；審查者的探針也印「是」） | 改成印每次 Read 的 offset／limit，要的行要蓋住第 1 行到最後一行、而且結果裡有結尾那一行。不拿第一行去比結果：範圍句在事實開頭會再出現一次（`grep -c` 回 2），從中間讀起也比得到。用審查者留的探針重跑：只讀檔尾那一筆印「否」。三發 15 個紀錄重判：讀了檔的 11 個都是 1 次 Read、limit 300、offset 沒給或 0，審查包 166 行，結論不變 |
| 2 | Important | `out/stats.jsonl` 不是 `stats.py` 的原樣輸出，去識別是手工做的 | 屬實 | 新增 `pubstats.py` 取代手工步驟，洩題檢查欄只留筆數；目錄 CLAUDE.md「`out/` 只放…」那一句改正 |
| 3 | Important | 三發讀得到審查包是 `run.sh` 的 `--add-dir` 給的，「限制」沒寫 | 屬實（`run.sh` 的 `dirs=("$w/prompts")` 與 `--permission-mode dontAsk`） | 「限制」補一條：互動 session 裡背景 subagent 讀 scratchpad 的檔沒被擋（大檔臂的兩個 haiku、這次步驟 4 的三個審查者）；沒測的是系統暫存目錄那條退路、別的權限模式、第 2 層審查者。沒有另外做探針 |
| 4 | Important | Agent 那 4 筆洩題命中的歸因寫錯 | 屬實。用完整輸入驗：把快照路徑後面的全形括號、換行前面補一個空白再餵 `leaky()`，`P-med-4` 的 4 筆 Agent、`P-med-6` 的 4 筆 Agent 與 7 筆 Bash 都不再被列出；`P-med-5` 的 4 筆 Agent 仍被列出，命中的是貼進去的計畫自己寫的 `~/.claude/…` | 量測文件那一段重寫（原本寫的「審查包的路徑」是錯的，它不會被列出） |
| 5 | Smell | 「第 56 秒開始」對不上 timeline | 屬實 | 同審查者 B 第 3 條 |
| 6 | Smell | SKILL.md 那句括號在放檔那條路不成立 | 屬實 | 同審查者 A 第 2 條 |

Not reported 裡提到 `fill.py` 檔頭「相同才代表 make 填的是範本」講過頭：順手改成「相同代表 make 也會用到的那幾步填的是範本；pack 獨有的部分這裡比不到」。

需要外部查證的四項：

- 每次 Read 審查包的 offset／limit：查了，現在印在 `out/readcheck.txt`
- `P-med-4` 三筆 Bash 的完整指令：查了，拆法屬實（見審查者 B 的處置第 5 條）
- 背景 haiku subagent 讀系統暫存目錄的檔會不會被擋：沒做，寫進「限制」
- 原始費用：父 session 紀錄的 `total_cost_usd` 是 1.6127、2.7643、1.7660；前兩發相加 4.3771（寫成 4.38），三發 6.1431（寫成 6.14）
