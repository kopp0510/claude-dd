# scripts/ — 輔助腳本

部署到 `~/.claude/scripts/` 的輔助腳本層（部署清單由 `install-dd-pipeline.sh`
頂部的 `DD_SCRIPTS` 陣列決定），加上本 repo 自用的 git hooks。

## 關鍵檔案

- `check-claude-md.sh` — CLAUDE.md pre-commit gate（block 版）。規則：staged
  變更含程式碼檔（副檔名見腳本內 `CODE_EXT`）的目錄，必須存在 CLAUDE.md 且
  同批 staged；逃生口 `SKIP_DOC_CHECK=1`（僅供迴圈檢查點 commit）。由
  `/dd-init` 掛進各專案的 `.git/hooks/pre-commit`。
  - **記憶檔名可設**：預設 `CLAUDE.md`，`git config dd.docfile GEMINI.md`
    改成別的（寫在 `.git/config`，不進版控）。用途是**只准放某個固定檔名的 repo**
    （例如規定記憶檔一律叫 `GEMINI.md`、不得出現 `CLAUDE.md` 的團隊）—— 檔名寫死
    就等於那些 repo 完全用不到 gate。
    - **只讀 `--local`**：設成 global 的話，一次設定會把這台機器上
      **所有** repo 的 gate 改認那個檔名，個人 repo 的 CLAUDE.md 全部變成不算。一個 repo 一個決定。
      ⚠️ **連 `-c dd.docfile=…` 與 `GIT_CONFIG_PARAMETERS` 也不生效**（那是 command 層、不是 local）——
      想在別的 repo 乾跑就真的 `git config --local dd.docfile <檔名>`，驗完 `--unset`
    - **只接受單純檔名**（`[A-Za-z0-9._-]`，不是 `.` / `..`，**也不以 `-` 開頭**）：帶路徑或空白一律 `exit 1`。
      這個字元集同時擋掉 regex 特殊字元，所以組 awk 樣式時只需要跳脫 `.`（`DOC_RE`）
    - **不可以是程式碼檔名**（2026-11-15）：副檔名在 `CODE_EXT` 裡的值（`main.py`、`notes.sh`…）一律 `exit 1`。
      修的洞：`dd.docfile=main.py` 時，改 `a/main.py` 的 commit 自己就算「記憶檔同批 staged」，`owed_dirs` 也把它當成銷帳 ——
      SKIP 欠的帳被洗掉、之後沒有 CLAUDE.md 的改碼 commit 照過，`git status` 是乾淨的（拋棄式 repo 實跑）。
      檢查放在 `CODE_EXT` 定義之後（要用它），不在上面那段字元集驗證裡。
      ⚠️ **擋不到的**：`Makefile`、`Dockerfile` 這類沒副檔名的檔，以及 `CODE_EXT` 沒列的副檔名 —— 這些檔本身不算程式碼，
      設成記憶檔名時 gate 要的是「每個改碼目錄都有一份、而且同批 staged」，不是自己替自己銷帳那一種（使用者 2026-11-15 選定只擋程式碼副檔名；
      選項說明寫的是「已經設成 GEMINI.md、AGENTS.txt 的 repo 不受影響」，另一個選項「只收 .md 結尾」會讓那些 repo 的 gate 拒絕執行）
    - ⚠️ **`-` 開頭要另外擋**：字元集本身放行 `-`，而 `md_of "."` 是 `echo "$DOC_FILE"` ——
      bash 內建 echo 把 `-n` / `-e` 當選項吃掉，根目錄的記憶檔路徑會變成**空字串**
      （`[ -f "" ]` 恆假、訊息也印不出檔名）；用 `od -c` 驗過，`echo "-n"` 真的印零位元組
    - **檔名在三處各自出現**，改動時三處都要顧：`md_of()`（組路徑）、訊息字串（`${DOC_FILE}`）、
      `owed_dirs` 的 awk 樣式（`ENVIRON["DOC_RE"]`，決定欠帳**銷不銷**）
    - 變異測試（記「哪個變異 → 哪幾則紅」）：

      | 變異 | 應該變紅的情境 |
      |---|---|
      | `md_of()` 改回寫死 `CLAUDE.md` | ⑫ 的這六則：①「只有 GEMINI.md 也過關」／②「補上 b/GEMINI.md 後過關」與它的 `said b/GEMINI.md`／③「補上 c/GEMINI.md:同批 staged 放行」「c 的欠帳已銷」與 `said c/GEMINI.md`。⚠️ **不是「①②③ 全部」**：②的「只有 CLAUDE.md 要擋」在變異版照樣 block（擋下的理由變成別的目錄），它的 `said "缺少 GEMINI.md 的目錄"` 也照樣綠（**訊息字串走 `${DOC_FILE}`、不經 `md_of()`**）—— 綠燈不代表那兩則釘住了這個功能 |
      | awk 樣式改回寫死 `/(^\|\/)CLAUDE\.md$/` | **只有**⑫③ 的「c 的欠帳已銷：只動 d 的 commit 放行」一則 |
      | 把 `case "$DOC_FILE" in …` 整段驗證拿掉 | ⑫④ 的「帶路徑」「含空白」兩則 expect + `said "必須是單純檔名"` |
      | `--local` 改回 `--get`（吃得到 global） | ⑫⑤ 的 expect 與 `said "c/CLAUDE.md"` |
      | 驗證的 `case` 拿掉 `-*` 那一條 | ⑫④ 的「以 - 開頭」expect 與 `said "不以 - 開頭"` |
      | 拿掉「不可以是程式碼檔名」那段 `if` | ⑬ 的三則 expect(「main.py:--start-segment 拒絕執行」「notes.sh:--start-segment 拒絕執行」「改 a/main.py 的 commit 不可以自己當記憶檔」)與三則 `said "不可以是程式碼檔名"`;「AGENTS.txt:--start-segment 照常」也跟著紅(前面那個 commit 進了歷史、變成欠帳,是連鎖不是它自己的斷言壞了)。notes.sh 那則排在 commit 之前才有牙:排在後面時它會被那筆欠帳頂住、照樣 block |

      ⚠️ **第二個變異第一版是 0 紅** —— 當時 ③ 的最後一則是「補上 `c/GEMINI.md` 後放行」。
      `owed_dirs` 其實跑了、也確實把 `c` 算成欠帳,**是 `[ -f "$md" ] && grep -qxF "$md" && continue`
      這條「同批 staged 就過關」的短路把結果蓋掉**。要測銷帳必須**再加一個完全不碰該目錄的 commit**,
      詳見 `tests/CLAUDE.md`
    - **動到 gate 的檔名判斷時，要巡的文件照專案 CLAUDE.md「觸發時機」那條，另加 CHANGELOG 的 `## 未發布`**（2026-10-16 加 `dd.docfile` 時巡過的見 `29726db`）；
      `commands/dd-init.md` **不用跟著改**，理由分兩半：
      - **區塊外**（Phase 3，`grep -n '^### Phase 3' commands/dd-init.md`）：它寫進 hook 的那一行
        只是轉呼叫 gate、**不判檔名**，所以行為正確。改它**不需要**跳 rev（蓋章區塊是
        ``grep -n '^```' commands/dd-init.md | head -2`` 夾出來的那段，Phase 3 在它之後）
      - **區塊內**：rev 12 以前步驟 8 的範圍指令寫死在蓋章區塊裡，要跟著檔名走就得跳 `dd-loop-rev`。
        rev 13（2026-10-30）起區塊只寫「指令見 `dd-loop`」，指令在 `skills/dd-loop/SKILL.md`（一樣寫死 `grep 'CLAUDE\.md$'`），
        要跟著檔名走改那裡就好、不必跳 rev；已蓋 rev 12 以前的專案區塊裡仍是舊指令
      ⚠️ **已知限制(不是「使用者看不到」)**：Phase 3 產生的訊息字串寫死 `CLAUDE.md`
      （hook 的註解、gate 不在時的 fallback 警告、pre-commit／lefthook 的設定名 ——
      `grep -n 'CLAUDE.md gate' commands/dd-init.md`）。設了 `dd.docfile` 的 repo 裡，
      協作者打開 `.git/hooks/pre-commit` 看到的仍是「需有 CLAUDE.md」，**而 gate 實際認的是
      `dd.docfile`**。要修就改 Phase 3 的措辭（不必跳 rev），但依專案 CLAUDE.md 動 commands
      要另外在沙盒 repo 乾跑一遍，所以沒跟這批一起做
  - **擋不到 `git commit --no-verify`／`-n`**：git 直接跳過 pre-commit，gate 整個不跑，
    SKIP 那種「沒起點就自動記」也不會發生。已經記過段落起點時，之後的正常 commit 會在欠帳裡補抓到；
    沒記起點、或繞過的就是最後一個 commit，就完全漏查。被擋時的訊息結尾會提醒別這樣繞；
    Claude 端由 `skills/gate-guard` 的 PreToolUse hook 在執行前 deny
  - **暫停旗標 `dd.stopped`**（2026-11-17；設計與使用者的決定在 `docs/designs/2026-11-17-dd-stop-design.md`）：`git config --local dd.stopped true` 時
    pre-commit 那條路放行、印「gate 暫停中」，`--start-segment` 印「迴圈暫停中」、exit 0，不查欠帳、不查 review 報告、不動起點檔；`--segment-base` 不受影響。
    - **暫停是延後、不是豁免**（使用者 2026-11-17 選「要補」）：gate 沒有為暫停加任何追討邏輯，靠的是 `owed_dirs` 本來就不分 commit 有沒有用 SKIP ——
      起點到 HEAD 之間改了程式碼而沒更新記憶檔的目錄都算。所以沒有起點檔時，暫停中第一個 commit 要記起點（跟 SKIP 那一支一樣），不然清掉旗標之後沒有東西可追
      （拋棄式 repo 實跑：沒有起點檔時，一個沒補文件的 commit 之後 gate rc=0、沒有輸出）
    - **只讀 `--local`、值要剛好是 `true`**：理由同 `dd.docfile`（global 會一次關掉這台機器所有 repo 的 gate）；`false`、`1`、`True` 一律當成沒暫停、不報錯
    - **起點檔在而內容讀不出來時不覆寫**，只印警告（stderr）：SKIP 那一支遇到這種情況會覆寫成現在的 HEAD（它的 `if ! read_base` 不分「不存在」與「壞了」）。
      SKIP 是偶爾一個 commit；暫停期間每個 commit 都走暫停這一支，覆寫等於把起點推到暫停中途
    - **`--start-segment` 暫停中 exit 0、不是非 0**：它沒有印「段落起點：」，照 `skills/dd-loop/SKILL.md` 就是沒記好；訊息自己講了該怎麼做（只做步驟 1、2）。
      回非 0 的話，照「被擋下時照它印的做」讀起來像有東西要修
    - ⚠️ **這是 SKIP 之外的第二條放行路徑，Claude 自己就設得了這個旗標**，設定只留在 `.git/config`、git 裡零痕跡。`skills/gate-guard` 不擋它，
      它的 deny 理由仍然只指向 `SKIP_DOC_CHECK=1`（被 gate 擋下時的出路只有那一條；暫停是使用者下的開關）。看得到的痕跡只有暫停中每個 commit 印的那一行「gate 暫停中」
    - 測試是 `tests/test-gate.sh` 的 ⑰。變異對照（2026-11-17；每個變異先確認 `grep -c '^✅ ⑰'` 不是 0、判定行數與固定版相同）：

      | 變異 | 應該變紅的情境 |
      |---|---|
      | pre-commit 暫停那一支的條件改成 `false` | ⑰「暫停中：改 a/ 不補文件的 commit 放行」「暫停中：再一個 commit 放行」「暫停中、起點檔內容壞掉：commit 放行」三則 expect、`said "gate 暫停中"`、`said "沒有覆寫它"`、三則 `base_is`；「恢復後」的 `said "段落起點之後有 commit 跳過檢查"` 是連鎖（暫停期間的改動沒有進歷史） |
      | `--start-segment` 暫停那一支的條件改成 `false` | ⑰「暫停中 --start-segment：不擋」「暫停中、沒有 review 報告：--start-segment 不擋」兩則 expect 與各自的 `said "迴圈暫停中"` |
      | `--local --get dd.stopped` 改成 `--get dd.stopped` | ⑰「dd.stopped 只設在 global：不算暫停，照樣擋」與「被擋下的 commit 不該留下起點檔」；下一則「暫停中：改 a/ 不補文件的 commit 放行」是連鎖（那個改動已經被 commit 走了） |
      | 暫停那一支沒有起點檔時不記起點 | ⑰ 第一個 repo 的三則 `base_is`（起點是空的）、「恢復後：只動 b/（有補文件）的 commit 被擋」與它的兩則 `said` |
      | 暫停那一支遇到壞起點檔照樣覆寫 | 只有 ⑰ 最後的 `base_is "not-a-sha"` |
  - **`--start-segment` 有兩個擋點，`reviews_missing()` 是第二個**（2026-10-07，S6）：
    專案**有 `docs/reviews/` 目錄時**（= opt-in），檢查「上一段的 commit 範圍內有沒有新增
    `docs/reviews/S*.md`」—— 沒有就 `exit 1`。擋點放在這裡而不是 pre-commit 的理由：
    **pre-commit 收到 0 個參數、拿不到 commit 訊息**，而「翻 `DONE`」那個 commit 不一定存在；
    `--start-segment` 是每段必經、而且天然就在「上一段剛結束」那個時點。
    - **樣式是 `(^|/)S[0-9][^/]*\.md$`**(`check-claude-md.sh` 的 `reviews_missing` 裡,理由寫在它上面的註解;位置用 `grep -n -F 'S[0-9][^/]*' scripts/check-claude-md.sh` 找,不寫行號 —— 這裡原本寫 `:186`/`:183`,2026-10-19 合進 `dd.docfile` 後就指歪了)。兩個設計都是刻意的:
      `S[0-9]` 而不是 `S[^/]*`(後者讓 `SUMMARY.md` / `SPEC.md` 也算報告);
      `(^|/)` 讓**子目錄**下的 `…/S1-a.md` 一樣命中(多張進度表時報告要分子目錄,段落 ID 會跨表重複)。
      ⚠️ **連帶的盲點**:段落 ID 用別的字母開頭(例如 `T1`–`T10`)時**一個都不命中**,
      於是 gate 判定「上一段沒有附 report」而 `exit 1`,**即使報告確實存在且已 commit**。
      已實際踩到;當下的處置是「起點改用進度表 commits 欄的值」,
      **不要為了讓 gate 過而改檔名**(那會讓檔名與段落 ID、commit 訊息三者不一致)。
    - **`docs/reviews/CLAUDE.md` 不算報告**(不是 `S` 開頭),改它不會放行。
    - 擋下時印的「三條路」(2026-11-15 以前是兩條)第 1 條是主對話直接派審查者的報告(每個審查者一份 `-a/-b/-c…`,加查證 `-judge.md`)。**判定樣式沒變** —— `-judge.md`、`-c.md` 本來就命中 `S[0-9]`。
      第 2 條(SKIP)多印一行「trailer 緊接在 `Co-Authored-By` 前面、中間不能空行」:隔了空行 git 不認它是 trailer,`--format='%(trailers…)'` 查不到、commit 照樣成功
    - **第 3 條(2026-11-15):這一段還沒做完、要先停下來做別段(進度表標 `BLOCKED`)時,建 `docs/reviews/S<段落>-BLOCKED.md` 並 commit。**
      修的洞:有 `docs/reviews/` 的專案,一段做到一半要開別段時 `--start-segment` 擋在這裡,原本印的兩條路都不適用(還沒做完所以沒有報告、也不是「不需要審」),
      `skills/task-planner/SKILL.md` 規則區塊的 `BLOCKED` 那條當時也只交代補 CLAUDE.md(拋棄式 repo 實跑:記起點 → 一個程式碼 commit → 再跑 `--start-segment` 回 1;同一天稍後規則區塊補上了申報檔那一句,但已經照抄進各專案設計文件的舊規則不會跟著變,那些專案靠的是這幾行訊息與 `skills/dd-loop/SKILL.md`「報告一律落地」底下講 `BLOCKED` 的那一條)。
      **判定沒改,只多印這幾行** —— `S1-BLOCKED.md` 本來就命中 `S[0-9][^/]*\.md`;`tests/test-gate.sh` ⑮ 把「只建檔沒 commit 照樣擋、commit 之後放行」釘住。
      變異:拿掉第 3 條那四行 → 只有 ⑮ 的三則 `said`(`S<段落>-BLOCKED.md`、`它只是申報`、`S<段落>-BLOCKED-2.md`)紅。
      ⚠️ **同一段第二次先停要另建 `S<段落>-BLOCKED-2.md`**:gate 用 `--diff-filter=A`,改既有那份不算新增,照「建 `S1-BLOCKED.md`」做會再被擋一次
      (2026-11-15 拋棄式 repo 實跑:只改既有的回 1、新增 `-2` 回 0;訊息多印一行講這件事,⑮ 後半釘住)。
      ⚠️ **gate 只看檔名(跟 `-SKIP.md` 同類,使用者 2026-11-15 選定這個做法)**:拿 `-BLOCKED.md` 當成一段已經做完的段落的報告,gate 分不出來。
      回頭做這一段時要重跑 `--start-segment`,所以之後再開下一段時,「回頭之後的 commit 範圍裡有沒有新增報告」照樣會查;
      查不到的是先停之前已經 commit 的那一部分有沒有被審到 —— 那要靠進度表 commits 欄的起點(步驟 4 的範圍從它算,見 `skills/dd-loop/SKILL.md`)
    - **剛採用這個慣例時第一次 `--start-segment` 通常會被擋**(上一段本來就沒報告)——
      預期行為,照它印的出路補一份 `S<N>-SKIP.md` 並 commit(只建檔不 commit 還是擋)。
      起點檔不存在、或上一段從空樹開始時不擋(`reviews_missing` 的 `EMPTY_TREE` 那行,視為第一段;2026-10-30 乾跑實測)。
    - **要退出:刪掉 `docs/reviews/` 目錄**,本檢查就完全不啟用。
    - ⚠️⚠️ **已知的繞過路徑(①②③ 是 2026-10-19 列的,④ 是 2026-11-15 加的,⑤ 是 2026-11-17 加的)—— 文件寫明,不要把它當閉環**:
      ①**跑完這一段但永遠不開下一段**(擋點只在「開下一段」那個時點);
      ②**漏跑一次 `--start-segment`** —— 起點沒搬動,`base..HEAD` 橫跨兩段,
      **上一段的報告會把這一段的要求頂掉**(實跑確認);
      ③**`rm` 掉起點檔** —— 兩個擋點一起關掉,而且 git 裡零痕跡
      (gate 的欠帳訊息本來就在教這招,所以那行後面補了警告);
      ④**申報檔只看檔名** —— `S<段落>-SKIP.md`、`S<段落>-BLOCKED.md` 只要是範圍裡新增的檔就放行,內容與真假 gate 都不看:
      拿 `-BLOCKED.md` 當成一段已經做完的段落的報告,gate 分不出來(細節見上面「第 3 條」那個條目);
      ⑤**暫停旗標** —— `git config --local dd.stopped true` 之後 `--start-segment` 兩個擋點都不查(pre-commit 也放行),設定只在 `.git/config`、git 裡零痕跡。
      跟③不同的是起點不動、帳照記:清掉旗標之後,欠帳與「起點以來要有報告」照樣查;一直不清就一直不查(細節見上面「暫停旗標」那個條目)。
      ⇒ 它買到的是「**要繼續往前走就得先結清上一段**」,不是閉環(`skills/dd-loop/SKILL.md`「報告一律落地」那條也寫明了這點)。
      **①②③ 都有特性測試**(2026-10-19):`tests/test-gate.sh` 裡說明以「繞過①」「繞過②」「繞過③」開頭的那幾則,
      各配一則對照(同一個狀態、只差那個繞過動作,結果相反)。④ 的是 ⑮ 裡說明以「繞過④」開頭的那一則,對照是它前面那則「只建 S1-BLOCKED.md 沒 commit:照樣擋」。⑤ 的是 ⑰ 的「暫停中、沒有 review 報告:--start-segment 不擋」,對照是它前面那則「沒暫停、上一段沒有 review 報告」。**變紅時先分清是哪一種**:
      繞過①③④⑤變紅 = gate 堵上了那條路(④ 是 gate 開始看申報檔的內容、或不收那個檔名了;⑤ 是暫停中 `--start-segment` 又開始查了),是刻意的就先改上面那句、再照新行為改測試。
      ⚠️ **繞過②以 gate 現在看得到的東西堵不掉**:它跟「報告 commit 之後還有步驟 6、7、8 的 commit」這個正常流程,在 gate 眼裡是同一個形狀
      (gate 只看起點..HEAD 有沒有新增報告,沒有「段落」的概念)。所以②變紅時先看區塊開頭的「正常流程」那則 ——
      它也紅了就是回歸,改回 gate,不要改文件(`docs/reviews/2026-10-18-pstack-gaps/S1-a.md` 的 A1)。
      變異實測(哪個變異 → 哪幾則變紅,刻意不記紅數):

      | 變異(改了哪一行) | 應該變紅的情境 |
      |---|---|
      | pre-commit 也查報告:`staged=` 那行下面加 `reviews_missing && exit 1` | 繞過①;另外從「建立 docs/reviews/ 的那個 commit」起一路連鎖變紅(前面被擋、後面的狀態跟著跑掉)。⚠️ 要確認繞過①那則自己有牙,得**只在它那個 commit 打開這個變異**(gate 副本改成 `[ -f "$(git rev-parse --git-path m1-on)" ] && reviews_missing && exit 1`,測試副本只在那一則前後 `touch` / `rm` 那個檔):只有它變紅。改在起點之後的**第一個** commit 打開則 0 紅 —— 那時 HEAD 就是起點、範圍是空的,`reviews_missing` 本來就回「不缺」(`S1-b.md` 的 B1) |
      | 試著堵繞過②:只算 HEAD 那個 commit 新增的報告(`reviews_missing` 裡 `"$range_base" "$head_sha"` 改成 `"$head_sha^" "$head_sha"`) | 繞過②**與**「正常流程」那則一起紅(外加它們後面的 `base_is`)—— 這就是「堵不掉」的證據 |
      | `--start-segment` 有 `docs/reviews/` 而沒有起點檔就拒絕:它那一支的 `head_or_empty > "$BASE_FILE"` 上面加 `[ -d docs/reviews ] && ! read_base && exit 1` | 只有繞過③的「rm 掉起點檔,開下一段放行」 |
      | `--start-segment` 沒有起點檔時從空樹記起:它那一支的 `head_or_empty > "$BASE_FILE"` 改成 `if read_base; then head_or_empty > "$BASE_FILE"; else echo "$EMPTY_TREE" > "$BASE_FILE"; fi` | 只有繞過③的「by/ 的欠帳被洗掉」 |
    - ⚠️ **`[ -d docs/reviews ] || return 1` 這行是 opt-in 的全部** —— 動它會讓
      **所有**沒採用這個慣例的專案（含 `test-gate.sh` 前 61 項用的拋棄式 repo）一起被擋。
    - ⚠️ **`--diff-filter=A`(只算「新增」)是刻意的**:gate 自己的訊息與五份文件都寫
      「有沒有**新增**」,而第一版用 `ACMR` —— 於是**上一段的 `S1-a.md` 改個錯字,
      這一段零報告也能開下一段**(reviewer 實跑抓到)。代價:報告的「處置」節如果要等
      下一段才寫得出來,那次補寫不算這一段的證據 —— 本專案的流程是在步驟 4 當場寫完,所以不衝突。
  - **SKIP 不是豁免**：段落起點記在 `git rev-parse --git-path dd-segment-base`
    （`--start-segment` 記下；忘了記時第一個 SKIP commit 自動記）。之後的正常 commit
    沿著 commit 的祖先關係結算起點以來的欠帳：改程式碼記帳，要由看得到那段程式碼的後代
    commit（含 merge commit 自己）更新該目錄 CLAUDE.md 才銷帳。所以舊起點不會讓 gate 變寬鬆，
    平行分支上的 CLAUDE.md 更新也抵不掉。
    目錄在 index 裡已經沒有程式碼就不追討；還有欠帳時 `--start-segment` 拒絕重記
  - ⚠️⚠️ **「記下的起點 → 這次實際要用的起點」有三處在解析，而退化政策刻意不同**
    （2026-10-07，S4 把機制抽成 `resolve_fork_base`）：

    | 處 | 產出 | 起點不是祖先 | 連共同祖先都沒有 |
    |---|---|---|---|
    | `owed_dirs` | range（`A..B`，空樹時是裸 `head`） | 退到共同祖先 | **放行，但印警告**（只檢查 staged） |
    | `reviews_missing` | base sha | 退到共同祖先 | **放行，但印警告**（跳過 review 檢查） |
    | `--segment-base` | base sha | **硬失敗** | **硬失敗** |

    ⚠️ **`--segment-base` 有一個例外沒寫在表上**:
    **起點是空樹時它印出空樹 sha 並 exit 0**(`[ "$base" = "$EMPTY_TREE" ] ||` 那一段)——
    因為「段落從第一個 commit 之前開始」是合法狀態,步驟 3、4、8 拿空樹 sha 去 `git diff` 是對的。
    實跑確認:全新 repo `--start-segment` → `--segment-base` 印 `4b825dc…`、exit 0。
    ⚠️ **而「空樹起點 + `--segment-base`」目前沒有任何測試覆蓋**(既有的 `--segment-base` 斷言,base 都是真 commit 或不存在)。

    **`--segment-base` 硬失敗時,stderr 講的下一步分四種**(2026-11-15;四種都是 exit 1、stdout 不印東西,`tests/test-gate.sh` 四種各有一則 `stdout_empty`):
    - 起點檔不存在 → 「沒記過」,叫人段落開始前先跑 `--start-segment`
    - 起點不在目前分支的歷史裡、有共同祖先 → 印出共同祖先的完整 sha,說範圍可以從它算(目前分支上這一段的 commit 不會漏、只會多;amend、rebase、換分支、`reset --hard` 到起點之前四種都在拋棄式 repo 比過 `git rev-list`,原範圍裡沒被涵蓋的都是 0 個),並寫明這一段還沒做完時不要重跑 `--start-segment`
    - 起點不在歷史裡、連共同祖先都沒有 → 叫人改用進度表 commits 欄的起點,沒有進度表就問使用者
    - 起點檔在、內容不是 commit 也不是空樹(物件被 git 清掉、檔案壞了,或內容是一個不是空樹的 tree —— `read_base` 連 tree 都收,這一支自己再判一次)→ 同上一種的下一步

    修的洞:原本四種共用一句「段落開始前先跑 `--start-segment`」。起點那個 commit 被 `git commit --amend` 掉之後照做,起點移到現在的 HEAD,
    `git diff <起點> --stat` 是 0 行 —— 這一段已經 commit 的全部不在步驟 3、4、8 的範圍裡(拋棄式 repo 實跑)。
    ⚠️ **共同祖先只印在 stderr**:印到 stdout 的話,`base=$(… --segment-base)` 的呼叫端會把它當成起點拿去用,等於把硬失敗改成軟退化。
    訊息改了字,`skills/dd-loop/SKILL.md`「段落起點與 `<起點>`」講取不到起點怎麼辦的那段要跟著對一次(2026-11-15 S2 起它照這幾句分情況:認的是「沒記過」「共同祖先是」「找不到共同祖先」「內容不是 commit」這四串字,四串都沒有、錯誤印在 stdout 時叫人照它印的修好再重跑;`skills/code-simplifier/SKILL.md`「取不到起點」那句認「共同祖先是」)。
    ⚠️ **「stdout 不印東西」只講這四種**:`dd.docfile` 不合法時整支在更前面就 exit 1,那句錯誤印在 stdout(既有的字元集檢查與 2026-11-15 加的程式碼檔名檢查都是)。
    呼叫端要看 exit code,不能只看輸出是不是空的 —— `skills/dd-loop/SKILL.md` 步驟 8 那段寫的是 `base=$(…) && [ -n "$base" ]`,擋得住。

    **前兩處「往寬退」是刻意的** —— 退窄會把欠帳 / review 要求洗掉，而那正是這兩個檢查要擋的事。
    **`--segment-base` 必須硬失敗**：它的輸出要餵 `git diff`，印空字串或錯的 base 是文件點名的地雷。
    ⚠️ **所以 `resolve_fork_base` 只抽「機制」不抽「政策」** —— 共用的是
    `merge-base --is-ancestor` + fork-point + 那句警告（**S6 的 review 抓到這兩處已經漂移**：
    一處退到共同祖先、另一處直接放行；根目錄 `docs/reviews/S6-a.md` 的 A2 / `docs/reviews/S6-b.md` 的 B2 —— `2026-10-23-裁決審查/` 底下也有同名檔，那裡的 A2/B2 是別的事）；「連共同祖先都沒有」的後續處置留在呼叫端，
    因為兩處的後果不同。`--segment-base` **刻意不用這支**：硬套進來就得加一個關掉 fallback 的
    mode 參數，那只是把同一個決策搬進函式裡（S4 規劃時的預判，S4 實作時確認了）。
    ⚠️ **改這三處任何一處,先跑變異測試**:`bash tests/test-gate.sh <改壞的 gate>`。
    ⚠️⚠️ **下面記的是「哪個變異 → 哪幾個情境變紅」,刻意不記紅數**:
    紅數同時綁「斷言集合」與「變異的具體寫法」兩個會變的東西,而文件通常只記得住數字 ——
    加任何一條碰到該路徑的斷言,紅數就過期。這與本 repo `tests/CLAUDE.md` 禁止寫「N 項」是同一類,
    **而且更糟:變異的定義本身沒被記下來**。實例:「`--segment-base` 改成軟退化」有兩種合理讀法
    (只退到共同祖先 / 再加上「沒祖先時仍印記下的 base」),review 實測各給 **3 紅與 4 紅** ——
    光看數字分不出是 gate 壞了還是變異寫法不同。

    | 變異(要寫清楚改了哪幾行) | 應該變紅的情境 |
    |---|---|
    | `--segment-base` 不再硬失敗(退到共同祖先) | 既有「起點失效時 --segment-base 要失敗」+ ⑩ 的「必須硬失敗」 |
    | `resolve_fork_base` 的 fork-point 整支拿掉 | 情境 7 的三則(`owed_dirs`)**與** ⑩ 的三則(`reviews_missing`)**各自獨立** —— 這才是「共用函式對兩個呼叫端都承重」的證據(3 + 3,不是「總共 N 紅」) |
    | 只拿掉 `resolve_fork_base` 共用那句警告 | 情境 7 與 ⑩ 的 `said` 各一則 ⚠️ **它只證明共用那句被釘住,不證明各呼叫端自己那句被釘住** |
    | 只打 `reviews_missing` 的「沒有共同祖先」那一支(改成擋 / 拿掉它的警告) | ⑪ 的兩則。⚠️ **修正前這兩個變異各 0 紅** —— ⑪ 把 `docs/reviews` 連目錄刪了,opt-in 判準不成立、那一支根本沒執行到;而 `said "找不到共同祖先"` 是被 `owed_dirs` 的訊息頂掉的 |
    | `--segment-base` 那一支整段改回 2026-11-15 之前的寫法(四種共用一句「段落開始前先跑」) | ⑪ 的 `said "也找不到共同祖先"`、`said "進度表"`、`said "不要重跑"`、`not_said "段落開始前先跑"`;⑭ 的 `said <共同祖先 sha>`、`said "不要重跑"`、`not_said`,壞起點檔那則的三個 `said` 與一個 `not_said`,tree 那則的 `said "內容不是 commit"`。各則 expect(block)與四則 `stdout_empty` 照樣綠 —— 舊版一樣是硬失敗、stdout 一樣是空的 |
    | 有共同祖先那一支多一行 `echo "$fork"`(印到 stdout) | 只有 ⑭ 的「起點被 amend 掉:stdout 是空的」 |
    | 「沒有共同祖先」與「內容不是 commit」共用的尾段多一行 `echo "$base"`(印到 stdout) | ⑪ 的「沒有共同祖先:stdout 是空的」與 ⑭ 的「起點檔內容不是 commit:stdout 是空的」 |
    | 拿掉共用尾段的「這一段還沒做完時不要重跑」那一行 | ⑪ 與 ⑭ 壞起點檔那則的 `said "不要重跑"` 各一則 |
    | 拿掉「…也找不到共同祖先」那一行 | 只有 ⑪ 的 `said "也找不到共同祖先"` |
    | 「沒記過」那一支多一行 `echo "HEAD"`(印到 stdout) | 只有 ⑭ 的「沒記過起點:stdout 是空的」 |
    | `--segment-base` 那一支的 `[ "$(git cat-file -t "$base" …)" = commit ]` 改成 `true`(不是空樹的 tree 也走 merge-base 那幾支) | ⑭ tree 那則的 `said "內容不是 commit"` 與 `not_said "也找不到共同祖先"` |
    ⚠️ 修法與三個空洞斷言陷阱見 `tests/CLAUDE.md`。
  - ⚠️ **`shellcheck -S warning` clean 不代表變數有局部化**:
    曾有函式宣告了**死的** `local`,真正用的變數卻是**漏宣告的全域** —— shellcheck 乾淨,一個字都沒說。
    要查局部化只能自己對 `local` 清單與函式內實際用到的變數名。
  - 列檔案的 git 指令都經過 `gitq`（`core.quotePath=false`）：git 預設把非 ASCII 路徑加引號跳脫，
    副檔名比對不到，中文目錄等於完全不檢查
  - 行為的回歸測試是 `tests/test-gate.sh`（CI 在 ubuntu 與 macOS `/bin/bash` 3.2 各跑一次）。本機跑：

    ```bash
    /bin/bash tests/test-gate.sh              # 測 repo 裡這份 gate
    /bin/bash tests/test-gate.sh /tmp/gate.sh # 測改壞的副本（變異測試）
    ```
- `dd-init-upgrade.sh` — `/dd-init` 升級舊蓋章區塊時的分類器（2026-10-30，S2）。把專案根目錄 CLAUDE.md 裡帶
  `dd-loop-version` 標記的區塊逐行分成「範本原文」（去前後空白後逐字等於腳本內 heredoc 清單的某一行）與「在地內容」，
  `--plan` 只印分類、`--apply <檔> <輸出>` 寫合併結果到另一個檔、`--list` 印清單；三個模式都不改原檔。用法、exit 碼與清單的
  產生指令寫在檔頭。
  - **清單是歷代蓋章區塊的行**：改了 `commands/dd-init.md` 的蓋章區塊就要把新的行加進 heredoc（產生指令在檔頭，要用 bash 跑）
  - **分類核心是一支 awk、一律 `LC_ALL=C`**：中文比對與「共同前綴 60 bytes」按位元組算，macOS 的 BWK awk、Debian 的 mawk、
    gawk 結果一樣（三種都實跑過）。別用 gawk 專屬函式（`gensub`、`asort`）—— ubuntu runner 的 `awk` 不保證是 gawk
  - **找區塊**：起點是標記上方最近的標題；往下切單位（空行跟著前一個、圍欄整塊一個），遇到「同級或更高、不在清單裡」的標題停；
    終點是停下之前**最後一個範本單位** —— 它之後的在地內容原地不動。在地單位跟著前面最近的範本錨點（編號步驟行、`驗證不過`、
    `CLAUDE.md 維護` 標題）插回新區塊同一處。專案改寫過的步驟行（第 0 欄的 `N. `）本身算在地，但它底下的子項仍錨到步驟 N
  - **標題比對不看 `#` 的個數**（`inL()`）：區塊掛在在地標題底下時，`--apply` 會把新區塊的標題降級（`## CLAUDE.md 維護` → `####`）；
    逐字比對的話下一次升級會把降級後的標題當在地行留下，多一個空標題（S2 步驟 4 實測）
  - **`--apply` 的輸出路徑已經存在就 exit 6、不寫**（一般檔、目錄、symlink、懸空 symlink 都算；2026-11-14 S1-1）：
    awk 的 `print > out` 會跟著 symlink 寫到它指的地方，clone 帶進來的 symlink 可以指到專案外
    （security-audit 試跑找到）。檢查放在建 `WORK` 之前，`--plan` 不受影響
  - 情境測試 `tests/test-dd-init-upgrade.sh`（變異對照見 `tests/CLAUDE.md`）
- `dd-stop.sh` — `/dd-stop` 的本體（2026-11-17；設計與使用者的決定在 `docs/designs/2026-11-17-dd-stop-design.md`）：`on`／`off`／`status`，暫停與恢復一個專案的 8 步迴圈（步驟 3–8）與 gate。
  用法、exit 碼、標記段開頭行兩個旗標（`created`、`sep`）的意思寫在檔頭。在專案的哪一層跑都可以，一律到 `git rev-parse --show-toplevel` 那一層做事。
  - **暫停有兩半，少一半就不算暫停**：旗標 `git config --local dd.stopped true`（gate 讀它，見上面 `check-claude-md.sh` 的「暫停旗標」條目）與
    repo 根目錄 `CLAUDE.local.md` 裡的標記段（Claude 讀它 —— `.git/config` 不在 context 裡）。`status` 兩邊各印一行，不一致時多印一行、不自己修
  - **它找的是跟自己同目錄的 gate**（`$(dirname "$0")/check-claude-md.sh`），不是專案 pre-commit 實際掛的那一份。`on` 先 `grep 'dd\.stopped'` 那份 gate，找不到（舊版或不在）就 exit 3、什麼都不做：
    旗標設了而 gate 不認得的話，Claude 照聲明不補 CLAUDE.md、commit 卻被擋。專案的 hook 掛的是別處的 gate 副本時（例如本 repo 的 `core.hooksPath` 跑 repo 這份、而使用者跑部署版的 `dd-stop.sh`），這個檢查看的不是同一份
  - **`CLAUDE.local.md` 是 symlink、不是一般檔、或已經進版控時不寫**：`on` exit 4、旗標沒設；`off` 在檔裡有標記段時 exit 5、旗標照樣清掉、不印「8 步迴圈已恢復」（檔裡沒有標記段就照常恢復）。
    不進版控靠 `git rev-parse --git-path info/exclude` 加一行 `/CLAUDE.local.md`（已經被別的規則忽略就不加）；`off` 不拿掉那一行。
    寫不進去（唯讀的檔、不能寫的目錄）走同一組 exit 碼，訊息是「寫不進」：`on` exit 4、這次沒有動旗標；`off` exit 5、標記段還在。
  - **`on` 先寫 `info/exclude` 與聲明、最後才設旗標**（2026-11-17 步驟 4 審查後改的；原本先設旗標）：寫聲明失敗時不可以留下「旗標設了、聲明沒寫」——
    gate 已經放行每個 commit，而 `commands/dd-stop.md` 回報的是失敗、Claude 也讀不到聲明，要等有人跑 `status` 才看得出來（拋棄式 repo 實跑：唯讀的 `CLAUDE.local.md`，舊順序跑完旗標是 `true`、標記段 0 份）。
    旗標設不了（`git config --local` 寫不進去）是 exit 1：這時聲明已經寫了，訊息叫人跑 `off` 拿掉。這一種留下的是「聲明在、旗標沒設」，gate 照擋，看得出來
  - **`remove_blocks` 是在 `do_off` 的 `if !` 裡被呼叫的，bash 在那種位置不套用 `set -e`**：裡面寫檔的每一步用 `&&` 接成一組，有一步不成就印「寫不進」回 1。
    原本沒有接：寫回失敗時檔案沒變，`while` 下一圈又找到同一個標記段，永遠重跑（唯讀的檔與不能寫的目錄各實跑一次，都要靠 alarm 砍掉）。在這個函式裡加寫檔的步驟時照樣接進那一組
  - **`off` 之後 `CLAUDE.local.md` 要跟 `on` 之前逐位元組相同**：原本不存在的刪掉，原本就在的（含 0 bytes）留著。原檔結尾沒有換行時 `on` 多補一個換行（`sep=1`），`off` 一起拿掉 ——
    但標記段後面有使用者暫停期間自己加的字時留著那個換行，不然原檔最後一行會跟他加的第一行黏在一起。切檔用 `head -n`／`tail -n +`／`head -c`（照原樣搬位元組），不用 awk：awk 會替最後一行補換行
  - **`off` 的欠帳清單是不帶參數跑一次同目錄的 gate**，輸出縮排兩格原樣印，前面先印「以下是 gate 的欠帳檢查（這次沒有 commit 被擋）：」—— gate 那段輸出的第一行是「commit 已擋下」，沒有這一行說明會被讀成有 commit 失敗。
    gate 的 exit code 不當成 `off` 的失敗。跑的時候把 `SKIP_DOC_CHECK` 清成空的（留在環境裡的話 gate 直接跳過、還會記起點）。
    gate 不帶參數時看的是「現在 staged 的」加「起點以來的欠帳」，所以這份清單也會列出暫停中已經 `git add`、還沒 commit 的改碼目錄，比「暫停期間欠的」寬。
    起點檔在而內容不是 commit 也不是空樹時，gate 不帶參數、沒有 staged 是靜靜 exit 0，所以 `off` 自己另外查一次，印「起點檔壞了，暫停期間的欠帳算不出來」，不印「沒有要補的」
  - **已知限制**：①`git config --local` 在同一個 repo 的所有 worktree 共用，`CLAUDE.local.md` 每個 worktree 各一份：在 A worktree 暫停，B 的 gate 也停、B 的 Claude 卻讀不到聲明
    ②已經開著的對話不會重讀 `CLAUDE.local.md`：暫停前開的要重開才會停，暫停期間開的要重開才會恢復（會不會中途重讀沒有查，設計不依賴它）③使用者自己在終端機的 commit 一樣被放行
    ④`--commands-only` 更新的人有新指令、沒有這支：`commands/dd-stop.md` 第 1 步會停下叫他重跑安裝
  - 情境測試 `tests/test-dd-stop.sh`（每個情境自己開一個 repo；第一個參數換成改壞的副本做變異對照，第二個參數換 gate）。變異對照（2026-11-17；步驟 4 審查修正之後整張重跑：表上每個變異都有紅、都跑到最後一則「N 不在 git repo」、判定行數與固定版相同；步驟 4 加的那幾列（「不認『不是一般檔』」到「找不到 gate」）另在 ubuntu:24.04 容器以一般帳號跑過，紅在同樣幾則。刻意不記個數，加一列就會過期）：

    | 變異 | 紅在哪 |
    |---|---|
    | `on` 不設旗標 | A「on 之後旗標是 true」、A status 的兩則、G 與 G2 暫停中的 commit、K「旗標是 true」、M2「.git 不能寫」的三則（設不了也不報） |
    | `on` 不查舊版 gate | F 裡 `on` 拒絕的那六則（舊版 gate 四則、沒有 gate 兩則） |
    | 不認 symlink | D：`on` 拒絕那五則、`off` 回 5 那幾則、「symlink 還是 symlink」 |
    | 不認已進版控 | E：`on` 拒絕那五則、`off` 回 5、不印已恢復、「檔案沒被動」 |
    | `on` 每次都加標記段 | A「重跑 on：標記段仍一份」「內容與第一次相同」「off 之後不存在」 |
    | `on` 不寫 `info/exclude` | A 的四則（有那一行、`git status` 看不到、重跑仍一行、`off` 後留著）、K、L「新的那一行自成一行」 |
    | `on` 不看是否已被忽略 | L「已經被忽略：不再寫」、A 兩則（重跑變兩行） |
    | `on` 不補換行 | B 兩種結尾沒有換行的原檔各三則、C「兩行沒有黏在一起」、K 兩則 |
    | `info/exclude` 不補換行 | L 兩則 |
    | `off` 不拿掉補的換行 | B 兩種結尾沒有換行的原檔與 K 的「逐位元組相同」 |
    | `off` 在後面有字時也拿掉補的換行 | 只有 C「結尾沒有換行的原檔：兩行沒有黏在一起」 |
    | `off` 不刪自己建的檔 | A「off 之後不存在」、F「沒有 gate 的 off：不存在」、M2「目錄不能寫」那幾則（刪檔那一步沒跑，就沒有失敗可報）與 M2 最後的「off 之後不存在」 |
    | `off` 空檔一律刪 | B「原本 0 bytes」的兩則 |
    | `off` 不清旗標 | A、D、E、F、M、M2 的「旗標沒了／照樣清掉」、G「off 之後 commit 被擋」等（gate 還在暫停，欠帳清單印不出來） |
    | `off` 不跑 gate | A「沒有要補的」、G 與 G2 的 `a/CLAUDE.md`、G 兩則順序、H「算不出來」 |
    | `off` 不清 `SKIP_DOC_CHECK` | 只有 G2 的兩則 |
    | `off` 不認壞起點檔 | 只有 H 的兩則 |
    | `off` 一律印 review 那行／不印 | A 的 `not_said "docs/reviews"`／I 的兩則 |
    | `off` 只拿第一份標記段 | C「兩份標記段」的兩則 |
    | `off` 聲明還在也往下印已恢復 | D、E、M、M2 兩種寫不進的 exit 5 與不印已恢復 |
    | `off` 不擋 symlink／版控 | D、E 的 `off` 那幾則 |
    | `off` 沒有結尾行照樣切 | M 的三則 |
    | `status` 不報不一致／值不是 `true` 也算暫停 | J 的兩則「不一致」／J「dd.stopped=false 算沒有暫停」 |
    | 多一個參數照跑 | N「多一個參數」「用法錯時旗標沒設」 |
    | 不 `cd` 到 repo 根目錄 | K「標記段寫在 repo 根目錄」「子目錄沒有多出」 |
    | 聲明沒寫日期 | A「聲明有日期」 |
    | `off` 欠帳清單沒有說明行／已恢復印在欠帳之前 | A 與 G 的說明行、G 的順序／G「已恢復在欠帳清單之後」 |
    | 不認「不是一般檔」 | 只有 E2 的 `said "不是一般檔"`：`on` 改成先寫聲明之後，寫進目錄會失敗，照樣 exit 4、旗標沒設，另外三則照綠 |
    | `off` 寫回改用 `mv` | C「原檔的權限沒變（600）」、M2 唯讀檔的 `off` 那四則（`mv` 換得掉唯讀的檔，於是印了已恢復） |
    | `status` 不加 `--local` | 只有 J「只設在 global」的 `said "沒有暫停"` |
    | `on` 改回先設旗標才寫聲明 | M2「on 寫不進：旗標沒設」、M2「.git 不能寫」的 exit 碼與 `said "旗標設不了"` |
    | `on` 聲明寫不進去照樣往下 | M2 唯讀檔的 `on` 三則（exit 碼、不印已暫停、旗標沒設） |
    | `on` 旗標設不了不報 | M2「.git 不能寫」的三則 |
    | `off` 寫不進之後不回 1／寫檔各步的結果不接（改回修之前） | M2 兩種 `off`：被 `limit` 的 alarm 砍掉，判成「輸出裡有 shell 錯誤」；後者另紅兩則 `said "寫不進"` |
    | `off` 找不到 gate 時印「沒有要補的」／直接失敗 | F 的 `said "欠帳沒有查"` 與 `not_said "沒有要補的"`／F「off 照樣恢復」的 exit 碼與 `said "8 步迴圈已恢復"` |

    ⚠️ 測不到的：聲明對 Claude 有沒有用（那是 `docs/measurements/2026-11-17-dd-stop/` 的實測）、worktree、`off` 途中被中斷留下的 `dd-stop.tmp`（在 git 目錄裡，下次 `off` 會覆寫）。
    沒有測試的：`on` 寫不進 `info/exclude`（拋棄式 repo 實跑過一次：一行 shell 錯誤、exit 1、旗標與聲明都沒動）；以 root 跑時 M2 整節不跑（見 `tests/CLAUDE.md`）。
    ⑰ 與 G 最後那則「欠帳銷掉了」的對照是 gate 的變異：把 `owed_dirs` 銷帳那一行的條件改成恆假，⑰「a/ 的欠帳已銷」與 G「補完之後」變紅，兩邊原本的「補上就放行」照樣綠（它們放行是因為記憶檔同批 staged）
- `githooks/pre-commit` — 本 repo 自用（dogfood）：先跑 `githooks/claude-md-size.sh --staged`（根目錄 CLAUDE.md 的大小上限，2026-11-16 加的；
  `SKIP_DOC_CHECK=1` 不跳過它），非 0 就擋下，再轉呼叫上面的 gate。那一層三個檔（hook、大小檢查、上限檔）的說明在 `githooks/CLAUDE.md`。
  **不部署**到 `~/.claude/`；啟用方式：`git config core.hooksPath scripts/githooks`。
  注意 `core.hooksPath` 設定後 git 會完全忽略 `.git/hooks/`，與 `/dd-init` 的
  預設掛載點互斥（dd-init Phase 3 會偵測並改掛到 hooksPath 目錄）。

## 此層慣例

- 新增要部署的腳本：檔案放這裡 + 加入 `DD_SCRIPTS` 陣列 + `--force` 重新部署
- 腳本必須通過 `shellcheck -S warning` 且可在 macOS bash 3.2 執行。CI 的 ShellCheck step
  是逐檔列出的（`.github/workflows/ci.yml`），新增腳本要自己加進清單，否則 CI 根本不會檢查它。
  3.2 相容性由 CI 的 macOS job（`bash32`）用 `/bin/bash` 實跑行為測試來驗 —— 它只抓得到行為測試碰得到的程式碼，
  新腳本要有行為測試並加進那個 job，才算有驗 3.2
- 變數後面緊接全形字（`）`、`：`）一律寫 `${var}`。`$var）` 在 macOS bash 3.2 會把全形字吃掉一半：
  變數值不見、只剩亂碼。實測 `zh_TW.UTF-8`、`en_US.UTF-8` 都會，macOS 的 `C.UTF-8` 與 Linux bash 5.2
  （`C.UTF-8`）不會；不報錯，shellcheck 連 style 級都不警告（2026-09-11，gate 的 `rm ${BASE_FILE}）` 踩過）
- gate 的檢查邏輯或輸出改動時，同步檢視全域模板 §3.9 與 `skills/dd-loop/SKILL.md` 對 gate 行為的描述，以及 `skills/task-planner/SKILL.md`
  進度表規則區塊依賴的 gate 行為：`--start-segment` 印出的起點（完整 SHA，還沒有 commit 時是空樹）、有欠帳時拒絕重記、
  SKIP 記帳、只查 CLAUDE.md 有沒有一起 staged 而不查內容、有 `docs/reviews/` 時先停要有申報檔才開得了別段。
  另外兩處認的是 gate 印的**字串**,改字就要跟著改:`--segment-base` 失敗時的那幾句(`skills/dd-loop/SKILL.md`「段落起點與 `<起點>`」與 `skills/code-simplifier/SKILL.md`「取不到起點」)
- 改了 gate 或它的情境測試，要故意把 gate 改壞一行（例如拿掉 `grep -qxF "$md"` 的 `-x`）存成副本，
  用上面的第二種跑法確認會出現 ❌。全綠不代表有在檢查：2026-09-11 拿掉 `-x`、讓 staged 清單被空白拆開，這兩種改壞法
  在當時的 57 個情境下照樣全過，補到 61 個才抓到

## 與上層的關係

安裝腳本的 `create_scripts()` 負責部署（覆蓋前有差異備份）；gate 的使用情境
定義在 `templates/global/CLAUDE.md` §3.9 與 `DD_PIPELINE_ARCHITECTURE.md`「核心工作法」。
