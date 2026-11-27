# S1-b：審查者 B（全面；從整檔內容倒著讀回 diff，先看文件宣稱再看程式碼）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），四個在同一則訊息平行派出。
派工 prompt 只有一句（逐字，路徑去識別）：

> 你的派工指示全文在 <S>/s1-review/prompt-b.txt —— 先用 Read 讀完整份，照它做，照它的輸出格式交回。

那份檔的全文（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad、`<REPO>` 是 claude-dd 的 clone；下面「發現」節同樣只換了路徑）：

````text
你是 claude-dd repo（<REPO>）S1 段落的程式碼審查者，代號 S1-b。
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

你的方向：全面（所有檔、所有面向）；從 ③ 的整檔內容倒著讀回 diff，先看文件宣稱再看程式碼

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
每條：S1-b-<序號>｜級別｜一句話｜證據（diff 檔行號或 路徑:行，原文縮排貼出；或指令與輸出）｜照做的失敗情境
## Not reported
看過、判定不是問題的（一句話理由）
## 需要外部查證
## What I ran
````

## 發現

（逐字原文，只換了路徑）

````text
## Findings

S1-b-1｜Critical｜`.screenshots` 這條檢查擋不到它要擋的寫入。使用者答「不要」只會跳過 `mkdir -p`，而蓋章區塊照樣叫之後的 session 把截圖存進 `.screenshots/`。問句寫的後果也不對。｜證據：
- commands/dd-init.md:56（diff.txt 1153）`  - 建立、補充（Edit）、`>>`、`mkdir`、插入：改到的是連結目標；目標在專案外，就是改專案外的檔`
- commands/dd-init.md:137（diff.txt 1234）蓋章區塊 `     - 截圖一律存 `.screenshots/`（已 gitignore）；勿丟專案根目錄`
- 設計文件:104（diff.txt 1564）`.screenshots`（`mkdir -p`；之後截圖會存進去）`：寫進 repo 的文字點出了這條路，S1 的修法沒處理它。
- scratchpad 的 m/new3/B/report.txt，subagent 自己寫：「`mkdir -p` 遇到已存在的連結目標不會改動它，之後截圖會寫進專案外的目錄」。
- 同一臂的 new2、new4 照文件原話問成「mkdir -p .screenshots 改到的是連結目標」。

｜照做的失敗情境：clone 帶進 `.screenshots -> ~/某目錄`。/dd-init 問了，使用者答「不要」，以為擋下了。`mkdir -p` 碰到已存在的連結本來就什麼都不做，所以跳過它等於沒擋。Phase 1 已經蓋進步驟 5「截圖一律存 `.screenshots/`」，下一個 session 跑 playwright 時截圖就寫到專案外。這也符合 A14／U4 的判準：會進 repo 的文字描述了一條 S1 沒修的寫出路徑。

S1-b-2｜Important｜check.sh 在 B 臂對 `.screenshots` 的兩條斷言都沒有鑑別力。只問 `.gitignore`、完全沒問 `.screenshots` 也會 PASS。｜證據：
- check.sh:39（diff.txt 1762）`B) names=".gitignore .screenshots"`
- check.sh:43–45（diff.txt 1766–1768）用 `questions | grep -qF -- "$n"` 判。
- 但 `.gitignore` 的問句一定帶 `.screenshots/`：dd-init.md:181 要追加的就是這一行。實際回報 m/new1/B 的 `.gitignore` 問句寫的是「要不要照寫 `echo '.screenshots/' >>`」，同時也滿足了 `/outside` 那條斷言。
- `mkdir -p` 對已存在的連結沒有作用，所以專案外的 sha 與清單斷言也抓不到 `.screenshots`。

｜照做的失敗情境：步驟 5 重跑 B（設計文件:147）。如果這輪修改讓 `.screenshots` 的問句不見了，check.sh 照樣 PASS。這次四份存檔回報確實都分開問了，所以宣稱碰巧成立，但判定方式證明不了它，而 results.txt:11 寫「判定只看 check.sh」。

S1-b-3｜Important｜答「要」之後改的是連結目標（例如 `AGENTS.md`），但 Phase 5 只 add／commit `CLAUDE.md`、`.gitignore`。改動靜靜留在 commit 外，Phase 6 照樣印成功。｜證據：
- dd-init.md:69（diff.txt 1166）`使用者答「要」之後，就對連結目標的路徑用 Write、Edit 照原本的步驟寫`
- dd-init.md:296–305（diff.txt 1393–1402）只有 `git add CLAUDE.md`、`-- CLAUDE.md .gitignore`。
- 提醒 commit 連結目標的句子只在 Phase 3 第 5 步（dd-init.md:280–281），Phase 1／5 沒有對應的一句。
- Y 臂走不到 Phase 5：prompt.txt:9（diff.txt 1840）寫「做完指定的 Phase 就停，不要 commit」。

｜照做的失敗情境：`CLAUDE.md -> AGENTS.md` 的專案答「要」，蓋章寫進 `AGENTS.md`（tracked 檔被改）。Phase 5 的 `git add CLAUDE.md` 沒有東西可 stage，`git diff --cached --quiet -- CLAUDE.md .gitignore` 為真，所以不 commit。Phase 6 印「✅ 初始化完成 … CLAUDE.md — 8 步開發迴圈」，蓋章留在未 commit 的修改裡。CHANGELOG 把這條路當成賣點寫（「例如 `CLAUDE.md` → `AGENTS.md` 的專案」）。

S1-b-4｜Important｜父目錄檢查的指令是裸的 `cd`。/dd-init 在主對話跑時，Bash 的 cwd 會留在 `.husky`，之後用相對路徑的步驟會錯。沙盒臂的 subagent 每次 Bash 都重設 cwd，結構上量不到這個問題。｜證據：
- dd-init.md:42（diff.txt 1139）``cd "$(dirname <路徑>)" && pwd -P` 的輸出等於專案根目錄…``
- 唯一 dirname 不是 `.` 的檢查路徑是 husky v9 的 `.husky/pre-commit`（dd-init.md:50）。
- Bash 工具的規則：「`cd` carries to the next call only in the main session, if the command succeeds and ends inside the working directories」。subagent 則是「cwd reset between bash calls」，所以 H3、H3K 綠燈證明不了主對話的行為。

｜照做的失敗情境：husky v9 專案。照字面單獨跑 `cd .husky && pwd -P` 後，cwd 停在 `.husky/`。第 4 步 `test -x .husky/pre-commit || chmod +x .husky/pre-commit` 找不到檔。Phase 5 的 `git add CLAUDE.md` 回 `pathspec 'CLAUDE.md' did not match`、exit 128，正是 dd-init.md:310–312 警告「連 CLAUDE.md 也不會被 stage」的那種壞法。寫成 `( cd … && pwd -P )` 這類子 shell 就不會留下 cwd。

S1-b-5｜Important｜第 2 步「不在 repo 裡」現在擋著 E、F、G、G2、H1、H2 這幾條分支，卻只寫「在 toplevel 底下」。新小節特地寫明的「專案根目錄 + `/`」邊界，這裡沒有。｜證據：
- dd-init.md:205（diff.txt 1302）`「不在 repo 裡」看的是上面那行指令**印出來的路徑**在不在 `git rev-parse --show-toplevel` 底下`
- 對照 dd-init.md:42 `等於專案根目錄、或以「專案根目錄 + `/`」開頭`
- 舊文字（dd8b5a9:163）就是這個寫法，但 S1 改寫了這條，並把它變成主要的防線。

｜照做的失敗情境：toplevel 是 `/home/u/app`，`.git/hooks/pre-commit -> /home/u/app-shared/pre-commit`。印出來的路徑以字串 `/home/u/app` 開頭，照字串前綴比會判成「在 repo 裡」，於是不問就 Edit 插入、`chmod +x`，改到專案外的 hook。

S1-b-6｜Important｜新小節與 CHANGELOG 把「解析 symlink」歸給 `--git-path`。照 git 原始碼，解析靠的是 `--path-format=absolute`（2.31 起）。第 2 步對這個旗標的說明又只講「子目錄也回絕對路徑」，沒講它擋著 symlink 檢查。｜證據：
- dd-init.md:50（diff.txt 1147）`` `git rev-parse --git-path` 印的是解析過 symlink 的路徑 ``
- CHANGELOG 未發布（diff.txt 2900）`` `git rev-parse --git-path` 會解析 symlink ``
- dd-init.md:198（diff.txt 1295）`--path-format=absolute --git-path hooks/pre-commit`（git 2.31 起；在子目錄跑也回絕對路徑…`
- 推論自 builtin/rev-parse.c 的 `print_path()`：只有 FORMAT_CANONICAL 走 `strbuf_realpath_forgiving`，預設格式不解析。另外 rev-parse 遇到不認得的 `--` 旗標會原樣印出來。
- 實測只有 2.42.0、2.39.5（results.txt:62–64）。

｜照做的失敗情境：
- 有人照新小節那句跑 `git rev-parse --git-path hooks/pre-commit`，或日後把「只為了絕對路徑」的旗標刪掉：拿到的是相對、沒解析的 `.git/hooks/pre-commit`，判成在 repo 裡，於是寫穿。
- git 2.25／2.30 這類舊版（推論）：印出 `--path-format=absolute` 加上沒解析的路徑，exit 0。文件沒寫舊版要怎麼辦，S1 對 Phase 3 的保護就靜靜失效。

S1-b-7｜Important｜會進 repo 的設計文件引用 F3、F4、F5c、F6，這些項目只定義在 scratchpad 的 plan-facts-r1.md，repo 裡找不到。｜證據：
- `grep -nE '\bF[0-9]+[a-z]?\b'` 設計文件，命中 :35（F5c）、:147（`見 F6`）、:155（`清單見 F3`）、:157（`見 F4`）。全文沒有任何 F 項的定義。
- scratchpad 的 plan-facts-r1.md:15/16/19/23 才有 `- F3：…`、`- F4：…`、`- F5c：…`、`- F6：…`。

｜照做的失敗情境：S2 換 session 接手時照 S2-1「上游 … 底下所有檔原樣複製（清單見 F3）」去找清單，找不到。S1 步驟 3–8 那句「部署版 … 與 repo HEAD 逐字相同，見 F6」的依據也指到空處。這正是全域 §3.10「要寫就先去那裡 grep」那類死指標。

S1-b-8｜Important｜Y 是唯一驗「答要」這條路的臂，卻沒列進步驟 5 的重跑清單，也沒列進進度表的驗收。｜證據：
- 設計文件:147（diff.txt 1607）`步驟 5 重跑 … 沙盒臂 A、B、C、C2、D、E、F、G、G2、I、對照臂 K1–K3 與 docker 臂 H1–H3`：沒有 Y。
- :54 的驗收欄也沒有 Y。
- Y 是定稿才加的（:143、results.txt:59）。

｜照做的失敗情境：步驟 4 若照 S1-b-3 改了「答要」那段文字，步驟 5 照清單重跑不會碰到 Y，這條路退步了也看不出來。

Smell S1-b-9｜量測目錄的 CLAUDE.md 把 check.sh 的行為縮短時掉了條件。｜證據：
- docs/measurements/2026-11-14-dd-init-symlink/CLAUDE.md:13 寫「H?K 會在容器裡實跑 `npm install` 與一次 commit」。
- check.sh:69：H1K 跑的是 `pre-commit validate-config && pre-commit install`；check.sh:74 的 `npm install` 只給 H2K、H3K。

｜照做的失敗情境：維護的人照 CLAUDE.md 理解 H1K，會預期它跑 npm install。

Smell S1-b-10｜results.txt:10 寫「問句一律答「不要」，A、D 的「是否升級」答「同意」」，但 Y 答「要」。｜證據：results.txt:31、:59；mkprompt.sh:18 `Y) ANSWERS='「寫檔前…」那節的問句答「要」。'`｜照做的失敗情境：讀「做法」節的人會以為所有臂都答「不要」。

## Not reported

- `--apply` 的輸出路徑只查它本身、不查父目錄：/dd-init 唯一的呼叫點是專案根目錄的固定檔名 `CLAUDE.md.dd-upgrade`（dd-init.md:97），父目錄就是 cwd，走不到這條。
- 腳本本身：exit 6 放在 `[ -f TARGET ]`、`[ -f TEMPLATE ]` 之後、建 WORK 之前。寫法 `{ [ -e ] || [ -L ]; }` 在 bash 3.2 與 `set -e` 下都沒問題。T1–T4 都包在 `run()`（`set +e … set -e`）裡。T4 對未修版拿到 exit 2，不等於 6，算有牙。
- tests/CLAUDE.md 的「空殼 → 40 ❌」等於原本 36 加四則 exit 碼，「拿掉檢查 → 七則」跟 ④ 的七行對得上。
- results.txt 的兩個 sha：b6e3666 是 `6afa7ca1…`，bc22fed 與工作目錄都是 `de1df4bc…`，已核對。D 臂「rev 9」也核過：v1.6.4 的標記是 `dd-loop-rev: 9`。
- 蓋章區塊沒動到，不必跳 rev：diff 的 hunk 都在 ```markdown 區塊外（dd-init.md:115–153），CI step 也已跑過。
- `commands/dd-init.md` 沒有 `$<數字>`（grep rc=1）。量測目錄的去識別掃描（`/Users/`、`-Users-`、`/private/tmp`、`-private-tmp-`）回 0 筆。
- step 3 的 simplifier 改動：check.sh（`!= control`、`-z`）、mkprompt.sh（case 合併）、setup.sh（`project_intro` + `echo`）讀過，和舊版等價。
- README、UPGRADING 提到掛載點、`.screenshots`、升級腳本的句子在新行為下仍然成立，不用同批改。
- worktree、submodule、`--separate-git-dir` 會被第 2 步判成在 repo 外：舊文字就這樣，而且只會多問，不會寫穿。
- hard link、`CLAUDE.md.bak-<秒級時間戳>` 被預先放好：clone 帶不進 hard link，時間戳也猜不到，在 A3 的威脅模型外。
- A3 寫明不處理 TOCTOU：那是通用的聲明，不是一條具體的寫出路徑。
- husky v9 在第 2 步與新小節可能各問一次：只是多問。check.sh 的「無」開頭判斷，以及問句寫在標題同一行會被略過：大多是寧可判紅，對照臂才會誤綠，算小事。

## 需要外部查證

- 拋棄式 repo 裡 `.git/hooks/pre-commit` 做成 symlink，分別跑 `git rev-parse --git-path hooks/pre-commit`（不帶旗標）與 `git rev-parse --path-format=absolute --git-path hooks/pre-commit`：可以確認 S1-b-6 的前半，也就是只有帶旗標才解析。
- 用 git ≤2.30 的容器跑同一條帶旗標的指令，看是不是印出旗標字串加上沒解析的相對路徑、exit 0：可以確認 S1-b-6 的後半。
- 在主對話（不是 subagent）對 husky v9 fixture 跑部署版 `/dd-init` Phase 3 加 Phase 5，看 `cd .husky && pwd -P` 之後 cwd 是不是留在 `.husky`、Phase 5 的 `git add CLAUDE.md` 是不是 exit 128：可以確認 S1-b-4。
- Y 型 fixture 答「要」之後接著跑 Phase 5，看 `git status` 是不是留著改過的 `AGENTS.md`、Phase 5 是不是沒 commit：可以確認 S1-b-3。

## What I ran

- Read diff.txt 第 1–2942 行，每次 150 行 → 全部讀完
- `grep -nE '\bF[0-9]+[a-z]?\b'` 設計文件、`git grep` 找 F3/F4/F5c/F6 → 只有 :35、:147、:155、:157 引用，repo 裡沒有定義
- `git show b6e3666:commands/dd-init.md | shasum -a 256`、`git show bc22fed:… | shasum -a 256`、`shasum -a 256 commands/dd-init.md` → `6afa7ca1…`、`de1df4bc…`、`de1df4bc…`
- `git show v1.6.4:commands/dd-init.md | grep -n dd-loop-rev` → rev 9
- `grep -n '\$[0-9]' commands/dd-init.md` → 無輸出，rc=1
- `git grep -n -- '--apply'`、`git grep -nE 'dd-upgrade|2–5|exit 5'` → 沒有別的呼叫端會對已存在的輸出路徑跑 `--apply`
- `grep -nE 'hooksPath|掛載點|symlink|…'` README.md、README.zh-TW.md、UPGRADING.md → 沒有變過期的句子
- `git show dd8b5a9:commands/dd-init.md | grep -n '不在 repo 裡'` → :163，舊寫法是「（toplevel 之外）」
- `grep -rnE '/Users/|-Users-|/private/tmp|-private-tmp-|danlio'` 量測目錄 → 0 筆
- `grep -nE … F(3|4|5c|6)` scratchpad 的 plan-facts-r*.md → plan-facts-r1.md:15、16、19、23
- 讀 scratchpad 的 m/new{1..4}/B/report.txt 問句段落與 check.txt → 四次都 PASS；`.gitignore` 問句含 `.screenshots/`；new3 自己指出「mkdir -p 不改連結目標、之後截圖寫到專案外」
- `sed -n` 印 dd-init.md:42、50、56、69、137、181、198、205，量測 CLAUDE.md:13，check.sh:69、74，results.txt:10 → 引用的原文都對得上
````

## 處置

- S1-b-1（Critical）部分採納：問句的後果改正 ——「`mkdir -p` 對已經存在的連結不做事（懸空的會失敗），後果在之後：蓋章區塊要之後的 session 把截圖一律存進 `.screenshots/`，截圖就存進連結目標」；
  答「不要」時一併告知「擋不住之後的截圖，要擋就自己把這個連結換成專案裡的目錄、再重跑 `/dd-init`（不要替他刪）」。
  沒改的那一半：蓋章區塊的「截圖一律存 `.screenshots/`」沒加「截圖前先確認它不是 symlink」—— 那是蓋章區塊（改了要跳 dd-loop-rev，所有專案升級時都會吃到），
  要不要加是設計取捨，列成需使用者決定（見 `S1-judge.md`）；2026-11-14 使用者選 A（只在 `/dd-init` 當下告知），蓋章區塊不改、不跳 dd-loop-rev
- S1-b-2（Important）採納：同 S1-a-1
- S1-b-3（Important）採納：「答「要」」那條寫明 Phase 5 要 commit 的是連結目標（目標在專案裡就把指令區塊裡的路徑換成目標；在專案外就拿掉並告知），
  用升級腳本升級的例外另寫（第 8 步的 `mv` 之後 `CLAUDE.md` 已經是一般檔）；Phase 5 開頭指回那一節。
  加臂 Y5（同 Y、做到 Phase 5）：bc22fed 的文字下紅（`git add CLAUDE.md` 等於沒加，留下 ` M AGENTS.md`），修正後的文字下 3/3 綠，commit 的是 `AGENTS.md`
- S1-b-4（Important）採納：同 S1-a-5
- S1-b-5（Important）採納：同 S1-a-7
- S1-b-6（Important）採納：同 S1-a-3。後半（git ≤2.30 印旗標字串加沒解析的路徑、exit 0）已實測成立
- S1-b-7（Important）採納：同 S1-a-8
- S1-b-8（Important）採納：設計文件步驟 5 的重跑清單與進度表驗收加了答「要」的臂 Y、Y5、YD（連同 AO、O、OI）。Y 在修正後的文字下 1 次綠，補一句之後再 1 次綠
- S1-b-9（Smell）採納：量測目錄 CLAUDE.md 與 `check.sh` 檔頭改寫 H?K 那句（H2K、H3K 先 `npm install`；H1K 先把回報的 YAML 加進設定、`pre-commit install`）
- S1-b-10（Smell）採納：`results.txt`「做法」改成 Y、Y5、YD 答「要」，A、AO、D 的「是否升級」答「同意」，其他答「不要」
- 「需要外部查證」：前兩條見 S1-a-3；主對話 cwd 沒跑，見 S1-a-5；Y 接 Phase 5 用 Y5 臂實跑，見 S1-b-3
