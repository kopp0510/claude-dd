# S1-judge（主對話查證）— 清理兩份 README

段落：使用者要求「README 太多廢話和歷史遺留的，請清理一下」。沒有進度表（單段），段落起點 `15e3446`。計畫經 plan-review 3 輪（第 3 輪第一次派工被中斷、使用者選重跑後通過）。

## 派工

- 審查範圍：`git diff 15e3446 07a1730`。diff 檔放 session 暫存目錄，組成：整段 diff、兩份 README 的 07a1730 版全文、已跑過的驗證與預期值（6 個 CI step、必留清單 grep、標題序列、被刪節名的引用）
- 步驟 3 沒跑 code-simplifier：diff 裡沒有程式碼
- 派 3 個 `code-reviewer`（下限）：A 資訊遺失、B 新句子對不對、C 同步點。改動全是文件，但刪哪句是大量人工判斷、新句子又改指別處，照 §3.9 不可 SKIP；三個方向對應「刪錯」「寫錯」「別處沒跟上」三種錯法

## 發現

| 項 | 查證 | 判定 |
|---|---|---|
| A1／B1／C1 步驟 5 合併後，「plugin 不在磁碟上」也寫成會印安裝指令 | 讀 `install-dd-pipeline.sh` 的 plugin 迴圈：不在磁碟那支印 `Plugin 檔案不存在` 後 `continue`；印 `claude plugin install` 的只有讀不到版本那支 | 採納 Important |
| A2 dd.docfile 刪掉「只接受單純檔名否則 exit 1」與「存在 `.git/config`、不進版控」 | 讀 `scripts/check-claude-md.sh` 的 `case "$DOC_FILE"` 與 `git config --local --get dd.docfile` | 採納 Important |
| B2 husky 括號接在「要你自己加」後面 | 讀 `commands/dd-init.md` Phase 3 第 2 步：husky v9 掛載點改成 `.husky/pre-commit`、照一般流程寫入 | 採納 Important |

駁回：無。

需要外部查證：A 問 task-planner 的互動行為（決策題、測試清單題）在新指向的檔裡有沒有寫 —— 主對話 grep `skills/task-planner/SKILL.md`，第 4 步標題就是「送 plan-review，問決策題與測試清單」，成立。

## 處置

- A1／B1／C1：兩份改回分開寫 —— 不在磁碟上印 `Plugin 檔案不存在` 後跳過；讀不到版本時跳過並印 `claude plugin install` 指令
- A2：兩份補回「存在 `.git/config`、不進版控，每個 clone 各自設」與「只接受單純檔名（不能帶路徑或空白、不以 `-` 開頭），否則每次 commit 都 `exit 1`」
- B2：兩份改成另起一句「husky v9 則由 `/dd-init` 直接寫進 `.husky/pre-commit`」
- 修完重跑 CI step（數字宣稱、flag 三方、迴圈步數四方、第五方、CHANGELOG 已發布區塊）全部 exit 0

## 重疊與獨有項

- 三個審查者**都**獨立抓到步驟 5 的條件被放寬 —— 不是誤判。這是「把兩條分支壓成一句」時最容易出的錯：條件從「各自」變成「其中一個」
- A 獨有：dd.docfile 的兩個失敗情況被刪（從「讀者會不會因此做錯」的方向才看得到）
- B 獨有：husky 的歧義（要讀 dd-init 的實際流程才看得出來）
- C 沒有獨有的 Important；它核過的同步點（錨點、節名、圖上字串、設計文件 A06）都成立
