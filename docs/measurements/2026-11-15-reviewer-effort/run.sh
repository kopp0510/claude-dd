#!/usr/bin/env bash
# 跑一發（從 ../2026-10-24-s5-inputs/run-noadvisor.sh 改來）：在該發的快照裡開 headless 父 session，stdout 存 <工作目錄>/logs/<發代號>.jsonl。
# 父 session 用 haiku（它只派工與轉交）；advisor 關掉；每發預算上限 8 美元；硬逾時 40 分鐘。
# 用法：bash run.sh <工作目錄> <發代號>
set -u
w=$1; run=$2
g=${run%%-*}
cd "$w/$run" || exit 1
dirs=("$w/prompts")
if [ -d "$w/$g" ]; then dirs+=("$w/$g"); fi
perl -e 'alarm 2400; exec @ARGV or exit 127' \
  claude -p "$(cat "$w/prompts/$run.parent.txt")" \
  --model haiku --output-format stream-json --verbose \
  --permission-mode dontAsk --allowedTools "Agent Read Glob Grep Bash" \
  --settings '{"advisorModel":""}' \
  --add-dir "${dirs[@]}" \
  --max-budget-usd 8 < /dev/null > "$w/logs/$run.jsonl" 2>&1
echo "${run} exit=$?"
