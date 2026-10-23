Critical 0 / Important 1 / Smells 0 — 審查範圍：快照的 `git diff HEAD~1 HEAD`，4 個檔（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）

重構本身沒問題：`resolve_fork_base` 跟舊的兩段 inline 寫法行為一致。唯一的問題在新加的測試：情境 ⑪ 宣稱有守住 `reviews_missing`，實際上根本沒跑到它。

[Important] tests/test-gate.sh 情境 ⑪（diff.txt:185–199）在測 `reviews_missing` 時，`docs/reviews/` 已經被刪掉了，所以這個檢查根本沒啟動；`said "找不到共同祖先"` 吃到的是 `owed_dirs` 印的那句。
  失敗情境：把 `reviews_missing` 退回「第一版靜默放行」（刪掉 `找不到共同祖先，**這次跳過 review 報告檢查**` 那兩行 echo），或改成在這裡擋下（`return 1` 改成 `return 0`），測試都照樣 90 ✅ / 0 ❌。這正是這則測試註解（diff.txt:186–187）說要防的回歸。tests/CLAUDE.md（diff.txt:126）寫的「連共同祖先都沒有時：兩處放行但必須印出警告」也因此不成立。
  證據：diff.txt:190 的 `rm -rf r.js README.md src docs 'api server'` 把 `docs/` 刪了，之後也沒有重建；`reviews_missing` 第一行 `[ -d docs/reviews ] || return 1`（diff.txt:457）會直接返回。另外 `owed_dirs` 的警告「不在目前分支的歷史裡，也找不到共同祖先，這次只檢查 staged」（diff.txt:414）本身就含 `找不到共同祖先`。這跟 tests/CLAUDE.md 自己點名的第 ① 個陷阱一樣：opt-in 目錄不存在，測試就「為了錯的理由而通過」。變異實測 M1、M2 都是 90 ✅ / 0 ❌。
  同一類較輕的問題：情境 ⑩ 的 `said "改從共同祖先"`（diff.txt:182）也會先被 `owed_dirs` 印的那句（prefix 是空的）滿足。所以把 `reviews_missing` 傳的 prefix `"review 檢查"` 改成空字串，測試還是全綠（M3）。⑩ 的 block 和 `said "沒有新增任何 docs/reviews/S*.md"` 仍然證明 `reviews_missing` 有退到共同祖先，只是警告措辭沒人守。

逐項核對、沒有問題的部分：
- **警告字串**：prefix 為空時，`…？），${prefix}改從共同祖先 $fork 算起` 和舊 `owed_dirs` 那句逐字一樣；prefix 為 `review 檢查` 時，也和舊 `reviews_missing` 那句逐字一樣。
- **exit code**：`local` 跟賦值是分開寫的，所以 `if fork=$(…)`、`elif eff=$(…)`、`if ! range_base=$(…)` 拿到的都是指令替換本身的 exit code。
- **stdout 和 stderr 分流**：警告走 `>&2`，不會被 `$(…)` 吃進去。
- **全域 `$base`**：兩個呼叫端在呼叫前都已經 `read_base`。
- **`--segment-base`**：確實會硬失敗（diff.txt:516–521），不呼叫 `resolve_fork_base`，起點失效時 exit 1、stdout 是空的。
- **文件裡的變異紅數**：「3 / 7 / 2 紅」我實際跑過，跟文件一致（M4 / M5 / M6）。

What I ran
- `cp -R <快照> $(mktemp -d)/r`，在副本裡做 6 個變異，各跑一次 `bash tests/test-gate.sh <變異 gate>`，結果：
  - M1（刪 `reviews_missing` 無共同祖先的警告）→ 90 ✅ / 0 ❌
  - M2（`reviews_missing` 無共同祖先時改成 `return 0`）→ 90 ✅ / 0 ❌
  - M3（`reviews_missing` 的 prefix 改成空字串）→ 90 ✅ / 0 ❌
  - M4（`--segment-base` 改成軟退化）→ 3 ❌
  - M5（拿掉整段 fork-point 退化）→ 7 ❌
  - M6（`resolve_fork_base` 不印警告）→ 2 ❌
- 副本原版 `bash tests/test-gate.sh` → 90 ✅ / 0 ❌（只是當變異的對照組）
- `sed -n 1,80p tests/test-gate.sh`，加上 grep `共同祖先|segment-base` → 用來讀 helper 和定位情境

Not reported
- `--start-segment` 擋下時印的 `範圍 ${base}..HEAD`（diff.txt:499）：退到共同祖先時，實際範圍是 `fork..HEAD`，訊息不準。這是既有問題，這次 diff 沒動到那一行。
- 拋棄式目錄 `/var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.Tq4beEybu0` 還在。刪目錄依規定要先確認，所以我沒刪。