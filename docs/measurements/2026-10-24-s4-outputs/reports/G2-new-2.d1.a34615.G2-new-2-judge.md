**裁決報告：S4 diff（4 檔）的步驟 4 code-review**

【派工】
派了 3 個 code-reviewer，在同一則訊息裡平行派出，都不帶 model 參數。每個拿到的 prompt 都含原樣轉達的「只准讀這些路徑」整節、diff 檔路徑與「被改到的檔讀 diff 檔那一份」、「範圍與已跑過的驗證」整段、各層 CLAUDE.md，以及職責：找漏洞、每條附證據、沒證據不算、外部查證列出來交回。
- A：gate 重構是否行為等價。項目包括警告字串逐字比對、exit code、stdout/stderr 分流、對全域 `$base` 的依賴，以及 `--segment-base` 是否真的硬失敗。
- B：新情境 ⑩⑪ 有沒有鑑別力。看 `said` 會不會被別的訊息命中、走到哪個分支、`base_is` 放的時機、orphan 分支清理；並在拋棄式副本實跑 scripts/CLAUDE.md 宣稱的 3/7/2 紅。
- C：註解與文件的宣稱在 HEAD 是否成立。項目包括識別符 git grep、新表格逐格核對、歷史歸因有無依據、標點慣例、根 CLAUDE.md 的同批同步清單。

數量理由：diff 有三類性質不同的東西（重構、測試、文件宣稱），一類一個是下限。3 個全部回來，沒有失敗、不需補派。

【採納】
1. A、B、C 三方都報｜Important（C 標 Critical，我降一級）｜情境 ⑪ 的 `--start-segment` 根本沒跑到 `reviews_missing` 的「連共同祖先都沒有」分支，是為了錯的理由通過。
   - 我的查證：
     - test-gate.sh:340 的 `rm -rf … docs …` 刪掉了 `docs/reviews`，之後沒有重建。
     - `reviews_missing` 在 check-claude-md.sh:151 的 `[ -d docs/reviews ] || return 1` 就直接返回。
     - 剩下的 `said "找不到共同祖先"`（test-gate.sh:349）吃到的是 `owed_dirs` 在 check-claude-md.sh:108 印的「…也找不到共同祖先，這次只檢查 staged」。`--start-segment` 先跑 `owed_dirs`（:183），才跑 `reviews_missing`（:191）。
     - 我自己在拋棄式副本做變異：刪掉 :165 那行警告（`grep -c` 確認剩 0），結果 exit=0、90 ✅、0 ❌，跟 A/B/C 的 M1 一致。B、C 另外跑了「改成 `return 0`」的變異，同樣 90/0。
   - 波及兩處宣稱，在 HEAD 都不成立：
     - tests/CLAUDE.md:11「連共同祖先都沒有時：兩處放行但必須印出警告」。
     - test-gate.sh:336-337 說要防「第一版靜默通過」。
   - 降級理由：gate 本身的行為是對的，錯在測試與文件把一個沒測到的分支說成「已覆蓋」，沒有實際放錯或擋錯。但不修不能續行。
   - 建議改法：
     - ⑪ 在 r7 之前重建 `docs/reviews/`，放 `CLAUDE.md`，不放 `S*.md`。
     - `said` 改斷言 `reviews_missing` 獨有的字串「這次跳過 review 報告檢查」。
     - 修完重跑上述兩個變異，確認會紅。scripts/CLAUDE.md 的變異清單補上這一組。

2. B、C｜Important｜情境 ⑩「reviews_missing 退到共同祖先，照樣擋」分不出「退到共同祖先」跟「直接拿失效的起點算」。
   - 我的查證：
     - `said "改從共同祖先"`（test-gate.sh:332）會先被 `owed_dirs` 以空 prefix 印出的 check-claude-md.sh:89 那句命中。
     - B 的推論成立：`r6a..r6c` 裡 S9-a.md 是刪除、不是新增，所以兩種算法都會擋。
     - B、C 的變異「`range_base=$base`，不走 `resolve_fork_base`」都是 90/0。A 的 M3（prefix 改成空字串）也是 90/0。
   - 建議改法：斷言帶前綴的「review 檢查改從共同祖先」。另外設計一組只有退到共同祖先才會擋的資料，例如報告在 fork 之後、起點之前新增。

3. C｜Important｜test-gate.sh:283-285 的新註解有三處跟 HEAD 不符。
   - 我的查證：
     - (a) 註解說「上面那句註解原本寫『起點 commit 被改寫』」，暗示已改掉，但 :273 的 `# ⑦ **起點 commit 被改寫(amend / rebase)之後…` 原封不動，diff 只改了 :138 那一行 expect。
     - (b) 「走的是 `range_base="$base"` 那一支」：這行在本次 diff 已刪掉（diff.txt:106-107），現在對應的是 `resolve_fork_base` 裡的 `echo "$base"`。
     - (c) 「真正把起點改寫掉的情境在最後面 ⑩」：⑩ 是 `git checkout -b sideline "${BASE_BEFORE}^"`，換分支而不是改寫起點；整支測試沒有任何一則真的 amend 或 rebase 起點 commit。
   - 建議改法：把 :273-276 ⑦ 的標題改成跟實際相符；(b) 改成指向 `resolve_fork_base` 的第一支；(c) 改成「起點不在目前歷史的情境（切分支模擬）在 ⑩」。

4. C｜Smells（C 標 Important，我降一級）｜「S6 的 reviewer 預言過」在快照裡找不到依據。
   - 我的查證：`git grep -e '預言' -e 'mode 參數'` 只命中這次新加的兩處，scripts/CLAUDE.md:58 與 check-claude-md.sh:77-78。快照 docs/reviews/ 只有 CLAUDE.md。
   - 降級理由：在快照裡無從證偽也無從證實，屬於「需要外部查證」。內容是設計理由的歸屬，不影響行為。
   - 建議改法：查到原文就附出處（報告路徑或 commit hash）；查不到就改成「我當時這樣預判」。

5. B（他放在 Not reported，我採納）｜Smells｜⑪ 的清理清單過期。
   - 我的查證：test-gate.sh:340 刪的 `'api server'` 整支測試從沒建過（`grep -n "api server"` 只有 :340 本身）；p/、r/、w/、keep/、feat/、feat2/、功能/、模組/、my dir/、top.js 都沒清，會被 r7 一起加回。
   - 依 B 的判斷，各目錄都帶自己的 CLAUDE.md，不影響結果；但「無關歷史上只有 lone/」這個前提不成立。
   - 建議改法：改成 `git rm` 之後 `git clean -fdx`，或者列出實際存在的路徑。

【駁回】
- A、B、C 都判定 `resolve_fork_base` 跟舊的兩段 inline 寫法行為等價，我同意，不構成發現。我的查證：
  - prefix 為空與 "review 檢查" 時，check-claude-md.sh:89 跟舊 diff.txt:86、109 逐字相同。
  - local 與賦值分開寫，exit code 不受影響。
  - 警告走 `>&2`，不會被 `$(…)` 吃進去。
  - 兩個呼叫端在呼叫前都已經 `read_base` 設好 `$base`（:183、:153）。
- B 提到 7 紅裡有 1 紅是連鎖造成的：數字本身正確，「同時打破兩個呼叫端」也成立，不報。
- A 提到 `--start-segment` 擋下時印的 `範圍 ${base}..HEAD`（:193）在退到共同祖先時不準：這行本次 diff 沒動，是既有問題，不在範圍內。值得另開一個小修。
- C 提到全形與半形標點混用：S6 段落早就是半形，是既有的混用，不是這次引入的。
- C 提到根 CLAUDE.md 的同批同步清單（README、ARCHITECTURE、CHANGELOG）：警告字串逐字沒變，gate 行為也沒變，不觸發。

【需使用者決定】
無

【需要外部查證】
- S6 的原始審查報告（快照外的 `docs/reviews/S6-*.md` 或當次紀錄）有沒有「加 mode 參數只是把同一個決策搬進函式」的原文。這決定採納 4 那條歸因能不能留。
- 審查者 A 留下拋棄式目錄 `/var/folders/lt/4prh2d3n2bs54832ml_d1xdm0000gn/T/tmp.Tq4beEybu0`。刪除要先確認，所以我沒動，請主對話決定要不要清。我自己的變異副本已經清掉。

【結論】
Critical 0 / Important 3 / Smells 2（採納數）

3 條 Important 都要先修才能續行。第 1、2 條修完要用對應的變異實跑確認會紅。我沒改任何檔、沒有 commit。