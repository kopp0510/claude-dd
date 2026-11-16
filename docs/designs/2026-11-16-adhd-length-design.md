# ADHD output style 加長度上限

使用者說開著 ADHD 風格還是給一堆字。量測後確認風格檔沒有任何一條限制長度，這一段把上限加進去並實測。一段（S1）：沒有 task 工具，照全域 §4.4 用進度表記進度。

## 來源

使用者的話（逐字）：

- 2026-11-16：「我發現 output-style ADHD, 這個 回答一點都不適合給ADHD, 還是給我一堆字 要我閱讀一堆」
- 2026-11-15：「你的回應都很長 把我當作ADHD 我今天很累 不想看太多字」
- 2026-11-14：「太多字, 再整理回給我」
- 2026-10-29：「你的回答都太攏長, 跟你說我有adhd 你才會精簡」「我要你 把我當作是adhd患者 來回覆」

## 動手前量到的

- `output-styles/adhd.md`（起點 `7e1ff44` 那一版，48 行）全檔沒有行數或字數上限。第 7 行寫「回答不只是要短，而是要排成…」；「誰優先」寫 CLAUDE.md 的規則「位置與內容不因下面任何一條而刪掉」；規則 9 寫「需要完整時照實全列」
- 2026-10-29 那批驗收的回覆長度，開風格與沒開差不多。指令：`jq -r 'select(.kind=="result")|.result|length' docs/measurements/2026-10-29-adhd-style/out/*.jsonl`，依檔名順序得 499、592、347、297（ADHD 臂的 p1-r1、p1-r2、p2-r1、p2-r2）與 550、620、313、391（default 臂同序）。那支 `check.sh` 的三條鑑別斷言沒有一條量整則的長度
- 使用者最近三個 session 的回覆長度。來源是本機 `~/.claude/projects/` 下這個專案目錄的 jsonl（不進 repo）。判定式：主對話（`isSidechain` 不為真）的 user 訊息裡，內容是純文字、而且不是以 `<`、`Base directory`、`Another Claude`、`This session is being`、`Skill /`、`[Cross-session`、`# DD` 開頭的，算使用者親手打的一輪；每輪取下一個使用者訊息之前最後一則有文字的 assistant 訊息，數非空行與字元（python `len`）：

| session（檔名前 8 碼） | 輪數 | 非空行中位數 | 字元中位數 | 超過 10 行的輪數 | 超過 20 行的輪數 |
|---|---|---|---|---|---|
| f691d75a | 15 | 15 | 814 | 12 | 4 |
| 00b8a3cc | 24 | 11 | 482 | 12 | 6 |
| 4056f6e9 | 43 | 13 | 606 | 25 | 11 |

  這三個 session 各自有沒有開 ADHD 風格沒有逐一核對（這個專案的 `.claude/settings.local.json` 在 2026-11-16 是 `outputStyle = ADHD`）
- 樣本：使用者問「現在分數多少」，回覆 19 非空行、1040 字元 —— 第一行是答案，後面是算法、一張 5 列的表、另外兩節清單、下一步
- 專案層風格檔會被載入（Claude Code 2.1.325，haiku，各 1 發）：沙盒放 `.claude/output-styles/zebra.md`（內容要求第一行寫 `ZEBRA-7`），`--settings '{"outputStyle":"Zebra","advisorModel":""}'` 的回覆第一行是 `ZEBRA-7`；`outputStyle` 給不存在的名字時沒有那一行
- 新版 P3 的 fixture 試跑 1 發（haiku、沒開風格、`--permission-mode dontAsk --allowedTools "Read Edit Write Glob Grep Bash(bash test.sh)"`）：`permission_denials` 0 筆、`bash test.sh` 是單獨一條、缺的六個檔沒被建出來、事後在沙盒跑 `bash test.sh` 得 `RESULT ok=2 missing=6`；回覆把六件做不完的寫成「e.txt ～ j.txt 不存在」的範圍寫法

## 假設與設計決定

- A1 「一則最多 10 行」這個數字是主對話定的，使用者沒有講過。依據：2026-11-15 之後主對話照「結束回報十行以內」回覆，同一個 session 之後的回覆 5 到 6 行，使用者沒有再抱怨。使用者可以改
- A2 不改全域模板（使用者 2026-10-29 的決定，記在本機 memory）。所以上限只寫在風格檔，沒開風格時不受影響
- A3 上限會讓出位置的只有六樣（「長度」第 4 條）：不確定或沒驗證的事、要讀者決定或動手的事、出錯的事、沒做完的事、驗證的實際輸出關鍵那一行、CLAUDE.md 要求逐項列出的清單。原本那句「位置與內容不因下面任何一條而刪掉」保護的是 CLAUDE.md 要求的全部內容，等於每一樣都不能縮，所以沒有保留，改成逐項保護（計畫審查第 1 輪重大 2 的改法沒有照字面採用，理由就是這個）
- A4 「解釋」「為什麼」不再是放寬長度的觸發詞，只有「詳細」「完整」「帶我走一遍」是
- A5 驗收不部署：兩臂的風格檔都放沙盒的專案層，不動 `~/.claude/`。部署由使用者自己跑
- A6 `DD_OUTPUT_STYLES` 不動：沒有新增或改名風格檔
- A7 計畫審查（`plan-review`）三輪：第 1 輪不通過（2 條重大）、第 2 輪不通過（1 條重大）、第 3 輪通過。紀錄在本檔最後一節

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | 風格檔加長度上限並實測 | IN_PROGRESS | — | `docs/measurements/2026-11-16-adhd-length/selftest.sh` 全部如預期；`check.sh out/batch<最後一批>` exit 0；LICENSE 引句 `grep -F` 全中；`tests/test-install.sh` 過 | 7e1ff44.. |

- 狀態只有 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`；同一時間最多一段 `IN_PROGRESS`
- 下一段：由上往下第一個 `TODO`，而且它依賴的段落都已 `DONE`。有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段
- 開工：`~/.claude/scripts/check-claude-md.sh --start-segment` 記起點；這段標 `IN_PROGRESS`，commits 欄先填 `<起點>..`（短 SHA；起點是空樹時填它印出的完整 SHA；回頭做 `BLOCKED` 過的段落時，欄裡原本的起點保留不改）；該段有「開工前提」就先查完，結果寫進「段落與小任務」該段底下。這些改動跟第一個小任務的 commit 一起送
- 每個小任務：照「段落與小任務」列的做，實作、驗證、commit，commit 訊息第一行結尾帶編號（例如 `（S2-1）`）。可用 `SKIP_DOC_CHECK=1` 先跳過 CLAUDE.md 檢查，gate 會記帳。測試照文件裡的測試清單加；想加清單以外的測試，先問使用者
- 小任務 commit 了不等於段落完成。小任務全部 commit 完，而且 SKIP 欠下的 CLAUDE.md 都補上了，才對整段跑步驟 3–8，範圍從表上這段的起點算。最後一個小任務用正常 commit；補 SKIP 改過的目錄的 CLAUDE.md 時，用 `git diff <起點> -- <目錄>` 看整段改了什麼，不要只看這次 staged 的（gate 只查 CLAUDE.md 有沒有一起送，不查寫了什麼）。步驟 6、7、8 的 commit 訊息第一行結尾帶段落編號（例如 `（S2）`）
- 標 `DONE`：步驟 3–8 全部跑完才標；commits 欄補上終點（標 `DONE` 之前最後一個 commit 的短 SHA，所以標 `DONE` 的 commit 自己不在範圍內），跟步驟 7、8 的 commit 一起送，7、8 都沒改檔就單獨開一個 docs commit。標到表上每段都 `DONE` 的那個 commit，刪掉根目錄 CLAUDE.md 的指路那段
- 接手：`IN_PROGRESS` 那段就是目前這段。拿「段落與小任務」的清單對 `git log --oneline <表上這段的起點>..HEAD` 裡結尾帶 `（S2-` 的 commit（不加範圍會對到別份文件的同編號 commit）。
  **前綴是「這一段自己的 ID 加一個 `-`」**，不是固定字串：插隊進來的 `S2.5` 要找的是 `（S2.5-`，
  拿 `（S2-` 去比對不到它，拿 `（S2` 又會把 S2.5 的 commit 誤算成 S2 的，還沒 commit 的小任務先做完。小任務都做完了，再看同一範圍裡有沒有帶 `（S2）` 的 commit：有，代表步驟 6 之後的步驟做到一半；沒有就從步驟 3 開始
- `BLOCKED` 用在這段要先停：外部卡住（等使用者決定、環境壞了），或使用者要先做別的事（別段、臨時修 bug）。狀態格寫 `BLOCKED` 和原因，外部卡住時停下來問使用者。先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md（不然 `--start-segment` 會拒絕）；專案有 `docs/reviews/` 目錄時，先停還要 commit 一份申報檔 `S<段落>-BLOCKED.md`（跟進度表標 `BLOCKED` 的改動、補的 CLAUDE.md 放同一個 commit）—— 這段還沒有 review 報告，少了它 `--start-segment` 一樣會拒絕。申報檔寫明停在哪個小任務、為什麼停、先停之前已經 commit 的範圍；放的位置照專案 `docs/reviews/CLAUDE.md` 的規定，專案有好幾張進度表時放這張表自己的子目錄、不要放進別張表的，寫之前先 `ls`（要的是新增的檔，蓋掉或改既有的不算）；同一段第二次先停另建 `S<段落>-BLOCKED-2.md`。回頭做這段時，範圍一樣從表上這段的起點算，步驟 4 照跑、報告照落地（`-BLOCKED.md` 只是申報，不算報告）。依賴還沒完成的段落維持 `TODO`
- 做到一半冒出新工作：先問使用者，同意才加一列 `TODO` 排進該在的位置；ID 不重編，插在中間用 `S2.5`。
  **同一批要在「段落與小任務」補上這一段的小任務**（名稱、要動的檔案、驗證方式、commit 訊息）——
  只加表上那一列的話，接手的 session 照上面「接手」那條去對 commit，清單本來就是空的，
  它會判定「小任務都做完了」而直接跳到步驟 3，整段程式碼從頭到尾沒人寫。
  沒有小任務條目的段落不得標 `IN_PROGRESS`
- 每列一行，細節寫進 commit 訊息

（本 repo 記起點用 repo 這份 `scripts/check-claude-md.sh --start-segment`，見根目錄 CLAUDE.md「開發本 repo」。）

## 段落與小任務

### S1 風格檔加長度上限並實測

- S1-1 判準定案：`docs/measurements/2026-11-16-adhd-length/` 的 `check.sh`、`selftest.sh`、`run.sh`、`CLAUDE.md`；本檔；根目錄 CLAUDE.md 的指路句。
  驗證：`selftest.sh` 全部如預期、三支腳本 `bash -n` 與 `shellcheck -S warning` 過、`run.sh` 用假的 `claude` 乾跑一次（管線、去識別、`outside`、`actual`）。
  commit 訊息結尾 `（S1-1）`
- S1-2 換 `output-styles/adhd.md`，跑 `run.sh`（2 發載入探針加 12 發），`check.sh out/batch<N> > out/batch<N>/check.out`，去識別掃描回 0 筆；通過之後才改：
  `README.md` 與 `README.zh-TW.md`「指令一覽」`/output-style ADHD` 那一列、`output-styles/LICENSE.txt` 逐節去向、`CHANGELOG.md` 未發布區塊既有的 `### Changed`、`DD_PIPELINE_ARCHITECTURE.md`「部署清單」ADHD 實證來源那句後面加一句（保留 2026-10-29 的來源）。
  驗證：`check.sh` exit 0；LICENSE.txt 逐節去向裡用「」引、而且說是 adhd.md 裡的句子，`grep -F` 新版都找得到；`tests/test-install.sh` 過（只確認 `name: ADHD` 與部署沒被改壞，不驗內容）。
  commit 訊息結尾 `（S1-2）`
- 不通過時：只改風格檔措辭，判準不動，兩臂整組重跑（新的批次編號，上一批的 `out/batch<N>/` 先 commit）；最多 3 批，第 3 批還不過就停下照實回報，不放寬判準
- 環境檢查不過（init 的風格、`permission_denials`、`modelUsage` 鍵數、`outside`），或守門在兩臂紅在同一處：算旗標或 fixture 問題，不算措辭批次。先把 `run.sh` 的修改 commit（訊息寫明原因）再重跑；`check.sh` 的判準不准動；這類重跑最多 2 次，超過就停下回報
- 步驟 4 的報告放 `docs/reviews/2026-11-16-adhd-length/S1-*.md`；步驟 6、7、8 的 commit 訊息結尾 `（S1）`

## 計畫審查紀錄

每輪派 1 個裁決者（opus）與 4 個審查者（haiku），讀檔檢查 12 人次都過。

- 第 1 輪：不通過（2 條重大）。重大 1：LICENSE.txt 逐節去向要改的地方列少了（規則 4、5、7、break 5、break 6）。重大 2：新版拿掉保護句後，驗證的實際輸出與沒做完的事會被壓掉，而原本的三個 prompt 都不跑指令、測不到。改法：「長度」第 4、5 條逐項保護；P3 換成會跑 `bash test.sh`、留做不完的事的題
- 第 2 輪：不通過（1 條重大）。規則 9「超過 5 項只列前幾項」與「長度」第 4 條「不能只寫數量」互相矛盾。改法：規則 9 寫明第 4 條列的那幾樣照實全列；P3 改成六件做不完
- 第 3 輪：通過。採納 12 條小事，都已改進腳本與本檔

駁回的批評（每條一句）：

- 輪1-R1-2、輪1-R3-9：說 P3 的檔案狀態沒有來源。當時的計畫有記（後來改成記 `actual`）
- 輪1-R1-7：說 `tests/test-install.sh` 驗證太弱。計畫只用它確認 `name: ADHD` 沒壞
- 輪1-R3-1：說 10 行該回問使用者。它是把「少一點字」落成可量的參數，已寫明不是使用者的決定、可調
- 輪2-R4-2：說來源標註不在保護清單。「誰優先」第一項就是
- 輪2-R4-5、輪3-R4-3：說圍欄上限與風格檔對不上。「長度」第 6 條已限制圍欄內容，fixture 沒有程式碼要貼
- 輪2-R1-1：說豁免條款吃掉上限。三題都含保護項，L 照樣卡 10 行
- 輪2-R1-5：說 `modelUsage` 不是沿用的欄位。計畫沒有這樣宣稱
- 輪2-R1-6、輪2-R2-5、輪3-R2-1：說沒交代為什麼不先部署。A5 與已知限制已寫明，另有載入探針
- 輪2-R2-2：說 LICENSE 的引句對不上新版。計畫已安排整行重寫，驗收改完才跑
- 輪2-R2-3：說目錄名不合慣例。形狀與 `2026-10-29-adhd-style` 相同
- 輪2-R2-4：說 README 的功能描述沒同步。那一列列的功能新版都還在
- 輪2-R3-3：說 500 字算進路徑會誤判。500 已留餘裕
- 輪2-R3-5：說 `set -e` 加 `grep -c` 會靜默中止。`check.sh` 沒有用 `set -e`，自測的好例也會抓到
- 輪2-R3-9：說兩臂都帶著全域 CLAUDE.md。刻意的：要驗風格沒把全域規則壓掉
- 輪3-R3-3：說 P3 守門靠字面的「變更」「驗證」會誤判。全域 §4.5 的回報格式本來就有這兩個字
- 輪3-R3-5：說 `modelUsage` 可能多出別的鍵。多了會紅燈，探針先跑會先露出來
- 輪3-R4-1：說「關鍵那一行」把 §2.6 的證據要求縮了。§2.6 第 3 條只要求附實際輸出，沒要求整段
- 輪3-R4-4：說規則 3 與「不要寫完下一步就結束」矛盾。一句管格式、一句管要不要停，現行版就這樣
- 輪3-R4-5：說 §4.5 的「注意」沒受保護。「誰優先」寫明 CLAUDE.md 要求的每一樣照樣要有
- 輪3-R4-6：說「有哪些」讓上限失效。豁免的只有讀者要的那份清單

審查留下、沒有查的外部查證項（都是小事）：預設模型的 `modelUsage` 會不會只有一個鍵；dontAsk 下讀不讀得到工作目錄以外的檔（改用 `outside` 計數擋）；開著風格時開工前的計畫實際會被縮到多短；驗證輸出很長時會不會整段放進圍欄。
