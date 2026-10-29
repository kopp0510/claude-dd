# S1-c（審查者 C）— 清理兩份 README

## 派工

subagent_type `code-reviewer`（agent 定義 opus），三個同一則訊息平行派出。派工 prompt 原文：

> 你是 8 步迴圈步驟 4 的審查者 C。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。
>
> 專案根目錄：/Users/danlio/project/my_project/claude-dd
> 審查範圍：git diff 15e3446 07a1730（清理兩份 README，加 CHANGELOG 一條、根 CLAUDE.md 一個節名）。
> 材料：<scratchpad>/rd-review-diff.txt。
> 用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔讀材料裡那一份，沒改到的檔讀 repo。
> 材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。
>
> 背景（事實）：使用者原話「README 太多廢話和歷史遺留的，請清理一下」。計畫審過 3 輪才動手。計畫要求：刪歷史敘述、量測過程、重複、只有維護者才需要的實作細節；留讀者要裝、要用、要判斷適不適合自己所需的資訊，以及授權資訊。兩份內容要一致。
>
> 你的方向：同步點：repo 裡還有誰引用或描述 README 被改掉的內容（git grep 被刪段落的特徵字串、錨點、節名；根 CLAUDE.md「CI 不驗、只能手動同步的區塊」那條與「新增 Output Style 步驟」、diagrams/src/CLAUDE.md「與上層的關係」與三支 gen_*.py 的圖上字串、DD_PIPELINE_ARCHITECTURE.md、UPGRADING.md、docs/designs 裡仍有效的決定）；CHANGELOG 那條描述的是否就是實際做的事；根 CLAUDE.md 那個節名改得對不對。
>
> 輸出（照抄標題）：
> Critical N / Important N / Smells N
> ## Findings
> [級別] 檔:行｜一句話
>   證據：…
>   失敗情境：…
> ## Not reported
> ## What I ran
> ## 需要外部查證

## 發現

Critical 0 / Important 1 / Smells 0（審查者 C，範圍 git diff 15e3446 07a1730，方向：同步點）

## Findings
[Important] README.md:55、README.zh-TW.md:56（07a1730 版，材料 diff 第 89／274 行）｜步驟 5 把兩條跳過路徑合成一句，說兩種情況都會印出該跑的 `claude plugin install` 指令，但「plugin 不在磁碟上」那條其實不會印
  證據：install-dd-pipeline.sh:784-787 是 `if [ ! -f "$plugin_json" ]; then echo -e "... Plugin 檔案不存在"; continue; fi`，只印紅字就 continue，不附指令。只有 :826-830 的「讀不到版本」分支會多印一行 `（若尚未安裝過，先跑 claude plugin install ...）`。舊版文字分成兩句寫（材料第 88、273 行），講的是對的。
  失敗情境：claude-md-management 沒在本機的使用者照 README 等指令出現，實際只看到「Plugin 檔案不存在」，而且 README 也沒有寫這個字串讓他對照。
  附註：我讀到工作目錄裡已經有改這兩行、還沒 commit 的修改（`git status` 是 ` M README.md`、` M README.zh-TW.md`），改法是把兩條路徑分開寫。那份修改不在我的範圍，我沒有審。

## Not reported
- docs/designs/2026-10-23-裁決審查-design.md:476（A06）寫「數字留在 README 與量測文件」，:510 寫「2.3/3、1.8/3 與『不另派裁決者』的理由留在 README」。這次 diff 拿掉了 README 那份。量測文件那份這次之前就不存在。數字現在只剩 CHANGELOG.md:498，也就是 README 指向的地方。這份設計文件的段落全部 DONE、根 CLAUDE.md 沒有「進度以…為準」的指路，所以它是歷史紀錄、不是現行決定，不列為 finding。
- 核過沒有問題：根 CLAUDE.md:249 節名；:256-262「CI 不驗」清單與 :144 引用的區塊都還在；:227 的 *(Traditional Chinese)* 標註有帶；內部錨點只剩 #upgrading／#升級且存在；被刪的「Sharing with others／分享給別人」沒有引用；diagrams/src/CLAUDE.md 與 gen_usage.py 字串對得上，gen_loop／gen_planner 沒有引用被刪內容；DD_PIPELINE_ARCHITECTURE.md、UPGRADING.md、docs/designs/2026-10-05 不受影響；scripts/CLAUDE.md:43-45 引用的節還在；CHANGELOG 新條目位置與內容對得上 diff，指標都核過。
- 沒列進 CHANGELOG 的改動（Language note 併入、Highlights 裡 --force 那句、zh 附加步驟「連帶擋掉」那句）屬於「重複／細節」的概括範圍，不構成描述錯誤。

## What I ran
- 材料 1-429、966-974 行；git grep 被刪內容特徵字串（結果在 scratchpad/C-grep1.txt）；git grep README 掃各目錄；sed install-dd-pipeline.sh:775-835；CHANGELOG 標題列；design 文件 1-30、470-478、505-512；git grep 2.3/3；diagrams/src/CLAUDE.md 100-130 與 gen_*.py；兩份 README 標題與錨點；git show 15e3446 標題；git status／git diff

## 需要外部查證
- 沒有

## 處置

- C1 步驟 5：同 A1，採納，處置同 A1
- Not reported 裡的設計文件 A06／S9-4：同意審查者判斷（設計文件段落全部 DONE、根 CLAUDE.md 沒有指路），計畫第 5 點已寫明取代它
