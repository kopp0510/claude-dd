# S2-b（審查者 B）— plan-review 流程圖改成分三排

## 派工

```
你是 8 步迴圈步驟 4 的審查者 B。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。

專案根目錄：/Users/danlio/project/my_project/claude-dd
審查範圍：git diff 062a7dd 0271d71（把 plan-review 流程圖改成「一排一個角色」的簡單版：diagrams/src/gen_review.py 重寫文字與版面、兩張 GIF 重出、diagrams/src/CLAUDE.md 與 CHANGELOG 同步、進度表加 S2、根 CLAUDE.md 指路句）。
材料：<scratchpad>/pg2-diff.txt（完整路徑：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/pg2-diff.txt）。
用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔用 git show 0271d71:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。
材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。

背景（事實）：使用者看了上一版說流程怪，選了簡單版草圖：三排（主對話／裁決者／審查者）、7 框、7 條線，重派與無法判定寫在圖下方「例外」小字。結構是使用者決定的，不要建議改結構；但框、線標籤、註解、legend 的字若與 skills/plan-review/SKILL.md 原文意思不符（說寬、說窄、漏條件、中英不一致），照報。

你的方向：產生器程式碼與 diagrams/src/CLAUDE.md 慣例：gen_review.py 有沒有照 gen_planner.py 的形狀與 diagrams/src/CLAUDE.md 的約束（data-role、M/L、defs 外、mask、dur/begin 整除 7.2、負 begin、begin 不是 dur 整數倍、短路徑不放球、legend 與實際線型一一對應、強調色 ≤2）；註解宣稱（例如「dur 與路徑長成正比」的數字、「強調色只給兩個焦點」）是否屬實；有沒有複製時帶進來不適用的東西。

輸出（照抄標題）：
Critical N / Important N / Smells N
## Findings
[級別] 檔:行｜一句話
  證據：…
  失敗情境：…
## Not reported
## What I ran
## 需要外部查證
```

## 發現

Critical 0 / Important 3 / Smells 1 — 審 git diff 062a7dd 0271d71（gen_review.py、diagrams/src/CLAUDE.md、CHANGELOG、設計文件、根 CLAUDE.md）

## Findings

[Important] diagrams/src/gen_review.py:150（另含 diagrams/src/CLAUDE.md「分組標題靠右是因為有連線從容器上緣左半邊進來」那句）｜組名擺放位置的理由寫錯了：真正逼組名離開右上的線在容器右半邊，不在左半邊
  證據：我在 scratchpad 實跑產出的 SVG，量到的跨線點如下。裁決者容器 x 76–1034（中線 555），上緣被 start@225、pass@555、fail@885 穿過；審查者容器 x 76–704（中線 390），上緣被 send@225、back@555 穿過，下緣沒有任何線穿過。主對話容器裡的「再審」線橫跨 225–885，中線是 730，所以也不是「在左半邊」。拿裁決者容器試算：組名放回右上時，en 版文字範圍約 x 614–1010，會壓到 fail 在 x=885 的那條直線。
  失敗情境：下一個人照註解理解成「右半邊沒線，組名放右上安全」，把組名移回去，就會壓到 ④→⑤ 那條線。依 diagrams/src/CLAUDE.md 的說法，文字壓線 verify-geometry 量不到，所以 exit 0 照樣全綠。另外 diagrams/src/CLAUDE.md 那句是 gen_planner 的理由，gen_review 有兩組組名已改放右下，這句沒同步。

[Important] diagrams/src/gen_review.py:12、:32/:56（legend「主流程」）｜註解寫「只畫常走的路」，但圖上畫了 ⑤→⑦「第 3 輪還不過」，而且 legend 把它算進金色實線的「主流程」；SKILL.md 明文把這條算成例外流程
  證據：skills/plan-review/SKILL.md:173「①常走的路：…（「沒跑成」「第 3 輪還不過」這種例外流程不算）」。third 這條邊畫在 gen_review.py:168、:180，用的是 GOLD 實線。
  失敗情境：讀者從 legend 與註解得出「第 3 輪不過」屬於主流程，和 SKILL.md 判重大條件時的用詞衝突。結構是使用者定的，不必動；要改的只是註解和 legend 的措辭（例如不寫「只畫常走的路」）。

[Important] diagrams/src/gen_review.py:25 / :47｜③ 寫「每條批評都附檔案行號」／「every criticism cites file:line」，比原文窄
  證據：SKILL.md:170「每條批評都要附證據：`路徑:行號範圍`…；或 grep 指令與結果」。
  失敗情境：讀圖的人會以為只附 grep 結果的批評不合格。SKILL.md:188–190 的讀檔檢查確實要抽「它引用的路徑:行」，但對單條批評的證據要求比圖上寬。

[Important] diagrams/src/gen_review.py:16（sub），連同刪掉的「什麼時候跑」註解｜「什麼時候跑」被刪後，全圖只剩副標說「複雜任務的計畫交出去之前」，漏掉 design-brainstorm 的設計不論大小都跑，也漏掉 task-planner 草稿
  證據：SKILL.md:18–22（task-planner 步驟 4 要跑；「簡單、中等任務 不跑（但走 design-brainstorm 的設計不論大小都跑）」）。diff 第 77–78 行刪掉了原本列出這兩種情況的 notes[0]。
  失敗情境：讀者以為中小任務走 design-brainstorm 時不用審。這條是刪註解造成的「說窄」，跟結構無關。

## Smells
- possible Mysterious claim：gen_review.py:195「dur 與路徑長成正比」。實際速率是 92px/1.8≈51、148px/2.4≈62、337px/7.2≈47 px/s，並不成比例。gen_planner.py:215 同一句寫「大致與路徑長成正比」，這裡複製時把「大致」拿掉了。改回「大致」即可。「再審約 720px、快約一倍」這句我實算是 720/7.2=100 px/s，屬實。

## Not reported
- 我逐項核過、屬實的：data-role 為 edge/mask/container/node 齊全；只用 M/L；連線畫在 defs 外；dur 1.8/2.4/7.2 都整除 7.2；begin 全是負值，而且都不是 dur 的整數倍；最短的路徑 88px，大於 40px；legend 兩項正好對上 GOLD 實線 6 條與 GOLD_DIM 虛線 1 條；強調色只有 GREEN、AMBER（GRAY 和 planner 一樣是中性色）；ay 標記與 GRAY 對照表刪乾淨，沒有殘留引用；「再審」兩顆球相差 3.6s，等於半週期；:192「放裁決者容器裡會撞到右下的組名」這句 en 版成立（label 569–672 對組名 614–1010）。
- 「再審交給新的裁決者」是推論，材料 ④ 已自己標出，這裡不重報。
- README 兩份的 alt text 只有標題，不受這次結構改動影響。

## What I ran
- `git diff --stat 062a7dd 0271d71` → 7 檔，數字與材料一致
- 讀 pg2-diff.txt 1–538 行（分兩段）、`git show 0271d71:diagrams/src/CLAUDE.md`、`skills/plan-review/SKILL.md` 1–235、`diagrams/src/gen_planner.py` 1–80 與 120–240
- `grep -n 'plan-review.*gif' README*.md`；`git show 0271d71:CHANGELOG.md | grep '^## '` → 條目在「## 未發布」底下
- 在 /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/revB 跑 `git show 0271d71:diagrams/src/gen_review.py` 和 `python3 gen_review.py`，再跑 chk.py（算各邊長度、組名估算框和線的碰撞、各容器上下緣被哪些線穿過）→ 路徑長 92/148/148/92/337/88/720；三個組名都沒碰撞；容器跨線點如第 1 條 Finding 所列

## 需要外部查證
- 無

## 處置

- 1（組名位置理由寫錯）：gen_review.py 註解改成「裁決者、審查者的上緣從左到右都有線穿過（fail 在 x=885、back 在 x=555），組名改放右下」；`diagrams/src/CLAUDE.md` 那句分開寫 gen_planner 與 gen_review 的理由
- 2（「只畫常走的路」與 SKILL.md 的例外流程用詞衝突）：檔頭註解改成「只畫通過、不通過、第 3 輪還不過這三條路」；legend 實線改「往下一步走（交出去、回報、判完之後）」，不再叫「主流程」
- 3（③ 只寫檔案行號）：同 S2-a 第 1 條
- 4（什麼時候跑）：同 S2-a 第 4 條
- Smell（「大致」被拿掉）：補回「大致」
