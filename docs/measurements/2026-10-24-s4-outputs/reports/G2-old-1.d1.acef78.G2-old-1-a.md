Critical 0 / Important 1 / Smells 0 — 範圍：快照 `git diff HEAD~1 HEAD`（scripts/check-claude-md.sh、scripts/CLAUDE.md、tests/test-gate.sh、tests/CLAUDE.md）

[Important] tests/test-gate.sh:332 與 :347：「必須斷言那句警告真的印出來」這兩則斷言是空的。它們不管 `reviews_missing` 有沒有印警告都會過。
  Failure：`--start-segment` 會先跑 `owed_dirs`（check-claude-md.sh:183），它的退化警告已經包含 `改從共同祖先`（經 `resolve_fork_base` 印出，prefix 是空字串），也包含 `也找不到共同祖先`（:108）。所以 `said "改從共同祖先"` 和 `said "找不到共同祖先"` 都會被 `owed_dirs` 的輸出滿足。就算把 `reviews_missing` 自己那句警告刪掉（:165），或讓它的 fork 警告完全不印，測試照樣全綠。測試註解 :341-342 說要擋的「第一版在這裡靜默通過」那個回歸，正好就是抓不到的這一種。
  Evidence：在拋棄式目錄做了兩個變異。刪掉 :165 的結果是 exit=0、90 ✅、0 ❌；把 :162 改成 `resolve_fork_base ... 2>/dev/null` 的結果也是 exit=0、90 ✅、0 ❌。改成斷言 `reviews_missing` 才有的字串（`review 檢查改從共同祖先`、`這次跳過 review 報告檢查`）就分辨得出來。
  連帶問題：scripts/CLAUDE.md 新增那段寫「退化時不印警告 → 2 紅（落在 `said` 斷言上）」。這兩紅只對「拿掉 `resolve_fork_base` 那句共用警告」成立，因為那樣會連 `owed_dirs` 一起靜音。只針對 `reviews_missing` 的靜默變異是 0 紅，文件把這組測試的保護範圍講大了。

What I ran
- `git diff HEAD~1 HEAD`：取得被審 diff
- `git show HEAD:scripts/check-claude-md.sh`（1-70、95-290 行）、`git show HEAD:tests/test-gate.sh`（1-80 行與 said/base_is 的 grep）：讀上下文與測試輔助函式
- 在拋棄式目錄用 HEAD 版的 test-gate.sh 跑兩個 gate 變異（gA 刪 :165；gB 在 :162 加 `2>/dev/null`）：兩個都是 exit=0、90 ✅ / 0 ❌

Not reported
- scripts/CLAUDE.md 寫的「`--segment-base` 軟退化 → 3 紅」「fork-point 拿掉 → 7 紅」沒有重現，受「最多一次重現實驗」限制。要核對的話，用對應變異跑 `bash tests/test-gate.sh <變異 gate>`。
- `resolve_fork_base` 隱性讀全域 `$base`，屬於既有風格，兩個呼叫端都先跑過 `read_base`，找不到失敗情境，所以沒列。