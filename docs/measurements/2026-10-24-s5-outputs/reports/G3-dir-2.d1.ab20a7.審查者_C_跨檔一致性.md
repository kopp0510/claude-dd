Critical 0 / Important 2 / Smells 0：審查範圍是快照 `git diff HEAD~1 HEAD`，共 8 檔，重點放在跨檔一致性與文件宣稱是否屬實。

[Important] `skills/verification-gate/SKILL.md:36`（diff 檔 1595 行）、`templates/global/CLAUDE.md:193-195`（快照行號，diff 檔 142-144 行）、`CHANGELOG.md:23-26`（diff 檔 275-278 行）：新加的「紅要對得上它應該怎麼紅，修 bug 時就是那個錯的值」跟同一份模板 §3.9 的鑑別力測試互相矛盾。
  Failure：verification-gate 要求 `git stash -u && <測試>` 時「紅的是原本那個 bug」。stash 掉修復，就是 §3.9 說的「改回舊版確認會紅」。§3.9（快照 `templates/global/CLAUDE.md:364-367`）明寫「不要斷言某個預期的壞結果」，舊碼可能掉進第三種狀態 C，只要「不等於固定版輸出」就算紅。模板 §3.5 自己的括號也說變異版照 §3.9 判，skill 卻反過來要求對上原 bug。照 skill 走的 agent 會把有鑑別力的紅判成無效，回頭去改一個正常的測試，正好重演 §3.9 記錄的 2026-10-07 事故。§3.5 的「修 bug 時就是那個錯的值」也有同樣問題：修 bug 時新測試第一次跑的就是舊碼。
  Evidence：`SKILL.md:36`「看到失敗，而且紅的是原本那個 bug，見下方紅旗」；`templates/global/CLAUDE.md:195`「判定變異版有沒有被抓到仍照 §3.9 鑑別力測試那條：不等於固定版的輸出就算紅」；`:364`「不要斷言某個預期的壞結果」。
  建議改法：§3.5 與紅旗改成「被測的東西真的跑到了、而且給了錯的結果」，錯的值不必是預期的那一個；stash 那行改成照 §3.9 判。

[Important] `skills/worktree-manager/SKILL.md`（diff 檔 1644-1699 行，整份）：收尾流程借了 pstack-claude 的 worktree-cleanup playbook，SKILL.md 裡卻沒有歸屬。
  Failure：根目錄 CLAUDE.md 收編清單的「只借概念、不抄檔案時…授權仍要處理：歸屬範圍精確到段落／項目」適用這次的借法。同一批的 verification-gate 有在檔頭補「借鑑 michael-denyer/pstack-claude 的 `tdd`」，design-brainstorm 也是同樣寫法，worktree-manager 卻只在 CHANGELOG（diff 檔 291 行）寫了「借鑑 pstack-claude 的 worktree-cleanup playbook」。CHANGELOG 發版後就凍結，skill 本體一直缺歸屬，這也是根目錄 CLAUDE.md 點名過的「不足歸屬」。
  Evidence：`git grep -n -i 'superpowers\|pstack' -- . ':!CHANGELOG.md'` 在 `skills/worktree-manager/` 沒有命中，只有 verification-gate 與 design-brainstorm 有「借鑑」行。
  建議改法：比照 verification-gate，在 worktree-manager 檔頭加一行借鑑，範圍寫到「收尾步驟 1 的 `!!` 處理」。

**已核對、宣稱成立的項目（不構成發現）**
- `scripts/CLAUDE.md` 新增的三列變異表我實跑過，「哪個變異 → 哪幾則變紅」全部對得上：
  - 變異 M1（pre-commit 也查報告）：繞過①變紅，從 r0 起一路連鎖變紅。
  - 變異 M2（有 `docs/reviews/` 但沒起點檔就拒絕）：只紅「rm 掉起點檔，開下一段放行」那一則。
  - 變異 M3（沒起點檔時從空樹記起）：只紅「by/ 的欠帳被洗掉」那一則。
  - 三個變異的判定行數都是 105，跟固定版一樣，代表 amend 包進 `expect` 之後整支都跑完了。
- 其他引用：⑦／⑧／⑨ 的位置、`staged=` 與 `head_or_empty > "$BASE_FILE"`（`--start-segment` 那一支）、`read_base`、`EMPTY_TREE` 都存在；兩條擋點訊息都含「先補完再記新起點」；worktree-manager 引的「步驟 4」「步驟 6」對得上建立流程；CHANGELOG 條目寫在 `## 未發布`，沒動到已發布區塊。

**需要外部查證（我沒有抓）**
- pstack-claude 的 LICENSE：查它的 repo 根目錄，決定借概念時歸屬要怎麼寫。
- 根目錄 CLAUDE.md 寫「SessionStart hook 會在 startup／resume／clear／compact 觸發，並注入 `<EXTREMELY_IMPORTANT>`」：查 pstack-claude 的 `hooks/hooks.json`，確認這句屬實。
- CHANGELOG 寫「寫法借鑑它 `reflect` 的 reviewer prompt 與 `poteto-mode` 的 babysit playbook」：查 pstack-claude 裡這兩份檔，確認出處屬實。
- worktree-manager 寫「git 2.42.0 與 2.54.0 實測」與 `worktree remove` 的拒絕訊息原文：要在兩個 git 版本實跑才能確認。

What I ran
- `git -C <快照> log --oneline -3; git tag; git diff --stat HEAD~1 HEAD` → 2 個 commit，8 檔
- `grep -n 'staged=\|head_or_empty\|read_base\|...' scripts/check-claude-md.sh` → 各錨點都存在（215、232、238 行等）
- `grep -n '^# [①-⑪]\|^# ----...' tests/test-gate.sh` → ⑦=276、⑧=297、繞過區塊=303、⑨=358
- `git grep -n -i 'superpowers\|pstack' -- . ':!CHANGELOG.md'` → worktree-manager 沒有命中
- `grep -n '鑑別力測試' templates/global/CLAUDE.md` → 195、364 行
- 在 mktemp 目錄產生變異 M1、M2、M3，跑 `/bin/bash tests/test-gate.sh <變異>` → 固定版 105 ✅；M1 84 ✅，判定行數 105；M2、M3 各 104 ✅，各只紅一則，跟文件寫的一致

Not reported：以下是既有問題，不在這次 diff 內。`tests/CLAUDE.md` 寫「`staged=$(…)` 下一行（第 153 行）」，現在那行在 238 行；`tests/test-gate.sh:406` 的「90 項全綠」是寫死的歷史數字；`tests/test-gate.sh:420` 寫「上面那行 `rm -rf`」，實際已經改成 `git clean`。