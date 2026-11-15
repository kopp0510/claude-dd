#!/bin/bash
# 根目錄 CLAUDE.md 的大小上限（本 repo 自用，不部署）。說明與已知的繞過路徑見同目錄 CLAUDE.md。
#
# 用法：
#   claude-md-size.sh --staged   pre-commit 用：看 index 那一版。這次 commit 讓它變大、而且超過上限才擋
#   claude-md-size.sh            CI 用：看工作目錄那一份。超過上限就不通過
#
# 上限寫在 scripts/githooks/claude-md-max-bytes。取哪一版的數字：
#   1. 最新的 v* tag 那一版有這個檔 → 用它（在 commit 裡調高不會生效，要等發下一版）
#   2. 否則（沒有 v* tag，或最新的 tag 還沒有這個檔）：
#      --staged 讀 HEAD 那一版；HEAD 也沒有才讀 index（加進上限檔的那個 commit 自己要過得去）
#      不帶參數讀工作目錄那一份
# 第 2 種情況擋不住「先單獨 commit 調高、下一個 commit 再加字」，CI 也擋不住同一次 push 裡的調高，
# 所以每次取上限都印出取自哪裡。取不到上限或內容不合法一律不通過。
DOC=CLAUDE.md
LIMIT_FILE=scripts/githooks/claude-md-max-bytes

case "$#:$1" in
    0:)         mode=worktree ;;
    1:--staged) mode=staged ;;
    *)          echo "用法：$0 [--staged]" >&2; exit 2 ;;
esac

top=$(git rev-parse --show-toplevel) || exit 2
cd "$top" || exit 2

# stdin：上限檔的內容。去掉 # 開頭的行與空行之後剛好剩一行整數（最多 12 位）才印出來、回 0
# 12 位的限制：放不進整數的數字，[ -gt ] 會報錯、回 2，if 把它當成「沒超過」而放行
# （/bin/bash 3.2.57 實測：[ 100 -gt 123456789012345678901234567890 ] 印 integer expression expected、回 2）
parse_limit() {
    local body
    body=$(grep -v '^#' | grep -v '^[[:space:]]*$')
    case "$body" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "${#body}" -le 12 ] || return 1
    printf '%s\n' "$body"
}

# $1 = staged / worktree。設定 limit 與 src；取不到就印原因、回 1
resolve_limit() {
    local tag why raw
    # 取最新的版本 tag 用 --sort=-v:refname（跟 ci.yml「CHANGELOG 已發布區塊不可改動」同一個寫法）：
    # 不排序拿到的是最舊的，照字典序排 v0.0.10 會輸給 v0.0.2
    tag=$(git tag --list 'v*' --sort=-v:refname | head -1)
    if [ -n "$tag" ]; then
        why="${tag} 還沒有這個檔，發下一版之後改以 tag 為準"
    else
        why="還沒有 v* tag"
    fi
    if [ -n "$tag" ] && git cat-file -e "${tag}:${LIMIT_FILE}" 2>/dev/null; then
        src="取自 ${tag}"
        raw=$(git show "${tag}:${LIMIT_FILE}")
    elif [ "$1" = staged ] && git cat-file -e "HEAD:${LIMIT_FILE}" 2>/dev/null; then
        # HEAD 排在 index 前面：同一個 commit 把上限調高、又把 CLAUDE.md 加大，調高的那一半不算
        src="取自 HEAD：${why}"
        raw=$(git show "HEAD:${LIMIT_FILE}")
    elif [ "$1" = staged ] && git cat-file -e ":${LIMIT_FILE}" 2>/dev/null; then
        # HEAD 還沒有上限檔：加進上限檔的那個 commit 自己要過得去
        src="取自 index：${why}"
        raw=$(git show ":${LIMIT_FILE}")
    elif [ "$1" = worktree ] && [ -f "$LIMIT_FILE" ]; then
        src="取自工作目錄：${why}"
        raw=$(cat "$LIMIT_FILE")
    else
        echo "❌ 根目錄 ${DOC} 大小上限：找不到上限檔 ${LIMIT_FILE}（${why}）"
        return 1
    fi
    if ! limit=$(printf '%s\n' "$raw" | parse_limit); then
        echo "❌ 根目錄 ${DOC} 大小上限：上限檔內容不合法（${src}）。# 開頭的行與空行不算，其餘要剛好一行整數"
        return 1
    fi
}

advice() {
    echo "   1. 新內容改寫進它在講的那個目錄的 CLAUDE.md（scripts/、tests/、docs/measurements/ 這類）或 DD_PIPELINE_ARCHITECTURE.md，根目錄不加"
    echo "   2. 一定要放根目錄：先把一塊既有的內容原文搬到上面那些地方、根目錄留一句指路，空出位置"
    echo "   不要為了過關把既有的句子縮短：縮短最容易把條件改掉"
    echo "   調高上限（${LIMIT_FILE}）之前先問使用者；有帶這個檔的 v* tag 之後，改了要等發下一版才生效"
}

if [ "$mode" = staged ]; then
    new=$(git cat-file -s ":${DOC}" 2>/dev/null) || new=0
    old=$(git cat-file -s "HEAD:${DOC}" 2>/dev/null) || old=0
    # 這次 commit 沒有讓它變大：不查（已經超過上限時，變小的 commit 也要過得去）
    [ "$new" -le "$old" ] && exit 0
    resolve_limit staged || exit 1
    echo "根目錄 ${DOC} ${old} → ${new} bytes，上限 ${limit}（${src}）"
    if [ "$new" -gt "$limit" ]; then
        echo "❌ 根目錄 ${DOC} 大小上限：commit 已擋下"
        advice
        exit 1
    fi
    exit 0
fi

if [ ! -f "$DOC" ]; then
    echo "❌ 根目錄 ${DOC} 大小上限：找不到 ${DOC}"
    exit 1
fi
new=$(( $(wc -c < "$DOC") ))   # macOS 的 wc 輸出前面有空白
resolve_limit worktree || exit 1
rc=0
if [ "$new" -gt "$limit" ]; then
    echo "❌ 根目錄 ${DOC} ${new} bytes，超過上限 ${limit}（${src}）"
    advice
    rc=1
else
    echo "✅ 根目錄 ${DOC} ${new} bytes，上限 ${limit}（${src}）"
fi
# 工作目錄那一份會是下一版的基準：不管這次的上限取自哪裡，它都要解析得出來
if [ -f "$LIMIT_FILE" ] && next=$(parse_limit < "$LIMIT_FILE"); then
    if [ "$next" != "$limit" ]; then
        echo "   工作目錄的上限檔寫 ${next}，發下一版之後才生效"
    fi
else
    echo "❌ 根目錄 ${DOC} 大小上限：工作目錄的 ${LIMIT_FILE} 不存在或內容不合法（它會是下一版的基準）"
    rc=1
fi
exit $rc
