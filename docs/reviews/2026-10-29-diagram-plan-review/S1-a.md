# S1-a（審查者 A）— plan-review 流程圖

## 派工

subagent_type `code-reviewer`（agent 定義 opus），與 code-simplifier 並行派出。派工 prompt 原文：

> 你是程式碼審查者（代號 A）。審查 claude-dd repo（/Users/danlio/project/my_project/claude-dd）一個功能段落的整段變更：讓 plan-review 在兩張流程圖（使用流程、大工作怎麼跑）各有自己的框，重出 4 張 GIF，並更新 diagrams/src/CLAUDE.md 與兩份 README 的圖說。
>
> 材料：<scratchpad>/dg-review-diff.txt。內容：①整段 diff（git diff 1971cf5 HEAD，不含 GIF）③被改到的三個檔的 HEAD 版整檔（附行號）④已跑過的驗證與預期值 —— ④列的已確認，不要重跑。
> **用 Read 的 offset/limit 每次 300 行讀到最後一行**（一次讀太多會被靜靜截斷）。被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。
>
> 你的方向：圖上文字宣稱的正確性 —— 每一句（框名、說明、註解、副標、分組標題）對照全域 ~/.claude/CLAUDE.md §4.1、skills/plan-review/SKILL.md、skills/task-planner/SKILL.md，有沒有說錯流程（誰叫 plan-review、什麼任務跳過、審過之後做什麼、「只問你決策題」對不對）；中英兩版語意是否一致。
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

Critical 0 / Important 4 / Smells 0（審查範圍：git diff 1971cf5 HEAD 的 gen_usage.py、gen_planner.py、diagrams/src/CLAUDE.md 與兩份 README 圖說；只看圖上文字宣稱的正確性與中英一致）

## Findings

[Important] diagrams/src/gen_planner.py:20（ZH review 節點）｜「通過才寫檔，只問你決策題」把使用者會被問到的題目縮成只有決策題
  證據：skills/task-planner/SKILL.md:79-81 寫 plan-review 結束時要問「兩種題」：決策題，以及測試清單題（選項「照這份清單加／要修改」），再加上 plan-review 交回的「需使用者決定」。同一段 README.zh-TW.md 的散文（task-planner 那段）寫的是「只問你決策題、要加哪些測試、以及審查判定只有你能決定的題目」，README.md 也一樣寫 "only the decision questions, which tests to add, and anything the review says only you can decide"。
  失敗情境：讀圖的人以為只會被問決策題，被問到測試清單題或「需使用者決定」時，會覺得流程走偏了。圖也跟緊鄰的 README 散文互相矛盾。

[Important] diagrams/src/gen_planner.py:45 對照 :20（EN 和 ZH 的 review 節點）｜兩版語意不一致：EN 少了 ZH 的「只問你…題」那半句
  證據：ZH `review=("plan-review 審草稿", ["裁決者派 ≥3 個審查者猛攻", "通過才寫檔，只問你決策題"])`；EN `review=("plan-review checks it", ["adjudicator sends 3+ reviewers", "written only after it passes"])`。gen_usage.py 的 ⑤ 也有同樣問題：ZH 第 27 行「計畫先交審查，通過才動手」，EN 第 65 行 "the plan is reviewed before any code"，EN 少了「通過才」這個條件。
  失敗情境：中英讀者對「審完之後問什麼」「沒通過能不能動手」拿到不同的說法。這兩個框是這次新增的，修第一條的時候要兩版一起改。

[Important] diagrams/src/gen_planner.py:18（loop 節點）搭配 :14 副標｜這次只在「2 段以上」那條分支標了 plan-review，「1 段」分支直接進 8 步迴圈，讀起來像 N=1 的複雜任務不用審
  證據：templates/global/CLAUDE.md:528（§4.1 複雜任務流程是「計畫 + 假設 → `plan-review` 通過 → 動手」），skills/task-planner/SKILL.md:54「只切出 1 段…照一般的 8 步迴圈做（它仍是全域 §4.1 的複雜任務，計畫先交 `plan-review`…）」，skills/plan-review/SKILL.md:18「全域 §4.1 的複雜任務（N = 1；…）…跑」。圖上 ◇ 本身就是「複雜任務先估段落數」，所以走 1 段分支的都是複雜任務。新副標寫「兩段以上交給 task-planner、草稿先過 plan-review」，loop 框寫「一圈做得完，不用拆」，兩邊都沒提 N=1 也要審。
  失敗情境：改版前兩條分支都沒有 plan-review，這次只把它加到 N≥2 分支。讀圖的人會推論「只有 1 段就跳過 plan-review」，跟 §4.1 相反。

[Important] diagrams/src/gen_usage.py:39（ZH note 3 第 1 行）／:79（EN）｜「簡單、中等任務跳過 ⑤，直接進 ⑥」漏了 design-brainstorm 的例外
  證據：skills/plan-review/SKILL.md:22「簡單、中等任務｜不跑（但走 `design-brainstorm` 的設計不論大小都跑）」，同檔第 3 行 description 也寫「design-brainstorm 的設計除外」。
  失敗情境：中等任務如果先走了 design-brainstorm，照圖會跳過 ⑤；照 skill 要跑。圖給的是無條件的規則，但它有例外。

## Not reported
- gen_usage.py:27 的 ⑤ 放在「STEP 3 · 日常開發（每個功能段落）」容器裡，可能讓人以為每一段都要重跑 plan-review（N≥2 時其實只審一次草稿）。容器標題是既有的，N=1 時一個任務剛好就是一段，判定是版面歸組，不算錯誤宣稱。
- 「通過才寫檔」「通過才動手」用了排他的「才」，但第 3 輪不通過或沒跑成時，使用者可以選「照改好的稿寫進設計文件」或「不審直接交」（task-planner/SKILL.md 第 4 步那三種結束方式的說明；plan-review/SKILL.md:68-74、:119）。planner 那句是從舊版的「plan-review 審過才寫檔」搬過來的；以流程圖主路徑的簡化來說可以接受，不單獨報。
- 「裁決者派 ≥3 個審查者猛攻、逐條查證」和 EN 的 "adjudicator sends 3+ reviewers, then verifies" 都對得上 plan-review/SKILL.md:9-10 與 description。
- 拿掉「交代工作」節點後，圖改從 ◇ 開始，沒有宣稱錯誤；diagrams/src/CLAUDE.md:58 對這件事的描述和程式碼一致。
- diagrams/src/CLAUDE.md:12、:14、:50 對框號、⑦ 位置、p65 被重排掉的描述，和 HEAD 程式碼（gen_usage.py:27-34、:186-189、:199-200）一致。
- 兩份 README 的新圖說（README.md:136、README.zh-TW.md:141）和 §4.1 一致，中英語意一致。
- git grep 掃過框號（⑤⑥⑦）、「交代工作」、"Hand over the work"，repo 裡沒有其他過期引用（motion-build-to-operate.svg 和 sample-flow.svg 的 ⑥⑦ 是另一張圖自己的編號）。
- 幾何檢查、GIF、getBBox 這些是派工 prompt 標明已確認的項目，沒有重跑。

## What I ran
- Read scratchpad/dg-review-diff.txt 第 1–938 行（分 4 次讀到最後一行）
- `grep -n '' skills/plan-review/SKILL.md | head -120` → 讀了「什麼時候跑」表與第 1–5 步
- `sed -n '1,110p' skills/task-planner/SKILL.md` → 讀了步驟 2 的 N=1 條、步驟 4、步驟 5
- `diff templates/global/CLAUDE.md ~/.claude/CLAUDE.md` → 兩份相同；`grep -n -A12 '### 4.1' templates/global/CLAUDE.md` → 第 522-534 行
- `git grep` 框號、舊節點名、GIF 檔名 → 結果見 Not reported
- `sed -n 120,130p README.md`、`sed -n 126,135p README.zh-TW.md` → task-planner 段散文與圖說

## 需要外部查證
- 無。（渲染後的 GIF 我沒看，只審了產生器字串；如果字串和 GIF 對不上，要看截圖才知道。）

## 處置

- A1「只問你決策題」：採納（Important）。讀 `skills/task-planner/SKILL.md:79`「問兩種題，跟它交回的『需使用者決定』一起問」屬實。ZH 改成只寫「通過才寫檔」，不再列舉會問哪些題
- A2 中英語意不一致：採納（Important）。planner 的 review 框兩版都只寫「通過才寫檔／written only after it passes」；usage ⑤ 的 EN 改成 "work starts only after the plan passes"，跟 ZH「通過才動手」對齊
- A3 1 段那條路看起來不用審：採納（Important）。讀 `skills/task-planner/SKILL.md:54`「它仍是全域 §4.1 的複雜任務，計畫先交 `plan-review`」屬實。loop 框加第二行「計畫仍先過 plan-review／the plan still goes to plan-review」
- A4 漏了 design-brainstorm 例外：採納（Important）。讀 `skills/plan-review/SKILL.md:22` 屬實。usage 註解第一行改成「簡單、中等任務跳過 ⑤（design-brainstorm 的設計例外）」
