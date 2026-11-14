【派工】
派了 4 個，全部是 general-purpose、haiku、effort low，沒有重派也沒有補派。計畫跨安裝腳本、測試、CI 和兩份 README，所以分四個方向：
- 輪1-R1：前提成不成立（逐條核對具體宣稱）
- 輪1-R2：漏掉的同步點（各層 CLAUDE.md 的同批規則）
- 輪1-R3：S1 的範圍與驗證（T1–T9 會不會變紅）
- 輪1-R4：S2 的 README 八項依據，以及 A1–A7 有沒有跳過使用者決定

【讀檔檢查】
- 輪1-R1：過。抽查 `install-dd-pipeline.sh:187-191`，`backup_before_overwrite` 是 `local category="$1" target="$2"` 加上 `[ -e "$target" ] || return 0`，對得上。
- 輪1-R2：過。抽查 `CLAUDE.md:5`，第一個 `##` 是「## 安裝 / 更新」；`docs/designs/2026-10-23-裁決審查-design.md` 的進度表下方確實有狀態規則區塊（開工記起點、DONE 時刪指路）。
- 輪1-R3：過。抽查 `install-dd-pipeline.sh:189`，對得上。
- 輪1-R4：過。抽查 `templates/global/CLAUDE.md:510-512` 的「開表的同時…加一段指路」，以及 `skills/self-improving-agent/hooks/hooks.json`（PostToolUse、matcher Bash、`error-capture.sh`），都對得上。
- 重派、補派：無。

【採納（重大）】
（無）

【採納（小事）】
- 輪1-R1-2｜S1-4 寫的 `backup_before_overwrite "commands"` 少了第二個參數。函式在 `[ -e "$target" ]` 那行會直接 return 0，什麼都不備份。T8 會抓到，但計畫本身應寫對｜改成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`，放在 `rm` 之前。
- 輪1-R3-1｜S1-1「不對所有情況都加 `-L`」的理由寫錯。頂層是懸空連結時，`[ -e "$target" ] || return 0`（`install-dd-pipeline.sh:189`）會先 return，根本走不到 `cp`｜改寫理由：真正要避開的是目錄（skills、命名空間指令）裡面的懸空連結。`-L` 用在整個目錄會在 GNU 上回 1，撞上 `set -e`。頂層懸空連結由 `-e` 擋掉，不必考慮。
- 輪1-R1-3／輪1-R4-2（合併）｜S2-1 第 6 項沒講清楚要引哪個數字、那個數字量的是什麼：
  - `docs/measurements/2026-10-23-reviewer-real-sessions.md` 的「中位=11.8 分」是每個 code-reviewer subagent 自己的耗時。來源是單機約 30 天的紀錄，排除了公司專案。它不是「每段」的耗時。
  - `skills/dd-loop/SKILL.md:66` 的 269s、5.13 美元，量的是「主對話直接派」整個步驟 4，原文自註「n 小、同時改了三件事，只是方向」。

  計畫要怎麼改：第 6 項寫明用哪一組數字、各自量什麼（單一審查者耗時，或整個步驟 4）。原文的限定語（近期樣本、單機、n 小、只是方向）要一起帶進兩份 README，不只附日期、樣本數和檔名。
- 輪1-R2-4／輪1-R4-7／輪1-R4-9（合併）｜S1、S2 驗收寫的「本機 ci.yml 20 個 step 全過」只是 `lint` job 的 step，而且是在 macOS 上跑：
  - macOS job 用 `/bin/bash`（3.2）跑 `tests/test-install.sh`（`ci.yml:594`），不在這 20 個裡。
  - T1 在 macOS 修之前就是綠的，只有 GNU 環境（CI 的 ubuntu job）才有鑑別力。
  - 新測試要到 push 之後才第一次在 ubuntu 上跑。

  push 後紅燈看得見，所以是小事。計畫要怎麼改：
  - S1 驗收補上本機 `/bin/bash tests/test-install.sh`。
  - S1 驗收補上「T1 的紅綠在 GNU 上取」。
  - 照實記下「T2–T9 在 ubuntu 上要等使用者 push 後才驗到」。debian 映像檔沒有 jq 和 python3，T2 在那裡跑不了等價比對。

【駁回】
- 輪1-R1-1／輪1-R2-1／輪1-R4-1｜沒排「在根目錄 CLAUDE.md 加指路句」｜這份是 task-planner 步驟 4 的草稿。照 `skills/task-planner/SKILL.md:74-75`，草稿要列的是進度表、小任務、測試清單、假設和既有的進度紀錄，計畫都列了。指路由步驟 5 寫（`skills/task-planner/SKILL.md:108-109`），流程已經安排。
- 輪1-R2-2｜進度表沒有規則區塊和起點機制｜步驟 5 會把規則區塊「整段照抄」（`skills/task-planner/SKILL.md:121`），開工記起點和 `<起點>..` 也寫在裡面（`:133`）。不是草稿要列的內容。
- 輪1-R2-3｜沒呼叫 task-planner｜這份就是 task-planner 的草稿格式（四節的設計文件、進度表、測試清單），前提不成立。
- 輪1-R1-4｜狀態欄寫 `TODO` 而不是 `IN_PROGRESS`｜規則是「開工時」才標 `IN_PROGRESS`（`skills/task-planner/SKILL.md:133`），草稿寫 `TODO` 是對的。
- 輪1-R1-5｜沒說明 README.md 要用英文寫｜計畫已寫「兩份 README 的同一段並排核對意思一致」，現有 README.md 是英文，根目錄 `CLAUDE.md` 注意事項已有這條規定。不構成缺失。
- 輪1-R1-6｜探針不在 repo，92 例重跑不了｜T2 寫的是「把探針的案例表搬進 `tests/test-install.sh`」，搬的是整份表，不是只挑代表案例。審查者讀錯了。
- 輪1-R1-7｜F5、F6 沒重跑｜S1-1 已安排在 debian 容器取紅與綠，S1-2 已安排先紅在那 16 例，計畫已經處理。
- 輪1-R1-8｜「分」的定義要查｜已查：是每個 code-reviewer subagent 的 jsonl 首末 `timestamp` 差（量測檔「方法」節），結論併入上面的成本小事。
- 輪1-R1-9｜§4.4 和 task-planner 本體沒讀｜已讀本體（`templates/global/CLAUDE.md:510-512`、`skills/task-planner/SKILL.md:108-136`），結論見上面三條駁回。
- 輪1-R3-2｜全域 CLAUDE.md 是 symlink 時，`cp` 會寫穿到連結指的檔｜這是既有行為，計畫沒有改它。§4.2 管的是 agent 自己改專案外的檔，不是安裝腳本執行時的行為。備份修好後這個寫入也救得回來。
- 輪1-R3-3｜`jq_inplace` 型別檢查怎麼吃 `--arg`｜型別檢查只要對檔案單獨跑一次 `jq -e 'type == "object"' "$file"`，不需要那些參數。是實作細節。
- 輪1-R3-4｜S1 段落範圍偏寬｜審查者自己也說不違規。§4.1 的高風險類別裡沒有這一項。
- 輪1-R3-5｜`jq -e` 對空輸入回 4 沒驗證｜jq 手冊寫「沒產生任何有效結果時 exit 4」（通用知識）。而且檢查只看是不是非 0，碼是幾不影響做法。
- 輪1-R3-6｜ubuntu 的 coreutils 版本可能不同｜GNU `cp -r` 沒帶 `-L`／`-H` 時預設不跟連結（通用知識）。這個預設各版 GNU 一致，F5 在 8.32 上的實跑可以代表。
- 輪1-R4-3｜不帶 `--force` 的覆蓋沒列行號｜審查者自己確認這句成立（呼叫點不看 `$FORCE`）。S2-1 已安排逐句核對表。
- 輪1-R4-4｜「你自己裝的也一樣」會誤導｜計畫那句的範圍限定在「`OFFICIAL_PLUGINS` 列的官方 plugin」，意思是「就算是你自己裝的那兩個也會被拿掉」，跟 F11 一致。審查者的證據反而支持這句。
- 輪1-R4-5｜A2「settings.json 可能放 token」沒證據｜計畫寫的是「可能」，是理由不是事實宣稱。Claude Code 的 settings.json 可以放 `env`（通用知識），這個顧慮成立。
- 輪1-R4-6｜沒寫 self-improving-agent hook 的實際行為｜開工前提第 3 項已安排查證。
- 輪1-R4-8｜三個 opus 審查者的費用要另外實測｜repo 裡已有現行做法（主對話直接派、最少 3 個）的量測（`skills/dd-loop/SKILL.md:66`），只是 n 小。處理方式併入上面的成本小事（數字連同限定語一起寫），不需要新實驗才能寫。

【需使用者決定】
（無）

【需要外部查證】
（無）

【結論】
通過
