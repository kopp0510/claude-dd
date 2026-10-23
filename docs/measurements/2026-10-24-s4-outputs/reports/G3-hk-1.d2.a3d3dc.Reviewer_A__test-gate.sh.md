Critical 0 / Important 1 / Smells 1 — 審查範圍：快照 `git diff HEAD~1 HEAD` 中 tests/test-gate.sh 的「已知的三條繞過路徑」區塊（第 303–356 行）與 amend 情境（第 287、294 行），並對照 scripts/check-claude-md.sh 實際程式碼。

[Important] scripts/CLAUDE.md 的變異表「`--start-segment` 沒有起點檔從空樹記起」那一列，描述的改法實際上會同時改到 SKIP 分支。
  Failure: 照那列的寫法套用，`head_or_empty > "$BASE_FILE"` 這個文字在檔案裡出現 2 次（`--start-segment` 分支與 SKIP 自動記起點分支，check-claude-md.sh:215 與 :232），sed 兩處都改，結果多紅一則（test-gate 輸出第 20 行的 base_is），與文件寫的「只有繞過③一則變紅」不符。
  Evidence: `sed 's/^        head_or_empty > "$BASE_FILE"$/…/' … | grep -c 'else echo "$EMPTY_TREE"'` 回 2；實跑 /tmp/gA-mut/mut2.sh 得 ❌ 共 2 處（起點檢查 1 + 繞過③ 1），✅ 84 → 104 之外的紅數與文件不同。
  文件應寫清楚要改的是哪一行（用行號或 `--start-segment` 分支的上下文），不要只寫一段會匹配兩處的文字。

[Smells] tests/test-gate.sh:344 的註解說「`said` 挑的『還有 commit 跳過檢查』兩個擋點的訊息都有」，實際只有 --start-segment 那一處會印。
  Evidence: check-claude-md.sh:195 含「還有 commit 跳過檢查、…」；pre-commit 的訊息（:257 與 :293）是「段落起點之後有 commit 跳過檢查改了這裡的程式碼」與「起點以來跳過檢查的 commit」，不含「還有 commit 跳過檢查」。
  斷言本身沒有問題（它只在 --start-segment 的輸出上執行），但註解會誤導以後改測試的人。

What I ran
- 建 /tmp/gA-mut/check-claude-md.sh（在 `staged=` 那行後插 `reviews_missing && { echo MUTANT-PRECOMMIT-REVIEW; exit 1; }`），`bash tests/test-gate.sh /tmp/gA-mut/check-claude-md.sh`（快照的 tests/test-gate.sh）→ exit 1，❌ 共 84 ✅、其中 ❌ 含「繞過①:段落內零報告的正常 commit 放行」（第 143 行），與 scripts/CLAUDE.md 變異表那列「繞過①變紅」相符。
- 建 /tmp/gA-mut/mut2.sh（sed 把 `head_or_empty > "$BASE_FILE"` 改成空樹分支）→ `bash tests/test-gate.sh /tmp/gA-mut/mut2.sh` → exit 1，❌ 2 處（見上面 Important）。
- 人工逐則對照 test-gate.sh 第 317–356 行與 check-claude-md.sh 的 owed_dirs / reviews_missing / --start-segment / --segment-base 程式碼：繞過①②③ 的各組對照（by1 / by2–by3 / rm 前後的 by4–by5）的預期值與理由都與程式碼路徑一致，沒有發現「因為別的擋點而通過」的斷言。

Not reported
- 繞過② 的 pass 斷言（第 337 行）與 by3 的 pass：我沒找到會因錯理由通過的地方；未另做 bypass② 的變異（文件已說明沒有 gate 端修法）。
- 狀態洩漏：區塊內每則 `--start-segment` 通過都會覆寫起點，已逐則確認 base_is 位置在覆寫之前（第 315、332、336、375 行附近），後面的 ⑨ 與 ⑩ 不受影響。
- amend（第 287 行）與 expect 包裝：符合 tests/CLAUDE.md 的 set -e 規則，沒有發現問題。
- 以上都不是本次改動引入的既有問題，未列為 finding。
- 沒有跑 bash 3.2 或 docker 版；這兩項已由送審者的驗證輸出覆蓋，不在我的範圍。