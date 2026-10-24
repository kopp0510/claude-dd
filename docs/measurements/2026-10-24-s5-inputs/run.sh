#!/usr/bin/env bash
# 跑 S5 的一發（從 S4 的 run.sh 改來：父 session 自己查證，所以用 opus）：在該發的快照裡開 headless 父 session，stdout 存 <s4>/logs/<發代號>.jsonl
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
  --max-budget-usd 20 < /dev/null > "$s4/logs/$run.jsonl" 2>&1
echo "${run} exit=$?"
