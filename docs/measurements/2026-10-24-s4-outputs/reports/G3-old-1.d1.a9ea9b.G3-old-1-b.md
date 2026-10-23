Critical 0 / Important 2 / Smells 0：審查範圍是 `git diff HEAD~1 HEAD`，共 8 檔，快照在 <s4>/G3-old-1

[Important] skills/verification-gate/SKILL.md:36（新加的紅旗那條也一樣）這兩處要求「stash 掉修復後紅的必須是原本那個 bug／對得上它應該怎麼紅」，跟 §3.9 的鑑別力規則衝突。
  Failure：`git stash -u` 把修復藏起來，等於「改回舊版確認會紅」。舊碼可能掉進第三種狀態，例如丟例外，而不是回報告裡那個錯值。照這兩處判，就會認定「紅的不是原 bug＝測試沒抓到」，回頭去改一個本來正常的測試，正是 §3.9 記下的那次 2026-10-07 事故。
  Evidence：templates/global/CLAUDE.md:364-366 寫「鑑別力測試(改回舊版確認會紅)…不要斷言某個預期的壞結果…變異版掉進第三種狀態」。同一個 diff 在 :195 也自己劃了界線（「判定變異版…仍照 §3.9…不等於固定版的輸出就算紅」），但 verification-gate 的 stash 模式正落在這條界線的另一邊，卻照「對得上原 bug」判。

[Important] skills/worktree-manager/SKILL.md 收尾步驟 1 的第三點，把「commit」列成 `!!`（被 gitignore 的）檔案的選項之一，而例子正是 `.env`。
  Failure：agent 照文件用 AskUserQuestion 給「commit / 搬走 / 刪掉」三選一，使用者選 commit，就得 `git add -f .env`，把 secret 寫進分支歷史。這違反全域 §3.7「不把 secret 寫進 commit」。文件也沒說 ignored 檔要 commit 得加 `-f`。
  Evidence：同一點寫著「上面兩種裡要留的…（commit、搬到哪、還是刪掉）」，「上面兩種」包含 `!!` 那一類，那一類的例子就是「步驟 4 複製出來、之後又改過的 `.env`」。

What I ran
- `git diff HEAD~1 HEAD` → 247 行，8 檔
- `git show HEAD:` 取 tests/test-gate.sh、scripts/check-claude-md.sh、scripts/CLAUDE.md、templates/global/CLAUDE.md、兩份 SKILL.md 來讀 → 已讀
- 一次重現實驗（`git archive` 到 mktemp 目錄 /var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.ysMCbH1ee8），照 scripts/CLAUDE.md 表格做三個變異，各跑 `bash tests/test-gate.sh <變異 gate>`：
  - 固定版 → exit 0，105 ✅，判定行 105
  - v1（`staged=` 那行下面加 `reviews_missing && exit 1`）→ 判定行 105，紅的包含「繞過①」，並從「建立 docs/reviews/ 的那個 commit」起連鎖變紅，跟表格寫的一致
  - v2 → 只紅「繞過③:rm 掉起點檔,開下一段放行」，一致
  - v3 → 只紅「繞過③:by/ 的欠帳被洗掉」，一致
  - 結論：tests/CLAUDE.md 新寫的判定行數驗法有效，四版的判定行都是 105

Not reported：CHANGELOG 與 worktree-manager 裡的「git 2.42.0 與 2.54.0 實測」屬外部查證，我沒驗。要確認的話，用兩個版本各跑 `git worktree remove` 一次：對有 `??` 的 worktree 應該被拒、對只有 `!!` 的應該靜默刪掉。上面那個實驗目錄我沒刪，刪除屬破壞性操作要先確認，你同意的話可以自己清掉。