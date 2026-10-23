# S3-judge — code-review 改裁決結構（第一次照新步驟 4 跑）

## 派工

- 主對話給裁決者的派工單：scratchpad 的 `S3_judge_prompt.txt`；diff 檔 `S3_review_bundle.txt`（4150 行：`git diff 6e9aaf0 HEAD` 加 13 個被改到檔案的整檔內容；工作目錄乾淨，HEAD = 92eea63）
- 步驟 3（code-simplifier）跳過：人工程式只有 `scripts/check-claude-md.sh` 三行 `echo` 字串，其餘是規則文件；所以 diff 檔沒有「步驟 3 的改動」那一份
- 裁決者：`general-purpose`、`model: opus`；約 7.2 分鐘（`duration_ms` 429097）、15 次工具
- 派了 3 個 `code-reviewer`（同一則訊息平行，不帶 model 參數 → opus；紀錄檔 agentType code-reviewer、spawnDepth 2、`message.model` claude-opus-5-5）。
  數量理由：diff 約 440 行、全是文件與提示字串，3 個方向就涵蓋，再多只會重疊在同樣的句子上
- 審查者方向與派工 prompt：見 `S3-a.md`、`S3-b.md`、`S3-c.md` 的派工節

## 發現

**Critical 1 / Important 3 / Smells 7（採納數）**；需使用者決定：無

- 【採納】
  1. a、b、c｜Critical｜模板「實測慢的審查時間大多花在一個檔一個檔撈 git,先備好就省掉這段」—— `docs/measurements/2026-10-23-reviewer-real-sessions.md` 結論 2 寫「這份數據證明不了『慢是因為逐檔撈 diff』」，結論 3 寫先交 diff 是推論、效果等 S4
  2. a｜Important｜蓋章版裁決子項少了「裁決者」主詞、「不續行」、「(含 Not reported、What I ran)」、「附選項與建議答案」
  3. a｜Important｜審查者被要求外部查證列出來交回，但裁決只有三類，這種項目沒地方放
  4. c（a、b 的 Not reported 也提到）｜Important｜`docs/reviews/CLAUDE.md` 新格式自相矛盾：審查者那份要「逐字原文」又要「三節」與「跨報告比對」，裁決者也沒交回它給審查者的 prompt
  5. a｜Important → Smells｜兩個「上面那條」指的是兩條不同的子項
  6. a｜Important → Smells｜「未追蹤的新檔放整檔」沒寫只限依序跑
  7. b、c｜Important → Smells｜`dd-init.md` rev 差異清單：rev 5、6 的條目在 rev 10 下自相矛盾；rev 9 句把「或」說成「要求」
  8. b｜Important → Smells｜CHANGELOG 新條目斷句、沒寫 `--force`、沒記 gate 提示、「或」說成強制
  9. c｜Important → Smells｜模板與蓋章版沒寫審查者是 opus
  10. c｜Important → Smells｜README 讀起來像「3 個」是量出來的
  11. a Not reported｜Smells｜沒定義某個審查者失敗或沒回來怎麼辦
- 【駁回】需使用者決定擋不擋續行；dd-init 沒有 rev 7（既有）；b、c 的「沒有漏改」「沒有殘留」結論一致；`reviews_missing` 認得新檔名（成立、不是缺陷）
- 【需要外部查證】Opus 裁決者派出的 code-reviewer 跑哪個 model；落地的審查者報告能不能同時是逐字原文又有三節

（裁決者完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 1：模板那句改成「先備好能不能加速是推論（慢的審查工具呼叫大多是 git diff/show/log），效果還沒量過」
- 2、5、6、9、11：模板與蓋章版同改 —— diff 檔內容改成 ①②③④ 編號、「未追蹤新檔放整檔」綁在依序那側、審查者「不帶 model 參數 —— agent 定義是 opus，不換 haiku」、
  「某個審查者沒回來 → 裁決者補派，補不了就照實寫進報告」；蓋章版補上「裁決者」「(含 Not reported、What I ran)」「不續行」「附選項與建議答案」
- 3：模板與蓋章版補「審查者列的外部查證項，裁決者能查就查，查不了另列『需要外部查證』交回」
- 4：模板、蓋章版、`docs/reviews/CLAUDE.md` 改成：審查者那幾份「派工」照裁決者交回的派工 prompt、「發現」放逐字原文、「處置」由主對話寫；重疊與獨有項寫進 `-judge.md`；
  裁決者交回時附上派工 prompt；派工節的範圍改成「diff 檔路徑與它的組成」。本段 `S3-a/b/c.md` 就是照這個落地的
- 7：rev 5、6 條目補「（rev 10 已由裁決結構取代）」「（rev 10 已改成『時間花在哪』）」；rev 9 句改成「列了…工具上限選項」
- 8：CHANGELOG 條目補句號、gate 提示檔名、`--force` 前提，工具上限改成「選項」
- 10：兩份 README 改成「一發只挖到一部分（數據），所以設了最少 3 個的下限，實際數量由裁決者決定」
- 外部查證：沙盒實跑（下面）已證實 `message.model` 是 claude-opus-5-5；三節加逐字原文的落地方式，本段三份報告就是實例
- **沙盒實跑另外抓到的三處**（拋棄式 repo `scratchpad/s3sandbox`，一個 subagent 扮主對話照 repo 版步驟 4 做，故意留一個 off-by-one 與一個未 commit 的 simplifier 改動），一併改進模板與蓋章版：
  - simplifier 自己改了什麼沒有分開交，三個審查者都看不出 `${1:?}` 是 simplifier 加的、改了行為 → diff 檔加「②步驟 3 自己改了什麼（依序時 `git diff HEAD`）」
  - 「已確認，不要重跑」那條的輸出正是 bug 算出來的值（`bash src/calc.sh 10` 印 4，應為 5）→ 驗證輸出「連同預期值一起寫」，註明「已確認」只代表跑過
  - 審查者報告的派工／處置要寫什麼沒定義 → 同第 4 條
- 修完重跑：模板步驟 4 與蓋章區塊的舊句清單逐句 `grep -cF` 全為 0、`2.3/3` 仍在、迴圈編號 8 項、本機 ci 檢查腳本全部 exit 0

## 重疊與獨有項

- 三個都抓到：第 1 條（模板那句無據的加速宣稱）
- 兩個以上：第 4 條（c 報出、a、b 在 Not reported 提到）、第 7 條（b、c）
- a 獨有：蓋章版少了限定（2）、外部查證沒地方放（3）、兩個「上面那條」（5）、未追蹤檔限依序（6）、審查者沒回來（11）
- b 獨有：CHANGELOG 條目（8）
- c 獨有：審查者沒寫 opus（9）、README 像是量出來的（10）
- 觀察：a 獨有 5 條、都在「兩份步驟 4 對照」這個方向；分方向派工讓獨有項集中在各自的方向
