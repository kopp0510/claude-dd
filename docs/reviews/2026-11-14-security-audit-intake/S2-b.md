# S2-b：審查者 B（全面，先從「文件裡的宣稱在 HEAD 還成立嗎」下手）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），S2-a…S2-d 四個在同一則訊息平行派出。
派工 prompt（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad；下面「發現」節同樣只換了路徑與使用者名稱）：

````text
先 Read <S>/s2-review/prompt-common.txt，照它做。你的代號是 S2-b。

你的方向：全面審查，但先從「文件裡的宣稱在 HEAD 還成立嗎」下手 —— diff 裡每一句引別處的敘述（檔名、節名、commit hash、數字、「已修掉」「見 X」「逐字相同」「沒有一條走不下去」這類），自己 grep / 讀檔核一次；含兩個宣稱的句子兩個都要核。
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

S2-b 審查結果：Critical 0／Important 4／Smell 5。範圍是 6f2118a 到工作目錄（fc2ccb0、aa9b162、d36e5d6，加上步驟 3 還沒 commit 的改動）。這次先核文件裡的宣稱。

## Findings

Important｜skills/security-audit/CLAUDE.md:71-72、CHANGELOG.md:27｜「沒有一條分支走不下去。乾跑判「做不完」的只有 D11c，停在「使用者沒回應」—— 那是乾跑情境刻意給的」這句的歸因，和 D11c 報告自己寫的結論相反｜證據：<S>/dry/report-D11c.txt【結論】「做不完。……主要缺口是 D11c-1 與 D11c-2：提議 budget 要先知道 unit 數，unit 數要偵察才有，偵察前又得先過 budget gate。」D11c-1 那條的處置是「用情境給的 60 units 代入」，也就是說算得出提議數字，只是因為 prompt 先給了 unit 數（<S>/dry/prompt-D11c.txt：「假設 target 很大（例如 ledger 會種出 60 個 unit）」）。D11c-8 另外指出「提議但未確認」算 set 還是 unset 文字沒說，所以「答應就走 D11a」是這份檔自己補的讀法，而同一份檔第 13 行的 ⚠️ 禁止補讀法。另外，設計文件 A6 的關卡是「有分支因此不能用 → 停下回報使用者」，能放行靠的就是這句｜失敗情境：在互動 session 對大型 repo 跑 `/security-audit` 而且沒設 budget 時，parent 照 SKILL.md:124、:126 要先提議 budget、再過偵察前的 gate，但偵察前沒有 unit 數，文字也沒給估法，提議只能用猜的。維護者讀這句會以為「只有 headless 才卡」，就不會把這個循環依賴當成擋路的問題處理。

Important｜skills/security-audit/CLAUDE.md:46-69（分支表）｜分支表漏了一條符合它自己判準（「會改變……派不派 agent」的條件句）的分支：focused reconnaissance｜證據：SKILL.md:126「Add focused reconnaissance only after repeating this gate for each extra call」；RECONNAISSANCE.md:57「if the budget gate in `SKILL.md` blocks a focused agent, launch nothing for it, seed the unmapped area as a `deferred` ledger unit with reason `budget_cannot_reserve_critics_and_validation`, and disclose the gap in the report」。試跑沒走到：results.txt 的 spent_breakdown 是 `"reconnaissance":4`。乾跑也沒走到：report-D8「standard 無需額外 focused recon」、report-D12「focused recon：0」，report-D14b 只是在情境裡假設它已經發生，沒走「gate 擋下 → 種 deferred unit」這條。本檔只在第 135 行「沒走過」裡順帶提到這句｜失敗情境：CHANGELOG.md:26 的「試跑沒走到的各派一個 subagent 只讀乾跑」與表上「封閉式判準」都暗示表已經列全，但這條派工分支從沒被走過。「從上游更新」第 6 步規定「上游動到「分支清單」那類條件句時……重跑那幾條的乾跑」，這條不在清單上，所以上游改了這句也不會觸發重跑。

Important｜skills/security-audit/CLAUDE.md:74-128（乾跑發現）｜漏記了幾份報告在自己【結論】裡排第一的問題。報告只存在 scratchpad、不進 repo，這份檔是唯一會留下來的紀錄｜證據：report-D12【結論】「最大的文字問題是 D12-1（gate 最小值不含 hunter，通過後仍可能 0 hunters）與 D12-8」，本檔沒有 D12-1。核原文：SKILL.md:126 的最低保留額是 4 個偵察＋critic＋至少 1 個 verifier，不含 hunter；:132 卻是「Assign hunters … until the hunting allowance is spent」。report-D10【結論】「最影響結果的兩處是 D10-1（scoped 與 profile 是否並存，文字沒明寫）與 D10-2」，本檔第 104 行只記了 D10-2 與 D10-4，沒有 D10-1。report-D15【結論】列的「D15-5/D15-7 ledger 沒有放 decision/disposition 的欄位」本檔也沒有｜失敗情境：上游之後改了 Cost budget 或 scoped 的文字，維護者照「從上游更新」第 6 步拿本檔的發現清單決定要重核哪些已知缺口，D12-1、D10-1、D15-5 不在清單上，就不會被重核。這份檔也沒寫「乾跑發現」是怎麼從 119 條裡挑出來的，讀的人會以為已經列全。

Important｜skills/security-audit/CLAUDE.md:16-24（從上游更新）｜更新步驟漏了專案規則裡 CI 不擋、而且專門針對 SKILL.md 內文的 `$<數字>` 自查｜證據：根目錄 CLAUDE.md「新增 Skill 步驟」7：「SKILL.md 與 `commands/*.md` 內文不要出現 `$<數字>`：帶參數呼叫時會被換成第 N 個參數、不報錯……自查：`grep -rn '\$[0-9]' skills/*/SKILL.md commands/*.md`」。`grep -n -F '$[0-9]' .github/workflows/ci.yml` 沒有輸出，CI 的 step 清單裡也沒有這項。本檔第 1–7 步只有 clone、diff、覆蓋、LICENSE、node 測試、乾跑、install｜失敗情境：上游哪天在 SKILL.md 加了含 `$1` 的 shell 範例，照第 1–7 步做全部會過，部署後使用者打 `/security-audit 對這個 repo 做完整稽核` 時那段文字會被換掉，而且不報錯。這是 vendored 文字最可能踩到的地方。

Smell｜docs/designs/2026-11-14-security-audit-intake-design.md:46（A19，fc2ccb0 改的）｜「S1 步驟 4 加的 Y、Y5、YD 例外」歸因錯了：Y 在 S1-3 就已經存在｜證據：`git show a0aa58a:docs/measurements/2026-11-14-dd-init-symlink/results.txt` 第 31 行「- Y：CLAUDE.md 是指向專案裡 AGENTS.md 的 symlink，「寫檔前」那題答「要」」、第 59 行「3/3 綠：Y」。Y5、YD 到 96aaa42 才出現。S1-b.md:185 的處置也只寫「加了答「要」的臂 Y、Y5、YD」進重跑清單與驗收，不是新增這些臂｜失敗情境：有人照 A19 追「答要」這個例外是什麼時候進協定的，會判成 S1-3 的協定裡沒有答「要」的臂，誤讀 a0aa58a 的結果。一個字的歸因錯誤，也就是全域 §3.10 的「歸因要能被反證」。

Smell｜skills/security-audit/CLAUDE.md:69（D16 那列）｜「(b) incomplete：……由 D12、D13、D14a、D14b、D15 的乾跑走到」列進了兩條沒走到 incomplete 的分支｜證據：report-D13 第 38 行最後的 metadata 是 `run_status: "in_progress"`（SKILL.md:133 那條本來就是 deferred 再用 final-clean critic 記缺口，不會變 incomplete）；report-D14a 停在提議，也沒走到 incomplete。真的寫出 incomplete 的只有 D12（`budget_cannot_fund_reconnaissance_and_reserves`）、D14b（`critic_budget_exhausted`）、D15（`validation_budget_exhausted`）｜失敗情境：結論「(b) 有人走過」照樣成立，但清單多列了 D13、D14a，下次重跑時會拿它們去驗 incomplete，結果驗不到。

Smell｜CHANGELOG.md:26｜「試跑沒走到的各派一個 subagent 只讀乾跑」用一句話概括了整組分支，有例外｜證據：分支表 D5d「facts 沒變：不另跑」、D16「(b) incomplete：不另跑」；再加上前面那條 focused recon。同一段第 27 行又說「沒走過的分支記在……」，前後自己打架｜失敗情境：只讀 CHANGELOG 的人會以為每條沒試跑的分支都有乾跑過。這是全域 §3.10「不要用一句話概括一組同類項目」那條。

Smell｜docs/measurements/2026-11-14-security-audit-trial/README.md:37｜「那 1 筆 needs_validation 的內容與後續驗證不寫在這裡（公開 repo）」的理由已經過期｜證據：同目錄 CLAUDE.md:17「報告裡那筆 claude-dd 的安全線索已在 S1 修掉」；設計文件第 3–4 行已經公開寫出那筆是什麼；CHANGELOG `### Fixed` 也有。S2-2 的計畫只要求 README 改「還沒收進 repo」那句，沒處理這句｜失敗情境：讀者看到「公開 repo 所以不寫」，會以為還有一個沒修的弱點，其實已經修了。

Smell｜docs/measurements/2026-11-14-security-audit-trial/results.txt:31-38、CLAUDE.md:10｜「探針」與「各模型花費（real）」這兩段沒有產生指令｜證據：`grep -rn 'costUSD\|probe1' docs/measurements/2026-11-14-security-audit-trial/*.sh` 沒有輸出，check.sh 只印 `modelUsage|keys`。數字本身我用 jq 對 <S>/runs/real.jsonl、probe1.jsonl、probe.jsonl 重算過，逐筆相同｜失敗情境：README 引用的「Opus US$11.96、Sonnet US$0.74」沒有指令可以重現。根目錄 CLAUDE.md 規定「寫進文件前把實測指令與輸出一起附上」。

## Not reported

- ④（派工材料）寫「SKILL.md 的 2a3、4a6,7」，但 ①-b 與我重跑的 `diff` 都是 `2a3`、`5a7,8`，插入內容相同。這不在 repo 裡，但派工節落地到 docs/reviews 之後就會凍結，**落地前請改掉**。
- 「乾跑發現」裡「Count reconnaissance…」那條標了（D11c、D13、D15），其實 D13、D15 原文是從「Also reserve verifier cost…」那句撞到同一個缺口（report-D13 的 D13-5、report-D15 第 6–8 行），缺口本身是真的，只是代號標得鬆。
- 「驗證器照表放行，沒寫理由也會過（D15）」：validate-coverage-ledger.cjs:559-564 的 `candidate` 分支沒有要求 `unresolved`，RECONNAISSANCE.md:150 也寫 `optional`，宣稱成立。
- 「`run-metadata.json` 沒有 schema、也沒有驗證器」：`grep -i metadata` 對 report-schema.json 與 *.cjs 都是 0 筆，成立。
- README:20「stream-json 沒有 `Base directory for this skill:` 那則訊息」：real.jsonl 有 1 筆命中，但那是 subagent Read 到 clone 根目錄 CLAUDE.md 的 tool_result 內文，不是 skill 注入的訊息，宣稱成立。
- README 裡的試跑數字都和 results.txt、jsonl 對得上：花費、wall 21.7 分、agent 7 次與分型、模型分組（我用 jq 依 parent_tool_use_id 分組重算過：主 session 與 4 個是 Opus、3 個是 Sonnet）、denials 3、unit／verdict 計數。
- 乾跑 subagent 都是 sonnet、都只讀：tasks/*.output 的 message.model 全是 claude-sonnet-5-5；tool_use 只有 Read、Grep、Bash，Bash 裡只有 ls、git、jq、cat 和 2>&1，沒有寫檔或 node。
- 「Node 是安裝腳本的必要依賴」（install-dd-pipeline.sh:320-325）、「`cp -r` 整個目錄部署」（install_builtin_skills）、A10 的前例（writing-great-skills 有 dmi、沒進指令一覽）、三處授權清單與數字同步、CHANGELOG 只動 `## 未發布`：都成立。
- fc2ccb0 對 S1-b.md、S1-judge.md 的改動都在「處置」節，沒碰「發現」節；dd-init.md:62、:72 確實有答「不要」時的截圖告知。
- 設計文件 :93、:110 還寫 `ls -l`：那是 S1-2、S1-3 當時的做法文字，A16 已經註明後來改成 `ls -ld`，不算改一半。
- S2 的 commits 欄 `6f2118a..` 跟 `.git/dd-segment-base` 一致。範圍裡包含 S1 的 fc2ccb0，但「接手」規則比對的是 `（S2-`，不會誤算。
- check.sh 的 denial 欄位是先截 140 字再用 sed 把路徑換成 `$S`。這是步驟 3 之前就有的寫法，換一個更長的 scratchpad 路徑可能漏出半截本機路徑，但目錄 CLAUDE.md 規定的去識別 grep 擋得到。
- skills/security-audit/CLAUDE.md:82 的「US$15」：`$<數字>` 規則只管 SKILL.md 與 commands，這份檔不適用。

## What I ran

- Read <S>/s2-review/prompt-common.txt；diff.txt 第 1–925 行分三段讀完
- `git log --oneline -12`、`git status --short`
- `diff <S>/vendor/…/SKILL.md skills/security-audit/SKILL.md` → `2a3`、`5a7,8`；`diff -rq` → 只多 CLAUDE.md、LICENSE.txt；上游 HEAD c1c8a8c1471…
- 讀設計文件第 1–75 行、第 150–228 行；SKILL.md 第 13–138 行與第 171–183 行；RECONNAISSANCE.md:57、:143-150；validate-coverage-ledger.cjs:555-565
- 讀 <S>/dry/report-D*.txt 的【結論】與 D10、D12、D2、D8、D4、D14a 的逐條；prompt-D11c、report-D11c 全文；grep 各報告的 incomplete、focused recon、Phase 5，以及「乾跑發現」各條引句的出處
- jq 讀 <S>/../tasks/<id>.output：16 個乾跑 subagent 的 model 與 tool_use
- jq 讀 <S>/runs/real.jsonl、probe1.jsonl、probe.jsonl：各 agent 的模型分組、denial 原指令、modelUsage 花費、probe 的 result；grep 'Base directory for this skill'
- `git show a0aa58a:` 與 `96aaa42:` 的 docs/measurements/2026-11-14-dd-init-symlink/results.txt，grep Y、Y5、YD
- grep docs/reviews 的 S1-b.md、S1-c.md、S1-judge.md（c-9、需使用者決定、節標題）；grep commands/dd-init.md 的 `ls -ld` 與 screenshots
- `bash scripts/check-claude-md.sh --segment-base` → 6f2118ac…
- `git grep` vendored 清單（mattpocock、i-have-adhd、tech-diagram-gif）、security-auditor、security-audit 在兩份 README 的出現處
- grep install-dd-pipeline.sh 的 node 檢查與 install_builtin_skills；grep ci.yml 的 `$[0-9]`、node --test 與 step 名稱；grep report-schema.json 與 *.cjs 的 metadata
- 印 CHANGELOG `## 未發布` 的小節標題；sed 逐行核對上面引用的行號

## 需要外部查證

- 設計文件 A6 的「有分支因此不能用 → 停下回報使用者」：D11c 判「做不完」時，主對話有沒有回報使用者？repo 裡看不出來，請主對話自己確認。
- 部署後的 `~/.claude/skills/security-audit/CLAUDE.md`，在 `/security-audit` session 讀配套檔時會不會被當成巢狀記憶載入（A21③，沒查）。會的話，「乾跑發現」裡的敘述會進到稽核 session。

## 處置

- b-1（Important）採納：同 S2-a 的 a-3。D11c 報告【結論】點名的循環依賴現在寫在分支表下那段（含「乾跑靠情境給的 60 個 unit 才算出提議數字」）；「答應就走 D11a、不設就走 D11b」刪掉，「提議了但使用者沒確認算 set 還是 unset」改記進乾跑發現（D11c-8）
- b-2（Important）採納：分支表加 D17（focused reconnaissance：每多一次重跑 gate，擋下就種 `deferred`），並照根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步補跑乾跑（sonnet，只讀，結論：做得完）；同批補了 S2-d 第 6 條找到的 D1b、D5c2、D7b、D8b。判準那段寫明清單是人照判準掃的、不保證列全，第一版漏了這五條
- b-3（Important）採納：乾跑發現補 D12-1（gate 最低額不含 hunter）、D12-4（縮範圍過不了 gate）、D10-1（scoped 與 profile 是否並存）、D15-5／D15-7（ledger 沒有放驗證結果的欄位），也補了其他報告【結論】點名、原本沒收的（D11b-5、D12-8、D14b-1／-3、D5c-4、D6-6）；開頭寫收錄原則：每份報告【結論】點名的都收，其餘只收兩條以上分支撞到的，收之前找過上游反例
- b-4（Important）採納：同 S2-a 的 a-2
- b-5（Smell）採納：`git show a0aa58a:docs/measurements/2026-11-14-dd-init-symlink/results.txt` 第 31、59 行確實有 Y；設計文件 A19 改成「Y 臂從 S1-3 就有、Y5 與 YD 臂是 S1 步驟 4 加的」
- b-6（Smell）採納：D16 (b) 改成「由 D12、D14b、D15 的乾跑走到（D13 停在 `in_progress`、D14a 停在 wave 1 之前，都沒走到）」；設計文件 S2-1 第 2 步那句（照抄來源）加了查證註記。S2-d 把同一條標 Important，採較高的級別處理（已修）
- b-7（Smell）採納：同 S2-a 的 a-3（CHANGELOG 改成逐條標記：試跑走過、乾跑、或不另跑附理由）
- b-8（Smell）採納：試跑 README 那句改成「那 1 筆 needs_validation 就是 S1 修掉的那筆（`--apply` 跟著 symlink 寫出，見設計文件進度表 S1 那列）」
- b-9（Smell）採納：同 S2-a 的 a-5
- Not reported 裡的「Count reconnaissance…」代號標得鬆：那條改寫後同時引了「Also reserve verifier cost from the profile」，D13、D15 撞到的那句在裡面了，代號維持（D11c、D13、D15）
- 需要外部查證 ①（A6：D11c 判「做不完」時有沒有回報使用者）：沒有。之前對使用者講的是「沒有一條分支走不下去」，這次在回報裡更正，並照 A6 交使用者決定（見 `S2-judge.md`）
- 需要外部查證 ②（A21③）：步驟 5 查了：jsonl 查不出來（stream-json 不記巢狀記憶，skill 目錄放在專案裡的對照臂也是 0），改成另開 inj、injctrl 兩臂叫 session 照貼 context 裡的 CLAUDE.md —— 部署版沒載入、對照臂有載入（n=1、靠模型自述；`docs/measurements/2026-11-14-security-audit-trigger/`）
