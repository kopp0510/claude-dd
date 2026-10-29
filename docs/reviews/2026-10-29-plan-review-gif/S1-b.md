# S1-b（審查者 B）— plan-review 流程圖

## 派工

```
你是 8 步迴圈步驟 4 的審查者 B。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。

專案根目錄：/Users/danlio/project/my_project/claude-dd
審查範圍：git diff f46b73b 6a2bdd3（新增 plan-review 流程圖：產生器 diagrams/src/gen_review.py、兩張 GIF、README 嵌入、diagrams/src/CLAUDE.md 與根 CLAUDE.md 同步、CHANGELOG、進度表）。
材料：<scratchpad>/pg-review-diff.txt（完整路徑：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/pg-review-diff.txt）。
用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔用 git show 6a2bdd3:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。
材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。

背景（事實）：使用者要一張專門畫 plan-review 怎麼運作的圖。圖的結構（8 框、9 條線、3 組）、框 ① 寫「推測要標明」、「無法判定」從讀檔檢查拉出，都是使用者決定的，不要建議改結構；但框裡的字若與 SKILL.md 原文意思不符，照報。計畫審過 2 輪。

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

Critical 0 / Important 2 / Smells 0：審 git diff f46b73b 6a2bdd3，重點看 diagrams/src/gen_review.py，以及它是否符合 diagrams/src/CLAUDE.md 的慣例

## Findings

[Important] diagrams/src/gen_review.py:197（材料行 365；第 365 行是我在 pg-review-diff.txt 裡讀到的行號，檔案行號是推算的）｜註解寫「68px→1.44」，但 `third` 這條同樣 68px 的線用的是 dur 1.2
  證據：我照 paths 的公式算出各線長度與 dur：send、retry、verify 都是 68px／1.44，third 是 68px／1.2（`ball("third", GOLD, 1.2, -0.4)`）。換算成速度，third 是 56.7 px/s，其他 68px 的線是 47.2 px/s。另外兩組數字屬實：88px→1.8（start）、128px→2.4（short、ok）。
  失敗情境：註解宣稱的長度→dur 對照有一條例外，註解沒寫。之後有人照註解調 dur，或照它新增 68px 的線，會以為 1.44 是唯一值，看不出 third 為什麼不同。修法二選一：third 改成 1.44，或在註解列出 1.2 的理由。

[Important] diagrams/src/gen_review.py:208（材料行 371；檔案行號是推算的）｜`short` 這條線畫成主流程的金色實線，跑在上面的球卻是灰色。灰色在 legend 只代表「重派」
  證據：`short` 列在金色實線那組，也就是 `for k in ("start", "send", "verify", "short", "ok", "fail", "third")`。球卻是 `ball("short", GRAY, 2.4, -1.3)`。legend 裡灰色只有一項：「重派：讀檔檢查沒過的審查者」（GRAY, dashed）。其他每條線的球都跟線同色，gen_planner.py 也一樣，例如 resume 線是 MINT、球也是 MINT。
  失敗情境：讀者在 GIF 上看到灰球從 ③ 讀檔檢查往下跑到 ⑧ 無法判定，照 legend 會讀成「重派」那條路。實際上這條是「有效審查者不足 3 個」的出口。diagrams/src/CLAUDE.md 的規則「legend 與實際連線一一對應」只管線，沒管球色，所以幾何檢查與 legend 規則都抓不到。修法二選一：球改成 GOLD，或者 short 線改成灰色並加進 legend。

## Not reported
- 我逐項核過、屬實的約束：所有 dur 都整除 7.2（1.2／1.44／1.8／2.4／7.2）。begin 全為負值，而且都不是各自 dur 的整數倍。again 兩顆球是 -0.3 與 -3.9，差 3.6，正是半週期，「錯開半週期」屬實。again 是最長的路徑（1518px），「最長的那條放兩顆」屬實。最短的線 68px，大於 40px，不違反短路徑不放球的規則。連線都畫在 defs 外、標了 data-role="edge"、只用 M/L。邊標籤都墊了 data-role="mask"。強調色只有 GREEN（ok）與 AMBER（fail），屬實。legend 三項對應三種實際線型（金實線、GOLD_DIM 虛線、GRAY 虛線），marker 也對得上。另外三句註解也屬實：「共用同一個 80px 間隙、上下錯開 30px」（350→430、c1±15）、「停在目標框前 12px」、「分組標題靠右」（start 線在 x=225、short 線在 x=555，都從容器上緣左半邊進入）。
- 從 gen_planner 原樣帶進來的 `box()` 註解（2026-09-12 那段歷史，「已經不成立了」）：放在新檔裡只是歷史敘述，沒有錯誤宣稱，不報。
- esc／poly／text_width／label／note／ball 跟 gen_planner.py 重複：專案寫明「`gen_review.py` 照 `gen_planner.py` 的做法寫」，而且每支產生器都獨立一份，所以照專案慣例不列為 Duplicated Code。
- 材料 ④ 引用「CLAUDE.md:311」，但 HEAD 那句在第 313 行（指路那段讓它下移 2 行）。這是驗證紀錄裡的行號，不在 diff 內。
- 框內字句與 SKILL.md 原文的對照不在我的方向內，沒有逐句審。

## What I ran
- Read pg-review-diff.txt 1–300、300–457 → 讀完全部 457 行
- `git show 6a2bdd3:diagrams/src/CLAUDE.md | sed -n 36,95p` → 讀到慣例全文（7.2 整除、負 begin、begin 不是 dur 的整數倍、<40px 不放球、legend 一一對應）
- `git show 6a2bdd3:diagrams/src/gen_planner.py`（grep ball/dur/legend/PLACE，並讀 28–36、180–200 行）→ planner 的每顆球都跟所在的線同色；它的註解寫「68px→1.44、88px→1.8、323px→7.2」
- `git grep -n -E '三支|6 張|6 份|六張|11 張|gen_planner|three generators|planner-(en|zh)' 6a2bdd3`（排除 reviews、measurements、CHANGELOG、designs）→ 沒有漏改的計數宣稱，只剩 CLAUDE.md:313 那句刻意保留的引用
- python3 照 gen_review 的座標公式算 9 條路徑的長度、dur、px/s → start 88/1.8/48.9、send 68/1.44/47.2、retry 68/1.44/47.2、verify 68/1.44/47.2、short 128/2.4/53.3、ok 128/2.4/53.3、fail 383/7.2/53.2、third 68/1.2/56.7、again 1518/7.2/210.8

## 需要外部查證
- 灰球在 GIF 上是否真的會被讀成「重派」：要看 diagrams/claude-dd-plan-review.gif 的 ③→⑧ 段，用肉眼判斷。這屬於視覺判讀，我沒開 GIF。

## 處置

- 1（third 的 dur）：改成 1.44，與其他 68px 的線同速；註解補上 383px→7.2
- 2（short 的灰球）：球改 GOLD，跟線同色；註解加「球色跟所在的線同色（legend 只講線色）」
- 主對話另補：again 約 1518px、dur 只能到 7.2，球比別條快約 4 倍，寫進註解（不改圖）
- 需要外部查證（灰球會不會被讀成重派）：球已改金色，問題不再存在
