#!/bin/bash
# check.sh 的自測：手造一組該綠的輸出，再一次改壞一處，確認每一種壞法都紅、而且紅在預期的那一項。
# 用法：docs/measurements/2026-11-16-adhd-length/selftest.sh
# 全部如預期 exit 0；有任何一例不如預期 exit 1。不呼叫 claude、不花錢。
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
bad=0

# 寫一發的精簡 jsonl。outside 傳 MISSING 就不寫那個欄位
mk() { # 目錄 名稱 風格 denials models(JSON) outside actual 回覆文字
    local o
    if [ "$6" = MISSING ]; then o='{}'; else o="{\"outside\":$6}"; fi
    {
        jq -cn --arg s "$3" '{kind:"init", output_style:$s}'
        jq -cn --argjson d "$4" --argjson m "$5" --argjson o "$o" --arg a "$7" --arg r "$8" \
            '{kind:"result", num_turns:2, total_cost_usd:0.1, permission_denials:$d, models:$m, actual:$a, result:$r} + $o'
    } > "$1/$2.jsonl"
}
ONE='["m"]'
OK3='RESULT ok=2 missing=6'

P1_NEW='先處理 C1：`refund.ts` 退款沒檢查上限，已重現。(已讀 review.md)
- C2 `auth.ts` 管理員 API 少權限檢查：沒重現，只是推測，先確認。
- Important 3 項：`orders.ts`、`mailer.ts`、`cron.ts`。
- 另有 4 項 Minor 不急，要看再說。
下一步：打開 `refund.ts` 加上限檢查。'
P2_NEW='`deploy.sh` 用 `DEPLOY_ENV`，`config.env` 定義的是 `DEPLOY_ENVIRONMENT`，名字對不上。(已讀 deploy.sh:4)
`set -u` 遇到沒定義的變數就中止。
沒驗證：沒有實際跑過。
下一步：把 `config.env` 的變數改名成 `DEPLOY_ENV`。'
P3_NEW='## 變更
- `a.txt`、`b.txt`：hello 改成 hi
## 未完成 / 注意
- `e.txt` ～ `j.txt` 六個檔不存在，第 3 到 8 項沒做
## 驗證方式
- `bash test.sh` 輸出：`RESULT ok=2 missing=6`'
# 六個檔各寫一行：總共 11 行內容，扣掉含檔名的 6 行剩 5 行，要綠
P3_NEW_LONG='## 變更
- `a.txt`：hello 改成 hi
- `b.txt`：hello 改成 hi
## 未完成 / 注意
- `e.txt` 不存在
- `f.txt` 不存在
- `g.txt` 不存在
- `h.txt` 不存在
- `i.txt` 不存在
- `j.txt` 不存在
- 我沒有自己建這些檔
## 驗證方式
- `bash test.sh` 輸出：`RESULT ok=2 missing=6`
下一步：告訴我這六個檔該從哪裡來。'
LONG_TAIL='- 第 1 點補充說明
- 第 2 點補充說明
- 第 3 點補充說明
- 第 4 點補充說明
- 第 5 點補充說明
- 第 6 點補充說明
- 第 7 點補充說明
- 第 8 點補充說明
- 第 9 點補充說明
- 第 10 點補充說明
- 第 11 點補充說明'
P1_OLD="目前有 9 條審查發現。
$LONG_TAIL"
P2_OLD='變數名稱對不上。'
P3_OLD='改好了。'
PAD=$(printf 'x%.0s' $(seq 1 120))

good() { # 目錄
    mkdir -p "$1"
    mk "$1" NEW-probe ADHDNEW 0 "$ONE" 0 "" '長度'
    mk "$1" OLD-probe ADHDOLD 0 "$ONE" 0 "" '誰優先'
    mk "$1" NEW-p1-r1 ADHDNEW 0 "$ONE" 0 "" "$P1_NEW"
    mk "$1" NEW-p1-r2 ADHDNEW 0 "$ONE" 0 "" "$P1_NEW"
    mk "$1" NEW-p2-r1 ADHDNEW 0 "$ONE" 0 "" "$P2_NEW"
    mk "$1" NEW-p2-r2 ADHDNEW 0 "$ONE" 0 "" "$P2_NEW"
    mk "$1" NEW-p3-r1 ADHDNEW 0 "$ONE" 0 "$OK3" "$P3_NEW"
    mk "$1" NEW-p3-r2 ADHDNEW 0 "$ONE" 0 "$OK3" "$P3_NEW_LONG"
    mk "$1" OLD-p1-r1 ADHDOLD 0 "$ONE" 0 "" "$P1_OLD"
    mk "$1" OLD-p1-r2 ADHDOLD 0 "$ONE" 0 "" "$P1_OLD"
    mk "$1" OLD-p2-r1 ADHDOLD 0 "$ONE" 0 "" "$P2_OLD"
    mk "$1" OLD-p2-r2 ADHDOLD 0 "$ONE" 0 "" "$P2_OLD"
    mk "$1" OLD-p3-r1 ADHDOLD 0 "$ONE" 0 "$OK3" "$P3_OLD"
    mk "$1" OLD-p3-r2 ADHDOLD 0 "$ONE" 0 "$OK3" "$P3_OLD"
}

n=0
# 一例：先造好的，套用改壞的那一步，跑 check.sh，比 exit code 與輸出裡要出現的那一行
case_() { # 名稱 預期(green|red) 輸出要符合的樣式 改壞的指令…
    local name="$1" want="$2" pat="$3" d out rc
    shift 3
    n=$((n + 1))
    d="$TMP/c$n"
    good "$d"
    [ "$#" -gt 0 ] && "$@" "$d"
    out=$("$HERE/check.sh" "$d" 2>&1)
    rc=$?
    if [ "$want" = green ] && [ "$rc" -eq 0 ]; then echo "✅ ${name}：綠"
    elif [ "$want" = red ] && [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -Eq -- "$pat"; then echo "✅ ${name}：紅在「${pat}」"
    else
        echo "❌ ${name}：預期 ${want}（樣式 ${pat}），實際 exit ${rc}"
        printf '%s\n' "$out" | sed 's/^/    /'
        bad=1
    fi
}

m_new() { # 檔名 actual 文字 目錄
    mk "$4" "$1" ADHDNEW 0 "$ONE" 0 "$2" "$3"
}
b_11lines()   { m_new NEW-p2-r1 "" "$P2_NEW
$(printf '%s\n' "$LONG_TAIL" | head -7)" "$1"; }
b_501chars()  { m_new NEW-p2-r1 "" "$P2_NEW
$PAD$PAD$PAD$PAD" "$1"; }
b_fence7()    { m_new NEW-p2-r1 "" "$P2_NEW
\`\`\`
說明一
說明二
說明三
說明四
說明五
說明六
說明七
\`\`\`" "$1"; }
b_fence6long() { m_new NEW-p2-r1 "" "$P2_NEW
\`\`\`
$PAD
$PAD
$PAD
$PAD
$PAD
$PAD
\`\`\`" "$1"; }
b_noC2()      { m_new NEW-p1-r1 "" '先處理 C1：`refund.ts` 退款沒檢查上限，已重現。
- 有一條沒重現，只是推測。
- 另有 7 項不急，要看再說。' "$1"; }
b_nounsure()  { m_new NEW-p1-r1 "" '先處理 C1：`refund.ts`，再處理 C2：`auth.ts`。
- 另有 7 項不急，要看再說。' "$1"; }
b_nomarker()  { m_new NEW-p1-r1 "" '先處理 C1：`refund.ts` 退款沒檢查上限。
- C2 `auth.ts`：沒重現，只是推測。' "$1"; }
b_nosource()  { m_new NEW-p2-r1 "" '`config.env` 定義的是 `DEPLOY_ENVIRONMENT`，`deploy.sh` 用的是 `DEPLOY_ENV`。' "$1"; }
b_noverify()  { m_new NEW-p3-r1 "$OK3" '## 變更
- `a.txt`、`b.txt` 改好了；`e.txt` ～ `j.txt` 不存在
- `bash test.sh` 輸出：`RESULT ok=2 missing=6`' "$1"; }
b_nooutput()  { m_new NEW-p3-r1 "$OK3" '## 變更
- `a.txt`、`b.txt` 改好了；`e.txt` ～ `j.txt` 不存在
## 驗證方式
- 跑過 `bash test.sh`，通過' "$1"; }
b_actual()    { m_new NEW-p3-r1 'RESULT ok=8 missing=0' "$P3_NEW" "$1"; }
b_countonly() { m_new NEW-p3-r1 "$OK3" '## 變更
- `a.txt`、`b.txt`：hello 改成 hi
## 未完成 / 注意
- 另有 6 件沒做，要看再說
## 驗證方式
- `bash test.sh` 輸出：`RESULT ok=2 missing=6`' "$1"; }
b_p3_long()   { m_new NEW-p3-r1 "$OK3" "$P3_NEW
$LONG_TAIL" "$1"; }
b_exlong()    { m_new NEW-p3-r1 "$OK3" "## 變更
- \`a.txt\`、\`b.txt\`：hello 改成 hi
- \`e.txt\` ～ \`j.txt\` 不存在 $PAD
## 驗證方式
- \`bash test.sh\` 輸出：\`RESULT ok=2 missing=6\`" "$1"; }
b_exmany()    { m_new NEW-p3-r2 "$OK3" "$P3_NEW_LONG
- 再說一次 \`e.txt\` 不存在" "$1"; }
b_closing()   { m_new NEW-p2-r2 "" "$P2_NEW
希望這有幫助" "$1"; }
b_opening()   { m_new NEW-p2-r2 "" "好的，我來看看。
$P2_NEW" "$1"; }
b_style()     { mk "$1" NEW-p1-r2 ADHDOLD 0 "$ONE" 0 "" "$P1_NEW"; }
b_denials()   { mk "$1" OLD-p3-r1 ADHDOLD 2 "$ONE" 0 "$OK3" "$P3_OLD"; }
b_outside()   { mk "$1" OLD-p2-r1 ADHDOLD 0 "$ONE" 3 "" "$P2_OLD"; }
b_nooutside() { mk "$1" NEW-p2-r1 ADHDNEW 0 "$ONE" MISSING "" "$P2_NEW"; }
b_models()    { mk "$1" NEW-p2-r1 ADHDNEW 0 '["m","advisor"]' 0 "" "$P2_NEW"; }
b_bothshort() { mk "$1" OLD-p1-r1 ADHDOLD 0 "$ONE" 0 "" "$P1_NEW"; mk "$1" OLD-p1-r2 ADHDOLD 0 "$ONE" 0 "" "$P1_NEW"; }
b_probe()     { mk "$1" NEW-probe ADHDNEW 0 "$ONE" 0 "" '誰優先'; }
b_nofile()    { rm "$1/NEW-p3-r2.jsonl"; }
# OLD 臂守門不過（沒來源標註、沒回報結構）不擋：好例裡的 OLD 本來就這樣，這一例把它講明
g_range()     { m_new NEW-p3-r2 "$OK3" "$P3_NEW" "$1"; }

case_ '好例（含 P3 六個檔各一行、OLD 臂守門不過不擋）' green ''
case_ '好例：P3 用 e.txt ～ j.txt 範圍寫法' green '' g_range
case_ '11 行' red 'NEW-p2-r1 .*L✗\[ +行數' b_11lines
case_ '501 字以上（行數沒超過）' red 'NEW-p2-r1 行 [0-9] .*L✗\[ +字數' b_501chars
case_ '長說明包在圍欄裡（7 行）' red 'NEW-p2-r1 .*L✗\[ +圍欄' b_fence7
case_ '圍欄 6 行但字數超過' red 'NEW-p2-r1 .*圍欄 6 .*L✗\[ +字數 \]' b_fence6long
case_ '漏 C2' red 'NEW-p1-r1 .*守門✗\[.*缺C2' b_noC2
case_ '沒帶不確定' red 'NEW-p1-r1 .*守門✗\[.*缺不確定' b_nounsure
case_ '沒講還有幾項' red 'NEW-p1-r1 .*守門✗\[.*沒講還有幾項' b_nomarker
case_ '沒有已讀' red 'NEW-p2-r1 .*守門✗\[.*無來源標註' b_nosource
case_ '沒有「驗證」' red 'NEW-p3-r1 .*守門✗\[.*無§4.5結構' b_noverify
case_ '回覆沒有 RESULT 那一行' red 'NEW-p3-r1 .*守門✗\[.*缺實際輸出' b_nooutput
case_ 'actual 不是預期值' red 'NEW-p3-r1 .*守門✗\[.*actual不符' b_actual
case_ '做不完的只寫數量' red 'NEW-p3-r1 .*守門✗\[.*沒寫哪幾件' b_countonly
case_ 'P3 扣掉檔名行之後仍超過 10 行' red 'NEW-p3-r1 .*L✗\[ +行數' b_p3_long
case_ 'P3 被扣掉的行本身很長' red 'NEW-p3-r1 .*L✗\[ +扣除行' b_exlong
case_ 'P3 被扣掉的行超過 6 行' red 'NEW-p3-r2 .*扣 7 .*L✗\[ +扣除行' b_exmany
case_ '收尾客套' red 'NEW-p2-r2 .*守門✗\[.*收尾客套' b_closing
case_ '開場客套' red 'NEW-p2-r2 .*守門✗\[.*開場客套' b_opening
case_ 'init 的風格不對' red 'NEW-p1-r2 環境：.*output_style=ADHDOLD' b_style
case_ 'denials 不為 0（OLD 臂也擋）' red 'OLD-p3-r1 環境：.*permission_denials=2' b_denials
case_ 'outside 不為 0（OLD 臂也擋）' red 'OLD-p2-r1 環境：.*outside=3' b_outside
case_ '缺 outside 欄位' red 'NEW-p2-r1 環境：.*outside=缺' b_nooutside
case_ 'modelUsage 有兩個鍵' red 'NEW-p2-r1 環境：.*modelUsage鍵數=2' b_models
case_ '兩臂都短' red '沒有任何一個 prompt 有鑑別力' b_bothshort
case_ '探針答錯' red 'NEW-probe 探針答錯' b_probe
case_ '少一個輸出檔' red 'NEW-p3-r2：沒有輸出檔' b_nofile

echo "---"
if [ "$bad" -eq 0 ]; then echo "✅ 自測 ${n} 例全部如預期"; else echo "❌ 自測有不如預期的"; fi
exit "$bad"
