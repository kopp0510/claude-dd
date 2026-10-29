#!/bin/bash
# ADHD output style 的行為驗收：同一組 prompt，ADHD 與 default 兩臂各跑 n=2，每發只留判定要用的欄位存 out/。
# 判定交給同目錄的 check.sh（判準寫死在那支，跑之前就定好）。
#
# 用法：docs/measurements/2026-10-29-adhd-style/run.sh <拋棄式工作目錄>
#   工作目錄要在 repo 與家目錄的 CLAUDE.md 鏈之外（例如 session scratchpad 底下）。
#   它必須不存在，或是本腳本之前建的（裡面有 .adhd-accept-work 標記）；否則拒跑，因為每發之前會整個刪掉重建
# 前提：~/.claude/output-styles/adhd.md 已部署（./install-dd-pipeline.sh --force）
# 花費：每發上限 US$2，共 8 發
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
WORK="${1:?用法：run.sh <拋棄式工作目錄>}"
OUT="$HERE/out"
MARK=.adhd-accept-work

if [ -e "$WORK" ] && [ ! -f "$WORK/$MARK" ]; then
    echo "❌ ${WORK} 已存在且不是本腳本建的（沒有 ${MARK}），拒跑：每發之前會整個刪掉它" >&2
    exit 1
fi
mkdir -p "$OUT"

prompt_1='讀 notes.txt，把裡面全部的項目列出來，再告訴我要怎麼把它們整理成一份 Markdown 待辦清單檔（我自己動手）。不要改任何檔案，也不要執行 shell 指令。'
prompt_2='把 greet.txt 裡的 hello 改成 hi。不要執行 shell 指令。做完照你的規則回報。'
printf '%s\n' "$prompt_1" > "$OUT/p1.prompt.txt"
printf '%s\n' "$prompt_2" > "$OUT/p2.prompt.txt"

for arm in ADHD default; do
    for p in 1 2; do
        for rep in 1 2; do
            rm -rf "$WORK"
            mkdir -p "$WORK"
            touch "$WORK/$MARK"
            ( cd "$WORK" && git init -q \
              && printf '%s\n' 買牛奶 繳電費 回覆房東 預約牙醫 修腳踏車 寄包裹 澆花 > notes.txt \
              && printf 'hello world\n' > greet.txt )
            real=$(cd "$WORK" && pwd -P)
            if [ "$p" = 1 ]; then prompt=$prompt_1; else prompt=$prompt_2; fi
            name="$arm-p$p-r$rep"
            raw="$WORK.raw.jsonl"
            ( cd "$WORK" && claude -p "$prompt" \
                --settings "{\"outputStyle\":\"$arm\",\"advisorModel\":\"\"}" \
                --output-format stream-json --verbose \
                --permission-mode dontAsk --allowedTools "Read Edit Glob Grep" \
                --max-budget-usd 2 --no-session-persistence \
                < /dev/null > "$raw" 2>&1 ) || echo "⚠️ ${name}：claude 回非 0（照樣保留輸出）"
            # 原始 stream-json 不進 repo（init 裡有編碼過的家目錄路徑、連接器清單、plugin 路徑），只留判定要用的欄位。
            # 回覆文字裡的路徑先換實體路徑再換傳入路徑（傳 /tmp/… 時實體路徑是 /private/tmp/…，順序反了會留下半截）
            jq -c --arg real "$real" --arg work "$WORK" --arg home "$HOME" '
                select((.type=="system" and .subtype=="init") or .type=="result")
                | if .type=="system" then {kind:"init", output_style}
                  else {kind:"result", num_turns, total_cost_usd,
                        permission_denials:(.permission_denials|length),
                        result:((.result // "") | split($real) | join("<work>")
                                | split($work) | join("<work>") | split($home) | join("<home>"))}
                  end' "$raw" > "$OUT/$name.jsonl"
            rm -f "$raw"
            echo "跑完 $name"
        done
    done
done
rm -rf "$WORK"
