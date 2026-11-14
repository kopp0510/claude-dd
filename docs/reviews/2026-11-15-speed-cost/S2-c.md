# S2 步驟 4：審查者 C（一致性與去識別）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數），同時派 code-simplifier 跑步驟 3。派工用一句話：「先用 Read 讀完 `<scratchpad>/s2/review/prompt-c.txt`，它就是你的完整任務說明，照裡面做。報告直接用文字交回，不要寫成檔。」下面是那個檔的全文（路徑已去識別：`<repo>`、`<scratchpad>`）。
diff 檔（1572 行）的組成：①`git diff 58fc4ba HEAD`（HEAD = 623f61a；不含 `out/reports/` 與 `judge.txt`，這兩類直接讀 repo）②被改到檔案在 HEAD 的整檔內容（帶行號；與步驟 3 並行，所以取 HEAD 版）③已跑過的驗證與預期值 7 條。步驟 3 的改動在派工當下是空的。

```text
你是 8 步開發迴圈步驟 4（code-review）的審查者 C。另外兩個審查者同時在審同一段，你們互相看不到。

職責：找漏洞、證明這次改動有錯。每條附證據（diff 檔行號、repo 檔案行、你跑的指令與輸出），沒證據的不算。
只用手上的資料判斷；需要外部查證的列出來交回，不要自己上網抓。不改任何檔、不 commit、不跑 claude 指令（會花錢）。

範圍：repo <repo> 的 git diff 58fc4ba HEAD（HEAD 是 623f61a），一段「審查者思考強度實驗」（量測腳本、結果文件、設計文件與兩份 CLAUDE.md 的補充）。
diff 檔：<scratchpad>/s2/review/S2-diff.txt，共 1572 行。Read 一次讀太多會靜靜截斷、不報錯；一律用 offset／limit 每次 300 行，讀到第 1572 行為止。
diff 檔三段：整段 diff（不含 docs/measurements/2026-11-15-reviewer-effort/out/reports/ 與 docs/measurements/2026-11-15-reviewer-effort/judge.txt，這兩類直接讀 repo）、被改到檔案的整檔內容（帶行號）、已經跑過的驗證（已確認，不要重跑）。
同時有一個 code-simplifier 在改工作目錄裡 docs/measurements/2026-11-15-reviewer-effort 底下的 stats.py、table.py、outside.py、deid.py：這四支一律讀 diff 檔裡那一份（HEAD 版）或 git show HEAD:<路徑>，不要讀工作目錄。其他檔照常讀 repo。
專案規則在根目錄與各層的 CLAUDE.md。回覆用繁體中文。

背景事實（不是結論，請自己查證）：
- 實驗在跑之前 commit 了方法、正確答案、判準（2b470b5）；第一發跑完、看報告之前補了洩題檢查的判法（e5c104b）；run.sh 在第一發作廢後加了一個環境變數（6903c1b）；甲的結果 61e594d；乙與結論 623f61a
- 使用者在乙跑完第一發後選「現在停」，所以乙只有 1 發
- 命中（哪份報告的哪一行算抓到）是寫這段 diff 的人自己人工判的

你的方向：跨文件一致性與去識別：設計文件 docs/designs/2026-11-15-speed-cost-design.md 這段改的地方（進度表、S1 狀態表兩句、S2 開工前提與結果）對不對得上量測文件與程式；根目錄 CLAUDE.md 新增的兩條（claude -p 10 分鐘背景等待上限、快照放暫存區的洩題檢查）與「python 的整數字串超過 4300 位」那幾處改寫，每句宣稱有沒有依據；docs/measurements/2026-11-15-reviewer-effort/CLAUDE.md 列的檔案與約束對不對得上實際的檔；docs/measurements/2026-11-15-reviewer-effort/out/（stats.jsonl 與 reports/）與這段新增的所有檔有沒有殘留本機路徑、帳號、信箱（這是公開 repo）；install-dd-pipeline.sh 與 tests/ 的註解改動有沒有跟程式碼對不上。

交回格式（直接用文字交回，不要寫成檔）：
每條發現：級別（Critical／Important／Smells）｜位置（檔案與行）｜內容｜證據。
另列「Not reported」（看過、判斷不報的，各一句理由）、「需要外部查證」（沒有寫「無」）、「What I ran」（跑過的指令）。
```

## 發現

審查者交回的全文（去識別後：路徑換成佔位，掃描樣式裡的 `claude-<uid>` 原文是實際的數字；其餘一字不改）：

```text
Critical 0 / Important 4 / Smells 2：審了 `git diff 58fc4ba HEAD`（HEAD 623f61a），範圍照指定的方向：跨文件一致性、去識別、註解與程式碼是否對得上。

**發現**

1. Important｜`CLAUDE.md:392`（新增那條「受測 session 的快照放在 scratchpad 底下時…」）｜句中「`cd` 到快照的上兩層」與實際不符：實際是快照的上三層，也就是工作目錄的上兩層。量測文件 `2026-11-15-reviewer-effort.md` 結果段寫的是「工作目錄的上兩層」，`outside.py` 用的也是 `dirname(dirname(w))`，這兩處是對的；root CLAUDE.md 這句跟它們矛盾。｜證據：P-med-3 審查者紀錄檔的指令是 `cd <暫存區> && find . -maxdepth 4 …`，而快照是 `<暫存區>/s2/work/P-med-3`（工作目錄是 `<暫存區>/s2/work`）。查法：`grep -ho '"command":"[^"]*probe[^"]*"' ~/.claude/projects/<P-med-3 編碼>/*/subagents/*.jsonl`。

2. Important｜`docs/measurements/2026-11-15-reviewer-effort.md` 結果段「作廢與沒算進去的發」中 `P-low-1` 那一項｜文件寫「沒有 result、沒有費用紀錄」，與紀錄不符：`logs/P-low-1.jsonl` 裡有一筆 result，`subtype=success`、`is_error=False`、`total_cost_usd=0.848`，是父 session 第一輪結束時印的。保守算 2 美元、合計約 18.9 美元的結論不受影響，但這句事實要改成「只有第一輪的 result（0.85 美元，不含之後背景跑的部分）」。｜證據：我用 python 掃 `logs/P-low-1.jsonl` 中 `type=="result"` 的紀錄，印出 `success False 0.8484830600000002 裁決者已在背景派出，還沒交回報告…`。

3. Important｜`docs/designs/2026-11-15-speed-cost-design.md:32`（進度表 S2 列的驗收欄，這段 diff 有改到這一列），另有 S2-2（`:185`）的「表上每個數字能用 `stats.py` 重算」｜驗收寫「`python3 -I stats.py` 能從存下的 stats 重算出表」，照字面做不到。`stats.py` 的用法是 `<工作目錄> <發代號>`，要讀 `~/.claude/projects/` 的原始紀錄和 `<工作目錄>/logs/*.jsonl`，這些都不在 repo 裡。真正從存下的 `out/stats.jsonl` 重印表的是 `table.py`，量測文件「結果」段寫的也是 `table.py`。步驟 5 照這條驗收去跑會跑不起來，或被迫去讀 repo 外的原始紀錄。｜證據：diff 檔 :653 是 `stats.py` 的用法行，:807–808 是 `table.py` 的用法行；量測文件結果段第一句寫「數字用 `python3 -I table.py out/stats.jsonl P` … 重印」。

4. Important｜`CLAUDE.md:389–391`（新增那條「`claude -p` 在父 session 最後一輪結束 10 分鐘後…」）｜句末的「跑完 grep 父 log 有沒有那句」，只在 stderr 也導進父 log 時才成立。這次的 run.sh 用 `> log 2>&1`，所以成立。但 repo 裡別的實驗把 stderr 另存成檔，那時 grep 父 log 會回 0 筆，看起來像沒被停掉。同一句前面也寫了「stderr 印」，建議改成「grep stderr（或導進父 log 的那份）」。｜證據：`docs/measurements/2026-10-30-dd-init-upgrade/run.sh:10` 是 `> "$T/$c.jsonl" 2> "$T/$c.stderr"`，`docs/measurements/2026-10-30-dd-loop-trigger/run.sh:27` 也一樣分開存。

5. Smells｜`docs/designs/2026-11-15-speed-cost-design.md:57–59`｜`:57` 改成「使用者 2026-11-15 選「留著」」，但同一段 `:59` 還留著「先留著；使用者選不留就另開一個 commit 拿掉」。決定已經做了，這句條件句過期，與上一句互相打架（全域 §3.10「補了一句限定之後，把那一段從頭讀到尾」）。｜證據：diff 檔 :57 與 :59。

6. Smells｜`docs/designs/2026-11-15-speed-cost-design.md:192` 對照量測文件「開工前提的結果」的 `### 3. 洩題檢查`｜設計文件把這項叫「前提 4」，指路去量測文件；量測文件同一件事的編號卻是 3（設計文件的前提 3 是預算）。照編號找會對錯節。另外 S1 狀態表 `:45` 的 `outofrange` 列與 `:48` 的 `none` 列，把「步驟 4 之後拿掉了…」「步驟 4 之後改成這樣寫」這種編修說明寫進了「印出的句子」那一欄。照這欄挑 T10 斷言字串的人會誤以為括號裡的字也會印出來。｜證據：設計文件 `:144–147` 的前提編號；量測文件 `### 3. 洩題檢查（比內容）`；`install-dd-pipeline.sh:402` 與 `:409–411` 的實際輸出不含那幾句。

**Not reported**
- 數字一致性：甲、乙兩張表的 token 合計、平均、80.5%、385/353/371/318、費用加總 18.88 都對得上。`out/stats.jsonl` 和工作目錄的 `logs/*.stats.json` 除了 notes 以外每個鍵都相同，notes 的筆數也是 4/4/4/4/3。
- 去識別：27 份報告、`judge.txt`、`parent-*.txt`、量測文件與目錄裡的 CLAUDE.md 都乾淨。我用不分大小寫的帳號名、`/Users/`、`-Users-`、`claude-<uid>`、`/private/tmp`、`/tmp/claude`、email、UUID 掃，0 個檔命中。整段 45 個檔改用 `core.quotePath=false` 重掃一次，也沒有命中；剩下的命中只出現在描述規則或掃描樣式的文字裡。報告裡唯一殘留的是 `<暫存區>/s2/probe` 這個佔位。
- 凍結：`judge.txt`、`parent-*`、`reviewer-b.txt`、`prepare.py`、`stats.py` 只有 2b470b5 一個 commit，`run.sh` 只多 6903c1b，跟目錄 CLAUDE.md 寫的「例外一個」一致。2b470b5 版的 `run.sh` 沒有 CEILING（grep -c 0）。量測文件的方法、正確答案、判準三節在 2b470b5 之後只多了 e5c104b 那段判法。
- `judge.txt` 寫「只改兩處」，屬實：拿暫存區的 `imp/judge-r1.txt` 把路徑換成 `{ROOT}` 後 diff，只有 :170 和 :173 兩處不同。
- 10 分鐘那條：stderr 原文、父 log 有 `subtype: success` 的 result、2.1.325 都有依據（7 份 log 的 init 都是 2.1.325）。
- 4300 位：本機 Python 3.13.2 實測，4301 位會 ValueError，4300 位 OK。`install-dd-pipeline.sh`、`tests/test-install.sh`、`tests/CLAUDE.md` 的註解都跟 `hasattr` 護欄和 T2 案例對得上。`git grep '3\.11'` 只剩費用 3.11 美元，沒有殘留舊寫法。
- 設計文件的 S1 `outofrange`、`none` 兩列，與 `install-dd-pipeline.sh:401–411` 的實際字串一致。
- 目錄 CLAUDE.md 的檔案清單和 `git ls-tree` 逐項對得上。dump 有 28 份、reports 有 27 份，少的那份是 `P-med-1` 的裁決者，跟「作廢的 P-med-1 只有審查者的報告」一致。設計文件 `:180` 的「進 repo 的東西」沒列 `table.py`、`outside.py`、`deid.py`、`judge.txt`、`reviewer-b.txt`，但實際只多不少，不報。
- M1 與 K1 引的行號，我逐行印出來看過，都講到該機制。`P-low-3.d2.ab9ac0:13` 標成 (a)，依據是 dd-loop 的 SKIP 路徑（b1935bb 的 `SKILL.md:93`），算 (a) 有爭議，但那份報告同時有 (b)，命中不變。
- 量測文件說 P-med-3 那個審查者「沒有讀任何檔的內容」，字面上不精確：`grep -rl` 會讀檔案內容，只是沒有輸出。照 e5c104b 的判法，那個目錄不屬於四類可能含答案的東西，結論不變，所以不另報。
- `4ae9e59`（S1 收尾）落在 S2 的範圍、不在 S1 的 commits 欄 `60239e7..fd96d69` 裡。它已經在這次範圍內被審到，不另報。

**需要外部查證**
- 使用者 2026-11-15 選了「留著」（設計 `:57`）、選了「現在停」（設計 `:199`）：對話紀錄不在我手上，核不到。
- 「互動式 session 那次 `code-reviewer` 19 個、haiku 25 個全部 medium」：要讀 `~/.claude/projects/` 中 2026-11-14T10:35Z 之後的 subagent 紀錄，超出範圍，沒查。
- `P-med-1` 四個審查者的秒數（198、83、193、103），以及 `P-low-1`「跑了約 3 分鐘」：要讀 P-med-1、P-low-1 的 subagent 紀錄檔時間戳，沒查。

**What I ran**
- `Read` prompt-c.txt；`Read` S2-diff.txt 的 1–900 行與 1565–1572 行。901–1564 行是同一批新檔帶行號的整檔副本，前段 diff 裡已整檔讀過，沒有逐行再讀 → 以前段 diff 內容為準
- `git log --oneline 58fc4ba..HEAD`；`git ls-tree -r --name-only HEAD docs/measurements/2026-11-15-reviewer-effort` → 6 個 commit、檔案清單
- `grep -n 'outofrange|…' install-dd-pipeline.sh`；`sed -n 398,412p install-dd-pipeline.sh` → 實際印出的字串
- `python3 --version` → 3.13.2；python 跑 `json.loads` 4301 位與 4300 位 → ValueError 與 ok
- 用 grep 從 P-med-3 subagent 紀錄找 probe 與 command_exists 的指令 → `cd <暫存區> && find …`、`cd <暫存區>/s2/probe && ls -la …`
- 在 logs/*.jsonl 裡 grep `Background tasks` 與 `claude_code_version`，並數 result 筆數 → stderr 原文、版本全是 2.1.325、P-low-1 有 1 筆 result
- python 解析 P-low-1、P-med-1 的 result → 兩筆都是 success，費用 0.848 與 2.864
- `sed -n` 讀設計文件 138–212 行
- 逐行印出 M1 與 K1 引用的報告行（16 處）→ 都講到該機制
- `git show b1935bb:skills/dd-loop/SKILL.md` 的 43–47 行與 88–96 行
- 對 45 個改動檔做去識別 grep（`core.quotePath=false`，不分大小寫）→ 規則文字以外 0 筆；對工作目錄的 out/、judge.txt 等做 `grep -ril` → 0 個檔
- `comm` 比對 dump 與 reports → 只差 P-med-1 的裁決者報告
- python 比對 out/stats.jsonl 與 logs/*.stats.json → 除了 notes，diff keys 全空
- 對每個凍結檔跑 `git log 58fc4ba..HEAD -- <檔>`；`git diff 2b470b5 HEAD -- 量測文件` → 只有 run.sh 多一個 commit；方法三節只多了判法那段
- `git show 2b470b5:…/run.sh | grep -c CEILING` → 0
- grep 其他 docs/measurements/*/run*.sh 的 stderr 導向 → 有兩支把 stderr 另存
- `git grep -n '3\.11' HEAD` → 只剩費用數字
- 把暫存區 `imp/judge-r1.txt` 的路徑換成 `{ROOT}` 後與 `judge.txt` diff → 只有 :170、:173 兩處不同
- 呼叫 advisor 一次
```

## 處置

| # | 發現 | 處置 |
|---|---|---|
| 1 | Important：根目錄 CLAUDE.md 寫「快照的上兩層」，實際是上三層 | 採納。快照是 `<暫存區>/s2/work/P-med-3`，它 `cd` 到 `<暫存區>`。改成「快照的上三層（暫存區的根）」 |
| 2 | Important：`P-low-1`「沒有 result、沒有費用紀錄」不對 | 採納。父 log 有一筆 `success`、0.848 美元的 result（第一輪）。改寫那一句；累計照樣保守算 2 美元 |
| 3 | Important：驗收寫 `stats.py` 能從存下的 stats 重算，做不到 | 採納。進度表驗收欄與 S2-2 的驗證改成 `table.py`（並留下原本寫的是什麼） |
| 4 | Important：「grep 父 log」只在 stderr 併進父 log 時成立 | 採納。改成 grep stderr，註明那支 `run.sh` 是 `2>&1` |
| 5 | Smells：設計文件「先留著；使用者選不留就…」過期 | 採納。審查者報的行號對不上，拿原文 grep 到的那一行改成「留著，不另開 commit」 |
| 6 | Smells：「前提 4」對不到量測文件的編號；S1 狀態表把編修說明寫進「印出的句子」欄 | 採納。前提 4 補上對應的小節；兩句編修說明搬到表格之後 |
| Not reported | `grep -rl` 其實會掃檔案內容 | 量測文件那一句改成「沒有任何內容進到輸出；沒有用 Read／cat 讀任何檔」 |
| 外部查證 | 使用者的兩個選擇 | 都是這個 session 裡 AskUserQuestion 的回答（「現在停」「留著」） |
| 外部查證 | 互動式 session 19 個／25 個都是 medium | 開工前提時量的，這一輪沒重跑 |
| 外部查證 | `P-med-1` 審查者秒數、`P-low-1` 約 3 分鐘 | 重跑 `stats.py` 得 198、83、193、103；`P-low-1` 所有紀錄首尾相差 169 秒 |
