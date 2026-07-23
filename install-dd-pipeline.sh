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
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
TEMPLATES_DIR="$CLAUDE_DIR/templates/dd"
AGENTS_DIR="$CLAUDE_DIR/agents"
SKILLS_DIR="$CLAUDE_DIR/skills"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"

# Skills 分桶（2026-07-23 依全 transcript 使用率盤點；檔案全數保留於 repo，部署與否由桶決定）
# - PROMOTED：實證常用，預設部署
# - MISC：低頻但屬 SRE / 備援性質，--with-misc 才部署
# - DEPRECATED：全歷史 0 次使用，--with-deprecated 才部署；觀察期後可評估刪除
# 註：原同名 wrapper skill（senior-frontend/backend/devops/fullstack/qa/secops、
# tdd-guide、playwright-pro、claude-api-expert、code-reviewer）已於 2026-05 移除，
# 改由 §7.2 主動觸發 + 直接派 Task 取代。
PROMOTED_SKILLS=(
    "code-simplifier"
    "design-brainstorm"
    "frontend-design"
    "review"
    "self-improving-agent"
    "task-planner"
    "verification-gate"
    "worktree-manager"
    "writing-great-skills"   # user-invoked（disable-model-invocation），零 context 稅
)

MISC_SKILLS=(
    "branch-finisher"
    "deploy-validate"
    "health-check"
    "incident-commander"
    "incident-response"
    "root-cause-analyzer"
    "security-audit"
    "security-auditor"
    "ui-design-system"
    "ux-researcher-designer"
    "vulnerability-scan"
)

DEPRECATED_SKILLS=(
    "agile-product-owner"
    "api-designer"
    "aws-solution-architect"
    "benchmark"
    "code-health"
    "competitive-teardown"
    "compliance-check"
    "config-safety-reviewer"
    "debt-analysis"
    "docs-gen"
    "docs-writer"
    "email-template-builder"
    "i18n-expert"
    "landing-page-generator"
    "performance-profile"
    "performance-tuner"
    "product-manager-toolkit"
    "product-strategist"
    "refactor-expert"
    "saas-scaffolder"
    "senior-architect"
    "senior-computer-vision"
    "senior-data-engineer"
    "senior-data-scientist"
    "senior-database"
    "senior-ml-engineer"
    "senior-prompt-engineer"
    "senior-security"
    "stripe-integration-expert"
    "subagent-orchestrator"
    "systems-architect"
    "tech-stack-evaluator"
    "test-engineer"
    "test-gen"
)

# 部署集合（預設 = PROMOTED；main() 解析 --with-misc / --with-deprecated 後擴充）
BUILTIN_SKILLS=("${PROMOTED_SKILLS[@]}")
ALL_SKILLS=("${PROMOTED_SKILLS[@]}" "${MISC_SKILLS[@]}" "${DEPRECATED_SKILLS[@]}")

# Agents 分桶（同 skills 的盤點基準）
# - PROMOTED：實證用過（senior-devops、security-auditor）+ 2 個官方 agent 本地備份
#   （code-simplifier、code-reviewer；plugin 未裝時的 fallback，確保離線/新環境可用）
# - DEPRECATED：全歷史 0 次使用
PROMOTED_AGENTS=(
    "code-simplifier"
    "code-reviewer"
    "senior-devops"
    "security-auditor"
)

DEPRECATED_AGENTS=(
    "senior-frontend"
    "senior-backend"
    "senior-database"
    "senior-fullstack"
    "senior-qa"
    "senior-secops"
    "senior-architect"
    "senior-data-engineer"
    "senior-data-scientist"
    "senior-ml-engineer"
    "senior-security"
    "senior-prompt-engineer"
    "senior-computer-vision"
    "dx-engineer"
    "tdd-guide"
    "playwright-pro"
    "claude-api"
)

BUILTIN_AGENTS=("${PROMOTED_AGENTS[@]}")
ALL_AGENTS=("${PROMOTED_AGENTS[@]}" "${DEPRECATED_AGENTS[@]}")

# DD commands（平面 .md 檔案）
# 2026-07-23 重整：dd-init 改造為「6 步開發迴圈」初始化；原多階段 pipeline
# （dd-start/arch/approve/dev/test/dx）全歷史 0 次使用，移入 deprecated 桶
DD_COMMANDS=(
    "dd-init"
)

DEPRECATED_DD_COMMANDS=(
    "dd-start"
    "dd-arch"
    "dd-approve"
    "dd-dev"
    "dd-test"
    "dd-dx"
)

ALL_DD_COMMANDS=("${DD_COMMANDS[@]}" "${DEPRECATED_DD_COMMANDS[@]}")

# 命名空間 commands（目錄型），分桶基準同 skills
NS_COMMANDS=(
    "workflow-review"
)

MISC_NS_COMMANDS=(
    "operations-deploy-validate"
    "operations-health-check"
    "operations-incident-response"
    "security-audit"
    "security-vulnerability-scan"
)

DEPRECATED_NS_COMMANDS=(
    "development-scaffold"
    "documentation-docs-gen"
    "performance-benchmark"
    "performance-profile"
    "quality-code-health"
    "quality-debt-analysis"
    "security-compliance-check"
    "testing-test-gen"
    "workflow-handoff-create"
    "workflow-prompt-create"
    "workflow-prompt-run"
    "workflow-todo-add"
    "workflow-todo-check"
)

ALL_NS_COMMANDS=("${NS_COMMANDS[@]}" "${MISC_NS_COMMANDS[@]}" "${DEPRECATED_NS_COMMANDS[@]}")

# 文件模板（部署到 ~/.claude/templates/dd/）
DD_TEMPLATES=(
    "CLAUDE.md.template"
    "PROJECT_STATE.md.template"
    "REQUIREMENTS.md.template"
    "ARCHITECTURE.md.template"
    "API_CONTRACT.md.template"
    "EXAMPLES.md.template"
    "ADR.md.template"
)

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
    echo "  --with-misc         連同 misc 桶一起部署（SRE / 備援性質項目）"
    echo "  --with-deprecated   連同 deprecated 桶一起部署（0 使用率封存項目）"
    echo "  --prune             移除 ~/.claude 中本次未部署桶位的舊檔（需確認）"
    echo "  --uninstall         移除 DD Pipeline（含所有桶位）"
    echo "  --update            更新 skills/agents 到最新版（旗標需置於 --update 之前）"
    echo "  --help              顯示此說明"
    echo ""
    echo "預設安裝內容（promoted 桶）："
    echo "  - ${#PROMOTED_SKILLS[@]} 個 Skills（實證常用；misc ${#MISC_SKILLS[@]} 個、deprecated ${#DEPRECATED_SKILLS[@]} 個需旗標）"
    echo "  - ${#PROMOTED_AGENTS[@]} 個 Agents（2 個實證 + 2 個官方備份；deprecated ${#DEPRECATED_AGENTS[@]} 個需旗標）"
    echo "  - ${#OFFICIAL_PLUGINS[@]} 個官方 Plugin（CLAUDE.md 管理工具，巢狀 CLAUDE.md 維護依賴）"
    echo "  - ${#DD_COMMANDS[@]} 個 DD Command（dd-init：6 步開發迴圈初始化）+ ${#NS_COMMANDS[@]} 個命名空間 Command"
    echo "  - ${#DD_TEMPLATES[@]} 個 Templates（文檔模板）"
    echo "  - 1 個全域 CLAUDE.md（互動式比對覆蓋）"
    echo ""
}

# 檢查基礎環境
check_environment() {
    print_step "1/8" "檢查基礎環境"

    local all_ok=true

    # 檢查 Claude Code CLI
    if command_exists "claude"; then
        local cc_version
        cc_version=$(claude --version 2>/dev/null | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)
        if [ -n "$cc_version" ]; then
            print_success "Claude Code CLI (v$cc_version)"
            # 原生 opt-in 功能最低版本：Workflow ≥ 2.1.154（見 commands/dd-dev.md）
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
        print_last_success "Bash"
    else
        print_last_fail "Bash"
        all_ok=false
    fi

    echo ""

    if [ "$all_ok" = false ]; then
        echo -e "${RED}基礎環境檢查失敗，請先安裝缺少的工具${NC}"
        exit 1
    fi
}

# 檢查內建 Skills（僅檢查，不安裝）
check_builtin_skills() {
    print_step "2/8" "檢查內建 Skills"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local count=${#BUILTIN_SKILLS[@]}
    local i=0
    local installed=0
    local missing=0

    for skill in "${BUILTIN_SKILLS[@]}"; do
        i=$((i + 1))
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

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
    if [ $missing -gt 0 ]; then
        echo -e "└── 未安裝：${YELLOW}$missing${NC}（執行安裝可補齊）"
    else
        echo -e "└── ${GREEN}全部已安裝${NC}"
    fi
    echo ""
}

# 檢查 Plugins（僅檢查，不安裝）
check_plugins() {
    print_step "5/8" "檢查官方 Plugins"

    local settings_file="$CLAUDE_DIR/settings.json"
    local count=${#OFFICIAL_PLUGINS[@]}
    local i=0

    for plugin in "${OFFICIAL_PLUGINS[@]}"; do
        i=$((i + 1))
        local plugin_key="${plugin}@${PLUGINS_MARKETPLACE}"
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

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
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
                    echo -e "├── ${RED}${CROSS} 相對路徑 hook：${NC}${hooks_file#$script_dir/}"
                    echo -e "│   command: ${YELLOW}$cmd${NC}"
                    echo -e "│   修正方式：改為 ${GREEN}\$HOME/.claude/skills/<skill-name>/...${NC}"
                    errors=$((errors + 1))
                    ;;
            esac
        done < <(grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' "$hooks_file" 2>/dev/null | sed 's/.*:[[:space:]]*"//; s/"$//; s/\\"/"/g')
    done < <(find "$script_dir/skills" -name "hooks.json" 2>/dev/null)

    if [ $errors -gt 0 ]; then
        echo -e "└── ${RED}發現 $errors 個 hook 相對路徑問題，中止部署${NC}"
        echo -e "    （hook 由 Claude Code 以當前工作目錄為基準執行，相對路徑會在其他專案中失效）"
        exit 1
    fi

    echo -e "└── ${GREEN}${CHECK} 所有 skill hook 路徑合法${NC}"
    echo ""
}

# 安裝內建 Skills
install_builtin_skills() {
    print_step "2/8" "安裝內建 Skills"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local count=${#BUILTIN_SKILLS[@]}
    local i=0

    mkdir -p "$SKILLS_DIR"

    for skill in "${BUILTIN_SKILLS[@]}"; do
        i=$((i + 1))
        local source="$script_dir/skills/$skill"
        local target="$SKILLS_DIR/$skill"
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

        if [ -d "$source" ]; then
            if [ ! -d "$target" ]; then
                cp -r "$source" "$target"
                echo -e "$tree_char $skill: ${GREEN}已安裝（新）${NC}"
            elif [ "$FORCE" = true ]; then
                rm -rf "$target"
                cp -r "$source" "$target"
                echo -e "$tree_char $skill: ${GREEN}已更新（強制）${NC}"
            else
                # 比較是否有更新
                if ! diff -rq "$source" "$target" > /dev/null 2>&1; then
                    rm -rf "$target"
                    cp -r "$source" "$target"
                    echo -e "$tree_char $skill: ${CYAN}已更新${NC}"
                else
                    echo -e "$tree_char $skill: ${YELLOW}已是最新${NC}"
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
    print_step "3/8" "檢查內建 Agents"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local count=${#BUILTIN_AGENTS[@]}
    local i=0
    local installed=0
    local missing=0

    for agent in "${BUILTIN_AGENTS[@]}"; do
        i=$((i + 1))
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

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
    if [ $missing -gt 0 ]; then
        echo -e "└── 未安裝：${YELLOW}$missing${NC}（執行安裝可補齊）"
    else
        echo -e "└── ${GREEN}全部已安裝${NC}"
    fi
    echo ""
}

# 安裝內建 Agents
install_builtin_agents() {
    print_step "3/8" "安裝內建 Agents"
    echo -e "├── 來源：${CYAN}DD Pipeline 內建${NC}"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local count=${#BUILTIN_AGENTS[@]}
    local i=0

    mkdir -p "$AGENTS_DIR"

    for agent in "${BUILTIN_AGENTS[@]}"; do
        i=$((i + 1))
        local source="$script_dir/agents/$agent.md"
        local target="$AGENTS_DIR/$agent.md"
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

        if [ -f "$source" ]; then
            if [ ! -f "$target" ]; then
                cp "$source" "$target"
                echo -e "$tree_char $agent: ${GREEN}已安裝（新）${NC}"
            elif [ "$FORCE" = true ]; then
                cp "$source" "$target"
                echo -e "$tree_char $agent: ${GREEN}已更新（強制）${NC}"
            else
                if ! cmp -s "$source" "$target"; then
                    cp "$source" "$target"
                    echo -e "$tree_char $agent: ${CYAN}已更新${NC}"
                else
                    echo -e "$tree_char $agent: ${YELLOW}已是最新${NC}"
                fi
            fi
        else
            echo -e "$tree_char $agent: ${RED}來源不存在${NC}"
        fi
    done

    echo ""
}


# 檢查 MCP
check_mcp() {
    print_step "4/8" "檢查 MCP"

    local claude_json="$HOME/.claude.json"

    echo "│"
    echo -e "├── ${CYAN}必要：${NC}"

    for mcp in "${REQUIRED_MCP[@]}"; do
        if file_exists "$claude_json" && grep -q "\"$mcp\"" "$claude_json"; then
            print_success "$mcp"
        else
            print_fail "$mcp (需要手動設定)"
        fi
    done

    echo "│"
    echo -e "└── ${CYAN}可選（推薦）：${NC}"

    local count=${#OPTIONAL_MCP[@]}
    local i=0

    for mcp in "${OPTIONAL_MCP[@]}"; do
        i=$((i + 1))
        if file_exists "$claude_json" && grep -q "\"$mcp\"" "$claude_json"; then
            if [ $i -eq $count ]; then
                echo -e "    └── $mcp: ${GREEN}${CHECK}${NC}"
            else
                echo -e "    ├── $mcp: ${GREEN}${CHECK}${NC}"
            fi
        else
            if [ $i -eq $count ]; then
                echo -e "    └── $mcp: ${YELLOW}未安裝${NC}"
            else
                echo -e "    ├── $mcp: ${YELLOW}未安裝${NC}"
            fi
        fi
    done

    echo ""
}

# 安裝官方 Plugins
install_plugins() {
    print_step "5/8" "啟用官方 Plugins"

    # JSON 讀寫需要 jq 或 python3 其一；皆缺時跳過此步驟（而非在 set -e 下中止、留下半套安裝）
    if ! command_exists "jq" && ! command_exists "python3"; then
        echo -e "└── ${YELLOW}${WARN} 缺少 jq 與 python3，跳過 Plugin 設定（安裝其一後重跑可補齊）${NC}"
        echo ""
        return
    fi

    local settings_file="$CLAUDE_DIR/settings.json"
    local installed_file="$CLAUDE_DIR/plugins/installed_plugins.json"
    local plugins_base="$CLAUDE_DIR/plugins/marketplaces/$PLUGINS_MARKETPLACE/plugins"

    local count=${#OFFICIAL_PLUGINS[@]}
    local i=0

    for plugin in "${OFFICIAL_PLUGINS[@]}"; do
        i=$((i + 1))
        local plugin_key="${plugin}@${PLUGINS_MARKETPLACE}"
        local plugin_dir="$plugins_base/$plugin"
        local plugin_json="$plugin_dir/.claude-plugin/plugin.json"
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

        # 檢查 Plugin 檔案是否存在
        if [ ! -f "$plugin_json" ]; then
            echo -e "$tree_char $plugin: ${RED}Plugin 檔案不存在${NC}"
            continue
        fi

        # 讀取版本號
        local version=""
        if command_exists "jq"; then
            version=$(jq -r '.version' "$plugin_json")
        else
            version=$(python3 -c "import json; print(json.load(open('$plugin_json'))['version'])")
        fi

        # 更新 settings.json — 啟用 Plugin
        if [ -f "$settings_file" ]; then
            if command_exists "jq"; then
                local tmp=$(mktemp)
                jq --arg key "$plugin_key" '.enabledPlugins[$key] = true' "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
            else
                python3 -c "
import json, sys
with open('$settings_file', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' not in data:
    data['enabledPlugins'] = {}
data['enabledPlugins']['$plugin_key'] = True
with open('$settings_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
            fi
        else
            # settings.json 不存在，建立新檔
            if command_exists "jq"; then
                echo "{}" | jq --arg key "$plugin_key" '{enabledPlugins: {($key): true}}' > "$settings_file"
            else
                python3 -c "
import json
data = {'enabledPlugins': {'$plugin_key': True}}
with open('$settings_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
            fi
        fi

        # 更新 installed_plugins.json — 登記 Plugin
        mkdir -p "$(dirname "$installed_file")"
        local install_path="$CLAUDE_DIR/plugins/cache/$PLUGINS_MARKETPLACE/$plugin/$version"
        local now=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

        if [ -f "$installed_file" ]; then
            if command_exists "jq"; then
                local tmp=$(mktemp)
                jq --arg key "$plugin_key" \
                   --arg path "$install_path" \
                   --arg ver "$version" \
                   --arg ts "$now" \
                   '
                   if .plugins[$key] then
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
                   ' "$installed_file" > "$tmp" && mv "$tmp" "$installed_file"
            else
                python3 -c "
import json
with open('$installed_file', 'r') as f:
    data = json.load(f)
key = '$plugin_key'
entry = {
    'scope': 'global',
    'projectPath': '',
    'installPath': '$install_path',
    'version': '$version',
    'installedAt': '$now',
    'lastUpdated': '$now'
}
if key in data.get('plugins', {}):
    data['plugins'][key][0]['version'] = '$version'
    data['plugins'][key][0]['lastUpdated'] = '$now'
    data['plugins'][key][0]['installPath'] = '$install_path'
else:
    if 'plugins' not in data:
        data['plugins'] = {}
    data['plugins'][key] = [entry]
with open('$installed_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
            fi
        else
            # installed_plugins.json 不存在，建立新檔
            if command_exists "jq"; then
                echo '{"version":2,"plugins":{}}' | jq \
                    --arg key "$plugin_key" \
                    --arg path "$install_path" \
                    --arg ver "$version" \
                    --arg ts "$now" \
                    '.plugins[$key] = [{
                        "scope": "global",
                        "projectPath": "",
                        "installPath": $path,
                        "version": $ver,
                        "installedAt": $ts,
                        "lastUpdated": $ts
                    }]' > "$installed_file"
            else
                python3 -c "
import json
data = {
    'version': 2,
    'plugins': {
        '$plugin_key': [{
            'scope': 'global',
            'projectPath': '',
            'installPath': '$install_path',
            'version': '$version',
            'installedAt': '$now',
            'lastUpdated': '$now'
        }]
    }
}
with open('$installed_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
            fi
        fi

        echo -e "$tree_char $plugin (v$version): ${GREEN}${CHECK} 已啟用${NC}"
    done

    echo ""
}

# 建立 DD Commands
create_commands() {
    print_step "6/8" "建立 Commands"

    mkdir -p "$COMMANDS_DIR"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
        local source="$script_dir/commands/$cmd.md"
        local status=""
        local tree_char="├──"
        [ $i -eq $total ] && tree_char="└──"

        if [ ! -f "$source" ]; then
            echo -e "$tree_char $cmd: ${RED}源檔案不存在${NC}"
            continue
        fi

        if [ ! -f "$target" ]; then
            cp "$source" "$target"
            status="new"
        elif [ "$FORCE" = true ]; then
            cp "$source" "$target"
            status="forced"
        elif cmp -s "$source" "$target"; then
            status="uptodate"
        else
            cp "$source" "$target"
            status="updated"
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
        local source_dir="$script_dir/commands/$ns_cmd"
        local status=""
        local tree_char="├──"
        [ $i -eq $total ] && tree_char="└──"

        if [ ! -d "$target_dir" ]; then
            if [ -d "$source_dir" ]; then
                cp -r "$source_dir" "$target_dir"
                status="new"
            else
                echo -e "$tree_char $ns_cmd: ${RED}源檔案不存在${NC}"
                continue
            fi
        elif [ "$FORCE" = true ]; then
            rm -rf "$target_dir"
            cp -r "$source_dir" "$target_dir"
            status="forced"
        else
            # 比較目錄內容（README.md 不部署，排除比較以維持冪等）
            if diff -rq -x README.md "$source_dir" "$target_dir" >/dev/null 2>&1; then
                status="uptodate"
            else
                rm -rf "$target_dir"
                cp -r "$source_dir" "$target_dir"
                status="updated"
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


# 建立 Templates
# 部署輔助腳本到 ~/.claude/scripts/
create_scripts() {
    echo -e "${BLUE}${INFO} 附加步驟：部署輔助腳本${NC}"

    mkdir -p "$SCRIPTS_DIR"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local count=${#DD_SCRIPTS[@]}
    local i=0

    for s in "${DD_SCRIPTS[@]}"; do
        i=$((i + 1))
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

        local source="$script_dir/scripts/$s"
        if [ ! -f "$source" ]; then
            echo -e "$tree_char $s: ${RED}源檔案不存在${NC}"
            continue
        fi

        cp "$source" "$SCRIPTS_DIR/$s"
        chmod +x "$SCRIPTS_DIR/$s"
        echo -e "$tree_char $s: ${GREEN}${CHECK}${NC}"
    done
    echo ""
}

create_templates() {
    print_step "7/8" "建立 Templates"

    mkdir -p "$TEMPLATES_DIR"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local count=${#DD_TEMPLATES[@]}
    local i=0

    for tpl in "${DD_TEMPLATES[@]}"; do
        i=$((i + 1))
        local target="$TEMPLATES_DIR/$tpl"
        local source="$script_dir/templates/$tpl"
        local status=""
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

        if [ ! -f "$source" ]; then
            echo -e "$tree_char $target: ${RED}源檔案不存在${NC}"
            continue
        fi

        if [ ! -f "$target" ]; then
            cp "$source" "$target"
            status="new"
        elif [ "$FORCE" = true ]; then
            cp "$source" "$target"
            status="forced"
        elif cmp -s "$source" "$target"; then
            status="uptodate"
        else
            cp "$source" "$target"
            status="updated"
        fi

        # 顯示狀態
        case $status in
            new)
                echo -e "$tree_char $target: ${GREEN}已安裝（新）${NC}"
                ;;
            forced)
                echo -e "$tree_char $target: ${GREEN}已更新（強制）${NC}"
                ;;
            updated)
                echo -e "$tree_char $target: ${CYAN}已更新${NC}"
                ;;
            uptodate)
                echo -e "$tree_char $target: ${YELLOW}已是最新${NC}"
                ;;
        esac
    done

    echo ""
}


# 移除安裝
uninstall() {
    print_header "${ROCKET} DD Pipeline 移除程式"

    echo "即將移除以下內容（含所有桶位，不論當初用什麼旗標部署）："
    echo "├── ~/.claude/commands/ 中的 ${#ALL_DD_COMMANDS[@]} 個 DD Commands 與 ${#ALL_NS_COMMANDS[@]} 個命名空間 Commands"
    echo "├── ~/.claude/templates/dd/"
    echo "├── ~/.claude/skills/ 中的 ${#ALL_SKILLS[@]} 個內建 skill"
    echo "├── ~/.claude/agents/ 中的 ${#ALL_AGENTS[@]} 個內建 agent"
    echo "└── 官方 Plugins 設定（claude-md-management）"
    echo ""

    read -p "確定要移除嗎？[y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 僅移除 ALL_DD_COMMANDS 列表中的命令（不動使用者自建的 dd-*.md）
        for cmd in "${ALL_DD_COMMANDS[@]}"; do
            rm -f "$COMMANDS_DIR/$cmd.md"
        done

        for ns_cmd in "${ALL_NS_COMMANDS[@]}"; do
            rm -rf "$COMMANDS_DIR/$ns_cmd"
        done

        rm -rf "$TEMPLATES_DIR"

        # 僅移除 DD_SCRIPTS 列表中的腳本（不動使用者自己的）
        for s in "${DD_SCRIPTS[@]}"; do
            rm -f "$SCRIPTS_DIR/$s"
        done

        # 僅移除 ALL_SKILLS 列表中的 skill（不動使用者自己的）
        for skill in "${ALL_SKILLS[@]}"; do
            rm -rf "$SKILLS_DIR/$skill"
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

            # 從 settings.json 移除
            if [ -f "$settings_file" ]; then
                if command_exists "jq"; then
                    local tmp=$(mktemp)
                    jq --arg key "$plugin_key" 'del(.enabledPlugins[$key])' "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
                else
                    python3 -c "
import json
with open('$settings_file', 'r') as f:
    data = json.load(f)
data.get('enabledPlugins', {}).pop('$plugin_key', None)
with open('$settings_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
                fi
            fi

            # 從 installed_plugins.json 移除
            if [ -f "$installed_file" ]; then
                if command_exists "jq"; then
                    local tmp=$(mktemp)
                    jq --arg key "$plugin_key" 'del(.plugins[$key])' "$installed_file" > "$tmp" && mv "$tmp" "$installed_file"
                else
                    python3 -c "
import json
with open('$installed_file', 'r') as f:
    data = json.load(f)
data.get('plugins', {}).pop('$plugin_key', None)
with open('$installed_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
                fi
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
    print_step "8/8" "檢查全域 CLAUDE.md"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local source="$script_dir/templates/global/CLAUDE.md"
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
            read -p "│   是否從 repo 模板安裝？[y/N]: " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
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

    # 情境 3：內容不同 — --force 靜默覆蓋
    if [ "$FORCE" = true ]; then
        local backup="$target.backup.$(date +%Y-%m-%d-%H%M%S)"
        cp "$target" "$backup"
        cp "$source" "$target"
        echo -e "├── ${YELLOW}已備份至 $(basename "$backup")${NC}"
        echo -e "└── ${GREEN}✅ 已用 repo 版本覆蓋（--force）${NC}"
        return
    fi

    # 情境 4：內容不同 — 互動選單
    echo -e "├── ${YELLOW}⚠️ 全域 CLAUDE.md 與 repo 版本不同${NC}"
    echo ""
    echo "差異摘要（前 30 行）："
    diff "$target" "$source" | head -30
    echo ""
    echo "選項："
    echo "  o) 覆蓋（自動備份為 CLAUDE.md.backup.YYYY-MM-DD-HHMMSS）"
    echo "  k) 保留本地版本（推薦，預設）"
    echo "  s) 顯示完整 diff 後再決定"
    echo ""
    read -p "選擇 [o/k/s，預設 k]: " choice
    choice=${choice:-k}

    case $choice in
        o|O)
            local backup="$target.backup.$(date +%Y-%m-%d-%H%M%S)"
            cp "$target" "$backup"
            cp "$source" "$target"
            echo -e "└── ${GREEN}✅ 已覆蓋，本地版本備份為 $(basename "$backup")${NC}"
            ;;
        s|S)
            diff "$target" "$source"
            echo ""
            read -p "看完後要覆蓋嗎？[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                local backup="$target.backup.$(date +%Y-%m-%d-%H%M%S)"
                cp "$target" "$backup"
                cp "$source" "$target"
                echo -e "└── ${GREEN}✅ 已覆蓋，本地版本備份為 $(basename "$backup")${NC}"
            else
                echo -e "└── ${YELLOW}已保留本地版本${NC}"
            fi
            ;;
        *)
            echo -e "└── ${YELLOW}已保留本地版本${NC}"
            ;;
    esac
}

# 清理 ~/.claude 中「本次未部署桶位」的舊部署殘留
# 只動 ALL_* 列表內（即本 repo 曾部署過）且不在本次部署集合中的項目；
# 使用者自建的 skills/agents/commands 一概不碰。可用 --with-misc/--with-deprecated 重裝復原。
prune_retired() {
    print_header "🧹 清理未部署桶位的舊檔（--prune）"

    local prune_skills=() prune_agents=() prune_cmds=() prune_ns=()

    for skill in "${ALL_SKILLS[@]}"; do
        if [[ ! " ${BUILTIN_SKILLS[*]} " == *" $skill "* ]] && [ -d "$SKILLS_DIR/$skill" ]; then
            prune_skills+=("$skill")
        fi
    done
    for agent in "${ALL_AGENTS[@]}"; do
        if [[ ! " ${BUILTIN_AGENTS[*]} " == *" $agent "* ]] && [ -f "$AGENTS_DIR/$agent.md" ]; then
            prune_agents+=("$agent")
        fi
    done
    for cmd in "${ALL_DD_COMMANDS[@]}"; do
        if [[ ! " ${DD_COMMANDS[*]} " == *" $cmd "* ]] && [ -f "$COMMANDS_DIR/$cmd.md" ]; then
            prune_cmds+=("$cmd")
        fi
    done
    for ns_cmd in "${ALL_NS_COMMANDS[@]}"; do
        if [[ ! " ${NS_COMMANDS[*]} " == *" $ns_cmd "* ]] && [ -d "$COMMANDS_DIR/$ns_cmd" ]; then
            prune_ns+=("$ns_cmd")
        fi
    done

    local total=$(( ${#prune_skills[@]} + ${#prune_agents[@]} + ${#prune_cmds[@]} + ${#prune_ns[@]} ))
    if [ "$total" -eq 0 ]; then
        echo -e "${GREEN}✅ 無殘留可清（~/.claude 已與本次部署集合一致）${NC}"
        return
    fi

    echo "即將從 ~/.claude 移除 $total 項（皆為本 repo 部署過、本次未部署的桶位項目）："
    [ ${#prune_skills[@]} -gt 0 ] && echo "├── skills: ${prune_skills[*]}"
    [ ${#prune_agents[@]} -gt 0 ] && echo "├── agents: ${prune_agents[*]}"
    [ ${#prune_cmds[@]} -gt 0 ] && echo "├── DD commands: ${prune_cmds[*]}"
    [ ${#prune_ns[@]} -gt 0 ] && echo "└── NS commands: ${prune_ns[*]}"
    echo ""

    read -p "確定要移除嗎？（可用 --with-misc / --with-deprecated 重裝復原）[y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消清理"
        return
    fi

    for skill in "${prune_skills[@]}"; do rm -rf "$SKILLS_DIR/$skill"; done
    for agent in "${prune_agents[@]}"; do rm -f "$AGENTS_DIR/$agent.md"; done
    for cmd in "${prune_cmds[@]}"; do rm -f "$COMMANDS_DIR/$cmd.md"; done
    for ns_cmd in "${prune_ns[@]}"; do rm -rf "$COMMANDS_DIR/$ns_cmd"; done

    echo -e "${GREEN}✅ 已移除 $total 項${NC}"
}

# 顯示完成訊息
show_completion() {
    print_header "✅ DD Pipeline 安裝完成！"

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
    local WITH_MISC=false
    local WITH_DEPRECATED=false
    local PRUNE=false

    # 解析參數
    # 註：--with-misc / --with-deprecated 直接擴充部署集合，故需置於 --update 之前才生效
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
            --with-misc)
                if [ "$WITH_MISC" = false ]; then
                    WITH_MISC=true
                    BUILTIN_SKILLS+=("${MISC_SKILLS[@]}")
                    NS_COMMANDS+=("${MISC_NS_COMMANDS[@]}")
                fi
                shift
                ;;
            --with-deprecated)
                if [ "$WITH_DEPRECATED" = false ]; then
                    WITH_DEPRECATED=true
                    BUILTIN_SKILLS+=("${DEPRECATED_SKILLS[@]}")
                    BUILTIN_AGENTS+=("${DEPRECATED_AGENTS[@]}")
                    DD_COMMANDS+=("${DEPRECATED_DD_COMMANDS[@]}")
                    NS_COMMANDS+=("${DEPRECATED_NS_COMMANDS[@]}")
                fi
                shift
                ;;
            --prune)
                PRUNE=true
                shift
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --update)
                FORCE=true
                validate_skill_hooks
                install_builtin_skills
                install_builtin_agents
                exit 0
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
        # 檢查模式：只檢查狀態，不實際安裝
        check_builtin_skills
        check_builtin_agents
        check_mcp
        check_plugins
        echo -e "${GREEN}環境檢查完成${NC}"
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

    # 建立 Templates 與輔助腳本（除非只安裝 commands）
    if [ "$COMMANDS_ONLY" = false ]; then
        create_templates
        create_scripts
    fi

    # 檢查 / 安裝全域 CLAUDE.md（除非只安裝 commands）
    if [ "$COMMANDS_ONLY" = false ]; then
        create_global_claude_md
    fi

    # 清理未部署桶位的舊檔（--prune，需逐項確認）
    if [ "$PRUNE" = true ]; then
        prune_retired
    fi

    # 顯示完成訊息
    show_completion
}

# 執行主程式
main "$@"
