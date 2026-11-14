# 速度與費用：安裝檢查提醒自動壓縮視窗、審查者思考強度實驗

使用者說「請你改善速度與費用」。量測後找到兩件 repo 這邊能做的事，他在選單選了「兩個都做」。兩段（S1 安裝檢查與文件、S2 實驗）：沒有 task 工具，照全域 §4.4 用進度表記進度。

## 來源

使用者的話（逐字，依序，2026-11-15）：

- 「請你改善速度與費用」
- （我量測後請他打 `/autocompact 400000`，他打了）「好了」
- 「請你改善速度」
- （我量測後建議 `/effort high`，他打了）「但我是想要優化和改善 你怎一直叫我調整 effort?」
- 我用選單問「repo 這邊我能動手做的有下面幾種，要做哪一個？」，選項：①安裝檢查＋README（讓 --check 發現「沒設自動壓縮視窗」就提醒，README 補上量到的時間與費用分佈。約 1 小時，照流程會派 3 個審查者）②實驗把審查者調快（等審查者佔 21% 的時間。跑對照實驗看調低審查者思考強度會快多少、少抓多少錯。要花約 20–40 美元；之前的實驗顯示便宜的審查者抓得比較少）③兩個都做（先做安裝檢查與 README，再跑審查者實驗，依結果決定要不要改規則）④都不做。**使用者選「兩個都做」**（使用者決定）

## 假設

- A1 使用者 2026-11-15 在選單選了「兩個都做」：先做安裝檢查與 README，再跑審查者實驗、依結果決定要不要改規則；實驗費用他看到的說法是「約 20–40 美元」。
- A2 提醒放在步驟 1（`check_environment`）而不是新開一個編號步驟：安裝腳本的「N/7」步數有 CI 數字檢查，放進既有步驟不動步數。
- A3 `none` 也印提醒（黃色、標「可選」），不分使用者用的是不是 100 萬視窗的模型：安裝腳本不知道他用哪個模型。
- A4 只認「執行安裝腳本當下的環境變數」，不認 settings.json 的 `env` 區塊裡的同名鍵：官方文件沒說那樣設對主對話有沒有效。
- A5 S2 不改任何規則檔；達到判準時怎麼改另外問。
- A6 README 只寫量到的數字與設定方法，不寫金額與百分比（價格沒查證）。
- A7 計畫審查（`plan-review`）三輪：第 1 輪不通過（3 條重大）、第 2 輪不通過（2 條重大）、第 3 輪通過。紀錄在本檔最後一節
- A8 測試清單由使用者在 2026-11-15 選定「照這份清單加」
- A9 S2 第一發跑完後估計總額超過 30 美元時，先停下問使用者（plan-review 第 3 輪採納）

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | 安裝檢查提醒自動壓縮視窗＋文件 | IN_PROGRESS | — | 沙盒 HOME 跑 `./install-dd-pipeline.sh --check`，設定檔是「最上層有設／最上層的值在範圍外／只設在個別模型／都沒設／壞掉」與環境變數是 400000、是 5 時各印各的那一行；`tests/test-install.sh` 在 macOS（`/bin/bash`，3.2）與 ubuntu:24.04 容器都 rc=0；本機照 ci.yml 逐 step 全過 | 60239e7.. |
| S2 | 審查者思考強度實驗（medium 對 low） | TODO | S1 | 量測文件有兩部分（計畫審查的 haiku 審查者、步驟 4 的 opus 審查者）兩臂的耗時、token、命中表，每個審查者實際跑的強度有紀錄佐證，並照跑之前寫死的判準各寫出「建議改／不建議改／分不出／沒跑完」其中一個；`python3 -I stats.py` 能從存下的 stats 重算出表 | |

- 狀態只有 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`；同一時間最多一段 `IN_PROGRESS`
- 下一段：由上往下第一個 `TODO`，而且它依賴的段落都已 `DONE`。有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段
- 開工：`~/.claude/scripts/check-claude-md.sh --start-segment` 記起點；這段標 `IN_PROGRESS`，commits 欄先填 `<起點>..`（短 SHA；起點是空樹時填它印出的完整 SHA；回頭做 `BLOCKED` 過的段落時，欄裡原本的起點保留不改）；該段有「開工前提」就先查完，結果寫進「段落與小任務」該段底下。這些改動跟第一個小任務的 commit 一起送
- 每個小任務：照「段落與小任務」列的做，實作、驗證、commit，commit 訊息第一行結尾帶編號（例如 `（S2-1）`）。可用 `SKIP_DOC_CHECK=1` 先跳過 CLAUDE.md 檢查，gate 會記帳。測試照文件裡的測試清單加；想加清單以外的測試，先問使用者
- 小任務 commit 了不等於段落完成。小任務全部 commit 完，而且 SKIP 欠下的 CLAUDE.md 都補上了，才對整段跑步驟 3–8，範圍從表上這段的起點算。最後一個小任務用正常 commit；補 SKIP 改過的目錄的 CLAUDE.md 時，用 `git diff <起點> -- <目錄>` 看整段改了什麼，不要只看這次 staged 的（gate 只查 CLAUDE.md 有沒有一起送，不查寫了什麼）。步驟 6、7、8 的 commit 訊息第一行結尾帶段落編號（例如 `（S2）`）
- 標 `DONE`：步驟 3–8 全部跑完才標；commits 欄補上終點（標 `DONE` 之前最後一個 commit 的短 SHA，所以標 `DONE` 的 commit 自己不在範圍內），跟步驟 7、8 的 commit 一起送，7、8 都沒改檔就單獨開一個 docs commit。標到表上每段都 `DONE` 的那個 commit，刪掉根目錄 CLAUDE.md 的指路那段
- 接手：`IN_PROGRESS` 那段就是目前這段。拿「段落與小任務」的清單對 `git log --oneline <表上這段的起點>..HEAD` 裡結尾帶 `（S2-` 的 commit（不加範圍會對到別份文件的同編號 commit）。
  **前綴是「這一段自己的 ID 加一個 `-`」**，不是固定字串：插隊進來的 `S2.5` 要找的是 `（S2.5-`，
  拿 `（S2-` 去比對不到它，拿 `（S2` 又會把 S2.5 的 commit 誤算成 S2 的，還沒 commit 的小任務先做完。小任務都做完了，再看同一範圍裡有沒有帶 `（S2）` 的 commit：有，代表步驟 6 之後的步驟做到一半；沒有就從步驟 3 開始
- `BLOCKED` 用在這段要先停：外部卡住（等使用者決定、環境壞了），或使用者要先做別的事（別段、臨時修 bug）。狀態格寫 `BLOCKED` 和原因，外部卡住時停下來問使用者。先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md（不然 `--start-segment` 會拒絕）；回頭做這段時，範圍一樣從表上這段的起點算。依賴還沒完成的段落維持 `TODO`
- 做到一半冒出新工作：先問使用者，同意才加一列 `TODO` 排進該在的位置；ID 不重編，插在中間用 `S2.5`。
  **同一批要在「段落與小任務」補上這一段的小任務**（名稱、要動的檔案、驗證方式、commit 訊息）——
  只加表上那一列的話，接手的 session 照上面「接手」那條去對 commit，清單本來就是空的，
  它會判定「小任務都做完了」而直接跳到步驟 3，整段程式碼從頭到尾沒人寫。
  沒有小任務條目的段落不得標 `IN_PROGRESS`
- 每列一行，細節寫進 commit 訊息

本 repo 的 hook 跑 repo 這份 gate：上面的 `~/.claude/scripts/check-claude-md.sh` 在這裡換成 `scripts/check-claude-md.sh`（根目錄 CLAUDE.md「開發本 repo」）。審查報告放 `docs/reviews/2026-11-15-speed-cost/`。

## 段落與小任務

### 開工前查到的事實（2026-11-15，repo 在 HEAD 089b10d，本機 macOS，Claude Code 2.1.325）

- F1 使用者的 `~/.claude/settings.json`（用 jq 讀）：最上層沒有 `autoCompactWindow`；`modelSettings` 裡 `claude-opus-5-5`、`claude-fable-5-1`、`claude-opus-4-8` 各有 `autoCompactWindow: 400000`；`claude-fable-5-2` 原本只有 `effortLevel`，使用者打 `/autocompact 400000` 之後多了 `autoCompactWindow: 400000`（指令回覆「Auto-compact window for Fable 5.2 set to 400k tokens」）
- F2 同一個 session 的紀錄檔：模型在 `2026-11-14T10:35:55Z` 從 `claude-opus-5-5` 換成 `claude-fable-5-2`。`compact_boundary` 紀錄：換之前 12 次 `auto`，`preTokens` 366,594–385,382；換之後一次 `auto` 是 969,715
- F3 量的那件工作（`2026-11-14T14:16:04Z`→`16:04:35Z`，安裝腳本補強兩段）：主對話 124 次請求；每次請求的 input+cache_read+cache_creation 從 244,546 長到約 76 萬；cache_read 合計 63,481,446；output 合計 321,419，其中 `output_tokens_details.thinking_tokens` 合計 136,430。有兩次請求 `usage.iterations` 長度是 3（叫 advisor），數字是 601,180 與 1,498,565，不是 context 大小
- F4 同一段時間的時間分配（相鄰事件間隔，合計 104.0 分）：等模型 55.6 分、跑 Bash 22.5 分、等 agent 交回 21.9 分（其中兩次各 478 秒與 458 秒，是計畫審查的兩輪）、AskUserQuestion 3.2 分
- F5 那段時間開始的 subagent 紀錄檔 17 份，每份紀錄的 `effort` 欄位都是 `"medium"`（opus 9 份、haiku 8 份）。同一個 session 更早、主對話還是 opus-5-5 時，有 14 份 opus 的 subagent 是 `"xhigh"`
- F6 那兩輪計畫審查：裁決者（opus）整發 499 秒與 474 秒；它派的 haiku 審查者各自 138、164、140、306 秒（第 1 輪 4 個）與 230、198、345 秒（第 2 輪 3 個）；haiku 審查者的輸出 22,784–66,995 token，其中思考 16,577–57,381。步驟 4 的 opus 審查者 6 個：184–281 秒，輸出 16,147–25,517、思考 9,225–18,167
- F7 `request 等待秒數` 對 context 大小：fable-5-2、單次迭代、非重建快取的 353 次請求，每秒輸出 token 在 context 0–25 萬是 96、70–100 萬是 98；輸出少於 400 token 的請求等待中位數 1.9–3.7 秒。也就是 context 大小沒有讓請求明顯變慢
- F8 本機照 `.github/workflows/ci.yml` 逐 step 跑：20 個 step 全 rc=0，合計 62 秒；`tests/test-install.sh` 39 秒（T2 那組約 35 秒）
- F9 這版 claude 執行檔裡找得到的字串：`/autocompact` 指令（`argumentHint:"[auto|<tokens>]"`）、`CLAUDE_CODE_AUTO_COMPACT_WINDOW`、設定鍵 `autoCompactWindow`；agent 定義的欄位說明有 `effort`（"Thinking effort: `low`, `medium`, `high`, `max`, or an integer"）。主對話的 Agent 工具 schema 有 `effort` 參數（enum 五個值：low、medium、high、xhigh、max）；subagent 紀錄檔每一筆有頂層的 `effort` 欄位
- F10 `install-dd-pipeline.sh` 現況：`check_environment` 依序檢查 Claude Code CLI、Node.js、Git、Bash、ffmpeg（ffmpeg 是可選、最後一行用 `└──`），有任何必要工具缺少才 `exit 1`；`main()` 先跑 `check_environment` 再跑 `validate_skill_hooks`，`--check` 接著跑 `check_builtin_skills`、`check_builtin_agents`、`check_mcp`、`check_plugins`。`plugin_enabled_state` 是讀 `$CLAUDE_DIR/settings.json` 的既有函式：jq 用 `-r -s` 並在「不是剛好一個頂層物件」時 `error(...)`，python3 用 `encoding="utf-8-sig"`、非 dict `sys.exit(1)`，兩者皆缺時 `grep` 鍵名回 `unknown`／`none`，空輸出回 `unparseable`
- F11 `tests/test-install.sh`：`TEST_ONLY` 的合法值寫在一個 `case`（`""|T2|T3|T4|T5|T6|T7|T8|T9`），其他值 exit 2；T2 的 `t2_case <呼叫點> <名稱> <settings 內容> <installed 內容> <claude.json 內容> <必須出現的 regex> <不可出現的 regex>` 每個案例 jq、python3 兩臂各開一個子行程跑 `drive.sh`；T4 是跑真的 `--check` 看 MCP 那一行
- F12 兩份 README 現況：「前置需求」有一行可選的 ffmpeg；`### What the review step costs`／對應的中文小節講步驟 4 的兩組量測，沒有講主對話。`grep -n -i 'ffmpeg' DD_PIPELINE_ARCHITECTURE.md` 0 筆
- F13 既有的審查者實驗素材：`docs/measurements/2026-10-24-s5-inputs/`（`prepare.py` 用 `git archive` 做兩個 commit 的快照、產 diff 檔與 prompt；`RANGES = {"G2": ("639bde7","b66d8ae"), "G3": ("08b2576","8514fb2"), …}`；`run.sh` 用 `claude -p … --model opus --output-format stream-json --verbose --permission-mode dontAsk --allowedTools "Agent Read Glob Grep Bash" --max-budget-usd 20`；`direct.txt` 是父 session 自己查證的說明）。那份目錄的 CLAUDE.md 寫明它是凍結的，要改實驗就另開新目錄。2026-10-24 的費用：S5 的 8 發合計約 36.6 美元（父 session 是 opus）、B 組關掉 advisor 的 4 發合計 10.05 美元（父 opus＋haiku 審查者）
- F14 scratchpad 裡還在的素材：`imp/judge-r1.txt`（30,206 bytes，2026-11-14 第 1 輪裁決者實際拿到的 prompt）、`imp/judge-report-r1.txt`（10,143 bytes，那一輪的裁決報告）
- F15 官方文件原文（2026-11-15 由 web-fetch subagent 從 code.claude.com/docs 逐字抓回，它註明是原文不是摘要；我沒有自己開瀏覽器看）：
  - `model-config.md`「Set the auto-compact window」：`**For every model**: set autoCompactWindow in a settings file, such as "autoCompactWindow": 200000 in ~/.claude/settings.json. A window you saved for a model with /autocompact takes precedence over this key in the same file for that model.`
  - 同一節：`run /autocompact with a value, like /autocompact 500k. Claude Code saves it to your user settings under the current model in modelSettings and applies it to the current session.`；`Before v2.1.288, the command saved one window for every model, as the top-level autoCompactWindow.`
  - 同一節：`set CLAUDE_CODE_AUTO_COMPACT_WINDOW to a token count such as 200000. Unless Claude Code ignores the value, the variable takes precedence over the command, the flag, and the autoCompactWindow setting.`；`A warning that quotes your CLAUDE_CODE_AUTO_COMPACT_WINDOW value means the value falls outside 100,000 to 1,000,000 or isn't a token count.`（環境變數超出範圍時怎麼處理有寫；設定鍵超出範圍時怎麼處理沒有寫）
  - `settings-reference.md` 的 `autoCompactWindow`：`Type: number of tokens, from 100000 to 1000000. Claude Code caps the value at your model's context window`；`Default: unset, so Claude Code picks a window tuned for your model`
  - `settings-reference.md` 的 `modelSettings`：`autoCompactWindow: a number of tokens from 100000 to 1000000, or "auto" for the window tuned for the model. /autocompact saves here. For that model, the value takes precedence over a top-level autoCompactWindow in the same settings file. Requires Claude Code v2.1.288 or later`
  - 「原生 100 萬視窗的模型預設約 967K 壓縮」那句只有先前 claude-code-guide subagent 的摘要，這次沒有逐字抓到；我自己看到的是 F2 的 969,715（一次）
  - settings.json 的 `env` 區塊裡放這個變數有沒有效：文件沒說
- F16 實測最上層的鍵有沒有作用（2026-11-15，各一發，`claude -p --model haiku`、只放行 Read、依序讀十個各約 7.9 萬 bytes 的文字檔；使用者設定的 `modelSettings` 沒有 haiku 那一格；環境變數 `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 沒設）：
  - 有設那一臂（`--settings '{"autoCompactWindow":100000,"advisorModel":""}'`）：stream-json 出現 3 筆 `compact_boundary`、`trigger: auto`，`pre_tokens` 是 81,120、80,113、63,356；每次請求的 context 沒有超過 71,565
  - 沒設那一臂（`--settings '{"advisorModel":""}'`）：0 筆 `compact_boundary`，context 一路長到 448,638、十個檔都讀完
  - 限制：各 n=1；鍵是用 `--settings` 給的，不是寫在 `~/.claude/settings.json`；量的是 haiku

### S1 安裝檢查提醒自動壓縮視窗＋文件

做什麼：`check_environment`（安裝的步驟 1，`--check` 與 `--commands-only` 也會跑）在 ffmpeg 那行之後多印一行，講「自動壓縮視窗」的設定狀態。只偵測、只提示，不改任何設定檔，不影響 exit code。
ffmpeg 現在是樹的最後一行（有裝、沒裝兩個分支都印 `└──`）：兩個分支都改成 `├──`，沒裝時的續行縮排改成 `│   `，新的這一行用 `└──`（續行縮排四個空白）。

新函式 `autocompact_state <settings.json 路徑>`，印出下面其中一個字：

| 回傳 | 條件（由上往下，先符合的先回） | 印出的那一行（摘要） |
|---|---|---|
| `env` | 環境變數 `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 非空，而且是 100000–1000000 之間的純數字（不讀檔） | ✅ 已由環境變數設定 |
| `envodd` | 那個環境變數非空，但不是上面那種值（例如 `5`、`200k`、`abc`） | ⚠ 環境變數的值不是 100000–1000000 的純數字，Claude Code 會不會採用無從判定 |
| `unparseable` | 設定檔壞掉、空檔、頂層不是剛好一個物件 | ⚠ settings.json 無法解析，無從判定 |
| `all` | 最上層 `autoCompactWindow` 是有效值（個別模型另外有沒有值都回這個） | ✅ 最上層已設；有個別設定的模型以個別值為準 |
| `outofrange` | 最上層有 `autoCompactWindow` 這個鍵、值不是 `null`、也不是有效值（範圍外的數字、非整數、字串、布林…；個別模型另外有沒有值都回這個） | ⚠ 最上層的值不是 100000–1000000 之間的整數，實際用多少無從判定；有個別設定的模型以個別值為準 |
| `permodel` | 最上層沒有這個鍵（或值是 `null`），但 `modelSettings.<模型>.autoCompactWindow` 至少一個是有效值 | ⚠ 只設在個別模型，沒設過的模型不適用；在 settings.json 最上層加 `"autoCompactWindow"`，沒有個別設定的模型也會套用 |
| `none` | 檔案不存在，或是物件但兩處都沒有有效值 | ⚠（可選）沒設，Claude Code 用它替各模型調的預設視窗；想提早壓縮：`/autocompact <token 數>`（只存給當下的模型）或在 settings.json 最上層加 `"autoCompactWindow"`（每個模型） |
| `unknown` | 沒有 jq 也沒有 python3，而檔案裡有 `"autoCompactWindow"` 字樣（沒有字樣回 `none`） | ⚠ 缺 jq 與 python3，疑似有設但無從判定 |

印出的句子只寫事實 F15 的官方原文撐得住的說法（最上層對每個模型、`/autocompact` 存給當下的模型、個別值優先、範圍 100000–1000000、沒設時用替模型調的預設）。「幾萬才壓縮」這類數字不進安裝輸出；量測檔與 README 要提就寫成有出處的單次紀錄（「2026-11-14 在 claude-fable-5-2 量到一次 969,715 才自動壓縮」），不推到別的模型。最上層與個別模型的值不同時實際用哪個，沒有實測，句子照官方原文寫。
環境變數那兩種狀態只用 shell 判斷，不經 jq／python3：先用 `case` 要求整個值是「1–9 開頭的一串數字」（開頭是 0 的值不拿去做算術比較，免得被當八進位而印出 shell 錯誤），再用 `[ -ge ]`／`[ -le ]` 比範圍；其餘一律 `envodd`。

jq 與 python3 兩條路徑照 `plugin_enabled_state` 的寫法（jq 用 `-s` 並要求剛好一個頂層物件、python 用 `utf-8-sig`、非 dict 回失敗），型別護欄對齊，兩條路徑用同一條規則：「有效值」= 值是整數的數字（`400000.0` 算、`400000.5` 不算）、在 100000 到 1000000 之間（含兩端）、不是布林（python 的 `True` 是 int，要另外排除）；最上層的鍵存在、不是 `null`、又不是有效值，一律是 `outofrange`（含字串與布林）；個別模型的值不是有效值（字串 `"auto"`、布林、範圍外的數字）就當那一格沒設；`modelSettings` 不是物件、或某個模型的值不是物件時略過那一格、不報錯。

小任務：

- **S1-1 加 `autocompact_state` 與步驟 1 的那一行，連同測試**。檔案：`install-dd-pipeline.sh`、`tests/test-install.sh`、`tests/CLAUDE.md`、根目錄 `CLAUDE.md`（「環境檢查」那段與「改這幾支…先跑 T2」那串函式名加上它）。
  驗證（用測試）：先加測試、看它紅在斷言上（函式還不存在時先放一個固定回 `none` 的空殼，讓它跑到斷言），再實作轉綠。
  T2 對照表加一個呼叫點 `acw`（`drive.sh` 加這個分支，兩臂各跑真的函式、比結論）；每個案例照既有 T2 的寫法帶「必須出現」的 regex（例如 `^permodel$`），所以空殼函式那一步就會紅在斷言上，不是只比兩臂一致。
  「jq 與 python3 都沒有」的退化路徑不塞進 `t2_case`（它強制兩臂各走 jq、python3）：在 T10 裡照 T9 `nojson.sh` 的遮法另寫一個小驅動，直接呼叫 `autocompact_state`。新的一組 T10 跑真的 `--check` 看印出的那一行。
  `drive.sh` 與 T10 在「不是測環境變數」的案例一律先 `unset CLAUDE_CODE_AUTO_COMPACT_WINDOW`（開發者的 shell 裡設著它時，其他案例會全部變成 `env`）；測環境變數的兩格用 `CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000 HOME=<沙盒> ./install-dd-pipeline.sh --check`（✅）與 `=5`（⚠）。
  T10 每一格斷言的是那一行裡該狀態獨有的一段字（不是只看有沒有印出一行）。
  寫死組別範圍或輸入類別的地方一起改（下面四處，另加 `tests/test-install.sh` 檔頭「2026-11-14 補上 T1–T9」那句、`tests/CLAUDE.md`「T2 只守它列的那幾類輸入」那串清單補上這次的新類別）：`tests/test-install.sh` 的 `TEST_ONLY` 合法值 `case` 與它的錯誤訊息、同檔「以下各組（T1–T9）在 2026-11-14 補上」那句（改成 T1–T9 在 2026-11-14、T10 在 2026-11-15）、`tests/CLAUDE.md` 講 `TEST_ONLY` 的那句、`tests/CLAUDE.md` 表格裡 `test-install.sh` 那一列（補上 T10 的描述，T2 列的函式清單加 `autocompact_state`）。
  commit：`feat: 安裝的環境檢查提醒自動壓縮視窗有沒有設（S1-1）`
- **S1-2 文件：量測檔、兩份 README、CHANGELOG、架構文件**。檔案：新檔 `docs/measurements/2026-11-15-main-session-context.md`（方法、腳本、當天輸出、限制；寫明時間窗，並跟 `2026-11-14-session-cost.md` 互相引用 —— 那份量的是同一個 session 較早的一段，12 次壓縮的 36.7–38.5 萬出自那裡；腳本照 `2026-11-14-session-cost.md` 的做法放在文件裡，不另開目錄）、`README.md`、`README.zh-TW.md`（「前置需求」的可選項加一行；「審查那一步要花多少／What the review step costs」之後加一小節講主對話這一塊）、`CHANGELOG.md` 的 `## 未發布`；兩份 README 安裝步驟清單的步驟 1 那句後面補一句（那一塊 CI 不驗、要手動同步），寫明它是提醒、不會中止安裝：中文「另外提醒自動壓縮視窗有沒有設（可選，只提示、不中止）」，英文同義。`DD_PIPELINE_ARCHITECTURE.md` 不改（它只寫「環境檢查」，沒有列檢查項）。
  驗證（不寫測試，理由：純文件）：新寫的每一句對回量測輸出或程式碼做一張逐句對照表；量測檔的腳本照文件寫的指令重跑一次、數字相同；量測檔與 README 新增的內容 `grep -nE '/Users/|-Users-|-private-tmp-'` 加帳號字樣要 0 筆；本機 CI 逐 step 全過（含兩份 README 的一致性檢查）。
  講設定怎麼運作的句子只寫事實 F15、F16 核過的；核不到的不寫（S1-1 的安裝輸出同一條，見上面狀態表下方）。
  commit：`docs: 補上主對話 context 的量測與自動壓縮視窗的說明（S1-2）`

整段的驗收另外加一條：macOS 上用 `/bin/bash tests/test-install.sh`（bash 3.2）跑一次 rc=0（本機照 ci.yml 逐 step 跑只等於 ubuntu 那個 job）。

開工前已查完（plan-review 第 1 輪列的外部查證，2026-11-15 做完，細節在事實 F15、F16）：官方文件原文逐字抓回；實測一次「只給最上層的鍵、該模型沒有個別設定」確實會提早自動壓縮。

步驟 3、4 的結果（2026-11-15；報告在 `docs/reviews/2026-11-15-speed-cost/S1-a.md`、`S1-b.md`、`S1-c.md`、`S1-judge.md`）：
- 步驟 3 只動了 `tests/test-install.sh` 的寫法（T10 三處），安裝腳本沒改
- 步驟 4 派 3 個審查者，Critical 0、Important 6、Smell 6，沒有駁回的。改了的：jq 與 python3 對三類輸入結論不同（字面值比浮點數精確、不合法的 UTF-8 位元組、幾千位的整數）；
  「都沒設」那一行改成寫明只查了哪裡；`outofrange` 拿掉沒查證過的第二行；README、CHANGELOG、量測檔的幾句（版本條件 v2.1.288、設定檔的讀取時點、日期、兩種算法分開寫）
- **等使用者決定**：S1-1 加了清單以外的測試而沒有先問（違反進度表下方那條規則）。多出來的是 T2 的 `a-top-min`、`a-top-max`、`a-top-nan`、`a-top-inf`、`a-pm-nan`、`a-top-null-pm`、`a-pm-mixed`；
  T10 的「沒有 settings.json」「環境變數是一長串數字」；`nojson.sh` 的 n3 與 `line` 模式；以及審查修正補的 `a-top-edge-lo`、`a-top-edge-hi`、`a-badutf8`、`a-bigint`。
  先留著；使用者選不留就另開一個 commit 拿掉
- 沒查的外部事實（句子已改成不依賴它們）：Claude Code 是不是用嚴格的 JSON 解析 settings.json；最上層的值在範圍外時整份設定會不會失效；專案層與 managed 的設定檔能不能設這個鍵

README 要寫的內容（兩份同義）：2026-11-15 量的一件兩段工作（一個 session、n=1）裡，主對話 124 次請求、每次帶的 context 從 24.5 萬長到 76 萬 token；那個模型沒設自動壓縮視窗；設了 40 萬的那個模型在同一個 session 稍早是 36.7–38.5 萬就壓縮。不寫金額、不寫省幾成。指到量測檔。

### S2 審查者思考強度實驗（medium 對 low）

目的：等 agent 交回佔那件工作 104 分鐘裡的 21.9 分（事實 F4：其中兩輪計畫審查是 478＋458 秒，約 15.6 分；其餘約 6.3 分，主要是步驟 4）。審查者目前以 medium 跑、輸出大半是思考。量「改成 low」會快多少、少抓多少。
這一段只量、不改規則：結果達到下面的判準也只寫「建議改」，要不要改 `skills/plan-review/SKILL.md` 或 `skills/dd-loop/SKILL.md` 另外問使用者、另開一列。

開工前提（先查完、結果寫進設計文件）：
1. Agent 工具的 `effort` 參數在 `claude -p` 裡有沒有作用，三發便宜的都要看到 subagent 紀錄檔的 `effort` 欄位是 `low`：①haiku 父 session 派一個 haiku 的 general-purpose ②第二層：haiku 父 session 派一個 general-purpose（haiku），由它再派一個 haiku（實驗的甲部分是裁決者派審查者，在第二層）③有定義檔的 agent：haiku 父 session 派 `code-reviewer`（定義檔寫 `model: opus`）做一件一句話的小事。任何一發沒作用就停下回報，不往下做。
2. 兩臂都明寫強度（`medium`／`low`），不靠預設值（使用者 2026-11-15 剛把預設改成 high，subagent 的預設會不會跟著變沒查）。
3. 第一發跑完讀 `result.total_cost_usd`，照它重估總額；估計總額超過 30 美元時先停下回報，由使用者決定要不要照跑（他看到的說法是約 20–40 美元），不直接跑到截斷；這個值取自最後一筆 result、會偏低（`docs/measurements/2026-10-23-reviewer-real-sessions.md` 記過），所以累計到 30 美元就不再開新的一發。
4. 洩題（比內容，不 grep 關鍵字）：甲部分的正確答案來自 2026-11-14，那條重大本來就是靠當時的規則推出來的，規則裡有那個機制不算洩題；要查的是「現在載入的規則比當時多了什麼」。拿受測 session 會載入的每一份部署檔，對快照 `b1935bb` 裡的對應檔做 diff：`~/.claude/CLAUDE.md` 對 `templates/global/CLAUDE.md`、`~/.claude/skills/plan-review/SKILL.md` 對 `skills/plan-review/SKILL.md`、`~/.claude/skills/dd-loop/SKILL.md` 對 `skills/dd-loop/SKILL.md`。diff 是空的就在量測文件寫「無污染」，那條重大照常計分。只有「部署版有、快照沒有，而且講到那條重大的機制」的段落才算受污染；唯一的計分項真的受污染時，甲不開跑，那一部分寫「沒跑完，不下結論」。乙沿用 2026-10-24 已經判過的（只算 K1、K4、K5）。
5. 快照裡各層的 CLAUDE.md 保留不刪（真實流程的審查者會讀專案規則；根目錄 CLAUDE.md 那條「刪掉 fixture 子目錄的 CLAUDE.md」講的是不想讓受測 session 讀到的實驗說明檔，這裡沒有那種檔）。實驗自己的說明檔放在快照之外。

甲部分（計畫審查，haiku 審查者）：
- 素材：2026-11-14 那份計畫的第 1 輪裁決者 prompt（scratchpad 裡的 `imp/judge-r1.txt`，當時實際送出的那份）＋ repo 在 `b1935bb` 的快照（`git archive` 到拋棄式目錄再 `git init`，prompt 裡的專案根目錄換成快照路徑）。
- 正確答案：當時第 1 輪裁決報告採納的那幾條（1 條重大、其餘小事），跑之前逐條抄進量測文件。命中判準照 `docs/measurements/2026-10-23-reviewer-real-sessions.md`「命中（判準跑之前寫死…）」那一節的寫法：同一個位置、同一個機制才算，級別不論。計分只算那 1 條重大；小事逐條列出命中與否，只當參考、不進判準。
- 兩臂：裁決者照舊（general-purpose、opus、明寫 medium），只差它派審查者時帶 `effort: "medium"` 或 `"low"`（改裁決者 prompt 裡派審查者那一句）。每臂 2 發，共 4 發，兩臂交錯跑（medium、low、medium、low）。
- 審查者人數由裁決者自己定（原 prompt 寫「最少 3 個」），不改它；每發記「審查者人數、有沒有重派或補派」。兩臂的人數不一樣時在結果裡註明，那一部分最多只能寫「分不出」（人數會同時影響聯集命中與整發秒數，n=2 分不開）。
- 跑法：haiku 父 session 只負責派一個裁決者、等它交回（跟實際流程一樣是「主對話 → 裁決者 → 審查者」三層）。
- 命中分兩欄記，都從 subagent 自己的紀錄檔讀（不讀父 session 轉述的文字）：「審查者報告的聯集」（任何一個審查者的報告裡有）與「裁決者採納」；裁決者自己查到、審查者都沒講的另記一欄。
- 時間記三個：裁決者整發秒數（裁決者紀錄檔第一筆到它與所有審查者最後一筆的時間戳，這就是主對話實際在等的時間）、最慢審查者秒數、父 session 的 `duration_api_ms`（有兩筆 result 時取最後一筆，只當參考）。

乙部分（步驟 4，opus 審查者）：
- 素材：`docs/measurements/2026-10-24-s5-inputs/` 用的 G2、G3 兩段舊 diff 與 `2026-10-24-s4-inputs/briefs.txt`，快照與 diff 檔做法照那份 `prepare.py`。已知錯誤只算 K1、K4、K5（K2、K3、K6 受全域規則污染，只當參考）。
- 兩臂：父 session 用 haiku，只做「在同一則訊息裡派剛好 3 個 `code-reviewer`、等全部回來、把三份報告原樣交回」，不查證；差別只有派工時帶 `effort: "medium"` 或 `"low"`。G2、G3 各 2 發 × 2 臂，共 8 發。
- 三個方向在 S2-1 寫進父 session 說明、跑之前就 commit：照那一段 diff 範圍裡的檔案平均分成三份（照 `git diff --name-only` 的順序切），不看已知錯誤在哪個檔來分。
- 順序：先跑完 G2 的兩臂（medium、low、medium、low）再跑 G3，這樣預算用完時不會出現一臂 2 發、另一臂不到 2 發的素材跨兩份。第一發跑完，照它的實際費用寫出估計總額。
- 命中看三份審查者報告的聯集，從審查者自己的紀錄檔讀（父 session 不查證，所以沒有「採納」欄）。這跟 2026-10-24 的 A 組（opus 父 session 自己查證）不是同一個量法，不並排比。
- 時間記：最慢審查者秒數（主對話在步驟 4 等的就是它）、每個審查者的秒數。

兩部分共用：
- 每發 `--settings '{"advisorModel":""}'`、`--max-budget-usd 8`、`--permission-mode dontAsk --allowedTools "Agent Read Glob Grep Bash"`（dontAsk 沒放行 Agent 就派不出去）、硬逾時；cwd 是那一發的快照，`--add-dir` 給放 prompt 與 diff 檔的實驗目錄（照 `s5-inputs/run.sh`）；`permission_denials` 不是空的那一發作廢重跑，費用照樣計入；跑完讀 `modelUsage` 的鍵確認沒有別的模型混進來。
- 量：整發秒數、最慢那個審查者的秒數、每個審查者的輸出 token 與思考 token、工具次數、費用、紀錄檔裡每個審查者的 `effort` 值（操作檢查）、`permission_denials`。操作檢查另外比兩臂的思考 token：low 臂沒有比 medium 臂少時，結果裡註明「欄位是 low，但思考量沒有變少」。某一發有任何審查者的 `effort` 欄位不是該臂的值：那一發作廢、重跑，費用照樣計入累計，作廢的理由記在結果文件。
- 洩題檢查：審查者、裁決者與父 session 的工具「呼叫」（Read 的路徑、Bash 的指令、Grep 的路徑）不可以指到快照與實驗目錄以外的 repo 路徑（做法照 `s5-inputs/checks.py`）；命中的逐筆人工看：真的讀到外面的檔才算，只是字串裡帶斜線（例如 echo 的內容）算誤報。每一筆判定（含誤報）記在結果文件；算數的那一發作廢重跑。
- 判準（跑之前寫進量測文件並 commit）。每一部分各判一次，結論只有三種：
  - 命中 ① 分三支：medium 臂 0 發命中 →「分不出」（不管 low 幾發）；low 臂少於 medium 臂 →「不建議改」；其餘算 ① 成立。甲：那條重大出現在「審查者報告的聯集」的發數，low ≥ medium（看聯集，不看裁決者採納 —— 裁決者會自己補查，看採納會把審查者漏掉的蓋過去）。乙：K1、K4、K5 出現在聯集的發數合計，low ≥ medium。
  - 時間 ②：甲比「裁決者整發秒數」，乙比「最慢審查者秒數」。要同時成立：low 臂的平均 ≤ medium 臂平均的 75%，而且兩臂不重疊（low 臂每一發都比 medium 臂每一發小；乙分 G2、G3 各自比）。
  - ① 成立、② 成立 →「建議改」。① 成立、② 不成立 →「分不出」（不寫建議改，也不寫不建議改）。寫「不建議改」而兩臂只差 1 發時，旁邊註明 n=2 下差 1 發分不出是不是真的比較差（保守起見仍不建議改）。
  - 甲另有一條：兩臂的審查者人數分佈不同 → 最多寫「分不出」。
  - 為什麼要「不重疊」：同一做法、同一份素材，兩發之間本來就差很多 —— 2026-10-24 的 `G3-dhk-3` 最慢審查者 136 秒、`G3-dhk-4` 234 秒（差 1.72 倍），只看 75% 的話雜訊就能過關。這組數字跑之前抄進判準那一節。
  - 雜訊下碰巧過關的機率也抄進判準那一節，寫「建議改」時列在旁邊：沒有任何效果時，每臂 2 發的四個秒數「low 兩發都比 medium 兩發小」的機率是 2!·2!/4! = 1/6（約 17%）；乙要 G2、G3 各自成立，兩份素材獨立時約 1/36。
  - 少跑：某一部分有任何一臂、任何一份素材不到 2 發（預算或作廢造成）→ 那一部分寫「沒跑完，不下結論」，已跑的數字照列。
  - n=2，三種結論都只講方向。
- 進 repo 的東西：新目錄 `docs/measurements/2026-11-15-reviewer-effort/`（`prepare.py`、`run.sh`、`stats.py`、兩份父 session 說明、`CLAUDE.md`、去識別後的報告與 stats）與結果文件 `docs/measurements/2026-11-15-reviewer-effort.md`。原始 stream-json 不進 repo，只抽判定要用的欄位；掃 `/Users/`、`-Users-`、`-private-tmp-`、帳號字樣。

小任務：

- **S2-1 實驗輸入與判準**。檔案：上面那個新目錄的腳本與說明、結果文件的「方法、正確答案、判準」三節。驗證（不寫測試，理由：一次性的量測腳本）：開工前提 1 的那一發；`prepare.py` 產出的 prompt 沒有殘留佔位字串（腳本自己 assert）；`stats.py` 對開工前提那一發的紀錄跑得出一列。commit：`docs: 審查者思考強度實驗的輸入與判準（S2-1）`
- **S2-2 跑甲部分並寫結果**。驗證：4 發的操作檢查欄都符合該臂；洩題檢查 0 筆；表上每個數字能用 `stats.py` 重算。commit：`docs: 計畫審查審查者 medium 對 low 的結果（S2-2）`
- **S2-3 跑乙部分、寫結果與結論**。驗證同上（8 發；預算不夠時照開工前提 3 少跑，少跑了哪幾發寫明）。commit：`docs: 步驟 4 審查者 medium 對 low 的結果與結論（S2-3）`

### 要新增的測試清單（全部在 `tests/test-install.sh`）

- T2 加呼叫點 `acw`（`autocompact_state`，jq 與 python3 兩臂比結論），每個案例都帶預期的回傳字（輸入類別裡「最上層」「個別模型」都是指那個鍵的值；整份檔案是 `null`、陣列另外列）：檔案不存在、空檔、壞 JSON、整份是 `null`、整份是陣列、`{}`、最上層是有效值、最上層是字串（回 `outofrange`）、最上層是 `true`（回 `outofrange`）、最上層是 `null`（當沒有這個鍵）、最上層是 5（範圍外）、最上層是 2000000（範圍外）、最上層是 `400000.0`（算有效）、最上層是 `400000.5`（不算）、最上層範圍外而個別模型有效（回 `outofrange`）、只有個別模型是有效值、個別模型的值是字串 `"auto"`、個別模型的值是 `true`、個別模型的值是 5、`modelSettings` 是陣列 `[{"autoCompactWindow":400000}]`（回 `none`）、某個模型的值不是物件、最上層與個別模型都有效（回 `all`）、開頭有 BOM、檔案裡有兩個 JSON 值
- T10 裡另寫的小驅動，測 jq 與 python3 都沒有時的退化路徑（照 T9 `nojson.sh` 把兩個都遮掉）：檔案裡有 `"autoCompactWindow"` 字樣回 `unknown`、沒有字樣回 `none`
- T10：真的跑 `--check`，下面每種情況各印對的那一行 —— 最上層有設、最上層的值在範圍外、只設在個別模型、都沒設、檔案壞掉、環境變數是 400000、環境變數是 5、環境變數是 `0400000`（`envodd`，而且輸出裡沒有 shell 錯誤訊息）；每格比對該狀態獨有的一段字；ffmpeg 那一行不再是 `└──`、新的這一行是 `└──`；另外確認這一行不影響 exit code（都沒設時 `--check` 仍 rc=0）
- `TEST_ONLY` 合法值加上 `T10`（打錯值仍 exit 2）

S2 不加測試。

## 計畫審查紀錄

三輪，每輪裁決者（opus）派 4 個審查者（haiku），都過了讀檔檢查，沒有重派或補派。三輪都沒有「需使用者決定」。

- 第 1 輪：不通過（3 條重大）。重大：甲部分把「裁決者採納」當命中、把最慢審查者秒數當等待時間；n=2 下「中位數 ≤ 75%」分不出雜訊；安裝輸出與 README 要寫的設定說法只有摘要、沒有原文（外部查證）。三條都改了，外部查證的結果是 F15、F16
- 第 2 輪：不通過（2 條重大）。重大：`none` 那一行把一個模型的一次觀察寫成所有模型都這樣；甲的洩題檢查用關鍵字 grep 會把唯一的計分項誤標成受污染。兩條都改了
- 第 3 輪：通過。採納的小事都已改進上面的段落

駁回的（每條一句，照裁決報告）：

第 1 輪

- 輪1-R1-1（主體）｜說「最上層是 true」指的是整份文件｜那一串是在講鍵值；整份文件是 null 或陣列另外列了。
- 輪1-R1-4｜drive.sh 沒有 `acw)` 分支｜「加呼叫點」本來就包含加這個分支，漏了一跑就會報錯。
- 輪1-R2-5｜沒寫標 DONE、刪除根目錄指路的 commit｜計畫照 task-planner 步驟 5 開表，規則區塊照抄進設計文件，那些規則管這件事。
- 輪1-R2-8｜A2 的 CI 數字檢查不確定有沒有｜ci.yml:161–163 確實會比對「N 個編號步驟」，A2 成立。
- 輪1-R3-2｜README 的因果句沒有被驗到｜那句寫的是 F1、F2 量到的數字，沒有斷言因果，也有指到量測檔。
- 輪1-R3-7｜`set -e` 加上 grep 會讓安裝中止｜計畫的 T10「都沒設時 rc=0」會變紅，不是靜默的錯。
- 輪1-R3-8（後半）｜說 T2 清單只收寫入型函式｜那份清單也有唯讀的 `plugin_enabled_state`、`mcp_scope`（CLAUDE.md:258–259），判準是「有 jq 與 python 兩條路」。
- 輪1-R3-9（中位數那部分）｜n=2 的中位數等於平均｜寫法不影響結論；少跑時怎麼判已經併入重大第 2 條。
- 輪1-R3-11｜S2「依賴 S1」｜這是使用者選的順序（A1），寫成依賴沒有壞處。
- 輪1-R3-13｜說事實裡沒有「使用者把預設改成 high」｜事實 :108 寫了使用者打了 `/effort high`。

第 2 輪

- 輪2-R1-7｜沒有 jq 也沒有 python3、檔案裡又沒有 `"autoCompactWindow"` 字樣時回 `none` 是「不確定卻說確定」｜這個情況下不管檔案壞不壞，那個檔裡確定沒有這個鍵，`none` 是對的。這也跟 `plugin_enabled_state` 的既有退化路徑一致。
- 輪2-R2-4｜設定不是「前置需求」，不該放在那段｜這是放哪一段的寫法選擇，句子本身不會錯。計畫同時在安裝步驟 1 與費用小節都有寫。
- 輪2-R3-6｜甲的判準 ② 把裁決者自己的時間也算進去，會稀釋效果｜這是第 1 輪重大 輪1-R4-1 採納的設計：主對話在等的就是裁決者整發，稀釋效果本來就是要量的東西。
- 輪2-R4-2｜快照裡 CHANGELOG.md:237、scripts/dd-init-upgrade.sh:75 的句子，以及 25 處 2026-11-14 的 CLAUDE.md 字樣會洩題｜b1935bb 的 commit 時間是 2026-11-14 21:33，早於 judge-r1.txt 的 22:30。那些內容就是當時審查者實際看得到的 repo，原本就該讀得到，不算洩題。
- 輪2-R4-7｜「預設改成 high」不成立，`/effort high` 只是 session 設定｜同 輪1-R3-13，沒有新證據。而且 `~/.claude/settings.json` 的 `modelSettings` 確實存著 `effortLevel`（:159、:162、:172），F1 也記了 fable-5-2 原本就有 `effortLevel`，它是寫進設定檔的值。
- 輪2-R4-E1｜`all`、`permodel` 兩句「對所有模型」「換到沒設過的模型不生效」要先實測才能印｜F15 有官方原文逐字支持：最上層鍵 `For every model`；`/autocompact` 存在 `modelSettings` 的當下模型；個別值 `takes precedence`。F16 也實測過最上層鍵確實生效。至於 `none` 那句，上面重大第 1 條改成原文說法之後就不需要實測。

第 3 輪

- 輪3-R3-4｜根目錄的指路句沒有排進任何小任務｜計畫 :10 已經寫了照 task-planner 步驟 5 加，那是開表的時候做，不是小任務（同輪1-R2-5 的理由）。
- 輪3-R3-5｜審查報告放在 `docs/reviews/2026-11-15-speed-cost/`，gate 會擋｜scripts/check-claude-md.sh:205 的正規式是 `(^|/)S[0-9][^/]*\.md$`，子目錄裡的 `S1-a.md` 也認得。輪3-R2 也核過這點。
- 輪3-R3-6、輪3-R4-8｜F15 的原文是 subagent 轉述的，要再找人核、要拿 settings.json 實測｜同輪2-R4-E1，無新證據。F15 註明是逐字原文，F16 也實測過最上層的鍵確實生效；`--settings` 對 settings.json 的差別，官方原文寫的是「in a settings file」。
- 輪3-R1-4、輪3-R4-5｜個別模型設 `"auto"` 被當成沒設，跟官方原文衝突｜官方原文說 `"auto"` 就是「為該模型調的預設視窗」，效果等於沒設。最上層有設時回 `all`，句子已經寫了個別設定優先；沒設時回 `none`，句子寫的是用預設。兩種印出來的都對。
- 輪3-R4-3｜開工前提 4 比的對象寫成工作樹｜原文寫的是「對快照 b1935bb 裡的對應檔」，列的是檔名對應；R4 自己也查到 b1935bb 跟 HEAD 這幾份是一樣的，結果不受影響。
- 輪3-R4-4｜環境變數用「純數字」，設定檔用「整數值的數字」，兩條規則不一樣｜環境變數本來是字串，比較嚴的檢查只會把結果落到 ⚠「無從判定」，那是誠實的輸出，不會印錯。
- 輪3-R4-7｜README 那句「那個模型沒設」沒寫是哪個模型｜S1-2 的驗證已經要求每一句都對回量測輸出（:52），模型名在對照表裡就要對上。
