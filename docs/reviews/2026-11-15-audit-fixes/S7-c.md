# S7 審查 — C（文件裡的宣稱）

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
> - 不要改 repo 裡的任何檔；不要在這個 repo 裡 commit、打 tag、切分支、改 git 設定；不要跑 `./install-dd-pipeline.sh`。小實驗放在 <scratchpad>/s7/review/rc7-c/ 底下（拋棄式 repo 自己 `git init`，要用腳本就複製過去）。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 文件已經寫明的限制（`scripts/githooks/CLAUDE.md`「第 2 條擋不住的」「繞得過的路」兩段）不用再列成發現；但那兩段寫的內容不對、不全、或跟程式對不上，要列。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：文件裡的宣稱。`scripts/githooks/CLAUDE.md`（整檔）、`tests/CLAUDE.md` 的 ⑯ 那一段與「此層約束」新增的那一條、`scripts/CLAUDE.md` 改的那一條、`DD_PIPELINE_ARCHITECTURE.md` 改的三處、`CHANGELOG.md` 新增的那一條、`scripts/githooks/claude-md-size.sh` 的檔頭與行內註解、`claude-md-max-bytes` 的註解、`ci.yml` 新 step 的註解、`tests/test-gate.sh` 檔頭與 ⑯ 節頭的註解、設計文件 S7 一節。逐句對程式碼與實測（審查包第 4 部分）：講行為的句子對不對、條件有沒有寫漏；指到別處的（節名、檔名、函式名、訊息字串、commit、tag）grep 得到嗎、指到的東西是不是它說的那個；同一件事在兩個地方的講法一不一致；同一份文件自己前後矛盾的地方。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體輸入 → 錯的輸出）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

審查者交回的原文（逐字；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 3 / Smells 6 — 範圍：`git diff a4d9185`（HEAD 808cf87，S7 段落），只審文件裡的宣稱（githooks/CLAUDE.md 整檔、tests/CLAUDE.md ⑯ 與此層約束、scripts/CLAUDE.md、架構文件、CHANGELOG、腳本與上限檔註解、ci.yml 註解、test-gate.sh 註解、設計文件 S7）
>
> 【發現】
> 1｜Important｜「繞得過的路」漏了一條：在本機打一個 `v*` tag，pre-commit 就改讀新上限。「調高要等發下一版才生效」這句因此不成立：本機打 tag 不必發版就能生效｜`scripts/githooks/claude-md-size.sh:492` `tag=$(git tag --list 'v*' --sort=-v:refname | head -1)` 只看本機有哪些 tag。`scripts/githooks/CLAUDE.md:44`「走第 1 條時，改了要等發下一版才生效」、第 54–59 行「繞得過的路」都沒寫到這條。拋棄式 repo 實跑：v1.0.0 上限 100 → 50→150 被擋（「取自 v1.0.0」）；接著 commit 上限 500，再 `git tag v1.0.1-tmp` → 同樣的 50→150 印「上限 500（取自 v1.0.1-tmp）」，rc=0，commit `grow2` 進了歷史｜失敗情境：commit 被擋 → `git tag v1.6.15-x`（不必 push）→ 下一個加字的 commit 放行，而且沒有任何警告。push tag 之後 CI 也照新 tag 的上限算｜建議：把這條補進「繞得過的路」與「第 1 條」的說明（hook 本身不防本機 tag）；CHANGELOG 那句「要等發下一版」改成「要等有新的 `v*` tag」
>
> 2｜Important｜「hook 擋不到、由 CI 補的」這張清單，四處講法不一致。917f4df 在 githooks/CLAUDE.md 補了「不經過 pre-commit 的 commit」，另外三處還是只列兩種｜`scripts/githooks/CLAUDE.md:58` 列了 cherry-pick、`merge --no-ff`、rebase、revert；但 `.github/workflows/ci.yml:549`「這裡補 hook 擋不到的（--no-verify、沒設 core.hooksPath 的 clone）」、`CHANGELOG.md:50`「補 hook 擋不到的（`--no-verify`、沒設 `core.hooksPath` 的 clone）」、`DD_PIPELINE_ARCHITECTURE.md:167`「這一步補它擋不到的：`--no-verify`、沒設 `core.hooksPath` 的 clone」都只列兩種，寫法也像是完整清單。同一檔的 `scripts/githooks/CLAUDE.md:26` 括號「（上限被調低，或超過的那個 commit 是用 `--no-verify` 進來的）」也漏了這一類｜失敗情境：讀架構文件或 ci.yml 的人，以為 cherry-pick、rebase 上來的 commit 本機會擋 → 實際上 V7 那四種都讓 HEAD 變成 150 bytes、大小檢查沒跑到｜建議：三處補上，或改成指到 githooks/CLAUDE.md「繞得過的路」，不要各自列舉
>
> 3｜Important｜「改完先跑 test-gate.sh，⑯ 跑這一層的三個檔」不對：⑯ 從來沒有用到 repo 裡真的 `claude-md-max-bytes`｜`scripts/githooks/CLAUDE.md:75`「所以改完先跑 `/bin/bash tests/test-gate.sh`（⑯ 在拋棄式 repo 裡跑這一層的三個檔）再 commit」，這一節標題是「改這三個檔之前」，三個檔含上限檔。第 84 行也寫「（`scripts/githooks/` 三個檔…）」。但 `tests/test-gate.sh:687-689` 只複製 `$HOOK`、`$SIZE_CHECK`、`$GATE`，上限檔由 `lim()`（第 697 行）自己寫。而且第 27 行明寫 pre-commit 不查上限檔本身｜失敗情境：把真的上限檔改成 `48,000` 或 13 位數 → commit 放行（只改上限檔時 pre-commit 什麼都不印），`test-gate.sh` 全綠 → 照這段做的人以為驗過了，要等 push 時 CI 的不帶參數模式才紅｜建議：寫明改上限檔時要驗的是直接跑 `scripts/githooks/claude-md-size.sh`（不帶參數），test-gate.sh 只涵蓋 hook 與大小檢查腳本
>
> 4｜Smells｜不排序時 `head -1` 拿到的是什麼，機制寫錯了：`git tag --list` 預設照 refname 字典序，不是照新舊｜`scripts/githooks/claude-md-size.sh:491`「不排序拿到的是最舊的」；`scripts/githooks/CLAUDE.md:96`「沒排序時 `head -1` 拿到最舊的 `v0.0.0`」。拋棄式 repo：先打 v2.0.0、後打 v1.0.0 → 不排序的 `head -1` 是 `v1.0.0`（後建的那個）｜失敗情境：⑯ 裡 v0.0.0 剛好既是最舊、也是字典序第一，所以結論對、理由錯；之後照這句去推別的 tag 組合會推錯｜建議：改成「不排序時照字典序，拿到字典序最前面的」
>
> 5｜Smells｜變異表「`--staged` 超過上限時的 `exit 1` 改 `exit 0`」那一列寫「C 起每一則該擋的 commit」，概括過頭了：P 的「CLAUDE.md 變大」照樣是綠的｜`scripts/githooks/CLAUDE.md:111`；V4 的 staged-noblock 清單沒有 P。P2 是在 `claude-md-size.sh:534` `resolve_limit staged || exit 1` 離開的，走不到被改的那個 exit｜失敗情境：重跑這個變異，看到 P2 綠，對照表格會誤判成回歸｜建議：寫「C 起每一則該擋的 commit，P 的『CLAUDE.md 變大』除外（它在取上限那一步就擋下）」
>
> 6｜Smells｜「要等 push 時 CI 擋」條件寫漏了：CI 只在 push 到 main 與開 PR 時跑｜`.github/workflows/ci.yml:3-7` `on: push: branches: [main]`、`pull_request`、`workflow_dispatch`；`scripts/githooks/CLAUDE.md:56-58` 三處寫「要等 push 時 CI 擋」｜失敗情境：push 到別的 branch、沒開 PR → 大小檢查不會跑｜建議：寫成「push 到 main 或開 PR 時」
>
> 7｜Smells｜「每次檢查都印出上限取自哪裡」跟程式對不上：`--staged` 在 CLAUDE.md 沒有變大時什麼都不印｜`CHANGELOG.md:53`「每次檢查都印出上限取自哪裡」、設計文件 S7 假設那句同樣寫法；`claude-md-size.sh:533` `[ "$new" -le "$old" ] && exit 0`；腳本檔頭第 14 行寫的是「每次取上限都印」，這句才對｜建議：CHANGELOG 改成「每次取上限都印」
>
> 8｜Smells｜「⑯ 在比對的字串」只列三個，沒說是舉例，實際比對的更多｜`scripts/githooks/CLAUDE.md:79` 只列「取自 …」「找不到上限檔」「上限檔內容不合法」；`tests/test-gate.sh` 還比對了「不存在或內容不合法」（854 等）、「找不到 CLAUDE.md」（847）、「先問使用者」（723，在 `advice()` 裡）、「發下一版之後才生效」（842、851）、「X → Y bytes，上限」格式｜失敗情境：改 `advice()` 的措辭 → ⑯ 變紅（會報錯，不會靜靜過關）｜建議：寫「例如」，或改成指向 `grep -n 'said\|not_said' tests/test-gate.sh`
>
> 9｜Smells｜上限檔的格式說明與錯誤訊息都沒提 12 位上限｜`scripts/githooks/claude-md-max-bytes:3`「其餘要剛好一行整數」；`claude-md-size.sh:517` 錯誤訊息同一句；只有 `scripts/githooks/CLAUDE.md:10` 寫了「最多 12 位」｜失敗情境：寫 13 位數 → 印「上限檔內容不合法…其餘要剛好一行整數」，可是內容確實是一行整數，從訊息看不出原因
>
> 10｜Smells｜指標指錯地方：`tests/test-gate.sh:677`「代號 A–R 對應 scripts/githooks/CLAUDE.md「情境與變異對照」那張表」，但那張表是變異表，沒有定義 A–R 各代表什麼。代號的定義在 `tests/CLAUDE.md:11` 與設計文件｜建議：改成指到 `tests/CLAUDE.md`
>
> 【Not reported】
> - 變異對照表其餘 19 列逐列對了 V4 的清單，「直接紅」與連鎖的分法都一致（例外只有發現 5）
> - `tests/CLAUDE.md` 的 `grep -nE '^# [A-R](、[A-R])? '` 實跑剛好命中 17 行，是 A 到 R 的節頭，沒有誤命中
> - githooks/CLAUDE.md:36 說跟 CHANGELOG 那一步「同一個寫法」：ci.yml:178、418 確實是同一行
> - githooks/CLAUDE.md:46-47：v1.6.14 是最新的 tag，`git cat-file -e` 實跑 rc=128，跟文件說的一致
> - githooks/CLAUDE.md:56：gate-guard 確實也擋 `-n`（guard-no-verify.sh:2、126）
> - 表格三列、第 26–30 行、12 位那段、tag 上限檔不合法時不退回 HEAD，都對過程式碼
> - CHANGELOG 條目確實在 `## 未發布` → `### Added` 底下（第 19、21 行）
> - tests/CLAUDE.md 此層約束說「⑫–⑮ 各開各的 repo」，與表格那一列的描述相符
> - 既有問題、不是這次 diff 引入的：gate-guard 擋下時的訊息叫人改用 `SKIP_DOC_CHECK=1`（guard-no-verify.sh:209）。被大小檢查擋下時，照做會再被擋一次。不會靜靜放行，而且不在這次 diff 範圍內
> - 既有問題、不是這次 diff 引入的：`CHANGELOG.md:627` 已發布區塊仍描述舊的 pre-commit（只 exec gate）。已發布區塊依規不可改
> - scripts/CLAUDE.md:72「pre-commit 收到 0 個參數」：exec gate 時仍不帶參數，這句還成立
>
> 【What I ran】
> - Read 審查包 pack.txt 第 1–600、601–900、1000–1300、1300–1500、1500–1832 行（第 900–1000 行是 claude-md-size.sh 全文，第 1 部分 diff 已含同樣內容，沒有另讀）
> - `grep -nE '^# [A-R](、[A-R])? ' tests/test-gate.sh` → 17 行，第 699–889 行
> - `grep -n "sort=-v:refname" .github/workflows/ci.yml` → 第 178、418 行
> - 讀 ci.yml 開頭的 `on:` → push 只限 main、pull_request、workflow_dispatch
> - `grep` guard-no-verify.sh → 第 2、126、209 行
> - `git tag --list 'v*' --sort=-v:refname | head -3` → v1.6.14/v1.6.13/v1.6.12；`git cat-file -e v1.6.14:scripts/githooks/claude-md-max-bytes` → rc=128
> - 拋棄式 repo（rc7-c/t2）：先打 v2.0.0、後打 v1.0.0 → 不排序的 `head -1` 是 v1.0.0
> - 拋棄式 repo（rc7-c/t1，複製真的 pre-commit、claude-md-size.sh、gate）：50→150 被擋（取自 v1.0.0）；commit 上限 500 並 `git tag v1.0.1-tmp` 之後，50→150 rc=0（取自 v1.0.1-tmp），commit 進了歷史
> - `git grep -n githooks`、`git grep -nE 'hook 擋不到|擋不到的'`（排除 docs/reviews）→ ci.yml:549、CHANGELOG.md:50、架構文件:167 三處只列兩種
> - `grep -nE '^## |^### ' CHANGELOG.md`；`grep -n '0 個參數' scripts/CLAUDE.md`
>
> 【需要外部查證】無

## 處置

它的第 1 行寫「Smells 6」，實際列出的 Smells 是 7 條（4–10）；下面照它列出來的逐條處理。它引的 `claude-md-size.sh:491`、`:492`、`:517`、`:533`、`:534` 是審查包裡的行號（腳本本身 120 行），我用它引的原文定位。

- **1（Important，本機打一個 `v*` tag）**：採納，級別沿用。與 `S7-a.md` 的 1 是同一件事，實跑的證據與改了什麼寫在那裡。它建議 CHANGELOG 那句改成「要等有新的 `v*` tag」：照改。
- **2（Important，「hook 擋不到、由 CI 補的」四處講法不一致）**：採納，級別沿用。與 `S7-d.md` 的 2 是同一件事。`git grep` 確認三處（`ci.yml` 新 step 的註解、`CHANGELOG.md` 未發布那一條、`DD_PIPELINE_ARCHITECTURE.md` CI 防線表那一列）都只列兩種。
  三處都改成「…、cherry-pick／merge／rebase 這類不經過 pre-commit 的 commit；清單在 `scripts/githooks/CLAUDE.md`「繞得過的路」」，不各自列完整清單；
  `scripts/githooks/CLAUDE.md`「已經超過上限時」的括號改成「超過的那個 commit 沒經過這支 hook —— 見下面『繞得過的路』」。這是我在 `917f4df` 只補一處造成的，記在 `S7-judge.md`「這一段自己犯的錯」。
- **3（Important，「⑯ 跑這一層的三個檔」不對）**：採納，級別沿用。讀 `tests/test-gate.sh` ⑯ 開頭確認：複製進拋棄式 repo 的是 `$HOOK`、`$SIZE_CHECK`、`$GATE`，上限檔由 `lim()` 自己寫，repo 裡那一份沒有用到。
  `scripts/githooks/CLAUDE.md`「改這三個檔之前」那句改成「⑯ 跑的是 `pre-commit` 與 `claude-md-size.sh`；上限檔是測試自己寫的」，另加一條「改上限檔之後直接跑一次不帶參數的 `claude-md-size.sh`」；「情境與變異對照」開頭講配置的括號也改成分開講哪些是複製的、哪個是測試寫的。
- **4（Smells，不排序的機制寫錯）**：採納。與 `S7-b.md` 的 3 是同一件事，實跑與改法寫在那裡。
- **5（Smells，變異表那一列「C 起每一則該擋的 commit」概括過頭）**：採納。核對 scratchpad 裡那次變異實測的清單：`staged-noblock` 變紅的沒有 P 的任何一則。那一列改成「C 起該擋的 commit（含連鎖）；P 的『CLAUDE.md 變大』除外，它在取上限那一步就擋下、走不到這一行」。
- **6（Smells，「要等 push 時 CI 擋」漏了條件）**：採納。讀 `ci.yml` 開頭確認觸發只有 push 到 `main`、`pull_request`、`workflow_dispatch`。「繞得過的路」開頭加一句講明「等 CI 擋」指什麼、什麼時候才跑，各條改成「要等 CI 擋」；
  設計文件 S7 講同一件事的三句、`CHANGELOG.md` 那一條也補上條件（這幾處是照判準掃出來的）。
- **7（Smells，「每次檢查都印出上限取自哪裡」跟程式對不上）**：採納。`CHANGELOG.md` 與設計文件 S7 假設那句都改成「每次取上限都印出取自哪裡」。
- **8（Smells，「⑯ 在比對的字串」只列三個）**：採納。改成指到指令：`sed -n '/^# ⑯/,$p' tests/test-gate.sh | grep 'said '`（實跑有輸出），並點名 `advice()` 裡的「先問使用者」也在內。
- **9（Smells，上限檔的格式說明與錯誤訊息沒提 12 位）**：採納。`claude-md-max-bytes` 的格式說明、腳本「上限檔內容不合法」那句訊息都補「最多 12 位」，設計文件裡上限檔內容的引文同步。
  訊息改字之後整份 `tests/test-gate.sh` 照樣 rc=0（⑯ 比對的是那句的前半）；改完直接跑不帶參數的那一種，印 ✅、rc=0。
- **10（Smells，測試檔註解說 A–R 對應變異表）**：採納。`tests/test-gate.sh` ⑯ 檔頭那句改成「代號 A–R 的清單在 tests/CLAUDE.md（test-gate.sh 那一列）；變異表用同一組代號」。
- Not reported 裡的兩件既有問題：gate-guard 擋下 `--no-verify` 時提示改用 `SKIP_DOC_CHECK=1`，而這個變數不跳過大小檢查（結果仍是擋下；gate-guard 是部署內容，這一段不動）；`CHANGELOG.md` 已發布區塊對舊 pre-commit 的描述（已發布區塊不可改）。兩件都不處理。
