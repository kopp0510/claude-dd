# S1-a：審查者 A（全面，先從「引用與數字對不對得上出處」下手）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），S1-a、S1-b、S1-c 三個在同一則訊息平行派出。
派工 prompt（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad；下面「發現」節同樣只換了路徑與使用者名稱）：

````text
先 Read <S>/tune-review/prompt-common.txt，照它做。你的代號是 S1-a。

你的方向（先從這裡下手，看完再全面看）：引用與數字對不對得上出處。diff 新增的每一句只要引了別處（檔案路徑、節名、步驟編號、commit、數字、「某某那條」），就去那個地方讀原文，確認存在、而且講的是這句話說的事。量測檔「整理」節的每個數字對「當天輸出」節；根目錄 CLAUDE.md 三段新文字引的東西逐個查；設計文件的敘述對 git log 與被引的檔。
````

`prompt-common.txt` 全文（逐字，路徑去識別）：

````text
你是 claude-dd repo（<REPO>）8 步開發迴圈步驟 4 的審查者。職責：找漏洞，每條附證據（路徑:行，或指令與輸出），沒證據的不算。不寫優點、不客套。

審查範圍：段落 S1「照 2026-11-14 的量測調整三條規則」從 58ae9b0 到目前工作目錄的整段（五個 commit）。全部是文件與規則文字，沒有產品程式碼。

材料：
- diff 檔：<S>/tune-review/diff.txt（834 行）。**用 Read 的 offset/limit 每次 300 行讀到最後一行**：Read 一次讀太多會靜靜截斷、不報錯。
  ① 整段 diff ② 步驟 3 沒跑的說明 ③ 被改到的檔的整檔內容（根目錄 CLAUDE.md 整檔、CHANGELOG 的未發布節）④ 已跑過的驗證與預期值
- ④ 列的驗證都已跑過、結果如列，不要重跑（測試、CI step、安裝、claude -p 都不要跑）。「跑過」不代表結論對 —— 你懷疑它驗的不是它宣稱的東西，就指出來
- 被改到的檔（CLAUDE.md、CHANGELOG.md、docs/measurements/2026-11-14-session-cost.md、docs/designs/2026-11-14-loop-tuning-design.md）以 diff 檔那份為準；其他檔直接讀工作目錄（審查期間不會再變）
- 專案規則：根目錄 CLAUDE.md、各層 CLAUDE.md、~/.claude/CLAUDE.md（尤其 §3.10 寫文件的判準）
- 這一段的計畫與假設：docs/designs/2026-11-14-loop-tuning-design.md（在 diff 裡）

已知、不用再報的：計畫審查第 1 輪沒過、第 2 輪沒跑成，使用者選了「拿掉放手語，其餘直接做」（設計文件「假設」節有寫）；放手語沒有寫進任何檔，不在審查範圍。量測用的 transcript 不在 repo，數字重跑不了（量測檔「方法」「限制」有寫）。

只用手上的資料與讀檔、grep、git 指令判斷；需要外部查證的列出來交回，不要自己做。不要改任何檔、不要 commit。

輸出格式：
- 每條：級別（Critical / Important / Smell）｜檔:行｜問題｜證據（引原文或指令輸出）｜具體失敗情境（誰照這段做、會怎樣錯）
- Not reported：看過、判斷不是問題的，各一句理由
- What I ran：跑過的 grep / 讀過的檔
- 需要外部查證：每條一句
````

## 發現

Critical 0 / Important 2 / Smell 0。範圍：S1，58ae9b0 到工作目錄（diff.txt 共 834 行，全部讀完）。這次照指定方向查：引用與數字對不對得上出處。

[Important] docs/measurements/2026-11-14-session-cost.md「整理」節的「session 的第一個請求（還沒做任何事）輸入 97,571 token」｜這個數字在「當天輸出」裡找不到，量的時段也可能不在量測範圍內。
  證據：
  - 「當天輸出」只貼了 python 腳本的輸出，裡面沒有 97571。「方法」節的 jq 指令（`... | head -1`）沒有時間過濾，取的是整份 transcript 的第一則。
  - 同一份輸出寫「2026-11-13T17:46 壓縮前 366594」。這次壓縮離範圍起點 17:42:47 只有 3 分多鐘，context 已經 36.7 萬 token，表示範圍起點之前 context 就不是空的：transcript 在起點前很可能已有內容。
  失敗情境：設計文件 S1-1 的驗收寫「『整理』節的每個數字對得上『當天輸出』」，照這條驗收的人對不到 97,571，這條驗收其實沒過。讀者會把 97,571 當成這件工作開頭的基準，跟同一節的 13.3–19.0 萬並列比較，但它可能量的是範圍外、更早的那個請求。

[Important] docs/designs/2026-11-14-loop-tuning-design.md「計畫審查紀錄」節｜照裁決報告原文抄進來的兩個指標，在 HEAD 對不到東西，旁邊也沒有註記。
  證據 1：`sed -n 115p CLAUDE.md` 印的是「`result`**（`result_index` 0 與 1 …」。被引的 `--settings '{"advisorModel":""}'` 在 HEAD 是第 119 行。`git show 58ae9b0:CLAUDE.md | sed -n 115p` 才是 advisor 那條的開頭：這一段在檔頭加了 2 行、在第 3 步加了 2 行，行號整組往下移。
  證據 2：駁回 R1-3 的依據寫「S2-judge 那 4 條是清單本身寫錯」。同一份文件 S1-3 驗證列自己記著「8 條、其中 4 條」在被引的檔裡對不到、已改成列舉，這句卻沒改，也沒加註。
  失敗情境：接手的人照 :115 去查，看到的是 result_index 那行。拿駁回 R1-3 的理由去對 S2-judge.md「採納（Important）」，對不到 4 條，就判斷不了這個駁回還站不站得住。§3.10 要求寫識別符、不寫行號；就算要保留原文，也要在後面補一句「（原文行號是 58ae9b0 的；『4 條』見 S1-3 的更正）」。

What I ran
- Read 了 prompt-common.txt 與 diff.txt 的 1–834 行 → 全部讀完
- `git show 58ae9b0:CLAUDE.md | sed -n '1,6p;113,117p'`、`sed -n '115p;119p' CLAUDE.md` → 58ae9b0 沒有指路行；:115 在 58ae9b0 是 advisor 那條，在 HEAD 是 result_index 那行
- `git show --stat` 看五個 commit 加上 58ae9b0 → S1-1 同批帶了設計文件與 CLAUDE.md 指路（+2），對得上設計文件寫的
- `grep -n 'exit 6' tests/test-dd-init-upgrade.sh` → 第 201、205、209、212、215 行有 exit 6 那組測試
- 用 awk 列出 S2-judge.md「採納（Important）」，再讀 S2-a～S2-d 的「處置」節 → 共 10 條。README 前置需求、拒絕清單（改的是試跑的 README 與目錄 CLAUDE.md）這兩條以外，都改到 skills/security-audit/CLAUDE.md；需使用者決定的只有 D11c
- `grep -n '^#'`、`grep -n 'D16\|已知限制'` skills/security-audit/CLAUDE.md，並讀了「從上游更新」 → 第 8 步存在，內容是重跑乾跑的條件
- 用 awk 列出 skills/security-audit/CLAUDE.md 分支表的標記欄 → 標「乾跑」的剛好 21 條，對得上 dry-run 21
- `git -c core.quotePath=false diff --numstat 9584605..58ae9b0` 再照路徑分類加總（結果存在 <S>/s1a-numstat.txt）→ code +101/−13、reviews +1626、measurements +860、designs +229、security-audit CLAUDE.md +189、其他 +76/−10、上游檔 +5300，全部跟量測檔一致
- `grep -n '乾跑\|9584605' docs/designs/2026-11-14-security-audit-intake-design.md` → S1 的 commits 欄是 9584605..，量測檔講的兩段工作出處對得上

Not reported（看過，判斷不是問題）
- 1007 分、673.4 分（9 筆加總）、334 分、171 = 157+8+4+2、136 = 157−21、3129（463196/148 取整）、「11 次在 4.4 小時內」（05:46→10:08）、36.7–38.5 萬、13.3–19.0 萬：都逐一對過「當天輸出」，算得對
- 21 個 dry-run 是全部 agent 類型合計，不是只算 sonnet：分支表的乾跑剛好 21 條，S2-d 處置也記著乾跑全是 sonnet，「限制」節也承認沒逐個核對
- 根目錄 CLAUDE.md 三段新文字引的 `--commands-only` 那條、`tests/` 的 exit 6 那組測試、S2-judge.md 的 10 條與兩條例外、D11c、「從上游更新」第 8 步、量測檔路徑：都存在，講的也是同一件事
- 收編清單新段寫的「已知限制」：skill CLAUDE.md 沒有這個節名，但第 84 行用「記成已知限制」記了 D11c，講的是同一件事
- 第 3 步既有的「有 4 條其實寫在別處」：不在這段 diff 裡，是之前就有的

需要外部查證
- 用 jq 加上 timestamp ≥ 2026-11-13T17:42:47 重跑第一個請求的輸入量，看 97,571 是不是落在範圍內。順便看 transcript 在 17:42:47 之前有沒有 assistant 訊息：這可以說明 17:46 那次壓縮前為什麼已經 36.7 萬
- 設計文件寫的「計畫審查第 1 輪派 4 個審查者、4 條重大」：裁決報告不在 repo 裡（docs/reviews/2026-11-14-loop-tuning/ 還不存在），我核對不了

## 處置

- 第 1 條（Important，97,571）採納：查證 —— 整份 transcript 的第一個請求時間是 `2026-11-13T12:54:31Z`，在量測範圍之前。量測檔「方法」那條 jq 註明不套時間範圍、
  「整理」寫明這個數字來自那條 jq、在範圍之前；設計文件 S1-1 的驗證改成「對得上當天輸出，或對得上方法節另外列的指令」
- 第 2 條（Important，照抄的審查紀錄對不到）採納：`git show 58ae9b0:CLAUDE.md | sed -n 115p` 確實是 advisor 那條。「計畫審查紀錄」加註：原文行號是 58ae9b0 那時的、
  「S2-judge 那 4 條」是第 1 版計畫的說法（那一項後來撤回）。原文照抄的部分不改
- 需要外部查證 ①（97,571 落不落在範圍內）：查了，不在範圍內，見第 1 條
- 需要外部查證 ②（第 1 輪「4 個審查者、4 條重大」核對不了）：沒補。裁決報告只在 scratchpad，計畫審查的報告本來就不落地進 repo；設計文件照抄了它的駁回清單
- Not reported 裡提到的「已知限制」節名：那一段已經隨 S1-3 撤回
