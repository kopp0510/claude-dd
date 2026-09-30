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
    # 用 buffer 寫出 UTF-8，不受 PYTHONIOENCODING 影響；非法字元換成替代字元，跟 jq 的輸出對齊
    cmd=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    c = json.load(sys.stdin)["tool_input"]["command"]
except Exception:
    sys.exit(1)
if isinstance(c, str):
    sys.stdout.buffer.write(c.encode("utf-8", "replace"))
' 2>/dev/null) || exit 0
else
    exit 0
fi
[ -z "$cmd" ] && exit 0

# 用簡化的 shell 斷詞找出「git commit + 繞過旗標」。處理單雙引號、反斜線、# 註解、heredoc、
# 分隔符號（; & | 換行 括號 反引號；2>&1 這類重導向裡的 & 不算）。以下內容會再遞迴檢查，最多巢狀 3 層：
# bash -c／sh -c 的參數、交給 shell 的 heredoc 內文、eval 的參數、雙引號裡的 $(…) 與 `…`、
# git -c alias.X=… 定義的別名。命中時 exit 0（awk 的 exit 1 代表沒命中）。
printf '%s' "$cmd" | awk '
# 切 token 存進 T[d, 1..n]，回傳 n。分隔符號變成 SEP；heredoc 內文收成一個 BODY 開頭的 token；
# 雙引號裡 $(…)／`…` 的內容另外放進 SUB[d, 1..NS[d]]，給呼叫端遞迴檢查
function tokenize(s, d,    n, i, L, c, cur, has, q, hd, hdash, e, ln, line, body, depth, k) {
    n = 0; NS[d] = 0; cur = ""; has = 0; q = ""; hd = ""; L = length(s)
    for (i = 1; i <= L; i++) {
        c = substr(s, i, 1)
        if (q == "\047") { if (c == "\047") q = ""; else cur = cur c; continue }
        if (q == "\"") {
            if (c == "\\" && i < L) { cur = cur substr(s, ++i, 1); continue }
            if (c == "$" && substr(s, i + 1, 1) == "(") {
                # 找對應的右括號（只算括號深度，不管裡面的引號），跳過整段、內容留給遞迴檢查
                depth = 0
                for (e = i + 1; e <= L; e++) {
                    k = substr(s, e, 1)
                    if (k == "(") depth++
                    else if (k == ")" && --depth == 0) break
                }
                SUB[d, ++NS[d]] = substr(s, i + 2, e - i - 2)
                cur = cur substr(s, i, e - i + 1); i = e
                continue
            }
            if (c == "`" && (e = index(substr(s, i + 1), "`"))) {
                SUB[d, ++NS[d]] = substr(s, i + 1, e - 1)
                cur = cur substr(s, i, e + 1); i += e
                continue
            }
            if (c == "\"") q = ""; else cur = cur c
            continue
        }
        if (c == "\047" || c == "\"") { q = c; has = 1; continue }
        if (c == "\\" && i < L) { cur = cur substr(s, ++i, 1); has = 1; continue }
        if (c == "#" && cur == "" && !has) { while (i < L && substr(s, i + 1, 1) != "\n") i++; continue }
        if (c == "<" && substr(s, i + 1, 1) == "<" && substr(s, i + 2, 1) != "<") {
            # heredoc：記下分隔字（去掉引號與反斜線），內文從下一個換行開始
            if (cur != "" || has) T[d, ++n] = cur
            cur = ""; has = 0; hd = ""; hdash = 0
            i += 2
            if (substr(s, i, 1) == "-") { hdash = 1; i++ }
            while (i <= L && index(" \t", substr(s, i, 1))) i++
            for (; i <= L && !index(" \t\n;&|()<>", k = substr(s, i, 1)); i++)
                if (!index("\047\"\\", k)) hd = hd k
            i--
            continue
        }
        if (c == "\n" && hd != "") {
            # 收 heredoc 內文到分隔字那一行為止（<<- 允許前導 tab）；沒有分隔字就收到結尾
            if (cur != "" || has) T[d, ++n] = cur
            cur = ""; has = 0; body = ""; ln = L + 1
            for (e = i + 1; e <= L; e = ln + 1) {
                ln = index(substr(s, e), "\n"); ln = ln ? e + ln - 1 : L + 1
                line = substr(s, e, ln - e)
                if (hdash) sub(/^\t+/, "", line)
                if (line == hd) break
                body = body line "\n"
            }
            T[d, ++n] = BODY body
            T[d, ++n] = SEP
            hd = ""
            i = (e <= L) ? ln - 1 : L
            continue
        }
        if (c == "&" && ((i > 1 && index("<>", substr(s, i - 1, 1))) || substr(s, i + 1, 1) == ">")) { cur = cur c; continue }
        if (c == " " || c == "\t" || index(";&|()`\n", c)) {
            if (cur != "" || has) T[d, ++n] = cur
            cur = ""; has = 0
            if (c != " " && c != "\t") T[d, ++n] = SEP
            continue
        }
        cur = cur c
    }
    if (cur != "" || has) T[d, ++n] = cur
    return n
}

function hookspath(s) { return tolower(s) ~ /core\.hookspath/ }
function base(w) { sub(/.*\//, "", w); return w }
# 下一個 token 是同一段指令裡的參數（不是 SEP）才跳過它，免得連分號一起吃掉、漏看下一段指令
function arg_next(d, i, n) { return (i < n && T[d, i + 1] != SEP) ? i + 1 : i }

# git -c alias.X=… 的內容：一般別名接在 git 後面檢查，! 開頭的 shell 別名直接檢查
function alias_bypasses(kv, d,    v) {
    if (tolower(kv) !~ /^alias\.[^=]*=/) return 0
    v = kv; sub(/^[^=]*=/, "", v)
    return (substr(v, 1, 1) == "!") ? bypasses(substr(v, 2), d + 1) : bypasses("git " v, d + 1)
}

# commit 的選項裡有沒有 --no-verify（含縮寫）或短選項 -n；會吃掉下一個 token 的選項要跳過它的參數
function commit_bypasses(d, i, n,    t, j, L, ch) {
    for (; i <= n && T[d, i] != SEP; i++) {
        t = T[d, i]
        if (t == "--") return 0
        if (t ~ /^--/) {
            if (t ~ /^--no-veri/) return 1
            if (t ~ /^--(message|file|author|date|template|reuse-message|reedit-message|fixup|squash|cleanup|trailer|pathspec-from-file)$/) i = arg_next(d, i, n)
            continue
        }
        if (t ~ /^-[^-]/) {
            L = length(t)
            for (j = 2; j <= L; j++) {
                ch = substr(t, j, 1)
                if (ch == "n") return 1
                if (index("mFCct", ch)) { if (j == L) i = arg_next(d, i, n); break }
                if (index("Su", ch)) break
            }
        }
    }
    return 0
}

function bypasses(s, d,    n, i, j, t, w, hp) {
    if (d > 3) return 0
    n = tokenize(s, d)
    for (j = 1; j <= NS[d]; j++) if (bypasses(SUB[d, j], d + 1)) return 1
    i = 1
    while (i <= n) {
        if (T[d, i] == SEP) { i++; continue }
        # 指令前面的環境變數設定、保留字（if then do { ! …）與重導向
        hp = 0
        while (i <= n && T[d, i] != SEP) {
            t = T[d, i]
            if (t ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { if (t ~ /^GIT_CONFIG/ && hookspath(t)) hp = 1 }
            else if (t ~ /^[0-9&]*[<>]/) { if (t ~ /^[0-9&]*[<>]+&?$/) i = arg_next(d, i, n) }
            else if (t !~ /^(if|then|else|elif|do|while|until|!|\{)$/) break
            i++
        }
        if (i > n || T[d, i] == SEP) continue
        w = base(T[d, i])
        # nice -n 5、timeout 60、sudo -u me 這類包一層的指令：往後找同一段裡的 git
        if (w ~ /^(command|builtin|exec|env|sudo|doas|nice|nohup|time|timeout|xargs|stdbuf|ionice)$/) {
            for (j = i + 1; j <= n && T[d, j] != SEP && base(T[d, j]) != "git"; j++)
                if (T[d, j] ~ /^GIT_CONFIG/ && hookspath(T[d, j])) hp = 1
            i = j
            if (i > n || T[d, i] == SEP) continue
            w = "git"
        }
        if (w ~ /^(bash|sh|zsh|dash|ksh)$/) {
            for (j = i + 1; j <= n && T[d, j] != SEP; j++) {
                if (substr(T[d, j], 1, 1) == BODY) { if (bypasses(substr(T[d, j], 2), d + 1)) return 1 }
                else if (T[d, j] ~ /^-[A-Za-z]*c[A-Za-z]*$/ && arg_next(d, j, n) > j) { j++; if (bypasses(T[d, j], d + 1)) return 1 }
            }
        } else if (w == "eval") {
            t = ""
            for (j = i + 1; j <= n && T[d, j] != SEP; j++) t = t " " T[d, j]
            if (bypasses(t, d + 1)) return 1
        } else if (w == "git") {
            # git 的全域選項：-c／--config-env 設 core.hooksPath 算繞過，-c alias.X=… 要檢查別名內容，
            # -C 等要跳過參數
            for (i++; i <= n && T[d, i] != SEP && T[d, i] ~ /^-/; i++) {
                t = T[d, i]
                if (t == "-c" || t == "--config-env") {
                    i = arg_next(d, i, n)
                    if (hookspath(T[d, i])) hp = 1
                    if (alias_bypasses(T[d, i], d)) return 1
                } else if (t ~ /^--config-env=/ && hookspath(t)) hp = 1
                else if (t == "-C" || t ~ /^--(git-dir|work-tree|namespace|exec-path|attr-source)$/) i = arg_next(d, i, n)
            }
            if (i <= n && T[d, i] == "commit" && (hp || commit_bypasses(d, i + 1, n))) return 1
        }
        while (i <= n && T[d, i] != SEP) i++
    }
    return 0
}

BEGIN { SEP = "\001"; BODY = "\002" }
{ buf = (NR == 1) ? $0 : buf "\n" $0 }
END { exit bypasses(buf, 0) ? 0 : 1 }
' || exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"claude-dd gate-guard：git commit 不可用 --no-verify／-n／core.hooksPath 跳過 hook。被 CLAUDE.md gate 擋下時照它的訊息補上該目錄的 CLAUDE.md；只是檢查點 commit 就改用 SKIP_DOC_CHECK=1 git commit …（gate 會記帳，之後的正常 commit 要補上）。使用者明確要求跳過 hook 時，請使用者自己在終端機執行。"}}
JSON
exit 0
