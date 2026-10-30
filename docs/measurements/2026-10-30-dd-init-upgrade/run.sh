#!/bin/bash
# 測試清單 4：部署版 /dd-init 在沙盒裡跑 Phase 0、1。用法：run.sh <案例> <同意|拒絕>
T=${OUT:?先 export OUT=<setup.sh 用的目錄>}; c="$1"; ans="$2"
p="/dd-init

（測試環境說明：只執行 Phase 0 與 Phase 1，Phase 2 之後全部跳過、不要掛 hook。這個環境沒有 AskUserQuestion：遇到要問使用者是否升級的那一題時，不要停下來，當作使用者回答「${ans}」，照那條繼續做完 Phase 1。）"
printf '%s\n' "$p" > "$T/$c.prompt.txt"
cd "$T/$c" && claude -p "$p" --output-format stream-json --verbose --max-budget-usd 2 --no-session-persistence \
  --permission-mode dontAsk --allowedTools "Read Glob Grep Bash Edit Write Skill" --disallowedTools "Agent NotebookEdit WebFetch WebSearch" \
  --settings '{"advisorModel":""}' < /dev/null > "$T/$c.jsonl" 2> "$T/$c.stderr"
echo "$c exit=$? lines=$(wc -l < "$T/$c.jsonl")"
