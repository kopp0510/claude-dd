Critical 0 / Important 2 / Smells 1。審查範圍是快照的 `git diff HEAD~1 HEAD`，共 4 檔：`scripts/CLAUDE.md`、`scripts/check-claude-md.sh`、`tests/CLAUDE.md`、`tests/test-gate.sh`。

[Important] tests/test-gate.sh:333-350 情境 ⑪ 根本沒跑到 `reviews_missing` 裡「連共同祖先都沒有」那一支，它要驗的「兩處放行但必須印警告」只驗到 `owed_dirs` 這一處。
  Failure: 第 336 行 `rm -rf ... docs` 把 `docs/reviews/` 刪掉了。於是 `reviews_missing` 在 `[ -d docs/reviews ] || return 1` 就提早回傳，走不到 `resolve_fork_base`。而 `said "找不到共同祖先"` 比對到的是 `owed_dirs` 印的「也找不到共同祖先，這次只檢查 staged」。結果：把 `reviews_missing` 的靜默放行改回第一版的寫法（不印警告），測試照樣 90 ✅。這正是 diff 自己在 `tests/CLAUDE.md` ① 警告過的「opt-in 目錄不在，測試為了錯的理由而通過」。
  Evidence: 我刪掉 `reviews_missing` 裡「找不到共同祖先，**這次跳過 review 報告檢查**」那兩行 echo（變異 M1），跑 `test-gate.sh` 得到 exit=0、90 ✅、0 ❌。另把固定版 ⑪ 的 `--start-segment` 輸出印出來，裡面只有 `owed_dirs` 那句警告，接著就是「段落起點：…」。

[Important] tests/CLAUDE.md:11、scripts/CLAUDE.md:52-53 這兩處文件寫的事，測試其實沒驗到。
  Failure: `tests/CLAUDE.md` 寫「連共同祖先都沒有時:兩處放行**但必須印出警告**」已有測試，`scripts/CLAUDE.md` 也把「退化時不印警告 → 2 紅」當成「警告有被守住」的證據。實際上那 2 紅（M2）只覆蓋 `resolve_fork_base` 的警告；`reviews_missing` 自己那句「找不到共同祖先」的警告拿掉後是 0 紅（M1）。讀文件的人會以為兩處都有守。另外這段變異紀錄只寫了紅的數量，沒寫哪個變異讓哪幾個情境變紅，違反全域 CLAUDE.md §3.9 的「要記『哪個變異 → 哪幾個情境變紅』」。
  Evidence: 變異 M2（刪掉 `resolve_fork_base` 裡「改從共同祖先 $fork 算起」那行 echo）跑出 exit=1、2 ❌，變紅的是「輸出沒提到：不在目前分支的歷史裡」與「輸出沒提到：改從共同祖先」；變異 M1 是 0 ❌。

Smells
[Smell] scripts/check-claude-md.sh:70-95 有可能是隱藏的依賴：`resolve_fork_base` 的說明只列了 `$1`=prefix、`$2`=head，實際上它還讀全域變數 `$base`。
  Failure: 以後若有呼叫端還沒 `read_base` 就直接呼叫它，或在 `local base` 遮蔽全域變數的函式裡呼叫，`merge-base` 會拿到空字串或錯的 sha。前者會讓 `merge-base` 失敗、退到「連共同祖先都沒有」，結果靜默放行或只檢查 staged。目前兩個呼叫端都先跑過 `read_base`，所以現在還不會出錯。
  Evidence: 第 83 行 `local prefix=$1 head=$2 fork`，第 84 行用的是 `"$base"`。

What I ran
- `git -C <repo> diff HEAD~1 HEAD` → 4 檔 diff
- `git show HEAD:scripts/check-claude-md.sh`（grep 加 `sed -n 100,240p`）與 `git show HEAD:tests/test-gate.sh`（`sed -n 1,50p`）→ 讀了呼叫端與測試 helper
- 在 mktemp 拋棄式目錄裡，用 HEAD 版的 test-gate.sh 對三份 gate 各跑一次（只跑這一次實驗）→ 固定版 90✅/0❌；M1 90✅/0❌（exit 0）；M2 90✅/2❌（exit 1）；並印出固定版 ⑪ 的 `--start-segment` 輸出，只看到 `owed_dirs` 的警告

Not reported：⑩ 的 `said "改從共同祖先"` 比對的也是 `owed_dirs` 那句警告，分不出是哪一處印的；不過 ⑩ 另有「block + 沒有新增任何 docs/reviews/S*.md」能確認 `reviews_missing` 有退到共同祖先並擋下，所以不列為發現。你提供的 test-gate / test-install / bash -n / shellcheck 結果我沒有重跑。

相關路徑：
- <s4>/G2-old-1/tests/test-gate.sh
- <s4>/G2-old-1/scripts/check-claude-md.sh
- <s4>/G2-old-1/scripts/CLAUDE.md
- <s4>/G2-old-1/tests/CLAUDE.md