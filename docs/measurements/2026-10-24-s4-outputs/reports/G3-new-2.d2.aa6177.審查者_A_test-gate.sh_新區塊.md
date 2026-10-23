Critical 0 / Important 1 / Smells 0 — 範圍：快照 `git diff HEAD~1 HEAD`，共 8 個檔。

主攻的 `tests/test-gate.sh` 新區塊和 ⑦ 那行 amend 的改動，我逐則對照 gate 原始碼（`scripts/check-claude-md.sh`）並實跑三個變異，沒找到缺陷。唯一的發現在文件規則上：這次新寫的「假紅」規則和 §3.9 的鑑別力規則互相衝突。

[Important] `skills/verification-gate/SKILL.md:36`（diff 檔 1595 行）、`skills/verification-gate/SKILL.md:58`（diff 檔 1617 行）、`templates/global/CLAUDE.md:193-195`（diff 檔 1894-1896 行）
- **缺陷**：新規則要求「修 bug 時紅的必須就是那個錯的值」。但 stash 迴歸模式（藏起修復、跑舊碼）其實就是 §3.9 說的「改回舊版確認會紅」。§3.9（diff 檔 2065-2066 行）明文寫「不要斷言某個預期的壞結果」，因為舊碼可能掉進第三種狀態。§3.5 末尾的括號只說「判定變異版仍照 §3.9」，沒有把 stash 迴歸歸給哪一條；`verification-gate:58` 連這個括號都沒有。
- **失敗情境**：修完 bug 後跑 `git stash -u && <測試>`，結果紅的是「預期 3、實際 undefined」而不是「實際 2」。照新寫的 `verification-gate:36`，這算「紅的不是原本那個 bug」，於是判定測試無效、回頭去改一個其實有鑑別力的測試。這正是 §3.9 記錄的 2026-10-07 事故。
- **證據**：diff 檔第 91 行寫「看到失敗，而且紅的是原本那個 bug」，第 142-144 行寫「修 bug 時就是那個錯的值」，與第 2065 行的鑑別力規則牴觸。佐證：本 session 載入的已部署版全域 CLAUDE.md §3.5 後來改成「錯的值不必是你預期的那一個：舊碼可能掉進第三種狀態…把修復藏起來重跑（`git stash -u`、改回舊版）時也照這條判」，可見作者後來修過同一個衝突。
- **建議**：判準改成「紅在被測物給出的錯誤結果上（斷言的實際值），而不是載入或資料建置失敗」，並明寫 stash/改回舊版的情況套用 §3.9。

新區塊與 ⑦ 的逐項查證結果（都成立）：
- **繞過①**：放行成立，因為 pre-commit 那條路（gate 第 229-300 行）從不呼叫 `reviews_missing`。對照組在 `by0..by1` 範圍裡沒有新增 `S*.md`，也沒有欠帳，所以擋它的確實是報告那一關。
- **繞過②**：「起點設 by2 就擋、設 by0 就放行」照 gate 第 185 行（只算 `--diff-filter=A` 的新增報告）推得出來。`base_is "$BY0"` 那行的理由（被擋下的 `--start-segment` 不寫起點檔，gate 第 213 行先 exit）也正確。
- **繞過③**：對照組的 `said "還有 commit 跳過檢查"` 只有欠帳那一關會印，挑得對。`rm` 之後兩關都靠 `read_base` 失敗而放行。`by6` 補了 `by/CLAUDE.md`，⑨ 以後各情境的前提沒被破壞，⑪ 的 `git clean` 也照常。
- **⑦ 的 amend**：包進 `expect` 的理由實跑證實：舊版測試搭配變異 M1，整支停在 ⑦，判定行只有 76 行（固定版 105 行）。

`scripts/CLAUDE.md` 變異表三列實跑結果，都與宣稱一致：
- **M1**（`staged=` 下面加 `reviews_missing && exit 1`）：繞過①變紅，另外從 r0 起一路連鎖變紅。
- **M2**（只加在 `--start-segment` 那一支）：只有「繞過③:rm 掉起點檔,開下一段放行」變紅。
- **M3**（只改 `--start-segment` 那一支）：只有「繞過③:by/ 的欠帳被洗掉…」變紅。

What I ran（都在 `mktemp -d` 複製的副本裡跑，跑完已刪除，快照沒動）：
- `bash test-gate.sh <固定版 gate>` → exit 0，105 ✅
- M1：`awk` 在 `staged=` 那行下面插入 `reviews_missing && exit 1`，跑 `test-gate.sh` → exit 1，判定行 105；紅的是 r0 起整串連鎖，含「繞過①…放行」
- M2/M3 第一次用樣式比對插入，結果同時命中第 215 與 232 兩行（第 232 行是 SKIP 那一支）→ M3 多紅一則 `base_is`；作廢，改用 `NR==215` 重做
- M2（`NR==215` 前插入）→ exit 1，判定行 105，只紅「繞過③:rm 掉起點檔,開下一段放行」
- M3（`NR==215` 替換）→ exit 1，判定行 105，只紅「繞過③:by/ 的欠帳被洗掉…」
- `git show HEAD~1:tests/test-gate.sh` 搭配 M1 跑 → exit 1，判定行 76，最後一則是「段落內的 commit」（停在裸跑的 amend）
- 用 `grep` 檢查 CHANGELOG 的標題與 `v*` tag → `## 未發布` 在 `## 1.6.4` 之上，位置正確

Not reported:
- 變異表寫的 `head_or_empty > "$BASE_FILE"` 在 gate 裡有兩處（第 215、232 行），只靠「它那一支」區分；我自己第一次就套錯行，但表裡寫明了是哪一支，不算錯。
- worktree-manager 引用的「步驟 4」「步驟 6」與 `SKILL.md` 第 20、23 行對得上；git 那句英文錯誤訊息和「ignored 檔會被直接刪掉」沒有在 git 2.42.0 / 2.54.0 重跑（需要外部查證：在拋棄式 repo 跑 `git worktree remove`）。
- `scripts/CLAUDE.md:71` 的「前 61 項」是既有的過期數字，不是這次 diff 引入的。