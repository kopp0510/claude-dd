三個審查者都回來了，每條發現我都自己查過、也跑過變異。只有一條 Important 牽涉到行為：情境 ⑪ 的測試是空通過，`reviews_missing` 在「連共同祖先都沒有」那一支是否印警告，等於沒人在守。其餘兩條 Important 是文件與註解問題。

【派工】
派了 3 個 `code-reviewer`（haiku），在同一則訊息裡平行派出：
- **A**：`check-claude-md.sh` 的邏輯，看分支、邊界、bash 3.2 相容、stdout 與 stderr 有沒有分開。
- **B**：`test-gate.sh` 的鑑別力，看斷言有沒有空通過、測試有沒有真的走到被測的分支。
- **C**：兩份 CLAUDE.md 和註解裡的說法，在 HEAD 還成不成立。

為什麼是 3 個：diff 只有 4 個檔，但包含三類性質不同的東西（腳本邏輯、測試、文件裡的說法），各派一個方向剛好不重疊，也符合「最少 3 個」的規定。三個都正常回來，不用補派。A 和 B 各自獨立抓到同一個問題（下面採納 1）。

【採納】
1. **A + B + C｜Important｜情境 ⑪ 空通過：「連共同祖先都沒有」時，`reviews_missing` 的警告根本沒測到**
   - 我的查證：
     - `tests/test-gate.sh:340` 執行 `rm -rf … docs`，所以 `check-claude-md.sh:151` 的 `[ -d docs/reviews ] || return 1` 會先返回，走不到 :162–167。
     - `:349` 的 `said "找不到共同祖先"` 其實是被 `owed_dirs` 印的「也找不到共同祖先」（`check-claude-md.sh:108`）滿足的。
     - 我自己跑了一個變異：把 :167 的 `return 1` 改成 `return 0`，結果仍是 **90 ✅ / 0 ❌、exit 0**。A 刪掉 :165–166 的警告、B 把 :165 換成 `:`，也都全綠。
   - 這和文件的說法衝突：`:335–337` 的註解、`tests/CLAUDE.md:11` 都寫「兩處放行但必須印出警告」，對 `reviews_missing` 不成立。⑪ 宣稱要守的「S6 抓過的靜默放行」，現在完全沒人守。
   - 建議改法：
     - 在 orphan 線上重建 `docs/reviews/CLAUDE.md`（不放 `S*.md`），再跑 `--start-segment`。
     - 斷言 `reviews_missing` 才會印的那句「跳過 review 報告檢查」。
     - 改完用上面的 `return 0` 變異確認會變紅。

2. **C｜Important｜「永遠 `return 1`」那個變異，兩份 CLAUDE.md 都寫 12 紅，現在實測是 15 紅，是這次 diff 讓它過期的**
   - 我的查證：
     - HEAD 版把 `check-claude-md.sh:151` 改成 `return 1`，跑出 **83 ✅ / 15 ❌**。
     - 用 HEAD~1 的 gate 加 HEAD~1 的測試做同一個變異，跑出 **75 ✅ / 12 ❌**。
     - 所以是本次新增的 ⑩ 斷言讓紅數變多了。
   - 位置：`scripts/CLAUDE.md:27`、`tests/CLAUDE.md:33`。
   - 建議改法：依 §3.10 不寫數字，改成寫變異方法加「引用前先重跑」；不然就兩處同批改成 15。

3. **C｜Important｜⑦ 的標題還是「起點 commit 被改寫」，新加的註解卻說那句已經修正，同一個檔自相矛盾**
   - 我的查證：`git show HEAD:tests/test-gate.sh` 的 :273–276 仍寫「⑦ 起點 commit 被改寫(amend / rebase)之後…」，而本次新增的 :283–285 寫「上面那句註解原本寫…名稱與實際不符(S4 修正)」。這段改動只改了 `expect` 的說明字串，標題註解沒動。
   - 為什麼要修：這句註解會讓讀者以為「amend 起點」已經有測試。
   - 建議改法：把 :273–276 改成「amend 段落內的 HEAD」，並把真正改寫起點的情境指到 ⑩。另外檔內同時有 `# 7.`（:111）和 `⑦`，可以順便消除編號重疊。

4. **A｜Smells｜⑩ 的 `said "改從共同祖先"`（`:332`）分不出是 `reviews_missing` 印的**
   - 我的查證：`--start-segment` 會先跑 `owed_dirs`（`check-claude-md.sh:183`），它呼叫 `resolve_fork_base ""`，同樣會印「改從共同祖先」。我把 :162 的前綴 `"review 檢查"` 改成 `"XX"`，結果仍是 **90 ✅ / 0 ❌**。
   - 影響有限：同一則的 block 斷言和 `said "沒有新增任何…"` 是有鑑別力的。我另外把 `reviews_missing` 改回第一版的「非祖先就放行」，跑出 3 ❌。
   - 建議改法：斷言改成 `said "review 檢查改從共同祖先"`。

5. **C｜Smells（從 Important 降級）｜`scripts/CLAUDE.md:34` 寫比對樣式是 `S[^/]*`，實際程式碼是 `S[0-9]`**
   - 我的查證：`check-claude-md.sh:176` 是 `S[0-9][^/]*`。不過 `git show HEAD~1:scripts/CLAUDE.md` 的 :34 本來就這樣寫。
   - 降級理由：這是既有問題，不是本次 diff 引入的，本次也沒碰那一行。但它確實是錯的說法。
   - 建議改法：另外改成 `S[0-9]`。

【駁回】
- **B 在 Not reported 裡說「⑩ 的 `said` 字串都是各自函式獨有的」**：不成立，「改從共同祖先」兩處都會印，見採納 4 的變異。
- **C 在 Not reported 裡說「`--segment-base` 改成軟退化會得到 4 紅，和文件的 3 紅不符」**：這是 C 用的變異寫法不同（把 is-ancestor 改成 `true`）。我照字面寫一個「非祖先時印共同祖先」的軟退化，跑出 **3 ❌**；fork-point 整支拿掉是 **7 ❌**，拿掉警告（:89）是 **2 ❌**，三個數字都和 `scripts/CLAUDE.md:60–62` 一致。

【需使用者決定】
無

【需要外部查證】
- 註解和文件引用了「S6 的 reviewer 預言過」「S6 的 review 抓到這兩處已經漂移」：
  - 出處：`check-claude-md.sh:78,80`、`scripts/CLAUDE.md:55,58`。
  - 為什麼查不了：快照的 `docs/reviews/` 只有 `CLAUDE.md`，設計文件 grep 不到 S4、S6 或 `resolve_fork_base`，我沒辦法確認這些被引用的報告內容存在。依 §3.10「把自己的判斷掛到別人頭上」那條，請到原 repo 對照那份 S6 報告；找不到的話，改寫成「當時預判」。

【結論】
採納 Critical 0 / Important 3 / Smells 2。我沒有改任何檔，也沒有 commit。變異實驗都在 mktemp 暫存目錄裡跑，跑完已刪除，也確認沒有殘留程序。