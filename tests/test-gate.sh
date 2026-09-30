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
OUT="$(mktemp)"
cd "$(mktemp -d)" || exit 2
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
  # 否則 macOS（/bin/bash 3.2）那個 CI job 會照樣全綠
  if grep -qE 'bad substitution|syntax error|command not found|invalid option|unbound variable' "$OUT"; then
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
said "不在目前分支的歷史裡"
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

exit $fail

