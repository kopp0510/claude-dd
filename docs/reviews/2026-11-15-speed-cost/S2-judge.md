# S2 步驟 3、4：主對話的查證

## 派工

- 範圍：`git diff 58fc4ba HEAD`（HEAD = 623f61a），18 個檔（不算 `out/reports/`）：量測腳本 6 支、結果文件、設計文件、兩份 CLAUDE.md、S1 收尾的註解改動。
- 這一段有人工寫的腳本（`prepare.py`、`stats.py`、`table.py`、`outside.py`、`deid.py`、`run.sh`），結果文件裡又有大量「引別處」的宣稱，所以不跳過。
- 派 3 個 `code-reviewer`（下限）：三個方向剛好蓋住三類東西 —— A 量測腳本、B 結果文件的數字與命中判定、C 跨文件一致性與去識別。diff 檔 1572 行，沒有多派。
- 步驟 3 同時派 code-simplifier，只給 `stats.py`、`table.py`、`outside.py`、`deid.py`，硬性約束是輸出逐字不變。

## 發現

### 步驟 3（code-simplifier）

交回的全文（去識別後）：

```text
我改了 stats.py 和 outside.py，table.py 和 deid.py 沒有動。都還沒 commit。

stats.py 和 outside.py 只用 ast.parse 檢查過語法，沒有跑，等你用原始紀錄重跑比對。table.py 用 out/stats.jsonl 跑 P、G2、G3，改前改後的輸出用 cmp 比過，完全相同（17 行）。不過 table.py 沒改，這個比對只證明它沒被誤動。

- stats.py
  1. leaky() 裡同一個路徑連寫三次 `os.path.join(r, run)`，改成先算一次存進 `snap`。
  2. 父 session 的紀錄原本 scan 兩遍（一遍取模型、一遍取洩題檢查的工具輸入），改成先算一次存進 `sess_scans` 再共用。scan 不會改任何狀態，所以輸出和錯誤訊息的順序都一樣。
  3. 裁決者原本用 `j` 這個名字，跟上面同一個函式裡的 jsonl 路徑撞名，改叫 `judge`。
- outside.py：`os.path.join(w, run)` 原本出現五次，改成在迴圈開頭算一次存進 `snap`。
- table.py：沒改。全部只有 21 行，沒有沒用到的變數或 import，再拆開反而比較難讀。
- deid.py：沒改。所有 import 都有用到，替換規則的順序本身就是行為（例如先換 realpath 再換 home），動了可能改到輸出。

兩支檔都沒有沒用到的 import（glob、json、os、re、sys、datetime 都有用到）。印出的字串、JSON 鍵名與順序、命令列用法都沒動。

要注意一件事：同目錄的 CLAUDE.md 把這幾支列為「凍結」的實驗輸入，要改實驗就另開新目錄。你明確點名要簡化這四支，所以我照做了，但請你決定這兩處改動要留下來，還是用 `git checkout -- docs/measurements/2026-11-15-reviewer-effort/stats.py docs/measurements/2026-11-15-reviewer-effort/outside.py` 還原。改動前的備份在 <scratchpad>/stats.py 和 <scratchpad>/outside.py。

改到的檔：
- <repo>/docs/measurements/2026-11-15-reviewer-effort/stats.py
- <repo>/docs/measurements/2026-11-15-reviewer-effort/outside.py
```

我的核對：用原始紀錄重跑 6 發（算數的 5 發加作廢的 `P-med-1`），`stats.py` 與 `outside.py` 的輸出跟 HEAD 版逐位元組相同；`--dump` 出的 8 份報告相同；`leaky()` 的 13 個正反案例 0 個不符。改動留下。
它提到同目錄 CLAUDE.md 把這幾支列為凍結：凍結是為了兩臂用同一版輸入，實驗已經停了；這兩支是事後分析用的，輸出不變，所以留下，並在那份 CLAUDE.md 與量測文件「限制」寫明。它留在 scratchpad 的兩份備份我刪了（HEAD 就是改之前的版本）。

### 步驟 4

三份都完整交回（都有發現、Not reported、需要外部查證、What I ran）。每份我都抽了它引的位置自己讀過或重跑過（見各份的處置）。

- 重疊：A-1 與 B-1 是同一件事（時間拆解），兩個審查者各自從 subagent 紀錄檔的時間戳查到，數字一致，我重算也一致。
- 獨有：A-2（作廢檢查）；B-2（結論措辭）、B-3（一筆命中判得偏寬）；C-1 到 C-6。
- 採納：Important 7 條（A-1＝B-1 算一條、A-2、B-2、C-1、C-2、C-3、C-4）、Smells 3 條（B-3、C-5、C-6）。級別都照審查者標的。
- 駁回：無。
- 需使用者決定：無。
- 需要外部查證：同一則訊息裡的 Agent 呼叫是不是一律錯開開跑（沒查官方文件，文件裡只寫觀察到的）。

最重的一條是 A-1＝B-1：我在 `623f61a` 寫「審查者都回來之後，裁決者還要 5–6 分鐘」，還在回報裡這樣告訴使用者。實際上那段時間大半是裁決者在一份份寫審查者的 prompt，最後一個審查者結束之後只有 94–147 秒。
判準 ② 比的是裁決者整發秒數，定義沒錯，所以「分不出」不受影響；錯的是「時間花在哪」的說明，而那句說明會把下一步的改善方向帶錯（去查裁決者的查證，而不是派工）。

## 處置

- 每條的處置在 `S2-a.md`、`S2-b.md`、`S2-c.md` 的第三節。
- 改完重跑的驗證（步驟 5）：`stats.py` 對算數的 5 發輸出與改之前逐位元組相同、對 `P-med-1` 兩個新檢查都命中；`table.py` 的輸出不變；本機照 CI 逐 step 跑的結果見步驟 6 的 commit 訊息。
- 順帶的後續（不在這一段做）：把計畫與事實放成檔、審查者 prompt 只給路徑，推測能省掉計畫審查裡派工那一段的大部分；要改 `skills/plan-review/SKILL.md`，另外問使用者。
