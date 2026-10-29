# S1-judge：全域 CLAUDE.md 瘦身 S1 的查證

範圍：`git diff f46d4de HEAD`（a30dc1a、f0e80ab、a542817），起點取自設計文件進度表 S1 的 commits 欄。

## 派工

- 步驟 3：`code-simplifier` 一個，**只審不改**（這段是原文搬移，改寫剛搬過去的原文會破壞搬移對照）。與步驟 4 並行，所以 diff 檔 ② 是「無」、③ 取 HEAD 版
- 步驟 4：`code-reviewer` 四個，同一則訊息平行派出，分方向：A 搬移前後條件與指向、B 文件宣稱與數字、C 量測腳本、D 全面。
  比下限多一個，因為這段同時有「搬移」（要逐句對舊版）與「新寫的量測腳本」兩種性質完全不同的東西，各給一個專責，再加一個全面
- diff 檔：scratchpad 的 `S1-diff.txt`（5593 行；①整段 diff ②無 ③HEAD 整檔帶行號 ④已跑過的驗證與預期值）
- 四份報告都完整收回（含 Not reported、What I ran），不用補派

## 發現

查證時一律讀檔或實跑，結果如下。

### 採納（Important）

1. **`..` 規則只在步驟 8**（A-2、D-1）。查證：拋棄式 repo 裡 commit a→b、工作目錄再改 c，`git diff b..` 只印 b、exit 0，`git diff b.. HEAD` exit 129（D 實測；A 對 `f46d4de..` 實測 129）。task-planner 規則區塊規定 commits 欄填 `<起點>..`，所以照全域 `<起點>` 定義整格代入是常走的路
2. **步驟 4 的 ≥3 關卡丟了「要派 agent 時」前提**（A-1）。查證：`git show f46d4de:templates/global/CLAUDE.md` 裡「最少 3 個」那句在「主對話直接派審查者」子項內，排在「沒有人工寫的程式碼就不要派 agent」之後；搬上來後是無條件句，SKILL.md 開頭又寫「兩邊講法不同時以全域 §3.9 的關卡為準」
3. **CHANGELOG 把 context 收益寫成全面受益**（B-1、D-2）。查證：CHANGELOG `## 未發布`「每個專案、每個 session 都少載這一塊；跑迴圈時多載一次 skill」vs 全域 §3.9「每次都叫」與量測 README「總量會增加」
4. **`inject_chars` 量錯、6,188 無法重現**（B-2③、C-1、D-3、simplifier-2）。查證：p1-start-1.jsonl 裡 user 訊息依序是 `Launching skill: dd-loop`（tool_result，24 字元）、`Base directory for this skill: …`（本文）；check.sh 只量前者
5. **README 宣稱超出 `results.tsv`**（B-2①②、C-4）。查證：初版 check.sh 只抽 Skill 的 tool_use 與 `tool_name=="Skill"` 的 denials
6. **`run.sh` 相對路徑靜靜不產出**（C-2、simplifier-1）。查證：子 shell 先 `cd` 再導向 `$W/out/…`；兩邊都用假 `claude` 實測過
7. **沒有 result 時 `denied_skill=0` 像通過**（C-3）。查證：只留 n1-typo-1.jsonl 前 3 行跑初版，`denied_skill=0`

### 採納（Smells）

- 「每次省 5,042」沒扣 skill 清單多出的 description 167 字元（C-S1）
- stderr 混進 jsonl（simplifier-4；C 判 Not reported，理由是會大聲失敗。仍採納，因為改成另存的成本是一個重導向）
- 工作目錄放 repo 底下會載入祖先 CLAUDE.md（C 的 Not reported）

### 駁回

- simplifier-3（`mkfix()` 改 subshell、git 身分只設一次）：不改行為，`results.tsv` 是這支腳本產生的證據，改寫法會讓「這份 tsv 是哪一版腳本跑的」多一個要交代的地方。不改
- D 的 Not reported「§7.4 與 §7.1 第 3 點字面張力」：同意 D 的判斷，§7.4 已明寫先後，dd-loop 本身也是 Skill 呼叫

### 需要外部查證（已查）

- 退路網址：`curl -sI https://github.com/kopp0510/claude-dd` → `HTTP/2 200`；`…/blob/main/skills/dd-loop/SKILL.md` → `HTTP/2 404`，因為 S1 還沒 push。**push 之後才成立**，這是使用者按 push 前的已知狀態
- 原始 jsonl 的 `permission_denials|length`、第一個 tool_use、本文長度：用 scratchpad 的原始 jsonl 以修正版 check.sh 重抽，結果進 `results.tsv`

## 處置

| # | 改了什麼 | 驗證 |
|---|---|---|
| 1 | 全域 §3.9 `<起點>` 那行加「只取 `..` 前面那段」；SKILL.md「段落起點與 `<起點>`」節寫這條與兩種壞法（漏掉工作目錄、exit 129）；步驟 8 那句改成引用上面，並把「輸出空白」改成「只列出還沒 commit 的那幾份」（A 的 Not reported） | 本機 CI 12 個 step 重跑全 exit 0；§3.9 步數仍 8 |
| 2 | 全域步驟 4 改成「要派 agent 時(不派的例外見 `dd-loop`),主對話平行派 `code-reviewer` **最少 3 個**」 | 同上 |
| 3 | CHANGELOG 改成「不跑迴圈的 session 淨省約 4.8k（修正後重量）；跑迴圈一段叫 4 次、每次約 6.2k，總量增加」並指向量測目錄 | — |
| 4、5、7 | check.sh 改量本文訊息、加 `result`、`first_tool`、`denials_total` 欄，欄位定義寫在檔頭；對**同一批** jsonl 重抽 `results.tsv`（沒重跑 `claude -p`）；README 註明重抽、改寫三項宣稱指向 tsv 欄位；設計文件 S1-2 量法那句補上實作時的發現 | 重抽結果：9 次 `result=ok`、`denials_total=0`；p2 兩發 `first_tool=Read`，其他正例 `Skill`，反例 `Grep`；`inject_chars` 6,188（p3-step4-2 為 6,217）。只留 3 行的 jsonl 印 `result=MISSING` |
| 6 | `run.sh` 把 `$W` 轉絕對路徑、stderr 另存、jsonl 空的就印警告 | 假 `claude` 跑 `run.sh relw` exit 0、`relw/out/` 有 jsonl 與 stderr；`shellcheck -S warning` exit 0 |
| Smells | README 與 CHANGELOG 改淨省約 4.8k（修正後重量）；README 補「工作目錄放 repo 外」 | — |

## 重疊與獨有項

- **重疊**（獨立抓到同一項，不是誤判）：
  - `..` 只在步驟 8：A、D
  - CHANGELOG 收益：B、D
  - `inject_chars`：B、C、D、simplifier
  - README 宣稱超出 tsv：B、C
  - `run.sh` 相對路徑：C、simplifier
- **獨有**：
  - A：步驟 4 關卡丟前提 —— 只有逐句對舊版的人看得到「這句原本在哪個子項底下」
  - C：沒有 result 時像通過；工作目錄放 repo 內的污染
  - D：依序跑時 `git diff X..` 是**靜默**漏掉工作目錄（A 只看到 exit 129 那種會報錯的）
