#!/bin/bash
# security-audit 觸發實測：ARM=pos|posctrl|neg|negctrl|d5b|inj|injctrl ./run.sh <scratchpad>
# 前提：已 ./install-dd-pipeline.sh --force；<scratchpad>/trig/claude-dd 是 claude-dd 的拋棄式 clone（目錄名要是 claude-dd）；
# negctrl 另要 <scratchpad>/trig/ctrl-plugin（拿掉 dmi 的副本）、injctrl 另要 <scratchpad>/trig/injctrl（skill 目錄放在專案裡的 git repo）；做法見 CLAUDE.md
set -u
S=${1:?scratchpad}; ARM=${ARM:?pos|posctrl|neg|negctrl|d5b|inj|injctrl}
T=$S/trig; HERE=$(cd "$(dirname "$0")" && pwd)
NOEDIT="Edit Write NotebookEdit"
CWD=$T/claude-dd
case "$ARM" in
  pos|posctrl) MODEL=haiku; CAP=0.5; PROMPT=$ARM; set -- --allowedTools "Skill" --disallowedTools "Read Glob Grep $NOEDIT Bash Agent" ;;
  neg)     MODEL=opus; CAP=3; PROMPT=neg; set -- --allowedTools "Skill Read Glob Grep" --disallowedTools "$NOEDIT Bash Agent" ;;
  negctrl) MODEL=opus; CAP=3; PROMPT=neg; set -- --allowedTools "Skill Read Glob Grep" --disallowedTools "$NOEDIT Bash Agent" --plugin-dir "$T/ctrl-plugin" ;;
  d5b)     MODEL=haiku; CAP=0.5; PROMPT=d5b
           # 預期值在跑之前算：預設輸出根目錄底下下一個沒用過的 run-<N>
           n=1; while [ -e "$HOME/security-audit-skill/claude-dd/run-$n" ]; do n=$((n+1)); done
           echo "$HOME/security-audit-skill/claude-dd/run-$n" > "$T/d5b.expected"
           # --add-dir：不加的話 dontAsk 連 Bash(ls:*) 列 cwd 外的目錄都擋（2026-11-14 haiku 探針，denials=1）
           # git remote／rev-parse：第一次只放行 ls，session 用 git 查 repo 名的那串被擋（denials=1），改用 Glob 才解出路徑
           set -- --allowedTools "Skill Glob Bash(ls:*) Bash(git remote:*) Bash(git rev-parse:*)" --disallowedTools "$NOEDIT Agent" --add-dir "$HOME/security-audit-skill" ;;
  inj)     MODEL=haiku; CAP=0.5; PROMPT=inj; set -- --allowedTools "Skill Read" --disallowedTools "Glob Grep $NOEDIT Bash Agent" ;;
  # 對照：同樣讀 HUNTING.md，但 skill 目錄在 cwd 的專案裡（巢狀 CLAUDE.md 會載入的情況）
  injctrl) MODEL=haiku; CAP=0.5; PROMPT=injctrl; CWD=$T/injctrl; set -- --allowedTools "Read" --disallowedTools "Skill Glob Grep $NOEDIT Bash Agent" ;;
  *) echo "ARM 只能是 pos|posctrl|neg|negctrl|d5b|inj|injctrl" >&2; exit 2 ;;
esac
cd "$CWD" || exit 1
perl -e 'alarm shift; exec @ARGV or exit 127' 900 \
  claude -p "$(cat "$HERE/$PROMPT.prompt.txt")" \
  --model "$MODEL" --output-format stream-json --verbose --max-budget-usd "$CAP" --no-session-persistence \
  --permission-mode dontAsk --settings '{"advisorModel":""}' "$@" \
  < /dev/null > "$T/$ARM.jsonl" 2> "$T/$ARM.stderr"
echo "exit=$?" > "$T/$ARM.exit"
