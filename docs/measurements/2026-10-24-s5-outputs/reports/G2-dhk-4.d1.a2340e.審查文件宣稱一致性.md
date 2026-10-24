Critical 0 / Important 3 / Smells 0 — 快照 `HEAD~1..HEAD`，4 檔：scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh

[Important] scripts/CLAUDE.md:34 文件寫的比對樣式已過期，與程式碼矛盾。
  Failure: 照文件把比對改回 `(^|/)S[^/]*\.md$`，`docs/reviews/SUMMARY.md` 會被當成報告，正是 test-gate.sh ⑧ 要擋的情況。
  Evidence: scripts/CLAUDE.md:34 寫 `(^|/)S[^/]*\.md$`；check-claude-md.sh:176 實際是 `(^|/)S[0-9][^/]*\.md$`；check-claude-md.sh:173 註解明說 `S[^/]*` 會讓 SUMMARY.md 算報告。

[Important] 同一次改動對「文件數」的宣稱互相矛盾。
  Failure: 讀者依 gate 註解只找到 4 份文件，依 scripts/CLAUDE.md 與測試註解卻應該有 5 份，無法判斷哪個正確。
  Evidence: check-claude-md.sh:170「gate 自己的訊息與四份文件都寫」；scripts/CLAUDE.md:30「與五份文件都寫」；test-gate.sh:264「與五份文件都寫」。另 tests/CLAUDE.md 與 CLAUDE.md 規則本身也不建議寫數字。

[Important] 多處引用「S6 / S4 的 review 抓到 / 預言過」的報告在快照裡不存在，無法核對。
  Failure: 這些句子把設計決定歸功於某份 review。讀者找不到依據，只能照信任走；若報告根本沒進版控，這些宣稱也無從驗證。
  Evidence: `ls docs/reviews` 只有 CLAUDE.md；`git grep` 找不到任何 S4/S6 報告檔。引用處：scripts/CLAUDE.md:55、:58；check-claude-md.sh:78、:80；test-gate.sh:337。

What I ran
- Read diff.txt 1–1010 行（分段讀完）→ 讀完全部內容
- `git show HEAD~1:tests/test-gate.sh | grep -c '^expect '` → 81
- `git show HEAD:tests/test-gate.sh | grep -c '^expect '` → 90（與已確認的 90 ✅ 相符，且 +9 即 S4 區塊的 9 個 expect）
- `git show HEAD:tests/test-gate.sh | sed -n '222,299p' | grep -c '^expect '` → 20；81−20=61，與 tests/CLAUDE.md:45、scripts/CLAUDE.md:22 的「前 61 項」相符
- `git grep 'S\[^/\]'`、`git grep 'S\[0-9\]'` → 見 finding 1
- `git grep '份文件'`、`git grep 'docs/reviews'`（排除 scripts/tests）→ 見 finding 2；其他文件沒有與 fallback 政策矛盾的句子
- `git grep '預言\|已經漂移\|抓到這兩處'`、`git grep 'S6'`、`ls -R docs/reviews` → 見 finding 3
- `git grep '共同祖先\|不在目前分支\|segment-base\|只檢查 staged\|跳過 review\|放行'`（templates、commands、skills、README、CLAUDE.md 等）→ 沒有過期的政策描述
- 讀 check-claude-md.sh 的 `resolve_fork_base`、`owed_dirs`、`reviews_missing`、`--segment-base`，與 scripts/CLAUDE.md 的三處退化表逐格核對 → 一致（owed_dirs 放行＋警告、reviews_missing 放行＋警告、--segment-base 硬失敗）

Not reported
- 變異測試數字（scripts/CLAUDE.md:27–34、:60–62；tests/CLAUDE.md:31–35 的 12/5/2/7/3/2 紅）未驗證，需外部查證，見下
- test-gate.sh 的 ⑩⑪ 區塊與 resolve_fork_base 的邏輯讀起來沒有缺陷，未列為發現
- `$base` 在 resolve_fork_base 中的使用由呼叫端先 read_base，符合現況，未列為發現

需要外部查證（未執行）
- `bash tests/test-gate.sh <改壞的 gate 副本>`，分別驗 scripts/CLAUDE.md 列的三組變異（`--segment-base` 軟退化 → 3 紅；fork-point 拿掉 → 7 紅；不印警告 → 2 紅）以及 tests/CLAUDE.md 的三組（12 / 5 / 2 紅）是否屬實
- 在其他 branch 或 commit 裡找 S4/S6 的 review 報告，確認 finding 3 引用的內容是否真的存在