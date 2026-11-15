# scripts/githooks/ — 本 repo 自用的 git hook

claude-dd 這個 repo 自己用的 pre-commit（dogfood）與它呼叫的大小檢查。**不部署**：不在 `install-dd-pipeline.sh` 的 `DD_SCRIPTS` 裡，
也不在 `scripts/*.sh` 那個 glob 內。clone 之後跑一次 `git config core.hooksPath scripts/githooks` 才會生效。

## 關鍵檔案

- `pre-commit` — 依序做兩件事：先跑 `claude-md-size.sh --staged`，非 0 就擋下；再 `exec` `scripts/check-claude-md.sh`（CLAUDE.md gate，說明在 `scripts/CLAUDE.md`）
- `claude-md-size.sh` — 根目錄 `CLAUDE.md` 的大小上限檢查，兩種跑法見下一節
- `claude-md-max-bytes` — 上限的數字（bytes）。`#` 開頭的行與空行不算，其餘要剛好一行整數、最多 12 位

## 根目錄 CLAUDE.md 的大小上限

2026-11-16（S7）加的。只管根目錄那一份 `CLAUDE.md`，量整個檔的 bytes。來由與當時量到的大小在
`docs/designs/2026-11-15-audit-fixes-design.md`「S7 根目錄 CLAUDE.md 大小上限」一節。

CI 那一半（`.github/workflows/ci.yml` 裡呼叫它的 step）在 S7-2 接上；下面寫「CI」的地方，在那之前還不成立。

| | `claude-md-size.sh --staged`（pre-commit 跑） | `claude-md-size.sh`（不帶參數，給 CI 跑） |
|---|---|---|
| 量哪一份 | index 裡的 `CLAUDE.md`（index 沒有就當 0） | 工作目錄的 `CLAUDE.md`（沒有這個檔就不通過） |
| 什麼時候取上限來比 | index 那一份比 `HEAD` 那一份大的時候；沒有變大就什麼都不印、exit 0 | 每次 |
| 不通過 | 變大、而且超過上限；或取不到上限 | 超過上限；或取不到上限；或工作目錄的上限檔不存在、內容不合法 |

- pre-commit 只擋讓它變大的 commit：已經超過上限時（上限被調低，或超過的那個 commit 是用 `--no-verify` 進來的），變小的 commit 過得去，再變大才擋。不帶參數那一種在降回上限以內之前每次都不通過
- pre-commit 不查上限檔本身：只改上限檔的 commit 它什麼都不印，改成不合法的內容也過得去。查它的是不帶參數那一種 —— 不管這次的上限取自哪裡，工作目錄那一份都要解析得出來（它會是下一版的基準），跟取到的上限不一樣時多印一行「工作目錄的上限檔寫 N，發下一版之後才生效」
- `git commit -a`、`git commit <路徑>` 時，hook 看到的 index 就是要 commit 的那一版（2026-11-16 拋棄式 repo 實跑：兩種讓它變大都被擋；變大的 CLAUDE.md 已經 `git add`、但指定路徑只 commit 別的檔時放行，CLAUDE.md 還留在 index）
- 從哪個目錄跑都量根目錄那一份（腳本開頭 `cd` 到 `git rev-parse --show-toplevel`）
- 擋下時印的做法在腳本的 `advice()`；exit code：通過 0、不通過 1、參數不認得或不在 git repo 裡 2

### 上限取自哪一版

每次取上限，都把出處印在那一行的括號裡。順序（腳本的 `resolve_limit()`）：

1. 最新的 `v*` tag（`git tag --list 'v*' --sort=-v:refname | head -1`，跟 `ci.yml`「CHANGELOG 已發布區塊不可改動」那一步同一個寫法）那一版有上限檔 → `取自 <tag>`
2. 沒有 `v*` tag，或那個 tag 沒有上限檔：
   - `--staged`：`HEAD` 那一版有 → `取自 HEAD：<原因>`；`HEAD` 也沒有、index 有 → `取自 index：<原因>`（加進上限檔的那個 commit 自己要過得去）
   - 不帶參數：工作目錄有 → `取自工作目錄：<原因>`
3. 都沒有 → 印「找不到上限檔」，不通過

`<原因>` 是 `<tag> 還沒有這個檔，發下一版之後改以 tag 為準` 或 `還沒有 v* tag`。

**調高上限**：先問使用者，再改 `claude-md-max-bytes`。走第 1 條時，改了要等發下一版才生效 —— 加字的 commit 自己把數字調高沒有用。

⚠️ **第 2 條擋不住的**（還沒有帶上限檔的 `v*` tag 時才走得到；寫這一段的 2026-11-16 就是：最新的 `v1.6.14` 沒有這個檔，
`git cat-file -e "v1.6.14:scripts/githooks/claude-md-max-bytes"` 回非 0）：

- pre-commit：先單獨 commit 把數字調高，下一個 commit 再加字。同一個 commit 一起做會被擋（讀的是 `HEAD` 那一版）
- 不帶參數那一種：工作目錄的數字改了就算數，所以 CI 擋不住同一次 push 裡的調高

兩種都會在歷史裡留下一個改上限檔的 commit。現在走的是哪一條，看它印的「取自 …」。

### 繞得過的路

- `git commit --no-verify`／`-n`：整支 hook 不跑，要等 push 時 CI 擋。Claude 端另有 `skills/gate-guard` 的 hook 在執行前 deny
- 沒設 `core.hooksPath` 的 clone：hook 不存在，要等 push 時 CI 擋
- 上一節第 2 條的那兩種

`SKIP_DOC_CHECK=1` **不會**跳過它：那個變數只有 gate 在讀，大小檢查排在 gate 前面。

### 取不到上限、上限檔不合法時一律不通過

- 不合法 = 去掉 `#` 開頭的行與空行之後不是剛好一行，或那一行不全是數字，或超過 12 位
- 12 位那一條的來由：放不進整數的數字，bash 的 `[ -gt ]` 會印 `integer expression expected`、回 2，`if` 把它當成「沒超過」而放行
  （`/bin/bash` 3.2.57 實測 `[ 100 -gt 123456789012345678901234567890 ]`）
- 最新 tag 那一版的上限檔不合法時，**不會**退回去讀 `HEAD`：讓 CLAUDE.md 變大的 commit 一律擋、不帶參數那一種一律不通過，
  要發一版帶合法上限檔的才解得開；只改別的檔的 commit 不受影響

## 改這三個檔之前

- hook 跑的是**工作目錄**那一份腳本。`claude-md-size.sh` 壞了的後果（2026-11-16 拋棄式 repo 實跑）：執行位元沒了（`Permission denied`）、
  或開頭就語法錯，**每一個** commit 都被擋，不只是動到 CLAUDE.md 的。把工作目錄那一份改好就恢復，不用 `--no-verify`。
  所以先在拋棄式 repo 跑過情境，真的 `pre-commit` 最後才改
- `git add` 新腳本之後看 `git ls-files -s scripts/githooks/`，腳本的模式要是 `100755`
- git 的 `<rev>:<path>` 寫成 `"${tag}:${LIMIT_FILE}"`，變數一律加大括號：緊貼冒號的 `$tag:` 在 zsh 會被當成修飾詞、冒號後面整段不見、不報錯
  （bash 不會；把指令貼到 Claude 的 Bash 工具裡試的時候才會中）。緊貼全形字的變數同理（`scripts/CLAUDE.md`「此層慣例」）
- 訊息裡的「取自 …」「找不到上限檔」「上限檔內容不合法」是情境在比對的字串，改字要一起改情境

## 情境與變異對照（2026-11-16）

情境 A–R 的內容在設計文件「S7」一節：拋棄式 repo 照這個 repo 的配置（`scripts/githooks/` 三個檔、`scripts/check-claude-md.sh`、`core.hooksPath`），
沒寫「直接跑」的都是真的 `git commit`、經過 `pre-commit`。原版用 `/bin/bash`（3.2.57）跑兩次，輸出逐位元組相同。

變異版的輸出跟原版逐則比，下表記「哪個變異 → 哪幾則不一樣」，不記數量。「連鎖」= 前面有一則該擋的放行了（或反過來），
之後 `HEAD` 的狀態跟原版不同，後面的情境跟著不一樣；它們不算那個變異自己的證據。

| 變異（改了哪一行） | 直接不一樣的情境 |
|---|---|
| `git tag --list … \| head -1` 拿掉 `--sort=-v:refname` | F 的「取自 v0.0.1」（沒排序時 `head -1` 拿到最舊的 `v0.0.0`，它沒有上限檔，改讀 `HEAD`）、G 的第二則（放行了）；H 起連鎖 |
| 同一行改成 `--sort=-refname`（字典序倒排） | I 的第二則（照 `v0.0.2` 的 300 擋下）；J 起連鎖 |
| 讀 tag 的那條分支改成 `if false` | F 的「取自 v0.0.1」、G 的第二則；H 起連鎖 |
| 讀 `HEAD` 的那條分支改成 `elif false` | C、D 的「取自 HEAD」（變成取自 index）、E 的第一則（放行了）；E 後兩則連鎖 |
| `[ "$new" -le "$old" ] && exit 0` 的 `-le` 改 `-eq` | K 的「350 → 340」（擋下）、L 的第一則（擋下）、O 的「縮到 100 並 commit」（多印一行）；K「340 → 345」、L 第二則、M、N 前兩則連鎖 |
| `--staged` 的大小改讀工作目錄 | A 的「第一個 commit 不帶 CLAUDE.md」（擋下），情境腳本接著取不到 `HEAD` 而中止。只在 L 那一節打開這個變異：L 的第一則（擋下）；只在 L 的第二則打開：L 的第二則（放行了） |
| `parse_limit()` 拿掉 `case` 那三行（整數檢查） | O 的「不是整數」「有兩行數字」（通過了）、P 的「CLAUDE.md 變大」「直接跑」（`[ -gt ]` 報錯） |
| `parse_limit()` 拿掉 12 位那一行 | O 的「30 位數」（通過了） |
| 找不到上限檔那一支的 `return 1` 改 `exit 0` | A 的三則「擋／不通過」；B 的第一則連鎖 |
| `resolve_limit staged \|\| exit 1` 改 `\|\| exit 0` | A 的兩則「擋」、P 的「CLAUDE.md 變大」；B 的第一則連鎖 |
| `resolve_limit worktree \|\| exit 1` 改 `\|\| exit 0` | A 的「直接跑」、P 的「直接跑」 |
| `--staged` 的 `-gt` 改 `-ge` | H 的「剛好 300」；H「301」、I 第二則連鎖 |
| 不帶參數的 `-gt` 改 `-ge` | H 的「直接跑：剛好 300」 |
| 工作目錄的上限檔不合法時不設 `rc=1` | O 的「不是整數」「有兩行數字」「30 位數」「沒有上限檔」 |
| 最後的 `exit $rc` 改 `exit 0` | D、K 的「直接跑」，O 的那四則 |
| `--staged` 超過上限時的 `exit 1` 改 `exit 0` | C 起每一則該擋的 commit（含連鎖） |
| 拿掉 `cd "$top"` | O 的「從子目錄直接跑」（量到的是 `scripts/CLAUDE.md`） |
| 拿掉「找不到 CLAUDE.md」那一段 | O 的「工作目錄沒有 CLAUDE.md」（印 ✅ 0 bytes、通過了） |
| `pre-commit` 拿掉呼叫大小檢查的那一行；或只拿掉它後面的 `\|\| exit 1` | A 起每一則大小的「擋」（含連鎖）；Q 一樣 |
| `pre-commit` 拿掉 `exec` gate 的那一行 | 只有 Q |

「只在 L 打開」的做法：變異版在 `git rev-parse --git-path m-on` 那個檔存在時才讀工作目錄，情境副本只在那一則前後 `touch`／`rm` 它；
情境副本配原版腳本跑出來的輸出要跟原版逐位元組相同，才算副本沒有動到別的東西。
