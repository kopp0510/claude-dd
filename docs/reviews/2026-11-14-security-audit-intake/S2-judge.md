# S2-judge：收編 cloudflare/security-audit-skill（S2）的查證

範圍：`git diff 6f2118a` 到工作目錄（aa9b162 S2-1、d36e5d6 S2-2，加上步驟 3 還沒 commit 的試跑 `check.sh` 與同目錄 CLAUDE.md），另含 S1 的 fc2ccb0（審查處置更新）。

## 派工

- 派了 4 個 `code-reviewer`（不帶 model，agent 定義是 opus），同一則訊息平行派出；派工 prompt 逐字記在 `S2-a.md`…`S2-d.md` 的「派工」節
- 為什麼 4 個：3 個全面審、各從不同的地方下手（a 漏掉的同步點、b 文件宣稱在 HEAD 還成立嗎、c 程式與試跑紀錄與去識別），
  第 4 個（d）專審 `skills/security-audit/CLAUDE.md` —— 它跟著 skill 部署到使用者的 `~/.claude/skills/`，這段 diff 裡引別處的宣稱最密的就是它
- 材料是 `<S>/s2-review/diff.txt`（925 行：①整段 diff、①-b SKILL.md 對上游的差異與 skill CLAUDE.md 整檔、②步驟 3 的改動、③整檔內容、④已跑過的驗證與預期值）；
  主對話派完自己把 diff 檔每次 300 行讀到最後一行
- ④ 的勘誤：④ 寫 SKILL.md 的 hunk 是「2a3、4a6,7」，實際 `diff` 是 `2a3`、`5a7,8`（①-b 那份對；插入內容相同）。S2-a、S2-b 提醒、S2-c 判成同一次插入；派工材料照當時送出的不改
- 4 份完整報告都收回（含 Not reported、What I ran），逐字存進 scratchpad 後落地

## 發現

### 讀檔檢查（每份抽一處自己讀）

- S2-a：上游 `README.md` Requirements 第三項（OS-enforced sandbox，「Without these controls, the workflow keeps the lead as `needs_validation`」）—— 對得上
- S2-b：`git show a0aa58a:docs/measurements/2026-11-14-dd-init-symlink/results.txt` 第 31、59 行有 Y 臂 —— 對得上
- S2-c：試跑 `check.sh` 的拒絕清單先 `.[0:140]` 再 `sed` 換路徑 —— 對得上
- S2-d：`report-D11b.txt` 第 4 點「依情境「target 不算大」，所以 parent 不提議 budget」—— 對得上

### 採納（Important）

- D11c 的歸因（S2-a 第 3 條、S2-b 第 1 條、S2-d 第 2 條）：report-D11c【結論】點名的主要缺口是循環依賴（提議 budget 要先有偵察後才有的 unit 數），
  同樣「使用者不回應」的 D14a 結論是做得完（靠 HUNTING.md 的後路）；「那是乾跑情境刻意給的」不成立，「答應就走 D11a、不設就走 D11b」是本 repo 的讀法（D11b 走的是 target 不大、不提議）。
  CHANGELOG 的「沒有一條走不下去」把這個條件壓掉了
- 「從上游更新」漏了 `$<數字>` 自查、重跑乾跑的條件只看 SKILL.md（S2-a 第 2 條、S2-b 第 4 條）
- 「上游沒寫」其實有寫（S2-a 第 4 條、S2-c 第 1 條、S2-d 第 4 條與第 9 條）：`budget` 的型別寫在 SKILL.md「as a maximum number of agent invocations across all phases」、鍵名列在「writes `run-metadata.json` with at least」那句；
  Phase 5 的 verifier 散在三句。④ 的引文回對只證明原句存在，沒證明缺口是真的
- 分支表漏列（S2-b 第 2 條、S2-d 第 6 條）：focused reconnaissance、guidance 派 agent、quick 最終 critic 接受新工作、parent 提議 profile、D5c 有忽略那邊，都符合表的判準
- 乾跑發現漏了報告【結論】點名的條目、也沒寫收錄原則（S2-b 第 3 條、S2-d 第 7 條）
- D16 (b) 列了沒走到 incomplete 的 D13、D14a（S2-d 第 1 條 Important；S2-b 第 6 條標 Smell，照較高的處理）
- balance 那條掛錯代號（S2-d 第 3 條）：只有 D11c-3、D13-1 講 balance 的起點
- headless 那組漏了 HUNTING.md 已有的後路（S2-d 第 5 條）：HUNTING.md「Shrink the hunter wave to fit, taking units in priority order.」、「a unit the budget cannot reach is explicitly `deferred`」；試跑那筆照 HUNTING.md 的 early stop 規則做了
- README 前置需求沒提上游要的沙盒（S2-a 第 1 條）
- 拒絕清單先截再換路徑，`results.txt` 撐不起 README「權限拒絕」那列（S2-c 第 2 條）

### 採納（Smell）

- `results.txt` 的探針、花費兩節沒有產生指令，probe2 會蓋掉 probe1（S2-a 第 5 條、S2-b 第 9 條、S2-c 第 4 條）
- CHANGELOG「試跑沒走到的各派一個 subagent 只讀乾跑」概括過頭（S2-b 第 7 條、S2-c 第 5 條）
- 試跑 README「公開 repo 所以不寫」的理由過期（S2-b 第 8 條、S2-c 第 6 條）
- 設計文件 A19 的 Y 臂歸因（S2-b 第 5 條）
- `git status --porcelain` 看不到被忽略的路徑（S2-c 第 3 條）
- 「從上游更新」不處理上游刪掉或改名的檔（S2-c 第 7 條）
- 「碰到 US$15 上限」：實際花 US$12.70，是預估撐不起（S2-d 第 8 條）
- D4 兩條把上游已處理的事寫成缺口（S2-d 第 10 條）：Write isolation 第 11 步「if it is decisive evidence, retain `needs_validation` with the exact promotion blocker」

### 駁回

無。

### 需使用者決定

- D11c 算不算設計文件 A6 說的「有分支因此不能用」（A6 規定要停下回報）。選項：照收、記成已知限制（建議）／暫不收編（revert S2 兩個 commit、S2 標 BLOCKED）。
  文件沒寫明：A6 只寫「不能用」，沒定義「要猜但互動時可避開」算不算

### 需要外部查證

- 部署後的 `~/.claude/skills/security-audit/CLAUDE.md` 在 `/security-audit` session 讀配套檔時會不會被當成巢狀記憶注入（S2-a、S2-b、S2-d；設計文件 A21③）：步驟 5 正向那發的 jsonl 查
- D5b 那發的 `ls ~/security-audit-skill/claude-dd/` 會不會被 dontAsk 擋（S2-c）：步驟 5 先用 haiku 探針
- 反向對照臂會不會因 clone 裡寫著「user-invoked」而不叫（S2-a 的提醒）：步驟 5 看對照臂有沒有叫起來，沒叫起來就判反向那發沒有鑑別力，換中性目錄重跑那一對
- Claude Code 自帶的 sandbox 能不能滿足上游四項控制（S2-a）：沒查，兩份 README 寫「沒驗證」
- dmi skill 帶參數叫時 `$1` 會不會被換（S2-a）：沒另外量；「從上游更新」第 6 步的自查照做就不必知道答案
- D11c 判做不完時主對話有沒有回報使用者（S2-b）：沒有，之前講的是「沒有一條分支走不下去」；這次更正並照 A6 問了

## 處置

- 需使用者決定那題：2026-11-14 使用者選「照收，記成已知限制」。記成設計文件 U9、`skills/security-audit/CLAUDE.md` 分支表下那段、CHANGELOG
- 逐條做了什麼見 `S2-a.md`…`S2-d.md` 的「處置」。改到的檔：`skills/security-audit/CLAUDE.md`（「從上游更新」、分支表、表下那段、乾跑發現、沒走過）、
  兩份 README（前置需求）、CHANGELOG `## 未發布`、設計文件（U9、A19、S2-1 第 2 步的 D16 註記、試跑那筆的來源句）、試跑目錄的 `check.sh`、`README.md`、`CLAUDE.md`
- 補跑的乾跑：D1b、D5c2、D7b、D8b、D17 各派一個 sonnet subagent（只讀，prompt 照原本 D12 那份的格式改分支與情境），五份結論都是做得完；
  原句 28 條 `grep -F` 回對 26 條命中，D5c2-3 是原句含粗體標記、D5c2-5 是改寫，兩條都沒被引進 skill CLAUDE.md
- 改完後跑過的驗證：
  - skill CLAUDE.md 裡「」括起來、含英文的上游原句，`grep -F` 對四份 `.md` 全部命中（沒命中的 8 筆都是中文句子，不是上游原句）；分支表從表頭到 D17 那列每行都以 `|` 開頭
  - 試跑 `check.sh` 改完用同一份輸入重跑：`bash` 與 `/bin/bash`（3.2.57）的整份輸出都與 `results.txt` 逐字相同（diff rc=0），`shellcheck -S warning` 過；
    `git -C <S>/target/claude-dd status --porcelain --ignored` 0 行
  - A14：skill CLAUDE.md 沒寫進 claude-dd 目標的內容（`grep -nE 'install-dd-pipeline|\.drafts|githooks|check-claude-md|my_project|dd-init'` 只命中「從上游更新」第 9 步的安裝指令）；
    這 5 份報告落地前掃過 `<使用者名>|/Users/|-Users-|/private/tmp`，只剩審查者描述 grep 樣式的兩句
- 步驟 5 照上面「需要外部查證」那三條調整：D5b 先跑 haiku 探針、正向那發查注入、反向對照沒叫起來就換中性目錄

## 重疊與獨有項

重疊（兩個以上審查者各自抓到）：

- D11c 歸因與 CHANGELOG 的「沒有一條走不下去」：a、b、d（c 抓的是同一句 CHANGELOG 的概括）
- `run-metadata.json`「鍵與型別沒定義」其實有寫：a、c、d
- `results.txt` 後兩節沒有產生指令、probe 互蓋：a、b、c
- Phase 5 verifier 其實有寫：a、d
- `$<數字>` 自查與更新步驟：a、b
- D16 (b)：b、d
- 分支表漏列：b（focused recon）、d（guidance 派 agent、quick critic、提議 profile、D5c 有忽略）
- 乾跑發現漏收：b、d
- 試跑 README 過期的理由：b、c
- ④ 的 hunk 勘誤：a、b、c
- A21③ 的注入問題：a、b、d

獨有：

- a：README 前置需求沒提沙盒；反向對照臂可能被 clone 裡的「user-invoked」壓住
- b：設計文件 A19 的 Y 臂歸因；D11c 有沒有照 A6 回報使用者
- c：拒絕清單先截再換路徑；`--ignored`；上游刪檔不會被清；D5b 那發可能被 dontAsk 擋
- d：balance 掛錯代號；headless 那組漏了 HUNTING.md 的後路；US$15 不是真的碰到；D4 兩條上游其實處理了；「沒走過」漏了五處

S2-d 是唯一專審一份檔的，它的 10 條全部採納，其中 5 條是另外三份沒有的 —— 只派全面審的話，skill CLAUDE.md 裡「上游其實有寫」的那幾條大多會漏掉。
