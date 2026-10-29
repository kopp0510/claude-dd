# S1-b（審查者 B）— plan-review 流程圖

## 派工

subagent_type `code-reviewer`（agent 定義 opus），與 code-simplifier 並行派出。派工 prompt 原文：

> 你是程式碼審查者（代號 B）。審查 claude-dd repo（/Users/danlio/project/my_project/claude-dd）一個功能段落的整段變更：讓 plan-review 在兩張流程圖（使用流程、大工作怎麼跑）各有自己的框，重出 4 張 GIF，並更新 diagrams/src/CLAUDE.md 與兩份 README 的圖說。
>
> 材料：<scratchpad>/dg-review-diff.txt。內容：①整段 diff（git diff 1971cf5 HEAD，不含 GIF）③被改到的三個檔的 HEAD 版整檔（附行號）④已跑過的驗證與預期值 —— ④列的已確認，不要重跑。
> **用 Read 的 offset/limit 每次 300 行讀到最後一行**（一次讀太多會被靜靜截斷）。被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。
>
> 你的方向：產生器程式碼的正確性 —— 座標、連線（從哪個框到哪個框、箭頭方向、會不會穿過別的框或文字）、小球 dur/begin 是否符合 diagrams/src/CLAUDE.md 的規則（整除 7.2、負值、不是 dur 整數倍、短於 40px 不放球）、legend 與實際連線一一對應、舊的識別符（p65、p71、Y7、ask）有沒有殘留或被別處引用、註解是否描述現況。
>
> 職責：找漏洞，每條附證據（路徑:行號 + 原文，或指令與輸出）；沒證據的不算。只用手上的資料與讀檔/grep 判斷，需要外部查證的列出來交回。不要改任何檔、不要 commit。
>
> 輸出格式：
> Critical N / Important N / Smells N
> ## Findings
> [級別] 路徑:行｜一句話
>   證據：…
>   失敗情境：…
> ## Not reported（看過但判定不報的，各一句理由）
> ## What I ran（讀過的檔、跑過的指令）
> ## 需要外部查證

## 發現

Critical 0 / Important 3 / Smells 0 — 審查範圍是 git diff 1971cf5 HEAD（gen_usage.py、gen_planner.py、diagrams/src/CLAUDE.md、兩份 README）。

我要負責的幾何與動畫部分全部沒問題：座標、箭頭方向、連線有沒有穿過框或文字、dur/begin、legend 都對得上。三條發現都是圖上文字或連線，跟來源 skill 的語意不一致。

## Findings

[Important] diagrams/src/gen_planner.py:181、187（"one" 連線）與 :18、:43（loop 節點）｜「1 段」分支從 ◇ 直接接到「照一般 8 步迴圈」，跳過了新加的 plan-review 框。但來源規定 1 段的複雜任務也要先過 plan-review。
  證據：skills/task-planner/SKILL.md:54 原文「只切出 1 段就不往下走：…照一般的 8 步迴圈做（它仍是全域 §4.1 的複雜任務，計畫先交 `plan-review`；…）」。全域 §4.1 原文「N = 1 的複雜任務直接把計畫交 `plan-review`」。圖上 review 框只在 `many → draft → write` 這條路上，loop 節點的字是「一圈做得完，不用拆」／"fits in one loop, no split"。
  失敗情境：改版前 plan-review 只寫在 plan 框的副標裡。現在它獨立成一框、只掛在 ≥2 段那條分支，讀者看 GIF 會推論「1 段就不用審計畫」，跟 task-planner 與 §4.1 相反。usage 圖的 ⑤ 寫的是「複雜工作」，兩張圖在同一件事上講法也不一樣。

[Important] diagrams/src/gen_planner.py:20（ZH review 節點）｜「通過才寫檔，只問你決策題」的「只」不對，plan-review 結束時問的不只決策題。
  證據：skills/task-planner/SKILL.md:72 的標題是「送 plan-review，問決策題與測試清單」。:79 原文是「用 AskUserQuestion 問兩種題，跟它交回的『需使用者決定』一起問」。README.zh-TW.md 同一段也寫「只問你決策題、要加哪些測試、以及審查判定只有你能決定的題目」。EN 版 :45 沒寫「只問」這句，所以中英兩版說法也不同。
  失敗情境：讀繁中 GIF 的人以為審完只會被問決策題，被問到測試清單時會覺得流程跟圖不符。圖說和它正上方的 README 段落也互相矛盾。

[Important] diagrams/src/CLAUDE.md:115-117（「與上層的關係」）｜這次兩張圖都畫進了 plan-review 的內容，但「來源清單」沒有加上 `skills/plan-review/SKILL.md`。
  證據：新字串引用了 plan-review 的性質：gen_planner.py:20/:45「裁決者派 ≥3 個審查者猛攻」，gen_usage.py:28/:66「裁決者派 ≥3 個審查者猛攻、逐條查證」。這些都出自 skills/plan-review/SKILL.md:3（「派一個裁決者（Opus），由它平行派至少 3 個審查者」）。CLAUDE.md:116-117 列的來源只有 DD_PIPELINE_ARCHITECTURE.md、README、templates/global/CLAUDE.md、task-planner/SKILL.md，並註明「CI 不驗圖片內容，只能靠人記得」。
  失敗情境：日後 plan-review 改掉裁決者或 ≥3 下限（README 已經記載 code-review 那邊拿掉了裁決者），改的人照這份清單不會知道要重出 4 張 GIF，圖上的宣稱就靜靜地過期。附帶一點：兩支產生器的 foot（gen_usage.py:48/:89）仍寫「依 README 安裝章節、dd-init 實際 Phase 與 task-planner 繪製」，也沒有提到 plan-review。

## Not reported
- 舊識別符：p65、p71、Y7、ask、交代工作、Hand over the work 用 git grep 掃過，只剩 CLAUDE.md:50、:58 與 gen_planner.py:71 的歷史敘述。Y7 這個名字留著，但現在指的就是 ⑦ gate，註解相符。
- usage 的連線都核過。p67 是 (798,702)→(798,770)，長 68px、方向向下進 ⑦。p76 是 ⑦ 右緣 968→x1000→y663→980，停在 ⑥ 右緣 +12，不碰 p56、也不碰 x=1080 的註解，在容器 x≤1040 內。p81 走 x=140，在容器左緣 180 之外。
- planner 的連線都核過。one、draft、write 各 68px，many、start 各 88px，next 323px，起訖點都是框邊或菱形頂點，終點留 12px 給箭頭。「2 段以上」的遮罩在 y320–337，夾在 G0 下緣 310 與 G1 上緣 346 之間。G1 標題靠右 1340、基線 372，在 resume 框上緣 386 之上。
- dur 全部整除 7.2，begin 全部是負值，而且都不是該球 dur 的整數倍（p67 −0.9/3.6、p76 −1.8/3.6、draft −0.5/1.44 等）。沒有短於 40px 的路徑放了球。
- legend：usage 的金、玫瑰虛線、薄荷，planner 的金、GOLD_DIM 虛線、薄荷，跟實際的連線色與虛線一一對應。
- 文字寬度用 verify-geometry 同一套估法算過，改過的副標與註解最寬到 1340，畫布寬 1440。
- 速度不一致：p76 長 210px 但 dur 3.6，比同圖其他線快。改版前的 p65 長 584px、dur 也是 3.6，問題本來就在，不是這次引入的。
- verify-geometry 的 LIMITS 有 notes=2，而 usage 有 4 則註解。這是既有狀況，④ 的輸出也沒有把它列成失敗項。
- usage 圖沒有畫「簡單中等任務跳過 ⑤」的連線，只寫在註解第 1 行。這是設計選擇，文字已經說明，不報。

## What I ran
- Read 完整 diff 檔（1–937 行，分 3 次讀）→ 讀完
- `git grep -n -E 'p65|p71|\bY7\b|交代工作|Hand over the work|"ask"'` 等三組 → 只剩歷史敘述
- `sed -n 118,138p README.md`、`sed -n 122,143p README.zh-TW.md` → 圖說段落
- `grep -n` skills/tech-diagram-gif/scripts/verify-geometry.py → `LIMITS = dict(nodes=9, edges=12, containers=4, notes=2`
- `grep -n` skills/plan-review/SKILL.md、skills/task-planner/SKILL.md → :3、:54、:72、:79 的原文如上
- python3 用 CJK 1em、其餘 0.55em 估改動字串的右端 → 最大 1340.15

## 需要外部查證
- 第 1 條要不要改，取決於作者的意圖：planner 圖是不是刻意只畫「≥2 段」那條路。如果要改，在 loop 節點副標補一句「計畫仍先過 plan-review」即可，不必加框。這要由主對話或使用者決定。

## 處置

- B1 1 段那條路跳過 plan-review：同 A3，採納，處置同 A3（審查者把它列在「需要外部查證」問要不要改：§4.1 與 task-planner 都寫明 1 段也要審，不需要問使用者）
- B2「只問」不對：同 A1，採納，處置同 A1
- B3 來源清單沒有 plan-review：採納（Important）。`diagrams/src/CLAUDE.md`「與上層的關係」加 `skills/plan-review/SKILL.md`；兩支產生器的 foot 也補上 plan-review
