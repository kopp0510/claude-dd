Critical 0 / Important 2 / Smells 0。審查範圍是 G3-old-2 快照的 `git diff HEAD~1 HEAD`，共 8 檔。

[Important] scripts/CLAUDE.md（變異表第一列）與 tests/test-gate.sh:319 宣稱「pre-commit 也查報告」這個變異會讓繞過① 變紅，但繞過① 那一則自己抓不到這個變異。它在實測裡變紅，是因為前面的情境先連鎖失敗了。
  Failure: 照設計，進繞過① 時起點等於 HEAD（by0）。這時 pre-commit 呼叫 `reviews_missing`，會被 check-claude-md.sh:165 的 `[ "$base" = "$head_sha" ] && return 1` 判成不缺報告。所以真的有人把 pre-commit 改成也查報告時，只要前面的情境沒有連鎖失敗，by1 會照樣通過，繞過① 保持綠燈，文件宣稱的保護就失效了。
  Evidence: 變異版輸出 m1.out:119 是 `❌ 重記起點(起點 = by0)：預期 pass，實際 block`，:131 是 `❌ 起點應為 …，實際是 0ca83a5…`，之後 :132 繞過① 才紅。也就是說，繞過① 變紅時起點根本不在 by0。

[Important] skills/verification-gate/SKILL.md:36 與 :58（還有 templates/global/CLAUDE.md:193–195）要求修 bug 時，`git stash -u` 跑舊碼要紅成「原本那個錯的值」才算。這跟同一份模板 :364–366 的鑑別力規則衝突：那條規定改回舊版時只比對「不等於固定版的輸出」，不能斷言某個預期的壞結果。
  Failure: 修 bug 時新測試第一次跑，跑的就是舊版（stash 模式本身就是「改回舊版確認會紅」）。舊碼如果掉進第三種狀態，例如丟例外或回另一個錯的值，agent 照 :58 會判定「不是應該的紅」，回頭去改一個其實有鑑別力的測試。這正是 :365–366 記錄的 2026-10-07 實例。模板第 195 行用「這條管新測試第一次跑」來切開兩條規則，但修 bug 時這兩種情況是同一次執行，切不開。verification-gate 那兩行連這個括號但書都沒有。
  Evidence: 讀到 SKILL.md:58「對得上「它應該怎麼紅」才算（修 bug 時就是那個錯的值）」，以及模板 :364「不要斷言某個預期的壞結果」。

What I ran
- `git diff HEAD~1 HEAD` → 247 行，8 檔
- `git show HEAD:tests/test-gate.sh`、`HEAD:scripts/check-claude-md.sh`、`HEAD:skills/worktree-manager/SKILL.md`、`HEAD:templates/global/CLAUDE.md`（grep）、`HEAD:CHANGELOG.md`（grep `^## `）→ 讀取比對
- 唯一一次重現實驗：在 `/tmp` 用固定版 gate 與變異版各跑一次 `bash test.sh <gate>`。變異版在 `staged=` 那行下面加 `reviews_missing && exit 1`。結果是固定版 exit 0（105 ✅ / 0 ❌），變異版 exit 1（84 ✅ / 27 ❌）；第一則紅在「建立 docs/reviews/ 的那個 commit」，繞過① 之前「重記起點(起點 = by0)」已經被擋。跑完已刪掉暫存目錄。

Not reported
- 繞過②、繞過③ 的對照組與其餘兩列變異描述，我讀程式碼核對過，邏輯成立；那兩列的「只有某則變紅」沒有實跑驗證。
- worktree-manager 對 `git worktree remove` 的行為宣稱（git 2.42.0 / 2.54.0）需要外部查證：在拋棄式 repo 放一個 ignored 的 `.env` 與一個 `??` 檔，各跑一次 `git worktree remove`。
- scripts/CLAUDE.md 新表格放在清單項內、前面沒有空行，在 GitHub 上能不能渲染成表格我沒驗證。