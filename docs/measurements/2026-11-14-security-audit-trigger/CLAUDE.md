# docs/measurements/2026-11-14-security-audit-trigger

security-audit 收編（S2）步驟 5 的部署後實測：`/security-audit` 叫得起來、不打指令名時不會自己叫、預設輸出路徑算得對、部署的 `CLAUDE.md` 會不會被當成巢狀記憶讀進去。

## 檔案

- `run.sh` —— `ARM=<臂> ./run.sh <scratchpad>`：在 `<scratchpad>/trig/claude-dd`（claude-dd 的拋棄式 clone，目錄名要是 `claude-dd`）跑一發 `claude -p`，輸出寫到 `<scratchpad>/trig/<臂>.jsonl`。
  臂：`pos`、`posctrl`、`neg`、`negctrl`、`d5b`、`inj`、`injctrl`；每臂的旗標寫在 `case` 裡
- `check.sh` —— `./check.sh <scratchpad> <repo 根目錄>`：從各臂的 jsonl 抽判定欄位，輸出就是 `results.txt`。路徑先換成 `<S>`、`~` 再截斷
- `results.txt` —— `check.sh` 的輸出；被 `README.md` 引用的證據，不要在原處重跑蓋掉
- `*.prompt.txt` —— 各臂的 prompt（negctrl 共用 `neg.prompt.txt`）；`inj-1`、`injctrl-1` 是第一版（只靠 grep jsonl，兩臂都 0，沒有鑑別力），留著對照；`probe-ls` 是定 d5b 旗標前的探針，兩次的旗標寫在 `README.md`
- `README.md` —— 跑法、結果、限制

## 此層慣例

- 原始 jsonl 不進 repo（init 訊息有編碼過的本機路徑）
- `neg`、`negctrl` 兩臂真的對 claude-dd 做了稽核：回覆與工具參數可能帶弱點細節，`check.sh` 對這兩臂只印工具次數、Skill 呼叫與判定欄位（設計文件 U4：公開 repo，未修的弱點細節不進 repo）
- 寫進來之前在本目錄跑 `grep -rnE --exclude=CLAUDE.md -- '-Users-[A-Za-z]|-private-tmp-|/private/tmp/|/Users/[A-Za-z]' .`，要回 0 筆（排除本檔，因為本檔寫著這個樣式）

## 與上層的關係

`skills/security-audit/CLAUDE.md` 分支清單的 D5b 那列、設計文件 A12 #3 與 A21 ③ 引用這裡的結果。
