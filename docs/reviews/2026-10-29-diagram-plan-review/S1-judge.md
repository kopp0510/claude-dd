# S1-judge（主對話查證）— plan-review 流程圖

段落：使用者指出 plan-review 沒有出現在流程圖裡，選了「兩張圖都給它自己的框」。沒有進度表（單段），段落起點 `1971cf5`。

## 派工

- 審查範圍：`git diff 1971cf5 801a317`（不含 GIF）。diff 檔放 session 暫存目錄，組成：整段 diff、三個被改到的檔的 HEAD 版整檔、已跑過的驗證與預期值（幾何檢查、getBBox、GIF 幀與接點 PSNR）
- 派 3 個 `code-reviewer`（下限）：A 圖上文字宣稱、B 產生器程式碼、C 文件與同步點。改動只有兩支產生器的字串與座標、一份 CLAUDE.md、兩句 README 圖說，三個方向就涵蓋了
- 與步驟 3 的 code-simplifier 並行。simplifier 沒有改任何檔（判斷改動都是座標與清單資料，沒有可以合併的邏輯），並核對了新註解裡的數字（間距 80、68px→1.44、88px→1.8、9 個節點）

## 發現

| 項 | 查證 | 判定 |
|---|---|---|
| A1／B2 planner review 框「只問你決策題」 | `skills/task-planner/SKILL.md:79`：「問兩種題，跟它交回的『需使用者決定』一起問」 | 採納 Important |
| A2 中英語意不一致 | 讀兩版字串：planner ZH 多半句、usage ⑤ EN 少「通過才」 | 採納 Important |
| A3／B1 1 段那條路看起來不用審 | `skills/task-planner/SKILL.md:54`：「它仍是全域 §4.1 的複雜任務，計畫先交 `plan-review`」 | 採納 Important |
| A4 漏 design-brainstorm 例外 | `skills/plan-review/SKILL.md:22`：「不跑（但走 `design-brainstorm` 的設計不論大小都跑）」 | 採納 Important |
| B3／C2 來源清單與 foot 沒有 plan-review | 讀 `diagrams/src/CLAUDE.md`「與上層的關係」與兩支 foot 字串 | 採納 Important |
| C1 CHANGELOG `## 未發布` 沒條目 | `sed -n 19,24p CHANGELOG.md` 只有 ADHD 那條 | 採納 Important |
| C3 ⑤ 在「每個功能段落」容器裡 | 看渲染截圖：⑤ 在 STEP 3 框內 | 採納 Important |

駁回：無。

需要外部查證：B 問「1 段那條路要不要改」、C 問「⑤ 要移出容器還是改標題」。前者 §4.1 與 task-planner 已寫明，不是使用者的選擇；後者看了截圖，選改標題（移出容器會新增「容器外節點」這個幾何失敗項）。

## 處置

- A1／A2／B2：planner review 框兩版都只寫「通過才寫檔／written only after it passes」；usage ⑤ 的 EN 改成 "work starts only after the plan passes"
- A3／B1：planner 的 loop 框加第二行「計畫仍先過 plan-review／the plan still goes to plan-review」
- A4：usage 註解第一行改成「簡單、中等任務跳過 ⑤（design-brainstorm 的設計例外）」，`diagrams/src/CLAUDE.md` 的描述同步
- B3／C2：`diagrams/src/CLAUDE.md` 來源清單加 `skills/plan-review/SKILL.md`；兩支 foot 補 plan-review
- C1：`CHANGELOG.md` 的 `## 未發布` 補一條
- C3：usage STEP 3 容器標題改成「日常開發（計畫審一次，每個功能段落走迴圈）」
- 修完重出：幾何檢查 planner 兩版 exit 0；usage 兩版只剩修前就有的「⑧ 在容器外」與 1 處估算溢出；getBBox 量所有節點文字距框右緣都 ≥12px；
  4 張 GIF 各 144 幀、第 0 與第 40 幀不同、接點 PSNR 與相鄰幀差 <0.2dB

## 重疊與獨有項

- A 與 B 都獨立抓到「1 段那條路沒標 plan-review」與「只問你決策題」—— 不是誤判
- B 與 C 都抓到來源清單少了 plan-review
- A 獨有：中英語意不一致、design-brainstorm 例外（C 在 Not reported 判成「圖內簡化」，讀 skill 原文後判 A 對：圖上寫的是無條件規則）
- C 獨有：CHANGELOG 沒條目、⑤ 所在容器的標題會誤導
- B 負責的幾何與動畫沒有發現問題，三條發現都在文字語意 —— 單派一個「文字宣稱」方向的話會漏掉 C 的兩條同步點
