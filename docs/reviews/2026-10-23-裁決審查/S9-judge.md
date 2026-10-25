# S9 查證

## 派工

同一則訊息平行派 3 個 `code-reviewer`（不帶 model，agent 定義是 opus），2026-10-25 15:11 派出：
- a 全面：規則、條件、限定語、證據強度標記有沒有變；A 類每一處「拿掉不會改變要做的事」站不站得住（去 gate、agent 定義讀原文核）；附錄 A 的改寫；改動附近的指代
- b 跨檔與內部引用：模板內部指代、設計文件「巡查結果」逐項核與漏掉的地方、README 兩份與 `scripts/CLAUDE.md` 的改法、進度表與 S9 一節、CHANGELOG
- c 盲對照：只拿機械比對找不到原文的 42 段、base 全部 379 段、新版模板；不給作者理由與 diff

數量理由：使用者嫌慢（計畫審查第 2 輪 108 分鐘），派最少的 3 個；三個方向涵蓋「意思有沒有變」「別處有沒有跟著壞」「不看作者理由的逐段對照」。

審查檔：
- a、b：scratchpad 的 `s9-final/S9-review-diff.txt`（2530 行）：①`git diff 316117c`（含工作目錄的設計文件一處措辭修正）②無（步驟 3 跳過）③新版模板整檔、設計文件進度表與 S9 一節、CHANGELOG `## 未發布` 區塊（不附整檔：只加一段，① 有前後文，已發布區塊由 CI 比對）④`check.sh … final` 與 `ci-steps.sh` 的輸出連同預期值（全 PASS、五個 step exit 0）⑤base 整檔、作者的分類與理由（標明「作者宣稱，要逐條查證」）
- c：scratchpad 的 `s9-final/S9-review-c.txt`（1272 行）：甲 42 段（同一支切段腳本切 base 與新版，base 的段在新版同一節找不到一模一樣的就列入）、乙 base 全部 379 段、丙新版模板整檔

偏離計畫：計畫寫 c 只拿 379 段與新版整檔；實際多給機械比對出的 42 段名單，讓它專心判這 42 段的意思（使用者嫌慢）。名單是腳本算的、不含作者判斷；另要 c 從其餘 337 段抽查至少 10 段。
Read 每次的行數：a、b 200 行、c 150 行（模板寫 300 行；這兩份檔有長行，300 行一段最大到 44 KB、64 KB，接近截斷線）。

三份都完整回來（c 5 分 52 秒、a 10 分 24 秒、b 11 分 53 秒）。主對話派完自己讀了 diff 檔 ①（第 1–490 行），對照 `scripts/check-claude-md.sh` 的擋下訊息核了 A13。

## 發現

讀檔檢查：a、b 引的 `agents/code-reviewer.md` Scope Discipline 與 Work Order 第 4 點、`scripts/check-claude-md.sh` 擋下訊息、`commands/dd-init.md:97`、`install-dd-pipeline.sh` 的部署順序，主對話都讀過原文，對得上；c 只讀對照檔（照派工），引的 base 段代號與新版行號抽查對得上。

| 項目 | a | b | c | 判定 |
|---|---|---|---|---|
| A07 只留下「不設工具次數上限」，「只用手上的資料判斷、需要外部查證的列出來交回」不見 | ✔ 1 | — | ✔ 2 | 採納 Important。新版 grep「只用手上」0 筆；Work Order 第 4 點叫審查者自己寫腳本實驗，Scope Discipline 只管範圍外 |
| A04 拿掉「prompt 標明已確認、不要重跑」：Scope Discipline 寫的是 pasted in，放在 diff 檔算不算沒寫；README 還寫輸出放在 prompt | ✔ 4（Smell） | ✔ 1 | ✔ 2 | 採納 Important（三份都提，b 指出 README 也跟著錯）。這次派工 prompt 主對話照樣手寫了「已確認，不要重跑」 |
| A08 連帶刪掉「報告檔的命名慣例:見專案自己的 `docs/reviews/CLAUDE.md`」，那句是給各專案的 | ✔ 3 | — | ✔ 3 | 採納 Important。A08 的理由「其餘是給維護者的」不涵蓋這句；蓋章版 grep `docs/reviews/CLAUDE` 0 筆 |
| 「欠帳」失去定義（A13 刪了唯一定義）、「下詳」拿掉後沒指標 | — | ✔ 2 | ✔ 1、4 | 採納 Smell |
| 「照 gate 印的指示」把做法交給別的檔 | — | Not reported（核過 gate 訊息） | ✔ 1 | 駁回：gate 擋下訊息印讀全部檔案、四段格式、逐層、SKIP 不是豁免；「只印 staged 理由」base 也一樣 |
| §3.9 連「實測／實證」標記一起刪 | ✔ 2 | — | — | 採納，Important 降 Smell：行為不變，刪故事是計畫第 3 輪審過的。四句補標記 |
| 「檔名沿用裁決者時期」失去出處 | — | ✔ 2 | — | 採納 Smell |
| §3.10「上面那條」與同輪改好的「§3.9…那條」不一致 | ✔ 5 | Not reported | — | 採納 Smell |
| 刪字後換行沒重排（④、「假綠」） | — | — | ✔ 5 | 採納 Smell |
| CHANGELOG 分類沒涵蓋 A08/A01/A10；「步驟 6 不可 SKIP」「不問使用者」gate 也印 | — | ✔ 3 | — | 採納 Smell |
| 巡查結果把 `dd-init.md:173`、`:323` 算成蓋章版副本 | — | ✔ 4 | — | 採納 Smell |
| `skills/verification-gate/SKILL.md:56` 引號沒照抄 | — | ✔ 5 | — | 駁回：既有、不在 diff；改 skill 要走乾跑；grep 找得到。結尾告知使用者 |
| 設計文件 S8 段 `:316` 已指歪 | — | Not reported（既有） | — | 不改：S8 當時的紀錄 |

需使用者決定：無。需要外部查證：「Write 新建檔時會不會載入 `docs/reviews/CLAUDE.md`」沒查，指標補回後不依賴它。

### 重疊與獨有項

- 三份都提：A04 的「已確認、不要重跑」—— 代表 A04 的理由（agent 定義已涵蓋）站不住
- a、c 獨立都提：A07 的「只用手上的資料判斷」、A08 的 `docs/reviews/CLAUDE.md` 指標
- b、c 獨立都提：「欠帳」與「下詳」
- a 獨有：證據標記、§3.10 指代一致；b 獨有：README、CHANGELOG 分類、巡查分類、verification-gate；c 獨有：換行重排
- c 只拿原文、不看作者理由，抓到的三條 Important 都跟看了理由的 a 重疊 —— 這次「給作者理由」沒有讓 a 跟著錯

## 處置

所有採納項寫成 scratchpad 的 `s9-final/review-fixes.py`（每處必須恰好命中 1 次才寫檔），套在 `sim-A.md` 產生 `sim-B.md`，再用 `splice.py` 換進模板；模板與 `sim-B.md` 逐 byte 相同（檢查 3）。55,281 → 55,579 bytes。
- 模板 §3.9：④ 補「派工 prompt 標明這些已確認、不要重跑」並併成一行；A07 那條補「派工 prompt 寫明『只用手上的資料判斷,需要外部查證的列出來交回』」；「寫之前先 `ls`」後補 `docs/reviews/CLAUDE.md` 指標；前言改「SKIP 欠下、還沒補的 CLAUDE.md」並補「見下方「報告一律落地」那條」；「檔名是歷史沿用」；`會漏`、`會跟著錯`、`不代表結果對`、`假綠` 補 `(實測)`／`(實證)`，「假綠」那句併成一行
- 模板 §3.10：「所以上面那條」→「所以 §3.9 那條」
- 兩份 README：驗證輸出寫進 diff 檔、prompt 標明已確認、不要重跑
- CHANGELOG：分類補「gate 盲點的說明、導覽與分類註記」，A13 括號改成「以及 gate 也會印的不回問、步驟 6 不可 SKIP」，bytes 改 55,579
- 設計文件：A04、A07、A08、A13 那幾列改寫；巡查結果 `:173`、`:323` 移出蓋章版副本；bytes 與百分比改 55,579、9.9%
- 證據標記預期值：§3.9 實測 5 → 8、實證 1 → 2（scratchpad 的 `s9-final/evidence.tsv`）
- 改完重跑（步驟 5）：`SIM=…/sim-B.md bash s9-final/check.sh 3.9 3.10 2.6 3.4 4.1 4.4 6.7 7.2 7.5 final` → `FAIL 數:0`；`bash s9-final/ci-steps.sh` → 五個 step 都 exit 0
