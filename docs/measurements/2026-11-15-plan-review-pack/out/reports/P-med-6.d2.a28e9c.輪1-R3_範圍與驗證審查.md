【我查了什麼】
- 讀完審查包 `P-med-6.pack.md` 全部 166 行（分 1 次 300 行讀取）。
- `git log --oneline -3`：HEAD 為 `84d0f2a base`，工作目錄乾淨。
- `grep -n -E 'BASH_SOURCE|^(jq_inplace|py_inplace|...)\(\)' install-dd-pipeline.sh`：函式位置與計畫吻合。
- `sed -n '156,160p;187,250p' install-dd-pipeline.sh`：`command_exists` 是 `command -v` 包裝；`backup_before_overwrite` 第 194 行是 `cp -r`，前面有 `[ -e "$target" ] || return 0`；`jq_inplace` / `py_inplace` 的檔頭註解與計畫一致。
- `sed -n '397,440p;630,700p;730,760p;790,830p'`：`plugin_enabled_state`、`mcp_scope`、`install_plugins` 的分支結構與計畫描述一致。
- `grep -n -E 'set -[eu]|pipefail' install-dd-pipeline.sh`：只有 `set -e`，沒有 `set -u`，沒有 pipefail。
- `sed -n '1241,1262p'`、`sed -n '879,890p'`：`show_completion` 無條件印 Agents 與 Plugin 兩段；`create_commands` 開頭的 `deprecated_dd` 迴圈前面沒有備份。
- `sed -n '171,186p;1180,1240p'`：`ask()` 非 TTY 時採預設值；全域 CLAUDE.md 的預設是 `k`（保留本地版）。計畫 T6 的「非互動保留本機版」與此吻合。
- `wc -l tests/test-install.sh`：87 行。
- `grep -c '^ *- name:'`（對應 ci.yml 第 12–558 行）：ubuntu lint job 有 20 個 step。macOS job 在第 564 行起（`/bin/bash tests/test-install.sh` 在第 594 行）。
- `grep -n -E '進度|指路|TodoWrite|TaskCreate' CLAUDE.md`：根目錄 CLAUDE.md 沒有指路句，計畫也沒有安排加入。
- `ls docs/designs/`：目前有 7 份既有設計文件，與計畫一致。
- `sed -n '1,25p;80,95p' docs/measurements/2026-10-23-reviewer-real-sessions.md`：數字是 code-reviewer subagent 的個別耗時，樣本約 30 天，排除 `-SRE` 專案，檔頭說明早期方法曾算錯。
- `sed -n '60,70p' skills/dd-loop/SKILL.md`（經 grep 確認）：269s / 5.13 美元 / 命中 4/6 是「直接派 vs 裁決者」的 n=6 實驗，不是三個審查者的成本。
- `grep -n 'Traditional Chinese' README.md`：第 19 行有該句，計畫的行號引用成立。
- `grep -n 'don.t install the gate|--force  |--uninstall  ' README.md`：第 67、70、156 行與計畫一致。
- `scripts/CLAUDE.md` 第 185–188 行：bash 3.2 相容只由 CI macOS job 的行為測試驗證。

【批評】
- 輪1-R3-1｜重大｜計畫建立進度表（`docs/designs/2026-11-14-installer-hardening-design.md`），但沒有安排全域 §4.4 規定的「開表時在根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」。S1 的文件同步只寫「根目錄 CLAUDE.md…只補這次留下的坑」，沒有指路句。之後的 session 讀不到這張表，會重估段落數並另開第二張表，先前的進度與 commit 範圍會遺失。這類遺失不會被任何 gate 或測試抓到。｜證據：審查包第 6 行承認「沒有『進度以…為準』那句」；第 52–57 行的 S1 文件同步清單沒有指路句；`grep -n -E '進度|指路' CLAUDE.md` 沒有命中；全域 CLAUDE.md §4.4 要求「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」。
- 輪1-R3-2｜重大｜S2-1 第 6 項要 README 寫「步驟 4 每段至少 3 個 opus 審查者」的時間與費用，但計畫引用的數字對不上這個說法。`docs/measurements/2026-10-23-reviewer-real-sessions.md:86` 的「code-reviewer 次數=311 中位=11.8 分」是單一 subagent 的耗時，樣本約 30 天、排除公司專案，不是「每段」或「三個平行審查者」的 wall time。`skills/dd-loop/SKILL.md:66` 的 5.13 美元 / 3.83 美元是 n=6 的「直接派 vs 裁決者」實驗，也不是三個審查者的成本。計畫的驗證是「逐句核對表：新寫的每一句對得上它引的量測檔」，只檢查字串存在，不檢查範圍是否相符，所以這個錯會通過核對。CI 的「數字宣稱一致性」只驗 skill / agent / command 數量，不驗文案中的時間與費用，後面的關卡也抓不到。｜證據：上面兩檔的行號；`docs/measurements/2026-10-23-reviewer-real-sessions.md:13` 的警語表示早期方法曾算錯，計畫沒有提。
- 輪1-R3-3｜一般｜S1-1 的 T1 在本機 macOS 修之前就是綠的（計畫第 24 行自己承認）。紅與綠只在一次性的 docker 探針裡取得，不是在 `tests/test-install.sh` 的 T1 上取得。違反 §3.5「新測試先寫失敗案例，確認會失敗」。另外 debian 映像檔沒有 jq / python3（計畫第 163 行），`tests/test-install.sh` 在那個容器裡跑不起來；計畫又沒有執行 ci.yml 的 ubuntu job（A6 不 push，F15 指出 ubuntu job 沒跑過這 34 個 commit）。所以真正的測試套件在 GNU 環境上，只會在使用者 push 之後的 CI 才第一次跑到。｜證據：審查包第 23–24、130、147、163 行；ci.yml 第 556–557 行。
- 輪1-R3-4｜一般｜驗證清單寫「本機 ci.yml 20 個 step 全過」，但這 20 個 step 只對應 ubuntu lint job（ci.yml 第 12–558 行）。macOS bash 3.2 job（ci.yml 第 564–594 行，含 `/bin/bash tests/test-install.sh`）沒有列入驗證。S1-2 與 S1-4 會新增 bash 程式碼路徑（陣列記錄、`jq -e` 檢查、python 分支），而 `scripts/CLAUDE.md:185–188` 說 3.2 相容只由那個 job 的行為測試驗證。｜證據：`grep -n '^ *- name:'` 的輸出與上列行號；`scripts/CLAUDE.md` 第 185–188 行。
- 輪1-R3-5｜一般｜T2 的紅燈判準是「確認在現行程式碼上紅在那 16 例」，沒有要求紅的是斷言失敗而不是載入失敗或 `command_exists` 覆寫出錯。計畫在 T3–T7 有寫「紅在斷言而不是載入失敗」，T2、T8、T9 沒有寫。§3.5 要求「紅要讀紅的內容」。｜證據：審查包第 34、49、93 行；第 41 行只對 T3–T7 有這條。
- 輪1-R3-6｜一般｜S1-3 的 mutation 驗證只寫「把安裝腳本對應的那一行改壞」，沒有指定 T3–T7 各自要改哪一行、改成什麼。計畫沒辦法證明每組測試都有鑑別力，也沒辦法重現。｜證據：審查包第 41 行。
- 輪1-R3-7｜一般｜S1-2 對 `null`、空檔、`[null]` 等 16 類輸入直接定了行為（例如 `enabledPlugins: null` 在安裝時照常寫入、移除時不報錯），這是設計取捨，計畫沒有列為「需使用者決定」，也沒有回問。§6.1 要求涉及設計取捨時回問。｜證據：審查包第 29–33 行；§6.1（全域 CLAUDE.md）。

【需要外部查證】
- 輪1-R3-8｜一般｜`jq -e 'type == "object"'` 在空輸入時回 exit 4（計畫第 33 行）。這個退出碼需要對照 jq 官方文件或在 macOS 的 jq 版本上實測確認。為什麼需要：`jq_inplace` 與 `set -e` 的互動依賴這個值，本次只能靠文字判斷。
- 輪1-R3-9｜一般｜GNU `cp -RL` 對懸空 symlink 回 1（F5 有實測），但計畫 S1-1 的做法是 `[ -L ]` 分支，而 `backup_before_overwrite` 開頭的 `[ -e ]` 會先擋掉懸空 symlink，所以 `-L` 分支實際上不會碰到懸空連結。需要在 GNU 上實測確認，計畫沒有列出這個路徑的測試。
