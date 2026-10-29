# 把 CLAUDE.md 規則改成 CI 檢查（dd-loop-rev 跳號、~/.claude/ 死指標）

使用者看了 mattpocock/skills 的 `/retro`（「有固定樣子的錯做成自動檢查，再把文字規則縮短」），選了先做這一條：
根目錄 CLAUDE.md 原本寫明「CI 不驗內容改了 rev 有沒有跳」。

## 進度表

| ID | 段落 | 狀態 | 依賴 | 驗收（步驟 5 要看到什麼） | commits |
|---|---|---|---|---|---|
| S1 | CI 擋「蓋章區塊改了沒跳 dd-loop-rev」並縮短根 CLAUDE.md 那段 | DONE | — | 新 step 原樣綠；改區塊不跳號、rev 退回、抓不到區塊三種變異紅；改區塊外、跳號後綠 | 848ea70..994df4f |
| S2 | CI 擋部署內容裡指不到東西的 `~/.claude/` 路徑 | DONE | — | 原樣綠；`rules/`、不存在的部署檔、`scripts/githooks`、`tests/`、零命中紅；佔位與 Claude 自己的路徑綠 | 80236ec..2ab0fc9 |

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

## 段落與小任務

### S1 dd-loop-rev 跳號檢查

- S1-1 `.github/workflows/ci.yml` 加 step；`DD_PIPELINE_ARCHITECTURE.md` CI 防線表加一列；根 `CLAUDE.md` 那段改成指向這道檢查；CHANGELOG
  - 驗證：step 抽出來在 repo 根目錄 `bash -e` 跑，原樣與 7 種變異（改區塊中段／最後一行不跳號、改區塊＋跳號、只跳號、圍欄標記改掉、rev 退回、改區塊外）；`/bin/bash` 3.2 也跑；YAML 用 ruby 解析
  - commit 訊息：`feat: CI 擋蓋章區塊改了沒跳 dd-loop-rev（S1-1）`

### S2 ~/.claude/ 死指標

使用者看完 S1 後選了「其他 3 條」裡的第 2 條（根 CLAUDE.md「cherry-pick 上來的 commit 要重核」那條）。

- S2-1 `.github/workflows/ci.yml` 加 step；`DD_PIPELINE_ARCHITECTURE.md` CI 防線表加一列；根 `CLAUDE.md` 那條改成指向這道檢查並寫明它管不到什麼；CHANGELOG
  - 驗證：step 抽出來在 repo 根目錄 `/bin/bash -e` 跑，原樣與 12 種變異（附加一行到 `scripts/check-claude-md.sh` 尾端，跑完還原並 `cmp`）＋掃描範圍全錯；YAML 用 ruby 解析
  - commit 訊息：`feat: CI 擋部署內容裡指不到東西的 ~/.claude/ 路徑（S2-1）`
