# S4 計畫審查 第 2 輪（plan-review）

檔名不用 `S` 開頭的理由同 `plan-S2-r2.md`。

## 派工

- 派工單：scratchpad 的 `judge_S4_r2.txt`（輪次 2、計畫換成照第 1 輪改寫後的 S4 一節、事實補「第 1 輪結果」「這輪改了哪裡」、haiku 實測、`8514fb2` 帶 G2 答案）
- 裁決者：`general-purpose`、`model: opus`，背景執行；約 7.5 分鐘（`duration_ms` 449539）、11 次工具；4 個 haiku 審查者（前提、隔離與洩題、量法、同步點與範圍）

## 發現（裁決者報告重點）

**結論：`不通過（3 條重大）`**；需使用者決定：無

- 【採納（重大）】
  1. 輪2-R1-2、輪2-R2-2、輪2-R3-5：快照只隔離了 repo。每一發 `claude -p` 都會載入部署版 `~/.claude/CLAUDE.md`，裡面已有 G2、G3 修正之後才寫進去的教訓（K2 ← db0af00、K3 ← a4ed41f、K6 ← ee68e72，`git log -S` 查證），所有組一起灌水；洩題檢查只 grep 兩個字串，抓不到；禁區沒含 `~/.claude/projects/`
  2. 輪2-R3-1、輪2-R3-2、輪2-R3-6：`result.duration_ms`、`total_cost_usd` 的來源不存在 —— projects 的紀錄檔沒有 `result`（s4probe 實測 0 筆），計畫也沒帶 `--output-format stream-json --verbose`；父 session 有兩筆 `result`，只取一筆會少算；沒檢查 `permission_denials` 與預算中止
  3. 輪2-R2-3、輪2-R3-3：「審查者層新舊直接比，讀得出先交 diff 檔的效果」不成立 —— 同一格同時變了 diff 檔、探索預算、派工指令、層數
- 【採納（小事）】7 條：舊做法父 session 的參數寫明；brief 要 grep 不含答案；K 先對到快照程式碼位置；G4「讀完」判準收緊；實驗輸入收進 repo；限制段寫明父層是 `claude -p`；命中表用 `sed -n` 印原句比對
- 【駁回】14 條（多數同第 1 輪、無新證據；另含舊做法費用基準、`docs/reviews/CLAUDE.md` 帶的判例不是 K1–K3）
- 【需要外部查證】小事 1 條：`total_cost_usd` 在背景子代理下有沒有涵蓋整條鏈

（完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 重大 1：試了兩種不載入全域規則的跑法，都不行 —— `--bare` 只認 `ANTHROPIC_API_KEY`（本機沒設）；`CLAUDE_CONFIG_DIR` 換到只有 `agents/code-reviewer.md` 的目錄，回 `Not logged in · Please run /login`。所以照 (a)：K2、K3、K6 標「受污染，只當參考」，命中比較只算 K1、K4、K5（三個用 `git log -S` 查全域模板與 skills 都 0 筆）；禁區改成「快照目錄以外一律不讀」；機械檢查改成「工具輸入出現快照與 `s4/` 以外的絕對路徑就作廢」；限制段寫明
- 重大 2：每發帶 `--output-format stream-json --verbose`、stdout 存 `out.jsonl`；全部 `result` 都讀、取最後一筆；`permission_denials` 不空或預算／錯誤中止就作廢重跑
- 重大 3：刪掉歸因，改寫成「舊實務對新實務的整體差異」，四個變數列進限制；開放問題回填「分不出 diff 檔單獨的效果」。「另加一組舊派工＋diff 檔」這次不加（會再加錢、加範圍；需要時另開）
- 小事 7 條：全部寫進設計文件 S4 一節
- 外部查證：第一發實跑時核對
- 送第 3 輪（最後一輪）
