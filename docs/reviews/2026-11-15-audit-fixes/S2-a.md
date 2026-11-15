# S2 審查 — A（dd-loop 與 code-simplifier 的新文字對不對得上 gate）

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

> 你是 8 步開發迴圈步驟 4 的審查者 A。職責：找漏洞，每條附證據（檔案與那幾行的原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。
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
> 你的方向：dd-loop 與 code-simplifier 的新文字對不對得上 gate 的實際行為。逐一拿 `scripts/check-claude-md.sh --segment-base` 的每一種結果（成功、四種失敗、`dd.docfile` 不合法時的提早結束）與「有／沒有進度表」的組合，照文字走一遍：有沒有哪一種組合文字沒講、講錯、或照做會讓步驟 3、4、8 的範圍漏掉這一段的 commit。也看新段落跟同一份 SKILL.md 其他段落（忘了記起點、從沒跑過 `--start-segment` 的專案、有進度表時、步驟 8 的指令）有沒有互相矛盾，以及全域模板 `templates/global/CLAUDE.md` §3.9 講 `<起點>` 的那幾句（這一段刻意沒改它）跟新文字有沒有打架。
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

> Critical 0 / Important 1 / Smells 1。範圍：`git diff f4e15a0`，只看 dd-loop 與 code-simplifier 的新文字跟 gate `--segment-base` 的實際行為對不對得上。
>
> 【發現】
> 1｜Important｜code-simplifier「取不到起點」那一支叫人去問「範圍不明」那一題，但那一題問的不是起點，而且它的預設答案會把範圍縮窄。dd-loop 這次新加了「3、4、8 用同一個值」，這一題交不出那個值，兩份 skill 在同一個情況下要人問的題目不一樣。
>   - 證據：審查包裡 `skills/code-simplifier/SKILL.md`。
>     - 第 16 行是「取不到起點（指令 exit 非 0 或輸出是空的）時當成「範圍不明」問一題」。
>     - 第 22 行是「**範圍不明**：問一題 —「要簡化哪個範圍？（預設：最近修改的檔案）」」。
>     - `skills/dd-loop/SKILL.md` 第 26 行（沒記過的情況）是「問使用者這一段從哪個 commit 開始」。
>     - dd-loop 第 29 行是「問到或取到起點之後,這一段剩下的步驟(3、4、8)都用同一個值」。
>   - 失敗情境：沒有進度表、從沒記過起點（gate 印「沒記過」），或「找不到共同祖先」。步驟 3 照 code-simplifier 問了，使用者接受預設的「最近修改的檔案」，步驟 3 就只審最近改的檔，跟「不要退回 `HEAD~1`」的本意相反。這一題也沒問出起點 sha，步驟 4、8 沒有「同一個值」可用，得再問一次，或各自拿不同的範圍。
>   - 建議：第 16 行取不到起點那一支改成「照 dd-loop『段落起點與 `<起點>`』那段問『這一段從哪個 commit 開始』」，不要指到第 22 行那一題。
>
> 【Smells】
> S1｜dd-loop 第 25–28 行只列 stderr 的四串字，沒講 gate 提早結束的情況。這兩種情況下 stderr 是空的、錯誤印在 stdout，照文字會找不到對應的那一句：
>   - `dd.docfile` 不合法：`scripts/check-claude-md.sh` 第 32、46 行的 echo 沒有 `>&2`。
>   - 不在 git repo 內：第 20 行。
>   - 不影響正確性：同一支 gate 在 pre-commit 也會 exit 1，步驟 6 的 commit 一定被擋，問題會浮出來，不會靜靜漏掉。
>   - 建議：補一句「四串字都沒有時，照 stdout 那句錯誤先修好 gate 設定，再重跑 `--segment-base`」。
>
> 【Not reported】
> - 成功（exit 0，含空樹起點，第 265–273 行）：文字直接用輸出，對得上。
> - 沒記過（第 260–262 行）：分支和字串都對得上。gate 自己印「段落開始前先跑 --start-segment」，跟 dd-loop「不要順手重跑」不矛盾：前者講段落開始前，後者講段落中途。
> - 有共同祖先（第 274–279 行）：stderr 有「共同祖先是 ${fork}」；「不會漏、只會多」跟 gate 第 276 行與 scripts/CLAUDE.md 的實跑紀錄一致。
> - 找不到共同祖先、內容不是 commit（第 281–286 行）：gate 說改用進度表、沒有就問使用者，跟 dd-loop 第 25、28 行一致。
> - 有進度表的四種組合：都用表上的起點，跟第 35–40 行與 code-simplifier 第 17 行一致。起點被 amend 時，表上的 sha 雖然已經不在分支上，`git diff <舊 sha>` 是比 tree，不會漏這一段的 commit。只有那個物件被 gc 清掉才會壞：amend 掉的 commit 還在 reflog 裡，要手動 prune 或放到過期才會發生，太牽強，不列。
> - 從沒跑過 `--start-segment`、之後第一個 SKIP commit 自動補記在段落中間：第 29 行「不要中途改回 `--segment-base`」擋得住，跟第 32–34 行不矛盾。
> - 步驟 8「把 `base=` 那一段換成 `base=<那個值>`」：對得上第 125 行的寫法；有進度表時第 121 行另有規定，不衝突。
> - 全域模板 §3.9 第 244–245 行與 `commands/dd-init.md` 第 137 行：沒有進度表時是 `--segment-base` 的輸出，「其餘情況見 `dd-loop`」，跟新文字不打架。
>
> 【What I ran】
> - Read 派工 prompt-a.txt → 29 行
> - Read 審查包 s2-review-pack.txt 1–300、301–568 → 全部讀完
> - `grep -n 'segment-base|沒記過|共同祖先|…|docfile' scripts/check-claude-md.sh` → 定位第 20–48、253–288 行
> - Read scripts/check-claude-md.sh 第 20–99、250–294 行
> - `grep -n 'segment-base\|<起點>' templates/global/CLAUDE.md` + `sed -n 240,247p` → 第 239、244、249 行
> - `grep -rn 'segment-base' skills commands`（排除 dd-loop、code-simplifier）→ 只有 commands/dd-init.md:137
> - scripts/CLAUDE.md 由系統載入讀過
>
> 【需要外部查證】無

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **1（Important，採納）**：屬實。`skills/code-simplifier/SKILL.md` 的「範圍不明」那一題原文是「要簡化哪個範圍？（預設：最近修改的檔案）」，取不到起點時問它，問不出起點、預設還會把範圍縮窄。設計文件 S2-1 寫的「與 code-simplifier 那句一致」是我沒讀那一題的內容就寫的。改成：印出共同祖先就用它；其他情況問「這一段從哪個 commit 開始」，並寫明不是「範圍不明」那一題。
  改完再乾跑一臂（沒記過起點、只給 code-simplifier 的 SKILL.md）：它交回的問題是「這一段從哪個 commit 開始？」，起點檔仍不存在、沒有多出 commit。
- **S1（Smells，採納）**：屬實（gate 那兩處 `echo` 沒有 `>&2`，上一段的審查也指出過 `dd.docfile` 那一處）。dd-loop 補一句：這幾句都沒有、錯誤印在 stdout 時，照它印的先修好再重跑 `--segment-base`。
- Not reported：都同意，沒有動作。
