【派工】
我派了 3 個 code-reviewer，同一則訊息平行送出，都沒帶 model 參數，三個都回來了，沒有補派。
- A：負責 gate 腳本的邏輯。看邊界情況（merge、amend、rebase、非 ASCII 路徑、worktree），以及 bash 3.2 和 shellcheck 相容性。
- B：負責 CI 新增的 step。看每個情境有沒有真的測到它說的東西，要求實際跑一次並做變異測試。
- C：負責文件和註解裡的宣稱，以及專案規則要求的同步有沒有做，對 diff 動到的識別符逐一 `git grep`。

只派 3 個，是因為 diff 只有 3 個檔、約 300 行，三個方向剛好對上三類檔案，再加人重疊會很大。三份報告確實高度重疊：A、B、C 都抓到 scripts/CLAUDE.md 沒同步，A、C 各自抓到非 ASCII 路徑問題。

派工 prompt 都包含：「只准讀這些路徑」整節、diff 檔路徑與「被改到的檔讀 diff 檔裡那一份」、「範圍與已跑過的驗證」整段、CLAUDE.md 清單、「每條附證據，沒證據不算」、外部查證項列出交回。另外各自加了上面的方向提示。

完整報告逐字在對話紀錄裡（agentId：A=ab708132f7c59896b、B=a6ff058dea63509a2、C=abaea4091eeb93507）。這次任務說明寫「不准改任何檔」，所以我沒有把報告落地成檔，主對話需要時要自己寫進 `docs/reviews/`。

下面每一條我都讀過程式碼查證。腳本那幾條都在自建的暫存 repo（git 2.42.0）用快照 `HEAD:scripts/check-claude-md.sh` 重跑過。

【採納】
1. A／B／C｜Critical（A、B 標 Critical，C 標 Important，我取 Critical）｜這次改了 `scripts/check-claude-md.sh`，同目錄的 `scripts/CLAUDE.md` 沒有一起改，全域模板 §3.9 和 dd-init 也沒有同步。
   - 查證：`git grep -E 'start-segment|segment-base|dd-segment-base'` 排除這 3 個檔後回 rc=1，也就是 0 筆。
   - `scripts/CLAUDE.md:8-11` 還是寫舊規則（只看 staged）。
   - `templates/global/CLAUDE.md:247` 步驟 8 用 `git show … HEAD`，只看最後一個 commit。
   - `templates/global/CLAUDE.md:273` 和 `commands/dd-init.md:124-125` 把 SKIP 寫成單純的逃生口，沒提會留欠帳。
   - 這違反根目錄 `CLAUDE.md:107-108` 和 `scripts/CLAUDE.md:21`。C 的實驗 D 證明這個 commit 拿新 gate 自己跑會被擋。腳本 :11 和 CHANGELOG 說 `--segment-base`「給迴圈步驟 3、4、8」用，但在別處沒有任何落點。
   - 定 Critical 的理由：它違反專案明文規則，最終 commit 過不了 gate；而且沒有文件叫人跑 `--start-segment`，新功能在實務上只能靠 SKIP 自動記起點那條路觸發。
   - 建議：同批更新 `scripts/CLAUDE.md`，§3.9 步驟 3、4、8 改用 `--segment-base`，步驟 2 前加 `--start-segment`，dd-init Phase 3 第 4 點和兩份 README 的 gate 描述也一起補。

2. A｜Important｜起點已經不在目前分支的歷史裡（amend、rebase、換分支）時，SKIP 不會重記起點，之後的正常 commit 只印警告就放行，SKIP 留下的欠帳就這樣消失。
   - 查證情境 E：沒記過起點，用 SKIP 做 `--amend` 新增 `src/a.js`，下一個只改 README 的 commit 放行。
   - 查證情境 F：在 feat 記起點，切回 main，SKIP 新增 `lib/l.js`，下一個 commit 放行。
   - 原因：`read_base` 只檢查起點是不是合法物件（腳本 :42-49），不檢查它是不是 HEAD 的祖先；SKIP 分支（:113）因此不重記。
   - 建議：SKIP 分支在起點不是 HEAD 的祖先時也重記。CI 情境 7 宣稱的「只查 staged」保留，我另外跑了情境 G，起點失效時 staged 的程式碼仍會被擋，這部分正確。

3. A｜Important｜merge commit 裡新增的程式碼看不到。
   - 查證情境 B：`merge --no-commit` 後新增 `src/a.js`，用 SKIP 提交這個 merge，之後的 commit 放行。
   - 原因：`git log --name-only`（:81）預設不列 merge commit 改到的檔案。
   - 建議：加 `--diff-merges=first-parent`。runner 的 git 版本支不支援，見「需要外部查證」。

4. A／C｜Important｜目錄名含非 ASCII 字元時，欠帳會被靜靜放掉。
   - 查證情境 A：SKIP 新增 `中文/a.js`，之後只改 README 的 commit 放行。
   - 原因：`git log`（:81）照預設 `core.quotePath` 輸出加了引號的路徑，dirname 算出來的目錄不存在，被 :136 的 `[ ! -d ]` 當成「整個刪掉了」跳過。
   - staged 那一支同樣的問題是改動前就有的，這次是把它帶進了新的欠帳路徑，所以算這次的問題。
   - 建議：:81 和 :120 都加 `-c core.quotePath=false`，長期改用 `-z`。

5. C｜Important｜`--start-segment` 判斷欠帳和正常 commit 不一致，會卡死。
   - 查證情境 D：SKIP 新增 `tmpx/a.js`，`git rm -r tmpx` 後的正常 commit 放行，但接著跑 `--start-segment` 被擋，要求補 `tmpx/CLAUDE.md`，而那個目錄已經不存在。
   - 原因：:88-95 沒有套 :136 的「目錄已刪就跳過」過濾。
   - 建議：把 `-d` 過濾移進 `owed_dirs`，兩邊共用。

6. B｜Important｜CI 情境 7（diff.txt:89-96）沒測到「只查 staged」那一半。
   - 查證：w1 只改 README，staged 裡沒有程式碼目錄，所以「起點失效就整個放行」和「只查 staged」兩種寫法結果一樣。
   - B 做了變異 M2（起點失效時印同一句警告後直接 `exit 0`），22 個情境全綠。
   - 建議：起點失效後再加一則 staged 程式碼、不附 CLAUDE.md 的 commit，預期 block。

7. B｜Smells（B 標 Important，我降級）｜情境 2 的「可以重記起點」和情境 5 的「印得出起點」只驗 exit code，不驗結果。
   - B 的變異 M1（已有起點時不覆寫）和 M3（印空字串）都 0 紅存活。
   - 降級理由：現在的程式碼行為正確，這只是未來回歸時抓不到。
   - 建議：斷言起點檔內容等於 `git rev-parse HEAD`；`--segment-base` 的輸出不可為空，而且要是 commit 或 tree。

8. A｜Smells（A 標 Important，我降級）｜起點只有在跑 `--start-segment` 時才會往前推，每個 commit 都要重算起點以來的整段歷史。
   - A 實測 300 個 commit 跑一次 gate 要 4.66s，我沒有重跑。
   - 降級理由：這個量級還能接受，根本解法是第 1 條把「段落開始先跑 `--start-segment`」寫進文件。

9. B｜Smells｜`ci.yml` diff.txt:90 的 `git checkout -qb side && echo …`。
   - 查證：在 `bash -e` 下，`&&` 串列裡前面的指令失敗不會中止 step，checkout 失敗會被吞掉。後果是錯誤訊息指錯地方，不會變成假綠。
   - 建議：拆成兩行。

【駁回】
- C 的 Not reported「起點失效時退回只查 staged，是刻意設計」：只駁回其中一半。staged 那一半確實是設計，情境 G 也驗證會擋。但 SKIP 不重記起點、讓欠帳消失，不是設計，已併入採納第 2 條。
- B 的 Not reported「`said "src"` 的字串太短，可能誤命中別處」：B 自己的推論成立，暫存目錄的路徑裡沒有 src，不構成問題。

【需使用者決定】
- 從上游 pull 或 merge 進來的別人的 commit，要不要算進「起點以來的欠帳」（來源 A）
  - 查證情境 C：記起點後，pull 進一個隊友沒走 gate、新增了 `api/t.py` 的 commit。我只改 README 的 commit 被擋，要求補 `api/CLAUDE.md`，`--start-segment` 也會因為這筆帳拒絕重記。
  - 程式碼、測試、文件都沒寫明哪個才是預期。CHANGELOG 只說「SKIP 跳過的目錄」，但腳本 :4 的總規則是「每個含程式碼的資料夾都要有 CLAUDE.md」。
  - 選項 (a)：維持現狀，任何來源的欠帳都要補；只把訊息裡「有 commit 跳過檢查」的說法改得中性。
  - 選項 (b)：只算自己第一父鏈上的 commit，pull 進來的不算。代價是要另外處理採納第 3 條的 merge 情境。
  - 我建議 (a)：它和 :4 的總規則一致，改動也最小。

【需要外部查證】
- GitHub Actions ubuntu-latest runner 的 git 版本是否 ≥ 2.31，決定能不能用 `--diff-merges`（採納第 3 條）。
- runner 的全域 git 設定有沒有 `core.hooksPath`。有的話 `.git/hooks/pre-commit` 會被忽略，CI 會直接報錯，不會假綠。
- CHANGELOG 寫的 rental-line 數字（4 個目錄、13 段裡有 8 段、約一小時後才補）要到 rental-line repo 重算才能確認。
- 已確認、不用再查：「CI 新增 22 個情境檢查」與 `expect` 呼叫數 22 一致（A、B、C 都實數過）。B 在 macOS bash 3.2.57 加 `-e` 實跑這個 step，22 個全綠，exit 0；shellcheck 0 個警告。

【結論】
採納 Critical 1 / Important 5 / Smells 3。