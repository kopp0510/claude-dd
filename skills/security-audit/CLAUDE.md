# skills/security-audit

Vendored 自 [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill)（MIT），上游 commit `c1c8a8c`，2026-11-14 收編。
user-invoked：frontmatter 有 `disable-model-invocation: true`，只在使用者打 `/security-audit` 時載入。
收編的計畫與決策在 `docs/designs/2026-11-14-security-audit-intake-design.md` 的 S2；試跑紀錄在 `docs/measurements/2026-11-14-security-audit-trial/`。

## 本 repo 改了什麼

- `SKILL.md` 兩處插入：frontmatter `name:` 下一行的 `disable-model-invocation: true`；frontmatter 結束後的 `> Vendored from` 那一行
- 加了 `LICENSE.txt`（上游根目錄 `LICENSE` 原文）與本檔
- 其餘檔逐字等於上游。驗法：`diff -r <上游 clone>/skills/security-audit skills/security-audit`，只剩上面兩處插入與 `Only in` 的 `LICENSE.txt`、`CLAUDE.md`

⚠️ 下面「乾跑發現」只記上游文字哪裡沒寫清楚，**不寫「本 repo 這樣讀」**：`SKILL.md` 的 vendored 行宣稱「其餘內容未改」，
在這裡補一句解讀等於靜靜改了行為。要改行為就改上游文字本身，並同批改掉 vendored 行與本節。

## 從上游更新

1. `git clone https://github.com/cloudflare/security-audit-skill` 到 scratchpad（不要放進 repo）
2. `diff -r <clone>/skills/security-audit skills/security-audit` 看上游改了什麼
3. 用上游的檔覆蓋過來，重加 `SKILL.md` 那兩處，vendored 行與本檔開頭的 commit 換成新的
4. `diff <clone>/LICENSE skills/security-audit/LICENSE.txt`，不同就換
5. 跑下一節的測試
6. 上游動到「分支清單」那類條件句時，照根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步重跑那幾條的乾跑，更新本檔
7. `./install-dd-pipeline.sh --force`

## 測試

```bash
node --test skills/security-audit/validate-findings.test.cjs skills/security-audit/validate-coverage-ledger.test.cjs
```

不在 CI（Node 是安裝腳本的必要依賴，但加 CI step 不在收編範圍內）；改這個目錄就本機跑一次。2026-11-14 在 Node v24.22.1 跑，結尾印 `ℹ fail 0`。

兩支驗證器只驗 `findings.json` 與 `coverage-ledger.json`。`run-metadata.json` 沒有 schema、也沒有驗證器
（`grep -lE 'run_status|incomplete_reason' skills/security-audit/*.cjs skills/security-audit/report-schema.json` 回空），
所以終止狀態「`run_status: "incomplete"` 加理由」沒有任何機械檢查，只靠 parent 自己記得寫。

## 分支清單與標記

判準：`SKILL.md` 裡會改變寫不寫檔、派不派 agent、要不要停下來問的條件句。標記三種：

- **乾跑**：2026-11-14 每條派一個 sonnet subagent，只讀、不寫檔、不跑 node、不派 agent，以 claude-dd 為目標照文字走那一條，回報卡住、要猜、互相矛盾的原句；原句都用 `grep -F` 回對過本目錄的檔
- **試跑已實跑**：`docs/measurements/2026-11-14-security-audit-trial/` 那次真的跑完的 quick、budget 9
- **不另跑**：附理由

| 分支 | 在哪一節 | 標記 |
|---|---|---|
| D1 Guidance mode（一個安全問題） | Operating modes | 乾跑 |
| D2 兩種模式都說得通時先問一題 | Operating modes | 乾跑 |
| D3 控制項不能全部強制 → 不執行目標碼、記 `needs_validation` | Universal execution safety | 試跑已實跑 |
| D4 控制項都能強制 → scratch promotion | Universal execution safety、Write isolation | 乾跑（只走文字；沙盒執行與 promotion 都沒實際做） |
| D5a 使用者指定 target 外的輸出目錄 | Full audit setup | 試跑已實跑 |
| D5b 沒指定時的預設輸出路徑 `~/security-audit-skill/<repo-name>/run-<N>` | Full audit setup | 乾跑；另由 S2 步驟 5 用 `claude -p` 實跑對照（未執行） |
| D5c 輸出目錄在 target 內（要版控忽略整個目錄，否則停下要外部路徑） | Full audit setup | 乾跑 |
| D5d 「Update metadata only when those facts change」 | Write isolation | facts 變了：試跑已實跑（`plan_revision`）；facts 沒變：不另跑（「不做事」那半乾跑觀察不到差別） |
| D6 有 prior ledger | Coverage and prior runs | 乾跑（拿一個真實的 quick prior run 走）；沒有 prior ledger：試跑已實跑 |
| D7 quick | Run profiles and scope | 試跑已實跑 |
| D8 standard（沒指定 profile 時的預設） | Run profiles and scope | 乾跑 |
| D9 deep | Run profiles and scope | 乾跑 |
| D10 scoped run | Run profiles and scope | 乾跑 |
| D11a 使用者設了 budget | Cost budget | 試跑已實跑 |
| D11b 沒設 budget | Cost budget | 乾跑 |
| D11c target 大、parent 自己提議 budget | Cost budget | 乾跑 |
| D12 撐不起偵察與保留額 | Cost budget | 乾跑 |
| D13 後面的 wave 保不住 critic 保留額 | Cost budget | 乾跑 |
| D14a wave 1 前估算明顯不夠 | Cost budget | 乾跑 |
| D14b final-critic 保留額被吃掉 | Cost budget | 乾跑 |
| D15 驗證預算用完 | Cost budget | 乾跑 |
| D16 兩種終止狀態 | Full audit workflow | (a) 全部寫完且驗證器通過：試跑已實跑；(b) incomplete：不另跑，由 D12、D13、D14a、D14b、D15 的乾跑走到 |

沒有一條分支走不下去。乾跑判「做不完」的只有 D11c，停在「使用者沒回應」—— 那是乾跑情境刻意給的；
使用者有回答時，答應就走 D11a、不設就走 D11b，兩條都有人走過。

## 乾跑發現

按句子分組，不按分支：同一句被好幾條分支各自撞到的排前面。括號是撞到它的乾跑代號。

**沒有使用者可以回答時（`claude -p`、headless）**

- Cost budget 的「or the parent proposes one for a large target」與「propose either a tighter scope or a coarser profile instead of silently thinning evidence」只寫「提議」，
  沒寫使用者不回應時怎麼做（D11c、D14a）。對照：strict gate 不過的那條有「If the request remains unchanged」的後續（D12）
- 試跑看到同一類缺口：Cost budget 只算 agent 次數，美元上限不在它的模型裡。試跑的 session 碰到 US$15 上限，自己把獵人從 2 個減成 1 個，
  記進 `run-metadata.json` 的 `plan_revision`（有記，不是靜默），但 `-p` 底下沒有使用者可以接這個調整

**預算算式**

- 「when in doubt reserve 30% of the balance after critic reservation」沒寫 balance 從哪裡算起（總額減 critic，或再減偵察）（D11c、D13、D14a、D14b）
- 「Before wave 1, update the pre-recon estimate」：偵察前只有 gate，沒有一份可以 update 的估算（D11c、D14a）；
  而 parent 要提議 budget 得先知道 unit 數，unit 要偵察後才有，「Apply the strict budget gate before launching any reconnaissance agent.」卻在偵察前（D11c）
- 「Count reconnaissance, every post-wave critic, and the separate final-clean critic as agent invocations.」沒列 Phase 5 的 fresh verifier，
  驗證保留額要不要把它算進去沒寫（D11c、D13、D15）
- 「If the remaining budget cannot cover the required critic calls and validation reserve」（那個 wave 記 `deferred`、用保留的 final-clean critic 記缺口）與
  「If later facts consume the required final-critic reserve」（不派 hunter、incomplete `critic_budget_exhausted`）觸發條件都是預算不夠，優先序沒寫；
  被擋的 wave 之後，那次保留的 final-clean critic 吃什麼輸入也沒寫（D13、D14a、D14b）
- 沒設 budget 時，除了「`budget` (null if unset)」沒有一句說 gate 與保留額要不要套用（D11b）

**profile 與 scope**

- deep 的「run critic waves to a clean pass」「keep candidate validation and final record verification as separate fresh agents」，配套檔裡 standard 也一樣：
  HUNTING.md「In `standard` and `deep`, when the post-wave critic reports no accepted」、VALIDATION-AND-REPORTING.md「Every other profile keeps the two passes separate.」（D9）；
  critic 輪數沒有上限（D9）
- deep 的「give `prior_covered_same_source` units an independent second pass」與 RECONNAISSANCE.md「then use the coverage critic to decide whether it needs another pass.」不一致，
  independent 也沒定義（D9）
- scoped：SKILL.md「record everything else as `out_of_scope`」與 RECONNAISSANCE.md「retain discovered excluded surfaces as `out_of_scope` units」管的範圍不同；`scope_paths` 的格式沒定義（D10）

**檔案形狀**

- `run-metadata.json` 的鍵與型別沒定義：`budget` 在試跑裡寫成物件（含 `max_agent_invocations`、`plan_revision` 等鍵），乾跑讀成一個數字（D12、D14b、D15）
- RECONNAISSANCE.md 狀態表的 `candidate` 列，`unresolved` 那格是 `optional`；SKILL.md 卻要「Keep each unvalidated fingerprint linked to a `candidate` ledger unit with that unresolved reason.」，
  驗證器照表放行，沒寫理由也會過（D15）
- 「Before delegation, the parent writes `run-metadata.json`」要求的欄位裡有 selected companion files，但 companion 要偵察後才選得出來（D8）
- gate 不過、一個 agent 都沒派時要寫哪些檔沒寫（D12）
- prior-run 規則 4「Make prior `needs_validation`, `deferred`, `blocked`, `out_of_scope`, and any changed-source unit current work.」沒列 `candidate`（D6）

**執行邊界與寫入隔離**

- promotion 要 parent 用 fd 級、no-follow 的操作（Write isolation 的「never reopen by path」），Claude Code 沒有現成工具做這件事，要 parent 自己寫程式，文字沒提供（D4）。
  會不會因此落到 `needs_validation`：沒驗證
- promotion 只驗型別與大小，「only trusted parent-side code may promote the minimum non-secret result」的 non-secret 沒有對應的檢查步驟（D4）
- 要 promote 的檔要在執行前列進 allowlist，hunter 事後產出名單外的檔怎麼辦沒寫（D4）

**其他**

- 「This skill is agent-neutral」那段的 `research`、`general` 角色，Claude Code 沒有同名 agent（D1）；試跑的 session 對應成 Explore 與 general-purpose（試跑 README 的「agent 次數」那列）
- 「If the request could mean either mode, ask one focused question」沒給問句（D2）
- 「the parent verifies that version control ignores the whole directory」：目錄還不存在時怎麼驗沒寫（D5c）

乾跑以 claude-dd 為目標時看到的目標內容（檔名、prior run 裡的記錄、本機路徑）不寫進本檔：這裡只記 skill 文字本身。

## 沒走過

- D5d 的「facts 沒變就不更新」那半
- D6 的 prior-run 規則 2、3 與規則 5 的 rejected 那半：拿來走的 prior run 沒有 confirmed 記錄
- `prior_covered_same_source`：拿來走的 prior run 是 quick，unit 粒度跟 deep 對不上，沒觸發（D9）
- D14b 的情境（wave 1 之後 focused recon 把預算吃到只剩 1 次）：照 Cost budget 的「Add focused reconnaissance only after repeating this gate for each extra call」做時到不了
- D4 的沙盒執行與 promotion
- standard、deep、scoped 特有的寫檔步驟（多一個 final-clean critic、deep 的兩段驗證者、scoped 的 `out_of_scope` unit）只乾跑、沒實跑；
  檔案組與兩支驗證器各 profile 相同（SKILL.md 的 shared run files 清單、「Profiles change breadth and redundancy, never the evidence bar」）
- ledger 的最終狀態，試跑只產生過 `covered`、`candidate`、`deferred`；`not_applicable`、`out_of_scope`、`blocked` 沒有實跑產生過
