#!/bin/bash
# CLAUDE.md gate（scripts/check-claude-md.sh）的情境測試：段落起點、SKIP 欠帳、中文與含空白的路徑。
# CI 會在 ubuntu（bash 5）與 macOS（/bin/bash 3.2）各跑一次（.github/workflows/ci.yml）。
#
# 用法：tests/test-gate.sh [gate 腳本路徑]　預設取 repo 裡的 scripts/check-claude-md.sh。
# 給別的路徑可以做變異測試：複製一份 gate 改壞一行，確認這裡會出現 ❌（scripts/CLAUDE.md 的規定）。
#
# 2026-09-11 修的漏洞：gate 原本只看「這次 commit」staged 的檔案。rental-line 段落 1
# 第一個 commit 用 SKIP 建了 4 個沒有 CLAUDE.md 的程式碼目錄，最後一個 commit 沒改
# 程式碼，gate 就放行了。現在記段落起點，正常 commit 時把起點以來欠的目錄一起查
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GATE="${1:-$ROOT/scripts/check-claude-md.sh}"
case "$GATE" in /*) ;; *) GATE="$PWD/$GATE" ;; esac
[ -x "$GATE" ] || { echo "❌ 找不到可執行的 ${GATE}"; exit 2; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT   # 本機會拿來重跑、做變異測試，暫存檔與拋棄式 repo 要清掉
OUT="$WORK/out"
mkdir "$WORK/repo" && cd "$WORK/repo" || exit 2
git init -q
git config user.email ci@example.com
git config user.name ci
printf '#!/bin/sh\nexec "%s"\n' "$GATE" > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
BASE_FILE="$(git rev-parse --git-path dd-segment-base)"
fail=0
expect() {  # $1=說明 $2=預期（pass / block） 其餘=指令
  desc="$1"; want="$2"; shift 2
  if "$@" > "$OUT" 2>&1; then got=pass; else got=block; fi
  # bash 3.2 不支援的寫法常常只印一行錯誤、結果照舊：輸出裡出現 shell 錯誤就算失敗，
  # 否則 macOS（/bin/bash 3.2）那個 CI job 會照樣全綠。bash 報腳本錯誤一律是「<腳本>: line N: …」，
  # 用這個前綴才抓得到 shopt、${a[-1]}、[ -v ] 這類清單外的錯誤；syntax error 另列，awk 的語法錯誤沒有前綴
  if grep -qE 'bad substitution|syntax error|command not found|invalid option|unbound variable|: line [0-9]+: ' "$OUT"; then
    echo "❌ ${desc}：輸出裡有 shell 錯誤"; sed 's/^/    /' "$OUT"; fail=1; return
  fi
  if [ "$got" = "$want" ]; then
    echo "✅ $desc"
  else
    echo "❌ ${desc}：預期 ${want}，實際 ${got}"; sed 's/^/    /' "$OUT"; fail=1
  fi
}
commit() { git add -A && git commit -qm "$1"; }
skip_commit() { git add -A && SKIP_DOC_CHECK=1 git commit -qm "$1"; }
said() { grep -qF "$1" "$OUT" || { echo "❌ 輸出沒提到：$1"; sed 's/^/    /' "$OUT"; fail=1; }; }
base_is() { [ "$(cat "$BASE_FILE" 2>/dev/null)" = "$1" ] || { echo "❌ 起點應為 ${1}，實際是 $(cat "$BASE_FILE" 2>/dev/null)"; fail=1; }; }

# 1. rental-line 段落 1：起點在第一個 commit 之前（還沒有 HEAD）
expect "還沒有 HEAD 也能記起點" pass "$GATE" --start-segment
base_is "$(git hash-object -t tree /dev/null)"
mkdir src && echo a > src/a.js
expect "SKIP 的檢查點 commit 放行" pass skip_commit c1
echo readme > README.md
expect "之後只改 README 的正常 commit 要擋（src 欠 CLAUDE.md）" block commit c2
said "src/CLAUDE.md"
echo doc > src/CLAUDE.md
expect "補上 src/CLAUDE.md 就放行" pass commit c3
echo more >> README.md
expect "欠的補完，之後不再追討" pass commit c4

# 2. 有欠帳時不准重記起點（起點往後移會把欠帳洗掉）
expect "沒有欠帳時可以重記起點" pass "$GATE" --start-segment
base_is "$(git rev-parse HEAD)"
echo b > src/b.js
expect "SKIP 改 src/b.js（起點不動）" pass skip_commit c5
base_is "$(git rev-parse HEAD~1)"
expect "有欠帳時拒絕重記起點" block "$GATE" --start-segment
said "先補完再記新起點"
base_is "$(git rev-parse HEAD~1)"
echo doc2 >> src/CLAUDE.md
expect "補完放行" pass commit c6

# 3. 起點再舊也不能變寬鬆：舊的 CLAUDE.md 更新抵不掉之後才 SKIP 的程式碼
echo c > src/c.js && echo doc3 >> src/CLAUDE.md
expect "X：程式碼和 CLAUDE.md 一起 commit" pass commit x
echo d > src/d.js
expect "Y：SKIP 只改程式碼" pass skip_commit y
echo z >> README.md
expect "Z：只改 README 也要擋（Y 欠的帳）" block commit z
said "src/CLAUDE.md"
echo doc4 >> src/CLAUDE.md
expect "補上放行" pass commit z2

# 4. 沒 SKIP 的 commit 規則不變：改到的目錄這次就要一起 staged CLAUDE.md
echo e >> src/a.js
expect "起點之後更新過 CLAUDE.md，這次沒 staged 仍要擋" block commit n1
said "未一起 staged"
echo doc5 >> src/CLAUDE.md
expect "同批補上放行" pass commit n2

# 5. --segment-base：有起點就印；沒有就失敗，不能印空字串給 git diff 吃
expect "有起點時印得出來" pass "$GATE" --segment-base
said "$(cat "$BASE_FILE" 2>/dev/null || echo 沒有起點檔)"
rm -f "$BASE_FILE"
expect "沒有起點時要失敗" block "$GATE" --segment-base

# 6. 忘了記起點：第一個 SKIP 自動記下；之後再 SKIP，起點也不動
echo f > src/f.js
expect "沒記起點直接 SKIP" pass skip_commit auto1
[ -f "$BASE_FILE" ] || { echo "❌ SKIP 沒有自動記下起點"; fail=1; }
said "$(cat "$BASE_FILE" 2>/dev/null || echo 沒有起點檔)"
mkdir p && echo 1 > p/x.js
expect "再 SKIP p/x.js（起點不動）" pass skip_commit auto2
base_is "$(git rev-parse HEAD~2)"
echo r >> README.md
expect "兩個 SKIP 欠的目錄都要擋" block commit auto3
said "src/CLAUDE.md"
said "p/CLAUDE.md"
echo doc6 >> src/CLAUDE.md && echo pdoc > p/CLAUDE.md
expect "補上放行" pass commit auto4

# 7. 起點被改寫、不在目前分支的歷史裡：改從共同祖先算，欠帳不能跟著消失
expect "重記起點" pass "$GATE" --start-segment
git checkout -qb br-rewritten && echo s > side.txt
expect "另一條線上的 commit（模擬被改寫的起點）" pass commit side
side=$(git rev-parse HEAD)
git checkout -q -
mkdir r && echo 1 > r/a.js
expect "SKIP r/a.js" pass skip_commit r1
echo "$side" > "$BASE_FILE"
expect "起點失效時 --segment-base 要失敗" block "$GATE" --segment-base
echo q >> README.md
expect "起點失效：從共同祖先算，照樣擋 r 欠的帳" block commit w1
# ⚠️ **這句子字串兩條路都會中**(2026-10-07 S4 的 review 抓到):退化放行的 fallback 訊息
#    「…不在目前分支的歷史裡,**也**找不到共同祖先…」含同一段字,所以把 fork-point 整支拿掉時
#    **這一則不會變紅**。要分辨得用後半句。
said "改從共同祖先 "    # 後面那個空格:fallback 訊息是「也找不到共同祖先,」,不含這個形狀
said "r/CLAUDE.md"
expect "起點失效也不准重記起點把欠帳洗掉" block "$GATE" --start-segment
echo rdoc > r/CLAUDE.md
expect "補上放行" pass commit w2
mkdir w && echo 1 > w/a.js
expect "staged 的程式碼目錄照查" block commit w3
said "w/CLAUDE.md"
echo wdoc > w/CLAUDE.md
expect "同批補上放行" pass commit w4

# 8. 欠帳的目錄後來沒有程式碼了：沒東西要補。看的是 index，只在工作目錄刪掉不算
expect "重記起點（取代失效的起點）" pass "$GATE" --start-segment
mkdir gone && echo g > gone/g.js
expect "SKIP 建 gone/g.js（沒有 CLAUDE.md）" pass skip_commit g1
git rm -rq gone
expect "刪掉整個 gone/ 的正常 commit 放行" pass commit g2
expect "目錄已刪，重記起點不再拒絕" pass "$GATE" --start-segment
mkdir mv && echo m > mv/m.js && echo '{}' > mv/data.json
expect "SKIP 建 mv/m.js" pass skip_commit mv1
git mv mv/m.js src/m.js && echo doc7 >> src/CLAUDE.md
expect "程式碼搬進 src（同批更新 src/CLAUDE.md），mv 只剩 data.json：放行" pass commit mv2
mkdir keep && echo k > keep/k.js
expect "SKIP 建 keep/k.js" pass skip_commit k1
rm -rf keep && echo k >> README.md && git add README.md
expect "只在工作目錄刪掉、沒 staged：commit 裡還有 keep/k.js，要擋" block git commit -qm k2
said "keep/CLAUDE.md"
git checkout -- keep
echo kdoc > keep/CLAUDE.md
expect "補上放行" pass commit k3

# 9. merge：平行分支上看不到那段程式碼的 CLAUDE.md 更新不算補上；merge commit 自己補的算
expect "重記起點" pass "$GATE" --start-segment
git checkout -qb br-feat
mkdir feat && echo f > feat/a.js
export GIT_AUTHOR_DATE=2030-01-01T00:00:00 GIT_COMMITTER_DATE=2030-01-01T00:00:00
expect "br-feat 上 SKIP 建 feat/a.js（日期較早）" pass skip_commit f1
git checkout -q -
mkdir -p feat && echo fdoc > feat/CLAUDE.md
export GIT_AUTHOR_DATE=2030-01-02T00:00:00 GIT_COMMITTER_DATE=2030-01-02T00:00:00
expect "主線先建 feat/CLAUDE.md（看不到 feat/a.js，日期較晚）" pass commit m1
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
git merge -q --no-edit br-feat
echo mm >> README.md
expect "merge 後的正常 commit 要擋：主線那份 CLAUDE.md 沒看過 feat/a.js" block commit m2
said "feat/CLAUDE.md"
echo fdoc2 >> feat/CLAUDE.md
expect "補上放行" pass commit m3
git checkout -qb br-feat2
mkdir feat2 && echo f > feat2/a.js
expect "br-feat2 上 SKIP 建 feat2/a.js" pass skip_commit f2
git checkout -q -
git merge -q --no-commit --no-ff br-feat2
echo f2doc > feat2/CLAUDE.md && git add feat2/CLAUDE.md
expect "merge commit 自己補上 feat2/CLAUDE.md：放行" pass git commit -qm merge2
echo y >> README.md
expect "之後不再追討 feat2" pass commit after2

# 10. 非 ASCII 路徑也要查（git 預設把中文路徑加引號跳脫，原本比對不到副檔名）
mkdir 功能 && echo 1 > 功能/a.js
expect "staged 中文目錄的程式碼、沒有 CLAUDE.md：要擋" block commit u1
said "功能/CLAUDE.md"
echo doc > 功能/CLAUDE.md
expect "補上放行" pass commit u2
mkdir 模組 && echo 1 > 模組/b.js
expect "SKIP 中文目錄的程式碼" pass skip_commit u3
echo u >> README.md
expect "之後的正常 commit 要擋 模組/CLAUDE.md" block commit u4
said "模組/CLAUDE.md"
echo doc > 模組/CLAUDE.md
expect "補上放行" pass commit u5

# 11. 根目錄的程式碼（路徑沒有斜線，目錄算成「.」）和含空白的目錄名也要查
echo 1 > top.js && mkdir "my dir" && echo 1 > "my dir/a.js"
expect "SKIP 根目錄與含空白目錄的程式碼" pass skip_commit t1
echo t >> README.md
expect "之後的正常 commit 要擋這兩個目錄" block commit t2
# 整行比對：根目錄這時還沒有 CLAUDE.md，要列在「缺少」清單；said 是子字串比對，「  CLAUDE.md（」開頭的行也會中
grep -qx '  CLAUDE.md' "$OUT" || { echo "❌ 輸出沒有列出根目錄的 CLAUDE.md"; sed 's/^/    /' "$OUT"; fail=1; }
said "my dir/CLAUDE.md"
echo doc > CLAUDE.md
expect "只補根目錄：my dir 還欠，照擋" block commit t3
said "my dir/CLAUDE.md"
echo doc > "my dir/CLAUDE.md"
expect "補上放行" pass commit t4
echo t >> README.md
expect "之後不再追討這兩個目錄" pass commit t5
# 根目錄已經有 CLAUDE.md 時：它的路徑是其他目錄 CLAUDE.md 路徑的字尾，別的目錄更新 CLAUDE.md 不能抵掉它
echo 2 >> top.js
expect "SKIP 改根目錄程式碼" pass skip_commit t6
echo more >> "my dir/CLAUDE.md"
expect "只 staged my dir/CLAUDE.md：根目錄還欠，照擋" block commit t7
said "  CLAUDE.md（段落起點之後"
echo more >> CLAUDE.md
expect "補上根目錄放行" pass commit t8
# 同批 staged 這條路也要認得含空白的目錄名
echo 1 > "my dir/b.js" && echo more2 >> "my dir/CLAUDE.md"
expect "含空白目錄的程式碼和它的 CLAUDE.md 同批：放行" pass commit t9

# ---- review 報告的強制(2026-10-07,S6)----
# 規則:專案有 docs/reviews/ 目錄時(= 採用了這個慣例),--start-segment 要求
# 「上一段的 commit 範圍內有新增 docs/reviews/S*.md」。
# ⚠️ **上面 61 項全部跑在沒有 docs/reviews/ 的拋棄式 repo 裡** —— 那正是 opt-in 的證明:
#    沒有這個目錄的專案完全不受影響,所以舊測試一項都不用改。
mkdir -p docs/reviews
echo '# 報告格式' > docs/reviews/CLAUDE.md
echo 1 > r.js && echo doc >> CLAUDE.md
expect "建立 docs/reviews/ 的那個 commit" pass commit r0

# ① 剛採用慣例時,上一段本來就沒報告 → 擋。這是真實的導入路徑,不是邊角情況
BEFORE_BASE=$(cat "$BASE_FILE" 2>/dev/null)   # 要在跑 gate 之前讀,之後讀就變成拿它自己比它自己
expect "剛採用慣例:上一段沒報告,照擋" block "$GATE" --start-segment
said "上一段沒有附 review 報告"
said "docs/reviews/S<段落>-SKIP.md"
base_is "$BEFORE_BASE"   # 被擋下時起點不可以被搬動

# ② 文件寫的出路:補一份 SKIP 申報 → 放行
echo '# S0 跳過 review:採用本慣例之前的段落' > docs/reviews/S0-SKIP.md
expect "補上 SKIP 申報的 commit" pass commit r1
expect "有 S<N>-SKIP.md:放行" pass "$GATE" --start-segment
base_is "$(git rev-parse HEAD)"

# ③ 下一段只改程式碼、沒附報告 → 拒絕
echo 2 > r.js && echo doc2 >> CLAUDE.md
expect "段落內的 commit" pass commit r2
expect "上一段沒附 review 報告:拒絕記新起點" block "$GATE" --start-segment
base_is "$(git rev-parse 'HEAD~1')"

# ④ 補上 S<N>-a.md / -b.md → 放行
echo '# S1 審查 — a' > docs/reviews/S1-a.md
echo '# S1 審查 — b' > docs/reviews/S1-b.md
expect "補上兩份報告的 commit" pass commit r3
expect "有 S<N>-a.md:放行" pass "$GATE" --start-segment
base_is "$(git rev-parse HEAD)"

# ⑤ 只改 docs/reviews/CLAUDE.md 不算報告(它不是 S 開頭)
echo 3 > r.js && echo doc3 >> CLAUDE.md
echo '改了格式說明' >> docs/reviews/CLAUDE.md
expect "只改報告格式說明的 commit" pass commit r4
expect "docs/reviews/CLAUDE.md 不算報告:照擋" block "$GATE" --start-segment

# ⑥ **只「修改」既有報告不算** —— gate 的訊息與五份文件都寫「有沒有**新增**」,
#    所以用 `--diff-filter=A`。第一版用 `ACMR`,於是上一段的 S1-a.md 改個錯字,
#    這一段零報告也能開下一段(reviewer 實測抓到)。
echo 4 > r.js && echo doc4 >> CLAUDE.md
echo '補一句處置' >> docs/reviews/S1-a.md
expect "只改既有報告的 commit" pass commit r4a
expect "只『修改』既有報告不算新增:照擋" block "$GATE" --start-segment
said "沒有新增任何 docs/reviews/S*.md"

# ⑦ **起點 commit 被改寫(amend / rebase)之後,檢查不可以靜默消失** ——
#    第一版在「起點不是祖先」時直接放行,於是 `git commit --amend` 掉起點那個 commit
#    就能讓整段的 review 要求蒸發(reviewer 實跑抓到)。現在退到共同祖先繼續算,
#    與同檔 `owed_dirs` 的退化規則一致。
echo '# S2 審查 — a' > docs/reviews/S2-a.md
expect "補報告放行" pass commit r4b
expect "重記起點" pass "$GATE" --start-segment
echo 5 > r.js && echo doc5 >> CLAUDE.md
expect "段落內的 commit" pass commit r4c
git commit -q --amend -m 'r4c amended'    # 改寫 HEAD(起點之後),起點本身仍在
# ⚠️ **這一則 amend 的是「段落內的 HEAD」,起點本身仍是祖先** —— 走的是 `range_base="$base"`
#    那一支,**沒有**跑到 fork-point 退化。上面那句註解原本寫「起點 commit 被改寫」,
#    名稱與實際不符(2026-10-07 S4 修正)。
#    ⚠️ **fork-point 退化本來就有測** —— 既有的情境 7 就是(對 `owed_dirs`);
#    ⑩ 補的是**對 `reviews_missing`** 的那一半,而且 ⑩ 也不是「改寫起點 commit」,
#    是從 `base^` 開新線讓起點不再是祖先(效果相同、寫法不同)。
expect "amend 段落內的 commit(起點仍是祖先):仍然照擋(零報告)" block "$GATE" --start-segment
said "沒有新增任何 docs/reviews/S*.md"

# ⑧ `docs/reviews/SUMMARY.md` 這種不是報告(pattern 是 S 後面接數字)
echo 6 > r.js && echo doc6 >> CLAUDE.md
echo '# 總覽' > docs/reviews/SUMMARY.md
expect "新增 SUMMARY.md 的 commit" pass commit r4d
expect "SUMMARY.md 不算報告:照擋" block "$GATE" --start-segment

# ⑨ 退出慣例的路要走得通:刪掉目錄就完全不啟用
rm -rf docs/reviews
expect "刪掉 docs/reviews/ 的 commit" pass commit r5
expect "沒有 docs/reviews/ 目錄:本檢查不啟用" pass "$GATE" --start-segment

# ⑩⑪ **三處「起點 → 有效範圍」的退化政策各自的行為**(2026-10-07 S4)。
# ⚠️ 這一段的存在理由:`check-claude-md.sh` 有**三處**在解析起點,而政策**刻意不同** ——
#    `owed_dirs` 與 `reviews_missing` 退到共同祖先(往寬退,才不會把欠帳 / report 要求洗掉),
#    `--segment-base` **必須硬失敗**(它的輸出要餵 `git diff`,印空字串或錯的 base 正是地雷)。
#    沒有這一段的話,把 `--segment-base` 也改成「退到共同祖先」的變異**不會有任何測試變紅**。
# ⚠️ 放在最後面是因為情境 ⑨ 把 docs/reviews 刪了,這裡要自己重建。
# ⚠️ 另外:**這幾則必須在「沒有 CLAUDE.md 欠帳」的狀態下跑** —— 否則 `--start-segment` 會
#    擋在欠帳那一關,`said` 斷言的 review 訊息根本不會出現(第一版就是這樣「為了錯的理由而通過」)。
mkdir -p docs/reviews && echo '# S9 審查 — a' > docs/reviews/S9-a.md
echo 7 > r.js && echo doc7 >> CLAUDE.md
expect "重建 docs/reviews 並補報告" pass commit r6a
expect "重記起點(起點 = r6a)" pass "$GATE" --start-segment
BASE_BEFORE=$(cat "$BASE_FILE")
echo 8 > r.js && echo doc8 >> CLAUDE.md
expect "段落內再一個 commit(零報告)" pass commit r6b

# 切到「起點的父」開新線:起點 r6a 不再是 HEAD 的祖先,而共同祖先 r6a^ 存在。
# 用正常 commit(同批更新 CLAUDE.md)才不會留下 SKIP 欠帳。
git checkout -q -b sideline "${BASE_BEFORE}^"
# ⚠️ **`docs/reviews/` 要在新線上重建** —— 這個檢查是 opt-in,判準是**工作目錄裡有沒有那個目錄**
#    (`[ -d docs/reviews ] || return 1`)。而 `r6a` 才是建目錄的那個 commit,它不在這條線上,
#    所以不重建的話整個檢查不啟用、測試會「為了錯的理由而通過」(第一版就是這樣)。
#    放的是 `CLAUDE.md` 而**不是** `S*.md`:目錄要存在,但範圍內不可以有新增的報告。
mkdir -p docs/reviews && echo '格式說明' > docs/reviews/CLAUDE.md
echo 9 > r.js && echo doc9 >> CLAUDE.md
expect "新線上的正常 commit(有 docs/reviews 目錄但零報告)" pass commit r6c
base_is "$BASE_BEFORE"      # 起點檔是 worktree 自己的,切 branch 不會動它

expect "起點不是祖先:--segment-base 必須硬失敗" block "$GATE" --segment-base
said "沒有可用的段落起點"

expect "起點不是祖先:reviews_missing 退到共同祖先,照樣擋" block "$GATE" --start-segment
# ⚠️ 斷言**帶 prefix 的那句**。`owed_dirs` 與 `reviews_missing` 共用 `resolve_fork_base`,
#    兩處的警告都含「改從共同祖先」—— 只斷言那五個字的話,`owed_dirs` 印了就過關,
#    分辨不出 `reviews_missing` 有沒有真的走到退化那一支。prefix 參數就是為此存在。
said "review 檢查改從共同祖先"
said "沒有新增任何 docs/reviews/S*.md"

# ⑪ 連共同祖先都沒有:兩處都要**放行但講出來**。
# ⚠️ 這是唯一允許的「放行」,所以必須斷言那**兩句**警告真的印出來 ——
#    第一版 `reviews_missing` 在這裡靜默通過,等於多一條繞過路徑(S6 的 review 抓到)。
# ⚠️⚠️ **兩句 said 都要挑「只有一處會印」的字串**:兩處的警告都含「找不到共同祖先」,
#    只斷言那五個字的話,`owed_dirs` 印了就過關。2026-10-07 實測這個洞:把
#    `reviews_missing` 的這一支改成 `return 0`(擋)、或整個拿掉它的警告,**90 項全綠**
#    —— 等於那一支完全沒測到。所以改斷言 `只檢查 staged`(只有 `owed_dirs` 印)
#    與 `跳過 review 報告檢查`(只有 `reviews_missing` 印)。
git checkout -q --orphan unrelated
git rm -rq --cached . >/dev/null 2>&1 || true
# ⚠️ **用 `git clean` 而不是列檔名**(2026-10-07 S4 的 review 抓到):原本那串 `rm -rf` 列的是
#    `r.js README.md src docs 'api server'` —— 而 **`api server` 在這個測試 repo 裡從來不存在**
#    (那是全域 CLAUDE.md 的範例名,我從範例抄而不是從實際的測試抄;真正建過的是 `my dir`),
#    同時漏掉 `p/ r/ w/ keep/ mv/ feat/ feat2/ 功能/ 模組/ 'my dir'/ top.js/ side.txt` 十幾個。
#    `commit()` 是 `git add -A`,所以那些目錄會被一起 commit 進 r7 —— 今天能過只因為它們此時
#    各自都已經有 CLAUDE.md。**之後若在 ⑪ 之前插一個「留下沒有 CLAUDE.md 的程式碼目錄」的情境,
#    r7 會變成 block、紅在 ⑪ 而病因在新情境。** 改成與內容無關的寫法就不會再有這個耦合。
git clean -xdfq 2>/dev/null || true
# ⚠️ **`docs/reviews/` 刪掉後要重建** —— 同 ⑩ 的理由:這個檢查是 opt-in,判準是**工作目錄裡
#    有沒有那個目錄**(`[ -d docs/reviews ] || return 1`)。上面那行 `rm -rf` 把 docs 一起刪了,
#    不重建的話 `reviews_missing` 第一行就 return,下面那句斷言永遠測不到(修正前就是這樣)。
#    放 `CLAUDE.md` 而**不是** `S*.md`:目錄要存在,但範圍內不可以有新增的報告。
mkdir -p docs/reviews && echo '格式說明' > docs/reviews/CLAUDE.md
mkdir -p lone && echo x > lone/x.js && echo doc > lone/CLAUDE.md && echo root > CLAUDE.md
expect "無關歷史上的第一個 commit" pass commit r7
# ⚠️ 起點檔到這裡還是 `BASE_BEFORE`,**因為 ⑩ 的 `--start-segment` 是被擋下的(擋下不寫入)**。
#    下面那個 `--start-segment` 會通過並覆蓋它,所以這個斷言只能放在這裡。
base_is "$BASE_BEFORE"

expect "沒有共同祖先:--segment-base 照樣硬失敗" block "$GATE" --segment-base
expect "沒有共同祖先:放行,但要講出來(不可靜默)" pass "$GATE" --start-segment
said "只檢查 staged"             # owed_dirs 那一處
said "跳過 review 報告檢查"       # reviews_missing 那一處

# ⚠️⚠️ **⑩⑪ 之後不要再接情境** —— 它們收尾在 orphan branch `unrelated` 上,
#    工作目錄被 `git clean -xdfq` 清空過(只留下這一段自己建的 `lone/` 與 `CLAUDE.md`),起點檔也被最後那個
#    `--start-segment` 覆蓋過。要加新情境請加在 ⑨ 之前,或自己重建需要的狀態。
exit $fail

