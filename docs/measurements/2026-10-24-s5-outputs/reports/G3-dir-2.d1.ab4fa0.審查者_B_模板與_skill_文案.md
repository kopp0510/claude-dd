Critical 0 / Important 4 / Smells 0 — 快照 `git diff HEAD~1 HEAD`（8 檔），主攻 verification-gate、worktree-manager 與全域模板 §3.5

[Important] skills/verification-gate/SKILL.md:36、:57-59（快照行號；diff 檔 1595、1616-1618）把「改回舊版確認會紅」也要求成「紅的是原本那個 bug」，跟模板 §3.9 鑑別力那條直接矛盾。
  證據：SKILL.md:36 寫 `git stash -u && <測試>`（看到失敗，**而且紅的是原本那個 bug**，見下方紅旗）。:58 寫「對得上『它應該怎麼紅』才算（修 bug 時就是那個錯的值）」。模板 :364-366 則寫「鑑別力測試(改回舊版確認會紅)…不要斷言某個預期的壞結果…變異版掉進**第三種**狀態」。stash 把修復藏起來重跑，正是「改回舊版」。模板 :195 用括號把變異版劃給 §3.9，但 skill 的紅旗沒帶這個範圍限定，只寫「判準見 §3.5」。
  失敗情境：修 bug 時舊碼掉進第三種狀態（預期 2、實際拋例外 C），agent 照 skill 判定「紅的不是原本那個 bug」，回頭去改一個其實正常的測試。這正是 :365-366 記下的 2026-10-07 事故。建議：§3.5 改成「被測的東西真的跑到、而且給了錯的結果」，錯的值不必是預期的那一個；skill 的 :36 與 :58 照同一個口徑改。

[Important] templates/global/CLAUDE.md:193-195（diff 檔 142-144）沒交代新功能的測試第一次跑時怎麼判。
  證據：§3.5 的規則是「新測試先寫失敗案例」，判準是「對得上『它應該怎麼紅』」，同時把「import 路徑寫錯、拼錯字」判成「只證明測試自己壞了」。可是新功能還沒寫時，第一次紅必然是「找不到函式」或 import 錯誤，跟拼錯字長得一樣，文中沒說這種紅算不算。
  失敗情境：agent 為還沒寫的 `parse()` 寫測試，看到 `parse is not a function`，可能卡住（永遠拿不到合格的紅），也可能把它當成「它應該怎麼紅」放行，而斷言其實從沒執行過。建議：寫明先放一個回錯值的空殼，讓測試真的跑到斷言。

[Important] skills/worktree-manager/SKILL.md:25-41（diff 檔 1669-1685）這段借鑑了 pstack-claude，skill 本體卻沒寫出處，違反根目錄 CLAUDE.md 的收編規則。
  證據：CHANGELOG.md:39 寫「借鑑 pstack-claude 的 worktree-cleanup playbook」。根目錄 CLAUDE.md:353 起寫「只借概念、不抄檔案時…授權仍要處理：歸屬範圍精確到段落」。同一批的 verification-gate:9 有補「借鑑…pstack-claude 的 `tdd`」，design-brainstorm:9 也是同樣寫法，只有 worktree-manager 沒補。我 grep `pstack` 的結果：worktree-manager 沒有命中。模板 §3.5 同樣借鑑了 `tdd`（CHANGELOG:23），也沒標出處。
  失敗情境：讀這個 skill 的人看不出收尾流程來自哪裡、授權是否處理過，這正是該條要擋的「不足歸屬」。建議：在 `## 收尾` 補一行「借鑑 pstack-claude 的 worktree-cleanup playbook」。

[Important] skills/worktree-manager/SKILL.md:35-36（diff 檔 1679-1680）的判斷方式會誘導 agent 把 `.env` 的值印出來。
  證據：原文是「之後又改過的 `.env`（跟 `.env.example` 不一樣，就是改過）」，沒有指定怎麼比。模板 §3.7（templates/global/CLAUDE.md:216）規定「讀到 `.env`…**不輸出值**」。
  失敗情境：agent 自然會跑 `diff .env .env.example` 來判斷，secret 原文就進了對話紀錄。建議：明寫用 `cmp -s .env .env.example`，只看 exit code。

需要外部查證（交回）：
- verification-gate 改寫後有沒有照根目錄 CLAUDE.md「新增 Skill 步驟 3」做乾跑（該條寫「新增或改寫都要」）。CHANGELOG 只提到 worktree-manager 有乾跑。查法：翻這輪的乾跑紀錄。
- pstack-claude 的授權條款與擁有者 `michael-denyer` 是否屬實。查法：看上游 repo 的 LICENSE。結果決定上一條出處要怎麼寫。

What I ran
- Read diff.txt 1-300、1406-1495、1559-1703 → diff 本體與 scripts/CLAUDE.md、兩份 SKILL.md 的整檔
- Grep `^----- ` diff.txt → 8 個整檔區段的起始行
- Grep `鑑別力|第三種|它應該怎麼紅|假紅|確認會失敗`（快照）→ 模板 :193、:195、:364-366，SKILL.md :9、:57-58，CHANGELOG
- Grep check-claude-md.sh 的 `staged=`、`head_or_empty > "$BASE_FILE"`、`read_base`、`EMPTY_TREE` 與訊息字串 → :28、:52、:195、:202、:215、:232、:238，scripts/CLAUDE.md 變異表引用的行都存在
- Read check-claude-md.sh:50-301 → 確認三條繞過的對照狀態與 said 字串跟 gate 行為吻合
- Read test-gate.sh:1-80、:150-299；Grep 裸跑的 commit/merge → 只剩 :168、:178 的 `git merge`，它們不觸發 pre-commit
- Grep `pstack|superpowers|diagram-design`（快照）→ worktree-manager 沒有出處，verification-gate 與 design-brainstorm 有
- Grep `檔案:行號` 形式的引用 → 這次 diff 沒有讓任何寫死的行號過期
- Grep 模板 `3\.7 敏感|\.env` → :214、:216

Not reported：
- test-gate.sh 新區塊與 scripts/CLAUDE.md 的變異表：讀程式碼核對過對照狀態、said 字串和變異點，沒找到錯誤。說明裡已交代 105/105 綠，所以沒重跑。
- worktree-manager:38 寫「每次都會出現在 `??`」：WORKTREE_INFO.md 若已被 commit 就不會出現，屬措辭小問題，構不成失敗情境。
- verification-gate:56 引用的「0 紅的第一個嫌疑人…」跟模板 :371 的措辭不完全一樣：既有問題，不是這次 diff 引入的。