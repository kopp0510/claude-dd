# dd-loop 觸發實測（2026-10-30）

問題：全域 §3.9 改成「段落開始時、步驟 3、4、8 開始前呼叫 Skill `dd-loop`」之後，全新 session 會不會真的叫它。

- 跑法：`./run.sh <工作目錄>`（`./install-dd-pipeline.sh --force` 部署之後）。每個情境在新建的拋棄式 repo 跑一次 `claude -p`，
  repo 裡有一張進度表（S1 `IN_PROGRESS`、小任務已 commit）。只放行 `Skill Read Glob Grep`，寫檔工具與 Agent 擋掉 —— 只測「叫不叫」，不測照做
- 判定：`./check.sh <工作目錄>/out` → `results.tsv`（欄位定義在 `check.sh` 檔頭；原始 jsonl 不進 repo）。工作目錄放在任何 repo 之外，免得載入祖先 CLAUDE.md
- `results.tsv` 是 S1 步驟 4 審查後用修正版 `check.sh` 對**同一批** jsonl 重抽的（初版把 `inject_chars` 量成 `Launching skill: dd-loop` 那 24 字元、也沒抽 `first_tool` 與 `denials_total`），`claude -p` 沒有重跑
- prompt：同目錄 `*.prompt.txt`

## 結果

| 情境 | 次數 | 叫了 dd-loop |
|---|---|---|
| p1-start 新段落開始 | 2 | 2/2，都是第一個工具呼叫 |
| p2-handover 換人接手進行中的段落 | 2 | 2/2（先 Read 進度表，判定要做步驟 3 後才叫） |
| p3-step4 接著做步驟 4 | 2 | 2/2，都是第一個工具呼叫 |
| p4-step8 接著做步驟 8 | 2 | 2/2，都是第一個工具呼叫 |
| n1-typo 改一個錯字（反例） | 1 | 0/1，沒叫任何 skill |

9 次的 `permission_denials` 都是空的（`denials_total=0`），9 次都有 result（`result=ok`）。第一個工具呼叫見 `first_tool` 欄。合計約 US$3.85。

限制：
- 只證明「會被叫起來」，不證明是全域那句明寫呼叫造成的，還是靠 description 比對（沒有跑 description 中性化的對照組）
- 每種情境 n=2，不是觸發率

## context 量（同日量）

- 全域模板：28,082 → 23,040 字元（省 5,042 字元；bytes 56,068 → 46,158；量的是 a30dc1a 版；S1 審查修正後是 23,107 字元／46,257 bytes，省 4,975 字元）。skill 清單多出 dd-loop 的 description（167 字元），不跑迴圈的 session 淨省約 4.8k 字元
- 每叫一次 `dd-loop` 注入 6,188 字元（`results.tsv` 的 `inject_chars`；p3-step4-2 是 6,217）。
  一段迴圈照規則會叫 4 次（段落開始、步驟 3、4、8 前），約 24.8k 字元，**比全域省下的多** ——
  跑迴圈的 session 總量會增加；好處只在不跑迴圈的 session
