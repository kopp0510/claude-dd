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

# 所有 Skills（從 claude-dd/skills/ 安裝，共 61 個）
BUILTIN_SKILLS=(
    # ── 核心 Skills（19 個）──
    "systems-architect"
    "test-engineer"
    "security-auditor"
    "docs-writer"
    "refactor-expert"
    "performance-tuner"
    "root-cause-analyzer"
    "config-safety-reviewer"
    "senior-database"
    "api-designer"
    "i18n-expert"
    "task-planner"
    "worktree-manager"
    "subagent-orchestrator"
    "code-simplifier"
    "frontend-design"
    "verification-gate"
    "design-brainstorm"
    "branch-finisher"
    # ── 整合包裝器 Skills（23 個）──
    # 開發類
    "senior-backend"
    "senior-frontend"
    "senior-devops"
    "senior-fullstack"
    "tdd-guide"
    "claude-api-expert"
    # 品質與審查類
    "code-reviewer"
    "review"
    "code-health"
    "debt-analysis"
    "test-gen"
    # 安全類
    "vulnerability-scan"
    "security-audit"
    "compliance-check"
    "senior-secops"
    # 效能類
    "performance-profile"
    "benchmark"
    # 維運類
    "deploy-validate"
    "health-check"
    "incident-response"
    # 測試類
    "senior-qa"
    "playwright-pro"
    # 文件類
    "docs-gen"
    # ── 工程團隊 Skills（9 個，原 OPTIONAL_SKILLS）──
    "senior-architect"
    "senior-security"
    "senior-prompt-engineer"
    "senior-data-engineer"
    "senior-data-scientist"
    "senior-ml-engineer"
    "senior-computer-vision"
    "ui-design-system"
    "ux-researcher-designer"
    # ── 產品與商業 Skills（13 個）──
    "agile-product-owner"
    "aws-solution-architect"
    "competitive-teardown"
    "email-template-builder"
    "incident-commander"
    "landing-page-generator"
    "product-manager-toolkit"
    "product-strategist"
    "saas-scaffolder"
    "self-improving-agent"
    "stripe-integration-expert"
    "tech-stack-evaluator"
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
    echo "  --check         只檢查環境（不安裝）"
    echo "  --force         強制重新安裝（覆蓋現有檔案）"
    echo "  --commands-only 只安裝 DD Commands（不安裝 skills）"
    echo "  --uninstall     移除 DD Pipeline"
    echo "  --update        更新 skills 到最新版"
    echo "  --help          顯示此說明"
    echo ""
    echo "安裝內容："
    echo "  - 60 個內建 Skills（16 個核心 + 23 個整合包裝器 + 9 個工程團隊 + 12 個產品與商業）"
    echo "  - 1 個官方 Plugin（CLAUDE.md 管理工具）"
    echo "  - 11 個 DD Commands + 19 個命名空間 Commands"
    echo "  - 8 個 Templates（文檔模板）"
    echo ""
}

# 檢查基礎環境
check_environment() {
    print_step "1/7" "檢查基礎環境"

    local all_ok=true

    # 檢查 Claude Code CLI
    if command_exists "claude"; then
        print_success "Claude Code CLI"
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
    print_step "2/7" "檢查內建 Skills"
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
    print_step "5/7" "檢查官方 Plugins"

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

# 安裝內建 Skills
install_builtin_skills() {
    print_step "2/7" "安裝內建 Skills"
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


# 檢查 MCP
check_mcp() {
    print_step "4/7" "檢查 MCP"

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
    print_step "5/7" "啟用官方 Plugins"

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
    print_step "6/7" "建立 Commands"

    mkdir -p "$COMMANDS_DIR"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # DD Pipeline commands（平面 .md 檔案）
    local dd_commands=(
        "dd-help"
        "dd-init"
        "dd-docs"
        "dd-start"
        "dd-arch"
        "dd-approve"
        "dd-revise"
        "dd-dev"
        "dd-test"
        "dd-status"
        "dd-stop"
    )

    # 命名空間 commands（目錄型）
    local ns_commands=(
        "development-scaffold"
        "documentation-docs-gen"
        "operations-deploy-validate"
        "operations-health-check"
        "operations-incident-response"
        "performance-benchmark"
        "performance-profile"
        "quality-code-health"
        "quality-debt-analysis"
        "security-audit"
        "security-compliance-check"
        "security-vulnerability-scan"
        "testing-test-gen"
        "workflow-handoff-create"
        "workflow-prompt-create"
        "workflow-prompt-run"
        "workflow-review"
        "workflow-todo-add"
        "workflow-todo-check"
    )

    local total=$(( ${#dd_commands[@]} + ${#ns_commands[@]} ))
    local i=0

    echo -e "├── ${BLUE}DD Pipeline Commands (${#dd_commands[@]} 個)${NC}"

    for cmd in "${dd_commands[@]}"; do
        i=$((i + 1))
        local target="$COMMANDS_DIR/$cmd.md"
        local source="$script_dir/commands/$cmd.md"
        local status=""
        local tree_char="├──"
        [ $i -eq $total ] && tree_char="└──"

        if [ ! -f "$target" ]; then
            if [ -f "$source" ]; then
                cp "$source" "$target"
            else
                create_command_content "$cmd" > "$target"
            fi
            status="new"
        elif [ "$FORCE" = true ]; then
            if [ -f "$source" ]; then
                cp "$source" "$target"
            else
                create_command_content "$cmd" > "$target"
            fi
            status="forced"
        else
            local temp_content=$(mktemp)
            if [ -f "$source" ]; then
                cp "$source" "$temp_content"
            else
                create_command_content "$cmd" > "$temp_content"
            fi

            if ! cmp -s "$target" "$temp_content"; then
                cp "$temp_content" "$target"
                status="updated"
            else
                status="uptodate"
            fi
            rm -f "$temp_content"
        fi

        case $status in
            new)     echo -e "$tree_char $cmd: ${GREEN}已安裝（新）${NC}" ;;
            forced)  echo -e "$tree_char $cmd: ${GREEN}已更新（強制）${NC}" ;;
            updated) echo -e "$tree_char $cmd: ${CYAN}已更新${NC}" ;;
            uptodate) echo -e "$tree_char $cmd: ${YELLOW}已是最新${NC}" ;;
        esac
    done

    echo -e "├── ${BLUE}命名空間 Commands (${#ns_commands[@]} 個)${NC}"

    for ns_cmd in "${ns_commands[@]}"; do
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
            # 比較目錄內容
            if diff -rq "$source_dir" "$target_dir" >/dev/null 2>&1; then
                status="uptodate"
            else
                rm -rf "$target_dir"
                cp -r "$source_dir" "$target_dir"
                status="updated"
            fi
        fi

        case $status in
            new)     echo -e "$tree_char $ns_cmd: ${GREEN}已安裝（新）${NC}" ;;
            forced)  echo -e "$tree_char $ns_cmd: ${GREEN}已更新（強制）${NC}" ;;
            updated) echo -e "$tree_char $ns_cmd: ${CYAN}已更新${NC}" ;;
            uptodate) echo -e "$tree_char $ns_cmd: ${YELLOW}已是最新${NC}" ;;
        esac
    done

    echo ""
}

# 建立 command 內容
create_command_content() {
    local cmd=$1

    case $cmd in
        "dd-help")
            cat << 'DDHELP'
# DD Pipeline 使用手冊

顯示 DD Pipeline 的完整使用說明、DD 模式介紹、可用命令和流程結構。

---

## 執行方式

當用戶執行此命令時，請顯示以下內容：

```
═══════════════════════════════════════════════════════════════════
📚 DD Pipeline 使用手冊
═══════════════════════════════════════════════════════════════════

## 什麼是 DD Pipeline？

DD (Driven Development) Pipeline 是一套基於多種開發方法論的
自動化開發流程，透過多 Agent 協作確保 Vibe Coding 的準確性。

## 包含的 DD 模式

┌─────────────────────────────────────────────────────────────────┐
│ 階段          │ DD 模式                    │ 說明              │
├─────────────────────────────────────────────────────────────────┤
│ 需求分析      │ RDD (Requirements)         │ 需求驅動          │
│ 架構設計      │ SDD + DDD + ADD + EDD      │ 架構/領域/決策/範例│
│ 開發實作      │ DbC + CDD + PDD            │ 契約/組件/提示詞   │
│ 測試審查      │ TDD + BDD + ATDD + FDD     │ 測試/行為/驗收/失敗│
└─────────────────────────────────────────────────────────────────┘

## 可用命令

┌──────────────┬────────────────────────────────────────────────┐
│ 命令          │ 說明                                          │
├──────────────┼────────────────────────────────────────────────┤
│ /dd-help     │ 顯示此說明                                     │
│ /dd-init     │ 初始化專案結構（自動偵測現有專案）              │
│ /dd-docs     │ 為現有程式碼產生 DD 文檔                        │
│ /dd-start    │ 啟動流程（需求分析）                            │
│ /dd-arch     │ 進入架構設計                                   │
│ /dd-approve  │ 確認架構，開始自動開發                          │
│ /dd-revise   │ 修改架構設計                                   │
│ /dd-dev      │ 手動觸發開發（通常自動執行）                    │
│ /dd-test     │ 手動觸發測試（通常自動執行）                    │
│ /dd-status   │ 查看目前進度                                   │
│ /dd-stop     │ 中斷流程                                       │
└──────────────┴────────────────────────────────────────────────┘

## 流程圖

  /dd-init ──▶ /dd-start ──▶ /dd-arch ──▶ ⏸️ 等待確認
                                              │
                    ┌─────────────────────────┴─────────────────┐
                    │                                           │
               /dd-approve                                /dd-revise
                    │                                           │
                    ▼                                           │
              自動開發測試 ◀────────────────────────────────────┘
                    │
                    ▼
           ✅ 完成 或 ❌ 失敗重試

## 使用的 Agent/Skill

┌─────────────────────────────────────────────────────────────────┐
│ 架構：systems-architect, senior-architect                      │
│ 後端：senior-backend, performance-tuner, security-auditor      │
│ 前端：senior-frontend, ui-design-system, ux-researcher-designer│
│ 測試：test-engineer, senior-qa, code-reviewer, Playwright MCP  │
│ 文檔：docs-writer                                              │
│ 優化：refactor-expert, senior-prompt-engineer                  │
│ 除錯：root-cause-analyzer                                      │
└─────────────────────────────────────────────────────────────────┘

## 專案結構（/dd-init 後產生）

  your-project/
  ├── CLAUDE.md              # 專案設定
  ├── PROJECT_STATE.md       # 流程狀態
  └── claude_docs/
      ├── requirements/      # 需求文檔
      ├── architecture/      # 架構文檔
      ├── contracts/         # API 契約
      ├── decisions/         # ADR 決策記錄
      ├── examples/          # 行為範例
      ├── design/            # UI/UX 設計
      └── reports/           # 測試報告

## 快速開始

  1. /dd-init              # 初始化專案
  2. /dd-start <需求描述>   # 開始需求分析
  3. /dd-arch              # 進入架構設計
  4. /dd-approve           # 確認後自動完成

═══════════════════════════════════════════════════════════════════
```
DDHELP
            ;;
        "dd-init")
            cat << 'DDINIT'
# DD Pipeline 初始化

初始化專案的 DD Pipeline 結構，建立必要的目錄和設定檔。

---

## 執行步驟

1. **詢問專案類型**：
   - 純後端 API
   - 純前端 SPA
   - 全端應用
   - CLI 工具

2. **詢問技術棧**（根據專案類型）：
   - 後端：Node.js/Go/Python/其他
   - 前端：React/Vue/Svelte/其他
   - 資料庫：PostgreSQL/MongoDB/MySQL/其他

3. **建立目錄結構**：
```
./
├── CLAUDE.md                    # 專案設定
├── PROJECT_STATE.md             # 流程狀態追蹤
└── claude_docs/
    ├── requirements/            # 需求文檔 (RDD)
    ├── architecture/            # 架構文檔 (SDD/DDD)
    ├── contracts/               # API 契約 (DbC)
    ├── decisions/               # 架構決策記錄 (ADD)
    ├── examples/                # 行為範例 (EDD)
    ├── design/                  # UI/UX 設計
    └── reports/                 # 測試報告
```

4. **產生 CLAUDE.md** 模板，包含：
   - 專案概述
   - 技術棧設定
   - DD 流程設定
   - 目錄結構說明
   - 程式碼規範

5. **產生 PROJECT_STATE.md** 初始狀態

6. **Git commit**（如果在 git repo 中）：
   ```
   git add .
   git commit -m "chore: 初始化 DD Pipeline 專案結構"
   ```

7. **顯示下一步提示**：
   ```
   ✅ DD Pipeline 初始化完成！

   📌 下一步：
   /dd-start <需求描述>
   ```

---

## 使用的工具

- 無需調用 Agent/Skill
- 使用 Write 工具建立檔案
- 使用 Bash 工具執行 git 命令
DDINIT
            ;;
        "dd-docs")
            cat << 'DDDOCS'
# DD Pipeline 文檔產生

為現有程式碼分析並產生 DD Pipeline 文檔。
適用於已有程式碼但尚未建立完整文檔的專案。

---

## 使用方式

```bash
# 產生所有文檔
/dd-docs

# 產生特定類型文檔
/dd-docs --requirements    # 需求文檔
/dd-docs --architecture    # 架構文檔
/dd-docs --api             # API 契約文檔
/dd-docs --examples        # 行為範例文檔
/dd-docs --design          # UI/UX 設計文檔

# 組合使用
/dd-docs --api --examples
```

---

## 執行步驟

### Phase 0: 前置檢查

1. 檢查 DD Pipeline 是否已初始化
2. 讀取專案設定（CLAUDE.md, PROJECT_STATE.md）
3. 判斷要產生的文檔類型

### Phase 1: 選擇文檔類型（無參數時）

使用 AskUserQuestion 詢問要產生哪些文檔

### Phase 2: 程式碼分析

根據選擇的文檔類型，啟動對應的分析流程：
- 需求分析 → REQUIREMENTS.md
- 架構分析 → ARCHITECTURE.md
- API 契約分析 → API_CONTRACT.md
- 架構決策記錄 → ADR-XXX.md
- 行為範例分析 → EXAMPLES.md
- UI/UX 設計分析 → DESIGN_SPEC.md

### Phase 3: 文檔產生

使用 docs-writer Agent 和對應 Skill 產生文檔

### Phase 4: 用戶確認

顯示產生的文檔摘要

### Phase 5: 更新狀態

更新 PROJECT_STATE.md 並 Git commit

---

## 文檔輸出位置

claude_docs/
├── requirements/REQUIREMENTS.md
├── architecture/ARCHITECTURE.md
├── contracts/API_CONTRACT.md
├── decisions/ADR-XXX.md
├── examples/EXAMPLES.md
└── design/DESIGN_SPEC.md

---

## 使用的 Agent/Skill

- docs-writer：撰寫各類文檔
- systems-architect：架構分析和 ADR 產生
- senior-architect, senior-backend, senior-frontend
- senior-qa, ui-design-system
DDDOCS
            ;;
        "dd-start")
            cat << 'DDSTART'
# DD Pipeline 啟動 - 需求分析 (RDD)

啟動 DD Pipeline 流程，進入需求分析階段。

---

## 輸入

用戶應提供需求描述，例如：
```
/dd-start 建立一個 Todo List 應用，支援 CRUD 操作
```

---

## 執行步驟

1. **讀取專案設定**：
   - 讀取 `./CLAUDE.md` 取得專案設定
   - 如果不存在，提示用戶先執行 `/dd-init`

2. **需求分析** (RDD)：

   調用 Skill: `ux-researcher-designer`
   - 分析用戶需求
   - 識別核心功能
   - 定義使用者故事

   調用 Skill: `senior-prompt-engineer`
   - 釐清模糊需求
   - 確認技術可行性
   - 建立需求邊界

3. **產出需求文檔**：
   - 建立 `claude_docs/requirements/REQUIREMENTS.md`
   - 包含：
     - 專案目標
     - 功能需求清單
     - 非功能需求
     - 使用者故事
     - 驗收標準

4. **更新狀態**：
   - 更新 `PROJECT_STATE.md`
   - 設定當前階段為「需求分析完成」

5. **Git commit**：
   ```
   git add .
   git commit -m "docs(requirements): 完成需求分析"
   ```

6. **自動進入下一階段**：
   - 顯示需求摘要
   - 自動執行 `/dd-arch` 進入架構設計

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Skill | `ux-researcher-designer` | 用戶研究、需求分析 |
| Skill | `senior-prompt-engineer` | 需求釐清、問題定義 |
| Agent | `docs-writer` | 產出需求文檔 |
DDSTART
            ;;
        "dd-arch")
            cat << 'DDARCH'
# DD Pipeline 架構設計 (SDD + DDD + ADD + EDD)

進入架構設計階段，設計系統架構、領域模型、記錄決策、定義範例。

---

## 執行步驟

1. **讀取需求**：
   - 讀取 `claude_docs/requirements/REQUIREMENTS.md`
   - 讀取 `./CLAUDE.md` 取得技術棧設定

2. **系統架構設計** (SDD)：

   調用 Agent: `systems-architect`
   - 設計整體系統架構
   - 定義模組劃分
   - 設計資料流

3. **技術選型與決策** (ADD)：

   調用 Skill: `senior-architect`
   - 技術選型決策
   - 記錄決策原因
   - 評估替代方案

   產出：`claude_docs/decisions/ADR-XXX-*.md`

4. **領域模型設計** (DDD)：

   調用 Skill: `senior-architect`
   - 識別領域邊界
   - 設計領域模型
   - 定義聚合根

5. **UI/UX 設計**（如果是前端/全端）：

   調用 Skill: `ux-researcher-designer`
   - 設計使用者流程
   - 定義 UI 元件

   產出：`claude_docs/design/DESIGN_SPEC.md`

6. **行為範例定義** (EDD)：

   調用 Skill: `senior-qa`
   - 定義行為範例
   - 描述預期結果

   產出：`claude_docs/examples/EXAMPLES.md`

7. **API 契約定義** (DbC)：

   調用 Skill: `senior-backend`
   - 定義 API 端點
   - 定義請求/回應格式

   產出：`claude_docs/contracts/API_CONTRACT.md`

8. **產出架構文檔**：

   調用 Agent: `docs-writer`
   - 整合所有設計
   - 產出 `claude_docs/architecture/ARCHITECTURE.md`

9. **更新狀態並等待確認**：
   - 更新 `PROJECT_STATE.md`
   - 顯示架構摘要
   - **暫停等待用戶確認**

   ```
   ⏸️ 架構設計完成，等待確認

   請審閱以下文檔：
   ├── claude_docs/architecture/ARCHITECTURE.md
   ├── claude_docs/contracts/API_CONTRACT.md
   ├── claude_docs/design/DESIGN_SPEC.md
   ├── claude_docs/examples/EXAMPLES.md
   └── claude_docs/decisions/ADR-*.md

   📌 下一步：
   ├── /dd-approve  確認架構，開始開發
   └── /dd-revise   修改架構
   ```

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Agent | `systems-architect` | 系統架構設計 |
| Skill | `senior-architect` | 技術選型、領域模型 |
| Skill | `ux-researcher-designer` | UI/UX 設計 |
| Skill | `senior-backend` | API 契約定義 |
| Skill | `senior-qa` | 行為範例定義 |
| Agent | `docs-writer` | 文檔產出 |
DDARCH
            ;;
        "dd-approve")
            cat << 'DDAPPROVE'
# DD Pipeline 確認架構

確認架構設計，開始自動執行開發和測試流程。

---

## 參數

- `--worktree`：使用 Git Worktree 隔離環境進行開發（可選）
- `--batch`：批次模式，每 3 個任務暫停等人工回饋（可選）
- `--classic`：使用舊版一次性實作模式（可選）

---

## 執行步驟

1. **確認架構文檔存在**

2. **Git commit 架構**

3. **更新狀態**

4. **根據專案類型啟動開發**：
   - 傳遞 `--worktree` / `--batch` / `--classic` 參數給 `/dd-dev`
   - 預設不帶額外參數 = 自動使用微任務 + Subagent 模式

5. **監控進度**：失敗自動重試（最多 3 次）

6. **完成後**：產出報告、Git tag

---

## 自動化流程

此命令會觸發完整的自動化流程，用戶無需手動執行後續命令。
預設使用 SADD（微任務 + Subagent 驅動）模式。
DDAPPROVE
            ;;
        "dd-revise")
            cat << 'DDREVISE'
# DD Pipeline 修改架構

根據用戶反饋修改架構設計。

---

## 輸入

用戶應提供修改意見，例如：
```
/dd-revise 我想用 GraphQL 而不是 REST API
```

---

## 執行步驟

1. **讀取現有架構**：
   - 讀取所有架構相關文檔
   - 理解當前設計

2. **分析修改需求**：

   調用 Skill: `senior-architect`
   - 分析修改影響範圍
   - 評估可行性
   - 識別需要更新的文檔

3. **執行修改**：

   調用 Agent: `systems-architect`
   - 更新系統架構
   - 調整相關設計

   調用 Agent: `docs-writer`
   - 更新所有受影響的文檔
   - 新增 ADR 記錄此次變更

4. **Git commit**：
   ```
   git add .
   git commit -m "refactor(architecture): <修改摘要>"
   ```

5. **顯示更新內容**：
   ```
   🔄 架構已更新

   變更內容：
   ├── claude_docs/architecture/ARCHITECTURE.md（已更新）
   ├── claude_docs/contracts/API_CONTRACT.md（已更新）
   └── claude_docs/decisions/ADR-XXX-*.md（新增）

   📌 下一步：
   ├── /dd-approve  確認架構，開始開發
   └── /dd-revise   繼續修改
   ```

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Agent | `systems-architect` | 架構調整 |
| Skill | `senior-architect` | 影響評估 |
| Agent | `docs-writer` | 文檔更新 |
DDREVISE
            ;;
        "dd-dev")
            cat << 'DDDEV'
# DD Pipeline 開發實作 (DbC + CDD + PDD)

執行開發實作階段，依照契約進行組件化開發。

---

## 參數

- `--backend`：只執行後端開發
- `--frontend`：只執行前端開發
- `--fix`：修正模式（讀取失敗原因並修正）
- `--worktree`：建立 Git Worktree 隔離環境（可選）
- `--batch`：批次模式，每 3 個任務暫停等人工回饋（可選）
- `--classic`：使用舊版一次性實作模式（向後相容）

---

## 預設模式：微任務 + Subagent 驅動 (SADD)

### 後端/前端開發流程

0. **Worktree 設定**（僅 --worktree 時）：
   調用 Skill: `worktree-manager`

1. **讀取架構和契約**

2. **微任務規劃**：
   調用 Skill: `task-planner`
   → 產出 claude_docs/plans/YYYY-MM-DD-<feature>.md

3. **執行策略**：
   - 預設 → 調用 Skill: `subagent-orchestrator`（全自動逐任務執行+審查）
   - --batch → 批次模式（每 3 個任務暫停）
   - --classic → 舊版一次性實作模式

4-7. 效能/安全/重構/文檔（不變）
8. Git commit
9. 自動觸發 /dd-test

---

## 修正模式 (--fix)

1. 讀取失敗原因
2. 調用 Agent: `root-cause-analyzer`
3. 執行修正
4. Git commit
5. 重新執行測試
DDDEV
            ;;
        "dd-test")
            cat << 'DDTEST'
# DD Pipeline 測試審查 (TDD + BDD + ATDD + FDD)

執行測試審查階段，包含單元測試、行為測試、驗收測試和失敗情境測試。

---

## 參數

- `--backend`：只執行後端測試
- `--frontend`：只執行前端測試
- `--integrate`：執行整合測試

---

## 執行步驟

### 後端測試流程

1. **讀取測試範例**：
   - 讀取 `claude_docs/examples/EXAMPLES.md`
   - 讀取 `claude_docs/contracts/API_CONTRACT.md`

2. **撰寫測試** (TDD)：

   調用 Agent: `test-engineer`
   - 撰寫單元測試
   - 撰寫整合測試
   - 依照範例撰寫行為測試 (BDD)

3. **執行測試**：

   調用 Agent: `test-engineer`
   - 執行所有測試
   - 收集測試結果

4. **失敗情境測試** (FDD)：

   調用 Agent: `test-engineer`
   - 測試錯誤處理
   - 測試邊界條件
   - 測試異常情況

5. **程式碼審查**：

   調用 Skill: `code-reviewer`
   - 審查程式碼品質
   - 檢查最佳實踐

6. **QA 驗收** (ATDD)：

   調用 Skill: `senior-qa`
   - 驗收測試
   - 確認符合需求

7. **結果處理**：

   **如果通過**：
   ```
   git add .
   git commit -m "test(backend): 後端測試通過"
   ```
   → 等待前端測試 或 進入整合測試

   **如果失敗**：
   - 記錄失敗原因到 `PROJECT_STATE.md`
   - 自動執行 `/dd-dev --backend --fix`
   - 重新測試（最多 3 次）

---

### 前端測試流程

1. **撰寫組件測試**：

   調用 Agent: `test-engineer`
   - 撰寫組件測試
   - 撰寫快照測試

2. **E2E 測試**：

   調用 MCP: `Playwright`
   - 開啟瀏覽器
   - 執行 E2E 測試腳本
   - 模擬使用者操作
   - 截圖保存

3. **UI/UX 審查**：

   調用 Skill: `ux-researcher-designer`
   - 審查截圖
   - 檢查使用者體驗
   - 提出改進建議

4. **QA 驗收**：

   調用 Skill: `senior-qa`

5. **結果處理**：

   同後端測試

---

### 整合測試流程

當後端和前端測試都通過後：

1. **完整 E2E 測試**：

   調用 MCP: `Playwright`
   - 執行完整使用者流程
   - 測試前後端整合

2. **最終 QA 驗收**：

   調用 Skill: `senior-qa`

3. **產出測試報告**：

   調用 Agent: `docs-writer`
   - 產出 `claude_docs/reports/TEST_REPORT.md`

4. **完成處理**：
   ```
   git add .
   git commit -m "test: 整合測試通過"
   ```
   → 產出 Release Notes → Git merge/tag

---

## 使用的 Agent/Skill/MCP

| 類型 | 名稱 | 用途 |
|------|------|------|
| Agent | `test-engineer` | 撰寫和執行測試 |
| Agent | `root-cause-analyzer` | 分析失敗原因 |
| Skill | `senior-qa` | QA 驗收 |
| Skill | `code-reviewer` | 程式碼審查 |
| Skill | `ux-researcher-designer` | UI/UX 審查 |
| MCP | `Playwright` | E2E 網頁測試 |
| Agent | `docs-writer` | 測試報告 |
DDTEST
            ;;
        "dd-status")
            cat << 'DDSTATUS'
# DD Pipeline 狀態查詢

顯示目前的專案狀態和進度。

---

## 執行步驟

1. **讀取狀態檔**：
   - 讀取 `PROJECT_STATE.md`

2. **顯示狀態**：
   ```
   ═══════════════════════════════════════════════════════════════════
   📊 DD Pipeline 狀態
   ═══════════════════════════════════════════════════════════════════

   ## 整體進度
   - [x] 初始化 - 完成
   - [x] 需求分析 - 完成
   - [x] 架構設計 - 完成
   - [ ] 架構確認 - 等待中
   - [ ] 後端開發 - 待開始
   - [ ] 前端開發 - 待開始
   - [ ] 後端測試 - 待開始
   - [ ] 前端測試 - 待開始
   - [ ] 整合測試 - 待開始
   - [ ] 發布 - 待開始

   ## 當前階段
   架構設計完成，等待確認

   ## 最近活動
   - 2024-01-15 10:30 - 完成架構設計
   - 2024-01-15 10:00 - 完成需求分析
   - 2024-01-15 09:30 - 初始化專案

   ## 迭代記錄
   （無）

   ## 下一步
   /dd-approve 或 /dd-revise

   ═══════════════════════════════════════════════════════════════════
   ```

---

## 無需調用 Agent/Skill

此命令只讀取和顯示狀態，不執行任何開發操作。
DDSTATUS
            ;;
        "dd-stop")
            cat << 'DDSTOP'
# DD Pipeline 中斷流程

中斷目前正在執行的 DD Pipeline 流程。

---

## 執行步驟

1. **確認中斷**：
   ```
   ⚠️ 確定要中斷 DD Pipeline 流程嗎？

   當前狀態：後端測試中（第 2 次迭代）

   中斷後：
   - 進度會保存到 PROJECT_STATE.md
   - 可以使用 /dd-status 查看狀態
   - 可以使用 /dd-approve 繼續流程

   [Y/n]
   ```

2. **保存狀態**：
   - 更新 `PROJECT_STATE.md`
   - 記錄中斷時間和原因

3. **Git commit**（如果有未提交的變更）：
   ```
   git add .
   git commit -m "wip: DD Pipeline 中斷 - <當前階段>"
   ```

4. **顯示恢復指引**：
   ```
   ⏸️ DD Pipeline 已中斷

   恢復方式：
   - /dd-approve  從當前階段繼續
   - /dd-status   查看詳細狀態
   ```

---

## 無需調用 Agent/Skill

此命令只處理流程控制，不執行任何開發操作。
DDSTOP
            ;;
    esac
}

# 建立 Templates
create_templates() {
    print_step "7/7" "建立 Templates"

    mkdir -p "$TEMPLATES_DIR"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # 定義所有 templates
    local templates=(
        "CLAUDE.md.template"
        "PROJECT_STATE.md.template"
        "REQUIREMENTS.md.template"
        "ARCHITECTURE.md.template"
        "API_CONTRACT.md.template"
        "EXAMPLES.md.template"
        "ADR.md.template"
        "TASK_PLAN.md.template"
    )

    local count=${#templates[@]}
    local i=0

    for tpl in "${templates[@]}"; do
        i=$((i + 1))
        local target="$TEMPLATES_DIR/$tpl"
        local source="$script_dir/templates/$tpl"
        local status=""
        local tree_char="├──"
        [ $i -eq $count ] && tree_char="└──"

        if [ ! -f "$target" ]; then
            # 目標檔案不存在 → 新安裝
            if [ -f "$source" ]; then
                cp "$source" "$target"
            else
                create_template_content "$tpl" > "$target"
            fi
            status="new"
        elif [ "$FORCE" = true ]; then
            # 強制更新
            if [ -f "$source" ]; then
                cp "$source" "$target"
            else
                create_template_content "$tpl" > "$target"
            fi
            status="forced"
        else
            # 比較檔案內容，偵測變更
            local temp_content=$(mktemp)
            if [ -f "$source" ]; then
                cp "$source" "$temp_content"
            else
                create_template_content "$tpl" > "$temp_content"
            fi

            if ! cmp -s "$target" "$temp_content"; then
                # 內容不同 → 更新
                cp "$temp_content" "$target"
                status="updated"
            else
                # 內容相同 → 已是最新
                status="uptodate"
            fi
            rm -f "$temp_content"
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

# 建立 template 內容
create_template_content() {
    local tpl=$1

    case $tpl in
        "CLAUDE.md.template")
            cat << 'CLAUDEMD'
# {{PROJECT_NAME}}

## 專案概述
{{PROJECT_DESCRIPTION}}

## 技術棧
- 後端：{{BACKEND_TECH}}
- 前端：{{FRONTEND_TECH}}
- 資料庫：{{DATABASE_TECH}}
- 測試框架：{{TEST_FRAMEWORK}}

## DD 流程設定

### 啟用的 DD
- [x] RDD - 需求驅動
- [x] SDD - 架構驅動
- [x] DDD - 領域驅動
- [x] ADD - 架構決策記錄
- [x] EDD - 範例驅動
- [x] DbC - 契約驅動
- [x] CDD - 組件驅動
- [x] PDD - 提示詞驅動
- [x] TDD - 測試驅動
- [x] BDD - 行為驅動
- [x] ATDD - 驗收測試
- [x] FDD - 失敗情境測試

### 開發模式
{{DEV_MODE}}

### 測試設定
- 最大重試次數：3
- 需要 E2E 測試：{{NEED_E2E}}
- 需要 UI/UX 審查：{{NEED_UX_REVIEW}}

## 目錄結構
```
src/
├── {{BACKEND_DIR}}/     # 後端程式碼
├── {{FRONTEND_DIR}}/    # 前端程式碼
└── shared/              # 共用程式碼

claude_docs/
├── requirements/        # 需求文檔
├── architecture/        # 架構文檔
├── contracts/           # API 契約
├── decisions/           # ADR 決策記錄
├── examples/            # 行為範例
├── design/              # UI/UX 設計
└── reports/             # 測試報告
```

## 程式碼規範
- 使用 {{LINTER}}
- 程式碼註解使用繁體中文
- Commit message 格式：conventional commits

## 特殊規則
{{SPECIAL_RULES}}
CLAUDEMD
            ;;
        "PROJECT_STATE.md.template")
            cat << 'PROJECTSTATE'
# {{PROJECT_NAME}} - DD Pipeline 狀態

## 整體進度
- [ ] 初始化 - 待開始
- [ ] 需求分析 (RDD) - 待開始
- [ ] 架構設計 (SDD/DDD/ADD/EDD) - 待開始
- [ ] 架構確認 - 待開始
- [ ] 後端開發 (DbC/CDD/PDD) - 待開始
- [ ] 前端開發 (CDD/PDD) - 待開始
- [ ] 後端測試 (TDD/BDD/ATDD/FDD) - 待開始
- [ ] 前端測試 (TDD/BDD/E2E) - 待開始
- [ ] 整合測試 - 待開始
- [ ] 發布 - 待開始

## 當前階段
尚未開始

## 最近活動
- {{TIMESTAMP}} - 初始化專案

## 迭代記錄
（無）

## Git 記錄
（無）

## 下一步
/dd-start <需求描述>
PROJECTSTATE
            ;;
        "REQUIREMENTS.md.template")
            cat << 'REQUIREMENTS'
# {{PROJECT_NAME}} - 需求文檔

## 專案目標
{{PROJECT_GOAL}}

## 功能需求

### 核心功能
1. {{FEATURE_1}}
2. {{FEATURE_2}}
3. {{FEATURE_3}}

### 次要功能
1. {{SECONDARY_FEATURE_1}}

## 非功能需求
- 效能：{{PERFORMANCE_REQ}}
- 安全：{{SECURITY_REQ}}
- 可用性：{{AVAILABILITY_REQ}}

## 使用者故事

### 故事 1：{{STORY_1_TITLE}}
**作為** {{ACTOR}}
**我想要** {{ACTION}}
**以便** {{BENEFIT}}

**驗收標準：**
- [ ] {{CRITERIA_1}}
- [ ] {{CRITERIA_2}}

## 範圍邊界

### 包含
- {{IN_SCOPE_1}}

### 不包含
- {{OUT_SCOPE_1}}

## 假設與限制
- {{ASSUMPTION_1}}
REQUIREMENTS
            ;;
        "ARCHITECTURE.md.template")
            cat << 'ARCHITECTURE'
# {{PROJECT_NAME}} - 系統架構

## 系統概覽

### 架構圖
```
{{ARCHITECTURE_DIAGRAM}}
```

## 技術選型

| 層級 | 技術 | 原因 |
|------|------|------|
| 後端 | {{BACKEND_TECH}} | {{BACKEND_REASON}} |
| 前端 | {{FRONTEND_TECH}} | {{FRONTEND_REASON}} |
| 資料庫 | {{DATABASE_TECH}} | {{DATABASE_REASON}} |

## 模組劃分

### 後端模組
```
src/server/
├── controllers/     # 控制器
├── services/        # 業務邏輯
├── models/          # 資料模型
├── middleware/      # 中間件
└── utils/           # 工具函數
```

### 前端模組
```
src/client/
├── components/      # UI 組件
├── pages/           # 頁面
├── hooks/           # 自定義 Hooks
├── services/        # API 服務
└── utils/           # 工具函數
```

## 資料流

```
{{DATA_FLOW_DIAGRAM}}
```

## 安全設計
- 認證方式：{{AUTH_METHOD}}
- 授權機制：{{AUTHZ_METHOD}}
- 資料加密：{{ENCRYPTION}}

## 擴展性考量
{{SCALABILITY_NOTES}}
ARCHITECTURE
            ;;
        "API_CONTRACT.md.template")
            cat << 'APICONTRACT'
# {{PROJECT_NAME}} - API 契約

## 基本資訊
- Base URL: `{{BASE_URL}}`
- 版本: `{{API_VERSION}}`
- 格式: JSON

## 認證
{{AUTH_DESCRIPTION}}

## 端點

### {{RESOURCE_NAME}}

#### 取得列表
```
GET /api/{{RESOURCE_PATH}}
```

**回應：**
```json
{
  "data": [
    {
      "id": "string",
      ...
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

#### 取得單一
```
GET /api/{{RESOURCE_PATH}}/:id
```

#### 新增
```
POST /api/{{RESOURCE_PATH}}
```

**請求：**
```json
{
  ...
}
```

#### 更新
```
PUT /api/{{RESOURCE_PATH}}/:id
```

#### 刪除
```
DELETE /api/{{RESOURCE_PATH}}/:id
```

## 錯誤格式
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "錯誤訊息"
  }
}
```

## 狀態碼
| 狀態碼 | 說明 |
|--------|------|
| 200 | 成功 |
| 201 | 建立成功 |
| 400 | 請求錯誤 |
| 401 | 未認證 |
| 403 | 無權限 |
| 404 | 找不到資源 |
| 500 | 伺服器錯誤 |
APICONTRACT
            ;;
        "EXAMPLES.md.template")
            cat << 'EXAMPLES'
# {{PROJECT_NAME}} - 行為範例 (EDD)

## 範例 1：{{EXAMPLE_1_TITLE}}

### 前置條件
- {{PRECONDITION_1}}

### 操作步驟
1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

### 預期結果
- {{EXPECTED_RESULT_1}}
- {{EXPECTED_RESULT_2}}

### 範例資料
**輸入：**
```json
{{INPUT_DATA}}
```

**輸出：**
```json
{{OUTPUT_DATA}}
```

---

## 範例 2：{{EXAMPLE_2_TITLE}}

### 前置條件
- {{PRECONDITION}}

### 操作步驟
1. {{STEP}}

### 預期結果
- {{EXPECTED_RESULT}}

---

## 邊界情況

### 情況 1：{{EDGE_CASE_1}}
- 輸入：{{EDGE_INPUT}}
- 預期：{{EDGE_EXPECTED}}

### 情況 2：空資料
- 輸入：空
- 預期：回傳空列表或適當錯誤

### 情況 3：無效資料
- 輸入：無效格式
- 預期：回傳 400 錯誤
EXAMPLES
            ;;
        "ADR.md.template")
            cat << 'ADR'
# ADR-{{NUMBER}}: {{TITLE}}

## 狀態
{{STATUS}} <!-- 提議中 | 已接受 | 已棄用 | 已取代 -->

## 背景
{{CONTEXT}}

## 決策
{{DECISION}}

## 原因
{{RATIONALE}}

## 替代方案

### 方案 A：{{ALTERNATIVE_A}}
- 優點：{{A_PROS}}
- 缺點：{{A_CONS}}

### 方案 B：{{ALTERNATIVE_B}}
- 優點：{{B_PROS}}
- 缺點：{{B_CONS}}

## 影響
- {{CONSEQUENCE_1}}
- {{CONSEQUENCE_2}}

## 相關決策
- ADR-{{RELATED_ADR}}

## 日期
{{DATE}}
ADR
            ;;
        "TASK_PLAN.md.template")
            cat << 'TASKPLAN'
# 微任務計畫：{{FEATURE_NAME}}

## 基本資訊
- **建立日期**：{{DATE}}
- **來源架構**：claude_docs/architecture/ARCHITECTURE.md
- **總任務數**：{{TOTAL_TASKS}} 個
- **預估時間**：約 {{ESTIMATED_MINUTES}} 分鐘（每任務 2-5 分鐘）
- **執行模式**：{{EXECUTION_MODE}}

## 依賴圖

```
{{DEPENDENCY_GRAPH}}
```

## 任務列表

### 任務 1: {{TASK_1_NAME}}

**檔案路徑：** `{{TASK_1_FILE_PATH}}`
**依賴：** 無

**TDD 五步驟：**

1. **寫失敗測試**
   - 測試檔案：`{{TASK_1_TEST_PATH}}`
   - 測試內容：{{TASK_1_TEST_DESCRIPTION}}

2. **驗證測試失敗**
   - 執行：`{{TEST_COMMAND}}`

3. **實作功能**
   - 檔案：`{{TASK_1_FILE_PATH}}`
   - 實作內容：{{TASK_1_IMPL_DESCRIPTION}}

4. **驗證測試通過**
   - 執行：`{{TEST_COMMAND}}`

5. **提交**
   - `git commit -m "{{TASK_1_COMMIT_MSG}}"`

---

## 驗證清單

- [ ] 所有任務都有明確的檔案路徑
- [ ] 每個任務都有完整的 TDD 五步驟
- [ ] 依賴關係無循環
- [ ] 測試程式碼可直接執行
- [ ] 所有架構功能都被覆蓋
TASKPLAN
            ;;
    esac
}

# 移除安裝
uninstall() {
    print_header "${ROCKET} DD Pipeline 移除程式"

    echo "即將移除以下內容："
    echo "├── ~/.claude/commands/dd-*.md"
    echo "├── ~/.claude/templates/dd/"
    echo "└── 官方 Plugins 設定（claude-md-management）"
    echo ""

    read -p "確定要移除嗎？[y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$COMMANDS_DIR"/dd-*.md
        rm -rf "$TEMPLATES_DIR"

        # 清理 Plugin 設定
        local settings_file="$CLAUDE_DIR/settings.json"
        local installed_file="$CLAUDE_DIR/plugins/installed_plugins.json"

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

        echo -e "${GREEN}DD Pipeline 已移除${NC}"
    else
        echo "取消移除"
    fi
}

# 顯示完成訊息
show_completion() {
    print_header "✅ DD Pipeline 安裝完成！"

    echo -e "${GREEN}📌 快速開始：${NC}"
    echo "   1. cd your-project"
    echo "   2. /dd-init"
    echo "   3. /dd-start \"你的需求\""
    echo ""
    echo -e "${GREEN}📌 已啟用的 Plugin：${NC}"
    echo "   claude-md-management — 使用 /revise-claude-md 管理 CLAUDE.md"
    echo ""
    echo -e "${GREEN}📌 查看說明：${NC}"
    echo "   /dd-help"
    echo ""
}

# 主程式
main() {
    local CHECK_ONLY=false
    local FORCE=false
    local COMMANDS_ONLY=false
    local UNINSTALL=false

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
            --update)
                FORCE=true
                install_builtin_skills
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

    if [ "$CHECK_ONLY" = true ]; then
        # 檢查模式：只檢查狀態，不實際安裝
        check_builtin_skills
        check_mcp
        check_plugins
        echo -e "${GREEN}環境檢查完成${NC}"
        exit 0
    fi

    # 安裝內建 Skills（核心功能）
    install_builtin_skills

    # 檢查 MCP
    check_mcp

    # 啟用官方 Plugins
    install_plugins

    # 建立 Commands
    create_commands

    # 建立 Templates（除非只安裝 commands）
    if [ "$COMMANDS_ONLY" = false ]; then
        create_templates
    fi

    # 顯示完成訊息
    show_completion
}

# 執行主程式
main "$@"
