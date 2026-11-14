Critical 1 / Important 2 / Smells 0 — 範圍是快照的 `git diff HEAD~1 HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）

**[Critical] tests/test-gate.sh:340、348-349：情境 ⑪ 根本沒跑到 `reviews_missing`，它聲稱要釘住的兩件事都沒有被測到**
- 原因：第 340 行 `rm -rf ... docs ...` 把工作目錄裡的 `docs/reviews/` 刪了。所以第 348 行的 `--start-segment` 在 check-claude-md.sh:151 `[ -d docs/reviews ] || return 1` 就直接返回了，連「無共同祖先」那一支都沒進去。
- 第 349 行的 `said "找不到共同祖先"` 能通過，靠的是 `owed_dirs` 自己的警告（check-claude-md.sh:108「…也找不到共同祖先，這次只檢查 staged」），跟 `reviews_missing` 無關。
- 這正是 tests/CLAUDE.md 第 11 行點名的「切到不含它的分支就整個檢查不啟用，測試為了錯的理由而通過」，而它又出現了。
- 失敗情境：把 check-claude-md.sh:165-166 的警告刪掉（又回到 S6 抓到的「靜默放行」），或把 :167 改成 `return 0`（無共同祖先時改成擋下），測試都照樣 90 ✅ / 0 ❌。
- 證據：見下方 M1、M2 兩個變異，兩個都存活。

**[Important] tests/test-gate.sh:332：`said "改從共同祖先"` 分不出警告是哪一處印的**
- `owed_dirs` 傳的 prefix 是空字串（check-claude-md.sh:105），它的警告本身就含「改從共同祖先」。所以就算 `reviews_missing` 退化時不出聲，這條斷言照樣通過。
- 目前能擋住的只有「不退化、直接放行」，因為第 331 行的 block 會變紅。「退化但靜默」擋不住。
- 失敗情境：把 :162 的 `resolve_fork_base` 呼叫加上 `2>/dev/null`，結果仍是 90 ✅。
- 修法提示：斷言改成比對 `"review 檢查改從共同祖先"`。
- 證據：見下方 M3。

**[Important] scripts/CLAUDE.md:62、tests/CLAUDE.md:11：文件宣稱的保證，在測試裡不成立**
- tests/CLAUDE.md:11 寫「連共同祖先都沒有時：兩處放行**但必須印出警告**」。scripts/CLAUDE.md:62 寫「退化時不印警告 → **2 紅**（落在 `said` 斷言上）」，但沒註明刪的是哪一行警告。檔內有三句：:89、:108、:165。
- 根專案 CLAUDE.md 規定「寫進文件的變異結果要註明插在哪一行」。
- 實際上刪掉 :165-166 是 0 紅。讀者照這兩句會以為 `reviews_missing` 的靜默放行已經被測試守住，不會再去查。
- 證據：同 M1。

**What I ran**
- 沒加任何變異、直接跑原版 gate → 90 ✅、exit 0（只是當作下面三個變異的對照，不是重跑你的驗證）
- M1：拿 gate 副本刪掉 :165-166（`reviews_missing` 無共同祖先時的警告）跑 `/bin/bash tests/test-gate.sh <副本>` → 90 ✅ / 0 ❌，exit 0
- M2：副本把 :167 的 `return 1` 改成 `return 0` → 90 ✅ / 0 ❌，exit 0
- M3：副本在 :162 的 `resolve_fork_base` 加 `2>/dev/null` → 90 ✅ / 0 ❌，exit 0
- 副本放在 mktemp 開的暫存目錄裡，跑完已刪掉，repo 沒有任何改動。

**Not reported**
- `--start-segment` 時 `owed_dirs` 和 `reviews_missing` 各呼叫一次 `resolve_fork_base`，退化警告會印兩次。只是外觀問題。
- test-gate.sh:340 的 `rm` 清單不完整（功能/、keep/、feat/ 這些留在工作目錄，被 `git add -A` 加進 r7）。但它們都附了 CLAUDE.md，不影響結果。
- 「前 61 項」這個寫法（scripts/CLAUDE.md:22、tests/CLAUDE.md:44、test-gate.sh:225）在這次之前就有，不在 diff 範圍內。
- scripts/CLAUDE.md:61 的「fork-point 拿掉 → 7 紅」和 :60 的「軟退化 → 3 紅」，我沒有重現。我讀到的程式碼看不出跟這兩個數字矛盾的地方。

**需要外部查證**：無
