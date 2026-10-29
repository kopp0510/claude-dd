#!/bin/bash
# run.sh 產出的判定。判準在跑之前就寫死在這支；同一批資料不改判準 —— 要改就兩臂整組重跑，並在 CLAUDE.md 記下改了什麼、為什麼。
#
# 用法：docs/measurements/2026-10-29-adhd-style/check.sh [輸出目錄（預設 ./out）]
# 通過（exit 0）= 每一發 init 的 output_style 正確、permission_denials 為空
#               + ADHD 臂每一發守門斷言全成立
#               + 至少一組（鑑別斷言, prompt）有鑑別力：ADHD 臂 2/2 成立、default 臂至少 1/2 不成立
# 沒有任何一組有鑑別力（例如 default 臂也成立、或 ADHD 臂只有 1/2）→ 印「未證明風格生效」，不算通過
# 輸入是 run.sh 抽出的精簡 jsonl（每發一行 kind=init、一行 kind=result），不是原始 stream-json
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT="${1:-$HERE/out}"
fail=0

first_line() { printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | head -1; }
last_line()  { printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | tail -1; }
has()        { printf '%s\n' "$1" | grep -Eq "$2"; }

# 鑑別斷言：只看全域 CLAUDE.md 沒要求的特徵
d1() { last_line "$1" | grep -Eq '^\**下一步\**[：:]'; }                     # 最後一行是「下一步：」
d2() { local f n; f=$(first_line "$1"); n=$(jq -rn --arg s "$f" '$s | length'); [ "$n" -le 60 ] && ! printf '%s' "$f" | grep -Eq '[：:]$|^#'; }  # 第一句短（字數用 jq 算，不隨 locale 變）、不是「以下是…：」或標題
d3() { has "$1" '(大約|約) ?[0-9一二三四五六七八九十幾半]+ ?(秒|分鐘|分|小時|天)'; }      # 有具體時間估計（規則 6）

for arm in ADHD default; do
    for p in 1 2; do
        for rep in 1 2; do
            f="$OUT/$arm-p$p-r$rep.jsonl"
            name="$arm-p$p-r$rep"
            if [ ! -f "$f" ]; then echo "❌ ${name}：沒有輸出檔"; fail=1; continue; fi
            style=$(jq -r 'select(.kind=="init") | .output_style' "$f" | head -1)
            denials=$(jq -r 'select(.kind=="result") | .permission_denials' "$f" | head -1)
            text=$(jq -r 'select(.kind=="result") | .result' "$f" | head -c 20000)
            line="$name style=$style denials=$denials"
            [ "$style" = "$arm" ] || { echo "❌ ${name}：init output_style=${style}，預期 ${arm}"; fail=1; }
            [ "$denials" = "0" ] || { echo "❌ ${name}：permission_denials=${denials}（先修旗標或 prompt 再整組重跑，不歸因風格）"; fail=1; }

            # 守門斷言
            g=""
            first_line "$text" | grep -Eq '^(好的|好，|當然|沒問題|Sure|Great|讓我|我來|我會|以下是)' && g="$g 開場客套"
            has "$text" '希望(這|對你)?有幫助|還需要什麼|有問題(再|隨時)|Let me know|Hope this' && g="$g 收尾客套"
            if [ "$p" = 1 ]; then
                for it in 買牛奶 繳電費 回覆房東 預約牙醫 修腳踏車 寄包裹 澆花; do
                    has "$text" "$it" || g="$g 缺項:$it"
                done
                has "$text" '已讀' || g="$g 無來源標註"
            else
                { has "$text" '變更' && has "$text" '驗證'; } || g="$g 無§4.5結構"
            fi
            if [ -n "$g" ]; then
                line="$line 守門✗[$g ]"
                [ "$arm" = ADHD ] && fail=1
            else
                line="$line 守門✓"
            fi

            for d in d1 d2 d3; do
                key="${arm}_${d}_p$p"
                eval "cnt_${key}=\${cnt_${key}:-0}"
                if "$d" "$text"; then eval "cnt_${key}=\$((cnt_${key} + 1))"; line="$line ${d}✓"; else line="$line ${d}✗"; fi
            done
            echo "$line"
        done
    done
done

echo "---"
disc=0
for d in d1 d2 d3; do
    for p in 1 2; do
        a=$(eval "echo \${cnt_ADHD_${d}_p${p}:-0}")
        b=$(eval "echo \${cnt_default_${d}_p${p}:-0}")
        verdict="無鑑別力"
        if [ "$a" -eq 2 ] && [ "$b" -le 1 ]; then verdict="有鑑別力"; disc=1; fi
        echo "${d} p${p}：ADHD ${a}/2、default ${b}/2 → ${verdict}"
    done
done
if [ "$disc" -eq 0 ]; then echo "❌ 沒有任何一組有鑑別力：未證明風格生效"; fail=1; fi
[ "$fail" -eq 0 ] && echo "✅ 通過" || echo "❌ 不通過"
exit "$fail"
