#!/bin/bash
# 只量不判：印出一個輸出目錄裡每一發的內容行數、字數、圍欄行數（算法與 check.sh 的長度斷言相同，沒有 P3 的扣除）。
# 保留題的輸出用這支看，check.sh 不讀它們。
# 用法：docs/measurements/2026-11-16-adhd-length/measure.sh <輸出目錄>
set -u
for f in "${1:?用法：measure.sh <輸出目錄>}"/*.jsonl; do
    [ -f "$f" ] || continue
    text=$(jq -r 'select(.kind=="result") | .result' "$f")
    cl=$(printf '%s\n' "$text" | awk '/^[[:space:]]*```/ { f = !f; next } f { next } /^[[:space:]]*$/ { next } /^[[:space:]]*#/ { next } { print }')
    fl=$(printf '%s\n' "$text" | awk '/^[[:space:]]*```/ { f = !f; next } f && !/^[[:space:]]*$/ { print }')
    n=$(printf '%s\n' "$cl" | awk 'NF { n++ } END { print n + 0 }')
    fn=$(printf '%s\n' "$fl" | awk 'NF { n++ } END { print n + 0 }')
    c=$(( $(printf '%s\n' "$cl" | jq -Rn '[inputs | length] | add // 0') + $(printf '%s\n' "$fl" | jq -Rn '[inputs | length] | add // 0') ))
    echo "$(basename "$f" .jsonl) 行 $n 字 $c 圍欄 $fn denials $(jq -r 'select(.kind=="result") | .permission_denials' "$f") outside $(jq -r 'select(.kind=="result") | .outside' "$f")"
done
