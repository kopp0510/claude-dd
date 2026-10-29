# S1-a（審查者 A）— ADHD output style

## 派工

subagent_type `code-reviewer`（agent 定義 opus），與 code-simplifier 並行派出。派工 prompt 原文：

> 你是程式碼審查者（代號 A）。審查 claude-dd repo（/Users/danlio/project/my_project/claude-dd）一個功能段落的整段變更：新增可開關的 ADHD 回覆風格（Claude Code output style），隨安裝腳本部署。
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
> 你的重點方向：安裝腳本與測試的正確性（install-dd-pipeline.sh 的部署／移除／完成訊息、tests/test-install.sh 斷言的鑑別力、ci.yml 第六組）（其他方向看到也照報）
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

Critical 0 / Important 3 / Smells 0。範圍：`git diff df7535e HEAD`（94d4da2），重點看安裝腳本、測試、ci.yml 第六組。

## Findings

1. **Important｜`docs/measurements/2026-10-29-adhd-style/run.sh` 的去識別 sed，以及 `CLAUDE.md`「怎麼重跑」第 4 步的驗收 grep**
   - 問題：去識別沒做乾淨，而驗收用的 grep 認不出漏掉的那種寫法，所以照樣回 0 筆。
   - 證據：run.sh 只換掉 `$WORK`、`pwd -P` 和 `$HOME` 這三種斜線路徑。Claude Code 會把專案目錄編碼成用 `-` 連起來的名字，這種寫法沒被換掉。`git grep -o -h '"[a-z_]*":"<home>/.claude/projects/<編碼後的 scratchpad 路徑>"]*"' HEAD -- docs/measurements/2026-10-29-adhd-style/out` 在 8 份 jsonl 裡各命中一次：`"auto":"<home>/.claude/projects/<編碼後的 scratchpad 路徑>/memory/"`。這串裡有使用者名稱 `danlio`、uid `501` 和 session UUID。第 4 步的 `grep -rl '/Users/\|/private/tmp'` 只認斜線路徑，所以回 0 筆。
   - 失敗情境：這是公開 repo，「原始輸出去識別後存」這句宣稱不成立，驗收步驟卻說它通過了。要修有兩件事：sed 加一條規則，換掉 `$HOME` 和 `$WORK` 的 dash 編碼形式；驗收 grep 加上 `-Users-` 和 `-private-tmp-`。

2. **Important｜`run.sh` 的 `rm -rf "$WORK"`（迴圈內每發一次，結尾再一次）**
   - 問題：`WORK="${1:?…}"` 是使用者傳進來的參數，沒做任何檢查就整個刪掉再重建。
   - 證據：diff 第 609–610 行是 `rm -rf "$WORK"; mkdir -p "$WORK"`。檔頭只寫了「會被清空重建」，沒有任何防護（例如要求目錄不存在或是空的、要求在 `$TMPDIR` 底下）。repo 裡另外兩支量測用的 run.sh（`2026-10-24-s4-inputs`、`s5-inputs`）都沒有 `rm -rf`，所以這支沒有前例可循。
   - 失敗情境：如果把參數誤傳成輸出所在的那個目錄（`run.sh docs/measurements/2026-10-29-adhd-style`），第一發之前 run.sh、check.sh 和已經跑好的 `out/` 就全被刪掉。如果傳的是家目錄底下的真實目錄，裡面的內容會永久消失。

3. **Important｜根 `CLAUDE.md`「新增 Output Style 步驟」1–4，以及 `install-dd-pipeline.sh` 的 `show_help`、`uninstall`、`show_completion`**
   - 問題：這份步驟清單寫來給「之後再加風格」用，卻漏了幾處寫死 ADHD 的地方，而這些地方 CI 都不驗。
   - 證據：
     - `show_help` 印 `"${#DD_OUTPUT_STYLES[@]} 個 Output Style（ADHD：用 /output-style 開關）"`：數量從陣列算，名字是手打的。同一支檔案 `show_completion` 的註解自己就把這種寫法叫做「最糟的組合：印「3 個」只列 2 個」。
     - `uninstall` 印「設為 ADHD 的，請改回 default」。
     - `show_completion` 整段只講 `/output-style ADHD`。
     - 兩份 README 的指令表寫死 `/output-style ADHD`，安裝步驟那句寫死 `adhd.md`。
     - 步驟清單只要求「加陣列 → 跑 --force → 行為驗收」，沒提要改這些地方。「新增 Skill 步驟」的第 2 步則明列了要同批改哪些地方。
   - 失敗情境：照這四步再加一個 `foo.md`，CI 全綠，`--help` 會印「2 個 Output Style（ADHD：…）」，完成訊息和 README 都看不到新風格。

## Not reported

- `create_output_styles` 的源檔缺失時只 `continue`，`show_completion` 照樣叫人去開 ADHD：跟 `create_scripts` 是同一種既有寫法。
- `check.sh` 的 `d2` 用 `${#f}` 判斷「≤ 60 字」，結果隨 locale 變（`LC_ALL=C` 時算位元組）。但 d2 本來就沒有鑑別力，「通過」只靠 d1，不影響結論。
- `run.sh` 的 sed 順序：如果 WORK 是用 `/tmp/…` 傳進來，`/private/tmp/x` 會變成 `/private<work>`。只留下 `/private` 這個前綴，不構成識別資訊。
- `--update` 不部署 output style：兩份 README 和 `--help` 都寫它只更新 skills/agents，宣稱成立。
- 以下 HEAD 敘述我核過，都成立：根 CLAUDE.md 寫的「第五組 `DD_SCRIPTS`」；架構文件和兩份 README 寫的「三個不佔編號的步驟」及順序；「冪等」那段宣稱；「安裝不改任何 outputStyle 設定」。
- bash 3.2 相容、`set -e` 下的 `[ ] && x`、變數緊貼全形字：新增的程式碼裡沒有問題。
- `LICENSE.txt` 的逐節去向：逐項對過，都相符。
- 測試的鑑別力：idempotent 那段的「無備份」會連帶守住 output-styles；`--commands-only` 乾淨 HOME 那則與 uninstall 保留 `mine.md` 那則，都會被對應的變異打紅。

## What I ran

- 讀 diff 檔第 1–910 行與 ③ 裡 install-dd-pipeline.sh、ci.yml、DD_PIPELINE_ARCHITECTURE.md、tests/CLAUDE.md、tests/test-install.sh 的 HEAD 版，還有 ④
- 抽 HEAD 版 install 腳本 grep 函式結構、`COMMANDS_ONLY`、`backup_before_overwrite`、`outputStyle`
- `git grep`：`四組 + DD_SCRIPTS`、`五組`、`兩個不佔編號`、`two unnumbered`、`附加步驟`、`skills / agents / commands / scripts`、`create_scripts`、`第五組`、`output.style` → 沒有過期敘述
- `git grep -c -e danlio -e claude-501 -e -private-tmp HEAD -- …/out` → 8 份檔各 1 處
- `git ls-files 'docs/**/*.sh'`，grep 前例 run.sh 的 `rm -rf` 和 `WORK=` → 沒有
- 對照上游 clone 的 SKILL.md、LICENSE、git log、tags、plugin.json

## 需要外部查證

- `/output-style ADHD` 比對的是 frontmatter 的 `name` 還是檔名？大小寫？
- uninstall 刪掉 `adhd.md` 後，設定仍是 `"outputStyle":"ADHD"` 時 Claude Code 的反應
- 另裝一個 frontmatter 也是 `name: ADHD` 的風格時，兩個同名風格怎麼處理

## 處置

（本份「Not reported」與「What I ran」兩節是主對話存檔時略為縮寫的版本，Findings 為原文）

- A1 去識別漏掉 `-Users-…` 編碼路徑：採納（Important）。原始 stream-json 不再進 repo，`run.sh` 改成只抽 init 的 `output_style` 與 result 的必要欄位；驗收 grep 加 `-Users-`、`-private-tmp-`。含洩漏的 commit 還沒推，已 amend 拿掉原始輸出（94d4da2 → 17a2408）
- A2 `rm -rf "$WORK"` 沒防呆：採納（Important）。`run.sh` 只接受不存在、或有 `.adhd-accept-work` 標記的目錄；實跑傳 repo 內的量測目錄 → 拒跑 exit 1
- A3 新增風格時寫死 ADHD 的地方沒列進步驟：採納（Important）。`show_help`／`uninstall` 的名字改由陣列產生，`show_completion` 改成走訪陣列 + `case` 補說明；根 CLAUDE.md「新增 Output Style 步驟」第 2 步列出要同批手動改的地方
- 需要外部查證三項：見 `S1-judge.md`
