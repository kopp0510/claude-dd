# S2-b：審查者 B（升級腳本與測試的正確性）

## 派工

`subagent_type: code-reviewer`，三個審查者同一則訊息平行派出。派工 prompt 是「先讀共用指示，再讀自己的方向」兩份檔，逐字如下。

共用指示：

> 你是 code-reviewer。repo：/Users/danlio/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md，全域規則在 templates/global/CLAUDE.md）。
> 審查範圍：段落 S2 的整段改動 = `git diff f2ab54a`（工作目錄乾淨，等於 f2ab54a..HEAD）。改動與被改檔的整檔內容都在 diff 檔：
> /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/s2-review/diff.txt
> （7865 行。用 Read 的 offset/limit 每次 300 行讀到最後一行 —— 一次讀太多會靜靜截斷、不報錯。被改到的檔一律讀 diff 檔裡那份；沒被改到的檔照常讀 repo。）
> diff 檔第 ④ 節是已跑過的驗證與結果，已確認、不要重跑測試／安裝／claude -p。
>
> 這段做了什麼（事實）：
> - S2-1（489bf74）新增 scripts/dd-init-upgrade.sh（升級分類器：舊蓋章區塊逐行查表分成範本行／在地行，--plan/--apply/--list）與 tests/test-dd-init-upgrade.sh，CI 加進 shellcheck 清單、ubuntu 與 bash32 job。
> - S2-2（304b0f2）commands/dd-init.md 蓋章區塊 rev 12（96 行）換成 rev 13（37 行），只在舊區塊裡的內容搬進 skills/dd-loop/SKILL.md；Phase 1 的 8step 舊版升級改用腳本；React 片段移到區塊外的 ````markdown 圍欄；CI 新增「現行蓋章區塊的每一行都在升級清單裡」；同批改 CHANGELOG、UPGRADING、根 CLAUDE.md、scripts/CLAUDE.md、tests/CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、設計文件。
> - 7b8638a：SKILL.md 的 `US$5.13` 改成「5.13 美元」（skill 帶參數呼叫時 `$<數字>` 會被代換）。
> - 舊區塊（rev 12）原文：`git show v1.6.12:commands/dd-init.md`。
>
> 你的職責：找漏洞，證明這段有錯。每條附證據（路徑:行 + 原文，或指令與輸出）；沒證據不算。只用手上的資料判斷，需要外部查證的列出來交回。
> 嚴重度：Critical / Important / Smell。不寫優點。
>
> 輸出格式：
> ## Findings（每條：級別｜檔:行｜問題｜證據｜失敗情境）
> ## Not reported（看到但判定不算的，一句理由）
> ## What I ran（指令照貼）

方向：

> 你的方向（B）：scripts/dd-init-upgrade.sh 與 tests/test-dd-init-upgrade.sh 的正確性。
> - awk 程式的定位（起點標題、終點、單元切分、圍欄）、--apply 的插入位置與標題降級、exit 碼，找會把在地內容刪掉、放錯步驟、或留下舊範本行的輸入。可以在 /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/s2-review/b/ 建 fixture 對 repo 的腳本跑 --plan/--apply（加 --template /Users/danlio/project/my_project/claude-dd/commands/dd-init.md），不准改 repo 檔。
> - bash 3.2 / BWK awk / mawk 相容性、set -e 下會不會靜默中止、LC_ALL=C 有沒有漏。
> - 測試的斷言有沒有鑑別力：哪個斷言在被測物壞掉時仍會綠（例如比對的字串同時出現在別處、計數撞到描述字串）。
> - 檔頭與註解、tests/CLAUDE.md、scripts/CLAUDE.md 對這兩支的宣稱，逐句對程式碼。

## 發現

（審查者交回的完整報告，逐字）

方向 B 結論：Critical 0、Important 3、Smell 0。範圍是 f2ab54a..HEAD 裡的 scripts/dd-init-upgrade.sh 與 tests/test-dd-init-upgrade.sh。三條都用 fixture 實跑重現過。

## Findings

**Important｜scripts/dd-init-upgrade.sh 第 348 行（`shift = (startTpl ? 0 : Lv - 1)`）與第 257 行（停點判斷 `!(trim(F[i]) in L)`）｜標題被降級過的區塊，第二次升級會多出一個空的 `CLAUDE.md 維護` 標題**
- 問題：rental 型（區塊掛在在地 `###` 底下），或專案把 `## 開發流程（…）` 改過名時，`--apply` 會把新區塊的 `## CLAUDE.md 維護` 降成 `####`（rental 型）或 `###`（改名型）。降級後的標題不在清單裡（清單只有 `## CLAUDE.md 維護`），下一次升級就把它當成在地行，錨在「驗證不過之後」留下來，再接上一份新的降級標題。原本那個標題底下的範本行被刪光，只剩一個空標題。測試「現行區塊自己跑一次結果不變」只涵蓋沒降級的情況，CI「現行蓋章區塊的每一行都在升級清單裡」也只比對沒降級的寫法，所以都擋不到。
- 證據：
  - rental fixture（6a9addd 區塊，標題換成 `### 工作流程（完成的定義，不可省略）`）連跑兩次 `--apply`。r1 只在第 36 行有 `#### CLAUDE.md 維護`；r2 在第 36、38 行各一個，`diff r1 r2` 顯示 `37a38,39 > #### CLAUDE.md 維護`。
  - 改名型（v1.6.12 區塊，標題改成 `## 開發流程`）連跑兩次：h2 的第 34、36 行都是 `### CLAUDE.md 維護`。
  - 對 r1 跑 `--plan`，「保留的行」列出 `36 [驗證不過之後]: #### CLAUDE.md 維護`：它只被列成一般在地行，沒有任何一節提醒會重複。
- 失敗情境：rental-management 這次升到 rev 13，下次 rev 跳 14 再跑 `/dd-init`，就會出現兩個同名標題，前一個是空的。Phase 1 第 7.3 步只用 `^[0-9]+\. ` 檢查步驟行有沒有重複，抓不到重複的標題。
- 修法方向（不明顯，所以寫出來）：判斷標題在不在清單時，先把開頭的 `#` 拿掉再比；或拿降級後的寫法反查。

**Important｜scripts/dd-init-upgrade.sh 第 280–282 行（錨點只從範本單位取）、第 310 行（`ua[u] == "s5"`）｜步驟 5 那一行被專案改寫過時，步驟 5 底下的驗證指令會錨到步驟 4，「步驟 5 既有的驗證指令行」那一節變成（無）**
- 證據：fixture 用 v1.6.12 區塊，把步驟 5 換成 `5. **再測一次**（本專案改寫）`，底下放 `- LOCAL5CMD npm run e2e`。`--plan` 印出 `61 [步驟 4 底下]:    - LOCAL5CMD npm run e2e`，「步驟 5 既有的驗證指令行」是（無）。`--apply` 後，LOCAL5CMD 在第 23 行，接著才是新的 `5. **再測一次** —` 在第 25 行，後面是佔位行。
- 失敗情境：Phase 1 第 7.1 步看「步驟 5 既有的驗證指令行」決定佔位行要填還是刪。那一節是空的，佔位行就會被填成具體指令，和專案原有的 e2e 指令重複。原有指令還落在步驟 4 底下。「疑似改寫」確實列了改寫過的步驟 5 那行，但沒提它底下的子項被改錨了。

**Important｜scripts/dd-init-upgrade.sh 第 307 行（`trim(F[x]) ~ /^[0-9]+\. /`）＋ tests/test-dd-init-upgrade.sh 第 53–62 行（`add_locals`）｜「步驟 1 之前」錨點的程式路徑完全沒有測試，把它整段刪掉，測試照樣全綠**
- 證據：
  - 變異 mut-pre.sh 拿掉 `if (has["pre"]) ins[firstStep] = …` 那一行（`grep -c 'MUT pre dropped'` 回 1，確認變異生效）。拿它跑 p.md fixture，輸出裡 `grep -c LOCALPRE` 回 0，在地段落被刪掉了。
  - 再跑 `tests/test-dd-init-upgrade.sh mut-pre.sh`：exit 0，35 ✅、0 ❌。
  - `add_locals` 只在步驟 4、5、8、驗證不過、維護小節插入在地行。LOCALH 在區塊外，走的不是 pre 路徑。
- 失敗情境：rev 12 的區塊在步驟 1 之前有大段起點說明，專案常在那裡加註記。這條路徑哪天壞掉、開始刪在地內容，CI 也不會變紅。
- 同一行另有一個小問題：縮排的在地編號清單（例如 `     1. LOCALNUM 先跑 migrate`）去掉前導空白後符合 `^[0-9]+\. `，會被列進「疑似改寫過的步驟行」（實跑時 `--plan` 列了第 62 行）。Phase 1 第 7.3 步就會去問使用者一組根本不存在的同號重複。影響小。

## Not reported
- awk 執行期錯誤（例如輸出路徑的目錄不存在）會回 exit 2，跟檔頭寫的「2 = 找不到標記」撞號。Phase 1 會照實轉述 awk 的錯誤訊息，結果還是「不升級」，不會造成損害。
- CRLF 檔：輸出混了 CRLF 與 LF（檔頭 2 行保留 `\r`，新區塊是 LF）。只是外觀問題。
- 被改寫過措辭的「驗證不過」行會變成在地行、錨到步驟 8，跟新的那行並存，而且只有長度 ≥60 bytes、前 60 bytes 相同時才列進「相似」。這屬於檔頭寫明的「多留、不會少」。
- 同一個錨點下、中間隔著範本單位的幾個在地單位，合併時會失去中間的空行。只影響外觀。
- 檔頭重新產生清單的指令：用 bash 跑出的結果與 `--list` 逐字相同（SAME，163 行）。React 片段的每一行都在清單裡，檔頭這兩句宣稱成立。ci.yml 的 `stamp()` 用的 awk 與腳本相同。
- 舊版區塊沒有 `---` 行，所以清單排除 `---` 不會留下舊範本。
- 本機只有 BWK awk（20200816），沒有 mawk／gawk。scripts/CLAUDE.md 寫「三種都實跑過」，我沒辦法驗證。要查的話：`docker run --rm -v "$PWD":/r -w /r debian bash tests/test-dd-init-upgrade.sh`（Debian 預設 awk 是 mawk），這能確認那句話與 mawk 相容性；另外可看 ubuntu runner 上 `awk --version` 是哪一支。
- tests/CLAUDE.md 寫的變異對照數字（33、9、10 ❌）：依指示沒有重跑。

## What I ran
- `cat prompt-common.txt dir-b.txt` → 讀了派工指示
- `cat -n scripts/dd-init-upgrade.sh`、`sed -n '196,368p'` → 讀了腳本本體
- `cat -n tests/test-dd-init-upgrade.sh`、用 awk 抽出 commands/dd-init.md 的蓋章區塊 → 讀了測試與現行區塊
- `dd-init-upgrade.sh --list` 後用 grep 找編號行、標題、驗證不過 → 清單裡的編號行只有步驟 1–8，標題只有 3 個
- 用 bash 跑檔頭的重新產生指令，與 `--list` 做 diff → SAME（163 行）；React 片段的每一行逐行 `grep -qxF` → 沒有缺漏
- 用 bash 掃 dd-init.md 歷代帶標記的區塊，數 `---` 與圍欄 → `---` 全部是 0
- `which mawk gawk awk` → 只有 /usr/bin/awk（BWK 20200816）
- `b/run.sh`：rental 連兩次 `--apply` → r1≠r2、兩個 `####`；改名型連兩次 → 兩個 `###`；pre 錨點＋改寫步驟 5＋縮排編號 → 結果如上；CRLF → exit 0，輸出混 CR
- `b/mut-pre.sh`（拿掉 pre 插入那一行）跑 p.md → LOCALPRE 剩 0 次；`tests/test-dd-init-upgrade.sh mut-pre.sh` → exit 0、35 ✅、0 ❌
- 對 r1.md 跑 `--plan` → 降級標題被列成「保留的行 [驗證不過之後]」

上面的 fixture 與輸出都放在 /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/s2-review/b/（run.sh、mut-pre.sh、r1.md、r2.md、h1.md、h2.md、p.plan、p1.md、mut-pre.out）。

## 處置

- Important｜降級過的標題第二次升級多一個空標題 → **採納**。awk 加 `htext()`／`inL()`：標題比對時不看 `#` 的個數（清單裡的標題另存一份去掉 `#` 的），起點、終點、單行判範本三處改用 `inL()`。測試加「rental 型升級過再升一次輸出不變」；把單行判範本改回 `(t in L)` → 1 ❌
- Important｜改寫過的步驟 5 底下的指令錨到步驟 4 → **採納**。在地單位若是第 0 欄的 `N. ` 步驟行，它本身照舊跟前一個錨點，但之後的在地單位改錨到步驟 N。測試加 3b（改寫步驟 5＋底下 `LOCALS5`）；拿掉這段 → 2 ❌
- Important｜「步驟 1 之前」錨點沒測試 → **採納**。`add_locals` 在步驟 1 前插 `LOCALP`，四版都斷言它在標記與步驟 1 之間；拿掉 pre 插入 → 8 ❌
- 同條的小問題：縮排的在地編號清單被列進「疑似改寫」→ **採納**。改成只認第 0 欄的 `N. `（上一條的錨點判斷同樣用未去空白的行）
- Not reported 的 mawk／gawk 無法驗證 → 我補跑了：docker `debian:stable-slim`（mawk 1.3.4）40 ✅、`bash:5`＋gawk 5.3.2 40 ✅、macOS BWK awk 40 ✅
- Not reported 的 awk 執行期錯誤回 exit 2 撞號 → 不處理：Phase 1 對 exit 非 0 一律不升級、照實轉述錯誤訊息，撞號不改變行為
