# S1-b（審查者 B：測試有沒有牙）— /dd-stop 指令、腳本與 gate 的暫停旗標

## 派工

subagent_type `code-reviewer`（agent 定義 opus，不帶 model 參數），四個在同一則訊息平行派出（2026-11-17），在步驟 3（code-simplifier）做完、還沒 commit 的時候。
Agent 呼叫的 prompt 只有「你的完整派工內容在這個檔，先用 Read 把它整份讀完，然後照它做」加檔案路徑，另寫明代號是 S1-b、報告用純文字照四個標題交回、不要寫成檔案。那個檔的內容如下
（絕對路徑換成 `<scratchpad>`、`<repo>`，其餘原文）：

> 你是這一段程式碼變更的審查者 S1-b。職責只有一個：找漏洞。每一條發現都要附證據（`檔案路徑` 加上你讀到的原文，或你實跑的指令與輸出）；沒有證據的不算、不要寫。不寫優點、不客套。
>
> repo：<repo>（規則在根目錄與各層 CLAUDE.md，跟你方向有關的那幾份要讀）。
> 這一段做的事：新增 `/dd-stop on|off|status` 指令 —— 暫停與恢復一個專案的 8 步開發迴圈（步驟 3–8）與 CLAUDE.md pre-commit gate。設計、使用者的決定（U1–U3）在 docs/designs/2026-11-17-dd-stop-design.md。
>
> 審查材料在這個檔：<scratchpad>/rev/S1-diff.txt（共 2153 行，最後一行是 `<<<材料結束>>>`）。
> - 用 Read 的 offset／limit 每次 300 行，讀到看見最後那一行為止（Read 一次讀太多會靜靜截斷、不報錯）。跟你方向無關的檔的 diff 可以掃過，但整份都要翻到。
> - 材料裡有 5 行超過 2000 字元（都是 CLAUDE.md 的表格列），Read 會截斷；要看那幾行就讀工作目錄的原檔。
> - 新增的檔看材料裡那一份；既有而被改到的檔要看上下文時讀工作目錄（審查期間沒有人在改）。
> - 材料第 ④ 節列的驗證已經跑過、結果已確認，不要重跑整支測試。「跑過」不代表測試寫得對 —— 測試本身也在審查範圍。
> - 你可以在 scratchpad 開拋棄式 git repo 做小實驗來證實某一條（目錄放 <scratchpad>/rev/S1-b/ 底下）。用 `/bin/bash <腳本>` 跑，不要在 zsh 裡 `source` repo 的任何腳本（`source ./install-dd-pipeline.sh` 會真的把安裝跑起來）。不要跑 `./install-dd-pipeline.sh`、不要跑 `claude -p`、不要碰真的 `~/.claude/`、不要改 repo 裡任何檔、不要 commit。
> - 只用手上的資料判斷；需要外部查證（上網、官方文件、別台機器）的列在「需要外部查證」交回，不要自己猜。
>
> 你的方向：測試有沒有牙：`tests/test-dd-stop.sh` 整支與 `tests/test-gate.sh` 說明以「⑰」開頭的那一區塊。找空洞的斷言：恆真的（快照取在被測指令之後、拿檔案跟自己比）、為了錯的理由而通過的（前一步的狀態讓它不管怎樣都過）、說明文字與實際檢查的東西對不上的、`ck 說明 指令` 的指令其實有一部分在 `ck` 外面跑的、`said`／`not_said` 的字串太短或也會被別的訊息命中的、該包在 `expect`／`run` 裡卻裸跑而會讓 `set -e` 靜靜中止整支的。再對 `scripts/CLAUDE.md` 的兩張變異對照表（「暫停旗標」條目 5 列、`dd-stop.sh` 條目那一張）：挑你懷疑的幾列，把被測腳本複製到 scratchpad 照表上說的改壞一行，用 `/bin/bash tests/test-dd-stop.sh <改壞的 dd-stop.sh>` 或 `/bin/bash tests/test-gate.sh <改壞的 gate>` 實跑，看紅的是不是表上寫的那幾則（這種單一變異的實跑可以做；輸出先導到檔案再看，不要接 `| head`）。再想 3 個表上沒有的變異（把某個行為弄壞的最小改動），看現有測試抓不抓得到 —— 抓不到的就是發現。另外看 `.github/workflows/ci.yml` 這一段加的 step 與 ShellCheck 清單、`tests/test-install.sh` 這一段加的斷言有沒有接對。
> 方向以外看到的問題照樣列，但先把方向內的查完。
>
> 每條發現標級別：Critical（照現在這樣會壞資料、會讓使用者以為暫停或恢復了而實際沒有、會靜靜漏掉該擋的東西）／Important（行為錯、文件宣稱與實際不符而會讓人照錯的做、測試斷言是空的或恆真）／Smell（不影響正確性）。
> 你判定「不是這次 diff 引入的既有問題」而不列的，放進 Not reported 並寫一句理由。
>
> 交回格式（純文字，不要寫成檔案；照這些標題）：
> 【What I ran】讀了哪些檔、跑了哪些指令（指令照貼，輸出只貼關鍵行）
> 【Findings】每條：S1-b-<序號>｜級別｜檔案與位置（用函式名、區塊名或可 grep 的原文，不要只給行號）｜問題｜證據｜會造成什麼
> 【Not reported】每條一行
> 【需要外部查證】每條一行；沒有就寫「沒有」

審查材料 `S1-diff.txt` 的四節：①`git diff 9679086 -- . ':!docs/measurements/2026-11-17-dd-stop/out'`（含步驟 3 還沒 commit 的改動）②步驟 3 自己改的（`git diff HEAD`）
③怎麼讀整檔（新增的檔看材料、既有的檔讀工作目錄）④已經跑過的驗證與預期值（`tests/test-dd-stop.sh` 131 個 ✅、`tests/test-gate.sh` 213 個 ✅、shellcheck 沒有輸出、`selftest-model.sh` 32 個 ✅、`tests/test-install.sh` exit 0、lint job 22 個 step、變異對照）。

## 發現

審查者交回的原文（派工的那個對話在查證開始前就中斷了，暫存區跟著清掉；這一份是下一個對話從那個對話的紀錄檔取回的，每行開頭的兩格縮排拿掉、絕對路徑換成 `<scratchpad>`、`<repo>`，其餘逐字）：

> 【What I ran】
> - Read：派工檔 prompt-b.txt；S1-diff.txt 全部 2153 行（每次 300 行，讀到 `<<<材料結束>>>`）；tests/test-gate.sh 第 1–80 行（helpers）；tests/test-install.sh 第 506–545 行（T5）與 T8 段（grep）；ci.yml 裡 dd-stop 相關的幾行（grep）
> - `grep -n 'GIT_CONFIG\|HOME=' tests/test-gate.sh tests/test-dd-stop.sh` → test-gate 只在 545–548、698–700 行暫設 GIT_CONFIG_GLOBAL，兩支都沒有先隔離 global config（這是既有寫法）
> - `grep -n 'dd-stop\|...' .github/workflows/ci.yml` → ShellCheck 清單第 29、38 行有兩個新檔；lint job 第 572–573 行跑 `tests/test-dd-stop.sh`；bash32 job 第 612–613 行跑 `/bin/bash tests/test-dd-stop.sh`。兩個 job 都接上了
> - 在 S1-b/ 做了變異版，`diff scripts/dd-stop.sh <變異>` 確認每個都真的改到；每個跑 `/bin/bash tests/test-dd-stop.sh <變異> > 檔`，再數 ✅、❌ 和「N 不在 git repo」：
>   - 表上的列 `off` 不清 SKIP_DOC_CHECK → rc=1，紅 2 則，都在 G2（「輸出沒提到：a/CLAUDE.md」「輸出不該提到：沒有要補的」），跟表一致
>   - 表上的列 `off` 不拿掉補的換行（`if false`）→ rc=1，紅 3 則：B 兩種結尾沒有換行的檔、K「逐位元組相同」，跟表一致
>   - gate 表上的列「壞起點檔照樣覆寫」（`/bin/bash tests/test-gate.sh g-overwrite.sh`）→ ⑰ 有 16 個 ✅，只紅「起點應為 not-a-sha」，跟表一致
>   - 新變異 N1：拿掉 unsafe_reason 的「不是一般檔」那一支 → rc=0，131 ✅，0 ❌
>   - 新變異 N2：remove_blocks 的 `cat "$tmp" > "$LOCAL_FILE"` 換成 `mv` → rc=0，131 ✅，0 ❌
>   - 新變異 N3：flag_on 拿掉 `--local` → rc=0，131 ✅，0 ❌
> - 行為實驗 `/bin/bash S1-b/exp.sh`（拋棄式 repo，用的是 repo 版 dd-stop.sh 與 gate）：
>   - CLAUDE.local.md 是目錄：原版 rc=4、旗標空的；N1 版 rc=1，印 `line 98: CLAUDE.local.md: Is a directory`，flag=true
>   - CLAUDE.local.md 是唯讀（chmod 444）：原版印 `line 100: CLAUDE.local.md: Permission denied`，rc=1，flag=true，標記段 0 份；之後 status 印「旗標…暫停中」「聲明…不在」「兩邊不一致」
>   - 原檔權限 600，跑 on 再 off：原版還是 600，mv 版變成 644
>
> 【Findings】
> S1-b-1｜Important｜scripts/dd-stop.sh `do_on`（`git config --local dd.stopped true` 在寫 `cat >> "$LOCAL_FILE" <<EOF` 之前）｜旗標先設好，才寫聲明。寫檔失敗時（唯讀檔、磁碟滿、權限不對），`set -e` 讓腳本以 exit 1 結束，旗標卻留著。exit 1 在檔頭的意思是「不在 git repo」。unsafe_reason 只查 symlink、不是一般檔、已進版控三種，不查能不能寫｜實跑唯讀檔：`line 100: CLAUDE.local.md: Permission denied`、rc=1、flag=true、標記段 0 份，status 報「兩邊不一致」｜使用者照 commands/dd-stop.md 第 3 步得到「失敗、停下」，以為沒有暫停；其實 gate 已經暫停，之後每個 commit 都放行。Claude 又讀不到聲明，照常跑迴圈。旗標要等哪天有人跑 off 或 status 才會被發現。改法：寫檔失敗就把旗標還原（或先寫聲明、再設旗標），並給一個專門的 exit 碼
> S1-b-2｜Important｜docs/designs/2026-11-17-dd-stop-design.md「實作時跟上面幾條不一樣的地方（2026-11-17 S1-2，都有測試）：…②`CLAUDE.local.md` 存在而不是一般檔（例如目錄）也算 exit 4」，以及 tests/test-dd-stop.sh 整支｜test-dd-stop.sh 沒有任何情境讓 CLAUDE.local.md 是目錄或其他非一般檔，「都有測試」這句不成立｜N1 變異（拿掉 `elif [ -e … ] && [ ! -f … ]` 那一支）跑整支：131 ✅、0 ❌。這支被拿掉時的行為是 `Is a directory`、rc=1、flag=true（實跑）｜那一支被改壞，測試照樣全綠，而壞掉的結果就是 S1-b-1 那種「旗標設了、聲明沒寫」。scripts/CLAUDE.md 的 dd-stop.sh 變異表也沒有這一列
> S1-b-3｜Smell｜scripts/dd-stop.sh remove_blocks `cat "$tmp" > "$LOCAL_FILE"     # 不用 mv：保留原檔的權限`｜註解講了要保留權限，但沒有測試守這件事｜N2 變異（改成 mv）131 ✅、0 ❌；實跑 600 的檔，mv 版跑完變成 644｜之後有人把它「簡化」成 mv，測試不會擋，使用者私人檔的權限會被放寬
> S1-b-4｜Smell｜scripts/dd-stop.sh `flag_on`（status 用的）與 tests/test-dd-stop.sh J｜「status 只讀 --local」沒有測試。test-gate ⑰ 有「只設在 global」那則，test-dd-stop 沒有對應的一則｜N3 變異（拿掉 `--local`）131 ✅、0 ❌｜global 設了 dd.stopped 時，status 會報「暫停中」，而 gate（只讀 --local）其實照擋，status 與 gate 說法不同
> S1-b-5｜Smell｜tests/test-dd-stop.sh A 段 `cp "$LF" "$WORK/block-sample.md"`（沒有包在 run／ck 裡）｜如果 `on` 被改壞成不建 CLAUDE.local.md，這行 cp 會失敗，`set -e` 讓整支在 A 就結束，B–N 一則都不跑。表上那句「每個都跑到最後一則」只對這 30 個變異成立｜讀原文：這一行在 `ck "A 聲明裡有…"` 那個迴圈之後，直接執行｜做這類變異時，看到的紅數會少一大截。跟 tests/CLAUDE.md「新增情境時別讓會回非 0 的指令裸跑」那條相牴觸
> S1-b-6｜Smell｜tests/test-gate.sh ⑰ `expect "⑰ 恢復後：補上 a/CLAUDE.md 就放行" pass commit s3`｜這一則放行，是因為 a/CLAUDE.md 這次一起 staged 了（tests/CLAUDE.md ⑫ 寫的「同批 staged 蓋掉銷帳」陷阱）。後面沒有再加一個不碰 a/ 的 commit 來證明欠帳真的銷掉了｜讀原文：⑰ 在這一則之後就接到第二個 repo｜它證明不了恢復之後欠帳會被清掉；說明文字比它實際檢查的東西多
>
> 【Not reported】
> - test-dd-stop.sh 與 test-gate.sh 都沒有先隔離使用者的 global git 設定（core.hooksPath、commit.gpgsign）：test-gate 本來就這樣寫，而且受影響時是假紅，不是假綠
> - ⑰「只設在 global」那則沒有先確認 GIT_CONFIG_GLOBAL 真的生效：表上「--local 改 --get」那個變異會紅，代表這台機器的 git 支援它；CI 的 git 版本也夠新
> - dd.stopped 有好幾個值時，`--unset-all` 的行為沒有測試：現實裡不太會發生
> - 「--segment-base 不受暫停影響」沒有測試：暫停時沒有任何流程會呼叫它，而且是改回原樣才會壞
> - test-install 新加的斷言（開頭三條、T5 清單兩列）都接對了；T8 用的是 dd-help.md，跟 dd-stop.md 從 deprecated_dd 拿掉這件事無關
> - 方向外的檔（README、CHANGELOG、docs/measurements 腳本）只掃過，沒有深入審
>
> 【需要外部查證】
> - ubuntu（GNU coreutils／grep）上 N1–N3 變異的結果是不是一樣：我只在 macOS 跑過 /bin/bash 3.2

## 處置

修正、測試與這份報告在同一個 commit（步驟 6，訊息結尾「（S1）」）。

| 發現 | 級別 | 處置 |
|---|---|---|
| S1-b-1 `on` 先設旗標 | Important | 採納，已修。與 S1-a-2 同一件，做了什麼見 `S1-a.md` |
| S1-b-2 設計文件寫「都有測試」，「不是一般檔」那一支沒有 | Important | 採納。加了 E2（`CLAUDE.local.md` 是目錄：`on` 回 4、輸出有「不是一般檔」、旗標沒設、目錄裡沒多東西）。設計文件那一句改成寫明哪幾條的測試是步驟 4 才補的；同一句的 ⑥（同目錄沒有 gate 時 `off` 照樣恢復）查證時發現也沒有測試（`grep -c '欠帳沒有查' tests/test-dd-stop.sh` 是 0），補在 F。變異：拿掉「不是一般檔」那一支只紅 `said "不是一般檔"` 一則 —— `on` 改成先寫聲明之後，寫進目錄會失敗、照樣 exit 4、旗標沒設，不再是報告實跑到的「旗標是 true」|
| S1-b-3 `cat` 不用 `mv` 是為了保留權限，沒有測試 | Smell | 採納。C 的原檔先 `chmod 600`，`off` 之後斷言權限沒變。變異（改用 `mv`）紅在這一則與 M2 唯讀檔的 `off` |
| S1-b-4 `status` 只讀 `--local` 沒有測試 | Smell | 採納。J 加「只設在 global 不算暫停」（`GIT_CONFIG_GLOBAL` 指到一個設了 `dd.stopped=true` 的檔）。變異（拿掉 `--local`）只紅這一則 |
| S1-b-5 A 段裸跑 `cp` | Smell | 採納。包進 `ck`，檔不在時補一個空的讓後面照跑 |
| S1-b-6 ⑰「補上就放行」證明不了欠帳銷掉 | Smell | 採納（與 S1-c-1 同一件）。⑰ 與 `tests/test-dd-stop.sh` 的 G 各加一則「補完之後，再一個不碰那個目錄的 commit 放行」。對照：gate 的 `owed_dirs` 銷帳那一行條件改成恆假，新加的兩則變紅、原本的「補上就放行」照樣綠 |

Not reported 的幾項沒有另外處理。

需要外部查證：做了。ubuntu:24.04 容器以一般帳號跑這三個變異（不認「不是一般檔」、改用 `mv`、拿掉 `--local`），紅在跟 macOS 同樣的幾則。
