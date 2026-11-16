#!/bin/bash
# run.sh 產出的判定。判準在跑之前就寫死在這支、先 commit 再跑；同一批資料不改判準。
#
# 用法：docs/measurements/2026-11-16-adhd-length/check.sh <某一批的輸出目錄，例如 out/batch1>
# 通過（exit 0）要五項都成立：
#   1. 兩發載入探針答對（NEW 回「長度」、OLD 回「誰優先」）
#   2. 每一發：init 的 output_style 等於該臂、permission_denials 為 0、modelUsage 只有一個鍵、outside 是數字而且為 0
#   3. NEW 臂 6 發的長度斷言 L 全成立
#   4. NEW 臂 6 發的守門全成立（OLD 臂的守門只印不擋）
#   5. 至少一個 prompt 有鑑別力：NEW 2/2 過 L、OLD 至少 1/2 不過 L
# 第 2 項不過是旗標或環境問題，不是風格的問題：修好重跑，不算進「最多 3 批」的措辭批次。
#
# 長度斷言 L（三個都成立）：
#   內容行 <= 10：非空行，扣掉 # 開頭的標題行、圍欄行與圍欄裡的行
#   字數 <= 500：內容行與圍欄裡的行的字元數總和，不含換行，用 jq 的 length 算（不隨 locale 變）
#   圍欄行數 <= 6：圍欄裡的非空行
#   P3 有六件做不完的事，風格允許為它超過 10 行：P3 先扣掉「含 e.txt 到 j.txt 任一檔名的內容行」再算行數與字數；
#   被扣掉的行最多 6 行、每行最多 100 字（不然一行長說明帶到檔名就躲掉了）
# 輸入是 run.sh 抽出的精簡 jsonl（每發一行 kind=init、一行 kind=result），不是原始 stream-json
set -u
OUT="${1:?用法：check.sh <某一批的輸出目錄>}"
fail=0
command -v jq > /dev/null || { echo "❌ 需要 jq"; exit 2; }

content_lines() {
    printf '%s\n' "$1" | awk '
        /^[[:space:]]*```/ { f = !f; next }
        f { next }
        /^[[:space:]]*$/ { next }
        /^[[:space:]]*#/ { next }
        { print }'
}
fence_lines() {
    printf '%s\n' "$1" | awk '
        /^[[:space:]]*```/ { f = !f; next }
        f && !/^[[:space:]]*$/ { print }'
}
nlines() { printf '%s\n' "$1" | awk 'NF { n++ } END { print n + 0 }'; }
nchars() { printf '%s\n' "$1" | jq -Rn '[inputs | length] | add // 0'; }
maxchars() { printf '%s\n' "$1" | jq -Rn '[inputs | length] | max // 0'; }
first_line() { printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | head -1; }
has() { printf '%s\n' "$1" | grep -Eq "$2"; }
hasF() { printf '%s\n' "$1" | grep -Fq "$2"; }

MISSING_RE='(e|f|g|h|i|j)\.txt'
NUM_RE='([0-9]+|一|二|三|四|五|六|七|八|九|十|兩) ?(項|個|條|件)'
WHERE_RE='要看再說|另有|其餘|還有|剩下|其他|不急|細節'
EXPECT_ACTUAL='RESULT ok=2 missing=6'

# 長度斷言。印出「行數 字數 圍欄行數 扣掉的行數 理由」，理由是空的就是成立
measure() { # $1 = prompt 編號，$2 = 回覆文字
    local cl fl ex n c f e why=""
    cl=$(content_lines "$2")
    fl=$(fence_lines "$2")
    ex=""
    if [ "$1" = 3 ]; then
        ex=$(printf '%s\n' "$cl" | grep -E "$MISSING_RE" || true)
        cl=$(printf '%s\n' "$cl" | grep -Ev "$MISSING_RE" || true)
    fi
    n=$(nlines "$cl")
    f=$(nlines "$fl")
    e=$(nlines "$ex")
    c=$(( $(nchars "$cl") + $(nchars "$fl") ))
    [ "$n" -le 10 ] || why="$why 行數"
    [ "$c" -le 500 ] || why="$why 字數"
    [ "$f" -le 6 ] || why="$why 圍欄"
    if [ "$e" -gt 6 ] || [ "$(maxchars "$ex")" -gt 100 ]; then why="$why 扣除行"; fi
    echo "$n $c $f $e$why"
}

# 守門。印出不成立的項目，空的就是全成立
guard() { # $1 = prompt 編號，$2 = 回覆文字，$3 = actual
    local g="" it all=1 line marker=0
    first_line "$2" | grep -Eq '^(好的|好，|當然|沒問題|Sure|Great|讓我|我來幫|以下是)' && g="$g 開場客套"
    has "$2" '希望(這|對你)?有幫助|還需要什麼|有問題(再|隨時)|Let me know|Hope this' && g="$g 收尾客套"
    case "$1" in
    1)
        has "$2" 'C1|refund' || g="$g 缺C1"
        has "$2" 'C2|auth' || g="$g 缺C2"
        has "$2" '沒重現|未確認|沒驗證|不確定|推測' || g="$g 缺不確定"
        for it in refund.ts auth.ts orders.ts mailer.ts cron.ts utils.ts README.md logger.ts types.ts; do
            hasF "$2" "$it" || all=0
        done
        if [ "$all" = 0 ]; then
            while IFS= read -r line; do
                if printf '%s\n' "$line" | grep -Eq "$NUM_RE" && printf '%s\n' "$line" | grep -Eq "$WHERE_RE"; then marker=1; fi
            done <<LINES
$2
LINES
            [ "$marker" = 1 ] || g="$g 沒講還有幾項"
        fi
        ;;
    2)
        hasF "$2" 'DEPLOY_ENVIRONMENT' || g="$g 缺病因"
        hasF "$2" '已讀' || g="$g 無來源標註"
        ;;
    3)
        { hasF "$2" '變更' && hasF "$2" '驗證'; } || g="$g 無§4.5結構"
        [ "$3" = "$EXPECT_ACTUAL" ] || g="$g actual不符"
        hasF "$2" "$EXPECT_ACTUAL" || g="$g 缺實際輸出"
        all=1
        for it in e.txt f.txt g.txt h.txt i.txt j.txt; do
            hasF "$2" "$it" || all=0
        done
        if [ "$all" = 0 ]; then
            has "$2" 'e\.txt.{0,12}j\.txt' || g="$g 沒寫哪幾件"
        fi
        ;;
    esac
    echo "$g"
}

field() { jq -r "select(.kind==\"$2\") | $3" "$1" 2> /dev/null | head -1; }

# 環境檢查。印出不成立的項目
env_check() { # $1 = 檔案，$2 = 預期的風格名
    local bad="" style denials nmodels outside
    style=$(field "$1" init '.output_style')
    denials=$(field "$1" result '.permission_denials')
    nmodels=$(field "$1" result '.models | length')
    outside=$(field "$1" result '.outside | if type == "number" then . else "缺" end')
    [ "$style" = "$2" ] || bad="$bad output_style=${style:-缺}"
    [ "$denials" = "0" ] || bad="$bad permission_denials=${denials:-缺}"
    [ "$nmodels" = "1" ] || bad="$bad modelUsage鍵數=${nmodels:-缺}"
    [ "$outside" = "0" ] || bad="$bad outside=${outside:-缺}"
    echo "$bad"
}

# 1. 載入探針
for arm in NEW OLD; do
    f="$OUT/$arm-probe.jsonl"
    if [ "$arm" = NEW ]; then want='長度'; other='誰優先'; else want='誰優先'; other='長度'; fi
    if [ ! -f "$f" ]; then echo "❌ ${arm}-probe：沒有輸出檔"; fail=1; continue; fi
    bad=$(env_check "$f" "ADHD$arm")
    [ -z "$bad" ] || { echo "❌ ${arm}-probe 環境：${bad}"; fail=1; }
    text=$(field "$f" result '.result')
    if hasF "$text" "$want" && ! hasF "$text" "$other"; then
        echo "${arm}-probe 探針✓"
    else
        echo "❌ ${arm}-probe 探針答錯（要「${want}」）：$(first_line "$text" | cut -c1-60)"; fail=1
    fi
done

# 2–4. 每一發
for arm in NEW OLD; do
    for p in 1 2 3; do
        for rep in 1 2; do
            name="$arm-p$p-r$rep"
            f="$OUT/$name.jsonl"
            if [ ! -f "$f" ]; then echo "❌ ${name}：沒有輸出檔"; fail=1; continue; fi
            bad=$(env_check "$f" "ADHD$arm")
            [ -z "$bad" ] || { echo "❌ ${name} 環境：${bad}"; fail=1; }
            text=$(jq -r 'select(.kind=="result") | .result' "$f" | head -c 20000)
            actual=$(field "$f" result '.actual')
            cost=$(field "$f" result '.total_cost_usd')
            m=$(measure "$p" "$text")
            nums=$(printf '%s' "$m" | cut -d' ' -f1-4)
            why=$(printf '%s' "$m" | cut -d' ' -f5-)
            # shellcheck disable=SC2086
            set -- $nums
            line="$name 行 $1 字 $2 圍欄 $3 扣 $4 費用 ${cost}"
            key="${arm}_p$p"
            eval "cnt_${key}=\${cnt_${key}:-0}"
            if [ -z "$why" ]; then
                eval "cnt_${key}=\$((cnt_${key} + 1))"
                line="$line L✓"
            else
                line="$line L✗[ $why ]"
                [ "$arm" = NEW ] && fail=1
            fi
            g=$(guard "$p" "$text" "$actual")
            if [ -z "$g" ]; then
                line="$line 守門✓"
            else
                line="$line 守門✗[$g ]"
                [ "$arm" = NEW ] && fail=1
            fi
            echo "$line"
        done
    done
done

# 5. 鑑別力
echo "---"
disc=0
for p in 1 2 3; do
    a=$(eval "echo \${cnt_NEW_p${p}:-0}")
    b=$(eval "echo \${cnt_OLD_p${p}:-0}")
    verdict="無鑑別力"
    if [ "$a" -eq 2 ] && [ "$b" -le 1 ]; then verdict="有鑑別力"; disc=1; fi
    echo "L p${p}：NEW ${a}/2、OLD ${b}/2 過，${verdict}"
done
if [ "$disc" -eq 0 ]; then echo "❌ 沒有任何一個 prompt 有鑑別力：未證明新版比舊版短"; fail=1; fi
if [ "$fail" -eq 0 ]; then echo "✅ 通過"; else echo "❌ 不通過"; fi
exit "$fail"
