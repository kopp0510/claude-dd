---
description: 暫停或恢復這個專案的 8 步開發迴圈與 CLAUDE.md gate（on／off／status）— 暫停期間只做實作、測試與 commit，恢復後再補
argument-hint: on | off | status
---

# DD 暫停 — 8 步開發迴圈與 gate 的開關

暫時不要跑迴圈的步驟 3–8、也不要讓 gate 擋 commit 時用。暫停是延後，不是豁免：暫停期間改了程式碼而沒更新
CLAUDE.md 的目錄，恢復之後 gate 照樣會要求補上。

使用者給的參數：`$ARGUMENTS`

檢查與改檔都在 `~/.claude/scripts/dd-stop.sh` 裡，這份指令只負責呼叫它、把結果講給使用者。**不要自己改
`git config`、不要自己編輯 `CLAUDE.local.md` 來代替它。**

---

## 執行步驟

1. **確認腳本在**：`[ -x ~/.claude/scripts/dd-stop.sh ] && echo 在 || echo 不在`。
   不在 → 告訴使用者：到 claude-dd 的 clone 跑 `git pull && ./install-dd-pipeline.sh --force` 之後再下一次指令。停下，不做後面的步驟。

2. **決定子指令**：參數只收 `on`、`off`、`status` 三個（各只收一個字）。
   - 沒有給參數 → 用 `status`，並在回覆裡說明三個用法：`/dd-stop on` 暫停、`/dd-stop off` 恢復、`/dd-stop status` 看現況
   - 給了別的字 → 不要猜是哪一個；回覆三個用法，停下

3. **執行**：`~/.claude/scripts/dd-stop.sh <子指令>`（在專案裡跑；它自己會找到 repo 根目錄）。
   把它印出來的內容整份原樣貼給使用者。下面各步要你告訴使用者的事，貼出的輸出裡已經有的不用再講一次。
   - exit code 不是 0 → 照它印的原因回報，停下。不要重試、不要自己動手把它沒做的事做完
     （它印的處理方式由使用者做；使用者明說要你做，你才動手）

4. **`on` 之後**：輸出裡要有「8 步迴圈已暫停」這幾個字才算成功（只看 exit code 不夠）。沒有 → 照實回報輸出，停下。成功時：
   - 這個對話從現在起照暫停聲明做（它寫在 repo 根目錄的 `CLAUDE.local.md`，用 Read 讀一次）：只做步驟 1、2，
     不跑步驟 3–8、不呼叫 `dd-loop`、不跑 `--start-segment`，commit 照平常下
   - 告訴使用者：其他已經開著的對話要重開才讀得到聲明；恢復用 `/dd-stop off`

5. **`off` 之後**：輸出裡要有「8 步迴圈已恢復」這幾個字才算成功。沒有 → 照實回報輸出，停下
   （exit 5 代表旗標已經清掉、但聲明還留在 `CLAUDE.local.md`：把它印的原因與處理方式轉述給使用者）。成功時：
   - 這個對話從現在起照專案 CLAUDE.md 與全域 CLAUDE.md §3.9 跑完整的 8 步；context 裡先前讀到的暫停聲明作廢
   - 告訴使用者：暫停期間開的、現在還開著的其他對話要重開，才會恢復跑迴圈
   - 輸出裡「以下是 gate 的欠帳檢查」底下列了要補的 CLAUDE.md（分「缺少 CLAUDE.md 的目錄」「未同步更新」兩組，每行開頭是 `<目錄>/CLAUDE.md`，後面可能接一段括號說明）→ 把那幾個目錄講給使用者，
     問要不要現在補；使用者說要才動手。那一段是 gate 平常擋 commit 時印的固定文字，這次沒有 commit 被擋：
     「commit 已擋下」不要回報成 commit 失敗；「AI agent 執行時：…」「git add 後重新 commit」「其他處理方式」那幾行這次不照做。
     使用者說要補時：用那一段印的 `git diff <起點> -- <目錄>` 看暫停期間那個目錄改了什麼，把受影響的段落更新進它的 CLAUDE.md
     （沒有這個檔就讀完該目錄再新建），只 `git add` 補的那幾份、另開一個 commit，不加 `SKIP_DOC_CHECK=1`。這個 commit 只補文件、不算功能段落，不必為它跑步驟 3–8；
     commit 沒被擋就是補齊了（還有沒補的，gate 會擋下並列出來）
   - 那一段印的是「起點檔壞了，暫停期間的欠帳算不出來」→ 照樣轉述，不要講成沒有欠帳
   - 輸出裡有 review 報告那一行（專案有 `docs/reviews/` 時才有）→ 照樣轉述

6. **`status` 之後**：步驟 3 貼的輸出就是現況（旗標一行、聲明一行），不用重講。多了一行「兩邊不一致」→ 補一句：
   要暫停下 `/dd-stop on`、要恢復下 `/dd-stop off`（它印的是腳本自己的路徑，對使用者講 slash 指令），由使用者選；不要自己修。

---

## 已知限制（使用者問到時照實說）

- 只在這個 clone 生效：旗標在 `.git/config`、聲明在沒進版控的 `CLAUDE.local.md`，協作者不受影響
- 同一個 repo 的其他 worktree：gate 會一起暫停（設定共用），但那邊的 Claude 讀不到聲明（`CLAUDE.local.md` 每個 worktree 各一份）
- 暫停中使用者自己在終端機的 commit 一樣被放行、一樣記帳
- 暫停聲明能不能讓 Claude 停下迴圈，靠的是 Claude 照 `CLAUDE.local.md` 做；gate 那一半是腳本擋的，不靠 Claude
