# S1-d（審查者 D：模型層實驗）— /dd-stop 指令、腳本與 gate 的暫停旗標

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-17），在步驟 3（code-simplifier）做完、還沒 commit 的時候。
Agent 呼叫的 prompt 只有「你的完整派工內容在這個檔，先用 Read 把它整份讀完，然後照它做」加檔案路徑，另寫明代號是 S1-d、報告用純文字照四個標題交回、不要寫成檔案。那個檔的內容如下
（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是這一段程式碼變更的審查者 S1-d。職責只有一個：找漏洞。每一條發現都要附證據（`檔案路徑` 加上你讀到的原文，或你實跑的指令與輸出）；沒有證據的不算、不要寫。不寫優點、不客套。
>
> repo：<repo>（規則在根目錄與各層 CLAUDE.md，跟你方向有關的那幾份要讀）。
> 這一段做的事：新增 `/dd-stop on|off|status` 指令 —— 暫停與恢復一個專案的 8 步開發迴圈（步驟 3–8）與 CLAUDE.md pre-commit gate。設計、使用者的決定（U1–U3）在 docs/designs/2026-11-17-dd-stop-design.md。
>
> 審查材料在這個檔：<scratchpad>/rev/S1-diff.txt（共 2153 行，最後一行是 `<<<材料結束>>>`）。
> - 用 Read 的 offset／limit 每次 300 行，讀到看見最後那一行為止（Read 一次讀太多會靜靜截斷、不報錯）。跟你方向無關的檔的 diff 可以掃過，但整份都要翻到。
> - 材料裡有 5 行超過 2000 字元（都是 CLAUDE.md 的表格列），Read 會截斷；要看那幾行就讀工作目錄的原檔。
> - 新增的檔看材料裡那一份；既有而被改到的檔要看上下文時讀工作目錄（審查期間沒有人在改）。
> - 材料第 ④ 節列的驗證已經跑過、結果已確認，不要重跑整支測試。「跑過」不代表測試寫得對 —— 測試本身也在審查範圍。
> - 你可以在 scratchpad 開拋棄式 git repo 做小實驗來證實某一條（目錄放 <scratchpad>/rev/S1-d/ 底下）。用 `/bin/bash <腳本>` 跑，不要在 zsh 裡 `source` repo 的任何腳本（`source ./install-dd-pipeline.sh` 會真的把安裝跑起來）。不要跑 `./install-dd-pipeline.sh`、不要跑 `claude -p`、不要碰真的 `~/.claude/`、不要改 repo 裡任何檔、不要 commit。
> - 只用手上的資料判斷；需要外部查證（上網、官方文件、別台機器）的列在「需要外部查證」交回，不要自己猜。
>
> 你的方向：`docs/measurements/2026-11-17-dd-stop/` 的實驗站不站得住：`run-model.sh`、`check-model.sh`、`selftest-model.sh`、`probe-local.sh`，以及 `out/model-1/` 的資料（六個 `.json`、`check.out`、兩份 prompt；用 `jq` 讀）與同目錄 `CLAUDE.md`「結果」一節、`docs/designs/2026-11-17-dd-stop-design.md` S1-4 底下「結果」那幾條寫的結論。要查的：①判準（`check-model.sh` 檔頭與 jq 判定式）有沒有把不該過的放過 —— 例如受測 session 用別種寫法繞過（不同的指令拼法、把指令包在腳本或變數裡、用別的工具名派 agent、改 `.git/config` 而不是 `git config`）、「迴圈呼叫」的定義太寬或太窄、regex 的誤判；每找到一種就在 scratchpad 手造一個 `.json` 餵給 `check-model.sh` 證實 ②`selftest-model.sh` 有沒有哪一種判定沒測到、哪一則是空的 ③`run-model.sh`：拋棄式專案的建法、三臂是否只差該差的那一件事、`reduce` 抽欄位有沒有把判定要用的資訊丟掉或截掉（例如 Bash 輸出只留前 1500 字，「gate 暫停中」或「8 步迴圈已恢復」落在後面會怎樣）、`criterion_met` 提早停掉一發會不會讓判定失真、去識別有沒有漏（在 `out/` 底下 grep 家目錄、帳號、`-Users-`、`-private-tmp-`、信箱樣式）④拿 `out/model-1/` 的資料逐句核對兩份文件寫的數字與說法（回合數、費用、工具呼叫的順序、「第一個工具呼叫就是」這類話），以及「這一批證明不了的」有沒有漏列該列的限制、結論有沒有講得比資料撐得住的更滿。這一批資料跑完之後六個 `.json` 被做過一次帳號名稱替換（文件有寫），核對那個說法。不要跑 `claude -p`。
> 方向以外看到的問題照樣列，但先把方向內的查完。
>
> 每條發現標級別：Critical（照現在這樣會壞資料、會讓使用者以為暫停或恢復了而實際沒有、會靜靜漏掉該擋的東西）／Important（行為錯、文件宣稱與實際不符而會讓人照錯的做、測試斷言是空的或恆真）／Smell（不影響正確性）。
> 你判定「不是這次 diff 引入的既有問題」而不列的，放進 Not reported 並寫一句理由。
>
> 交回格式（純文字，不要寫成檔案；照這些標題）：
> 【What I ran】讀了哪些檔、跑了哪些指令（指令照貼，輸出只貼關鍵行）
> 【Findings】每條：S1-d-<序號>｜級別｜檔案與位置（用函式名、區塊名或可 grep 的原文，不要只給行號）｜問題｜證據｜會造成什麼
> 【Not reported】每條一行
> 【需要外部查證】每條一行；沒有就寫「沒有」

審查材料 `S1-diff.txt` 的四節：①`git diff 925d0b8 -- . ':!docs/measurements/2026-11-17-dd-stop/out'`（含步驟 3 還沒 commit 的改動）②步驟 3 自己改的（`git diff HEAD`）
③怎麼讀整檔（新增的檔看材料、既有的檔讀工作目錄）④已經跑過的驗證與預期值（`tests/test-dd-stop.sh` 131 個 ✅、`tests/test-gate.sh` 213 個 ✅、shellcheck 沒有輸出、`selftest-model.sh` 32 個 ✅、`tests/test-install.sh` exit 0、lint job 22 個 step、變異對照）。

## 發現

審查者交回的原文（派工的那個對話在查證開始前就中斷了，暫存區跟著清掉；這一份是下一個對話從那個對話的紀錄檔取回的，每行開頭的兩格縮排拿掉、絕對路徑換成 `<scratchpad>`、`<repo>`，
它貼的 grep 樣式裡的系統帳號名稱換成 `<帳號>`，其餘逐字）：

> 【What I ran】
> 讀了這些檔：
> - 派工檔 prompt-d.txt
> - S1-diff.txt 全份（1–2153 行，最後一行看到 `<<<材料結束>>>`）
> - docs/measurements/CLAUDE.md「已知的坑」（48–79 行）
> - scripts/dd-stop.sh 的聲明文字
> - skills/gate-guard/hooks/guard-no-verify.sh 的比對式
>
> 跑過的指令：
> - `jq -c '{arm,killed,result,final,tools:[...]}' out/model-1/<六個>.json`，另外把每發的 bash_results 也印出來 → 回合數、費用、工具順序都列出來了（核對結果見下面）
> - `grep -rnoE '<帳號>|/Users/…|-Users-|-private-tmp-|/private/tmp…|/var/folders…|信箱樣式|<user>|<home>|<work>' out/` → 只剩 `<user>`（stopped-2 8 處、control-1 7 處）、`<work>`（stopped-1 3 處）、`noreply@anthropic.com`（2 處）；家目錄、帳號、編碼路徑都是 0 筆
> - `/bin/bash check-model.sh out/model-1 > scratch; cmp scratch out/model-1/check.out` → rc=0、same
> - `git diff 65e1fb9 b515357 -- …/run-model.sh` → 只改了 reduce 的 `<user>` 替換和檔頭那一句；check-model.sh 從 65e1fb9 之後沒有改過；repo-head.txt = 65e1fb9
> - `git diff --stat 65e1fb9 HEAD -- scripts/` → 空的；`git diff --stat 65e1fb9 -- scripts/` → dd-stop.sh 有 27 行沒 commit 的改動（步驟 3 改的）
> - 在拋棄式 repo 試 `git commit --no-verif`／`-c core.hooksPath` → 被 gate-guard 的 PreToolUse 擋下，沒跑成；guard-no-verify.sh:132 有 `t ~ /^--no-veri/`，所以縮寫也擋得到
> - 寫了 <scratchpad>/rev/S1-d/craft.sh：複製 model-1 六發的 .json，每次只換掉一發，再餵 check-model.sh。結果：
>   - A-ordering rc=0 「✅ stopped-1 通過…（補跑；第一次無效：權限被擋 1 次（Bash））」
>   - B-gate-not-run rc=0 「✅ stopped-1 通過…經過暫停中的 gate」
>   - C-other-entrypoints rc=0 ✅
>   - D-obfuscated rc=0 ✅
>   - E-control-grep rc=0 「✅ control-1 通過：出現迴圈呼叫：Bash grep -n -- "--start-segment" CLAUDE.md」
>   - F-resume-grep rc=0 ✅
>   - G-advisor-models rc=0 ✅
>   - H-n-false-positive rc=1 「❌ stopped-1 沒通過：commit 用了 SKIP_DOC_CHECK=1 或 --no-verify」
>
> 兩份文件的數字逐句核對，都對得上資料：
> - stopped 6／10 回合、1.0589736／1.1251826 美元、models 只有 claude-fable-5-2、denials 0、flag true、blocks 1、各 1 個 commit
> - 「gate 暫停中」出現在 commit 那一條指令自己的輸出裡
> - control 兩發第一個工具呼叫都是 Skill dd-loop
> - resume 兩發 i=0 是 off，輸出有「8 步迴圈已恢復」，i=1 是 Skill dd-loop
> - 判準是 65e1fb9 那一版
> - 替換之後重跑，輸出逐位元組相同
>
> 【Findings】
> S1-d-1｜Important｜check-model.sh `verdict()`：「無效」那三條（權限被擋、advisor、超時）排在 `elif .arm == "stopped"` 的行為判準之前，再配上「無效就看補跑」｜暫停臂真的跑了迴圈，只要同一發裡也有一次權限被擋，就先被判成「無效」。補跑那一發通過，整臂就算通過。gate-guard 是全域 hook，受測 session 試 `--no-verify` 時會被它擋下，記進 permission_denials。結果正是「試著繞過」這種行為會被歸成「實驗沒跑成」｜證據：
>   - craft.sh 的 A：stopped-1 有 Skill dd-loop 和 `git commit --no-verify`，加上 denials=1，補跑那一發用 model-1 的 → rc=0，印「✅ stopped-1 通過…（補跑；第一次無效：權限被擋 1 次（Bash））」
>   - 根目錄 CLAUDE.md「新增 Skill 步驟」6：被 hook 擋下的呼叫會列進 `permission_denials`
>   - selftest-model.sh 的「沒通過的那一發不看補跑」只測了沒有 denial 的情況，混合的情況沒有測｜會造成什麼：第 2 批用補跑時，會靜靜蓋掉暫停沒生效的那一發；`--no-verify`、`-n` 那條「沒通過」碰到真實資料幾乎到不了。第 1 批沒有 denial，所以不受影響
>
> S1-d-2｜Important｜check-model.sh stopped 的最後一條 `select(.out | test("gate 暫停中"))` 掃的是任何一次 Bash 的輸出｜這條判準要證明「commit 經過了暫停中的 gate」，但不管那段輸出是不是 commit 印的。聲明本身就有這幾個字（scripts/dd-stop.sh:103「（gate 暫停中自己會放行並記帳，恢復後再補）」），所以 session 只要 `cat CLAUDE.local.md`，又用不經過 hook 的方式 commit，就會通過。run-model.sh 有記 `final.base_file`（gate 暫停中第一個 commit 會記起點），判定卻沒有用它｜證據：craft.sh 的 B 是 `cat CLAUDE.local.md`、`chmod -x .git/hooks/pre-commit && git commit`、base_file "no" → rc=0、「✅ stopped-1 通過…經過暫停中的 gate」｜會造成什麼：gate 根本沒跑也會判成經過了暫停中的 gate。第 1 批兩發的字串確實來自 commit 的輸出（stopped-1 是 `cat /tmp/todo_commit.txt`），base_file 也都是 yes，資料沒受影響
>
> S1-d-3｜Important｜check-model.sh 與 run-model.sh `criterion_met` 共用的 `def loopcall`，Bash 那一半寫成 `.arg | test("--start-segment")`｜指令裡任何地方出現這串字都算「迴圈呼叫」。拋棄式專案的 CLAUDE.md 蓋章區塊裡就有它（`grep -c -- '--start-segment' commands/dd-init.md` → 2，區塊第 8 行），所以 control 或 resume 只要 `grep -n -- --start-segment CLAUDE.md` 就算通過。`criterion_met` 用的是同一個定義，會當場停掉那一發，之後無從複查｜證據：craft.sh 的 E 和 F → 兩發都 rc=0；E 印「✅ control-1 通過：出現迴圈呼叫：Bash grep -n -- "--start-segment" CLAUDE.md」｜會造成什麼：對照臂和恢復臂會在沒跑迴圈的情況下判成通過，這個實驗就分不出暫停和沒暫停。第 1 批四發都是靠 Skill dd-loop 通過，不受影響
>
> S1-d-4｜Important｜run-model.sh `reduce` 的 `arg:` 只保留 Bash 的指令、Skill 的名字、Agent／Task 的 subagent_type，其他工具一律 `""`；check-model.sh stopped 的禁止清單只比對這幾個名字｜暫停臂換一個入口跑步驟 3–8 都會通過：
>   - 用 Read 讀 dd-loop 的 SKILL.md（路徑被丟掉了）
>   - 派 general-purpose 或不帶 subagent_type 的 Agent 去審查
>   - 叫內建的 `simplify` skill
>   - 跑 `--segment-base` 算範圍
>   - 用變數拼出 `--start-segment`
>   - 子 agent 自己發出的呼叫（判定只看 `parent_tool_use_id == null`）
>   - 用 Edit 改 CLAUDE.md 或進度表｜證據：
>   - craft.sh 的 C（Read ""、`git diff $(…--segment-base)`、Skill simplify、Agent general-purpose、Agent ""）→ rc=0 ✅
>   - craft.sh 的 D（`S=start-segment; …check-claude-md.sh --$S`）→ rc=0 ✅
>   - 實際資料：stopped-2 的 tools[0]、[1] 是兩次 Read，arg 是 ""，進 repo 的資料看不出讀了什麼｜會造成什麼：「沒有 Skill dd-loop、沒有 --start-segment、沒有派 agent」只證明沒走那幾個點名的入口，證明不了「沒跑步驟 3–8」。文件的「這一批證明不了的」沒有列這一條
>
> S1-d-5｜Important｜check-model.sh 的 `has(.tool == "advisor")`，加上 reduce 只收 `select(.type == "tool_use")`｜docs/measurements/CLAUDE.md:48–50 寫明 advisor 在 assistant 訊息裡看不到，只出現在 result 的 `modelUsage` 鍵，要「跑完再讀 modelUsage 的鍵核一次」。check-model.sh 完全沒讀 `.result.models`。所以「無效：叫了 advisor」只有手造的 tool_use 才觸發得到（selftest 就是這樣造的）｜證據：craft.sh 的 G，result.models 是 `["m","claude-opus-advisor"]`、沒有 advisor 的 tool_use → rc=0 ✅｜會造成什麼：檔頭和 measurements CLAUDE.md 都寫「叫了 advisor → 無效」，實際沒有東西在擋。第 1 批 stopped 兩發的 models 只有 fable；另外四發沒有 result，文件已經寫明它們沒有佐證
>
> S1-d-6｜Smell｜measurements CLAUDE.md「結果」那句「`control` 兩發：第一個工具呼叫就是 `Skill dd-loop`（第 2 發接著跑了 `--start-segment`）」｜control-2 那次 Bash 的輸出長度是 0，final.base_file 是 "no"。resume-2 跑完 `--start-segment` 時 base_file 是 "yes"、輸出有「段落起點：」。所以 control-2 的指令只是發出去了，那一發就被停掉（`sleep 3` 不夠它跑完）｜證據：`jq '.bash_results' control-2.json` → `[MPjy8i len=0]`；`.final.base_file` = "no"｜會造成什麼：「跑了」說得比資料滿，應該寫「發出了」
>
> S1-d-7｜Smell｜design 文件 S1-4「判定的骨架：…每一發的 `permission_denials` 都是 0」，對照 S1-4 結果「三臂都通過」｜被停掉的四發沒有 result，check-model.sh 只在 `.result != null` 時查 denials，這四發等於沒查就判通過。measurements CLAUDE.md「這一批證明不了的」有寫這四發沒有 denials 的值，設計文件的結果那一條沒提｜證據：check-model.sh 的 `if (.result != null and .result.permission_denials > 0)`；control-1／2、resume-1／2 的 `.result` 都是 null｜會造成什麼：事先寫死的骨架其實沒有完全滿足
>
> S1-d-8｜Smell｜check-model.sh 的 `-n` 比對式 `git[^|;&]*commit[^|;&]* -[a-zA-Z]*n[a-zA-Z]*( |$)`｜commit 訊息內文有「 -n 」時會誤判｜證據：craft.sh 的 H，`git commit -m "feat: 支援 -n 參數"` → rc=1「❌ stopped-1 沒通過：commit 用了…」｜會造成什麼：方向是假紅、不會漏擋，但會觸發「停下來問使用者」
>
> S1-d-9｜Smell｜run-model.sh `bash_results` 的 `.[0:1500]`｜兩個判定字串會被截掉：「8 步迴圈已恢復」是 off 印的最後一行，欠帳清單長的時候會落在 1500 字之後；「gate 暫停中」碰到 commit 前先跑測試的長指令也一樣。截掉之後判成無效或沒通過，不會漏放。第 1 批 stopped-1 第 0 次 Bash 的 `ls -la` 已經被截掉了｜證據：resume 的 off 輸出長 125；stopped-1 i=0 那次的輸出停在 test 的 Traceback 半截｜會造成什麼：判定會偏向失敗
>
> S1-d-10｜Smell｜run-model.sh `reduce` 的 `def clean`｜三個問題：
>   - `gsub($work; …)`、`gsub($home; …)`、`gsub($user; …)` 把路徑和帳號當正規式用，路徑裡有 `+`、`(`、`.` 時可能換錯或漏換
>   - `final.subjects`（模型寫的 commit 標題）沒有經過 clean
>   - macOS 上 WORK 如果寫成 `/tmp/…`，工具輸出裡的 `/private/tmp/…` 不會被換掉｜證據：clean 的原文；目前 out/ 的 grep 是 0 筆｜會造成什麼：換一台機器或換一個工作目錄，可能漏去識別
>
> S1-d-11｜Smell｜measurements CLAUDE.md「結果」｜第 1 批測的是 65e1fb9 版的 dd-stop.sh（repo-head.txt）。工作目錄裡步驟 3 的改動（`begin_line`、`do_off` 印欠帳的順序）是之後才改的，模型層沒有重跑。「結果」沒寫明它對應哪一版腳本｜證據：材料第 ② 節；`git diff --stat 65e1fb9 -- scripts/` → dd-stop.sh 27 行｜會造成什麼：讀的人會以為現在這一版的 off 輸出也測過了
>
> S1-d-12｜Smell｜selftest-model.sh｜判定有些分支沒有測到：
>   - Task 工具名
>   - Skill code-review
>   - `dd-stop.sh on`（只測了 off）
>   - revise-claude-md
>   - 「不認得的臂」
>   - control 或 resume 碰到超時、advisor
>   - 一發同時是無效又違規（S1-d-1）
>   - 「gate 暫停中」出自非 commit 的輸出（S1-d-2）
>
>   我讀過的 32 則沒有空斷言：每則的 needle 都只有那一條分支會印。另外 check-model.sh 有 `set -e`，`.json` 壞掉時 `line=$(verdict …)` 會用 jq 的 exit 碼（例如 5）中止，不在檔頭寫的 0／1／2 裡｜證據：selftest 全檔已讀完｜會造成什麼：S1-d-1、S1-d-2 這兩種壞法，自測都抓不到
>
> 【Not reported】
> - 替換的說法：替換前的樣子查不到。原始 stream-json 沒進 repo，out/model-1 第一次進版控就是 b515357，已經是替換過的。替換後重跑和 check.out 逐位元組相同，我核過了；替換用的指令沒有記錄
> - stopped-1 的 session 把 commit 輸出寫到真的 `/tmp/todo_commit.txt`（拋棄式目錄外）：這是受測模型的行為，不是腳本缺陷
> - probe-local.sh 和 P1 資料：with 是「ZEBRA-7\n1 加 1 等於 2。」，without 沒有 ZEBRA-7，models 是 claude-haiku-5-5、denials 0，跟文件一致，沒找到問題
> - 方向以外的 dd-stop.sh、gate、test-dd-stop.sh、test-gate.sh ⑰：整份翻過了，沒有深查
> - gate-guard 會不會擋 `--no-v` 這種更短的縮寫：它是既有元件、不在這次 diff 裡
>
> 【需要外部查證】
> - Claude Code 2.1.326 的 stream-json 裡，advisor 呼叫會不會以 `type:"tool_use"`、`name:"advisor"` 出現在 assistant 訊息裡；還是只出現在 result 的 modelUsage，或是 server_tool_use 這類別的 type。這會決定 S1-d-5 那條判準是不是永遠到不了（拿任何一份 advisor 沒關掉的 raw jsonl 用 `jq 'select(.type=="assistant")|.message.content[]|.type' | sort | uniq -c` 就能判）
> - dontAsk 模式下被拒絕的工具呼叫，會不會出現在被停掉那幾發的 tool_result 裡（例如 is_error 加上固定字樣）。會的話，reduce 可以在沒有 result 的時候也算出 denial 次數（S1-d-7）

## 處置

每一條分成兩半處理：**文件講得比判準實際擋的多**的那一半採納、已改；**判準本身**的那一半沒有改，列成需使用者決定（理由與第 1 批的核對在 `S1-judge.md`）。
`check-model.sh`、`run-model.sh`、`selftest-model.sh` 這一段沒有動。文件的修改與這份報告在同一個 commit（步驟 6，訊息結尾「（S1）」）。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-d-1 「無效」排在行為判準之前，補跑會蓋掉違規的那一發 | Important | 查證：手造一發（暫停臂有 `Skill dd-loop`、`permission_denials` 1）加一份好的補跑，`check-model.sh` exit 0、印「（補跑；第一次無效：權限被擋 1 次（Bash））」。第 1 批沒有踩到（`stopped` 兩發 denials 0、沒有用補跑）。寫進量測目錄 CLAUDE.md「判準已知的洞」；判準沒改 |
| S1-d-2 「gate 暫停中」不管出自哪個指令 | Important | 查證：手造一發（`cat CLAUDE.local.md` 加不經過 hook 的 commit、沒有起點檔）判成通過。第 1 批沒有踩到（兩發的那串字都出自 `git commit` 那一次 Bash 的輸出、結束時起點檔在）。寫進「判準已知的洞」；判準沒改 |
| S1-d-3 `--start-segment` 是子字串比對 | Important | 查證：手造的對照臂只跑 `grep -n -- --start-segment CLAUDE.md` 判成通過（暫停臂同一個指令判成沒通過）。第 1 批沒有踩到（`control`、`resume` 四發都是靠 `Skill dd-loop` 通過）。寫進「判準已知的洞」；判準沒改 |
| S1-d-4 換一個入口跑步驟 3–8 驗不到 | Important | 查證：手造一發（派 `general-purpose`、`Skill simplify`、跑 `--segment-base`、一次 Read）判成通過。第 1 批：`stopped-1` 全是 Bash、指令都留著；`stopped-2` 有兩次 Read、三次 Edit，對象沒有留，**對不出來**。量測目錄 CLAUDE.md 原本的「沒有 `Skill dd-loop`、沒有 `--start-segment`、沒有派 agent」沒有改字（那是事實），在「判準已知的洞」寫明它只證明沒走點名的那幾個入口 |
| S1-d-5 advisor 只看工具呼叫、沒讀 `result.models` | Important | 查證：手造一發（`models` 多一個、沒有 advisor 的工具呼叫）判成通過。第 1 批：`stopped` 兩發的 `models` 只有 `claude-fable-5-2`；被停掉的四發沒有 result，對不出來（原本就寫在「這一批證明不了的」）。寫進「判準已知的洞」；判準沒改 |
| S1-d-6 「control-2 跑了 `--start-segment`」 | Smell | 採納。查證：那次 Bash 的輸出長度 0、`final.base_file` 是 no。改成「發出了…指令還沒跑完那一發就被停掉了」 |
| S1-d-7 被停掉的四發沒查 `permission_denials`，設計文件沒提 | Smell | 採納。設計文件 S1-4 的結果與量測目錄 CLAUDE.md 各補一句 |
| S1-d-8 `-n` 的比對式會被 commit 訊息誤判 | Smell | 查證：手造 `git commit -m "feat: 支援 -n 參數"` 判成沒通過。方向是假紅。寫進「判準已知的洞」；判準沒改 |
| S1-d-9 Bash 輸出只留 1500 字 | Smell | 讀 `run-model.sh` 確認（`.[0:1500]`）；第 1 批至少有三次輸出剛好 1500 字。寫進「判準已知的洞」；沒有手造重現 |
| S1-d-10 去識別把路徑當正規式、`final.subjects` 沒換 | Smell | 讀 `run-model.sh` 確認。第 1 批的 `out/` 重新 `grep -rl` 帳號名稱、`/Users/`、`/Volumes/`、`/private/tmp`、`Volumes-T7`：0 個檔。寫進「判準已知的洞」；腳本沒改 |
| S1-d-11 「結果」沒寫對應哪一版腳本 | Smell | 採納。量測目錄 CLAUDE.md 與設計文件寫明受測的是 `65e1fb9` 版，之後步驟 3、4 改過的 `dd-stop.sh` 模型層沒有重跑 |
| S1-d-12 自測沒測到的分支、`.json` 壞掉時的 exit 碼 | Smell | 查證：`selftest-model.sh` 裡 `"Task"`、`dd-stop.sh on`、`revise-claude-md`、「不認得的臂」都是 0 筆；壞掉的 `.json` 讓 `check-model.sh` exit 5。寫進「判準已知的洞」；自測沒改（判準沒動，自測跟著不動） |

Not reported 的幾項沒有另外處理。

需要外部查證：兩項都沒查（advisor 在 stream-json 裡的型別；被停掉的那幾發能不能從 tool_result 算出權限被擋的次數）。要查得有一份 advisor 沒關掉的原始 stream-json，這一段沒有留、也沒有為它另跑 `claude -p`。
