【我查了什麼】

- 讀過的檔：根目錄 `CLAUDE.md`（前 5 行、`## 新增 …` 各段、`## 核心工作法`、「CI 不驗、只能手動同步的區塊」段）、`tests/CLAUDE.md`、`scripts/CLAUDE.md`、`docs/reviews/CLAUDE.md`、`skills/dd-loop/SKILL.md`、`skills/task-planner/SKILL.md`、`DD_PIPELINE_ARCHITECTURE.md`（安裝行為保證、CI 防線表）、`README.md`（章節標題與安裝段）。
- 找到的各層 CLAUDE.md（gate 的要求範圍）：根目錄、`diagrams/src`、`docs/measurements/*`、`docs/reviews`、`scripts`、`skills/*/hooks`、`skills/security-audit`、`skills/tech-diagram-gif/scripts`、`templates/global`、`tests`。`docs/` 本身沒有 CLAUDE.md，`docs/designs/` 有 7 份既有設計文件（與計畫一致）。
- 跑過的指令：
  - `grep -rn -E '新增|同時改|同批|要一起|同步|手動同步' --include=CLAUDE.md .`
  - `grep -n -E '新增|同時改|同批|要一起|同步' DD_PIPELINE_ARCHITECTURE.md README.md README.zh-TW.md UPGRADING.md`
  - `grep -rn -E '進度以|指路' …`（對 `.md` 檔）— 沒有任何結果，根目錄 CLAUDE.md 確實沒有指路句
  - `grep -n '^## ' CLAUDE.md`：第一個 `##` 在第 5 行
  - `grep -n -E '^(backup_before_overwrite|jq_inplace|py_inplace|install_plugins|uninstall|mcp_scope|jq_register|py_register|show_completion|create_commands|validate_skill_hooks)\('`：函式都存在（187、209、228、730、1059、630、879、1241、463），`deprecated_dd` 在 889 行
  - `ls docs/reviews`、`ls docs/designs`、`ls docs/measurements`：計畫引的 `2026-10-23-reviewer-real-sessions.md` 存在
  - `grep -n 'test-install' .github/workflows/ci.yml DD_PIPELINE_ARCHITECTURE.md`：`DD_PIPELINE_ARCHITECTURE.md:137` 有 test-install 那一列
- 計畫前提的核對：F18（DD_PIPELINE_ARCHITECTURE.md:72-74 的兩句）與 F16（README 的 `--uninstall` 與 `--force`）與實際文字一致。

【批評】

輪1-R2-1｜重大｜進度表開好後不會在根目錄 CLAUDE.md 加指路句，計畫也沒列這件事。下一個 session 不會看到這張表，會重新估段落、另開第二張表，前面的進度與 commit 範圍就遺失。這條規則是 §4.4 明文要求的，沒有任何 gate 或測試檢查它。計畫開頭自己寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，但 S1、S2 的小任務、文件同步與驗證裡都沒有加它。｜證據：全域 CLAUDE.md §4.4 規定「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」；`skills/task-planner/SKILL.md:109` 給了句型「進度以 docs/designs/<檔名>.md 的「進度表」為準：開工先讀表，照表下方的規則做。」；`grep -rn -E '進度以|指路' --include=*.md .` 無結果；根目錄 CLAUDE.md 第 5 行即第一個 `## 安裝 / 更新`。

輪1-R2-2｜一般｜計畫完全沒提 `docs/reviews/` 留痕慣例。這個目錄存在就是開關，`--start-segment` 會要求上一段的 commit 範圍內有新增 `docs/reviews/S*.md`。計畫的 S1 與 S2 都沒有步驟 4 的報告檔、沒有 `-SKIP.md`，也沒寫新表的報告要放子目錄。`docs/reviews/CLAUDE.md` 規定新表的報告放 `docs/reviews/<進度表檔名去掉 -design.md>/`，計畫的設計文件會叫 `2026-11-14-installer-hardening-design.md`，所以子目錄應該是 `docs/reviews/2026-11-14-installer-hardening/`。gate 會擋（exit 1），所以不是靜默失敗，定為一般。｜證據：`docs/reviews/CLAUDE.md` 第 1–3 行與「段落 ID 跨進度表會重複」段；`skills/dd-loop/SKILL.md:14-17`（gate 條件與 SKIP 出路）、`:81-93`（報告一律落地、`-a/-b/-c/-judge.md` 命名）。

輪1-R2-3｜一般｜計畫的段落收尾順序沒有排進 §3.9 的步驟 3、4、5、8。S1 寫的是 S1-1 到 S1-4 各自 commit 加一組「文件同步」commit，段落最後的 code-simplifier、code-review、再測、評分與修正 CLAUDE.md（步驟 8）都沒有。計畫的 S1 會改根目錄 CLAUDE.md 與 `tests/CLAUDE.md`，這兩份依 §3.9 步驟 8 都要用 `claude-md-improver` 審。｜證據：全域 CLAUDE.md §3.9 第 3、4、5、8 步；計畫 S1 的「文件同步」段只列要改的檔，沒有任何步驟 3 以後的項目。

輪1-R2-4｜一般｜S2 改的 README 段落裡，有幾段在根目錄 CLAUDE.md「CI 不驗、只能手動同步的區塊」清單中，計畫沒有對照這份清單。清單寫明要手動同步的包括「安裝步驟清單」與「前置需求段落」，還有「核心工作法的迴圈說明段」與「授權段」。S2 的第 2、3 項改的是安裝步驟的行為描述（README 安裝段），第 6 項加迴圈成本，計畫沒有寫要巡這份清單。｜證據：根目錄 CLAUDE.md「CI 不驗、只能手動同步的區塊」段（約第 273 行起）；`README.md:40`（First-time install）與 `README.md:56-58`（安裝步驟，寫了「Diff the global CLAUDE.md」）；`README.md:87`（核心工作法）。

輪1-R2-5｜一般｜英文 README 會連到 `CHANGELOG.md` 或量測檔時，要標註 *(Traditional Chinese)*。計畫 S2 第 6 項寫「附量測日期、樣本數與檔名」，若連結 `docs/measurements/…` 或 `CHANGELOG.md`，英文 README 就要照這條標註。計畫沒有提。｜證據：根目錄 CLAUDE.md「注意事項」中「README 有英文與繁中兩份」那一條的第二句「CHANGELOG.md 與 UPGRADING.md 維持純繁中，英文 README 連向它們時須標註 *(Traditional Chinese)*」。

【需要外部查證】

輪1-R2-6｜一般｜S2 開始時 `--start-segment` 會看 S1 的起點到 HEAD 之間有沒有新增 `docs/reviews/…/S1*.md` 或 SKIP 檔。計畫沒說 S1 的起點怎麼定（新表的第一段，起點是哪個 commit），也沒說 S1 的報告放哪個路徑。這要實跑 `scripts/check-claude-md.sh --start-segment` 才能確認會不會誤擋。｜為什麼需要：我只能讀檔，無法確認 gate 在這個 repo 的實際判定結果。
