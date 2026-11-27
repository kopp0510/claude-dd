# S4 審查 — C（文件之間的一致與規則遵守）

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
> - 不要跑 `./install-dd-pipeline.sh`、不要跑 `claude` 指令、不要改 repo 裡的任何檔、不要 commit。小實驗放在 <scratchpad>/rc4-c/ 底下。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：文件之間的一致與規則遵守。`CHANGELOG.md` `## 未發布` 新增的三條：每一句對不對得上實際的 diff 與審查包的驗證輸出（例如「新版 2／2／2 = 6、舊版 3／2／3 = 8」）；放的小節對不對；有沒有動到已發布的區塊。根目錄 `CLAUDE.md` 改的那一行對不對（`agents/` 那一行；CI 的「數字宣稱一致性」讀的是這一行的哪些字）。`docs/designs/2026-11-15-audit-fixes-design.md` 的 S4 那幾段（開工前提的結果、S4-2 乾跑結果、進度表 S4 那一列）對不對得上實際做的事，跟同一份文件的假設 A1、A10、A11 與 S4-1／S4-2／S4-3 的小任務描述有沒有出入（計畫寫了要做而沒做的、做了而計畫沒寫的，都列出來）。根目錄與各層 CLAUDE.md 規定「同批要改」「手動同步」的地方有沒有漏（搜「同批」「同步」「手動同步」「授權」，逐條對這次的改動：改了 vendored skill 的內容、新增一個授權檔、動到 CHANGELOG）。全 repo 還有沒有別處提到被改掉的東西而沒跟著改（例如別的文件引用 self-improving-agent 的評分方式、Codex／OpenClaw 支援、或說「agents 沒有授權檔」「code-reviewer 是官方備份」這類句子；`git grep` 找）。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體情境 → 會錯在哪）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

逐字原文（交回的訊息；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 1 / Smells 3 — `git diff 5d9d68b HEAD`（S4：90cfe4c、0d2125d、6ea3552）裡文件之間對不對得上、有沒有照規則同步
>
> 【發現】
> 1｜Important｜評分改動的行為變化寫得不完整：CHANGELOG 與 skill 的 CLAUDE.md 都只寫 Scope 從 3 變 2，但 Durability、Impact 的評法也一起變了。拿來舉例的 8 → 6 有 1 分不是 Scope 造成的，而且 6 分沒有跌破門檻｜`CHANGELOG.md:136`「⚠️ 行為改變：整個專案適用的條目 Scope 從 3 變 2，總分可能跌破「≥ 6 才建議升級」的門檻（同一條記憶乾跑：新版 2／2／2 = 6、舊版 3／2／3 = 8）。」；`skills/self-improving-agent/CLAUDE.md:91-92`「This changes results: a project-wide entry scores Scope 2 instead of 3」。舊版 `git show 5d9d68b:skills/self-improving-agent/agents/memory-analyst.md` 的 Durability／Impact 只有一句問句（「Will this still be true in a month?」），沒有刻度；新版改照 promotion-rules.md 的表打分。設計文件 `docs/designs/2026-11-15-audit-fixes-design.md:180` 自己寫了「Durability 差的 1 分是舊版沒有刻度、它自己說是猜的」，CHANGELOG 把這句限定拿掉了｜讀 CHANGELOG 的人會以為一條記憶因為這次改動少 2 分，或以為只有 Scope 會變。之後有人回報「Durability 分數跟以前不一樣」，查 CLAUDE.md 的「Differences from upstream」查不到這一項。另外舉的例子是 6，仍然 ≥ 6，示範不出「跌破門檻」｜CHANGELOG 補半句「Durability、Impact 也改照表上的刻度打分（舊版沒有刻度）；例子裡 Scope 的定義只造成 1 分差距」。CLAUDE.md 的 Differences 那條也補上 Durability／Impact
>
> 2｜Smells｜`agents/LICENSE.txt` 有一句說「根目錄 CLAUDE.md 列為自製」，但根目錄 CLAUDE.md 沒有點名說這兩個 agent 是自製｜`agents/LICENSE.txt:4-5`「另外兩個（senior-devops.md、security-auditor.md）根目錄 CLAUDE.md 列為自製」；`CLAUDE.md:41` 只寫「+ senior-devops、security-auditor」，沒有標「自製」。`CLAUDE.md:113`「自製 agent 用 `inherit`」只能間接推出這件事；`install-dd-pipeline.sh:60` 把它們寫成「實證用過」｜這個檔自稱「只寫查得到的事實」，有人照指標去 CLAUDE.md 找「列為自製」那一句會找不到｜改成「不在本檔範圍（它們不是官方 plugin 的檔）」，或改寫成指到 `CLAUDE.md` 的「新增 Agent 步驟」第 1 步
>
> 3｜Smells｜授權檔那條 CHANGELOG 放在 `### Fixed`，前例是放 `### Added`｜這次的三條在 `## 未發布` 的 `### Fixed` 底下（`CHANGELOG.md:65` 起，條目在 :133–:141）。前例：1.6.13 的 output-styles 與它的 `LICENSE.txt` 記在 `### Added`（`CHANGELOG.md:203`、`:210`）｜看 Added 找「這版新增了哪些檔」的人會漏看 `agents/LICENSE.txt`｜不急；要對齊前例就把那條移到 `### Added`
>
> 4｜Smells｜計畫與實際做的不完全一樣：S4-3 的檔案清單沒有根目錄 `CLAUDE.md`，實際上改了｜`docs/designs/2026-11-15-audit-fixes-design.md:184` S4-3 的「檔案：」只列 `agents/LICENSE.txt`、兩份 README、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md`；`git show --stat 6ea3552` 多了 `CLAUDE.md | 2 +-`｜改的內容本身沒問題（「目錄結構」本來就要記這類檔，前例是 `output-styles/LICENSE.txt` 那行）。只是接手的人拿計畫對 commit 時會對不上｜步驟 8 或標 DONE 時在 S4-3 的檔案清單補上 `CLAUDE.md`
>
> 【Not reported】
> - CHANGELOG 其他句子都對得上 diff：舊版的 Scope 定義（3／1／0）、Scoring Guide（0／1／2／3）、「`./scripts/` 不在這個目錄」（`ls skills/self-improving-agent` 沒有 scripts）、`clawhub publish` 那兩處還在（`SKILL.md:126`、`skills/extract/SKILL.md:153`）、「這個檔不部署」（`install_builtin_agents` 只複製 `agents/$agent.md`）。三條都在 `## 未發布` 底下，已發布的區塊沒動（`git diff v1.6.14 -- CHANGELOG.md` 沒有任何刪除行）
> - 根目錄 `CLAUDE.md:41`：CI 的 `grep -oE "agents/\` — [0-9]+ 個 Agents"`（`ci.yml:144`）只讀「4 個 Agents」這幾個字，加在分號後面的內容不影響比對
> - 兩份 README 的授權表、`DD_PIPELINE_ARCHITECTURE.md` 的授權段都加了 `agents/LICENSE.txt`，中英兩份內容一致，有照收編清單第 7 條（「三處授權段」）做
> - 開工前提的結果：`git show 5d9d68b:skills/self-improving-agent/CLAUDE.md | grep '上游\|差異\|upstream'` rc=1，跟設計文件寫的「0 筆」一致。開工前提的結果跟第一個小任務的 commit（90cfe4c）一起送，照規則
> - 進度表 S4 是 `IN_PROGRESS`、commits 欄是 `5d9d68b..`：現在在步驟 4，還不到標 DONE 的時候，這個狀態是對的
> - A1（`clawhub publish` 不動）、A10（code-reviewer 寫明是改過的檔）、A11（Scope 3 變 2）都照做了。A11 本身也只寫了 Scope（理由同發現 1），沒有另外列
> - `skills/self-improving-agent/settings.json:8` 仍然列 `openclaw`、`codex`：這次 diff 已經在 CLAUDE.md:86-87 寫明刻意保留，A1 也沒要求改
> - `CLAUDE.md:113`「官方備份維持上游的 `opus`」：官方 feature-dev 版的 code-reviewer 是 `sonnet`、pr-review-toolkit 版是 `opus`。這句是既有的，這次 diff 沒動
> - `agents/code-reviewer.md` 的 description 仍寫「官方 code-reviewer plugin 未裝時的本地備份」，跟 LICENSE.txt 說它是「改過的檔」語氣不同。這是既有的說法，而且「備份」指的是用途、不是內容相同，不算矛盾
> - 全 repo 用 `git grep` 找 openclaw／codex：除了 CHANGELOG、設計文件、settings.json（見上）以外，只有 `skills/writing-great-skills/SKILL.md:7`，那是別的 skill 的 codex 檔，跟這次無關。沒有別的文件引用 memory-analyst 的評分方式
> - `skills/self-improving-agent/hooks/CLAUDE.md:38` 的「同批」規則管的是 hook 的行為，這次沒動 hook
>
> 【What I ran】
> - Read 審查包 1–763 行（分三次讀）、`prompt-c.txt`
> - `sed -n 1,30p`、`sed -n 160,200p`、`sed -n 36,50p docs/designs/2026-11-15-audit-fixes-design.md` → 讀了假設 A1–A13、進度表規則、S4 那一節
> - `grep -n` CHANGELOG 的標題與 LICENSE、`git tag` → 最新 tag 是 v1.6.14；未發布的 Added 在 :21、Changed 在 :45、Fixed 在 :65；1.6.13 的 Added 在 :203
> - `grep -n agents .github/workflows/ci.yml` → :144 的正規式
> - `git grep -n -i 'openclaw\|codex'`、`git grep -n '官方備份|本地備份…'`、`git grep -n '自製'`、`git grep -n LICENSE` 掃 README、架構文件、CLAUDE.md、UPGRADING → 結果見上
> - `git show --stat` 看 3 個 commit；`git show 5d9d68b:` 看舊版 CLAUDE.md（grep rc=1）與舊版 memory-analyst.md 46–53 行
> - `grep -c '' agents/code-reviewer.md` → 117；`git diff v1.6.14 -- CHANGELOG.md | grep '^-'` → 0
> - `grep '^model'` agents 與官方副本 → feature-dev 的 code-reviewer 是 sonnet，其他是 opus
> - `head -12 agents/senior-devops.md agents/security-auditor.md`；`ls agents skills/self-improving-agent`；install-dd-pipeline.sh 的 `install_builtin_agents` 段
>
> 【需要外部查證】
> 無

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實。舊版的 Durability、Impact 各只有一句問句、沒有刻度；我在 CHANGELOG 與 skill 的 CLAUDE.md 都只寫了 Scope，例子 8 → 6 也沒有跌破門檻。
  拿判準掃（`git grep -nE 'Scope' -- . ':!docs/reviews' | grep -E '3 ?(分)?(變|降|→|to|instead)|2 instead of 3|從 3'`）共四處：
  `CHANGELOG.md` 與 `skills/self-improving-agent/CLAUDE.md` 改寫（三項都會變；Scope「單檔」也從 1 變 0；總分可能升也可能降；例子照實寫 8 → 6、仍達門檻、差的 2 分各是哪一項）；
  設計文件的假設 A11 與「採納的小事」那一行是審過的計畫紀錄，沒有改寫，改在 S4-2 底下補一條更正。
- **2（Smells，採納）**：屬實，根目錄 CLAUDE.md 沒有哪一句點名這兩個 agent 是自製。`agents/LICENSE.txt` 改成「不是官方 plugin 的檔，不在這個檔的範圍」。
- **3（Smells，採納）**：授權檔那一條從 `### Fixed` 移到 `### Added`（新增的檔）。它引的前例位置不對：`CHANGELOG.md` 提到 `output-styles/LICENSE.txt` 的那一條在 `## 1.6.11` 的 `### Added` 底下，不是 1.6.13，
  而且那一條講的是整個 output style、順帶提到授權檔；移過去的理由是「新增的檔放 Added」，不是那個前例。
- **4（Smells，採納）**：設計文件 S4-3 的檔案清單補上根目錄 `CLAUDE.md`，與審查後才加的 `agents/code-reviewer.md`。
- Not reported 裡一條既有的句子記在這裡：根目錄 CLAUDE.md「新增 Agent 步驟」寫官方備份「維持上游的 `opus`」，官方 feature-dev 版的 code-reviewer 是 `sonnet`。這次 diff 沒動那一句；步驟 8 審根目錄 CLAUDE.md 時處理。
- 其餘 Not reported：都同意，沒有動作。
