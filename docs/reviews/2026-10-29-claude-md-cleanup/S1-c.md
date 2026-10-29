# S1-c（審查者 C）— 清理各層 CLAUDE.md

## 派工

subagent_type `code-reviewer`（agent 定義 opus），三個同一則訊息平行派出。派工 prompt 原文：

> 你是 8 步迴圈步驟 4 的審查者 C。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。
>
> 專案根目錄：/Users/danlio/project/my_project/claude-dd
> 審查範圍：git diff 2d436c0 86f37df（清理各層 CLAUDE.md 與全域模板，加 CHANGELOG 一條）。
> 材料：<scratchpad>/cm-review-diff.txt（完整路徑：<scratchpad>/cm-review-diff.txt）。
> 用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔讀材料裡那一份，沒改到的檔讀 repo。
> 材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。
>
> 背景（事實）：使用者原話「所有的CLAUDE.md 和README.md 都是檢查 有沒有多餘廢話 或老舊資訊 不可靠 沒有參考價值的 都清理」，並選了清理「有把握可刪」與「寫短（拿掉日期、故事）」兩類；「可能可刪（沒驗證）」那類不動；寫錯或過時的直接修。判準：拿掉會不會讓人做錯事；規則本身要留，只拿掉日期、故事、重複。全域模板 templates/global/CLAUDE.md 會部署成使用者的 ~/.claude/CLAUDE.md。
>
> 你的方向：同步點：repo 裡還有誰引用被改掉的句子或被刪的段落（git grep 被刪內容的特徵字串、節名、檔內指標，例如 tests/test-gate.sh 指向 tests/CLAUDE.md 的「恆真」、scripts/CLAUDE.md 指向 tests/CLAUDE.md 的句子）；commands/dd-init.md 的蓋章區塊有沒有逐字抄了被改的全域模板句子（有就要跳 dd-loop-rev）；兩份 README、DD_PIPELINE_ARCHITECTURE.md 有沒有依賴被改的句子；CHANGELOG 那條描述的是否就是實際做的事；Markdown 表格與清單結構有沒有被弄壞。
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

Critical 0 / Important 4 / Smells 0（範圍是 git diff 2d436c0 86f37df，以 HEAD=86f37df 為準）

注意：我審到一半時工作目錄被改了（`git diff HEAD --stat` 顯示 5 個檔有改動、還沒 commit）。下面 I1、I2 這兩條，工作目錄裡已經有對應的修改；以 HEAD 來看仍然成立。

## Findings
[Important] diagrams/src/CLAUDE.md:51（HEAD）｜「（要 ≥12px）」把當初的量測值改寫成一個沒有出處的門檻
  證據：舊版寫的是「（2026-09-11 四張都 ≥12px）」，是一次量測結果。`verify-geometry.py` 的 `check_text_overflow`（678–697）只用 0.5px 容差判斷文字有沒有超出框，沒有 12px 這種要求。`composition-quality-contract.md` 裡的 12px 只出現在 port 間距和平行線間距，跟文字溢出無關。
  失敗情境：之後改圖的人看到某段字尾離框右緣 8px，會以為沒過而去改版面，但它其實沒問題。工作目錄已經改成「這是量到的值，不是門檻」。
[Important] CLAUDE.md:24（HEAD）｜指標說「各元件的加入日期與實證來源見 DD_PIPELINE_ARCHITECTURE.md『部署清單』」，但那節沒有 tech-diagram-gif 的實證來源
  證據：這次刪掉的舊段落寫著「實證來源為當次對話的完整管線驗證」。HEAD 的 DD_PIPELINE_ARCHITECTURE.md:81 只寫到「2026-08-10 新增自製 tech-diagram-gif」，plan-review 和 ADHD 有寫來源，它沒有。結果是這條資訊搬家時掉了，指標指向一個不存在的東西。
  失敗情境：照指標去找 tech-diagram-gif 為什麼被收，什麼都找不到，而原本的那句已經刪了。工作目錄的 ARCH 已經補上。
[Important] skills/tech-diagram-gif/scripts/verify-geometry.py:344（不在 diff 裡，但被這次 diff 弄斷）｜docstring 說「英文版因此誤報十幾處文字溢出（同目錄 CLAUDE.md 的字級那條記過）」，但被指到的那條內容已經刪了
  證據：這次 diff 把 skills/tech-diagram-gif/scripts/CLAUDE.md 的「猜高了誤報（`gen_loop`/`gen_usage` 的 `.nm` 實際 15 卻當成 20，英文版誤報十幾處文字溢出）」改成只剩「猜高了誤報文字溢出」（現在第 38 行）。`grep -n '十幾處' skills/tech-diagram-gif/scripts/CLAUDE.md` 找不到任何一行。diagrams/src/CLAUDE.md 裡同一件事的紀錄（「2026-09-12 起誤報少很多…從 1 降到 0」）也一起刪了。
  失敗情境：讀程式的人照這個「記過」去找佐證，找不到，等於這句宣稱沒有出處。
[Important] CHANGELOG.md:37–40｜「順手修正幾處寫錯或過時的：」後面列了四項，看起來是完整清單，但這次 diff 改掉的過時說法不只這四處
  證據：漏掉的有：①會部署的全域模板 §7.2 表格有兩列從「派 Task」改成「用 Agent 工具派」（templates/global/CLAUDE.md:809、813）；②根 CLAUDE.md 殘留清理表的「與 DD wrapper 撞名」改成「與 DD 的同名 agent 撞名」；③diagrams/src/CLAUDE.md 的 style-8 路徑從 `~/.claude/skills/...` 改成 `../../skills/...`。
  失敗情境：使用者讀 CHANGELOG 決定要不要接受模板差異時，以為模板只是拿掉日期和故事，不知道 §7.2 這張觸發表的內容也變了。

## Not reported
- scripts/CLAUDE.md:97 還在用現在式寫「`test-gate.sh` 前 61 項」。tests/CLAUDE.md 禁止寫死項數，而這次 diff 剛好把記錄這個毛病的那句教訓刪了。毛病本身是既有問題，所以不列為發現。
- `error-capture.sh:15` 的「Install: Add to .claude/settings.json」跟新寫的「不要手動加」互相矛盾。hooks/CLAUDE.md 新加的那段已經自己承認這點，不另報。
- `skills/self-improving-agent/settings.json` 帶著一個非標準格式的 `hooks` 鍵，是上游既有的，不在 diff 裡。
- 查過沒有問題：tests/test-gate.sh:355 指向「恆真」（還在，第 41 行）；test-gate.sh:304/308/338 指向 scripts/CLAUDE.md 的「不是閉環」、三條繞過路徑和變異實測（還在）；dd-init.md:97「不要把它寫成閉環」成立；模板拿掉的「沒印出這行就是沒記好」只是重複句，dd-init.md:61 仍保留，不需要跳 rev；兩份 README 和 DD_PIPELINE_ARCHITECTURE.md 都沒有引用被刪的段落；CHANGELOG 說 CI 會比對 UPGRADING 判定線（ci.yml:342）成立；「列出與現行版的差異」在判定線下一行成立；tag 存在；style-8 路徑存在；三支 .ttl 都是 40px；被改過的 Markdown 表格結構都沒壞；hooks.json 確實會自動載入。

## What I ran
- `git diff --stat 2d436c0 86f37df`；材料分三次讀完；git grep 恆真／三組數字／不是閉環／派 Task／沒印出這行／dd-start／舊 DD Pipeline；grep dd-init.md 界線與判定線、ci.yml UPGRADING；`sed -n 77,100p DD_PIPELINE_ARCHITECTURE.md`；ls/cat self-improving-agent；git grep 腳本裡「見／記在 … CLAUDE.md」→ verify-geometry.py:344；`sed -n 678,697p verify-geometry.py`；在 scratchpad 跑 gen_loop/gen_usage 與 verify-geometry.py（loop-zh-TW 沒有溢出，其他三張各 1–2 處），跑完刪掉暫存目錄；`git tag -l 'pre-prune*'`；`git diff HEAD --stat`

## 需要外部查證
- 無

## 處置

- C1：同 A1；C2：同 B2
- C3 `verify-geometry.py` 的 docstring 指向被刪的「十幾處」：採納 Important。不改程式碼，把那句括號補回 `skills/tech-diagram-gif/scripts/CLAUDE.md`
- C4 CHANGELOG 的修正清單看起來是完整的：採納 Important。補上 §7.2「派 Task」、wrapper 撞名、style-8 路徑三項，並寫明「不只下面這些」
