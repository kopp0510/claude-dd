# S9-a 審查報告

## 派工

subagent_type: code-reviewer（opus，不帶 model），方向：全面（意思、限定語、證據標記、A 類理由）。2026-10-25 15:11 與另兩個同一則訊息平行派出；讀 2530 行的 diff 檔 `s9-final/S9-review-diff.txt`（scratchpad）。用時 10 分 24 秒、25 次工具。派工 prompt 全文：

> 你是 claude-dd repo（/Users/danlio/project/my_project/claude-dd）S9 段落、8 步迴圈步驟 4 的審查者。你的職責：找漏洞，每條附證據（檔案:行號＋原文，或指令＋輸出），沒證據的不算。
>
> 這段做了什麼（事實）：
> - 精煉全域規則模板 templates/global/CLAUDE.md。它會部署成 ~/.claude/CLAUDE.md，每個 Claude Code session 都會讀進來。61,706 → 55,281 bytes。
> - 使用者的要求：意思不能變；並逐條判「這條規則還需不需要」，拿掉沒影響才刪。作者把可刪的分成「有把握（A 類 19 處）」與「沒驗證（B 類）」，使用者選「只刪 A」。另外套用了計畫附錄 A 的改寫（刪日期、故事細節，修引用；計畫審查通過過）。A 類是計畫審查之後才加的，沒有被審過，所以這一步要特別查它。
> - 起點 316117c，4 個 commit：d75ebbb（§3.9）、58684bd（§3.10）、b0b4889（§2.6、§3.4、§4.1、§4.4、§6.7、§7.2、§7.5 與 CHANGELOG）、4069ec5（README 兩份、scripts/CLAUDE.md、設計文件的巡查結果）；工作目錄另有設計文件一處措辭修正（A13 那列）。
> - 這段只有文件、沒有程式碼；步驟 3（code-simplifier）跳過。
>
> 你是審查者 a，方向「全面」：
> - 新版模板跟 base 比，規則、條件、例外、限定語、證據強度標記（實測、實證、曾、實際）有沒有變弱、變強或不見。
> - A 類每一處（審查檔 ⑤-2 是作者的理由，作者宣稱、要逐條查證）：拿掉之後，照新版做事的 agent 會不會做出不同的行為？「別處已經講了」「gate 會自己印」「agent 定義有寫」這類理由，去那個地方讀原文確認真的講了同一件事（gate 是 scripts/check-claude-md.sh，agent 定義是 agents/code-reviewer.md）。
> - 計畫附錄 A 的改寫（刪日期、故事、修引用）有沒有改到意思。
> - 模板內部被改動附近的指代（上一條、上面、「…」那條、§x.y）在新版還指得到嗎。
> 不在你的範圍：README、scripts/CLAUDE.md、repo 其他檔的引用（審查者 b 負責）。
>
> 審查檔：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/s9-final/S9-review-diff.txt（2530 行）。用 Read 的 offset/limit 每次 200 行，從第 1 行讀到最後一行「===== diff 檔結束 =====」（這份檔有些行很長；Read 一次讀太多會靜靜截斷、不報錯）。
>
> 規則：
> - 被改到的檔，一律讀審查檔裡那一份；沒被改到的檔照常讀 repo（唯讀）。
> - 已跑過的驗證輸出在審查檔的 ④（連同預期值）：這些已確認，不要重跑。
> - 只用手上的資料判斷；需要外部查證的（上網、跑安裝、開容器、派別的 agent、跑 claude -p）列出來交回，不要自己去做。
> - 唯讀：不改任何檔、不 commit、不在 repo 裡建檔。
> - 每條發現標嚴重度：Critical（照新版做事會做錯、而且不會被任何檢查擋下）、Important（意思變了或引用錯了，但影響有限）、Smell（措辭、格式）。
>
> 交回格式（照抄標題）：
> 【發現】每條：嚴重度｜位置（新版行號，或 檔:行）｜問題｜證據｜建議改法
> 【Not reported】看過、判定不是問題的（每條一句理由）
> 【What I ran】跑過的指令與讀過的範圍（審查檔讀到第幾行）

## 發現（逐字原文）

【發現】

1. Important｜新版 §3.9 第 284 行（「不設審查者的工具次數上限」）。對應 A07｜A07 刪掉的不只是量測數字，還有一條給主對話的指示，而 agent 定義只補回一半。這樣 CHANGELOG 說的「規則本身都留著」，對這條就不成立。
   - 證據：
     - base:306–307 原文是「把次數撐大的是開放式問題…所以 prompt 寫明『只用手上的資料判斷,需要外部查證的列出來交回』」。在新版模板 grep「只用手上」，0 筆。
     - agents/code-reviewer.md 的 Scope Discipline 只管範圍外的證據：「A finding that needs evidence from outside your scope: list what you would check and hand it back… Do not go fetch it」。
     - 同一份定義的 Work Order 第 4 點反而叫審查者自己做實驗：「For what reading cannot settle, build one script covering every remaining hypothesis at once and run it in a throwaway directory」。
     - 所以「只用手上的資料判斷」那一半（範圍內也不另做實驗）沒有任何地方再講。
     - 「開放式問題會把工具次數撐大」這條寫 prompt 的提醒也一起刪了。
     - 剩下的第 284 行少了原本搭配的約束，讀起來變成「放它跑」。這一行也是 §3.9 步驟 4 子項裡唯一沒有粗體標題的。
     - CHANGELOG 未發布區塊第 24 行寫「量測明細與設計理由…規則本身都留著」。
   - 影響：照新版做的主對話不會再把這句寫進派工 prompt。審查者可能回到 base:305–306 記的 21/26 次工具、13–17 分鐘那種跑法。這是多花時間，不是做錯。
   - 建議改法：第 284 行改成「派工 prompt 寫明『只用手上的資料判斷,需要外部查證的列出來交回』;不設審查者的工具次數上限(砍上限會連查證一起砍)」。

2. Important｜新版 §3.9 第 239、263、268、380 行，另外第 261、345 行連實例一起刪｜這幾處把整句實證刪掉，「實測／實證」標記也跟著沒了，宣稱變成沒有依據的斷言。計畫附錄 A 准刪的是「日期與故事細節」，沒有准把證據強度標記拿掉。
   - 證據（diff ①）：
     - 第 239 行：「只看最後一個 commit 會漏。」，base:246–247 有「實測某專案段落 1…5 份 CLAUDE.md 都不在範圍內」。
     - 第 263 行（⚠️⚠️ 規則）：「reviewer 會跟著錯。」，base:276 有「(實證:兩個都接受了錯的框架,只有第三方去查才發現)」。
     - 第 268 行：「『跑過』不代表結果對。」，base:283 有「(實測一次:標成已確認的輸出正是 bug 算出來的值…)」。
     - 第 380 行（⚠️⚠️ 規則）：「測到的是假綠。」，base:414 有「(實測:情境全過,而真實 rebase 下那段從未執行)」。
     - 第 261、345 行：實例連「實測」一起刪了（base:273–274、378）。
     - 對照組：§3.10 只刪日期、留下「實測」（新版 383、441、476、506 行）。同一個 commit 系列裡兩節的處理方式不一致。
   - 為什麼現有檢查抓不到：④ 的 check 6 比的是作者自己訂的預期行數，不能獨立證明這些刪除沒問題。
   - 影響：照規則做事的行為不變，所以影響有限。但下一個人會把這兩條 ⚠️⚠️ 當成推論而不是實測過的事實。模板 §1.2（新版 51–52 行）也寫了來源標註「不可為了精簡而砍」。
   - 建議改法：不恢復故事，只在原位補一個 `(實測)` 或 `(實證)`，例如第 380 行寫「測到的是假綠(實測)」。

3. Important｜新版 §3.9 第 301–309 行。對應 A08｜A08 連帶刪掉了「報告檔的命名慣例:見專案自己的 `docs/reviews/CLAUDE.md`」（base:340）。這是給各專案使用者的指標，不是給維護者的。A08 的理由寫「其餘是給維護者的」，不涵蓋這一句。
   - 證據：
     - repo 的 docs/reviews/CLAUDE.md 規定了模板沒寫的東西：「之後每張表開一個 `<進度表檔名去掉 -design.md>/` 子目錄」「沒有進度表的段落…開 `<日期>-<主題>/`」，以及「前兩節(派工 / 發現)寫完就不改」。
     - 新版模板只剩「多張進度表時放子目錄」與「寫之前先 `ls`」。
     - gate 擋下時的提示（scripts/check-claude-md.sh `--start-segment` 那段 echo）只寫 `docs/reviews/S<段落>-a.md`，沒有提子目錄，也沒有指向 docs/reviews/CLAUDE.md。
     - 蓋章版也沒有這個指標：在 commands/dd-init.md grep `docs/reviews/CLAUDE`，0 筆。
   - 影響：主對話落地報告時可能用錯子目錄名，或日後去改前兩節。主對話會不會自己讀到 docs/reviews/CLAUDE.md，要看巢狀 CLAUDE.md 在「用 Bash `ls`、用 Write 新建檔」時會不會載入。這點是我的推論，見 Not reported 最後一條的外部查證。
   - 建議改法：在第 302 行後補回一句「報告檔的命名慣例見專案自己的 `docs/reviews/CLAUDE.md`」。

4. Smell｜新版 §3.9 第 268 行（④）。對應 A04｜「已經講過、可刪」這個理由比作者寫的弱。
   - 證據：
     - base:265–267 同一條就引用了 Scope Discipline，作者當時明知 agent 定義有這條，仍要求 prompt「明寫『這些已確認,不要重跑』」。
     - Scope Discipline 的原文是「Verification output the caller pasted in」，現在驗證輸出放在 diff 檔 ④，要審查者自己 Read。檔案內容算不算 pasted in，手上資料證明不了。
     - 新版 ④ 也沒要求把這段標成「已確認」。
   - 建議改法：④ 末尾加「並標明已確認」，約 6 個字。

5. Smell｜新版 §3.10 第 491–492 行 vs 第 502 行｜同一次改動把第 502 行從「上面那條」改成明確的「§3.9『…』那條」，但第 491 行「所以上面那條『diff 動到的每一個識別符…』」一樣是從 §3.10 指進 §3.9，卻沒有跟著改。那一行本身沒動，不過這次把同類的另一處改了，兩處寫法就不一致了。
   - 建議改法：改成「所以 §3.9『diff 動到的每一個識別符各跑一次 `git grep`』那條」。

【Not reported】

- A01、A02、A05、A09、A10、A14、A16、A19：刪的是導覽、出處、沿革、分類註記、目的說明，原句都沒有要做什麼的指示。§3.10 的適用範圍那句留著（新版 428 行）。
- A03：理由成立。
  - create_scripts 與 create_global_claude_md 都在同一個 `COMMANDS_ONLY` 判斷下（install-dd-pipeline.sh:1314–1320）。
  - `--update`（:1287–1293）兩個都不跑。
  - 腳本不同就一律覆蓋（create_scripts 的 cmp 分支）；模板在互動選單預設保留舊版。所以只會出現「舊模板配新 gate」，舊模板裡本來就有舊 gate 的判斷。「新模板配舊 gate」只有手動複製才會發生。
- A06：「最少 3 個」與「一發只會挖到一部分」都留著（新版 274、276 行）。gate 擋下時也印「最少 3 個」。
- A11：§3.10 新版 466–467 行講的是同一件事，而且適用範圍更廣。
- A12：§5.2 新版 649 行「本機 commit 不用問」涵蓋。
- A13：理由成立。gate 擋下時印的內容我已讀過（scripts/check-claude-md.sh 末段的 echo）：
  - 「不要問使用者、不要建空殼。讀取該目錄全部檔案後…該層職責一句話、關鍵檔案與用途、此層慣例/約束、與上層模組的關係…git add 後重新 commit」。
  - 未同步時「…並逐層檢查上層…是否也需堆疊更新」。
  - 有欠帳時「SKIP 不是豁免」，以及「最終 commit 必須全過」。
  - `--start-segment` 有欠帳時拒絕重記起點。
  - 新版 422 行留下的正好是 gate 沒寫的幾項。
- A15：plan mode 是使用者自己按的鍵；`ExitPlanMode` 那句（540 行）留著。
- A17：「開工先把該段標 IN_PROGRESS」在同一段 592 行。
- A18：§7.1 第 4 點（800 行）涵蓋。
- 三處引用修正都指得到：412 行「上一條」指 411 行；471 行「先 grep 既有的痕跡有沒有更強的」在 374 行；502 行「…第一個嫌疑人永遠是實驗本身」在 390 行。「上述那次」改成「曾有一次」（374 行），因為日期刪掉後「上述」已經沒有對象，改得對。
- 新版 241 行「那個檢查」：「下詳」的目標被 A08 刪了，但 303–304 行仍說明 `--start-segment` 要求新增報告，讀得通。
- 新版 260、539、600、602、787 行的指代都還指得到。
- 需要外部查證（不在我的範圍）：
  - scripts/CLAUDE.md:116 新寫「`commands/dd-init.md` 的蓋章版寫明了這點」（不是閉環）。我在 dd-init.md grep `不是閉環` 是 0 筆，交給審查者 b。要定案就跑 `grep -n '閉環' commands/dd-init.md`。
  - 發現 3 的影響大小，要看 Claude Code 在用 Write 新建 `docs/reviews/…` 檔、或只用 Bash `ls` 時，會不會載入 `docs/reviews/CLAUDE.md`。要拿 `claude -p` 實測，我沒跑。

【What I ran】

- Read 審查檔 S9-review-diff.txt：第 1–2530 行，分段讀到「===== diff 檔結束 =====」（1–200、201–400、401–600、601–800、801–1000、1001–1200、1201–1400、1401–1600、1601–1800、1801–2000、2001–2200、2201–2420、2421–2530）
- `grep -n` 審查檔的分節標記 → ①–⑤ 的位置，總長 2530 行
- `git status --short; git rev-parse --short HEAD` → 只有設計文件是 M，HEAD 4069ec5
- `sed -n 180,330p scripts/check-claude-md.sh` → 讀了 reviews_missing、`--start-segment`、`--segment-base`、擋下時的訊息
- `cat docs/reviews/CLAUDE.md`；`grep docs/reviews commands/dd-init.md`；`grep -rn docs/reviews/CLAUDE` → 命名慣例只寫在 docs/reviews/CLAUDE.md，蓋章版沒有指向它
- `sed -n 1,60p agents/code-reviewer.md` → Scope Discipline 與 Work Order 第 4 點
- `grep` 與 `sed -n 967,1000p; 1098,1175p; 1238,1260p; 1284,1294p install-dd-pipeline.sh` → 部署順序、`--commands-only` 與 `--update` 的範圍
- 把審查檔 492–1331 行取出到 scratchpad 的 a-newtpl.txt，再 `grep` 指代字樣（上一條、下方、那條、只用手上…） → 指代都還指得到，「只用手上」0 筆
- `grep -n -E '只用手上|時間花在哪|命名慣例|docs/reviews/CLAUDE|不是閉環' commands/dd-init.md templates/global/CLAUDE.md skills/*/SKILL.md` → 蓋章版第 87 行只剩「需要外部查證的列出來交回」
- `grep -n 開放問題 設計文件` → A05 說的「開放問題」那節存在（第 121 行）
- 沒有重跑 ④ 的 check.sh 與 ci-steps.sh

## 處置

- 1（Important，A07 只留下放寬的一半）：採納。新版 §3.9 那條改成「派工 prompt 寫明『只用手上的資料判斷,需要外部查證的列出來交回』;不設審查者的工具次數上限(…)」。查證：`agents/code-reviewer.md` 的 Work Order 第 4 點確實叫審查者自己寫腳本做實驗，Scope Discipline 只管範圍外的證據
- 2（Important，§3.9 連「實測／實證」一起刪）：採納，降為 Smell —— 照規則做事的行為不變，刪故事是計畫第 3 輪審過的附錄 A。在 `會漏`、`會跟著錯`、`不代表結果對`、`假綠` 四句後補 `(實測)`／`(實證)`；判準句（`不是 diff 多長`）與 87 份那句不補，補了讀不通
- 3（Important，A08 連帶刪掉 `docs/reviews/CLAUDE.md` 指標）：採納。補回「報告檔的命名慣例:見專案自己的 `docs/reviews/CLAUDE.md`」，放在「寫之前先 `ls`」那條後面
- 4（Smell，pasted in 涵不涵蓋檔案）：採納。④ 補「派工 prompt 標明這些已確認、不要重跑」
- 5（Smell，§3.10「上面那條」）：採納。改成「§3.9 那條」
- 外部查證「`scripts/CLAUDE.md:116` 指的蓋章版有沒有寫不是閉環」：主對話查了，`commands/dd-init.md:97`「pre-commit 不會強制它存在(只在開下一段時查…)—— 不要把它寫成閉環」，成立
- 外部查證「Write 新建檔時會不會載入 `docs/reviews/CLAUDE.md`」：沒查；指標補回後不再依賴它
