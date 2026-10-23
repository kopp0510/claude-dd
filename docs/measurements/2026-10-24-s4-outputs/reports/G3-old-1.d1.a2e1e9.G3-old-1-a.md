Critical 0 / Important 3 / Smells 0。審查範圍是快照的 `git diff HEAD~1 HEAD`，共 8 檔，repo 在 `<s4>/G3-old-1`。

[Important] templates/global/CLAUDE.md:141 新增的 §3.5「紅了要對得上『它應該怎麼紅』才算（修 bug 時就是那個錯的值）」，跟同檔 §3.9 鑑別力測試那條直接矛盾。verification-gate SKILL.md:36 也跟著寫成「紅的是原本那個 bug」。
  Failure: 修 bug 時用 `git stash -u` 退回舊碼跑新測試，舊碼沒有給出預期的「實際 2」，而是掉進第三種狀態（例如回 null 或丟例外）。照新條文要判成「沒抓到」，結果回頭去改一個其實有鑑別力的測試。這正是 §3.9 記下的 2026-10-07 實例。括號裡用「新測試第一次跑」和「變異版」來分開兩條規則，但修 bug 時對舊碼跑新測試本身就是在改回舊版，兩條規則套在同一個動作上，這個分法分不開。
  Evidence: `git show HEAD:templates/global/CLAUDE.md` 第 364–367 行寫「不要斷言某個預期的壞結果……變異版掉進第三種狀態……差點……回頭去改一個正常的測試」。

[Important] templates/global/CLAUDE.md:143 括號把變異版的判定交給 §3.9「不等於固定版的輸出就算紅」。可是 §3.9 那條沒有「假紅」的但書，新條文要擋的假紅會從這裡重新被算成紅。
  Failure: 變異把檔案改到載入不了，或 import 壞掉，輸出也「不等於固定版」。照 §3.9 算紅，就被當成測試有牙，跟這次新增的「import 路徑寫錯也會紅，那只證明測試自己壞了」互相打架。
  Evidence: §3.9 第 367 行只寫「變異版只要『不等於它』就算紅」。第 368–370 行的「⚠️」講的是別的事（有牙不代表新的一邊該發生、清單不代表是全的），沒有排除載入失敗。

[Important] skills/worktree-manager/SKILL.md:114-128 收尾流程借鑑了 pstack-claude 的 worktree-cleanup playbook，CHANGELOG.md:29 有寫明，但部署出去的 SKILL.md 沒有任何借鑑標註。同一個 diff 裡 verification-gate 那處就有加上。
  Failure: 使用者拿到的 skill 本體看不出這段的來源，構成根目錄 CLAUDE.md「只借概念、不抄檔案時……授權仍要處理」所說的不足歸屬（判準是「能逐條指出哪一段來自誰」）。前例是 verification-gate:9 與 design-brainstorm:9 都把借鑑寫在 SKILL.md 第 9 行。
  Evidence: `git grep -i pstack HEAD`（排除 CHANGELOG）只命中 CLAUDE.md:335,337 與 verification-gate SKILL.md:9，worktree-manager 沒有命中。

What I ran
- `git diff HEAD~1 HEAD` 與 `git show HEAD:{tests/test-gate.sh,scripts/check-claude-md.sh,CHANGELOG.md,skills/worktree-manager/SKILL.md}`，取檔到 /tmp → 讀完，沒有異常
- `grep -n BASE_FILE` 掃 test-gate.sh → 新區塊之前的 rm 只有第 93 行一處（後面接的是 SKIP 自動記起點，不經過 `--start-segment`）
- 唯一一次重現實驗：在 mktemp 拋棄式目錄，照 scripts/CLAUDE.md 新表格的三個變異改 gate，各跑一次 test-gate.sh → 固定版 105 ✅，判定行數 105；m1 84 ✅，判定行數 105，從「建立 docs/reviews/ 的那個 commit」起連鎖變紅（含繞過①）；m2 只紅「繞過③:rm 掉起點檔,開下一段放行」；m3 只紅「繞過③:by/ 的欠帳被洗掉」。表格的記載與 tests/CLAUDE.md「判定行數要一樣」的驗法都對得上實測
- `git grep -i 'superpowers\|pstack' HEAD` → 結果如上一條 Evidence
- `git grep -n -A6 '鑑別力測試(改回舊版'` 讀 templates/global/CLAUDE.md → 引用見第 1 條的 Evidence

Not reported：scripts/CLAUDE.md 的「`test-gate.sh` 前 61 項」是寫死的數字，屬於既有內容，不在這次 diff 內。pstack-claude 本身的 LICENSE 是什麼需要外部查證（到該 repo 看 LICENSE 就能確定），我沒有查。