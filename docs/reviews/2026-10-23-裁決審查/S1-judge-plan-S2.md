# S1 驗收 — plan-review 實跑（拿 S2 計畫當題目）

S1 的步驟 5 驗收：照 `skills/plan-review/SKILL.md`（commit 3a5c718 之後、補上 B6 判例之前的版本）實際跑一輪。
這份不是 S1 程式碼的審查，是「新 skill 跑起來的樣子」的證據，也是 S2 計畫第 1 輪的裁決結果。

## 派工

- 主對話照 SKILL.md 第 1、2 步：用腳本從 SKILL.md 取出「裁決者範本」，只填 `{…}`（輪次 1、範圍＝設計文件的 S2 一段、
  計畫全文＋三個附錄（設計決策表、技術設計 › 計畫審查、進度表 S2 列）、事實清單 7 條、根目錄），`《…》` 原樣留給裁決者
- 事實清單裡引用的行號（全域模板 547/554、task-planner 72/85、design-brainstorm 13/66、gen_planner.py 20/45）派工前逐行 `sed -n` 核過
- 裁決者：`general-purpose`、`model: opus`，背景執行
- 實際過程（從 subagent 紀錄檔讀）：裁決者派 4 個 haiku 審查者（深度 2），各 4／8／6／13 次工具、約 1.4–2.9 分鐘，全部完成後
  裁決者才開始查證；裁決者整體約 6.8 分鐘（`duration_ms` 410932）、10 次工具

## 發現（裁決者報告原文）

【派工】
派了 4 個，都用 haiku，沒有重派也沒有補派。
- 輪1-R1：前提成不成立，外加 plan-review SKILL.md 跟三個插入點接不接得上
- 輪1-R2：漏掉的同步點，範圍是全 repo 的批准類敘述與各層 CLAUDE.md 的同批規則
- 輪1-R3：範圍與驗證，看驗證抓不抓得到錯、順序、範圍做多或做少
- 輪1-R4：全面，特別看停等語、進度表規則區塊，以及 brainstorm 與 task-planner 的交接
理由：S2 跨三份規則檔、兩份 README、一支流程圖產生器和 CHANGELOG，同步點多，所以在三個專攻方向之外多派一個全面型，交叉覆蓋。

【讀檔檢查】
- 輪1-R1：過。抽查 skills/task-planner/SKILL.md:83，原文是「使用者批准的測試清單，就是使用者要求加的測試…」，對得上。
- 輪1-R2：過。抽查 templates/global/CLAUDE.md:708–710，§6.1「回問」清單裡有「涉及設計取捨」，對得上。
- 輪1-R3：過。抽查 docs/designs/2026-10-23-裁決審查-design.md:12，S2 驗收欄有「`claude -p` 全新 session 走 task-planner 時會叫 plan-review」，對得上。
- 輪1-R4：過。抽查 skills/design-brainstorm/SKILL.md:14–16，寫的是「ExitPlanMode 的時機錨在第 5 步逐段確認之後、第 6 步寫設計文件之前」，對得上。
- 沒有重派、沒有補派。

【採納（重大）】
1. 來源：輪1-R1-1、輪1-R2-2、輪1-R3-2、輪1-R4-2
   內容：task-planner 把「使用者批准的測試清單」當成 §3.5「使用者要求才加測試」的授權來源。計畫拿掉批准題，卻沒寫這份授權改從哪裡來。照做之後，測試會在沒人要求的情況下寫進設計文件。
   查證：skills/task-planner/SKILL.md:83、同檔 :89「結尾附批准的測試清單」、同檔 :119（進度表規則區塊）「測試照文件裡的測試清單加；想加清單以外的測試，先問使用者」、templates/global/CLAUDE.md:199「不主動新增測試;使用者要求或修 bug 時例外」。計畫 S2-2 只寫「步驟 4 與其完成條件；批准題拿掉」，:83 的授權語意和 :89 都沒處理。
   計畫要怎麼改：S2-2 的檔案欄明列 :83 與 :89，寫出測試清單的新授權方式（選項見【需使用者決定】第 1 題）。:119 屬於照抄進各專案的規則區塊，要一併判斷改不改。
2. 來源：輪1-R4-3、輪1-R1-2
   內容：design-brainstorm 的插入點跟流程順序對不上。plan-review 規定在 brainstorm「設計逐段整理好、離開 plan mode 之前」跑；計畫寫的插入點卻是「硬閘門與步驟 8」，而步驟 8 在寫檔之後、ExitPlanMode 早已按過，審查放那裡攔不住任何東西。計畫也沒寫步驟 8 的「依回饋修改至批准」改成什麼。
   查證：skills/plan-review/SKILL.md:20、skills/design-brainstorm/SKILL.md:14–16、同檔 :64–67。
   計畫要怎麼改：plan-review 插在第 5 步之後、ExitPlanMode 之前，硬閘門改寫成這個順序；步驟 8 拿掉「修改至批准」，只留下一步的分流；ExitPlanMode 仍由使用者按。
3. 來源：輪1-R1-3、輪1-R3-4、輪1-R4-1
   內容：英文版有同樣的批准敘述，但 S2-3 的驗證只 grep「批准」，README.md 也不在 grep 的範圍裡。
   查證：diagrams/src/gen_planner.py:45 `"files written after you approve"`、README.md:127「The plan is shown to you for approval before anything is written」、S2-3 驗證指令不含 README.md 也不含英文字樣。
   計畫要怎麼改：S2-3 檔案欄點名兩處英文；驗證改成 `grep -rniE '批准|approv' README.md README.zh-TW.md DD_PIPELINE_ARCHITECTURE.md diagrams/src/gen_planner.py`，舊寫法要回 0（逐處判，留下的要寫理由）。
4. 來源：輪1-R1-4、輪1-R2-5、輪1-R3-5、輪1-R4-7
   內容：改 gen_planner.py 的文字可能讓字溢出框，S2-3 只寫「開 GIF 看文字」，沒列專案規定的幾何檢查。
   查證：diagrams/src/CLAUDE.md:45、:54、:117。
   計畫要怎麼改：S2-3 驗證加上「兩版 SVG 各跑 verify-geometry.py --cycle 7.2，0 項不過」，再開 GIF 看文字。
5. 來源：輪1-R2-4、輪1-R3-1、輪1-R4-6
   內容：S2 驗收要用 `claude -p` 測，但計畫沒寫測之前要先 `--force` 部署；沒部署就測會假綠（已部署的 plan-review description 本來就寫 task-planner 會啟用）或假紅。
   查證：根目錄 CLAUDE.md:185、~/.claude/CLAUDE.md:554、skills/plan-review/SKILL.md:3、:80、設計文件:11 與 :12。
   計畫要怎麼改：S2 驗收欄開頭補「`--force` 部署後」；判定依據改成看「改寫後的 task-planner 沒有再問批准題、而且叫了 plan-review」。

【採納（小事）】
- 輪1-R4-9、輪1-R1-7、輪1-R3-3：步驟 4 的 :79「跟批准題一起批」與 :82「決策題選了非建議答案…再問一次批准」要改寫；決策題併進 plan-review 第 4 步一起問，選了非建議答案照 plan-review SKILL.md:73 的規則重審。
- 輪1-R2-3、輪1-R3-7、輪1-R4-11：§4.1 停等語段（templates/global/CLAUDE.md:559–562）跟新寫的「→ 動手」放在同一節，沒寫哪個優先。S2-1 寫明「→ 動手」不覆蓋停等語，停等語段保留不動。
- 輪1-R3-6、輪1-R4-10：design-brainstorm :14「逐段確認」、:50「這部分同意嗎」、:52「同意後再做」是設計對話中的決策題，不是最終批准。S2-2 寫明第 5 步的逐段確認保留。
- 輪1-R1-5、輪1-R2-6：重出流程第 2 步要用 playwright（diagrams/src/CLAUDE.md:93），開工前提只點名 ffmpeg。ffmpeg 已確認在 /opt/homebrew/bin/ffmpeg。
- 輪1-R1-6、輪1-R2-7：CHANGELOG 條目要寫進 `## 未發布`。
- 輪1-R2-8：`grep -n '複雜' commands/dd-init.md` 已確認 0 筆；S2-1 直接寫「已核對，dd-init 不引用 §4.1，不跳 rev」。

【駁回】
- 輪1-R2-1｜§6.1「涉及設計取捨→回問」跟新規則衝突｜計畫只拿掉計畫交出去之前的最後一道批准，§6.1 管的是工作中的回問，兩者沒有矛盾；「什麼要問使用者」也是使用者決定。
- 輪1-R4-4｜task-planner 只切出 1 段就離開，會繞過審查｜離開之後仍是 §4.1 的複雜任務，S2-1 已涵蓋。
- 輪1-R4-5｜不走 task-planner 的複雜任務沒有驗證｜S1 驗收已含「`claude -p` 全新 session 複雜需求會叫起 plan-review」。
- 輪1-R3-8｜S2-1 與 S2-2 之間有過渡期矛盾｜同一段內連續 commit，整段跑完、部署之後才生效。
- 輪1-R4-8｜乾跑應該改成在拋棄式 repo 實跑｜「新增 Skill 步驟 3」本身已規定會寫檔的步驟在拋棄式 repo 真的跑。
- 輪1-R4-12｜brainstorm 接 task-planner 時 plan-review 跑兩次｜兩次審的是不同產物；三個插入點是使用者決定。
- 輪1-R4-13｜沒提醒既有使用者重跑 `--force`｜既有機制（UPGRADING.md），CHANGELOG 已在 S2-3 範圍內。
- 輪1-R2-10｜`--force` 會覆蓋本機全域 CLAUDE.md｜既有安裝行為，覆蓋前會先備份，跟 S2 計畫的正確性無關。

【需使用者決定】
1. 來源：輪1-R1-1、輪1-R2-2、輪1-R3-2、輪1-R4-2｜拿掉 task-planner 的批准題之後，設計文件裡的測試清單憑什麼算「使用者要求加的測試」？｜(a) 測試清單保留成一題決策題 (b) 開工前貼出的計畫含測試清單、沒喊停就視為要求 (c) 只收使用者明說要加的測試｜建議 (a)｜§3.5 只說「使用者要求時例外」，沒定義什麼算要求｜卡住採納（重大）第 1 條

【需要外部查證】
- 輪1-R2-9、輪1-R4-14｜小事｜本機 playwright 能不能用（重出 GIF 第 2 步需要）。

【結論】
不通過（5 條重大）

## 處置

- 第 3 步「不通過」：需使用者決定第 1 題卡住重大第 1 條 → 先問。使用者選 (a)「只問測試那一題」（建議答案）
- 5 條重大、6 條小事全部寫進設計文件的 S2 一節與 S2 驗收列（`docs/designs/2026-10-23-裁決審查-design.md`）
- 外部查證（playwright）列進 S2 開工前提
- 第 2 輪：S2 開工時照 SKILL.md 送審，附上本報告
- **這次實跑驗到的 skill 行為**：巢狀派工等到全部審查者才判 ✔；自訂數量（4 > 最少 3）並寫理由 ✔；讀檔抽查每個審查者一處 ✔；
  三類分類＋小事／重大 ✔；需使用者決定附選項與建議答案、標出卡住哪條 ✔；結論字面三選一 ✔
