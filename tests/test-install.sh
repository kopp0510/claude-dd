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
[ "$(ls "$SANDBOX"/.claude/output-styles/*.md | wc -l)" -eq "${#DD_OUTPUT_STYLES[@]}" ]
grep -qx 'name: ADHD' "$SANDBOX/.claude/output-styles/adhd.md"
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

# --commands-only 在乾淨 HOME：不得部署 output style（上面那個 SANDBOX 已經有了，驗不出來）
CO_SANDBOX=$(mktemp -d "$WORK/co.XXXXXX")
HOME="$CO_SANDBOX" ./install-dd-pipeline.sh --commands-only < /dev/null
[ ! -e "$CO_SANDBOX/.claude/output-styles/adhd.md" ]
echo "✅ --commands-only 未部署 output style"

# --uninstall 非互動走預設 N：取消移除、不得誤刪
HOME="$SANDBOX" ./install-dd-pipeline.sh --uninstall < /dev/null
[ -d "$SANDBOX/.claude/skills/code-simplifier" ]
echo "✅ 非互動 uninstall 預設取消，未誤刪"

# --uninstall --yes：移除部署的 output style，不動使用者自己的風格檔
UN_SANDBOX=$(mktemp -d "$WORK/un.XXXXXX")
HOME="$UN_SANDBOX" ./install-dd-pipeline.sh < /dev/null
printf -- '---\nname: Mine\n---\n' > "$UN_SANDBOX/.claude/output-styles/mine.md"
HOME="$UN_SANDBOX" ./install-dd-pipeline.sh --uninstall --yes < /dev/null
[ ! -e "$UN_SANDBOX/.claude/output-styles/adhd.md" ]
[ -f "$UN_SANDBOX/.claude/output-styles/mine.md" ]
echo "✅ uninstall --yes 移除 adhd.md、保留使用者自己的風格檔"

# ---------------------------------------------------------------------------
# 以下各組（T1–T9）在 2026-11-14 補上：碰設定檔、備份與完成訊息的路徑。
# 斷言失敗時一律印出「組名＋斷言名」再 exit 1 —— 上面那些裸 [ … ] 在 set -e 下失敗不印任何字。
# ---------------------------------------------------------------------------

# --- T1 開始（這一段自足：GNU 容器裡用 sed 把這兩行註解之間抽出來單獨跑，見 tests/CLAUDE.md）
# 全域 CLAUDE.md 是指向別處的 symlink（dotfiles 管理的常見擺法）時，--force 覆蓋前備份的要是它指到的內容。
# GNU 的 cp -r 只複製連結本身，接著 cp 寫穿連結，備份讀出來就變成新內容；macOS 的 cp -r 會跟著連結，所以這組在 macOS 本來就綠。
T1_HOME=$(mktemp -d "${WORK:-${TMPDIR:-/tmp}}/t1.XXXXXX")
mkdir -p "$T1_HOME/.claude" "$T1_HOME/dotfiles"
printf '我自己的全域規則\n' > "$T1_HOME/dotfiles/CLAUDE.md"
ln -s "$T1_HOME/dotfiles/CLAUDE.md" "$T1_HOME/.claude/CLAUDE.md"
HOME="$T1_HOME" ./install-dd-pipeline.sh --force < /dev/null > "$T1_HOME/out.txt" 2>&1 \
    || { echo "❌ T1：--force 安裝失敗"; cat "$T1_HOME/out.txt"; exit 1; }
t1_bak=$(find "$T1_HOME/.claude/backups" -path '*/global/CLAUDE.md' 2>/dev/null | head -1)
[ -n "$t1_bak" ] || { echo "❌ T1：找不到全域 CLAUDE.md 的備份"; exit 1; }
[ "$(cat "$t1_bak")" = "我自己的全域規則" ] \
    || { echo "❌ T1：備份的內容不是原本的內容（備份第一行：$(head -1 "$t1_bak")）"; exit 1; }
cmp -s templates/global/CLAUDE.md "$T1_HOME/.claude/CLAUDE.md" \
    || { echo "❌ T1：--force 之後全域 CLAUDE.md 不是模板內容"; exit 1; }
echo "✅ T1 全域 CLAUDE.md 是 symlink 時，--force 覆蓋前備份的是它指到的內容"
# --- T1 結束

# --- T2：jq 與 python3 兩條路徑逐項等價（install_plugins／uninstall／plugin_enabled_state／mcp_scope）
# 每個案例、每一臂各開一個沙盒 HOME，交給另一個 bash 行程跑真的函式：行程裡照安裝腳本自己的 set -e 跑。
# 不在這支測試裡直接 `函式 || rc=$?` —— 那樣呼叫，bash 會讓函式裡的 set -e 失效，測到的就不是真的安裝行為；
# 而且這支測試上面那行 source 是在真實 HOME 下跑的，CLAUDE_DIR 已經定死，直接呼叫會寫進真的 ~/.claude。
# python3 那一臂靠重新定義 command_exists（對 jq 回 1）走到。
command -v jq >/dev/null 2>&1 || { echo "❌ T2：這台機器沒有 jq —— 兩臂會走同一條路，等價比對沒有意義"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ T2：這台機器沒有 python3 —— 兩臂會走同一條路，等價比對沒有意義"; exit 1; }
T2_DIR=$(mktemp -d "$WORK/t2.XXXXXX")
T2_KEY="${OFFICIAL_PLUGINS[0]}@${PLUGINS_MARKETPLACE}"
cat > "$T2_DIR/drive.sh" <<'DRIVE'
# $1=要跑的函式 $2=臂（jq|py） $3=沙盒 HOME $4=plugin key；在 repo 根目錄執行
export HOME="$3"
# shellcheck source=/dev/null
source ./install-dd-pipeline.sh
if [ "$2" = py ]; then
    command_exists() { [ "$1" != jq ] && command -v "$1" >/dev/null 2>&1; }
fi
if command_exists jq; then echo jq; else echo python3; fi > "$HOME/arm.txt"
case "$1" in
    install)   install_plugins ;;
    uninstall) ASSUME_YES=true; uninstall ;;
    state)     plugin_enabled_state "$4" "$HOME/.claude/settings.json" ;;
    mcp)       mcp_scope playwright "$HOME/.claude.json" ;;
esac
DRIVE

t2_canon() {  # 印檔案的正規化內容：鍵排序、時間戳換成 TS；解析不了就印位元組數與開頭
    python3 - "$1" <<'PY'
import json, os, sys
p = sys.argv[1]
if not os.path.exists(p):
    print("(absent)")
    sys.exit()
raw = open(p, "rb").read()
try:
    d = json.loads(raw.decode("utf-8"))
except Exception:
    print("RAW %d bytes: %r" % (len(raw), raw[:40]))
    sys.exit()
def scrub(o):
    if isinstance(o, dict):
        return dict((k, "TS" if k in ("installedAt", "lastUpdated") else scrub(v)) for k, v in o.items())
    if isinstance(o, list):
        return [scrub(x) for x in o]
    return o
print(json.dumps(scrub(d), sort_keys=True, ensure_ascii=False))
PY
}

t2_mkhome() {  # $1=沙盒 HOME：建假的 marketplace，每個官方 plugin 的 plugin.json 都有 version
    local p d
    for p in "${OFFICIAL_PLUGINS[@]}"; do
        d="$1/.claude/plugins/marketplaces/$PLUGINS_MARKETPLACE/plugins/$p/.claude-plugin"
        mkdir -p "$d"
        printf '{"name":"%s","version":"1.2.3"}\n' "$p" > "$d/plugin.json"
    done
}

T2_FAILED=""
T2_COUNT=0
# $1=函式 $2=案例名 $3=settings.json $4=installed_plugins.json $5=~/.claude.json（三個都可填 @absent=不建檔）
# $6=兩臂的結論都要符合的 regex（可空） $7=兩臂的結論都不可以出現的 regex（可空）
t2_case() {
    local site="$1" name="$2" arm h rc why=""
    T2_COUNT=$((T2_COUNT + 1))
    for arm in jq py; do
        h=$(mktemp -d "$T2_DIR/h.XXXXXX")
        t2_mkhome "$h"
        if [ "$3" != "@absent" ]; then printf '%s' "$3" > "$h/.claude/settings.json"; fi
        if [ "$4" != "@absent" ]; then printf '%s' "$4" > "$h/.claude/plugins/installed_plugins.json"; fi
        if [ "$5" != "@absent" ]; then printf '%s' "$5" > "$h/.claude.json"; fi
        rc=0
        "$BASH" "$T2_DIR/drive.sh" "$site" "$arm" "$h" "$T2_KEY" < /dev/null \
            > "$h/out.txt" 2> "$T2_DIR/$site.$name.$arm.err" || rc=$?
        {
            sed $'s/\x1b\\[[0-9;]*m//g' "$h/out.txt"
            echo "rc=$rc"
            echo "settings: $(t2_canon "$h/.claude/settings.json")"
            echo "installed: $(t2_canon "$h/.claude/plugins/installed_plugins.json")"
        } | sed "s|$h|<HOME>|g" > "$T2_DIR/$site.$name.$arm.txt"
        cp "$h/arm.txt" "$T2_DIR/$site.$name.$arm.arm" 2>/dev/null || echo "沒寫出" > "$T2_DIR/$site.$name.$arm.arm"
        rm -rf "$h"
    done
    [ "$(cat "$T2_DIR/$site.$name.jq.arm")" = jq ] || why="${why} jq 那一臂沒走 jq；"
    [ "$(cat "$T2_DIR/$site.$name.py.arm")" = python3 ] || why="${why} python3 那一臂沒走 python3；"
    # set -e 被 `|| rc=$?` 接住之後擋不到 shell 錯誤，另外看 stderr（樣式同 test-gate.sh）
    if grep -qE 'bad substitution|syntax error|command not found|invalid option|unbound variable|: line [0-9]+: ' \
        "$T2_DIR/$site.$name.jq.err" "$T2_DIR/$site.$name.py.err"; then
        why="${why} stderr 有 shell 錯誤；"
    fi
    cmp -s "$T2_DIR/$site.$name.jq.txt" "$T2_DIR/$site.$name.py.txt" || why="${why} 兩臂結論不同；"
    for arm in jq py; do
        if [ -n "$6" ] && ! grep -qE -- "$6" "$T2_DIR/$site.$name.$arm.txt"; then
            why="${why} ${arm} 那一臂沒有出現「${6}」；"
        fi
        if [ -n "${7:-}" ] && grep -qE -- "$7" "$T2_DIR/$site.$name.$arm.txt"; then
            why="${why} ${arm} 那一臂出現了不該有的「${7}」；"
        fi
    done
    if [ -n "$why" ]; then
        T2_FAILED="${T2_FAILED}${site}.${name} "
        echo "❌ T2 ${site}.${name}：${why}"
    fi
}

T2_OK_SETTINGS='^settings: \{"enabledPlugins": \{"[^"]+": true'
T2_OK_INSTALLED='^installed: \{"plugins": \{"[^"]+": \[\{"installPath": "<HOME>/\.claude/plugins/cache/[^"]+/1\.2\.3"'

# settings.json 的 15 種內容 × 安裝／移除／查啟用狀態。三類定案的結論直接斷言：
#   空檔、只有空白、頂層不是物件 → 失敗、不改檔；enabledPlugins 是 null → 當成沒有這個鍵；
#   plugin_enabled_state 對頂層不是物件回 none 是既有的刻意設計，不在這條裡
t2_case install   s-absent    "@absent" "@absent" "@absent" "$T2_OK_SETTINGS"
t2_case uninstall s-absent    "@absent" "@absent" "@absent" '^settings: \(absent\)$' '解析失敗'
t2_case state     s-absent    "@absent" "@absent" "@absent" '^none$'
t2_case install   s-empty     ''        "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-empty     ''        "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-empty     ''        "@absent" "@absent" '^unparseable$'
t2_case install   s-blank     '  
'                                       "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-blank     '  
'                                       "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-blank     '  
'                                       "@absent" "@absent" '^unparseable$'
t2_case install   s-badjson   '{'       "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-badjson   '{'       "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-badjson   '{'       "@absent" "@absent" '^unparseable$'
t2_case install   s-null      'null'    "@absent" "@absent" '^settings: null$' '已啟用'
t2_case uninstall s-null      'null'    "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-null      'null'    "@absent" "@absent" '^none$'
t2_case install   s-array     '[]'      "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-array     '[]'      "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-array     '[]'      "@absent" "@absent" '^none$'
t2_case install   s-string    '"str"'   "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-string    '"str"'   "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-string    '"str"'   "@absent" "@absent" '^none$'
t2_case install   s-number    '123'     "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-number    '123'     "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-number    '123'     "@absent" "@absent" '^none$'
t2_case install   s-emptyobj  '{}'      "@absent" "@absent" "$T2_OK_SETTINGS"
t2_case uninstall s-emptyobj  '{}'      "@absent" "@absent" '^settings: \{\}$' '解析失敗'
t2_case state     s-emptyobj  '{}'      "@absent" "@absent" '^none$'
t2_case install   s-ep-null   '{"enabledPlugins":null}' "@absent" "@absent" "$T2_OK_SETTINGS" '更新失敗'
t2_case uninstall s-ep-null   '{"enabledPlugins":null}' "@absent" "@absent" '^settings: \{"enabledPlugins": null\}$' '解析失敗'
t2_case state     s-ep-null   '{"enabledPlugins":null}' "@absent" "@absent" '^none$'
t2_case install   s-ep-string '{"enabledPlugins":"x"}'  "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-ep-string '{"enabledPlugins":"x"}'  "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-ep-string '{"enabledPlugins":"x"}'  "@absent" "@absent" '^none$'
t2_case install   s-ep-array  '{"enabledPlugins":[]}'   "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-ep-array  '{"enabledPlugins":[]}'   "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-ep-array  '{"enabledPlugins":[]}'   "@absent" "@absent" '^none$'
t2_case install   s-ep-other  '{"enabledPlugins":{"other@m":false},"keep":1}' "@absent" "@absent" '"other@m": false.*"keep": 1\}$' '更新失敗'
t2_case uninstall s-ep-other  '{"enabledPlugins":{"other@m":false},"keep":1}' "@absent" "@absent" '^settings: \{"enabledPlugins": \{"other@m": false\}, "keep": 1\}$' '解析失敗'
t2_case state     s-ep-other  '{"enabledPlugins":{"other@m":false},"keep":1}' "@absent" "@absent" '^none$'
t2_case install   s-ep-false  "{\"enabledPlugins\":{\"$T2_KEY\":false}}" "@absent" "@absent" "$T2_OK_SETTINGS"
t2_case uninstall s-ep-false  "{\"enabledPlugins\":{\"$T2_KEY\":false}}" "@absent" "@absent" '^settings: \{"enabledPlugins": \{\}\}$' '解析失敗'
t2_case state     s-ep-false  "{\"enabledPlugins\":{\"$T2_KEY\":false}}" "@absent" "@absent" '^disabled$'
t2_case install   s-ep-true   "{\"enabledPlugins\":{\"$T2_KEY\":true}}"  "@absent" "@absent" "$T2_OK_SETTINGS"
t2_case uninstall s-ep-true   "{\"enabledPlugins\":{\"$T2_KEY\":true}}"  "@absent" "@absent" '^settings: \{"enabledPlugins": \{\}\}$' '解析失敗'
t2_case state     s-ep-true   "{\"enabledPlugins\":{\"$T2_KEY\":true}}"  "@absent" "@absent" '^enabled$'

# installed_plugins.json 的 16 種內容 × 安裝／移除。登記項的第一筆不是物件（[null]、["x"]）→ 失敗、不改檔
T2_E='{"enabledPlugins":{}}'
t2_case install   p-absent        "@absent" "@absent" "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-absent        "$T2_E"   "@absent" "@absent" '^installed: \(absent\)$' '解析失敗'
t2_case install   p-empty         "@absent" ''        "@absent" 'installed_plugins\.json 更新失敗' '已啟用'
t2_case uninstall p-empty         "$T2_E"   ''        "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-badjson       "@absent" '{'       "@absent" 'installed_plugins\.json 更新失敗' '已啟用'
t2_case uninstall p-badjson       "$T2_E"   '{'       "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-null          "@absent" 'null'    "@absent" '^installed: null$' '已啟用'
t2_case uninstall p-null          "$T2_E"   'null'    "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-array         "@absent" '[]'      "@absent" 'installed_plugins\.json 更新失敗' '已啟用'
t2_case uninstall p-array         "$T2_E"   '[]'      "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-emptyobj      "@absent" '{}'      "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-emptyobj      "$T2_E"   '{}'      "@absent" '^installed: \{\}$' '解析失敗'
t2_case install   p-plugins-null  "@absent" '{"plugins":null}'  "@absent" "$T2_OK_INSTALLED" '更新失敗'
t2_case uninstall p-plugins-null  "$T2_E"   '{"plugins":null}'  "@absent" '^installed: \{"plugins": null\}$' '解析失敗'
t2_case install   p-plugins-array "@absent" '{"plugins":[]}'    "@absent" 'installed_plugins\.json 更新失敗' '已啟用'
t2_case uninstall p-plugins-array "$T2_E"   '{"plugins":[]}'    "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-plugins-str   "@absent" '{"plugins":"x"}'   "@absent" 'installed_plugins\.json 更新失敗' '已啟用'
t2_case uninstall p-plugins-str   "$T2_E"   '{"plugins":"x"}'   "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-skeleton      "@absent" '{"version":2,"plugins":{}}' "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-skeleton      "$T2_E"   '{"version":2,"plugins":{}}' "@absent" '^installed: \{"plugins": \{\}, "version": 2\}$' '解析失敗'
t2_case install   p-entry-empty   "@absent" "{\"plugins\":{\"$T2_KEY\":[]}}"   "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-entry-empty   "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[]}}"   "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-obj     "@absent" "{\"plugins\":{\"$T2_KEY\":{}}}"   "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-entry-obj     "$T2_E"   "{\"plugins\":{\"$T2_KEY\":{}}}"   "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-str     "@absent" "{\"plugins\":{\"$T2_KEY\":\"x\"}}" "@absent" "${OFFICIAL_PLUGINS[0]}: .*installed_plugins\\.json 更新失敗"
t2_case uninstall p-entry-str     "$T2_E"   "{\"plugins\":{\"$T2_KEY\":\"x\"}}" "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-valid   "@absent" "{\"plugins\":{\"$T2_KEY\":[{\"version\":\"0.9\",\"installPath\":\"/old\",\"installedAt\":\"A\",\"lastUpdated\":\"B\"}]}}" "@absent" "$T2_OK_INSTALLED" '/old'
t2_case uninstall p-entry-valid   "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[{\"version\":\"0.9\",\"installPath\":\"/old\",\"installedAt\":\"A\",\"lastUpdated\":\"B\"}]}}" "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-null    "@absent" "{\"plugins\":{\"$T2_KEY\":[null]}}"  "@absent" "${OFFICIAL_PLUGINS[0]}: .*installed_plugins\\.json 更新失敗"
t2_case uninstall p-entry-null    "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[null]}}"  "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-stritem "@absent" "{\"plugins\":{\"$T2_KEY\":[\"x\"]}}" "@absent" "${OFFICIAL_PLUGINS[0]}: .*installed_plugins\\.json 更新失敗"
t2_case uninstall p-entry-stritem "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[\"x\"]}}" "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'

# ~/.claude.json 的 15 種內容 × mcp_scope。解析不了、或頂層不是物件 → unparseable（無從判定），不可以講成 none（確定沒有）
t2_case mcp c-absent        "@absent" "@absent" "@absent"  '^none$'
t2_case mcp c-empty         "@absent" "@absent" ''         '^unparseable$'
t2_case mcp c-badjson       "@absent" "@absent" '{'        '^unparseable$'
t2_case mcp c-null          "@absent" "@absent" 'null'     '^unparseable$'
t2_case mcp c-array         "@absent" "@absent" '[]'       '^unparseable$'
t2_case mcp c-string        "@absent" "@absent" '"str"'    '^unparseable$'
t2_case mcp c-emptyobj      "@absent" "@absent" '{}'       '^none$'
t2_case mcp c-servers-null  "@absent" "@absent" '{"mcpServers":null}' '^none$'
t2_case mcp c-servers-array "@absent" "@absent" '{"mcpServers":[]}'   '^none$'
t2_case mcp c-global        "@absent" "@absent" '{"mcpServers":{"playwright":{}}}' '^global$'
t2_case mcp c-projects-null "@absent" "@absent" '{"projects":null}'   '^none$'
t2_case mcp c-projects-arr  "@absent" "@absent" '{"projects":[]}'     '^none$'
t2_case mcp c-project-null  "@absent" "@absent" '{"projects":{"/a":null}}' '^none$'
t2_case mcp c-local         "@absent" "@absent" '{"projects":{"/a":{"mcpServers":{"playwright":{}}},"/b":{"mcpServers":null}}}' '^local:1$'
t2_case mcp c-mixed         "@absent" "@absent" '{"mcpServers":"x","projects":{"/a":{"mcpServers":{"playwright":1}}}}' '^local:1$'

if [ -n "$T2_FAILED" ]; then
    echo "❌ T2：${T2_COUNT} 個案例裡有不符的：${T2_FAILED}"
    exit 1
fi
echo "✅ T2 jq 與 python3 兩條路徑在 ${T2_COUNT} 個假設定檔案例上結論相同，定案的結論也都對"
