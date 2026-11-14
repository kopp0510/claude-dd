# S2 步驟 4：審查者 A（英文 README 對程式碼）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數）。這一段沒有跑步驟 3 的 code-simplifier（唯一的程式碼改動是 `show_help` 的一行字串）。
給審查者的 prompt 只有一句「完整派工在 `<scratchpad>/imp/review2/prompt-a.txt`，先讀完再照做」加三句防漏；下面是那個檔的全文（路徑已去識別）。
diff 檔 `<scratchpad>/imp/review2/diff.txt`（968 行）的組成：①`git diff 00955e2 HEAD`（HEAD = 44ec47a）②沒有跑步驟 3 的說明
③兩份 README 在 HEAD 的整檔內容 ④已跑過的驗證（本機 CI 20 個 step、`tests/test-install.sh`）與逐句核對表 K1–K13（每列附指令與實際輸出）。

````text
你是 8 步開發迴圈步驟 4 的審查者 A。職責：找漏洞。每一條發現都要附證據（檔案的行、或你實際跑的指令與輸出）；沒有證據的不算。不寫優點。

## 範圍與資料

- 審查範圍：repo <repo> 的 `git diff 00955e2 HEAD`（一個功能段落，1 個 commit：44ec47a）。這一段改的是兩份 README（英文 README.md、繁中 README.zh-TW.md）、CHANGELOG.md、根目錄 CLAUDE.md 的一行、設計文件，以及 install-dd-pipeline.sh 的 show_help 裡一行字串
- diff 檔：<scratchpad>/imp/review2/diff.txt（四部分：整段 diff／步驟 3 的說明／兩份 README 在 HEAD 的整檔內容／已經跑過的核對與驗證）
- **diff 檔用 Read 的 offset／limit 每次 300 行讀到最後一行**。Read 一次讀太多會靜靜截斷、不報錯
- 工作目錄與 HEAD 相同，沒有別的 agent 在改檔：README 以外的檔（install-dd-pipeline.sh、commands/dd-init.md、scripts/、skills/、templates/global/CLAUDE.md、docs/measurements/ 等）直接讀工作目錄
- diff 檔第 4 部分已經跑過、結果已確認，**不要重跑**；但那是寫的人自己做的核對，「核過」不代表對：每一列的指令抓的是不是它聲稱要證明的那件事，請照樣質疑

## 硬性限制

- 不要執行、也不要 source install-dd-pipeline.sh（任何參數都不要）——它會改到真實的 ~/.claude。不要跑 tests/ 底下的測試
- 唯讀：不改 repo 裡任何檔、不 commit、不把報告寫成檔（直接在最終訊息交回完整報告）
- 需要小型重現時，只能在 <scratchpad>/imp/review2/a/ 底下建檔，而且不得呼叫或 source 安裝腳本本體
- 只用手上的資料判斷；需要外部查證的（Claude Code 自己的行為、GitHub runner、別的平台）列出來交回，不要猜
- repo 的 CLAUDE.md 裡寫的 8 步迴圈與報告落地流程由主對話負責，你只做這一次審查

## 這段做了什麼（事實，不含判斷）

兩份 README 同批加了：
- 新小節「What installing changes／安裝會改到什麼」（五條）
- 安裝選項：--force 與 --uninstall 兩行的註解改寫，下面加一段講 --uninstall 移除與留下什麼
- 安裝第 5 步補上設定檔更新不了時的行為與「先登記、再啟用」
- 新小節「What the review step costs／審查那一步要花多少」
- 前置需求補 claude-md-management 的安裝指令
- 「Who it's not for／不適合誰」結尾那句（要翻譯的範圍）與「Why nested CLAUDE.md files」結尾那句（不掛 gate 怎麼做）改寫
另外：show_help 的 --force 說明、根目錄 CLAUDE.md「安裝 / 更新」區塊第一行的註解、CHANGELOG `## 未發布` 的一條

## 你的方向：英文 README 新寫與改寫的每一句 ↔ 程式碼實際行為

把 README.md 這段新增或改寫的句子逐句拆開，每一個事實宣稱都去讀它講的那段程式碼（install-dd-pipeline.sh 的對應函式、commands/dd-init.md、skills/*/hooks/、scripts/check-claude-md.sh、.github/workflows/ci.yml、templates/global/CLAUDE.md）：

1. 宣稱對不對、條件有沒有寫漏（「一律」「只」「不會」「either way」這類全稱最容易錯）
2. 有沒有哪一句在某個安裝模式下不成立（一般安裝、--force、--update、--commands-only、--check、--uninstall、非互動）
3. 同一份 README 裡，新寫的句子跟原本就在的句子有沒有互相矛盾（例如 Upgrading 一節、安裝 7 步的說明、gate 規則那一節、MCP 一節）
4. 安裝腳本的 --help 輸出（show_help）跟 README 的安裝選項說的是不是同一件事

照你平常的報告格式交回（分級、每條附證據與具體情境、Not reported、What I ran）。用繁體中文。
````

## 發現

審查者交回的完整報告（逐字；只把本機路徑換成 `<scratchpad>`、`<repo>`）：

````text
Critical 0 / Important 4 / Smells 0。範圍是 `git diff 00955e2 HEAD`（44ec47a），方向是英文 README 新寫的句子對程式碼實際行為。

[Important] README.md:84「Those hooks stay in place, but the gate script they call is gone, so each commit prints a warning and goes through unchecked」這句在舊版 `/dd-init` 掛的 hook 上不成立。
  Failure：專案是舊版 `/dd-init` 掛的 hook，那一行是單獨的 `"$HOME/.claude/scripts/check-claude-md.sh" || exit 1`，之後沒有重跑 `/dd-init`。這時跑 `--uninstall`，腳本不見，sh 回 127，接著 `|| exit 1`，每次 commit 都被擋，不是「警告後放行」。使用者在自己 hook 裡呼叫 gate、非 0 就讓 hook 失敗的那種寫法也一樣。
  Evidence：commands/dd-init.md:277「舊版沒有防護的寫法（`"$HOME/.claude/scripts/check-claude-md.sh" || exit 1` 單獨一行）順便換成 gate 那行」；:268 是使用者自己 hook 的分支。K7 只核了現行的 gate 那行（:203），沒核舊的寫法。README.md:144 原本就有同型的宣稱（「When the gate script is missing … it only warns」），新句把它延伸到 uninstall 情境。

[Important] README.md:84「That last part needs `jq` or `python3` and a file that parses; otherwise it prints what to remove by hand」：jq 與 python3 都沒有時，印出來的只講 settings.json，沒講 installed_plugins.json。
  Failure：機器上沒有 jq 也沒有 python3，跑 `--uninstall`，照印出的訊息手動清。`installed_plugins.json` 裡的 `claude-md-management@…`、`skill-creator@…` 兩筆登記會留著。
  Evidence：install-dd-pipeline.sh `uninstall()` 內 `缺少 jq 與 python3，跳過 Plugin 設定清理（請手動移除 settings.json 的 enabledPlugins 項目）`（K6 第 65 行），訊息裡沒有 installed_plugins.json。解析失敗那條路徑（K6 第 77、87 行）兩個檔都有講。

[Important] README.md:84「It does not touch your global `CLAUDE.md`」這句屬實，但沒交代後果；同一段對 hook 有交代後果，對它沒有。
  Failure：uninstall 之後全域模板還在，§3.9 仍要求「段落開始前先記起點：`~/.claude/scripts/check-claude-md.sh --start-segment`，印出「段落起點：…」才算記好」，步驟 3、4、8 前也仍要求呼叫 Skill `dd-loop`。這兩個都已刪除，於是每個段落都會卡在找不到腳本、叫不到 skill。
  Evidence：`uninstall()` 對 `DD_SCRIPTS`、`ALL_SKILLS` 執行 `rm`（K6 第 41–52 行）；templates/global/CLAUDE.md §3.9 的「段落開始前先記起點」與「先呼叫 Skill `dd-loop`」兩句。

[Important] README.md:19 列出「要翻的不只全域模板」的清單，漏了 agent 的 description。
  Failure：照這份清單翻譯的人不會去翻 agents/。4 個 agent 裡有 3 個的 description 是中文，而 description 同樣決定 agent 會不會被派到；英文需求可能對不上。
  Evidence：`grep -m1 '^description:' agents/*.md` 的結果：code-reviewer、security-auditor、senior-devops 是中文，只有 code-simplifier 是英文。

What I ran
- Read prompt-a.txt（1–39 行）→ 派工內容
- Read diff.txt 第 1–250、250–539、842–968 行 → diff、HEAD 的 README.md、K1–K13
- `sed -n` install-dd-pipeline.sh 的 170–305（ask/backup/json_edit/show_help）、306–374（check_environment）、523–648（skills/agents）、760–1333（plugins/commands/scripts/styles/uninstall/global CLAUDE.md/completion）、1334–1451（main）→ 上列各條的依據
- `grep -n FORCE install-dd-pipeline.sh` → `FORCE` 除了改印出的字樣，只影響全域 CLAUDE.md；`--update` 會把它設成 true
- `cat` skills/self-improving-agent/hooks/{hooks.json,error-capture.sh}、skills/gate-guard/hooks/hooks.json，`ls -a` 兩個 skill 目錄 → 兩支 hook 的時機與 README 相符，比對的是輸出文字（`error:`、`failed` 都在比對清單裡），兩個 skill 都有 `.claude-plugin/`
- `sed -n 264,330p` 與 `grep -n check-claude-md.sh commands/dd-init.md` → 舊 hook 寫法、Phase 5 的 commit
- `grep` skills/dd-loop/SKILL.md 的「不派」「最少 3」，`sed -n 300,380p` docs/measurements/2026-10-23-reviewer-real-sessions.md → 費用那一節的數字與 A 組那一列相符
- `grep runs-on/tests` .github/workflows/ci.yml → ubuntu 與 macOS（`/bin/bash`）都跑三支測試
- `grep -n start-segment scripts/check-claude-md.sh` → 沒掛 hook 時不會擋 commit
- `grep description` agents/*.md、`head` output-styles/adhd.md → agent description 的語言

Not reported：
- `--force` 加 `--commands-only` 時不碰全域 CLAUDE.md，--help 和 README 沒寫這個例外。實際上不會有人這樣組合，所以沒報。
- 版本警告只在 `claude --version` 解析得了時才出現，而且它講的是 opt-in 功能，不是最低支援版本。README 那句字面上沒錯。
- 安裝時會刪掉自己的同名舊指令 `dd-help/dd-docs/dd-revise/dd-status/dd-stop`（會先備份），「What installing changes」沒提到。這是 diff 之外既有的行為。
- `--uninstall` 刪 skill、agent 前不備份，也會在不備份的情況下重寫 settings.json 的排版。這是既有行為，新句沒有說反。
- 兩件要外部查證、我沒查：skills 目錄的 hook 刪掉之後，執行中的 session 是否到重開才失效；Claude Code 是否真的會載入 self-improving-agent 的 hooks.json（gate-guard 有 2026-09-30 的實測紀錄，這一支我只看到它有 `.claude-plugin/`）。
- 繁中 README 只看了 diff 片段，沒有逐句比對。
````

## 處置

- **`--uninstall` 之後「hook 只警告、放行」在舊版 hook 上不成立**（Important）→ 採納。自己核：`git tag --contains edb6b96` 最早是 v1.3.0；前一個 tag 的 `commands/dd-init.md` 沒有「gate 沒執行」那句、掛的是單獨一行 `… || exit 1`。
  README 的 `--uninstall` 段落改寫成條列：v1.3.0 起的 hook 印警告後放行；更早的寫法或使用者自己呼叫 gate 的 hook 會讓每次 commit 失敗，要把那一行拿掉
- **沒有 jq 與 python3 時，手動清理的提示只講 `settings.json`**（Important）→ 採納，改的是安裝腳本那句訊息（補上 `installed_plugins.json`）。T9 加 (e)：把 jq 與 python3 都當成不存在跑 `uninstall`，斷言提示講到這個檔；改之前紅、改之後綠
- **「不動全域 `CLAUDE.md`」沒交代後果**（Important）→ 採納。README 補上：那份如果是這個 repo 的模板，仍會要求呼叫 `dd-loop` 與執行 gate 腳本，而兩者已被移除，要自己換掉或刪掉
- **要翻譯的範圍漏了 agent 的 description**（Important）→ 採納。自己核：4 個 agent 裡 code-reviewer、security-auditor、senior-devops 的 description 是中文。兩份 README 那句改成「大部分 skill 與 agent 的 description」
- Not reported 的「安裝會刪掉舊指令檔，README 沒提」：審查者 C 列為 Important，已補（見 S2-c）
- Not reported 的兩件外部查證（skill 目錄的 hook 刪掉後執行中的 session 何時失效；Claude Code 會不會載入 self-improving-agent 的 hooks.json）：前者沒查；後者這個 session 自己就一直收到那支 hook 插的提醒，至少這台機器上會載入
