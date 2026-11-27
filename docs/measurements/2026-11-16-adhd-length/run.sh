#!/bin/bash
# ADHD output style 加了長度上限之後的行為驗收：同一組 prompt，舊版（OLD）與新版（NEW）兩臂各跑 n=2，
# 每發只留判定要用的欄位。判定交給同目錄的 check.sh（判準寫死在那支，跑之前就 commit）。
#
# 用法：docs/measurements/2026-11-16-adhd-length/run.sh <拋棄式工作目錄> <批次編號>
#   工作目錄要在 repo 與家目錄的 CLAUDE.md 鏈之外（例如 session scratchpad 底下）。
#   它必須不存在，或是本腳本之前建的（裡面有 .dd-sandbox 標記）；否則拒跑，因為每發之前會整個刪掉重建。
#   受測 session 的 cwd 是它底下的 proj/，標記檔放在 proj/ 外面：第 1 批標記檔放在 cwd 裡、檔名又帶實驗主題，
#   受測 session 看得到（P3 四發的 outside 都是 1，原始紀錄已刪，推測是去讀了那個檔，沒有證實）。
#   輸出寫進 out/batch<批次編號>/；那個目錄已經存在就拒跑（上一批的數字不蓋掉）。
# 不需要先部署：每發只把自己那一臂的風格檔放進 proj/.claude/output-styles/（專案層），不動 ~/.claude/。
#   OLD = git 裡 BASE 那一版的 output-styles/adhd.md，NEW = repo 工作樹現在的 output-styles/adhd.md；
#   各自只把 frontmatter 的 name 改成 ADHDOLD、ADHDNEW（避免跟已部署的 ADHD 撞名），其餘逐字相同。
# 只跑一發：ONLY="<臂> <prompt 編號>" run.sh <工作目錄> <批次編號>（prompt 4、5 是保留題）。
# 順序：先跑兩發載入探針，任一臂答錯就停，不跑後面 12 發。
# 花費：每發上限 2 美元，共 2 + 12 發
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
WORK="${1:?用法：run.sh <拋棄式工作目錄> <批次編號>}"
BATCH="${2:?用法：run.sh <拋棄式工作目錄> <批次編號>}"
OUT="$HERE/out/batch$BATCH"
PROJ="$WORK/proj"
MARK=.dd-sandbox
BASE=dd6bffa

if [ -e "$WORK" ] && [ ! -f "$WORK/$MARK" ]; then
    echo "❌ ${WORK} 已存在且不是本腳本建的（沒有 ${MARK}），拒跑：每發之前會整個刪掉它" >&2
    exit 1
fi
if [ -e "$OUT" ]; then
    echo "❌ ${OUT} 已存在，拒跑：換一個批次編號，上一批的輸出不蓋掉" >&2
    exit 1
fi
mkdir -p "$OUT"

STYLES="$OUT/.styles"
mkdir -p "$STYLES"
git -C "$REPO" show "$BASE:output-styles/adhd.md" > "$STYLES/old.src"
cp "$REPO/output-styles/adhd.md" "$STYLES/new.src"
sed 's/^name: ADHD$/name: ADHDOLD/' "$STYLES/old.src" > "$STYLES/ADHDOLD.md"
sed 's/^name: ADHD$/name: ADHDNEW/' "$STYLES/new.src" > "$STYLES/ADHDNEW.md"
for a in old:ADHDOLD new:ADHDNEW; do
    changed=$(diff "$STYLES/${a%%:*}.src" "$STYLES/${a##*:}.md" | grep -c '^[<>]' || true)
    if [ "$changed" != 2 ]; then
        echo "❌ ${a##*:}.md 與來源不是只差 name 那一行（差 ${changed} 行）" >&2
        exit 1
    fi
done
{
    echo "OLD ${BASE}:output-styles/adhd.md blob $(git -C "$REPO" hash-object "$STYLES/old.src")"
    echo "NEW 工作樹 output-styles/adhd.md blob $(git -C "$REPO" hash-object "$STYLES/new.src")"
} > "$OUT/styles.txt"

prompt_0='你的 output style 指示裡，第一個 `##` 標題是什麼？只回標題那幾個字。'
prompt_1='讀 review.md，告訴我現在狀況怎樣、我該先處理什麼。不要改任何檔案，也不要執行 shell 指令。'
prompt_2='deploy.sh 跑了就失敗（訊息在 deploy.log），為什麼？不要改任何檔案，也不要執行 shell 指令。'
# 第 3 批起 P3 多一句「除了這一條，不要執行其他 shell 指令」：前兩批有 3 發被擋，第 2 批的 denied 欄顯示被擋的是
# for 迴圈串起來的只讀指令（單純的 ls、cat、git status 在 dontAsk 下沒列進 --allowedTools 也會放行，迴圈不會）
prompt_3='照 todo.md 把事情做完，再用 `bash test.sh` 驗證（指令照這樣打，不要加別的）。除了這一條，不要執行其他 shell 指令。做完照你的規則回報。'
# 保留題（調措辭用，不是判定用；內容與 P1 到 P3 不同）。只在 ONLY 模式跑，check.sh 不讀它們的輸出
# shellcheck disable=SC2034  # prompt_4、prompt_5 由 run_one 與 ONLY 模式用 eval 取用
prompt_4='讀 inbox.md，今天我該先回哪幾張？不要改任何檔案，也不要執行 shell 指令。'
# shellcheck disable=SC2034
prompt_5='build 為什麼失敗（訊息在 build.log）？不要改任何檔案，也不要執行 shell 指令。'

# 每發之前整個重建工作目錄與 fixture（fixture 當場寫出來，不從 repo 複製）
setup() { # $1 = prompt 編號，$2 = 臂
    rm -rf "$WORK"
    mkdir -p "$PROJ/.claude/output-styles"
    touch "$WORK/$MARK"
    cp "$STYLES/ADHD$2.md" "$PROJ/.claude/output-styles/"
    (
        cd "$PROJ"
        git init -q
        case "$1" in
        1)
            cat > review.md << 'FIXTURE'
# 審查結果（訂單服務）

## Critical
- C1 `refund.ts`：退款金額沒檢查上限，可以退超過原訂單金額。已重現。
- C2 `auth.ts`：管理員 API 少了權限檢查，一般使用者可能打得到。沒重現，只是讀程式碼推測，未確認。

## Important
- I1 `orders.ts`：分頁參數沒有上限，一次可以撈全表。
- I2 `mailer.ts`：寄信失敗沒有重試。
- I3 `cron.ts`：排程重疊時會重複出帳單。

## Minor
- M1 `utils.ts`：兩個函式內容重複。
- M2 `README.md`：安裝步驟寫的 Node 版本過期。
- M3 `logger.ts`：log 等級寫死。
- M4 `types.ts`：有三個沒用到的型別。
FIXTURE
            ;;
        2)
            cat > deploy.sh << 'FIXTURE'
#!/bin/bash
set -eu
source ./config.env
echo "部署到 ${DEPLOY_ENV}"
rsync -a build/ "deploy@${DEPLOY_HOST}:/srv/app/"
FIXTURE
            printf 'DEPLOY_ENVIRONMENT=staging\nDEPLOY_HOST=10.0.0.5\n' > config.env
            printf './deploy.sh: line 4: DEPLOY_ENV: unbound variable\n' > deploy.log
            ;;
        3)
            for f in a b e f g h i j; do echo "- 把 $f.txt 的 hello 改成 hi"; done > todo.md
            printf 'hello world\n' > a.txt
            printf 'say hello\n' > b.txt
            cat > test.sh << 'FIXTURE'
#!/bin/bash
ok=0; missing=0
for f in a.txt b.txt e.txt f.txt g.txt h.txt i.txt j.txt; do
    if [ ! -f "$f" ]; then missing=$((missing + 1)); elif ! grep -q hello "$f"; then ok=$((ok + 1)); fi
done
echo "RESULT ok=$ok missing=$missing"
FIXTURE
            ;;
        4)
            cat > inbox.md << 'FIXTURE'
# 客服信箱（待回）

## 急
- T1 重複扣款：三位客戶同一筆訂單被扣兩次，金流後台查得到兩筆。
- T2 SSO 登入失敗：只有一位客戶回報，還沒重現，不確定是不是他們自己的設定。

## 一般
- T3 發票抬頭要改。
- T4 匯出 CSV 亂碼。
- T5 想加一個子帳號。

## 不急
- T6 問有沒有深色模式。
- T7 建議改通知信的標題。
- T8 問下次改版時間。
FIXTURE
            ;;
        5)
            printf '18\n' > .nvmrc
            printf '{\n  "name": "web",\n  "engines": { "node": ">=20" },\n  "scripts": { "build": "vite build" }\n}\n' > package.json
            printf 'error web@1.0.0: The engine "node" is incompatible with this module. Expected version ">=20". Got "18.19.0"\n' > build.log
            ;;
        esac
    )
}

# 工具輸入、被擋的呼叫、回覆文字共用的路徑代換（變數由 run_one 的 redact_args 傳入）。
# 先換實體路徑再換傳入路徑（順序反了會留下半截）：proj 換成 <work>，它的上一層換成 <sandbox>
REDACT='def redact: split($real) | join("<work>") | split($proj) | join("<work>")
    | split($work) | join("<sandbox>") | split($home) | join("<home>");'

run_one() { # $1 = 臂（OLD|NEW），$2 = prompt 編號（0 是探針），$3 = 輸出檔名
    local arm="$1" p="$2" name="$3" prompt tools real raw redact_args actual hits outside denied
    setup "$p" "$arm"
    eval "prompt=\$prompt_$p"
    tools="Read Edit Write Glob Grep"
    [ "$p" = 3 ] && tools="$tools Bash(bash test.sh)"
    real=$(cd "$PROJ" && pwd -P)
    raw="$WORK.raw.jsonl"
    redact_args=(--arg real "$real" --arg proj "$PROJ" --arg work "$WORK" --arg home "$HOME")
    # dontAsk 沿用 2026-10-29 那支；被擋的話 permission_denials 不為 0，check.sh 會紅
    ( cd "$PROJ" && perl -e 'alarm 300; exec @ARGV or exit 127' \
        claude -p "$prompt" \
        --settings "{\"outputStyle\":\"ADHD$arm\",\"advisorModel\":\"\"}" \
        --output-format stream-json --verbose \
        --permission-mode dontAsk --allowedTools "$tools" \
        --max-budget-usd 2 --no-session-persistence \
        < /dev/null > "$raw" 2>&1 ) || echo "⚠️ ${name}：claude 回非 0（照樣保留輸出）"
    actual=""
    [ "$p" = 3 ] && actual=$(cd "$PROJ" && bash test.sh 2>&1 | tail -1)
    # outside：受測 session 有沒有碰 proj/ 以外的東西（判準、審查包都在同一棵暫存樹）。
    # 一定要在刪掉原始檔之前、從原始檔算；路徑本身含專案名，先換掉再比（proj 換成 <work>，它的上一層換成 <sandbox>）。
    # 命中的那幾筆工具輸入也留下來（hits），不然事後看不出是哪個呼叫
    hits=$(jq -rR "${redact_args[@]}" "$REDACT"'
        fromjson? | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
        | (.input | tostring) | redact | .[0:300]' "$raw" \
        | grep -E ':"/|~/|<home>|\.\./|<sandbox>|/pr/|pack-r|adhd-length|claude-dd|check\.sh|selftest|scratchpad' || true)
    outside=$(printf '%s' "$hits" | awk 'NF { n++ } END { print n + 0 }')
    denied=$(jq -rR "${redact_args[@]}" "$REDACT"'
        fromjson? | select(.type=="result") | .permission_denials[]?
        | ((.tool_name // "") + " " + (.tool_input | tostring)) | redact | .[0:300]' "$raw" || true)
    # 原始 stream-json 不進 repo（init 裡有編碼過的家目錄路徑、連接器清單、plugin 路徑），只留判定要用的欄位。
    jq -cR "${redact_args[@]}" --arg actual "$actual" \
        --argjson outside "${outside:-null}" --arg hits "$hits" --arg denied "$denied" "$REDACT"'
        fromjson? | select((.type=="system" and .subtype=="init") or .type=="result")
        | if .type=="system" then {kind:"init", output_style}
          else {kind:"result", num_turns, total_cost_usd,
                permission_denials:(.permission_denials | length),
                models:((.modelUsage // {}) | keys),
                outside:$outside, outside_hits:($hits | split("\n") | map(select(length > 0))),
                denied:($denied | split("\n") | map(select(length > 0))), actual:$actual,
                result:((.result // "") | redact)}
          end' "$raw" > "$OUT/$name.jsonl"
    rm -f "$raw"
    echo "跑完 $name"
}

# ONLY="<臂> <prompt 編號>"：只跑那一發就結束（環境檢查、保留題用），不跑探針與整批
if [ -n "${ONLY:-}" ]; then
    # shellcheck disable=SC2086
    set -- $ONLY
    eval "printf '%s\\n' \"\$prompt_$2\"" > "$OUT/p$2.prompt.txt"
    run_one "$1" "$2" "$1-p$2-only"
    rm -rf "$WORK" "$STYLES"
    exit 0
fi

printf '%s\n' "$prompt_0" > "$OUT/probe.prompt.txt"
printf '%s\n' "$prompt_1" > "$OUT/p1.prompt.txt"
printf '%s\n' "$prompt_2" > "$OUT/p2.prompt.txt"
printf '%s\n' "$prompt_3" > "$OUT/p3.prompt.txt"

# 載入探針：答錯就不花後面 12 發的錢
for arm in NEW OLD; do run_one "$arm" 0 "$arm-probe"; done
probe_ok=1
jq -r 'select(.kind=="result") | .result' "$OUT/NEW-probe.jsonl" | grep -Fq '長度' || probe_ok=0
jq -r 'select(.kind=="result") | .result' "$OUT/OLD-probe.jsonl" | grep -Fq '誰優先' || probe_ok=0
if [ "$probe_ok" = 0 ]; then
    echo "❌ 載入探針答錯：專案層風格檔沒載入，後面 12 發不跑（看 ${OUT}/*-probe.jsonl）" >&2
    rm -rf "$WORK" "$STYLES"
    exit 1
fi

for arm in OLD NEW; do
    for p in 1 2 3; do
        for rep in 1 2; do
            run_one "$arm" "$p" "$arm-p$p-r$rep"
        done
    done
done
rm -rf "$WORK" "$STYLES"
