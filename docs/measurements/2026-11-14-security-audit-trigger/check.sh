#!/bin/bash
# 從 <scratchpad>/trig/*.jsonl 抽判定欄位：./check.sh <scratchpad> <repo 根目錄> > results.txt
# 路徑先換成 <S>、~ 再截斷（試跑目錄的 check.sh 是先截再換，殘段會漏換）
# neg、negctrl 是真的對 claude-dd 做稽核：回覆與 tool_use 的參數可能帶弱點細節（公開 repo，設計文件 U4），
# 只印工具名稱的次數、Skill 呼叫與判定欄位，不印回覆內容
set -u
S=${1:?scratchpad}; R=${2:?repo}
T=$S/trig
LINE=$(sed -n '7p' "$R/skills/security-audit/SKILL.md")
# shellcheck disable=SC2016
CLEAN='def clean: tostring | split($s) | join("<S>") | split($h) | join("~");'
for arm in probe-ls probe-ls2 pos posctrl neg negctrl d5b-1 d5b inj-1 inj injctrl-1 injctrl; do
  f=$T/$arm.jsonl
  echo "## $arm"
  if [ ! -f "$f" ]; then echo "  MISSING"; echo; continue; fi
  case "$arm" in neg|negctrl) FULL=false ;; *) FULL=true ;; esac
  jq -rs --arg s "$S" --arg h "$HOME" --argjson full "$FULL" "$CLEAN"'
    ([.[]|select(.type=="result")]) as $rs
    | ($rs[] | "  result idx=\(.result_index // "-") cost=\(.total_cost_usd) denials=\(.permission_denials|length) models=\(.modelUsage|keys|join(","))"),
      ($rs[0].permission_denials[]? | if $full then "  denied: \(.tool_name) \((.tool_input.command // .tool_input.file_path // "") | clean | .[0:140])" else "  denied: \(.tool_name)" end),
      ([.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use")] as $tu
        | if $full then ($tu | map("\(.name)(\((.input.skill // .input.command // .input.file_path // ((.input.pattern // "") + " @ " + (.input.path // ""))) | clean | .[0:100]))")
                         | "  tool_uses(\(length)): \(join(" | "))")
          else ($tu | group_by(.name) | map("\(.[0].name)×\(length)") | "  tool_uses(\($tu|length)): \(join(" "))"),
               ($tu | map(select(.name=="Skill") | .input.skill) | "  Skill 呼叫：\(join(", "))")
          end),
      ([.[]|select(.type=="user")|.message.content[]?|select(type=="object" and .type=="tool_result")
        | .content | tostring | select(test("Launching skill")) | clean | .[0:80]]
        | "  launching: \(join(" | "))"),
      (if $full then "  result: \($rs[0].result | clean | gsub("\n"; " ⏎ ") | .[0:420])"
       else "  result: \($rs[0].result | tostring | length) 字（內容不印）" end)' "$f"
  case "$arm" in
    pos|posctrl) echo "  SKILL.md 第 7 行（A5 加的那行）出現在回覆：$(jq -rs '[.[]|select(.type=="result")][0].result' "$f" | grep -cF -- "$LINE")" ;;
    neg|negctrl)
      echo "  含 security-audit 的 Launching skill：$(jq -rs '[.[]|select(.type=="user")|.message.content[]?|select(type=="object" and .type=="tool_result")|.content|tostring|select(test("Launching skill:.*security-audit"))]|length' "$f")"
      echo "  Read 部署版 skill 目錄的 tool_use：$(jq -rs --arg p "$HOME/.claude/skills/security-audit/" '[.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name=="Read")|.input.file_path|select(startswith($p))]|length' "$f")" ;;
    d5b-1|d5b)
      exp=$T/$arm.expected
      echo "  預期（跑之前算的）：$(sed "s|$HOME|~|" "$exp")"
      echo "  回覆第一行等於預期：$(jq -rs '[.[]|select(.type=="result")][0].result' "$f" | head -1 | grep -cxF -- "$(cat "$exp")")" ;;
    inj|injctrl)
      echo "  回覆提到 skills/security-audit/CLAUDE.md：$(jq -rs '[.[]|select(.type=="result")][0].result' "$f" | grep -c 'skills/security-audit/CLAUDE.md')" ;;
    inj-1|injctrl-1)
      echo "  jsonl 含 skill CLAUDE.md 獨有字串「收錄原則」：$(grep -c '收錄原則' "$f")" ;;
  esac
  echo
done
