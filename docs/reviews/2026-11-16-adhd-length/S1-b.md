# S1-b（審查者 B）— ADHD output style 加長度上限

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），三個在同一則訊息平行派出，在步驟 3（code-simplifier）做完、還沒 commit 的時候。方向：量測腳本與判準。
Agent 呼叫的 prompt 只有一句「完整的派工說明在這個檔，先用 Read 讀完再照做」加檔案路徑，另寫明全程唯讀、報告用文字交回；那個檔的內容如下
（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是程式碼審查者（代號 B）。審查 claude-dd repo（<repo>）一個功能段落的整段變更。你的職責：找漏洞、找錯的宣稱，每一條都附證據；沒有證據的不算發現。不寫優點。
>
> ## 這一段做了什麼（事實）
> - 使用者 2026-11-16 說：「我發現 output-style ADHD, 這個 回答一點都不適合給ADHD, 還是給我一堆字 要我閱讀一堆」
> - 段落起點 dd6bffa。改了 output-styles/adhd.md（Claude Code 的 output style，部署到 ~/.claude/output-styles/）：新增「長度」「範例」兩節，改寫「誰優先」、規則 1、4、5、7、9、「什麼時候可以不照」第 1 點
> - 新增量測目錄 docs/measurements/2026-11-16-adhd-length/（run.sh、check.sh、selftest.sh、measure.sh、CLAUDE.md、out/）：用 claude -p 跑舊版與新版兩臂、三個 prompt 各 n=2，check.sh 判定。跑了三批：第 1、2 批不通過，第 3 批通過
> - 同步了 README.md、README.zh-TW.md、output-styles/LICENSE.txt、CHANGELOG.md、DD_PIPELINE_ARCHITECTURE.md；新增設計文件 docs/designs/2026-11-16-adhd-length-design.md，根目錄 CLAUDE.md 加了一句進度指路
> - 「一則最多 10 行」這個數字是做這段的人自己定的，使用者沒有指定數字
> - templates/global/CLAUDE.md（全域模板）這一段刻意沒改（使用者 2026-10-29 的決定）
> - 步驟 3（code-simplifier）改了 run.sh 與 measure.sh，還沒 commit
>
> ## 材料
> 全部在這個檔：<scratchpad>/review-diff.txt（共 2364 行，最後一行是「########## 檔尾」）。
> 用 Read 的 offset／limit 每次 300 行讀到最後一行（Read 一次讀太多會靜靜截斷、不報錯）。
> - ① 整段 diff（git diff dd6bffa，不含 out/ 的實測輸出）
> - ② 步驟 3 自己改了什麼（分開附：simplifier 有沒有改到行為也要看）
> - ③ 被改到的檔的整檔內容；被改到的檔一律讀這一份，不讀工作目錄
> - ④ 已經跑過的驗證與預期值：這些已確認，不要重跑。「跑過」不代表結果對，要看的是它驗的是不是該驗的東西
> 沒被改到的檔、以及 out/ 底下的實測輸出（docs/measurements/2026-11-16-adhd-length/out/batch*/*.jsonl，每個檔的 result 那一筆有 .result 回覆全文）照常從 repo 讀。
> 專案規則在根目錄 CLAUDE.md 與各層 CLAUDE.md（例如 docs/measurements/CLAUDE.md、「新增 Output Style 步驟」「注意事項」）。
>
> ## 你的方向
> 量測腳本與判準（run.sh、check.sh、selftest.sh、measure.sh）。①check.sh 的「通過」是不是真的證明了它說的事：有沒有哪個斷言在該紅的時候不會紅、或在不該紅的時候紅；P3 的扣除行規則有沒有讓過長的回覆溜過去 ②第 3 批通過是不是因為對的理由：拿 out/batch3/ 的實際回覆自己用 jq 讀出來對 check.out 的數字與守門結果 ③run.sh 三次修改（標記檔移出、只放一臂的風格檔、P3 題目多一句、ONLY 單發模式、保留題）有沒有讓第 3 批與前兩批不可比、或讓 NEW／OLD 兩臂拿到不同的條件 ④步驟 3 的改動（材料 ②）有沒有改到行為 ⑤bash 3.2 相容、set -e／管線的坑、zsh 無關（腳本用 bash 跑）
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

diff 檔 `<scratchpad>/review-diff.txt`（2364 行）的組成：① `git diff dd6bffa`（不含 `out/` 的實測輸出，另附檔名清單）② 步驟 3 的改動 `git diff HEAD`
③ 被改到的檔的整檔內容（`adhd.md`、`LICENSE.txt`、四支腳本、量測目錄 CLAUDE.md、設計文件；README、CHANGELOG、架構文件、根目錄 CLAUDE.md 只放 diff）與起點那一版的 `adhd.md`
④ 已跑過的驗證與預期值（三批的 `check.out`、自測、保留題的量測、步驟 3 的行為不變檢查、`tests/test-install.sh`、LICENSE 引句驗收、去識別掃描）。
被審的是 `a4a5c5c` 加上步驟 3 還沒 commit 的改動。

## 發現

審查者交回的原文（從它的紀錄檔抽出，沒有改字）：

> 【摘要】Critical 0／Important 3／Smells 2
>
> 第 3 批的「通過」我用 jq 獨立重算過，數字和守門結果都對得上 check.out。用更嚴的算法重算（P3 不扣檔名行、標題也算進去），NEW 照樣在 10 行、500 字內，所以通過的理由站得住。問題出在 check.sh 沒量的那幾條規則，加上兩個目前還沒被利用的漏洞。
>
> 【發現】
>
> 1｜Important｜風格檔的「每行 30 字以內」沒有量，第 3 批 NEW 的回覆也沒照做，「這份驗收沒證明的」沒列這一條
> - 證據：
>   - adhd.md「長度」第 1 條原文：「一則回覆最多 10 行，每行一句、30 個字以內。」
>   - check.sh 只量總字數 500（`[ "$c" -le 500 ] || why="$why 字數"`），沒有每行字數的斷言。
>   - 我對 out/batch3 NEW 六發數「非空、非標題且超過 30 字的行」：p1-r1 5/8、p1-r2 5/8、p2-r1 4/5、p2-r2 4/5、p3-r1 8/8、p3-r2 7/7，共 33/41 行超過。最長一行：p2-r1 118 字、p2-r2 144 字。
>   - 10 行 × 30 字推得的上限是 300 字，NEW-p2 兩發是 305 與 341，check 用的是 500 所以照樣綠。
> - 失敗情境：CHANGELOG 把「每行一句 30 個字以內」寫成新規則，同一段又寫「實測…第 3 批通過」。讀者（或之後改風格檔的人）會以為每行字數也驗過了。實際上模型幾乎每行都超過，使用者看到的還是一行塞 100 多字的長句。
> - 建議改法：在 docs/measurements/2026-11-16-adhd-length/CLAUDE.md「這份驗收沒證明的」補一條：每行 30 字沒量，第 3 批 NEW 41 行裡 33 行超過。CHANGELOG 那句加限定。判準不動。
>
> 2｜Important｜規則 2 點名「不寫」的內容，第 3 批 NEW 有 4 發照寫；check.sh 不檢查，CHANGELOG 卻把字數下降歸功於這份清單
> - 證據：
>   - adhd.md 規則 2 的不寫清單有「總覽句（『共 12 項，其中…』）」與「第一句講過的事，後面的清單或各節再講一次」。
>   - NEW-p1-r1 第 1 行：「審查列了 9 項沒處理：2 項 Critical、3 項 Important、4 項 Minor（已讀 review.md:4-16）。」
>   - NEW-p1-r2 第 1 行：「審查列了 9 項：Critical 2、Important 3、Minor 4，都還沒有修復紀錄 …」
>   - NEW-p3-r1 第 1 行「8 項只做完 2 項：`e.txt` 到 `j.txt` 這 6 個檔不存在」，第 8 行又寫「沒做：`e.txt` 到 `j.txt` 共 6 項」。NEW-p3-r2 第 1 行與第 8 行同樣重複。
>   - check.sh 的 guard() 只查開場、收尾客套與各題的必留項。
>   - CHANGELOG 原文：「第三版改成點名不寫哪些內容才降下來」。
> - 失敗情境：字數確實降了，但列出來的禁項沒被遵守。之後有人照「點名就有效」的結論繼續加禁項，實際效果沒有證據撐著。
> - 建議改法：「這份驗收沒證明的」補一條「規則 2 的不寫清單沒有斷言，第 3 批 NEW 有 4 發寫了總覽句或重複第一句」。CHANGELOG 那句改成「第三版改了措辭後字數降下來」，不要歸因到點名清單。
>
> 3｜Important｜selftest.sh 沒有「缺C1」「缺病因」兩種壞例，有違這個目錄 CLAUDE.md 的規則
> - 證據：
>   - 我跑 `grep -c` 數每個守門標籤在兩支檔裡出現幾次：「缺C1」check=1 self=0，「缺病因」check=1 self=0，其他守門標籤 selftest 都有。
>   - 目錄 CLAUDE.md「約束」：「加新的判準就加一個會紅的壞例」。selftest.sh 檔頭寫的是「確認每一種壞法都紅」。
> - 失敗情境：之後的日期目錄照慣例複製這支 check.sh 再改。只要 P2 的 `hasF "$2" 'DEPLOY_ENVIRONMENT'` 被改壞（例如換 fixture 時漏改變數名），NEW 臂回覆漏了病因也會判通過，而 selftest 仍印「全部如預期」。這是最直接驗「病因沒被壓掉」的那一條。現在的 check.sh 我讀過，這兩條是對的，所以不影響第 3 批的判定。
> - 建議改法：補 b_nocause（P2 回覆不含 DEPLOY_ENVIRONMENT）與 b_noC1（P1 回覆不含 C1 也不含 refund）兩例，各自預期紅在對應的標籤。
>
> 4｜Smells｜P3 被扣掉的檔名行，字數也整行不算，P3 實際上限可以到 16 行、約 1100 字
> - 證據：
>   - measure() 先做 `cl=$(… | grep -Ev "$MISSING_RE" …)`，再算 `c=$(( $(nchars "$cl") + $(nchars "$fl") ))`，被扣的行不進字數。被扣的行只受「最多 6 行、每行 100 字」限制。
>   - MISSING_RE `(e|f|g|h|i|j)\.txt` 是子字串比對，`file.txt`、`some.txt` 也會中。
>   - 第 3 批沒被利用：NEW-p3 把扣除行算回去是 r1 8 行 348 字、r2 7 行 307 字，照樣在上限內。
> - 失敗情境：之後某版措辭讓模型在每一行都帶上檔名順便解釋，P3 可以有 10 行加 6 行、500 加 600 字，照樣 L✓。
> - 建議改法：扣除行只免行數、字數照算；或在「長度斷言」的說明裡明寫字數也免。
>
> 5｜Smells｜`#` 開頭的行行數和字數都不算，而且非標題的 `#12` 這類行也會被當成標題
> - 證據：content_lines 用 `/^[[:space:]]*#/ { next }`，nchars 只算 cl 與 fl，標題行的字完全不計。
> - 失敗情境：模型把說明寫成 `### …` 長標題，L 照樣成立。第 3 批 NEW-p3 只有三個短標題（「## 變更」等），結果不受影響。
> - 建議改法：標題只免行數，字數照算；判定式改成 `^#{1,6} `。
>
> 【Not reported】
> - 步驟 3 的改動：measure.sh 的 count_lines、count_chars、result_field 與原本的內聯寫法逐字等價；run.sh 的 REDACT def 代換順序、套用位置與原本相同，沒有改到行為。
> - 前後批可比性：check.sh 從 274ca20（S1-1）之後沒被改過（`git log` 只有那一筆）。P3 prompt 的新句子在第 3 批兩臂都有（batch3/p3.prompt.txt 與 batch1、batch2 的版本已對照）。兩臂 init 的 output_style 各自正確，models 都是同一個 claude-fable-5-2。styles.txt 的 NEW blob 2f82e10 等於 HEAD 與 7ef3f61 的 adhd.md。CHANGELOG 與 CLAUDE.md 的跨批比較只用到沒改過的 P1、P2。
> - OLD-p3-r1 只紅在「扣除行」：就算它算通過，OLD 也只有 1/2 過，P3 照樣有鑑別力，結論不變。
> - 用 Write 寫進 ~/.claude/projects 的記憶檔會污染後面的發：那種工具輸入是絕對路徑，`:"/` 會命中、outside 會大於 0；第 3 批全部是 0。
> - set -e 的 `[ … ] && x=…` 在 && 串列裡不會中止；`grep -c … || true` 已補。bash 3.2 支援陣列與 `"${arr[@]}"`。這幾項讀程式碼就判定沒問題。
> - batch1、batch2 的 check.out 數字與 CLAUDE.md「各批結果」的宣稱逐項對得上。
>
> 【What I ran】
> - Read：prompt-B.txt，review-diff.txt 第 1–1239 行與 2305–2364 行（③ 只讀了 adhd.md 開頭幾行，被改到的檔是用 ① 的 diff 判斷的）
> - `grep -n '^##########\|^diff --git' review-diff.txt` → 各節的起訖行
> - 對 out/batch3 每發用 jq 印出 .result 的全文 → 用來看 NEW 六發與 OLD-p3 兩發的實際回覆
> - 用 jq 對 batch3 每發獨立重算非空行、標題行、內容行、總字數、扣除行與長度、最長行、outside、denials、models、actual → 行數、字數都與 check.out 相同
> - 對 batch3 每發讀 init 的 output_style，並讀 styles.txt 與三批的 p3.prompt.txt → 兩臂風格正確，P3 新句子只在第 3 批
> - `cat batch1/check.out batch2/check.out` 與兩批的 styles.txt → 與 CLAUDE.md 的宣稱相同
> - 用 jq 數 NEW 每發超過 30 字的內容行 → 33/41
> - 用 `grep -c` 數每個守門標籤在 check.sh 與 selftest.sh 出現幾次 → 缺C1、缺病因 在 selftest 是 0
> - `git log --oneline dd6bffa..HEAD -- check.sh run.sh` → check.sh 只有 274ca20 一筆
> - `git rev-parse HEAD:/7ef3f61:/dd6bffa:output-styles/adhd.md`，`git show --stat 92a231b` → blob 對得上
>
> 【需要外部查證】
> - 無。

## 處置

| 發現 | 級別 | 處置 |
|---|---|---|
| B1 每行 30 字沒量、也沒照做 | Important | 採納。自己重算：第 3 批 NEW 41 行內容行裡 33 行超過、最長 144。寫進量測目錄 CLAUDE.md「沒證明的」（連同第 4 批的 32/41、最長 136）與 CHANGELOG。判準不動 |
| B2 點名不寫的內容照樣出現，CHANGELOG 卻歸功給它 | Important | 採納。查證：第 3 批 `NEW-p1-r1`、`NEW-p1-r2` 第一行是總覽句，`NEW-p3` 兩發第一行的事後面又講一次。寫進「沒證明的」；CHANGELOG 的因果句改成「第三版同時改了好幾處，分不出是哪一處有效」 |
| B3 selftest 沒有「缺C1」「缺病因」的壞例 | Important | 採納。查證：兩個標籤在 `selftest.sh` 出現 0 次。補 `b_noC1`、`b_nocause` 兩例，自測變 29 例，最後一行「✅ 自測 29 例全部如預期」 |
| B4 P3 被扣掉的行連字數也不算 | Smell | 採納成已知限制，不改判準（改了前面幾批就不能比）。自己重算：把扣掉的行加回去，第 3 批 NEW 的 P3 是 8 行 348 字、7 行 307 字。寫進「沒證明的」 |
| B5 `#` 開頭的行行數與字數都不算 | Smell | 同 B4，寫進「沒證明的」，不改判準 |

B 的 Not reported 裡「步驟 3 沒有改到行為」與主對話的檢查一致（假的 claude 跑整批，新舊版 19 個輸出檔逐檔相同）。
