# S2-c：審查者 C（全面，先從「程式與試跑紀錄」下手）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），S2-a…S2-d 四個在同一則訊息平行派出。
派工 prompt（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad；下面「發現」節同樣只換了路徑與使用者名稱）：

````text
先 Read <S>/s2-review/prompt-common.txt，照它做。你的代號是 S2-c。

你的方向：全面審查，但先從程式與試跑紀錄下手 —— ② 步驟 3 對 check.sh 的改動（行為、bash 3.2、jq 語意、它的輸出被 results.txt 引為證據）、run.sh、試跑目錄的 README／CLAUDE.md／results.txt 彼此與實際檔案對不對得上、去識別（本機路徑、使用者名稱、編碼過的路徑）有沒有漏、install-dd-pipeline.sh 那一行。
````

`prompt-common.txt` 全文（逐字，路徑去識別）：

````text
你是 claude-dd repo（<REPO>）8 步開發迴圈步驟 4 的審查者。職責：找漏洞，每條附證據（路徑:行，或指令與輸出），沒證據的不算。不寫優點、不客套。

審查範圍：段落 S2「收編 cloudflare/security-audit-skill 為 user-invoked promoted skill」從 6f2118a 到目前工作目錄的整段（兩個 commit aa9b162、d36e5d6，加上步驟 3 還沒 commit 的改動）。
另有 fc2ccb0（S1 的審查處置更新，docs/reviews/ 兩份與設計文件）也在範圍內。

材料：
- diff 檔：<S>/s2-review/diff.txt（924 行）。**用 Read 的 offset/limit 每次 300 行讀到最後一行**：Read 一次讀太多會靜靜截斷、不報錯。
  ① 整段 diff（排除與上游逐字相同的 vendored 檔）、①-b SKILL.md 對上游的差異與新增的 skills/security-audit/CLAUDE.md 整檔、② 步驟 3 的改動、③ 幾支檔的整檔內容、④ 已跑過的驗證與預期值
- ④ 列的驗證都已跑過、結果如列，不要重跑（測試、CI step、安裝都不要跑）。「跑過」不代表結論對 —— 你懷疑它驗的不是它宣稱的東西，就指出來
- 被改到的檔以 diff 檔那份為準；審查期間工作目錄不會再變，所以 diff 檔沒附整檔的（README、CLAUDE.md、CHANGELOG、DD_PIPELINE_ARCHITECTURE.md、設計文件）可以直接讀工作目錄
- 上游 clone（唯讀參考）：<S>/vendor/security-audit-skill（skills/security-audit/ 底下就是被複製的檔）
- 乾跑報告與 prompt：<S>/dry/report-D*.txt、<S>/dry/prompt-D*.txt（skills/security-audit/CLAUDE.md 的「乾跑發現」與分支清單由它們整理而來；報告含本機路徑，引用時換成 <S>）
- 專案規則：根目錄 CLAUDE.md（尤其「新增 Skill 步驟」「第三方 Skill / Agent 收編檢查清單」「注意事項」裡手動同步的區塊）、各層 CLAUDE.md、~/.claude/CLAUDE.md §3.10（寫文件的判準）
- 設計文件：docs/designs/2026-11-14-security-audit-intake-design.md（S2 的計畫在「### S2：收編 security-audit」那節，假設 A5–A14）

已知、不用再報的：S2 步驟 5（install --force、claude -p 五發觸發實測）還沒跑；skills/security-audit/CLAUDE.md 分支清單 D5b 那列寫「未執行」就是指這個。

只用手上的資料與讀檔、grep、git 指令判斷；需要外部查證（上網、跑 claude -p）的列出來交回，不要自己做。不要改任何檔、不要 commit。

輸出格式：
- 每條：級別（Critical / Important / Smell）｜檔:行｜問題｜證據（引原文或指令輸出）｜具體失敗情境（誰照這段做、會怎樣錯）
- Not reported：看過、判斷不是問題的，各一句理由
- What I ran：跑過的 grep / 讀過的檔
- 需要外部查證：每條一句
````

## 發現

S2-c 的結果：Critical 0、Important 2、Smell 5。範圍是 6f2118a 到工作目錄（aa9b162、d36e5d6、步驟 3 還沒 commit 的改動、fc2ccb0）。我從程式與試跑紀錄下手，最後全面看過一遍。路徑都寫成 repo 相對路徑，scratchpad 一律寫成 `<S>`。

## Findings

**Important｜skills/security-audit/CLAUDE.md:108｜這條把「試跑的 session 沒照文字做」寫成了「上游文字沒定義」**
- 證據：
  - 本檔:108 原文：「`run-metadata.json` 的鍵與型別沒定義：`budget` 在試跑裡寫成物件…，乾跑讀成一個數字」。
  - 上游有列鍵名。SKILL.md:89：「writes `run-metadata.json` with at least `run_id`, `repo`, `target`, `source_ref`, `profile`, `scope_paths`, `budget` (null if unset), … and `run_status: "in_progress"`」。
  - 上游也有給 budget 的型別。SKILL.md:124：「record `budget` in `run-metadata.json` as a maximum number of agent invocations across all phases」。
  - 所以照文字做的是乾跑（讀成數字）。試跑 session 寫成物件（results.txt:21）是偏離了 :124。
  - 真正沒給鍵名的只有 :89 裡的 selected companion files、prior-run paths、shared-file owners 三項。
  - 源頭是 D12 報告的結論「metadata 的 JSON 鍵名，文字沒有定義」。同一份報告的 D12-5 就引了 :89 的原句。
- 失敗情境：本節開頭（:13）宣稱只記「上游文字哪裡沒寫清楚」。維護者從上游更新時，會把這條當成上游的缺口去追。被稽核的 session 讀到也會以為 budget 寫成什麼形狀都行。真正該記的事實是：session 偏離了 :124，而 :34–36 寫明沒有驗證器擋得到。這件事現在被寫成了相反的意思。

**Important｜docs/measurements/2026-11-14-security-audit-trial/check.sh:19–20｜先截 140 字、後跑 sed 去識別，results.txt 的拒絕清單撐不起 README:28 那句**
- 證據：
  - check.sh:19 先做 `.[0:140]`，:20 才 `sed "s|$S|\$S|g"`。scratchpad 路徑本身就吃掉約 114 字。
  - 結果 results.txt:10 只剩 `Bash S=$S/sa-plugin/skills/securi`，:12 只剩 `Bash ls -la $S/sa-plugin/skills/s`。
  - README:28 寫「變數賦值、`grep`、`ls … ; ls …`」。這裡的 `;` 和後半段，在被引為證據的 results.txt 裡都看不到。
  - 我從 `<S>/runs/real.jsonl` 抽了完整指令，README 那句屬實（第三筆是 `ls -la <S>/sa-plugin/skills/security-audit/ ; ls -la <S>/audit-out/ 2>&1`）。問題是讀者無從核對。
  - 輸出會跟著路徑長度變。我改用較長的 `<S>/s2c-review-tmp` 重跑：其餘 28 行逐字相同，只有 :10、:12 變成 `Bash S=$S/sa-plugi`、`Bash ls -la $S/sa-`。
  - 截斷點落在路徑中間時，殘段不會被 sed 換掉，只剩本目錄 CLAUDE.md:18 的 grep 兜底。
  - 另外只有第一段 jq 經過 sed，:25、:31、:33 的輸出沒有。目前這幾行抽的欄位不含路徑。
- 失敗情境：
  - 讀者想核 README:28，results.txt 給不出依據。
  - A11 要為步驟 5 新開一支 check.sh，照這個寫法複製的話，同樣的截斷會再發生一次。
  - 改法是在 jq 裡先換掉路徑再截，例如 `--arg s "$S"` 配 `split($s)|join("$S")`。

**Smell｜check.sh:35、README:27｜`git status --porcelain` 看不到被 .gitignore 忽略的路徑，「沒有改到目標」的證據比宣稱窄**
- 證據：
  - clone 的 `.gitignore` 忽略了 `.claude/`、`.env`、`*.log` 等路徑。
  - run.sh:16 放行的 `Write Edit` 沒有限定路徑。
  - 我核過，這次的結論成立：real.jsonl 裡所有 Write／Edit 的 file_path 都在 `<S>/audit-out/run-1/` 底下，而且 `git -C <S>/target/claude-dd status --porcelain --ignored` 是空的。
- 失敗情境：之後照抄這個判準，session 寫進 clone 的 `.claude/settings.local.json` 會被判成「沒改到目標」。補上 `--ignored` 即可。

**Smell｜README:11、run.sh:18、results.txt:32–38｜照「跑法」重現不出 results.txt 後段，第二發探針還會蓋掉第一發**
- 證據：
  - probe1、probe2 都用 `MODE=probe` 跑，run.sh:18 兩次都寫進 `$S/runs/probe.jsonl`。
  - scratchpad 裡有 `probe1.jsonl`，表示當時手動改過名，「跑法」沒寫這一步。
  - results.txt:32–38（「## 探針」「## 各模型花費（real）」）不是 check.sh 產的，repo 裡也沒有產生它們的指令。
  - 我用 jq 從三份 jsonl 重算，數字全部對得上。
- 失敗情境：照 README「跑法」重做的人，第二發會蓋掉第一發的 jsonl，也產不出 :32–38。

**Smell｜CHANGELOG.md:26｜「試跑沒走到的各派一個 subagent 只讀乾跑」講得比實際多**
- 證據：skills/security-audit/CLAUDE.md:55 寫 D5d「facts 沒變：不另跑」，:69 寫 D16「(b) incomplete：不另跑」。這正是全域 §3.10 說的「用一句話概括一組同類項目」。
- 失敗情境：讀 CHANGELOG 的人以為每條沒實跑的分支都有乾跑，不會去看「沒走過」那一節。

**Smell｜docs/measurements/2026-11-14-security-audit-trial/README.md:37｜不寫內容的理由已經過期**
- 證據：
  - README:37 寫「那 1 筆 needs_validation 的內容與後續驗證不寫在這裡（公開 repo）」。
  - 同目錄 CLAUDE.md:16–17 寫那筆「已在 S1 修掉」。設計文件:3–4 直接寫出了內容（`scripts/dd-init-upgrade.sh --apply` 會跟著 symlink 寫到專案外）。
  - U4 限制的是「未修的弱點」。我讀了 findings.json 的 title，確認就是 S1-1 修掉的那筆。
  - S2-2 的計畫只改了 CLAUDE.md 那一句，README 這句沒有一起改。
- 失敗情境：公開 repo 的讀者讀到 README，會以為 claude-dd 還藏著一筆沒修的弱點。

**Smell｜skills/security-audit/CLAUDE.md:20｜從上游更新的步驟不處理上游刪掉或改名的檔**
- 證據：
  - :20 原文：「用上游的檔覆蓋過來」。第 3 步之後沒有任何一步重跑 :11 的 `diff -r`。
  - 試跑的主 session 第 2 個工具呼叫就是對整個 skill 目錄 `Glob **/*`（real.jsonl）。
- 失敗情境：上游把某個配套檔改名，舊檔留在 repo，跟著 `cp -r` 部署出去，之後的稽核 session 會把它讀進來。

## Not reported
- 步驟 3 的 jq `def tool_uses($name)` 與原式等價：`|` 和 `//` 的優先序沒變。④ 前後輸出相同；我在拋棄式目錄重跑，除了上面那兩行跟路徑長度有關的差異，results.txt:1–30 逐字相同，`/bin/bash` 3.2.57 的輸出也相同。
- check.sh:29 那句「$? 是緊鄰上一行 node 的結束碼」的註解正確。
- README 結果表的數字我全部重算過，都對得上：花費、wall 21.7 分、各模型花費、主 session 加 4 個偵察跑 Opus 而其餘 3 個跑 Sonnet、agent 次數 7、單元 2/1/9、verdict、兩支驗證器、HEAD 9584605、拒絕 3 次。
- README:20「叫得起來」的依據成立。probe1 第一個工具呼叫就 Read 了 prompt 沒給的 `<S>/sa-plugin/skills/security-audit/HUNTING.md`，之前沒有任何搜尋。real.jsonl 裡 `Base directory for this skill` 雖然命中 1 次，但那是 subagent 讀根目錄 CLAUDE.md 的 tool_result，不是 skill 載入訊息。
- skills/security-audit/CLAUDE.md 裡每段「」原句，我都對它被標的檔與節（Cost budget、Write isolation、Full audit setup 等）核過，全部正確。④ 只對四檔合併內容核過，抓不到這一類錯。
- 去識別：段落新增的每一行，加上試跑目錄與 skills/security-audit/CLAUDE.md，都沒有使用者名、`/tmp/`、`-Users-`、UUID。
- scratchpad 裡實際跑過的 run.sh、check.sh（HEAD 版）、三份 prompt（換回佔位後）與 repo 版逐字相同。
- install-dd-pipeline.sh 那一行的字母序與對齊都沒問題。`install_builtin_skills` 用 `cp -r` 整個目錄，tests/test-install.sh 動態比 `${#PROMOTED_SKILLS[@]}`，沒有寫死數字。
- ④ 記的「4a6,7」與 ①-b 的「5a7,8」是同一次插入的兩種對齊寫法，內容一樣。
- S1-judge.md:56「需使用者決定」那節還寫著待決定，但它屬於凍結的「發現」節（docs/reviews/CLAUDE.md 規定不改），選了 A 已經寫進「處置」:77、:87。
- agent description 指向模型自己叫不到的 dmi skill：這是設計使然，模型只能請使用者打 `/security-audit`。
- 「指令一覽」沒加 `/security-audit`：設計文件 A10 有理由，也有前例。
- 試跑目錄 CLAUDE.md:18 的 grep 把整份 CLAUDE.md 排除掉：目前該檔沒有洩漏，所以沒有實際的失敗情境。

## What I ran
- Read 了 prompt-common.txt；diff.txt 的 1–300、300–600、600–925 行；設計文件 1–50、150–229 行
- `diff` scratchpad 的 runs/run.sh、runs/check.sh 與 repo 版（check.sh 比 HEAD）→ 都 rc=0；三份 prompt 換回佔位後 → 都 rc=0
- `head` 與 `diff` 上游和 repo 的 SKILL.md → 2a3、5a7,8；`grep -n '^#' SKILL.md` 取節範圍
- python3 -I 抽 skills/security-audit/CLAUDE.md 的「」原句，逐檔做子字串比對 → 標的檔全部正確
- `grep -nF` 各原句在 SKILL.md 的行號；`sed -n '89p;112p;124p;126p' SKILL.md`
- `grep` 乾跑報告 D12、D14b、D15 的 run-metadata 段落，以及各報告的結論行
- jq 查 real.jsonl：Write／Edit 的 file_path 全在 `<S>/audit-out/run-1`；Bash 只有 6 次，3 次 is_error；拒絕的完整指令與錯誤訊息；各 agent 的 model；modelUsage
- jq 查 probe1、probe 兩份 jsonl：前幾個工具呼叫、init 的 plugins 欄位、result 的花費與拒絕數；`grep -c 'Base directory'` 三份 jsonl → real 1、probe 0、probe1 0
- `git -C <S>/target/claude-dd status --porcelain --ignored` → 空；`cat` clone 的 .gitignore
- jq 讀 findings.json 的 verdict 與 title（只讀這兩欄）
- 重跑 check.sh（④ 列過，但我要驗它的輸出跟路徑長度有沒有關、以及 bash 3.2 下是否相同）：在 `<S>/s2c-review-tmp` 放 real.jsonl 的路徑替換副本，其餘目錄用 symlink 指回原處，跑 `bash` 與 `/bin/bash`，再和 results.txt:1–30 diff → 只有 :10、:12 不同；3.2 與 5 的輸出相同。這個目錄還留著，沒刪
- `stat -f %SB` 看 scratchpad 各目錄的建立時間 → 全是同一秒，判斷不出先後，因此沒寫成 finding
- `git diff 6f2118a | grep '^+' | grep -nE '<使用者名|claude-501|/tmp/|-Users-|/Users/|UUID|my_project>'` → 只命中 CLAUDE.md:18 那個樣式本身；試跑目錄與 skills/security-audit/CLAUDE.md → 0 筆
- `grep` install-dd-pipeline.sh 的 node 檢查、`install_builtin_skills`、PROMOTED_SKILLS；tests/test-install.sh 的計數方式
- `git grep` 了：自動化全面掃描、security-auditor、disable-model-invocation／user-invoked、c1c8a8c
- commands/dd-init.md 的 `ls -l`／`ls -ld`；S1-b.md 與 S1-judge.md 的節標題；docs/reviews/CLAUDE.md 的規矩；CHANGELOG 未發布區塊的小節
- 兩個表格（skills/security-audit/CLAUDE.md:46–69、試跑 README:18–30）每列都以 `|` 開頭
- 用 `sed -n` 逐一核對所有引用的行號

## 需要外部查證
- 這條不在 diff 範圍內，但步驟 5 會撞到。設計文件:217 的 D5b 那發用 `--allowedTools "Skill Glob Bash(ls:*)"`，要列出 `~/security-audit-skill/claude-dd/`，那個目錄不在 cwd 也不在 --add-dir 內。試跑 real 那筆 `ls -la <S>/sa-plugin/… ; ls -la <S>/audit-out/ 2>&1` 兩段都在白名單內，照樣被 dontAsk 擋下；probe2 的白名單內複合指令（`; … | head -1`）卻沒被擋。三個可能原因（路徑在允許目錄外、`;`、`2>&1`）分不開。建議先用 haiku 跑一發 `claude -p` 只做 `ls ~/security-audit-skill/claude-dd/`，看會不會被擋。如果會，那一發的「permission_denials 是空的」判準在跑之前就註定不過，要先改旗標（例如加 `--add-dir`），或改用 Glob 當作「列目錄」的證據。

## 處置

- c-1（Important）採納：同 S2-a 的 a-4
- c-2（Important）部分採納：試跑的 `check.sh` 不改截斷順序 —— `results.txt` 是被引用的證據，改了就跟它脫鉤。改法：README「權限拒絕」那列縮成 `results.txt` 看得到的內容（變數賦值開頭的一串、`git ls-files | grep …`、`ls -la …`，每筆只留前 140 字）；目錄 CLAUDE.md 的 `check.sh` 那條加 ⚠️ 寫明「先截再換路徑，路徑一長殘段不會被換掉，照它寫新腳本時先換再截」；步驟 5 新開的 `check.sh` 照「先換再截」寫
- c-3（Smell）採納：`check.sh` 改成 `git status --porcelain --ignored`；對同一個 clone 重跑仍是 0 行，整份輸出與 `results.txt` 逐字相同；README 那列寫明 `--ignored` 是 S2 步驟 4 補的
- c-4（Smell）採納：同 S2-a 的 a-5
- c-5（Smell）採納：同 S2-a 的 a-3
- c-6（Smell）採納：同 S2-b 的 b-8
- c-7（Smell）採納：「從上游更新」第 3 步改成「刪掉本目錄裡 `LICENSE.txt`、`CLAUDE.md` 以外的檔，再把上游整份複製過來」，加第 4 步重跑 `diff -r` 確認只剩兩處插入與兩個 `Only in`
- 審查者留在 scratchpad 的 `s2c-review-tmp` 目錄：在 scratchpad 內、不進 repo
- 需要外部查證（D5b 那發 `ls ~/security-audit-skill/claude-dd/` 會不會被 dontAsk 擋）：步驟 5 先用 haiku 探針跑一發再定旗標
