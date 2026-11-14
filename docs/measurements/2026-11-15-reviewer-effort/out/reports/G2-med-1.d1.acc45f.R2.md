Critical 0 / Important 2 / Smells 1。審查範圍是快照的 `git diff HEAD~1 HEAD`(4 個檔)。

**[Important] <WORK>/G2-med-1/tests/test-gate.sh:340、348–349 — 情境 ⑪ 根本沒跑到 `reviews_missing` 的「連共同祖先都沒有」分支,是「為了錯的理由而通過」。**
- 失敗情境:第 340 行 `rm -rf ... docs ...` 把 `docs/reviews` 刪了。所以第 348 行的 `--start-segment` 在 `[ -d docs/reviews ] || return 1`(gate:151)就返回了,永遠到不了 gate:162–167。第 349 行的 `said "找不到共同祖先"` 其實是被 `owed_dirs` 那句「…也找不到共同祖先，這次只檢查 staged」(gate:108)滿足的。
- 證據:我做了兩個變異,90 ✅ / 0 ❌ 都和基準一樣。M1 把 gate:167 的 `return 1` 改成 `return 0`(該放行卻擋);M2 刪掉 gate:165–166 那兩行警告(靜默放行,也就是 S6 抓到的那個繞過路徑)。
- 修法:在 orphan 線上 commit r7 之前重建 `docs/reviews/`(做法同 ⑩ 第 323 行),並把斷言收窄成 `said "這次跳過 review 報告檢查"`。

**[Important] <WORK>/G2-med-1/tests/CLAUDE.md:11 寫的「連共同祖先都沒有時:兩處放行**但必須印出警告**」是假宣稱。test-gate.sh:335 的註解「兩處都要放行但講出來」同樣不成立。**
- 失敗情境:後人會以為 `reviews_missing` 的無祖先分支有測試守著,而實際上任何改動那個分支的變異都是全綠。
- 證據:同上面的 M1 / M2 結果。scripts/CLAUDE.md:49 那列「`reviews_missing` … **放行，但印警告**」也沒有測試在守。修上一條時這幾處要一起改。

**Smells**
- [Smell] possible Mysterious Name / 隱性輸入,位置 <WORK>/G2-med-1/scripts/check-claude-md.sh:70–72、84、88:函式說明只寫了 `$1` / `$2`,但 `resolve_fork_base` 實際還讀全域的 `$base`。
  - 失敗情境:之後有人在沒先跑 `read_base` 的地方呼叫它,`$base` 是空的,`merge-base` 會失敗,函式落進 `return 1`。依各呼叫端,結果是「只檢查 staged」或「跳過 review 檢查」放行。
  - 證據:目前兩個呼叫端在呼叫前都跑過 `read_base`(gate:183、231、152),所以現在不會發生。

**What I ran**
- `sed -n` 印出 gate 的 89、165、166、167、210 行,確認變異的落點 → 各行內容與預期一致
- `/bin/bash tests/test-gate.sh <原版 gate>` → 90 ✅ / 0 ❌
- M1(gate:167 `return 1` 改成 `return 0`)→ 90 ✅ / 0 ❌
- M2(刪 gate:165–166 警告)→ 90 ✅ / 0 ❌
- M3(gate:210 的 `--segment-base` 改成軟退化)→ 3 ❌,和 scripts/CLAUDE.md:60 寫的「3 紅」相符
- M4(刪 gate:88–92 的 fork-point)→ 7 ❌,和「7 紅」相符
- M5(刪 gate:89 的警告)→ 2 ❌,和「2 紅」相符
- 變異副本與輸出放在 `/var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.srFRpgQR62`,沒刪(刪除要先經確認)

**Not reported**
- ⑩ 的 `said "改從共同祖先"`(test-gate.sh:332):`owed_dirs` 也會印這句,所以它分不出是哪個呼叫端印的。目前兩端共用同一句警告,只有「某一端改成自己印、而且不印」這種變異會漏掉,所以不報。
- test-gate.sh:340 的 `'api server'` 在檔內沒有任何地方建立過(grep 只命中這一行),orphan 線上也留著 p/、w/、keep/ 等舊目錄。都無害。
- 「前 61 項」(scripts/CLAUDE.md:22、tests/CLAUDE.md:44)是改動前就有的寫法,不在這次 diff 裡。

**需要外部查證**:無。
