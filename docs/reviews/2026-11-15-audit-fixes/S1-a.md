# S1 審查 — A（gate 腳本本身的正確性）

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

> 你是 8 步開發迴圈步驟 4 的審查者 A。職責：找漏洞，每條附證據（檔案與那幾行的原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。
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
> 你的方向：gate 腳本本身的正確性。逐行看 `scripts/check-claude-md.sh` 這次改到的三處：有沒有哪種輸入會走錯分支、放行該擋的、或擋下該放的（例如 dd.docfile 的各種值、大小寫、起點檔的各種內容、HEAD 還沒有 commit、detached HEAD、worktree、bash 3.2 與 `set -e` 之下的行為、變數緊貼全形字、stdout／stderr 分流）。也看這次的改動有沒有動到沒打算動的既有路徑。
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

> Critical 0 / Important 0 / Smells 1 — 範圍 `git diff 02b53d3` 到工作目錄，只看 `scripts/check-claude-md.sh` 改到的三處（方向 A：gate 腳本本身對不對）
>
> 這三處沒有找到會放行該擋的、擋下該放的，或弄壞資料、歷史的地方。
>
> 【發現】
> S1｜Smells｜起點檔的內容是一個 tree 物件、但不是空樹時，`--segment-base` 印的是「不在目前分支的歷史裡，也找不到共同祖先」，不是「內容不是 commit」。原因是 `read_base` 對 `commit|tree` 都回 0，這種輸入就掉進第三種訊息，沒進第四種。印出的下一步兩支相同（改用進度表的起點、不要重跑），所以行為沒錯，只有描述不準。｜證據：審查包 check-claude-md.sh:83-84 `commit|tree) return 0 ;;`，以及 :264、:268、:275。實跑：`git rev-parse HEAD^{tree} > .git/dd-segment-base; --segment-base` → 印「…不在目前分支的歷史裡，也找不到共同祖先」，rc=1｜建議：可以不修。要修的話，在 `--segment-base` 這一支裡，`read_base` 成功之後再判一次 `[ "$base" != "$EMPTY_TREE" ] && [ "$(git cat-file -t "$base")" = tree ]`，成立就改走「內容不是 commit」那一句。
>
> 【Not reported】
> - dd.docfile 新檢查：拿它的樣式和 `code_dirs_of`、`CODE_RE` 比過，三處都是同一段 `\.($CODE_EXT)$`、都分大小寫。`main.PY` 不會被擋，但 `a/main.PY` 也不算程式碼，不會自己替自己銷帳，兩邊一致。`x.d.ts`、`.sh` 這類值會被擋。檢查放在 `case "$1"` 與 `SKIP_DOC_CHECK` 之前，所以 SKIP commit 也一樣 exit 1，這和「每次 commit 都 exit 1」的文件寫法一致。
> - dd.docfile 不合法時，`--segment-base` 會把錯誤訊息印到 stdout，和註解「四種都維持 exit 1、stdout 空」的意思不合。實跑 `2>/dev/null` 之後 stdout 印出錯誤句，rc=1。判定不是問題：唯一的呼叫寫法 `skills/dd-loop/SKILL.md:116` 是 `base=$(…) && [ -n "$base" ]`，會被 exit 1 擋下；而且原本 :32 的字元集錯誤本來就印在 stdout，這次只是照同一個做法多加一處。
> - 有共同祖先那一支說「目前分支上這一段的 commit 不會漏」：推過一遍成立。`fork` 的祖先都是 `base` 的祖先，所以 HEAD 上凡是從 `base` 走不到的 commit 都在 `fork..HEAD` 裡。如果 reset 到起點之前，`fork` 就等於 HEAD，範圍是空的，和 V7 的結果一致。
> - HEAD 還沒有 commit（`checkout --orphan`）而起點是 commit 時：實跑走到「找不到共同祖先」那一支，rc=1，stderr 沒有 shell 錯誤，訊息符合實際狀態。
> - 起點檔存在但是空的：`head` 讀到空字串，`cat-file` 失敗，走到「內容不是 commit」那一支，正確。
> - stdout、stderr 分流：新的訊息行都有 `>&2`；只有 :265 在成功時把 `$base` 印到 stdout。
> - 變數緊貼全形字：`${base}`、`${fork}`、`${BASE_FILE}`、`${DOC_FILE}」` 都加了大括號。`$0 --start-segment` 後面接的是空白，沒有這個問題。
> - 這支腳本沒有開 `set -e`。`if printf … | grep -q` 與 `if fork=$(…)` 都放在 `if` 條件裡，不會被提早中止。
> - 第 3 條路（BLOCKED）：只多了 `echo` 幾行，`reviews_missing` 的判定沒改。改既有的檔不算新增，所以同一段第二次先停要另建 `-2`，這和 `--diff-filter=A` 的行為一致。
> - worktree 與 detached HEAD：`BASE_FILE`、`HEAD` 的解析方式沒改，`git merge-base` 吃 detached HEAD 沒有問題。
> - 起點檔寫成 ref 名稱（例如 `main`）時，`read_base` 也會接受：這是改動前就有的行為，不在這次 diff 裡。
>
> 【What I ran】
> - Read prompt-a.txt → 派工內容
> - Read s1-review-pack.txt 第 1–900 行與第 1562–1597 行 → diff、gate 整檔、test-gate.sh 開頭、已跑過的驗證
> - `grep -n 'segment-base' skills/dd-loop/SKILL.md` → :116 `base=$(… --segment-base) && [ -n "$base" ]`
> - 在 scratchpad 開拋棄式 repo（/private/tmp/claude-501/-Volumes-T7-home-project-my-project-claude-dd/f691d75a-d904-4c64-916c-d3b4d3714db8/scratchpad/revA，跑完已刪）：
>   - `--start-segment` → rc=0
>   - `checkout --orphan` 後 `--segment-base` → rc=1，走「找不到共同祖先」那一支
>   - 起點檔寫入 tree sha 後 `--segment-base` → rc=1，印「不在目前分支的歷史裡，也找不到共同祖先」（S1 的證據）
>   - `dd.docfile=x.py` 後 `--segment-base 2>/dev/null` → stdout 印出錯誤句，rc=1
>
> 【需要外部查證】
> - 沒有。

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **S1（Smells，採納）**：屬實。`read_base` 的 `commit|tree) return 0` 讓不是空樹的 tree 走到 merge-base 那幾支。照審查者實跑的指令重現後修：`--segment-base` 那一支先單獨處理空樹，再用 `git cat-file -t` 要求是 commit 才走 merge-base，其餘走「內容不是 commit、也不是空樹」那一句。`tests/test-gate.sh` ⑭ 加一則（起點檔寫入 `HEAD^{tree}`）；變異（那個判斷改成 `true`）→ 只有這一則的 `said` 與 `not_said` 紅。與 C 的 S3 是同一項。
- **Not reported 第 2 條（`dd.docfile` 不合法時錯誤句印在 stdout）**：審查者判定不是問題，我同意行為不改（既有的字元集檢查本來就印在 stdout，改成 stderr 是另一個行為變更），但它跟我寫的「四種都維持 stdout 空」放在一起會被讀成沒有例外。gate 的註解與 `scripts/CLAUDE.md` 各補一句：那句話只講這四種，呼叫端要看 exit code。
- 其餘 Not reported：都同意，沒有動作。其中「起點檔寫成 ref 名稱也會被接受」是改動前就有的行為，不在這一段的範圍，沒有處理。
