# S1-b — error-capture 大輸出效能 + hook 逾時

## 派工

- 範圍：`git diff 93dd5b7 608caa9`（6 檔），一律 `git show 608caa9:<路徑>` 取檔（與 code-simplifier 並行）
- 已給、標明不要重跑的驗證：新測試 × 新 hook 兩種 locale 30/30；新測試 × 舊 hook 兩種 locale 只有 4 個大輸出情境逾時失敗；
  長度提早退出的變異只讓 2 個「最後一行才是錯誤」失敗；docker bash:5.3 跑舊 hook 30/30；shellcheck 乾淨
- 重點：新舊空白判斷語意差異、perl/alarm 包裝誤報或卡住、註解/文件的假宣稱、diff 改變的事實在別處是否還被宣稱；最多一次重現實驗
- a、b 兩份 prompt 相同

## 發現

- [Important] `skills/gate-guard/hooks/hooks.json` 沒有 `timeout`，但 CHANGELOG／CLAUDE.md 宣稱「使用者要求所有 hook 都有逾時」—— 只做了一半
- [Minor] 註解「約 16KB」實際約 22KB（**兩份獨立都抓到**）
- 已驗無問題：新舊空白判斷在合法輸入上等價；錯誤字夾不合法位元組仍命中；perl exec 失敗回 127 不會誤判為逾時；第 2 輪 PATH 不影響 perl／env
- 盲點（推論、未驗）：慢點若在會繼承 stdout 的子行程，alarm 砍主程序後 `$(...)` 仍會等

## 處置

- gate-guard 的 `hooks.json` 補 `"timeout": 30`，同步該層 `CLAUDE.md` 與 CHANGELOG（改成「兩份 hooks.json」）；`validate_skill_hooks` 通過、`test-guard-no-verify.sh` 99 個全過
- 16KB 同 a
- 子行程盲點：現行慢點在主 shell，不處理，記錄於此

- code-simplifier：無改動（認為已夠簡潔）
