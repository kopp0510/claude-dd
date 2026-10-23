Critical 1 / Important 4 / Smells 0。審查範圍是快照的 `git diff HEAD~1 HEAD`（513af68），三個檔：ci.yml、CHANGELOG.md、scripts/check-claude-md.sh。

**[Critical]｜scripts/CLAUDE.md:8-11（diff 沒動到它）｜改了 gate 腳本，同目錄的 CLAUDE.md 和全域模板 §3.9 都沒跟著改，違反專案明文規則**
- 證據 1：`git log --stat -1` 顯示這個 commit 只動 3 個檔，scripts/CLAUDE.md 不在裡面。
- 證據 2：根目錄 CLAUDE.md 規定「改 `.sh` 等程式碼檔時，該目錄的 CLAUDE.md 必須同批更新」；scripts/CLAUDE.md:21 規定「gate 的檢查邏輯改動時，同步檢視全域模板 §3.9」。
- 證據 3：scripts/CLAUDE.md:8-11 現在仍寫「staged 變更含程式碼檔的目錄，必須存在 CLAUDE.md 且同批 staged」，完全沒提段落起點、欠帳，也沒提 `--start-segment` / `--segment-base`。
- 證據 4：在快照用 `git grep` 找 `start-segment|segment-base|dd-segment-base`，排除這 3 個檔後是 0 筆。templates/global/CLAUDE.md:273、commands/dd-init.md:125、README.md:138 都還是舊的說法。換句話說，這個 commit 本身照 gate 自己的規則也會被擋。
- 建議改法：同批更新 scripts/CLAUDE.md 和 templates §3.9 的 gate 描述。dd-init 的告知文字（Phase 3 第 4 點）和兩份 README 也要補上新行為。

**[Important]｜check-claude-md.sh:59-64（diff 第 187-193 行）、113（SKIP 分支）｜起點不在目前分支的歷史裡時只警告不擋，SKIP 的欠帳就此消失，rebase、amend、換分支都會碰到**
- 失敗情境 1（amend）：沒記過起點，跑 `SKIP_DOC_CHECK=1 git commit --amend` 新增 src/a.js。自動記下的起點是被 amend 掉的那個舊 HEAD，下一個正常 commit 只印 ⚠️ 就 PASS，src/ 從頭到尾沒有 CLAUDE.md。
- 失敗情境 2（rebase）：記起點、SKIP 新增 src/a.js，再 `git rebase main`，之後的正常 commit 一樣 PASS。
- 失敗情境 3（換分支）：在 feat 記起點後切到 main，SKIP 新增 lib/l.js，之後一樣 PASS。原因是 SKIP 分支看到 `read_base` 成功就不重記起點，不管它還是不是祖先。
- 證據：在 /tmp 實跑三種情境都是 PASS，輸出含「⚠️ 段落起點 … 不在目前分支的歷史裡」。CI 情境 7 把這個「放行」寫成了預期行為。
- 建議改法：SKIP 分支在起點不是 HEAD 的祖先時要重記。起點失效時改用 `git merge-base "$base" HEAD` 當範圍下界，或者直接擋下，不要放行。

**[Important]｜check-claude-md.sh:81（diff 第 209 行）｜起點以來的範圍把 pull/merge 進來的別人的 commit 也算進去，所以會拿隊友的帳擋自己 commit**
- 失敗情境：先記起點。隊友在上游新增 api/t.py，沒寫 CLAUDE.md，也沒走 gate。我 `git pull --no-rebase` 之後，只改 README 的 commit 被擋，訊息要求補 api/CLAUDE.md，理由寫的是「段落起點之後有 commit 跳過檢查」。可是我根本沒有 SKIP 過。而且 `--start-segment` 也會因為這筆帳拒絕重記，人就卡住了。
- 證據：實跑輸出 `BLOCK … 缺少 CLAUDE.md 的目錄：api/CLAUDE.md`。
- 建議改法：範圍只算第一父鏈（`--first-parent`），或者只算本人 / 本 worktree 的 commit。至少錯誤訊息不要宣稱「跳過檢查」。

**[Important]｜check-claude-md.sh:81 + 136（diff 第 209、275 行）｜目錄名含非 ASCII 字元時，欠帳會被靜靜放掉**
- 失敗情境：在 `中文/` 目錄 SKIP 新增 a.js，之後的正常 commit 直接 PASS。
- 原因：`git log --name-only` 在 core.quotePath 預設值下輸出的是加了引號的 `"\344\270\255…/a.js"`。dirname 算出來的目錄不存在，於是被第 136 行的 `[ ! -d "$d" ] && continue` 當成「整個刪掉了」跳過。
- 證據：實跑 `[b] PASS`。本機 `git config --get core.quotePath` 沒有設定（exit 1），也就是用預設值 true。
- 建議改法：`git -c core.quotePath=false log …`，`diff --cached` 那一支也一起加。

**[Important]｜check-claude-md.sh:81 + 112-116｜起點自動記下之後永遠不會往前推，每次 commit 都要重算整段歷史，時間隨 commit 數線性變長**
- 失敗情境：起點只有在跑 `--start-segment` 時才會前移。但在 Critical 那條提到的文件裡，沒有任何地方告訴使用者要跑它。所以實際上起點就停在第一次 SKIP 的地方。之後每個 commit 都要跑 owed_dirs，每結算一個 commit 就要開大約 10 支子程序。
- 證據：300 個 commit 的範圍，一次 gate 跑了 4.66s（`time` 實測），換算一個 commit 約 15ms。3000 個 commit 推算約 45s，這是推論，沒有實跑。
- 建議改法：把「段落開始先跑 `--start-segment`」寫進文件和 dd-init。或者在欠帳結清的那個正常 commit 自動把起點推到 HEAD。

**[Important]｜check-claude-md.sh:81（diff 第 209 行）｜merge commit 裡新增的程式碼看不到**
- 原因：`git log --name-only` 預設不列 merge commit 改到的檔案。
- 失敗情境：`git merge --no-commit --no-ff b1` 之後新增 src/a.js，用 SKIP commit 這個 merge，之後的正常 commit PASS。
- 證據：實跑 `d73bbc5 7bc84ae 413e827 merge` 之後是 `[after-merge] PASS`。
- 建議改法：加 `--diff-merges=first-parent`，或用 `-m --first-parent`，要和上面那條的修法一起考量。

**Not reported**
- bash 3.2 遇到 `$'\001'` case 分支：用 /bin/bash 3.2.57 實跑正常。
- 含空白的路徑：實跑會正確擋下。
- worktree：起點寫進 `.git/worktrees/wt/`，各自獨立，正常運作。
- 在子目錄 commit / 跑 `--segment-base`：正常。
- 起點檔內容是垃圾時：SKIP 會重記，正常。
- shellcheck 0 個警告。
- staged 那一支的非 ASCII 路徑加引號問題：既有問題，這次 diff 沒有引入。
- CHANGELOG 寫「22 個情境」：我數了 ci.yml 裡的 `expect` 呼叫，確實是 22 個，不報。
- `git log` 預設按日期排序，時間戳錯亂時結算順序可能顛倒：沒做實驗，不報。

**What I ran**
- `git -C <快照> log --stat -2`：HEAD 只動了 ci.yml、CHANGELOG.md、check-claude-md.sh。
- `git -C <快照> grep -n -e start-segment -e segment-base -e dd-segment-base`（排除 3 個被改的檔）：0 筆。
- `shellcheck -S warning scripts/check-claude-md.sh`：exit 0。
- `/bin/bash --version`：3.2.57。
- 在 /tmp mktemp 建的 repo 實跑各情境，hook 用 exec 呼叫快照裡的 gate：
  - 基本 SKIP：BLOCK（正確）
  - 非 ASCII 目錄：PASS（漏洞）
  - 空白目錄：BLOCK（正確）
  - 換分支後 SKIP：PASS + ⚠️
  - rebase：PASS + ⚠️
  - amend：PASS + ⚠️
  - merge 內新增程式碼：PASS
  - pull 進隊友的 commit：BLOCK api/CLAUDE.md
  - worktree：BLOCK（正確），起點寫在 .git/worktrees/wt/dd-segment-base
- 300 個 commit 的範圍跑 gate：4.662s。

**需要外部查證**
- GitHub Actions runner 的 git 版本是否支援 `--diff-merges`（git ≥ 2.31）：查 runner image 的 git 版本就能確定。