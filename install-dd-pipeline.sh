#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# DD Pipeline 安裝程式
# 基於多種 Driven Development 方法論的自動化開發流程
# ═══════════════════════════════════════════════════════════════════

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 符號定義
CHECK="✅"
CROSS="❌"
WARN="⚠️"
INFO="📋"
ROCKET="🚀"

# 路徑定義
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # 本 repo 根目錄（部署來源）
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
TEMPLATES_DIR="$CLAUDE_DIR/templates/dd"
AGENTS_DIR="$CLAUDE_DIR/agents"
SKILLS_DIR="$CLAUDE_DIR/skills"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"

# Skills 部署清單（使用率盤點制：只保留實證常用的元件，其餘刪除、git 歷史可回溯）
# 註：原 misc 桶（11 skills / 5 NS commands）與 deprecated 桶（34 skills /
# 17 agents / 6 dd 指令 / 13 NS commands）均已於 2026-08-04 刪除。
PROMOTED_SKILLS=(
    "code-simplifier"
    "design-brainstorm"
    "frontend-design"
    "review"
    "self-improving-agent"
    "task-planner"
    "tech-diagram-gif"
    "verification-gate"
    "worktree-manager"
    "writing-great-skills"   # user-invoked（disable-model-invocation），零 context 稅
)

# 部署集合
BUILTIN_SKILLS=("${PROMOTED_SKILLS[@]}")
ALL_SKILLS=("${PROMOTED_SKILLS[@]}")

# Agents（同 skills 的盤點基準）
# - PROMOTED：實證用過（senior-devops、security-auditor）+ 2 個官方 agent 本地備份
#   （code-simplifier、code-reviewer；plugin 未裝時的 fallback，確保離線/新環境可用）
PROMOTED_AGENTS=(
    "code-simplifier"
    "code-reviewer"
    "senior-devops"
    "security-auditor"
)

BUILTIN_AGENTS=("${PROMOTED_AGENTS[@]}")
ALL_AGENTS=("${PROMOTED_AGENTS[@]}")

# DD commands（平面 .md 檔案）
# 2026-07-23 重整：dd-init 改造為「6 步開發迴圈」初始化；原多階段 pipeline
# （dd-start/arch/approve/dev/test/dx）已於 2026-08-04 刪除，見 git 歷史
DD_COMMANDS=(
    "dd-init"
)

ALL_DD_COMMANDS=("${DD_COMMANDS[@]}")

# 命名空間 commands（目錄型）
NS_COMMANDS=(
    "workflow-review"
)

ALL_NS_COMMANDS=("${NS_COMMANDS[@]}")

# 輔助腳本（部署到 ~/.claude/scripts/；check-claude-md.sh 由 /dd-init 掛進專案 pre-commit）
DD_SCRIPTS=(
    "check-claude-md.sh"
)

# 必要的 MCP
REQUIRED_MCP=(
    "playwright"
)

# 可選的 MCP
OPTIONAL_MCP=(
    "context7"
    "sequential-thinking"
    "serena"
    "cipher"
    "zeabur"
    "google-docs"
    "googleDrive"
    "claude-mem"
)

# 官方 Plugins
OFFICIAL_PLUGINS=(
    "claude-md-management"
)

PLUGINS_MARKETPLACE="claude-plugins-official"

# 輔助函數
print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}${INFO} 步驟 $1：$2${NC}"
}

print_success() {
    echo -e "├── $1: ${GREEN}${CHECK}${NC}"
}

print_fail() {
    echo -e "├── $1: ${RED}${CROSS}${NC}"
}

print_warn() {
    echo -e "├── $1: ${YELLOW}${WARN}${NC}"
}

print_last_success() {
    echo -e "└── $1: ${GREEN}${CHECK}${NC}"
}

print_last_fail() {
    echo -e "└── $1: ${RED}${CROSS}${NC}"
}

# 檢查指令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 檢查目錄是否存在
dir_exists() {
    [ -d "$1" ]
}

# 檢查檔案是否存在
file_exists() {
    [ -f "$1" ]
}

# 互動詢問（read 的安全包裝）：非互動環境（curl | bash、CI）下 read 遇 EOF
# 會在 set -e 之下中止整個腳本，故互動詢問一律經此函式 — 無 TTY 時採用預設值
# 結果放在 REPLY
ask() {
    local prompt="$1" default="$2"
    if [ -t 0 ]; then
        read -r -p "$prompt" REPLY || REPLY=""
        REPLY="${REPLY:-$default}"
    else
        REPLY="$default"
        echo "${prompt}${default}（非互動環境，採用預設值）"
    fi
}

# 覆蓋既有部署前先備份到 ~/.claude/backups/（每次執行共用一個備份目錄），
# 防止使用者對已部署檔案的本地修改被無聲抹除
BACKUP_ROOT=""
backup_before_overwrite() {
    local category="$1" target="$2"
    [ -e "$target" ] || return 0
    if [ -z "$BACKUP_ROOT" ]; then
        BACKUP_ROOT="$CLAUDE_DIR/backups/pre-install-$(date +%Y-%m-%d-%H%M%S)"
    fi
    mkdir -p "$BACKUP_ROOT/$category"
    cp -r "$target" "$BACKUP_ROOT/$category/"
}

print_backup_notice() {
    if [ -n "$BACKUP_ROOT" ]; then
        echo -e "${YELLOW}📦 覆蓋前的舊版已備份至：${BACKUP_ROOT}（確認無需保留後可刪）${NC}"
        echo ""
    fi
}

# 用 jq 就地改寫 JSON 檔：先寫暫存檔，成功才回寫原檔
# 回寫用 cat 而非 mv，保留原檔 inode / 權限 / symlink 身分（settings.json 可能被
# dotfiles 管理器 symlink 到別處，mv 會把它換成獨立實體檔且權限變 0600）
# 失敗（JSON 損毀等）回傳 1 且原檔不動，呼叫端須用 `|| ...` 接住，以免 set -e 中止安裝
# 用法：jq_inplace <檔案> <jq 參數...>
jq_inplace() {
    local file="$1"
    shift
    local tmp
    tmp=$(mktemp)
    if jq "$@" "$file" > "$tmp"; then
        cat "$tmp" > "$file" || { rm -f "$tmp"; return 1; }
        rm -f "$tmp"
    else
        rm -f "$tmp"
        return 1
    fi
}

# python3 版就地改寫：讀入 JSON 為 data，執行變更敘述後寫回原檔（open('w') 截斷
# 寫入，同樣保留 inode / symlink）。變更敘述透過 env 取用 KEY=VAL 參數。
# 呼叫端撰寫變更敘述時：用單引號或 quoted heredoc（避免 shell 先展開 $），
# 且首行不得縮排（敘述會原樣插入 python 原始碼頂層）
# 失敗（JSON 損毀等）回傳非零且原檔不動（載入失敗即退出，不會走到寫入）
py_inplace() {
    local file="$1" mutate="$2"
    shift 2
    env JSON_FILE="$file" "$@" python3 -c "
import json, os
env = os.environ
path = env['JSON_FILE']
with open(path) as f:
    data = json.load(f)
$mutate
with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
}

# 就地改寫 JSON 的統一入口：有 jq 用 jq，否則用 python3（install_plugins 已保證其一存在）
# KEY=VAL 參數同時提供給 jq（--arg KEY VAL）與 python（環境變數），兩邊用同名取值
# 失敗回傳非零且原檔不動，呼叫端須以 `|| ...` 接住，以免 set -e 中止安裝
# 用法：json_edit <檔案> <jq filter> <python 變更敘述> [KEY=VAL ...]
json_edit() {
    local file="$1" jq_filter="$2" py_mutate="$3"
    shift 3
    if command_exists "jq"; then
        local jq_args=() kv
        for kv in "$@"; do
            jq_args+=(--arg "${kv%%=*}" "${kv#*=}")
        done
        jq_inplace "$file" "${jq_args[@]}" "$jq_filter"
    else
        py_inplace "$file" "$py_mutate" "$@"
    fi
}

# 顯示使用說明
show_help() {
    echo "DD Pipeline 安裝程式"
    echo ""
    echo "用法: $0 [選項]"
    echo ""
    echo "選項:"
    echo "  --check             只檢查環境（不安裝）"
    echo "  --force             強制重新安裝（覆蓋現有檔案）"
    echo "  --commands-only     只安裝 DD Commands（不安裝 skills）"
    echo "  --uninstall         移除 DD Pipeline（本 repo 部署過的項目）"
    echo "  --yes               跳過 --uninstall 的確認詢問（供自動化使用；"
    echo "                      其餘互動詢問於非互動環境一律採預設值）"
    echo "  --update            更新 skills/agents 到最新版"
    echo "  --help              顯示此說明"
    echo ""
    echo "安裝內容："
    echo "  - ${#PROMOTED_SKILLS[@]} 個 Skills（實證常用）"
    echo "  - ${#PROMOTED_AGENTS[@]} 個 Agents（2 個實證 + 2 個官方備份）"
    echo "  - ${#OFFICIAL_PLUGINS[@]} 個官方 Plugin（CLAUDE.md 管理工具，巢狀 CLAUDE.md 維護依賴）"
    echo "  - ${#DD_COMMANDS[@]} 個 DD Command（dd-init：6 步開發迴圈初始化）+ ${#NS_COMMANDS[@]} 個命名空間 Command"
    echo "  - 1 個全域 CLAUDE.md（互動式比對覆蓋）"
    echo ""
}

# 檢查基礎環境
check_environment() {
    if [ "${COMMANDS_ONLY:-false}" = true ]; then
        print_step "1/2" "檢查基礎環境"
    else
        print_step "1/7" "檢查基礎環境"
    fi

    local all_ok=true

    # 檢查 Claude Code CLI
    if command_exists "claude"; then
        local cc_version
        cc_version=$(claude --version 2>/dev/null | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)
        if [ -n "$cc_version" ]; then
            print_success "Claude Code CLI (v$cc_version)"
            # 原生 opt-in 功能最低版本：Workflow ≥ 2.1.154
            local min_native="2.1.154"
            if [ "$(printf '%s\n%s\n' "$min_native" "$cc_version" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" != "$min_native" ]; then
                echo -e "│   ${YELLOW}⚠ 版本 < ${min_native}：原生 Workflow/Worktree 等 opt-in 功能不可用（pipeline 預設流程不受影響）${NC}"
            fi
        else
            print_success "Claude Code CLI（版本無法解析，略過版本檢查）"
        fi
    else
        print_fail "Claude Code CLI"
        all_ok=false
    fi

    # 檢查 Node.js
    if command_exists "node"; then
        print_success "Node.js ($(node -v))"
    else
        print_fail "Node.js"
        all_ok=false
    fi

    # 檢查 Git
    if command_exists "git"; then
        print_success "Git"
    else
        print_fail "Git"
        all_ok=false
    fi

    # 檢查 Bash
    if command_exists "bash"; then
        print_success "Bash"
    else
        print_fail "Bash"
        all_ok=false
    fi

    # 檢查 ffmpeg（可選：tech-diagram-gif 的 GIF 匯出用；缺少時該 skill 退化交付 SVG）
    if command_exists "ffmpeg"; then
        print_last_success "ffmpeg（可選，GIF 匯出）"
    else
        echo -e "└── ${YELLOW}⚠ ffmpeg 未安裝（可選）：tech-diagram-gif 將退化交付 SVG${NC}"
        echo -e "    ${YELLOW}安裝：macOS \`brew install ffmpeg\`；Debian/Ubuntu \`sudo apt install ffmpeg\`${NC}"
    fi

    echo ""

    if [ "$all_ok" = false ]; then
        echo -e "${RED}基礎環境檢查失敗，請先安裝缺少的工具${NC}"
        exit 1
    fi
}

# 檢查內建 Skills（僅檢查，不安裝）
check_builtin_skills() {
    print_step "2/7" "檢查內建 Skills"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local count=${#BUILTIN_SKILLS[@]}
    local i=0
    local installed=0
    local missing=0

    for skill in "${BUILTIN_SKILLS[@]}"; do
        i=$((i + 1))
        local tree_char="├──"
        [ "$i" -eq "$count" ] && tree_char="└──"

        if dir_exists "$SKILLS_DIR/$skill"; then
            echo -e "$tree_char $skill: ${GREEN}${CHECK} 已安裝${NC}"
            installed=$((installed + 1))
        else
            echo -e "$tree_char $skill: ${YELLOW}未安裝${NC}"
            missing=$((missing + 1))
        fi
    done

    echo ""
    echo -e "├── 已安裝：${GREEN}$installed${NC} / $count"
    if [ "$missing" -gt 0 ]; then
        echo -e "└── 未安裝：${YELLOW}$missing${NC}（執行安裝可補齊）"
    else
        echo -e "└── ${GREEN}全部已安裝${NC}"
    fi
    echo ""
}

# 檢查 Plugins（僅檢查，不安裝）
check_plugins() {
    print_step "5/7" "檢查官方 Plugins"

    local settings_file="$CLAUDE_DIR/settings.json"
    local count=${#OFFICIAL_PLUGINS[@]}
    local i=0

    for plugin in "${OFFICIAL_PLUGINS[@]}"; do
        i=$((i + 1))
        local plugin_key="${plugin}@${PLUGINS_MARKETPLACE}"
        local tree_char="├──"
        [ "$i" -eq "$count" ] && tree_char="└──"

        if [ -f "$settings_file" ] && grep -q "\"$plugin_key\"" "$settings_file"; then
            echo -e "$tree_char $plugin: ${GREEN}${CHECK} 已啟用${NC}"
        else
            echo -e "$tree_char $plugin: ${YELLOW}未啟用${NC}"
        fi
    done

    echo ""
}

# 驗證 Skills 的 hook 路徑（防止相對路徑：hook command 以 cwd 為基準執行，
# 相對路徑在非 skill 目錄跑 Bash 時會找不到腳本 → non-blocking 報錯）
validate_skill_hooks() {
    local errors=0

    print_step "前置" "驗證 Skill hook 路徑"

    while IFS= read -r hooks_file; do
        while IFS= read -r cmd; do
            # 命令若以直譯器開頭（如 node "$HOME/..."），改檢查其第一個參數的路徑
            local path_to_check="$cmd"
            case "${cmd%% *}" in
                bash|sh|zsh|node|python|python3|npx|deno)
                    path_to_check="${cmd#* }"
                    path_to_check="${path_to_check#\"}"
                    path_to_check="${path_to_check#\'}"
                    ;;
            esac
            case "$path_to_check" in
                /*|\$HOME/*|~/*|\$\{CLAUDE_PLUGIN_ROOT\}*)
                    # 絕對路徑或可展開變數開頭 → 合法
                    ;;
                *)
                    echo -e "├── ${RED}${CROSS} 相對路徑 hook：${NC}${hooks_file#"$SCRIPT_DIR"/}"
                    echo -e "│   command: ${YELLOW}$cmd${NC}"
                    echo -e "│   修正方式：改為 ${GREEN}\$HOME/.claude/skills/<skill-name>/...${NC}"
                    errors=$((errors + 1))
                    ;;
            esac
        done < <(grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' "$hooks_file" 2>/dev/null | sed 's/.*:[[:space:]]*"//; s/"$//; s/\\"/"/g')
    done < <(find "$SCRIPT_DIR/skills" -name "hooks.json" 2>/dev/null)

    if [ "$errors" -gt 0 ]; then
        echo -e "└── ${RED}發現 $errors 個 hook 相對路徑問題，中止部署${NC}"
        echo -e "    （hook 由 Claude Code 以當前工作目錄為基準執行，相對路徑會在其他專案中失效）"
        exit 1
    fi

    echo -e "└── ${GREEN}${CHECK} 所有 skill hook 路徑合法${NC}"
    echo ""
}

# 安裝內建 Skills
install_builtin_skills() {
    print_step "2/7" "安裝內建 Skills"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local count=${#BUILTIN_SKILLS[@]}
    local i=0

    mkdir -p "$SKILLS_DIR"

    for skill in "${BUILTIN_SKILLS[@]}"; do
        i=$((i + 1))
        local source="$SCRIPT_DIR/skills/$skill"
        local target="$SKILLS_DIR/$skill"
        local tree_char="├──"
        [ "$i" -eq "$count" ] && tree_char="└──"

        if [ -d "$source" ]; then
            # 內容相同一律報「已是最新」（--force 也不重寫），不同才備份後覆蓋
            if [ ! -d "$target" ]; then
                cp -r "$source" "$target"
                echo -e "$tree_char $skill: ${GREEN}已安裝（新）${NC}"
            elif diff -rq "$source" "$target" > /dev/null 2>&1; then
                echo -e "$tree_char $skill: ${YELLOW}已是最新${NC}"
            else
                backup_before_overwrite "skills" "$target"
                rm -rf "$target"
                cp -r "$source" "$target"
                if [ "$FORCE" = true ]; then
                    echo -e "$tree_char $skill: ${GREEN}已更新（強制）${NC}"
                else
                    echo -e "$tree_char $skill: ${CYAN}已更新${NC}"
                fi
            fi
        else
            echo -e "$tree_char $skill: ${RED}來源不存在${NC}"
        fi
    done

    echo ""
}

# 檢查內建 Agents（僅檢查，不安裝）
check_builtin_agents() {
    print_step "3/7" "檢查內建 Agents"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local count=${#BUILTIN_AGENTS[@]}
    local i=0
    local installed=0
    local missing=0

    for agent in "${BUILTIN_AGENTS[@]}"; do
        i=$((i + 1))
        local tree_char="├──"
        [ "$i" -eq "$count" ] && tree_char="└──"

        if file_exists "$AGENTS_DIR/$agent.md"; then
            echo -e "$tree_char $agent: ${GREEN}${CHECK} 已安裝${NC}"
            installed=$((installed + 1))
        else
            echo -e "$tree_char $agent: ${YELLOW}未安裝${NC}"
            missing=$((missing + 1))
        fi
    done

    echo ""
    echo -e "├── 已安裝：${GREEN}$installed${NC} / $count"
    if [ "$missing" -gt 0 ]; then
        echo -e "└── 未安裝：${YELLOW}$missing${NC}（執行安裝可補齊）"
    else
        echo -e "└── ${GREEN}全部已安裝${NC}"
    fi
    echo ""
}

# 安裝內建 Agents
install_builtin_agents() {
    print_step "3/7" "安裝內建 Agents"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local count=${#BUILTIN_AGENTS[@]}
    local i=0

    mkdir -p "$AGENTS_DIR"

    for agent in "${BUILTIN_AGENTS[@]}"; do
        i=$((i + 1))
        local source="$SCRIPT_DIR/agents/$agent.md"
        local target="$AGENTS_DIR/$agent.md"
        local tree_char="├──"
        [ "$i" -eq "$count" ] && tree_char="└──"

        if [ -f "$source" ]; then
            # 內容相同一律報「已是最新」（--force 也不重寫），不同才備份後覆蓋
            if [ ! -f "$target" ]; then
                cp "$source" "$target"
                echo -e "$tree_char $agent: ${GREEN}已安裝（新）${NC}"
            elif cmp -s "$source" "$target"; then
                echo -e "$tree_char $agent: ${YELLOW}已是最新${NC}"
            else
                backup_before_overwrite "agents" "$target"
                cp "$source" "$target"
                if [ "$FORCE" = true ]; then
                    echo -e "$tree_char $agent: ${GREEN}已更新（強制）${NC}"
                else
                    echo -e "$tree_char $agent: ${CYAN}已更新${NC}"
                fi
            fi
        else
            echo -e "$tree_char $agent: ${RED}來源不存在${NC}"
        fi
    done

    echo ""
}

# 檢查 MCP
# 判定單一 MCP 在 ~/.claude.json 中的設定範圍，輸出下列其一：
#   global      — 根層 mcpServers（官方 scope 名稱為 user；所有專案皆可用，profile 要的就是這個）
#   local:<N>   — 僅出現在 N 個專案的 projects.<路徑>.mcpServers（官方 scope 名稱為 local）
#   none        — 檔案不存在，或解析成功但找不到
#   unparseable — 檔案存在但 JSON 解析失敗（損毀 / 截斷），有無安裝無從判定
#   unknown     — 無 jq 也無 python3，只能字串比對，連「是否真的設定」都僅為字串證據
# 兩點必須留意：
#   1) 純字串 grep 會把別的專案的 scoped 設定誤判為已安裝，故需真正解析 JSON
#   2) 官方第三種 scope（project = 專案根目錄的 .mcp.json）不在此檔內，本函式看不到
mcp_scope() {
    local mcp="$1" file="$2" out=""

    file_exists "$file" || { echo "none"; return; }

    if command_exists "jq"; then
        # 型別護欄與 python3 分支對齊：非物件的 mcpServers / projects 條目一律略過，
        # 而不是讓整條 filter 報錯（報錯會被誤讀成「沒安裝」）
        out=$(jq -r --arg name "$mcp" '
            def hasmcp($o): ($o | type) == "object" and (($o.mcpServers // {}) | type) == "object"
                            and (($o.mcpServers // {}) | has($name));
            if hasmcp(.) then "global"
            else
                (((.projects // {}) | if type == "object" then [to_entries[] | select(hasmcp(.value))] | length else 0 end)) as $n
                | if $n > 0 then "local:\($n)" else "none" end
            end' "$file" 2>/dev/null) || out=""
    elif command_exists "python3"; then
        out=$(MCP_NAME="$mcp" MCP_FILE="$file" python3 -c '
import json, os, sys
name, path = os.environ["MCP_NAME"], os.environ["MCP_FILE"]
try:
    with open(path) as f:
        data = json.load(f)
except Exception:
    sys.exit(1)
def hasmcp(o):
    return isinstance(o, dict) and isinstance(o.get("mcpServers") or {}, dict) \
           and name in (o.get("mcpServers") or {})
if hasmcp(data):
    print("global")
else:
    projects = data.get("projects") or {}
    n = sum(1 for p in projects.values() if hasmcp(p)) if isinstance(projects, dict) else 0
    print("local:%d" % n if n else "none")
' 2>/dev/null) || out=""
    else
        grep -q "\"$mcp\"" "$file" 2>/dev/null && echo "unknown" || echo "none"
        return
    fi

    # 空輸出 = 解析失敗或空檔：回報「無法判定」而非「沒安裝」
    # （對一個要求可稽核的腳本，把不確定講成確定的斷言是最該避免的錯誤）
    [ -n "$out" ] && echo "$out" || echo "unparseable"
}

# 依範圍輸出一行；$1=樹狀符號 $2=名稱 $3=範圍 $4=縮排 $5=額外說明（可空）
# 必要與可選兩區塊共用，避免同一份 scope→訊息映射寫兩次而漂移
print_mcp_line() {
    local tree="$1" mcp="$2" scope="$3" indent="$4" extra="$5"
    case "$scope" in
        global)
            echo -e "${indent}${tree} $mcp: ${GREEN}${CHECK}${NC}" ;;
        local:*)
            echo -e "${indent}${tree} $mcp: ${YELLOW}${WARN} 僅 ${scope#local:} 個專案設定（非全域${extra}）${NC}" ;;
        unparseable)
            echo -e "${indent}${tree} $mcp: ${YELLOW}${WARN} 無法判定（~/.claude.json 解析失敗，檔案損毀？）${NC}" ;;
        unknown)
            echo -e "${indent}${tree} $mcp: ${YELLOW}${WARN} 疑似已設定（缺 jq/python3，僅字串比對，範圍未知）${NC}" ;;
        *)
            echo -e "${indent}${tree} $mcp: ${YELLOW}未安裝${NC}" ;;
    esac
}

check_mcp() {
    print_step "4/7" "檢查 MCP"

    local claude_json="$HOME/.claude.json"
    local scope

    echo "│"
    echo -e "├── ${CYAN}必要：${NC}"

    for mcp in "${REQUIRED_MCP[@]}"; do
        scope=$(mcp_scope "$mcp" "$claude_json")
        if [ "$scope" = "none" ]; then
            print_fail "$mcp (需要手動設定)"
        else
            print_mcp_line "├──" "$mcp" "$scope" "" "，迴圈步驟 5 在其他專案不可用"
        fi
    done

    echo "│"
    echo -e "└── ${CYAN}可選（推薦）：${NC}"

    local count=${#OPTIONAL_MCP[@]}
    local i=0
    local tree

    for mcp in "${OPTIONAL_MCP[@]}"; do
        i=$((i + 1))
        tree="├──"
        [ "$i" -eq "$count" ] && tree="└──"
        scope=$(mcp_scope "$mcp" "$claude_json")
        print_mcp_line "$tree" "$mcp" "$scope" "    " "，其他專案用不到"
    done

    echo ""
}

# 安裝官方 Plugins
install_plugins() {
    print_step "5/7" "啟用官方 Plugins"

    # JSON 讀寫需要 jq 或 python3 其一；皆缺時跳過此步驟（而非在 set -e 下中止、留下半套安裝）
    if ! command_exists "jq" && ! command_exists "python3"; then
        echo -e "└── ${YELLOW}${WARN} 缺少 jq 與 python3，跳過 Plugin 設定（安裝其一後重跑可補齊）${NC}"
        echo ""
        return
    fi

    local settings_file="$CLAUDE_DIR/settings.json"
    local installed_file="$CLAUDE_DIR/plugins/installed_plugins.json"
    local plugins_base="$CLAUDE_DIR/plugins/marketplaces/$PLUGINS_MARKETPLACE/plugins"

    # installed_plugins.json 的登記敘述（迴圈不變，先備好）：jq 與 python 兩路徑
    # 須維持等價 — 已存在就更新 version / lastUpdated / installPath，否則新建整筆
    # shellcheck disable=SC2016  # 單引號內的 $key/$path/$ver/$ts 是 jq 變數，不可由 shell 展開
    local jq_register='
        if (.plugins[$key] // [] | length) > 0 then
            .plugins[$key][0].version = $ver |
            .plugins[$key][0].lastUpdated = $ts |
            .plugins[$key][0].installPath = $path
        else
            .plugins[$key] = [{
                "scope": "global",
                "projectPath": "",
                "installPath": $path,
                "version": $ver,
                "installedAt": $ts,
                "lastUpdated": $ts
            }]
        end
    '
    local py_register
    py_register=$(cat <<'PYEOF'
entry = {'scope': 'global', 'projectPath': '', 'installPath': env['path'],
         'version': env['ver'], 'installedAt': env['ts'], 'lastUpdated': env['ts']}
plugins = data.setdefault('plugins', {})
if plugins.get(env['key']):
    plugins[env['key']][0].update(version=env['ver'], lastUpdated=env['ts'], installPath=env['path'])
else:
    plugins[env['key']] = [entry]
PYEOF
)

    local count=${#OFFICIAL_PLUGINS[@]}
    local i=0

    for plugin in "${OFFICIAL_PLUGINS[@]}"; do
        i=$((i + 1))
        local plugin_key="${plugin}@${PLUGINS_MARKETPLACE}"
        local plugin_dir="$plugins_base/$plugin"
        local plugin_json="$plugin_dir/.claude-plugin/plugin.json"
        local tree_char="├──"
        [ "$i" -eq "$count" ] && tree_char="└──"

        # 檢查 Plugin 檔案是否存在
        if [ ! -f "$plugin_json" ]; then
            echo -e "$tree_char $plugin: ${RED}Plugin 檔案不存在${NC}"
            continue
        fi

        # 讀取版本號（解析失敗時跳過該 plugin，不中止安裝）
        local version=""
        if command_exists "jq"; then
            version=$(jq -r '.version' "$plugin_json" 2>/dev/null) || version=""
        else
            version=$(PLUGIN_JSON="$plugin_json" python3 -c "import json, os; print(json.load(open(os.environ['PLUGIN_JSON']))['version'])" 2>/dev/null) || version=""
        fi
        if [ -z "$version" ] || [ "$version" = "null" ]; then
            echo -e "$tree_char $plugin: ${YELLOW}${WARN} plugin.json 版本解析失敗，跳過${NC}"
            continue
        fi

        # 更新 settings.json — 啟用 Plugin（讀寫失敗時跳過該 plugin，不在 set -e 下中止安裝）
        # 檔案不存在時先種空骨架，讓下方只需處理「就地更新」一種路徑
        local settings_ok=true
        if [ ! -f "$settings_file" ] && ! echo '{}' > "$settings_file"; then
            settings_ok=false   # 連空骨架都寫不進去（權限等問題）
        else
            # shellcheck disable=SC2016  # 單引號內的 $key 是 jq 變數，不可由 shell 展開
            json_edit "$settings_file" \
                '.enabledPlugins[$key] = true' \
                "data.setdefault('enabledPlugins', {})[env['key']] = True" \
                "key=$plugin_key" || settings_ok=false
        fi
        if [ "$settings_ok" = false ]; then
            echo -e "$tree_char $plugin: ${YELLOW}${WARN} settings.json 更新失敗（檔案可能損毀），跳過${NC}"
            continue
        fi

        # 更新 installed_plugins.json — 登記 Plugin（讀寫失敗時跳過，不中止安裝）
        mkdir -p "$(dirname "$installed_file")"
        local install_path="$CLAUDE_DIR/plugins/cache/$PLUGINS_MARKETPLACE/$plugin/$version"
        local now
        now=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
        # 同 settings.json：不存在時先種空骨架，只留「就地更新」一種路徑
        local installed_ok=true
        if [ ! -f "$installed_file" ] && ! echo '{"version":2,"plugins":{}}' > "$installed_file"; then
            installed_ok=false   # 連空骨架都寫不進去（權限等問題）
        else
            json_edit "$installed_file" "$jq_register" "$py_register" \
                "key=$plugin_key" "path=$install_path" "ver=$version" "ts=$now" || installed_ok=false
        fi

        if [ "$installed_ok" = false ]; then
            echo -e "$tree_char $plugin: ${YELLOW}${WARN} installed_plugins.json 更新失敗（檔案可能損毀），跳過${NC}"
            continue
        fi

        echo -e "$tree_char $plugin (v$version): ${GREEN}${CHECK} 已啟用${NC}"
    done

    echo ""
}

# 建立 DD Commands
create_commands() {
    if [ "${COMMANDS_ONLY:-false}" = true ]; then
        print_step "2/2" "建立 Commands"
    else
        print_step "6/7" "建立 Commands"
    fi

    mkdir -p "$COMMANDS_DIR"

    # 清理已移除的 DD Commands（2026-04 精簡）
    local deprecated_dd=("dd-help" "dd-docs" "dd-revise" "dd-status" "dd-stop")
    for old in "${deprecated_dd[@]}"; do
        if [ -f "$COMMANDS_DIR/$old.md" ]; then
            rm "$COMMANDS_DIR/$old.md"
            echo -e "├── ${YELLOW}🧹 已清理舊命令：$old${NC}"
        fi
    done

    local total=$(( ${#DD_COMMANDS[@]} + ${#NS_COMMANDS[@]} ))
    local i=0

    echo -e "├── ${BLUE}DD Pipeline Commands (${#DD_COMMANDS[@]} 個)${NC}"

    for cmd in "${DD_COMMANDS[@]}"; do
        i=$((i + 1))
        local target="$COMMANDS_DIR/$cmd.md"
        local source="$SCRIPT_DIR/commands/$cmd.md"
        local status=""
        local tree_char="├──"
        [ "$i" -eq "$total" ] && tree_char="└──"

        if [ ! -f "$source" ]; then
            echo -e "$tree_char $cmd: ${RED}源檔案不存在${NC}"
            continue
        fi

        if [ ! -f "$target" ]; then
            cp "$source" "$target"
            status="new"
        elif cmp -s "$source" "$target"; then
            status="uptodate"
        else
            backup_before_overwrite "commands" "$target"
            cp "$source" "$target"
            if [ "$FORCE" = true ]; then status="forced"; else status="updated"; fi
        fi

        case $status in
            new)     echo -e "$tree_char $cmd: ${GREEN}已安裝（新）${NC}" ;;
            forced)  echo -e "$tree_char $cmd: ${GREEN}已更新（強制）${NC}" ;;
            updated) echo -e "$tree_char $cmd: ${CYAN}已更新${NC}" ;;
            uptodate) echo -e "$tree_char $cmd: ${YELLOW}已是最新${NC}" ;;
        esac
    done

    echo -e "├── ${BLUE}命名空間 Commands (${#NS_COMMANDS[@]} 個)${NC}"

    for ns_cmd in "${NS_COMMANDS[@]}"; do
        i=$((i + 1))
        local target_dir="$COMMANDS_DIR/$ns_cmd"
        local source_dir="$SCRIPT_DIR/commands/$ns_cmd"
        local status=""
        local tree_char="├──"
        [ "$i" -eq "$total" ] && tree_char="└──"

        if [ ! -d "$target_dir" ]; then
            if [ -d "$source_dir" ]; then
                cp -r "$source_dir" "$target_dir"
                status="new"
            else
                echo -e "$tree_char $ns_cmd: ${RED}源檔案不存在${NC}"
                continue
            fi
        else
            # 比較目錄內容（README.md 不部署，排除比較以維持冪等）
            if diff -rq -x README.md "$source_dir" "$target_dir" >/dev/null 2>&1; then
                status="uptodate"
            else
                backup_before_overwrite "commands" "$target_dir"
                rm -rf "$target_dir"
                cp -r "$source_dir" "$target_dir"
                if [ "$FORCE" = true ]; then status="forced"; else status="updated"; fi
            fi
        fi

        # README.md 僅供 repo 瀏覽，不部署（否則會被列為可呼叫的 <ns>:README 條目）
        rm -f "$target_dir/README.md"

        case $status in
            new)     echo -e "$tree_char $ns_cmd: ${GREEN}已安裝（新）${NC}" ;;
            forced)  echo -e "$tree_char $ns_cmd: ${GREEN}已更新（強制）${NC}" ;;
            updated) echo -e "$tree_char $ns_cmd: ${CYAN}已更新${NC}" ;;
            uptodate) echo -e "$tree_char $ns_cmd: ${YELLOW}已是最新${NC}" ;;
        esac
    done

    echo ""
}

# 部署輔助腳本到 ~/.claude/scripts/
create_scripts() {
    echo -e "${BLUE}${INFO} 附加步驟：部署輔助腳本${NC}"

    mkdir -p "$SCRIPTS_DIR"

    local count=${#DD_SCRIPTS[@]}
    local i=0

    for s in "${DD_SCRIPTS[@]}"; do
        i=$((i + 1))
        local tree_char="├──"
        [ "$i" -eq "$count" ] && tree_char="└──"

        local source="$SCRIPT_DIR/scripts/$s"
        if [ ! -f "$source" ]; then
            echo -e "$tree_char $s: ${RED}源檔案不存在${NC}"
            continue
        fi

        # 與其他部署點同語意：內容相同報「已是最新」不重寫，不同才備份後覆蓋
        local target="$SCRIPTS_DIR/$s"
        if [ ! -f "$target" ]; then
            cp "$source" "$target"
            echo -e "$tree_char $s: ${GREEN}已安裝（新）${NC}"
        elif cmp -s "$source" "$target"; then
            echo -e "$tree_char $s: ${YELLOW}已是最新${NC}"
        else
            backup_before_overwrite "scripts" "$target"
            cp "$source" "$target"
            if [ "$FORCE" = true ]; then
                echo -e "$tree_char $s: ${GREEN}已更新（強制）${NC}"
            else
                echo -e "$tree_char $s: ${CYAN}已更新${NC}"
            fi
        fi
        chmod +x "$target"
    done
    echo ""
}

# 移除安裝
uninstall() {
    print_header "${ROCKET} DD Pipeline 移除程式"

    echo "即將移除以下內容（本 repo 部署過的項目；更早的 misc/deprecated 部署請先依 UPGRADING.md 清理）："
    echo "├── ~/.claude/commands/ 中的 ${#ALL_DD_COMMANDS[@]} 個 DD Commands 與 ${#ALL_NS_COMMANDS[@]} 個命名空間 Commands"
    echo "├── ~/.claude/templates/dd/（舊版部署殘留；現行版本已不再部署文件模板）"
    echo "├── ~/.claude/skills/ 中的 ${#ALL_SKILLS[@]} 個內建 skill"
    echo "├── ~/.claude/agents/ 中的 ${#ALL_AGENTS[@]} 個內建 agent"
    echo "└── 官方 Plugins 設定（claude-md-management）"
    echo ""

    if [ "${ASSUME_YES:-false}" = true ]; then
        REPLY="y"
    else
        ask "確定要移除嗎？[y/N] " "N"
    fi

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 僅移除 ALL_DD_COMMANDS 列表中的命令（不動使用者自建的 dd-*.md）
        for cmd in "${ALL_DD_COMMANDS[@]}"; do
            rm -f "$COMMANDS_DIR/$cmd.md"
        done

        for ns_cmd in "${ALL_NS_COMMANDS[@]}"; do
            rm -rf "${COMMANDS_DIR:?}/$ns_cmd"
        done

        rm -rf "$TEMPLATES_DIR"

        # 僅移除 DD_SCRIPTS 列表中的腳本（不動使用者自己的）
        for s in "${DD_SCRIPTS[@]}"; do
            rm -f "$SCRIPTS_DIR/$s"
        done

        # 僅移除 ALL_SKILLS 列表中的 skill（不動使用者自己的）
        for skill in "${ALL_SKILLS[@]}"; do
            rm -rf "${SKILLS_DIR:?}/$skill"
        done

        # 僅移除 ALL_AGENTS 列表中的 agent（不動使用者自己的）
        for agent in "${ALL_AGENTS[@]}"; do
            rm -f "$AGENTS_DIR/$agent.md"
        done

        # 清理 Plugin 設定（JSON 讀寫需要 jq 或 python3 其一）
        local settings_file="$CLAUDE_DIR/settings.json"
        local installed_file="$CLAUDE_DIR/plugins/installed_plugins.json"

        if ! command_exists "jq" && ! command_exists "python3"; then
            echo -e "${YELLOW}${WARN} 缺少 jq 與 python3，跳過 Plugin 設定清理（請手動移除 settings.json 的 enabledPlugins 項目）${NC}"
        else
        for plugin in "${OFFICIAL_PLUGINS[@]}"; do
            local plugin_key="${plugin}@${PLUGINS_MARKETPLACE}"

            # 從 settings.json 移除（解析失敗時警告後繼續，不中止移除流程）
            if [ -f "$settings_file" ]; then
                # shellcheck disable=SC2016  # 單引號內的 $key 是 jq 變數，不可由 shell 展開
                json_edit "$settings_file" \
                    'del(.enabledPlugins[$key])' \
                    "data.get('enabledPlugins', {}).pop(env['key'], None)" \
                    "key=$plugin_key" \
                    || echo -e "${YELLOW}${WARN} settings.json 解析失敗，請手動移除 enabledPlugins 的 $plugin_key${NC}"
            fi

            # 從 installed_plugins.json 移除（同上，失敗不中止）
            if [ -f "$installed_file" ]; then
                # shellcheck disable=SC2016  # 單引號內的 $key 是 jq 變數，不可由 shell 展開
                json_edit "$installed_file" \
                    'del(.plugins[$key])' \
                    "data.get('plugins', {}).pop(env['key'], None)" \
                    "key=$plugin_key" \
                    || echo -e "${YELLOW}${WARN} installed_plugins.json 解析失敗，請手動移除 $plugin_key${NC}"
            fi
        done
        fi

        echo -e "${GREEN}DD Pipeline 已移除${NC}"
    else
        echo "取消移除"
    fi
}

# 建立 / 比對全域 CLAUDE.md
create_global_claude_md() {
    print_step "7/7" "檢查全域 CLAUDE.md"

    local source="$SCRIPT_DIR/templates/global/CLAUDE.md"
    local target="$CLAUDE_DIR/CLAUDE.md"

    if [ ! -f "$source" ]; then
        echo -e "└── ${YELLOW}⚠️ repo 內無 templates/global/CLAUDE.md，跳過${NC}"
        return
    fi

    # 情境 1：本機無檔案
    if [ ! -f "$target" ]; then
        if [ "$FORCE" = true ]; then
            cp "$source" "$target"
            echo -e "└── ${GREEN}✅ 已從 repo 模板安裝全域 CLAUDE.md（--force）${NC}"
        else
            echo -e "├── ${CYAN}全域 CLAUDE.md 不存在${NC}"
            ask "│   是否從 repo 模板安裝？[y/N]: " "N"
            if [[ "$REPLY" =~ ^[Yy]$ ]]; then
                cp "$source" "$target"
                echo -e "└── ${GREEN}✅ 已安裝${NC}"
            else
                echo -e "└── ${YELLOW}跳過，保持無全域 CLAUDE.md${NC}"
            fi
        fi
        return
    fi

    # 情境 2：內容一致
    if cmp -s "$source" "$target"; then
        echo -e "└── ${GREEN}✅ 與 repo 版本一致${NC}"
        return
    fi

    # 情境 3：內容不同 — --force 靜默覆蓋（備份走統一機制，完成訊息會顯示位置）
    if [ "$FORCE" = true ]; then
        backup_before_overwrite "global" "$target"
        cp "$source" "$target"
        echo -e "└── ${GREEN}✅ 已用 repo 版本覆蓋（--force，舊版已備份）${NC}"
        return
    fi

    # 情境 4：內容不同 — 互動選單
    echo -e "├── ${YELLOW}⚠️ 全域 CLAUDE.md 與 repo 版本不同${NC}"
    echo ""
    echo "差異摘要（前 30 行）："
    diff "$target" "$source" | head -30
    echo ""
    echo "選項："
    echo "  o) 覆蓋（舊版自動備份到 ~/.claude/backups/，完成訊息會顯示位置）"
    echo "  k) 保留本地版本（推薦，預設）"
    echo "  s) 顯示完整 diff 後再決定"
    echo ""
    ask "選擇 [o/k/s，預設 k]: " "k"
    local choice="$REPLY"

    case $choice in
        o|O)
            backup_before_overwrite "global" "$target"
            cp "$source" "$target"
            echo -e "└── ${GREEN}✅ 已覆蓋，舊版已備份（完成訊息會顯示位置）${NC}"
            ;;
        s|S)
            diff "$target" "$source"
            echo ""
            ask "看完後要覆蓋嗎？[y/N]: " "N"
            if [[ "$REPLY" =~ ^[Yy]$ ]]; then
                backup_before_overwrite "global" "$target"
                cp "$source" "$target"
                echo -e "└── ${GREEN}✅ 已覆蓋，舊版已備份（完成訊息會顯示位置）${NC}"
            else
                echo -e "└── ${YELLOW}已保留本地版本${NC}"
            fi
            ;;
        *)
            echo -e "└── ${YELLOW}已保留本地版本${NC}"
            ;;
    esac
}

# 顯示完成訊息
show_completion() {
    print_header "✅ DD Pipeline 安裝完成！"

    print_backup_notice

    echo -e "${GREEN}📌 快速開始：${NC}"
    echo "   1. cd your-project"
    echo "   2. /dd-init  （蓋章 6 步開發迴圈 + 專案 CLAUDE.md）"
    echo "   3. 開發：實作+測試 → commit → 簡化 → review → 再測 → commit"
    echo ""
    echo -e "${GREEN}📌 已安裝的內建 Agents（${#BUILTIN_AGENTS[@]} 個）：${NC}"
    echo "   供 wrapper skills 透過 Task tool 調用"
    echo ""
    echo -e "${GREEN}📌 已啟用的 Plugin：${NC}"
    echo "   claude-md-management — 使用 /revise-claude-md 管理 CLAUDE.md"
    echo ""
    echo -e "${GREEN}📌 查看說明：${NC}"
    echo "   參閱 README.md"
    echo ""
}

# 主程式
main() {
    local CHECK_ONLY=false
    local FORCE=false
    local COMMANDS_ONLY=false
    local UNINSTALL=false
    local UPDATE=false
    local ASSUME_YES=false

    # 解析參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check)
                CHECK_ONLY=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --commands-only)
                COMMANDS_ONLY=true
                shift
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --yes)
                ASSUME_YES=true
                shift
                ;;
            --update)
                UPDATE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "未知選項: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 移除模式
    if [ "$UNINSTALL" = true ]; then
        uninstall
        exit 0
    fi

    print_header "${ROCKET} DD Pipeline 安裝程式"

    # 檢查環境
    check_environment

    # 驗證 skill hook 路徑（發現相對路徑即中止，防止部署壞設定）
    validate_skill_hooks

    if [ "$CHECK_ONLY" = true ]; then
        # 檢查模式：只檢查狀態，不實際安裝（優先於 --update，維持「不安裝」的宣稱）
        check_builtin_skills
        check_builtin_agents
        check_mcp
        check_plugins
        echo -e "${GREEN}環境檢查完成${NC}"
        exit 0
    fi

    # 更新模式（參數解析完才執行）
    if [ "$UPDATE" = true ]; then
        FORCE=true
        install_builtin_skills
        install_builtin_agents
        print_backup_notice
        exit 0
    fi

    # 安裝內建 Skills / Agents / Plugins（--commands-only 時跳過，只裝 Commands）
    if [ "$COMMANDS_ONLY" = false ]; then
        # 安裝內建 Skills（核心功能）
        install_builtin_skills

        # 安裝內建 Agents（補齊 wrapper skills 依賴）
        install_builtin_agents

        # 檢查 MCP
        check_mcp

        # 啟用官方 Plugins
        install_plugins
    fi

    # 建立 Commands
    create_commands

    # 部署輔助腳本（除非只安裝 commands）
    if [ "$COMMANDS_ONLY" = false ]; then
        create_scripts
    fi

    # 檢查 / 安裝全域 CLAUDE.md（除非只安裝 commands）
    if [ "$COMMANDS_ONLY" = false ]; then
        create_global_claude_md
    fi

    # 顯示完成訊息
    show_completion
}

# 執行主程式（被 source 時不執行，供 CI 直接 source 取用陣列與函式；
# 從 stdin 餵入執行時 BASH_SOURCE 為空，fallback 到 $0 使 main 照常執行）
if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
    main "$@"
fi
