# S2-c（審查者 C：repo 裡沒被改到卻該跟著改的地方）— 三條教訓搬回全域模板（`2172879..`）

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），三個在同一則訊息平行派出（2026-11-20）。步驟 3（code-simplifier）沒有跑，理由在審查材料第 2 部分。
Agent 呼叫的 prompt 如下（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是審查者 S2-c。先用 Read 讀完這份派工，照它做：
> <scratchpad>/s2/prompt-common.md
>
> 你的重點檔（第 3 部分整檔讀完）：README.md、README.zh-TW.md、DD_PIPELINE_ARCHITECTURE.md 裡講 dd-loop、全域模板、8 步迴圈的段落。
> 重點問題：repo 裡沒被改到的地方有沒有該跟著改而沒改的 —— 各層 `CLAUDE.md`（根目錄、`scripts/`、`tests/`、`docs/measurements/`、`docs/reviews/`、`skills/*/CLAUDE.md`）、`UPGRADING.md`、`docs/designs/`、`commands/`、`agents/`、`install-dd-pipeline.sh` 的輸出字串、`tests/`、`.github/workflows/ci.yml`；根目錄 `CLAUDE.md` 規定「動到 §3.9 文案或 dd-loop 時要巡」的那些區塊逐項對；兩份 README 的同一段有沒有講得不一樣。整段 diff（第 1 部分）一樣全部讀完，其他檔有發現照報。

它指到的共用派工 `prompt-common.md`（三個審查者讀的是同一份；同樣只換絕對路徑）：

> # 審查派工（8 步開發迴圈步驟 4，claude-dd 段落 S2）
>
> 你是程式碼審查者。唯一的職責：找漏洞。每一條發現都要附證據（審查材料的行號與原文），沒證據的不算。
> 不寫優點、不寫總評。全程唯讀：不改檔、不 commit、不跑測試、不派別的 agent。
>
> ## 範圍
> repo：<repo>（它的上一層不是 git repo；git 指令用 `git -C <repo>`）
> 要審的是 `git diff 2172879 HEAD`（HEAD = `1e23d3e`；工作目錄沒有未 commit 的改動，沒有未追蹤的新檔）。共 9 個檔、1 個 commit。
> 步驟 3（code-simplifier）沒有跑，理由在審查材料第 2 部分。
>
> ## 審查材料（只有這一個檔）
> <scratchpad>/s2/diff-pack.md
> 共 2553 行，最後一行是 `<<<審查材料結束>>>`。四個部分：
> - 第 1 部分（第 2 行起）：整段 diff
> - 第 2 部分（第 185 行起）：步驟 3 改了什麼（沒有跑）
> - 第 3 部分（第 187 行起）：被改到的 9 個檔的整檔內容（HEAD 版），每個檔夾在 `<<<FILE 路徑>>>` 與 `<<<END 路徑>>>` 之間；`CHANGELOG.md` 只放「## 未發布」一節。各檔的起始行：
>   188 CHANGELOG.md｜270 DD_PIPELINE_ARCHITECTURE.md｜473 README.md｜795 README.zh-TW.md｜1132 docs/measurements/2026-11-20-domain-traps-pointer.md｜1209 docs/reviews/2026-11-19-prompt-audit/S1-c.md｜1419 docs/reviews/2026-11-19-prompt-audit/S1-d.md｜1629 skills/dd-loop/SKILL.md｜1787 templates/global/CLAUDE.md
> - 第 4 部分（第 2542 行起）：步驟 1 已經跑過的驗證與預期值。這些已確認，不要重跑（不要跑 `tests/*.sh`、不要派 agent、不要跑 `claude -p`、不要跑 `install-dd-pipeline.sh`）。「跑過」不代表結果對：驗證方式本身抓不抓得到錯，也在審查範圍內。
>
> 讀法：用 Read 的 `offset`／`limit` 每次 300 行（Read 一次讀太多會靜靜截斷、不報錯）。
> - 第 1、2、4 部分全部讀完（第 2–186 行、第 2542 行到最後一行）。
> - 第 3 部分：你的重點檔（見派工訊息）整檔讀完；其他檔在你要查證某條發現時再讀那一段。
> - 被改到的檔一律讀審查材料裡那一份，不讀工作目錄的；沒被改到的檔（例如 `commands/dd-init.md`、`install-dd-pipeline.sh`、`scripts/*.sh`、`tests/*.sh`、其他 skill、各層 `CLAUDE.md`、`docs/designs/`）照常從 repo 讀。
> - 不要讀 settings 檔、`.mcp.json`、`~/.claude.json`（可能有憑證）。
>
> ## 這段 diff 是什麼（事實，不是結論）
> - 全是給模型讀的指示文字與文件，沒有程式碼。`templates/global/CLAUDE.md` 部署後變成 `~/.claude/CLAUDE.md`，每個專案的每個 session 都載入；`skills/dd-loop/SKILL.md` 部署到 `~/.claude/skills/dd-loop/`。字句就是行為。
> - 背景：`e8bd89e`（2026-11-18）把全域模板 §3.9「規則」裡的三條教訓（race 與交易、併發的驗法、git 進行中狀態）搬到 `skills/dd-loop/SKILL.md` 的「領域陷阱」一節，模板留一句指標。`docs/designs/2026-10-30-global-claude-md-slim-design.md` 第 33 行記著使用者 2026-10-30 的決定：這幾條留在全域。使用者 2026-11-20 被問到之後選「搬回全域模板」。這一段做的就是搬回。
> - 最新的發布版是 tag `v1.6.16` = `1290eb5`；`e8bd89e` 在它之後，還沒發布。
> - `docs/reviews/CLAUDE.md` 規定審查報告的前兩節（派工、發現）寫好就凍結，第三節（處置）可以補；這段 diff 動了 `S1-c.md`、`S1-d.md`。
> - 上一段（S1）的審查報告在 `docs/reviews/2026-11-19-prompt-audit/S1-*.md`。
>
> ## 要找的（文件與指示文字的錯，比照程式碼的 bug）
> 1. 搬回的三條：文字、位置、縮排、前後條目的銜接有沒有壞；模板或 dd-loop 裡有沒有句子還指向已經拿掉的那一節，或者指向「全域 §3.9 的某一條」而那一條現在的位置、名字不同了。
> 2. repo 裡其他沒被改到的檔，有沒有還在講「領域陷阱」一節、或預設這三條在 dd-loop／不在全域模板的句子（自己 grep，附指令與輸出）。反過來：有沒有句子預設這三條不在模板（例如行數、bytes、條數的宣稱）。
> 3. 文件裡的事實宣稱與實際不符：指到的檔、節名、commit、tag、數量、日期、引用的別處原文。用 grep／git 查得到的就查，附指令與輸出。
> 4. 改動紀錄與實際不符：`CHANGELOG.md`「## 未發布」說了什麼，diff 與 git 歷史真的是那樣嗎；有沒有改了卻沒記的；改寫那一項時有沒有掉了原本記著的事。
> 5. 互相矛盾：同一個檔內、或跨檔（全域模板對 dd-loop、對 `commands/dd-init.md` 的蓋章區塊、對兩份 README 與 `DD_PIPELINE_ARCHITECTURE.md`、對各層 `CLAUDE.md`）。
> 6. 第 4 部分的驗證：哪些宣稱其實沒被它證明；驗證的指令在該抓的錯發生時會不會變紅。
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

審查者交回的報告，逐字（只把絕對路徑換成 `<scratchpad>`、`<repo>`）。行號是審查材料 `diff-pack.md` 的行號，凍結在 `1e23d3e`。

Critical 0 / Important 0 / Smells 2：審的是 claude-dd `git diff 2172879 HEAD`（HEAD = 1e23d3e），重點檔是兩份 README、`DD_PIPELINE_ARCHITECTURE.md`，加上 repo 裡這段 diff 沒動到的檔。

【我讀了什麼】
- 審查材料 `<scratchpad>/s2/diff-pack.md`：第 1–190 行（派工所說的第 1、2 部分全部、CHANGELOG 開頭）、第 188–272 行（CHANGELOG「## 未發布」整節）、第 2540–2553 行（第 4 部分）。
- 兩份 README 與 ARCH 在第 3 部分的整檔內容我沒有逐行讀完。改成從 repo（HEAD，工作目錄是乾淨的）用 grep 把講 §3.9、dd-loop、教訓、全域模板的段落抽出來讀：README.md 第 20–32 行、第 110–128 行、第 215 行；README.zh-TW.md 第 21–32 行、第 108–130 行、第 226 行；DD_PIPELINE_ARCHITECTURE.md 第 100–140 行、第 160–185 行。
- 另外從 repo 讀的：根目錄 `CLAUDE.md` 第 150–170、240–275、310–325 行；`docs/reviews/CLAUDE.md` 第 1–55 行；`docs/reviews/2026-11-19-prompt-audit/S1-judge.md` 的處置節（第 59–70、125–137 行）；`S1-d.md` 第 180–208 行；`skills/dd-loop/SKILL.md` 用 grep 抽了幾段。

【What I ran】（都在 <repo>）
- `git log --oneline 1290eb5..HEAD` → 共 21 個 commit，e8bd89e 到 1e23d3e
- `git show --stat e8bd89e` → 只動了 `skills/dd-loop/SKILL.md`、`templates/global/CLAUDE.md`，所以搬走時沒有連帶改別的檔、要跟著回復
- `git log -S'領域陷阱' 1290eb5..HEAD`、`git log -S'domain pitfalls'` → e8bd89e、acb6d8b、1e23d3e
- `git show acb6d8b -- README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md …` → acb6d8b 在**兩份** README 加了「領域陷阱」那句，也在 ARCH 加了
- `git grep -n '領域陷阱\|domain pitfall\|pitfalls' -- ':!docs/reviews' ':!docs/measurements'` → 只剩 CHANGELOG.md 第 59、81 行
- `git grep -n 'advisory\|FOR UPDATE\|rebase-merge\|進行中狀態\|detached' -- ':!docs/reviews' ':!docs/measurements' ':!CHANGELOG.md'` → 只有模板第 272、274、295、297 行，和 `docs/designs/2026-10-30-…slim-design.md:33`（使用者決定那一行，與搬回一致）
- `grep -n '領域\|搬來\|那一節\|race\|併發\|進行中'`，範圍是 dd-loop、模板、`commands/dd-init.md`、`skills/*/CLAUDE.md`、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、`docs/measurements/CLAUDE.md`、`docs/reviews/CLAUDE.md`、根目錄 `CLAUDE.md`、`UPGRADING.md`、`agents/*.md` → 沒有指向已拿掉那一節的句子。命中的都是別的意思：dd-init 第 117 行講 `--plan` 的另一節；code-reviewer 的 "race conditions" 是通用的 bug 類別
- `grep -n '§3\.9\|下方\|下面' skills/dd-loop/SKILL.md` → 沒有句子指向已拿掉的那一節
- `git diff 1290eb5 HEAD --stat -- skills/dd-loop/SKILL.md` → 2 行加、2 行減（只有 ⚠️⚠️→⚠️）；新舊兩版都是 156 行，檔尾都以 `\n` 結束
- `git show 1290eb5:skills/dd-loop/SKILL.md | grep -c '⚠️⚠️'` → 2。這兩處在第 56、87 行，不在那一節裡，所以 CHANGELOG「dd-loop 的 ⚠️⚠️ 收成 ⚠️（6758536）」那一條還成立
- `git diff 1290eb5 HEAD -- templates/global/CLAUDE.md | grep '^@@'` → 有一個 `@@ -611,7 +611,9 @@` hunk（§6.2）
- `git log 1290eb5..HEAD -- templates/global/CLAUDE.md` → 動過模板的有 e8bd89e、c9b5190、d2f2aad、51f736a、acb6d8b、1e23d3e
- `git log -S'只留步驟清單與關卡' -- README.zh-TW.md`、`git log -S'只留 8 步清單、不能跳的關卡與驗證教訓' -- CLAUDE.md` → 兩句都在 d3b980d（2026-10-30）
- `grep -n '^## ' S1-c.md S1-d.md S1-judge.md` → 這次改的那幾行都在「## 處置」節之內（S1-c 第 184 行起、S1-d 第 183 行起）

【Critical】
（無）

【Important】
（無）

【Smells】
- S2-c-s1｜CHANGELOG.md（審查材料第 253 行；diff 第 25 行）｜原文：「這三條的文字與 v1.6.16 只差 `⚠️⚠️` → `⚠️`；模板其他地方的差異見本節 `e8bd89e`、`c9b5190`、`d2f2aad` 的條目。」
  - 錯在哪：模板從 v1.6.16 到 HEAD 還有 `51f736a` 的 §6.2 改動（`git diff 1290eb5 HEAD` 裡的 `@@ -611,7 +611,9 @@`），這句列的三個 hash 沒有包含它。§6.2 那條在同一節裡另有條目（第 242 行），但那條沒寫 hash。
  - 失敗情境：有人拿 v1.6.16 模板對 HEAD 做 diff，照這句去找條目，會以為差異只有三個 commit；§6.2 那一塊要另外找。補 `51f736a`（或改成「見本節各條」）就好。
- S2-c-s2｜CHANGELOG.md（審查材料第 229 行對第 251 行）｜原文：第 229 行「`DD_PIPELINE_ARCHITECTURE.md` 的 dd-loop 那句補上『領域陷阱』一節（那一節搬回全域模板後已拿掉…）」；第 251 行「兩份 README 與 `DD_PIPELINE_ARCHITECTURE.md` 提到那一節的句子都拿掉」。
  - 錯在哪：acb6d8b 其實在**兩份 README** 和 ARCH 都加了那一句（`git show acb6d8b -- README.md README.zh-TW.md`），但第 229 行只記了 ARCH。這段 diff 改寫了第 229 行，卻沒補上 README；結果第 251 行記了「拿掉兩份 README 的句子」，而「加上」那一步在 CHANGELOG 沒有記載。
  - 失敗情境：讀者只看 CHANGELOG，找不到 README 曾經加過這句。發布時兩份 README 對 v1.6.16 的淨差異是 0，所以不會誤導使用者，只是 CHANGELOG 前後對不上。S1-c.md 處置節 S1-c-1 那一列同樣只寫了 `README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md`，漏了 `README.md`。

【既有問題】
- 兩份 README 和根目錄 `CLAUDE.md` 對「§3.9 留下什麼」的說法不一樣。
  - README.zh-TW.md 第 128 行寫「全域 §3.9 只留步驟清單與關卡，並明寫呼叫這個 skill」；README.md 是 "global §3.9 keeps the step list and its gates, and calls this skill"。
  - 根目錄 `CLAUDE.md` 第 159 行寫「全域模板 §3.9 只留 8 步清單、不能跳的關卡與驗證教訓」。
  - 搬回之後，§3.9 的「規則」裡確實有驗證教訓（三條加上本來就在的鑑別力、0 紅等）。所以 README 的「只留步驟清單與關卡」漏了教訓，和根目錄 CLAUDE.md 互相矛盾。
  - 判定為既有的依據：兩句都是 d3b980d（2026-10-30）寫的，不在這段 diff 的 `+` 行裡，e8bd89e 也沒碰。不過它屬於根目錄 CLAUDE.md「觸發時機」要巡的「核心工作法的迴圈說明段」，這一段動到 §3.9 文案，照規定要巡到它。

【Not reported】
- S1-c.md 處置節 S1-c-2 那一列：「現況是留在 dd-loop」「CHANGELOG 的那一條寫明『留在哪一邊還沒問使用者』」已經不是現況，CHANGELOG 也沒有那句了。不報，因為同一列句尾補了「後續：…使用者選搬回…CHANGELOG 那一條跟著改寫」，讀到列尾就會更正；`docs/reviews/CLAUDE.md` 也允許補寫處置節。
- 量測紀錄開頭指向 `S2-…md`，這個檔在 HEAD 還不存在。不報：S1-judge.md 第 133 行已經定好報告放那裡，步驟 6 才會落地，屬於預定的前向指標。
- 部署順序的風險：如果某台機器的 `~/.claude/CLAUDE.md` 是 e8bd89e 之後的版本（帶指標），安裝時又選預設 `k)` 保留本地，而 dd-loop 被覆蓋了，那句指標就指向不存在的一節。不報：e8bd89e 還沒發布，v1.6.16 的使用者本機是教訓本身、沒有指標，受影響的只有作者自己的機器；第 4 部分寫了步驟 5 會用 `--force` 部署並 diff。
- 三條的文字、位置、縮排與前後條目的銜接：第 4 部分的 A、B（整塊與 v1.6.16 逐字 diff）已經證明，我目讀 diff 第 151–184 行也沒看到問題。
- 第 4 部分的驗證本身：C 和 H 的 grep 樣式蓋到中英文的關鍵字（含 pitfall、concurren、in-progress），B 比對整塊「規則:」到「### 3.10」，連位置都證明了。我沒找到該紅卻不會紅的情況；沒驗到的部署版，第 4 部分自己已經列為未做。
- `commands/dd-init.md` 蓋章區塊、`install-dd-pipeline.sh` 輸出字串、`tests/`、`.github/workflows/ci.yml`、`UPGRADING.md`、`agents/`、各層 `CLAUDE.md`：grep 都沒有和這三條或「領域陷阱」相關的句子；e8bd89e 也沒動過它們。也沒找到哪裡預設這三條不在模板（例如行數或 bytes 上限）：gate 的大小上限只管根目錄 CLAUDE.md。
- 兩份 README 的 dd-loop 那一列：兩邊內容一致，也與 c74f115 版逐行相同（第 4 部分 G）。

【需要外部查證】
- 部署後 `~/.claude/CLAUDE.md` 是不是真的有這三條、`~/.claude/skills/dd-loop/SKILL.md` 是不是已經沒有那一節：要跑 `install-dd-pipeline.sh --force` 之後再 `diff`（步驟 5 已排）。我這個 session 載入的全域檔還是帶指標的那一版，可見目前還沒部署。

## 處置

修正與這份報告在同一個 commit（步驟 6）。編號照「發現」節。

| 發現 | 級別 | 處置 |
|---|---|---|
| S2-c-s1 CHANGELOG 列模板其他差異時漏了 `51f736a` | Smell | 採納，已修（與 S2-b-s1 同一件，查證見 `S2-b.md`）。 |
| S2-c-s2 CHANGELOG 記了「拿掉兩份 README 的句子」，卻沒記 `acb6d8b` 在兩份 README 加過 | Smell | 採納，已修。查證：`git show acb6d8b --stat -- README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md` 三個檔各改一行。CHANGELOG 那一句改成「`DD_PIPELINE_ARCHITECTURE.md` 與兩份 README 的 dd-loop 那句補上…」；`S1-c.md` 處置的 S1-c-1、S1-c-s5 兩列補上 `README.md`。 |

既有問題一項（兩份 README 寫「全域 §3.9 只留步驟清單與關卡」，根目錄 `CLAUDE.md` 寫的是「8 步清單、不能跳的關卡與驗證教訓」）：屬實，已修。那兩句是 2026-10-30 寫的，當時 §3.9 就有驗證教訓，所以從那時起就漏了；它在根目錄 `CLAUDE.md`「觸發時機」要巡的「核心工作法的迴圈說明段」裡，這一段動到 §3.9 文案，照規定該巡到。兩份 README 各補上「與驗證教訓」／"and the verification lessons"。步驟 1 的巡查只 grep 了三條的關鍵字，沒有讀那一段的句子，所以沒抓到。

Not reported 裡「部署順序的風險」（本機全域檔帶指標、安裝時選保留本地、dd-loop 卻被覆蓋）：屬實，沒處理。`e8bd89e` 沒有發布過，帶指標的全域檔只存在這一台機器，步驟 5 已用 `--force` 部署並核對。

需要外部查證（部署後全域檔有沒有這三條、dd-loop 還有沒有那一節）：步驟 5 查了，見 `S2-judge.md`。
