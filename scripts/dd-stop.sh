#!/bin/bash
# /dd-stop 的本體：暫停與恢復這個專案的 8 步開發迴圈（步驟 3–8）與 CLAUDE.md gate。
#
# 用法：dd-stop.sh on | off | status      （在專案裡任何一層跑都可以，一律在 repo 根目錄做事）
#
# 暫停有兩半，on 兩半都做、off 兩半都還原：
#   ①旗標 `git config --local dd.stopped true` —— 同目錄的 check-claude-md.sh 讀它：pre-commit 放行並記帳、
#     --start-segment 不記新起點（細節在那支的檔頭）
#   ②聲明 —— repo 根目錄 CLAUDE.local.md 裡的一段標記段。旗標在 .git/config，Claude 的 context 看不到；
#     CLAUDE.local.md 每個 session 一開始就載入、不進版控、只在這個 clone 生效，跟旗標的範圍一樣
# 暫停是延後、不是豁免：暫停期間改了程式碼而沒更新 CLAUDE.md 的目錄，off 之後 gate 照樣追（off 會先印一次清單）。
#
# exit：0 正常；1 不在 git repo；2 用法錯；3 同目錄的 gate 是不認得 dd.stopped 的舊版（on 不做事）；
#       4 CLAUDE.local.md 不是可以安全改的檔（symlink、已進版控、不是一般檔），on 不做事、旗標沒設；
#       5 off 已清掉旗標，但聲明還留在 CLAUDE.local.md（同 4 的三種情況，或標記段沒有結尾行）—— 不印「已恢復」
#
# 標記段的開頭行記兩個旗標，off 靠它們把檔案還原成 on 之前的樣子（逐位元組）：
#   created=1  檔案是 on 建的（原本不存在）：拿掉標記段之後是 0 bytes 就刪檔。原本就在的檔（含 0 bytes）一律不刪
#   sep=1      原檔結尾沒有換行，on 在標記段前面多補了一個：off 一起拿掉 —— 但標記段後面有使用者自己加的字時留著，
#              不然原檔的最後一行會跟他加的第一行黏在一起
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
GATE="$HERE/check-claude-md.sh"
LOCAL_FILE="CLAUDE.local.md"
BEGIN_PREFIX='<!-- dd-stop:begin '
END_LINE='<!-- dd-stop:end -->'

usage() {
    echo "用法：$0 on | off | status"
    echo "  on      暫停：gate 放行並記帳，Claude 只做迴圈的步驟 1、2"
    echo "  off     恢復：清掉旗標與聲明，列出暫停期間欠下、要補的 CLAUDE.md"
    echo "  status  看現在有沒有暫停"
}

case "$1" in
    on|off|status) ;;
    *) usage; exit 2 ;;
esac
[ "$#" -eq 1 ] || { usage; exit 2; }

top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "❌ dd-stop.sh：不在 git repo 內"; exit 1; }
cd "$top" || exit 1

flag_on() { [ "$(git config --local --get dd.stopped 2>/dev/null)" = "true" ]; }

# 標記段開頭行的行號（第一個）；沒有就印空字串
begin_line() {
    [ -f "$LOCAL_FILE" ] || return 0
    grep -n -F -- "$BEGIN_PREFIX" "$LOCAL_FILE" | grep -E '^[0-9]+:<!-- dd-stop:begin ' | sed -n '1s/:.*//p'
}

# CLAUDE.local.md 為什麼不能改：能改就印空字串
unsafe_reason() {
    if [ -L "$LOCAL_FILE" ]; then
        echo "它是 symlink（改它等於改連結指到的檔）"
    elif [ -e "$LOCAL_FILE" ] && [ ! -f "$LOCAL_FILE" ]; then
        echo "它不是一般檔"
    elif git ls-files --error-unmatch -- "$LOCAL_FILE" > /dev/null 2>&1; then
        echo "它已經進版控（聲明會跟著 commit 出去，協作者看到「暫停中」而他們的 gate 照擋）"
    fi
}

last_byte_is_newline() {  # $1=檔案（不是空的）
    [ -z "$(tail -c 1 "$1")" ]
}

do_on() {
    if ! grep -q 'dd\.stopped' "$GATE" 2>/dev/null; then
        echo "❌ ${GATE} 不認得暫停旗標（舊版，或檔案不在）：沒有暫停"
        echo "   到 claude-dd 的 clone 跑 git pull && ./install-dd-pipeline.sh --force，再重跑一次"
        exit 3
    fi
    reason=$(unsafe_reason)
    if [ -n "$reason" ]; then
        echo "❌ 不能把暫停聲明寫進 ${top}/${LOCAL_FILE}：${reason}。沒有暫停、旗標沒設"
        echo "   把它改成沒進版控的一般檔（或先移走）再重跑"
        exit 4
    fi

    git config --local dd.stopped true

    # 不進版控、也不動 .gitignore：只寫這個 clone 自己的 info/exclude
    if ! git check-ignore -q -- "$LOCAL_FILE"; then
        exclude=$(git rev-parse --git-path info/exclude)
        mkdir -p "$(dirname "$exclude")"
        if [ -s "$exclude" ] && ! last_byte_is_newline "$exclude"; then echo >> "$exclude"; fi
        echo "/${LOCAL_FILE}" >> "$exclude"
    fi

    if [ -z "$(begin_line)" ]; then
        created=0; sep=0
        if [ ! -e "$LOCAL_FILE" ]; then
            created=1
        elif [ -s "$LOCAL_FILE" ] && ! last_byte_is_newline "$LOCAL_FILE"; then
            sep=1
            echo >> "$LOCAL_FILE"
        fi
        today=$(date +%Y-%m-%d)
        cat >> "$LOCAL_FILE" <<EOF
${BEGIN_PREFIX}created=${created} sep=${sep} 由 /dd-stop on 寫入，/dd-stop off 會移除 -->
**8 步開發迴圈暫停中**（${today} 起，使用者用 \`/dd-stop on\` 開的）。恢復之前，這個專案只做步驟 1、2（實作與測試跑綠、commit）：
不跑步驟 3–8，不呼叫 \`dd-loop\`，不跑 \`--start-segment\`，不開新段落、不動設計文件的進度表，改程式碼時不必同批更新 CLAUDE.md。commit 照平常下，不要加 \`SKIP_DOC_CHECK=1\`、不要用 \`--no-verify\`（gate 暫停中自己會放行並記帳，恢復後再補）。
這一句優先於本專案 CLAUDE.md 的「開發流程」「CLAUDE.md 維護」、設計文件進度表的開工與標 DONE 規則、全域 CLAUDE.md §3.9 的迴圈；其他規則照舊（動手前的佐證、測試要跑綠、破壞性操作先確認）。恢復：\`/dd-stop off\`；看到 \`dd-stop.sh off\` 印出「8 步迴圈已恢復」之後，這一段作廢。
${END_LINE}
EOF
    fi

    echo "8 步迴圈已暫停（${top}）"
    echo "  gate：commit 照平常下，它會放行並記帳；暫停期間改過程式碼的目錄，恢復後要補 CLAUDE.md"
    echo "  Claude：聲明寫在 ${LOCAL_FILE}（沒進版控）。已經開著的其他對話要重開才讀得到"
    echo "  恢復：/dd-stop off"
}

# 拿掉 CLAUDE.local.md 裡的標記段。回傳 0 = 檔裡已經沒有標記段；1 = 還有、沒辦法拿（原因已印出）
remove_blocks() {
    local b e rel line created sep total tmp size
    tmp=$(git rev-parse --git-path dd-stop.tmp)
    while b=$(begin_line) && [ -n "$b" ]; do
        reason=$(unsafe_reason)
        if [ -n "$reason" ]; then
            echo "⚠️ 沒有動 ${top}/${LOCAL_FILE}：${reason}"
            return 1
        fi
        rel=$(tail -n "+$((b + 1))" "$LOCAL_FILE" | grep -n -x -F -- "$END_LINE" | sed -n '1s/:.*//p')
        if [ -z "$rel" ]; then
            echo "⚠️ ${top}/${LOCAL_FILE} 第 ${b} 行的標記段沒有結尾行（${END_LINE}）：沒有動它"
            return 1
        fi
        e=$((b + rel))
        line=$(sed -n "${b}p" "$LOCAL_FILE")
        created=0; sep=0
        case "$line" in *" created=1 "*) created=1 ;; esac
        case "$line" in *" sep=1 "*) sep=1 ;; esac
        total=$(awk 'END { print NR }' "$LOCAL_FILE")

        # b 是 1 時不可以寫 head -n 0：舊的 BSD head 把 0 當成不合法的行數
        if [ "$b" -gt 1 ]; then head -n "$((b - 1))" "$LOCAL_FILE" > "$tmp"; else : > "$tmp"; fi
        if [ "$e" -ge "$total" ]; then
            # 標記段後面沒有東西：on 補的那個換行一起拿掉
            if [ "$sep" = 1 ] && [ -s "$tmp" ]; then
                size=$(wc -c < "$tmp" | tr -d ' ')
                head -c "$((size - 1))" "$tmp" > "$tmp.2"
                mv "$tmp.2" "$tmp"
            fi
        else
            tail -n "+$((e + 1))" "$LOCAL_FILE" >> "$tmp"
        fi
        if [ "$created" = 1 ] && [ ! -s "$tmp" ]; then
            rm -f "$LOCAL_FILE"
        else
            cat "$tmp" > "$LOCAL_FILE"     # 不用 mv：保留原檔的權限
        fi
        rm -f "$tmp"
    done
    return 0
}

do_off() {
    git config --local --unset-all dd.stopped 2>/dev/null || true

    if ! remove_blocks; then
        echo "旗標已清除（gate 恢復檢查），但聲明還在 ${LOCAL_FILE}：Claude 開新對話時還會讀到「暫停中」"
        echo "手動處理後重跑：$0 off"
        exit 5
    fi

    echo "以下是 gate 的欠帳檢查（這次沒有 commit 被擋）："
    base_file=$(git rev-parse --git-path dd-segment-base)
    base_broken=0
    if [ -f "$base_file" ]; then
        case "$(git cat-file -t "$(head -n 1 "$base_file")" 2>/dev/null)" in
            commit|tree) ;;
            *) base_broken=1 ;;
        esac
    fi
    gate_ran=0
    owed_out=""
    if [ -x "$GATE" ]; then
        gate_ran=1
        # SKIP_DOC_CHECK 留在環境裡的話 gate 會直接跳過，這裡要的是真的檢查
        owed_out=$(SKIP_DOC_CHECK="" "$GATE" 2>&1) || true
    fi
    if [ -n "$owed_out" ]; then
        printf '%s\n' "$owed_out" | sed 's/^/  /'
    fi
    if [ "$gate_ran" = 0 ]; then
        echo "  ⚠️ 找不到可執行的 ${GATE}：欠帳沒有查"
    elif [ "$base_broken" = 1 ]; then
        echo "  ⚠️ 起點檔壞了，暫停期間的欠帳算不出來（${base_file} 的內容不是 commit、也不是空樹）"
        echo "     跑 ${GATE} --segment-base，照它印的處理"
    elif [ -z "$owed_out" ]; then
        echo "  沒有要補的"
    fi

    if [ -d docs/reviews ]; then
        echo "這個專案有 docs/reviews/：下次 --start-segment 之前，起點以來的 commit 要有 review 報告或 S<段落>-SKIP.md 申報"
    fi

    echo "8 步迴圈已恢復：從現在起照專案 CLAUDE.md 與全域 §3.9 跑完整 8 步。這個對話讀過的暫停聲明作廢；暫停期間開的、現在還開著的其他對話要重開"
}

do_status() {
    local f=0 s=0
    flag_on && f=1
    [ -n "$(begin_line)" ] && s=1
    if [ "$f" = 1 ]; then echo "旗標（git config --local dd.stopped）：暫停中 —— gate 放行並記帳"
    else echo "旗標（git config --local dd.stopped）：沒有暫停 —— gate 照常檢查"; fi
    if [ "$s" = 1 ]; then echo "聲明（${LOCAL_FILE} 的標記段）：在 —— Claude 開新對話時只做步驟 1、2"
    else echo "聲明（${LOCAL_FILE} 的標記段）：不在 —— Claude 照常跑 8 步"; fi
    if [ "$f" != "$s" ]; then
        echo "⚠️ 兩邊不一致（這支不自己修）：要暫停跑 $0 on，要恢復跑 $0 off"
    fi
}

case "$1" in
    on) do_on ;;
    off) do_off ;;
    status) do_status ;;
esac
