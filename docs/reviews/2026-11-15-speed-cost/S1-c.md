# S1 步驟 4：審查者 C（文件裡的宣稱）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數），同時派 code-simplifier 跑步驟 3。下面是給這個審查者的 prompt 全文（路徑已去識別：`<repo>`、`<scratchpad>`）。
diff 檔（3014 行）的組成：①`git diff 60239e7 HEAD`（HEAD = ded7c0b）②步驟 3 的改動（並行，派工當下是空的）③`install-dd-pipeline.sh` 與 `tests/test-install.sh` 在 HEAD 的整檔內容 ④已跑過的驗證與預期值 11 條。

````text
你是 code reviewer。唯一的職責：找這段改動的漏洞。每條發現都要附證據（diff 檔的行號加原文，或你實際跑的唯讀指令與輸出）；沒證據的不算。不寫優點。

審查範圍：repo `<repo>` 的 `git diff 60239e7 HEAD`（兩個 commit：S1-1 安裝腳本的環境檢查多一行報「自動壓縮視窗」有沒有設，連同測試；S1-2 量測檔、兩份 README、CHANGELOG）。

材料都在這個 diff 檔（3014 行）：
<scratchpad>/s1/review/S1-diff.txt
- 第 1–702 行：整段 diff。第 706–2989 行：`install-dd-pipeline.sh` 與 `tests/test-install.sh` 在 HEAD 的整檔內容（帶行號）。第 2990 行到檔尾：已經跑過的驗證與預期值。
- 用 Read 的 offset／limit 每次 300 行讀：Read 一次讀太多會靜靜截斷、不報錯。第 1–702 行與第 2990 行到檔尾要整段讀完；整檔內容那一部分，讀你的方向需要的區段。
- `install-dd-pipeline.sh` 與 `tests/test-install.sh` 一律讀 diff 檔裡那一份，不要讀工作目錄（另一個 agent 正在同時改工作目錄的這兩支檔）。其他檔照常從 repo 讀。
- 第 4 部分列的驗證已經跑過、結果已確認，不要重跑測試、不要跑安裝腳本、不要跑 CI。「跑過」不代表結果對：你可以質疑某個驗證其實沒驗到它宣稱的東西。
- 只做唯讀的事（Read、grep、git log／show／diff）。不要改檔、不要 commit、不要執行 `./install-dd-pipeline.sh`（它會動到真實的 ~/.claude）。
- 只用手上的資料判斷；需要上網或要跑東西才能確認的，列在「需要外部查證」交回，不要自己猜。
- 專案規則在根目錄與各層的 CLAUDE.md（根目錄那份的「注意事項」有安裝腳本的規矩：jq 與 python3 兩條路徑逐項等價、`set -e` 下回非 0 的指令、不確定就說不確定）。

你的方向：文件裡的宣稱。兩份 README 新增的小節、前置需求那一行、安裝步驟 1 那句（英文與中文講的是不是同一件事、有沒有哪一句超出量測檔「當天輸出」或設計文件 F15、F16 撐得住的範圍）；`docs/measurements/2026-11-15-main-session-context.md` 的「整理」「限制」每個數字對回它自己的「當天輸出」；腳本做的事跟「方法」節講的一不一樣；CHANGELOG 條目、根目錄 CLAUDE.md 這次改的兩處、設計文件的狀態表，跟程式實際行為對不對得上；README 的錨點連結指不指得到標題。

回報格式（繁體中文，短；不要貼你讀檔的過程）：
- 每條發現：級別（Critical／Important／Smell）｜位置（檔案與 diff 檔行號）｜問題｜證據（原文或指令輸出）｜會造成什麼
- Not reported：你看過、判斷不算問題的（每條一句理由）
- 需要外部查證
- What I ran：你實際跑的指令（沒有就寫沒有）
````

## 發現

審查者交回的報告全文（路徑已去識別，其餘逐字）。

````text
Critical 0 / Important 3 / Smell 4。審的是 git diff 60239e7 HEAD 的文件宣稱，材料用 S1-diff.txt（第 1–702 行、HEAD 腳本 410–477 與 1487–1507 行、第 4 部分）。

**[Important] 1｜install-dd-pipeline.sh `autocompact_state`／`print_autocompact_line` 的 `*)` 分支（diff 檔 377、417、445–447 行）；README.md 55 行；README.zh-TW.md 94 行**
- 問題：腳本只讀 `$CLAUDE_DIR/settings.json` 一個檔，`none` 卻印成確定的「沒設」。README 也寫 "The environment check reports whether one is set"。
- 證據：
  - 呼叫點是 `print_autocompact_line "$(autocompact_state "$CLAUDE_DIR/settings.json")"`（HEAD 471 行）。
  - F15 原文說這個鍵設在 "a settings file, such as … ~/.claude/settings.json"，又說環境變數 "takes precedence over the command, the flag, and the autoCompactWindow setting"。也就是說還有別的 settings 檔，也有 flag。
  - 印出的句子是 `沒設，Claude Code 用它替各模型調的預設視窗`。
- 會造成什麼：視窗設在專案層 `.claude/settings.json` 或 managed settings 時，安裝輸出仍斷言「沒設」。這違反根目錄 CLAUDE.md 那條「不確定就說不確定，不可退化成有把握的斷言」。同一份檔對 `~/.claude.json` 有前例：只涵蓋部分 scope 時要註明會低報。這裡沒有註明。

**[Important] 2｜CHANGELOG.md（diff 檔 16 行）對比腳本 357 行與 T2 `a-pm-5`、`a-pm-true`（diff 檔 612–613 行）**
- 問題：CHANGELOG 寫「值不是 100000–1000000 的整數…時照實說『無從判定』」。實際上個別模型的值無效時，腳本當成那一格沒設，回 `none`，印「沒設」。
- 證據：
  - 註解原文：「個別模型的值不是有效值（"auto"、布林、範圍外）就當那一格沒設」。
  - 測試原文：`t2_case acw a-pm-5 '{"modelSettings":{"m":{"autoCompactWindow":5}}}' … '^none$'`。
- 會造成什麼：
  - CHANGELOG 的描述只對最上層與環境變數成立，對個別模型不成立。
  - `modelSettings.m.autoCompactWindow: 5` 時 Claude Code 怎麼處理，F15 沒寫，安裝輸出卻斷言「沒設」。最上層的同一個值卻是 `outofrange`（無從判定），兩邊不對稱。

**[Important] 3｜README.md 79 行；README.zh-TW.md 118 行；腳本 447 行**
- 問題 a：`/autocompact` 是 v2.1.288 起才「只存給當下的模型」，三處都丟掉了這個版本條件。
  - 證據：F15 原文 "Before v2.1.288, the command saved one window for every model, as the top-level autoCompactWindow"。README、安裝腳本、量測檔 grep `2.1.288` 都是 0 筆。
  - 會造成什麼：舊版 Claude Code 的使用者照文件會以為 `/autocompact` 只影響一個模型，實際上它寫的是最上層，影響每個模型。
- 問題 b："switching to a model you have not set puts you back on that model's default"／「換到沒設過的模型就回到那個模型的預設」少了一個前提：最上層沒有設。
  - 證據：同一段下一句就說最上層的鍵 "applies to every model"。兩句連著讀互相矛盾。

**[Smell] 4｜量測檔「方法」（diff 檔 168–169 行）；README.md 76–77 行**
- 問題：「那台機器當時的 settings.json（用 jq 讀）…`claude-fable-5-2` 那一格沒有這個鍵」沒寫是什麼時候讀的。
- 證據：
  - 同一段寫使用者在 `2026-11-14T16:25:48Z` 對 fable 下了 `/autocompact 400000`。照 F15，這個指令會寫進 `modelSettings`。
  - 量測日是 11-15。如果是 11-15 讀的，fable 那一格應該已經有值。
  - opus 那格「11-13 已有 400000」也同樣沒有讀取時點。
- 會造成什麼：README 的 "The model in use had no auto-compact window saved"、"a model with a 400,000-token window saved compacted 12 times" 都靠這個快照。讀的人照方法重查，會看到矛盾。

**[Smell] 5｜量測檔「整理」（diff 檔 300 行）**
- 問題：「跑 Bash 22.5 分（93 次裡超過 30 秒的 17 次佔 17.0 分）」把兩種算法放在同一句，寫成「佔」。
- 證據：22.5 是相鄰事件間隔的 bucket；17.0 出自另一種算法，那一行的合計是 22.9（diff 檔 291 行）。「限制」節自己寫了兩者差在平行呼叫。
- 會造成什麼：17.0 不是 22.5 的子集，讀起來卻像子集。

**[Smell] 6｜README.md 74 行；README.zh-TW.md 113 行**
- 問題：「One job measured on 2026-11-15」「2026-11-15 量的一件工作」。
- 證據：那件工作發生在 `2026-11-14T14:16:04`→`16:04:35`（diff 檔 274 行），969,715 那次壓縮在 `2026-11-14T13:43:36`。設計文件 102 行建議的寫法是「2026-11-14 在 claude-fable-5-2 量到一次 969,715」，README 沒有寫日期也沒有寫模型名。
- 會造成什麼：日期容易被讀成事件發生日；與設計文件自己規定的寫法不一致。

**[Smell] 7｜README.md 79 行 "reports which of these is set"；README.zh-TW.md 118 行「會報設在哪一層」**
- 問題：說得比腳本做的多。
- 證據：
  - 最上層有效時只回 `all`，不報個別模型有沒有設（diff 檔 351 行「個別模型另外有沒有值都回這個」）。
  - 環境變數有值時直接回 `env`、不讀檔（diff 檔 363–375 行）。
  - README 全文沒提 `CLAUDE_CODE_AUTO_COMPACT_WINDOW`。
- 會造成什麼：讀者以為可以看出每一層的狀態；README 也沒告訴讀者有一個優先於檔案的環境變數。

**Not reported**
- 量測檔「整理」「限制」的每個數字我都對過「當天輸出」，全部對得上：opus 自動壓縮 12 次、366594–385382；fable 969715、371343、manual 779930；請求 124 次、單次迭代 122 次、244546→759029；cache_read 63481446；output 321419、thinking 136430；55.6、21.9、3.2 分；12、1、1。
- 方法節對比腳本也一致：去掉 isSidechain、iterations>1 另列、壓縮與模型看整份檔、用字串比時間並排除帶毫秒的那一秒。
- 「另外做的一次對照」的表與 F16 的數字一致（81,120、80,113、63,356、71,565、448,638）。
- 兩份 README 的前置需求、步驟 1、新小節中英對得上。
- 錨點 `#what-the-main-session-costs`、`#主對話那一塊要花多少` 都對得上標題（README.md 148 行、README.zh-TW.md 151 行）。
- CHANGELOG「`--check` 與 `--commands-only` 也會跑」成立：HEAD 411–414 行與 1498 行在所有模式都呼叫 `check_environment`。
- 設計文件 S1 標 `IN_PROGRESS`、commits 欄 `60239e7..`，符合它自己的規則。
- 根目錄 CLAUDE.md 兩處改動符合腳本。
- session-cost.md 的範圍到 10:30:08，與新量測檔互相引用、不重疊，12 次壓縮也在它自己的輸出裡。
- 設計文件 F4 寫「跑 Bash 22.9 分」，量測檔寫 22.5：這不在本次 diff 內，是既有內容，提一句。

**需要外部查證**
- F16 沒記 Claude Code 版本，量測檔寫「Claude Code 2.1.325」：要對照實驗 jsonl 的 init 訊息才能確認。
- 專案層 `.claude/settings.json` 與 managed settings 裡的 `autoCompactWindow` 會不會生效：要查官方 settings 優先序文件，這會決定 Important 1 的嚴重度。
- 個別模型的值在範圍外時 Claude Code 怎麼處理：F15 沒寫。

**What I ran**
- Read／`sed -n` 讀 S1-diff.txt 的第 1–702 行與 2985–3014 行 → 讀完。
- `grep -n 'F15\|F16'`、`sed -n 20,40p;60,125p docs/designs/2026-11-15-speed-cost-design.md` → 取得 F15、F16、S1 規格。
- `grep -n 'check_environment\|COMMANDS_ONLY…' S1-diff.txt`，再 `sed -n` 讀 HEAD 410–477、1487–1507 行 → 確認呼叫點只傳 `$CLAUDE_DIR/settings.json`，而且所有模式都會跑。
- `grep -n '^#' README.md | grep -i 'main session'`、`grep '主對話' README.zh-TW.md` → 148 行、151 行標題存在。
- `grep -n '壓縮\|compact\|10:30:08' docs/measurements/2026-11-14-session-cost.md` → 範圍到 10:30:08，「自動壓縮 12 次」。
- `grep -rn '2.1.288' README.md README.zh-TW.md install-dd-pipeline.sh docs/measurements/2026-11-15-main-session-context.md` → 0 筆。這條誤讀了工作目錄的 install-dd-pipeline.sh，違反「只讀 diff 檔那份」的指示；diff 檔裡的腳本內容也沒有這個字串。
````

## 處置

- **1 `none` 印成確定的「沒設」（Important）→ 採納**，與 A 的第 2 條重疊，改法見那裡；兩份 README 的前置需求與小節都改成「讀 `~/.claude/settings.json` 與環境變數、其他設定檔不讀」
- **2 CHANGELOG 講的比程式做的多（Important）→ 採納**。CHANGELOG 改成「最上層的值或環境變數不是…時照實說無從判定；個別模型的值不是有效值時，那一格當成沒有有效設定」。
  個別模型範圍外時印的句子也從「沒設」變成「沒有有效的設定」，不再斷言它沒設
- **3 版本條件與前提（Important）→ 採納**。兩份 README 與安裝輸出都補上「v2.1.288 起」；「換到沒設過的模型就回到預設」補上前提「最上層沒設的時候」
- **4 設定檔是什麼時候讀的（Smell）→ 採納**。從 transcript 查到是 `2026-11-14T16:20:44Z`（那件工作做完之後、`/autocompact` 之前），寫進「方法」；
  「限制」補一條：`claude-opus-5-5` 那 12 次壓縮發生在讀之前，當時它的視窗值沒有另外的紀錄。README 兩句改成「那次讀到的」
- **5 兩種算法寫在同一句（Smell）→ 採納**，拆成兩句
- **6 日期（Smell）→ 採納**。README 改成「2026-11-14（UTC）的一件工作，事後從 session 紀錄量的」，並寫出模型名、註明 969,715 只是一個模型的一次紀錄
- **7 「報設在哪一層」說得比做的多（Smell）→ 採納**。改成「報它在那裡看到什麼」，並寫出環境變數優先於設定檔
- Not reported 最後一條（設計文件 F4 寫 22.9 分）→ 屬實，F4 那句標的算法是相鄰事件間隔，該是 22.5，已改
- 需要外部查證：實驗的版本 → 兩臂 jsonl 的 init 訊息 `claude_code_version` 都是 2.1.325，量測檔補上出處；另外兩條沒有查，改法見 A
