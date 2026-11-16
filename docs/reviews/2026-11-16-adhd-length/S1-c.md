# S1-c（審查者 C）— ADHD output style 加長度上限

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），三個在同一則訊息平行派出，在步驟 3（code-simplifier）做完、還沒 commit 的時候。方向：文件宣稱對不對得上資料。
Agent 呼叫的 prompt 只有一句「完整的派工說明在這個檔，先用 Read 讀完再照做」加檔案路徑，另寫明全程唯讀、報告用文字交回；那個檔的內容如下
（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是程式碼審查者（代號 C）。審查 claude-dd repo（<repo>）一個功能段落的整段變更。你的職責：找漏洞、找錯的宣稱，每一條都附證據；沒有證據的不算發現。不寫優點。
>
> ## 這一段做了什麼（事實）
> - 使用者 2026-11-16 說：「我發現 output-style ADHD, 這個 回答一點都不適合給ADHD, 還是給我一堆字 要我閱讀一堆」
> - 段落起點 7e1ff44。改了 output-styles/adhd.md（Claude Code 的 output style，部署到 ~/.claude/output-styles/）：新增「長度」「範例」兩節，改寫「誰優先」、規則 1、4、5、7、9、「什麼時候可以不照」第 1 點
> - 新增量測目錄 docs/measurements/2026-11-16-adhd-length/（run.sh、check.sh、selftest.sh、measure.sh、CLAUDE.md、out/）：用 claude -p 跑舊版與新版兩臂、三個 prompt 各 n=2，check.sh 判定。跑了三批：第 1、2 批不通過，第 3 批通過
> - 同步了 README.md、README.zh-TW.md、output-styles/LICENSE.txt、CHANGELOG.md、DD_PIPELINE_ARCHITECTURE.md；新增設計文件 docs/designs/2026-11-16-adhd-length-design.md，根目錄 CLAUDE.md 加了一句進度指路
> - 「一則最多 10 行」這個數字是做這段的人自己定的，使用者沒有指定數字
> - templates/global/CLAUDE.md（全域模板）這一段刻意沒改（使用者 2026-10-29 的決定）
> - 步驟 3（code-simplifier）改了 run.sh 與 measure.sh，還沒 commit
>
> ## 材料
> 全部在這個檔：<scratchpad>/review-diff.txt（共 2364 行，最後一行是「########## 檔尾」）。
> 用 Read 的 offset／limit 每次 300 行讀到最後一行（Read 一次讀太多會靜靜截斷、不報錯）。
> - ① 整段 diff（git diff 7e1ff44，不含 out/ 的實測輸出）
> - ② 步驟 3 自己改了什麼（分開附：simplifier 有沒有改到行為也要看）
> - ③ 被改到的檔的整檔內容；被改到的檔一律讀這一份，不讀工作目錄
> - ④ 已經跑過的驗證與預期值：這些已確認，不要重跑。「跑過」不代表結果對，要看的是它驗的是不是該驗的東西
> 沒被改到的檔、以及 out/ 底下的實測輸出（docs/measurements/2026-11-16-adhd-length/out/batch*/*.jsonl，每個檔的 result 那一筆有 .result 回覆全文）照常從 repo 讀。
> 專案規則在根目錄 CLAUDE.md 與各層 CLAUDE.md（例如 docs/measurements/CLAUDE.md、「新增 Output Style 步驟」「注意事項」）。
>
> ## 你的方向
> 文件裡的宣稱對不對得上實際資料。①CHANGELOG.md 新條目、docs/measurements/2026-11-16-adhd-length/CLAUDE.md（各批結果、保留題、沒證明的）、設計文件、DD_PIPELINE_ARCHITECTURE.md、兩份 README 的每一個數字與宣稱，拿 out/ 的檔與 check.out、styles.txt 逐一核對（行數、字數、blob、發數、日期、哪一批過不過）②保留題的規則（最多 10 發、每發 10 行內而且 400 字內才進第 3 批、新版措辭不拿 P1 到 P3 試）寫進文件並 commit 的時間點，是不是真的早於跑保留題與第 3 批：用 git log 與各 commit 的內容核對 ③專案規則要求同批同步的地方有沒有漏（根目錄 CLAUDE.md「新增 Output Style 步驟」「注意事項」裡 CI 不驗、只能手動同步的區塊；兩份 README 內容是否一致）④「沒證明的」一節有沒有漏掉該講的限制、或把沒證明的事講成證明了
> 方向是重點，不是邊界：看到方向以外的問題照樣報。
>
> ## 規則
> - 全程唯讀：只能讀檔、grep、git log／show／diff、跑 jq 讀 out/ 的檔。不改檔、不 commit、不跑 run.sh（會呼叫 claude -p、要花錢）、不跑安裝腳本、不動 ~/.claude/
> - 只用手上的資料判斷；需要外部查證的（例如上游 i-have-adhd 的原文、Claude Code 的實際行為）列在「需要外部查證」交回，不要猜
> - 每條發現附證據：檔名加原文（行號可能對不上，以你引的原文為準），或你跑的指令與輸出；寫出具體的失敗情境（誰、在什麼情況下、會得到什麼錯的結果）
> - 分級：Critical（照現況會出錯或誤導而且沒有別的關卡擋得住）／Important（該修）／Smells（順手可改）
> - 報告用繁體中文，直接用文字交回，不要寫成檔
>
> ## 輸出格式（照這些標題）
> 【摘要】Critical N／Important N／Smells N
> 【發現】每條：編號｜級別｜一句話｜證據｜失敗情境｜建議改法
> 【Not reported】看過、判斷不算發現的，各一句理由
> 【What I ran】讀了哪些檔、跑了哪些指令
> 【需要外部查證】

diff 檔 `<scratchpad>/review-diff.txt`（2364 行）的組成：① `git diff 7e1ff44`（不含 `out/` 的實測輸出，另附檔名清單）② 步驟 3 的改動 `git diff HEAD`
③ 被改到的檔的整檔內容（`adhd.md`、`LICENSE.txt`、四支腳本、量測目錄 CLAUDE.md、設計文件；README、CHANGELOG、架構文件、根目錄 CLAUDE.md 只放 diff）與起點那一版的 `adhd.md`
④ 已跑過的驗證與預期值（三批的 `check.out`、自測、保留題的量測、步驟 3 的行為不變檢查、`tests/test-install.sh`、LICENSE 引句驗收、去識別掃描）。
被審的是 `deddc75` 加上步驟 3 還沒 commit 的改動。

## 發現

審查者交回的原文（從它的紀錄檔抽出，沒有改字）：

> 【摘要】Critical 0／Important 4／Smells 3
>
> 先講結論：文件裡的數字都對得上 out/；保留題的規則也確實在跑保留題之前就 commit 了。問題出在三件事：CHANGELOG 講錯了原因、有一條規則沒量、有一處行為改變沒寫進 CHANGELOG。
>
> 【發現】
>
> 1｜Important｜CHANGELOG 把「字數降下來」歸給「點名不寫哪些內容」，這跟前兩版的實際措辭不符，也跟量測文件自己寫的「分不出是哪一處」矛盾。
> - 證據：CHANGELOG 新條目寫「前兩批不通過：只寫行數上限或總字數上限時，行數降了、字數沒降；第三版改成點名不寫哪些內容才降下來」。
> - `git show f3dbcd6:output-styles/adhd.md`（第一版）的長度第 1 條是「一行講一件事，約 40 個字以內」。第一版有每行字數上限，不是「只寫行數上限」。
> - `git show e3a84da:output-styles/adhd.md`（第二版）第 2 條已經寫了「沒被問到的背景、排序的理由、其他可能性不寫」。也就是第二版已經點名過不寫哪些內容。
> - `docs/measurements/2026-11-16-adhd-length/CLAUDE.md`「沒證明的」寫：「第三版同時改了好幾處，分不出是哪一處讓字數降下來」。
> - 另外，第 1 批 NEW 的 P1 是 513、496 字，OLD 是 826、704 字（`out/batch1/check.out`）。跟舊版比，字數其實有降，「字數沒降」只在第 2 批對第 1 批時成立。
> - 失敗情境：之後有人要再調 ADHD 或其他風格的措辭，照 CHANGELOG 會以為「點名不寫的內容」是有效的那一招，只往這個方向改。實際上第二版就有這一招，照樣沒過。
> - 建議改法：改成「第一版每行約 40 字、第二版 10 行加 300 字，都是行數降、字數沒降；第三版同時改了好幾處（每行 30 字、點名不寫、必留各一行、來源只標一次、範例），分不出是哪一處有效」。
>
> 2｜Important｜CHANGELOG 宣稱「每行一句 30 個字以內」，但驗收沒量這一條，第 3 批 NEW 大部分的行都超過，「沒證明的」也沒寫這件事。
> - 證據：對 `out/batch3/NEW-p*.jsonl` 逐行算 `jq length`，結果如下：
>   - p1-r1 最長 68 字，5/8 行超過 30
>   - p1-r2 最長 69 字，5/8
>   - p2-r1 最長 118 字，4/5
>   - p2-r2 最長 144 字，4/5
>   - p3-r1 最長 71 字，8/11
>   - p3-r2 最長 62 字，7/10
>   - 合計 33/47 行超過 30 字
> - `check.sh` 的長度斷言只有內容行 ≤10、總字數 ≤500、圍欄 ≤6，沒有每行字數。
> - 失敗情境：使用者看 CHANGELOG 或 README「10 行」會以為一則回覆大約一個畫面。實際上 NEW-p2-r2 的一行有 144 個全形字，80 欄的終端機會折成大約 4 列，「5 行」在畫面上超過 10 列。使用者抱怨的正是「一堆字」。
> - 建議改法：在「沒證明的」與 CHANGELOG 加一行「每行 30 字沒有斷言；第 3 批 NEW 47 行裡有 33 行超過，最長 144 字」。或者把 CHANGELOG 裡的「每行 30 字」改成只是規則內容、不算實測結果。
>
> 3｜Important｜「誰優先」的語意變了，CHANGELOG 沒寫，LICENSE 的對應也因此不準。
> - 舊版寫「使用者當下的明確指示與 CLAUDE.md 的規則，都優先於這份風格」。
> - 新版只剩「使用者當下的明確指示優先於這份風格」，並加了「每一樣都寫到最短：任務結束回報每一節 1 到 2 行」。
> - 結果是：CLAUDE.md 不再被宣告優先於風格，而且風格開始限制 CLAUDE.md 規定的回報長度。
> - 證據：
>   - review-diff ① adhd.md 的「誰優先」新舊兩段。
>   - CHANGELOG 新條目（L60–67）沒有一句提到「誰優先」。
>   - `output-styles/LICENSE.txt` 寫「When to break the rules 6（a rule fights the harness）—— 改寫，併入「誰優先」：第二段的「CLAUDE.md 要求出現的每一樣照樣要有」（上游的 system prompt outranks）」。上游的意思是 system prompt 優先，新版第二段卻是風格去壓縮 CLAUDE.md 要求的內容。
> - 失敗情境：使用者照 CHANGELOG 升級，不知道開著 ADHD 時全域 §4.5 回報、§1.2「但注意 X」這類條件句會被壓成每節 1 到 2 行。出問題時去查 CHANGELOG 也找不到原因。
> - 建議改法：CHANGELOG 補一句「誰優先」改了什麼，並附設計文件 A3 的理由。LICENSE 那一條註明「已不再是 outranks：要求的項目保留，但長度由本風格限制」。
>
> 4｜Important｜53 發全部只在 `claude-fable-5-2` 一個模型上跑，「沒證明的」與 CHANGELOG 都沒寫這個限制。
> - 證據：`jq -r 'select(.kind=="result")|.models|join(",")' out/*/*.jsonl | sort | uniq -c` 輸出 `53 claude-fable-5-2`。
> - 量測 CLAUDE.md 只寫「預設模型」，設計文件裡提到的 haiku 只用在載入探針與 fixture 試跑。
> - 失敗情境：使用者換成 opus 或 sonnet 當主模型時（memory 記錄他會換模型），「新版 5 到 8 行」這個結論沒有證據撐，卻寫得像通用結果。
> - 建議改法：「沒證明的」加一行「只測了 claude-fable-5-2（2026-11-16 到 17 的預設模型），其他模型沒測」，CHANGELOG 的實測那句也帶上模型名。
>
> 5｜Smells｜引用的中間措辭 blob `f3609bb`、`2a0a3e7` 不在 git 裡，讀者沒辦法查看那兩份措辭。
> - 證據：`git log --find-object=f3609bb 7e1ff44..HEAD` 回「不能解析 'f3609bb'」，`2a0a3e7` 也一樣。量測 CLAUDE.md「保留題」逐份列出這兩個 blob，還說「三批加保留題一共試了 5 份措辭」。
> - 失敗情境：之後有人想看第三版第一份、第二份改了什麼、為什麼 401 字那一發之後要「再收緊」，只能拿到 blob 號碼，拿不到內容。「5 份措辭」這句也沒辦法核對。
> - 建議改法：把兩份中間版本存進各自的 `out/batchdev*/`（例如 `style.md`），或者在文件裡註明「中間版本沒有留存」。
>
> 6｜Smells｜P3 的「有鑑別力」有一部分靠的是扣除行規則，不是長度。CHANGELOG 把 P3 扣過的數字和 P1、P2 混在同一個範圍裡。
> - 證據：
>   - `out/batch3/check.out`：`OLD-p3-r1 行 7 字 404 … L✗[ 扣除行 ]`。這一發的行數和字數都在 10 行、500 字內，只因為含檔名的兩行分別是 105、135 字（我用 jq 量的）而判紅。
>   - 加回扣掉的兩行，OLD-p3-r1 實際約 644 字。
>   - CHANGELOG 寫「舊版六發 7 到 18 行、404 到 852 字」，404 是扣過之後的數字，但條目沒有說 P3 有扣除。
> - 失敗情境：讀者會以為舊版每一發都超過上限，其實 OLD-p3-r1 以總長度來看已經在上限內。
> - 建議改法：CHANGELOG 註明「P3 扣掉含檔名的行」，或者把 P3 的範圍分開列。
>
> 7｜Smells｜2026-10-29 驗收的鑑別特徵沒有在新版上重驗，但架構文件仍然拿它當出貨版的實證。
> - 證據：
>   - `DD_PIPELINE_ARCHITECTURE.md` L103–104 寫「實證來源為 `docs/measurements/2026-10-29-adhd-style/` 的行為驗收實跑（2026-11-17 加長度上限…）」。
>   - 2026-10-29 的 `d3`（具體時間估計）與 p1「列齊 7 項」守門，在新的 `check.sh` 裡都沒有。
>   - 第 3 批 NEW 六發最後一行都是「下一步：」（我看過），所以 `d1` 那一項從輸出看得出來還在；`d3` 沒有任何資料。
> - 失敗情境：新版的 10 行上限可能把時間估計擠掉，但兩份驗收都不會發現。
> - 建議改法：「沒證明的」加一行「2026-10-29 的 d3（時間估計）與 7 項全列守門沒有在新版上重跑」。
>
> 【Not reported】
> - 保留題規則的時間點沒問題：規則在 cd1efcd 裡（commit 時間 23:58:56），`batchenvp3/styles.txt` 的修改時間是 23:59:03，batchdev1 是 23:59:34，batch3 是 00:02:15，都晚於 commit。
> - 各批數字逐項對過都對得上：
>   - 第 1 批：10、9 對 12、15；513、539；P3 四發 outside=1；OLD 一發 denials=1。
>   - 第 2 批：586、568、511、495；P3 四發都紅在扣除行；outside 都是 0；denials 1 的是 NEW-p3-r2 與 OLD-p3-r2。
>   - dev1 到 dev10 的行數與字數；batchenvp3；第 3 批的範圍；設計文件裡 2026-10-29 的八個長度（499…391）；起點那一版 48 行與第 7 行原文。
> - 兩份 README 的 `/output-style ADHD` 那一列內容一致。安裝步驟那句與 `show_completion()` 都不描述風格內容，不需要跟著改。
> - 日期一致：架構文件寫 2026-11-17、LICENSE 寫 16 到 17、commit 時間落在 11-16 23:42 到 11-17 00:11。
> - LICENSE 裡的段落序號（「誰優先」第二、三、四段）與新版對得上。
> - 步驟 3 對 run.sh 與 measure.sh 的改動：④ 已經用假的 claude 做過 diff -r，我沒有另外找到行為差異。
>
> 【What I ran】
> - Read：prompt-C.txt；review-diff.txt 第 1–1498 行與 2258–2364 行（③ 的 check.sh、selftest.sh、measure.sh、CLAUDE.md、設計文件整檔與 ① 內容相同，沒有重讀）；`docs/measurements/2026-10-29-adhd-style/CLAUDE.md`、`out/p1.prompt.txt`
> - `cat out/batch{1,2,3}/{styles.txt,check.out}`、`out/batchdev*/styles.txt` → 數字與 blob 如上
> - `git log --format='%h %ad %s' 7e1ff44..HEAD` 與 `--find-object` 查五個 blob → 61b28fc、01b3425、2f82e10 都在 git 裡；f3609bb、2a0a3e7 解析不到
> - `stat` 各批 styles.txt、batch3 jsonl 與 check.out 的修改時間 → 時間序如上
> - `git show cd1efcd --` 兩份文件 → 保留題規則在這個 commit 裡
> - `git show f3dbcd6:` 與 `e3a84da:output-styles/adhd.md` 的「長度」一節 → 第一版有每行 40 字，第二版已點名不寫的內容
> - 對 batch3 NEW 逐行 `jq length` → 33/47 行超過 30 字，最長 144
> - `jq .models out/*/*.jsonl | uniq -c` → 53 發都是 claude-fable-5-2
> - batch3 各發最後一行、OLD-p3-r1 全文與扣除行長度（105、135）
> - 對 2026-10-29 的 out/*.jsonl 跑 `jq length`；`git show 7e1ff44:output-styles/adhd.md | wc -l`
> - `grep ADHD/adhd` 掃 install-dd-pipeline.sh、兩份 README、DD_PIPELINE_ARCHITECTURE.md、UPGRADING.md；`git grep` 舊措辭
>
> 【需要外部查證】
> - 上游 i-have-adhd 的「a rule fights the harness」原文，是不是明確寫 system prompt outranks the style（影響第 3 條 LICENSE 對應的判斷）。
> - Claude Code 終端機對全形字的實際折行寬度（影響第 2 條「畫面上超過 10 列」的估計，目前是按 80 欄、一個全形字佔 2 欄推算的）。

## 處置

| 發現 | 級別 | 處置 |
|---|---|---|
| C1 CHANGELOG 的因果句與前兩版的實際措辭不符 | Important | 採納。查證：第一版（`f3dbcd6`）有「約 40 個字以內」，第二版（`e3a84da`）已有「其他可能性不寫」。CHANGELOG 改成分別寫第一、二版各是什麼、各怎麼不過，第三版「分不出是哪一處有效」 |
| C2 每行 30 字沒量 | Important | 採納，同 A5、B1。C 算的分母是 47 行（P3 把標題行也算進去），主對話照 `check.sh` 的內容行算是 41 行，文件用 41 |
| C3 「誰優先」語意變了，CHANGELOG 沒寫 | Important | 採納。CHANGELOG 補一句「誰優先」改了什麼；LICENSE.txt 加註（同 A7） |
| C4 只在一個模型上跑 | Important | 採納。查證：`out/` 裡 result 都是 `claude-fable-5-2`（C 算的時候 53 筆，加上第 4 批是 67 筆）。寫進「沒證明的」與 CHANGELOG |
| C5 兩份中間措辭的 blob 不在 git 裡 | Smell | 採納。從 `2f82e10` 把後來加的句子拿掉重建，`git hash-object` 對上 `f3609bb`、`2a0a3e7`，存進量測目錄的 `styles/` |
| C6 P3 的數字是扣過的，CHANGELOG 混在一起講 | Smell | 採納。CHANGELOG 把第三題分開列，並註明先扣掉列檔名的行 |
| C7 2026-10-29 的鑑別特徵沒在新版重驗 | Smell | 採納。寫進「沒證明的」 |

外部查證兩項都沒查：上游「a rule fights the harness」的原文、終端機對全形字的折行寬度（C2 的「畫面上超過 10 列」是 C 的估計，文件裡沒有引用這個數字）。
