# S1-c（審查者 C）— plan-review 流程圖

## 派工

subagent_type `code-reviewer`（agent 定義 opus），與 code-simplifier 並行派出。派工 prompt 原文：

> 你是程式碼審查者（代號 C）。審查 claude-dd repo（/Users/danlio/project/my_project/claude-dd）一個功能段落的整段變更：讓 plan-review 在兩張流程圖（使用流程、大工作怎麼跑）各有自己的框，重出 4 張 GIF，並更新 diagrams/src/CLAUDE.md 與兩份 README 的圖說。
>
> 材料：<scratchpad>/dg-review-diff.txt。內容：①整段 diff（git diff 1971cf5 HEAD，不含 GIF）③被改到的三個檔的 HEAD 版整檔（附行號）④已跑過的驗證與預期值 —— ④列的已確認，不要重跑。
> **用 Read 的 offset/limit 每次 300 行讀到最後一行**（一次讀太多會被靜靜截斷）。被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。
>
> 你的方向：文件與同步點 —— diagrams/src/CLAUDE.md 的每句宣稱在 HEAD 還成立嗎（框號、失敗項清單、節點上限、「分組標題靠右」的理由）；repo 裡還有誰描述這兩張圖的內容（git grep 框號、「交代工作」、圖說、DD_PIPELINE_ARCHITECTURE.md、CHANGELOG `## 未發布`、docs/designs 裡引用這些圖的段落）而沒跟著改；兩份 README 的圖說是否一致；根 CLAUDE.md 有沒有規定改圖要同批改的地方。
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

Critical 0 / Important 3 / Smells 0 — 審查範圍：1971cf5..HEAD（801a317），讀的是 dg-review-diff.txt 裡的 ①③④；未改動的檔讀 repo

## Findings

[Important] CHANGELOG.md:19｜`## 未發布` 沒有這次重出 4 張 GIF、加 plan-review 框的條目
  證據：`sed -n 19,31p CHANGELOG.md` 只有 ADHD 風格那一條；`git show --stat 801a317` 沒有 CHANGELOG。前兩次只重出圖的改動都有記：CHANGELOG.md:104「「大工作怎麼跑」中英兩張 GIF 重出（副標改成「plan-review 審過才寫檔」）」、:116「「8 步開發迴圈」中英兩張 GIF 重出（④ 改成…）」。上一輪設計文件把 CHANGELOG 列為改圖要同批改的檔（docs/designs/2026-10-23-裁決審查-design.md:206「`CHANGELOG.md`（寫進 `## 未發布`）」）。
  失敗情境：下一版發布時，README 嵌的兩張圖從版面到內容都變了（使用流程從 7 框變 8 框、大工作圖拿掉「交代工作」），版本紀錄卻一字不提。

[Important] diagrams/src/CLAUDE.md:115-117（另見 gen_usage.py:48、gen_planner.py:34 的 foot）｜來源清單沒有 plan-review，可是兩張圖現在都把它的機制畫成獨立一框
  證據：CLAUDE.md:116-117 的來源只列「`DD_PIPELINE_ARCHITECTURE.md`、`README`、`templates/global/CLAUDE.md`（§3.9…§4.1…）與 `skills/task-planner/SKILL.md`；那些內容改了，這裡的字串要跟著改」。新框的字是 gen_usage.py:28「裁決者派 ≥3 個審查者猛攻、逐條查證」和 gen_planner.py:20「裁決者派 ≥3 個審查者猛攻」，出處是 skills/plan-review/SKILL.md:3「派一個裁決者（Opus），由它平行派至少 3 個審查者」。兩支 foot 也只寫「依 README 安裝章節、dd-init 實際 Phase 與 task-planner 繪製」和「依全域 CLAUDE.md §4.1、§3.9 與 task-planner 繪製」。
  失敗情境：之後有人改 plan-review（例如拿掉裁決者，就像 rev 11 對步驟 4 做過的那樣），照這份清單不會想到要重出圖。CI 不驗圖片內容（:117 自己寫了），圖就會一直過期。

[Important] diagrams/src/gen_usage.py:19/56 搭配 :95/:199｜⑤ plan-review 放在「STEP 3 · 日常開發（每個功能段落）」容器裡，讀起來像每一段都要過一次 plan-review
  證據：GRP[2]=(180,588,860,294)，⑤ 在 (COL_L, ROWS[2]=624)，落在第三個容器裡；容器標題是 ZH「STEP 3 · 日常開發（每個功能段落）」、EN「STEP 3 · Daily development (every increment)」。實際上兩段以上的工作只審一次整份草稿，之後才寫進度表、逐段做：gen_planner.py:73 的 review 排在 table 之前，不在「每一段」那組（GROUPS[2]）裡。README.md:135 的圖說也把兩者分開寫：「put the plan for complex work through `plan-review`, then every feature increment runs the same loop」。
  失敗情境：看使用流程圖的人以為 S1、S2、S3 每段開工前都要跑一次 plan-review，這跟同一份 README 上面那張大工作圖互相矛盾。

## Not reported
- CLAUDE.md:12、:14、:50、:58 的框號、失敗項、節點上限 9、「交代工作」移除：跟 HEAD 版程式碼和 verify-geometry.py:26 `LIMITS = dict(nodes=9, …)` 一致。
- CLAUDE.md:59 和 gen_planner.py:170「分組標題靠右」的理由仍成立：many 在 x=225 從上緣進第二組（76..1364，左半），start 在 x=885 進第三組（736..1364，左半）。第一組上緣沒有線進來，但這句講的是整體理由，沒有說錯。
- 兩份 README 的圖說語意一致（README.md:135 對 README.zh-TW.md:140）；根 CLAUDE.md:43「6 張 GIF（使用流程、8 步迴圈、大工作怎麼跑 × 中英）」仍成立。DD_PIPELINE_ARCHITECTURE.md 沒有描述圖的內容。
- gen_planner.py:20「通過才寫檔，只問你決策題」比 task-planner/SKILL.md:79-88 簡化（另有測試清單題；第 3 輪沒過，使用者也可以選照改好的稿寫檔）。舊字串「plan-review 審過才寫檔」就是同樣的簡化，屬圖內縮寫，不算這次引入。
- 註解「簡單、中等任務跳過 ⑤」沒提 design-brainstorm 的設計也會過 plan-review（plan-review/SKILL.md:3「design-brainstorm 的設計除外」），屬圖內簡化。
- git grep 抓到的 motion-build-to-operate.svg、sample-flow.svg 裡的 ⑥⑦ 是另一張圖的編號，跟這次無關。docs/designs、docs/reviews 裡提到 gen_planner 的段落是歷史紀錄，不需要跟著改。
- CLAUDE.md:97「上層有 11 張」：`ls diagrams/*.gif | wc -l` → 11，仍成立。

## What I ran
- Read dg-review-diff.txt 1–937（分 3 段讀到底）
- `git log --oneline 1971cf5..HEAD; git diff --stat 1971cf5 HEAD` → 只有 801a317，9 個檔
- `git grep -n -E 'usage-flow|task-planner\.gif|…|交代工作|Hand over the work|gen_usage|gen_planner'` → 只有 README 嵌圖、CLAUDE.md、CHANGELOG 舊條目、docs 歷史
- `grep -n … verify-geometry.py` → :26 `LIMITS = dict(nodes=9, …)`
- `sed -n 118,140p README.md`、`sed -n 128,145p README.zh-TW.md` → 圖說和上下文
- `sed -n 19,31p CHANGELOG.md`、`sed -n 95,118p CHANGELOG.md`、`grep -n 'GIF|gen_…' CHANGELOG.md` → 未發布區塊沒有圖的條目；:104、:116 是前例
- `for c in $(git log -8 -- diagrams/)…grep -c CHANGELOG` → 801a317 是 0
- `grep -n … DD_PIPELINE_ARCHITECTURE.md`、`grep -n … CLAUDE.md`（根）→ 沒有要同步的圖內容描述
- `grep -n … skills/plan-review/SKILL.md`、`skills/task-planner/SKILL.md` → 核對框內文字的出處
- `git grep -n -E '框 ?[⑤⑥⑦]|…|p65|p71|Y7'` → 沒有殘留的舊框號引用
- `ls diagrams/*.gif | wc -l` → 11

## 需要外部查證
- 第 3 條要不要改，要看渲染後的 GIF：⑤ 是否在視覺上明顯落在 STEP 3 框內（開 diagrams/claude-dd-usage-flow*.gif 看第 0 幀）。也請作者決定 ⑤ 是該移出容器，還是改容器標題。

## 處置

- C1 CHANGELOG 沒有條目：採納（Important）。讀 `CHANGELOG.md` 的 `## 未發布` 確實只有 ADHD 那條；補一條
- C2 來源清單：同 B3，採納，處置同 B3
- C3 ⑤ 放在「每個功能段落」容器裡：採納（Important）。看渲染圖 ⑤ 確實在 STEP 3 框內。改容器標題為「STEP 3 · 日常開發（計畫審一次，每個功能段落走迴圈）／Daily development (plan reviewed once, every increment loops)」，不移框（移出容器會新增「容器外節點」失敗項）
