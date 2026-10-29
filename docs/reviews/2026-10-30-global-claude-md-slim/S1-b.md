# S1-b：審查者 B（文件裡的宣稱、數字、引用、同步點）

## 派工

`subagent_type: code-reviewer`，與其他審查者同一則訊息平行派出。共用派工說明（逐字）：

> 你是 code-review 審查者。審查範圍：claude-dd repo（/Users/danlio/project/my_project/claude-dd）段落 S1 的整段改動 = `git diff f46d4de HEAD`（3 個 commit：a30dc1a、f0e80ab、a542817；工作目錄乾淨）。
> 段落目標：把全域模板 templates/global/CLAUDE.md §3.9 的 8 步迴圈做法細則，原文搬進新 skill skills/dd-loop/SKILL.md，全域只留 8 步清單、關卡、驗證教訓，並明寫「段落開始時、步驟 3、4、8 開始前呼叫 dd-loop」；同批改部署陣列、README×2、根 CLAUDE.md、架構文件、CHANGELOG、引用處；新增觸發實測 docs/measurements/2026-10-30-dd-loop-trigger/。設計文件：docs/designs/2026-10-30-global-claude-md-slim-design.md。
> 
> 資料：diff 檔 /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/S1-diff.txt（①整段 diff ②步驟 3 改動：無 ③被改到檔案的 HEAD 整檔（帶行號）④已跑過的驗證與預期值 —— ④ 已確認，不要重跑）。
> **diff 檔用 Read 的 offset/limit 每次 300 行讀到最後一行（共 5593 行）**：Read 一次讀太多會靜靜截斷、不報錯。被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔照常讀 repo。舊版可用 `git show f46d4de:<path>`。
> 
> 你的職責：找漏洞，每條附證據（路徑:行號 + 原文，或指令與輸出），沒證據不算。只用手上的資料判斷，需要外部查證（上網、跑 claude -p 等）的列出來交回。專案規則在各層 CLAUDE.md 與全域模板 §3.10。
> 輸出：Critical / Important / Smells 三級，每條「位置｜問題｜失敗情境｜證據｜建議」；另列 Not reported（看到但判為不報的，附理由）、What I ran（跑過的指令）、需要外部查證。

派工 prompt 的其餘部分（逐字）：「先讀這份共用派工說明並照做：<上面那份的路徑>」，接著：

> 你是審查者 B，方向：**文件裡的宣稱、數字、引用、同步點**。CHANGELOG、README×2、根 CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、scripts/CLAUDE.md、diagrams/src/CLAUDE.md、設計文件、量測 README/CLAUDE.md 裡每個數字（行數、bytes、字元、次數、費用）、每個「見 X」「在 X」、每個「原地成立」判定，逐一對實際檔案或 results.tsv 核。另查各層 CLAUDE.md 規定「新增 skill 要同批改」的地方（根 CLAUDE.md「新增 Skill 步驟」「CI 不驗、只能手動同步的區塊」、vendor／授權清單等）有沒有漏改。

## 發現

（逐字原文）

審查者 B 報告（方向：文件宣稱、數字、引用、同步點），範圍是 `git diff f46d4de HEAD`（a30dc1a、f0e80ab、a542817）。

Critical 0 / Important 2 / Smells 0

**[Important] CHANGELOG.md:16-17｜context 收益寫成全面受益，和同一段的實測結論相反**
- 問題：CHANGELOG 寫「每個專案、每個 session 都少載這一塊；跑迴圈時多載一次 skill」。實際上規則要求一段迴圈叫 4 次，實測也判定跑迴圈的 session 總量會增加。
- 失敗情境：讀 CHANGELOG 的人會以為所有 session 都省 context，而且只多付一次 skill 注入。實際上跑迴圈的 session 是淨增加：4 × 6,188 ≈ 24.8k 字元，大於省下的 5,042 字元。設計文件 S1-2 自己定過條件：「若一段 4 次注入的總量超過全域省下的量，就在報告如實寫出、不再宣稱 context 有好處」。這個條件已經觸發，但 CHANGELOG 沒有跟著改。
- 證據：
  - `templates/global/CLAUDE.md` §3.9 新增句：「段落開始時、以及步驟 3、4、8 開始前,先呼叫 Skill `dd-loop` —— 每次都叫」
  - `docs/measurements/2026-10-30-dd-loop-trigger/README.md:28-31`：「一段迴圈照規則會叫 4 次…最多約 24.8k 字元，**比全域省下的多** —— 跑迴圈的 session 總量會增加；好處只在不跑迴圈的 session」
  - 設計文件 S1-2 驗證那條（diff 檔第 210 行）
- 建議：「多載一次」改成「每段約 4 次」，並刪掉「每個 session 都少載」或加上限定。

**[Important] docs/measurements/2026-10-30-dd-loop-trigger/README.md:12-23, 28｜結果表有三項宣稱，committed 的證據 results.tsv 撐不起來，其中一項和 tsv 的數字矛盾**
- 問題：該目錄 CLAUDE.md 規定 results.tsv 是「被 README.md 與設計文件引用的證據」，不可重跑覆蓋，而且原始 jsonl 不進 repo。但 README 有三項宣稱 check.sh 根本沒抽出來：
  - ①「都是第一個工具呼叫」與「p2 先 Read 進度表」：check.sh 只抽 Skill 的 tool_use，看不到其他工具，也看不到順序。
  - ②「9 次的 `permission_denials` 都是空的」：check.sh 只數 `tool_name=="Skill"` 的那幾筆（`denied_skill=`），只證明沒有 Skill 被擋，不證明整個欄位是空的。設計文件 S1-2 自己也把判定降成「permission_denials 裡沒有 Skill」。
  - ③「每叫一次 `dd-loop` 注入 6,188 字元」：results.tsv 的 `inject_chars` 9 列全是 24，來源不明。依據是：check.sh 抓的是「含 dd-loop 的 tool_result」，抓到的是 24 字元那一段；從字數看像是 `Launching skill: dd-loop`（這是我的推測），不是 skill 本文。
- 失敗情境：原始 jsonl 已經不在，事後要核對時拿 results.tsv 只會得到「注入 24 字元」，跟 README 的 6,188 互相矛盾。而 24.8k 這個「比全域省下的多」的結論，靠的正是 6,188 這個數字。另外，`inject_chars` 這欄名稱會讓讀者以為量的就是注入量。
- 證據：
  - check.sh：`select(.tool_name=="Skill")`、`select(test("dd-loop"))|length`
  - results.tsv：p1–p4 共 8 列都是 `inject_chars=24`
  - 自己重算：SKILL.md 去掉 frontmatter，在 a30dc1a 是 6,120 字元，整檔 6,323 字元。6,188 落在兩者之間，可信，但從 repo 內的東西無法重現。
- 建議：
  - check.sh 改成抽 skill 注入訊息的長度，以及每份 jsonl 的第一個 tool_use 名稱和 `permission_denials|length`，重跑後放進新的日期目錄（照該層 CLAUDE.md，不覆蓋原處）。
  - 或者 README 把這三句降級成「未進 repo 的觀察」，並寫明 6,188 的量法。

**有核對、而且成立的**（所以不報）
- 全域模板大小：f46d4de 是 842 行、56,068 bytes、28,082 字元；HEAD 是 748 行、46,158 bytes、23,040 字元，差 5,042 字元，與 CHANGELOG、量測 README 一致。
- 費用合計是 3.8545，對上「約 US$3.85」。
- 4 個正例各 2 次、反例 1 次，與 run.sh 一致。
- 13 個 skills 的同步：根 CLAUDE.md 目錄結構、兩份 README 的安裝步驟 2 與表格標題、架構文件部署清單、PROMOTED_SKILLS 都已改；表格與陣列都照字母序。沒有其他地方列舉全部 skill，也不涉及 vendored 或授權清單。
- 設計文件 A 組的行號，逐筆用 `sed -n` 印出來比對都指對：
  - ci.yml 317/319/322/472
  - 架構文件 100/129
  - README 88/91、101/104、103/106、121/124、143/153、149/159
  - scripts/CLAUDE.md 173/183
  - diagrams/src/CLAUDE.md 13/116
  - verification-gate SKILL.md:56
  - dd-init.md 75/83/323
  - 根 CLAUDE.md:181
- 判為「原地成立」的幾筆也成立：README 143/153（「寫實際讀到的內容」）、121/124 與 149/159（逐層更新）的依據仍留在全域 §3.9 的規則裡；dd-init 蓋章區塊（52–149 行）內沒有任何指向全域的字句。
- 全域 §3.9 裡沒有殘留的「見下方／上一條」懸空指標；§7.3 確實有「不重入」，可以被引用；退路句的 repo 網址與 README 第 42 行的 clone 網址一致。

**Not reported**
- 設計文件寫「找不到的 3 行、兩處同時出現：0」：在 HEAD 重算，找不到的是 5 行。多出的兩行是 SKILL.md 步驟 8 補的 `..` 說明，以及 a542817 的「上一條」改寫，兩者都是刻意的，④ 也已註明這份對照是在 S1-1 commit 前跑的。重複行仍是 0。我的正規化數出 181 行、文件寫 183 行，差在切區塊的寫法，不構成錯誤。
- p1-start 的 prompt 寫「新的一個功能段落（S2）」，但 fixture 的進度表只有 S1。這是 fixture 本身不一致，不是文件宣稱，對「叫不叫」的判定沒有影響。
- 設計文件大量寫行號，偏離 §3.10「寫識別符不寫行號」。這是查證紀錄的快照，而且我逐筆核過都對，所以不報。
- 6,188 是在 a30dc1a 版量的，a542817 之後 SKILL.md 多了 39 字元。README 已標「同日量」，量級沒變。

**What I ran**
- `cat S1-prompt-common.txt` → 讀到派工說明
- 用 Read 每次 300 行讀 S1-diff.txt：讀了 1–700 行（① 整段 diff 與 ②）和 5583–5594 行（④）。③ 整檔沒讀，需要整檔時改用 `git show`、`sed` 讀 repo。 → 看過 diff 全文
- `git grep -n '§3\.9'`，排除 docs/reviews 等 → 21 處，逐筆判定
- 對搬走的內容做關鍵詞 git grep（報告一律落地、範圍要明講、judge.md、SKIP-REVIEW 等） → 只命中 dd-init 蓋章區塊、gate 腳本、scripts/CLAUDE.md 這些獨立副本
- 在 deployed 目錄 git grep「全域模板」「全域 CLAUDE.md」 → 沒有懸空指標
- `git show f46d4de/HEAD:templates/global/CLAUDE.md | wc -c` 和 `wc -m` → 56068/46158 bytes，28082/23040 字元
- 用 `git show <c>:skills/dd-loop/SKILL.md | wc -m` 查 a30dc1a、f0e80ab、HEAD → 6323/6323/6362，a30dc1a 去掉 frontmatter 是 6120
- 用 awk 加總 results.tsv 的 cost → 3.8545
- 寫了一支 bash 腳本，正規化 f46d4de 的 §3.9，與 HEAD 的 §3.9 ∪ SKILL.md 做 comm → 舊版 181 行、重複 0、找不到 5 行（都是刻意改寫）
- 用 `sed -n` 印出設計文件引用的各個行號 → 全部指對
- grep 13/12 skills、worktree-manager、verification-gate 的出現位置 → 數字已同步，沒有其他 skill 列舉

**需要外部查證**
- 用原始 jsonl（`/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/trig/` 底下的 out，如果還在）跑 `jq '[.[]|select(.type=="result")][0].permission_denials|length'`，以及每份的第一個 tool_use 名稱。這能確定 README 的「都空」「第一個工具呼叫」是不是真的成立。
- 在同一批 jsonl 裡找 skill 本文那則訊息（可能是 `isMeta` 的 user text，不是 tool_result）並量長度，確認 6,188 字元的出處。

## 處置

- Important 1（CHANGELOG 寫成全面受益）→ 採納，與 D-2 重疊。改成「不跑迴圈的 session 淨省約 4.8k（修正後重量）；跑迴圈的 session 一段叫 4 次、總量增加」並指向量測目錄
- Important 2（README 三項宣稱 tsv 撐不起）→ 採納，與 C-1、C-4 重疊。`check.sh` 改抽 `first_tool`、`denials_total`、`result`，`inject_chars` 改量 `Base directory for this skill:` 那則 user 訊息；對同一批 jsonl 重抽 `results.tsv`（9 次 `denials_total=0`、`result=ok`；p2 兩發 `first_tool=Read`、其他正例 `Skill`；`inject_chars` 6,188，p3-step4-2 是 6,217），README 註明重抽、沒重跑 `claude -p`
- 外部查證兩條 → 用 scratchpad 裡的原始 jsonl 查完，結果即上一條
