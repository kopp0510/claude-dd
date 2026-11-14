【我查了什麼】
- 讀 `install-dd-pipeline.sh`：陣列 36–125 行；`backup_before_overwrite` 187–199；`create_global_claude_md` 1156–1235；skills 520–545、agents 598–616、commands 915–930、scripts 1000–1016、output-styles 1040–1056；`uninstall` 1059–1140（1067 行的警告文字）
- 讀 `skills/dd-loop/SKILL.md` 43–66；`skills/self-improving-agent/hooks/hooks.json`、`skills/self-improving-agent/CLAUDE.md` 67–79；`skills/gate-guard/hooks/hooks.json`；`agents/code-reviewer.md:4`（`model: opus`）
- 讀 `commands/dd-init.md` Phase 5（317–320 行，commit 訊息「chore: 初始化 8 步開發迴圈慣例」）
- 讀 `docs/measurements/2026-10-23-reviewer-real-sessions.md` 13、60、86、317–364；`docs/designs/2026-10-23-裁決審查-design.md:66`
- 讀 `README.md` 38、56、58、67–82、127、156、176；`README.zh-TW.md` 39、57、133
- 讀 `.github/workflows/ci.yml` 12、564（runs-on）、239–263（flag 對照）、304–322、496–544（迴圈步數）
- grep 指令：`grep -rn 'skills-dir' .`、`grep -rn '5\.13\|3\.83' docs/ skills/`、`grep -n 'runs-on' .github/workflows/ci.yml`、`grep -n '移除後' install-dd-pipeline.sh`、`grep -n 'claude-md-management\|plugin install' README*.md`、`grep -rn "don't install\|single root" README.md commands/dd-init.md templates/global/CLAUDE.md`
- 沒跑測試、沒安裝、沒開容器、沒上網。

【批評】
輪1-R4-1｜重大｜「迴圈的時間與費用」這一項會把三組不同對象的量測寫成「步驟 4 的成本」。(a) 11.8 分中位數是單一 code-reviewer subagent 的 jsonl 起訖差，不是步驟 4 的牆鐘時間；步驟 4 是 ≥3 個並行審查者，計時方式不同。(b) 269s／5.13 美元來自 A 臂（沒有裁決者）對 S4 臂的比較，n=2 段、每段 2 發，且 A 同時改了三件事、分不開。量測檔自己寫「n 小，但方向一致」，dd-loop 也寫「n 小、同時改了三件事，只是方向」。計畫只要求附「樣本數與檔名」，沒要求附這些限定。
證據：`docs/measurements/2026-10-23-reviewer-real-sessions.md:13`（耗時定義是 subagent jsonl 的 max−min）、`:86`（311 筆是 per-subagent）、`:319`、`:361`；`docs/designs/2026-10-23-裁決審查-design.md:66`（「n=2/段；A 同時改了…三件事，分不開」）；`skills/dd-loop/SKILL.md:66`（「n 小、同時改了三件事，只是方向」）。
③ 成立的理由：CI 不驗 README 的數字陳述（`ci.yml` 的檢查只對 skills/agents/commands 數字與迴圈步數）；dd-loop 第 45 行允許文件類段落不派 agent，所以 S2 很可能沒有獨立審查者；計畫的「逐句核對表」只會確認「數字在引用檔裡找得到」，會通過，但抓不到「把單臂數字當成整體成本」這種錯。

輪1-R4-2｜小事｜「步驟 4 每段至少 3 個 opus 審查者」漏了例外。dd-loop 規定沒有人工寫程式碼的段落不派 agent，文件段落改用自己逐條核對。S2 本身是文件段，所以「每段」這個寫法對 S2 不成立。證據：`skills/dd-loop/SKILL.md:45`。opus 的部分正確（`agents/code-reviewer.md:4`）。

輪1-R4-3｜小事｜「--uninstall」段計畫只寫「不動各專案的 hook 與蓋章區塊」，漏了後果。uninstall 會刪 `~/.claude/scripts/check-claude-md.sh`（DD_SCRIPTS），安裝腳本在移除前的警告寫的是「移除後各專案掛著的 hook 會失效」。照計畫寫的話，讀者會以為專案 gate 會繼續生效。證據：`install-dd-pipeline.sh:1067`；`README.md:70–71` 目前沒有這句。

輪1-R4-4｜小事｜第 5 項「全域會掛的 hook」只查到設定檔宣告，沒有查到行為。self-improving-agent 的 `hooks.json` 由 skills-dir 載入（`skills/self-improving-agent/CLAUDE.md:78`），但 repo 裡唯一的實測紀錄只有 gate-guard（`CLAUDE.md:83`）。這次 session 裡，這個 hook 在讀到含 `error:` 字樣的原始碼時就跳出提醒（`PostToolUse:Bash hook additional context`），README 若只寫「全域掛上」，會漏掉「文字比對、會誤報」這個限制。

輪1-R4-5｜小事｜S2 的驗證寫「本機重跑 ci.yml 全部 step」。ci.yml 的 lint job 跑在 `ubuntu-latest`（`ci.yml:12`），macOS 那個 job 跑在 `macos-latest`（`ci.yml:564`）。本機只能跑 macOS 端，ubuntu 那個 job 不會被驗到。這次只影響「CI 跑在哪些平台」那段的陳述是否有實際跑過，README 本身寫的是設定而非結果，所以這條只是驗證描述不完整。

已核對、沒有問題的項目（為了對照，不算批評）：第 2 項（不帶 `--force` 時 skills、agents、指令、腳本、輸出風格不同就備份後覆蓋）與第 3 項（settings.json 與 installed_plugins.json 不備份、就地改）與計畫一致；第 1 項的範圍（不動全域 CLAUDE.md 與 backups、會取消 OFFICIAL_PLUGINS 的登記）與 `uninstall()` 一致；第 4 項的 commit 中文訊息與 dd-init 一致；第 8 項的 claude-md-management 指令與安裝腳本印出的 `claude plugin install ${plugin}@...` 格式一致。

【需要外部查證】
輪1-R4-6｜小事｜self-improving-agent 的 error-capture hook 是否真的在全域 session 生效（透過 skills-dir plugin 自動載入），repo 裡沒有 `claude -p` 實測紀錄可以證明。依 CLAUDE.md 的 skill 驗證規則，要用 `claude -p` 跑一次，並用 `--plugin-dir` 或 `Launching` 這類標記確認，不能只看設定檔。

輪1-R4-7｜小事｜`/dd-init` Phase 5 commit 的中文訊息是否在所有掛載路徑下都會出現（例如 `core.hooksPath`、husky 轉換路徑、升級路徑）。我只讀了 commit 指令本身，沒有追完所有分支；這要實際跑 dd-init 沙盒才能確認。
