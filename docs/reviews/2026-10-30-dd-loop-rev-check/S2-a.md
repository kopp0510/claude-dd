# S2-a — 審查者 A（~/.claude/ 死指標檢查）

## 派工

> 你是 code-reviewer，代號 A。審查範圍：git diff 2aeeacc 80236ec（claude-dd repo，/Users/danlio/project/my_project/claude-dd）。新增一個 CI step：掃部署內容裡的 ~/.claude/ 路徑，指向本 repo 不部署的地方、或部署目錄裡 repo 沒有的檔，就紅燈；同批把根 CLAUDE.md 那條「cherry-pick 後自己 grep」改成指向這道檢查，補 DD_PIPELINE_ARCHITECTURE.md CI 防線表、CHANGELOG、進度表 S2。
> 
> 材料：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/dp-diff.txt。用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷）。被改到的檔用 git show 80236ec:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。材料 ④ 的驗證已確認，不要重跑。
> 
> 你的方向：新 CI step 的 bash 邏輯：regex 會漏掉哪些寫法（例如 "$HOME"/.claude、~/.claude 不帶斜線、反斜線跳脫、Windows 路徑）；loc 擷取、rel 清理（去 </...、去尾端句點）會不會把真的死指標洗成合法；case 判定順序與 glob（scripts/*[!h] 這組）在 bash 3.2 與 ubuntu bash 的行為；佔位跳過條件會不會讓真的死指標溜過；skills/、agents/、commands/、output-styles/ 只驗「repo 有這個檔」是否等於「部署後有」（讀 install-dd-pipeline.sh 的部署函式確認，例如 skill 子目錄是不是整包複製、commands 有沒有 NS 目錄）；set -e 下有沒有指令回非 0 靜默中止
> 
> 職責：找漏洞，每條附證據（路徑:行號、原文、或指令與輸出），沒證據不算。只用手上的資料判斷；需要外部查證的列出來交回。不要改檔、不要 commit。可以在 scratchpad（/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad）建拋棄式檔案做小實驗，不要動 repo。
> 
> 輸出格式：第一行「Critical N / Important N / Smells N」；## Findings（每條 [級別] 路徑:行｜一句話；證據；失敗情境）；## Not reported（看到但不報的與理由）；## What I ran；## 需要外部查證。

## 發現

Critical 0 / Important 3 / Smells 0 — 審查範圍：git diff 2aeeacc 80236ec，重點看新 CI step「部署內容裡的 ~/.claude/ 路徑要指得到東西」

## Findings

[Important] .github/workflows/ci.yml:新 step 的 grep 那行（`[A-Za-z0-9_./<>*{}-]*`）｜路徑裡出現非 ASCII 字元時，regex 會在那個字元前截斷。截斷後剩 `skills/`、`scripts/` 這種部署目錄本身，`-e` 一定成立，真的死指標就這樣過了。
  證據：從 `git show 80236ec:.github/workflows/ci.yml` 抽出 step，只把掃描對象換成拋棄式輸入檔，用 /bin/bash -e 跑。輸入「用途見 ~/.claude/skills/舊名稱/SKILL.md」抓出來的是 `~/.claude/skills/`，沒有任何 ❌，exit 0。
  失敗情境：本 repo 的文件是中文，skill 改名、或寫中文佔位的指標（例如 `~/.claude/scripts/某支.sh`）會全部漏掉。根 CLAUDE.md 新寫的「是部署目錄的話 repo 裡對應的檔要存在」碰到這類路徑就不成立。`$var` 形式的路徑也一樣（`~/.claude/scripts/${name}.sh` 被截成 `scripts/`）。這個可以算刻意當佔位放過，但文件沒寫。

[Important] .github/workflows/ci.yml:新 step 的 `if [ ! -e "$rel" ]`｜「repo 有這個檔」不等於「部署後有」。output-styles/ 和 commands/ 部署的是陣列裡列的檔，不是整個目錄。
  證據：install-dd-pipeline.sh 的 `create_output_styles()` 只跑 `for s in "${DD_OUTPUT_STYLES[@]}"`（陣列裡只有 `adhd.md`）；`create_commands()` 只複製 `DD_COMMANDS` 的 `.md` 和 `NS_COMMANDS` 的目錄。`git ls-files output-styles` 會列出 `output-styles/LICENSE.txt`。實驗輸入「見 ~/.claude/output-styles/LICENSE.txt」→ 沒有 ❌，exit 0。
  失敗情境：指向 `~/.claude/output-styles/LICENSE.txt` 會放行，但部署後那個檔不存在。以後在 commands/ 加 CLAUDE.md 或 README 也一樣：CI 的陣列一致性只掃 `commands/dd-*.md`，所以這種檔不會被那道擋。現在只有 skills/（`cp -r` 整包複製）和 agents/（陣列一致性有擋）兩層，「repo 有」才等於「部署有」。scripts/ 已經有特例處理，output-styles/ 和 commands/ 沒有。

[Important] .github/workflows/ci.yml:新 step 的 grep 那行｜regex 抓不到 `"$HOME"/.claude/...` 這種引號寫法，整行都不會進掃描清單。
  證據：實驗輸入「見 "$HOME"/.claude/rules/docfile.md」→ 輸出檔裡沒有這一行，step exit 0。這是 shell 常見寫法（`cat "$HOME"/.claude/rules/x.md`）。現在 repo 裡有 0 筆（`git grep -nE '"\$HOME"/\.claude'` 在七個掃描目錄都回空）。
  失敗情境：本次事件的原型（指向 rules/）只要寫成這種引號形式就會漏。根 CLAUDE.md 寫「掃…裡的 `~/.claude/`、`$HOME/.claude/`」，讀的人會以為 shell 寫法都涵蓋到了。

## Not reported
- 第一層本身就是佔位時（例如 `~/.claude/<category>/x`、`~/.claude/{skills,agents}/`）會走到 `*)` 分支紅燈（實驗確認）。這是誤報、不會漏，現在也是 0 筆，文件也寫了「只驗第一層」，所以不報。
- `~/.claude/skills/ghost<br>` 這種路徑緊接 HTML 標籤（非 `</`）的寫法，會被 `*'<'*` 當成佔位跳過。現在沒有實例，觸發也太刻意。
- `scripts/*[!h]|scripts/*[!s]h|scripts/*[!.]sh` 這組，我用 `scripts/sh`、`scripts/.sh`、`scripts/x.sh/`、`.sh.bak` 逐一推過：前兩個會落到 `-e` 紅燈，後兩個被 glob 擋下。bash 3.2 與 5 在 case 的 `[!x]` 和 `*` 跨 `/` 上行為一樣，沒發現問題。
- 有 `set -e`：`[ $fail -eq 0 ] && echo` 在 && 串列裡，`grep … || true`，`$(printf|sed)` 回 0，沒有會靜默中止的指令。
- loc 的擷取與 `${HOME}` 和 `$HOME` 兩種前綴的剝除：看過，沒問題。
- 範圍外的既有問題：`create_commands()` 註解寫「README.md 不部署」，但 `cp -r "$source_dir"` 會把它一起複製。這次 diff 沒動到這裡，而且 commands/workflow-review/ 目前也沒有 README.md。

## What I ran
- `git diff --stat 2aeeacc 80236ec` → 5 個檔，+60/-3
- `sed -n` 讀 install-dd-pipeline.sh 的 install_builtin_skills / install_builtin_agents / create_commands / create_scripts / create_output_styles 與陣列定義 → skills 用 `cp -r` 整包複製；output-styles 與 scripts 照陣列逐檔複製
- `git ls-files agents commands output-styles scripts` → 列出 output-styles/LICENSE.txt、scripts/CLAUDE.md、scripts/githooks/pre-commit
- 在七個掃描目錄跑 `git grep -nE '\.claude/' … | grep -vE '(~|\$HOME|\$\{HOME\})/\.claude/'` → 只剩專案相對的 `.claude/rules/` 和 tests 的 `$SANDBOX/.claude`，都不是 ~ 路徑
- `git grep -nE '"\$HOME"/\.claude|CLAUDE_CONFIG_DIR|…'` → 0 筆
- 在七個掃描目錄跑 `git grep -noE <step 的 regex>` → 66 筆，第一層分佈和派工材料 ④ 一致
- 實驗：把 step 從 80236ec 的 ci.yml 抽到 /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/A-step.sh，掃描對象換成同一目錄下的 A-input.txt（6 行），在 repo 根目錄 `/bin/bash -e` 跑 → 只有 `<category>` 那行 ❌，exit 1。中文 skill 路徑、`${name}.sh`、output-styles/LICENSE.txt、`ghost<br>` 都放行；`"$HOME"/.claude` 沒進輸出檔

## 需要外部查證
- 這道 step 跑的 job 是不是只在 ubuntu-latest（ci.yml 第 12 行是 ubuntu-latest；我沒逐一確認 step 屬於哪個 job、有沒有 macOS matrix）。要確認時讀 80236ec:.github/workflows/ci.yml 的 jobs 結構。這會決定 git grep -E 跑的是 glibc 還是 BSD 的 regex 實作；`\{` 在兩邊都當字面大括號，我推論不影響結果，但沒在 ubuntu 上實跑。

## 處置

見 `S2-judge.md` 的「處置」。
