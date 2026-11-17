# S1-a（審查者 A：腳本正確性）— /dd-stop 指令、腳本與 gate 的暫停旗標

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-17），在步驟 3（code-simplifier）做完、還沒 commit 的時候。
Agent 呼叫的 prompt 只有「你的完整派工內容在這個檔，先用 Read 把它整份讀完，然後照它做」加檔案路徑，另寫明代號是 S1-a、報告用純文字照四個標題交回、不要寫成檔案。那個檔的內容如下
（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是這一段程式碼變更的審查者 S1-a。職責只有一個：找漏洞。每一條發現都要附證據（`檔案路徑` 加上你讀到的原文，或你實跑的指令與輸出）；沒有證據的不算、不要寫。不寫優點、不客套。
>
> repo：<repo>（規則在根目錄與各層 CLAUDE.md，跟你方向有關的那幾份要讀）。
> 這一段做的事：新增 `/dd-stop on|off|status` 指令 —— 暫停與恢復一個專案的 8 步開發迴圈（步驟 3–8）與 CLAUDE.md pre-commit gate。設計、使用者的決定（U1–U3）在 docs/designs/2026-11-17-dd-stop-design.md。
>
> 審查材料在這個檔：<scratchpad>/rev/S1-diff.txt（共 2153 行，最後一行是 `<<<材料結束>>>`）。
> - 用 Read 的 offset／limit 每次 300 行，讀到看見最後那一行為止（Read 一次讀太多會靜靜截斷、不報錯）。跟你方向無關的檔的 diff 可以掃過，但整份都要翻到。
> - 材料裡有 5 行超過 2000 字元（都是 CLAUDE.md 的表格列），Read 會截斷；要看那幾行就讀工作目錄的原檔。
> - 新增的檔看材料裡那一份；既有而被改到的檔要看上下文時讀工作目錄（審查期間沒有人在改）。
> - 材料第 ④ 節列的驗證已經跑過、結果已確認，不要重跑整支測試。「跑過」不代表測試寫得對 —— 測試本身也在審查範圍。
> - 你可以在 scratchpad 開拋棄式 git repo 做小實驗來證實某一條（目錄放 <scratchpad>/rev/S1-a/ 底下）。用 `/bin/bash <腳本>` 跑，不要在 zsh 裡 `source` repo 的任何腳本（`source ./install-dd-pipeline.sh` 會真的把安裝跑起來）。不要跑 `./install-dd-pipeline.sh`、不要跑 `claude -p`、不要碰真的 `~/.claude/`、不要改 repo 裡任何檔、不要 commit。
> - 只用手上的資料判斷；需要外部查證（上網、官方文件、別台機器）的列在「需要外部查證」交回，不要自己猜。
>
> 你的方向：`scripts/dd-stop.sh` 與 `scripts/check-claude-md.sh` 這一段加的兩處（`dd.stopped`）的正確性。逐條分支看：`on`／`off`／`status` 每一個 exit code 的路徑；`CLAUDE.local.md` 的各種原始狀態（不存在、0 bytes、結尾有沒有換行、使用者在標記段前後加了字、有兩份標記段、沒有結尾行、symlink、已進版控、不是一般檔）下 `on` 再 `off` 是否逐位元組還原、會不會吃掉使用者的內容；`.git/info/exclude` 的處理；`set -e` 下會不會在半路中止而留下「旗標設了、聲明沒寫」或反過來的狀態；macOS `/bin/bash` 3.2 與 Linux（GNU grep／sed／head／tail／wc）兩邊行為會不會不同；從子目錄、路徑有空白或中文、worktree、bare repo、還沒有任何 commit 的 repo 跑會怎樣；gate 那兩段在暫停中有沒有該記帳而沒記、起點檔三種狀態（沒有／讀得出來／壞掉）是否照設計；恢復後欠帳是不是真的追得到。材料 ② 節是 code-simplifier 剛改的，確認它沒有改到行為。
> 方向以外看到的問題照樣列，但先把方向內的查完。
>
> 每條發現標級別：Critical（照現在這樣會壞資料、會讓使用者以為暫停或恢復了而實際沒有、會靜靜漏掉該擋的東西）／Important（行為錯、文件宣稱與實際不符而會讓人照錯的做、測試斷言是空的或恆真）／Smell（不影響正確性）。
> 你判定「不是這次 diff 引入的既有問題」而不列的，放進 Not reported 並寫一句理由。
>
> 交回格式（純文字，不要寫成檔案；照這些標題）：
> 【What I ran】讀了哪些檔、跑了哪些指令（指令照貼，輸出只貼關鍵行）
> 【Findings】每條：S1-a-<序號>｜級別｜檔案與位置（用函式名、區塊名或可 grep 的原文，不要只給行號）｜問題｜證據｜會造成什麼
> 【Not reported】每條一行
> 【需要外部查證】每條一行；沒有就寫「沒有」

審查材料 `S1-diff.txt` 的四節：①`git diff 925d0b8 -- . ':!docs/measurements/2026-11-17-dd-stop/out'`（含步驟 3 還沒 commit 的改動）②步驟 3 自己改的（`git diff HEAD`）
③怎麼讀整檔（新增的檔看材料、既有的檔讀工作目錄）④已經跑過的驗證與預期值（`tests/test-dd-stop.sh` 131 個 ✅、`tests/test-gate.sh` 213 個 ✅、shellcheck 沒有輸出、`selftest-model.sh` 32 個 ✅、`tests/test-install.sh` exit 0、lint job 22 個 step、變異對照）。

## 發現

審查者交回的原文（派工的那個對話在查證開始前就中斷了，暫存區跟著清掉；這一份是下一個對話從那個對話的紀錄檔取回的，每行開頭的兩格縮排拿掉、絕對路徑換成 `<scratchpad>`、`<repo>`，其餘逐字）：

> S1-a 審查報告。方向內的找到 2 條 Important、1 條 Smell，沒有 Critical。最嚴重的是 `off` 在寫不進 `CLAUDE.local.md` 時會無限迴圈，我在拋棄式 repo 實跑重現了。
>
> 【What I ran】
> - 讀完整份 `S1-diff.txt`，第 1 行到 `<<<材料結束>>>`，分 300 行一段讀。重點讀的是 `scripts/dd-stop.sh`、`check-claude-md.sh` 的 diff、`tests/test-dd-stop.sh`、`tests/test-gate.sh` 的 ⑰，以及 ② 節 code-simplifier 的改動。
> - 讀了工作目錄 `scripts/check-claude-md.sh` 第 18–97 行，確認四件事：gate 沒有 `set -e`；`STOPPED` 在 `dd.docfile` 驗證之後才算；`read_base` 的判法是 `git cat-file -t` 為 commit 或 tree，跟 `off` 的 `base_broken` 一致；`head_or_empty` 在沒有 commit 時回空樹。
> - `scripts/CLAUDE.md` 已經在 context 裡（dd-stop.sh 條目、暫停旗標條目、兩張變異表）。
> - 實驗腳本：`/bin/bash <scratchpad>/rev/S1-a/exp.sh` 與同目錄的 `exp2.sh`。兩支都用 repo 版 `dd-stop.sh` 與 gate 的副本、放在同一層，每支程式設 `perl alarm 5` 當逾時。關鍵輸出：
>   - H1b：原本就有的 `CLAUDE.local.md`，`on` 之後 `chmod 444`，再跑 `off`。結果 `rc=142`（被 alarm 砍掉），5 秒內印了 206 行同一句：`dd-stop.sh: line 152: CLAUDE.local.md: Permission denied`；`flag=[]`。
>   - H3：檔是 `on` 建的（created=1），repo 根目錄 `chmod 555`，再跑 `off`。結果 `rc=142`，印了 207 行 `rm: CLAUDE.local.md: Permission denied`。
>   - H2：原本就有的 `CLAUDE.local.md` 先 `chmod 444`，再跑 `on`。結果 `rc=1`，輸出只有 `dd-stop.sh: line 100: CLAUDE.local.md: Permission denied`；`flag=[true] blocks=0`。`status` 印「旗標：暫停中」「聲明：不在」「兩邊不一致」。接著改 `a/x.sh`、不補文件 commit：gate 印「gate 暫停中」並記下起點，`commit rc=0`。
>   - H4（還沒有任何 commit 的 repo）：`on` 是 0；暫停中第一個 commit 記下空樹 `4b825dc…`；`off` 列出 `a/CLAUDE.md` 欠帳，exit 0。符合設計。
>   - H5（linked worktree、路徑含空白）：在 worktree 跑 `on`，旗標在主 worktree 也看得到，聲明只在 worktree，`git status` 看不到它；`off` 恢復並刪掉檔。符合已知限制。
>   - H6（bare repo）：`❌ dd-stop.sh：不在 git repo 內`，rc=1。
>   - H7（`off` 時有 staged 但沒 commit 的 `z/q.sh`）：欠帳清單列出 `z/CLAUDE.md`。
>   - 結束時 `ps -ax | grep -c '[d]d-stop.sh off'` 是 0，沒有留下程序。
>
> 【Findings】
> S1-a-1｜Important｜`scripts/dd-stop.sh` 的 `do_off` 裡 `if ! remove_blocks; then` 那一行，以及 `remove_blocks` 的 `while b=$(begin_line) && [ -n "$b" ]; do` 迴圈。
> - 問題：`remove_blocks` 是在 `if !` 的條件裡被呼叫，bash 在這種位置會停用函式內的 `set -e`。所以寫回那一步（`cat "$tmp" > "$LOCAL_FILE"`）或刪檔那一步（`rm -f "$LOCAL_FILE"`）失敗時，腳本不會停。檔案沒有變，下一圈 `begin_line` 又找到同一個標記段，於是永遠重跑。
> - 證據：H1b 與 H3 都被 5 秒的 alarm 砍掉（exit 142），各印了 206、207 行同一個錯誤。H1b 跑完 `flag=[]`，表示旗標已經清掉，標記段還在。
> - 會造成什麼：檔案或目錄寫不進去時（唯讀檔、目錄沒有寫入權限、別的使用者擁有），`/dd-stop off` 會在 Claude 的 Bash 裡卡到逾時，stderr 一直洗版。這時旗標已清、gate 已經恢復擋 commit，但聲明還在，新開的對話照樣讀到「暫停中」。exit 5 那條「聲明還在、手動處理」的出路永遠走不到。`tests/test-dd-stop.sh` 沒有寫入失敗的情境；`scripts/CLAUDE.md` 的「測不到的」只列了中斷後留下的 `dd-stop.tmp`，沒提這個。
>
> S1-a-2｜Important｜`scripts/dd-stop.sh` 的 `do_on`，`git config --local dd.stopped true` 寫在寫聲明（`echo >> "$LOCAL_FILE"`、`cat >> "$LOCAL_FILE" <<EOF`）與寫 `info/exclude` 之前。
> - 問題：`set -e` 會在半路中止，留下「旗標設了、聲明沒寫」的狀態。輸出只有一行 shell 錯誤，沒說旗標已經設了。
> - 證據：H2 跑完 `flag=[true] blocks=0`；輸出只有 `line 100: CLAUDE.local.md: Permission denied`。之後一個改碼、不補文件的 commit 被放行，印的是「gate 暫停中」。
> - 會造成什麼：`commands/dd-stop.md` 第 3、4 步的規則是 exit 非 0、或輸出沒有「8 步迴圈已暫停」就照實回報失敗。使用者因此以為沒有暫停，Claude 也照常跑迴圈，但 gate 已經靜靜放行每個 commit。帳雖然照記，可是沒有人知道要 `off`，直到使用者自己跑 `status`。這正是 `scripts/CLAUDE.md` 寫的「暫停有兩半，少一半就不算暫停」，而 `status` 那一行是事後才看得到的痕跡。`info/exclude` 寫入失敗也會走到同一個狀態（它也在設旗標之後），這條我沒有實跑。
>
> S1-a-3｜Smell｜`do_off` 的「以下是 gate 的欠帳檢查（這次沒有 commit 被擋）：」這一段。
> - 問題：它不帶參數跑 gate，gate 會連「現在 staged、還沒 commit」的改碼目錄一起列進清單。
> - 證據：H7，暫停中只 `git add z/q.sh` 沒有 commit，`off` 列出 `z/CLAUDE.md`。
> - 會造成什麼：使用者照 `commands/dd-stop.md` 第 5 步補帳，補完那個 commit 照樣過，不會漏，只是清單的意思比「暫停期間欠的」寬。不影響正確性。
>
> 【Not reported】
> - 有查過、沒有發現問題：
>   - code-simplifier（② 節）的改動沒有改到行為。新的 `begin_line` 用的正規式 `^<!-- dd-stop:begin ` 裡沒有 BRE 特殊字元，跟舊的 `-F` 加 `-E` 過濾等價。`gate_ran` 重排後，三支分支的條件與輸出跟原本一一對應。多宣告的 `local reason` 只是收窄變數範圍。
>   - gate 那兩處（`--start-segment` 暫停那支、pre-commit 暫停那支），以及起點檔三種狀態（沒有、讀得出來、壞掉）都照設計：不帶 `set -e`、`STOPPED` 在 docfile 驗證之後、`read_base` 不覆寫壞檔。沒有 commit 的 repo 記成空樹、`off` 認空樹，也照設計。
>   - `on` 再 `off` 的逐位元組還原，我照著讀了 0 bytes、只有空白、結尾有沒有換行、前後有使用者加的字、兩份標記段、沒有結尾行、symlink、已進版控、不是一般檔這幾種，跟測試與設計一致。
>   - bare repo、子目錄、路徑含空白與中文、linked worktree 都照設計或照已知限制。
> - 太邊角、沒有列：
>   - 原檔結尾沒有換行（sep=1），使用者暫停期間又在標記段「前面」插字時，`off` 會吃掉最後一個換行。只差一個換行、不掉內容。
>   - 原檔最後一個位元組是 NUL 時，`tail -c 1` 的判斷會失準，標記段開頭行會接在 NUL 後面。只有二進位檔才會遇到。
> - ⑰ 的「只設在 global」那則在 git < 2.32 上可能是空斷言：舊版不認 `GIT_CONFIG_GLOBAL`，那則照樣會擋，所以不管 gate 對不對都綠。這台機器上 `--get` 那個變異讓它變紅過，CI 上的 git 版本也夠新，所以沒列成發現。
> - 暫停中的 commit 如果完全不經過 pre-commit（使用者自己在終端機用 `-n`，或 rebase、cherry-pick），而且當時沒有起點檔，那筆欠帳追不到。這是既有的 `--no-verify` 類繞過，`scripts/CLAUDE.md` 已經寫了；`on` 自己不記起點是設計的選擇。
> - `docs/measurements/` 底下的 `check-model.sh`、`run-model.sh`、`selftest-model.sh`、`probe-local.sh`，以及 README、CHANGELOG、ARCHITECTURE、install 的 diff，我都翻過一遍，沒有逐條審。不在我的方向內。
>
> 【需要外部查證】
> - GNU coreutils 與 grep 上跑 `tests/test-dd-stop.sh`：材料 ④ 寫這要等步驟 5 在 ubuntu 容器裡跑，我只在 macOS 上做了實驗。

## 處置

修正、測試與這份報告在同一個 commit（步驟 6，訊息結尾「（S1）」）。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-a-1 `off` 寫不進 `CLAUDE.local.md` 時永遠重跑 | Important | 採納，已修。查證：先寫測試（`tests/test-dd-stop.sh` 的 M2），對修之前的腳本跑，唯讀的檔與不能寫的目錄兩種 `off` 都被 10 秒的 alarm 砍掉（exit 142）。修法：`remove_blocks` 寫檔的每一步用 `&&` 接成一組，有一步不成就印「寫不進」、回 1，`do_off` 走既有的 exit 5（旗標已清、不印已恢復）；改回可寫之後重跑 `off` 會把標記段拿掉。變異「寫不進之後不回 1」「寫檔各步的結果不接」都紅在 M2 那兩則。原因與「在這個函式裡加寫檔步驟要接進同一組」寫進 `scripts/CLAUDE.md` |
| S1-a-2 `on` 先設旗標，寫聲明失敗時旗標留著 | Important | 採納，已修（與 S1-b-1 同一件）。查證：M2 對修之前的腳本跑，唯讀檔的 `on` 是 exit 1、印一行 `Permission denied`、旗標是 `true`。修法：`on` 改成先寫 `info/exclude` 與聲明、最後才設旗標；聲明寫不進去 exit 4、訊息寫明沒有動旗標；旗標設不了 exit 1、訊息叫人跑 `off` 拿掉已經寫的聲明。變異「改回先設旗標」「聲明寫不進去照樣往下」「旗標設不了不報」各紅在 M2。報告說沒有實跑的那一句（`info/exclude` 寫不進去）：查證時在拋棄式 repo 跑了，現行版是一行 shell 錯誤、exit 1、旗標與聲明都沒動；這一種沒有另外包訊息、沒有測試，寫進腳本檔頭與 `scripts/CLAUDE.md` |
| S1-a-3 `off` 的欠帳清單含只 staged、還沒 commit 的目錄 | Smell | 採納，改文件不改行為。查證：拋棄式 repo 暫停中只 `git add z/q.sh`，`off` 列出 `z/CLAUDE.md`。gate 不帶參數本來就看 staged，照清單補不會漏；`scripts/CLAUDE.md` 講欠帳清單的那一條補一句 |

Not reported 的幾項：code-simplifier 的改動沒有改到行為 —— 另拿 HEAD 版（步驟 3 之前）與現行版跑同一串沒有寫檔失敗的情境，輸出逐位元組相同；`sep=1` 而使用者在標記段前面插字、最後一個位元組是 NUL 這兩種沒有處理，同意太邊角；
`GIT_CONFIG_GLOBAL` 在舊 git 上恆綠那一點寫進 `tests/CLAUDE.md`（新加的 J「只設在 global」同理）。

需要外部查證：做了。ubuntu:24.04 容器（bash 5.2.21、git 2.43.0、GNU coreutils 9.4）跑 `tests/test-dd-stop.sh`：root 是 144 個 ✅、0 個 ❌（M2 不跑）；一般帳號是 159 個 ✅、0 個 ❌。
