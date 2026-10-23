# S4-b — 驗證加速與抓錯數

## 派工

裁決者給審查者 B 的派工 prompt（共用說明加各自的方向檔，逐字）。範圍：`ac8fcfe..HEAD`。

````text
```
先用 Read 讀完這兩個檔，它們就是你的完整任務說明（共同說明 + 你的方向），照做：
1. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-common.txt
2. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-B.focus.txt
你是審查者 B。用繁體中文交回完整報告（含 Not reported、What I ran）。
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
### S4-rev-B.focus.txt
```
## 你的方向：B 量測文件數字對 stats.jsonl
逐格核對量測文件「新做法對照」一節（diff 檔 ③ 段量測文件第 124–262 行）的數字與 `docs/measurements/2026-10-24-s4-outputs/stats.jsonl`（repo 裡讀）：
- 原始數字表 14 列每一格（整發、費用、裁決者秒/工具、審查者數、最慢、每個審查者工具次數的順序）
- 「全部 14 發合計約 US$34.7」
- 結論 1：G2 約 335s 對 112s（3 倍）、G3 約 365s 對 195s（1.9 倍）、費用 3.6 倍與 2.5 倍、「裁決者耗時 314–352s，審查者層 164–235s」—— 範圍是否涵蓋了 haiku 組（hk 的 286、439）？說的是哪些發？
- 結論 3：「費用約新組的 1/3–1/2」
- 結論 4：審查者層新 164–235s 對舊 81–187s；「舊組每個審查者撈 git 3–5 次；新組與 haiku 組在 G2、G3 是 0–3 次」對照文件裡「當天輸出」那段
- G4 段：G2 1010 行、G3 3024 行、G4 1155 行；「G3 有 3 個審查者用 Read 讀到第 2000 行就停（G3-hk-1 1 個、G3-hk-2 2 個）」—— 對照當天輸出，G3-new-* 有沒有也停在 2000 附近被漏列？；G4 第 1 發「3 個都讀到最後一行」、第 2 發「4 個只讀約 310 行」
- 設計文件開放問題（diff 檔第 34–35 行）與 S4 列寫的數字是否與量測文件一致；「慢 1.9–3 倍、貴 2.5–3.6 倍」對的是新組還是含 haiku
- 作廢段：「3 筆都是審查者…用 --no-verify 或 -n」對照 stats.jsonl 的 permission_denials 實際內容（數筆數、看指令裡是否真有 --no-verify / -n）
- 設計文件 S4 一節的費用粗估「5×4 + 4×2 + 4×1.6」的組成是否對應實際發數
可以寫 python 讀 stats.jsonl 計算。
```
````

## 發現

審查者 B 的報告原文（逐字）：

````text
Critical 0 / Important 3 / Smells 0。範圍是 `ac8fcfe..HEAD`，方向 B：拿量測文件「新做法對照」一節的數字逐格對 `stats.jsonl`。

數字本身全對：14 列原始數字表每一格都和 stats.jsonl 一致（用腳本逐格比對，14 列都 OK）；合計 34.66，文件寫「約 US$34.7」；結論 1、3、4 和設計文件開放問題裡的倍數、範圍都對得上。下面三條問題都出在「宣稱說過頭」或「歸屬錯」，不是算錯。

[Important] diff 檔 1689 行（量測文件 :162）寫「3 筆都是審查者…用 `--no-verify` 或 `-n`」，其中 1 筆其實是裁決者的
  Failure：stats.jsonl 裡 G4-new-1 有 2 筆 denial、G4-new-2 有 1 筆，共 3 筆，三筆的指令裡也確實都有 `--no-verify` 或 `-qn`，這部分是對的。但 G4-new-1 第 2 筆的 description 是 "Reproduce reviewer-reported gate bypasses in temp repos"，指令裡的 `== A non-ASCII`…`== F base stale` 六個情境，跟 `reports/G4-new-1.d1.a1f012.G4-new-1-judge.md` 的「查證情境 A」(:37)、B (:32)、C (:71)、D (:43)、E (:26)、F (:27) 逐一對上（`中文/a.js`、`src/a.js`、`api/t.py`、`tmpx`、`--amend`、`lib/l.js`）。所以這筆是裁決者查證時被擋的，作廢理由「兩發都是審查者自己決定這樣測」只對一半。
  Evidence：`python3 -I b_check.py` 印出三筆 permission_denials 原文；`grep -n '情境 [A-G]' G4-new-1*` 的結果。
  建議改法：改成「2 筆是審查者、1 筆是裁決者查證時」。

[Important] 量測文件 :200、:202–203 與設計文件 :118 寫的「讀到第 2000 行就停」「讀到最後一行」是腳本自己假設出來的，不是觀察到的
  Failure：統計腳本 :236 寫 `lim = i.get("limit") or 2000`，算的是 Read 的請求範圍，完全不看 tool_result。只要 Read 不帶 limit，3024 行的檔一律算成 2000、1010 或 1155 行的檔一律算成「讀完」。所以「G3-hk-1 1 個、G3-hk-2 2 個停在 2000」「G4 第 1 發 3 個都讀到最後一行」其實就是把 :200 的前提「Read 最多讀 2000 行」代回腳本得到的結果，不能拿來佐證這個前提。如果 Read 對大檔回的是「檔案太大」之類的錯誤而不是截斷，這三格實際讀到的是 0 行，結論就反了。
  Evidence：diff 檔第 1999 段 stats 腳本，以及量測文件 :235–237 的程式碼。
  外部查證：去讀那幾發 `agent-*.jsonl` 裡不帶 limit 的 Read 呼叫的 tool_result，看是截斷的內容還是錯誤訊息。

[Important] 量測文件 :202–203 與設計文件 :118 寫 G4 第 2 發「4 個都只讀前段的 diff、沒讀整檔內容那段」，沒有照設計文件預先寫死的判準判
  Failure：設計文件 S4 一節的判準是「工具結果含該檔末段，或報告引到該檔後半的行」，量測文件實際用的只有 Read 的範圍。同一份文件 :262 自己承認用 `sed`／`cat` 讀的不算進去。而 G4-new-2 那 4 個審查者撈了 git 2、3、0、4 次（`git show`／`diff` 也能把 `scripts/check-claude-md.sh` 印出來），Reviewer D 也直接把快照裡的 `check-claude-md.sh` 拿出來跑（見 denial 原文 `cp $R/scripts/check-claude-md.sh`）。「沒讀整檔內容」這句的根據只有 Read 範圍，卻被拿去回答開放問題「讀不讀得完」。
  Evidence：當天輸出 :255 `G4-new-2 ['314/1155 git=2', '310/1155 git=3', '310/1155 git=0', '311/1155 git=4']`。另外我查過報告裡的引用：`check-claude-md.sh` 在 48de43f 只有 183 行，D 引的 :187–209 超出檔長，所以是 diff.txt 的行號；A 引到 :76。在報告引用這一層，4 個審查者都沒引到檔案後半，這一半判準反而支持原結論。
  建議改法：句子改成「沒用 Read 讀到整檔內容那段」，並寫明 tool_result 沒查。設計文件 :118 同批補上「只算 Read」的限定。

已核對、沒有問題的：
- 結論 1 的「314–352s」「164–235s」只涵蓋新組 G2、G3 那 4 發（裁決者 321、314、341、352；最慢審查者 179、164、210、235），沒有含 haiku 組的 286、439。結論 1 的標題就是「新做法比舊做法」，所以範圍沒錯。
- 「慢 1.9–3 倍、貴 2.5–3.6 倍」說的是新組對舊組：時間 2.99 與 1.87 倍，費用 3.64 與 2.54 倍。換成 haiku 組，時間是 2.79 與 1.94 倍，費用只有 1.2 倍，所以這句不能套到 haiku 組，文件也沒這樣套。
- 結論 3「費用約新組的 1/3–1/2」：G2 0.33、G3 0.47，用平均算；逐發比是 0.30–0.67。
- 結論 4：舊組最慢審查者 102、81、187、168，即 81–187；舊組撈 git 4、4、4、3、4、5、5、3 次，即 3–5；新組與 haiku 組在 G2、G3 最多 3 次。
- G4 段：diff 檔行數 1010、3024、1155 都和當天輸出一致。G3-new 那幾發讀到 2079、1718、1642、1700、250、1701，沒有一個剛好停在 2000，所以文件沒有漏列。

Not reported
- 費用粗估「5×4 + 4×2 + 4×1.6」：它的組成對應計畫的 5 新、4 haiku、4 舊共 13 發。實際是 14 發，多出來的是 G4 作廢後重跑的那一發，而且這段已標成「推論」，不報。
- `cost` 與 `api_s` 只取最後一筆 result（G2-new-2、G4-new-1 有 2 筆，G3-old-2 有 3 筆）。stats.py :99 自己寫了 duration_ms 是各輪分開算的，total_cost_usd 是不是累計值，手上的資料判斷不了，列為外部查證：讀這三發父 log 的每一筆 result，比 total_cost_usd 有沒有遞增。同組各發的費用相近（3.33 對 3.40、3.50 對 4.36），看起來是累計，所以不報。
- 結論 4 沒提 haiku 組在 G3 的最慢審查者（158、106）比舊組（187、168）快。文件那句只講新組，不算錯。
- 量測文件 :162 引用的 tool_result 原文「PreToolUse:Bash hook error…」不在 stats.jsonl 裡，我沒辦法核對。

What I ran
- `sed`／`grep -n` 讀 diff 檔：①段第 1–120 行、③段量測文件第 1650–1790 行、stats.py 第 1997–2111 行 → 取得文件內容
- `head`、`wc -l docs/measurements/2026-10-24-s4-outputs/stats.jsonl` → 14 筆
- `python3 -I /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/b_check.py`（逐格比對表格、算合計、平均、倍數，印出 denial）→ 14 列都 OK、合計 34.66、G2 2.99／3.64、G3 1.87／2.54、hk 對新組費用 0.33／0.47、denial 共 3 筆
- `grep -n -i 'no-verify|重現|情境…' reports/G4-*` → G4-new-1 裁決者的「查證情境 A–F」與 denial 第 2 筆的指令一一對應；G4-new-2 那筆是 Reviewer D 的（rebase-local-base、跑 1000 個 commit 那組）
- `grep -o 'check-claude-md\.sh:[0-9-]*|diff\.txt:…' G4-new-2.d2.*`，以及 `git show 48de43f:scripts/check-claude-md.sh | wc -l` → 183 行，報告最多引到檔案的 :76
````

## 處置

修正在 1e209ef。編號對到 `S4-judge.md` 的「採納」清單。

- B1（3 筆 denial 不全是審查者）→ 採納 7（降 Smells）。改成「G4-new-1 有一筆是裁決者發的」
- B2、B3（讀行數的數字）→ 採納 1（Important），同 A3 的修法
- 其餘數字核對全部一致，不用改
