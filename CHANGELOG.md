# 變更紀錄

記錄影響使用方式的結構性變更。版本號採[語意化版本](https://semver.org/lang/zh-TW/)，
格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，
每個版本對應一個 git tag（`git show v1.0.0`、`git log v0.4.0..v0.5.0` 可看該版完整內容）。
升級步驟見 [UPGRADING.md](UPGRADING.md)。

**發版步驟**（「未發布」累積到值得發一版時）：

1. 把 `## 未發布` 改成 `## <版本> — <YYYY-MM-DD>`（不留空的未發布區塊，下次直接新開）
2. `git commit -m "docs: CHANGELOG 整理為 <版本>"`
3. `git tag -a v<版本> -m "<一句話重點>"` —— tag 指向上一步那個 commit
4. `git push origin main --tags`
5. `gh release create v<版本> --title "v<版本> — <重點>" --notes-file <該節內容>`

> 0.2.0 涵蓋專案初始（2025-12-15）到 2026-07-24 的所有變更，但只有 6 步迴圈改造
> 這一項被逐條記錄；更早的細節見 git 歷史。

## 未發布

### 全域 CLAUDE.md:72 條候選蒸餾成 7 條,**淨 ±0 行**

來源是 2026-10-07～10-09 共 14 個功能段落的步驟 7,累積在一個專案的 4 份設計文件裡。
⚠️ **原本的提案是 9 項、自稱「淨增 60–80 行」,被兩個顧問推翻**:
fable 用 `wc -c` 逐項驗出「取代」實際上**都變長**(真實 +105 行 / +9.4 KB);
advisor 指出判準該是**判準 vs 過程** —— 而本檔當時 757 行裡
**13 行帶日期、16 行含「實測」、6 行含工具名**,已經是「某一次 review 的過程紀錄
穿著全域規則的衣服」。

**定案的 7 條**(每項 ≤5 行、零日期、零「實測:」、零工具名):

- §3.9 **取代**「紅數不是證據」那 10 行 → 「**0 紅 / 沒有差異 / 無輸出的第一個嫌疑人永遠是實驗本身**」
  三項自檢(變異生效了嗎 / 總數對得上嗎 / 實驗到達那個狀態了嗎)
- §3.9 鑑別力那條追加:**有牙只證明「與舊碼在這一格不同」** ——
  不證明新的那邊該發生、也不證明清單是全的
- §3.9 **取代**「grep 同型兄弟」那 7 行 → 「**diff 動到的每個識別符各跑一次 `git grep`**,
  逐條核『這句話在 HEAD 還成立嗎』」;要找的是**誰提到這個符號的性質**,不是同型
- §3.9 **取代**「抽共用元件」那 7 行 → 「**清點先問「誰有資格進入分母」**」四條做法
  (排除樣式錨定完整識別符並把已知目標餵進去 / 分母含元件自己那份 /
  從「誰在做決定」反推 / 縮範圍時列原始清單逐項標做不做)
- §3.9 步驟 4:**派工 prompt 交事實,不交「我判斷元凶是 X」**(自己的錯誤診斷會讓 reviewer 跟著錯)
- **§3.5**(原本 `mock` 零命中):**mock 掉承重的那一支是空通過最常見的偽裝** +
  端到端要印出中間經過了什麼
- **§6.1**:**回問前先驗問題的前提,再逐條對照每個選項擋得住什麼** ——
  使用者是在我寫的框架下做決定的

**同批壓掉的敘事**(為了讓淨變化是 0):reviewer 五發實驗的 wall-clock 與實戰細節
(6 行 → 3 行,保留對照實驗的量化結論)、「一行程式碼不是跳過理由」(13 行 → 6 行)。

**退掉的**:①**差異化派工**(a 給查核點 / b 給開放方向)—— 11 個觀察樣本全來自同一個專案,
而「哪個發現最重要」是自評的,**觀察樣本不能推翻對照實驗**;
②「逐層列舉 route→controller→service→repository」—— 那是 Express 形狀,而且只攔得住半族。

**順手修掉一處自我矛盾**:§3.9 開頭「忘了記下一段的起點…只會多審,不會漏」與
90 行後「⚠️ 這也讓全域 CLAUDE.md 那句…**對這個檢查不成立**」直接打架 —— 給前者加了限定。

### `/dd-init` 的專案模板:`dd-loop-rev` 8 → 9

步驟 4 補上「派工 prompt 交事實、不交診斷」,版本檢查清單同批補上 rev 8 的差異。

### `verification-gate`:紅旗 +2 條

本技能的鐵律管「**有沒有跑並讀輸出**」,而這兩條管「**那次執行有效嗎**」:
①寫下「0 紅 / 全綠」而沒先驗實驗本身 ②斷言「有以 X 呼叫」就當成驗過了。
兩條都指回全域檔的判準,**不複製內容**(避免兩份副本各自漂移)。

## 1.6.1 — 2026-10-07

### Fixed

只修正文件敘述，**不含行為變更**（gate、安裝腳本、測試都沒動）。1.6.0 區塊已發布、不改，勘誤寫在這裡。

- **1.6.0 的測試項數**：1.6.0 寫「`tests/test-gate.sh` 新增六個情境（…）**61 → 81** 項」。
  實跑 `tests/test-gate.sh` 數 ✅：v1.5.0 是 61、加入 review 報告擋點的 `bd46245` 是 81、
  **`v1.6.0` 這個 tag 是 90** —— 後 9 項是同一版內 gate 的內部重構（抽出 `resolve_fork_base`，
  兩處退化規則改成共用）補的測試，不影響使用方式。
  61 → 81 新增的 20 項涵蓋括號裡列的 9 種情境（含建立前置 commit 的步驟），不是「六個」。
- **1.6.0 的變異測試紅數**：三組（12／5／2，5 紅裡有 4 項屬舊的 61 項）是在 `bd46245` 量的，
  2026-10-07 依同樣的變異重跑，數字相同；第二組另外直接拿 v1.5.0 的 61 項跑同一個變異，4 紅。
  在 **`v1.6.0` 這個 tag 上重跑是 17／5／2**：第一組多出的 5 紅落在上一條那 9 項後加的情境裡。
- **`UPGRADING.md`「已是 8 步迴圈的專案：補上段落起點」**：「原因見 CHANGELOG『未發布』」改成「1.2.0」——
  那批 2026-09-11 的變更在 1.2.0 發布，這個指向從 v1.2.0 起就是錯的。

## 1.6.0 — 2026-10-07

### `--start-segment` 現在擋得住「上一段沒附 review 報告」

上一節把步驟 4 的證據變成 committed 檔,但只買到「留痕」—— gate 不會強制它存在。
現在 `scripts/check-claude-md.sh --start-segment` 多一個擋點:

- **專案有 `docs/reviews/` 目錄時**(= 採用了這個慣例),開下一段要記新起點前,
  檢查「上一段的 commit 範圍內有沒有新增 `docs/reviews/S*.md`」—— 沒有就 `exit 1`,
  並印出兩條出路(跑步驟 4 / 建 `S<N>-SKIP.md` 申報)。
- **opt-in**:沒有那個目錄的專案完全不受影響 —— gate 既有的 61 項測試**一項都沒改**。
  要退出就刪掉 `docs/reviews/`。
- ⚠️ **剛採用時第一次一定會被擋**(上一段本來就沒報告),補一份 `S<N>-SKIP.md` 即可。
- ⚠️ **`docs/reviews/CLAUDE.md` 不算報告**(不是 `S` 開頭)。
- ⚠️ **擋得住的只有「開下一段」這個時點,pre-commit 不擋** —— 「跑完但永遠不開下一段」
  仍然繞得過。它買到的是**「要繼續往前走就得先結清上一段」**,不是閉環。

`tests/test-gate.sh` 新增六個情境(導入路徑、SKIP 放行、沒報告擋下、兩份報告放行、
`CLAUDE.md` 不算、**只改既有報告不算新增**、**amend 過的歷史仍照擋**、`SUMMARY.md` 不算、刪目錄退出),
**61 → 81** 項。

**變異測試三組**(⚠️ 第一版只寫一組而且量錯對象):把 opt-in 那行改成永遠 `return 1` → **12 紅**
(證明新情境在測這個功能);**把那行整個拿掉** → **5 紅、其中 4 在舊的 61 項**
(**這組才是「沒採用的專案完全不受影響」的佐證**);`--diff-filter=A` 改回 `ACMR` → **2 紅**。

**升級**:`git pull && ./install-dd-pipeline.sh --force`,再到各專案跑 `/dd-init`。
已經在用 `docs/reviews/` 的專案升級後第一次 `--start-segment` 會被擋,照上面補 SKIP 申報。

### 步驟 4 的證據要留痕(§3.9)

8 步迴圈裡只有 commit 那一步有機械強制力,**步驟 4(兩個 reviewer)是最容易靜默掉的一步** ——
它不留痕(跑完什麼都不產生,進度表標 `DONE` 是同一個 agent 自己填的)、最貴(13–17 分鐘 ×2)、
而且跳過條款就寫在它上面幾行。**跳過還會自我延續**:步驟 7 是迴圈唯一固化教訓的格子,
輸入來自步驟 4 的發現 —— 步驟 4 跳掉就沒東西可寫,下一段照樣踩,而剪斷這條回授線不會報錯。

- `templates/global/CLAUDE.md` §3.9 步驟 4 與 `commands/dd-init.md` 的蓋章版同批新增:
  - **兩份報告落地成 committed 檔** `docs/reviews/S<段落>-{a,b}.md`,三節:**派工 / 發現 / 處置**。
    第三節(每項實際怎麼處理)是唯一只有自己寫得出來、也唯一看得出「發現有沒有變成修正」的部分。
  - **證據不可以放 `.git/`** —— 段落起點檔 `dd-segment-base` 走 `git rev-parse --git-path`、
    每個 worktree 各自一份、不進版控;放那裡等於沒留痕。
  - **跳過要申報**:commit 訊息加 trailer `SKIP-REVIEW: <段落> <理由>`。
    ⚠️ 目的是**拿掉「靜默省略」這個選項**,不是讓說謊變不可能(報告內容真偽驗不出來,也不該試)。
  - ⚠️ **明寫這不是閉環**:`.md` 不在 gate 的 `CODE_EXT` 裡,gate 既不會擋也不會強制 ——
    假裝它是閉環只會多一份寫成閉環形狀的清單。
  - ⚠️ **判準用「有沒有引別處」,不是「程式碼幾行」**:diff 裡只要有引別處行號 / 函式 /
    UI 字串 / commit 範圍的敘述,就不是「只有一個運算式」。這一條是**補跑那次 review 給的版本**,
    比原本的寫法好 —— 那段 63 行裡只有 1 行程式碼,而補審在「修正版」裡**又抓到一個新的錯宣稱**
    (把只給後台用的查詢說成客戶端清單:`where` 不過濾,但回傳欄位帶旗標、前端照它畫)
    與一處列舉不全(列 2 處、實際 8 處),兩者都已複製到三四個檔案。
  - ⚠️ **「程式碼只有一行 / 定義域全被測試覆蓋」不是合法的跳過理由**(實證):
    那衡量錯了對象 —— review 真正抓的是**註解與文件裡的宣稱**,不是運算式。
    某段只跑 simplifier 就抓到一句「作者自稱查證過卻仍然錯」的宣稱;下一段同等規模的改動,
    兩個 reviewer 抓出 2 個 Critical。**hotfix 段落通常正是人工判斷最密的地方。**

### 半號段落的定義(§4.4)

`S2.5` 這種插在兩段之間的 hotfix,**有自己的 commit 且改了人工邏輯 → 算新段落,要走步驟 3–8**;
只是補檔進同一個 commit、或純文件/資料改動,才算前一段的小任務。
`task-planner` 的規則區塊只說「ID 不重編,插在中間用 `S2.5`」,**沒說要不要走 3–8**,
而那份規則是照抄進設計文件、不跟著 skill 更新的 —— 實測有一個半號段落就是從這個縫跳過了步驟 4。

### 未做:gate 無法檢查 `SKIP-REVIEW`(技術限制,查證後的結論)

原本想讓 gate 強制「結清一段時要嘛有兩份報告檔、要嘛有 `SKIP-REVIEW` trailer」。**做不到** ——
`scripts/githooks/pre-commit` 是 `exec "$...check-claude-md.sh"`、**不帶參數**,
而 git 的 `pre-commit` 階段本來就拿不到 commit 訊息(訊息要到 `commit-msg` 才有,以 `$1` 傳入)。
要做這件事得**新增一個 `commit-msg` hook** 並改 `install-dd-pipeline.sh` 與 `/dd-init` 的掛載,
那是安裝面的變更,留待決定。(`docs/reviews/` 檔案存在性倒是 pre-commit 檢查得到,
但少了 trailer 這半就分不出「申報過的跳過」與「靜默跳過」,只做一半沒有意義。)

## 1.5.0 — 2026-10-06

### Changed

- **全域模板改成「少停下來問」**（依 Opus 5.5 / Fable 5.1 官方 prompt 建議）：
  §5.2 自己的改動本機 commit 不用問（commit 前看 `git status`、只 add 自己改的檔；push 仍不做）；
  §3.5 相關既有測試改成直接跑（原本與 §3.8「測試指令無需確認」互相矛盾）；
  §6.1 新增「時間很重要」與「自己繼續做」——只在破壞性操作、改變範圍、缺使用者才能給的資訊時停下；
  §6.2 能自己讀檔釐清就先查再回報；§4.2 破壞性清單加「修改目前專案以外的檔案」；
  §1.2 長度表從「硬上限、超過即違規」改成參考長度（官方建議不寫死數字上限）

## 1.4.0 — 2026-10-05


### Added

- **CI 新增「CHANGELOG 已發布區塊不可改動」**：新條目被寫進已發布的版本區塊時，`git diff` 看起來正常、
  其他檢查全綠，發版時會被算進錯的版本。2026-10-05 踩過：用腳本插條目時索引差一位（`n>=36` 跳過
  0-based 35 的 `### Changed`），兩條本輪變更進了 `## 1.2.0`，是使用者問「發版有什麼風險」才翻出來。
  新 step 以最新的 `v*` tag（`--sort=-v:refname`，避開 `pre-prune-*` 這類沒有 CHANGELOG.md 的 tag）為基準，三道：
  - 逐 `## <x.y.z>` 區塊比對，兩邊都存在的版本區塊必須逐字相同
  - **從 tag 裡最新的版本標題到檔尾必須逐字相同** —— 逐區塊比對看不到「新標題插進區塊之間」與「區塊順序對調」，
    因為終止行自己不在比對範圍裡（兩個 reviewer 各自實跑證實：插一塊假的 `## 1.2.5`、把 1.1.0 與 1.0.0 對調，舊版都 exit 0）
  - CHANGELOG 與 tag 有差異、卻既沒有 `## 未發布` 也沒有新版本區塊時擋下 —— 剛發完版沒有 `## 未發布` 這個錨點，
    條目很容易落在前言或最新版本標題正上方，那兩處都在前兩道的範圍外
  需要 checkout 設 `fetch-depth: 0`（實測 `git clone --depth 1` 之後 `git tag` 是 0 筆）；
  抓不到 tag 或 tag 裡沒有 CHANGELOG.md 都明確失敗、不靜默放過。負面測試 11 個變異逐一確認

### Changed

- **CI 的「迴圈步數第五方」列檔案補 `core.quotePath=false`**：git 預設把非 ASCII 路徑轉成八進位跳脫字串，
  `awk` 開不了那個檔名、而該 step 照樣 exit 0 —— 中文檔名的 `.md`／`.sh` 被整道檢查靜默跳過。
  2026-10-05 新增一份中文檔名的設計文件後撞到：裡面放一行步數寫錯的箭頭摘要，修前 exit 0（2 個檔開不了），
  修後 exit 1 並指名該檔。gate 腳本早有這條規矩，當時沒推廣到 ci.yml
- **步驟 4 加一條「想讓它快就界定探索預算」（`dd-loop-rev` 6 → 7）**：使用者問「code-reviewer 還會卡很久嗎」，
  這輪把派送方式真的量了。同一份 prompt、同一個 model、同一份素材，Task 派出的 subagent 要 223/257s，
  同一個 agent 當 headless session 跑只要 115/125s，而**派送管線本身只佔 ~25s**（整體 wall 減掉 subagent 自己的 duration）。
  真正決定時間的是它跑幾次工具：3–5 次 = 2–4 分鐘；同一天 S1 段落那兩發 21/26 次 = 13–17 分鐘，而且 diff 還更小 ——
  差別在問題開放到什麼程度（問「在真實 CI 環境會不會失效」，它就去抓上游原始碼、開 docker 用 mawk 重跑）。
  原始數字與限制在 `docs/measurements/2026-10-05-reviewer-overhead.md`（subagent 為什麼慢一倍沒查出來，jsonl 沒給它的 api 時間）。
  同批把「並行派時 wall 約等於較慢那一發」從「未實測的推論」改成實測值（781s 與 1007s，整體 ~1007s）
## 1.3.0 — 2026-10-05

### Added

- **gate-guard：擋 Claude 用 `--no-verify` 繞過 CLAUDE.md gate**。`git commit --no-verify`／`-n`／
  `-c core.hooksPath=` 會讓 pre-commit 整個不跑，gate 連那次 commit 都看不到；沒記段落起點、或繞過的是
  最後一個 commit 時就完全漏查。新增只有 hook、沒有 skill 的 plugin `skills/gate-guard`（PreToolUse(Bash)），
  在 Claude 執行前 deny，理由指向正式逃生口 `SKIP_DOC_CHECK=1`。只擋 `git commit`：`git config core.hooksPath`、
  `git log -n`、commit 訊息內文的 `-n` 都放行。只擋 Claude，使用者自己在終端機打的不擋；全域生效，沒裝 gate 的專案也擋（Claude 本來就不該自己跳過 hook）。
  先用 `git config core.hooksPath` 把 hook 關掉再 commit 的擋不到（改 hooksPath 是正常設定操作，刻意不擋）。
  promoted Skills 因此從 10 個變 11 個；CI 加跑它的行為測試（該擋、該放行各情境，jq 與 python3 兩條分支都跑）
- **CI 新增 macOS job，用 `/bin/bash` 3.2 實跑行為測試**：腳本規定要能在 macOS 內建的 bash 3.2 執行，但 CI 原本
  只跑 ubuntu（bash 5），3.2 不支援的寫法在那裡照樣全綠。新 job 跑 error-capture、gate-guard、gate 情境與安裝端到端
  測試；後兩者因此從 ci.yml 內嵌搬成 `tests/test-gate.sh`、`tests/test-install.sh`，兩個 job 共用。gate-guard 與 gate
  情境測試另外把 shell 錯誤訊息判為失敗 —— 實測在 gate 加一行 `lc=${staged,,}`，只看結果的話 3.2 下照樣全過。
  CI 也加上 `workflow_dispatch`，可以手動在任意分支跑

### Changed

- gate 擋下 commit 時，「其他處理方式」多一行提醒不要用 `--no-verify`／`-n` 繞過
- **`agents/code-reviewer.md` 大幅瘦身審查成本**（2026-10-02）：實測同一個專案連續四段，
  code-reviewer 每次 20–25 分鐘、35–45 次 tool 呼叫、13–17 萬 token。拆解後改三處：
  - **Fowler 12 項 smell 改成條件掛載** —— 只在該次變更有新增或重構函式／類別／模組邊界時才掛；
    diff 全是資料、設定、註解、文件時整段跳過（原本是 `always carry`，對純註解的 diff 也要比對 12 項）
  - **砍掉 0–100 信心評分**，改 Critical / Important 兩級加一條門檻：
    「能講出具體失敗情境**並**指出依據」才報，否則不報（不是降級報）。原本的分數只被用在 ≥80 這個門檻上
  - **新增 Scope Discipline 一節**：只審呼叫者給的範圍、呼叫者附上的驗證輸出視為已確認不重跑、
    需要範圍外的證據就列出來交回。原本定義裡沒有任何範圍紀律，實測它會自己 `git archive` 解兩棵樹、
    跑到別的 repo 查證
  - **Output Format 改成固定模板**：每條發現 ≤4 行（問題一句 + 失敗情境 + 依據），
    結尾必附「我實跑了什麼」清單（呼叫者靠它免於重做，不可省略），砍掉 fix suggestion 與推理敘述
  - `model: opus` **不動**（本 repo CLAUDE.md 規定官方備份維持上游設定）
- **全域 CLAUDE.md §3.9 步驟 4 加兩條**（2026-10-02）：prompt 要附已跑過的驗證輸出並寫明不要重跑；
  該段沒有「人工寫的程式碼」（diff 全是資料／設定／註解／文件，或改動已被專案的機械檢查完全覆蓋）時
  不派 agent，改成自己核對並附證據。判準是「有沒有正確性還沒被機械檢查證明的人工判斷」，不是 diff 長度
- **`/dd-init` 蓋章版同步上面那條，`dd-loop-rev` 4 → 5**（2026-10-02）：蓋章版步驟 4 補上
  「附驗證輸出、不要重跑」與「沒有人工寫的程式碼就不派 agent」兩條規則（實測敘述留在全域模板，蓋章版只放規則）。
  不跳 rev 的話已蓋章的專案跑 `/dd-init` 會被告知「已是現行版」而永遠拿不到這次修正 —— CI 只驗檔內 rev 前後一致，
  不驗「內容改了 rev 有沒有跳」。同批更新 `UPGRADING.md` 寫死的 rev 值
- 全域模板那條原本寫「在**進度表的執行紀錄**寫明跳過的理由」，但 `task-planner` 的進度表沒有這一欄；
  改成「設計文件『段落與小任務』該段底下」（該 skill 本來就是這樣放結果的）
- 兩份 README 的迴圈清單第 4 步補上「例外見下」，並在迴圈說明段寫出例外內容（原本清單只寫「全量跑」）
- **跳 rev 時第三處要改，`grep -n 'dd-loop-rev'` 抓不到**（2026-10-02）：Phase 1 緊接在「已是現行版」
  之後的「舊版/手寫版」判定線寫的是「有 `8step` 但 rev 比 N 舊」，不含 `dd-loop-rev` 字串。4 → 5 時只改前兩處，
  rev 4 的專案就既不等於 5（不算現行版）、也不比 4 舊（不算舊版），落在兩條分支之間；CI 只驗檔內
  `dd-loop-rev` 唯一性，看不到這行，照樣綠燈。已補上判定線、升級對話框的「rev 4 缺什麼」，
  並把這個第三處與查法寫進 repo CLAUDE.md
- **CI 補驗舊版判定線寫的 rev**（2026-10-02）：併進「迴圈步數四方一致」step。錨在分支標籤
  （`dd-init.md` 的「舊版/手寫版」、`UPGRADING.md` 的「判定為舊版」），取該行 `rev` 之後的第一個數字
  跟現行 rev 比 —— 不盯「rev 比 N 舊」這個措辭，因為措辭跟數字一起被改掉是真實情境，盯措辭的版本
  只會喊「抓不到」而放過數字錯誤。負面測試六個變異：N 改壞（兩檔各一次）、措辭改掉且 N 停在舊值、
  判定線不寫號碼、分支標籤改名 —— 五個紅燈且訊息各自指出病因；只改措辭但 N 正確的那個如預期放過，還原回綠
- 步驟 4 新規則的「跳過理由寫哪裡」補上沒有設計文件時的去處（寫在回報裡），模板與蓋章版同步
- **code-review 改派兩個 reviewer、報告取聯集（dd-loop-rev 5 → 6）**：單發 reviewer 只挖得到一部分。
  同一段 diff（claude-dd `48de43f`，3 個由後續 commit 認定的真錯誤）用 `claude -p --agent` 跑五發，
  每發都只命中 2 項、而且是不同的 2 項：兩發聯集平均 2.3/3，單發 1.8/3（10 組配對中 3 組達 3/3）。
  事後再補一發確認那個「漏抓」是不是系統性的，共六發：3 項中最難的那項命中 4/6，確認是擲硬幣、不是系統性漏抓
  （六發重算：單發 1.83/3、兩發聯集 2.27/3，15 組中 4 組達 3/3 —— 平均數與規則都不變，所以規則文案沿用五發那組數字）。
  同批加上「兩份報告講不一樣時讀程式碼判定、不要表決」—— 實測有一發看到真錯誤卻判成「既有問題」丟進
  Not reported，而那個錯誤寫法正是該次 diff 複製進新路徑的。全域模板 §3.9 步驟 4、`/dd-init` 蓋章版、
  兩份 README 迴圈說明段同批更新
- **`agents/code-reviewer.md` 新增 Work Order**：先讀 diff → 把每個可疑點寫成一行假設 → 能用讀程式碼
  解決的引行號收工 → 只對讀不出答案的合成一支腳本一次測完；並明寫「看得出來的缺陷附行號就夠，不需要重現」。
  動機是實測發現時間不是花在重跑呼叫端的指令（兩版都沒重跑），而是各自去 mktemp 建 repo 跑重現。
  **這條在 n=2、單一素材下量不出改善**（命中數與時間都在雜訊內），收下的理由是規則本身合理且無量測到的害；
  模型時間五發都是 58–84s，2–4 分鐘的 wall clock 幾乎全是非模型開銷，所以改 prompt 本來就動不了時間

### Fixed

- **`/dd-init` 遇到 hook 管理工具時，gate 會變成死碼或被默默洗掉**。舊規則只看既有 hook 的最後一行是不是
  `exit`／`exec`：pre-commit 套件產生的 hook 以 `fi` 結尾、每條路都在 `if … fi` 裡 `exec` 或 `exit`，gate 接在
  後面永遠不執行，之後「已含」的字串比對又一直回報已裝；husky v9（`.husky/_`）與 lefthook 產生的 hook 則會在
  下次 `npm install` 被重寫，gate 靜靜消失。現在：pre-commit 套件與 lefthook 不去改它們產生的檔，只刪掉舊版
  留下的死碼，改給一段 `.pre-commit-config.yaml`／`lefthook.yml` 設定（pre-commit 4.6.2、lefthook 2.1.15 實測；
  pre-commit 那段帶 `stages: [pre-commit]` 與 `verbose: true`，不在 push 時誤擋、放行訊息不被藏起來）；
  husky v9 改掛 `.husky/pre-commit`，husky v8 插在 `husky.sh` 那行之後（8.0.3、9.1.7 實測各跑一次、`HUSKY=0`
  一起跳過）；其他手寫 hook 一律把 gate 插在 shebang 之後，非 shell 的 hook 不插、改問使用者；「已含」改成看位置。
  用舊版裝過的專案重跑一次 `/dd-init`：手寫 hook 當場修好；pre-commit 套件與 lefthook 要等使用者把設定加進去並 commit
- `/dd-init` 裝的 gate 那行改成**找不到 gate 腳本時只警告、不擋**，警告寫明「這次 commit 沒檢查改到程式碼的目錄
  有沒有同批更新 CLAUDE.md」：hook 常會進版控，沒裝 claude-dd 的協作者、或解除安裝 claude-dd 之後，
  原本每次 commit 都會因為找不到腳本而失敗
- `/dd-init` 的掛載點改用 `git rev-parse --path-format=absolute --git-path hooks/pre-commit` 取得，在 monorepo
  子目錄執行也拿到正確的絕對路徑；`core.hooksPath` 是 `/dev/null`、在 repo 外或設在 global 時先告知或詢問

## 1.2.0 — 2026-09-12

### Changed

- **複雜任務動手前先估段落數，兩段以上 Claude 自己叫 task-planner**。原本只有使用者講「拆任務」這類
  關鍵字時一定會叫；沒講就只靠 Claude 讀 skill 說明自己判斷，而且看不出它有沒有判斷過。全域模板 §4.1
  加一條：複雜任務的計畫裡要寫出「預估 N 個功能段落」，N ≥ 2 就呼叫 `task-planner`，使用者沒提也一樣；
  task-planner 的說明補上具體訊號（一次交代好幾個功能、從頭做一個模組或系統、設計文件列了好幾個模組或頁面）。
  review 抓到的缺口一併補上：N 照功能數算（同一個功能的資料、API、畫面算一段），高風險工作不跟別的功能算同一段；
  根目錄 CLAUDE.md 已經有「進度以…為準」時照表接手、不再叫，N 只算表上沒有的新工作（不然換 session 接手可能又叫一次）；
  task-planner 只切出 1 段就停，說一圈做得完、不用拆。§4.4 沒有 task 工具時的進度表格式，改成直接指向
  `~/.claude/skills/task-planner/SKILL.md` 的「進度表格式」一節 —— 一段做得完的工作不會叫 skill，原本無從得知格式。
  裝好後用 `claude -p` 開全新的 session 實測，prompt 存在 jsonl 旁邊。這種 session 沒有寫檔工具、也叫不出
  AskUserQuestion，所以只測到「叫不叫、出不出得了草稿」，批准後寫檔、commit 那段沒測到。
  補例外之前：一次交代三個功能、不含關鍵字，第一句就寫出「預估要 3 個功能段落」並叫起 task-planner，照步驟 4
  出了草稿；只改一行字的要求沒有叫。補完之後：同樣三個功能仍叫起 task-planner（這次第一句寫的是「預估 ≥ 2 個功能段落」，
  沒寫確切段數，草稿切出 3 段）；已有進度表、根目錄有指路的專案說「照設計文件繼續做」，沒有叫，引用 §4.1 那句後照表判斷
  下一段是 S1；一個會動到資料、指令、help 的新功能（`tenant search`）寫出「預估：1 個功能段落」，沒有叫。
  兩份 README 同步
- **task-planner 改成功能段落規劃，進度表寫進設計文件**。原本拆的是「2–5 分鐘的微任務」，
  單位跟 8 步迴圈的功能段落對不上，還有三處跟全域規則衝突：每個微任務強制先寫測試（§3.5
  不主動新增測試）、不問人直接寫檔（§4.1 複雜任務先確認）、寫到 `docs/plans/`（跟
  design-brainstorm 的 `docs/designs/` 分成兩個資料夾，一個功能兩份檔）。它唯一實際跑出來的
  計畫檔也被刪掉了。改成兩層：段落（一圈 8 步，驗收寫「步驟 5 要看到什麼」；產生帳款、改帳款
  狀態、金額計算、改權限規則、批次或排程刪除這類高風險工作不跟其他功能混在同一段）與段落內的
  小任務（`S2-1` 編號，實作、驗證、commit，commit 訊息帶編號）；小任務 commit 了不等於段落完成，
  小任務全部做完、SKIP 欠下的 CLAUDE.md 補完，才整段跑步驟 3–8，跑完才標 `DONE`。進度表寫進
  設計文件（沒有設計文件就在 `docs/designs/` 開一份短的），規則區塊照抄進文件，換 session 只讀
  文件也照得做；先列要新增的測試與決策題，使用者批准後才寫檔並 commit；下一段固定照表上順序挑，
  有段落 `BLOCKED` 或冒出新工作都先停下來問。改寫時拿 rental-line 設計文件與 rental-management
  口頭需求各乾跑一次（只讀），抓到二十多處讀法不一或互相矛盾的地方一併改掉。全域模板 §4.4 的
  檔案式追蹤跟著改用這張表（沒有設計文件、就算只有一段也開一份短的；取代下面那條的 `docs/plans/`
  與 🚧 / ✅），design-brainstorm 的交接說明同步。改完再做一次完整乾跑：第二版重跑同樣兩次規劃，
  另外在拋棄式沙盒專案照規則真的做完三段（寫程式、commit、步驟 3–8），中途換一個沒讀 skill、
  只讀專案文件的 agent 接手做完。進度表、commit 編號、範圍、指路刪除逐項用指令核對都對得上，但又抓到
  只讀看不出來的問題：接手規則照字面會跳過還沒做的小任務；gate 在目錄同時有 staged 變更與 SKIP 欠帳時
  只印 staged 的理由，照訊息補會漏（規則改成看 `git diff <起點> -- <目錄>`）；「清單外的測試先問」
  沒進規則區塊；指路不空一行會併進上一段。規劃端的決策題界線、專案要求兩種驗法時怎麼寫、指路連結與
  舊進度宣告的衝突等 17 處一併改掉；review 又補上三件：接手時會對到別份文件的同編號 commit（改看
  表上起點之後的 log）、先補好 CLAUDE.md 就不會被 gate 擋（所以不論擋不擋都看整段 diff）、使用者
  中途要先做別的事沒有規則（比照 `BLOCKED`，回頭做時起點不改）。§4.4 的「沒有這列就先加」限定為
  使用者交代的段落並連同小任務一起補，不再跟「冒出新工作先問」衝突
- **全域模板 §4.4 補上「原生 Task 工具與 TodoWrite 都沒有」時的退化路徑**。原本只寫
  「新版用原生 Task 工具、舊版用 TodoWrite」,假設 harness 一定會提供其中一個 ——
  實際遇過兩組都不提供的 build(`ToolSearch` 找不到,關鍵字搜尋只回 `TaskOutput` /
  `TaskStop`,那是背景 job 的輸出與中止不是待辦)。沒寫退化路徑的後果是模型直接
  宣稱「沒有 task 工具可用」然後跳過追蹤。補的做法是**檔案式追蹤**:段落寫進設計文件
  或 `docs/plans/` 的段落表,開工標 🚧、收工改 ✅ 並補 commit 清單 —— 它跨 session
  留著也進 git,比工具式耐用,代價是沒人提醒更新,所以強調「開工就先加那一列」。

- **全域模板 §6.2 補上除錯的第一個分支：「跑的是不是你剛改的那份」**。原本只教
  「先分辨錯的是被測物還是測試本身」，漏掉熱重載（`node --watch`、nodemon、HMR、
  掛載進容器的 volume）還沒跟上這種情況 —— 錯誤訊息看起來完全合理，會讓人開始改
  沒問題的碼。判準是**錯誤訊息的行號對不對得上現在的檔案**。
- **全域模板 §2.6 第 1 點的觸發條件補上「含回傳形狀」**。原本寫「改既有函式/設定/
  介面前先 Grep 呼叫端」，但「回傳從陣列改成物件」不長得像簽章變更，觸發不了這條規則
  —— 而動態語言漏掉的呼叫點 lint 與單元測試都抓不到，只有跑到那一行才炸。
- **`dd-init` 樣板的 Playwright 段落補上瀏覽器端的判準**。原本只寫「看後端有沒有
  收到請求」，需要另外去翻 log；補上 `performance.getEntriesByType('resource')`
  數請求數，驗「前端擋下來、根本沒送出」時不必離開瀏覽器。

### Added

- **CI 新增「error-capture hook 行為測試」step**：`skills/self-improving-agent/hooks/test-error-capture.sh`
  （純 bash，整套跑兩輪 —— 一輪預設 PATH、一輪把 jq 藏起來逼它走 python3 後備，否則 ubuntu runner
  有 jq，後備那條分支在 CI 上永遠零覆蓋）。這支 hook 的失效是零輸出 exit 0，與「真的沒錯誤」
  外觀相同，shellcheck 完全無感。**它守的是逐行比對的語意，不是 pattern／exclusion 清單的完整性**
  —— 範圍寫在 `hooks/CLAUDE.md`，別當成全面防線
- **CI 新增「tech-diagram-gif 幾何閘門自我測試」step**：跑 `scripts/test-verify-geometry.py`
  （純標準庫，ubuntu runner 自帶 python3）。這支閘門自己會錯，而且全判通過（漏檢）與全判失敗
  （假陽性）外觀上都像正常結果 —— 在此之前它完全沒有 CI，現成可跑卻沒人跑。同批補進
  `DD_PIPELINE_ARCHITECTURE.md` 的 CI 防線表
- **README 新增「大工作怎麼跑」圖**（`diagrams/claude-dd-task-planner*.gif`，中英各一，放在兩份 README
  的 task-planner 段落下面）。那段文字有分岔（估出 1 段照一般迴圈、2 段以上交給 task-planner）、
  有繞回來的圈（每一段裡小任務一個個做，整段才跑 3–8，標 DONE 再做下一段），還有換 session 照表接手；
  原本兩張圖只順帶提一句。來源是新的產生器 `diagrams/src/gen_planner.py`，照 `verify-geometry.py` 畫：
  兩版幾何檢查 0 項不過（舊兩張各有 8/31 留下的未通過項），渲染後量到節點文字離框邊最少 15px，
  GIF 循環接點與相鄰幀的 PSNR 只差 0.04／0.03dB，四邊都是底色。為了過檢查的三個做法寫進
  `diagrams/src/CLAUDE.md`：節點文字的字級只寫在 `font-size` 屬性、CSS 不設（檢查腳本讀屬性，沒寫就依 class
  猜，猜得比實際大）、九個節點都放進容器、邊標籤底下墊 `data-role="mask"` 的底色塊。review 抓到「怎麼估段落數」
  把高風險講寬了：英文版寫成 billing or permission work，連 SKILL 說要跟功能放一起的「沿用既有的權限檢查」
  都包了進去，已照 §4.1 改成「產生帳款、改權限規則這類高風險工作」
- **`skill-creator` 納入 `OFFICIAL_PLUGINS`**（Anthropic 官方 plugin，走 `/plugin`
  路線，不 vendor 進本 repo）：補上「怎麼跑一輪 skill 開發」— 訪談 → 草稿 →
  同一批測試題跑「有 skill / 無 skill」兩組對照 → 評分 → 迭代，與既有
  `writing-great-skills`（純寫作觀念參考）互補而非重疊。
  連帶修 `install_plugins()` 三處：①`plugin.json` 缺 `version` 欄位時（skill-creator
  即如此）改讀 `installed_plugins.json` 裡 Claude Code 記的值（缺 version 時它填內容
  雜湊）②兩處讀取都加**型別護欄，只接受 JSON 字串** — 沒有它時 `"version": null` 在
  jq 印 `null`（被守衛擋下）、在 python3 印 `None`（**繞過守衛**，寫出
  `installPath=.../None` 這種指向不存在目錄的紀錄），兩路徑不等價 ③跳過訊息改為只陳述
  「兩個檔都取不到版本字串」並附上該跑的 `claude plugin install` 指令，不再宣稱成因 —
  走到那裡的情況有四種（未安裝過／檔案損毀／entry 是空陣列／entry 在但 version 非字串），
  腳本分辨不出時就不講死。**不自行編版本號** — `installPath` 用它組 cache 路徑，
  編錯會指向不存在的目錄。等價性以 26 個邊界案例實測（plugin.json 10 例 +
  installed_plugins.json 16 例），jq 與 python3 兩路徑 0 分歧

- **`tech-diagram-gif` 收編 diagram-design 的四項規則**（借鏡自
  [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design)，MIT，
  概念改寫未 vendor 任何檔案，歸屬記在該 skill 的 `LICENSE.txt`）：硬閘門新增
  「先判斷該不該畫」、元素數量預算（節點 ≤9 / 連線 ≤12 / 強調色 ≤2 / 分組 ≤4 / 註解框 ≤2）、
  連線可量測規則（標籤間隙 ≥6px、port ≥12px、遮罩 z-order、不穿越非端點節點）、
  「產出前檢查清單（Taste Gate）」20 項。檢查清單**依判定時機與手段分五組**（第 1 步數清單 /
  第 4 步算座標 / 第 4 步看截圖 / 第 5、6 步交付），避免出現「該項要到後面步驟才有素材可判」
  或「第 4 步才發現數量超標只能整份重來」。未採用其 python 幾何驗證腳本（不塞 runtime 依賴）、
  HTML 靜態交付（本 skill 只交 GIF）與 39 型 reference（使用率盤點制）
- 同輪順帶定調：節點間距**取嚴為 80px**（`svg-layout-best-practices` 的 Universal
  Layout Rules），contract 表列的 40px 是上游 showcase 不及格線，不再出現在閘門裡
- **`tech-diagram-gif` 新增 `scripts/verify-geometry.py`**（純標準庫、無 pip 依賴、
  缺 python3 退化為人工算）：把 Taste Gate「版面幾何」組從「用眼睛看」變成可執行的閘門，
  第 4 步改為「先跑腳本再看截圖」。同批新增 `test-verify-geometry.py`（每種變異各弄壞
  一項確認抓得到，另有回歸案例確認不誤報；案例數見該檔與 `scripts/CLAUDE.md`，
  本文不寫死數字）與 `scripts/CLAUDE.md`。SVG 需標
  `data-role`（`node`/`container`/`edge`），無標記時腳本退化用畫法猜並印警告
- **修正一項翻譯錯誤**：邊標籤遮罩與連線的間隙原寫「6–10px」（讀成上下限），
  上游 diagram-design 原文是 minimum 6px、擁擠時 push to 8–10px —— **6 是下限不是區間**。
  照誤寫版判定，間隙 12px 的正常圖會被判不合格。已改為 ≥6px 並在 contract 記下原委
- **`diagrams/` 新增 5 張 GIF**，把 `tech-diagram-gif` 能畫的類型（4 種風格 × 2 種
  動畫模式）各出一張：Style 8 / Style 2 的傳播路徑圖、Style 11 事件流地鐵圖、
  Style 12 事故排查、以及建置→營運五幕敘事動畫。Style 11 / 12 需要 Kafka 拓撲與
  監控數據，claude-dd 沒有，用示範情境並在圖上標明非實況。
  手寫 SVG 來源進 `diagrams/src/`（與腳本產生的 SVG 不同，那是產物、這是來源），
  `diagrams/src/CLAUDE.md` 補上兩類來源的區分
- **vendor intake 清單補「只借概念、不抄檔案」的歸屬規則**：歸屬要精確到段落／項目，
  不可整節掛名。判準是「能逐條指出哪一段來自誰」。同輪把該 skill 的量化數字從三份手抄
  （第 1 步、第 3 步、Taste Gate）收成一份 —— contract 是唯一來源，SKILL.md 只留
  Taste Gate 這份操作用的逐項版本，其餘改為指路

- **CI 迴圈步數第五方檢查**：既有的四方一致只數**編號清單**，使用者實際看到的兩類
  文案不在範圍 — 安裝腳本印出的「N 步開發迴圈」，以及散落各處的一行式箭頭摘要。
  第五方補上這兩類：箭頭摘要先合併續行，箭頭 ≥3 且同時含 `commit` 與 `review`
  才認定為迴圈摘要；腳本部分排除註解行（那裡是有日期的歷史敘述），CHANGELOG 與
  UPGRADING 同理排除。上線當下就抓到人工逐檔翻仍漏掉的一處

### Fixed

- **`error-capture.sh` 的 exclusion 一票否決，真實的建置失敗被整段吞掉**：舊版拿整份輸出比對
  exclusion，輸出裡任何一處出現 `console.error` 或 `no error`，同一份輸出裡真正的失敗全部不報 ——
  而且是零輸出 exit 0，與「這次真的沒錯誤」外觀完全相同。兩個必踩的真實樣態：TS build 失敗夾帶
  原始碼片段（`console.error`），以及多服務輸出裡 `compiled with no errors` 與 `Build failed` 並存
  （`no error` 是 `no errors` 的子字串）。改成**逐行**比對：exclusion 只否決它所在的那一行。
  同批修正三份文件「成功時零開銷」的說法 —— hook 拿不到 exit code，它做的是文字比對，
  成功但印了 `failed` 的指令一樣會觸發
- **`verify-geometry.py` 從不讀 SVG 自己 `<style>` 宣告的字級**，一律查內建預設表，兩個方向都會錯：
  猜高了誤報（`gen_loop.py` 的 `.nm` 實際 15px 被當成 20px，英文版一次誤報 17 處文字溢出），
  猜低了**靜默漏檢**（只在 `<style>` 把字級放大的圖，文字爆框卻判通過、exit 0）。改成照瀏覽器的
  優先序取值（`<style>` 的 class 規則 > `font-size` 屬性 > 內建表 —— 依 SVG 1.1 §6.4，
  presentation attribute 的特異性為 0，所以 CSS 勝出），只認 px 字面值，同一區塊重複宣告取最後一個，
  並先剝掉 CSS 註解（否則「把舊值註解留在下面」這個常見習慣會讓註解裡的舊字級蓋掉真正生效的規則）。
  實測溢出誤報：`loop-zh-TW` 1→0、`loop-en` 17→2、`usage-en` 10→1
- **`/dd-init` Phase 3 的 gate 掛載有兩個靜默失效路徑**：①三條分支裡只有一條做 `chmod +x`，
  既有 hook 沒有執行位元時 gate 等於沒裝，git 只印一行 `hook was ignored` 的 hint 就過去了；
  ②既有 hook 以 `exit 0` 或 `exec` 結尾時，追加在檔尾的呼叫是死碼，而下一條分支的「已含」是純
  字串比對 —— 字串就在檔案裡，於是每次跑 `/dd-init` 都回報「已裝」，永遠不會修好
- **`--uninstall` 的移除預告漏列輔助腳本**（含 pre-commit gate，移除後各專案掛著的 hook 會失效），
  且 plugin 那行寫死一個名字、實際會取消登記兩個。改由 `OFFICIAL_PLUGINS` 陣列生成；完成訊息同病同治
- **`UPGRADING.md` 的「保留本地客製」做不到**：原本寫「最後一步改成不帶 `--force` 才會出 diff 選單
  讓你選 `k`」，但前面那個指令的 `--force` 已經先把全域 CLAUDE.md 覆蓋掉，等跑到最後一步兩邊內容
  一致、腳本直接 return，那個選單**永遠不會出現**（實跑驗證）。改成兩個指令都要拿掉 `--force`，
  並警告別選 `s`（舊腳本那個分支的裸 `diff` 在 `set -e` 下會中止安裝）。同節補上 `--prune` 掃不到
  `templates/`，要自己 `rm -rf ~/.claude/templates/dd`，以及「會印 7 行紅字『源檔案不存在』屬預期」
- **`/dd-init` 在沒有 `.gitignore` 的專案不會把 CLAUDE.md 送進版控**：Phase 5 原本寫
  `git add CLAUDE.md .gitignore 2>/dev/null || true`。`git add` 是全有全無，純後端/CLI 專案
  沒有 `.gitignore`（Phase 2 只在有前端 UI 時才建），整條以 exit 128 失敗、**staged 清單為空**，
  接著 `git commit` 也失敗，但 Phase 6 照樣印「✅ 初始化完成」—— 蓋章好的 CLAUDE.md 就留在 untracked。
  改成兩條獨立的 `git add`，並讓 `git commit` 與 guard 都帶 pathspec（`-- CLAUDE.md …`）：
  不帶 pathspec 的話提交的是整個 index，使用者做到一半、早就 staged 的程式碼會被一起掛進
  「初始化」這個 commit 而毫無提示（實測重現過）。帶了之後 hook 拿到的是臨時 index、只看得到這幾個檔，
  連誤擋都不會發生。同時把 `[ -f .gitignore ] && git add …` 改成 `if … fi`（前者在檔案不存在時整行回
  exit 1，agent 把區塊拆成一行一行跑時會看成失敗）。四種情境實測：無 .gitignore、有 .gitignore、
  零 staged、使用者另有無關的 staged 變更 —— CLAUDE.md 都進版控，使用者的檔案原封不動留在 index。
  第 158 行原本保證「此 commit 只動 CLAUDE.md/.gitignore，會通過 gate」也一併更正：gate 看的是整個 index
- **安裝腳本的「s) 顯示完整 diff 後再決定」選了會直接中止安裝**：全域 CLAUDE.md 互動選單（情境 4）的
  `s` 分支裡 `diff "$target" "$source"` 單獨成行，內容不同時回 exit 1，配上檔頭的 `set -e` 直接結束整個
  安裝行程，講好的「看完後要覆蓋嗎」永遠問不到，而且中止點之後的安裝步驟全部沒跑。補 `|| true`。
  同一函式上面的 `diff … | head -30` 反而沒事 —— 管線取的是 `head` 的結束狀態。
  `bash -n` 與 `shellcheck -S warning` 對修正前的版本都是全過的，這類錯只能靠帶 `set -e` 的隔離重現抓到；
  根目錄 CLAUDE.md 補上通則（`diff`／`grep`／`cmp` 回非 0 是正常結果，一律 `|| true` 或放進管線，
  後者以腳本沒開 `set -o pipefail` 為前提）
- **`self-improving-agent` 五個 sub-skill 算出的記憶體目錄一律不存在**：`extract`／`promote`／
  `remember`／`review`／`status` 都用 `sed 's|/|%2F|g; …'` 把 cwd 編成 `%2F` 形式，而 Claude Code 實際是
  **把解析後絕對路徑裡每一個非英數字元各換成一個 `-`**（`/`、`_`、`.`、空白、中文都算）。後果全部靜默且
  回報成功：`remember` 印「✅ Saved to auto-memory」但寫到不存在的路徑、`status` 讀到 0 個檔判為 healthy、
  `review` 判定「auto-memory may be disabled」。改用 `pwd -P | sed 's/[^a-zA-Z0-9]/-/g'`（`-P` 是因為
  Claude Code 記的是實體路徑，macOS 的 `/tmp` 就是 symlink）。中途採用過只換 `/` 與 `_` 的版本，被
  code-review 以 CLI bundle 內的 `replace(/[^a-zA-Z0-9]/g,"-")` 與真實 session 建出的目錄推翻；
  修正版拿 Claude Code 自己建的三個目錄對照全中，含 `測試 目錄/v1.2_x` → `-------v1-2-x` 這種。
  五處都補上驗證與 glob fallback：`LC_ALL=C`／`POSIX` 下 sed 會逐 byte 而非逐字元，非 ASCII 路徑會多出
  一堆 `-`，而這個 repo 是可攜設定庫，Linux 上踩得到。原本 `review` 唯一那條 fallback 也是壞的
  （拿未編碼的 basename 去比對已編碼的目錄名，`*my_project*` 無匹配）
- **gate 放行了「用 SKIP 跳過、之後也沒補」的 CLAUDE.md**：gate 原本只看「這一次 commit」
  staged 的檔案，檢查點 commit 用 `SKIP_DOC_CHECK=1` 跳過的目錄，只要最終 commit 沒再碰
  那些目錄的程式碼就不會被查。rental-line 段落 1 實際發生：第一個 commit 用 SKIP 建了
  `backend/src` 等 4 個沒有 CLAUDE.md 的程式碼目錄，最後一個 commit 沒動程式碼，gate 直接
  放行（約一小時後才手動補上）。用 gate 同一套規則重算 rental-line 的 commit，13 段裡有 8 段
  有 commit 是跳過檢查才進得去。修法：新增**段落起點**（`git rev-parse --git-path dd-segment-base`，
  worktree 各自一份）—— `--start-segment` 在段落開始前記下，忘了記時第一個 SKIP commit 自動記；
  之後每個正常 commit 沿著 commit 的祖先關係結算起點以來的欠帳（改程式碼記帳，要由看得到那段
  程式碼的後代 commit 更新該目錄 CLAUDE.md 才銷帳，merge commit 自己補的也算），所以起點再舊
  也不會變寬鬆，平行分支上的 CLAUDE.md 更新也抵不掉。起點被 amend／rebase 改寫時改從共同祖先算；
  目錄在 index 裡已經沒有程式碼就不再追討；還有欠帳時 `--start-segment` 拒絕重記；
  `--segment-base` 印出起點給迴圈步驟 3、4、8 算範圍，起點失效就失敗。整段一次掃完，
  起點到 HEAD 有 1000 個 commit 時約 0.08 秒。CI 新增 61 個情境檢查（含還沒有 HEAD 的第一個
  commit、舊起點、起點被改寫、merge、程式碼刪掉或搬走、只在工作目錄刪掉、根目錄與含空白的目錄名）
- **非 ASCII 路徑完全不檢查**（原始版本就有）：git 預設把中文路徑加引號跳脫（`"功能/\345…"`），
  結尾變成引號，副檔名永遠比對不到 —— staged `功能/a.js` 又沒有 CLAUDE.md，原始版本 exit 0 放行。
  列檔案的 git 指令改用 `core.quotePath=false`
- **迴圈步驟 3、4、8 只看最後一個 commit**：simplifier 包裝器預設 `git diff HEAD~1`、
  步驟 8 算範圍用 `git show HEAD`、本地 code-reviewer agent 不給範圍時只看還沒 staged 的改動，
  但一段常有好幾個 commit。rental-line 13 段裡有 11 段只看最後一個 commit 會漏掉 CLAUDE.md
  （全部 96 份只看得到 31 份；段落 1 算出來是空的，第一個 commit 建的 5 份都不在範圍內。
  該專案 2026-09-09 已在自己的 CLAUDE.md 改用 `<base>..HEAD`，這次回寫）。全域模板 §3.9、
  `/dd-init` 蓋章版、code-simplifier 包裝器改成段落開始前跑 `--start-segment`、範圍用
  `--segment-base` 算；蓋章版加 `dd-loop-rev`（目前是 `4`），標記是 `8step` 但 rev 比現行值舊
  （沒有 rev 標記或號碼更早）的專案跑 `/dd-init` 會提議升級。UPGRADING 補上這個升級步驟，
  並更正「`/dd-init` 會跳過既有區塊」的過期說法。
  連帶補上：步驟 4 依序跑時另附 `git ls-files --others --exclude-standard`（簡化新增、還沒 commit
  的檔案 `git diff` 看不到）；蓋章版補上並行時的範圍寫法；步驟 8 指令加 `core.quotePath=false`，
  抓未 commit 的用 `git diff --name-only HEAD` 加 `git ls-files --others --exclude-standard`
  （中文目錄、未追蹤新目錄裡的 CLAUDE.md 原本都會漏；**不要用 `status --porcelain -uall | awk '{print $NF}'`**，
  含空白的路徑 git 會加引號，`$NF` 從空白切開後比對不到，少列一份卻照樣 exit 0）；CI 檢查 dd-init 裡的
  dd-loop-rev 前後一致
- **`--check` 把停用中的 plugin 回報成「已啟用」**：`check_plugins()` 原本用
  `grep -q "\"$plugin_key\""` 判斷 settings.json，但 `enabledPlugins` 是
  `{key: bool}`，**停用是「鍵在、值為 false」**，grep 只看得到鍵在。實測本機
  `ralph-wiggum` 值為 `false` 卻被報成「✅ 已啟用」。新增 `plugin_enabled_state()`
  比照 `mcp_scope()` 的分級：`enabled` / `disabled` / `none` / `unparseable`
  （檔案損毀，無從判定）/ `unknown`（缺 jq 與 python3，只有字串證據、分不出
  true 與 false）。jq 與 python3 兩路徑以 15 例邊界測試驗過 0 分歧
- 六張 GIF 的循環接點會跳：球的 `begin` 是 `dur` 的整數倍時，「跑完一圈跳回起點」
  剛好落在 GIF 循環接點上。另外 `dev-loop` 的框間連線只有 20px，而球含光暈直徑 16px，
  停在終點時整個箭頭被蓋住 — 那 5 條短連線改為只留箭頭
- **8 步迴圈的文案殘留 9 處**：2026-08-31 迴圈擴充到 8 步時三類文字沒跟上 —
  安裝腳本印給使用者的訊息仍寫「6 步」（2 處）、標題宣稱 8 步但箭頭只列到第 6 步
  （6 處，含 `DD_PIPELINE_ARCHITECTURE.md` 停在 7 段）、`README.zh-TW.md` 把安裝腳本
  **自身進度**的 7 步誤寫為 8 步而括號內仍是 `1/7 … 7/7`（英文版同段本就正確）。
  本檔與 UPGRADING 的歷史敘述、`/dd-init` 的 `6step`／`7step` 版本標記均不動 —
  後者是舊專案升級偵測的判斷依據

### Removed

- **移除三層架構圖**（`claude-dd-architecture*.gif` 與 `gen_arch.py`）：它畫的是目錄
  清單而不是架構，13 個框寫的都是 `DD_PIPELINE_ARCHITECTURE.md` 已有的文字，
  卻多一份圖要隨每次改動重畫。README 保留 `usage-flow` 與 `dev-loop` 兩張

## 1.1.0 — 2026-08-31

### Changed

- **開發迴圈由 6 步改為 8 步**（同日兩階段擴充）：
  - **步驟 7「沉澱本輪所學」**（`claude-md-management:revise-claude-md`）— 本輪學到的
    踩雷／指令／慣例寫進 CLAUDE.md，會先列建議等使用者同意才寫檔；沒學到就跳過
  - **步驟 8「評分 & 修正本輪動過的 CLAUDE.md」**（`claude-md-improver`）— 補 pre-commit
    gate 的盲點：gate 只確認改碼目錄的 CLAUDE.md「有寫」、**不確認「寫得對」**。
    **第一個動作是算範圍**（`git show HEAD` 聯集 `git status`），因為該 skill 的 Phase 1
    是「find 全部」，實測有專案含 87 份 CLAUDE.md，不先算範圍會全 repo 掃。
    **步驟 7 跳過不代表步驟 8 跳過** — gate 逼出來的那些改動一樣要審
  - 步驟 1–6 編號與內容不變。先在 claude-dd dogfood 4 次抓到 2 個真錯誤才推全域。
    已用舊版 `/dd-init` 蓋章過的專案不會自動更新，重跑 `/dd-init` 會偵測舊版並提議升級
- 全域模板收緊回應風格與 task 粒度；巢狀 CLAUDE.md 的代價改寫為
  「代價 → 對策 → 殘餘風險」三段式
- 全域模板 §3.4 砍掉 `/goal` 的操作手冊（官方文件轉述，非行為規則），留一行指路
- `claude-mem` 由必要 MCP 改列「推薦第三方 Plugin」— 它走 hooks + plugin 系統，
  MCP 檢查對它永遠誤報未安裝

### Added

- 全域模板 **§2.6 動手前範圍盤點與佐證要求**：改既有介面前先 Grep 呼叫端並列出受影響
  檔案；病因要有第一手證據；結果只報實際跑過的
- 全域模板 **§4.1 停等語規則**：使用者說「先告訴我」「不要直接改」時，該輪只出計畫
- 全域模板 **§2.5 擴充**：skill / agent / 工具的 description 也算「名稱層級」資訊，
  要拿它的行為下判斷前先讀 SKILL.md 本體
- 全域模板 §7.2 觸發表新增 `revise-claude-md`（關鍵字刻意避開 improver 與
  self-improving-agent，避免撞列）
- **第三張圖表「8 步開發迴圈」**（`claude-dd-dev-loop*.gif`，中英各一）並嵌進兩份
  README — 先前兩張圖只把迴圈壓成一個框裡的一行字
- **`diagrams/src/` 納入版控** — 6 張 GIF 的產生器（零依賴 Python 手寫 SVG）與重出流程。
  先前只保存成品 GIF，改一個字就得整張重畫
- `tech-diagram-gif` 陷阱表補上 playwright 的工具層與瀏覽器層差異：`browser_navigate`
  擋 `file://` 但 `run_code` 裡的 `page.goto('file://…')` 不受限、`run_code` 裡拿不到 `fs`、
  `page.screenshot({path})` 可寫任意路徑
- **CI 新增兩道防線**：安裝 flag 三方對照（腳本 case 分支 ↔ `--help` ↔ 兩份 README）、
  迴圈步數四方一致（全域模板 §3.9 ↔ `/dd-init` 蓋章版 ↔ 兩份 README ↔ `dd-loop-version` 標記）

### Fixed

- **`/dd-init` 的版本標記停在 `6step`** — 判斷邏輯是「含 `6step` → 已是現行版」，
  導致已蓋章的專案永遠不會被提議升級。**靜默失效、不報錯**
- 兩份 README 的迴圈清單只列到第 7 步，與「8 步」標題自相矛盾
- `/dd-init` 蓋章版與兩份 README 原本把 `/revise-claude-md` 當成巢狀文件同步的工具，
  與其實際行為（回顧本 session 學到什麼）不符 — 已拆成兩件事分別說明
- `diagrams/src/gen_usage.py` 只產 `.svg` 不產 `.html`，與該目錄 CLAUDE.md 寫的
  「6 份 .svg 與 .html」不符，照文件做會在重出流程第 2 步斷掉
- README 與 CLAUDE.md 事實查核：13 處與實作對齊的修正

### Removed

- 可選 MCP 移除 `cipher` — 上游已 deprecated 改名 byterover-cli，本機使用紀錄已斷

## 1.0.0 — 2026-08-11

首次對外發布。版本號自本版起生效，`install-dd-pipeline.sh` 的 CLI flags 與
`~/.claude/` 佈局視為穩定介面，日後破壞性變更走 2.0.0。

### Added

- 雙語 README：`README.md`（英文，GitHub 預設顯示）與 `README.zh-TW.md`（繁體中文），
  兩份頂部各有一行語言切換列。英文版含 language note，說明規則本文仍是繁中
- 專案架構圖與使用流程圖（`diagrams/*.gif`，Style 8 Dark Luxury、8 秒循環、20fps），
  由 tech-diagram-gif skill 產出並納入版控，兩份 README 皆嵌入。雙語出圖：
  英文用原檔名（與 README 同一套慣例），繁中版加 `.zh-TW` 後綴
- 可選 MCP 新增 `context7` — 取版本正確的官方文件，支撐全域 CLAUDE.md §2.5
  「禁止從名稱推論 API」
- CHANGELOG 改採 semver，回溯補上 v0.2.0–v1.0.0 的 git tag

### Changed

- MCP 檢查改為真正解析 JSON 判斷 scope（jq → python3 → 退化標示），區分官方
  `user` 與 `local`；`~/.claude.json` 同時存放所有專案的設定，字串 grep 會把
  別的專案的設定誤判為已安裝
- 對外整備：清除客戶代號、升級指南與變更紀錄自 README 拆出為 UPGRADING.md / CHANGELOG.md
- CI 數字宣稱檢查改語言無關正規式，並同時驗兩份 README

### Removed

- `templates/*.template` 7 個文件模板（REQUIREMENTS / ARCHITECTURE / API_CONTRACT /
  EXAMPLES / ADR / PROJECT_STATE / CLAUDE.md）— 舊多階段流程的產出物，其消費者
  （`/dd-start` 等）已於 0.4.0 刪除，現行 `/dd-init` 直接生成內容，全 repo 無讀取路徑
  - 安裝步驟由 8 步減為 7 步，不再部署 `~/.claude/templates/dd/`
  - **既有安裝的 `~/.claude/templates/dd/` 不會被自動刪除**，需要時手動 `rm -rf` 或跑 `--uninstall`
  - 取回：`git checkout pre-prune-2026-08-04 -- templates/`

### Fixed

- MCP 檢查的假陽性；`~/.claude.json` 損毀時回報「無法判定」而非誤報未安裝；
  jq 與 python3 兩條路徑的型別護欄對齊，同一台機器裝不裝 jq 得到相同結論
- 文件死連結與 tag 目標錯誤

## 0.5.0 — 2026-08-10

### Added

- 自製 skill `tech-diagram-gif`：技術圖表繪製與 GIF 匯出（流程圖 / 架構圖 / 走向動畫），
  風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)（MIT）
- 安裝腳本環境檢查加入 `ffmpeg` 可選項偵測：缺少時該 skill 退化交付 SVG，不中止安裝

### Changed

- Promoted skills 由 9 個增為 10 個

## 0.4.0 — 2026-08-04

單桶化：repo 改為單一部署清單，只保留有實證使用紀錄的元件並全數預設部署。
被刪內容可自 tag `pre-prune-2026-08-04` 取回（該 tag 落在本版範圍內），見 UPGRADING.md。

### Removed

- deprecated 桶：全歷史 0 次使用的 34 skills / 17 agents / 6 dd 指令 / 13 NS commands
- misc 桶：SRE 備援性質但零實際調用的 11 skills / 5 NS commands
- 安裝腳本的 `--prune`（單一清單後無桶可清）
- plugin marketplace 分發路線（`.claude-plugin/marketplace.json`）— 同批評估、實測可行後
  仍移除：plugin 機制無法部署全域 CLAUDE.md 與 pre-commit gate，只能交付元件子集，
  與「完整工作法」的定位不符，為維持單一安裝路線而不採用

### Changed

- 被刪的 6 個 dd 指令為舊版多階段流程的 `/dd-start`、`/dd-arch`、`/dd-approve`、
  `/dd-dev`、`/dd-test`，加上已停用的 `/dd-dx`；`/dd-init` 保留並改造

## 0.3.0 — 2026-07-31

### Changed

- 全域模板依 Claude 5 家族遷移指引調整：規則內容不變，僅語氣平述化
  （§3.1、§3.9、§7 開頭、§7.2 標題、§7.5），原 §7.6 的藉口逐條表濃縮為單一原則句

## 0.2.0 — 2026-07-23

### Changed

- 骨幹改為 6 步開發迴圈：原多階段 DD Pipeline（`dd-start` → `dd-arch` → `dd-approve`
  → `dd-dev` → `dd-test`）依實際使用率盤點後封存，改為經實際專案實戰驗證的功能段落迴圈
- `/dd-init` 改造：從產出設計文件骨架，改為蓋章開發迴圈到專案 CLAUDE.md
- 全域模板 §7.2 Skill 觸發表由 21 列瘦身至 8 列，只留預設部署元件對應項

### Removed

- §7.2 被移除列的目標已不再預設部署：senior-qa、test-engineer、tdd-guide、test-gen、
  senior-frontend、ui-design-system、ux-researcher-designer、landing-page-generator、
  senior-backend、dx-engineer、senior-fullstack、senior-secops、playwright-pro
