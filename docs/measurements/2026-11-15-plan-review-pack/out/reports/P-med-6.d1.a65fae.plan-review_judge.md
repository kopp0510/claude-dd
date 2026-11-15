我是第 1 輪的裁決者，結論是 `通過`。4 個審查者都過了讀檔檢查，沒有一條批評查證後算重大。審查者標為重大的批評一共 4 類：根目錄指路句（4 個人都提）、少排步驟 3–8、成本數字對不上、這輪不在 Linux 上跑測試。查證後前兩類駁回，後兩類降成小事。

【派工】
派了 4 個（haiku、effort medium）：
- 輪1-R1：前提成不成立（逐一查安裝腳本各函式、測試、README 的宣稱）
- 輪1-R2：漏掉的同步點
- 輪1-R3：範圍與驗證
- 輪1-R4：全面，加重查 S2 的 README 句子與 S1-4 的完成訊息

為什麼派 4 個：計畫有兩段、跨安裝腳本、測試、CI、兩份 README 與架構文件。重派 0 個，補派 0 個。

【讀檔檢查】
4 個都過：
- 輪1-R1：抽 `install-dd-pipeline.sh:187-195`，對得上（`backup_before_overwrite` 先 `[ -e "$target" ] || return 0`，再 `cp -r`）
- 輪1-R2：抽 `scripts/check-claude-md.sh:180`，對得上（`[ -d docs/reviews ] || return 1`）
- 輪1-R3：抽 `scripts/CLAUDE.md:185-188`，對得上（bash 3.2 相容由 `bash32` job 驗）
- 輪1-R4：抽 `install-dd-pipeline.sh:1067`，對得上（「含 pre-commit gate — 移除後各專案掛著的 hook 會失效」）

【採納（重大）】
無。

【採納（小事）】
- **輪1-R1-3、輪1-R3-2、輪1-R4-9｜S2-1 第 6 項的成本數字，量的不是「步驟 4 每段」**
  - 2026-10-23 那份量的是單一 code-reviewer subagent 的耗時：一台機器、約 30 天、排除含 `-SRE` 的專案，而且檔內寫「引用下面的數字前先重跑」（已讀 `docs/measurements/2026-10-23-reviewer-real-sessions.md:1-16`）。
  - 5.13 美元那組是「直接派 vs 另派裁決者」的對照，作者自註「n 小、同時改了三件事，只是方向」（已讀 `skills/dd-loop/SKILL.md:66`）。
  - 計畫要怎麼改：README 照原檔寫出每個數字量的是什麼與限制；開工前提 5 加一句：照原檔要求先重跑，跑不了就照實寫「這是某日的快照」。逐句核對表要比「量的是什麼」，不只比數字。
- **輪1-R4-4｜S1-4 少寫一個參數**
  - 計畫寫 `backup_before_overwrite "commands"`，但函式簽名是 `local category="$1" target="$2"`。缺 target 時直接 return 0，什麼都不備份（已讀 `install-dd-pipeline.sh:187-189`）。
  - 計畫要怎麼改：改成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`，放在 `rm` 之前。
- **輪1-R4-5｜S2-1 第 1 項「不動各專案的 hook」少了後果**
  - 移除後 hook 還在，但 gate 腳本被刪了：hook 放行 commit，只印「CLAUDE.md gate 沒執行」警告（已讀 `commands/dd-init.md:203`、`install-dd-pipeline.sh:1067`）。
  - 計畫要怎麼改：README 補一句「hook 留著，但不再擋 commit，只印警告」。
- **輪1-R1-6、輪1-R3-3、輪1-R1-13｜GNU 環境只有 docker 單點重現**
  - 本機 macOS 上 T1 修前就是綠的；`tests/test-install.sh` 本身在 ubuntu 要等使用者 push 後才第一次跑。
  - 新測試若用了 BSD 才有的寫法，push 後 CI 會紅，所以不是靜默錯。
  - 計畫要怎麼改：S1-1 在 debian 容器裡至少跑一次 T1（T1 不需要 jq），修前修後各取紅綠；回報寫明「ubuntu job 尚未跑過這批 commit」。
- **輪1-R3-6｜S1-3 的變異沒寫改哪一行**
  - 計畫要怎麼改：T3–T7 每組記下「改了哪一行、改成什麼 → 哪幾個情境變紅」（全域 §3.9 鑑別力測試那條）。

【駁回】
指路句、步驟 3–8 與開工程序這一群：草稿沒寫，不算缺失，因為 task-planner 在 plan-review 之後一定會補上（已讀 `skills/task-planner/SKILL.md:108-109、121、133-136`）：
- 步驟 5 一定會在根目錄 CLAUDE.md 第一個 `##` 前加指路句。
- 照抄進設計文件的規則區塊含 `--start-segment` 記起點、標 `IN_PROGRESS`、步驟 3–8 跑完才標 `DONE`。

逐條：
- 輪1-R1-1、輪1-R2-1、輪1-R3-1、輪1-R4-1｜沒排根目錄指路句｜task-planner 步驟 5 一定會寫（SKILL.md:108-109）。
- 輪1-R1-2、輪1-R4-3｜沒排步驟 3–8 與 review 報告｜規則區塊規定小任務全部 commit 完才跑步驟 3–8（SKILL.md:135-136），報告怎麼落地由 dd-loop 管。
- 輪1-R2-2｜沒寫 `docs/reviews/` 報告與子目錄｜同上，報告的檔名與位置是 dd-loop 步驟 4 的細則。
- 輪1-R2-3、輪1-R4-2｜沒有 `IN_PROGRESS`、`--start-segment` 與 commits 欄的時機｜規則區塊的「開工」那條已規定（SKILL.md:133）。
- 輪1-R1-4｜T1–T9 不是使用者要求的測試｜使用者決定（事實段：測試清單題選定的就是使用者要求的；SKILL.md:97）。
- 輪1-R1-5｜擴大範圍沒先問｜使用者說「請你優化改善」、沒指定項目，選 4 與 5 已在 A1 揭露；全域 §4.1 規定 plan-review 通過就動手，使用者可隨時喊停。
- 輪1-R1-7｜T7 的假目錄沒寫要放壞的 hooks.json｜T7 寫「skill 的 hooks.json 用相對路徑時」，已含這個 fixture。
- 輪1-R1-8、輪1-R4-8｜A4 與「頂層非物件算失敗」互相矛盾｜A4 刻意保留；註解寫明這是與 python3 分支對齊的型別護欄（`install-dd-pipeline.sh:403-404`），頂層非物件時 plugin 確實沒啟用，回 `none` 不算假斷言。
- 輪1-R1-9、輪1-R3-9｜懸空連結被 `[ -e ]` 跳過｜懸空連結沒有原內容可備份，不會掉資料，是既有行為。
- 輪1-R1-10、輪1-R3-7｜空檔、null 的行為是設計取捨，該回問｜根目錄 CLAUDE.md 已定「jq 與 python3 兩路徑逐項等價」「不確定就說不確定」，計畫照房規定案，不必回問。
- 輪1-R3-4、輪1-R4-6｜驗證只有 lint job，漏了 bash 3.2｜本機 macOS 跑 lint job 的 `tests/test-install.sh` 時，靠 `#!/bin/bash` 這個 shebang 走的就是 3.2（已讀 `install-dd-pipeline.sh:1`、`ci.yml:556-557`），3.2 有驗到；GNU 的缺口已列進上面的小事。
- 輪1-R3-5｜T2 沒要求「紅在斷言」｜計畫指定紅在 92 例裡的那 16 例；載入失敗會讓全部變紅，所以這個判準本身就能區分。
- 輪1-R4-7｜F20 的前提不實｜F20 自己標了「沒有重跑」，開工前提 2 已安排去查 `commands/dd-init.md`。
- 輪1-R1-11、輪1-R4-10｜self-improving-agent 的 hook 是否全域生效｜開工前提 3 已安排查證，README 只寫查得到的；根目錄 CLAUDE.md 新增 Skill 步驟 6 記了 2026-09-30 實測過 hook-only 元件以 `<名字>@skills-dir` 載入。
- 輪1-R1-12、輪1-R3-8、輪1-R4-11｜`jq -e` 空輸入回 4 沒有依據｜T2 的空檔案例直接斷言結論，值不對會在測試紅出來，不會靜默。
- 輪1-R4-12｜`cp -RL` 行為沒實跑｜F5 已在 debian 與 macOS 實跑過。

【需使用者決定】
無。

【需要外部查證】
無。審查者交回的外部查證項都已在上面查完、分類。

【結論】
通過
