Critical 0 / Important 1 / Smells 0 (範圍：快照 `git diff HEAD~1 HEAD` 的 4 檔，重點 `scripts/check-claude-md.sh`)

**[Important]** `tests/test-gate.sh`（diff 第二段 340–349 行）未覆蓋 `reviews_missing` 的「連共同祖先都沒有」警告，這條路徑可以靜默退化。
- 失敗情境：刪掉 `scripts/check-claude-md.sh` 第 165–166 行（`reviews_missing` 的 `echo "⚠️ … 跳過 review 報告檢查"` 兩行）後，測試仍全綠（90 ✅ / 0 ❌）。
- 證據：test-gate.sh 第 340 行 `rm -rf r.js README.md src docs …` 刪掉 `docs/`，第 341 行之後沒有重建，所以 gate 第 151 行 `[ -d docs/reviews ] || return 1` 直接返回，`reviews_missing` 的警告根本不會執行。第 349 行的 `said "找不到共同祖先"` 只會匹配到 `owed_dirs` 印的同句警告。
- 註解第 335–337 行聲稱「兩處都要放行但講出來」，實際只驗了 `owed_dirs` 一側。修法是在第 340 行之後補建 `docs/reviews/` 目錄，再斷言 `said` 警告。

**其他檢查（未發現問題）**
- `resolve_fork_base` 抽出後，`owed_dirs`（第 105–110 行）與 `reviews_missing`（第 162–168 行）的 range 與警告文字與改動前逐項等價；`owed_dirs` 的 `is_ancestor` 分支產生的 range 與舊版相同。
- 警告經 `>&2` 輸出（第 89 行），stdout 只含 sha，`$(...)` 取值不受影響。
- `${prefix}` 有加大括號（第 89 行），符合 scripts/CLAUDE.md 的全形字規則。
- 腳本無 `set -e`，`if ! range_base=$(…)` 寫法正確。

**Not reported**
- `reviews_missing` 第 176 行 `--diff-filter=A` 不計 rename（R）。用 `git mv` 把草稿搬成 `S*.md` 會被擋。舊版 `ACMR` 同樣不計 R，本 diff 沒有引入新的回歸，只是 `--diff-filter=A` 的語意邊界，判為不夠格。
- 第 340 行 `rm -rf … docs` 之後 `git rm` 與 `checkout --orphan` 的組合，未觀察到其他副作用。
- `scripts/CLAUDE.md` 第 25–34 行與 `tests/CLAUDE.md` 第 630–635 行的變異紅數字（3/7/2、12/5/2），我沒有重跑，見下方外部查證項。

**需要外部查證**
- 在 `scripts/CLAUDE.md` 宣稱的三個變異（`--segment-base` 軟退化、`resolve_fork_base` 拿掉 fork-point 整支、退化時不印警告）各跑一次，核對紅數是否為 3 / 7 / 2。`tests/CLAUDE.md` 的 12 / 5 / 2 也同理。這些數字是文件內的快照，我沒有驗證。

**What I ran**
- Read diff.txt 1–300、301–600、601–900、901–1010 → 完整讀完（含 HEAD 整檔版本）
- Read prompts/G2-dhk-4.txt → 派工說明
- `cp` 快照的 `scripts/check-claude-md.sh` 到 mktemp 目錄、`sed -i '' '165,166d'` 刪除 reviews 警告兩行、`bash -n` → SYNTAX_OK
- `bash <snapshot>/tests/test-gate.sh <mutant gate>` → exit 0，pass=90 fail=0（變異未被抓到）