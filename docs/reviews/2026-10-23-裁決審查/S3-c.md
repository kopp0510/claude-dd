# S3-c — code-review 改裁決結構

## 派工

裁決者給審查者 c 的派工 prompt（共用部分逐字，加上方向句）。範圍：`git diff 6e9aaf0 92eea63`。

方向：gate 提示、`docs/reviews/CLAUDE.md`、`scripts/CLAUDE.md`、兩份 README、設計文件的宣稱成不成立，以及全 repo 有沒有殘留（173s／11 次工具）

```text
你是 claude-dd repo（/Users/danlio/project/my_project/claude-dd）段落 S3「code-review 改裁決結構」的審查者。

## 範圍與取檔
- diff 檔：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4e4927d5-72bb-4910-b6a4-f0ff595356ac/scratchpad/S3_review_bundle.txt
  （約 4150 行；第 1–443 行是 `git diff 6e9aaf0 HEAD`，第 444 行起是每個被改到檔案的整檔內容，帶行號，以 `----- FILE: <路徑>` 分隔）。
- **被改到的檔一律讀 diff 檔裡那一份，不讀工作目錄**。沒被改到的檔（例如 .github/workflows/ci.yml、tests/、skills/、agents/code-reviewer.md、DD_PIPELINE_ARCHITECTURE.md、diagrams/src/）照常讀 repo。
- 專案規則：repo 根目錄 CLAUDE.md、scripts/CLAUDE.md、docs/reviews/CLAUDE.md（後兩份被改到，讀 diff 檔那份）。
- 計畫與三輪計畫審查：docs/designs/2026-10-23-裁決審查-design.md 的 S3 一節（在 diff 檔裡）。

## 你的職責
找漏洞、證明這次改動有錯。每條附證據（diff 檔行號或 repo 檔案:行、grep 結果原文），**沒證據的不算**。
分級 Critical / Important / Smells；判成「既有問題、不是這次引入的」也要列出來（放 Not reported 並附行號），由裁決者判。
只用手上的資料判斷；需要外部查證的（例如實際派 agent 跑、上網查）列出來交回、不要自己去做。不設工具次數上限。不准改 repo 任何檔、不 commit。

## 已確認，不要重跑（2026-10-24 本輪實跑）
- 本機照跑 ci.yml 的「迴圈步數四方一致」「迴圈步數第五方」「CHANGELOG 已發布區塊不可改動」三個 step（指令用 ruby -ryaml 從 ci.yml 原文取出）：都 exit 0；四方輸出「全域模板 §3.9=8 dd-init 蓋章版=8 README.md=8 README.zh-TW=8 標記=8step」「✅ 四方一致，版本標記與 dd-loop-rev（含舊版判定線的 rev）都對得上」
- `shellcheck -S warning scripts/check-claude-md.sh` 通過；`bash tests/test-gate.sh` exit 0
- 舊句逐句 `grep -cF` 都回 0：
  - 模板步驟 4 範圍（`sed -n '/^### 3\.9/,/^> 步驟 1/p' templates/global/CLAUDE.md`）：派兩個 reviewer 跑同一份 prompt／兩份報告對同一處講不一樣時／最多做一次重現實驗／git show／兩份報告一律落地成 committed 檔／S<段落>-{a,b}.md／13–17 分鐘 ×2 發／成本 ×2
  - dd-init 蓋章區塊（第一、二個 ^``` 之間）：派兩個 reviewer 跑同一份 prompt／兩份報告講不一樣時／最多做一次重現實驗／git show／兩份報告落地成 committed 檔／S<段落>-{a,b}.md／成本 ×2／781s 與 1007s／13–17 分鐘 ×2
  - scripts/check-claude-md.sh、docs/reviews/CLAUDE.md、兩份 README 各自的舊句清單
- 保留項還在：模板步驟 4 範圍的 2.3/3、1.8/3；`grep -cF '同時打兩發' templates/global/CLAUDE.md` = 1；蓋章區塊的 2.3/3 與「兩個 reviewer 抓出 2 個 Critical」；S6-{a,b}.md 兩處

## 交回格式
- Critical / Important / Smells：每條「位置（diff 檔行號或 檔:行）｜內容｜證據原文｜失敗情境｜建議改法」
- Not reported（含判成既有問題的，附行號與理由）
- 需要外部查證
- What I ran（你實際跑過的指令）
```

## 發現

（裁決者交回的逐字原文）

Critical 1 / Important 4 / Smells 0。審查範圍：`git diff 6e9aaf0 HEAD`（HEAD=92eea63）。被改到的檔讀 S3_review_bundle.txt 裡那一份；沒被改到的檔讀 repo（tests/、agents/、docs/measurements/）。

Fowler 壞味道基準這次沒套用：diff 全是文件和提示字串，沒有新增的程式結構。

[Critical] templates/global/CLAUDE.md:280（bundle diff 第 397 行）「實測」宣稱跟量測文件矛盾
- 內容：模板寫「實測慢的審查時間大多花在一個檔一個檔撈 git,先備好就省掉這段」。
- 證據 1：docs/measurements/2026-10-23-reviewer-real-sessions.md:112 寫「這份數據**證明不了**『慢是因為逐檔撈 diff』」，同檔 :114 寫先交 diff 是「**推論**…效果要等 S4…才算數」。
- 證據 2：設計文件（bundle 2302 起算第 40 行、第 118 行）也把「先交 diff 能加速」列成推論與 S4 的驗收項。
- 失敗情境：全域模板部署後，每個專案都會讀到一句被標成實測的推論。這違反 §2，也違反 §3.10 對辯護性註解的規定，而且 S4 量測之前就先替結論背書了。
- 建議改法：改成「推論：…，S4 實測後再定」，或整句刪掉。

[Important] docs/reviews/CLAUDE.md:23、28、29、31；templates/global/CLAUDE.md:308–309；commands/dd-init.md:89：審查者報告的格式彼此矛盾
- 衝突 1：審查者報告要「照裁決者交回的完整報告落地」（逐字），又要求「各三節：派工 / 發現 / 處置」。code-reviewer 的輸出格式是 verdict、findings、What I ran、Not reported，沒有派工和處置兩節。
- 衝突 2：模板 :285–288（bundle 404–406）規定裁決者只交回「每個審查者的完整報告」，沒交回它發給審查者的 prompt。所以主對話寫不出審查者那幾份的「派工」節。
- 衝突 3：:28「多個審查者獨立抓到同一項要標出來」和 :31「末尾加一節各審查者獨有項（比對其他審查者的報告）」都需要跨報告比對。審查者是平行跑的，做不到；主對話補上又會破壞「逐字」。
- 衝突 4：「處置」在 N 份審查者報告和 `-judge.md` 各寫一次。:45 要求處置「必須保持正確」，等於要同步維護 N+1 份。設計文件 S3-3（bundle diff 第 185 行）只定義了 `-judge.md` 的三節，沒定義審查者那幾份。
- 失敗情境：第一個照新慣例落地的段落，主對話只能二選一：改寫審查者原文（證據作廢），或者三節空著或靠猜。
- 建議改法：審查者那幾份只放逐字原文。把重疊項、獨有項、處置集中寫進 `-judge.md`，裁決者交回時一併附上它發給審查者的 prompt。

[Important] templates/global/CLAUDE.md:281–282、commands/dd-init.md:84：計畫要求的「審查者 Opus」沒寫進去
- 證據：設計文件 S3-1（bundle diff 第 156 行）列的要素是「`subagent_type: "code-reviewer"`，Opus」。決策表（設計文件第 49 行）寫「code-review 審查者模型 Opus…補不回漏掉的錯」，第 112 行寫「code-review 審查者不換 haiku」。改完的模板和蓋章版只寫了 subagent_type，沒寫 model。
- 背景：agents/code-reviewer.md:4 是 `model: opus`，但 Agent 工具的 model 參數可以覆寫它。同一套 plan-review 的審查者正是 haiku。
- 失敗情境：裁決者照 plan-review 的習慣替審查者帶上 `model: "haiku"`，就違反了上面那條使用者決定，而且不會有任何錯誤。
- 建議改法：補一句「審查者不帶 model 參數，或明寫 opus；不換 haiku」。

[Important] README.md:125、README.zh-TW.md:130：拿 2.3/3、1.8/3 去支撐「最少 3 個」
- 內容：英文版寫「dispatches **at least three** reviewers in parallel: measured …(two runs union to 2.3/3…)」，中文版寫「最少 3 個審查者 —— 實測…」。
- 證據 1：這組實驗只比了一發和兩發，沒有量過三發。
- 證據 2：設計決策表第 50 行寫「最少 3 個」的理由是「使用者決定」。設計 S3-1 第 156 行要求這組數字只當「一發只挖到一部分」的依據，並標明數量由裁決者決定。兩份 README 都沒寫「數量由裁決者決定」。模板 :282 用的是「一發只會挖到一部分 ——」，寫法是對的。
- 失敗情境：讀者以為「3」是量出來的。以後有人拿「兩發就到 2.3」去主張降回 2，或在這上面再推論，用的都是一個不存在的依據。
- 建議改法：照模板的寫法改成「一發只挖到一部分（數據…）；最少 3 個是設定的下限，實際數量由裁決者決定」。中英兩份同批改。

[Important] commands/dd-init.md:46：說 rev 9「還要求 prompt 寫『最多做一次重現實驗』」，與舊文不符
- 證據：舊蓋章版（bundle diff 第 93 行）原文是「prompt 寫明『最多做一次重現實驗』，**或**『需要外部查證的列出來交回…』」，是二選一，不是硬性要求。舊模板（bundle diff 第 412–413 行）也是「或」。
- 失敗情境：升級對話框把 rev 9 描述成強制工具上限，使用者是在錯的前提下決定要不要升級（影響低，但它是一句會被照抄的事實宣稱）。
- 建議改法：「還要求」改成「還建議」，或改成「還列了『最多做一次重現實驗』這個選項」。

其餘重點方向，查過、成立：
- `reviews_missing` 認得新檔名：比對式是 `gitq diff --name-only --diff-filter=A … | grep -qE '(^|/)S[0-9][^/]*\.md$'`（bundle 3150 起算第 205 行）。`S3-c.md`、`S3-judge.md` 都會命中；`plan-S3-r1.md` 因為 S 前面是 `-`，不會命中。
- tests/test-gate.sh 沒有斷言舊提示字串。review 相關的 said 只比「上一段沒有附 review 報告」「docs/reviews/S<段落>-SKIP.md」「沒有新增任何 docs/reviews/S*.md」，三句都還在。:254–258 的 `S1-a/-b` 是測資，不受影響。測試沒有用 `-judge.md`、`-c.md` 當測資的情境；比對式沒動，所以不算缺陷。
- 全 repo git grep「兩個 reviewer / 取聯集 / -a 與 -b / {a,b} / two reviewers」：剩下的命中都是歷史敘述或刻意保留的項目，沒有現行規則殘留。包括 dd-init.md:46 rev 歷史、:81、:99；scripts/CLAUDE.md:147；check-claude-md.sh:103、:190；docs/reviews/CLAUDE.md:9；templates :275、:469；tests/CLAUDE.md:11；設計文件 :53、:104、:142、:208。
- 中英兩份 README 講的是同一件事（diff 檔、Opus 裁決者、最少 3 個、三類、讀程式碼不表決），內容等價。
- scripts/CLAUDE.md:76 的宣稱成立。
- 設計 S3 進度表列是 IN_PROGRESS；沙盒實跑和部署讀回還沒做，這跟「步驟 5 才做」的計畫一致。

Not reported:
- docs/reviews/CLAUDE.md:27 派工範圍只寫 `git diff <起點> HEAD`，沒涵蓋依序路徑的 `git diff <起點>` 加未追蹤新檔。這是既有寫法，不是這次 diff 引入的，但它和新的 diff 檔規則並列，讀起來會矛盾。
- CHANGELOG.md 未發布條目（bundle diff 第 13–14 行）：「…詢問升級」後面缺句號，接著「兩份 README…」會渲染成同一句。只是文字問題。

需要外部查證：
- Opus 裁決者派 code-reviewer 時，審查者實際跑的 model：S3 沙盒實跑時讀 subagent jsonl 的 `message.model` 就能確定。如果裁決者帶了 model 覆寫，會直接在這裡看出來。
- 沙盒實跑時檢查一份落地的 `S*-a.md`，看三節和逐字原文能不能同時成立，可以實證上面那條格式矛盾。

What I ran：
- 用 `sed -n '1,443p'` 讀 bundle 的 diff 部分 → 讀完整段 diff
- `grep -n '^----- FILE\|reviews_miss\|S\[0-9\]' bundle` → 定位各檔與比對式
- `sed -n '3120,3180p;2690,2742p' bundle` → 讀 reviews_missing 與 docs/reviews/CLAUDE.md 全檔
- `git rev-parse --short HEAD; git status --short` → 92eea63，工作目錄乾淨
- `git grep -nE '兩個 reviewer|取聯集|兩份報告|two reviewers|…|\{a,b\}|S<段落>-a|兩發…'`（排除 CHANGELOG 與歷史報告）→ 結果如上，沒有現行規則殘留
- `grep -n 'said\|聯集\|reviewer\|-b.md\|兩條路…' tests/test-gate.sh`；`sed -n 245,265p tests/test-gate.sh` → 沒有斷言舊提示
- `grep -n '^model\|^name' agents/code-reviewer.md` → model: opus
- 對 bundle 裡的設計文件 grep `3 個\|最少\|Opus\|haiku` → 決策表第 49、50、112 行
- `ls docs/measurements`；`grep -rn '撈\|工具次數' docs/measurements`；`sed -n 108,116p docs/measurements/2026-10-23-reviewer-real-sessions.md` → 「證明不了」「推論」原文
- `grep -n '一個檔一個檔撈' -r . --include='*.md'` → 只有 templates/global/CLAUDE.md:280
- `grep -n '最少 3\|at least three'` 掃兩份 README、模板、dd-init → 行號如上

## 處置

- 採納，對應 `S3-judge.md` 的第 1（Critical）、4（Important）、7、9、10（降為 Smells）條：全部照改
- 「`reviews_missing` 認得 `-c.md`、`-judge.md`」：成立、不是缺陷
- 兩條外部查證：放進步驟 5 沙盒實跑，結果見 `S3-judge.md` 處置
