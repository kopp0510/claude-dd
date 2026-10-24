Critical 0 / Important 4 / Smells 0. Range: `HEAD~1..HEAD` of scripts/CLAUDE.md, scripts/check-claude-md.sh, tests/CLAUDE.md, tests/test-gate.sh.

**Findings**

1. **[Important]** scripts/CLAUDE.md:34 | 寫的報告比對樣式是 `(^|/)S[^/]*\.md$`，HEAD 實際是 `S[0-9]`。
   - 證據: scripts/check-claude-md.sh:176 為 `grep -qE '(^|/)S[0-9][^/]*\.md$'`；同檔 :173 註解寫「`S[0-9]` 不是 `S[^/]*`」；templates/global/CLAUDE.md:301 也寫 `S[0-9]`。
   - 失敗情境: 照這份文件的樣式核對報告，`docs/reviews/SUMMARY.md` 會被算成報告，和 tests/test-gate.sh ⑧（SUMMARY.md 不算報告）的結論相反。
   - 建議: 文件改成 `S[0-9]`。

2. **[Important]** tests/test-gate.sh:338-349 | 「連共同祖先都沒有時，`reviews_missing` 也要印警告」沒有被測到。
   - 證據: ⑪ 用 `rm -rf … docs` 刪掉 docs/，而 scripts/check-claude-md.sh:151 `[ -d docs/reviews ] || return 1` 會先返回，走不到 :162–165。第 349 行的 `said "找不到共同祖先"` 比到的是 owed_dirs 的訊息（:108）。變異 M1（把 :165 的警告改成 `:`）跑出 90 ✅ / 0 ❌。
   - 失敗情境: reviews_missing 的「放行但不講」回歸（S6 抓過的那種）全綠通過。tests/CLAUDE.md:11 與 scripts/CLAUDE.md:44–50 宣稱「兩處都斷言警告」，這不成立。
   - 建議: 在 docs/reviews 存在、且無共同祖先的 repo 裡再斷言 `said` 該句。

3. **[Important]** scripts/CLAUDE.md:27 與 tests/CLAUDE.md:33 | 「永遠 `return 1`」變異寫 12 紅，目前實測 15 紅。
   - 證據: 變異 M6 跑出 83 ✅ / 15 ❌，15 條全部落在 ⑨ 之後的新區塊。
   - 失敗情境: 照文件重跑會得到 15，讀者無法判斷是測試被改壞還是文件過期。§3.10 要求列舉而不寫數字，這裡的數字已經不符。
   - 建議: 刪掉數字，改寫產生指令，或更新為 15。

4. **[Important]** tests/test-gate.sh:273–276 | ⑦ 的標題與註解寫「起點 commit 被改寫」，但同檔 :283–285 說那不是 ⑦ 測的。
   - 證據: test-gate.sh:273 `# ⑦ **起點 commit 被改寫(amend / rebase)之後…**`；:284–285 `上面那句註解原本寫「起點 commit 被改寫」，名稱與實際不符`。另外檔內還有一個 `# 7.`（:111，起點不在分支歷史內），兩個「7」並存。
   - 失敗情境: 讀者依 ⑦ 的標題以為 amend 起點已有測試，可能誤判 ⑩ 的 sideline 設定可以刪。
   - 建議: 改標題與註解，去掉與 `# 7.` 的編號衝突。

**Not reported**

- 「四份文件」（check-claude-md.sh:170）與「五份文件」（test-gate.sh:264、scripts/CLAUDE.md:30）計數不一致。沒有可證明的失敗情境，§3.10 要的是刪數字。
- 變異 M2（把 `--segment-base` 的 is-ancestor 換成 `true`）得 4 紅，文件寫 3 紅。我不知道文件「軟退化」的確切寫法，不下結論。
- scripts/CLAUDE.md:13–14 移除了「起點被改寫時改從共同祖先算」一句，但表格（:46–50）與程式仍有該政策，不算矛盾。
- `reviews_missing` 的檢查是兩個 tree 之間的 diff，不是逐 commit 的新增。範圍內新增後又刪掉的報告會被擋，屬於保守方向，不報。
- 兩份 CLAUDE.md 重複同一張變異表（數字重複，已由第 3 點涵蓋）。
- 既有問題：CHANGELOG 與 UPGRADING 的歷史敘述，不在範圍內。

**需要外部查證**

無。

**What I ran**

- `git -C <snap> grep -nF -e 'S[^/]*\.md' -e 'S[0-9]' -e '四份' -e '五份' -e '份文件'` → 命中 scripts/CLAUDE.md:34（`S[^/]*`），check-claude-md.sh:176 與 templates/global/CLAUDE.md:301 為 `S[0-9]`；「四份」在 check:170，「五份」在 test-gate:264 與 scripts/CLAUDE.md:30。
- `git -C <snap> grep -n -e '共同祖先' -e 'segment-base' -e 'reviews_missing' -e 'resolve_fork_base'` → 只有 scripts/tests/templates 與歷史文件的既有敘述，沒有新的過期命中。
- `git -C <snap> grep -n -e '起點 commit 被改寫' -e '名稱與實際不符' -e '⑦'` → test-gate.sh:273、:284–285。
- 變異 M1–M6，在 mktemp 副本中以 python 精確替換（每個目標字串須恰好命中 1 次才寫入），各跑 `bash tests/test-gate.sh <變異副本>`：
  - M1 reviews_missing 警告改 `:` → 90 ✅ / 0 ❌，exit 0。
  - M2 `--segment-base` 的 is-ancestor 改 `true` → 87 ✅ / 4 ❌。
  - M3 resolve_fork_base 的 fork-point 整支拿掉 → 87 ✅ / 7 ❌。
  - M4 resolve_fork_base 的警告改 `:` → 90 ✅ / 2 ❌。
  - M5 拿掉 `[ -d docs/reviews ] || return 1` → 85 ✅ / 5 ❌，其中 4 條在前 61 項（:112、:135、:140、:155），1 條在新區塊（:298）。
  - M6 該守門改 `return 1` → 83 ✅ / 15 ❌，全部在新區塊。
- 未重跑 baseline（沿用 90/0）；未重跑 shellcheck 與 `bash -n`（已確認）。