#!/bin/bash
# error-capture.sh 的行為測試。CI 會跑這支（.github/workflows/ci.yml）。
#
# 為什麼需要它：這支 hook 的失效方式是**完全靜默** —— 零輸出、exit 0，與「這次真的沒有
# 錯誤」在外觀上無法區分。2026-09-12 踩過：exclusion 拿整份輸出比對，變成一票否決 ——
# 輸出裡任何一處出現 console.error 或 no error，同一份輸出裡真正的失敗全部被吞掉。
# `shellcheck` 與 `bash -n` 對這種錯完全無感，只有行為測試抓得到。
#
# 不依賴 python3：payload 是固定字串，JSON 直接手寫（換行寫成字面的兩字元 \n，
# 由 JSON 解析器還原）。payload 內不可出現雙引號，否則 JSON 會壞掉。
#
# 用法：test-error-capture.sh [error-capture.sh 的路徑]　預設取同目錄那支。
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
HOOK="${1:-$HERE/error-capture.sh}"
[ -x "$HOOK" ] || { echo "❌ 找不到可執行的 ${HOOK}"; exit 2; }

pass=0
fail=0

# $1=案例名　$2=fire|silent　$3=stderr 內容（換行用字面 \n）
check() {
    local name="$1" expect="$2" payload="$3"
    local out rc got
    out=$(printf '{"tool_name":"Bash","tool_input":{"command":"x"},"tool_response":{"stdout":"","stderr":"%s"}}' \
          "$payload" | "$HOOK")
    rc=$?
    got=silent
    [ -n "$out" ] && got=fire

    if [ "$rc" -ne 0 ]; then
        printf '%-44s ❌ hook exit=%s（不論有沒有命中都應為 0）\n' "$name" "$rc"
        fail=$((fail + 1))
        return
    fi
    if [ "$got" != "$expect" ]; then
        printf '%-44s ❌ 期望 %s，實際 %s\n' "$name" "$expect" "$got"
        fail=$((fail + 1))
        return
    fi
    # 有觸發時輸出必須帶 additionalContext，否則提醒送不到 Claude 手上
    if [ "$got" = fire ] && ! printf '%s' "$out" | grep -q '"additionalContext"'; then
        printf '%-44s ❌ 觸發了，但輸出不含 additionalContext\n' "$name"
        fail=$((fail + 1))
        return
    fi
    printf '%-44s ✅ %s\n' "$name" "$got"
    pass=$((pass + 1))
}

echo "必須觸發                                     結果"
echo "------------------------------------------------------"
# 這三條是 2026-09-12 那個「一票否決」bug 的回歸測試。①③ 在修好前都是靜默的。
check '真錯誤與 console.error 同在一份輸出' fire \
    'src/a.ts:3 console.error(e)\nBuild failed with 1 error'
check '單純找不到檔案（煙霧測試，修前也會過）' fire \
    'cat: nope: No such file or directory'
check 'no errors 與 Build failed 並存' fire \
    'web: compiled with no errors\napi: Build failed with 3 errors'
check '被排除的行在前、真錯誤在後' fire \
    'console.error(x)\nnpm ERR! build died'

echo
echo "必須靜默                                     結果"
echo "------------------------------------------------------"
check '純粹在講錯誤處理的程式碼' silent 'const errorHandler = (e) => {}'
check '提到 hook 自己的名字' silent 'ran error-capture.sh ok'
check '空輸出' silent ''
check '只有空白與換行' silent '   \n  \n   '
# 同一行同時有 exclusion 與 pattern → 該行被否決，且沒有別行可命中
check '排除字與錯誤字在同一行' silent 'logger.error( failed to parse )'

echo
if [ "$fail" -eq 0 ]; then
    echo "✅ ${pass} 個情境全部符合預期（觸發 4 / 靜默 5）"
    exit 0
fi
echo "❌ ${fail} 個情境不符預期（通過 ${pass} 個）"
exit 1
