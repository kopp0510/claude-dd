# S1-c（審查者 C）— ADHD output style

## 派工

subagent_type `code-reviewer`（agent 定義 opus），與 code-simplifier 並行派出。派工 prompt 原文：

> 你是程式碼審查者（代號 C）。審查 claude-dd repo（/Users/danlio/project/my_project/claude-dd）一個功能段落的整段變更：新增可開關的 ADHD 回覆風格（Claude Code output style），隨安裝腳本部署。
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
> 你的重點方向：風格檔 output-styles/adhd.md 本身（規則會不會跟全域 CLAUDE.md 打架、會不會讓 Claude 省略該講的事）與行為驗收 run.sh / check.sh 的有效性（判準有沒有鑑別力、會不會假通過、去識別完不完整）（其他方向看到也照報）
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

Critical 0 / Important 4 / Smells 0 — 範圍：`git diff df7535e HEAD`（94d4da2），從 review-diff.txt 讀；被改到的檔一律讀 diff 檔裡那一份

## Findings

**[Important] docs/measurements/2026-10-29-adhd-style/run.sh（「# 去識別」那段 sed）與 CLAUDE.md「怎麼重跑」第 4 步：去識別沒做完，而第 4 步那個「要回 0 筆」的檢查看不到漏掉的部分**
- 證據：8 份 out/*.jsonl 的 init 訊息都留著 `"memory_paths":{"auto":"<home>/.claude/projects/<編碼後的 scratchpad 路徑>/memory/"}`。我用 grep 掃，`<編碼後的 scratchpad 路徑>` 一共命中 8 次。同一則 init 還有 `"messaging_socket_path":"/tmp/cc-socks/71399.sock"`，以及 synced plugin 路徑 `plugins/synced/42b53a65-…_5577bddd-…/`。
- 為什麼漏：sed 只替換斜線形式的 `$WORK`、`pwd -P` 和 `$HOME`。Claude Code 把路徑編碼成 `-` 連接的形式，sed 對不上。第 4 步的 `grep -rl '/Users/\|/private/tmp'` 也只認斜線形式，結果回 0 筆，看起來就像去識別已經完成。
- 失敗情境：每次 commit 都會把使用者名稱、上層 session 的 UUID 和 scratchpad 的目錄配置帶進公開 repo，而文件宣稱「去識別」、「要回 0 筆」。使用者名稱本身已經出現在 repo 的 LICENSE 裡，所以這一項敏感度低。真正的問題是這個驗收方式給了假的保證，下次換一台機器或換一個 HOME 照樣會漏。

**[Important] check.sh 的鑑別斷言（d1、d2）與 CLAUDE.md「新增 Output Style 步驟」第 4 步：整套驗收實際上只證明了規則 3，其他規則壞掉也會通過**
- 證據：out/check.out 裡唯一判為「有鑑別力」的只有 d1（最後一行是 `下一步：`，規則 3 的字面要求），d2 的兩組都是「無鑑別力」。守門斷言在 default 臂也 8/8 成立，只能證明兩臂沒差，證明不了風格生效。規則 1、2、5、6、9、10 都沒有任何一條斷言會因為「風格失效」而變紅。
- 失敗情境：有人把 adhd.md 的規則 6（時間估計）或規則 10 刪掉，或改到失效，只要規則 3 還在，check.sh 照樣 exit 0。可是 CLAUDE.md 第 4 步說要靠這個驗收證明「回覆真的照規則走」。ADHD 臂其實已經出現「大約 3 分鐘」這類可以拿來判斷的特徵，check.sh 沒有用上。

**[Important] output-styles/LICENSE.txt「When to break the rules 5–6 —— 改寫，併入「誰優先」」：去向寫錯了**
- 證據：上游 SKILL.md 第 5 條的核心是「規則會刪掉答案本身時，任務優先」，例子是「what are my options gets 2 to 4 ranked options」。第 6 條講的是「do the work instead of asking 'want me to'」和「point time estimates at whoever executes the steps」。adhd.md 的「誰優先」只寫了「使用者指示與 CLAUDE.md 優先」，這兩條的內容都不在裡面。最接近第 5 條的句子是「真的超過兩個選項時照實說」，但它在「說話方式」一節，LICENSE 又把那一節歸給本機的 ELI5（我讀了 ~/.claude/output-styles/eli5-zh.md，確實有這一句）。
- 違反的規則：根 CLAUDE.md 收編清單規定「歸屬範圍精確到段落／項目…能逐條指出哪一段來自誰才算寫對」。照 LICENSE 去「誰優先」找，找不到第 5、6 條的內容。

**[Important] output-styles/adhd.md 規則 3、5 和全域 §6.1 可能衝突，驗收也測不到**
- 證據：規則 5 要求「每次都寫「第 N/M 步完成：<做了什麼>。下一步：<什麼>」」，規則 3 要求「最後一行寫 `下一步：…`」。上游第 6 條的「do the work instead of asking 'want me to'」沒有收進來（理由見上一條）。全域 §6.1 規定「決定好的下一步就直接做，不要只寫「接下來我會…」就結束這一輪」。「誰優先」列出的優先項（來源標註、回報格式、表態、失敗回報、進度說明）不含 §6.1，只有一句總括的「CLAUDE.md 的規則都優先」。
- 失敗情境（推論，沒實測）：多步的 agent 工作裡，模型每做完一步就寫「第 2/5 步完成…下一步：…」然後結束這一輪，等使用者回應。驗收的兩個 prompt 都是單一步驟（result 的 num_turns 都是 2–3），所以「沒把全域規則壓掉」這個宣稱沒有涵蓋到這種情況。

**[Important，文件只改了一半] DD_PIPELINE_ARCHITECTURE.md:53-54**
- 「直接改 `~/.claude/` 的 skills / agents / commands / scripts 會在下次安裝時被覆蓋（覆蓋前自動備份…）」這裡沒有補上 output-styles。同一份檔第 11、67 行的清單在這次 diff 裡都補了，而 create_output_styles 同樣是「有差異就備份再覆蓋」（`backup_before_overwrite "output-styles"`）。
- 失敗情境：使用者在本機改了 ~/.claude/output-styles/adhd.md，對照這段文件，以為它不在「會被覆蓋」的範圍內，結果下次安裝就被蓋掉（雖然有備份）。

## Not reported
- check.sh 在 `set -e` 底下那段 `[ "$arm" = ADHD ] && fail=1`（arm=default 時左邊回 1）：我用 /bin/bash 3.2 實跑過，不會中止，所以不報。
- d2 的 `${#f}` 會跟著 locale 變：在 LC_ALL=C 下算的是位元組，60 位元組約等於 20 個中文字。d2 在兩種 locale 下都無鑑別力，不影響這批的判定。
- run.sh 傳入 `/tmp/...`（非實體路徑）時，第一條 sed 會把 `/private/tmp/...` 改成 `/private<work>`：結果只是佔位符難看，沒有洩漏，不報。
- check.sh 檔頭說「default 臂兩條鑑別斷言全成立 → 未證明風格生效」，但 ADHD 臂只有 1/2 成立時也會印同一句。訊息本身沒錯，只是說明少列了一種觸發情況。
- 根 CLAUDE.md 寫 gate-guard 是「唯一的例外」：ADHD 的實證來源是驗收實跑，跟 plan-review 的前例一樣，不算新的例外。
- 新的 run.sh、check.sh 不在 CI 的 shellcheck 清單裡：既有的 docs/measurements/*/run.sh 也都不在，是 repo 的前例。

## What I ran
- 照 `##### FILE` 和 `diff --git` 的標記切出各段，讀了 ① 整段 diff（行 1–906，jsonl 用 jq 解析）、④ 驗證段，以及 HEAD 版本的 install-dd-pipeline.sh（backup_before_overwrite、create_scripts、uninstall、show_completion、main）和 ci.yml（ShellCheck 清單、數字宣稱、第五方）
- 用 jq 抽出 8 份 jsonl 的 `.result`、assistant 的 text、num_turns 和 cost，再看 init 的 keys、mcp_servers、plugins、memory_paths
- 用 grep 掃 jsonl 裡的 `danlio`、`/Users/`、`/private`、`claude-501`、`-Users-`：`<編碼後的 scratchpad 路徑>` 命中 8 次
- 用 `/bin/bash` 3.2 跑了一個 set -e 的小重現（`if` 裡 `[ … ] && fail=1`）：不會中止
- 上游 i-have-adhd：`git log`、`git describe` 得到 1ecea19 / v0.4.1；SKILL.md 最後變動於 5a9244e；`.claude-plugin/plugin.json` 的 version 是 0.4.1；LICENSE 的版權行一致；讀了 SKILL.md 全部各節
- 讀了 ~/.claude/output-styles/eli5-zh.md，核對「說話方式」的來源
- 用 `git grep` 掃 HEAD：`danlio`、`Users-danlio`、`去識別`、`--update`、`agents / commands`、`uninstall`、`output-style`、`ELI5`；也看了 tests/test-install.sh 第 1–66 行和 docs/reviews/CLAUDE.md 開頭

## 需要外部查證
- synced plugin 路徑裡的兩個 UUID（`42b53a65-…_5577bddd-…`）是不是 org 或帳號 ID：要看 Claude Code 文件，或問使用者，才知道值不值得遮掉
- `--uninstall` 移除 adhd.md 之後，settings 裡還留著 `outputStyle: "ADHD"` 時，Claude Code 會怎麼處理（靜默退回 default，還是報錯）：要開一個全新的 session 實測
- run.sh 檔頭寫的「claude ≥ 2.1.269」從哪來，我手上沒有證據；init 只顯示這次跑的是 2.1.312
- 規則 3、5 會不會讓多步任務每做一步就停下來：要用一個多步的 prompt 跑 `claude -p`，兩臂各跑一次，比較 num_turns 和最後一行

## 處置

- C1 去識別：同 A1，採納（Important），處置同 A1
- C2 驗收只證明規則 3：採納（Important）。加鑑別斷言 `d3`（具體時間估計，規則 6），並在量測 CLAUDE.md 新增「證明了什麼、沒證明什麼」一節，照實寫出規則 1、2、4、5、7–10 沒有對應的鑑別斷言。判準改了，所以兩臂整組重跑
- C3 LICENSE.txt 的 break 5–6 去向寫錯：採納（Important）。5 改寫進「說話方式」第二點與「誰優先」的「只管長什麼樣子」；6 改寫進「誰優先」新增的第二段，LICENSE.txt 逐句標出對應
- C4 規則 3、5 可能讓多步工作每步都停：採納（Important，推論）。`adhd.md`「誰優先」加一段：「下一步」與進度是寫給讀者看的，決定好的下一步就直接做、不要問要我繼續嗎（上游 break 6 的 do the work instead of asking）。**沒驗證**：重跑的兩個 prompt 仍是單步，量測 CLAUDE.md 把這項列在「沒證明」
- C5 `DD_PIPELINE_ARCHITECTURE.md` 53–54 行：同 B4
- 需要外部查證四項：見 `S1-judge.md`
