# S2-a（審查者 A：搬回的文字、全域模板與 dd-loop）— 三條教訓搬回全域模板（`ba799a2..`）

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），三個在同一則訊息平行派出（2026-11-20）。步驟 3（code-simplifier）沒有跑，理由在審查材料第 2 部分。
Agent 呼叫的 prompt 如下（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是審查者 S2-a。先用 Read 讀完這份派工，照它做：
> <scratchpad>/s2/prompt-common.md
>
> 你的重點檔（第 3 部分整檔讀完）：templates/global/CLAUDE.md、skills/dd-loop/SKILL.md。
> 重點問題：搬回的三條與它們前後的條目，一個第一次讀的模型照字面走會不會做錯或卡住；模板與 dd-loop 之間（以及對 `commands/dd-init.md`、`agents/*.md`、其他 skill）還有沒有指向已拿掉那一節的句子，或預設這三條不在模板的句子。整段 diff（第 1 部分）一樣全部讀完，其他檔有發現照報。

它指到的共用派工 `prompt-common.md`（三個審查者讀的是同一份；同樣只換絕對路徑）：

> # 審查派工（8 步開發迴圈步驟 4，claude-dd 段落 S2）
>
> 你是程式碼審查者。唯一的職責：找漏洞。每一條發現都要附證據（審查材料的行號與原文），沒證據的不算。
> 不寫優點、不寫總評。全程唯讀：不改檔、不 commit、不跑測試、不派別的 agent。
>
> ## 範圍
> repo：<repo>（它的上一層不是 git repo；git 指令用 `git -C <repo>`）
> 要審的是 `git diff ba799a2 HEAD`（HEAD = `73cd7a5`；工作目錄沒有未 commit 的改動，沒有未追蹤的新檔）。共 9 個檔、1 個 commit。
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
> - 背景：`c0f6d33`（2026-11-18）把全域模板 §3.9「規則」裡的三條教訓（race 與交易、併發的驗法、git 進行中狀態）搬到 `skills/dd-loop/SKILL.md` 的「領域陷阱」一節，模板留一句指標。`docs/designs/2026-10-30-global-claude-md-slim-design.md` 第 33 行記著使用者 2026-10-30 的決定：這幾條留在全域。使用者 2026-11-20 被問到之後選「搬回全域模板」。這一段做的就是搬回。
> - 最新的發布版是 tag `v1.6.16` = `2636b36`；`c0f6d33` 在它之後，還沒發布。
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

審查者交回的報告，逐字（只把絕對路徑換成 `<scratchpad>`、`<repo>`）。行號是審查材料 `diff-pack.md` 的行號，凍結在 `73cd7a5`。

Critical 0 / Important 1 / Smells 0 — `git diff ba799a2 HEAD`（73cd7a5）；重點檔是 templates/global/CLAUDE.md 與 skills/dd-loop/SKILL.md

【我讀了什麼】
- 審查材料 <scratchpad>/s2/diff-pack.md：第 1–190 行（第 1、2 部分，以及 CHANGELOG 的開頭）、188–269（CHANGELOG「未發布」整節）、1629–1786（dd-loop 整檔）、1787–2541（模板整檔）、2540–2553（第 4 部分）。S1-c.md、S1-d.md 只用 awk 列出 `## ` 標題，確認改動落在哪一節。
- 從 repo 讀了：<repo>/CLAUDE.md 第 150–165 行、scripts/dd-stop.sh 第 100–112 行、docs/designs/2026-10-30-global-claude-md-slim-design.md 第 25–50 行、docs/reviews/CLAUDE.md 第 1–30 行，另外 grep 了 commands/dd-stop.md 與 commands/dd-init.md。

【What I ran】
- `git log --oneline -3` → HEAD 是 73cd7a5，前一個是 ba799a2
- `git grep -n -E 'advisory|隔離級別|pre-image|rebase-merge|read committed|迴圈暫停中也一樣|讀檔不算呼叫|dd-loop/SKILL.md 的那一節|領域陷阱|domain pitfall|race 與交易|三條教訓'`（排除 CHANGELOG、docs/reviews、那份量測紀錄）→ 只命中 templates/global/CLAUDE.md 的那三條，和 slim-design.md:33（使用者的決定）。沒有殘留的指標或節名。
- `git grep -n c0f6d33`（同樣的排除）→ 只有兩份量測紀錄引用，都是歷史敘述
- `git grep` 找模板或 dd-loop 的行數、bytes 宣稱 → 只有 slim-design.md:45 的「58 行」與 2026-10-23 design 的「901 行」，都是當時的快照、有日期。大小上限 `claude-md-max-bytes` 只管根目錄 CLAUDE.md，不管模板。
- `git grep -n '§3\.9'`（commands、agents、skills、scripts、README、ARCH、各層 CLAUDE.md）→ 沒有一句預設這三條在 dd-loop 或不在模板。CLAUDE.md:159「§3.9 只留 8 步清單、不能跳的關卡與驗證教訓」與現況一致。
- `git log -S` 查 README.md「domain pitfalls」、README.zh-TW「另有「領域陷阱」一節」、ARCH「另從 §3.9 搬來」→ 三句都是 c360152 加的、73cd7a5 拿掉的
- `git show 2636b36:templates/global/CLAUDE.md | grep -n '每完成一個\|^規則:\|迴圈外'` → v1.6.16 的 §3.9 前言（237）與「規則:」（267）都在；整份檔沒有「迴圈外」
- 用 awk 列 S1-c.md、S1-d.md 的 `## ` 標題 → 兩份的改動都在「## 處置」之後（S1-c 處置從檔內第 184 行起、改動在 187 起；S1-d 處置從約第 183 行起、改動在 203），符合 docs/reviews/CLAUDE.md「只有第三節可以補」的規定
- `grep` commands/dd-stop.md、commands/dd-init.md → 沒有提到領域陷阱、race 或那一節

【Critical】
無。

【Important】
1. [Important] templates/global/CLAUDE.md（審查材料第 2024、2054–2068、2081–2085 行）：三條搬回 §3.9「規則:」之後，ba799a2 指標句裡的適用範圍沒有跟著回來。拿掉的是 diff 第 155–156 行：「…碰到這類修改就用 Read 讀 …,迴圈外的修改、迴圈暫停中也一樣」。而這三條現在所在那一節的前言是第 2024 行：「每完成一個**功能段落**(非每行改動),依序走下面 8 步。」
   - 錯在哪：repo 自己寫明了這個位置的問題。CLAUDE.md:161–162 說：「寫註解…的判準在全域模板 **§3.10**，刻意放在 §3.9 之外：§3.9 的前言是「每完成一個功能段落…依序走」，放在裡面的話，沒跑迴圈的專案會連這些判準一起跳過。」暫停聲明 scripts/dd-stop.sh:108 也寫「這一句優先於…全域 CLAUDE.md §3.9 的迴圈；其他規則照舊（動手前的佐證、測試要跑綠、破壞性操作先確認）」。照字面讀，那三條屬於「§3.9 的迴圈」，不在「照舊」的清單裡。
   - 失敗情境：兩種 session 會照字面把三條判成不適用，而且不會報錯。①迴圈外的單次修改：例如沒蓋章的專案，使用者說「修一下這支 API 的 race」，模型照「交易包起來」修、用「同時打兩發」驗。②`/dd-stop on` 暫停中的專案碰到同一種修改。這正是 S1-c-1 量測的情境（docs/measurements/2026-11-20-domain-traps-pointer.md）。現在三條每個 session 都會載入，「讀不到」的問題解決了，「讀到但判成不適用」沒有人處理過。CHANGELOG 第 255 行把指標句那句「迴圈外、暫停中也一樣」降成「搬回之前的經過（留作紀錄）」，等於宣稱這個顧慮隨搬回而消失，沒有依據。
   - 第 4 部分的驗證抓不到這件事：A、B 只證明文字與 v1.6.16 相同；C、D、H 只證明殘留字串歸零。沒有一項檢查適用範圍。
   - 不是 v1.6.16 才有的問題：ba799a2 曾用指標句把範圍補上，這段 diff 把它拿掉了。同一節另外 5 條教訓也有相同的範圍問題，那部分是既有的，見下。要不要在 §3.9「規則:」補一句範圍（這樣會偏離「與 v1.6.16 逐字相同」），還是改放到 §3.10，需要使用者決定：使用者 2026-11-20 選的是「搬回全域模板」，選項裡有沒有包含「位置與 v1.6.16 相同」，材料裡看不出來。

【Smells】
無。

【既有問題】
- §3.9「規則:」裡另外 5 條驗證教訓（擋誤用三件事、鑑別力測試、0 紅先疑實驗、識別符 git grep、清點分母）有同一個範圍問題：它們在前言「每完成一個功能段落」那一節底下，暫停聲明又只把 §3.9 整節當成「迴圈」。這幾行不在這段 diff 的 `+` 行裡，v1.6.16 就這樣（2636b36 的「規則:」在第 267 行），所以判定是既有的。
- c360152 在 README.md 加了「domain pitfalls」那句，但 S1-c 處置與 CHANGELOG Fixed 那一項（審查材料第 229 行）只記了 README.zh-TW 與 ARCH，漏了英文版。這段 diff 已經把那句拿掉，兩邊抵銷，現在沒有後果。

【Not reported】
- 量測紀錄開頭指向 `docs/reviews/2026-11-19-prompt-audit/` 的 `S2-…md`，目前目錄裡只有 S1-*：這是指向這一輪即將落地的報告，步驟 4 完成後就成立。
- CHANGELOG「位置與 v1.6.16 相同」「只差 ⚠️⚠️ → ⚠️」：第 4 部分的 A、B 用 diff 證明了，我沒重跑。
- 模板裡引用「§3.9 鑑別力測試那條」（2001 行）、「§3.9 那條 diff 動到…」（§3.10）、「§3.9 …實驗本身那條」：指到的條目都還在 §3.9。
- dd-loop 第 1637 行「全域 §3.9 列出 8 步與不能跳的關卡」：沒有預設那三條在 dd-loop。
- slim-design.md:45 的「58 行／20,287 bytes」：是 2026-10-30 的快照、有日期，也不是這段 diff 動的。

【需要外部查證】
- Important 1 的行為面：要開新 session 跑 `claude -p` 才知道。①迴圈外的資料庫 race prompt（沿用 domain-traps-pointer.md 那一個）在新模板下，模型會不會套用那三條，對照 ba799a2 的指標版。②`/dd-stop on` 暫停中跑同一個 prompt。這兩項要部署後跑模型，不在我的權限內。

## 處置

修正與這份報告在同一個 commit（步驟 6）。編號照「發現」節：Important 那一條記成 S2-a-1。

| 發現 | 級別 | 處置 |
|---|---|---|
| S2-a-1 三條搬回 §3.9 之後，指標句裡的「迴圈外的修改、迴圈暫停中也一樣」沒有跟著回來 | Important | 文字的部分屬實：§3.9 沒有任何一句寫這幾條在迴圈外適用（步驟 5 乾跑的 subagent 也這樣回報，它說自己會套用、但是自己推的）。沒有補範圍句，依據是量測：審查者列的兩個外部查證都做了，部署搬回版之後用同一個資料庫 race 的 prompt 各跑 8 發，迴圈外 7 發、迴圈暫停中 7 發的回答用到那一條（判定看有沒有「隔離級別」四個字；16 發都有效）。規則是跑之前寫的：過半就不補、模板維持與 v1.6.16 相同。紀錄在 `docs/measurements/2026-11-20-lessons-outside-loop.md`，連同它的限制（只有一個 prompt；記號是看過先前 16 發才挑的；git 進行中狀態那一條沒測）。審查者建議「補不補交使用者決定」：沒有問。使用者選的是搬回全域模板；補不補一句範圍是寫法，量得出來，照量測定。CHANGELOG 那一項補上這次量測，不再讓「搬回之前的經過」那一句看起來像顧慮已經消失。 |

既有問題兩項：
- §3.9「規則」裡另外五條驗證教訓有同一個範圍問題：屬實，v1.6.16 就是這樣，沒改。這次量的只有 race 那一條；五條都沒測，記在量測紀錄的「沒量的」。
- `c360152` 在 `README.md` 也加過那一句，但 S1-c 的處置與 CHANGELOG 只記了中文版與 ARCH：屬實，已補（`S1-c.md` 處置的 S1-c-1、S1-c-s5 兩列與 CHANGELOG 那一句都加上英文 README）。

Not reported 的各項看過，沒有要翻案的。量測紀錄開頭指到的 `S2-…md` 就是這一組報告。
