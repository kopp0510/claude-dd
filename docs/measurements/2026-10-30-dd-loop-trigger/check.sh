#!/bin/bash
# 只抽判定欄位，每份 jsonl 一列：
#   skills       Skill 呼叫順序；dd-loop 有沒有在裡面
#   first_tool   第一個 tool_use 的工具名
#   denied_skill permission_denials 裡 Skill 的筆數；denials_total 全部筆數
#   inject_chars dd-loop 本文注入的字元數（Skill 的 tool_result 只有 "Launching skill: dd-loop"，
#                本文在下一則 user 訊息，以 "Base directory for this skill:" 開頭）
#   result       沒有 result 那一行（session 中途死掉、被截斷）時印 MISSING，其餘欄位不可信
set -eu
for f in "${1:?out 目錄}"/*.jsonl; do
  jq -rs --arg n "$(basename "$f" .jsonl)" '
    ([.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use")]) as $tu
    | ([$tu[]|select(.name=="Skill")|.input.skill]) as $sk
    | ([.[]|select(.type=="result")][0]) as $r
    | ([.[]|select(.type=="user")|.message.content|if type=="string" then . else map(.text // "")|join("") end
        |select(startswith("Base directory for this skill:") and test("/dd-loop"))|length]|add // 0) as $inj
    | "\($n)\tresult=\(if $r==null then "MISSING" else "ok" end)\tskills=\($sk|join(","))\tdd-loop=\(($sk|index("dd-loop"))!=null)\tfirst_tool=\($tu[0].name // "")\tdenied_skill=\([($r.permission_denials // [])[]|select(.tool_name=="Skill")]|length)\tdenials_total=\(($r.permission_denials // [])|length)\tinject_chars=\($inj)\tcost=\($r.total_cost_usd)"' "$f"
done
