# S1-a（審查者 A）— plan-review 流程圖

## 派工

```
你是 8 步迴圈步驟 4 的審查者 A。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。

專案根目錄：/Users/danlio/project/my_project/claude-dd
審查範圍：git diff f46b73b 6a2bdd3（新增 plan-review 流程圖：產生器 diagrams/src/gen_review.py、兩張 GIF、README 嵌入、diagrams/src/CLAUDE.md 與根 CLAUDE.md 同步、CHANGELOG、進度表）。
材料：<scratchpad>/pg-review-diff.txt（完整路徑：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/pg-review-diff.txt）。
用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔用 git show 6a2bdd3:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。
材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。

背景（事實）：使用者要一張專門畫 plan-review 怎麼運作的圖。圖的結構（8 框、9 條線、3 組）、框 ① 寫「推測要標明」、「無法判定」從讀檔檢查拉出，都是使用者決定的，不要建議改結構；但框裡的字若與 SKILL.md 原文意思不符，照報。計畫審過 2 輪。

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

Critical 0 / Important 4 / Smells 0

範圍：`git diff f46b73b 6a2bdd3`。只查一個方向：`gen_review.py`（6a2bdd3 版）的 ZH／EN 兩個 dict，逐句對 `skills/plan-review/SKILL.md`。這段範圍內 SKILL.md 沒有改過，所以我讀的是 repo 版。

## Findings
[Important] diagrams/src/gen_review.py:27、:50｜邊標籤「有效審查者不足 3 個」／"under 3 valid reviewers" 比原文寬：原文要先補派，補完還不足 3 個才是「無法判定」，圖上把補派省掉了
  證據：SKILL.md:194-195「有效審查者少於 3 個：補派新代號補到 3 個（補派只做一次…）；補完還是少於 3 個，結論寫 `無法判定（有效審查者不足 3 個）`」。圖的結構（從讀檔檢查拉出這條線）是使用者決定的，不在這條裡；問題只在標籤的字。
  失敗情境：README 讀者以為只要有一個審查者沒過讀檔檢查、有效人數掉到 2，審查就直接判「無法判定」。實際流程會先補派。CHANGELOG 和程式第 12 行的註解都寫「每一句都對過原文」，這句其實對不上。改法可以是「補派後仍不足 3 個」／"still under 3 after backfill"。

[Important] diagrams/src/gen_review.py:30、:53-54｜註解「什麼算重大」比原文窄：漏了第 ① 條的例外，也漏了第 ② 條的一個分支
  證據：SKILL.md:173「①常走的路…；金額、權限、刪資料不管多少見都算」；:174「②照做會壞、會錯，或會跳過使用者的決定」。圖上只寫「常走的路、照做會錯、後面的關卡也抓不到」，EN 同樣。
  失敗情境：讀者照圖判斷「很少走的刪資料路徑」或「照做會跳過使用者決定」都不算重大。原文這兩種都算。這正是 f46b73b 剛加進 §3.10 的那條「縮短既有文字時，條件最容易被改掉」。

[Important] diagrams/src/gen_review.py:20、:43（以及 legend :32、:56）｜讀檔檢查框寫「每人抽一處」／"one cited line per reviewer"，把原文的「至少」拿掉了；「對不上就重派」也漏了「最多重派一次」
  證據：SKILL.md:189「每個審查者**至少**抽一處它引用的 `路徑:行`」；:192「每個代號的位置**最多重派一次**（回錯誤或沒過讀檔檢查都算這一次）…重派還是不行，它不算有效審查者」。另外 legend「重派：讀檔檢查沒過的審查者」也比原文窄，原文回錯誤一樣會重派。
  失敗情境：讀者以為裁決者每人只抽一行。圖上那條虛線迴圈沒有寫上限，看起來可以一直重派下去。實際規則是至少抽一處，重派最多一次，之後就不算有效審查者。

[Important] diagrams/src/gen_review.py:22、:45｜通過框寫「不再問『計畫可以嗎』」／EN 用 "never"，說成絕對，原文其實有例外
  證據：SKILL.md:100「⚠️ 使用者的 CLAUDE.md、或呼叫本 skill 的那個 skill 仍寫著要使用者批准時，照那邊問」；:234 表格也寫「（使用者自己的規則要求批准時例外，見第 4 步）」；:97 在 plan mode 裡仍要使用者按一次 ExitPlanMode。
  失敗情境：使用者在自己的 CLAUDE.md 寫了「要我批准」，照圖會以為 plan-review 會把這條蓋掉。原文明說不蓋掉。EN 的 "never" 比 ZH 的「不再」更絕對，中英語氣也不一致。

## Not reported
- 副標「複雜工作的計畫交出去之前」／"before a complex plan goes out" 比「什麼時候跑」註解窄：design-brainstorm 的設計不論大小都跑。下面的註解已經補上這點，所以我沒列成 finding。
- EN 的 "adopt / reject / ask the user"：原文是「需使用者決定」，由主對話之後去問，不是裁決者自己問使用者。語感稍有偏差，意思大致對得上。
- 「什麼時候跑」沒列「使用者說『審計畫』」這個觸發；這份註解沒宣稱自己是完整清單。
- 「無法判定／沒跑成」框沒提原文 :118 的兩件事：要先問還沒問的「需使用者決定」；確認輪沒跑成時不給「不審直接交」這個選項。這是例外路徑，摘要省略可以接受。
- 結構類的意見（框數、線數、組別）照派工指示不提。
- 其餘句子逐條對過，意思相符：標題、組名、①②④⑥⑦ 框、「已是第 3 輪」、「再送一輪（最多 3 輪）」、foot。

## What I ran
- Read scratchpad/pg-rev-prompt-A.txt → 派工內容
- `git show 6a2bdd3:diagrams/src/gen_review.py | cat -n` → 拿 ZH／EN dict 的行號
- Read skills/plan-review/SKILL.md 全文（235 行）
- `git diff --stat f46b73b 6a2bdd3 -- skills/` → 空輸出，範圍內 SKILL.md 沒改
- Read pg-review-diff.txt 1-300、300-457 → 讀完全份，含 ④ 對照表

## 需要外部查證
無。


## 處置

- 1（補派）：邊標籤改「補派後仍不足 3 個」／"still under 3 after backfill"
- 2（什麼算重大）：註解改成四行，補「金額、權限、刪資料一律算」與「或跳過你的決定」，中英同步
- 3（至少／最多一次）：框改「每人至少抽一處它引用的行來讀」「對不上就重派，最多一次」；legend 改「讀檔檢查沒過或回錯誤的審查者」，EN 同步
- 4（不再問）：框改「你的規則要批准時照樣問」／"approval only if your rules ask"
- Not reported 的四項維持不改（理由照審查者所寫）
