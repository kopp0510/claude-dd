Critical 0 / Important 3 / Smells 0。範圍：`HEAD~1..HEAD` 的 `scripts/CLAUDE.md`、`scripts/check-claude-md.sh`、`tests/CLAUDE.md`、`tests/test-gate.sh`。

[Important] `tests/test-gate.sh:335-349`（情境 ⑪）聲稱 `reviews_missing` 在無共同祖先時也會放行並印警告，但測試實際上沒有走到那支程式。
  Failure: 把 `check-claude-md.sh:165` 的警告拿掉（靜默放行，正是注解說 S6 抓到的繞過路徑），`test-gate.sh` 仍是 90 ✅ / 0 ❌。原因是 `test-gate.sh:340` 的 `rm -rf … docs` 刪掉了 `docs/reviews`，所以 `check-claude-md.sh:151` 的 `[ -d docs/reviews ] || return 1` 先返回。
  Evidence: 變異 warn_rev_off → 90 ✅ / 0 ❌ / exit 0。建議：⑪ 之前重建 `docs/reviews/`，並斷言 review 專屬的警告文字（`said "找不到共同祖先"` 只對應 owed 那句）。

[Important] `scripts/CLAUDE.md:27`、`scripts/CLAUDE.md:62`、`tests/CLAUDE.md:33` 寫的變異數字重跑對不上。
  Failure: 讀者依文件以為「永遠 return 1」會紅 12 個情境、「退化時不印警告」會紅 2 個，實際結果不同；文件本身也違反全域 §3.10「能列舉的就列舉、不要寫死數字」。
  Evidence: `[ -d docs/reviews ] || return 1` → `return 1` 實測 15 紅（文件寫 12）；只拿掉 owed 那句警告 → 1 紅（文件寫 2）；只拿掉 reviews 那句 → 0 紅。`:` 替換 `opt_removed` 的 5 紅、`seg_soft` 3、`fork_off` 7、`acmr` 2 與文件相符。建議：刪數字或附產生指令，並在修完 ⑪ 後重算。

[Important] `tests/test-gate.sh:283` 的新註解寫「走的是 `range_base="$base"` 那一支」，但這段 diff 已把該分支抽進 `resolve_fork_base`，程式裡不存在這個賦值。
  Failure: 維護者照註解去找不存在的分支，無法判斷 amend HEAD 的情境實際經過哪段程式。實際上 base 是祖先時由 `check-claude-md.sh:82-94` 的 `resolve_fork_base` 回傳 base（`:162` 呼叫）。
  Evidence: `grep -n 'range_base="\$base"' scripts/check-claude-md.sh` → 無輸出。

Not reported:
- `check-claude-md.sh:196-197`（gate 訊息）寫「兩個 reviewer、-a.md 與 -b.md」，與全域 §3.9 步驟 4「最少 3 個審查者加裁決」不符。這行不在本 diff 內，判為既有問題。
- `tests/test-gate.sh:273-276`（⑦ 標題）描述的是「amend 起點 commit」情境，但 ⑦ 實際 amend 的是 HEAD；`:282-285` 已自我更正，不另報。
- `CHANGELOG.md:413` 寫「起點被 amend／rebase 改寫時改從共同祖先算」，在 diff 外，我沒有核對未發布區塊是否需要本輪條目。
- 需要外部查證：`scripts/CLAUDE.md:55-58`、`check-claude-md.sh:78-80`、`test-gate.sh:337` 歸因的「S6 review 抓到」「S6 的 reviewer 預言」「S4 實作時確認」。快照只有 2 個 commit，`docs/reviews/` 只有 CLAUDE.md，無法驗證。需要的是 S4、S6 的 review 原文與對應 commit hash。

What I ran（變異檔放在 `/private/tmp/reviewC.bEzqKl`，未改 repo，未 commit）:
- Read `diff.txt` offset 1 / 301 / 601 / 901（共 1010 行）→ 全部讀完
- `/bin/bash tests/test-gate.sh`（未改的 gate 副本，當作變異對照基準；你已確認的指令我重跑了一次）→ 90 ✅ / 0 ❌ / exit 0
- 變異 seg_soft（`--segment-base` 加 `|| git merge-base`）→ 88 / 3 ❌（文件 3，相符）
- 變異 fork_off（`fork=$(false)`）→ 87 / 7 ❌（文件 7，相符）
- 變異 warn_owed_off（owed 警告改 `:`）→ 90 / 1 ❌，只紅「找不到共同祖先」（文件 2，不符）
- 變異 warn_rev_off（reviews 警告改 `:`）→ 90 / 0 ❌ / exit 0
- 變異 opt_always_ret1（`[ -d docs/reviews ] || return 1` → `return 1`）→ 83 / 15 ❌（文件 12，不符）
- 變異 opt_removed（該行改 `:`）→ 85 / 5 ❌；4 個在 `test-gate.sh` 第 1–221 行（舊區段 expect 數 61，文件「4 在舊 61 項」相符）
- 變異 acmr2（reviews_missing 的 `--diff-filter=A` → `ACMR`）→ 89 / 2 ❌（文件 2，相符）
- `grep -n 'range_base="\$base"' scripts/check-claude-md.sh` → 無輸出
- `ls docs/reviews`、`git log --oneline -3` → 只有 CLAUDE.md；只有 2 個 commit
- `git grep '共同祖先' -- '*.md'` 與前例引用 grep → 結果見 Not reported