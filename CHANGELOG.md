# 變更紀錄

記錄影響使用方式的結構性變更。版本號採[語意化版本](https://semver.org/lang/zh-TW/)，
格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，
每個版本對應一個 git tag（`git show v1.0.0`、`git log v0.4.0..v0.5.0` 可看該版完整內容）。
升級步驟見 [UPGRADING.md](UPGRADING.md)。

> 0.2.0 涵蓋專案初始（2025-12-15）到 2026-07-24 的所有變更，但只有 6 步迴圈改造
> 這一項被逐條記錄；更早的細節見 git 歷史。

## 未發布

### Changed

- **複雜任務動手前先估段落數，兩段以上 Claude 自己叫 task-planner**。原本只有使用者講「拆任務」這類
  關鍵字時一定會叫；沒講就只靠 Claude 讀 skill 說明自己判斷，而且看不出它有沒有判斷過。全域模板 §4.1
  加一條：複雜任務的計畫裡要寫出「預估 N 個功能段落」，N ≥ 2 就呼叫 `task-planner`，使用者沒提也一樣；
  task-planner 的說明補上具體訊號（一次交代好幾個功能、從頭做一個模組或系統、設計文件列了好幾個模組或頁面）。
  review 抓到的缺口一併補上：N 照功能數算（同一個功能的資料、API、畫面算一段），高風險工作不跟別的功能算同一段；
  根目錄 CLAUDE.md 已經有「進度以…為準」時照表接手、不再叫，N 只算表上沒有的新工作（不然換 session 接手可能又叫一次）；
  task-planner 只切出 1 段就停，說一圈做得完、不用拆。§4.4 沒有 task 工具時的進度表格式，改成直接指向
  `~/.claude/skills/task-planner/SKILL.md` 的「進度表格式」一節 —— 一段做得完的工作不會叫 skill，原本無從得知格式。
  裝好後用 `claude -p` 開全新的 session 實測，prompt 存在 jsonl 旁邊。這種 session 沒有寫檔工具、也叫不出
  AskUserQuestion，所以只測到「叫不叫、出不出得了草稿」，批准後寫檔、commit 那段沒測到。
  補例外之前：一次交代三個功能、不含關鍵字，第一句就寫出「預估要 3 個功能段落」並叫起 task-planner，照步驟 4
  出了草稿；只改一行字的要求沒有叫。補完之後：同樣三個功能仍叫起 task-planner（這次第一句寫的是「預估 ≥ 2 個功能段落」，
  沒寫確切段數，草稿切出 3 段）；已有進度表、根目錄有指路的專案說「照設計文件繼續做」，沒有叫，引用 §4.1 那句後照表判斷
  下一段是 S1；一個會動到資料、指令、help 的新功能（`tenant search`）寫出「預估：1 個功能段落」，沒有叫。
  兩份 README 同步
- **task-planner 改成功能段落規劃，進度表寫進設計文件**。原本拆的是「2–5 分鐘的微任務」，
  單位跟 8 步迴圈的功能段落對不上，還有三處跟全域規則衝突：每個微任務強制先寫測試（§3.5
  不主動新增測試）、不問人直接寫檔（§4.1 複雜任務先確認）、寫到 `docs/plans/`（跟
  design-brainstorm 的 `docs/designs/` 分成兩個資料夾，一個功能兩份檔）。它唯一實際跑出來的
  計畫檔也被刪掉了。改成兩層：段落（一圈 8 步，驗收寫「步驟 5 要看到什麼」；產生帳款、改帳款
  狀態、金額計算、改權限規則、批次或排程刪除這類高風險工作不跟其他功能混在同一段）與段落內的
  小任務（`S2-1` 編號，實作、驗證、commit，commit 訊息帶編號）；小任務 commit 了不等於段落完成，
  小任務全部做完、SKIP 欠下的 CLAUDE.md 補完，才整段跑步驟 3–8，跑完才標 `DONE`。進度表寫進
  設計文件（沒有設計文件就在 `docs/designs/` 開一份短的），規則區塊照抄進文件，換 session 只讀
  文件也照得做；先列要新增的測試與決策題，使用者批准後才寫檔並 commit；下一段固定照表上順序挑，
  有段落 `BLOCKED` 或冒出新工作都先停下來問。改寫時拿 rental-line 設計文件與 rental-management
  口頭需求各乾跑一次（只讀），抓到二十多處讀法不一或互相矛盾的地方一併改掉。全域模板 §4.4 的
  檔案式追蹤跟著改用這張表（沒有設計文件、就算只有一段也開一份短的；取代下面那條的 `docs/plans/`
  與 🚧 / ✅），design-brainstorm 的交接說明同步。改完再做一次完整乾跑：第二版重跑同樣兩次規劃，
  另外在拋棄式沙盒專案照規則真的做完三段（寫程式、commit、步驟 3–8），中途換一個沒讀 skill、
  只讀專案文件的 agent 接手做完。進度表、commit 編號、範圍、指路刪除逐項用指令核對都對得上，但又抓到
  只讀看不出來的問題：接手規則照字面會跳過還沒做的小任務；gate 在目錄同時有 staged 變更與 SKIP 欠帳時
  只印 staged 的理由，照訊息補會漏（規則改成看 `git diff <起點> -- <目錄>`）；「清單外的測試先問」
  沒進規則區塊；指路不空一行會併進上一段。規劃端的決策題界線、專案要求兩種驗法時怎麼寫、指路連結與
  舊進度宣告的衝突等 17 處一併改掉；review 又補上三件：接手時會對到別份文件的同編號 commit（改看
  表上起點之後的 log）、先補好 CLAUDE.md 就不會被 gate 擋（所以不論擋不擋都看整段 diff）、使用者
  中途要先做別的事沒有規則（比照 `BLOCKED`，回頭做時起點不改）。§4.4 的「沒有這列就先加」限定為
  使用者交代的段落並連同小任務一起補，不再跟「冒出新工作先問」衝突
- **全域模板 §4.4 補上「原生 Task 工具與 TodoWrite 都沒有」時的退化路徑**。原本只寫
  「新版用原生 Task 工具、舊版用 TodoWrite」,假設 harness 一定會提供其中一個 ——
  實際遇過兩組都不提供的 build(`ToolSearch` 找不到,關鍵字搜尋只回 `TaskOutput` /
  `TaskStop`,那是背景 job 的輸出與中止不是待辦)。沒寫退化路徑的後果是模型直接
  宣稱「沒有 task 工具可用」然後跳過追蹤。補的做法是**檔案式追蹤**:段落寫進設計文件
  或 `docs/plans/` 的段落表,開工標 🚧、收工改 ✅ 並補 commit 清單 —— 它跨 session
  留著也進 git,比工具式耐用,代價是沒人提醒更新,所以強調「開工就先加那一列」。

- **全域模板 §6.2 補上除錯的第一個分支：「跑的是不是你剛改的那份」**。原本只教
  「先分辨錯的是被測物還是測試本身」，漏掉熱重載（`node --watch`、nodemon、HMR、
  掛載進容器的 volume）還沒跟上這種情況 —— 錯誤訊息看起來完全合理，會讓人開始改
  沒問題的碼。判準是**錯誤訊息的行號對不對得上現在的檔案**。
- **全域模板 §2.6 第 1 點的觸發條件補上「含回傳形狀」**。原本寫「改既有函式/設定/
  介面前先 Grep 呼叫端」，但「回傳從陣列改成物件」不長得像簽章變更，觸發不了這條規則
  —— 而動態語言漏掉的呼叫點 lint 與單元測試都抓不到，只有跑到那一行才炸。
- **`dd-init` 樣板的 Playwright 段落補上瀏覽器端的判準**。原本只寫「看後端有沒有
  收到請求」，需要另外去翻 log；補上 `performance.getEntriesByType('resource')`
  數請求數，驗「前端擋下來、根本沒送出」時不必離開瀏覽器。

### Added

- **README 新增「大工作怎麼跑」圖**（`diagrams/claude-dd-task-planner*.gif`，中英各一，放在兩份 README
  的 task-planner 段落下面）。那段文字有分岔（估出 1 段照一般迴圈、2 段以上交給 task-planner）、
  有繞回來的圈（每一段裡小任務一個個做，整段才跑 3–8，標 DONE 再做下一段），還有換 session 照表接手；
  原本兩張圖只順帶提一句。來源是新的產生器 `diagrams/src/gen_planner.py`，照 `verify-geometry.py` 畫：
  兩版幾何檢查 0 項不過（舊兩張各有 8/31 留下的未通過項），渲染後量到節點文字離框邊最少 15px，
  GIF 循環接點與相鄰幀的 PSNR 只差 0.04／0.03dB，四邊都是底色。為了過檢查的三個做法寫進
  `diagrams/src/CLAUDE.md`：節點文字的字級只寫在 `font-size` 屬性、CSS 不設（檢查腳本讀屬性，沒寫就依 class
  猜，猜得比實際大）、九個節點都放進容器、邊標籤底下墊 `data-role="mask"` 的底色塊。review 抓到「怎麼估段落數」
  把高風險講寬了：英文版寫成 billing or permission work，連 SKILL 說要跟功能放一起的「沿用既有的權限檢查」
  都包了進去，已照 §4.1 改成「產生帳款、改權限規則這類高風險工作」
- **`skill-creator` 納入 `OFFICIAL_PLUGINS`**（Anthropic 官方 plugin，走 `/plugin`
  路線，不 vendor 進本 repo）：補上「怎麼跑一輪 skill 開發」— 訪談 → 草稿 →
  同一批測試題跑「有 skill / 無 skill」兩組對照 → 評分 → 迭代，與既有
  `writing-great-skills`（純寫作觀念參考）互補而非重疊。
  連帶修 `install_plugins()` 三處：①`plugin.json` 缺 `version` 欄位時（skill-creator
  即如此）改讀 `installed_plugins.json` 裡 Claude Code 記的值（缺 version 時它填內容
  雜湊）②兩處讀取都加**型別護欄，只接受 JSON 字串** — 沒有它時 `"version": null` 在
  jq 印 `null`（被守衛擋下）、在 python3 印 `None`（**繞過守衛**，寫出
  `installPath=.../None` 這種指向不存在目錄的紀錄），兩路徑不等價 ③跳過訊息改為只陳述
  「兩個檔都取不到版本字串」並附上該跑的 `claude plugin install` 指令，不再宣稱成因 —
  走到那裡的情況有四種（未安裝過／檔案損毀／entry 是空陣列／entry 在但 version 非字串），
  腳本分辨不出時就不講死。**不自行編版本號** — `installPath` 用它組 cache 路徑，
  編錯會指向不存在的目錄。等價性以 26 個邊界案例實測（plugin.json 10 例 +
  installed_plugins.json 16 例），jq 與 python3 兩路徑 0 分歧

- **`tech-diagram-gif` 收編 diagram-design 的四項規則**（借鏡自
  [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design)，MIT，
  概念改寫未 vendor 任何檔案，歸屬記在該 skill 的 `LICENSE.txt`）：硬閘門新增
  「先判斷該不該畫」、元素數量預算（節點 ≤9 / 連線 ≤12 / 強調色 ≤2 / 分組 ≤4 / 註解框 ≤2）、
  連線可量測規則（標籤間隙 ≥6px、port ≥12px、遮罩 z-order、不穿越非端點節點）、
  「產出前檢查清單（Taste Gate）」20 項。檢查清單**依判定時機與手段分五組**（第 1 步數清單 /
  第 4 步算座標 / 第 4 步看截圖 / 第 5、6 步交付），避免出現「該項要到後面步驟才有素材可判」
  或「第 4 步才發現數量超標只能整份重來」。未採用其 python 幾何驗證腳本（不塞 runtime 依賴）、
  HTML 靜態交付（本 skill 只交 GIF）與 39 型 reference（使用率盤點制）
- 同輪順帶定調：節點間距**取嚴為 80px**（`svg-layout-best-practices` 的 Universal
  Layout Rules），contract 表列的 40px 是上游 showcase 不及格線，不再出現在閘門裡
- **`tech-diagram-gif` 新增 `scripts/verify-geometry.py`**（純標準庫、無 pip 依賴、
  缺 python3 退化為人工算）：把 Taste Gate「版面幾何」組從「用眼睛看」變成可執行的閘門，
  第 4 步改為「先跑腳本再看截圖」。同批新增 `test-verify-geometry.py`（12 種變異各弄壞
  一項確認抓得到、1 個回歸案例確認不誤報）與 `scripts/CLAUDE.md`。SVG 需標
  `data-role`（`node`/`container`/`edge`），無標記時腳本退化用畫法猜並印警告
- **修正一項翻譯錯誤**：邊標籤遮罩與連線的間隙原寫「6–10px」（讀成上下限），
  上游 diagram-design 原文是 minimum 6px、擁擠時 push to 8–10px —— **6 是下限不是區間**。
  照誤寫版判定，間隙 12px 的正常圖會被判不合格。已改為 ≥6px 並在 contract 記下原委
- **`diagrams/` 新增 5 張 GIF**，把 `tech-diagram-gif` 能畫的類型（4 種風格 × 2 種
  動畫模式）各出一張：Style 8 / Style 2 的傳播路徑圖、Style 11 事件流地鐵圖、
  Style 12 事故排查、以及建置→營運五幕敘事動畫。Style 11 / 12 需要 Kafka 拓撲與
  監控數據，claude-dd 沒有，用示範情境並在圖上標明非實況。
  手寫 SVG 來源進 `diagrams/src/`（與腳本產生的 SVG 不同，那是產物、這是來源），
  `diagrams/src/CLAUDE.md` 補上兩類來源的區分
- **vendor intake 清單補「只借概念、不抄檔案」的歸屬規則**：歸屬要精確到段落／項目，
  不可整節掛名。判準是「能逐條指出哪一段來自誰」。同輪把該 skill 的量化數字從三份手抄
  （第 1 步、第 3 步、Taste Gate）收成一份 —— contract 是唯一來源，SKILL.md 只留
  Taste Gate 這份操作用的逐項版本，其餘改為指路

- **CI 迴圈步數第五方檢查**：既有的四方一致只數**編號清單**，使用者實際看到的兩類
  文案不在範圍 — 安裝腳本印出的「N 步開發迴圈」，以及散落各處的一行式箭頭摘要。
  第五方補上這兩類：箭頭摘要先合併續行，箭頭 ≥3 且同時含 `commit` 與 `review`
  才認定為迴圈摘要；腳本部分排除註解行（那裡是有日期的歷史敘述），CHANGELOG 與
  UPGRADING 同理排除。上線當下就抓到人工逐檔翻仍漏掉的一處

### Fixed

- **`/dd-init` 在沒有 `.gitignore` 的專案不會把 CLAUDE.md 送進版控**：Phase 5 原本寫
  `git add CLAUDE.md .gitignore 2>/dev/null || true`。`git add` 是全有全無，純後端/CLI 專案
  沒有 `.gitignore`（Phase 2 只在有前端 UI 時才建），整條以 exit 128 失敗、**staged 清單為空**，
  接著 `git commit` 也失敗，但 Phase 6 照樣印「✅ 初始化完成」—— 蓋章好的 CLAUDE.md 就留在 untracked。
  改成兩條獨立的 `git add`，並讓 `git commit` 與 guard 都帶 pathspec（`-- CLAUDE.md …`）：
  不帶 pathspec 的話提交的是整個 index，使用者做到一半、早就 staged 的程式碼會被一起掛進
  「初始化」這個 commit 而毫無提示（實測重現過）。帶了之後 hook 拿到的是臨時 index、只看得到這幾個檔，
  連誤擋都不會發生。同時把 `[ -f .gitignore ] && git add …` 改成 `if … fi`（前者在檔案不存在時整行回
  exit 1，agent 把區塊拆成一行一行跑時會看成失敗）。四種情境實測：無 .gitignore、有 .gitignore、
  零 staged、使用者另有無關的 staged 變更 —— CLAUDE.md 都進版控，使用者的檔案原封不動留在 index。
  第 158 行原本保證「此 commit 只動 CLAUDE.md/.gitignore，會通過 gate」也一併更正：gate 看的是整個 index
- **安裝腳本的「s) 顯示完整 diff 後再決定」選了會直接中止安裝**：全域 CLAUDE.md 互動選單（情境 4）的
  `s` 分支裡 `diff "$target" "$source"` 單獨成行，內容不同時回 exit 1，配上檔頭的 `set -e` 直接結束整個
  安裝行程，講好的「看完後要覆蓋嗎」永遠問不到，而且中止點之後的安裝步驟全部沒跑。補 `|| true`。
  同一函式上面的 `diff … | head -30` 反而沒事 —— 管線取的是 `head` 的結束狀態。
  `bash -n` 與 `shellcheck -S warning` 對修正前的版本都是全過的，這類錯只能靠帶 `set -e` 的隔離重現抓到；
  根目錄 CLAUDE.md 補上通則（`diff`／`grep`／`cmp` 回非 0 是正常結果，一律 `|| true` 或放進管線，
  後者以腳本沒開 `set -o pipefail` 為前提）
- **`self-improving-agent` 五個 sub-skill 算出的記憶體目錄一律不存在**：`extract`／`promote`／
  `remember`／`review`／`status` 都用 `sed 's|/|%2F|g; …'` 把 cwd 編成 `%2F` 形式，而 Claude Code 實際是
  **把解析後絕對路徑裡每一個非英數字元各換成一個 `-`**（`/`、`_`、`.`、空白、中文都算）。後果全部靜默且
  回報成功：`remember` 印「✅ Saved to auto-memory」但寫到不存在的路徑、`status` 讀到 0 個檔判為 healthy、
  `review` 判定「auto-memory may be disabled」。改用 `pwd -P | sed 's/[^a-zA-Z0-9]/-/g'`（`-P` 是因為
  Claude Code 記的是實體路徑，macOS 的 `/tmp` 就是 symlink）。中途採用過只換 `/` 與 `_` 的版本，被
  code-review 以 CLI bundle 內的 `replace(/[^a-zA-Z0-9]/g,"-")` 與真實 session 建出的目錄推翻；
  修正版拿 Claude Code 自己建的三個目錄對照全中，含 `測試 目錄/v1.2_x` → `-------v1-2-x` 這種。
  五處都補上驗證與 glob fallback：`LC_ALL=C`／`POSIX` 下 sed 會逐 byte 而非逐字元，非 ASCII 路徑會多出
  一堆 `-`，而這個 repo 是可攜設定庫，Linux 上踩得到。原本 `review` 唯一那條 fallback 也是壞的
  （拿未編碼的 basename 去比對已編碼的目錄名，`*my_project*` 無匹配）
- **gate 放行了「用 SKIP 跳過、之後也沒補」的 CLAUDE.md**：gate 原本只看「這一次 commit」
  staged 的檔案，檢查點 commit 用 `SKIP_DOC_CHECK=1` 跳過的目錄，只要最終 commit 沒再碰
  那些目錄的程式碼就不會被查。rental-line 段落 1 實際發生：第一個 commit 用 SKIP 建了
  `backend/src` 等 4 個沒有 CLAUDE.md 的程式碼目錄，最後一個 commit 沒動程式碼，gate 直接
  放行（約一小時後才手動補上）。用 gate 同一套規則重算 rental-line 的 commit，13 段裡有 8 段
  有 commit 是跳過檢查才進得去。修法：新增**段落起點**（`git rev-parse --git-path dd-segment-base`，
  worktree 各自一份）—— `--start-segment` 在段落開始前記下，忘了記時第一個 SKIP commit 自動記；
  之後每個正常 commit 沿著 commit 的祖先關係結算起點以來的欠帳（改程式碼記帳，要由看得到那段
  程式碼的後代 commit 更新該目錄 CLAUDE.md 才銷帳，merge commit 自己補的也算），所以起點再舊
  也不會變寬鬆，平行分支上的 CLAUDE.md 更新也抵不掉。起點被 amend／rebase 改寫時改從共同祖先算；
  目錄在 index 裡已經沒有程式碼就不再追討；還有欠帳時 `--start-segment` 拒絕重記；
  `--segment-base` 印出起點給迴圈步驟 3、4、8 算範圍，起點失效就失敗。整段一次掃完，
  起點到 HEAD 有 1000 個 commit 時約 0.08 秒。CI 新增 61 個情境檢查（含還沒有 HEAD 的第一個
  commit、舊起點、起點被改寫、merge、程式碼刪掉或搬走、只在工作目錄刪掉、根目錄與含空白的目錄名）
- **非 ASCII 路徑完全不檢查**（原始版本就有）：git 預設把中文路徑加引號跳脫（`"功能/\345…"`），
  結尾變成引號，副檔名永遠比對不到 —— staged `功能/a.js` 又沒有 CLAUDE.md，原始版本 exit 0 放行。
  列檔案的 git 指令改用 `core.quotePath=false`
- **迴圈步驟 3、4、8 只看最後一個 commit**：simplifier 包裝器預設 `git diff HEAD~1`、
  步驟 8 算範圍用 `git show HEAD`、本地 code-reviewer agent 不給範圍時只看還沒 staged 的改動，
  但一段常有好幾個 commit。rental-line 13 段裡有 11 段只看最後一個 commit 會漏掉 CLAUDE.md
  （全部 96 份只看得到 31 份；段落 1 算出來是空的，第一個 commit 建的 5 份都不在範圍內。
  該專案 2026-09-09 已在自己的 CLAUDE.md 改用 `<base>..HEAD`，這次回寫）。全域模板 §3.9、
  `/dd-init` 蓋章版、code-simplifier 包裝器改成段落開始前跑 `--start-segment`、範圍用
  `--segment-base` 算；蓋章版加 `dd-loop-rev`（目前是 `4`），標記是 `8step` 但 rev 比現行值舊
  （沒有 rev 標記或號碼更早）的專案跑 `/dd-init` 會提議升級。UPGRADING 補上這個升級步驟，
  並更正「`/dd-init` 會跳過既有區塊」的過期說法。
  連帶補上：步驟 4 依序跑時另附 `git ls-files --others --exclude-standard`（簡化新增、還沒 commit
  的檔案 `git diff` 看不到）；蓋章版補上並行時的範圍寫法；步驟 8 指令加 `core.quotePath=false`，
  抓未 commit 的用 `git diff --name-only HEAD` 加 `git ls-files --others --exclude-standard`
  （中文目錄、未追蹤新目錄裡的 CLAUDE.md 原本都會漏；**不要用 `status --porcelain -uall | awk '{print $NF}'`**，
  含空白的路徑 git 會加引號，`$NF` 從空白切開後比對不到，少列一份卻照樣 exit 0）；CI 檢查 dd-init 裡的
  dd-loop-rev 前後一致
- **`--check` 把停用中的 plugin 回報成「已啟用」**：`check_plugins()` 原本用
  `grep -q "\"$plugin_key\""` 判斷 settings.json，但 `enabledPlugins` 是
  `{key: bool}`，**停用是「鍵在、值為 false」**，grep 只看得到鍵在。實測本機
  `ralph-wiggum` 值為 `false` 卻被報成「✅ 已啟用」。新增 `plugin_enabled_state()`
  比照 `mcp_scope()` 的分級：`enabled` / `disabled` / `none` / `unparseable`
  （檔案損毀，無從判定）/ `unknown`（缺 jq 與 python3，只有字串證據、分不出
  true 與 false）。jq 與 python3 兩路徑以 15 例邊界測試驗過 0 分歧
- 六張 GIF 的循環接點會跳：球的 `begin` 是 `dur` 的整數倍時，「跑完一圈跳回起點」
  剛好落在 GIF 循環接點上。另外 `dev-loop` 的框間連線只有 20px，而球含光暈直徑 16px，
  停在終點時整個箭頭被蓋住 — 那 5 條短連線改為只留箭頭
- **8 步迴圈的文案殘留 9 處**：2026-08-31 迴圈擴充到 8 步時三類文字沒跟上 —
  安裝腳本印給使用者的訊息仍寫「6 步」（2 處）、標題宣稱 8 步但箭頭只列到第 6 步
  （6 處，含 `DD_PIPELINE_ARCHITECTURE.md` 停在 7 段）、`README.zh-TW.md` 把安裝腳本
  **自身進度**的 7 步誤寫為 8 步而括號內仍是 `1/7 … 7/7`（英文版同段本就正確）。
  本檔與 UPGRADING 的歷史敘述、`/dd-init` 的 `6step`／`7step` 版本標記均不動 —
  後者是舊專案升級偵測的判斷依據

### Removed

- **移除三層架構圖**（`claude-dd-architecture*.gif` 與 `gen_arch.py`）：它畫的是目錄
  清單而不是架構，13 個框寫的都是 `DD_PIPELINE_ARCHITECTURE.md` 已有的文字，
  卻多一份圖要隨每次改動重畫。README 保留 `usage-flow` 與 `dev-loop` 兩張

## 1.1.0 — 2026-08-31

### Changed

- **開發迴圈由 6 步改為 8 步**（同日兩階段擴充）：
  - **步驟 7「沉澱本輪所學」**（`claude-md-management:revise-claude-md`）— 本輪學到的
    踩雷／指令／慣例寫進 CLAUDE.md，會先列建議等使用者同意才寫檔；沒學到就跳過
  - **步驟 8「評分 & 修正本輪動過的 CLAUDE.md」**（`claude-md-improver`）— 補 pre-commit
    gate 的盲點：gate 只確認改碼目錄的 CLAUDE.md「有寫」、**不確認「寫得對」**。
    **第一個動作是算範圍**（`git show HEAD` 聯集 `git status`），因為該 skill 的 Phase 1
    是「find 全部」，實測有專案含 87 份 CLAUDE.md，不先算範圍會全 repo 掃。
    **步驟 7 跳過不代表步驟 8 跳過** — gate 逼出來的那些改動一樣要審
  - 步驟 1–6 編號與內容不變。先在 claude-dd dogfood 4 次抓到 2 個真錯誤才推全域。
    已用舊版 `/dd-init` 蓋章過的專案不會自動更新，重跑 `/dd-init` 會偵測舊版並提議升級
- 全域模板收緊回應風格與 task 粒度；巢狀 CLAUDE.md 的代價改寫為
  「代價 → 對策 → 殘餘風險」三段式
- 全域模板 §3.4 砍掉 `/goal` 的操作手冊（官方文件轉述，非行為規則），留一行指路
- `claude-mem` 由必要 MCP 改列「推薦第三方 Plugin」— 它走 hooks + plugin 系統，
  MCP 檢查對它永遠誤報未安裝

### Added

- 全域模板 **§2.6 動手前範圍盤點與佐證要求**：改既有介面前先 Grep 呼叫端並列出受影響
  檔案；病因要有第一手證據；結果只報實際跑過的
- 全域模板 **§4.1 停等語規則**：使用者說「先告訴我」「不要直接改」時，該輪只出計畫
- 全域模板 **§2.5 擴充**：skill / agent / 工具的 description 也算「名稱層級」資訊，
  要拿它的行為下判斷前先讀 SKILL.md 本體
- 全域模板 §7.2 觸發表新增 `revise-claude-md`（關鍵字刻意避開 improver 與
  self-improving-agent，避免撞列）
- **第三張圖表「8 步開發迴圈」**（`claude-dd-dev-loop*.gif`，中英各一）並嵌進兩份
  README — 先前兩張圖只把迴圈壓成一個框裡的一行字
- **`diagrams/src/` 納入版控** — 6 張 GIF 的產生器（零依賴 Python 手寫 SVG）與重出流程。
  先前只保存成品 GIF，改一個字就得整張重畫
- `tech-diagram-gif` 陷阱表補上 playwright 的工具層與瀏覽器層差異：`browser_navigate`
  擋 `file://` 但 `run_code` 裡的 `page.goto('file://…')` 不受限、`run_code` 裡拿不到 `fs`、
  `page.screenshot({path})` 可寫任意路徑
- **CI 新增兩道防線**：安裝 flag 三方對照（腳本 case 分支 ↔ `--help` ↔ 兩份 README）、
  迴圈步數四方一致（全域模板 §3.9 ↔ `/dd-init` 蓋章版 ↔ 兩份 README ↔ `dd-loop-version` 標記）

### Fixed

- **`/dd-init` 的版本標記停在 `6step`** — 判斷邏輯是「含 `6step` → 已是現行版」，
  導致已蓋章的專案永遠不會被提議升級。**靜默失效、不報錯**
- 兩份 README 的迴圈清單只列到第 7 步，與「8 步」標題自相矛盾
- `/dd-init` 蓋章版與兩份 README 原本把 `/revise-claude-md` 當成巢狀文件同步的工具，
  與其實際行為（回顧本 session 學到什麼）不符 — 已拆成兩件事分別說明
- `diagrams/src/gen_usage.py` 只產 `.svg` 不產 `.html`，與該目錄 CLAUDE.md 寫的
  「6 份 .svg 與 .html」不符，照文件做會在重出流程第 2 步斷掉
- README 與 CLAUDE.md 事實查核：13 處與實作對齊的修正

### Removed

- 可選 MCP 移除 `cipher` — 上游已 deprecated 改名 byterover-cli，本機使用紀錄已斷

## 1.0.0 — 2026-08-11

首次對外發布。版本號自本版起生效，`install-dd-pipeline.sh` 的 CLI flags 與
`~/.claude/` 佈局視為穩定介面，日後破壞性變更走 2.0.0。

### Added

- 雙語 README：`README.md`（英文，GitHub 預設顯示）與 `README.zh-TW.md`（繁體中文），
  兩份頂部各有一行語言切換列。英文版含 language note，說明規則本文仍是繁中
- 專案架構圖與使用流程圖（`diagrams/*.gif`，Style 8 Dark Luxury、8 秒循環、20fps），
  由 tech-diagram-gif skill 產出並納入版控，兩份 README 皆嵌入。雙語出圖：
  英文用原檔名（與 README 同一套慣例），繁中版加 `.zh-TW` 後綴
- 可選 MCP 新增 `context7` — 取版本正確的官方文件，支撐全域 CLAUDE.md §2.5
  「禁止從名稱推論 API」
- CHANGELOG 改採 semver，回溯補上 v0.2.0–v1.0.0 的 git tag

### Changed

- MCP 檢查改為真正解析 JSON 判斷 scope（jq → python3 → 退化標示），區分官方
  `user` 與 `local`；`~/.claude.json` 同時存放所有專案的設定，字串 grep 會把
  別的專案的設定誤判為已安裝
- 對外整備：清除客戶代號、升級指南與變更紀錄自 README 拆出為 UPGRADING.md / CHANGELOG.md
- CI 數字宣稱檢查改語言無關正規式，並同時驗兩份 README

### Removed

- `templates/*.template` 7 個文件模板（REQUIREMENTS / ARCHITECTURE / API_CONTRACT /
  EXAMPLES / ADR / PROJECT_STATE / CLAUDE.md）— 舊多階段流程的產出物，其消費者
  （`/dd-start` 等）已於 0.4.0 刪除，現行 `/dd-init` 直接生成內容，全 repo 無讀取路徑
  - 安裝步驟由 8 步減為 7 步，不再部署 `~/.claude/templates/dd/`
  - **既有安裝的 `~/.claude/templates/dd/` 不會被自動刪除**，需要時手動 `rm -rf` 或跑 `--uninstall`
  - 取回：`git checkout pre-prune-2026-08-04 -- templates/`

### Fixed

- MCP 檢查的假陽性；`~/.claude.json` 損毀時回報「無法判定」而非誤報未安裝；
  jq 與 python3 兩條路徑的型別護欄對齊，同一台機器裝不裝 jq 得到相同結論
- 文件死連結與 tag 目標錯誤

## 0.5.0 — 2026-08-10

### Added

- 自製 skill `tech-diagram-gif`：技術圖表繪製與 GIF 匯出（流程圖 / 架構圖 / 走向動畫），
  風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)（MIT）
- 安裝腳本環境檢查加入 `ffmpeg` 可選項偵測：缺少時該 skill 退化交付 SVG，不中止安裝

### Changed

- Promoted skills 由 9 個增為 10 個

## 0.4.0 — 2026-08-04

單桶化：repo 改為單一部署清單，只保留有實證使用紀錄的元件並全數預設部署。
被刪內容可自 tag `pre-prune-2026-08-04` 取回（該 tag 落在本版範圍內），見 UPGRADING.md。

### Removed

- deprecated 桶：全歷史 0 次使用的 34 skills / 17 agents / 6 dd 指令 / 13 NS commands
- misc 桶：SRE 備援性質但零實際調用的 11 skills / 5 NS commands
- 安裝腳本的 `--prune`（單一清單後無桶可清）
- plugin marketplace 分發路線（`.claude-plugin/marketplace.json`）— 同批評估、實測可行後
  仍移除：plugin 機制無法部署全域 CLAUDE.md 與 pre-commit gate，只能交付元件子集，
  與「完整工作法」的定位不符，為維持單一安裝路線而不採用

### Changed

- 被刪的 6 個 dd 指令為舊版多階段流程的 `/dd-start`、`/dd-arch`、`/dd-approve`、
  `/dd-dev`、`/dd-test`，加上已停用的 `/dd-dx`；`/dd-init` 保留並改造

## 0.3.0 — 2026-07-31

### Changed

- 全域模板依 Claude 5 家族遷移指引調整：規則內容不變，僅語氣平述化
  （§3.1、§3.9、§7 開頭、§7.2 標題、§7.5），原 §7.6 的藉口逐條表濃縮為單一原則句

## 0.2.0 — 2026-07-23

### Changed

- 骨幹改為 6 步開發迴圈：原多階段 DD Pipeline（`dd-start` → `dd-arch` → `dd-approve`
  → `dd-dev` → `dd-test`）依實際使用率盤點後封存，改為經實際專案實戰驗證的功能段落迴圈
- `/dd-init` 改造：從產出設計文件骨架，改為蓋章開發迴圈到專案 CLAUDE.md
- 全域模板 §7.2 Skill 觸發表由 21 列瘦身至 8 列，只留預設部署元件對應項

### Removed

- §7.2 被移除列的目標已不再預設部署：senior-qa、test-engineer、tdd-guide、test-gen、
  senior-frontend、ui-design-system、ux-researcher-designer、landing-page-generator、
  senior-backend、dx-engineer、senior-fullstack、senior-secops、playwright-pro
