# S5 審查 — C（S5-2 的那一句與 A/B、UPGRADING 的指示）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S5（`review` 包裝器與 `workflow-review` 退場、code-simplifier 包裝器補約束）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。Agent 呼叫的 prompt 只有一句「先用 Read 把這個檔整份讀完，它就是你的完整派工內容，照它寫的做」，加派工檔的路徑；派工檔全文如下（`<scratchpad>` 是這個 session 的暫存目錄，沒進 repo）。

審查包 `<scratchpad>/s5-review-pack.txt`（755 行）的組成：第 1 節 `git diff b3b2bf9 HEAD`（HEAD = 63f4d6c，工作目錄乾淨）；第 2 節步驟 3 的結果（code-simplifier 看過三個檔的改動，沒有要改的）；
第 3 節被刪掉的兩個檔的原文；第 4 節已跑過的驗證 V1–V9 與預期值。被改到的檔沒有另附整檔：工作目錄與 HEAD 相同，派工寫明直接讀 repo。

````
你是 code-reviewer，審 claude-dd 這個 repo 的一個功能段落（S5）。你的職責：找漏洞。每條發現都要附證據（`路徑:行` 加原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。

審查包：<scratchpad>/s5-review-pack.txt（755 行）。**用 Read 的 offset/limit 每次 300 行讀到最後一行**（Read 一次讀太多會靜靜截斷、不報錯）。
裡面有：整段 diff（`git diff b3b2bf9 HEAD`）、被刪掉的兩個檔的原文、已經跑過的驗證與預期值。
工作目錄與 HEAD 相同，被改到的檔直接讀 repo 裡的就是 diff 描述的那一版。repo：/Volumes/T7/home/project/my_project/claude-dd
專案規則在根目錄與各層 CLAUDE.md；這一段的計畫、假設與結果在 `docs/designs/2026-11-15-audit-fixes-design.md` 的「### S5」一節。

這一段做了兩件事：
- S5-1：`skills/review/` 與 `commands/workflow-review/` 從 repo 刪掉、從部署陣列拿掉（`NS_COMMANDS` 變成空陣列），同批改 CI、測試、文件。
- S5-2：`skills/code-simplifier/SKILL.md` 的 Prompt 模板加一句約束，附 A/B 實測。

硬限制：
- **不要執行 `./install-dd-pipeline.sh`，不要在 shell 裡 `source` 它**（Bash 工具是 zsh，source 會讓整支安裝在真實的 `~/.claude` 上跑起來）；不要跑 `tests/*.sh`。審查包第 4 節列的驗證已經跑過、已確認，不要重跑。語法檢查可以用 `/bin/bash -n`、`shellcheck -S warning`。
- 全程唯讀：不改檔、不 commit、不寫報告檔（發現用文字交回）。要做小實驗只能在 <scratchpad> 底下自己開的新目錄裡做，不要動那裡既有的檔。
- 只用手上的資料判斷；需要上網或跑上面禁止的指令才能確認的，列在「需要外部查證」交回。
- 發現分級：Critical（照現在的內容使用會壞、會錯，而且不會報錯）／Important（文件或程式碼說的與事實不符、漏了專案規則規定要同批改的地方、驗證抓不到它該抓的錯）／Smells（其他）。
- 被你判成「既有問題、不是這次 diff 引入」的項目，回去看這次 diff 有沒有把同一個寫法帶進新的地方，再決定要不要報。

你的方向：
**S5-2 與 UPGRADING 的指示**。`skills/code-simplifier/SKILL.md` 新加的那一句：與同一份 SKILL.md 其他段落、與 `agents/code-simplifier.md` 的原文、與全域模板 `templates/global/CLAUDE.md` §3.2 有沒有矛盾或歧義；會不會擋掉該做的簡化。
A/B 的宣稱對不對得上證據：`CHANGELOG.md` 那一條與設計文件 S5-2「結果」裡的每一個數字與每一句結論，拿審查包 V9 列的素材檔自己 `grep`／`diff` 重量一次（那些檔可以讀）；量法本身有沒有洞（例如 `function` 的計數把新加的 helper 算進去、箭頭的樣式漏算、「巢狀條件已簡化」的判準）；結論有沒有說得比證據多（n、素材數、環境）；判定是不是派出前寫的那一套（看設計文件 S5-2 的「驗證」與 commit 758dbc9 當時的版本：`git show 758dbc9:docs/designs/2026-11-15-audit-fixes-design.md`）。
`UPGRADING.md` 新的一節：照著做會不會出錯或誤刪（指令、路徑、取回步驟列的東西全不全），它說的安裝腳本行為是不是真的（讀 `install-dd-pipeline.sh` 確認，不要執行）。設計文件 S5 一節的假設、結果、「沒做的」有沒有與 diff 不符的地方。

輸出格式（照抄這些標題）：
第一行：Critical N / Important N / Smells N — 範圍一句話
【發現】每條：序號｜級別｜內容｜證據（路徑:行 與原文，或指令與輸出）｜會出事的情境｜建議改法
【Not reported】你看過、判斷不用報的（各一句理由）
【What I ran】你讀了什麼、跑了什麼指令（指令照貼）
【需要外部查證】沒有就寫「無」
````

## 發現

審查者交回的報告，逐字（只把暫存目錄的絕對路徑換成 `<scratchpad>`）：

````
Critical 0 / Important 4 / Smells 3 — 範圍：S5（b3b2bf9..63f4d6c），重點看 S5-2 新加的那一句、A/B 的宣稱與量法、UPGRADING「已退場的元件」那一節

【發現】
1｜Important｜第二輪 A/B 的結論說「四發的 context 都有全域 CLAUDE.md」，可是第二輪根本沒叫 agent 照貼 context，所以這句沒有證據撐。同一份文件自己也寫「這一輪沒有叫它照貼 context」｜docs/designs/2026-11-15-audit-fixes-design.md:262「這一輪沒有叫它照貼 context」；同檔 :272「四發的 context 都有全域 CLAUDE.md（它的 §3.2 寫「不重排 import」，舊的兩發照樣重排了）」；CHANGELOG.md:157「四發的 context 裡都有全域 CLAUDE.md，沒有它的環境沒測」；審查包 V9 第 755 行「第二輪沒有要求照貼」｜讀者會以為第二輪查過 context。他們還會把「舊模板即使看得到全域 §3.2，照樣重排 import」當成量到的事實，拿來證明這一句非加不可。但第二輪的 context 是用第一輪推出來的，沒有量過｜這兩處改成「第一輪照貼過、四發都有；第二輪沒照貼，推論相同」，或把「全域 §3.2 也擋不住」這個推論拿掉
2｜Important｜結果表寫「`quote()` 9 組輸入與原版相同」，可是素材目錄裡的比對腳本有 13 組，對不上｜design.md:264 表頭「`quote()` 9 組輸入與原版」；`s5-ab2/cmp.mjs` 的 `cases` 陣列，我跑 `node cmp.mjs ./base/src/quote.js ./new1/src/quote.js | grep -cE '^(same|DIFF)'` → 13；四臂各跑一次都是 `bad 0`｜之後有人照著重跑，數到的是 13，就分不出是記錄寫錯，還是當時用了另一支沒留下來的腳本。這是寫少了，結論本身沒錯，只是證據對不回去｜改成 13，或註明 9 組指的是哪一支腳本
3｜Important｜新那一句的適用範圍有兩處不清楚：(a)「編碼風格只照專案 CLAUDE.md 寫明的」把 codebase 既有的寫法、ESLint／Prettier 設定都排除在外，連「新寫的碼對齊周圍既有慣例」這種該做的簡化也一併擋掉；(b) 句尾的「不重排 import」可以讀成不帶條件，專案 CLAUDE.md 有寫 import 規則時兩邊會打架，合併重複 import 也會被擋（實測已經出現）｜skills/code-simplifier/SKILL.md:43「編碼風格只照專案 CLAUDE.md 寫明的；…專案 CLAUDE.md 沒寫就不套用，不重排 import。」；第一輪舊臂不改箭頭的理由是「這個檔全用箭頭函式，以專案寫法為準」（design.md 第一輪那一條），新句子字面上連這種依據也禁了；CHANGELOG.md:157 副作用「新模板 2 發都沒有合併…理由是合併就得挪動 import」｜步驟 3：codebase 全用箭頭、規則寫在 ESLint 不在 CLAUDE.md，這一段新加了一個 `function`，simplifier 不會把它改齊。另一種：專案 CLAUDE.md 寫了「import 要排序」，句尾那條不帶條件的禁令跟它衝突。這兩種情境都沒測過｜改成「agent 定義裡列的偏好（…）不算專案標準：專案 CLAUDE.md 或既有程式碼沒有這個慣例時不套用」，把「不重排 import」移進條件句。改了字之後照 design.md 的規則要重跑 A/B
4｜Important｜UPGRADING 的清理指令只查目錄在不在，沒查它是不是 claude-dd 部署的那一份就 `rm -rf`。專案 CLAUDE.md「殘留清理」一節就提過，`~/.claude/skills/` 會有外部來源放進來的同名 skill｜UPGRADING.md:99-100 `ls -d ~/.claude/skills/review ~/.claude/commands/workflow-review   # 先看在不在` / `rm -rf …  # 確認是這兩個再刪`，「確認」要怎麼做沒寫｜使用者自己有一個（或別的套件裝的）不相干的 `review` skill，`ls -d` 印出路徑，他照第二行刪掉，沒有備份。安裝腳本這一條路徑也不會先備份｜先加一行比對，例如 `git diff --no-index <(git show v1.6.14:skills/review/SKILL.md) ~/.claude/skills/review/SKILL.md`，或 `head -3` 看 `description` 有沒有「調用 workflow-review 命令」；不同就別刪

【Smells】
5｜Smell｜UPGRADING 說安裝腳本「只新增、覆蓋現行清單上的東西」，這句不完全對：`create_commands` 有 `deprecated_dd` 迴圈，會先備份再刪掉 dd-help、dd-docs 等五個舊指令｜UPGRADING.md:95；install-dd-pipeline.sh:1087-1093 `local deprecated_dd=(...)` … `rm "$COMMANDS_DIR/$old.md"`｜改成「只清 `deprecated_dd` 列的舊 dd-*.md，不涵蓋 skills 與命名空間目錄」，跟設計文件 B2 的說法一致
6｜Smell｜判定式雖然是派出前寫好的，但第二輪的素材規格（「只把 import 與箭頭函式加多，其餘不變」）在看過第一輪的理由後改成「風格混用」。設計文件有揭露這件事，但 :272 寫「照派出前寫死的判定算通過」，CHANGELOG 對換素材一字沒提｜758dbc9 版 design.md:256「換一次素材（只把沒排序的 import 與箭頭函式加多，其餘不變）」對照現行 :262「與上面寫的…不同：依第一輪看到的理由改成風格混用」｜CHANGELOG 的實測那句補「第二輪素材依第一輪結果改過（不是派出前定的那一份）」
7｜Smell｜取回步驟沒列 README 安裝步驟 6 的文字（這段 CI 不驗），也沒提醒加回來就等於重新引入沒有 LICENSE 的第三方內容，違反收編清單第 1 項｜UPGRADING.md:105-107 只列「數字與表格」與 test-install 斷言；README.md 步驟 6 現在寫「Install the `/dd-init` command into `~/.claude/commands/`」｜補上「README 兩份安裝步驟 6、授權表那一列、CHANGELOG」，再加一句「加回前先解決授權」

【Not reported】
- 量法本身：`function` 的計數會把新加的 helper 算進去（new1 的 3），表上已經註明；箭頭的 regex 只抓頂層 `const x = (`，我另外用 `=>` 總數交叉核對：base、new1、new2 都是 4，old1、old2 都是 0，結論不受影響
- 「巢狀條件已簡化」沒有明文判準，但四臂 diff 都看得到四層 if 變成 early return，屬實
- 第二輪表上其餘的數字（模組順序、import 行數、function、箭頭）與第一輪的三項宣稱，我重量後全部對得上
- CHANGELOG 說 agent 定義把 import 排序、偏好 `function` 列成專案標準：agents/code-simplifier.md:13-16 原文確實如此。agent 另外列的 return type、try/catch、React Props 這幾條，新句子用「編碼風格」這個總稱涵蓋了，沒有逐條點名，算不上矛盾
- 步驟 3 會不會繞過這個包裝器：全域 §7.4 規定步驟 3 照 §7.2 呼叫 `code-simplifier` skill，所以模板會用到
- 全域 §3.2「不順手做：改命名」跟 SKILL.md 重點「改善命名」互相衝突，但這是既有問題，這次 diff 沒有把同一個寫法帶進新地方
- SKILL.md:10「簡化邏輯全在 agent 內，不在此重複」跟新句子有一點張力（包裝器開始管風格了），只是措辭問題
- UPGRADING「四種升級情境」：`^## ` 數出來確實是 4 節

【What I ran】
- Read 派工檔 prompt-c.txt、審查包 s5-review-pack.txt（1–755 行，分三段讀）、skills/code-simplifier/SKILL.md、agents/code-simplifier.md:10-49、skills/dd-loop/SKILL.md:44-55、install-dd-pipeline.sh:1080-1179、1270-1324
- `for d in base old1 old2 new1 new2; do grep -n "^import" …/quote.js; grep -cE '^(export )?(async )?function '; grep -cE '^(export )?const [A-Za-z]+ = (async )?\('; grep -cE '=>'; done`（s5-ab2）→ function／箭頭／=> 是 base 2/4/4、old1、old2 6/0/0、new1 3/4/4、new2 2/4/4；new 兩臂的 import 與 base 逐字相同
- `diff base/src/quote.js {new1,new2,old1}/src/quote.js` → new 兩臂沒動 import 與箭頭，四層 if 改成 early return；old1 重排 import、全部改成 function
- `diff prompt-old1.txt prompt-new1.txt` 等三組 → 只差範圍路徑與約束那一句
- `node cmp.mjs ./base/src/quote.js ./<臂>/src/quote.js`（四臂）→ 都是 `bad 0`；`… | grep -cE '^(same|DIFF)'` → 13
- 第一輪（s5-ab）同一組 grep，再加 `grep -c 'result = null'` → 四臂 import 與 base 相同、function 都是 0、null 都是 0
- `git show 758dbc9:docs/designs/… | grep -n S5-2`；`git diff 758dbc9 63f4d6c -- docs/designs/…`
- `grep -n 'deprecated_dd\|rm -rf\|…' install-dd-pipeline.sh`；`grep -n 'NS_COMMANDS\|命名空間' install-dd-pipeline.sh`
- `git grep -n 'workflow-review\|/review\b' -- . ':!CHANGELOG.md' ':!UPGRADING.md' ':!docs/designs' ':!docs/reviews' ':!docs/measurements' | grep -v self-improving-agent`
- `grep -n '^## ' UPGRADING.md`；`git ls-tree -r --name-only v1.6.14 -- skills/review commands/workflow-review` → 兩個檔都在
- `grep -n` 定位 CHANGELOG.md、design.md、UPGRADING.md 引用的行
- 唯讀列出本機 `ls ~/.claude/skills/review ~/.claude/commands/workflow-review`（兩個都還在），沒有改動

【需要外部查證】
- 無
````

## 處置

| # | 級別 | 處置 | 查證 |
|---|---|---|---|
| 1 | Important | 採納 | 第二輪的派工內容（`<scratchpad>/s5-ab2/prompt-*.txt`）確實沒有照貼 context 那一段。設計文件改成「第一輪四發都回報有、第二輪是推論」，並寫明「舊模板看得到 §3.2 照樣重排」沒有直接證據；CHANGELOG 那一條重寫 |
| 2 | Important | 採納 | 我的 9 組是臨時寫在指令列裡的、沒存檔；素材目錄那支 13 組的是某一臂留下的。設計文件寫明 9 組是哪些輸入，第三輪起存成 `<scratchpad>/s5-ab2/mycmp.mjs`，五份重跑都是 `inputs 9 diffs 0` |
| 3 | Important | 採納 | 句子改成第二版（`skills/code-simplifier/SKILL.md`）：點名 agent 那一節列的每一項、風格以被改的檔既有的寫法為準且混用時不統一、import 只合併同模組的重複行不改順序、專案 CLAUDE.md 有寫 import 規則時照它。改了字，前兩輪的證據不算它的：判定先 commit（6015e7b）再派第三輪 2 發，兩發都符合（結果在設計文件）。審查者舉的兩個情境（專案 CLAUDE.md 有寫 import 規則、規則寫在 ESLint 而全檔同一種寫法）照樣沒測，都列進 CHANGELOG 那一條的「沒有實測的」 |
| 4 | Important | 採納 | `UPGRADING.md` 改成三行：先 `grep -c 'workflow-review' ~/.claude/skills/review/SKILL.md`、`ls ~/.claude/commands/workflow-review`，兩行都對得上才 `rm -rf`，並寫明對不上時不要刪、`rm -rf` 沒有備份。沙盒 HOME 實跑三種：本 repo 部署的印 5 與 `review.md`；不相干的同名 skill 印 0（rc=1）；檔不在印找不到 |
| 5 | Smell | 採納 | `install-dd-pipeline.sh` 的 `deprecated_dd` 迴圈確實會刪五個舊 `dd-*.md`。`UPGRADING.md` 那句改寫 |
| 6 | Smell | 採納 | CHANGELOG 的限制寫明「這份素材是看過第一份的結果之後換的」；設計文件的判定句改成「判定式是派出前寫的，素材不是」 |
| 7 | Smell | 採納 | `UPGRADING.md` 取回那一條改成逐處列出（兩份 README 的幾處、CLAUDE.md、架構文件、測試斷言、CHANGELOG），加一句「先解決授權再加」 |
