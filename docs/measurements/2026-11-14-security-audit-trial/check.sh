#!/bin/bash
# 從 real.jsonl 與稽核產物只抽判定欄位（不印 finding 內容）。用法：./check.sh <scratchpad>
set -u
S=${1:?scratchpad}
JSONL=$S/runs/real.jsonl
RUN_DIR=$S/audit-out/run-1
SKILL_DIR=$S/sa-plugin/skills/security-audit
echo "## session"
jq -rs '
  def tool_uses($name): .[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name==$name);
  ([.[]|select(.type=="result")]) as $rs
  | "results=\($rs|length)",
    ($rs[]|"  idx=\(.result_index // "-") subtype=\(.subtype) cost=\(.total_cost_usd) duration_ms=\(.duration_ms) api_ms=\(.duration_api_ms) turns=\(.num_turns) denials=\(.permission_denials|length) models=\(.modelUsage|keys|join(","))"),
    "agent_calls_by_type:",
    ([tool_uses("Agent")|.input.subagent_type // "(none)"]|group_by(.)|map("  \(.[0])=\(length)")|.[]),
    "agent_calls_total=\([tool_uses("Agent")]|length)",
    "skill_calls=\([tool_uses("Skill")|.input.skill]|join(","))",
    "denials:",
    ([$rs[]|.permission_denials[]?|"  \(.tool_name) \(.tool_input.command // .tool_input.file_path // "" | tostring | .[0:140])"]|unique|.[])
' "$JSONL" | sed "s|$S|\$S|g"
echo "## 產物"
for f in run-metadata.json architecture.md coverage-ledger.json findings.json REPORT.md FINDINGS-DETAIL.md NEEDS-VALIDATION.md; do
  if [ -f "$RUN_DIR/$f" ]; then echo "  $f bytes=$(wc -c < "$RUN_DIR/$f" | tr -d ' ')"; else echo "  $f MISSING"; fi
done
[ -f "$RUN_DIR/run-metadata.json" ] && jq -r '"run_status=\(.run_status) incomplete_reason=\(.incomplete_reason // "-") profile=\(.profile) budget=\(.budget|tostring)"' "$RUN_DIR/run-metadata.json"
[ -f "$RUN_DIR/findings.json" ] && jq -r 'if type=="array" then . else (.findings // []) end | group_by(.verdict) | map("  verdict \(.[0].verdict)=\(length)") | .[]' "$RUN_DIR/findings.json"
[ -f "$RUN_DIR/coverage-ledger.json" ] && jq -r 'group_by(.status)|map("  unit \(.[0].status)=\(length)")|.[]' "$RUN_DIR/coverage-ledger.json"
echo "## 自己重跑驗證器"
# echo 的 $? 是緊鄰上一行 node 的結束碼，兩行之間不可插入其他指令
node "$SKILL_DIR/validate-findings.cjs" "$RUN_DIR/findings.json" > "$S/runs/vf.txt" 2>&1
echo "  validate-findings exit=$? first=$(head -1 "$S/runs/vf.txt")"
node "$SKILL_DIR/validate-coverage-ledger.cjs" "$RUN_DIR/coverage-ledger.json" > "$S/runs/vl.txt" 2>&1
echo "  validate-coverage-ledger exit=$? first=$(head -1 "$S/runs/vl.txt")"
echo "## 目標 repo 有沒有被改"
# --ignored：被 .gitignore 忽略的路徑（例如 .claude/）也算
echo "  git_status_lines=$(git -C "$S/target/claude-dd" status --porcelain --ignored | wc -l | tr -d ' ') head=$(git -C "$S/target/claude-dd" rev-parse --short HEAD)"
echo
echo "## 探針"
# probe1 的 jsonl 是跑完 probe1 後從 probe.jsonl 改名來的；probe2 留在 probe.jsonl
for pair in probe1:probe1 probe2:probe; do
  label=${pair%%:*}; file=$S/runs/${pair#*:}.jsonl
  if [ -f "$file" ]; then
    jq -rs --arg n "$label" '.[]|select(.type=="result")|"  \($n) idx=\(.result_index // "-") cost=\(.total_cost_usd) denials=\(.permission_denials|length) models=\(.modelUsage|keys|join(","))"' "$file"
  else echo "  $label MISSING"; fi
done
echo "## 各模型花費（real）"
jq -rs '[.[]|select(.type=="result")][0].modelUsage|to_entries[]|"  \(.key) cost=\(.value.costUSD)"' "$JSONL"
