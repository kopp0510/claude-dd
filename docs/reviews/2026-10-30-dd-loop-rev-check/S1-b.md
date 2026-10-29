# S1-b — 審查者 B（dd-loop-rev 跳號檢查）

## 派工

> 你是 code-reviewer，代號 B。審查範圍：git diff 2bd0014 848ea70（claude-dd repo，/Users/danlio/project/my_project/claude-dd）。新增一個 CI step：改了 commands/dd-init.md 的蓋章區塊卻沒跳 dd-loop-rev 就紅燈；同批把根 CLAUDE.md 那段說明縮短、補 DD_PIPELINE_ARCHITECTURE.md CI 防線表與 CHANGELOG、開進度表。
> 
> 材料：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/rb-diff.txt。用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷）。被改到的檔用 git show 848ea70:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。材料 ④ 的驗證已確認，不要重跑。
> 
> 你的方向：根 CLAUDE.md 那段改寫：拿材料 ③ 的舊版逐句對新版，找出被拿掉或被改寬、改窄的條件、指向、出處（全域模板 §3.10「縮短既有文字時，條件最容易被改掉」那條的三種錯法）；新寫的「CI 驗 ①②、③④ 不驗」是否屬實（讀 ci.yml「迴圈步數四方一致」與新 step）
> 
> 職責：找漏洞，每條附證據（路徑:行號、原文、或指令與輸出），沒證據不算。只用手上的資料判斷；需要外部查證的列出來交回。不要改檔、不要 commit。
> 
> 輸出格式：第一行「Critical N / Important N / Smells N」；## Findings（每條 [級別] 路徑:行｜一句話；證據；失敗情境）；## Not reported（看到但不報的與理由）；## What I ran；## 需要外部查證。

## 發現

Critical 1 / Important 3 / Smells 0 — git diff 2bd0014 848ea70（根 CLAUDE.md 那段改寫、新 CI step 的說法）

## Findings

[Critical] CLAUDE.md:273（848ea70）｜新句「同一次發版改好幾次區塊，只要跳一次號」把舊規則放寬了：舊版是每次動到區塊都要跳號，新版改成每次發版跳一次。ci.yml:361 的註解也寫了同一句。
  證據：舊版 ③ 寫「動到…蓋章區塊…就必須同步跳 `dd-loop-rev`」，沒有提發版。repo 的實際做法也是每次改都跳號：v1.6.5 的 rev 是 9、v1.6.6 是 11，中間 1299d45 跳到 10、0233de6 跳到 11。dd-init.md:46 的差異清單裡有「rev 10 的步驟 4…」這一條，但 rev 10 從沒出現在任何 tag 裡。這表示確實有專案蓋到發版之間的 rev（根 CLAUDE.md「開發本 repo」也寫明 commit 驗證完就重跑安裝）。
  失敗情境：發版後第一次改區塊，rev 從 12 跳到 13，使用者重跑安裝，再對自己的專案跑 /dd-init，專案蓋上 rev 13。同一次發版裡第二次改區塊，照新規則不跳號，新 step 也是綠的（tag 的 rev 12 比現在的 13 小）。結果那個專案再跑 /dd-init 會被告知「已是現行版」，拿不到第二次的修正。CI 用 tag 當基準，本來就抓不到這種情況；新句等於把這個抓不到的盲點寫成了規則。

[Important] CLAUDE.md:284（848ea70）｜「③、④ CI 不驗」不完全對：④ 的前半「`UPGRADING.md` 寫死的 rev 值」其實有 CI 驗。
  證據：`grep -n 'rev' UPGRADING.md` 只命中第 82 行「rev 比 12 舊的，會被判定為舊版」。這正是 ci.yml「迴圈步數四方一致」裡 `for spec in … "UPGRADING.md:判定為舊版"` 那段在比對的那一行。② 也已經透過 `grep -n 'rev 比' … UPGRADING.md` 把它列進去了。所以 ④ 和 ② 指的是同一處，只有「CHANGELOG 未發布區塊」才是 CI 真的不驗的。
  失敗情境：這段文字的用途就是分清哪些有 CI 驗、哪些沒有，結果把一處有 CI 驗的寫成沒驗，同一處還在 ② 和 ④ 各列一次。照清單做的人會以為 UPGRADING 另外還有一個寫死的 rev，去找一個不存在的地方。

[Important] CLAUDE.md:277（848ea70）｜「同批要改這四處」寫的是數量，但底下的子項自己又寫「兩處」「兩檔各一處」「與 CHANGELOG」，實際要改的地方是 7 處（① 2 處、② 2 處、③ 1 處、④ 2 處）。這違反全域 CLAUDE.md §3.10「凡是能列舉的就列舉，不要數」。
  證據：第 278–282 行，① 寫「兩處」、② 寫「兩檔各一處」、④ 寫「rev 值與 CHANGELOG 未發布區塊」。
  失敗情境：讀的人照「四處」逐項打勾，CHANGELOG 那一項很容易漏掉。CI 不驗 CHANGELOG，也沒有其他檢查會發現它漏了。

[Important] ci.yml:27（stamp()）與 CLAUDE.md:275｜舊定義裡「開頭是 `## 開發流程`」這個識別特徵被拿掉了；新 step 也只認「第一個 ```markdown 圍欄」，沒有確認抓到的區塊第一行是 `## 開發流程`。
  證據：舊版 ③ 原文是「三個反引號圍起來、開頭是 `## 開發流程` 的那一整塊」，新版只剩「三個反引號 `markdown` 圍起來的那一整塊」。dd-init.md 目前只有一個 ```markdown 圍欄（第 52 行），第 53 行就是 `## 開發流程（每個功能段落依序走）`；其他圍欄（157、168、271 行…）不是 markdown 就是沒有語言標記。
  失敗情境：日後有人在 Phase 0–1 加一個 ```markdown 範例（新圍欄出現在第 52 行之前），stamp() 就會改抓那個範例。非空檢查照樣通過，之後真正的蓋章區塊再怎麼改都是綠燈。舊文件寫的識別特徵正好能擋這種情況，現在 step 裡沒有，文件裡也沒了。

## Not reported
- 舊句裡的「緊接在後」「這行不含 `dd-loop-rev` 字串」兩個說明被刪了：② 的 grep 指令還在，照做不會出錯，所以不報。
- 舊版結尾記的那次事件出處（「同一輪前面的 commit…靠 code-review 才抓到」）從 CLAUDE.md 拿掉了；CHANGELOG:24 改寫成「以前只靠 code-review 抓（漏過一次，CI 全綠）」，讀起來像是 code-review 漏掉了，和舊版說的「code-review 抓到」相反。但「漏過一次」的主詞不明確，所以沒列成發現，交給你判斷。
- ① 寫「CI 驗前後一致」是對的：四方 step 有 `revs … sort -u` 的唯一性檢查和標記格式的 regex。新 step 和 ③、CHANGELOG 都無關，這部分屬實。
- 設計文件和進度表不在我負責的方向內，沒有審。

## What I ran
- Read rb-prompt-B.txt、rb-diff.txt（共 211 行，全部讀完）→ 拿到派工與材料
- `git show 848ea70:.github/workflows/ci.yml`，讀 302–356 行 → 四方 step 驗唯一性、標記格式、兩條判定線上的 rev
- `grep -n 'rev' UPGRADING.md` → 只有第 82 行
- `git show 848ea70:commands/dd-init.md | grep -n '^```'` → 第 52 行是唯一的 ```markdown，第 53 行是 `## 開發流程`
- 逐個 tag 讀 dd-init.md 的 rev → v1.6.5=9、v1.6.6=11、v1.6.7–v1.6.11=12
- `git log -G'dd-loop-rev: [0-9]+；' -- commands/dd-init.md` → 1299d45（rev 10）與 0233de6（rev 11）落在同一次發版之間
- grep 848ea70 版 CLAUDE.md、CHANGELOG、ci.yml 的行號 → 用來核對上面引用的行號

## 需要外部查證
- 舊版說「同一輪前面的 commit 動過蓋章區塊沒跳號，靠 code-review 才抓到」，是哪一個 commit？用 `git log -S'dd-loop-rev' -- commands/dd-init.md docs/reviews/` 對照 reviews 報告，就能確定 CHANGELOG「漏過一次」的歸因對不對。
- 有沒有專案目前蓋著 rev 10 這種從沒進過 tag 的號碼？在使用者的專案裡跑 `grep -r 'dd-loop-rev:' */CLAUDE.md`，可以確認 Critical 那條的失敗情境是不是已經真的發生過。

## 處置

見 `S1-judge.md` 的「處置」。
