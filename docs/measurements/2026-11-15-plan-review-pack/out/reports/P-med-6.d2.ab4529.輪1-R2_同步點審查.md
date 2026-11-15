【我查了什麼】
- 讀完審查包 `P-med-6.pack.md` 全部 166 行（分兩段讀，最後一行為 `<<<審查包結束>>>`）。
- 計畫的目錄結構：`find . -name CLAUDE.md -not -path './.git/*'`，共 20 份，含根目錄、`tests/`、`scripts/`、`docs/reviews/`、`docs/measurements/*`、`skills/*` 等。
- 同步規則掃描：`grep -rn -E '新增|同時改|同批|要一起|同步|手動同步' --include=CLAUDE.md .`。與計畫直接相關的條目是根目錄 CLAUDE.md 的「新增 Script／Output Style／Command 步驟」與「README 內容須同批更新」、`tests/CLAUDE.md` 的 `test-install.sh` 那一列、`scripts/CLAUDE.md` 的 gate 條目。
- 進度指路句：`grep -c '進度以' CLAUDE.md` 回 `0`；根目錄 CLAUDE.md 第一個 `##` 在第 5 行（`## 安裝 / 更新`）。
- 既有設計文件：`ls docs/designs | wc -l` 回 `7`。
- 步驟 4 報告慣例：`ls docs/reviews` 有 `CLAUDE.md`、`S6-a.md`、`S6-b.md` 與多個日期子目錄；`docs/reviews/CLAUDE.md` 第 1–11 行寫「目錄存在即為 opt-in」與「新進度表的報告放子目錄」。
- gate 規則：`scripts/check-claude-md.sh` 第 180 行 `[ -d docs/reviews ] || return 1`，第 204–205 行的 `--diff-filter=A` 加 `(^|/)S[0-9][^/]*\.md$`。
- 安裝腳本錨點：`grep -n` 得到 `backup_before_overwrite`（187 行）、`jq_inplace`（209）、`py_inplace`（228）、`install_plugins`（730）、`create_commands` 內的 `deprecated_dd`（889）、`show_completion` 的「已安裝的內建 Agents」與「已啟用的 Plugin」（1251、1254）、`--commands-only` 判斷（880、1268、1368、1386、1392）。
- 文件是否提到完成訊息的 plugin 段：`grep -n -E '已啟用的 Plugin|已安裝的內建 Agents' README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md` 無結果。
- 測試 header：`sed -n '1,12p' tests/test-install.sh`，第 2–3 行列出測試涵蓋範圍。
- `DD_PIPELINE_ARCHITECTURE.md` 第 66–74 行的「行為保證」：冪等、JSON 就地改寫、可回復三條。

【批評】
- 輪1-R2-1｜重大｜開進度表時，計畫沒有加根目錄 CLAUDE.md 的「進度以 docs/designs/…md 的進度表為準」指路句，也沒有 S1/S2 做完後更新表格狀態與 commits 欄的步驟。下一個 session 讀 CLAUDE.md 看不到這張表，會重新估段落數、另開第二張，先前進度與 commit 範圍靜默遺失，沒有任何 gate 或測試會報錯。證據：`CLAUDE.md` 第 5 行起第一個 `##`，`grep -c '進度以' CLAUDE.md` 回 `0`；計畫事實段第 6 行明寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，S1 文件同步的根目錄 CLAUDE.md 條目也只寫「只補這次留下的坑」。使用者的全域 §4.4 規定「開表的同時，在根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，計畫沒有照做。
- 輪1-R2-2｜中｜計畫沒有安排步驟 4 的 review 報告，也沒有說報告放哪裡。`docs/reviews/` 存在，所以 gate 是 opt-in，`--start-segment` 在開下一段時會要求上一段 commit 範圍內有新增 `docs/reviews/S*.md`。gate 會擋住，所以不是靜默錯誤，但計畫的 commit 清單與驗證步驟都漏了這一項。證據：`ls docs/reviews` 與 `docs/reviews/CLAUDE.md` 第 1–11 行，`scripts/check-claude-md.sh` 第 180 行與第 205 行。另外 `docs/reviews/CLAUDE.md` 第 9–11 行規定「新進度表的報告放子目錄」（如 `docs/reviews/<設計日期-主題>/`），計畫的設計文件名是 `2026-11-14-installer-hardening-design.md`，但計畫沒寫報告子目錄。
- 輪1-R2-3｜中｜進度表的狀態欄只有 `TODO`，沒有 `IN_PROGRESS` 規則，commits 欄也沒有寫入時機。全域 §4.4 要求「開工先標 IN_PROGRESS，步驟 3–8 跑完才改 DONE 並補 commit 範圍」，計畫沒有對應的步驟。這不會被任何檢查擋住，中斷時表格與實際狀態會不一致。證據：計畫第 10–13 行的進度表；使用者的全域 §4.4「task-planner 退化成檔案式追蹤」段落。

【需要外部查證】
- 無。上面三條都能用本機 `grep` 與讀檔確認，不需要上網或跑測試。
