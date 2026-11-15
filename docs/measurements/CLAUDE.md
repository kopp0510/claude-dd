# docs/measurements

實測的原始數字與實驗輸入。底下每個 `<日期>-<主題>/` 目錄各有自己的 CLAUDE.md（一次實驗可能拆成 inputs、outputs 兩個目錄）；第一層的 `<日期>-<主題>.md` 是量測紀錄，有的有同名的目錄、有的沒有。
這一份是跑 `claude -p` 實驗的共通做法與已知的坑，2026-11-16 從根目錄 CLAUDE.md 逐字搬來（每節開頭註明原本在哪一節）。不管要做哪一節的事，「已知的坑」一節都要看。

## 測 skill 會不會自己叫

（原根目錄 CLAUDE.md「新增 Skill 步驟」第 5 步）

動到 description 或觸發條件時，裝好後測「會不會自己叫」—— 同一個 session 裡推論不算數，要開全新的：
在拋棄式專案裡跑 `claude -p "<需求>" --output-format stream-json --verbose --max-budget-usd 3 --no-session-persistence
--permission-mode dontAsk --allowedTools "Skill Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent"
< /dev/null > out.jsonl`，正反各一個（該叫的大需求、不該叫的小改動），解析 jsonl 看有沒有 `Launching skill:`，
並確認 `permission_denials` 是空的 —— dontAsk 沒加 `--allowedTools Skill` 會把 Skill 擋掉，只證明它「想叫」。
要量 skill 注入了多少字元，量下一則以 `Base directory for this skill:` 開頭的 user 訊息：Skill 的 tool_result 只有 `Launching skill: <名字>` 那一行
（2026-10-30 dd-loop 實測，量法見 `docs/measurements/2026-10-30-dd-loop-trigger/check.sh`）。
prompt 存成 `<名字>.prompt.txt` 放在 jsonl 旁邊，不然事後核對不了「不含關鍵字」這種說法；每次約 US$0.4–1.6。
這種 session 沒有寫檔工具也沒有 AskUserQuestion（題目會印成文字），只測得到「叫不叫、出不出得了草稿」，寫檔與 commit 的步驟要另外在沙盒實跑。
測會叫 `plan-review` 的 skill 時，`--allowedTools` 加 `Agent`、`--disallowedTools` 拿掉 `Agent`、加 `--forward-subagent-text`、`--max-budget-usd` 調高 ——
不然派不出裁決者，「沒問批准題」會因為審查根本沒跑而自動成立。
加了 `disable-model-invocation: true` 的 skill，正向那發只能用 slash 叫，而 slash 叫法的 stream-json 沒有 Skill 的 tool_use、也沒有 `Launching skill:`：
要讓回覆照貼 skill 本文裡只有這一版才有的一行，再配一發指令名換成不存在的對照。反向那發也要對照：用 `--plugin-dir` 載入拿掉 dmi 的副本，
同一個 prompt 要叫得起來，「沒叫」才有鑑別力（2026-11-14 security-audit，`docs/measurements/2026-11-14-security-audit-trigger/`）

## 量 agent 指令本體

（原根目錄 CLAUDE.md「新增 Agent 步驟」第 5 步；那一步最後的「量測前先關掉 advisor」每一種量測都用得到，放在「已知的坑」）

改 agent 指令本體想知道有沒有變好，用 A/B 實測：`jq -n --rawfile` 把去掉 frontmatter 的新舊兩份塞成
`{名字:{description,prompt}}`，`claude -p --agents <json> --agent <名字> --model opus` 各跑一發，素材挑
「後續 commit 已認定真錯誤」的舊 diff（ground truth 現成）。先用 haiku 問一句確認兩個 arm 真的載入不同
prompt，再花 opus 的錢。**快慢看 `result.duration_api_ms` 不看 wall**：2026-10-02 五發實測 api 58–84s、
非模型開銷 35–170s，用 wall 做 n=1 比較會得到相反結論。**命中數也要 n≥2**：單發 reviewer 命中的是隨機
子集，五發各中 3 項中的 2 項、子集還不同。
**量 Task 派出的 subagent 時**：它跑的是 agent 定義裡的 `model`，父 session 的 `--model` 不影響它
（實測 haiku 父 session 派 code-reviewer，subagent 的 `message.model` 是 `claude-opus-5-5`）——
父層可以用 haiku 省錢，但別誤以為那樣是在測 haiku 的 reviewer。數字的位置：subagent 自己的
`duration_ms`／`tool_uses`／`total_tokens` 在「帶 `output_file` 的 task 記錄」的 `usage`
（`jq -c 'select(.output_file!=null)|.usage'`），`result.subagent_stats` 只有 spawned/completed 計數、
沒有時間；subagent 的訊息靠 `parent_tool_use_id != null` 認（每則有 `timestamp`）；**父 session 會有兩筆
`result`**（`result_index` 0 與 1 —— subagent 在背景跑，父層先結束一輪、它完成後再被喚起），
只取第一筆會少算整體時間；要讓 subagent 的文字進 jsonl 加 `--forward-subagent-text`。

## 已知的坑

（原根目錄 CLAUDE.md「新增 Agent 步驟」第 5 步最後的「量測前先關掉 advisor」、「開發本 repo」的「沙盒用 `claude -p` 測行為前」一條，與「注意事項」裡跑實驗才遇到的幾條）

- **量測前先關掉 advisor**：`~/.claude/settings.json` 設了 `advisorModel` 時，`claude -p` 的 session 會自己叫 advisor（另一個模型），
  assistant 訊息的 `message.model` 看不到它，只出現在 result 的 `modelUsage` 鍵，它的費用與等待時間會算進那一發。
  `--disallowedTools advisor` 擋不掉，要加 `--settings '{"advisorModel":""}'`；跑完再讀 `modelUsage` 的鍵核一次
- **沙盒用 `claude -p` 測行為前，先 `./install-dd-pipeline.sh --force`**：headless session 載入的是
  `~/.claude/` 的部署版，不是 repo 這份。2026-10-02 踩過：dd-init 的 rev 跳 5 → 6 後直接去沙盒跑
  `/dd-init`，它回「含 `dd-loop-rev: 5` → 已是現行版，跳過」—— 那是**舊版的正確行為**，看起來卻像
  新版判定壞了。部署後重跑才判為舊版並列出 rev 5 缺的兩條
- **`claude -p` 的 stream-json 要進 repo 前先去識別，而且要認得 Claude Code 自己編碼過的路徑**：init 訊息的 `memory_paths` 等欄位
  把路徑裡的 `/` 換成 `-`（`-Users-<名字>-…`、`-private-tmp-…`），只換斜線形式、只 grep `/Users/` 都抓不到，還會回 0 筆看起來像通過。
  init 另有連接器清單、plugin 路徑。做法：只抽判定要用的欄位（照 `docs/measurements/2026-10-29-adhd-style/run.sh`），掃描樣式加 `-Users-`、`-private-tmp-`。
- **`claude -p` 實驗的 fixture 有子目錄時，子目錄的 CLAUDE.md 會被受測 session 當巢狀記憶讀進去**：gate 對 `docs/measurements/` 底下
  放 `.py`／`.sh` 的目錄一樣要求 CLAUDE.md（2026-10-30 在另一台機器的 branch 實測，第一次 commit 就被擋），所以檔照寫，
  `run.sh` 把 fixture 複製到拋棄式目錄後跑 `find "$WORK" -mindepth 2 -name CLAUDE.md -delete`。fixture 由 `run.sh` 當場 `printf` 出來、
  不從 repo 複製的（`docs/measurements/2026-10-29-adhd-style/run.sh`）碰不到。
- **stream-json 看不出巢狀 CLAUDE.md 有沒有被讀進去**：grep jsonl 找那份 CLAUDE.md 獨有的字串，連會載入的對照臂也是 0。
  改成叫受測 session 照貼 context 裡出現的 CLAUDE.md 路徑與第一行，並配一個「skill 目錄放在 cwd 專案裡」的對照臂：對照臂報得出來，這個查法才有鑑別力
  （2026-11-14 `docs/measurements/2026-11-14-security-audit-trigger/` 的 inj、injctrl）
- **dontAsk 加 `Bash(ls:*)` 照樣擋 cwd 外的路徑**：`ls ~/…` 回 denial，加 `--add-dir <那個目錄>` 才放行（同一次的 probe-ls、probe-ls2）；
  複合指令要每一段都在白名單，受測 session 常把 `git`、`echo`、`ls` 串成一條而被擋（同一次的 d5b 兩發）
- **用 auto mode 跑 `claude -p` 時，受測 session 自己到 `/tmp` 開副本做實驗會被擋**，`permission_denials` 不為 0：擋它的是 auto mode 的分類器
  （理由字串 `[Shared Scratch Sweep]`），不是目錄白名單，`--add-dir /tmp /private/tmp` 照樣擋（2026-10-30 同一次實測，denial 2 → 3；本機沒重現）。
  `docs/measurements/2026-10-29-adhd-style/run.sh` 用的是 `--permission-mode dontAsk`，它會不會經過這個分類器沒驗證；判準要求 denials=0 時，先決定用哪個 mode 再跑。
- **`claude -p` 在父 session 最後一輪結束 10 分鐘後，會把還在跑的背景 subagent 停掉**：stderr 印 `Background tasks still running 10m after the last turn (…); stopping them`，
  父 log 照樣有 `subtype: success` 的 result，subagent 的紀錄檔停在一半、沒有最後的報告。要等超過 10 分鐘的 subagent（例如裁決者再派審查者）時設
  `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0`（2.1.325 實測；2026-11-15 `docs/measurements/2026-11-15-reviewer-effort/run.sh`）；跑完 grep stderr 有沒有那句（那支 `run.sh` 用 `2>&1` 把 stderr 併進父 log；stderr 另存的要 grep 那個檔）
- **受測 session 的快照放在 scratchpad 底下時，它找得到 scratchpad 裡別的檔**：2026-11-15 有個審查者 `cd` 到快照的上三層（暫存區的根）去 `find` 計畫提到的探針腳本。
  洩題檢查要掃「快照以外的暫存區絕對路徑」，只認家目錄、`../` 會漏（那個目錄的 `outside.py`）；答案檔不要跟快照放在同一棵暫存樹下
