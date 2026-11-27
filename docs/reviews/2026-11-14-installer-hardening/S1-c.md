# S1 步驟 4：審查者 C（文件與註解裡的宣稱）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數）與步驟 3 的 code-simplifier。
給審查者的 prompt 只有一句「完整派工在 `<scratchpad>/imp/review/prompt-c.txt`，先讀完再照做」加三句防漏；下面是那個檔的全文（路徑已去識別）。
diff 檔 `<scratchpad>/imp/review/diff.txt`（2940 行）的組成：①`git diff f6179b2 HEAD`（HEAD = 072615e）②步驟 3 與審查同時進行的說明
③`install-dd-pipeline.sh`、`tests/test-install.sh`、`tests/CLAUDE.md` 在 HEAD 的整檔內容 ④已跑過的驗證 V1–V10 與預期值。

````text
你是 8 步開發迴圈步驟 4 的審查者 C。職責：找漏洞。每一條發現都要附證據（diff 檔的行、或你實際跑的指令與輸出）；沒有證據的不算。不寫優點。

## 範圍與資料

- 審查範圍：repo <repo> 的 `git diff f6179b2 HEAD`（一個功能段落，4 個 commit：20680b1、cd1b1c7、3155dfb、072615e）
- diff 檔：<scratchpad>/imp/review/diff.txt（2940 行，四部分：整段 diff／步驟 3 的說明／被改到的檔在 HEAD 的整檔內容／已經跑過的驗證）
- **diff 檔用 Read 的 offset／limit 每次 300 行讀到最後一行**。Read 一次讀太多會靜靜截斷、不報錯
- 被改到的檔（install-dd-pipeline.sh、tests/test-install.sh、tests/CLAUDE.md）一律讀 diff 檔第 3 部分那一份，**不要讀工作目錄**：另一個 agent（code-simplifier）正在同時改工作目錄。其餘被改到的大份文件用 `git show HEAD:<路徑>`。沒被改到的檔照常讀
- diff 檔第 4 部分的驗證已經跑過、結果已確認，**不要重跑**；但「跑過」不代表結果對，預期值寫在旁邊，覺得預期本身有問題就報

## 硬性限制

- 不要執行、也不要 source install-dd-pipeline.sh（任何參數都不要）——它會改到真實的 ~/.claude。不要跑 tests/test-install.sh（工作目錄正在被改）
- 唯讀：不改 repo 裡任何檔、不 commit、不把報告寫成檔（直接在最終訊息交回完整報告）
- 需要小型重現時，只能在 <scratchpad>/imp/review/c/ 底下建檔（把要驗的那幾行邏輯抄成獨立的小腳本，對該目錄下的假檔案跑；可以用 /bin/bash（macOS 內建 3.2）、jq、python3），重現腳本不得呼叫或 source 安裝腳本本體
- 只用手上的資料判斷；需要外部查證的（上游文件、別的平台的行為）列出來交回，不要猜
- repo 的 CLAUDE.md 裡寫的 8 步迴圈與報告落地流程由主對話負責，你只做這一次審查

## 這段做了什麼（事實，不含判斷）

- backup_before_overwrite：目標是指向檔案的 symlink 時改用 `cp -L`，其餘維持 `cp -r`
- jq_inplace 開頭加 `jq -e 'type == "object"'`；py_inplace 載入後加 `isinstance(data, dict)` 檢查
- install_plugins：settings 那句 python、py_register、jq_register 改寫（鍵是 null 當成沒有；登記項第一筆不是物件就報錯）；啟用成功的 plugin 記進全域陣列 ENABLED_PLUGINS
- uninstall：兩句 python 改成鍵是 null 時不報錯
- mcp_scope：jq 與 python3 兩段都加「頂層不是物件 → 失敗」，落到既有的 unparseable；print_mcp_line 的字樣跟著改
- create_commands：清 deprecated_dd 列的舊指令檔之前先 backup_before_overwrite
- show_completion：agent 與 plugin 兩段只在 COMMANDS_ONLY=false 時印；plugin 只列 ENABLED_PLUGINS
- tests/test-install.sh：新增 T1–T9（原有的 10 個檢查沒有動）
- 文件：tests/CLAUDE.md、根目錄 CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、README.md、README.zh-TW.md、CHANGELOG.md、設計文件

## 你的方向：文件與註解裡的宣稱

這一段新增或改寫了很多敘述。逐句拿去對程式碼（diff 檔第 3 部分）與第 4 部分的實測：

1. CHANGELOG.md `## 未發布` 新增的五條、tests/CLAUDE.md 的新段落、根目錄 CLAUDE.md 改的那一段、DD_PIPELINE_ARCHITECTURE.md 改的三處、兩份 README 的 MCP 退化表、設計文件 docs/designs/2026-11-14-installer-hardening-design.md：每一句事實宣稱（行為、數字、指令、檔名、識別符、「只在 Linux 發生」這類範圍）對不對得上
2. 安裝腳本與測試檔裡新加的註解：講的原因與機制是不是真的（例如 GNU 與 macOS 的 cp 行為、jq 對空輸入的行為、`函式 || rc=$?` 讓 set -e 失效）
3. tests/CLAUDE.md 寫的那條 docker 指令照抄能不能跑；變異對照那一段與第 4 部分 V6 逐項對
4. 同一件事在兩個以上的檔講到時，說法一不一致（中英兩份 README、CHANGELOG 對架構文件、註解對文件）
5. 該改沒改的：用 `git grep`（對 HEAD）找其他還在講這些行為的敘述（覆蓋前備份、完成訊息、unparseable 的定義、設定檔解析失敗時怎麼處理、test-install.sh 涵蓋什麼），看有沒有因為這段而過期的
6. 設計文件的進度表與「段落與小任務」跟實際做的（4 個 commit）對不對得上

照你平常的報告格式交回（分級、每條附證據、Not reported、What I ran）。用繁體中文。
````

## 發現

審查者交回的完整報告（逐字；只把本機路徑換成 `<scratchpad>`、`<repo>`）：

````text
Critical 0 / Important 3 / Smells 0 — `git diff f6179b2 HEAD`（20680b1、cd1b1c7、3155dfb、072615e），只審文件與註解裡的宣稱

[Important] DD_PIPELINE_ARCHITECTURE.md「失敗不半套」新加的那句：「兩條路徑對同一份檔案的結論相同（`tests/test-install.sh` 的 T2）」寫成了全稱宣稱，但它不成立
  Failure: settings.json 開頭有 UTF-8 BOM（Windows 編輯器常見）或是兩份 JSON 黏在一起（`{}{}`）時，`jq -e 'type == "object"'` 回 0，jq 那條寫入並印「已啟用」（`{}{}` 會寫回兩個物件）；python3 的 `json.load` 丟 JSONDecodeError，印「更新失敗」。`mcp_scope` 在同樣情況下 jq 回 `none`，python3 回 `unparseable`。T2 的 92 例裡沒有這兩種，所以它守不到。根目錄 CLAUDE.md 新加的「等價靠 T2 守」也一樣。
  Evidence: c/ 底下用本機 jq 1.7.1 實跑：`cat.json` 與 `bom.json` 的 precheck rc=0，filter rc=0 而且有輸出，`jq -r '"none"'` 印出 `none|none|`（cat）、`none|`（bom）；python3 印 `Extra data` 與 `Unexpected UTF-8 BOM`。程式碼本身的落差在這段之前就有；新的是這句宣稱。要嘛改寫成「T2 那 92 例結論相同」，要嘛補上這兩類。

[Important] tests/test-install.sh 第 672 行 T3 的註解（設計文件 S1-3 也有同一句）：「它的『無備份產生』斷言靠 plugin 步驟被跳過才成立」，這個理由是錯的
  Failure: `install_plugins` 從頭到尾沒有呼叫 `backup_before_overwrite`。架構文件新加的那句「settings.json 與 installed_plugins.json 是就地改寫、不備份」、設計文件 A2 都這樣寫。所以就算 SANDBOX 裡有 marketplace，`[ ! -d backups ]` 照樣成立。這是一句辯護性的註解，會讓後來的人以為「plugin 步驟會產生備份」。
  Evidence: diff 檔第 3 部分 install_plugins（腳本第 750–904 行）沒有任何 `backup_before_overwrite`；`backup_before_overwrite` 的呼叫點只在第 539、615、921、951、987、1036、1076、1224、1246、1257 行。

[Important] tests/CLAUDE.md 新加的 `plain` 那條，以及 test-install.sh 第 427–428 行的註解：「輸出裡有壞的位元組時 BSD sed 整個失敗、什麼都不印」，這個機制寫錯了
  Failure: BSD sed 會先印出壞位元組之前的那幾行，到那一行才 exit 1。所以真正的風險是「壞位元組之後的內容全部不見」，不是「整份是空的」。照現在的寫法推理，會以為正向的斷言一定會跟著紅，但如果要找的字在壞位元組之前，正向斷言照樣綠。
  Evidence: c/bad.txt 三行，第 2 行有 `\xef\xbc`。在 UTF-8 locale 下跑 `sed $'s/\x1b\\[[0-9;]*m//g'`：stdout 是 `line1 ok`，stderr 是 `RE error: illegal byte sequence`，rc=1。

其他逐項對過的都成立：
- CHANGELOG 五條，含 16/92 例的組成、四類差異的方向、「原本印 2 個」
- 92 = 15×3 + 16×2 + 15；V4 列的 16 例跟 CHANGELOG 的分類對得上
- `jq -e` 遇到空輸入回 4；`函式 || rc=$?` 與 `( 函式 ) || rc=$?` 會讓 set -e 失效，另一個 bash 行程不受影響
- GNU 與 macOS 的 cp 差異（V9）
- tests/CLAUDE.md 變異對照跟 V6 的 14 列逐項一致
- docker 指令：假 claude 由測試檔自己放（第 19–23 行），iconv、cmp 在 ubuntu 基底映像就有，引號與 `|| exit 3` 的優先順序都對
- 兩份 README 的退化表說法一致
- 設計文件進度表：IN_PROGRESS、`f6179b2..`、四個 commit 訊息與小任務逐字相同，狀態改動跟第一個小任務 20680b1 一起送；根目錄 CLAUDE.md 的指路有加
- 「7 個寫穿連結的呼叫點」數過，對得上

What I ran
- Read diff.txt 第 1–900、1001–1300、1480–1779、2298–2392、2907–2941 行 → 取得 diff、腳本、測試檔與 V1–V10
- `git show HEAD:docs/designs/2026-11-14-installer-hardening-design.md | sed -n '1,120p'` → 進度表與小任務
- `git grep`（HEAD，排除 docs/reviews、docs/measurements）找備份、unparseable、完成訊息、test-install 的相關敘述 → 沒找到因這段而過期的敘述
- `git show HEAD:CHANGELOG.md | grep -n '^## '`、`git log f6179b2..HEAD -- <文件>` → 新條目在 `## 未發布`；設計文件在 20680b1、其餘文件在 072615e
- c/ 裡用 jq 與 python3 跑 `{}{}`、BOM、NaN 三個檔 → cat 與 bom 兩邊結論不同，NaN 兩邊都成功
- c/ 裡 `jq -e 'type=="object"' 空檔` → rc=4；/bin/bash 3.2 跑 set -e 加 `||` 的三種寫法 → 函式與子 shell 的 set -e 都失效、子行程 rc=1
- c/ 裡 BSD sed 吃壞位元組 → 印出第 1 行後 rc=1

Not reported
- BOM 與黏在一起的 JSON 這兩種情況下程式碼的落差，在這段之前就有
- README 第 5 步沒列「settings.json 更新失敗→跳過」這種情況，屬 S2 的範圍
- jq 1.8.2（macOS runner）對 BOM 的行為沒有查證，要在 runner 上跑 `printf '\xef\xbb\xbf{}' | jq -e 'type=="object"'` 才能確定
````

## 處置

- **「兩條路徑對同一份檔案的結論相同」是全稱宣稱，不成立**（Important）→ 採納，兩邊都做：
  ①程式補上這份報告實跑出來的兩類 —— 多個 JSON 值（處置見 S1-a）與開頭有 BOM。BOM 的定案是「當成正常的檔」：jq 本來就略過 BOM（本機 1.7.1 與 Ubuntu 的 1.7 實跑），
  python3 讀 JSON 的五處都改用 `utf-8-sig`；T2 補 `s-bom`、`p-bom`、`c-bom`、`j-bom`，改碼前紅、改碼後綠
  ②文件改寫：架構文件、根目錄 CLAUDE.md、`tests/CLAUDE.md`、CHANGELOG 都改成「T2 只守它列的那幾類輸入，沒列的類別沒有保證」
- **T3 註解「無備份斷言靠 plugin 步驟被跳過才成立」理由是錯的**（Important）→ 採納。`install_plugins` 確實從不呼叫 `backup_before_overwrite`。註解改成「各組用自己的沙盒，不去動原有檢查沿用的那個 `SANDBOX`」；
  設計文件 S1-3 的同一句是計畫原文，沒有改字，在 S1 的「步驟 3、4 的結果」寫了更正
- **`plain` 的說明把 BSD sed 的行為寫錯**（Important）→ 採納。自己重跑：三行的檔、第 2 行有壞位元組，UTF-8 locale 下 `sed` 印出第 1 行後 rc=1。測試檔的註解與 `tests/CLAUDE.md` 那條都改成「印到那一行就失敗、之後的內容全部不見」
- Not reported 的「README 第 5 步沒列更新失敗→跳過」：收進設計文件 S2-1 的第 5b 項
- Not reported 的「jq 1.8.2（macOS runner）對 BOM 的行為沒查證」：仍然沒驗證，記在設計文件；push 之後 macOS job 的 T2 會跑到
