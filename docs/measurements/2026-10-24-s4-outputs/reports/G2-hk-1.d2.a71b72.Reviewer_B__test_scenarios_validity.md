Critical 0 / Important 1 / Smells 0 — 範圍：快照 `git diff HEAD~1 HEAD` 的 4 檔，重點為 `tests/test-gate.sh` 的 ⑥–⑪ 與 `scripts/check-claude-md.sh` 的 `resolve_fork_base` / `reviews_missing`（只讀 diff 檔，未實跑）。

[Important] tests/test-gate.sh:338-349 ⑪ 裡 `reviews_missing` 的「連共同祖先都沒有」分支從未執行，`said "找不到共同祖先"` 比對到的是 `owed_dirs` 的警告。
  Failure: 把 check-claude-md.sh:165-167 的警告與 `return 1` 拿掉或改成 `return 0`，test-gate 仍全綠。原因是 test-gate.sh:340 的 `rm -rf … docs` 先刪了 docs/reviews，check-claude-md.sh:151 的 `[ -d docs/reviews ] || return 1` 就提前返回。
  Evidence: test-gate.sh:340 刪 `docs`；check-claude-md.sh:108 的 owed 警告含「也找不到共同祖先」，所以 test-gate.sh:349 的 said 由它滿足。⑪ 的標題與註解（335–337）宣稱「兩處都要放行但講出來」，對 reviews 那一處不成立。
  修法方向：在 r7 commit 前於 orphan 上重建 `docs/reviews`，並把 said 改成「跳過 review 報告檢查」。

What I ran
- `grep -n '^----- ' diff.txt` → 四段位置 206 / 306 / 599 / 657，全檔 1010 行
- `sed -n 1,205p diff.txt` → 前段 git diff（read only）
- `sed -n 306,598p diff.txt` → check-claude-md.sh 整檔（read only）
- `sed -n 657,1010p diff.txt` → test-gate.sh 整檔（read only）
- 其餘判斷純靠讀程式碼推演；未跑 git、未跑 test-gate、未做變異實驗

Not reported
- 未實跑、需交回確認：對 check-claude-md.sh:165-167 做變異（刪除或改 return 0）後跑 `bash tests/test-gate.sh <變異副本>`，預期全綠，可證實上面那則。
- 未實跑、需交回確認：scripts/CLAUDE.md 寫的三個變異紅數（3 / 7 / 2）與 test-gate 的 90 / 81 數字；文件裡的數字要重跑才算數。
- 註解理由方向相反：check-claude-md.sh:75 與 scripts/CLAUDE.md 說「往寬退才不會洗掉 report 要求」，但對 reviews 而言寬範圍更容易找到 S 檔。實際影響有限（amend 情境只多一個 commit），不列為缺陷。
- `--diff-filter=A` 在預設 rename 偵測下，把草稿改名成 `S1-a.md` 會被判為 R 而擋下。只會誤擋、不會放行（推論，未實跑）。
- test-gate.sh:273 ⑦ 的標題寫「起點 commit 被改寫」，實際測的是 HEAD 的 amend。test-gate.sh:283–285 已自行註明，只是標題過時。
- ⑩ 的 `said "改從共同祖先"`（test-gate.sh:332）同時被 owed 與 reviews 兩處警告滿足，但 test-gate.sh:333 的「沒有新增任何 docs/reviews/S*.md」已能區分 reviews 分支，不影響判定。