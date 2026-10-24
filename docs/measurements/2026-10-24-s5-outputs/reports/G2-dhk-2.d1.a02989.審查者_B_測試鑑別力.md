Important 1 / Critical 0 / Smells 0 — 審查範圍為 `git diff HEAD~1 HEAD` 的 4 個檔（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）。

**Findings**

[Important] tests/test-gate.sh:338-349 ⑪ 的「連共同祖先都沒有」情境只驗到 `owed_dirs` 的警告，沒有驗 `reviews_missing` 的警告；註解宣稱「兩處都要放行但講出來」，實際未成立。
- 證據：第 340 行 `rm -rf r.js README.md src docs 'api server'` 把 `docs/` 整個刪掉，所以到第 348 行的 `--start-segment` 時 `docs/reviews` 不存在，`reviews_missing` 在 check-claude-md.sh:151 的 `[ -d docs/reviews ] || return 1` 就返回，根本進不到 `resolve_fork_base`。第 349 行的 `said "找不到共同祖先"` 只能被 `owed_dirs` 的警告（「也找不到共同祖先」）滿足。變異實驗：把 check-claude-md.sh:165 那行 `echo "⚠️ 段落起點 $base 找不到共同祖先，**這次跳過 review 報告檢查**" >&2` 改成 `:`，測試仍是 90 ✅ / 0 ❌、exit 0。
- 失敗情境：有人把 `reviews_missing` 的「放行但要講出來」改成靜默放行（也就是 S6 review 抓過的那個繞過路徑），`test-gate.sh` 全綠，回歸測試抓不到。
- 建議：⑪ 在 `docs/reviews/` 存在的狀態下另跑一次 `--start-segment`（例如在 orphan 線上重建 `docs/reviews/CLAUDE.md`），並斷言 review 專屬的那句「跳過 review 報告檢查」。

**Not reported**
- ⑩ 的 `reviews_missing` 退到共同祖先、`--segment-base` 硬失敗、起點不是祖先的斷言，我逐條讀過，`said` 的字串都是各自函式獨有的（「改從共同祖先」+「沒有新增任何 docs/reviews/S*.md」、「沒有可用的段落起點」），沒有發現空通過。
- `resolve_fork_base` 抽取後 `owed_dirs` 與 `reviews_missing` 的行為與舊版一致，未發現問題。
- scripts/CLAUDE.md 與 tests/CLAUDE.md 寫的變異紅數（3 紅、7 紅、2 紅、12 紅、5 紅等）我沒有重跑，只能確認不是我這次驗的部分。這屬於既有文件的數字，不算本次發現。
- 沒有發現 `resolve_fork_base` 的 `local` 或 stdout/stderr 分流問題（警告走 stderr，`$(...)` 只取 stdout）。

**需要外部查證**
- 無。

**What I ran**
- 讀取 diff 檔全部 1010 行（分 4 次 Read）→ 完整讀過 4 個被改檔的整檔內容
- 把 check-claude-md.sh:165 的 `echo` 換成 `:`（副本放 /tmp，快照未動）後執行 `/bin/bash tests/test-gate.sh <副本>` → exit 0，90 ✅ / 0 ❌，仍全綠（即上方 Important 的證據）
- 清掉 /tmp 副本目錄 → 完成