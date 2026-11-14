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
3. 刪掉本目錄裡 `LICENSE.txt`、`CLAUDE.md` 以外的檔，再把上游 `skills/security-audit/` 整份複製過來（只覆蓋的話，上游刪掉或改名的檔會留在這裡、跟著部署）；
   重加 `SKILL.md` 那兩處，vendored 行與本檔開頭的 commit 換成新的
4. 重跑第 2 步的 `diff -r`，要只剩「本 repo 改了什麼」那節的兩處插入與 `Only in` 的 `LICENSE.txt`、`CLAUDE.md`
5. `diff <clone>/LICENSE skills/security-audit/LICENSE.txt`，不同就換
6. `grep -n '\$[0-9]' skills/security-audit/SKILL.md` 要沒有輸出：帶參數叫 `/security-audit <要求>` 時，`SKILL.md` 內文的 `$<數字>` 會被換成參數、不報錯（根目錄 CLAUDE.md「新增 Skill 步驟」第 7 步；CI 不擋）
7. 跑下一節的測試
8. 第 2 步的 diff 動到分支表判準所說的條件句，或動到本檔引用的原句（四份 `.md` 都算；拿本檔「」裡的英文原句 `grep -F` 新版，找不到的就是被改了）時，
   照根目錄 CLAUDE.md「新增 Skill 步驟」第 3 步重跑相關分支的乾跑，更新本檔
9. `./install-dd-pipeline.sh --force`

## 測試

```bash
node --test skills/security-audit/validate-findings.test.cjs skills/security-audit/validate-coverage-ledger.test.cjs
```

不在 CI（Node 是安裝腳本的必要依賴，但加 CI step 不在收編範圍內）；改這個目錄就本機跑一次。2026-11-14 在 Node v24.22.1 跑，結尾印 `ℹ fail 0`。

兩支驗證器只驗 `findings.json` 與 `coverage-ledger.json`。`run-metadata.json` 沒有 schema、也沒有驗證器
（`grep -lE 'run_status|incomplete_reason' skills/security-audit/*.cjs skills/security-audit/report-schema.json` 回空），
所以終止狀態「`run_status: "incomplete"` 加理由」沒有任何機械檢查，只靠 parent 自己記得寫。

## 分支清單與標記

判準：`SKILL.md` 裡會改變寫不寫檔、派不派 agent、要不要停下來問的條件句。清單是人照判準掃出來的，不保證列全：
第一版 D1–D16 漏了 D1b、D5c2、D7b、D8b、D17，收編的 S2 步驟 4 審查才找到、補跑了乾跑。標記三種：

- **乾跑**：2026-11-14 每條派一個 sonnet subagent，只讀、不寫檔、不跑 node、不派 agent，以 claude-dd 為目標照文字走那一條，回報卡住、要猜、互相矛盾的原句；原句都用 `grep -F` 回對過本目錄的檔
- **試跑已實跑**：`docs/measurements/2026-11-14-security-audit-trial/` 那次真的跑完的 quick、budget 9
- **不另跑**：附理由

| 分支 | 在哪一節 | 標記 |
|---|---|---|
| D1 Guidance mode（一個安全問題，不派 agent） | Operating modes | 乾跑 |
| D1b Guidance mode 派 focused agent | Operating modes | 乾跑 |
| D2 兩種模式都說得通時先問一題 | Operating modes | 乾跑 |
| D3 控制項不能全部強制 → 不執行目標碼、記 `needs_validation` | Universal execution safety | 試跑已實跑 |
| D4 控制項都能強制 → scratch promotion | Universal execution safety、Write isolation | 乾跑（只走文字；沙盒執行與 promotion 都沒實際做） |
| D5a 使用者指定 target 外的輸出目錄 | Full audit setup | 試跑已實跑 |
| D5b 沒指定時的預設輸出路徑 `~/security-audit-skill/<repo-name>/run-<N>` | Full audit setup | 乾跑；S2 步驟 5 用 `claude -p` 實跑對照：解出 `run-2`，與跑之前算的相同（`docs/measurements/2026-11-14-security-audit-trigger/`） |
| D5c 輸出目錄在 target 內、版控沒忽略 → 停下要外部路徑 | Full audit setup | 乾跑 |
| D5c2 輸出目錄在 target 內、版控忽略整個目錄 → 用它 | Full audit setup | 乾跑 |
| D5d 「Update metadata only when those facts change」 | Write isolation | facts 變了：試跑已實跑（`plan_revision`）；facts 沒變：不另跑（「不做事」那半乾跑觀察不到差別） |
| D6 有 prior ledger | Coverage and prior runs | 乾跑（拿一個真實的 quick prior run 走）；沒有 prior ledger：試跑已實跑 |
| D7 quick | Run profiles and scope | 試跑已實跑（最終 critic 沒有接受新工作） |
| D7b quick 的最終 critic 接受新工作 → 記 `deferred`、不開第二波 | Run profiles and scope | 乾跑 |
| D8 standard（沒指定 profile 時的預設） | Run profiles and scope | 乾跑 |
| D8b parent 依 target 大小與風險自己提議 profile | Run profiles and scope | 乾跑 |
| D9 deep | Run profiles and scope | 乾跑 |
| D10 scoped run | Run profiles and scope | 乾跑 |
| D11a 使用者設了 budget | Cost budget | 試跑已實跑 |
| D11b 沒設 budget（target 不大，parent 不提議） | Cost budget | 乾跑 |
| D11c target 大、parent 自己提議 budget | Cost budget | 乾跑 |
| D12 撐不起偵察與保留額 | Cost budget | 乾跑 |
| D13 後面的 wave 保不住 critic 保留額 | Cost budget | 乾跑 |
| D14a wave 1 前估算明顯不夠 | Cost budget | 乾跑 |
| D14b final-critic 保留額被吃掉 | Cost budget | 乾跑 |
| D15 驗證預算用完 | Cost budget | 乾跑 |
| D16 兩種終止狀態 | Full audit workflow | (a) 全部寫完且驗證器通過：試跑已實跑；(b) incomplete：不另跑，由 D12、D14b、D15 的乾跑走到（D13 停在 `in_progress`、D14a 停在 wave 1 之前，都沒走到） |
| D17 focused reconnaissance：每多一次重跑 gate，擋下就把沒涵蓋的區域種成 `deferred` | Cost budget（另見 RECONNAISSANCE.md） | 乾跑 |

乾跑判「做不完」的只有 D11c（target 大、沒設 budget）。卡在兩處：parent 要提議 budget 得先知道 unit 數，unit 要偵察後才有，偵察前卻要先過 gate
（乾跑靠情境給的 60 個 unit 才算出提議數字）；提議之後使用者不回應時，文字沒寫下一步。同樣「使用者不回應」的 D14a 走得完，
因為 HUNTING.md 有不需要使用者的後路（見下一節第一組）。其餘分支都走得完，要猜的地方記在下一節。
D11c 照設計文件 A6 交使用者決定，2026-11-14 選「照收，記成已知限制」（U9）：互動使用時自己先設 budget、或回答 parent 提議的數字就避開；headless 跑大 target 時先設 budget。

## 乾跑發現

收錄原則：每份乾跑報告【結論】點名的條目都收（結論用範圍帶過的併成一句；同一句被幾份撞到也合併），其餘只收兩條以上分支撞到的；收之前拿四份 `.md` 找過反例，
上游其實有寫、只是分散在別處的，寫成「散在哪幾句」而不是「沒寫」。乾跑報告本身只在 scratchpad，不進 repo。
按句子分組，同一句被好幾條分支撞到的排前面；括號是撞到它的乾跑代號。

**沒有使用者可以回答時（`claude -p`、headless）**

- 三處「propose」都沒寫提議之後要不要等使用者回答、沒回答時怎麼做：budget 的「or the parent proposes one for a large target」（D11c）、
  profile 的「or propose one from the target's size and stakes」（D8b）、wave 1 前的「propose either a tighter scope or a coarser profile instead of silently thinning evidence」（D14a）。
  對照：strict gate 不過的那條有「If the request remains unchanged」的後續（D12）；D14a 那處另有 HUNTING.md 的「Shrink the hunter wave to fit, taking units in priority order.」
  與「a unit the budget cannot reach is explicitly `deferred`」可以照做，不必等使用者
- 「提議了但使用者沒確認」的 budget 算 set 還是 unset 沒寫：Cost budget 要把 parent 提議的值記進 `budget`，metadata 那句卻是「`budget` (null if unset)」（D11c）
- 「The default is `standard`.」與「propose one from the target's size and stakes」哪個先沒寫，size 與 stakes 也沒有門檻（D8b）
- 試跑看到的相關情況（不是文字缺口）：Cost budget 只算 agent 次數，美元上限不在它的模型裡。試跑的 session 預估 US$15 上限撐不起第二個獵人，
  自己把獵人從 2 個減成 1 個、記進 `run-metadata.json` 的 `plan_revision`，照 HUNTING.md「If time or resources force an early stop, mark every untouched unit `deferred`」
  把沒做的 unit 標 `deferred` 並在報告寫明 partial pass

**預算算式**

- Strict budget gate 的最低保留額（「Reserve the four baseline reconnaissance calls, one final post-wave critic for `quick` or one post-wave plus one distinct final-clean critic for `standard`/`deep`, and at least one verifier call.」）不含任何 hunter：
  預算剛好等於最低額時 gate 會過，hunting allowance 卻是 0（D12、D17）。這時該停在哪個終止狀態沒寫：列出的三個 `incomplete_reason` 都對不上，寫完一份全部 `deferred` 的報告走 (a) 也說得通（D17）
- gate 不過時的選項「ask for a larger budget, narrower scope, or different profile」：最低保留額跟範圍大小無關，縮範圍過不了 gate（D12）
- 「when in doubt reserve 30% of the balance after critic reservation」：balance 從哪裡算起沒寫（總額減 critic，或再減偵察）（D11c、D13）；
  同一句的「about 1 or 2 agents per expected candidate」，expected candidate 數沒有估法、也沒有整數算式（D14a、D14b）；「implied hunter count」也沒有從 unit 數換算的規則（D14a）
- 每個 candidate 要保留幾個 verifier 散在三句，要自己拼：SKILL.md「one surviving candidate is one or two verifier assignments depending on profile」、
  「Also reserve verifier cost from the profile」，與 VALIDATION-AND-REPORTING.md「Every other profile keeps the two passes separate.」（quick 1 個，standard、deep 是 Phase 3 加 Phase 5 共 2 個）。
  「Count reconnaissance, every post-wave critic, and the separate final-clean critic as agent invocations.」沒列 verifier（D11c、D13、D15）
- 「Before wave 1, update the pre-recon estimate」：偵察前只有 gate，沒有一份可以 update 的估算，估算要寫到哪也沒寫（D11c、D14a、D17）；
  而 parent 要提議 budget 得先知道 unit 數，unit 要偵察後才有，「Apply the strict budget gate before launching any reconnaissance agent.」卻在偵察前（D11c）
- 後面的 wave 保不住保留額時（「If the remaining budget cannot cover the required critic calls and validation reserve」，記 `deferred`、用保留的 final-clean critic 記缺口），
  與「If later facts consume the required final-critic reserve」（記 incomplete `critic_budget_exhausted`）的分界沒寫，「later facts」指什麼也沒定義（D13、D14b）；
  被擋的 wave 之後，保留的 final-clean critic 吃什麼輸入、什麼時候觸發沒寫（D13）；quick 沒有 final-clean critic，這句在 quick 怎麼套沒寫（D17）；
  `critic_budget_exhausted` 那條要把 planned work 標 `deferred`，unit 的 reason 寫什麼沒寫（D14b）
- 驗證預算不夠時的「validate candidates in fingerprint order while the budget permits」：standard 一個 candidate 算一次還是兩次（Phase 3 加 Phase 5）、fingerprint 升冪還是降冪沒寫；
  只經 Phase 3 驗過的記錄算不算「An incomplete run may report independently verified records」的 independently verified 沒寫；「that unresolved reason」是 `validation_budget_exhausted` 字串還是自由文字也沒寫（D15）
- 沒設 budget 時，除了「`budget` (null if unset)」與報告的「budget (if set)」，沒有一句說 gate 與保留額要不要套用（D11b）；
  hunter 數量只有「Use enough focused hunters to cover the units without combining unrelated boundaries」，沒有量（D11b）

**profile 與 scope**

- deep 的「run critic waves to a clean pass」「keep candidate validation and final record verification as separate fresh agents」，配套檔裡 standard 也一樣：
  HUNTING.md「In `standard` and `deep`, when the post-wave critic reports no accepted」、VALIDATION-AND-REPORTING.md「Every other profile keeps the two passes separate.」（D9）；
  critic 輪數沒有上限（D9）
- deep 的「give `prior_covered_same_source` units an independent second pass」與 RECONNAISSANCE.md「then use the coverage critic to decide whether it needs another pass.」不一致，
  independent 也沒定義（D9）
- scoped 跟 profile 是兩條獨立的軸、還是 scoped 暗示 quick，沒寫；只能從 metadata 同時有 `profile`、`scope_paths` 反推並存（D10）
- scoped：SKILL.md「record everything else as `out_of_scope`」與 RECONNAISSANCE.md「retain discovered excluded surfaces as `out_of_scope` units」管的範圍不同；`scope_paths` 的格式沒定義，沒有 scoped 時填什麼也沒寫（D8、D8b、D10）
- scoped 的 `out_of_scope` unit 粒度、trace 能不能讀到範圍外、prior run 怎樣算「compatible」都沒寫；「states plainly that it is a partial pass」沒給措辭與位置（D10）

**檔案形狀**

- `run-metadata.json` 沒有 schema（見「測試」那節）。SKILL.md 列了至少要有的鍵（「Before delegation, the parent writes `run-metadata.json` with at least」那句），
  也寫了 `budget` 是「a maximum number of agent invocations across all phases」；試跑的 session 卻把 `budget` 寫成物件（含 `max_agent_invocations`、`plan_revision` 等鍵），偏離了這句，沒有東西擋。
  那句裡 selected companion files、prior-run paths、shared-file owners 三項沒給鍵名，`run_id` 與這三項的格式也沒定義（D8、D12）
- 「Before delegation, the parent writes `run-metadata.json`」要求的欄位裡有 selected companion files，但 companion 要偵察後才選得出來（D8）
- RECONNAISSANCE.md 狀態表的 `candidate` 列，`unresolved` 那格是 `optional`；SKILL.md 卻要「Keep each unvalidated fingerprint linked to a `candidate` ledger unit with that unresolved reason.」，
  驗證器照表放行，沒寫理由也會過（D15）
- ledger 沒有放驗證結果的欄位：VALIDATION-AND-REPORTING.md 要「record the decision in every linked coverage unit」，已驗與未驗的 candidate 卻都是 `candidate`，
  「Set `run_status: "complete"` only when every ledger candidate has an independent final disposition」因此沒辦法從 ledger 判（D15）
- gate 不過、一個 agent 都沒派時要寫哪些檔沒寫，沒有 ledger 時報告的覆蓋那節從哪裡來也沒寫（D12）
- prior-run 規則 4「Make prior `needs_validation`, `deferred`, `blocked`, `out_of_scope`, and any changed-source unit current work.」沒列 `candidate`（D6）
- critic 回報新 unit 的 JSON 要填具體的 `"subsystem"`，quick 的 ledger 卻規定用固定值 `profile/quick/all-in-scope-subsystems`，critic 給的值要丟掉還是另存沒寫（D7b）
- 沒偵察到的區域種成 `deferred` unit 時（D17），unit 要的 boundary、attack class 都還不知道，怎麼填沒寫

**執行邊界與寫入隔離**

- 輸出目錄在 target 內（D5c2）時，`scratch/` 也在 target 內：沙盒要的「a read-only target and toolchain, with the target-controlled process able to write only inside its assigned `scratch/` directory」
  要怎麼同時成立沒寫；hunter 掃 target 時要不要排除輸出目錄也沒寫（D5c2）
- promotion 要 parent 用 fd 級、no-follow 的操作（Write isolation 的「never reopen by path」），Claude Code 沒有現成工具，要 parent 自己寫程式（D4）。
  做不到時上游有寫：Write isolation 第 11 步「if it is decisive evidence, retain `needs_validation` with the exact promotion blocker」；沒實跑過
- promotion 只驗型別與大小，「only trusted parent-side code may promote the minimum non-secret result」的 non-secret 沒有對應的檢查步驟（D4）
- promote 的檔要在執行前列進 allowlist，名單外的檔不 promote、也不當證據（第 10 步禁止 glob scratch）；名單能不能在執行後擴充沒寫（D4）
- Guidance mode 派的 focused agent（「You may launch focused agents when useful; they return results to the current task.」）：派幾個、哪種角色、結果什麼形式都沒寫；
  Write isolation 寫在 Full audit setup 底下，guidance 沒有輸出目錄，派出的 agent 要不要套、`scratch/` 放哪裡沒寫，而同一節又禁止「Do not use `/tmp` or the host home directory as a writable fallback.」（D1、D1b、D2）

**其他**

- 「This skill is agent-neutral」那段的 `research`、`general` 角色，Claude Code 沒有同名 agent（D1、D1b）；試跑的 session 對應成 Explore 與 general-purpose（試跑 README 的「agent 次數」那列）
- 「If the request could mean either mode, ask one focused question」沒給問句（D2）；guidance 的「use only the relevant parts of this skill」沒說哪些部分、配套檔能不能用；
  使用者答「不用產出報告」只對到 full audit 觸發條件裡的「requests report artifacts」，算不算排除 full audit 沒寫（D2）
- 「the parent verifies that version control ignores the whole directory」：目錄還不存在時怎麼驗沒寫（D5c、D5c2）；
  使用者自選的輸出目錄要不要再加 `run-<N>` 一層、prior runs 要去哪找也沒寫（D5c、D5c2）
- 「Source ref」要記 worktree 是不是 dirty，dirty 時要不要記是哪些檔、那些改動算不算在審查範圍沒寫（D5c2、D6）

乾跑以 claude-dd 為目標時看到的目標內容（檔名、prior run 裡的記錄、本機路徑）不寫進本檔：這裡只記 skill 文字本身。

## 沒走過

- D5d 的「facts 沒變就不更新」那半
- D6 的 prior-run 規則 2、3（拿來走的 prior run 沒有 confirmed 記錄）；規則 4 的 `blocked`、`out_of_scope` 與「still-external 的 `needs_validation`」那半（prior ledger 沒有這兩種 status，那筆 `needs_validation` 的寫出點已經修掉）；
  規則 5 的 rejected 那半（prior run 的 `findings.json` 沒有 rejected）
- deep 對 `prior_covered_same_source` unit 的第二輪：拿來走的 prior run 是 quick，unit 粒度跟 deep 對不上，沒觸發（D9）；同源 covered unit 本身 D6 有走到
- D14b 的情境（wave 1 之後 focused recon 把預算吃到只剩 1 次）：照 Cost budget 的「Add focused reconnaissance only after repeating this gate for each extra call」做時到不了
- D4 的沙盒執行與 promotion
- standard、deep、scoped 特有的寫檔步驟（多一個 final-clean critic、deep 的兩段驗證者、scoped 的 `out_of_scope` unit）只乾跑、沒實跑；
  檔案組與兩支驗證器各 profile 相同（SKILL.md 的 shared run files 清單、「Profiles change breadth and redundancy, never the evidence bar」）
- ledger 的最終狀態，試跑只產生過 `covered`、`candidate`、`deferred`；`not_applicable`、`out_of_scope`、`blocked` 沒有實跑產生過；
  `deferred` 的 reason 試跑只產生過 `budget_cannot_reserve_critics_and_validation`，`quick_profile_final_critic` 只乾跑過（D7b）
