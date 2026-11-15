【派工】
我派了 4 個審查者，都是 general-purpose、haiku、effort medium，同一則訊息平行派出，沒有重派也沒有補派：
- 輪1-R1：前提成不成立
- 輪1-R2：漏掉的同步點
- 輪1-R3：範圍與驗證
- 輪1-R4：全面，另看有沒有跳過使用者講定的事

派 4 個的理由：計畫同時動安裝腳本、測試檔、兩份 README、架構文件與 CHANGELOG，牽涉的面比一般單段計畫廣。所以在下限 3 個之外，多派一個做全面審查。

【讀檔檢查】
- 輪1-R1：過。抽查 `install-dd-pipeline.sh` 187–196 的 `backup_before_overwrite`（`[ -e "$target" ] || return 0`、`cp -r "$target" …`），以及 1126–1146 的 uninstall 迴圈 `for plugin in "${OFFICIAL_PLUGINS[@]}"`，兩處都對得上。
- 輪1-R2：過。抽查 `skills/task-planner/SKILL.md` 步驟 5 的「專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，對得上。
- 輪1-R3：過。抽查 `install-dd-pipeline.sh` 528–530（skills 的 `backup_before_overwrite` → `rm -rf` → `cp -r`），對得上。
- 輪1-R4：過。抽查 `install-dd-pipeline.sh:397` 的 `plugin_enabled_state()`，對得上。

4 個都是有效審查者。

【採納（重大）】
（無）

【採納（小事）】
- 輪1-R1-1＋輪1-R3-5｜S1-1 寫「不對所有情況都加 `-L`」的理由是「GNU `cp -RL` 遇到懸空連結回 1」，這個理由放在 target 本身不成立。`[ -e "$target" ]` 會跟著連結判斷，target 是懸空連結時第 189 行就 `return 0`，根本走不到 `cp`。真正的風險在目錄型 target：skills、命名空間指令目錄如果本身是 symlink，`cp -RL` 會把目錄裡每個連結都跟過去，裡面有一個懸空連結，GNU 就回 1，在 `set -e` 下中止安裝。而 T1 只測了檔案 symlink｜計畫要怎麼改：把理由改成「目錄 target 內部可能有懸空連結」。再二選一：給目錄 symlink 加一則測試，或在「測不到、照實記下的」補一行。
- 輪1-R1-3＋輪1-R4-3｜S1-2 定案寫「頂層不是物件 → 兩條路徑都算失敗」，跟 A4 保留 `plugin_enabled_state` 回 `none` 讀起來互相矛盾。T2 又把 `plugin_enabled_state` 放進比對，但沒寫它的預期結論｜計畫要怎麼改：定案那句註明只適用 `install_plugins`、`uninstall`、`mcp_scope`。T2 對 `plugin_enabled_state` 寫明預期是兩條路徑都回 `none`，照 A4。
- 輪1-R1-4｜S2-1 第 6 點「時間與費用」，repo 裡有幾組口徑不同的數字：
  - `docs/measurements/2026-10-23-reviewer-real-sessions.md` 的單一 code-reviewer 中位 11.8 分，n=311
  - 同一檔「結論」裡 G2／G3 整發的倍數
  - `skills/dd-loop/SKILL.md` 的 2026-10-24 整個步驟 4 對照（269s、5.13 美元，作者自註「n 小」）

  另外 `README.md:104` 已經有「至少三個審查者」那一段，也引了同一份量測｜計畫要怎麼改：每個數字註明它量的是什麼（單一審查者還是整個步驟 4）。並寫明要補在 `README.md:104` 那一段附近，不另開重複的段落。
  - 不列重大的理由：照做不一定會寫錯，計畫已要求附日期、樣本數與檔名，逐句核對表也會對原文。
- 輪1-R2-1＋輪1-R3-1＋輪1-R4-1｜計畫沒寫要在根目錄 CLAUDE.md 加「進度以 docs/designs/… 為準」的指路句｜計畫要怎麼改：在設計文件那段明寫「同批在根目錄 CLAUDE.md 第一個 `##` 前加指路」。
  - 不列重大的理由：task-planner 步驟 5 的寫檔流程本來就把這句列為必做，計畫並沒有要求不加。
- 輪1-R2-5｜S1 的驗收「等價表探針 92 例不一致數從 16 變 0」，依據的探針在 scratchpad、不在 repo，下一個 session 重跑不了｜計畫要怎麼改：驗收改成「T2（repo 內）在修之前紅在那 16 例、修之後全綠」，探針只當背景。
- 輪1-R3-3＋輪1-R4-5｜驗收只有本機 macOS 跟 debian 容器裡 `cp` 的重現。T2–T9 在 GNU 上要等使用者 push 後 ubuntu job 跑了才知道，而本機已經比公開版多 34 個 commit 沒在 ubuntu 跑過（F15）｜計畫要怎麼改：在驗收或假設註明「ubuntu job 的結果要等使用者 push 後才看得到」。可選做法：在容器裡用 apt 裝好 jq 與 python3，先跑一次 `tests/test-install.sh`。
- 輪1-R3-4｜S1-3 的變異只寫「把對應的那一行改壞」。`tests/CLAUDE.md`「此層約束」要求選對變異方向，全域 §3.9 要求記下「哪個變異 → 哪幾個情境變紅」｜計畫要怎麼改：T3–T7 每組寫明要改哪一行。結果記成「變異 → 變紅的情境」對照，寫進 `tests/CLAUDE.md` 的 `test-install.sh` 那一列。

【駁回】
- 輪1-R1-2｜T1 在本機修之前就是綠的｜計畫已經安排在 debian 容器呼叫真的 `backup_before_overwrite` 取紅與綠。
- 輪1-R1-5｜「你自己裝的也一樣」會被讀錯｜這是計畫內的說明，不是 README 原文。它講的就是 `OFFICIAL_PLUGINS` 列出、但使用者自己手動裝過的那幾個，跟 1126–1146 的迴圈一致。
- 輪1-R1-6｜self-improving-agent 的 hook 寫成無條件｜計畫的開工前提 3「什麼時候會插提醒」已經安排查這件事。
- 輪1-R1-7｜hook 是否真的全域載入（原列外部查證）｜開工前提 3 已安排。另外本 session 跑 Bash 時，這個 hook 實際插了一則 `<error-detected>` 提醒，可以當載入的證據。
- 輪1-R1-8＋輪1-R3-6｜`jq -e` 對空輸入的 exit code 沒有實跑過｜確切是 4 還是 1 無關緊要，任何非 0 都會走失敗分支。計畫也要求 T2 先在現行程式碼上紅在那 16 例，碼對不上時會大聲紅。
- 輪1-R2-2＋輪1-R3-2｜沒排步驟 3–8｜task-planner「進度表格式」的規則區塊（照抄進設計文件）已規定小任務全部 commit 後整段跑步驟 3–8。
- 輪1-R2-3＋輪1-R4-2｜沒排 `--start-segment` 與 `IN_PROGRESS`｜同一個規則區塊的「開工」那條已規定。草稿表一律從 `TODO` 開始，是格式本來就這樣。
- 輪1-R2-4｜四節裡沒有規則區塊｜task-planner 規定規則區塊放在「進度表」這一節裡整段照抄，四節的說法沒有漏掉它。
- 輪1-R2-6｜CHANGELOG 連結要標 *(Traditional Chinese)*｜計畫沒有要新增連向 CHANGELOG 或 UPGRADING 的連結，沒有證據。
- 輪1-R2-7｜ci.yml 20 個 step 沒依據｜實測 lint job（ubuntu）是 20 個 `- name:`、macOS job 是 6 個，跟 F14 一致。
- 輪1-R2-8｜claude-md-management 沒有確認 `version` 欄位（原列外部查證）｜README 寫的手動安裝指令跟 `version` 欄位無關。安裝腳本取不到版本時印的就是同一條指令（F16）。
- 輪1-R4-4｜新增文字沒有逐條判必要性｜使用者講定的範圍是「精煉規則文件」，也就是刪減、縮短，不是新增說明。
- 輪1-R4-6｜T1–T9 有沒有經過使用者選定（原列外部查證）｜task-planner 步驟 4 規定 plan-review 結束後才問測試清單題，計畫已經安排。

【需使用者決定】
（無）

【需要外部查證】
- 輪1-R3-7＋輪1-R4-7｜小事｜ubuntu-latest runner 有沒有預裝 jq 與 python3（T2 兩條路徑都要用到）。查不到的話也只會在 CI 大聲紅，不是不報錯的錯。

【結論】
通過
