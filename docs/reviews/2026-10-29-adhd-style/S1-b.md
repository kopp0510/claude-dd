# S1-b（審查者 B）— ADHD output style

## 派工

subagent_type `code-reviewer`（agent 定義 opus），與 code-simplifier 並行派出。派工 prompt 原文：

> 你是程式碼審查者（代號 B）。審查 claude-dd repo（/Users/danlio/project/my_project/claude-dd）一個功能段落的整段變更：新增可開關的 ADHD 回覆風格（Claude Code output style），隨安裝腳本部署。
>
> 職責：找漏洞。每條發現附證據（diff 檔裡的行、或你 grep / 讀檔的結果）；沒證據不算。分級 Critical / Important / Smell。
>
> 材料：diff 檔 <scratchpad>/review-diff.txt（5258 行）
> - 組成：① `git diff df7535e HEAD` 整段；③ 被改到的檔的 HEAD 版本整檔（以 `######## FILE:` 分隔）；④ 已跑過的驗證與預期值
> - 用 Read 的 offset/limit 每次 300 行讀到最後一行（Read 一次讀太多會靜靜截斷、不報錯）
> - 被改到的檔一律讀 diff 檔裡那一份，不讀工作目錄（另一個 agent 正在改工作目錄）；沒被改到的檔照常讀 repo
> - ④ 列的驗證已確認，不要重跑
>
> 背景事實：
> - 使用者要求：「把我當作是 adhd 患者來回覆」「要可以帶著走」「要可以開或關」；選了「ADHD 風格裡順便放 ELI5 的重點，一個就夠」
> - 官方文件（https://code.claude.com/docs/en/output-styles.md）：使用者層風格檔放 `~/.claude/output-styles`；`/output-style <style>` 切換、寫進 `.claude/settings.local.json`；`default` 出現在 `/output-style` 清單裡、同樣方式選；`~/.claude/settings.json` 的 `outputStyle` 是全專案預設、專案設定優先；終端機啟動時才讀風格檔；`keep-coding-instructions` 預設 false
> - 專案規則：根目錄與各層 CLAUDE.md（尤其根 CLAUDE.md「注意事項」、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、`docs/reviews/CLAUDE.md`），全域規則 ~/.claude/CLAUDE.md
> - 上游 i-have-adhd clone 在 <scratchpad>/ihad/repo（核對 LICENSE.txt 的逐節去向用）
>
> 你的重點方向：文件與註解的宣稱（根 CLAUDE.md、兩份 README 同批一致、DD_PIPELINE_ARCHITECTURE.md、CHANGELOG、tests/CLAUDE.md、measurements CLAUDE.md、LICENSE.txt 逐節去向對上游原文）（其他方向看到也照報）
>
> 特別要查：註解與文件裡的宣稱（引別處的行為、函式、數字、UI 字串、檔案位置）在 HEAD 是否成立；diff 動到的識別符各 `git grep` 一次，看有沒有別處的敘述因此過期；bash 3.2 相容、`set -e` 下回非 0 的指令、變數緊貼全形字（`$var：` 要寫 `${var}：`）。
>
> 只用手上的資料判斷，需要外部查證（上網、跑 claude）的列出來交回。不改任何檔案。
>
> 輸出格式：
> ## Findings（每條：級別｜檔:位置｜問題｜證據｜失敗情境）
> ## Not reported（看到但判定不報的，各一句理由）
> ## What I ran（讀了哪些、grep 了什麼）
> ## 需要外部查證

## 發現

（存檔時做的去識別：session 暫存目錄換成 `<scratchpad>`、Claude Code 編碼過的專案目錄名換成 `<編碼後的 scratchpad 路徑>`；其餘照原文）

Critical 0 / Important 4 / Smells 0 — 範圍：df7535e..94d4da2 整段（ADHD output style），材料取自 review-diff.txt ①③④

## Findings

[Important] docs/measurements/2026-10-29-adhd-style/run.sh 的去識別 sed（diff 檔約 618–619 行：`s#$WORK#`、`s#$(pwd -P)#`、`s#$HOME#`）＋ 同目錄 CLAUDE.md「怎麼重跑」第 4 步（diff 檔 289 行）｜去識別漏掉 Claude Code 自己編碼過的路徑，用來驗收的 grep 也看不到這種寫法
  證據：init 訊息（diff 檔 400 行）裡的 `memory_paths.auto` = `<home>/.claude/projects/<編碼後的 scratchpad 路徑>/memory/`。projects 目錄的編碼會把 `/` 換成 `-`，所以三條 sed 都比對不到。`git grep -l '/Users/\|/private/tmp' HEAD -- …/out` → 0 個檔（文件說要回 0，結果也是 0）；`git grep -l danlio HEAD -- …/out` → 8 個檔，8 個 jsonl 全中。同一筆 init 還原樣留著 `messaging_socket_path`、`plugins[].path` 裡 synced 那筆的兩段 UUID（`42b53a65-…_5577bddd-…`，我不確定這是不是組織或帳號 ID），以及使用者接了哪些 claude.ai 連接器（Gmail、Google Drive、Calendar 等）。
  失敗情境：別人在自己的機器重跑 run.sh 再 commit，使用者名稱和 scratchpad 路徑會進公開 repo。文件寫的是「去識別後存」，而它指定的驗收 grep 回 0 筆，看起來像通過了。之前的量測（2026-10-24-s4/s5-outputs）只 commit 統計值，不 commit 原始 jsonl。

[Important] docs/measurements/2026-10-29-adhd-style/check.sh 的 d2（diff 檔約 325 行 `[ "${#f}" -le 60 ]`）｜`${#f}` 在不同 locale 下算出來的值不一樣：UTF-8 算字元，C locale 算位元組
  證據：拿同一行在 /bin/bash 3.2 實跑，en_US.UTF-8 得 36，LC_ALL=C 得 48。對 8 發 result 的第一行逐一量：ADHD-p1-r2 從 52 變 98，default-p2-r1 從 50 變 74，兩筆都跨過 60 這條線。專案自己就有這條約束：install-dd-pipeline.sh 的 uninstall() 註解寫「使用者機器的 locale 不可控」（diff 檔 ③ 裡的安裝腳本）。
  失敗情境：在 LC_ALL=C 下重跑 check.sh，產出會跟 commit 進去的 out/check.out 不同：ADHD-p1-r2 的 d2 由 ✓ 變 ✗，`d2 p2` 的 default 由 2/2 變 1/2。整體判定不變，因為通過靠的是 d1。但檔頭說「判準寫死、同一批資料不改判準」，結果卻會隨執行環境變。量測 CLAUDE.md 寫的「≤ 60 字」也只有在 UTF-8 下才成立。

[Important] 根 CLAUDE.md「新增 Output Style 步驟」第 4 步（diff 檔 83–84 行）｜叫人「新增或改了風格檔內文」就照 2026-10-29-adhd-style 重跑，但這套工具做不到新增風格的驗收，而且重跑會蓋掉有日期的證據
  證據：run.sh 寫死 `OUT="$HERE/out"`，臂也寫死成 `for arm in ADHD default`；check.sh 也寫死 ADHD/default 與這兩個 prompt 的斷言（diff 檔 321–347、595–619 行）。量測 CLAUDE.md 的「約束」寫「out/ 是當時的輸出，不要手改」「同一批資料不改判準」。根 CLAUDE.md（diff 檔 60–61 行）與 DD_PIPELINE_ARCHITECTURE.md（diff 檔 166–167 行）都把這個目錄引為「實證來源」。
  失敗情境：(a) 新增第二個風格時照第 4 步做，run.sh 根本不會跑到新風格，要跑就得改 check.sh，又違反那個目錄自己的約束。(b) 改了 adhd.md 之後照做，out/ 和 check.out 被新一批輸出覆蓋，兩份文件引用的「2026-10-29 實證」就不再是當時那批。

[Important] DD_PIPELINE_ARCHITECTURE.md 約 53–54 行（diff 檔 ③ 2675 行起那份的「修改一律改 repo 再重新部署；直接改 `~/.claude/` 的 skills / agents / commands / scripts 會在下次安裝時被覆蓋（覆蓋前自動備份到 `~/.claude/backups/`）」）｜同一份檔的第 11 行與第 67 行都補了 output-styles，只有這句沒補，屬於改一半的列舉（全域 §3.10「只改一半的統一比不改更糟」）
  證據：create_output_styles 對內容不同的檔，同樣會先 `backup_before_overwrite "output-styles"` 再 cp 覆蓋（diff 檔 696–698 行），行為跟 scripts 一樣。
  失敗情境：使用者在 `~/.claude/output-styles/adhd.md` 上直接改，看這句列舉沒有 output-styles，就以為不會被覆蓋。下次安裝內容不同，就被蓋回 repo 版（只剩備份）。

## Not reported
- run.sh 的 `rm -rf "$WORK"` 沒有防呆，參數打錯會刪掉別的目錄。用法和 CLAUDE.md 都寫明是拋棄式目錄，判定是用法風險，不算缺陷。
- run.sh、check.sh 不在 CI 的 shellcheck 清單裡：根 CLAUDE.md「新增 Script 步驟」只管 `scripts/`，④ 也顯示本機已跑過 shellcheck。
- LICENSE.txt 的逐節去向：我拿上游 1ecea19 的 SKILL.md 逐節對照，v0.4.1、5a9244e、4 點（不取 dopamine）、規則 1–10、break 1–4 都對得上。break 5–6 併入「誰優先」也說得通，因為「只管長什麼樣子、不改要寫什麼」就是 #5 的「the shape stays」。「說話方式」來自 ELI5，我對過 `~/.claude/output-styles/eli5-zh.md`，逐句對得上。規則 1 多了「或結論」、規則 9 措辭比上游窄一點，都只是改寫的程度，歸屬仍正確。
- d2 判準「第一行短、不是開場」跟全域 §1.2「先給結論、不寫開場白」部分重疊，所以「只用全域沒要求的特徵」這句對 d2 說不太過去。d2 本來就沒有鑑別力，不影響結論。
- check.sh 檔頭寫「default 臂兩條鑑別斷言全成立 → 印未證明」，只是充分條件，不完整但沒寫錯。
- tests/test-install.sh 檔頭第 3 行的用途列舉沒加 output style，但內容仍然成立。
- diagrams/src/*.svg 仍寫「skills / agents / commands」：那是產生出來的圖，不在這次 diff 範圍。
- README 兩份的新增列、CHANGELOG（在 `## 未發布`）、tests/CLAUDE.md、CI 的「第六組」、ARCH 的步驟順序（Commands → scripts → output-styles → 全域 CLAUDE.md，跟 main() 一致），以及 bash 3.2 寫法、set -e 下回非 0 的指令、變數緊貼全形字：都查過，沒發現問題。

## What I ran
- 用 sed/awk 分段讀 review-diff.txt（因為有超長 jsonl 行，改用 cut 截斷）：① 全部非 jsonl 的 diff、③ install-dd-pipeline.sh（backup_before_overwrite、create_scripts、uninstall、show_completion、main）、test-install.sh、tests/CLAUDE.md、ARCH 45–62 行、兩份 README 的相關行、④ → 都讀了
- 用 jq 解析 diff 檔 400 行的 init 訊息（keys、plugins、memory_paths、messaging_socket_path）→ 找到 memory_paths 帶有編碼過的使用者名稱
- `git grep -l '/Users/\|/private/tmp' HEAD -- …/out` → 0；`git grep -l danlio HEAD -- …/out` → 8
- 用 /bin/bash 3.2 在 UTF-8 與 C 兩種 locale 下量 `${#f}`，涵蓋 8 發 result 的第一行 → 結果見上方第二條
- 讀上游 ihad/repo：git log、describe、SKILL.md、plugin.json version、LICENSE → 跟 LICENSE.txt 宣稱的一致
- 讀 `~/.claude/output-styles/eli5-zh.md` → 跟「說話方式」逐句對得上
- `git grep` 查 `兩個不`、`unnumbered`、`五組`、`DD_SCRIPTS ↔`、`陣列一致性`、`附加步驟`、`skills / agents / commands`、`output.style|outputStyle|output-styles` → 除了 ARCH 53 行，沒找到其他過期敘述
- `ls docs/measurements` 與既有 outputs 目錄 → 之前的量測沒 commit 原始 jsonl
- 讀 ci.yml 的 shellcheck 清單，以及 check-claude-md.sh 的 CODE_EXT（.md 不算程式碼，所以 output-styles/ 不需要 CLAUDE.md）

## 需要外部查證
- run.sh 檔頭寫的 `claude ≥ 2.1.269` 這個版本下限：跑 `claude --version`，再翻 changelog 看 init 從哪一版開始有 `output_style` 欄位。
- `/output-style ADHD` 有沒有分大小寫，以及 `/output-style` 寫進 `.claude/settings.local.json`、`default` 怎麼關：這些來自派工說明裡的官方文件摘要，我沒有自己查。
- 移除安裝後，如果 settings 還留著 `outputStyle: "ADHD"`，Claude Code 怎麼處理（退回 default 還是報錯）：要開一個沙盒跑 `claude -p` 才知道。
- synced plugin 路徑那兩段 UUID 是不是組織或帳號 ID：要對照 claude.ai 帳號資訊。

## 處置

- B1 去識別：同 A1，採納（Important），處置同 A1
- B2 `d2` 的 `${#f}` 隨 locale 變：採納（Important）。字數改用 `jq` 的 `length` 算；拿第一批資料在預設與 `LC_ALL=C` 各跑一次，`d2` 結果相同
- B3 第 4 步叫人在原目錄重跑、新增風格做不到：採納（Important）。第 4 步改成開新的日期目錄、照這套改出新風格的臂與斷言；量測 CLAUDE.md 的「約束」寫明 `out/` 是被引用的證據、不在原處重跑
- B4 `DD_PIPELINE_ARCHITECTURE.md` 53–54 行漏 output-styles：採納（Important），已補
- 需要外部查證四項：見 `S1-judge.md`
