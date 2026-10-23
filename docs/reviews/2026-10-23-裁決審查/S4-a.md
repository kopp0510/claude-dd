# S4-a — 驗證加速與抓錯數

## 派工

裁決者給審查者 A 的派工 prompt（共用說明加各自的方向檔，逐字）。範圍：`ac8fcfe..HEAD`。

````text
```
先用 Read 讀完這兩個檔，它們就是你的完整任務說明（共同說明 + 你的方向），照做：
1. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-common.txt
2. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-A.focus.txt
你是審查者 A。用繁體中文交回完整報告（含 Not reported、What I ran）。
```

### S4-rev-common.txt
```
你是 8 步開發迴圈步驟 4 的 code-review 審查者。repo：/Users/danlio/project/my_project/claude-dd（繁中專案）。被審範圍：`ac8fcfe..HEAD`（裁決審查設計文件 S4「驗證加速與抓錯數」：一次 claude -p 實驗的輸入腳本、輸出統計、量測文件新增一節、設計文件與計畫審查報告）。

## 讀什麼
- diff 檔：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-review-diff.txt
  （①整段 diff，第 1–775 行 ②步驟 3 simplifier 改動＝無 ③被改到的檔整檔帶行號，第 778 行起）。被改到的檔一律讀 diff 檔裡那一份；沒被改到的檔（例如 docs/reviews/ 舊報告、templates/global/CLAUDE.md、git 歷史）照常讀 repo / 用 git show。
  Read 工具不指定範圍一次最多 2000 行，這份 2237 行，請用 offset 分段讀完你負責的部分。
- 排除：`docs/measurements/2026-10-24-s4-outputs/reports/`（51 份當時審查者報告原文，是量測資料，不審它們的內容）；但量測文件引用它們的「檔名前綴 + 行號」是要審的宣稱，可以去讀那些檔核對。
- 專案規則：repo 根目錄 CLAUDE.md、各層 CLAUDE.md；寫文件的判準在 templates/global/CLAUDE.md §3.10（列舉不數、引用要能指到對的東西、不承諾別處行為、歸因可反證）。

## 已確認、不要重跑（附預期值）
- `python3 -I docs/measurements/2026-10-24-s4-inputs/test_leaky.py` → `11 / 11 []` exit 0（預期全過）
- `bash -n run.sh`、三支 .py `py_compile` → exit 0
- CI「迴圈步數第五方」本機跑 → 8 個 ✅、exit 0
- simplifier 沒改任何檔
- 實驗（14 發 claude -p）不可重跑：要花錢，快照與 log 在 session 暫存目錄已不可得。數字以 `docs/measurements/2026-10-24-s4-outputs/stats.jsonl` 為準。
- 主對話用 sed 印過這些引用原句（原句存在；但「這句是否真的構成命中」仍可質疑）：G2 各發 K1 引用、G3-new-1 ac0356:3 與 judge:23、G3-hk-2 abe0ae:3 與 judge:11、G3-old-2 a8c1fb:3、G3-new-2 aa6177:12、G3-hk-1 a3d3dc:18；db0af00/a4ed41f/ee68e72 用 git show grep 過對應句子存在。

## 你的職責
找漏洞、證明這次改動有錯（程式邏輯錯、數字對不上、引用指錯、宣稱說過頭、文件互相矛盾）。每條附證據（diff 檔行號或 repo 檔案行、grep / python 指令與輸出）；沒證據的不算。不要客套、不要「整體不錯」。
只用手上的資料判斷（repo、git 歷史、diff 檔、outputs/ 底下的檔）；需要外部查證的（例如 Claude Code 紀錄檔格式、Read 工具上限）列出來交回，不要自己去抓網路或讀 ~/.claude/projects/。
可以在 scratchpad 寫暫存 python 腳本做計算（用 python3 -I）。不准 commit、不准改 repo 裡任何檔、不准跑 claude。

## 交回格式
- 每條發現：級別（Critical / Important / Smells）｜位置（檔:行）｜內容｜證據（指令與輸出或原文）｜具體失敗情境｜建議改法
- Not reported：看過但判定不報的（含「既有問題」），各附一句理由
- What I ran：跑過的指令清單
```
### S4-rev-A.focus.txt
```
## 你的方向：A 程式碼正確性
審 `docs/measurements/2026-10-24-s4-inputs/` 的 prepare.py、stats.py、run.sh、test_leaky.py（diff 檔 ③ 段有帶行號的整檔）。重點：
- stats.py：whole_s 的計時（t0 只取父 session 紀錄、max 取所有層）是否會算錯；scan 的 last_text 是否真的是「最後一則 assistant text」；層級判定（spawnDepth、parentAgentId 與 a["id"] 的切片 `[6:-10]` 對不對）；作廢條件（permission_denials、最後一筆 result）；leaky() 的判定（`../` 例外會不會放過真的外爬、ROOT_ARG 漏掉什麼、replace 掉禁區句後會不會放過真的讀取）；leaky 只看工具「輸入」，而文件宣稱另掃了工具「結果」—— 那段程式在哪？
- prepare.py：快照建法（put_tree 清目錄、git archive、刪 docs/reviews）、make_diff（diff 檔是共用的：只在第一發產生 —— 不同發的快照 diff 會不會不同？）、`--diff-filter=d`、佔位替換順序（{BRIEF} 內容若含 `{SNAP}` 之類會不會被二次替換）。
- run.sh：`--add-dir "$s4/prompts" "$s4/$g"`、exit code 是否反映 claude 的結束碼（perl alarm + echo exit=$?）、set -u。
- test_leaky.py：有沒有鑑別力（把 leaky 改壞會不會紅）；exec split 的方式是否可靠；案例是否涵蓋文件宣稱的三次誤報。
- 量測文件 diff 檔第 201–225 行嵌的「讀到第幾行」腳本：Read 的 offset/limit 計算、沒 offset 時 2000 的假設、spawnDepth 篩選對 old 組。
```
````

## 發現

審查者 A 的報告原文（逐字）：

````text
Critical 0 / Important 3 / Smells 0 — 範圍：ac8fcfe..HEAD 的程式碼部分，也就是 `docs/measurements/2026-10-24-s4-inputs/` 底下的 prepare.py、stats.py、run.sh、test_leaky.py，加上量測文件裡嵌的「讀到第幾行」腳本（diff 檔第 201–246 行）

[Important] stats.py:533（diff 檔第 533 行）｜`leaky()` 先把整個 s4 換成 `<S4>` 再比對，所以 s4 底下的所有東西都被放行。但派工單 judge.txt:309、old-reviewer.txt:351 明文禁止讀「{S4} 底下別的東西」，兩者範圍不一致。
  證據：拿 `/S4` 當 s4，`leaky()` 對這幾個輸入都回 False：`cat /S4/logs/G2-new-1.jsonl`、Read `/S4/prompts/G2-new-1.txt`、`cd .. && ls`、`git -C .. log --all`、`T=$(mktemp -d); cat ../logs/G2-new-1.jsonl`。只有帶 `../` 而且不在 mktemp 指令裡的才會抓到。原因有兩個：LEAK 只認 `../` 不認裸的 `..`；第 536 行只要同一個指令出現 mktemp 或 /tmp/，就放過 `../`。
  失敗情境：第 2 批（例如 G2-hk-2）的審查者用 Bash 讀 `<s4>/logs/G2-*-1.jsonl`。那裡有第 1 批裁決者的報告，K1 的答案就在裡面。這種讀法 `leaky()` 不會報，量測文件第 149 行「洩題檢查沒有命中」照樣成立。工具結果那道掃描同樣換掉了「s4 工作目錄」，也看不到。run.sh:486 還用 `--add-dir "$s4/$g"` 把 diff.txt 開給舊組，舊組讀了它，這兩道檢查也都抓不到。
  建議：白名單只留該發自己的快照、prompts/<該發>*、`<s4>/<g>/diff.txt`（舊組不留），其餘 `<S4>/` 一律算命中；LEAK 補上 `(^|\s)\.\.(\s|$)`。第 149 行的宣稱要改成檢查實際涵蓋的範圍。

[Important] 2026-10-23-reviewer-real-sessions.md 第 149 行（diff 檔第 149 行）｜文件說「工具結果另外掃 `/Users/` 開頭的路徑……每一發只剩 1–2 筆」，但凍結的輸入目錄裡沒有這段程式。
  證據：`grep -n 'tool_result' stats.py` 沒有命中；`scan()`（stats.py:508–524）只讀 `type=="assistant"` 的 tool_use 輸入；`grep -rn tool_result docs/measurements/2026-10-24-s4-inputs/` 也是 0。
  失敗情境：輸入目錄的 CLAUDE.md 寫「量測文件的數字是用這一版輸入跑出來的」，可是「1–2 筆、全是禁區那句」這個結論沒有對應的程式，也沒附指令。後人照 stats.py 重跑只會得到工具輸入那一半，核對不了這句。這違反 §3.10「引用要能指到對的東西」。
  建議：把那段掃描的程式像第 201 行那支腳本一樣附在文件裡，或併進 stats.py；做不到就把這句改成「另跑、未保存」。

[Important] 量測文件嵌的腳本，diff 檔第 219–221 行｜「讀到第幾行」只看 Read 的輸入（offset/limit），不看 tool_result 有沒有失敗。報錯的 Read 也被算成讀到 `off+lim-1`。
  證據：腳本只走 assistant 的 tool_use、`i = b["input"]`，從來不讀 user 那邊的 tool_result 或 is_error。我在 scratchpad 用 prepare.py 重建了 diff 檔，G3 的 diff.txt 有 3024 行、252520 bytes。行數和文件寫的一致；大小接近 Read 的整檔大小／token 上限，這點推論自 Read 工具除了 2000 行之外還另有大小上限（有 allow_large 參數），沒有實測。
  失敗情境：如果 G3-hk-1、G3-hk-2 那幾次不帶 limit 的 Read 是因為超過 token 上限而報錯，它們一行都沒讀到。但腳本記成 2000/3024，第 184 行就寫成「讀到第 2000 行就停」。第 186 行 G4-new-1「3 個都用 Read 讀到最後一行」也是只從輸入推出來的。
  建議：用 tool_use_id 配對 tool_result，排除 is_error 的那幾次，或在文件註明「只算請求範圍，沒核對回傳」。

What I ran
- `python3 -I prepare.py . <scratchpad>/revA/s4 G2-new-1 G3-new-1 G4-new-1 G2-old-1` → 4 份快照建好。G2、G3、G4 的 diff.txt 分別是 1010、3024、1155 行（和文件一致）；第二段起點在第 204、250、311 行；G4 的 `----- scripts/check-claude-md.sh -----` 在第 971 行（和文件一致）
- 快照 `ls-tree` 與原 rev 的 `ls-tree` 比對（排除 docs/reviews/）→ G2、G3、G4 都一致；docs/reviews 只剩 CLAUDE.md；三段的 `diff --name-only` 檔案清單和 briefs.txt 寫的 4、8、3 檔相符
- `diff <(G2-new-1 的 diff) <(G2-old-1 的 diff)` → 相同（共用 diff 檔沒問題）
- `git show <6 個 rev>:.gitattributes | grep -c export` → 都是 0（git archive 不會少檔）
- scratchpad 的 revA_leak.py，對 10 個繞過輸入跑 `leaky()` → 9 個回 False（輸出見第一條）
- `grep -n 'tool_result\|is_error' stats.py`，以及對 inputs/ 的 grep → 沒有 tool_result
- 用 python 比對量測表 14 列和 stats.jsonl → 全部 OK
- 手算費用與倍數：合計 34.66、G2 整發 2.99 倍、G3 1.87 倍、費用 3.64 倍與 2.54 倍，haiku／新組 0.33 與 0.47，git 次數範圍 3–5 和 0–3 → 都和文件相符

Not reported
- stats.py 的 `[6:-10]` 切片：`agent-` 是 6 字元、`.meta.json` 是 10 字元，切法正確；而且 parentAgentId 對不上的話會產生錯誤，stats.jsonl 裡沒有。
- whole_s 的計時：t0 只取父 session、max 取所有層，邏輯正確；父層兩筆 result 的情況也處理到了。
- 佔位替換順序：brief 裡沒有大括號，而且最後有 assert 擋殘留佔位，不會二次替換。
- `--diff-filter=d`：正確，刪除的檔不能 `git show HEAD:`。
- run.sh 的 `$?`：拿到的是 perl exec 之後 claude 的結束碼，正確。
- test_leaky.py 的鑑別力：拿掉 ROOT_ARG、`../` 例外、反引號替換，各自會讓第 4、8／11、10 則變紅。`own` 的替換沒有測試涵蓋，但它只會造成誤報、不會漏報，所以不報。
- 舊組與裁決者的模型斷言對空的 models 會直接放行（`all([])` 為真），新組審查者有擋。這次每個 agent 都交出了文字，實際沒有出事，所以不報。
- split 出來的 `body.split("\n")` 會多編一行空行：只影響外觀。
- prepare.py 已經存在的 diff.txt 不會重產，換版本時可能用到舊的那份：屬於假設情境，沒有發生。

需要外部查證（我沒有去查）
- G3-hk-1、G3-hk-2 那些 offset/limit 為空的 Read，tool_result 是不是錯誤。讀各發 `~/.claude/projects/<編碼>/*/subagents/agent-*.jsonl` 的 tool_result 就能確定第三條的嚴重度。
- Read 的 offset 是 1-based 還是 0-based：這會決定腳本 `off+lim-1` 有沒有差一行。
- 父 session 紀錄的第一個時間戳是在 headless 開機前還是開機後：這會決定第 196 行「整發時間含 headless 開機」和第 127 行的定義有沒有矛盾。
- 有多筆 result 的發次（G2-new-2、G3-old-2、G4-new-1）裡，`total_cost_usd` 是不是累計值。stats.py 第 593 行的註解說 duration_ms 是每輪各算的。
- Claude Code 的 Bash 在 dontAsk 加 `--allowedTools Bash` 時，會不會擋 `cd ..` 或 cat 工作目錄以外的路徑：這會決定第一條的漏洞實際上能不能走到。
````

## 處置

修正在 1e209ef。編號對到 `S4-judge.md` 的「採納」清單。

- A1（`leaky()` 整個 `<s4>` 放行、不認 `..`）→ 裁決採納 3（Important）。`stats.py` 凍結不改；量測文件寫明缺口，補 `2026-10-24-s4-outputs/extra_checks.py` 的跨發掃描，14 發 0 筆
- A2（工具結果掃描沒有程式）→ 採納 2（Important）。同一支的 `res` 欄，結果寫進 `extra_checks.out`
- A3（讀行數只看請求）→ 採納 1（Important）。改用 `extra_checks.py` 的 `read` 欄配對回傳，量測文件與設計文件開放問題同批改
- 舊組讀了 diff 檔、檢查抓不到 → 駁回（補掃 0 次）；超過上限會整次報錯 → 駁回（實際是靜靜截斷）
