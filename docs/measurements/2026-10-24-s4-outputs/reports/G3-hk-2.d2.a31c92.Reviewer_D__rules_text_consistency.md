Critical 0 / Important 1 / Smells 0 — 範圍：快照 `git diff HEAD~1 HEAD` 的 8 個檔案，側重規則文字的正確性與一致性

[Important] templates/global/CLAUDE.md:193-195 新增的「假紅」規則只定義了修 bug 時「應該紅成什麼」，新功能時的判準沒有寫。
  Failure: 新功能的測試第一次跑出現 ImportError，讀這條規則的人無法判斷它是假紅還是正確的紅，可能直接實作而沒看過斷言失敗。
  Evidence: diff 檔 142-144 行只寫「修 bug 時就是那個錯的值」；`grep -n '新功能\|找不到這個函式\|空殼' templates/global/CLAUDE.md` 只命中 408 行（非 §3.5）；verification-gate/SKILL.md:57-59 也只對應修 bug。建議在 §3.5 補一句新功能的判準（應紅在斷言，不是 import/NameError）。外部查證：若部署的 ~/.claude/CLAUDE.md 含「先放一個回錯值的空殼」而模板沒有，模板與部署版已漂移，需用 diff 比對（不在本次範圍內）。

What I ran
- Read diff.txt 1–544（前段 git diff 全部與 CHANGELOG.md 整檔）→ 範圍內前段完整、CHANGELOG 未發布區塊位於 1.6.4 之前，格式與既有區塊一致
- grep `先寫失敗案例|假紅|不等於固定版|鑑別力測試|新功能還沒寫` → 模板 193/195/364 與 verification-gate 9/57 的文字互相一致；§3.9 的「不等於固定版的輸出就算紅」轉述忠實，未發現矛盾
- grep `§3\.5`、`確認會失敗` 於快照 → 命中 CHANGELOG、模板、verification-gate、task-planner 83 行；無其他文件重述舊句，dd-init 蓋章區塊與 README 未引用 §3.5，不需同批同步
- awk/sed 檢視根 CLAUDE.md 336–348 → 新段落在 blockquote 與表格之間，表格 339–347 全為 `|` 開頭，表格未被切斷
- grep `pstack` 於快照 → 歸屬見 verification-gate/SKILL.md:9 與 CHANGELOG 26/28/39
- 核對 worktree-manager/SKILL.md 收尾步驟引用：「步驟 4 複製的 .env」「步驟 6 寫的 WORKTREE_INFO.md」與實際步驟編號一致

Not reported
- 外部查證（未做）：pstack-claude 的授權是否允許借概念（根 CLAUDE.md「只借概念、不抄檔案時授權仍要處理」）。verification-gate 在檔內有歸屬，worktree-manager 的收尾流程只在 CHANGELOG 標出歸屬；需查 pstack-claude 的 LICENSE 才能定案。
- 外部查證（未做）：CHANGELOG 與 worktree-manager 宣稱的「git 2.42.0 與 2.54.0 實測」，需安裝 2.54.0 才能確認，本次未執行。
- 未審範圍：diff.txt 2025 行以後的整檔內容未逐頁讀，tests/test-gate.sh 與 scripts/CLAUDE.md 的變異表不在我的方向，由其他審查者負責。
- 無 Fowler smell 檢查：diff 是規則文字與測試說明，沒有新增程式結構。