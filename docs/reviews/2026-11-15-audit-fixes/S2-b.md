# S2 審查 — B（task-planner 與 dd-loop 的 BLOCKED 流程）

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

> 你是 8 步開發迴圈步驟 4 的審查者 B。職責：找漏洞，每條附證據（檔案與那幾行的原文，或你跑的指令與輸出）；沒證據的不算。不寫優點。
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
> 你的方向：task-planner 規則區塊與 dd-loop 新增的 BLOCKED 那一條。照文字走一遍「一段做到一半先停、去做別段、再回頭做完」的整個流程（含同一段第二次先停、這段還沒有任何 commit 就先停、專案沒有 `docs/reviews/`、報告放在子目錄、SKIP 欠帳還沒補），對照 gate 的 `--start-segment` 實際怎麼擋、`docs/reviews/CLAUDE.md` 怎麼寫：有沒有哪一步照做會被擋而文字沒講、或文字要求的事 gate 其實不需要、或回頭做完時步驟 4 的範圍／報告會漏。也看這兩處文字跟別處講 BLOCKED 的地方（規則區塊其他幾條、全域模板 §4.4、dd-loop 其他段落、scripts/CLAUDE.md）有沒有矛盾，以及規則區塊這一條變長之後有沒有把原本的條件改掉（對照 diff 的舊句與新句）。
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

> Critical 0 / Important 1 / Smells 3：範圍是 `git diff f4e15a0..HEAD`（9afb1eb）中 task-planner 規則區塊與 dd-loop 新增的 BLOCKED 那條
>
> 【發現】
> B1｜Important｜新一張進度表的第一段，在還沒有任何報告時就先停，「放哪個子目錄」照規則區塊這句判不出來。結果可能放到根目錄，或放到別張表的子目錄。
> - 證據：task-planner 規則區塊（審查包第 3 部分第 140 行）寫的是「同一個 commit 加一份 `docs/reviews/S<段落>-BLOCKED.md`（別的報告放在子目錄就放同一個子目錄）」。`docs/reviews/CLAUDE.md:16` 的規定是「之後每張表開一個 `<進度表檔名去掉 -design.md>/` 子目錄」。`ls docs/reviews` 看得到：根目錄只有 `S6-a.md`、`S6-b.md`，其餘都在各表自己的子目錄，例如 `2026-11-15-speed-cost/` 裡已經有 S1–S3 的報告。
> - 失敗情境：新表的 S1 做到一半先停，這張表自己還沒有報告。這時「別的報告」只能指別張表的報告。session 讀到的是照抄進設計文件的那份規則區塊，不一定讀過 `docs/reviews/CLAUDE.md`。它可能寫進最近那張表的子目錄，例如 `2026-11-15-speed-cost/S1-BLOCKED.md`，申報就掛到別張表名下。如果那裡已經有同名檔，就會蓋掉那張表的申報：`git status` 顯示 `M`，gate 用 `--diff-filter=A` 不認修改，所以會再擋一次（`docs/reviews/CLAUDE.md:53`）。
> - 建議：括號改成「放進這張進度表的子目錄 `docs/reviews/<進度表檔名去掉 -design.md>/`（這張表的報告都放那裡；寫之前先 `ls`）」。dd-loop 新增那條也補上同一句。
>
> B2｜Smell｜「這段已經有 commit 時」這個條件和 gate 的判定對不上，兩邊都有落差，但 gate 都不會靜默放行。
> - 證據：gate 的 `reviews_missing` 有一行 `[ "$base" = "$head_sha" ] && return 1`。gate 看的是「從上一次 `--start-segment` 到現在有沒有 commit」，不是「這段曾經有過 commit」。
> - 情境 a（文字要求了 gate 不需要的事）：回頭做這段、重跑 `--start-segment` 之後，還沒 commit 就第二次先停。這時「這段已經有 commit」成立，文字要求建 `-BLOCKED-2.md`，gate 其實會放行。
> - 情境 b（文字沒講）：這段沒有 commit、也沒有 SKIP 欠帳時，規則區塊沒說 `BLOCKED` 狀態的修改要不要 commit，也沒說「同一個 commit」指哪一個（因為沒有補 CLAUDE.md 的那個 commit）。如果 session 把狀態修改單獨 commit，就變成「已經有 commit」，`--start-segment` 會擋。不過擋下時印的第 3 條路救得回來（V3 的乾跑臂就是這樣走的）。
> - 建議：條件改成「上次 `--start-segment` 之後已經有 commit，或這次先停要 commit 進度表時」，再補一句「狀態修改跟申報檔放同一個 commit」。
>
> B3｜Smell｜三處對申報檔內容的要求不一樣。
> - 證據：`docs/reviews/CLAUDE.md:47` 要求寫「停在哪個小任務、為什麼停、先停之前已經 commit 的範圍（進度表 commits 欄的起點到當時的 HEAD）」。task-planner 只寫「停在哪個小任務、為什麼停」。dd-loop（審查包第 104 行）寫「停在哪、為什麼停」。
> - 失敗情境：照規則區塊做的 session 不會寫 commit 範圍。範圍在進度表上查得到，所以不影響正確性；問題是三份文件互相不一致。
> - 建議：兩份 SKILL.md 都補上「先停之前已經 commit 的範圍」，或者改成指向 `docs/reviews/CLAUDE.md`。
>
> B4｜Smell｜本 repo 自己正在用的設計文件，規則區塊還是舊句。
> - 證據：`docs/designs/2026-11-15-audit-fixes-design.md:45` 的 `BLOCKED` 那條仍是舊版，沒有申報檔那段。這份文件在這次 diff 裡有被改到，表上 S3、S4 還是 TODO，而本 repo 有 `docs/reviews/`。CHANGELOG 的 ⚠️ 自己就叫正在用的專案「自己把這一句補進設計文件」，本 repo 沒有補。
> - 補救管道還在：gate 擋下時會印第 3 條路。
> - 建議：把那一句同步進本 repo 的設計文件。
>
> 【Not reported】
> - 舊句的三個條件（補 SKIP 欠帳、回頭時範圍從表上這段的起點算、依賴沒完成維持 TODO）新句都原樣保留，沒有被改掉。
> - SKIP 欠帳還沒補：gate 先查 `owed_dirs` 再查 `reviews_missing`。把補 CLAUDE.md 和申報檔放進同一個 commit，兩個擋點一次解掉，順序沒有問題。
> - 這段還沒有任何 commit 就先停：起點等於 HEAD 時 `reviews_missing` 回 1、不擋，所以文字寫「不用申報檔」是對的（另一個方向的落差見 B2）。
> - 專案沒有 `docs/reviews/`：`[ -d docs/reviews ] || return 1`，條件和 gate 一致。
> - 報告放在子目錄：gate 的樣式 `(^|/)S[0-9][^/]*\.md$` 認得子目錄底下的檔。半號段落的 `S2.5-BLOCKED.md` 也命中。
> - 回頭做完時步驟 4 的範圍：用表上的起點，涵蓋先停之前的 commit，另外會多審插進來那段的 commit，只會多審不會漏。下一次開段，gate 查的是回頭時重跑 `--start-segment` 之後的範圍，會要求新增報告（`S1-a.md` 等）。這需要回頭時重跑 `--start-segment`，開工那條的括號已經涵蓋。
> - 第二次先停要新增 `-BLOCKED-2.md`：和 gate 的 `--diff-filter=A`、`docs/reviews/CLAUDE.md`、scripts/CLAUDE.md 三處一致。
> - 和「下一段：有段落 BLOCKED 時先停下來問使用者」不矛盾：那條管的是 session 自己跳段，`BLOCKED` 那條管的是使用者要求。全域模板（`templates/global/CLAUDE.md`）裡沒有提到 BLOCKED。
> - dd-loop 第 24 行「不要重跑 `--start-segment`」只在 `--segment-base` exit 非 0 時適用，不會擋到回頭時的開工。
>
> 【What I ran】
> - Read `prompt-b.txt` → 派工內容
> - Read `s2-review-pack.txt` 第 1–300 行、第 301–568 行 → 讀到最後一行
> - `grep -n 'start-segment|BLOCKED|reviews…' scripts/check-claude-md.sh` 加上讀 `docs/reviews/CLAUDE.md` 前 80 行 → 拿到 gate 擋點的行號與 reviews 規則
> - Read `scripts/check-claude-md.sh` 第 95–294 行 → `resolve_fork_base`、`reviews_missing`、`--start-segment` 與 `--segment-base` 兩支
> - `grep -n BLOCKED` 跑在設計文件、`templates/global/CLAUDE.md`、兩份 README、`DD_PIPELINE_ARCHITECTURE.md`、`UPGRADING.md`、`commands/dd-init.md`，另外 `ls docs/reviews` 與 `find docs/reviews -name '*BLOCKED*'` → 設計文件第 45 行是舊句；repo 裡還沒有任何 BLOCKED 檔
> - `grep -n` 跑在 `docs/reviews/CLAUDE.md`，另外 `ls` 兩個 2026-11-15 的子目錄 → 第 16、47、53 行；兩個子目錄的內容
>
> 【需要外部查證】
> 無。

## 處置

每一條都讀了它引的位置或重跑了它的指令。

- **B1（Important，採納）**：屬實（`docs/reviews/CLAUDE.md` 的做法是每張表一個子目錄；`ls docs/reviews` 根目錄只有 `S6-a.md`、`S6-b.md`）。原句「別的報告放在子目錄就放同一個子目錄」在新表第一段先停時指不到東西。改成：位置照專案 `docs/reviews/CLAUDE.md` 的規定，專案有好幾張進度表時放這張表自己的子目錄、不要放進別張表的，寫之前先 `ls`。dd-loop 那一條同步。
  改完重跑乾跑（拋棄式 repo 另有一張舊表的子目錄，裡面已經有同名的 `S1-BLOCKED.md`）：申報檔建在 `docs/reviews/2026-11-01-demo/`，舊表那份的 `git hash-object` 與乾跑前相同。
- **B2（Smells，採納）**：屬實（`reviews_missing` 看的是起點到 HEAD 之間有沒有 commit）。條件從「這段已經有 commit 時」改成「專案有 `docs/reviews/` 目錄時，先停還要 commit 一份申報檔（跟進度表標 `BLOCKED` 的改動、補的 CLAUDE.md 放同一個 commit）」——這樣寫在兩種情境下 gate 都不會擋；代價是「這段一個 commit 都沒有」時多一份其實不需要的申報檔。
  加跑一臂（S1 剛開工、一個 commit 都沒有就先停）：它把設計文件與申報檔放進同一個 commit，之後 `--start-segment` exit 0。
- **B3（Smells，採納）**：屬實。兩份 SKILL.md 都補上「先停之前已經 commit 的範圍」，跟 `docs/reviews/CLAUDE.md` 一致。
- **B4（Smells，採納）**：屬實。本 repo 設計文件進度表下方照抄的規則區塊，`BLOCKED` 那一條換成新句（用腳本從 `skills/task-planner/SKILL.md` 取同一行，不手抄）；假設 A7 的句子跟著改。
- Not reported：都同意，沒有動作。
