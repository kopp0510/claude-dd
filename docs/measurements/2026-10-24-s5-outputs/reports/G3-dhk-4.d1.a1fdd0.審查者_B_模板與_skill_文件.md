Critical 0 / Important 1 / Smells 0. 範圍是快照 `git diff HEAD~1 HEAD` 的 8 檔，重點看 templates/global/CLAUDE.md、verification-gate、worktree-manager。

[Important] templates/global/CLAUDE.md:193-196（diff 檔 1894-1896）與 :364-367（diff 檔 2065-2068）
§3.5 新增的括號寫「判定變異版有沒有被抓到仍照 §3.9…不等於固定版的輸出就算紅」，§3.9 的「寫法」也只說「不等於就算紅」，沒有寫明「不等於」必須來自被測物給了錯的結果。同一個 bullet 上一句卻明說 import 錯、拼錯字、資料沒建好的紅不算。
Failure: 變異版讓 gate 或測試載入失敗、全部變紅，照 §3.9 的寫法會被判成「抓到了」，而這正是 §3.5 同一段要排除的假紅。
Evidence: 讀 diff 檔 1894-1896 與 2065-2068，兩段文字互相矛盾；舊版 §3.9 也沒有這個限定（HEAD~1 同段相同）。
建議：§3.9 的「寫法」補上「不等於要來自被測物給了錯的結果，載入失敗不算」。

[需外部查證，未報]
- CLAUDE.md（根目錄）diff 檔 43-47 與 CHANGELOG 未發布（diff 檔 14-30）：pstack-claude 的 SessionStart hook 注入 `<EXTREMELY_IMPORTANT>`、觸發的事件（startup/resume/clear/compact）、`reflect`、`poteto-mode`、`worktree-cleanup` playbook 的內容。快照內無法驗證，需到該上游 repo 讀原文。
- verification-gate SKILL.md:9（diff 檔 73-82）與 CHANGELOG「借鑑 pstack-claude 的 tdd」：歸屬是否精確，需同上。
- worktree-manager 收尾的「git 2.42.0 與 2.54.0 實測」與 `!!` 不被拒絕、`??` 被拒絕的行為：需在這兩版 git 上跑 `git worktree remove` 實測。我只依 git 行為判斷，認為方向正確，未驗版本號。
- scripts/CLAUDE.md 變異表（diff 檔 60-69）每列「應該變紅的情境」：需實跑變異，我未跑。

[未報]
- worktree-manager:38「WORKTREE_INFO.md 每次都會出現在 `??`」以專案未 gitignore 為前提，快照沒有依據，不成立為缺陷。
- worktree-manager 收尾移除了舊版「確認 worktree 內變更已全部 commit」的前置條件，CHANGELOG 只寫新增的 status 檢查、沒寫這個語意改動。屬文件漏寫，不是功能錯誤。
- 已核對的引用（都成立）：check-claude-md.sh 的 `EMPTY_TREE`（:28）、`read_base`（:52）、`resolve_fork_base`（:92）、`reviews_missing`（:159）、`[ -d docs/reviews ] || return 1`（:161）、`(^|/)S[0-9][^/]*\.md$` 在 :186、註解 `S[0-9]` 在 :183、`--diff-filter=A` 在 :185、`還有 commit 跳過檢查` 在 :195、`上一段沒有附 review 報告` 在 :202、`沒有新增任何 docs/reviews/S*.md` 在 :203、`只檢查 staged` 在 :118、`跳過 review 報告檢查` 在 :175、`改從共同祖先` 在 :99、`沒有可用的段落起點` 在 :224；githooks/pre-commit 以無參數 exec gate。tests/test-gate.sh 新區塊（diff 檔 191-245）的 said 字串與 CLAUDE.md 的繞過①②③敘述一致。

What I ran:
- 讀 diff 檔全部 3024 行（11 段 Read）→ 內容完整，無截斷
- Grep 關鍵字於 scripts/check-claude-md.sh（上列字串與行號）→ 全部命中
- Read scripts/githooks/pre-commit → `exec .../scripts/check-claude-md.sh`，無參數
- 未執行任何測試、變異或安裝指令（依指示）