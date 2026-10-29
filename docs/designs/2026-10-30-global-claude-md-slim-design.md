# 全域 CLAUDE.md 瘦身：8 步迴圈的「怎麼做」搬進 dd-loop skill

全域 CLAUDE.md（`templates/global/CLAUDE.md`，每個專案、每個 session 都載入）的 §3.9 開發迴圈佔約 36%，只有跑迴圈時用得到。
把做法細節搬進一個由規則明寫呼叫的 skill，全域只留清單、關卡與驗證教訓。

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | 新 skill dd-loop + 全域 §3.9 瘦身 | TODO | — | 全域模板行數與 bytes 下降（前後 `wc -lc`）；搬走的每一句在 `skills/dd-loop/SKILL.md` 找得到原文；`claude -p` 沙盒正例（段落開始、做到一半接手、步驟 4 前、步驟 8 前）jsonl 有 `Launching skill: dd-loop` 且 `permission_denials` 裡沒有 Skill；小改動反例不叫；§3.9 引用清單（A、B 兩組樣式）每筆都有判定；ci.yml 讀文件的 step 本機全 exit 0 | |
| S2 | /dd-init 蓋章區塊瘦身並跳 rev 12→13 | TODO | S1 | 待重規劃（見「段落與小任務」S2 的開工前提） | |

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
- S1-2 部署並實測 skill 會被叫起來
  - 檔案：`docs/measurements/2026-10-30-dd-loop-trigger/`（`*.prompt.txt`、去識別後的 jsonl 抽取結果、`run.sh`）
  - 驗證：`./install-dd-pipeline.sh --force` 後，拋棄式 repo 跑 `claude -p`，設定照根 `CLAUDE.md`「新增 Skill 步驟 5」整條抄（`--output-format stream-json --verbose --max-budget-usd 3 --no-session-persistence --permission-mode dontAsk --allowedTools "Skill Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent" < /dev/null`，另加 `--settings '{"advisorModel":""}'`，prompt 存成 `<名字>.prompt.txt`）。判定：`Launching skill: dd-loop` 有沒有出現，並列出所有 Skill 呼叫的順序（「照做」交給 S1-1 驗證 ⑤）。這只證明「會被叫」，不證明是明寫呼叫還是 description 比對；之後改 memory 措辭只寫「會被叫起來」。三個情境：正例「做一段功能」、正例「進度表上 IN_PROGRESS 段落做到一半（同 ⑤ 的 fixture），接著做步驟 3」都要出現 `Launching skill: dd-loop`；另加兩個正例「小任務都 commit 完，接著做步驟 4」「接著做步驟 8」也要出現；反例「改一個 typo」不出現；順手記 jsonl 裡 Skill 呼叫次數與注入量；與附錄 A「--allowedTools 含 Skill 與寫檔工具」不同：這裡照專案規則把寫檔工具列進 disallow，因為只測「叫不叫」，判定改成「permission_denials 裡沒有 Skill」；正例各跑 2 次；Skill 注入量從 jsonl 的 Skill tool_result 內容長度取，若一段 4 次注入的總量超過全域省下的量，就在報告如實寫出、不再宣稱 context 有好處。stream-json 進 repo 前照根 CLAUDE.md 那條去識別（只抽判定欄位）
  - commit：`test: 實測 dd-loop 在段落開始時被叫起來（S1-2）`

### S2 /dd-init 蓋章區塊瘦身並跳 rev 12→13

- **開工前提**：先重新規劃並送 plan-review（使用者決定）。下面的 S2 草稿是確認輪 3C 不通過後的改稿，未經審查，只當重規劃的起點，不可照做。重規劃時一併處理 3C 範圍外小事：rental-management 沒有 `## 開發流程` 標題（Phase 1 會在末尾再加一份區塊）

- S2-1 蓋章區塊縮成專案具體版，跳 rev
  - 檔案：`commands/dd-init.md`（蓋章區塊；兩處 `dd-loop-rev`；「舊版/手寫版」判定線；「列出與現行版的差異」加 rev 13 一句）、`UPGRADING.md`（「判定為舊版」那行的 rev）、`CHANGELOG.md`
  - 檔案另含 `skills/dd-loop/SKILL.md`（起點擋點、CODE_EXT 等搬進來）、`UPGRADING.md:70–71`（「專案自己加的內容會保留」照新規則核對）、`commands/dd-init.md:323`（區塊外「逐層往上堆疊更新是 §3.9 的工作流規則」改指向）、`scripts/CLAUDE.md:44–52`（「區塊內：步驟 8 的範圍指令寫死…得跳 dd-loop-rev」在搬出後不成立，改寫）
  - 引用蓋章區塊內容的地方清點：`git grep -n -E '蓋章區塊|區塊內|dd-loop-rev|步驟 [348] 的'`（排除條件同 S1 的 A 組），逐筆判定寫進設計文件
  - Phase 1 升級指示（rev ≤12 與只有 `8step` 的舊版 → 13，第一次「減法」升級），以**行**對照新舊範本內容判，不看位置：
    - 範本段落完整清單（整段換新、不保留）：`## 開發流程` 標題行、`dd-loop-version` 標記行、起點段落、8 個編號步驟、`驗證不過` 那行、範本自帶的 `## CLAUDE.md 維護` 小節
    - 判準：區塊內凡是「任何一版範本文字」的行就換新；不是任何一版範本文字的行一律保留（不只靠「含識別符」判），放回新區塊**同一步驟底下**；步驟外的在地小節放在新區塊末尾。圍欄與它包住的指令整塊一起判
    - 舊細則歸零檢查只套在「被判成範本、已換新」的範圍，保留下來的在地行不列入。識別字串用各舊版範本的整句（例如 v1.6.4 區塊的「派兩個 reviewer 跑同一份 prompt，報告取聯集」、6a9addd 區塊的 `git status --porcelain | awk '{print $NF}'` 那行），不用 `報告一律落地`、`diff 檔` 這種一般詞；檢查前先確認每個字串在對應 fixture 升級前 ≥1
    - 「列出與現行版的差異」的 rev 12 那句如實寫出換掉的範圍（標題、標記、起點段落、8 步的子項、驗證不過、CLAUDE.md 維護小節），並寫「不是範本文字的行會保留在原步驟底下」；AskUserQuestion 之前先列出「將刪除的行」，清單是空的就當成異常回報、不升級
  - 蓋章區塊留：`## 開發流程` 標題、rev 標記、呼叫 `dd-loop` 的時機（照全域：段落開始、步驟 3、4、8 前一律呼叫）、`--start-segment` 一行、8 個編號步驟（CI 從 `^## 開發流程` 數到 `^驗證不過`）、步驟 5 的 `<依偵測結果填入>` 驗證指令、截圖路徑、`驗證不過` 那行；8 個編號步驟各帶與全域相同的關卡；「呼叫 dd-loop」旁加後備句「沒有這個 skill 時，細則見 claude-dd repo 的 `skills/dd-loop/SKILL.md`」（區塊進專案版控，協作者未必裝 claude-dd，見 `commands/dd-init.md:165`）
  - 只在區塊裡有、全域與 skill 都沒有的內容逐項定去處（清單以驗證 ② 實際比對結果為準；已知另有「不要把它寫成閉環」「CODE_EXT」「只有這裡把指令寫死」「時間花在哪」「不另派裁決者」，各寫搬進 skill 或刪掉的理由）：起點兩個擋點與舊版 gate 處置（:56–69）→ 搬進 skill；React 驗證法（:113–124）→ 留在步驟 5 底下當專案驗證指令；`## CLAUDE.md 維護` 小節（:140–148，含 :142「每個有程式碼的資料夾都要有 CLAUDE.md」）→ 留在區塊（專案具體規則）
  - 驗收另加：區塊內沒有第 0 欄的 ``` 圍欄
  - 驗證：① ci.yml 跳號檢查與四方一致本機綠；②把舊區塊每個非空行在「新區塊 ∪ 全域 §3.9 ∪ SKILL.md」裡找，印出找不到的行逐條判；本機跑 ci.yml 的 stamp step 時把它寫的 `/tmp/dd-init-tagged.md` 等路徑改到 scratchpad；③照根 CLAUDE.md「新增 Command 步驟」派 subagent 在沙盒 repo 照 **repo 的** `commands/dd-init.md` 做一遍（若改用 `claude -p` 跑 `/dd-init`，先重跑 `--force` 部署新版）。測試檔不手寫，fixture 從各版 `commands/dd-init.md` 用 stamp 抽法取出範本區塊（zsh 下寫 `git show "${t}:commands/dd-init.md"`）：rev 12（`v1.6.12`）、rev 9（`v1.6.4`）、rev 2（`6a9addd`，`awk '{print $NF}'` 當指令寫）、只有 8step 沒有 rev（`v1.1.0`）、rev 13（現行版，確認跳過、不改檔）。每個舊版 fixture 插入自編在地內容：步驟 4、步驟 8 底下各一行沒有識別符的規則、步驟 5 一段帶圍欄的專案指令、步驟外一個在地小節，其中至少一個在地小節故意含一個舊版識別字串。subagent 以「同意」作答跑一次，機械核對：①`diff` 升級前後，被刪掉的行是「將刪除的行」清單的子集；②在地行留在原本那一步底下；③範本換新範圍內的舊識別字串為 0，在地小節那個仍在；④沒有重複標題、只有一個 rev 標記；⑤區塊含「呼叫 dd-loop」。再以「拒絕」作答跑一次 rev 12 那份，確認區塊原樣保留
  - commit：`feat: dd-init 蓋章區塊改成專案具體版、指向 dd-loop，rev 跳 13（S2-1）`

### 要新增的測試清單

使用者選定（2026-10-30，「照這份清單加」）：S1 不新增 committed 測試。驗證用：

1. ci.yml 讀文件的既有 step 在本機跑
2. 搬移對照腳本（放 scratchpad，不進 repo）
3. subagent 照 SKILL.md 乾跑一段，加一個只讀專案文件的接手 agent
4. `claude -p` 觸發實測：正例 4 種（段落開始、做到一半接手、步驟 4 前、步驟 8 前）各 2 次，反例改 typo；去識別結果放 `docs/measurements/2026-10-30-dd-loop-trigger/` 當證據，不是 CI 測試

S2 的測試清單在重規劃時另定。

