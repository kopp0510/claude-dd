# S1-a（審查者 A）— 清理各層 CLAUDE.md

## 派工

subagent_type `code-reviewer`（agent 定義 opus），三個同一則訊息平行派出。派工 prompt 原文：

> 你是 8 步迴圈步驟 4 的審查者 A。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。
>
> 專案根目錄：/Users/danlio/project/my_project/claude-dd
> 審查範圍：git diff 2d436c0 86f37df（清理各層 CLAUDE.md 與全域模板，加 CHANGELOG 一條）。
> 材料：<scratchpad>/cm-review-diff.txt（完整路徑：<scratchpad>/cm-review-diff.txt）。
> 用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔讀材料裡那一份，沒改到的檔讀 repo。
> 材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。
>
> 背景（事實）：使用者原話「所有的CLAUDE.md 和README.md 都是檢查 有沒有多餘廢話 或老舊資訊 不可靠 沒有參考價值的 都清理」，並選了清理「有把握可刪」與「寫短（拿掉日期、故事）」兩類；「可能可刪（沒驗證）」那類不動；寫錯或過時的直接修。判準：拿掉會不會讓人做錯事；規則本身要留，只拿掉日期、故事、重複。全域模板 templates/global/CLAUDE.md 會部署成使用者的 ~/.claude/CLAUDE.md。
>
> 你的方向：規則遺失：逐條看被刪掉或縮短的句子，判斷裡面有沒有「規則、條件、做法、會失敗的情況、唯一的指標或證據出處」被一起拿掉。被刪的若是這類、而同檔或它指向的地方沒有留下，就是發現。「別處已經講了」要自己去那裡讀確認。也看縮短後條件有沒有變寬或變窄。
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

Critical 0 / Important 4 / Smells 0 — 範圍是 git diff 2d436c0 86f37df（審查者 A，看規則有沒有被一起刪掉）

## Findings
[Important] diagrams/src/CLAUDE.md:51｜原本記的是一次觀察結果，縮短後變成了沒有出處的通過門檻
  證據：舊文「以渲染後 `getBBox()` 量到的字尾與框右緣距離為準（2026-09-11 四張都 ≥12px）」，新文「…為準（要 ≥12px）」。`verify-geometry.py` 的 `check_text_overflow`（:678–697）判溢出只看有沒有超出框邊，容差 0.5px。contract 和 SKILL.md 裡的 ≥12px 只用在 port 間距與平行連線間距（composition-quality-contract.md:56–57），沒有任何一處規定「文字到框邊要 ≥12px」。
  失敗情境：改 gen_loop/gen_usage 之後，某段字尾離框右緣 8px，其實沒有溢出。照新文判，它會被當成不合格去重排；這條門檻是這次清理憑空造出來的，條件變窄了。

[Important] scripts/CLAUDE.md:129｜唯一能定位證據的路徑被刪了，剩下的「S6-a 的 A2 / S6-b 的 B2」會指到兩份檔
  證據：被刪的句子是全段唯一寫出路徑的地方（「S4 的 review 去 grep `docs/reviews/S6-{a,b}.md`」）。repo 裡有兩組同名檔：`docs/reviews/S6-a.md` 和 `docs/reviews/2026-10-23-裁決審查/S6-a.md`，兩份都有 A2 和 B2。前者的 A2/B2 是退化規則漂移（S6-a.md:18、S6-b.md:14），後者的 A2 是「驗收照字面不成立」、B2 是 README 措辭（裁決審查/S6-a.md:71、S6-b.md:70）。
  失敗情境：讀者去核「兩處已經漂移」的出處，先找到 `2026-10-23-裁決審查/S6-a.md` 的 A2，那裡有一條格式相同、內容無關的發現，讀者就停在那裡。這正是 §3.10「指錯檔，而那裡真的有同型的東西」那一類。

[Important] docs/reviews/CLAUDE.md:39｜判例縮短後找不到是哪份檔、更正的是什麼，也少了第二個更正位置
  證據：舊文寫明「2026-10-07 S4 的 reviewer 指出 `S6-a.md` A2 的『新增測試情境 ⑦ 釘住它』是假宣稱…更正寫進 `…/S4-a.md` 的處置與 `tests/test-gate.sh` 的註解」。新文只剩「`S6-a.md` 沒動，更正寫在 `…/S4-a.md` 的處置」。`S6-a.md` 同樣有上面那兩份，`tests/test-gate.sh:276` 的 ⑦ 註解這個更正位置也被刪了。
  失敗情境：這條規矩的意思是「原報告不改，更正寫在後來的報告裡」。照判例去查的人分不出是哪份 S6-a.md，也不知道 A2 被更正了什麼，判例因此失去示範作用。

[Important] docs/reviews/CLAUDE.md:32｜舊慣例的日期邊界被刪，「兩份一組可以」的條件因此變寬
  證據：舊文「2026-10-24 以前的報告是兩份一組（`-a`、`-b`）」，新文「舊報告有兩份一組（`-a`、`-b`）的…那是當時的慣例，不改」。同一個目錄 `2026-10-23-裁決審查/` 裡 S1、S2 是兩份一組，S3 起是 3 份以上加 `-judge.md`；把同目錄的新舊分開的，只有那個日期。
  失敗情境：之後有一段只附了 `-a`、`-b` 兩份（違反全域 §3.9 至少 3 份的規定）。稽核的人讀這份 CLAUDE.md，會把它歸成「舊報告、當時的慣例、不改」，不會判成缺報告。

## Not reported
- 根 CLAUDE.md 說「各元件的加入日期與實證來源見 `DD_PIPELINE_ARCHITECTURE.md`『部署清單』」。那裡沒有 tech-diagram-gif 的實證來源（舊根 CLAUDE.md 寫的是「當次對話的完整管線驗證」），ADHD 的「來源是使用者要求」也沒寫。這條沒達到發現的門檻：被刪掉的內容本來就無從查證。
- 取回指令只寫了 `skills/<名字>`，舊的 `git show pre-prune-2026-08-04:commands/dd-dev.md` 被刪了。路徑寫錯時 git 會直接報錯，不會靜默出事，所以不列為發現。
- 既有問題、不在 diff 裡：scripts/CLAUDE.md 的 context 行仍寫「含 `test-gate.sh` 前 61 項用的拋棄式 repo」，這是現在式的寫死項數，與 tests/CLAUDE.md 禁止寫「N 項」的規定衝突。
- 另外逐條核過，都已經有別處承接：刪掉的「本 repo gate 同各專案」由根 CLAUDE.md:165 承接；「不是閉環／永遠不開下一段」由 scripts/CLAUDE.md:78、83 和 dd-init.md:97 承接；opt-in 的三組變異數字仍在 tests/CLAUDE.md:33–38；§3.10 刪掉的指向句，§3.9 仍有原句（template:376）；`--segment-base` 的功能說明仍在 scripts/CLAUDE.md:117–126；CI 比對 UPGRADING 判定線的宣稱屬實（ci.yml:332–342）；self-improving-agent 的 hooks.json 與 plugin.json 存在，error-capture.sh:15 的 `Install:` 註解也和新文描述一致。

## What I ran
- Read cm-rev-prompt-A.txt 與 cm-review-diff.txt（每次 300 行，讀到第 715 行）→ 全部讀完
- grep 部署清單、閉環、SKIP_DOC_CHECK、S6-a/b、2026-10-24、派 Task、12px → 找到兩組 S6-a.md；`派 Task` 已無殘留
- grep A2/B2 於四份 S6-a/b → 兩組各自的 A2/B2 內容不同（行號見上）
- grep 12px／溢出 於 tech-diagram-gif；sed verify-geometry.py:678–697 → 溢出判定沒有 12px 門檻
- git show 2d436c0:diagrams/src/CLAUDE.md | grep getBBox → 舊文是觀察句「2026-09-11 四張都 ≥12px」
- grep ci.yml 的 UPGRADING／判定為舊版 → 有比對（:332–342）
- grep 閉環 於 dd-init.md → :97 有寫
- sed DD_PIPELINE_ARCHITECTURE.md 77–100 → 有日期，tech-diagram-gif 沒有實證來源
- cat self-improving-agent hooks.json；grep gate-guard「與上層的關係」→ 檔案與章節都存在
- ls docs/reviews 各個子目錄 → 裁決審查/ 的 S1、S2 是兩份一組，S3 起是 3 份以上加 judge

## 需要外部查證
- 無

## 處置

- A1 diagrams:51「要 ≥12px」變成門檻：採納 Important（讀 `verify-geometry.py` 的 `check_text_overflow`，容差 0.5px、沒有 12px）。改回量測值，並寫明「不是門檻」
- A2 scripts 的「S6-a 的 A2 / S6-b 的 B2」指到兩份同名檔：採納 Important（`ls` 確認 `docs/reviews/S6-a.md` 與 `docs/reviews/2026-10-23-裁決審查/S6-a.md` 都存在）。補上完整路徑，並註明另一組同名檔是別的事
- A3 docs/reviews:39 判例縮太短：採納 Important。補回「⑦ 釘住它」是假宣稱、與 `tests/test-gate.sh` ⑦ 的註解這個更正位置
- A4 docs/reviews:32 刪了日期邊界：採納 Important。補回「2026-10-24 以前」，並加「之後的段落照上面的格式」
- Not reported 的「前 61 項」：不改。第 1 輪 plan-review 已判它是位置描述（`tests/test-gate.sh` 也這樣寫），不是過期的項數
