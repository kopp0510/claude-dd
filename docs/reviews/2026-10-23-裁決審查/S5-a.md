# S5-a — 拿掉裁決者的對照（審查者 A 腳本正確性）

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
# S5 審查者 A（腳本正確性）完整報告（逐字）

派工 prompt：見同目錄 prompt.md 的「共用部分」＋「A：腳本正確性」；啟動訊息為「先用 Read 整份讀完 …/S5-review/prompt.md（它是你的完整任務說明）。照「共用部分」做，你的代號是 A，方向是「各自方向」裡的「A：腳本正確性」。其他方向（B、C、D）由別人負責，不必做。最後照「報告格式」交回完整報告。」

---

審查者 A（方向：腳本正確性），範圍 9798edc..HEAD。結果：Critical 1、Important 3、Smells 0。

腳本本身算出來的數字都對得上原始紀錄：每次 Read 的回傳都是字串、沒有回傳 0 行的，派工前的秒數也逐發相符。問題出在 `stats.py` 有兩件事沒檢查到，加上一項指標的定義，這些讓 B 組的結論和費用欄不可靠。

## Critical

**[C1] `stats.py` 的模型檢查漏掉 advisor：B 組兩發其實還有第三個模型（fable）參與，時間、費用、命中三方面都受影響**
- 位置：`2026-10-24-s5-inputs/stats.py`（diff 檔第 475–476 行）只看 assistant 訊息的 `message.model`。`run.sh` 的 `--allowedTools` 擋不住 server tool。所以量測文件第 88 行寫的「模型斷言全過」不成立。
- 證據：
  - 用 `jq ... .modelUsage` 讀 `s5/logs/*.jsonl` 最後一筆 result：
    - G2-dhk-1 是 `{"claude-opus-5-5":1.636,"claude-haiku-5-5":0.376,"claude-fable-5-1":2.095}`
    - G3-dhk-1 是 `{...opus 2.998, haiku 0.591, "claude-fable-5-1":2.899}`
    - 另外 6 發都沒有 fable。
  - 這兩發的父 session jsonl 各有一筆 `server_tool_use:advisor`：
    - G2-dhk-1：06:47:31.551 送出，06:51:12.634 拿到 `advisor_tool_result`，花了 **221s**。
    - G3-dhk-1：06:49:09.801 送出，06:52:31.360 拿到，花了 **202s**。送出的時間點就在「四個審查者都回來了，正在逐條查證」之後，接著父 session 就寫了報告。
  - 回傳內容是 `advisor_redacted_result`（加密），看不到它講了什麼。
- 影響：
  - B 組最慢的兩發（503s、529s）和兩個最長的收尾（177s、304s）都含 advisor 的 200 多秒。G3-dhk-1 的收尾 304s 裡有 202s 是 advisor。
  - 這兩發費用裡有 51%／45% 是 fable 的錢。扣掉後 B 組費用平均約 2.78，不是 4.03，所以結論 4 的「只比 A 少約 20%」不成立。
  - 結論 4 的「父 session 要花更多時間查 haiku 的報告」，把 advisor 的耗時歸給了 haiku。
  - K6 寫的「B 兩發都是父 session 自己查到的」，其中 G3-dhk-1 那發是在問完 fable 之後才寫報告。
  - S4 也有同樣的污染（屬既有問題，但 S5 的五組並排有引用）：`s4/logs/G3-hk-1.jsonl` 的 modelUsage 有 `"claude-fable-5-1":1.41`。
- 建議改法：
  - 量測文件把這兩發標成「混入 advisor（fable）」，B 組的時間、費用、K6 改成另算或註明。
  - 作廢檢查要讀 result 的 `modelUsage` 鍵，出現預期以外的模型就作廢；或查 `server_tool_use`。
  - 下一輪實驗要擋掉 advisor。`--disallowedTools` 能不能擋它，見下面「需要外部查證」。

## Important

**[I1] 「審查者層最慢」這項指標遇到補派就算錯：G3-dhk-2 表上寫 111s，實際審查者從第 29s 跑到第 316s 左右**
- 位置：`stats.py` 的 `rmax = max(a["sec"] for a in revs)`（diff 檔第 489 行）。這是取「單一審查者」最長的時間，不是審查者層從頭到尾的跨度。
- 證據：我寫的 span.py 印出各審查者的開始時間。G3-dhk-2 是 `starts [29, 43, 58, 205]`：第 4 個審查者（`a534fa`「審查者_C2_補完_C_未讀段」）是第一波回來之後才補派的。量測文件的表和段落都沒提到這次補派。
- 建議改法：表上加註「含補派一個審查者」，或者這一欄改用「第一個審查者開始到最後一個結束」的跨度。

**[I2] 結論 3 把剩下的時間標成「＋開機」，但 `whole_s` 根本不含開機時間；那段其實是審查者錯開啟動的時間**
- 位置：量測文件結論 3（diff 檔第 125 行）寫「A 82–122s（派工前 23–34s ＋收尾 38–52s ＋開機）」。
- 證據：
  - `stats.py` 的 `t0` 取的是父 session jsonl 的第一個時間戳（diff 檔第 493 行）。這時 CLI 已經啟動完，所以整發時間不含開機。
  - span.py 實測 A 組 4 發扣掉 pre、post、最慢審查者之後，還剩 14、16、46、29s，剛好等於審查者啟動時間的差距：
    - G2-dir-1：`starts [27, 40, 53]`
    - G3-dir-1：`starts [43, 74, 28, 59]`
  - 也就是說，說明裡要求「同一則訊息平行派」，實際上審查者是每隔約 13–15s 才起一個。
- 建議改法：把「＋開機」改成「＋審查者錯開啟動」。這個口徑能不能拿來跟 S4 的「整發減審查者層最慢」比，由 B／D 判斷。

**[I3] 最後一筆 result 的費用和 API 時間會漏掉最後一輪，`cost`／`api_s` 偏低**
- 位置：`stats.py` 的 `last = res[-1]`，再取 `total_cost_usd`、`duration_api_ms`（diff 檔第 458、497–498 行）。
- 證據：用 jq 讀各筆 result 的 `.usage.output_tokens`（該輪產出）和 `.modelUsage.outputTokens`（累計）：
  - G3-dir-1：最後一輪 output 4792，累計值兩次都是 67068，沒動；cost 三筆都是 6.8928。
  - G3-dir-2：最後一輪 3320，累計 61501 沒動。
  - G2-dhk-2：最後一輪 4344，累計 opus 17434 沒動。
  - G3-dhk-2：最後一輪 3896，累計 30392 沒動。
  - G2-dir-1 第 4 輪倒是有加進去：36110→40940，剛好多 4830，cost 3.807→3.952。
- 影響：用 G2-dir-1 那一輪推估，每次漏算約 US$0.15，4 發偏低約 2–4%。結論方向不受影響。S4 用的是同一種算法，所以這是既有問題延續下來。
- 建議改法：量測文件在費用欄加註「偏低，最後一輪不一定記入」；或者改用每輪 `usage` 自己加總。

## Not reported
- 讀 diff 檔的行數（`checks.py`、`sec1.py`）：我擔心過 regex `^\s*(\d+)\t` 遇到 list 型的結果（`json.dumps` 會把 tab 變成跳脫字元）或大輸出被存成外部檔時，會算成 0 行。實測 8 發共 280 次 Read diff.txt，回傳全是字串，0 筆抽不出行號，所以缺行數可信。diff 檔第二段每行開頭也有 `N\t`，但 `^` 只錨在 Read 自己加的行號上，不會重複計算。
- `sec1.py` 只算 code-reviewer，`checks.py` 算全部子代理：判法不一樣，但 S5 的子代理全是 code-reviewer，結果相同。
- `cross` 檢查有盲區：它不涵蓋旁邊的 `scratchpad/s4/`（裡面有 S4 的報告和答案）和 `s5/reports/`；`leaky()` 對 `/private/tmp/...` 開頭的絕對路徑也不會命中。我自己掃了 8 發所有工具輸入，找 `scratchpad/s4`、`/s4/`、`reports`、`s5-outputs`、`measurements`、`logs/`，唯一命中的是 G3-dir-1 aa2813 某個 Bash 的 description 字串（"pre-commit checks reports"），不是真的去讀。所以「8 發 0 筆」的結論成立，只是檢查本身不夠完整。
- `checks.py --dump` 取最後一筆非空 result：各發最後一筆長度 3296–4301 字元，都是正式報告，不是「等待中」那種短訊息。
- G2-dir-1／G2-dir-2 被看門狗結束：父 jsonl 最後一筆是 `stop_hook_summary`，時間緊接在最後一則 assistant 之後，沒有尾巴把整發時間拉長。
- G2-dhk-2 的洩題誤報（`ROOT_ARG` 吃到 echo 字串裡的「 / 」）：沿用 S4 那份，屬既有問題，量測文件已經承認。
- `prepare.py`／`run.sh` 跟 S4 版的差異：只改了模型（haiku→opus）、預算、prompt 來源，另加 `{LINES}`。佔位檢查改成 `for k in rep`，涵蓋的鍵比 S4 多，沒有引入偏差。
- step 3 拿掉 `judge` 變數：S5 版的 `run_stats` 之後沒有任何地方讀 `judge`，輸出不變。

## 需要外部查證
- `claude -p --disallowedTools advisor`（或其他寫法）能不能擋掉 advisor 這個 server tool；advisor 是不是由使用者帳號層的設定開的。這決定下一輪實驗怎麼擋它。
- result 的 `total_cost_usd`／`modelUsage` 為什麼有時不含最後一輪：是 Claude Code 的已知行為，還是要用別的欄位。
- advisor 的回傳是加密的，fable 在 G3-dhk-1 對 K5／K6 的判定有沒有影響，從紀錄上判斷不出來。

## What I ran
- 用 Read 讀 diff 檔第 1–593 行、第 2113–2187 行 → 讀了腳本全文和第 ④ 段的輸出
- `diff` S4 與 S5 的 `stats.py`、`prepare.py`、`run.sh` → 差異就是上面列的那些，`leaky()` 那段沒動
- `jq 'select(.type=="result")|{cost,api,dur,turns,len}'` 讀 s5 各 log → 例如 G3-dir-1 三筆 cost 都是 6.8928，最後一筆 dur 48685ms
- `jq '.modelUsage'` 讀 s5 和 s4 的 logs → G2-dhk-1、G3-dhk-1、S4 G3-hk-1 有 `claude-fable-5-1`（2.095／2.899／1.41）
- grep `claude-fable`，再用 jq 找 `server_tool_use` → 只有 G2-dhk-1、G3-dhk-1 的父 session 各呼叫 advisor 一次，其他發是 0
- 用 jq 列出時間線 → advisor 耗時 221s（06:47:31→06:51:12）、202s（06:49:09→06:52:31）
- `tmp-A/probe.py`（統計 Read diff.txt 的回傳型別和抽不出行號的筆數，並掃有沒有越界路徑）→ 8 發全是 `('str','',False)`，越界只有 1 筆，是 description 文字
- `tmp-A/span.py`（各審查者的開始時間）→ pre 與 `stats.jsonl` 逐發相同；A 組啟動錯開 14–46s；G3-dhk-2 有第 4 個審查者在第 205s 才啟動（這支腳本的 whole／post 欄有 bug，我沒採用那兩欄）

暫存腳本：
- <scratchpad>/S5-review/tmp-A/probe.py
- <scratchpad>/S5-review/tmp-A/span.py
````

## 處置

編號指 `S5-judge.md` 的採納／駁回項；修正在本段步驟 4 之後的 commit。

- A-C1（advisor 參與 B 組）→ 採納 1（Critical）與 2：量測文件「原始數字」補 advisor 那條、五組並排 B 與 S4 haiku 兩列加註、結論 4 改寫；設計文件 132–297 加註
- A-I1（G3-dhk-2 補派 C2）→ 採納 4：原始數字表加註、補一條說明
- A-I2（「＋開機」標錯）→ 採納 3：結論 3 改成「審查者依序開跑的錯開時間 14–46s」
- A-I3（費用取最後一筆偏低）→ 採納 10（調成 Smells）：原始數字說明加註
