#!/bin/bash
# Self-Improving Agent — Error Capture Hook
# Fires on PostToolUse (Bash) to detect command failures.
# Zero output unless an error PATTERN matches the command's output text.
# It is NOT exit-status based: Claude Code's tool_response carries only
# stdout / stderr / interrupted / isImage / noOutputExpected — there is no exit
# code field to read — so a command that succeeded but printed "failed" or
# "error:" still fires. Matching is per line (see EXCLUSIONS below).
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

# JSON parsing/emitting needs jq or python3 — pick one up front, exit silently if neither
if command -v jq >/dev/null 2>&1; then
    JSON_TOOL=jq
elif command -v python3 >/dev/null 2>&1; then
    JSON_TOOL=python3
else
    exit 0
fi

# Extract tool_response from stdin JSON
if [ "$JSON_TOOL" = jq ]; then
    OUTPUT=$(printf '%s' "$INPUT" | jq -r '.tool_response | if type == "object" then ((.stdout // "") + "\n" + (.stderr // "")) else tostring end' 2>/dev/null) || exit 0
else
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
fi

# Exit silently if the response is empty or whitespace-only
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

# Match LINE BY LINE: a line only counts as an error if that same line is not itself an
# excluded false positive. Exclusions used to be tested against the WHOLE output, which made
# them a one-vote veto — a single incidental "console.error" anywhere silenced every real
# error beside it. Two real cases that used to exit 0 in total silence:
#   src/a.ts:3 console.error(e) / Build failed with 1 error   (any TS build failure with source context)
#   web: compiled with no errors / api: Build failed with 3 errors   ("no error" is a substring of "no errors")
contains_error=false
matched_pattern=""
matched_line=""
while IFS= read -r line; do
    excluded=false
    for excl in "${EXCLUSIONS[@]}"; do
        if [[ "$line" == *"$excl"* ]]; then
            excluded=true
            break
        fi
    done
    if [ "$excluded" = true ]; then
        continue
    fi
    for pattern in "${ERROR_PATTERNS[@]}"; do
        if [[ "$line" == *"$pattern"* ]]; then
            contains_error=true
            matched_pattern="$pattern"
            matched_line="$line"
            break
        fi
    done
    if [ "$contains_error" = true ]; then
        break
    fi
done <<< "$OUTPUT"

# Exit silently if no error
[ "$contains_error" = false ] && exit 0

# The matching line itself is the context (already excluded-checked)
context_snippet=$(printf '%s' "$matched_line" | cut -c1-200)

# Return a concise reminder via additionalContext — ~40 tokens
MSG="<error-detected>
Command error detected (pattern: \"$matched_pattern\").
If this was unexpected or required investigation to fix, save the solution:
  /self-improving-agent:remember \"explanation of what went wrong and the fix\"
Or if this is a known pattern, check: /self-improving-agent:review
Context: $context_snippet
</error-detected>"

if [ "$JSON_TOOL" = jq ]; then
    jq -n --arg ctx "$MSG" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
else
    MSG="$MSG" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": os.environ["MSG"]}}))
'
fi
exit 0
