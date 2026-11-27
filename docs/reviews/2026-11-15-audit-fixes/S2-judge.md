# S2 步驟 3、4：主對話的查證

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S2。

## 派工

- 範圍：`git diff 133071e`（表上這段的起點）到工作目錄。HEAD = d41ba84，4 個 commit（S2-1 到 S2-4），工作目錄乾淨。
- 步驟 3 沒有跑：這一段的 diff 全是 Markdown（三份 SKILL.md、`commands/dd-init.md`、CLAUDE.md、CHANGELOG、設計文件），沒有程式碼，code-simplifier 的範圍是空的。
- 步驟 4 不跳過：diff 沒有程式碼，但改的是 Claude 會照著做的指令文字，裡面每一句都在講別處的行為（gate 印什麼、安裝腳本做什麼、`docs/reviews/` 怎麼放），機械檢查看不到這一類。
- 派 3 個 `code-reviewer`（下限，不帶 model 參數），照改的三處分方向：A 起點文字對 gate、B BLOCKED 流程、C Phase 4 與文件宣稱。審查包 567 行，沒有多派。
- 派工 prompt 只交事實（改了哪三處、審查包的組成、已跑過的驗證與預期值），沒有寫我對哪裡可能有錯的判斷。

## 發現

三份都完整交回（都有發現、Not reported、What I ran、需要外部查證）。讀檔檢查：每份我都重跑了它至少一條指令或讀了它引的位置，都對得上。

- 採納（全部）：
  - Important：A1（code-simplifier 取不到起點時問錯題）、B1（新表第一段先停時申報檔放哪判不出來）、C1（`jq -r` 分不出字串 "true" 與布林 true）、C2（空檔時 `jq` 不報錯、會被判成未啟用）
  - Smells：A-S1（錯誤印在 stdout 的情況沒講）、B2（「這段已經有 commit」跟 gate 的判定對不上）、B3（三處對申報檔內容的要求不一樣）、B4（本 repo 設計文件的規則區塊還是舊句）、C3（設計文件寫的改法跟實際落地的不一致）
  - 級別照審查者標的，沒有調級。
- 駁回：無。
- 需使用者決定：無。
- 需要外部查證（C 列的兩條，都沒查成，留著）：
  - Claude Code 怎麼看 `enabledPlugins` 裡值是字串 `"true"` 的鍵。新指令把它算成未啟用並把實際的值講給使用者，不依賴這個答案。
  - plugin 只在專案層設定檔啟用時，Phase 4 只讀 `~/.claude/settings.json` 會判成未啟用；這時 `claude plugin install` 會怎麼做沒有實跑（會改真實的 `~/.claude`）。Phase 4 只加了「提示不要講成確定沒裝」。
  - 同類、我自己留的：`claude plugin enable` 只從 `claude plugin --help`（本機 2.1.325）確認有這個子指令，沒有實跑。

## 處置

逐條的處置在 `S2-a.md`、`S2-b.md`、`S2-c.md`。修完之後的驗證：

- Phase 4 文件裡的指令對 12 份假設定檔的結論，與 `install-dd-pipeline.sh` 的 `plugin_enabled_state()` 逐份相同。
- 改過字的三處都重跑乾跑（sonnet subagent，結果用指令核對）：Phase 4 三臂、task-planner 規則區塊兩臂（多張進度表、一個 commit 都沒有就先停）、code-simplifier 一臂。
- 步驟 5 的結果寫在設計文件「段落與小任務」S2 底下。

## 重疊與獨有項

- 重疊：沒有兩個審查者報同一條。A 與 C 都看了 dd-loop 認的四串字對不對得上 gate，都判定對得上（各自放在 Not reported）。
- A 獨有：兩份 skill 在同一個情況下問的題目不一樣。我在設計文件寫了「一致」，寫的時候只對了「都是問一題」，沒讀那一題的內容。
- B 獨有：四條都是把規則區塊那一句放進具體情境才看得出來的（新表第一段、回頭之後還沒 commit、零 commit 先停、本 repo 自己）。我的乾跑只跑了最順的那一種情境。
- C 獨有：兩條 Important 都是「文字叫模型自己寫 `jq`」帶出來的；我在同一輪乾跑裡自己踩到 `//` 那個坑，只補了那一句警告，沒有往「同一類還有哪些」想。

## 這一段自己犯的錯（給步驟 7）

- 乾跑臂都過了就當成文字沒問題：乾跑只證明我挑的那幾種輸入走得通，沒挑到的輸入（空檔、字串值、多張表、零 commit）要靠審查者列出來。
- 叫模型「用 jq 讀」而不給指令：每個模型寫出來的 `jq` 不一樣，坑也不一樣。這個 repo 的規則本來就寫了能寫成指令就寫成指令。
