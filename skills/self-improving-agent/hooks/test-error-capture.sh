#!/bin/bash
# error-capture.sh 的行為測試。CI 會跑這支（.github/workflows/ci.yml）。
#
# 【它守什麼】逐行比對的**語意**：exclusion 不得一票否決整份輸出、命中要回得出合法的
# additionalContext、回報的要是第一個命中行、stdout 與 stderr 兩邊都要讀、jq 與 python3
# 兩條分支都要能動。2026-09-12 踩過：exclusion 拿整份輸出比對，輸出裡任一處出現
# console.error 或 no error，同一份輸出裡真正的失敗全部被吞掉 —— 零輸出 exit 0，
# 與「這次真的沒錯誤」外觀完全相同，shellcheck 與 bash -n 都無感。
#
# 【它不守什麼 —— 不要以為加了這支就全有了】ERROR_PATTERNS 與 EXCLUSIONS 兩張清單的
# **完整性**。情境只碰到其中幾條，增刪清單項目這支測試不會有任何反應。要守那個得逐條列舉，
# 成本遠高於價值，所以刻意不做 —— 但別在文件裡把這支寫成全面防線。
#
# 【payload 怎麼寫】直接手寫進 JSON 字串字面值（換行用字面兩字元 \n）。含雙引號或反斜線
# 會生出壞 JSON，hook 解不開就靜默 exit 0 —— 期望 silent 的案例會「通過」而其實什麼都沒驗。
# 所以每個 payload 送出前都會先驗 JSON 合法性，不合法直接判該案例失敗。
#
# 用法：test-error-capture.sh [error-capture.sh 的路徑]　預設取同目錄那支。
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
HOOK="${1:-$HERE/error-capture.sh}"
[ -x "$HOOK" ] || { echo "❌ 找不到可執行的 ${HOOK}"; exit 2; }

# hook 在 jq 與 python3 都沒有時「靜默 exit 0」是正確行為，那種環境下本測試量不到東西，
# 會整排報「期望 fire 實際 silent」而看起來像 hook 壞了。講清楚再中止。
if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    echo "❌ 需要 jq 或 python3 才驗得動這支 hook（兩者皆無時 hook 靜默 exit 0 是正確的）"
    exit 2
fi

pass=0
fail=0
TOOL_PATH="$PATH"   # 跑第二輪時換成「看不到 jq」的 PATH，逼 hook 走 python3 後備

json_ok() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$1" | jq empty >/dev/null 2>&1
    else
        printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1
    fi
}

# $1=案例名　$2=fire|silent　$3=err|out（payload 放哪一欄）　$4=payload　$5=(選用) Context 必須含的字
check() {
    local name="$1" expect="$2" stream="$3" payload="$4" want="${5:-}"
    local json out rc got err=""

    if [ "$stream" = out ]; then
        json=$(printf '{"tool_name":"Bash","tool_input":{"command":"x"},"tool_response":{"stdout":"%s","stderr":""}}' "$payload")
    else
        json=$(printf '{"tool_name":"Bash","tool_input":{"command":"x"},"tool_response":{"stdout":"","stderr":"%s"}}' "$payload")
    fi

    # payload 帶雙引號／反斜線會讓這串 JSON 壞掉，hook 解不開就靜默 —— 期望 silent 的案例
    # 會假通過。用不同的訊息報，才不會跟「行為不對」混在一起。
    if ! json_ok "$json"; then
        printf '%-40s ❌ payload 組不出合法 JSON（含雙引號或反斜線？）\n' "$name"
        fail=$((fail + 1))
        return
    fi

    # out=$(...) 與 rc=$? 要分開兩行：併成 local out=$(...) 的話 rc 抓到的是 local 的
    # 結束狀態（永遠 0），下面的 exit code 檢查會靜靜失效
    out=$(printf '%s' "$json" | env PATH="$TOOL_PATH" "$HOOK")
    rc=$?
    got=silent
    [ -n "$out" ] && got=fire

    if [ "$rc" -ne 0 ]; then
        err="hook exit=${rc}（不論有沒有命中都應為 0）"
    elif [ "$got" != "$expect" ]; then
        err="期望 ${expect}，實際 ${got}"
    elif [ "$got" = fire ] && ! printf '%s' "$out" | grep -q '"additionalContext"'; then
        err="觸發了，但輸出不含 additionalContext"
    elif [ "$got" = fire ] && ! printf '%s' "$out" | grep -q 'PostToolUse'; then
        err="觸發了，但 hookEventName 不是 PostToolUse"
    elif [ -n "$want" ] && ! printf '%s' "$out" | grep -q -- "$want"; then
        err="Context 裡找不到「${want}」（應回報第一個命中行）"
    fi

    if [ -n "$err" ]; then
        printf '%-40s ❌ %s\n' "$name" "$err"
        fail=$((fail + 1))
        return
    fi
    printf '%-40s ✅ %s\n' "$name" "$got"
    pass=$((pass + 1))
}

run_suite() {
    echo "必須觸發"
    echo "----------------------------------------------------------"
    # 前三條是 2026-09-12「一票否決」那個 bug 的回歸測試，修好前都是靜默的
    check '真錯誤與 console.error 同在一份輸出' fire err \
        'src/a.ts:3 console.error(e)\nBuild failed with 1 error'
    check 'no errors 與 Build failed 並存' fire err \
        'web: compiled with no errors\napi: Build failed with 3 errors'
    check '被排除的行在前、真錯誤在後' fire err \
        'console.error(x)\nnpm ERR! build died'
    check '單純找不到檔案（煙霧測試，修前也會過）' fire err \
        'cat: nope: No such file or directory'
    # hook 讀的是 stdout+stderr 兩邊。少了這條，把 stdout 抽取拿掉的迴歸會整個溜過去
    check '錯誤走 stdout 而不是 stderr' fire out \
        'npm ERR! code ELIFECYCLE'
    check 'stdout 也吃得到逐行比對' fire out \
        'console.error(x)\nBuild failed with 2 errors'
    # 一次守住三件事：Context 不得空白、不得被截掉、必須是「第一個」命中行（break 2 的語意）
    check '兩行都命中時回報第一行' fire err \
        'first ERROR: alpha\nsecond ERROR: beta' 'alpha'

    echo
    echo "必須靜默"
    echo "----------------------------------------------------------"
    check '純粹在講錯誤處理的程式碼' silent err 'const errorHandler = (e) => {}'
    check '提到 hook 自己的名字' silent err 'ran error-capture.sh ok'
    check '空輸出' silent err ''
    check '只有空白與換行' silent err '   \n  \n   '
    check '排除字與錯誤字在同一行' silent err 'logger.error( failed to parse )'
    check 'stdout 也套用同一組 exclusion' silent out 'console.error(failed)'
}

echo "=== 第 1 輪：預設 PATH（有 jq 就走 jq）==="
run_suite

# hook 是 jq 優先、python3 後備。只跑一輪的話另一條分支零覆蓋 —— 而 ubuntu runner 有 jq，
# 等於 python3 那條（給沒裝 jq 的機器用的）在 CI 上從來沒被驗過。
if command -v jq >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    shim=$(mktemp -d) || shim=""
    if [ -n "$shim" ]; then
        ok=yes
        for t in cat grep cut python3; do
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
        rm -rf "$shim"
    fi
else
    echo
    echo "⚠️  jq 與 python3 沒有同時存在，只驗得到其中一條分支"
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "✅ ${pass} 個情境全部符合預期"
    exit 0
fi
echo "❌ ${fail} 個情境不符預期（通過 ${pass} 個）"
exit 1
