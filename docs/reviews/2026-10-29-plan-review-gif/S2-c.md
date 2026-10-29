# S2-c（審查者 C）— plan-review 流程圖改成分三排

## 派工

```
你是 8 步迴圈步驟 4 的審查者 C。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。

專案根目錄：/Users/danlio/project/my_project/claude-dd
審查範圍：git diff 062a7dd 0271d71（把 plan-review 流程圖改成「一排一個角色」的簡單版：diagrams/src/gen_review.py 重寫文字與版面、兩張 GIF 重出、diagrams/src/CLAUDE.md 與 CHANGELOG 同步、進度表加 S2、根 CLAUDE.md 指路句）。
材料：<scratchpad>/pg2-diff.txt（完整路徑：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/pg2-diff.txt）。
用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔用 git show 0271d71:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。
材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。

背景（事實）：使用者看了上一版說流程怪，選了簡單版草圖：三排（主對話／裁決者／審查者）、7 框、7 條線，重派與無法判定寫在圖下方「例外」小字。結構是使用者決定的，不要建議改結構；但框、線標籤、註解、legend 的字若與 skills/plan-review/SKILL.md 原文意思不符（說寬、說窄、漏條件、中英不一致），照報。

你的方向：同步點與文件：repo 裡誰還寫著舊的 GIF 清單或產生器數量（git grep）；diagrams/src/CLAUDE.md 改寫後的句子是否正確、表格結構有沒有壞；根 CLAUDE.md 的指路句與進度表（docs/designs/2026-10-29-plan-review-gif-design.md）是否照 skills/task-planner/SKILL.md「進度表格式」與全域 §4.4；README 嵌入位置與 alt 中英是否一致；CHANGELOG 條目是否描述了實際做的事。

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

Critical 0 / Important 3 / Smells 0（審 git diff 062a7dd 0271d71，方向：同步點與文件）

## Findings

[Important] docs/designs/2026-10-29-plan-review-gif-design.md:5｜開頭的「使用者決定」還寫著 S1 的結構與框字，跟 S2 的圖對不上，本次 diff 沒改這一行
  證據：:5 寫「使用者決定：圖的結構（8 框、9 條線、3 組）；框 ① 寫「推測要標明」；「無法判定」從讀檔檢查拉出。」；0271d71 的 gen_review.py:19 ① 是「附查到的事實，交給裁決者」（沒有「推測要標明」），讀檔檢查框和無法判定的線都拿掉了；同一份文件 :42 寫 7 框、7 條線
  失敗情境：下一個 session 照表接手，或之後有人改這張圖，讀到 :5 會把「① 沒寫推測要標明」「無法判定沒從讀檔檢查拉出」當成違反使用者決定，然後改回去。另外有兩種可能分不出來：使用者在 S2 真的放棄了「推測要標明」，或是重寫時把它弄丟了（見「需要外部查證」）

[Important] diagrams/src/gen_review.py:30-31、:53-55（連同 diagrams/src/CLAUDE.md:15、CHANGELOG.md:24）｜「例外」只寫了「審查者不足 → 沒跑成」這一條，SKILL.md 第 5 步其他幾條沒跑成的路，圖上完全沒有
  證據：SKILL.md:117「裁決者回錯誤、報告缺「結論」或自相矛盾、結論是 `無法判定`、或使用者說不等了」都算沒跑成；SKILL.md:58 也寫了報告缺結論或自相矛盾時當成沒跑成。舊版 none 框（「無法判定／沒跑成」）涵蓋得到這些；新版的例外只有「補派後還湊不到 3 個有效審查者：審查沒跑成」。④ 寫「判通不通過」，看起來只有兩種結果，但 SKILL.md:50-56 的結論有三種值
  失敗情境：看圖的人以為只有審查者湊不滿才會「沒跑成」。裁決者回錯誤、報告缺結論的時候，圖上沒有任何路可以對照。brief 說的「說窄、漏條件」就是這種；結構不用動，例外那行的字寫寬一點就好

[Important] diagrams/src/gen_review.py:25、:47｜③「每條批評都附檔案行號」／"every criticism cites file:line" 比原文窄
  證據：SKILL.md:170「每條批評都要附證據：`路徑:行號範圍`…；或 grep 指令與結果」。原文接受 grep 結果當證據，圖上只寫檔案行號。CHANGELOG.md:24 和 diagrams/src/CLAUDE.md:15 都宣稱「框裡每句話都對過 SKILL.md 原文」
  失敗情境：讀者以為附 grep 結果的批評不算數。「對過原文」這句宣稱在這一框不成立

## Not reported
- diagrams/src/CLAUDE.md:116（本次 diff 沒動到，是既有問題）寫「第 1–5 步任何一句改了都要回頭對」，但 gen_review.py:13 寫明它的來源還包括「裁決者範本」。③ 的「互相看不到對方」（SKILL.md:147）和例外裡的「重派最多一次／補派」（SKILL.md:192-195）都出自範本。本次 diff 讓圖更依賴範本，範本改了的時候，照 :116 的指示不會回頭對圖
- 「再審：新的裁決者」是推論，不在 SKILL.md 字面上（材料 ④ 已自己標明）。它只出現在邊標籤和 legend，不在框裡，不算違反「框裡每句話」的宣稱；我讀 SKILL.md:39-41、:66 後認為這個推論站得住
- 已核過、沒有問題：
  - 根 CLAUDE.md 的指路句和 task-planner SKILL.md:108-109 逐字相同，放在第一個 `##` 之前，前後都有空行。S1 標 DONE 時刪掉、S2 開工時再加回，符合 :136
  - 進度表 S2 列：格式、狀態、commits 欄填 `062a7dd..` 都符合 :133；「段落與小任務」也補上了 S2-1
  - diagrams/src/CLAUDE.md:15 那列以 `|` 開頭，表格沒有被截斷
  - README 嵌入：README.md:109 和 README.zh-TW.md:112 各自嵌對語言版，alt 和兩版 title 一致；本次 diff 沒動 README
  - CHANGELOG 只改 `## 未發布` 的條目，沒碰已發布的區塊（最新 tag 是 v1.6.11）
  - repo 裡沒有其他地方還寫著舊結構（8 框、9 條線、讀檔檢查）；GIF 清單（CLAUDE.md:38、diagrams/src/CLAUDE.md:104-105）不受影響

## What I ran
- `wc -l pg2-diff.txt` → 538 行；`git diff --stat 062a7dd 0271d71` → 7 個檔
- Read pg2-diff.txt 1-300、300-538 → 讀完整份
- `cat -n skills/plan-review/SKILL.md | sed -n 1,200p` → 對照框、標籤、註解的原文
- `git grep -n -E 'plan-review\.(zh-TW\.)?gif|gen_review|review-(zh-TW|en)\.svg' 0271d71` → 只在 README 兩份、diagrams/src/CLAUDE.md、設計文件、docs/reviews 出現
- `git grep` 產生器數量（四支、三支、產生器…）→ 沒有寫死的數量和這次改動有關
- `git show 0271d71:diagrams/src/CLAUDE.md | cat -n` → 讀全檔
- `grep -n` task-planner SKILL.md 的指路與進度表規則，加上 `git show 0271d71:docs/designs/2026-10-29-plan-review-gif-design.md | cat -n` → 找到 :5 過期的那一行
- `git show 0271d71:README.md | sed -n 95,120p`、README.zh-TW.md 100-116、CHANGELOG.md 1-32、`git tag -l 'v*'` → 嵌入位置、alt、未發布區塊、最新 tag v1.6.11
- `git grep -n -E '8 框|9 條|連線 9|推測要標明|從讀檔檢查|…'` → 過期的只有設計文件 :5

## 需要外部查證
- 使用者在 S2 選的簡單版草圖裡，① 有沒有保留「推測要標明是推測」：查主對話裡使用者確認草圖那則訊息。這一點決定 Finding 1 要怎麼修：是把設計文件 :5 改成 S2 的決定，還是把「推測要標明」加回 ①

## 處置

- 1（設計文件 :5 還是 S1 的決定）：改寫成 S1 與 S2 各自的決定；框 ① 的「推測要標明」是 S1 使用者決定、S2 草圖沒說要拿掉，加回框 ①
- 2（沒跑成只列一種原因）：同 S2-a 第 3 條
- 3（③ 只寫檔案行號）：同 S2-a 第 1 條
- Not reported 第 1 項（`diagrams/src/CLAUDE.md` 只寫第 1–5 步）：採納，改成「第 1–5 步與裁決者範本」
- Not reported 第 2 項（新的裁決者是推論）：`diagrams/src/CLAUDE.md` 那列標明「SKILL.md 沒寫『新的』，是推的」
