#!/bin/bash
# 開工前提 P1：專案根目錄的 CLAUDE.local.md 會不會被全新的 session 載入。
# 兩臂只差有沒有這個檔（with／without），各 1 發、haiku。有檔那一臂的檔照 dd-stop.sh 的做法列進 .git/info/exclude。
# 判定（跑之前寫死）：with 的回覆第一行是 ZEBRA-7、without 的回覆裡沒有 ZEBRA-7，才算「會載入」。
#
# 用法：probe-local.sh <拋棄式工作目錄>   （要在 repo 與家目錄的 CLAUDE.md 鏈之外；必須不存在或是本腳本建的）
# 花費：每發上限 1 美元，共 2 發
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
WORK="${1:?用法：probe-local.sh <拋棄式工作目錄>}"
OUT="$HERE/out"
MARK=.dd-stop-probe-work

if [ -e "$WORK" ] && [ ! -f "$WORK/$MARK" ]; then
    echo "❌ ${WORK} 已存在且不是本腳本建的（沒有 ${MARK}），拒跑：每發之前會整個刪掉它" >&2
    exit 1
fi
mkdir -p "$OUT"
prompt='用一句話回答：1 加 1 等於多少？不要用任何工具。'
printf '%s\n' "$prompt" > "$OUT/probe-local.prompt.txt"

for arm in with without; do
    rm -rf "$WORK"
    mkdir -p "$WORK"
    touch "$WORK/$MARK"
    ( cd "$WORK" && git init -q && printf '# 探針專案\n\n這個專案只有一個檔。\n' > CLAUDE.md )
    if [ "$arm" = with ]; then
        ( cd "$WORK" && printf '每則回覆的第一行只寫 ZEBRA-7 這幾個字，第二行起才是回答。\n' > CLAUDE.local.md \
          && printf '/CLAUDE.local.md\n' >> .git/info/exclude )
    fi
    raw="$WORK.raw.jsonl"
    ( cd "$WORK" && claude -p "$prompt" --model haiku \
        --settings '{"advisorModel":""}' \
        --output-format stream-json --verbose \
        --permission-mode dontAsk --allowedTools "Read" \
        --max-budget-usd 1 --no-session-persistence \
        < /dev/null > "$raw" 2>&1 ) || echo "⚠️ ${arm}：claude 回非 0（照樣保留輸出）"
    # 原始 stream-json 不進 repo（init 有編碼過的家目錄路徑、連接器清單），只留判定要用的欄位
    jq -c --arg home "$HOME" '
        select(.type=="result")
        | {kind:"result", num_turns, total_cost_usd, models:(.modelUsage|keys),
           permission_denials:(.permission_denials|length),
           result:((.result // "") | split($home) | join("<home>"))}' "$raw" > "$OUT/probe-local-$arm.jsonl"
    rm -f "$raw"
    echo "跑完 $arm"
done
rm -rf "$WORK"

w=$(jq -r '.result' "$OUT/probe-local-with.jsonl" | sed -n '1p')
n=$(jq -r '.result' "$OUT/probe-local-without.jsonl" | grep -c 'ZEBRA-7' || true)
echo "with 第一行：${w}"
echo "without 含 ZEBRA-7 的行數：${n}"
if [ "$w" = "ZEBRA-7" ] && [ "$n" = 0 ]; then echo "✅ CLAUDE.local.md 會載入"; else echo "❌ 判定不成立"; exit 1; fi
