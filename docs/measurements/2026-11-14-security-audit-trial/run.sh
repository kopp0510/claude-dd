#!/bin/bash
# security-audit 試跑：MODE=probe|real ./run.sh <scratchpad>
set -u
S=${1:?scratchpad}; MODE=${MODE:?probe|real}
case "$MODE" in
  probe) MODEL=haiku; CAP=0.5; ALARM=600; OUT=$S/probe-out ;;
  real)  MODEL=opus;  CAP=15;  ALARM=5400; OUT=$S/audit-out ;;
  *) echo "MODE 只能是 probe 或 real" >&2; exit 2 ;;
esac
cd "$S/target/claude-dd" || exit 1
perl -e 'alarm shift; exec @ARGV or exit 127' "$ALARM" \
  claude -p "$(cat "$S/runs/$MODE.prompt.txt")" \
  --model "$MODEL" --output-format stream-json --verbose --max-budget-usd "$CAP" --no-session-persistence \
  --plugin-dir "$S/sa-plugin" --add-dir "$OUT" \
  --permission-mode dontAsk \
  --allowedTools "Skill Read Glob Grep Agent Write Edit Bash(node:*) Bash(git:*) Bash(mkdir:*) Bash(ls:*) Bash(wc:*) Bash(test:*) Bash(echo:*) Bash(head:*) Bash(tail:*) Bash(cat:*) Bash(jq:*) Bash(sort:*) Bash(pwd) Bash(date:*)" \
  --settings '{"advisorModel":""}' \
  < /dev/null > "$S/runs/$MODE.jsonl" 2> "$S/runs/$MODE.stderr"
echo "exit=$?" > "$S/runs/$MODE.exit"
