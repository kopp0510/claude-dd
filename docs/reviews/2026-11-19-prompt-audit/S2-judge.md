# S2-judge（主對話查證）— 三條教訓搬回全域模板（`ba799a2..`）

段落 S2，起點 `ba799a2`（`check-claude-md.sh --start-segment` 記的）。這一段沒有進度表；報告和上一段放同一個目錄。

## 派工

派了 3 個 `code-reviewer`（下限就是 3），2026-11-20 同一則訊息平行派出，沒有重派或補派，三份報告都完整交回。只派 3 個的理由：這段 diff 只有 1 個 commit、9 個檔，內容分三塊，各給一個重點 ——
搬回的文字與 dd-loop（A）、改動紀錄對不對得上 diff 與 git 歷史（B）、repo 裡沒被改到卻該跟著改的地方（C）。重點只是重點，三個拿到的是同一份審查材料、同一份共用派工。派工只交事實。

這段 diff 全是文件與指示文字，沒有程式碼。照樣派審查者：CHANGELOG、量測紀錄與報告處置節的敘述引了別處的 commit、行為與數字，這些沒有被機械檢查證明。
步驟 3（code-simplifier）沒有跑：9 個檔都是 `.md`，而且搬回的三條要和 v1.6.16 的原文逐字相同，不讓它改寫。

審查材料一個檔（scratchpad 的 `s2/diff-pack.md`，2553 行）：①`git diff ba799a2 HEAD`（HEAD = `73cd7a5`，工作目錄乾淨）；②步驟 3 沒跑與理由；
③被改到的 9 個檔的整檔內容（`CHANGELOG.md` 只放「未發布」一節）；④步驟 1 跑過的驗證與預期值。派工寫明用 Read 每次 300 行讀到最後一行。

動手之前計畫先交 plan-review：1 輪，裁決者派 4 個審查者，結論「通過」，沒有重大；採納的小事 7 條都併進做法（CHANGELOG 不寫「淨變化只有」、照根目錄 `CLAUDE.md` 的觸發時機巡一遍、步驟 4 寫明範圍、`S1-d.md` 的處置也要補、乾跑的派工寫明 context 裡的全域檔是舊版、新 session 的檢查用整行比對、部署前先列會被覆蓋的檔）。

## 發現

讀檔檢查（每個審查者挑它引的東西自己重讀或重跑）：

- A：它引的根目錄 `CLAUDE.md`「寫註解、CLAUDE.md、設計文件時的判準在全域模板 **§3.10**，刻意放在 §3.9 之外…沒跑迴圈的專案會連這些判準一起跳過」讀了，原文相同；`scripts/dd-stop.sh` 的暫停聲明「這一句優先於…全域 CLAUDE.md §3.9 的迴圈；其他規則照舊（動手前的佐證、測試要跑綠、破壞性操作先確認）」也相同
- B：`git log --format=%h 2636b36..HEAD -- templates/global/CLAUDE.md` 印出 `73cd7a5`、`c360152`、`8dcaa73`、`3e3243a`、`3637c92`、`c0f6d33`，`8dcaa73` 確實在裡面；CHANGELOG §6.2 那一項原本沒有附 hash
- C：`git show c360152 --stat -- README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md` 三個檔各一行；`README.zh-TW.md` 的「全域 §3.9 只留步驟清單與關卡，並明寫呼叫這個 skill」與 `README.md` 的 "global §3.9 keeps the step list and its gates, and calls this skill" grep 得到

採納、已修（都是 Smell）：
- S2-b-s1 與 S2-c-s1（同一件）：CHANGELOG 列模板其他差異時漏了 `8dcaa73`
- S2-c-s2（A、B 列在既有問題）：`c360152` 在英文 `README.md` 也加過那一句，CHANGELOG 與 `S1-c.md` 處置漏記
- C 的既有問題：兩份 README 寫「§3.9 只留步驟清單與關卡」，漏了驗證教訓

屬實、查了、沒有改字：
- S2-a-1（Important）。文字上 §3.9 沒有任何一句寫這三條在迴圈外適用，這一點成立。它的失敗情境（迴圈外、迴圈暫停中的 session 把三條判成不適用）是它自己列在「需要外部查證」的事，兩種都量了：各 8 發，各 7 發用到。
  規則事先寫好（過半就不補），所以不補範圍句，模板那三條維持與 v1.6.16 逐字相同。級別沒有調：它標 Important 的理由是「不會報錯」，量測沒有推翻這個理由，只是沒量到它發生。
  審查者說補不補要使用者決定：沒有問，理由寫在 `S2-a.md` 的處置。

既有問題、沒改：§3.9「規則」裡另外五條驗證教訓同樣沒有範圍句（v1.6.16 就這樣，五條都沒測）。

駁回：無。需使用者決定：無。

需要外部查證：
- 查了：S2-a 的兩項（迴圈外、迴圈暫停中各跑同一個 prompt）；S2-c 的一項（部署後全域檔有這三條、dd-loop 沒有那一節）。結果在處置
- 沒查：git 進行中狀態那一條、另外五條驗證教訓在迴圈外用不用得到；使用者在對話裡下 `/dd-stop on` 之後同一個對話接著做的情況

## 處置

改了的檔（步驟 2 的 `73cd7a5` 加上步驟 6 的 commit）：
- 搬回本身：`templates/global/CLAUDE.md`、`skills/dd-loop/SKILL.md`
- 跟著改的文件：`README.md`、`README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md`、`CHANGELOG.md`、`docs/measurements/2026-11-20-domain-traps-pointer.md`（開頭加註）
- 上一段報告的處置節：`docs/reviews/2026-11-19-prompt-audit/S1-c.md`、`S1-d.md`
- 新增的量測紀錄：`docs/measurements/2026-11-20-lessons-outside-loop.md`

步驟 5 重測（修完之後；預期都事先寫好，結果用指令核）：

1. 文字與位置。`2636b36` 版模板的 `⚠️⚠️` 換成 `⚠️` 之後抽出那三條，與現在的模板抽出的三條 `diff`：沒有輸出。兩版各抽「規則:」到「### 3.10」之前整塊 `diff`：沒有輸出。
   `git diff ba799a2 --stat`：模板 18 行加、2 行減，dd-loop 21 行減（只少最後一節）。
2. 殘留。`git grep -n '領域陷阱\|domain pitfalls'` 命中的檔：`CHANGELOG.md`、`docs/measurements/2026-11-20-domain-traps-pointer.md`、`docs/reviews/2026-11-19-prompt-audit/` 的 `S1-a.md`、`S1-b.md`、`S1-c.md`、`S1-d.md`（這一組 S2 報告落地之後也會命中）；都是歷史紀錄。
   `grep -c 'read-then-write\|rebase-merge\|advisory lock' skills/dd-loop/SKILL.md`：0。
3. CI 的每一個 `run:` 步驟在本機各跑一次（`/bin/bash` 3.2），跑了兩輪：第一輪工作目錄是修完審查發現之後的內容、這一組 S2 報告還沒寫；第二輪四份 S2 報告都在（之後只改了本檔這一行）。兩輪都是 lint 22 步、bash32 7 步，29 步都 exit 0。GitHub 上的 CI 沒跑（沒有 push）。
4. dd-loop 乾跑（部署之前；一個 general-purpose subagent 讀 repo 裡的 `skills/dd-loop/SKILL.md` 與模板 §3.9，派工寫明它 context 裡的全域檔是舊版、不算）：
   - 沒有句子還指向拿掉的那一節；它核過的節名與步驟指標都指得到（只有一處指到「專案自己的 `docs/reviews/CLAUDE.md`」，專案不一定有那個檔）
   - 它卡住或要猜的六處都不是這次搬動帶進來的，沒改，轉新段落：專案沒有 `docs/reviews/` 時要不要自己建；步驟 3、4 什麼時候可以並行；模板說「例外見 dd-loop」而 dd-loop 沒有「例外」這個字眼、那一條管不管步驟 3；沒有進度表時 `S<段落>` 與子目錄叫什麼；要修掉的是全部還是採納的 Critical／Important（模板與 dd-loop 的寫法不同）；「重跑時」指什麼時候。
     另外兩處是三條本文原有的字眼：「確認 `grep` 回 0」沒寫 grep 什麼、「後面那段 rebase 判斷」指哪一段
   - 三條接得上；迴圈外它會套用，但回報那是自己推的（與 S2-a-1 同一件）
5. 部署：部署前先列會被覆蓋的檔 —— `~/.claude/CLAUDE.md`、`~/.claude/skills/dd-loop/SKILL.md`、`~/.claude/skills/self-improving-agent/CLAUDE.md`（後者是 `ba799a2` 改的那一句）。
   `bash ./install-dd-pipeline.sh --force`，exit 0；`diff -q templates/global/CLAUDE.md ~/.claude/CLAUDE.md` 相同，`skills/dd-loop`、`skills/self-improving-agent` 對部署版 `diff -rq` 沒有輸出；
   部署版的全域檔與 dd-loop 裡「領域陷阱」都是 0 筆，全域檔「read-then-write」1 筆；`--check` 的輸出裡「與 repo 不同」0 行。
6. 新 session 檢查：開一發 haiku、不給任何工具，叫它照貼 context 裡含「read-then-write」的那一行；貼出來的與 `~/.claude/CLAUDE.md` 的那一行整行相同（1 筆），0 次工具呼叫。
7. 量測（`docs/measurements/2026-11-20-lessons-outside-loop.md`）：迴圈外 8 發有效、7 發用到；迴圈暫停中 8 發有效、7 發用到。暫停臂原本的規則寫「這次不量」，看過迴圈外臂的結果之後才加量，紀錄裡寫明了。

沒有做的：
- 步驟 3 沒有跑（理由見派工）
- 步驟 1 的巡查只 grep 了三條的關鍵字，沒有讀 README「核心工作法」那一段的句子；C 抓到的那一句是這樣漏的
- 量測用的拋棄式 repo（開在工作區底下）與它在 `~/.claude/projects/` 留下的兩個資料夾，量完刪掉了；刪完 `~/.claude/projects` 的清單與量測之前相同
- ZCode 那一側沒有重新部署（留給使用者）

## 重疊與獨有項

- 兩個都抓到：CHANGELOG 漏了 `8dcaa73`（B-s1、C-s1）
- 三個都提到、級別不同：`c360152` 在英文 README 也加過那一句而沒記（A、B 列既有問題，C 標 Smell）
- A 獨有：範圍句沒有跟著回來（這一段唯一的 Important；步驟 1 的驗證沒有一項查適用範圍，是它點出來的）
- C 獨有：兩份 README「只留步驟清單與關卡」漏了驗證教訓；部署順序的風險
- 三個都沒抓到、乾跑才列出的：dd-loop 與模板之間六處要猜的句子（都不是這一段帶進來的）
