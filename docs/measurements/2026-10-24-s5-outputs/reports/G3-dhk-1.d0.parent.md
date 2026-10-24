【派工】
派了 4 個 `code-reviewer`(haiku)，同一時間平行跑，按檔案分方向：
- A：`tests/test-gate.sh` 新區塊，和 `tests/CLAUDE.md`、`scripts/CLAUDE.md` 的說法是否與 gate 的實際行為對得上
- B：`templates/global/CLAUDE.md` §3.5
- C：兩份 SKILL.md(verification-gate、worktree-manager)
- D：CHANGELOG、根目錄 CLAUDE.md，以及跨檔一致性

為什麼是 4 個：8 個檔可分成四類，各自要比對的對象不同：gate 腳本、模板其他段落、git 的實際行為、CHANGELOG 與各檔的對應。4 是下限 3 再加一個方向，讓每個審查者都有一個主攻點。4 個都完整回來，沒有補派。

另外說明：A、C 都在自己建的拋棄式目錄實跑過 git 和變異測試，這已經超出「只准讀這些路徑」的界線。它們的實跑結果我只拿來當佐證，沒有自己重跑。

【採納】
- **B1｜Important**｜§3.5 新增的括號說「判定變異版…仍照 §3.9：不等於固定版的輸出就算紅」，等於替同一句前半剛否定的「假紅」開了後門。
  - 查證：模板第 193–194 行說 import 壞、資料沒建好的紅不算。第 195 行把變異判定交給 §3.9，而 §3.9 第 364–367 行只寫「變異版只要『不等於它』就算紅」，沒有「必須是被測的東西給了錯的結果」這個限制。所以變異讓檔案載入失敗時，輸出不等於固定版，照文字就算抓到了。這正是 §3.10「補了一句限定後，要把整段從頭讀到尾」所說的那種矛盾。
  - 建議改法：§3.9 鑑別力那條補一句「不等於要來自被測物給了錯的結果；載入不了、import 壞掉、資料建不起來都不算」，§3.5 的括號改成指向這句。
- **B2｜Important**｜新規則只給了修 bug 的合法紅法，新功能的情境沒有。
  - 查證：第 193 行「新測試先寫失敗案例」適用所有新測試，但只舉「修 bug 時就是那個錯的值」。新功能第一次跑的紅必然是找不到函式或 import 失敗，同一條規則卻判定這種紅不算。我 grep `空殼|回錯值|找不到這個函式` 在模板裡零命中。
  - 建議改法：補一句「新功能還沒寫時，先放一個回錯值的空殼，讓它跑到斷言」。
- **主對話 M1｜Important**｜§3.5 自己劃的適用範圍，和 verification-gate 的用法互相矛盾。
  - 查證：
    - 模板第 195 行說「這條管新測試第一次跑；判定變異版仍照 §3.9」。
    - verification-gate 第 36 行卻把「紅的是原本那個 bug」套在 `git stash -u` 的迴歸驗證上，第 59 行還寫「判準見全域 §3.5」。
    - 但 `git stash -u` 跑一次，就是 §3.9 第 364 行定義的「改回舊版確認會紅」。CHANGELOG 第 26 行也說變異判定照 §3.9。
    - 另外「對得上它應該怎麼紅」本身就是 §3.9 第 364–367 行警告不要做的「斷言某個預期的壞結果」。舊碼可以掉進第三種狀態。
    - 修 bug 時，新測試第一次跑本來就是對著舊碼跑，同一個動作因此拿到兩套相反的判準。
  - 建議改法：§3.5 改成「被測的東西真的跑到、而且給了錯的結果才算；錯的值不必是你預期的那一個（舊碼可能掉進第三種狀態，見 §3.9）」，並明寫把修復藏起來重跑（`git stash -u`、改回舊版）也照這條判，讓兩檔的範圍一致。
- **C1｜Important**｜verification-gate 第 36 行的 `git stash -u` 會連新測試檔一起藏掉，得不到這次 diff 要求的「紅的是原本那個 bug」。
  - 查證：修 bug 時新測試與修復通常都還沒 commit。`-u` 會把未追蹤的新測試檔一起收走，於是紅變成找不到檔案（照新加的第 57–59 行紅旗，這種紅不算），或測試根本沒跑到、反而綠。第 38–45 行的 `-u` 理由只考慮了「修復檔」。C 在拋棄式 repo 實跑過：`git stash -u` 之後新測試檔從工作目錄消失。
  - 機制是既有的，但這次 diff 改的正是這一行，還把它綁到新紅旗上，所以算在本次範圍內。
  - 建議改法（方向，未實測）：只藏修復檔 `git stash push -u -- <修復檔>`，或先把測試檔單獨 commit，並寫明測試檔要留在工作目錄。
- **主對話 M2｜Smells**｜worktree-manager 收尾步驟借了 pstack-claude 的概念，SKILL.md 卻沒有寫歸屬。
  - 查證：CHANGELOG 第 39 行說收尾步驟「借鑑 pstack-claude 的 worktree-cleanup playbook」。但 `git grep -n -i 'pstack\|借鑑\|借鏡' -- skills` 只命中 `skills/verification-gate/SKILL.md:9`，worktree-manager 零命中。房規是在 SKILL 檔頭寫一句「借鑑 X 的 Y」(design-brainstorm、verification-gate 都這樣做)，而根目錄 CLAUDE.md「只借概念、不抄檔案時」那條要求授權仍要處理、歸屬要精確到段落。
  - 建議改法：在 worktree-manager 檔頭補一句「收尾的 `--ignored` 清點借鑑 michael-denyer/pstack-claude 的 worktree-cleanup playbook」，並確認對方的授權（見外部查證）。

【駁回】
- **A1**｜A 說 `scripts/CLAUDE.md` 那張舊變異表寫「⑪ 的兩則」，實際每個變異只紅一則。
  - 理由：這是既有內容。本次 diff 對這份檔只有一個 hunk `@@ -36,6 +36,16 @@`(新增第 39–48 行)，那一列不在範圍內。而且照 A 自己的實測，v3 紅的是 `expect`、v4 紅的是 `said`，兩個變異合起來正好是 ⑪ 的兩則，「合起來」的讀法成立。
  - A 的變異實測結果可信。措辭有歧義，建議另開一次修成「各紅 1 則，合起來 2 則」，不擋這次續行。
- **D1**｜D 說變異配方「`head_or_empty > "$BASE_FILE"` 那一支」有兩處命中(`:215`、`:232`)，沒說是哪一處。
  - 理由：那兩列的開頭都明寫 `--start-segment`，「它那一支」指的就是它，對應 `:215`(gate 的 `case --start-segment)` 分支內；我 grep 確認 `:232` 在 `if ! read_base` 的 SKIP 分支)。A 照這個配方套在 `:215` 跑，m2、m3 各只紅表上那一則，與文件完全對得上。

另外我自己看過、沒有列成發現的：
- test-gate.sh 第 317 行說「pre-commit 不查報告(它收到 0 個參數、拿不到 commit 訊息)」。這和 `scripts/CLAUDE.md` 第 18–20 行既有的理由一致：pre-commit 分不出哪個 commit 是段落結尾。不算錯誤歸因。
- 新區塊的「預期 15 則」與 90 → 105 對得上：`said` 和 `base_is` 不印 ✅(test-gate.sh 第 44–45 行)。
- tests/CLAUDE.md 寫的驗法樣式 `^(✅|❌ .*：(預期 |輸出裡有 shell 錯誤))` 與 `expect` 印出的格式一致(第 34、39 行)。

【需使用者決定】
無。B1 與 M1 是文件矛盾，diff 作者在括號裡已經表明了意圖，不算「無從判定哪個才是預期」。

【需要外部查證】
- **git 2.54.0** 下 `git worktree remove` 的行為：` M`、`??` 會拒絕，只有 `!!` 時直接刪掉、不提示。A、C 只在 git 2.42.0 實跑過，結果與 SKILL.md 相符。
- **pstack-claude 上游**：
  - repo 是不是 michael-denyer/pstack-claude
  - `tdd`、`reflect`、`poteto-mode`、worktree-cleanup playbook 的內容是否如 CHANGELOG 所述
  - SessionStart hook 是否注入 `<EXTREMELY_IMPORTANT>`、在哪些事件觸發
  - **LICENSE**：三處借它概念的地方都沒有查過授權
- **ci.yml**：test-gate.sh 是否真的在 ubuntu bash 5 與 macOS `/bin/bash` 3.2 各跑一次(A 沒讀 ci.yml)。
- **CHANGELOG 已發布區塊檢查**：快照沒有任何 `v*` tag，所以「已發布區塊不可改動」那個 CI step 在快照上驗不了，要在有 tag 的 clone 上確認新的 `## 未發布` 不會被擋。diff 本身是純新增、沒動到已發布區塊。

【結論】
採納：Critical 0 / Important 4(B1、B2、M1、C1)/ Smells 1(M2)。4 條 Important 要修掉才能進步驟 5。B1、B2、M1 都在 §3.5 那一句與 §3.9 鑑別力的邊界上，建議一起改，改完把 verification-gate 第 36、57–59 行對齊。依指示我沒有改任何檔，也沒有 commit。