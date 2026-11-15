# S5 審查 — B（文件之間對不對得上、有沒有照規則同批同步）

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
**文件之間對不對得上、有沒有照規則同批同步**。根目錄 CLAUDE.md 的「新增 Skill 步驟」「新增 Command 步驟」「注意事項」（尤其講「CI 不驗、只能手動同步的區塊」那一條）與「第三方 Skill / Agent 收編檢查清單」第 7 項，列了增刪元件時要一起改的地方：逐項對這次 diff，找漏掉的。
兩份 README（英文 `README.md`、繁中 `README.zh-TW.md`）內容要一致：安裝步驟、指令一覽、Promoted Skills、授權表；表格有沒有壞（每一列都以 `|` 開頭）。`DD_PIPELINE_ARCHITECTURE.md`、`UPGRADING.md`、`CHANGELOG.md`（條目只能在 `## 未發布`；小節順序）、`tests/CLAUDE.md`、根目錄 CLAUDE.md 新加的句子：每一句宣稱自己去 repo 裡查是不是真的（例如「現在沒有任何測試跑到命名空間的複製、比對、刪 README.md 那段程式碼」「`--check` 也不會提到它們」「v1.6.14 是它們還在的最後一個版本」）。
全 repo 還有沒有把退場的兩個元件當成還在的句子（自己 `git grep`，不要只信審查包 V8 的清單；也找不含這兩個名字、但講的是它們的句子，例如「綜合審查」「命名空間指令」的數量或範例）。進度表的狀態、commits 欄、指路句照不照表下方的規則。

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
Critical 0 / Important 1 / Smells 4 — 範圍：S5（`git diff b3b2bf9 HEAD`，758dbc9 與 63f4d6c）。這次只查文件之間對不對得上、該同批改的有沒有漏。

【發現】
1｜Important｜兩份 README 寫升級和解除安裝的地方都沒跟上這次退場。照 README 做的人不會知道要自己清 `~/.claude/skills/review` 與 `~/.claude/commands/workflow-review`，而 README 對 `--uninstall` 的說法也因此變得不對。｜證據：`README.md:105`「For upgrades from older layouts and for moving an existing project onto the 8-step cycle, see [UPGRADING.md]」，`README.zh-TW.md:108`「從舊版部署升級、既有專案升級到 8 步迴圈：見 [UPGRADING.md](UPGRADING.md)。」，這兩句只列兩種情境，UPGRADING.md 現在有四種（`grep -n '^## ' UPGRADING.md` 印出 11/60/74/91 四個標題，第 91 行就是新加的「已退場的元件」）。`README.md:87`「`--uninstall` removes the skills, agents, commands, scripts and output styles this repo deployed」，`README.zh-TW.md:88`「`--uninstall` 移除這個 repo 部署的 skill、agent、指令…」，可是 `install-dd-pipeline.sh` 解除安裝只走 `ALL_SKILLS`／`ALL_DD_COMMANDS`／`ALL_NS_COMMANDS`（第 1268、1291、1295 行一帶），而 UPGRADING.md:97 自己也寫「`--uninstall` 也只認現行清單」。`README.md:67`／`README.zh-TW.md:68` 還寫安裝會刪掉「舊版這個 repo 部署過的指令檔」，只列 dd-help 那五個。｜會出事的情境：v1.6.14 以前裝過的人照 README 的「Routine update」跑 `git pull && ./install-dd-pipeline.sh --force`，`review` skill 留在 `~/.claude` 裡繼續自動觸發，去叫一個沒有授權的第三方指令。之後跑 `--uninstall`，README 說會移除這個 repo 部署的東西，實際上這兩個留著。根目錄 CLAUDE.md「安裝 / 更新」底下那句「從舊版（全量 / 分桶時期）升級、既有專案升級到 8 步迴圈：見 UPGRADING.md」也一樣只列兩種，不過同一檔第 37 行有指到新的那一節。｜建議改法：兩份 README 的 Upgrading 指路句補上「已退場元件要手動清」，連到 UPGRADING.md 那一節；`--uninstall` 那句加「只認現行清單，已退場的見 UPGRADING.md」。

2｜Smell｜`tests/CLAUDE.md` 新加的約束條目放錯節了。｜證據：`grep -nE '^#' tests/CLAUDE.md` 印出 `14:## 此層約束`、`121:## 與上層的關係`。新條目在第 125 行，直接接在「gate 本體的規則…CI 防線的總表在根目錄的 `DD_PIPELINE_ARCHITECTURE.md`。」那段散文後面，中間沒有空行，檔尾還多一行空行（`od -c` 結尾是 `\n\n`）。｜會出事的情境：讀「此層約束」的人找不到「加回命名空間 command 時要把斷言換回來」這條。｜建議改法：把這條搬進「## 此層約束」。

3｜Smell｜設計文件 S5-1 的結果寫的命中筆數和實際不合。｜證據：`docs/designs/2026-11-15-audit-fixes-design.md` S5-1 結果寫「`tests/CLAUDE.md` 兩句」。`git grep -nE 'workflow-review' 758dbc9 -- . ':!CHANGELOG.md' ':!UPGRADING.md' ':!docs/designs' ':!docs/reviews' ':!docs/measurements'` 在 tests/CLAUDE.md 只命中第 125 行一行，審查包 V8 也寫「tests/CLAUDE.md 一行」。｜會出事的情境：之後有人拿這份清單核對時，會以為少了一筆。｜建議改法：改成「一行（第 125 行那條）」。

4｜Smell｜S5-2 跳過了「新增 Skill 步驟」第 3 步規定的乾跑。｜證據：根目錄 `CLAUDE.md` 寫「部署前先乾跑（新增或改寫都要）」；設計文件 S5-2「沒做的：沒有照根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步把整份 `SKILL.md` 乾跑一遍」。理由有寫明，A/B 那 8 發跑的也正是新句子。｜會出事的情境：見第 5 條。乾跑要抓的是「哪一句只能用猜的」，A/B 測的素材沒碰到那幾個沒點名的偏好，抓不到。｜建議改法：接受這個理由就不用動；要照規則走，就派一個乾跑臂只讀 SKILL.md，逐句引出有疑問的句子交回。

5｜Smell｜新約束括號裡只點名了兩項偏好，可能被讀成完整清單。｜證據：`skills/code-simplifier/SKILL.md` 寫「agent 定義裡列的偏好（import 排序、`function` 與箭頭函式的取捨）不算專案標準」。`agents/code-simplifier.md:12-19` 的「Apply Project Standards」其實列了六項，另外四項是「Use explicit return type annotations」「explicit Props types」「avoid try/catch when possible」「consistent naming」。｜會出事的情境：在 TS 專案上，agent 把括號當成完整清單，照樣替頂層函式加回傳型別，或照「avoid try/catch」拿掉錯誤處理，而這些在專案 CLAUDE.md 裡都沒寫。前面那句「編碼風格只照專案 CLAUDE.md 寫明的」可以讀成涵蓋全部，但沒有實測過。｜建議改法：括號改成「例如 import 排序、`function`／箭頭函式、回傳型別標註、try/catch 的取捨」，或直接寫「該節列的每一項」。改了字之後，CHANGELOG 和設計文件裡的 A/B 證據就不算這個新句子的了，要照專案規則重跑。

【Not reported】
- CHANGELOG：新條目都在 `## 未發布`，小節順序是 Added、Changed、Removed、Fixed，跟 1.0.0 等舊版同序，不用報。
- 兩份 README：指令一覽、Promoted Skills（13 列）、授權表逐行都以 `|` 開頭；安裝步驟 2、6 與標題的數字中英一致。
- 「v1.6.14 是它們還在的最後一個版本」成立：最新 tag 就是 v1.6.14，裡面兩個檔都在，`git log v1.6.14..HEAD` 只有 758dbc9 動過這兩個目錄。
- UPGRADING.md 開頭的「四種升級情境」和標題數對得上。
- 「`grep -n 'NS_COMMANDS\|ns_cmd' tests/*.sh` 只剩註解」成立，只命中 `tests/test-install.sh:47` 一行，是註解。
- CI 的 `[0-9]+ 個命名空間 command 目錄` 在 CLAUDE.md 只會比到「0 個」那一處；第 147 行寫的是 `N`，不是數字。
- 「`--check` 也不會提到它們」：審查包 V6 已經實測過。
- `DD_PIPELINE_ARCHITECTURE.md` 的「`--uninstall` 只移除本 repo 部署過的檔案」用的是「只」，講的是上限，不算錯。
- 全 repo 再 grep 這幾個字：「綜合審查」「review 包裝」「`"review"`」「/workflow-review」「14 個」「1 個命名空間」，在部署內容與文件裡（排除 docs/reviews、docs/measurements、CHANGELOG）沒有一句把退場的元件當成還在；templates/global §7.2 那一列指的是 code-reviewer agent，不是退場的 skill。
- UPGRADING.md「要取回」那段的待辦清單沒列 `tests/CLAUDE.md` 的說明與 `NS_COMMANDS` 的註解，影響小，不報。
- ci.yml 改用 `find -type d` 之後，隱藏目錄會被算進去、指向目錄的 symlink 不會，跟 `ls -d */` 不一樣。這不在我的方向內，目前 `commands/` 也沒有這兩種東西。
- `--help` 會印「+ 0 個命名空間 Command」：計畫裡明寫照印。
- 進度表 S5 的 IN_PROGRESS、commits 欄 `b3b2bf9..`、根目錄的指路句，都合表下方的規則。

【What I ran】
- Read 派工檔 prompt-b.txt；Read 審查包 s5-review-pack.txt 三段（1–300、301–600、601–756）
- `git rev-parse --short HEAD && git status --short | wc -l` → 63f4d6c、0
- `git -c core.quotePath=false grep -nE 'workflow-review|skills/review|/review\b|綜合審查|comprehensive review|Combined|命名空間|namespace|NS_COMMANDS|NS command' -- . ':!docs/reviews' ':!docs/measurements' | grep -v '^CHANGELOG.md' | grep -v 'self-improving-agent/skills/review'`
- `sed -n 1,50p UPGRADING.md`；`grep -n 'prune_retired\|deprecated_dd' install-dd-pipeline.sh`；`git tag --sort=-creatordate | head -5`；`git log --oneline v1.6.14..HEAD -- skills/review commands/workflow-review`；`grep -n '^## ' UPGRADING.md`
- `grep -nE '\b1[34]\b' README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md CLAUDE.md`；`ls skills | wc -l; ls commands`
- `grep -niE 'command' DD_PIPELINE_ARCHITECTURE.md`／`README.md`
- `grep -nE '^## |UPGRADING' README.md README.zh-TW.md`；`sed -n 95,106p README.md`；`sed -n 96,109p README.zh-TW.md`；`sed -n 280,283p README.md`；`sed -n 294,299p README.zh-TW.md`
- `grep -nE '^##+ ' CHANGELOG.md`；`grep -nE '^## |^### (Removed|Fixed|Changed|Added|Deprecated)' CHANGELOG.md | grep -B3 -A1 Removed`
- `grep -nE '^#|^- \*\*' tests/CLAUDE.md`；`sed -n 100,128p tests/CLAUDE.md`；`grep -n 'NS_COMMANDS\|ns_cmd' tests/*.sh`
- `git -c core.quotePath=false grep -nE "ls -d commands|commands/\*/|xargs -n1 basename" -- . ':!docs/reviews' ':!docs/measurements'`
- `grep -niE '\breview\b' README.md`；`grep -nE '\breview\b|審查' README.zh-TW.md`
- 用 awk 掃兩份 README 指令一覽、Promoted Skills、授權表：表格後面接的都不是非 `|` 的行；`awk 'NR>=210&&NR<=236' README.zh-TW.md`
- `sed -n 28,50p docs/designs/2026-11-15-audit-fixes-design.md`
- `grep -nE 'workflow-review|skills/review' tests/CLAUDE.md`；`grep -n 'verification-gate\|T11_HOME' tests/test-install.sh`；`ls skills/verification-gate`
- `git -c core.quotePath=false grep -nE '14 (個|promoted|skills|Skills)|1 個命名空間|1 namespace|two commands|兩個指令' -- . ':!docs/reviews' ':!docs/measurements' ':!CHANGELOG.md'`；`git ls-files '*CLAUDE.md'`
- `git grep -nE '`review`|"review"|review skill|review 包裝|Skill\(skill="review|/review' -- skills agents templates commands scripts install-dd-pipeline.sh .github README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md CLAUDE.md | grep -v self-improving-agent`
- `git ls-tree -r --name-only v1.6.14 -- skills/review commands/workflow-review`；`git log --oneline -1 v1.6.14`；`git diff --stat v1.6.14 b3b2bf9 -- skills/review commands/workflow-review | wc -l` → 0；`git show v1.6.14:README.md | grep -n 'workflow-review\|review |'`
- `sed -n 286,298p; 1092,1100p; 1120,1160p install-dd-pipeline.sh`；`sed -n 1255,1300p install-dd-pipeline.sh | grep -nE 'ALL_SKILLS|for '`；`grep -nE 'dd-help|解除安裝' README.zh-TW.md`
- `cat skills/code-simplifier/SKILL.md`；`sed -n 12,22p agents/code-simplifier.md`
- `sed -n 53,82p; 84,96p; 150,162p DD_PIPELINE_ARCHITECTURE.md`
- `git show 758dbc9:tests/CLAUDE.md | grep -nE 'workflow-review|skills/review'`；`git -c core.quotePath=false grep -nE 'workflow-review' 758dbc9 -- . ':!CHANGELOG.md' ':!UPGRADING.md' ':!docs/designs' ':!docs/reviews' ':!docs/measurements'`
- `grep -nE 'workflow-review|skills/review|綜合審查' docs/reviews/CLAUDE.md templates/global/CLAUDE.md commands/dd-init.md scripts/dd-init-upgrade.sh` → rc=1；`tail -c 200 tests/CLAUDE.md | od -c`
- 沒有執行安裝腳本、沒有 source 它、沒有跑 tests/*.sh、沒有改任何檔。

【需要外部查證】
無
````

## 處置

| # | 級別 | 處置 | 查證 |
|---|---|---|---|
| 1 | Important | 採納 | 讀了兩份 README 的 `--uninstall` 那一段與「Upgrading」指路句、根目錄 CLAUDE.md「安裝 / 更新」那句：都沒提退場的元件要手動清。三處各補一句 |
| 2 | Smell | 採納 | `grep -nE '^#' tests/CLAUDE.md`：新條目落在「## 與上層的關係」底下。搬進「## 此層約束」結尾，檔尾多的空行拿掉 |
| 3 | Smell | 採納 | `git grep workflow-review` 在 `tests/CLAUDE.md` 只有一行；設計文件寫「兩句」是把提到 `review` skill 的 T11 那一句也算進去了。改成一行並寫明 |
| 4 | Smell | 駁回 | 改的只有 Prompt 模板的一行，A/B 跑的就是那一行送出去的內容；「哪一句只能用猜的」這次由審查者 b、c 讀那一句指出來了（見 5 與 c 的 3），沒有另外派乾跑臂。`description` 與觸發條件沒動 |
| 5 | Smell | 採納（與 c 的 3 併案） | `sed -n 12,19p agents/code-simplifier.md`：那一節確實不只兩項。句子改成點名那一節「列的每一項」並多舉兩項，改字後重跑 A/B（第三輪） |
