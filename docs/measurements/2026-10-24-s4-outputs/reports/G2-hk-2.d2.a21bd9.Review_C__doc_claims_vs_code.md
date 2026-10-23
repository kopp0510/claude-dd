Critical 0 / Important 1 / Smells 0 — 範圍：快照 `git diff HEAD~1 HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）

[Important] scripts/check-claude-md.sh:165-166 — `reviews_missing` 的「連共同祖先都沒有 → 放行但印警告」沒有任何測試覆蓋，而 tests/test-gate.sh:336 的註解與 tests/CLAUDE.md、scripts/CLAUDE.md 的表格都宣稱有覆蓋。
  Failure: 刪掉 165–166 兩行 echo（只留 `return 1`）→ test-gate.sh 仍是 90 ✅ / 0 ❌，靜默放行不會被抓到。
  Evidence: 第 340 行 `rm -rf … docs` 刪掉 docs/reviews，`reviews_missing` 在第 151 行 opt-in 判斷就 `return 1`，走不到 165 行；第 349 行 `said "找不到共同祖先"` 其實是 owed_dirs 的警告（第 108 行）印的，刪掉第 108 行才會變紅（1 紅）。

What I ran
- 在 /var/folders 暫存目錄複製 gate，刪除 check-claude-md.sh:165-166，執行 `/bin/bash tests/test-gate.sh <副本>` → 90 ✅ / 0 ❌（exit 0）
- 同上，刪除 :88-92（resolve_fork_base 的 fork-point 分支）→ 87 ✅ / 7 ❌（與 scripts/CLAUDE.md 宣稱的「7 紅」相符）
- 同上，刪除 :108-109（owed_dirs 的無共同祖先警告）→ 90 ✅ / 1 ❌（`輸出沒提到：找不到共同祖先`）
- 同上，刪除 :89（resolve_fork_base 的「改從共同祖先」警告）→ 90 ✅ / 2 ❌（與宣稱的「2 紅」相符）
- `git status --porcelain`（快照）→ 無輸出，快照未被改動
- 讀 `git show` 所得的 diff 檔：HEAD~1 版的 owed_dirs 與 reviews_missing 已經有同樣的共同祖先退化邏輯（diff 被刪行 106–111 與 83–87）

Not reported
- 「S6 的 review 抓到這兩處已經漂移」：改動前兩處已一致，漂移是 S6 中間版本的狀態，這句是過去式的提案理由，沒有現況錯誤，不報。
- 變異紅數的寫法：紅數本身可重現（7、2），但文件只給計數、沒列出哪些情境變紅，與全域規則的建議格式不完全相同，沒有具體失敗情境，不報。
- 「3 紅」（`--segment-base` 軟退化）：未實作該變異，未驗證。
- 新增文字混用半形 `, : (`（scripts/CLAUDE.md:31–34、check-claude-md.sh:48、72）：純標點，不報。
- 表格格式：表格列都以 `|` 開頭，前後有空行，沒有切斷外層清單，不報。
- `resolve_fork_base` 之後「連共同祖先都沒有」的警告仍是兩處各寫一次，註解的「由結構保證」只涵蓋機制部分，宣稱範圍大致正確，不報。
- `--segment-base` 的實作（check-claude-md.sh:210）與文件表格「起點不是祖先 → 硬失敗」一致，不報。
- 未查的外部項目：無。