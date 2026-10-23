# S4-c — 驗證加速與抓錯數

## 派工

裁決者給審查者 C 的派工 prompt（共用說明加各自的方向檔，逐字）。範圍：`ac8fcfe..HEAD`。

````text
```
先用 Read 讀完這兩個檔，它們就是你的完整任務說明（共同說明 + 你的方向），照做：
1. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-common.txt
2. /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S4-rev-C.focus.txt
你是審查者 C。用繁體中文交回完整報告（含 Not reported、What I ran）。
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
### S4-rev-C.focus.txt
```
## 你的方向：C 命中表與參考段的引用逐條核對
量測文件「命中」與「參考」與「結論 5」「限制」裡每一個 `<檔名前綴> :<行>` 引用（例如 `G2-new-1.d2.a79b15` :3、judge :12），到 `docs/measurements/2026-10-24-s4-outputs/reports/` 找對應檔（judge 指同一發的 `.d1.*judge.md`；舊組 judge 不存在），用 `sed -n '<N>p'` 印出那一行，判斷：
1. 行號指到的那句是否就是宣稱的內容（§3.10：數字對了不等於指的東西對了）
2. 是否符合設計文件寫死的命中判準：「同一個位置（同一檔、同一個測試情境或同一段文字）且同一個機制（為什麼錯）」。K1/K4/K5 的正確答案原文在 repo 的 `docs/reviews/2026-10-07-review-followups/S4-a.md:23`、`docs/reviews/2026-10-18-pstack-gaps/S1-a.md:20`、`S1-b.md:13`，先讀它們。
3. 未命中的格子：用 grep 在該組該發所有報告找有沒有其實命中、卻被判成沒抓到的（尤其 K5 在 G3-new-2、G3-hk-1、G3-old-1；K4 全部）。反之找判成命中但其實機制不同的。
4. 「採納」欄：裁決者是真的採納（列在【採納】段）還是在駁回／外部查證段？看 judge 檔那行所在的段落標題。
5. 參考段 K2/K3/K6 的宣稱（「6 發每一發都有人抓到」「新、haiku 各兩發的裁決者都採納」「舊組沒抓到」等）逐條核。
6. 結論 5「把審查者丟進 Not reported 的項目撈回來（G2-new-2 judge :46）」「K6 在 G3-hk-1 是裁決者自查補上的（judge :17，C 的 Not reported 提過一半）」。
7. 限制段「新做法多抓到的真問題（G2 的 ⑩ said 分不出誰印的、G3 的 §3.5 對新功能沒有判準）」有沒有出處。
```
````

## 發現

審查者 C 的報告原文（逐字）：

````text
Critical 0 / Important 4 / Smells 1 — 範圍：`ac8fcfe..HEAD` 的量測文件 `docs/measurements/2026-10-23-reviewer-real-sessions.md`「新做法對照」一節，核對命中表、參考段、結論 5、限制段的引用（方向 C）

下面的行號：量測文件用 repo 檔的行號（等於 diff 檔行號 + 16），reports 用 `docs/measurements/2026-10-24-s4-outputs/reports/` 底下的檔名前綴加行號。

[Important] 量測文件:213（diff 檔:197）｜限制段把「G2 的 ⑩ `said` 分不出誰印的」和「G3 的 §3.5 對新功能沒有判準」舉成「新做法多抓到的真問題」。這兩個例子都不成立。
- 證據：
  - ⑩ 那條在當時的正確答案裡就有：`docs/reviews/2026-10-07-review-followups/S4-a.md:59` 寫「3. ⑩ 的 `said "改從共同祖先"` 無法分辨是哪個呼叫端印的」；`S4-b.md:43` 也有。
  - 這次的舊組也看到了 ⑩，只是放進 Not reported：`G2-old-1.d1.a594bb` :21、`G2-old-2.d1.a67862` :14、`G2-old-2.d1.a0166b` :16。
  - §3.5 新功能那條受全域規則污染，跟 K6 同一類。`docs/reviews/2026-10-18-pstack-gaps/S1-a.md:56` 寫「『新功能還沒寫時先放回錯值的空殼』是我照這個判準推出來的」，`git log -S '新功能還沒寫' -- templates/global/CLAUDE.md` 回 ee68e72。抓到它的審查者自己也承認：`G3-new-2.d2.ae16a9` :11 寫「這次對話開頭載入的全域 CLAUDE.md §3.5 已經是後來修過的版本，多了『新功能還沒寫時…』」。另外 `G3-hk-2.d2.a31c92` :3 是 haiku 組，不是新組。
- 失敗情境：讀者會以為新做法有命中表以外的額外收穫，實際上一條舊做法也抓得到，另一條是洩題。
- 建議：換成真的只有新組抓到、又沒被污染的例子；找不到就刪掉這個括號。

[Important] 量測文件:181（diff 檔:165）與 :195（diff 檔:179）｜K6 參考段寫「6 發每一發都有人抓到」，結論 5 寫「K6 在 `G3-hk-1` 是裁決者自查補上的」。實際上 haiku 組兩發都沒有任何審查者抓到 K6，兩發都是裁決者自己補的。
- 證據：
  - `G3-hk-2.d1.ac21da` :14 寫「2. 裁決者自查｜Important｜§3.5 新增的括號…verification-gate 新寫的 `git stash -u`…」。
  - `G3-hk-2` 四個審查者都沒報 K6：`grep -n 'stash\|3\.9\|鑑別\|第三種' G3-hk-2.d2.*` 只命中 a31c92 :9「…轉述忠實，未發現矛盾」與 abe0ae :8（講的是別的事）。
  - `G3-hk-1.d2.aad426` :7 明寫「不算矛盾」。
- 失敗情境：
  - 照命中表「聯集＝審查者原始報告」的定義，K6 是新組 2/2、舊組 2/2、haiku 0/2。「每一發都有人抓到」把裁決者算進「有人」，蓋掉了這個差異。
  - 這正是結論 3「haiku 審查者沒有比 Opus 審查者少抓」的反例，雖然它只是參考資料。
  - 結論 5 證明裁決者有用的證據也少算了一半。
- 建議：K6 改寫成「審查者聯集：新 2/2、haiku 0/2、舊 2/2；haiku 兩發都是裁決者自查補上（`G3-hk-1` judge :17、`G3-hk-2` judge :14）」。結論 5 同批改，結論 3 補一句「參考用的 K6 上 haiku 審查者 0/2」。

[Important] 量測文件:183（diff 檔:167）｜K3 寫「新組第 1 發併在 K1 的連帶影響裡（judge :22）」，指錯了。judge :22 屬於第 2 條（⑩ 的 `said`），不是第 1 條（⑪，也就是 K1）。
- 證據：
  - `G2-new-1.d1.a01928` :12 是「1. …⑪…沒跑到 `reviews_missing`」，也就是 K1。
  - :20 是「2. A、B 都報｜Important｜⑩ 的 `said "改從共同祖先"`…」，:22 是它底下的「連帶影響：…也沒寫『哪個變異讓哪幾則變紅』」。
  - 審查者 `G2-new-1.d2.abdceb` :22 自己就報了這句，不只裁決者。
- 失敗情境：這是 §3.10 說的「數字對了、指的東西不對」。複核的人讀 K1 那條會找不到 K3。
- 同一句的其他問題：
  - 新組第 2 發其實也碰到了：`G2-new-2.d2.ab6459` :32 寫「變異紅數『3／7／2 紅』沒有記『哪個變異讓哪幾則變紅』」，在 Not reported。
  - haiku 第 2 發也碰到了：`G2-hk-2.d2.a21bd9` :17 寫「文件只給計數、沒列出哪些情境變紅」，在 Not reported。
  - haiku 第 1 發 judge :19 的機制是「沒寫插在哪一行」，不是 K3 原文（`S4-a.md:40`）講的「紅數耦合斷言數、寫死」。照「同一個機制」的判準，算它「採納」說過頭了。

[Important] 量測文件:213（diff 檔:197）對照命中表 K5 那列 :176｜限制段寫「未命中但沾邊的列在『參考』」，設計文件也要求「判成未命中但沾邊的也列原句，交步驟 4 複核」（diff 檔:90）。但參考段只列了 K2、K3、K6，K5 的沾邊原句一句都沒列。
- 證據：好幾份報告都寫下了 K5 的症狀：變異下繞過① 變紅，是從前面「建立 docs/reviews/ 那個 commit」連鎖紅過來的。只是沒推到「單獨跑不會紅」那一步。
  - `G3-new-2.d1.a148f0` :37
  - `G3-new-2.d2.aa6177` :18、:24
  - `G3-hk-1.d2.ae9ad9` :9
  - `G3-hk-1.d2.a3d3dc` :13
  - `G3-old-1.d1.a2e1e9` :18
  - `G3-old-1.d1.a9ea9b` :16
- 失敗情境：G3-new-2、G3-hk-1、G3-old-1 三格判「沒抓到」，沒有交出可以複核的沾邊證據，「判準寫死、未命中也可複核」這個宣稱是空的。
- 判斷：我同意這三格都不算命中，機制推論缺了一步。但要照自己寫的規則把原句列出來。

[Smells] 量測文件:213｜限制段的兩個「新做法多抓到」例子沒附位置，命中表與參考段每格都附了。例如 ⑩ 可附 `G2-new-1` judge :20，§3.5 可附 `G3-new-2` judge :20、`G3-hk-2` judge :19。若照第一條改掉例子，這條就不用處理。

Not reported（核過、判定成立，不報）：
- K1 八格的原句與機制都對。引用行都指到 ⑪；Failure 行都寫了 `rm -rf … docs` 讓 `[ -d docs/reviews ] || return 1` 提早回傳，加上 `said` 被 `owed_dirs` 那句滿足。四個 judge 行都在【採納】段內（G2-new-1 :12 在 11–41；G2-new-2 :12 在 11–51；G2-hk-1 :11 在 10–30；G2-hk-2 :12 在 11–33）。
- K5 命中三格：`G3-new-1.d2.ac0356` :3–5、`G3-hk-2.d2.abe0ae` :3–4、`G3-old-2.d1.a8c1fb` :3–6，機制都是「HEAD==base → :165 return 1，紅是連鎖」，和 `S1-b.md:13` 一致。judge :23（G3-new-1）、:11（G3-hk-2）都在【採納】段。
- K5 判未命中的引用 `G3-new-2.d2.aa6177` :12（「繞過①：放行成立」）指得對。
- K4 全部沒抓到，這個判斷正確。照文件給的 grep 再加 `正常流程|gate 端|三句|range_base|head_sha^` 掃，沒有一行說繞過② 和正常流程的覆蓋重疊。`G3-hk-1.d2.a3d3dc` :18 的原句也指得對。
- K2 各格：`G2-new-2` judge :41 在【採納】且降成 Smells；`G2-new-1` judge :53 在【需要外部查證】；`G2-hk-1.d2.ae62d9` :7 加 judge :47 在外部查證；舊組 grep `預言` 0 命中。都成立。
- K3 舊組 `G2-old-1.d1.a594bb` :8 的原句指得對。
- 結論 5 的 `G2-new-2` judge :46 是「B（他放在 Not reported，我採納）」，成立。「K1/K4/K5 沒有一個是裁決者自己補的」也成立。`G3-hk-1` judge :17 確實是「裁決者（C 的 Not reported 提過一半）」。不過 C 的 :7 原話是「不算矛盾」，說「提過一半」偏寬，因為這句是照抄裁決者的話，不另報。
- K6 新組、舊組四發的審查者原句都在：G3-new-1 a4bd2c :3／a91069 :3／a854a1 :3；G3-new-2 aa6177 :5／a2fd4b :3／ae16a9 :5；G3-old-1 a2e1e9 :3／a9ea9b :3；G3-old-2 a8c1fb :7／ac0b58 :3。
- 原始數字表、統計腳本、G4 段不在我的方向內，沒審。

What I ran：
- `grep -n '^diff --git…' S4-review-diff.txt`，再 Read diff 檔第 15–98、99–246 行 → 找到量測文件那一節與設計文件 S4 那一節
- `sed -n` 印 `S4-a.md:23-30,34-46,55-60`、`S1-a.md:20-24,27-28,50-57`、`S1-b.md:13-17,22-23` → 對到正確答案原文
- 逐格 `sed -n '<N>p'` 和 `sed -n '<N>,<M>p'` 印 G2／G3 各個引用行 → 第三條以外全部指得對
- 對每個 `*judge.md` 跑 `grep -n '^【'` → 取得各段的起訖行
- `grep -n 'head_sha\|第一個 commit\|繞過①\|by1\|:165…' G3-new-2* G3-hk-1* G3-old-1*` → 抓到 K5 的沾邊原句
- `grep -n '繞過②\|:337\|第 337\|by3' G3-*` 和 `grep -n 'gate 端\|三句\|range_base\|185' G3-*` → K4 0 命中
- `grep -n 'stash\|verification-gate' G3-*`、`grep -n '3\.9\|鑑別\|第三種' G3-hk-*.d2.*`，加上 `sed -n '10,25p' G3-hk-2.d1*`、`sed -n '11,27p' G3-hk-1.d1*` → haiku 兩發的 K6 都是裁決者自查
- `grep -n '預言\|S6 的 review' G2-*`、`grep -n '紅數\|3 紅\|7 紅\|哪幾\|N 項' G2-*` → K2、K3 各格
- `grep -n '⑩\|改從共同祖先' docs/reviews/2026-10-07-review-followups/S4-*.md`、`grep -rn '新功能\|空殼' docs/reviews/2026-10-18-pstack-gaps/`、`git log --oneline -S '新功能還沒寫' -- templates/global/CLAUDE.md` → ⑩ 在舊答案裡有；§3.5 新功能那條源自 ee68e72
- `grep -n '⑩' G2-old*`、`grep -n '新功能' G3-*` → 舊組也看到 ⑩；§3.5 新功能那條只有 G3-new-2 與 G3-hk-2 報了
- `sed -n "<n>p"` 印量測文件 176、181、183、195、213 行 → 確認檔案行號

Not reported（範圍）：沒有改任何檔、沒有跑 claude；原始數字、stats.py 與 G4 段屬於別的方向。
````

## 處置

修正在 1e209ef。編號對到 `S4-judge.md` 的「採納」清單。

- C1、C5（限制段舉的兩例不成立）→ 採納 6（Important）。刪掉例子，改寫「沒有找到有出處、沒受污染、只有新組抓到的例子」
- C2（K6 蓋掉 haiku 組差異）→ 採納 5（Important）。改成審查者聯集新 2/2、haiku 0/2、舊 2/2，結論 3、5 同批補
- C3（K3 參考列）→ 採納 8（降 Smells）。改成「沒有一發算得上命中，只有沾邊」並逐條寫原因
- C4（K5 沾邊原句沒列）→ 採納 4（Important）。補三格原句位置
