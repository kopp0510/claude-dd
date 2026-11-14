#!/bin/bash
# 從 real.jsonl 與稽核產物只抽判定欄位（不印 finding 內容）。用法：./check.sh <scratchpad>
set -u
S=${1:?scratchpad}; J=$S/runs/real.jsonl; O=$S/audit-out/run-1; SK=$S/sa-plugin/skills/security-audit
echo "## session"
jq -rs '
  ([.[]|select(.type=="result")]) as $rs
  | "results=\($rs|length)",
    ($rs[]|"  idx=\(.result_index // "-") subtype=\(.subtype) cost=\(.total_cost_usd) duration_ms=\(.duration_ms) api_ms=\(.duration_api_ms) turns=\(.num_turns) denials=\(.permission_denials|length) models=\(.modelUsage|keys|join(","))"),
    "agent_calls_by_type:",
    ([.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name=="Agent")|.input.subagent_type // "(none)"]|group_by(.)|map("  \(.[0])=\(length)")|.[]),
    "agent_calls_total=\([.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name=="Agent")]|length)",
    "skill_calls=\([.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name=="Skill")|.input.skill]|join(","))",
    "denials:",
    ([$rs[]|.permission_denials[]?|"  \(.tool_name) \(.tool_input.command // .tool_input.file_path // "" | tostring | .[0:140])"]|unique|.[])
' "$J" | sed "s|$S|\$S|g"
echo "## 產物"
for f in run-metadata.json architecture.md coverage-ledger.json findings.json REPORT.md FINDINGS-DETAIL.md NEEDS-VALIDATION.md; do
  if [ -f "$O/$f" ]; then echo "  $f bytes=$(wc -c < "$O/$f" | tr -d ' ')"; else echo "  $f MISSING"; fi
done
[ -f "$O/run-metadata.json" ] && jq -r '"run_status=\(.run_status) incomplete_reason=\(.incomplete_reason // "-") profile=\(.profile) budget=\(.budget|tostring)"' "$O/run-metadata.json"
[ -f "$O/findings.json" ] && jq -r 'if type=="array" then . else (.findings // []) end | group_by(.verdict) | map("  verdict \(.[0].verdict)=\(length)") | .[]' "$O/findings.json"
[ -f "$O/coverage-ledger.json" ] && jq -r 'group_by(.status)|map("  unit \(.[0].status)=\(length)")|.[]' "$O/coverage-ledger.json"
echo "## 自己重跑驗證器"
node "$SK/validate-findings.cjs" "$O/findings.json" > "$S/runs/vf.txt" 2>&1; echo "  validate-findings exit=$? first=$(head -1 "$S/runs/vf.txt")"
node "$SK/validate-coverage-ledger.cjs" "$O/coverage-ledger.json" > "$S/runs/vl.txt" 2>&1; echo "  validate-coverage-ledger exit=$? first=$(head -1 "$S/runs/vl.txt")"
echo "## 目標 repo 有沒有被改"
echo "  git_status_lines=$(git -C "$S/target/claude-dd" status --porcelain | wc -l | tr -d ' ') head=$(git -C "$S/target/claude-dd" rev-parse --short HEAD)"
