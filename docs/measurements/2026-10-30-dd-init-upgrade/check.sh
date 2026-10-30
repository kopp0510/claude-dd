#!/bin/bash
# 測試清單 4 的判定：jsonl 的 Bash 呼叫順序 + 最終 CLAUDE.md 的內容
T=${OUT:?先 export OUT=<setup.sh 用的目錄>}
for c in agree refuse rental react create cli curl rev13; do
  j="$T/$c.jsonl"; d="$T/$c"; echo "== $c"
  [ -s "$j" ] || { echo "  ❌ 沒有 jsonl"; continue; }
  jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name + " " + ((.input.command // .input.file_path // .input.skill // "")|tostring|gsub("\n";" ")|.[0:110])' "$j" | grep -n 'dd-init-upgrade\|Write\|Edit\|mv \|cp CLAUDE' | sed 's/^/  /'
  jq -r 'select(.type=="result") | "  result: \(.subtype) cost=\(.total_cost_usd) denials=\(.permission_denials|length)"' "$j"
  f="$d/CLAUDE.md"
  echo "  標記：$(grep -c 'dd-loop-version' "$f" 2>/dev/null) 行；rev13：$(grep -c 'dd-loop-rev: 13' "$f" 2>/dev/null)；佔位：$(grep -c '依偵測結果填入' "$f" 2>/dev/null)；React：$(grep -c 'React 專案' "$f" 2>/dev/null)；LOCAL：$(grep -o 'LOCAL[A-Z0-9]*' "$f" 2>/dev/null | sort | tr '\n' ' ')"
  echo "  步驟：$(grep -cE '^[0-9]+\. ' "$f" 2>/dev/null)；備份：$(find "$d" -maxdepth 1 -name 'CLAUDE.md.bak-*' | wc -l | tr -d ' ')；dd-upgrade 殘留：$(find "$d" -maxdepth 1 -name 'CLAUDE.md.dd-upgrade' | wc -l | tr -d ' ')；與原檔相同：$(cmp -s "$f" "$T/$c.orig" && echo 是 || echo 否)；git：$(git -C "$d" status --porcelain | tr '\n' ' ')"
done
