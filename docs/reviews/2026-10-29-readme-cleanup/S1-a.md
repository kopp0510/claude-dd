# S1-a（審查者 A）— 清理兩份 README

## 派工

subagent_type `code-reviewer`（agent 定義 opus），三個同一則訊息平行派出。派工 prompt 原文：

> 你是 8 步迴圈步驟 4 的審查者 A。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。
>
> 專案根目錄：/Users/danlio/project/my_project/claude-dd
> 審查範圍：git diff 15e3446 07a1730（清理兩份 README，加 CHANGELOG 一條、根 CLAUDE.md 一個節名）。
> 材料：<scratchpad>/rd-review-diff.txt。
> 用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔讀材料裡那一份，沒改到的檔讀 repo。
> 材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。
>
> 背景（事實）：使用者原話「README 太多廢話和歷史遺留的，請清理一下」。計畫審過 3 輪才動手。計畫要求：刪歷史敘述、量測過程、重複、只有維護者才需要的實作細節；留讀者要裝、要用、要判斷適不適合自己所需的資訊，以及授權資訊。兩份內容要一致。
>
> 你的方向：資訊遺失：逐段看 diff 裡被刪掉的每一句，判斷它是不是讀者要裝、要用、要判斷適不適合所需的資訊（行為、限制、預設值、會失敗的情況）。被刪的若是這類、而新版兩份都沒有，就是發現。也看壓短後的句子有沒有把條件弄丟（例如「只在 X 時」變成無條件）。
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

Critical 0 / Important 2 / Smells 0

## Findings
[Important] README.md:90 與 README.zh-TW.md:56（材料 diff 第 89、274 行，步驟 5）｜壓短時把「只在讀不到版本時才印安裝指令」改成了兩種情況都印，條件被放寬了
  證據：install-dd-pipeline.sh:784-786 在 plugin 不在磁碟上時只印 `Plugin 檔案不存在` 就 `continue`，不會印指令；`claude plugin install` 的提示只在 :828-829，也就是兩邊都讀不到版本字串的那條分支。新版寫的是 "A plugin that isn't on disk or has no readable version is skipped, with the `claude plugin install` command to run"，中文版是「找不到 plugin 或讀不到版本時跳過，並印出該跑的 `claude plugin install` 指令」。舊版兩份都把兩種情況分開寫，所以是對的。
  失敗情境：本機沒有 claude-md-management 的使用者照 README 等安裝提示，結果只看到紅字「Plugin 檔案不存在」，沒有任何指令可跑。這裡 README 寫的跟腳本實際行為不一樣，而且兩份 README 錯法相同。

[Important] README.md:121 與 README.zh-TW.md:126-127（dd.docfile 那條）｜兩份都刪掉了「只接受單純檔名，否則 exit 1」這個會失敗的情況，也刪掉了「設定存在 .git/config、不進版控」
  證據：scripts/check-claude-md.sh:29-33 的 `case "$DOC_FILE" in *[!A-Za-z0-9._-]*|.|..|-*) … exit 1`，這支腳本就是 pre-commit hook。新版兩份都只剩「只讀 `--local`，global、`-c`、`GIT_CONFIG_PARAMETERS` 不生效」，沒有寫檔名限制，也沒有寫設定不進版控。
  失敗情境：①使用者照「給只准放特定檔名的 repo 用」設了 `dd.docfile .github/copilot-instructions.md` 這種帶路徑的值，之後每個 commit 都會被 exit 1 擋下，README 沒有寫過這個限制。②「一個 repo 一個決定」讀起來像是 repo 層級、會跟著 clone 走的設定，但它存在 `.git/config`。協作者 clone 之後沒有這個設定，gate 改回找 `CLAUDE.md`，在只放 `GEMINI.md` 的 repo 裡就會被擋。

## Not reported
- 中文版附加步驟刪掉了「（任一個失敗會連帶擋掉後面的全域 CLAUDE.md 那步）」。install-dd-pipeline.sh:1383-1390 的順序與 `set -e` 確實是這樣，但英文版本來就沒有這句，刪掉後兩份反而一致；失敗時使用者也會直接看到安裝中止，所以不算讀者會因此做錯的資訊。
- task-planner 段刪掉了「只問決策題、要加哪些測試、審查判定只有你能決定的題目，不問整份計畫批不批准；卡住或冒出新工作會停下來問」。這是使用者會遇到的互動行為，新版改成指向 `templates/global/CLAUDE.md` §4.1 與 `skills/task-planner/SKILL.md`。這次沒有核對那兩份是否真的寫了這些，所以不報。
- gate 腳本不在時的括號舉例刪掉了「或已解除安裝」。一般條件「gate 腳本不在時只警告、不擋」還在，所以不算丟條件。
- 其他刪除的句子：改指 MCP 退化表的「疑似已設定…範圍未知」、改留在 Upgrading 的 `--force` 備份、留在步驟 8 列點的「先算範圍」、留在維護規則列點的 SKIP 欠帳擋 markdown commit、留在步驟 7 的「分享給別人」預設否。這些在新版都還有對應，逐條核過，沒有遺失。

## What I ran
- Read 材料 1-434 行（① diff 全段）與 960-974 行（④）→ 讀完
- `grep -n 'Plugin 檔案不存在\|取不到版本字串\|claude plugin install' install-dd-pipeline.sh` → :785 只印紅字、:828-829 才附 install 指令
- `sed -n 775,795p install-dd-pipeline.sh` → 檔案不存在的分支直接 `continue`
- `sed -n 1375,1395p install-dd-pipeline.sh` → create_scripts、create_output_styles 在 create_global_claude_md 之前
- `sed -n 24,40p scripts/check-claude-md.sh` → 檔名限制的 case 與 exit 1
- `grep -n 'git clone\|uninstall\|dd.docfile\|前置需求\|Prerequisites' README*.md` → 兩份仍有 clone 指令（:42/:43）與 Prerequisites／前置需求標題，所以根 CLAUDE.md 新改的節名對得上
- `grep -c '兩發聯集平均' CHANGELOG.md` → 1

## 需要外部查證
- `grep -n '決策題\|批不批准\|停下來問' skills/task-planner/SKILL.md templates/global/CLAUDE.md`：確認刪掉的 task-planner 互動行為在新指向的兩份檔案裡確實有寫，用來判斷上面 Not reported 第 2 條要不要升級成發現。

## 處置

- A1 步驟 5 合併後放寬了印指令的條件：採納（Important）。讀 `install-dd-pipeline.sh` 的 plugin 迴圈：`Plugin 檔案不存在` 那支直接 `continue`，`claude plugin install` 提示只在讀不到版本那支。兩份改回分開寫，並寫出 `Plugin 檔案不存在` 字串
- A2 dd.docfile 刪掉檔名限制與「不進版控」：採納（Important）。讀 `scripts/check-claude-md.sh` 的 `case "$DOC_FILE"` 與 `exit 1`。兩份補回「只接受單純檔名，否則每次 commit 都 exit 1」與「存在 `.git/config`、不進版控，每個 clone 各自設」
- 需要外部查證（task-planner 互動行為）：主對話已查，`skills/task-planner/SKILL.md` 第 4 步標題「送 plan-review，問決策題與測試清單」與其下的決策題說明都在，README 指過去成立
