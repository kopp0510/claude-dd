# S4-d — 驗證加速與抓錯數

## 派工

裁決者給審查者 D 的派工 prompt（共用說明加各自的方向檔，逐字）。範圍：`ac8fcfe..HEAD`。

````text
```
先用 Read 讀完這兩個檔，它們就是你的完整任務說明（共同說明 + 你的方向），照做：
1. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-common.txt
2. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-D.focus.txt
你是審查者 D。用繁體中文交回完整報告（含 Not reported、What I ran）。
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
### S4-rev-D.focus.txt
```
## 你的方向：D 文件宣稱、交叉引用與結論有沒有說過頭
審設計文件 S4 節與開放問題（diff 檔第 15–97 行與 ③ 段）、量測文件新節的文字宣稱（非逐格數字）、三份 plan-S4-r*.md、inputs/CLAUDE.md、根目錄 CLAUDE.md 那一行。重點：
- 計畫（設計文件 S4 節，跑之前寫死的）與實際做法/文件的落差有沒有照實寫：例如計畫說整發取「最後一筆 result 的 duration_ms」，stats.py 改成時間戳；計畫說機械檢查掃工具「結果」的絕對路徑，stats.py 只看輸入；計畫說 brief grep 答案片段的結果「附進量測文件」—— 有附嗎？計畫說「答案先對到程式碼…寫進命中判準」有寫嗎？計畫說「G4 1 發」，實際 2 發；計畫的費用粗估「5×4」；計畫說斷言 `git log --oneline | wc -l` 等於 2。逐條列「計畫寫了、實際沒做或沒記」的
- commit hash 宣稱：db0af00、a4ed41f、ee68e72、7b4bd74、1f5ae2a、3f474dc、8478a4b、ee68e72 與 K 的對應；G2/G3/G4 範圍與「4 檔 +111/−18」「8 檔 +124/−7」「3 檔 +231/−16（最大）」（用 git diff --shortstat 核）；`git ls-tree -r --name-only 8514fb2` 帶著 G2 答案那句
- briefs.txt 寫的檔案清單是否等於各範圍 `git diff --name-only`；brief 的驗證數字（90 ✅ / 81、105 ✅ / 90、16 個 step）與舊報告／commit 訊息是否一致（用 git show 那些 commit 或讀 docs/reviews 舊報告的派工節）
- 結論是否說過頭：例如「haiku 審查者沒有比 Opus 審查者少抓」在 n=2、3 個錯誤下的措辭；「多出來的主要是裁決者那一層」的歸因（§3.10 歸因要能被反證）；結論 4「附帶觀察」；開放問題那兩條的摘要是否忠於量測文件
- 交叉引用：量測文件引用的路徑（`2026-10-24-s4-inputs/stats.py` 這種相對路徑在文件所在目錄是否成立）；inputs/CLAUDE.md 的描述（例如 stats.py「洩題」作廢、test_leaky「該抓的、誤報各幾則」）與程式是否一致；inputs/CLAUDE.md 說 outputs 有「每個 agent 最後一則文字」—— 檔名格式對嗎
- 進度表 S4 列（IN_PROGRESS、`ac8fcfe..`）與規則區塊是否一致；根目錄 CLAUDE.md 那行
- plan-S4-r*.md 的處置是否與最終設計文件一致（例如 r2 說「stdout 存 out.jsonl」而最後是 logs/<發代號>.jsonl；r2 說「機械檢查改成工具輸入出現…絕對路徑」而設計文件寫工具「結果」）
```
````

## 發現

審查者 D 的報告原文（逐字）：

````text
Critical 0 / Important 7 / Smells 0。審查範圍是 `ac8fcfe..HEAD`，方向 D：文件宣稱、交叉引用、結論有沒有說過頭。

這次最要緊的兩條是第 1 條和第 4 條：一條是洩題檢查「沒有命中」說過頭了，一條是 G4／G3「讀到第幾行」的量法跟文件寫的不是同一件事。

[Important] 1｜stats.py:533 `leaky()`、量測文件 diff 檔:149、設計文件 diff 檔:67–69
- 內容：機械檢查把整個 `<s4>` 前綴換成 `<S4>` 才去比對，所以讀「別發」的 log、快照、prompt 都不會被抓到。計畫審查 r3 第 4 條已經採納「別發的 log 放在 s4/ 底下會被白名單放行」，處置寫「15 條小事全部寫進設計文件」（diff 檔:773）。但程式沒改，設計文件也只寫了「在快照外」（diff 檔:68）。
- 證據：我在 scratchpad 跑 revD/t.py，`leaky("/S4", …)` 對下面五種輸入全部回 False：`/S4/logs/G2-old-1.jsonl`、`/S4/G2-old-1/scripts/CLAUDE.md`、`/S4/prompts/G2-old-1.txt`、`cat /S4/G3/diff.txt`、`../../S4/logs/a.jsonl`。test_leaky.py 裡沒有任何一則「同一個 s4 底下的別發路徑」該判洩題的案例。
- 失敗情境：批次是依序跑的。第 2 批的 agent 可以讀到第 1 批同一段的裁決者報告（`logs/G2-new-1.jsonl` 的 tool_result 裡就有答案），檢查照樣綠。量測文件:149 說「洩題檢查沒有命中」，這句的涵蓋範圍比實際的判定式大。
- 建議：白名單收窄成「該發自己的快照、`<s4>/<段>/diff.txt`、`<s4>/prompts/<該發>*`」，補一則負面測試。量測文件的結論要照實寫明這個缺口。

[Important] 2｜量測文件 diff 檔:146
- 內容：文件寫「3 筆都是審查者在拋棄式 repo 測 gate 時…」和「兩發都是審查者自己決定這樣測」，但 G4-new-1 第 2 筆 denial 是裁決者自己下的查證指令。
- 證據：stats.jsonl:13 第 2 筆 denial 的 description 是 `Reproduce reviewer-reported gate bypasses in temp repos`，指令裡有六個情境：A non-ASCII、B merge commit SKIP、C teammate commit、D deleted dir、E amend w/o base、F base stale。`reports/G4-new-1.d1.a1f012.G4-new-1-judge.md` 的 :26、:27、:32、:37、:43、:71 逐條寫「查證情境 E／F／B／A／D／C」，內容跟那六個情境一一對上。:29 還寫「我另外跑了情境 G」。
- 失敗情境：讀者會以為新做法的審查者層才是撞 gate-guard 的來源。「再跑也會撞同一道擋」這個不重跑的理由，有一部分是建立在錯的歸屬上。
- 建議：改成「3 筆裡 2 筆是審查者、1 筆是裁決者查證時」，或改成「層別沒有從 log 確認」。

[Important] 3｜設計文件 S4 節（diff 檔:69、71、79、82、85、87、91）跟實際做法的落差沒有照實記
同一節的 diff 檔:75 有用「（實跑時改的：…）」標明改過的地方，所以有前例；下面這幾處卻沒標：
- a. 計畫:79 整發時間取「最後一筆 result 的 `duration_ms`」。stats.py:592–595 改成用時間戳算，理由只寫在程式註解裡。設計文件沒改；量測文件:127 只給了新定義，沒說偏離了計畫。
- b. 計畫:69 寫掃工具「**結果**」裡的絕對路徑，stats.py:580–585 只掃工具輸入。計畫審查 r2 的處置（diff 檔:726）寫的本來就是「工具輸入」，所以是設計文件跟 r2 互相矛盾。量測文件:149 說「工具結果另外掃…每一發只剩 1–2 筆」，但那支腳本不在 repo 裡，違反計畫:95「數字由腳本產生並附指令」。
- c. 計畫:71、91 寫 G4 只跑 1 發，實際跑了 2 發（stats.jsonl:13–14），設計文件沒標。
- d. 計畫:85 寫 brief 的答案片段 grep「結果附進量測文件」。我跑 `grep -n '從未執行到\|查不到出處\|3 紅\|正常流程唯一\|pre-commit 不查報告\|判準相反\|brief' docs/measurements/2026-10-23-reviewer-real-sessions.md`，只命中命中表自己的列（:175、:176、:182），沒有 grep 結果。
- e. 計畫:87 寫「答案先對到程式碼…寫進命中判準」。計畫:88 的判準和量測文件都沒有這份對照（我 grep `答案先對到`，只命中計畫:342 自己）。
- f. 計畫:91 的 G4 判準還有「報告引到該檔後半的行」和「有沒有截斷或未讀完字樣」，量測文件:186 只用了 Read 的範圍。
- g. 計畫:82 寫「第一發核對 `total_cost_usd` 有沒有涵蓋背景子代理」，r2 的處置也寫「第一發實跑時核對」（diff 檔:730）。量測文件:127 只寫「（含子代理）」，沒有附核對的根據。

失敗情境：設計文件的檔頭寫「跑之前寫死」，讀者照設計文件重做或判讀，會拿到跟數字不一致的方法。
建議：在 S4 節用「實跑時改的」逐條標出來；d、e 兩條要嘛補上，要嘛寫明沒做。

[Important] 4｜量測文件 diff 檔:184–187、:233–238，設計文件 diff 檔:35
- 內容：「讀到第幾行」那支腳本（diff 檔:219–221）只看 Read 的 tool_use **輸入**（offset＋limit，沒給 limit 就假設 2000），不看 tool_result。所以它量到的是「請求的範圍」，不是「實際讀到的範圍」。Read 除了 2000 行，還有 token 上限：超過時整次呼叫報錯、一行都不給。
- 證據：
  - 我這個 session 用 Read 讀 diff 檔前 780 行（73033 bytes），回的是 `File content (35799 tokens) exceeds maximum allowed tokens (25000)`。
  - 我照 prepare.py 重建三份 diff 檔（revD/regen.py）：G2 1010 行、69124 bytes；G3 3024 行、252520 bytes；G4 1155 行、66084 bytes。大小都跟會報錯的那 73KB 同一個量級或更大。
  - 文件寫「G4 第 1 發 3 個審查者都用 Read 讀到最後一行」、G2 的「1010/1010」，可能只是一次失敗的、不帶 limit 的 Read。G3 那 3 個「停在第 2000 行」的審查者，很可能拿到的是錯誤訊息，不是 2000 行。
  - 量測文件:185 自己有寫「沒驗證」，但設計文件:35 的開放問題摘要把這個但書拿掉了，直接寫「第 1 發 3 個審查者都讀到 diff 檔最後一行」「有 3 個審查者停在第 2000 行」。
  - 量測文件:246「haiku 組的 0/… 多半是用 Bash 的 sed／cat 讀」沒有任何輸出支撐，是 §2.4 禁止的模糊詞。
- 失敗情境：開放問題「大 diff 讀不讀得完」的答案被當成已經量到，後續可能據此決定 diff 檔不用切段。
- 建議：措辭改成「請求讀到第 N 行（沒核對工具結果是否成功）」；設計文件:35 補回「沒驗證」；:246 改成「沒統計」，或補上統計 sed／cat 的指令。

[Important] 5｜設計文件 diff 檔:55、量測文件 diff 檔:192：「K3 對應 a4ed41f」指錯了第一次寫進去的 commit
- 證據：我跑 `git log -S '要記「哪個變異' -- templates/global/CLAUDE.md`，最早是 713038a（2026-10-07 16:02，「全域迴圈補兩條 + S4 的報告落地」），diff 第 46 行加了「變異測試的『紅數』不是證據 —— 要記『哪個變異 → 哪幾個情境變紅』」。a4ed41f（10-09）只是改寫成現在的措辭。`git merge-base --is-ancestor b66d8ae 713038a` 成立。
- 失敗情境：要追「教訓什麼時候進全域規則」的人會拿到晚了兩天、而且是蒸餾改寫的那個 commit。「都用 `git log -S` 查過」的結果是被搜尋片語的選擇決定的，正是 §3.10「歸因要能被反證」要防的情況。污染的結論不受影響，兩個 commit 都在 G2 之後。
- 建議：改成「K3 ← 713038a（a4ed41f 改寫）」。

[Important] 6｜量測文件 diff 檔:172（結論 1 的歸因）
- 內容：文件寫「裁決者耗時 314–352s，其中審查者層只佔 164–235s，剩下的是裁決者自己讀 diff、派工、**等待**、逐條查證」。「等待審查者」本來就屬於審查者層，放進「剩下」自相矛盾。而且 `rev_max_s` 是單一審查者自己的耗時（stats.py:591），不是「第一個派出到最後一個回來」的跨度，所以「剩下」裡混著審查者的排程時間，分不出裁決者自己的工作量。
- 證據（用 stats.jsonl 算）：G2 整發差 223s，其中審查者層差 80s（171.5 對 91.5），約 36%；G3 整發差 170s，其中審查者層差 45s，約 26%。「主要」在數字上站得住，但「剩下的是裁決者自己…」反證不了。
- 建議：刪掉「等待」，改成「剩下的含裁決者自己的工作，以及審查者沒有同時開跑的空檔（沒拆）」。

[Important] 7｜量測文件 diff 檔:167：K3 參考列的機制換掉了，引用的「命中」跟跑之前寫死的 K3 不是同一個機制
- 內容：K3 原句（`docs/reviews/2026-10-07-review-followups/S4-a.md:40`）的機制是「寫死 3／7／2 紅，耦合到斷言數，違反 tests/CLAUDE.md 不寫 N 項」。量測文件把 K3 改寫成「寫死紅數、**沒記哪個變異讓哪幾則變紅**」，引用的三處都是後面那個機制，或者是第三種：
  - `G2-hk-1.d1` :19：「只寫了語意、沒寫插在哪一行」
  - `G2-old-1.d1.a594bb` :8：「沒寫哪個變異讓哪幾個情境變紅」
  - `G2-new-1.d1` :22：同上
- 失敗情境：跑之前寫死的判準是「同一個位置且同一個機制」（diff 檔:88）。照判準，這幾處算「沾邊」，不算「抓到」。參考列雖然不計分，但「haiku 第 1 發採納」這種說法會被引用。
- 建議：K3 的描述照 S4-a.md:40 原句寫，三處改列成「沾邊」。

Not reported
- shortstat「4 檔 +111/−18」「8 檔 +124/−7」「3 檔 +231/−16」：用 `git diff --shortstat` 核過，正確。briefs.txt 的檔案清單也等於快照的 `git diff --name-only`，三段都對。
- `git ls-tree -r --name-only 8514fb2` 確實帶著 `review-followups/S4-a.md`、`S4-b.md`。7b4bd74、1f5ae2a 跟 K4 無關，屬實。db0af00、ee68e72 是 K2、K6 最早寫進去的 commit，屬實。8478a4b 是 48de43f 的後代，同一天。
- brief 的 90／81、8、105／90、16 個 step 跟舊派工節（S4-a.md:11、S1-a.md:7–9）、b66d8ae 的 commit 訊息一致。G3 brief 拿掉了 m1／m3 變異那句，符合「拿掉指向特定錯誤的字句」。
- 這些數字都核過、對得上：diff 檔行數 1010／3024／1155、G4 第一段到第 310 行、check-claude-md.sh 從第 971 行開始、費用合計 34.66、倍數 3／1.9／3.6／2.5、git 次數 3–5 對 0–3、報告 51 份、K1／K5 命中表合計 3／3／3、K2 和 K6 引用的行。
- 結論 3「haiku 沒有比 Opus 少抓」：同一節有「只是這批的觀察」，結論 2 也寫了分不出差異，措辭夠保守，不報。
- 進度表 S4 列（IN_PROGRESS、`ac8fcfe..`、有 S4-1 小任務）符合規則區塊；根目錄 CLAUDE.md 那行跟計畫:93 一致。
- 計畫的費用粗估「5×4」是照計畫的 G4 1 發算的，合理；實際多跑一發，已經算在第 3 條 c。
- r2 寫 `out.jsonl`、最後改成 `logs/<發代號>.jsonl`：是後續輪次的修正，本身不算錯；它延伸出來的白名單問題在第 1 條。
- reports/ 原文的內容不審（照派工排除）。

需要外部查證（我沒去抓）
- 審查者那次 Read 的 tool_result 是否成功、拿到幾行：要讀當時 `~/.claude/projects/<快照編碼>/…/agent-*.jsonl` 的 tool_result，這能決定第 4 條。依量測文件:198，那些紀錄已經不可得。
- Read 工具在 subagent 裡的 token 上限是否同樣是 25000：要看 Claude Code 的文件或實測。

What I ran
- `git diff --shortstat` 加 `--name-only` 對三個範圍 → 4／111／18、8／124／7、3／231／16，清單跟 briefs 一致
- `git log -1` 查 db0af00、a4ed41f、ee68e72、7b4bd74、1f5ae2a、3f474dc、8478a4b、48de43f → 日期和主旨如上
- `git log -S` 查 K2、K3、K6 的片語，以及「那只證明」「連共同祖先都沒有」「pre-commit 不查」「正常流程」 → db0af00、a4ed41f、ee68e72、ee68e72；0；0；7b4bd74 與 1f5ae2a
- `git log -S '要記「哪個變異'`，加上 `merge-base --is-ancestor b66d8ae 713038a` → 713038a，在 G2 之後
- `git ls-tree -r --name-only 8514fb2 | grep review-followups/S4` → S4-a.md、S4-b.md
- `python3 -I revD/regen.py`（照 prepare.py 重建快照與 diff 檔）→ 行數 1010／3024／1155，段落起始行如上
- `wc -c` 三份 diff 檔，以及 `head -780 S4-review-diff.txt` → 69124／252520／66084；73033
- `python3 -I revD/t.py`（用 leaky 測別發的路徑）→ 5 則全部 False
- `sed -n` 印 reports 的引用行（G2 各裁決者 :11／:12／:19／:22／:41／:46、ae62d9:7、a594bb:8、G3-hk-1 judge:17、aa6177:8、G3-new-1 judge:23、ac0356:3–6、G3-hk-2 judge:11）→ 內容如上
- 讀 S4-a.md:23／34／40、S1-a.md:20／27、S1-b.md:13／22 → K1–K6 原句
- `grep` G4-new-1 的裁決者與 C 報告找「情境 A–G」→ 裁決者查證 A–F
- `grep` 量測文件找 brief 答案片段，`grep` 設計文件找「答案先對到」→ 只有命中表列與計畫:342
- `grep` K4 的各種寫法在 G3-* → 只命中 a3d3dc:18、abe0ae:5
- `git show` 舊報告派工節與 b66d8ae／8514fb2 的 commit 訊息 → 90／81、105／90、16 一致

暫存檔：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/revD/regen.py、/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/revD/t.py
````

## 處置

修正在 1e209ef。編號對到 `S4-judge.md` 的「採納」清單。

- D1 → 同 A1；D2 → 同 B1；D3（計畫寫死的做法實跑偏離沒標）→ 採納 4（Important），設計文件 S4 節逐條加「實跑時改的」或「實跑時沒做」，brief grep 補跑（0 筆）
- D3b → 同 A2；D4 → 同 A3，末項 haiku 讀法改成「沒數」（採納 11，Smells）
- D5（K3 第一次寫進全域是 713038a）→ 採納 9（Smells），量測文件與設計文件都補上
- D6（結論 1「等待」措辭）→ 採納 10（Smells），改成「各審查者開跑時間的落差」
- D7 → 同 C3
