# 全域模板 §7.2 改過的兩列會不會照新寫法觸發（2026-11-20）

`c0f6d33` 改了全域模板 §7.2 兩列：`claude-md-improver` 只接 `CLAUDE.md`（原本是任何 `.md` 檔），`self-improving-agent` 拿掉「優化 skill」。
這裡各開一個全新的 session 測一發。**每個 prompt 只有一發**，只能說「這一發是這樣」，不是比例。

## 做法

- 先確認部署的 `~/.claude/CLAUDE.md` 和 `templates/global/CLAUDE.md` 逐字相同（`diff -q`）。
- 拋棄式專案（開在 scratchpad 底下）：一份 `CLAUDE.md`、一份有錯字的 `README.md`、一份 `skills/foo/SKILL.md`。
  scratchpad 底下的 cwd `CLAUDE.md` 不會被載入（`docs/measurements/CLAUDE.md`「已知的坑」），使用者層的 `~/.claude/CLAUDE.md` 會，這次要測的正是那一份。
- Claude Code 2.1.327，`claude-fable-5-2`。指令（照 `docs/measurements/CLAUDE.md`「測 skill 會不會自己叫」）：
  `claude -p "<prompt>" --output-format stream-json --verbose --max-budget-usd 3 --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}' --allowedTools "Skill Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent" < /dev/null`
- 判定：jsonl 裡 `Skill` 工具呼叫的 `skill` 參數，與 tool_result 裡的 `Launching skill:`。四發的 `subtype` 都是 `success`、`permission_denials` 都是空的。

## 結果

| prompt（原文） | 叫了哪個 skill | 新寫法預期 |
|---|---|---|
| 幫我審查這個專案的 CLAUDE.md,看有沒有過期或寫錯的地方 | `claude-md-management:claude-md-improver` | 叫它 |
| 幫我修 README.md 裡安裝步驟的錯字 | 沒有 | 不叫 `claude-md-improver`（舊寫法「任何 `.md` 檔」會命中） |
| 幫我優化 skills/foo/SKILL.md 這個 skill 的寫法 | `skill-creator:skill-creator` | 不叫 `self-improving-agent`（舊寫法有「優化 skill」） |
| 幫我整理 memory,把學到的沉澱成規則 | `self-improving-agent` | 叫它 |

## 沒量的

- 舊寫法那一臂沒有跑：這裡只證明新寫法這四發照預期走，沒有證明舊寫法會走錯。
- §7.1 第 5 步（「模糊」照 §6.1 判斷）與 §7.6 的改動沒有測。
- 原始 jsonl 沒有進 repo（裡面有本機路徑與 plugin 清單）。
