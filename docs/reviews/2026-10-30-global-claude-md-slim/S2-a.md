# S2-a：審查者 A（搬家有沒有掉條件、指標有沒有懸空）

## 派工

`subagent_type: code-reviewer`，三個審查者同一則訊息平行派出。派工 prompt 是「先讀共用指示，再讀自己的方向」兩份檔，逐字如下。

共用指示：

> 你是 code-reviewer。repo：/Users/danlio/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md，全域規則在 templates/global/CLAUDE.md）。
> 審查範圍：段落 S2 的整段改動 = `git diff f2ab54a`（工作目錄乾淨，等於 f2ab54a..HEAD）。改動與被改檔的整檔內容都在 diff 檔：
> /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/s2-review/diff.txt
> （7865 行。用 Read 的 offset/limit 每次 300 行讀到最後一行 —— 一次讀太多會靜靜截斷、不報錯。被改到的檔一律讀 diff 檔裡那份；沒被改到的檔照常讀 repo。）
> diff 檔第 ④ 節是已跑過的驗證與結果，已確認、不要重跑測試／安裝／claude -p。
>
> 這段做了什麼（事實）：
> - S2-1（489bf74）新增 scripts/dd-init-upgrade.sh（升級分類器：舊蓋章區塊逐行查表分成範本行／在地行，--plan/--apply/--list）與 tests/test-dd-init-upgrade.sh，CI 加進 shellcheck 清單、ubuntu 與 bash32 job。
> - S2-2（304b0f2）commands/dd-init.md 蓋章區塊 rev 12（96 行）換成 rev 13（37 行），只在舊區塊裡的內容搬進 skills/dd-loop/SKILL.md；Phase 1 的 8step 舊版升級改用腳本；React 片段移到區塊外的 ````markdown 圍欄；CI 新增「現行蓋章區塊的每一行都在升級清單裡」；同批改 CHANGELOG、UPGRADING、根 CLAUDE.md、scripts/CLAUDE.md、tests/CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、設計文件。
> - 7b8638a：SKILL.md 的 `US$5.13` 改成「5.13 美元」（skill 帶參數呼叫時 `$<數字>` 會被代換）。
> - 舊區塊（rev 12）原文：`git show v1.6.12:commands/dd-init.md`。
>
> 你的職責：找漏洞，證明這段有錯。每條附證據（路徑:行 + 原文，或指令與輸出）；沒證據不算。只用手上的資料判斷，需要外部查證的列出來交回。
> 嚴重度：Critical / Important / Smell。不寫優點。
>
> 輸出格式：
> ## Findings（每條：級別｜檔:行｜問題｜證據｜失敗情境）
> ## Not reported（看到但判定不算的，一句理由）
> ## What I ran（指令照貼）

方向：

> 你的方向（A）：搬家有沒有掉條件或指標懸空。
> - 把 rev 12 舊區塊（git show v1.6.12:commands/dd-init.md 的 ```markdown 區塊）每一句的「條件與指向」，對照它現在的去處：新區塊、skills/dd-loop/SKILL.md、templates/global/CLAUDE.md §3.9／§4.4。設計文件 S2 有「舊區塊內容去處」的逐條判定，逐條驗它說的對不對（特別是判成「只是斷行或標點不同」「刪除」的那些）。
> - 這段 diff 動到的識別符與檔名（dd-loop-rev、蓋章區塊、dd-init-upgrade.sh、CLAUDE.md.dd-upgrade、React 片段…）各 git grep 一次，看「提到它的性質」的句子在 HEAD 還成不成立（含 README 兩份、DD_PIPELINE_ARCHITECTURE.md、diagrams/src、UPGRADING、各層 CLAUDE.md）。
> - 根 CLAUDE.md 規定跳 rev 時同批要改的 ①–⑤ 與「CI 不驗、只能手動同步的區塊」，逐項核有沒有做。

## 發現

（審查者交回的完整報告，逐字）

Critical 0 / Important 3 / Smells 0. 範圍：`git diff f2ab54a`（S2，到 HEAD 7b8638a），方向 A：搬家有沒有掉條件、指標有沒有懸空。

## Findings

[Important] commands/dd-init.md:67｜升級流程第 7.3 步拿 `grep -nE '^[0-9]+\. ' CLAUDE.md.dd-upgrade` 掃整份檔，要求「1–8 每號剛好一行」，但這個掃描沒限定在區塊內。
  證據：該行原文是「用 `grep -nE '^[0-9]+\. ' CLAUDE.md.dd-upgrade` 確認 1–8 每號剛好一行，才往下走」。測試清單 4 的沙盒專案（docs/measurements/2026-10-30-dd-init-upgrade/setup.sh 的 `hdr`、`locals`）在區塊外都沒有編號清單，所以 8 個案例全綠也證明不了這一點。
  失敗情境：專案 CLAUDE.md 在區塊外有自己的編號清單（例如設計文件提到 lawdesk-ai 區塊後還有一大段在地內容），就一定有重號。照這句做的 agent 可能卡在這一步，也可能把專案自己的編號行當成「重複的步驟行」去問使用者或刪掉。範圍應該限定在 `dd-loop-version` 標記到 `## CLAUDE.md 維護` 之間。

[Important] CHANGELOG.md:39｜「`/dd-init` 蓋章區塊同樣瘦身，見下一條」這個指標懸空。
  證據：這一條已經是 `## 未發布` 的最後一條，下一行就是 `## 1.6.12 — 2026-10-30`。講蓋章區塊瘦身的「rev 12 → 13，從 96 行…」是上一條。
  失敗情境：讀者往下找會找到已發布的 1.6.12 區塊。根 CLAUDE.md 規定已發布區塊不能再改，所以發版前沒修，這個錯指標就永遠留著。

[Important] docs/designs/2026-10-30-global-claude-md-slim-design.md 驗證 5 的「刪除」項（半號段落 `S2.5` 那兩行）｜刪除的理由是「全域 §4.4 已有同一條判準，每個 session 都載入」，但這句在兩處不成立，條件因此被收窄。
  證據：
  - templates/global/CLAUDE.md:505 的半號判準，寫在 §4.4「**兩者都沒有時**…退化成檔案式追蹤」那個 `>` 引言區塊裡，前後都是同一個引言區塊。
  - rev 12 原本把它放在步驟 4 的條列裡，沒有附帶條件。
  - 新區塊在 dd-init.md:77–78 寫「叫不到時（沒裝 claude-dd…）細則見 … `skills/dd-loop/SKILL.md`」，但 `grep -n -E '半號|S2\.5' skills/dd-loop/SKILL.md commands/dd-init.md` 是 0 筆命中。
  失敗情境：
  - 升級到 rev 13 的專案裡，有原生 Task 工具的 session 會把那段讀成「只適用於檔案式追蹤」，於是 hotfix 段落只跑步驟 1、2。
  - 沒裝 claude-dd 的協作者照區塊的後備指標去讀 SKILL.md，完全看不到這條判準。

## Not reported
- 舊區塊其他句子的去處：逐句看過，除了上面三條，都只是改寫或斷行不同，條件沒掉。包括兩個擋點、舊版 gate、diff 檔四項、`.git/`、`CODE_EXT`、步驟 7／8 關係、步驟 8 的 `$NF` 陷阱。「第一次一定被擋」在 SKILL.md:16–17 反而加了條件，更精確。
- 跳 rev 的同批清單 ①–⑤ 都有做。
  - ①：dd-init.md:38 與 :75 兩處都是 13。
  - ②：dd-init.md:40 與 UPGRADING.md:82 都是「rev 比 13 舊」。
  - ③：dd-init.md:41 有補 rev 12 那一句。
  - ④：CHANGELOG `## 未發布` 有條目。
  - ⑤：有 CI step 擋。
- 會有人當成問題但其實沒錯的：
  - UPGRADING.md:70–71 對 6step／7step／無標記仍寫「專案自己加的內容會保留」，跟新 Phase 1:48 一致。
  - UPGRADING.md:83 的「將刪除的行」「保留的行」跟腳本 `section()` 的標題一致。
  - README 兩份、DD_PIPELINE_ARCHITECTURE.md、diagrams/src/gen_usage.py、scripts/CLAUDE.md:46–49 提到蓋章或 dd-init 的句子，在 HEAD 都還成立。
- 細小的措辭流失，沒到門檻：
  - 「進度表的位置看根目錄 CLAUDE.md 開頭的指路句」這個定位提示沒搬進 SKILL.md:30。
  - SKILL.md:70 少了「不要自己去抓」這幾個字，但意思還在。
- 範圍外、這段之前就有：設計文件自己記下沒修的 3 處 SKILL.md 既有文字。

## What I ran
- `cat prompt-common.txt dir-a.txt` → 讀到指示
- `grep -n` 列 diff.txt 的結構 → 拿到各檔的區段行號
- `git diff --stat f2ab54a`；`git show v1.6.12:commands/dd-init.md > old-ddinit.md`；兩份都 `grep -n '^```'` → 舊區塊在 53–148，新區塊在 73–111，React 片段在 117–130
- `sed -n 40,175p old-ddinit.md`、`sed -n 1,160p commands/dd-init.md`、`cat -n skills/dd-loop/SKILL.md` → 對照全文
- `sed -n 185,300p` 設計文件 → 讀「舊區塊內容去處」和驗證 5 的判定
- `python3 -I cmp.py`（把舊區塊切成子句，正規化後去新區塊、SKILL.md、全域模板裡找）→ 找不到的大多只是改寫，再逐條人工判
- `git grep -n -E '蓋章區塊|蓋章版|區塊內|dd-loop-rev|dd-init-upgrade|dd-upgrade|React …'`（排除 docs/reviews、designs、measurements、CHANGELOG）→ 逐筆核過，都成立
- `grep -n 'rev 比' commands/dd-init.md UPGRADING.md`、`grep -n dd-loop-rev`、`grep -n '列出與現行版的差異'`、`sed -n 70,100p UPGRADING.md` → ①②③ 都有做
- `grep`／`sed -n 200,368p scripts/dd-init-upgrade.sh` → 對過 `--plan` 各節的標題
- `grep -n -i dd-init README*.md DD_PIPELINE_ARCHITECTURE.md diagrams/src/*.py`；`grep -n -E 'dd-loop|stamp|蓋章' …` → 都沒有過期的敘述
- `grep -n -E '半號|S2\.5' templates/global/CLAUDE.md skills/dd-loop/SKILL.md skills/task-planner/SKILL.md commands/dd-init.md`；`sed -n 485,515p templates/global/CLAUDE.md` → 只有全域模板:505 有，而且在「兩者都沒有時」的引言區塊裡
- `cat docs/measurements/2026-10-30-dd-init-upgrade/setup.sh` → 區塊外都沒有編號清單
- `sed -n 83,137p diff.txt` → CHANGELOG 與根 CLAUDE.md 的 diff
- `grep -n '見下一條' CHANGELOG.md`；`grep -n 'grep -nE' commands/dd-init.md` → 39；67

需要外部查證（我沒去查）：讀已蓋章專案（例如 lawdesk-ai、rental-management）的 CLAUDE.md，看區塊外有沒有 `^[0-9]+\. ` 的行。有的話，第一條就不只是推論，而是一定會發生。

## 處置

- Important｜7.3 的步驟重號檢查掃整份檔 → **採納**。改成只看區塊內（`dd-loop-version` 標記到 `CLAUDE.md 維護` 標題），附 awk 指令，並寫明區塊外專案自己的編號清單不算重號。外部查證我做了：12 個已蓋章專案的 CLAUDE.md 只數行（`grep -cE '^[0-9]+\. '`），9 個超過 8 行，所以照舊寫法一定卡住。對沙盒檔在區塊外加 `1.`、`2.` 兩行後，新指令仍只印 8 行。與 C 的第 3 條重疊
- Important｜CHANGELOG「見下一條」懸空 → **採納**。那句是 S1 條目原本的結尾，插入兩條新條目時被推到最後；搬回 S1 條目結尾
- Important｜半號段落判準在 §4.4 是有條件的引言區塊、SKILL.md 沒有 → **採納**。搬進 SKILL.md「段落起點與 `<起點>`」節尾，寫明「不管有沒有進度表、用哪種 task 工具都一樣」；設計文件的判定改寫並註明是審查後改的
- Not reported 的「進度表位置看指路句」「不要自己去抓」→ 同意不到門檻，不改
