三份審查回報裡，有 1 條 Critical 0、Important 2、Smells 1 成立，另外 3 條駁回。本身沒改任何檔，也沒 commit。

【派工】
派了 4 個 `code-reviewer`（haiku），同一則訊息平行派出，全部回來了。用 4 個是因為這份 diff 有四塊性質不同的東西，各需要不同的查法：
- A：`tests/test-gate.sh` 新增的繞過區塊與 ⑦ 的 amend 改動，對照 gate 實際邏輯看斷言有沒有鑑別力。
- B：文件宣稱與程式碼對不對得上，包括 `scripts/CLAUDE.md` 的變異表、`tests/CLAUDE.md` 的計數 grep、`test-gate.sh` 註解裡引用的別處。
- C：`worktree-manager` 收尾段，要在拋棄式 repo 實跑 git 驗證。
- D：規則文字本身的一致性：§3.5 對照 §3.9 與 verification-gate、要不要同步到其他檔、CHANGELOG 格式、vendor intake 總則插入的位置。

【採納】
1. A｜Important｜「繞過①：段落內零報告的正常 commit 放行」(`tests/test-gate.sh:320`) 放在段落的第一個 commit 上。這時 HEAD 等於起點，gate 第 165 行 `[ "$base" = "$head_sha" ] && return 1` 會直接放行，所以就算 pre-commit 改成也查報告，這一則單獨跑也不會紅。
   - 查證：我在 `/tmp/judge.36OU` 跑了整支測試，用的變異是「`staged=`（第 238 行）下面加 `reviews_missing && exit 1`」。繞過① 確實紅了，但紅的原因是前面「重記起點(起點 = by0)」先被擋下，`base_is` 顯示起點還停在舊值，於是 HEAD 不等於起點。也就是說它是連鎖紅，不是自己測出來的。A 的最小重現（乾淨狀態）結果是 by1 rc=0、by2 rc=1，和讀程式碼推出來的一樣。
   - 影響：`scripts/CLAUDE.md` 變異表第 1 列寫「繞過①是具名的那一則」，這個歸因與實際的鑑別來源不符。
   - 建議改法：by1 之後再加一個段落內零報告的 commit（例如 by1b），把繞過①的斷言移到它身上。然後在「起點正確」的狀態下重驗 m1 會讓這一則變紅，再修正變異表那一列的描述。
2. 裁決者自查｜Important｜§3.5 新增的括號 (`templates/global/CLAUDE.md:195`) 寫「判定變異版有沒有被抓到仍照 §3.9 鑑別力測試那條：不等於固定版的輸出就算紅」，這和同一批 diff 的另外兩處衝突：
   - 第一處：§3.9 對鑑別力測試的定義就是「改回舊版確認會紅」(:364)。verification-gate 新寫的 `git stash -u && <測試>`（「紅的是原本那個 bug」）正是改回舊版。結果同一個動作，§3.5 說「不等於就算紅」，SKILL 說「要紅在原本的 bug」。
   - 第二處：§3.9 第 364–370 行沒有「載入失敗不算」的但書。所以照括號的寫法，一個讓 import 或語法壞掉的變異也能算「抓到了」，這正是這次要擋的假紅。
   - 建議改法：§3.9 鑑別力那條補一句「不等於必須來自被測的東西給出錯的結果；載入失敗、import 壞掉、資料沒建起來不算」，§3.5 的括號改成指向它，不要把變異版排除在外。CHANGELOG 第 17 行的轉述同批改掉。
3. D｜Important｜§3.5 只定義了修 bug 時「應該怎麼紅」（錯的值），沒講新功能。新功能第一次跑時「找不到函式」這種 ImportError，和規則點名要排除的「import 路徑寫錯」長得一模一樣，讀的人判斷不出算不算。
   - 查證：`templates/global/CLAUDE.md:193-195` 和 `skills/verification-gate/SKILL.md:57-59` 都只舉了修 bug 的情況。
   - 建議改法：補一句「新功能還沒寫時，找不到函式不算；先放一個回錯值的空殼，讓它跑到斷言」。
4. B｜Smells（從 Important 降級）｜`tests/test-gate.sh:343` 寫「tests/CLAUDE.md 的『恆真斷言』那條」，但實際標題是「一個「恆真」的斷言比沒有斷言更糟」(`tests/CLAUDE.md:42`)。
   - 降級理由：`grep 恆真 tests/CLAUDE.md` 只命中這一處，指的是對的東西，只是措辭不同，不會把人引到錯的地方。
   - 建議改法：引用時照抄標題原文。

【駁回】
- A｜Smells｜說「先補完再記新起點：兩個擋點的訊息都有」這句註解（`test-gate.sh:344`）錯了。
  - 駁回理由：gate 第 195 行「❌ 還有 commit 跳過檢查、…，先補完再記新起點」與第 204 行「❌ 上一段沒有附 review 報告…，先補完再記新起點」兩句都含這個字串。註解的意思是「所以 said 改挑只有欠帳擋點才印的『還有 commit 跳過檢查』」，內容正確，是 A 讀錯了。
- C（Not reported）｜`WORKTREE_INFO.md` 每次都出現在 `??` 是過度概括（若被 gitignore 會變成 `!!`）。
  - 不報理由：落到 `!!` 時照樣會被刪掉，而這本來就是建議的處置，不會造成錯誤結果。
- C（Not reported）｜`allowed-tools` 沒列 AskUserQuestion。
  - 不報理由：建立流程原本就在用它，是既有狀況。根目錄 CLAUDE.md 也寫明 `allowed-tools` 是預授權、不是白名單，漏列只會多問一次權限。
- B 的三列變異實測與 C 的 git 2.42.0 實跑（` M`、`A `、`??` 會被拒絕，`!!` 會被直接刪掉、不提示）都和文件相符，不算發現。另外我數了 m1 輸出的判定行，`grep -cE '^(✅|❌ .*：(預期 |輸出裡有 shell 錯誤))'` = 105，和固定版一樣，證明 ⑦ 包進 `expect` 之後整支確實跑完了。

【需使用者決定】
採納第 2 條要往哪個方向修：
- A）§3.9 補上「載入失敗不算」的但書，§3.5 的括號指向它，verification-gate 不用動。
- B）保留 §3.5 對變異版的排除，把 verification-gate 那句改成只看「有沒有紅」。

建議選 A：B 等於把這次要擋的假紅放回變異測試裡。

【需要外部查證】
- 「git 2.54.0 實測」(`worktree-manager/SKILL.md`、CHANGELOG)：本機只有 2.42.0，C 只驗了這一版。
- pstack-claude 的授權：根目錄 CLAUDE.md 規定只借概念時「授權仍要處理」。現在 verification-gate 第 9 行有寫來源，worktree-manager 只在 CHANGELOG 寫了；要看對方的 LICENSE 才能定案。

【結論】Critical 0 / Important 3 / Smells 1（採納數）

補充：
- 四位審查者的完整報告（含 Not reported、What I ran）都在我這輪的對話裡。這次的說明規定不准寫檔，所以沒落地成 scratchpad 檔，主對話要歸檔時得自己存。
- 實驗留下 `/tmp/judge.36OU`（m1.sh、m1.out），沒有刪。
- A、B、C 在 `/tmp` 下也有各自的拋棄式目錄（例如 `/tmp/gate-exp.*`、`/tmp/wt-exp.2a1Eg8`、`/tmp/wt-exp2.yMjb37`），沒有清。