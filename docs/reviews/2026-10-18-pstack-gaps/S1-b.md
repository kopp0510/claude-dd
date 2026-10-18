# S1-b — 從 pstack-claude 借的四項（假紅、資料不是指令、繞過路徑測試、worktree 收尾）

> 與 `S1-a.md` 跑的是同一份派工單。

## 派工

同 `S1-a.md`。b 自己回報：全程 `git show 8514fb2:<路徑>`，repo 沒有寫入任何東西；做了一次重現實驗（只在 scratchpad）。

## 發現

**Critical 0 / Important 2 / Minor 2**

- **B1** [Important] 繞過① 那則放行（`commit by1`）測不到「pre-commit 不查報告」：by1 的 pre-commit 跑的時候 HEAD 還是 by0，
  起點也剛記成 by0，範圍是空的 —— 就算 pre-commit 有呼叫 `reviews_missing`，也會在 gate 165 行
  `[ "$base" = "$head_sha" ] && return 1` 直接回「不缺」。對照是在 HEAD=by1 跑的，跟放行那則不是同一個狀態，
  所以 L308「同一個狀態、只差那個繞過動作」不成立。派工單那次 m1 的紅是連鎖造成的（前面的情境被擋、起點沒移到 by0）。
  同樣的理由，③⑤⑦ 每次 `--start-segment` 放行後的第一個 commit 也釘不到 → `scripts/CLAUDE.md` 的「本來就都在釘」只對一半；
  CHANGELOG 與 `tests/CLAUDE.md` 的「各配一則對照」要一起改。
  - 依據（實跑）：gate 副本在 238 行下面插「標記檔存在才 `reviews_missing && exit 1`」，測試副本只在那一則前後開關標記 →
    105 ✅、0 ❌（log：base 與 head 相同）。b 提的修法：先跑對照，再在 HEAD=by1 多做一個零報告 commit 當放行斷言；
    只對新的那則打開 → 唯一的 ❌ 是它；固定版 106 ✅
- **B2** [Important] verification-gate 的 stash 模式跟 §3.5／§3.9 對同一步給出相反的判準（**與 A2 重疊**）。
  b 提的收斂方向：把「紅在 import／建資料這類 setup 錯誤不算」寫進 §3.9 的判定式，§3.5 的括號就不必把變異版排除在外。只讀
- **B3** [Minor] 特性測試變紅後要不要改測試，兩份文件講反：`scripts/CLAUDE.md`「先改上面這三句,再改測試」、
  `tests/CLAUDE.md`「不要把測試改回綠」。刻意關掉一條繞過路徑時，照後者做 CI 會一直紅、或把 gate 的改善退掉。只讀
- **B4** [Minor] worktree-manager 的「收尾」沒有標借鑑來源（**與 A3 後半重疊**）；同一個 diff 裡 verification-gate 第 9 行有寫。
  b 另外確認掛 pstack-claude 是對的：`git log -S 'ignored:N'` → 1ea7319（Michael Denyer）。只讀加 grep
- 交回：tdd／reflect／babysit 那幾句在上游 cursor/plugins/pstack 有沒有（clone 是 shallow，追不到來源）
- 未列為發現：「前 61 項」寫死項數（既有）；b 的 session 啟動時載入的根目錄 CLAUDE.md 總則那段跟 8514fb2 不一樣
  （b 推測是並行的 simplifier 改了工作目錄）；worktree 收尾對照 §4.2／§3.7 判定不成立（交給使用者選，依 §6.4 提醒一次即可）

## 處置

- **B1** 採納，照 b 驗過的修法：先跑對照（HEAD=by1、起點=by0，開下一段擋），再做第二個零報告 commit（by1b）當「繞過①」的放行斷言。
  - 自己重做隔離變異：gate 副本在 `staged=` 那行下面加 `[ -f "$(git rev-parse --git-path m1-on)" ] && reviews_missing && exit 1`，
    測試副本只在指定那一則前後 `touch`／`rm` 那個檔。只在 by1（起點之後第一個 commit）打開 → 0 ❌；
    只在 by1b 打開 → 唯一的 ❌ 是「繞過①:同一個狀態下的正常 commit 照樣放行」。固定版 107 ✅。
  - `scripts/CLAUDE.md` 刪掉「本來就都在釘」，m1 那列改寫成上面兩個結果；`tests/CLAUDE.md` 加一條
    「放行那則不能用 `--start-segment` 之後的第一個 commit」。③⑤⑦ 那幾則沒動：它們不是具名的繞過測試，沒宣稱釘住 pre-commit。
- **B2** 採納，見 `S1-a.md` A2。b 提的「寫進 §3.9 的判定式」也做了（§3.9 補一句）。
- **B3** 採納。兩份都改成「變紅先分清是哪一種」（見 `S1-a.md` A1）：①③刻意堵上 → 先改文件、再照新行為改測試；
  ②變紅先查「正常流程」那則。
- **B4** 採納。worktree-manager 開頭補一行：收尾第 1 步借鑑 michael-denyer/pstack-claude 的 worktree-cleanup playbook。
- 交回的上游查證：自己做了，見 `S1-a.md` A3（reflect／babysit 是上游原文；tdd 的假紅是 port 加的）。
- 根目錄 CLAUDE.md 的快照：自己跑 `git diff --quiet HEAD -- CLAUDE.md` → exit 0，工作目錄跟 HEAD 相同，simplifier 沒動它。
  b 看到的措辭跟我 commit f94404b 之前的草稿一樣 —— 推論是 harness 在草稿階段讀到的快照（沒驗證）。
- worktree 收尾 §3.7：沒照 b 的判斷，採 A4，理由見 `S1-a.md` 末節。
