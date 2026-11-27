# S1-b（審查者 B：改動紀錄對得上最終文字嗎、跨檔一致）— 2026-11 提示文字稽核的改動（`1290eb5..`）

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-20），在步驟 3（code-simplifier）跑完、沒有改任何檔之後。
Agent 呼叫的 prompt 如下（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是審查者 S1-b。先用 Read 讀完這份派工，照它做：
> <scratchpad>/s4/prompt-common.md
>
> 你的重點檔（第 3 部分整檔讀完）：skills/self-improving-agent/CLAUDE.md、skills/self-improving-agent/SKILL.md、skills/self-improving-agent/README.md、CHANGELOG.md（未發布一節），以及用來對照的 skills/self-improving-agent/skills/promote/SKILL.md、skills/review/SKILL.md、skills/status/SKILL.md、agents/memory-analyst.md、reference/promotion-rules.md。
> 重點問題：①「Differences from upstream」與 CHANGELOG 的每一句宣稱，對得上 skill 檔的最終文字嗎（逐句對，附兩邊原文）；有沒有 diff 裡改了、兩份紀錄都沒記的。②同一件事在幾個檔各寫一次的地方（review 對 memory-analyst、status 對 review、promote 對 promotion-rules、SKILL.md／README 的總覽對各子 skill），字句或條件有沒有不一致。③第 4 部分的驗證有哪些宣稱沒被證明。整段 diff（第 1 部分）一樣全部讀完，其他檔有發現照報。

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

S1-b 的審查報告（範圍 `git diff 1290eb5`，HEAD 是 `c74f115`）

【我讀了什麼】
- 審查材料 `<scratchpad>/s4/diff-pack.md`：
  - 第 1–1700 行（整段 diff、第 2 部分、CHANGELOG 起頭）
  - 第 3852–4361 行（self-improving-agent 的 CLAUDE.md、README、SKILL.md、memory-analyst）
  - 第 4611–4709 行（promotion-rules）
  - 第 4908–5097 行（promote）
  - 第 5220–5544 行（review、status）
  - 第 7323–7376 行（第 4 部分）
- 另外從 repo 讀的：
  - `install-dd-pipeline.sh` 第 1360–1430 行，以及 `PROMOTED_SKILLS`
  - 根目錄 `CLAUDE.md` 第 50–58 行、第 138–143 行，以及裡面提到 CHANGELOG 的幾行
  - `skills/self-improving-agent/reference/rules-directory-patterns.md` 第 1–70 行
  - `skills/self-improving-agent/templates/rule-template.md`
  - git log／tag 的資料

【What I ran】
- `git log --oneline 1290eb5..HEAD` → 17 個 commit，`e8bd89e` 到 `c74f115`。
- `git log -S'same audit, this commit'` → 這句是 `6b46c96` 加的。
- 從 `## 未發布` 抽到 `## 1.6.16`，對每個詞跑 `grep -cF`：
  - Copilot、25KB、OWASP、§7、領域陷阱、ExitPlanMode、優化 skill、docker、state lock、dd-init、tech-diagram、⚠️⚠️、`index` 都是 0。
  - `frontmatter` 1、`remember` 2，但命中的都是別的事。
- 各 tag 的 `git ls-tree scripts/githooks/`：v1.6.13、v1.6.14 只有 pre-commit；v1.6.15、v1.6.16 有 `claude-md-max-bytes`。CHANGELOG 第 26 行的說法成立。
- `git show -s 7278dec` → 2026-06-23「frontend-design 更新至上游最新版」，和 diff 第 439 行對得上。
- `install-dd-pipeline.sh` 第 1393–1402 行：內容不同又帶 `--force` 時，先 `backup_before_overwrite`，再 `cp` 模板蓋過去。「overwrites … after a backup」的說法成立。
- `git grep -e git-common-dir -e worktree -- docs/measurements`：沒有任何一筆是「從子目錄／worktree 開 session 的 `claude -p` 實測」的紀錄。
- 在 scratchpad 的拋棄式 repo 跑 skill 那段 `ROOT=…; ${ROOT:-$(pwd -P)}`：
  - main、`main/sub/deep`、worktree、symlink、`symlink/sub/deep`、`main/.git` 都得到 main 的實際路徑。
  - 從 `~/project` 捷徑進 claude-dd，得到 `/Volumes/T7/...`。
  - **submodule 得到 `<super>/.git/modules/sm`**。
- `printf '測' | LC_ALL=C sed …` → `---`；換 UTF-8 → `-`。
- 在測試目錄裡放 `app/[id]/page.tsx` 與 `src/x.ts` 兩個檔，用 skill 那條 `find . \( -name node_modules -o -name .git \) -prune -o -path "*/<path>" -print` 查：
  - `app/[id]/page.tsx` → 0 筆
  - `./src/x.ts` → 0 筆
  - `src/x.ts` → 1 筆
- status 第 3 步的 regex 對 `https://example.com/docs/a.md`、`~/.claude/notes.md` 各抽出 `/example.com/docs/a.md`、`/.claude/notes.md`。
- `date -r <file> +%F` 在本機（macOS）→ 2026-11-20，rc 0。

【Critical】
沒有。

【Important】

1. **Important｜status 第 3 步的重算（5453–5455）、promote 第 6 步的重算（5041–5043）會丟掉 fallback 找到的資料夾**
   - 原文：`# A new command starts without Step 1's variables: compute them again.` 底下是同一條公式；promote 也是 `MEMORY_DIR is recomputed because a new command starts without Step 2's variables`。
   - 錯在哪：
     - 第 1 步的 fallback（5404–5408、4946–4947）存在的理由，就是「公式算錯時改用 `find` 找到的那個」。
     - 重算又回到同一條公式，把 fallback 的結果蓋掉。兩處都沒說「第 1 步改用了 fallback 的話，沿用那個路徑」。
   - 失敗情境（兩種實測過的公式失準）：
     - ① `LC_ALL=C`，路徑有中日韓字：`測` 變成 `---`，不是 `-`。
     - ② 在 submodule 裡開：ROOT 是 `super/.git/modules/sm`。
   - 會怎樣：
     - status 第 3 步的 `grep … "$MEMORY_DIR/MEMORY.md"` 讀不到檔，迴圈什麼都不印，Stale 是 0，Capacity 的 stale 那列判成 Healthy。
     - promote 第 6 步的 `grep … 2>/dev/null` 完全沒輸出，agent 會以為找不到要刪的條目，跳過清理或回報「條目不在」。

2. **Important｜review 第 4 步（5307）與 memory-analyst 第 2 步（4291）說的「CLAUDE.md files that load for this project」少列了會載入的檔**
   - 原文：`Read the CLAUDE.md files that load for this project, whichever exist: CLAUDE.md and .claude/CLAUDE.md under the checkout root …, and ~/.claude/CLAUDE.md`
   - 錯在哪：
     - 同一段 diff 的 `docs/measurements/CLAUDE.md`（材料第 335 行）自己寫「同一份檔放到…子目錄當 cwd 就載入了（連同上層目錄的 CLAUDE.md）」。
     - 這次派工的 session 就從 claude-dd 載入了 `my_project/CLAUDE.md` 與 `my_project/.claude/CLAUDE.md`。
     - `CLAUDE.local.md` 也沒列。
   - 失敗情境：在 claude-dd 開 review。某條記憶重述的是 `my_project/CLAUDE.md` 已經寫的規則。
     - review 不會判成「already in」，會把它列成候選。
     - 使用者接著跑 promote，同一條規則就寫進 `claude-dd/CLAUDE.md`，重複一份。

3. **Important｜新加的路徑存在性檢查（4308、5282；diff 第 652、1114 行的 `+` 行）碰到含 `[`…`]` 或 `./` 開頭的路徑會報假 Stale**
   - 原文：`a relative one exists if it is found … (find <root> … -path "*/<path>" -print) … Before searching, drop a trailing "/" … and split a {a,b} shorthand …; find matches neither as written.`
   - 錯在哪：
     - `-path` 把 `[id]` 當成字元集合。
     - `*/./src/x.ts` 永遠不會命中。
     - 實測兩者都 0 筆，而 `src/x.ts` 有 1 筆。
     - 這句列了兩個「find 照寫配不到」的例外，讀起來像只有這兩個。
   - 失敗情境：Next.js 專案的記憶寫 `app/[id]/page.tsx`，或任何寫成 `./src/...` 的路徑。review 與 memory-analyst 會把它列成 Stale；使用者照建議刪掉一條其實還有效的記憶。

4. **Important｜promote 第 3 步決定 rules 檔 `paths` 的新規則（4975–4977）有兩處讀法分歧，而且和同一步的表格衝突**
   - 原文：`take paths from the files or directories the entry says the rule applies to … if the entry names none, write the rule to ./CLAUDE.md instead of a rules file`
   - 衝突一，和表格：
     - 同一步的表格寫 `Applies to specific file types | .claude/rules/<topic>.md | "API handlers need validation"`（4968）。
     - 下方對照表把 `File-type-specific patterns` 放在 rules 欄（5081）。
     - 這兩個例子都沒點名路徑，照新規則一律進 `./CLAUDE.md`，表格那一列永遠用不到。
   - 衝突二，條目點名的是「檔案類型」時，例如「所有 `*.handler.ts`」：
     - 讀法 A：類型不是「files or directories」，所以進 `./CLAUDE.md`。這是乾跑 ⑥ 的結果。
     - 讀法 B：照 `reference/rules-directory-patterns.md` 的 `"**/*.test.ts"` 寫成 glob，建 rules 檔。
   - 這也反駁了 Differences 4005 的「no file in this directory answered them」：rules-directory-patterns.md 有用檔案類型 glob 的寫法。
   - 衝突三，`--target`：使用者明確給了 `--target rules/testing.md`（4924 的用法）、沒給 `--paths`、條目也沒點名路徑時：
     - 讀法 A：這段只在「didn't specify a target」時適用，照使用者指定寫 rules 檔。
     - 讀法 B：「names none → ./CLAUDE.md」照樣適用，使用者指定的目標被改掉。
     - 兩種讀法寫到不同的檔，都不會報錯。

5. **Important｜「Proven 從條目本身判」（4624）和 recurrence 訊號（5276–5278、4302–4304）是兩種讀法**
   - 原文：
     - `Judge "Proven" from what the entry itself records: two or more separate occurrences … An entry that records neither is not proven.`
     - 對照 `Same concept appears multiple times (different wording)`／`Similar entries across topic files`。
   - 失敗情境：三條各記一次的記憶講同一件事。
     - 讀法 A：每條各自沒證明，都不是候選，只列在 Consolidation。
     - 讀法 B：跨條目重複就算兩次以上，列成候選。
   - 候選清單會翻轉。第 4 部分「沒有修、只記錄的含糊處」只列了「同一輪兩次算不算 separate」，沒有這一條。

6. **Important｜CHANGELOG「## 未發布」只記了這段範圍的一部分**
   - 原文：第 13–53 行，整節都是這段 diff 新增的。
   - 抽出未發布那一節 grep，下列都是 0 筆（見 What I ran），兩份紀錄都沒記的：
     - 全域模板，部署後每個專案都會載入：
       - §7.1 第 5 步改成照 §6.1 判斷（1643）。
       - §7.2 第一列由「任何 `.md` 檔」縮成「`CLAUDE.md`」（1650–1651）；刪掉 `優化 skill`（1655–1656）。
       - §7.6 整段改寫（1664–1667）。
       - 三條領域陷阱搬到 dd-loop（1467–1494、410–429）。
       - ⚠️⚠️ 全部收斂。
       - §6.7 新增 docker 例外（1633–1634）。
     - 其他檔：
       - `security-auditor` 換成 OWASP 2025 並重新編號（103–138）。
       - `senior-devops` 的 state backend（150–151）。
       - `code-reviewer` 的 description（90–91）。
       - `dd-init` 刪掉改版考古（163–165）。
       - tech-diagram-gif 硬閘門 3 改成「從一開始就寫在暫存目錄、不刪檔」（1344–1350）。
     - 只記在 Differences、沒進 CHANGELOG 的 self-improving-agent 改動：
       - 2026-11-18 那四筆：remember 第 3 步分索引式／清單式寫入、promote／remember／promotion-rules 的全域規則改寫到模板、Install 段、Copilot 列、兩個 agent 的 frontmatter。
       - memory-architecture 的 25KB／worktree／容量表。
       - review 的「several candidates → list and stop」（Differences 4001 有記，CHANGELOG 第 31–36 行沒有）。
   - 根目錄 `CLAUDE.md:287` 只規定「條目一律寫進 `## 未發布`」，沒規定每項都要有條目，所以這條我判 Important 而不是 Critical。
   - 失敗情境：讀 CHANGELOG 升級的人不知道 §7.2 的觸發範圍縮小了，也不知道 promote 不再寫 `~/.claude/CLAUDE.md`。

【Smells】

- **review 1 對 status（5260、Differences 4001）**
  - 原文：`Several candidates and none clearly this project: list them and stop, as /self-improving-agent:status does.`
  - status（5407–5408）寫的是 `print "Memory directory not found: $MEMORY_DIR" and stop`，沒有說要列出候選。「as status does」對不上。

- **status 4 的方向寫反了（5514）**
  - 原文：`/self-improving-agent:review … may report fewer`
  - status 第 3 步只 grep `MEMORY.md`（5472、5478）。review 把「索引行加主題檔」算一條（5272），主題檔裡的路徑也查。
  - 5438 說索引式才是健康的版面，所以在健康的版面上 review 通常報得更多。

- **200 行／25KB 不一致**
  - memory-architecture 改成「200 lines or 25KB」（716、732）。
  - 下面這幾處仍只寫 200 行：SIA `CLAUDE.md` 3869、`SKILL.md` 4146 與 4171、`README.md` 4045、review 5270、memory-analyst 4286。
  - 另外 diff 第 737 行說「The 200-line target for CLAUDE.md … from the docs」，但它前面那張表沒有任何 CLAUDE.md 的 200 行數字。

- **重複條目的處理不一致**
  - review 第 4 步（5309）：任何和 CLAUDE.md 重複的都建議從記憶刪掉。
  - memory-analyst（4328）：只有 `scores ≥ 6 but is already written` 才建議刪。
  - 分數低的重複條目，兩條流程給的建議不同。

- **memory-analyst 自己寫死門檻**
  - 原文（4327，`+` 行）：`total score ≥ 6 and all four promotion signals above hold`
  - review 5292 才說「do not restate the thresholds from memory」，Differences 3963–3964 也說各檔改成指向 promotion-rules。

- **過期檢查的對象兩邊不一樣**
  - review 寫「tools, versions, or commands」（5283）。
  - memory-analyst 寫「Version numbers」加「removed dependencies」（4309–4310）。
  - CHANGELOG 第 45 行與 Differences 4019 寫「版本、工具、相依套件」，像是兩邊都查三樣。實際上兩邊各少一樣。

- **promote 4977–4979 的清單漏了一處**
  - 原文：`Everything else that asks still asks: [Step 1, Step 2, Step 6, Decision Guide, all-projects]`
  - 清單漏了第 5 步「If file would exceed 200 lines, suggest using `.claude/rules/` instead」（5012）。
  - 同一段又說「do not wait」，這個建議要不要等回答，兩種讀法。

- **找不到 claude-dd checkout**
  - promote 的全域目標（4969、4662、remember 1056）寫「`templates/global/CLAUDE.md` in the claude-dd checkout」。
  - skill 部署在 `~/.claude/skills/self-improving-agent/`，所有檔都沒寫怎麼找到那個 checkout；找不到時怎麼辦也沒寫。

- **Differences 3958 的指標失效**
  - 原文：`(same audit, this commit)`
  - 它後面又加了好幾筆，「this commit」已經指不到。實際是 `6b46c96`（`git log -S`）。

- **「tested 2026-11-19 with `claude -p`」查不到紀錄**
  - 這句出現在 CHANGELOG 第 19 行、Differences 3976、memory-architecture diff 第 721 行，以及五個 skill 的註解。
  - `docs/measurements` 裡沒有對應紀錄（git grep 0 筆）。

- **status 的 stale 列算的是路徑，不是條目**
  - status 的 Stale entries 列（5436、5444）拿第 3 步的輸出來分級，而第 3 步每個路徑印一行。review（5353）說 count 數的是條目。
  - 一條記憶有 4 個失效路徑就會判成 Critical。
  - 同一處，5427（`+` 行）`find "$PROJ/.claude/rules" -maxdepth 1` 數不到子目錄裡的 rules 檔。rules-directory-patterns.md 第 14–16 行的範例就有 `rules/frontend/components.md`。

- **CHANGELOG 第 53 行把只能當跡象的結果寫成定論**
  - 原文：`建訂單連線中斷時兩邊都先查過才重送`
  - 量測檔（材料第 270 行）寫的是「S4 兩臂有效的只有 B 的 1 發，所以 S4 只能當跡象」。縮進 CHANGELOG 時把這個但書拿掉了。

【既有問題】
這幾項的問題行都不在這段 diff 的 `+` 行裡，或是從 `-` 行原樣帶過來的。

- **fallback 本身也受 locale 影響**：fallback 的 `basename … | sed 's/[^a-zA-Z0-9]/-/g'` 在 `LC_ALL=C` 下一樣逐 byte 換（實測 `測` → `---`）。所以它在自己要救的那種情況下也找不到。這是 `-` 行的 `ls -d …*"$(basename … | sed …)"*` 原樣帶來的，`+` 行只把 glob 換成 `find`。
- **status 的路徑 regex**：status 第 3 步的 regex（1283，context 行）把 `~/…` 與 URL 抽成 `/.claude/notes.md`、`/example.com/docs/a.md`（實測）。新的 `case /*` 會把它們當絕對路徑，判成 STALE。review 那邊對 `~/` 是照寫查。
- **SKILL.md 總覽過期**：`SKILL.md:114`（材料 4228）`Entries that recur across sessions (promotion candidates)` 是 context 行。現在的候選判準是「兩次以上的發生或跑過的檢查」，加上分數與排除條件，這句已經對不上。
- **review／memory-analyst 會把條目原文印出來，不遮憑證**：review 範本 `"{{entry}}"`（5335）與 memory-analyst「include … exact text」（4343）都會原樣印。這次只有 promote 加了遮值。

【Not reported】
看過、判定不算的，每條一句理由：

- **githooks 的 tag 說明**：`ls-tree` 證實 v1.6.14 沒有 `claude-md-max-bytes`、v1.6.15 有，說法成立。
- **frontend-design 修改聲明**：`7278dec` 是 2026-06-23，說法成立。
- **PROMOTED_SKILLS**：清單裡有 `self-improving-agent`，說法成立。
- **installer 覆蓋前會備份**：讀了程式碼，說法成立。
- **ROOT 公式在子目錄、worktree、symlink 下都對**：實測過，不另列。
- **`date -r` 在本機能用**：實測 rc 0。
- **lawdesk-ai 專案名進 repo**：repo 裡早就多處出現。
- **tag 驗證本身**：我第一次用 `cat-file -e` 驗 tag 時寫法出錯，以 `ls-tree` 的結果為準。

【需要外部查證】
- **git 版本**：git < 2.31 不認得 `--path-format=absolute`，rev-parse 會輸出什麼，ROOT 會不會變成垃圾字串。要在舊 git（例如 Ubuntu 20.04 的 2.25）跑一次那段公式。
- **submodule 的記憶資料夾**：Claude Code 在 submodule 裡用哪個路徑當記憶資料夾。這決定第 1 條的 submodule 情境是不是真的會發生。
- **上層 CLAUDE.md 與 CLAUDE.local.md**：官方 memory 文件是不是明寫會載入上層目錄的 CLAUDE.md 與 CLAUDE.local.md（第 2 條的佐證，目前用的是本 diff 自己的實測句與這個 session 的載入情形）。
- **memory 文件裡的數字**：code.claude.com/docs/en/memory.md 是否寫 200 行／25KB、4 MiB 會跳過、CLAUDE.md 200 行目標。
- **OWASP Top 10:2025**：正式版的編號與名稱（security-auditor 103–125）。
- **舊版 macOS 的 `date -r`**：`date -r <檔案>` 在舊版 macOS 的行為。

**第 4 部分的驗證沒證明的事**

- **對照組只隔離了最後一個 commit**：對照組是 `b5e9f96`，也就是 HEAD^。新舊比較只隔離了 `c74f115`；`0e3c410`、`9a3e3b2`、`795e100`、`407155c` 對 `1290eb5` 的行為差異沒有比。
- **`grep -cF` 只證明字串在**：只核了 Differences 最後一筆，而且只證明字串存在，不證明語意。CHANGELOG 沒核。
- **status 沒有結果紀錄**：第 7333 行說有對真工作區跑，但第 4 部分沒有任何 status 的預期與結果。
- **remember、extract 沒有乾跑**：remember 第 3 步的索引式／清單式兩條分支、複製 frontmatter，以及 extract 的搜尋，這段範圍都改了，第 4 部分都沒跑。根目錄 `CLAUDE.md` 第 53–54 行規定每條分支各一發。
- **promote 少跑的分支**：給了 `--target`、全域規則（寫模板加先問）、「照樣升級 → 要」、清單式的 `MEMORY.md`、主題檔清空後要不要刪、fallback 路徑。
- **②③④ 分不出有沒有問**：「有沒有問」是 agent 自述。`git status` 空、`diff -rq` 空，和「問了才停」或「沒問就停」都相容，分不出來。
- **⑤ 的「0 個中日韓字」不一定有鑑別力**：只有在來源條目是中文、專案 `CLAUDE.md` 不是中文時，這才證明「照目標檔的語言寫」。這兩個前提沒寫。
- **`claude -p` 量的是 Claude Code，不是 skill 的公式**：記憶資料夾的 `claude -p` 實測量的是 Claude Code 的行為，不是 skill 那條 shell 公式算出同一個路徑。我實跑公式：子目錄、worktree、symlink 都對，submodule 不對。
- **`test-install.sh` 管的是部署**：我沒讀它的內容。照 `tests/CLAUDE.md` 的描述它是安裝測試，不會檢查 skill 文字的對錯。21 個 ✅ 不能拿來支持這段的任何文字宣稱。

## 處置

修正與這份報告在同一個 commit（步驟 6）。編號照「發現」節的順序：Important 是 S1-b-1 到 S1-b-6，Smells 照出現順序是 S1-b-s1 到 S1-b-s12。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-b-1 status 第 3 步、promote 第 6 步的重算會丟掉備援找到的資料夾 | Important | 採納，已修。兩個重算區塊的註解寫明「前面的步驟用了候選的資料夾，就把 `MEMORY_DIR` 設成那個路徑」；步驟 5 乾跑時 remember 的那一發說第 3 步沒有對應的句子，補了一句。乾跑（一個候選的材料）：promote 把條目從候選的 `memory/` 移除、remember 把新主題檔寫在候選的 `memory/`、status 的數字來自候選（9 個主題檔）；三個材料用 `verify.py` 核，公式算的資料夾都沒被建出來。 |
| S1-b-2 「會載入的 CLAUDE.md」少列了檔 | Important | 採納，已修（與 S1-a-3 同一件，處置見 `S1-a.md`）。 |
| S1-b-3 路徑檢查碰到 `[`…`]` 或 `./` 開頭會報假 Stale | Important | 採納，已修（與 S1-a-s6 同一件）。乾跑材料 C：現行版兩發都不把 `app/[id]/page.tsx`、`./src/server.ts` 列成 Stale；`c74f115` 版 review 那一發兩個都列了。 |
| S1-b-4 promote 決定 rules 檔 `paths` 的規則有兩處讀法分歧、和表格衝突 | Important | 採納，已修，三處衝突各一句：①`paths` 取自條目說規則適用的「檔、目錄或檔案樣式」（原本只寫檔或目錄，表格「specific file types」那一列用不到）；②檔案類型照 `reference/rules-directory-patterns.md` 寫成 glob（`*.test.ts` 寫成 `**/*.test.ts`、目錄寫成 `<dir>/**/*`），只是觸發規則的檔不算；③那一段只管「自己挑的目標」，使用者給的 `--target`（和跟著它的 `--paths`）照用（這一句是步驟 5 第二批補的：第一批那一發照用了，但它的報告說文件沒寫）。Differences 的「no file in this directory answered them」前面加了限定（點名別的檔的那幾條除外）。乾跑：條目限定 `tests/api/` 的那一發 `paths` 是 `tests/api/**/*`；`*.test.ts` 的那一發是 `**/*.test.ts`；「改 X 後跑 Y」的那一發寫進 `./CLAUDE.md`；給了 `--target rules/api.md --paths "src/api/**/*.ts"` 的那一發寫出 `.claude/rules/api.md`、`paths` 就是給的那個，依據引的是新加的那句。`*.test.ts` 那一發的 `c74f115` 對照也寫出 `**/*.test.ts`，這一格分不出新舊。使用者給了 `--target` 卻沒給 `--paths` 時 `paths` 寫什麼，仍然沒寫，轉新段落。 |
| S1-b-5 「Proven 從條目本身判」和 recurrence 訊號是兩種讀法 | Important | 採納，已修。`reference/promotion-rules.md` 的 Proven 那句加上「同一個教訓記在好幾條」（指到 review 第 2 步的 recurrence 訊號）。乾跑材料 C：三條各只記一次、講同一件事的條目，現行版 review 與 memory-analyst 都判成候選；`c74f115` 版兩發都判成不是。 |
| S1-b-6 CHANGELOG「未發布」只記了一部分 | Important | 採納，已修（與 S1-c-3、S1-d-1 同一件）：補上 2026-11-18 那幾個 commit 的條目，附 commit hash。 |
| S1-b-s1 review 寫「as status does」 | Smell | 採納，已修（與 S1-a-s2 同一件）。 |
| S1-b-s2 status 寫 review「may report fewer」方向反了 | Smell | 採納，已修（與 S1-a-s5 同一件）。 |
| S1-b-s3 200 行／25KB 不一致 | Smell | 沒改。只講 200 行的那幾處是 2026-11-19 稽核報告標記、交使用者決定的一項（L4）；「沒有任何地方檢查 25KB」轉新段落。 |
| S1-b-s4 重複條目的處理 review 與 memory-analyst 不一致 | Smell | 採納，已修：memory-analyst 改成「已寫進 CLAUDE.md 或 rules/ 的不算候選，不管幾分；建議從記憶移除」。乾跑材料 A：`use-pnpm`（6 分、已寫在專案 `CLAUDE.md`）被判成不是候選並建議移除。 |
| S1-b-s5 memory-analyst 自己寫死門檻 | Smell | 採納，已修：改成指到 Scoring Guide 的「Promote when」門檻。第一批乾跑那一發讀到的是改之前的句子，不算；重跑一發，它的對話紀錄檔裡 `threshold of that Scoring Guide` 出現 2 次，候選是預期的三條。 |
| S1-b-s6 過期檢查的對象兩邊不一樣，紀錄卻寫得像兩邊都查三樣 | Smell | 部分採納：Differences 那句改成分開寫 review 查什麼、memory-analyst 查什麼。兩邊查的對象仍然不同（memory-analyst 沒有「指令」），沒改，轉新段落；步驟 5 的 memory-analyst 那一發也把它列為卡住。 |
| S1-b-s7 promote「其他要問的照問」清單漏了第 5 步 | Smell | 不採納。第 5 步寫的是 suggest（建議改用 rules），不是要等回答的問題。 |
| S1-b-s8 部署後的 skill 找不到 claude-dd checkout | Smell | 屬實，沒改，轉新段落。步驟 5「全專案通用」那一發答「不要」所以沒實際卡住，它把這句列為卡住。 |
| S1-b-s9 Differences 的「this commit」指不到 | Smell | 採納，已修：改成 `6b46c96`。 |
| S1-b-s10 「tested 2026-11-19 with `claude -p`」查不到紀錄 | Smell | 採納，已補（與 S1-d 的同一條 Smell 同一件）：2026-11-20 重量一次，紀錄在 `docs/measurements/2026-11-20-memory-dir.md`（五種位置各一發）。 |
| S1-b-s11 status 的 Stale 列算的是路徑不是條目；rules 只數第一層 | Smell | 屬實，沒改，轉新段落（兩件都是）。 |
| S1-b-s12 CHANGELOG 把只能當跡象的結果寫成定論 | Smell | 採納，已修（與 S1-c 的 Smell 1、S1-d-2 同一件）：CHANGELOG 與量測紀錄的結論都改成只用事先寫下的判定式，那一項標成只能當跡象。 |

既有問題四項都屬實、都沒在這一段改，轉新段落：備援自己在 `LC_ALL=C` 下也逐 byte 換（沒重測）；status 的路徑 regex（與 S1-a-4 同一件，對照見 `S1-a.md`）；`SKILL.md:114` 的總覽句；review 與 memory-analyst 印條目原文時不遮憑證。

Not reported 的各項看過，沒有要翻案的。

需要外部查證：
- git < 2.31：查了，公式算錯。`docs/measurements/2026-11-20-memory-dir.md` 記了 git 2.25.1 下的結果，公式改成不用 `--path-format=absolute`。
- submodule 的記憶資料夾：量了（同一份紀錄），用 submodule 自己的根目錄，公式跟著改。
- 上層的 `CLAUDE.md` 與 `CLAUDE.local.md`：查了 code.claude.com/docs/en/memory.md（2026-11-20），從工作目錄往上每一層都載入。
- memory 文件裡的數字：`reference/memory-architecture.md` 寫明出處是同一頁、2026-11-19 讀的；這一段沒有重讀。
- OWASP Top 10:2025：2026-11-20 對 top10.owasp.org/2025 核過 A01–A10 的名稱。
- 舊版 macOS 的 `date -r`：沒查。

「第 4 部分的驗證沒證明的事」那一節：對照組只隔離最後一個 commit、status 沒有結果紀錄、remember 與 extract 沒乾跑、promote 少跑的分支、「有沒有問」只有自述 —— 都成立。步驟 5 補跑了 status、remember、extract 與 promote 的這些分支（給了 `--target`、全專案通用規則、「照樣升級 → 要」、清單式 `MEMORY.md`、備援路徑），每一發的檔案狀態用指令核；「有沒有問」仍然只有 agent 的報告，沒有別的來源。清單與結果在 `S1-judge.md`。
