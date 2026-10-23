【派工】
我平行派了 4 個 `code-reviewer`，都不帶 model 參數。每個都拿到完整的路徑限制、範圍與已跑驗證、專案規則和職責。4 個都回來了，沒有失敗，不需要補派。
- A：查 `tests/test-gate.sh` 新增的繞過①②③區塊和 ⑦ amend 改寫，逐則對照 gate 邏輯，並實跑變異。
- B：查 `scripts/CLAUDE.md` 變異表、`tests/CLAUDE.md` 的新宣稱和跨檔引用，三個變異都實跑。
- C：查 `worktree-manager` 收尾流程，在拋棄式 repo 實跑 git 2.42.0；另看 `verification-gate`。
- D：查 template §3.5、CHANGELOG `## 未發布`、收編總則、歸屬與授權、dd-init 同步義務。

為什麼是 4 個：這個 diff 有兩類性質不同的東西。一類是可以實跑驗證的（test-gate 加上變異、git worktree 行為），一類是跨檔的規則一致性（§3.5、§3.9、verification-gate、CHANGELOG）。每類各 2 發，讓同一類有兩個獨立的視角；而 3 發的話，總有一個方向只剩單發。

【採納】
1. B、C、D 三方獨立命中｜Important｜「假紅」新規則跟 §3.9 鑑別力測試互相打架。
   - 內容：verification-gate 把「紅的是原本那個 bug」掛在 `git stash -u` 迴歸模式上。§3.5 也寫「修 bug 時就是那個錯的值」。但把修復藏起來重跑，正是 §3.9 的「改回舊版確認會紅」，而 §3.9 明寫「不要斷言某個預期的壞結果」、只要「不等於固定版的輸出就算紅」。
   - 反方向也有洞（D）：§3.5 新括號把變異版的判定整個交給 §3.9 的「不等於」，而那句沒有假紅但書。import 壞掉的變異照字面會被算成「抓到了」。
   - 查證：
     - §3.9 原文：快照 `templates/global/CLAUDE.md:364-367`。
     - 新 §3.5：diff.txt:142-144。
     - verification-gate stash 那行：diff.txt:91，SKILL.md:36；紅旗：diff.txt:99-101。
   - 失敗情境：舊碼掉進第三種狀態。照 verification-gate 會判成「紅錯了」，回頭去改一個正常的測試，也就是 §3.9 記下的 2026-10-07 那次誤判。
   - 建議改法：
     - §3.5 改成「被測物真的跑到、而且給了錯的結果才算；錯的值不必是你預期的那一個」，並明寫 stash 或改回舊版時也照這條判。
     - §3.9 那句「不等於」補但書：載入失敗、資料沒建好造成的「不等於」不算。
     - verification-gate:36、:57-59 與 CHANGELOG 對應條目同批改。
2. A｜Important｜`tests/test-gate.sh` 的「繞過①」那則對它要釘的變異沒有鑑別力，現在會紅只是被前面的連鎖帶到。
   - 查證：
     - by1 是 by0 重記起點後的第一個 commit。pre-commit 執行時 HEAD 等於 base，而 `reviews_missing` 有一行 `[ "$base" = "$head_sha" ] && return 1`（快照 `scripts/check-claude-md.sh:165`，我已讀）。所以就算 pre-commit 也查報告，by1 照樣放行。
     - A 在拋棄式 repo 實跑：變異版下段內第一個 commit 放行（PASS），第二個才擋（BLOCK）。
     - 整支測試裡繞過①會紅，是因為 by0 先被擋、起點沒有前進。B 跑 m1 時看到的連鎖也跟這個一致。
   - 失敗情境：前面情境的狀態一變，連鎖就會斷，繞過①在 m1 下變綠。`scripts/CLAUDE.md` 變異表寫的「繞過①是具名的那一則」跟著失真，正是 `tests/CLAUDE.md` 警告的「為了錯的理由而通過」。
   - 建議改法：在 by1 之後、對照之前，再加一則段內第二個零報告的正常 commit（HEAD ≠ base），讓它當具名的繞過①；同批改變異表第一列的說法。
3. D｜Important｜worktree-manager 收尾段沒寫借鑑來源。
   - 查證：
     - CHANGELOG（diff.txt:30）寫了借鑑 pstack-claude 的 worktree-cleanup playbook。
     - 同一批的 verification-gate:9 有在檔內一行掛名，`design-brainstorm:9` 也是同樣前例，而 worktree-manager SKILL.md 全檔沒有。我 grep `pstack|superpowers` 只在 `skills/*/SKILL.md` 這兩處命中。
     - 根目錄 CLAUDE.md「只借概念、不抄檔案時」規定授權仍要處理、歸屬精確到段落。
   - 建議改法：在收尾步驟 1 或檔頭加一行，例如「收尾時對被 ignore 檔的處理借鑑 michael-denyer/pstack-claude 的 worktree-cleanup playbook」。
4. C｜Smells（由 Important 調降）｜`.env` 只被舉成 `!!` 的例子，但專案沒把 `.env` 加進 gitignore 時它會落在 `??`；而問使用者的選項含「commit」，也沒有提醒 secret 風險。
   - 查證：C 實跑 git 2.42.0，`.gitignore` 只有 `node_modules/` 時，輸出是 `?? .env`。SKILL.md:20 的步驟 4 會無條件複製 `.env`；本 repo 的 `.gitignore:23` 有 `.env`，但這個 skill 是給任意專案用的。
   - 調降理由：`??` 那支本來就會擋 remove 並交給使用者決定，不會靜默出錯。而且從 `.env.example` 複製來的檔通常沒有真 secret。改版前的「確認變更已全部 commit」風險其實更大。
   - 建議改法：註明 `.env` 視專案 `.gitignore` 而定，可能出現在 `??` 或 `!!`；碰到 `.env` 類的檔不給 commit 選項，或至少附警告。

【駁回】
- D｜CHANGELOG `## 未發布` 位置違規的疑慮：不成立。diff 只在 `## 1.6.4` 之上新增行（diff.txt:10-31），沒有動到已發布區塊。另外快照沒有 `v*` tag，CI 那道檢查在快照裡無法重現。
- B、D｜變異表的錨點有沒有歧義：`staged=` 只在 :238 出現一次。`head_or_empty > "$BASE_FILE"` 有 :215（`--start-segment`）與 :232（SKIP）兩處，但表上寫明「它那一支」，我讀 :215 確認是 `--start-segment` 那一支，沒有歧義。m2、m3 經 A、B 各自實跑，都只紅宣稱的那一則。
- B、D 列為既有問題｜`scripts/CLAUDE.md` 的「前 61 項」：我回去看了，diff.txt:71 是 context 行，這次 diff 沒有新增或複製這個數字，不在範圍內。它確實過期，順帶提一次。
- C｜`allowed-tools` 沒列 AskUserQuestion：根目錄 CLAUDE.md 寫明它只是預授權、不是白名單，而這份 skill 沒寫「不詢問、直接執行」，不構成矛盾。
- B、C｜「`WORKTREE_INFO.md` 每次都會出現在 `??`」說得太滿（專案若把它 gitignore 或 commit 進分支就不會出現）：沒有失敗情境，不採納。

【需使用者決定】
無。第 1 條的語意，§3.9 原文已經寫明預期（改回舊版時不斷言特定壞值），不屬於「無從判定哪個才是預期」。

【需要外部查證】
- pstack-claude 的 LICENSE 是否存在、是否相容，上游 owner 是否就是 `michael-denyer`（收編清單 #1，只借概念時授權仍要處理）。
- pstack-claude 的 SessionStart hook 是否真的在 startup、resume、clear、compact 都觸發，注入內容是否含 `<EXTREMELY_IMPORTANT>` 並要求叫 `pstack:poteto-mode`。
- worktree-manager 宣稱的 git 2.54.0 行為。2.42.0 已由 C 實跑確認：中文錯誤訊息逐字相符，只剩 `!!` 時 remove 會直接刪掉目錄（exit 0）。

【結論】
採納 Critical 0 / Important 3 / Smells 1。

說明：依任務說明第 5 條「不准改任何檔」，我沒有把各審查者報告逐字寫進 scratchpad 檔，報告全文只在本對話裡。另外 A、B、C 在 /tmp 留下了實驗目錄（`/tmp/g3rev.8XoG`、`/tmp/g3rev.05zr`、`/tmp/wtexp.*`），還沒清。