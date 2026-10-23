# S3 計畫審查 第 1 輪（plan-review）

檔名不用 `S` 開頭的理由同 `plan-S2-r2.md`。

## 派工

- 派工單：scratchpad 的 `judge_S3_r1.txt`（由 S2 第 4 輪那份改出：輪次 1、範圍改 S3、計畫換成 S3 一節＋設計決策表＋技術設計 code-review＋進度表 S3 列、事實換成 S3 相關的已讀行號與巢狀派 code-reviewer 實測）
- 裁決者：`general-purpose`、`model: opus`；約 5.7 分鐘（`duration_ms` 343244）、13 次工具；4 個 haiku 審查者

## 發現（裁決者報告重點）

**結論：`不通過（2 條重大）`**；需使用者決定：無；需要外部查證：無

- 【採納（重大）】
  1. 舊寫法殘留驗不到：S3-1 的 grep 只命中 277、290、301，漏掉 `templates/global/CLAUDE.md` 286、295、298；`commands/dd-init.md` 蓋章區塊內 83、85、89、99；
     `scripts/check-claude-md.sh` 225；`docs/reviews/CLAUDE.md` 3、28、31。test-gate 與 CI 四方一致都不比內文 ⇒ 殘留會全綠
  2. 步驟 4「要控時間就在 prompt 寫明『最多做一次重現實驗』」（templates:280–284）是硬上限，跟使用者決定「不設硬性工具上限」衝突，計畫沒列要改
- 【採納（小事）】9 條：CHANGELOG 要跟跳 rev 同批；開工前提文字過期；沙盒實跑沒歸屬；裁決三類與 Critical/Important/Smells/Not reported 的對應；
  審查者職責與 agent「minimize false positives」方向不同；diff 檔組成沒寫；裁決者沒回來的處置；`-judge.md` 內容與撰寫者沒定義；
  `scripts/CLAUDE.md` 要改什麼沒寫；「編號仍 8 項」沒附指令
- 【駁回】12 條（gate 不數份數、Opus 派 code-reviewer 沒測過、巢狀讀 scratchpad、opus 覆寫、沒有共用範本、中間 commit 不一致、IN_PROGRESS、
  test-gate 註解、整段跳過時的裁決者、流程圖、第 9 項、審查者自標已查）

（完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 重大 1：S3-1／S3-2／S3-3 的檔案欄改成用內容列出全部舊句；驗收改成「`$OLD` 字串 grep 回 0」，範圍分別是 §3.9、蓋章區塊、gate 腳本與 `docs/reviews/CLAUDE.md`；`git show` 改用內容判
- 重大 2：S3-1 明列刪掉「最多做一次重現實驗」、只留「外部查證交回」；`commands/dd-init.md:84` 同句列進 S3-2
- 小事 9 條：全部寫進設計文件 S3 一節（沙盒實跑選「把 repo 版步驟 4 交 subagent 照做」，不必先部署）
- 照改寫後的 S3 送第 2 輪
