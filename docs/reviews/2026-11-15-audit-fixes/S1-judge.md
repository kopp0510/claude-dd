# S1 步驟 3、4：主對話的查證

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S1。

## 派工

- 範圍：`git diff 9d77062`（表上這段的起點）到工作目錄。HEAD = 5ec112d，5 個 commit（S1-1、S1-2、S1-3 兩個、S1-4），加步驟 3 還沒 commit 的改動。
- 不跳過：這一段改的是擋 commit 的 gate，文件裡又有大量引別處的宣稱（變異結果、情境編號、別的檔的行為）。
- 步驟 3、4 依序跑：並行時審查者讀的是 HEAD 版，看不到 simplifier 對 gate 的改動。
- 派 3 個 `code-reviewer`（下限，不帶 model 參數）：三個方向對上這段的三類東西 —— A gate 腳本、B 測試的鑑別力、C 文件與註解的宣稱。審查包 1596 行，沒有多派。
- 派工 prompt 只交事實（三處行為、審查包的組成、已跑過的驗證與預期值），沒有寫我對哪裡可能有錯的判斷。

## 發現

### 步驟 3（code-simplifier）

只給 `scripts/check-claude-md.sh`、`tests/test-gate.sh` 在這一段的 diff，寫明六條不能動的（`--segment-base` 不併進 `resolve_fork_base`、四種失敗維持 exit 1 與 stdout 空、被 `said`／`not_said` 釘住的字串不改字、`dd.docfile` 新檢查留在 `CODE_EXT` 之後、`${var}`、不增減測試情境）。
它只改了一處註解：`--segment-base` 那一支的註解寫「三種」，程式碼有四個失敗出口，改成「四種」並列出來（+3 −2 行）。
我的驗證（不看它自述）：`git diff` 只有那一處；`/bin/bash tests/test-gate.sh` rc=0、146 個 ✅、0 個 ❌；`shellcheck -S warning` 無輸出。

### 步驟 4

三份都完整交回（都有發現、Not reported、What I ran、需要外部查證）。讀檔檢查：每份我都重跑了它至少一條指令或讀了它引的位置，都對得上。

- 採納（全部）：
  - Important：B1（`tests/CLAUDE.md`「這一段」指錯對象）、C1（`scripts/CLAUDE.md` 說 dd-loop 已經照訊息分情況，其實還沒）、C2（寫成 amend 也比過 `git rev-list`，其實沒比）
  - Smells：A-S1＝C-S3（不是空樹的 tree 走錯訊息）、B-S1（`stdout_empty` 只測一支）、B-S2（「也找不到共同祖先」那行沒釘住）、B-S3（共用尾段的「不要重跑」與「它只是申報」沒釘住）、B-S4（繞過④ 沒有標籤）、C-S1（grep 錯誤字串只在 macOS 是那樣）、C-S2（「git 裡零痕跡」說過頭）、C-S4（`notes.sh` 那則在 M1 下為了錯的理由綠）
  - 級別照審查者標的，沒有調級。
- 駁回：無。
- 需使用者決定：無。
- 需要外部查證：C 列的一條（GNU grep 的錯誤字串）自己在 ubuntu:24.04 容器查了，結果在 `S1-c.md` 的處置。

## 處置

逐條的處置在 `S1-a.md`、`S1-b.md`、`S1-c.md`。修完之後：

- `/bin/bash tests/test-gate.sh`：rc=0、150 個 ✅、0 個 ❌（審查前 146 個）。
- 變異從修完的版本重做，每個只改一處，固定版與各變異版的判定行數相同；哪個變異紅在哪幾則記在 `scripts/CLAUDE.md` 的兩張變異表（`dd.docfile` 那張與退化政策那張）與「第 3 條」那個條目。
- 步驟 5 的結果（macOS、ubuntu 容器、本機照 ci.yml 逐 step 跑）寫在設計文件「段落與小任務」S1 底下。

## 重疊與獨有項

- 重疊：不是空樹的 tree 走錯訊息（A-S1、C-S3，兩個都實跑重現）；`notes.sh` 那則的鑑別力（B 放在 Not reported、C 列為 S4，判斷不同 —— 讀測試後照 C 的做法改，改完那則自己有牙）。
- A 獨有：`dd.docfile` 不合法時錯誤句印在 stdout（它放在 Not reported；我補了文件上的例外說明）。
- B 獨有：B1，以及四條「新分支的某一行沒有被任何斷言釘住」（S1–S4）。這一類只有逐則對照測試與 gate 的行號才看得出來，我自己的變異只打了我想到的那幾行。
- C 獨有：C1、C2 兩條都是我寫的時候沒有回頭核對的宣稱（一句講別的檔的現況、一句講自己跑過什麼），以及 grep 訊息的平台差異、「零痕跡」的措辭。

## 這一段自己犯的錯（給步驟 7）

- 測試字串以 `-` 開頭被 grep 當成選項，修之前的紅燈看起來像正確的紅燈。
- 寫「四種都比過」時把「測試跑過這個情境」當成「比過 rev-list」。
- 寫「它照這幾句分情況」時描述的是計畫做完之後的狀態，不是當下的狀態。
- 給使用者的選項說明裡，「加申報檔」的取捨寫得比實際嚴重（回頭做完那段有沒有補跑審查，gate 其實查得到一部分）；實作時才發現，已在設計文件與 `scripts/CLAUDE.md` 更正。
