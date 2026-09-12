# self-improving-agent / hooks

vendored skill 裡唯一會實際執行的程式碼：一支 PostToolUse hook，在 Bash 指令的輸出裡
找錯誤字樣，命中就回一則約 40 token 的提醒，建議使用者跑 `/self-improving-agent:remember`
把解法存下來。它自己不寫 auto-memory。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `error-capture.sh` | hook 本體。stdin 收 Claude Code 的 JSON，取 `tool_response` 的 stdout+stderr，逐行比對 `EXCLUSIONS` 與 `ERROR_PATTERNS`，命中則用 `hookSpecificOutput.additionalContext` 回提醒。JSON 讀寫 jq 優先、python3 後備，兩者都沒有就靜靜 exit 0 |
| `test-error-capture.sh` | 上者的行為測試（CI 會跑）。整套跑兩輪：一輪預設 PATH、一輪把 jq 藏起來逼它走 python3 後備，否則另一條分支零覆蓋。payload 手寫進 JSON，含雙引號或反斜線會生出壞 JSON 讓 hook 靜默 exit 0、案例假通過 —— 所以每個 payload 送出前都先驗 JSON 合法性，不合法就判該案例失敗 |
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
- **改這支腳本後必須跑 `./test-error-capture.sh`**（同目錄，CI 也會跑）。情境數不寫在這裡
  （會過期）—— 跑一次就會逐案印出來。**新增行為時同批補一個情境進去**：這支 hook 的失效是
  零輸出 exit 0，跟「真的沒錯誤」長得一樣，沒有情境守著就等於沒寫。
  「單純找不到檔案」那條是**煙霧測試** —— 修好前後都會觸發，只證明沒把整支弄壞
- **它守的是逐行比對的「語意」，別把它當全面防線。** 以下是實際做變異測試量出來的，不是推測：
  守得住 —— exclusion 不可一票否決整份輸出、stdout 與 stderr 兩邊都要讀、回報的要是**第一個**
  命中行（`break 2` 退化成 `break` 會被抓）、Context 不可空白或被截掉、`hookEventName` 要正確、
  jq 與 python3 兩條分支都要能動。
  `ERROR_PATTERNS` / `EXCLUSIONS` 兩張清單**沒有被系統性涵蓋**：只有情境剛好用到的那幾項
  （`npm ERR!`、`ERROR:`、`Build failed`、`console.error`、`.error(`、`no error` …）受保護，
  大幅砍清單會被抓到是**副作用不是設計** —— 動到情境沒碰過的項目，測試不會有任何反應。
  **想知道某個改動有沒有被守到，就自己做一次變異測試**：改壞那一處 → 跑測試 → 還原。
  2026-09-12 就是這樣量的：第一版有一批變異溜過去，補了 stdout、第一行、hookEventName、
  雙分支四類情境之後才守住
- **兩支都在 CI 的 ShellCheck 清單裡**（`.github/workflows/ci.yml`，逐檔寫死 —— 新增腳本要自己加進去），
  也都要 bash 3.2 相容。但兩支的 shell 設定**刻意不同**：`error-capture.sh` 是 `set -eu`，
  裡面不可出現會回非 0 的裸指令；`test-error-capture.sh` 只有 `set -u`，**不可以加 `-e`**。
  實測（拿一個 `exit 3` 的假 hook 餵給兩個版本）：`set -u` 印 37 行、exit 1、26 個案例
  全部正確報出 `hook exit=3`；改成 `set -eu` 只印 3 行、exit 3 —— **印完標題就死，
  一個案例都沒跑**，而且看起來只像「輸出比較短」。它整個工作就是去抓 hook 的非 0 結束碼，
  加 `-e` 等於把要驗的東西變成自己的死因。
  （順帶一提，`rc != 0` 那條分支平常沒有情境會走到，就是用這個 `exit 3` 假 hook 驗的）

## 與上層的關係

上層有**四句**宣稱散在**三份**檔案裡，**改行為就要四句一起改**：
`../SKILL.md`（「Token overhead」那行）、`../CLAUDE.md`（Hooks 段）、
`../README.md` **兩句**（What's Included 表格的 Hooks 列，以及 Design Principles 的
「Zero capture overhead」）。上游原本四句都寫成「成功時零開銷」，都是錯的 ——
2026-09-12 第一次修只改到四句中的三句，是 code-review 抓到 README 有兩句才補齊。
這是 vendored 內容（MIT, Reza Rezvani，`../LICENSE`），本地修改要留得住理由 —— 所以踩雷寫在這裡，
不寫在 commit 訊息裡。
