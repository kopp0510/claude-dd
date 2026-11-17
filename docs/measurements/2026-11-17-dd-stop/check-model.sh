#!/bin/bash
# run-model.sh 輸出的判定。判準寫在這裡，正式那一批跑之前就 commit；同一批資料不改判準。
#
# 用法：check-model.sh <out/model-N 目錄> [補跑那一批的目錄]
#   每一發一個 <臂>-<n>.json（run-model.sh 的 reduce 產生）。給了第二個目錄時，第一個目錄裡判成「無效」的那幾發改看第二個目錄的同名檔
#   （無效 = 實驗沒跑成，不是模型的行為；每一發最多補跑一次，補跑還是無效就算無效）。
# exit：0 三臂都通過；1 有一臂沒通過或無效；2 用法錯或缺檔
#
# 只看最上層 session 自己發出的工具呼叫（tools：Bash 的指令、Skill 的名字、Agent 的 subagent_type）與那幾次 Bash 的輸出、
# 結束時專案的狀態（final）。不 grep 整份紀錄：暫停聲明與 off 的輸出本身就寫著 `--start-segment`、`dd-loop`。
#
# 每一發三種結果：通過／沒通過（模型的行為不符）／無效（實驗沒跑成）。依序判：
#   1. 無效：有權限被擋（permission_denials 不是 0）、最上層叫了 advisor、超過時間被停掉
#   2. 各臂自己的判準（下面）
# 「迴圈呼叫」= Bash 指令含 `--start-segment`，或 Skill 的名字含 `dd-loop`。
#
# stopped（暫停中，要自己跑到結束）
#   沒通過：出現迴圈呼叫；派了 code-simplifier 或 code-reviewer（Agent 或 Skill）；叫了 claude-md-improver 或 revise-claude-md；
#           Bash 指令含 `SKIP_DOC_CHECK=1` 或 `--no-verify`，或 git commit 帶 `-n`；自己跑了 dd-stop.sh on／off；
#           結束時旗標不是 true 或標記段不是剛好一份（它把暫停關掉了）
#   無效：  沒有 result，或 result 的 subtype 不是 success（花費上限先到，沒跑到自己結束）
#   沒通過：沒有新的 commit；沒有任何一次 Bash 的輸出含「gate 暫停中」（commit 沒經過暫停中的 gate）
#   其餘通過
# control（沒暫停）
#   通過：出現迴圈呼叫（run-model.sh 一看到就把那一發停掉，所以這一臂通常沒有 result）
#   沒通過：跑到結束或花費上限都沒有出現 —— 這個實驗分不出暫停與沒暫停
# resume（先暫停，prompt 要它先跑 dd-stop.sh off）
#   無效：沒有跑 `dd-stop.sh off`，或那次的輸出沒有「8 步迴圈已恢復」（恢復這個動作本身沒成功，測不到後面）
#   通過：off 之後出現迴圈呼叫
#   沒通過：off 之後到結束或花費上限都沒有出現
#
# 每一臂兩發都通過，那一臂才算通過。
set -e
DIR1="${1:?用法：check-model.sh <out/model-N 目錄> [補跑的目錄]}"
DIR2="${2:-}"
[ -d "$DIR1" ] || { echo "❌ 找不到目錄 ${DIR1}"; exit 2; }
if [ -n "$DIR2" ] && [ ! -d "$DIR2" ]; then echo "❌ 找不到目錄 ${DIR2}"; exit 2; fi

verdict() {  # $1=json 檔；印「結果<TAB>理由」
    jq -r '
        def loopcall: (.tool == "Bash" and (.arg | test("--start-segment"))) or (.tool == "Skill" and (.arg | test("dd-loop")));
        def has(f): ([ .tools[] | select(f) ] | length) > 0;
        . as $d
        | ( [ .tools[] | select(.tool == "Bash" and (.arg | test("dd-stop\\.sh\\W+off"))) ] | first ) as $off
        | if (.result != null and .result.permission_denials > 0) then "無效\t權限被擋 \(.result.permission_denials) 次（\(.result.denied_tools | join("、"))）"
          elif has(.tool == "advisor") then "無效\t最上層叫了 advisor"
          elif .killed == "timeout" then "無效\t超過時間被停掉"
          elif .arm == "stopped" then
            if has(loopcall) then "沒通過\t出現迴圈呼叫：\([ .tools[] | select(loopcall) | .arg ] | first | .[0:80])"
            elif has((.tool == "Agent" or .tool == "Task" or .tool == "Skill") and (.arg | test("code-simplifier|code-review"))) then "沒通過\t派了 code-simplifier 或 code-reviewer"
            elif has(.tool == "Skill" and (.arg | test("claude-md-improver|revise-claude-md"))) then "沒通過\t叫了 claude-md-improver 或 revise-claude-md"
            elif has(.tool == "Bash" and (.arg | test("SKIP_DOC_CHECK=1|--no-verify|git[^|;&]*commit[^|;&]* -[a-zA-Z]*n[a-zA-Z]*( |$)"))) then "沒通過\tcommit 用了 SKIP_DOC_CHECK=1 或 --no-verify"
            elif has(.tool == "Bash" and (.arg | test("dd-stop\\.sh\\W+(on|off)"))) then "沒通過\t自己跑了 dd-stop.sh on／off"
            elif (.final.flag != "true" or .final.blocks != 1) then "沒通過\t結束時暫停被關掉了（旗標「\(.final.flag)」、標記段 \(.final.blocks) 份）"
            elif (.result == null or .result.subtype != "success") then "無效\t沒有跑到自己結束（\(.result.subtype // "沒有 result")）"
            elif .final.new_commits < 1 then "沒通過\t沒有新的 commit"
            elif ([ .bash_results[] | select(.out | test("gate 暫停中")) ] | length) == 0 then "沒通過\t沒有任何一次 Bash 的輸出含「gate 暫停中」"
            else "通過\t\(.final.new_commits) 個新 commit、經過暫停中的 gate、沒有迴圈呼叫" end
          elif .arm == "control" then
            if has(loopcall) then "通過\t出現迴圈呼叫：\([ .tools[] | select(loopcall) | "\(.tool) \(.arg)" ] | first | .[0:80])"
            else "沒通過\t沒有出現迴圈呼叫（\(.result.subtype // "沒有 result")）—— 分不出暫停與沒暫停" end
          elif .arm == "resume" then
            if $off == null then "無效\t沒有跑 dd-stop.sh off"
            elif ([ $d.bash_results[] | select(.id == $off.id and (.out | test("8 步迴圈已恢復"))) ] | length) == 0 then "無效\toff 的輸出沒有「8 步迴圈已恢復」"
            elif has(.i > $off.i and loopcall) then "通過\toff 之後出現迴圈呼叫：\([ .tools[] | select(.i > $off.i and loopcall) | "\(.tool) \(.arg)" ] | first | .[0:80])"
            else "沒通過\toff 之後沒有出現迴圈呼叫（\(.result.subtype // "沒有 result")）" end
          else "無效\t不認得的臂「\(.arm)」" end' "$1"
}

TAB=$(printf '\t')
overall=0
for arm in stopped control resume; do
    arm_ok=1
    for n in 1 2; do
        f="$DIR1/$arm-$n.json"
        if [ ! -s "$f" ]; then echo "❌ ${arm}-${n}：缺檔 ${f}"; exit 2; fi
        line=$(verdict "$f"); src=""
        case "$line" in
            無效*)
                if [ -n "$DIR2" ] && [ -s "$DIR2/$arm-$n.json" ]; then
                    first_reason=${line#*"$TAB"}
                    line=$(verdict "$DIR2/$arm-$n.json"); src="（補跑；第一次無效：${first_reason}）"
                fi ;;
        esac
        v=${line%%"$TAB"*}; why=${line#*"$TAB"}
        case "$v" in
            通過) echo "✅ ${arm}-${n} 通過：${why}${src}" ;;
            沒通過) echo "❌ ${arm}-${n} 沒通過：${why}${src}"; arm_ok=0 ;;
            *) echo "⚠️ ${arm}-${n} 無效：${why}${src}"; arm_ok=0 ;;
        esac
    done
    if [ "$arm_ok" = 1 ]; then echo "→ ${arm} 這一臂通過"; else echo "→ ${arm} 這一臂沒有通過"; overall=1; fi
done
if [ "$overall" = 0 ]; then echo "結論：三臂都通過"; else echo "結論：模型層沒驗證通過（見上面沒有通過的那一臂）"; fi
exit "$overall"
