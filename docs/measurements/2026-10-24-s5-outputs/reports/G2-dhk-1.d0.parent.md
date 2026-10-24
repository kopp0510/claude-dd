## 步驟 4 code-review 報告（G2-dhk-1）

【派工】
- 派了 3 個 `code-reviewer`（haiku），在同一則訊息裡並行。方向如下：
  - A：`scripts/check-claude-md.sh` 的正確性與回歸
  - B：`tests/test-gate.sh` 新情境有沒有鑑別力（做變異實驗）
  - C：兩份 CLAUDE.md 與註解裡的宣稱是否跟程式一致
- 為什麼派 3 個：diff 是「1 支腳本＋1 支測試＋2 份文件」，剛好切成三個不重疊的方向，3 也是規定的下限。
- 三個都有回來，不用補派。
- A 只用了 4 次工具，什麼都沒跑，回報 0 項發現，下面兩條 Important 它都沒抓到。所以 A 的「乾淨」不能當成「沒有問題」的證據。另外 A 說「`--diff-filter=A` 的改動只在 `reviews_missing`」，但這次 diff 根本沒有改 `--diff-filter`，可見它沒有逐段讀 diff。
- 我自己在 `/tmp/g2mut.xJPx`（拋棄式副本，沒動快照）跑了以下變異：M1、M2、E、A、B、C、r1、if-false。

【採納】
1. B＋C｜**Important**｜情境 ⑪ 宣稱測了「連共同祖先都沒有時，兩處都放行並印警告」，實際上 `reviews_missing` 那一支從來沒跑到。
   - 查證：`tests/test-gate.sh:340`（diff 檔 L997）`rm -rf r.js README.md src docs …` 把 `docs/reviews` 一起刪了。所以 `check-claude-md.sh:151` 的 `[ -d docs/reviews ] || return 1` 先返回，走不到 `:162-167`。這正是 ⑩ 自己的註解（`:319-322`）點名過的「為了錯的理由而通過」，⑩ 修好了，⑪ 又重踩一次。
   - 實測：
     - M1，刪掉 `:165-166` 的警告 → 0 ❌
     - M2，`:167` 的 `return 1` 改成 `return 0` → 0 ❌
     - E，只刪 `owed_dirs` 的警告（`:108`）→ ⑪ 的 `said "找不到共同祖先"` 變紅。這證明這個斷言是被 `owed_dirs` 那句滿足的。
   - 調級理由：程式行為本身是對的，所以不到 Critical。但測試宣稱的覆蓋並不存在，而且有三處文件重複這個宣稱，依專案規則屬於 review 要抓的「宣稱與實際不符」。
   - 同一個宣稱出現在三處，都要修：
     - `tests/test-gate.sh:335-337`
     - `tests/CLAUDE.md:11`（「兩處放行但必須印出警告」）
     - `scripts/CLAUDE.md:49` 那一列，以及 `:59`（「改這三處任何一處，先跑變異測試」）。對這一格跑變異會得到 0 紅。
   - 建議改法：在 ⑪ 的 `commit r7` 之前加 `mkdir -p docs/reviews && echo 格式 > docs/reviews/CLAUDE.md`（照 ⑩ 的寫法），並在 `--start-segment` 之後加 `said "這次跳過 review 報告檢查"`。
   - 驗收條件：拿修好的測試重跑 M1 和 M2，兩個都要紅。

2. C（加我自己查證）｜**Important**｜新註解宣稱「修正」了一件其實沒修的事，還引用了一個已經不存在的分支。
   - 查證 1：`tests/test-gate.sh:284-285` 寫「上面那句註解原本寫『起點 commit 被改寫』……(S4 修正)」。但 `:273` 的 ⑦ 標頭現在仍是「⑦ **起點 commit 被改寫(amend / rebase)之後…**」。`git diff HEAD~1 HEAD -- tests/test-gate.sh | grep -c '^-.*起點 commit 被改寫'` 回 0，也就是標頭從來沒被改過。讀的人會先看到標頭這樣說，十行後又讀到「這句已經修正」。
   - 查證 2：`:283` 寫「走的是 `range_base="$base"` 那一支」。`grep -n 'range_base="\$base"' scripts/check-claude-md.sh` 沒有命中（exit 1），這次 diff 已經把那支抽進 `resolve_fork_base`（`:84-86`）。
   - 建議改法：
     - 把 ⑦ 標頭改成實際測的內容：「段落內的 HEAD 被 amend，起點仍是祖先」。
     - 刪掉「原本寫…修正」那半句。
     - 分支引用改成「`resolve_fork_base` 的 is-ancestor 分支」。

3. B＋C｜**Smells**（從 Important 降級）｜「永遠 `return 1` → 12 紅」被這次新增的情境弄過期了。
   - 位置：`scripts/CLAUDE.md:27`、`tests/CLAUDE.md:33`。
   - 查證：同一個變異 r1，跑舊版測試（`HEAD~1`）是 12 行 ❌，跑新版測試是 15 行 ❌。那一列不在這次 diff 的增刪行裡，但數字是被這次 diff 弄過期的。
   - 降級理由：那一列的論點「新區塊真的在測這個功能」仍然成立，只有數字不對。
   - 建議改法：改成 15，或依全域 §3.10 改寫成「哪個變異 → 哪幾則情境變紅」並附產生指令。

4. B｜**Smells**｜沒有任何斷言保證「起點是祖先的正常路徑不印退化警告」。
   - 查證：`check-claude-md.sh:84` 改成 `if false; then` → 90 ✅ / 0 ❌。原因是 `merge-base` 對祖先會回它自己，結果一樣，只是每次都多印一句假警告。
   - 舊程式也有同樣的缺口，但這次把那一支抽成共用函式，又寫了「改這三處先跑變異測試」，所以列入。
   - 建議改法：在某一則正常的 `pass` 後面斷言輸出不含「不在目前分支的歷史裡」。

5. B｜**Smells**｜變異表沒寫「紅」是以什麼為單位（❌ 行數還是失敗的 expect 數）。
   - 查證：我的變異寫法數 ❌ 行數，得到 3／7／2，與文件一致。B 換一種寫法得到「3 個 expect、4 行 ❌」。
   - 建議改法：表頭註明單位，並寫出變異的確切改法。

另外核對過、跟文件一致的數字：`--segment-base` 軟退化 → 3 ❌（實測 3），拿掉 fork-point 整支 → 7 ❌（實測 7），拿掉 `resolve_fork_base` 的警告 → 2 ❌（實測 2）。

【駁回】
- C｜「退化時不印警告 → 2 紅」對不上（C 量到 1 紅）。
  - 理由：C 拿掉的是 `owed_dirs` 的警告。文件指的是 `resolve_fork_base` 的警告（`:89`），我和 B 實測都是 2 紅，與文件相符。
- A Not reported #1｜HEAD 被倒退到起點之前時，訊息會指錯原因。
  - 理由：屬於既有問題。舊版 `reviews_missing`（`HEAD~1` 的 `:106-110`）和新版 `resolve_fork_base`（`:84-92`）是同一組 `merge-base` 呼叫，結果相同，不是這次 diff 造成的。
- A Not reported #2｜刪掉再加回同內容的報告，可能被當成 rename。
  - 理由：`git diff base head` 只比兩端，起點沒有的檔案會顯示成 A。要被判成 R，必須同時有另一份同內容的檔案被刪掉，情境太罕見，不採納。
- C Not reported｜gate 訊息 `:196-197` 寫「兩個 reviewer」，跟全域 §3.9 的「最少 3 個」不一致。
  - 理由：那幾行不在這次 diff 內，屬於既有問題。記一筆，另開處理。

【需使用者決定】
無。表格裡每一格的退化政策都有文件寫明是刻意這樣設計的。

【需要外部查證】
- `scripts/CLAUDE.md:55-58`、`check-claude-md.sh:78-80`、`test-gate.sh:337` 把一些事歸給「S6 的 review 抓到」「S6 的 reviewer 預言過」「S4 實作時確認」。快照只有 2 個 commit，`docs/reviews/` 裡只有 CLAUDE.md，沒辦法驗。需要 S4、S6 的 review 原文與 commit hash。

【結論】
採納 Critical 0 / Important 2 / Smells 3。依規則 Important 要先修掉才能往下走。沒有改任何檔，也沒有 commit。變異副本留在 `/tmp/g2mut.xJPx`，可以自行刪除。