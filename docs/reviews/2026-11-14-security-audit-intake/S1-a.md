# S1-a：審查者 A（全面（所有檔、所有面向））

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），四個在同一則訊息平行派出。
派工 prompt 只有一句（逐字，路徑去識別）：

> 你的派工指示全文在 <S>/s1-review/prompt-a.txt —— 先用 Read 讀完整份，照它做，照它的輸出格式交回。

那份檔的全文（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad、`<REPO>` 是 claude-dd 的 clone；下面「發現」節同樣只換了路徑）：

````text
你是 claude-dd repo（<REPO>）S1 段落的程式碼審查者，代號 S1-a。
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

你的方向：全面（所有檔、所有面向）

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
每條：S1-a-<序號>｜級別｜一句話｜證據（diff 檔行號或 路徑:行，原文縮排貼出；或指令與輸出）｜照做的失敗情境
## Not reported
看過、判定不是問題的（一句話理由）
## 需要外部查證
## What I ran
````

## 發現

（逐字原文，只換了路徑）

````text
Critical 2 / Important 4 / Smell 2 — 審查範圍：`git diff 9584605` 到工作目錄（cf093e7 S1-1、58e3edb S1-2、a0aa58a S1-3，加上步驟 3 simplifier 還沒 commit 的改動）

下文的 `<S>` 指 <S>。repo 檔案路徑都相對於 <REPO>。

## Findings

S1-a-1｜Critical｜check.sh 對 B 臂 `.screenshots` 那一半的斷言結構上不可能變紅，results.txt 卻以「判定只看 check.sh」宣稱 B 綠｜
  證據：
  - 目標是已存在的目錄：
    - setup.sh:23–24 原文 `mkdir "$X/shots"`、`ln -s "$X/shots" "$R/.screenshots"`。
    - Phase 2 對這個路徑只做 `mkdir -p .screenshots`。symlink 指到既有目錄時，這條指令什麼都不寫（推論自 mkdir -p 的語意）。
  - 前兩道斷言不會動：check.sh:19–22 比對專案外的 sha、權限與清單，check.sh:25 驗 `[ -L ]`，這兩道都不會變。
  - 剩下兩道會被 `.gitignore` 那題滿足：check.sh:37 `grep -q '/outside'` 與 :44 `grep -qF -- ".screenshots"`。
    - <S>/m/new2/B/report.txt 問題 2 原文：「照寫的話，`echo '.screenshots/' >> .gitignore` 會改到專案外的檔」。
  - 宣稱的出處：results.txt:11「判定只看 check.sh」、results.txt:48「3/3 綠：B」。
  照做的失敗情境：
  - 文字退化成只問 `.gitignore`、`.screenshots` 不問就直接 `mkdir -p`，B 照樣 PASS。之後 playwright 的截圖會寫進專案外的目錄。
  - 留存的 new1–new4 B 回報確實各自另問了 `.screenshots`，所以這次的行為是對的。錯的是「這半有被驗到」這個宣稱。

S1-a-2｜Critical（前提：用 README 記載的 `--commands-only` 更新）｜dd-init.md 把 `CLAUDE.md.dd-upgrade` 交給腳本的 exit 6 擋，但 `--commands-only` 只部署新的 dd-init.md，留下沒有 exit 6 的舊腳本｜
  證據：
  - commands/dd-init.md:48 原文：「升級的輸出檔 `CLAUDE.md.dd-upgrade` 由升級腳本自己擋（已經存在就 exit 6）」。這條把該路徑排出了檢查清單。
  - commands/dd-init.md:91 第 1 步只看腳本存不存在，不看版本。
  - install-dd-pipeline.sh:1382 `create_commands` 無條件執行；:1385–1386 寫 `if [ "$COMMANDS_ONLY" = false ]; then create_scripts`。
  - `git show v1.6.14:scripts/dd-init-upgrade.sh | grep -c 'exit 6'` → 0。
  - README.md:67 記載了 `--commands-only`。
  - 同檔有對照的前例：dd-init.md:196–197 在 Phase 3 偵測舊版 gate，會提示 `git pull && ./install-dd-pipeline.sh --force`。Phase 1 對升級腳本沒有這種偵測。
  照做的失敗情境：
  1. 已裝 v1.6.14 的使用者 pull 後跑 `--commands-only`。
  2. 對一個 clone 來的專案跑 /dd-init：根目錄有 `CLAUDE.md.dd-upgrade -> /外部/x`，CLAUDE.md 是 8step 舊 rev。
  3. 使用者同意升級。第 6 步的舊腳本用 awk `print > out` 跟著連結寫到 /外部/x，這正是 S1-1 自己的前提。
  - 這和 S1 之前的行為相同、不是退步，所以可以降級。但在這條有文件記載的安裝路線上，S1 宣稱的保護不成立。

S1-a-3｜Important｜文件把「解析 symlink」歸給 `--git-path`，實際做這件事的是 `--path-format=absolute`，而 :198 只把那個 flag 說成「回絕對路徑」｜
  證據：
  - 實跑（git 2.42.0），在 <S>/m/base-old3/F/repo，其中 `.git/hooks/pre-commit -> …/F/outside/hook`：
    - `git rev-parse --git-path hooks/pre-commit` → `.git/hooks/pre-commit`
    - `git rev-parse --path-format=absolute --git-path hooks/pre-commit` → `<S>/m/base-old3/F/outside/hook`
  - 錯誤歸因出現在四處：
    - commands/dd-init.md:50「`git rev-parse --git-path` 印的是解析過 symlink 的路徑」
    - CHANGELOG.md:31「（`git rev-parse --git-path` 會解析 symlink）」
    - docs/designs/2026-11-14-security-audit-intake-design.md:127
    - results.txt:62「git 的 --git-path 解析 symlink」
  - dd-init.md:198 原文：「（git 2.31 起；在子目錄跑也回絕對路徑，…）」。
  - skills/worktree-manager/SKILL.md:56–58 把不帶 flag 的 `--git-path` 寫成 2.31 之前的替代寫法。
  照做的失敗情境：
  1. 維護者為了相容舊 git 或精簡指令，拿掉 `--path-format=absolute`。照文件的理由，這個 flag 只管「絕對路徑」。
  2. 印出來的路徑變成 `.git/hooks/pre-commit`，被判成在 repo 裡，於是不問。
  3. E、F、G、G2、I、H1、H2 那幾種連結又會被寫穿。

S1-a-4｜Important｜「Write 遇到 symlink 會拒絕」與「H3 照建議改寫目標」這兩個「實測」，在 m/ 下留存的回報裡找不到，而且 dd-init.md 同一節自己互相矛盾｜
  證據：
  - 同一節的兩句：
    - dd-init.md:67：「Write、Edit 遇到 symlink 會拒絕，並建議改寫連結目標的路徑（2026-11-14 Claude Code 2.1.325 實測）」
    - dd-init.md:40–41：「Phase 0 第 3 步就會走建立模式，Write 跟著連結在專案外建檔」
  - 拒絕只出現在 Edit：`grep -rl 'Refusing to write' <S>/m` 只命中 base-old2/C 與 base-old3/C，兩次都是 Edit。
  - 沒有任何一臂對 symlink 呼叫過 Write：C2、E 的回報都寫沒呼叫，例如 base-old3/C2/report.txt:19「我沒有執行它」。
  - H3 是直接寫目標，不是被拒後照建議：
    - <S>/m/base-old-h/H3/report.txt:5「用 Edit 直接改 symlink 的目標檔 `.../H3/outside/hook`」，前面沒有被拒絕的步驟。
    - results.txt:44 也只寫「用 Edit 對連結目標的路徑插入 gate」。
  - 以下兩處說的比 results.txt 多：
    - CHANGELOG.md:33「有一臂照建議對連結目標用 Edit」
    - design:48 A21①「兩個都不寫…H3 照建議對連結目標的路徑用 Edit」
  照做的失敗情境：
  - 讀者拿 :67 當工具層的保證，例如認定懸空連結走建立模式時「Write 會擋」。但 :41 的說法正好相反。
  - A21① 把「直接拿目標路徑寫」錯歸成「被拒後照建議寫」。後人會以為只要不照工具的建議做就安全。

S1-a-5｜Important｜dd-init.md:42 的父目錄檢查指令在主 session 會改掉之後所有 Bash 的 cwd（只影響 dirname 不是 `.` 的 `.husky/pre-commit`）｜
  證據：
  - dd-init.md:42 原文：`cd "$(dirname <路徑>)" && pwd -P`。
  - Bash 工具說明：「`cd` carries to the next call only in the main session, if the command succeeds and ends inside the working directories」。
  - 之後用相對路徑的指令：dd-init.md:264 `test -x <掛載點> || chmod +x <掛載點>`、:297 `git add CLAUDE.md`、:303 `git diff --cached --quiet -- CLAUDE.md`。
  - 沙盒臂驗不到這條，因為 subagent 每次呼叫都重設 cwd：
    - <S>/m/new-h1/H3K/report.txt:9 照字面跑了 `cd .husky && pwd -P`。
    - 同一份回報第 18 行的 `chmod +x .husky/pre-commit` 仍然成功。
  照做的失敗情境（推論，主 session 未實跑）：husky v9 專案在主 session 跑 /dd-init。
  1. 父目錄檢查跑完後，cwd 停在 `.husky`。
  2. `chmod +x .husky/pre-commit` 找不到檔。
  3. Phase 5 `git add CLAUDE.md` 報 pathspec 錯。
  4. `[ -f .gitignore ]` 為假，改走 else 分支；`git diff --cached --quiet -- CLAUDE.md` 回 0，commit 被安靜跳過，CLAUDE.md 沒進版控。
  - 改成 `(cd … && pwd -P)` 就不會發生。

S1-a-6｜Important｜懸空的 `CLAUDE.md` 答「要」之後，照字面走會卡住：模式判成補充，但沒有內容可讀，Edit 也建不了檔｜
  證據：
  - dd-init.md:31–32：「懸空的 symlink 算 symlink、不算不存在」「存在 → 補充模式（加在哪、要不要升級，照 Phase 1 的判斷）」。
  - dd-init.md:69：「使用者答「要」之後，就對連結目標的路徑用 Write、Edit 照原本的步驟寫」。
  - dd-init.md:87：「沒有標記也沒有 `## 開發流程` → 用 **Edit** 在末尾加入」。
  - 沒有臂覆蓋這條：
    - C2 只測「不要」（results.txt:10、21）。
    - Y 的連結不是懸空的（results.txt:31）。
  照做的失敗情境：
  1. 專案的 `CLAUDE.md -> AGENTS.md`，但 AGENTS.md 還沒建立。使用者答「要」。
  2. 進入補充模式後，Read 連結目標失敗，對不存在的檔用 Edit 也失敗。
  3. 文件沒說這時要改走建立模式、用 Write，執行的模型只能自己猜。

S1-a-7｜Smell｜第 2 步「印出來的路徑在不在 toplevel 底下」沒寫 `/` 邊界，同檔 :42 的父目錄檢查有寫｜
  證據：
  - dd-init.md:205：「「不在 repo 裡」看的是上面那行指令**印出來的路徑**在不在 `git rev-parse --show-toplevel` 底下」。
  - dd-init.md:42：「等於專案根目錄、或以「專案根目錄 + `/`」開頭」。
  - 9584605:commands/dd-init.md:163 原本就寫「（`git rev-parse --show-toplevel` 之外）」。S1 改寫了這句，而且讓它成為 husky v9 以外掛載點的唯一防線（design:139–140）。
  - 所有 fixture 都是 `repo/` 對 `outside/`，沒有共同前綴的情況。
  照做的失敗情境：
  - toplevel 是 `/w/app`，`.git/hooks/pre-commit -> /w/app-shared/hook`。
  - 用字串前綴比對的執行者會判成「在 repo 裡」，於是不問，寫到 /w/app-shared/hook。
  - 留存回報裡的臂都是目測比對，沒看到這種失誤，所以只列 Smell。

S1-a-8｜Smell｜設計文件引用的 F3、F4、F5c、F6 在 repo 裡沒有定義，而且 :147「部署版…目前與 repo HEAD 逐字相同，見 F6」在 commit 當下就不成立｜
  證據：
  - 引用位置：design:35（F5c）、:147（F6）、:155（F3）、:157（F4）。
  - `git grep` 找不到任何 F 編號的定義。定義只在 <S>/plan-facts-r1.md:15–23，`git ls-files | grep -c plan-facts` → 0。
  - :147 不成立：
    - `cmp ~/.claude/commands/dd-init.md commands/dd-init.md` → differ（line 30）。
    - 兩個部署檔都與 `git show 9584605:` 版本相同（cmp 通過）。
    - cf093e7、58e3edb 早於這份文件進 repo 的 a0aa58a，就已經改過這兩個檔。
  照做的失敗情境：
  - 公開 repo 的讀者或下一個 session 照「見 F6」找不到出處。
  - 照 :147 以為部署版已是最新，就不會去查「部署版是舊的」這個狀態，也就是 S1-a-2 那個狀態。

## Not reported
- dd-init.md:48、:110 的秒級時間戳備份檔 `cp`：要在剛好那一秒的檔名事先放連結，clone 無法預測，不算可行路徑。
- A3 TOCTOU：威脅模型是 clone 帶進來、事先就存在的連結。
- A15 沒有單獨成臂的變體（懸空 `.gitignore`；6step、7step、手寫版升級）：由同一道 `[ -L ]` 擋，C2、E、D 已覆蓋。
- A21② 安裝順序：那是 npm 與 pre-commit 自己的寫入，不是 /dd-init 的寫入。
- `mv` 到一個指向目錄的 CLAUDE.md：判模式前的 `[ -L CLAUDE.md ]` 會先問，而且 `--plan` 在 `[ -f ]` 就 exit 1。
- worktree 或 submodule 的 hooks 落在 toplevel 外：只會多問一題，是安全的方向。
- repo 內的 hook symlink 不問：寫入仍在 repo 內。
- check.sh 只驗 `[ -L ]`、不驗指向：檔頭 :3 已寫明這個限制。
- T1–T4：④ 的未修版跑出 7 則紅，與 tests/CLAUDE.md:12「拿掉 exit 6 → 那七則紅」一致。
- simplifier 改的 check.sh、mkprompt.sh、setup.sh：讀 diff 並對照 ④ 的等價核對，行為相同。
- 蓋章區塊沒動，不必跳 dd-loop-rev（④ 的 CI 綠）。
- results.txt 的計數與雜湊：
  - 所有 check.txt 的末行，對上各臂所用的文字版本，與 :36–59 一致。
  - 三個 sha 前綴（6afa7ca1、6bd5b025、de1df4bc）相符，m/dd-init-old.md 也是 6afa7ca1。
  - 「改了兩處」與 diff 結果相符（兩個 hunk：51、67–69）。
- 去識別：新進 repo 的量測檔、設計文件與 CHANGELOG 沒有本機路徑，只有 A20 的規則文字本身。
- 同批義務已做：CHANGELOG `## 未發布`、DD_PIPELINE_ARCHITECTURE.md:135、tests/CLAUDE.md、scripts/CLAUDE.md、根 CLAUDE.md 指路都有改。其他巢狀 CLAUDE.md 沒有 S1 會觸發的同批規則。
- exit 6 之後答「不要刪」：第 6 步「exit 非 0 → 不升級」已涵蓋。
- results.txt:71 D 說「答不要之後的模式判斷沒寫」：dd-init.md:31 已寫「使用者答「不要」就跳過 Phase 1」，第一版就有。
- 目前 `~/.claude` 的部署版等於 9584605：步驟 5 才部署，屬預期。只有 design:147 的敘述錯，見 S1-a-8。
- mkprompt.sh 的 awk `\n` 跳脫：正常。

## 需要外部查證
- check.sh:20 與 setup.sh:47 的 `stat -f '%Lp' … 2>/dev/null || stat -c '%a'`（setup-h.sh:34 沒有 fallback）：
  - GNU coreutils 的 `stat -f` 是檔案系統模式。我推測它會 exit 0 並印出別的東西，fallback 不會被觸發（不確定，建議驗證）。
  - 只有在 Linux 跑 check.sh 才受影響，目前都在 macOS 跑。
  - 指令：`docker run --rm debian:bookworm sh -c 'stat -f "%Lp" /etc/hostname; echo rc=$?'`
- git < 2.31 遇到 `--path-format=absolute` 會印什麼：dd-init.md:198 只寫「2.31 起」，沒寫更舊的 git 怎麼辦。
  - 指令：在 git 2.30 的容器裡跑 `git rev-parse --path-format=absolute --git-path hooks/pre-commit`。
- 主 session 的 cwd 延續（S1-a-5）：在 husky v9 fixture 上用主 session 跑 /dd-init。
  - 父目錄檢查之後跑 `pwd`；Phase 5 之後跑 `git log -1 -- CLAUDE.md`。
- Claude Code 2.1.325 的 Write 遇到 symlink 是拒絕還是寫穿（S1-a-4）：
  - 在拋棄式 repo 裡，對 `CLAUDE.md -> ../outside/x` 呼叫 Write，指向一般檔與懸空各試一次，再看 outside/x。
- tests/CLAUDE.md:12「空殼腳本 → 40 ❌」，④ 沒附這次的輸出：
  - 指令：`printf '#!/bin/bash\nexit 0\n' > <scratch>/shell.sh && chmod +x <scratch>/shell.sh && tests/test-dd-init-upgrade.sh <scratch>/shell.sh 2>&1 | grep -c '^❌'`，預期 40。測試第 12 行有 `UP="${1:-…}"`，可以接腳本路徑。

## What I ran
- 用 Read 每次 150 行讀 <S>/s1-review/diff.txt → 1–2942 全讀完
- `git -c core.quotePath=false grep -nE 'dd-upgrade|exit 6|2–5|2-5 見|git-path|寫檔前|三個模式都不改原檔' -- . ':!docs/reviews'` → 引用點全數列出
- `grep -rl 'Refusing to write' <S>/m`，再對 C 的兩份 grep 那一行 → 只有 base-old2/C、base-old3/C，都是 Edit
- 對 base-old3/G、base-old-h/H3、C2（三輪）、base-old2/E 的回報 grep Edit、Write、heredoc → 都是直接寫目標，沒有對 symlink 呼叫 Write
- 用 awk 抽 new1–new4 B 回報的問句段 → 每份都另問了 `.screenshots`；new2 的 `.gitignore` 題含 `'.screenshots/'`
- 用 shasum 核 58e3edb、HEAD、工作目錄、m/dd-init-old.md、dd-init-new.md、dd-init-new2.md → 6afa7ca1、de1df4bc、de1df4bc、6afa7ca1、6bd5b025、de1df4bc
- `diff m/dd-init-new.md commands/dd-init.md` → 兩個 hunk（51、67–69）；dd-init-new2.md → 無差異
- `git show v1.6.4:commands/dd-init.md | grep -o 'dd-loop-rev: [0-9]*'` → 9
- `git show v1.6.14:scripts/dd-init-upgrade.sh | grep -c 'exit 6'` → 0
- 用 `cmp` 比部署版與工作目錄、部署版與 `git show 9584605:` → 前者 differ，後者相同（兩個檔都是）
- `sed -n 1360,1400p install-dd-pipeline.sh`，並 grep `--commands-only` → create_scripts 只在 COMMANDS_ONLY=false 時執行；README.md:67 有記載
- 在 m/base-old3/F/repo 帶與不帶 `--path-format=absolute` 跑 `git rev-parse --git-path hooks/pre-commit` → `.git/hooks/pre-commit` 對 `<S>/m/base-old3/F/outside/hook`
- 取所有 m/*/*/check.txt 的末行，並從 prompt.txt 對出各臂用的文字版本 → 計數與 results.txt:36–59 一致
- `grep -rnE '/Users/|-Users-|/private/tmp|-private-tmp-|danlio|claude-501'` 掃量測目錄、設計文件與 CHANGELOG → 只命中 A20 的規則文字
- `git ls-files '*CLAUDE.md'`，再於各層 grep 同批、同時改、同步、一起改 → 沒有 S1 漏做的
- `git grep` F 編號，並 grep <S>/plan-facts-r1.md → repo 內沒有定義；定義在 plan-facts-r1.md:15–23
- 對 new*/E、F、G、G2、I 與 new-h1/H1、H2 的回報 grep 前綴比對的寫法 → 沒有，都是目測
- 用 `sed -n` 讀 dd-init.md 24–34、35–70、86–104、196–208、293–306，grep 備份、chmod、git add 的行號，並再 grep 一次核對所引行號
- `git log --stat 9584605..HEAD` → 三個 commit 的檔案清單
- `git grep dd-init-upgrade` 掃 README 兩份、UPGRADING、CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、.github、skills、templates → 沒有過期的宣稱
- `sed -n 12p tests/CLAUDE.md`、grep tests/test-dd-init-upgrade.sh 的參數 → 「40 ❌」、7 則紅、`UP="${1:-…}"`

Not reported：untracked 的 docs/measurements/2026-11-14-security-audit-trial/ 照指示不在範圍內。GNU stat、舊版 git、主 session 的 cwd、Write 遇到 symlink 這四件需要容器或主 session 才能實跑，列在「需要外部查證」。
````

## 處置

- S1-a-1（Critical）採納：`check.sh` 改成每條連結各查一次問句有沒有附「它自己的」連結目標（`links.txt` 逐行 `readlink`、去掉 `<BASE>/<臂>/` 前綴後 `grep -F`），不再只查有沒有 `/outside`。
  負面測試：B 的回報刪掉 `.screenshots` 那幾行 → 紅在「問句沒附 ./.screenshots 的連結目標」「問句沒提到 .screenshots」，還原後綠。存起來的 B 回報用新版重判都沒翻
- S1-a-2（Critical）採納：Phase 1「用升級腳本升級」第 6 步在 `--apply` 之前先跑 `{ [ -e CLAUDE.md.dd-upgrade ] || [ -L CLAUDE.md.dd-upgrade ]; }`，在就 `ls -ld`、問、不刪、不跑 `--apply`，
  並寫明「舊版升級腳本不會自己擋（用 `--commands-only` 更新的人手上可能是舊版腳本）」；「寫檔前」那節改成指向第 6 步。
  加臂 AO（升級腳本換成 9584605 的舊版）：a0aa58a 的文字下紅（連結目標被蓋掉、沒問），修正後的文字下 3/3 停在第 6 步
- S1-a-3（Important）採納：四處歸因改正（`commands/dd-init.md`「寫檔前」那節、CHANGELOG、設計文件、`results.txt`），寫明解析靠的是 `--path-format=absolute`、只寫 `--git-path` 印的是沒解析的相對路徑。
  「需要外部查證」的 git < 2.31 已查：alpine:3.13 的 git 2.30.6 印兩行（`--path-format=absolute` 本身、沒解析的 `.git/hooks/pre-commit`），exit 0。
  所以 Phase 3 第 2 步加了退路：輸出要剛好一行、`/` 開頭，否則就是 git 舊於 2.31，改用 `git rev-parse --git-path hooks/pre-commit` 的相對路徑照「寫檔前」那節檢查。
  加臂 O、OI（git 2.30.6）：a0aa58a 的文字下兩臂是綠的（subagent 自己發現、臨場補），修正後的文字下各 1 次綠，照退路判斷
- S1-a-4（Important）採納：「需要外部查證」的 Write 已查（主對話，Claude Code 2.1.325，拋棄式目錄）：Write、Edit 對指向存在的檔與懸空的 symlink 都拒絕。
  `commands/dd-init.md`「寫檔前」那節拿掉「Write 跟著連結在專案外建檔」半句（留下「`[ -e ]` 與 Glob 都把它當成不存在，Phase 0 第 3 步就會走建立模式」），結尾那段寫明「（含懸空的）」；
  H3 的歸因在 CHANGELOG 與設計文件 A21 ① 改成「直接對連結目標的路徑用 Edit」
- S1-a-5（Important）採納：父目錄檢查改成 `(cd "$(dirname <路徑>)" && pwd -P)`，並寫「括號不能省：主對話的 Bash 會把 `cd` 留到下一次呼叫」。
  「需要外部查證」的主對話實跑沒做：改法不靠它成不成立（子 shell 不會留下 cwd）
- S1-a-6（Important）採納：「答「要」」那條寫明連結目標還不存在就照建立模式、對連結目標的路徑用 Write。
  加臂 YD（`CLAUDE.md` 指向還不存在的 `AGENTS.md`）：a0aa58a 的文字下紅（`AGENTS.md` 建了但沒進版控），修正後的文字下 3/3 綠
- S1-a-7（Smell）採納：Phase 3 第 2 步「不在 repo 裡」加 `/` 邊界（「等於它、或以它加 `/` 開頭；`/w/app-shared/…` 不在 `/w/app` 底下」）
- S1-a-8（Smell）採納：設計文件的 F3、F4、F5c 換成內容本身（F3 的上游檔逐一列出），F6 那句改成「規劃時 `cmp` 過…；S1 的 commit 都還沒部署」
- 「需要外部查證」的 GNU `stat -f` 已查（node:22-bookworm 的容器）：印檔案系統資訊、把 `%Lp` 當檔名、exit 1，`|| stat -c` 再補一行，`before.txt` 會帶著會變的 free blocks。
  腳本沒改，量測目錄 CLAUDE.md 與 `results.txt` 寫明只在 macOS 跑
- 「需要外部查證」的空殼腳本 40 ❌ 已查：`tests/test-dd-init-upgrade.sh <空殼>` → 24 ✅、40 ❌（2026-11-14，步驟 5 重跑時）
