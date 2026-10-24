Critical 0 / Important 3 / Smells 0. 範圍：快照 `git diff HEAD~1 HEAD`（4 檔），重點是 `tests/test-gate.sh` 新增的 ⑩⑪ 情境對 `scripts/check-claude-md.sh` 的鑑別力。

[Important] tests/test-gate.sh:340 ⑪ 的 `rm -rf ... docs` 先刪掉了 docs/reviews，所以 `reviews_missing` 的「連共同祖先都沒有」分支（check-claude-md.sh:162-167）從未執行。
  Failure: `reviews_missing` 在無共同祖先時改成靜默放行或直接擋下，整個測試仍是 90 ✅ / 0 ❌。
  Evidence: 刪掉 check-claude-md.sh:165-166 的警告 → 90 ✅ / 0 ❌；把 :167 的 `return 1` 改成 `return 0` → 90 ✅ / 0 ❌。:349 的 `said "找不到共同祖先"` 其實由 owed_dirs 的警告（check-claude-md.sh:108）滿足。建議在 :339 之後、commit r7 之前補 `mkdir -p docs/reviews`，並改斷言 `"這次跳過 review 報告檢查"`。

[Important] tests/test-gate.sh 沒有任何斷言保證「起點仍是祖先」時不印退化警告。
  Failure: 有人拿掉 `resolve_fork_base` 的 is-ancestor 分支（check-claude-md.sh:84），每次正常 commit 都會印出「段落起點 … 不在目前分支的歷史裡」的假警告，測試仍全綠。
  Evidence: 把 :84 的條件改成 `if false; then` 後 → 90 ✅ / 0 ❌。建議加一則正常路徑的 `pass` 並斷言輸出不含「不在目前分支的歷史裡」。

[Important] scripts/CLAUDE.md:27-29 與 tests/CLAUDE.md:33-35 的變異數字重跑對不上，且沒有寫明計數單位。
  Failure: 照文件重做「永遠 return 1」變異，得到 7 個失敗的 expect（15 行 ❌），既不是文件寫的 12 紅，也不是 12 行。同一份文件的 `--segment-base` 軟退化寫 3 紅，實測是 3 個失敗的 expect（4 行 ❌）；fork-point 拿掉寫 7 紅，實測是 7 行 ❌。計數單位前後不一致。
  Evidence: 見下方 m13、m1、m2 的結果。文件的數字是「實跑」的證據，重跑無法重現，會讓下一個人懷疑整組變異表。

What I ran:
- `git -C <snap> show HEAD~1:scripts/check-claude-md.sh > /tmp/g2rev/old.sh`，`/bin/bash tests/test-gate.sh /tmp/g2rev/old.sh` → 90 ✅ / 0 ❌（改回舊版仍全綠；這次改動是行為不變的重構，所以這是預期結果）
- m1 `--segment-base` 改成 `if read_base; then` → 87 ✅ / 4 ❌（3 個 expect 失敗：:120、:328、:347，外加 1 行 said）
- m2 刪 check-claude-md.sh:88-92（fork-point 整支）→ 87 ✅ / 7 ❌（3 個 expect 失敗）
- m3 刪 :165-166（reviews_missing 警告）→ 90 ✅ / 0 ❌
- m4 `--diff-filter=A` 改 `ACMR` → 89 ✅ / 2 ❌（1 個 expect + 1 行 said）
- m5 刪 :151（opt-in 守門）→ 85 ✅ / 5 ❌（全部是 expect；其中 4 個在舊的 61 項，1 個是 ⑨，與文件 4/5 一致）
- m6 刪 :89（fork-point 警告）→ 90 ✅ / 2 ❌（兩行都是 said，與文件 2 紅一致）
- m7 刪 :108-109（owed_dirs 無共同祖先警告）→ 90 ✅ / 1 ❌（said「找不到共同祖先」）
- m11 `if false` 取代 :84 → 90 ✅ / 0 ❌
- m12 :167 `return 1` 改 `return 0` → 90 ✅ / 0 ❌
- m13 :151 改成無條件 `return 1` → 83 ✅ / 15 ❌（7 個 expect 失敗 + 8 行 said/base_is）
- `sed -n` 逐行核對 check-claude-md.sh 的 88、89、92、108、109、151、165、166、210 行內容，行號與上列對應

Not reported:
- 這次重構讓舊 gate 也 90/0 通過，屬預期：這些情境是政策的特徵測試，不是重構本身的回歸網。
- test-gate.sh:332 的 `said "改從共同祖先"` 也會被 owed_dirs 的警告滿足，但 :333 的 `said "沒有新增任何 docs/reviews/S*.md"` 是 reviews 專屬輸出，所以這不是缺陷。
- 文件中「ACMR → 2 紅」「fork-point 拿掉 → 7 紅」「退化警告拿掉 → 2 紅」「opt-in 行拿掉 → 5 紅（4 在舊項）」都能重現。
- 需要外部查證：無。