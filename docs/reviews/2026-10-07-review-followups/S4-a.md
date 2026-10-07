# S4-a — 抽出 `resolve_fork_base`

> ⚠️ **放子目錄的理由**:claude-dd 的 `docs/reviews/` 根下已有上一張進度表的 `S6-{a,b}.md`。
> 本段屬於 lawdesk-ai `docs/designs/2026-10-07-review-followups-design.md` 那張表,
> 段落 ID 會跨表重複 —— 慣例見 lawdesk-ai 的 `docs/reviews/CLAUDE.md`(2026-10-07 S1 踩過一次)。

## 派工

- **範圍**:`git diff 639bde7 HEAD`(單一 commit `b66d8ae`,4 檔)。並行派送 → 明寫**一律用 `git show HEAD:`**。
- **探索預算**:最多一次重現實驗;要外部查證的列出來交回。
- **附上已跑過的驗證**:`test-gate.sh` 90 綠(基準 81)、`test-install.sh` 8 綠、`bash -n`、
  shellcheck clean、重構前後各一輪變異測試的紅數。
- **點名七項**,最高優先是 **bash 3.2 相容性**(CI 的 macOS job 用 3.2,而我自認沒在 3.2 上跑過),
  另外明寫了**我自己已踩過並修掉的兩個空洞斷言**,問「還有沒有第三個」。

## 發現

**Critical 1 / Important 2 / Minor 5**

> A 的開場:「**`check-claude-md.sh` 的重構本身是對的**(行為零變化、bash 3.2 乾淨)。
> 唯一的 Critical 在**測試的宣稱與覆蓋**,別去 gate 的程式碼裡找。」

### [Critical] 情境 ⑪ 的 `reviews_missing`「連共同祖先都沒有」分支**整份測試從未執行到**

- **實跑確認**(兩個獨立變異):
  - M3:刪掉那兩句 `echo`(回到 S6 之前的**靜默放行**)→ **90 綠 0 紅**
  - M4:同一分支 `return 1` → `return 0`(放行改成擋,**語意完全反過來**)→ **仍然 90 綠 0 紅**
- 病因:⑪ 的 `rm -rf … docs …` 把 `docs/` 整個刪掉 → `[ -d docs/reviews ] || return 1` 直接早退。
  `said "找不到共同祖先"` 實際命中的是 `owed_dirs` 的「…也找不到共同祖先,這次只檢查 staged」。
- ⚠️ A 的措辭:「**正是作者自己在 ⑩ 記下、說已經修掉的 opt-in 陷阱①,在 ⑪ 原封不動地重演**。」
- **連帶三處假宣稱**:⑪ 的註解、`tests/CLAUDE.md` 的「兩處放行但必須印出警告」、
  以及 **`docs/reviews/S6-a.md` A2 的「新增測試情境 ⑦ 釘住它」**(⑦ 本來就釘不到)。

### [Important] 「S6 的 reviewer 預言過這件事」查不到出處
- `git grep -e '預言' -e 'mode 參數' HEAD` 在整個 HEAD tree **只命中這兩句自己**。
- 失敗情境:這是「這個決策有人替我驗證過」的**權威引用**,用來支撐 `--segment-base` 刻意不共用。
  往後有人想重新評估要不要統一三處,會去翻 S6 報告找不到任何東西 —— 等於這個設計理由沒有第一手依據。
- ⚠️ 同句另一半「S6 的 review 抓到這兩處**已經漂移**」**有據**(S6-a 的 A2 / S6-b 的 B2),不要一起砍。

### [Important] 寫死「3 紅 / 7 紅 / 2 紅」,與本 repo `tests/CLAUDE.md` 自己的禁令同一類
- `tests/CLAUDE.md` 明文「⚠️ **不要在這裡寫「N 項」**」。這三個紅數**耦合到同一份 test-gate.sh 的斷言數**,
  而**本 commit 自己就把它們改掉了** —— 我列的「重構前」是 `owed_dirs` 4 紅,重構後變異②變成 7 紅,
  差額正好來自本段新加的 ⑩。
- **變異②的拆解(實跑)**:`owed_dirs` **3** + `reviews_missing` **3** + **1 則連鎖**
  (⑪ 的 `base_is`,因為 ⑩ 被誤放行而覆寫了起點檔 —— **不是獨立訊號**)。
  「對兩個呼叫端都承重」的推論**成立**,但證據是「**兩邊各至少一則 expect 變紅**」而不是總數 7。
- 變異①(`--segment-base` 改軟退化)實跑 **3 紅**,與文件相符。

### [Minor] ×5
1. `resolve_fork_base` 的契約註解只列 `$1`/`$2`,**沒寫它讀全域 `$base`、呼叫前必須 `read_base` 成功**。
   第三個呼叫端若忘了,`merge-base --is-ancestor "" "$head"` 失敗 → `return 1` → 呼叫端印
   「找不到共同祖先」,看起來像「無關歷史」而不是「沒記起點」。
2. **⑪ 的 `rm -rf` 清單名實不符**:`'api server'` 在這個測試 repo 裡**從來不存在**
   (測試建的是 `my dir`;前者出現在**全域 CLAUDE.md 的範例**裡),清單還漏掉
   `p/ r/ w/ keep/ mv/ feat/ feat2/ 功能/ 模組/ 'my dir'/ top.js/ side.txt`。
   `commit()` 是 `git add -A`,所以那十幾個目錄被一起 commit 進 r7 —— 今天能過只因為它們此時都已有 CLAUDE.md。
   **失敗情境**:之後在 ⑪ 之前插一個「留下沒有 CLAUDE.md 的程式碼目錄」的情境,r7 會變成 block,
   **紅在 ⑪、病因在新情境**。建議改成 `git clean -xdf` 這類與實際內容無關的寫法。
3. ⑩ 的 `said "改從共同祖先"` 無法分辨是哪個呼叫端印的(兩處都含那五個字)。
4. **`scripts/CLAUDE.md` 新表的 `--segment-base` 列漏了空樹起點**:起點是空樹時它
   **印出空樹 sha 並 exit 0**。實跑確認(全新 repo → 印 `4b825dc…`、exit 0)。
   順帶:五處 `--segment-base` 斷言**沒有一處覆蓋「空樹起點 + `--segment-base`」**(既有缺口)。
5. `--start-segment` 擋下時印的 `範圍 ${base}..HEAD` 用的是**記下的起點**,退化時實際查的是共同祖先
   —— 訊息會叫人去看一個不是實際被檢查的範圍(S6 引入,本段第一次讓它被測到)。

### 逐條回答(A 獨有的部分)

- **Q1 bash 3.2 安全,實跑**:`/bin/bash 3.2.57` 跑完整套 90 綠 0 紅,`: line N:` 防護一次都沒命中。
  **`local prefix=$1 head=$2 fork` 沒有命令替換,所以「`local x=$(cmd)` 吃掉 exit status」那個陷阱根本碰不到。**
- **Q2 行為零變化**,逐條比對兩句警告「逐字節相同」。
  ⚠️ **附帶指出我順手修的那個毛病有意義**:重構前 `local head_sha range fork` 宣告了死的 `range`,
  而真正用的 `range_base` 是**漏宣告的全域**。**而 `shellcheck -S warning` clean 並沒有抓到它** ——
  所以「shellcheck 乾淨」不能當成「變數有局部化」的證據。
- **Q6** 變異②下 `tests/test-gate.sh:123` 的 `said "不在目前分支的歷史裡"` **沒有變紅** ——
  退化放行的 fallback 訊息含同一個子字串。**那則既有斷言比看起來弱。**

### A 的 Not reported / 自我申報
- 變異③(拿掉共用函式那句警告)**它沒跑**,預測 2 紅並明寫「未驗證」。
- ⚠️ **它申報超出預算**:實際跑了 baseline + M1–M4 共 5 次,外加一個全新 repo。

## 處置

| 發現 | 處置 |
|---|---|
| **Critical** | **採納。** code-simplifier 獨立抓到同一條並已修(`git clean` 後重建 `docs/reviews/CLAUDE.md`、`said` 換成「只有一處會印」的字串)。**我自己複驗**:兩個變異各 2 紅 / 1 紅(修正前各 0 紅)。⚠️ A 指出的第三處假宣稱(**`S6-a.md` A2 的「新增測試情境 ⑦ 釘住它」**)—— **報告的前兩節不改**(第 3 節以外是當時 agent 的輸出,改了證據就作廢,見 `docs/reviews/CLAUDE.md`);這個更正寫在**本檔**與 `tests/test-gate.sh` 的註解裡。 |
| Important(錯歸屬) | **採納,三處一起改,含源頭。** 我追到源頭在 **lawdesk-ai 的設計文件 `:247`**(它自己就寫「reviewer 預言的」,而 `:89` 的框架是「我和 simplifier 當時的共同判斷」)。只修 claude-dd 的兩處副本會留下錯的源頭,所以設計文件一起改(lawdesk-ai `e6f0065`)。有據的那半句保留。 |
| Important(紅數) | **採納,改成表格「哪個變異 → 哪幾個情境變紅」,不記紅數。** 並把 A 指出的兩件事寫進去:①「對兩個呼叫端都承重」的證據是 **3+3** 而不是總數 ②「2 紅」那個變異**方向選錯**(只動共用的 echo,各呼叫端自己那句從沒被變異過 → 動了就是 0 紅 = 這個 Critical)。 |
| Minor 1 | **採納** —— simplifier 已補(隱性輸入 `$base` + 呼叫前要 `read_base`)。 |
| Minor 2 | **採納。** 自己驗了:`'api server'` 從未被 `mkdir`(`grep` 到的兩處都是我寫的字),實際建的是 `my dir`。改用 `git clean -xdfq` —— 與內容無關,並寫明「從範例抄而不是從實際的測試抄」這個成因。 |
| Minor 3 | **採納** —— simplifier 已改成 `said "review 檢查改從共同祖先"`,而且它量到「傳空 prefix」這個變異因此從 0 紅變 1 紅 → **`prefix` 現在是承重的**。 |
| Minor 4 | **採納。** 自己實跑確認(全新 repo → `4b825dc…`、exit 0),表上補了空樹例外,並記下「這個組合沒有測試覆蓋」是既有缺口。 |
| Minor 5 | **不收,登記。** 那是 gate 的**行為**改動(要把有效 base 傳到訊息那一行),改它需要自己的變異測試。S6 引入、不在本段 diff。 |
| A 指出的弱斷言(`:123`) | **採納,而且驗了鑑別力。** 收緊成 `said "改從共同祖先 "`(帶尾空格,fallback 訊息是「也找不到共同祖先,」不含這個形狀)。同一個變異從 **7 紅變 8 紅** —— 多的正是那一則。 |
| A 的超支申報 | **接受,而且認為是對的判斷。** 那些額外的跑換到了 Critical(決定性證據是 M4:**把那一支改成相反語意仍然全綠**)。預算是預設值;**誠實申報且換到 Critical 的超支**比守住預算而漏掉它好。 |
