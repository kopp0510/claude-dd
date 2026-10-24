#!/usr/bin/env bash
# 跑 S5 的一發、關掉 advisor（同 run.sh，只多 --settings 把 advisorModel 設成空字串；B 組第 1、2 發的父 session 叫了 advisor，使用者 2026-10-24 選擋掉重跑）：在該發的快照裡開 headless 父 session，stdout 存 <s4>/logs/<發代號>.jsonl
# 用法：bash run.sh <s4 工作目錄> <發代號>
set -u
s4=$1; run=$2
g=${run%%-*}
cd "$s4/$run" || exit 1
perl -e 'alarm 3600; exec @ARGV or exit 127' \
  claude -p "$(cat "$s4/prompts/$run.parent.txt")" \
  --model opus --output-format stream-json --verbose \
  --permission-mode dontAsk --allowedTools "Agent Read Glob Grep Bash" \
  --add-dir "$s4/prompts" "$s4/$g" \
  --settings '{"advisorModel":""}' --max-budget-usd 20 < /dev/null > "$s4/logs/$run.jsonl" 2>&1
echo "${run} exit=$?"
