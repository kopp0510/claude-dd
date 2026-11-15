# 評分後的缺陷修補

使用者要我檢查這個 repo 的流程與設定並逐項評分；交出評分後他選了「修缺陷」那一批。這份文件有四段（S1 gate、S2 流程文字、S3 安裝腳本 `--check`、S4 vendored 內容與授權）：沒有 task 工具，照全域 §4.4 用進度表記進度。

## 來源

- 使用者的話（逐字，依序，2026-11-15）：「幫我檢查claude-dd 這整個repo 流程 和設定, 再請給我一份每個的分數,低於60分要告訴我如何改善調整」、「所以現在該怎做?」
- 我用選單問「claude-dd 評分後要我動手做哪幾批？」（可複選：A 修缺陷／B review 與 workflow-review 退場／C 出兩份 CLAUDE.md 的逐條清單／D error-capture 少誤報）。**使用者只選了「A 修缺陷（建議）」**（使用者決定）。選項 A 的說明：「7 項：gate 的 dd.docfile 繞過、amend 掉起點後範圍變 0、BLOCKED 後開不了下一段、--check 看不出部署版過期、/dd-init Phase 4 兩處措辭、self-improving-agent 的死指標與評分表打架、agents 兩個官方備份補授權檔。照 8 步迴圈做，約 2–3 小時。」
- 7 項的佐證都是評分那一輪在拋棄式 repo 實跑或讀檔得到的，整理在「開工前查到的事實」

## 假設

- A1 範圍只有使用者選的 A（7 項）。審查 agent 回報但我沒重跑的其他發現（cherry-pick／merge 不經 hook、`HUSKY=0`、`CODE_EXT` 缺 `mts`、gate-guard 斷詞漏判、self-improving-agent 的其他小矛盾、門檻 3+ 對 2+、`clawhub publish` 那兩處）不做
- A2 不動 `commands/dd-init.md` 的蓋章區塊（Phase 4 在區塊外），不跳 `dd-loop-rev`；全域模板 §3.9 的 `<起點>` 那句在蓋章區塊裡有一份逐字副本，所以模板那句也不改，新做法只寫進 `skills/dd-loop/SKILL.md`。不發版、不 push、不跑 `./install-dd-pipeline.sh`（部署由使用者自己做）
- A3 CHANGELOG 條目一律寫進 `## 未發布`，用行首錨
- A4 D1（使用者決定，2026-11-15）：`dd.docfile` **只拒絕副檔名在 `CODE_EXT` 裡的值**。擋不到的：`Makefile`、`Dockerfile` 這類沒副檔名的檔，以及清單沒列的副檔名（`mts`、`zsh`、`lua`…）—— 使用者選的時候選項說明已寫出這個缺口
- A5 D2（使用者決定，2026-11-15）：段落標 `BLOCKED` 去做別段、專案有 `docs/reviews/` 時，**建申報檔 `docs/reviews/S<段落>-BLOCKED.md`**。gate 判定邏輯不改（檔名本來就命中 `S[0-9][^/]*\.md`），只在擋下訊息多列這條路。取捨：gate 只看檔名（跟 `SKIP.md` 同類），拿它當成做完的段落的報告 gate 分不出來，記進 `scripts/CLAUDE.md`。（S1-3 實作時更正：原本寫「回頭做完那段有沒有補跑步驟 4 沒有關卡會查」不對 —— 回頭做時要重跑 `--start-segment`，之後開下一段時 gate 照樣查那個範圍有沒有新增報告；查不到的是先停之前已經 commit 的那一部分，那靠進度表 commits 欄的起點）
- A6 gate 訊息改了，照 `scripts/CLAUDE.md`「此層慣例」同步檢視 `skills/dd-loop/SKILL.md`、`skills/task-planner/SKILL.md` 規則區塊；照根目錄 CLAUDE.md「CI 不驗、只能手動同步的區塊」巡兩份 README 的「CLAUDE.md 維護規則」、gate 對策段、`DD_PIPELINE_ARCHITECTURE.md` 的 gate 段
- A7 `skills/task-planner/SKILL.md` 的規則區塊改了之後，已經照抄進各專案設計文件的舊版不會跟著變（根目錄 CLAUDE.md「核心工作法」已寫明）；CHANGELOG 條目寫明這點，不去改其他專案。本檔進度表下方照抄的那份，`BLOCKED` 那一條在 S2 步驟 4 之後已經換成新句（審查者指出本 repo 自己也還有 S3、S4 要做），其餘各條沒有變
- A8 `--segment-base` 維持硬失敗、stdout 維持空的（`scripts/CLAUDE.md` 的退化政策表不變），只改 stderr 的訊息
- A9 S2、S4 改到 SKILL.md／commands 內文但不動 description 與觸發條件，只做根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步的乾跑，不做第 5 步的 `claude -p` 觸發測試
- A10 S4 的授權檔只寫查得到的事實：本機官方 marketplace 副本的比對結果與該目錄的 LICENSE；開工前提另外查 GitHub 上游，查不到就寫「上游線上版沒查到」，不編。`code-reviewer.md` 是改過的衍生檔，授權檔裡寫明它改過
- A11 S4-2 是行為改變：評分以 `reference/promotion-rules.md` 為準，Scope「整個專案」從 3 分變 2 分，總分可能跌破 6 的門檻
- A12 計畫審查（`plan-review`）1 輪通過：4 個審查者、0 條重大、12 條小事都已改進這份計畫、7 條駁回。紀錄在本檔最後一節
- A13 測試清單由使用者在 2026-11-15 選定「照這份清單加」

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | gate：dd.docfile 不收程式碼檔名、起點失效時的訊息、BLOCKED 申報 | DONE | — | `/bin/bash tests/test-gate.sh`（macOS 3.2）與 ubuntu:24.04 容器都 rc=0、新情境都是 ✅；變異（拿掉 dd.docfile 新檢查／起點失效訊息改回舊句／拿掉 BLOCKED 那一行訊息）各自只讓對應的新情境變紅；拋棄式 repo 實跑 `dd.docfile=main.py` 時 gate exit 1；本機照 ci.yml 逐 step 全過 | 9d77062..5927484 |
| S2 | 流程文字：dd-loop 取不到起點的下一步、task-planner 的 BLOCKED、dd-init Phase 4 | DONE | S1 | 沙盒乾跑臂用指令核對：amend 臂交回的起點等於 gate 印的共同祖先 sha、起點檔沒被重寫；BLOCKED 臂的拋棄式 repo `git log --diff-filter=A --name-only -- docs/reviews` 有 `S1-BLOCKED.md`、之後 `--start-segment` exit 0、進度表 S1 的起點沒被改；Phase 4 三臂（值 true／false／沒有鍵）結論依序是已啟用／未啟用／未啟用；本機照 ci.yml 逐 step 全過（蓋章區塊沒動，rev 檢查照綠） | f4e15a0..0227f5b |
| S3 | 安裝腳本：`--check` 看得出部署版與 repo 不同 | TODO | — | `/bin/bash tests/test-install.sh` 與 ubuntu:24.04 容器都 rc=0、T11 是 ✅；變異（把比對拿掉）→ T11 紅；真的跑 `./install-dd-pipeline.sh --check`：`plan-review` 那行印出「與 repo 不同」（本機部署版正好是舊的）、其他 skill 照舊、結束碼 0；本機照 ci.yml 逐 step 全過 | |
| S4 | vendored 內容：self-improving-agent 死指標與評分表、agents 授權檔 | TODO | — | `grep -rn 'codex-install\|clawhub install' skills/self-improving-agent` 0 筆；`agents/memory-analyst.md` 不再有自己的分數定義、只指到 `reference/promotion-rules.md`；乾跑臂拿範例記憶照 memory-analyst.md 評分，Scope 是 2、三個分數等於照 promotion-rules.md 那張表算的；`agents/LICENSE.txt` 存在，兩份 README 與架構文件的授權段都列到它；本機照 ci.yml 逐 step 全過 | |

- 狀態只有 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`；同一時間最多一段 `IN_PROGRESS`
- 下一段：由上往下第一個 `TODO`，而且它依賴的段落都已 `DONE`。有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段
- 開工：`~/.claude/scripts/check-claude-md.sh --start-segment` 記起點；這段標 `IN_PROGRESS`，commits 欄先填 `<起點>..`（短 SHA；起點是空樹時填它印出的完整 SHA；回頭做 `BLOCKED` 過的段落時，欄裡原本的起點保留不改）；該段有「開工前提」就先查完，結果寫進「段落與小任務」該段底下。這些改動跟第一個小任務的 commit 一起送
- 每個小任務：照「段落與小任務」列的做，實作、驗證、commit，commit 訊息第一行結尾帶編號（例如 `（S2-1）`）。可用 `SKIP_DOC_CHECK=1` 先跳過 CLAUDE.md 檢查，gate 會記帳。測試照文件裡的測試清單加；想加清單以外的測試，先問使用者
- 小任務 commit 了不等於段落完成。小任務全部 commit 完，而且 SKIP 欠下的 CLAUDE.md 都補上了，才對整段跑步驟 3–8，範圍從表上這段的起點算。最後一個小任務用正常 commit；補 SKIP 改過的目錄的 CLAUDE.md 時，用 `git diff <起點> -- <目錄>` 看整段改了什麼，不要只看這次 staged 的（gate 只查 CLAUDE.md 有沒有一起送，不查寫了什麼）。步驟 6、7、8 的 commit 訊息第一行結尾帶段落編號（例如 `（S2）`）
- 標 `DONE`：步驟 3–8 全部跑完才標；commits 欄補上終點（標 `DONE` 之前最後一個 commit 的短 SHA，所以標 `DONE` 的 commit 自己不在範圍內），跟步驟 7、8 的 commit 一起送，7、8 都沒改檔就單獨開一個 docs commit。標到表上每段都 `DONE` 的那個 commit，刪掉根目錄 CLAUDE.md 的指路那段
- 接手：`IN_PROGRESS` 那段就是目前這段。拿「段落與小任務」的清單對 `git log --oneline <表上這段的起點>..HEAD` 裡結尾帶 `（S2-` 的 commit（不加範圍會對到別份文件的同編號 commit）。
  **前綴是「這一段自己的 ID 加一個 `-`」**，不是固定字串：插隊進來的 `S2.5` 要找的是 `（S2.5-`，
  拿 `（S2-` 去比對不到它，拿 `（S2` 又會把 S2.5 的 commit 誤算成 S2 的，還沒 commit 的小任務先做完。小任務都做完了，再看同一範圍裡有沒有帶 `（S2）` 的 commit：有，代表步驟 6 之後的步驟做到一半；沒有就從步驟 3 開始
- `BLOCKED` 用在這段要先停：外部卡住（等使用者決定、環境壞了），或使用者要先做別的事（別段、臨時修 bug）。狀態格寫 `BLOCKED` 和原因，外部卡住時停下來問使用者。先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md（不然 `--start-segment` 會拒絕）；專案有 `docs/reviews/` 目錄時，先停還要 commit 一份申報檔 `S<段落>-BLOCKED.md`（跟進度表標 `BLOCKED` 的改動、補的 CLAUDE.md 放同一個 commit）—— 這段還沒有 review 報告，少了它 `--start-segment` 一樣會拒絕。申報檔寫明停在哪個小任務、為什麼停、先停之前已經 commit 的範圍；放的位置照專案 `docs/reviews/CLAUDE.md` 的規定，專案有好幾張進度表時放這張表自己的子目錄、不要放進別張表的，寫之前先 `ls`（要的是新增的檔，蓋掉或改既有的不算）；同一段第二次先停另建 `S<段落>-BLOCKED-2.md`。回頭做這段時，範圍一樣從表上這段的起點算，步驟 4 照跑、報告照落地（`-BLOCKED.md` 只是申報，不算報告）。依賴還沒完成的段落維持 `TODO`
- 做到一半冒出新工作：先問使用者，同意才加一列 `TODO` 排進該在的位置；ID 不重編，插在中間用 `S2.5`。
  **同一批要在「段落與小任務」補上這一段的小任務**（名稱、要動的檔案、驗證方式、commit 訊息）——
  只加表上那一列的話，接手的 session 照上面「接手」那條去對 commit，清單本來就是空的，
  它會判定「小任務都做完了」而直接跳到步驟 3，整段程式碼從頭到尾沒人寫。
  沒有小任務條目的段落不得標 `IN_PROGRESS`
- 每列一行，細節寫進 commit 訊息

## 段落與小任務

### 開工前查到的事實（2026-11-15，HEAD 0a46303，本機 macOS）

- `scripts/check-claude-md.sh`：`dd.docfile` 的驗證只有字元集（`*[!A-Za-z0-9._-]*|.|..|-*`），`CODE_EXT` 定義在它之後。拋棄式 repo 實跑：預設時 `a/main.py` 沒有 CLAUDE.md 的 commit 被擋；SKIP commit 之後 `--start-segment` rc=1（欠帳）；`git config --local dd.docfile main.py` 之後同一個 `--start-segment` rc=0，之後 `b/` 新增程式碼、沒有 CLAUDE.md 的正常 commit rc=0，`git status --short` 0 行
- 同一支：`--segment-base` 失敗時只有一句「沒有可用的段落起點（沒記過，或起點已不在目前分支的歷史裡）：段落開始前先跑 … --start-segment」。拋棄式 repo 實跑：記起點 → `git commit --amend` 掉起點那個 commit → 再 commit 一筆 → `--segment-base` rc=1、stdout 空；照訊息跑 `--start-segment` 之後 `git diff <起點> --stat` 0 行
- 同一支：`reviews_missing` 只看 `起點..HEAD` 有沒有新增 `docs/reviews/` 底下 `S[0-9][^/]*\.md` 的檔。拋棄式 repo 實跑：有 `docs/reviews/`，S1 記起點、commit 一筆程式碼（CLAUDE.md 同批），再跑 `--start-segment` → rc=1「上一段沒有附 review 報告」
- `install-dd-pipeline.sh`：`check_builtin_skills` 只用 `dir_exists`、`check_builtin_agents` 只用 `file_exists`；`install_builtin_skills` 用 `diff -rq` 判斷要不要重寫。本機 `diff -rq skills ~/.claude/skills` 只有 `plan-review/SKILL.md` 不同，`--check` 對它印「已安裝」、rc=0
- `commands/dd-init.md` Phase 4：「`enabledPlugins` 是否含 `claude-md-management@claude-plugins-official`」「提示執行 `./install-dd-pipeline.sh --force`（腳本會裝）」。安裝腳本只登記已在磁碟上的 plugin、不下載（`README.md` 前置需求；`install_plugins` 有 `.enabledPlugins[$key] = true`）
- `skills/self-improving-agent/SKILL.md` 與 `README.md` 都有 `./scripts/codex-install.sh`，該目錄沒有 `scripts/`。`agents/memory-analyst.md` 的 Scope 是「Project-wide (3) vs. one-file (1) vs. one-time (0)」，`reference/promotion-rules.md` 的表是 0 單檔／1 單目錄／2 整個專案／3 所有專案，兩邊門檻都是 ≥ 6
- `agents/code-simplifier.md` 與本機 `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/code-simplifier/agents/code-simplifier.md` `cmp` 相同，該 plugin 目錄有 `LICENSE`（Apache License）。`agents/code-reviewer.md` 的非空白行與本機官方 `feature-dev`、`pr-review-toolkit` 的同名檔各有 8、11 行相同。`find agents -iname '*licen*'` 0 筆
- 基準：本機照 ci.yml 逐 step 跑 26 個全部 rc=0；ubuntu:24.04 容器（bash 5.2.21、jq 1.7）三支測試與兩支 hook 測試 rc=0；`tests/test-gate.sh` 120 個 ✅

### S1 gate（動的是擋 commit 的規則，單獨一段）

開工前提：跑一次 `/bin/bash tests/test-gate.sh`，記下 ✅ 數與 rc。→ 2026-11-15 HEAD 9d77062：rc=0、120 個 ✅、0 個 ❌。

- S1-1 拒絕把 `dd.docfile` 設成程式碼檔名
  - 檔案：`scripts/check-claude-md.sh`（`CODE_EXT` 定義之後加檢查：`DOC_FILE` 命中 `\.(CODE_EXT)$` 就印錯誤並 exit 1）、`tests/test-gate.sh`（⑫ 之後加 ⑬）、`scripts/CLAUDE.md`（「記憶檔名可設」補一句、變異表一列、擋不到的那幾類）、`tests/CLAUDE.md`
  - 驗證（測試）：先寫 ⑬、確認現況紅：`dd.docfile=main.py` block 且 `said "不可以是程式碼檔名"`；`dd.docfile=notes.sh` block；`dd.docfile=AGENTS.txt` 正常（對照）
  - commit：`fix: gate 不收程式碼檔名當 dd.docfile（S1-1）`
- S1-2 起點失效時 `--segment-base` 的訊息分開講
  - 檔案：`scripts/check-claude-md.sh`、`tests/test-gate.sh`、`scripts/CLAUDE.md`、`tests/CLAUDE.md`
  - 內容：沒記過起點 → 照舊叫你跑 `--start-segment`。起點檔在、但不在目前分支的歷史裡（換過分支或改寫過歷史）→ 印出共同祖先，說明範圍可以從它算、會多含被改寫的那個 commit，並寫明不要重跑 `--start-segment`（起點會移到現在，這一段已經 commit 的就不在範圍內）。連共同祖先都沒有 → 「改用進度表 commits 欄的起點；沒有進度表就問使用者」。三種都維持 exit 1、stdout 空（實作時多分出第四種：起點檔在、內容不是 commit —— 原本併在「沒記過」那句裡一樣叫人重記；下一步同「連共同祖先都沒有」，測試多加一則）
  - 驗證（測試）：先寫、確認現況紅：amend 掉起點後 block、stdout 空、`said` 共同祖先 sha、輸出不含「段落開始前先跑」；孤兒分支時 `said "進度表"`；沒記過起點時 `said "段落開始前先跑"`（對照，現況綠）
  - commit：`fix: 起點失效時 --segment-base 講出共同祖先、不再叫人重記（S1-2）`
- S1-3 「上一段沒有附 review 報告」的擋下訊息加第 3 條路（A5）
  - 檔案：`scripts/check-claude-md.sh`、`tests/test-gate.sh`、`scripts/CLAUDE.md`（「擋下時印的兩條路」那條、已知繞過補一條）、`tests/CLAUDE.md`、`docs/reviews/CLAUDE.md`（申報格式補 `S<段落>-BLOCKED.md`）
  - 實作時的三處調整：①`said` 的字串改成 `S<段落>-BLOCKED.md`（`-` 開頭會被 grep 當成選項，永遠紅）②同一段第二次先停時改既有的檔不算新增、會再被擋，訊息與 `docs/reviews/CLAUDE.md` 加「另建 `-BLOCKED-2.md`」，⑮ 多兩則特性測試（修 bug 時發現的同類缺陷，一起釘住）③「已知繞過」寫成 `scripts/CLAUDE.md` 那份清單的 ④，清單標題不再寫「三條」
  - 驗證（測試）：有 `docs/reviews/`、上一段有 commit 沒報告 → block 且 `said "-BLOCKED.md"`（現況紅）；新增並 commit `docs/reviews/S1-BLOCKED.md` 之後 `--start-segment` pass（特性測試，現況就綠，這一則把它釘住）
  - commit：`fix: gate 擋下訊息補上段落先停時的申報方式（S1-3）`
- S1-4 同步文件
  - 檔案：兩份 README（「CLAUDE.md 維護規則」與 gate 對策段提到 dd.docfile、review 報告的地方；沒有對應句子就不加）、`DD_PIPELINE_ARCHITECTURE.md` gate 段、`CHANGELOG.md` `## 未發布`
  - 驗證（其他方式，純文件）：本機逐 step 跑 ci.yml；每句新增的敘述用 `grep -n` 對回 gate 原始碼
  - commit：`docs: gate 三項修補的說明（S1-4）`

S1 的步驟 3–5（2026-11-15）：

- 步驟 3：code-simplifier 只改一處註解（「三種」→「四種」）。步驟 4：3 個 `code-reviewer`，0 條 Critical、3 條 Important、8 條 Smells（去掉重複），全部採納；報告在 `docs/reviews/2026-11-15-audit-fixes/S1-{a,b,c,judge}.md`
- 步驟 4 帶出的程式碼改動：不是空樹的 tree 當起點時改走「內容不是 commit、也不是空樹」那一句；測試補四種的 `stdout_empty`、各支自己那一行的 `said`、`notes.sh` 那則移到 commit 之前
- 步驟 5（修完之後重跑）：`/bin/bash tests/test-gate.sh` macOS（bash 3.2）rc=0、150 個 ✅、0 個 ❌；ubuntu:24.04 容器（bash 5.2.21）rc=0、150 個 ✅、0 個 ❌；
  拋棄式 repo 設 `dd.docfile=main.py` 後 commit 與 `--start-segment` 都 rc=1、印「不可以是程式碼檔名」、沒有產生 commit；本機照 ci.yml 逐 step 跑 26 個全部 rc=0；
  變異九個（各只改一處，固定版與變異版判定行數相同），紅的都只落在對應的斷言，對照記在 `scripts/CLAUDE.md`
- 步驟 7：跳過 —— 這一段的教訓（`said` 字串不可以 `-` 開頭、同一段第二次先停要另建檔、`stdout 空` 只講那四種）在步驟 1–6 已經寫進 `tests/CLAUDE.md`、`scripts/CLAUDE.md`、`docs/reviews/CLAUDE.md`，沒有另外要進根目錄或全域的。步驟 8：範圍三份（`docs/reviews/CLAUDE.md`、`scripts/CLAUDE.md`、`tests/CLAUDE.md`），逐句對回測試名稱與指令，修了三處對不上的（變異表「三則 `stdout_empty`」應為四則、對照那則的名稱、`tests/CLAUDE.md` 把 `stdout_empty` 寫成對舊寫法有牙）
- S2 開工時要接的事：`scripts/CLAUDE.md` 那句「`skills/dd-loop/SKILL.md`…要跟著對一次」—— S2-1 落地後在那裡補上 dd-loop 已經照訊息分情況

### S2 流程文字（依賴 S1：文字要引用 S1 改好的 gate 訊息）

- S2-1 `skills/dd-loop/SKILL.md`：`--segment-base` exit 非 0 之後的下一步
  - 內容：有進度表 → 用表上這段的起點；沒有進度表 → 看 gate 印的那一句：「沒記過」就當成範圍不明、問使用者一題（與 `skills/code-simplifier/SKILL.md`「取不到起點」那句一致）；「不在目前分支的歷史裡」就用它印的共同祖先，不重跑 `--start-segment`。全域模板不改（A2）
  - 檔案：`skills/dd-loop/SKILL.md`；`skills/code-simplifier/SKILL.md` 只檢視、有矛盾才改
  - 驗證（乾跑）：一個 subagent 在拋棄式 repo（已記起點 → amend → 再 commit 一筆）照 repo 這份 `skills/dd-loop/SKILL.md` 算步驟 4 的範圍，交回它用的起點；我用指令核對它等於 gate 印的共同祖先 sha、起點檔內容沒變
  - commit：`fix: dd-loop 補上取不到起點時的下一步（S2-1）`
  - 乾跑結果（2026-11-15，兩個 sonnet subagent 各拿一個拋棄式 repo、只給 `skills/dd-loop/SKILL.md` 的副本，結果用指令核對）：
    amend 臂交回的起點 `6cc6922…` 等於 `git merge-base <起點檔的值> HEAD`，起點檔內容與乾跑前相同，沒有多出 commit；
    加跑一個「從沒記過起點」的臂：它停下來交回要問使用者的那一題、沒有跑 `--start-segment`（起點檔仍不存在）。
    兩臂都沒有回報要猜的句子；「沒記過」臂提到文件沒寫問到起點之後要不要補記 —— 不補記（下一段開始前照常跑 `--start-segment`），沒有另外加句子
  - 同批改了 `skills/code-simplifier/SKILL.md`「取不到起點」那句：原句只說「問一題，不要退回 `HEAD~1`」，gate 印出共同祖先時照它做會多問一題，補上「印出共同祖先就用它、不要重跑 `--start-segment`」
- S2-2 `skills/task-planner/SKILL.md` 規則區塊的 BLOCKED 那條（A5）
  - 內容：在「先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md」後面補：專案有 `docs/reviews/` 時，同一個 commit 加 `docs/reviews/S<段落>-BLOCKED.md` 寫明停下的原因（不然 `--start-segment` 會以「上一段沒有附 review 報告」拒絕）；回頭做完這段時步驟 4 照跑、報告照落地。「有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段」那條不改。`skills/dd-loop/SKILL.md`「報告一律落地」那條同步寫明這個檔名不算審查報告
  - 檔案：`skills/task-planner/SKILL.md`、`skills/dd-loop/SKILL.md`
  - 驗證（乾跑，會 commit 所以在拋棄式 repo 真跑）：一個 subagent 拿一份有進度表、有 `docs/reviews/`、S1 做到一半的拋棄式 repo，prompt 寫明「使用者已要求先做 S2」，照規則區塊把 S1 標 BLOCKED 並開 S2；我用指令核對 `docs/reviews/S1-BLOCKED.md` 已 commit、`--start-segment` exit 0、進度表 S1 是 BLOCKED 且 commits 欄的起點沒被改
  - commit：`fix: task-planner 補上段落先停時的 review 申報檔（S2-2）`
  - 乾跑結果（2026-11-15，一個 sonnet subagent，拋棄式 repo 有進度表、有 `docs/reviews/`、S1 做完第一個小任務；它只讀專案自己的文件，規則區塊是改好的這一版）：
    第一次 `--start-segment` 被擋 → 它建 `docs/reviews/S1-BLOCKED.md`、進度表 S1 標 `BLOCKED` 和原因、一個 commit → 第二次 `--start-segment` exit 0。
    指令核對：`git log --diff-filter=A --name-only -- docs/reviews` 有 `S1-BLOCKED.md`；起點檔 = HEAD；進度表 S1 是 `BLOCKED…`、commits 欄仍是 `bf179bf..`；S2 是 `IN_PROGRESS`、`639bc77..`（留在工作目錄沒 commit，照規則跟第一個小任務一起送）。
    它回報要猜的四處（狀態格的格式、申報檔的內容格式、先停那個 commit 的訊息格式、有沒有 SKIP 欠帳要自己查）都是原本規則就沒寫死的，結果都對，沒有另外加句子
  - 規則區塊多寫了計畫沒列的一句：同一段第二次先停另建 `S<段落>-BLOCKED-2.md`（S1-3 實作時發現 gate 只認新增的檔）
- S2-3 `commands/dd-init.md` Phase 4 兩處措辭
  - 內容：①改成解析 JSON、`enabledPlugins` 裡那個鍵的值是 `true` 才算啟用（鍵在、值為 `false` 是停用；不用字串比對）②「（腳本會裝）」改成先 `claude plugin install claude-md-management@claude-plugins-official`；已經下載、只是沒登記時，重跑 `./install-dd-pipeline.sh` 會登記並啟用（它不下載）
  - 檔案：`commands/dd-init.md`（Phase 4，蓋章區塊之外）
  - 驗證（乾跑）：三個 subagent 各拿一份假的 settings.json（值 true／值 false／沒有那個鍵）照 Phase 4 這段文字判斷，交回結論與它會給使用者的提示；結論依序要是已啟用／未啟用／未啟用。本機逐 step 跑 ci.yml 確認兩道蓋章區塊檢查照綠
  - commit：`fix: dd-init Phase 4 判斷 plugin 啟用看值、不講安裝腳本會下載（S2-3）`
  - 乾跑結果（2026-11-15，sonnet subagent 各拿一份假的 settings.json，不准讀真的、不准跑 `claude plugin`）：值 true → 已啟用、無提示；值 false → 未啟用、提示 `claude plugin enable …`；沒有鍵 → 未啟用、提示 `claude plugin install …`；
    檔案截斷（計畫外加的第四臂）→ 無從判定、不提示安裝。假檔的真值另用 `jq` 與 `python3` 各讀一次核對
  - 與計畫不同的三處：①第一版照計畫寫「未啟用 → 先 `claude plugin install`」，值 false 那臂回報「停用與沒登記要不要給不同提示」沒寫 —— 分成兩條，停用給 `claude plugin enable`（`claude plugin --help` 列有 `enable [options] <plugin>  Enable a disabled plugin`，2.1.325 本機實跑）
    ②計畫寫的「已經下載、只是沒登記時重跑安裝腳本會登記並啟用」沒有寫進指令：讀 `install_plugins()` 後，它的條件是 marketplace 目錄有那個 plugin 的 `plugin.json` 而且取得到版本字串，一句話講不準，沒有寫進指令。第一版還留著半句「只把本機已經有的登記起來並設成啟用」，步驟 4 的審查者指出它跟這裡的說法不一致，定稿只剩「安裝腳本不下載 plugin 的檔案」
    ③加一句 `jq` 的 `//` 會把 `false` 當成沒有值（沒有鍵那臂回報的，`echo '{"a":false}' | jq -r '.a // "無鍵"'` 印「無鍵」）；改字之後 true／false／沒有鍵／壞檔四臂重跑過，加 `//` 那句之後 false 臂再跑一次，結論都相同
- S2-4 `CHANGELOG.md` `## 未發布` 補 S2 的條目（含 A7 那句）；commit：`docs: 流程文字三項修補的 CHANGELOG（S2-4）`

S2 的步驟 3–5（2026-11-15）：

- 步驟 3 沒有跑：diff 全是 Markdown，沒有程式碼。步驟 4：3 個 `code-reviewer`，0 條 Critical、4 條 Important、5 條 Smells，全部採納；報告在 `docs/reviews/2026-11-15-audit-fixes/S2-{a,b,c,judge}.md`
- 步驟 4 帶出的改動：`/dd-init` Phase 4 改成直接附一條 `jq`（判法同 `plugin_enabled_state()`），不讓模型自己寫；code-simplifier 取不到起點時改問「這一段從哪個 commit 開始」；task-planner 的 `BLOCKED` 那條改成「專案有 `docs/reviews/` 時先停一律 commit 申報檔」並寫明放哪、寫什麼；dd-loop 補上錯誤印在 stdout 的情況；本檔照抄的規則區塊同步
- 步驟 5（修完之後）：Phase 4 的指令對 12 份假設定檔的結論與 `plugin_enabled_state()` 逐份相同，文件裡的指令與測過的那份 `diff` 相同；改過字的三處重跑乾跑六臂（Phase 4 的 false／空檔／字串值、規則區塊的多張表／零 commit 先停、code-simplifier 沒記過起點），結果用指令核對都對；本機照 ci.yml 逐 step 跑的結果見這個 commit 的訊息
- 步驟 7：沒有寫檔。有一條候選要等使用者同意才寫進根目錄 CLAUDE.md「注意事項」查設定檔那一條：指令文字要模型判斷 plugin 啟用狀態時，直接附 `/dd-init` Phase 4 那條 `jq`，不要寫「用 jq 讀」——
  模型自己寫的 `jq` 會踩三個坑（`//` 把 `false` 當成沒有值、`-r` 印出來分不出字串 "true" 與布林 true、空檔不報錯也不印東西），這一段三個都實測到
- 步驟 8：範圍只有 `scripts/CLAUDE.md`。修了一句因為這一段而過期的（task-planner 規則區塊「只交代補 CLAUDE.md」）、補了 dd-loop 現在怎麼處理印在 stdout 的錯誤、同步清單加上「認 gate 字串的兩處」
- 沒驗證的：`claude plugin enable` 與 `claude plugin install` 都沒有實跑（會改真實的 `~/.claude`），只確認 `claude plugin --help` 列有這兩個子指令

### S3 安裝腳本 `--check`

- S3-1 `check_builtin_skills`、`check_builtin_agents` 比對內容
  - 內容：目錄／檔案在的時候，再用 `diff -rq`（skills）或 `cmp -s`（agents）比 repo 來源（`$SCRIPT_DIR`）與部署版；不同就印「已安裝（與 repo 不同，重跑安裝會更新）」並另外計數，結尾多一行。只印、不改檔、不影響結束碼。`diff`／`cmp` 一律放在 `if` 條件裡（腳本是 `set -e`）。判斷方式與安裝本身相同，所以部署目錄裡多出執行期的檔（例如 `.DS_Store`）時兩邊一樣會判成不同
  - 檔案：`install-dd-pipeline.sh`、`tests/test-install.sh`（新增 T11；`TEST_ONLY` 白名單那一行、它的錯誤訊息、上方註解與檔頭的組別清單同批加 T11）、`tests/CLAUDE.md`
  - 驗證（測試）：先寫 T11、確認現況紅：沙盒 HOME 安裝後改一個已部署 skill 的 SKILL.md 與一個 agent 檔，跑 `--check`：那兩行含「與 repo 不同」、另一個沒改的 skill 那行不含、`--check` 前後沙盒 HOME 的檔案清單與內容雜湊相同、rc=0
  - commit：`feat: --check 看得出部署版與 repo 不同（S3-1）`
- S3-2 文件：兩份 README 的 `--check` 說明、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md` `## 未發布`；驗證：本機逐 step 跑 ci.yml（flag 三方對照只驗名稱，名稱沒變）；commit：`docs: --check 新增的過期提示（S3-2）`

### S4 vendored 內容與授權

開工前提：①查 GitHub 上游的 `code-simplifier` plugin 目錄有沒有 LICENSE（repo 名稱從本機 `~/.claude/plugins/known_marketplaces.json` 讀，讀不到就不查、照 A10 寫）②讀 `skills/self-improving-agent/CLAUDE.md` 有沒有記「與上游的差異」，有就同批更新。

- S4-1 拿掉 self-improving-agent 指不到東西的安裝小節
  - 檔案：`skills/self-improving-agent/SKILL.md`、`skills/self-improving-agent/README.md`（刪 `### Codex CLI` 與 `### OpenClaw` 兩個安裝小節、Platform Support 表對應的兩列）、`skills/self-improving-agent/CLAUDE.md`（記這次與上游的差異）。上游的出處連結保留；`clawhub publish` 那兩處不動（A1）
  - 驗證（其他方式，行為零改動）：`grep -rn 'codex-install\|clawhub install' skills/self-improving-agent` 0 筆；`grep -rn '\$[0-9]' skills/*/SKILL.md commands/*.md` 仍是 0 筆
  - commit：`fix: self-improving-agent 拿掉指不到東西的安裝小節（S4-1）`
- S4-2 評分表只留一份（A11，行為改變）
  - 內容：`agents/memory-analyst.md`「Score each entry」底下自己的分數定義，改成指到 `~/.claude/skills/self-improving-agent/reference/promotion-rules.md` 的 Scoring Guide；門檻句留著
  - 檔案：`skills/self-improving-agent/agents/memory-analyst.md`、`skills/self-improving-agent/CLAUDE.md`
  - 驗證（乾跑）：一個 subagent 拿範例記憶（「這個專案的測試要用 /bin/bash 跑」）照改好的 memory-analyst.md 評分，交回三個分數；期望 Scope=2，三個分數等於我照 promotion-rules.md 的表算的。另跑 ci.yml 的「~/.claude/ 路徑要指得到東西」
  - commit：`fix: self-improving-agent 的評分表只留 promotion-rules 那一份（S4-2）`
- S4-3 agents 兩個官方備份的授權
  - 內容：新增 `agents/LICENSE.txt`：`code-simplifier.md` 與本機官方 marketplace 副本逐字相同（比對日期與指令）；`code-reviewer.md` 是改過的檔，有部分行與官方 `feature-dev`、`pr-review-toolkit` 的同名檔相同（行數與比對指令）；來源 plugin 目錄附 Apache License 2.0；後面附 Apache-2.0 全文（從本機官方副本的 LICENSE 複製）。兩份 README 的授權表各加一列、`DD_PIPELINE_ARCHITECTURE.md` 授權段加一句
  - 檔案：`agents/LICENSE.txt`（新）、`README.md`、`README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md` `## 未發布`（S4 三項一起寫，含 A11）
  - 驗證（其他方式，純文件）：本機逐 step 跑 ci.yml（「陣列與目錄一致性」用 `ls agents/*.md`，`.txt` 不會被算成 agent）；`cmp` 確認附的全文與本機官方副本的 LICENSE 相同
  - commit：`docs: agents 兩個官方備份補上授權檔（S4-3）`

### 測試清單（使用者 2026-11-15 選定「照這份清單加」）

1. `tests/test-gate.sh` ⑬（S1-1）：`dd.docfile` 設 `main.py`、`notes.sh` 要拒絕，`AGENTS.txt` 照常（對照）
2. `tests/test-gate.sh`（S1-2）：amend 掉起點後 `--segment-base` 失敗、不印任何起點、訊息含共同祖先、不再叫人重記；從沒記過起點時照舊叫人先記（對照）
3. `tests/test-gate.sh`（S1-2）：連共同祖先都沒有時（孤兒分支）訊息叫人用進度表的起點或問使用者
4. `tests/test-gate.sh`（S1-3）：上一段沒報告被擋時訊息列出 BLOCKED 申報檔；commit 了 `S1-BLOCKED.md` 之後開下一段放行
5. `tests/test-install.sh` T11（S3-1）：`--check` 對改過的已部署 skill 與 agent 印「與 repo 不同」、沒改的不印、不寫任何檔、結束碼 0

## 計畫審查紀錄

`plan-review` 第 1 輪：通過。4 個審查者（前提／漏掉的同步點／範圍與驗證／全面），讀檔檢查都過，沒有重派。

採納的小事（12 條，都已改進上面的計畫）：S4-2 是行為改變、要寫明 Scope 從 3 降為 2；S4-1 的 grep 驗收會命中出處連結與 `clawhub publish`；模板 `<起點>` 那句在蓋章區塊有副本、不改；S2-2 的乾跑要給「使用者已要求先做 S2」；S1-2 訊息要說範圍會多含一個 commit、乾跑驗收改成比對 sha；「自己指定」改成用進度表或問使用者；原因措辭沿用「換過分支或改寫過歷史」；「找不到共同祖先」那一支要有測試；D2 的取捨要寫明並記進已知繞過；`docs/reviews/CLAUDE.md` 要補 BLOCKED 的格式；D1 要寫出擋不到的類別；`tests/test-install.sh` 的 `TEST_ONLY` 白名單要加 T11。

駁回（7 條）：「S1 會在使用者決定前動手」（D1、D2 本來就列為要問的題）；dd-init Phase 3 寫死檔名（A1 範圍外）；README 沒提 docs/reviews（沒有就不用改）；「起點沒被改」與 `--start-segment` 衝突（指的是進度表 commits 欄）；「重跑安裝會登記並啟用」沒讀碼（已讀碼確認）；不確定 repo 來源路徑變數（`SCRIPT_DIR`）；`gh api` 查上游（已排進開工前提）。

需要外部查證（2 條小事）：Apache-2.0 對改過的衍生檔怎麼標示（A10 已寫明在授權檔標出改過）；部署目錄裡的執行期檔會被 `--check` 報成不同（S3-1 已寫明與安裝本身一致）。
