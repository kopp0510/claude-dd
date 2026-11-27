# S2 步驟 4：審查者 A（量測腳本）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數），同時派 code-simplifier 跑步驟 3。派工用一句話：「先用 Read 讀完 `<scratchpad>/s2/review/prompt-a.txt`，它就是你的完整任務說明，照裡面做。報告直接用文字交回，不要寫成檔。」下面是那個檔的全文（路徑已去識別：`<repo>`、`<scratchpad>`）。
diff 檔（1572 行）的組成：①`git diff 9e473c3 HEAD`（HEAD = b66dbff；不含 `out/reports/` 與 `judge.txt`，這兩類直接讀 repo）②被改到檔案在 HEAD 的整檔內容（帶行號；與步驟 3 並行，所以取 HEAD 版）③已跑過的驗證與預期值 7 條。步驟 3 的改動在派工當下是空的。

```text
你是 8 步開發迴圈步驟 4（code-review）的審查者 A。另外兩個審查者同時在審同一段，你們互相看不到。

職責：找漏洞、證明這次改動有錯。每條附證據（diff 檔行號、repo 檔案行、你跑的指令與輸出），沒證據的不算。
只用手上的資料判斷；需要外部查證的列出來交回，不要自己上網抓。不改任何檔、不 commit、不跑 claude 指令（會花錢）。

範圍：repo <repo> 的 git diff 9e473c3 HEAD（HEAD 是 b66dbff），一段「審查者思考強度實驗」（量測腳本、結果文件、設計文件與兩份 CLAUDE.md 的補充）。
diff 檔：<scratchpad>/s2/review/S2-diff.txt，共 1572 行。Read 一次讀太多會靜靜截斷、不報錯；一律用 offset／limit 每次 300 行，讀到第 1572 行為止。
diff 檔三段：整段 diff（不含 docs/measurements/2026-11-15-reviewer-effort/out/reports/ 與 docs/measurements/2026-11-15-reviewer-effort/judge.txt，這兩類直接讀 repo）、被改到檔案的整檔內容（帶行號）、已經跑過的驗證（已確認，不要重跑）。
同時有一個 code-simplifier 在改工作目錄裡 docs/measurements/2026-11-15-reviewer-effort 底下的 stats.py、table.py、outside.py、deid.py：這四支一律讀 diff 檔裡那一份（HEAD 版）或 git show HEAD:<路徑>，不要讀工作目錄。其他檔照常讀 repo。
專案規則在根目錄與各層的 CLAUDE.md。回覆用繁體中文。

背景事實（不是結論，請自己查證）：
- 實驗在跑之前 commit 了方法、正確答案、判準（c7e3cb9）；第一發跑完、看報告之前補了洩題檢查的判法（d3af3fc）；run.sh 在第一發作廢後加了一個環境變數（9671749）；甲的結果 e4b6f32；乙與結論 b66dbff
- 使用者在乙跑完第一發後選「現在停」，所以乙只有 1 發
- 命中（哪份報告的哪一行算抓到）是寫這段 diff 的人自己人工判的

你的方向：量測腳本的正確性：docs/measurements/2026-11-15-reviewer-effort 的 stats.py、prepare.py、run.sh、table.py、outside.py、deid.py。它們量的是不是結果文件說的那個東西（裁決者整發秒數、最慢審查者秒數、token 去重、effort 怎麼讀、作廢檢查、洩題判定）；有沒有會讓表上數字錯、或該作廢卻沒作廢的 bug；prepare.py 產生的兩臂 prompt 是不是只差 effort。

交回格式（直接用文字交回，不要寫成檔）：
每條發現：級別（Critical／Important／Smells）｜位置（檔案與行）｜內容｜證據。
另列「Not reported」（看過、判斷不報的，各一句理由）、「需要外部查證」（沒有寫「無」）、「What I ran」（跑過的指令）。
```

## 發現

審查者交回的全文（去識別後，其餘一字不改）：

```text
Critical 0 / Important 2 / Smells 0。範圍是 `git diff 9e473c3 HEAD`（b66dbff），只看量測腳本的方向：stats.py、prepare.py、run.sh、table.py、outside.py、deid.py。四支被 simplifier 改動的檔都用 diff 檔裡的 HEAD 版或 `git show HEAD:`。

## 發現

**1. Important｜結果文件 `docs/measurements/2026-11-15-reviewer-effort.md:168`（「判準以外看到的」第 2 點）與 `:219`（結論段「甲順帶看到的一件事」）**
- 內容：甲的審查者不是同時開跑的，是錯開開跑。文件用「裁決者整發秒數減最慢審查者」去推「審查者都回來之後，裁決者還要 5–6 分鐘」「審查者只佔前 1.5–4 分鐘」，這個推法不成立。stats.py 的 `rev_s` 是每個審查者自己紀錄檔的首尾差，不是它在整發時間軸上的起訖位置。
- 證據：四發裁決者都在同一則訊息裡派 4 個審查者，同一個 msgid（`…HQ4yTQSo`）。每個 prompt 約 14.8k 字，tool_use 依序出現在 +83、+158、+234、+312 秒。以裁決者第一筆為 0，各發實際時間如下：

| 發 | 審查者開始 | 最後一個審查者結束 | 裁決者結束 | 最後一個審查者之後的時間 |
|---|---|---|---|---|
| `P-med-2` | 84／159／234／312 | +466 | +614 | 148 s |
| `P-low-2` | 85／160／235／312 | +360 | +455 | 95 s |
| `P-med-3` | 87／161／236／313 | +426 | +542 | 116 s |
| `P-low-3` | 84／159／234／312 | +370 | +476 | 106 s |

- 所以審查者都回來之後只剩約 1.6–2.5 分鐘，不是 5–6 分鐘。前約 5 分鐘是裁決者在逐個寫審查者的長 prompt，這段兩臂相同。決定整發結束的是最後開跑的 R4，不是表上「最慢審查者」那一個：`P-med-2` 最慢的是 R1（229 s），但 R1 在 +313 就結束了。
- 判準 ② 用的 `judge_s` 定義沒錯，表上數字和「分不出」的結論不受影響。要改的是這兩段的機制說明：等待時間大多花在「裁決者串行寫 prompt」，不是在「裁決者事後查證」。

**2. Important｜`stats.py:40-45` 與 `run_stats` 的作廢檢查（`:77-116`）**
- 內容：作廢檢查完全抓不到 `P-med-1` 那種失敗（subagent 被停掉、報告沒寫完）。
- 原因 1：這批紀錄裡所有 subagent 都沒用 SubagentHandback（handback=0），`text` 一律退回 `last_text`，看不出有沒有交回。
- 原因 2：stats.py 不 grep 父 log 的 `Background tasks still running`，也不檢查裁決者報告有沒有【結論】、審查者有沒有交回。
- 失敗情境：乙之後補跑時，如果某個審查者被中途停掉，它的 `rev_s` 會偏短，照樣算進「最慢審查者」，判準 ② 的比較就被污染，而 `errors` 是空的。根目錄 CLAUDE.md 這次新加的那條寫了「跑完 grep 父 log 有沒有那句」，但腳本沒做。
- 證據：
  - `python3 -I stats-head.py ../work P-med-1`（stats-head.py 是 `git show HEAD:` 取出的 HEAD 版）輸出 `[] 4 602 ['medium']`：已作廢的那一發 errors 是空的，會被當成正常的一發。
  - `grep -l "Background tasks still running" logs/*.jsonl` 只命中 `P-med-1.jsonl`。
  - 四份 d1 報告各有 1 個【結論】。
  - 算數的 5 發沒有被這個漏洞影響，這條是給還沒跑的發用的。

## Not reported
- token 去重（同一訊息 id 取最大）：`table.py` 的合計我逐列加過，5 發全對（例如 16960+13993+44745+27429=103127）。
- `cost`、`api_s`、`modelUsage` 只取最後一筆 result：每發的多筆 result 數值完全相同（例如 `P-med-2` 兩筆都是 3.047／997759），取最後一筆不會少算。
- `permission_denials` 只查父 result：我掃了每個 subagent 帶 is_error 又含 permission／denied 的 tool_result，全部 0 筆。
- effort 讀法：每個審查者紀錄檔的每一筆 assistant 都有 `effort`（noeff=0），值都等於該臂的值；裁決者都是 medium。
- prepare.py 兩臂的 prompt：judge、parent、R1 檔我都 diff 過，只差 effort 字樣與帶發代號的路徑（路徑裡看得到 med／low，但 judge 與 parent 本來就明寫 effort，不另外算干擾）。LINES 兩臂都是 254。
- outside.py 與 leaky() 認不出不帶斜線的 `..`（例如 `cd ..`、`ls ..`、Glob 的 path 是 `".."`）：我掃了算數的 5 發，0 筆，不影響這次結果。
- leaky() 的誤報（路徑後面接換行）：文件已經寫明。
- 結果文件的算術：80.5%、112.5 秒／19%、各差值、費用合計 18.88，我都對過，沒有錯。
- deid.py：報告數 5／5／5／5／4／3，跟 agent 數對得上，沒有被丟掉的報告。

## 需要外部查證
- Agent tool_use 在串流中寫完就先開跑（所以同一則訊息裡的審查者會錯開開跑），這是 Claude Code 的行為還是巧合，我沒查官方文件。時間戳已經證明這次確實錯開了。

## What I ran
- Read：prompt-a.txt；S2-diff.txt 第 1–1572 行（每次 300 行）。
- 列 work 與 logs 目錄；`grep -l "Background tasks still running" logs/*.jsonl` → 只有 P-med-1；數 reports 各發的份數 → 3／5／5／4／5／5。
- `python3 -I s2/review/chk-a.py <work>`：每發的 result 數值、各 subagent 的起訖時間、handback 數、被拒數、effort、`..` 用法 → 結果如上（handback 全是 0，被拒 0，`..` 0）。
- `python3 -I s2/review/chk-b.py <work>`：裁決者派 Agent 的時間點與 msgid → 同一個 msgid，+83／158／234／312。第二發中途 KeyError，只影響我自己的腳本，P-med-2 已印完。
- `grep -c '【結論】' reports/*.d1.*` → 四個裁決者各 1；`grep -n` judge.txt 的 {ROOT}、{EFFORT}、「平行」。
- `git show HEAD:…/stats.py > stats-head.py && python3 -I stats-head.py ../work P-med-1` → `[] 4 602 ['medium']`。
- `diff` 比 P-med-2 與 P-low-2 的 judge、parent，以及 G2-med-1 與 G2-low-1 的 R1、parent → 只差 effort 與路徑。

我寫的檢查腳本在 <scratchpad>/s2/review/chk-a.py、<scratchpad>/s2/review/chk-b.py、<scratchpad>/s2/review/stats-head.py。
```

## 處置

| # | 發現 | 處置 |
|---|---|---|
| 1 | Important：時間拆解錯了（審查者是錯開開跑的） | 採納。我用時間戳重算，四發的 Agent 呼叫都在同一則訊息、第 83–86／158–161／234–236／312–313 秒出現，最後一個審查者結束之後是 147／94／117／107 秒。量測文件「判準以外看到的」那一點與結論段的觀察整段改寫，加 `timeline.py` 與 `out/timeline.md`；根目錄 CLAUDE.md 補一條。「分不出」的結論與表上的數字不變 |
| 2 | Important：作廢檢查抓不到 `P-med-1` 那種失敗 | 採納。重跑 HEAD 版確認 `P-med-1` 的 errors 是空的。`stats.py` 補兩個檢查（父 log 非 JSON 行有 `Background tasks still running`；裁決者報告沒有【結論】）。補完重跑：算數的 5 發輸出逐位元組相同，`P-med-1` 兩個都命中 |
| Not reported | `..` 不帶斜線認不出 | 寫進量測文件「限制」（算數的 5 發 0 筆是審查者掃的，我沒重掃） |
| 外部查證 | 同一則訊息的 Agent 呼叫是不是都這樣錯開 | 沒查官方文件；文件裡只寫這四發觀察到的，註明沒查 |
