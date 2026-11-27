# S7 審查 — A（腳本的邏輯）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S7（根目錄 CLAUDE.md 大小上限，pre-commit 與 CI 都擋）。

## 派工

`code-reviewer`，不帶 model 參數，與另外三個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s7/review/pack.txt`，1832 行，沒進 repo）的組成：
- 第 1 部分：`git diff a4d9185`（表上這段的起點到工作目錄；HEAD = 808cf87，工作目錄乾淨、沒有未追蹤的檔）
- 第 2 部分：步驟 3（code-simplifier）跑了，沒有改任何檔（主對話用 `cmp` 核對過）
- 第 3 部分：`scripts/githooks/claude-md-size.sh`、`scripts/githooks/pre-commit`、`scripts/githooks/claude-md-max-bytes` 整檔；`tests/test-gate.sh` 的檔頭到 helper 與 ⑯ 整節；
  `ci.yml` 的 ShellCheck 清單與新 step；`scripts/githooks/CLAUDE.md` 整檔；`tests/CLAUDE.md` 那一列新增的文字與「此層約束」新增的那一條（都帶行號或折行）
- 第 4 部分：已跑過的驗證 V1–V9（整份測試在 macOS `/bin/bash` 3.2.57 與 ubuntu:24.04 容器、真 repo 直接跑、測試層級的變異對照與變異清單、本機照 ci.yml 逐 step 跑、CI 新 step 的負面測試、不經過 pre-commit 的 commit 實測、hook 壞掉的後果、步驟 3 的結果）

派工 prompt（逐字；prompt 裡的暫存目錄絕對路徑在這裡寫成 `<scratchpad>`，審查者拿到的是一句「先用 Read 讀這個檔，再照它寫的做」加這個檔的路徑）：

> 你是程式碼審查者。職責：找漏洞、每條附證據；沒證據的不算。不寫優點、不客套。
>
> repo：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。
> 審查範圍：`git diff a4d9185`（到工作目錄；8 步開發迴圈 S7 段落，HEAD = 808cf87，6 個 commit：2c3a277、7cc3289、12be2fd、694d06c、917f4df、808cf87；工作目錄乾淨、沒有未追蹤的檔）。這一段做的事：
> 根目錄 `CLAUDE.md` 加大小上限。新腳本 `scripts/githooks/claude-md-size.sh`（本 repo 自用、不部署）有兩種跑法：帶 `--staged` 由 `scripts/githooks/pre-commit` 在每次 commit 時跑（index 那一版比 `HEAD` 那一版大、而且超過上限才擋）；不帶參數由 CI 的新 step 跑（工作目錄那一份超過上限就不通過）。
> 上限寫在 `scripts/githooks/claude-md-max-bytes`（48000），取的是「最新 `v*` tag 那一版」的數字；那個 tag 沒有這個檔時，`--staged` 依序讀 `HEAD`、index，不帶參數讀工作目錄。現在最新的 tag `v1.6.14` 沒有這個檔。
> `tests/test-gate.sh` 檔尾加了 ⑯（情境 A–R，在拋棄式 repo 裡經過真的 pre-commit）；`.github/workflows/ci.yml` 加一個 step、ShellCheck 清單加一行；
> `scripts/githooks/CLAUDE.md`（新）、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md`、`docs/designs/2026-11-15-audit-fixes-design.md`（S7 一節與進度表）跟著改；根目錄 `CLAUDE.md` 只多一句進度表指路（段落標 DONE 的 commit 會刪掉）。
>
> 審查包（先讀它）：<scratchpad>/s7/review/pack.txt
> - 用 Read 的 `offset`/`limit` 每次 300 行，讀到最後一行（一次讀太多會靜靜截斷、不報錯）。共 1832 行。
> - 第 1 部分是整段 diff；第 2 部分是步驟 3（code-simplifier）的結果（它沒有改任何檔）；第 3 部分是被改到的程式碼與 `scripts/githooks/CLAUDE.md` 在派工當下的內容（帶行號），另有 `tests/CLAUDE.md` 那一列新增的文字（那一行在 diff 裡太長，Read 會截斷）；第 4 部分是已經跑過的驗證與預期值。
> - 被改到的檔以審查包第 3 部分為準；沒放進審查包的部分與其他檔直接讀工作目錄（步驟 4 期間沒有人改工作目錄）。
> - 第 4 部分的驗證已經確認過，不要重跑整份 `tests/test-gate.sh`、`tests/test-install.sh`，不要跑 docker。要驗一個想法，在拋棄式目錄裡做小實驗。
>
> 規則：
> - 只用手上的資料（讀檔、grep、git 紀錄、在拋棄式目錄裡的小實驗）判斷。需要上網、需要動到真實 `~/.claude`、或需要改這個 repo 的 git 狀態才查得到的，列在「需要外部查證」交回。
> - 不要改 repo 裡的任何檔；不要在這個 repo 裡 commit、打 tag、切分支、改 git 設定；不要跑 `./install-dd-pipeline.sh`。小實驗放在 <scratchpad>/s7/review/rc7-a/ 底下（拋棄式 repo 自己 `git init`，要用腳本就複製過去）。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 文件已經寫明的限制（`scripts/githooks/CLAUDE.md`「第 2 條擋不住的」「繞得過的路」兩段）不用再列成發現；但那兩段寫的內容不對、不全、或跟程式對不上，要列。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：腳本的邏輯。`scripts/githooks/claude-md-size.sh` 與 `scripts/githooks/pre-commit`，逐條分支看：各種 git 狀態下（還沒有任何 commit、沒有 tag、最新 tag 有／沒有上限檔、detached HEAD、linked worktree、從子目錄跑、`git commit -a`／指定路徑、merge 衝突解完之後的 commit、`--amend`、CLAUDE.md 被刪掉或改名、CLAUDE.md 或上限檔是 symlink）它量的是哪一份、上限取自哪裡、exit code 是多少；註解與 `scripts/githooks/CLAUDE.md` 說「一律不通過」的每一條路是不是真的不通過，包含它呼叫的指令自己失敗的時候（`git tag`、`git show`、`git cat-file`、`wc`、`grep`）；上限檔的各種內容（CRLF、前導 0、前後空白、BOM、負號、超大數字、`#` 前面有空白）在 `/bin/bash` 3.2 與 bash 5 各會怎樣；`v*` 這個樣式加 `--sort=-v:refname` 選到的是不是「最新發版」。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體輸入 → 錯的輸出）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

審查者交回的原文（逐字；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 1 / Smells 2 — 範圍：`git diff a4d9185`（HEAD 808cf87）；我只看了 `scripts/githooks/claude-md-size.sh`、`scripts/githooks/pre-commit` 的邏輯，以及 `scripts/githooks/CLAUDE.md` 裡講這兩支行為的段落。
>
> 【發現】
>
> 1｜Important｜只要本機有一個 `v*` tag，就能讓 pre-commit 改用調高後的上限；`git tag --list 'v*'` 會收任何 `v` 開頭的 tag，而且 `v` 加字母的 tag 排在所有版本號前面。這兩條路在「繞得過的路」都沒寫｜
> 證據：`scripts/githooks/claude-md-size.sh:45` 的原文是 `tag=$(git tag --list 'v*' --sort=-v:refname | head -1)`，讀的是本機所有 tag，沒有要求 tag 已經 push，也沒有要求長得像版本號。拋棄式 repo 實跑（`rc7-a/exp1.sh`，git 2.42.0，`/bin/bash` 3.2.57）的結果：
> - 情境一：v1.0.0 的上限是 100。先單獨 commit 把上限調成 1000，加字的 commit 被擋（`grow-before-tag rc=1`，「取自 v1.0.0」）。接著跑本機的 `git tag v1.0.1`，同一個加字的 commit 就放行（`根目錄 CLAUDE.md 50 → 500 bytes，上限 1000（取自 v1.0.1）`，`grow-after-localtag rc=0`）。
> - 情境二：建 `vendor-snap` 與 `v1.0.0-rc1` 兩個 tag 後，排序結果依序是 `vendor-snap`、`v1.0.0-rc1`、`v1.0.0`，上限因此印成「取自 vendor-snap」。｜
> 失敗情境：已經發過帶上限檔的版本之後，有兩種做法讓 pre-commit 照新的數字放行，不必真的發版：先 commit 調高上限，再在本機打任何一個 `v*` tag；或者打一個 `v` 開頭、不是版本號的 tag，它會被當成「最新發版」。這個 tag 如果跟著使用者平常的 `git push --tags` 推上去，CI 也會改用它。`scripts/githooks/CLAUDE.md:44` 寫「走第 1 條時，改了要等發下一版才生效」，`CHANGELOG.md` 也寫「在 commit 裡調高不會生效，要等發下一版」；兩處講成有保證，但實際上任何本機 tag 都算數。gate-guard 也不擋 `git tag`。｜
> 建議：在「繞得過的路」補上這一條（本機 tag 就算數，一起 push 上去 CI 也算數），或者把樣式收緊成只認版本號的 tag，例如 `v[0-9]*`。`ci.yml`「CHANGELOG 已發布區塊」那一步用的是同一個寫法，見 Not reported。
>
> 2｜Smells｜「繞得過的路」少了兩條會跳過 pre-commit 的路：CLAUDE.md 換成 symlink，以及 `git am`｜
> 證據：`claude-md-size.sh:83` 的原文是 `new=$(git cat-file -s ":${DOC}" 2>/dev/null) || new=0`，量的是 index 裡的 blob。CLAUDE.md 是 symlink 時，這個 blob 是連結目標的路徑字串。實跑結果：
> - 把 CLAUDE.md 換成指向 500 bytes 檔案的 symlink 再 commit，hook 放行（`commit rc=0`，`HEAD size: 6`）；不帶參數那一種會擋（`❌ 根目錄 CLAUDE.md 500 bytes，超過上限 100`，rc=1），因為 `wc -c <` 會跟著連結讀到目標。
> - 用 `git am` 套一個讓 CLAUDE.md 變成 500 bytes 的 patch，結果是 `am rc=0 HEAD size: 500`，大小檢查沒有跑。｜
> 失敗情境：這兩條路在本機都不會被擋，要等 push 之後 CI 才擋。`scripts/githooks/CLAUDE.md:54-59` 的清單沒有這兩條，讀的人會以為列出來的已經是全部。｜
> 建議：在清單補這兩條，都寫成「要等 push 時 CI 擋」。
>
> 3｜Smells｜說明寫「取不到上限、上限檔不合法時一律不通過」，但 `--staged` 只在 CLAUDE.md 變大時才去取上限，沒變大就直接放行｜
> 證據：`claude-md-size.sh:14` 的原文是「取不到上限或內容不合法一律不通過」；`scripts/githooks/CLAUDE.md:63` 的標題是「取不到上限、上限檔不合法時一律不通過」；同檔 `:24` 那一列寫「變大、而且超過上限；或取不到上限」。可是 `claude-md-size.sh:86` 是 `[ "$new" -le "$old" ] && exit 0`，這一行排在 `resolve_limit` 前面。｜
> 失敗情境：上限檔被刪掉或改壞之後，只改別的檔、或讓 CLAUDE.md 變小的 commit，pre-commit 照樣放行（情境 A 的「第一個 commit 不帶它 → 放行」、P 的「只改別的檔 → 放行」就是這個行為）。同檔 `:23` 與 `:68-69` 有寫清楚，但 `:24` 那一列讀起來像是一個獨立的不通過條件，`:14` 與 `:63` 的「一律」也把範圍講大了。｜
> 建議：`:24` 改成「變大時：超過上限，或取不到上限」，`:14` 與 `:63` 補上「（`--staged` 只在變大時）」。
>
> 【Not reported】
> - 上限檔內容的各種寫法：CRLF（`\r`）、BOM、前後空白、`#` 前面有空白、負號、`+`，都會被 `:34` 的 `*[!0-9]*` 判成不合法，結果是不通過。前導 0：`/bin/bash` 3.2.57 實測 `[ 100 -gt 0099 ]`、`[ 100 -gt 08 ]` 都照十進位比，不是八進位。12 位上限：`[ 100 -gt 999999999999 ]` 回 1，沒有報錯。
> - 還沒有任何 commit（HEAD 不存在）、detached HEAD、linked worktree、從子目錄跑、`commit -a`／指定路徑：讀程式都沒問題。`:24-25` 會先 cd 到 toplevel；`<rev>:path` 不帶 `./` 時本來就從根目錄算；`GIT_INDEX_FILE` 那一點有情境 N 實跑過。
> - merge 衝突解完之後的 commit：比的是 HEAD（ours）。合進來的那一邊已經超過上限時，hook 會擋，CI 也會擋，行為一致。`--amend` 比的是被 amend 的那個 commit，連續 amend 也繞不過上限。
> - CLAUDE.md 被刪掉或改名：`--staged` 時 new=0，放行；不帶參數時 exit 1。兩者都跟表格寫的一致。
> - 上限檔是 symlink：tag 或 HEAD 那一版讀到的是連結字串，判成不合法、不通過；工作目錄那一版會跟著連結讀。兩邊不一致，但都是擋下，不是放行。
> - 呼叫的指令自己失敗時：`git show` 失敗得到空字串，判成不合法、不通過；`grep` 失敗也得到空字串、不通過；`git tag` 失敗會被當成「還沒有 v* tag」退回 HEAD 或工作目錄，但 CI 那一步先查過有沒有 tag；`wc` 讀不到檔時 `$(( ))` 得 0、會放行，前提是工作目錄的 CLAUDE.md 不可讀，git checkout 不會造出這種狀態，所以不列。
> - `v1.0.0-rc1` 排在 `v1.0.0` 前面：這是 versionsort 預設的行為，repo 裡沒有 rc tag，不列。
> - `ci.yml` 的 CHANGELOG step 也用同一個 `v*` 寫法：那是既有的程式，不是這次 diff 加的，所以只把它當作發現 1 的背景。這個 repo 現在只有 `v1.6.x` 系列與 `pre-prune-2026-08-04`（後者不符合 `v*`），所以眼前沒有觸發。
> - 文件已經寫明的限制（`--no-verify`、發版前分兩個 commit、cherry-pick／merge／rebase／revert）沒有重複列。
>
> 【What I ran】
> - Read `prompt-a.txt`（全文）。Read `pack.txt` 第 1–300 行（diff 與設計段落）。被改到的程式直接讀工作目錄，內容與審查包第 3 部分相同。
> - `cat -n scripts/githooks/{claude-md-size.sh,pre-commit,claude-md-max-bytes,CLAUDE.md}` → 分別是 120、7、4、119 行。
> - `git tag --list 'v*' --sort=-v:refname | head -5` → v1.6.14、v1.6.13、v1.6.12、v1.6.11、v1.6.10。`git tag | grep -v '^v[0-9]'` → pre-prune-2026-08-04。`git --version` → 2.42.0。`grep -n fetch-depth ci.yml` → 第 18、582 行是 `fetch-depth: 0`。
> - `/bin/bash rc7-a/exp1.sh rc7-a/r1`（拋棄式 repo，上限 100，gate 換成 `exit 0`）→ symlink：commit rc=0、不帶參數 rc=1；本機 tag：打 tag 前 rc=1、打 tag 後 rc=0；`vendor-snap` 排第一，印「取自 vendor-snap」；`git am` 後 rc=0、HEAD 的 CLAUDE.md 是 500 bytes。
> - `/bin/bash rc7-a/nums.sh` → 3.2.57：0099 與 08 都照十進位比，12 位數回 1。
>
> 【需要外部查證】
> - bash 5 下前導 0 與 12 位數的行為：這台機器沒有 `/opt/homebrew/bin/bash` 和 `/usr/local/bin/bash`，所以沒有跑。要跑就在 ubuntu:24.04 容器執行 `bash rc7-a/nums.sh`，結果決定 bash 5 是否同樣照十進位比（我推測會，依據是 bash 的 test 用 strtoimax 以十進位解析，但沒有驗證）。

## 處置

- **1（Important，本機打一個 `v*` tag 就算；`v` 開頭但不是版本號的 tag 排在最前面）**：採納，級別沿用。與 `S7-b.md` 的 1、`S7-c.md` 的 1、`S7-d.md` 的 1 是同一件事。
  自己重跑它的實驗腳本（另開一個拋棄式 repo，git 2.42.0、`/bin/bash` 3.2.57）結果相同：調高上限檔的 commit 之後，加字的 commit rc=1、印「取自 v1.0.0」；`git tag v1.0.1` 之後同一個改動 rc=0、印「上限 1000（取自 v1.0.1）」。
  `vendor-snap`、`v1.0.0-rc1`、`v1.0.0` 三個 tag 照 `--sort=-v:refname` 排出來就是這個順序，上限印「取自 vendor-snap」。
  處置是寫進文件、不改取 tag 的寫法；它建議的「樣式收緊成 `v[0-9]*`」沒有採納，理由在 `S7-judge.md` 的「處置」。改到的地方：
  `scripts/githooks/CLAUDE.md`「上限取自哪一版」補一段「最新的 `v*` tag 到底是什麼」、「調高上限」那句改成「要等下一個 `v*` tag」、「繞得過的路」加兩條（本機打一個 tag；`v` 開頭但不是這條 branch 發版的 tag）；
  `scripts/githooks/claude-md-size.sh` 檔頭加兩行講同一件事、第 1 條的括號改成「要等下一個 v* tag，也就是發下一版」；`CHANGELOG.md` 未發布那一條補「腳本認的是本機的 tag，分不出發版與打了一個 tag」。
- **2（Smells，「繞得過的路」少了 symlink 與 `git am`）**：採納。同一次重跑：CLAUDE.md 換成 symlink 的 commit rc=0、`HEAD` 那個 blob 是 6 bytes，不帶參數直接跑 rc=1（量到目標的 500 bytes）；`git am` rc=0、`HEAD` 的 CLAUDE.md 500 bytes、沒有任何大小檢查的輸出。
  兩條都補進「繞得過的路」；`git am` 併進「不經過 pre-commit 的 commit」那一條，並寫明那是試過的幾種、不是完整清單。
- **3（Smells，「一律不通過」把範圍講大了）**：採納。讀碼確認：`[ "$new" -le "$old" ] && exit 0` 排在 `resolve_limit staged` 前面，沒變大的 commit 不取上限。三處都改：
  腳本檔頭那句改成「要取上限的時候取不到、或內容不合法，一律不通過」並註明 `--staged` 只在變大時才取；`scripts/githooks/CLAUDE.md` 表格「不通過」那一列改成「變大的時候：超過上限，或取不到上限、取到的上限檔不合法」；
  那一節的標題改成「要取上限的時候取不到、或上限檔不合法：一律不通過」，第一條先講「要取上限的時候」是什麼時候。`CHANGELOG.md` 的同一句也跟著改（這一處是我照判準掃出來的，不在它的清單裡）。
- **需要外部查證（bash 5 對前導 0 與 12 位數的比法）**：查了。`docker run --rm ubuntu:24.04` 跑它的 `nums.sh`：bash 5.2.21 印出的三行與 3.2.57 相同（`0099`、`08` 照十進位比；12 位數回 1、沒有報錯）。
- Not reported 裡它判斷不列的幾項（上限檔是 symlink 時 tag 與工作目錄兩邊讀到的不一樣但都是擋下、`wc` 讀不到檔時會放行但 checkout 造不出那種狀態、`v1.0.0-rc1` 排在 `v1.0.0` 前面）：沒有另外處理；最後一項寫進了「繞得過的路」的第二條新條目。
