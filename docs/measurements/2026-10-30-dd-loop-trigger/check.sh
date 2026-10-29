#!/bin/bash
# 只抽判定欄位：每份 jsonl 的 Skill 呼叫順序、有沒有 dd-loop、permission_denials 裡有沒有 Skill、dd-loop 注入長度、費用
set -eu
for f in "${1:?out 目錄}"/*.jsonl; do
  jq -rs --arg n "$(basename "$f" .jsonl)" '
    ([.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name=="Skill")|.input.skill]) as $sk
    | ([.[]|select(.type=="result")][0]) as $r
    | ([.[]|select(.type=="user")|.message.content[]?|select(.type=="tool_result")|(.content|tostring)|select(test("dd-loop"))|length]|add // 0) as $inj
    | "\($n)\tskills=\($sk|join(","))\tdd-loop=\(($sk|index("dd-loop"))!=null)\tdenied_skill=\([($r.permission_denials // [])[]|select(.tool_name=="Skill")]|length)\tinject_chars=\($inj)\tcost=\($r.total_cost_usd)"' "$f"
done
