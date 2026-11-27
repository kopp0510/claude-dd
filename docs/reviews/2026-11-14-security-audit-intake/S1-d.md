# S1-d：審查者 D（文件與量測的宣稱）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），四個在同一則訊息平行派出。
派工 prompt 只有一句（逐字，路徑去識別）：

> 你的派工指示全文在 <S>/s1-review/prompt-d.txt —— 先用 Read 讀完整份，照它做，照它的輸出格式交回。

那份檔的全文（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad、`<REPO>` 是 claude-dd 的 clone；下面「發現」節同樣只換了路徑）：

````text
你是 claude-dd repo（<REPO>）S1 段落的程式碼審查者，代號 S1-d。
你的職責：找漏洞。每條發現都要附證據（diff 檔的行號與原文、你讀到的檔案路徑:行、或你跑的指令與輸出）；沒證據的不算。不寫優點。

審查範圍：S1 整段，`git diff dd8b5a9` 起到工作目錄（3 個 commit：88ae4e2 S1-1、b6e3666 S1-2、bc22fed S1-3，加上步驟 3 code-simplifier 還沒 commit 的改動）。
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

你的方向：文件與量測的宣稱：results.txt、CHANGELOG ## 未發布、設計文件 S1 的實作紀錄、scripts/CLAUDE.md、tests/CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、量測目錄 CLAUDE.md 的每一句，對照程式碼與 check.sh／setup.sh 實際做的事；特別是「check.sh 驗了 X」這類句子是否屬實

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
- 拿不準是不是既有問題時，去看那幾行在 dd8b5a9 是不是已經長這樣；這段把同一個錯寫法複製到新地方，也算這段的問題

輸出格式（照抄標題）：
## Findings
每條：S1-d-<序號>｜級別｜一句話｜證據（diff 檔行號或 路徑:行，原文縮排貼出；或指令與輸出）｜照做的失敗情境
## Not reported
看過、判定不是問題的（一句話理由）
## 需要外部查證
## What I ran
````

## 發現

（逐字原文，只換了路徑）

````text
Critical 1 / Important 7 / Smells 3 —— S1 整段（git diff dd8b5a9 到工作目錄，含步驟 3 還沒 commit 的改動），方向：文件與量測的宣稱

## Findings

S1-d-1｜Critical｜部署版升級腳本是舊版時，新小節把 `CLAUDE.md.dd-upgrade` 交給「腳本自己擋」，但沒有任何一步確認腳本真的有 exit 6
- 證據：
  - `commands/dd-init.md:48` `升級的輸出檔 \`CLAUDE.md.dd-upgrade\` 由升級腳本自己擋（已經存在就 exit 6）…不用檢查`
  - `commands/dd-init.md:91` 第 1 步只查腳本存不存在。Phase 3 有前例：`:195` 會 grep `--start-segment` 認出舊版 gate
  - `install-dd-pipeline.sh:1382` 的 `create_commands` 每次都跑；`:1385-1386` 的 `create_scripts` 在 `--commands-only` 時跳過。這個 flag 寫在 README.md:67
  - `cmp` 結果：目前部署的 `~/.claude/scripts/dd-init-upgrade.sh` 和 `commands/dd-init.md` 都等於 dd8b5a9 那一版
- 照做的失敗情境：
  1. 前提：機器上部署的是 S1 之前的腳本，使用者跑 `git pull && ./install-dd-pipeline.sh --commands-only`。
  2. 結果是新的 dd-init.md 配上沒有 exit 6 的舊腳本。
  3. 對一個 clone 跑 `/dd-init`：CLAUDE.md 是 8step 舊區塊，`CLAUDE.md.dd-upgrade` 是事先放好、指到專案外的 symlink。
  4. Phase 0 的 `[ -L CLAUDE.md ]` 不成立，新小節又寫了輸出檔不用檢查，第 6 步就跑 `--apply`。
  5. 舊腳本 exit 0、寫到專案外。④ 已經記下未修腳本對這個情境 exit 0、外部檔被改。
- 修法不只一種：可以照 Phase 3 第 1 步的做法認出舊版腳本，也可以讓新小節也檢查 `CLAUDE.md.dd-upgrade`。

S1-d-2｜Important｜四處說「`git rev-parse --git-path` 會解析 symlink」，都漏了 `--path-format=absolute`；不加這個旗標，印的是沒解析過的相對路徑
- 證據：
  - 出現在 `commands/dd-init.md:50`、`CHANGELOG.md:31`、設計文件 `:127`、`results.txt:62`
  - 實測量的指令是加了旗標的那一版（設計文件 `:139`，舊文字 G 回報第 3 點）
  - 我對 scratchpad 的 fixture 跑了兩種寫法（唯讀）：
    - `m/base-old3/F/repo`：不加旗標 → `.git/hooks/pre-commit`；加旗標 → `<S>/base-old3/F/outside/hook`
    - E：`.git/hooks/pre-commit` 對 `…/outside/nope-hook`
    - I：`.githooks/pre-commit` 對 `…/outside/hooksdir/pre-commit`
  - repo 自己的 `skills/worktree-manager/SKILL.md:56-58` 也寫了不加旗標「回的是相對路徑」
- 照做的失敗情境：有人照這幾句的寫法驗證，或把第 2 步的指令縮短成這裡寫的形式，拿到的 `.git/hooks/pre-commit` 在 toplevel 底下，就判定「在 repo 裡」、不問。E、F、G、G2 這類掛載點會寫到專案外。這幾句正是「其他掛載點不進新小節」的唯一理由。

S1-d-3｜Important｜Write 遇到 symlink 會怎樣，同一小節前後兩句相反；「Write 會拒絕」標成實測，但實測裡 Write 從來沒被呼叫過
- 證據：
  - `commands/dd-init.md:41` `Phase 0 第 3 步就會走建立模式，Write 跟著連結在專案外建檔`
  - `:67` `Write、Edit 遇到 symlink 會拒絕…（2026-11-14 Claude Code 2.1.325 實測）`
  - 設計文件同樣互相矛盾：A2（`:25`）寫「建立（Write）、補充（Edit）會寫穿」，A21 ①（`:48`）寫「兩個都不寫」。CHANGELOG.md:33 照抄了 A21
  - scratchpad 全目錄 grep `Refusing to write`，只命中 `m/base-old2/C`、`m/base-old3/C` 的回報，兩次都是 Edit
  - `m/base-old3/C2/report.txt:19`：`Phase 1 建立模式的動作是用 Write 寫入 CLAUDE.md。我沒有執行它。`
- 照做的失敗情境：兩句至少一句是錯的。讀者信 `:67`，會以為懸空 CLAUDE.md 下的 Write 有工具擋著；信 `:41`，就跟 `:67` 的「實測」衝突。Write 的那一半沒有證據。

S1-d-4｜Important｜CHANGELOG 和 A21 說舊文字下 H3「照建議」對連結目標用 Edit，但 H3 回報裡沒有出現過拒絕
- 證據：
  - `CHANGELOG.md:33` `舊文字下有一臂照建議對連結目標用 Edit`；設計文件 A21 ①（`:48`）寫「舊文字下 H3 照建議對連結目標的路徑用 Edit」
  - `results.txt:44` 只寫 `H3：用 Edit 對連結目標的路徑插入 gate`
  - scratchpad `m/base-old-h/H3/report.txt` 的【做了什麼】第 5 步是 `用 Edit 直接改 symlink 的目標檔`，前面沒有對 `.husky/pre-commit` 的 Edit，也沒有拒絕訊息
- 照做的失敗情境：公開的 CHANGELOG 寫了一條實測裡沒出現的因果（工具拒絕 → 模型照建議改寫目標）。「拒絕不是防護」這個結論仍然由 H3、G 撐著，錯的只是歸因。

S1-d-5｜Important｜check.sh 對 B 的 `.screenshots` 沒有鑑別力：只問 `.gitignore` 的回報也會判綠
- 證據：
  - `check.sh:39` B 的名字清單是 `.gitignore .screenshots`
  - `check.sh:44` 用 `grep -qF -- "$n"`，只比對子字串
  - `setup.sh` 的 B 把 `.screenshots` 連到已經存在的目錄，所以 `mkdir -p` 什麼都不做，專案外的檔問不問都不變
  - 實際的 `.gitignore` 問句本來就含這個字串，例如 `m/new2/B/report.txt` 問題 2 的「`echo '.screenshots/' >> .gitignore` 會改到專案外的檔」。`/outside` 斷言（`:37`）也能由 `.gitignore` 的 `ls -l` 滿足
- 照做的失敗情境：subagent 只檢查 `.gitignore`，對 `.screenshots` 直接 `mkdir -p`、不問 → `check.sh B` 仍然 PASS。進度表驗收與設計文件「兩個路徑都要有問句」的那一半沒人驗。

S1-d-6｜Important｜check.sh 沒驗臂 A 的「CLAUDE.md 不變」，exit 6 之後繞路升級也會判綠
- 證據：
  - 設計文件 `:96` 的 S1-2 驗收：`假檔 sha 不變、symlink 還在、CLAUDE.md 不變`
  - `check.sh` symlink 分支（18–45 行）對 A 只驗外部檔、`CLAUDE.md.dd-upgrade` 還是 symlink、問句含 `/outside` 與名字，沒有任何 `CLAUDE.md` 斷言。`m/check.sh.bak` 也沒有
- 照做的失敗情境：
  1. subagent 遇到 exit 6，先問過，再改用 `--apply CLAUDE.md CLAUDE.md.dd-upgrade2`。
  2. 接著 `mv` 完成升級，違反第 6 步的「exit 非 0 → 不升級」。
  3. symlink 和外部檔都沒動 → `check.sh A` PASS，`results.txt` 的「A 2/2 綠」也會把它算進去。

S1-d-7｜Important｜設計文件引用 F3、F4、F5c、F6，但整份文件沒有定義它們；F6 那句「目前與 HEAD 逐字相同」也已經不成立
- 證據：
  - 引用處：`:147` `（部署版 \`scripts/dd-init-upgrade.sh\`、\`commands/dd-init.md\` 目前與 repo HEAD 逐字相同，見 F6）`；`:155` `清單見 F3`；`:157` `見 F4`；`:35` `（F5c）`
  - 全檔 grep `\bF[0-9]+[a-z]?\b` 只命中這 4 行，都是引用
  - `cmp`：部署版兩個檔都等於 dd8b5a9、不等於 HEAD（bc22fed）
- 照做的失敗情境：S2-1 接手的人去找「清單見 F3」（要原樣複製的上游檔清單），在進 repo 的文件裡找不到。`:147` 那句寫成「目前」，S1 改過這兩個檔之後就是錯的。

S1-d-8｜Important｜A3 明寫「TOCTOU 不處理」，照 A14 自己的判準算命中，卻沒有照 A14 的處置就進了公開 repo
- 證據：
  - 設計文件 `:26` `A3：檢查與寫檔之間的 TOCTOU 不處理`
  - 設計文件 `:37` A14 判準：`原文描述了一條能讓寫入落到專案外、而 S1 沒修的路徑。命中時預設處置：在 S1 補一個小任務修掉…修不了才停下問`
- 照做的失敗情境：
  - 共用專案目錄裡，另一個有寫入權限的本機使用者，可以在 `[ -e ]`／`[ -L ]` 檢查和 `>>`／awk `print > out` 之間把 `.gitignore` 或 `CLAUDE.md.dd-upgrade` 換成 symlink，寫入就落到專案外。
  - 這是 S1 沒修、而且文件寫出來了的路徑。處置屬於使用者決定（接受風險並記下理由，或修）。

S1-d-9｜Smell｜可能的 Speculative Generality：新小節的「父目錄解析後還在專案裡」沒有任何一臂走到，進度表驗收卻列了它
- 證據：
  - 規則在 `commands/dd-init.md:42-43`
  - 設計文件 `:127` 自己寫了 I 在第 2 步就被擋下
  - 其他臂的目標路徑都在專案根目錄（B、C、C2、D、Y）；H3 換的是檔、不是 `.husky` 目錄
  - 設計文件 `:54` 的驗收仍列「掛載點的父目錄…都停下問」
- 照做的失敗情境：把父目錄那條規則整條刪掉，所有臂照樣全綠。

S1-d-10｜Smell｜Phase 6 的完成訊息是固定文案，新加的「答不要」分支會讓它照抄時說錯話
- 證據：
  - `commands/dd-init.md:337-339` 固定印 `├── CLAUDE.md — 8 步開發迴圈…`、`├── .screenshots/ + .gitignore（有前端時）`
  - 新小節 `:62-63` 寫答「不要」→ 不蓋章，或只跳過那一行
- 照做的失敗情境：Phase 1 答「不要」之後照抄 Phase 6，告訴使用者 CLAUDE.md 已設定。Phase 3「不裝」既有同樣問題，這段把它複製到 Phase 1、2。

S1-d-11｜Smell｜「H?K 會在容器裡實跑 npm install」對 H1K 不成立
- 證據：
  - `docs/measurements/2026-11-14-dd-init-symlink/CLAUDE.md:13` `H?K 會在容器裡實跑 \`npm install\` 與一次 commit`
  - `check.sh:6` `H?K 另在容器裡實跑：npm install 後 gate 還在`
  - H1K 分支（`check.sh:69`）跑的是 `pre-commit validate-config && pre-commit install`，沒有 npm
- 照做的失敗情境：照這兩句去重現 H1K 的人會跑錯工具，或在核對時找不到 npm install 的步驟。

## Not reported
- sha 都對：6afa7ca1 是 b6e3666 的 dd-init.md；de1df4bc 是 bc22fed 的版本，也等於工作目錄；6bd5b025 是 scratchpad 的 `m/dd-init-new.md`。第一版和定稿的 diff 剛好兩處，和 results.txt:13-14 一致
- results.txt 說 D 的 fixture 是「rev 9」：v1.6.4 的標記確實是 `dd-loop-rev: 9`
- `commands/dd-init.md:92` 寫「2–5 見腳本檔頭」：那句只用在 `--plan`，`--plan` 不會回 6
- A13：設計文件只出現在 bc22fed；S1-1、S1-2 只送了自己的檔
- 去識別：在量測目錄、設計文件、CHANGELOG 用 git grep `-Users-|-private-tmp-|/Users/|/private/tmp` 掃，只命中 A20 描述規則那一句
- tests/CLAUDE.md 寫空殼變異 40 ❌：等於原本 36 加四則 exit 6 的 exit 碼斷言，和新增的測試結構一致（我沒重跑）
- 「S1-2 那次同一個 check.sh 判綠」：`m/check.sh.bak` 已經有同一條 `/outside` 斷言，沒有反證
- T1「symlink 還在」在「拿掉 exit 6 檢查」的變異下照樣綠：tests/CLAUDE.md 已寫明
- 步驟 3 改了量測目錄的 .sh，`CODE_EXT` 含 `sh`，步驟 6 commit 時 gate 會要求同批送那個目錄的 CLAUDE.md。這是流程提醒，不是缺陷
- cwd 本身是 symlink 子目錄時跑 /dd-init：寫入落在使用者所在的實體目錄，是使用者選的位置，不列

## 需要外部查證
- Claude Code 2.1.325 的 Write 遇到既有 symlink、遇到懸空 symlink，是拒絕還是寫穿。這會決定 S1-d-3 要留 `:41` 還是 `:67`
- Linux 上 GNU coreutils 的 `stat -f '%Lp' <檔>`：我推論它會把 `%Lp` 當成檔名，先印檔案系統資訊、exit 1，接著 `|| stat -c '%a'` 再補一行。若是這樣，`before.txt`／`now` 會帶著會變動的 free blocks，在 Linux 重跑時 check.sh 會誤判紅燈（`setup.sh:47`、`check.sh:20`；`setup-h.sh:34` 沒有 fallback）。本機沒有 gstat，所以沒列成發現
- 拋棄式 HOME 跑一次 `./install-dd-pipeline.sh --commands-only`，實測確認 scripts 沒有更新。目前只讀了程式碼（S1-d-1）

## What I ran
- Read diff.txt 第 1–2942 行（每次 150 行）→ 讀完
- `git show b6e3666|bc22fed:commands/dd-init.md | shasum -a 256`；`shasum commands/dd-init.md` → 6afa7ca1…、de1df4bc…、de1df4bc…
- `git show v1.6.4:commands/dd-init.md | grep dd-loop-rev` → rev 9
- `grep -nE '\bF[0-9]+[a-z]?\b' <設計文件>` → 只命中 :35、:147、:155、:157，沒有定義
- `git log --oneline -- <設計文件>`；`git show --stat` 三個 commit → 設計文件只在 bc22fed
- `grep -n commands-only install-dd-pipeline.sh`；Read 1360–1404 → `create_commands` 每次都跑，`create_scripts` 在 commands-only 時跳過
- `cmp` 部署版 vs repo、部署版 vs dd8b5a9 → 不等於 HEAD，等於 dd8b5a9
- `grep -n CODE_EXT= scripts/check-claude-md.sh` → 含 sh
- `git grep` `2–5|exit 5`、`dd-upgrade`、`--git-path`（排除 docs/reviews）→ 見上
- `sed -n 52,60p skills/worktree-manager/SKILL.md` → 不加 `--path-format` 時「回的是相對路徑」
- scratchpad：`ls`、`grep -rl 'Refusing to write'` → 只有 C 臂的回報（Edit）
- 讀 `m/base-old3/C2/report.txt`（grep）、`m/base-old-h/H3/report.txt`（整份）、`m/base-old3/G/report.txt`（grep）→ C2 沒呼叫 Write；H3 直接 Edit 連結目標、沒有拒絕
- 印所有 B 回報的問句段落 → 新文字下的 `.gitignore` 問句都含 `.screenshots/`
- 對 `m/base-old3/{F,E,I}/repo` 跑 `git rev-parse --git-path hooks/pre-commit`，加與不加 `--path-format=absolute` → 不加：repo 內的相對路徑；加：解析到 outside 的路徑
- `shasum m/dd-init-new.md m/dd-init-new2.md`；`diff m/dd-init-new.md commands/dd-init.md` → 6bd5b025、de1df4bc；差異剛好兩處
- `grep m/check.sh.bak` → 已有 `/outside` 斷言，沒有 CLAUDE.md 斷言
- `git grep -nE '(-Users-|-private-tmp-|/Users/|/private/tmp)'`，範圍是量測目錄、設計文件、CHANGELOG → 只有 A20 那句
- `grep UPGRADING.md`、`grep README* --commands-only`、`command -v gstat` → UPGRADING 沒有 exit 碼清單；README.md:67 有記這個 flag；沒有 gstat
- 每個引用的行號都用 `sed -n` 印出來對過原文

相關路徑：
- <REPO>/commands/dd-init.md
- <REPO>/CHANGELOG.md
- <REPO>/docs/designs/2026-11-14-security-audit-intake-design.md
- <REPO>/docs/measurements/2026-11-14-dd-init-symlink/check.sh
- <REPO>/docs/measurements/2026-11-14-dd-init-symlink/results.txt
- <REPO>/docs/measurements/2026-11-14-dd-init-symlink/CLAUDE.md
- <REPO>/install-dd-pipeline.sh
- <REPO>/skills/worktree-manager/SKILL.md
````

## 處置

- S1-d-1（Critical）採納：同 S1-a-2
- S1-d-2（Important）採納：同 S1-a-3
- S1-d-3（Important）採納：同 S1-a-4
- S1-d-4（Important）採納：同 S1-a-4 的後半（H3 的歸因）
- S1-d-5（Important）採納：同 S1-a-1
- S1-d-6（Important）採納：`check.sh` 對 A、AO 加「CLAUDE.md 沒被升級（還是 rev 9、沒有 rev 13）」與「沒有 `CLAUDE.md.bak-*`」。
  負面測試：A 的 `CLAUDE.md` 換成 rev 13 → 紅在「被升級或改掉了」；多放一個 `.bak-*` → 紅在「有升級第 8 步的備份檔」；還原後綠
- S1-d-7（Important）採納：同 S1-a-8
- S1-d-8（Important）駁回：A3「檢查與寫檔之間的 TOCTOU 不處理：威脅是「clone 帶進來的 symlink」，事先存在、不是並行建立」是計畫審查時定的範圍。
  這條的情境要「另一個對專案目錄有寫入權限的本機使用者」，那個人不必搶時間差，直接改 `.git/hooks/pre-commit` 或專案裡的程式碼就能做更多事，TOCTOU 沒有讓他多出能力。
  S1-a、S1-b、S1-c 三份都把 A3 列進 Not reported
- S1-d-9（Smell）不改：父目錄那條有臂走到 —— OI（git 2.30.6）退回沒解析的 `.githooks/pre-commit` 之後，路徑本身不是 symlink，是父目錄 `.githooks` 那條擋下的（修正後的文字下 1 次綠）。規則保留
- S1-d-10（Smell）採納：同 S1-c-5
- S1-d-11（Smell）採納：同 S1-b-9
- 「需要外部查證」：Write 見 S1-a-4；GNU `stat` 見 S1-a 的處置；`--commands-only` 在拋棄式 HOME 實跑沒做 —— 讀了 `install-dd-pipeline.sh`（`create_scripts` 只在 `COMMANDS_ONLY` 為 false 時跑），AO 臂直接放舊版腳本模擬那個狀態
