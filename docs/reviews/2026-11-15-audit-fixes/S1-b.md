# S1 審查 — B（測試的鑑別力）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S1（gate：dd.docfile 不收程式碼檔名、起點失效時的訊息、BLOCKED 申報）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s1-review-pack.txt`，1596 行，沒進 repo）的組成：
- 第 1 部分：`git diff 02b53d3`（起點）到工作目錄的整段 diff，HEAD = 8e63a18，含步驟 3 還沒 commit 的改動
- 第 2 部分：步驟 3（code-simplifier）自己改了什麼（`git diff HEAD`：`scripts/check-claude-md.sh` 一處註解，+3 −2 行；沒有未追蹤的新檔）
- 第 3 部分：`scripts/check-claude-md.sh`、`tests/test-gate.sh`、`docs/reviews/CLAUDE.md` 的整檔（帶行號）
- 第 4 部分：已跑過的驗證 V1–V8（macOS 與 ubuntu:24.04 的 `tests/test-gate.sh` 都是 rc=0、146 個 ✅；shellcheck；本機照 ci.yml 逐 step 跑 26 個 rc=0；四個變異各自紅在哪；拋棄式 repo 實跑 `dd.docfile=main.py`；rebase、換分支、reset 三種的 `git rev-list` 比對；同一段第二次先停）

其他被改到的文件（兩份 CLAUDE.md、CHANGELOG、README、架構文件、設計文件）沒有放整檔：步驟 3、4 依序跑，審查期間沒有人改工作目錄，派工 prompt 寫明那幾份直接讀工作目錄。

派工 prompt（逐字，審查者拿到的是一句「先讀這個檔再照做」加這個檔的路徑）：

> 你是 8 步開發迴圈步驟 4 的審查者 B。職責：找漏洞，每條附證據（檔案與那幾行的原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。
>
> Repo：/Volumes/T7/home/project/my_project/claude-dd（專案規則在根目錄與各層的 CLAUDE.md；本段相關的是 scripts/CLAUDE.md、tests/CLAUDE.md、docs/reviews/CLAUDE.md）。
>
> 審查範圍：`git diff 02b53d3` 到工作目錄（5 個 commit 加上步驟 3 還沒 commit 的一處註解改動）。這一段改的是 pre-commit gate `scripts/check-claude-md.sh` 的三處行為、它的情境測試 `tests/test-gate.sh`，以及說明這些行為的文件。
>
> 審查包：/private/tmp/claude-501/-Volumes-T7-home-project-my-project-claude-dd/f691d75a-d904-4c64-916c-d3b4d3714db8/scratchpad/s1-review-pack.txt
> （共 1596 行。用 Read 的 offset/limit 每次 300 行讀到最後一行：Read 一次讀太多會靜靜截斷、不報錯。）
> 組成：第 1 部分整段 diff；第 2 部分步驟 3（code-simplifier）自己改了什麼；第 3 部分 `scripts/check-claude-md.sh`、`tests/test-gate.sh`、`docs/reviews/CLAUDE.md` 的整檔（帶行號）；第 4 部分已經跑過的驗證（指令、預期、實際）。
> - 第 3 部分那三個檔一律讀審查包裡那一份。其他被改到的文件（scripts/CLAUDE.md、tests/CLAUDE.md、CHANGELOG.md、README.md、README.zh-TW.md、DD_PIPELINE_ARCHITECTURE.md、docs/designs/2026-11-15-audit-fixes-design.md）工作目錄就是被審的版本，審查期間沒有人會改，可以直接讀；沒被改到的檔照常讀。
> - 第 4 部分的驗證已確認，不要重跑整支測試、CI 或容器。要查證某一條具體懷疑時，可以在你自己的暫存目錄開拋棄式 git repo 跑 gate（`/Volumes/T7/home/project/my_project/claude-dd/scripts/check-claude-md.sh`）；不要改 repo 裡的任何檔、不要 commit、不要跑 `./install-dd-pipeline.sh`。
> - 只用手上的資料判斷；需要外部查證（上網、別的機器、別的 git 版本）的列出來交回。
>
> 這三處行為（事實，不是我的判斷）：
> 1. `git config --local dd.docfile <值>`：值命中 `\.(CODE_EXT)$` 時 gate 印「不可以是程式碼檔名」並 exit 1（檢查放在 `CODE_EXT` 定義之後）。
> 2. `--segment-base` 失敗時分四種訊息（起點檔不存在／起點不在目前分支歷史裡但有共同祖先／連共同祖先都沒有／起點檔內容不是 commit），四種都 exit 1、stdout 不印東西。
> 3. `--start-segment` 以「上一段沒有附 review 報告」擋下時，訊息從兩條路變三條路，多列 `docs/reviews/S<段落>-BLOCKED.md`（同一段第二次先停另建 `-BLOCKED-2.md`）；判定邏輯沒改。
>
> 你的方向：測試的鑑別力。逐則看 `tests/test-gate.sh` 新加的 ⑬⑭⑮ 與 ⑪ 的新斷言、新 helper（`not_said`、`stdout_empty`）：有沒有恆真的斷言、為了錯的理由而通過的情境、前一則的狀態洩到後一則、`set -e` 下會讓整支提早中止的裸指令、對照組其實沒有對照到。第 4 部分 V5 的變異結果是不是足以證明每個新行為都被釘住；有沒有哪個新分支完全沒有測試。
>
> 級別：Critical（會放行該擋的、擋下該放的、或資料／歷史被弄壞）／Important（行為或文件宣稱是錯的，照做會出錯）／Smells（不影響正確性）。
>
> 交回格式（直接用文字交回，不要寫報告檔）：
> 【發現】每條：編號｜級別｜一句話內容｜證據（檔案與原文，或指令與輸出）｜建議怎麼改
> 【Not reported】看過、判定不是問題的（每條一句理由）
> 【What I ran】跑過的指令與讀過的檔
> 【需要外部查證】

## 發現

審查者交回的原文（逐字）：

> Critical 0 / Important 1 / Smells 4 — 範圍是 git diff 02b53d3 到工作目錄，方向是測試的鑑別力
>
> 【發現】
> B1｜Important｜`tests/CLAUDE.md` 的 `test-gate.sh` 那一列，⑬⑭⑮ 的說明插在 ⑫ 的說明和「⚠️ 這一段有一個『同批 staged 蓋掉銷帳』的陷阱」之間。現在「這一段」緊接在 ⑮ 後面，讀起來像在講 ⑮，其實講的是 ⑫③（GEMINI.md 和 awk 的 DOC_RE）。照字面去 ⑮ 找這個陷阱或為它補測試都會白做，要改 ⑫ 的人又不知道這條警告是給他的｜證據：`grep -o '有牙的只有那兩則 \`said\`。⚠️ \*\*這一段有一個「同批 staged 蓋掉銷帳」的陷阱\*\*' tests/CLAUDE.md` 有命中。`git show 02b53d3:tests/CLAUDE.md` 裡同一句前面接的是「不碰 ⑩⑪ 收尾的狀態。⚠️ **這一段有一個「同批 staged」（也有命中）｜建議：把 ⑬⑭⑮ 那段移到陷阱那句之後，或把「這一段」改成「⑫ 這一段」。
>
> 【Smells】
> S1｜`--segment-base` 宣稱四種失敗「stdout 都不印東西」（CHANGELOG、scripts/CLAUDE.md、gate 第 257 行的註解），但 `stdout_empty` 只測了「有共同祖先」那一支。另外兩支是這次新寫的：「連共同祖先都沒有」（⑪）和「內容不是 commit」（⑭ 壞起點檔那則），都只有 expect、said、not_said。之後有人在這兩支多印一行 `echo "$base"`，不會有任何一則變紅｜證據：test-gate.sh 第 596 行是唯一一個 `stdout_empty`。V5 的 M2b 只變異了 fork 那一支｜建議：⑪ 第 447 行之後、⑭ 第 600 行之後各加一則 `stdout_empty`。
>
> S2｜「連共同祖先都沒有」那一支自己的第一行（gate 第 275 行「…不在目前分支的歷史裡，也找不到共同祖先」）沒有被釘住。⑪ 只斷言兩支共用的尾句（said "進度表"）。把第 275 行刪掉、或改印成「內容不是 commit」那句，⑪ 照樣綠｜證據：test-gate.sh 第 450–451 行只有 `said "進度表"`、`not_said "段落開始前先跑"`。第 279 行（「進度表」那句）是兩支共用的｜建議：⑪ 加 `said "也找不到共同祖先"`。在那個 OUT 裡只有這一支會印這句，`owed_dirs` 沒有跑。
>
> S3｜兩支共用的尾句第 280 行「這一段還沒做完時不要重跑 --start-segment」沒有被釘住。`said "不要重跑"` 只出現在 fork 那一支的 OUT 之後（第 593 行）。刪掉第 280 行不會有任何一則紅｜證據：⑪（第 450–451 行）和壞起點檔那則（第 601–603 行）都沒有 `said "不要重跑"`｜建議：兩處各補一則。同類的還有第 244 行「它只是申報、不是審查報告」，M3 把它一起拿掉，但沒有任何 said 對應它。
>
> S4｜scripts/CLAUDE.md 新增了繞過 ④，並說「④ 的是 ⑮ 的『S1-BLOCKED.md 已 commit：開下一段放行』」。但這則的說明不像 ①②③ 那樣以「繞過④」開頭，緊接著的「變紅時先分清是哪一種：繞過①③變紅 = …」也沒有講 ④。⑮ 那則變紅時，讀的人用標籤找不到它，也查不到該怎麼判｜證據：`grep -n '繞過④' tests/test-gate.sh scripts/CLAUDE.md` 沒有任何輸出｜建議：把那則 expect 的說明改成以「繞過④」開頭，判讀那句補上 ④。
>
> 【Not reported】
> - ⑬ 裡 `main.py` 的兩則 expect 有鑑別力。fixed 版擋下它們的唯一原因就是新檢查，M1 下兩則都變成 pass。commit c1 有新增的 a/main.py，不是因為 nothing to commit 才失敗。
> - ⑬ 的 `notes.sh` 那則 expect 在 M1 下會因為欠帳照樣 block，是為了錯的理由綠。但同一則的 said 會紅，針對 `.sh` 的單點變異下前面的 main.py 不會寫起點，它會變成 pass。不構成漏洞。
> - AGENTS.txt 那則對照真的只差設定值。前面幾則都被擋下、沒有寫入起點，起點檔一樣不存在。M1 下它跟著變紅是連鎖，scripts/CLAUDE.md 變異表已寫明。
> - ⑭ `said "$FORK"` 不是恆真的：FORK 是 s0，gate 只在 fork 訊息印它，起點 s1 的 sha 不一樣。M2a 下它會紅。
> - 新加的 `not_said "段落開始前先跑"`：新訊息裡都沒有這串字。owed_dirs 的「段落開始前重記起點」不會出現在 `--segment-base` 的 OUT 裡。字串不是 `-` 開頭，不會因為 grep 報錯而恆綠。
> - `stdout_empty` 在 `set -e` 下不會中止：命令替換放在 `[ -z … ]` 的參數裡，它的結束碼不會觸發 set -e。M2b 證明它有鑑別力。
> - ⑮ 那兩則 block 的原因是對的：a/CLAUDE.md 同批 commit，沒有欠帳，而且 `said "上一段沒有附 review 報告"` 也印證了。`S<段落>-BLOCKED.md` 不是 `S<段落>-BLOCKED-2.md` 的子字串，兩則 said 各自釘住第 242、243 行。b4 那則的確在測「只改既有的不算」，`--diff-filter=A` 改成 ACMR 時它會變成 pass。
> - 狀態洩漏：⑬⑭⑮ 各自開乾淨的 repo、各自重設 BASE_FILE，GIT_CONFIG_GLOBAL 和日期環境變數在前面已經 unset。
> - `OLD_BASE=$(cat …)`、`S1_BASE=$(cat …)` 這兩行裸跑，某個變異讓前一則 `--start-segment` 被擋時會讓整支 `set -e` 提早中止。但 rc 不是 0，V5 也有核對判定行數，不會變成假綠。既有的第 241、392 行也是同一個形狀。
> - V5 各變異紅的項目和 scripts/CLAUDE.md 第 154、169、219、220 行的變異表一一對得上（M2a 是 8 則，M2b 是 1 則）。
>
> 【What I ran】
> - Read prompt-b.txt：全文
> - Read s1-review-pack.txt：分 1–300、300–600、600–900、900–1250、1250–1597 讀完
> - `grep -o` tests/CLAUDE.md 那一句 → 有命中；`git show 02b53d3:tests/CLAUDE.md | grep -o` 舊版那一句 → 有命中；`grep -n '繞過④' tests/test-gate.sh scripts/CLAUDE.md` → 沒有輸出
>
> 【需要外部查證】
> 無

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **B1（Important，採納）**：屬實（照審查者的 grep 重跑，命中 1 筆）。`tests/CLAUDE.md` 那句改成「⑫ 有一個『同批 staged 蓋掉銷帳』的陷阱」。
- **S1（Smells，採納）**：屬實，原本只有一則 `stdout_empty`。⑪ 與 ⑭ 壞起點檔那則各加一則，「沒記過」那一支也加一則，現在四種各有一則。變異：共用尾段多印一行 → ⑪ 與壞起點檔那兩則紅；「沒記過」那一支多印一行 → 只有它那則紅。
- **S2（Smells，採納）**：屬實。⑪ 加 `said "也找不到共同祖先"`；變異（拿掉那一行）→ 只有這一則紅。
- **S3（Smells，採納）**：屬實。⑪ 與壞起點檔那則各加 `said "不要重跑"`（變異：拿掉共用尾段那一行 → 這兩則紅）；⑮ 加 `said "它只是申報"`（拿掉第 3 條路那四行的變異現在紅三則 `said`）。
- **S4（Smells，採納）**：屬實（`grep -n '繞過④'` 原本 0 筆）。⑮ 那則 expect 的說明改成以「繞過④」開頭，`scripts/CLAUDE.md` 的判讀句補上 ④。
- Not reported 裡「`notes.sh` 那則在 M1 下為了錯的理由綠」：審查者判定不構成漏洞，C 的 S4 把它列為 Smells。我照 C 的建議把那則移到 commit 之前，現在 M1 下它自己會紅（見 `S1-c.md`）。
- 其餘 Not reported：都同意，沒有動作。
