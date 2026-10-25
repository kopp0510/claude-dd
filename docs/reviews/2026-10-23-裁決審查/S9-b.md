# S9-b 審查報告

## 派工

subagent_type: code-reviewer（opus，不帶 model），方向：跨檔與內部引用。2026-10-25 15:11 與另兩個同一則訊息平行派出；讀 同 a（scratchpad）。用時 11 分 53 秒、44 次工具。派工 prompt 全文：

> 你是 claude-dd repo（/Users/danlio/project/my_project/claude-dd）S9 段落、8 步迴圈步驟 4 的審查者。你的職責：找漏洞，每條附證據（檔案:行號＋原文，或指令＋輸出），沒證據的不算。
>
> 這段做了什麼（事實）：
> - 精煉全域規則模板 templates/global/CLAUDE.md。它會部署成 ~/.claude/CLAUDE.md，每個 Claude Code session 都會讀進來。61,706 → 55,281 bytes。
> - 使用者的要求：意思不能變；並逐條判「這條規則還需不需要」，拿掉沒影響才刪。作者把可刪的分成「有把握（A 類 19 處）」與「沒驗證（B 類）」，使用者選「只刪 A」。另外套用了計畫附錄 A 的改寫（刪日期、故事細節，修引用；計畫審查通過過）。A 類是計畫審查之後才加的，沒有被審過，所以這一步要特別查它。
> - 起點 316117c，4 個 commit：d75ebbb（§3.9）、58684bd（§3.10）、b0b4889（§2.6、§3.4、§4.1、§4.4、§6.7、§7.2、§7.5 與 CHANGELOG）、4069ec5（README 兩份、scripts/CLAUDE.md、設計文件的巡查結果）；工作目錄另有設計文件一處措辭修正（A13 那列）。
> - 這段只有文件、沒有程式碼；步驟 3（code-simplifier）跳過。
>
> 你是審查者 b，方向「跨檔與內部引用」：
> 1. 模板內部：新版裡每個指代（「上一條」「上面」「下面」「同上」「這條」「那條」「下詳」「§x.y」「「…」那條」）是不是還指到存在而且相符的東西。
> 2. repo 其他檔引用到模板被刪或被改的內容：設計文件 S9 一節「巡查結果」列的每一處逐項核（尤其標「不做」的理由成不成立），再自己 git grep 找它漏掉的地方。
> 3. README.md、README.zh-TW.md、scripts/CLAUDE.md 的改法對不對（對照 scripts/check-claude-md.sh 實際印的訊息、agents/code-reviewer.md 的原文、commands/dd-init.md 蓋章區塊的原文），兩份 README 是否一致。
> 4. 設計文件進度表 S9 列、S7 原因格、S9 一節（A 類表、推翻清單、數字、小任務）是否跟實際一致；CHANGELOG 的 ## 未發布 條目是否跟實際改動一致。
> 不在你的範圍：A 類每一處該不該刪（審查者 a 負責）。
>
> 審查檔：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/s9-final/S9-review-diff.txt（2530 行）。用 Read 的 offset/limit 每次 200 行，從第 1 行讀到最後一行「===== diff 檔結束 =====」（這份檔有些行很長；Read 一次讀太多會靜靜截斷、不報錯）。
>
> 規則：
> - 被改到的檔，一律讀審查檔裡那一份；沒被改到的檔照常讀 repo（唯讀）。
> - 已跑過的驗證輸出在審查檔的 ④（連同預期值）：這些已確認，不要重跑。
> - 只用手上的資料判斷；需要外部查證的（上網、跑安裝、開容器、派別的 agent、跑 claude -p）列出來交回，不要自己去做。
> - 唯讀：不改任何檔、不 commit、不在 repo 裡建檔。
> - 每條發現標嚴重度：Critical（照新版做事會做錯、而且不會被任何檢查擋下）、Important（意思變了或引用錯了，但影響有限）、Smell（措辭、格式）。
>
> 交回格式（照抄標題）：
> 【發現】每條：嚴重度｜位置（新版行號，或 檔:行）｜問題｜證據｜建議改法
> 【Not reported】看過、判定不是問題的（每條一句理由）
> 【What I ran】跑過的指令與讀過的範圍（審查檔讀到第幾行）

## 發現（逐字原文）

Critical 0 / Important 1 / Smell 4。範圍：S9 步驟 4，審查者 b（跨檔與內部引用），316117c..工作目錄。

【發現】

1. Important｜README.md:125、README.zh-TW.md:130｜兩份 README 都還寫「驗證輸出放在 prompt 裡」，新版模板已經不這樣規定。
   - 證據：
     - README.md:125 寫 "the prompt carries the verification output you already ran, with the expected values (the code-reviewer agent's own definition tells it not to re-run that)"；zh-TW:130 寫「prompt 要附上已經跑過的驗證輸出、連同預期值（不要重跑寫在 code-reviewer 的 agent 定義裡）」。
     - 新版模板 :268 只寫「④步驟 1(重跑時加步驟 5)已經跑過的驗證輸出,連同預期值一起寫」，放在 diff 檔裡；整節沒有任何一句要 prompt 帶驗證輸出，或在 prompt 裡標明它已確認（A04 把 base:265–267 整條刪了）。
     - A04 的理由引 agents/code-reviewer.md:21，原文是 "Verification output the caller **pasted in** is already established"。新版的輸出是放在審查者自己去 Read 的檔案裡，算不算 pasted in，原文沒有講。這次派工 prompt 你仍然手寫了「這些已確認，不要重跑」，可見現在實際上還靠這句。
   - 建議：README 兩份改成「驗證輸出連同預期值寫進 diff 檔（第 ④ 部分）」；「不要重跑」的依據二選一：模板 ④ 補半句「派工 prompt 指向 ④、標明已確認」，或在 A04 那列寫明「放在 diff 檔也算 pasted in」是推論。

2. Smell｜新版模板 :240、:297｜被刪的段落帶走了兩個詞的出處，現在讀到時找不到解釋。
   - 證據：
     - 「欠帳」：base 出現兩次，:248 與 :460。:460 是唯一的定義，原文「SKIP 不是豁免:gate 會追查起點以來被跳過、還沒補 CLAUDE.md 的目錄…還有欠帳時…」，被 A13 刪掉。新版只剩 :240「CLAUDE.md 的欠帳只會多審」。
     - 「檔名沿用裁決者時期」（:297）：模板裡講到「裁決者」的段落（base:299–302「為什麼不另派裁決者」）被 A07 刪了。
     - 同族的小問題：:241 的「下詳」拿掉之後，「上一段有沒有附 review 報告」那個檢查要到 :303–304 才以括號帶過，中間沒有指標。
   - 建議：:240 改成「SKIP 欠下、還沒補的 CLAUDE.md 只會多審」；:297 改成「(檔名是歷史沿用,內容是主對話的查證)」；:241 括號補「見下方跳過那條」。

3. Smell｜CHANGELOG.md `## 未發布`（第 23–27 行）｜分類清單有幾處沒涵蓋，有一處跟 gate 實際印的不符。
   - 證據：
     - 沒涵蓋：條目說只刪了列出的幾類，但 A08 對不上任何一類。A08 刪掉的是 gate 的盲點、「不是閉環」、`docs/reviews/CLAUDE.md` 命名慣例的指標（base:336–340），也正是 scripts/CLAUDE.md:116 要跟著改的原因。A01（§2.6 分工導覽句）、A10（分類註記）也沒有對應類別，§2.6 只出現在標題的節名裡。
     - 不符：條目寫「留下 gate 沒寫的：…步驟 6 不可 SKIP」，但 scripts/check-claude-md.sh:318 會印「檢查點 commit（迴圈步驟 2）：SKIP_DOC_CHECK=1 git commit ...（最終 commit 必須全過）」。設計文件 A13 那列也是同一句，而且把「不問使用者」列為 gate 已經印、所以可以刪的項目（check-claude-md.sh:299），但新版模板 :422 照樣保留「不回問使用者」。
   - 建議：CHANGELOG 補一類「gate 盲點與指標（A08）、導覽與分類註記」；「步驟 6 不可 SKIP」改成「gate 也會印，模板保留」；A13 那列的理由欄拿掉「不問使用者」，或註明模板刻意保留。

4. Smell｜設計文件 S9「巡查結果」的「不做，蓋章版副本」那列｜把 `commands/dd-init.md:173`、`:323` 也算進蓋章版副本，但這兩行在蓋章區塊外面。
   - 證據：`grep -n '^```' commands/dd-init.md | head -2` 回 52、149。:173 在 Phase 3（自己判斷舊版 gate），:323 在 Phase 6 的輸出（「逐層往上堆疊更新是 §3.9 的工作流規則」）。「不做」的結論仍成立：:173 跟模板無關，:323 由新版模板 :411 支撐。但「動蓋章區塊要跳 rev」這個理由套不到這兩行，照根 CLAUDE.md 的規矩，區塊外改了不必跳 rev。
   - 建議：把 :173、:323 移到「不做，引用仍成立」，各寫實際理由。

5. Smell｜設計文件「不做，本來就不是原句：`skills/verification-gate/SKILL.md:56`」｜同一種「引號沒照抄原文」的寫法，模板裡的改了，這裡沒改，標準不一致。
   - 證據：verification-gate:56 引「0 紅的第一個嫌疑人永遠是實驗本身」，模板原句（:390）是「「0 紅 / 沒有差異 / 無輸出」的第一個嫌疑人永遠是實驗本身」。附錄 A 把模板裡同類的「0 的第一個嫌疑人…」改成 :502 的「§3.9「…第一個嫌疑人永遠是實驗本身」那條」，這裡卻以「本來就不是原句」為由不改，等於 §3.10 說的「只改一半的統一」。這是既有問題、不在 diff 裡，grep「第一個嫌疑人」照樣找得到，不影響使用。
   - 建議：改成跟 :502 一樣的寫法，或理由欄寫清楚為什麼這處不比照。

【Not reported】
- 模板內部的指標逐條核過，都指得到而且相符：:198「§3.9 鑑別力測試那條」；:253「例外見下」；:260「見下方「報告一律落地」那條」，對到 :292；:264「「範圍要明講」那條」，對到 :254；:412「上一條(…)」，對到 :411；:471「「先 grep 既有的痕跡有沒有更強的」那條在 §3.9」，原文在 :374；:491「上面那條「diff 動到的每一個識別符…」」，原文在 :395；:502「§3.9「…第一個嫌疑人永遠是實驗本身」」，原文在 :390；:539、:586、:593、:602、:787 也都對得上。只有一處措辭不一致：:491 仍寫「上面那條」，同一輪 :502 已改成「§3.9 … 那條」，但不會指錯。
- A13 的依據：gate 的 :299–301、:306–309 會印格式、不建空殼、不問使用者、git add 後重新 commit、逐層檢查上層。兩份 README 改寫的句子跟 gate 原文逐項相符（「與上層模組的關係」也照抄），兩份彼此一致。
- A04、A07 的依據：agents/code-reviewer.md:21、:24 都在，內容跟 A04、A07 那兩列說的相符。只有「pasted in」能不能涵蓋放在檔案裡的輸出，見發現 1。
- A03 的依據：install-dd-pipeline.sh:1315 跑 create_scripts，:1320 才跑 create_global_claude_md，兩個都包在 COMMANDS_ONLY=false 裡。dd-init.md:173 與 UPGRADING.md:79 都還有舊版 gate 的判斷。
- A05：設計文件「開放問題」（:121–123）有同樣的話。A06：gate :225 會印「最少 3 個」。A08：gate 被擋下時會印退出方法（「刪掉 docs/reviews/ 目錄」）。A14：根 CLAUDE.md:155–156 有這個理由。A18：§7.1 第 4 點本身還在。
- scripts/CLAUDE.md:116 新的指標指得到：dd-init.md:97 在蓋章區塊（52–149）裡，寫「只在開下一段時查…不要把它寫成閉環」。
- 蓋章區塊 :61、:76、:84、:87、:97、:105、:131 還留著被刪的字句，「不做」理由（動區塊要跳 rev）成立。但現在蓋章版比全域模板長，下次跳 rev 時要同步。
- 巡查的 ① 指令我自己重跑過，結果跟設計文件列的一致。用被刪字句的關鍵字（Karpathy、Shift+Tab、Overseer、2.3/3、修復格式、不要重跑、閉環、時間花在哪、下詳、上述那次、空殼、佔位等）全 repo grep，沒有找到巡查清單以外的現行規則引用。docs/measurements 裡提到 §3.9 的都是當時的歷史紀錄。
- 兩份 README 開始照抄 gate 的訊息，多了一處要跟著 gate 改的地方。根 CLAUDE.md:254 的手動巡查觸發條件「gate 行為」已經涵蓋「為什麼要巢狀」底下的 gate 對策段落，不算新漏洞。
- 設計文件的數字：61,706 → 55,281（實際各量一次）、少 10.4%、A 類 19 處、B 類 17 處、必留 69 條（④ 已驗）、「必留清單 19 條」（舊清單 88 條、新清單 69 條，比對結果 19 條被拿掉、0 條新增）、計畫第 3 輪小事 18 條（15 條照改、3 條不用改，跟 decision.md 第 7 項一致），都對得上。
- 進度表：S9 起點 316117c 等於 dd-segment-base 檔的內容；--start-segment 能通過，是因為 S8 範圍裡新增了 `docs/reviews/2026-10-23-裁決審查/S8-{a,b,c,judge}.md`（a01d7bb）。S7 原因格補「使用者又要先做 S9」，符合規則。四個 commit 改的檔跟 S9-1 到 S9-4 的小任務描述一致（S9-4 另外改了 CHANGELOG 一行，補「兩份 README 與 scripts/CLAUDE.md 同批改」，沒寫進小任務描述，不影響）。
- 既有問題（不在 diff）：設計文件 S8 段第 90 行「「報告一律落地」那條 grep 得到（:316）」，這次精煉後已經指歪（現在是 :292）。

【What I ran】
- 審查檔 S9-review-diff.txt：每次 200 行讀完第 1–2530 行，讀到最後一行「===== diff 檔結束 =====」
- `git status --short; git log --oneline -5` → 只有設計文件一處未 commit，HEAD 4069ec5
- `git show 316117c:templates/global/CLAUDE.md | wc -c` → 61706；`wc -c templates/global/CLAUDE.md` → 55281
- `grep -n ... scripts/check-claude-md.sh`、`sed -n 200,240p` 與 `285,325p` → 修復格式訊息在 :299–309，「最少 3 個」在 :225，「最終 commit 必須全過」在 :10、:318
- `grep -n '^```' commands/dd-init.md | head -2` → 52、149；`sed -n 52,149p` 讀完整個蓋章區塊；`sed -n 160,180p`、`316,326p` → :173 在 Phase 3、:323 在 Phase 6，都在區塊外
- `grep -n ... agents/code-reviewer.md` → :14、:21、:24
- `git grep` 九節的 § 編號（排除 templates/、CHANGELOG、docs/）→ 結果跟巡查 ① 列的一致
- `git grep` 被刪字句關鍵字兩輪、`git grep` 空殼／佔位／自主修復一輪 → 沒有找到巡查清單以外的現行引用
- `sed` 讀 README.md 136–175、README.zh-TW.md 144–152 與 178–196 → 兩份一致
- `sed` 讀 UPGRADING.md 72–84、docs/reviews/CLAUDE.md 1–30、plan-review SKILL.md 120–128 與 14–20、verification-gate SKILL.md 50–60、tests/CLAUDE.md 9–13、test-gate.sh 300–306 與 413–417、DD_PIPELINE_ARCHITECTURE.md 95–99、check-claude-md.sh 190–195 → 巡查列的「引用仍成立」都成立
- `grep` gen_loop.py 的 ④⑥⑧ 與 cnote → 對新版 §3.9 都還成立
- `grep -n` 新版模板的所有指代詞 → 逐條核過，結果見 Not reported 第一條
- `grep 欠帳|豁免|追查`，新版對 base → 新版只剩 :240；base 有 :248 與 :460
- `git show --stat` 四個 commit 與 `git diff` → 改的檔跟小任務一致；未 commit 的只有 A13 那列的措辭
- `git log efb7931~1..316117c` 加 docs/reviews 的 name-status，再讀 dd-segment-base 檔 → S8 報告四份；起點 316117c
- `grep install-dd-pipeline.sh` → create_scripts 在 :1315、create_global_claude_md 在 :1320，都在 COMMANDS_ONLY=false 底下
- `sed -n 121,126p` 設計文件 → 「開放問題」有 A05 那句
- `wc -l` 與 `diff`（scratchpad 的 s9-tools/must-keep.tsv 對 s9-final/must-keep.tsv）→ 88 對 69，拿掉 19 條、新增 0 條

Not reported：沒有重跑 ④ 的 check.sh 與 ci-steps.sh（你說已確認）。A 類每處該不該刪是審查者 a 的範圍，沒有判。沒有派 agent、沒有跑 claude -p、沒有跑安裝。

## 處置

- 1（Important，README 還寫驗證輸出放在 prompt）：採納。兩份 README 改成「驗證輸出連同預期值寫進 diff 檔，prompt 標明已確認、不要重跑」，跟模板 ④ 補的那句一致
- 2（Smell，「欠帳」「檔名沿用裁決者時期」失去出處、「下詳」）：採納。改成「SKIP 欠下、還沒補的 CLAUDE.md」「(檔名是歷史沿用,…)」，括號補「見下方「報告一律落地」那條」
- 3（Smell，CHANGELOG 分類沒涵蓋 A08/A01/A10、「步驟 6 不可 SKIP」gate 也印）：採納。查證 `scripts/check-claude-md.sh` 擋下訊息末段印「最終 commit 必須全過」、缺檔訊息印「不要問使用者」屬實。CHANGELOG 改成「以及 gate 也會印的不回問、步驟 6 不可 SKIP」並補「gate 盲點的說明、導覽與分類註記」；設計文件 A13 那列同步
- 4（Smell，`dd-init.md:173`、`:323` 在蓋章區塊外）：採納。`grep -n '^```' commands/dd-init.md | head -2` 回 52、149 屬實；巡查結果那列改寫兩行的實際理由
- 5（Smell，`skills/verification-gate/SKILL.md:56` 引號沒照抄）：駁回。既有問題、不在這段 diff；改它要動 skill（走專案「新增 Skill 步驟 3」的乾跑），grep「第一個嫌疑人」照樣找得到。結尾告知使用者
- Not reported 裡的「設計文件 S8 段 :316 已指歪」：不改。那是 S8 當時的紀錄，S8 時 :316 是對的
