#!/bin/bash
# 安裝腳本（install-dd-pipeline.sh）的端到端測試：在拋棄式 HOME 裡非互動安裝，驗部署內容、冪等、
# --force／--update／--commands-only／--uninstall 與 --check 不寫入。
# CI 在 ubuntu（bash 5）與 macOS（/bin/bash 3.2）各跑一次（.github/workflows/ci.yml）。
# 2026-10-01 從 ci.yml 內嵌 step 搬出來，macOS 那個 job 才能共用；判斷一行都沒改。
#
# 用法：tests/test-install.sh　（在哪個目錄跑都可以；只寫拋棄式 HOME 與暫存目錄，跑完清掉）
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# runner 無 claude CLI，放一個只回版本號的假 binary 讓環境檢查通過
mkdir -p "$WORK/fakebin"
printf '#!/bin/sh\necho "2.1.200 (Claude Code)"\n' > "$WORK/fakebin/claude"
chmod +x "$WORK/fakebin/claude"
export PATH="$WORK/fakebin:$PATH"

./install-dd-pipeline.sh --help > /dev/null
echo "✅ --help 可執行"

# --check：只檢查環境、不得寫入任何檔案（獨立乾淨 sandbox，驗 README 的「不安裝」宣稱）
CHECK_SANDBOX=$(mktemp -d "$WORK/check.XXXXXX")
HOME="$CHECK_SANDBOX" ./install-dd-pipeline.sh --check < /dev/null
[ -z "$(ls -A "$CHECK_SANDBOX")" ]
echo "✅ --check 未寫入任何檔案"

SANDBOX=$(mktemp -d "$WORK/home.XXXXXX")

# 首次安裝：非互動環境下互動詢問須走預設值，不得中止
HOME="$SANDBOX" ./install-dd-pipeline.sh < /dev/null

# 驗證部署結果 = 部署清單
# shellcheck source=../install-dd-pipeline.sh
source ./install-dd-pipeline.sh
[ "$(ls -d "$SANDBOX"/.claude/skills/*/ | wc -l)" -eq "${#PROMOTED_SKILLS[@]}" ]
[ "$(ls "$SANDBOX"/.claude/agents/*.md | wc -l)" -eq "${#PROMOTED_AGENTS[@]}" ]
[ -f "$SANDBOX/.claude/commands/dd-init.md" ]
[ -d "$SANDBOX/.claude/commands/workflow-review" ]
[ ! -f "$SANDBOX/.claude/commands/workflow-review/README.md" ]
[ -x "$SANDBOX/.claude/scripts/check-claude-md.sh" ]
echo "✅ 首次安裝部署內容正確"

# 冪等：重跑不得改動內容、不得產生備份
HOME="$SANDBOX" ./install-dd-pipeline.sh < /dev/null
[ ! -d "$SANDBOX/.claude/backups" ]
echo "✅ 重跑冪等（無備份產生 = 無檔案被覆蓋）"

# --force：內容相同時不重寫，因此同樣不得產生備份
HOME="$SANDBOX" ./install-dd-pipeline.sh --force < /dev/null
[ ! -d "$SANDBOX/.claude/backups" ]
echo "✅ --force 內容相同不重寫（無備份產生）"

# --update 非互動可用
HOME="$SANDBOX" ./install-dd-pipeline.sh --update < /dev/null
echo "✅ --update 非互動可用"

# --commands-only：只裝 commands，不得動到既有 skills
skills_before=$(ls -d "$SANDBOX"/.claude/skills/*/ | wc -l)
HOME="$SANDBOX" ./install-dd-pipeline.sh --commands-only < /dev/null
[ "$(ls -d "$SANDBOX"/.claude/skills/*/ | wc -l)" -eq "$skills_before" ]
[ -f "$SANDBOX/.claude/commands/dd-init.md" ]
echo "✅ --commands-only 未動到既有 skills"

# --uninstall 非互動走預設 N：取消移除、不得誤刪
HOME="$SANDBOX" ./install-dd-pipeline.sh --uninstall < /dev/null
[ -d "$SANDBOX/.claude/skills/code-simplifier" ]
echo "✅ 非互動 uninstall 預設取消，未誤刪"
