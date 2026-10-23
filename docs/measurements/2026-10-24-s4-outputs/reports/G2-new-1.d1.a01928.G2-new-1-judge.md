【派工】
我派了 3 個 `code-reviewer`，不帶 model 參數，在同一則訊息裡平行跑，三個都回來了，沒有補派：
- A：`resolve_fork_base` 重構跟改動前行為是否等價。看 stdout/stderr、exit code、變數作用域、bash 3.2。
- B：`test-gate.sh` 新增的 ⑦⑩⑪ 斷言有沒有鑑別力。逐步追蹤拋棄式 repo 每一刻的狀態，以及 gate 走哪條分支。
- C：註解與文件的宣稱，包括反事實、變異數字、歸因、前後矛盾、表格。

數量取 3 的理由：這次 diff 的人工判斷集中在「程式碼重構」「測試斷言」「文件宣稱」三類，各派一個主攻。三個人都允許跨方向報，靠交集互相佐證。最後 A、B、C 獨立打到同一條 ⑪ 的問題，B、C 各自打到 ⑩/⑦ 的問題，交集足夠，所以沒有加派。

給三人的 prompt 都包含：「只准讀這些路徑」整節、diff 檔路徑、「被改到的檔讀 diff 檔裡那一份」、「範圍與已跑過的驗證」整段（含預期值）、各層 CLAUDE.md 的位置、職責（找漏洞，每條附證據，沒證據不算）、外部查證列出交回不自己抓、不設工具次數上限、不改檔。

【採納】
1. A、B、C 都報｜Important（B 標 Critical，我調降：gate 程式碼本身是對的，錯的是測試覆蓋和文件宣稱，沒有使用者端的錯誤行為）｜⑪「連共同祖先都沒有：兩處放行但要講出來」根本沒跑到 `reviews_missing`。
   - 查證：
     - 清場指令把 `docs/` 刪了（diff 檔 190，即 test-gate.sh:340 的 `rm -rf r.js README.md src docs 'api server'`）。所以 `reviews_missing` 在 check-claude-md.sh:151 的 `[ -d docs/reviews ] || return 1` 就提早返回，到不了 :162-167。
     - test-gate.sh:349 的 `said "找不到共同祖先"` 被 `owed_dirs` 在 check-claude-md.sh:108 印的「也找不到共同祖先，這次只檢查 staged」滿足，因為 `--start-segment` 在 :183 先跑 `owed_dirs`，而它的 stderr 會進 `$OUT`。
     - 三個審查者各自做了變異：刪掉 :165-166 的警告後仍是 90 ✅ / 0 ❌。我沒有重跑這個變異，但從程式碼讀出的結論和它一致。
   - 受牽連的宣稱：scripts/CLAUDE.md:49 表格裡 `reviews_missing` 那列的「放行，但印警告」、test-gate.sh:336-337、tests/CLAUDE.md:11 的「兩處放行但必須印出警告」。
   - 建議改法：在 orphan 線上重建 `docs/reviews/CLAUDE.md`（不放 `S*.md`），斷言改成 `said "這次跳過 review 報告檢查"`。

2. A、B 都報｜Important｜⑩ 的 `said "改從共同祖先"`（test-gate.sh:332）同樣被 `owed_dirs` 的警告滿足，證明不了 `reviews_missing` 的退化警告有印出來。
   - 查證：`owed_dirs` 在 check-claude-md.sh:105 以空 prefix 呼叫 `resolve_fork_base`，:89 印出「…？），改從共同祖先 X 算起」，而且比 review 檢查先跑。A、B 的變異（在 :162 的呼叫加 `2>/dev/null`）都是 90 ✅。
   - 連帶影響：scripts/CLAUDE.md:62 的「退化時不印警告 → 2 紅（落在 `said` 斷言上）」只證明了 owed_dirs 那一側，也沒寫「哪個變異讓哪幾則變紅」。
   - 建議改法：改成 `said "review 檢查改從共同祖先"`。修完重跑三組變異，把「變異 → 變紅的情境名稱」寫進 scripts/CLAUDE.md:59-62。

3. B、C 都報｜Important｜test-gate.sh:304 的反事實宣稱是錯的。原文：「沒有這一段的話，把 `--segment-base` 也改成『退到共同祖先』的變異不會有任何測試變紅」。
   - 查證：情境 7 在 test-gate.sh:119 把起點設成 `side`。`side` 是從主線分出去的 commit，跟 HEAD 有共同祖先，所以 :120 的「起點失效時 --segment-base 要失敗」本來就會被這種變異打紅。B、C 把測試截到 ⑨ 為止跑，都得到 1 紅，紅的就是 :120；跑全檔是 3 紅，跟 scripts/CLAUDE.md:60 寫的「3 紅」一致，等於同批文件自相矛盾。
   - 建議改法：刪掉這句，或改成「情境 7 已守住『有共同祖先』這一格；這一段補的是『沒有共同祖先』與 review 那一側」。

4. B、C 都報｜Important｜⑦ 只改了一半。新註解（test-gate.sh:283-285）寫「上面那句註解原本寫『起點 commit 被改寫』…（S4 修正）」，但那句標頭還留在原處。
   - 查證：`git show HEAD:tests/test-gate.sh | sed -n '273,276p'` 印出來，標頭仍是「⑦ 起點 commit 被改寫(amend / rebase)之後…現在退到共同祖先繼續算」。diff 對 ⑦ 只改了 :286 的 expect 說明字串。
   - 建議改法：把 :273-276 的標頭改成「amend 段落內的 HEAD」的真實語意，或把整段歷史敘述移到 ⑩。

5. C 報｜Smells（C 標 Important，我調降：那張表是 S6 標了日期的實測紀錄，這次 diff 沒動到那幾行，但它確實讓表過期了）｜scripts/CLAUDE.md:27 與 tests/CLAUDE.md:33 的「那行 → 永遠 `return 1` | 12」在 HEAD 已不成立。
   - 查證：C 實跑得 15 紅，多出的 3 紅在 ⑩（:331 的 block、:333 的 said、:345 的 base_is）。從程式碼推得通：⑩ 依賴 opt-in 那行為真。這個 15 我沒有自己重跑。
   - 建議改法：兩份表同批標註「S6 當時的快照」，或附上重跑後的數字與產生指令。

6. B 報（C 列為不報的小問題）｜Smells｜⑪ 的清場不完整，而且有誤導。
   - 查證：:340 列了從未建立的 `'api server'`（整份測試只有 `my dir`）。p、r、w、keep、mv、feat、feat2、功能、模組、top.js、my dir 都還留在工作目錄，被 :342 `commit` 裡的 `git add -A` 收進 r7。r7 不是「只有 lone/ 的第一個 commit」，現在能通過只是因為那些目錄剛好都有 CLAUDE.md。
   - 建議改法：用 `git clean -fdq`（或 `rm -rf` 加上列舉）把工作目錄真的清空；同時保留重建 docs/reviews 的步驟（見第 1 條）。

【駁回】
- C 列為既有問題、沒報的：check-claude-md.sh:193 的「範圍 ${base}..HEAD」在退到共同祖先時印的是記下的起點，不是實際範圍；:284 的 `git diff $base` 同理。我回去看了那幾行，`git show HEAD~1` 的同一段寫法一樣，這次 diff 沒複製、也沒擴散這個寫法，所以確實是既有問題，不算本次採納項。值得另開一題。
- B 的 Not reported「⑩ 的 block 分不出退到共同祖先和直接用 r6a 算」：沒有規格說後者錯，同意不報。
- A 的「多個共同祖先時 merge-base 只取一個」：改動前就是這樣，沒變，同意不報。
- `resolve_fork_base` 讀全域 `$base`：沿用既有寫法，沒有失敗情境，不報。可以在函式註解補一句它依賴 `read_base` 設好的 `$base`，屬於選擇性改善。

重構本體方面，A 逐項比對了警告字句、stderr 去向、分支結構、作用域（`range_base` 改成 local 是附帶修正），結論是行為等價。我讀 diff 檔 47-116 的結果一致：兩處警告字句跟改動前逐字相同。

【需使用者決定】
無

【需要外部查證】
- 「S6 的 review 抓到這兩處已經漂移（一處退到共同祖先、另一處直接放行）」與「S6 的 reviewer 預言過（mode 參數）」這兩句歸因（check-claude-md.sh:78、:80，scripts/CLAUDE.md:55-58）。快照的 `docs/reviews/` 只有 CLAUDE.md；`git grep -E '預言|漂移|mode 參數'` 除了這兩個檔，沒有任何相關出處。要讀 S6 的報告原文核對，找不到就照全域 §3.10 改成「我當時這樣預判」。
- 文件寫的「fork-point 整支拿掉 → 7 紅」沒有人重跑核對。修完第 1、2 條之後本來就要重跑三組變異，屆時一併核對。

【結論】
Critical 0 / Important 4 / Smells 2

另外：三個審查者各自在 `/var/folders/.../T/` 留下沒刪的變異暫存目錄（A：`tmp.hTxSzhBY8V`，B：`tmp.lrVFIBXEfv`，C 沒附路徑）。依 §4.2 刪檔要先確認，交由主對話決定要不要清。我沒有改任何檔，也沒有 commit。