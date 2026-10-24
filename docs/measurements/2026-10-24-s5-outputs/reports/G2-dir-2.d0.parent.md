【派工】
我派了 3 個 `code-reviewer`，同一則訊息平行送出，沒帶 model 參數：
- A 審 `check-claude-md.sh` 的程式邏輯：重構後行為是否等價、bash 3.2、`set -e` 這類陷阱。
- B 審 `test-gate.sh` 新情境的鑑別力：每則是否真的跑到被測分支，可以用變異實驗證明。
- C 核對兩份 CLAUDE.md 和註解的宣稱：行號、紅數、「會擋／不會擋」是否與實際一致，並 `git grep` 同 repo 其他提到這些符號的地方。

數量定在 3：這次 diff 是兩支程式各配一份文件，「程式對不對」「測試抓不抓得到」「文件說得對不對」三個方向各自獨立，彼此重疊又能交叉驗證。三個都正常回來，沒有補派。

我自己也在 /tmp 副本跑了變異實驗查證，跑完已刪：
- 原版：90 ✅
- `reviews_missing` 沒有共同祖先時，刪掉警告（m1）：90 ✅，抓不到
- 同一處改成擋下（m2）：90 ✅，抓不到
- `reviews_missing` 退到共同祖先時，警告被吞掉（m3）：90 ✅，抓不到
- `resolve_fork_base` 不印警告（v1）：2 紅
- 拿掉 fork-point 那一支（v2）：7 紅
- `--segment-base` 改成軟退化（v3）：3 紅，其中第 120 行那則是舊情境 7

【採納】
1. A／B／C｜**Important**（B、C 標 Critical，我降一級）｜情境 ⑪ 根本沒跑到 `reviews_missing` 的「連共同祖先都沒有」分支。
   - 查證：`tests/test-gate.sh:340` 的 `rm -rf … docs …` 刪掉了 `docs/reviews`，所以 `check-claude-md.sh:151` 的 `[ -d docs/reviews ] || return 1` 直接回傳。`:349` 的 `said "找不到共同祖先"` 能過，是因為 `owed_dirs` 在 `:108` 也印了「也找不到共同祖先」。m1、m2 都是 90 ✅、exit 0。`tests/CLAUDE.md:11` 寫的「兩處放行但必須印出警告」，以及 `scripts/CLAUDE.md:49` 那一列，有一半沒有測試在守。
   - 降級理由：gate 本身的行為現在是對的，缺的是回歸防護，加上一句錯的覆蓋宣稱，不是會跑錯的 bug。
   - 改法：在 orphan 線上重建 `docs/reviews/`，只放 `CLAUDE.md`，不放 `S*.md`。`said` 改比對只有 `reviews_missing` 會印的「這次跳過 review 報告檢查」。
2. B｜Important｜`tests/test-gate.sh:332` 的 `said "改從共同祖先"` 分不出是誰印的。
   - 查證：`--start-segment` 在 `:183` 先跑 `owed_dirs`，它用空前綴呼叫 `resolve_fork_base`，同一句也會印出來（`:89`）。m3 把 `reviews_missing` 那句吞掉，照樣 0 紅。
   - 改法：改成 `said "review 檢查改從共同祖先"`。
3. B／C｜Important｜`tests/test-gate.sh:304` 說「沒有這一段的話，把 `--segment-base` 改成退到共同祖先，不會有任何測試變紅」，這句是錯的。
   - 查證：v3 的 3 紅裡，第 120 行「起點失效時 --segment-base 要失敗」是舊情境 7，HEAD~1 就已經有了。這句是在替新區塊辯護，卻給後人錯的前提。
   - 改法：改成「舊情境 7 只守起點失效且有共同祖先這一格，⑩ 另外釘住 reviews_missing 退到共同祖先」，或者直接刪掉這句。
4. C｜**Smells**（C 標 Important，我降一級）｜`tests/test-gate.sh:283-285` 說上面那句「原本寫『起點 commit 被改寫』…（S4 修正）」，但 `:273-276` 的 ⑦ 標頭沒改，還是寫「起點 commit 被改寫（amend／rebase）…`--amend` 掉起點那個 commit」。
   - 查證：diff 那一段 `@@ -280,7 +280,10 @@` 只改了 expect 名稱，並加了這段註解。
   - 降級理由：新註解自己已經把讀者導向 ⑩，不會留下錯的覆蓋印象，傷害是同一段自相矛盾。
   - 改法：把 `:273-276` 的標頭改成「段落內 HEAD 被 amend」，並刪掉「已修正」那句。
5. A／C｜Smells｜`resolve_fork_base` 隱含讀全域的 `$base`，但 `check-claude-md.sh:71-72` 的說明只寫了 `$1`、`$2`。
   - 查證：`:84`、`:88` 直接用了 `$base`。目前兩個呼叫端都先跑過 `read_base`（`:183`、`:231`、`:152`），所以現在不會錯。
   - 改法：說明補一句「讀全域 `$base`（呼叫前須 `read_base`）」，或者把 base 改成參數傳入。
6. A／B｜Smells｜`tests/test-gate.sh:340` 的清理清單和實際狀態對不上。
   - 查證：`'api server'` 整份測試從沒建立過。前面建的 `p/`、`r/`、`w/`、`feat*`、`功能`、`模組`、`keep`、`my dir`、`top.js` 都沒清，`commit()` 的 `git add -A` 會把它們全收進 r7。
   - 改法：照實際建立過的路徑列清單，或者改用 `git clean`。
7. C｜Smells｜`scripts/CLAUDE.md:60-62` 只記了紅數，沒記哪幾則變紅，違反全域 §3.9「要記哪個變異 → 哪幾個情境變紅」。
   - 查證：正因為只記了「3 紅」，才看不出其中一則是舊情境 7，也就看不出第 3 條那句是錯的。
   - 改法：每個變異附上變紅的情境名稱。

【駁回】
- 無。另外確認了兩件事：
  - `scripts/CLAUDE.md:60-62` 的 3／7／2 紅數我實跑重現了（v3／v2／v1），數字是對的。
  - A 說重構前後兩處警告字串逐字相同，我讀了 `:89`、`:105`、`:162`，接上前綴後確實與 HEAD~1 一致。

【需使用者決定】
無

【需要外部查證】
- `check-claude-md.sh:78`、`scripts/CLAUDE.md:55,58` 引用了「S6 的 reviewer 預言過」「S6 的 review 抓到這兩處已經漂移」。但快照的 `docs/reviews/` 只有 `CLAUDE.md`，沒有 S6 的報告；`git grep '預言'` 在這兩支以外沒有命中。要確認那份 S6 報告的內文真的有這段，不然就照 §3.10 改成「我當時這樣預判」。

【結論】
Critical 0／Important 3／Smells 4（採納數）