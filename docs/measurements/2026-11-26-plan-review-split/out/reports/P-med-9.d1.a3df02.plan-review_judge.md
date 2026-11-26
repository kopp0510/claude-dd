**【派工】**
計畫有 2 段（S1、S2，以進度表為準）。我在同一則訊息裡平行派了 3 個審查者，都是 general-purpose、haiku、effort medium：
- 輪1-R1：只查 S1，其他段是背景
- 輪1-R2：只查 S2，其他段是背景
- 輪1-R3：跨段，查段落之間的依賴、順序、重複與漏掉的同步點

沒有重派，也沒有補派。

**【讀檔檢查】**
- 輪1-R1：過。抽查 `install-dd-pipeline.sh:187-189`，那裡是 `local category="$1" target="$2"`，接著是 `[ -e "$target" ] || return 0`，和它的引用對得上。
- 輪1-R2：過。抽查兩處都對得上：`README.md:104` 有 Step 4 的例外句 "when the increment's diff is all data, configuration, comments or documentation … no agent is dispatched"；`commands/dd-init.md:264-269` 有「使用者不裝就跳過第 4 步，第 5 步改講『這個 repo 沒裝 gate』」。
- 輪1-R3：過。抽查兩處都對得上：`CLAUDE.md:187-188` 有「進度表連同規則區塊照抄進專案的設計文件」；`templates/global/CLAUDE.md:510-511` 有開表時要加指路那一段。

**【採納（重大）】**
無。

**【採納（小事）】**
- 輪1-R1-1、輪1-R3-3｜S1-4 寫成 `backup_before_overwrite "commands"`，少了第二個參數。照字面做，`target` 是空的，函式會直接 return 0，不備份也不報錯（已讀 `install-dd-pipeline.sh:187-189`、`:889-893`）。T8 會抓到它，所以不算重大｜改成 `backup_before_overwrite "commands" "$COMMANDS_DIR/$old.md"`，寫在 `rm` 之前。
- 輪1-R1-2｜S1-3 說 `SANDBOX` 的「無備份產生」斷言「靠 plugin 步驟被跳過才成立」，這個理由不成立。`install_plugins`（730–878 行）裡沒有任何 `backup_before_overwrite` 呼叫，9 個呼叫點都在別的函式（已跑 `grep -n backup_before_overwrite install-dd-pipeline.sh`）｜開新沙盒的做法保留，理由改成「避免和既有斷言共用狀態」。
- 輪1-R1-3｜S1 與 S2 的驗收只寫「本機（macOS）跑 ci.yml」。T2–T9 從沒在 GNU 或 ubuntu 上跑過，而且 F15 說本機多出的 34 個 commit 沒跑過 ubuntu job｜驗收欄寫明「ubuntu job 未在本機驗證，push 後由使用者看 CI」。
- 輪1-R1-4｜如果某個 runner 沒有 jq，`command_exists jq` 就恆為假，T2 會變成 python 比 python，照樣綠（空通過）｜T2 開頭先斷言 jq 真的存在、jq 那條路徑真的有跑到；沒有 jq 時印出來並讓測試失敗，或明確跳過。
- 輪1-R2-1｜S2-1 第 6 點要寫「步驟 4 每段至少 3 個 opus 審查者」，漏了例外：純資料、設定、註解、文件的段落不派審查者（已讀 `README.md:104`）。「opus」這部分是對的（已讀 `agents/code-reviewer.md:4` 的 `model: opus`）｜把例外一起寫進去。
- 輪1-R2-3、輪1-R3-4｜成本數字少了限定條件，日期也有落差：
  - `skills/dd-loop/SKILL.md:66` 寫的是「2026-10-24 實測」，原文自己註明「n 小、同時改了三件事，只是方向」。
  - 同一組數字在 `docs/measurements/2026-10-23-reviewer-real-sessions.md:319`，檔名日期是 10-23。
  - 那 311 筆是 code-reviewer 的執行次數，不是「每段」的成本。

  改法：README 以量測檔為準，附路徑與該節日期，照抄「n 小、只是方向」，寫明 11.8 分鐘是單一 reviewer 的中位數。
- 輪1-R2-5｜S2-1 第 2 點的覆蓋行為沒寫 S1-4 新增的「清 5 個舊指令檔之前先備份」，而 S2 本來就是要照 S1 改完後的行為寫｜補一句。
- 輪1-R3-6｜S1 的驗收寫「探針 92 例不一致數 16→0」，但探針在 scratchpad、不在 repo，之後的 session 重跑不了｜驗收改成指向 T2（S1-2 已經把這張案例表搬進 `tests/test-install.sh`）。

**【駁回】**
- 輪1-R3-1｜開表時沒在根 CLAUDE.md 加「進度以…為準」的指路｜task-planner 步驟 5 本來就會做（已讀 `skills/task-planner/SKILL.md:108`）。這份是步驟 4 的草稿（同檔 :74），不是缺失。
- 輪1-R3-2｜設計文件四節沒有照抄規則區塊｜計畫寫的四節就是 task-planner 步驟 5 定的四節（同檔 :105），而規則區塊屬於「進度表格式」，要整段照抄（同檔 :121），由步驟 5 處理。
- 輪1-R2-2｜F20 說「don't install the gate」在 repo 裡沒有對應做法，這是錯的｜計畫的開工前提 2 已經安排去讀 `commands/dd-init.md` Phase 3 查證；F20 自己也標了這項「未重跑」。
- 輪1-R2-4｜CI 抓不到新寫的事實句｜計畫已安排逐句核對表，把每一句對到它依據的程式碼或量測檔，這就是它的驗證。審查者沒拿出這個核對表會漏掉某句的證據。
- 輪1-R2-6（原列需要外部查證、標重大）｜不確定 self-improving-agent 的 hook 真的會被掛上｜repo 裡有同一個機制的實測紀錄：`skills/gate-guard/hooks/CLAUDE.md:46-49` 寫明以 skills-dir plugin 載入、自動掛上 `hooks.json`，2026-09-30 用 `claude -p` 實測 deny 成功。self-improving-agent 也有 `.claude-plugin/` 與 `hooks/hooks.json`（已跑 `ls -a`），開工前提 3 也會去讀它。
- 輪1-R3-5｜「你自己裝的也一樣」語意不清｜括號的意思是：`OFFICIAL_PLUGINS` 列的 plugin 就算是使用者自己裝的，也會被拿掉。這和 `install-dd-pipeline.sh:1125` 起只對 `OFFICIAL_PLUGINS` 跑的迴圈一致，沒有說錯。

**【需使用者決定】**
無。

**【需要外部查證】**
- 輪1-R1-4｜小事｜GitHub `macos-latest` 與 `ubuntu-latest` 的 runner 映像有沒有預裝 jq。不管查出來是哪個答案，加上面那條斷言就能防住空通過。
- 輪1-R1-5｜小事｜ubuntu 上 jq 的版本和本機不同時，jq 與 python3 改完的 JSON 逐字比對是不是還相同。不同的話 CI 會直接紅，不會靜默；建議比對前先正規化（例如 `jq -S`）。

**【結論】**
通過
