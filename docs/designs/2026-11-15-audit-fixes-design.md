# 評分後的缺陷修補

使用者要我檢查這個 repo 的流程與設定並逐項評分；交出評分後他選了「修缺陷」那一批。這份文件有四段（S1 gate、S2 流程文字、S3 安裝腳本 `--check`、S4 vendored 內容與授權）：沒有 task 工具，照全域 §4.4 用進度表記進度。

## 來源

- 使用者的話（逐字，依序，2026-11-15）：「幫我檢查claude-dd 這整個repo 流程 和設定, 再請給我一份每個的分數,低於60分要告訴我如何改善調整」、「所以現在該怎做?」
- 我用選單問「claude-dd 評分後要我動手做哪幾批？」（可複選：A 修缺陷／B review 與 workflow-review 退場／C 出兩份 CLAUDE.md 的逐條清單／D error-capture 少誤報）。**使用者只選了「A 修缺陷（建議）」**（使用者決定）。選項 A 的說明：「7 項：gate 的 dd.docfile 繞過、amend 掉起點後範圍變 0、BLOCKED 後開不了下一段、--check 看不出部署版過期、/dd-init Phase 4 兩處措辭、self-improving-agent 的死指標與評分表打架、agents 兩個官方備份補授權檔。照 8 步迴圈做，約 2–3 小時。」
- 7 項的佐證都是評分那一輪在拋棄式 repo 實跑或讀檔得到的，整理在「開工前查到的事實」
- S5（2026-11-15 加的）：S1–S4 做完後使用者再問一次同一句，我重新評分，低於 60 的還是六項，結尾寫「我建議先做 1（退場）與 3（包裝器加一句）」；使用者回「好」。「好」沒有點名項目；我讀成同意做我建議的這兩件（推論，不是使用者逐項選的）。四條步驟 7 候選沒有回覆，不寫

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
| S3 | 安裝腳本：`--check` 看得出部署版與 repo 不同 | DONE | — | `/bin/bash tests/test-install.sh` 與 ubuntu:24.04 容器都 rc=0、T11 是 ✅；變異（把比對拿掉）→ T11 紅；真的跑 `./install-dd-pipeline.sh --check`：`plan-review` 那行印出「與 repo 不同」（本機部署版正好是舊的）、其他 skill 照舊、結束碼 0；本機照 ci.yml 逐 step 全過 | 0dc3b53..575e144 |
| S4 | vendored 內容：self-improving-agent 死指標與評分表、agents 授權檔 | DONE | — | `grep -rn 'codex-install\|clawhub install' skills/self-improving-agent` 0 筆；`agents/memory-analyst.md` 不再有自己的分數定義、只指到 `reference/promotion-rules.md`；乾跑臂拿範例記憶照 memory-analyst.md 評分，Scope 是 2、三個分數等於照 promotion-rules.md 那張表算的；`agents/LICENSE.txt` 存在，兩份 README 與架構文件的授權段都列到它；本機照 ci.yml 逐 step 全過 | cf6beea..503a583 |
| S5 | `review` 包裝器與 `workflow-review` 退場、code-simplifier 包裝器補約束 | DONE | — | 本機照 ci.yml 逐 step 跑全部 rc=0；`tests/test-install.sh` 在 macOS `/bin/bash` 與 ubuntu:24.04 容器都 rc=0；沙盒 HOME 全新安裝後 `~/.claude/skills/review`、`~/.claude/commands/workflow-review` 都不存在、`commands/` 底下沒有子目錄；舊名的 `git grep`（排除 CHANGELOG、UPGRADING、docs/designs、docs/reviews、docs/measurements）剩下的每一筆都是「已退場」的敘述；code-simplifier 的 A/B：舊 prompt 至少一發重排了 import 或把箭頭函式改成 `function`，新 prompt 每一發都沒有 | b3b2bf9..41d98a7 |
| S6 | 根目錄 CLAUDE.md 搬出 `claude -p` 實驗的做法與描述導覽段 | DONE | — | 核對腳本：`bf7e654` 的根目錄 CLAUDE.md 照清單替換後與工作目錄那份逐位元組相同、每一塊整塊在目的檔恰好出現 1 次；本機照 ci.yml 逐 step 跑全部 rc=0；`git grep 'CLAUDE.md#殘留清理手動' -- . ':!docs/designs'` 0 筆（這份文件自己會提到這串字）；乾跑三臂與全新 session 補測三發的結果（判定見「段落與小任務」S6）；`wc -c CLAUDE.md` 前後的數字（56,111 → 46,424） | bf7e654..0dafca5 |
| S7 | 根目錄 CLAUDE.md 大小上限（pre-commit 與 CI 都擋） | DONE | — | 拋棄式 repo 的情境（真的 `git commit` 經過 `scripts/githooks/pre-commit`）每一則都符合預期；變異對照表上每個變異都讓它對應的情境變 ❌（表外還有 ⑯ 抓不到的，記在 `scripts/githooks/CLAUDE.md`）；`shellcheck -S warning` 與 `/bin/bash`（3.2）都過；本機照 ci.yml 逐 step 跑全部 rc=0，新 step 的 log 印出大小、上限、上限取自哪裡；上限檔臨時改成 40000 時新 step rc≠0、還原後 rc=0；標 DONE 刪掉指路句之後 `wc -c CLAUDE.md` 是 46,424 | e4ec5cc..affb9da |

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

S3 的步驟 3–5（2026-11-15）：

- 實際跑真實環境的 `--check` 時，標出不同的是 4 個 skill（`code-simplifier`、`dd-loop`、`plan-review`、`task-planner`），不只進度表寫的 `plan-review`：另外三個是 S2 改了 repo、還沒重新部署。直接 `diff -rq` 也是這四個
- 步驟 3：`code-simplifier` 跑了，沒有改。步驟 4：3 個 `code-reviewer`，0 條 Critical、5 條 Important、3 條 Smells（其中兩條是同一件事），全部採納；報告在 `docs/reviews/2026-11-15-audit-fixes/S3-{a,b,c,judge}.md`
- 步驟 4 帶出的改動：`diff`／`cmp` 回 2 以上（部署的檔讀不到）另外印「無法比對」，不併進「與 repo 不同」；T11 加「只改子目錄的 skill」「讀不到的檔」兩格，快照涵蓋目錄與 symlink、三次 `--check` 都包；
  根目錄 CLAUDE.md 拿掉「只跑四段」那句、兩份 README 的結束碼說法、`tests/CLAUDE.md` 的變異對照搬位置並照實際的改法重寫
- 測試清單以外加的（都在 T11 這一組裡）：剛裝好的對照、同名的 `code-simplifier` skill 與另外兩個沒改的不可以被標、段尾計數、輸出沒有 shell 錯誤與壞的 UTF-8、重跑安裝後不再報、只改子目錄的 skill、讀不到的檔（最後兩格是審查後修 bug 時加的）
- 步驟 5 的結果見 `S3-judge.md`「處置」
- 步驟 7：沒有寫檔。候選（等使用者同意才寫進根目錄 CLAUDE.md「注意事項」`set -e` 那一條）：`diff`、`cmp`、`grep` 有第三種結束碼（2 = 出錯），用 `! cmd` 或 `if cmd` 壓成兩種時，出錯會被算進其中一邊；要分三種就寫 `cmd || rc=$?`
- 步驟 8：範圍是根目錄 `CLAUDE.md` 與 `tests/CLAUDE.md`。修了一處（`tests/CLAUDE.md`「T8、T9、T10 另有 `utf8_ok`」漏了 T11）；根目錄那四句對回程式碼與實跑輸出都成立
- 沒做的：`--check` 的一行說明（`--help`、兩份 README 的指令範例、根目錄 CLAUDE.md）仍寫「只檢查環境」，這次之前就不精確；commands、scripts、output styles、全域 CLAUDE.md 過期了 `--check` 還是看不出來

### S4 vendored 內容與授權

開工前提：①查 GitHub 上游的 `code-simplifier` plugin 目錄有沒有 LICENSE（repo 名稱從本機 `~/.claude/plugins/known_marketplaces.json` 讀，讀不到就不查、照 A10 寫）②讀 `skills/self-improving-agent/CLAUDE.md` 有沒有記「與上游的差異」，有就同批更新。

開工前提的結果（2026-11-15）：①`known_marketplaces.json` 記的 repo 是 `anthropics/claude-plugins-official`；`gh api repos/anthropics/claude-plugins-official/contents/plugins/code-simplifier --jq '.[].name'` 回 `.claude-plugin`、`LICENSE`、`agents` —— 上游線上版有 LICENSE。本機官方副本（`~/.claude/plugins/marketplaces/claude-plugins-official/`）的 `plugins/code-simplifier/LICENSE`、`plugins/feature-dev/LICENSE`、`plugins/pr-review-toolkit/LICENSE` 與根目錄 `LICENSE` 用 `cmp` 比都相同（Apache License 2.0，202 行）。②`skills/self-improving-agent/CLAUDE.md` 沒有記與上游差異的段落（`grep -n '上游\|差異\|upstream'` 0 筆），S4-1 在檔尾新開一節。

- S4-1 拿掉 self-improving-agent 指不到東西的安裝小節
  - 檔案：`skills/self-improving-agent/SKILL.md`、`skills/self-improving-agent/README.md`（刪 `### Codex CLI` 與 `### OpenClaw` 兩個安裝小節、Platform Support 表對應的兩列）、`skills/self-improving-agent/CLAUDE.md`（記這次與上游的差異）。上游的出處連結保留；`clawhub publish` 那兩處不動（A1）
  - 驗證（其他方式，行為零改動）：`grep -rn 'codex-install\|clawhub install' skills/self-improving-agent` 0 筆；`grep -rn '\$[0-9]' skills/*/SKILL.md commands/*.md` 仍是 0 筆
  - commit：`fix: self-improving-agent 拿掉指不到東西的安裝小節（S4-1）`
- S4-2 評分表只留一份（A11，行為改變）
  - 內容：`agents/memory-analyst.md`「Score each entry」底下自己的分數定義，改成指到 `~/.claude/skills/self-improving-agent/reference/promotion-rules.md` 的 Scoring Guide；門檻句留著
  - 檔案：`skills/self-improving-agent/agents/memory-analyst.md`、`skills/self-improving-agent/CLAUDE.md`
  - 驗證（乾跑）：一個 subagent 拿範例記憶（「這個專案的測試要用 /bin/bash 跑」）照改好的 memory-analyst.md 評分，交回三個分數；期望 Scope=2，三個分數等於我照 promotion-rules.md 的表算的。另跑 ci.yml 的「~/.claude/ 路徑要指得到東西」
  - commit：`fix: self-improving-agent 的評分表只留 promotion-rules 那一份（S4-2）`
  - 乾跑結果（2026-11-15，兩個 sonnet subagent；預期在派出前寫下：新版 Durability 2、Impact 2、Scope 2，舊版 Scope 3）：新版交回 2／2／2、總分 6，讀的是 `~/.claude/skills/self-improving-agent/reference/promotion-rules.md`（部署版與 repo 這份 `cmp` 相同）；
    舊版（改之前的 `memory-analyst.md`）交回 Durability 3、Impact 2、Scope 3、總分 8。同一條記憶在兩版差 2 分，其中 Scope 差的 1 分是定義不同造成的；Durability 差的 1 分是舊版沒有刻度、它自己說是猜的。
    新版那個 subagent 回報表上「Stable pattern／Architectural truth」「Prevents mistakes／Prevents breakage」的界線沒寫 —— 那是上游表格本身的粗細，沒有動
  - 更正（步驟 4 審查後）：假設 A11 與下面「採納的小事」只寫了 Scope 從 3 變 2，不完整。舊版的 Durability、Impact 各只有一句問句、沒有刻度，改成照表打分之後這兩項也會變；Scope「單檔」也從 1 變 0。
    總分可能升也可能降。上面那條乾跑的 8 → 6 仍達門檻，不是「跌破門檻」的例子。`CHANGELOG.md` 與 `skills/self-improving-agent/CLAUDE.md` 已照這個寫
  - 步驟 4 審查後 `agents/memory-analyst.md` 多一句退路（讀不到評分表時不評分、升級候選清單留空並說明原因）。改完再乾跑兩發（sonnet；預期在派出前寫下）：
    正常路徑 2／2／2 = 6、候選清單有這一條；路徑改成不存在的檔（其餘逐字相同）→ 沒評分、沒有找別的檔代替、候選清單是空的並說明原因。都與預期相同。
    兩發都回報「Use the format defined in the `/self-improving-agent:review` skill」那一句要猜 —— 既有的句子，沒有動
- S4-3 agents 兩個官方備份的授權
  - 內容：新增 `agents/LICENSE.txt`：`code-simplifier.md` 與本機官方 marketplace 副本逐字相同（比對日期與指令）；`code-reviewer.md` 是改過的檔，有部分行與官方 `feature-dev`、`pr-review-toolkit` 的同名檔相同（行數與比對指令）；來源 plugin 目錄附 Apache License 2.0；後面附 Apache-2.0 全文（從本機官方副本的 LICENSE 複製）。兩份 README 的授權表各加一列、`DD_PIPELINE_ARCHITECTURE.md` 授權段加一句
  - 檔案：`agents/LICENSE.txt`（新）、`README.md`、`README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md` `## 未發布`（S4 三項一起寫，含 A11）；
    實際還改了根目錄 `CLAUDE.md`「目錄結構」`agents/` 那一行（計畫漏列），與步驟 4 審查後加的 `agents/code-reviewer.md`（開頭一行改動說明）
  - 驗證（其他方式，純文件）：本機逐 step 跑 ci.yml（「陣列與目錄一致性」用 `ls agents/*.md`，`.txt` 不會被算成 agent）；`cmp` 確認附的全文與本機官方副本的 LICENSE 相同
  - commit：`docs: agents 兩個官方備份補上授權檔（S4-3）`

S4 的步驟 3–5（2026-11-15）：

- 步驟 3：沒有跑 `code-simplifier`，這一段的 diff 全是 Markdown 與純文字。步驟 4：照樣派了 3 個 `code-reviewer`（有一處行為改變與一批引別處的宣稱），0 條 Critical、3 條 Important、7 條 Smells，全部採納；
  報告在 `docs/reviews/2026-11-15-audit-fixes/S4-{a,b,c,judge}.md`
- 步驟 4 帶出的改動：`agents/code-reviewer.md` 開頭加一行改動說明（Apache-2.0 第 4 條 (b)；這個檔原本不在 S4-3 的檔案清單）；`agents/memory-analyst.md` 補讀不到評分表時的退路；
  `skills/self-improving-agent/CLAUDE.md` 的差異清單寫明從 2026-11-15 起、不完整；行為改變的說明改成三項都會變（見 S4-2 的更正）；`agents/LICENSE.txt` 開頭三處說法改準；授權檔的 CHANGELOG 條目移到 `### Added`
- 步驟 5 的結果見 `S4-judge.md`「處置」
- 沒做、沒驗證的：沒有重新部署，部署版的 `memory-analyst.md`、`code-reviewer.md` 還是舊的；加了那一行說明的 `code-reviewer.md` 沒有拿去實際審查過；授權標示夠不夠沒有人驗證過；
  `skills/self-improving-agent/settings.json` 的 `platforms` 仍列 `openclaw`、`codex`；skill 裡 review／promote 兩個子 skill 的候選條件與 Scoring Guide 是兩套說法、`memory-analyst.md` 的 Output Format 指到沒有分數欄位的格式（都是既有的，審查者 A 列在 Not reported）
- 步驟 7：沒有寫檔。候選（等使用者同意才寫進根目錄 CLAUDE.md）：①收編檢查清單第 1 項「授權相容」只查授權檔在不在、相不相容；補一句「把那份授權的散布條件逐條對被收的檔 —— Apache-2.0 改過的檔要在檔內寫明改過（第 4 條 (b)）」
  ②寫「行為改變」的說明時重新比對新舊兩份定義的每一項，不沿用計畫裡的一句話；舉的例子要示範得出那個結論
- 步驟 8：範圍是根目錄 `CLAUDE.md` 與 `skills/self-improving-agent/CLAUDE.md`。根目錄修了一處：「新增 Agent 步驟」寫官方備份「維持上游的 `opus`」，官方 `feature-dev` 版的 code-reviewer 其實是 `sonnet`，改成寫明哪幾份是什麼；
  同一句補上「改這兩個官方備份之後重跑 `agents/LICENSE.txt` 列的比對指令」。skill 那份的差異清單逐句對回 git 與檔案都成立，沒有改

### S5 `review` 兩個元件退場、code-simplifier 包裝器補約束

假設（S5 自己的；`plan-review` 審過）：

- B1 退場 = 從 repo 刪掉 `skills/review/` 與 `commands/workflow-review/`（`git rm -r`）並從部署陣列拿掉。不另開 tag；取回用 `git checkout v1.6.14 -- skills/review commands/workflow-review`（`git diff v1.6.14 b3b2bf9 -- skills/review commands/workflow-review` 是空的，tag 已經在 origin 上）
- B2 使用者機器上已部署的 `~/.claude/skills/review/`、`~/.claude/commands/workflow-review/` 不由安裝腳本清：`create_commands` 既有的清理迴圈（`deprecated_dd`）只認 `dd-*.md` 單檔，不涵蓋命名空間目錄與 skills 目錄，`--uninstall` 也只認現行部署清單。
  沿用 2026-08-04 的做法，在 `UPGRADING.md` 寫手動清理的指令；不擴充那個迴圈、不動 `~/.claude`
- B3 不發版、不跳 `dd-loop-rev`；CHANGELOG 只寫進 `## 未發布`
- B4 兩件事放同一段：都小、同一次同意，步驟 4 一次審兩件
- B5 `agents/code-simplifier.md` 不動（`agents/LICENSE.txt` 寫它與官方檔逐字相同）。約束加在 `skills/code-simplifier/SKILL.md`
- B6 `skills/self-improving-agent/skills/review/`（也是 `name: review`）不動；撞名因為 `skills/review` 退場而消失
- B7 沒有要新增的測試：S5-1 只改既有斷言（部署清單變了），S5-2 用 A/B 實跑驗

開工前提的結果（2026-11-15，scratchpad 實測）：照 ci.yml「陣列與目錄一致性」`ALL_NS_COMMANDS` 那一組的寫法、陣列是空的、`set -e`，macOS `/bin/bash` 3.2.57 與 ubuntu:24.04 都判「一致」，多一個子目錄時判「不一致」，rc=0；
但 macOS 多印一行 `ls: commands/*/: No such file or directory`，ubuntu 多印那一行與 `basename: missing operand`。空陣列的 `for` 迴圈跑 0 次。

- S5-1 `review` 包裝器與 `workflow-review` 退場
  - 內容：`git rm -r skills/review commands/workflow-review`；`install-dd-pipeline.sh` 的 `PROMOTED_SKILLS` 拿掉 `"review"`、`NS_COMMANDS` 變空陣列，`create_commands` 的「命名空間 Commands (N 個)」標題在 N 是 0 時不印（其他印個數的地方照印 0）；
    ci.yml 那一組的目錄那一邊改成 `find commands -mindepth 1 -maxdepth 1 -type d | sed 's#.*/##' | sort`（不用 `xargs`，沒有子目錄時不印錯誤）；
    `tests/test-install.sh` 開頭兩條 `workflow-review` 的斷言改成「`commands/` 底下沒有子目錄」，T11「讀不到的檔」那一格寫 `review` 的四行（`chmod 000`、`cat` 判斷、`t11_expect`、`chmod 644`）換成 `verification-gate`
  - 檔案：`skills/review/`、`commands/workflow-review/`（刪）、`install-dd-pipeline.sh`、`.github/workflows/ci.yml`、`tests/test-install.sh`、`tests/CLAUDE.md`（T11 變異對照裡寫 review 的那一句，重跑那個變異再改）、根目錄 `CLAUDE.md`（目錄結構的數字與名稱、部署清單加取回方式）、
    `README.md`、`README.zh-TW.md`（安裝步驟、指令一覽、Promoted Skills 標題與那一列、授權表那一列）、`DD_PIPELINE_ARCHITECTURE.md`（部署清單那句、授權段的例外）、`UPGRADING.md`（已部署的殘留手動清、取回方式）、`CHANGELOG.md` `## 未發布` `### Removed`
  - 驗證（其他方式 + 既有測試；沒有新行為可以寫成會失敗的測試，改的是部署清單）：本機逐 step 跑 ci.yml 全部 rc=0；負面測試（拋棄式副本，macOS 與 ubuntu 容器各一次）：`commands/` 多一個子目錄、`NS_COMMANDS` 多一個名字而目錄不在、`PROMOTED_SKILLS` 留著 `review` 而目錄刪掉，三個都要紅，還原回綠；
    那個 step 在沒有子目錄時 stderr 是空的（兩個平台）；`tests/test-install.sh` 整份在 macOS `/bin/bash` 與 ubuntu:24.04 容器 rc=0，容器另開一般帳號跑 `TEST_ONLY=T11`；
    沙盒 HOME 全新安裝 rc=0、輸出沒有「命名空間 Commands」那一行與 shell 錯誤、`~/.claude/commands/` 只有 `dd-init.md`，`--uninstall --yes` rc=0；
    升級情境（沙盒 HOME 先裝 b3b2bf9 的內容、再裝新版）：兩個舊目錄還在，照 `UPGRADING.md` 新寫的指令清掉後 `--check` 正常；
    舊名的 `git grep`（`workflow-review`，以及濾掉 `self-improving-agent/skills/review` 的 `skills/review`；排除 CHANGELOG、UPGRADING、docs/designs、docs/reviews、docs/measurements）：剩下的每一筆都要是「已退場」的敘述，逐筆列在下面的結果裡，不能有把它們當成還在的句子
  - commit：`chore: review 包裝器與 workflow-review 退場（S5-1）`
  - 結果（2026-11-15）：
    - 刪之前 `git status --short --ignored -- skills/review commands/workflow-review` 沒有輸出（兩個目錄各只有一個追蹤中的檔），`git rm -r` 後目錄不在
    - `grep -nE 'set -[a-z]*u|nounset' install-dd-pipeline.sh tests/*.sh .github/workflows/ci.yml scripts/*.sh` 沒有命中（空陣列在 bash 3.2 不會撞到未定義變數檢查）
    - 本機逐 step 跑 ci.yml：26 個 step 都 rc=0
    - 負面測試（「陣列與目錄一致性」那個 step，macOS `/bin/bash` 與 ubuntu:24.04 各一次，結果相同）：乾淨版 rc=0、stderr 0 行；`commands/` 多一個 `stray/` → rc=1「ALL_NS_COMMANDS：陣列與實際目錄不一致」；
      `NS_COMMANDS=("ghost")` 而目錄不在 → rc=1 同一句；`PROMOTED_SKILLS` 留著 `"review"` → rc=1「ALL_SKILLS：陣列與實際目錄不一致」
    - `tests/test-install.sh` 整份：macOS `/bin/bash` rc=0、行首 ❌ 0；ubuntu:24.04 容器三支測試加兩支 hook 測試都 rc=0，另開一般帳號跑 `TEST_ONLY=T11` rc=0（讀不到檔那一格有跑到）
    - T11 變異重跑（兩處 `-eq 1` 改 `-ge 1`）：rc=1「Skills 的 verification-gate 那一行應該有『無法比對』，實際：…已安裝（與 repo 不同，重跑安裝會更新）」；原版 rc=0
    - 沙盒 HOME 全新安裝 rc=0：輸出是「DD Pipeline Commands (1 個)」接「└── dd-init: 已安裝（新）」，沒有命名空間標題、shell 錯誤 0 筆；`~/.claude/commands/` 只有 `dd-init.md`、`~/.claude/skills/` 13 個目錄沒有 `review`。`--uninstall --yes` rc=0（提示印「0 個命名空間 Commands」）
    - 升級情境：沙盒 HOME 先裝 b3b2bf9 的內容（rc=0，兩個舊目錄在）→ 新版 `--force`（rc=0，兩個舊目錄還在，`--check` 沒有提到它們）→ 照 `UPGRADING.md` 的兩行指令清掉 → `--check` rc=0、skills 13 個
    - 舊名的 `git grep` 剩下的（都是「已退場」的敘述）：`CLAUDE.md`「部署清單」與「目錄結構」各一句、`DD_PIPELINE_ARCHITECTURE.md` 部署清單的歷史與授權段各一句、`install-dd-pipeline.sh` 的 `NS_COMMANDS` 註解、`tests/CLAUDE.md` 一行（「`commands/` 底下沒有子目錄」那條；同檔 T11 變異那一句提的是 `review` skill，不含 `workflow-review` 這個字）；`skills/review`（濾掉 `self-improving-agent/skills/review`）0 筆
    - 計畫以外多改的：根目錄 `CLAUDE.md`「新增 Command 步驟」命名空間那條、`tests/CLAUDE.md` 各補一句「命名空間的部署程式碼現在沒有測試跑到，加回時把斷言換回來」；`UPGRADING.md` 開頭「三種升級情境」改「四種」
- S5-2 code-simplifier 包裝器補一句約束
  - 內容：`skills/code-simplifier/SKILL.md` 的 Prompt 模板「約束：」那一行後面加一句：編碼風格只照專案 CLAUDE.md 寫明的；agent 定義裡列的偏好（import 排序、`function` 與箭頭函式的取捨）不算專案標準，專案 CLAUDE.md 沒寫就不套用，不重排 import
    （這是第一版，63f4d6c commit 的就是它；步驟 4 的審查之後改成第二版，現行的句子以 `skills/code-simplifier/SKILL.md` 為準，見下面「第三輪」）
  - 檔案：`skills/code-simplifier/SKILL.md`、`CHANGELOG.md` `## 未發布`
  - 驗證（行為，A/B；結果用 `diff`、`grep` 核對，不看 agent 自述）：scratchpad 的拋棄式 repo 放一個小 `.js`（import 沒排序、有箭頭函式、有一處可簡化的巢狀條件），CLAUDE.md 不寫風格規則。派包裝器實際會先試的那個 agent 類型（`code-simplifier:code-simplifier`；派之前 `cmp` 它的定義檔與 repo 這份）：舊 Prompt 模板 2 發、新的 2 發，各在自己的副本上改。
    每一發另外要它照貼 context 裡出現的 CLAUDE.md 路徑與第一行（subagent 可能帶著這個 session 的全域 CLAUDE.md，那份 §3.2 已經寫「不重排 import」，會讓舊的那一邊也不動）。
    判定（派出前寫死）：舊的至少 1 發重排了 import 或把箭頭函式改成 `function`，而新的每一發都沒有 → 通過；新的任何一發照樣重排或改成 `function` → S5-2 不成立，不 commit、不寫 CHANGELOG，停下來回報使用者（要改 agent 本文會碰到 B5）；
    舊的每一發都沒動 → 這個素材沒有鑑別力，不當成通過的證據：換一次素材（只把沒排序的 import 與箭頭函式加多，其餘不變）再跑一輪 2+2；
    還是分不出來 → 那一句照樣 commit（它與全域 §3.2 同方向，前提是新的每一發都沒有重排、巢狀條件有被簡化），CHANGELOG 與回報寫明「沒有實測證據顯示它改變了行為」，不拿它當評分改善的依據
  - commit：`fix: code-simplifier 包裝器不套用專案沒寫的風格偏好（S5-2）`
  - 結果（2026-11-15；派的是 `code-simplifier:code-simplifier`，它的定義檔 `~/.claude/plugins/cache/claude-plugins-official/code-simplifier/1.0.0/agents/code-simplifier.md` 與 repo 這份 `cmp` 相同；數字都是我用 `grep`、`diff`、`node` 核對的，不是 agent 自述）：
    - 第一輪（全檔都用箭頭函式、import 沒排序、三層巢狀；舊 2 發、新 2 發）：四發的 import 行都與原檔相同、`function` 宣告都是 0、`result = null` 都清掉了 → 舊的每一發都沒動，**這份素材沒有鑑別力**。
      四發照貼的 context：都有 `~/.claude/CLAUDE.md` 與這個 repo 的根目錄 `CLAUDE.md`（素材專案的 CLAUDE.md 沒有被注入，是它們自己讀的）。舊的兩發不動的理由都是「這個檔全用箭頭函式，以專案寫法為準」
    - 第二輪（換素材；與上面寫的「只把 import 與箭頭函式加多」不同：依第一輪看到的理由改成**風格混用**，`function` 2 個、箭頭 4 個、import 7 行沒排序且 `./zones.js` 分兩行；這一輪沒有叫它照貼 context）：

      | 臂 | 模組出現順序 | import 行 | `function` 宣告 | 箭頭 | 巢狀條件 | `quote()` 9 組輸入與原版（我自己的比對，見表下） |
      |---|---|---|---|---|---|---|
      | 原檔 | zones、fs、os、path、crypto、assert | 7 行 | 2 | 4 | — | — |
      | 舊 1 | 變了（內建照字母在前、zones 在後） | 6 行 | 6 | 0 | 已簡化 | 相同 |
      | 舊 2 | 變了（同上） | 6 行 | 6 | 0 | 已簡化 | 相同 |
      | 新 1 | 相同 | 逐字相同 | 3（多一個不匯出的 helper） | 4 | 已簡化 | 相同 |
      | 新 2 | 相同 | 逐字相同 | 2 | 4 | 已簡化 | 相同 |

      9 組輸入是我自己另外跑的，第一次是臨時寫在指令列裡、沒存檔，審查者在素材目錄找到的 13 組那一支是某一臂自己留下的、不是這個數字的出處。
      第三輪起存成 `<scratchpad>/s5-ab2/mycmp.mjs`：它的 9 組是 `undefined`、`null`、`{}`、`items: null`、空陣列、未知國家、TW、US 加 express、JP 加 `express: 0`（`id` 是隨機值只比型別與長度）；
      第一次那一支沒留下來，是不是同樣這 9 組核對不了。用存檔的這一支重跑：原檔對自己、舊 1、舊 2、新 1、新 2、新 3、新 4 都是 `inputs 9 diffs 0`

      判定：舊的 2 發都重排了 import、把 4 個箭頭全改成 `function`，新的 2 發都沒有 → 判定式（舊的至少一發有、新的每一發都沒有）是派出前寫的，照它算通過；素材不是派出前定的那一份（見上）。每臂 n=2、一份素材。
      第二輪沒有量 context：第一輪四發都回報有全域 CLAUDE.md（它的 §3.2 寫「不重排 import」），同一個 session 接著派的第二輪照理也有，這是推論；所以「舊模板看得到 §3.2 照樣重排」沒有直接證據。沒有全域 CLAUDE.md 的環境沒測
    - 副作用：新的 2 發都沒有合併 `./zones.js` 那兩行 import，理由都是「合併就得挪動 import」。那一句沒有為這個再改字（改了字，上面的證據就不算它的，要重跑）；寫進 CHANGELOG
    - 第三輪（步驟 4 的審查之後；那一句改了字，前兩輪的證據不算新句子的）。審查指出三件事：括號只點名兩項會被讀成完整清單（agent 那一節列了六項）、
      「不重排 import」讀起來不帶條件（專案 CLAUDE.md 有寫 import 規則時會打架、合併重複行也被擋）、「只照專案 CLAUDE.md」字面上連既有程式碼的寫法也排除。
      新句子見 `skills/code-simplifier/SKILL.md` 的 Prompt 模板。**派出前寫死的判定**：同一份第二輪素材、新句子 2 發（舊模板沒改字，沿用第二輪舊 1、舊 2 當對照）；
      每一發都要 模組出現順序與原檔相同、箭頭 4 個都還在、沒有把箭頭改成 `function`、巢狀條件已簡化、`quote()` 對同一組輸入與原檔相同 → 通過；任何一發不符 → 新句子不成立，停下回報。
      `./zones.js` 那兩行有沒有被合併只記錄、不列入判定（句子寫的是可以合併，沒有要求）
      - 結果（判定在 6015e7b 先 commit 才派；`<scratchpad>/s5-ab2/{new3,new4}`，派工內容 `prompt-new3.txt`、`prompt-new4.txt`）：

        | 臂 | 模組出現順序 | import 行 | `./zones.js` 行數 | `function` 宣告 | 箭頭 | `result = null` 殘留 | `mycmp.mjs` |
        |---|---|---|---|---|---|---|---|
        | 原檔 | — | 7 | 2 | 2 | 4 | 4 | — |
        | 舊 1（第二輪） | 變了 | 6 | 1 | 6 | 0 | 0 | diffs 0 |
        | 舊 2（第二輪） | 變了 | 6 | 1 | 6 | 0 | 0 | diffs 0 |
        | 新 3 | 相同 | 6 | 1 | 2 | 4 | 0 | diffs 0 |
        | 新 4 | 相同 | 6 | 1 | 2 | 4 | 0 | diffs 0 |

        兩發都符合 → 通過。兩發都把 `./zones.js` 的兩行合併成一行、留在原本第一行的位置。新 3 把 `totalWeight` 的索引迴圈改成 `for...of`（對真正的陣列結果相同；`{length: 1, 0: {…}}` 這種類陣列物件會從算得出來變成丟錯，那 9 組輸入沒有這種），這跟風格約束無關，是 agent 自己的簡化判斷。
        句子裡講到、但這一輪沒測的：專案 CLAUDE.md 有寫 import 規則時照它、回傳型別標註、try/catch、「以既有寫法為準」在全檔同一種風格時的效果
    - 沒做的：沒有照根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步把整份 `SKILL.md` 乾跑一遍 —— 這次只改 Prompt 模板的一行，上面三輪 A/B 跑的就是那一行會送出去的內容（現行的句子是第三輪那 2 發）；`description` 與觸發條件沒動，沒跑 `claude -p` 的觸發測試
    - 舊的兩發各在素材目錄的上一層寫了比對用的暫存檔（違反派工寫的「只改這個目錄裡的檔」），都在 scratchpad 裡、不在 repo；其中一發回報它的檔被另一發蓋掉。不影響上表（表上的數字是我對各臂自己的 `src/quote.js` 量的）

S5 的步驟 3–5（2026-11-15）：

- 步驟 3：`code-simplifier:code-simplifier` 看了安裝腳本、測試、ci.yml 這次改到的行，沒有要改的，沒動檔
- 步驟 4：3 個 `code-reviewer`，0 條 Critical、5 條 Important、7 條 Smells；Important 全部採納，Smells 採納 6 條、駁回 1 條（沒有另派整份 `SKILL.md` 的乾跑臂）；
  報告在 `docs/reviews/2026-11-15-audit-fixes/S5-{a,b,c,judge}.md`
- 步驟 4 帶出的改動（都是文件與那一句 prompt，沒有程式碼）：`skills/code-simplifier/SKILL.md` 那一句改成第二版並重跑 A/B（上面「第三輪」）；
  `UPGRADING.md` 的清理指令先確認是不是這個 repo 部署的那一份才刪、取回步驟逐處列出並提醒授權、「只新增、覆蓋」那句改準；
  兩份 README 的 `--uninstall` 與升級指路句、根目錄 CLAUDE.md 的升級指路句補上退場元件；`tests/CLAUDE.md` 新條目搬進「此層約束」；CHANGELOG 那一條重寫；上面 S5-2 結果的兩處更正
- 步驟 5（修完之後重跑）：照 ci.yml 逐 step 跑 26 個全部 rc=0；`/bin/bash tests/test-install.sh` macOS（bash 3.2）rc=0、21 個 ✅（輸出裡 5 行 ❌ 都是沙盒安裝印的「playwright (需要手動設定)」，步驟 1 那次也是 5 行）；
  ubuntu:24.04 容器：`test-gate.sh` rc=0（150 個 ✅）、`test-dd-init-upgrade.sh` rc=0（48 個 ✅）、`test-install.sh` rc=0（21 個 ✅）、兩支 hook 測試 rc=0、一般帳號 `TEST_ONLY=T11` rc=0；
  `UPGRADING.md` 新寫的三行指令在沙盒 HOME（先裝 b3b2bf9 的內容、再裝新版）實跑三種情況：這個 repo 部署的印 5 與 `review.md`、不相干的同名 skill 印 0、檔不在印找不到；
  舊名 `git grep`（排除 CHANGELOG、UPGRADING、docs/designs、docs/reviews、docs/measurements）剩下的每一筆都是「已退場」的敘述：根目錄 CLAUDE.md 兩行、`DD_PIPELINE_ARCHITECTURE.md` 兩行、兩份 README 的 `--uninstall` 那句、`install-dd-pipeline.sh` 的 `NS_COMMANDS` 註解、`tests/CLAUDE.md` 一行
- 步驟 4 之後沒有再對真實 HOME 跑安裝；部署與清掉本機已部署的那兩個目錄由使用者自己做
- 步驟 7：候選四條列給使用者（見 `S5-judge.md`「這一段自己犯的錯」），等同意才寫進 CLAUDE.md，這一輪沒有寫。步驟 8：範圍是根目錄 `CLAUDE.md` 與 `tests/CLAUDE.md`（`claude-md-management:claude-md-improver`，只審這兩份），這一段改到的每一句實跑核對過
  （`skills/` 13 個目錄與 `PROMOTED_SKILLS` 13、`NS_COMMANDS` 0 與 `commands/` 0 個子目錄、`grep -n 'NS_COMMANDS\|ns_cmd' tests/*.sh` 只有一行註解、`UPGRADING.md` 有「已退場的元件」那一節、T11 變異的紀錄在 `<scratchpad>/s5-mut/`），沒有要改的

### S6 根目錄 CLAUDE.md 搬出 `claude -p` 實驗的做法與描述導覽段

來源：2026-11-16 我把根目錄 `CLAUDE.md` 與全域模板逐條分成「可拿掉／沒驗證／留」交給使用者（可拿掉 0 條），使用者回「B1 B2」。
B1 = 只有跑 `claude -p` 實驗才用得到的做法與坑；B2 = 描述與導覽（安裝輸出的描述、「核心工作法」、迴圈步數的 CI 兩道防線、殘留清理）。B3、B4、全域模板不動。

假設：

- 「搬」= 原文逐字搬。搬的塊由腳本從 `git show bf7e654:CLAUDE.md` 依行號切出來（切之前比對每塊開頭的字），不是重打。新寫或改過的字：根目錄留下的指路句（Skill 步驟 5、6，Agent 步驟 5，「注意事項」一條）與三條約束句；根目錄的行內改字（「目錄結構」`docs/` 那行、「CI 不驗、只能手動同步的區塊」那條補的清單項與觸發時機、收編清單第 6 項的指代）；新檔的標題、開頭兩句與各節的出處註記；搬來的字裡因為換檔而改的三處（gate 段「見下方「開發本 repo」」→「見根目錄 CLAUDE.md「開發本 repo」」、迴圈步數段尾「`DD_PIPELINE_ARCHITECTURE.md` 那處」→「本檔那處」、「量測前先關掉 advisor」三行改成一條 bullet）；架構文件三段前面的銜接句；`README.zh-TW.md` 那一段的銜接句、`README.md` 的英文翻譯；兩份 measurements 子目錄 CLAUDE.md 與 `scripts/CLAUDE.md` 各一句指路；`CHANGELOG.md` 的條目（步驟 4 的審查指出原本列得比實際少，2026-11-16 補齊）
- B1 的去處是新檔 `docs/measurements/CLAUDE.md`（檔名是我選的）。根目錄的指路寫「做之前先 Read」；巢狀 CLAUDE.md 什麼時候自動載入沒有實測過，不靠它
- 「安裝 / 更新」兩段整段搬到架構文件，其中三句是改安裝輸出時要守的約束，根目錄留著（兩邊各一份）：沒有驗證測得到 B2 的指路有沒有用，約束句不離開每輪都載入的檔
- 「核心工作法」根目錄留三段：dd-loop 與模板 §3.9 怎麼分工、§3.10 為什麼放在 §3.9 之外、task-planner 規則區塊照抄後不會跟著更新。開頭兩行與箭頭圖刪掉不搬（架構文件同名一節有自己的）；講 gate 的那段搬到架構文件同名一節的最後，與那裡既有的「配套：…」段並存、不合併
- 「殘留清理」搬進兩份 README 的「清理外部殘留」一節（使用者看到的寫法是「要搬就搬進 README」）。根目錄那一節的第一句刪掉不搬：README 既有的第一句講同一件事，少掉的只有陣列名 `BUILTIN_SKILLS` 與「tresor」這個例子
- 不發版、不跳 `dd-loop-rev`、不動 `templates/`、`install-dd-pipeline.sh`、`ci.yml`；部署與 push 由使用者自己做

小任務：

- **S6-1** B1 搬到 `docs/measurements/CLAUDE.md`
  - 搬：「新增 Skill 步驟」第 5 步、「新增 Agent 步驟」第 5 步（兩步的第一句留在根目錄，後面接指路）、「開發本 repo」的「沙盒用 `claude -p` 測行為前…」一條、「注意事項」裡開頭是這幾串字的條目：「`claude -p` 的 stream-json 要進 repo 前先去識別」「`claude -p` 實驗的 fixture 有子目錄時」「stream-json 看不出巢狀 CLAUDE.md 有沒有被讀進去」「dontAsk 加 `Bash(ls:*)` 照樣擋 cwd 外的路徑」「用 auto mode 跑 `claude -p` 時」「`claude -p` 在父 session 最後一輪結束 10 分鐘後」「受測 session 的快照放在 scratchpad 底下時」
  - 不搬：「同一則訊息裡派的幾個 subagent 不一定同時開跑」起的那幾條與「新增 Skill 步驟」第 6 步（講怎麼寫 skill、派 subagent、測 hook）
  - 同批改指路：`docs/measurements/2026-10-30-dd-loop-trigger/CLAUDE.md`、`docs/measurements/2026-10-29-adhd-style/CLAUDE.md` 各一句；根目錄「目錄結構」`docs/` 那一行
  - 驗證：核對腳本（根目錄與「`bf7e654` 那版照清單替換」逐位元組相同；每一塊整塊在新檔恰好出現 1 次；新檔扣掉搬來的塊只剩標題與出處註記；沒有 4 個以上空白開頭的行）
  - commit：`docs: claude -p 實驗的做法搬到 docs/measurements/CLAUDE.md（S6-1）`
- **S6-2** B2 搬到架構文件與 README
  - 「安裝 / 更新」底下兩段 → `DD_PIPELINE_ARCHITECTURE.md`「安裝腳本」一節最後；「核心工作法」講 gate 的那段 → 同檔「核心工作法」一節最後；「注意事項」的「**迴圈步數**已有 CI 兩道防線」一條 → 同檔「CI 防線」一節最後（表格與表後引用塊之後）；「殘留清理（手動）」的表格、指令與最後一句 → `README.zh-TW.md`「清理外部殘留（手動）」，`README.md` 同一節寫英文
  - 同批改：`scripts/CLAUDE.md`「與上層的關係」那句、根目錄收編清單第 6 項的指代、根目錄「CI 不驗、只能手動同步的區塊」那條（補四方與第五方的定義在哪、清單加上「清理外部殘留」一節）、`CHANGELOG.md` `## 未發布`
  - 驗證：核對腳本（同上，另查架構文件「CI 防線」表每一列連續、各檔圍欄行數是偶數、根目錄不含「## 殘留清理」）；`git grep 'CLAUDE.md#殘留清理手動' -- . ':!docs/designs'` 0 筆；本機照 ci.yml 逐 step 跑全部 rc=0
  - commit：`docs: 根目錄 CLAUDE.md 的描述與導覽段搬到架構文件與 README（S6-2）`

步驟 5 的乾跑（兩個小任務都 commit 之後才派；判定在這裡先寫死）：

- 各派一個全新的 general-purpose subagent，只讀，問三個實際會遇到的問題：①改了某個 skill 的 description，照這個 repo 的規則部署後怎麼驗它會不會自己被叫（要完整指令、判定方式、每次花多少）②要跑一個受測 session 會自己到暫存目錄開副本改檔的實驗、判準要求權限拒絕數是 0，權限模式怎麼選、已知會被擋的情況 ③某個會再叫 plan-review 的 skill 改了 description，測它會不會自己被叫的完整指令
- 每臂交回：答案、每個做法引出處的原句與檔案路徑（一字不差）、context 裡有哪些 CLAUDE.md（路徑加第一行）、依序 Read 了哪些檔
- 判定：引的原句（去掉換行與行首的 `>` 後）在 `docs/measurements/CLAUDE.md` 找得到，而且是指定的那一條 —— ①「測 skill 會不會自己叫」裡的指令與費用 ②「已知的坑」講 auto mode 的那一條 ③「測 skill 會不會自己叫」裡講會叫 `plan-review` 的 skill 的那一句。對不上先讀原檔那一段再判
- 原句本身不寫在這裡（寫進 repo 等於把答案放到 agent grep 得到的地方），臂回來之後才補
- 三臂都拿到 → 只能寫「全新 agent 從這個 repo 拿得到搬走的內容（每臂 n=1）」，並照實寫它是照根目錄的指路去讀、還是自己搜到的；context 裡沒有根目錄 CLAUDE.md 的臂沒測到指路。**這不證明主對話做到那一步時會主動去讀**
- 有臂沒拿到 → 讀它的 Read 順序，改指路句的位置後重跑那一臂一次；還是沒拿到就停下回報

步驟 4 的修正（2026-11-16，逐條在 `docs/reviews/2026-11-15-audit-fixes/S6-{a,b,c,judge}.md`）：

- 「量測前先關掉 advisor」原本跟著 Agent 第 5 步搬進「量 agent 指令本體」一節，三個審查者都指出做 skill 觸發測試或一般實驗的人照指路走讀不到它 → 移到新檔「已知的坑」的第一條；根目錄三句指路改成「Read 整份」並點名它
- 「新增 Skill 步驟」第 6 步（測 hook 擋不擋）靠的指令底稿在搬走的第 5 步 → 第 6 步加一句指路。這一步本身沒有搬，仍照 plan-review 駁回的那條
- 搬到架構文件的三段不在根目錄的巡檢清單 → 補進「CI 不驗、只能手動同步的區塊」那條；三段前各加一句銜接句（跟同一節既有的哪一段講同一件事、要一起改）。兩段並存、不合併的決定不變
- CHANGELOG 的 45,731 是「刪掉進度指路句之後才會有」的數字，當時寫成量到的 → 改成最終版實際的大小並寫明量的是哪一版
- 新檔開頭兩句不準（有實驗拆成兩個目錄、第一層的 `.md` 不都是彙整）→ 照 `ls docs/measurements` 的結果改寫

步驟 5 乾跑的結果（2026-11-16，三臂都在步驟 4 的修正之前派出，讀的是 `69f0e65`）：

- 三臂的答案都引到 `docs/measurements/CLAUDE.md` 指定的那一條，引的原句對得上：①「測 skill 會不會自己叫」的指令、判定與「每次約 US$0.4–1.6」那句 ②「已知的坑」講 auto mode 的那一條 ③「測 skill 會不會自己叫」裡「測會叫 `plan-review` 的 skill 時，`--allowedTools` 加 `Agent`…」那一句
- **但這三臂沒測到指路**：三臂都回報開始時 context 裡的根目錄 CLAUDE.md 是舊版（搬走的內容還在裡面、沒有指路句）。同一個對話派出的 subagent 帶的是對話開始時載入的那一份，不是磁碟上改過的。三臂去讀新檔的線索都是 gitStatus 裡 `2b23dd9` 的 commit 標題（標題寫了新檔的路徑）
- 所以這三臂只證明：新檔裡找得到搬走的內容、引文逐字對得上。指路有沒有用改用下面的做法測
- 兩臂另外指出「測 skill 會不會自己叫」一節沒寫要不要關 advisor（那句當時在另一節）—— 跟步驟 4 的第一條修正是同一件事

步驟 5 補測：全新 session 測指路（判定在這裡先寫死，這個 commit 之後才跑）：

- 受測目錄：`git archive HEAD` 解到暫存區的快照。不是 git repo（沒有 gitStatus 的 commit 標題），路徑不同所以也沒有這個專案的 memory。快照拿掉會直接點名新檔的三處：`docs/designs/`、`docs/reviews/`、`CHANGELOG.md`；根目錄 CLAUDE.md 用拿掉進度指路句的版本（標 `DONE` 之後的樣子，由核對腳本的同一份清單組出來）。其餘的檔不動
- 指令：旗標照 `docs/measurements/CLAUDE.md`「測 skill 會不會自己叫」，差別是 `--allowedTools "Read Glob Grep"`（這次不是測 skill 觸發，不放 Skill），另加「已知的坑」的 `--settings '{"advisorModel":""}'`。不用先部署：測的是專案的根目錄 CLAUDE.md 與 repo 裡的檔，不是 `~/.claude/` 的部署內容
- 三題各 1 發，題目都不提新檔與節名：Q1 調整了 dd-loop 這個 skill 的 description，怎麼確認它還會不會被自動叫到 Q2 要確認 gate-guard 的 PreToolUse hook 擋得住 `git commit --no-verify`，用什麼指令開全新 session 測、怎麼判定 Q3 調整了 `agents/code-reviewer.md` 的指令本體，怎麼量有沒有變好、開跑前要注意什麼。Q1、Q2 是審查者 A 點名的兩個漏讀情境
- 判定（每發，看最後的答案文字有沒有這些字串；它們在快照的根目錄 CLAUDE.md 都是 0 次、新檔才有，`grep -cF` 核過）：Q1 `dontAsk`、`Launching skill`、`advisorModel`；Q2 `dontAsk`、`no-session-persistence`；Q3 `duration_api_ms`、`advisorModel`
- 另外記錄、不算過不過：第一次碰到 `docs/measurements/CLAUDE.md` 之前跑過哪些工具（第一個工具就是 Read 那個檔 = 路徑只可能來自根目錄 CLAUDE.md；先 Grep／Glob 才找到 = 可能是搜到的）；`permission_denials`（全域 CLAUDE.md §7 可能讓它想叫 Skill 而被擋）；`modelUsage` 的鍵（核 advisor 真的關了）；有沒有工具呼叫指到快照以外的路徑
- 三發都過，只能寫「帶著新版根目錄 CLAUDE.md 的全新 session，被問到這三件事時拿得到搬走的內容（每題 n=1）」。沒有「拿掉指路句」的對照臂，**不證明是指路句造成的**；**不證明主對話在長對話中途做到那一步時會主動去讀**；受測 session 一讀 `docs/measurements/` 底下的檔，那份 CLAUDE.md 可能當巢狀記憶自動進 context，stream-json 看不出來（新檔「已知的坑」有這一條）
- 有一發沒過 → 讀它的工具順序與答案，改指路句後那一題重跑一次；還是沒過就停下回報

步驟 5 補測的結果（2026-11-16，快照取自 `7e5a1c2`，claude 2.1.325，三發同時跑）：

- 三發都過。答案裡指定字串的次數：Q1 `dontAsk` 2、`Launching skill` 2、`advisorModel` 3；Q2 `dontAsk` 3、`no-session-persistence` 2；Q3 `duration_api_ms` 1、`advisorModel` 1
- 三發的第一個工具呼叫都是 Read `docs/measurements/CLAUDE.md`，之前沒有 Grep／Glob；工具呼叫數是 6、8、2，沒有指到快照以外的路徑
- `permission_denials` 三發都是 0；`modelUsage` 的鍵三發都只有 `claude-fable-5-2`（advisor 沒被叫）；`subtype` 都是 `success`，stderr 都是 0 bytes
- 另外讀過三份答案的指令行：Q1 給的是 `--allowedTools "Skill Read Glob Grep"` 那條，開跑前列了先部署與關 advisor；Q2 把 `Bash` 從 `--disallowedTools` 移到 `--allowedTools`，寫明底稿在新檔「測 skill 會不會自己叫」，判定用 `PreToolUse:Bash hook error` 與 `permission_denials`；Q3 給了 `--agents`、`duration_api_ms` 與關 advisor
- 花費（result 的 `total_cost_usd`）：1.33、1.80、1.22 美元
- 這只證明上面寫死的那一句：帶著新版根目錄 CLAUDE.md 的全新 session，被問到這三件事時拿得到搬走的內容（每題 n=1）。沒有對照臂、不證明是指路句造成的，也不證明主對話在長對話中途會主動去讀
- 三發的 jsonl、題目、抽欄位的腳本都在做這件事的 session 暫存區，沒進 repo（jsonl 的 init 訊息有本機路徑）
- 跑完補核的兩件（判定裡寫的是推論）：三發 init 訊息的 `memory_paths` 都指到快照自己那個路徑的記憶目錄，裡面 0 個檔；快照往上每一層目錄都沒有 `CLAUDE.md`、`CLAUDE.local.md`、`.claude/CLAUDE.md`。init 訊息沒有列出載入了哪幾份 CLAUDE.md 的欄位，「路徑只可能來自根目錄 CLAUDE.md」仍是推論（依據：第一個工具呼叫就是 Read 那個路徑，之前沒有任何搜尋）
- 補測之後根目錄又改了一句（標 `DONE` 後的收尾檢查發現）：「CI 不驗、只能手動同步的區塊」那條新寫的「本檔不再有副本」跟「安裝 / 更新」留著的三條約束矛盾，改成寫明那三條兩邊各一份、要一起改。補測的快照是改這句之前的版本（根目錄 46,319 bytes，改完 46,424）；這句不是指路句，沒有重跑

步驟 7、8（2026-11-16）：

- 步驟 7：候選列給使用者（見 `S6-judge.md`「這一段自己犯的錯」；其中「同一個對話派出的 subagent 帶的是對話開始時那一版 CLAUDE.md，改了 CLAUDE.md 之後不能拿它驗指路」適合放進 `docs/measurements/CLAUDE.md`「已知的坑」）。使用者 2026-11-16 回「加」，那一條寫進「已知的坑」的最後；其餘候選沒有寫
- 步驟 8：範圍照表上的起點 `bf7e654` 算出五份（根目錄 `CLAUDE.md`、`docs/measurements/CLAUDE.md`、`docs/measurements/2026-10-29-adhd-style/CLAUDE.md`、`docs/measurements/2026-10-30-dd-loop-trigger/CLAUDE.md`、`scripts/CLAUDE.md`），用 `claude-md-management:claude-md-improver` 只審這一段改到的地方。實跑核對：指到的節名都在、架構文件「CI 防線」一節最後一段是迴圈步數那段、三條約束句引的字串在安裝腳本與設計文件裡找得到、每個日期目錄都有 CLAUDE.md、收編清單的表格 7 列完整。沒有找到要改的錯，沒有動檔

沒驗證的事：

- 以後用這個 commit 之後的 rev 做快照實驗（`--add-dir` 加進來的那種），快照裡的 `docs/measurements/CLAUDE.md` 會不會被受測 session 當巢狀記憶讀進去、把實驗手法洩給它（審查者 C 列的，要跑對照臂才知道）
- 新檔「已知的坑」的「fixture 有子目錄時」那條寫「`run.sh` …跑 `find "$WORK" -mindepth 2 -name CLAUDE.md -delete`」，`git grep -n 'mindepth 2'` 只命中這一句自己，沒有任何 run.sh 有這行。這是逐字搬來的既有句子，這一段沒有改

步驟 3 不跑 code-simplifier（diff 只有 Markdown）。步驟 4 照樣派 3 個 code-reviewer。要新增的測試：沒有。

### S7 根目錄 CLAUDE.md 大小上限（pre-commit 與 CI 都擋）

來源：2026-11-16 我量了根目錄 `CLAUDE.md` 的大小（`git show <commit>:CLAUDE.md | wc -c`，每列是當天最後一個 commit）：2026-08-31 12,797 → 10-30 42,290 → 11-14 48,844 → 11-15 56,111 → 11-16（S6 之後）46,424 bytes。`2bd0014..HEAD`（HEAD 當時是 `e4ec5cc`）有 68 個 commit 動到它，合計加 19,914；扣掉 S6 搬移的兩個 commit，其餘合計只減 1,786。我提了四種做法，第 1 種是「大小上限，寫成會擋的檢查」，上限誰能調高給了兩個選項：甲 = 數字寫在 repo、調高前先問使用者；乙 = 數字寫在 repo，但檢查讀的是最新發版 tag 那一版的數字。我那則訊息的最後一行是「回『乙 48000』（或『甲』加一個數字；現在是 46,424），我就動手做第 1 項」。使用者回「好」。

假設：

- 使用者的原話只有「好」。乙與 48000 是我的建議，我把「好」讀成接受建議；這是我的解讀，回報時第一行寫明
- 只管根目錄 `CLAUDE.md`。全域模板與各層巢狀 CLAUDE.md 不設上限
- 量的是整個檔的 bytes（含 HTML 註解）
- 這一段不部署任何東西：`scripts/githooks/` 不在 `DD_SCRIPTS`、`tests/` 不部署。不動 `install-dd-pipeline.sh`、`templates/`、兩份 README；不跳 `dd-loop-rev`；不發版；push 由使用者自己做
- 乙在「有一個帶上限檔的 `v*` tag」之後才成立。現在最新的 `v1.6.14` 沒有這個檔。到下一次發版之前：pre-commit 讀 `HEAD` 那一版的上限（同一個 commit 調高沒有用，但先單獨 commit 調高、下一個 commit 再加字就過得去）；CI 讀工作目錄那一份（同一次 push 改得到）。這個缺口不再往下補，每次取上限都印出取自哪裡，回報時照實講
- 根目錄 `CLAUDE.md` 不新增任何永久內容。開工時照進度表規則加回的指路句（130 bytes，含後面的空行），在標 DONE 的那個 commit 刪掉；刪完 `wc -c CLAUDE.md` 要回到 46,424。這一段的說明與步驟 7 的教訓都寫進巢狀檔（`scripts/githooks/CLAUDE.md`、`tests/CLAUDE.md`）或架構文件
- `SKIP_DOC_CHECK=1` 不跳過大小上限（它只跳過 gate）。`git commit --no-verify` 會跳過整支 hook，那種 commit 靠 CI 補擋（push 到 `main` 或開 PR 時才跑）；gate-guard 只擋 Claude 用 `--no-verify`
- hook 只在設了 `core.hooksPath scripts/githooks` 的 clone 生效（這台有設）；沒設的 clone 要等 push 到 `main` 或開 PR、由 CI 擋
- 測試要不要收進 repo 由使用者決定（進度表規則：清單以外的測試先問使用者）。S7-1、S7-2 做完、步驟 3 開始之前用 AskUserQuestion 問，題目裡寫出不收的後果（`--staged` 那條路在 repo 裡沒有回歸測試、CI 的 `bash32` job 驗不到這支腳本、腳本壞了會擋住 commit —— 計畫時寫的是「擋住所有讓根目錄 CLAUDE.md 變大的 commit」，S7-1 在拋棄式 repo 實跑的結果是執行位元沒了或開頭就語法錯時**每一個** commit 都被擋，見 `scripts/githooks/CLAUDE.md`「改這三個檔之前」）；同意才做 S7-3。不管收不收，同一批情境在 S7-1 都會在 scratchpad 的拋棄式 repo 實跑。2026-11-16 S7-2 commit 之後用選單問了，使用者選「收進 repo」

設計：

1. 上限檔 `scripts/githooks/claude-md-max-bytes`（新）：`#` 開頭的說明行，加一行整數。內容：

   ```
   # 根目錄 CLAUDE.md 的大小上限（bytes）。讀它的是 scripts/githooks/claude-md-size.sh。
   # 調高之前先問使用者。有帶這個檔的 v* tag 之後，檢查讀的是最新 tag 那一版：改這裡要等發下一版才生效。
   # 格式：# 開頭的行與空行不算，其餘要剛好一行整數（最多 12 位）。
   48000
   ```

2. 檢查腳本 `scripts/githooks/claude-md-size.sh`（新；`#!/bin/bash`，3.2 相容，不用 `set -e`，執行位元開著）：
   - 用法：`--staged`（pre-commit 用，看 index 那一版）；不帶參數（CI 用，看工作目錄那一份）；其他參數 exit 2
   - 開頭 `cd "$(git rev-parse --show-toplevel)"`，失敗 exit 2
   - 取上限：`tag=$(git tag --list 'v*' --sort=-v:refname | head -1)`（跟 `ci.yml`「CHANGELOG 已發布區塊不可改動」那一步同一個寫法）。那個 tag 有上限檔 → 讀 tag 那一版。沒有（沒有任何 tag，或那個 tag 沒有這個檔）→ `--staged` 依序試 `HEAD` 那一版、index 那一版（`HEAD` 沒有這個檔時才讀 index，所以加進上限檔的那個 commit 自己過得去）；不帶參數讀工作目錄那一份
   - 解析：去掉 `#` 開頭的行與空行之後，要剛好剩一行、整行都是數字、不超過 12 位；否則算不合法。找不到上限檔或不合法都是 exit 1
   - `--staged`：`new` = `git cat-file -s :CLAUDE.md`（index 裡沒有就當 0）；`old` = `git cat-file -s HEAD:CLAUDE.md`（沒有 HEAD 或 HEAD 沒有這個檔就當 0）。`new` 沒有比 `old` 大 → 什麼都不印、exit 0（這次 commit 沒有讓它變大，連上限都不取）。變大 → 取上限，印一行「根目錄 CLAUDE.md `old` → `new` bytes，上限 `limit`（取自 …）」；`new` 大於上限 → 印做法、exit 1；否則 exit 0。上限取不到 → exit 1
   - 不帶參數：`new` = 工作目錄 `CLAUDE.md` 的 bytes（`$(( $(wc -c < CLAUDE.md) ))`，macOS 的 `wc` 輸出前面有空白；沒有這個檔 → exit 1）。取上限，印「✅／❌ 根目錄 CLAUDE.md `new` bytes，上限 `limit`（取自 …）」；`new` 大於上限 → exit 1。另外不管上限取自哪裡，工作目錄那一份上限檔也要解析得出來（它會是下一版的基準），解析不出來 → exit 1；它的值跟取到的上限不同時多印一行「工作目錄的上限檔寫 `n`，發下一版之後才生效」
   - 「取自 …」的固定寫法：`取自 <tag>`；`取自 HEAD：<原因>`；`取自 index：<原因>`；`取自工作目錄：<原因>`。原因兩種：`<tag> 還沒有這個檔，發下一版之後改以 tag 為準`、`還沒有 v* tag`
   - 兩句固定的錯誤：`找不到上限檔 scripts/githooks/claude-md-max-bytes（<原因>）`、`上限檔內容不合法（取自 …）`
   - 擋下時印的做法（四句）：新內容改寫進它在講的那個目錄的 CLAUDE.md 或 `DD_PIPELINE_ARCHITECTURE.md`，根目錄不加；一定要放根目錄，就先把一塊既有的內容原文搬走、根目錄留一句指路；不要為了過關把既有的句子縮短（縮短最容易把條件改掉）；調高上限先問使用者，有帶這個檔的 `v*` tag 之後改了要等發下一版才生效
   - 緊貼全形字的變數一律寫 `${var}`（`scripts/CLAUDE.md`「此層慣例」）

3. `scripts/githooks/pre-commit`：`exec` gate 之前先跑大小檢查，非 0 就不往下。改完是：

   ```bash
   #!/bin/bash
   # claude-dd 自用 pre-commit（dogfood）：先查根目錄 CLAUDE.md 的大小上限，再呼叫 repo 內的 CLAUDE.md gate
   # 啟用（clone 後跑一次）：git config core.hooksPath scripts/githooks
   # 逃生口 SKIP_DOC_CHECK=1 git commit ... 只跳過 gate，不跳過大小上限（見同目錄 CLAUDE.md）
   top=$(git rev-parse --show-toplevel) || exit 1
   "$top/scripts/githooks/claude-md-size.sh" --staged || exit 1
   exec "$top/scripts/check-claude-md.sh"
   ```

4. `.github/workflows/ci.yml`（`lint` job，已有 `fetch-depth: 0`）：
   - ShellCheck 清單加 `scripts/githooks/claude-md-size.sh`，插在 `scripts/githooks/pre-commit \` 的下一行、行尾帶反斜線（清單最後一項沒有反斜線，不接在最後）
   - 新 step「根目錄 CLAUDE.md 大小上限（以最新 v* tag 那一版的上限為準）」：先查有沒有任何 `v*` tag，沒有就印跟「CHANGELOG 已發布區塊不可改動」那一步同一句錯誤、exit 1（腳本自己遇到沒有 tag 會退回工作目錄的上限；在 CI 那代表 checkout 壞了，不能當成「還沒發版」）；再跑 `scripts/githooks/claude-md-size.sh`。`run: |` 裡不用 heredoc

5. 文件（都不是根目錄）：
   - `scripts/githooks/CLAUDE.md`（新；gate 對有程式碼變更的目錄要求同目錄的 CLAUDE.md 一起 staged，`sh` 在 `CODE_EXT` 裡）：這一層的職責、三個檔各做什麼、上限怎麼調高、乙什麼時候才成立、哪些路繞得過（`--no-verify`、沒掛 hook 的 clone、發版前分兩個 commit）、情境與變異對照記在哪
   - `scripts/CLAUDE.md`「關鍵檔案」裡 `githooks/pre-commit` 那一條：補「先跑大小檢查」並指到 `githooks/CLAUDE.md`
   - `DD_PIPELINE_ARCHITECTURE.md`：CI 防線表加一列（加在表格裡面，加完把表格範圍逐行印出來確認每一行都是 `|` 開頭）；同表第一列的「11 支腳本」改 12；「核心工作法」一節「本 repo 自身也掛同一個 gate（dogfood）」那一句補上同一支 hook 還擋大小上限、說明在 `scripts/githooks/CLAUDE.md`
   - `CHANGELOG.md` 的 `## 未發布` → `### Added` 加一條（「CI 新增…」這種條目在已發布的區塊有前例）

擋誤用機制的三個檢查（全域模板 §3.9）：

- 誤用發生的那一刻機制在不在：加字的 commit 在設了 hooksPath 的 clone 會經過 hook；沒設的要等 push 到 `main` 或開 PR。hook 與腳本都在 main，不是只存在某個 branch 的檔。hook 從工作目錄跑，同一個 commit 把腳本改壞就擋不到，這跟其他檢查一樣，diff 看得到
- 基準不取自被稽核的對象：上限取自最新 tag 那一版；有帶上限檔的 tag 之前，pre-commit 取自 `HEAD`、CI 取自工作目錄（上面假設裡的已知缺口）
- 參數白名單：沒有「被包的指令成功才做」的後置動作，不適用
- 既有的痕跡有沒有更強的：`DD_PIPELINE_ARCHITECTURE.md` 的 CI 防線表沒有任何一列管檔案大小

情境（S7-1 在 scratchpad 的拋棄式 repo 實跑；使用者同意的話 S7-3 收進 `tests/test-gate.sh`）。拋棄式 repo 照真 repo 的配置：`scripts/githooks/pre-commit`、`scripts/githooks/claude-md-size.sh`、`scripts/check-claude-md.sh` 從真 repo 複製，`scripts/CLAUDE.md`、`scripts/githooks/CLAUDE.md` 各放一行，`git config core.hooksPath scripts/githooks`。上限用小數字。沒寫「直接跑」的都是真的 `git commit`，經過 `pre-commit`：

- A 還沒有任何 commit、哪裡都沒有上限檔，第一個 commit 就帶根目錄 CLAUDE.md → 擋，訊息是「找不到上限檔」。第一個 commit 不帶它 → 放行；之後新增它（有 HEAD 了、還是沒有上限檔）→ 擋；直接跑不帶參數的模式 → exit 1、「找不到上限檔」
- B 上限檔（100）與 CLAUDE.md（50 bytes）同一個 commit → 放行，印出上限 100、「取自 index：還沒有 v* tag」。直接跑不帶參數的模式 → exit 0、「取自工作目錄：還沒有 v* tag」
- C CLAUDE.md 變 150 → 擋，輸出有 150、100、「取自 HEAD：還沒有 v* tag」、「先問使用者」
- D 把 `v0.0.0` 打在還沒有上限檔的第一個 commit 上，CLAUDE.md 變 150 → 擋，輸出有「v0.0.0 還沒有這個檔」；直接跑不帶參數的模式 → exit 1，印 ❌、150、100、「取自工作目錄：v0.0.0 還沒有這個檔」
- E 同一個 commit 把上限檔改成 200、CLAUDE.md 變 150 → 擋（`HEAD` 那一版還是 100）。先單獨 commit 上限檔 200、下一個 commit CLAUDE.md 才變 150 → 放行（發版前的已知缺口；寫成情境是為了這個行為變了看得到）
- F 打 `v0.0.1`（上限檔 200）；同一個 commit 把上限檔改成 300、CLAUDE.md 變 250 → 擋，輸出有「取自 v0.0.1」與 200
- G 只 commit 上限檔 300、CLAUDE.md 不動 → 放行，大小檢查什麼都不印。下一個 commit CLAUDE.md 變 250 → 照擋，上限還是 `v0.0.1` 的 200（乙的核心：調高要等發版）
- H 打 `v0.0.2`；CLAUDE.md 剛好 300 bytes → 放行，直接跑不帶參數的模式也通過；301 → 擋
- I 只 commit 上限檔 400、打 `v0.0.10`；CLAUDE.md 300 → 350 → 放行，輸出有「取自 v0.0.10」與 400（照字典序倒排會選到 `v0.0.2` 的 300 而擋下）
- J index 裡把上限檔刪掉、CLAUDE.md 變 450 → 照 `v0.0.10` 的 400 擋下
- K 只 commit 上限檔 120、打 `v0.0.12`（CLAUDE.md 350，超過上限）；350 → 340 → 放行、不印；340 → 345 → 擋；直接跑不帶參數的模式 → exit 1，印 ❌、340、120
- L index 與工作目錄不一樣：index 是變小的版本、工作目錄是更大的 → 放行；index 是變大的版本、工作目錄改回小的 → 擋
- M `SKIP_DOC_CHECK=1` 加上讓它變大的 commit → 照擋
- N `git commit -am` 讓它變大 → 擋；`git commit CLAUDE.md -m …`（指定路徑）讓它變大 → 擋；變大的 CLAUDE.md 已經 `git add`、但指定路徑只 commit 別的檔 → 放行，而且 CLAUDE.md 還留在 index 沒被 commit
- O 直接跑不帶參數的模式：CLAUDE.md 縮到上限以內並 commit → exit 0、印 ✅、「取自 v0.0.12」；從子目錄跑 → 量的還是根目錄那一份；工作目錄沒有 CLAUDE.md → exit 1；工作目錄的上限檔改成別的數字 → exit 0、多印「發下一版之後才生效」；改成不合法（`abc`、兩行數字、30 位數）或刪掉 → exit 1
- P 最新 tag 的上限檔不合法（上限檔改成 `abc` 並 commit、打 `v0.0.13`）：CLAUDE.md 變大 → 擋，訊息是「上限檔內容不合法」；只改別的檔 → 放行；直接跑不帶參數的模式 → exit 1
- Q 經過 hook 之後 gate 還是有跑到：新增 `scripts/x.sh`、不附 `scripts/CLAUDE.md` → 擋，輸出有 gate 的「commit 已擋下」
- R 不認得的參數 → exit 2

變異對照（先存下原版每一則情境的完整輸出，變異版跟它不一樣就算紅；逐個看不一樣的原因是被測的腳本給了錯的結果，不是載入失敗。記「哪個變異 → 哪幾則不一樣」，不記紅數；每個變異跑完還原、`cmp` 確認與原檔相同）：

- 拿掉 `--sort=-v:refname`（不排序時 `head -1` 我預期拿到 `v0.0.0`，它沒有上限檔，會退回 `HEAD`；實跑確認）→ F 的輸出、G 的第二則至少這兩則不一樣
- 改成 `--sort=-refname`（字典序倒排）→ I 不一樣
- 拿掉讀 tag 的那條分支 → G 的第二則、J 不一樣
- 拿掉 `HEAD` 那一層（tag 沒有就直接讀 index）→ E 的第一則不一樣
- 「沒有變大就離開」改成「大小相等才離開」→ K 的「350 → 340」不一樣
- `--staged` 的大小改讀工作目錄 → L 的兩則不一樣
- 拿掉整數檢查 → O、P 的不合法那幾則不一樣
- 找不到上限檔時改成放行 → A 不一樣
- 「大於」改成「大於等於」→ H 的「剛好 300」不一樣
- 不帶參數的模式不驗工作目錄的上限檔 → O 的不合法那幾則不一樣
- `pre-commit` 拿掉呼叫大小檢查的那一行，或拿掉它後面的 `|| exit 1` → 大小那幾則「擋」的都不一樣，Q 一樣

S7-1 實跑的結果（2026-11-16）：上面每個變異都有情境不一樣，直接不一樣的是哪幾則、哪些只是連鎖，記在 `scripts/githooks/CLAUDE.md`「情境與變異對照」。跟上面的預期不一樣的地方：

- 「`--staged` 的大小改讀工作目錄」在 A 的「第一個 commit 不帶 CLAUDE.md」就把它擋下、情境腳本接著中止，跑不到 L。改成只在 L 打開這個變異，才看得到 L 的兩則各自不一樣
- 「拿掉讀 tag 的那條分支」最先不一樣的是 F 的「取自 v0.0.1」與 G 的第二則；J 也不一樣，但那是前面放行之後的連鎖，不算 J 自己的證據
- 「拿掉 `HEAD` 那一層」除了 E 的第一則，C、D 的「取自 HEAD」也不一樣（變成取自 index）
- 「拿掉整數檢查」不一樣的是 O 的 `abc`、兩行數字與 P 的兩則；30 位數那一則是 12 位那一行在擋，另外做了一個變異
- 實作時補的情境：A、D、H 各一則直接跑；O 的「從子目錄跑」「工作目錄沒有 CLAUDE.md」「刪掉上限檔」（已補進上面的清單）
- 實作時補的變異：拿掉 12 位那一行、兩處 `resolve_limit … || exit 1` 各改成 `exit 0`、最後的 `exit $rc` 改 `exit 0`、`--staged` 超過上限時的 `exit 1` 改 `exit 0`、拿掉 `cd`、拿掉「找不到 CLAUDE.md」那一段、`pre-commit` 拿掉 `exec` gate 的那一行
- S7-3 之後另外實跑的一項（2026-11-16，拋棄式 repo、git 2.42.0，上限 100、`main` 的 CLAUDE.md 50 bytes）：`git cherry-pick`、`git merge --no-ff`、`git rebase`、`git revert` 產生的 commit 不經過 pre-commit —— 四種都讓 `HEAD` 的 CLAUDE.md 變成 150 bytes，大小檢查沒有跑到；對照的一般 commit、`git merge --squash` 之後的 `git commit`、`git commit --amend` 都有跑到、被擋下。計畫時「哪些路繞得過」只列了 `--no-verify`、沒掛 hook 的 clone、發版前分兩個 commit，少了這一類；已補進 `scripts/githooks/CLAUDE.md`「繞得過的路」。這一類跟 `--no-verify` 一樣要等 push 時由 CI 擋

小任務：

- **S7-1** 大小檢查腳本、上限檔、hook、說明檔
  - 檔：`scripts/githooks/claude-md-size.sh`（新）、`scripts/githooks/claude-md-max-bytes`（新）、`scripts/githooks/CLAUDE.md`（新）、`scripts/githooks/pre-commit`、`scripts/CLAUDE.md`；同一個 commit 帶開工的改動（進度表這一列、這一節、根目錄的指路句、計畫審查紀錄）
  - 順序：先寫情境腳本（scratchpad），大小檢查先放一個一律 exit 0 的空殼，確認該擋的情境是因為「沒擋」而紅；再寫腳本到情境全過、跑變異對照。真的 `scripts/githooks/pre-commit` 最後才改 —— hook 從工作目錄跑，腳本有 bug 會擋住自己的 commit，而 `--no-verify` 不能用
  - 驗證：情境 A–R 每一則符合預期（輸出連同中間印的大小與上限一起留在 scratchpad）；變異對照；`shellcheck -S warning scripts/githooks/claude-md-size.sh scripts/githooks/pre-commit`；情境腳本用 `/bin/bash`（3.2）跑；真 repo 上直接跑 `scripts/githooks/claude-md-size.sh` → exit 0、印出「取自工作目錄：v1.6.14 還沒有這個檔」；真 repo 的上限檔臨時改成 40000 → exit 1，還原後 exit 0、`git status --short` 沒有多出改動
  - 3.2 相容：這裡只有開發當下在本機（macOS `/bin/bash` 3.2）跑過。`scripts/CLAUDE.md` 寫「新腳本要有行為測試並加進那個 job，才算有驗 3.2」，所以沒有 S7-3 的話，CI 的 `bash32` job 驗不到這支腳本，要寫進回報
  - commit：`feat: 根目錄 CLAUDE.md 加大小上限，pre-commit 擋下讓它超過上限的 commit（S7-1）`
- **S7-2** CI step 與文件
  - 檔：`.github/workflows/ci.yml`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md`
  - 驗證：`ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")'`；本機照 ci.yml 逐 step 跑全部 rc=0，新 step 的 log 有 ✅ 那一行；負面測試三個，各自還原後回綠：①上限檔臨時改成 40000 → 新 step rc≠0 ②在新腳本臨時加一個 warning 級的問題 → ShellCheck 那一步 rc≠0（證明清單真的有檢查到它）③架構文件的 12 臨時改回 11 → 「數字宣稱一致性」那一步 rc≠0；架構文件 CI 防線表的範圍逐行印出來，每一行都是 `|` 開頭
  - commit：`ci: 新增根目錄 CLAUDE.md 大小上限的檢查，補 CI 防線表（S7-2）`
  - 實跑的結果（2026-11-16）：本機照 ci.yml 逐 step 跑，兩個 job 的每個 step 都 rc=0，新 step 印「✅ 根目錄 CLAUDE.md 46554 bytes，上限 48000（取自工作目錄：v1.6.14 還沒有這個檔，發下一版之後改以 tag 為準）」（46554 含開工加回的指路句）。上面三個負面測試都是 rc=1、還原後 rc=0（還原用備份檔 `cmp` 確認）。另外做了兩個：
    ④ShellCheck 清單拿掉新腳本那一行、同時在腳本種同一個問題 → ShellCheck 那一步照樣 rc=0（清單那一行拿掉就沒人檢查這支腳本），「數字宣稱一致性」那一步 rc=1（宣稱 12、實際 11）；
    ⑤沒帶 tag 的淺 clone（`git clone --no-tags --depth 1`）裡跑新 step → rc=1、印「找不到任何 v* tag」；同一個 clone 直接跑腳本 → rc=0、「取自工作目錄：還沒有 v* tag」（step 開頭那道檢查擋的就是這個）；clone 裡補一個 tag 之後新 step rc=0。
    ubuntu:24.04 容器（bash 5.2.21、git 2.43.0）跑同一批情境，每一則的輸出與 macOS `/bin/bash` 存下的相同；容器裡真 repo 直接跑腳本 rc=0
- **S7-3**（使用者 2026-11-16 選了「收進 repo」）情境收進 `tests/test-gate.sh`
  - 檔：`tests/test-gate.sh`、`tests/CLAUDE.md`、`DD_PIPELINE_ARCHITECTURE.md`（CI 防線表「gate 情境測試」那一列補一句）
  - 內容：在檔尾 `exit $fail` 之前加一節，另開一個拋棄式 repo、照上面的配置放真的 `scripts/githooks/pre-commit`，跑情境 A–R；沿用檔裡的 `expect`、`said`、`not_said`。第二、三個參數可以換成別的大小檢查腳本與 `pre-commit` 的路徑（做變異用），不給就取 repo 裡那一份。這支測試本來就在 `lint` 與 `bash32` 兩個 job 各跑一次，不用另外接 CI
  - 驗證：`/bin/bash tests/test-gate.sh` rc=0、新情境都是 ✅、原有情境的 ✅ 一則不少（改之前先記下原有的 ✅ 行，改之後比對）；變異對照同上；ubuntu:24.04 容器跑一次
  - commit：`test: 根目錄 CLAUDE.md 大小上限的情境測試（S7-3）`
  - 實跑的結果（2026-11-16）：情境成為 `tests/test-gate.sh` 的 ⑯，說明以「⑯ A」…「⑯ R」開頭。`/bin/bash`（3.2.57）與 ubuntu:24.04 容器（bash 5.2.21）都 rc=0；改之前存下的輸出逐行等於改之後輸出的開頭（原有情境一則不少），新增的 ✅ 行去掉「⑯ 」之後與 S7-1 情境腳本的 ✅ 行相同。
    變異對照改在測試層級重跑（變異版當第二或第三個參數）：每個變異都 rc=1，⑯ 之前的輸出都沒有變，變 ❌ 的情境與 S7-1 那次情境腳本變 ❌ 的集合相同；`scripts/githooks/CLAUDE.md` 的對照表改成記「哪幾則變 ❌」。
    跟 S7-1 的表不一樣的兩處：「大小相等才離開」的 O「縮到 100 並 commit」、「`--staged` 大於改成大於等於」的 H「301」只是輸出不同，沒有斷言在看，不會紅（各自另有直接變紅的情境）。
    搬進來時改的一處：A 建第一個 commit 之後取 `HEAD` 那一行原本裸跑，建不起來時 `set -e` 靜靜結束；改成印一行 ❌ 再結束
    更正：commit `d0e72b1` 的訊息寫「本機照 ci.yml 逐 step 跑全部 rc=0」，不對。那次有一步是 rc=1（「迴圈步數第五方」：`tests/CLAUDE.md` 的 `test-gate.sh` 那一列原本就有兩個箭頭、也有 commit 與 review 這兩個字，我加的說明又帶一個箭頭，湊滿三個就被當成迴圈的箭頭摘要）。彙總印了「rc 不是 0 的 step 數：1」，我沒有先看就接著 commit。下一個 commit 把那個箭頭改成文字，整份重跑全部 rc=0

要新增的測試（2026-11-16 用選單問，使用者選「收進 repo」；已補進下面測試清單的第 6 條）：`tests/test-gate.sh`（S7-3）上面情境 A–R，經過真的 `scripts/githooks/pre-commit`。

步驟 3–8 照進度表規則對整段跑（範圍從 `e4ec5cc` 算）；步驟 4 的報告放 `docs/reviews/2026-11-15-audit-fixes/S7-*.md`（寫之前先 `ls`）。步驟 7 有教訓的話寫進巢狀檔，不寫根目錄。

步驟 3 的結果（2026-11-16）：code-simplifier 的範圍是 `scripts/githooks/claude-md-size.sh` 與 `scripts/githooks/pre-commit`（包裝器的預設不含測試檔），它沒有改任何檔（兩支腳本與派工前的備份 `cmp` 相同）。

步驟 4 的結果（2026-11-16，4 個審查者，逐條處置在 `docs/reviews/2026-11-15-audit-fixes/S7-judge.md`）：沒有 Critical。採納的都改在說明、註解與一句錯誤訊息，大小檢查的判斷邏輯沒有動。

- 四份報告都指出同一件事：上限取的是「本機版本號最大的 `v*` tag」。調高上限檔的 commit 進去之後，在本機打一個版本號更大的 tag 就生效，不必真的發版；
  `v` 開頭但不是版本號的 tag、打在別條 branch 上的 tag 也算（拋棄式 repo 實跑，結果寫在 `scripts/githooks/CLAUDE.md`「繞得過的路」）。
  這是「乙」這個做法本身的範圍：腳本分不出「發版」與「打了一個 tag」。沒有改取 tag 的寫法 —— 收緊成只認版本號的形狀、或只認 `HEAD` 的祖先，
  都擋不住「調高之後打一個 tag」，還會跟 `ci.yml` 另外兩步的同一個寫法分家。處置是寫進「繞得過的路」，回報時放前面講
- `/dd-init` Phase 3 的位置規則照字面會把這支 hook 判成要搬（讀規則推出來的，沒有實跑 `/dd-init`）；兩行對調的後果有實跑：`tests/test-gate.sh` ⑯ 變紅、本機 commit 沒有訊息。
  處置是在 hook 檔頭與 `scripts/githooks/CLAUDE.md` 寫明順序有承重。根目錄 CLAUDE.md 講 `core.hooksPath` 與 `/dd-init` 的那一句講的是掛載位置，沒有改
- 另外補的實跑（同一天、git 2.42.0、拋棄式 repo）：`git am` 不經過 pre-commit；根目錄 CLAUDE.md 換成 symlink 時 `--staged` 量到的是連結字串、放行，不帶參數那一種量到目標的內容；
  `git tag --list` 不排序時是字典序（先打 `v2.0.0`、`v1.9.0`、`v1.10.0`、最後打 `v1.0.0`，`head -1` 是 `v1.0.0`）；bash 5.2.21（ubuntu:24.04 容器）比前導 0 與 12 位數的結果跟 3.2.57 相同
- 審查者 B 實跑找到 ⑯ 抓不到的三個變異（不帶參數時改讀 `HEAD` 的上限檔、取 tag 時拿掉 `'v*'`、不在 git repo 裡時回 0），我重跑確認。
  補情境是測試清單以外的測試，照進度表規則要先問使用者；問之前先記在 `scripts/githooks/CLAUDE.md`「⑯ 抓不到的變異」

步驟 5 的結果（2026-11-16，步驟 4 的修正都做完、還沒 commit 的工作目錄）：

- `/bin/bash tests/test-gate.sh`（3.2.57）：rc=0、沒有 ❌；ubuntu:24.04 容器（bash 5.2.21、git 2.43.0）：rc=0、沒有 ❌
- `shellcheck -S warning`（兩支腳本與 `tests/test-gate.sh`）：rc=0
- 變異對照：照改過的腳本重出全部變異檔、每個變異重跑整份測試，變 ❌ 的集合都與步驟 4 之前那一次相同；固定版沒有 ❌
- 本機照 ci.yml 逐 step 跑：兩個 job 的每個 step 都 rc=0（跑的腳本在有 step 沒過時會回非 0，這次回 0）
- 真 repo 直接跑 `scripts/githooks/claude-md-size.sh`：印 ✅、46554 bytes、上限 48000、「取自工作目錄：v1.6.14 還沒有這個檔，發下一版之後改以 tag 為準」，rc=0

步驟 6（2026-11-16）：`7dd3d25`（審查修正與五份報告）。

步驟 7（2026-11-16，`dd803d3`）：三條寫進巢狀 CLAUDE.md，根目錄沒有加字 —— `tests/CLAUDE.md` 兩條（表格列別用箭頭符號，CI「迴圈步數第五方」會把它當成迴圈摘要；
拿 gate 的變異版看 ⑯ 之前先確認 ⑯ 有跑到）、`scripts/githooks/CLAUDE.md` 一條（「繞得過的路」是唯一一份清單，另外三處只舉例並指到它）。

步驟 8（2026-11-16）：範圍照表上的起點算出四份（根目錄 `CLAUDE.md`、`scripts/CLAUDE.md`、`scripts/githooks/CLAUDE.md`、`tests/CLAUDE.md`），用 `claude-md-improver` 只審這四份。
`scripts/githooks/CLAUDE.md` 在步驟 4 之後才改的句子逐句對程式碼，沒實跑過的在拋棄式 repo 補跑（工作目錄的上限檔改了沒 commit 就算數；上限檔三種改壞法直接跑都不通過、只改上限檔的 commit 都放行；
不帶 `'v*'` 時 `wip-x` 排第一、`pre-prune-2026-08-04` 排在 `v…` 後面）。改了兩句：「⑯ 抓不到的變異」第一條原本寫「⑯ 每次直接跑的時候」，實際走到那條分支的直接跑只有 B、D 兩則；
「本機打一個 `v*` tag」那條的「CI 也照它算」是照 `ci.yml` 推的、沒有 push 驗過，補上標註。另外三份這一段改到的地方沒有與實際不符的。

**最後一個決定（2026-11-16 問，使用者選「不補」）**：要不要補清單以外的測試（照進度表規則要先問）。題目有兩組：

- ⑯ 抓不到的三個變異各補一則情境。先對過：這三個變異今天會不會讓 pre-commit（`--staged`）或 CI（不帶參數）的結果不同 ——
  - 不帶參數時改讀 `HEAD` 的上限檔：不會。`--staged` 不走那一支（`resolve_limit()` 裡 `[ "$1" = worktree ]` 那一支）；CI checkout 出來的工作目錄與 `HEAD` 相同（推論，沒有在 CI 上驗）。
    只有本機改了上限檔、沒 commit 就直接跑時才不同（步驟 8 實跑：`HEAD` 是 100、工作目錄改成 1000，500 bytes 的 CLAUDE.md 照 1000 通過）
  - 取 tag 時拿掉 `'v*'`：今天不會。真 repo 帶不帶都選到 `v1.6.14`（步驟 8 實跑）；要有名字排在 `v` 後面的 tag 才不同（實跑：`wip-x`）
  - 不在 git repo 裡回 0 而不是 2：不會。hook 與 CI 都在 repo 裡跑（推論）
- 審查者 B 另外建議的特性測試，釘住兩條已知繞得過的路：別條 branch 上的 `v*` tag 也算、不是版本號形狀的 `v` 開頭 tag 也算。
  它們不擋任何東西；作用是哪天取 tag 的寫法改了，測試會紅、提醒回頭改 `scripts/githooks/CLAUDE.md`「繞得過的路」

給使用者三個選項：不補／補那三則／補那三則加兩則特性測試。建議第一個，依據是上面三條都寫不出一條今天會讓 hook 或 CI 結果不同的路。
結果：使用者選「不補」。沒有加測試；三個缺口照樣記在 `scripts/githooks/CLAUDE.md` 檔尾「⑯ 抓不到的變異」，兩條繞得過的路也沒有特性測試。
之後要補的話是一個帶程式碼的新段落（進度表加一列，步驟 3–8 整圈），不是回頭改 S7。

### 測試清單（使用者 2026-11-15 選定「照這份清單加」）

1. `tests/test-gate.sh` ⑬（S1-1）：`dd.docfile` 設 `main.py`、`notes.sh` 要拒絕，`AGENTS.txt` 照常（對照）
2. `tests/test-gate.sh`（S1-2）：amend 掉起點後 `--segment-base` 失敗、不印任何起點、訊息含共同祖先、不再叫人重記；從沒記過起點時照舊叫人先記（對照）
3. `tests/test-gate.sh`（S1-2）：連共同祖先都沒有時（孤兒分支）訊息叫人用進度表的起點或問使用者
4. `tests/test-gate.sh`（S1-3）：上一段沒報告被擋時訊息列出 BLOCKED 申報檔；commit 了 `S1-BLOCKED.md` 之後開下一段放行
5. `tests/test-install.sh` T11（S3-1）：`--check` 對改過的已部署 skill 與 agent 印「與 repo 不同」、沒改的不印、不寫任何檔、結束碼 0
6. `tests/test-gate.sh` ⑯（S7-3；這一條是 2026-11-16 另外問的，使用者選「收進 repo」）：根目錄 CLAUDE.md 大小上限的情境 A–R（內容見上面 S7 一節），在拋棄式 repo 裡經過真的 `scripts/githooks/pre-commit`

## 計畫審查紀錄

`plan-review` 第 1 輪：通過。4 個審查者（前提／漏掉的同步點／範圍與驗證／全面），讀檔檢查都過，沒有重派。

採納的小事（12 條，都已改進上面的計畫）：S4-2 是行為改變、要寫明 Scope 從 3 降為 2；S4-1 的 grep 驗收會命中出處連結與 `clawhub publish`；模板 `<起點>` 那句在蓋章區塊有副本、不改；S2-2 的乾跑要給「使用者已要求先做 S2」；S1-2 訊息要說範圍會多含一個 commit、乾跑驗收改成比對 sha；「自己指定」改成用進度表或問使用者；原因措辭沿用「換過分支或改寫過歷史」；「找不到共同祖先」那一支要有測試；D2 的取捨要寫明並記進已知繞過；`docs/reviews/CLAUDE.md` 要補 BLOCKED 的格式；D1 要寫出擋不到的類別；`tests/test-install.sh` 的 `TEST_ONLY` 白名單要加 T11。

駁回（7 條）：「S1 會在使用者決定前動手」（D1、D2 本來就列為要問的題）；dd-init Phase 3 寫死檔名（A1 範圍外）；README 沒提 docs/reviews（沒有就不用改）；「起點沒被改」與 `--start-segment` 衝突（指的是進度表 commits 欄）；「重跑安裝會登記並啟用」沒讀碼（已讀碼確認）；不確定 repo 來源路徑變數（`SCRIPT_DIR`）；`gh api` 查上游（已排進開工前提）。

需要外部查證（2 條小事）：Apache-2.0 對改過的衍生檔怎麼標示（A10 已寫明在授權檔標出改過）；部署目錄裡的執行期檔會被 `--check` 報成不同（S3-1 已寫明與安裝本身一致）。

`plan-review`（S5，2026-11-15）第 1 輪：通過。4 個審查者（前提／漏掉的同步點／範圍與驗證／全面），讀檔檢查都過，沒有重派。沒有重大、沒有需使用者決定、沒有需要外部查證。

採納的小事（4 條，都已改進上面的 S5）：A/B 每臂至少 2 發、判定預先寫死（含新臂失敗時停下回報）、新句子點名 agent 定義裡的偏好不算專案標準；B2 的理由寫準（既有的 `deprecated_dd` 迴圈只認 `dd-*.md` 單檔）；T11 寫 `review` 的四行都要換；ci.yml 的新寫法寫死成不用 `xargs`、驗證加「stderr 是空的」。

駁回（6 條）：CI 那一行是可以不做的順手修（沒有子目錄後每次都印錯誤、會被讀成壞了，是刻意改）；`--help` 與 `--uninstall` 會印「0 個命名空間」（計畫明寫照印）；沒安排標 IN_PROGRESS 與記起點（表下方的規則已規定）；一條不是批評；subagent 的 system prompt 與 user 訊息誰優先（A/B 實跑就是在驗這件事）；gate 會因為改 `.github/` 擋 commit（`CODE_EXT` 沒有 yml）。

`plan-review`（S6，2026-11-16）第 1 輪：通過。4 個審查者（前提成不成立／漏掉的同步點／範圍與驗證／全面），讀檔檢查都過，沒有重派。沒有重大、沒有需使用者決定、沒有需要外部查證。用的是 repo 這份 `skills/plan-review/SKILL.md` 的範本與審查包（部署版還是沒有審查包的舊版）。

採納的小事（都已改進上面的 S6）：殘留清理的範圍到檔尾、核對腳本另查圍欄行數與根目錄不含那一節；迴圈步數那條插在「CI 防線」一節最後、不拆開表格與表後的引用塊；gate 段與架構文件既有的段落並存要寫明；「會寫新字的地方」不寫種類數；乾跑移到步驟 5、引文比對前去掉行首的 `>`；新檔的出處註記不寫條數；「核心工作法」多留一段的理由；根目錄「CI 不驗」那條補四方與第五方的定義在哪、清單加上 README 的「清理外部殘留」。

駁回：「新增 Skill 步驟」第 6 步與「同一則訊息裡派的幾個 subagent」起的那幾條也該搬（使用者決定的範圍沒有它們）；`runci.rb` 沒跑 `bash32` job（讀過，兩個 job 都跑）；README「前置需求」要同步（這次沒動到那條規則）；乾跑只證明 repo 裡找得到（計畫已寫明它不證明什麼）；新檔不在 `git ls-files`（S6-1 就 commit 了）；刪掉箭頭圖後步驟沒有編號可對照（編號由全域 §3.9 定義）；GitHub 預設 shell 帶 pipefail（沒寫 `shell:` 時不帶，而且這段不動 ci.yml）；「明寫先 Read」沒有實測（不是批評，計畫已寫明）。

`plan-review`（S7，2026-11-16）第 1 輪：通過。4 個審查者（前提成不成立／漏掉的同步點／範圍與驗證／全面），讀檔檢查都過，沒有重派。沒有重大、沒有需使用者決定。用的是 repo 這份 `skills/plan-review/SKILL.md` 的範本與審查包（部署版與 repo 不同）。

採納的小事（都已改進上面的 S7）：發版前 `--staged` 的上限改成依序讀 tag、`HEAD`、index（原本直接讀 index，同一個 commit 調高就過得去）；「取自 …」與兩句錯誤訊息寫成固定字串；拿掉 `--sort=-v:refname` 那個變異的機制寫錯了（不排序時拿到的是最舊的 tag，不是 `v0.0.2`）、它也會讓 F 不一樣；變異對照改成跟原版的完整輸出比，不斷言「某一則要紅」；「沒有逃生口」改成寫明 `--no-verify` 會跳過整支 hook、靠 CI 補擋；問使用者測試那一題要寫出不收的後果；不帶參數的模式取大小時去掉 `wc` 輸出前面的空白；補「還沒有任何 commit」與「tag 有上限檔、index 刪掉上限檔」兩則情境。

駁回：「好」被讀成「乙 48000」（原訊息最後一行就是在問這個、計畫已寫明是解讀、回報第一行會講）；加 S7 這一列與加回指路句沒有規則依據（使用者同意做這項工作；表上有不是 DONE 的列就該有指路句）；要巡 README 的「CLAUDE.md 維護規則」（gate 本身沒改，改的是本 repo 自用、不部署的 hook）；hook 對「變小但仍超過上限」放行而 CI 擋下（刻意的，CI 比較嚴）；上限檔沒有執行位元的情境（要開執行位元的是腳本；沒開時 hook 會直接報錯）。

需要外部查證（2 條小事）：`git commit -a` 與指定路徑的 commit 時 hook 裡 `git cat-file -s :CLAUDE.md` 讀到的是不是要 commit 的那一版（改成情境 N 實測）；bash 3.2 下的行為（S7-1 用 `/bin/bash` 跑情境；CI 驗不驗得到看 S7-3）。
