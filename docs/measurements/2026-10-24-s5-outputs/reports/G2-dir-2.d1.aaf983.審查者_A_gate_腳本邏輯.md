Critical 0 / Important 1 / Smells 2：審查範圍是快照 `git diff HEAD~1 HEAD`，主力看 `scripts/check-claude-md.sh`，並對照了 `tests/test-gate.sh`。

`scripts/check-claude-md.sh` 本身的重構和舊版行為等價（已讀 diff.txt 第 83–116 行，與整檔第 82–94、105、162 行對照）。兩處警告句接上 prefix 後，和舊字串逐字相同：`""` 接出「），改從共同祖先」，`"review 檢查"` 接出「），review 檢查改從共同祖先」。`local` 和賦值分開寫，所以 `if ! x=$(…)` 和 `elif x=$(…)` 拿到的是函式自己的 exit code。全形字前面有寫成 `${prefix}`。腳本沒開 `set -e`，也沒有新增管線或 `grep -c`。這部分沒有發現。

[Important] <s5>/G2-dir-2/tests/test-gate.sh:340,349 情境 ⑪ 根本沒跑到 `reviews_missing` 的「連共同祖先都沒有」分支，所以 `said "找不到共同祖先"` 守不住它要守的那條迴歸。
  失敗情境：把 gate 第 165–166 行（reviews_missing 的警告）刪掉，等於恢復「第一版靜默放行」，結果整組 test-gate 仍是 90 ✅、0 ❌，exit 0。原因有兩個：第 340 行 `rm -rf … docs …` 把 `docs/reviews` 刪了，`reviews_missing` 在第 151 行的 opt-in 判斷就先 `return 1`；而 `said` 找的字串，被 `owed_dirs` 第 108 行的警告「也找不到共同祖先，這次只檢查 staged」滿足了。
  證據：變異版 m1 跑出 `m1 exit=0`、✅ 90、沒有 ❌。插標記版 m2 在 ⑪ 的輸出是「也找不到共同祖先，這次只檢查 staged」後面接 `DBG_NODIR`，沒有出現 `DBG_NOFORK`。
  連帶問題：tests/CLAUDE.md 寫「連共同祖先都沒有時:兩處放行**但必須印出警告**」，第 336–337 行的註解也宣稱擋住了靜默通過，這兩句現在都不成立。這正好就是 tests/CLAUDE.md ① 自己警告過的「opt-in 目錄不在 → 為了錯的理由而通過」。修法：⑪ 要在 orphan 線上重建 `docs/reviews/`（放 `CLAUDE.md`，不放 `S*.md`），而且 `said` 要改成只有 reviews_missing 會印的字串，例如「這次跳過 review 報告檢查」。

## Smells

- [Smell｜possible Mysterious Name／隱性耦合] <s5>/G2-dir-2/scripts/check-claude-md.sh:72,84,88 `resolve_fork_base` 把 head 當成 `$2` 傳入，卻直接讀全域的 `$base`。檔頭的參數說明只寫了 `$1`、`$2`。
  失敗情境：日後有呼叫端沒先跑 `read_base`，或者先改了 `$base` 才呼叫（例如想拿它解析另一個 sha），函式會靜靜拿錯的起點去算，不會報錯。目前兩個呼叫端都先跑過 `read_base`，所以現在沒有錯。
- [Smell] <s5>/G2-dir-2/tests/test-gate.sh:340 清理清單和實際狀態對不上。`'api server'` 在整份測試裡沒有任何地方建立過（grep 只命中這一行）。前面建的 `my dir`、`功能`、`模組`、`p`、`r`、`w`、`mv`、`keep`、`feat`、`feat2`、`top.js`、`side.txt` 都沒清，會被 `commit()` 的 `git add -A` 一起收進 r7。
  失敗情境：現在能過，是因為這些目錄剛好都有 CLAUDE.md。日後前面的情境只要留下一個沒有 CLAUDE.md 的程式碼目錄，r7 就會因為不相干的理由被擋。

## What I ran
- 讀 diff.txt 第 1–1010 行（分三段）→ 讀完
- `cp gate m1.sh; sed -i '' '165,166d' m1.sh; /bin/bash tests/test-gate.sh m1.sh` → exit 0，✅ 90，沒有 ❌
- 在 m2.sh 的 reviews_missing 插 `DBG_NODIR`、`DBG_NOFORK` 標記，用一份末尾改成印出 `$OUT` 的測試副本跑 → ⑪ 的輸出是 owed_dirs 的「也找不到共同祖先」加上 `DBG_NODIR`，沒有 `DBG_NOFORK`
- Grep `api server|找不到共同祖先`（tests/、scripts/）→ `'api server'` 只出現在 test-gate.sh:340；「找不到共同祖先」出現在 check-claude-md.sh:108 和 :165 兩處，test-gate.sh:349 是斷言本身

Not reported：沒有逐一重驗 scripts/CLAUDE.md 寫的變異紅數（3、7、2）；read_base 接受任意 tree 物件是既有行為，不在這次 diff 裡；沒有重跑呼叫者已經跑過的 test-gate、test-install、shellcheck、`bash -n`。實驗目錄留在 `/tmp/revA.DVYk`，沒有刪。