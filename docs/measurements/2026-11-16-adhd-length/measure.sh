#!/bin/bash
# 只量不判：印出一個輸出目錄裡每一發的內容行數、字數、圍欄行數（算法與 check.sh 的長度斷言相同，沒有 P3 的扣除）。
# 保留題的輸出用這支看，check.sh 不讀它們。
# 用法：docs/measurements/2026-11-16-adhd-length/measure.sh <輸出目錄>
set -u
count_lines() { printf '%s\n' "$1" | awk 'NF { n++ } END { print n + 0 }'; }
count_chars() { printf '%s\n' "$1" | jq -Rn '[inputs | length] | add // 0'; }
result_field() { jq -r "select(.kind==\"result\") | .$2" "$1"; } # 檔案 欄位
for f in "${1:?用法：measure.sh <輸出目錄>}"/*.jsonl; do
    [ -f "$f" ] || continue
    text=$(result_field "$f" result)
    # 圍欄外：去掉空行與 # 標題；圍欄內：只去掉空行
    cl=$(printf '%s\n' "$text" | awk '/^[[:space:]]*```/ { f = !f; next } f { next } /^[[:space:]]*$/ { next } /^[[:space:]]*#/ { next } { print }')
    fl=$(printf '%s\n' "$text" | awk '/^[[:space:]]*```/ { f = !f; next } f && !/^[[:space:]]*$/ { print }')
    c=$(( $(count_chars "$cl") + $(count_chars "$fl") ))
    echo "$(basename "$f" .jsonl) 行 $(count_lines "$cl") 字 $c 圍欄 $(count_lines "$fl") denials $(result_field "$f" permission_denials) outside $(result_field "$f" outside)"
done
