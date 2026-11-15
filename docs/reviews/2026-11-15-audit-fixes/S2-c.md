# S2 審查 — C（dd-init Phase 4 與文件裡的宣稱）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S2（流程文字：dd-loop 取不到起點的下一步、task-planner 的 BLOCKED、dd-init Phase 4）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。

審查包（scratchpad 的 `s2-review-pack.txt`，567 行，沒進 repo）的組成：
- 第 1 部分：`git diff f4e15a0`（起點）到工作目錄的整段 diff，HEAD = 9afb1eb，工作目錄乾淨
- 第 2 部分：步驟 3 沒有跑（這一段的 diff 全是 Markdown，沒有程式碼）
- 第 3 部分：`skills/dd-loop/SKILL.md`、`skills/code-simplifier/SKILL.md`、`skills/task-planner/SKILL.md` 的整檔與 `commands/dd-init.md` 的 Phase 4（帶行號）
- 第 4 部分：已跑過的驗證 V1–V9（三組乾跑的做法、預期與指令核對的結果；`claude plugin --help` 列的子指令；`jq` 的 `//` 實測；本機照 ci.yml 逐 step 跑 26 個 rc=0；`$<數字>` 自查 0 筆；dd-loop 認的四串字在 gate 裡的命中數）

其他被改到的文件（scripts/CLAUDE.md、CHANGELOG、設計文件）沒有放整檔：步驟 4 期間沒有人改工作目錄，派工 prompt 寫明那幾份直接讀工作目錄。

派工 prompt（逐字，審查者拿到的是一句「先讀這個檔再照做」加這個檔的路徑）：

> 你是 8 步開發迴圈步驟 4 的審查者 C。職責：找漏洞，每條附證據（檔案與那幾行的原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。
>
> Repo：/Volumes/T7/home/project/my_project/claude-dd（專案規則在根目錄與各層的 CLAUDE.md；本段相關的是根目錄 CLAUDE.md、scripts/CLAUDE.md、docs/reviews/CLAUDE.md）。
>
> 審查範圍：`git diff f4e15a0` 到工作目錄（4 個 commit，工作目錄乾淨）。這一段沒有改程式碼，改的是 Claude 會照著做的指令文字：`skills/dd-loop/SKILL.md`、`skills/code-simplifier/SKILL.md`、`skills/task-planner/SKILL.md`、`commands/dd-init.md` 的 Phase 4，以及說明它們的文件（scripts/CLAUDE.md 一句、CHANGELOG.md、docs/designs/2026-11-15-audit-fixes-design.md）。
>
> 審查包：/private/tmp/claude-501/-Volumes-T7-home-project-my-project-claude-dd/f691d75a-d904-4c64-916c-d3b4d3714db8/scratchpad/s2-review-pack.txt
> （共 567 行。用 Read 的 offset/limit 每次 300 行讀到最後一行：Read 一次讀太多會靜靜截斷、不報錯。）
> 組成：第 1 部分整段 diff；第 2 部分步驟 3 的狀況；第 3 部分三份 SKILL.md 的整檔與 dd-init.md 的 Phase 4（帶行號）；第 4 部分已經跑過的驗證（做法、預期、實際）。
> - 第 3 部分那幾個檔一律讀審查包裡那一份。其他被改到的文件（scripts/CLAUDE.md、CHANGELOG.md、設計文件）工作目錄就是被審的版本，審查期間沒有人會改，可以直接讀；沒被改到的檔（例如 scripts/check-claude-md.sh、install-dd-pipeline.sh、templates/global/CLAUDE.md、docs/reviews/CLAUDE.md、兩份 README）照常讀。
> - 第 4 部分的驗證已確認，不要重跑 CI、整支測試或那幾個乾跑。要查證某一條具體懷疑時，可以在你自己的暫存目錄開拋棄式 git repo 跑 gate（`/Volumes/T7/home/project/my_project/claude-dd/scripts/check-claude-md.sh`）；不要改 repo 裡的任何檔、不要 commit、不要跑 `./install-dd-pipeline.sh`（連 `--check` 都不要）、不要跑 `claude plugin` 的任何子指令、不要讀或印 `~/.claude/settings.json` 的內容。
> - 只用手上的資料判斷；需要外部查證（上網、別的機器、別的版本）的列出來交回。
>
> 這一段改了什麼（事實，不是我的判斷）：
> 1. dd-loop「段落起點與 `<起點>`」：新增一段，寫 `--segment-base` exit 非 0 之後的下一步（有進度表用表上的起點；沒有進度表照 gate 印在 stderr 的那一句分情況；不要重跑 `--start-segment`；取到之後步驟 3、4、8 用同一個值）。步驟 8 結尾那句補上「照上方那段取到起點，把 `base=` 換掉再跑」。code-simplifier「取不到起點」那句同步。
> 2. task-planner 進度表規則區塊的 `BLOCKED` 那條：補上專案有 `docs/reviews/`、這段已經有 commit 時要加 `docs/reviews/S<段落>-BLOCKED.md`（第二次先停另建 `-BLOCKED-2.md`），回頭做完時步驟 4 照跑。dd-loop「報告一律落地」底下新增一條講同一件事。
> 3. dd-init Phase 4 第 1 項：從「`enabledPlugins` 是否含」改成解析 JSON 看值是不是 `true`；提示從「`./install-dd-pipeline.sh --force`（腳本會裝）或 `claude plugin install`」改成停用給 `claude plugin enable`、沒有鍵給 `claude plugin install`、不提示跑安裝腳本。
> gate 這三處對應的行為是上一段（S1，commit 9d77062..5927484）改的，說明在 scripts/CLAUDE.md。
>
> 你的方向：dd-init Phase 4 的新文字，以及這一段文件裡的宣稱。①Phase 4：對照 `install-dd-pipeline.sh` 的 `install_plugins()`、`plugin_enabled_state()` 與兩份 README 的前置需求段，新文字講安裝腳本的那句對不對；各種 settings.json 形狀（頂層不是物件、`enabledPlugins` 是 null 或不是物件、值是字串 "true"、檔案不存在）照文字會判成什麼、合不合理；`commands/dd-init.md` 其他 Phase 或結尾摘要有沒有還照舊說法寫的地方。②文件宣稱：CHANGELOG 新增的三條、scripts/CLAUDE.md 改的那一句、設計文件 S2 底下新增的乾跑紀錄與「與計畫不同的三處」——每一句對回程式碼、對回第 4 部分的驗證，找寫得比實際做的多、或引到別處而別處不是那樣的句子。
>
> 級別：Critical（照文字做會弄壞資料／歷史，或讓該跑的審查、該擋的 commit 靜靜被跳過）／Important（文字或文件宣稱是錯的，照做會出錯）／Smells（不影響正確性）。
>
> 交回格式（直接用文字交回，不要寫報告檔）：
> 【發現】每條：編號｜級別｜一句話內容｜證據（檔案與原文，或指令與輸出）｜建議怎麼改
> 【Not reported】看過、判定不是問題的（每條一句理由）
> 【What I ran】跑過的指令與讀過的檔
> 【需要外部查證】

## 發現

審查者交回的原文（逐字；C 那份交回時 harness 在最前面加了一行說明，沒有收進來）：

> Critical 0 / Important 2 / Smells 1 — 範圍：`git diff f4e15a0`（第 1 部分的 7 個檔），重點看 dd-init Phase 4 與文件裡的宣稱
>
> 【發現】
> 1｜Important｜Phase 4 叫人「用 `jq` 讀，看值是不是 `true`」。可是 `jq -r` 讀到字串 `"true"` 和讀到布林 `true` 印出來一模一樣，照字面做會把字串 `"true"` 判成「已啟用」。文字只警告了 `//`，沒警告這個。另外值是 `null`、`1` 這類「不是 true、也不是 false、鍵也在」的情況，三條分支都接不到。安裝腳本的 `plugin_enabled_state()` 用 `== true` / `== false` 比較，這類值落到 `none`，也就是未啟用。｜證據：拋棄式目錄實跑 `printf '{"enabledPlugins":{"k":"true"}}' > f.json; jq -r '.enabledPlugins["k"]' f.json` 印出 `true`；`install-dd-pipeline.sh` 第 539–541 行 `elif $e[$key] == true then "enabled" elif $e[$key] == false then "disabled" else "none"`；Phase 4 第 302–305 行只寫了「值是 `false`」與「沒有這個鍵…」兩條分支｜建議：改成「型別是布林而且等於 `true` 才算啟用（jq 用 `== true`，不要用 `-r` 看印出的字）；其他值一律算未啟用」，或直接對齊 `plugin_enabled_state()` 的 enabled/disabled/none 三分法。
>
> 2｜Important｜Phase 4 寫「檔案解析不了就照實說『無從判定』」，但用 `jq` 讀空檔時什麼都不印、也不報錯，看不出解析失敗。照文字做，會落到「沒有這個鍵 → 未啟用 → 提示 `claude plugin install`」，跟文字要求的「無從判定」相反。本 repo 根目錄 CLAUDE.md 自己也記過這個坑（「空檔時 jq 回報成功而檔案沒寫」）。檔案裡不只一個 JSON 值時，不加 `-s` 的 jq 會逐個印，也同樣看不出問題。｜證據：同一個拋棄式目錄 `printf '' > f.json; jq -r '.enabledPlugins["k"]' f.json` 沒有任何輸出、沒有錯誤訊息；`plugin_enabled_state()` 第 563–564 行把空輸出判成 `unparseable`（「空輸出 = 解析失敗或空檔」）；V4 的「壞檔」臂用的是截斷的檔，不是空檔｜建議：補一句「空檔、輸出是空的、或檔案裡不只一個 JSON 值，都算解析不了」，或叫它用 `python3 -c 'json.load…'` 判斷，或用 `jq -s` 先確認剛好一個物件。
>
> 3｜Smell｜設計文件 S2-3「與計畫不同的三處」②寫「一句話講不準，改成只寫『安裝腳本不下載 plugin 的檔案，不要提示跑它就會裝』」，但實際文字（dd-init.md 第 306 行）還多了「只把本機已經有的登記起來並設成啟用」，正是②說講不準的那一句。這句本身大致對：README 兩份第 39/40 行寫「只登記已在磁碟上找得到的」，`install_plugins()` 第 937、978 行另外要求 marketplace 目錄有 `plugin.json`、而且拿得到版本字串。問題是設計文件描述的改法和實際落地的不一致。｜證據：design doc 第 82 行 vs dd-init.md 第 306 行｜建議：設計文件②改成照實描述，或把第 306 行後半句刪掉。
>
> 【Not reported】
> - Phase 4 講安裝腳本的那句：對照 `install_plugins()`（沒有任何下載動作，只寫 installed_plugins.json 與 `enabledPlugins[$key]=true`）和兩份 README 前置需求段，「不下載」是對的。
> - 停用的 plugin 其實重跑安裝腳本也會被設回啟用（第 1016 行），但 Phase 4 選擇兩種情況都不提示腳本，不會讓人做錯事。
> - 頂層是陣列、`enabledPlugins` 是陣列時，jq 會直接報錯（`Cannot index array`），一般會被讀成「解析不了」，跟 `plugin_enabled_state()` 的 `unparseable` 或 `none` 至少不會誤判成已啟用；`enabledPlugins: null` 落在「沒有 enabledPlugins」那條，和腳本的 `none` 一致。
> - dd-init.md 其他地方沒有殘留舊說法：Phase 6 摘要只寫「claude-md-management plugin 檢查」，第 152 行是講 plugin 的用途。
> - Phase 4（第 299 行起）在蓋章區塊（127–165、171–184 行）之外，CHANGELOG 寫「不跳 rev」是成立的。
> - dd-loop 新段認的四串字都對得上 gate 第 261、276、281、283 行；「找不到共同祖先」是「也找不到共同祖先」的子字串，對得上。「沒記過」那支 gate 印的是「先跑 --start-segment」，跟 dd-loop 叫人「問使用者、不要重跑」的指示相反，但 dd-loop 那句是明確寫給 exit 非 0 的情況，V2 也驗過模型會照 dd-loop 做。
> - scripts/CLAUDE.md 改的那句、CHANGELOG 新增的三條、code-simplifier 那句，對回 gate 程式碼與 V1–V9 都一致。
> - task-planner 的「這段已經有 commit 時」：沒有 commit 時範圍是空的，`reviews_missing` 回「不缺」（scripts/CLAUDE.md 有記），所以這個條件是對的。
>
> 【What I ran】
> - Read 派工檔 prompt-c.txt、審查包 s2-review-pack.txt（1–300、300–567 行，讀到結尾）
> - `grep -n` 找安裝腳本的 plugin 函式與 dd-init.md 裡提到安裝腳本、plugin 的地方 → 找到 `plugin_enabled_state` 在 525 行、`install_plugins` 在 873 行，dd-init 相關的有 86、101、152、206、209、301–306、360、382 行
> - Read install-dd-pipeline.sh 515–604、860–1029 行
> - grep 兩份 README 的 plugin install／下載字樣，讀 dd-init.md 340–400 行（Phase 6）
> - grep gate 的 segment-base 訊息，Read scripts/check-claude-md.sh 250–294 行
> - `grep -n '^```'` 與 `'^````'` 查 dd-init.md 蓋章區塊 → 127/165、171/184 行；`git diff f4e15a0 --stat` → 7 個檔
> - 在 scratchpad/rc 用 jq 跑五種 settings 形狀：`[]` → 報錯；`enabledPlugins:null` → 印 `null`；`enabledPlugins:[]` → 報錯；值是字串 `"true"` → 印 `true`；空檔 → 沒有輸出
>
> 【需要外部查證】
> - Claude Code 怎麼看 `enabledPlugins` 裡值是字串 `"true"` 的鍵（算不算啟用）：要看官方文件或實測，這決定第 1 條的嚴重程度。
> - plugin 只在專案層的 `.claude/settings.json` 或 `settings.local.json` 啟用時，Phase 4 只讀 `~/.claude/settings.json`，會判成未啟用並提示 `claude plugin install`；而 plugin 已經裝過時，`claude plugin install` 會怎麼做沒有實跑過。
>
> 拋棄式實驗目錄：/private/tmp/claude-501/-Volumes-T7-home-project-my-project-claude-dd/f691d75a-d904-4c64-916c-d3b4d3714db8/scratchpad/rc

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實（重跑審查者的指令：字串 `"true"` 用 `jq -r` 印出 `true`；`== true` 回 `false`）。
- **2（Important，採納）**：屬實（空檔時 `jq -r '.enabledPlugins["k"]'` 沒有輸出、rc=0）。
  兩條一起處理：Phase 4 不再讓模型自己寫 `jq`，直接附一條指令，判法跟安裝腳本的 `plugin_enabled_state()` 相同（`-s` 收成陣列、剛好一個物件、布林比較），四種輸出各對一個動作；檔案不存在另外寫。
  拿 12 份假設定檔（true、false、沒有鍵、截斷、空檔、字串 "true"、頂層陣列、兩個 JSON 值、`enabledPlugins` 是 null／陣列／不存在、值是 1）跑文件裡那條指令，結論與 `plugin_enabled_state()` 逐份相同（截斷那份指令失敗、沒有輸出，文件把它歸在「無從判定」）。文件裡的指令與測過的那一份用 `diff` 比過，逐字相同。
  改完重跑三臂（false、空檔、字串 "true"）：依序是未啟用並提示 `claude plugin enable`、無從判定、未啟用並提示 `claude plugin install`（把實際的值講出來）。
- **3（Smells，採納）**：屬實。定稿的 Phase 4 只剩「安裝腳本不下載 plugin 的檔案」，設計文件 ② 改成照實描述。
- 需要外部查證的兩條都查不了（一條要官方文件或實測 Claude Code 怎麼看字串值，一條要實跑 `claude plugin install`，會改真實的 `~/.claude`）：
  第一條靠新指令繞開（字串值一律算未啟用，並把實際的值告訴使用者）；第二條只做到文字層面 —— Phase 4 加一句「只讀了 `~/.claude/settings.json` 一個檔，提示不要講成確定沒裝」。兩條都記在 `S2-judge.md` 的「需要外部查證」。
- Not reported：都同意，沒有動作。
