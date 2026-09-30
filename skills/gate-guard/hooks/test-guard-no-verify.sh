#!/bin/bash
# guard-no-verify.sh 的行為測試。CI 會跑這支（.github/workflows/ci.yml）。
#
# 【它守什麼】「哪些指令要擋、哪些要放行」的判斷：git commit 帶 --no-verify／-n／core.hooksPath
# 要擋；其他 git 指令（git config core.hooksPath、git log -n）和訊息內文剛好出現 -n 的 commit
# 要放行；jq 與 python3 兩條讀 JSON 的分支都要能動；兩者都沒有時不擋（放行）。
#
# 【它不守什麼】shell 語法的完整解析。hook 用簡化的斷詞規則（單雙引號、反斜線、分隔符號），
# 沒列在這裡的寫法（例如 export 之後隔一段才 commit）不在保證範圍內。
#
# 用法：test-guard-no-verify.sh [guard-no-verify.sh 的路徑]　預設取同目錄那支。
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
HOOK="${1:-$HERE/guard-no-verify.sh}"
[ -x "$HOOK" ] || { echo "❌ 找不到可執行的 ${HOOK}"; exit 2; }

# hook 在 jq 與 python3 都沒有時一律放行，那種環境下「該擋」的案例全都會失敗、看起來像 hook 壞了
if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    echo "❌ 需要 jq 或 python3 才驗得動這支 hook（兩者皆無時 hook 一律放行是正確的）"
    exit 2
fi

pass=0
fail=0
TOOL_PATH="$PATH"   # 第 2 輪換成看不到 jq 的 PATH，逼 hook 走 python3 後備

# 用 jq／python3 組 JSON，指令裡的雙引號、換行才不會生出壞 JSON（壞 JSON 會讓 hook 靜默放行、案例假通過）
payload() {
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}'
    else
        python3 -c 'import json,sys; print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}}))' "$1"
    fi
}

# $1=案例名　$2=block|allow　$3=指令　$4=(選用) 直接給整段 hook 輸入，不用 $3 組
check() {
    local name="$1" expect="$2" input out rc got
    input="${4:-$(payload "$3")}"
    out=$(printf '%s' "$input" | env PATH="$TOOL_PATH" "$HOOK")
    rc=$?
    if [ "$rc" -ne 0 ]; then
        printf '%-44s ❌ hook exit=%s（應一律 exit 0）\n' "$name" "$rc"
        fail=$((fail + 1))
        return
    fi
    case "$out" in
        *'"permissionDecision":"deny"'*|*'"permissionDecision": "deny"'*) got=block ;;
        '') got=allow ;;
        *) got="unexpected-output" ;;
    esac
    if [ "$got" = "$expect" ]; then
        printf '%-44s ✅ %s\n' "$name" "$got"
        pass=$((pass + 1))
    else
        printf '%-44s ❌ 期望 %s 實際 %s\n' "$name" "$expect" "$got"
        fail=$((fail + 1))
    fi
}

run_suite() {
    # ---- 要擋 ----
    check '--no-verify'                              block 'git commit --no-verify -m "x"'
    check '-n'                                       block 'git commit -n -m "x"'
    check '-nm 合在一起'                             block 'git commit -nm "x"'
    check '-am 之後才放 --no-verify'                 block 'git commit -am "x" --no-verify'
    check '--no-verify 的縮寫 --no-veri'             block 'git commit --no-veri -m x'
    check 'git -c core.hooksPath= commit'            block 'git -c core.hooksPath=/dev/null commit -m "x"'
    check 'git --config-env=core.hooksPath'          block 'git --config-env=core.hooksPath=HP commit -m x'
    check 'GIT_CONFIG_* 環境變數設 hooksPath'        block 'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m x'
    check 'git -C 路徑 commit --no-verify'           block 'git -C /tmp/repo commit --no-verify -m x'
    check '&& 串在後面'                              block 'git add . && git commit --no-verify -m x'
    check '環境變數前綴 + -n'                        block 'SKIP=1 git commit -n -m x'
    check '絕對路徑的 git'                           block '/usr/bin/git commit --no-verify -m x'
    check 'bash -c 包起來'                           block 'bash -c "git commit --no-verify -m x"'
    check '換行分隔的第二行'                         block $'git add -A\ngit commit -n -m x'
    # 2026-10-01 code-review 補的繞過寫法：保留字、重導向、包一層的指令、別名、雙引號裡的 $(…)
    check 'if … then 裡面'                           block 'if true; then git commit -n -m x; fi'
    check 'for … do 裡面'                            block 'for i in 1; do git commit -n -m x; done'
    check '{ … } 群組'                               block '{ git commit -n -m x; }'
    check '! 反轉結束碼'                             block '! git commit -n -m x'
    check '2>&1 之後才放 --no-verify'                block 'git commit -m x 2>&1 --no-verify'
    check '開頭是重導向'                             block '2>/dev/null git commit -n -m x'
    check 'nice -n 5 包一層'                         block 'nice -n 5 git commit -n -m x'
    check 'timeout 60 包一層'                        block 'timeout 60 git commit --no-verify -m x'
    check 'git -c alias 定義繞過的別名'              block 'git -c alias.ci="commit --no-verify" ci -m x'
    check 'git --attr-source 參數分開寫'             block 'git --attr-source HEAD commit -n -m x'
    check '雙引號裡的 $(…)'                          block 'out="$(git commit -n -m wip)"'
    check '雙引號裡的反引號'                         block 'echo "`git commit --no-verify -m wip`"'
    check 'heredoc 交給 bash 執行'                   block $'bash <<\'EOF\'\ngit commit -n -m x\nEOF'
    check '-c 吃不到參數時不能吞掉分號'              block 'git -c; git commit --no-verify -m x'

    # ---- 要放行 ----
    check '一般 commit'                              allow 'git commit -m "x"'
    check '訊息裡有 -n'                              allow 'git commit -m "fix -n flag"'
    check '訊息裡有 --no-verify 字樣'                allow 'git commit -m "docs: 說明 --no-verify 會跳過 gate"'
    check 'heredoc 訊息（Claude 的慣用寫法）'        allow $'git commit -m "$(cat <<\'EOF\'\nfeat: 擋 --no-verify 與 -n\n\n說明 "-n" 的用法\nEOF\n)"'
    check 'SKIP_DOC_CHECK=1 是正式逃生口'            allow 'SKIP_DOC_CHECK=1 git commit -m "x"'
    check '-F 讀訊息檔'                              allow 'git commit -F msg.txt'
    check '-c 重用訊息（commit 的 -c）'              allow 'git commit -c HEAD'
    check '--amend --no-edit'                        allow 'git commit --amend --no-edit'
    check 'git config 設 hooksPath（開發本 repo）'   allow 'git config core.hooksPath scripts/githooks'
    check 'git config --get core.hooksPath'          allow 'git config --get core.hooksPath'
    check 'git log -n 5'                             allow 'git log -n 5'
    check 'grep -n'                                  allow 'grep -n "no-verify" README.md'
    check 'echo 印出字樣'                            allow 'echo "git commit --no-verify"'
    check '# 註解裡的字樣'                           allow $'# git commit --no-verify\ngit status'
    check 'heredoc 訊息內文有 git commit -n'         allow $'git commit -F - <<\'EOF\'\nfeat: gate-guard\n\ngit commit -n 現在會被擋\nEOF'
    check '先寫訊息檔的 heredoc，再 -F'              allow $'cat > /tmp/msg <<\'EOF\'\ngit commit -n 會被擋\nEOF\ngit commit -F /tmp/msg'
    check 'heredoc 訊息裡有奇數個雙引號'             allow $'git commit -m "$(cat <<\'EOF\'\nfix: strip trailing " before --no-verify check\nEOF\n)"'
    check '-m 吃不到參數時不能吞掉分號'              allow 'git commit -m; git log -n 5'
    check '2>&1 重導向'                              allow 'git commit -m x 2>&1'
    check '不是 Bash 的輸入（沒有 command）'         allow '' '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"}}'
    check '壞掉的 JSON'                              allow '' 'not json'
}

echo "=== 第 1 輪：預設 PATH（有 jq 就走 jq）==="
run_suite

# hook 是 jq 優先、python3 後備；只跑一輪的話 python3 那條在有 jq 的 CI 上從來沒被驗過
shim=$(mktemp -d) || shim=""
if [ -n "$shim" ] && command -v jq >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    ok=yes
    for t in cat awk python3; do
        p=$(command -v "$t") || { ok=no; break; }
        ln -sf "$p" "$shim/$t" || { ok=no; break; }
    done
    if [ "$ok" = yes ]; then
        echo
        echo "=== 第 2 輪：PATH 看不到 jq，逼 hook 走 python3 後備 ==="
        TOOL_PATH="$shim"
        run_suite
        TOOL_PATH="$PATH"
    else
        echo "⚠️  組不出不含 jq 的 PATH，跳過 python3 後備那輪"
    fi
else
    echo
    echo "⚠️  jq 與 python3 沒有同時存在，只驗得到其中一條分支"
fi

[ -n "$shim" ] && rm -rf "$shim"

# jq 與 python3 都沒有：讀不了 JSON，一律放行（不擋）而且不報錯。PATH 只放 cat 與 awk ——
# 另外組一份，不沿用第 2 輪的：第 2 輪被跳過時那份是空的，hook 會因為找不到 cat 才放行，案例假通過
shim=$(mktemp -d) || shim=""
ok=no
if [ -n "$shim" ]; then
    ok=yes
    for t in cat awk; do
        p=$(command -v "$t") || { ok=no; break; }
        ln -sf "$p" "$shim/$t" || { ok=no; break; }
    done
fi
echo
if [ "$ok" = yes ]; then
    echo "=== 第 3 輪：jq 與 python3 都沒有 ==="
    TOOL_PATH="$shim"
    check '讀不了 JSON 時放行'                   allow 'git commit --no-verify -m x'
    TOOL_PATH="$PATH"
else
    echo "⚠️  組不出只有 cat 與 awk 的 PATH，跳過第 3 輪"
fi
[ -n "$shim" ] && rm -rf "$shim"

echo
if [ "$fail" -eq 0 ]; then
    echo "✅ ${pass} 個情境全部符合預期"
    exit 0
fi
echo "❌ ${fail} 個情境不符預期（通過 ${pass} 個）"
exit 1
