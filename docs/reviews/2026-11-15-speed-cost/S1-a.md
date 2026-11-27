# S1 步驟 4：審查者 A（安裝腳本的邏輯）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數），同時派 code-simplifier 跑步驟 3。下面是給這個審查者的 prompt 全文（路徑已去識別：`<repo>`、`<scratchpad>`）。
diff 檔（3014 行）的組成：①`git diff 750c8db HEAD`（HEAD = 3fe579d）②步驟 3 的改動（並行，派工當下是空的）③`install-dd-pipeline.sh` 與 `tests/test-install.sh` 在 HEAD 的整檔內容 ④已跑過的驗證與預期值 11 條。

````text
你是 code reviewer。唯一的職責：找這段改動的漏洞。每條發現都要附證據（diff 檔的行號加原文，或你實際跑的唯讀指令與輸出）；沒證據的不算。不寫優點。

審查範圍：repo `<repo>` 的 `git diff 750c8db HEAD`（兩個 commit：S1-1 安裝腳本的環境檢查多一行報「自動壓縮視窗」有沒有設，連同測試；S1-2 量測檔、兩份 README、CHANGELOG）。

材料都在這個 diff 檔（3014 行）：
<scratchpad>/s1/review/S1-diff.txt
- 第 1–702 行：整段 diff。第 706–2989 行：`install-dd-pipeline.sh` 與 `tests/test-install.sh` 在 HEAD 的整檔內容（帶行號）。第 2990 行到檔尾：已經跑過的驗證與預期值。
- 用 Read 的 offset／limit 每次 300 行讀：Read 一次讀太多會靜靜截斷、不報錯。第 1–702 行與第 2990 行到檔尾要整段讀完；整檔內容那一部分，讀你的方向需要的區段。
- `install-dd-pipeline.sh` 與 `tests/test-install.sh` 一律讀 diff 檔裡那一份，不要讀工作目錄（另一個 agent 正在同時改工作目錄的這兩支檔）。其他檔照常從 repo 讀。
- 第 4 部分列的驗證已經跑過、結果已確認，不要重跑測試、不要跑安裝腳本、不要跑 CI。「跑過」不代表結果對：你可以質疑某個驗證其實沒驗到它宣稱的東西。
- 只做唯讀的事（Read、grep、git log／show／diff）。不要改檔、不要 commit、不要執行 `./install-dd-pipeline.sh`（它會動到真實的 ~/.claude）。
- 只用手上的資料判斷；需要上網或要跑東西才能確認的，列在「需要外部查證」交回，不要自己猜。
- 專案規則在根目錄與各層的 CLAUDE.md（根目錄那份的「注意事項」有安裝腳本的規矩：jq 與 python3 兩條路徑逐項等價、`set -e` 下回非 0 的指令、不確定就說不確定）。

你的方向：安裝腳本的邏輯。`autocompact_state` 與 `print_autocompact_line`：八種回傳的條件有沒有漏洞或互相矛盾；jq 與 python3 兩條路徑對同一份輸入會不會給不同結論（自己想測試表上沒有的輸入類別）；環境變數那段的 shell 判斷；`set -e` 下會不會中止安裝；bash 3.2 相容；印出的每一句話是不是設計文件 F15 的官方原文撐得住的說法；函式上方註解的每個宣稱對不對。

回報格式（繁體中文，短；不要貼你讀檔的過程）：
- 每條發現：級別（Critical／Important／Smell）｜位置（檔案與 diff 檔行號）｜問題｜證據（原文或指令輸出）｜會造成什麼
- Not reported：你看過、判斷不算問題的（每條一句理由）
- 需要外部查證
- What I ran：你實際跑的指令（沒有就寫沒有）
````

## 發現

審查者交回的報告全文（路徑已去識別，其餘逐字）。

````text
Critical 0 / Important 2 / Smell 1。審查範圍是 `git diff 750c8db HEAD` 裡安裝腳本的邏輯：`autocompact_state`、`print_autocompact_line`，以及 T2 的 acw 案例和 T10。

**[Important] jq 與 python3 對同一份輸入給出不同結論，至少有 6 類輸入表上沒列**
- 位置：diff 檔第 381–392 行（jq 路徑）、第 394–414 行（python3 路徑）。
- 證據：把 diff 檔第 3 部分的 `install-dd-pipeline.sh` 抽成 scratchpad 的 `inst.sh`，用 bash 載入後跑 `autocompact_state`。python3 臂照 T2 的做法把 `command_exists jq` 改成回 false。本機是 jq 1.7.1、Python 3.13.2：
  ```
  {"autoCompactWindow":99999.99999999999999999}           jq=outofrange py=all
  {"autoCompactWindow":1000000.0000000000000001}          jq=outofrange py=all
  {"modelSettings":{"m":{"autoCompactWindow":99999.99999999999999999}}}  jq=none py=permodel
  {"autoCompactWindow":nan}（小寫）                        jq=outofrange py=unparseable
  {"theme":"\xff\xfe","autoCompactWindow":400000}（不合法 UTF-8）  jq=all py=unparseable
  {"x":1後面接5000個0,"autoCompactWindow":400000}         jq=all py=unparseable
  {"x":[[[…3000 層…]]],"autoCompactWindow":400000}        jq=unparseable py=all
  ```
- 三個原因：
  - 前三列：jq 1.7 拿原始的十進位字面值比大小，python 先轉成 float，數值剛好落在邊界時結論不同。
  - 小寫 `nan`：jq 收，python 不收。
  - 不合法 UTF-8：jq 換成替代字元照樣解析，python 報錯。
  - 大整數：Python 3.11 起整數字串上限 4300 位，超過就報 ValueError（我實際觸發過）。
  - 3000 層巢狀：jq 有深度上限。
- 會造成什麼：同一台機器裝不裝 jq，印出來的那一行不同，違反根目錄 CLAUDE.md「jq 與 python3 兩條路徑須逐項等價」。後三類無關的鍵也會觸發，跟 autoCompactWindow 本身無關。這些輸入都不常見，所以列 Important、不列 Critical。不合法 UTF-8 與小寫 `nan` 兩類，`plugin_enabled_state` 和 `mcp_scope` 用同一套寫法，我推測一樣受影響，但沒驗證。

**[Important] `none` 和 `all` 兩句話比手上的證據說得更肯定**
- 位置：diff 檔第 445–447 行（`*)` 分支）、第 436 行（`all`）；呼叫點在第 468 行，只傳 `$CLAUDE_DIR/settings.json`。
- 證據：
  - 函式只讀 `~/.claude/settings.json` 和這個 shell 的環境變數。
  - 印出的卻是「沒設，Claude Code 用它替各模型調的預設視窗」。
  - F15 的原文是「set autoCompactWindow in **a** settings file, such as … ~/.claude/settings.json」，可見別的設定檔也能設。
  - 根目錄 CLAUDE.md 對 `~/.claude.json` 有同型規則：「`project` scope 不在其中，任何以此檔為據的檢查都會低報，文件須註明」。
- 會造成什麼：專案的 `.claude/settings.json`、`settings.local.json` 或 managed settings 設了這個鍵時，安裝輸出仍斷言「沒設、用預設」。反過來，`all` 這句也看不到被更高優先的設定檔蓋掉的情況。這違反「不確定就說不確定」。至少要把句子限定成「`~/.claude/settings.json` 沒設」。

**[Smell] `NaN`／`Infinity` 被定成 `outofrange`，可能應該是 `unparseable`**
- 位置：diff 檔第 603–606 行（T2 的 a-top-nan、a-top-inf、a-pm-nan），結論來自第 438–439 行。
- 證據：註解自己寫了「NaN、Infinity 不是合法的 JSON」。`outofrange` 那句的第二行是「有個別設定的模型以個別值為準」，前提是這份檔案有被採用。
- 會造成什麼：Claude Code 如果用嚴格的 JSON 解析，整份檔案就讀不進來。這時「以個別值為準」是錯的提示。這是推論，需要外部查證，見下方第 1 條。

**Not reported（看過、判斷不算問題的）**
- 環境變數分支：先過濾 `*[!0-9]*|0*`、再要求長度 ≤7 才比大小，所以不會印 shell 錯誤。我實跑 `400000`→env，`0400000`、空白開頭、`1000001`、`99999`、`abc` 都→envodd，`1000000`→env。
- `set -e`：`out=$(…) || out=""`、`&& … || …`，以及 `print_autocompact_line "$(…)"` 這種當參數用的指令替換，都不會中止安裝。
- bash 3.2：`${#var}`、`case [!0-9]`、單一 `local` 多個賦值都沒問題。jq 和 python 程式碼裡沒有單引號，不會提早結束字串。
- 重複鍵：兩邊都取最後一個值（實測 dup 案例兩邊都是 `all`）。`-0`、`4e5`、`-Infinity`、UTF-16 檔，兩邊結論相同。
- python `valid()` 的註解說「範圍先比，所以 NaN／inf 不會走到 int()」「True 過不了範圍」，讀程式碼後成立。
- `env`、`permodel`、`outofrange` 三句，F15 原文都撐得住：環境變數優先、個別值優先、範圍 100000–1000000、沒設時用替模型調的預設。
- `envodd` 直接回傳、不讀設定檔：這是設計表定的做法，句子也寫了「無從判定」。
- `--commands-only` 也會跑步驟 1：`main()` 在任何模式分支之前就呼叫 `check_environment`（抽出來的 `inst.sh` 第 1498 行）。
- 方向外，我順帶看到：兩份 README 寫「/autocompact … switching to a model you have not set puts you back on that model's default」（diff 檔第 79 行）、「換到沒設過的模型就回到那個模型的預設」（第 118 行）。最上層有設時，換過去用的是最上層的值，不是預設。這句和緊接的下一句放在一起讀會互相矛盾。

**需要外部查證**
1. Claude Code 讀 settings.json 用不用嚴格的 JSON.parse。如果是嚴格解析，`NaN`／`Infinity`／`nan` 會讓整份檔案無效，Smell 那條就成立。
2. 最上層的鍵是 `null` 或範圍外（例如 5）時，Claude Code 是只忽略那個鍵，還是整份 settings 驗證失敗。這會影響 `a-top-null` 定成 `none`、`outofrange` 第二行說得對不對。
3. 專案層和 managed 的 settings 檔能不能設 `autoCompactWindow`，以及它們和 `~/.claude/settings.json` 的優先順序。這會影響 Important 第 2 條要怎麼改句子。

**What I ran**
- 讀 diff 檔第 1–702 行與第 2989–3015 行，加上第 3 部分的 helpers、`check_environment`、`plugin_enabled_state` → 已讀。
- `sed -n 65,105p docs/designs/2026-11-15-speed-cost-design.md` → F15、F16 與設計狀態表。
- `awk … S1-diff.txt | sed … > <scratchpad>/s1/rv-logic/inst.sh` → 從 diff 檔抽出 HEAD 版的安裝腳本。
- 13 個 fixture（在 `<scratchpad>/s1/rv-logic/c/`）各用 `bash -c 'export HOME=<scratch>/fh; source ./inst.sh; autocompact_state <檔>'` 跑 jq 與 python3 兩臂 → 7 類結論不同，輸出如上表。
- 7 個環境變數值用 `/bin/bash`（3.2）跑 `autocompact_state /nonexist` → 結果如 Not reported 所列，沒有 shell 錯誤。
- `python3 -c 'json.loads(4401 位整數)'` → `ValueError: Exceeds the limit (4300 digits)`。
- `jq --version` → jq-1.7.1；`python3 --version` → 3.13.2。

沒有跑安裝腳本、測試或 CI，也沒有改 repo 裡的任何檔。
````

## 處置

- **兩條路徑結論不同（Important）→ 採納，修了三類、兩類只記錄**。我自己重跑確認：`99999.99999999999999999`、`1000000.0000000000000001` 在 jq 1.7.1 與 1.8.1 的舊寫法回 `false`、python3 回 `true`；
  不合法的 UTF-8 位元組 jq 照樣解析、python3 報 `UnicodeDecodeError`；5000 位的整數 python 3.13 報錯、jq 照收。
  修法：jq 的 `valid` 先 `. * 1` 換成浮點數再比；python3 讀檔加 `errors="replace"`、有 `sys.set_int_max_str_digits` 就設成 0。
  T2 補四列（`a-top-edge-lo`、`a-top-edge-hi`、`a-badutf8`、`a-bigint`），修正前四列都紅（前兩列紅在 jq 那一臂、後兩列紅在 python3 那一臂），修正後 146 例全綠。
  沒對齊的兩類：小寫的 `nan`（重跑確認 jq 收、python3 不收）、3000 層巢狀（重跑確認 jq 回「Exceeds depth limit」、python3 照收）。
  要對齊得自己重做兩邊解析器的上限，而這兩種檔要刻意造才會有；寫進函式上方的註解與 `tests/CLAUDE.md`。
  報告推測 `plugin_enabled_state`、`mcp_scope` 也受影響：那幾支不在這一段的 diff 裡，沒有改、沒有測，`tests/CLAUDE.md` 寫明這三類只有 `acw` 有列
- **`none` 與 `all` 說得比證據肯定（Important）→ 採納**（與 C 的第 1 條重疊）。`none` 那一行改成「~/.claude/settings.json 與這個 shell 的環境變數都沒有有效的設定（其他設定檔沒查）」，
  「用預設視窗」改成有前提的「都沒設時…」。`all` 那句本來就寫明是「settings.json 最上層已設」，講的是這個檔的內容，沒有改；
  「被別的設定檔蓋掉」的情況靠 README 與 `none` 那行的「其他設定檔不讀」交代
- **`NaN`／`Infinity` 該不該是 `unparseable`（Smell）→ 部分採納**。Claude Code 是不是用嚴格的 JSON 解析沒有查證，狀態維持 `outofrange`；
  但 `outofrange` 的第二行「有個別設定的模型以個別值為準」預設了這份檔會被採用，拿掉了，只留「實際用多少無從判定」
- 順帶提的 README 那句（換模型回到預設）→ 採納，見 C 的第 3 條
- 需要外部查證三條：都沒有查。改法是讓句子不依賴它們（第 1、2 條：拿掉 `outofrange` 的第二行；第 3 條：寫明其他設定檔沒查）
