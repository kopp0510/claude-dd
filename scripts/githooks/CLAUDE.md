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

CI 那一半是 `.github/workflows/ci.yml` 的「根目錄 CLAUDE.md 大小上限」那一步（`lint` job）：先查有沒有任何 `v*` tag，沒有就不通過
（shallow clone 不帶 tag，腳本會退回去讀工作目錄的上限檔，上限就變成這次 push 自己寫的數字），再跑不帶參數的那一種。

| | `claude-md-size.sh --staged`（pre-commit 跑） | `claude-md-size.sh`（不帶參數，給 CI 跑） |
|---|---|---|
| 量哪一份 | index 裡的 `CLAUDE.md`（index 沒有就當 0） | 工作目錄的 `CLAUDE.md`（沒有這個檔就不通過） |
| 什麼時候取上限來比 | index 那一份比 `HEAD` 那一份大的時候；沒有變大就什麼都不印、exit 0 | 每次 |
| 不通過 | 變大的時候：超過上限，或取不到上限、取到的上限檔不合法 | 超過上限；或取不到上限、取到的上限檔不合法；或工作目錄的上限檔不存在、內容不合法 |

- pre-commit 只擋讓它變大的 commit：已經超過上限時（上限被調低，或超過的那個 commit 沒經過這支 hook —— 見下面「繞得過的路」），變小的 commit 過得去，再變大才擋。不帶參數那一種在降回上限以內之前每次都不通過
- pre-commit 不查上限檔本身：只改上限檔的 commit 它什麼都不印，改成不合法的內容也過得去。查它的是不帶參數那一種 —— 不管這次的上限取自哪裡，工作目錄那一份都要解析得出來（它會是下一版的基準），跟取到的上限不一樣時多印一行「工作目錄的上限檔寫 N，發下一版之後才生效」
- `git commit -a`、`git commit <路徑>` 時，hook 看到的 index 就是要 commit 的那一版（2026-11-16 拋棄式 repo 實跑：兩種讓它變大都被擋；變大的 CLAUDE.md 已經 `git add`、但指定路徑只 commit 別的檔時放行，CLAUDE.md 還留在 index）
- 從哪個目錄跑都量根目錄那一份（腳本開頭 `cd` 到 `git rev-parse --show-toplevel`）
- 擋下時印的做法在腳本的 `advice()`；exit code：通過 0、不通過 1、參數不認得或不在 git repo 裡 2

### 上限取自哪一版

每次取上限，都把出處印在那一行的括號裡。順序（腳本的 `resolve_limit()`）：

1. 最新的 `v*` tag（`git tag --list 'v*' --sort=-v:refname | head -1`，跟 `ci.yml`「CHANGELOG 已發布區塊不可改動」「dd-init 蓋章區塊改了就要跳 dd-loop-rev」兩步同一個寫法）那一版有上限檔 → `取自 <tag>`
2. 沒有 `v*` tag，或那個 tag 沒有上限檔：
   - `--staged`：`HEAD` 那一版有 → `取自 HEAD：<原因>`；`HEAD` 也沒有、index 有 → `取自 index：<原因>`（加進上限檔的那個 commit 自己要過得去）
   - 不帶參數：工作目錄有 → `取自工作目錄：<原因>`
3. 都沒有 → 印「找不到上限檔」，不通過

`<原因>` 是 `<tag> 還沒有這個檔，發下一版之後改以 tag 為準` 或 `還沒有 v* tag`。

「最新的 `v*` tag」= 本機所有 `v` 開頭的 tag 裡，照版本號排最大的那一個。腳本只認這個，不查它推上去了沒、是不是 `v<數字>.<數字>.<數字>` 的形狀、
在不在目前這條 branch 的歷史裡 —— 後果在下面「繞得過的路」。

**調高上限**：先問使用者，再改 `claude-md-max-bytes`。走第 1 條時，改了要等下一個 `v*` tag 才生效（發下一版時打的那個）—— 加字的 commit 自己把數字調高沒有用。

⚠️ **第 2 條擋不住的**（還沒有帶上限檔的 `v*` tag 時才走得到；寫這一段的 2026-11-16 就是：最新的 `v1.6.14` 沒有這個檔，
`git cat-file -e "v1.6.14:scripts/githooks/claude-md-max-bytes"` 回非 0）：

- pre-commit：先單獨 commit 把數字調高，下一個 commit 再加字。同一個 commit 一起做會被擋（讀的是 `HEAD` 那一版）
- 不帶參數那一種：工作目錄的數字改了就算數，所以 CI 擋不住同一次 push 裡的調高

兩種都會在歷史裡留下一個改上限檔的 commit。現在走的是哪一條，看它印的「取自 …」。

### 繞得過的路

下面說「等 CI 擋」的，指 `ci.yml` 的那一步：push 到 `main`、開 PR、或手動 `workflow_dispatch` 時才跑。push 到別的 branch 又沒開 PR 時，沒有任何檢查在看。
除了第一、二條，都是 2026-11-16 在拋棄式 repo（git 2.42.0）實跑過的。

- `git commit --no-verify`／`-n`：整支 hook 不跑，要等 CI 擋。Claude 端另有 `skills/gate-guard` 的 hook 在執行前 deny
- 沒設 `core.hooksPath` 的 clone：hook 不存在，要等 CI 擋
- 不經過 pre-commit 的 commit：`git cherry-pick`、`git merge --no-ff` 自動合併出來的那個 commit、`git rebase` 重放的 commit、`git revert`、`git am`（這幾種都讓 `HEAD` 的 CLAUDE.md 超過上限，大小檢查沒有跑到；`git merge --squash` 之後的 `git commit`、`git commit --amend` 有跑到、被擋下）。這是試過的幾種，不是完整清單。一樣要等 CI 擋
- 根目錄 `CLAUDE.md` 換成 symlink：`--staged` 量的是 index 裡那個 blob，symlink 的 blob 是連結目標的路徑字串（幾個 bytes），所以放行；不帶參數那一種的 `wc -c <` 會跟著連結量到目標的內容（連到 500 bytes 的檔、上限 100：commit 過了，直接跑不通過）。要等 CI 擋
- 本機打一個 `v*` tag：調高上限檔的 commit 進去之後，再打一個版本號更大的 `v*` tag（不必 push、不必真的發版），下一個加字的 commit 就照新數字放行（打 tag 前擋、印「取自 v1.0.0」；`git tag v1.0.1` 之後同一個改動放行、印「取自 v1.0.1」）。這個 tag 被 `git push --tags` 帶上去之後，CI 也照它算。
  腳本分不出「發版」與「打了一個 tag」，gate-guard 也不管 `git tag`；擋這條路的只有「調高之前先問使用者」這條規則，與每次印出來的「取自 …」
- `v` 開頭、但不是這條 branch 發版的 tag 也算：tag 打在別條 branch 上（不是 `HEAD` 的祖先）照樣被拿來當上限；`vendor-snap` 這種名字照版本號排會排在所有 `v<數字>…` 前面，`v1.0.0-rc1` 也排在 `v1.0.0` 前面。
  這個 repo 的 tag 只有 `v<x.y.z>` 與 `pre-prune-2026-08-04`（`git tag --list`）；要打別種 tag 就不要用 `v` 開頭 —— 上面第 1 條提到的 `ci.yml` 那兩步也拿同一個寫法當「最新發版」
- 上一節「第 2 條擋不住的」那兩種

`SKIP_DOC_CHECK=1` **不會**跳過它：那個變數只有 gate 在讀，大小檢查排在 gate 前面。

這張清單只有這一份：`ci.yml` 那一步上面的註解、`CHANGELOG.md` 講這個檢查的那一條、`DD_PIPELINE_ARCHITECTURE.md` CI 防線表那一列都只舉幾種並指到這裡，
加一條時不用去那三處各補一份（2026-11-16 四處各列各的：補了這裡、另外三處還是舊的兩種，審查才抓到）。

### 要取上限的時候取不到、或上限檔不合法：一律不通過

- 「要取上限的時候」：不帶參數那一種每次都取；`--staged` 只在 CLAUDE.md 變大時才取。沒變大的 commit（只改別的檔、或讓它變小）不取上限，上限檔被刪掉或改壞了也照樣放行
- 不合法 = 去掉 `#` 開頭的行與空行之後不是剛好一行，或那一行不全是數字，或超過 12 位
- 12 位那一條的來由：放不進整數的數字，bash 的 `[ -gt ]` 會印 `integer expression expected`、回 2，`if` 把它當成「沒超過」而放行
  （`/bin/bash` 3.2.57 實測 `[ 100 -gt 123456789012345678901234567890 ]`）
- 最新 tag 那一版的上限檔不合法時，**不會**退回去讀 `HEAD`：讓 CLAUDE.md 變大的 commit 一律擋、不帶參數那一種一律不通過，
  要發一版帶合法上限檔的才解得開；只改別的檔的 commit 不受影響

## 改這三個檔之前

- hook 跑的是**工作目錄**那一份腳本。`claude-md-size.sh` 壞了的後果（2026-11-16 拋棄式 repo 實跑）：執行位元沒了（`Permission denied`）、
  或開頭就語法錯，**每一個** commit 都被擋，不只是動到 CLAUDE.md 的。把工作目錄那一份改好就恢復，不用 `--no-verify`。
  所以改完先跑 `/bin/bash tests/test-gate.sh`（⑯ 在拋棄式 repo 裡跑這一層的 `pre-commit` 與 `claude-md-size.sh`；上限檔是測試自己寫的，repo 裡那一份它沒用到）再 commit；要改 `pre-commit` 時它最後才改
- 改 `claude-md-max-bytes` 之後直接跑一次 `scripts/githooks/claude-md-size.sh`（不帶參數）：pre-commit 不查上限檔本身、⑯ 也沒用到 repo 這一份，
  內容改壞了（多一個逗號、超過 12 位、說明行的 `#` 前面多了空白）commit 過得去、測試全綠，要等這一步或 CI 才紅
- `pre-commit` 裡兩行的順序有承重：gate 那行是 `exec`，排在它後面的指令不會跑，所以大小檢查在前。`/dd-init` Phase 3 對已經含 gate 的 hook 是看位置的
  （`commands/dd-init.md`「已含」那條：gate 呼叫不在 shebang 與註解之後，就搬到那個位置），照字面套在這支上會被判成要搬 —— 這是讀規則推出來的，沒有在這個 repo 實跑過 `/dd-init`。
  兩行對調的後果有實跑（2026-11-16，對調過的副本當 `tests/test-gate.sh` 的第三個參數）：⑯ 從 A 起該擋的都變成放行、測試 rc=1；本機 commit 的時候不會有任何訊息。
  這支 hook 是手改的，不要讓 `/dd-init` 動它
- `git add` 新腳本之後看 `git ls-files -s scripts/githooks/`，腳本的模式要是 `100755`
- git 的 `<rev>:<path>` 寫成 `"${tag}:${LIMIT_FILE}"`，變數一律加大括號：緊貼冒號的 `$tag:` 在 zsh 會被當成修飾詞、冒號後面整段不見、不報錯
  （bash 不會；把指令貼到 Claude 的 Bash 工具裡試的時候才會中）。緊貼全形字的變數同理（`scripts/CLAUDE.md`「此層慣例」）
- 腳本印的訊息有好幾句是 `tests/test-gate.sh` ⑯ 在比對的（`sed -n '/^# ⑯/,$p' tests/test-gate.sh | grep 'said '` 列得出來，`advice()` 裡的「先問使用者」也在內），改字要一起改測試

## 情境與變異對照（2026-11-16）

情境 A–R 在 `tests/test-gate.sh` 的 ⑯（CI 的 ubuntu 與 macOS `/bin/bash` 3.2 兩個 job 都跑這支測試）：拋棄式 repo 照這個 repo 的配置
（`scripts/githooks/` 放複製過去的 `pre-commit` 與 `claude-md-size.sh`、加上測試自己寫的上限檔，`scripts/check-claude-md.sh` 放 gate，`core.hooksPath` 指到 `scripts/githooks`），沒寫「直接跑」的都是真的 `git commit`、經過 `pre-commit`。
本機跑：`/bin/bash tests/test-gate.sh`。

改了這一層的腳本要做變異對照：複製一份、改壞一行，當成測試的第二個參數（大小檢查）或第三個參數（`pre-commit`），沒換的給空字串或不給 ——
`/bin/bash tests/test-gate.sh "" <改壞的 claude-md-size.sh>`、`/bin/bash tests/test-gate.sh "" "" <改壞的 pre-commit>`。repo 裡那一份不用動。

下表記「哪個變異 → ⑯ 的哪幾則變 ❌」，不記數量（2026-11-16 用 `/bin/bash` 3.2.57 跑的；每個變異跑的時候，⑯ 之前 gate 的那些情境都沒有變）。
「連鎖」= 前面有一則該擋的放行了（或反過來），之後 `HEAD` 的狀態跟原版不同，後面的情境跟著紅；它們不算那個變異自己的證據。
每個變異各自變紅的完整清單沒有收進 repo，要看就照上面的做法重跑那個變異。

| 變異（改了哪一行） | 直接變 ❌ 的情境 |
|---|---|
| `git tag --list … \| head -1` 拿掉 `--sort=-v:refname` | F（輸出沒有「取自 v0.0.1」：沒排序時照名稱的字典序，`head -1` 拿到排最前面的 `v0.0.0`，它沒有上限檔，改讀 `HEAD`）、G 的第二則（放行了）；H 之後還有紅的，不逐則分：有的是前面放行之後的連鎖，有的是那一則自己也要讀對 tag |
| 同一行改成 `--sort=-refname`（字典序倒排） | I 的第二則（照 `v0.0.2` 的 300 擋下）；J 之後還有紅的，不逐則分：字典序倒排時 `v0.0.2` 一直排第一，後面每一則要讀新 tag 的都讀錯 |
| 讀 tag 的那條分支改成 `if false` | F（輸出沒有「取自 v0.0.1」）、G 的第二則（放行了）；H 之後還有紅的，不逐則分（同第一列） |
| 讀 `HEAD` 的那條分支改成 `elif false` | C、D 的第一則（輸出沒有「取自 HEAD」，變成取自 index）、E 的第一則（放行了）；E 後兩則連鎖 |
| `[ "$new" -le "$old" ] && exit 0` 的 `-le` 改 `-eq` | K 的「350 → 340」（擋下）、L 的第一則（擋下）；K「340 → 345」、L 第二則、M、N 前兩則連鎖。O 的「縮到 100 並 commit」會多印一行，那一則沒有斷言在看輸出，不會紅 |
| `--staged` 的大小改讀工作目錄 | A 的「第一個 commit 不帶 CLAUDE.md」（擋下），測試接著印「第一個 commit 沒建起來，A 之後的情境沒有跑」就結束。只在 L 那一節打開這個變異：L 的第一則（擋下），第二則跟著紅；只在 L 的第二則打開：L 的第二則（放行了）；兩種都是 M、N 前兩則連鎖 |
| `parse_limit()` 拿掉 `case` 那三行（整數檢查） | O 的「不是整數」「有兩行數字」（通過了）、P 的「CLAUDE.md 變大」「直接跑」（`[ -gt ]` 報錯，測試判「輸出裡有 shell 錯誤」） |
| `parse_limit()` 拿掉 12 位那一行 | O 的「30 位數」（通過了） |
| 找不到上限檔那一支的 `return 1` 改 `exit 0` | A 的三則「擋／不通過」；B 的第一則連鎖 |
| `resolve_limit staged \|\| exit 1` 改 `\|\| exit 0` | A 的兩則「擋」、P 的「CLAUDE.md 變大」；B 的第一則連鎖 |
| `resolve_limit worktree \|\| exit 1` 改 `\|\| exit 0` | A 的「直接跑」、P 的「直接跑」 |
| `--staged` 的 `-gt` 改 `-ge` | H 的「剛好 300」（擋下）；I 第二則連鎖 |
| 不帶參數的 `-gt` 改 `-ge` | H 的「直接跑：剛好 300」 |
| 工作目錄的上限檔不合法時不設 `rc=1` | O 的「不是整數」「有兩行數字」「30 位數」「沒有上限檔」 |
| 最後的 `exit $rc` 改 `exit 0` | D、K 的「直接跑」，O 的那四則 |
| `--staged` 超過上限時的 `exit 1` 改 `exit 0` | C 起該擋的 commit（含連鎖）；P 的「CLAUDE.md 變大」除外，它在取上限那一步就擋下、走不到這一行 |
| 拿掉 `cd "$top"` | O 的「從子目錄直接跑」（量到的是 `scripts/CLAUDE.md`） |
| 拿掉「找不到 CLAUDE.md」那一段 | O 的「工作目錄沒有 CLAUDE.md」（印 ✅ 0 bytes、通過了；`wc` 讀不到檔的那一行錯誤也被測試判成 shell 錯誤） |
| `pre-commit` 拿掉呼叫大小檢查的那一行；或只拿掉它後面的 `\|\| exit 1` | A 起每一則大小的「擋」（含連鎖）；Q 照樣綠 |
| `pre-commit` 拿掉 `exec` gate 的那一行 | 只有 Q |

「只在 L 打開」的做法：變異版在 `git rev-parse --git-path m-on` 那個檔存在時才讀工作目錄；另做一份測試檔的副本，只在那一則前後 `touch`／`rm` 它
（副本不放在 `tests/` 底下時三個參數都要給 —— 預設值是照測試檔自己的位置推的）。
副本配原版腳本跑出來的輸出要跟正本逐位元組相同，才算副本沒有動到別的東西。

### ⑯ 抓不到的變異（2026-11-16 審查時在拋棄式副本實跑：三個都是 rc=0、沒有一則變 ❌）

- 不帶參數那一種改成讀 `HEAD` 那一版的上限檔（原本讀工作目錄那一份）：⑯ 每次直接跑的時候，工作目錄與 `HEAD` 的上限檔內容都一樣。
  所以「上限取自哪一版」第 2 條的「不帶參數：工作目錄有」與「第 2 條擋不住的」講不帶參數的那一條，沒有情境釘住
- `git tag --list 'v*'` 拿掉 `'v*'`：⑯ 裡沒有不是 `v` 開頭的 tag。真 repo 的 `pre-prune-2026-08-04` 照版本號倒排排在 `v…` 後面，拿掉了也選不到它；
  名字排在 `v` 後面的 tag（實跑：`wip-x`）才會被選到
- `top=$(git rev-parse --show-toplevel) || exit 2` 改成 `|| exit 0`：exit code 那一條的「不在 git repo 裡 2」沒有情境
