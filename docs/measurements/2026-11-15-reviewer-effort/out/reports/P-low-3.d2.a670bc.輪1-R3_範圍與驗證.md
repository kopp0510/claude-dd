【我查了什麼】
- `ls docs/designs`：既有 7 份設計文件，與計畫一致。`wc -l tests/test-install.sh`：87 行。`ls docs/reviews`：目錄存在，`--start-segment` 在有此目錄時要求段落報告（`scripts/check-claude-md.sh:15`）。
- `skills/task-planner/SKILL.md:103-109`：建表時要在根目錄 CLAUDE.md 第一個 `##` 前加指路句；設計文件結尾要附「使用者選定的測試清單」（第 105 行、第 74 行）。
- `grep -n '進度以' CLAUDE.md`：根目錄 CLAUDE.md 沒有指路句，計畫也沒有安排加入。
- `skills/dd-loop/SKILL.md:61`：步驟 4 最少 3 個 code-reviewer，agent 定義為 opus。
- `install-dd-pipeline.sh:187-196`：`backup_before_overwrite` 用 `cp -r`，前面 `[ -e "$target" ] || return 0`。與計畫及 F4 一致。
- `install-dd-pipeline.sh:889-921`：`deprecated_dd` 清理與 `backup_before_overwrite "commands"`，與 F9 一致。
- `tests/test-install.sh:1-56`：沙盒 HOME、`--check` 不寫入、`--force` 內容相同無備份。與計畫描述一致。
- `.github/workflows/ci.yml`：ubuntu job 與 macOS job 都跑 `tests/test-install.sh`（第 557、594 行）。ci.yml 內沒有安裝 jq 或 python3 的 step。
- 全域 CLAUDE.md §5.2：「不合併多個邏輯變更為單一 commit」。
- 使用者逐字話語（事實區塊）只有「你認為現在這份repo 分數多少…」與「請你優化改善」，沒有任何選測試清單的話。

【批評】
輪1-R3-1｜重大｜計畫漏掉 task-planner 規定的根目錄指路句。開進度表時必須同時在根目錄 CLAUDE.md 第一個 `##` 前加「進度以 docs/designs/…為準」，計畫只說根目錄 CLAUDE.md 沒有這句，沒有安排加。之後的 session 不會看到進度表，會重估段落數、另開第二張表，原有進度與 commit 範圍靜默遺失。｜證據：`skills/task-planner/SKILL.md:108-109`（規定）；`grep -n '進度以' CLAUDE.md` 無結果；計畫「S1 的文件同步」清單沒有這一項。

輪1-R3-2｜小（規則缺漏，但不靜默）｜計畫完全沒有排進 §3.9 的步驟 3–8。沒有段落起點（`--start-segment`）、沒有 code-simplifier、沒有 ≥3 個 code-reviewer 與 `docs/reviews/` 報告落地、沒有再測與第二次 commit 的時程。`docs/reviews/` 目錄存在，gate 會擋沒有報告的段落，所以這不會靜默通過，但照計畫做會卡在步驟 6 之前。｜證據：`ls docs/reviews`（有目錄）；`scripts/check-claude-md.sh:13-15`；`skills/dd-loop/SKILL.md:61`；計畫的進度表與段落區塊都沒有提到這些步驟。

輪1-R3-3｜小（使用者決定相關，需使用者確認）｜T3–T9 是為「未出錯的路徑補測試」，不是修 bug，屬於 §3.5「不主動新增測試」的例外之外。計畫說「task-planner 步驟 4 的測試清單題選定的清單就是使用者要求加的測試」，但事實區塊裡使用者的逐字話語沒有任何選測試清單的內容，這個說法沒有依據。task-planner 也要求設計文件結尾附「使用者選定的測試清單」。｜證據：`skills/task-planner/SKILL.md:74、105`；事實區塊「使用者講過的話」兩則，無測試清單；全域 CLAUDE.md §3.5。

輪1-R3-4｜小｜S1-4 把兩個互不相關的修正（清舊指令前備份、完成訊息只報真的跑過的）放進同一個 commit，違反全域 §5.2 的「不合併多個邏輯變更為單一 commit」。S1-2 同樣把五個函式的修正併進一個 commit。｜證據：全域 CLAUDE.md §5.2（`~/.claude/CLAUDE.md` 內容）；計畫 S1-4 與 S1-2 的 commit 行。

輪1-R3-5｜小｜T1 在本機 macOS 修之前就是綠的（計畫自己承認），因此 CI 的 macOS job 上 T1 不會抓到這個缺陷，等於只有 ubuntu job 會紅。計畫的驗收只寫「本機 ci.yml 20 個 step 全過」，本機是 macOS，於是 ubuntu 上的紅綠要靠另外的 docker 步驟，沒有納入 CI 驗收。｜證據：計畫 S1-1 驗證段；F5（本機 `cp -r` 複製成一般檔）；`.github/workflows/ci.yml:12`（ubuntu job）。

輪1-R3-6｜小｜T2 的等價斷言在兩條路徑錯得一樣時會空通過。計畫只對三類各挑代表案例直接斷言結論，其餘 92 例只比兩條路徑是否一致。例如兩條路徑都把空檔當成「已啟用」，斷言仍會綠。計畫雖有代表案例，但代表案例的選法沒有寫明是哪幾例。｜證據：計畫 T2 段；計畫 S1-2 驗證段「另外對上面三類各挑代表案例斷言結論本身」。

【需要外部查證】
輪1-R3-7｜中｜T2 依賴 ubuntu-latest 與 macOS runner 上 jq 與 python3 的有無來決定測哪一條路徑。計畫用重新定義 `command_exists` 來強制走 python3 路徑，理由是 runner 上兩者都有。這需要確認 GitHub 的 ubuntu-latest 與 macos-latest 映像檔預裝的 jq、python3 版本。我沒有上網查，也沒有在 ci.yml 找到安裝步驟。
輪1-R3-8｜中｜S2 的 README 會寫「CI 跑在 ubuntu-latest、macos-latest 的 bash 3.2」，要確認 macos-latest 目前是否仍附 `/bin/bash` 3.2（計畫 S2-1 第 7 點依賴它）。這需要查 GitHub runner 映像檔文件。
