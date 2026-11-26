【我查了什麼】
- 讀完審查包 `P-med-9.pack.md` 全部 166 行（分兩段讀：1–166 一次讀完，含 `<<<審查包結束>>>`）。
- 專案根目錄 `<WORK>/P-med-9`。以下證據路徑都相對此根目錄。
- F16 逐字核對：`grep -n` / `sed -n '19p;38p;67p;70p;156p' README.md` 全部吻合。`grep -n -i -E 'windows|linux|wsl' README.md` 回 0。
- F17 核對：`skills/dd-loop/SKILL.md:66` 的 269s／5.13／4/6、350s／3.83／3/6 吻合；`docs/measurements/2026-10-23-reviewer-real-sessions.md:86` 的 311／11.8／27.7 吻合。
- F18 核對：`DD_PIPELINE_ARCHITECTURE.md:72,74` 吻合。
- `CHANGELOG.md:19` 有 `## 未發布`。
- 規則：`CLAUDE.md:243–248`（README 雙語同批更新）、`CLAUDE.md:264–290`（CI 不驗、需手動同步的 README 區塊，含「核心工作法」段與「8 步」字樣）、`templates/global/CLAUDE.md` §3.9 步驟 4（`最少 3 個`、`不派的例外見 dd-loop`）。
- 語言與 commit：`templates/global/CLAUDE.md:28–29` 吻合（回應與 commit 都是繁中）。
- hook：`install-dd-pipeline.sh:35–50`（`PROMOTED_SKILLS` 含 `gate-guard`、`self-improving-agent`）；`grep -n -E 'claude-plugin|plugin\.json|marketplace add|plugins/cache' install-dd-pipeline.sh` 只看到版本取值與 cache 路徑，沒有把 `skills/*/.claude-plugin` 註冊成 plugin 的程式碼；`grep -n 'hooks' install-dd-pipeline.sh` 只有 `validate_skill_hooks`（463–491）與呼叫點（1346），沒有寫入 settings.json。`skills/self-improving-agent/.claude-plugin/plugin.json` 與 `skills/gate-guard/.claude-plugin/plugin.json` 存在。`skills/self-improving-agent/hooks/error-capture.sh` 頭註解與 `skills/self-improving-agent/hooks/CLAUDE.md` 說明它是文字比對（`error:`、`exit code`），不是 exit code。
- 「不裝 gate」：`grep -n -E '不裝|不掛|don.t install|不安裝' commands/dd-init.md README.md templates/global/CLAUDE.md`，見 `commands/dd-init.md:264–269`、`:292`、`:367`。
- CI 的 README 檢查範圍：`.github/workflows/ci.yml:99–116`（數字宣稱）、`:239–263`（flag 三方對照）、`:304–322`（迴圈步數）。
- 未跑測試、build 或 CI，只讀檔與 grep。

【批評】
輪1-R2-1｜小事｜計畫 S2-1 第 6 點要 README 寫「步驟 4 每段至少 3 個 opus 審查者」，這句與同檔現有說明衝突。現有文字寫明，增量只有資料、設定、註解或文件時不派審查者；S2 本身就是純文件段，照這句寫會讓 README 對純文件段說錯。計畫也沒有把這個例外寫進去。計畫的驗證只靠作者自己的「逐句核對表」，CI 的正規式不會抓到這句。證據：`README.md:104`（「Step 4 has one exception: when the increment's diff is all data, configuration, comments or documentation … no agent is dispatched」）；`templates/global/CLAUDE.md` §3.9 步驟 4「不派的例外見 `dd-loop`」；`CLAUDE.md:251` 同樣寫法。

輪1-R2-2｜小事｜計畫的事實 F20 說「『don't install the gate』在 repo 裡沒有對應做法」，與 repo 不符。`/dd-init` 有「使用者選擇不裝」的路徑，`commands/dd-init.md:264–269` 寫明不裝就跳過第 4 步、第 5 步改講「這個 repo 沒裝 gate」；`:292`、`:367` 也有對應處理。計畫第 8 點（照查到的改寫那句）的前提因此寫錯：該問的是「單一根 CLAUDE.md 這種模式在 repo 裡有沒有定義」，不是「不裝 gate 有沒有做法」。證據：`commands/dd-init.md:264–269`、`:292`、`:367`；`README.md:156` 原句。

輪1-R2-3｜小事｜S2-1 第 6 點只給時間（中位 11.8 分），卻要寫「迴圈的時間與費用」。費用數字只出現在 `skills/dd-loop/SKILL.md:66`（n 小、同時改三件事，原文自己寫「只是方向」），而計畫沒有把這個限制寫進去。`docs/measurements/2026-10-23-reviewer-real-sessions.md:86` 的 311 筆是 code-reviewer 次數，不是「每段」的成本，計畫沒有說明這層換算。另外，該量測的標題寫「含本 repo S1 那兩發新做法的審查」，樣本含本 repo 自己的審查，計畫沒有提這個偏差。

輪1-R2-4｜小事｜S2 的驗證抓不到 S2 寫進去的新事實。計畫說「本機重跑 ci.yml 全部 step」，但 CI 的檢查只比對數字、flag 名稱與迴圈編號（`.github/workflows/ci.yml:99–116`、`:239–263`、`:304–322`），新加的費用、hook、語言、平台等敘述不在任何機械檢查範圍內。唯一的檢查是作者自己寫的逐句核對表，而 S2 是純文件段，不派 code-review（見 1）。計畫應把新增的每句事實指到具體的 grep 或量測檔驗收條件。

輪1-R2-5｜小事｜S2-1 第 2 點列出「不帶 `--force` 會換成 repo 版、舊版備份到 `pre-install-<時間>/`」，但漏掉 S1-4 會改的行為：`create_commands` 清除 `deprecated_dd` 那 5 個舊指令檔（計畫 S1-4；事實 F9：`create_commands` 開頭的 `local deprecated_dd=(...)`，迴圈裡直接 `rm`）。S1 完成後這些檔會先備份，但 README 不會寫。S2 依賴 S1，README 應跟著 S1 的實際行為寫。

【需要外部查證】
輪1-R2-6｜重大（若查證為假）｜S2-1 第 5 點要寫「全域會掛的 hook：…補上 self-improving-agent 的那一個」，但 repo 內看不到這些 hook 會被 Claude Code 掛上。安裝腳本只把 skill 目錄複製到 `~/.claude/skills/`，沒有把 `.claude-plugin/plugin.json` 或 `hooks.json` 註冊成 plugin 或寫進 `settings.json`（見「我查了什麼」的 grep）。`skills/self-improving-agent/CLAUDE.md:78` 寫「registered automatically by `hooks/hooks.json`」，這是自己說的，不是實測。`README.md:127` 說 gate-guard「is installed globally」也依賴同一個機制。為什麼需要：Claude Code 是否會讀 `~/.claude/skills/<名稱>/` 底下的 `.claude-plugin/plugin.json` 與 `hooks/hooks.json`，只能靠實際載入驗證（例如在沙盒 HOME 裝好後，讓 Claude Code 觸發一次 Bash 錯誤字串，看有沒有出現 `<error-detected>` 提醒）。如果不會掛，S2-1 第 5 點、`README.md:127` 原句、與 gate-guard 的「全域」說法都要改。計畫的開工前提第 3 點只讀 `hooks.json` 內容，無法證明掛上。

【我查了什麼的補充】
- 沒找到計畫說的 `docs/designs/` 新檔（2026-11-14-installer-hardening-design.md）；這不影響 S2 的批評，只表示計畫是草稿。
- 計畫在 F20 說 S2 前提 1、3、4 沒重跑；我沒有重跑，只有讀到 `commands/dd-init.md` 與 `templates/global/CLAUDE.md` 的相關段。前提 1（中文硬編在哪些檔）我沒有完整 grep，交給計畫自己的開工前提處理。
