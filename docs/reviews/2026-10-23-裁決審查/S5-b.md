# S5-b — 拿掉裁決者的對照（審查者 B 數字核對）

## 派工

裁決者交回的派工 prompt（四人共用部分加各自方向，逐字；路徑換成 `<scratchpad>`）。範圍：`9798edc..HEAD`。

````text
# 派工 prompt（裁決者給審查者，共用部分 + 各自方向）

## 數量與方向的理由
派 4 個（下限 3）。主對話建議三個方向（腳本正確性／數字與命中核對／結論推論），其中「命中判定」被明寫為主對話自己 grep 判的、要複核的東西，且需逐份讀 8 發報告，工作量與「數字核對」（stats.jsonl、logs、時間量法）是兩種不同的原始資料，合在一個人身上容易兩邊都只抽樣，所以拆成 B（數字）與 C（命中）兩人。A 管腳本、D 管結論推論與跨檔一致性（設計文件、CLAUDE.md、兩份量測文件之間）。

## 共用部分（四人相同）

你是 code-reviewer，審查專案 /Users/danlio/project/my_project/claude-dd 的段落 S5「拿掉裁決者的對照」（範圍 9798edc..HEAD）。這段大多是量測文件、實驗腳本（python/bash）與設計文件，沒有產品程式碼。

### diff 檔（必讀）
<scratchpad>/S5-review-diff.txt（2187 行，約 208 KB）。
**Read 不指定範圍會在約 47 KB 靜靜截斷、不報錯，一律用 offset/limit 每次 300 行讀，讀到第 2187 行為止。**
四段：① 第 1–563 行 整段 diff（排除機器輸出）② 第 564–593 行 步驟 3 code-simplifier 的改動（commit 66d4314，只動 1 行）③ 第 594–2112 行 被改到檔案的整檔內容（HEAD 版，帶行號）④ 第 2113–2187 行 機器輸出全文（S5 的 stats.jsonl、checks.out、sec1.out）與報告檔名清單。
被改到的檔一律讀 diff 檔裡那一份，不讀工作目錄。

### 可以讀的
- repo（唯讀）
- 原始紀錄（唯讀）：<scratchpad>/s5/（S5 的快照 G2、G3、各發目錄 G2-dir-1…、logs/、reports/、prompts/、stats.jsonl、checks.out）、同目錄的 s4/（S4 的）、以及 ~/.claude/projects/ 底下名稱含 `scratchpad-s5-` 或 `scratchpad-s4-` 的目錄（各發的 session 紀錄 jsonl）
- 不准讀 /Users/danlio/project/SRE。repo 與原始紀錄不准改任何檔、不 commit、不 push。要寫暫存檔只能寫在 <scratchpad>/S5-review/tmp-<你的代號>/。

### 已經跑過的驗證（已確認，不要重跑；「已確認」只代表跑過，預期值寫在後面，若你懷疑預期值本身錯了就說出來）
- `cmp` S4 與 S5 的 G2、G3 diff.txt：印出 DIFF_SAME。預期：逐位元組相同
- `direct.txt` 對答案句片段（從未執行到、查不到出處、3 紅、正常流程唯一的覆蓋、pre-commit 不查報告、判準相反、繞過、stash、⑪）`grep -c`：全部 0。預期：全部 0
- S4 與 S5 兩份 stats.py 從 `LEAK` 到 `def run_stats` 那段 `diff`：沒有差異。預期：相同
- checks.py 拿 S4 的 G3-new-1、G2-new-1、G2-hk-2 試跑：G3-new-1 每個審查者全檔缺 2276–2774 行。預期：非 0（S4 已知 Read 截斷）
- stats.py、checks.py、sec1.py 對 8 發的輸出就是 diff 檔第 ④ 段
- CI「迴圈步數第五方」step（用 ruby 從 ci.yml 取出原文照跑），新檔 git add 之後跑：exit 0。預期：exit 0
- 命中判定（量測文件「五組並排」底下的命中位置）是主對話用 grep 報告檔判的 —— 這是要複核的，不在「已確認」之列

### 你的職責
找漏洞、證明這次有錯。每條發現附證據（檔案＋行、或你實跑的指令與輸出原文）；沒證據的不算。只用手上的資料判斷；需要外部查證（上游原始碼、網路、重跑 claude 實驗、花錢）的不要做，列在「需要外部查證」交回。可以跑唯讀指令（grep、python 讀檔計算、jq 等），不要重跑上面「已確認」的項目，也不要重跑 claude -p 實驗。

### 報告格式
- Critical / Important / Smells 分級列出，每條：位置、問題、證據、建議改法
- Not reported：你看過、判斷不是問題（或判成既有問題、非本次 diff 引入）的項目，附一句理由
- 需要外部查證
- What I ran：你跑的指令清單（含關鍵輸出）

## 各自方向

### A：腳本正確性
重點：checks.py、sec1.py（新檔），以及改過的 stats.py、prepare.py、run.sh。逐行讀 diff 檔 ③ 的整檔內容：邏輯錯誤、邊界（空輸入、找不到時靜默回 0、檔名含中文/空白、glob 漏抓）、計數口徑（例如把「描述它的那句話」也算進去）、兩份腳本對同一件事的判法不一致、S4 版與 S5 版的差異是否引入偏差。拿原始紀錄實跑腳本（唯讀、輸出寫到你的 tmp 目錄）驗證你的懷疑，並和 diff 檔 ④ 的輸出比對。特別留意：輸出為 0 / 無差異時，先懷疑腳本自己沒跑到。

### B：量測文件與設計文件的數字核對
重點：docs/measurements/2026-10-23-reviewer-real-sessions.md 新增的 S5 段落、docs/designs/2026-10-23-裁決審查-design.md 的 S5 段落、兩個 s5-inputs/s5-outputs 的 CLAUDE.md。把每一個數字（時間、token、工具次數、費用、行數、發數、比例、平均）逐條對原始紀錄（s5/stats.jsonl、s5/logs、~/.claude/projects/*scratchpad-s5-* 的 jsonl、s4 對應資料）重算。特別核 commit 4e47492「修正 S5 對照的時間量法並標出實跑落差」後的時間量法：口徑是否一致、S4 與 S5 是否用同一口徑比較、「實跑落差」標得對不對。命中位置不是你的主責（C 管），但數字裡若有命中數就要核。

### C：命中判定複核
重點：量測文件「五組並排」底下的命中位置／命中數，以及任何「某發抓到／沒抓到某個已知錯誤」的宣稱。答案（已知真錯誤）定義在哪裡要先找到（設計文件、s5-inputs 的 CLAUDE.md、或 S4 的量測段），然後逐份讀 s5/reports/ 的 8 份報告（以及需要比較時 s4/reports/），獨立判定每一發對每一個已知錯誤是命中、部分命中、還是沒中，給出報告原文引用。和量測文件的判定逐格比對，列出不一致處。注意：命中判定不能只看關鍵字 grep —— 提到同一段落但結論相反、或把真錯誤判成「既有問題」丟進 Not reported 的，要分清楚。

### D：結論、限制與跨檔一致性
重點：量測文件 S5 段落的結論與限制、設計文件 S5 段落、CLAUDE.md（根目錄與 s5-inputs/s5-outputs）的敘述。逐條檢查：推論是否被資料支持（n 多小、變因是否混雜、和 S4 比較時條件是否相同）、有沒有過度宣稱或把推測寫成事實、同一件事在不同檔案（兩份量測文件、設計文件、CLAUDE.md、prompt/direct.txt）講法是否矛盾、引用的行號／檔名／commit／段落是否指得到（用 sed -n 印出那一行比對，不只看檔案存在）、Markdown 表格是否被插入的段落截斷。依全域 ~/.claude/CLAUDE.md §3.10 的判準（不要寫死計數、不要承諾別處行為、歸因要能反證）檢查。
````

## 發現

審查者報告原文（逐字）。

````text
# S5 審查者 B（量測文件與設計文件的數字核對）完整報告（逐字）

派工 prompt：見同目錄 prompt.md 的「共用部分」＋「B：量測文件與設計文件的數字核對」；啟動訊息為「先用 Read 整份讀完 …/S5-review/prompt.md（它是你的完整任務說明）。照「共用部分」做，你的代號是 B，方向是「各自方向」裡的「B：量測文件與設計文件的數字核對」。其他方向（A、C、D）由別人負責，不必做。最後照「報告格式」交回完整報告。」

---

審查者 B（量測文件與設計文件的數字核對）報告，範圍 9798edc..HEAD

Critical 1 / Important 3 / Smells 2

數字本身大致抄得對：stats.jsonl 對原始數字表 8 列逐格相符；A 平均 269、B 427、S4 的 154/350/346、費用平均 5.13/4.03/1.31/3.83/1.57、合計 36.6、快約 23%、貴約 3.9 倍、「整發減審查者層最慢」A 82–122、S4 132–297、舊 17–23、15 個裡 13 個、777–2684、sec1 的 9/13 全部重算吻合。S4 與 S5 的 whole_s 定義相同（兩份 stats.py 的 t0、stamps 寫法逐字一樣），所以 4e47492 改成「整發減審查者層最慢」後，S4 與 S5 用的是同一口徑。問題出在這些數字底下混進了沒有記錄的成分，以及有幾處標籤貼錯。

[Critical] docs/measurements/2026-10-23-reviewer-real-sessions.md S5「結論」第 4 條，以及「原始數字」作廢那條的「模型斷言全過」
  問題：B 組有 2 發的父 session 叫了 advisor 工具，用的是第三個模型 claude-fable-5-1，文件完全沒提（`git grep -i 'advisor\|fable' -- docs/` 0 筆）。B「最慢」「收尾 43–304s」「只比 A 便宜約 20%」這三個結論都被它撐大了。
  證據：
  - result.modelUsage 裡，G2-dhk-1 的 fable 是 2.1 美元（總額 4.11 的 51%），G3-dhk-1 是 2.9 美元（總額 6.49 的 45%）；A 的 4 發只有 opus。
  - 父 session jsonl 裡 server_tool_use advisor 的時間點：G2-dhk-1 在 193s 送出、414s 收到結果（審查者 326s 就結束了，所以收尾 177s 裡有 88s 在等 advisor）；G3-dhk-1 在 291s 送出、493s 收到（審查者 224s 結束，收尾 304s 裡有 202s 在等 advisor）。
  - 扣掉 advisor 後，B 的費用平均約 2.78，比 A 便宜約 46%，不是 20%；整發平均約 355s，不是 427s，跟 S4 的 350/346 只差幾秒。所以「父 session 要花更多時間查 haiku 的報告」這個歸因不成立。
  - stats.py 的模型斷言只看 jsonl 裡 assistant 的 message.model，看不到 advisor 用的模型，所以「全過」雖然屬實，卻沒有攔到這件事。
  建議改法：作廢或限制那節寫明 advisor 介入了哪幾發、多少秒、多少錢；結論 4 改寫，或附上扣掉 advisor 後的數字。也可以考慮在下次實驗的 run.sh 用 disallowedTools 把 advisor 關掉。

[Important] 同一份文件的結論 3，以及設計文件 S5 一節第 2 行（「新組與 haiku 組 132–297s」）
  問題：297s 這個上限來自 S4 的 G3-hk-1（455 減 158）。那一發的裁決者也叫了 advisor（約 116s），所以裁決者那一層的上限被 advisor 撐大了，這是 4e47492 新寫進兩份文件的數字。
  證據：s4 G3-hk-1 的 modelUsage 有 claude-fable-5-1，1.41 美元；裁決者紀錄 agent-a44a086a3ceeffd02.jsonl 的 server_tool_use 在 18:38:16，advisor_tool_result 在 18:40:12。
  建議改法：註明這一發有 advisor 介入；或區間只列沒有 advisor 的發（新組 135–167、haiku 組 132–197）。S4 haiku 組的平均 346s／1.57 美元也含這一發，並排表要加註。

[Important] 結論 3「A 82–122s（派工前 23–34s ＋收尾 38–52s ＋開機）」
  問題：多出來的那段被標成「開機」，但它其實是審查者一個接一個派出的錯開時間，不是開機。whole 是從父 session 的第一個時間戳起算，開機根本不在 whole 裡；派工前（pre）也已經從 t0 起算。所以整發減最慢審查者 = 派工前 + 收尾 + （審查者層跨度 − 最慢審查者）。
  證據（tmp-B/stag.py）：A 的審查者開始時間依序是 G2-dir-1 [27,40,53]、G2-dir-2 [23,36,50]、G3-dir-1 [28,43,59,74]、G3-dir-2 [34,49,63]，每個間隔約 13–15s。跨度減最慢審查者分別是 14、16、46、29s，正好等於 82–122 減掉（派工前＋收尾）的差。舊組的審查者在 5–7s 時同時開跑，這個差只有 1s。
  建議改法：「開機」改成「依序派工的錯開時間（13–46s）」。這段時間是 A 做法本身的成本，不是量測雜訊。

[Important] 結論 2「扣掉收尾，A 的審查者層（139–226s）跟舊組（81–187s）同一個量級」，以及 G3-dhk-2 這一列
  問題 1：139–226 是「最慢的單一審查者」（rev_max），不是「整發扣掉收尾」。整發扣掉收尾是 178–289s（235−52、221−43、293−49、327−38），裡面還有派工前 23–34s 和錯開時間，跟舊組的整發 104–205 比，差距被低估了。
  問題 2：G3-dhk-2 是兩波派工。第 4 個審查者 a534fa（「C2_補完_C_未讀段」）到 205s 才開始，前 3 個在 58s 前就開了。所以「審查者層最慢 111s／收尾 43s」漏掉了中間約 51s 的父 session 工作，以及第二波；這一發的審查者層跨度實際是 287s。文件沒有提到這一發有補派（grep「補派／C2／第二波」都是 0 筆）。
  建議改法：「審查者層」改成明說是最慢的單一審查者，或另列一欄跨度；G3-dhk-2 加註兩波派工。

[Smell] 結論 2「慢約 1.7 倍」：269/153.5 = 1.75，四捨五入是 1.8；用四捨五入後的 269/154 也是 1.747。
[Smell] 結論 5「父 session 是 opus 並讀完整份 diff 檔」：checks.out 顯示 G3-dir-2 的父 session 缺 1700/3024 行，同一份文件的設計文件段也寫了這件事，兩處自相矛盾。應改成「讀了大部分」，或把 G3-dir-2 排除出這句。

Not reported
- 原始數字表 8 列、五組並排的時間與費用欄、S4 三組的值：逐格對過 stats.jsonl 與 s4/stats_all.jsonl，都相符。
- S4 與 S5 口徑：whole_s／t0／stamps 的定義在兩份 stats.py 裡相同；total_cost_usd 取最後一筆 result 是對的（多筆 result 的值是累計，jq 驗過）。
- 「一批同時跑同組的 G2、G3 兩發（S4 一批三發）」：起始時間戳證實（S5 每批同一秒開始；S4 每批是 new/old/hk 三發同時）。
- sec1.out、checks.out 的計數（9/13、13/15、2 個讀完的都在 B 組、res 1–3、cross 0）都正確。
- A 全部跑在 14:22–14:40、B 全部跑在 14:44–15:04，A、B 兩組沒有交錯跑，存在時段混雜。這屬於推論與限制，留給 D；文件的限制只寫了 S4 與 S5 不同時段。
- 「S4 那一節說的截斷發生在第二段」掛在「S4 新組」底下，但 S4 那節舉的截斷例子都是 haiku 組；所述事實（截斷點都在第二段）成立，所以不列。

需要外部查證
- G2-dir-1、G2-dir-2 的「exit 143、被看門狗結束」：logs 裡沒有 exit code，要看 run.sh 外層 wrapper 的輸出或看門狗腳本的紀錄才能確認。
- advisor 為什麼只在部分發出現（可能是全域環境自帶的工具）：要看 headless session 的工具清單來源。

What I ran
- sed 讀 diff 檔第 1–160、1940–2187 行 → 讀到 S5 段落、stats.py、run.sh、④ 機器輸出
- cat s4/stats_all.jsonl → 取 S4 三組的 whole、rev_max、cost
- git show 4e47492 → 看時間量法改了什麼（只有措辭與口徑，S4、S5 都改成 整發−rev_max）
- diff S4 與 S5 stats.py 從 run_stats 到檔尾 → whole_s 與 t0 定義相同
- jq 讀 8 發 result 的 cost／api／dur → 多筆 result 的 cost 是累計，最後一筆正確
- tmp-B/win.py → 每發的起訖時間（證實分批方式，A、B 沒有交錯）
- tmp-B/stag.py → 審查者開始與結束的相對秒數；A 是依序派工、相隔 13–15s；G3-dhk-2 第 4 個審查者在 205s 才開始；舊組 5–7s 同時開跑
- jq 讀 result.modelUsage（S5 8 發、S4 12 發）→ G2-dhk-1 fable 2.1、G3-dhk-1 fable 2.9、S4 G3-hk-1 fable 1.41
- tmp-B/adv.py → G2-dhk-1 的 advisor 在 193→414s、G3-dhk-1 在 291→493s；A 組 0 次
- tmp-B/adv4.py（S4）→ G3-hk-1 裁決者的 advisor 在 18:38:16→18:40:12
- git grep -i 'advisor|fable' -- docs/ → 0 筆
- grep run.sh（S4）→ 父 session 是 haiku、budget 10

暫存腳本放在 <scratchpad>/S5-review/tmp-B/
````

## 處置

編號指 `S5-judge.md` 的採納／駁回項；修正在本段步驟 4 之後的 commit。

- B-Critical（advisor）→ 採納 1，同 S5-a
- B-Important1（S4 G3-hk-1 也叫了 advisor）→ 採納 2：結論 3 區間改成 132–197s 並說明，設計文件加註
- B-Important2（開機）→ 採納 3
- B-Important3 問題 1（「扣掉收尾」措辭）→ 採納 12（調成 Smells）：結論 2 改成「最慢的單一審查者」；「差距被低估」駁回
- B-Important3 問題 2（補派 C2）→ 採納 4
- B-Smell1（1.7 應為 1.8）→ 駁回（269/154=1.747）
- B-Smell2（父 session 沒讀完）→ 併入採納 5
