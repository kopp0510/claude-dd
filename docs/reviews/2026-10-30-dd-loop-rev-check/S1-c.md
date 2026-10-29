# S1-c — 審查者 C（dd-loop-rev 跳號檢查）

## 派工

> 你是 code-reviewer，代號 C。審查範圍：git diff 2bd0014 848ea70（claude-dd repo，/Users/danlio/project/my_project/claude-dd）。新增一個 CI step：改了 commands/dd-init.md 的蓋章區塊卻沒跳 dd-loop-rev 就紅燈；同批把根 CLAUDE.md 那段說明縮短、補 DD_PIPELINE_ARCHITECTURE.md CI 防線表與 CHANGELOG、開進度表。
> 
> 材料：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/rb-diff.txt。用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷）。被改到的檔用 git show 848ea70:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。材料 ④ 的驗證已確認，不要重跑。
> 
> 你的方向：同步點：repo 裡還有誰寫著「CI 不驗 rev 有沒有跳」或描述 CI 防線清單、step 數（git grep 「dd-loop-rev」「不驗」「CI 防線」「跳號」等，含 UPGRADING.md、README 兩份、commands/dd-init.md、scripts/CLAUDE.md、templates/）；根 CLAUDE.md 的「CI 不驗、只能手動同步的區塊」清單與「新增 ci.yml 檢查 step 必做負面測試、同批補 CI 防線表」這兩條規則有沒有照做；CHANGELOG 條目與架構文件新列是否描述了實際行為；進度表與指路句是否照 skills/task-planner/SKILL.md「進度表格式」
> 
> 職責：找漏洞，每條附證據（路徑:行號、原文、或指令與輸出），沒證據不算。只用手上的資料判斷；需要外部查證的列出來交回。不要改檔、不要 commit。
> 
> 輸出格式：第一行「Critical N / Important N / Smells N」；## Findings（每條 [級別] 路徑:行｜一句話；證據；失敗情境）；## Not reported（看到但不報的與理由）；## What I ran；## 需要外部查證。

## 發現

Critical 0 / Important 2 / Smells 0 — git diff 2bd0014 848ea70（被改到的檔讀 848ea70 版）

## Findings

[Important] CLAUDE.md:273（848ea70）｜新規則「同一次發版改好幾次區塊，只要跳一次號」放寬了舊規則，但沒說明理由，跟 repo 的前例也不合
- 證據：舊文寫「動到…蓋章區塊…就必須同步跳 `dd-loop-rev`」，是每次改都要跳（rb-diff.txt ③ 第 181–182 行）。前例是同一版內跳了兩次：v1.6.5 的 rev=9，v1.6.6 的 rev=11（指令在下方）；CHANGELOG.md:131、:138 記的 9→10 與 10→11 兩條 rev 都在同一版內。另外，部署走的是 repo 工作目錄，不是 tag：CLAUDE.md「開發本 repo」寫「安裝腳本不帶 `--force` 也會覆蓋部署那份…驗證完 commit 後再重跑，其他專案才會用到新版」。
- 失敗情境：commit X 改了區塊 A，rev 12→13。作者 `--force` 安裝後到 lawdesk-ai 跑 `/dd-init`，蓋上 rev 13。之後 commit Y 改了區塊 B 但沒跳號。CI 拿 v1.6.11（rev 12）當基準比，13>12 判綠。lawdesk-ai 再跑 `/dd-init` 會被告知「已是現行版」，拿不到 B。CI 改用 tag 當基準本身是設計取捨，但「只要跳一次號」這句寫進規則後，連人工都不會補跳。這要使用者決定：(a) 規則文字維持「每次改都跳」，CI 只當下限；(b) 接受放寬，並註明「從 main 安裝的專案可能卡在未發布的 rev」。

[Important] CLAUDE.md:281、:284（848ea70）｜④ 列了「`UPGRADING.md` 寫死的 rev 值」，結尾又說「③、④ CI 不驗」。但 UPGRADING.md 唯一寫死 rev 的那行，就是 ② 那條有 CI 驗的「判定為舊版」判定線
- 證據：在 `git show 848ea70:UPGRADING.md` 裡 grep `rev`，只命中 :82「…`8step` 但 rev 比 12 舊的，會被判定為舊版…」。ci.yml:342 `for spec in … "UPGRADING.md:判定為舊版"` 會拿這行的 rev 與 `cur_rev` 比對。
- 失敗情境：同一段裡，② 說這行 CI 有驗，④ 又說 CI 不驗，兩句互相矛盾（§3.10「補一句限定之後從頭讀到尾」）。讀的人照 ④ 會以為 UPGRADING 的 rev 漂移不會被擋，又多做一次手動核對；或者反過來，以為 ④ 指的是另一處 rev，去找一個不存在的東西。④ 應該只留 CHANGELOG 未發布區塊，或把 UPGRADING 那半併進 ②。

## Not reported
- 其他同步點逐項核過，沒發現問題：①全 repo（含 UPGRADING、兩份 README、templates、scripts/CLAUDE.md、commands/、tests/）找不到其他「CI 不驗 rev 有沒有跳」的殘留；②「新增 ci.yml 檢查 step 必做負面測試、同批補 CI 防線表」兩條都照做了（④ 的變異與 DD_PIPELINE_ARCHITECTURE.md:129）；③「CI 不驗、只能手動同步的區塊」清單不必因這次改；④CHANGELOG 條目在 `## 未發布`/`### Added`，描述與 step 行為相符；⑤架構文件新列的描述與 step 相符；⑥進度表規則區塊與 skills/task-planner/SKILL.md「進度表格式」逐字 diff 相同；指路句在第一個 `##` 前、前後有空行，2026-10-29 那份全部 DONE 後指路已刪。
- ci.yml:14 的 fetch-depth 註解只寫 CHANGELOG 那個 step 依賴 tag，新 step 也依賴 tag。沒報，因為拿掉 fetch-depth 時新 step 會印「找不到任何 v* tag」並紅燈，不是靜默放過。
- 根 CLAUDE.md 舊文界線裡的「開頭是 `## 開發流程`」在新文被拿掉了。沒報，因為新文用 `grep -n '^```' … | head -2` 定界，已經足夠；dd-init.md 區塊內的 ```js 等圍欄都有縮排，`^```$` 不會誤收（848ea70 的 dd-init.md :52 開頭、:149 結尾，:117/:120 有縮排）。

## What I ran
- `wc -l` 與分段 Read rb-diff.txt → 211 行，一次讀完
- `git grep -n -E '不驗|跳號|rev 有沒有跳'` 與 `'CI 防線|道防線|防線表'` @848ea70 → 只命中本 diff 的檔與既有報告
- `git show {2bd0014,848ea70}:CLAUDE.md | sed -n 1,8p`、`sed -n 230,290p` → 指路句換成新的；第 273–284 行內容如上
- `git show 848ea70:commands/dd-init.md | grep -n '^\s*```|dd-loop-rev|rev 比|列出與現行版的差異'` → 區塊 :52–:149，內層圍欄有縮排
- `grep` ci.yml（848ea70）的 job、checkout、step 名、rev 檢查 → lint job 有 fetch-depth: 0；:342 驗 UPGRADING 判定線
- `git grep dd-loop-rev|蓋章區塊` 掃 UPGRADING/README/templates/scripts/tests/commands/skills → 沒有殘留宣稱
- `git show 848ea70:UPGRADING.md | grep -n rev` → 只有 :82
- 用 diff 比 task-planner SKILL.md :131–146 與設計文件 :12–27 → SAME
- `bash -c 'for t in $(git tag … | tail -10); do … grep dd-loop-rev; done'` → v1.6.5=9、v1.6.6=11、v1.6.7–v1.6.11=12
- `git show 848ea70:CHANGELOG.md | sed -n 1,22p` 與 `sed -n 125,140p` → 條目在未發布；9→10→11 在同一版內

## 需要外部查證
- 除了作者自己，有沒有使用者從 main 而不是從 tag 安裝？這決定第一條的實際影響範圍，要問使用者。

## 處置

見 `S1-judge.md` 的「處置」。
