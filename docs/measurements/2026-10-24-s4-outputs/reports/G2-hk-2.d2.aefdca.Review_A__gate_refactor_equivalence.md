**Critical 0 / Important 0 / Smells 0**: scripts/check-claude-md.sh 重構（`resolve_fork_base`）行為等價，未發現可報的問題。範圍：快照 `git diff HEAD~1 HEAD` 的 4 個檔。

Not reported:
- `resolve_fork_base` 依賴全域 `$base`。呼叫端都在 `read_base` 成功之後（`owed_dirs` 由 line 136/231 呼叫，`reviews_missing` 由 line 57 保證），沒有漏宣告；`range_base` 改為 local 後全檔無其他讀取點。
- 三處警告句：兩個呼叫端的字串已逐字比對，去掉 `${prefix}` 後與改動前完全相同（owed 與 review 兩句都是 145 bytes，字串相等）。
- stdout/stderr：警告都走 `>&2`，函式 stdout 只有起點 sha，`$(...)` 不會吞進不該進的東西。原本印到終端的警告仍在終端。
- 腳本沒有 `set -e`，`if ! x=$(f)` 與 `elif x=$(f)` 的分支語意與改動前一致。
- `--segment-base`（line 210）保留獨立的 `merge-base --is-ancestor` 且不退化，與 scripts/CLAUDE.md 的三處表格相符。第四處 `is-ancestor` 不存在。
- 既有行為、非本次引入：`base` 是 `HEAD` 的後代時，fork-point 會回 `head`，範圍變成空。改動前後相同，不算回歸。
- `prefix` 這個參數名不準（實際插在句中），屬命名問題，沒有具體失敗情境，不報。
- scripts/CLAUDE.md 與 test-gate.sh 註解裡的歷史變異數字（3 紅 / 7 紅 / 2 紅）與 S6 review 的「已漂移」敘述，我沒有重跑，也沒有查證。需要的話可跑 `bash tests/test-gate.sh <變異版 gate>` 比對。

What I ran:
- `awk` 擷取 diff 檔 check-claude-md.sh 段落、tests 段落 → 讀到 `resolve_fork_base` 與兩個呼叫端的改動、test-gate 新增的 ⑩⑪ 情境
- `grep -n 'merge-base\|range\|fork'` 於快照與 `HEAD~1` 版本 → 找到所有 merge-base 呼叫點（owed_dirs、reviews_missing、--segment-base、line 210）與 `range_base` 的使用點
- `grep -n 'set -'` 於兩個版本 → 無輸出，腳本未開 `set -e`
- `sed -n` 讀取 check-claude-md.sh 的 owed_dirs / reviews_missing / --segment-base 段落 → 行為邏輯與註解一致
- 字串 grep 擷取 + sed 替換 `${prefix}` 後比對 owed 與 review 兩句警告 → 兩句皆 SAME，145 bytes