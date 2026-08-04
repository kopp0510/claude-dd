#!/bin/bash
# Self-Improving Agent — Error Capture Hook
# Fires on PostToolUse (Bash) to detect command failures.
# Zero output on success — only captures when errors are detected.
#
# Interface: Claude Code passes hook input as JSON on stdin (tool_name /
# tool_input / tool_response). Detected errors are returned as
# hookSpecificOutput.additionalContext JSON so the reminder reaches Claude.
#
# Install: Add to .claude/settings.json:
# {
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Bash",
#       "hooks": [{
#         "type": "command",
#         "command": "$HOME/.claude/skills/self-improving-agent/hooks/error-capture.sh"
#       }]
#     }]
#   }
# }

set -eu

INPUT=$(cat) || exit 0
[ -z "$INPUT" ] && exit 0

# Extract tool_response from stdin JSON (needs jq or python3; exit silently otherwise)
if command -v jq >/dev/null 2>&1; then
    OUTPUT=$(printf '%s' "$INPUT" | jq -r '.tool_response | if type == "object" then ((.stdout // "") + "\n" + (.stderr // "")) else tostring end' 2>/dev/null) || exit 0
elif command -v python3 >/dev/null 2>&1; then
    OUTPUT=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
resp = data.get("tool_response", "")
if isinstance(resp, dict):
    resp = str(resp.get("stdout", "")) + "\n" + str(resp.get("stderr", ""))
elif not isinstance(resp, str):
    resp = json.dumps(resp)
print(resp)
' 2>/dev/null) || exit 0
else
    exit 0
fi

# Exit silently if no output or empty
[ -z "${OUTPUT//[[:space:]]/}" ] && exit 0

# Error patterns — ordered by specificity
ERROR_PATTERNS=(
    "error:"
    "Error:"
    "ERROR:"
    "FATAL:"
    "fatal:"
    "FAILED"
    "failed"
    "command not found"
    "No such file or directory"
    "Permission denied"
    "Module not found"
    "ModuleNotFoundError"
    "ImportError"
    "SyntaxError"
    "TypeError"
    "ReferenceError"
    "Cannot find module"
    "ENOENT"
    "EACCES"
    "ECONNREFUSED"
    "ETIMEDOUT"
    "npm ERR!"
    "pnpm ERR!"
    "Traceback (most recent call last)"
    "panic:"
    "segmentation fault"
    "core dumped"
    "exit code"
    "non-zero exit"
    "Build failed"
    "Compilation failed"
    "Test failed"
)

# False positive exclusions — don't trigger on these
EXCLUSIONS=(
    "error-capture"       # Don't trigger on ourselves
    "error_handler"       # Code that handles errors
    "errorHandler"
    "error.log"           # Log file references
    "console.error"       # Code that logs errors
    "catch (error"        # Error handling code
    "catch (err"
    ".error("             # Logger calls
    "no error"            # Absence of error
    "without error"
    "error-free"
)

# Check exclusions first
for excl in "${EXCLUSIONS[@]}"; do
    if [[ "$OUTPUT" == *"$excl"* ]]; then
        exit 0
    fi
done

# Check for error patterns
contains_error=false
matched_pattern=""
for pattern in "${ERROR_PATTERNS[@]}"; do
    if [[ "$OUTPUT" == *"$pattern"* ]]; then
        contains_error=true
        matched_pattern="$pattern"
        break
    fi
done

# Exit silently if no error
[ "$contains_error" = false ] && exit 0

# Extract relevant error context (fixed-string match; no hit is not an error)
error_context=$(printf '%s\n' "$OUTPUT" | grep -iF -m 5 -- "$matched_pattern" | head -5) || true
context_snippet=$(printf '%s\n' "$error_context" | head -2 | tr '\n' ' ' | cut -c1-200)

# Return a concise reminder via additionalContext — ~40 tokens
MSG="<error-detected>
Command error detected (pattern: \"$matched_pattern\").
If this was unexpected or required investigation to fix, save the solution:
  /self-improving-agent:remember \"explanation of what went wrong and the fix\"
Or if this is a known pattern, check: /self-improving-agent:review
Context: $context_snippet
</error-detected>"

if command -v jq >/dev/null 2>&1; then
    jq -n --arg ctx "$MSG" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
else
    MSG="$MSG" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": os.environ["MSG"]}}))
'
fi
exit 0
