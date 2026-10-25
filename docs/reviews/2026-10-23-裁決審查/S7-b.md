# S7-b 審查報告

## 派工

subagent_type: code-reviewer（opus，不帶 model），方向：跨檔一致。2026-10-25 與另兩個同一則訊息平行派出；讀 scratchpad 的 `s7/S7-review-diff.txt`（810 行）。用時 6 分 20 秒、11 次工具。派工 prompt 全文：

> 你是 claude-dd repo（/Users/danlio/project/my_project/claude-dd）S7 段落、8 步迴圈步驟 4 的審查者。你的職責：找漏洞，每條附證據（檔案:行號＋原文，或指令＋輸出），沒證據的不算。
>
> 這段做了什麼（事實）：
> - plan-review skill（計畫審查：裁決者派審查者攻擊計畫、查證後回報，最多 3 輪）原本第 3 輪還不通過時只准「把剩下的重大缺失列給使用者」。S7 改成：第 3 輪不通過時重大與小事都先改進計畫，回報每條重大寫明改了沒；再讓使用者選「跑一次只審第 3 輪改法的確認輪（輪次 3C）／照改好的計畫繼續／停下」。task-planner、design-brainstorm 兩個會呼叫 plan-review 的 skill 同步改。
> - 兩個 commit：6962874（主要改動）、efb7931（乾跑抓到 9 處後修正）。這三份 SKILL.md 已部署、也已隨 v1.6.7 發布，所以這次審查若要改，要另寫 CHANGELOG 未發布。
> - 只有 SKILL.md 文字，沒有程式碼；步驟 3（code-simplifier）跳過。
>
> 審查檔：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/s7/S7-review-diff.txt（810 行）。用 Read 的 offset/limit 每次 200 行，從第 1 行讀到最後一行「===== diff 檔結束 =====」（Read 一次讀太多會靜靜截斷、不報錯）。
>
> 你是審查者 b，方向「跨檔一致」：task-planner/SKILL.md、design-brainstorm/SKILL.md 對同一條路徑（第 3 輪不通過、確認輪、照改好的計畫繼續、未經審查的標記、什麼時候問決策題與測試清單題、什麼時候送 ExitPlanMode）寫的是否跟 plan-review 一致；兩份 README、DD_PIPELINE_ARCHITECTURE.md、根 CLAUDE.md、templates/global/CLAUDE.md、commands/dd-init.md 有沒有還在講舊行為（「最多 3 輪、剩下的列給使用者」之類）而沒跟著改（自己 git grep）；CHANGELOG 1.6.7 的 S7 條目、設計文件 S7 一節是否跟實際改動一致。
>
> 規則：
> - 被改到的三份 SKILL.md，一律讀審查檔 ③ 那一份；其他檔照常讀 repo（唯讀）。
> - 審查檔 ④ 是已跑過的驗證（連同預期值）：這些已確認，不要重跑。
> - 只用手上的資料判斷；需要外部查證的（上網、跑安裝、派別的 agent、跑 claude -p、在別的專案實跑）列出來交回，不要自己去做。
> - 唯讀：不改任何檔、不 commit、不在 repo 裡建檔。
> - 每條發現標嚴重度：Critical（照新版做事會做錯、而且不會被任何檢查擋下）、Important（照新版會卡住、要用猜的、或兩處互相矛盾，但影響有限）、Smell（措辭、格式）。
>
> 交回格式（照抄標題）：
> 【發現】每條：嚴重度｜位置（檔:行）｜問題｜證據｜建議改法
> 【Not reported】看過、判定不是問題的（每條一句理由）
> 【What I ran】跑過的指令與讀過的範圍（審查檔讀到第幾行）
> 【需要外部查證】每條：要查什麼｜為什麼

## 發現（逐字原文）

Critical 0 / Important 4 / Smell 3。範圍是 S7（6962874、efb7931）：三份 SKILL.md 讀審查檔 ③ 那一份，另外看了 CHANGELOG 1.6.7、設計文件 S7 一節，以及 README、DD_PIPELINE_ARCHITECTURE.md、根 CLAUDE.md、templates/global/CLAUDE.md、commands/dd-init.md 有沒有沒跟著改的舊說法。

【發現】
1. Important｜task-planner/SKILL.md:91–92、design-brainstorm/SKILL.md:14–15（審查檔 ③）｜確認輪沒跑成時，兩個呼叫端會在設計文件寫錯紀錄，而第 3 輪的改法也沒有任何地方標「未經審查」。路徑：plan-review:77 寫確認輪「沒跑成 → 走第 5 步」，這是 S7 新開的分支；第 5 步（:101–102）只給「重跑／不審直接交」兩個選項。使用者選「不審直接交」後，task-planner:92 在假設寫「這份段落草稿沒經過 plan-review（使用者選不審直接交）」，design-brainstorm:15 寫「沒經過 plan-review」。可是草稿其實已經過三輪，第 3 輪採納的重大改法沒人審過，這條路上卻沒有一句要記下來。兩個呼叫端都沒區分「第 1 輪就沒跑成」和「確認輪沒跑成」。plan-review 自己也只在 :71「照改好的計畫繼續」那條要求「標明哪些改法未經審查」，第 5 步沒有。設計文件的假設與開放問題沒有任何檢查會看，S7 原本要解決的「使用者看不出改了沒、有沒有人審過」在這條路上又冒出來｜證據：③ plan-review:77「沒跑成 → 走第 5 步，重跑仍算同一次確認輪」；:102「再問要重跑還是不審直接交」；task-planner:92「並在設計文件的假設寫明「這份段落草稿沒經過 plan-review（使用者選不審直接交）」」；design-brainstorm:15「…採納的重大缺失與改法（未經審查）或「沒經過 plan-review」」｜建議改法：plan-review 第 5 步補一句：確認輪選「不審直接交」時，照 :71 標明第 3 輪的改法未經審查。兩個呼叫端的「沒跑成」那條各補：確認輪沒跑成時寫「第 3 輪採納的重大與改法（未經審查；確認輪沒跑成）」，不寫「沒經過 plan-review」。

2. Important｜plan-review/SKILL.md:29（③）｜乾跑 P1 只修了一半。④-3 的預期值寫「列出的每處在 efb7931 都改了」，實際沒全改。:75 自己寫明「審查範圍」那一欄審查者看不到；:128 規定貼給審查者的只有兩組標記之間的內容；:142 叫審查者以「計畫或事實開頭」寫的範圍為準。但第 1 步的「審查範圍」那一項（:29）仍只說「只審一段時寫明其他段落是背景」，沒要求把範圍句也寫進計畫或事實開頭。結果是第 1–3 輪「只審一段」時，範圍照樣到不了審查者，審查者會全面攻擊，把背景段落沒做的事算成缺失。P1 列了三處建議改法，第三處（「:29 只審一段時也要求把範圍句寫進事實開頭」）沒改｜證據：③ plan-review:29「**審查範圍**：…只審一段時寫明「其他段落是背景，不在範圍內」」；:111「審查範圍：{範圍}」在 `<<<計畫開始>>>` 標記之外；:128「《計畫與事實》貼上面兩組標記之間的內容（連標記一起）」；④-3 P1 第三點原文「:29「只審一段時」也要求把範圍句寫進事實開頭」｜建議改法：:29 補「範圍句同時寫進事實開頭（審查者看不到這一欄）」，跟 :75 用同一套說法。

3. Important｜plan-review/SKILL.md:69、:75（③）｜乾跑 P6 只在 task-planner 那邊解掉，直接呼叫 plan-review 的路上沒有對應說法。:69 把還沒問的「需使用者決定」和「接下來怎麼做」放在同一批問，:95 又規定「會改到計畫的題」排在前面。所以使用者可能先答了一題會改到計畫的「需使用者決定」，接著選確認輪。這時 :75 的範圍句只列「第 3 輪採納的這幾條」，因答案改的部分落在範圍外，依 :190「範圍外的採納…一律標小事、不計入結論的 N」。結果是使用者答案帶出的改法被結構性地排除在確認輪擋得到的範圍外，主對話只能猜要不要把它列進範圍句。task-planner 靠「決策題延到選定後才問」（:87）避開了，plan-review 本身沒有。P6 原文就寫了「plan-review :67–76 對『第 3 輪停下時使用者答案改到計畫』也沒有說法」｜證據：③ plan-review:69「所有還沒問的「需使用者決定」一起問，再問接下來怎麼做」；:75「只審第 3 輪採納的這幾條〈逐條列出，重大與小事都列〉」；:190｜建議改法：:75 的範圍句改成「第 3 輪採納的這幾條，加上因第 3 輪停下時使用者答案而改的地方」。

4. Important｜docs/designs/2026-10-23-裁決審查-design.md 進度表 S7 列（HEAD 與工作目錄的驗收欄文字相同）｜S7 的驗收條件還沒達成，而這段已經進到步驟 4。驗收欄寫「三份改到的分支乾跑無卡住或矛盾（task-planner 寫檔那條在拋棄式 repo 實跑）」，但 ④-3 自己寫「修完之後沒有再乾跑一次」，④ 裡也沒有任何拋棄式 repo 實跑 task-planner 寫檔那條的紀錄。efb7931 改了不少：task-planner 決策題與測試清單題延後才問、審查者範本、裁決者分類規則、第 4 步先改小事，這些都是乾跑之後才加的，修完後的分支沒有任何乾跑證據。另外 ④-4 真跑確認輪的結論是「不通過（1 條重大）」，所以「確認輪不通過 → 照改好的稿繼續／停下」之後那段路也沒驗過｜證據：審查檔 ④-3 原文「efb7931 全部修掉。修完之後沒有再乾跑一次」；設計文件進度表 S7 驗收欄原文如上｜建議改法：標 DONE 之前補一次修完後的乾跑（三份分支），加上 task-planner 寫檔那條在拋棄式 repo 實跑；不補的話，在 S7 一節寫明驗收沒做完、理由是什麼。

5. Smell｜CHANGELOG.md 1.6.7 的 S7 條目（③ :33–34）、設計文件 S7-1（③ :440）｜發布說明比實際改動窄。efb7931 有三件改動影響的不只確認輪，CHANGELOG 都沒寫：①第 4 步第 1 項「先照採納（小事）改計畫（不再送審）」，每一次通過都適用；②審查者範本改認「計畫或事實開頭」的範圍句，每一輪都適用；③task-planner 第 3 輪那條路上，決策題與測試清單題從「同時問」改成選定後才問。「對應選項同步」讀不出③是時機改變。設計文件 S7-1 也只描述 6962874 的範圍，沒提乾跑抓到的 9 處和 efb7931｜證據：efb7931 的 commit 訊息「審查者範本改認「計畫或事實開頭」的範圍句；…通過時先改小事；…task-planner 決策題與測試清單題延到選定後才問」；③ CHANGELOG :33–34 全文｜建議改法：在 CHANGELOG `## 未發布` 補一條（1.6.7 已發布，不能改），設計文件 S7 一節補一行 efb7931 與乾跑結果。

6. Smell｜plan-review/SKILL.md:96（③）｜分批順序裡「呼叫端寫明要等『接下來怎麼做』選完才問的題」，例子只舉了「沒跑成」那條路上的決策題。task-planner:87 現在第 3 輪那條路也把決策題延後了。task-planner 的決策題照它自己的定義（:81）就是「會改到計畫的題」，照 :95 字面應該排在「接下來怎麼做」前面，要靠讀到這條例外才知道延後。例子沒跟上，讀者容易照 :95 先問｜證據：③ plan-review:96「（例如 task-planner 在「沒跑成」那條路上的決策題）」；task-planner:87「（決策題與測試清單題還不問，草稿可能還會變）」｜建議改法：例子改成「task-planner 在第 3 輪不通過與沒跑成兩條路上的決策題」。

7. Smell｜design-brainstorm/SKILL.md:14（③）｜同一個選項三份檔叫法不同：plan-review 叫「照改好的計畫繼續」（:70、:71、:77、:95、:216），design-brainstorm:14 叫「照改好的稿繼續」，task-planner 叫「照改好的稿寫進設計文件」。task-planner 自訂選項是有意的（它原本就是「照現稿寫進設計文件」）；design-brainstorm 沒有自訂選項，實際問使用者的會是 plan-review 的字面，但 :14 用另一個字面去比對｜證據：如上各行｜建議改法：design-brainstorm:14 改成「照改好的計畫繼續」。

【Not reported】
- README.md:127、README.zh-TW.md:132、templates/global/CLAUDE.md:538：「只問決策題、測試、需使用者決定」這類措辭沒提第 3 輪不通過時要問「接下來怎麼做」。這是 S2 就有的措辭（舊版也要問「照現稿／停下」），S7 沒改變它對不對。
- DD_PIPELINE_ARCHITECTURE.md、根 CLAUDE.md、commands/dd-init.md：git grep 不到 plan-review 輪數或第 3 輪處理方式的敘述，沒有沒跟著改的舊說法。
- 設計文件 :82「再審（最多 3 輪）」與技術設計流程圖：「最多 3 輪自動」仍成立；:62 已補「S7 起…確認輪」。:182–185、:171 的「照現稿」是 S2 的歷史紀錄。
- plan-review:77 確認輪不通過時要不要先照 1–3 改計畫：「照上面的回報方式」只准對被擋住的那幾條寫「沒改」，可以推得出要改；task-planner:89 也寫「確認輪採納的…改法」。不算要用猜的。
- task-planner:88「通過就照上一條『通過』走」：「上一條」指 :86 的「通過」條，指對了。
- task-planner:94 與 plan-review:83「已經是第 3 輪（含確認輪）就不再送」兩處一致；design-brainstorm:23、:80 也一致。
- design-brainstorm 第 8 步：已經離開 plan mode 時第 3 輪不通過，「未經審查」要寫去哪沒寫（:15 說第 6 步，第 6 步已經跑過）；還有 design-brainstorm 沒寫使用者選「停下」之後怎麼辦。這兩個縫舊版就有，S7 只換了措辭。
- ④-4 真跑結論「不通過（1 條重大）」來自範圍內一條小事的外部查證被標成重大。:190 只把範圍外的降為小事，範圍內照三個條件判，跟規則一致。

【What I ran】
- 審查檔 /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/s7/S7-review-diff.txt，Read 1–200、200–399、400–599、600–810 → 讀到第 810 行「===== diff 檔結束 =====」
- `git grep -n -E '最多 3 輪|3 輪|第 3 輪|三輪|確認輪|3C|照現稿|剩下的重大|…round 3' -- ':!CHANGELOG.md' ':!docs/reviews'` → 命中只在三份 SKILL.md、設計文件、量測文件（三輪計畫審查的歷史敘述），以及 gate-guard 測試裡不相干的「第 3 輪」
- `git grep -n -i -E 'plan-review|plan review|計畫審查' -- README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md CLAUDE.md templates/global/CLAUDE.md commands/dd-init.md UPGRADING.md` → 13 處，都沒寫輪數或第 3 輪處理方式
- `sed -n 127p README.md`、`sed -n 132p README.zh-TW.md`、`sed -n 520,542p templates/global/CLAUDE.md` → 見 Not reported 第 1 條
- `sed -n 78,86p DD_PIPELINE_ARCHITECTURE.md` → 只有元件清單
- `git show --stat efb7931 6962874` → 兩個 commit 的訊息與檔案清單
- `sed -n 1,30p` 與 `sed -n 55,100p` docs/designs/2026-10-23-裁決審查-design.md → 進度表、技術設計表 :62、流程圖 :82
- `git diff --stat` 與 `git diff | grep '^[-+]| S7'` → 工作目錄只改了 S7 那列的狀態欄（BLOCKED 改 IN_PROGRESS），驗收欄文字與 HEAD 相同

【需要外部查證】
- 修完後的乾跑：照 efb7931 版三份 SKILL.md 走一次確認輪各分支，特別是發現 1（確認輪沒跑成後選不審直接交）和發現 3（第 3 輪停下時使用者答案改到計畫、又選確認輪）｜④-3 寫明修完後沒有再乾跑，這兩條路的實際走法只有乾跑看得出主對話怎麼猜
- task-planner 寫檔那條在拋棄式 repo 實跑（第 3 輪或確認輪不通過 → 照改好的稿寫進設計文件 → 步驟 5 的假設內容）｜這是進度表 S7 驗收欄列的項目，④ 裡沒有紀錄
- 設計文件 :435「lawdesk-ai 一份計畫第 1–3 輪重大 3、1、1 條」｜素材在別的專案，我沒去讀

## 處置

- 1（Important，確認輪沒跑成時呼叫端寫錯紀錄）：採納，同 a-2
- 2（Important，`:29` 範圍句）：採納，同 a-4
- 3（Important，使用者答案改的地方在範圍外）：採納，同 a-3
- 4（Important，驗收的修完後乾跑與沙盒實跑沒做）：採納。步驟 5 補做：派一個只讀乾跑走七條路徑、派一個在 scratchpad 拋棄式 repo 實跑 task-planner「確認輪沒跑成 → 照改好的稿寫進設計文件」的步驟 5，結果見 `S7-judge.md`
- 5（Smell，CHANGELOG 比實際窄、設計文件 S7-1 沒提 efb7931）：採納。CHANGELOG `## 未發布` 加 Fixed 一條，含 1.6.7 沒寫到的三件；設計文件 S7 一節補 efb7931 與這次審查
- 6（Smell，分批例子沒跟上）：採納。例子改成「task-planner 在第 3 輪不通過與沒跑成兩條路上的決策題」
- 7（Smell，design-brainstorm「照改好的稿繼續」字面不同）：採納。改成「照改好的計畫繼續」
- Not reported 裡的 design-brainstorm 第 8 步「未經審查寫去哪」「停下之後怎麼辦」：S7 之前就有，不在這段，不改
