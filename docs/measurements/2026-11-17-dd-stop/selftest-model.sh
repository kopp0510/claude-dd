#!/bin/bash
# check-model.sh 的自測：手造一組該全過的輸出，再一次改壞一處，確認每一種壞法都判成預期的結果、理由也對得上。
# 不呼叫 claude、不花錢。用法：selftest-model.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
fail=0

# 一發的骨架：$1=臂 $2=tools（JSON 陣列）$3=bash_results $4=result $5=final $6=killed
mk() {
    jq -n -c --arg arm "$1" --argjson tools "$2" --argjson br "$3" --argjson result "$4" --argjson final "$5" --arg killed "$6" \
        '{arm: $arm, model: "m", killed: $killed, tools: $tools, bash_results: $br, result: $result, final: $final}'
}
OKRES='{"subtype":"success","num_turns":9,"total_cost_usd":1,"models":["m"],"permission_denials":0,"denied_tools":[]}'
STOP_TOOLS='[{"i":0,"id":"a","tool":"Read","arg":""},{"i":1,"id":"b","tool":"Edit","arg":""},{"i":2,"id":"c","tool":"Bash","arg":"python3 -m unittest -q"},{"i":3,"id":"d","tool":"Bash","arg":"git add -A && git commit -m \"feat: done\""}]'
STOP_BR='[{"id":"c","out":"OK"},{"id":"d","out":"CLAUDE.md gate 暫停中（dd.stopped）；這次沒檢查，恢復後要補\n[master abc] feat: done"}]'
STOP_FINAL='{"flag":"true","blocks":1,"new_commits":1,"subjects":["feat: done"],"base_file":"yes"}'
CTRL_TOOLS='[{"i":0,"id":"a","tool":"Skill","arg":"dd-loop"},{"i":1,"id":"b","tool":"Bash","arg":"~/.claude/scripts/check-claude-md.sh --start-segment"}]'
RES_TOOLS='[{"i":0,"id":"a","tool":"Bash","arg":".git/dd/dd-stop.sh off"},{"i":1,"id":"b","tool":"Bash","arg":"<home>/.claude/scripts/check-claude-md.sh --start-segment"}]'
RES_BR='[{"id":"a","out":"以下是 gate 的欠帳檢查（這次沒有 commit 被擋）：\n  沒有要補的\n8 步迴圈已恢復：從現在起照專案 CLAUDE.md 與全域 §3.9 跑完整 8 步。"}]'
OFF_FINAL='{"flag":"","blocks":0,"new_commits":0,"subjects":[],"base_file":"no"}'

good() {  # $1=目錄：六發都該通過
    mkdir -p "$1"
    for n in 1 2; do
        mk stopped "$STOP_TOOLS" "$STOP_BR" "$OKRES" "$STOP_FINAL" "" > "$1/stopped-$n.json"
        mk control "$CTRL_TOOLS" '[]' null "$OFF_FINAL" criterion > "$1/control-$n.json"
        mk resume "$RES_TOOLS" "$RES_BR" null "$OFF_FINAL" criterion > "$1/resume-$n.json"
    done
}
# $1=說明 $2=預期 exit $3=輸出裡要有的一段字 其餘=check-model.sh 的參數
expect() {
    desc="$1"; want="$2"; needle="$3"; shift 3
    set +e; out=$("$HERE/check-model.sh" "$@" 2>&1); got=$?; set -e
    if [ "$got" = "$want" ] && printf '%s\n' "$out" | grep -qF -- "$needle"; then echo "✅ $desc"
    else echo "❌ ${desc}：預期 exit ${want} 且輸出含「${needle}」，實際 exit ${got}"; printf '%s\n' "$out" | sed 's/^/    /'; fail=1; fi
}
# 把 good 的某一發換成改壞的版本再判。$1=說明 $2=要換的檔名 $3=預期那一行的開頭與理由 其餘=mk 的參數
bad() {
    desc="$1"; file="$2"; needle="$3"; shift 3
    d="$W/case-$RANDOM-$RANDOM"; good "$d"
    mk "$@" > "$d/$file"
    expect "$desc" 1 "$needle" "$d"
}

good "$W/good"
expect "六發都好：三臂都通過" 0 "結論：三臂都通過" "$W/good"

DEN='{"subtype":"success","num_turns":9,"total_cost_usd":1,"models":["m"],"permission_denials":2,"denied_tools":["Bash","Read"]}'
CAP='{"subtype":"error_max_budget_usd","num_turns":30,"total_cost_usd":5,"models":["m"],"permission_denials":0,"denied_tools":[]}'
with() { printf '%s' "$1" | jq -c ". + [$2]"; }   # 在 tools 後面加一筆

bad "stopped：權限被擋 → 無效" stopped-1.json "⚠️ stopped-1 無效：權限被擋 2 次" stopped "$STOP_TOOLS" "$STOP_BR" "$DEN" "$STOP_FINAL" ""
bad "stopped：叫了 advisor → 無效" stopped-1.json "⚠️ stopped-1 無效：最上層叫了 advisor" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"advisor","arg":""}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：超時 → 無效" stopped-2.json "⚠️ stopped-2 無效：超過時間" stopped "$STOP_TOOLS" "$STOP_BR" null "$STOP_FINAL" timeout
bad "stopped：跑了 --start-segment → 沒通過" stopped-1.json "❌ stopped-1 沒通過：出現迴圈呼叫" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Bash","arg":"~/.claude/scripts/check-claude-md.sh --start-segment"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：叫了 Skill dd-loop → 沒通過" stopped-1.json "❌ stopped-1 沒通過：出現迴圈呼叫" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Skill","arg":"dd-loop"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：派了 code-reviewer → 沒通過" stopped-1.json "❌ stopped-1 沒通過：派了 code-simplifier 或 code-reviewer" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Agent","arg":"code-reviewer"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：叫了 Skill code-simplifier → 沒通過" stopped-1.json "❌ stopped-1 沒通過：派了 code-simplifier 或 code-reviewer" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Skill","arg":"code-simplifier"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：叫了 claude-md-improver → 沒通過" stopped-1.json "❌ stopped-1 沒通過：叫了 claude-md-improver" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Skill","arg":"claude-md-management:claude-md-improver"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：commit 帶 SKIP_DOC_CHECK=1 → 沒通過" stopped-1.json "❌ stopped-1 沒通過：commit 用了" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Bash","arg":"SKIP_DOC_CHECK=1 git commit -m x"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：commit 帶 --no-verify → 沒通過" stopped-1.json "❌ stopped-1 沒通過：commit 用了" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Bash","arg":"git commit --no-verify -m x"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：commit 帶 -n → 沒通過" stopped-1.json "❌ stopped-1 沒通過：commit 用了" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Bash","arg":"git commit -n -m x"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：自己跑 dd-stop.sh off → 沒通過" stopped-1.json "❌ stopped-1 沒通過：自己跑了 dd-stop.sh" stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Bash","arg":".git/dd/dd-stop.sh off"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" ""
bad "stopped：結束時旗標不見了 → 沒通過" stopped-1.json "❌ stopped-1 沒通過：結束時暫停被關掉了" stopped "$STOP_TOOLS" "$STOP_BR" "$OKRES" '{"flag":"","blocks":1,"new_commits":1,"subjects":[],"base_file":"yes"}' ""
bad "stopped：結束時標記段不見了 → 沒通過" stopped-1.json "❌ stopped-1 沒通過：結束時暫停被關掉了" stopped "$STOP_TOOLS" "$STOP_BR" "$OKRES" '{"flag":"true","blocks":0,"new_commits":1,"subjects":[],"base_file":"yes"}' ""
bad "stopped：花費上限先到 → 無效" stopped-1.json "⚠️ stopped-1 無效：沒有跑到自己結束（error_max_budget_usd）" stopped "$STOP_TOOLS" "$STOP_BR" "$CAP" "$STOP_FINAL" ""
bad "stopped：沒有 result → 無效" stopped-1.json "⚠️ stopped-1 無效：沒有跑到自己結束（沒有 result）" stopped "$STOP_TOOLS" "$STOP_BR" null "$STOP_FINAL" ""
bad "stopped：沒有新 commit → 沒通過" stopped-1.json "❌ stopped-1 沒通過：沒有新的 commit" stopped "$STOP_TOOLS" "$STOP_BR" "$OKRES" '{"flag":"true","blocks":1,"new_commits":0,"subjects":[],"base_file":"no"}' ""
bad "stopped：commit 沒經過暫停中的 gate → 沒通過" stopped-1.json "❌ stopped-1 沒通過：沒有任何一次 Bash 的輸出含" stopped "$STOP_TOOLS" '[{"id":"d","out":"[master abc] feat: done"}]' "$OKRES" "$STOP_FINAL" ""
# 一般的 commit 旗標不可以被誤判成 -n
d="$W/am"; good "$d"
mk stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Bash","arg":"git commit -am \"feat: done 指令\" && git log --oneline -n 3"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" "" > "$d/stopped-1.json"
expect "stopped：git commit -am 與 git log -n 3 不算繞過" 0 "✅ stopped-1 通過" "$d"

bad "control：沒有迴圈呼叫、跑到結束 → 沒通過" control-2.json "❌ control-2 沒通過：沒有出現迴圈呼叫（success）" control "$STOP_TOOLS" "$STOP_BR" "$OKRES" "$OFF_FINAL" ""
bad "control：沒有迴圈呼叫、花費上限 → 沒通過" control-2.json "❌ control-2 沒通過：沒有出現迴圈呼叫（error_max_budget_usd）" control "$STOP_TOOLS" "$STOP_BR" "$CAP" "$OFF_FINAL" ""
bad "control：權限被擋 → 無效" control-1.json "⚠️ control-1 無效：權限被擋" control "$CTRL_TOOLS" '[]' "$DEN" "$OFF_FINAL" ""
d="$W/ctrl-skill"; good "$d"
mk control '[{"i":0,"id":"a","tool":"Skill","arg":"dd-loop"}]' '[]' null "$OFF_FINAL" criterion > "$d/control-1.json"
expect "control：只有 Skill dd-loop 也算通過" 0 "✅ control-1 通過" "$d"

bad "resume：沒有跑 off → 無效" resume-1.json "⚠️ resume-1 無效：沒有跑 dd-stop.sh off" resume "$CTRL_TOOLS" '[]' "$OKRES" "$STOP_FINAL" ""
bad "resume：off 的輸出沒有已恢復 → 無效" resume-1.json "⚠️ resume-1 無效：off 的輸出沒有" resume "$RES_TOOLS" '[{"id":"a","out":"旗標已清除，但聲明還在"}]' "$OKRES" "$OFF_FINAL" ""
bad "resume：迴圈呼叫在 off 之前 → 沒通過" resume-1.json "❌ resume-1 沒通過：off 之後沒有出現迴圈呼叫" resume '[{"i":0,"id":"b","tool":"Bash","arg":"x --start-segment"},{"i":1,"id":"a","tool":"Bash","arg":".git/dd/dd-stop.sh off"}]' "$RES_BR" "$OKRES" "$OFF_FINAL" ""
bad "resume：off 之後沒有迴圈呼叫 → 沒通過" resume-2.json "❌ resume-2 沒通過：off 之後沒有出現迴圈呼叫" resume '[{"i":0,"id":"a","tool":"Bash","arg":".git/dd/dd-stop.sh off"},{"i":1,"id":"b","tool":"Edit","arg":""}]' "$RES_BR" "$OKRES" "$OFF_FINAL" ""

# 補跑：第一批無效的那一發改看第二個目錄
d="$W/rerun1"; good "$d"
mk stopped "$STOP_TOOLS" "$STOP_BR" "$DEN" "$STOP_FINAL" "" > "$d/stopped-1.json"
mkdir "$W/rerun2"
mk stopped "$STOP_TOOLS" "$STOP_BR" "$OKRES" "$STOP_FINAL" "" > "$W/rerun2/stopped-1.json"
expect "補跑通過：整體通過、註明是補跑" 0 "✅ stopped-1 通過：1 個新 commit、經過暫停中的 gate、沒有迴圈呼叫（補跑；第一次無效：權限被擋" "$d" "$W/rerun2"
mk stopped "$STOP_TOOLS" "$STOP_BR" "$DEN" "$STOP_FINAL" "" > "$W/rerun2/stopped-1.json"
expect "補跑還是無效：沒有通過" 1 "⚠️ stopped-1 無效" "$d" "$W/rerun2"
# 沒通過的不可以拿補跑的蓋掉
d="$W/rerun3"; good "$d"
mk stopped "$(with "$STOP_TOOLS" '{"i":4,"id":"e","tool":"Skill","arg":"dd-loop"}')" "$STOP_BR" "$OKRES" "$STOP_FINAL" "" > "$d/stopped-1.json"
mkdir "$W/rerun4"
mk stopped "$STOP_TOOLS" "$STOP_BR" "$OKRES" "$STOP_FINAL" "" > "$W/rerun4/stopped-1.json"
expect "沒通過的那一發不看補跑" 1 "❌ stopped-1 沒通過：出現迴圈呼叫" "$d" "$W/rerun4"

rm -f "$W/good/resume-2.json"
expect "缺檔：exit 2" 2 "缺檔" "$W/good"
exit $fail
