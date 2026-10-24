## 步驟 4 code-review 報告（4 檔：scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）

結論先講：重構本身沒有問題，但新加的情境 ⑪ 是空通過——它宣稱守住的 `reviews_missing` 警告根本沒被執行到。三位審查者各自獨立抓到同一點，A、B 都實跑變異確認過（警告刪掉後仍是 90 ✅ / 0 ❌）。我沒有改任何檔，也沒有 commit。

**【派工】**
- 平行派了 3 個 `code-reviewer`（haiku），三個都回來了，不用補派。
  - A：gate 腳本邏輯，包括 `resolve_fork_base` 抽出前後是否等價、bash 3.2 相容、`set -e` 的坑。
  - B：測試有沒有真的跑到被測的分支、斷言有沒有鑑別力。
  - C：註解與文件的宣稱和程式碼是否一致，以及 repo 其他地方有沒有因此過期的敘述。
- 用最低的 3 個：diff 只有 4 檔、約 200 行，照「邏輯 / 測試 / 文件宣稱」三個方向切開剛好不重疊。
- C 交回了兩份內容不同的報告（被通知了兩次），兩份我都查證了。

**【採納】**
1. A、B、C（三方獨立）｜**Important**｜情境 ⑪ 只驗到 `owed_dirs` 一處，沒驗到 `reviews_missing`，卻宣稱「兩處都要放行但講出來」。
   - 我的查證：
     - `tests/test-gate.sh:340` 的 `rm -rf … docs …` 把 `docs/` 刪掉，之後 341 行沒有重建。
     - 所以 gate `scripts/check-claude-md.sh:151` 的 `[ -d docs/reviews ] || return 1` 直接返回，162–167 行那段根本沒跑。
     - `test-gate.sh:349` 的 `said "找不到共同祖先"` 能過，是因為 `check-claude-md.sh:108`（`owed_dirs`）也印了含這幾個字的句子；`git grep` 只找到 108 與 165 兩處。
     - A、B 各自把 165–166 行的警告刪掉後實跑，都是 90 ✅ / 0 ❌、exit 0。
   - 這正好是 `tests/CLAUDE.md:11` 自己點名的陷阱 ①。⑩ 有照這條在新線上重建目錄（`test-gate.sh:319–323`），⑪ 卻把目錄刪掉了。
   - 同樣不成立的宣稱還有：`test-gate.sh:335–337`、`tests/CLAUDE.md:11`「連共同祖先都沒有時:兩處放行但必須印出警告」。
   - 建議改法：
     - 在 ⑪ 的 orphan 分支上重建 `docs/reviews/`，裡面放 `CLAUDE.md`、不放 `S*.md`。
     - 斷言改用只有 165 行才有的字串，例如 `said "跳過 review 報告檢查"`；349 行可以保留，當作 `owed_dirs` 那一側的斷言。
     - 修完把 165–166 行刪掉再跑一次變異，要看到紅才算數。
2. 我自己（M1）｜**Smells**｜⑩ 的 `said "改從共同祖先"`（`test-gate.sh:332`）分不出是哪一處印的。
   - 我的查證：`--start-segment` 會先跑 `owed_dirs`（gate:183），它呼叫 `resolve_fork_base ""` 時也印出「…改從共同祖先…」。
   - 所以就算 `reviews_missing` 沒印，這行照樣會過。好在同一則的 `block` 斷言有鑑別力（`reviews_missing` 放行就會紅），所以只是 Smell。
   - 建議改法：改成 `said "review 檢查改從共同祖先"`。
3. 我自己（M2）｜**Smells**｜⑪ 的清理清單 `rm -rf r.js README.md src docs 'api server'`（`test-gate.sh:340`）不完整，還會誤導讀者。
   - 我的查證：
     - `git grep "api server"` 只找到這一行，整支測試從沒建過這個目錄。
     - `p/ r/ w/ keep/ feat/ feat2/ 功能/ 模組/ "my dir"/ top.js` 都沒刪，會被 `commit()` 的 `git add -A` 加回 r7。
     - r7 能過，只是因為這些目錄剛好都有 CLAUDE.md。
     - 第 1 條的 bug 就是這份清單裡的 `docs` 造成的。
   - 建議改法：清單裡的 `docs` 改成上面說的重建，把不存在的 `'api server'` 拿掉，並寫明其他目錄是刻意留著的。

**【駁回】**
- C（第二份）：`scripts/CLAUDE.md:34` 寫的樣式 `S[^/]*` 跟程式碼 `S[0-9]`（gate:176）不一致。
  - 我核對過，兩邊確實矛盾，但這兩行都不在這次 diff 的範圍內（scripts/CLAUDE.md 的 hunk 從 38 行開始；gate 只動了 70–94、100–111、149–168 行），屬於既有問題。
  - 也不是這次把錯誤寫法複製到新路徑。建議另外開一個小修。
- C（第二份）：「四份文件」（gate:170）和「五份文件」（scripts/CLAUDE.md:30、test-gate.sh:264）互相矛盾。
  - 三行都不在這次 diff 範圍內，C 第一份報告自己也判為既有問題，同樣建議另外修。
- C（第二份）：「S6 的 review 抓到這兩處已經漂移」這句沒有依據。
  - 這句有依據：未改動的 gate 157–160 行就記載了「第一版在起點不是祖先時直接 `return 1`」，跟「一處退到共同祖先、另一處直接放行」對得上。
  - 只剩「S6 的 reviewer 預言過」那句查不到，已移到【需要外部查證】。
- B：「`--segment-base` 軟退化」實測是 4 ❌，文件寫 3 紅。
  - B 的變異是把祖先檢查直接改成 `true`，連「沒有共同祖先」那一則（347 行）也會放行。文件說的「軟退化」是退到共同祖先，347 行會照樣失敗。
  - 我照文件那種變異推算，紅的是 120、328 行兩則 expect 加 329 行的 `said`，正好 3。兩種變異不一樣，所以這不能證明文件寫錯。
- 順帶：B 實跑「fork-point 整支拿掉」得到 7 ❌，跟 `scripts/CLAUDE.md:61` 的「7 紅」一致。

**【需使用者決定】** 無

**【需要外部查證】**
- `scripts/CLAUDE.md:58`「S6 的 reviewer 預言過，S4 實作時確認了」和 gate:78 的同一句：快照的 `docs/reviews/` 只有 `CLAUDE.md`，查不到 S6 報告的原文。依全域 §3.10，這類「掛到 reviewer 頭上」的引用要先找到原文；找不到就改寫成「我當時這樣預判」。
- 「退化時不印警告 → 2 紅」（`scripts/CLAUDE.md:62`）：我推算這 2 紅來自 `resolve_fork_base` 那句警告（⑩ 的 332 行加情境 7 的 123 行），不包含 gate:165。修完第 1 條後，這段描述要寫明是哪一處的警告，數字也要重新量。

**【結論】** Critical 0 / Important 1 / Smells 2（採納數）

另外，B 在 `/tmp/gatemut.2iBG9h` 留下了變異用的暫存檔，沒有清掉；它在快照 repo 之外，我沒有動。