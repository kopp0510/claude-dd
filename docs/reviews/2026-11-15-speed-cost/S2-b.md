# S2 步驟 4：審查者 B（結果文件）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數），同時派 code-simplifier 跑步驟 3。派工用一句話：「先用 Read 讀完 `<scratchpad>/s2/review/prompt-b.txt`，它就是你的完整任務說明，照裡面做。報告直接用文字交回，不要寫成檔。」下面是那個檔的全文（路徑已去識別：`<repo>`、`<scratchpad>`）。
diff 檔（1572 行）的組成：①`git diff 58fc4ba HEAD`（HEAD = 623f61a；不含 `out/reports/` 與 `judge.txt`，這兩類直接讀 repo）②被改到檔案在 HEAD 的整檔內容（帶行號；與步驟 3 並行，所以取 HEAD 版）③已跑過的驗證與預期值 7 條。步驟 3 的改動在派工當下是空的。

```text
你是 8 步開發迴圈步驟 4（code-review）的審查者 B。另外兩個審查者同時在審同一段，你們互相看不到。

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

你的方向：結果文件 docs/measurements/2026-11-15-reviewer-effort.md 的每個數字與宣稱：對 out/stats.jsonl 與 table.py 的輸出；引用的報告檔與行號（out/reports/）指到的內容是不是它說的那個、算不算照「正確答案」那節定義的命中（M1 的 (a)(b)、K1）；判準有沒有照跑之前寫死的版本套（git show 2b470b5 對 HEAD，看判準與正確答案事後有沒有被改）；洩題判法事後補的那段站不站得住；結論與限制有沒有講過頭。

交回格式（直接用文字交回，不要寫成檔）：
每條發現：級別（Critical／Important／Smells）｜位置（檔案與行）｜內容｜證據。
另列「Not reported」（看過、判斷不報的，各一句理由）、「需要外部查證」（沒有寫「無」）、「What I ran」（跑過的指令）。
```

## 發現

審查者交回的全文（去識別後，其餘一字不改）：

```text
Critical 0 / Important 2 / Smells 1 — 範圍：git diff 58fc4ba..623f61a，重點是 docs/measurements/2026-11-15-reviewer-effort.md 的數字、宣稱與命中判定

**[Important]｜docs/measurements/2026-11-15-reviewer-effort.md:168、:219｜時間拆解錯了：「裁決者整發秒數 − 最慢審查者」被寫成「審查者都回來之後，裁決者自己查證、寫報告還要 5–6 分鐘」和「審查者只佔前 1.5–4 分鐘」。實際上裁決者是一個接一個派審查者，每個間隔約 75 秒。**
- 差掉的那 318–385 秒，裡面有三段：派工前的約 85 秒、一個個派出去的約 230 秒、最後一個審查者回來之後的時間。最後那段只有 94–147 秒，不是 5–6 分鐘。
- 從第一個審查者開始到最後一個結束，實際是 275–383 秒，比「最慢的 84–229 秒」長很多。
- 結論段（:219）用這組拆法推出「審查者的強度不是主要的那一塊」，依據不成立。方向也許還是對的（固定的派工時間約 310 秒），但文件寫的原因是錯的。
- 證據：我用 subagent 紀錄檔的 timestamp 算了各段時間（相對裁決者第一筆）：
  - `P-med-2`：4 個審查者在 84、159、234、312 秒開始，最後一個 466 秒結束，裁決者 614 秒結束。最後一個審查者回來之後只剩 147 秒。
  - 另外三發，最後一個審查者回來之後分別是 `P-low-2` 94 秒、`P-med-3` 117 秒、`P-low-3` 107 秒。
  - 派工前四發都是 84–87 秒。
  - 另外，`P-med-2` 裡最慢的 R1（229 秒）在 313 秒就結束了，真正卡住整發的是最後派出的 R4（466 秒結束）。所以「最慢審查者秒數」不等於關鍵路徑。

**[Important]｜docs/measurements/2026-11-15-reviewer-effort.md:217｜結論段用粗體寫「**不建議改**」，但「不建議改」是判準（:112–118，在 2b470b5 寫死）裡的一個結論類別，條件是「low 臂少於 medium 臂」。**
- 這次甲是「分不出」，乙是「沒跑完」，沒有一部分落在「不建議改」。
- 只看結論段的人會讀成「實驗判定 low 比較差」。應該改寫成「兩部分都沒達到建議改，所以規則維持原樣」這類說法，不要借用判準的類別名。
- 證據：:114 寫「low 臂少於 medium 臂 →『不建議改』」；:214–215 結論表寫「分不出／沒跑完」。

**[Smells]｜reviewer-effort.md:156（`P-low-3.d2.ab9ac0` :13 被判成「a 與 b」）｜兩個機制都判得偏寬。**
- (a)：原文寫的是「`dd-loop` 的 SKIP 路徑（`SKILL.md:93`）會讓『每段』不成立」。b1935bb 的 `SKILL.md:93` 是 SKIP 檔的寫法，不是「diff 全是資料、設定、註解、文件就不派」的條件（那句在 :45）。它講到「每段」不成立，但沒講到 (a) 的觸發條件。
- (b)：原文只說「時間和費用並列」「樣本 6 個」，沒講到「11.8 分是單一 code-reviewer 的時間，不是每段的成本」。
- 這筆不影響結論：同一發的 `P-low-3.d2.a649be` :23 是清楚的 (b)。`P-med-1.d2.aa301f` :23 的 (a) 也是用「跳過條款（SKIP 檔）」判的，同樣偏寬，但那發只當參考。

**Not reported**
- 判準與正確答案事後有沒有改：`git diff 2b470b5 HEAD` 對量測文件只有新增洩題判法段落和結果段。正確答案（M1 的 a/b、K1/K4/K5）與判準一字未動。凍結輸入事後只改了 run.sh（4 行），judge.txt、prepare.py、stats.py 都沒動。
- 洩題判法是事後補的：P-med-1.jsonl 最後修改 02:20:42，e5c104b 在 02:22:05 commit，P-low-1.jsonl 最後修改 02:25:07，6903c1b 在 02:25:54。順序和文件寫的一致。「還沒看報告」本身沒辦法用證據證明，但時間差只有 1.5 分鐘。判法的四類（真 repo、projects、別發、內容不同的部署檔）對 P-med-3 那筆 `find`／`ls` 判「不算」是一致的。
- 數字都對得上：
  - stats.jsonl 與 scratchpad 的 `logs/<發>.stats.json` 五發比對，除 notes 外每個欄位都相同。原始 notes 的洩題筆數 4/4/4/4/3，和文件一致。
  - 文件裡的加總和比例我逐一手算過，全部對：輸出／思考 token 合計、裁決者減最慢審查者（385/353/371/318）、110 秒（19%）、費用合計 18.88、甲四發 11.26、13 條小事表各欄合計 7/7/5/5。
- M1 引用的 12 個「檔:行」都印出來看過，指到的都是它說的內容：
  - 審查者那幾行的 (a)/(b) 歸類，除上面那筆 Smell 外都站得住。
  - 裁決者引的行，都落在【採納（小事）】與【駁回】兩個標題之間。
  - P-med-2 的重大是 T1（judge.md :11），四發的【結論】和表上一致。
- K1 三筆：:3 是標題行，機制（owed_dirs 印的那句、`[ -d docs/reviews ] || return 1`）在下面的 :4–5。歸類正確。乙不計分。
- 13 條小事表我沒有逐格重判：文件自己標了「關鍵字輔助、✗ 只代表沒找到」，它也不進判準。
- 「P-med-3 的 M1 是輪1-R4 講到的」：aa5d73 的檔名就是 R4，而 cd 到上兩層的是 R3（a1efc8）。正確。

**需要外部查證**
- 根目錄 CLAUDE.md 新增那條寫「2.1.325 實測」，以及 stderr 原文、`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS` 這個環境變數名：只能對 P-med-1 的 stderr 原檔或 Claude Code 官方文件核對，我沒查。
- reviewer-effort.md:58 寫 `~/.claude/settings.json` 替 opus 設了 `effortLevel: xhigh`：文件自己標了「沒驗證」，要讀那個設定檔才能確認。

**What I ran**
- `git log --oneline 58fc4ba..HEAD`、`git show 2b470b5 --stat`、`git diff 2b470b5 HEAD -- docs/measurements/2026-11-15-reviewer-effort.md` → 判準與正確答案沒改
- `git diff --stat 2b470b5 HEAD -- docs/measurements/2026-11-15-reviewer-effort/ ':!…/out'` → 凍結輸入只有 run.sh 改了
- 用 `sed -n` 印出 out/reports/ 裡 16 處被引用的行 → 內容都符合引用；ab9ac0:13 偏寬
- 在 judge.md 裡 grep 段落標題與【結論】下一行 → 小事段的範圍、結論都一致
- `git show b1935bb:skills/dd-loop/SKILL.md | sed -n '43,46p;88,94p'` → :93 是 SKIP 檔寫法，:45 才是 (a) 的條件
- 用 python 讀 `~/.claude/projects/<各發快照編碼>/*/subagents/agent-*.jsonl` 的 timestamp，算派工前、審查者區間、最後一個回來之後、各審查者起訖 → 得到上面那組數字（例如最後一個回來之後 147/94/117/107 秒、派工間隔約 75 秒）
- 用 python 比對 out/stats.jsonl 與 scratchpad 的 `logs/<發>.stats.json` → 五發都沒有不同的欄位
- `git log --date=iso`、`ls -lT …/work/logs/` → 第一發、補判法、改 run.sh 三者的先後順序和文件一致
```

## 處置

| # | 發現 | 處置 |
|---|---|---|
| 1 | Important：時間拆解錯了 | 採納，與 A-1 同一件事（兩個審查者各自查到），處置見 `S2-a.md` |
| 2 | Important：結論段的「不建議改」借用了判準的類別名 | 採納。改成「審查者的強度維持原樣」，並寫明這不是判準裡的「不建議改」 |
| 3 | Smells：`P-low-3.d2.ab9ac0` :13 判成「a 與 b」偏寬 | 採納。讀了那一行與 `b1935bb` 的 `skills/dd-loop/SKILL.md` :45、:93：它引的是 SKIP 檔那一條，不是 (a) 的條件。表上改標「偏寬」並在表下說明；`P-med-1.d2.aa301f` :23 同樣改寫。`P-low-3` 的命中靠 `a649be` :23，不變 |
| 外部查證 | 「2.1.325 實測」與 stderr 原文 | 審查者 C 從 7 份父 log 的 init 訊息與 `P-med-1` 的 log 核過（見 `S2-c.md` 的 Not reported） |
| 外部查證 | `effortLevel: xhigh` 的來源 | 沒查（設定檔在專案外）；文件原本就標「沒驗證」 |
