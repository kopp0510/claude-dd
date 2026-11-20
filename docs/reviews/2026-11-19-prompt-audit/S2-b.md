# S2-b（審查者 B：改動紀錄對不對得上 diff 與 git 歷史）— 三條教訓搬回全域模板（`ba799a2..`）

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），三個在同一則訊息平行派出（2026-11-20）。步驟 3（code-simplifier）沒有跑，理由在審查材料第 2 部分。
Agent 呼叫的 prompt 如下（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是審查者 S2-b。先用 Read 讀完這份派工，照它做：
> <scratchpad>/s2/prompt-common.md
>
> 你的重點檔（第 3 部分整檔讀完）：CHANGELOG.md（「## 未發布」）、docs/measurements/2026-11-20-domain-traps-pointer.md、docs/reviews/2026-11-19-prompt-audit/S1-c.md 與 S1-d.md 的「## 處置」節。
> 重點問題：這幾個檔說的每一件事（哪個 commit 做了什麼、誰在哪天決定什麼、與 v1.6.16 差在哪、量測的數字、「後續」寫的事）對不對得上 diff 與 git 歷史；改寫 CHANGELOG 那一項時有沒有掉了原本記著的事；報告凍結的兩節有沒有被動到。整段 diff（第 1 部分）一樣全部讀完，其他檔有發現照報。

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

S2-b 審查報告（範圍 `git diff ba799a2 HEAD`，HEAD = 73cd7a5；重點：CHANGELOG「## 未發布」、domain-traps-pointer 量測紀錄、S1-c／S1-d 的「處置」節）

Critical 0 / Important 0 / Smells 1

【我讀了什麼】
- 審查材料 diff-pack.md：第 1、2 部分（1–186）、第 4 部分（2542–2553）全部讀完。
- 第 3 部分的重點檔整檔讀完：CHANGELOG 188–269、docs/measurements/2026-11-20-domain-traps-pointer.md 1132–1208、S1-c.md 1209–1418、S1-d.md 1419–1628。
- 另外從 repo 讀了：docs/reviews/CLAUDE.md（前 60 行）、S1-judge.md 59–70 與 112–137、docs/designs/2026-10-30-global-claude-md-slim-design.md 28–38，以及 `git show c360152`、`git show -s ba799a2`。

【What I ran】
- `git log --format='%h %ad %s' 2636b36..HEAD -- templates/global/CLAUDE.md` → 動過模板的 commit 有 c0f6d33、3637c92、3e3243a、8dcaa73、c360152、73cd7a5。
- `git diff 2636b36 HEAD -- templates/global/CLAUDE.md`（先把 ⚠️⚠️ 換成標記再看）→ 和 v1.6.16 的差異只剩四種：
  - ⚠️⚠️ 收成 ⚠️（各處）
  - §6.2 一行變三行（8dcaa73）
  - §6.7 的 docker 例外（3e3243a）
  - §7.1、§7.2、§7.6（c0f6d33）
  - 266 與 291 兩個 hunk 只差 ⚠️。所以「三條位置與 v1.6.16 相同、文字只差 ⚠️⚠️→⚠️」成立。
- `git diff 2636b36 HEAD --stat -- skills/dd-loop/SKILL.md README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md` → 只有 dd-loop 2+/2-（31dd5bb 的 ⚠️），兩份 README 與 ARCH 都回到 v1.6.16 的樣子。
- `git show c360152 -- README.md README.zh-TW.md` → 兩份 README 都在 c360152 加過「領域陷阱／domain pitfalls」。
- `git show -s ba799a2` 加上 S1-judge.md 133 行：「S1-c-2：搬回全域模板。另開 S2 段落做，報告放同一個目錄的 `S2-…md`」（2026-11-20，用 AskUserQuestion 問的）→ 這和 CHANGELOG、S1-c、S1-d 的「後續」，以及量測紀錄開頭的說法相符。
- `grep -n '^## ' S1-c.md S1-d.md` → 「處置」節在 S1-c 第 184 行、S1-d 第 183 行。diff 的 hunk 從 187、203 起，所以只動到處置節，派工、發現兩節沒被動到。
- `git grep -n -i 'read-then-write\|advisory\|rebase-merge\|進行中狀態\|併發驗法\|race 與交易\|pitfall'`（排除 CHANGELOG、docs/reviews 與這份量測紀錄）→ 只命中模板 269、274、297 行，以及設計文件第 33 行（「留在全域」，和現況一致）。
- `git grep -n c0f6d33`（排除 docs/reviews）→ 只命中 CHANGELOG 與量測紀錄，都是歷史敘述。
- `grep -n '搬來\|§3.9' skills/dd-loop/SKILL.md` → 沒有句子指向已經拿掉的那一節。
- `git grep` 找全域模板的行數／bytes 宣稱 → 只命中歷史紀錄（CHANGELOG 舊版本區塊、設計文件），沒有現行的宣稱會被 +16 行弄錯。

【Critical】
（無）

【Important】
（無）

【Smells】
1. Smell｜CHANGELOG.md 審查材料第 253 行
   - 原文：「這三條的文字與 v1.6.16 只差 `⚠️⚠️` → `⚠️`；模板其他地方的差異見本節 `c0f6d33`、`3637c92`、`3e3243a` 的條目。」
   - 錯在哪：這份清單少了 8dcaa73。照 `git diff 2636b36 HEAD -- templates/global/CLAUDE.md`，模板和 v1.6.16 的差異還包括 §6.2（8dcaa73：「不做：自動重試」從一行變三行）。§6.2 那一條在同一節（第 242 行起），但那個條目沒有附 hash。
   - 失敗情境：發版前有人照這句的三個 hash 逐條核「模板和 v1.6.16 差在哪」，會漏掉 §6.2。這句是要給出完整差異清單的，結果缺一項（§3.10「列舉」那一類）。修法：補上 §6.2 那一條（8dcaa73）。
   - 第 4 部分的驗證：A、B 只驗了三條的文字與「規則」整塊，沒有驗這句「其他差異見哪幾條」，所以它是沒被驗過的宣稱。

【既有問題】
- CHANGELOG 材料第 229 行與 S1-c.md 處置 S1-c-1（材料第 1399 行）列的「補上領域陷阱」對象不完整：
  - c360152 實際改了 README.md、README.zh-TW.md、DD_PIPELINE_ARCHITECTURE.md 三個檔。
  - CHANGELOG 229 只記 ARCH；S1-c-1 只記 README.zh-TW 與 ARCH，兩處都沒記英文 README.md。
  - 這兩行在這段 diff 裡雖然是 `+` 行，但只是在後面補上「已拿掉」或「後續」，漏列的部分 c360152 時就是那樣，不是這次引入的。
  - 現在三個檔都已經回到 v1.6.16 的寫法，新寫的 CHANGELOG 251 行也寫「兩份 README」，所以最後的狀態是對的，影響很小。

【Not reported】
- CHANGELOG 改寫那一項有沒有掉了原本記著的事：原本記的「c0f6d33 搬到領域陷阱、原處留指標」「指標改寫與 8 發對 4 發的量測」都還在。只有「還沒問使用者」換成了答案和原因，沒有掉內容。
- 量測紀錄內文第 1147 行的 `git diff ecfc89c -- templates/global/CLAUDE.md` 現在重跑會得到不同結果：開頭已經寫明「下面的內文沒有改、量的是搬回之前」，算歷史紀錄。
- 量測紀錄開頭指向還不存在的 `S2-…md`：這是本段步驟 4 正在產生的報告，命名照 S1-judge 133 行與 docs/reviews/CLAUDE.md 的格式，不算承諾別處沒有的東西。
- S1-c-2 處置裡「CHANGELOG 的那一條寫明『留在哪一邊還沒問使用者』」在 HEAD 已經不成立：同一格緊接著寫了「後續：…CHANGELOG 那一條跟著改寫」，讀得通。
- S1-judge.md 處置第 63、114 行還在講「指標那一句」：那是 S1 當時做了什麼的紀錄，第 133 行記了後來的決定，不算過期。
- docs/reviews/CLAUDE.md 規定處置節要保持正確：這次在 S1-c、S1-d 補「後續」符合這條，沒有違規。
- 第 4 部分 B 的 awk 從「規則:」抽起，可能匹配到更前面的「規則:」：兩版做同樣的 ⚠️ 替換後照樣逐字比對，抓得到文字或位置的改動，我自己的 diff 也確認了。

【需要外部查證】
- 無（步驟 5 已列出部署、部署版 diff、新 session 載入確認，不在本次唯讀範圍）。

## 處置

修正與這份報告在同一個 commit（步驟 6）。編號照「發現」節：Smell 那一條記成 S2-b-s1。

| 發現 | 級別 | 處置 |
|---|---|---|
| S2-b-s1 CHANGELOG 列「模板其他地方的差異見哪幾條」時漏了 `8dcaa73`（§6.2） | Smell | 採納，已修（與 S2-c-s1 同一件）。查證：`git log --format=%h 2636b36..HEAD -- templates/global/CLAUDE.md` 印出 `73cd7a5`、`c360152`、`8dcaa73`、`3e3243a`、`3637c92`、`c0f6d33`；`c360152` 改的是指標句（已隨搬回拿掉）、`73cd7a5` 是搬回本身，其餘四個就是那一句該列的。那一句補上 `8dcaa73`，§6.2 那一項也補上 hash。 |

既有問題一項（CHANGELOG 與 S1-c 處置漏記英文 `README.md`）：屬實，已補（與 S2-a 的既有問題、S2-c-s2 同一件）。

Not reported 的各項看過，沒有要翻案的。
