# 全域 CLAUDE.md 瘦身：8 步迴圈的「怎麼做」搬進 dd-loop skill

全域 CLAUDE.md（`templates/global/CLAUDE.md`，每個專案、每個 session 都載入）的 §3.9 開發迴圈佔約 36%，只有跑迴圈時用得到。
把做法細節搬進一個由規則明寫呼叫的 skill，全域只留清單、關卡與驗證教訓。

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | 新 skill dd-loop + 全域 §3.9 瘦身 | DONE | — | 全域模板行數與 bytes 下降（前後 `wc -lc`）；搬走的每一句在 `skills/dd-loop/SKILL.md` 找得到原文；`claude -p` 沙盒正例（段落開始、做到一半接手、步驟 4 前、步驟 8 前）jsonl 有 `Launching skill: dd-loop` 且 `permission_denials` 裡沒有 Skill；小改動反例不叫；§3.9 引用清單（A、B 兩組樣式）每筆都有判定；ci.yml 讀文件的 step 本機全 exit 0 | f46d4de..a34cda1 |
| S2 | /dd-init 蓋章區塊瘦身並跳 rev 12→13 | IN_PROGRESS | S1 | `tests/test-dd-init-upgrade.sh` 在 ubuntu 與 bash 3.2 綠（含兩個變異會紅）；ci.yml「蓋章區塊每一行都在升級清單裡」負面測試紅、還原綠；新區塊關卡五條 grep 都命中；部署後 `cmp` 三支一致；`claude -p` 跑部署版 `/dd-init`：同意才 `--apply`、輸出只有一個 rev 13 標記、拒絕時檔案不變 | f2ab54a.. |

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

## 來源

- 使用者在 plan mode 核准的方向（2026-10-30）：全域 §3.9 的「怎麼做」搬進 skill，全域留清單與關卡；規則明寫呼叫，不靠 description 比對；好處只算 context 用量，必須實測 skill 叫得起來
- 使用者決定：§3.9「規則」裡 8 條驗證教訓（race 與交易、併發驗法、擋誤用機制三件事、git 進行中狀態、鑑別力測試、0 紅先疑實驗、識別符 git grep、清點分母）**留在全域**
- 使用者決定（plan-review 確認輪後）：只做 S1；S2 留 TODO，等 S1 實測證明 skill 叫得起來後另寫計畫、重新送 plan-review
- 段落草稿經 plan-review 4 輪（1、2、3、3C，每輪 4 個審查者）：S1 自第 3 輪起沒有重大缺失；後三輪的重大缺失都在 S2 的 Phase 1 升級規則

## 假設

- ⚠️ 未經審查：確認輪 3C 不通過（2 條重大），其改法未經審查：Phase 1 改以「行」對照新舊範本判、範本段落清單補標題／標記／維護小節、在地行放回同一步驟、歸零檢查只套換新範圍並改用整句識別字串、fixture 改為 rev 12／9／2(6a9addd)／8step-only(v1.1.0)／13 與機械 diff 核對；以及 3C 的小事（差異句範圍、permission_denials 判定統一、注入量判讀、檔案清單補 SKILL.md 與 UPGRADING、/tmp 改 scratchpad、正例跑 2 次、frontmatter、純文件段落步驟 3 只審不改、rental-management 手動處理）。第 3 輪（不通過，1 條重大）的改法在確認輪範圍內；其中重大 1 的原改法（結構性規則初版、三個 fixture）被確認輪推翻並改寫如上；第 3 輪的 8 條小事確認輪沒指出問題（已改進計畫（未經審查；在確認輪範圍內，確認輪沒指出問題））

- 新 skill 名 `dd-loop`（`ls skills/` 目前沒有同名）
- 搬進 skill 的照原文（逐句搬，不改寫意思）；全域 §3.9 的 8 步可以各改寫成一行，關卡用原文。改寫的每一行都跟原句並排對照條件與指向（§3.10「縮短既有文字時」）
- 全域 §3.9 呼叫 `dd-loop` 的時機：①段落開始的第一個動作 ②步驟 3、4、8 開始前一律呼叫一次（無條件，不靠 agent 判斷手上有沒有內容；接手與 context 壓縮後都涵蓋）。蓋章區塊用同一寫法
- 寫作限制（CI 會讀）：新增的行不以 `數字. ` 開頭（步數計數，ci.yml:471）；一行式箭頭摘要必須剛好 7 個箭頭（ci.yml:487–504）；蓋章區塊內的圍欄一律縮排、不在第 0 欄（stamp 擷取 ci.yml:427 會提早截斷）；rev 13 差異句寫「rev 12 缺…」，不寫 `dd-loop-rev: 13` 字樣（唯一性檢查 ci.yml:330–331）
- 行數預估更正：8 條教訓（`templates/global/CLAUDE.md:353–410`，58 行）留在全域，§3.9 縮完約 75–80 行，不是附錄 A 寫的 35–45 行；§3.9 現為 193 行、20,287 bytes（`wc -c`）。不為了湊行數搬走教訓
- rental-management（rev 2）沒有 `## 開發流程` 標題，Phase 1 會命中「無區塊 → 末尾加入」而變成兩份區塊，這是既有行為、只影響它一個：計畫註明該專案升級時手動處理
- 蓋章專案實為 11 個：7 個有 rev 標記，另 4 個（ansible、gps-simulator、line-card、postpartumcaresystem）只有 `8step`，判成舊版後走同一條結構性升級規則
- 呼叫寫成明寫「呼叫 Skill `dd-loop`」，不靠 description 比對（同 §3.9 步驟 7、8 與 §4.1 的 plan-review 寫法）
- 好處只算 context 用量；不宣稱遵守率變好
- 不新增 committed 測試：驗證用既有 CI step 本機跑、`claude -p` 沙盒實跑、subagent 乾跑


## 段落與小任務

### S1 新 skill dd-loop + 全域 §3.9 瘦身

- S1-1 新增 `skills/dd-loop/SKILL.md`、全域 §3.9 縮短、部署陣列與數字同步
  - 檔案：`skills/dd-loop/SKILL.md`（新）、`templates/global/CLAUDE.md`、`install-dd-pipeline.sh`（`PROMOTED_SKILLS`）、`README.md`、`README.zh-TW.md`（Promoted Skills 表格、標題數字、安裝步驟「N 個 promoted Skills」）、根 `CLAUDE.md`（目錄結構 12→13；「核心工作法」第 7、8 步細則改指 skill；「CI 不驗、只能手動同步」那條的觸發條件「迴圈步數或 §3.9 文案」加上 `skills/dd-loop/SKILL.md`）、`scripts/CLAUDE.md`（:173 改成「§3.9、`skills/dd-loop/SKILL.md`，以及 `skills/task-planner/SKILL.md`」三個都留、:183）、`diagrams/src/CLAUDE.md`（:13 步驟 4 對齊；文字有變就同批重出 GIF）、兩份 README 的迴圈說明段（README.md:88、:101、:103；zh-TW :91、:104、:106；最終以 grep 結果為準）、CLAUDE.md 維護規則段（README.md:121；zh-TW :124）與 gate 對策段（README.md:143、:149；zh-TW :153、:159）；其餘命中檔（DD_PIPELINE_ARCHITECTURE.md:99/:128、diagrams/src/gen_loop.py、gen_planner.py、skills/verification-gate/SKILL.md:56）照 grep 結果補進，不靠手列、`DD_PIPELINE_ARCHITECTURE.md`（部署清單、元件數）、`CHANGELOG.md`（目前沒有 `## 未發布`，先在 `## 1.6.12` 之上新開）
  - 搬走（全域 → skill）：§3.9 前言裡起點的各種情況（全域留一句指令）；步驟 3 的範圍細節；步驟 4 全部子項；步驟 8 的範圍指令與 `status --porcelain` 陷阱、improver 先算範圍；「規則」裡管迴圈機制的：步驟 1、5 跑既有測試、巢狀 CLAUDE.md 逐層更新、步驟 7 vs 上一條、步驟 7 跳過不代表 8 跳過、順序不可反、步驟 8 發現分兩類、7、8 動到檔要 commit、gate 被擋時的處置、專案 CLAUDE.md 可覆蓋
  - 留在全域：§3.9 標題與「每完成一個功能段落」前言；第一個動作呼叫 `dd-loop`、`--start-segment` 一行；8 個編號步驟各一行並附關卡（不帶紅燈進 commit；步驟 4 修掉 Critical/Important 才續行、收回完整報告少於 3 份不續行、報告落地或 SKIP 申報；步驟 6 不可用 SKIP；步驟 7、8 呼叫的 skill 名）；`> 步驟 1 的測試證明…` 那行；「驗證不過 → 重跑步驟 5」；8 條驗證教訓原文
  - §3.9 引用改指向（附錄 A S1 第 4 項）：用兩組樣式產出清單：A 組 `git grep -n -E '§3\.9|報告一律落地|範圍要明講|派工前先準備' -- . ':!docs/reviews' ':!docs/designs' ':!docs/measurements' ':!CHANGELOG.md'`；B 組（概念詞）`git grep -n -E 'segment-base|SKIP-REVIEW|-judge\.md|diff 檔|蓋章區塊|區塊內|步驟 [348] 的'`，排除條件同 A，扣掉 A 已命中的行。兩組樣式本身寫進設計文件（引用前先重跑），逐筆判「改指 skill／刪掉／原地仍成立」，判定寫進設計文件 S1 底下；`commands/dd-init.md` 區塊外的 :323 歸 S2-1
  - 驗證：①前後 `wc -lc templates/global/CLAUDE.md`；②搬移對照：基準取 `git show <段落起點>:templates/global/CLAUDE.md | sed -n '/^### 3\.9/,/^### 3\.10/p'`（不從工作目錄取，否則空轉），腳本把舊 §3.9 每個非空行（去掉前導空白與列表符號）在「新全域 §3.9 ∪ SKILL.md」裡找，印出找不到的行，逐條人工判是不是刻意改寫（預期只有改成指向 skill 的那幾句）；另印「同時出現在新全域與 SKILL.md」的行交人工判；所有改寫過的行與原句並排對照條件與指向；③ 抽成本機腳本時所有 `/tmp` 一律改到 scratchpad；先 `git add skills/dd-loop`（死指標與箭頭檢查用 `git grep`／`git ls-files`，看不到未追蹤檔）再把 ci.yml 讀文件的 step 抽成腳本本機 `bash -e` 全 exit 0（含迴圈步數四方一致、第五方、數字宣稱、§7.2 觸發目標、死指標）；④ `ruby -ryaml` 解析 ci.yml；⑤ 照根 CLAUDE.md「新增 Skill 步驟 3」派 subagent 在 scratchpad 拋棄式 repo 照 SKILL.md 實跑一段（含有／沒有進度表兩條分支），逐條引用卡住或矛盾的原文；另照根 `CLAUDE.md:53` 派一個只讀專案文件的接手 agent：拋棄式 repo 放 fixture 進度表（一段 IN_PROGRESS、commits 欄填起點、根 CLAUDE.md 放指路句），從那段接手，用指令核對它有沒有叫 skill、範圍是否用表上的起點；⑥改完重跑 A、B 兩組樣式，每一筆都有判定
  - SKILL.md frontmatter 不設 `disable-model-invocation`（要能被明寫呼叫）
  - 步驟 3：S1、S2 都是純文件段落，code-simplifier 只審不改（避免改寫剛搬過去的原文）
  - 步驟 4 的派工方向：至少一個審查者專審「搬移前後條件與指向有沒有掉」（附錄 A 驗證 4）；S2 同
  - commit：`feat: 8 步迴圈的做法搬進 dd-loop skill，全域 §3.9 只留清單與關卡（S1-1）`
- S1-1 實作紀錄（2026-10-30）
  - 與草稿不同：「規則」裡 4 條一行規則留在全域、沒搬（步驟 1、5 跑既有測試；巢狀 CLAUDE.md 逐層更新；gate 被擋時的處置；專案 CLAUDE.md 可覆蓋）。
    理由：它們不只在跑迴圈時用得到（任何 commit 都可能被 gate 擋、任何改碼都要逐層更新），而且 README 的 gate 對策段把它們寫成 §3.9 的規則；搬走只省 4 行
  - 搬走的：前言起點細節、步驟 3、4 的細則、步驟 8 的範圍指令與陷阱、步驟 7 與 8 的關係（6 條）
  - 搬移對照（基準 `git show f46d4de:templates/global/CLAUDE.md` 的 §3.9，183 個非空行）：找不到的 3 行都是刻意改寫——
    「依序走:」→「依序走下面 8 步。」、步驟 4「例外見下」→「例外見 `dd-loop`」、步驟 8 標題行加「(指令見 `dd-loop`)」；條件與指向逐條對過沒掉。同時留在兩處的行：0
  - A 組引用判定：`ci.yml` 317/319/322/472（數 §3.9 步數）原地成立；根 CLAUDE.md「核心工作法」第 7、8 步細則那句改指 skill；手動同步觸發條件加 `skills/dd-loop/SKILL.md`；
    其餘根 CLAUDE.md（定義於 §3.9、§3.10 刻意放外面、四方一致、2026-09-12 踩雷史）原地成立；`DD_PIPELINE_ARCHITECTURE.md` 100、129 原地成立；
    README.md:103／zh-TW:106「派工與報告落地見 §3.9 步驟 4」改指 skill；README 88/91（定義於 §3.9）、121/124（逐層更新是 §3.9 規則）、143/153（寫實際讀到的內容）、149/159（逐層檢查）原地成立（那幾條留在全域）；
    `scripts/CLAUDE.md:173` 改成「§3.9 與 `skills/dd-loop/SKILL.md`，以及 task-planner」；:183 原地成立；`diagrams/src/CLAUDE.md:13`、:116 加 dd-loop（圖上文字沒變，不重出 GIF）；
    `gen_loop.py`、`gen_planner.py` 頁尾「依全域 §3.9 繪製」原地成立；`skills/verification-gate/SKILL.md:56`（0 紅教訓）原地成立；`commands/dd-init.md` 75/83（區塊內）、323 屬 S2，區塊沒動、原地成立
  - B 組引用判定（概念詞，75 筆）：多數講 gate 腳本、dd-init 蓋章區塊與測試，這段沒改它們，原地成立；引「全域模板」的只有根 CLAUDE.md:181（`--segment-base` 用 `~/.claude/scripts/` 那份），全域與 skill 都還是那條路徑，成立；
    README.md:101／zh-TW:104（步驟 7、8 順序）描述的行為沒變，成立
  - 乾跑（驗證 ⑤，2026-10-30）：
    - 接手 agent（只讀全域模板與專案文件、dd-loop 尚未部署）抓到「有進度表時 `<起點>` 以表上為準」整條被搬走，叫不到 skill 時沒有依據在表上起點與 `--segment-base` 間選 ⇒ 這條（含 exit 非 0 = 沒算出來）放回全域 §3.9；
      另在 §7.4 註明迴圈步驟 3、4 觸發 §7.2 那兩列時先叫 `dd-loop`、§3.9 註明每次叫不算 §7.3 的重入
    - 照 SKILL.md 實跑 A（無進度表）、B（有進度表）兩個拋棄式 repo，到下一段 `--start-segment` 都 exit 0。採納：步驟 8 有進度表時把表上那格連 `..` 填進 `base`，`git diff` exit 129 而管線 exit 0、輸出空白 ⇒ SKILL.md 寫明只取 `..` 前面；
      退路句補 repo 網址與「裝的是沒有這個 skill 的舊版」
    - 沒處理、留給之後（都是搬過來之前 §3.9 原文就有的，不是這次搬移造成的）：沒有進度表時 `<段落>` 編號沒定義；「報告一律落地」與「有 `docs/reviews/` 時」講法不一；`docs/reviews/CLAUDE.md` 新專案沒有；
      「依序跑 / 並行」怎麼選沒寫；④ 步驟 1 輸出與 simplifier 之後的版本不對應；③「被改到檔案」沒定義；步驟 3、4 改碼會讓步驟 6 再被 gate 擋；報告跟哪個 commit 送沒寫；SKIP 欠帳要在步驟 3 前補完只寫在 task-planner
- S1-2 部署並實測 skill 會被叫起來
  - 檔案：`docs/measurements/2026-10-30-dd-loop-trigger/`（`*.prompt.txt`、去識別後的 jsonl 抽取結果、`run.sh`）
  - 驗證：`./install-dd-pipeline.sh --force` 後，拋棄式 repo 跑 `claude -p`，設定照根 `CLAUDE.md`「新增 Skill 步驟 5」整條抄（`--output-format stream-json --verbose --max-budget-usd 3 --no-session-persistence --permission-mode dontAsk --allowedTools "Skill Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent" < /dev/null`，另加 `--settings '{"advisorModel":""}'`，prompt 存成 `<名字>.prompt.txt`）。判定：`Launching skill: dd-loop` 有沒有出現，並列出所有 Skill 呼叫的順序（「照做」交給 S1-1 驗證 ⑤）。這只證明「會被叫」，不證明是明寫呼叫還是 description 比對；之後改 memory 措辭只寫「會被叫起來」。三個情境：正例「做一段功能」、正例「進度表上 IN_PROGRESS 段落做到一半（同 ⑤ 的 fixture），接著做步驟 3」都要出現 `Launching skill: dd-loop`；另加兩個正例「小任務都 commit 完，接著做步驟 4」「接著做步驟 8」也要出現；反例「改一個 typo」不出現；順手記 jsonl 裡 Skill 呼叫次數與注入量；與附錄 A「--allowedTools 含 Skill 與寫檔工具」不同：這裡照專案規則把寫檔工具列進 disallow，因為只測「叫不叫」，判定改成「permission_denials 裡沒有 Skill」；正例各跑 2 次；Skill 注入量從 jsonl 的 Skill tool_result 內容長度取（實作時發現 tool_result 只有 `Launching skill: dd-loop` 那 24 字元，本文在下一則 user 訊息、以 `Base directory for this skill:` 開頭；check.sh 改量那則），若一段 4 次注入的總量超過全域省下的量，就在報告如實寫出、不再宣稱 context 有好處。stream-json 進 repo 前照根 CLAUDE.md 那條去識別（只抽判定欄位）
  - commit：`test: 實測 dd-loop 在段落開始時被叫起來（S1-2）`

### S2 /dd-init 蓋章區塊瘦身並跳 rev 12→13

計畫經 plan-review 第 1–3 輪與確認輪 3C（每輪 4 個審查者）；3C 通過，3C 的小事改法照改、未再送審。各輪報告見 `docs/reviews/2026-10-30-global-claude-md-slim/plan-review-S2-r*.md`（檔名刻意不以 `S<數字>` 開頭，免得被 gate 當成步驟 4 的報告）。

S2 是設計文件 `docs/designs/2026-10-30-global-claude-md-slim-design.md` 進度表上的一段（依賴 S1，S1 已 DONE）。
一段、兩個小任務；小任務各自 commit，整段再跑步驟 3–8。

開工（跟 S2-1 的 commit 一起送）：`scripts/check-claude-md.sh --start-segment` 記起點；把這份計畫寫進設計文件 S2 段，取代舊草稿；
進度表 S2 的驗收欄改成本計畫的驗收；S2 標 `IN_PROGRESS`，commits 欄填 `<起點>..`；測試清單照使用者選定的寫進設計文件。

#### 為什麼要做、做到什麼程度

- 已蓋章的專案除了全域 CLAUDE.md，還會載入專案根目錄 CLAUDE.md 裡的蓋章區塊。rev 12 的範本區塊是 96 行、6,762 字元（量過），
  內容幾乎是 S1 搬進 `dd-loop` 的同一批細則。
- 量過（S2-2，2026-10-30）：新區塊 37 行、1,733 字元，已蓋章專案不跑迴圈的 session 每次約省 5k 字元；跑迴圈的 session 仍是淨增（S1 量測：一段叫 4 次 `dd-loop`、每次約 6.2k 字元）
- 目標：①新蓋章的專案拿到短區塊（rev 13）②舊專案跑 `/dd-init` 時，能**機械地**把「範本原文」換成新區塊、留下專案自己加的內容
- 範圍：`/dd-init` 只碰專案**根目錄** CLAUDE.md 裡的蓋章區塊；巢狀 CLAUDE.md 由各專案自己維護，不碰（使用者決定）
- 不在範圍：實際去升級使用者的 11 個專案（使用者之後逐專案跑 `/dd-init`，看過清單、同意才改）

#### 上次（3C）卡在哪、這次怎麼避開

上次的升級規則要 agent 自己判斷「哪一行是範本、哪一行是在地內容」，3C 指出：結構規則會把在地規則行刪掉，
「舊細則歸零檢查」又跟「保留在地小節」互相衝突。

這次改成**查表**：把**帶 `dd-loop-version` 標記的**歷代蓋章區塊出現過的每一行（去前後空白）做成一份清單，放在腳本裡。
- 區塊裡的行**逐字等於清單某一行** → 範本原文 → 換新
- 不等於 → 在地內容 → 保留
- 清單排除太通用的行：空行、`---`、單獨的圍欄行（```、```bash、```js…）。圍欄的開合行不查表，圍欄單位只看裡面的行
- 不做「識別字串歸零」檢查；測試改用兩條獨立斷言（見測試清單）

代價：被 agent 在先前升級時改寫過措辭的範本句，不會被認成範本，會被保留（多留、不會少）。為了不讓它們靜靜留下過期指引，
`--plan` 另列一節「保留、但與範本某行相似」（去前後空白後與清單某行共同前綴 ≥60 bytes；awk 在 macOS 按 bytes 算長度，兩個平台都用 bytes），升級前給使用者看。

實測（2026-10-30；清單用全部 45 版、174 行時量的，改成只取帶標記的版本後在 S2-1 重量）：
- R3 舊計畫說的「91 行只對到 3 行」是拿單一版範本比；全版查表後 GlucoLink（rev 12）74 行只剩 6 行不匹配、duoduo-infra（rev 9）72/6、lawyerWebsite（rev 9）74/7、duoduo-helm（rev 9）79/13
- rental-line（rev 7）85 行中 39 行匹配；不匹配的 46 行逐行看過：步驟 5 的專案驗證指令（圍欄內）、專案踩雷紀錄、少數幾句改寫過措辭的範本句（步驟 7、8 的說明、多行版的步驟 8 指令）
- lawdesk-ai（rev 12，業主資料敏感，只量數字）：187 個非空行只有 10 行匹配，最後一個匹配在區塊中段，區塊內 7 個 `###` 子標題。升級對它幾乎沒有效果，使用者已知道
- 無 rev 的 4 個舊版不匹配比例約一半到 9 成，沒逐行看
- 標記種類（2026-10-30 只數標記）：11 個全是 `8step`；7 個有 rev（2、7、9×3、12×2），4 個沒有 rev；沒有 `6step`／`7step`。所以「6step／7step 走 agent 判斷」目前影響 0 個專案
- rental-management（rev 2）的區塊掛在 `### 工作流程（完成的定義，不可省略）` 底下，不是 `## 開發流程`

#### 小任務

##### S2-1 新增升級分類腳本 `scripts/dd-init-upgrade.sh`

- 新區塊來源：`--template <dd-init.md>`，預設 `~/.claude/commands/dd-init.md`。區塊錨點用 ci.yml `stamp()` 那組（`^```markdown$` 開、之後第一個 `^```$` 關）
- 模式：
  - `--plan <CLAUDE.md>`：只印區塊起訖行號、將刪除的行（附行號）、保留的行（附「原在步驟 N／驗證不過之後／CLAUDE.md 維護底下」）、「保留但與範本相似」、「步驟 5 既有的驗證指令行」、「保留的圍欄裡有部分行在清單中」警示
  - `--apply <CLAUDE.md> <輸出路徑>`：把合併後的完整檔寫到輸出路徑；寫之前自檢輸出只有一個 `dd-loop-version`，不對就 exit 5、不寫
  - `--list`：印清單（CI 用，不讓 CI 自己解析 heredoc）
  - 三個模式都不改原檔；取代原檔由 Phase 1 在使用者同意後做
- 找區塊：以 `dd-loop-version` 標記行定位；起點 = 標記行上方最近的標題；終點 = 從起點往下掃，「下一個同級或更高級、而且不在清單裡的標題」之前**最後一個範本單位**。
  最後一個範本單位之後的內容原地不動（lawdesk-ai 那種區塊後段是大段專案內容的情況）。
  區塊中間夾了清單外的同級 `##` 時，終點會停在它前面、它後面的舊範本行不會被換掉 → `--plan` 另列「區塊外還有範本行」並附行號（不靜默）
- 分類單位：空行不算單位，跟著前一個單位走；一般行一行一單位；圍欄（開合行先去前後空白再判斷，處理縮排圍欄）從開到關算一個單位，裡面每一行都在清單裡才算範本
- 錨點（決定在地單位放哪）：清單裡的編號步驟行（`^[0-9]+\. `）、`驗證不過` 那行、`## CLAUDE.md 維護` 標題。在地單位跟著前面最近的錨點：
  步驟 1 之前 → 新區塊前言之後；步驟 N 底下 → 新區塊步驟 N 那段末尾（原縮排、原順序）；`驗證不過` 之後 → 新區塊 `驗證不過` 之後；`## CLAUDE.md 維護` 底下 → 新區塊同一小節末尾
- 起點標題不在清單裡時（rental-management 的 `### 工作流程…`）：保留那個標題，新區塊去掉自己的 `## 開發流程` 那行接在它底下；新區塊其他標題（`## CLAUDE.md 維護`）降一級，避免 `##` 掛在 `###` 底下
- 新區塊 `<依偵測結果填入…>` 的佔位行：一律保留，交給 Phase 1 依 Phase 0 偵測結果填或刪（後端 curl、前端 playwright 兩行各自判；舊區塊步驟 5 底下已有對應的具體指令就刪那一行佔位）
- `--plan` 另標「疑似改寫過的步驟行」：保留行裡符合 `^[[:space:]]*[0-9]+\. ` 的（措辭被改過的編號步驟不是錨點，會跟新區塊同號步驟並存）
- exit：0 正常；2 找不到標記；3 刪除的行扣掉標題與標記之後是 0（清單過期或區塊被整份改寫，不升級）；4 一檔兩個標記；5 `--apply` 自檢失敗
- 清單：腳本內 heredoc，由 `git log --format=%h -- commands/dd-init.md` 中蓋章區塊帶 `dd-loop-version` 的版本產生（排除條件見上）；產生指令寫在腳本檔頭。S2-2 改完新區塊後把 rev 13 的行加進去
- 分類主體用 awk（一律 `LC_ALL=C`，長度按 bytes、兩個平台一致）、外殼 bash，macOS bash 3.2 相容，過 `shellcheck -S warning`；寫中文訊息照 `scripts/CLAUDE.md`「此層慣例」
- 測試：`tests/test-dd-init-upgrade.sh`（見測試清單）
- 同批（根 CLAUDE.md「新增 Script 步驟」與 gate）：
  - `install-dd-pipeline.sh` 的 `DD_SCRIPTS`
  - `.github/workflows/ci.yml` 三處：ShellCheck 檔案清單（腳本與測試兩支）、ubuntu job 加 `run: tests/test-dd-init-upgrade.sh`、bash32 job 加 `run: /bin/bash tests/test-dd-init-upgrade.sh`，bash32 job 的 checkout 補 `fetch-depth: 0`（fixture 要 `git show <tag>:`）
  - `DD_PIPELINE_ARCHITECTURE.md` 的「shellcheck（warning 級，N 支腳本）」加兩支，CI 防線表加「升級分類腳本測試」一列
  - `scripts/CLAUDE.md`、`tests/CLAUDE.md` 的關鍵檔案表；根 CLAUDE.md「目錄結構」`tests/` 那行的測試檔名
  - 兩份 README 安裝步驟裡只寫了部署 `check-claude-md.sh` 的那句（README.md、README.zh-TW.md 各一處），補上新腳本
  - 新腳本與新測試 `chmod +x`，`git ls-files -s` 確認是 100755（ubuntu job 直接執行）
  - 執行 `./install-dd-pipeline.sh --force` 部署（S2-1 commit 之後）
- 驗證：①測試清單 1；②11 個已蓋章專案的 CLAUDE.md **複製**到 scratchpad 跑 `--plan > <scratchpad 檔>`，只用 `grep -c` 取各節行數與 exit，不把內容印進對話、不進 repo（lawdesk-ai 同樣只取數字）；③`ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")'`
- commit：`feat: 新增 dd-init 升級分類腳本，以歷代範本行查表分出在地內容（S2-1）`
- S2-1 實測（2026-10-30）：
  - 清單 150 行（45 版裡帶標記的版本；原本 174 行是全部 45 版）
  - 測試 33 則 ✅：macOS `/bin/bash` 3.2＋BWK awk、docker `bash:5`＋gawk、docker `debian:stable-slim`＋mawk 三種都全綠
  - 空殼腳本（只 `exit 0`）：16 ✅／32 ❌，紅的是「沒有產生輸出檔」與各斷言的錯值
  - 變異 a（圍欄一律算範本，`tpl[nu] = 1`）：9 ❌，四版的 LOCAL5 圍欄內容不見、React 圍欄沒列進「部分行在清單中」
  - 變異 b（終點遇到任何同級標題就停，拿掉 `!(… in L)`）：7 ❌，四版 LOCALV 跑到 `## CLAUDE.md 維護` 之後、6a9addd 與 v1.1.0 各留一行舊範本、純範本輸出不等於預期
  - 11 個已蓋章專案的複本跑 `--plan`（只量測、不作驗收；內容沒印出來）全部 exit 0：

    | 專案 | 刪 | 留 | 相似 | 疑似改寫步驟 | 步驟 5 在地行 | 部分圍欄 | 區塊外範本行 |
    |---|---|---|---|---|---|---|---|
    | duoduo-infra | 74 | 8 | 0 | 0 | 6 | 0 | 0 |
    | rental-line | 37 | 47 | 0 | 0 | 29 | 0 | 10 |
    | lawdesk-ai | 7 | 91 | 0 | 11 | 0 | 0 | 0 |
    | postpartumcaresystem | 13 | 49 | 3 | 2 | 0 | 0 | 0 |
    | lawyerWebsite | 75 | 7 | 0 | 0 | 6 | 0 | 0 |
    | rental-management | 27 | 7 | 2 | 2 | 0 | 0 | 0 |
    | duoduo-helm | 74 | 15 | 0 | 0 | 9 | 0 | 0 |
    | ansible | 6 | 37 | 2 | 8 | 0 | 0 | 0 |
    | line-card | 21 | 18 | 1 | 0 | 10 | 0 | 0 |
    | GlucoLink | 68 | 6 | 0 | 0 | 6 | 0 | 8 |
    | gps-simulator | 14 | 26 | 4 | 2 | 0 | 0 | 0 |

    「留」只算區塊內被保留的行；最後一個範本行之後的內容原地不動、不算在內（lawdesk-ai 那 91 行之後還有大段）

##### S2-2 蓋章區塊縮成 rev 13，Phase 1 升級改用腳本

- 新區塊（`commands/dd-init.md` 蓋章區塊）留：
  - `## 開發流程（每個功能段落依序走）`、rev 13 標記
  - 一句：做法細則在 `dd-loop`，段落開始時、步驟 3、4、8 開始前先呼叫；沒有這個 skill 時見 https://github.com/kopp0510/claude-dd 的 `skills/dd-loop/SKILL.md`（區塊進專案版控，協作者未必裝 claude-dd）
  - `--start-segment` 一行
  - 8 個編號步驟，各帶與全域 §3.9 相同的關卡（不帶紅燈進 commit；步驟 4「要派 agent 時最少 3 個、收回少於 3 份不續行、報告落地跳過要申報」；步驟 8「先算範圍、指令見 `dd-loop`」）
  - 步驟 5 的兩行 `<依偵測結果填入…>`、截圖路徑；React 那段改成 Phase 0 偵測到 React 才填入
  - `驗證不過` 那行；`## CLAUDE.md 維護` 小節只留前兩條（每個有程式碼的資料夾要有 CLAUDE.md、逐層堆疊更新與 gate 只擋改碼那層）
- 舊區塊內容去處（驗收：舊 rev 12 區塊每個非空行到「新區塊 ∪ 全域 §3.9 ∪ `skills/dd-loop/SKILL.md`」裡找，印出找不到的逐條判；這份清單以那個比對結果為準）：
  - 起點的兩個擋點、剛採用 `docs/reviews/` 時第一次一定被擋、舊版 gate 的處置 → 搬進 SKILL.md「段落起點與 `<起點>`」節
  - 「一發只挖到一部分」的五發實測（2.3/3 對 1.8/3）、「不另派裁決者」的實測數字、「時間花在哪」 → 搬進 SKILL.md 步驟 3、4 節
  - 「`.md` 不在 gate 的 `CODE_EXT` 裡…不要把它寫成閉環」 → 搬進 SKILL.md「報告一律落地」那條
  - 步驟 7、8 的關係（兩條）→ SKILL.md 已有，刪
  - React 驗證法 → 留在 dd-init（Phase 0 偵測到 React 才填）
- Phase 0：加 React 偵測（`package.json` 的 dependencies／devDependencies 有 `react`）；建立模式、末尾加入模式、升級三種都照 Phase 0 結果填 React 段
- Phase 1：
  - 路由改成先看有沒有 `dd-loop-version` 標記，再看有沒有 `## 開發流程` 標題（現在先判「無 `## 開發流程` → 末尾加入」，rental-management 會被加第二份區塊）
  - rev 判定線全部跳 13（照根 CLAUDE.md「動到蓋章區塊就必須跳 dd-loop-rev」那條的 ①–④；保留 CI 依賴的「舊版/手寫版」「判定為舊版」字樣）；「列出與現行版的差異」加一句 rev 12 缺什麼
  - 有 `8step` 標記的舊版（rev ≤12 或沒有 rev）：部署版 `~/.claude/scripts/dd-init-upgrade.sh` 不存在就提示到 claude-dd repo 跑 `./install-dd-pipeline.sh --force`、不升級；存在就跑 `--plan`，把將刪除的行、保留的行、「保留但與範本相似」、「區塊外還有範本行」原樣列出來，再 AskUserQuestion；取代之前先跑 `git status --porcelain -- CLAUDE.md`，有未 commit 的修改就在 AskUserQuestion 裡一併告知；同意 → `--apply` 寫到 `mktemp` 暫存檔、照 Phase 0 結果把 `<依偵測結果填入…>` 填掉或刪掉（純 CLI／函式庫專案：兩行佔位改成「跑真實指令或消費端範例」的具體指令，同全域 §3.9 步驟 5）、Phase 0 偵測到 React 就把 React 那段補進步驟 5 底下、取代前把原檔複製一份並印出備份路徑、再取代原檔；拒絕 → 原樣。exit 2–5 → 不升級，照實回報
  - `6step`／`7step` 標記（目前 0 個專案，不為它驗證錨點）與沒有標記的（手寫版、缺 code-review 步驟）：維持現行做法（agent 判斷），不走腳本
- 引用蓋章區塊內容的地方清點：`git grep -n -E '蓋章區塊|區塊內|蓋章版|dd-loop-rev' -- . ':!docs/reviews' ':!docs/designs' ':!docs/measurements' ':!CHANGELOG.md'`，逐筆判定寫進設計文件。已知要改：
  - `scripts/CLAUDE.md`「區塊內：步驟 8 的範圍指令寫死…得跳 dd-loop-rev」（搬出後不成立）、「`commands/dd-init.md` 的蓋章版也寫明了這點」（改指 `dd-loop`）
  - `UPGRADING.md`「判定為舊版」那行的 rev 與「專案自己加的內容會保留」的說法
  - `commands/dd-init.md` 區塊外「逐層往上堆疊更新是 §3.9 的工作流規則」
  - 判定是否仍成立：`diagrams/src/gen_usage.py` 描述 Phase 1 的字串、`README.md`／`README.zh-TW.md` 指令一覽的 `/dd-init` 說明
- 改了 SKILL.md 與蓋章區塊，照根 CLAUDE.md「CI 不驗、只能手動同步的區塊」的觸發時機，逐項巡兩份 README 與 `DD_PIPELINE_ARCHITECTURE.md` 那幾個區塊
- 根 CLAUDE.md「動到蓋章區塊就必須跳 dd-loop-rev」的同批清單加 ⑤：升級清單要加入新區塊的行（CI「現行蓋章區塊的每一行都在升級清單裡」會擋）
- 把 rev 13 新區塊的行加進 S2-1 的清單；ci.yml 加 step「現行蓋章區塊的每一行都在升級清單裡」（呼叫 `--list`，空行與通用行照同一套排除；先確認抽到的區塊非空、最後一行是 `## CLAUDE.md 維護` 小節的內容，抽取失效就紅）
- CHANGELOG `## 未發布`
- 驗證：
  1. 測試清單 1 裡 rev 13 的斷言、測試清單 2
  2. ci.yml 跳號檢查、四方一致、陣列一致、數字宣稱、「蓋章區塊每一行都在升級清單裡」本機綠（照 S1 的做法：把 ci.yml 每個 `run: |` 抽成 scratchpad 腳本、`/tmp/` 換成 scratchpad 路徑，`/bin/bash -e` 逐支跑）
  3. **新區塊的關卡逐條 grep**（0 命中就補在括號裡那一步）：`不可帶紅燈`（步驟 1）、`最少 3 個`與`少於 3 份`（步驟 4）、`落地`與`跳過要申報`（步驟 4）、`不可用 SKIP`（步驟 6）、`第一個動作是算範圍`（步驟 8）；新區塊這幾處措辭照全域 §3.9 原文寫
  4. 新區塊沒有第 0 欄的 ```（stamp 遇到就截斷）；8 個步驟行以外的新增行不以 `數字. ` 開頭；本機跑 ci.yml「第五方」整個 step（它掃全部 `*.md`、`*.sh`，不只 README）
  5. 「舊區塊內容去處」的逐行比對：找不到的每一行，判定（搬到哪、或刪的理由）寫進設計文件 S2 底下
  6. **部署前乾跑**（根 CLAUDE.md「新增 Skill 步驟 3」，改寫與改 commands 都要）：在 `--force` 部署之前，①派 subagent 照 repo 改後的 `skills/dd-loop/SKILL.md`「段落起點」節與步驟 3、4 節做一遍，分支各跑一次（有 `docs/reviews/` 的第一次被擋；舊版 gate：從 git 歷史取沒有 `--start-segment` 的 `check-claude-md.sh` 掛進拋棄式 repo 的 hook）；②派 subagent 只讀 repo 的 `commands/dd-init.md` Phase 0、1，不寫檔，逐條引用原文回報卡住、猜測、互相矛盾的句子；①的會寫檔步驟在 scratchpad 拋棄式 repo 真的跑；Phase 1 的寫檔實跑留給部署後的測試清單 4
  7. `ruby -ryaml` 解析 ci.yml
  8. 新區塊寫完重量行數與字元，更新「為什麼要做」與 CHANGELOG 的數字
  9. **順序**：驗證 1–8 綠、乾跑沒有卡住的句子 → `cmp ~/.claude/CLAUDE.md templates/global/CLAUDE.md`（不同就先停下說明，`--force` 會覆蓋它）→ `./install-dd-pipeline.sh --force`（從工作目錄複製，不需先 commit；改了 SKILL.md、dd-init.md、清單，根 CLAUDE.md「新增 Skill 步驟 4」）→ `cmp` 比部署版與 repo 版（`~/.claude/commands/dd-init.md`、`~/.claude/scripts/dd-init-upgrade.sh`、`~/.claude/skills/dd-loop/SKILL.md`），不一致就中止 → 測試清單 4（用部署版跑）→ 綠了才 commit S2-2
- commit：`feat: dd-init 蓋章區塊改成短版、指向 dd-loop，舊區塊升級改用分類腳本，rev 跳 13（S2-2）`
- S2-2 實測（2026-10-30）：
  - 乾跑（部署前，2026-10-30）：SKILL.md 段落起點三分支實跑，抓到 8 處，修了 5 處（trailer 要跟 `Co-Authored-By` 同一段、「第一次一定被擋」改成有條件、補 SKIP 要 commit、舊版 gate 的徵兆與 grep 寫法、出路給 clone URL 並重跑 `--start-segment`）；
    沒修的 3 處是本段以前就有的文字（diff 檔第 ② 項看不到 simplifier 新增的未追蹤檔、沒有設計文件時 SKIP 理由寫哪、gate 擋下訊息沒講 trailer 不可隔空行），段落結束時回報。
    dd-init Phase 0、1 唯讀乾跑抓到 14 處，修了 12 處（列 `--plan` 全部節、重號步驟與重複小節要問、暫存檔改成專案根目錄的 `CLAUDE.md.dd-upgrade`、rev 比 13 大與 exit 1 的分支、差異清單從專案 rev 起累加等）；
    6step／7step 照舊由 agent 判斷、沒標記又不在 `## 開發流程` 底下的手寫流程認不出來，兩條照實寫明、不修
  - 測試清單 4（部署後，`docs/measurements/2026-10-30-dd-init-upgrade/`）：8 例全部照預期 —— 升級的 5 例都先 `--plan` 再 `--apply`、備份、標記剛好一個 rev 13、在地行留在原步驟、佔位都填掉；
    拒絕那例只跑 `--plan`、檔案逐字不變；rev 13 那例跳過不動；新建那例加了 React 段。合計 US$5.08。
    步驟 4 修正後重新部署、步驟 5 重跑一次（`results-after-review.txt`）：8 例結果相同，CLI 那例的 playwright 行與截圖子項都刪掉了；合計 US$5.16
  - 步驟 4（`docs/reviews/2026-10-30-global-claude-md-slim/S2-{a,b,c,judge}.md`）：3 份報告，採納 Important 8 條（含 1 條重疊）、Smell 2 條，Critical 0，全部修掉；升級腳本測試修後 40 ✅（BWK、mawk 1.3.4、gawk 5.3.2）
  - 測試 35 則 ✅（加了 rev 13 標記與「現行區塊跑一次不變」兩則）；變異重跑：空殼 33 ❌、a 9 ❌、b 10 ❌（明細在 `tests/CLAUDE.md`）
  - 新區塊 37 行、1,733 字元（`wc -m`，UTF-8）；rev 12 是 96 行、6,762 字元。React 片段放在區塊外的 ````markdown 圍欄
  - 驗證 5（舊區塊每個非空行到「新區塊 ∪ 全域 §3.9 與 §4.4 ∪ `skills/dd-loop/SKILL.md` ∪ React 片段」裡逐字找）：搬完後 53 行找不到，逐條判定如下
    （行的內容見 `git show v1.6.12:commands/dd-init.md`；比對指令：兩邊各去前後空白、`sort -u` 後 `comm -23`）
    - 已在 SKILL.md、只是斷行或全半形標點不同（同一句話換行位置不同就逐字比不到）：兩個擋點那段、`.git/` 不放證據、報告落地那整條、派工交事實、程式碼只有一行不是理由、主對話直接派、時間花在哪、步驟 7／8 的關係兩條、diff 檔四項、等全部回來才查證、附驗證輸出、需使用者決定、範圍要明講、沒有人工程式碼不派、hotfix、有進度表時的起點例外、起點檔不存在的但書、步驟 8 指令與 `$NF` 陷阱、`CODE_EXT` 不是閉環
    - 這次搬進 SKILL.md 的（原本只在區塊裡）：兩個擋點與「剛採用 `docs/reviews/` 第一次一定被擋」、舊版 gate 的處置、「實證：兩個都接受了錯的框架」、不寫附驗證輸出時「整組再跑一遍」、五發實測 2.3/3 對 1.8/3、不另派裁決者的數字、時間花在哪的數字、`CODE_EXT` 那句、「只跑 simplifier 就抓到」「補審又抓到一個新的錯宣稱」兩個實例
    - 由新區塊改寫取代：rev 12 的標記行、步驟 4、步驟 6、步驟 8 的舊寫法
    - 刪除：「步驟 3、4 寫 `<起點>` 會自動套用上面那條例外，只有這裡把指令寫死」（新區塊不再寫死指令，這句沒有對象）；「task-planner 的規則區塊沒寫明這條」（區塊不再講 task-planner）。半號段落 `S2.5` 那兩行原本判成刪除（理由「全域 §4.4 已有」），步驟 4 審查指出 §4.4 那條在「兩種 task 工具都沒有時」的引言區塊裡、讀起來有條件，改成搬進 SKILL.md「段落起點」節

#### 步驟 3、4 的做法

- 步驟 3：code-simplifier 只審腳本、測試與 ci.yml，不改搬過去的原文
- 步驟 4：至少 3 個 code-reviewer，其中一個專審「舊區塊搬移前後條件與指向有沒有掉」、一個專審分類腳本與測試
- 步驟 5：步驟 3、4 動到 `scripts/dd-init-upgrade.sh`、`commands/dd-init.md`、`skills/dd-loop/SKILL.md` 任一支時，依序：改到 SKILL.md 重跑驗證 6 ①、改到 dd-init.md Phase 0、1 重跑驗證 6 ②、改到 dd-init.md 或清單重跑驗證 2、4 → `cmp ~/.claude/CLAUDE.md templates/global/CLAUDE.md` → `./install-dd-pipeline.sh --force` → 三支 `cmp` 部署版與 repo 版、不一致就中止 → 重跑測試清單 1 與 4 → 綠了才進步驟 6 commit

#### 假設

- 腳本放 `scripts/`（部署到 `~/.claude/scripts/`，跟 gate 同一層），不放 `skills/dd-loop/`：它是 `/dd-init` 的工具，不是迴圈細則
- 範本行清單放在腳本 heredoc，不放 `commands/dd-init.md`：清單裡有舊版的 `dd-loop-rev: N` 標記行與 `## 開發流程` 行，放進 dd-init.md 會讓 CI 的「整份檔的 `dd-loop-rev: N` 只能有一種值」（`revs=` 那行）與「從 `^## 開發流程` 數編號項」（`count_block` 那行）兩道檢查誤判
- 不升級使用者現有的 11 個專案

### 要新增的測試清單

使用者選定（2026-10-30，「照這份清單加」）：S1 不新增 committed 測試。驗證用：

1. ci.yml 讀文件的既有 step 在本機跑
2. 搬移對照腳本（放 scratchpad，不進 repo）
3. subagent 照 SKILL.md 乾跑一段，加一個只讀專案文件的接手 agent
4. `claude -p` 觸發實測：正例 4 種（段落開始、做到一半接手、步驟 4 前、步驟 8 前）各 2 次，反例改 typo；去識別結果放 `docs/measurements/2026-10-30-dd-loop-trigger/` 當證據，不是 CI 測試

S2 使用者選定（2026-10-30，「照這份清單加」）：

1. `tests/test-dd-init-upgrade.sh`（新增，ubuntu 與 bash32 job 都跑，照 `test-gate.sh` 的慣例）。fixture 從 git 歷史抽各版範本區塊（v1.6.12 rev 12、v1.6.4 rev 9、6a9addd rev 2、v1.1.0 只有 8step），抽出來先確認非空。各插入自編在地內容：步驟 4、8 底下各一行、步驟 5 一段縮排的圍欄專案指令、`驗證不過` 之後一行、步驟外一個在地小節、一行逐字等於清單外通用行（`---`）的在地行。新區塊用 `--template` 指向 repo 的 `commands/dd-init.md`。斷言（獨立於腳本自己的清單）：
   - fixture 自編的每一行在地內容都出現在輸出，而且落在對應錨點底下
   - 該版範本的每一行（套用清單的排除條件），在新區塊以外出現 0 次（「保留但相似」列出的除外；「區塊外還有範本行」那則 fixture 不套這條，改斷言 `--plan` 列出那幾行）
   - 合併後只有一個 `dd-loop-version`、沒有重複的 `## 開發流程`
   - rental-management 型：起點是在地 `###`，標題保留、新區塊標題降級
   - 在地 `##` 夾在步驟 8 與 `驗證不過` 之間：`--plan` 列出「區塊外還有範本行」
   - 區塊後段的大段在地內容原地不動；「保留但相似」列得出一句改寫過的範本句
   - 純範本 fixture（零在地內容）：exit 0、整塊換新
   - 步驟 7 那行措辭被改過的 fixture：`--plan` 列在「疑似改寫過的步驟行」
   - `--plan` 輸出的各節標題與行號真的出現，並抽一筆行號用 `sed -n "<N>p"` 印出原檔那一行、與輸出的原文比對（防訊息字串寫壞、行號指錯）
   - React 圍欄改過一行的 fixture：`--plan` 列出「保留的圍欄裡有部分行在清單中」
   - exit 2（無標記）、3（只剩標題與標記可刪）、4（兩個標記）、5（`--apply` 自檢）
   - rev 13 的斷言（新區塊的標記是 rev 13）S2-2 才加
   - 先放空殼腳本，確認紅的是斷言；再做兩個變異（分類吃掉一行在地內容、終點提早停），比對固定版的完整輸出確認會紅
2. ci.yml 新 step「現行蓋章區塊的每一行都在升級清單裡」（S2-2）：做負面測試（改區塊一行不更新清單 → 紅；區塊抽取失效 → 紅；還原 → 綠），補進 `DD_PIPELINE_ARCHITECTURE.md` CI 防線表
3. 11 個已蓋章專案 CLAUDE.md 的複本跑 `--plan`（**只量測、不作驗收**；scratchpad，不進 repo，只記數字；順便數「在地行逐字等於清單裡、但不在 rev 12 區塊的行」「步驟 5 在地圍欄有沒有縮排」）
4. `--force` 部署、`cmp` 三支一致之後，在沙盒 repo 用 `claude -p --output-format stream-json` 跑部署版 `/dd-init` Phase 1（prompt 寫死「AskUserQuestion 那一步當作使用者回答『同意』（或『拒絕』）」）。從 jsonl 的 tool_use 紀錄核：①`dd-init-upgrade.sh … --plan` 出現在寫死的答案點之前 ②「同意」才有 `--apply`、「拒絕」沒有（不看 agent 自述）。每個「同意」類案例都斷言：`dd-loop-version` 數 = 1、`## 開發流程` 數 = 1（rental 型數降級後的標題）、rev 13 區塊的非空行扣掉佔位行全部出現在輸出裡。案例：
   - rev 12「同意」（非 React fixture）：輸出的標記是 rev 13；不含 rev 12 獨有的行（= `git show v1.6.12:commands/dd-init.md` 區塊的行減去 rev 13 區塊的行，照清單的排除條件，先斷言這個集合非空）；`grep -c '<依偵測結果填入'` 回 0；有呼叫 `--apply`
   - rev 12「拒絕」：`cmp` 前後相同、沒呼叫 `--apply`
   - rental-management 型一次
   - 帶 React 的升級一次、建立模式＋React 一次：「獨有行」集合扣掉 React 段；斷言 React 段的識別字串（`native value setter`）在步驟 5 底下、只出現一次
   - 純 CLI 專案 fixture：步驟 5 底下有具體驗證指令（不只是佔位數 = 0）
   - 步驟 5 已有具體 curl 指令的 fixture：該 curl 行出現次數 = 1，而且後端佔位行不在
   - rev 13 fixture：判現行版、不改檔

