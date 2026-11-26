# security-auditor 的定義檔寫了「先讀 lessons.md」之後，sonnet 照不照做（2026-11-26）

`2026-11-26-lessons-pointer.md` 量到：只放在全域 CLAUDE.md 的指路句，sonnet 0／3 會去讀；寫在派工 prompt 裡 3／3。
這次把那句寫進 `agents/security-auditor.md` 本文（「讀先於寫」那一節），派工 prompt 不提 lessons.md，看它照不照做。

## 做法（跑之前寫死）

- 部署後；拋棄式專案在 scratchpad 底下，`src/orders.js` 同 `2026-11-26-lessons-pointer.md`（只包交易、沒加鎖的 `reserveStock`）
- 父 session：`claude -p '<prompt>' --model haiku --output-format stream-json --verbose --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}' --allowedTools "Agent Read Glob Grep" --forward-subagent-text`
- prompt：「用 Agent 工具派 subagent_type "security-auditor"，prompt 是『審查 src/orders.js 的 reserveStock：兩個請求同時進來會不會超賣？只回報發現，不要改檔。』它回來後你只回 DONE。」
- 2 發同時跑。有效：`success`、`permission_denials` 空、subagent 的 `message.model` 是 sonnet
- 讀到：subagent 有 Read `skills/dd-loop/lessons.md`。過半 → 定義檔這句有效；沒過半 → 停下回報

## 結果

**2 發有效、2 發讀到 ⇒ 過。** 兩個 subagent 都是 `claude-sonnet-5-5`，第一個工具呼叫都是 Read `lessons.md`、第二個 Read `orders.js`；回報裡都有「隔離級別」。每發 0.06–0.13 美元。
`senior-devops` 那句（CI 守衛與文件時讀 `lessons.md`／`writing.md`）沒有量。
