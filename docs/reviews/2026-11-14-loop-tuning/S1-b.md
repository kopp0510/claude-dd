# S1-b：審查者 B（全面，先從「三段新規則本身：照字面做會不會做錯、跟別的規則打不打架」下手）

## 派工

`subagent_type: code-reviewer`（不帶 model，agent 定義是 opus），S1-a、S1-b、S1-c 三個在同一則訊息平行派出。
派工 prompt（逐字，路徑去識別：`<S>` 是這個 session 的 scratchpad；下面「發現」節同樣只換了路徑與使用者名稱）：

````text
先 Read <S>/tune-review/prompt-common.txt，照它做。你的代號是 S1-b。

你的方向（先從這裡下手，看完再全面看）：三段新規則本身。一個之後的 session 照字面做，會不會做錯、卡住、或跟別的規則打架。逐段拿去對：同一份根目錄 CLAUDE.md 的其他段落（尤其「新增 Skill 步驟」「新增 Command 步驟」「第三方 Skill / Agent 收編檢查清單」「注意事項」）、skills/dd-loop/SKILL.md（步驟 4 審查者怎麼交回報告）、skills/security-audit/CLAUDE.md（「從上游更新」與分支清單那幾節）、templates/global/CLAUDE.md（§2、§3.9、§3.10、§4.6）。有兩句互相矛盾、或一句話有兩種讀法，引兩邊的原文。
````

`prompt-common.txt` 全文（逐字，路徑去識別）：

````text
你是 claude-dd repo（<REPO>）8 步開發迴圈步驟 4 的審查者。職責：找漏洞，每條附證據（路徑:行，或指令與輸出），沒證據的不算。不寫優點、不客套。

審查範圍：段落 S1「照 2026-11-14 的量測調整三條規則」從 58ae9b0 到目前工作目錄的整段（五個 commit）。全部是文件與規則文字，沒有產品程式碼。

材料：
- diff 檔：<S>/tune-review/diff.txt（834 行）。**用 Read 的 offset/limit 每次 300 行讀到最後一行**：Read 一次讀太多會靜靜截斷、不報錯。
  ① 整段 diff ② 步驟 3 沒跑的說明 ③ 被改到的檔的整檔內容（根目錄 CLAUDE.md 整檔、CHANGELOG 的未發布節）④ 已跑過的驗證與預期值
- ④ 列的驗證都已跑過、結果如列，不要重跑（測試、CI step、安裝、claude -p 都不要跑）。「跑過」不代表結論對 —— 你懷疑它驗的不是它宣稱的東西，就指出來
- 被改到的檔（CLAUDE.md、CHANGELOG.md、docs/measurements/2026-11-14-session-cost.md、docs/designs/2026-11-14-loop-tuning-design.md）以 diff 檔那份為準；其他檔直接讀工作目錄（審查期間不會再變）
- 專案規則：根目錄 CLAUDE.md、各層 CLAUDE.md、~/.claude/CLAUDE.md（尤其 §3.10 寫文件的判準）
- 這一段的計畫與假設：docs/designs/2026-11-14-loop-tuning-design.md（在 diff 裡）

已知、不用再報的：計畫審查第 1 輪沒過、第 2 輪沒跑成，使用者選了「拿掉放手語，其餘直接做」（設計文件「假設」節有寫）；放手語沒有寫進任何檔，不在審查範圍。量測用的 transcript 不在 repo，數字重跑不了（量測檔「方法」「限制」有寫）。

只用手上的資料與讀檔、grep、git 指令判斷；需要外部查證的列出來交回，不要自己做。不要改任何檔、不要 commit。

輸出格式：
- 每條：級別（Critical / Important / Smell）｜檔:行｜問題｜證據（引原文或指令輸出）｜具體失敗情境（誰照這段做、會怎樣錯）
- Not reported：看過、判斷不是問題的，各一句理由
- What I ran：跑過的 grep / 讀過的檔
- 需要外部查證：每條一句
````

## 發現

S1-b 的審查結果：Critical 0、Important 5、Smell 1。範圍是 58ae9b0..91b4614 加三段新規則。我依派工指示，把這三段拿去對根目錄 CLAUDE.md 的其他段落、skills/dd-loop/SKILL.md、skills/security-audit/CLAUDE.md 和全域模板。下面的行號都是工作目錄版本；diff 檔裡那份 CLAUDE.md 與工作目錄相同，因為沒有未 commit 的改動。

**Important 1｜CLAUDE.md:131、134 對 CLAUDE.md:369–371**
- 問題：「指令文字只留先跑它」和「注意事項」那條互相矛盾，而它指去的正是那條。
- 證據：
  - 131 寫：「能寫成腳本就寫成腳本…指令文字只留「先跑它、非 0 就停下回報」」
  - 369 寫：「`commands/*.md` 的安全檢查不可以只靠 `scripts/` 的新行為：`--commands-only` 只跑 `create_commands`…指令文字要自己先查」
  - 134 只說「見「注意事項」`--commands-only` 那條」，沒說哪一條優先。
  - 這條規則自己舉的 2026-11-14 例子，是在指令文字裡留了檢查，不是只留「先跑它」。commands/dd-init.md:107–109 寫：「這一步不能省：舊版升級腳本不會自己擋（用 `--commands-only` 更新的人手上可能是舊版腳本）」。
- 失敗情境：
  1. 下一個 session 照 131 的字面，把 dd-init 第 6 步的存在檢查收進腳本，指令只留「跑它、非 0 就停」。
  2. 使用者用 `--commands-only` 更新，手上是沒有這個檢查的舊腳本。
  3. 舊腳本 exit 0，指令照樣往下做，exit 6 那次修掉的 symlink 寫穿問題重新出現。
  - 腳本是新檔時，舊環境裡找不到它，exit 127，會停下來，這種情況是安全的。危險的是「腳本已存在、只是舊版」，而 131 沒有區分這兩種。

**Important 2｜CLAUDE.md:54–55 與 60 對 skills/security-audit/CLAUDE.md:47**
- 問題：乾跑「不准寫檔」和「完整報告寫進那個檔」，同一步裡有兩種讀法。
- 證據：
  - 54–55 寫：「只讀的步驟拿實際在用的專案跑、不准寫檔」
  - 60 寫：「一次派好幾個沙盒臂或乾跑時…完整報告寫進那個檔」
  - security-audit/CLAUDE.md:47 對乾跑的定義是「只讀、不寫檔、不跑 node、不派 agent」
  - S1-4 的驗證是「試派兩個 haiku subagent 做唯讀的小查核」，結果它們寫了報告檔（設計文件 S1-4 與 diff 檔 ④）。所以當時採用的讀法是「唯讀 = 不改 repo，scratchpad 可寫」，但這個讀法沒有寫進任何一處。
- 失敗情境：
  - 照 security-audit「從上游更新」第 8 步重跑乾跑時，派工 prompt 會同時含「不寫檔」和「報告寫進檔」。
  - agent 選哪一邊都違反另一句：寫了檔就違反 47 的定義；沒寫檔，主對話照 61「核對檔案在」會判失敗。
  - 主對話也可能為了能寫檔，把乾跑改成 54 不允許的形式。
- 要補的是一句「報告檔放 scratchpad、不算寫檔」之類的界定。

**Important 3｜CLAUDE.md:396 的理由句，對 skills/security-audit/CLAUDE.md:26**
- 問題：「清單沒有東西會用到」與 repo 內現有流程相反，而且三段文字繞成一個圈。
- 證據：
  - CLAUDE.md:396 寫：「「要猜但做得完」的不整理成清單：文字既然不改，清單沒有東西會用到」
  - security-audit/CLAUDE.md:26 寫：「動到本檔引用的原句（…拿本檔「」裡的英文原句 `grep -F` 新版，找不到的就是被改了）時，照根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步重跑相關分支的乾跑」
  - 也就是說，「乾跑發現」裡那批要猜的原句，正是上游更新時判斷要不要重跑的觸發器。清單有東西在用它。
- 兩個後果：
  - 之後照 396 收的 skill 沒有這份清單，上游改了某條「要猜」分支時，沒有任何東西會觸發重跑。這正是設計文件 S1-3 自己寫的「之後怎樣算這條錯了」。
  - 繞圈：399 說 security-audit 第 8 步「仍照它自己寫的做」；第 8 步說照根目錄第 3 步做；根目錄第 3 步對「照原文收」的 skill 又被 395 改成「只回答做不做得完」。照字面走，重跑出來只有做不做得完，第 8 步要的「更新本檔」（乾跑發現那節）就拿不到要猜的內容，那節會慢慢過期。

**Important 4｜CLAUDE.md:61 對 CLAUDE.md:55–56**
- 問題：「結論對得上」有兩種讀法，其中一種把「不看 agent 自述」換成了核對自述。
- 證據：
  - 55–56 寫：「結果用指令核對，不看 agent 自述」
  - 61 寫：「主對話用指令核對檔案在、結論對得上，要看細節才分段讀檔」
- 失敗情境：
  - 一行結論和報告檔都是 agent 寫的，「結論對得上」最省事的讀法是拿一行結論去比報告檔的結論。
  - 對沙盒臂，這等於用 agent 自述驗 agent 自述，sandbox 裡的實際檔案狀態沒有用指令核對。
  - 還有「要看細節才分段讀檔」：主對話照字面，一行結論是「綠」就不讀檔、也不跑判定指令。
  - 2026-11-14 量測裡就有判定翻轉的例子：B 一次判紅是回報打錯標題（CHANGELOG 未發布節）。只看自述會把這種當真。

**Important 5｜CLAUDE.md:131 對 .github/workflows/ci.yml:34–36、549–557、587–590**
- 問題：「exit code 加 `tests/` 的 bash 測試」沒交代測試要怎麼進 CI，而 CI 的測試清單是逐檔寫死的。
- 證據：
  - ci.yml 的 shellcheck 清單逐檔列了 `tests/test-gate.sh`、`tests/test-dd-init-upgrade.sh`、`tests/test-install.sh`。
  - ubuntu job 和 macOS bash 3.2 job 也各自逐一寫 `run: tests/test-*.sh`。
  - 「新增 Script 步驟」第 3 步有寫「那份清單是逐檔寫死的，沒加等於完全不檢查」，但 131 只要求「加 `tests/` 的 bash 測試」，沒指向 ci.yml，也沒指向「新增 Script 步驟」。
- 失敗情境：
  - 下一個 session 照 131 新建 `tests/test-x.sh`，本機跑綠就 commit。
  - CI 既不 shellcheck 它，也不在 ubuntu 或 bash 3.2 上跑它，131 說「靠測試驗」的那層實際沒進 CI。
  - 根目錄「目錄結構」的 tests 那行也逐檔列名，同樣會靜靜過期。

**Smell 1｜CLAUDE.md:397 寫「「採納（Important）」的 10 條裡」**
- 問題：用了數字，沒有列舉，和全域 §3.10「凡是能列舉的就列舉，不要數」不一致。
- 證據：S2-judge.md:24–38 我數出來確實是 10 條，目前對得上。被引的是已 commit 的審查報告，過期風險低，所以只列 Smell。
- 失敗情境：較弱。將來若有人補改 S2-judge.md（例如補一條遺漏），這個數字會靜靜錯掉。

**看過、判斷不是問題的**
- 「一次派好幾個」沒給門檻（1 個算不算）：派一個時交回全文的成本小，依規則的目的讀不出會做錯。
- 新規則會不會套到 dd-loop 的審查者身上：60 限定「沙盒臂或乾跑」，dd-loop SKILL.md:67–68 要求審查者完整報告逐字存檔、主對話讀全文。兩者範圍不重疊，沒有衝突。
- 131 要加測試，和全域 §3.5「不主動新增測試」：專案 CLAUDE.md 的優先序（第 3 位）高於全域 §3–§6（第 4 位），而且這是專案明文規則。在 task-planner 段落內還要照「測試清單以外先問」，這是互相配合，不是矛盾。
- 395「照原文收、不改它的文字」對 security-audit 是否成立：它只插了 dmi 與 vendored 行（security-audit/CLAUDE.md:9–11），上游文字未改，算數。
- 「做不完的寫進該 skill 目錄 CLAUDE.md 的已知限制」：security-audit 沒有叫「已知限制」的小節，D11c 寫在分支清單節的 84 行，用了「記成已知限制」字樣。下一個 session 找得到，不至於做錯。
- 397「其餘都改到 skills/security-audit/CLAUDE.md」：10 條的處置是否全落在該檔，屬其他審查者的方向，我沒有逐條核。

**What I ran**
- Read prompt-common.txt
- Read diff.txt，分 1–300、300–599、600–835 三段讀完
- `grep -n` 新規則各關鍵句、`--commands-only`、`不准寫檔` → 根目錄 CLAUDE.md 53–61、131–134、369–371、395–399
- `sed -n 1,50p; 78,92p skills/security-audit/CLAUDE.md` → 「從上游更新」1–9 步、乾跑定義在 47、D11c 在 84
- `sed -n 45,100p skills/dd-loop/SKILL.md` → 步驟 4 派工與報告落地
- `grep -n '交回\|自述\|不寫檔\|唯讀' templates/global/CLAUDE.md` → 沒有與新規則衝突的命中
- `grep -n 'tests/test-' .github/workflows/ci.yml` 和 `sed -n 24,40p; 540,592p` → 測試清單逐檔寫死
- `sed -n 24,40p docs/reviews/2026-11-14-security-audit-intake/S2-judge.md` → 採納（Important）10 條
- `grep -n 'commands-only\|CLAUDE.md.dd-upgrade' commands/dd-init.md` → 107–110

**需要外部查證**
- Agent 工具派出的 subagent 有沒有 session scratchpad 的寫入權。如果某些 subagent_type（例如 Explore、Plan）沒有 Write，60 的寫法就派不了那幾類 agent：要看各 agent 定義的 tools，或實派一次。

## 處置

- Important 1（「只留先跑它」與 `--commands-only` 那條矛盾）採納：規則補上界線 —— 只適用新開的腳本（`--commands-only` 更新的人手上沒有它，跑起來非 0 會停）；
  把新檢查加進既有腳本不算，指令文字仍要自己先查。「新腳本在舊環境會非 0」是照 shell 的行為推論的，沒有實跑
- Important 2（「不准寫檔」與「報告寫進檔」）採納：補一句「scratchpad 的報告檔不算上面說的寫檔，不准寫的是被測的專案」
- Important 3（「清單沒有東西會用到」與 security-audit 第 8 步相反）採納，處置是**撤回 S1-3**：`skills/security-audit/CLAUDE.md` 第 8 步確實拿「本檔引用的原句」判斷要不要重跑，
  那些原句就在乾跑發現那份清單裡，所以那段的理由不成立。收編很少發生、根目錄 CLAUDE.md 每個 session 都載入，不改寫、直接拿掉那一段與 CHANGELOG 條目（設計文件 S1-3 記了原因）
- Important 4（「結論對得上」可能變成核對自述）採納：改寫成「那一行結論與報告檔都是 agent 自述，結果照樣用指令核對；主對話先確認報告檔在，要看細節才分段讀」
- Important 5（測試怎麼進 CI 沒交代）採納：`grep -n 'tests/test-' .github/workflows/ci.yml` 確認 ShellCheck 清單與兩個 job 的 `run:` 都逐檔寫死。規則補上：新腳本照「新增 Script 步驟」納管；
  測試加進既有的 `tests/test-*.sh`，新開測試檔要自己接進 `ci.yml` 與本檔「目錄結構」`tests/` 那行
- Smell 1（「10 條」用數字）：那一段隨 S1-3 撤回
- 需要外部查證（哪些 agent 類型沒有寫檔工具）：沒有實派驗證；規則補了「派有寫檔工具的類型，例如 general-purpose」。這個 session 的 agent 清單寫著 Explore、Plan 沒有 Edit／Write
