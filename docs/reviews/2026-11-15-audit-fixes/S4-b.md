# S4 審查 — B（授權與歸屬的宣稱）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S4（vendored 內容：self-improving-agent 死指標與評分表、agents 授權檔）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s4-review-pack.txt`，763 行，沒進 repo）的組成：
- 第 1 部分：`git diff cf6beea HEAD`（表上這段的起點到 HEAD = a2954f7），工作目錄乾淨、沒有未追蹤的檔；`agents/LICENSE.txt` 只放前 40 行，後面 202 行是 Apache-2.0 全文
- 第 2 部分：步驟 3（code-simplifier）沒有跑，這一段的 diff 全是 Markdown 與純文字
- 第 3 部分：`skills/self-improving-agent/` 被改到的四個檔與 `reference/promotion-rules.md` 在派工當下的整檔內容（帶行號）
- 第 4 部分：已跑過的驗證 V1–V6（兩條 grep 驗收、S4-2 的乾跑與預期、與本機官方副本的比對輸出、照 ci.yml 逐 step 跑、CHANGELOG 與 tag 的差異）

派工 prompt（逐字；prompt 裡的暫存目錄絕對路徑在這裡寫成 `<scratchpad>`，審查者拿到的是一句「先讀這個檔再照做」加這個檔的路徑）：

> 你是程式碼審查者。職責：找漏洞、每條附證據；沒證據的不算。不寫優點、不客套。
>
> repo：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。
> 審查範圍：`git diff cf6beea HEAD`（8 步開發迴圈 S4 段落，3 個 commit：14c9e8b、b90303a、a2954f7）。這一段沒有程式碼，改的是文字：
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
> - 不要跑 `./install-dd-pipeline.sh`、不要跑 `claude` 指令、不要改 repo 裡的任何檔、不要 commit。小實驗放在 <scratchpad>/rc4-b/ 底下。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：授權與歸屬的宣稱。`agents/LICENSE.txt` 前 40 行的每一句，逐句對回審查包 V4 的指令輸出，並自己重跑其中至少兩條比對（讀本機官方副本）：講的行數、哪幾行相同、哪幾節是官方沒有的、「不寫它源自哪一份」這些說法，有沒有說得比證據多、或漏掉該講的（例如 `code-reviewer.md` 還跟哪些來源有關：根目錄 README 授權表說它的 Fowler smell baseline 改編自 mattpocock/skills）；附的全文是不是完整的 Apache-2.0。兩份 README 授權表新增的那一列、`DD_PIPELINE_ARCHITECTURE.md` 授權段新增的那一句，三處講的是不是同一件事、跟 `agents/LICENSE.txt` 有沒有出入；表格那一列有沒有把表格弄壞（每一行都以 `|` 開頭）。根目錄 CLAUDE.md「第三方 Skill / Agent 收編檢查清單」的第 1 項（授權相容）與第 7 項（納管要同步哪幾處）、「只借概念、不抄檔案時」那一段的歸屬判準，逐條對這次的做法。`agents/LICENSE.txt` 放在 `agents/` 會不會被安裝腳本部署、會不會被 CI 的陣列一致性或 `~/.claude/` 路徑檢查算進去（讀 `install-dd-pipeline.sh` 的 `install_builtin_agents` 與 `.github/workflows/ci.yml` 對應的 step）。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體情境 → 會錯在哪）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

逐字原文（交回的訊息；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 1 / Smells 2 — 範圍：`git diff cf6beea HEAD` 裡的授權與歸屬宣稱（`agents/LICENSE.txt` 前 40 行、兩份 README 授權表新增的那一列、`DD_PIPELINE_ARCHITECTURE.md` 授權段、根目錄 CLAUDE.md 收編清單 #1 與 #7）
>
> 【發現】
> 1｜Important｜改過的 Apache-2.0 檔 `agents/code-reviewer.md` 檔內沒有「這個檔被改過」的說明。這次 S4-3 宣稱補齊了授權（CHANGELOG 寫「補上授權檔」），只在旁邊另放一份 `agents/LICENSE.txt` 說明它改過。｜`grep -n -i 'mattpocock\|adopted\|fowler\|anthropic\|official\|modified\|changed' agents/code-reviewer.md` 只命中 `:51 ## Fowler Smell Baseline` 與 `:53 ...adopted from mattpocock/skills`。檔內唯一碰到來源的是 frontmatter description 的「官方 code-reviewer plugin 未裝時的本地備份」，只講用途，沒說被改過。`agents/LICENSE.txt:16` 自己寫「code-reviewer.md —— 改過的檔（117 行）」。｜Apache-2.0 §4(b) 要求 "cause any modified files to carry prominent notices stating that You changed the files"。有人只複製 `agents/code-reviewer.md` 這一個檔（這正是 `install_builtin_agents` 部署時做的事，只 `cp` `<名字>.md`）時，手上的檔既沒有授權資訊，也沒有改動說明，收編清單 #1「授權相容」並沒有真的做完。｜在 `code-reviewer.md` 正文開頭或 frontmatter 加一句改動說明，指向 `agents/LICENSE.txt`（例如「Modified from anthropics/claude-plugins-official (Apache-2.0); see agents/LICENSE.txt」）。只放一份同目錄說明夠不夠算 §4(b) 的 notice，是法律判斷，列在下面「需要外部查證」。
> 2｜Smells｜`agents/LICENSE.txt:21` 列「與官方兩份不同的地方」時，frontmatter 只寫了 description。對 feature-dev 那份來說，還漏了 model、color、tools 三處。｜官方 feature-dev 的 frontmatter 是 `tools: Glob, Grep, LS, …`、`model: sonnet`、`color: red`；repo 這份是 `model: opus`、`color: green`，也沒有 tools 行。用 `grep -nxFf` 對 feature-dev 比，相同的只有第 1、2、6 行（`---`、`name`、`---`）。｜讀者照第 21 行會以為 frontmatter 只差 description，這比證據說得少。違反根目錄 CLAUDE.md「只借概念」那一段的判準：「能逐條指出『哪一段來自誰』才算寫對」。｜第 21 行改成：與 feature-dev 那份另外不同在 model、color、tools。
> 3｜Smells｜`agents/LICENSE.txt:20` 說「與官方的兩個同名檔」相同的部分包含「『Output Format』的標題」，但這一行只和 pr-review-toolkit 那份相同。｜對 pr-review-toolkit 比命中第 70 行 `## Output Format`，對 feature-dev 比沒有命中。V4 也記了 feature-dev 那份的標題只有 Review Scope、Core Review Responsibilities、Confidence Scoring、Output Guidance。｜讀者會以為兩份官方檔都有 Output Format，而 13 行與 10 行的差距正好有一部分出在這裡。｜在這一句註明「Output Format 標題只與 pr-review-toolkit 那份相同」。
>
> 【Not reported】
> - `agents/LICENSE.txt:13` 說 code-simplifier.md「逐字相同」：我重跑 `cmp`，結果相同。第 14 行說 pr-review-toolkit 的同名檔內容不同：`cmp -s` 回 rc=1，相符。
> - 第 18–19 行的 13 行（56 行）與 10 行（46 行）：重跑 `grep -cxFf` 相符，`wc -l` 也對得上。117 行相符。
> - 第 21 行的四節（Scope Discipline、Work Order、Fowler、Severity）：對照 V4 的標題清單，官方兩份確實都沒有。
> - 第 22 行的 Fowler 歸屬：`skills/writing-great-skills/LICENSE.txt` 是 MIT、Copyright (c) 2026 Matt Pocock，與 `code-reviewer.md:53` 的 "adopted from mattpocock/skills" 以及兩份 README 第 294／310 行既有的列一致。新增那一列沒有重複寫 Fowler，因為上一列已經寫了，不算漏。
> - 第 23 行「不寫它源自哪一份」：證據只有部分行相同、git 紀錄最早一筆是 279c8a9，這句沒有說得比證據多。
> - 第 10 行的 .gcs-sha：重讀是 b5b01ac…，相符。第 28 行：三個 plugin.json 的 author 都是 Anthropic、沒有 license 欄位；三個目錄裡都沒有 NOTICE。相符。第 29 行的樣板 `Copyright [yyyy]`：官方 LICENSE 第 190 行確實沒填。
> - 附的全文：`tail -n 202 agents/LICENSE.txt | cmp - "$M/LICENSE"` 相同，從開頭的 "Apache License" 到結尾的 "limitations under the License." 都在，是完整的 Apache-2.0。
> - 三處描述（兩份 README 新增列、架構文件新增句、LICENSE.txt）講的是同一件事：逐字相同、改過、只有部分行相同、Apache-2.0，彼此沒有出入。
> - 兩張表格範圍（README.md 第 292–301 行、README.zh-TW.md 第 308–317 行）每一行都以 `|` 開頭，表格沒壞。
> - 收編清單 #7 要求同步的「三處授權段」（兩份 README 與架構文件）都改了，根目錄 CLAUDE.md 目錄結構那行也補了。
> - 部署：`install_builtin_agents` 只複製 `$SCRIPT_DIR/agents/$agent.md`，所以 LICENSE.txt 不會被部署。CI 的陣列一致性用的是 `ls agents/*.md`（ci.yml:79），`.txt` 不算進去。CI 第 144 行抓的「4 個 Agents」字串仍然在。`~/.claude/plugins/...` 路徑的第一層 `plugins/` 是放行的，V5 也已經全綠。
> - `DD_PIPELINE_ARCHITECTURE.md` 沒有提到 Fowler 改編自 mattpocock：這是既有狀態，不是這次 diff 引入的，新增那句也不涉及 Fowler。
> - `~/.claude/agents/` 部署版不附 LICENSE：那是使用者自己從 clone 複製到本機，不算對外散布，不列。
>
> 【What I ran】
> - Read 審查包第 1–763 行（分三次）與 prompt-b.txt。
> - `wc -l agents/LICENSE.txt agents/code-reviewer.md` → 236、117
> - `cmp agents/code-simplifier.md $M/plugins/code-simplifier/agents/code-simplifier.md` → 相同
> - `grep -v '^[[:space:]]*$' agents/code-reviewer.md | grep -nxFf` 分別對 pr-review-toolkit 與 feature-dev → pr 命中 1,2,4,5,6,7,8,9,33,34,35,36,70；fd 命中 1,2,6,7,8,9,33,34,35,36
> - `head -8` 兩份官方 code-reviewer.md 與 repo 這份 → feature-dev 是 model: sonnet、color: red，有 tools 行
> - `tail -n 202 agents/LICENSE.txt | cmp - $M/LICENSE` → 相同；`tail -5` 結尾完整
> - grep code-reviewer.md／code-simplifier.md 有沒有改動說明 → 沒有
> - `head -5 skills/writing-great-skills/LICENSE.txt` → MIT、Matt Pocock；grep mattpocock／fowler 在 README×2、架構文件、CLAUDE.md 的分布
> - 用 python3 讀三個 plugin.json 的 author／license、ls 三個 plugin 目錄、`cat .gcs-sha`、`grep 'Copyright \[yyyy\]' $M/LICENSE` → 第 190 行
> - `cmp -s` pr-review-toolkit 的 code-simplifier.md → rc=1
> - 讀 `install_builtin_agents`（install-dd-pipeline.sh:758 起）；`grep -n 'agents/' .github/workflows/ci.yml` → 第 79、144、292、369 行
> - awk 逐行檢查兩份 README 授權表的範圍 → 表格行都以 `|` 開頭
>
> 【需要外部查證】
> - Apache-2.0 §4(b) 的 "prominent notices"：同目錄另放一份 LICENSE.txt 說明改動算不算，還是一定要寫在被改的檔裡。這需要查 Apache 官方 FAQ（apache.org/legal）或請法務判斷，結果決定發現 1 該維持 Important 還是降級。

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實。`agents/code-reviewer.md` 檔內原本沒有任何一句說它改過；`agents/LICENSE.txt` 附的全文第 4 條 (b) 寫的是「You must cause any modified files to carry prominent notices stating that You changed the files」。
  改法：`agents/code-reviewer.md` 的 frontmatter 之後加一行 HTML 註解，寫明這個檔在本 repo 改過、有一部分行與官方 plugin 的同名檔相同（Apache License 2.0）、細節與授權全文在 `agents/LICENSE.txt`。
  措辭跟 `agents/LICENSE.txt` 一樣，只說改過與部分行相同，不說它源自哪一份。
  放在 body 不放 frontmatter：frontmatter 裡的註解 Claude Code 的 parser 吃不吃，手上沒有證據。
  `agents/code-simplifier.md` 沒有動（`cmp` 與官方副本仍相同）—— 它沒改過，加了反而讓「逐字相同」變成假的。
  沒驗證的三件事：①這一行會進 agent 的 prompt，對審查行為有沒有影響沒有測（註解裡寫了「不是審查指示」）②加了檔內說明之後，授權上夠不夠，沒有人驗證過
  ③「只放同目錄一份說明夠不夠算 (b) 的 notice」沒有去查 —— 加了檔內說明之後這一題不必回答。
  這個檔不在 S4-3 原本的檔案清單，是這一步加的；部署版要等重跑安裝才會有這一行。
- **2（Smells，採納）**、**3（Smells，採納）**：都屬實（兩份官方檔的 frontmatter 與 `## Output Format` 的命中數自己重看過：feature-dev 那份是 `model: sonnet`、`color: red`、有 `tools:`、沒有 `## Output Format`）。
  `agents/LICENSE.txt` 那一段改寫成三類：兩份都相同的、只與 pr-review-toolkit 那份相同的（`model: opus`、`color: green`、「Output Format」標題）、與兩份都不同的。
  加了註解之後重跑檔裡引的指令：`agents/code-reviewer.md` 是 119 行（檔裡的行數跟著改）、兩條 `grep -cxFf` 仍是 13 與 10、`tail -n 202 agents/LICENSE.txt | cmp` 仍相同。
- Not reported：都同意，沒有動作。
