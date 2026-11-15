---
name: code-simplifier
description: 調用官方 code-simplifier agent 簡化程式碼。當使用者要求簡化、降低複雜度、清理冗餘，或執行 8 步開發迴圈步驟 3 時啟用。不適用於 PR 審查（用 code-reviewer）。
allowed-tools: Task, Bash, Read, Grep, Glob
---

# Code Simplifier — 官方 agent 包裝器

本 skill 只負責介面層：定範圍 → 調用官方 code-simplifier agent → 呈現結果。
簡化邏輯全在 agent 內，不在此重複。

## 範圍決定

- **8 步開發迴圈步驟 3**（最常見）：範圍 = 該功能段落從起點到現在的變更（`git diff <起點>`，
  起點 = `~/.claude/scripts/check-claude-md.sh --segment-base` 的輸出），**不詢問**，直接執行。
  一段常有好幾個 commit，`HEAD~1` 只看得到最後一個；取不到起點（指令 exit 非 0 或輸出是空的）時不要退回 `HEAD~1`、也不要重跑 `--start-segment`（起點會移到現在，整段變成 0 行）：指令印出「共同祖先是 `<sha>`」就用那個 sha 當起點，不用問；其他情況問使用者「這一段從哪個 commit 開始」，拿到的 commit 就是起點，步驟 4、8 也用它（不是下面「範圍不明」那一題 —— 那題的預設是最近修改的檔案，會把範圍縮窄）。
  **專案有 `task-planner` 進度表時例外**：起點改用表上這段 commits 欄的起點。
  表在哪不用問 —— 根目錄 CLAUDE.md 第一個 `##` 之前的指路句會寫明檔名（通常在 `docs/designs/`）；
  沒有那句指路就是沒有進度表，照 `--segment-base` 走。回頭做 `BLOCKED` 過的段落時，
  中間插做別段會把 `--segment-base` 往後推，用它會漏掉這段先前已寫好的部分
- **使用者指明檔案/目錄/片段**：照指示，不追問
- **範圍不明**：問一題 —「要簡化哪個範圍？（預設：最近修改的檔案）」，其餘參數用預設

預設不含測試檔；使用者要求才包含。

## Agent 調用

依序嘗試 `subagent_type`：

1. `code-simplifier:code-simplifier`（plugin 命名空間）
2. `code-simplifier`（本地 `~/.claude/agents/code-simplifier.md`）

兩者皆回 `Agent type not found` → 停下，請使用者跑 `./install-dd-pipeline.sh` 補齊。

Prompt 模板：

```
請簡化以下程式碼，提高可讀性與可維護性，保留所有功能：

範圍：{檔案清單或片段}

重點：降低圈複雜度、改善命名、移除冗餘、簡化條件（early return、減少巢狀）。
約束：不改公開 API 簽名；有測試必須全過。編碼風格只照專案 CLAUDE.md 寫明的；agent 定義裡列的偏好（import 排序、`function` 與箭頭函式的取捨）不算專案標準，專案 CLAUDE.md 沒寫就不套用，不重排 import。
輸出：簡化摘要 + 關鍵變更的 Before/After 對比。
```

## 結果呈現

轉述 agent 的簡化摘要與 Before/After 對比。統計數字**只引用 agent 實際回報的**，
沒有就不列 — 禁止自行估算複雜度指標。

簡化後提醒（在 8 步迴圈中則直接續行步驟 4）：用 `git diff` 審查變更，重跑測試確認行為不變。

## 範圍外

- 架構層重構（模組拆分、設計模式）、效能調校 — 超出簡化範疇，明說不做
- 第三方 / 生成的程式碼 — 不修改
- 效能關鍵段落 — 「看似複雜但高效」的寫法保留，標註說明即可
