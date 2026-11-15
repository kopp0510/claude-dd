【我查了什麼】

- 目錄與指路：`ls docs/designs/` 有 7 份（與計畫一致）；`grep -n '進度以' CLAUDE.md` 無輸出；根目錄 CLAUDE.md 的 `^## ` 第一個是「## 安裝 / 更新」（行 5）。
- 規則文件：`find . -name CLAUDE.md` 共 20 份（含 `scripts/CLAUDE.md`、`tests/CLAUDE.md`、`skills/self-improving-agent/hooks/CLAUDE.md`，沒有 `docs/CLAUDE.md`）；`grep -rn -E '新增|同時改|同批|要一起|同步' --include=CLAUDE.md .` 讀了與本計畫相關的條目（根 CLAUDE.md 行 45–341、`tests/CLAUDE.md` 行 11、`scripts/CLAUDE.md` 行 184–192）。
- 任務規則：`skills/task-planner/SKILL.md` 行 108（「加一段指路」）、115、119–121（「規則區塊整段照抄」）、131–145（IN_PROGRESS、`--start-segment`、commits 欄、標 DONE 才刪指路）。根 CLAUDE.md 行 186「小任務只走步驟 1、2，全部 commit 完，整段才跑 3–8」。`templates/global/CLAUDE.md` 行 249 是步驟 3 code-simplifier。
- 函式與呼叫點：`grep -n` 確認 `backup_before_overwrite`（行 187）、`jq_inplace`（209）、`py_inplace`（228）、`plugin_enabled_state`（397）、`validate_skill_hooks`（463）、`install_builtin_skills`（504）、`mcp_scope`（630）、`install_plugins`（730）、`create_commands`（879）、`uninstall`（1059）、`show_completion`（1241）存在；`backup_before_overwrite` 9 個呼叫點與計畫 F4 相符；`install-dd-pipeline.sh` 1404 行、`tests/test-install.sh` 87 行。
- 備份行為：`sed -n` 讀 agents（行 596–606）、commands（912–923）、scripts（1000–1008）、output-styles（1040–1047）。四者在內容不同時都先 `backup_before_overwrite` 再覆寫，不看 `$FORCE`。計畫 README 第 2 點的描述與此相符。
- `command_exists` 呼叫點（行 251–1122）：jq 與 python3 分支由 `command_exists` 決定，計畫 T2 的「重定義 command_exists」可行。
- README：`sed -n '67p;70p;156p' README.md`、`grep -n -i 'claude-md-management'`、`grep -n -i 'hook'`、`grep -n -E 'CHANGELOG|UPGRADING'`（行 84–85 已標 *(Traditional Chinese)*）。README 第 19 行的翻譯句與計畫 F16 相符。
- 量測檔：`docs/measurements/2026-10-23-reviewer-real-sessions.md` 存在，行 86 為「次數=311 中位=11.8 分」，與計畫相符。
- hook：`skills/self-improving-agent/hooks/hooks.json` 為 PostToolUse、Bash、`error-capture.sh`。
- CI：`runs-on` 為 ubuntu-latest（行 12）與 macos-latest（行 564）；`test-install.sh` 在 36、557、594 行。
- 架構文件：`DD_PIPELINE_ARCHITECTURE.md` 行 72–74 寫「jq_inplace / py_inplace / json_edit」，行 74 寫「可回復」。計畫的 S1 文件同步有列 ARCH 的「可回復」與 CI 防線表，但沒提 `json_edit`。
- 另：`grep -c -E '^\s+- name:' .github/workflows/ci.yml` 回 26（兩個 job 合計）。計畫寫 lint job 為 20，兩者不矛盾，但我無法從這個數字確認 20。

【批評】

輪1-R2-1｜重大｜計畫沒有安排在根目錄 CLAUDE.md 加指路那句。§4.4 與 task-planner 規定開表時要同時加指路，計畫卻只說「根目錄 CLAUDE.md 沒有這句」，S1 文件同步也只列「只補這次留下的坑」。｜證據：`grep -n '進度以' CLAUDE.md` 無輸出；task-planner SKILL.md:108 規定「專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」；SKILL.md:115 的做法是把文件與指路一起 commit。③ 的理由：下一個 session 讀不到表，會依 §4.1 重估段落、另開第二張表；gate 不檢查指路，這個遺失不報錯。

輪1-R2-2｜重大｜計畫沒有排 §3.9 的步驟 3–8。S1、S2 的流程只有小任務 commit 與驗證，沒有 code-simplifier、≥3 個 code-reviewer 且報告落地、步驟 5 再測、步驟 7、步驟 8。S1 文件同步只寫「跟最後一個小任務或步驟 6 一起 commit」。｜證據：根 CLAUDE.md:186「小任務只走步驟 1、2，全部 commit 完，整段才跑 3–8」；templates/global/CLAUDE.md:249 步驟 3、4 的規定。① 每段都會經過；② 跳過使用者定的必經流程；③ 步驟 3–5 本來是抓錯的地方，計畫後面沒有其他關卡能補上，又不會報錯。

輪1-R2-3｜重大｜段落起點與進度表狀態沒有排。計畫的表全部是 TODO、commits 欄空白，也沒有 `--start-segment`。task-planner 規定開工時記起點、把段落標 IN_PROGRESS、commits 欄先填 `<起點>..`。｜證據：task-planner SKILL.md:133；計畫的進度表草稿。① 每段都會；② step 8 的範圍（`--segment-base` 或表上的起點）與 gate 的 SKIP 欠帳都依賴起點；③ 起點錯了，範圍會靜默算錯，之後不會有報錯。

輪1-R2-4｜重大｜設計文件的四節（來源、假設、進度表、段落與小任務）沒有規則區塊。task-planner 規定「規則區塊整段照抄」，因為接手的 session 只讀文件、沒載入這個 skill。少了它，接手的 session 不知道要標 DONE 的條件、也不知道要刪指路。｜證據：task-planner SKILL.md:119–121「規則區塊整段照抄：接手的 session 只讀文件、沒載入本 skill，也要照得做」；SKILL.md:136 的「標 DONE」與刪指路規則。① 每個後續 session 都會碰到；② 接手的人會跳過步驟 3–8 與刪指路；③ 沒有任何檢查會抓到。

輪1-R2-5｜小｜S1 的驗收條件「等價表探針 92 例不一致數從 16 變 0」指的是 scratchpad 裡的探針，不在 repo 裡。將來的 session 無法重跑，驗收會變成只能看計畫的敘述。（T2 會把案例搬進 repo，可以補上，但計畫沒寫這個驗收要改成 T2。）｜證據：計畫 S1 驗收、F6 寫明探針在 scratchpad、不在 repo。

輪1-R2-6｜小｜README 若在 S2 新增 CHANGELOG 或 UPGRADING 的連結，依 CLAUDE.md 規定要標 *(Traditional Chinese)*。計畫沒有提這點。｜證據：根 CLAUDE.md 注意事項「CHANGELOG.md 與 UPGRADING.md 維持純繁中，英文 README 連向它們時須標註」；README.md:84–85 已有標註，所以要保持一致。

輪1-R2-7｜小｜計畫寫的 `ci.yml` 20 個 step 沒有可以直接核對的依據。`grep -c -E '^\s+- name:' .github/workflows/ci.yml` 回 26（兩個 job 合計）。計畫需要註明是 lint job 的數字，驗收才能對得上。｜證據：上面那條 grep 的輸出 26。

【需要外部查證】

輪1-R2-8｜重大｜S2 第 8 點要在 README 前置需求補 `claude plugin install claude-md-management@claude-plugins-official`，但計畫沒有確認這個 plugin 的 `.claude-plugin/plugin.json` 有沒有 `version` 欄位。根 CLAUDE.md 規定：缺 version 的 plugin 不能自行填版本，而且要靠手動安裝先登記。若沒有 version，指令的寫法與安裝腳本的提示都會不對。｜為什麼需要：repo 裡沒有這個 plugin 的檔案；要查 claude-md-management 的 marketplace 副本或 `installed_plugins.json` 才能判定。

【這次沒發現的】整體來說，計畫列的大部分前提與數字都對得上（7 份設計文件、9 個 backup 呼叫點、備份行為、量測數字、README 的句子、`--check` 的訊息、CI 平台、hook 內容），沒有發現把已經規定好的事誤判為需要請示的情況。
