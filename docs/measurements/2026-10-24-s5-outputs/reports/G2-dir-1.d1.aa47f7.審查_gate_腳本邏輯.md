Critical 1 / Important 1 / Smells 0。範圍是快照的 `git diff HEAD~1 HEAD`,共 4 個檔:`scripts/check-claude-md.sh`、`scripts/CLAUDE.md`、`tests/test-gate.sh`、`tests/CLAUDE.md`。

[Critical] `tests/test-gate.sh:340`(diff 檔第 997 行)情境 ⑪ 執行 `rm -rf ... docs`,刪掉了 `docs/reviews/`。所以 `reviews_missing` 在 `[ -d docs/reviews ] || return 1`(gate 第 151 行)就直接 return 了,「連共同祖先都沒有」那個分支(gate 第 162–167 行)從來沒被執行。
  失敗情境:把那個分支的警告刪掉(m1),或把放行改成擋(m2),兩種都是 90 ✅ / 0 ❌。測試第 349 行的 `said "找不到共同祖先"` 其實是被 `owed_dirs` 印的「也找不到共同祖先，這次只檢查 staged」(gate 第 108 行)滿足的。結果「兩處放行但必須印警告」這個宣稱,有一半沒有任何斷言在守。這正好是 `tests/CLAUDE.md` 新增段落的坑 ①:「切到不含它的分支就整個檢查不啟用,測試會『為了錯的理由而通過』」。
  證據:diff 檔第 997 行 `rm -rf r.js README.md src docs 'api server'`。變異結果見下方「What I ran」的 m1、m2。
  修法:在 orphan 線上重建 `docs/reviews/`(放 `CLAUDE.md` 就好),並把斷言改成只有 `reviews_missing` 才會印的句子 `"這次跳過 review 報告檢查"`。

[Important] 這次新寫的文件把上面那個未經驗證的行為寫成「已測試」:
- `tests/CLAUDE.md:11`(diff 檔第 610 行)寫「連共同祖先都沒有時:兩處放行**但必須印出警告**」。
- `scripts/CLAUDE.md:49` 那張表把 `reviews_missing` 標成「放行，但印警告」,而第 59–62 行的變異清單暗示三處都有測試把關。
  失敗情境:之後有人改壞 `reviews_missing` 的無祖先分支,不論是改成靜默放行(正是 S6 抓過的那條繞過路徑),還是改成擋,CI 都全綠,而文件還在告訴讀者這裡有測試。
  另外,情境 ⑩ 的 `said "改從共同祖先"`(測試第 332 行)同樣分不出是誰印的:`owed_dirs` 透過 `resolve_fork_base ""` 也會印這句。所以它證明不了 `reviews_missing` 有退化。
  證據:m1、m2 都 0 紅。gate 第 105 行 `resolve_fork_base "" "$head"` 用的是同一句警告。

What I ran
- 讀完 diff 檔第 1–1010 行(4 段,每段 300 行)→ 已讀到第 1010 行
- 在 mktemp 拋棄式目錄做 m1:刪掉 gate 第 165–166 行(`reviews_missing` 無祖先的警告),跑 `/bin/bash tests/test-gate.sh` → exit 0,90 ✅ / 0 ❌
- m2:gate 第 167 行 `return 1` 改成 `return 0`(無祖先時改成擋)→ exit 0,90 ✅ / 0 ❌
- m3:刪掉 gate 第 89 行(`resolve_fork_base` 的警告)→ exit 1,2 ❌(「不在目前分支的歷史裡」「改從共同祖先」),和文件寫的「2 紅」一致
- m4:gate 第 210 行改成 `if read_base; then` → exit 1,4 ❌。這和文件寫的「軟退化 → 3 紅」不是同一個變異,不拿來比

Not reported:
- 重構本身:兩處警告的措辭逐字等價;stderr 不會被 `$(...)` 吃掉;`local a=$1 b=$2 c` 在 bash 3.2 可以用;`$base` 一律在 `read_base` 之後才用。這些都看過,沒有問題。
- 既有問題:`scripts/CLAUDE.md:22` 的「前 61 項」已經過期,和 `tests/CLAUDE.md` 自己的「不要寫 N 項」衝突,但不在這次 diff 裡。
- 情境 ⑪ 的 `rm` 清單裡有從來沒建過的 `'api server'`,而 `功能/`、`模組/`、`p/` 等目錄留著、被 `git add -A` 帶進 orphan commit。目前無害,所以不報。