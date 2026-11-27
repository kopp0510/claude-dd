# S1-c：審查者 C（全面，先從「漏掉的同步點與 repo 的規矩」下手）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），S1-a、S1-b、S1-c 三個在同一則訊息平行派出。
派工 prompt（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad；下面「發現」節同樣只換了路徑與使用者名稱）：

````text
先 Read <S>/tune-review/prompt-common.txt，照它做。你的代號是 S1-c。

你的方向（先從這裡下手，看完再全面看）：漏掉的同步點與 repo 的規矩。在各層 CLAUDE.md 搜「同批」「同步」「手動同步」「要一起」，讀到的規則逐條對這段 diff：CHANGELOG 的寫法、兩份 README 與 DD_PIPELINE_ARCHITECTURE.md 有沒有因為這三條規則而過期的句子、設計文件的進度表與規則區塊有沒有照 skills/task-planner/SKILL.md「進度表格式」、根目錄指路的寫法、docs/measurements/ 與 docs/reviews/ 各自的慣例、公開 repo 的去識別（量測檔與設計文件裡有沒有本機路徑、session 識別、不該公開的個人資訊）。另外看量測檔的「方法」：照它寫的指令與腳本，另一個人拿得到同樣的數字嗎，哪一步會卡住。
````

`prompt-common.txt` 全文（逐字，路徑去識別）：

````text
你是 claude-dd repo（<REPO>）8 步開發迴圈步驟 4 的審查者。職責：找漏洞，每條附證據（路徑:行，或指令與輸出），沒證據的不算。不寫優點、不客套。

審查範圍：段落 S1「照 2026-11-14 的量測調整三條規則」從 139bc41 到目前工作目錄的整段（五個 commit）。全部是文件與規則文字，沒有產品程式碼。

材料：
- diff 檔：<S>/tune-review/diff.txt（834 行）。**用 Read 的 offset/limit 每次 300 行讀到最後一行**：Read 一次讀太多會靜靜截斷、不報錯。
  ① 整段 diff ② 步驟 3 沒跑的說明 ③ 被改到的檔的整檔內容（根目錄 CLAUDE.md 整檔、CHANGELOG 的未發布節）④ 已跑過的驗證與預期值
- ④ 列的驗證都已跑過、結果如列，不要重跑（測試、CI step、安裝、claude -p 都不要跑）。「跑過」不代表結論對 —— 你懷疑它驗的不是它宣稱的東西，就指出來
- 被改到的檔（CLAUDE.md、CHANGELOG.md、docs/measurements/2026-11-14-session-cost.md、docs/designs/2026-11-14-loop-tuning-design.md）以 diff 檔那份為準；其他檔直接讀工作目錄（審查期間不會再變）
- 專案規則：根目錄 CLAUDE.md、各層 CLAUDE.md、~/.claude/CLAUDE.md（尤其 §3.10 寫文件的判準）
- 這一段的計畫與假設：docs/designs/2026-11-14-loop-tuning-design.md（在 diff 裡）

已知、不用再報的：計畫審查第 1 輪沒過、第 2 輪沒跑成，使用者選了「拿掉放手語，其餘直接做」（設計文件「假設」節有寫）；放手語沒有寫進任何檔，不在審查範圍。量測用的 transcript 不在 repo，數字重跑不了（量測檔「方法」「限制」有寫）。

只用手上的資料與讀檔、grep、git 指令判斷；需要外部查證的列出來交回，不要自己做。不要改任何檔、不要 commit。

輸出格式：
- 每條：級別（Critical / Important / Smell）｜檔:行｜問題｜證據（引原文或指令輸出）｜具體失敗情境（誰照這段做、會怎樣錯）
- Not reported：看過、判斷不是問題的，各一句理由
- What I ran：跑過的 grep / 讀過的檔
- 需要外部查證：每條一句
````

## 發現

S1-c 審查：段落 S1，範圍 139bc41..69c528d，五個 commit。結果 Critical 0、Important 4、Smell 0。

**[Important]｜CLAUDE.md「新增 Skill 步驟」第 3 步（diff ③-a 384–392 行）｜新例外沒有回指到第 3 步**
- 問題：新加的「照原文收」例外放在收編清單表格後面（③-a 726 行）。它改的是第 3 步的回報內容，但第 3 步本文一字沒改，還寫著「逐條引用原文回報哪一句讓它卡住、只能用猜的、或兩句互相矛盾」，也沒有指向例外的字。
- 證據：③-a 384–385 行是上面那句原文。同一份檔的 ③-a 673–678 行規定：「在規則文件裡加『例外條款』時，要掃同一份檔案裡所有把該規則寫死成指令的地方」。
- 失敗情境：下一次收第三方 skill，收編清單第 7 項會把人帶回「新增 Skill 步驟」逐步做。照第 3 步派乾跑的人看不到例外，乾跑 prompt 照舊要求列出「要猜」的句子，主對話又得到一份這次規則想拿掉的清單。

**[Important]｜CLAUDE.md 收編清單後的新段落（③-a 727 行）｜「清單沒有東西會用到」被現有範例推翻**
- 問題：新段落拿掉「要猜但做得完」清單的理由是「文字既然不改，清單沒有東西會用到」。但唯一的前例裡，這份清單有用處：上游更新時靠它決定要不要重跑乾跑。
- 證據：`skills/security-audit/CLAUDE.md:26–27` 寫「動到本檔引用的原句（…拿本檔「」裡的英文原句 `grep -F` 新版，找不到的就是被改了）時，照…第 3 步重跑相關分支的乾跑」。那些原句就在 86 行起的「乾跑發現」，也就是這份清單。
- 失敗情境：照新規則收的下一個 skill 沒有引用原句。上游改了一句「要猜」的條件句，只要那句不在分支表判準裡，就沒有東西觸發重跑。這正是設計文件 S1-3 寫的反證條件（diff 142 行：「更新上游時有一條『要猜』的分支被上游改了、沒人發現」）。新規則也沒寫這類 skill 更新上游時要怎麼偵測改動。

**[Important]｜CLAUDE.md「新增 Command 步驟」新條目（③-a 462 行）｜寫測試時要同步改的地方沒列出來**
- 問題：條目寫「exit code 加 `tests/` 的 bash 測試」，但沒提新測試檔要接到哪裡。CI 裡的測試是逐檔寫死的，`tests/CLAUDE.md` 也沒有「新增測試要接進 ci.yml」的規則。新腳本本身要走的「新增 Script 步驟」（`DD_SCRIPTS`、shellcheck 清單、架構文件的數字），條目也沒指過去，只指了 `--commands-only` 那條。
- 證據：
  - `.github/workflows/ci.yml:34-36`（shellcheck 清單只有三支測試）
  - `ci.yml:549-557`、`ci.yml:587-594`（逐檔 `run: tests/test-*.sh`）
  - 根目錄 CLAUDE.md「目錄結構」tests 那行列舉了三支
  - `DD_PIPELINE_ARCHITECTURE.md:135-136` 的 CI 防線表
- 失敗情境：有人照這條規則新開 `tests/test-<x>.sh`。本機跑綠，CI 卻從來不跑它、也不做 shellcheck，而且沒有任何檢查會報錯。

**[Important]｜docs/measurements/2026-11-14-session-cost.md「方法」（diff 185–190 行）｜要重跑卻找不到 transcript**
- 問題：檔裡要求「引用數字前先重跑」，但只寫了「那個 session 的 transcript jsonl」，沒寫路徑樣式，也沒寫怎麼從時間範圍認出是哪一份。前例 `docs/measurements/2026-10-23-reviewer-real-sessions.md` 寫了 `~/.claude/projects/**`，加上篩選條件。另外，jq 那條「第一個請求」指令沒有套 python 用的時間窗。transcript 裡如果有 17:42:47 之前的紀錄，`head -1` 抓到的就不是「session 一開始」，97,571 這個數字就不成立。
- 證據：diff 186 行「只算主對話…時間範圍…」；189 行的 jq 沒有 timestamp 條件。
- 失敗情境：就算在 transcript 被清掉之前，在同一台機器上照「方法」重跑，第一步也卡在「是哪一個 jsonl」，只能猜。這樣「引用前先重跑」做不到，引用的人會直接抄快照數字。

**Not reported**（看過，判斷不是問題）
- 進度表規則區塊：與 `skills/task-planner/SKILL.md` 的規則區塊用 `diff` 比，逐字相同；表頭也相同。
- 根目錄指路：寫法與位置合 §4.4（在第一個 `##` 之前）。139bc41 那時沒有指路，因為 security-audit-intake 的 S1、S2 都已標 DONE、指路已刪，所以不會有兩條並存。
- 審查報告放 `docs/reviews/2026-11-14-loop-tuning/`：合 `docs/reviews/CLAUDE.md` 的子目錄慣例，gate 的樣式 `(^|/)S[0-9]` 也比對得到。
- 去識別：量測檔、設計文件、CLAUDE.md、CHANGELOG 用 `-Users-`、`-private-tmp-`、`/private/tmp/`、`/Users/`、`scratchpad/`、UUID 掃過，只命中描述掃描樣式的句子。
- 「10 條、除了兩條」：S2-judge.md「採納（Important）」逐條數過，確實是 10 條，兩條例外的文字對得上。
- CHANGELOG：新條目在 `## 未發布` 的 `### Changed`，沒動已發布的區塊。
- 兩份 README 與 DD_PIPELINE_ARCHITECTURE.md：只有連到收編清單的指標，沒有因這三條規則過期的句子。
- 量測數字內部一致：171 = 157 + 8 + 4 + 2；136 = 157 − 21；1007 − 673.4 ≈ 334；05:46 到 10:08 約 4.4 小時。乾跑 21 個 = 設計文件的 16 個加補跑的 5 個。
- 「交回的全文會一直留在主對話的 context 裡」：同一份量測有 12 次自動壓縮，所以這句說過頭了。但它不會讓人照著做錯，所以沒報。

**What I ran**
- Read prompt-common.txt；diff.txt 分三次讀完 1–835 行。
- `git status` / `git log` / `sed -n 1,8p CLAUDE.md` / `git show 139bc41:CLAUDE.md` → 工作目錄乾淨；139bc41 那時沒有指路。
- `grep` security-audit-intake 設計文件的狀態 → S1、S2 都是 DONE。
- 用 `sed` 抽出 task-planner 與 loop-tuning 設計文件的規則區塊，再 `diff` → 相同。
- `grep -n 'tests/' .github/workflows/ci.yml` → 測試逐檔寫死（34–36、549–594 行）。
- `grep` 兩份 README 與 DD_PIPELINE_ARCHITECTURE.md 的「乾跑、沙盒臂、收編」→ 只有連到清單的指標。
- 讀 `skills/security-audit/CLAUDE.md` 的標題與 16–30、86–92 行 → 第 8 步靠「本檔引用的原句」。
- 讀 S2-judge.md 的 24–40、69–90 行 → 採納（Important）是 10 條。
- 讀 `docs/reviews/CLAUDE.md` 與 `scripts/check-claude-md.sh` 裡的 `docs/reviews` 部分 → 子目錄慣例成立。
- 讀 `docs/measurements/2026-10-23-reviewer-real-sessions.md` 1–40 行 → 前例有寫 transcript 位置。
- 去識別的 `grep -nE` 掃四份被改到的檔 → 只命中描述樣式的句子。
- `grep` security-audit-intake 設計文件裡的乾跑、試跑派工 → 乾跑 16 + 5 = 21；試跑是 `claude -p`，不算主對話派的 agent。

**需要外部查證**
- 136 個沙盒臂：要逐一讀那次 transcript 裡 157 個 sonnet Agent 呼叫的 description，確認沒有用「乾跑」而不是「dry-run」命名的乾跑，也沒有沙盒臂以外的派工。
- 「交回訊息」的分類：要拿 transcript 的一則樣本確認 `queued_command` 且 `isMeta` 的那一類真的是 subagent 的交回全文。新規則「交回全文留在 context」的量化依據就是這個分類。
- 時間窗：python 的 `t > end` 用字串比較，帶毫秒的 `…10:30:08.xxxZ` 會被排除。要確認最後一秒的紀錄沒有被漏算。

## 處置

- 第 1 條（Important，新例外沒有回指到第 3 步）：S1-3 撤回之後這個例外不存在了，不用回指
- 第 2 條（Important，「清單沒有東西會用到」被現有範例推翻）採納：同 S1-b 的 Important 3，撤回 S1-3
- 第 3 條（Important，寫測試時要同步改的地方沒列）採納：同 S1-b 的 Important 5
- 第 4 條（Important，找不到 transcript、jq 沒套時間窗）採納：量測檔「方法」補上路徑樣式與找法（`grep -l '2026-11-13T17:42:47' ~/.claude/projects/*/*.jsonl`，當天只命中一份）；
  jq 那條註明不套時間範圍、取到的請求時間是 `2026-11-13T12:54:31Z`
- Not reported 裡的「交回的全文會一直留在 context 說過頭」：照改，寫成「交回的訊息會整份進主對話的 context」
- 需要外部查證 ①（136 個是不是都是沙盒臂）：查了 —— 157 個 sonnet 裡不含 `dry-run` 的 description，去掉 arm、docker、control、baseline、final-text、`v3…` 這些臂名之後剩 0 個；寫進量測檔的限制
- 需要外部查證 ②（「交回訊息」的分類）：查了 —— 範圍內 `queued_command` 且 `isMeta` 的紀錄，開頭都是 `[Subagent hand-back`；寫進量測檔的限制
- 需要外部查證 ③（字串比時間會不會漏最後一秒）：查了 —— 時間以 `2026-11-14T10:30:08` 開頭的紀錄 0 筆；寫進量測檔的限制
