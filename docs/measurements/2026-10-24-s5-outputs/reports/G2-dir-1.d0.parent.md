## 步驟 4 審查報告：G2-dir-1（`git diff HEAD~1 HEAD`，4 個檔）

三個審查者都回來了。我自己把 diff 檔第 1–1010 行讀完，逐條查證。沒有改任何檔，也沒有 commit。

**【派工】**

我派了 3 個 `code-reviewer`，同一則訊息平行送出，都沒帶 model 參數。

- **A**：審 `scripts/check-claude-md.sh` 的邏輯。包括各種邊界情況、`set -e`、bash 3.2 相容性、擋不下來時是放行還是擋下。
- **B**：審 `tests/test-gate.sh` 新測試有沒有真的抓錯的能力。逐個分支對照「這支由哪則測試蓋到」。
- **C**：審註解與文件裡的宣稱。對 diff 動到的每個名稱跑全 repo `git grep`。

**為什麼是 3 個**：這次改動有三個獨立的失敗面：重構本身、測試是否有效、文件宣稱是否成立，正好各派一個。diff 只有約 200 行，3 個已經達到下限，加第 4 個主要只會換來重複。實際結果也是三個在最重要的那條上重疊（三個都獨立抓到，A、B、C 都附了變異實跑），所以沒有補派。

**【採納】**

1. **來源 A（Critical）、B、C（Important）｜Important（從 Critical 降一級）**
   - **內容**：情境 ⑪ 宣稱「沒有共同祖先時，兩處都放行但要印警告」，實際只測到 `owed_dirs` 那一處。`reviews_missing` 在「沒有共同祖先」時的處理分支從來沒被跑到。
   - **我的查證**：
     - `tests/test-gate.sh:340`（diff 檔第 997 行）`rm -rf r.js README.md src docs 'api server'` 把 `docs/reviews/` 刪了。
     - 所以 gate 跑到 `check-claude-md.sh:151` 的 `[ -d docs/reviews ] || return 1` 就直接放行，走不到 `:162–167`。
     - `test-gate.sh:349` 的 `said "找不到共同祖先"` 之所以會過，是因為 `owed_dirs` 在 `:108` 印的「也找不到共同祖先，這次只檢查 staged」剛好含這幾個字。
     - A、B、C 各自做了變異實跑，結果都是 90 ✅ / 0 ❌，抓不到。A 的 m1 刪掉 `:165–166` 的警告；m2 把 `:167` 改成 `return 0`。B 改用 perl 重做 m1；C 換掉 `:165` 的警告字串。
     - 文件把這個沒驗證的行為寫成「有測試把關」：`tests/CLAUDE.md:11` 寫「兩處放行**但必須印出警告**」，`scripts/CLAUDE.md:49` 的表格也是這個意思。
   - **調級理由**：`check-claude-md.sh:162–167` 的程式碼行為本身是對的（印警告、`return 1`）。缺的是測試保護，再加上一句假的覆蓋宣稱，並不是 gate 本身會做錯判斷。
   - **建議改法**：
     - ⑪ 的 orphan 線上重建 `docs/reviews/`，裡面只放 `CLAUDE.md`。
     - 斷言改成只有 `reviews_missing` 才會印的句子 `said "這次跳過 review 報告檢查"`。
     - 改完重做 m1、m2，確認兩個都會變紅。

2. **來源 B、C｜Important**
   - **內容**：情境 ⑦ 的段頭註解只修了一半，和這次新加的註解自相矛盾。
   - **我的查證**：
     - `test-gate.sh:273–276` 這次沒改，仍寫「起點 commit 被改寫(amend / rebase)…現在退到共同祖先繼續算」。
     - 緊接著新加的 `:283–285` 卻說這則「**沒有**跑到 fork-point 退化」，還說「上面那句註解原本寫…(S4 修正)」，但上面那句其實沒修。
     - 我另外查到兩處同一個過期描述，這次沒同步：`tests/CLAUDE.md:11`（diff 檔第 610 行）和 `CHANGELOG.md:37`（`## 未發布`）都還把「**amend 過的歷史仍照擋**」列成在測起點被改寫的情境。
   - **C 有一個子論點我不採納**：它說「原本寫」指的對象不存在。其實「上面那句」指的就是 `:273` 的段頭，那句仍在原地。
   - **建議改法**：
     - 改寫 `:273–276`，讓它跟 `:283` 一致。
     - 把 `:283` 的「原本寫…修正」改成真實的描述。
     - `tests/CLAUDE.md:11` 與 CHANGELOG 未發布區那一項也一起改。

3. **來源 B（Important）｜Smells（降一級）**
   - **內容**：情境 ⑩ 的 `said "改從共同祖先"`（`test-gate.sh:332`）分不出是哪一處印的。
   - **我的查證**：`--start-segment` 會先跑 `owed_dirs`（`check-claude-md.sh:183`），它用空 prefix 呼叫 `resolve_fork_base`（`:105`），印出的也是同一句。B 的 m2 在 `:162` 加 `2>/dev/null` 讓 review 那一路不印警告，結果 0 紅。
   - **降級理由**：被刪掉共用函式裡的 echo 這種變異會被抓到（A 的 m3、C 的變異 d 都是 2 紅）。這個 `said` 只放過「在呼叫端把警告吞掉」這一種寫法。另外 `:331` 的 block 已經證明退化確實發生了。
   - **建議改法**：改成 `said "review 檢查改從共同祖先"`。

4. **來源 C｜Smells**
   - **內容**：`resolve_fork_base` 偷偷讀全域變數 `$base`，但函式說明（`check-claude-md.sh:72`）只列了 `$1` 和 `$2`。
   - **我的查證**：`:84` 和 `:88` 直接用 `$base`。目前兩個呼叫端都先跑過 `read_base`（`:152`、`:183`、`:231`），所以現在沒有會壞的情境。
   - **建議改法**：在說明裡補一句「讀全域 `$base`，呼叫前須先 `read_base`」。

5. **來源 C（A、B 列在 Not reported）｜Smells**
   - **內容**：`test-gate.sh:340` 的刪除清單寫錯了，實際沒清乾淨。
   - **我的查證**：
     - `'api server'` 在整支測試裡從沒建過。我用 `git grep` 查，只有 `:340` 一處；`git show HEAD~1:tests/test-gate.sh` 裡也沒有。實際建的是 `"my dir"`（`:196`）。
     - 結果 `p/`、`r/`、`w/`、`feat/`、`功能/`、`my dir/` 等目錄都留著，被 `commit` 裡的 `git add -A` 一起收進 r7。
   - **影響**：以後若有情境留下沒有 CLAUDE.md 的程式碼目錄，⑪ 會因為無關的原因變紅。
   - **建議改法**：清單換成實際存在的目錄，或在 orphan 線上改用 `git clean -fdq`。

**【駁回】**

- **C｜「原本寫」指的對象不存在**：理由見採納第 2 條。
- **A、B、C 的 Not reported「重構本身有問題」**：三個都沒報，我也逐行核過了。
  - 新舊警告句逐字一致，`owed_dirs` 的空 prefix 跟舊措辭相同（diff 檔第 86 行對照 `:89`）。
  - `local prefix=$1 head=$2 fork` 在 bash 3.2 可用。
  - stderr 不會被 `$(...)` 吃掉。
  - 沒有共同祖先時 `git merge-base` 回非 0，`if fork=$(...)` 能正確判斷。
- **既有問題，不是這次 diff 引入的**：我回去看了 `scripts/CLAUDE.md:22` 的「前 61 項」和 `check-claude-md.sh:170` 的「四份文件」。這次 diff 沒碰那兩行，也沒有把同樣的寫法複製到新程式碼，所以不列入本次。順帶一提，兩處都已經過期。

**【需使用者決定】**

無。

**【需要外部查證】**

- **S6 的出處**：`scripts/CLAUDE.md:55`、`:58` 與 `check-claude-md.sh:78`、`:80` 引用「S6 的 reviewer 預言過」「S6 的 review 抓到這兩處已經漂移」。快照的 `docs/reviews/` 只有 `CLAUDE.md`，`git log` 也只有兩個 commit，在範圍內查不到出處。要拿 S6 審查報告的原文核對。
- **變異數字只對上了一個**：`scripts/CLAUDE.md:60–62` 寫了「3 紅 / 7 紅 / 2 紅」，但沒寫各變異改在哪一行。
  - 「2 紅」已由 A 的 m3、C 的變異 d 實跑對上，前提是刪掉的是 `:89`。
  - 「3 紅」和「7 紅」沒人用同一種變異重做過。A 的 m4 是 4 紅，但它是不同的變異，不能拿來比。
  - 建議原作者補上變異的具體寫法，再重跑一次。

**【結論】**

採納 **Critical 0 / Important 2 / Smells 3**。兩條 Important 修掉才能往下走：⑪ 的測試要能真的跑到 `reviews_missing` 的分支，⑦ 的註解和連帶的兩處文件要改一致。