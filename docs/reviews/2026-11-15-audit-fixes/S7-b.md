# S7 審查 — B（測試）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S7（根目錄 CLAUDE.md 大小上限，pre-commit 與 CI 都擋）。

## 派工

`code-reviewer`，不帶 model 參數，與另外三個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s7/review/pack.txt`，1832 行，沒進 repo）的組成：
- 第 1 部分：`git diff a4d9185`（表上這段的起點到工作目錄；HEAD = 808cf87，工作目錄乾淨、沒有未追蹤的檔）
- 第 2 部分：步驟 3（code-simplifier）跑了，沒有改任何檔（主對話用 `cmp` 核對過）
- 第 3 部分：`scripts/githooks/claude-md-size.sh`、`scripts/githooks/pre-commit`、`scripts/githooks/claude-md-max-bytes` 整檔；`tests/test-gate.sh` 的檔頭到 helper 與 ⑯ 整節；
  `ci.yml` 的 ShellCheck 清單與新 step；`scripts/githooks/CLAUDE.md` 整檔；`tests/CLAUDE.md` 那一列新增的文字與「此層約束」新增的那一條（都帶行號或折行）
- 第 4 部分：已跑過的驗證 V1–V9（整份測試在 macOS `/bin/bash` 3.2.57 與 ubuntu:24.04 容器、真 repo 直接跑、測試層級的變異對照與變異清單、本機照 ci.yml 逐 step 跑、CI 新 step 的負面測試、不經過 pre-commit 的 commit 實測、hook 壞掉的後果、步驟 3 的結果）

派工 prompt（逐字；prompt 裡的暫存目錄絕對路徑在這裡寫成 `<scratchpad>`，審查者拿到的是一句「先用 Read 讀這個檔，再照它寫的做」加這個檔的路徑）：

> 你是程式碼審查者。職責：找漏洞、每條附證據；沒證據的不算。不寫優點、不客套。
>
> repo：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。
> 審查範圍：`git diff a4d9185`（到工作目錄；8 步開發迴圈 S7 段落，HEAD = 808cf87，6 個 commit：2c3a277、7cc3289、12be2fd、694d06c、917f4df、808cf87；工作目錄乾淨、沒有未追蹤的檔）。這一段做的事：
> 根目錄 `CLAUDE.md` 加大小上限。新腳本 `scripts/githooks/claude-md-size.sh`（本 repo 自用、不部署）有兩種跑法：帶 `--staged` 由 `scripts/githooks/pre-commit` 在每次 commit 時跑（index 那一版比 `HEAD` 那一版大、而且超過上限才擋）；不帶參數由 CI 的新 step 跑（工作目錄那一份超過上限就不通過）。
> 上限寫在 `scripts/githooks/claude-md-max-bytes`（48000），取的是「最新 `v*` tag 那一版」的數字；那個 tag 沒有這個檔時，`--staged` 依序讀 `HEAD`、index，不帶參數讀工作目錄。現在最新的 tag `v1.6.14` 沒有這個檔。
> `tests/test-gate.sh` 檔尾加了 ⑯（情境 A–R，在拋棄式 repo 裡經過真的 pre-commit）；`.github/workflows/ci.yml` 加一個 step、ShellCheck 清單加一行；
> `scripts/githooks/CLAUDE.md`（新）、`scripts/CLAUDE.md`、`tests/CLAUDE.md`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md`、`docs/designs/2026-11-15-audit-fixes-design.md`（S7 一節與進度表）跟著改；根目錄 `CLAUDE.md` 只多一句進度表指路（段落標 DONE 的 commit 會刪掉）。
>
> 審查包（先讀它）：<scratchpad>/s7/review/pack.txt
> - 用 Read 的 `offset`/`limit` 每次 300 行，讀到最後一行（一次讀太多會靜靜截斷、不報錯）。共 1832 行。
> - 第 1 部分是整段 diff；第 2 部分是步驟 3（code-simplifier）的結果（它沒有改任何檔）；第 3 部分是被改到的程式碼與 `scripts/githooks/CLAUDE.md` 在派工當下的內容（帶行號），另有 `tests/CLAUDE.md` 那一列新增的文字（那一行在 diff 裡太長，Read 會截斷）；第 4 部分是已經跑過的驗證與預期值。
> - 被改到的檔以審查包第 3 部分為準；沒放進審查包的部分與其他檔直接讀工作目錄（步驟 4 期間沒有人改工作目錄）。
> - 第 4 部分的驗證已經確認過，不要重跑整份 `tests/test-gate.sh`、`tests/test-install.sh`，不要跑 docker。要驗一個想法，在拋棄式目錄裡做小實驗。
>
> 規則：
> - 只用手上的資料（讀檔、grep、git 紀錄、在拋棄式目錄裡的小實驗）判斷。需要上網、需要動到真實 `~/.claude`、或需要改這個 repo 的 git 狀態才查得到的，列在「需要外部查證」交回。
> - 不要改 repo 裡的任何檔；不要在這個 repo 裡 commit、打 tag、切分支、改 git 設定；不要跑 `./install-dd-pipeline.sh`。小實驗放在 <scratchpad>/s7/review/rc7-b/ 底下（拋棄式 repo 自己 `git init`，要用腳本就複製過去）。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 文件已經寫明的限制（`scripts/githooks/CLAUDE.md`「第 2 條擋不住的」「繞得過的路」兩段）不用再列成發現；但那兩段寫的內容不對、不全、或跟程式對不上，要列。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：測試。`tests/test-gate.sh` 的檔頭、參數處理與 ⑯。每一則斷言成立的時候到底證明了什麼：有沒有恆真的、為了別的理由而通過的、靠前一則留下的狀態才成立的；`said`／`not_said` 的字串是不是只有要測的那條分支會印；`set -e` 之下哪幾行是裸跑的、變異版讓它回非 0 時會怎樣；ubuntu（GNU 工具、git 2.43）與 macOS 的差異；新加的第二、三個參數對 ⑯ 之前原有的情境有沒有影響。`scripts/githooks/CLAUDE.md`「情境與變異對照」那張表與審查包 V4 的實測清單逐列對一次。另外自己想 2–3 個表上沒有的變異（把腳本改壞一行），在拋棄式副本上實跑 `/bin/bash tests/test-gate.sh "" <改壞的副本>`（這個可以跑，一次大約 20 秒），看 ⑯ 有沒有哪一則變 ❌。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體輸入 → 錯的輸出）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

審查者交回的原文（逐字；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 1 / Smells 2 — 範圍：`git diff a4d9185`（HEAD 808cf87），方向是測試：`tests/test-gate.sh` 的檔頭、參數與 ⑯，加上 `scripts/githooks/CLAUDE.md` 的對照表與「繞得過的路」
>
> 【發現】
> 1｜Important｜「繞得過的路」與「第 2 條擋不住的」兩段都沒列本機自己打 `v*` tag 這條路。上限取的是本機最新的 `v*` tag，所以打一個 tag 就等於「發下一版」。
> - 證據：`scripts/githooks/claude-md-size.sh:45` 原文 `tag=$(git tag --list 'v*' --sort=-v:refname | head -1)`，接著 `:51` 原文 `if [ -n "$tag" ] && git cat-file -e "${tag}:${LIMIT_FILE}" 2>/dev/null; then`，讀的是本機所有 tag。`scripts/githooks/CLAUDE.md:44` 原文「走第 1 條時，改了要等發下一版才生效 —— 加字的 commit 自己把數字調高沒有用」。這一條是讀碼推論，沒有實跑。
> - 失敗情境：
>   1. 有帶上限檔的 tag 之後，先單獨 commit 上限檔改成 99999。這個 commit 只動上限檔，`:86` 直接 exit 0 放行。
>   2. 接著 `git tag v1.6.99`（只打在本機）。
>   3. 下一個 commit 把 CLAUDE.md 加到 60000 → 印「取自 v1.6.99」、放行。
>   4. 之後用 `git push --tags` 推上去（使用者的 push 指令含 `--tags`）時，CI 的基準也變成這個 tag。
> - 建議：在「繞得過的路」補這一條，寫明 tag 不必是真的發版。也可以補一則特性測試釘住這個行為。
>
> 2｜Smells｜⑯ 抓不到三個變異。我在拋棄式副本上實跑，三個都是 rc=0、0 ❌、⑯ 之前的 151 行不變。
> - 證據與各自的失敗情境：
>   - ①`wthead`：不帶參數那一種原本讀工作目錄的上限檔，改成讀 `HEAD` 的（`raw=$(git show "HEAD:${LIMIT_FILE}")`）。⑯ 每一則直接跑的時候，工作目錄與 `HEAD` 的上限檔都一樣，所以 `scripts/githooks/CLAUDE.md:39`、`:50`「工作目錄的數字改了就算數」沒有特性測試，只有 E 有替 pre-commit 那個缺口寫特性測試。在 CI 裡 checkout 出來的工作目錄就是 `HEAD`，所以實際行為不會壞，只是這兩句文件過期時不會變紅。
>   - ②`anytag`：拿掉 `'v*'` 這個 pattern。⑯ 沒有任何不是 `v` 開頭的 tag，真 repo 卻有 `pre-prune-2026-08-04`。這個 tag 現在因為 `p` 排在 `v` 前面才沒被選到；換成 `wip-x` 這類排在 `v` 後面的名字就會被選中。
>   - ③`topexit0`：`top=$(git rev-parse --show-toplevel) || exit 2` 改成 `|| exit 0`。`scripts/githooks/CLAUDE.md:30` 寫的「不在 git repo 裡 2」沒有測試。
> - 建議：補一則「工作目錄的上限檔與 `HEAD` 不同時直接跑」，加一個非 `v*`、名字排在 `v` 後面的 tag，再補一則在 repo 外跑、斷言 exit 2。
>
> 3｜Smells｜「不排序拿到的是最舊的 tag」這句講錯了機制。`git tag --list` 不給 `--sort` 時照名稱的字典序排；⑯ 裡 `v0.0.0` 剛好既是字典序第一、也是最舊的，只是巧合。
> - 證據：`claude-md-size.sh:44` 原文「不排序拿到的是最舊的」；`scripts/githooks/CLAUDE.md:96` 原文「沒排序時 `head -1` 拿到最舊的 `v0.0.0`」。實跑：先打 `v1.9.0`、再打 `v1.10.0`，`git tag --list 'v*' | head -1` 印 `v1.10.0`，是最新的那一個。
> - 失敗情境：照註解推論「拿掉 sort 一定退回最舊版」的人會判錯。真 repo 有 `v1.6.x` 與將來的 `v1.10.x` 時，結果剛好相反。
> - 建議：改成「不排序時照字典序，拿到的是字典序第一個」。
>
> 【Not reported】
> - 裸跑的行（`set -e`）：`:703`、`:726`、`:736–737`、`:749`、`:778`、`:845`、`:861`、`:868` 我逐一推過已知變異會留下的狀態（例如 `notag` 讓 j1 把上限檔的刪除 commit 進去、之後 `git reset` 再 `git add` 加回來）。沒有一行會讓 `set -e` 靜靜中止；唯一會中止的地方已改成 `:706` 先印 ❌ 再結束。
> - `said`／`not_said` 的字串：「gate：commit 已擋下」只有 gate 會印（`scripts/check-claude-md.sh:336`）；大小檢查印的是「大小上限：commit 已擋下」，不會誤中。「不存在或內容不合法」只有 `:117` 印。`not_said "發下一版之後才生效"` 與 advice 的「發下一版才生效」是不同字串。沒找到恆真的或靠錯的理由通過的斷言。
> - 新的第二、三個參數不影響 ⑯ 之前的情境：我跑的四次前 151 行都與原版 cmp 相同。另外第一個參數（gate）現在也會複製進 ⑯：用 gate 變異跑時 ⑯ 會多紅幾則（至少 Q）。`scripts/CLAUDE.md` 的 gate 變異紀錄都帶日期，算歷史快照，不列。
> - `scripts/githooks/CLAUDE.md` 變異表 20 列，與審查包 V4 的 23 個變異逐一對過，每一列直接紅的與連鎖的情境都對得上。`wtsize` 那一列的「第一個 commit 沒建起來」與 V4 的註記一致。
> - `noarith`（拿掉 `$(( ))`）：在 macOS 上因 `wc` 輸出前面有空白、6 則 `said` 變紅；ubuntu 的 GNU `wc` 沒有空白，推測那邊會全綠。bash32 job 跑得到，所以不列。
> - 執行位元：`:690` 對複製的檔 `chmod +x`，所以 repo 那一份丟了執行位元時 ⑯ 抓不到。但那個 commit 本身會被 hook 擋下，CI 的 step 直接執行腳本也會失敗，不列。
> - H 的「301：擋」沒有 `said`：沒想到一個會讓它因為錯的理由被擋、其他斷言卻都不變的變異，不列。
> - ubuntu 與 macOS 的差異：`head -c`、`tr`、`sh -c`、`--sort=-v:refname` 在兩邊都可用；`git commit <路徑>` 時 hook 看到的 index 已由 N 在兩邊實跑過（V2）。
> - `--staged` 多帶參數（例如 `--staged x`）沒有測試：屬瑣碎的白名單，不列。
>
> 【What I ran】
> - 讀審查包 pack.txt 第 1–1832 行（分 7 段）、prompt-b.txt。
> - `grep -n 'commit 已擋下' scripts/check-claude-md.sh` → `:336`；`grep -n 'test-gate.sh' scripts/CLAUDE.md` → gate 變異的用法；`git tag --list | grep -v '^v'` → `pre-prune-2026-08-04`；`git config --get tag.sort` → 沒設。
> - `grep -nE '^# [A-R](、[A-R])? ' tests/test-gate.sh` → A–R 18 組標題，沒有多抓。
> - 在 rc7-b/ 用 python 產生 4 個變異，舊字串各出現一次，`diff` 確認已生效；`/bin/bash tests/test-gate.sh` 原版 rc=0；用 `"" <變異>` 跑：wthead rc=0 0❌、anytag rc=0 0❌、topexit0 rc=0 0❌、noarith rc=1 6❌；四次的前 151 行都與原版 cmp 相同。
> - 在 rc7-b/tagsort 拋棄式 repo：先打 `v1.9.0`、再打 `v1.10.0` → 不排序與 `--sort=-v:refname` 的 `head -1` 都是 `v1.10.0`。
>
> 【需要外部查證】
> 無

## 處置

- **1（Important，本機打一個 `v*` tag 這條路沒列）**：採納，級別沿用。與 `S7-a.md` 的 1 是同一件事；它註明是讀碼推論、沒有實跑，實跑的證據在 `S7-a.md` 的處置。改了什麼也寫在那裡。
  它建議「也可以補一則特性測試釘住這個行為」：⑯ 的 F、G、H 已經釘住「打了新 tag 之後照新上限」（讀 tag 的分支改成 `if false` 時這幾則會紅）；
  「tag 在別條 branch 上也算」「不是版本號的 `v` 開頭 tag 也算」沒有情境。補情境是測試清單以外的測試，併進下面第 2 條問使用者的那一題。
- **2（Smells，⑯ 抓不到三個變異）**：屬實。自己另做三個變異檔重跑：`wthead`、`anytag`、`topexit0` 都是 rc=0、沒有任何 ❌、⑯ 之前的 151 行與原版相同（同一批跑的原版也是 rc=0）。
  補情境是測試清單以外的測試，照進度表規則要先問使用者。問之前先把三個缺口記在 `scripts/githooks/CLAUDE.md` 檔尾「⑯ 抓不到的變異」；
  進度表 S7 驗收欄原本寫「變異對照每個變異都…」，改成講明是對照表上的變異。問的結果與之後做了什麼記在 `S7-judge.md` 的「處置」。
- **3（Smells，「不排序拿到最舊的 tag」講錯機制）**：採納。與 `S7-c.md` 的 4 是同一件事。自己實跑（拋棄式 repo，依序打 `v2.0.0`、`v1.9.0`、`v1.10.0`、`v1.0.0`）：不排序的清單是 `v1.0.0 v1.10.0 v1.9.0 v2.0.0`，`head -1` 是最後才打的 `v1.0.0`。
  腳本那行註解改成「不排序是照名稱的字典序由小到大，head -1 拿到的是字典序最前面的（不是最新的）」；變異表第一列改成「沒排序時照名稱的字典序，`head -1` 拿到排最前面的 `v0.0.0`」。
- **Not reported 的「第一個參數（gate）現在也會複製進 ⑯」**：它沒有實跑、也沒有列成發現；這是這次 diff 造成的，所以我跑了。
  「印了擋下卻回 0」的 gate 變異當第一個參數：⑯ 只有 Q 變 ❌，其餘 ⑯ 的情境都綠。`tests/CLAUDE.md` 的 `test-gate.sh` 那一列補一句「做 gate 的變異對照時 ⑯ 要一起看」。
  （我第一次用的是開頭直接 `exit 0` 的 gate：⑯ 的 ❌ 是 0 —— 因為測試在 ⑯ 之前就結束了，輸出裡一行 ⑯ 都沒有。這個看錯的經過記在 `S7-judge.md`「這一段自己犯的錯」。）
- Not reported 的 `noarith`（拿掉 `$(( ))` 在 macOS 上 6 則變紅、它推測 ubuntu 會全綠）：沒有在 ubuntu 上查；那一行的註解已經寫明是為了 macOS 的 `wc`，不處理。
