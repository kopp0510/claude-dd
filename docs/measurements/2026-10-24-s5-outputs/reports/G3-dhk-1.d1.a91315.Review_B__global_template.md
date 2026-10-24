Critical 0 / Important 2 / Smells 0 — 範圍是快照 `git diff HEAD~1 HEAD` 的 8 個檔，主攻 `templates/global/CLAUDE.md` §3.5 的改動。

[Important] `templates/global/CLAUDE.md:195` §3.5 的變異判準指向 §3.9，但 §3.9 沒有「不等於要來自被測物給錯結果」的限制。
  Failure: 變異版讓模組載入失敗（import 壞掉）時，§3.9 的「不等於固定版輸出就算紅」會判成「抓到了」，但同一段 §3.5 第 193–194 行剛說 import 錯誤也會紅，兩句互相矛盾。
  Evidence: `grep -n '不等於|鑑別力' templates/global/CLAUDE.md` → 195 行引用 §3.9；364–367 行的鑑別力條文只寫「變異版只要『不等於它』就算紅」，沒有該限制。

[Important] `templates/global/CLAUDE.md:193–195` 「對得上它應該怎麼紅」只舉修 bug 的例子，新功能的情境沒有合法的紅法。
  Failure: 寫新功能的測試時，函式還不存在，紅燈來自「找不到函式」，而同一條規則明說 import 或找不到的紅不算。照規則寫的人沒有合格的做法，只能猜。
  Evidence: `grep -n '空殼|回錯值|找不到這個函式' templates/global/CLAUDE.md` → 無命中。

Not reported:
- 根目錄 CLAUDE.md 第 333–337 行的新引言塊位置正確，表格第 339 行前有空行，沒有插斷表格。
- CHANGELOG 的 `## 未發布` 插在 `## 1.6.4` 之前，已發布區塊未動。
- `scripts/CLAUDE.md` 的行號錨點都對得上：186 是樣式行、183 是註解、215 是 `--start-segment` 那支的 `head_or_empty`、232 是 SKIP 路徑。`staged=` 在 238 行。
- 本 diff 沒有新增函式或模組結構，Fowler 基線不適用。
- `tests/CLAUDE.md` 表格裡的「61 → 73」是舊文字，不是這次新增的。

需要外部查證（未執行，需要跑變異或在 git 2.42/2.54 上實測）:
- `scripts/CLAUDE.md` 與 `tests/CLAUDE.md` 裡 2026-10-19 的變異結果，例如「整支停在 ⑦ 那行裸跑的 amend」，需要實際套用變異重跑 `tests/test-gate.sh`。
- `skills/worktree-manager/SKILL.md` 與 CHANGELOG 中 `git worktree remove` 的拒絕行為與中文錯誤訊息原文，需要在 git 2.42.0 與 2.54.0 實測。
- `pstack-claude` 的 SessionStart hook 與 2026-10-18 評估紀錄，是外部 repo 的事實，我沒有查證。
- 部署版 `~/.claude/CLAUDE.md` 是否與 repo 模板一致，超出我的讀取範圍。

What I ran:
- Read diff 檔 1–3024 行（分段讀完）→ 完整讀完，含 8 個檔案的整檔內容
- `Grep '不等於|鑑別力|空殼|回錯值|找不到這個函式|紅了要讀紅的內容' templates/global/CLAUDE.md` → 193、195、364–367、371 命中；空殼與回錯值無命中
- `Grep 'staged=|reviews_missing|head_or_empty >|read_base\(\)|\[ -d docs/reviews \]|S\[0-9\]' scripts/check-claude-md.sh` → 52、159、161、183、186、215、232、238 命中
- `Read scripts/check-claude-md.sh 196–237` → 215 在 `--start-segment` 的 case 分支內，232 在 SKIP 分支內