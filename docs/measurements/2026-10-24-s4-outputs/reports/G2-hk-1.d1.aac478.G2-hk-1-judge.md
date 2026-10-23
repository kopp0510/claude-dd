【派工】
派了 3 個審查者（code-reviewer，haiku），在同一則訊息裡平行派出，3 個都有回來，不需要補派。
- A：查 `scripts/check-claude-md.sh` 重構前後是否等價，包括 `$base` 全域變數、stdout/stderr 分流、exit code、`${prefix}` 為空字串時的措辭、`--segment-base` 是否真的硬失敗。
- B：查 `tests/test-gate.sh` 的 ⑦⑩⑪ 斷言有沒有真的走到它名稱宣稱的分支。
- C：查註解與文件的宣稱是否符合程式碼，以及專案規則（變異結果、歸因、CHANGELOG）。

為什麼是 3 個：diff 只有 4 檔，其中 1 檔是腳本，風險集中在三類：重構等價、測試有沒有測到、文件宣稱。一類派一個，達到下限 3 就夠了。
另外要照實說：A 自行把 gate 複製到 `/tmp/gA-mut` 做變異實跑，超出了「只准讀」的路徑限制。它沒有改到快照，結果和 B 純讀碼推演出來的一致。

【採納】
1. A＋B｜Important｜⑪「連共同祖先都沒有：兩處都放行但要講出來」其實沒有測到 `reviews_missing` 那一處。
   - 查證：
     - test-gate.sh HEAD:340 在 orphan 分支上 `rm -rf ... docs`，所以 check-claude-md.sh:151 的 `[ -d docs/reviews ] || return 1` 會提前返回，走不到 162–167 行的警告。
     - test-gate.sh:349 的 `said "找不到共同祖先"` 被 `owed_dirs` 自己的警告滿足了：check-claude-md.sh:108 印「也找不到共同祖先」，而 `--start-segment` 在 183 行會先跑 `owed_dirs`。
     - A 的變異實跑：刪掉 165 行的警告後，結果是 90 ✅ / 0 ❌，也就是 S6 修過的「靜默放行」回歸不會被抓到。
     - test-gate.sh:335 的註解、tests/CLAUDE.md 新增那句「連共同祖先都沒有時：兩處放行但必須印出警告」，對 review 這一處都不成立。⑩ 的註解（diff 檔 169–172 行）點名過這種「目錄不在、為錯的理由而通過」，結果 ⑪ 又重犯一次。
   - 建議改法：在 orphan 分支的 r7 之前重建 `docs/reviews/CLAUDE.md`（只放 CLAUDE.md，不放 S*.md）。把 said 改成只有 `reviews_missing` 會印的「跳過 review 報告檢查」。改完重跑同一個變異，確認會變紅。

2. C｜Critical 降為 Important｜scripts/CLAUDE.md 新增的變異結果「3 紅 / 7 紅 / 2 紅」只寫了語意、沒寫插在哪一行。
   - 查證：
     - 根目錄 CLAUDE.md:307 明文要求「寫進文件的變異結果要註明插在哪一行」。
     - 「退化時不印警告 → 2 紅」沒說是哪一句警告。第 1 條已經證實：刪 `reviews_missing` 的警告是 0 紅。這句文件會讓人以為兩處的警告都有測試守著。
   - 降級理由：只影響文件，執行期沒有影響。但它和第 1 條的漏洞直接相關，所以不降到 Smells。
   - 建議改法：每個變異寫明「哪一行改成什麼 → 哪幾個情境變紅」（照全域 §3.9「要記哪個變異 → 哪幾個情境變紅」）。修完第 1 條之後再重量一次。

3. C＋B｜Smells｜統一只改了一半。新註解（test-gate.sh:284–285）說「上面那句註解原本寫『起點 commit 被改寫』…（S4 修正）」，但 ⑦ 的段落標題（test-gate.sh:273）在 HEAD 仍然是「起點 commit 被改寫(amend / rebase)之後」，下面還寫著「現在退到共同祖先繼續算」。
   - 查證：`git show HEAD~1:tests/test-gate.sh` 的 273 行就是這個標題；diff 沒動它，只改了 expect 的描述字串。新註解說「已修正」，實際沒修。
   - 建議改法：把 ⑦ 的標題與內文改成「amend 段落內的 HEAD」，或把那句「原本寫…已修正」刪掉。

【駁回】
- B｜「往寬退才不會把 report 要求洗掉」理由方向相反（寬範圍更容易找到 S 檔）。
  - 理由：對照組不是「窄範圍」，而是 v1 的直接放行（check-claude-md.sh:158–160 的註解寫明）。退到共同祖先比放行嚴格，這句成立。B 自己也沒列為缺陷。
- B｜⑩ 的 `said "改從共同祖先"` 同時被兩處警告滿足。
  - 理由：test-gate.sh:333 的 `said "沒有新增任何 docs/reviews/S*.md"` 只有 `reviews_missing` 擋下時才會印（check-claude-md.sh:191–193）。再加上預期是 block，已經足以鎖定 review 那一支。
- C｜CHANGELOG `## 未發布` 沒有條目。
  - 理由：這次是內部重構加測試，使用者可見的行為不變（A 已逐支核對等價），不需要條目。
- A｜重構等價性：沒有發現問題。我自己也讀了 diff 檔裡 check-claude-md.sh 的 82–94、100–111、149–168 行：
  - `prefix=""` 時印出的警告和舊版逐字相同。
  - 警告走 stderr，所以命令替換只抓到 sha。
  - 函式在子 shell 裡跑，`local head` 不會污染呼叫端。
  - `--segment-base` 在 209–216 行確實硬失敗。

【需使用者決定】
無

【需要外部查證】
- C 提的歸因問題：check-claude-md.sh:78、80 與 scripts/CLAUDE.md 新段落寫「S6 的 reviewer 預言過」「S6 的 review 抓到這兩處已經漂移」。快照只有兩個 commit（e0177bd base、85d416f change），`docs/reviews/` 底下只有 CLAUDE.md，在快照裡查不到 S6 報告的內文。要到原 repo 的 `docs/reviews/` 或 S6 的派工紀錄 grep「預言」「漂移」的原文；找不到就改成「我當時這樣預判」（全域 §3.10）。
- 「3 / 7 / 2 紅」與 scripts/CLAUDE.md 既有表格裡的 12 紅，三個審查者和我都沒有重量過，只有第 1 條那一個變異被 A 實跑過。

【結論】
Critical 0 / Important 2 / Smells 1（採納數）。採納的 2 條 Important 要先修，修完才能續行，其中第 1 條是測試的漏洞，不是 gate 本身的錯。依指示沒有改任何檔，也沒有 commit。