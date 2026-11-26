#!/bin/bash
# 安裝腳本（install-dd-pipeline.sh）的端到端測試：在拋棄式 HOME 裡非互動安裝，驗部署內容、冪等、
# --force／--update／--commands-only／--uninstall 與 --check 不寫入。
# 2026-11-14 補上 T1–T9：symlink 的備份、jq 與 python3 兩條路徑的等價表（只守它列的那幾類輸入）、plugin 登記、--check 的 MCP 輸出、
# 覆蓋前備份、全域 CLAUDE.md 三種情境、hook 路徑驗證、舊指令檔的備份、完成訊息。
# 2026-11-15 補上 T10：環境檢查的自動壓縮視窗那一行；T2 的等價表加 `autocompact_state`。
# 2026-11-15 補上 T11：`--check` 看得出部署的 skill、agent 與 repo 這份不同。
# 2026-11-26 補上 T12：環境檢查的「AGENTS.md 載入」那一行；T2 的等價表加 `agents_md_state`。
# 測不到的：全域 CLAUDE.md 的互動選單（ask 用 [ -t 0 ] 判斷，管線餵 stdin 一律走預設值）。
# CI 在 ubuntu（bash 5）與 macOS（/bin/bash 3.2）各跑一次（.github/workflows/ci.yml）。
# 2026-10-01 從 ci.yml 內嵌 step 搬出來，macOS 那個 job 才能共用；判斷一行都沒改。
#
# 用法：tests/test-install.sh　（在哪個目錄跑都可以；只寫拋棄式 HOME 與暫存目錄，跑完清掉）
#       TEST_ONLY=T5 tests/test-install.sh　（原有的檢查與 T1 照跑，T2 之後只跑指定那一組；本機做變異實驗用）
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
[ -f "$SANDBOX/.claude/commands/dd-stop.md" ]
# 2026-11-15 起沒有命名空間 command（NS_COMMANDS 是空的）：commands/ 底下不該有子目錄。
# 加回命名空間 command 時，把「目錄在、README.md 沒被部署」那兩條斷言加回來
[ -z "$(find "$SANDBOX/.claude/commands" -mindepth 1 -maxdepth 1 -type d)" ]
[ -x "$SANDBOX/.claude/scripts/check-claude-md.sh" ]
[ -x "$SANDBOX/.claude/scripts/dd-stop.sh" ]
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
[ -f "$SANDBOX/.claude/commands/dd-stop.md" ]
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
# 以下各組：T1–T9 在 2026-11-14 補上（碰設定檔、備份與完成訊息的路徑），T10 在 2026-11-15 補上（環境檢查的自動壓縮視窗那一行），
# T11 在 2026-11-15 補上（`--check` 的 skill、agent 那兩段看得出部署版與 repo 不同），T12 在 2026-11-26 補上（環境檢查的 AGENTS.md 載入那一行）。
# 斷言失敗時一律印出「組名＋斷言名」再 exit 1 —— 上面那些裸 [ … ] 在 set -e 下失敗不印任何字。
# 本機做變異實驗時可以只跑一組：`TEST_ONLY=T5 tests/test-install.sh`（上面原有的檢查與 T1 照跑，T2 之後只跑指定那組）。
# ---------------------------------------------------------------------------
# TEST_ONLY 打錯（t5、T05）時會一組都沒跑卻 rc=0，所以先驗值；新增一組時這裡要跟著加
case "${TEST_ONLY:-}" in
    ""|T2|T3|T4|T5|T6|T7|T8|T9|T10|T11|T12) ;;
    *) echo "❌ TEST_ONLY=${TEST_ONLY} 不是 T2–T12 其中一組"; exit 2 ;;
esac
want() { [ -z "${TEST_ONLY:-}" ] || [ "$TEST_ONLY" = "$1" ]; }
# 去掉顏色碼。LC_ALL=C：輸出裡有壞的位元組時，UTF-8 locale 下的 BSD sed 印到那一行就失敗、
# 那一行之後的內容全部不見，「不可以出現某字」的斷言就可能空通過
plain() { LC_ALL=C sed $'s/\x1b\\[[0-9;]*m//g' "$1"; }
# 輸出是不是合法的 UTF-8：訊息裡的變數緊貼全形字（`$old（…`）時 bash 3.2 會把變數名吃掉、印出壞的位元組
# 轉出來的內容要寫到檔案、不可以丟 /dev/null：macOS 的 iconv 在輸出是 /dev/null、而某個多位元組字剛好跨過 1024 位元組邊界時，
# 會對合法的 UTF-8 回 1（2026-11-15 在 macOS 27.0.1 實測；寫到檔案或管線就正常，壞的位元組照樣回 1）
utf8_ok() { iconv -f UTF-8 -t UTF-8 "$1" > "${WORK:-${TMPDIR:-/tmp}}/utf8_ok.out" 2> /dev/null; }

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

# --- T2：jq 與 python3 兩條路徑逐項等價（install_plugins／uninstall／plugin_enabled_state／mcp_scope／autocompact_state／agents_md_state）
# 每個案例、每一臂各開一個沙盒 HOME，交給另一個 bash 行程跑真的函式：行程裡照安裝腳本自己的 set -e 跑。
# 不在這支測試裡直接 `函式 || rc=$?` —— 那樣呼叫，bash 會讓函式裡的 set -e 失效，測到的就不是真的安裝行為；
# 而且這支測試上面那行 source 是在真實 HOME 下跑的，CLAUDE_DIR 已經定死，直接呼叫會寫進真的 ~/.claude。
# python3 那一臂靠重新定義 command_exists（對 jq 回 1）走到。
command -v python3 >/dev/null 2>&1 || { echo "❌ 這台機器沒有 python3 —— T2 的另一臂要它，T3 之後各組也用它把 JSON 正規化再比"; exit 1; }
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
    acw)       unset CLAUDE_CODE_AUTO_COMPACT_WINDOW   # 開發者的 shell 設著它的話，每一格都會變成 env
               autocompact_state "$HOME/.claude/settings.json" ;;
    agents)    agents_md_state "$HOME/.claude/settings.json" ;;
esac
DRIVE

t2_canon() {  # 印檔案的正規化內容：鍵排序、安裝腳本填的時間戳換成 TS（別的值照留）；解析不了就印位元組數與開頭
    python3 - "$1" <<'PY'
import json, os, re, sys
ISO = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T")
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
        return dict((k, "TS" if k in ("installedAt", "lastUpdated") and isinstance(v, str) and ISO.match(v) else scrub(v))
                    for k, v in o.items())
    if isinstance(o, list):
        return [scrub(x) for x in o]
    return o
print(json.dumps(scrub(d), sort_keys=True, ensure_ascii=False))
PY
}

T2_PLUGIN_JSON=""   # 非空時，第一個官方 plugin 的 plugin.json 改用這份內容
t2_mkhome() {  # $1=沙盒 HOME：建假的 marketplace，每個官方 plugin 的 plugin.json 都有 version
    local p d
    for p in "${OFFICIAL_PLUGINS[@]}"; do
        d="$1/.claude/plugins/marketplaces/$PLUGINS_MARKETPLACE/plugins/$p/.claude-plugin"
        mkdir -p "$d"
        if [ -n "$T2_PLUGIN_JSON" ] && [ "$p" = "${OFFICIAL_PLUGINS[0]}" ]; then
            printf '%s' "$T2_PLUGIN_JSON" > "$d/plugin.json"
        else
            printf '{"name":"%s","version":"1.2.3"}\n' "$p" > "$d/plugin.json"
        fi
    done
}

T2_FAILED=""
T2_COUNT=0
# $1=函式 $2=案例名 $3=settings.json $4=installed_plugins.json $5=~/.claude.json（三個都可填 @absent=不建檔）
# $6=兩臂的結論都要符合的 regex $7=兩臂的結論都不可以出現的 regex（都可空；要放好幾條就一行一條，用 $NL 接）
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
    local pat
    for arm in jq py; do
        while IFS= read -r pat; do
            [ -z "$pat" ] && continue
            grep -qE -- "$pat" "$T2_DIR/$site.$name.$arm.txt" || why="${why} ${arm} 那一臂沒有出現「${pat}」；"
        done <<EOF
$6
EOF
        while IFS= read -r pat; do
            [ -z "$pat" ] && continue
            if grep -qE -- "$pat" "$T2_DIR/$site.$name.$arm.txt"; then why="${why} ${arm} 那一臂出現了不該有的「${pat}」；"; fi
        done <<EOF
${7:-}
EOF
    done
    if [ -n "$why" ]; then
        T2_FAILED="${T2_FAILED}${site}.${name} "
        echo "❌ T2 ${site}.${name}：${why}"
    fi
}

if want T2; then
command -v jq >/dev/null 2>&1 || { echo "❌ T2：這台機器沒有 jq —— 兩臂會走同一條路，等價比對沒有意義"; exit 1; }
NL=$'\n'
T2_BOM=$'\xef\xbb\xbf'
T2_OK_SETTINGS='^settings: \{"enabledPlugins": \{"[^"]+": true'
T2_OK_INSTALLED='^installed: \{"plugins": \{"[^"]+": \[\{"installPath": "<HOME>/\.claude/plugins/cache/[^"]+/1\.2\.3"'

# settings.json 的各種內容 × 安裝／移除／查啟用狀態。定案的結論直接斷言：
#   空檔、只有空白、頂層不是物件、檔案裡不只一個 JSON 值 → 失敗、不改檔（查啟用狀態回 unparseable）；
#   enabledPlugins 是 null → 當成沒有這個鍵；是字串或陣列 → 安裝與移除失敗，查啟用狀態回 none（頂層是物件、只是那個鍵型別不對）；
#   開頭有 UTF-8 BOM → 當成正常的檔
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
t2_case state     s-null      'null'    "@absent" "@absent" '^unparseable$'
t2_case install   s-array     '[]'      "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-array     '[]'      "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-array     '[]'      "@absent" "@absent" '^unparseable$'
t2_case install   s-string    '"str"'   "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-string    '"str"'   "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-string    '"str"'   "@absent" "@absent" '^unparseable$'
t2_case install   s-number    '123'     "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-number    '123'     "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-number    '123'     "@absent" "@absent" '^unparseable$'
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
t2_case install   s-multi     '{} {}'   "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-multi     '{} {}'   "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-multi     '{} {}'   "@absent" "@absent" '^unparseable$'
t2_case install   s-nullobj   'null {}' "@absent" "@absent" 'settings\.json 更新失敗' '已啟用'
t2_case uninstall s-nullobj   'null {}' "@absent" "@absent" 'settings\.json 解析失敗'
t2_case state     s-nullobj   'null {}' "@absent" "@absent" '^unparseable$'
t2_case install   s-bom       "${T2_BOM}{}" "@absent" "@absent" "$T2_OK_SETTINGS" '更新失敗'
t2_case uninstall s-bom       "${T2_BOM}{}" "@absent" "@absent" '^settings: \{\}$' '解析失敗'
t2_case state     s-bom       "${T2_BOM}{\"enabledPlugins\":{\"$T2_KEY\":true}}" "@absent" "@absent" '^enabled$'

# installed_plugins.json 的各種內容 × 安裝／移除。登記項的第一筆不是物件（[null]、["x"]）→ 失敗、不改檔。
# 登記失敗的 plugin 不可以已經在 settings.json 被寫成啟用（先登記、再啟用）
T2_E='{"enabledPlugins":{}}'
T2_INST_FAIL='installed_plugins\.json 更新失敗'"$NL"'^settings: \(absent\)$'
T2_FIRST_FAIL="${OFFICIAL_PLUGINS[0]}: .*installed_plugins\\.json 更新失敗"
T2_FIRST_ON="^settings: .*\"${T2_KEY}\": true"
t2_case install   p-absent        "@absent" "@absent" "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-absent        "$T2_E"   "@absent" "@absent" '^installed: \(absent\)$' '解析失敗'
t2_case install   p-empty         "@absent" ''        "@absent" "$T2_INST_FAIL" '已啟用'
t2_case uninstall p-empty         "$T2_E"   ''        "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-badjson       "@absent" '{'       "@absent" "$T2_INST_FAIL" '已啟用'
t2_case uninstall p-badjson       "$T2_E"   '{'       "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-null          "@absent" 'null'    "@absent" '^installed: null$'"$NL"'^settings: \(absent\)$' '已啟用'
t2_case uninstall p-null          "$T2_E"   'null'    "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-array         "@absent" '[]'      "@absent" "$T2_INST_FAIL" '已啟用'
t2_case uninstall p-array         "$T2_E"   '[]'      "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-emptyobj      "@absent" '{}'      "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-emptyobj      "$T2_E"   '{}'      "@absent" '^installed: \{\}$' '解析失敗'
t2_case install   p-plugins-null  "@absent" '{"plugins":null}'  "@absent" "$T2_OK_INSTALLED" '更新失敗'
t2_case uninstall p-plugins-null  "$T2_E"   '{"plugins":null}'  "@absent" '^installed: \{"plugins": null\}$' '解析失敗'
t2_case install   p-plugins-array "@absent" '{"plugins":[]}'    "@absent" "$T2_INST_FAIL" '已啟用'
t2_case uninstall p-plugins-array "$T2_E"   '{"plugins":[]}'    "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-plugins-str   "@absent" '{"plugins":"x"}'   "@absent" "$T2_INST_FAIL" '已啟用'
t2_case uninstall p-plugins-str   "$T2_E"   '{"plugins":"x"}'   "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-skeleton      "@absent" '{"version":2,"plugins":{}}' "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-skeleton      "$T2_E"   '{"version":2,"plugins":{}}' "@absent" '^installed: \{"plugins": \{\}, "version": 2\}$' '解析失敗'
t2_case install   p-entry-empty   "@absent" "{\"plugins\":{\"$T2_KEY\":[]}}"   "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-entry-empty   "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[]}}"   "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-obj     "@absent" "{\"plugins\":{\"$T2_KEY\":{}}}"   "@absent" "$T2_OK_INSTALLED"
t2_case uninstall p-entry-obj     "$T2_E"   "{\"plugins\":{\"$T2_KEY\":{}}}"   "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-str     "@absent" "{\"plugins\":{\"$T2_KEY\":\"x\"}}" "@absent" "$T2_FIRST_FAIL" "$T2_FIRST_ON"
t2_case uninstall p-entry-str     "$T2_E"   "{\"plugins\":{\"$T2_KEY\":\"x\"}}" "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
# 既有的登記：只更新 version／lastUpdated／installPath，installedAt 與其他欄位要留著（整筆新建的話這兩個斷言會紅）
t2_case install   p-entry-valid   "@absent" "{\"plugins\":{\"$T2_KEY\":[{\"version\":\"0.9\",\"installPath\":\"/old\",\"installedAt\":\"A\",\"lastUpdated\":\"B\",\"keepme\":1}]}}" "@absent" "${T2_OK_INSTALLED}${NL}\"installedAt\": \"A\"${NL}\"keepme\": 1" '/old'
t2_case uninstall p-entry-valid   "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[{\"version\":\"0.9\",\"installPath\":\"/old\",\"installedAt\":\"A\",\"lastUpdated\":\"B\",\"keepme\":1}]}}" "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-null    "@absent" "{\"plugins\":{\"$T2_KEY\":[null]}}"  "@absent" "$T2_FIRST_FAIL" "$T2_FIRST_ON"
t2_case uninstall p-entry-null    "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[null]}}"  "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-entry-stritem "@absent" "{\"plugins\":{\"$T2_KEY\":[\"x\"]}}" "@absent" "$T2_FIRST_FAIL" "$T2_FIRST_ON"
t2_case uninstall p-entry-stritem "$T2_E"   "{\"plugins\":{\"$T2_KEY\":[\"x\"]}}" "@absent" '^installed: \{"plugins": \{\}\}$' '解析失敗'
t2_case install   p-multi         "@absent" '{} {}'   "@absent" "$T2_INST_FAIL" '已啟用'
t2_case uninstall p-multi         "$T2_E"   '{} {}'   "@absent" 'installed_plugins\.json 解析失敗'
t2_case install   p-bom           "@absent" "${T2_BOM}{}" "@absent" "$T2_OK_INSTALLED" '更新失敗'
t2_case uninstall p-bom           "$T2_E"   "${T2_BOM}{}" "@absent" '^installed: \{\}$' '解析失敗'

# plugin.json（marketplace 裡那份）不只一個 JSON 值 → 當成讀不到版本；開頭有 BOM → 照常讀
T2_PLUGIN_JSON='{"version":"9.9.9"} {}'
t2_case install   j-multi         "@absent" "@absent" "@absent" "${OFFICIAL_PLUGINS[0]}: .*都取不到版本字串" "${OFFICIAL_PLUGINS[0]} \\(v"
T2_PLUGIN_JSON="${T2_BOM}{\"version\":\"1.2.3\"}"
t2_case install   j-bom           "@absent" "@absent" "@absent" "${OFFICIAL_PLUGINS[0]} \\(v1\\.2\\.3\\): .*已啟用"
# plugin.json 沒有 version（官方 skill-creator 就是這樣）→ 改讀 installed_plugins.json 裡 Claude Code 自己記的值；
# 那份不只一個 JSON 值時讀不到、照樣算沒有版本
T2_PLUGIN_JSON='{"name":"no-version-here"}'
t2_case install   j-noversion     "@absent" "{\"plugins\":{\"$T2_KEY\":[{\"version\":\"85cce0381e78\",\"installPath\":\"/old\",\"installedAt\":\"A\",\"lastUpdated\":\"B\"}]}}" "@absent" "${OFFICIAL_PLUGINS[0]} \\(v85cce0381e78\\): .*已啟用${NL}/cache/[^\"]+/85cce0381e78\"" '取不到版本'
t2_case install   j-nover-multi   "@absent" "{\"plugins\":{\"$T2_KEY\":[{\"version\":\"85cce0381e78\"}]}} {}" "@absent" "${OFFICIAL_PLUGINS[0]}: .*都取不到版本字串" "${OFFICIAL_PLUGINS[0]} \\(v"
T2_PLUGIN_JSON=""

# ~/.claude.json 的各種內容 × mcp_scope。解析不了、頂層不是物件、或不只一個 JSON 值 → unparseable（無從判定），不可以講成 none（確定沒有）
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
t2_case mcp c-multi         "@absent" "@absent" '{"mcpServers":{"playwright":{}}} {}' '^unparseable$' '^(global|none)$'
t2_case mcp c-bom           "@absent" "@absent" "${T2_BOM}{\"mcpServers\":{\"playwright\":{}}}" '^global$'

# settings.json 的各種內容 × 自動壓縮視窗的狀態（autocompact_state）。「有效值」= 100000–1000000 之間、值是整數的數字（布林不算）。
#   整份檔案解析不了、或不是剛好一個物件 → unparseable；
#   最上層的鍵是有效值 → all；鍵在、不是 null、又不是有效值（範圍外、非整數、字串、布林）→ outofrange（個別模型有沒有值都一樣）；
#   最上層沒有這個鍵或是 null：modelSettings 底下至少一個模型是有效值 → permodel，否則 none；
#   modelSettings 不是物件、某個模型的值不是物件 → 略過那一格
T2_PM='"modelSettings":{"m":{"effortLevel":"high","autoCompactWindow":400000}}'
t2_case acw a-absent      "@absent" "@absent" "@absent" '^none$'
t2_case acw a-empty       ''        "@absent" "@absent" '^unparseable$'
t2_case acw a-badjson     '{'       "@absent" "@absent" '^unparseable$'
t2_case acw a-null        'null'    "@absent" "@absent" '^unparseable$'
t2_case acw a-array       '[]'      "@absent" "@absent" '^unparseable$'
t2_case acw a-emptyobj    '{}'      "@absent" "@absent" '^none$'
t2_case acw a-top-valid   '{"autoCompactWindow":400000}'   "@absent" "@absent" '^all$'
t2_case acw a-top-min     '{"autoCompactWindow":100000}'   "@absent" "@absent" '^all$'
t2_case acw a-top-max     '{"autoCompactWindow":1000000}'  "@absent" "@absent" '^all$'
t2_case acw a-top-float   '{"autoCompactWindow":400000.0}' "@absent" "@absent" '^all$'
t2_case acw a-top-frac    '{"autoCompactWindow":400000.5}' "@absent" "@absent" '^outofrange$'
t2_case acw a-top-5       '{"autoCompactWindow":5}'        "@absent" "@absent" '^outofrange$'
t2_case acw a-top-2m      '{"autoCompactWindow":2000000}'  "@absent" "@absent" '^outofrange$'
t2_case acw a-top-string  '{"autoCompactWindow":"400000"}' "@absent" "@absent" '^outofrange$'
t2_case acw a-top-true    '{"autoCompactWindow":true}'     "@absent" "@absent" '^outofrange$'
t2_case acw a-top-null    '{"autoCompactWindow":null}'     "@absent" "@absent" '^none$'
# NaN、Infinity 不是合法的 JSON，但 jq（1.7、1.7.1、1.8.1 實測）與 python3 的 json 都收，而且都當成數字（jq 印 NaN 會印成 null，型別仍是 number）：不是有效值
t2_case acw a-top-nan     '{"autoCompactWindow":NaN}'      "@absent" "@absent" '^outofrange$'
t2_case acw a-top-inf     '{"autoCompactWindow":Infinity}' "@absent" "@absent" '^outofrange$'
t2_case acw a-pm-nan      '{"modelSettings":{"m":{"autoCompactWindow":NaN}}}' "@absent" "@absent" '^none$'
t2_case acw a-top-null-pm "{\"autoCompactWindow\":null,${T2_PM}}" "@absent" "@absent" '^permodel$'
t2_case acw a-top-oor-pm  "{\"autoCompactWindow\":5,${T2_PM}}"    "@absent" "@absent" '^outofrange$'
t2_case acw a-both        "{\"autoCompactWindow\":400000,\"modelSettings\":{\"m\":{\"autoCompactWindow\":200000}}}" "@absent" "@absent" '^all$'
t2_case acw a-pm-valid    "{${T2_PM}}" "@absent" "@absent" '^permodel$'
t2_case acw a-pm-auto     '{"modelSettings":{"m":{"autoCompactWindow":"auto"}}}' "@absent" "@absent" '^none$'
t2_case acw a-pm-true     '{"modelSettings":{"m":{"autoCompactWindow":true}}}'   "@absent" "@absent" '^none$'
t2_case acw a-pm-5        '{"modelSettings":{"m":{"autoCompactWindow":5}}}'      "@absent" "@absent" '^none$'
t2_case acw a-ms-array    '{"modelSettings":[{"autoCompactWindow":400000}]}'     "@absent" "@absent" '^none$'
t2_case acw a-pm-notobj   '{"modelSettings":{"m":"x","n":null,"o":[400000]}}'    "@absent" "@absent" '^none$'
t2_case acw a-pm-mixed    '{"modelSettings":{"m":"x","n":{"autoCompactWindow":400000}}}' "@absent" "@absent" '^permodel$'
t2_case acw a-bom         "${T2_BOM}{\"autoCompactWindow\":400000}" "@absent" "@absent" '^all$'
t2_case acw a-multi       '{"autoCompactWindow":400000} {}' "@absent" "@absent" '^unparseable$' '^(all|none)$'
# 2026-11-15 審查時找到的四類（當時兩臂結論不同）：
#   數字字面值比 float 精確、四捨五入後剛好落在邊界上：jq（1.7、1.7.1、1.8.1 實測）拿字面值的原樣比大小，python3 先轉成 float
#   settings.json 裡有不合法的 UTF-8 位元組（跟這個鍵無關的地方）：jq 換成替代字元照樣解析，python3 預設報錯
#   別的鍵是幾千位的整數：python（3.13.2 實測）整數字串超過 4300 位就報 ValueError，jq 照收
t2_case acw a-top-edge-lo '{"autoCompactWindow":99999.99999999999999999}'  "@absent" "@absent" '^all$'
t2_case acw a-top-edge-hi '{"autoCompactWindow":1000000.0000000000000001}' "@absent" "@absent" '^all$'
t2_case acw a-badutf8     $'{"t":"caf\xe9","autoCompactWindow":400000}'    "@absent" "@absent" '^all$'
t2_case acw a-bigint      "{\"x\":1$(printf '%05000d' 0),\"autoCompactWindow\":400000}" "@absent" "@absent" '^all$'

# settings.json 的各種內容 × AGENTS.md 載入設定（agents_md_state）。看 pluginConfigs → <ID> → options.instructionFiles，
# ID 有新的 cc-plugin-agents-md@builtin 與舊的 agents-md@builtin 兩個；只認字串值，中間任何一層不是物件就當沒有。
#   官方列的四種值各回 and／or／claudemd／managedonly；別的字串 → odd；兩個 ID 都有字串值又不同 → conflict；都沒有 → none
#   整份檔案解析不了、或不是剛好一個物件 → unparseable
T2_AN='"cc-plugin-agents-md@builtin"'
T2_AO='"agents-md@builtin"'
t2_ag() { printf '{"pluginConfigs":{%s:{"options":{"instructionFiles":%s}}}}' "$1" "$2"; }
t2_case agents g-absent    "@absent" "@absent" "@absent" '^none$'
t2_case agents g-empty     ''        "@absent" "@absent" '^unparseable$'
t2_case agents g-badjson   '{'       "@absent" "@absent" '^unparseable$'
t2_case agents g-null      'null'    "@absent" "@absent" '^unparseable$'
t2_case agents g-array     '[]'      "@absent" "@absent" '^unparseable$'
t2_case agents g-emptyobj  '{}'      "@absent" "@absent" '^none$'
t2_case agents g-and       "$(t2_ag "$T2_AN" '"claude-md-and-agents-md"')" "@absent" "@absent" '^and$'
t2_case agents g-or        "$(t2_ag "$T2_AN" '"claude-md-or-agents-md"')"  "@absent" "@absent" '^or$'
t2_case agents g-claudemd  "$(t2_ag "$T2_AN" '"claude-md"')"               "@absent" "@absent" '^claudemd$'
t2_case agents g-managed   "$(t2_ag "$T2_AN" '"managed-only"')"            "@absent" "@absent" '^managedonly$'
t2_case agents g-odd       "$(t2_ag "$T2_AN" '"both"')"                    "@absent" "@absent" '^odd$'
t2_case agents g-number    "$(t2_ag "$T2_AN" '1')"                         "@absent" "@absent" '^none$'
t2_case agents g-bool      "$(t2_ag "$T2_AN" 'true')"                      "@absent" "@absent" '^none$'
t2_case agents g-old       "$(t2_ag "$T2_AO" '"claude-md-and-agents-md"')" "@absent" "@absent" '^and$'
t2_case agents g-both-same "{\"pluginConfigs\":{${T2_AN}:{\"options\":{\"instructionFiles\":\"claude-md\"}},${T2_AO}:{\"options\":{\"instructionFiles\":\"claude-md\"}}}}" "@absent" "@absent" '^claudemd$'
t2_case agents g-both-diff "{\"pluginConfigs\":{${T2_AN}:{\"options\":{\"instructionFiles\":\"claude-md\"}},${T2_AO}:{\"options\":{\"instructionFiles\":\"claude-md-and-agents-md\"}}}}" "@absent" "@absent" '^conflict$'
t2_case agents g-new-null  "{\"pluginConfigs\":{${T2_AN}:{\"options\":{\"instructionFiles\":null}},${T2_AO}:{\"options\":{\"instructionFiles\":\"claude-md-or-agents-md\"}}}}" "@absent" "@absent" '^or$'
t2_case agents g-pc-array  '{"pluginConfigs":[]}'                          "@absent" "@absent" '^none$'
t2_case agents g-pc-string '{"pluginConfigs":"claude-md-and-agents-md"}'   "@absent" "@absent" '^none$'
t2_case agents g-opt-str   "{\"pluginConfigs\":{${T2_AN}:{\"options\":\"claude-md-and-agents-md\"}}}" "@absent" "@absent" '^none$'
t2_case agents g-top-key   '{"instructionFiles":"claude-md-and-agents-md"}' "@absent" "@absent" '^none$'
t2_case agents g-other     '{"pluginConfigs":{"cc-plugin-easel@builtin":{"options":{"autoCharts":true}}}}' "@absent" "@absent" '^none$'
t2_case agents g-bom       "${T2_BOM}$(t2_ag "$T2_AN" '"claude-md-and-agents-md"')" "@absent" "@absent" '^and$'
t2_case agents g-multi     "$(t2_ag "$T2_AN" '"claude-md-and-agents-md"') {}" "@absent" "@absent" '^unparseable$' '^(and|none)$'
t2_case agents g-badutf8   $'{"t":"caf\xe9","pluginConfigs":{"cc-plugin-agents-md@builtin":{"options":{"instructionFiles":"claude-md"}}}}' "@absent" "@absent" '^claudemd$'
t2_case agents g-bigint    "{\"x\":1$(printf '%05000d' 0),\"pluginConfigs\":{${T2_AN}:{\"options\":{\"instructionFiles\":\"claude-md\"}}}}" "@absent" "@absent" '^claudemd$'

if [ -n "$T2_FAILED" ]; then
    echo "❌ T2：${T2_COUNT} 個案例裡有不符的：${T2_FAILED}"
    exit 1
fi
echo "✅ T2 jq 與 python3 兩條路徑在 ${T2_COUNT} 個假設定檔案例上結論相同，定案的結論也都對"
fi

# --- T3：plugin 登記端到端。新開的沙盒 HOME、裡面有假的 marketplace
# （各組都用自己的沙盒：不去動上面原有檢查沿用的那個 SANDBOX 的狀態）
if want T3; then
T3_HOME=$(mktemp -d "$WORK/t3.XXXXXX")
t2_mkhome "$T3_HOME"
printf '{"theme":"dark","enabledPlugins":{"other@m":false}}\n' > "$T3_HOME/.claude/settings.json"
HOME="$T3_HOME" ./install-dd-pipeline.sh < /dev/null > "$T3_HOME/out1.txt" 2>&1 \
    || { echo "❌ T3：第一次安裝失敗"; tail -20 "$T3_HOME/out1.txt"; exit 1; }
t3_s1=$(t2_canon "$T3_HOME/.claude/settings.json")
t3_i1=$(t2_canon "$T3_HOME/.claude/plugins/installed_plugins.json")
echo "$t3_s1" | grep -qF '"theme": "dark"' || { echo "❌ T3：settings.json 原有的 theme 不見了：${t3_s1}"; exit 1; }
echo "$t3_s1" | grep -qF '"other@m": false' || { echo "❌ T3：settings.json 原有的 other@m 不見了：${t3_s1}"; exit 1; }
for p in "${OFFICIAL_PLUGINS[@]}"; do
    echo "$t3_s1" | grep -qF "\"$p@$PLUGINS_MARKETPLACE\": true" \
        || { echo "❌ T3：settings.json 沒有啟用 ${p}：${t3_s1}"; exit 1; }
    echo "$t3_i1" | grep -qF "\"installPath\": \"$T3_HOME/.claude/plugins/cache/$PLUGINS_MARKETPLACE/$p/1.2.3\"" \
        || { echo "❌ T3：installed_plugins.json 沒有 ${p} 的登記：${t3_i1}"; exit 1; }
    plain "$T3_HOME/out1.txt" | grep -q "$p (v1.2.3): .*已啟用" \
        || { echo "❌ T3：安裝輸出沒有印 ${p} 已啟用"; exit 1; }
done
HOME="$T3_HOME" ./install-dd-pipeline.sh < /dev/null > "$T3_HOME/out2.txt" 2>&1 \
    || { echo "❌ T3：重跑安裝失敗"; tail -20 "$T3_HOME/out2.txt"; exit 1; }
[ "$(t2_canon "$T3_HOME/.claude/settings.json")" = "$t3_s1" ] || { echo "❌ T3：重跑後 settings.json 內容變了"; exit 1; }
[ "$(t2_canon "$T3_HOME/.claude/plugins/installed_plugins.json")" = "$t3_i1" ] \
    || { echo "❌ T3：重跑後 installed_plugins.json 除了時間戳以外的內容變了"; exit 1; }
HOME="$T3_HOME" ./install-dd-pipeline.sh --uninstall --yes < /dev/null > "$T3_HOME/out3.txt" 2>&1 \
    || { echo "❌ T3：uninstall --yes 失敗"; tail -20 "$T3_HOME/out3.txt"; exit 1; }
t3_s3=$(t2_canon "$T3_HOME/.claude/settings.json")
t3_i3=$(t2_canon "$T3_HOME/.claude/plugins/installed_plugins.json")
[ "$t3_s3" = '{"enabledPlugins": {"other@m": false}, "theme": "dark"}' ] \
    || { echo "❌ T3：uninstall 之後 settings.json 應該只剩原有的鍵，實際：${t3_s3}"; exit 1; }
[ "$t3_i3" = '{"plugins": {}, "version": 2}' ] \
    || { echo "❌ T3：uninstall 之後 installed_plugins.json 應該沒有登記，實際：${t3_i3}"; exit 1; }
echo "✅ T3 plugin 登記端到端：寫入並保留原有的鍵、重跑內容不變、uninstall --yes 拿掉登記"
fi

# --- T4：--check 對 ~/.claude.json 的幾種內容各印什麼（必要的 MCP 是 REQUIRED_MCP 的第一個）
if want T4; then
T4_HOME=$(mktemp -d "$WORK/t4.XXXXXX")
t4_check() {  # $1=~/.claude.json 的內容 $2=說明 $3=輸出要有的字（固定字串）
    printf '%s' "$1" > "$T4_HOME/.claude.json"
    HOME="$T4_HOME" ./install-dd-pipeline.sh --check < /dev/null > "$T4_HOME/out.txt" 2>&1 \
        || { echo "❌ T4：--check 失敗（${2}）"; tail -20 "$T4_HOME/out.txt"; exit 1; }
    plain "$T4_HOME/out.txt" | grep -F "${REQUIRED_MCP[0]}" | grep -qF "$3" \
        || { echo "❌ T4：${2} 時，${REQUIRED_MCP[0]} 那一行應該有「${3}」，實際：$(plain "$T4_HOME/out.txt" | grep -F "${REQUIRED_MCP[0]}" | head -1)"; exit 1; }
}
t4_check "{\"mcpServers\":{\"${REQUIRED_MCP[0]}\":{}}}" "設在根層 mcpServers" "${REQUIRED_MCP[0]}: ✅"
t4_check "{\"projects\":{\"/a\":{\"mcpServers\":{\"${REQUIRED_MCP[0]}\":{}}}}}" "只設在一個專案底下" "僅 1 個專案設定"
t4_check '{' "檔案壞掉" "無法判定"
t4_check 'null' "內容是 null" "無法判定"
t4_check '{}' "檔案正常但沒有設定" "需要手動設定"
echo "✅ T4 --check 對 ~/.claude.json：全域有、只在專案有、檔案壞掉、沒設定，各印各的"
fi

# --- T5：部署後被改過的檔，重裝時先備份再換回 repo 版（不帶 --force 也一樣）
if want T5; then
T5_HOME=$(mktemp -d "$WORK/t5.XXXXXX")
HOME="$T5_HOME" ./install-dd-pipeline.sh < /dev/null > "$T5_HOME/out1.txt" 2>&1 \
    || { echo "❌ T5：第一次安裝失敗"; tail -20 "$T5_HOME/out1.txt"; exit 1; }
# 每列：部署後的相對路徑｜repo 裡的來源｜備份目錄裡的相對路徑
T5_FILES="skills/code-simplifier/SKILL.md|skills/code-simplifier/SKILL.md|skills/code-simplifier/SKILL.md
agents/code-reviewer.md|agents/code-reviewer.md|agents/code-reviewer.md
commands/dd-init.md|commands/dd-init.md|commands/dd-init.md
commands/dd-stop.md|commands/dd-stop.md|commands/dd-stop.md
scripts/check-claude-md.sh|scripts/check-claude-md.sh|scripts/check-claude-md.sh
scripts/dd-stop.sh|scripts/dd-stop.sh|scripts/dd-stop.sh
output-styles/adhd.md|output-styles/adhd.md|output-styles/adhd.md"
echo "$T5_FILES" | while IFS='|' read -r dep src bak; do
    [ -f "$T5_HOME/.claude/$dep" ] || { echo "❌ T5：安裝後找不到 ${dep}"; exit 1; }
    echo "T5 我改過的" >> "$T5_HOME/.claude/$dep"
done
HOME="$T5_HOME" ./install-dd-pipeline.sh < /dev/null > "$T5_HOME/out2.txt" 2>&1 \
    || { echo "❌ T5：重裝失敗"; tail -20 "$T5_HOME/out2.txt"; exit 1; }
echo "$T5_FILES" | while IFS='|' read -r dep src bak; do
    cmp -s "$src" "$T5_HOME/.claude/$dep" || { echo "❌ T5：重裝後 ${dep} 沒有換回 repo 版"; exit 1; }
    t5_bak=$(find "$T5_HOME/.claude/backups" -path "*/$bak" 2>/dev/null | head -1)
    [ -n "$t5_bak" ] || { echo "❌ T5：${dep} 被換掉之前沒有備份"; exit 1; }
    grep -q 'T5 我改過的' "$t5_bak" || { echo "❌ T5：${dep} 的備份不是改過的那一版"; exit 1; }
done
echo "✅ T5 改過的 skill、agent、指令、腳本、輸出風格：重裝後換回 repo 版，改過的版本在備份裡"
fi

# --- T6：全域 CLAUDE.md 的三種情境（非互動）
if want T6; then
T6_HOME=$(mktemp -d "$WORK/t6.XXXXXX")
mkdir -p "$T6_HOME/.claude"
cp templates/global/CLAUDE.md "$T6_HOME/.claude/CLAUDE.md"
HOME="$T6_HOME" ./install-dd-pipeline.sh < /dev/null > "$T6_HOME/out1.txt" 2>&1 \
    || { echo "❌ T6：安裝失敗（內容相同）"; tail -20 "$T6_HOME/out1.txt"; exit 1; }
plain "$T6_HOME/out1.txt" | grep -q '與 repo 版本一致' || { echo "❌ T6：內容相同時沒有印「與 repo 版本一致」"; exit 1; }
[ ! -d "$T6_HOME/.claude/backups" ] || { echo "❌ T6：內容相同卻產生了備份"; exit 1; }
printf '我的版本\n' > "$T6_HOME/.claude/CLAUDE.md"
HOME="$T6_HOME" ./install-dd-pipeline.sh < /dev/null > "$T6_HOME/out2.txt" 2>&1 \
    || { echo "❌ T6：安裝失敗（內容不同、不帶 --force）"; tail -20 "$T6_HOME/out2.txt"; exit 1; }
[ "$(cat "$T6_HOME/.claude/CLAUDE.md")" = "我的版本" ] || { echo "❌ T6：不帶 --force、非互動時本機版被改掉了"; exit 1; }
plain "$T6_HOME/out2.txt" | grep -q '已保留本地版本' || { echo "❌ T6：不帶 --force 時沒有印「已保留本地版本」"; exit 1; }
[ -z "$(find "$T6_HOME/.claude/backups" -path '*/global/CLAUDE.md' 2>/dev/null)" ] \
    || { echo "❌ T6：沒有覆蓋卻產生了全域 CLAUDE.md 的備份"; exit 1; }
HOME="$T6_HOME" ./install-dd-pipeline.sh --force < /dev/null > "$T6_HOME/out3.txt" 2>&1 \
    || { echo "❌ T6：安裝失敗（--force）"; tail -20 "$T6_HOME/out3.txt"; exit 1; }
cmp -s templates/global/CLAUDE.md "$T6_HOME/.claude/CLAUDE.md" || { echo "❌ T6：--force 之後不是模板內容"; exit 1; }
t6_bak=$(find "$T6_HOME/.claude/backups" -path '*/global/CLAUDE.md' 2>/dev/null | head -1)
[ -n "$t6_bak" ] || { echo "❌ T6：--force 覆蓋前沒有備份"; exit 1; }
[ "$(cat "$t6_bak")" = "我的版本" ] || { echo "❌ T6：--force 的備份不是本機原本那一版"; exit 1; }
echo "✅ T6 全域 CLAUDE.md：相同不動、不同且不帶 --force 保留本機版、--force 備份後換成模板"
fi

# --- T7：skill 的 hooks.json 用相對路徑時，validate_skill_hooks 要以 exit 1 中止
# 函式裡是 exit 1，所以交給另一個 bash 行程跑；SCRIPT_DIR 指到假的 repo 目錄
if want T7; then
T7_DIR=$(mktemp -d "$WORK/t7.XXXXXX")
cat > "$T7_DIR/drive.sh" <<'DRIVE'
# $1=沙盒 HOME $2=假的 repo 根目錄
export HOME="$1"
# shellcheck source=/dev/null
source ./install-dd-pipeline.sh
SCRIPT_DIR="$2"
validate_skill_hooks
DRIVE
mkdir -p "$T7_DIR/home" "$T7_DIR/bad/skills/x/hooks" "$T7_DIR/good/skills/x/hooks"
printf '{"hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"./hooks/x.sh"}]}]}}\n' > "$T7_DIR/bad/skills/x/hooks/hooks.json"
# shellcheck disable=SC2016  # 要寫進檔案的就是字面的 $HOME
printf '{"hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"$HOME/.claude/skills/gate-guard/hooks/guard-no-verify.sh"}]}]}}\n' > "$T7_DIR/good/skills/x/hooks/hooks.json"
t7_rc=0
"$BASH" "$T7_DIR/drive.sh" "$T7_DIR/home" "$T7_DIR/bad" < /dev/null > "$T7_DIR/bad.out" 2>&1 || t7_rc=$?
[ "$t7_rc" -eq 1 ] || { echo "❌ T7：相對路徑的 hook 應該讓它 exit 1，實際 rc=${t7_rc}"; exit 1; }
plain "$T7_DIR/bad.out" | grep -q '相對路徑 hook' || { echo "❌ T7：沒有印出是哪個相對路徑 hook"; exit 1; }
t7_rc=0
"$BASH" "$T7_DIR/drive.sh" "$T7_DIR/home" "$T7_DIR/good" < /dev/null > "$T7_DIR/good.out" 2>&1 || t7_rc=$?
[ "$t7_rc" -eq 0 ] || { echo "❌ T7：合法路徑的 hook 不該被擋，實際 rc=${t7_rc}"; cat "$T7_DIR/good.out"; exit 1; }
[ -z "$(ls -A "$T7_DIR/home")" ] || { echo "❌ T7：驗證 hook 路徑時寫了東西進 HOME"; exit 1; }
echo "✅ T7 hooks.json 用相對路徑 → validate_skill_hooks 以 exit 1 中止；合法路徑放行"
fi

# --- T8：舊版留下的指令檔（deprecated_dd 列的那幾個）被清掉之前要先備份
if want T8; then
T8_HOME=$(mktemp -d "$WORK/t8.XXXXXX")
mkdir -p "$T8_HOME/.claude/commands"
printf '我改過的舊指令\n' > "$T8_HOME/.claude/commands/dd-help.md"
HOME="$T8_HOME" ./install-dd-pipeline.sh < /dev/null > "$T8_HOME/out.txt" 2>&1 \
    || { echo "❌ T8：安裝失敗"; tail -20 "$T8_HOME/out.txt"; exit 1; }
utf8_ok "$T8_HOME/out.txt" || { echo "❌ T8：安裝輸出有不合法的 UTF-8（訊息裡的變數緊貼全形字時要寫成 \${var}）"; exit 1; }
[ ! -e "$T8_HOME/.claude/commands/dd-help.md" ] || { echo "❌ T8：舊指令檔 dd-help.md 沒有被清掉"; exit 1; }
t8_bak=$(find "$T8_HOME/.claude/backups" -path '*/commands/dd-help.md' 2>/dev/null | head -1)
[ -n "$t8_bak" ] || { echo "❌ T8：dd-help.md 被清掉之前沒有備份"; exit 1; }
[ "$(cat "$t8_bak")" = "我改過的舊指令" ] || { echo "❌ T8：dd-help.md 的備份內容不對"; exit 1; }
plain "$T8_HOME/out.txt" | grep -q '覆蓋前的舊版已備份至' || { echo "❌ T8：完成訊息沒有印備份位置"; exit 1; }
echo "✅ T8 舊指令檔 dd-help.md 被清掉前有備份，完成訊息印出備份位置"
fi

# --- T9：完成訊息只報這次真的做了的
if want T9; then
T9_DIR=$(mktemp -d "$WORK/t9.XXXXXX")
# (a) --commands-only：agent 與 plugin 兩步都沒跑，不可以印這兩段
mkdir -p "$T9_DIR/a"
HOME="$T9_DIR/a" ./install-dd-pipeline.sh --commands-only < /dev/null > "$T9_DIR/a.txt" 2>&1 \
    || { echo "❌ T9：--commands-only 安裝失敗"; tail -20 "$T9_DIR/a.txt"; exit 1; }
if plain "$T9_DIR/a.txt" | grep -q '已啟用的 Plugin'; then echo "❌ T9：--commands-only 沒跑 plugin 步驟，卻印了「已啟用的 Plugin」"; exit 1; fi
if plain "$T9_DIR/a.txt" | grep -q '已安裝的內建 Agents'; then echo "❌ T9：--commands-only 沒裝 agent，卻印了「已安裝的內建 Agents」"; exit 1; fi
# (b) 完整安裝、沒有任何 plugin 啟用成功（沙盒裡沒有 marketplace）
mkdir -p "$T9_DIR/b"
HOME="$T9_DIR/b" ./install-dd-pipeline.sh < /dev/null > "$T9_DIR/b.txt" 2>&1 \
    || { echo "❌ T9：安裝失敗（沒有 marketplace）"; tail -20 "$T9_DIR/b.txt"; exit 1; }
if plain "$T9_DIR/b.txt" | grep -q '已啟用的 Plugin'; then echo "❌ T9：沒有任何 plugin 啟用成功，卻印了「已啟用的 Plugin」"; exit 1; fi
plain "$T9_DIR/b.txt" | grep -q '這次沒有啟用任何官方 Plugin' || { echo "❌ T9：沒有任何 plugin 啟用成功時，沒有照實印出來"; exit 1; }
plain "$T9_DIR/b.txt" | grep -q '已安裝的內建 Agents' || { echo "❌ T9：完整安裝卻沒有印「已安裝的內建 Agents」"; exit 1; }
# (c) 只有第一個官方 plugin 在 marketplace：只列它、數量是 1
mkdir -p "$T9_DIR/c"
t2_mkhome "$T9_DIR/c"
rm -rf "$T9_DIR/c/.claude/plugins/marketplaces/$PLUGINS_MARKETPLACE/plugins/${OFFICIAL_PLUGINS[1]}"
HOME="$T9_DIR/c" ./install-dd-pipeline.sh < /dev/null > "$T9_DIR/c.txt" 2>&1 \
    || { echo "❌ T9：安裝失敗（只有一個 plugin）"; tail -20 "$T9_DIR/c.txt"; exit 1; }
plain "$T9_DIR/c.txt" | grep -q '已啟用的 Plugin（1 個）' || { echo "❌ T9：只啟用了 1 個 plugin，完成訊息的數量不是 1"; exit 1; }
t9_list=$(plain "$T9_DIR/c.txt" | sed -n '/已啟用的 Plugin（/,/^$/p')
echo "$t9_list" | grep -q "^   ${OFFICIAL_PLUGINS[0]}" || { echo "❌ T9：完成訊息沒有列出啟用成功的 ${OFFICIAL_PLUGINS[0]}"; exit 1; }
if echo "$t9_list" | grep -q "^   ${OFFICIAL_PLUGINS[1]}"; then echo "❌ T9：${OFFICIAL_PLUGINS[1]} 沒有啟用，卻列在「已啟用的 Plugin」底下"; exit 1; fi
# (d) marketplace 在、installed_plugins.json 壞掉：登記失敗的 plugin 不可以已經在 settings.json 被寫成啟用，完成訊息也要照實說
mkdir -p "$T9_DIR/d"
t2_mkhome "$T9_DIR/d"
printf '[]' > "$T9_DIR/d/.claude/plugins/installed_plugins.json"
HOME="$T9_DIR/d" ./install-dd-pipeline.sh < /dev/null > "$T9_DIR/d.txt" 2>&1 \
    || { echo "❌ T9：安裝失敗（installed_plugins.json 壞掉）"; tail -20 "$T9_DIR/d.txt"; exit 1; }
plain "$T9_DIR/d.txt" | grep -q '這次沒有啟用任何官方 Plugin' || { echo "❌ T9：登記全部失敗，完成訊息卻沒有說沒啟用"; exit 1; }
t9_s=$(t2_canon "$T9_DIR/d/.claude/settings.json")
if echo "$t9_s" | grep -q ': true'; then echo "❌ T9：登記失敗，settings.json 卻已經寫成啟用（完成訊息說沒啟用）：${t9_s}"; exit 1; fi
# (e) 沒有 jq 也沒有 python3 時 uninstall 清不了 plugin 的登記：提示要把兩個檔都講到（只講 settings.json 的話，照做會漏掉 installed_plugins.json）
cat > "$T9_DIR/nojson.sh" <<'DRIVE'
# $1=沙盒 HOME；在 repo 根目錄執行。把 jq 與 python3 都當成不存在
export HOME="$1"
# shellcheck source=/dev/null
source ./install-dd-pipeline.sh
command_exists() { [ "$1" != jq ] && [ "$1" != python3 ] && command -v "$1" >/dev/null 2>&1; }
ASSUME_YES=true
uninstall
DRIVE
mkdir -p "$T9_DIR/e/.claude"
"$BASH" "$T9_DIR/nojson.sh" "$T9_DIR/e" < /dev/null > "$T9_DIR/e.txt" 2>&1 \
    || { echo "❌ T9：沒有 jq 與 python3 時 uninstall 失敗"; tail -20 "$T9_DIR/e.txt"; exit 1; }
plain "$T9_DIR/e.txt" | grep -q '缺少 jq 與 python3' || { echo "❌ T9：沒有 jq 與 python3 時 uninstall 沒有印出手動清理的提示"; exit 1; }
plain "$T9_DIR/e.txt" | grep '缺少 jq 與 python3' | grep -q 'installed_plugins.json' \
    || { echo "❌ T9：uninstall 的手動清理提示沒有講 installed_plugins.json"; exit 1; }
for t9_f in a b c d e; do
    utf8_ok "$T9_DIR/$t9_f.txt" || { echo "❌ T9：安裝輸出有不合法的 UTF-8（${t9_f}）"; exit 1; }
done
echo "✅ T9 完成訊息：--commands-only 不印 plugin 與 agent 兩段；沒啟用就照實說；只列啟用成功的"
fi

# --- T10：環境檢查（步驟 1，--check 也會跑）的「自動壓縮視窗」那一行
if want T10; then
T10_DIR=$(mktemp -d "$WORK/t10.XXXXXX")
T10_N=0
# $1=settings.json 的內容（@absent=不建檔） $2=環境變數 CLAUDE_CODE_AUTO_COMPACT_WINDOW 的值（空=不設）
# $3=說明 $4=那一行要有的字（固定字串，挑該狀態獨有的一段）
t10_check() {
    local h line ff
    T10_N=$((T10_N + 1))
    h="$T10_DIR/h${T10_N}"
    mkdir -p "$h/.claude"
    if [ "$1" != "@absent" ]; then printf '%s' "$1" > "$h/.claude/settings.json"; fi
    # 不設時要明確 unset：開發者的 shell 設著這個變數的話，每一格都會變成「環境變數」那一行
    ( if [ -n "$2" ]; then export CLAUDE_CODE_AUTO_COMPACT_WINDOW="$2"; else unset CLAUDE_CODE_AUTO_COMPACT_WINDOW; fi
      HOME="$h" ./install-dd-pipeline.sh --check < /dev/null > "$h/out.txt" 2>&1 ) \
        || { echo "❌ T10：--check 失敗（${3}）"; tail -20 "$h/out.txt"; exit 1; }
    line=$(plain "$h/out.txt" | grep -F '自動壓縮視窗' | head -1)
    case "$line" in
        "└── "*"$4"*) ;;
        *) echo "❌ T10：${3} 時，自動壓縮視窗那一行應該以「└── 」開頭、而且有「${4}」，實際：${line:-（沒有這一行）}"; exit 1 ;;
    esac
    ff=$(plain "$h/out.txt" | grep -F 'ffmpeg' | head -1)
    case "$ff" in
        "├── "*) ;;
        *) echo "❌ T10：${3} 時，ffmpeg 那一行應該以「├── 」開頭（它不再是最後一行），實際：${ff:-（沒有這一行）}"; exit 1 ;;
    esac
    local shell_err
    shell_err=$(grep -E 'integer expression expected|value too great for base|bad substitution|syntax error|command not found|unbound variable' "$h/out.txt" | head -1)
    [ -z "$shell_err" ] || { echo "❌ T10：${3} 時，輸出裡有 shell 錯誤：${shell_err}"; exit 1; }
    utf8_ok "$h/out.txt" || { echo "❌ T10：${3} 時，輸出有不合法的 UTF-8"; exit 1; }
}
t10_check '{"autoCompactWindow":400000}' "" "最上層有設" "最上層已設"
t10_check '{"autoCompactWindow":5}' "" "最上層的值在範圍外" "不是 100000–1000000 之間的整數"
t10_check '{"modelSettings":{"m":{"autoCompactWindow":400000}}}' "" "只設在個別模型" "只設在個別模型"
t10_check '{"theme":"dark"}' "" "都沒設" "都沒有有效的設定（其他設定檔沒查）"
t10_check "@absent" "" "沒有 settings.json" "都沒有有效的設定（其他設定檔沒查）"
t10_check '{' "" "檔案壞掉" "settings.json 無法解析"
t10_check '{"theme":"dark"}' "400000" "環境變數是 400000" "設了環境變數"
t10_check '{"autoCompactWindow":400000}' "5" "環境變數是 5" "不是 100000–1000000 的純數字"
t10_check '{"autoCompactWindow":400000}' "0400000" "環境變數是 0400000" "不是 100000–1000000 的純數字"
t10_check '{"autoCompactWindow":400000}' "99999999999999999999999" "環境變數是一長串數字" "不是 100000–1000000 的純數字"
# 沒有 jq 也沒有 python3：只有字串證據。有字樣回 unknown（不講成「已設」），沒字樣回 none
cat > "$T10_DIR/nojson.sh" <<'DRIVE'
# $1=沙盒 HOME $2=state（只問狀態）或 line（跑整個環境檢查）；在 repo 根目錄執行。把 jq 與 python3 都當成不存在
export HOME="$1"
unset CLAUDE_CODE_AUTO_COMPACT_WINDOW
# shellcheck source=/dev/null
source ./install-dd-pipeline.sh
command_exists() { [ "$1" != jq ] && [ "$1" != python3 ] && command -v "$1" >/dev/null 2>&1; }
if [ "$2" = line ]; then check_environment; else autocompact_state "$HOME/.claude/settings.json"; fi
DRIVE
mkdir -p "$T10_DIR/n1/.claude" "$T10_DIR/n2/.claude" "$T10_DIR/n3/.claude"
printf '{"autoCompactWindow":400000}' > "$T10_DIR/n1/.claude/settings.json"
printf '{"theme":"dark"}' > "$T10_DIR/n2/.claude/settings.json"
# $1=沙盒 HOME 的目錄名 $2=應該回的狀態 $3=說明
t10_nojson_state() {
    local s
    s=$("$BASH" "$T10_DIR/nojson.sh" "$T10_DIR/$1" state < /dev/null 2> "$T10_DIR/$1.err") \
        || { echo "❌ T10：沒有 jq 與 python3 時 autocompact_state 失敗（${3}）"; cat "$T10_DIR/$1.err"; exit 1; }
    [ "$s" = "$2" ] || { echo "❌ T10：沒有 jq 與 python3、${3} 時應該回 ${2}，實際：${s}"; exit 1; }
}
t10_nojson_state n1 unknown "檔案裡有這個鍵的字樣"
t10_nojson_state n2 none "檔案裡沒有這個鍵的字樣"
t10_nojson_state n3 none "沒有 settings.json"
"$BASH" "$T10_DIR/nojson.sh" "$T10_DIR/n1" line < /dev/null > "$T10_DIR/n1.txt" 2>&1 \
    || { echo "❌ T10：沒有 jq 與 python3 時環境檢查失敗"; tail -20 "$T10_DIR/n1.txt"; exit 1; }
plain "$T10_DIR/n1.txt" | grep -F '自動壓縮視窗' | grep -qF '缺 jq 與 python3' \
    || { echo "❌ T10：沒有 jq 與 python3 時，那一行應該講缺 jq 與 python3，實際：$(plain "$T10_DIR/n1.txt" | grep -F '自動壓縮視窗' | head -1)"; exit 1; }
echo "✅ T10 環境檢查的自動壓縮視窗那一行：${T10_N} 種設定與環境變數各印各的、不影響結束碼；沒有 jq 與 python3 時不講成已設"
fi

# --- T12：環境檢查（步驟 1，--check 也會跑）的「AGENTS.md 載入」那一行（2026-11-26）
# 每個狀態印各自的字、以「├── 」開頭（自動壓縮視窗仍是最後一行「└── 」）、不影響結束碼；預設值（沒設、or）不印 ⚠
if want T12; then
T12_DIR=$(mktemp -d "$WORK/t12.XXXXXX")
T12_N=0
# $1=settings.json 的內容（@absent=不建檔） $2=說明 $3=那一行要有的字（固定字串，挑該狀態獨有的一段） $4=yes 時那一行要有 ⚠、no 時不可以有
t12_check() {
    local h line ac
    T12_N=$((T12_N + 1))
    h="$T12_DIR/h${T12_N}"
    mkdir -p "$h/.claude"
    if [ "$1" != "@absent" ]; then printf '%s' "$1" > "$h/.claude/settings.json"; fi
    ( unset CLAUDE_CODE_AUTO_COMPACT_WINDOW; HOME="$h" ./install-dd-pipeline.sh --check < /dev/null > "$h/out.txt" 2>&1 ) \
        || { echo "❌ T12：--check 失敗（${2}）"; tail -20 "$h/out.txt"; exit 1; }
    line=$(plain "$h/out.txt" | grep -F 'AGENTS.md 載入' | head -1)
    case "$line" in
        "├── "*"$3"*) ;;
        *) echo "❌ T12：${2} 時，AGENTS.md 載入那一行應該以「├── 」開頭、而且有「${3}」，實際：${line:-（沒有這一行）}"; exit 1 ;;
    esac
    case "$4:$line" in
        yes:*"⚠"*|no:*) ;;
        *) echo "❌ T12：${2} 時，那一行應該有 ⚠，實際：${line}"; exit 1 ;;
    esac
    if [ "$4" = no ] && case "$line" in *"⚠"*) true ;; *) false ;; esac; then
        echo "❌ T12：${2} 時，那一行不該有 ⚠（不是錯），實際：${line}"; exit 1
    fi
    ac=$(plain "$h/out.txt" | grep -F '自動壓縮視窗' | head -1)
    case "$ac" in
        "└── "*) ;;
        *) echo "❌ T12：${2} 時，自動壓縮視窗那一行應該仍以「└── 」開頭，實際：${ac:-（沒有這一行）}"; exit 1 ;;
    esac
    utf8_ok "$h/out.txt" || { echo "❌ T12：${2} 時，輸出有不合法的 UTF-8"; exit 1; }
}
T12_AG() { printf '{"pluginConfigs":{"%s":{"options":{"instructionFiles":"%s"}}}}' "$1" "$2"; }
t12_check "$(T12_AG cc-plugin-agents-md@builtin claude-md-and-agents-md)" "設成兩種都讀" "（CLAUDE.md 與 AGENTS.md 都讀）" no
t12_check "$(T12_AG agents-md@builtin claude-md-and-agents-md)" "舊 ID 設成兩種都讀" "（CLAUDE.md 與 AGENTS.md 都讀）" no
t12_check "$(T12_AG cc-plugin-agents-md@builtin claude-md-or-agents-md)" "明寫預設值" "設為預設值 claude-md-or-agents-md" no
t12_check '{"theme":"dark"}' "沒設" "沒設（其他設定檔沒查）" no
t12_check "@absent" "沒有 settings.json" "沒設（其他設定檔沒查）" no
t12_check "$(T12_AG cc-plugin-agents-md@builtin claude-md)" "只讀 CLAUDE.md" "設為 claude-md，不讀 AGENTS.md" no
t12_check "$(T12_AG cc-plugin-agents-md@builtin managed-only)" "managed-only" "設為 managed-only" no
t12_check "$(T12_AG cc-plugin-agents-md@builtin both)" "不認得的值" "不是官方文件列的四種值之一" yes
t12_check '{"pluginConfigs":{"cc-plugin-agents-md@builtin":{"options":{"instructionFiles":"claude-md"}},"agents-md@builtin":{"options":{"instructionFiles":"claude-md-and-agents-md"}}}}' "兩個 ID 不同" "值不同，以哪個為準無從判定" yes
t12_check '{' "檔案壞掉" "settings.json 無法解析" yes
# 預設那兩行的提示要講到不讀 AGENTS.md 的條件與改法
plain "$T12_DIR/h4/out.txt" | grep -qF '工作目錄以上有 CLAUDE.md、.claude/CLAUDE.md 或 CLAUDE.local.md 就不讀 AGENTS.md' \
    || { echo "❌ T12：沒設時，提示沒有講到不讀 AGENTS.md 的條件"; exit 1; }
# 沒有 jq 也沒有 python3：有字樣回 unknown（不講成已設），沒字樣回 none
cat > "$T12_DIR/nojson.sh" <<'DRIVE'
# $1=沙盒 HOME；在 repo 根目錄執行。把 jq 與 python3 都當成不存在
export HOME="$1"
# shellcheck source=/dev/null
source ./install-dd-pipeline.sh
command_exists() { [ "$1" != jq ] && [ "$1" != python3 ] && command -v "$1" >/dev/null 2>&1; }
agents_md_state "$HOME/.claude/settings.json"
DRIVE
mkdir -p "$T12_DIR/n1/.claude" "$T12_DIR/n2/.claude"
T12_AG cc-plugin-agents-md@builtin claude-md-and-agents-md > "$T12_DIR/n1/.claude/settings.json"
printf '{"theme":"dark"}' > "$T12_DIR/n2/.claude/settings.json"
# $1=沙盒 HOME 的目錄名 $2=應該回的狀態
t12_nojson() {
    local s
    s=$("$BASH" "$T12_DIR/nojson.sh" "$T12_DIR/$1" < /dev/null 2> "$T12_DIR/$1.err") \
        || { echo "❌ T12：沒有 jq 與 python3 時 agents_md_state 失敗（${1}）"; cat "$T12_DIR/$1.err"; exit 1; }
    [ "$s" = "$2" ] || { echo "❌ T12：沒有 jq 與 python3 時 ${1} 應該回 ${2}，實際：${s}"; exit 1; }
}
t12_nojson n1 unknown
t12_nojson n2 none
echo "✅ T12 環境檢查的 AGENTS.md 載入那一行：${T12_N} 種設定各印各的、不影響結束碼；沒有 jq 與 python3 時不講成已設"
fi

# --- T11：--check 的「檢查內建 Skills」「檢查內建 Agents」看得出部署版與 repo 這份不同（2026-11-15）
# 原本只看目錄／檔案在不在：部署版是舊的照印「已安裝」。比法跟安裝本身一樣（skill 用 diff -rq、agent 用 cmp -s）。
if want T11; then
T11_HOME=$(mktemp -d "$WORK/t11.XXXXXX")
T11_OUT="$WORK/t11.out"     # 輸出放在沙盒 HOME 外面：下面要比 --check 前後 HOME 裡的檔有沒有變
mkdir -p "$T11_OUT"
HOME="$T11_HOME" ./install-dd-pipeline.sh < /dev/null > "$T11_OUT/install.txt" 2>&1 \
    || { echo "❌ T11：安裝失敗"; tail -20 "$T11_OUT/install.txt"; exit 1; }
# 快照：一般檔記 cksum，目錄與 symlink 記型別與路徑（只記一般檔的話，--check 多建一個空目錄或 symlink 會看不出來）
t11_snap() { (cd "$T11_HOME" && find . \( -type f -o -type d -o -type l \) | LC_ALL=C sort | while IFS= read -r f; do
    if [ -L "$f" ]; then echo "l $f"; elif [ -d "$f" ]; then echo "d $f"; else cksum "$f"; fi; done); }
# 跑一次 --check（輸出寫到 $1），前後各拍一次快照：結束碼要是 0、沙盒 HOME 不可以有任何變化
t11_check() {  # 輸出檔 情境
    t11_snap > "$T11_OUT/before.txt"
    HOME="$T11_HOME" ./install-dd-pipeline.sh --check < /dev/null > "$1" 2>&1 \
        || { echo "❌ T11：${2}時 --check 的結束碼不是 0（它只提示，不該影響結束碼）"; tail -20 "$1"; exit 1; }
    t11_snap > "$T11_OUT/after.txt"
    cmp -s "$T11_OUT/before.txt" "$T11_OUT/after.txt" \
        || { echo "❌ T11：${2}時 --check 前後沙盒 HOME 不一樣（它不該寫任何東西）"; diff "$T11_OUT/before.txt" "$T11_OUT/after.txt" | head -5; exit 1; }
}
# 某一段結尾的計數行（「├── 與 repo 不同：2（…」）；後面比到全形括號，「：1」才不會連「：14」一起算
t11_foot() {  # 檔 段落 標籤 數字
    plain "$1" | awk -v sec="$2" -v want="── $3：$4（" '
        index($0, "檢查內建 ") { on = (index($0, sec) > 0) }
        on && index($0, want) { n++ }
        END { exit (n == 1 ? 0 : 1) }' \
        || { echo "❌ T11：${2} 那一段結尾應該有一行「${3}：${4}」，實際：$(plain "$1" | grep -F "── ${3}：" | tr '\n' ' ')"; exit 1; }
}
# 某個名字在 skill 或 agent 那一段的那一行（兩段都有 code-simplifier，所以用段落標題夾出來）
t11_line() { plain "$1" | awk -v sec="$2" -v name="$3" '
    index($0, "檢查內建 ") { on = (index($0, sec) > 0) }
    on && index($0, " " name ": ") { print; exit }'; }
t11_expect() {  # 檔 段落 名字 要有的字 不可以有的字（可空）
    line=$(t11_line "$1" "$2" "$3")
    case "$line" in
        *"$4"*) ;;
        *) echo "❌ T11：${2} 的 ${3} 那一行應該有「${4}」，實際：${line:-（沒有這一行）}"; exit 1 ;;
    esac
    if [ -n "$5" ]; then
        case "$line" in
            *"$5"*) echo "❌ T11：${2} 的 ${3} 那一行不該有「${5}」，實際：${line}"; exit 1 ;;
        esac
    fi
}
# 對照：剛裝好、什麼都沒改，--check 不可以報任何一個不同
t11_check "$T11_OUT/clean.txt" "剛裝好"
if plain "$T11_OUT/clean.txt" | grep -qF '與 repo 不同'; then
    echo "❌ T11：剛裝好、什麼都沒改，--check 卻報了不同：$(plain "$T11_OUT/clean.txt" | grep -F '與 repo 不同' | head -3)"; exit 1
fi
t11_expect "$T11_OUT/clean.txt" "Skills" "dd-loop" "已安裝" ""
t11_expect "$T11_OUT/clean.txt" "Agents" "code-simplifier" "已安裝" ""
# 把兩個 skill 與一個 agent 改成「跟 repo 不一樣」（模擬部署版是舊的）；兩段都有 code-simplifier，只改 agent 那一份。
# gate-guard 改的是子目錄裡的檔：比法少了遞迴（diff -q）時只有它看得出來
printf '\n部署版多出來的一行\n' >> "$T11_HOME/.claude/skills/dd-loop/SKILL.md"
printf '\n' >> "$T11_HOME/.claude/skills/gate-guard/hooks/hooks.json"
printf '\n部署版多出來的一行\n' >> "$T11_HOME/.claude/agents/code-simplifier.md"
t11_check "$T11_OUT/stale.txt" "部署版與 repo 不同"
t11_expect "$T11_OUT/stale.txt" "Skills" "dd-loop" "與 repo 不同" ""
t11_expect "$T11_OUT/stale.txt" "Skills" "gate-guard" "與 repo 不同" ""
t11_expect "$T11_OUT/stale.txt" "Agents" "code-simplifier" "與 repo 不同" ""
t11_expect "$T11_OUT/stale.txt" "Skills" "code-simplifier" "已安裝" "與 repo 不同"   # 同名的 skill 沒改
t11_expect "$T11_OUT/stale.txt" "Skills" "plan-review" "已安裝" "與 repo 不同"
t11_expect "$T11_OUT/stale.txt" "Agents" "code-reviewer" "已安裝" "與 repo 不同"
t11_foot "$T11_OUT/stale.txt" "Skills" "與 repo 不同" 2
t11_foot "$T11_OUT/stale.txt" "Agents" "與 repo 不同" 1
t11_err=$(plain "$T11_OUT/stale.txt" | grep -E ': line [0-9]+: |bad substitution|unbound variable' || true)
[ -z "$t11_err" ] || { echo "❌ T11：輸出裡有 shell 錯誤：${t11_err}"; exit 1; }
utf8_ok "$T11_OUT/stale.txt" || { echo "❌ T11：輸出有不合法的 UTF-8"; exit 1; }
# 部署的檔讀不到時（diff／cmp 回 2）不可以講成「與 repo 不同，重跑安裝會更新」：重跑安裝會在備份那一步中止。
# root 讀得到 chmod 000 的檔（容器裡常是 root），那時這一格驗不到，印出來、不當成通過
chmod 000 "$T11_HOME/.claude/skills/verification-gate/SKILL.md" "$T11_HOME/.claude/agents/senior-devops.md"
if cat "$T11_HOME/.claude/skills/verification-gate/SKILL.md" > /dev/null 2>&1; then
    T11_UNREADABLE="（讀不到檔案那一格沒跑：這個帳號讀得到 chmod 000 的檔）"
else
    HOME="$T11_HOME" ./install-dd-pipeline.sh --check < /dev/null > "$T11_OUT/unreadable.txt" 2>&1 \
        || { echo "❌ T11：部署的檔讀不到時 --check 的結束碼不是 0"; tail -20 "$T11_OUT/unreadable.txt"; exit 1; }
    t11_expect "$T11_OUT/unreadable.txt" "Skills" "verification-gate" "無法比對" "與 repo 不同"
    t11_expect "$T11_OUT/unreadable.txt" "Agents" "senior-devops" "無法比對" "與 repo 不同"
    t11_foot "$T11_OUT/unreadable.txt" "Skills" "無法比對" 1
    t11_foot "$T11_OUT/unreadable.txt" "Agents" "無法比對" 1
    t11_foot "$T11_OUT/unreadable.txt" "Skills" "與 repo 不同" 2
    T11_UNREADABLE="讀不到的檔印「無法比對」、不講成重跑會更新；"
fi
chmod 644 "$T11_HOME/.claude/skills/verification-gate/SKILL.md" "$T11_HOME/.claude/agents/senior-devops.md"
# 重跑安裝之後就該回到「沒有不同」
HOME="$T11_HOME" ./install-dd-pipeline.sh < /dev/null > "$T11_OUT/reinstall.txt" 2>&1 \
    || { echo "❌ T11：重跑安裝失敗"; tail -20 "$T11_OUT/reinstall.txt"; exit 1; }
t11_check "$T11_OUT/fixed.txt" "重跑安裝之後"
if plain "$T11_OUT/fixed.txt" | grep -qF '與 repo 不同'; then
    echo "❌ T11：重跑安裝之後 --check 還報不同：$(plain "$T11_OUT/fixed.txt" | grep -F '與 repo 不同' | head -3)"; exit 1
fi
echo "✅ T11 --check 看得出部署版與 repo 不同：改過的 skill（含只改子目錄的）、agent 各自標出、沒改的照印已安裝、不寫檔、結束碼 0；${T11_UNREADABLE}重跑安裝後不再報"
fi
