#!/bin/bash

# check-claude-md.sh — git pre-commit gate（block 版）
# 規則：每個含程式碼的資料夾都要有 CLAUDE.md，且該資料夾改了程式碼時 CLAUDE.md 需同批更新
# 部署：claude-dd/scripts/ → ~/.claude/scripts/（source of truth 在 claude-dd repo）
# 掛載：由 /dd-init 寫入專案 .git/hooks/pre-commit 呼叫本腳本
# 逃生口：SKIP_DOC_CHECK=1 git commit（僅供迴圈步驟 2 的檢查點 commit；最終 commit 必須全過）

[ "$SKIP_DOC_CHECK" = "1" ] && exit 0

# 視為「程式碼」的副檔名（改動這些才要求文件同步；純文件/設定/資產不觸發）
CODE_EXT='js|jsx|ts|tsx|mjs|cjs|py|go|rs|java|kt|rb|php|sh|bash|c|h|cpp|hpp|cs|swift|sql|vue|svelte'
# 任一路徑段命中即排除的目錄
EXCLUDE_DIRS='(^|/)(\.git|node_modules|dist|build|out|coverage|vendor|\.next|\.screenshots|__pycache__|\.venv|venv|tmp|test-data|migrations)(/|$)'

staged=$(git diff --cached --name-only --diff-filter=ACMR)
[ -z "$staged" ] && exit 0

code_dirs=$(printf '%s\n' "$staged" \
    | grep -E "\.($CODE_EXT)\$" \
    | grep -Ev "$EXCLUDE_DIRS" \
    | while IFS= read -r f; do dirname "$f"; done \
    | sort -u)
[ -z "$code_dirs" ] && exit 0

missing=""
stale=""

while IFS= read -r d; do
    if [ "$d" = "." ]; then
        md="CLAUDE.md"
    else
        md="$d/CLAUDE.md"
    fi

    if [ ! -f "$md" ]; then
        missing="$missing
  $md"
    elif ! printf '%s\n' "$staged" | grep -qxF "$md"; then
        stale="$stale
  ${md}（該目錄有程式碼變更，但 CLAUDE.md 未一起 staged）"
    fi
done <<EOF
$code_dirs
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
echo ""
echo "其他處理方式："
echo "  - 檢查點 commit（迴圈步驟 2）：SKIP_DOC_CHECK=1 git commit ...（最終 commit 必須全過）"
exit 1
