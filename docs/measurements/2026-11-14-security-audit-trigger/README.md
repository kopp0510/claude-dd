# security-audit 部署後觸發實測（2026-11-14，Claude Code 2.1.325）

S2 步驟 5：`./install-dd-pipeline.sh --force` 之後，用全新的 `claude -p` session 驗四件事：

1. `/security-audit` 叫得起來，載入的是部署版
2. 不打指令名、只說「做完整安全稽核」時，它不會自己叫起來（`disable-model-invocation: true` 有作用）
3. 沒指定輸出目錄時，預設路徑算得對（D5b）
4. 部署的 `~/.claude/skills/security-audit/CLAUDE.md` 會不會被當成巢狀記憶讀進去（設計文件 A21 ③）

結果都在 `results.txt`（`check.sh` 的輸出）。12 發合計 US$3.09。

## 跑法

`<S>` 是 scratchpad，`<repo>` 是 claude-dd 根目錄。

1. 在 `<repo>` 跑 `./install-dd-pipeline.sh --force`，再跑 `diff -rq skills/security-audit ~/.claude/skills/security-audit`，要沒有輸出
2. 建拋棄式 clone：`git clone -q <repo> <S>/trig/claude-dd && git -C <S>/trig/claude-dd checkout -q dd8b5a9`
   （dd8b5a9 在 S2 之前，clone 裡沒有 `skills/security-audit/`，叫得起來的只有部署版）
3. 建 negctrl 用的副本：`<S>/trig/ctrl-plugin/` 放 `.claude-plugin/plugin.json`（`name` 是 `sa-ctrl`）與 `skills/security-audit/`（從 repo 複製，刪掉 `CLAUDE.md`、用 `sed` 刪掉 `disable-model-invocation: true` 那行）
4. 建 injctrl 用的 repo：`<S>/trig/injctrl/` 跑 `git init`，把 repo 的 `skills/security-audit/` 複製到 `skills/` 底下再 commit
5. 每一臂跑一次 `ARM=<臂> ./run.sh <S>`：`pos`、`posctrl`、`d5b`、`inj`、`injctrl` 用 haiku；`neg`、`negctrl` 用 opus，兩發平行跑
6. 跑 `./check.sh <S> <repo> > results.txt`

`probe-ls`、`probe-ls2`、`inj-1`、`injctrl-1`、`d5b-1` 不是 `run.sh` 現在的臂，是先跑的版本，旗標見下面「結果」。

## 結果

| 臂 | 做什麼 | 判準 | 結果 |
|---|---|---|---|
| pos | `/security-audit` 加「照貼 frontmatter 之後第一個非空行」；只放行 Skill | 回覆含 SKILL.md 第 7 行（A5 加的那行，上游沒有）；沒有工具呼叫；denials 0 | 過：那行出現 1 次、工具呼叫 0、denials 0 |
| posctrl | 同一個 prompt，指令名換成不存在的 | 回覆不含那一行 | 過：0 次，回覆說沒有載入任何 skill |
| neg | 不打指令名，要求「對這個 repo 做完整的安全稽核」；放行 Skill、Read、Glob、Grep | 沒有含 `security-audit` 的 `Launching skill:`；沒有 Read 部署版 skill 目錄；denials 0 | 過：三項都是 0，也沒有叫起 `review`（Skill 呼叫是空的）；session 自己用 Read、Grep 做了稽核 |
| negctrl | 同 neg，另用 `--plugin-dir` 載入沒有 dmi 的副本 | 有含 `security-audit` 的 `Launching skill:` | 過：`Launching skill: sa-ctrl:security-audit`，所以 neg 的 0 有鑑別力 |
| d5b | `/security-audit` 加「只解析 Output directory、印成一行」；放行 Skill、Glob、`Bash(ls:*)`、`Bash(git remote:*)`、`Bash(git rev-parse:*)`，`--add-dir ~/security-audit-skill` | 回覆等於跑之前算的 `~/security-audit-skill/claude-dd/run-2`；session 自己列了那個目錄；denials 0 | 路徑對、有用 Glob 列 `~/security-audit-skill/claude-dd`（`run-*`）；**denials 1，沒過這一項**（見限制） |
| d5b-1 | 同 d5b，但 Bash 只放行 `ls` | 同上 | 同上：路徑對、denials 1 |
| inj | `/security-audit` 加「Read skill 目錄的 HUNTING.md，再照貼 context 裡出現的 CLAUDE.md 路徑與第一行」 | 回覆不提 `skills/security-audit/CLAUDE.md` | 只列出全域 CLAUDE.md 與 clone 根目錄的 CLAUDE.md |
| injctrl | 同樣讀 HUNTING.md，但 skill 目錄放在 cwd 的專案裡 | 回覆提到 `skills/security-audit/CLAUDE.md` | 提到了，第一行 `# skills/security-audit` —— 這種查法在「會載入」時看得到，所以 inj 沒提到有意義 |
| inj-1、injctrl-1 | 第一版：只 Read，再 grep jsonl 有沒有 skill CLAUDE.md 獨有的字串「收錄原則」 | — | 兩臂都 0：stream-json 不記巢狀記憶，這種查法沒有鑑別力，改成上面的自述加對照 |
| probe-ls | 只放行 `Bash(ls:*)`，`ls ~/security-audit-skill/claude-dd/` | — | denials 1：dontAsk 擋 cwd 外的路徑 |
| probe-ls2 | 同上，加 `--add-dir ~/security-audit-skill` | — | denials 0，印出 `run-1`；d5b 因此加了 `--add-dir` |

結論：

- `/security-audit` 叫得起來，不打指令名時不會自己叫
- 預設輸出路徑算得對；session 先試 git 指令查 repo 名，被擋後改讀 `.git/config`
- 部署版的 skill CLAUDE.md 沒有被當成巢狀記憶讀進去（n=1、靠模型自述，有正向對照）

## 限制

- 每臂都只跑一次
- d5b 兩次的 denials 都是同一型：session 把 `git rev-parse`、`git remote`、`echo`、`ls`（第 2 次加上 `basename`）串成一條 Bash，dontAsk 要每一段都在白名單才放行。
  被擋之後它改用 Glob 與 Read `.git/config`，路徑照樣對。判準的「denials 0」沒達到；沒有再放寬旗標重跑
- neg、negctrl 沒有 `<臂>.exit`：兩發在跑的時候 `run.sh` 被改過（加 injctrl 臂）。bash 邊跑邊讀腳本，`claude` 結束後從舊的位置讀到改過的內容，第 28 行語法錯誤，寫 exit 那行沒跑到。
  兩發 `claude` 自己的 result 是 `subtype=success`、`is_error=false`；init 訊息的 cwd 是 clone、工具清單沒有 Bash、Edit、Write、Agent，negctrl 另載入了 `sa-ctrl`。那次改了 d5b 的旗標、新增 injctrl 臂、把 `cd` 改成 `cd "$CWD"`，neg、negctrl 的旗標沒動
- negctrl 同時載入部署的 dmi 版與 plugin 副本，兩臂的載入方式不同
- inj 靠模型自己回報 context 裡有什麼；injctrl 證明它在「有載入」時會報出來，但沒證明它一定報全
- pos 用 slash 叫時，stream-json 沒有 Skill 的 tool_use，也沒有 `Launching skill:` 那行（與試跑的探針相同），所以「叫得起來」是看回覆內容判的
