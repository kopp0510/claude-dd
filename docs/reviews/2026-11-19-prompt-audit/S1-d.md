# S1-d（審查者 D：repo 內各層文件與量測紀錄的事實宣稱）— 2026-11 提示文字稽核的改動（`2636b36..`）

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-20），在步驟 3（code-simplifier）跑完、沒有改任何檔之後。
Agent 呼叫的 prompt 如下（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是審查者 S1-d。先用 Read 讀完這份派工，照它做：
> <scratchpad>/s4/prompt-common.md
>
> 你的重點檔：repo 內各層文件與量測紀錄：CLAUDE.md、scripts/CLAUDE.md、scripts/githooks/CLAUDE.md、tests/CLAUDE.md、docs/measurements/CLAUDE.md、docs/measurements/2026-11-19-global-6.2-retry.md、CHANGELOG.md（未發布一節）、skills/tech-diagram-gif/ 的四個檔。這幾份 CLAUDE.md 很長而改動只有幾行：第 3 部分只需要讀改動那幾行的前後各約 40 行，以及那幾行引用到的段落。
> 重點問題：diff 的 `+` 行裡每一個可以查的事實宣稱（commit hash、tag、檔名與路徑、節名、腳本與測試的數量、函式或變數名、日期、量測數字、引用別處的原文），逐條用 grep／git／ls 對 repo 查，附指令與輸出；查出不符的報成發現，查了相符的列在 What I ran。另外看：量測紀錄的結論有沒有超出它的數據；CHANGELOG 未發布一節說的每一項，在 diff 裡找得到對應的改動嗎。整段 diff（第 1 部分）一樣全部讀完，其他檔有發現照報。

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

S1-d 審查報告(範圍 `git diff 2636b36`..`ecfc89c`,重點:各層文件、量測紀錄、CHANGELOG 未發布、tech-diagram-gif)

【我讀了什麼】
- diff-pack.md:第 1 部分(1–1691)與第 2 部分(1692–1695)全部讀完,第 4 部分(7323–7375)全部讀完。
- 第 3 部分讀了:CHANGELOG(1699–1742)、CLAUDE.md(1744–2099)、docs/measurements/CLAUDE.md(3020–3062)、scripts/CLAUDE.md(3064–3179)、scripts/githooks/CLAUDE.md(3398–3487)、tests/CLAUDE.md(7184–7273)、tech-diagram-gif/SKILL.md(5545–5770)。
- 量測紀錄與 diff 裡的新檔內容相同,在 225–315 讀過。
- 沒有整份讀 pack 裡的 composition-quality-contract.md、icons.md、style-2-dark-terminal.md(5772–6445)。這三份只讀了 diff hunk,另外從 repo grep／sed 看了相關段落(contract 118–140)。
- 從 repo 另外讀的:skills/tech-diagram-gif/scripts/verify-geometry.py(245–330、420–470)、skills/tech-diagram-gif/scripts/CLAUDE.md(grep)、agents/LICENSE.txt(1–40)、docs/measurements/2026-11-15-reviewer-effort.md(grep)、tests/test-*.sh(trap／mktemp)、.github/workflows/ci.yml(grep)。

【What I ran】
- `git log --oneline 2636b36..HEAD` → 17 個 commit,`c0f6d33`…`ecfc89c`。
- `git ls-tree <tag> scripts/githooks/`:
  - v1.6.14 只有 pre-commit;v1.6.15、v1.6.16 有 claude-md-max-bytes。
  - 最新 tag 是 v1.6.16(`git describe --tags --abbrev=0`)。
  - githooks/CLAUDE.md 與 CHANGELOG 的 tag 說法相符。
- `git cat-file -e "v1.6.14:scripts/githooks/claude-md-max-bytes"`(字面寫 tag)→ rc=128;v1.6.16 → rc=0。
- 我第一次用 zsh 迴圈 `"$t:scripts/…"` 跑,印出 `v1.6.14 rc=0`。那是 zsh 展開造成的假結果(見 Important 3),不是事實。
- `git log -p 2636b36..HEAD -- scripts/githooks/CLAUDE.md` → 31dd5bb(2026-11-18)寫「v1.6.14 到 v1.6.16 都帶」,96753ff 更正。CHANGELOG 那句描述相符。
- `git show -s a372fe3` → 2026-06-23「frontend-design 更新至上游最新版」。`git diff a372fe3 HEAD -- skills/frontend-design/SKILL.md` 只差 description 與 modifications 兩行,相符。
- `git show --stat 29726db` → 2026-10-16,改了 CHANGELOG、DD_PIPELINE_ARCHITECTURE、兩份 README、scripts/CLAUDE.md,相符。
- `git diff 8dcaa73^:templates/global/CLAUDE.md 8dcaa73:templates/global/CLAUDE.md` → 只差 §6.2(-1 行、+3 行),與量測紀錄「只差 §6.2 那三行」相符。
- `git show --stat` 查 3637c92、31dd5bb → remember 的 description、兩個 agent 的 frontmatter、extract 的「Agent tool」,與 Differences 那條相符。「this commit」那條是 43373fe 加的,該 commit 動了所列各檔,相符。
- `grep -nE '\bTask\b' CLAUDE.md docs/measurements/CLAUDE.md commands/*.md skills/*/SKILL.md …` → 只剩 task-planner 的標題與 vendored 的 security-audit。「三處」= CLAUDE.md 2 處 + docs/measurements/CLAUDE.md 1 處,相符。
- `grep -n '^#' docs/measurements/CLAUDE.md` → 「已知的坑」是第 44 行的 `##`,新加的條目在它底下,相符。
- `grep` docs/measurements/2026-11-15-reviewer-effort.md → 174–179 行的表:三發都是 84/85、159/160、234/235、312。CLAUDE.md 的「四發一個隔約 75 秒」相符。
- tests:`ls tests/` 有四支;每支都有 `WORK=$(mktemp -d)` 加 `trap 'rm -rf "$WORK"' EXIT`;ci.yml 第 36–39 行四支都在 shellcheck 清單。全部相符。
- verify-geometry.py:`grep -c 'data-graph-role\|data-owner'` → 0。第 317–319 行 `role != 'edge'` 就跳過。contract 第 126–129 行有那段原文。scripts/CLAUDE.md 第 48–50 行有「部分標記…整批略過」。composition contract 新加的那句全部相符。
- `git grep -n 'git-common-dir\|worktree' -- docs/` → 0 筆。
- `git grep -c '⚠️⚠️'` → 還剩在 scripts/CLAUDE.md(3)、tests/CLAUDE.md(2)、tests/test-gate.sh(3)、scripts/dd-init-upgrade.sh(1)。最後那處是舊版範本行清單,應該留著。
- `wc -l agents/code-reviewer.md` → 119,與 agents/LICENSE.txt 寫的行數相符。

【Critical】
無。

【Important】

1. CHANGELOG「## 未發布」漏記 2026-11-18 那 8 個 commit 的改動。Fixed 那一節卻拿它們當「上次」「先前的改動」。
   - 證據:`git log --name-only 2636b36..HEAD` 顯示 `c0f6d33`、`d468905`、`3637c92`、`31dd5bb`、`43373fe`、`3e3243a`、`2117860`、`febdc45` 都沒動 CHANGELOG.md。
   - 這幾個詞在未發布一節 `grep -cF` 都回 0:OWASP、senior-devops、security-auditor、§7、領域、dd-loop、dd-init、tech-diagram、SVG、docker、allowed-tools、templates/global、marketplace。
   - 漏掉的是會改變部署後行為的改動:
     - 全域模板 §7.1 第 5 條、§7.2 由「任何 `.md`」改成「`CLAUDE.md`」並刪掉「優化 skill」、§7.6 拿掉「under-trigger 比 over-trigger 嚴重」(pack 1642–1667)。
     - 領域陷阱從 §3.9 搬到 dd-loop(1410–1429、1466–1494)。
     - §6.7 加了 docker 例外(1633)。
     - security-auditor 改成 OWASP 2025 並重新編號(111–138)。
     - code-simplifier 的 `allowed-tools: Task` 改成 `Agent`(378–379),commands/dd-init.md 的 Task 也改成 Agent。
     - tech-diagram-gif 硬閘門 3:SVG 從「產出後刪除」改成「一開始就寫在暫存目錄、不刪」(1344–1350)。
     - self-improving-agent 的 2026-11-18 那批(remember 用索引寫主題檔、全域規則改寫到 templates/global、拿掉 Copilot)。
   - CHANGELOG 第 27 行(pack 1714)寫「上次只改了 `commands/`、`skills/` 那幾處」,那個「上次」本身就不在任何 CHANGELOG 區塊裡。
   - 失敗情境:發 1.6.17 時把未發布一節改成版本區塊,用 `--force` 更新的人讀 CHANGELOG 看不到 §7 觸發規則改了、看不到 tech-diagram-gif 不再刪 SVG,不會報錯。
   - 依據:root CLAUDE.md「CHANGELOG 條目一律寫進 `## 未發布`」(pack 2031),以及「觸發時機」含「§3.9 文案(含 dd-loop)」(1997)。

2. 量測紀錄的結論超出它自己定下的判定方法,CHANGELOG 第 51–53 行(pack 51–53、1738–1740)照搬了這個結論。
   - 方法寫「**只看服務 log 的請求序列,不看模型自述**」(242),「判定式在跑之前寫下」的只有請求數:S1、S2 各 2 次 GET,S3 1 次,S4 不該有沒查就再 POST(253)。
   - 但粗體結論「失敗後的第一個動作有差別」(232)量的是 `lsof`、`curl -v`、`sleep 3`。
     - 這些不會出現在服務 log:`log()` 只寫 `time method path code`(281)。
     - 也不在事先寫下的判定式裡。
     - 照它自己的判定式,結論應該是「沒有差別」,也就是 12c22f4 原本的 commit 標題。
   - 「舊寫法 10 發都先查原因」用到了它自己規則判為無效的發:
     - 「有效的一發要 `permission_denials` 為空」(254)。
     - S2 的 A 臂 5 發都有 denial(255、263)。
     - S2b 的 A 臂有 1 發 denial(269,`ps`)。
     - 所以 10 發裡照規則有效的只有 4 發。
   - 「舊寫法 5 發裡 1 發停下來回報」出自整臂無效的那一批(n=1)。B 臂沒有試 `lsof`、也就沒被擋,所以這一發可能是白名單造成的,不是 §6.2 措辭造成的。
   - S4 表後自己寫「只能當跡象」(270),結論段與 CHANGELOG 第 53 行卻直接寫「兩邊都先查過才重送」。
   - 失敗情境:以後有人拿這份紀錄當「措辭改變了行為」的證據,這份紀錄依它自己的規則撐不住這個說法。
   - 補充:S1、S3、S4 的白名單和 S4 的 prompt 沒有記下來,原始 log 也沒有進 repo(`ls docs/measurements` 沒有同名目錄),所以無從重核。

3. githooks/CLAUDE.md 新加的「查法」在 zsh 裡用變數帶 tag 時會靜靜回 0(pack 3448)。
   - 原文:「`git cat-file -e "<最新 tag>:scripts/githooks/claude-md-max-bytes"` 回 0 就是走第 1 條」。
   - 在 Bash 工具(zsh;root CLAUDE.md 1923 行寫明是 zsh)裡,通常會寫成 `t=$(git tag --list 'v*' --sort=-v:refname | head -1); git cat-file -e "$t:scripts/…"`。zsh 會把 `$t:s…` 當成 `:s` 修飾子。
   - 實測:`zsh -c 't=v1.6.14; print -r -- "[$t:scripts/githooks/claude-md-max-bytes]"'` → `[v1.6.14`,路徑整段被吃掉。`cat-file -e v1.6.14` 回 0,而 `ls-tree` 顯示 v1.6.14 沒有這個檔。我自己第一次查就中了這個坑。
   - 失敗情境:之後最新 tag 沒有上限檔時,照查法判成「走第 1 條」,不會去走第 2 條「擋不住」的那兩種處理。不會報錯。
   - 修法:寫成 `"${t}:scripts/…"`,或註明要寫 tag 字面值。

【Smells】
- docs/measurements/CLAUDE.md 「已知的坑」開頭的註(pack 3023)還寫「最後一條『同一個對話派出的 subagent』是 2026-11-16 新加的」。這次在它後面加了 2026-11-19 的 scratchpad 那條(3057),那句已經不成立。讀的人會把新的那條當成從根目錄 CLAUDE.md 搬來的。
- 量測紀錄第 14 行(pack 240)「見 `CLAUDE.md`『已知的坑』」沒寫路徑。根目錄 CLAUDE.md 沒有這一節(`grep -n '^#'` 只在 docs/measurements/CLAUDE.md 第 44 行找到)。
- tech-diagram-gif/SKILL.md ffmpeg 那段(pack 5681、5685)用了 `"$TMP/f%03d.png"`,但沒有任何指令設定 `TMP`:硬閘門 3 只說「scratchpad;沒有就 `mktemp -d`」。新開的 Bash 呼叫裡 `$TMP` 是空的,會變成讀 `/f%03d.png`。這段 diff 在 promote 第 6 步、status 第 3 步修的正是同一類問題(「a new command starts without … variables」)。
- scripts/CLAUDE.md(pack 3113)把原本「巡完動到的是兩份 README…、ARCH 的 gate 段、CHANGELOG 的 `## 未發布`」縮成「照專案 CLAUDE.md『觸發時機』那條」。但那條的手動同步清單(pack 1988–1995)沒有 CHANGELOG,縮短時掉了這一項。
- root CLAUDE.md(pack 79)縮短時拿掉了原因:「每個 Agent 呼叫的 prompt 約 1.48 萬字元,寫完才出現在紀錄檔」(reviewer-effort.md 第 171 行)。下一句的「放成檔、prompt 只給路徑」因此看不出為什麼有效。
- CHANGELOG 第 19 行與 memory-architecture.md 新加的那句都說「2026-11-19 用 `claude -p` 實測(子目錄、worktree)」,但 repo 裡找不到這次實測的紀錄(`git grep git-common-dir -- docs/` 回 0)。

【既有問題】
- tech-diagram-gif:沒有 ffmpeg 時退化交付 SVG,要把 SVG「從暫存目錄複製到交付目錄」(5569)。第 6 步(5697)與 Taste Gate 交付組(5755)卻要求「交付目錄只有 GIF」,照清單打勾會判成沒過。舊版(pack 1381、1390)的「交付目錄只留 GIF」就已經有同樣的矛盾,不是這段 diff 引入的;這段 diff 只換了措辭。
- tests/CLAUDE.md 第 7219、7230 行、scripts/CLAUDE.md、tests/test-gate.sh 還有 ⚠️⚠️。這幾行不在 `+` 行裡,commit 也只宣稱收斂全域模板與 dd-loop 的。

【Not reported】
- 量測的 `--setting-sources project` 隔離與「各 25 發」:5 個情境 × 5 發 = 25,對得上。
- 費用 US$32.7:在 50 × 0.57 到 50 × 0.80 之間。
- 「6 發先 sleep」:S2b 4 發 + S2 2 發 = 6,對得上。
- ffmpeg 指令裡的 `diagrams/<名稱>.gif` 是佔位寫法,和檔內其他 `<diagram.svg>` 一致。
- code-reviewer.md 的 description 改了,但 LICENSE.txt 寫的 119 行還對,而它本來就列「description 與官方不同」。
- 根目錄 CLAUDE.md 第 1778 行還稱它「官方備份」:不在我的重點檔、也不在 `+` 行。
- scripts/dd-init-upgrade.sh 第 74 行的 ⚠️⚠️:那是舊版範本行清單,應該留著。
- §7 改動有沒有照「觸發時機」巡 README／ARCH:不在我的重點檔,沒查。

【需要外部查證】
- `git rev-parse --path-format=absolute --git-common-dir` 在 git < 2.31 上:可能不認這個旗標而把參數原樣印出、仍回 0,讓 ROOT 變成垃圾路徑。要在舊版 git(例如 ubuntu 20.04 的 2.25)跑一次。
- 在 submodule 裡,git-common-dir 是 `…/.git/modules/<sub>`,`${ROOT%/.git}` 剝不掉。Claude Code 對 submodule 用哪個資料夾當 key,要查文件或實測。
- frontend-design「上游內文已改寫」:要拿上游 repo 現行版比對。
- 第 4 部分的乾跑只涵蓋 self-improving-agent。root CLAUDE.md 第 1798 行要求改過的 skill／command 都要乾跑,這段 diff 也改了 tech-diagram-gif、dd-loop、dd-init。
- 第 1815 行要求動到 description 或觸發條件時要開新 session 測「會不會自己叫」。這段 diff 改了 code-reviewer 的 description 和全域 §7 觸發規則,第 4 部分沒有這類測試。
- `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD`、claude 2.1.327 的載入行為:要查官方文件。

## 處置

修正與這份報告在同一個 commit（步驟 6）。編號照「發現」節：Important 是 S1-d-1 到 S1-d-3，Smells 照出現順序是 S1-d-s1 到 S1-d-s6。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-d-1 CHANGELOG「未發布」漏記 2026-11-18 那幾個 commit | Important | 採納，已修（與 S1-b-6、S1-c-3 同一件）：逐個 commit 補上條目，附 hash。 |
| S1-d-2 量測紀錄的結論超出它自己定的判定方法，CHANGELOG 照搬 | Important | 採納，已修。`docs/measurements/2026-11-19-global-6.2-retry.md` 的結論改成只用事先寫下的判定式；「失敗後第一個動作」標成事後多看的一項；照規則無效的發數寫出來；建訂單那一項寫明只能當跡象。CHANGELOG 那一條跟著改。 |
| S1-d-3 githooks/CLAUDE.md 的查法在 zsh 用變數帶 tag 時靜靜回 0 | Important | 採納，已修：查法後面補一句，tag 用變數帶時要寫成 `"${t}:…"`，並寫明 zsh 會把 `"$t:scripts/…"` 的 `:s` 當修飾子。 |
| S1-d-s1 docs/measurements/CLAUDE.md「最後一條是 2026-11-16 新加的」已經不成立 | Smell | 採納，已修：那句補上 2026-11-19 新加的那一條。 |
| S1-d-s2 量測紀錄「見 `CLAUDE.md`『已知的坑』」沒寫路徑 | Smell | 採納，已修：改成 `docs/measurements/CLAUDE.md`。 |
| S1-d-s3 tech-diagram-gif 的 ffmpeg 那段用了沒人設定的 `$TMP` | Smell | 採納，已修：改成寫暫存目錄的實際路徑，並寫明新開的指令沒有先前設的變數。乾跑一發（幀放在專案外的目錄）：ffmpeg 的輸入是幀目錄的實際路徑，`diagrams/login-flow.gif` 是 `GIF image data, version 89a, 640 x 360`，專案 `git status --short` 只有 `?? diagrams/`，幀目錄的 21 個檔都還在。 |
| S1-d-s4 scripts/CLAUDE.md 縮短時掉了 CHANGELOG 那一項 | Smell | 採納，已修：補回「另加 CHANGELOG 的 `## 未發布`」。 |
| S1-d-s5 根目錄 CLAUDE.md 縮短時拿掉了「prompt 約 1.48 萬字元」這個原因 | Smell | 採納，已修：補回。 |
| S1-d-s6 「2026-11-19 用 `claude -p` 實測」找不到紀錄 | Smell | 採納，已補（與 S1-b-s10 同一件）：`docs/measurements/2026-11-20-memory-dir.md`。 |

既有問題兩項屬實，沒在這一段改，轉新段落：tech-diagram-gif 沒有 ffmpeg 時交付 SVG，和「交付目錄只有 GIF」的檢查項互相矛盾；`tests/CLAUDE.md`、`scripts/CLAUDE.md`、`tests/test-gate.sh` 還有連寫兩個 ⚠️ 的地方。

Not reported 的各項看過，沒有要翻案的。

需要外部查證：
- git < 2.31、submodule：都查了，公式算錯，已改（`docs/measurements/2026-11-20-memory-dir.md`）。
- frontend-design「上游內文已改寫」：這一段沒有重查。
- 改過的 skill／command 要乾跑：步驟 5 補跑了 tech-diagram-gif（合成那一步）與 dd-init（建立模式、升級列差異各一發）；dd-loop 這一段只多了「領域陷阱」一節，量的是指標到不到得了它（`docs/measurements/2026-11-20-domain-traps-pointer.md`）。
- 動到 description 或觸發條件要開新 session 測：全域 §7.2 改過的兩列測了（`docs/measurements/2026-11-20-global-7-trigger.md`，每個 prompt 一發）。code-reviewer 的 description 在 2026-11-19 測過（新舊各 5 發），那次的紀錄沒有進 repo，只記在稽核的待辦清單裡。
- `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` 與 2.1.327 的載入行為：沒對官方文件；`docs/measurements/CLAUDE.md` 那一條記的是實測到的現象。
