Critical 0 / Important 2 / Smells 0。審查範圍：快照的 `git diff HEAD~1 HEAD`，共 4 個檔。

`resolve_fork_base` 這次重構本身沒找到錯。逐項比對結果如下：

- **警告字句**：兩處跟改動前逐字相同。`owed_dirs` 傳空字串，得到「，改從共同祖先」；`reviews_missing` 傳 `review 檢查`，得到「，review 檢查改從共同祖先」。
- **stderr**：在 `$(...)` 裡照樣流到呼叫端的 stderr，跟改動前一樣。
- **exit code 分支**：分支結構沒變，指令還是 `merge-base --is-ancestor` → `merge-base`。
- **bash 3.2**：沒用到 3.2 不支援的語法。
- **變數作用域**：`range_base` 從全域改成 local，這是附帶的修正，`grep` 確認沒有其他地方讀它。

兩條發現都在新加的測試和文件上：

**[Important] diff.txt:185-199（tests/test-gate.sh 情境 ⑪）「連共同祖先都沒有：放行但要講出來」這則測試根本沒跑到 `reviews_missing`。**
- 證據：diff.txt:190 的 `rm -rf r.js README.md src docs ...` 把 `docs/` 刪了。所以 `reviews_missing` 第一行 `[ -d docs/reviews ] || return 1` 就提早返回，碰不到 `resolve_fork_base`。這正是 tests/CLAUDE.md 這次新寫的地雷①（opt-in 目錄不在，測試為了錯的理由通過）。
- 為什麼還會過：`said "找不到共同祖先"` 吃到的是 `owed_dirs` 印的「也找不到共同祖先，這次只檢查 staged」，不是 review 那句。
- 實跑：把 `reviews_missing` 那兩行警告刪掉（變異 m1），就是註解裡說要防的「第一版靜默通過」，結果 90 ✅ / 0 ❌，沒被抓到。
- 建議改法：在 orphan 線上重建 `docs/reviews/CLAUDE.md`，斷言改成 `said "這次跳過 review 報告檢查"`。

**[Important] diff.txt:181-183（情境 ⑩）`said "改從共同祖先"` 抓不到 `reviews_missing` 自己的退化警告。**
- 原因：`--start-segment` 會先跑 `owed_dirs`，它也印「…，改從共同祖先 … 算起」。
- 實跑：只把 `reviews_missing` 那次呼叫的 stderr 導到 `2>/dev/null`（變異 m2），結果 90 ✅ / 0 ❌。
- 連帶影響：scripts/CLAUDE.md（diff.txt:34）寫的「退化時不印警告 → 2 紅（落在 `said` 斷言上）」只證明 `owed_dirs` 的警告有被斷言，`reviews_missing` 那一側沒證明。那裡也只記了紅數，沒記「哪個變異 → 哪幾個情境變紅」，違反全域 §3.9 的規則。
- 建議改法：斷言改成 `said "review 檢查改從共同祖先"`。修完要更新這段文件，把三組變異分別讓哪幾則變紅重新跑一次、寫進去。

What I ran
- `git show HEAD~1:scripts/check-claude-md.sh | grep -n 'fork|merge-base|...'` → 改動前兩處的警告字句與分支，用來逐字比對
- `sed`/`grep` 讀 HEAD 版 scripts/check-claude-md.sh 的 1-30、140-235 行，以及 `range_base|range|fork|eff|prefix` → 確認作用域，`range_base` 沒有全域讀者
- `sed -n 1,80p tests/test-gate.sh` → 確認 `said` 用 `grep -F` 比對整份輸出（stdout+stderr）
- 在 mktemp 拋棄式目錄做兩個變異，跑 `bash tests/test-gate.sh <變異 gate>`：m1（刪 `reviews_missing` 無共同祖先的兩行警告）→ 90 ✅ / 0 ❌；m2（`resolve_fork_base "review 檢查"` 加 `2>/dev/null`）→ 90 ✅ / 0 ❌。暫存目錄 /var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.hTxSzhBY8V 沒有刪，按 §4.2 刪檔要先問

Not reported
- 文件裡「fork-point 拿掉 → 7 紅」「`--segment-base` 軟退化 → 3 紅」兩組數字沒有重跑核對，要核對就跑 `bash tests/test-gate.sh <對應變異>`。
- `git merge-base` 在多個共同祖先時只取一個，這是改動前就有的行為，沒有變。