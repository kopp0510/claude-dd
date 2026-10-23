Critical 0 / Important 1 / Smells 0 — 範圍：快照 `git diff HEAD~1 HEAD`（scripts/check-claude-md.sh、scripts/CLAUDE.md、tests/test-gate.sh、tests/CLAUDE.md）

[Important] tests/test-gate.sh:349 情境 ⑪ 沒有守住 `reviews_missing` 的「連共同祖先都沒有」分支，而註解宣稱它守住了這一支。
  Failure: 有人把 `scripts/check-claude-md.sh:165` 的警告刪掉（即 S6 那個「靜默放行」的回歸），整段仍放行、測試仍全綠，沒有任何情境會變紅。
  Evidence: 第 340 行 `rm -rf ... docs ...` 之後，docs/reviews 已不存在，`check-claude-md.sh` 的 `reviews_missing` 在第 151 行 `[ -d docs/reviews ] || return 1` 就提前返回，走不到第 162–167 行。第 349 行的 `said "找不到共同祖先"` 其實是 `owed_dirs` 第 108 行的警告在撐。變異實驗：刪掉第 165 行警告後重跑 `bash tests/test-gate.sh <變異 gate>` → exit 0、90 ✅ / 0 ❌。

修正方向（不替你動手）：情境 ⑪ 要在 `docs/reviews/` 存在的狀態下驗 `reviews_missing` 的警告，例如在 orphan 分支上補建 docs/reviews/CLAUDE.md，然後重跑變異確認會變紅。

What I ran
- `cat diff.txt`（前 220 行與 check-claude-md.sh、test-gate.sh 整檔）→ 讀取完成
- `grep -n "rm -rf r.js README.md\|沒有共同祖先:放行\|找不到共同祖先" tests/test-gate.sh scripts/check-claude-md.sh` → 定位第 340、348、349 行與第 108、165 行
- 複製 check-claude-md.sh 到 /tmp/gA-mut，`sed` 刪除第 165 行警告（grep 確認計數為 0）→ `bash tests/test-gate.sh /tmp/gA-mut/check.sh` → exit 0，90 ✅ / 0 ❌

Not reported
- 已逐條核對、判定成立的部分：`resolve_fork_base` 與兩個呼叫端的 stdout/stderr 分流、`$base` 全域取用（兩處呼叫前都已 `read_base`）、`local` 宣告、警告措辭在 `prefix=""` 時與舊版逐字相同、`owed_dirs` 與 `reviews_missing` 的 range 與退化分支等價、`--segment-base` 確實硬失敗（第 209–216 行）、`set -e` 不存在於 gate，故命令替換的非零退出不會中止腳本。以上皆未發現等價性問題。
- scripts/CLAUDE.md 與 tests/CLAUDE.md 內的變異計數（「3 紅 / 7 紅 / 2 紅」）與「2026-10-07 實測」：我沒有重跑，無法確認，不列為發現。
- 未執行 bash 3.2 相容性實測與 shellcheck：這些是已確認的驗證，且我沒有發現新的 3.2 風險點。
- 外部查證項：無。