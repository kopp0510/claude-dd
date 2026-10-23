# S3 計畫審查 第 2 輪（plan-review）

檔名不用 `S` 開頭的理由同 `plan-S2-r2.md`。

## 派工

- 派工單：scratchpad 的 `judge_S3_r2.txt`（輪次 2、照第 1 輪改寫後的 S3 一節、事實補第 1 輪結果與「這輪改了哪裡」）
- 裁決者：`general-purpose`、`model: opus`；約 5.6 分鐘（`duration_ms` 336744）、9 次工具；4 個 haiku 審查者
- 裁決者自己的改動：計畫沒有貼進審查者 prompt，改成要審查者 Read 派工單第 6–119 行

## 發現（裁決者報告重點）

**結論：`不通過（2 條重大）`**；需使用者決定：無；需要外部查證：無

- 【採納（重大）】
  1. 第 1 輪重大 1 的修法仍不可靠：`$OLD` 單一 regex 照計畫正確做完一定紅（模板 279 的五發數字要保留、368「同時打兩發」、
     `S6-{a,b}.md` 歷史檔名、gate 190「不再靠兩份各寫一次」），真的漏改卻放行（`commands/dd-init.md:86` 的 `git show HEAD:<路徑>`、
     `scripts/check-claude-md.sh:226`、`docs/reviews/CLAUDE.md:23` 都不含 `$OLD` 的字）。必紅會逼執行者放寬 grep，漏抓就永遠沒人發現
  2. 沒有部署步驟：S3 改了 gate、全域模板、蓋章版，標 DONE 時 `~/.claude/` 仍是舊版，S4 量到的可能是舊流程（根目錄 CLAUDE.md「驗證完 commit 後再重跑安裝」）
- 【採納（小事）】6 條：被改到的檔讀 diff 檔裡的 HEAD 版本；沙盒實跑核對 model／agentType／spawnDepth；沙盒用哪份 gate；
  `-judge.md` 與三節的對應；「rev 9 缺什麼」的內容；S3-4 改成列句子、ARCHITECTURE 已確認不用改
- 【駁回】9 條（Opus 派 code-reviewer、子項縮排、test-gate 沒跑、第五方箭頭、IN_PROGRESS、文字一致性比對、報告子目錄、審查者職責、共用範本）

（完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 重大 1：拿掉 `$OLD`，改成每個檔列「要消失的舊句」（完整片語）逐句 `grep -cF` 回 0，另列「要保留的行」；
  範圍限在模板步驟 4（`sed -n '/^### 3\.9/,/^> 步驟 1/p'`）、蓋章區塊、其他檔整檔。清單裡每一句都先確認現在真的存在（各命中 1）
- 重大 2：S3 步驟 6 之後加 `--force` 部署並讀回；進度表 S3 列驗收補上
- 小事 6 條：全部寫進設計文件 S3 一節
- 照改寫後的 S3 送第 3 輪（最後一輪）
