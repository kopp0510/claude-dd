# S1-judge（主對話查證）— CI 擋蓋章區塊改了沒跳 dd-loop-rev

段落：使用者看了 mattpocock/skills 的 `/retro`（有固定樣子的錯做成自動檢查，再縮短文字規則），選了先做這一條。進度表 `docs/designs/2026-10-30-dd-loop-rev-check-design.md`，段落起點 `2bd0014`，S1-1 是 `848ea70`。中等任務（一個 CI step 加文件），沒跑 plan-review。

## 派工

- 審查範圍：`git diff 2bd0014 848ea70`。diff 檔放 session 暫存目錄：整段 diff、步驟 3 並行的說明、根 CLAUDE.md 那段的舊版全文、已跑過的 8 種變異與預期值
- 步驟 3 的 code-simplifier 與審查並行：沒改任何一行；另回報一個行為問題（見下表 S1）
- 派 3 個 `code-reviewer`（下限）：A 新 step 的 bash 邏輯、B 根 CLAUDE.md 縮短時掉的條件、C 同步點。這段有 CI 腳本也有縮短既有規則，§3.10 說後者最容易掉條件，所以 B 單獨一個方向

## 發現

| 項 | 查證 | 判定 |
|---|---|---|
| S1／A2 `rev_of` 零命中時 `set -e` 靜默中止，「抓不到 rev 標記」那句永遠印不出來 | 主對話 `/bin/bash -e -c '…old=$(rev_of norev.md); echo reached'` → exit=1、reached 沒印 | 採納 Important |
| A1／B1／C1 「同一次發版改好幾次區塊，只要跳一次號」放寬了舊規則 | 舊文「動到…就必須同步跳」；主對話逐 commit 列出 v1.6.0 以來改到區塊的 commit：S3（1299d45 9→10、8d5796c 不跳）、S6（0233de6 10→11、88deff5 不跳）、S8（dbf4a2f 不跳、a01d7bb 11→12），都在 v1.6.10 前 —— 前例是一段跳一次，不是一版一次 | 採納 Important（B 標 Critical，降級：新 step 沒有讓任何東西比以前更不安全，錯的是我寫的那句規則文字；改回去就好） |
| A3／B2／C2 ④ 的「`UPGRADING.md` 寫死的 rev」就是 ② 那條判定線，「④ CI 不驗」不對 | `git show 848ea70:UPGRADING.md \| grep -n rev` 只有 :82「判定為舊版」那行，ci.yml 四方 step 有驗 | 採納 Important |
| B3 「同批要改這四處」是數量，子項自己又有「兩處」「各一處」 | 讀那段 | 採納 Important（§3.10 列舉不要數） |
| B4 拿掉「開頭是 `## 開發流程`」，step 也沒驗區塊第一行 | `git show 848ea70:commands/dd-init.md` :52 是唯一的 ```markdown、:53 是 `## 開發流程`；C 在 Not reported 判不需要，理由是 `head -2` 定界夠用 —— 但那只對「現在」成立，前面多一個 ```markdown 範例時 stamp() 會改抓範例而永遠綠 | 採納 Important（C 的駁回理由不成立） |
| B Not reported：CHANGELOG「以前只靠 code-review 抓（漏過一次）」讀起來像 code-review 漏了 | 舊文是「CI 全綠，靠 code-review 才抓到」 | 採納 Smell |

駁回：無。

需要外部查證：A 問 GitHub Actions 沒設 `shell:` 時是不是 `bash -e {0}` —— 這個 step 的修法（`|| true`）在有沒有 pipefail 下都成立，沒有查。C 問有沒有別人從 main 安裝 —— 規則改回每段跳號，不依賴這個答案。

## 處置

- S1／A2：`rev_of` 結尾補 `|| true`，旁邊註明有承重；新增變異「標記改成 `dd-loop-REV`」→ exit 1，印出「抓不到 rev 標記（v1.6.11：'12'、現在：''）」
- A1／B1／C1：根 CLAUDE.md 改回「每段改了都要跳」並附前例（S3、S6、S8 各跳一號、review 修正不另跳），寫明 CI 只是下限、擋不到什麼；ci.yml 註解、CHANGELOG、架構文件同步改
- A3／B2／C2：④ 只留 CHANGELOG，註明 UPGRADING 那處就是 ②
- B3：「這四處」改成「同批要改：」
- B4：界線補回「開頭是 `## 開發流程`」；step 加一道「抓到的第一行不是 `## 開發流程` 就紅燈」；新增變異「第 10 行前插一個 ```markdown 範例」→ exit 1
- B Smell：CHANGELOG 改成「曾有一次沒跳號、CI 全綠，靠 code-review 才抓到」
- 改完重跑：10 種變異 `/bin/bash -e`（3.2.57）全部與預期相同；`ruby` YAML 解析通過；`ci.yml` 讀文件的 7 個 step 本機 exit 0

## 重疊與獨有項

- 三個審查者**都**抓到「只要跳一次號」放寬規則、與「④ 的 UPGRADING 就是 ②」—— 不是誤判。前者正是 §3.10「縮短既有文字時條件最容易被改掉」：我為了配合 CI 的基準（tag），把規則改寫成 CI 量得到的樣子
- simplifier 與 A 都抓到 `set -e` 靜默中止 —— 根 CLAUDE.md 早有寫這個坑（`n=$(grep -c ...)` 那條），我的 8 種變異沒有一種走到這條路
- B 獨有：識別特徵被拿掉；C 在 Not reported 判它不需要，讀程式碼後採 B
- C 獨有：進度表規則區塊逐字比對、指路句位置都核過沒問題
