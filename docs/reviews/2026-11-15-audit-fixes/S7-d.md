# S7 審查 — D（整合、同步點、發版之後）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S7（根目錄 CLAUDE.md 大小上限，pre-commit 與 CI 都擋）。

## 派工

`code-reviewer`，不帶 model 參數，與另外三個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s7/review/pack.txt`，1832 行，沒進 repo）的組成：
- 第 1 部分：`git diff e4ec5cc`（表上這段的起點到工作目錄；HEAD = 8e91309，工作目錄乾淨、沒有未追蹤的檔）
- 第 2 部分：步驟 3（code-simplifier）跑了，沒有改任何檔（主對話用 `cmp` 核對過）
- 第 3 部分：`scripts/githooks/claude-md-size.sh`、`scripts/githooks/pre-commit`、`scripts/githooks/claude-md-max-bytes` 整檔；`tests/test-gate.sh` 的檔頭到 helper 與 ⑯ 整節；
  `ci.yml` 的 ShellCheck 清單與新 step；`scripts/githooks/CLAUDE.md` 整檔；`tests/CLAUDE.md` 那一列新增的文字與「此層約束」新增的那一條（都帶行號或折行）
- 第 4 部分：已跑過的驗證 V1–V9（整份測試在 macOS `/bin/bash` 3.2.57 與 ubuntu:24.04 容器、真 repo 直接跑、測試層級的變異對照與變異清單、本機照 ci.yml 逐 step 跑、CI 新 step 的負面測試、不經過 pre-commit 的 commit 實測、hook 壞掉的後果、步驟 3 的結果）

派工 prompt（逐字；prompt 裡的暫存目錄絕對路徑在這裡寫成 `<scratchpad>`，審查者拿到的是一句「先用 Read 讀這個檔，再照它寫的做」加這個檔的路徑）：

> 你是程式碼審查者。職責：找漏洞、每條附證據；沒證據的不算。不寫優點、不客套。
>
> repo：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。
> 審查範圍：`git diff e4ec5cc`（到工作目錄；8 步開發迴圈 S7 段落，HEAD = 8e91309，6 個 commit：f53d11a、1b33cae、d0e72b1、abf3d18、83c18ee、8e91309；工作目錄乾淨、沒有未追蹤的檔）。這一段做的事：
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
> - 不要改 repo 裡的任何檔；不要在這個 repo 裡 commit、打 tag、切分支、改 git 設定；不要跑 `./install-dd-pipeline.sh`。小實驗放在 <scratchpad>/s7/review/rc7-d/ 底下（拋棄式 repo 自己 `git init`，要用腳本就複製過去）。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 文件已經寫明的限制（`scripts/githooks/CLAUDE.md`「第 2 條擋不住的」「繞得過的路」兩段）不用再列成發現；但那兩段寫的內容不對、不全、或跟程式對不上，要列。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：整合、同步點、發版之後。`.github/workflows/ci.yml` 的改動（新 step 放的位置、`run: |` 的寫法、淺 clone 那道檢查、PR 觸發時 checkout 到的是什麼、ShellCheck 清單）；專案各層 CLAUDE.md 規定「加一個東西要同時改哪幾處」的規則（搜「新增」「同時改」「同批」「要一起」「手動同步」），逐條對這一段有沒有漏；下一次發版（打一個帶上限檔的 `v*` tag）之後行為會怎麼變 —— 照腳本推一遍打 tag 前後各一個 commit 的結果，再看文件（含 `CHANGELOG.md` 檔頭的發版步驟、`UPGRADING.md`、兩份 README）有沒有哪裡該講而沒講、或講的跟你推出來的不一樣；根目錄 `CLAUDE.md` 那句指路刪掉之後，有沒有別的檔引用了會跟著消失的東西；`scripts/githooks/` 不部署 —— 安裝腳本、`tests/test-install.sh`、CI 的「陣列與目錄一致性」「部署內容裡的 ~/.claude/ 路徑要指得到東西」對新檔有沒有意外的影響；`templates/global/CLAUDE.md` §3.9「寫一個『擋誤用』或『讓 X 可偵測』的機制之前，先驗三件事」那一條，逐項對這個機制。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體輸入 → 錯的輸出）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

審查者交回的原文（逐字；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 3 / Smells 0 — 範圍：`git diff e4ec5cc`（HEAD 8e91309），方向是整合、同步點、發版之後
>
> 【發現】
> 1｜Important｜上限的出處是「任何一個版本號最大的 `v*` tag」。腳本不檢查這個 tag 是不是 HEAD 的祖先，也不檢查它是不是真的發過版。所以「在 commit 裡調高不會生效，要等發下一版」這個保證，打一個 tag 就能繞過。「繞得過的路」那一節沒有列這一條｜`scripts/githooks/claude-md-size.sh:492` `tag=$(git tag --list 'v*' --sort=-v:refname | head -1)`，接著 `:498` 直接 `git cat-file -e "${tag}:${LIMIT_FILE}"`，中間沒有 ancestry 檢查。`scripts/githooks/CLAUDE.md:54-59` 的清單沒有這一條。我在拋棄式 repo 實跑：main 的上限檔是 100；在 side 分支把上限調成 9999、打 `v1.0.1-wip`，再切回 main。`merge-base --is-ancestor` 回 1（不是祖先），可是 main 上讓 CLAUDE.md 50→500 的 commit rc=0，印「上限 9999（取自 v1.0.1-wip）」。不帶參數那一種也 rc=0，另外印「工作目錄的上限檔寫 100，發下一版之後才生效」，這句會誤導｜發版之後，被擋下的人（或 Claude；gate-guard 不管 `git tag`）在任何分支上 commit 一個調高的上限檔，再 `git tag v1.6.99`，之後每個加字的 commit 都會放行。發版步驟（`CHANGELOG.md` 第 4 步）是 `git push origin main --tags`，這個 tag 會一起推上去，CI 也會拿它當上限｜至少把這條寫進「繞得過的路」。要擋的話，只接受 HEAD 的祖先 tag（`git describe --tags --abbrev=0 --match 'v*'`，或加 `merge-base --is-ancestor`）
> 2｜Important｜83c18ee 把「不經過 pre-commit 的 commit」（cherry-pick、`merge --no-ff`、rebase、revert）補進了 `scripts/githooks/CLAUDE.md`，可是另外三處講同一件事的地方還是只列兩種，讀起來像完整清單｜`scripts/githooks/CLAUDE.md:58` 有四種 git 操作。`DD_PIPELINE_ARCHITECTURE.md:167` 寫「這一步補它擋不到的：`--no-verify`、沒設 `core.hooksPath` 的 clone」；`CHANGELOG.md:50` 寫「補 hook 擋不到的（`--no-verify`、沒設 `core.hooksPath` 的 clone）」；`.github/workflows/ci.yml:549` 寫「這裡補 hook 擋不到的（--no-verify、沒設 core.hooksPath 的 clone）」。`git grep` 確認這三處都沒有 cherry-pick、merge、rebase 等字｜讀 CI 防線表的人會以為本機 merge 或 rebase 進來的 commit 已經被 pre-commit 擋過，其實沒有跑到（V7 實測），要等 push 時 CI 才擋｜三處都補上「不經過 pre-commit 的 commit（cherry-pick／merge --no-ff／rebase／revert）」，或改成「完整清單見 `scripts/githooks/CLAUDE.md`『繞得過的路』」
> 3｜Important｜pre-commit 改成「先跑大小檢查、最後才 `exec` gate」之後，`/dd-init` Phase 3 的位置判定會把這支 hook 判成「gate 不在正確位置」，要求把 gate 搬到最前面。根目錄 CLAUDE.md 那句「兩者不衝突」不再成立。這一條是讀規則推出來的，沒有實跑 `/dd-init`｜`commands/dd-init.md:274-276`：「已含 → **看位置，不看有沒有這串字**：gate 呼叫在…shebang 與註解之後…才算裝好；不是…就搬到那個位置」。現在的 `scripts/githooks/pre-commit:5-7`，gate 前面多了 `top=…` 與大小檢查兩行；S7 之前 `exec` gate 緊接在註解後面，判定是「已裝好」。`CLAUDE.md:170-171`：「`/dd-init` Phase 3 會偵測此設定並改掛到 hooksPath 目錄，兩者不衝突」｜在本 repo 跑 `/dd-init`：掛載點是 `scripts/githooks/pre-commit`（進版控的檔）。照字面把 `exec …check-claude-md.sh` 搬到 shebang 與註解之後，`exec` 一執行就換掉行程，後面的大小檢查永遠跑不到，而且不報錯。如果搬的時候沒帶 `top=`，則是每個 commit 都失敗｜把根目錄那句改掉，或在 `scripts/githooks/CLAUDE.md` 寫明「本 repo 不要跑 `/dd-init` Phase 3；它的位置規則會把大小檢查變成死碼」
>
> 【Not reported】
> - 發版前後的行為，我照腳本推了一遍：v1.6.15 打在 CHANGELOG 整理的那個 commit 上（那時上限檔已經是 48000）。打 tag 前，`--staged` 走 HEAD 那一版、CI 走工作目錄那一份；打 tag 後兩種都走 `取自 v1.6.15`，數字一樣，只有「取自 …」那一段字變了。`CHANGELOG.md` 檔頭的發版步驟、`UPGRADING.md`、兩份 README 不需要因此多寫什麼（這一層不部署，也不影響使用者）
> - CI 的 `push` 與 `pull_request` 觸發：`fetch-depth: 0` 會帶 tag。PR 量的是 merge ref 的工作目錄，也就是合併後的結果。新 step 放在 lint job 的測試步驟之前，`run: |` 裡沒有 heredoc。ShellCheck 那一行插在清單中間、行尾有反斜線，V6 ④ 已經證明它有承重
> - 新檔對安裝與其他 CI 檢查沒有意外影響：`create_scripts()` 只部署 `DD_SCRIPTS`（`install-dd-pipeline.sh` 1190 行起）；「陣列與目錄一致性」用 `ls scripts/*.sh`，不往子目錄找（`ci.yml:90-93`）；`scripts/githooks/*` 裡沒有 `.claude/` 路徑（grep rc=1），所以「~/.claude/ 路徑要指得到東西」那一步碰不到它們；`test-install.sh` 也沒有提到 githooks
> - 根目錄的指路句刪掉之後：沒有別的檔引用那一句。46554、46424 這兩個數字只出現在設計文件的歷史紀錄裡
> - 各層 CLAUDE.md 的「同批」規則我逐條對過，都做了：新增 Script 步驟的第 1、3 步（ShellCheck 清單、架構文件的「12 支腳本」）；第 2、4 步因為這一層不部署而不適用（`CLAUDE.md:135`）。另外 CI 防線表、CHANGELOG 的未發布區塊、bash32 的行為測試（在 test-gate ⑯ 裡）、新 step 的負面測試也都有
> - 在 S7 之前分出來的 branch 上 commit 不會跑大小檢查：本 repo 現在只有 main（`git branch -a`），理論上存在、實際沒有，所以不列
> - `v1.0.2-rc1` 這種 tag 會排在 `v1.0.2` 前面（實測）：repo 從來沒用過預發布 tag，不列
> - gate-guard 擋下 `--no-verify` 時提示改用 `SKIP_DOC_CHECK=1`，而這個變數不跳過大小檢查：結果仍然是擋下，不是繞過；那段訊息也不在這次的 diff 裡
> - 全域模板 §3.9「擋誤用」那條的三項：①hook 與腳本都在 main 的工作目錄裡，存在 ②只有發版前，基準取自被稽核的對象（HEAD 或工作目錄），這個缺口已寫明；發版後的問題是上面第 1 條 ③沒有後置動作，不適用
>
> 【What I ran】
> - Read `prompt-d.txt` 全檔；`pack.txt` 第 1–899、1000–1833 行（中間 900–999 是腳本整檔，內容跟 diff 相同，所以跳過）
> - `sed -n 1,22p` 讀 ci.yml 開頭，再 grep 它的 fetch-depth、checkout、`tag --list` → `fetch-depth: 0` 在第 18、582 行；觸發是 push main、`pull_request`、`workflow_dispatch`
> - `git grep` 兩種繞過寫法的那串字 → 三處只列兩種（第 2 條）；`git grep githooks`（排除 docs/reviews、docs/designs、CHANGELOG）→ 沒有意外的引用
> - grep `guard-no-verify.sh` → 會擋 `--no-verify`／`-n`／`core.hooksPath`
> - `grep '\.claude/' scripts/githooks/*` → rc=1；讀 `ci.yml:80-100`；grep `create_scripts` 與 `test-install.sh` 裡的 githooks、scripts/
> - 讀 `commands/dd-init.md:196-280`（Phase 3 的位置規則）、`CLAUDE.md:160-175`、`CHANGELOG.md:1-20`
> - `git tag --sort=-v:refname` → 最新是 v1.6.14；另外有 `pre-prune-2026-08-04`
> - grep 兩份 README 與 UPGRADING 的 hooksPath、dogfood、`SKIP_DOC_CHECK` → 只講到 gate，沒有要同步的地方
> - `git branch -a` 與 `git worktree list` → 只有 main，而且含 f53d11a
> - `grep -nE '^# [A-R]…' tests/test-gate.sh` → 17 行，對得上 A–R
> - 拋棄式 repo（rc7-d/r2，`git init -b main`）放真腳本：side 分支調高上限並打 tag，main 加字 → commit rc=0、取自 v1.0.1-wip，不帶參數那一種 rc=0。第一次實驗（rc7-d/r）因為預設分支是 master 而沒切回去，只拿它的排序結果：`v2-test` 會成為最新、`v1.0.2-rc1` 排在 `v1.0.2` 前面
>
> 【需要外部查證】
> - 第 3 條：在本 repo 的拋棄式複本裡實跑一次 `/dd-init` Phase 3，看模型會不會照「看位置」那一條搬動 `scripts/githooks/pre-commit`，用來確定實際後果是大小檢查變成死碼，還是每個 commit 都失敗

## 處置

它引的 `claude-md-size.sh:492`、`:498` 是審查包裡的行號，我用原文定位。

- **1（Important，上限的出處是「任何一個版本號最大的 `v*` tag」，不查是不是 `HEAD` 的祖先）**：採納，級別沿用。與 `S7-a.md` 的 1 是同一件事；「tag 不在這條 branch 的歷史上也算」是它獨有的部分。
  自己實跑（拋棄式 repo）：`main` 的上限檔 100、打 `v1.0.0`；`side` 分支把上限調成 9999、打 `v1.0.1`；切回 `main`，`git merge-base --is-ancestor v1.0.1 HEAD` 回 1，
  CLAUDE.md 50 → 500 的 commit rc=0、印「上限 9999（取自 v1.0.1）」，不帶參數直接跑也 rc=0。寫進「繞得過的路」。
  它建議的「只接受 `HEAD` 的祖先 tag（`git describe --tags --abbrev=0 --match 'v*'` 或 `merge-base --is-ancestor`）」沒有採納，理由在 `S7-judge.md` 的「處置」。
- **2（Important，另外三處還是只列兩種）**：採納，級別沿用。與 `S7-c.md` 的 2 是同一件事，改法寫在那裡。
- **3（Important，`/dd-init` Phase 3 的位置規則會把這支 hook 判成要搬）**：採納，級別沿用，但後果比它寫的輕一級。讀 `commands/dd-init.md`「已含」那條原文確認規則是看位置的
  （「gate 呼叫在上一條說的位置（shebang 與註解之後…）才算裝好；不是…就搬到那個位置」）；「照字面會被判成要搬」仍然是讀規則推出來的，沒有實跑 `/dd-init`。
  它寫搬了之後「大小檢查永遠跑不到，而且不報錯」：我把兩行對調的副本當 `tests/test-gate.sh` 的第三個參數實跑，rc=1、⑯ 從 A 起該擋的都變成「預期 block，實際 pass」——
  本機 commit 的確不會有訊息，但測試與 CI 的「gate 段落起點」那一步會紅。
  處置：`scripts/githooks/pre-commit` 檔頭加兩行註解（順序有承重、不要照那條規則搬）；`scripts/githooks/CLAUDE.md`「改這三個檔之前」加一條，只寫有證據的兩件事（照字面會被判成要搬：沒實跑；對調之後 ⑯ 會紅：實跑）。
  根目錄 CLAUDE.md 那句「`/dd-init` Phase 3 會偵測此設定並改掛到 hooksPath 目錄，兩者不衝突」沒有改：它講的是掛載位置（`.git/hooks/` 與 hooksPath 目錄），那一點仍然成立；而且這一段不往根目錄加字。
- **需要外部查證（在拋棄式複本實跑 `/dd-init` Phase 3）**：沒有做，列為沒驗證。理由：結果不會改變處置（兩種後果裡，「大小檢查變死碼」的已實跑、測試會紅；「每個 commit 都失敗」的本來就會當場看到），
  而要驗「模型照這條規則會不會搬」得開全新的 `claude -p` session 才算數。
- Not reported 裡的各項（發版前後照腳本推的行為、PR 觸發時量的是 merge ref、新檔對安裝與其他 CI 檢查沒有影響、各層「同批」規則逐條對過）：沒有要處理的。
