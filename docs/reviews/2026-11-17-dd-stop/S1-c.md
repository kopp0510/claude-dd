# S1-c（審查者 C：文件宣稱）— /dd-stop 指令、腳本與 gate 的暫停旗標

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-17），在步驟 3（code-simplifier）做完、還沒 commit 的時候。
Agent 呼叫的 prompt 只有「你的完整派工內容在這個檔，先用 Read 把它整份讀完，然後照它做」加檔案路徑，另寫明代號是 S1-c、報告用純文字照四個標題交回、不要寫成檔案。那個檔的內容如下
（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是這一段程式碼變更的審查者 S1-c。職責只有一個：找漏洞。每一條發現都要附證據（`檔案路徑` 加上你讀到的原文，或你實跑的指令與輸出）；沒有證據的不算、不要寫。不寫優點、不客套。
>
> repo：<repo>（規則在根目錄與各層 CLAUDE.md，跟你方向有關的那幾份要讀）。
> 這一段做的事：新增 `/dd-stop on|off|status` 指令 —— 暫停與恢復一個專案的 8 步開發迴圈（步驟 3–8）與 CLAUDE.md pre-commit gate。設計、使用者的決定（U1–U3）在 docs/designs/2026-11-17-dd-stop-design.md。
>
> 審查材料在這個檔：<scratchpad>/rev/S1-diff.txt（共 2153 行，最後一行是 `<<<材料結束>>>`）。
> - 用 Read 的 offset／limit 每次 300 行，讀到看見最後那一行為止（Read 一次讀太多會靜靜截斷、不報錯）。跟你方向無關的檔的 diff 可以掃過，但整份都要翻到。
> - 材料裡有 5 行超過 2000 字元（都是 CLAUDE.md 的表格列），Read 會截斷；要看那幾行就讀工作目錄的原檔。
> - 新增的檔看材料裡那一份；既有而被改到的檔要看上下文時讀工作目錄（審查期間沒有人在改）。
> - 材料第 ④ 節列的驗證已經跑過、結果已確認，不要重跑整支測試。「跑過」不代表測試寫得對 —— 測試本身也在審查範圍。
> - 你可以在 scratchpad 開拋棄式 git repo 做小實驗來證實某一條（目錄放 <scratchpad>/rev/S1-c/ 底下）。用 `/bin/bash <腳本>` 跑，不要在 zsh 裡 `source` repo 的任何腳本（`source ./install-dd-pipeline.sh` 會真的把安裝跑起來）。不要跑 `./install-dd-pipeline.sh`、不要跑 `claude -p`、不要碰真的 `~/.claude/`、不要改 repo 裡任何檔、不要 commit。
> - 只用手上的資料判斷；需要外部查證（上網、官方文件、別台機器）的列在「需要外部查證」交回，不要自己猜。
>
> 你的方向：文件與指令裡的宣稱對不對得上程式碼。逐句核對這幾份這一段新增或改動的句子，凡是講到「腳本會印什麼、exit 幾、哪個檔會怎樣、哪個測試守哪件事、哪一節在哪個檔」的，都去讀被引用的那一處確認：`commands/dd-stop.md`（每一步引用的輸出字串、exit code 的意思，要跟 `scripts/dd-stop.sh` 與 `scripts/check-claude-md.sh` 實際印的逐字對）、`skills/dd-loop/SKILL.md`「段落起點與 `<起點>`」這一段改的那幾行、兩份 README（`README.md` 與 `README.zh-TW.md` 這一段的改動要互相對得上、也對得上實際行為）、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md` 的 `## 未發布`、根目錄 `CLAUDE.md`、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、`docs/designs/2026-11-17-dd-stop-design.md`（D1–D8 與「實作時跟上面幾條不一樣的地方」跟程式碼對不對得上）、`scripts/dd-stop.sh` 與 gate 的檔頭註解。另外照根目錄 `CLAUDE.md` 的規定查有沒有漏改的同步點：「新增 Command 步驟」「新增 Script 步驟」「注意事項」裡「CI 不驗、只能手動同步的區塊」那一條列的每一處（這一段動到了部署陣列、gate 行為、`skills/dd-loop/SKILL.md`）、`commands/*.md` 內文不可以有 `$<數字>`、`install-dd-pipeline.sh` 的 `DD_COMMANDS`／`DD_SCRIPTS`／`deprecated_dd`／`--help`／`show_completion`、`UPGRADING.md` 要不要提。`dd-stop` 這個名字以前是另一個已退場的指令（安裝腳本的退場清單裡有過），查這次把它拿出清單之後有沒有哪裡還把它當成要刪的舊檔。
> 方向以外看到的問題照樣列，但先把方向內的查完。
>
> 每條發現標級別：Critical（照現在這樣會壞資料、會讓使用者以為暫停或恢復了而實際沒有、會靜靜漏掉該擋的東西）／Important（行為錯、文件宣稱與實際不符而會讓人照錯的做、測試斷言是空的或恆真）／Smell（不影響正確性）。
> 你判定「不是這次 diff 引入的既有問題」而不列的，放進 Not reported 並寫一句理由。
>
> 交回格式（純文字，不要寫成檔案；照這些標題）：
> 【What I ran】讀了哪些檔、跑了哪些指令（指令照貼，輸出只貼關鍵行）
> 【Findings】每條：S1-c-<序號>｜級別｜檔案與位置（用函式名、區塊名或可 grep 的原文，不要只給行號）｜問題｜證據｜會造成什麼
> 【Not reported】每條一行
> 【需要外部查證】每條一行；沒有就寫「沒有」

審查材料 `S1-diff.txt` 的四節：①`git diff 925d0b8 -- . ':!docs/measurements/2026-11-17-dd-stop/out'`（含步驟 3 還沒 commit 的改動）②步驟 3 自己改的（`git diff HEAD`）
③怎麼讀整檔（新增的檔看材料、既有的檔讀工作目錄）④已經跑過的驗證與預期值（`tests/test-dd-stop.sh` 131 個 ✅、`tests/test-gate.sh` 213 個 ✅、shellcheck 沒有輸出、`selftest-model.sh` 32 個 ✅、`tests/test-install.sh` exit 0、lint job 22 個 step、變異對照）。

## 發現

審查者交回的原文（派工的那個對話在查證開始前就中斷了，暫存區跟著清掉；這一份是下一個對話從那個對話的紀錄檔取回的，每行開頭的兩格縮排拿掉、絕對路徑換成 `<scratchpad>`、`<repo>`，其餘逐字）：

> S1-c 審查結果：文件與指令裡的宣稱跟程式碼大致對得上。沒有 Critical，也沒有 Important；有 5 條 Smell。
>
> 【What I ran】
> - 讀了這些：材料 `<scratchpad>/rev/S1-diff.txt` 全部 2153 行（看到 `<<<材料結束>>>`）；工作目錄的 `scripts/check-claude-md.sh` 第 155–386 行（`owed_dirs`、`reviews_missing`、`case "$1"`、暫停那一支、擋下時的訊息）；`install-dd-pipeline.sh` 的 `create_commands()`（第 1075–1130 行）、`show_help` 與 `show_completion` 開頭；`skills/dd-loop/SKILL.md` 第 10–22 行；`scripts/CLAUDE.md`（system-reminder 給了全文）；`.github/workflows/ci.yml` 第 20–40 行
> - `git grep -n 'dd-stop' -- . ':!docs/reviews' ':!docs/measurements' …` → 只出現在新指令、新腳本、部署陣列與同批改的文件裡。舊名字沒有被當成要刪的檔：`deprecated_dd` 只剩 dd-help、dd-docs、dd-revise、dd-status；`UPGRADING.md` 沒有任何 dd-stop
> - `grep -n '\$[0-9]' commands/dd-stop.md` → rc=1，0 筆
> - `wc -c CLAUDE.md` → 47182，上限 48000
> - `grep -n '^set ' scripts/check-claude-md.sh` → 沒有 `set -e`，所以 `STOPPED=$(git config --local --get …)` 在沒設旗標時不會讓 gate 中止
> - `grep -n 'echo' scripts/check-claude-md.sh` → `commands/dd-stop.md` 第 5 步引的字串，在 gate 裡都逐字找得到：「commit 已擋下」、「→ AI agent 執行時：」、「git add 後重新 commit」、「其他處理方式：」、「看這段改了什麼：git diff $base -- <目錄>」
> - `dd-stop.sh` 裡的「8 步迴圈已暫停」「8 步迴圈已恢復」「以下是 gate 的欠帳檢查（這次沒有 commit 被擋）」「起點檔壞了，暫停期間的欠帳算不出來」「兩邊不一致」，與 gate 的「迴圈暫停中（dd.stopped）…」「gate 暫停中（dd.stopped）…」，跟指令、`skills/dd-loop/SKILL.md`、兩份 README、CHANGELOG、設計文件 D2–D4 逐字對過，都一致
> - ci.yml 的 ShellCheck 清單 → 14 支，跟 `DD_PIPELINE_ARCHITECTURE.md` 的「14 支腳本」相同
> - `grep -nE '^# [A-N][0-9]? ' tests/test-dd-stop.sh` → A 到 N 共 14 行都抓得到，跟 `tests/CLAUDE.md` 寫的取法相符
> - `grep -n 'DD_SCRIPTS\|DD_COMMANDS\|ALL_DD_COMMANDS' install-dd-pipeline.sh` → uninstall 照陣列跑，新檔會一起移除
> - 實驗 `/bin/bash <scratchpad>/rev/S1-c/t.sh`：用 repo 版的兩支腳本，在拋棄式 repo 依序做了：記起點 → `on` → 暫停中 commit 改了 a/x.sh（新目錄）和 b/y.sh → `off` → 只補 a/CLAUDE.md 再 commit → 再一個無關的 commit。關鍵輸出：
>   - `off` rc=0，縮排印出「缺少 CLAUDE.md 的目錄：a/CLAUDE.md」「未同步更新：b/CLAUDE.md（段落起點之後有 commit 跳過檢查…）」「看這段改了什麼：git diff <sha> -- <目錄>」，最後才印「8 步迴圈已恢復」
>   - 只補 a 的那個 commit rc=1，訊息只剩 b/CLAUDE.md
>   - 無關的 commit rc=1，訊息同樣只剩 b/CLAUDE.md
>   - 結論：指令說的「commit 沒被擋就是補齊了（還有沒補的，gate 會擋下並列出來）」，在部分補帳時成立
>
> 【Findings】
> S1-c-1｜Smell｜`tests/test-gate.sh` ⑰ 的「⑰ 恢復後：補上 a/CLAUDE.md 就放行」與 `tests/test-dd-stop.sh` 的 G｜補完帳之後，沒有一個「完全不碰 a/ 的 commit」來釘住欠帳真的銷掉了。現在能放行，是因為 a/CLAUDE.md 跟著同一批 staged、走了短路。｜`tests/CLAUDE.md` 在 ⑫ 那段寫明：「要釘住銷帳必須**再加一個完全不碰該目錄的 commit**」。⑰ 最後一則是 `echo doc2 > a/CLAUDE.md` 接 `expect "⑰ 恢復後：補上 a/CLAUDE.md 就放行" pass commit s3`，後面就沒有了。｜`commands/dd-stop.md` 第 5 步「commit 沒被擋就是補齊了」這一句，這兩支新測試都沒有釘住。現在靠 ⑫ 的既有測試和我上面的實驗撐著；gate 的銷帳邏輯以後退化時，⑰ 與 G 不會變紅。
>
> S1-c-2｜Smell｜`commands/dd-stop.md` 第 5 步「列了要補的 CLAUDE.md（一行一個 `<目錄>/CLAUDE.md`）」｜實際輸出分「缺少 CLAUDE.md 的目錄：」「未同步更新：」兩組；未同步那組每行結尾還帶「（理由）」。｜實驗輸出：`b/CLAUDE.md（段落起點之後有 commit 跳過檢查改了這裡的程式碼，CLAUDE.md 到現在還沒補）`；gate 的 `stale="$stale\n  ${md}（${reason}）"`。｜模型照字面比對時可能會漏抓；目錄本身照樣抓得出來，所以不影響正確性。
>
> S1-c-3｜Smell｜`README.md`「Core workflow」那一句「`--start-segment` records nothing (it prints a "paused" line)」｜實際印的是中文「迴圈暫停中（dd.stopped）：沒有記新起點…」，沒有 paused 這個字。繁中版寫的是「印「迴圈暫停中」」。｜`scripts/check-claude-md.sh` 的 `echo "迴圈暫停中（dd.stopped）：沒有記新起點。這個工作只做步驟 1、2；恢復用 /dd-stop off"`｜英文讀者拿 "paused" 去找輸出會找不到；兩份 README 的說法有落差。
>
> S1-c-4｜Smell｜`docs/designs/2026-11-17-dd-stop-design.md` D3 `off` ①「`git config --local --unset dd.stopped`」｜程式碼用的是 `--unset-all`，而「實作時跟上面幾條不一樣的地方」①–⑧ 沒有列這一條。｜`scripts/dd-stop.sh` `do_off()`：`git config --local --unset-all dd.stopped 2>/dev/null || true`｜行為比設計寫的更穩（多個值也清得掉），只是設計文件沒有反映實作。
>
> S1-c-5｜Smell｜`scripts/CLAUDE.md` 的 `dd-stop.sh` 條目「變異對照（2026-11-17，30 個變異都有紅…）」｜寫了一個總數。表只有 27 列，要把含「／」的三列各拆成兩個才湊得到 30，讀者沒辦法直接核對。｜全域 §3.10：「凡是能列舉的就列舉，不要數」。同一份檔在 gate 的變異表也寫了「刻意不記紅數」。｜以後加一列或拆一列時，「30」會靜靜過期。
>
> 【Not reported】
> - `UPGRADING.md` 沒有提 dd-stop：舊的 dd-stop.md 會由 `create_commands()` 先備份再覆蓋（`backup_before_overwrite` 那一支），兩份 README「同名的檔會被換掉」已經寫明，我判斷不需要升級說明
> - `--commands-only` 只裝指令、不裝 dd-stop.sh：已經在 CHANGELOG、`scripts/CLAUDE.md` 已知限制 ④ 與指令第 1 步揭露
> - uninstall 不會清掉各專案裡的 `dd.stopped` 與 `CLAUDE.local.md`：那些是專案自己的狀態，超出這段的範圍
> - gate 擋下時印的「→ AI agent 執行時：不要問使用者」會原樣出現在 `off` 的輸出裡：`commands/dd-stop.md` 第 5 步已經寫明「那幾行這次不照做」
> - `--help` 裡「--commands-only 只安裝 DD Commands（不安裝 skills）」那一句沒講它也不裝 scripts：既有問題，不是這次 diff 引入的
>
> 【需要外部查證】
> 沒有

## 處置

修正與這份報告在同一個 commit（步驟 6，訊息結尾「（S1）」）。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-c-1 補完帳之後沒有「不碰那個目錄的 commit」 | Smell | 採納（與 S1-b-6 同一件），做了什麼見 `S1-b.md` |
| S1-c-2 `commands/dd-stop.md` 第 5 步說清單「一行一個 `<目錄>/CLAUDE.md`」 | Smell | 採納。改成「分『缺少 CLAUDE.md 的目錄』『未同步更新』兩組，每行開頭是 `<目錄>/CLAUDE.md`，後面可能接一段括號說明」。這一句改完沒有再乾跑，設計文件 S1-4 的結果有寫 |
| S1-c-3 英文 README 寫 prints a "paused" line | Smell | 採納。改成寫明那一行以「迴圈暫停中」開頭、腳本的輸出是中文。繁中版本來就寫對，沒有動 |
| S1-c-4 設計文件 D3 寫 `--unset`，實作是 `--unset-all` | Smell | 採納。補進「實作時跟上面幾條不一樣的地方」的 ⑨ |
| S1-c-5 `scripts/CLAUDE.md` 寫「30 個變異都有紅」 | Smell | 採納。個數拿掉，改成「表上每個變異都有紅」，並寫明刻意不記個數 |

Not reported 的幾項沒有另外處理。它量的 `wc -c CLAUDE.md` 47182 查證時重量過，相同（標 DONE 時會刪掉指路那一句，之後會變小）。
