# S1-judge（主對話查證）— 清理各層 CLAUDE.md

段落：使用者要求「所有的CLAUDE.md 和README.md 都是檢查 有沒有多餘廢話 或老舊資訊 不可靠 沒有參考價值的 都清理」，選了清理「有把握可刪」與「寫短（拿掉日期、故事）」兩類；「可能可刪（沒驗證）」不動，寫錯或過時的直接修。沒有進度表（單段），段落起點 `2d436c0`。計畫經 plan-review 1 輪通過（13 條小修正照改）。

## 派工

- 審查範圍：`git diff 2d436c0 86f37df`。diff 檔放 session 暫存目錄，組成：整段 diff、已跑過的驗證與預期值（6 個讀文件的 CI step、替換腳本 0 個 WARN、`.ttl`／`.sm` 實測、蓋章區塊沒動）。被改到的檔工作目錄與 HEAD 相同，讓審查者直接讀 repo
- 步驟 3 沒跑 code-simplifier：diff 全是 `.md`，沒有程式碼
- 派 3 個 `code-reviewer`（下限）：A 規則遺失、B 新句子對不對、C 同步點。刪哪句是大量人工判斷、又改指別處，照 §3.9 不可 SKIP
- 審查者 C 審到一半時主對話已開始修 A、B 的發現，C 在報告開頭註明了，判定以 HEAD 為準

## 發現

| 項 | 查證 | 判定 |
|---|---|---|
| A1／B1／C1 `diagrams/src/CLAUDE.md`「要 ≥12px」把量測值寫成門檻 | 讀 `verify-geometry.py` 的 `check_text_overflow`：只判有沒有超出框、容差 0.5px | 採納 Important |
| A2 scripts 的「S6-a 的 A2 / S6-b 的 B2」指到兩份同名檔 | `ls` 確認根目錄與 `2026-10-23-裁決審查/` 各有一份 `S6-a.md` | 採納 Important |
| A3 `docs/reviews/CLAUDE.md` 判例縮太短 | 舊文有「⑦ 釘住它」與 `tests/test-gate.sh` 的更正位置；`grep -n '⑦' tests/test-gate.sh` 有該註解 | 採納 Important |
| A4 `docs/reviews/CLAUDE.md` 刪了「2026-10-24 以前」 | `ls docs/reviews/2026-10-23-裁決審查/`：S1、S2 兩份一組，S3 起 3 份以上 | 採納 Important |
| B2／C2 tech-diagram-gif 實證來源搬家時掉了 | `grep -n tech-diagram-gif DD_PIPELINE_ARCHITECTURE.md`：只有日期 | 採納 Important |
| C3 `verify-geometry.py` docstring 指向被刪的「十幾處」 | 讀 docstring：「同目錄 CLAUDE.md 的字級那條記過」 | 採納 Important |
| C4 CHANGELOG 的修正清單看起來完整 | 對照 diff：§7.2、wrapper、style-8 路徑沒列 | 採納 Important |
| B3 兩個括號連在一起 | 讀那一行 | 採納 Smell |

駁回：無。

不改：三個審查者都在 Not reported 提到 `scripts/CLAUDE.md` 的「`test-gate.sh` 前 61 項」。第 1 輪 plan-review 判它是位置描述（`tests/test-gate.sh` 自己也這樣標），不是過期的項數，照計畫保留。

需要外部查證：B 問 `~/.claude/settings.json` 有沒有手動登記 error-capture —— 主對話 `jq -r '.hooks // {} | tostring' ~/.claude/settings.json | grep -c error-capture` 得 0，新句子「不要手動加」成立。

## 處置

- A1：改回「2026-09-11 量的四張，字尾離框右緣都還有 ≥12px；這是量到的值，不是門檻」
- A2：補完整路徑 `docs/reviews/S6-a.md`／`S6-b.md`，註明 `2026-10-23-裁決審查/` 的同名檔是別的事
- A3：判例補回「⑦ 本來就釘不到」與 `tests/test-gate.sh` ⑦ 的註解
- A4：補回「2026-10-24 以前」，加「之後的段落照上面的格式」
- B2：`DD_PIPELINE_ARCHITECTURE.md` 部署清單補「實證來源為當次對話的完整管線驗證」
- C3：不動程式碼，把「`.nm` 實際 15 卻當成 20，英文版誤報十幾處」補回 `skills/tech-diagram-gif/scripts/CLAUDE.md`
- C4：CHANGELOG 補三項，並寫明「不只下面這些」
- B3：兩個括號併成一個
- 修完重跑 6 個讀文件的 CI step，全部 exit 0

## 重疊與獨有項

- 三個審查者**都**抓到「≥12px 變成門檻」—— 不是誤判。這是「刪日期」最容易出的錯：日期一拿掉，量測值讀起來就像規則
- B 與 C 都抓到實證來源掉了：刪句子時以為「別處已經講了」，實際上別處只有一半
- A 獨有：兩條指標失去唯一能定位的路徑（同名檔問題），以及日期本身就是規則的邊界
- C 獨有：程式碼註解指向被刪的文字（只 grep CLAUDE.md 看不到），以及 CHANGELOG 清單不完整
