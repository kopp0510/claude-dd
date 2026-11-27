# S3 審查 — A（安裝腳本的邏輯）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S3（安裝腳本：`--check` 看得出部署版與 repo 不同）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s3-review-pack.txt`，627 行，沒進 repo）的組成：
- 第 1 部分：`git diff db8637e HEAD`（表上這段的起點到 HEAD = 420564e），工作目錄乾淨、沒有未追蹤的檔
- 第 2 部分：步驟 3（code-simplifier）跑了，沒有改任何檔
- 第 3 部分：`install-dd-pipeline.sh` 的 `check_builtin_skills`、`install_builtin_skills`、`check_builtin_agents`、`install_builtin_agents` 開頭、`--check` 的流程，與 `tests/test-install.sh` 的檔頭、`TEST_ONLY` 那一段、T11（都帶行號）
- 第 4 部分：已跑過的驗證 V1–V7（T11 先紅後綠、macOS 與 ubuntu 整份 rc=0、8 個變異各紅在哪、對真實環境跑 `--check` 的輸出、lint、照 ci.yml 逐 step 跑）

派工 prompt（逐字；prompt 裡的暫存目錄絕對路徑在這裡寫成 `<scratchpad>`，審查者拿到的是一句「先讀這個檔再照做」加這個檔的路徑）：

> 你是程式碼審查者。職責：找漏洞、每條附證據；沒證據的不算。不寫優點、不客套。
>
> repo：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。
> 審查範圍：`git diff db8637e HEAD`（8 步開發迴圈 S3 段落，2 個 commit：986bc79、420564e）。這一段做的事：
> `./install-dd-pipeline.sh --check` 的「檢查內建 Skills」「檢查內建 Agents」兩段，原本只看目錄／檔案在不在；現在目錄／檔案在的時候再跟 repo 這份比內容
> （skill 用 `diff -rq`、agent 用 `cmp -s`），不同就印「已安裝（與 repo 不同，重跑安裝會更新）」、段尾多一行「與 repo 不同：N」。只提示、不改檔、不影響結束碼。
> `tests/test-install.sh` 新增 T11；兩份 README、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md`、根目錄 `CLAUDE.md`、`tests/CLAUDE.md` 跟著改。
>
> 審查包（先讀它）：<scratchpad>/s3-review-pack.txt
> - 用 Read 的 `offset`/`limit` 每次 300 行，讀到最後一行（一次讀太多會靜靜截斷、不報錯）。共 627 行。
> - 第 1 部分是整段 diff；第 2 部分是步驟 3（code-simplifier）的結果；第 3 部分是被改到的程式碼在派工當下的相關段落（帶行號）；第 4 部分是已經跑過的驗證與預期值。
> - 被改到的程式碼以審查包第 3 部分為準；沒放進審查包的部分與其他檔直接讀工作目錄（步驟 4 期間沒有人改工作目錄）。
> - 第 4 部分的驗證已經確認過，不要重跑整份測試、不要跑 docker。
>
> 規則：
> - 只用手上的資料（讀檔、grep、git 紀錄、在拋棄式目錄裡的小實驗）判斷。需要上網、需要動到真實 `~/.claude` 才查得到的，列在「需要外部查證」交回。
> - **不要跑 `./install-dd-pipeline.sh`（任何參數）除非把 `HOME` 換成你自己建的拋棄式目錄**；不要在 zsh 裡 `source` 它（要取函式用 `bash -c 'source ./install-dd-pipeline.sh && <函式>'`，而且一樣先換 `HOME`）。不要改 repo 裡的任何檔、不要 commit。小實驗放在 <scratchpad>/rc3-a/ 底下。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：安裝腳本的邏輯。`check_builtin_skills`、`check_builtin_agents` 的新分支：跟安裝端（`install_builtin_skills`、`install_builtin_agents`）的比法與分支是不是一一對得上（它印「重跑安裝會更新」，重跑安裝真的會更新嗎；它沒印的，重跑安裝會不會其實也動到）；`set -e` 下每一條新指令回非 0 時會怎樣；macOS /bin/bash 3.2 相容；輸出的樹狀符號與計數在各種組合下（全部相同、部分不同、部分未安裝、兩者都有）對不對；部署端是 symlink、多出檔案、少了檔案、權限讀不到、repo 來源不存在這些輸入各會印什麼。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體輸入 → 錯的輸出）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

審查者交回的原文（逐字；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 1 / Smells 0 — 範圍：`git diff db8637e HEAD` 裡安裝腳本的部分，也就是 `check_builtin_skills`、`check_builtin_agents` 的新分支，以及它們和 `install_builtin_skills`、`install_builtin_agents` 是否對得上
>
> 【發現】
> 1｜Important（只出現在權限異常這條少見的路，不是常走的路）｜部署版裡有讀不到的檔時，`--check` 照樣印「重跑安裝會更新」，但重跑安裝會中止、什麼都沒更新。
> - 證據：`install-dd-pipeline.sh:507` `if [ -d "$source" ] && ! diff -rq "$source" "$SKILLS_DIR/$skill" > /dev/null 2>&1; then`。`diff` 遇到讀不到的檔回 2，`!` 之後一樣走進「與 repo 不同」這一支。安裝端第 672 行先跑 `backup_before_overwrite`，它在第 199 行用 `cp -r "$target" …`，碰到讀不到的檔就失敗，`set -e` 直接中止。agent 也一樣：第 708 行的 `cmp -s` 回 2，被判成不同。
> - 失敗情境：拋棄式 HOME 裝好後，`chmod 000 ~/.claude/skills/dd-loop/SKILL.md`，再 `chmod 000 ~/.claude/agents/code-reviewer.md`。這時 `--check` rc=0，兩行都印「已安裝（與 repo 不同，重跑安裝會更新）」。照提示重跑安裝得到 rc=1，訊息是 `cp: …/skills/dd-loop/SKILL.md: Permission denied`，dd-loop 沒更新，它後面的 skill 與 agent 也全沒跑到。
> - 建議：讓 `diff`／`cmp` 回 2 時另外印一句「無法比對（讀不到）」，不要和回 1 的「不同」走同一支。安裝會中止是既有行為，不是這次 diff 引入的；這次新增的是叫人去重跑的那句提示。
>
> 【Not reported】
> - 比法與分支一一對得上：兩端都用 `dir_exists` 也就是 `[ -d ]`（第 161–163 行），安裝端是 `[ ! -d "$target" ]`；agent 兩端都用 `[ -f ]`（第 166–168 行與第 753 行）；比法同樣是 `diff -rq` 與 `cmp -s`。所以 `--check` 判成相同的，安裝端也判成「已是最新」、不會改寫；判成不同的，安裝端會備份後覆蓋。另外確認過：`--update` 與一般安裝都走同一組 install 函式（第 1545、1546 行與第 1554、1557 行），複製到部署目錄之後沒有其他步驟再改 skill 或 agent 的檔（`chmod` 只有第 1193 行，那是 scripts）。
> - 拿實驗核對了幾種部署端狀態：
>   - 部署版多一個檔、少一個檔：都報不同，安裝端用同一個比法，也會覆蓋。
>   - 部署的 skill 目錄是 symlink，指向內容較舊的外部目錄：報不同；重跑安裝後它換成實體目錄，外部那份不動，「會更新」這句成立。
>   - symlink 直接指回 repo 自己那份：印 ✅。
> - repo 的來源不存在時，`--check` 印綠色「已安裝」，安裝端印「來源不存在」。兩邊說法不一致，但這和改版前一樣；而且部署陣列和目錄的一致性有 CI 擋，正常 clone 下到不了這條路。
> - 部署路徑是一般檔（skill）或目錄（agent）時，`--check` 印「未安裝（執行安裝可補齊）」，安裝端則中止或寫進那個目錄裡。這是改版前就有的既有行為，這次的 diff 沒動到這一支。
> - `set -e`：新加的 `diff`、`cmp` 都放在 `if` 條件裡，`[ "$stale" -gt 0 ]` 也在 `if` 裡，不會觸發中止。bash 3.2 相容：只用到 `local`、`$(( ))`，訊息裡變數緊貼全形字的地方都寫成 `${stale}`。實驗用 `/bin/bash` 跑，rc=0，沒有 shell 錯誤。
> - 樹狀符號與計數：全部相同、部分不同、部分未安裝、兩者都有，這幾種組合都讀過；段尾依序是「├── 已安裝」「├── 與 repo 不同」（stale>0 才印）、最後一行 └──，順序對。實驗輸出的「與 repo 不同：4」與「與 repo 不同：1」也和實際改的數量相同。
> - repo 工作目錄裡有被 gitignore 的 `skills/tech-diagram-gif/scripts/__pycache__/verify-geometry.cpython-313.pyc`。安裝時 `cp -r` 會連它一起複製；兩邊的 `__pycache__` 不一致時，`--check` 會一直報那個 skill 不同。原因是安裝本來就會複製被忽略的檔，這是既有問題；目前部署版和 repo 相同，V5 也沒報它。
>
> 【What I ran】
> - 讀了 prompt-a.txt 全文、s3-review-pack.txt 第 1–627 行全部。
> - `install-dd-pipeline.sh`：讀了第 1540–1579 行，另外 grep 了 `dir_exists`／`file_exists`（第 161–168 行）、`backup_before_overwrite`（第 187–201 行）、`chmod`、各函式的呼叫點。
> - grep `skills/` 底下的腳本有沒有把執行期的狀態寫回 skill 目錄：0 筆。
> - `git ls-files -o -i --exclude-standard skills agents`：1 筆，就是上面那個 `.pyc`。
> - 在 scratchpad 的 `rc3-a/` 開拋棄式 HOME：
>   - `HOME=$H ./install-dd-pipeline.sh`：rc=0。
>   - 接著造出這幾種狀態：讀不到的 skill 檔、多一個檔、少一個檔、指向舊內容的 symlink 目錄、指回 repo 的 symlink、讀不到的 agent。
>   - `HOME=$H /bin/bash ./install-dd-pipeline.sh --check`：rc=0。4 個 skill 加 1 個 agent 標成不同，計數是 4 與 1，review 那行印 ✅。
>   - 重跑安裝：rc=1，`cp: …/dd-loop/SKILL.md: Permission denied`。code-simplifier 已經換成實體目錄，外部那份的「old」還在。
>
> 【需要外部查證】無

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實，自己重現了：沙盒 HOME 裝好後 `chmod 000 …/skills/review/SKILL.md`，改之前的 `--check` 印「已安裝（與 repo 不同，重跑安裝會更新）」，重跑安裝 rc=1（`cp: …/skills/review/SKILL.md: Permission denied`）。
  修法照建議：`diff`／`cmp` 的結束碼分三種 —— 0 相同、1 不同、2 以上另外印「已安裝（無法比對：部署的檔讀不到或比對失敗）」，段尾多一行「無法比對：N」，不再叫人重跑安裝。
  T11 加一格（skill 與 agent 各 `chmod 000` 一個檔）：先在改之前的安裝腳本上跑，紅在「Skills 的 review 那一行應該有『無法比對』」，改完轉綠。
  這一格用 `chmod 000`，root 讀得到，所以以 root 跑時不跑、並在 ✅ 那一行印出來；ubuntu 容器裡另開一般帳號跑過（rc=0）。
  這是測試清單以外加的斷言（修 bug 時加的），最終回報會講明。
- Not reported 裡的兩條既有問題沒有動（不在這一段的範圍），記在這裡：
  - repo 的來源不存在時 `--check` 印「已安裝」、安裝端印「來源不存在」，兩邊說法不一樣（部署陣列與目錄的一致性有 CI 擋，正常 clone 走不到）。
  - 安裝用 `cp -r` 會連被 gitignore 的檔一起複製（目前有一個 `skills/tech-diagram-gif/scripts/__pycache__/…pyc`）；repo 與部署版的 `__pycache__` 不一樣時，`--check` 會一直報那個 skill 不同，安裝也會每次都覆蓋它。目前兩邊相同。
- 其餘 Not reported：都同意，沒有動作。
