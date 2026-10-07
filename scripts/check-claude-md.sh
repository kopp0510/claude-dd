#!/bin/bash

# check-claude-md.sh — git pre-commit gate（block 版）
# 規則：每個含程式碼的資料夾都要有 CLAUDE.md，且該資料夾改了程式碼時 CLAUDE.md 需同批更新
# 部署：claude-dd/scripts/ → ~/.claude/scripts/（source of truth 在 claude-dd repo）
# 掛載：由 /dd-init 寫入專案 .git/hooks/pre-commit 呼叫本腳本
# 逃生口：SKIP_DOC_CHECK=1 git commit（僅供迴圈步驟 2 的檢查點 commit；最終 commit 必須全過）
# 段落起點：SKIP 不是豁免。起點記在 .git/dd-segment-base（worktree 各自一份），之後的正常
#   commit 會連「起點以來跳過檢查、到現在還沒補 CLAUDE.md」的目錄一起查
#   --start-segment  段落開始前記起點（還有欠帳時拒絕：起點往後移會把欠帳洗掉）
#   --segment-base   印出起點，給迴圈步驟 3、4、8 算整段範圍（沒記過或已失效就失敗，不印空字串）
# review 報告：專案有 docs/reviews/ 目錄時（= 採用了這個慣例），--start-segment 會要求
#   「上一段的 commit 範圍內有新增 docs/reviews/S*.md」。沒有那個目錄的專案完全不受影響。
#   目的不是讓說謊變不可能（報告內容真偽驗不出來），是把「靜默省略步驟 4」這個選項拿掉

top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "❌ check-claude-md.sh：不在 git repo 內"; exit 1; }
cd "$top" || exit 1

# 視為「程式碼」的副檔名（改動這些才要求文件同步；純文件/設定/資產不觸發）
CODE_EXT='js|jsx|ts|tsx|mjs|cjs|py|go|rs|java|kt|rb|php|sh|bash|c|h|cpp|hpp|cs|swift|sql|vue|svelte'
# 任一路徑段命中即排除的目錄
EXCLUDE_DIRS='(^|/)(\.git|node_modules|dist|build|out|coverage|vendor|\.next|\.screenshots|__pycache__|\.venv|venv|tmp|test-data|migrations)(/|$)'
# 同一組規則給 awk 用：從環境變數讀，awk 才不會再處理一次反斜線
export CODE_RE="\\.($CODE_EXT)\$" EXCLUDE_RE="$EXCLUDE_DIRS"

BASE_FILE=$(git rev-parse --git-path dd-segment-base)
case "$BASE_FILE" in /*) ;; *) BASE_FILE="$top/$BASE_FILE" ;; esac
EMPTY_TREE=$(git hash-object -t tree /dev/null)   # 還沒有任何 commit 時，起點記成空樹

# git 預設把非 ASCII 路徑加引號跳脫（"src/\344…"），副檔名就比對不到 — 列檔案一律關掉
gitq() {
    git -c core.quotePath=false "$@"
}

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

# 這個目錄（不含子目錄）在 index 裡還有沒有程式碼檔：程式碼整個刪掉或搬走了，就沒東西要寫。
# 看 index 不看工作目錄 — 只在工作目錄刪掉、沒 staged 的話，這次 commit 裡其實還在
still_has_code() {
    gitq ls-files -- ":(literal)$1" | DIR="$1" awk '
        { p = $0; if (!sub(/\/[^\/]*$/, "", p)) p = "." }
        p == ENVIRON["DIR"] && $0 ~ ENVIRON["CODE_RE"] { found = 1; exit }
        END { exit !found }'
}

# 「記下的起點 → 這次實際要用的起點」—— `owed_dirs` 與 `reviews_missing` 共用。
# stdout = 有效起點;exit 1 = 連共同祖先都沒有(**由呼叫端決定那時要怎麼辦**)。
# $1 = 警告句中間那一小段(兩處措辭不同),$2 = head sha
#
# ⚠️ **只抽「機制」不抽「政策」**(2026-10-07,S4)。三處解析起點的地方退化規則**刻意不同**:
#   ・`owed_dirs` / `reviews_missing` —— 退到共同祖先(**往寬退**,才不會把欠帳 / report 要求洗掉)
#   ・`--segment-base` —— **必須硬失敗**,它的輸出要餵 `git diff`,印空字串或錯的 base 正是地雷
#   所以 `--segment-base` **刻意不用這支**:硬套進來就得加一個關掉 fallback 的 mode 參數,
#   那只是把同一個決策搬進函式裡(S6 的 reviewer 預言過這件事)。
# ⚠️ 真正值得抽的是**會漂移的那幾行**:`merge-base --is-ancestor`、fork-point、以及那句警告 ——
#   S6 的 review 就是抓到這兩處**已經漂移**(一處退到共同祖先、另一處直接放行)。
#   「連共同祖先都沒有」的後續處置留在呼叫端,因為兩處的後果不同(一個只檢查 staged、一個跳過 review 檢查)。
resolve_fork_base() {
    local prefix=$1 head=$2 fork
    if git merge-base --is-ancestor "$base" "$head" 2>/dev/null; then
        echo "$base"
        return 0
    fi
    if fork=$(git merge-base "$base" "$head" 2>/dev/null); then
        echo "⚠️ 段落起點 $base 不在目前分支的歷史裡（換過分支或改寫過歷史？），${prefix}改從共同祖先 $fork 算起" >&2
        echo "$fork"
        return 0
    fi
    return 1
}

# 起點以來、到 HEAD 為止還沒補 CLAUDE.md 的目錄。
# 沿著 commit 的祖先關係結算：改程式碼記帳，要由看得到那段程式碼的後代 commit 更新該目錄的
# CLAUDE.md 才算補上，merge 時把各條線的欠帳合起來。所以起點再舊也不會變寬鬆，
# 平行分支上看不到那段程式碼的 CLAUDE.md 更新也抵不掉
owed_dirs() {
    local head range eff
    head=$(git rev-parse --verify -q HEAD) || return 0
    if [ "$base" = "$EMPTY_TREE" ]; then
        range=$head
    elif eff=$(resolve_fork_base "" "$head"); then
        range="$eff..$head"
    else
        echo "⚠️ 段落起點 $base 不在目前分支的歷史裡，也找不到共同祖先，這次只檢查 staged" >&2
        echo "   段落開始前重記起點：$0 --start-segment" >&2
        return 0
    fi
    # 第一份輸入：每個 commit（\001 開頭那行）新增/修改/改名的檔案；merge 用 -c，只列它自己改的
    # 第二份輸入：同一段 commit 由舊到新（父一定排在子前面），後面接著它的父 commit
    HEAD_SHA="$head" awk '
        function dir(p) { if (!sub(/\/[^\/]*$/, "", p)) p = "."; return p }
        FILENAME == ARGV[1] {
            if (substr($0, 1, 1) == "\001") c = substr($0, 2)
            else if ($0 != "") files[c] = files[c] "\n" $0
            next
        }
        {
            split("", cur)
            for (i = 2; i <= NF; i++) {
                n = split(owed[$i], a, "\n")
                for (j = 1; j <= n; j++) if (a[j] != "") cur[a[j]] = 1
            }
            n = split(files[$1], f, "\n")
            for (j = 1; j <= n; j++) if (f[j] ~ ENVIRON["CODE_RE"] && f[j] !~ ENVIRON["EXCLUDE_RE"]) cur[dir(f[j])] = 1
            for (j = 1; j <= n; j++) if (f[j] ~ /(^|\/)CLAUDE\.md$/) delete cur[dir(f[j])]
            s = ""
            for (k in cur) s = s "\n" k
            owed[$1] = s
        }
        END {
            n = split(owed[ENVIRON["HEAD_SHA"]], a, "\n")
            for (j = 1; j <= n; j++) if (a[j] != "") print a[j]
        }
    ' <(gitq log --root -c --format='%x01%H' --name-only --diff-filter=ACMR "$range") \
      <(git rev-list --reverse --topo-order --parents "$range") \
        | sort | while IFS= read -r d; do
            still_has_code "$d" && echo "$d"
        done
}

# 上一段有沒有附 review 報告(8 步迴圈的步驟 4)。
# **只在專案採用了 docs/reviews/ 慣例時才管** —— 目錄存在 = opt-in,
# 沒有這個目錄的專案(含 gate 自己的測試用拋棄式 repo)完全不受影響。
# 回 0 = 缺報告(該擋),回非 0 = 不該擋。
reviews_missing() {
    local head_sha range_base
    [ -d docs/reviews ] || return 1
    read_base || return 1                                    # 沒記過起點 = 還沒有「上一段」
    [ "$base" = "$EMPTY_TREE" ] && return 1                  # 上一段從空樹開始，視為第一段
    head_sha=$(git rev-parse --verify -q HEAD) || return 1   # 還沒有任何 commit
    [ "$base" = "$head_sha" ] && return 1                    # 起點就是 HEAD = 上一段沒有 commit

    # ⚠️ **退化規則要跟 `owed_dirs` 一致**（2026-10-07 的 review 抓到）：
    #   第一版在「起點不是祖先」時直接 `return 1` 放行 —— 於是
    #   **記好起點 → `git commit --amend` 掉起點那個 commit → 整段零報告 → 照樣放行**，
    #   而且兩個訊號都看不出 review 檢查被跳過了。amend 未 push 的 commit 是日常操作。
    #   2026-10-07（S4）起兩處共用 `resolve_fork_base`，這個一致性由結構保證、不再靠兩份各寫一次。
    if ! range_base=$(resolve_fork_base "review 檢查" "$head_sha"); then
        # 連共同祖先都沒有：照 `owed_dirs` 的做法放行，但**要講出來** ——
        # 第一版在這裡靜默通過，等於多一條繞過路徑。
        echo "⚠️ 段落起點 $base 找不到共同祖先，**這次跳過 review 報告檢查**" >&2
        echo "   （上一段的 docs/reviews/S*.md 沒有被驗到；要重新開始追蹤：rm ${BASE_FILE}）" >&2
        return 1
    fi

    # ⚠️ **`--diff-filter=A` 不是 `ACMR`**（同一輪 review 抓到）：gate 自己的訊息與四份文件
    #   都寫「有沒有**新增**」，而 `ACMR` 之下**改一個字到既有報告就過關** ——
    #   上一段的 `S1-a.md` 修個錯字，這一段零報告也能開下一段。程式碼要跟文件一致。
    # ⚠️ **`S[0-9]` 不是 `S[^/]*`**：後者讓 `SUMMARY.md` / `SPEC.md` 這種也算報告。
    #   報告檔名形如 `S1-a.md` / `S7.5-b.md` / `S10-SKIP.md`，一律 S 後面接數字。
    gitq diff --name-only --diff-filter=A "$range_base" "$head_sha" -- docs/reviews \
        | grep -qE '(^|/)S[0-9][^/]*\.md$' && return 1
    return 0
}

case "$1" in
    --start-segment)
        owed=""
        read_base && owed=$(owed_dirs)
        if [ -n "$owed" ]; then
            echo "❌ 還有 commit 跳過檢查、到現在還沒補的 CLAUDE.md，先補完再記新起點："
            printf '%s\n' "$owed" | while IFS= read -r d; do echo "  $(md_of "$d")"; done
            echo "（起點往後移會把這筆欠帳洗掉。確定要放棄追蹤：rm ${BASE_FILE}）"
            echo "  ⚠️ 那也會一併清掉「上一段要附 review 報告」的要求，而且 git 裡零痕跡" >&2
            exit 1
        fi
        if reviews_missing; then
            echo "❌ 上一段沒有附 review 報告（8 步迴圈的步驟 4），先補完再記新起點："
            echo "   範圍 ${base}..HEAD 裡沒有新增任何 docs/reviews/S*.md"
            echo ""
            echo "   兩條路，選一條："
            echo "   1. 跑步驟 4（兩個 reviewer 同一份 prompt，報告取聯集），"
            echo "      報告存 docs/reviews/S<段落>-a.md 與 -b.md，三節：派工 / 發現 / 處置"
            echo "   2. 這一段真的不需要（diff 全是資料／設定，或已被機械檢查完全覆蓋）："
            echo "      建 docs/reviews/S<段落>-SKIP.md 寫明理由，並在 commit 訊息加"
            echo "      SKIP-REVIEW: <段落> <理由> 這行 trailer"
            echo ""
            echo "   （不想採用這個慣例：刪掉 docs/reviews/ 目錄，本檢查就完全不啟用）"
            exit 1
        fi
        head_or_empty > "$BASE_FILE"
        echo "段落起點：$(cat "$BASE_FILE")"
        exit 0
        ;;
    --segment-base)
        if read_base && { [ "$base" = "$EMPTY_TREE" ] || git merge-base --is-ancestor "$base" HEAD 2>/dev/null; }; then
            echo "$base"
            exit 0
        fi
        echo "❌ 沒有可用的段落起點（沒記過，或起點已不在目前分支的歷史裡）：段落開始前先跑 $0 --start-segment" >&2
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

staged=$(gitq diff --cached --name-only --diff-filter=ACMR)
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
    # CLAUDE.md 存在且這次一起 staged：這個目錄過關
    [ -f "$md" ] && printf '%s\n' "$staged" | grep -qxF "$md" && continue

    if printf '%s\n' "$staged_dirs" | grep -qxF "$d"; then
        reason="該目錄有程式碼變更，但 CLAUDE.md 未一起 staged"
    else
        reason="段落起點之後有 commit 跳過檢查改了這裡的程式碼，CLAUDE.md 到現在還沒補"
        owed_hit=1
    fi

    if [ ! -f "$md" ]; then
        missing="$missing
  $md"
    else
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
echo "  - 不要用 --no-verify／-n 繞過：hook 整個不跑，沒記段落起點或那是最後一個 commit 時就完全漏查"
exit 1
