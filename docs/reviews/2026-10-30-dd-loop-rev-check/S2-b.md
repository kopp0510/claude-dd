# S2-b — 審查者 B（~/.claude/ 死指標檢查）

## 派工

> 你是 code-reviewer，代號 B。審查範圍：git diff 2aeeacc 80236ec（claude-dd repo，/Users/danlio/project/my_project/claude-dd）。新增一個 CI step：掃部署內容裡的 ~/.claude/ 路徑，指向本 repo 不部署的地方、或部署目錄裡 repo 沒有的檔，就紅燈；同批把根 CLAUDE.md 那條「cherry-pick 後自己 grep」改成指向這道檢查，補 DD_PIPELINE_ARCHITECTURE.md CI 防線表、CHANGELOG、進度表 S2。
> 
> 材料：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/dp-diff.txt。用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷）。被改到的檔用 git show 80236ec:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。材料 ④ 的驗證已確認，不要重跑。
> 
> 你的方向：根 CLAUDE.md 那條改寫：拿材料 ③ 舊版逐句對新版，找出被拿掉或改寬改窄的條件、出處、指令；新句「它管不到的」兩項是否屬實且完整（例如 CLAUDE.md 自己、README、docs/ 不在掃描範圍）；CHANGELOG 條目與 DD_PIPELINE_ARCHITECTURE.md 新列是否描述了 step 的實際行為（讀 ci.yml 新 step 逐句對）
> 
> 職責：找漏洞，每條附證據（路徑:行號、原文、或指令與輸出），沒證據不算。只用手上的資料判斷；需要外部查證的列出來交回。不要改檔、不要 commit。可以在 scratchpad（/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad）建拋棄式檔案做小實驗，不要動 repo。
> 
> 輸出格式：第一行「Critical N / Important N / Smells N」；## Findings（每條 [級別] 路徑:行｜一句話；證據；失敗情境）；## Not reported（看到但不報的與理由）；## What I ran；## 需要外部查證。

## 發現

Critical 0 / Important 1 / Smells 0 — 審查範圍 git diff 2aeeacc 80236ec（根 CLAUDE.md 改寫、CHANGELOG 條目、DD_PIPELINE_ARCHITECTURE.md 新列，逐句對照 ci.yml 新 step）

## Findings

[Important] CLAUDE.md:192-193（80236ec 版，即 diff 的新行「它管不到的：在這些目錄**以外**的路徑，以及指向本機其他地方（不在 `~/.claude/` 底下）的死指標 —— 那兩種還是要自己顧」）｜「管不到」只列兩項，讀起來像其他情況 CI 都會擋。實際上掃描範圍**之內**還有五類會直接綠燈放過。CHANGELOG:23-24 寫「指向本 repo 不部署的地方…就紅燈」，同樣說得比實際寬。
- 證據：我把 80236ec 的 tree `git archive` 到 scratchpad，抽出 step 的 run 段（路徑檔改寫到 scratchpad），每次在 `scripts/check-claude-md.sh` 尾端附加一行註解，用 `/bin/bash -e` 跑：
  - `~/.claude/output-styles/LICENSE.txt` → exit 0 ✅。step 只用 `[ -e "$rel" ]` 檢查檔案在 repo 裡存不存在。但安裝腳本只部署 `DD_OUTPUT_STYLES`（install-dd-pipeline.sh:92-94 只有 `adhd.md`），根 CLAUDE.md 自己也寫 LICENSE.txt「不部署」。所以「repo 有、部署後沒有」這類，在 scripts/ 以外的部署目錄都驗不到。
  - `~/.claude/projects/-Users-x%2Fproj/memory/MEMORY.md` → exit 0 ✅。`projects` 落在 `continue` 那個 case（ci.yml 新 step `''|CLAUDE.md|settings.json|settings.local.json|projects|plugins) continue`），後面的路徑完全不驗。根 CLAUDE.md 收編清單 #3 記的 self-improving-agent「`%2F` 編碼算出的記憶體目錄從來不存在」正是這一類，CI 擋不到。
  - `~/.claude/plugins/nope/x` → exit 0 ✅，理由同上。
  - `~/.claude/skills/<名字>/SKILLL.md` → exit 0 ✅。只要含佔位符號就只驗第一層，佔位符號後面的拼錯驗不到。這條豁免 ARCH 那列有寫，CLAUDE.md 新句沒寫。
  - `~/.claude/scripts/中文.sh` → exit 0 ✅。regex 的字元集 `[A-Za-z0-9_./<>*{}-]` 遇到非 ASCII 就截斷，rel 只剩 `scripts/`，被當成目錄放過。`"$HOME"/.claude/rules/x.md`（HOME 加引號的寫法）→ exit 0、筆數 66，regex 根本沒抓到這筆。
  - 另外，舊規則的標題是「它指向的檔在這裡存不存在」，也包含相對 repo 的指標（例如指到只存在別的 branch 的 `docs/…` 檔）。這種既不在 `~/.claude/` 底下，也不算新句說的「本機其他地方」，新句的兩項都沒涵蓋它。
- 失敗情境：下一次 cherry-pick 帶進 `~/.claude/projects/<錯的編碼>/…`，或是指向 output-styles/LICENSE.txt 這類「repo 有、不部署」的檔，CI 全綠。讀者看了 CLAUDE.md 會以為「只有那兩種要自己顧」，就不會再 grep。舊句附的 `git grep` 指令也被拿掉了，連自己顧的工具都沒留下。

## Not reported
- CLAUDE.md 新句列的寫法是「`~/.claude/`、`$HOME/.claude/`」，少了 regex 也有抓的 `${HOME}`。列的 Claude Code 自有項目少了 `settings.local.json` 和裸的 `~/.claude/`。這兩處都是少列「會放過」的東西，不會讓人因此誤判成紅燈，影響輕微。
- ARCH 那列說佔位寫法是「`<名字>`、`*`」，step 實際還豁免 `{` 和 `...`。這是少列，沒有說錯行為。
- ARCH 新列其他敘述（第一層判定、`scripts/` 只認第一層 `.sh`、零命中紅燈）逐句對過 step，都正確。
- 已有的變異驗證（材料 ④）沒重跑。

## What I ran
- `wc -l` + Read dp-diff.txt（162 行，全部讀完）→ 讀完
- `grep -nE '^(PROMOTED_|DD_|NS_|BUILTIN)'`、`sed -n 86,96p / 1020,1050p / 930,960p install-dd-pipeline.sh` → 確認 output-styles 只部署 DD_OUTPUT_STYLES（adhd.md）
- `git show 80236ec:.github/workflows/ci.yml > scratchpad/B-ci.yml` → 取得新 step
- 在 80236ec 上 `git grep -noE <step 的 regex>`，統計第一層分佈 → 和材料 ④ 一致
- 在 80236ec 上 `git grep -nE '\.claude/'` 排除 regex 能抓到的寫法 → 剩下的都是專案相對的 `.claude/rules/`（self-improving-agent），不是 home 路徑
- 在 scratchpad/B-exp（git archive 80236ec）用 `/bin/bash -e step.sh` 跑 7 個變異 → output-styles/LICENSE.txt、projects/%2F、plugins/nope、`<名字>`/SKILLL.md、scripts/中文.sh、"$HOME"/.claude/rules 都是 exit 0；commands/workflow-review/NOPE.md 是 exit 1（對照組）

## 需要外部查證
- 無

## 處置

見 `S2-judge.md` 的「處置」。
