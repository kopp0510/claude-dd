# S1-c：審查者 C（commands/dd-init.md 的指示流程（每條寫檔分支照做一遍））

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），四個在同一則訊息平行派出。
派工 prompt 只有一句（逐字，路徑去識別）：

> 你的派工指示全文在 <S>/s1-review/prompt-c.txt —— 先用 Read 讀完整份，照它做，照它的輸出格式交回。

那份檔的全文（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad、`<REPO>` 是 claude-dd 的 clone；下面「發現」節同樣只換了路徑）：

````text
你是 claude-dd repo（<REPO>）S1 段落的程式碼審查者，代號 S1-c。
你的職責：找漏洞。每條發現都要附證據（diff 檔的行號與原文、你讀到的檔案路徑:行、或你跑的指令與輸出）；沒證據的不算。不寫優點。

審查範圍：S1 整段，`git diff 9584605` 起到工作目錄（3 個 commit：cf093e7 S1-1、58e3edb S1-2、a0aa58a S1-3，加上步驟 3 code-simplifier 還沒 commit 的改動）。
untracked 的 docs/measurements/2026-11-14-security-audit-trial/ 屬下一段，不在範圍。

材料：<S>/s1-review/diff.txt
- 這份檔含 ①整段 diff ②步驟 3 的改動（分開附，看得出哪些是 simplifier 改的）③被改到的檔的整檔內容 ④已跑過的驗證與預期值
- 用 Read 的 offset/limit **每次 150 行**讀到最後一行（共 2942 行）。一次讀太多會靜靜截斷、不報錯
- 被改到的檔，一律讀 diff 檔裡那一份；沒被改到的檔（例如 .github/workflows/ci.yml、scripts/check-claude-md.sh、UPGRADING.md）照常讀工作目錄
- ④ 列的測試、CI step、沙盒臂都已經跑過，不要重跑；但斷言寫得對不對、驗的是不是它宣稱驗的東西，仍在範圍內

背景（事實，不是結論）：
- 這段修的是：`/dd-init`（commands/dd-init.md，給 Claude 照做的指令文件）與 scripts/dd-init-upgrade.sh 寫檔時，目標若是 clone 帶進來的 symlink，寫入會跟著連結落到專案外
- 設計與驗收在 ③ 的 docs/designs/2026-11-14-security-audit-intake-design.md（「進度表」S1 那列、「段落與小任務」S1、假設 A13–A21）
- 專案規則在根目錄 CLAUDE.md、scripts/CLAUDE.md、tests/CLAUDE.md、docs/measurements/2026-11-14-dd-init-symlink/CLAUDE.md；全域規則在 ~/.claude/CLAUDE.md（§3.9、§3.10 是寫碼與寫文件的判準）
- 這是公開 repo：若任何會進 repo 的文字描述了一條「能讓寫入落到專案外、而 S1 沒修」的路徑，要列為發現

你的方向：commands/dd-init.md 的指示流程：把 Phase 0–5 每一條寫檔分支當成要照做的人走一遍，查新小節「寫檔前：先看目標是不是 symlink」涵蓋了沒、答「要」與「不要」之後的下游走不走得通、有沒有和既有段落矛盾；其他檔是背景但發現照列

要查的（每條都要自己讀檔或 grep 確認，不信 diff 檔裡的敘述）：
1. 程式碼與指令文字照做時會不會錯：分支漏掉、條件寫反、bash 3.2 不相容、`set -e` 下回非 0 中止、zsh／bash 差異
2. commands/dd-init.md 的新規則與文件其他段落有沒有互相矛盾、有沒有照字面做會走錯或卡住的地方
3. 文件、註解、CHANGELOG、results.txt 裡的宣稱在這個工作目錄還成立嗎（引用的行號、函式、指令、數字、版本、「實測」結果）；diff 動到的識別符用 `git grep` 找其他提到它的地方
4. 專案規定「同批要一起改」的地方有沒有漏（在各層 CLAUDE.md grep「同批」「同時改」「同步」「手動同步」「跳 dd-loop-rev」）
5. 驗證有沒有牙：check.sh 的斷言在它要抓的錯發生時會不會變紅；測試會不會空通過

規則：
- 只用手上的資料與唯讀指令判斷（Read、Grep、git show／log／grep、bash -n、shellcheck）。不要改檔、不要 commit、不要跑 install-dd-pipeline.sh、不要派 agent、不要開 docker
- 需要外部查證的（要上網、要跑會寫檔的東西、要真容器）列在「需要外部查證」交回
- 每條標級別：Critical（照做會把檔寫到專案外、或驗證是空的而宣稱有效）／Important（會錯、會誤導、規定要同步卻漏）／Smell（小事）
- 拿不準是不是既有問題時，去看那幾行在 9584605 是不是已經長這樣；這段把同一個錯寫法複製到新地方，也算這段的問題

輸出格式（照抄標題）：
## Findings
每條：S1-c-<序號>｜級別｜一句話｜證據（diff 檔行號或 路徑:行，原文縮排貼出；或指令與輸出）｜照做的失敗情境
## Not reported
看過、判定不是問題的（一句話理由）
## 需要外部查證
## What I ran
````

## 發現

（逐字原文，只換了路徑）

````text
## Findings

S1-c-1｜Critical（前提：用了 `--commands-only`）｜新小節不檢查 `CLAUDE.md.dd-upgrade`，把它交給升級腳本的 exit 6 去擋。但 `--commands-only` 只部署 `commands/`、不部署 `scripts/`，Phase 1 第 1 步也只看腳本在不在、不看版本，所以使用者手上可能是新文字配舊腳本｜證據：`commands/dd-init.md:48`（diff 檔 1145）
```
  升級的輸出檔 `CLAUDE.md.dd-upgrade` 由升級腳本自己擋（已經存在就 exit 6）
```
`commands/dd-init.md:91`（diff 檔 1188）`1. ~/.claude/scripts/dd-init-upgrade.sh 不存在 → 提示…`（只看存在）。`install-dd-pipeline.sh:1366-1390`：`create_commands` 無條件跑，`create_scripts` 包在 `if [ "$COMMANDS_ONLY" = false ]` 裡。`--commands-only` 是 README.md:67、README.zh-TW.md:68 寫給使用者的公開選項。同一份文件裡已經有先例：Phase 3 第 1 步用 `grep -q -- '--start-segment'` 偵測舊版 gate（`commands/dd-init.md:195`）｜照做的失敗情境：使用者更新 repo 後跑 `./install-dd-pipeline.sh --commands-only`，接著在一個 clone 來的專案跑 `/dd-init` 升級，而這個專案帶了指到專案外的 `CLAUDE.md.dd-upgrade` symlink。照新文字不必檢查這個路徑，舊版 `--apply` 就經由 awk 的 `print > out` 寫到專案外。⚠️ 這條描述了一條 S1 還沒修、會寫到專案外的路徑（A14）：落地之前請先處理

S1-c-2｜Important｜新小節、CHANGELOG、results.txt 都說解析 symlink 的是 `git rev-parse --git-path`。實際上做解析的是 `--path-format=absolute`，只加 `--git-path` 不會解析。Phase 3 除了 husky v9，其他寫檔分支全靠這一點擋｜證據：`commands/dd-init.md:50`（diff 檔 1147）`其他掛載點由 Phase 3 第 2 步檢查：`git rev-parse --git-path` 印的是解析過 symlink 的路徑`；CHANGELOG `## 未發布` 第 13 行（diff 檔 2900）`（`git rev-parse --git-path` 會解析 symlink）`；results.txt:62（diff 檔 1909）`git 的 --git-path 解析 symlink`。實跑：`git -c core.hooksPath=/tmp rev-parse --git-path hooks/pre-commit` → `/tmp/pre-commit`；加上 `--path-format=absolute` → `/private/tmp/pre-commit`（git 2.42.0，`/tmp -> private/tmp`）｜照做的失敗情境：維護者或 agent 照第 50 行，以為「只要 `--git-path` 就會解析」。例如在 git < 2.31（`commands/dd-init.md:198` 自己註明 `--path-format` 要 2.31 起）上拿掉這個旗標，或改寫第 2 步時把它簡化掉。這時印出來的是沒解析過的 `.git/hooks/pre-commit`，判成在 repo 裡、不會問，接著 Edit 或 chmod 就跟著連結改到專案外。這正是 §3.10 說的「用來證明安全的那一句，正是失效的機制」。git < 2.31 實際會印什麼，見「需要外部查證」第 1 條

S1-c-3｜Important｜父目錄檢查照字面寫成 `cd "$(dirname <路徑>)" && pwd -P`。主對話 Bash 工具的 `cd` 會留到下一次呼叫，所以 husky v9 那條跑完之後 cwd 停在 `.husky`，後面相對路徑的指令都跑錯目錄。沙盒臂是 subagent，每次呼叫 cwd 都會重設，看不到這個問題｜證據：`commands/dd-init.md:42`（diff 檔 1139）
```
- 父目錄解析後還在專案裡：`cd "$(dirname <路徑>)" && pwd -P` 的輸出等於專案根目錄
```
Bash 工具說明：「`cd` carries to the next call only in the main session, if the command succeeds and ends inside the working directories」；subagent 則是「cwd reset between bash calls」。`.husky/pre-commit` 是要檢查的路徑裡唯一 dirname 不是 `.` 的。後面接著的是相對路徑：`commands/dd-init.md:263` 的 `test -x <掛載點> || chmod +x <掛載點>`（husky v9 的掛載點是「repo 根目錄的 `.husky/pre-commit`」），以及 `:297` 的 `git add CLAUDE.md`。H3、H3K 臂做完 Phase 3 就停，沒跑 Phase 5｜照做的失敗情境：husky v9 專案跑 `/dd-init` 時，檢查完 cwd 變成 `<repo>/.husky`。第 4 步 `chmod +x .husky/pre-commit` 報 No such file。Phase 5 `git add CLAUDE.md` 回 `fatal: pathspec`（exit 128）；`[ -f .gitignore ]` 是假；`git diff --cached --quiet -- CLAUDE.md` 沒差異，所以不 commit。蓋好章的 CLAUDE.md 就留在工作目錄沒進版控，正是 Phase 5 註解（`:310-312`）點名要避免的結果。改成 `(cd … && pwd -P)` 放進 subshell 就不會留下 cwd

S1-c-4｜Important｜「寫檔前」答「要」之後，Phase 1 改的是連結目標，Phase 5 卻只 `git add CLAUDE.md`（連結本身沒變）。設計裡「要」這條路主要是給 `CLAUDE.md → AGENTS.md` 用的（A16），結果蓋章靜靜地沒被 commit｜證據：`commands/dd-init.md:69`（diff 檔 1166）`使用者答「要」之後，就對連結目標的路徑用 Write、Edit 照原本的步驟寫`；`:297-304` 的 Phase 5 只對 `CLAUDE.md .gitignore` 做 add 與 diff。答「不要」那條有接 Phase 5（`:62`），答「要」那條沒有。Phase 3 第 5 步有「實際改的是連結目標 → 提醒他 commit」（`:280-281`），Phase 1 沒有對應的一句。Y 臂的 TASK 只到 Phase 1（mkprompt.sh:10），prompt.txt:9 寫「不要 commit」，所以沒測到這裡｜照做的失敗情境：Y 型專案答「要」，`AGENTS.md` 蓋了章；Phase 5 的 `git diff --cached --quiet -- CLAUDE.md` 判成沒變更，不 commit，也不提醒。Phase 6 照樣印 ✅，`AGENTS.md` 的改動一直沒進版控

S1-c-5｜Important｜Phase 1、Phase 2 的「不要」是這次新加的分支，但 Phase 6 的完成訊息還是固定把 CLAUDE.md、`.screenshots/ + .gitignore` 列成「已設定」｜證據：`commands/dd-init.md:62-63`（diff 檔 1159-1160）`Phase 1 → CLAUDE.md 這次不蓋章，告知使用者`、`Phase 2 → 只跳過那個路徑對應的那一行…；告知使用者`；`:337-339`（diff 檔 1434-1436）`已設定：├── CLAUDE.md — 8 步開發迴圈…├── .screenshots/ + .gitignore（有前端時）`。Phase 6 的範本沒有任何條件分支｜照做的失敗情境：C 型（CLAUDE.md 是指到專案外的 symlink）答「不要」，Phase 1 先講了沒蓋章，Phase 6 又印「✅ 初始化完成！已設定：CLAUDE.md — 8 步開發迴圈」，前後矛盾。Phase 5 的註解（`:312`）本來就把「Phase 6 照樣印 ✅」列為要避免的壞結果。Phase 3「不裝」那條在 9584605 就是這個形狀，這次把同一個問題複製到 Phase 1 和 Phase 2

S1-c-6｜Important｜設計文件引用了 F3、F4、F5c、F6，整份 repo 都找不到定義，指標指到空的。S2-1 要複製的檔案清單就靠 F3｜證據：`grep -nE 'F[0-9]+[a-z]?' docs/designs/2026-11-14-security-audit-intake-design.md`，F3、F4、F5c、F6 各只出現 1 次，而且都是引用。沒有任何一行以 `- F` 開頭，也沒有 `F6：`。引用處：設計文件:35 A12 `（F5c）`、:147 `見 F6`、:155 `清單見 F3`、:157 `見 F4`（diff 檔 1495、1607、1615、1617）。另外 :147 說「部署版 … 目前與 repo HEAD 逐字相同」，現在已經不成立：`cmp ~/.claude/scripts/dd-init-upgrade.sh` 與 `commands/dd-init.md` 的部署版都等於 `9584605` 那一版，跟 HEAD 不同｜照做的失敗情境：S2 由新的 session 照進度表接手，S2-1 第一項就是「清單見 F3」，找不到清單，只能自己猜要複製哪些檔

S1-c-7｜Smell｜同一個新小節裡兩句互相矛盾：第 41 行說 Write 會跟著懸空連結在專案外建檔，第 67 行說 Write、Edit 遇到 symlink 會拒絕（實測）｜證據：`commands/dd-init.md:40-41`（diff 檔 1137-1138）`Phase 0 第 3 步就會走建立模式，Write 跟著連結在專案外建檔`；`:67`（diff 檔 1164）`Write、Edit 遇到 symlink 會拒絕…（2026-11-14 Claude Code 2.1.325 實測）`。results.txt:45 裡 C2 在舊文字下是綠的，也不支持第 41 行的說法｜照做的失敗情境：維護者拿第 41 行當工具行為的依據，跟第 67 行的實測結論衝突。規則本身（要抓懸空連結）不受影響

S1-c-8｜Smell｜「照寫的後果」那幾條，套到 6step、7step、手寫版升級時有歧義：這幾種走 Edit 原地改，不走第 8 步的 `mv`，但它們被叫做「升級」｜證據：`commands/dd-init.md:56-57` 的 `建立、補充（Edit）…：改到的是連結目標` 與 `升級（第 8 步的 mv）：用一般檔取代連結本身。…連結目標不會更新`；`:86` `這幾種…不走升級腳本`。設計（diff 檔 285）列的後果有 `chmod`，定稿拿掉了；`.husky/pre-commit` 的「搬位置／換寫法」也沒列進去｜照做的失敗情境：6step 專案的 CLAUDE.md 是指到專案外的 symlink。agent 挑了「升級」那條去問，告訴使用者「連結目標不會更新」；使用者答「要」，實際上 Edit 改的就是專案外的目標

S1-c-9｜Smell｜照字面做會拿到誤導或空的結果：①第 6 步 exit 6 時用 `ls -l CLAUDE.md.dd-upgrade` 給使用者看，但腳本對目錄也回 exit 6，`ls -l` 一個目錄列的是裡面的內容、看不出它是目錄（應用 `ls -ld`）②第 3 步第 2 條「掛載點是 symlink 時一併附 `ls -l`」：印出來的路徑已經解析過，從它看不出掛載點原本是不是 symlink，文件也沒說要對哪個沒解析的路徑跑 ③`[ -L <路徑> ]` 單獨跑，一般情況就是「無輸出 + exit 1」，正是 `:319-321` 自己警告「會被誤修」的形狀｜證據：`commands/dd-init.md:99`、`:207`、`:40`；腳本的 exit 6 條件 `[ -e "$OUTFILE" ] || [ -L "$OUTFILE" ]`（scripts/dd-init-upgrade.sh:219）把目錄也算在內｜照做的失敗情境：T4 型（輸出路徑是既有目錄）時，使用者只看到 `total 0`，不知道擋住的是一個目錄

## Not reported
- 在 linked worktree 或 submodule 裡，`--git-path hooks/pre-commit` 會落在 toplevel 外，第 2 步每次都會問：同樣的條件在 9584605 就有了，這段沒有改變它
- A3 不處理 TOCTOU：威脅模型是「事先放好的 symlink」，並行攻擊不在範圍內，設計已經明寫
- 第 8 步備份檔 `CLAUDE.md.bak-<秒>`：要事先猜中那一秒才放得了 symlink，不可行
- `git rev-parse --show-toplevel` 與 `pwd -P` 的比對：git 的 toplevel 來自 getcwd，本來就是實體路徑，兩邊一致
- check.sh、mkprompt.sh、setup.sh 在步驟 3 的改動：逐項讀過，三個 case、`-z` 與 `wc -l`、`project_intro; echo` 的位元組都和原本等價
- check.sh 的斷言：symlink 臂靠專案外的 sha、權限、清單加上「symlink 還在」，有牙；問句那兩條讀的是自述，文件已寫明；H?K 用的擋下字串 `CLAUDE.md gate：commit 已擋下` 跟 `scripts/check-claude-md.sh:295` 對得上
- 修改都在蓋章區塊外，不必跳 `dd-loop-rev`：看了改動的行號，都不在 115-172 行內；CI step 也已經綠
- results.txt 的 sha：58e3edb → `6afa7ca1`、a0aa58a → `de1df4bc`，跟記錄相符；設計文件沒出現在 S1-1、S1-2 的 commit 裡（A13 成立）
- 去識別：量測目錄、設計文件、CHANGELOG 掃過，唯一命中是設計文件 A20 描述掃描樣式的那一句

## 需要外部查證
1. git < 2.31 跑 `git rev-parse --path-format=absolute --git-path hooks/pre-commit` 會印什麼（docker `debian:bullseye` 帶的 git 是 2.30，或 `ubuntu:20.04` 的 2.25）。如果它把不認得的 `--path-format=absolute` 原樣印出來、再接一行沒解析的 `.git/hooks/pre-commit`，S1-c-2 就是照字面做會寫到專案外，要升成 Critical
2. git 從哪一版起不讀 symlink 的 `.gitignore`（我記得是 2.32，不確定，建議驗證）。`commands/dd-init.md:59` 寫成通則，只在括號附 2.42.0；更舊的 git 上，「照寫也擋不住截圖進版控」這句不成立
3. Claude Code 的 Write 遇到懸空 symlink 是拒絕還是寫穿：A21① 與 results.txt 只有 Edit 的拒絕訊息原文，決定 S1-c-7 哪一句才對
4. 主對話（非 subagent）照 husky v9 分支跑完 Phase 3 後，下一次 Bash 的 `pwd`：用來確認 S1-c-3 會實際發生

## What I ran
- Read diff.txt 第 1–2942 行，每次 150 行 → 讀完
- `git status --short` → 只有量測目錄 3 個檔改了，另有 security-audit-trial 目錄 untracked
- `grep -nE 'F[0-9]+[a-z]?' <設計文件>` → F3、F4、F5c、F6 各 1 次；查 `^- F`、`F6：` → 0 筆
- `git grep -nE '\bF(3|4|5c|6)\b'` → 無輸出（ERE 的 `\b` 可能不生效，結論以上一條的檔內 grep 為準）
- 讀 `install-dd-pipeline.sh` 1295-1320、1360-1400 → `--commands-only` 會跳過 `create_scripts`
- `grep -n commands-only README*.md UPGRADING.md …` → README.md:67、README.zh-TW.md:68
- `grep -n 'commit 已擋下' scripts/check-claude-md.sh` → 第 295 行
- `git show <c>:commands/dd-init.md | shasum -a 256` → 58e3edb 是 6afa7ca1、a0aa58a 是 de1df4bc
- `git log --oneline 9584605..HEAD`、`git show --name-only cf093e7 58e3edb` → 設計文件不在這兩個 commit 裡
- `git show 9584605:commands/dd-init.md | grep …` → 9584605 的 Phase 6 範本與「使用者選擇不裝」和現在相同
- `cmp ~/.claude/{scripts/dd-init-upgrade.sh,commands/dd-init.md}` 對 HEAD 與 9584605 → 部署版等於 9584605；部署版裡 `exit 6` 出現 0 次
- `git -c core.hooksPath=/tmp rev-parse [--path-format=absolute] --git-path hooks/pre-commit` → 不加旗標印 `/tmp/pre-commit`，加了印 `/private/tmp/pre-commit`（git 2.42.0）
- `grep -rnE '/Users/|-Users-|/private/tmp|-private-tmp-|danlio' <量測目錄> <設計文件> CHANGELOG.md` → 1 筆，是設計文件 A20 描述掃描樣式的那一句
- `bash -n check.sh` → ok
- `grep -n` 列 dd-init.md 的 Phase 標題 → 對過行號
````

## 處置

- S1-c-1（Critical）採納：同 S1-a-2。它提的 A14（這條描述了 S1 沒修的寫出路徑、落地前先處理）：已在落地前修掉
- S1-c-2（Important → 照它的條件升為 Critical）採納：同 S1-a-3。它說 git < 2.31 若印旗標字串加沒解析的路徑就要升級 —— 實測正是如此，所以照 Critical 處理、修完才續行
- S1-c-3（Important）採納：同 S1-a-5
- S1-c-4（Important）採納：同 S1-b-3
- S1-c-5（Important）採納：Phase 6 的程式碼區塊後加「「已設定」只列實際做了的：「寫檔前」那節答「不要」跳過的、Phase 3 使用者選擇不裝的，那一行改寫成沒設定與原因
  （例如 `CLAUDE.md — 沒蓋章：它是指到專案外的 symlink`），不要照抄成已設定」。沙盒臂只做指定的 Phase、沒有臂跑 Phase 6，這條沒有實跑驗證
- S1-c-6（Important）採納：同 S1-a-8
- S1-c-7（Smell）採納：同 S1-a-4
- S1-c-8（Smell）採納：後果清單把 6step／7step／手寫版的升級（Edit 原地改）併進「改到的是連結目標」那條，`mv` 那條改名「用升級腳本升級（第 8 步的 `mv`）」；
  之後再補「搬位置／換寫法、`chmod`」兩項，H3、O 兩臂再各 1 次綠
- S1-c-9（Smell）採納：① `CLAUDE.md.dd-upgrade` 已存在或 exit 6 時改成 `ls -ld` ② Phase 3 第 2 步改成對沒解析的路徑跑 `ls -ld <沒解析的路徑>` ③ 檢查寫成 `[ -L <路徑> ] && echo 是 symlink || echo 不是 symlink`
- 「需要外部查證」：1 見 S1-a-3；2 已查 —— git 2.42.0、2.39.5 不讀 symlink 的 `.gitignore`（印 `Too many levels of symbolic links`），git 2.30.6 會讀，`commands/dd-init.md` 寫明版本；
  3 見 S1-a-4；4 沒跑，見 S1-a-5
