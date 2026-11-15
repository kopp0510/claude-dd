# S4 步驟 3、4：主對話的查證

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S4。

## 派工

- 範圍：`git diff cf6beea`（表上這段的起點）到工作目錄。HEAD = a2954f7，3 個 commit（S4-1、S4-2、S4-3），工作目錄乾淨。
- 步驟 3：沒有跑 `code-simplifier`。這一段的 diff 全是 Markdown 與純文字（`git diff --stat cf6beea a2954f7` 列的 11 個檔都是 `.md` 或 `.txt`），沒有程式碼可以簡化。
- 步驟 4：照樣派審查者。diff 沒有程式碼，但有一處行為改變（`agents/memory-analyst.md` 的評分指示）與一批引別處的宣稱（授權檔裡的比對結果、CHANGELOG、差異紀錄），這些機械檢查看不到。
  派 3 個 `code-reviewer`（下限，不帶 model 參數），照改動分方向：A skill 改完之後自不自洽、B 授權與歸屬的宣稱、C 文件之間的一致。整段 diff 扣掉 Apache-2.0 全文約 70 行，沒有多派。
- 派工 prompt 只交事實（做了什麼、審查包的組成、已跑過的驗證與預期值），沒有寫我對哪裡可能有錯的判斷。

## 發現

三份都完整交回（都有發現、Not reported、What I ran、需要外部查證）。讀檔檢查：每份我都讀了它引的位置或重跑了它的指令，都對得上；
只有 C 的第 3 條引的前例位置不對（它說 1.6.13，那一條其實在 `## 1.6.11` 底下），結論不受影響。

- 採納（全部，10 條）：
  - Important：A1（「Differences from upstream」只列這次的兩條，讀起來像完整清單）、B1（改過的 `agents/code-reviewer.md` 檔內沒有說它改過）、C1（行為改變只寫了 Scope，Durability、Impact 也會變；例子沒有跌破門檻）
  - Smells：A2（「two tables」其實是一份條列加一張表）、A3（讀不到評分表時，候選清單怎麼辦沒寫）、B2（授權檔列 frontmatter 的差異只寫了 description）、B3（「Output Format」標題只與一份官方檔相同）、
    C2（授權檔說「根目錄 CLAUDE.md 列為自製」，那裡沒有這一句）、C3（授權檔的 CHANGELOG 條目放在 Fixed）、C4（設計文件 S4-3 的檔案清單漏了根目錄 CLAUDE.md）
  - 級別照審查者標的，沒有調級。
- 駁回：無。
- 需使用者決定：無。B1 的改法（在 agent 檔裡加一行說明）動到 S4-3 檔案清單以外的檔；它在「補授權」的本意內、一行、可復原，直接做了，最終回報會講明。
- 需要外部查證：
  - A：上游現行版的兩份定義還在不在 —— 沒有查。差異紀錄改成指到 git 裡的 `7248a15`，不再講「上游」，這一題不必回答。
  - B：Apache-2.0 第 4 條 (b) 的「prominent notices」放在同目錄另一個檔算不算 —— 沒有查。已經在被改的檔裡加了說明，這一題不必回答；加了之後授權上夠不夠，沒有人驗證過。

## 處置

逐條的處置在 `S4-a.md`、`S4-b.md`、`S4-c.md`。修完之後的驗證（步驟 5，都在改完的工作目錄上跑）：

- `grep -rn 'codex-install\|clawhub install' skills/self-improving-agent` 0 筆；`grep -rn '\$[0-9]' skills/*/SKILL.md commands/*.md` 0 筆。
- `agents/memory-analyst.md`：舊的三句分數定義 0 筆、指到 `reference/promotion-rules.md` 1 處、門檻句還在；指到的路徑在部署位置存在。
- 乾跑（sonnet，預期都在派出前寫下）：第一輪新版 2／2／2 = 6、舊版 3／2／3 = 8；補了退路句之後第二輪，正常路徑 2／2／2 = 6、候選清單有那一條，
  路徑改成不存在的檔 → 沒評分、候選清單是空的並說明原因。四發都與預期相同。每個版本、每條分支各只有一發。
- 與本機官方副本的比對重跑：`agents/code-simplifier.md` 仍 `cmp` 相同；`agents/code-reviewer.md` 119 行，與官方兩份逐行相同的仍是 13、10 行；
  `agents/code-reviewer.md` 對起點的差異只有新增的那一行註解與一個空行；`tail -n 202 agents/LICENSE.txt` 與官方副本的 LICENSE 仍 `cmp` 相同。
- 兩份 README 授權表新增那一列前後的表格行都以 `|` 開頭；`git diff v1.6.14 -- CHANGELOG.md` 沒有刪除行。
- 本機照 `.github/workflows/ci.yml` 逐 step 跑：26 個 step 都 rc=0。

沒跑的：沒有重新部署，所以部署版的 `memory-analyst.md`、`code-reviewer.md` 還是舊的；加了註解的 `code-reviewer.md` 沒有拿去實際審查過。

## 重疊與獨有項

- 重疊：沒有兩個審查者抓到同一條。A 的 Not reported 與 C 的第 1 條都碰到「評分方式」，角度不同（A 看 skill 內部有沒有第三處定義，C 看對外的說明寫得全不全）。
- A 獨有：新開的差異清單沒有寫明從哪一天起、之前的改動去哪裡找。我只想著「記下這次改了什麼」，沒想到新開一節的標題本身就是一個「這是全部」的宣稱。
- B 獨有：只在旁邊放授權檔，沒有照那份授權自己的條件去對被改的檔。我附了全文卻沒有讀第 4 條。
- C 獨有：行為改變的說明照計畫的假設（A11）寫，沒有回頭看舊的定義到底定義了哪幾項。

## 這一段自己犯的錯（給步驟 7）

- 補授權檔時只做了「附上全文、寫明來源」，沒有把那份授權的散布條件逐條對一次；改過的檔要在檔內寫明改過這一條就漏了。
- 寫行為改變的說明時沿用計畫裡的一句話（「Scope 從 3 變 2」），沒有重新比對新舊兩份定義；乾跑結果裡明明有另一項也差了 1 分，還是只寫了一項。
- 例子與結論對不上：寫「可能跌破門檻」，舉的例子是 6 分（仍達門檻）。
