#!/bin/bash
# ADHD output style 的行為驗收：同一組 prompt，ADHD 與 default 兩臂各跑 n=2，原始輸出去識別後存 out/。
# 判定交給同目錄的 check.sh（判準寫死在那支，跑之前就定好）。
#
# 用法：docs/measurements/2026-10-29-adhd-style/run.sh <拋棄式工作目錄>
#   工作目錄要在 repo 與家目錄的 CLAUDE.md 鏈之外（例如 session scratchpad 底下），會被清空重建
# 前提：~/.claude/output-styles/adhd.md 已部署（./install-dd-pipeline.sh --force），claude ≥ 2.1.269
# 花費：每發上限 US$2，共 8 發
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
WORK="${1:?用法：run.sh <拋棄式工作目錄>}"
OUT="$HERE/out"
mkdir -p "$OUT"

prompt_1='讀 notes.txt，把裡面全部的項目列出來，再告訴我要怎麼把它們整理成一份 Markdown 待辦清單檔（我自己動手）。不要改任何檔案，也不要執行 shell 指令。'
prompt_2='把 greet.txt 裡的 hello 改成 hi。不要執行 shell 指令。做完照你的規則回報。'

for arm in ADHD default; do
    for p in 1 2; do
        for rep in 1 2; do
            rm -rf "$WORK"
            mkdir -p "$WORK"
            ( cd "$WORK" && git init -q \
              && printf '%s\n' 買牛奶 繳電費 回覆房東 預約牙醫 修腳踏車 寄包裹 澆花 > notes.txt \
              && printf 'hello world\n' > greet.txt )
            if [ "$p" = 1 ]; then prompt=$prompt_1; else prompt=$prompt_2; fi
            name="$arm-p$p-r$rep"
            printf '%s\n' "$prompt" > "$OUT/p$p.prompt.txt"
            ( cd "$WORK" && claude -p "$prompt" \
                --settings "{\"outputStyle\":\"$arm\",\"advisorModel\":\"\"}" \
                --output-format stream-json --verbose \
                --permission-mode dontAsk --allowedTools "Read Edit Glob Grep" \
                --max-budget-usd 2 --no-session-persistence \
                < /dev/null > "$OUT/$name.raw.jsonl" 2>&1 ) || echo "⚠️ ${name}：claude 回非 0（照樣保留輸出）"
            # 去識別：工作目錄與家目錄換成佔位符
            sed -e "s#$WORK#<work>#g" -e "s#$(cd "$WORK" && pwd -P)#<work>#g" -e "s#$HOME#<home>#g" \
                "$OUT/$name.raw.jsonl" > "$OUT/$name.jsonl"
            rm -f "$OUT/$name.raw.jsonl"
            echo "跑完 $name"
        done
    done
done
rm -rf "$WORK"
