# S1-a — dd.docfile 推上游的文件同步

段落：S1（無進度表，日期子目錄，編號重新起算）
範圍：`git diff 21ca5ed 29726db`，branch `main`，被審 commit `29726db`
（`dd.docfile` 的程式碼與測試由 `fbf2ab4`／`0710481` cherry-pick 進 `main`，在段落起點之前，
不在本次範圍 —— 它們自己的審查報告在 `docs/reviews/2026-10-16-gate-docfile/`）

## 派工

- 範圍是**純文件同步**：兩份 README 的「CLAUDE.md 維護規則」各加一條、`DD_PIPELINE_ARCHITECTURE.md` 的 gate 段加兩行、`CHANGELOG.md` 的 `## 未發布` 新增 `### Added`、`scripts/CLAUDE.md` 把「上游文件刻意不同步」改寫成「已同步」
- 五項重點：①文件宣稱逐條核 `scripts/check-claude-md.sh` ②兩份 README 對等（CI 不驗散文）③改寫段的理由站不站得住 ④專案 CLAUDE.md「CI 不驗、只能手動同步的區塊」有沒有漏巡 ⑤CHANGELOG 的節序與已發布區塊
- 明寫已跑過不要重跑：`tests/test-gate.sh` 103 ✅ / 0 ❌、CHANGELOG 已發布區塊 `shasum` 相同、diff 無步數宣稱
- 取檔一律 `git show 29726db:<路徑>`；預算最多一次重現實驗

## 發現

Critical 0 / Important 3 / Smells 0。

| # | 級別 | 內容 | 依據 |
|---|---|---|---|
| A1 | Important | CHANGELOG 新增那條說「變異對照記在 `tests/CLAUDE.md`」，而 ⑫ 的五列對照表在 `scripts/CLAUDE.md`。**危險在於指錯的地方真的有一張表**（`tests/CLAUDE.md` 有 2026-10-07 S6 那組），讀者會「找到東西而停下」 | `grep -c '變異 | 應該變紅' tests/CLAUDE.md` → 0；`scripts/CLAUDE.md` 的表頭在「變異測試（2026-10-16」之後 |
| A2 | Important | 兩份 README 都寫 `--segment-base` 「一併改認它」／"follow the same name"，而該分支只讀 `base` 與 `merge-base`、從頭到尾不碰 `$DOC_FILE`。來源 `~/.claude/rules/company.md` §2 寫的是「一併**可用**」（準確），這次改寫成「改認」 | `scripts/check-claude-md.sh` 的 `--segment-base)` 分支 = `read_base` + `merge-base --is-ancestor` + `echo "$base"` |
| A3 | Important | `scripts/CLAUDE.md` 改寫段把「不動 `commands/dd-init.md`」的成本掛在錯的範圍：真正會寫 `dd.docfile` 指引的 Phase 3 在**蓋章區塊之外**（fence 52–148，Phase 3 在 161），改它**不必**跳 rev。決定（不動）站得住，但靠的是另一條理由（hook 那行只轉呼叫 gate、不判檔名） | `grep -n '^```' commands/dd-init.md | head -2` → 52 / 148；`grep -n '^### Phase 3'` → 161 |

**兩份獨立抓到同一項**：A1 = B1（變異表指錯檔）、A3 = B2（dd-init 的理由）。

逐項答覆（它查完判為乾淨、要求不要重跑）：①`dd.docfile` 的其餘宣稱全部對得上（`--local`、字元集、`.`／`..`／`-` 開頭、`exit 1`、三處使用點、`--start-segment` 與 SKIP 欠帳、報告路徑、情境 ⑫ 自己開乾淨 repo）②兩份 README 七項逐項對等、插入位置相同 ③架構文件新增兩行為真 ④「為什麼要巢狀」的 gate 對策段不含檔名假設、不用改；CI 防線表那一列本來就是摘要（連 S4 的 fork-base、S6 的 review 情境都沒列）⑤`### Added` 在 `### Changed` 之前與 1.3.0／1.4.0 一致

它另外實跑驗證了「`-c dd.docfile=…` 與 `GIT_CONFIG_PARAMETERS` 不生效」：拋棄式 repo 裡 `git -c dd.docfile=GEMINI.md commit` 的 hook 內 `git config --local --get` 回空、無 scope 的 `--get` 回 `GEMINI.md`。

Not reported：CHANGELOG「檔名寫死在 `md_of()`」是動機敘述的簡寫；`scripts/CLAUDE.md` 與 gate 檔頭的範例寫 `git config dd.docfile`（不帶 `--local`，寫入時預設就是 local，可用）在本次 hunk 之外；**範圍外但之後會踩到**：gate 檔頭與 `scripts/CLAUDE.md` 在 `main` 上指向 `~/.claude/rules/company.md §2`，那個檔只存在這台機器，上游讀者點不到。

## 處置

- **A1 採納**：CHANGELOG 改成「對照表記在 `scripts/CLAUDE.md`（`tests/CLAUDE.md` 記的是 ⑫ 那組情境本身的陷阱）」—— 兩份檔各自管什麼講清楚，而不是只換一個路徑
- **A2 採納**：兩份 README 改成「`--start-segment` 與 SKIP 欠帳機制一併改認它（`--segment-base` 只印起點、不碰檔名，但非法值一樣會先被擋下 —— 驗證在分派子命令之前）」。英文同批改成同樣的語意
- **A3 採納**：改寫段拆成兩半 —— 區塊外的 Phase 3 行為正確且改它不必跳 rev（附 `grep` 指令）；區塊內是步驟 8 寫死的 `grep 'CLAUDE\.md$'`，那才是要跳 rev 的部分。同時把原本的末句（「要設這個選項的人看得到的是 README 與本節，不是 `/dd-init` 的輸出」）**刪掉並改成已知限制**：Phase 3 產生的 hook 註解、fallback 警告、pre-commit／lefthook 設定名都寫死 `CLAUDE.md`，設了 `dd.docfile` 的 repo 裡協作者看到的是錯的檔名 —— 要修就改 Phase 3 的措辭（不必跳 rev），但動 commands 依專案 CLAUDE.md 要另外沙盒乾跑，所以沒跟這批一起做
- **Not reported 的「範圍外」那條照樣修**（上游讀者點不到本機路徑）：gate 檔頭與 `scripts/CLAUDE.md` 改成不指向任何本機檔的說法（「只准放某個固定檔名的 repo，例如記憶檔一律叫 `GEMINI.md` 的團隊」）。它雖然來自 cherry-pick 的那兩筆，但**這批就是要送上游**，不修等於把一個點不到的指標推出去
- **CI 防線表不補**：兩份報告都判斷那個括號是標籤而非窮舉（既有的 S4、S6 情境也沒列），補了反而製造「它是窮舉」的假判例

修正落在 `64806e3`。
