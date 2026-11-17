# S1-judge（主對話查證）— /dd-stop 指令、腳本與 gate 的暫停旗標

段落 S1，起點 `925d0b8`，進度表在 `docs/designs/2026-11-17-dd-stop-design.md`。

## 派工

派了 4 個 `code-reviewer`（下限是 3），同一則訊息平行派出，沒有重派或補派，四份報告都完整交回。派 4 個的理由：這一段有四種不同性質的東西，各給一個方向 ——
腳本與 gate 的正確性（A）、測試有沒有牙（B）、文件與指令裡的宣稱（C）、模型層實驗的腳本與判準（D）。方向只是重點，四個拿到的是同一份 diff 檔。
派工 prompt 只交事實（做了什麼、材料在哪、哪些驗證跑過與預期值）。

⚠️ 派工與查證不在同一個對話：派工的那個對話在四份報告交回之後、查證開始之前就中斷了，它的暫存區沒有留下。
查證的這個對話從那個對話的紀錄檔取回四份報告與四份派工 prompt（逐字），再照它們落地。審查者審的是 `925d0b8` 到當時的工作目錄（含步驟 3 還沒 commit 的改動）；
原本的 diff 檔沒有留，各報告「派工」節對它的描述取自當時組檔的指令。

## 發現

讀檔檢查（每個審查者的東西自己重跑，不照報告自述）：

- A：兩條 Important 都先寫成測試（`tests/test-dd-stop.sh` 的 M2），對修之前的腳本跑：唯讀檔的 `on` 是 exit 1、旗標留著；唯讀檔與不能寫的目錄兩種 `off` 都被 alarm 砍掉（exit 142）。跟它報的相同
- B：它的三個新變異（不認「不是一般檔」、寫回改用 `mv`、`status` 拿掉 `--local`）修之前都是 0 紅，這一點沒有重跑（修之後的腳本已經不同）；補了測試之後三個都有紅。
  它說「都有測試」不成立：`grep` 測試檔確認沒有目錄的情境；順著同一句往下對，⑥（沒有 gate 時的 `off`）也沒有測試，它沒有報
- C：`wc -c CLAUDE.md` 是 47182，相同；它引的五處（`commands/dd-stop.md` 第 5 步那一句、英文 README 的 "paused"、設計文件 D3 的 `--unset` 對 `scripts/dd-stop.sh` 的 `--unset-all`、`scripts/CLAUDE.md` 的「30 個變異」、⑰ 最後一則）在工作目錄都找得到
- D：前五條與「 -n 」、`.json` 壞掉那兩項各手造一份 `.json` 餵 `check-model.sh`，結果與它報的相同；`grep -c -- '--start-segment' commands/dd-init.md` 是 2，相同；其餘讀 `run-model.sh`、`selftest-model.sh` 對過

採納、已修（級別照審查者標的，沒有調級）：
- Important：S1-a-1；S1-a-2 與 S1-b-1（同一件）；S1-b-2
- Smell：S1-a-3、S1-b-3 到 S1-b-6、S1-c-1 到 S1-c-5、S1-d-6、S1-d-7、S1-d-11
- 逐條的查證與做了什麼在各份報告的處置

採納成已知限制、沒有改腳本：S1-d-8、S1-d-9、S1-d-10、S1-d-12（都是「偏向判成沒通過」或「自測沒涵蓋」，寫進量測目錄 CLAUDE.md）。

駁回：沒有。

需使用者決定：S1-d-1 到 S1-d-5（Important）。五條的事實都成立，各分兩半：
- 文件講得比判準實際擋的多的那一半：採納、已改（量測目錄 CLAUDE.md 新增「判準已知的洞」、「這一批證明不了的」補三條、設計文件 S1-4 的結果補兩條）
- 判準本身（`check-model.sh`，其中「換入口」那一條還要改 `run-model.sh` 留下來的資料）：**沒有改**。理由：
  ①量測目錄 CLAUDE.md 寫明「判準改了字，之前那一批就不算它的」。改了之後第 1 批不算新判準的，模型層要重新算數只能再跑一批，那是花使用者的錢（文件寫的最壞值是 22 美元），不是這個對話可以自己決定的
  ②`run-model.sh` 留資料的那一段沒有不花錢的端到端驗法，改了而不跑等於放一段沒驗過的程式碼進去
  ③這五個洞影響的是「下一批會不會被誤判」，不影響部署出去的東西（`dd-stop.sh`、gate、指令）
- 第 1 批對得出來的：S1-d-1、-2、-3 沒有踩到（見 `S1-d.md` 的處置）。對不出來的：S1-d-4 在 `stopped-2`（它的兩次 Read、三次 Edit 對象沒有留）；S1-d-5 在被停掉的四發（沒有 result）
- 建議：現在不跑第 2 批；量測目錄 CLAUDE.md 已寫明「要跑第 2 批，先補這幾條、補自測、commit，再跑」。這只是一句文件，沒有機械檢查擋著
- 這一項沒有擋住步驟 5 到 8：修得動而不必花錢的那一半已經修了，剩下的要使用者開口才動

需要外部查證：A、B 的（ubuntu）做了，結果在各自的處置。D 的兩項沒查（要一份 advisor 沒關掉的原始 stream-json）。

## 處置

- 程式碼：`scripts/dd-stop.sh` —— `on` 改成先寫 `info/exclude` 與聲明、最後才設旗標，聲明寫不進去 exit 4、旗標設不了 exit 1；`remove_blocks` 寫檔各步接成一組，寫不進時印「寫不進」、回 1（`off` exit 5）
- 測試：`tests/test-dd-stop.sh` 加 E2、M2、F 的 `off`、C 的權限、J 的 global、G 的銷帳那兩則，A 的 `cp` 包進 `ck`；`tests/test-gate.sh` ⑰ 加銷帳那一則
- 文件：`scripts/CLAUDE.md`、`tests/CLAUDE.md`、設計文件、`commands/dd-stop.md`、`README.md`、`CHANGELOG.md`、`docs/measurements/2026-11-17-dd-stop/CLAUDE.md`
- 步驟 5 重測（修完之後）：
  - macOS `/bin/bash`（3.2）：`tests/test-dd-stop.sh` 159 個 ✅、0 個 ❌；`tests/test-gate.sh` 214 個 ✅、0 個 ❌；`tests/test-install.sh` 與 `tests/test-dd-init-upgrade.sh` exit 0；`shellcheck -S warning` 沒有輸出；`selftest-model.sh` 32 個 ✅
  - ubuntu:24.04 容器（bash 5.2.21、git 2.43.0、GNU coreutils 9.4）：四支測試以 root 與一般帳號各跑一次，都是 exit 0、0 個 ❌；`tests/test-dd-stop.sh` 在 root 是 144 個 ✅（M2 不跑）、一般帳號 159 個
  - `tests/test-dd-stop.sh` 的變異整張重跑（macOS）：每個都有紅、都跑到最後一則、判定行數與固定版相同；對照表在 `scripts/CLAUDE.md`。步驟 4 加的那幾個另在 ubuntu 容器以一般帳號跑過，紅在同樣幾則
  - gate 的「不銷帳」變異：`tests/test-gate.sh` 新加的 ⑰ 那一則與 `tests/test-dd-stop.sh` G 新加的那一則變紅，兩邊原本的「補上就放行」照樣綠
  - HEAD 版與現行版的 `dd-stop.sh` 跑同一串沒有寫檔失敗的情境，輸出逐位元組相同
  - CI lint job 本機逐 step 的結果寫在步驟 6 那個 commit 的訊息
- 沒有做的：模型層沒有重跑（第 1 批測的是 `65e1fb9` 版的 `dd-stop.sh`）；`commands/dd-stop.md` 改的那一句沒有再乾跑；`on` 寫不進 `info/exclude` 沒有測試；沒有部署到 `~/.claude/`（留給使用者）

## 重疊與獨有項

- 兩個都抓到：`on` 先設旗標（A-2、B-1，各自實跑）；「補上就放行」證明不了銷帳（B-6、C-1）
- A 獨有：`off` 寫不進時永遠重跑（A-1，這一段最重的一條：`/dd-stop off` 會卡到逾時，而另外三個方向都沒有碰寫檔失敗）；欠帳清單含只 staged 的目錄（A-3）
- B 獨有：「不是一般檔」沒有測試（B-2）、權限（B-3）、`--local`（B-4）、裸跑的 `cp`（B-5）—— 都是「拿掉這一支，測試照樣全綠」，只有做變異才看得出來
- C 獨有：清單格式（C-2）、英文 README 的 "paused"（C-3）、`--unset-all`（C-4）、寫死的個數（C-5）
- D 獨有：整份 —— 模型層的判準沒有別的審查者看
- 四個都沒有抓到、查證時才發現的：設計文件同一句裡的 ⑥ 也沒有測試；`on` 寫不進 `info/exclude` 時只有一行 shell 錯誤
