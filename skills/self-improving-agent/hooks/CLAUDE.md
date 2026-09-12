# self-improving-agent / hooks

vendored skill 裡唯一會實際執行的程式碼：一支 PostToolUse hook，在 Bash 指令的輸出裡
找錯誤字樣，命中就回一則約 40 token 的提醒，建議使用者跑 `/self-improving-agent:remember`
把解法存下來。它自己不寫 auto-memory。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `error-capture.sh` | hook 本體。stdin 收 Claude Code 的 JSON，取 `tool_response` 的 stdout+stderr，逐行比對 `EXCLUSIONS` 與 `ERROR_PATTERNS`，命中則用 `hookSpecificOutput.additionalContext` 回提醒。JSON 讀寫 jq 優先、python3 後備，兩者都沒有就靜靜 exit 0 |
| `hooks.json` | 註冊用設定。`command` 必須是 `$HOME/...` 絕對路徑 —— hook 以當下工作目錄為基準執行，寫 `./hooks/xxx.sh` 換個專案就找不到（根目錄 CLAUDE.md「Skill hook 路徑規範」，`validate_skill_hooks()` 會在部署前擋下相對路徑） |

## 此層約束

- **它看不到 exit code**。`tool_response` 裡**每一筆都有**的是 `stdout` / `stderr` /
  `interrupted` / `isImage` / `noOutputExpected`，另有偶發欄位 `gitOperation`(230)、
  `returnCodeInterpretation`(95)、`persistedOutputPath` / `persistedOutputSize`(71)、
  `backgroundTaskId`(50)、`backgroundCwdHint`(11)、`timedOutAfterMs`(9) ——
  **共 12 種，不是 5 種**（2026-09-12 掃 `~/.claude/projects` 底下 414 份 transcript、
  9651 筆帶 stdout/stderr 的 `toolUseResult`；括號是出現筆數）。
  但**沒有任何一個是數字退出碼**：最接近的 `returnCodeInterpretation` 只有 95 筆，
  值是 `No matches found` 這種語意註解，不是通用退出狀態。所以這支 hook 是**文字比對**，
  不是「偵測失敗」—— 成功但輸出裡有 `failed`、`error:` 的指令一樣會觸發。
  文件不可寫成「zero overhead on success」，要寫「未命中錯誤字串時」
- **exclusion 一律逐行比對，不可退回整份輸出比對**。舊版用 `[[ "$OUTPUT" == *"$excl"* ]]`
  對整份輸出比，變成一票否決：輸出裡任何一處出現 `console.error` 或 `no error`，
  同一份輸出裡真正的失敗全部被吞掉，而且是完全靜默（零輸出、exit 0，跟「這次沒錯」長得一模一樣）。
  2026-09-12 修掉，兩個實測會踩到的真實案例已寫成註解留在檔內
- **改這支腳本後必須跑 `./test-error-capture.sh`**（同目錄，純 bash 無依賴，CI 也會跑）。
  9 個情境：4 個必須觸發、5 個必須靜默。**新增行為時同批補一個情境進去** ——
  沒有情境守著的行為等於沒寫，而這支 hook 的失效是零輸出 exit 0，跟「真的沒錯誤」長得一樣。
  其中三個是 2026-09-12「一票否決」那個 bug 的回歸測試：真錯誤與 `console.error` 同在一份
  輸出、`no errors` 與 `Build failed` 並存、被排除的行在前而真錯誤在後。
  「單純找不到檔案」那條是**煙霧測試** —— 修好前後都會觸發，只證明沒把整支弄壞
- 它在 CI 的 ShellCheck 清單裡（`.github/workflows/ci.yml`，逐檔寫死），
  bash 3.2 相容、`set -eu` 下不可用會回非 0 的裸指令

## 與上層的關係

上層有**四句**宣稱散在**三份**檔案裡，**改行為就要四句一起改**：
`../SKILL.md`（「Token overhead」那行）、`../CLAUDE.md`（Hooks 段）、
`../README.md` **兩句**（What's Included 表格的 Hooks 列，以及 Design Principles 的
「Zero capture overhead」）。上游原本四句都寫成「成功時零開銷」，都是錯的 ——
2026-09-12 第一次修只改到四句中的三句，是 code-review 抓到 README 有兩句才補齊。
這是 vendored 內容（MIT, Reza Rezvani，`../LICENSE`），本地修改要留得住理由 —— 所以踩雷寫在這裡，
不寫在 commit 訊息裡。
