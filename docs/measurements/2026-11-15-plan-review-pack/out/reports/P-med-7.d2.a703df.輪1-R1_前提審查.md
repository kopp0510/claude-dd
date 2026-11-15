【我查了什麼】
- 讀完材料 `prompts/P-med-7.pack.md` 全 166 行（一次讀完，未截斷）。
- 讀 `install-dd-pipeline.sh` 的 `ask`(:173)、`backup_before_overwrite`(:187)、`jq_inplace`(:209)、`py_inplace`(:228)、`json_edit`(:248)、`plugin_enabled_state`(:397)、`validate_skill_hooks`(:463)、`install_builtin_skills`(:504–531)、`mcp_scope`(:630)、`install_plugins`(:730–876)、`create_commands`(:879–960)、`scripts`/`output-styles` 覆蓋段(:1000–1050)、`uninstall` 的 plugin 段(:1118–1150)、`create_global_claude_md`(:1157–1238)、`show_completion`(:1241)。
- 跑過的 grep／讀取：
  - `git rev-parse --short HEAD` → `e3e9e18`；`git log --oneline` 只有 `e3e9e18 base`；`git rev-parse origin/main` → 不是有效修訂版。
  - `grep -n '進度以' CLAUDE.md` → 無命中；`grep -n '^## ' CLAUDE.md` → 第一個是 `5:## 安裝 / 更新`。
  - `grep -n -E 'setdefault|\.pop\(' install-dd-pipeline.sh` → 767、845、1133、1143 四處 python 寫法。
  - `grep -rn -E '新增|同時改|同批|要一起|同步' --include=CLAUDE.md`（全部 CLAUDE.md）→ 與本計畫相關的是根 CLAUDE.md 的「新增 Script／Output Style／Command」區塊、`tests/CLAUDE.md`、`DD_PIPELINE_ARCHITECTURE.md` 的安裝行為保證（:72、:74）。計畫都有列到。
  - `grep -n FORCE install-dd-pipeline.sh` → 覆蓋行為在各段都不依 `--force` 決定，與計畫的 README 項 2 一致。
  - `REQUIRED_MCP`（:100–102）只有 `playwright`，與 T4 的假設一致。
  - `.github/workflows/ci.yml`：lint job 20 個 step、macOS job 另計，與 F14 一致。
  - `docs/measurements/2026-10-23-reviewer-real-sessions.md:86` 的 311／11.8／27.7 數字存在；`skills/dd-loop/SKILL.md:66` 的 269s／5.13／350s／3.83 數字存在。
- 結論：計畫引用的程式碼行為（cp -r 備份、jq/py 各路徑的行為、覆蓋不看 --force、show_completion 無條件列印、deprecated 直接 rm、validate_skill_hooks 以 exit 1 中止）在本 checkout 都對得上。問題集中在計畫漏寫的規則、數量錯誤，以及事實來源與本 checkout 不一致。

【批評】
- 輪1-R1-1｜重大｜計畫沒有安排 §4.4 要求的「根目錄 CLAUDE.md 指路句」，也沒有 IN_PROGRESS/DONE 的標記流程。計畫自己承認根 CLAUDE.md 沒有「進度以…為準」那句，卻只在 S1 文件同步裡寫「只補這次留下的坑」，沒有加指路句。全域 §4.4 寫明「開表的同時，在根 CLAUDE.md 第一個 `##` 之前加一段指路」，理由是沒有指路的下個 session 會看不到表、重估段落、進度與 commit 範圍遺失。證據：`prompts/P-med-7.pack.md:6`、`:12`（全部 TODO）、`:54`（只補坑）；`CLAUDE.md:5`（第一個 `##`，指路句必須插在它之前）。三條都符合：每開一張表都會遇到；下個 session 會看不到進度；沒有任何檢查會抓到。
- 輪1-R1-2｜重大｜S2 項 6 要把「步驟 4 每段至少 3 個 opus 審查者，附量測日期、樣本數與檔名」寫進兩份 README，但計畫引用的 311 次數字是「全部 code-reviewer subagent」（來源是 `~/.claude/projects/**/agent-*.meta.json`，排除公司路徑），不是步驟 4 的量；而量測檔自己寫「引用下面的數字前先重跑（數字是當天的快照）」。證據：`docs/measurements/2026-10-23-reviewer-real-sessions.md:9–12`（來源與排除）、`:16`（引用前先重跑）、`:86`（當天快照）；`prompts/P-med-7.pack.md:77`、`:156`。計畫的驗證是「逐句核對表」，只要 README 句子與快照原文一致就會過，這個比對抓不到「快照已過期」與「樣本母體不是步驟 4」這兩種錯，也沒有任何 CI 驗 README 的時間或費用數字。
- 輪1-R1-3｜中｜計畫說 python 路徑「三句」要改，實際有四句。除了 install 的 settings（:845）與 uninstall 的兩句（:1133、:1143），還有 `py_register` 的 `plugins = data.setdefault('plugins', {})`（:767）。計畫的定案寫「`plugins` 的值是 null 當成沒有這個鍵」，但做法只點名三句，所以 `{"plugins":null}` 在 python 路徑會繼續在 `plugins[...]` 上失敗，而 jq 路徑（`.plugins[$key] = …` 對 null 可寫入）會成功，兩條路徑結論不一致。證據：`install-dd-pipeline.sh:767`；`prompts/P-med-7.pack.md:31`、`:33`。T2 會紅，所以這不是 ③，但實作者會拿到紅燈後自己決定行為。
- 輪1-R1-4｜中｜T1（symlink 備份）在本機 macOS 修之前就是綠的（計畫自己寫的，`prompts/P-med-7.pack.md:24`）。紅與綠的證據是靠 docker 裡另外 source 函式、手動跑 `cp`，不是跑 `tests/test-install.sh` 裡的 T1。§3.5 要求新測試必須以測試本身看到紅燈，計畫沒有要求這件事；唯一會紅的環境是 ubuntu CI，計畫沒有要求在 ubuntu 上確認 T1 修前是紅的。
- 輪1-R1-5｜中｜計畫沒有排進 §3.9 的步驟 3（code-simplifier）、步驟 4（code-review，每段至少 3 個 reviewer，修掉 Critical/Important 才續行）、步驟 8（CLAUDE.md 範圍與評分）。整份計畫只有 S1-1 到 S1-4 的驗證與 S2 的 ci.yml 重跑。證據：`prompts/P-med-7.pack.md` 全檔 grep `review|simplif|步驟 [348]|dd-loop` 只命中 `:67`、`:77`、`:123`、`:155–156`，都不是排程。這是「漏寫」，不是「寫錯」，所以不列為重大。
- 輪1-R1-6｜中｜計畫的事實段標題寫「repo 在 HEAD b1935bb」，F15 寫「公開版 origin/main 停在 9584605，本機多 34 個 commit」。本 checkout 的 HEAD 是 `e3e9e18`，只有一個 commit，沒有 origin/main。這代表計畫的事實（F1 的 20 個 step 全過、F6 的 92 例探針、F15 的 CI 紀錄）可能來自另一份 checkout，這裡無法重現。證據：`prompts/P-med-7.pack.md:124`、`:147`；`git rev-parse --short HEAD` → `e3e9e18`。另外 F6 的探針腳本只在 scratchpad（`prompts/P-med-7.pack.md:131`），不在 repo，計畫的驗收條件「92 例不一致數從 16 變 0」沒有可重跑的 repo 內產物。

【需要外部查證】
- 輪1-R1-7｜中｜F1、F6、F15 的數字是在 b1935bb 上取得的，這台 checkout 是 e3e9e18。需要在實際要改的 repo 上重跑 `ci.yml` 全部 step 與等價探針，並確認 origin/main 與 34 個 commit 的說法。為什麼需要：HEAD 不一致，這裡無法確認那些數字屬於這個 repo。
- 輪1-R1-8｜小｜計畫依賴 `jq -e` 對空輸入回 4，以及 `jq -e` 對 `false` 回 1。兩者在 macOS 的 jq 與 debian:bullseye 的 jq 1.6 上是否相同，我沒有驗證。為什麼需要：S1-2 的「空檔算失敗」寫法依賴這個退出碼，應在兩個環境實跑一次。
