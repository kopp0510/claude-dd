# S1-c：審查者 C（docs/measurements/2026-10-30-dd-loop-trigger/ 的腳本正確性與量測結論）

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

> 你是審查者 C，方向：**docs/measurements/2026-10-30-dd-loop-trigger/ 的 run.sh、check.sh 正確性，以及量測結論站不站得住**。run.sh 建的 fixture 是否真的符合各 prompt 情境（例如 p1「新段落 S2」時表上沒有 S2）；check.sh 的 jq 判定在「叫了別的 skill」「result 缺欄位」「permission_denials 不是 Skill」時會不會判錯；inject_chars 欄位量的是什麼（README 改用 6,188 那個數字是怎麼來的，能不能從 repo 重現）；README 的結論（8/8、「好處只在不跑迴圈的 session」、24.8k）與限制是否寫對；有沒有把個人路徑或可識別資料寫進 repo。bash 3.2 相容、`set -eu` 下的陷阱也看。

## 發現

（逐字原文）

審查者 C 的結果：Critical 0、Important 4、Smells 1。範圍是 `git diff f46d4de HEAD` 裡的 docs/measurements/2026-10-30-dd-loop-trigger/ 全部檔案（run.sh、check.sh、README.md、CLAUDE.md、results.tsv、*.prompt.txt）。目錄在 HEAD 與工作目錄一致，直接讀 repo。

## Important

**[Important] check.sh:8、results.tsv 每列、README.md:29 —— `inject_chars` 量的不是 skill 注入長度。README 的 6,188 從 repo 重現不了**
- 問題：check.sh 只加總「內容含 dd-loop 的 tool_result」的長度。results.tsv 正例每列都是 `inject_chars=24`，24 剛好是 `Launching skill: dd-loop` 的字元數。skill 本文不在 tool_result 裡，所以這個欄位沒量到注入量。
- 證據：
  - check.sh:2 註解寫「dd-loop 注入長度」。
  - `printf 'Launching skill: dd-loop' | wc -m` → 24。
  - README.md:29 寫「6,188 字元（p1-start-1 的 jsonl 量到的 skill 本文）」，但 jsonl 不進 repo（CLAUDE.md:16），check.sh 也算不出這個數。
  - `skills/dd-loop/SKILL.md`（HEAD）去掉 frontmatter 後是 6,159 字元，跟 6,188 差 29。我推測差的是注入時加的檔頭，沒驗證。
- 失敗情境：下一個人照 CLAUDE.md:10「重測就開新目錄」跑 check.sh，拿到 24，跟 README 的 6,188 對不上，也不知道 6,188 怎麼量出來。24.8k 的結論（README.md:30）唯一的數據來源因此沒有留下可重跑的指令。
- 建議：改 jq，量那則 skill 本文訊息（或改成記 SKILL.md body 的 `wc -m`），重新產生 results.tsv，或在 README 附上 6,188 的量法。另外 README.md:7 與 CLAUDE.md:9 列欄位時都漏了 inject_chars，跟 check.sh:2 不一致。

**[Important] run.sh:24-28 —— 工作目錄給相對路徑時，每個情境都靜靜地不跑**
- 問題：子 shell 先 `cd "$W/repo-…"`，再把輸出導到 `"$W/out/…"`，所以相對路徑是從 repo 目錄算的。目錄不存在，重導失敗，`|| true` 把錯誤吞掉，run.sh 照樣 exit 0。
- 證據：用假的 `claude` 跑 `CASES=p1-start REPS=1 bash run.sh work`，輸出：
  - `run.sh: line 24: work/out/p1-start-1.jsonl: No such file or directory`（n1-typo 也一樣）
  - `run exit=0`
  - `work/out` 是空的
  - 同樣條件改用絕對路徑，兩份 jsonl 都產生了
- 失敗情境：照 README.md:5 的 `./run.sh <工作目錄>` 寫成 `./run.sh work`，跑完沒有任何結果；要到 check.sh 才炸出 `Could not open file work/out/*.jsonl`（exit 2）。
- 建議：`W=$(mkdir -p "$1" && cd "$1" && pwd)`。拿掉 `|| true`，或改成檢查 jsonl 非空。

**[Important] check.sh:7,9 —— 沒有 result 那一行時，`denied_skill` 照樣印 0，看起來像通過**
- 問題：`$r` 是 null 時，`($r.permission_denials // [])` 變成空陣列，印 `denied_skill=0`，只有 `cost=null` 露出異常。
- 證據：只放一行 assistant 的 jsonl，check.sh 輸出 `x skills= dd-loop=false denied_skill=0 inject_chars=0 cost=null`。
- 失敗情境：session 中途死掉、超出 budget、或 stream 被截斷（run.sh 用 `|| true` 不會擋）時，反例 n1 的列跟「沒叫 skill、也沒被擋」長得一樣，「0/1 沒叫」會變成假陰性。
- 建議：`$r == null` 時印 `result=MISSING`。

**[Important] README.md:14-17、README.md:20 —— 結論比 results.tsv 能證明的多**
- 問題：
  - 「都是第一個工具呼叫」與 p2「先 Read 進度表，判定要做步驟 3 後才叫」：check.sh 只抽 Skill 呼叫序列，沒有記錄其他工具的順序，results.tsv 證明不了。
  - 「9 次的 `permission_denials` 都是空的」：check.sh 只數 `tool_name=="Skill"` 的那幾筆。results.tsv 只證明「沒有 Skill 被擋」，證明不了整個陣列是空的。
- 證據：check.sh:6、9 的 select 條件；results.tsv 欄位只有 `skills=` 與 `denied_skill=`。
- 失敗情境：原始 jsonl 不在 repo，沒有人能核對這兩句。違反 CLAUDE.md:10「results.tsv 是被引用的證據」的前提。
- 建議：check.sh 加一欄「第一個 tool_use 的名字」與 `denials_total`；或把 README 改成只寫 tsv 撐得住的說法。

## Smells

**[Smell] README.md:28 —— 「不跑迴圈的 session 每次都省這麼多」沒扣掉新 skill 的 description**
- 問題：dd-loop 的 description 每個 session 都會出現在 skill 清單裡，所以淨省量不是 5,042。
- 證據：HEAD 的 SKILL.md `description` 167 字元。28,082 → 23,040 我用 python 重算過，一致；bytes 56,068 → 46,158 也一致。
- 失敗情境：淨省約 4,875，不是 5,042。量級不大，但下一輪會把這個「省多少」當基準。

## 核對過、沒問題

- 合計費用：results.tsv 加總 3.8545，與 README「約 US$3.85」一致。
- 8/8 與 n1 0/1 與 tsv 一致。
- 24.8k = 4 × 6,188（前提是 6,188 本身成立，見上面第一條）。
- 「4 次」跟全域 templates/global/CLAUDE.md:239「段落開始時、以及步驟 3、4、8 開始前」一致。

## Not reported

- p1 的 fixture 表上 S1 仍是 `IN_PROGRESS`，沒有 S2 列，prompt 卻說開 S2：全域 §4.4 有「沒有這列就先加」，情境合法，只是不典型。
- fixture CLAUDE.md 寫「照表下方的規則做」，設計文件裡其實沒有規則區塊：這次只測叫不叫，不影響判定。
- run.sh:28 的 `2>&1` 把 stderr 混進 jsonl：會讓 `jq -s` 大聲失敗，不是靜默問題。
- 工作目錄放在 claude-dd repo 底下時，會載入祖先 CLAUDE.md、污染結果：README 沒寫工作目錄要放 repo 外。目前被上面的相對路徑 bug 蓋住了，修好後會浮現，建議 README 補一句。
- 個資：目錄內 grep `/Users/|danlio|kopp|-Users-|-private-tmp|@gmail`，只命中 CLAUDE.md:16 的佔位寫法 `-Users-<名字>-…`，不是真實路徑。fixture 用 `t@t`，沒問題。
- bash 3.2：`local name=$1 rep`、`${REPS:-1 2}` 的分詞、`${1:?}` 都相容；`set -eu` 下沒有其他會中止的單獨 grep/diff。

## What I ran

- `cat -n` 讀目錄內 10 個檔 → 內容如上
- results.tsv cost 加總（awk）→ 3.8545
- `printf 'Launching skill: dd-loop' | wc -m` → 24
- 用 python 量 f46d4de 與 HEAD 的 templates/global/CLAUDE.md → 28082/56068、23040/46158
- 用 python 量 HEAD 的 skills/dd-loop/SKILL.md → total 6362、body 6159、description 167
- 目錄內 `git grep` 個資樣式 → 只有 CLAUDE.md:16 的佔位
- 在 scratchpad 用假 `claude` 跑 `run.sh work`（相對路徑）→ No such file、exit 0、out 空
- 同上改絕對路徑 → 兩份 jsonl 都產生
- check.sh 吃沒有 result 的 jsonl → `denied_skill=0 cost=null`
- check.sh 吃空的 out 目錄 → jq Could not open、exit 2

## 需要外部查證

- 拿任一份原始 jsonl（例如 p1-start-1）確認三件事：
  1. skill 本文是不是以非 tool_result 的 user 訊息注入。這能證實 inject_chars=24 只是 Launching 字串。
  2. `permission_denials` 每筆的鍵名是不是 `tool_name`。如果不是，denied_skill 永遠是 0。
  3. 每一份的第一個 tool_use 是不是 Skill，以及 9 份的 `permission_denials` 是不是都是 `[]`。這能核對 README:14-17、20 的說法。
- 6,188 與 6,159 差的 29 字元是不是注入檔頭（例如 "Base directory for this skill: …"）：要看 jsonl 原文。

scratchpad 實驗目錄：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/revC

## 處置

- Important 1（`inject_chars` 量錯）→ 採納，見 S1-b 處置
- Important 2（`run.sh` 相對路徑靜靜不產出）→ 採納，與步驟 3 simplifier 第 1 條重疊。`W=$(mkdir -p "${1:?}/out" && cd "$1" && pwd)`；stderr 另存 `.stderr`；jsonl 是空的就印警告。假 `claude` 實測 `run.sh relw`（相對路徑）exit 0 且 `relw/out/` 有 jsonl
- Important 3（沒有 result 時 `denied_skill=0` 像通過）→ 採納。加 `result=MISSING` 欄；只留前 3 行的 jsonl 實測印 `result=MISSING`
- Important 4（README 宣稱超出 tsv）→ 採納，見 S1-b 處置
- Smell（沒扣 description）→ 採納，README 與 CHANGELOG 改成淨省約 4.8k（修正後重量）
- Not reported「工作目錄放 repo 底下會載祖先 CLAUDE.md」→ 採納，README 補一句
