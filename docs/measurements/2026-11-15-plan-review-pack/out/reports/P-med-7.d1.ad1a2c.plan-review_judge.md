【派工】
派了 4 個審查者（haiku、effort medium），沒有重派，也沒有補派：
- 輪1-R1：查前提，逐個讀安裝腳本的函式，看改法做不做得到
- 輪1-R2：查漏掉的同步點（各層 CLAUDE.md、ARCHITECTURE、CI、gate）
- 輪1-R3：查範圍與驗證（T1–T9 有沒有鑑別力、跨平台、使用者決定）
- 輪1-R4：查 S2 要寫進 README 的事實，以及會不會撞 CI 的檢查

為什麼派 4 個：計畫有兩段、跨安裝腳本、測試、README 與多份文件，3 個不夠細分。

【讀檔檢查】
- 輪1-R1：過（抽查 `docs/measurements/2026-10-23-reviewer-real-sessions.md:86`，內容是「次數=311 中位=11.8 分 第90百分位=27.7 分」，對得上）
- 輪1-R2：過（抽查 `DD_PIPELINE_ARCHITECTURE.md:138`，內容是 bash32 job 含安裝端到端，對得上）
- 輪1-R3：過（抽查 `install-dd-pipeline.sh:187-190` 的 `local category="$1" target="$2"` 與 `[ -e "$target" ] || return 0`，以及 `:1082-1088` 的 ASSUME_YES 分支，都對得上）
- 輪1-R4：過（抽查 `install-dd-pipeline.sh:1121-1124` 的「缺少 jq 與 python3，跳過 Plugin 設定清理」與 `:1067`，都對得上）

【採納（重大）】
（無）

【採納（小事）】
- 輪1-R3-1｜T2 呼叫真的 `uninstall` 時沒寫要設 `ASSUME_YES=true`。非互動下 `ask` 採預設 N（`install-dd-pipeline.sh:1082-1088`），移除段整段不跑，uninstall 那幾例兩條路徑必然一致。計畫要求的「先紅在那 16 例」核對會發現數字不對，所以不算重大｜計畫要怎麼改：T2 明寫 uninstall 案例設 `ASSUME_YES=true`；紅燈時逐例對照「哪個案例 → 哪條路徑不一致」，不能只看紅數
- 輪1-R1-3｜`py_register` 的 `plugins = data.setdefault('plugins', {})`（`install-dd-pipeline.sh:767`）遇到 `{"plugins":null}` 會拿到 None 而失敗。計畫說 python「三句」改成 None 當空物件，這三句只有 settings 那句（`:845`）和 uninstall 兩句，沒包含這句，改完 T2 會紅｜計畫要怎麼改：S1-2 做法改成四句，把 `py_register` 的 `plugins` 為 None 的處理列進去
- 輪1-R3-3｜S1-4 寫 `backup_before_overwrite "commands"` 只給一個參數。函式第二個參數是 target，空的話直接 return 0、不備份（`:187-190`）。T8 會接住｜計畫要怎麼改：寫成迴圈裡對每個要刪的 `$COMMANDS_DIR/$old.md` 各呼叫一次 `backup_before_overwrite "commands" <該檔>`
- 輪1-R3-6｜source 安裝腳本時，`install-dd-pipeline.sh:26` 會重新算 `SCRIPT_DIR`｜計畫要怎麼改：T7 寫明在 source 之後才覆寫 `SCRIPT_DIR`
- 輪1-R1-4／R3-4（合併）｜T1 的紅綠證據是 docker 裡手寫的函式呼叫，不是 `tests/test-install.sh` 的 T1 本身。本機 macOS 修前就綠，ubuntu CI 沒跑過這 34 個 commit，所以沒人看過「T1 這則測試在 GNU 上紅」。沙盒設錯的話，T1 修前修後都綠也不會被發現｜計畫要怎麼改：在 GNU 環境跑 T1 那段。可以在 debian 容器裡用 bash 跑 T1 的 setup 加安裝的 global 步驟，或在 ubuntu 容器裝 jq／python3 後跑整支 test-install.sh。修前紅、修後綠都附輸出
- 輪1-R3-5｜S1-4 把「清舊指令檔前備份」和「完成訊息只報實際做了的」兩個不相干的修正放進同一個 commit，違反全域 §5.2「不合併多個邏輯變更為單一 commit」｜計畫要怎麼改：拆成兩個 commit（S1-4a、S1-4b）
- 輪1-R3-7｜T5 沒寫「不帶 `--force`」，但 S2 第 2 條「不帶 --force 也會換掉」要靠它當證據｜計畫要怎麼改：T5 明寫不帶 `--force` 重裝
- 輪1-R2-2／R4-9（合併）｜本機驗收只寫「ci.yml 20 個 step」，那是 ubuntu lint job 的數量，沒涵蓋 macOS bash32 job（`DD_PIPELINE_ARCHITECTURE.md:138`）｜計畫要怎麼改：驗收加上本機照 macOS job 的 step 用 `/bin/bash` 跑 test-install.sh；在回報註明 ubuntu 的結果要等使用者 push 後才看得到
- 輪1-R1-2／R4-3（合併）｜S2 第 6 項的成本數字有三個限制：311 次是全部 code-reviewer subagent，不只步驟 4；量測檔自己寫數字是當天快照、引用前要重跑；dd-loop 的 5.13 美元是 n=2、只看得出方向（`docs/measurements/...:86`、`skills/dd-loop/SKILL.md:66`）。逐句核對表只比對原文，抓不到這幾種誤讀｜計畫要怎麼改：第 6 項寫明每個數字的母體、n、日期與「當天快照」這個但書，不寫成步驟 4 的保證值
- 輪1-R4-1｜uninstall 在沒有 jq 也沒有 python3 時會跳過 plugin 清理（`:1121-1124`），但 S2 第 1 項寫成無條件「會拿掉」｜計畫要怎麼改：補上這個條件
- 輪1-R4-2｜uninstall 會刪掉 gate 本體，各專案的 hook 之後就失效（`:1067`）｜計畫要怎麼改：S2 第 1 項補上這個後果
- 輪1-R4-4｜CI 用中文錨點 `^> 步驟 1` 定位全域模板（`.github/workflows/ci.yml:314`、`:501`），翻譯模板後迴圈步數那兩道檢查會失效｜計畫要怎麼改：開工前提 1 的清單加上 ci.yml 錨點

【駁回】
- 輪1-R1-1／R2-1／R3-2｜沒有在根目錄 CLAUDE.md 加指路句｜這份計畫是 task-planner 步驟 4 送審的草稿，步驟 5 本來就規定要加指路（`skills/task-planner/SKILL.md:108-109`），屬於既定流程會處理的事
- 輪1-R1-5｜沒排 §3.9 的步驟 3、4、8｜進度表的規則區塊與 dd-loop 會管，task-planner 把小任務定為只走步驟 1、2，整段跑 3–8，不算漏
- 輪1-R1-6／R1-7｜審查用的 checkout 的 HEAD 是 e3e9e18，和事實寫的 b1935bb 不同｜這是審查用的副本環境，不是計畫的缺失；能抽查的行（test-install.sh 87 行、各函式行為）都對得上
- 輪1-R3-8｜探針放在 scratchpad、不在 repo｜T2 本來就要把案例表搬進 `tests/test-install.sh`；debian 重現的問題已併進 R1-4／R3-4 那條
- 輪1-R4-5｜self-improving-agent 的 hook 觸發條件計畫沒寫｜開工前提 3 已經要查「什麼時候會插提醒」
- 輪1-R4-6｜「會用繁中」是靠規則，以及全域 CLAUDE.md 預設是 No｜它引的 `README.md:56` 講的是 plugin 登記，不是全域 CLAUDE.md 的預設，證據不支持

【需使用者決定】
（無）

【需要外部查證】
- 輪1-R3-9｜小｜GitHub 的 `ubuntu-latest`／`macos-latest` runner 有沒有內建 jq（ci.yml 沒有安裝 jq 的步驟）。如果沒有，CI 上 T2 兩邊都走 python，等價比對會靜靜變綠。建議 T2 開頭先斷言 `command -v jq` 存在，不存在就 fail
- 輪1-R1-8／R3-10｜小｜macOS 與 ubuntu 上的 jq 版本，`jq -e` 對空輸入是不是都回 4、對 false 是不是都回 1
- 輪1-R2-3／R4-7｜小｜`claude-md-management@claude-plugins-official` 是否存在、`plugin.json` 有沒有 `version`，這決定 README 那條安裝指令的寫法
- 輪1-R2-4／R4-8｜小｜self-improving-agent 的 hook 在使用者機器上是否真的全域載入，要用 `claude -p` 實測才知道

【結論】
通過
