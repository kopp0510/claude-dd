# S1-c（審查者 C：全域模板、dd-loop、dd-init 與 agent 定義）— 2026-11 提示文字稽核的改動（`2636b36..`）

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-20），在步驟 3（code-simplifier）跑完、沒有改任何檔之後。
Agent 呼叫的 prompt 如下（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是審查者 S1-c。先用 Read 讀完這份派工，照它做：
> <scratchpad>/s4/prompt-common.md
>
> 你的重點檔（第 3 部分整檔讀完）：templates/global/CLAUDE.md、skills/dd-loop/SKILL.md、commands/dd-init.md、agents/code-reviewer.md、agents/security-auditor.md、agents/senior-devops.md、skills/code-simplifier/SKILL.md、skills/frontend-design/SKILL.md。
> 重點問題：①全域模板被刪掉或搬走的每一段（diff 的 `-` 行），條件、例外、出處有沒有在別處留著（搬到 dd-loop 的「領域陷阱」逐條對）；模板裡還有沒有句子指向已經搬走或改名的東西。②模板 §3.9、§7 與 dd-loop、dd-init 之間講同一件事的地方有沒有不一致；dd-init 蓋到專案的內容與模板對得上嗎。③agent 與 skill 的 frontmatter／description 改動後，觸發條件與全域 §7.2 的表對得上嗎；工具名（Agent、Skill、TaskCreate 等）寫的是存在的工具嗎（只憑檔內與 repo 內的證據判斷，查不了的列外部查證）。④§6.2 的新文字與 docs/measurements/2026-11-19-global-6.2-retry.md 記的被測文字一樣嗎。整段 diff（第 1 部分）一樣全部讀完，其他檔有發現照報。

它指到的共用派工 `prompt-common.md`（四個審查者讀的是同一份；同樣只換絕對路徑）：

> # 審查派工（8 步開發迴圈步驟 4，claude-dd）
>
> 你是程式碼審查者。唯一的職責：找漏洞。每一條發現都要附證據（審查材料的行號與原文），沒證據的不算。
> 不寫優點、不寫總評。全程唯讀：不改檔、不 commit、不跑測試、不派別的 agent。
>
> ## 範圍
> repo：<repo>（它的上一層不是 git repo；git 指令用 `git -C <repo>`）
> 要審的是 `git diff 2636b36`（到工作目錄；工作目錄 = HEAD `ecfc89c`，沒有未 commit 的改動，沒有未追蹤的新檔）。共 31 個檔、17 個 commit。
> 步驟 3（code-simplifier）跑過了，沒有改任何檔。
>
> ## 審查材料（只有這一個檔）
> <scratchpad>/s4/diff-pack.md
> 共 7375 行，最後一行是 `<<<審查材料結束>>>`。四個部分：
> - 第 1 部分（第 3 行起）：整段 diff
> - 第 2 部分（第 1692 行起）：步驟 3 改了什麼（沒有）
> - 第 3 部分（第 1696 行起）：被改到的 31 個檔的整檔內容，每個檔夾在 `<<<FILE 路徑>>>` 與 `<<<END 路徑>>>` 之間；`CHANGELOG.md` 只放「## 未發布」一節。各檔的起始行：
>   1699 CHANGELOG.md｜1744 CLAUDE.md｜2128 agents/code-reviewer.md｜2250 agents/security-auditor.md｜2380 agents/senior-devops.md｜2482 commands/dd-init.md｜2885 docs/measurements/2026-11-19-global-6.2-retry.md｜2977 docs/measurements/CLAUDE.md｜3064 scripts/CLAUDE.md｜3398 scripts/githooks/CLAUDE.md｜3552 skills/code-simplifier/SKILL.md｜3613 skills/dd-loop/SKILL.md｜3793 skills/frontend-design/SKILL.md｜3852 skills/self-improving-agent/CLAUDE.md｜4033 skills/self-improving-agent/README.md｜4114 skills/self-improving-agent/SKILL.md｜4264 skills/self-improving-agent/agents/memory-analyst.md｜4353 skills/self-improving-agent/agents/skill-extractor.md｜4471 skills/self-improving-agent/reference/memory-architecture.md｜4611 skills/self-improving-agent/reference/promotion-rules.md｜4710 skills/self-improving-agent/skills/extract/SKILL.md｜4908 skills/self-improving-agent/skills/promote/SKILL.md｜5094 skills/self-improving-agent/skills/remember/SKILL.md｜5220 skills/self-improving-agent/skills/review/SKILL.md｜5373 skills/self-improving-agent/skills/status/SKILL.md｜5545 skills/tech-diagram-gif/SKILL.md｜5772 skills/tech-diagram-gif/references/composition-quality-contract.md｜5923 skills/tech-diagram-gif/references/icons.md｜6335 skills/tech-diagram-gif/references/style-2-dark-terminal.md｜6446 templates/global/CLAUDE.md｜7184 tests/CLAUDE.md
> - 第 4 部分（第 7323 行起）：步驟 1 已經跑過的驗證與預期值。這些已確認，不要重跑（不要跑 `tests/test-install.sh`、不要派 agent 乾跑 skill、不要跑 `claude -p`）。「跑過」不代表結果對：驗證方式本身抓不抓得到錯，也在審查範圍內。
>
> 讀法：用 Read 的 `offset`／`limit` 每次 300 行（Read 一次讀太多會靜靜截斷、不報錯）。
> - 第 1、2、4 部分全部讀完（第 3–1695 行、第 7323 行到最後一行）。
> - 第 3 部分：你的重點檔（見派工訊息）整檔讀完；其他檔在你要查證某條發現時再讀那一段。
> - 被改到的檔一律讀審查材料裡那一份，不讀工作目錄的；沒被改到的檔（例如 `install-dd-pipeline.sh`、`scripts/*.sh`、`tests/*.sh`、其他 skill）照常從 repo 讀。
> - 不要讀 settings 檔、`.mcp.json`、`~/.claude.json`（可能有憑證）。
>
> ## 這段 diff 是什麼（事實，不是結論）
> - 幾乎全是給模型讀的指示文字與文件：skill（`skills/**/SKILL.md`）、agent 定義（`agents/*.md`）、指令（`commands/dd-init.md`）、各層 `CLAUDE.md`、`CHANGELOG.md`、全域模板 `templates/global/CLAUDE.md`（部署後變成 `~/.claude/CLAUDE.md`，每個專案都載入），加上 skill 檔裡的幾段 shell。字句就是行為。
> - 來源是 2026-11 對提示文字做的三輪稽核（目標模型 Claude Fable 5.2）：收斂強調記號、更正過期或互相矛盾的句子、把全域模板的「領域陷阱」搬到 `skills/dd-loop/SKILL.md`、改全域 §6.2「不做：自動重試」的寫法、修 `skills/self-improving-agent`。
> - `skills/self-improving-agent` 是收編的第三方 skill；本地改動逐條記在 `skills/self-improving-agent/CLAUDE.md` 的「Differences from upstream」。repo 根 `CLAUDE.md` 規定：改過的 skill 部署前要由 subagent 乾跑；說上游「沒寫」某件事之前要對過該 skill 目錄的每個 `.md`。
> - 全域 §6.2 的新舊寫法做過行為量測，紀錄在 `docs/measurements/2026-11-19-global-6.2-retry.md`。
> - 這段範圍裡先前的 16 個 commit（`c0f6d33` 到 `3ed8a01`）當時都沒有走過審查，這次是第一次審。
>
> ## 要找的（文件與指示文字的錯，比照程式碼的 bug）
> 1. 照字面做會做錯、做不出來，或兩種讀法會得出不同結果的句子（寫出兩種讀法各會怎樣）。
> 2. 互相矛盾：同一個檔內、或跨檔（例如 `review/SKILL.md` 對 `agents/memory-analyst.md`、`status/SKILL.md` 對 `review/SKILL.md`、全域模板對 `skills/dd-loop/SKILL.md`、`commands/dd-init.md` 對全域模板）。
> 3. 文件裡的事實宣稱與實際不符：指到的檔、節名、函式、指令、commit、數量、日期、引用的別處原文。用 grep／git 查得到的就查，附指令與輸出。
> 4. 改動紀錄與實際不符：`CHANGELOG.md`「## 未發布」與 `skills/self-improving-agent/CLAUDE.md`「Differences from upstream」說改了什麼，diff 裡真的是那樣嗎；有沒有改了卻沒記的。
> 5. 搬移或縮短時掉了條件、例外、日期、出處、路徑（把 diff 的 `-` 行與 `+` 行並排對條件與指向）。
> 6. skill 檔裡的 shell：在 macOS（zsh、BSD 工具）與 Linux 上照貼會不會壞、會不會靜靜給出錯的結果（可以自己在暫存目錄跑唯讀的小實驗，附輸出）。
> 7. 第 4 部分的驗證：哪些宣稱其實沒被它證明。
>
> ## 規則
> - 只用手上的資料與唯讀指令（Read、grep、git log／show／diff、ls）判斷。需要上網、需要跑測試或跑模型才知道的，寫進「需要外部查證」交回。
> - 每條發現：級別（Critical／Important／Smell）｜檔名與審查材料的行號｜原文引用｜錯在哪｜具體的失敗情境（誰照這句做、在什麼輸入下、得到什麼錯的結果）。
>   Critical = 照做會壞東西或丟資料、洩漏憑證；Important = 照做會得到錯的結果或做不出來，而且不會報錯；Smell = 其餘。
> - 既有的問題（不是這段 diff 引入的）另列一節「既有問題」，不要丟掉：寫出你為什麼判定它不是這次引入的（那幾行不在 diff 的 `+` 行裡）。
> - 真的沒找到就照實寫，不要硬湊。
> - 你所在的環境若規定用某個工具交回報告（例如 SubagentHandback），就用那個工具交完整報告。
>
> ## 交回格式（照抄這些標題）
> 【我讀了什麼】審查材料讀了哪些行範圍、另外從 repo 讀了哪些檔
> 【What I ran】指令與關鍵輸出
> 【Critical】
> 【Important】
> 【Smells】
> 【既有問題】
> 【Not reported】看過、判定不算的（每條一句理由）
> 【需要外部查證】

## 發現

審查者交回的報告，逐字（只把絕對路徑換成 `<scratchpad>`、`<repo>`）。行號是審查材料 `diff-pack.md` 的行號，凍結在 `ecfc89c`。

【我讀了什麼】
- 審查材料 <scratchpad>/s4/diff-pack.md：第 1 部分 1–1695 全讀；第 2 部分 1692–1695；第 4 部分 7323–7376。
- 第 3 部分的重點檔全讀：commands/dd-init.md 2482–2883、skills/dd-loop/SKILL.md 3613–3791、skills/code-simplifier/SKILL.md 3552–3611、skills/frontend-design/SKILL.md 3793–3850、agents/code-reviewer.md、security-auditor.md、senior-devops.md 2128–2480。
- templates/global/CLAUDE.md 讀的是材料 6446–6745。後半段我用 diff 確認過：材料裡模板第 1–734 行與部署的 ~/.claude/CLAUDE.md 逐字相同（我那份已經整份讀過），所以沒有逐行重讀。
- 另外從 repo 讀：install-dd-pipeline.sh 50–75、1455–1465；scripts/dd-stop.sh 100–110；docs/designs/2026-10-30-global-claude-md-slim-design.md 25–40；CLAUDE.md 130–145、275–294。

【What I ran】
- `git log --oneline 2636b36..HEAD` → 17 個 commit，c0f6d33 到 ecfc89c。
- `git tag --contains 2636b36` → 只有 v1.6.16，2636b36 本身就是 v1.6.16。所以這 17 個 commit 都該記在「## 未發布」。
- `git diff 8dcaa73^ 8dcaa73 -- templates/global/CLAUDE.md` → 只有 §6.2 一行換成三行。8dcaa73 的模板 blob 是 45b85ce，與 HEAD 相同（材料第 1442 行 `index 5672e6d..45b85ce`）。
- `git diff 8dcaa73 HEAD -- templates/global/CLAUDE.md` 再 grep §6.2 → 沒有輸出，8dcaa73 之後 §6.2 沒再改過。
- 把模板 diff 的 `-` 行（材料 1467–1479、1490–1494，去掉 `-`、把 ⚠️⚠️ 換成 ⚠️）和 dd-loop 3773–3790 做 diff → 一字不差。
- 在 repo 裡 git grep 以下字串，沒有過期的引用：`read-then-write|advisory lock|rebase-merge|隔離級別|領域陷阱`、`under-trigger|任何 \`.md\` 檔|優化 skill`、`2026-07 重整`、`⚠️⚠️`（模板、dd-loop、dd-init 都是 0）。
- `git grep 本地備份|官方 code-reviewer` → install-dd-pipeline.sh:59 還寫「2 個官方 agent 本地備份」，CLAUDE.md:34、94 與 README.zh-TW.md:56 也這樣寫，詳見 Not reported。
- `git grep 'Task tool'` → install-dd-pipeline.sh:1461 還印「供 wrapper skills 透過 Task tool 調用」。
- `git grep '^allowed-tools:'` → 用到 Agent 的 skill（code-simplifier、design-brainstorm、plan-review、task-planner）都寫 `Agent`，前後一致。
- `git show -s a372fe3` → 這是 claude-dd 自己的 commit（2026-06-23「frontend-design 更新至上游最新版」）。`git diff a372fe3 febdc45^ -- skills/frontend-design/SKILL.md` → 期間只改過 description，內文沒動。
- `git grep '§3\.9'`：CLAUDE.md:157–160 寫了理由——放在 §3.9 裡的東西，沒跑迴圈的專案會跳過；dd-stop.sh:107 規定暫停期間「不呼叫 `dd-loop`」。

【Critical】
（無）

【Important】
1. Important｜templates/global/CLAUDE.md 材料 1481（HEAD 模板第 269 行）＋ skills/dd-loop/SKILL.md 材料 3616、3771
   原文：
   - 模板：「- 併發 race、資料庫鎖、git 進行中狀態的驗法見 `dd-loop` skill 的「領域陷阱」一節(碰到這類修改時讀)」
   - dd-loop 的 description：「…不適用於迴圈外的單次修改或純問答。」
   錯在哪：
   - 這三條原本在全域模板裡，每個 session 都會載入。搬到 dd-loop 之後，只有呼叫 dd-loop 才拿得到；而 dd-loop 自己的 description 排除迴圈外的修改，模板又沒寫怎麼「讀」（叫 Skill 還是 Read 檔）。
   - scripts/dd-stop.sh:107 的暫停聲明明寫「不跑步驟 3–8，不呼叫 `dd-loop`」，卻同時要求「測試要跑綠」照舊做。
   - 指標句把內容縮成「驗法」，但搬走的第一條其實講的是修法（「包進交易通常是錯的修法」、改用 advisory lock）。這正是模板 §3.10「縮短既有文字時條件最容易被改掉」那一類錯。
   失敗情境：
   - 情境一：在 `/dd-stop on` 的專案裡修一個 read-then-write race。照暫停聲明不呼叫 dd-loop，所以讀不到「Postgres read committed 下包交易擋不住」，於是寫出包進交易就收工的修法。這不會報錯，要等併發時才出事。
   - 情境二：迴圈外的單次 hotfix。模型照 dd-loop 的 description 判斷不適用，結果一樣。
   - 情境三：模型讀了指標句，判斷自己在「修」而不是「驗」，於是不去讀。
   佐證：repo CLAUDE.md:159–160 自己記過這個理由：「§3.9 的前言是…放在裡面的話，沒跑迴圈的專案會連這些判準一起跳過」。搬到更窄的 dd-loop，跳過的範圍更大。

2. Important（建議標「需使用者決定」）｜commit c0f6d33；docs/designs/2026-10-30-global-claude-md-slim-design.md:33
   原文：「使用者決定：§3.9「規則」裡 8 條驗證教訓（race 與交易、併發驗法、擋誤用機制三件事、git 進行中狀態、鑑別力測試、0 紅先疑實驗、識別符 git grep、清點分母）**留在全域**」
   錯在哪：c0f6d33 把其中三條（race 與交易、併發驗法、git 進行中狀態）搬出全域。commit 訊息只寫「依 prompt-audit」，沒有新的使用者決定；設計文件也沒更新，仍寫這 8 條留在全域。
   失敗情境：這等於用 audit 的建議推翻有紀錄的使用者決定。之後的人讀設計文件，會以為 8 條都還在全域；或者拿這次的搬移當前例，繼續搬剩下的 5 條。

3. Important｜CHANGELOG.md「## 未發布」（材料 13–53）
   錯在哪：這是部署到每個專案的全域模板與 agent。下面這些會改變行為的改動，都沒有記：
   - §7.2：claude-md-improver 從「+ 任何 `.md` 檔」縮成「+ `CLAUDE.md`」（材料 1650–1651）；「優化 skill」不再導到 self-improving-agent（1655–1656）
   - §7.6 改寫：拿掉「under-trigger 比 over-trigger 嚴重」（1664–1667）
   - §7.1 第 5 步（1642–1643）
   - 領域陷阱搬到 dd-loop（1467–1494）
   - §6.7 新增 docker 例外（1633–1634）
   - security-auditor 改成 OWASP 2025 並重新編號（103–138）：A02/A03 換成 A04/A05，A10 從 SSRF 換成 Mishandling of Exceptional Conditions
   - senior-devops 的 IaC state 寫法（150–151）
   - code-reviewer 的 description 拿掉「本地備份」（90–91）
   - tech-diagram-gif 從「產出後刪 SVG」改成「一開始就寫暫存目錄、要刪檔先問」（1344–1349）
   已記的只有 §6.2、self-improving-agent、frontend-design、githooks，以及 Task→Agent 的一部分。
   失敗情境：
   - 使用者升級後照 CHANGELOG 判斷變了什麼，不會知道說「修 README.md」已經不再觸發 claude-md-improver。
   - 拿新舊兩版 security-auditor 的報告比對，同一個 A03 指的是不同類別（Injection 對 Supply Chain），差異無聲。
   註：repo CLAUDE.md 沒有「每次改模板都要記 CHANGELOG」的明文（只有新增 output style、跳 rev 等情境要求），所以這條是派工第 4 項「改了卻沒記」，不是違規。

【Smells】
1. Smell｜CHANGELOG.md 材料 53，以及 docs/measurements/2026-11-19-global-6.2-retry.md 材料 234
   原文：「建訂單連線中斷時兩邊都先查過才重送」
   錯在哪：同一份量測材料 270 寫「S4 兩臂有效的只有 B 的 1 發，所以 S4 只能當跡象」。結論句和 CHANGELOG 都拿掉了這個但書，一次跡象讀起來像是兩臂都量到的結果，也就是 §3.10 ② 那一類。
   另一處：結論句「舊寫法 10 發都先查原因」也算進了照判定式無效的發次：S2 的 A 臂 5 發都有 denial，S2b 的 A 臂有 1 發 `ps` denial（材料 255、269）。
   註：第 ④ 項本身查證成立。§6.2 的新文字與量測 B 臂（8dcaa73）逐字相同，HEAD 之後沒再改。

2. Smell｜templates/global/CLAUDE.md 材料 1643
   原文：「5. 模糊 → 照 §6.1 判斷:有 ≥80% 把握就動手並寫明假設,否則用 AskUserQuestion 問」
   錯在哪：§6.1 還有「回問」的三個條件（理解錯會浪費大量時間、涉及設計取捨、慣例衝突），這裡只摘了 80% 那一條。只讀 §7.1 的人會漏掉那三個條件。

3. Smell｜skills/frontend-design/SKILL.md 材料 3798
   原文：「內文是 2026-06-23 同步的上游版(commit a372fe3)」
   錯在哪：a372fe3 是 claude-dd 自己的 commit，不是上游 commit。拿這個 hash 去上游 repo 查授權來源的人會找不到。宣稱本身成立：a372fe3 之後內文確實沒改過，只動了 description。

4. Smell｜templates/global/CLAUDE.md 材料 1617
   原文：「對方那一側的暫時性失敗(連線中斷、服務忙或被限流、檔案被別的行程鎖住)」
   錯在哪：檔案被別的行程鎖住發生在本機，不是「對方那一側」，同一句的分類自相矛盾。量測也沒有涵蓋鎖檔這一種（材料 271 的「沒量的」清單裡沒列它，S1–S4 都是 HTTP）。

5. Smell｜skills/dd-loop/SKILL.md 材料 3616、3621
   錯在哪：description 與開頭那句「這份寫各步怎麼做」都沒提到新加的「領域陷阱」一節。DD_PIPELINE_ARCHITECTURE.md:105 也還把 dd-loop 描述成「從全域 §3.9 原文搬出的迴圈做法細則」。從 skill 清單判斷要不要叫它的模型，看不出它管 race 與 git 狀態。

6. Smell｜install-dd-pipeline.sh:1461（不在 diff 裡）
   原文：`echo "   供 wrapper skills 透過 Task tool 調用"`
   錯在哪：CHANGELOG 材料 27 說這一輪把剩下的 Task 改成 Agent，安裝完成訊息這一處漏了。`git grep 'Task tool'` 不是 0，也就是 §3.10「只改一半的統一」。

【既有問題】
- commands/dd-init.md 蓋章區塊第 7、8 步（材料 2637、2640）寫「/revise-claude-md」「claude-md-improver」，沒帶 plugin 命名空間；全域模板 §3.9 寫的是 `claude-md-management:revise-claude-md` 與 `claude-md-management:claude-md-improver`。這幾行不在 diff 的 `+` 行裡，區塊這次也沒跳 rev，所以判定不是這次引入的。
- templates/global/CLAUDE.md §4.4「原生 Task 工具(`TaskCreate`…)」：這一輪把派工工具一律改叫 Agent 之後，「Task 工具」在這裡指的是待辦工具，名字容易混。不在 diff 的 `+` 行裡。

【Not reported】
- 搬走的三條陷阱有沒有掉內容：機械 diff 一字不差，只拿掉一個 ⚠️。
- 模板裡指向已搬走內容的句子：git grep 只剩那句指標，§3.5 與 §3.10 引用的「鑑別力」「第一個嫌疑人」兩條都還在 §3.9。
- dd-init 蓋章區塊對模板 §3.9：區塊沒改、不用跳 rev。這次 dd-init 改的都在區塊外（重整說明、「三個→這幾個」寫法、工具表）；Phase 5 下面實際有 4 條，原本寫「三個」本來就數錯，改成不數符合 §3.10。
- code-reviewer 的 description 拿掉「官方 plugin 未裝時的本地備份」，但 CLAUDE.md:34、94、README.zh-TW.md:56、installer:59 還寫官方備份：那些是在講檔案來源與授權，不是在講觸發條件，不算矛盾。dd-loop 一律派 `subagent_type: "code-reviewer"`，不受影響。
- §7.2 各列與 code-simplifier、frontend-design、self-improving-agent、claude-md-improver 的 description 對照：觸發條件都對得上。ci.yml 的 §7.2 反引號護欄照樣成立，每列都還有反引號。
- §7.6 或「任何 .md」的舊說法有沒有被引用：git grep 回 0。
- self-improving-agent 那一串 diff（材料 443–1335）：照派工讀完了，不是我的重點檔，沒做逐條跨檔核對，留給負責那一塊的審查者。
- 第 4 部分的驗證：只涵蓋 self-improving-agent 與 test-install.sh。模板 §7 的觸發改動、陷阱搬移後拿不拿得到，都沒有行為驗證。這是 Important 1 的佐證，不另列一條。

【需要外部查證】
- OWASP Top 10:2025 的正式編號與名稱（A01 併入 SSRF、A03 Software Supply Chain Failures、A10 Mishandling of Exceptional Conditions）：我照通用知識判定一致，要對 owasp.org/Top10 的 2025 版。
- §6.7「perl alarm 砍不掉 `docker` 指令」：只有 2026-11-15 一次、在這位使用者的機器上量到，現在寫進要公開發佈的全域模板。要在別的機器重現，確認不是 OrbStack 或某個 docker CLI 版本特有的行為。
- frontend-design 的「2026-11-19 比對時上游內文已改寫」：要對 anthropics 上游的 frontend-design 現行版。
- `allowed-tools: Agent` 是否是現行 Claude Code 認得的工具名：repo 內 4 支 skill 都這樣寫、彼此一致；我所在的環境派工工具就叫 Agent，但 repo 裡沒有官方文件可對。

## 處置

修正與這份報告在同一個 commit（步驟 6）。編號照「發現」節：Important 是 S1-c-1 到 S1-c-3，Smells 是 S1-c-s1 到 S1-c-s6。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-c-1 「領域陷阱」搬到 dd-loop 之後，迴圈外的修改拿不到 | Important | 採納，改寫了指標句，搬不搬回去交使用者決定（見 S1-c-2）。模板那句改成：碰到這類修改就用 Read 讀 `~/.claude/skills/dd-loop/SKILL.md` 的那一節，迴圈外的修改、迴圈暫停中也一樣（讀檔不算呼叫 `dd-loop`）。`README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md` 講 dd-loop 的那一句補上「領域陷阱」。改寫有沒有用另外量了，新舊各 8 發、16 發都有效：舊指標到了 4 發（3 發呼叫 Skill `dd-loop`、1 發用 Read），改寫後到了 8 發（都是用 Read）。只有一個 prompt（資料庫 race），「到了」只證明讀了那個檔。紀錄在 `docs/measurements/2026-11-20-domain-traps-pointer.md`。後續：使用者 2026-11-20 決定搬回全域模板，S2 段落做了，指標句與補在 README、ARCH 的那一句都拿掉。 |
| S1-c-2 `c0f6d33` 把三條教訓搬出全域模板，和 2026-10-30 的使用者決定相反 | Important（審查者建議標「需使用者決定」） | 需使用者決定，寫這份報告時還沒問到答案。查證：`docs/designs/2026-10-30-global-claude-md-slim-design.md` 第 33 行確實記著那三條留在全域模板；搬走是 2026-11-18 稽核的一項，使用者當時同意套用那份 diff，但那份 diff 沒有把這個衝突列出來。現況是留在 dd-loop 加上 S1-c-1 的指標。兩個選項：留在 dd-loop（那一節 18 行，全域模板只留 2 行的指標；拿不拿得到靠指標）；搬回全域模板（每個 session 都載入，不靠指標）。CHANGELOG 的那一條寫明「留在哪一邊還沒問使用者」。後續：2026-11-20 用 AskUserQuestion 問了，使用者選搬回全域模板；S2 段落搬回，CHANGELOG 那一條跟著改寫。 |
| S1-c-3 CHANGELOG「未發布」漏記 | Important | 採納，已修（與 S1-b-6、S1-d-1 同一件）。 |
| S1-c-s1 CHANGELOG 與量測紀錄的結論拿掉了「只能當跡象」，也算進了無效的發 | Smell | 採納，已修（與 S1-d-2 同一件）：結論改成只用事先寫下的判定式，「失敗後第一個動作」標成事後多看的一項，照規則無效的發數寫出來。 |
| S1-c-s2 §7.1 第 5 步只摘了 §6.1 的 80% 那一條 | Smell | 不採納。那一步寫的是「照 §6.1 判斷」，是指過去、不是取代；§6.1 每個 session 都載入，摘要漏的三個條件就在同一份檔。 |
| S1-c-s3 frontend-design 把 `a372fe3` 寫得像上游的 commit | Smell | 採納，已修：寫明是 claude-dd 自己的 commit。 |
| S1-c-s4 §6.2 把「檔案被別的行程鎖住」歸在「對方那一側」 | Smell | 屬實，沒改，轉新段落。那一句是 2026-11-19 量測的被測文字（審查者自己核過逐字相同）；改字就和量測紀錄對不上，要改得連量測一起重做。 |
| S1-c-s5 dd-loop 的 description 與開頭沒提「領域陷阱」；ARCH 的描述過期 | Smell | 部分採納：`DD_PIPELINE_ARCHITECTURE.md` 與 `README.zh-TW.md` 那一句補上了。dd-loop 自己的 description 沒改：改 description 會動到觸發，要另外做新 session 的觸發測試，而全域模板的指標句已經直接給了檔案路徑。後續：S2 搬回全域模板後，補上的那一句與指標句都拿掉。 |
| S1-c-s6 安裝完成訊息還寫「Task tool」 | Smell | 採納，已修。`git grep -n 'Task tool'` 剩下的命中：`skills/security-audit/` 的兩個檔（那個 skill 自己對「Task tool」的定義，跨平台用語，不是這一輪要統一的對象）、CHANGELOG 與 `skills/self-improving-agent/CLAUDE.md` 描述這次改名的句子。`tests/test-install.sh` 改完後重跑，exit 0。 |

既有問題兩項屬實，沒在這一段改，轉新段落：`commands/dd-init.md` 蓋章區塊第 7、8 步的 skill 名字沒帶 plugin 命名空間（改它要跳 `dd-loop-rev`）；§4.4 的「Task 工具」指待辦工具、容易和派工工具混。

Not reported 的各項看過，沒有要翻案的。其中「模板 §7 的觸發改動、陷阱搬移後拿不拿得到，都沒有行為驗證」：兩件都補量了（`docs/measurements/2026-11-20-global-7-trigger.md`、`docs/measurements/2026-11-20-domain-traps-pointer.md`）。

需要外部查證：
- OWASP Top 10:2025：2026-11-20 對 top10.owasp.org/2025 核過 A01–A10 的名稱。
- §6.7「perl alarm 砍不掉 `docker`」在別台機器會不會重現：沒查，手上只有這一台。
- frontend-design「上游內文已改寫」：這一段沒有重查；依據是 2026-11-19 稽核時的比對。
- `allowed-tools: Agent` 是不是現行工具名：沒對官方文件。步驟 5 的 dd-init 乾跑裡，subagent 的紀錄檔有一筆 `tool_use`，name 是 `Agent`、`subagent_type` 是 `Explore`，所以這個環境裡派工工具叫 Agent。
