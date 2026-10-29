# S2-a（審查者 A）— plan-review 流程圖改成分三排

## 派工

```
你是 8 步迴圈步驟 4 的審查者 A。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。

專案根目錄：/Users/danlio/project/my_project/claude-dd
審查範圍：git diff 062a7dd 0271d71（把 plan-review 流程圖改成「一排一個角色」的簡單版：diagrams/src/gen_review.py 重寫文字與版面、兩張 GIF 重出、diagrams/src/CLAUDE.md 與 CHANGELOG 同步、進度表加 S2、根 CLAUDE.md 指路句）。
材料：<scratchpad>/pg2-diff.txt（完整路徑：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/pg2-diff.txt）。
用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔用 git show 0271d71:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。
材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。

背景（事實）：使用者看了上一版說流程怪，選了簡單版草圖：三排（主對話／裁決者／審查者）、7 框、7 條線，重派與無法判定寫在圖下方「例外」小字。結構是使用者決定的，不要建議改結構；但框、線標籤、註解、legend 的字若與 skills/plan-review/SKILL.md 原文意思不符（說寬、說窄、漏條件、中英不一致），照報。

你的方向：圖上文字 ↔ skills/plan-review/SKILL.md 原文：gen_review.py 的 ZH 與 EN 兩個 dict 每一句（標題、副標、組名、框、邊標籤、註解、legend、foot）逐句對原文，看有沒有說錯、說得比原文寬或窄、中英意思不一致。④ 有現成對照表可用，但要自己讀原文那幾行確認。

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

Critical 0 / Important 4 / Smells 0 — 審查範圍是 git diff 062a7dd 0271d71。我把 gen_review.py 的 ZH 與 EN 兩個 dict 逐句對了 skills/plan-review/SKILL.md 原文。

## Findings

[Important] diagrams/src/gen_review.py:25 與 :47（③ attack 框）｜「每條批評都附檔案行號」「every criticism cites file:line」比原文說得窄。
  證據：SKILL.md:170 原文是「每條批評都要附證據：`路徑:行號範圍`…；或 grep 指令與結果」。行號只是兩種證據之一。另外 SKILL.md:190 的讀檔檢查要求的是「每個審查者至少引用一處檔案行」，不是每一條批評都要有行號。同一張圖的回報邊標籤（:27 `back="附證據回報"`、:50 `"report with proof"`）用的是「證據」，跟原文一致，所以 ③ 框和這個標籤彼此也講不一樣。
  失敗情境：讀者照圖寫審查者 prompt 或判讀報告時，會把「只附 grep 指令與結果」的批評當成不合格。原文明確允許這種寫法。

[Important] diagrams/src/gen_review.py:20 與 :42（⑥ ok 框）｜這次 diff 刪掉了舊版的「你的規則要批准時照樣問」，現在「通過 → 開工」讀起來是無條件開工。
  證據：diff 第 64 行舊版是 `ok=("通過 → 開工", [..., "你的規則要批准時照樣問"])`，EN 舊版是 `"approval only if your rules ask"`。新版兩語都只剩「先改小事、問你要決定的題」。原文 SKILL.md:100：「使用者的 CLAUDE.md、或呼叫本 skill 的那個 skill 仍寫著要使用者批准時，照那邊問」。SKILL.md:92 還有一條：使用者選了非建議答案、而且會改到計畫，而還沒到第 3 輪時，要回第 1 步再送一輪，不是開工。例外小字（:30–31、:53–55）兩條都沒寫。
  失敗情境：使用者自己的規則要求批准時，看圖的人會以為通過後直接開工，跳過那道批准。這正是原文 §③「跳過使用者的決定」那一類。

[Important] diagrams/src/gen_review.py:30–31 與 :53–55（「例外」註解）｜「沒跑成」只列了一個原因（補派後湊不到 3 個有效審查者）。例外小字的標題給人「完整列舉」的印象，但原文有五種原因。
  證據：SKILL.md:117：「裁決者回錯誤、報告缺「結論」或自相矛盾、結論是 `無法判定`、或使用者說不等了」，SKILL.md:58 也有同樣的規定。補充：舊版是用邊標籤「補派後仍不足 3 個」接到「無法判定／沒跑成」框，S1 就只畫了這一種原因。這次改寫成「例外」清單，條列的形式讓遺漏更像是在說「只有這幾種」。
  失敗情境：裁決者回錯誤、或報告裡寫 `通過` 但「採納（重大）」不是空的。看圖的人在例外清單裡找不到對應的路，可能當成通過往下走。SKILL.md:120 與 :235 明文禁止這樣做。

[Important] diagrams/src/gen_review.py:16（ZH sub）、:38（EN sub）｜S1 的「什麼時候跑」註解被刪掉了，現在觸發條件只剩副標的「複雜任務的計畫交出去之前」，比原文窄。
  證據：diff 第 77–78 行刪掉的註解原本寫了「task-planner 的草稿出好之後」「design-brainstorm 的設計（不論大小）」「簡單、中等任務不跑」。原文 SKILL.md:18–22 的表格裡，design-brainstorm 的設計「不論大小都跑」，不限複雜任務。
  失敗情境：讀者看這張圖會以為中等規模的 design-brainstorm 設計不用跑 plan-review。（如果使用者選的草圖本來就沒有這則註解，這條請駁回，改成只看副標：副標沒寫「只有」，嚴格說不算錯。）

## Not reported
- 「什麼算重大」註解：這次 diff 只是搬了位置，文字沒動，而且已對過 SKILL.md:172–175，意思相符。
- ⑤ 沒寫「小事順手改」「重大的外部查證主對話自己查」；例外小字沒寫「確認輪沒跑成時不給不審直接交」（SKILL.md:86）。這幾條我判為簡化圖可以接受的省略，沒報。
- 「再審：新的裁決者」是推論，不是原文字面。依據是 SKILL.md:66 加上第 2 步每輪都用 Agent 派裁決者，加上 SKILL.md:9，推論成立，不報。不過 diagrams/src/CLAUDE.md 新的那列把它寫成事實，沒標推論，這點附帶提一下。
- 其餘各句對過原文，相符：組名、①、②、④、⑦、邊標籤（通過／不通過／第 3 輪還不過／附證據回報）、legend、foot、中英對照。

## What I ran
- Read pg2-rev-prompt-A.txt → 拿到派工
- Read pg2-diff.txt 1–300、300–538 → 讀完全部 538 行
- cat -n skills/plan-review/SKILL.md（1–150、150–235）→ 讀完全部 235 行

## 需要外部查證
- 使用者確認的「簡單版」草圖有沒有「什麼時候跑」註解、⑥ 框有沒有寫批准例外。這會決定第 2、4 條要不要駁回：如果草圖是使用者刻意這樣簡化的，那兩條算使用者決定。

## 處置

- 1（③ 只寫檔案行號）：改「每條批評都附證據（檔案行號或 grep 結果）」，EN 同步
- 2（⑥ 看起來無條件開工）：「例外」小字補「你的規則寫了要你批准：通過之後照樣先問你」
- 3（沒跑成只列一種原因）：「例外」小字改成列出裁決者回錯誤、報告缺結論或自相矛盾、補派後湊不到 3 個、你說不等了
- 4（什麼時候跑）：副標改成「複雜任務的計畫、task-planner 草稿、design-brainstorm 的設計（不論大小）交出去之前」
- 需要外部查證（草圖有沒有這些）：主對話查了對話紀錄，草圖的框字只有短句，沒有刻意刪掉批准例外或觸發條件，所以照改，不算使用者決定
