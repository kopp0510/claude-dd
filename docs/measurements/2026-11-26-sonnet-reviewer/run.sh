#!/usr/bin/env bash
# 跑一發（照 ../2026-10-24-s5-inputs/run-noadvisor.sh，多設 CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0 免得背景審查者被停掉）
# 用法：bash run.sh <工作目錄> <發代號>
set -u
s4=$1; run=$2
g=${run%%-*}
cd "$s4/$run" || exit 1
CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0 perl -e 'alarm 3600; exec @ARGV or exit 127' \
  claude -p "$(cat "$s4/prompts/$run.parent.txt")" \
  --model opus --output-format stream-json --verbose \
  --permission-mode dontAsk --allowedTools "Agent Read Glob Grep Bash" \
  --add-dir "$s4/prompts" "$s4/$g" \
  --settings '{"advisorModel":""}' --max-budget-usd 20 < /dev/null > "$s4/logs/$run.jsonl" 2>&1
echo "${run} exit=$?"
