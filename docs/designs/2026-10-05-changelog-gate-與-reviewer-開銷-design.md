# CHANGELOG 已發布區塊防線 與 code-reviewer 派送開銷

兩件各自獨立的工作，由使用者於 2026-10-05 指定：補一道 CI 防線擋「條目被寫進已發布的版本區塊」，
以及查清 code-reviewer「卡很久」的根因。

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | CHANGELOG 已發布區塊防線 | IN_PROGRESS | — | 往 `## 1.2.0` 插一行 → 該 CI step 紅燈；還原 → 綠燈；模擬發版（新增一個版本區塊）不誤擋 | a94f678.. |
| S2 | 查清 code-reviewer 慢在哪 | TODO | — | 拿出「Task 派送 vs headless」的 api/wall/工具數對照，結論寫進文件 | |

- 狀態只有 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`；同一時間最多一段 `IN_PROGRESS`
- 下一段：由上往下第一個 `TODO`，而且它依賴的段落都已 `DONE`。有段落 `BLOCKED` 時先停下來問使用者，不自己跳去做別段
- 開工：`~/.claude/scripts/check-claude-md.sh --start-segment` 記起點；這段標 `IN_PROGRESS`，commits 欄先填 `<起點>..`（短 SHA；起點是空樹時填它印出的完整 SHA；回頭做 `BLOCKED` 過的段落時，欄裡原本的起點保留不改）；該段有「開工前提」就先查完，結果寫進「段落與小任務」該段底下。這些改動跟第一個小任務的 commit 一起送
- 每個小任務：照「段落與小任務」列的做，實作、驗證、commit，commit 訊息第一行結尾帶編號（例如 `（S2-1）`）。可用 `SKIP_DOC_CHECK=1` 先跳過 CLAUDE.md 檢查，gate 會記帳。測試照文件裡的測試清單加；想加清單以外的測試，先問使用者
- 小任務 commit 了不等於段落完成。小任務全部 commit 完，而且 SKIP 欠下的 CLAUDE.md 都補上了，才對整段跑步驟 3–8，範圍從表上這段的起點算。最後一個小任務用正常 commit；補 SKIP 改過的目錄的 CLAUDE.md 時，用 `git diff <起點> -- <目錄>` 看整段改了什麼，不要只看這次 staged 的（gate 只查 CLAUDE.md 有沒有一起送，不查寫了什麼）。步驟 6、7、8 的 commit 訊息第一行結尾帶段落編號（例如 `（S2）`）
- 標 `DONE`：步驟 3–8 全部跑完才標；commits 欄補上終點（標 `DONE` 之前最後一個 commit 的短 SHA，所以標 `DONE` 的 commit 自己不在範圍內），跟步驟 7、8 的 commit 一起送，7、8 都沒改檔就單獨開一個 docs commit。標到表上每段都 `DONE` 的那個 commit，刪掉根目錄 CLAUDE.md 的指路那段
- 接手：`IN_PROGRESS` 那段就是目前這段。拿「段落與小任務」的清單對 `git log --oneline <表上這段的起點>..HEAD` 裡結尾帶 `（S2-` 的 commit（不加範圍會對到別份文件的同編號 commit）。
  **前綴是「這一段自己的 ID 加一個 `-`」**，不是固定字串：插隊進來的 `S2.5` 要找的是 `（S2.5-`，
  拿 `（S2-` 去比對不到它，拿 `（S2` 又會把 S2.5 的 commit 誤算成 S2 的，還沒 commit 的小任務先做完。小任務都做完了，再看同一範圍裡有沒有帶 `（S2）` 的 commit：有，代表步驟 6 之後的步驟做到一半；沒有就從步驟 3 開始
- `BLOCKED` 用在這段要先停：外部卡住（等使用者決定、環境壞了），或使用者要先做別的事（別段、臨時修 bug）。狀態格寫 `BLOCKED` 和原因，外部卡住時停下來問使用者。先停之前，用正常 commit 補完這段 SKIP 欠下的 CLAUDE.md（不然 `--start-segment` 會拒絕）；回頭做這段時，範圍一樣從表上這段的起點算。依賴還沒完成的段落維持 `TODO`
- 做到一半冒出新工作：先問使用者，同意才加一列 `TODO` 排進該在的位置；ID 不重編，插在中間用 `S2.5`。
  **同一批要在「段落與小任務」補上這一段的小任務**（名稱、要動的檔案、驗證方式、commit 訊息）——
  只加表上那一列的話，接手的 session 照上面「接手」那條去對 commit，清單本來就是空的，
  它會判定「小任務都做完了」而直接跳到步驟 3，整段程式碼從頭到尾沒人寫。
  沒有小任務條目的段落不得標 `IN_PROGRESS`
- 每列一行，細節寫進 commit 訊息

## 來源

使用者口頭指定（2026-10-05），兩項皆源自同一個 session 的實測：

- **S1 的病因有第一手證據**：插入 CHANGELOG 條目的 python 索引差一位（`n>=36` 跳過 0-based 35 的
  `### Changed`），兩條本輪變更被寫進已發布的 `## 1.2.0 — 2026-09-12` 區塊。`git diff` 看起來正常、
  CI 全綠，是使用者問「發版有什麼風險」才翻出來（已修：`fa251a3`）。現有 CI 沒有任何 step 看 CHANGELOG 的區塊歸屬
- **S2 的已知數據**：同一段 diff（`48de43f`）跑六發 `claude -p --agent`，`duration_api_ms` 都是 58–84s，
  但 wall 93–258s，非模型開銷 35–170s。但那是 headless session，不是 Task 派出的 subagent；
  使用者原本遇到的 20–25 分鐘是後者

## 假設

- S1 的判準是「已發布區塊不可改動」——連錯字修正也會被擋，要改就得發新版。**不做例外機制**
- S1 需要 CI 拿得到 tag：目前 `actions/checkout@v4` 沒設 `fetch-depth`（已讀 `.github/workflows/ci.yml:14`），
  是 shallow、沒有 tag，所以 S1-1 要一起加 `fetch-depth: 0`
- S2 若量出根因不在 DD pipeline 可控範圍（例如純屬 harness 的派送開銷），S2-2 退化成只寫一句紀錄、不動規則
- S2 的素材重建自 `48de43f~1`/`48de43f` 的 `git archive`，不依賴上個 session 的 scratchpad

## 段落與小任務

### S1 CHANGELOG 已發布區塊防線

**開工前提（已查，2026-10-05）**：實測 `git clone --depth 1 file://<repo>` 之後 `git tag` 為 0 筆、
`git describe --tags --abbrev=0` 直接 `fatal: No names found`。所以 S1-1 必須同批把第一個 job 的
checkout 改成 `fetch-depth: 0`，否則這個檢查在 CI 永遠走到「抓不到 tag」那條。

- **S1-1 新增 ci.yml 檢查 step**
  - 檔案：`.github/workflows/ci.yml`（新 step + 第一個 job 的 checkout 加 `fetch-depth: 0`）
  - 做法：取最近 tag 的 `CHANGELOG.md`，逐 `## <版本>` 區塊與 HEAD 比對，**兩邊都存在的版本區塊必須逐字相同**；
    未發布區塊與新增的版本區塊不限制。tag 抓不到時要明確失敗，不可靜默放過
  - 驗證（負面變異，照 repo 規則每個都要看到預期結果）：①往 `## 1.2.0` 插一行 → 紅燈 ②改 `## 1.1.0` 的字句 → 紅燈
    ③刪 `## 1.1.0` 一行 → 紅燈 ④只改未發布區塊 → 綠燈 ⑤模擬發版（新增一個版本區塊）→ 綠燈 ⑥tag 抓不到 → 紅燈且訊息講明原因
  - commit：`ci: CHANGELOG 已發布區塊不可改動（S1-1）`
- **S1-2 同批文件同步**
  - 檔案：`DD_PIPELINE_ARCHITECTURE.md`（CI 防線表加一列）、`CLAUDE.md`（加一條：條目要插未發布、已發布不可動，附這次的踩雷）
  - 驗證：重跑「數字宣稱一致性」與 S1-1 的新 step，兩者皆綠
  - commit：`docs: CI 防線表與 CLAUDE.md 同步 CHANGELOG 檢查（S1-2）`

### S2 查清 code-reviewer 慢在哪

**開工前提**：先用 haiku 便宜探一次，確認 Task 派出的 subagent 的時間與工具數在 jsonl 裡拿得到
（候選：`result.subagent_stats`、`--forward-subagent-text`、`--include-partial-messages`）。拿不到就改用可拿到的代理指標，並在文件寫明限制。

- **S2-1 量測並記錄**
  - 檔案：`docs/measurements/2026-10-05-reviewer-overhead.md`（新）、`CLAUDE.md`（目錄結構補一行 `docs/`）
  - 做法：重建 2-commit 快照，同一份 prompt、同一個 model（opus），**Task 派送與 headless 各兩發**（使用者批准預算 ≈US$3）；
    記 wall、`duration_api_ms`、非模型開銷、工具呼叫數、cost
  - 驗證：jsonl 原始數字貼進文件，數字自己重算一次（不抄 agent 自述）
  - commit：`docs: 量測 reviewer 的派送開銷（S2-1）`
- **S2-2 依結論更新規則**
  - 檔案：`templates/global/CLAUDE.md` §3.9 步驟 4；**若動到 `/dd-init` 蓋章區塊就要跳 `dd-loop-rev` 7**，
    連動 Phase 1 判定式、蓋章標記、「rev 比 N 舊」判定線、差異清單、`UPGRADING.md`、CHANGELOG 未發布
  - 驗證：重跑「迴圈步數四方一致」（含 rev）與「第五方」
  - commit：`docs: 依量測結論更新步驟 4（S2-2）`

### 測試清單（使用者批准）

不新增測試檔。S1 的「測試」就是 ci.yml 那個新 step 本身，加上上面六個負面變異的手動驗證；S2 是量測，無測試。
