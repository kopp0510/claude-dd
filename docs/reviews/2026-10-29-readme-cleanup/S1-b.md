# S1-b（審查者 B）— 清理兩份 README

## 派工

subagent_type `code-reviewer`（agent 定義 opus），三個同一則訊息平行派出。派工 prompt 原文：

> 你是 8 步迴圈步驟 4 的審查者 B。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。
>
> 專案根目錄：/Users/danlio/project/my_project/claude-dd
> 審查範圍：git diff 15e3446 07a1730（清理兩份 README，加 CHANGELOG 一條、根 CLAUDE.md 一個節名）。
> 材料：<scratchpad>/rd-review-diff.txt。
> 用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔讀材料裡那一份，沒改到的檔讀 repo。
> 材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。
>
> 背景（事實）：使用者原話「README 太多廢話和歷史遺留的，請清理一下」。計畫審過 3 輪才動手。計畫要求：刪歷史敘述、量測過程、重複、只有維護者才需要的實作細節；留讀者要裝、要用、要判斷適不適合自己所需的資訊，以及授權資訊。兩份內容要一致。
>
> 你的方向：新寫或改寫的句子對不對：每一句新句子的宣稱，對照它描述的來源（install-dd-pipeline.sh 的實際行為、scripts/check-claude-md.sh、commands/dd-init.md Phase 3、templates/global/CLAUDE.md §3.9／§4.1、skills/task-planner/SKILL.md、CHANGELOG.md 的五發實驗、docs/measurements/2026-10-23-reviewer-real-sessions.md、skills/gate-guard）。也查中英兩版每一段講的是不是同一件事。
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

Critical 0 / Important 2 / Smells 0 — 審查 git diff 15e3446 07a1730（兩份 README、CHANGELOG、根 CLAUDE.md）。方向 B：新寫的句子是否符合它描述的來源。

## Findings
[Important] README.md 安裝步驟 5（"A plugin that isn't on disk or has no readable version is skipped, with the `claude plugin install` command to run"）／README.zh-TW.md 步驟 5（「找不到 plugin 或讀不到版本時跳過，並印出該跑的 `claude plugin install` 指令」）｜兩份都寫成「plugin 不在磁碟上」時也會印安裝指令，實際上這條路徑不會印。
  證據：install-dd-pipeline.sh:784-786 `if [ ! -f "$plugin_json" ]; then echo ... Plugin 檔案不存在; continue`，這裡沒有提示。只有讀不到版本的分支（:828-829）才印「先跑 claude plugin install …」。舊文把兩種情況分開寫，是對的。
  失敗情境：新機器上 claude-md-management 還沒下載，讀者照 README 等安裝指令出現，結果只看到紅字「Plugin 檔案不存在」就結束，沒有任何下一步。

[Important] README.md CLAUDE.md maintenance rules 的 gate 那條（"…hands you a snippet to add to `.pre-commit-config.yaml` / `lefthook.yml` yourself (husky v9: `.husky/pre-commit`)"）／README.zh-TW.md 對應那條（「要你自己加進 `.pre-commit-config.yaml`／`lefthook.yml`（husky v9 加在 `.husky/pre-commit`）」）｜husky 的括號接在「要你自己加」那句後面，讀起來是 husky 也要手動加。實際上 /dd-init 會自己把 gate 寫進 `.husky/pre-commit`。
  證據：commands/dd-init.md:179-180，`core.hooksPath` 以 `.husky/_` 結尾時「掛載點改成 repo 根目錄的 `.husky/pre-commit`」，接著照一般流程寫入（:230-234 是 husky v8 和 v9 的插入位置規則）。只有 pre-commit 套件和 lefthook 走「交設定給使用者」（:184、:211）。舊文另起一句 "with husky v9 it goes into `.husky/pre-commit`"，沒有這個歧義。
  失敗情境：husky 專案的讀者以為要自己動 `.husky/pre-commit`，於是手動加 gate 呼叫，或在跑 /dd-init 前後自己再補一行，位置不對時 gate 會跑兩次。dd-init.md:230-231 寫明，插在 husky.sh 之前會跑兩次。

## Not reported
- 其他新句子我都對過來源，成立：CHANGELOG.md:498 確實有「兩發聯集平均」；docs/measurements/2026-10-23-reviewer-real-sessions.md 存在，內容是裁決者和直接派的比較；check-claude-md.sh:27 只讀 `--local`；gate 的修復格式在 :299-301；gate-guard 擋下時指向 SKIP_DOC_CHECK=1（guard-no-verify.sh:209）；templates/global/CLAUDE.md §4.1（:532-535）寫了估段落數、N≥2 就叫 task-planner；「step 8 用 claude-md-improver 審本輪動過的檔」符合 §3.9 步驟 8；根 CLAUDE.md 新的節名「前置需求／Prerequisites」對得上 README.zh-TW.md:32 和 README.md:31 的標題。
- 中英兩版其餘各段我逐段比過，講的是同一件事。zh 刪掉的「任一個失敗會連帶擋掉後面的全域 CLAUDE.md 那步」在 EN 本來就沒有，刪掉之後兩份反而一致。
- EN Highlights 的 "deployed … after an interactive diff" 沒有提到新機器上是詢問要不要安裝。這點步驟 7 已經寫了，不算錯，所以不列。

## What I ran
- Read rd-review-diff.txt 行 1-429、965-974 → 讀了整段 diff 和 ④ 的驗證紀錄
- grep CHANGELOG.md 兩發聯集平均；ls 量測檔；grep install-dd-pipeline.sh 的 plugin 訊息；grep 兩份 README 的前置標題 → CHANGELOG.md:498 命中、量測檔存在、訊息在 :785 / :828-829、標題在 README.md:31 和 README.zh-TW.md:32
- sed install-dd-pipeline.sh:775-792 → 不存在的分支只 echo 加 continue
- grep check-claude-md.sh 的 docfile 和修復訊息；grep dd-init.md 的 husky、lefthook、pre-commit → 結果如上面兩條證據
- grep gate-guard 的 SKIP_DOC_CHECK、量測檔的裁決者段、模板 §4.1 → 都成立

## 需要外部查證
無

## 處置

- B1 步驟 5：同 A1，採納，處置同 A1
- B2 husky 括號讀起來要手動加：採納（Important）。讀 `commands/dd-init.md` Phase 3 第 2 步：`core.hooksPath` 以 `.husky/_` 結尾時掛載點改成 `.husky/pre-commit` 照一般流程寫入。兩份改成另起一句「husky v9 則由 `/dd-init` 直接寫進 `.husky/pre-commit`」
