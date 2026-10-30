#!/bin/bash
# /dd-init 的升級分類：專案 CLAUDE.md 裡的舊版蓋章區塊，逐行分成「範本原文」與「專案自己加的內容」，
# 範本原文換成現行範本區塊，自己加的內容原樣放回新區塊的同一步底下。
#
# 用法：
#   dd-init-upgrade.sh [--template <dd-init.md>] --plan <CLAUDE.md>
#   dd-init-upgrade.sh [--template <dd-init.md>] --apply <CLAUDE.md> <輸出路徑>
#   dd-init-upgrade.sh --list
# --template 預設 ~/.claude/commands/dd-init.md（取其中 ```markdown 到下一個 ``` 之間的蓋章區塊，同 ci.yml 的 stamp()）。
# 三個模式都不改原檔：--plan 只印分類結果，--apply 把合併後的完整檔寫到輸出路徑，取代原檔由 /dd-init Phase 1 在使用者同意後做。
#
# exit：0 正常；1 用法錯或讀不到範本；2 找不到 dd-loop-version 標記；3 可刪的行扣掉標題與標記是 0
#       （清單過期或區塊被整份改寫，不升級）；4 一檔有兩個以上標記；5 --apply 自檢失敗（輸出的標記不是剛好一個，不寫檔）
#
# 判法：區塊裡的行去前後空白後，逐字等於下方清單某一行 → 範本原文；不等於 → 在地內容。標記行一律算範本。
# 圍欄（``` 開到 ``` 關）整塊算一個單位，裡面每一行都在清單裡才算範本。
# 被改寫過措辭的範本句不會被認出來、會被保留（多留、不會少），--plan 另列「保留、但與範本某行相似」給人看。
#
# 清單 = 帶 dd-loop-version 標記的歷代蓋章區塊的每一行（去前後空白），排除空行、`---`、單獨的圍欄行。
# 改了蓋章區塊就要把新的行加進來（CI「現行蓋章區塊的每一行都在升級清單裡」會擋）。重新產生：在 claude-dd repo 根目錄用 bash 跑
#   for t in $(git log --format=%h -- commands/dd-init.md); do
#     b=$(git show "${t}:commands/dd-init.md" | awk '/^```markdown$/ && !f {f=1; next} f && /^```$/ {exit} f')
#     case "$b" in *dd-loop-version*) printf '%s\n' "$b" ;; esac
#   done | LC_ALL=C sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
#     | LC_ALL=C grep -v -e '^$' -e '^---$' -e '^```[A-Za-z]*$' | LC_ALL=C sort -u
# （zsh 下 "$t:commands" 的 :c 會被當成修飾詞，一定要寫 "${t}:…" 或用 bash 跑）
# 另外要有 commands/dd-init.md 裡 ````markdown 那段 React 片段的行（它在區塊外，Phase 1 偵測到 React 才補進區塊），
# 上面的指令抓不到它；目前的內容跟舊版區塊裡的那段相同，所以已經在清單裡。
set -e

list_lines() {
cat <<'__DD_TEMPLATE_LINES__'
## CLAUDE.md 維護
## 開發流程（每個功能段落依序走）
## 開發流程（每個功能段落必走，不可省略）
**gate 只擋改碼的那一層**（缺 CLAUDE.md 或沒同批更新）；往上逐層堆疊是這裡的工作流規則，
**hotfix 段落通常正是人工判斷最密的地方。**
**判斷有沒有真的送出，看後端有沒有收到請求，不是看畫面。**
**判斷有沒有真的送出，看後端有沒有收到請求，不是看畫面。** 拿不到後端 log 時，
**報告一律落地成 committed 檔，跳過要申報**（檔名、格式、SKIP 的寫法見 `dd-loop`）
**有進度表時 `--segment-base` 不是最終答案**：專案有 `task-planner` 產的進度表（根目錄 CLAUDE.md 開頭的指路句會寫明檔名，通常在 `docs/designs/`）時，
**段落開始時、以及步驟 3、4、8 開始前，先呼叫 Skill `dd-loop`**，每次都叫。叫不到時（沒裝 claude-dd，或裝的是還沒有這個 skill 的舊版），
**註解與文件裡的宣稱**,不是運算式。實測某段只跑 simplifier 就抓到一句「作者自稱查證過
- **主對話直接派審查者**：在同一則訊息裡平行派審查者（`subagent_type: "code-reviewer"`，不帶 model 參數、不換 haiku）**最少 3 個**（設定的下限），實際數量自己定並寫理由；**先派工、派完自己讀 diff 檔**；在派工 prompt 寫明審查者職責：找漏洞、每條附證據、沒證據不算。某個審查者沒回來 → 補派，補不了就照實寫進報告。一發只挖到一部分（實測同一段 diff 五發，每發都只命中 3 個已知錯誤中的 2 個、子集還不同；兩發聯集平均 2.3/3 對單發 1.8/3）
- **主對話直接派審查者**：在同一則訊息裡平行派審查者（`subagent_type: "code-reviewer"`，不帶 model 參數、不換 haiku）**最少 3 個**（設定的下限），實際數量自己定，理由寫進 `-judge.md` 的派工節；**先派工、派完自己讀 diff 檔**；在派工 prompt 寫明審查者職責：找漏洞、每條附證據、沒證據不算。某個審查者沒回來或報告不完整 → 補派，補不了就照實寫進報告；收回的完整報告少於 3 份 → 不算跑過步驟 4，照實說，不續行。一發只挖到一部分（實測同一段 diff 五發，每發都只命中 3 個已知錯誤中的 2 個、子集還不同；兩發聯集平均 2.3/3 對單發 1.8/3）
- **兩份報告講不一樣時用讀程式碼判定，不要表決**：被某一發判成「既有問題、不是這次引入的」而丟進 Not reported 的項目，自己回去看那幾行（實測踩過：那個錯誤寫法正是這次 diff 複製進新路徑的）
- **想讓它快就界定探索預算，不是改派送方式**：實測派送管線只佔 ~25s，時間由它跑幾次工具決定（3–5 次 = 2–4 分、21/26 次 = 13–17 分）。prompt 寫明「最多做一次重現實驗」，或「需要外部查證的列出來交回、不要自己去抓」
- **時間花在哪**：實測派送管線只佔 ~25s，時間由它跑幾次工具決定（3–5 次 = 2–4 分、21/26 次 = 13–17 分）。prompt 寫明「需要外部查證的列出來交回、不要自己去抓」；不設工具次數上限（砍上限會連查證一起砍）
- **步驟 7 跳過不代表步驟 8 跳過**：步驟 2、6 被 gate 逼著更新的 CLAUDE.md
- **派兩個 reviewer 跑同一份 prompt，報告取聯集**：單發只挖到一部分（實測同一段 diff 五發，每發都只命中 3 個已知錯誤中的 2 個、子集還不同；兩發聯集平均 2.3/3 對單發 1.8/3）。成本 ×2，並行跑 wall 幾乎不變
- **派兩個 reviewer 跑同一份 prompt，報告取聯集**：單發只挖到一部分（實測同一段 diff 五發，每發都只命中 3 個已知錯誤中的 2 個、子集還不同；兩發聯集平均 2.3/3 對單發 1.8/3）。成本 ×2；並行派時 wall 約等於較慢那一發（實測：同一則訊息派兩個，781s 與 1007s，整體 ~1007s）
- **派兩個 reviewer 跑同一份 prompt，報告取聯集**：單發只挖到一部分（實測同一段 diff 五發，每發都只命中 3 個已知錯誤中的 2 個、子集還不同；兩發聯集平均 2.3/3 對單發 1.8/3）。成本 ×2；並行派時 wall 約等於較慢那一發（未實測的推論）
- **派工前先準備一個 diff 檔**（放 scratchpad）：①整段 diff（依序跑時 `git diff <起點>` 加未追蹤新檔，與步驟 3 並行時 `git diff <起點> HEAD`）；②步驟 3 自己改了什麼（依序跑時 `git diff HEAD`，分開附 —— simplifier 改了行為正是要抓的）；③**派工當下**被改到檔案的整檔內容（依序取工作目錄版本，另把未追蹤新檔放整檔；並行取 `HEAD` 版本，因為 simplifier 正在改工作目錄）；④已跑過的驗證輸出，**連同預期值一起寫**（「已確認」只代表跑過，不代表結果對）。被改到的檔，審查者與主對話一律讀 diff 檔裡那一份、不讀工作目錄；diff 檔用 Read 的 `offset`／`limit` 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯，約 47 KB 就停），這句也寫進給審查者的 prompt
- **派工前先準備一個 diff 檔**（放 scratchpad）：①整段 diff（依序跑時 `git diff <起點>` 加未追蹤新檔，與步驟 3 並行時 `git diff <起點> HEAD`）；②步驟 3 自己改了什麼（依序跑時 `git diff HEAD`，分開附 —— simplifier 改了行為正是要抓的）；③**派工當下**被改到檔案的整檔內容（依序取工作目錄版本，另把未追蹤新檔放整檔；並行取 `HEAD` 版本，因為 simplifier 正在改工作目錄）；④已跑過的驗證輸出，**連同預期值一起寫**（「已確認」只代表跑過，不代表結果對）。被改到的檔，審查者與裁決者一律讀 diff 檔裡那一份、不讀工作目錄
- **派工前先準備一個 diff 檔**（放 scratchpad）：整段 diff（依序跑時 `git diff <起點>` 加未追蹤新檔，與步驟 3 並行時 `git diff <起點> HEAD`）、**派工當下**被改到檔案的整檔內容（依序取工作目錄版本；並行取 `HEAD` 版本，因為 simplifier 正在改工作目錄；未追蹤新檔放整檔）、上面那條要附的驗證輸出。被改到的檔，審查者與裁決者一律讀 diff 檔裡那一份、不讀工作目錄
- **由裁決者派審查者**：派一個裁決者（`general-purpose`、`model: "opus"`），它平行派審查者（`subagent_type: "code-reviewer"`）**最少 3 個**，數量自己定並寫理由；在派工 prompt 寫明審查者職責：找漏洞、每條附證據、沒證據不算。一發只挖到一部分（實測同一段 diff 五發，每發都只命中 3 個已知錯誤中的 2 個、子集還不同；兩發聯集平均 2.3/3 對單發 1.8/3）
- **由裁決者派審查者**：派一個裁決者（`general-purpose`、`model: "opus"`），它平行派審查者（`subagent_type: "code-reviewer"`，不帶 model 參數、不換 haiku）**最少 3 個**（設定的下限），實際數量裁決者自己定並寫理由；在派工 prompt 寫明審查者職責：找漏洞、每條附證據、沒證據不算。某個審查者沒回來 → 裁決者補派，補不了就照實寫進報告。一發只挖到一部分（實測同一段 diff 五發，每發都只命中 3 個已知錯誤中的 2 個、子集還不同；兩發聯集平均 2.3/3 對單發 1.8/3）
- **等全部審查者回來才查證**：每個審查者的完整報告（含 Not reported、What I ran）一回來就逐字存進 scratchpad 檔。逐條讀程式碼查證：採納 / 駁回 / 需使用者決定。採納項沿用審查者的級別，調級要寫理由；採納的 Critical / Important 修掉才續行，Smells 照改不擋。審查者講不一樣時讀程式碼判定、不表決；被判成「既有問題」丟進 Not reported 的，回去看那幾行（實測踩過：那個錯誤寫法正是這次 diff 複製進新路徑的）。審查者列的外部查證項，能查就查，查不了另列「需要外部查證」。有審查者的報告不完整又補不了 → 不算跑過步驟 4，照實說，不續行
- **等全部審查者回來才查證**：派工 prompt 派出時、每個審查者的完整報告（含 Not reported、What I ran）一回來，都逐字存進 scratchpad 檔。逐條讀程式碼查證（預設「這條可能是錯的」；查證的人就是寫 diff 的人，要駁回就讀程式碼證明）：採納 / 駁回 / 需使用者決定。採納項沿用審查者的級別，調級要寫理由；採納的 Critical / Important 修掉才續行，Smells 照改不擋。審查者講不一樣時讀程式碼判定、不表決；被判成「既有問題」丟進 Not reported 的，回去看那幾行（實測踩過：那個錯誤寫法正是這次 diff 複製進新路徑的）。審查者列的外部查證項，能查就查，查不了另列「需要外部查證」
- **裁決者等全部審查者回來，逐條讀程式碼查證**：採納 / 駁回 / 需使用者決定。採納項沿用審查者的級別，調級要寫理由；採納的 Critical / Important 修掉才續行，Smells 照改不擋。審查者講不一樣時讀程式碼判定、不表決；被判成「既有問題」丟進 Not reported 的，裁決者回去看那幾行（實測踩過：那個錯誤寫法正是這次 diff 複製進新路徑的）。審查者列的外部查證項，裁決者能查就查，查不了另列「需要外部查證」交回。裁決者把每個審查者的完整報告（含 Not reported、What I ran）逐字寫進 scratchpad 檔並交回路徑，連同它給審查者的派工 prompt；裁決者沒回來或報告不完整 → 不算跑過步驟 4，照實說，不續行
- **裁決者等全部審查者回來，逐條讀程式碼查證**：採納 / 駁回 / 需使用者決定。採納項沿用審查者的級別，調級要寫理由；採納的 Critical / Important 修掉才續行，Smells 照改不擋。審查者講不一樣時讀程式碼判定、不表決；被判成「既有問題」丟進 Not reported 的，裁決者回去看那幾行（實測踩過：那個錯誤寫法正是這次 diff 複製進新路徑的）。裁決者把每個審查者的完整報告逐字寫進 scratchpad 檔並交回路徑；沒回來或報告不完整 → 不算跑過步驟 4，照實說
- <依偵測結果填入：curl 打真實 API 驗證後端邏輯（登入/CRUD/權限…）>
- <依偵測結果填入：playwright 真的開瀏覽器登入、操作 UI、截圖驗證前端可用>
- prompt 要附上步驟 1（重跑時加步驟 5）已跑過的驗證輸出，明寫「已確認，不要重跑」，否則它會把測試、build、渲染指令整組再跑一遍
- ⚠️ **React 專案**：`browser_click` / `browser_fill_form` 常常不觸發 onClick 與
- ⚠️ **「程式碼只有一行 / 定義域全被測試覆蓋」不是合法的跳過理由**:review 真正抓的是
- ⚠️ **兩份報告落地成 committed 檔(`docs/reviews/S<段落>-{a,b}.md`,三節:派工/發現/處置),
- ⚠️ **半號段落(`S2.5`)有自己的 commit 且改了人工邏輯 → 算新段落,要走步驟 3–8**;
- ⚠️ **報告落地成 committed 檔(每個審查者一份 `docs/reviews/S<段落>-a.md`、`-b.md`、`-c.md`…,加查證 `S<段落>-judge.md`(檔名沿用,內容是主對話的查證);各三節:派工/發現/處置 —— 審查者那幾份的派工照給它的派工 prompt、發現放逐字原文、處置由主對話寫;重疊與獨有項寫進 `-judge.md`),
- ⚠️ **報告落地成 committed 檔(每個審查者一份 `docs/reviews/S<段落>-a.md`、`-b.md`、`-c.md`…,加裁決 `S<段落>-judge.md`;各三節:派工/發現/處置 —— 審查者那幾份的派工照裁決者交回的派工 prompt、發現放逐字原文、處置由主對話寫;重疊與獨有項寫進 `-judge.md`),
- ⚠️ **報告落地成 committed 檔(每個審查者一份 `docs/reviews/S<段落>-a.md`、`-b.md`、`-c.md`…,加裁決 `S<段落>-judge.md`;各三節:派工/發現/處置),
- ⚠️⚠️ **派工的 prompt 交事實（行號、數字、實測輸出），不要交「我判斷元凶是 X」** ——
- 不另派裁決者：2026-10-24 實測主對話（Opus）直接派平均 269s、US$5.13、命中 4/6，另派 Opus 裁決者 350s、US$3.83、命中 3/6（直接派比較貴；n 小、同時改了三件事，只是方向）
- 不另派裁決者：2026-10-24 實測主對話（Opus）直接派平均 269s、命中 4/6，另派 Opus 裁決者 350s、命中 3/6（n 小、同時改了三件事，只是方向）
- 功能落地後，受影響目錄的 CLAUDE.md 逐層堆疊更新（用 claude-md-management plugin 的 /revise-claude-md 或手動）
- 功能落地後，受影響目錄的 CLAUDE.md 逐層堆疊更新（程式碼改了 → 文件跟著改）。
- 功能落地後，受影響目錄的 CLAUDE.md 逐層堆疊更新（程式碼改了 → 文件跟著改，pre-commit gate 會擋）
- 截圖一律存 `.screenshots/`（已 gitignore）；勿丟專案根目錄
- 步驟 7 處理的是「本輪學到什麼」，與上一條的「程式碼改了所以文件要同步」是兩件事
- 步驟 7 處理的是「本輪學到什麼」，與上一條的「程式碼改了所以文件要同步」是兩件事；
- 每個有程式碼的資料夾都要有 CLAUDE.md（說明該層職責與慣例）
- 發現若是「行為變了，但**無從判定哪個才是預期**」（程式碼、測試、文件都沒寫明語意），**用 AskUserQuestion 把選擇交回使用者**，
- 範圍要明講給 reviewer：依序跑時 `git diff <起點>` 加上 `git ls-files --others --exclude-standard`（步驟 3 新增、還沒 commit 的檔案 `git diff` 看不到）
- 與步驟 3 並行時用 `git diff <起點> HEAD`，並要求 reviewer 一律用 `git show HEAD:<路徑>` 取檔案、不讀工作目錄（simplifier 正在改，讀到一半會被換掉）
- 這段沒有「人工寫的程式碼」（diff 全是資料／設定／註解／文件，或改動已被專案的機械檢查完全覆蓋）就不派 agent，
- 重跑步驟 1 的相關測試
1. **實作功能 + 首輪測試通過**（相關既有測試跑綠 + 基本手動驗證，不可帶紅燈進 commit）
2. **commit**（第一次 — 保留簡化前還原點）
3. 跑 **code-simplifier**（對該段新增/修改的程式碼，官方 agent）
3. 跑 **code-simplifier**（對該段新增/修改的程式碼：`git diff <起點>`，官方 agent）
4. 跑 **code-review**（該段 diff，每段全量跑；修掉 Critical/Important 才續行）
4. 跑 **code-review**（該段 diff：`git diff <起點>`，範圍要明講給 reviewer；每段全量跑；修掉 Critical/Important 才續行）
4. 跑 **code-review**（該段 diff；每段全量跑，例外見 `dd-loop`；修掉 Critical/Important 才續行）。
4. 跑 **code-review**（該段 diff；每段全量跑，例外見下；修掉 Critical/Important 才續行）
4. 跑 **code-review**（該段 diff；每段全量跑；修掉 Critical/Important 才續行）
5. **再測一次** — 確認步驟 3、4 沒破壞行為，不可只跑單元測試：
6. **再 commit**（最終版本）
6. **再 commit**（最終版本；gate 必須全過，不可用 SKIP 繞過）
7. **沉澱本輪學到的**（有才做）— 本輪若留下踩雷、指令或慣例，用
7. **沉澱本輪所學**（有才做）— 本輪若留下踩雷、指令或慣例，用
8. **評分 & 修正本輪動過的 CLAUDE.md** — 第一個動作是算範圍，不是開始審。
8. **評分 & 修正本輪動過的 CLAUDE.md** — 第一個動作是算範圍，不是開始審（指令見 `dd-loop`）。
8. **評分 & 修正本輪動過的 CLAUDE.md** — 第一個動作是算範圍，不是開始審：
<!-- dd-loop-version: 6step；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 10；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 11；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 12；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 13；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 2；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 3；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 4；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 5；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 6；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 7；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 8；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；dd-loop-rev: 9；供 /dd-init 判斷是否提議升級，勿刪 -->
<!-- dd-loop-version: 8step；供 /dd-init 判斷是否提議升級，勿刪 -->
UI 字串 / commit 範圍的敘述,就不是「只有一個運算式」—— 補審在那段的「修正版」裡
`<起點>` 以**表上這段 commits 欄的起點**為準。回頭做 `BLOCKED` 過的段落時兩者會不一樣 —— 中間插做別段會把 `--segment-base` 往後推，
`base=$(~/.claude/scripts/check-claude-md.sh --segment-base) && [ -n "$base" ] && { git -c core.quotePath=false diff --name-only "$base" HEAD; git -c core.quotePath=false diff --name-only HEAD; git -c core.quotePath=false ls-files --others --exclude-standard; } | grep 'CLAUDE\.md$' | sort -u`
`base=$(~/.claude/scripts/check-claude-md.sh --segment-base) && [ -n "$base" ] && { git -c core.quotePath=false diff --name-only "$base" HEAD; git -c core.quotePath=false status --porcelain -uall | awk '{print $NF}'; } | grep 'CLAUDE\.md$' | sort -u`
`base=$(~/.claude/scripts/check-claude-md.sh --segment-base) && { git diff --name-only "$base" HEAD; git status --porcelain | awk '{print $NF}'; } | grep 'CLAUDE\.md$' | sort -u`
`input`，否則 React 讀不到值：
`performance.getEntriesByType('resource').filter(r => r.name.includes('/api/x')).length`
`task-planner` 的規則區塊沒寫明這條,而那份規則是照抄進設計文件、不跟著 skill 更新的。
`{ git show --name-only --pretty=format: HEAD; git status --porcelain | awk '{print $NF}'; } | grep 'CLAUDE\.md$' | sort -u`
`~/.claude/scripts/check-claude-md.sh --segment-base` 的輸出（exit 非 0 或輸出是空的 = 範圍沒算出來，不是範圍為空）。其餘情況見 `dd-loop`。
claude-md-management plugin 的 /revise-claude-md 寫進 CLAUDE.md；
const set = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
gate 不會強制它存在 —— 不要把它寫成閉環。
gate 不檢查，上層過期不會有任何訊號
git 會加引號，`$NF` 切開後比對不到，少列一份卻照樣 exit 0 不報錯
pre-commit 不會強制它存在(只在開下一段時查,而且只查「有沒有新增任何一份」)—— 不要把它寫成閉環。
set.call(el, v); el.dispatchEvent(new Event('input', { bubbles: true }));
②**專案有 `docs/reviews/` 目錄時**（= 採用了 review 留痕慣例），上一段的 commit 範圍內
②最貴(13–17 分鐘 ×2)③跳過條款就寫在上面。**而它一跳,步驟 7 就沒東西可寫 ——
②最貴(至少 3 個審查者)③跳過條款就寫在上面。**而它一跳,步驟 7 就沒東西可寫 ——
②最貴(至少 3 個審查者加一個裁決者)③跳過條款就寫在上面。**而它一跳,步驟 7 就沒東西可寫 ——
⚠️ **這個指令有兩個擋點**：①起點以來有 `SKIP_DOC_CHECK=1` 欠下、還沒補的 CLAUDE.md
⚠️ 判準用「**有沒有引別處**」而不是「程式碼幾行」:diff 裡只要有引別處行號 / 函式 /
⚠️ 目的是**拿掉「靜默省略」這個選項**,不是讓說謊變不可能;`.md` 不在 gate 的 `CODE_EXT` 裡,
⚠️ 證據**不可以放 `.git/`**(`dd-segment-base` 走 `git rev-parse --git-path`、不進版控)。
一段常有好幾個 commit，步驟 3、4、8 都看「起點到現在」的整段；`<起點>` = `~/.claude/scripts/check-claude-md.sh --segment-base` 的輸出
一段常有好幾個 commit，步驟 3、4、8 都看「起點到現在」的整段；`<起點>` = `~/.claude/scripts/check-claude-md.sh --segment-base` 的輸出。
下文的 `<起點>`：有 `task-planner` 進度表時以**表上這段 commits 欄的起點**為準（只取 `..` 前面那段）；沒有進度表時是
下面這行是**沒有進度表**時的寫法；有進度表時 `base` 改填表上這段 commits 欄的起點
不先算範圍會全 repo 掃。範圍是空的才跳過
不先算範圍會全 repo 掃。範圍是空的才跳過（指令 exit 非 0 是範圍沒算出來，不算空）
不先算範圍會全 repo 掃。範圍是空的才跳過（指令 exit 非 0 是範圍沒算出來，不算空）。
不要自己選一邊也不要讓 reviewer 選 —— 查證時標成「需使用者決定」（附選項與建議答案）再問。金額、權限、資料保留期這類決定選錯了不會報錯，只會靜靜地錯下去
不要自己選一邊也不要讓 reviewer 選 —— 裁決者標成「需使用者決定」（附選項與建議答案），由主對話問。金額、權限、資料保留期這類決定選錯了不會報錯，只會靜靜地錯下去
不要自己選一邊也不要讓 reviewer 選 —— 裁決者標成「需使用者決定」，由主對話問。金額、權限、資料保留期這類決定選錯了不會報錯，只會靜靜地錯下去
不要自己選一邊也不要讓 reviewer 選。金額、權限、資料保留期這類決定選錯了不會報錯，只會靜靜地錯下去
也要進步驟 8 的範圍 — gate 只確認「有寫」、不確認「寫得對」
什麼都沒印 = 舊版 gate，到 claude-dd repo 跑 `./install-dd-pipeline.sh --force`）。
但這只在起點檔已經存在時成立：從沒跑過 `--start-segment` 的專案要等第一個 `SKIP_DOC_CHECK=1` commit 才會自動補記，
先到 claude-dd repo 跑 `git pull && ./install-dd-pipeline.sh --force`。
判準是**「這段有沒有正確性還沒被機械檢查證明的人工判斷」，不是 diff 多長**
剛採用第二個慣例時第一次一定會被擋（上一段本來就沒報告），補一份 `S<N>-SKIP.md` 即可。
卻仍然錯」的宣稱;下一段同等規模的改動,兩個 reviewer 抓出 2 個 Critical。
又抓到一個新的錯宣稱,而 playwright 攔 request body 看不到這一類東西。
受控輸入（工具回報成功但畫面 state 沒變，照著它的回報就會宣稱「測過了」其實沒點到）。
只是補檔進同一個 commit、或純文件/資料改動,才算前一段的小任務。
各步的做法細則（段落起點與 `<起點>` 怎麼算、步驟 4 怎麼派工與報告落地、步驟 8 怎麼算範圍）在 `dd-loop` skill：
在瀏覽器裡數請求數也算數（驗「前端擋下來、根本沒送出」特別好用）：
它是唯一可跳過、也是唯一會回問你的步驟
它會先列出建議、等你同意才寫檔。沒有值得留的就跳過
後兩條抓「還沒 commit 的」；**不要改用 `status --porcelain -uall | awk '{print $NF}'`** —— 含空白的路徑
掉的一步:①不留痕(跑完什麼都不產生,進度表標 `DONE` 是同一個 agent 自己填的,等於自證)
改成自己逐條核對、在回報附證據，理由寫進設計文件「段落與小任務」該段底下。
改成自己逐條核對、在回報附證據，理由寫進設計文件「段落與小任務」該段底下（沒有設計文件就寫在回報裡）。
改成自己逐條核對、在回報附證據，理由寫進設計文件「段落與小任務」該段底下（沒有設計文件就寫在回報裡）；有 `docs/reviews/` 時另建 `docs/reviews/S<段落>-SKIP.md`（見下方報告落地那條）。
改用 `browser_evaluate` 直接操作 DOM；填欄位要用 native value setter 再 dispatch
段落開始前先記起點：`~/.claude/scripts/check-claude-md.sh --start-segment`（要印出「段落起點：…」才算記好；
段落開始前先記起點：`~/.claude/scripts/check-claude-md.sh --start-segment`，印出「段落起點：…」才算記好。
段落開始前先記起點：`~/.claude/scripts/check-claude-md.sh --start-segment`，印出「段落起點：…」才算記好；被擋下時照它印的做，不要繞過。
沒印出這行就是沒記好；若是舊版 gate（grep 不到 `--start-segment`），它會照常檢查 staged，印出「commit 已擋下」也不要照著補檔或 commit，
沒有新增 `docs/reviews/S*.md`。兩者都會 `exit 1` 並印出該怎麼做 —— 照它印的做，不要繞過。
用它就漏掉這段先前已經寫好的部分；表上那個較舊、較寬，只會多審。
算出幾份就只審那幾份（用 claude-md-improver）。範圍是空的才跳過（指令 exit 非 0 是範圍沒算出來，不算空）
算出幾份就只審那幾份（用 claude-md-improver）。該 skill 預設會 find 全部，
細則見 claude-dd repo（https://github.com/kopp0510/claude-dd）的 `skills/dd-loop/SKILL.md`。
自己的錯誤診斷寫進去，reviewer 會跟著錯（實證：兩個都接受了錯的框架，只有第三方去查才發現）。
表單送不出去時（後端零請求）改用 `form.requestSubmit()`。
要寫就標明是推測。
要派 agent 時（不派的例外見 `dd-loop`），主對話平行派 `code-reviewer` **最少 3 個**；收回的完整報告少於 3 份 → 不算跑過步驟 4，照實說，不續行。
起點就落在段落中間，它前面的 commit 步驟 3、4、8 全看不到，而 gate 印「記下段落起點 …」、`--segment-base` 也正常 exit 0，兩個訊號都看不出範圍縮水。
跳過時 commit 訊息加 trailer `SKIP-REVIEW: <段落> <理由>`**。步驟 4 是 8 步裡最容易**靜默**
跳過時建 `docs/reviews/S<段落>-SKIP.md` 寫明理由（gate 認的是這個檔，只加 trailer 開下一段時照樣被擋），commit 訊息加 trailer `SKIP-REVIEW: <段落> <理由>`**。步驟 4 是 8 步裡最容易**靜默**
跳過時建 `docs/reviews/S<段落>-SKIP.md` 寫明理由（有 `docs/reviews/` 時 `--start-segment` 要範圍裡新增一份 `S<數字>…md`，只加 trailer 開下一段時會被擋），commit 訊息加 trailer `SKIP-REVIEW: <段落> <理由>`**。步驟 4 是 8 步裡最容易**靜默**
那是迴圈唯一固化教訓的格子,剪斷這條回授線不會報錯。**
驗證不過 → 修完重跑步驟 5，不可帶著紅燈進步驟 6。
（exit 非 0 或輸出是空的 = 範圍沒算出來，不是範圍為空）。忘了記下一段的起點時，範圍會連上一段一起算——只會多審，不會漏。
（exit 非 0 或輸出是空的 = 範圍沒算出來，不是範圍為空）。忘了記下一段的起點時，範圍會連上一段一起算——只會多審，不會漏；
（步驟 3、4 寫 `<起點>` 會自動套用上面那條例外，只有這裡把指令寫死）：
__DD_TEMPLATE_LINES__
}

usage() { echo "用法：$(basename "$0") [--template <dd-init.md>] --plan <CLAUDE.md> | --apply <CLAUDE.md> <輸出路徑> | --list" >&2; exit 1; }

TEMPLATE="$HOME/.claude/commands/dd-init.md"
MODE=""; TARGET=""; OUTFILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --template) [ $# -ge 2 ] || usage; TEMPLATE="$2"; shift 2 ;;
    --plan)     [ $# -ge 2 ] || usage; MODE=plan; TARGET="$2"; shift 2 ;;
    --apply)    [ $# -ge 3 ] || usage; MODE=apply; TARGET="$2"; OUTFILE="$3"; shift 3 ;;
    --list)     MODE=list; shift ;;
    *) usage ;;
  esac
done
[ -n "$MODE" ] || usage
if [ "$MODE" = list ]; then list_lines; exit 0; fi
[ -f "$TARGET" ] || { echo "❌ 讀不到 ${TARGET}" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "❌ 讀不到範本 ${TEMPLATE}（先到 claude-dd repo 跑 ./install-dd-pipeline.sh --force，或用 --template 指定）" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
list_lines > "$WORK/list"
awk '/^```markdown$/ && !f {f=1; next} f && /^```$/ {exit} f' "$TEMPLATE" > "$WORK/block"
grep -q 'dd-loop-version' "$WORK/block" || { echo "❌ ${TEMPLATE} 裡抽不到帶 dd-loop-version 標記的蓋章區塊" >&2; exit 1; }

# 位元組語意（LC_ALL=C）：中文字比對、「共同前綴 60 bytes」在 macOS awk 與 Linux mawk/gawk 算出來一樣
# shellcheck disable=SC2016  # awk 程式本體，$0 等是 awk 的欄位
LC_ALL=C awk -v mode="$MODE" -v out="$OUTFILE" '
function trim(s) { sub(/^[ \t\r]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
function hlevel(s) { if (s !~ /^#+ /) return 0; match(s, /^#+/); return RLENGTH }
function isfence(s) { return trim(s) ~ /^```/ }
function generic(t) { return t == "" || t == "---" || t ~ /^```[A-Za-z]*$/ }
function label(a,   k) {
  if (a == "pre") return "步驟 1 之前"
  if (a == "v") return "驗證不過之後"
  if (a == "m") return "CLAUDE.md 維護底下"
  k = substr(a, 2); return "步驟 " k " 底下"
}
function section(title, cnt) { printf "\n## %s\n", title; if (cnt == 0) print "  （無）" }
FNR == 1 { fi++ }
fi == 1 { L[$0] = 1; nl++; LL[nl] = $0; next }
fi == 2 { nb++; NB[nb] = $0; next }
{ n++; F[n] = $0 }
END {
  for (i = 1; i <= n; i++) if (index(F[i], "dd-loop-version")) { mc++; mk = i }
  if (mc == 0) { print "❌ 找不到 dd-loop-version 標記，不是 /dd-init 蓋章過的區塊" > "/dev/stderr"; exit 2 }
  if (mc > 1) { print "❌ 有 " mc " 個 dd-loop-version 標記，不知道要升級哪一份" > "/dev/stderr"; exit 4 }

  # 起點：標記上方最近的標題；沒有標題就是標記行本身
  start = mk
  for (i = mk - 1; i >= 1; i--) if (hlevel(F[i]) > 0) { start = i; break }
  if (start == mk) { Lv = 6; startTpl = 1 } else { Lv = hlevel(F[start]); startTpl = (trim(F[start]) in L) }

  # 切單位：空行跟著前一個單位；圍欄開到關算一個；遇到「同級或更高級、不在清單裡的標題」停
  nu = 0; stop = n + 1
  for (i = start + 1; i <= n; i++) {
    if (trim(F[i]) == "") { if (nu > 0) ue[nu] = i; continue }
    if (!isfence(F[i])) {
      h = hlevel(F[i])
      if (h > 0 && h <= Lv && !(trim(F[i]) in L)) { stop = i; break }
    }
    nu++; us[nu] = i; j = i
    if (isfence(F[i])) { for (j = i + 1; j <= n && !isfence(F[j]); j++) ; if (j > n) j = n }
    ul[nu] = j; ue[nu] = j
    if (us[nu] == ul[nu]) {
      t = trim(F[i]); tpl[nu] = (i == mk) || (t in L)
    } else {
      c = 0; k = 0
      for (x = i + 1; x < j; x++) { t = trim(F[x]); if (generic(t)) continue; c++; if (t in L) k++ }
      tpl[nu] = (c > 0 && k == c)
      if (!tpl[nu] && k > 0) partial[nu] = k "/" c
    }
    i = j
  }
  lastTpl = 0
  for (u = 1; u <= nu; u++) if (tpl[u]) lastTpl = u
  end = (lastTpl > 0) ? ul[lastTpl] : start

  # 錨點：在地單位跟著前面最近的範本步驟行／驗證不過／CLAUDE.md 維護
  anchor = "pre"; del = 0
  for (u = 1; u <= lastTpl; u++) {
    t = trim(F[us[u]])
    if (tpl[u]) {
      if (t ~ /^[0-9]+\. /) { match(t, /^[0-9]+/); anchor = "s" substr(t, 1, RLENGTH) }
      else if (t ~ /^驗證不過/) anchor = "v"
      else if (t ~ /^#+ CLAUDE\.md 維護/) anchor = "m"
      for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) != "" && x != mk) del++
    } else ua[u] = anchor
  }
  if (del == 0) { print "❌ 區塊裡除了標題與標記之外沒有任何一行認得出是範本原文（清單過期，或區塊被整份改寫過），不升級" > "/dev/stderr"; exit 3 }

  if (mode == "plan") {
    printf "區塊：第 %d–%d 行；起點標題：%s（%s）\n", start, end, (start == mk ? "（無，從標記行起算）" : F[start]), (startTpl ? "範本，換新" : "在地，保留；新區塊的第一個標題不放，其餘標題降級接在底下")
    c = 0; for (u = 1; u <= lastTpl; u++) if (tpl[u]) for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) != "") c++
    if (startTpl && start != mk) c++
    section("將刪除的行", c)
    if (startTpl && start != mk) printf "  %d: %s\n", start, F[start]
    for (u = 1; u <= lastTpl; u++) if (tpl[u]) for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) != "") printf "  %d: %s\n", x, F[x]
    c = 0; for (u = 1; u <= lastTpl; u++) if (!tpl[u]) for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) != "") c++
    section("保留的行", c)
    for (u = 1; u <= lastTpl; u++) if (!tpl[u]) for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) != "") printf "  %d [%s]: %s\n", x, label(ua[u]), F[x]
    # 相似：去前後空白後，與清單某行的前 60 bytes 相同（逐字相同的已經是範本，不會在這裡）
    c = 0
    for (u = 1; u <= lastTpl; u++) if (!tpl[u]) for (x = us[u]; x <= ul[u]; x++) {
      t = trim(F[x]); if (length(t) < 60 || (t in L)) continue
      for (y = 1; y <= nl; y++) if (length(LL[y]) >= 60 && substr(LL[y], 1, 60) == substr(t, 1, 60)) { c++; sim[x] = LL[y]; break }
    }
    section("保留、但與範本某行相似", c)
    for (x = 1; x <= n; x++) if (x in sim) printf "  %d: %s\n      ≈ 範本：%s\n", x, F[x], sim[x]
    c = 0; for (u = 1; u <= lastTpl; u++) if (!tpl[u]) for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) ~ /^[0-9]+\. /) { c++; dstep[x] = 1 }
    section("疑似改寫過的步驟行（不是錨點，會跟新區塊同號步驟並存）", c)
    for (x = 1; x <= n; x++) if (x in dstep) printf "  %d: %s\n", x, F[x]
    c = 0; for (u = 1; u <= lastTpl; u++) if (!tpl[u] && ua[u] == "s5") for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) != "") c++
    section("步驟 5 既有的驗證指令行（Phase 1 據此決定佔位行填或刪）", c)
    for (u = 1; u <= lastTpl; u++) if (!tpl[u] && ua[u] == "s5") for (x = us[u]; x <= ul[u]; x++) if (trim(F[x]) != "") printf "  %d: %s\n", x, F[x]
    c = 0; for (u = 1; u <= lastTpl; u++) if (u in partial) c++
    section("保留的圍欄裡有部分行在清單中（整塊保留，可能跟新區塊重複）", c)
    for (u = 1; u <= lastTpl; u++) if (u in partial) printf "  %d–%d：%s 行在清單中\n", us[u], ul[u], partial[u]
    c = 0
    for (x = 1; x <= n; x++) if ((x < start || x > end) && !generic(trim(F[x])) && (trim(F[x]) in L)) { c++; outside[x] = 1 }
    section("區塊外還有範本行（不會被換掉）", c)
    for (x = 1; x <= n; x++) if (x in outside) printf "  %d: %s\n", x, F[x]
    exit 0
  }

  # --apply：在地單位依錨點插回新區塊
  for (u = 1; u <= lastTpl; u++) if (!tpl[u]) {
    a = ua[u]; last = ul[u]
    if (u < lastTpl && !tpl[u + 1]) last = ue[u]   # 下一個也是在地單位：保留兩者之間的空行
    for (x = us[u]; x <= last; x++) grp[a] = grp[a] F[x] "\n"
    has[a] = 1
  }
  firstStep = 0; vIdx = 0
  for (p = 1; p <= nb; p++) {
    t = trim(NB[p])
    if (t ~ /^[0-9]+\. /) { match(t, /^[0-9]+/); sidx[substr(t, 1, RLENGTH) + 0] = p; if (!firstStep) firstStep = p }
    else if (t ~ /^驗證不過/) vIdx = p
  }
  if (!vIdx) vIdx = nb + 1
  if (!firstStep) firstStep = vIdx
  if (has["pre"]) ins[firstStep] = ins[firstStep] grp["pre"] "\n"
  for (k = 1; k <= 99; k++) if (has["s" k]) {
    p = vIdx
    if ((k + 1) in sidx) p = sidx[k + 1]
    while (p > 1 && trim(NB[p - 1]) == "") p--
    ins[p] = ins[p] grp["s" k]
  }
  if (has["v"]) ins[vIdx + 1] = ins[vIdx + 1] "\n" grp["v"]
  if (has["m"]) ins[nb + 1] = ins[nb + 1] "\n" grp["m"]

  shift = (startTpl ? 0 : Lv - 1)
  o = 0
  for (x = 1; x < start; x++) O[++o] = F[x]
  if (!startTpl) O[++o] = F[start]
  for (p = 1; p <= nb + 1; p++) {
    if (p in ins) { s = ins[p]; while ((q = index(s, "\n")) > 0) { O[++o] = substr(s, 1, q - 1); s = substr(s, q + 1) } }
    if (p > nb) break
    line = NB[p]
    if (shift > 0 && hlevel(line) > 0) {
      if (p == 1) continue
      pre = ""; for (q = 0; q < shift; q++) pre = pre "#"
      line = pre line
    }
    O[++o] = line
  }
  for (x = end + 1; x <= n; x++) O[++o] = F[x]
  c = 0; for (x = 1; x <= o; x++) if (index(O[x], "dd-loop-version")) c++
  if (c != 1) { print "❌ 自檢失敗：合併結果有 " c " 個 dd-loop-version 標記（應為 1），沒有寫檔" > "/dev/stderr"; exit 5 }
  for (x = 1; x <= o; x++) print O[x] > out
  close(out)
}' "$WORK/list" "$WORK/block" "$TARGET"
