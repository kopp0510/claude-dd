【我查了什麼】
- 讀 `install-dd-pipeline.sh` 第 187–250 行（`backup_before_overwrite`、`jq_inplace`、`py_inplace`）與 1241–1275 行（`show_completion`）；函式行號用 `grep -n -E 'backup_before_overwrite\(\)|jq_inplace\(\)|py_inplace\(\)|mcp_scope\(\)|install_plugins\(\)|uninstall\(\)|show_completion\(\)|create_commands\(\)|validate_skill_hooks\(\)|deprecated_dd'` 核對，函式都存在。
- `wc -l`：`install-dd-pipeline.sh` 1404 行、`tests/test-install.sh` 87 行、`README.md` 265 行、`README.zh-TW.md` 281 行。
- `tests/test-install.sh`：`grep -c -E 'settings\.json|\.claude\.json|installed_plugins'` 回 0，與事實 F2 一致。
- `tests/CLAUDE.md:10` 有 `test-install.sh` 那一列，事實 F19 成立。
- `grep -n -E '進度以|指路|^## ' CLAUDE.md`：根目錄 CLAUDE.md 沒有「進度以…為準」那句。
- `ls docs/designs/`：7 份，與計畫一致。
- 讀 `CLAUDE.md` 的「新增」「同批」「同步」段落（45、100、126、144、158、236、243、259、270、339 等行）。
- `grep -n -E '269|5.13|350' skills/dd-loop/SKILL.md`：第 66 行有「2026-10-24 實測…平均 269s、5.13 美元…n 小、同時改了三件事」。
- `grep -n -E '311|11\.8|27\.7' docs/measurements/2026-10-23-reviewer-real-sessions.md`：第 86 行是「code-reviewer 次數=311 中位=11.8 分 第90百分位=27.7 分」。
- `README.md` 第 38、56、70、104、156 行原文與計畫的 F16 描述相符。
- `install-dd-pipeline.sh` 889–895 行：`deprecated_dd` 清理迴圈前面沒有備份，與 F9 一致。

【批評】

輪1-R1-1｜重大｜計畫開了一張進度表，卻沒有在根目錄 CLAUDE.md 加指路句。全域 §4.4 寫明「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」。計畫的「文件同步」清單只提到根目錄 CLAUDE.md 要補「這次留下的坑」，沒有這一條。下一個 session 走 §4.1 時看不到這張表，會重估段落數、另開第二張表，前面的進度與 commit 範圍就會靜靜遺失。
證據：`CLAUDE.md` 的 `^## ` 清單（第 5 行起）沒有任何指路句，`grep -n '進度以'` 無結果；計畫「段落與小任務」與「S1 的文件同步」兩段都沒有這一項。全域 CLAUDE.md §4.4 原文就是此要求。
嚴重度依據：③。沒有任何 gate、測試或 review 會檢查這句是否存在。

輪1-R1-2｜小｜S1-4 的寫法 `backup_before_overwrite "commands"` 少了第二個參數。函式簽名是 `local category="$1" target="$2"`，而且 `[ -e "$target" ] || return 0`（install-dd-pipeline.sh:187–189）。照計畫的字面寫，`target` 是空字串，函式直接 return 0，不做備份也不報錯。現有呼叫點（第 921、957 行）都是 `"commands" "$target"`。
證據：install-dd-pipeline.sh:187–191、921。
被 T8 接住：T8 會斷言備份目錄裡有 `dd-help.md`，所以這個錯會紅。計畫應把寫法改成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`，在計畫上寫對。

輪1-R1-3｜小（可能升級）｜S2 第 6 點寫「迴圈的時間與費用…附量測日期、樣本數與檔名」，但計畫沒有說明要用哪一個數字。`docs/measurements/2026-10-23-reviewer-real-sessions.md` 第 86 行的 311、中位 11.8 分，是 code-reviewer 在 session 紀錄裡的呼叫統計，不是「一段迴圈步驟 4 要花多久」。`skills/dd-loop/SKILL.md:66` 的 269s、5.13 美元是 n 很小、同時改三件事的單次比較。如果 README 把前者寫成「迴圈每段的時間」，讀者會看到一個和問題無關的數字，而且沒有任何檢查會抓到。
證據：上述兩處 grep 輸出。
需要先讀該量測檔的表頭，確認「分」指的是什麼，才能決定要引哪一組數字（見下方外部查證）。

輪1-R1-4｜小｜進度表的狀態欄寫 `TODO`。全域 §4.4 的退化規則是「開工先把該段標 `IN_PROGRESS`」，計畫沒有寫這個步驟。
證據：計畫「進度表草稿」的狀態欄；全域 §4.4 原文。

輪1-R1-5｜小｜S2 沒說明 README.md 必須用英文寫。根目錄 CLAUDE.md 注意事項（`grep -n 'README 有英文'` 第 243 行）規定 `README.md` 是英文、`README.zh-TW.md` 是繁中，CHANGELOG 與 UPGRADING 維持純繁中。計畫的 S2-1 只寫「新寫的每一句」，又說「兩份 README 同段並排核對意思一致」，執行者可能把繁中句子直接寫進 `README.md`。
證據：`CLAUDE.md:243` 原文。

輪1-R1-6｜小｜計畫的等價探針（92 例、16 例不一致）放在 scratchpad，不在 repo 裡，也不在 `tests/`。計畫的 S1-2 驗收寫「探針 92 例不一致數從 16 變 0」，任何人都無法重跑這個數字。真正能在 repo 裡重跑的是 T2，而 T2 只覆蓋計畫列出的 16 例中的代表案例，並不是 92 例全部。
證據：計畫 S1-2 驗證段與 T2 清單；F6、F7 只存在於 scratchpad。

【需要外部查證】
- 輪1-R1-7｜小｜F5 的 debian:bullseye 結果（`cp -r` 複製出連結本身、`cp -RL` 複製出一般檔）與 F6 的 92 例探針結果，我沒有重跑（依規則不開容器、不跑探針）。計畫的 S1-1 紅綠驗證與 S1-2 的驗收數字都依賴這些結果，需由能執行的人重跑 `docker run --rm -v <repo>:/repo:ro debian:bullseye` 的 S1-1 實驗，並確認 92 例腳本仍在 scratchpad。
- 輪1-R1-8｜小｜`docs/measurements/2026-10-23-reviewer-real-sessions.md` 的表頭定義要讀過才能判斷「中位=11.8 分」指的是什麼。我只讀到第 86 行的輸出列，沒有讀定義段。這決定輪1-R1-3 的嚴重度。
- 輪1-R1-9｜小｜全域 CLAUDE.md §4.4 的退化規則與 `docs/designs/` 進度表格式（`skills/task-planner/SKILL.md`「進度表格式」一節）我只依系統提示的摘要引用，沒有讀 SKILL.md 本體，輪1-R1-1、輪1-R1-4 的引文需要對照本體再確認。
