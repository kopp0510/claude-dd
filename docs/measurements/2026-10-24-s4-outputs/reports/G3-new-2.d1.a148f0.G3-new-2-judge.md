【派工】
我平行派了 3 個 `code-reviewer`，都沒帶 model 參數：
- A 審 `tests/test-gate.sh` 新增的繞過①②③區塊和 ⑦ 那行 amend 包進 `expect` 的改動，對照 `scripts/check-claude-md.sh` 逐則核，並實跑 `scripts/CLAUDE.md` 變異表的三個變異。
- B 審文件宣稱與交叉引用：CHANGELOG、§3.5 與 §3.9 是否一致、verification-gate、收編總則，以及這次改動有沒有漏掉要同批同步的檔案。
- C 審 worktree-manager 的收尾流程，在拋棄式 repo 實跑 git，次要看「假紅」條文的語意。

派 3 個的理由：diff 只有一處是程式碼（test-gate.sh），其餘都是規則文件。這三個方向剛好切開「行為實測」「引用核對」「新流程實證」，彼此沒有重疊，再多派只會重複讀同一批檔案。三個都回來了，沒有失敗，不用補派。

【採納】
1. A、B、C 都報｜Important｜verification-gate 新紅旗和 §3.9 鑑別力測試直接衝突。
   - 內容：SKILL.md:36 寫「`git stash -u && <測試>`（看到失敗，而且紅的是原本那個 bug）」，:58 寫「修 bug 時就是那個錯的值」。把修復藏起來重跑，就是 §3.9 的「改回舊版確認會紅」。
   - 查證：diff 檔 1595、1616–1617 行。§3.9 在 diff 檔 2065–2067 行（模板:364–367）明寫「不要斷言某個預期的壞結果」，因為舊碼可能掉進第三種狀態。§3.5 那個括號例外（模板:195）在 SKILL.md 兩處都沒帶。CHANGELOG:26 宣稱「仍照 §3.9」，對這支 skill 不成立。
   - 失敗情境：舊碼回的是 undefined 而不是 2，照 SKILL.md 判就會認定測試無效，回頭去改一個正常的測試。這正是 §3.9 記的 2026-10-07 那次差點發生的事。
   - 建議改法：判準改成「紅的原因要來自被測物給了錯的結果，不是載入失敗或資料沒建好；錯的值不必是你預期的那一個」。stash 或改回舊版的情況明寫照 §3.9 判。§3.5:193–194 與 CHANGELOG:23–26 同批改。
2. B｜Important｜§3.5 的括號讓變異版不受新規則管。
   - 內容：模板:195 寫「判定變異版…仍照 §3.9…不等於固定版的輸出就算紅」。
   - 查證：§3.9:367 只寫「不等於它就算紅」，沒有排除條件。變異版 import 壞掉、載入失敗一樣「不等於」，照這句就算抓到。
   - 失敗情境：這次要擋的假紅，在變異測試上照樣放行。
   - 建議改法：§3.9 那條補「不等於要來自被測物給了錯的結果，載入失敗、import 壞掉、資料建不起來不算」，§3.5 的括號改成指向它。
3. C｜Important｜§3.5 新句只給了修 bug 的判準，新功能的紅沒有判準。
   - 內容：模板:193–195 管的是所有新測試的第一次紅，但「對得上它應該怎麼紅」只舉了修 bug 的例子。
   - 查證：TDD 寫新功能時，第一次紅通常是「找不到函式 / cannot import name」，和條文裡判為「測試自己壞了」的「import 路徑寫錯、拼錯字」分不出來。讀者可能拒收合法的紅，也可能照收而放過真的打錯字，兩種讀法都能從字面推出來。
   - 建議改法：補新功能那一支，怎麼補見下方需使用者決定。
4. B｜Important｜worktree-manager 缺借鑑出處。
   - 查證：CHANGELOG:39 寫「借鑑 pstack-claude 的 worktree-cleanup playbook」。專案的「只借概念、不抄檔案時…授權仍要處理：歸屬範圍精確到段落／項目」規則在快照 CLAUDE.md:353。房規是在 SKILL.md:9 寫一行「借鑑 …」，design-brainstorm:9 與這次的 verification-gate:9 都這樣寫，而 worktree-manager 整檔沒有。
   - 建議改法：SKILL.md:9 位置補「收尾那段借鑑 michael-denyer/pstack-claude 的 worktree-cleanup playbook」。根目錄 CLAUDE.md 收編總則的寫法借鑑（CHANGELOG:29–30 寫了借鑑 `reflect`、`poteto-mode`）正文也沒標，這部分我降成 Smells：它是 repo 內部文件，不會部署。
5. B、C 都放進 Not reported，我收成 Smells｜worktree-manager 兩處小措辭。
   - 一：:38 說 `WORKTREE_INFO.md`「只記分支、路徑與基線結果」，少了步驟 6（:23）寫的 base。
   - 二：:30「`!!` 那幾行處理完還是會留在輸出裡」只對留下的檔成立，刪掉或搬走的檔不會再出現（C 實測）。
   - 建議改法：前者補上 base，後者改成「決定留著的 `!!` 檔仍會出現在輸出裡」。

【駁回】
- C｜worktree-manager 的 `allowed-tools` 沒列 AskUserQuestion：C 自己也不報，我同意。CLAUDE.md 的「注意事項」寫明 allowed-tools 只是免確認預授權，漏列只會多一次權限詢問；建立流程的第 2 步本來就用 AskUserQuestion。
- C｜收尾沒涵蓋 locked worktree、submodule、未 push 的 commit、stash：locked 與 submodule 是既有缺口，而且 submodule 已寫在「限制備忘」（:46），不是這次 diff 引入的。未 push 的 commit 和 stash 在 remove 之後仍在，不會遺失資料。
- A｜變異表的 `head_or_empty > "$BASE_FILE"` 在 gate 裡有兩處（:215 與 :232）：表裡已寫明「它那一支」，A 和 B 用 :215 實跑，結果都符合表上宣稱，不算錯。
- A｜`scripts/CLAUDE.md:71` 的「前 61 項」是過期數字：這行不在本次 diff 裡（diff 檔第 70–71 行是 context），屬既有問題。我回去看過，這次 diff 沒有複製這個數字到新段落，駁回。可以另外記一筆既有欠帳。
- test-gate.sh 新區塊與 ⑦ 的 amend：A 和 B 各自實跑三個變異，結果一致。M1 讓繞過①紅，並從建立 docs/reviews/ 那個 commit 起一路連鎖紅；M2 只紅「rm 掉起點檔,開下一段放行」；M3 只紅「by/ 的欠帳被洗掉」。判定行數三份都是 105。舊版測試配 M1 停在 ⑦，只有 76 行。`said` 字串和 `base_is` 的推論對照 gate :185、:195、:202、:213 都成立，沒有發現問題。

【需使用者決定】
- 新功能（實作還沒寫）時，第一次紅怎樣才算有效？
  - A) 先放一個回錯值的空殼，紅必須落在斷言上；「找不到函式」不算。
  - B) 接受「找不到函式 / not defined」這種紅，但只限被測的那個新名稱；import 其他東西失敗仍不算。
  - 建議答案 A：判準和修 bug 那支一致，都是「紅在斷言上」，也不會留下 B 那種「這個名稱算不算被測物」的模糊空間。
  - 注意：A、C 兩位引了我這個 session 載入的已部署版全域 CLAUDE.md，那份 §3.5 已經是 A 的寫法。那不是快照裡的檔，我只當參考，不當證據。

【需要外部查證】
- `git worktree remove` 在 git 2.54.0 的行為與訊息原文。C 只在 2.42.0 實跑，結果全部符合 SKILL.md 的描述，包括中文訊息原文與 `!!` 檔直接刪掉不提示；英文訊息原文沒驗。
- pstack-claude 上游的幾件事：LICENSE、owner 是否為 `michael-denyer`、SessionStart hook 的 matcher 是否真的涵蓋 startup、resume、clear、compact（CLAUDE.md 新總則與 verification-gate:9 引用了這些）。

【結論】
採納 Critical 0 / Important 4 / Smells 2。Smells 是採納 4 的根目錄 CLAUDE.md 部分，和採納 5。

我沒有改任何檔，也沒有 commit。三位審查者的完整報告只在本輪的 Agent 結果裡，沒有寫進 scratchpad：任務說明禁止寫檔，只有寫回報告這一步沒照全域 §3.9 的做法。需要原文可以用 SendMessage 向它們調：A = `aa6177ed8f50e4f1c`、B = `a2fd4b64c4bfd0f41`、C = `ae16a9c7b9c956b69`。