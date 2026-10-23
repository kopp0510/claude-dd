Critical 0 / Important 1 / Smells 1 — 範圍：快照 `git diff HEAD~1 HEAD` 中 tests/test-gate.sh「已知的三條繞過路徑」區塊、scripts/CLAUDE.md 的變異表、ctrl ⑦ amend 改動。

[Important] tests/test-gate.sh:320 「繞過①」的放行斷言在段落的第一個 commit 上，這個 commit 無論 pre-commit 查不查報告都會通過，所以它證明不了「pre-commit 不查報告」。
  Failure: 起點 by0 記下後，`commit by1` 時 HEAD == 起點，`reviews_missing` 在 gate 第 162 至 165 行 `[ "$base" = "$head_sha" ] && return 1` 直接放行。把「pre-commit 也查報告」的變異加進去，by1 仍然 pass，這一則不會變紅。
  Evidence: 我在 /tmp/gate-exp.* 做了最小重現（非整支重跑）。變異版：by1（段落第一個 commit）rc=0；by2（第二個、零報告）rc=1。scripts/CLAUDE.md:45 的變異表把這個紅歸給「繞過①」，但實際紅的是 tests/test-gate.sh:328 的「這一段補上報告」那則（by2 的 pass 斷言），表上的歸因與實測不符。
  建議：在 by1 與對照之間再加一個段落內 commit（例如 by1b），把繞過①的斷言放在它上面；再重新確認變異版會在它上面變紅，並修正 scripts/CLAUDE.md:45 的歸因。

[Smells] tests/test-gate.sh:344 註解說「兩個擋點的訊息都有，誰擋都會中」，但 `said "還有 commit 跳過檢查"`（第 351 行）只存在於 `--start-segment` 的欠帳分支（gate 第 195 行），reviews 分支印的是「上一段沒有附 review 報告」，不含這句。註解描述錯誤，斷言本身的鑑別力沒問題。

What I ran
- `git diff`（快照 HEAD~1..HEAD，讀 diff.txt 前 249 行）→ 讀到 8 檔的完整變更
- 讀 scripts/check-claude-md.sh 全檔（1–300 行）→ 確認 `reviews_missing`、`owed_dirs`、各 die 訊息字串
- 讀 tests/test-gate.sh 的 helper（expect/said/base_is）與新區塊 → 逐則推演 by0…by6 的狀態
- grep `繞過|by1|by2|還有 commit 跳過檢查|reviews_missing && exit` → 取得行號
- 最小重現腳本（/tmp/gate-exp.*，`staged=` 後插 `reviews_missing && exit 1`）→ 原版 by1/by2 rc=0/0；變異版 by1 rc=0、by2 rc=1
- 計數推演：新區塊新增 15 個 expect（含 amend 包裝），90+15=105，與已跑的 105 ✅ 一致

Not reported
- 新區塊其餘斷言（繞過②的對照與放行、繞過③ 的 rm/洗帳/對照、said 字串）逐則推演皆正確，未報。
- scripts/CLAUDE.md 變異表的其他列（列 2、3）推演與之相符，但未實跑，不列為發現。
- CHANGELOG、SKILL.md、templates、worktree-manager 等非派工方向的內容未審。
- 未實跑整支 tests/test-gate.sh（依指示不重跑）；變異表的完整紅數屬於需要外部查證的項目，交回主對話：`cp` 快照 gate、套用變異、跑完整 test-gate.sh 看紅的是哪幾則。