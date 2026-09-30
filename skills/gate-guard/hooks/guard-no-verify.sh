#!/bin/bash
# claude-dd gate-guard — PreToolUse(Bash) hook：擋 Claude 用 --no-verify／-n／core.hooksPath
# 繞過 CLAUDE.md pre-commit gate。
#
# 只擋「git commit」帶上繞過旗標；其他 git 指令（git config core.hooksPath …、git log -n 5）
# 和 commit 訊息內文剛好出現的 -n、--no-verify 字樣都放行。正式的逃生口是
# SKIP_DOC_CHECK=1（gate 會記帳，之後的正常 commit 要補），這支不管它。
#
# 輸入：Claude Code 從 stdin 傳入的 JSON，取 tool_input.command。讀 JSON 要 jq 或 python3，
# 兩者都沒有就放行（不擋、不報錯）。
# 輸出：命中時印 permissionDecision = deny 的 JSON；沒命中不輸出。一律 exit 0。
# 行為測試：同目錄 test-guard-no-verify.sh（CI 會跑）。
set -u

input=$(cat) || exit 0

if command -v jq >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command | if type == "string" then . else empty end' 2>/dev/null) || exit 0
elif command -v python3 >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    c = json.load(sys.stdin)["tool_input"]["command"]
except Exception:
    sys.exit(1)
if isinstance(c, str):
    sys.stdout.write(c)
' 2>/dev/null) || exit 0
else
    exit 0
fi
[ -z "$cmd" ] && exit 0

# 用簡化的 shell 斷詞找出「git commit + 繞過旗標」。只處理單雙引號、反斜線、# 註解與
# 分隔符號（; & | 換行 括號 反引號）；bash -c／sh -c／eval 的內容會再遞迴檢查一次。
# 命中時 exit 0（awk 的 exit 1 代表沒命中）。
printf '%s' "$cmd" | awk '
function tokenize(s, d,    n, i, L, c, cur, has, q) {
    n = 0; cur = ""; has = 0; q = ""; L = length(s)
    for (i = 1; i <= L; i++) {
        c = substr(s, i, 1)
        if (q == "\047") { if (c == "\047") q = ""; else cur = cur c; continue }
        if (q == "\"") {
            if (c == "\\" && i < L) { cur = cur substr(s, ++i, 1); continue }
            if (c == "\"") q = ""; else cur = cur c
            continue
        }
        if (c == "\047" || c == "\"") { q = c; has = 1; continue }
        if (c == "\\" && i < L) { cur = cur substr(s, ++i, 1); has = 1; continue }
        if (c == "#" && cur == "" && !has) { while (i < L && substr(s, i + 1, 1) != "\n") i++; continue }
        if (c == " " || c == "\t" || index(";&|()`\n", c)) {
            if (cur != "" || has) T[d, ++n] = cur
            cur = ""; has = 0
            if (c != " " && c != "\t") T[d, ++n] = SEP
            continue
        }
        cur = cur c
    }
    if (cur != "" || has) T[d, ++n] = cur
    N[d] = n
}

function hookspath(s) { return tolower(s) ~ /core\.hookspath/ }

# commit 的選項裡有沒有 --no-verify（含縮寫）或短選項 -n；會吃掉下一個 token 的選項要跳過它的參數
function commit_bypasses(d, i, n,    t, k, j, L, ch) {
    for (; i <= n && T[d, i] != SEP; i++) {
        t = T[d, i]
        if (t == "--") return 0
        if (t ~ /^--/) {
            k = t; sub(/=.*/, "", k)
            if (k ~ /^--no-veri/) return 1
            if (t !~ /=/ && k ~ /^--(message|file|author|date|template|reuse-message|reedit-message|fixup|squash|cleanup|trailer|pathspec-from-file)$/) i++
            continue
        }
        if (t ~ /^-[^-]/) {
            L = length(t)
            for (j = 2; j <= L; j++) {
                ch = substr(t, j, 1)
                if (ch == "n") return 1
                if (index("mFCct", ch)) { if (j == L) i++; break }
                if (index("Su", ch)) break
            }
        }
    }
    return 0
}

function bypasses(s, d,    n, i, j, w, hp, rest) {
    if (d > 3) return 0
    tokenize(s, d); n = N[d]; i = 1
    while (i <= n) {
        if (T[d, i] == SEP) { i++; continue }
        # 指令前面的環境變數設定與常見前綴
        hp = 0
        while (i <= n && T[d, i] != SEP && (T[d, i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || T[d, i] ~ /^(command|builtin|exec|env|sudo|nice|nohup|time)$/)) {
            if (T[d, i] ~ /^GIT_CONFIG/ && hookspath(T[d, i])) hp = 1
            i++
        }
        if (i > n || T[d, i] == SEP) continue
        w = T[d, i]; sub(/.*\//, "", w)
        if (w ~ /^(bash|sh|zsh|dash|ksh)$/) {
            for (j = i + 1; j < n && T[d, j] != SEP; j++)
                if (T[d, j] ~ /^-[A-Za-z]*c[A-Za-z]*$/) { if (bypasses(T[d, j + 1], d + 1)) return 1; break }
        } else if (w == "eval") {
            rest = ""
            for (j = i + 1; j <= n && T[d, j] != SEP; j++) rest = rest " " T[d, j]
            if (bypasses(rest, d + 1)) return 1
        } else if (w == "git") {
            # git 的全域選項：-c／--config-env 設 core.hooksPath 算繞過，-C 等要跳過參數
            for (i++; i <= n && T[d, i] != SEP && T[d, i] ~ /^-/; i++) {
                if (T[d, i] == "-c" || T[d, i] == "--config-env") { i++; if (hookspath(T[d, i])) hp = 1 }
                else if (T[d, i] ~ /^--config-env=/ && hookspath(T[d, i])) hp = 1
                else if (T[d, i] == "-C" || T[d, i] ~ /^--(git-dir|work-tree|namespace|exec-path)$/) i++
            }
            if (i <= n && T[d, i] == "commit" && (hp || commit_bypasses(d, i + 1, n))) return 1
        }
        while (i <= n && T[d, i] != SEP) i++
    }
    return 0
}

BEGIN { SEP = "\001" }
{ buf = (NR == 1) ? $0 : buf "\n" $0 }
END { exit bypasses(buf, 0) ? 0 : 1 }
' || exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"claude-dd gate-guard：git commit 不可用 --no-verify／-n／core.hooksPath 繞過 CLAUDE.md gate。被 gate 擋下時照它的訊息補上該目錄的 CLAUDE.md；只是檢查點 commit 就改用 SKIP_DOC_CHECK=1 git commit …（gate 會記帳，之後的正常 commit 要補上）。"}}
JSON
exit 0
