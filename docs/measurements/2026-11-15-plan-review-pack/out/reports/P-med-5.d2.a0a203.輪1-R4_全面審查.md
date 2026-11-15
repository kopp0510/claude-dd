【我查了什麼】
- `CLAUDE.md`：`grep -n '進度以' CLAUDE.md` 無結果；第一個 `##` 在第 5 行。
- `docs/designs/` 現有 7 份設計文件（與計畫「7 份」相符）。
- `install-dd-pipeline.sh`：`backup_before_overwrite` 在 187–195 行，為 `cp -r "$target" "$BACKUP_ROOT/$category/"`，無 `-L`。`ask` 在 175 行以 `[ -t 0 ]` 判斷。`install_builtin_agents` 在 580–606 行，覆蓋前會呼叫 `backup_before_overwrite "agents"`（604 行），與計畫 T5 的假設相符。`deprecated_dd` 在 889 行，前面沒有備份。`show_completion` 的兩段字串在 1251、1254 行，`main` 以 `COMMANDS_ONLY` 分支（1268、1368、1386、1392 行）。`uninstall()` 內只處理 `settings.json`、`installed_plugins.json` 與 `OFFICIAL_PLUGINS`，沒有提到 `CLAUDE.md` 或 `backups`，與 F11 相符。`jq_inplace`、`py_inplace`、`plugin_enabled_state`、`mcp_scope` 分別在 209、228、397、630 行。
- `tests/test-install.sh`：87 行，`SANDBOX` 於第 30 行建立，大多數斷言已存在。`tests/CLAUDE.md` 第 10 行是 `test-install.sh` 那一列。
- `.github/workflows/ci.yml`：`test-install.sh` 在 Ubuntu 與 macOS（`/bin/bash`）兩個 job 都會跑（557、594 行）。
- `agents/code-reviewer.md` 的 `model: opus`（第 4 行）。`skills/dd-loop/SKILL.md` 第 61 行與全域模板第 251 行都是「最少 3 個」。
- `README.md` 第 70–71 行的 `--uninstall` 文字與計畫引用一致。
- `skills/self-improving-agent/hooks/hooks.json` 掛的是 PostToolUse、Bash 那一支 `error-capture.sh`。該目錄有 `.claude-plugin`。
- `CHANGELOG.md` 第 19 行有 `## 未發布`。
- 本機 `grep` 的 `--include` 在 zsh 下報錯，沒有影響上述結果。

【批評】
- 輪1-R4-1｜重大｜計畫在 `docs/designs/` 開進度表，卻沒有在根目錄 `CLAUDE.md` 第一個 `##` 之前加指路句（「進度以 docs/designs/…md 的「進度表」為準…」）。全域 §4.4 明文要求開表時同批加這句。計畫自己也寫了「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，卻沒有把補它放進 S1 或 S2 的文件同步。下一個 session 依 §4.1 會重新估段落數、另開第二張表，原本的段落起點與 commit 範圍就靜靜遺失。這一項每個 session 都會走到、沒有報錯，後面的 code-review 與 gate 也不會檢查它。證據：`CLAUDE.md:5` 是第一個 `##`，`grep -n '進度以' CLAUDE.md` 無結果；全域 §4.4 的「開表的同時…加一段指路」。
- 輪1-R4-2｜小｜全域 §3.9 要求「段落開始前先記起點」（`check-claude-md.sh --start-segment`），計畫沒有任何一步做這件事，進度表的 commits 欄也沒有起點來源。證據：全域 CLAUDE.md §3.9 的「段落開始前先記起點」段落；計畫進度表 `commits` 欄留空。若沒記，`--segment-base` 會非 0 結束，屬於響亮失敗，所以只列為小問題。
- 輪1-R4-3｜中｜S1-2 的定案規則（「頂層不是物件 → 兩條路徑都算失敗」）與假設 A4（`plugin_enabled_state` 頂層不是物件維持 `none`）互相矛盾。T2 又把 `plugin_enabled_state` 納入等價比對，但沒有寫它的預期結論，因此「對 `plugin_enabled_state` 的 null／陣列頂層應該得到什麼」無法判定。證據：計畫 S1-2 定案段落與 A4；`install-dd-pipeline.sh:397` 的 `plugin_enabled_state()`。
- 輪1-R4-4｜中｜使用者先前講定「精煉規則文件要逐條判必要性、分三類交他選」。計畫以它來排除弱項 3（A1），卻沒有對自己新增的文字套用同一規則。S1「文件同步」要在根目錄 `CLAUDE.md` 補字、S2 要在兩份 README 新增八項、`DD_PIPELINE_ARCHITECTURE.md` 與 CHANGELOG 也要增加內容，全部沒有逐條判必要性的步驟。這是使用者的決定被跳過，但不屬於「錯了沒人抓到」，所以列為中。證據：計畫 A1 的文字；事實段「使用者先前在這個 repo 講定的事」。
- 輪1-R4-5｜小｜驗收只涵蓋本機 macOS 與 debian 容器。計畫 S1 的驗收是「本機 ci.yml 20 個 step 全過」，但事實 F15 說 34 個未推的 commit 從未在 ubuntu job 跑過。計畫沒有寫出 push 後要看哪一個 CI job，也沒寫 T2 在 ubuntu-latest 上 `jq` 是否存在。使用者自己決定 push，所以 CI 結果要等他推之後才會出現，計畫應寫明這一點。證據：事實段 F15；計畫 S1 驗收段。

【需要外部查證】
- 輪1-R4-6｜中｜T3–T9 不是 bug 修復測試，依全域 §3.5 只有「使用者要求」時才能加。計畫說這份清單就是 task-planner 步驟 4「測試清單題」使用者選定的清單，但這個選擇紀錄不在 repo 內，我無法驗證。需要使用者或 task-planner 的題目紀錄，確認 T1–T9 是否全部被選中；若只選了部分，其餘就違反 §3.5。
- 輪1-R4-7｜小｜`ubuntu-latest` runner 是否預裝 `jq`，以及 T2 的 python3 替身（重新定義 `command_exists`）在 Linux 上是否與 macOS 行為一致。這影響 S1-2 的紅綠判定能否在 CI 上重現。需要 push 後看 CI 或查 GitHub runner 映像檔清單，我沒有上網查。
