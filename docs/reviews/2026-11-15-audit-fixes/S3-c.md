# S3 審查 — C（文件裡的宣稱）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S3（安裝腳本：`--check` 看得出部署版與 repo 不同）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s3-review-pack.txt`，627 行，沒進 repo）的組成：
- 第 1 部分：`git diff 0dc3b53 HEAD`（表上這段的起點到 HEAD = 2276c3c），工作目錄乾淨、沒有未追蹤的檔
- 第 2 部分：步驟 3（code-simplifier）跑了，沒有改任何檔
- 第 3 部分：`install-dd-pipeline.sh` 的 `check_builtin_skills`、`install_builtin_skills`、`check_builtin_agents`、`install_builtin_agents` 開頭、`--check` 的流程，與 `tests/test-install.sh` 的檔頭、`TEST_ONLY` 那一段、T11（都帶行號）
- 第 4 部分：已跑過的驗證 V1–V7（T11 先紅後綠、macOS 與 ubuntu 整份 rc=0、8 個變異各紅在哪、對真實環境跑 `--check` 的輸出、lint、照 ci.yml 逐 step 跑）

派工 prompt（逐字；prompt 裡的暫存目錄絕對路徑在這裡寫成 `<scratchpad>`，審查者拿到的是一句「先讀這個檔再照做」加這個檔的路徑）：

> 你是程式碼審查者。職責：找漏洞、每條附證據；沒證據的不算。不寫優點、不客套。
>
> repo：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。
> 審查範圍：`git diff 0dc3b53 HEAD`（8 步開發迴圈 S3 段落，2 個 commit：64aa70b、2276c3c）。這一段做的事：
> `./install-dd-pipeline.sh --check` 的「檢查內建 Skills」「檢查內建 Agents」兩段，原本只看目錄／檔案在不在；現在目錄／檔案在的時候再跟 repo 這份比內容
> （skill 用 `diff -rq`、agent 用 `cmp -s`），不同就印「已安裝（與 repo 不同，重跑安裝會更新）」、段尾多一行「與 repo 不同：N」。只提示、不改檔、不影響結束碼。
> `tests/test-install.sh` 新增 T11；兩份 README、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md`、根目錄 `CLAUDE.md`、`tests/CLAUDE.md` 跟著改。
>
> 審查包（先讀它）：<scratchpad>/s3-review-pack.txt
> - 用 Read 的 `offset`/`limit` 每次 300 行，讀到最後一行（一次讀太多會靜靜截斷、不報錯）。共 627 行。
> - 第 1 部分是整段 diff；第 2 部分是步驟 3（code-simplifier）的結果；第 3 部分是被改到的程式碼在派工當下的相關段落（帶行號）；第 4 部分是已經跑過的驗證與預期值。
> - 被改到的程式碼以審查包第 3 部分為準；沒放進審查包的部分與其他檔直接讀工作目錄（步驟 4 期間沒有人改工作目錄）。
> - 第 4 部分的驗證已經確認過，不要重跑整份測試、不要跑 docker。
>
> 規則：
> - 只用手上的資料（讀檔、grep、git 紀錄、在拋棄式目錄裡的小實驗）判斷。需要上網、需要動到真實 `~/.claude` 才查得到的，列在「需要外部查證」交回。
> - **不要跑 `./install-dd-pipeline.sh`（任何參數）除非把 `HOME` 換成你自己建的拋棄式目錄**；不要在 zsh 裡 `source` 它（要取函式用 `bash -c 'source ./install-dd-pipeline.sh && <函式>'`，而且一樣先換 `HOME`）。不要改 repo 裡的任何檔、不要 commit。小實驗放在 <scratchpad>/rc3-c/ 底下。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：文件裡的宣稱。這一段改到的每一份文件（`README.md`、`README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md` 的 `## 未發布`、根目錄 `CLAUDE.md`、`tests/CLAUDE.md`、`docs/designs/2026-11-15-audit-fixes-design.md`）新增或改動的每一句，逐句對回程式碼與審查包的驗證輸出：講的行為是不是真的（例如「commands、scripts、output styles、全域 CLAUDE.md 不比」「比法跟安裝本身一樣」「只提示、不改檔、不影響結束碼」「只跑 skills、agents、MCP、plugin 四段」）；兩份 README 的內容有沒有對齊；根目錄 CLAUDE.md 規定「同批要改」的地方有沒有漏（在各層 CLAUDE.md 搜「同批」「同步」「手動同步」，逐條對這次的改動：新增一組測試、改 `--check` 的輸出、動到 CHANGELOG）；同一份文件裡別處有沒有因為這次改動而變成過期或互相矛盾的句子（例如別處寫「`--check` 只檢查環境」「只看在不在」這類）；CHANGELOG 有沒有動到已發布的區塊。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體輸入 → 錯的輸出）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

審查者交回的原文（逐字；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 2 / Smells 1 — 範圍：`git diff 0dc3b53 HEAD`（64aa70b、2276c3c）改到的文件，逐句對回 install-dd-pipeline.sh 與審查包的驗證輸出
>
> 【發現】
> 1｜Important｜根目錄 CLAUDE.md 新加的「`--check` 只跑 skills、agents、MCP、plugin 四段」不對，而且和同一段上面幾行互相矛盾。`--check` 會先跑 `check_environment` 和 `validate_skill_hooks`，再跑那四段。｜證據：`CLAUDE.md:27` 原文「`--check` 只跑 skills、agents、MCP、plugin 四段，commands、scripts（gate 住在這層）、output styles、全域 CLAUDE.md 過期了它看不出來。」；同檔 `CLAUDE.md:18`「環境檢查（步驟 1 / `--check`）除必要工具外含**可選項 ffmpeg**」；`install-dd-pipeline.sh:1527` `check_environment`、`:1530` `validate_skill_hooks`，兩個都在 `:1532` `if [ "$CHECK_ONLY" = true ]` 之前｜失敗情境：讀者照第 27 行判斷「`--check` 不跑環境檢查、不驗 hook 路徑」，於是不拿 `--check` 查 ffmpeg、自動壓縮視窗那一行或 hook 相對路徑。其實這三項它都會跑，只要 hook 有相對路徑它就 exit 1｜建議：改成「`--check` 在環境檢查與 hook 路徑驗證之外，只跑 skills、agents、MCP、plugin 四段」，或乾脆拿掉「只跑…四段」，留下「commands、scripts…不比」就好
> 2｜Important｜`tests/CLAUDE.md` 變異對照的頭兩條，寫的變異和實際跑的不一樣。照字面重做會紅在另一個斷言。｜證據：`tests/CLAUDE.md:99`（diff 裡新加那段的第 2 行）寫「skill 那段的 `diff -rq` 拿掉 → T11「Skills 的 dd-loop 那一行應該有」；agent 那段的 `cmp -s` 拿掉 → T11「Agents 的 code-simplifier 那一行應該有」」；審查包 V4 記的是「m1 skill 那段的條件改成 if false」「m2 agent 那段的條件改成 if false」。照字面只刪 `diff -rq` 這兩個字，`install-dd-pipeline.sh:507` 會變成 `! "$source" "$SKILLS_DIR/$skill" > /dev/null 2>&1`：執行一個目錄回 126，`!` 之後是真，所以每個 skill 都會被報成不同｜失敗情境：照文件重做「拿掉 diff -rq」→ 紅在 T11「剛裝好、什麼都沒改，--check 卻報了不同」，不在文件寫的「dd-loop 那一行應該有」。重做的人會以為測試或文件壞了。`cmp -s` 那條同理：`! "$source" "$AGENTS_DIR/…"` 是在執行一個 .md 檔｜建議：照 V4 寫成「條件改成 `if false`」（設計文件 S3 列寫的是「變異（把比對拿掉）」，同一個問題也要一起對齊）
> 3｜Smells｜兩份 README 寫結束碼「stays 0／照舊是 0」，是絕對宣稱。CHANGELOG、架構文件、根目錄 CLAUDE.md 用的是比較準的「不影響結束碼」。｜證據：`README.md:85`「It only reports: no file is changed and the exit code stays 0.」；`README.zh-TW.md:86`「只提示：不改任何檔，結束碼照舊是 0。」；`install-dd-pipeline.sh:481-483` 基礎環境檢查失敗會 `exit 1`；`:640` hook 相對路徑也會 `exit 1`，兩個都在 `--check` 路徑上｜失敗情境：機器缺必要工具時跑 `--check` → exit 1，和 README「stays 0」不符。這不是這次比對造成的，但這句讀起來像 `--check` 一定回 0｜建議：兩份都改成「不會因為這項比對而改變結束碼」或「doesn't affect the exit code」
>
> 【Not reported】
> - CHANGELOG：條目在 `## 未發布`（第 19 行）底下的 `### Added`（第 21–44 行）。diff 只動到第 27 行附近，已發布的 `## 1.6.14` 之後的區塊沒有碰。
> - 「比法跟安裝本身一樣」成立：skill 兩邊都是 `[ -d "$source" ]` 加 `diff -rq`（`:507` 對 `:664/:669`），agent 兩邊都是 `[ -f "$source" ]` 加 `cmp -s`（`:708` 對 `:751/:756`）。repo 這份不存在時，`--check` 印「已安裝」，安裝印「來源不存在」。這只出現在 repo 本身壞掉的時候，不列。
> - 「commands、scripts、output styles、全域 CLAUDE.md 不比」成立：`--check` 那一支（`:1532-1539`）只呼叫四個 check_*，然後就 `exit 0`。
> - 「重跑安裝會更新／覆蓋」成立：一般安裝會走 `install_builtin_skills`／`install_builtin_agents`（`:1551-1556`），內容不同就備份再覆蓋，不看 FORCE。`--commands-only` 不會更新，但文件寫的是「重跑安裝」，不算錯。
> - 「只提示、不改檔」：比對那一支只有 echo 和計數。T11 的 cksum 快照加上 V4 的 m4b 變異，已經守住這一點。
> - 兩份 README 新加的那段：位置相同（都接在指令範例的 code block 之後），四個要點（怎麼比、標記字樣、不改檔／結束碼、不比哪些）一一對得上。英文版多一句說明「輸出是繁中」，合理。
> - `DD_PIPELINE_ARCHITECTURE.md:76-77` 的保證條目和 `:143` 的 CI 防線表那列都和程式碼一致。這次沒有新增 CI step，不用新增列。
> - tests/CLAUDE.md T11 的描述：「沒改的不可以有」看起來只抽查了 3 個，但 `grep -cF '與 repo 不同：1'` 必須剛好 2 行，這等於每段剛好 1 個不同，所以宣稱成立。`TEST_ONLY` 的 case 有同批改成 T2–T11（`tests/test-install.sh:103-104` 與 `tests/CLAUDE.md` 那句一致）。
> - 「同批」規則：新增的是既有測試檔裡的一組，不是新的測試檔，所以不用改 ci.yml 或目錄結構那行。沒有新增 CI step、陣列、flag、迴圈步數。README 的「指令一覽」、MCP 表不受影響。
> - 既有問題，不是這次引入：`CLAUDE.md:12`「--check # 只檢查環境」、`README.md:77`「check the environment only」、`README.zh-TW.md:78`「只檢查環境（不安裝）」、`install-dd-pipeline.sh:284` help「只檢查環境（不安裝）」。這次之前 `--check` 就已經會檢查 skills、agents 在不在，這些句子早就不精確。這次讓落差變大，但不是這次造成的，所以只列在這裡。
> - 設計文件 S3 列改成 IN_PROGRESS、commit 欄寫 `0dc3b53..`，符合進度表規則（DONE 時才補上迄點）。
>
> 【What I ran】
> - Read 派工檔 prompt-c.txt 全文；Read 審查包 s3-review-pack.txt 第 1–300、300–627 行（讀到最後一行）
> - `git grep -n -e '--check' -- README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md CLAUDE.md UPGRADING.md tests/CLAUDE.md scripts/CLAUDE.md` → 列出各檔 `--check` 的敘述（UPGRADING.md、scripts/CLAUDE.md 沒有）
> - `grep -n 'exit 1|…|CHECK_ONLY…' install-dd-pipeline.sh` → exit 1 在 `:483`、`:640`、`:1513`；`--check` 分支在 `:1482`、`:1532`
> - `sed -n 470,486p install-dd-pipeline.sh` → `check_environment` 結尾 `all_ok=false` 時 `exit 1`
> - `sed -n 1541,1580p`、`sed -n 275,295p install-dd-pipeline.sh` → 一般安裝與 `--update` 的流程、help 文字
> - `grep -n '^## \|^### ' CHANGELOG.md`；`git describe --tags --abbrev=0` → v1.6.14；`git diff v1.6.14 HEAD --stat -- CHANGELOG.md` → 只有新增（114 insertions）
> - 第一條複合指令裡 `echo ===` 在 zsh 報 `== not found`，後半沒有跑；之後改用 `echo ---` 重跑
>
> 【需要外部查證】無

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實（`--check` 先跑 `check_environment`、`validate_skill_hooks`，再跑那四段）。根目錄 CLAUDE.md 那句改成「內容比對只有這兩段有：commands、scripts…過期了 `--check` 看不出來」，不再寫「只跑四段」。
- **2（Important，採納）**：與 B 的第 3 條是同一件事，處置見 `S3-b.md`。設計文件進度表 S3 那一格的「變異（把比對拿掉）」是開工前寫的驗收條件，沒有改；實際跑的變異記在 `tests/CLAUDE.md` 與設計文件 S3 底下。
- **3（Smells，採納）**：兩份 README 的「stays 0／照舊是 0」改成「does not affect the exit code／不影響結束碼」。
- Not reported 裡的既有問題沒有動：`--check` 的一行說明（`CLAUDE.md`、兩份 README 的指令範例、`--help`）都寫「只檢查環境」，這次之前就不精確（它本來就會檢查 skills、agents 在不在）。
  改 `--help` 的字要連 flag 三方對照一起看，不在這一段的範圍；最終回報提一次。
- 其餘 Not reported：都同意，沒有動作。
