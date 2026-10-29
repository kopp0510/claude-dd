# S1-b（審查者 B）— 清理各層 CLAUDE.md

## 派工

subagent_type `code-reviewer`（agent 定義 opus），三個同一則訊息平行派出。派工 prompt 原文：

> 你是 8 步迴圈步驟 4 的審查者 B。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。
>
> 專案根目錄：/Users/danlio/project/my_project/claude-dd
> 審查範圍：git diff 2d436c0 86f37df（清理各層 CLAUDE.md 與全域模板，加 CHANGELOG 一條）。
> 材料：<scratchpad>/cm-review-diff.txt（完整路徑：<scratchpad>/cm-review-diff.txt）。
> 用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔讀材料裡那一份，沒改到的檔讀 repo。
> 材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。
>
> 背景（事實）：使用者原話「所有的CLAUDE.md 和README.md 都是檢查 有沒有多餘廢話 或老舊資訊 不可靠 沒有參考價值的 都清理」，並選了清理「有把握可刪」與「寫短（拿掉日期、故事）」兩類；「可能可刪（沒驗證）」那類不動；寫錯或過時的直接修。判準：拿掉會不會讓人做錯事；規則本身要留，只拿掉日期、故事、重複。全域模板 templates/global/CLAUDE.md 會部署成使用者的 ~/.claude/CLAUDE.md。
>
> 你的方向：新寫或改寫的句子對不對：每一句新宣稱（例如 .ttl 40px、style-12 沒有 .sm、hooks.json 自動載入、CI 會比對兩條判定線的 rev、grep 指令、指向別處的路徑與節名）對照它描述的來源實際讀一次或跑一次 grep。也查改寫後句子的語法與意思是不是通順完整（替換後有沒有殘句、斷句、多餘空格）。
>
> 輸出（照抄標題）：
> Critical N / Important N / Smells N
> ## Findings
> [級別] 檔:行｜一句話
>   證據：…
>   失敗情境：…
> ## Not reported
> ## What I ran
> ## 需要外部查證

## 發現

Critical 0 / Important 2 / Smells 1
（審查範圍：git diff 2d436c0 86f37df）

## Findings
[Important] diagrams/src/CLAUDE.md:51｜「（要 ≥12px）」把一次量測值改寫成了一條門檻規則，但這條規則找不到出處
  證據：舊版寫的是「（2026-09-11 四張都 ≥12px）」，是量到的結果（`git show 2d436c0:diagrams/src/CLAUDE.md | grep -n 12px` 第 51 行）。`verify-geometry.py` 的 `check_text_overflow()` 容差只有 0.5px（`x2 > hi + 0.5`）。`composition-quality-contract.md` 裡的 ≥12px 只用在 port 間距與平行連線間距，沒有用在文字與框右緣的距離。
  失敗情境：之後有人改 loop 或 usage 圖，量到字尾離框右緣 8px。他會照這句判成不合格而去重排版面，但腳本與 contract 都沒有這條規定。

[Important] CLAUDE.md:40｜「各元件的加入日期與實證來源見 `DD_PIPELINE_ARCHITECTURE.md`「部署清單」」，但那節沒有 tech-diagram-gif 的實證來源
  證據：`DD_PIPELINE_ARCHITECTURE.md` 第 77–85 行只寫「2026-08-10 新增自製 tech-diagram-gif」。舊版根 CLAUDE.md 第 23 行寫的「實證來源為當次對話的完整管線驗證」這次刪掉了，也沒有搬到 ARCH。其餘元件（plan-review、ADHD、gate-guard）在 ARCH 都還在。
  失敗情境：下次照使用率盤點制清點時，有人順著這個指標去找 tech-diagram-gif 的實證，找不到，就可能把它判成沒有實證的元件。

## Smells
[Smell] CLAUDE.md:170｜「…那串「列出與現行版的差異」（`grep -n '列出與現行版的差異' commands/dd-init.md`）（新增一句「rev N 缺什麼」，…）」兩個括號直接連在一起，讀起來像斷句；把 grep 那個括號併進前文或移到句尾就順了。內容本身核對過是對的：dd-init.md:40 是判定線，:41 是「列出與現行版的差異」，「判定線下一行起」成立。

## Not reported
- scripts/CLAUDE.md:99 還寫著「`test-gate.sh` 前 61 項」，是寫死項數的現在式句子。這次 diff 刪掉了 tests/CLAUDE.md 裡解釋這件事的那句，但 :99 這行本身是舊的問題，不是這次引入的。
- skills/self-improving-agent/hooks/error-capture.sh:15 的 `# Install: Add to .claude/settings.json` 仍是上游原文。hooks/CLAUDE.md 新增的那段已經寫明「還沒改」，所以不算假宣稱。
- 以下新宣稱都核對過，成立：`.ttl` 三支都是 40px；style-12 沒有 `.sm`；style-11 是 `.sm` 14、`.nm` 19、`.al` 14、`.ttl` 26；`../../skills/tech-diagram-gif/references/style-8-dark-luxury.md` 從 diagrams/src 解析得到；tag `pre-prune-2026-08-04` 存在；ci.yml「迴圈步數四方一致」step 有比對兩條判定線上的 rev（第 332–356 行，含「抓不到那行」）；`code-reviewer`、`security-auditor` 都在 agents/；dd-init.md:97 在蓋章區塊（52–149 行）內，寫了「不要把它寫成閉環」；`2026-10-07-review-followups/S4-a.md` 的處置確實記了 S6-a A2 ⑦ 的更正；`S6-a` 的 A2、`S6-b` 的 B2 確實是漂移那項；`2026-10-23-裁決審查/` 的 S3–S5 是裁決者寫的；gate-guard/hooks/CLAUDE.md 有「與上層的關係」節；self-improving-agent 有 `.claude-plugin/plugin.json` 與絕對路徑的 `hooks.json`，本 session 執行 Bash 時 error-capture hook 實際觸發了；全庫 `git grep '派 Task'` 0 筆；「.ttl 實測也會錯」的新敘述符合歷史（104df7b、51ad5d7、766153c、b15432f）。

## What I ran
- `git diff --stat 2d436c0 86f37df`；Read 每次 300 行讀完 cm-review-diff.txt（715 行）；`sed -n 77,95p DD_PIPELINE_ARCHITECTURE.md`；`git tag | grep pre-prune`；`sed -n 330,365p .github/workflows/ci.yml`；`grep -n '列出與現行版的差異\|rev 比' commands/dd-init.md`；`grep -n ttl diagrams/src/gen_*.py`；解析 style-11、style-12 的 `<style>`；grep 12px 於 contract/SKILL/verify-geometry.py 加 `sed -n 678,697p`；`git show 2d436c0:diagrams/src/CLAUDE.md | grep -n 12px`；`grep -n '閉環' commands/dd-init.md`；ls/cat self-improving-agent；grep S6-a/S6-b A2/B2 與 followups/S4-a.md；`git log -S'.ttl {{'`；`git grep -n '派 Task'`

## 需要外部查證
- 讀 `~/.claude/settings.json`，確認 hooks 裡沒有手動又登記一次 error-capture.sh。

## 處置

- B1 diagrams:51：同 A1
- B2 tech-diagram-gif 的實證來源搬家時掉了：採納 Important。補進 `DD_PIPELINE_ARCHITECTURE.md`「部署清單」
- B3（Smell）兩個括號連在一起：採納，併成一個括號
- 需要外部查證（`~/.claude/settings.json` 有沒有手動登記 error-capture）：主對話用 jq 讀 `.hooks`，`error-capture` 命中 0 筆，新句子成立
