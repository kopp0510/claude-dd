# S2-c — 審查者 C（~/.claude/ 死指標檢查）

## 派工

> 你是 code-reviewer，代號 C。審查範圍：git diff 2aeeacc 80236ec（claude-dd repo，/Users/danlio/project/my_project/claude-dd）。新增一個 CI step：掃部署內容裡的 ~/.claude/ 路徑，指向本 repo 不部署的地方、或部署目錄裡 repo 沒有的檔，就紅燈；同批把根 CLAUDE.md 那條「cherry-pick 後自己 grep」改成指向這道檢查，補 DD_PIPELINE_ARCHITECTURE.md CI 防線表、CHANGELOG、進度表 S2。
> 
> 材料：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/dp-diff.txt。用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷）。被改到的檔用 git show 80236ec:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。材料 ④ 的驗證已確認，不要重跑。
> 
> 你的方向：同步點與誤報風險：repo 裡還有誰寫著「cherry-pick 後要自己 grep ~/.claude/」或描述 CI 防線、掃描範圍（git grep）；「新增 ci.yml 檢查 step 必做負面測試、同批補 CI 防線表」有沒有照做；現在被判合法的 66 筆裡，有沒有其實是死指標而被放過的（逐一查：例如 skills/self-improving-agent/hooks/error-capture.sh、agents/code-simplifier.md 在 repo 裡存在嗎、真的會被部署嗎）；進度表 S2 列與「段落與小任務」是否照 skills/task-planner/SKILL.md「進度表格式」
> 
> 職責：找漏洞，每條附證據（路徑:行號、原文、或指令與輸出），沒證據不算。只用手上的資料判斷；需要外部查證的列出來交回。不要改檔、不要 commit。可以在 scratchpad（/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad）建拋棄式檔案做小實驗，不要動 repo。
> 
> 輸出格式：第一行「Critical N / Important N / Smells N」；## Findings（每條 [級別] 路徑:行｜一句話；證據；失敗情境）；## Not reported（看到但不報的與理由）；## What I ran；## 需要外部查證。

## 發現

Critical 0 / Important 1 / Smells 0 — git diff 2aeeacc 80236ec（ci.yml 新 step、根 CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、CHANGELOG、設計文件 S2）

## Findings

[Important] .github/workflows/ci.yml:396（80236ec 版本；diff 檔第 37–45 行）｜「部署後是否存在」只對 `scripts/` 做了 repo 與部署不是一比一的特判。`output-styles/`、`commands/` 也不是整個目錄照搬，但 step 拿 `[ -e "$rel" ]` 檢查 repo 裡的檔就放行。
- 證據：
  - `output-styles/LICENSE.txt` 在 repo 裡（`git ls-tree -r --name-only 80236ec output-styles/` 回 `output-styles/LICENSE.txt`、`adhd.md`）。但 `create_output_styles()` 只複製 `DD_OUTPUT_STYLES`，也就是只有 `adhd.md`（install-dd-pipeline.sh:1016-1040、92-94），根 CLAUDE.md「目錄結構」也寫明 LICENSE.txt「不部署」。
  - 命名空間 commands 複製完會 `rm -f "$target_dir/README.md"`（install-dd-pipeline.sh:961-962），tests/test-install.sh:42 也斷言它不存在。
- 失敗情境：部署內容裡寫「授權見 `~/.claude/output-styles/LICENSE.txt`」，或寫 `~/.claude/commands/workflow-review/README.md`（repo 裡補了這個 README 之後），step 判為存在、顯示綠燈，使用者機器上卻是死指標。這正是 step 註解自己點名的那類錯（「repo 裡有、部署後沒有」），只是只修了 scripts/ 那一處。
- 文件端也一樣：根 CLAUDE.md:191-193 寫「是部署目錄的話 repo 裡對應的檔要存在（`scripts/` 只認第一層的 `.sh`）」，接著列出「它管不到的」兩種，但沒列「佔位寫法只驗第一層」（防線表那列有寫），也沒列上面這類不部署的檔。照 CLAUDE.md 讀的人會以為這兩種都被擋。

## Not reported
- 現在判為合法的 66 筆逐一核過，都不是死指標：
  - 部署目錄底下有具體路徑的那幾筆，repo 裡都有對應的檔：`agents/code-simplifier.md`、`skills/self-improving-agent/hooks/error-capture.sh`、`skills/self-improving-agent/agents/skill-extractor.md`、`skills/tech-diagram-gif/scripts/verify-geometry.py`、`skills/gate-guard/hooks/guard-no-verify.sh`、`skills/task-planner/SKILL.md`。
  - 它們都會被部署：skills 是整個目錄 `cp -r`（install-dd-pipeline.sh:520/527）；skills/ 底下 12 個目錄都在 `PROMOTED_SKILLS` 裡；agents/ 的 4 個 `.md` 都在 `PROMOTED_AGENTS` 裡。
  - 其餘是 `CLAUDE.md`、`projects/…`、`settings.json`，以及裸的 `~/.claude/`（4 筆，其中 2 筆是 SVG 的 `</text>` 被去掉後的結果）。
- regex 漏掉的寫法也查過：`"$HOME"/.claude`、`CLAUDE_DIR`、`/Users/x/.claude`、`~/.claude` 後面不接 `/`，在掃描範圍裡都是 0 筆。沒被抓到的 `.claude/` 都是專案相對路徑（`.claude/rules/`）或 tests 裡的 `$SANDBOX/.claude/…`，本來就不該抓。
- 同步點：全 repo 已經沒有「cherry-pick 後自己 `git grep '~/\.claude/'`」的舊說法殘留。README 兩份、UPGRADING、scripts/CLAUDE.md、tests/CLAUDE.md 都沒提這件事。CI 防線表已補一列，也沒有其他寫死的 CI step 數要同步。
- 負面測試：材料 ④ 已列 12 種變異加「掃描範圍全錯」，照規定做了，我沒重跑。
- 進度表 S2：格式符合 task-planner「進度表格式」。
  - commits 欄是 `2aeeacc..`，與 `--segment-base` 輸出 `2aeeaccb…` 一致。
  - `IN_PROGRESS` 跟第一個小任務 S2-1 一起 commit，符合「這些改動跟第一個小任務的 commit 一起送」。
  - 「段落與小任務」有 S2-1 條目，含檔案、驗證、commit 訊息，commit 訊息有帶 `（S2-1）`。
- 根 CLAUDE.md 的白名單括號少列 `settings.local.json` 與裸 `~/.claude/`：括號是舉例，不算錯。

## What I ran
- `git grep -noE '<step 同一個 regex>' 80236ec -- scripts/ tests/ commands/ skills/ agents/ output-styles/ templates/ | wc -l` → 66（與 ④ 相同）；同一指令列出第一層與出處 → 分布如上
- `git cat-file -e 80236ec:<6 個被引用的部署檔>` → 全部 OK
- `sed -n 36,100p / 495,535p / 925,965p / 1016,1040p install-dd-pipeline.sh` → 部署陣列；skills 整目錄 cp；NS commands 刪 README.md；output-styles 只複製陣列內的檔
- `git cat-file -e 80236ec:{skills,agents,commands,output-styles}/CLAUDE.md, output-styles/LICENSE.txt, commands/workflow-review/README.md` → 只有 output-styles/LICENSE.txt 存在
- `git grep -nE '\.claude(/|\b)' … | grep -v '<step regex 前綴>'` → 只剩專案相對路徑與 `$SANDBOX/.claude`
- `git grep -nE '"\$HOME"/\.claude|CLAUDE_(DIR|HOME|CONFIG_DIR)|/Users/[a-z]+/\.claude|~/\.claude[^/]'` → 0
- `git grep -nE "git grep -n '~/|cherry-pick" 80236ec`、`'CI 防線|[0-9]+ 道'` → 只命中本 diff 的檔與歷史報告
- `sed -n 119,185p skills/task-planner/SKILL.md` 與 `git show 80236ec:docs/designs/2026-10-30-dd-loop-rev-check-design.md` → 對照格式
- `scripts/check-claude-md.sh --segment-base` → 2aeeaccb999704fffa2d53673ed82f457da72b82

## 需要外部查證
- 無。（CI 實際在 ubuntu runner 上跑出綠燈，要等 push 才看得到；step 在 lint job，runs-on ubuntu-latest，ci.yml:12）

## 處置

見 `S2-judge.md` 的「處置」。
