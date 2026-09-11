#!/bin/bash

# check-claude-md.sh — git pre-commit gate（block 版）
# 規則：每個含程式碼的資料夾都要有 CLAUDE.md，且該資料夾改了程式碼時 CLAUDE.md 需同批更新
# 部署：claude-dd/scripts/ → ~/.claude/scripts/（source of truth 在 claude-dd repo）
# 掛載：由 /dd-init 寫入專案 .git/hooks/pre-commit 呼叫本腳本
# 逃生口：SKIP_DOC_CHECK=1 git commit（僅供迴圈步驟 2 的檢查點 commit；最終 commit 必須全過）
# 段落起點：SKIP 不是豁免。起點記在 .git/dd-segment-base（worktree 各自一份），之後的正常
#   commit 會連「起點以來跳過檢查、到現在還沒補 CLAUDE.md」的目錄一起查
#   --start-segment  段落開始前記起點（還有欠帳時拒絕：起點往後移會把欠帳洗掉）
#   --segment-base   印出起點，給迴圈步驟 3、4、8 算整段範圍（沒記過就失敗，不印空字串）

top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "❌ check-claude-md.sh：不在 git repo 內"; exit 1; }
cd "$top" || exit 1

# 視為「程式碼」的副檔名（改動這些才要求文件同步；純文件/設定/資產不觸發）
CODE_EXT='js|jsx|ts|tsx|mjs|cjs|py|go|rs|java|kt|rb|php|sh|bash|c|h|cpp|hpp|cs|swift|sql|vue|svelte'
# 任一路徑段命中即排除的目錄
EXCLUDE_DIRS='(^|/)(\.git|node_modules|dist|build|out|coverage|vendor|\.next|\.screenshots|__pycache__|\.venv|venv|tmp|test-data|migrations)(/|$)'

BASE_FILE=$(git rev-parse --git-path dd-segment-base)
case "$BASE_FILE" in /*) ;; *) BASE_FILE="$top/$BASE_FILE" ;; esac
EMPTY_TREE=$(git hash-object -t tree /dev/null)   # 還沒有任何 commit 時，起點記成空樹

# stdin 的檔案清單 → 含程式碼的目錄（去重）
code_dirs_of() {
    grep -E "\.($CODE_EXT)\$" \
        | grep -Ev "$EXCLUDE_DIRS" \
        | while IFS= read -r f; do dirname "$f"; done \
        | sort -u
}

md_of() {
    if [ "$1" = "." ]; then echo "CLAUDE.md"; else echo "$1/CLAUDE.md"; fi
}

head_or_empty() {
    git rev-parse --verify -q HEAD || echo "$EMPTY_TREE"
}

# 讀起點到 $base；檔案不存在、或內容不是 commit / 空樹就失敗
read_base() {
    [ -f "$BASE_FILE" ] || return 1
    base=$(head -n 1 "$BASE_FILE")
    case "$(git cat-file -t "$base" 2>/dev/null)" in
        commit|tree) return 0 ;;
    esac
    return 1
}

# 起點以來「改了程式碼、之後沒有 commit 更新該目錄 CLAUDE.md」的目錄。
# 照 commit 先後結算：程式碼改動記成欠帳，同一個或更晚的 commit 更新 CLAUDE.md 才算補上。
# 所以起點再舊也不會變寬鬆 — 較早的 CLAUDE.md 更新抵不掉之後才跳過檢查的程式碼
owed_dirs() {
    local range line files="" owed="" md
    if [ "$base" = "$EMPTY_TREE" ]; then
        git rev-parse --verify -q HEAD >/dev/null || return 0
        range=HEAD
    elif git merge-base --is-ancestor "$base" HEAD 2>/dev/null; then
        range="$base..HEAD"
    else
        echo "⚠️ 段落起點 $base 不在目前分支的歷史裡（換過分支或改寫過歷史？），這次只檢查 staged" >&2
        echo "   段落開始前重記起點：check-claude-md.sh --start-segment" >&2
        return 0
    fi
    # 每個 commit 以一行 \001 開頭，後面是它改到的檔案；結尾多補一行 \001 結算最後一個 commit
    while IFS= read -r line; do
        case "$line" in
            $'\001')
                owed=$(printf '%s\n%s\n' "$owed" "$(printf '%s\n' "$files" | code_dirs_of)" | grep -v '^$' | sort -u)
                md=$(printf '%s\n' "$files" | grep -E '(^|/)CLAUDE\.md$' | while IFS= read -r f; do dirname "$f"; done)
                [ -n "$md" ] && owed=$(printf '%s\n' "$owed" | grep -vxF "$md")
                files=""
                ;;
            ?*)
                files="$files
$line"
                ;;
        esac
    done <<EOF
$(git log --reverse --format='%x01' --name-only --diff-filter=ACMR "$range"; printf '\001\n')
EOF
    printf '%s\n' "$owed" | grep -v '^$'
}

case "$1" in
    --start-segment)
        if read_base; then
            owed=$(owed_dirs)
            if [ -n "$owed" ]; then
                echo "❌ 還有 commit 跳過檢查、到現在還沒補的 CLAUDE.md，先補完再記新起點："
                printf '%s\n' "$owed" | while IFS= read -r d; do echo "  $(md_of "$d")"; done
                echo "（起點往後移會把這筆欠帳洗掉。確定要放棄追蹤：rm $BASE_FILE）"
                exit 1
            fi
        fi
        head_or_empty > "$BASE_FILE"
        echo "段落起點：$(cat "$BASE_FILE")"
        exit 0
        ;;
    --segment-base)
        if read_base; then
            echo "$base"
            exit 0
        fi
        echo "❌ 還沒記段落起點：段落開始前先跑 check-claude-md.sh --start-segment" >&2
        exit 1
        ;;
esac

if [ "$SKIP_DOC_CHECK" = "1" ]; then
    # 忘了記起點也追得到：第一個跳過檢查的 commit 自動記下（已有起點就不動，舊起點不會變寬鬆）
    if ! read_base; then
        head_or_empty > "$BASE_FILE"
        echo "CLAUDE.md gate 已跳過；記下段落起點 $(cat "$BASE_FILE")，之後的正常 commit 會補查這段跳過的目錄"
    fi
    exit 0
fi

staged=$(git diff --cached --name-only --diff-filter=ACMR)
staged_dirs=$(printf '%s\n' "$staged" | code_dirs_of)
owed=""
read_base && owed=$(owed_dirs)
[ -z "$staged_dirs" ] && [ -z "$owed" ] && exit 0

missing=""
stale=""
owed_hit=0

while IFS= read -r d; do
    [ -z "$d" ] && continue
    md=$(md_of "$d")
    in_staged=0
    printf '%s\n' "$staged_dirs" | grep -qxF "$d" && in_staged=1
    # 欠帳的目錄後來整個刪掉了：沒東西要寫
    [ "$in_staged" = 0 ] && [ ! -d "$d" ] && continue

    if [ ! -f "$md" ]; then
        missing="$missing
  $md"
        [ "$in_staged" = 0 ] && owed_hit=1
    elif ! printf '%s\n' "$staged" | grep -qxF "$md"; then
        if [ "$in_staged" = 1 ]; then
            reason="該目錄有程式碼變更，但 CLAUDE.md 未一起 staged"
        else
            reason="段落起點之後有 commit 跳過檢查改了這裡的程式碼，CLAUDE.md 到現在還沒補"
            owed_hit=1
        fi
        stale="$stale
  ${md}（${reason}）"
    fi
done <<EOF
$(printf '%s\n%s\n' "$staged_dirs" "$owed" | sort -u)
EOF

[ -z "$missing" ] && [ -z "$stale" ] && exit 0

echo "❌ CLAUDE.md gate：commit 已擋下"
if [ -n "$missing" ]; then
    echo ""
    echo "缺少 CLAUDE.md 的目錄：$missing"
    echo ""
    echo "→ AI agent 執行時：不要問使用者、不要建空殼。讀取該目錄全部檔案後，"
    echo "  自行產生 CLAUDE.md（內容：該層職責一句話、關鍵檔案與用途、此層慣例/約束、"
    echo "  與上層模組的關係），git add 後重新 commit。"
fi
if [ -n "$stale" ]; then
    echo ""
    echo "未同步更新：$stale"
    echo ""
    echo "→ AI agent 執行時：比對本次 staged 的程式碼變更，把受影響的段落更新進該"
    echo "  CLAUDE.md（新增的檔案/端點/元件要列入；行為改變要改描述），並逐層檢查"
    echo "  上層 CLAUDE.md 是否也需堆疊更新，git add 後重新 commit。"
fi
if [ "$owed_hit" = 1 ]; then
    echo ""
    echo "段落起點：$base — 起點以來跳過檢查的 commit 也算在內，這次沒改程式碼也照樣擋（SKIP 不是豁免）"
    echo "  看這段改了什麼：git diff $base -- <目錄>"
fi
echo ""
echo "其他處理方式："
echo "  - 檢查點 commit（迴圈步驟 2）：SKIP_DOC_CHECK=1 git commit ...（最終 commit 必須全過）"
exit 1
