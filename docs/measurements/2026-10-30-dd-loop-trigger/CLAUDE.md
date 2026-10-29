# docs/measurements/2026-10-30-dd-loop-trigger

`skills/dd-loop` 的觸發實測：全域 §3.9 改成明寫「呼叫 Skill `dd-loop`」之後，全新 session 會不會真的叫它（全域 CLAUDE.md 瘦身 S1-2）。

## 檔案

- `run.sh` —— 建拋棄式 repo（有一張 S1 `IN_PROGRESS` 的進度表）並跑 `claude -p`，四個正例各 2 次、一個反例 1 次。
  旗標照根 CLAUDE.md「新增 Skill 步驟 5」，另加 `--settings '{"advisorModel":""}'`；只放行 `Skill Read Glob Grep`，只測叫不叫
- `check.sh` —— 從 jsonl 只抽判定欄位，欄位定義寫在它的檔頭。skill 本文不在 Skill 的 tool_result 裡（那裡只有 `Launching skill: dd-loop`），在下一則以 `Base directory for this skill:` 開頭的 user 訊息
- `results.tsv` —— `check.sh` 的輸出，被 `README.md` 與設計文件引用的證據；**不要在原處重跑 `claude -p` 蓋掉**，要重測就開新的日期目錄（S1 審查後用修正版 `check.sh` 對同一批 jsonl 重抽過一次，`README.md` 有記）
- `*.prompt.txt` —— 五個情境的 prompt 原文
- `README.md` —— 結果表、限制、context 量

## 此層慣例

- 原始 stream-json 不進 repo（init 訊息有編碼成 `-Users-<名字>-…` 的路徑、連接器清單），只留 `check.sh` 抽出來的欄位
- 跑之前要先 `./install-dd-pipeline.sh --force`：headless session 載入的是 `~/.claude/` 的部署版

## 與上層的關係

`docs/measurements/` 放實測原始數字；引用它的是 `docs/designs/2026-10-30-global-claude-md-slim-design.md` 的 S1 與 `DD_PIPELINE_ARCHITECTURE.md` 部署清單那句。
