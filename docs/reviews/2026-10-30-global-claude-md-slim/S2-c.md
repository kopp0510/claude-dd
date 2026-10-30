# S2-c：審查者 C（dd-init Phase 0／1 流程與 CI）

## 派工

`subagent_type: code-reviewer`，三個審查者同一則訊息平行派出。派工 prompt 是「先讀共用指示，再讀自己的方向」兩份檔，逐字如下。

共用指示：

> 你是 code-reviewer。repo：/Users/danlio/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md，全域規則在 templates/global/CLAUDE.md）。
> 審查範圍：段落 S2 的整段改動 = `git diff f2ab54a`（工作目錄乾淨，等於 f2ab54a..HEAD）。改動與被改檔的整檔內容都在 diff 檔：
> /private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/s2-review/diff.txt
> （7865 行。用 Read 的 offset/limit 每次 300 行讀到最後一行 —— 一次讀太多會靜靜截斷、不報錯。被改到的檔一律讀 diff 檔裡那份；沒被改到的檔照常讀 repo。）
> diff 檔第 ④ 節是已跑過的驗證與結果，已確認、不要重跑測試／安裝／claude -p。
>
> 這段做了什麼（事實）：
> - S2-1（489bf74）新增 scripts/dd-init-upgrade.sh（升級分類器：舊蓋章區塊逐行查表分成範本行／在地行，--plan/--apply/--list）與 tests/test-dd-init-upgrade.sh，CI 加進 shellcheck 清單、ubuntu 與 bash32 job。
> - S2-2（304b0f2）commands/dd-init.md 蓋章區塊 rev 12（96 行）換成 rev 13（37 行），只在舊區塊裡的內容搬進 skills/dd-loop/SKILL.md；Phase 1 的 8step 舊版升級改用腳本；React 片段移到區塊外的 ````markdown 圍欄；CI 新增「現行蓋章區塊的每一行都在升級清單裡」；同批改 CHANGELOG、UPGRADING、根 CLAUDE.md、scripts/CLAUDE.md、tests/CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、設計文件。
> - 7b8638a：SKILL.md 的 `US$5.13` 改成「5.13 美元」（skill 帶參數呼叫時 `$<數字>` 會被代換）。
> - 舊區塊（rev 12）原文：`git show v1.6.12:commands/dd-init.md`。
>
> 你的職責：找漏洞，證明這段有錯。每條附證據（路徑:行 + 原文，或指令與輸出）；沒證據不算。只用手上的資料判斷，需要外部查證的列出來交回。
> 嚴重度：Critical / Important / Smell。不寫優點。
>
> 輸出格式：
> ## Findings（每條：級別｜檔:行｜問題｜證據｜失敗情境）
> ## Not reported（看到但判定不算的，一句理由）
> ## What I ran（指令照貼）

方向：

> 你的方向（C）：commands/dd-init.md 的 Phase 0／1 流程與 CI。
> - 照 Phase 0、1（含「用升級腳本升級」1–8 步）走各種專案狀態：rev 12、rev 比 13 大、6step、無標記有 ## 開發流程、無標記無標題、掛在 ### 工作流程 底下、CLI 專案、React 專案、有未 commit 修改。找判斷順序漏接、互相矛盾、照做會壞的句子。對照 Phase 5 的 git add 與 .gitignore 處理。
> - .github/workflows/ci.yml 這段新增／改動的 step：抽取是否自證、會不會在壞掉時照樣綠、ci.yml 其他既有 step（四方一致、rev 跳號、第五方、~/.claude 路徑、數字宣稱）在新區塊下是不是還量得到它該量的東西（例如 rev_on_line 讀到的是不是判定線上的 13）。
> - DD_PIPELINE_ARCHITECTURE.md CI 防線表的新列與 step 實際行為逐句比對。

## 發現

（審查者交回的完整報告，逐字）

Critical 0 / Important 3 / Smells 1。範圍：S2 的 `git diff f2ab54a`（方向 C：dd-init.md 的 Phase 0／1、ci.yml、DD_PIPELINE_ARCHITECTURE.md 的 CI 防線表）

## Findings

**Important｜commands/dd-init.md:115–130、ci.yml「dd-init 蓋章區塊改了就要跳 dd-loop-rev」的 `stamp()`、根 CLAUDE.md:288–289｜改了 React 片段不必跳 rev，CI 也擋不到**
- 證據：
  - React 片段原本在蓋章區塊裡（`git show v1.6.12:commands/dd-init.md`：第 113 行在第 52–149 行的 ```markdown 圍欄內）。這次搬到區塊外的 ````markdown 圍欄（dd-init.md:117–130）。
  - rev 跳號 step 的 `stamp()` 只取 `/^```markdown$/` 到下一個 `/^```$/` 之間的內容，抓不到 React 片段。
  - 根 CLAUDE.md:288–289 的「界線」仍寫「蓋章區塊 = 三個反引號 markdown 圍起來…的那一整塊；Phase 0–6 的執行指示在區塊外，改它們不必跳 rev」。這次只在 ⑤ 加了「含區塊外 React 片段」，界線那句沒改。
- 失敗情境：
  1. 下一段修正 React 片段的內容（例如換掉 `browser_evaluate` 的寫法），依界線規則不跳 rev，CI 跳號 step 也照樣綠。
  2. 已蓋 rev 13 的 React 專案跑 `/dd-init`，Phase 1 判「含 rev 13 → 已是現行版，跳過」，永遠拿不到這次修正，也不報錯。
- 這正是根 CLAUDE.md 寫明要擋的情境。清單 step 雖然有查 React 片段，但它只管「行在不在清單裡」，不管 rev。

**Important｜commands/dd-init.md:65 與 :57、scripts/dd-init-upgrade.sh:268（partial）｜React 圍欄被改過一行時，升級後會有兩份 React 程式碼，第 7 步沒有處理指示**
- 證據：
  - 腳本把圍欄當一個單位：裡面不是每行都在清單中，就整塊保留，並列在「保留的圍欄裡有部分行在清單中」。
  - tests/test-dd-init-upgrade.sh:168–173 實測：React 的 ```js 圍欄改一行，結果是「1/2 行在清單中」、整塊保留。
  - 圍欄周圍的 React 說明行（`- ⚠️ **React 專案**…`、`表單送不出去時…`）各自都在清單裡，會被刪掉。
  - 第 7 步只處理兩件事：7.1 佔位行、7.3「疑似改寫過的步驟行」與「區塊外還有範本行」。「部分行在清單中」那一節只在第 4 步列給使用者看。7.2 則一律「偵測到 React 就補上 React 那段」。
- 失敗情境：rev 12 的 React 專案在 `set.call(...)` 那行加過註解，跑升級後：
  - 舊的 js 圍欄留在步驟 5 底下，前後沒有任何說明文字。
  - 7.2 又在 `- 截圖一律存` 底下補一份完整的 React 片段。
  - 最後 CLAUDE.md 有兩份 native setter 程式碼，其中一份是孤兒。7.3 的檢查只數步驟編號，照樣放行。

**Important｜commands/dd-init.md:67｜「1–8 每號剛好一行」的檢查對整個檔案 grep，專案在區塊外有編號清單就永遠過不了**
- 證據：原文是「用 `grep -nE '^[0-9]+\. ' CLAUDE.md.dd-upgrade` 確認 1–8 每號剛好一行，才往下走」。這條 grep 掃的是整個輸出檔，不是只掃區塊。
- 實測的 fixture 都沒有區塊外的編號清單，所以測不到：docs/measurements/2026-10-30-dd-init-upgrade/setup.sh:18–28 只有 `# 測試專案`／`Node 服務。`／`## 部署 - LOCALD`；tests 也一樣。
- 失敗情境：
  1. 專案 CLAUDE.md 有 `## 安裝` 底下的 `1. npm i`、`2. cp .env…`，`--plan` 又列了「疑似改寫過的步驟行」。
  2. 合併後 1、2 號各有兩行以上，條件永遠不成立，agent 卡在「才往下走」。
  3. 或者 agent 為了湊成「剛好一行」，去刪或改區塊外專案自己的清單。

**Smell｜commands/dd-init.md:62–64｜CLI 專案的佔位行處理，兩句互相矛盾**
- 證據：第 62 行說「不適用的那行刪掉（沒有前端時，playwright 那行連同底下的截圖子項一起刪）」；第 64 行說「純 CLI／函式庫專案兩行都換成『跑真實指令 / 消費端範例』的具體指令」。
- 失敗情境：CLI 專案照第 62 行該刪 playwright 行與截圖子項，照第 64 行又該把 playwright 行換掉。換掉的話，`- 截圖一律存 .screenshots/` 會留在一個 CLI 指令底下。results.txt 的 cli 例只驗了「佔位：0」，沒驗截圖子項有沒有留下。

## Not reported
- 第 6 步 `--apply` 沒寫 exit 非 0 時怎麼辦：exit 5 只在輸出的標記不是一個時發生，而第 2 步的 `--plan` 已經擋過同樣的輸入，想不出實際會碰到的情境。
- 有兩個 `8step` 標記的專案（舊版 Phase 1 曾加第二份區塊，CHANGELOG 提到 rental-management）：會走到第 2 步 exit 4 →「不升級、告知原因」，之後沒有任何路可以升級。這要先查證真的有專案長這樣才算數，所以沒列入，見下方外部查證。
- `含 dd-loop-rev: 13` 是子字串比對，rev 130 也會命中。離現在太遠，不算。
- 新 CI step 的 `comm -23` 需要清單照 C 語系排序。如果有人照錯誤訊息把新行接在 heredoc 尾端，CI 會紅燈，但錯誤訊息不明確。目前的清單是排序過的，也不會靜靜變綠。
- 使用者拒絕升級時，Phase 5 仍會 `git add CLAUDE.md`，把他本來沒 commit 的修改一起送進去。這是改動前就有的行為（「已是現行版」那條也一樣）。
- 我核對過、沒有問題的部分：
  - 四方一致的 `count_block`：`'^## 開發流程'` 只命中第 74 行，算出 8 步。
  - `rev_on_line` 讀判定線：dd-init.md:40 與 UPGRADING.md:82 都讀到 13。
  - rev 唯一性：只有 `dd-loop-rev: 13` 一種。
  - `~/.claude/scripts/dd-init-upgrade.sh` 已在 DD_SCRIPTS 裡，會部署。
  - 防線表新的兩列（fixture 來源 v1.6.12／v1.6.4／6a9addd／v1.1.0、兩個 job 都設 `fetch-depth: 0`）與 ci.yml、測試檔逐句對得上。

## 需要外部查證（我沒有去查）
- `grep -c 'dd-loop-version' <rental-management 等專案>/CLAUDE.md`：如果結果 ≥2，Phase 1 對這些專案是死路（exit 4 之後沒有退路），上面那條就該升成 Important。

## What I ran
- `cat prompt-common.txt; cat dir-c.txt` → 讀到派工指示
- `grep -nE '^(…|diff --git|…)' diff.txt` → 取得 diff 檔的目錄
- Read diff.txt 1–215、4715–5030、7092–7461、5391–5491 → ci／CHANGELOG／ARCH／UPGRADING 的 diff、dd-init.md 整檔、升級腳本整檔、量測檔
- `sed -n 1,20p; 304,467p; 492,545p .github/workflows/ci.yml` → 讀既有的 step
- `grep -n '舊版/手寫版' commands/dd-init.md; grep -n '判定為舊版' UPGRADING.md; grep -n '^## 開發流程' commands/dd-init.md` → 各在 40、82、74 行
- `scripts/dd-init-upgrade.sh --list | LC_ALL=C sort -c` → sorted
- `sed -n 286,290p CLAUDE.md` → 界線那句沒包含 React 片段
- `git show v1.6.12:commands/dd-init.md | grep -n 'React\|^```'` → 舊版 React 在第 52–149 行的區塊內
- `grep -nE 'git show|v1\.|6a9addd' tests/test-dd-init-upgrade.sh; grep -n fetch-depth ci.yml` → 與防線表一致
- `sed -n 160,182p tests/test-dd-init-upgrade.sh` → React 圍欄部分保留（1/2）的測試

## 處置

- Important｜React 片段搬出區塊後改它不必跳 rev、CI 擋不到 → **採納**。ci.yml 跳號 step 的 `stamp()` 把 ````markdown 圍欄接在區塊後一起比；根 CLAUDE.md 的「界線」與架構文件 CI 表同批改。負面測試在拋棄式 clone 打假 tag `v9.9.9`：內容相同 → 綠；只改 React 一行 → 紅；只改區塊一行 → 紅
- Important｜React 圍欄部分在清單時會兩份並存 → **採納**。7.2 改成「`--plan` 那一節列到 React 的 ```js 圍欄時先問留哪份，不要兩份並存」
- Important｜7.3 重號檢查掃整份檔 → **採納**（同 A 第 1 條，處置見 S2-a）
- Smell｜CLI 專案佔位行兩句矛盾 → **採納**。CLI 專案改成 curl 那行換成跑真實指令、playwright 那行連截圖子項刪掉
- 外部查證「有沒有專案帶兩個標記」→ 我查了：12 個已蓋章專案 `grep -c 'dd-loop-version'` 全是 1，exit 4 的死路目前沒有專案會走到；維持 Not reported
