# S1-a（審查者 A：self-improving-agent 給模型照著做的指示與 shell）— 2026-11 提示文字稽核的改動（`1290eb5..`）

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-20），在步驟 3（code-simplifier）跑完、沒有改任何檔之後。
Agent 呼叫的 prompt 如下（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是審查者 S1-a。先用 Read 讀完這份派工，照它做：
> <scratchpad>/s4/prompt-common.md
>
> 你的重點檔（第 3 部分整檔讀完）：`skills/self-improving-agent/` 底下給模型照著做的指示文字：
> skills/promote/SKILL.md、skills/review/SKILL.md、skills/status/SKILL.md、skills/extract/SKILL.md、skills/remember/SKILL.md、agents/memory-analyst.md、agents/skill-extractor.md、reference/promotion-rules.md、reference/memory-architecture.md。
> 重點問題：一個第一次讀這些檔的模型照字面走每一步，會在哪裡做錯、卡住，或兩個模型會做出不同的結果；shell 片段照貼會不會壞。整段 diff（第 1 部分）一樣全部讀完，其他檔有發現照報。

它指到的共用派工 `prompt-common.md`（四個審查者讀的是同一份；同樣只換絕對路徑）：

> # 審查派工（8 步開發迴圈步驟 4，claude-dd）
>
> 你是程式碼審查者。唯一的職責：找漏洞。每一條發現都要附證據（審查材料的行號與原文），沒證據的不算。
> 不寫優點、不寫總評。全程唯讀：不改檔、不 commit、不跑測試、不派別的 agent。
>
> ## 範圍
> repo：<repo>（它的上一層不是 git repo；git 指令用 `git -C <repo>`）
> 要審的是 `git diff 1290eb5`（到工作目錄；工作目錄 = HEAD `c74f115`，沒有未 commit 的改動，沒有未追蹤的新檔）。共 31 個檔、17 個 commit。
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
> - 這段範圍裡先前的 16 個 commit（`e8bd89e` 到 `b5e9f96`）當時都沒有走過審查，這次是第一次審。
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

審查者交回的報告，逐字（只把絕對路徑換成 `<scratchpad>`、`<repo>`）。行號是審查材料 `diff-pack.md` 的行號，凍結在 `c74f115`。

審查者 S1-a 報告（範圍 `git diff 1290eb5`..c74f115，重點是 self-improving-agent 的指示文字）

結果：Critical 0、Important 4、Smell 7。

【我讀了什麼】
- 審查材料 diff-pack.md：第 1–1700 行（第 1、2 部分全部）、第 7323–7376 行（第 4 部分全部）。
- 第 3 部分整檔讀完的：4264–5544 行，也就是 memory-analyst、skill-extractor、memory-architecture、promotion-rules、extract、promote、remember、review、status 九個檔。
- 從 repo 另外讀了 install-dd-pipeline.sh 第 1360–1419 行（create_global_claude_md）。

【What I ran】
- `git --version` → 2.42.0。
- 在 scratchpad 的 s1a 目錄建拋棄式 repo，測 `git rev-parse --path-format=absolute --git-common-dir`：
  - 從 symlink 路徑進到子目錄 → 回傳 real/.git，是實體路徑。
  - 從 worktree → 回傳主 checkout 的 .git。
  - 從 submodule → 回傳 `…/real/.git/modules/mod`。這個值沒有以 `/.git` 結尾，`${ROOT%/.git}` 剝不掉，ROOT 直接是 `.git/modules/mod`。
- 在 claude-dd 底下照貼 ROOT 算式 → 得到 `-Volumes-T7-home-project-my-project-claude-dd`。
- `ls -d ~/.claude/projects/-Volumes-T7-home-project-my-project-claude-dd/memory ~/.claude/projects/-Volumes-T7-home-project-my-project/memory` → 兩個都存在。
- 把 status 第 3 步第 2 段迴圈照貼，餵一份含 4 行的假 MEMORY.md：
  - `~/.claude/skills/x/SKILL.md` → `STALE (path): /.claude/skills/x/SKILL.md`
  - `https://code.claude.com/docs/en/memory.md` → `STALE (path): /code.claude.com/docs/en/memory.md`
  - `./docs/a.md` 與 `docs/a.md`（檔案都存在）→ 沒有列出，正確。
- `date -r <file> +%F`（macOS）→ `2026-11-20`，正常。
- `for k in foo bar; do grep -rniF -- "$k" <不存在的目錄> 2>/dev/null; done` → 沒有任何輸出，rc=2。
- review 的 find 指令：`find … -path "*/./docs/a.md"` → 0 筆；`-path "*/docs/a.md"` → 1 筆。

【Critical】
無。

【Important】
1. promote 與 extract 的搜尋指令補上 `2>/dev/null`，記憶目錄算錯時變成完全不出聲。
   - 位置：diff 第 848→855 行（promote 第 2 步）、第 811→817 行（extract 第 1 步）。
   - 原文：舊版 `grep -ni "<keywords>" "$MEMORY_DIR/MEMORY.md"`、`grep -rni "<keywords>" "$MEMORY_DIR/"`；新版兩處都是 `for k in …; do grep -rniF -- "$k" "$MEMORY_DIR" 2>/dev/null; done`。
   - 錯在哪：唯一的 `[ -d "$MEMORY_DIR" ] || …` 檢查寫在註解行裡，照貼不會執行。舊版的 grep 遇到不存在的目錄至少會印 `No such file or directory`，新版吞掉了。
   - 失敗情境：目錄算錯時（例如下一條的情況），實測沒有輸出、rc=2，看起來和「找不到相關條目」一模一樣。
     - extract 的下一句是「If not, use the user's description directly」，會照常往下做。
     - promote 會回報「記憶裡沒有這條」。
     - 兩處註解自己寫「a missing directory means wrong path, not nothing to promote」，但照貼的指令分不出這兩種情況。
   - remember 原本就有 `2>/dev/null`，不是這次引入的。

2. 五個 skill 用 shell 當下的 cwd 算 repo 根目錄，不是用 session 的專案根目錄。在父目錄開 session、shell 已經 `cd` 進子 repo 時，會靜靜拿到另一份記憶。
   - 位置：promote 第 4943 行、review 第 5252 行、status 第 5400 行、remember 第 5140 行、extract 第 4753 行（`ROOT=$(git rev-parse --path-format=absolute --git-common-dir …)`）。
   - 原文：「The directory is keyed by the git repo root, not the cwd … (tested 2026-11-19)」。
   - 錯在哪：實測只涵蓋「session 開在子目錄」與「開在 worktree」。沒涵蓋「session 開在不是 git repo 的父目錄（例如 my_project），之後 shell 進到子 repo」。專案 CLAUDE.md 寫明主對話的 Bash 會把 `cd` 留到下一次呼叫。
   - 實證就是本 session：載入的記憶是 `-Volumes-T7-home-project-my-project`，而我的 cwd 是 claude-dd。照貼算式得到 `…-my-project-claude-dd`，而且這個目錄真的存在，所以 `[ -d ]` 檢查會通過，不會有任何警告。
   - 失敗情境：
     - status 會顯示另一個專案的健康狀態。
     - remember 會把條目寫進另一個專案的記憶。
     - promote 第 6 步會去刪另一個專案記憶裡的條目。
   - submodule 也一樣，ROOT 變成 `.git/modules/<名>`，見下方「需要外部查證」。

3. review、memory-analyst 列「會載入的 CLAUDE.md」時漏掉上層目錄的 CLAUDE.md 與 CLAUDE.local.md。
   - 位置：review 第 5307–5308 行；memory-analyst 第 4291–4292 行。
   - 原文：「Read the CLAUDE.md files that load for this project, whichever exist: `CLAUDE.md` and `.claude/CLAUDE.md` under the checkout root …, and `~/.claude/CLAUDE.md`」。
   - 錯在哪：這句寫成會載入的檔案的完整清單，但同一份 diff 的其他地方說法不同：
     - docs/measurements/CLAUDE.md（diff 第 335 行）：「連同上層目錄的 CLAUDE.md」都會載入。
     - memory-architecture.md 第 4490 行寫「Files higher in the directory tree load first」，第 4488 行列了 `./CLAUDE.local.md`。
   - 失敗情境：子 repo（例如 claude-dd）的某條記憶，主要指示其實已經寫在上層 my_project/CLAUDE.md。照這句做不會讀那份，結果：
     - 這條會被列成升級候選，而不是「remove from memory」。
     - 和上層那份矛盾的記憶不會進 Conflicts。

4. status 的路徑檢查把 `~/…` 路徑和 URL 判成過期，而過期數會直接決定整體 Capacity。
   - 位置：status 第 5477–5482 行（diff 第 1281–1287 行，這次改了這個迴圈）。
   - 原文：「absolute ones as is, relative ones from $PROJ」，以及 `case $f in /*) p=$f ;; *) p=$PROJ/$f ;; esac`。
   - 錯在哪：正規式不收 `~`，也會從 URL 中間截出一段，截出來的字串以 `/` 開頭，被當成絕對路徑。review 第 5282 行明寫「check an absolute or `~/` path as written」，兩邊做法不一致。
   - 失敗情境：實測 `~/.claude/skills/x/SKILL.md` 與 docs 的 URL 兩行都印 STALE。第 5444 行規定「Stale entries is the total from Step 3」，第 5436 行規定超過 3 筆是 Critical。
     - 一份健康、但有 4 行 `~/` 路徑或文件連結的 MEMORY.md 會被評成 Critical。
     - 第 5518 行的建議會叫人去刪那些其實沒過期的條目。
   - 正規式本身是既有的，但這次改了這個迴圈、加了「absolute as is」的說法，卻沒處理這兩種常見寫法。

【Smells】
1. 退路的 find 找到的是專案目錄，不是記憶目錄，下一步沒有寫。
   - 位置：status 第 5406–5408 行、review 第 5258–5260 行、promote、remember、extract 各自的 fallback 那一行。
   - 情況：`find ~/.claude/projects -maxdepth 1 -name "*<basename>"` 列出的是 `~/.claude/projects/<編碼>`。沒有寫要把 MEMORY_DIR 改成「候選 + /memory」。
   - 最常見的觸發是「這個專案還沒寫過記憶」：專案目錄存在（裡面有 session 檔），memory/ 不存在。這時 find 剛好列出一個「明顯是本專案」的候選，第 5407 行的「Still no directory」就有兩種讀法：
     - 讀成「專案目錄找到了」→ 往下跑，印出一份全是 0 的 dashboard，正是第 5408 行禁止的。
     - 讀成「記憶目錄還是沒有」→ 印 not found 並停止。
2. review 第 5260 行寫「list them and stop, as /self-improving-agent:status does」；Differences from upstream 第 498 行也寫「lists candidates and stops … like status」。但 status 第 5407–5408 行寫的是印 `Memory directory not found` 再停，沒說要列出候選。兩邊照做會得到不同的輸出。
3. status 數 `.claude/rules/` 用 `-maxdepth 1`（第 5427 行），只數第一層。同一個 skill 的 memory-architecture 第 4553 行寫 rules「Recursive — can organize into subdirectories」，而 memory-analyst 第 4293 行是「Read all files」。同一個 repo，status 和 review 報的 rules 數可能不同。
4. memory-architecture 這次加了 MEMORY.md 的 25KB 上限（第 4516、4592 行），但 status、review、remember、memory-analyst 都只算行數。100 行但超過 25KB 的 MEMORY.md 已經被截斷，status 仍會評成 Healthy。
5. status 第 5514 行說 review「may report fewer」，但 review 會讀主題檔、也查版本與工具（第 5283 行），而 status 第 3 步只 grep MEMORY.md。索引式記憶（第 5438–5439 行說這是健康的排法）的路徑都在主題檔裡，review 報的可以比 status 多。這句只寫了一個方向。
6. review、memory-analyst 的 find 寫法沒處理開頭的 `./`：實測 `-path "*/./docs/a.md"` 回 0 筆，所以記憶寫 `./docs/a.md` 會被判成過期。去掉結尾 `/`、拆開 `{a,b}` 那句沒有涵蓋這種寫法。
7. memory-analyst 沒有任何找記憶目錄的步驟，只寫 `~/.claude/projects/<project>/memory/`（第 4276 行）。這次的修正只改了五個 skill（CHANGELOG 第 17 行），被單獨派出去的 agent 只能自己猜路徑，第 2 條的錯也會出現在它身上。這個缺口是既有的，但這次的修正沒有延伸到它。

【既有問題】
- promote 帶 `--target rules/x.md` 但沒給 `--paths` 時，paths 怎麼定沒有規定（Usage 第 4924 行、Step 5 第 5016 行的「if scoped」）。這次只補了「沒給 target」的情況（第 4975 行）。
- extract 第 7 步範本的 `Install: /plugin install`、`Publish: clawhub publish`、`Source: MEMORY.md entries at lines …`（第 4868–4871 行）都不在 `+` 行裡。它們和索引式記憶、以及「不要從 marketplace 裝」的新說法不一致，但不是這次引入的。
- promote Step 5 的「If file would exceed 200 lines, suggest using `.claude/rules/`」（第 5012 行，既有）和這次新增的 Step 3「條目沒點名路徑就寫進 ./CLAUDE.md」（第 4976 行）放在一起時，建議改用的 rules 檔沒有 paths，效果和 CLAUDE.md 一樣。不會壞東西。

【Not reported】
- 「install-dd-pipeline.sh --force 不一致就覆蓋 ~/.claude/CLAUDE.md、先備份」這個宣稱：讀第 1393–1403 行，屬實。
- ROOT 遇到 symlink：git 回實體路徑，和 pwd -P 一致，沒問題。
- `date -r` 在 macOS 可用；GNU 的 `date -r` 本來就是取檔案修改時間。
- Capacity 表和 Interpretation 的百分比界線（120 行 = 60%、180 行 = 90%）對得上。
- CHANGELOG 與 Differences from upstream 記的條目，我抽查了 Duplicates、120 行、Step 6 重算、test conventions、「or mark」、`{{names}}` 六處，diff 裡都對得上。
- 舊版 git（< 2.31）不認 `--path-format`：macOS 這台是 2.42，沒去查別的平台。

【需要外部查證】
- Claude Code 在 submodule 裡開 session 時，記憶目錄用的是 superproject 的根，還是 submodule 自己的 worktree 根。不管是哪一個，現在的算式都會得到 `.git/modules/<名>`。可以在 submodule 開一次 `claude -p`，叫它印 auto-memory 路徑來確定。
- 在不是 git repo 的父目錄開 session、Bash 已經 `cd` 進子 repo 時，Claude Code 載入的記憶目錄確定是父目錄那份（本 session 的現象支持這一點，但沒有對照官方文件）。這是第 2 條 Important 成立的前提，建議用一發 `claude -p` 確認。

## 處置

修正與這份報告在同一個 commit（步驟 6）。編號照「發現」節的順序：Important 是 S1-a-1 到 S1-a-4，Smells 是 S1-a-s1 到 S1-a-s7。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-a-1 promote、extract 的搜尋加了 `2>/dev/null`，目錄算錯時不出聲 | Important | 採納，已修。promote、extract、remember、status 四個檔的「資料夾在不在」從註解改成會執行的一行，不在就印 `Memory directory not found: <路徑>` 再用 `find` 列候選。查證：四個指令區塊在 zsh 與 bash 各跑一次、資料夾不在，都印那一行；步驟 5 乾跑裡資料夾不在的每一發，報告都貼了這一行原樣輸出。 |
| S1-a-2 公式跟著 shell 的 cwd 走，不是 session 的專案 | Important | 屬實，沒在這一段改，交使用者決定。查證：在子 repo 根目錄，`1290eb5` 的公式（`pwd -P`）與現行公式算出同一個資料夾（存在）；在子 repo 的子目錄，舊公式算出不存在的 `…-claude-dd-skills/memory`、現行公式算出子 repo 那一份（存在）。所以審查者說的情境在這一段之前就有，這一段把它擴大到子目錄。要修得先決定記憶跟 session 開的專案走、還是跟 shell 所在的 repo 走（skill 的指令拿不到 session 開在哪）；現況寫在 `skills/self-improving-agent/CLAUDE.md`「Reported by the same review and not changed here」。 |
| S1-a-3 「會載入的 CLAUDE.md」漏掉上層目錄與 `CLAUDE.local.md` | Important | 採納，已修（與 S1-b-2 同一件）。review 第 4 步與 memory-analyst 第 2 步改成三種檔名（`CLAUDE.md`、`CLAUDE.local.md`、`.claude/CLAUDE.md`）在 checkout 根目錄與以上每一層都找，加 `~/.claude/CLAUDE.md`。依據：code.claude.com/docs/en/memory.md（2026-11-20 讀）。乾跑（材料 C，上一層有 `CLAUDE.md`、根目錄有 `CLAUDE.local.md`）：現行版 review 與 memory-analyst 都把寫在那兩個檔的兩條判成「已寫入、建議從記憶移除」；`c74f115` 版兩發都把它們列成候選。 |
| S1-a-4 status 把 `~/…` 與 URL 判成過期 | Important → 既有問題 | 屬實，沒在這一段改，轉新段落。調級的理由：抽路徑的 regex 與「不存在就印 STALE」在 `1290eb5` 就是這樣。拿同一份三行的 `MEMORY.md`（一個 `~/` 路徑、一個 URL、一個存在的相對路徑）跑 `1290eb5` 的那幾行與現行版，兩邊都只印 `STALE (path): /.claude/notes/a.md`、`STALE (path): /example.com/docs/a.md`。這一段對這個迴圈的改動是相對路徑改從 `$PROJ` 起算。要修得換掉抽路徑的方式，是新規則。 |
| S1-a-s1 備援找到的是專案資料夾、不是記憶資料夾 | Smell | 採納，已修。註解寫明候選是專案資料夾、記憶在它底下的 `memory/`，那個目錄存在才採用。步驟 5 乾跑發現 promote、remember、extract 沒寫「沒有候選／好幾個候選」怎麼辦（那幾發是照派工訊息停下的），補了一句：promote、remember 回報後停，extract 講明後只用使用者的描述。乾跑：一個候選、兩個候選、沒有候選三種情況，promote、remember、extract 各一發，停下或不搜的那幾發報告引的依據都是新加的那一句。 |
| S1-a-s2 review 寫「as status does」，status 沒說要列候選 | Smell | 採納，已修（與 S1-b 的 Smell「review 1 對 status」同一件）。status 改成回報「Memory directory not found」加候選後停下。 |
| S1-a-s3 status 數 rules 只數第一層 | Smell | 轉新段落，沒改。 |
| S1-a-s4 沒有任何地方檢查 25KB | Smell | 轉新段落，沒改。 |
| S1-a-s5 status 寫 review「may report fewer」，只對一個方向 | Smell | 採納，已修：改成「may report a different number」，兩個方向的原因都寫出來。 |
| S1-a-s6 `find -path` 沒處理開頭的 `./` | Smell | 採納，已修（與 S1-b-3 同一件）：搜尋前去掉開頭的 `./` 與結尾的 `/`、拆開 `{a,b}`、在 `[`、`]`、`*`、`?` 前加反斜線。乾跑（材料 C）：現行版兩發都找到 `app/[id]/page.tsx` 與 `./src/server.ts`；`c74f115` 版 review 那一發把這兩個存在的檔列成 Stale。 |
| S1-a-s7 memory-analyst 沒有找記憶資料夾的步驟 | Smell | 沒改，轉新段落。它由呼叫的一方給路徑；單獨派出去時怎麼算沒寫，乾跑的幾發也都把這句列為卡住。 |

既有問題三項：`--target` 沒帶 `--paths`、extract 第 7 步的範本，轉新段落；promote 第 5 步「超過 200 行就建議改用 rules」不採納，審查者自己寫明不會壞東西。

需要外部查證兩項：submodule 用哪個資料夾，2026-11-20 用 `claude -p` 量了（`docs/measurements/2026-11-20-memory-dir.md`：用 submodule 自己的根目錄），公式跟著改。「session 開在不是 git repo 的父目錄、shell 進了子 repo」沒有另外量，只有這個 session 自己的現象（載入的是父目錄那一份）。
