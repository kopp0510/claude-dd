# 收編 security-audit 與 dd-init 寫檔不跟 symlink

使用者評估 cloudflare/security-audit-skill 之後選了「先付費試跑」，試跑（`docs/measurements/2026-11-14-security-audit-trial/`）在 claude-dd 自己身上找到一筆 `needs_validation`：
`scripts/dd-init-upgrade.sh --apply` 的輸出路徑事先是 symlink 時，awk 會跟著它寫到專案外。使用者接著選「A，兩件事都做」：正式收編這個 skill，並修掉這筆。

## 來源

- 使用者決定（對話中講定）：
  - U1：正式收編 security-audit，修試跑找到的 symlink 寫出，試跑報告複製到 `~/security-audit-skill/claude-dd/run-1/`（已完成）
  - U2：先付費試跑再決定收不收（已完成）
  - U3：push 由使用者自己按，只做到本機 commit
  - U4：claude-dd 是公開 repo，未修的弱點細節不進 repo
  - U5：S2 的乾跑用「只讀乾跑」（每條分支一個 subagent，寫檔的步驟引用試跑）
  - U6：`/dd-init` Phase 2 的 symlink 寫入點併進 S1 一起修
  - U7：S1-3 保留擴大到 Phase 1、Phase 3，含 docker 真工具實測
  - U8：計畫審查第 3 輪後選「跑確認輪」
  - 決策題 Q1：`--apply` 的輸出路徑已存在時拒絕寫出、exit 6（建議答案）
  - 測試清單題：照「要新增的測試清單」加
- 上游：`cloudflare/security-audit-skill` commit `c1c8a8c`（MIT，Copyright (c) 2025-2026 Cloudflare, Inc.）
- 計畫審查（plan-review）：審了 1、2、3 輪與確認輪 3C，每輪派的審查者：輪 1 五個、輪 2 六個、輪 3 六個、輪 3C 六個。第 3 輪不通過（2 條重大），兩條改進後由確認輪審過、通過；確認輪採納的 21 條小事照 plan-review 第 4 步直接改進，沒有再送審

## 假設

- A1：S1-1 的修法是「輸出路徑已存在（一般檔、目錄、symlink、懸空 symlink）就 exit 6、不寫」，不改成「寫暫存檔再 mv 取代」（決策題 Q1，使用者選了這個）
- A2：腳本層：TARGET（`CLAUDE.md` 本身）是 symlink 時 `dd-init-upgrade.sh` 只讀它，不在 S1-1 範圍；`/dd-init` 層：`CLAUDE.md` 是 symlink 時，建立（Write）、補充（Edit）對連結本身的路徑會被工具拒絕（見 A21 ①），但工具建議改寫連結目標的路徑，照做、或改用 `>>`、heredoc，就寫到連結目標，升級的 `--plan`／`--apply` 跟著連結讀、第 8 步 `mv` 會用一般檔取代連結本身（rename 取代的是目錄項目，不寫穿；但會拆掉 `CLAUDE.md` → `AGENTS.md` 這類連結，連結目標的內容也會在 Phase 5 進 repo）。三種模式都由 S1-3 在 Phase 1 判斷模式之前的 `[ -L CLAUDE.md ]` 檢查處理
- A3：檢查與寫檔之間的 TOCTOU 不處理：威脅是「clone 帶進來的 symlink」，事先存在、不是並行建立
- A4：`commands/dd-init.md` 要改的地方（Phase 1 第 6 步、Phase 1 之前新加的寫檔前檢查、Phase 2 的指令區塊、Phase 3 的掛載點）都在蓋章區塊外（區塊用 ``grep -n '^```' commands/dd-init.md | head -2`` 夾出），不跳 `dd-loop-rev`
- A5：security-audit 的上游文字不改，只加兩處：frontmatter `name:` 下一行加 `disable-model-invocation: true`；frontmatter 結束的 `---` 後加一行 vendored 說明，寫法照 `skills/writing-great-skills/SKILL.md` 裡 `> Vendored from` 開頭那行（用字串定位，不寫行號）
- A6：「新增 Skill 步驟」第 3 步的乾跑照使用者選的做法（U5）：分支用封閉式判準列出 ——「SKILL.md 裡會改變寫不寫檔、派不派 agent、要不要停下來問的條件句」—— 逐條標「乾跑」「試跑已實跑」或「不另跑＋理由」（清單見 S2-1 做法第 2 步），標「乾跑」的每條各派一個 subagent。寫檔那部分：只有 quick 的寫檔流程實跑過；檔案組與兩支驗證器各 profile 相同（依據 SKILL.md 的 shared run files 清單、「Profiles change breadth and redundancy, never the evidence bar」、Phase 4 的 Structured output）；standard／deep／scoped 特有的寫檔步驟（多一個 final-clean critic、deep 的雙驗證者、scoped 的 `out_of_scope`）沒實跑，照實寫進 `skills/security-audit/CLAUDE.md`。有分支因此不能用 → 停下回報使用者
- A7：部署（`./install-dd-pipeline.sh --force`）算在使用者「A，兩件事都做」（正式收編）的授權內；專案 CLAUDE.md「新增 Skill 步驟」第 4 步明寫要部署；安裝腳本覆蓋前先備份
- A8：skill 目錄裡上游的兩支 `*.test.cjs` 不加進 CI（Node 雖是安裝腳本的必要依賴，但加 CI step 屬擴大範圍）；S2-1 驗證時本機手動跑。`install_builtin_skills()` 用 `cp -r` 整個目錄，所以 `CLAUDE.md`、`LICENSE.txt`、`*.test.cjs` 都會部署到 `~/.claude/skills/security-audit/`（前例：`skills/self-improving-agent/CLAUDE.md` 也照這樣部署）
- A9：`agents/security-auditor.md` 的 description「不適用於自動化全面掃描、SecOps 管線建置或威脅建模(不在部署範圍)」收編後「全面稽核」有了 `/security-audit`，在 S2-2 改成指過去；agent 本文「不做自動化全面掃描」講的是 agent 自己，不改
- A10：README「指令一覽」不加 `/security-audit`：前例 `writing-great-skills`（同為 user-invoked）也沒列；在 Promoted Skills 表格那列寫明用 `/security-audit` 叫
- A11：S2 步驟 5 的 `claude -p` 觸發實測，結果放新目錄 `docs/measurements/2026-11-14-security-audit-trigger/`（prompt、check.sh、results.txt、CLAUDE.md；只抽判定欄位，原始 jsonl 不進 repo），由步驟 6 的 commit 送；試跑那個目錄的 `results.txt` 不重跑覆蓋
- A12：收編清單逐項結論：#1 MIT（Cloudflare），放 `LICENSE.txt`，上游 frontmatter 沒有 license 欄位；#2 上游沒有 hooks；#3 試跑實跑（quick，輸出目錄是 prompt 指定的，見試跑 `real.prompt.txt`）＋兩支驗證器 65 則測試；「路徑算式、目錄命名」要實跑對照，所以預設輸出路徑 `~/security-audit-skill/<repo-name>/run-<N>` 另外在 S2 步驟 5 用 `claude -p` 實跑一次對照（D5b）；#4 Node 本來就是安裝腳本的必要依賴（README 前置需求段：Claude Code CLI、Node.js、Git、Bash 缺一安裝中止），不新增 runtime；#5 `grep` 過沒有 `~/.claude`、`$<數字>`，預設輸出路徑在 target 外；#6 skill `security-audit` 與 agent `security-auditor` 名稱不同、不撞，功能互補（全面稽核 vs 逐項手動審查），處置是 A9 的指路；skill `review`（description「跨維度綜合審查包裝器，調用 workflow-review 命令同時執行安全+效能+配置審查」）與 `/workflow-review:review` 審的是變更或合併前的多維度審查，security-audit 審整個 codebase 的信任邊界，不重疊；S2 不改 `review`。S2 步驟 5 反向那發若叫起 `review`，另開一個小任務（先問使用者，照進度表規則補條目）：在它的 description 加一句指路、照「新增 Skill 步驟」第 5 步跑兩發觸發重測（該叫的、不該叫的各一），並寫明「只動 description、沒動本文步驟，第 3 步乾跑不另跑」；#7 S2-1 同批納管
- A13：設計文件與根 CLAUDE.md 指路在 task-planner 步驟 5 寫到磁碟，但**不單獨 commit**，跟 S1 的最後一個修正 S1-3 同一個 commit 送 —— 文件裡有三處寫出點的描述，U4 規定修好之前不進 repo。S1-1、S1-2 commit 時只 `git add` 自己的檔。這偏離 task-planner 步驟 5 的完成條件（「`git log -1` 看得到那個 commit」）與「開工標記跟第一個小任務一起送」；形狀同它「還沒有 git repo 時，文件與指路跟第一個小任務一起 commit」那條。驗收：S1-3 之前沒有任何 commit 含這份文件
- A14：會進 repo 的紀錄，寫進去之前先過一次。判準：原文描述了一條能讓寫入落到專案外、而 S1 沒修的路徑。命中時預設處置：在 S1 補一個小任務修掉（照「進度表」規則先問使用者、補小任務條目），再落地；修不了才停下問。要過的有：
  - 本計畫各輪 plan-review 報告留在 scratchpad，不進 repo
  - S1 步驟 4 的審查者原文先存 scratchpad，過完再落地到 `docs/reviews/`（那裡的規矩不准事後改「發現」節）
  - S2 乾跑以 claude-dd 為目標，發現寫進 `skills/security-audit/CLAUDE.md`（會部署）之前
  - S1-3 commit 前的設計文件（含 task-planner 步驟 5 寫進假設的重大現況）
- A15：S1-3 的寫檔前檢查是 `/dd-init` 的文字規則，靠模型照做。驗法：沙盒臂（subagent 照 repo 版 `commands/dd-init.md` 做）測 S1-3 驗證列出的各臂；Phase 3 牽涉 hook 管理工具的分支照根目錄 CLAUDE.md「新增 Command 步驟」用 docker 裝真工具（pre-commit、husky v8、husky v9）實測，每個工具一臂 symlink、一臂不放 symlink 的對照。沒有單獨一臂的、由同一道檢查擋的變體：`.gitignore` 是懸空 symlink（同 B 的 `[ -L ]`，懸空情況由 C2、E 測）、Phase 1 的 6step／7step／手寫版升級（同 D，由判斷模式前那次 `[ -L CLAUDE.md ]` 擋）。lefthook 那條不寫檔，不測
- A16：遇到 symlink 一律「`ls -ld` 給使用者看（S1 步驟 4 的 c-9 從 `ls -l` 改成 `ls -ld`）、問要不要照寫」，不硬擋：有的專案刻意把 `CLAUDE.md` 做成指向 repo 內 `AGENTS.md` 的 symlink。使用者答「照寫」之後，Phase 3 第 5 步既有的「掛載點是 symlink、實際改的是連結目標 → 提醒他 commit」照舊（那句留著、不刪）
- A17：S1-3 的範圍：U6 選的是 Phase 2；Phase 1、Phase 3 是同類掃描補進來的，第 3 輪後使用者選「保留擴大」（U7）
- A18：S1 全部完成（S1-3 commit）之前不 push；交進度時提醒使用者（U3）。S1-1、S1-2 的 commit 訊息與 CHANGELOG 只寫各自已修的那一處
- A19：沙盒臂與 docker 臂的 subagent 用 sonnet（跟乾跑一致；它代表的是「照文字做的模型」，不是使用者實際用的模型，所以宣稱只到「這份文字下 sonnet 會停」）。subagent 沒有可以回答的使用者：`commands/dd-init.md` 要它問使用者的地方，它把問句原文寫進回報，symlink 問句一律當成答「不要」（S1 步驟 4 加的 Y、Y5、YD 例外，答「要」）、其他問句照該臂 prompt 給的答案（照 `docs/measurements/2026-10-30-dd-init-upgrade/run.sh` 的寫法），然後往下做。一臂可以因此走過不只一個寫檔終點
- A20：S1-3 的各臂 fixture 與斷言寫成腳本放 `docs/measurements/2026-11-14-dd-init-symlink/`（`setup.sh` 建 fixture、`check.sh` 用指令核對、`results.txt` 記每臂在舊文字與新文字下的結果、用到的工具版本、CLAUDE.md），跟 S1-3 一起 commit。subagent 的回報原文留 scratchpad，只抽判定要用的句子進 `results.txt`，照根目錄 CLAUDE.md 的去識別規則掃過（`-Users-`、`-private-tmp-`）
- A21（需要外部查證，小事）：①Claude Code 的 Write／Edit 遇到 symlink 是寫穿還是取代連結 —— 已查（S1-3 舊文字基準，Claude Code 2.1.325）：兩個都不寫，拒絕並建議改寫連結目標（「Refusing to write …: it is a symbolic link. Write to the link's target path instead: …」）；指向存在的檔與懸空的連結都拒絕（2026-11-14 主對話另測）。這不是保護：舊文字下 H3 直接對連結目標的路徑用 Edit、G 改用 heredoc，都改到了專案外的檔（`docs/measurements/2026-11-14-dd-init-symlink/results.txt`）②`pre-commit install`、`npm install`（husky v8／v9）遇到已經是 symlink 的掛載點怎麼處理 —— H1–H3 的 fixture 一律「先 install、後把掛載點換成 symlink」，實跑記錄；另一種順序不測 ③部署後的 `~/.claude/skills/security-audit/CLAUDE.md` 會不會在 skill 被叫起時當成巢狀記憶載入 —— 沒查；前例 `skills/self-improving-agent/CLAUDE.md` 一樣部署，所以那份 CLAUDE.md 只寫給維護者看、被稽核 session 讀到也無害的內容 ④dontAsk 會不會經過 auto mode 分類器 —— 擋下的話 `permission_denials` 不為空，看得到

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | `/dd-init` 寫檔不跟 symlink 寫到專案外 | DONE | — | 拋棄式目錄裡 `CLAUDE.md.dd-upgrade` 是指向專案外檔案的 symlink 時 `--apply` exit 6、專案外檔案 bytes 不變；沒有既存輸出時照常 exit 0；`bash` 與 `/bin/bash`（3.2）跑 `tests/test-dd-init-upgrade.sh` 全綠；沙盒臂 A、AO、B、C、C2、D、E、F、G、G2、I、O、OI（subagent 照新版 `commands/dd-init.md` 做；AO 用舊版升級腳本，O、OI 用 git 2.30.6）遇到 symlink（升級輸出檔、`.gitignore`、`.screenshots`、`CLAUDE.md` 的建立／補充／升級、Phase 3 掛載點的各寫檔分支、掛載點的父目錄）都停下問、專案外假檔的 sha 與權限沒變；答「要」的臂 Y、Y5、YD（`CLAUDE.md` 指向專案裡的 `AGENTS.md`）寫進 `AGENTS.md`、連結還在，Y5、YD 的 Phase 5 commit 的是 `AGENTS.md`；對照臂 K1–K3（不放 symlink）不跳提問、照常寫入；docker 臂 H1–H3：pre-commit、husky v8、husky v9 三個真工具各一臂 symlink、各一臂不放 symlink 的對照（H2、H3 對照：gate 照常掛上、`npm install` 之後 gate 還在；H1 對照：照 Phase 3 pre-commit 分支刪掉舊呼叫、交 YAML，代使用者加進設定並 `pre-commit install` 後 commit 時 gate 有跑） | 9584605..96aaa42 |
| S2 | 收編 cloudflare/security-audit-skill 為 user-invoked promoted skill | IN_PROGRESS | S1 | `./install-dd-pipeline.sh --force` 後 `diff -rq skills/security-audit ~/.claude/skills/security-audit` 無差異；全新 `claude -p` session 用 `/security-audit` 叫得起來（回覆貼出只存在於 claude-dd 這一版、上游沒有的標記行，不存在的 slash 名稱貼不出）；自然語言的安全稽核需求不會自己叫起它（拿掉 dmi 的對照組會叫起來）；預設輸出路徑解析成 harness 先算好的下一個未用編號（目前是 `~/security-audit-skill/claude-dd/run-2`）；本機跑 CI 的相關 step 與 `tests/test-install.sh` 全綠 | 6f2118a.. |

- 狀態只有 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`；同一時間最多一段 `IN_PROGRESS`
- 下一段：由上往下第一個 `TODO`，而且它依賴的段落都已 `DONE`。有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段
- 開工：`~/.claude/scripts/check-claude-md.sh --start-segment` 記起點；這段標 `IN_PROGRESS`，commits 欄先填 `<起點>..`（短 SHA；起點是空樹時填它印出的完整 SHA；回頭做 `BLOCKED` 過的段落時，欄裡原本的起點保留不改）；該段有「開工前提」就先查完，結果寫進「段落與小任務」該段底下。這些改動跟第一個小任務的 commit 一起送
- 每個小任務：照「段落與小任務」列的做，實作、驗證、commit，commit 訊息第一行結尾帶編號（例如 `（S2-1）`）。可用 `SKIP_DOC_CHECK=1` 先跳過 CLAUDE.md 檢查，gate 會記帳。測試照文件裡的測試清單加；想加清單以外的測試，先問使用者
- 小任務 commit 了不等於段落完成。小任務全部 commit 完，而且 SKIP 欠下的 CLAUDE.md 都補上了，才對整段跑步驟 3–8，範圍從表上這段的起點算。最後一個小任務用正常 commit；補 SKIP 改過的目錄的 CLAUDE.md 時，用 `git diff <起點> -- <目錄>` 看整段改了什麼，不要只看這次 staged 的（gate 只查 CLAUDE.md 有沒有一起送，不查寫了什麼）。步驟 6、7、8 的 commit 訊息第一行結尾帶段落編號（例如 `（S2）`）
- 標 `DONE`：步驟 3–8 全部跑完才標；commits 欄補上終點（標 `DONE` 之前最後一個 commit 的短 SHA，所以標 `DONE` 的 commit 自己不在範圍內），跟步驟 7、8 的 commit 一起送，7、8 都沒改檔就單獨開一個 docs commit。標到表上每段都 `DONE` 的那個 commit，刪掉根目錄 CLAUDE.md 的指路那段
- 接手：`IN_PROGRESS` 那段就是目前這段。拿「段落與小任務」的清單對 `git log --oneline <表上這段的起點>..HEAD` 裡結尾帶 `（S2-` 的 commit（不加範圍會對到別份文件的同編號 commit）。
  **前綴是「這一段自己的 ID 加一個 `-`」**，不是固定字串：插隊進來的 `S2.5` 要找的是 `（S2.5-`，
  拿 `（S2-` 去比對不到它，拿 `（S2` 又會把 S2.5 的 commit 誤算成 S2 的，還沒 commit 的小任務先做完。小任務都做完了，再看同一範圍裡有沒有帶 `（S2）` 的 commit：有，代表步驟 6 之後的步驟做到一半；沒有就從步驟 3 開始
- `BLOCKED` 用在這段要先停：外部卡住（等使用者決定、環境壞了），或使用者要先做別的事（別段、臨時修 bug）。狀態格寫 `BLOCKED` 和原因，外部卡住時停下來問使用者。先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md（不然 `--start-segment` 會拒絕）；回頭做這段時，範圍一樣從表上這段的起點算。依賴還沒完成的段落維持 `TODO`
- 做到一半冒出新工作：先問使用者，同意才加一列 `TODO` 排進該在的位置；ID 不重編，插在中間用 `S2.5`。
  **同一批要在「段落與小任務」補上這一段的小任務**（名稱、要動的檔案、驗證方式、commit 訊息）——
  只加表上那一列的話，接手的 session 照上面「接手」那條去對 commit，清單本來就是空的，
  它會判定「小任務都做完了」而直接跳到步驟 3，整段程式碼從頭到尾沒人寫。
  沒有小任務條目的段落不得標 `IN_PROGRESS`
- 每列一行，細節寫進 commit 訊息

## 段落與小任務

### S1：`/dd-init` 寫檔不跟 symlink 寫到專案外

開工前提：跑 repo 版 `scripts/check-claude-md.sh --start-segment`（根目錄 CLAUDE.md「開發本 repo」規定用 repo 那份），進度表 S1 標 `IN_PROGRESS`、commits 欄填 `<起點>..`；這兩處改動照 A13 跟 S1-3 一起送。

- **S1-1 `dd-init-upgrade.sh --apply` 輸出路徑已存在就拒絕寫出**
  - 檔案：`scripts/dd-init-upgrade.sh`、`tests/test-dd-init-upgrade.sh`、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、`DD_PIPELINE_ARCHITECTURE.md`
  - 做法：
    1. `tests/test-dd-init-upgrade.sh` 第 8 節（exit 碼）加 T1–T4（見測試清單），寫法照同節 exit 5 那則（`set +e; "$UP" --template "$TPL" --apply …; got=$?; set -e`，再判 exit 碼與檔案狀態），不用裸呼叫（檔頭 `set -e`）。先對**未修的**腳本跑，確認 T1–T4 紅、而且紅在被測腳本給了錯的結果：T1 的外部檔被改、T2 被指向的檔被建立、T3 內容被蓋、T4 的 exit 不是 6；不是 fixture 建不起來
    2. `scripts/dd-init-upgrade.sh`：在 `[ -f "$TEMPLATE" ] || …` 之後、`WORK=$(mktemp -d)` 之前加：`--apply` 模式下 `[ -e "$OUTFILE" ] || [ -L "$OUTFILE" ]` 成立 → 印「❌ 輸出路徑 ${OUTFILE} 已經存在（一般檔、目錄或 symlink 都算），不覆寫；確認不需要後自己刪掉再跑」到 stderr，exit 6。檔頭 exit 清單補「6 --apply 的輸出路徑已經存在（含 symlink），不寫檔」，檔頭「三個模式都不改原檔」那句補上「--apply 也不覆寫已存在的輸出路徑」
    3. `scripts/CLAUDE.md` 的 `dd-init-upgrade.sh` 條目補一句：輸出路徑已存在就 exit 6，理由是 awk 的 `print > out` 會跟著 symlink 寫出去
    4. `tests/CLAUDE.md` 的 `test-dd-init-upgrade.sh` 那列：「exit 2–5」改「exit 2–6」；變異對照補「拿掉 exit 6 那段檢查 → T1–T4 紅」；加了 T1–T4 之後重跑「空殼腳本」變異，照實際輸出更新那一則並標新日期（不先寫死數字）
    5. `DD_PIPELINE_ARCHITECTURE.md` CI 防線表「dd-init 升級分類腳本情境測試」那列的「抓什麼」補「`--apply` 跟著 symlink 寫到專案外」
  - 驗證：用測試驗。`bash tests/test-dd-init-upgrade.sh` 與 `/bin/bash tests/test-dd-init-upgrade.sh` 全綠；變異：複製一份腳本拿掉新檢查，`bash tests/test-dd-init-upgrade.sh <副本>` 只有 T1–T4 紅；空殼變異照上面第 4 點重跑；`shellcheck -S warning scripts/dd-init-upgrade.sh tests/test-dd-init-upgrade.sh` 無輸出
  - commit：`fix: dd-init-upgrade.sh --apply 輸出路徑已存在（含 symlink）就拒絕寫出（S1-1）`

- **S1-2 dd-init Phase 1 第 6 步處理非 0 exit**
  - 檔案：`commands/dd-init.md`（Phase 1「用升級腳本升級」第 6 步）、`CHANGELOG.md`（新開 `## 未發布`，放在 `## 1.6.14 — 2026-10-30` 之上）
  - 做法：第 6 步補「exit 非 0 → 不升級，把它印的原因照實告訴使用者；exit 6 是 `CLAUDE.md.dd-upgrade` 已經存在（上次升級沒做完留下的，或不是你建的 symlink）：`ls -l CLAUDE.md.dd-upgrade` 給使用者看它是什麼，問要不要刪掉重跑，不要自己刪」。CHANGELOG 寫 S1-1、S1-2 的修正
  - 驗證：用其他方式驗（`commands/` 沒有自動測試；專案規則要求 commands 改動派 subagent 在沙盒實跑）：
    1. `git add` 之後（有的 step 用 `git grep`、`git ls-files`，只掃已追蹤的檔），本機跑 CI「dd-init 蓋章區塊改了就要跳 dd-loop-rev」與「CHANGELOG 已發布區塊不可改動」兩個 step（`ruby -ryaml` 抽出 run 腳本用 bash 跑），都綠；前一個 step 會檢查第一個 ```markdown 圍欄的第一行是 `## 開發流程`，擋得住蓋章區塊被夾錯，另外自己印 ``grep -n -A1 '^```markdown' commands/dd-init.md | head -2`` 確認第二行是 `## 開發流程`
    2. 沙盒臂 A（subagent）：scratchpad 拋棄式 git repo，放 `git show v1.6.4:commands/dd-init.md` 抽出的蓋章區塊當 CLAUDE.md，`CLAUDE.md.dd-upgrade` 預先做成指向 repo 外假檔的 symlink；subagent 照 repo 版 `commands/dd-init.md` Phase 1「用升級腳本升級」做（腳本用 repo 的 `scripts/dd-init-upgrade.sh --template <repo>/commands/dd-init.md` 代替 `~/.claude/scripts/…`，第 4 步視為使用者同意）。用指令核對，不看自述：假檔 sha 不變、symlink 還在、CLAUDE.md 不變；它的回報有 `ls -l` 的結果與「要不要刪掉重跑」的問題。驗收只宣稱「新版文字下會停、沒動到檔」，不宣稱「是新文字讓它停的」
  - commit：`fix: dd-init Phase 1 升級遇到輸出檔已存在時停下回報（S1-2）`

- **S1-3 dd-init 寫檔前檢查目標是不是 symlink**
  - 檔案：`commands/dd-init.md`（`### Phase 1` 之前新加一小節「寫檔前：先看目標是不是 symlink」——只用行內 code、不用 ``` 圍欄，免得 ``grep -n '^```' … | head -2`` 夾錯蓋章區塊；Phase 0 第 3 步判模式那句、Phase 1、Phase 2 的指令區塊、Phase 3 各寫檔分支）、`CHANGELOG.md`、`docs/measurements/2026-11-14-dd-init-symlink/`（A20）；同一個 commit 帶上 A13 的設計文件、根 CLAUDE.md 指路、進度表的 `IN_PROGRESS` 與起點。S1-3 開頭寫明 A17
  - 做法：
    1. 同類掃描，逐分支讀、不只靠 grep：`grep -nE` 列出寫檔動作（`>`、`>>`、`mkdir`、`cp`、`mv`、`chmod`、`tee`、**Write**、**Edit**、`刪掉`、`插入`、`搬`、`換成`），再把 Phase 1 每一種模式與 Phase 3 第 3、4 步的每一條分支從頭讀一遍，列出每條的寫檔終點，逐筆標「要檢查」或「不用（理由）」。規劃時已讀到的清單：
       - Phase 1：`CLAUDE.md` 的建立（Write）、補充（Edit）、升級（8step 舊 rev，以及 6step／7step／手寫版那支；`--plan`／`--apply` 讀、第 8 步 `mv` 取代連結本身）→ 要檢查，Phase 0 第 3 步判模式時先跑一次 `[ -L CLAUDE.md ]`（懸空 symlink 會被 `[ -e ]` 判成不存在 → 建立模式而寫穿）；升級輸出檔 → S1-1／S1-2 已處理；第 8 步 `cp` 的目標帶秒級時間戳 → 不用
       - Phase 2：`.screenshots`（`mkdir -p` 對指向存在目錄的連結不做事、對懸空的會失敗；之後的截圖會存進連結目標）、`.gitignore`（`>>`）→ 要檢查
       - Phase 3 第 3 步：pre-commit 套件分支「hook 檔裡的刪掉」→ 要檢查；lefthook 分支、其他工具產生的檔 → 不寫檔，不用；「不存在 → Write」→ 要檢查（懸空 symlink 會被當成不存在而寫穿）；「已存在且未含 → Edit 插入」（含 husky v8）→ 要檢查；「已含 → 搬位置／換寫法」→ 要檢查；husky v9 的 `.husky/pre-commit` → 要檢查
       - Phase 3 第 4 步 `chmod +x <掛載點>`（含「已含、位置對、只差 chmod」）→ 要檢查（會改到連結目標的權限）
       - Phase 5 `git add .gitignore` → 不用（只 stage 連結本身）
    2. 新小節寫規則：
       - 清單裡「要檢查」的目標寫入前檢查兩件事：`[ -L <路徑> ]`；父目錄解析後的路徑（`cd "$(dirname <路徑>)" && pwd -P`）等於專案根目錄、或以「專案根目錄 + `/`」開頭。專案根目錄在 git repo 裡是 `git rev-parse --show-toplevel`，不在 git repo 裡（Phase 1、2 支援空目錄的新專案）是專案根目錄的 `pwd -P`
       - 任一不成立 → `ls -l <路徑>` 給使用者看它指到哪，問要不要照寫。問句依模式寫出「照寫」的後果：建立、補充、`>>`、Edit、`chmod` 會改到連結目標；升級的 `mv` 會用一般檔取代連結本身（`CLAUDE.md` → `AGENTS.md` 這類連結會被拆掉、連結目標的內容會進 repo），升級模式另外建議改對連結目標跑（A16）
       - 已經問過的不重問：Phase 3 第 2 步已經為掛載點在 toplevel 之外問過、使用者同意的路徑，新小節不再問。Phase 1 的 symlink 問句排在升級的同意題之前
       - 答「不要」接到下游：Phase 1 → 告知 `CLAUDE.md` 沒蓋章、Phase 5 不 commit `CLAUDE.md`，Phase 2、3 照常；Phase 2 → 只跳過那一行；Phase 3 → 算進第 5 步的「使用者選擇不裝」
       - Phase 0 第 3 步判模式那句、Phase 2 的指令區塊（`mkdir` 之前）、Phase 3 各分支各補一句指回新小節
    3. CHANGELOG 補 S1-3（寫明哪幾臂是 docker 真工具實測、哪幾臂是沙盒、用到的工具版本與指令，以及 A21 ① 查到的 Write／Edit 遇到 symlink 的行為）
  - 驗證：用其他方式驗（`commands/` 沒有測試框架）。fixture 與斷言寫成 A20 的 `setup.sh`／`check.sh`；每一臂的假檔都在拋棄式 repo 外、建好就 `chmod 644`；subagent 照 A19 做。symlink 臂的斷言一律用指令核對、不看自述：假檔的 sha 與權限（`stat`）都不變、symlink 還在、回報裡有 `ls -l` 的結果與引用那個 symlink 路徑的問句：
    1. `git add` 之後，本機跑 CI「dd-init 蓋章區塊改了就要跳 dd-loop-rev」「CHANGELOG 已發布區塊不可改動」「迴圈步數第五方」三個 step，都綠；``grep -n -A1 '^```markdown' commands/dd-init.md | head -2`` 第二行是 `## 開發流程`
    2. 舊文字基準：開始改 `commands/dd-init.md` 之前，用 S1-2 commit 那一版的文字把下面每一條 symlink 臂（B、C、C2、D、E、F、G、G2、I、H1–H3 的 symlink 臂）各跑一次，逐臂記下紅在哪個斷言，寫進 `results.txt`。舊文字下沒紅的臂，照 S1-2 臂 A 的寫法縮宣稱：只說「新版文字下會停、沒動到檔」，不宣稱是新文字讓它停的
    3. 沙盒臂 B：git repo、有前端（`package.json` 帶 react）；`.gitignore` 是 symlink，假檔**不含** `.screenshots/` 這一行（否則 `grep -qxF` 本來就不寫，sha 不變沒有牙）；`.screenshots` 是指向 repo 外目錄的 symlink；做 Phase 2。兩個路徑都要有問句，假檔與外部目錄都不變
    4. 沙盒臂 C：`CLAUDE.md` 是 symlink、假檔沒有 `## 開發流程`；做 Phase 1（補充模式）
    5. 沙盒臂 C2：`CLAUDE.md` 是懸空 symlink（指向存在的目錄裡、不存在的檔），放 `package.json` 免得 Phase 0 走新專案提問；做 Phase 0–1（建立模式）。核對那個檔沒被建立
    6. 沙盒臂 D：`CLAUDE.md` 是 symlink、假檔帶 `git show v1.6.4:commands/dd-init.md` 抽出的舊 8step 區塊；prompt 給升級同意題的答案「同意」，讓舊文字下走得到第 8 步；做 Phase 1（升級模式）
    7. 沙盒臂 E：`.git/hooks/pre-commit` 是懸空 symlink（指向存在的目錄裡、不存在的檔）；做 Phase 3（「不存在 → Write」分支）。核對那個檔沒被建立
    8. 沙盒臂 F：`.git/hooks/pre-commit` 是 symlink、假檔是 `#!/bin/sh` 加一行指令、不含 gate；做 Phase 3（「未含 → Edit 插入」與第 4 步 `chmod`）
    9. 沙盒臂 G：同 F，但假檔已含接在檔尾的舊版 gate 呼叫；做 Phase 3（「已含 → 搬位置」）
    10. 沙盒臂 G2：同 F，但假檔已含位置正確的 gate 呼叫、權限 644；做 Phase 3（「已含、位置對、只差 chmod」）
    11. 沙盒臂 I（父目錄檢查）：`core.hooksPath` 設成 `.githooks`，`.githooks` 是指向 repo 外目錄的 symlink、裡面沒有 `pre-commit`；做 Phase 3。掛載點字串在 toplevel 底下（第 2 步不會問），只有新的父目錄檢查會問。核對外部目錄裡沒有多出檔
        - ⚠️ 這條前提實跑後不成立：`git rev-parse --path-format=absolute --git-path` 會解析 symlink（只寫 `--git-path` 印的是沒解析的相對路徑），印出來的是 repo 外的路徑，第 2 步就會問（舊文字下 I 也是綠的）。I 照跑，結果只宣稱「新文字下會停」
    12. 對照臂（不放 symlink；斷言不跳 symlink 問句、照常寫入）：K1 git repo、沒有 `CLAUDE.md`、`package.json` 帶 react，做 Phase 0–2（建立模式 + Phase 2）；K2 非 git 目錄、`CLAUDE.md` 是一般檔且沒有 `## 開發流程`、`package.json` 帶 react，做 Phase 0–2（補充模式 + Phase 2）；K3 git repo、沒有 hook 檔，做 Phase 3，gate 寫進 `.git/hooks/pre-commit` 且可執行
    13. docker 臂 H1／H2／H3：
        - 機制：拋棄式 repo 與 repo 外的假檔用**相同的絕對路徑** bind mount 進容器；容器裡也看得到 gate 腳本（`~/.claude/scripts/check-claude-md.sh` 以相同路徑掛進去，否則 `dd-init.md` Phase 3 開頭會整段跳過）；主機上的 subagent 用自己的工具讀寫檔，`pre-commit install`、`npm install`、`git commit` 走 `docker exec`。跑之前從主機與容器各 `readlink` 一次、各取一次假檔 sha，確認兩邊解析到同一個檔
        - fixture：照 A21 ② 一律「先 install、後把掛載點換成 symlink」。H1 pre-commit（`.pre-commit-config.yaml` + `pre-commit install`，hook 檔帶舊版 gate 呼叫）、H2 husky v8（`.husky/pre-commit` 帶 `_/husky.sh` 那行）、H3 husky v9（`core.hooksPath` 是 `.husky/_`）
        - 每個工具兩臂。symlink 臂：掛載點是指向 repo 外假檔的 symlink，照上面的斷言
        - H2、H3 對照臂（不放 symlink）：不跳 symlink 問句、gate 照常掛上，再跑一次 `npm install` 之後 gate 還在
        - H1 對照臂：照 `dd-init.md` pre-commit 分支斷言 —— hook 檔裡的舊 gate 呼叫被刪掉、hook 檔裡沒有 gate、YAML 段落有交給使用者、第 5 步講「還沒生效」；再由 harness 代使用者把 YAML 加進設定、`pre-commit install`，commit 一次確認 gate 有執行
    14. 掃描清單裡每一筆「要檢查」都在新小節或該處的補句裡：拿第 1 步那份逐分支清單（不是 grep 結果）逐筆 `grep -n` 對
    15. `git log --oneline` 確認 S1-3 之前的 commit 都不含設計文件；設計文件與 `results.txt` 照 A14 過一次
  - 實作紀錄（S1-3 commit 時寫）：
    - 做法第 1 步清單的去向（第 14 項：每一筆用 `grep -n` 對那句原文，都找得到）：Phase 1 `CLAUDE.md` 的建立／補充／兩種升級 → 新小節「Phase 1」那條＋Phase 0 第 3 步的補句；升級輸出檔 → 新小節註明由 S1-1 的 exit 6 擋；Phase 2 兩個路徑 → 新小節＋Phase 2 開頭的補句；husky v9 的 `.husky/pre-commit` → 新小節＋Phase 3 第 2 步 husky v9 那條的補句。
      Phase 3 其他寫檔分支（pre-commit 套件的刪掉、不存在 → Write、未含 → Edit 插入（含 husky v8）、已含 → 搬位置／換寫法、第 4 步 `chmod`）**不進新小節**，改寫 Phase 3 第 2 步「掛載點不在 repo 裡」那條：看的是指令**印出來的路徑**，不是 `.git/hooks/pre-commit` 這個名字。依據是實跑：`git rev-parse --path-format=absolute --git-path` 對 `.git/hooks/pre-commit`、`core.hooksPath` 目錄、hooksPath 目錄裡的檔、懸空連結都印解析後的 repo 外路徑（主機 git 2.42.0、容器 git 2.39.5）。各分支在新文字下都停在第 2 步：E（不存在 → Write）、F（未含 → Edit 插入與 chmod）、G（已含 → 搬位置）、G2（只差 chmod）、H1（pre-commit 套件的刪掉）、H2（husky v8 插入）
    - 舊第 2 步**沒有**擋住指到 repo 外的掛載點：舊文字下 G、G2 的 subagent 看到 repo 外的路徑仍然照寫（G2 引第 5 步那條提醒當不問的理由），所以第 5 步最後那條補了「這條是改完之後的提醒，不是不問的理由」
    - 量測 prompt：第 1、2 輪的 prompt 有「只在 {REPO} 裡動作」，它自己就擋住寫到專案外，G、G2 在那兩輪是綠的；只有第 3 輪（`prompt.txt`，不帶這句）算舊文字基準
    - 結果（新文字第一版）：舊文字下紅的 B、C、D、G、G2、H3 各 3/3 綠；舊文字下就綠的 C2、E、F、I、H1、H2 各 1/1；對照臂 K1–K3、H1K–H3K 各 1/1（含容器裡 commit 被 gate 擋）；A 1 次，只紅在問句沒逐字貼 `ls -l`
    - 第一版新小節結尾寫「不要照那個建議改寫目標」沒有限定條件，答「要」（A16 為 `CLAUDE.md` → `AGENTS.md` 這類專案留的路）的人照不了。第二版（a0aa58a，S1-3 的 commit）補「使用者答「要」之後，就對連結目標的路徑用 Write、Edit 照原本的步驟寫」，加一臂 Y（`CLAUDE.md` 指向專案裡的 `AGENTS.md`、答「要」）
    - 結果（第二版）：B、C、D、G、G2、H3 各再 1/1；A 2/2；Y 3/3（蓋章寫進 `AGENTS.md`、連結還在）。逐臂見 `results.txt`
  - commit：`fix: dd-init 寫檔前先看目標是不是 symlink（S1-3）`

- S1 整段步驟 3–8：範圍從表上 S1 的起點算。步驟 4 的報告照 A14 先過一次再落地。步驟 5 重跑上面的測試、變異與沙盒臂（舊文字基準不重跑）；步驟 4 加了臂 AO、Y5、YD、O、OI，舊文字或第二版下紅過的臂各 3 次、其他 1 次；commit 後跑 `./install-dd-pipeline.sh --force` 部署（規劃時 `cmp` 過，部署版與當時的 repo 逐字相同；S1 的 commit 都還沒部署，2026-11-14 部署版的 `scripts/dd-init-upgrade.sh`、`commands/dd-init.md` 與 HEAD 不同）
  - 實作紀錄（步驟 3–5）：步驟 4 的發現與處置見 `docs/reviews/2026-11-14-security-audit-intake/S1-judge.md`；`commands/dd-init.md` 改成第三版之二，各版的臂與結果見 `docs/measurements/2026-11-14-dd-init-symlink/results.txt`

### S2：收編 security-audit

開工前提：跑 repo 版 `scripts/check-claude-md.sh --start-segment`，進度表 S2 標 `IN_PROGRESS`、commits 欄填 `<起點>..`，跟 S2-1 一起送。

- **S2-1 加 skill 檔、乾跑、部署陣列、同步數字與授權**
  - 檔案：
    - `skills/security-audit/`：上游 `skills/security-audit/` 底下所有檔原樣複製（上游 c1c8a8c 的 AI-AND-LLM.md、ATTACK-CLASSES.md、CLIENT-SIDE.md、CLOUD-AND-DEPLOYMENT.md、DATA-ISOLATION-AND-LIFECYCLE.md、DESKTOP-MOBILE-AND-LOCAL-IPC.md、HUNTING.md、MEMORY-SAFETY-AND-BINARY.md、PROTOCOLS-RPC-AND-MESSAGING.md、RECONNAISSANCE.md、report-schema.json、RESOURCE-EXHAUSTION-AND-AVAILABILITY.md、SKILL.md、SUPPLY-CHAIN-AND-RELEASE.md、validate-coverage-ledger.cjs、validate-coverage-ledger.test.cjs、validate-findings.cjs、validate-findings.test.cjs、VALIDATION-AND-REPORTING.md、WEB-PROTOCOL-AND-AUTH.md；照抄前 `ls` 上游目錄重核一次），`SKILL.md` 照 A5 加兩處
    - `skills/security-audit/LICENSE.txt`：上游 `LICENSE`（MIT，Cloudflare）原文
    - `skills/security-audit/CLAUDE.md`：gate 要求（目錄有 `.cjs`，`scripts/check-claude-md.sh` 的 `CODE_EXT` 含 `cjs`）；寫上游 repo 與 commit `c1c8a8c`、本 repo 的兩處改動、怎麼從上游更新、兩支驗證器的測試怎麼跑、A6 的分支清單與每條的標記、乾跑發現（含試跑那筆：session 因 US$15 上限把獵人從 2 減成 1，`run-metadata.json` 的 `plan_revision` 有記，不是靜默；但 SKILL.md「Cost budget」的預算只算 agent 次數，美元上限不在它的模型裡，`-p` 底下也沒有使用者可以接它的提議）
    - `install-dd-pipeline.sh` `PROMOTED_SKILLS`：加 `"security-audit"   # user-invoked（disable-model-invocation）；vendored 自 cloudflare/security-audit-skill`（依字母序放在 `self-improving-agent` 之前）
    - `README.md`：`Install 13 promoted Skills` → 14、`## Promoted Skills (13, …)` → 14、表格加一列（說明、vendored 自哪、user-invoked、用 `/security-audit` 叫）、授權表加一列
    - `README.zh-TW.md`：`安裝 13 個 promoted Skills` → 14、`## Promoted Skills（預設部署，13 個）` → 14、表格加一列、授權表加一列
    - 根目錄 `CLAUDE.md`「目錄結構」的 `` `skills/` — 13 個 Skills `` → 14，括號內 vendored 說明補 security-audit
    - `DD_PIPELINE_ARCHITECTURE.md`：`13 個 promoted Skills` → 14（用這個字串定位）；「授權」清單加 `skills/security-audit/LICENSE.txt`
  - 做法：
    1. 複製檔案、照 A5 改 SKILL.md、寫 LICENSE.txt
    2. 乾跑（A6）。分支清單（節名與關鍵句以上游 `c1c8a8c` 的 SKILL.md 為準，括號是上游行號，只供定位）：
       - D1 Operating modes：Guidance mode（一個安全問題）（12–15），連同「Full audit planning 的要求只在 full audit mode 適用」（90）→ 乾跑
       - D2 Operating modes：兩種模式都說得通時先問一題（17）→ 乾跑
       - D3 執行邊界：控制項不能全部強制 → 不執行目標碼、記 `needs_validation`（33–40）→ 試跑已實跑（試跑 README「發現」那列與「限制」第 3 點）
       - D4 執行邊界：控制項都能強制 → scratch promotion（40、68–80）→ 乾跑
       - D5a Output directory：使用者指定、在 target 外的路徑 → 試跑已實跑（試跑 `real.prompt.txt` 給了輸出目錄）
       - D5b Output directory：沒指定時的預設路徑算式 `~/security-audit-skill/<repo-name>/run-<N>`、`<N>` 取下一個沒用過的整數（50–51）→ 乾跑，另外在 S2 步驟 5 用 `claude -p` 實跑對照（收編清單 #3 要求路徑算式、目錄命名實跑）
       - D5c Output directory：target 內（使用者自己選且版控忽略整個目錄）／否則停下要外部路徑（51）→ 乾跑。維持一條：兩個結果由同一個條件句分出來，同一個 subagent 走得到兩邊
       - D5d run-metadata：「Update metadata only when those facts change」（86）。facts 變了就更新 → 試跑已實跑（`results.txt` 的 `plan_revision`）；facts 沒變就不更新 → 不另跑（這半是「不做事」，乾跑只能讀到同一句話、觀察不到差別），列進 `skills/security-audit/CLAUDE.md` 的「沒走過」清單
       - D6 Prior runs：有 prior ledger（96–104）→ 乾跑，用真實的 `~/security-audit-skill/claude-dd/run-1/` 走一次，逐條標規則 1–6 哪幾條被真實資料走到：run-1 的 confirmed 是 0，所以規則 2、3 與規則 5 的 rejected 那半標「沒走過」，列進 `skills/security-audit/CLAUDE.md`；沒有 prior ledger（105）→ 試跑已實跑
       - D7 quick（111）→ 試跑已實跑
       - D8 standard，沒指定 profile 時的預設（預設寫在 109，standard 的定義在 112）→ 乾跑
       - D9 deep（113）→ 乾跑
       - D10 scoped run（115）→ 乾跑
       - D11a Cost budget：使用者設了 budget（121）→ 試跑已實跑（budget 9）
       - D11b 沒設 budget（`budget` 記 null，86）→ 乾跑
       - D11c target 大、parent 自己提議 budget（121）→ 乾跑
       - D12 撐不起偵察與保留額 → 不派 agent、要求更大預算／更窄範圍，不變就記 incomplete（123）→ 乾跑
       - D13 後面的 wave 保不住 critic 保留額 → 那個 wave 記 `deferred`（130）→ 乾跑
       - D14a wave 1 前估算明顯不夠 → 說出來、提議更窄範圍或更粗 profile（132）→ 乾跑
       - D14b final-critic 保留額被吃掉 → incomplete `critic_budget_exhausted`（132）→ 乾跑
       - D15 驗證預算用完 → incomplete `validation_budget_exhausted`、部分報告（134）→ 乾跑
       - D16 兩種終止狀態（179）：(a) 全部寫完且驗證器通過 → 試跑已實跑（`results.txt` 的 `run_status=complete`）；(b) incomplete → 不另跑，由 D12–D15 走到
       標「乾跑」的 16 條（D1、D2、D4、D5b、D5c、D6 有 prior ledger、D8、D9、D10、D11b、D11c、D12、D13、D14a、D14b、D15）各派一個 subagent（sonnet；只讀，不寫檔、不跑 node、不派 agent），讀 repo 的 `skills/security-audit/SKILL.md` 與它引用的配套檔，以 claude-dd 為目標走那一條，逐條引用卡住、要猜、互相矛盾的原文；會寫檔的步驟只描述會寫什麼、寫到哪
    3. 乾跑發現照 A14 過一次，整理進 `skills/security-audit/CLAUDE.md`（分支清單、標記、沒走過的照實列）；有分支不能用就停下回報使用者
    4. 改部署陣列、數字、授權
  - 驗證：用其他方式驗（這段是複製上游檔與改文件數字，repo 的 CI step 就是這些宣稱的檢查）：
    1. `diff -r <上游>/skills/security-audit skills/security-audit` 只剩 SKILL.md 的兩處插入與新增的 LICENSE.txt、CLAUDE.md
    2. `git add` 之後（有的 step 只掃已追蹤的檔），本機用 `ruby -ryaml` 抽出 ci.yml 的「陣列與目錄一致性」「數字宣稱一致性」「部署內容裡的 ~/.claude/ 路徑要指得到東西」「全域模板 §7.2 觸發目標存在性與部署」「迴圈步數第五方」五個 step 用 bash 跑，全綠（新加的 .md 都在第五方的掃描範圍內）
    3. `node --test skills/security-audit/validate-findings.test.cjs skills/security-audit/validate-coverage-ledger.test.cjs` 過（評估時在 scratchpad 跑過 34+31=65 則）
    4. `grep -rn '\$[0-9]' skills/*/SKILL.md commands/*.md` 無輸出
    5. 16 份乾跑報告裡每條引用的原句，用 `grep -F` 回對 SKILL.md 或配套檔；回不到的不算
  - commit：`feat: 收編 cloudflare/security-audit-skill 為 user-invoked skill（S2-1）`

- **S2-2 部署清單實證、試跑紀錄、agent 指路**
  - 檔案：
    - `DD_PIPELINE_ARCHITECTURE.md`「部署清單」那段加一句：2026-11-14 收編 vendored security-audit（user-invoked），實證來源為 `docs/measurements/2026-11-14-security-audit-trial/` 的試跑
    - `docs/measurements/2026-11-14-security-audit-trial/`：README「skill 還沒收進 repo」那句改成已收進；CLAUDE.md「此層慣例」第一條的「含 claude-dd 自己的未修安全線索」改成實際理由（那筆線索已在 S1 修掉；報告仍含本機路徑）；CLAUDE.md「與上層的關係」的「收編（如果做）時」改成已收編；README「收編時打算這樣改」是試跑當時的描述，留著；整個目錄首次 commit
    - `agents/security-auditor.md` description：括號改成指向 `/security-audit`（A9）
    - `CHANGELOG.md` `## 未發布`：寫 S2
  - 驗證：用其他方式驗：
    1. `git add` 之後，本機跑 CI「CHANGELOG 已發布區塊不可改動」「迴圈步數第五方」兩個 step，綠
    2. 量測目錄裡跑該目錄 CLAUDE.md 寫的去識別 grep，回 0 筆
    3. `git add` 之後（`git grep` 看不到 untracked 檔）`git grep -n 'security-audit'`（排除 `docs/reviews`）逐筆核「這句話在 HEAD 還成立嗎」
  - commit：`docs: security-audit 的部署清單實證、試跑紀錄與 agent 指路（S2-2）`

- S2 整段步驟 3–8：步驟 5：`./install-dd-pipeline.sh --force` → `diff -rq skills/security-audit ~/.claude/skills/security-audit`；`bash tests/test-install.sh`；全新 `claude -p` 五發，cwd 一律是 scratchpad 裡 claude-dd 的拋棄式 clone，clone 的目錄名固定是 `claude-dd`（上游 SKILL.md:50 的 repo name 取自目錄名或 Git remote）（`--output-format stream-json --verbose --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}'`、每發設 `--max-budget-usd`、`< /dev/null`），結果照 A11 落地：
  - 正向：`/security-audit` 加「把你載入的 skill 本文裡、frontmatter 之後第一個非空行原文照貼，不做稽核」；`--allowedTools "Skill"`、`--disallowedTools "Read Glob Grep Edit Write NotebookEdit Bash Agent"`。判準：回覆用 `grep -F` 比得到 A5 加的那一整行（只存在於 claude-dd 這一版 —— repo 與部署版 —— 上游沒有），jsonl 沒有 Read／Glob／Grep 的 tool_use，`permission_denials` 是空的
  - 正向對照：同一個 prompt 與旗標，slash 換成不存在的名稱 → 回覆比不到那一行
  - 反向：不含 skill 名、要求做這個 repo 的完整安全稽核；照根目錄 CLAUDE.md「新增 Skill 步驟」第 5 步的旗標（`--allowedTools "Skill Read Glob Grep"`、`--disallowedTools "Edit Write NotebookEdit Bash Agent"`）→ jsonl 沒有含 `security-audit` 的 `Launching skill:` 行、沒有 Read 到 `~/.claude/skills/security-audit/` 的 tool_use（clone 裡 repo 自己那份 `skills/security-audit/` 是被稽核的目標，讀到不算觸發）、`permission_denials` 是空的；叫起了 `review` 就照 A12 #6 另開小任務
  - 反向對照：同一個 prompt 與旗標，加 `--plugin-dir` 載入照試跑 README「跑法」第 1 步做的副本（`.claude-plugin/plugin.json` + `skills/security-audit/`），但**拿掉** dmi 那一行 → 預期有含 `security-audit` 的 `Launching skill:` 行（plugin skill 帶命名空間，所以用子字串比）。這一發同時也載入部署的 dmi 版，兩臂的載入方式不同，寫進 results 說明。沒出現 → 反向那發沒有鑑別力，兩發一起換 prompt 重跑
  - 預設輸出路徑（D5b）：prompt 寫明「使用者明確要求完整稽核（full audit mode），這次只做 Full audit setup 裡解析 Output directory 那一步，把解析出的絕對路徑印成一行，不建目錄、不往下做」；旗標另給：`--allowedTools "Skill Glob Bash(ls:*)"`、`--disallowedTools "Edit Write NotebookEdit Agent"`（只放行列目錄，一般 Bash 與寫檔照擋）。預期值由 harness 在跑之前 `ls ~/security-audit-skill/claude-dd/` 算出下一個未用編號（目前 run-1 已存在（U1），所以是 run-2），不寫死。判準：印出的路徑等於那個值，而且 jsonl 裡有這個 session 自己列 `~/security-audit-skill/claude-dd/` 的 tool_use；`permission_denials` 是空的。結果與涵蓋到哪寫進 A12 #3 與 `skills/security-audit/CLAUDE.md`

### 要新增的測試清單（使用者選定）

只有 S1 加測試，都在 `tests/test-dd-init-upgrade.sh` 第 8 節，寫法照同節 exit 5 那則（`set +e … set -e` 包住）：

- T1：`--apply` 的輸出路徑是指向 WORK 外一個檔的 symlink → exit 6；那個檔 `cmp` 跟原本相同；symlink 還在
- T2：輸出路徑是懸空 symlink，指向「存在的目錄裡、不存在的檔」→ exit 6；那個檔沒有被建立（未修版會建立它，這樣紅燈才有鑑別力）
- T3：輸出路徑是既有一般檔 → exit 6；內容 `cmp` 不變
- T4：輸出路徑是既有目錄 → exit 6

S1-2、S1-3 與 S2 不加 repo 測試（`commands/` 沒有測試框架，驗證靠沙盒臂、對照臂與 docker 臂，fixture 腳本放量測目錄、不進 `tests/`；S2 靠 CI 既有 step、上游自帶的兩支 node 測試、`claude -p` 實測）。
