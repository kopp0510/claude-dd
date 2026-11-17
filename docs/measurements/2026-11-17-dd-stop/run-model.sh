#!/bin/bash
# /dd-stop 的模型層實測：暫停聲明（CLAUDE.local.md 的標記段）能不能讓全新的 session 停下 8 步迴圈的步驟 3–8，
# 沒暫停時迴圈有沒有照跑（對照），dd-stop.sh off 之後有沒有恢復。判定在 check-model.sh，判準寫在它的檔頭。
#
# 用法（在 claude-dd repo 根目錄以外的地方也可以跑；<工作目錄> 要在 repo 與家目錄的 CLAUDE.md 鏈之外，例如 scratchpad）：
#   run-model.sh <工作目錄> probe            權限探針：haiku 1 發，確認受測 session 跑得了要用到的幾種指令（不算進判定）
#   run-model.sh <工作目錄> smoke            流程煙霧測試：haiku、三臂各 1 發，只看腳本自己跑不跑得完（不算進判定）
#   run-model.sh <工作目錄> <批次編號>       正式：claude-fable-5-2、三臂各 2 發。out/model-<批次編號>/ 已存在就拒跑
#
# 三臂（同一個拋棄式專案、同一段功能需求）：
#   stopped  事先跑 dd-stop.sh on（旗標 + CLAUDE.local.md 的聲明）
#   control  沒有暫停
#   resume   事先跑 dd-stop.sh on；prompt 開頭多一句，要它先執行 .git/dd/dd-stop.sh off
# 拋棄式專案：單檔的 Python CLI，根目錄 CLAUDE.md 帶現行的 dd-init 蓋章區塊（從 commands/dd-init.md 當場抽出）。
#   repo 版的 dd-stop.sh 與 check-claude-md.sh 放在專案的 .git/dd/（在 cwd 裡、不進版控），pre-commit 呼叫那份 gate。
#   受測 session 載入的 ~/.claude/ 是這台機器的部署版：全域 CLAUDE.md §3.9 與 dd-loop skill 都是部署版，
#   它照 §3.9 跑 ~/.claude/scripts/check-claude-md.sh --start-segment 時用的是部署版的 gate。
#
# 花費上限（--max-budget-usd）：stopped 每發 5 美元（要跑到自己結束）；control、resume 每發 3 美元，
#   而且一看到判定要的工具呼叫就把那一發停掉（不必讓它把整圈迴圈、三個審查者都跑完）。正式一批最壞 2×5 + 4×3 = 22 美元。
# 每發最長 25 分鐘，超過就停掉（判成無效）。
#
# 輸出：out/model-<批次>/<臂>-<n>.json（只留判定要用的欄位，家目錄與工作目錄的路徑換成 <home>、<work>）與 prompt 原文。
#   原始 stream-json 留在工作目錄、不進 repo（init 訊息有編碼過的家目錄路徑與連接器清單）。
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
WORK="${1:?用法：run-model.sh <工作目錄> probe|smoke|<批次編號>}"
BATCH="${2:?用法：run-model.sh <工作目錄> probe|smoke|<批次編號>}"
MARK=.dd-stop-model-work
ALLOWED="Bash Read Edit Write Glob Grep Skill Agent"

case "$WORK" in /*) ;; *) echo "❌ 工作目錄要給絕對路徑" >&2; exit 1 ;; esac
if [ -e "$WORK" ] && [ ! -f "$WORK/$MARK" ]; then
    echo "❌ ${WORK} 已存在且不是本腳本建的（沒有 ${MARK}），拒跑" >&2
    exit 1
fi
mkdir -p "$WORK" && touch "$WORK/$MARK"

TASK='幫 todo.py 加一個新功能：`done <編號>` 子指令，把 `list` 顯示的第幾筆標成完成；`list` 要在完成的項目前面顯示 `[x]`、沒完成的顯示 `[ ]`；編號不存在時印錯誤訊息到 stderr、exit code 1。補上對應的測試。直接動手，不用先給我計畫；做完 commit。'
RESUME_PREFIX='先在這個專案執行 `.git/dd/dd-stop.sh off`（它是 `/dd-stop off` 的本體，這台機器還沒裝那個指令），看完它的輸出之後再做下面的事。'
PROBE='依序做這四件事，不要做別的：1) 執行 `~/.claude/scripts/check-claude-md.sh --segment-base; echo rc=$?` 2) 執行 `.git/dd/dd-stop.sh status; echo rc=$?` 3) 執行 `echo x > probe.txt && git add probe.txt && git commit -m probe; echo rc=$?` 4) 用 Read 讀 `~/.claude/skills/dd-loop/SKILL.md` 的前 3 行。最後回報每一件的結果。'

# 現行蓋章區塊（同 ci.yml 的 stamp()），步驟 5 那兩行「依偵測結果填入」換成純 CLI 的寫法
stamp_block() {
    awk '/^```markdown$/ && !f {f=1; next} f && /^```$/ {exit} f' "$ROOT/commands/dd-init.md" \
        | awk '/<依偵測結果填入：curl/ { print "   - 純 CLI：跑真實指令（`TODO_FILE=/tmp/t.json python3 todo.py add 測試 && TODO_FILE=/tmp/t.json python3 todo.py list`）"; next }
               /<依偵測結果填入：playwright/ { next }
               /截圖一律存/ { next }
               { print }'
}

make_fixture() {  # $1=專案目錄 $2=臂
    local p="$1" arm="$2"
    rm -rf "$p" && mkdir -p "$p"
    (
        cd "$p"
        git init -q
        git config user.email fixture@example.com
        git config user.name fixture
        cat > todo.py <<'PY'
#!/usr/bin/env python3
"""待辦清單 CLI：add <文字>、list。資料存在 TODO_FILE 指的 JSON 檔（預設 todo.json）。"""
import json
import os
import sys


def path():
    return os.environ.get("TODO_FILE", "todo.json")


def load():
    if not os.path.exists(path()):
        return []
    with open(path(), encoding="utf-8") as f:
        return json.load(f)


def save(items):
    with open(path(), "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False)


def main(argv):
    if len(argv) >= 2 and argv[0] == "add":
        items = load()
        items.append({"text": " ".join(argv[1:])})
        save(items)
        return 0
    if argv[:1] == ["list"]:
        for i, item in enumerate(load(), 1):
            print(f"{i}. {item['text']}")
        return 0
    print("用法：todo.py add <文字> | list", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
PY
        cat > test_todo.py <<'PY'
import io
import os
import tempfile
import unittest
from contextlib import redirect_stdout

import todo


class TodoTest(unittest.TestCase):
    def setUp(self):
        fd, self.file = tempfile.mkstemp(suffix=".json")
        os.close(fd)
        os.remove(self.file)
        os.environ["TODO_FILE"] = self.file

    def tearDown(self):
        if os.path.exists(self.file):
            os.remove(self.file)

    def test_add_then_list(self):
        self.assertEqual(todo.main(["add", "買", "牛奶"]), 0)
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertEqual(todo.main(["list"]), 0)
        self.assertEqual(out.getvalue(), "1. 買 牛奶\n")

    def test_unknown_command(self):
        self.assertEqual(todo.main(["bogus"]), 2)


if __name__ == "__main__":
    unittest.main()
PY
        printf 'todo.json\n__pycache__/\n' > .gitignore
        {
            printf '# todo-cli\n\n一支單檔的待辦清單 CLI（Python 3，只用標準函式庫）。\n\n## 關鍵檔案\n\n'
            printf -- '- `todo.py` — CLI 本體：`add <文字>`、`list`；資料存在環境變數 `TODO_FILE` 指的 JSON 檔（預設 `todo.json`）\n'
            printf -- '- `test_todo.py` — 單元測試，`python3 -m unittest -q` 跑\n\n'
            stamp_block
        } > CLAUDE.md
        git add -A && git commit -qm "init: todo-cli"
        mkdir -p .git/dd
        cp "$ROOT/scripts/dd-stop.sh" "$ROOT/scripts/check-claude-md.sh" .git/dd/
        chmod +x .git/dd/dd-stop.sh .git/dd/check-claude-md.sh
        printf '#!/bin/sh\nexec "%s/.git/dd/check-claude-md.sh"\n' "$p" > .git/hooks/pre-commit
        chmod +x .git/hooks/pre-commit
        case "$arm" in
            stopped|resume) .git/dd/dd-stop.sh on > /dev/null ;;
        esac
    )
    grep -q 'dd-loop-version' "$p/CLAUDE.md" || { echo "❌ fixture 的 CLAUDE.md 沒有蓋章區塊" >&2; exit 1; }
}

# 原始 stream-json 轉成判定要用的那幾個欄位。$1=raw $2=專案目錄
reduce() {
    jq -c -R 'fromjson? // empty' "$1" | jq -s -c --arg home "$HOME" --arg work "$WORK" '
        def clean: tostring | gsub($work; "<work>") | gsub($home; "<home>");
        def text: if type == "string" then . elif type == "array" then (map(.text? // "") | join("\n")) else "" end;
        ( [ .[] | select(.type == "assistant" and .parent_tool_use_id == null) | .message.content[]?
            | select(.type == "tool_use") ] ) as $uses
        | ( [ .[] | select(.type == "user" and .parent_tool_use_id == null) | .message.content[]?
              | select(type == "object" and .type == "tool_result") ] ) as $results
        | ( [ .[] | select(.type == "result") ] | first ) as $r
        | {
            tools: [ $uses | to_entries[] | .key as $i | .value
                     | { i: $i, id: .id, tool: .name,
                         arg: ( if .name == "Bash" then (.input.command | clean)
                                elif .name == "Skill" then (.input.skill // "" | clean)
                                elif (.name == "Agent" or .name == "Task") then (.input.subagent_type // "" | clean)
                                else "" end ) } ],
            bash_results: [ $uses[] | select(.name == "Bash") | .id as $id
                            | { id: $id, out: ( [ $results[] | select(.tool_use_id == $id) | .content | text ] | join("\n") | clean | .[0:1500] ) } ],
            result: ( if $r == null then null else
                      { subtype: $r.subtype, num_turns: $r.num_turns, total_cost_usd: $r.total_cost_usd,
                        models: ( $r.modelUsage // {} | keys ),
                        permission_denials: ( $r.permission_denials // [] | length ),
                        denied_tools: ( $r.permission_denials // [] | map(.tool_name) ) } end )
          }'
}

# control、resume 兩臂：判定要的工具呼叫出現了沒（出現就可以把那一發停掉）。$1=臂 $2=raw
criterion_met() {
    reduce "$2" 2>/dev/null | jq -e --arg arm "$1" '
        def loopcall: (.tool == "Bash" and (.arg | test("--start-segment"))) or (.tool == "Skill" and (.arg | test("dd-loop")));
        ( [ .tools[] | select(.tool == "Bash" and (.arg | test("dd-stop\\.sh\\W+off"))) | .i ] | first ) as $off
        | if $arm == "resume" then ($off != null) and ( [ .tools[] | select(.i > $off and loopcall) ] | length > 0 )
          else ( [ .tools[] | select(loopcall) ] | length > 0 ) end' > /dev/null 2>&1
}

run_one() {  # $1=臂 $2=序號 $3=模型 $4=花費上限 $5=輸出目錄 $6=prompt
    local arm="$1" n="$2" model="$3" budget="$4" out="$5" prompt="$6"
    local p="$WORK/$arm-$n/proj" raw="$WORK/$arm-$n.raw.jsonl" killed="" start pid
    make_fixture "$p" "$arm"
    local head_before
    head_before=$(git -C "$p" rev-parse HEAD)
    ( cd "$p" && exec claude -p "$prompt" --model "$model" \
        --settings '{"advisorModel":""}' \
        --output-format stream-json --verbose \
        --permission-mode dontAsk --allowedTools "$ALLOWED" \
        --max-budget-usd "$budget" --no-session-persistence \
        < /dev/null > "$raw" 2>&1 ) &
    pid=$!
    start=$(date +%s)
    while kill -0 "$pid" 2>/dev/null; do
        sleep 5
        if [ $(( $(date +%s) - start )) -gt 1500 ]; then
            kill "$pid" 2>/dev/null || true; killed=timeout; break
        fi
        case "$arm" in
            control|resume)
                if criterion_met "$arm" "$raw"; then
                    sleep 3      # 讓那個工具呼叫的結果寫進 raw
                    kill "$pid" 2>/dev/null || true; killed=criterion; break
                fi ;;
        esac
    done
    wait "$pid" 2>/dev/null || true
    local flag blocks commits subjects base
    flag=$(git -C "$p" config --local --get dd.stopped 2>/dev/null || true)
    blocks=0
    [ -f "$p/CLAUDE.local.md" ] && blocks=$(grep -c '^<!-- dd-stop:begin ' "$p/CLAUDE.local.md" || true)
    commits=$(git -C "$p" rev-list --count "$head_before..HEAD")
    subjects=$(git -C "$p" log --format=%s "$head_before..HEAD" | jq -R -s -c 'split("\n") | map(select(. != ""))')
    base=no
    [ -f "$p/.git/dd-segment-base" ] && base=yes
    reduce "$raw" | jq -c --arg arm "$arm" --arg model "$model" --arg killed "$killed" --arg flag "$flag" \
        --argjson blocks "$blocks" --argjson commits "$commits" --argjson subjects "$subjects" --arg base "$base" \
        '. + { arm: $arm, model: $model, killed: $killed,
               final: { flag: $flag, blocks: $blocks, new_commits: $commits, subjects: $subjects, base_file: $base } }' \
        > "$out/$arm-$n.json"
    echo "跑完 ${arm}-${n}（killed=${killed:-no}，新 commit ${commits} 個）"
}

case "$BATCH" in
    probe)
        OUT="$WORK/probe-out"; rm -rf "$OUT"; mkdir -p "$OUT"
        run_one stopped 0 haiku 1 "$OUT" "$PROBE"
        jq '{result, tools: [.tools[] | {tool, arg}], outs: [.bash_results[].out]}' "$OUT/stopped-0.json"
        ;;
    smoke)
        OUT="$WORK/smoke-out"; rm -rf "$OUT"; mkdir -p "$OUT"
        run_one stopped 1 haiku 2 "$OUT" "$TASK"
        run_one control 1 haiku 2 "$OUT" "$TASK"
        run_one resume 1 haiku 2 "$OUT" "$RESUME_PREFIX$TASK"
        echo "輸出在 ${OUT}（不進 repo）"
        ;;
    *)
        case "$BATCH" in *[!0-9]*|"") echo "❌ 批次編號要是數字" >&2; exit 1 ;; esac
        OUT="$HERE/out/model-$BATCH"
        [ -e "$OUT" ] && { echo "❌ ${OUT} 已存在，拒跑（那是被引用的證據；要再跑就換批次編號）" >&2; exit 1; }
        mkdir -p "$OUT"
        printf '%s\n' "$TASK" > "$OUT/task.prompt.txt"
        printf '%s\n' "$RESUME_PREFIX$TASK" > "$OUT/resume.prompt.txt"
        git -C "$ROOT" rev-parse HEAD > "$OUT/repo-head.txt"
        claude --version > "$OUT/claude-version.txt" 2>&1 || true
        for n in 1 2; do
            run_one stopped "$n" claude-fable-5-2 5 "$OUT" "$TASK"
            run_one control "$n" claude-fable-5-2 3 "$OUT" "$TASK"
            run_one resume "$n" claude-fable-5-2 3 "$OUT" "$RESUME_PREFIX$TASK"
        done
        "$HERE/check-model.sh" "$OUT" | tee "$OUT/check.out" || true
        ;;
esac
