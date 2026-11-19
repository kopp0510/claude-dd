# 「領域陷阱」搬到 dd-loop 之後，迴圈外的修改拿不拿得到（2026-11-20）

問題：`c0f6d33` 把全域模板 §3.9 的三條教訓（race 與交易、併發的驗法、git 進行中狀態）搬到 `skills/dd-loop/SKILL.md` 的「領域陷阱」一節，
模板只留一句指標。不在 8 步迴圈裡的 session 碰到併發 race 時，會不會去讀那一節？指標句改寫之後有沒有比較常到？
（步驟 4 審查的 S1-c-1，報告在 `docs/reviews/2026-11-19-prompt-audit/`。）

結論：**這個 prompt 下，舊指標 8 發到了 4 發，改寫後 8 發到了 8 發。差 4 發，照事先寫的判定式（差 3 發以上）寫成「改寫後比較常到」。**
只有一個 prompt、一種領域（資料庫 race），每臂 8 發。

## 兩臂

兩臂的 `~/.claude/CLAUDE.md` 只差指標那一句（`git diff ecfc89c -- templates/global/CLAUDE.md` 只有這一處）：

- 舊臂（`ecfc89c` 的模板，當時部署的那一份；部署新版時留下的備份 `global/CLAUDE.md` 和 `git show ecfc89c:templates/global/CLAUDE.md` 逐字相同）：
  「併發 race、資料庫鎖、git 進行中狀態的驗法見 `dd-loop` skill 的「領域陷阱」一節(碰到這類修改時讀)」
- 新臂（部署工作目錄的模板之後，`diff -q` 確認部署版與 repo 相同）：
  「併發 race 與資料庫鎖的修法與驗法、git 進行中狀態的驗法在 `dd-loop` skill 的「領域陷阱」一節:碰到這類修改就用 Read 讀 `~/.claude/skills/dd-loop/SKILL.md` 的那一節,迴圈外的修改、迴圈暫停中也一樣(讀檔不算呼叫 `dd-loop`)」

`skills/dd-loop/SKILL.md` 兩臂相同。

## 做法

- Claude Code 2.1.327，`claude-fable-5-2`，每發一個全新的 session。舊臂先同時跑 3 發，後來補的 5 發同時跑；新臂 8 發同時跑。
- 拋棄式專案（開在 scratchpad 底下）：`package.json` 與 `src/orders.js`。`orders.js` 只有一個 `reserveStock`：
  `BEGIN` → `SELECT available` → 不夠就 `ROLLBACK` → `INSERT … ON CONFLICT (sku) DO UPDATE SET available = $2` → `COMMIT`（沒有鎖）。
  scratchpad 底下的 cwd `CLAUDE.md` 不會被載入（`docs/measurements/CLAUDE.md`「已知的坑」），使用者層的 `~/.claude/CLAUDE.md` 會，這次要測的正是那一份。
- prompt（原文）：「src/orders.js 的 reserveStock,兩個請求同時進來會超賣。請告訴我要怎麼改(先不要改檔),以及改完要怎麼驗證真的修好了。」
- 指令：`claude -p "<prompt>" --model claude-fable-5-2 --output-format stream-json --verbose --max-budget-usd 3 --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}' --allowedTools "Skill Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent" < /dev/null`
- 前置檢查（不算進任何一臂）：同樣的旗標下叫它 Read `~/.claude/skills/dd-loop/SKILL.md`，`subtype` 是 `success`、`permission_denials` 是空的。
  所以「用 Read 讀到」這條路在這組旗標下量得到。

## 判定式

事先寫的（舊臂跑之前）：

- 一發算「到了」：jsonl 裡有 Read 工具呼叫、`file_path` 以 `skills/dd-loop/SKILL.md` 結尾，或有 Skill 工具呼叫、`skill` 是 `dd-loop`。
- 一發算有效：`result` 的 `subtype` 是 `success`，而且 `permission_denials` 是空的。無效的發不算進任何一邊。
- 新臂過關：有效的發裡過半到了。

⚠️ **發數與差幾發才算數，是看過舊臂前 3 發之後才改的，不是事先寫的。** 原本是每臂 3 發、「新臂多 2 發以上才說改寫有用」。
舊臂前 3 發到了 2 發，3 發對 3 發不可能再多 2 發，所以改成每臂 8 發（舊臂在部署新版之前補了 5 發）、差 3 發以上才寫「改寫後比較常到」，否則寫「沒量到差別」。
新臂的 8 發是定下這條之後才跑的。

## 結果

16 發的 `subtype` 都是 `success`、`permission_denials` 都是空的。

| 臂 | 到了 | 怎麼到的 |
|---|---|---|
| 舊 | 4／8 | 第 2、3、7 發呼叫 Skill `dd-loop`；第 6 發先 Grep「領域陷阱」再 Read `~/.claude/skills/dd-loop/SKILL.md`；第 1、4、5、8 發沒有碰 dd-loop |
| 新 | 8／8 | 8 發都是先 Grep「領域陷阱」再 Read `~/.claude/skills/dd-loop/SKILL.md`；沒有一發呼叫 Skill `dd-loop` |

次要的（不進判定）：回答的文字裡有沒有那一節才有的做法。

| 臂 | 提到 `FOR UPDATE` | 提到 `read committed` | 提到 sleep |
|---|---|---|---|
| 舊 | 第 1、2、5、6、7 發 | 8 發都有 | 第 2 發 |
| 新 | 8 發都有 | 8 發都有 | 第 5 發 |

這張表分不出新舊：沒有碰 dd-loop 的舊臂第 1、5 發也講了 `FOR UPDATE` 與 `read committed`（模型本來就知道）。
「插一個 sleep 把窗拉寬」新臂 8 發只有 1 發的回答用了 sleep 這個字，就算讀到了那一節，也不代表照它的驗法答（沒有逐發讀回答對過）。

費用：舊臂 8 發合計 5.28 美元，新臂 3.84 美元（各發 `result` 的 `total_cost_usd` 相加）。

## 沒量的

- 只有這一個 prompt。git 進行中狀態（rebase／merge）那一條沒有測。
- 迴圈暫停中（`/dd-stop on`）的專案沒有測；指標句寫了「迴圈暫停中也一樣」，那半句沒有被這次量測碰到。
- 「到了」只證明它讀了那個檔，沒有證明它照那一節的做法改或驗。
- 會不會在不相干的修改上也去讀那個檔（多花的 token）沒有量。
- 這是「留在 dd-loop 靠指標」這條路量到的結果；搬回全域模板那條路沒有對照（搬回去每個 session 都載入，不必量到不到得了）。
- 原始 jsonl 沒有進 repo（裡面有本機路徑與 plugin 清單）。
