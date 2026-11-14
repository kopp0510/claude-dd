# S2-a：審查者 A（全面，先從「漏掉的同步點」下手）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），S2-a…S2-d 四個在同一則訊息平行派出。
派工 prompt（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad；下面「發現」節同樣只換了路徑與使用者名稱）：

````text
先 Read <S>/s2-review/prompt-common.txt，照它做。你的代號是 S2-a。

你的方向：全面審查，但先從「漏掉的同步點」下手 —— 在各層 CLAUDE.md 搜「新增」「同時改」「同批」「要一起」「同步」「手動同步」「CI 不驗」，把讀到的規則逐條對這段 diff，找該改沒改、改了一半、或改法跟規則寫的不一樣的地方。
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

S2-a 報告：沒有 Critical；4 條 Important、1 條 Smell。最該先處理的是兩份 README 的前置需求沒提上游要的沙盒。

範圍：6f2118a 到目前工作目錄，含 fc2ccb0、aa9b162、d36e5d6，以及步驟 3 還沒 commit 的兩個檔。路徑都相對 repo 根目錄，scratchpad 寫成 <S>。

1. Important｜README.md:33-37、README.zh-TW.md:34-38（前置需求）｜收編時沒巡到上游的第三項需求：OS 強制的沙盒。沒有它，full audit 一筆都到不了 `confirmed`，兩份 README 卻一個字都沒提
   證據：
   - 上游 <S>/vendor/security-audit-skill/README.md:90：「An OS-enforced sandbox for target-controlled builds, tests, … Without these controls, the workflow keeps the lead as `needs_validation` instead of executing target code.」
   - SKILL.md:36：「Run target-controlled builds, tests, … only inside an OS-enforced sandbox that provides all of these controls」
   - `grep -nE '沙盒|沙箱|sandbox' README.md README.zh-TW.md` → 0 筆。
   - 同型的可選依賴有寫：README.md:36「Optional: `ffmpeg` — GIF export in tech-diagram-gif; without it that skill delivers SVG」。
   - 根 CLAUDE.md:255 把「前置需求段落」列在 CI 不驗、要手動同步的區塊；:263 的觸發時機含「**收編新的 vendored 元件**時，逐項巡一遍」。設計文件 A12 #4 只評了 Node。
   失敗情境：使用者照 README 裝好，對自己的 web 專案打 `/security-audit` 做完整稽核，結果全是 `needs_validation`、0 筆 confirmed。README 沒提沙盒，他會以為是 skill 品質差，不知道是少了一項會讓結果退化的可選依賴。ffmpeg 那條就有寫退化行為。

2. Important｜skills/security-audit/CLAUDE.md:23、:40（「從上游更新」第 6 步）｜上游更新後要不要重跑乾跑，條件比房規窄；第 1–7 步也沒有 `$<數字>` 自查
   證據：
   - 根 CLAUDE.md:53：「部署前先乾跑（新增或改寫都要）」。
   - 本檔 :23：「上游動到「分支清單」那類條件句時，照根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步重跑那幾條的乾跑」。
   - 本檔 :40 把判準限定成「`SKILL.md` 裡會改變寫不寫檔、派不派 agent、要不要停下來問的條件句」。
   - 但乾跑發現有好幾條引的是配套檔：:100 引 HUNTING.md 與 VALIDATION-AND-REPORTING.md，:102、:104、:109 引 RECONNAISSANCE.md。
   - 根 CLAUDE.md:73-75 的第 7 步（`grep -rn '\$[0-9]' skills/*/SKILL.md commands/*.md`）不在本檔第 1–7 步裡。
   失敗情境：
   - 上游把 RECONNAISSANCE.md:150 `candidate` 列的 `unresolved` 改成必填。SKILL.md 的條件句沒變，所以第 6 步不觸發、沒人重跑乾跑；:109「驗證器照表放行，沒寫理由也會過」就留在部署版裡變成錯的。
   - 上游 SKILL.md 加進一個 `$1`，照 7 步走完不會 grep 到。這個 skill 是 user-invoked，本來就用 `/security-audit <要求>` 帶參數叫，那個 `$1` 會被靜靜換成第一個參數。

3. Important｜CHANGELOG.md:26-27（另見 skills/security-audit/CLAUDE.md:71）｜「沒有一條走不下去」把 D11c 的限定條件壓掉了，而且「情境刻意給的」這個歸因站不住
   證據：
   - CHANGELOG:26-27：「試跑沒走到的各派一個 subagent 只讀乾跑；沒有一條走不下去」。
   - CLAUDE.md:71：「乾跑判「做不完」的只有 D11c，停在「使用者沒回應」—— 那是乾跑情境刻意給的」。
   - 但 <S>/dry/prompt-D14a.txt:12 給的是同一個條件：「使用者對你的提議沒有回應（headless）」。report-D14a 的結論卻是「做得完…使用者無回應時文字沒有明確指示，要靠 HUNTING.md 的「priority order／deferred」自己推」。
   - 同一個條件得出兩個結論，差別在文字有沒有可以推的後路，跟情境怎麼設無關。本檔 :80-81 自己也把它列成文字缺口；唯一一次實跑（試跑）就是 `-p` headless。
   失敗情境：使用者讀了 CHANGELOG，在 `claude -p` 或 CI 裡對大 repo 跑 `/security-audit`、不設 budget（走 D11c）。parent 提出 budget 沒人回，文字沒有下一步，CHANGELOG 卻說每條都走得完。這正是全域 §3.10「縮短既有文字時，條件最容易被改掉」那一型。

4. Important｜skills/security-audit/CLAUDE.md:108、:90-91（乾跑發現）｜有兩條寫成「上游文字沒寫」，其實 SKILL.md 寫了
   證據（:108，budget 型別）：
   - 原文：「`run-metadata.json` 的鍵與型別沒定義：`budget` 在試跑裡寫成物件…，乾跑讀成一個數字」。
   - SKILL.md:89 列了鍵：「`run_id`, `repo`, `target`, `source_ref`, `profile`, `scope_paths`, `budget` (null if unset), … `run_status: "in_progress"`」。
   - SKILL.md:124 給了 budget 的型別：「record `budget` in `run-metadata.json` as a maximum number of agent invocations」。
   - 試跑的 `<S>/audit-out/run-1/run-metadata.json`，`jq keys` 的鍵名跟 :89 對得上；但 `jq '.budget|type'` 是 `object`。這是 session 沒照 :124 寫，不是文字沒定義。
   證據（:90-91，Phase 5 驗證者）：
   - 原文：「沒列 Phase 5 的 fresh verifier，驗證保留額要不要把它算進去沒寫（D11c、D13、D15）」。
   - SKILL.md:124 有：「one surviving candidate is one or two verifier assignments depending on profile」。
   - VALIDATION-AND-REPORTING.md:124 有：「Every other profile keeps the two passes separate」。
   - 被引的 D15 自己就是這樣讀的，<S>/dry/report-D15.txt:6：「standard 每個 candidate 要 Phase 3 + Phase 5 兩個 agent（… `about 1 or 2 agents per expected candidate`）」。
   - ④ 的回對只驗原句存不存在，沒驗缺口是不是真的。
   失敗情境：
   - 維護者照本檔 :13-14「要改行為就改上游文字本身」去補這兩個「缺口」，改的是上游其實寫了的句子，vendored 行「其餘內容未改」就不成立了。
   - 之後替 `run-metadata.json` 寫檢查的人讀到「型別沒定義」，會讓物件型的 `budget` 過關。

5. Smell｜docs/measurements/2026-11-14-security-audit-trial/README.md:12、results.txt:32-38｜results.txt 有兩節找不到產生指令，跑法第 4 步卻把整份寫成 check.sh 的輸出
   證據：
   - README.md:12：「`./check.sh <scratchpad>` → `results.txt`」。
   - check.sh 只讀 `real.jsonl`（check.sh:5），印到「## 目標 repo 有沒有被改」為止。
   - results.txt:32「## 探針」與 :36「## 各模型花費（real）」在 repo 裡找不到產生它們的指令。
   - 兩次探針都用 `MODE=probe`，run.sh:18 都寫進 `"$S/runs/$MODE.jsonl"`，probe2 會蓋掉 probe1。
   - 根 CLAUDE.md:329：「寫進文件前把實測指令與輸出一起附上」。
   失敗情境：手上還有原始 jsonl 的人想重核 README 花費列的「Opus US$11.96、Sonnet US$0.74」或 probe1 的兩筆 result，照跑法做不出這兩節。CLAUDE.md:10 寫了「加上兩次探針與各模型花費」，但沒寫怎麼算。

Not reported
- fc2ccb0：
  - 三處改動都在「處置」節（S1-b.md:171 之後、S1-judge.md:73–88），沒違反 docs/reviews/CLAUDE.md:36「前兩節寫完就不改」。
  - 「使用者選 A」對得上 S1-judge.md:59 的選項 A。
  - A16 的 `ls -ld` 對得上 commands/dd-init.md:58、:108、:223；A19 的 Y、Y5、YD 對得上 docs/measurements/2026-11-14-dd-init-symlink/mkprompt.sh:21。
- 新增 Skill 第 2 步與收編清單 #7 的同步點都做齊了：
  - 部署陣列；
  - 兩份 README 的標題數、安裝步驟數、Promoted 表格列、授權列；
  - 根 CLAUDE.md 目錄結構；
  - 架構文件的元件數、授權清單、部署清單那句。
  - `git grep` 找不到殘留的 13。
- 指令一覽沒列 `/security-audit`：A10 引的前例屬實，skills/writing-great-skills/SKILL.md:4 有 dmi，指令一覽也沒列它。
- node 測試不在 CI：照 A8 的決定，skills/security-audit/CLAUDE.md:32 照實寫了。
- DD_PIPELINE_ARCHITECTURE.md:21「不加 runtime 依賴（只用 bash + jq 或 python3 擇一）」是既有的句子；Node 本來就是安裝腳本的硬性需求（install-dd-pipeline.sh:319-323）。
- agents/security-auditor.md 的 description「(用 /security-audit)」：dmi 的 skill 模型叫不到，但這句是請使用者去打指令，說得通。本文 :122 照 A9 不改。
- skills/security-audit/CLAUDE.md:42「原句都用 `grep -F` 回對過」：D12-12 沒回對到、5 條要正規化才命中；但本檔實際引用的英文句，④ 全部命中，沒有造成錯。
- 去識別：diff 涉及的 40 個檔掃 `-Users-|-private-tmp-|/private/tmp/|/Users/|<使用者>`，命中的全是描述樣式的句子，沒有真路徑。
- 進度表：S2 的起點 6f2118a 與 `.git/dd-segment-base` 一致。fc2ccb0 標（S1）卻落在 S2 範圍內，不影響「接手」時比對 `（S2-`。
- 給主對話的提醒（不是發現）：
  - ④ 記 SKILL.md 的 hunk 是「2a3、4a6,7」，實際 `diff` 是 `2a3`、`5a7,8`（①-b 那份是對的）。寫進 S2 報告的「派工」節之前要改。
  - S2 步驟 5 的反向與反向對照兩發，cwd 是 claude-dd 的 clone，又放行 Read、Glob、Grep。clone 的根 CLAUDE.md:32 寫著「security-audit…（user-invoked）」。這個 session 一讀 `skills/security-audit/` 的檔，harness 就把該目錄的 CLAUDE.md（:4「只在使用者打 `/security-audit` 時載入」）注入了 context（repo 內的情況，我這次實際看到）。這兩句可能讓模型不去叫拿掉 dmi 的那一份，削弱反向對照的鑑別力。

What I ran
- 讀 <S>/s2-review/prompt-common.txt；diff.txt 分 1–300、301–600、601–925 三段讀完 → 讀完
- `git ls-files` 抓所有 CLAUDE.md；`git grep -nE '新增|同時改|同批|要一起|手動同步|CI 不驗|一起改|逐項巡'` 與另一次 `同步`（排除根 CLAUDE.md 與全域模板，兩份另外直接讀）→ 規則清單
- 讀 docs/reviews/CLAUDE.md；`grep '^## '` S1-b.md、S1-judge.md；`git show --stat fc2ccb0` → fc2ccb0 只改處置節
- 設計文件 `sed` 17–73、150–230 → S2 計畫、A5–A21、進度表規則
- `diff` 上游 SKILL.md 與 repo 版 → `2a3`、`5a7,8`
- `git grep disable-model-invocation` → writing-great-skills:4、security-audit:3
- `git grep -iE 'security-auditor|security-audit|全面…'`（排除 docs/reviews 與 skill 目錄）→ 每一處逐條核過
- 對兩份 README、架構文件、根 CLAUDE.md、安裝腳本、tests/test-install.sh、ci.yml、全域模板、dd-init.md、UPGRADING.md 各 `grep 'writing-great-skills|tech-diagram-gif|vendored'` → 列舉點都已同步
- `git grep -E '1[34] ?(個|promoted|Skills|skills)'` → 沒有殘留的 13
- README.md 第 25–48 行與第 150–166 行；`grep 'sandbox|沙盒|沙箱'` 兩份 README → 0 筆
- 上游 README 第 60–95 行、上游 LICENSE 開頭 → Requirements 三項
- SKILL.md 的 `grep '^#'`、第 12–46、84–136、170–195 行；VALIDATION-AND-REPORTING.md:124；validate-coverage-ledger.cjs:555–565；RECONNAISSANCE.md:150 → 逐條核乾跑發現
- 各份 dry report 的【結論】；prompt-D11c、D14a 的條件；D12、D14b、D15 的 budget 與 run-metadata、D11c、D13、D15 的 Phase 5 grep → 歸因核對
- 對 <S>/audit-out/run-1/run-metadata.json 跑 `jq keys`、`jq '.budget|type'` → 鍵名對上 SKILL.md:89；budget 是 object
- `cat` `.git/dd-segment-base` → 6f2118a
- 讀安裝腳本的 show_completion、install_builtin_skills、PROMOTED_SKILLS；grep tests/test-install.sh → 沒有別的列舉點
- 去識別 grep 掃 diff 涉及的 40 個檔 → 只命中樣式描述
- results.txt 的 `grep '^## '`；README 與 CLAUDE.md 裡寫 check.sh 的行 → 第 5 條

需要外部查證
- Claude Code 的 sandbox 功能能不能滿足 SKILL.md:36 的四項控制（斷網、空環境、唯讀 target、資源上限）。這決定第 1 條要寫成「可選依賴：開 X」還是「目前沒有辦法」。
- 部署後的 `~/.claude/skills/security-audit/CLAUDE.md`，在 skill 被叫起、讀配套檔時會不會被當成記憶注入（A21③，repo 外的情況）。
- 用 `/security-audit <參數>` 叫 dmi skill 時，SKILL.md 內文的 `$1` 會不會被替換。根 CLAUDE.md:73 那條是 2026-10-30 在 dd-loop 上量到的，第 2 條②以它為前提。

## 處置

- a-1（Important）採納：兩份 README 前置需求在 ffmpeg 那條後面加一條可選項 —— 給 `/security-audit` 用的 OS 層沙盒（照上游 README 的 Requirements 寫四項控制），沒有它時 full audit 不執行目標程式碼、要實跑才能確認的線索停在 `needs_validation`；Claude Code 自帶的 sandbox 能不能滿足四項寫「沒驗證」（外部查證那條沒查）
- a-2（Important）採納：`skills/security-audit/CLAUDE.md`「從上游更新」加第 6 步 `grep -n '\$[0-9]' skills/security-audit/SKILL.md` 要沒有輸出；重跑乾跑的條件（現在是第 8 步）改成「動到分支表判準所說的條件句，或動到本檔引用的原句（四份 `.md` 都算）」，附怎麼找（本檔「」裡的英文原句 `grep -F` 新版）
- a-3（Important）採納：CHANGELOG 那句改成「乾跑判「做不完」的只有大 target 沒設 budget 那條：提議 budget 要先知道偵察後才有的 unit 數，headless 時提議之後也沒有下一步」；`skills/security-audit/CLAUDE.md` 分支表下那段拿掉「那是乾跑情境刻意給的」，改寫兩個卡點，並寫明同樣「使用者不回應」的 D14a 走得完是因為 HUNTING.md 有後路。D11c 算不算「不能用」交使用者決定（見 `S2-judge.md`）
- a-4（Important）採納：:108 改寫 —— SKILL.md 列了至少要有的鍵、也寫了 `budget` 是「a maximum number of agent invocations across all phases」，試跑的 session 寫成物件是偏離了這句、沒有東西擋；真的沒給鍵名的只有 selected companion files、prior-run paths、shared-file owners。:90-91 改寫成「每個 candidate 要保留幾個 verifier 散在三句，要自己拼」，三句原文都列出
- a-5（Smell）採納：試跑 `check.sh` 補「## 探針」「## 各模型花費（real）」兩節的產生指令，用同一份輸入重跑，`bash` 與 `/bin/bash`（3.2.57）的整份輸出都與 `results.txt` 逐字相同（diff rc=0）、`shellcheck -S warning` 過；README 跑法第 3 步補「probe1 跑完先把 `runs/probe.jsonl` 改名成 `runs/probe1.jsonl` 再跑 probe2」；目錄 CLAUDE.md 的 `results.txt` 那條改成「`check.sh` 的輸出」
- 給主對話的提醒 ①（④ 的 `4a6,7`）：派工材料不改（派工節照當時送出的逐字記）；勘誤記在 `S2-judge.md`
- 給主對話的提醒 ②（反向對照臂可能被 clone 裡的「user-invoked」字樣壓住）：帶進步驟 5，見 `S2-judge.md` 處置
- 需要外部查證：沙盒四項 → 沒查，README 寫「沒驗證」；部署後的 skill CLAUDE.md 會不會被注入 → 步驟 5 正向那發的 jsonl 查；dmi skill 的 `$1` 會不會被換 → 沒另外量，第 6 步的自查照做就不必知道答案
