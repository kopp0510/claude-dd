審查者 B 交回:Critical 1 / Important 2 / Smells 1。範圍是快照的 `git diff HEAD~1 HEAD`,共 3 檔,重點看 ci.yml 新增的「gate 段落起點」step。

整體結論:CI step 在 `bash -e` 下實跑,22 個情境全綠,exit 0。核心情境有鑑別力:把 hook 換成空檔會紅 7 項,把欠帳改成「不照 commit 先後結算」會被情境 3 的 Z 抓到。漏洞在幾個只看 exit code、不看結果的情境,3 個變異都 0 紅存活。另外這次改了 gate 腳本,卻沒同批更新 `scripts/CLAUDE.md`。

---

**[Critical]｜`scripts/CLAUDE.md:8-11`、`templates/global/CLAUDE.md:273`｜改了 `scripts/check-claude-md.sh` 的行為,同層 CLAUDE.md 沒有同批更新**
- 內容:新行為包括 `--start-segment`、`--segment-base`、SKIP 自動記起點、照起點以來的欠帳擋 commit。`scripts/CLAUDE.md` 仍寫「規則:staged 變更含程式碼檔的目錄…同批 staged;逃生口 `SKIP_DOC_CHECK=1`」,對新行為一個字都沒提。同檔第 21 行要求「gate 的檢查邏輯改動時,同步檢視全域模板 §3.9」,而快照的模板 §3.9 也完全沒有 segment 相關字樣。
- 為什麼要修:這違反根目錄 CLAUDE.md:107-108「改 `.sh` 等程式碼檔時,該目錄的 CLAUDE.md 必須同批更新」。新版 gate 本身也會在下一個正常 commit 把 `scripts/` 列成欠帳擋下。CHANGELOG 說 `--segment-base` 是「給迴圈步驟 3、4、8 算整段範圍」,但 §3.9 沒有任何地方叫人去用它,這句話目前沒有落點。
- 證據:diff 只動 3 檔(diff.txt:2/103/125)。`git grep -n -E 'segment|段落起點' -- scripts/CLAUDE.md templates/global/CLAUDE.md` 沒有命中任何 segment 字樣(只命中舊的 staged 描述)。
- 建議改法:同批更新 `scripts/CLAUDE.md` 的 gate 描述;§3.9 補上 `--start-segment` 與 `--segment-base` 的用法,或在設計文件寫明交給哪一段。如果這個 commit 是步驟 2 的 SKIP 檢查點,步驟 6 一定要補上。

**[Important]｜`ci.yml` 情境 7(diff.txt:89-96)｜「警告後只查 staged」那一半沒有測到**
- 內容:w1 只改 README,staged 裡沒有程式碼目錄。所以「起點失效時整個放行」和「起點失效時只查 staged」兩種寫法的結果一樣,`said` 只驗了警告字串。
- 失敗情境:我把 gate 改成「起點不是祖先時印出同一句警告後直接 `exit 0`」(M2),22 項全綠。也就是說,換過分支的人 staged 了真的程式碼又沒附 CLAUDE.md,也能整個放行,而 CI 抓不到。
- 證據:M2 變異後 `bash -e step.sh` → rc=0,沒有任何 ❌。
- 建議改法:起點失效後再加一則 `echo x > src/g.js` 而 CLAUDE.md 不 staged,預期 block。

**[Important]｜`ci.yml` 情境 2 的「沒有欠帳時可以重記起點」(diff.txt:51)與情境 5 的「有起點時印得出來」(diff.txt:76)｜只驗 exit code,沒驗結果**
- 變異 M1:`--start-segment` 在已有起點時不覆寫,但照樣 exit 0。22 項全綠。結果是起點永遠停在最舊那個,步驟 3、4、8 的範圍會一直變寬,CI 看不出來。
- 變異 M3:`--segment-base` 印空字串、exit 0。22 項全綠。這正是 diff.txt:75 註解說要擋的「不能印空字串給 git diff 吃」,而目前只測了「沒有起點」那一支。
- 證據:兩個變異各跑一次 `bash -e step.sh`,都是 rc=0、沒有 ❌。
- 建議改法:重記起點後斷言 `[ "$(cat "$BASE_FILE")" = "$(git rev-parse HEAD)" ]`;`--segment-base` 的輸出斷言等於檔案內容,而且 `git cat-file -t` 是 commit 或 tree。

**[Smells]｜`ci.yml:90`(diff.txt:90)｜`git checkout -qb side && echo s > side.txt`**
- 內容:在 `bash -e` 下,`&&` 串列裡前面那個指令失敗不會讓 step 中止,checkout 失敗會被靜默吞掉。
- 後果:之後的 commit 會落在原本的分支上,`git rev-parse HEAD` 寫進起點的是目前分支自己的 HEAD,w1 不會印警告,`said` 會紅。所以結果是錯誤訊息指錯地方,不會變成假綠。
- 建議改法:拆成兩行。

---

**Not reported**
- CHANGELOG 的「22 個情境」是用數的,違反全域 §3.10「能列舉就列舉,不要數」的精神;但 CHANGELOG 屬於歷史快照,而且我實數 expect 確實是 22,不報。
- `said "src"`(diff.txt:55)的字串很短。我推論在 runner 上不會從別處誤命中:腳本開頭會先 `cd` 進 `mktemp -d` 開的暫存目錄,失敗訊息裡印出的 `rm $BASE_FILE` 路徑就在這個目錄底下,不含 "src",所以不報。
- 檢查過、沒有空通過:4 個預期 block 的 commit(c2、z、n1、auto2)都有 staged 內容,不是 nothing-to-commit 造成的失敗。佐證是空 hook 變異時這幾項全部轉紅。
- 情境 7 的起點是 HEAD 的後代,不是真正分岔或改寫過的歷史;因為 gate 用的是 `merge-base --is-ancestor`,兩者等價,不報。

**What I ran**(在 `/tmp/revB.qpWm`,從快照 `git show HEAD:` 取出 gate 與 ci.yml,step 腳本用 awk 抽出,`GATE` 改成指向本地 gate)
- `bash -e step.sh` → 22 個 ✅,EXIT=0(macOS bash 3.2.57、git 2.42.0)
- `shellcheck -S warning gate.sh` → exit 0,沒有警告
- 變異 M1(已有起點時不重記)→ rc=0,0 紅(存活)
- 變異 M2(起點失效就整個 `exit 0`)→ rc=0,0 紅(存活)
- 變異 M3(`--segment-base` 印空字串)→ rc=0,0 紅(存活)
- 變異 unordered(CLAUDE.md 更新在最後一次扣掉,不照 commit 先後)→ `grep -c allmd` 為 2,確認變異已生效;結果只有 ❌ Z 一項(被抓到)
- 變異 no-hook(把 pre-commit 換成空檔)→ 7 項 ❌(被抓到)
- 變異前後 gate.sh 與快照 HEAD 版 md5 相同(42c036d9…),確認每次都已還原
- `git grep -n -E 'segment|段落起點|SKIP_DOC_CHECK|staged' -- scripts/CLAUDE.md templates/global/CLAUDE.md DD_PIPELINE_ARCHITECTURE.md CLAUDE.md commands/dd-init.md` → 沒有任何 segment 相關描述

**需要外部查證**
- GitHub ubuntu-latest runner 的 bash 5 與較新 git:在那裡重跑同一個 step,確認結果和 macOS bash 3.2 / git 2.42 一致。
- runner 的全域 git 設定有沒有 `core.hooksPath`:`git config --global --get core.hooksPath`。有設的話,`.git/hooks/pre-commit` 會被忽略,所有 block 情境都會紅,CI 會直接報錯,不會假綠。
- CHANGELOG 說「13 段裡有 8 段」有跳過檢查的 commit,這要到 rental-line repo 重算才能確認。