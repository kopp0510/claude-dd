# 審查者的思考強度：medium 對 low（2026-11-15）

設計與判準的來源：`docs/designs/2026-11-15-speed-cost-design.md` 的 S2。實驗輸入在 `2026-11-15-reviewer-effort/`（凍結）。
這份文件只量、不改規則：結論寫「建議改」也只是建議，要不要改 `skills/plan-review/SKILL.md` 或 `skills/dd-loop/SKILL.md` 另外問使用者。

## 要回答的問題

2026-11-14 那件工作 104 分鐘裡，等 agent 交回佔 21.9 分（`2026-11-15-main-session-context.md`）。審查者派出去時帶 `effort: "low"`，會快多少、少抓多少？

## 方法

兩部分各兩臂，只差審查者的 `effort` 參數（`medium`／`low`），兩臂都明寫、不靠預設值。

| | 甲：計畫審查 | 乙：步驟 4 |
|---|---|---|
| 審查者 | 裁決者派的 general-purpose、`model: "haiku"`，人數由裁決者定（最少 3） | 父 session 派的 `code-reviewer`（定義檔 `model: opus`），剛好 3 個 |
| 中間層 | 裁決者：general-purpose、opus、明寫 `effort: "medium"`（兩臂相同） | 沒有 |
| 父 session | haiku，只派工、不審 | haiku，只派工、不審、不查證 |
| 素材 | 2026-11-14 一份計畫的第 1 輪裁決者 prompt（`judge.txt`）＋ repo 在 `b1935bb` 的快照 | 2026-10-24 用過的 G2（`639bde7`→`b66d8ae`，4 檔）、G3（`08b2576`→`8514fb2`，8 檔）兩段舊 diff |
| 發數 | 每臂 2 發，共 4 發，交錯跑（med、low、med、low） | 每份素材每臂 2 發，共 8 發；先跑完 G2 再跑 G3，各自交錯 |
| 命中怎麼看 | 審查者報告的聯集（另記裁決者採納、裁決者自己補上的） | 三份審查者報告的聯集（父 session 不查證，沒有採納欄） |
| 比的時間 | 裁決者整發秒數（裁決者紀錄檔第一筆，到它與所有審查者最後一筆） | 最慢審查者秒數 |

共用：`--settings '{"advisorModel":""}'`、`--permission-mode dontAsk --allowedTools "Agent Read Glob Grep Bash"`、`--max-budget-usd 8`、硬逾時 40 分鐘；cwd 是那一發的快照。
報告、秒數、token、`effort` 都從各個 subagent 自己的紀錄檔讀（`stats.py`），不讀父 session 轉述的文字。

跟設計文件寫的不一樣的兩處（跑之前就改、兩臂相同）：
- 乙的審查者任務說明由 `prepare.py` 先寫成檔（`reviewer-b.txt` 填好），父 session 只給每個審查者一句「先讀哪個檔」。設計原本寫由 haiku 父 session 自己組 prompt；那樣兩臂的 prompt 會隨父 session 的轉述而不同
- 父 session 最後只回一行 `DONE …`，不貼報告（報告本來就從紀錄檔讀）

作廢重跑（費用照計）：`permission_denials` 不是空的；任何審查者紀錄檔的 `effort` 不是該臂的值；模型不對（父 session 要 haiku、甲的裁決者要 opus、甲的審查者要 haiku、乙的審查者要 opus）；`modelUsage` 有別的模型；洩題檢查人工判定屬實。

洩題檢查怎麼判（2026-11-15 補，第一發 `P-med-1` 跑完、還沒看任何一份報告有沒有命中之前寫的）：
`P-med-1` 有一個審查者用 Bash 讀了部署在家目錄的 `~/.claude/skills/task-planner/SKILL.md` 與 `~/.claude/CLAUDE.md`（甲的裁決者 prompt 是當時的原文，沒有「只准讀這些路徑」那一節，
被審的計畫又是在講安裝到 `~/.claude`）。原本只寫「真的讀到外面才算」，沒分讀到的是什麼。定成：讀到的東西可能含答案、或比快照新，才算洩題 ——
①真的 repo 工作目錄 ②`~/.claude/projects/`（對話紀錄）③別發的快照、prompt、diff ④內容跟 `b1935bb` 對應檔不同的部署檔。
讀到「跟快照對應檔逐字相同」的部署檔不算（它從快照裡讀得到一樣的內容），但每一筆照樣記在結果裡，連同比對結果。

預算：估計總額超過 30 美元先停下問使用者；累計（含探針與作廢的發）到 30 美元就不再開新的一發。

## 開工前提的結果（2026-11-15）

### 1. Agent 工具的 `effort` 參數在 `claude -p` 裡有作用

三發探針，父 session 都是 haiku，每個 subagent 只回兩個字。讀的是 subagent 紀錄檔 assistant 那幾筆的 `effort` 欄位。

| 探針 | 派法 | 帶 `effort: "low"` 的那個 | 不帶參數的那個 | 費用（美元） |
|---|---|---|---|---|
| p1 | 第 1 層：2 個 general-purpose、`model: "haiku"` | `low` | `medium` | 0.02 |
| p2 | 第 2 層：中間一個 general-purpose（haiku、明寫 medium，紀錄 `medium`）再派 2 個 haiku | `low` | `medium` | 0.02 |
| p3 | 有定義檔的 agent：2 個 `code-reviewer`（紀錄的模型是 `claude-opus-5-5`） | `low` | `xhigh` | 0.46 |

三發的 `permission_denials` 都是空的。結論：參數在三種派法都有作用。

### 2. medium 是不是現在實際在跑的強度

- 這台機器、主對話是互動式 session 的那一次（2026-11-14T10:35Z 之後派出的 subagent 紀錄檔）：`code-reviewer` 19 個全部 `medium`（模型 `claude-opus-5-5`）；第 2 層的 haiku general-purpose 25 個全部 `medium`。所以 medium 臂就是那次實際在跑的強度
- `claude -p` 裡不帶參數的 `code-reviewer` 是 `xhigh`（上表 p3，n=1），跟互動式 session 觀察到的不一樣。這台機器的 `~/.claude/settings.json` 替 `claude-opus-5-5` 設了 `effortLevel: xhigh`，我推測是它造成的，沒驗證；互動式 session 為什麼是 medium 也沒查
- 所以兩臂都明寫強度；這份實驗的結論只講「明寫 medium 對明寫 low」，不講「不帶參數時」

### 3. 洩題檢查（比內容）

受測 session 會載入的部署檔，對 `b1935bb` 裡的對應檔做 `diff -q`：`~/.claude/CLAUDE.md` 對 `templates/global/CLAUDE.md`、`~/.claude/skills/plan-review/SKILL.md`、`~/.claude/skills/dd-loop/SKILL.md`、`~/.claude/agents/code-reviewer.md` 各對 repo 裡同名的檔 —— 四份都相同。無污染，甲那條重大照常計分。
`b1935bb` 的樹裡沒有那份計畫後來寫成的設計文件（`git ls-tree -r b1935bb --name-only | grep -c installer-hardening` 回 0）。
乙沿用 2026-10-24 判過的：只算 K1、K4、K5。

## 正確答案（跑之前寫死）

命中判準：同一個位置、同一個機制才算，級別不論（照 `2026-10-23-reviewer-real-sessions.md`「命中（判準跑之前寫死…）」那一節）。

### 甲

計分只算這 1 條重大（2026-11-14 第 1 輪裁決報告「採納（重大）」唯一的一條）：

- **M1** 位置：計畫 S2-1 的第 6 項「迴圈的時間與費用：步驟 4 每段至少 3 個 opus 審查者，附量測日期、樣本數與檔名」。
  機制（講到下面任一個就算，記是哪一個）：
  (a)「每段」不成立 —— diff 全是資料、設定、註解、文件時步驟 4 不派 agent；
  (b) 事實 F17 的兩組數字量的不是同一件事（單個 code-reviewer 的 wall time 對「直接派 vs 另派裁決者」的小樣本比較），不能寫成每段要花的時間與費用。
  只說這一項「要寫清楚」「數字要附出處」而沒講到 (a) 或 (b) 的不算。

參考（不進判準），當時採納的小事 13 條，逐條記命中與否：

| 代號 | 位置與內容 |
|---|---|
| m1 | S1-4 的 `backup_before_overwrite "commands"` 少了 target 參數，函式直接 return 0 |
| m2 | S1-1「不對所有情況都加 -L」的理由不成立：懸空連結在 `[ -e ]` 那行就 return 了，到不了 cp |
| m3 | S1-2「頂層不是物件 → 兩條路徑都算失敗」沒排除 `plugin_enabled_state`（它刻意回 `none`） |
| m4 | `mcp_scope` 的 `null` 改回 `unparseable` 後，跟函式上方 none／unparseable 的定義註解衝突 |
| m5 | S2-1 第 1 項「你自己裝的也一樣」會被讀成刪掉使用者自己裝的任何 plugin |
| m6 | S2-1 第 1 項「不動各專案的 hook」：gate 腳本被刪後 hook 只印警告、不再檢查 |
| m7 | S2-1 第 4 項 commit 語言少了條件（專案另有規定則從之；全域模板要使用者接受才寫入） |
| m8 | S1-4 新增「清舊指令檔前先備份」，架構文件「可回復」那條沒同步 |
| m9 | T2 的 jq 臂沒斷言 jq 真的在，沒有 jq 時兩臂都走 python3、等價斷言空通過 |
| m10 | T2 在 `set -e` 底下呼叫會回非 0 的失敗路徑，沒寫怎麼接 |
| m11 | 本機驗證沒指定 `/bin/bash`（3.2） |
| m12 | T1 從沒在 GNU 上紅過，ubuntu job 要 push 後才跑 |
| m13 | S2 全是文件，步驟 4 不派審查者，驗證只剩作者自己的核對表 |

### 乙

照 `2026-10-23-reviewer-real-sessions.md` 的定義，只算 K1、K4、K5（K2、K3、K6 受全域規則污染，這次不記）：

- **K1**（G2）`tests/test-gate.sh` 情境 ⑪：`docs` 被刪掉後 `reviews_missing` 的「沒有共同祖先」那一支沒跑到，`said "找不到共同祖先"` 是被 `owed_dirs` 印的那句滿足的
- **K4**（G3）`tests/test-gate.sh` 繞過② 那則其實是正常流程唯一的覆蓋
- **K5**（G3）`tests/test-gate.sh` 繞過① 那則測不到「pre-commit 不查報告」：那時 HEAD 等於起點，gate 直接放行

每臂最多 6 個命中：K1、K4、K5 各最多 2（每份素材每臂 2 發）。
2026-10-24 的三組都是 K1 兩發都中、K4 兩發都沒中、K5 兩發中一發。

## 判準（跑之前寫死）

每一部分各判一次，結論只有：建議改／不建議改／分不出／沒跑完，不下結論。n=2，都只講方向。

- **命中 ①**：medium 臂 0 發命中 →「分不出」（不管 low 幾發）；low 臂少於 medium 臂 →「不建議改」；其餘算 ① 成立。
  甲：M1 出現在「審查者報告的聯集」的發數，low ≥ medium（看聯集，不看裁決者採納 —— 裁決者會自己補查）。
  乙：K1、K4、K5 出現在聯集的發數合計，low ≥ medium。
- **時間 ②**：甲比裁決者整發秒數，乙比最慢審查者秒數。要同時成立：low 臂平均 ≤ medium 臂平均的 75%，而且兩臂不重疊（low 臂每一發都比 medium 臂每一發小；乙分 G2、G3 各自比）。
- ① 成立、② 成立 →「建議改」。① 成立、② 不成立 →「分不出」。寫「不建議改」而兩臂只差 1 發時，註明 n=2 下差 1 發分不出是不是真的比較差。
- 甲另有一條：兩臂的審查者人數分佈不同 → 最多寫「分不出」。
- 少跑：某一部分有任何一臂、任何一份素材不到 2 發 → 那一部分寫「沒跑完，不下結論」，已跑的數字照列。
- 操作檢查：low 臂審查者的思考 token 沒有比 medium 臂少時，結果裡註明「欄位是 low，但思考量沒有變少」。

為什麼要「不重疊」：同一做法、同一份素材，兩發之間本來就差很多 —— 2026-10-24 的 `G3-dhk-3` 最慢審查者 136 秒、`G3-dhk-4` 234 秒（差 1.72 倍），只看 75% 的話雜訊就能過關。
雜訊下碰巧過關的機率：沒有任何效果時，每臂 2 發的四個秒數「low 兩發都比 medium 兩發小」的機率是 2!·2!/4! = 1/6（約 17%）；乙要 G2、G3 各自成立，兩份素材獨立時約 1/36。

## 結果

還沒跑。
