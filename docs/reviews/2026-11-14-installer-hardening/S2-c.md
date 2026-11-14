# S2 步驟 4：審查者 C（該寫沒寫與過期的敘述）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數）。這一段沒有跑步驟 3 的 code-simplifier（唯一的程式碼改動是 `show_help` 的一行字串）。
給審查者的 prompt 只有一句「完整派工在 `<scratchpad>/imp/review2/prompt-c.txt`，先讀完再照做」加三句防漏；下面是那個檔的全文（路徑已去識別）。
diff 檔 `<scratchpad>/imp/review2/diff.txt`（968 行）的組成：①`git diff 00955e2 HEAD`（HEAD = 44ec47a）②沒有跑步驟 3 的說明
③兩份 README 在 HEAD 的整檔內容 ④已跑過的驗證（本機 CI 20 個 step、`tests/test-install.sh`）與逐句核對表 K1–K13（每列附指令與實際輸出）。

````text
你是 8 步開發迴圈步驟 4 的審查者 C。職責：找漏洞。每一條發現都要附證據（檔案的行、或你實際跑的指令與輸出）；沒有證據的不算。不寫優點。

## 範圍與資料

- 審查範圍：repo <repo> 的 `git diff 00955e2 HEAD`（一個功能段落，1 個 commit：44ec47a）。這一段改的是兩份 README（英文 README.md、繁中 README.zh-TW.md）、CHANGELOG.md、根目錄 CLAUDE.md 的一行、設計文件，以及 install-dd-pipeline.sh 的 show_help 裡一行字串
- diff 檔：<scratchpad>/imp/review2/diff.txt（四部分：整段 diff／步驟 3 的說明／兩份 README 在 HEAD 的整檔內容／已經跑過的核對與驗證）
- **diff 檔用 Read 的 offset／limit 每次 300 行讀到最後一行**。Read 一次讀太多會靜靜截斷、不報錯
- 工作目錄與 HEAD 相同，沒有別的 agent 在改檔：README 以外的檔（install-dd-pipeline.sh、commands/dd-init.md、scripts/、skills/、templates/global/CLAUDE.md、docs/measurements/ 等）直接讀工作目錄
- diff 檔第 4 部分已經跑過、結果已確認，**不要重跑**；但那是寫的人自己做的核對，「核過」不代表對：每一列的指令抓的是不是它聲稱要證明的那件事，請照樣質疑

## 硬性限制

- 不要執行、也不要 source install-dd-pipeline.sh（任何參數都不要）——它會改到真實的 ~/.claude。不要跑 tests/ 底下的測試
- 唯讀：不改 repo 裡任何檔、不 commit、不把報告寫成檔（直接在最終訊息交回完整報告）
- 需要小型重現時，只能在 <scratchpad>/imp/review2/c/ 底下建檔，而且不得呼叫或 source 安裝腳本本體
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

## 你的方向：該寫沒寫的，以及因這段而過期的

這一段的目的是讓一個只讀 README 的陌生人，在安裝之前就知道會發生什麼。請從安裝腳本與 /dd-init 實際做的事往回找：

1. 逐個讀 install-dd-pipeline.sh 的 main() 會呼叫的函式與 uninstall()，以及 commands/dd-init.md 的各 Phase：有哪些會改到使用者機器或專案的行為（寫檔、刪檔、改設定、commit、掛 hook、覆蓋、備份），README（HEAD 版）從頭到尾都沒講、或講得跟實際不一樣。只報「裝之前應該知道」的，不報實作細節
2. 這段新寫的內容讓 README 別處、README.zh-TW.md 別處、DD_PIPELINE_ARCHITECTURE.md、UPGRADING.md、根目錄 CLAUDE.md 的哪些既有句子變成過期或互相矛盾（用 git grep 找還在講 --force、--uninstall、備份、hook、語言、費用、平台的敘述）
3. 新寫的句子有沒有可能誤觸 .github/workflows/ci.yml 的檢查（數字宣稱一致性、安裝 flag 三方對照、迴圈步數四方一致與第五方）—— 本機已跑過全綠（第 4 部分 V1），請看的是「檢查的正規式會不會把新句子裡的數字或箭頭算進去而剛好沒紅」這種
4. 第 4 部分的逐句核對表：有沒有哪一列的指令其實證明不了它標題講的那件事

照你平常的報告格式交回（分級、每條附證據、Not reported、What I ran）。用繁體中文。
````

## 發現

審查者交回的完整報告（逐字；只把本機路徑換成 `<scratchpad>`、`<repo>`）：

````text
Critical 0 / Important 6 / Smells 0 — 範圍：`git diff 00955e2 HEAD`（44ec47a；兩份 README、CHANGELOG、根目錄 CLAUDE.md、設計文件、show_help 一行）

[Important] README.md:84、README.zh-TW.md:85 寫「hook 還在、gate 腳本刪了，之後每次 commit 只印一行警告、照樣放行」，這句只對 v1.3.0 起蓋的 hook 成立。
  Failure：一個用 v1.2.0 以前的 `/dd-init` 掛過 hook、之後沒重跑的專案，hook 裡是沒有防護的 `"$HOME/.claude/scripts/check-claude-md.sh" || exit 1`。`--uninstall` 刪掉腳本之後，sh 回 127，接著 `exit 1`，每次 commit 都被擋，不是放行。
  Evidence：`git show edb6b96^:commands/dd-init.md` 第 146 行就是那個沒防護的寫法；有防護的寫法最早出現在 edb6b96／be3087e（2026-10-01），最早收進它的 tag 是 v1.3.0；CHANGELOG.md:665–666 自己寫著「解除安裝 claude-dd 之後，原本每次 commit 都會因為找不到腳本而失敗」；commands/dd-init.md:277 也承認舊寫法還存在。核對表 K7 只 grep 了現行那一種寫法，證明不了這句話。

[Important] README.md:66、README.zh-TW.md:67 說安裝會換掉「跟 repo 同名、內容不同」的檔，但沒講安裝也會刪掉 repo 裡沒有的檔。
  Failure：使用者自己有 `~/.claude/commands/dd-status.md`（或 dd-help、dd-docs、dd-revise、dd-stop），跑一次安裝（帶不帶 `--force` 都一樣）就被刪了，只留備份。這不是「同名換新」，README 也完全沒提。
  Evidence：install-dd-pipeline.sh:929 有 `local deprecated_dd=("dd-help" "dd-docs" "dd-revise" "dd-status" "dd-stop")`，後面接 `backup_before_overwrite` 再 `rm`。核對表 K1 自己數到 create_commands 裡「3 處備份」，第三處就是這段刪除，但結論沒寫進去。

[Important] 這段把 `--force` 改寫成「只多了不問就覆蓋全域 CLAUDE.md」（README.md:67/77、show_help），結果既有那些「缺腳本就跑 `--force`」的提示，叫人用了一個唯一作用跟目的無關、而且會覆蓋檔案的旗標；其中一處還跟新寫的前置需求矛盾。
  Failure：使用者照 `/dd-init` 的提示跑 `./install-dd-pipeline.sh --force` 去補 gate 腳本或 plugin，他客製過的全域 CLAUDE.md 不問就被覆蓋（有備份）。commands/dd-init.md:303 的「`--force`（腳本會裝）」也跟 README.md:38 的「it never downloads one」對不上：claude-md-management 不在磁碟上時，跑 `--force` 什麼都裝不起來。
  Evidence：`grep -n -- '--force'` 找到的有 commands/dd-init.md:86、101、206、209、303，scripts/dd-init-upgrade.sh:157、159、217，skills/dd-loop/SKILL.md:20。install_plugins 遇到 plugin.json 不存在時只印「Plugin 檔案不存在」然後 `continue`（install-dd-pipeline.sh 的 install_plugins 內）。

[Important] 新寫的 `--uninstall` 段落（README.md:84、zh:85）說它也會把使用者自己先裝的 plugin 取消登記，但另外三處還寫「只移除本 repo 部署過的項目」，跟這段互相矛盾。
  Failure：讀 `--help` 或架構文件的人會以為使用者自己裝的 claude-md-management／skill-creator 不受影響，實際上兩個都會從 enabledPlugins 與 installed_plugins.json 拿掉。
  Evidence：DD_PIPELINE_ARCHITECTURE.md:78 寫「`--uninstall` 只移除本 repo 部署過的項目」；install-dd-pipeline.sh:287 是 show_help 的 `移除 DD Pipeline（本 repo 部署過的項目）`；README.md:80 的註解是「remove what this repo deployed」。uninstall() 不管 plugin 是誰裝的，一律對 OFFICIAL_PLUGINS 做 `del(.enabledPlugins[$key])`／`del(.plugins[$key])`。

[Important] README.md:137、zh:140 的「US$5.13／269 秒」漏了量測檔自己寫的兩個前提，數字看起來比實際穩、也比實際低。
  Failure：讀者把 5.13 美元當成一次審查的大概花費，但量測檔說費用是從父 log 最後一筆 result 取的，「最後一輪不一定記進去，會偏低」；而且這組對照用的是 S4 凍結的小 diff（第一段 G2 1–203 行、G3 1–249 行），每個審查者只花 139–226 秒，同一份檔另一組真實 session 的審查者中位數是 11.8 分鐘。
  Evidence：docs/measurements/2026-10-23-reviewer-real-sessions.md 的「原始數字」段（「費用取父 log 最後一筆 result…會偏低（S4 同一種算法）」）、「diff 檔讀了多少」段（G2 1–203、G3 1–249 行），以及表裡「審查者層最慢」那欄 142／139／171／226s。核對表 K8 只核了 5.13 與 269 這兩個數字，沒核這兩條限制。

[Important] README.md:19、zh:20 列「換語言要翻哪些」，漏了 agent 的 description。
  Failure：照這份清單翻譯的人會留下 3 個中文的 agent description（code-reviewer、senior-devops、security-auditor）。它們跟 skill description 一樣，是用來判斷要不要派這個 agent 的依據，清單卻只列了 skill。
  Evidence：`grep -n '^description' agents/*.md`：senior-devops、code-reviewer、security-auditor 是中文，只有 code-simplifier 是英文。

What I ran
- `wc -l` 加 Read diff.txt（每次 300 行，讀了 1–968 行） → 讀完
- `sed -n` install-dd-pipeline.sh 的 170–280、306–374、523–648、760–1333、1334–1451 行 → 讀了 helper、check_environment、各個 install／create 函式、uninstall、create_global_claude_md、show_completion、main
- Read commands/dd-init.md 的 1–127、186–380 行 → Phase 0–6
- `git grep -n -- '--force' …`（文件、commands、skills、scripts、templates） → 找到上面第 3 條列的那些位置
- `git log -S'if [ -x "$HOME/.claude/scripts/check-claude-md.sh" ]' -- commands/dd-init.md`、`git tag --contains` → edb6b96／be3087e，最早在 v1.3.0
- `git show edb6b96^:commands/dd-init.md | grep -n check-claude-md.sh` → 第 146 行是沒防護的寫法
- `sed -n 655,675p CHANGELOG.md` → 第 665–666 行
- `find skills -name hooks.json` 加 cat → 只有兩個 hook（gate-guard 是 PreToolUse、self-improving-agent 是 PostToolUse，matcher 都是 Bash）
- `sed -n 60,124p` error-capture.sh → 樣式清單裡有 `error:`、`failed`
- `grep` ci.yml 的 job、step 與測試呼叫 → ubuntu 與 macOS 兩個 job 都跑 tests/*.sh；`sed -n 99,172p`、`239,265p` → 數字宣稱與 flag 檢查的正規式都不會吃到這段的新句子
- `sed`／`grep` 量測檔的 83–123、279–373 行 → 上面第 5 條
- `grep` skills/dd-loop/SKILL.md 的 50–95 行 → 步驟 4 派工的規則
- `grep -n '^description' agents/*.md` → 上面第 6 條
- `sed -n 1,90p` DD_PIPELINE_ARCHITECTURE.md、`sed -n 1,60p` UPGRADING.md → 架構文件第 78 行

Not reported
- 既有問題、不在這段 diff 裡：uninstall 會 `rm -rf ~/.claude/templates/dd`，不備份（它自己的確認提示有列出來）；uninstall 不會把安裝時備份走的同名原檔放回去（`review`、`frontend-design` 這類通用名字的 skill，解除安裝後原本那份只剩在 backups 裡）；「先登記再啟用，所以登記失敗不會留下已啟用的 plugin」不涵蓋「本來就已經啟用」的情況。
- 需要外部查證（我沒查）：
  1. plugin 只在 marketplaces 目錄裡、cache 裡沒有時，安裝腳本登記的 `installPath` 指到不存在的目錄，Claude Code 會壞掉還是自己修好？這決定 README.md:38 新加的「claude-md-management isn't on disk」判準對那類使用者有沒有用。
  2. Claude Code 會不會把 `gate-guard@skills-dir` 這類鍵寫進 settings.json？uninstall 不清它。
  3. 2.1.154 以外，skill 目錄裡的 hook 能自動載入，要求的最低版本是多少？
- CI 方向（第 3 項）沒有找到會被新句子誤觸、而剛好沒紅的地方。
````

## 處置

- **`--uninstall` 之後「hook 只警告、放行」**（Important）→ 採納，與 S2-a 第一條同一件事
- **安裝會刪掉 repo 裡已經沒有的舊指令檔，README 沒提**（Important）→ 採納。「安裝會改到什麼」第一條補上那幾個檔名、會先備份、使用者自己同名的檔也會被刪
- **`--force` 改寫之後，別處「缺腳本就跑 `--force`」的提示變得奇怪**（Important）→ 部分採納：
  - 採納的：`--help` 與兩份 README 的 `--force` 說明改成「例行更新用：同一般安裝，另外全域 CLAUDE.md 不問直接覆蓋」，跟 README「Upgrading」一節講的例行更新（`git pull && ./install-dd-pipeline.sh --force`）對得上
  - 不改的：`commands/dd-init.md`、`scripts/dd-init-upgrade.sh`、`skills/dd-loop/SKILL.md` 那幾處提示。它們叫人做的就是文件定義的例行更新，會覆蓋全域 CLAUDE.md 這件事 README 的 Upgrading 一節已經警告、而且有備份；
    改這三個檔要照專案規定另外做沙盒乾跑，不在這一段（純 README）的範圍
  - 另記一件既有的不準：`commands/dd-init.md` Phase 4 寫「`--force`（腳本會裝）」，但安裝腳本只登記已經在磁碟上的 plugin、不會下載。寫進設計文件的「已知、這次沒處理」
- **另外三處還寫「只移除本 repo 部署過的項目」**（Important）→ 採納。架構文件那句、`--help` 的 `--uninstall` 說明、兩份 README 的註解都改成「移除本 repo 部署的檔案，並取消登記官方 plugin」
- **5.13 美元漏了兩個前提**（Important）→ 採納，與 S2-b 第三條同一件事
- **要翻譯的範圍漏了 agent 的 description**（Important）→ 採納，與 S2-a 第四條同一件事
- Not reported 的「uninstall 不會把安裝時換掉的同名檔放回去」：採納（順手補），README 與架構文件都加一句
- Not reported 的「先登記再啟用不涵蓋本來就已啟用的情況」：採納（順手改），那句改成「登記失敗時不會接著去啟用它」
- Not reported 的三件外部查證（`installPath` 指到不存在的目錄時 Claude Code 怎麼處理、`gate-guard@skills-dir` 這類鍵會不會被寫進 settings.json、skill 目錄的 hook 自動載入要的最低版本）：都沒查，列在設計文件
