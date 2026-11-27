# S1 審查 — C（文件與註解裡的宣稱）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S1（gate：dd.docfile 不收程式碼檔名、起點失效時的訊息、BLOCKED 申報）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s1-review-pack.txt`，1596 行，沒進 repo）的組成：
- 第 1 部分：`git diff 02b53d3`（起點）到工作目錄的整段 diff，HEAD = 8e63a18，含步驟 3 還沒 commit 的改動
- 第 2 部分：步驟 3（code-simplifier）自己改了什麼（`git diff HEAD`：`scripts/check-claude-md.sh` 一處註解，+3 −2 行；沒有未追蹤的新檔）
- 第 3 部分：`scripts/check-claude-md.sh`、`tests/test-gate.sh`、`docs/reviews/CLAUDE.md` 的整檔（帶行號）
- 第 4 部分：已跑過的驗證 V1–V8（macOS 與 ubuntu:24.04 的 `tests/test-gate.sh` 都是 rc=0、146 個 ✅；shellcheck；本機照 ci.yml 逐 step 跑 26 個 rc=0；四個變異各自紅在哪；拋棄式 repo 實跑 `dd.docfile=main.py`；rebase、換分支、reset 三種的 `git rev-list` 比對；同一段第二次先停）

其他被改到的文件（兩份 CLAUDE.md、CHANGELOG、README、架構文件、設計文件）沒有放整檔：步驟 3、4 依序跑，審查期間沒有人改工作目錄，派工 prompt 寫明那幾份直接讀工作目錄。

派工 prompt（逐字，審查者拿到的是一句「先讀這個檔再照做」加這個檔的路徑）：

> 你是 8 步開發迴圈步驟 4 的審查者 C。職責：找漏洞，每條附證據（檔案與那幾行的原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。
>
> Repo：/Volumes/T7/home/project/my_project/claude-dd（專案規則在根目錄與各層的 CLAUDE.md；本段相關的是 scripts/CLAUDE.md、tests/CLAUDE.md、docs/reviews/CLAUDE.md）。
>
> 審查範圍：`git diff 02b53d3` 到工作目錄（5 個 commit 加上步驟 3 還沒 commit 的一處註解改動）。這一段改的是 pre-commit gate `scripts/check-claude-md.sh` 的三處行為、它的情境測試 `tests/test-gate.sh`，以及說明這些行為的文件。
>
> 審查包：/private/tmp/claude-501/-Volumes-T7-home-project-my-project-claude-dd/f691d75a-d904-4c64-916c-d3b4d3714db8/scratchpad/s1-review-pack.txt
> （共 1596 行。用 Read 的 offset/limit 每次 300 行讀到最後一行：Read 一次讀太多會靜靜截斷、不報錯。）
> 組成：第 1 部分整段 diff；第 2 部分步驟 3（code-simplifier）自己改了什麼；第 3 部分 `scripts/check-claude-md.sh`、`tests/test-gate.sh`、`docs/reviews/CLAUDE.md` 的整檔（帶行號）；第 4 部分已經跑過的驗證（指令、預期、實際）。
> - 第 3 部分那三個檔一律讀審查包裡那一份。其他被改到的文件（scripts/CLAUDE.md、tests/CLAUDE.md、CHANGELOG.md、README.md、README.zh-TW.md、DD_PIPELINE_ARCHITECTURE.md、docs/designs/2026-11-15-audit-fixes-design.md）工作目錄就是被審的版本，審查期間沒有人會改，可以直接讀；沒被改到的檔照常讀。
> - 第 4 部分的驗證已確認，不要重跑整支測試、CI 或容器。要查證某一條具體懷疑時，可以在你自己的暫存目錄開拋棄式 git repo 跑 gate（`/Volumes/T7/home/project/my_project/claude-dd/scripts/check-claude-md.sh`）；不要改 repo 裡的任何檔、不要 commit、不要跑 `./install-dd-pipeline.sh`。
> - 只用手上的資料判斷；需要外部查證（上網、別的機器、別的 git 版本）的列出來交回。
>
> 這三處行為（事實，不是我的判斷）：
> 1. `git config --local dd.docfile <值>`：值命中 `\.(CODE_EXT)$` 時 gate 印「不可以是程式碼檔名」並 exit 1（檢查放在 `CODE_EXT` 定義之後）。
> 2. `--segment-base` 失敗時分四種訊息（起點檔不存在／起點不在目前分支歷史裡但有共同祖先／連共同祖先都沒有／起點檔內容不是 commit），四種都 exit 1、stdout 不印東西。
> 3. `--start-segment` 以「上一段沒有附 review 報告」擋下時，訊息從兩條路變三條路，多列 `docs/reviews/S<段落>-BLOCKED.md`（同一段第二次先停另建 `-BLOCKED-2.md`）；判定邏輯沒改。
>
> 你的方向：文件與註解裡的宣稱對不對得上程式碼與實測。逐句核對這次新增或改寫的敘述：`scripts/CLAUDE.md`（dd.docfile 那條、退化政策底下「分四種」那段、兩張變異表新增的列、「第 3 條」那個條目、已知繞過的 ④）、`tests/CLAUDE.md`、`docs/reviews/CLAUDE.md`、`CHANGELOG.md` 的 `## 未發布` 新增四條、兩份 README 與 `DD_PIPELINE_ARCHITECTURE.md` 改的那一句、gate 腳本與測試裡的註解、`docs/designs/2026-11-15-audit-fixes-design.md`。找：講錯的、講一半的、同一件事兩處講法不一致的、引用別處（檔名、情境編號、函式名、變異結果）而指不到或指錯的、數量寫死而已經不對的、該同步而沒同步的地方（根目錄 CLAUDE.md 有一節列出「CI 不驗、只能手動同步的區塊」與動到 gate 行為時要巡的地方）。
>
> 級別：Critical（會放行該擋的、擋下該放的、或資料／歷史被弄壞）／Important（行為或文件宣稱是錯的，照做會出錯）／Smells（不影響正確性）。
>
> 交回格式（直接用文字交回，不要寫報告檔）：
> 【發現】每條：編號｜級別｜一句話內容｜證據（檔案與原文，或指令與輸出）｜建議怎麼改
> 【Not reported】看過、判定不是問題的（每條一句理由）
> 【What I ran】跑過的指令與讀過的檔
> 【需要外部查證】

## 發現

審查者交回的原文（逐字）：

> Critical 0 / Important 2 / Smells 4。範圍：`git diff 02b53d3` 到工作目錄，看的是文件與註解裡的宣稱。
>
> 這次新增的敘述大多對得上程式碼和第 4 部分的實測，包括三張變異表的列、⑫④ 的理由、task-planner 的 BLOCKED 那條、兩份 README 與架構文件改的那一句。對不上的有下面兩條 Important。
>
> 【發現】
> 1｜Important｜`scripts/CLAUDE.md` 說 dd-loop 那段「照這幾句分情況」，但 dd-loop 在 HEAD 沒有照 gate 訊息分情況。｜證據：`scripts/CLAUDE.md:157` 原文「訊息改了字,`skills/dd-loop/SKILL.md`「段落起點與 `<起點>`」講取不到起點怎麼辦的那段要跟著對一次(它照這幾句分情況)。」；`skills/dd-loop/SKILL.md:22-23` 只寫「(exit 非 0 或輸出是空的 = 範圍沒算出來,不是範圍為空)」，沒有任何一句對應四種訊息。設計文件把「dd-loop 取不到起點的下一步」排在 S2。｜建議：括號改成講現況，例如「(目前只寫 exit 非 0 = 範圍沒算出來；照訊息分情況是 S2 的工作)」；或在 S2 落地之後再寫這句。
>
> 2｜Important｜amend 那一種沒有拿 `git rev-list` 比過，文件卻寫成四種都比過。｜證據：`scripts/CLAUDE.md:150` 原文「amend、rebase、換分支、`reset --hard` 到起點之前四種都在拋棄式 repo 比過 `git rev-list`,原範圍裡沒被涵蓋的都是 0 個」。審查包 V7 列的是 rebase、換分支、reset --hard、reset 後再 commit，amend 寫「由測試 ⑭ 跑」。⑭ 只有 `said "$FORK"`、`said "不要重跑"`、`not_said`、`stdout_empty`、`base_is`，沒有比 rev-list（`tests/test-gate.sh` ⑭ 那段）。結論本身成立：我在拋棄式 repo 補跑 amend，結果是 `old range: 1 fork range: 1 missing: 0`。｜建議：照 V7 改寫實際比過的四種，amend 另註「⑭ 沒比 rev-list，2026-11-15 另跑一次 0 個」；或把 amend 的比對加進 V7 的紀錄。
>
> S1｜Smell｜`-BLOCKED.md` 被 grep 當成選項時印的錯誤字串，只在 macOS 的 BSD grep 上是這樣。｜證據：`tests/CLAUDE.md` 原文「（印 `grep: Invalid argument`、回 2）」。`/usr/bin/grep -qF "-BLOCKED.md" f` 印 `grep: Invalid argument`、rc=2（BSD grep 2.6.0-FreeBSD）。GNU grep 印的字不一樣，我沒有實測。｜建議：寫成「（macOS 印 `grep: Invalid argument`；回 2）」。「said 永遠紅、not_said 永遠綠」這句不受影響，是對的。
>
> S2｜Smell｜「git 裡零痕跡」說過頭了，而且跟 `scripts/CLAUDE.md` 的說法不一致。｜證據：`scripts/check-claude-md.sh:42` 與 `tests/test-gate.sh` ⑬ 註解都寫「git 裡零痕跡」。但 `dd.docfile=main.py` 存在 `.git/config`，`git config --local --list` 看得到。`scripts/CLAUDE.md` 同一件事寫的是「`git status` 是乾淨的」，這個說法準。｜建議：兩處註解改成跟 `scripts/CLAUDE.md` 一樣的說法。
>
> S3｜Smell｜起點檔內容是非空的 tree sha 時，訊息歸到「找不到共同祖先」，不是文件寫的「內容不是 commit」。｜證據：`read_base` 收 `commit|tree`（腳本第 83-84 行）。實跑 `git rev-parse HEAD^{tree} > .git/dd-segment-base; check-claude-md.sh --segment-base` 印「❌ 沒有可用的段落起點：記下的起點 03fe285… 不在目前分支的歷史裡，也找不到共同祖先」，rc=1。`scripts/CLAUDE.md` 那張「分四種」表把「內容不是 commit」寫成一種。下一步的指示兩邊一樣，行為上不會做錯。｜建議：在「內容不是 commit」那一列註明「非空的 tree 落到上一種的訊息」；或在 `read_base` 只對 `$EMPTY_TREE` 收 tree。
>
> S4｜Smell｜⑬ 的 notes.sh 那則 expect 在 M1 變異下會因為別的原因照樣綠。｜證據：審查包 V5 的 M1 紅燈沒有「dd.docfile=notes.sh:--start-segment 拒絕執行」。原因是 M1 下 c1（a/main.py）已經 commit，起點是空樹，`owed_dirs` 把 a 算成欠帳，所以照樣擋。只有它的 `said` 有牙。`scripts/CLAUDE.md` 的 M1 那一列寫「兩則 expect 與三則 said」，數字是對的，但沒講 notes.sh 的 expect 是被欠帳頂住才綠的。｜建議：在 M1 那一列補一句「notes.sh 的 expect 被 c1 的欠帳頂住、照樣綠，靠它的 said」；或讓 notes.sh 那則在 c1 之前跑。
>
> 【Not reported】
> - 變異表 M1、M2a、M2b、M3 各列的紅燈清單，跟 V5 的輸出一則一則對得上。
> - `tests/CLAUDE.md` 說「⑫④ 能用 `--segment-base` 是因為 ③ 已記過起點」：`tests/test-gate.sh` ⑫③ 確實有「記段落起點」那則 `--start-segment`，成立。
> - 「`skills/task-planner/SKILL.md` 的 BLOCKED 那條也只交代補 CLAUDE.md」：`skills/task-planner/SKILL.md:140` 原文相符。
> - 「原本四種共用一句」：舊程式碼只有一句「沒記過，或起點已不在目前分支的歷史裡」，四種都走那一句，成立。
> - `owed_dirs` 在沒有共同祖先時印「段落開始前重記起點」，`--segment-base` 印「還沒做完時不要重跑」：兩句各有條件，不矛盾。`owed_dirs` 那行是這次之前就有的。
> - 兩份 README、`DD_PIPELINE_ARCHITECTURE.md` 都沒有寫到 review 擋下時的「兩條路」，沒有該同步而沒同步的地方。全庫 grep「兩條路」，剩下的命中是歷史紀錄或不相干的內容。
> - 設計文件 S1-3 驗證那一行還寫 `said "-BLOCKED.md"`：同一節下一行「實作時的三處調整」已經更正，設計文件是過程紀錄，不算錯。
> - ⑮ 第二次先停的情境，中間沒有重跑 `--start-segment` 就直接「回頭做 S1」。流程跟文件描述的不完全一樣，但被測的「改既有檔不算新增」照樣成立。
>
> 【What I ran】
> - Read：派工檔 prompt-c.txt；審查包第 1–900 行、第 1506–1596 行（腳本與測試的整檔內容跟第 1 部分的 diff 對照過）；`skills/dd-loop/SKILL.md:18-39`；`tests/test-gate.sh:455-536`（⑫）；`scripts/CLAUDE.md:145-158`
> - `git grep` 兩條路、三條繞過、三條路、two ways → 結果見上一節
> - `grep BLOCKED skills/task-planner/SKILL.md skills/dd-loop/SKILL.md` → task-planner 140 行，dd-loop 33 行
> - `grep segment-base` 掃 dd-loop、task-planner、全域模板、dd-init → 只有「exit 非 0 = 範圍沒算出來」，沒有分情況
> - `grep docs/reviews|SKIP.md` 掃兩份 README 與 `DD_PIPELINE_ARCHITECTURE.md` → 0 筆
> - `/usr/bin/grep -qF "-BLOCKED.md" f` → `grep: Invalid argument`，rc=2
> - 拋棄式 repo 跑 amend 後比 rev-list → `old 1 / fork 1 / missing 0`
> - 同一個 repo 把起點檔寫成 tree sha 後跑 `--segment-base` → 印「也找不到共同祖先」，rc=1
> - 暫存目錄：/private/tmp/claude-501/-Volumes-T7-home-project-my-project-claude-dd/f691d75a-d904-4c64-916c-d3b4d3714db8/scratchpad/revc
>
> 【需要外部查證】
> - GNU grep 遇到 `grep -qF "-BLOCKED.md"` 印什麼字、回幾：在 ubuntu:24.04 容器跑一次，決定 S1 那句要不要改。

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實，那個括號是我寫的，寫的時候 S2 還沒做。括號拿掉，只留「要跟著對一次」；S2-1 落地時再補「它照這幾句分情況」。
- **2（Important，採納）**：屬實，寫那句時 amend 沒有比過 `git rev-list`（審查包 V7 也寫明了），我把測試 ⑭ 當成比過。自己在拋棄式 repo 補跑一次（不引審查者的數字）：原範圍 2 個、從共同祖先 2 個、沒被涵蓋 0 個。那句現在成立，沒有改字。
- **S1（Smells，採納）**：外部查證自己做了：ubuntu:24.04 的 GNU grep 3.11 印 `grep: LOCKED.md: invalid context length argument`、rc=2。`tests/CLAUDE.md` 改成兩種都寫。
- **S2（Smells，採納）**：屬實。gate 的註解與 ⑬ 的註解改成「`git status` 是乾淨的（設定只留在 .git/config）」。S1-1 的 commit 訊息也寫了「零痕跡」，那個不改寫歷史。
- **S3（Smells，採納）**：與 A 的 S1 同一項，選的是改程式碼（處置見 `S1-a.md`），`scripts/CLAUDE.md` 的第四種同步改寫。
- **S4（Smells，採納）**：屬實。`notes.sh` 那則移到「改 a/main.py 的 commit」之前；重跑 M1：它自己變紅（三則 expect、三則 `said`，加 AGENTS.txt 的連鎖）。`scripts/CLAUDE.md` 的 M1 那一列與 `tests/CLAUDE.md` 同步。
- Not reported：都同意。其中「設計文件 S1-3 驗證那一行還寫 `said "-BLOCKED.md"`」留著（下一行已更正）；「⑮ 第二次先停中間沒有重跑 `--start-segment`」其實有（「繞過④」那則就是），測試的標籤「回頭做 S1」講得比實際寬，被測的行為不受影響，沒有改。
