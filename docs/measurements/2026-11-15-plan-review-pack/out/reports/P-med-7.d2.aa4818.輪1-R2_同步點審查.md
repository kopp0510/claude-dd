【我查了什麼】
- 讀完審查包 166 行（`P-med-7.pack.md`，offset 0、limit 300 一次讀完）。
- `grep -n '進度以' CLAUDE.md`：rc=1，根目錄 CLAUDE.md 沒有指路句。`sed -n 1,12p CLAUDE.md` 確認第一個 `##` 在第 5 行之前沒有指路。
- `ls docs/designs/`：7 份既有設計文件。逐份 `grep -n -E 'IN_PROGRESS|TODO|DONE|進度表'`：各份進度表都是 DONE，沒有進行中的表（與計畫事實第 6 行相符）。
- `grep -n -E '同批|同時改|要一起|手動同步|同步' CLAUDE.md`、`grep -rn -E '新增|同時改|同批|要一起|手動同步' --include=CLAUDE.md .`：逐條對到計畫的範圍。與計畫相關的規則是：新增 Script、Output Style、Skill 的陣列同步；README 兩份同批；CI 不驗的手動區塊（前置需求、MCP 表、指令一覽）；`dd-loop-rev` 跳號（計畫 A6 不動蓋章區塊，此條不適用）。
- `CODE_EXT` 在 `scripts/check-claude-md.sh:39`，不含 `.md`，所以新增 `docs/designs/*.md` 不會觸發 gate 要求 CLAUDE.md。`docs/` 底下沒有 CLAUDE.md（`docs/reviews/`、`docs/measurements/*` 才有）。
- `grep -n -E 'backups|備份' README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md CLAUDE.md scripts/CLAUDE.md`：`DD_PIPELINE_ARCHITECTURE.md:54-56` 寫「全域 CLAUDE.md 是例外」，與計畫 README 第 2 點不衝突，所以不列為缺漏。
- `grep -n -E 'test-install' DD_PIPELINE_ARCHITECTURE.md CLAUDE.md tests/CLAUDE.md README.md`：`tests/CLAUDE.md:10` 與 `DD_PIPELINE_ARCHITECTURE.md:137` 是計畫要補的兩處，計畫有列。
- `grep -n '^## 未發布' CHANGELOG.md`：第 19 行存在。
- `grep -n -i -E 'translat|翻譯|don.t install the gate' README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md CLAUDE.md`：README.md:19、README.zh-TW.md:20 有「翻譯全域模板」句，DD_PIPELINE_ARCHITECTURE.md 沒有。
- `install-dd-pipeline.sh:43,115,281,1259` 與 `hooks.json` 位置：self-improving-agent 有 `.claude-plugin/plugin.json` 與 `hooks/hooks.json`，安裝腳本只登記 `OFFICIAL_PLUGINS`。
- `README.md:38` 與 `README.zh-TW.md:39`：前置需求段已有 skill-creator 的安裝指令，沒有 claude-md-management 的對應指令（計畫第 8 點的前提成立）。

【批評】
輪1-R2-1｜重大｜計畫開出了 `docs/designs/2026-11-14-installer-hardening-design.md` 的進度表，卻沒有在根目錄 CLAUDE.md 第一個 `##` 之前加指路句。下一個 session 依 §4.1 會看不到這張表，於是重新估段落數、另開第二張表，先前的進度與 commit 範圍就靜靜遺失。計畫的 S1 文件同步只寫根目錄 CLAUDE.md「只補這次留下的坑」，驗收條目也沒有檢查這句。
證據：`CLAUDE.md:1-12` 無「進度以」（`grep -n '進度以' CLAUDE.md` rc=1）；計畫第 6 行只陳述「沒有進度紀錄」，沒有提到 §4.4 的「開表的同時加指路」；計畫第 54 行「根目錄 CLAUDE.md … 只補這次留下的坑」。全域 CLAUDE.md §4.4 原文：「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，並且說明少了這句，下一個 session 就看不到這張表。
判定：①每開一張表都會走到；②下一個 session 會重估、另開表；③`scripts/check-claude-md.sh` 只檢查改碼目錄的 CLAUDE.md，沒有檢查指路句（我讀過該檔對 `docs/` 的處理，未逐行查 `ci.yml`）。

輪1-R2-2｜小｜驗證只寫「本機 ci.yml 20 個 step 全過」（S1、S2 的驗收條目）。`ci.yml` 的 20 個 step 是 ubuntu lint job（事實 F14），macOS job 的 `/bin/bash` 3.2 那組 step 沒有列入本機驗證。`DD_PIPELINE_ARCHITECTURE.md:138` 寫 `test-install` 屬於 `bash32` job。計畫新增的 T2 會大量用到 jq／python3 分支與 bash 結構，3.2 相容性只能靠那個 job 驗，而計畫不 push，CI 跑不到。
證據：計畫第 13、25、49 行的驗證條目；`DD_PIPELINE_ARCHITECTURE.md:138`（「macOS `/bin/bash` 3.2 行為測試（`bash32` job：…安裝端到端）」）；事實 F14（lint 20 steps）、F15（ubuntu job 沒跑過本機 34 個 commit）。

【需要外部查證】
輪1-R2-3｜小｜計畫 S2 第 8 點要寫的「前置需求補 claude-md-management 的安裝指令」，是否真的需要：`install_plugins` 只在讀不到版本時印 `claude plugin install`（`install-dd-pipeline.sh` 中 `PLUGINS_MARKETPLACE` 那段）。`claude-md-management` 的 `plugin.json` 有沒有 `version` 欄位，要看使用者機器上的 marketplace 或 cache，repo 裡沒有這份檔，我沒有查到。若有版本，就不需要寫這條指令，只寫「需先存在於本機」即可。

輪1-R2-4｜小｜計畫 S2 第 5 點「全域會掛的 hook：補上 self-improving-agent 的那一個」依賴的是 Claude Code 的 `<名字>@skills-dir` 載入機制，安裝腳本只登記 `OFFICIAL_PLUGINS`。`self-improving-agent/hooks/hooks.json` 存在，但它在使用者機器上是否真的被載入，repo 內查不到。計畫的開工前提第 3 點已列為要查，這裡只提醒：README 寫「全域會掛」之前要實際看到它在 `/hooks` 或 `claude -p` 的 init 裡出現，不能只靠檔案存在。
