# docs/measurements/2026-11-14-security-audit-trial

cloudflare/security-audit-skill 的試跑紀錄：用 `--plugin-dir` 載入、對 claude-dd 的拋棄式 clone 跑 quick profile，量花費、agent 次數、產出與權限拒絕。

## 檔案

- `run.sh` —— `MODE=probe|real ./run.sh <scratchpad>`：在 `<scratchpad>/target/claude-dd` 跑 `claude -p`，旗標含 `--plugin-dir`、`--permission-mode dontAsk`、Bash 白名單、`--settings '{"advisorModel":""}'`，用 perl `alarm` 限時
- `check.sh` —— 從 `real.jsonl` 與稽核產物抽判定欄位：result 筆數與花費、Agent 依 `subagent_type` 計數、Skill 呼叫、權限拒絕、產物大小、`run_status`、各 verdict 筆數、自己重跑兩支驗證器、clone 有沒有被改
- `results.txt` —— `check.sh` 的輸出加上兩次探針與各模型花費；被 `README.md` 引用的證據，**不要在原處重跑蓋掉**
- `*.prompt.txt` —— 三次執行的 prompt，`<scratchpad>` 是佔位
- `README.md` —— 跑法、結果表、限制

## 此層慣例

- 原始 stream-json、稽核產物（REPORT.md、findings.json…）不進 repo：前者有編碼過的本機路徑；後者的 `run-metadata.json` 含本機絕對路徑，
  報告裡那筆 claude-dd 的安全線索已在 S1 修掉（`docs/designs/2026-11-14-security-audit-intake-design.md` 進度表 S1 那列），要用的數字摘在 `README.md` 的結果表
- 寫進來之前在本目錄跑 `grep -rnE '--exclude=CLAUDE.md' -- '-Users-[A-Za-z]|-private-tmp-|/private/tmp/|/Users/[A-Za-z]' .`，要回 0 筆（排除本檔，因為本檔寫著這個樣式）

## 與上層的關係

`docs/measurements/` 放實測原始數字；這份是 security-audit 收編的實證來源，`DD_PIPELINE_ARCHITECTURE.md` 部署清單那句引用它；`skills/security-audit/CLAUDE.md` 的分支清單把它標成「試跑已實跑」。
