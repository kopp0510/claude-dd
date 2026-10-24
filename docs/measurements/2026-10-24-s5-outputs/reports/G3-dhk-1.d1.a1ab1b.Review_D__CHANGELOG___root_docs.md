Critical 0 / Important 1 / Smells 0. Range: 快照 `git diff HEAD~1 HEAD`（8 檔，CHANGELOG 與根目錄 CLAUDE.md 為主）。

[Important] scripts/CLAUDE.md:47 的變異配方「`head_or_empty > "$BASE_FILE"` 那一支」在 `check-claude-md.sh` 有兩處命中，配方沒指明是哪一處。
  Failure: 照第 2 或第 3 列的寫法套到 `:232`（SKIP 自動記起點那一支），而不是 `:215`（`--start-segment`），變異落在錯的分支，表上的「應該變紅的情境」對不上，讀者會以為 gate 或測試有問題。
  Evidence: `grep -n 'head_or_empty > "\$BASE_FILE"' scripts/check-claude-md.sh` → `:215`（`case --start-segment` 內）與 `:232`（`if SKIP_DOC_CHECK` 內）。建議改用「`--start-segment` 分支的 `head_or_empty > "$BASE_FILE"`（`:215`）」這類錨定句，同時修第 2、3 列。

**What I ran**
- 分 10 次 Read `diff.txt` 第 1–3024 行 → 全部讀完，無截斷
- `git -C <snapshot> tag | wc -l` → 0（快照沒有任何 tag）
- `git -C <snapshot> log --oneline | head -3` → `502ac84 change`、`00f4d5f base`
- `git diff --stat HEAD~1 HEAD`（已讀）→ 8 檔、+124 −7；CHANGELOG 為 +22 −0，已發布區塊未動
- `git grep` 「先寫失敗案例 / 紅了要讀紅的內容 / 假紅 / 看到紅就當成」→ 只出現在 templates §3.5、verification-gate SKILL、CHANGELOG，dd-init 與 README 沒有鏡像，不需跳 dd-loop-rev
- `grep` `scripts/check-claude-md.sh` 的 `staged=` / `reviews_missing` / `read_base` / `EMPTY_TREE` / `head_or_empty > "$BASE_FILE"` → `staged=` 唯一（:238）；`head_or_empty` 寫檔處 :215、:232；`reviews_missing` 定義 :159；`EMPTY_TREE` :28
- `cat scripts/githooks/pre-commit` → `exec …/check-claude-md.sh`，不帶參數，與 scripts/CLAUDE.md「pre-commit 收到 0 個參數」相符
- `git grep` `worktree remove` / `WORKTREE_INFO` / `status --porcelain` 於 README、DD_PIPELINE_ARCHITECTURE、commands、templates → 只有 dd-init.md:42、:134 與 templates:337，皆為歷史敘述或「不要用」的警告，無需同步
- `git grep pstack` → 只在 CHANGELOG、根目錄 CLAUDE.md、verification-gate SKILL 出現
- Read `scripts/check-claude-md.sh` 180–245 → `--start-segment` 分支與 SKIP 分支的位置確認
- 人工讀 `tests/test-gate.sh` 新增的「繞過①②③」段（:303–356）與 scripts/tests CLAUDE.md 的對應敘述 → 各則的前提與 base 狀態前後一致，未發現假綠（未重跑，採用你給的 105/105 結果）

**Not reported**
- CHANGELOG 的 tag 比對（CI 以最新 `v*` tag 為基準）無法在快照驗證，因快照沒有 tag。但 diff 是純新增，已發布區塊沒有被改動，所以不列為發現。
- 三個變異表的紅數與情境對應沒有重跑，只能當文件主張；見下方外部查證。
- 根目錄 CLAUDE.md 與 CHANGELOG 的「借鑑 pstack-claude」段落，與收編清單的授權規則是否衝突，需看 pstack-claude 授權，超出快照範圍，不報。

**需要外部查證**
- 在 git 2.42.0 與 2.54.0 各跑一次 `git worktree remove`，驗證 ` M` / `??` 會拒絕、`!!` 會靜默刪除（worktree-manager SKILL:29–38 與 CHANGELOG:35–39 的主張）。
- 讀 pstack-claude repo 的 SessionStart hook 原文，確認 `<EXTREMELY_IMPORTANT>` 與觸發事件（根目錄 CLAUDE.md:333–337）。
- 在 scripts 複本上套用 scripts/CLAUDE.md 的三個變異（先修上面那列的行號歧義），各跑 `/bin/bash tests/test-gate.sh <變異副本>`，比對表中的紅情境。
- 在有 tag 的 clone 上跑 ci.yml 的「CHANGELOG 已發布區塊不可改動」step，確認新 `## 未發布` 區塊位置不會被擋。