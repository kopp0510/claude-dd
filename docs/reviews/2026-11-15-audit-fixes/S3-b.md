# S3 審查 — B（T11 測試）

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
> - **不要跑 `./install-dd-pipeline.sh`（任何參數）除非把 `HOME` 換成你自己建的拋棄式目錄**；不要在 zsh 裡 `source` 它（要取函式用 `bash -c 'source ./install-dd-pipeline.sh && <函式>'`，而且一樣先換 `HOME`）。不要改 repo 裡的任何檔、不要 commit。小實驗放在 <scratchpad>/rc3-b/ 底下。
> - 每條發現附證據：`路徑:行號` 加上那一行的原文，或指令與輸出。行號以你實際讀到的為準。
> - 級別：Critical（照做會壞、會錯，而且不會報錯）／Important（常走的路上會出錯或誤導）／Smells（不影響正確性）。
> - 被你判成「既有問題、不是這次 diff 引入」的，也要寫進 Not reported 並說明為什麼。
>
> 你的方向：測試。`tests/test-install.sh` 的 T11：每一個斷言，在它該抓的錯真的發生時會不會紅（有沒有空通過、有沒有只證明「有印出一行」）；`t11_line` 的 awk 夾段落的寫法在實際輸出上抓到的是不是它以為的那一行；`t11_snap` 的前後比對抓得到哪些寫入、抓不到哪些；對照組（剛裝好就跑 `--check`）有沒有鑑別力；`TEST_ONLY` 白名單與檔頭說明有沒有漏改；T11 在 ubuntu（bash 5、GNU 工具）與 macOS（bash 3.2、BSD 工具）會不會有一邊行為不同；跟設計文件 `docs/designs/2026-11-15-audit-fixes-design.md` 的 S3-1 與「測試清單」對不對得上（清單以外多加的斷言也列出來）；`tests/CLAUDE.md` 記的變異對照與審查包第 4 部分的 V4 逐條對不對得上。
>
> 交回格式（照這些標題；直接用文字交回，不要寫報告檔）：
> 第 1 行：Critical N / Important N / Smells N — 範圍一句話
> 【發現】每條：編號｜級別｜內容｜證據｜失敗情境（具體輸入 → 錯的輸出）｜建議
> 【Not reported】看過、判定沒問題或不列的，各一句理由
> 【What I ran】讀了哪些檔的哪幾行、跑了哪些指令與結果
> 【需要外部查證】沒有就寫「無」

## 發現

審查者交回的原文（逐字；暫存目錄的絕對路徑寫成 `<scratchpad>`）：

> Critical 0 / Important 2 / Smells 2 — `git diff 0dc3b53 HEAD`（S3：64aa70b、2276c3c），只看測試方向：T11、`tests/CLAUDE.md` 的變異紀錄，以及它們跟設計文件對不對得上
>
> 【發現】
> 1｜Important｜T11 沒有釘住 `diff -r`。把 check 端的 `diff -rq` 改成 `diff -q`（不遞迴），T11 照樣全綠。原因是 T11 只改了 skill 第一層的 `SKILL.md`。這樣一來，設計文件寫的「比法跟安裝本身一樣」沒有任何測試在守。｜證據：`tests/test-install.sh:761` `printf '\n部署版多出來的一行\n' >> "$T11_HOME/.claude/skills/dd-loop/SKILL.md"`。我在拋棄式副本 rc3-b/B 把 `install-dd-pipeline.sh:507` 改成 `! diff -q "$source"`，跑 `TEST_ONLY=T11 /bin/bash tests/test-install.sh` 得到 rc=0、`✅ T11 …`（12 個 ✅）。｜失敗情境：在沙盒 HOME 改 `skills/tech-diagram-gif/references/` 底下第一個檔，再跑 `--check`。repo 原版印「tech-diagram-gif: 已安裝（與 repo 不同…）」加「與 repo 不同：1」；`-q` 變異版印「tech-diagram-gif: ✅ 已安裝」，rc 都是 0。有子目錄的 skill：gate-guard、self-improving-agent、tech-diagram-gif（`ls -d skills/*/*/`）。｜建議：T11 另外改一個子目錄裡的檔（例如 `tech-diagram-gif/references/*`），並斷言那一行有「與 repo 不同」；`tests/CLAUDE.md` 的變異表補上這一列。
>
> 2｜Important｜`tests/CLAUDE.md` 的 T11 變異對照插進了 T2 那段說明的中間。結果原本講 T2 的那句「沒列的照樣可能不一致 —— 審查時補的兩類就是第一版沒想到的；jq 與 python3 對大整數、NaN 的寫回格式沒比過」現在接在 T11 的段落後面，讀起來像在講 T11。｜證據：`tests/CLAUDE.md:96` 是 T2 的「`acw` 已知沒對齊、也沒列的…」，`:97–102` 是新插入的 T11 變異對照，`:103` 是「沒列的照樣可能不一致 —— 審查時補的兩類…jq 與 python3…」（`sed -n 75,104p tests/CLAUDE.md`）。｜失敗情境：讀者讀完 T11 的變異表會以為 T11 還有沒比過的 jq／python3 類別；只讀 T2 的人則讀不到這條限制（它被隔在 T11 段落後面）。｜建議：把 T11 那段搬到 `:103–104` 之後，或另起一條。
>
> 3｜Smells｜`tests/CLAUDE.md` 記的 m1、m2 變異寫法，跟實際跑過的不一樣。｜證據：`tests/CLAUDE.md:99` 寫「skill 那段的 `diff -rq` 拿掉 → …；agent 那段的 `cmp -s` 拿掉 → …」；審查包第 4 部分 V4 寫「m1 skill 那段的條件改成 if false」「m2 agent 那段的條件改成 if false」。｜失敗情境：照字面重做「拿掉 `diff -rq …`」，`:507` 會變成 `if [ -d "$source" ] && ; then`，那是語法錯誤，整支腳本跑不起來，會紅在 T11 之前的原有檢查，不會紅在紀錄寫的 T11 斷言。違反 §3.9「記哪個變異 → 哪幾個情境變紅」。｜建議：改寫成「條件改成 `if false`」。
>
> 4｜Smells｜`t11_snap` 只用 `find . -type f` 對一般檔算 cksum。`--check` 如果新建空目錄或 symlink、或刪掉空目錄，它都抓不到；而且只比對 stale 那一次 `--check`，clean 與 fixed 那兩次沒有前後快照。｜證據：`tests/test-install.sh:743` `t11_snap() { (cd "$T11_HOME" && find . -type f | … cksum "$f"; done); }`；`:763–768` 只包住 stale 那一次。｜失敗情境：在報不同的那一支加 `mkdir -p "$SKILLS_DIR/.stale"`，`before.txt` 與 `after.txt` 會相同，「它不該寫任何檔」那條照綠（這是讀程式碼判的，沒實跑）。原有的 `--check` 不寫入檢查是空 HOME，進不到這一支。｜建議：快照改成 `find . \( -type f -o -type d -o -type l \)`，只對一般檔算 cksum，其餘只記路徑與型別。
>
> 【Not reported】
> - `t11_line` 的 awk 抓的是對的那一行：段落標題是 `print_step` 印的「步驟 2/7：檢查內建 Skills」「步驟 3/7：檢查內建 Agents」（`install-dd-pipeline.sh:132,489,691`），整支腳本只有這兩處含「檢查內建 」（grep）。Agents 段的 `on` 會一路延到 MCP、plugin 段，但遇到第一個符合的就 `exit`，agent 那幾行排在前面；`" " name ": "` 的寫法不會被前綴相同的名字誤中。
> - 對照組有鑑別力：我做了一個「每個已安裝 skill 都算 stale」的變異，紅在 clean 對照（「與 repo 不同：14」）。V4 的 m3 也是紅在這裡。
> - 「與 repo 不同：1」用 `grep -cF` 會連「：14」一起算進去，不過唯一會讓它空通過的變異（只有 stale 時才算錯數）很做作；計數錯成 14 的情況會先被 clean 對照擋下（實跑）。
> - `TEST_ONLY` 白名單、錯誤訊息、檔頭第 7 行、第 96–97 行的註解都加了 T11；`git grep 'T2–T10'` 是 0 筆。
> - 跨平台：awk 只用 `index`，mawk、BWK、gawk 都照位元組比；`cksum` 輸出只在同一台機器上比；`grep -cF … || true` 在 `set -e` 下安全。ubuntu 端由審查包第 4 部分的 V3 涵蓋，我沒有重跑。
> - 設計文件 S3-1 的驗證條件（那兩行含「與 repo 不同」、沒改的 skill 不含、檔案清單與雜湊相同、rc=0）都有對應的斷言。清單以外多出來的斷言（第 39 行規定「想加清單以外的測試，先問使用者」）都屬於同一組 T11 的加強，我不列成違規：clean 對照、clean 的「已安裝」、同名 `code-simplifier` skill、`plan-review`、`code-reviewer`、兩行「與 repo 不同：1」計數、shell 錯誤、UTF-8、重跑安裝後不再報。
> - `tests/CLAUDE.md` 的其他變異紀錄（m3、m6、m4b、m7、m4／m5 紅在 T11 之前）都跟 V4 對得上；「固定版 12 個 ✅」我在 B.log 數到 12（B 是遞迴差異之外與固定版相同的副本）。
> - 我沒有發現這次 diff 帶進來的既有問題。
>
> 【What I ran】
> - Read 派工檔；Read 審查包 1–300、300–627 行（全部）
> - `sed -n 20,93p tests/test-install.sh` → 原有的 `--check` 不寫入檢查用的是空 HOME
> - `grep -n 'S3\|T11\|測試清單' docs/designs/2026-11-15-audit-fixes-design.md`，`sed -n 143,148p` → S3-1 的驗證條件
> - `git grep -n 'T2–T10\|T2-T10'` → 0 筆；`grep -n '檢查內建' install-dd-pipeline.sh` → 487、489、689、691；`grep -n 'print_step()' -A4` → 印「步驟 $1：$2」
> - `ls -d skills/*/*/` → 列出有子目錄的 skill
> - 在 rc3-b 用 rsync 做兩份副本（不含 .git），各跑 `TEST_ONLY=T11 /bin/bash tests/test-install.sh`：A（每個 skill 都計 stale）→ rc=1，❌ 在 clean 對照；B（`diff -q`）→ rc=0，✅ T11
> - 沙盒 HOME 各裝一次 repo 原版與 B 副本，改 `tech-diagram-gif/references/` 第一個檔再跑 `--check`：原版報不同（計數 1），B 印「✅ 已安裝」，rc 都是 0
> - `grep -c '^✅' B.log` → 12；`sed -n 75,104p tests/CLAUDE.md` → 確認插入位置
>
> 【需要外部查證】無

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實，自己重跑了這個變異（`diff -rq` 改 `diff -q`）：改 T11 之前照樣全綠。
  T11 加改一個只動子目錄的 skill（`gate-guard/hooks/hooks.json`），那一行要有「與 repo 不同」；改完後同一個變異紅在「Skills 的 gate-guard 那一行應該有」。
- **2（Important，採納）**：屬實（`sed -n 93,104p tests/CLAUDE.md`：T11 那段插在 T2 說明的中間）。T11 的變異對照搬出來另起一條，放在 T2 那一條之後。
- **3（Smells，採納）**：屬實。我寫「`diff -rq` 拿掉」，實際跑的是把條件改成 `if false`。這一輪修正後程式碼變了，變異全部重跑，對照照實際的改法重寫（每條寫明改了哪一句）。
- **4（Smells，採納）**：`t11_snap` 改成一般檔比 `cksum`、目錄與 symlink 比型別與路徑；三次 `--check`（剛裝好、改過、重跑安裝後）都包前後快照。
  審查者那個情境（報不同的那一支裡 `mkdir` 一個空目錄）實跑：紅在「--check 前後沙盒 HOME 不一樣」。讀不到檔的那一次沒包快照（`cksum` 讀不到那兩個檔）。
- Not reported 裡「`grep -cF '與 repo 不同：1'` 會連『：14』一起算」：順手改掉 —— 計數改成分段比對、比到數字後面的全形括號（`t11_foot`）。
- Not reported 裡「清單以外多出來的斷言」：同意它的判定（都是同一組 T11 的加強）；最終回報會把清單以外加的列出來。
- 其餘 Not reported：都同意，沒有動作。
