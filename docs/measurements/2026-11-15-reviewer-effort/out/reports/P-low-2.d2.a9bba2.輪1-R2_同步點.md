【我查了什麼】
- 讀 `CLAUDE.md`（根目錄）、`DD_PIPELINE_ARCHITECTURE.md`、`tests/CLAUDE.md`、`scripts/CLAUDE.md`、`README.md`、`README.zh-TW.md`、`install-dd-pipeline.sh` 的 `backup_before_overwrite` 與 `jq_inplace`/`py_inplace` 段、`tests/test-install.sh` 檔頭、`.github/workflows/ci.yml` 的 macOS job。`docs/` 底下沒有 CLAUDE.md（`ls` 回 No such file）。
- `grep -n '進度以' CLAUDE.md`：無結果（rc=1），與計畫一致。
- `grep -n '^## ' CLAUDE.md`：第一個 `##` 在第 5 行（`## 安裝 / 更新`）。
- `grep -n -E '同批|同時改|要一起|手動同步|CI 不驗' CLAUDE.md tests/CLAUDE.md scripts/CLAUDE.md DD_PIPELINE_ARCHITECTURE.md`：命中的規則是 `CLAUDE.md:48,104,132,151,162,243,273,401`、`DD_PIPELINE_ARCHITECTURE.md:103,153`、`tests/CLAUDE.md:11`。其中與本計畫相關的是 README 兩份同批、CHANGELOG `## 未發布`（`CHANGELOG.md:19`）、CI 防線表、`tests/CLAUDE.md` 的 test-install 列（第 10 行）。計畫都有列到，沒有漏的檔。
- `docs/designs/` 有 7 份既有設計文件，與計畫一致。`docs/designs/2026-11-14-loop-tuning-design.md:32` 的 `## 進度表` 是先例。
- `grep -n -E '指路|進度以|IN_PROGRESS' docs/designs/*.md`：先例的進度表都有「狀態」規則區塊（如 `docs/designs/2026-10-23-裁決審查-design.md:22-27`），並規定開工時記起點、標 DONE 時刪根目錄指路段。
- `skills/task-planner/SKILL.md` 存在（我沒讀本文）。
- `.github/workflows/ci.yml`：`lint` job 的 ubuntu 步驟在第 10–~550 行；macOS job 在 `:564`，`/bin/bash` 3.2 的 `tests/test-install.sh` 執行在 `:594`。
- `grep -n -E '已啟用|已安裝的內建' .github/workflows/ci.yml tests/*.sh`：無結果，所以 S1-4 改完成訊息不會踩到 CI 字串比對。
- `grep -n -E 'test-install' DD_PIPELINE_ARCHITECTURE.md tests/CLAUDE.md`：CI 防線表與 tests/CLAUDE.md 的列都存在，計畫有列。
- `CHANGELOG.md:19` 有 `## 未發布`，計畫可直接寫入。

【批評】
輪1-R2-1｜重大｜計畫沒有在根目錄 CLAUDE.md 加「進度以 docs/designs/…為準」的指路段，但新建了進度表。全域 §4.4 明文要求「開表的同時」在第一個 `##` 前加指路，且先例都有。少了這段，下一個 session 看不到表，會重估段落數、另開第二張表，前面的進度與 commit 範圍就遺失。S1 的文件同步清單也沒提到這段。
證據：`CLAUDE.md:5`（第一個 `##`）前沒有指路；`grep -n '進度以' CLAUDE.md` 無結果；`~/.claude/CLAUDE.md` §4.4 第 2 段規定「開表的同時…加一段指路」；先例 `docs/designs/2026-10-23-裁決審查-design.md:27` 規定標 DONE 時要刪它。
嚴重度依據：③。沒有任何 gate 或測試會檢查指路段是否存在，後面的關卡也抓不到。

輪1-R2-2｜重大｜計畫的進度表沒有「狀態規則」區塊，也沒有「開工時記起點」的機制。commits 欄只寫了空值，沒有寫 `<起點>..`，也沒有說明要用 `check-claude-md.sh --start-segment` 記起點。步驟 3、4、8 的範圍是從表上這個起點算的（§3.9 第 2 段、先例 `docs/designs/2026-10-23-裁決審查-design.md:24`）。起點沒記，範圍就會被算錯。例如 S2 的 step 8 會只審最後一個 commit 的 CLAUDE.md，而不是整段。步驟 8 的 CLAUDE.md 範圍會靜默縮小，沒有任何檢查會抓到。
證據：`docs/designs/2026-10-23-裁決審查-design.md:22-27` 是規則區塊的完整寫法；計畫草稿的進度表（ID、段落、狀態、依賴、驗收、commits）沒有起點欄，也沒有規則段。
嚴重度依據：③。範圍錯了不會報錯，後面的 code-review 與 gate 也不會去比對起點是否正確。

輪1-R2-3｜一般｜計畫沒有依 §4.1 呼叫 `task-planner`。計畫有兩個功能段落（N=2），§4.1 規定 N≥2 就要呼叫 `task-planner`，使用者沒提「拆任務」也一樣。計畫自己寫了「進度表草稿」，跳過了 skill 的產出。
證據：`~/.claude/CLAUDE.md` §4.1「N ≥ 2 就呼叫 `task-planner`」；`skills/task-planner/SKILL.md` 存在（本輪未讀）。
嚴重度依據：只符合①②，不符合③（錯了會被 plan-review 與開工前的檢查看到），因此列為一般。

輪1-R2-4｜小事｜S1 的驗證寫「本機 ci.yml 20 個 step 全過」，但這 20 個是 lint job（ubuntu）的 step。macOS job（`ci.yml:564-594`）的 `/bin/bash` 3.2 執行 `tests/test-install.sh` 不在這 20 個裡。T2 會新寫 jq/python 等價表，若用到 bash 4 語法，只會在 macOS job 紅，而 push 之後才看得到。
證據：`.github/workflows/ci.yml:594`（`run: /bin/bash tests/test-install.sh`）；計畫的驗證只寫 20 個 step。
嚴重度依據：會被 CI 抓到（紅燈可見），不是靜默錯，因此只列為小事。

【需要外部查證】
- 無。上面的批評都能用本地檔案與 grep 核對，沒有需要上網或跑指令才能確認的項目。
