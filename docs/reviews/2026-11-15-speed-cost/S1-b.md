# S1 步驟 4：審查者 B（測試）

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

你的方向：測試。`tests/test-install.sh` 這次加的 T2 `acw` 那幾列、T10、`utf8_ok` 的改動、`TEST_ONLY`：每個斷言在它該抓的錯真的發生時會不會紅（有沒有空通過、有沒有只證明「有印出一行」）；`drive.sh` 與 `nojson.sh` 走的是不是它宣稱的那條路；有沒有哪個設計文件「要新增的測試清單」列的案例其實沒寫進去；`tests/CLAUDE.md` 這次改的每一句（變異對照、輸入類別清單、utf8_ok 那段）跟測試檔的實際內容對不對得上。

回報格式（繁體中文，短；不要貼你讀檔的過程）：
- 每條發現：級別（Critical／Important／Smell）｜位置（檔案與 diff 檔行號）｜問題｜證據（原文或指令輸出）｜會造成什麼
- Not reported：你看過、判斷不算問題的（每條一句理由）
- 需要外部查證
- What I ran：你實際跑的指令（沒有就寫沒有）
````

## 發現

審查者交回的報告全文（路徑已去識別，其餘逐字）。

````text
Critical 0 / Important 1 / Smell 1 — `git diff 60239e7 HEAD`，看的是測試這條線（T2 `acw`、T10、`utf8_ok`、`TEST_ONLY`、`tests/CLAUDE.md`）

這輪沒找到空通過的斷言。設計文件「要新增的測試清單」列的案例都寫進去了。發現有兩條：

- **Important｜位置：`tests/test-install.sh` 新增的幾列（diff 檔 594–596、604–607、616、668、673、684–699 行）**
  - 問題：這幾則測試在設計文件的清單之外，而設計文件規定加清單以外的測試要先問使用者。
  - 證據：`docs/designs/2026-11-15-speed-cost-design.md:37` 寫「測試照文件裡的測試清單加；想加清單以外的測試，先問使用者」。同檔 180–182 行的清單沒有這些項目：`a-top-min`、`a-top-max`、`a-top-nan`、`a-top-inf`、`a-pm-nan`、`a-top-null-pm`、`a-pm-mixed`；T10 的「沒有 settings.json」「環境變數是一長串數字」；nojson 的 n3（沒有檔）與 `line` 模式。
  - 會造成什麼：如果沒問過使用者，就違反設計文件自己定的規則（A8 寫明清單由使用者選定）。如果問過，請把那次同意補進設計文件；不然下一個照文件審的人會再判一次違規。
- **Smell｜位置：`tests/CLAUDE.md`（diff 檔 496 行）與 `tests/test-install.sh` 的註解（diff 檔 554 行）**
  - 問題：「寫到檔案**或管線**就正常」裡的「管線」沒有佐證。
  - 證據：第 4 部分第 8 點只列了輸出到 `/dev/null` 與輸出到檔案兩種，沒有任何一筆是管線。
  - 會造成什麼：之後有人把 `utf8_ok` 改成 `| cat` 之類的管線，會以為這條已經驗過，其實沒跑過。補一次管線的實測，或把「或管線」刪掉。

Not reported：
- 回傳字的斷言：T2 `acw` 的 regex 錨在整行（`^all$` 等），不會撞到 `.txt` 裡的 `rc=`／`settings:`／`installed:` 行。空殼那一步紅 20 條，對得上設計文件 111 行的要求。
- `drive.sh` 的 `acw` 分支：兩臂靠 `arm.txt` 核實各走 jq 與 python3；也先 `unset` 了環境變數（diff 檔 572–573 行）。
- `nojson.sh` 沒有自己核實 jq 與 python3 真的被遮掉，但遮罩失效時 n1 會回 `all`，「應該回 unknown」那條斷言就會紅，等於間接驗到了。n3（沒有檔）在 `file_exists` 就回 `none`，碰不到 grep 那條退路；它的標題也只寫「沒有檔」，沒有誤導。
- T10 各格比對的字串都只屬於一種狀態：「之間的整數」對 `outofrange`、「的純數字」對 `envodd`，彼此分得開；`@absent` 與 `{"theme":"dark"}` 能分辨「檔案不存在」那一支。只看每種狀態的第一行，`outofrange`、`permodel`、`none` 的第二行沒有斷言。對照設計文件，這不算漏。
- T10 的 shell 錯誤 regex 比 T2 窄（沒有 `: line [0-9]+: `）。我舉不出現行程式碼在哪個輸入下會漏報，所以不列。
- `acw` 沒有「只有空白」「最上層是 false」「`modelSettings` 是 null」這幾列：照程式碼推，兩臂結論相同，設計清單也沒列。
- `tests/CLAUDE.md` 的三處：變異對照 12 條與第 4 部分第 6 點逐條相符；T10 描述的 10 種與 `t10_check` 的呼叫一一對上；輸入類別清單與 T2 的列對得上。
- `TEST_ONLY` 的 `case` 與錯誤訊息都改成 T10。打錯值會 exit 2 這件事沒有測試，這是本輪以前就沒有的。
- 設計清單 180–183 行列的案例：T2、T10、`nojson.sh`、`TEST_ONLY` 每一項都找得到對應的測試。

需要外部查證：
- settings.json 有不合法的 UTF-8 位元組時，兩臂會不會結論不同。我推測 jq 會把壞位元組換成替代字元、照樣解析；python 用 `encoding="utf-8-sig"` 會報錯，結果是 `unparseable`。這是推測，沒有實跑。查法：拿 `printf '{"t":"caf\xe9","autoCompactWindow":400000}'` 在 jq 1.7／1.8 跑 `autocompact_state` 的那段過濾式。這一類輸入 `plugin_enabled_state`、`mcp_scope` 也一樣，是本輪以前就有的缺口；T2 的輸入類別清單沒有它。

What I ran（都是唯讀）：
- Read 讀 diff 檔第 1–709 行、第 2395–2529 行、第 2985 行到檔尾 → 讀完
- `grep -n` 在 diff 檔定位 `test-install.sh` 段、`WORK=`、`t2_case`、`T2_BOM` → 定位到
- `grep -n -iE '測試|T10|T2|acw|nojson|drive' docs/designs/2026-11-15-speed-cost-design.md` → 拿到清單（178–183 行）與規則（37 行）
- `grep -n -E 'NaN|Infinity|一長串|…|nojson' docs/designs/…` → 清單之外的那些案例在設計文件裡 0 筆
- `grep -nE 'print_(last_)?success\(\)'`、`ffmpeg`、`encoding=`（在 diff 檔）→ 確認 `print_success` 印 `├──`、各條 python 路徑都用 `utf-8-sig`
````

## 處置

- **清單以外的測試（Important）→ 屬實，需使用者決定**。設計文件的規則是「想加清單以外的測試，先問使用者」，S1-1 我沒有問就加了。
  多出來的：T2 的 `a-top-min`、`a-top-max`、`a-top-nan`、`a-top-inf`、`a-pm-nan`、`a-top-null-pm`、`a-pm-mixed`；T10 的「沒有 settings.json」「環境變數是一長串數字」；
  `nojson.sh` 的 n3（沒有檔）與 `line` 模式；再加上這次審查修正補的四列（`a-top-edge-lo`、`a-top-edge-hi`、`a-badutf8`、`a-bigint`）。
  其中「一長串數字」是變異「不擋長度」唯一會紅的那一格，`NaN` 那幾列跑紅時抓到我原本寫錯的預期值。
  先留著，寫進設計文件 S1 底下等使用者回答；使用者選不留就另開一個 commit 拿掉
- **「或管線」沒有佐證（Smell）→ 補了實測，句子留著**。`iconv -f UTF-8 -t UTF-8 <檔> | cat`：55 個長度（1000–1030、2040–2052、4090–4100）iconv 都回 0、內容相同；
  壞位元組回 1。`tests/CLAUDE.md` 那句補上這個結果
- 需要外部查證（不合法的 UTF-8 位元組）→ 重跑確認兩臂結論不同，已修，見 A 的第 1 條
- Not reported 裡「T10 的 shell 錯誤樣式比 T2 窄」：沒有改，報告自己也舉不出會漏的輸入
