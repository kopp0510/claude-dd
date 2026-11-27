# S4 審查 — A（self-improving-agent 改完之後自不自洽）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S4（vendored 內容：self-improving-agent 死指標與評分表、agents 授權檔）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s4-review-pack.txt`，763 行，沒進 repo）的組成：
- 第 1 部分：`git diff 5d9d68b HEAD`（表上這段的起點到 HEAD = 6ea3552），工作目錄乾淨、沒有未追蹤的檔；`agents/LICENSE.txt` 只放前 40 行，後面 202 行是 Apache-2.0 全文
- 第 2 部分：步驟 3（code-simplifier）沒有跑，這一段的 diff 全是 Markdown 與純文字
- 第 3 部分：`skills/self-improving-agent/` 被改到的四個檔與 `reference/promotion-rules.md` 在派工當下的整檔內容（帶行號）
- 第 4 部分：已跑過的驗證 V1–V6（兩條 grep 驗收、S4-2 的乾跑與預期、與本機官方副本的比對輸出、照 ci.yml 逐 step 跑、CHANGELOG 與 tag 的差異）

派工 prompt（逐字；prompt 裡的暫存目錄絕對路徑在這裡寫成 `<scratchpad>`，審查者拿到的是一句「先讀這個檔再照做」加這個檔的路徑）：

> 你是程式碼審查者。職責：找漏洞、每條附證據；沒證據的不算。不寫優點、不客套。
>
> repo：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。
> 審查範圍：`git diff 5d9d68b HEAD`（8 步開發迴圈 S4 段落，3 個 commit：90cfe4c、0d2125d、6ea3552）。這一段沒有程式碼，改的是文字：
> - S4-1：`skills/self-improving-agent/` 的 `SKILL.md`、`README.md` 刪掉「OpenClaw」「Codex CLI」兩個安裝小節與 Platform Support 表對應的兩列。
> - S4-2：`skills/self-improving-agent/agents/memory-analyst.md`「### 4. Score each entry」自己的分數定義拿掉，改成指到 `reference/promotion-rules.md` 的 Scoring Guide（這是行為改變）。
> - S4-3：新增 `agents/LICENSE.txt`（兩個官方備份 agent 與官方檔的比對結果，後面附 Apache-2.0 全文）；兩份 README 的授權表、`DD_PIPELINE_ARCHITECTURE.md` 的授權段、根目錄 `CLAUDE.md`、`CHANGELOG.md` 的 `## 未發布` 跟著改。
> - 與上游的差異記在 `skills/self-improving-agent/CLAUDE.md` 檔尾。
>
> 審查包（先讀它）：<scratchpad>/s4-review-pack.txt
> - 用 Read 的 `offset`/`limit` 每次 300 行，讀到最後一行（一次讀太多會靜靜截斷、不報錯）。共 763 行。
> - 第 1 部分是整段 diff（`agents/LICENSE.txt` 只放前 40 行，後面是 Apache-2.0 全文）；第 2 部分是步驟 3 的狀況；第 3 部分是被改到的檔在派工當下的整檔內容（帶行號）；第 4 部分是已經跑過的驗證與預期值。
> - 被改到的檔以審查包第 3 部分為準；沒放進審查包的檔直接讀工作目錄（步驟 4 期間沒有人改工作目錄）。
> - 第 4 部分的驗證已經確認過，不要重跑整套 CI、不要跑 docker。
>
> 規則：
> - 只用手上的資料（讀檔、grep、git 紀錄、在拋棄式目錄裡的小實驗）判斷。需要上網查的列在「需要外部查證」交回。
> - 本機官方 marketplace 副本 `~/.claude/plugins/marketplaces/claude-plugins-official/` 可以**讀**（只讀 `plugins/code-simplifier`、`plugins/feature-dev`、`plugins/pr-review-toolkit` 與根目錄的 `LICENSE`）；`~/.claude/skills/self-improving-agent/` 可以讀。`~/.claude` 底下其他東西不要讀，任何東西都不要改。
> - 不要跑 `./install-dd-pipeline.sh`、不要跑 `claude` 指令、不要改 repo 裡的任何檔、不要 commit。小實驗放在 <scratchpad>/rc4-a/ 底下。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：self-improving-agent 這個 skill 改完之後還自洽嗎。S4-1 刪掉兩個小節與兩列之後，同一個 skill 目錄裡（`SKILL.md`、`README.md`、`CLAUDE.md`、`skills/*/SKILL.md`、`agents/*.md`、`reference/*.md`、`templates/`、`settings.json`、`hooks/`）還有沒有句子指到被刪掉的東西、或因為刪掉而變成講不通（例如別處寫「三個平台」「見上方 Codex 一節」）；Markdown 表格與圍欄刪完之後還完整嗎。S4-2：`memory-analyst.md` 新的那一段，一個只拿到這份 agent 指示的模型照做得出來嗎（路徑對不對、在 plugin 以 `self-improving-agent@skills-dir` 載入時那個路徑存在嗎、讀不到時的做法清不清楚）；同一個 skill 裡還有沒有**第三處**自己定義分數或門檻的地方（`skills/review/SKILL.md`、`skills/promote/SKILL.md`、`skills/status/SKILL.md`、`README.md`、`SKILL.md`…），它們跟 Scoring Guide 對不對得上；`memory-analyst.md` 其他段落（例如 Promotion signals、Output Format 指到 review skill）跟新的那一段有沒有打架。`skills/self-improving-agent/CLAUDE.md` 新增的「Differences from upstream」每一句對不對得上實際的 diff。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體情境 → 會錯在哪）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

逐字原文（交回的訊息；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 1 / Smells 2 — 範圍：`git diff 5d9d68b HEAD` 裡 S4 對 skills/self-improving-agent 的改動（S4-1、S4-2、CLAUDE.md 新增的上游差異一節）
>
> 【發現】
> 1｜Important｜新開的「Differences from upstream」一節只列了兩條 2026-11-15 的改動。claude-dd 先前對這個 skill 做過的改動都沒列，但標題讀起來像完整清單。｜`skills/self-improving-agent/CLAUDE.md:81` `## Differences from upstream (this copy lives in the claude-dd repo)`，底下只有 2026-11-15 兩條。`git log -- skills/self-improving-agent` 列出更早的改動 commit：0a7ad08「五處記憶體目錄路徑編碼」、46f6b91「hook 改用 stdin JSON 介面、/si: 死指令改實名」、a9a2889「error-capture hook…加 30 秒逾時」、0ffc749「hook 改用 $HOME 絕對路徑」。`git show e5137e4:skills/self-improving-agent/skills/review/SKILL.md` 第 26 行還是 `%2F` 的舊算式，現行版是 `sed 's/[^a-zA-Z0-9]/-/g'`。｜情境：日後有人要跟上游重新同步，拿這一節當「本地改了什麼」的清單，覆蓋上游新版時保留這兩條就停手 → 路徑編碼修正、hook 的 stdin 介面與逾時、`$HOME` 絕對路徑都被上游舊版蓋掉，不會報錯（路徑編碼錯了就靜靜找不到記憶目錄）。｜二選一：把標題限定為「2026-11-15 起」；或補上先前的改動，至少寫一句「更早的改動見 `git log -- skills/self-improving-agent`」。
>
> 2｜Smells｜差異說明寫「Upstream had two tables that disagreed」，但 memory-analyst 原本的分數定義是條列，不是表格。｜`skills/self-improving-agent/CLAUDE.md:88` `Upstream had two`／`:89` `tables that disagreed (the agent said Scope 3 = project-wide…`。`git show e5137e4:skills/self-improving-agent/agents/memory-analyst.md` 第 48–50 行是 `Rate each entry on three dimensions:`、`- **Durability** (0-3): …` 這種條列。｜情境：讀者照「表格」去上游找第二張表，找不到 → 懷疑這段記錄寫錯。不影響行為。｜改成「two definitions」。
>
> 3｜Smells｜讀不到檔時的退路只講到評分。同一節下一句的候選門檻、與第 5 步「依分數排序」在沒分數時要怎麼做，沒有寫。｜`agents/memory-analyst.md:51-52` `If you cannot read the file, say so in the report and leave the entries unscored.`，緊接 `:54` `Promotion candidates: total score ≥ 6`、`:59` `1. Promotion candidates (sorted by score, highest first)`。｜情境：promotion-rules.md 讀不到 → 條目全部沒分數 → 第 5 步的候選清單有兩種讀法：空著，或憑第 3 步的 Promotion signals 硬列。結果因模型而異。現況下這個檔存在（`ls ~/.claude/skills/self-improving-agent/reference/` 有 promotion-rules.md，與 repo 版 cmp 相同），只有缺檔時才會發生。｜補一句：沒分數時不列 Promotion candidates，或只列不排序並標明未評分。
>
> 【Not reported】
> - S4-1 刪完還有沒有句子指到被刪的東西：`grep -rniE 'openclaw|codex|clawhub|platform|copilot|scripts/|AGENTS\.md'` 掃整個 skill 目錄，剩下的命中有 `settings.json:8` 的 platforms（CLAUDE.md:86-87 已記為刻意保留）、兩處 `clawhub publish`（`SKILL.md:126`、`skills/extract/SKILL.md:153`，跟「two `clawhub publish` mentions」對得上），以及兩處 clawhub.ai 出處連結（`SKILL.md:150`、`README.md:77`）。沒有「三個平台」「見 Codex 一節」這類句子。
> - 表格與圍欄完整：SKILL.md 142–145、README.md 70–73 都是表頭、分隔線加兩列，每行都以 `|` 開頭。Installation／Install 底下只剩一個 `### Claude Code` 小節，圍欄成對。
> - 還有沒有第三處自己定義分數：同一 skill 裡數字分數與 `≥ 6` 只出現在 memory-analyst.md 與 reference/promotion-rules.md。memory-analyst.md:54 的 `≥ 6` 與 promotion-rules.md:21 一致。`skills/review/SKILL.md` Step 2 第 4 點的候選條件（「Appeared in 2+ sessions」「Not project-specific trivia」）和 `skills/promote/SKILL.md:123-127` 的「appeared 3+ times」都是非數字的準則，從上游原樣留下，與 Scoring Guide 的張力是既有問題，不是這次引入。
> - memory-analyst.md:68 的 Output Format 指到 review skill 的格式，那個格式（「seen {{n}}x, applies broadly」）沒有分數欄位，與第 5 步「依分數排序」不一致。這是既有問題，這次 diff 沒動那兩行。
> - 路徑：`~/.claude/skills/self-improving-agent/reference/promotion-rules.md` 在部署位置存在，與 repo 版相同。寫法跟 hooks.json 的 `$HOME/.claude/skills/...`、`skills/extract/SKILL.md:69` 的同類路徑一致。走上游 `/plugin install` 的人不會有這個路徑，但 hook 早有同樣的前提，屬既有慣例。
> - 部署版的 memory-analyst.md 跟 repo 版不同（cmp 在 line 48 不同）：S4 還沒部署，這是預期內的，不算發現。
> - CLAUDE.md:85 的 Codex 理由「script under `./scripts/` that is not in this directory」：目錄裡確實沒有 `scripts/`（`find . -type f` 的清單裡沒有），句子屬實。
>
> 【What I ran】
> - Read 派工檔 prompt-a.txt 全部；Read 審查包 1–763 行（分三次）
> - `find . -type f | sort`（skill 目錄）→ 22 個檔，沒有 scripts/
> - `grep -rniE 'openclaw|codex|clawhub|platform|copilot|scripts/|AGENTS\.md' .` → 命中都在上面 Not reported 列的那幾行
> - `grep -rniE 'score|≥ ?6|durab|impact|threshold|total' .` → 分數定義只在 memory-analyst.md 與 promotion-rules.md
> - cat `skills/review/SKILL.md` 全文；Read `skills/promote/SKILL.md` 118–150 行；grep status、promote、memory-architecture、templates、skill-extractor 的 candidate／promot／score → 沒有數字門檻
> - `ls ~/.claude/skills/self-improving-agent/reference/` → promotion-rules.md 存在；`cmp` 部署版與 repo 版 promotion-rules.md → 相同；`cmp` 兩邊 memory-analyst.md → 在 line 48 不同（未部署）
> - cat hooks.json、.claude-plugin/plugin.json、settings.json；`grep -rn 'CLAUDE_PLUGIN_ROOT\|~/.claude/skills\|HOME/.claude/skills'` → 全是 `$HOME`／`~` 的絕對路徑寫法
> - `git log --format='%h %ad %s' -- skills/self-improving-agent` → 19 筆，含 0a7ad08、46f6b91、a9a2889、0ffc749 等先前的本地改動
> - `git show e5137e4:…/memory-analyst.md`（46–50 行，條列）、`git show e5137e4:…/promotion-rules.md`（Scope 列與現行版相同）、`git show e5137e4:…/review/SKILL.md`（第 26 行是 `%2F` 舊算式）
>
> 【需要外部查證】
> - 上游 alirezarezvani/claude-skills 現行版的 memory-analyst.md 是否還有那段 Scope 3/1/0 的定義，以及 promotion-rules.md 是否仍是 0/1/2/3 那張表（判斷「Upstream had…」講的是收編當時還是現在）。目前只對過收編時的 e5137e4。

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實。`git log --format='%h %ad %s' --date=short -- skills/self-improving-agent` 最早一筆是 `e5137e4`，之後有它列的 `0ffc749`、`46f6b91`、`0a7ad08`、`a9a2889` 等本機改動，這一節都沒列。
  改法照建議的第二種：節的開頭加一段，寫明這份清單從 2026-11-15 起、不完整，更早的改動讀 `git log -- skills/self-improving-agent`，這個目錄最早的 commit 是 `e5137e4`。
  沒有回頭補寫舊的改動：那會是另一份要靠人維護、會寫錯的清單。
- **2（Smells，採納）**：屬實，舊版那一份是條列不是表格（`git show 5d9d68b:skills/self-improving-agent/agents/memory-analyst.md` 第 48–50 行）。
  改成「The copy in `e5137e4` (the earliest commit of this directory) had two definitions that disagreed」。寫成指到 commit 而不是「Upstream」，
  所以它列的外部查證（上游現行版還有沒有那段定義）不必查：這句現在講的是 git 裡核得到的那一版。
- **3（Smells，採納）**：屬實。`agents/memory-analyst.md` 的退路句後面補一句：沒有分數就沒有升級候選，第 5 步那份清單留空並說明原因，其他清單不靠分數。
  選「留空」而不是「列出來但不排序」：沒有分數時列候選等於繞過門檻。
  這條分支原本沒有乾跑過，補跑一發（sonnet；路徑改成不存在的 `promotion-rules-MISSING.md`，其餘逐字相同；預期在派出前寫下）：
  交回「沒評分：評分表檔讀不到」、沒有找別的檔代替、Promotion candidates 是空的並引了新加的那一句。與預期相同。
  同一版文字的正常路徑也重跑一發：2／2／2 = 6、候選清單有這一條。與預期相同。
- Not reported 裡兩條既有問題沒有動（這次 diff 沒碰那幾行），記在這裡：
  - `skills/review/SKILL.md` 與 `skills/promote/SKILL.md` 的候選條件是「出現過幾次」這類非數字的準則，跟 Scoring Guide 的分數門檻是兩套說法。
  - `agents/memory-analyst.md` 的 Output Format 指到 review skill 的格式，那個格式沒有分數欄位，跟第 5 步「依分數排序」對不上。兩個乾跑臂也都回報這一句要猜。
- 其餘 Not reported：都同意，沒有動作。
