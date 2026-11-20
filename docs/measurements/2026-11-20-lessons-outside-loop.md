# 三條教訓放回全域 §3.9 之後，迴圈外與迴圈暫停中用不用得到（2026-11-20）

問題：使用者 2026-11-20 決定把三條教訓（race 與交易、併發的驗法、git 進行中狀態）從 dd-loop 搬回全域模板 §3.9「規則」，位置與 v1.6.16 相同。
§3.9 的前言是「每完成一個功能段落…依序走下面 8 步」，那一節沒有任何一句寫這幾條在迴圈外也適用；搬回之前模板的指標句寫過「迴圈外的修改、迴圈暫停中也一樣」，搬回時拿掉了。
不在 8 步迴圈裡的 session、以及迴圈暫停中（`/dd-stop on`）的專案，碰到資料庫 race 時會不會用到這幾條？要不要補一句範圍？
（步驟 4 審查的 S2-a-1，報告在 `docs/reviews/2026-11-19-prompt-audit/`。）

結論：**這個 prompt 下，迴圈外 8 發有 7 發、迴圈暫停中 8 發有 7 發用到（回答裡有「隔離級別」）。照事先寫的規則（過半）不補範圍句，模板那三條維持與 v1.6.16 相同。**
只有一個 prompt、一種領域（資料庫 race），每臂 8 發。

## 做法

- Claude Code 2.1.327，`claude-fable-5-2`，每發一個全新的 session，同一臂的 8 發同時跑。prompt、旗標與 `docs/measurements/2026-11-20-domain-traps-pointer.md` 相同
  （「src/orders.js 的 reserveStock,兩個請求同時進來會超賣。請告訴我要怎麼改(先不要改檔),以及改完要怎麼驗證真的修好了。」；`--permission-mode dontAsk --settings '{"advisorModel":""}' --allowedTools "Skill Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent"`）。
- 兩臂跑之前都先部署搬回版：`diff -q templates/global/CLAUDE.md ~/.claude/CLAUDE.md` 相同，`~/.claude/CLAUDE.md` 與 `~/.claude/skills/dd-loop/SKILL.md` 裡「領域陷阱」都是 0 筆。
- 迴圈外臂：那一次量測用的拋棄式專案（scratchpad 底下，`package.json` 與 `src/orders.js`，不是 git repo）。scratchpad 底下不載入 cwd 的記憶檔，使用者層的 `~/.claude/CLAUDE.md` 會載入。
  另開一發 haiku、不給任何工具，叫它照貼 context 裡含「read-then-write」的那一行：貼出來的與 `~/.claude/CLAUDE.md` 的那一行整行相同（1 筆），沒有工具呼叫。
- 暫停臂：在平常工作的專案底下開一個拋棄式 git repo（同樣兩個檔，commit 一次），跑部署版的 `dd-stop.sh on`，它把暫停聲明寫進 `CLAUDE.local.md`。
  前置檢查：一發 haiku、不給工具，照貼 context 裡含「8 步開發迴圈暫停中」的那一行，與 `CLAUDE.local.md` 的那一行整行相同（1 筆）。
  這一臂的 session 連上層目錄的 `CLAUDE.md` 也會載入，所以兩臂的差別不只有暫停聲明。

## 判定式

- 一發算有效：`result` 的 `subtype` 是 `success`，而且 `permission_denials` 是空的。
- 一發算「用到」：`result` 的文字裡有「隔離級別」四個字（那一條的原文是「先查隔離級別」）。
- 臂的結論：有效的發裡用到的過半 → 不補範圍句；沒過半 → 在 §3.9「規則」補一句涵蓋全部驗證教訓的範圍句，重新部署再量。

⚠️ **「隔離級別」這個記號是看過先前 16 發之後挑的。** `docs/measurements/2026-11-20-domain-traps-pointer.md` 那 16 發裡，讀到 dd-loop 那一節的 12 發（舊臂第 2、3、6、7 發，新臂 8 發）每一發的回答都有這四個字，
沒讀到的 4 發（舊臂第 1、4、5、8 發）都沒有。沒讀到的只有 4 發，「沒讀到就不會寫這四個字」的依據就這麼多。
迴圈外臂的規則在部署之前寫好；暫停臂原本寫「這次不量」，看過迴圈外臂的結果之後才決定加量，它的規則在它開跑之前寫好（記號與門檻沿用）。

## 結果

16 發的 `subtype` 都是 `success`、`permission_denials` 都是空的；沒有一發呼叫 Skill `dd-loop` 或 Read `dd-loop/SKILL.md`。

| 臂 | 有「隔離級別」 | 沒有的那一發 |
|---|---|---|
| 迴圈外 | 7／8 | 第 7 發（回答用了 advisory lock，沒有「隔離級別」四個字） |
| 暫停中 | 7／8 | 第 4 發（回答有 `read committed`，沒有「隔離級別」四個字） |

次要的（不進判定）：回答裡有沒有 `sleep` 這個字（那一條的驗法是「臨時插一個 sleep 把窗拉寬」）。迴圈外第 1、2、3、4、7、8 發有，暫停中第 1、2、4、5、6、8 發有；
指標那一次量測的 16 發裡只有舊臂第 2 發、新臂第 5 發有。這一項是事後看的，沒有事先寫規則。

費用：迴圈外 8 發合計 4.21 美元，暫停中 8 發合計 3.40 美元（各發 `result` 的 `total_cost_usd` 相加；兩發 haiku 檢查沒算）。

## 沒量的

- 只有這一個 prompt。git 進行中狀態那一條沒有測；§3.9「規則」裡另外五條驗證教訓（擋誤用、鑑別力測試、0 紅先疑實驗、識別符 git grep、清點分母）也沒有測。
- 「用到」只看回答裡有沒有那四個字，沒有逐發讀回答核對做法對不對。
- 沒有「補了範圍句」的對照臂：兩臂都過半，照規則不補，所以也沒量補了會不會更高。
- 暫停聲明是 `dd-stop.sh on` 當場寫的那一版；使用者在對話裡下 `/dd-stop on`、同一個對話接著做的情況沒有測。
- 原始 jsonl 沒有進 repo（裡面有本機路徑與 plugin 清單）。
