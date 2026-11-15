# S5 審查 — A（安裝腳本、CI、測試的程式碼）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S5（`review` 包裝器與 `workflow-review` 退場、code-simplifier 包裝器補約束）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。Agent 呼叫的 prompt 只有一句「先用 Read 把這個檔整份讀完，它就是你的完整派工內容，照它寫的做」，加派工檔的路徑；派工檔全文如下（`<scratchpad>` 是這個 session 的暫存目錄，沒進 repo）。

審查包 `<scratchpad>/s5-review-pack.txt`（755 行）的組成：第 1 節 `git diff b3b2bf9 HEAD`（HEAD = 63f4d6c，工作目錄乾淨）；第 2 節步驟 3 的結果（code-simplifier 看過三個檔的改動，沒有要改的）；
第 3 節被刪掉的兩個檔的原文；第 4 節已跑過的驗證 V1–V9 與預期值。被改到的檔沒有另附整檔：工作目錄與 HEAD 相同，派工寫明直接讀 repo。

````
你是 code-reviewer，審 claude-dd 這個 repo 的一個功能段落（S5）。你的職責：找漏洞。每條發現都要附證據（`路徑:行` 加原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。

審查包：<scratchpad>/s5-review-pack.txt（755 行）。**用 Read 的 offset/limit 每次 300 行讀到最後一行**（Read 一次讀太多會靜靜截斷、不報錯）。
裡面有：整段 diff（`git diff b3b2bf9 HEAD`）、被刪掉的兩個檔的原文、已經跑過的驗證與預期值。
工作目錄與 HEAD 相同，被改到的檔直接讀 repo 裡的就是 diff 描述的那一版。repo：/Volumes/T7/home/project/my_project/claude-dd
專案規則在根目錄與各層 CLAUDE.md；這一段的計畫、假設與結果在 `docs/designs/2026-11-15-audit-fixes-design.md` 的「### S5」一節。

這一段做了兩件事：
- S5-1：`skills/review/` 與 `commands/workflow-review/` 從 repo 刪掉、從部署陣列拿掉（`NS_COMMANDS` 變成空陣列），同批改 CI、測試、文件。
- S5-2：`skills/code-simplifier/SKILL.md` 的 Prompt 模板加一句約束，附 A/B 實測。

硬限制：
- **不要執行 `./install-dd-pipeline.sh`，不要在 shell 裡 `source` 它**（Bash 工具是 zsh，source 會讓整支安裝在真實的 `~/.claude` 上跑起來）；不要跑 `tests/*.sh`。審查包第 4 節列的驗證已經跑過、已確認，不要重跑。語法檢查可以用 `/bin/bash -n`、`shellcheck -S warning`。
- 全程唯讀：不改檔、不 commit、不寫報告檔（發現用文字交回）。要做小實驗只能在 <scratchpad> 底下自己開的新目錄裡做，不要動那裡既有的檔。
- 只用手上的資料判斷；需要上網或跑上面禁止的指令才能確認的，列在「需要外部查證」交回。
- 發現分級：Critical（照現在的內容使用會壞、會錯，而且不會報錯）／Important（文件或程式碼說的與事實不符、漏了專案規則規定要同批改的地方、驗證抓不到它該抓的錯）／Smells（其他）。
- 被你判成「既有問題、不是這次 diff 引入」的項目，回去看這次 diff 有沒有把同一個寫法帶進新的地方，再決定要不要報。

你的方向：
**安裝腳本、CI、測試的程式碼**。`NS_COMMANDS=()` 之後，`install-dd-pipeline.sh` 裡每一處用到 `NS_COMMANDS`／`ALL_NS_COMMANDS` 的地方（`grep -n 'NS_COMMANDS' install-dd-pipeline.sh` 逐處讀）在各條路徑上的行為：一般安裝、`--force`、`--update`、`--commands-only`、`--check`、`--uninstall`、`--help`；bash 3.2 與 `set -e` 下會不會中止或印錯東西；樹狀圖的 `├──`／`└──` 在其他路徑上對不對。
ci.yml 那一行 `find … | sed 's#.*/##' | sort`：在 ubuntu 與 macOS 的行為、路徑含特殊字元時、以及 ci.yml 裡還有沒有別的 step 假設 `commands/` 底下有子目錄（例如「部署內容裡的 ~/.claude/ 路徑」那個 step 的 `commands/*/…` 分支、數字宣稱那個 step）。
`tests/test-install.sh`：新斷言 `[ -z "$(find …)" ]` 抓不抓得到它該抓的錯、T11 換成 `verification-gate` 之後四處是否一致、計數斷言（`t11_foot … 2`）有沒有因此變。還有沒有別的測試或腳本用到被刪掉的名字。

輸出格式（照抄這些標題）：
第一行：Critical N / Important N / Smells N — 範圍一句話
【發現】每條：序號｜級別｜內容｜證據（路徑:行 與原文，或指令與輸出）｜會出事的情境｜建議改法
【Not reported】你看過、判斷不用報的（各一句理由）
【What I ran】你讀了什麼、跑了什麼指令（指令照貼）
【需要外部查證】沒有就寫「無」
````

## 發現

審查者交回的報告，逐字（只把暫存目錄的絕對路徑換成 `<scratchpad>`）：

````
Critical 0 / Important 0 / Smells 0 — 範圍：b3b2bf9..63f4d6c 裡安裝腳本、ci.yml、tests/test-install.sh 的改動（照派工的方向）

【發現】
沒有夠得上門檻的發現。

【Not reported】
- install-dd-pipeline.sh:84 `ALL_NS_COMMANDS=("${NS_COMMANDS[@]}")`，還有 :1139、:1295 對空陣列跑的 `for`：腳本只有 `set -e`（:8），沒有 `set -u`（審查包 V7 的 grep 沒命中），所以 bash 3.2 下空陣列展開不會報 unbound。迴圈跑 0 次，各條路徑都不會中止。
- install-dd-pipeline.sh:1097 `total` 等於 1，所以 dd-init 的 `tree_char` 是 `└──`，:1135 的標題在 N=0 時不印，樹狀圖收尾正確。加回命名空間 command 時，total 會把 NS 一起算進去，dd-init 的前綴回到 `├──`，標題接在它後面，也正確。
- `--commands-only`、`--force`、`--update` 走的都是同一個 `create_commands`，沒有另一份處理 NS 的程式碼。`--check` 不比對 commands，grep `ns_cmd|COMMANDS_DIR` 在 check 那段沒有命中。`--help`（:295）與 `--uninstall`（:1266）印「0 個命名空間」，是計畫明寫要照印的。
- ci.yml:85 的 `find … | sed 's#.*/##' | sort`：BSD 與 GNU find 都支援 `-mindepth`、`-maxdepth`，而且它們放在 `-type` 前面，GNU 不會警告。空陣列那一邊是 `printf "%s\n"` 印出一個空行，經命令替換後是空字串，兩邊相等（V2 已驗）。跟原本的 `ls -d */` 比有兩點不同：隱藏目錄會被算進去、指向目錄的 symlink 不算。repo 裡兩種都沒有，也想不出會實際出事的情境。
- ci.yml:396-397 的 `commands/*/*` 分支還在，但它最後還是用 `[ ! -e "$rel" ]` 對 repo 實際檢查，沒有子目錄不會讓它誤判。數字宣稱 step 的 :149-151 抓的是 CLAUDE.md 那句「0 個命名空間 command 目錄」，比對值是 `${#ALL_NS_COMMANDS[@]}`=0，兩邊一致。
- tests/test-install.sh:50 的 `[ -z "$(find … -type d)" ]`：:46 已經先斷言 dd-init.md 存在，所以目錄一定在，find 不會因為找不到目錄而輸出空字串、假性通過。有子目錄就會在 `set -e` 下失敗，這是 tests/CLAUDE.md 寫明的已知性質。
- T11 換成 verification-gate 的四處（:798、:799、:804、:811）名字一致。skills/verification-gate/SKILL.md 存在，也不在 stale 那組（stale 只改 dd-loop、gate-guard），所以 :808 的 `t11_foot … "與 repo 不同" 2` 不會因為換名而變。`t11_line` 比對的是 `" name: "`，不會跟其他名字前綴相撞。
- tests、scripts、ci、install、commands、skills、agents、templates 裡已經沒有 `workflow-review` 或 `skills/review` 被當成現存元件。只剩 install-dd-pipeline.sh:80 與 tests/CLAUDE.md:125 兩句「已退場」的說明。templates/global/CLAUDE.md:720 的 `review` 是 prompt 關鍵字，不是 skill 名稱。

【What I ran】
- Read prompt-a.txt；Read s5-review-pack.txt，分三段讀，offset 1/300/599，讀到第 755 行
- `grep -n 'NS_COMMANDS' install-dd-pipeline.sh` → 9 處：82、84、295、1097、1135、1136、1139、1266、1295
- `grep -n '^set \|set -[eu]\|set -o' install-dd-pipeline.sh` → 只有 :8 的 `set -e`
- `sed -n` 讀 install-dd-pipeline.sh 的 75-90、285-300、1090-1185、1255-1320 行
- `grep -n '命名空間\|ns_cmd\|commands/\*\|COMMANDS_DIR' install-dd-pipeline.sh`；`grep -n 'commands' .github/workflows/ci.yml`
- `sed -n` 讀 ci.yml 的 60-175、360-410 行
- `grep -n 'T11' tests/test-install.sh`；`grep -n 'verification-gate\|review' tests/*.sh`；`sed -n 748,770p tests/test-install.sh`；`sed -n 40,50p tests/test-install.sh`；`ls skills/verification-gate`；`ls skills`
- `git grep -n 'ls -d commands\|commands/\*/' -- . ':!docs/reviews' ':!docs/designs' ':!CHANGELOG.md'` → 只有 ci.yml:396、:397
- `git grep -n 'workflow-review\|skills/review\b' -- scripts tests .github install-dd-pipeline.sh commands skills agents templates | grep -v self-improving-agent/skills/review` → 只有上面那兩句退場說明
- `git grep -nE '`review`|skill="review"|Skill\(review|/review\b' -- templates skills commands agents scripts | grep -v skills/self-improving-agent` → 只有 templates/global/CLAUDE.md:720
- `/bin/bash -n install-dd-pipeline.sh` → synOK；`shellcheck -S warning install-dd-pipeline.sh tests/test-install.sh` → rc=0

【需要外部查證】
無
````

## 處置

沒有發現。它列在 Not reported 的項目我回頭對過程式碼的有三條：

- 空陣列加 `set -e`、沒有 `set -u`：`grep -nE 'set -[a-z]*u|nounset' install-dd-pipeline.sh tests/*.sh .github/workflows/ci.yml scripts/*.sh` 沒有命中，屬實
- `find` 與原本的 `ls -d */` 的兩點差異（隱藏目錄會算進去、指向目錄的 symlink 不算）：屬實，`commands/` 目前兩種都沒有，不改；記在 `S5-judge.md`
- T11 的計數斷言不受換名影響：stale 那一格改的是 `dd-loop` 與 `gate-guard`，屬實
