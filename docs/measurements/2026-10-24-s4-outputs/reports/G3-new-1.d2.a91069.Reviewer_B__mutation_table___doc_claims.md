Critical 0 / Important 1 / Smells 0。審查範圍：快照 `git diff HEAD~1 HEAD`，共 8 檔，被改到的檔一律讀 diff.txt 裡的版本。

**[Important]** `skills/verification-gate/SKILL.md:36`（diff.txt 1595 行）與 `templates/global/CLAUDE.md:193-195`（diff.txt 142-144 行）

- **內容**：新規則要求「紅的是原本那個 bug／對得上它應該怎麼紅（修 bug 時就是那個錯的值）」。但修 bug 時「把修復藏起來、跑舊碼看會紅」，做的正是 §3.9 的鑑別力測試。§3.9 明文規定這種測試「不要斷言某個預期的壞結果」，變異版「只要不等於固定版就算紅」。
- **證據**：
  - 模板 §3.9（快照 `templates/global/CLAUDE.md:364-367`）寫「鑑別力測試(改回舊版確認會紅)…不要斷言某個預期的壞結果」。2026-10-07 那次實例：舊碼掉進第三種狀態 C，而測試其實有鑑別力。
  - 新 §3.5 有一句豁免：「這條管新測試第一次跑;判定變異版…仍照 §3.9」。可是修 bug 時，新測試第一次跑的對象就是舊碼，兩條規則管的是同一件事，這句豁免分不出該套哪一條。
  - verification-gate 則連這句豁免都沒帶：它把「紅的是原本那個 bug」直接掛在 `git stash -u && <測試>` 上（也就是把修復拿掉、改跑舊版），紅旗那條也只指向 §3.5。
- **失敗情境**：agent 修 bug 後跑 `git stash -u && <測試>`，舊碼紅在一個不是原 bug 值的第三種狀態。照 verification-gate 第 36、58 行，它會判「紅錯了、不算數」，回頭去改一個其實正常的測試。這正是 §3.9 記下、差點發生的那次誤判。
- **建議**：要先講清楚「錯的值」指的是什麼。可以改成「紅在斷言上、而且被測物真的跑到了」，把它跟「import／拼字／資料沒建好」這類紅分開，不要求紅成某個特定的值。verification-gate 第 36 行也要補上指向 §3.9 鑑別力測試的豁免。

**Not reported（看過但不報）**

- **scripts/CLAUDE.md 新變異表**：三列都實跑過，宣稱成立（見下方 What I ran）。
  - 「`staged=` 那行」在 gate 裡只有一處（第 238 行）。
  - 「它那一支的 `head_or_empty > "$BASE_FILE"`」：第 215 行是 `--start-segment` 那一支，另一處第 232 行在 SKIP 那一支，所以說法沒有歧義。
- **tests/CLAUDE.md 的驗法 `grep -cE '^(✅|❌ .*：(預期 |輸出裡有 shell 錯誤))'`**：它只數 `expect` 印的判定行。`said`／`base_is` 失敗時印的 `❌ 輸出沒提到：`、`❌ 起點應為` 都不會被數到，這符合「判定行數」的意思。
- **diff 裡引用別處的敘述**，在 HEAD 都成立：
  - 「⑦ 那行」：amend 在第 287 行，落在 ⑦（第 276 行）與 ⑧（第 297 行）之間。
  - 「放在 ⑧ 與 ⑨ 之間」：新區塊在第 297 行之後、第 358 行之前。
  - 「恆真斷言那條」：`tests/CLAUDE.md:42`。
  - 「還剩的裸跑 hook 指令」：只有兩處 `git merge`，觸發的不是 pre-commit。
- **繞過③ 的 rm 前對照**：它被 `owed` 那個擋點攔下，`reviews_missing` 根本沒跑到，所以「review 那一關在 rm 前也會擋」沒有被斷言。測試註解已經寫明是刻意的；而 rm 之後的放行斷言，會被「沒有起點檔就判缺報告」這類變異抓到，所以不報。
- **worktree-manager**：「`WORKTREE_INFO.md` 每次都會出現在 `??`」沒考慮專案把它 gitignore 掉的情況，屬枝節。另外 CHANGELOG 寫「git 2.42.0 與 2.54.0 實測」，我無法查證，需要外部查證：在兩個 git 版本下各跑一次 `git worktree remove`，看 `!!` 檔是不是不提示就被刪掉。
- **`test-gate.sh 前 61 項`**：這是 diff 上下文裡的既有文字，不是這次引入的。

**What I ran**

- `grep -n 'staged=\|head_or_empty > "$BASE_FILE"…' scripts/check-claude-md.sh` → `staged=` 在第 238 行（唯一）；`head_or_empty > "$BASE_FILE"` 在第 215 行（`--start-segment`）與第 232 行（SKIP）。
- 把 gate 與 `test-gate.sh` 複製到 `/tmp/g3rev.05zr`，用 python 套三個變異（m1：`staged=` 下面加 `reviews_missing && exit 1`；m2、m3：照變異表把第 215 行改掉）。各跑 `/bin/bash test-gate.sh <gate>` 的結果：

  | 版本 | exit | 判定行數 | 變紅的情境 |
  |---|---|---|---|
  | 固定版 | 0 | 105 | 無 |
  | m1 | 1 | 105 | 從「建立 docs/reviews/ 的那個 commit」起一路連鎖，含繞過①，另外 ⑩「新線上的正常 commit」也紅 |
  | m2 | 1 | 105 | 只有「繞過③:rm 掉起點檔,開下一段放行」 |
  | m3 | 1 | 105 | 只有「繞過③:by/ 的欠帳被洗掉…」 |

- 把第 287 行還原成裸跑的 `git commit -q --amend` 再跑：配 m1 是 exit 1、判定行數 76、「繞過①」出現 0 次；配固定版是 exit 0、判定行數 104。這證實 tests/CLAUDE.md 的「停在 ⑦ 那行、繞過①根本沒跑」，也證實它的驗法數得出差異。
- `sed -n 364,368p templates/global/CLAUDE.md`：§3.9 鑑別力測試那條原文。
- `grep '^## ' CHANGELOG.md`：`## 未發布` 只有一處（第 19 行），位置在 1.6.4 之前，沒有動到已發布的區塊。