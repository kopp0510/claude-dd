#!/bin/bash
# /dd-stop 的本體（scripts/dd-stop.sh）的情境測試：暫停旗標、CLAUDE.local.md 的標記段、off 之後逐位元組還原、欠帳清單。
# CI 會在 ubuntu（bash 5）與 macOS（/bin/bash 3.2）各跑一次（.github/workflows/ci.yml）。
#
# 用法：tests/test-dd-stop.sh [dd-stop.sh 路徑] [gate 路徑]
# 都不給就取 repo 裡的 scripts/dd-stop.sh 與 scripts/check-claude-md.sh。兩支會被複製到暫存目錄的同一層
# （dd-stop.sh 找的是「跟自己同目錄」的 gate），拋棄式 repo 的 pre-commit 掛的也是那份 gate。
# 給別的路徑可以做變異測試：複製一份改壞一行，確認這裡會出現 ❌（變異對照見 scripts/CLAUDE.md）。
# 只換 gate：tests/test-dd-stop.sh "" <改壞的 check-claude-md.sh>
#
# 每個情境自己開一個乾淨的 repo（`newrepo`），互不相依：變異版讓某一則變紅，不會連鎖到別的情境。
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC_STOP="${1:-$ROOT/scripts/dd-stop.sh}"
case "$SRC_STOP" in /*) ;; *) SRC_STOP="$PWD/$SRC_STOP" ;; esac
SRC_GATE="${2:-$ROOT/scripts/check-claude-md.sh}"
case "$SRC_GATE" in /*) ;; *) SRC_GATE="$PWD/$SRC_GATE" ;; esac
for f in "$SRC_STOP" "$SRC_GATE"; do
  [ -f "$f" ] || { echo "❌ 找不到 ${f}"; exit 2; }
done
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
OUT="$WORK/out"
mkdir "$WORK/bin"
cp "$SRC_STOP" "$WORK/bin/dd-stop.sh"
cp "$SRC_GATE" "$WORK/bin/check-claude-md.sh"
chmod +x "$WORK/bin/dd-stop.sh" "$WORK/bin/check-claude-md.sh"
STOP="$WORK/bin/dd-stop.sh"
GATE="$WORK/bin/check-claude-md.sh"
LF=CLAUDE.local.md
fail=0

ng() { echo "❌ $*"; fail=1; }
ok() { echo "✅ $*"; }
newrepo() {  # $1=目錄名（在 $WORK 底下）。建好、掛上 gate、有第一個 commit，cd 進去
  mkdir -p "$WORK/$1" && cd "$WORK/$1" || exit 2
  git init -q
  git config user.email ci@example.com
  git config user.name ci
  printf '#!/bin/sh\nexec "%s"\n' "$GATE" > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  echo root > CLAUDE.md
  git add CLAUDE.md && git commit -qm init
}
# $1=說明 $2=預期 exit code 其餘=整條指令；輸出（stdout+stderr）留在 $OUT
run() {
  desc="$1"; want="$2"; shift 2
  set +e; "$@" > "$OUT" 2>&1; got=$?; set -e
  # 同 test-gate.sh：bash 3.2 不支援的寫法常常只印一行錯誤、結果照舊，輸出裡有 shell 錯誤就算失敗
  if grep -qE 'bad substitution|syntax error|command not found|invalid option|unbound variable|: line [0-9]+: ' "$OUT"; then
    ng "${desc}：輸出裡有 shell 錯誤"; sed 's/^/    /' "$OUT"; return
  fi
  if [ "$got" = "$want" ]; then ok "$desc"; else ng "${desc}：預期 exit ${want}，實際 exit ${got}"; sed 's/^/    /' "$OUT"; fi
}
# ⚠️ said／not_said 的字串不可以用 - 開頭（會被當成 grep 的選項，見 tests/CLAUDE.md）
said() { grep -qF "$1" "$OUT" || { ng "輸出沒提到：$1"; sed 's/^/    /' "$OUT"; }; }
not_said() { if grep -qF "$1" "$OUT"; then ng "輸出不該提到：$1"; sed 's/^/    /' "$OUT"; fi; }
ck() {  # $1=說明 其餘=要成立的指令
  desc="$1"; shift
  if "$@" > /dev/null 2>&1; then ok "$desc"; else ng "$desc"; fi
}
flag() { git config --local --get dd.stopped 2>/dev/null || true; }
flag_true() { [ "$(flag)" = "true" ]; }
flag_unset() { [ -z "$(flag)" ]; }
blocks() { if [ -f "$LF" ]; then grep -c '^<!-- dd-stop:begin ' "$LF" || true; else echo 0; fi; }
blocks_is() { [ "$(blocks)" = "$1" ]; }
exclude_lines() { grep -c -x -F "/$LF" "$(git rev-parse --git-path info/exclude)" || true; }
exclude_is() { [ "$(exclude_lines)" = "$1" ]; }
untracked_hidden() { ! git status --porcelain | grep -q "$LF"; }
absent() { [ ! -e "$1" ] && [ ! -L "$1" ]; }
same() { cmp -s "$1" "$2"; }
differs() { ! cmp -s "$1" "$2"; }
before() { [ "$1" -gt 0 ] && [ "$1" -lt "$2" ]; }      # 兩個都是行號；0 = 沒找到
content_is() { [ "$(cat "$1"; echo x)" = "$2" ]; }   # $2 = 預期內容後面接一個 x（保住結尾的換行）

# A 原本沒有 CLAUDE.local.md：on、重跑 on、status、off
newrepo a
run "A on（原本沒有 ${LF}）" 0 "$STOP" on
said "8 步迴圈已暫停"
ck "A on 之後旗標是 true" flag_true
ck "A 標記段恰好一份" blocks_is 1
ck "A info/exclude 有那一行、恰好一行" exclude_is 1
ck "A git status 看不到 ${LF}" untracked_hidden
ck "A 開頭行記的是 created=1 sep=0" grep -q '^<!-- dd-stop:begin created=1 sep=0 ' "$LF"
ck "A 標記段最後一行是結尾行" [ "$(tail -n 1 "$LF")" = '<!-- dd-stop:end -->' ]
ck "A 聲明有日期" grep -q "（$(date +%Y-%m-%d) 起" "$LF"
for s in '8 步開發迴圈暫停中' '不呼叫 `dd-loop`' '不跑 `--start-segment`' '不要加 `SKIP_DOC_CHECK=1`' '`--no-verify`' '恢復：`/dd-stop off`' '全域 CLAUDE.md §3.9'; do
  ck "A 聲明裡有「${s}」" grep -qF -- "$s" "$LF"
done
cp "$LF" "$WORK/block-sample.md"      # 後面 symlink、已進版控的情境拿它當「檔裡已經有標記段」的素材
run "A 再跑一次 on" 0 "$STOP" on
ck "A 重跑 on：標記段仍一份" blocks_is 1
ck "A 重跑 on：info/exclude 仍一行" exclude_is 1
ck "A 重跑 on：內容與第一次相同" same "$LF" "$WORK/block-sample.md"
run "A status（暫停中）" 0 "$STOP" status
said "暫停中"
said "標記段）：在"
not_said "不一致"
run "A off" 0 "$STOP" off
said "8 步迴圈已恢復"
said "以下是 gate 的欠帳檢查（這次沒有 commit 被擋）"
said "沒有要補的"
not_said "docs/reviews"
ck "A off 之後旗標沒了" flag_unset
ck "A off 之後 ${LF} 不存在（它是 on 建的）" absent "$LF"
ck "A off 之後 info/exclude 那一行留著" exclude_is 1
run "A status（沒有暫停）" 0 "$STOP" status
said "沒有暫停"
said "標記段）：不在"
not_said "不一致"
run "A 沒暫停時再跑 off" 0 "$STOP" off
said "8 步迴圈已恢復"

# B on 再 off：原本就在的檔逐位元組還原，而且不刪
roundtrip() {  # $1=代號 $2=說明；原檔已經放在 $WORK/orig-$1
  newrepo "b-$1"
  cp "$WORK/orig-$1" "$LF"
  run "B ${2}：on" 0 "$STOP" on
  ck "B ${2}：on 之後標記段一份" blocks_is 1
  ck "B ${2}：on 之後檔案變了" differs "$LF" "$WORK/orig-$1"
  ck "B ${2}：開頭行記的是 created=0 sep=${3}" grep -q "^<!-- dd-stop:begin created=0 sep=${3} " "$LF"
  run "B ${2}：off" 0 "$STOP" off
  ck "B ${2}：off 之後檔還在" [ -f "$LF" ]
  ck "B ${2}：off 之後與原檔逐位元組相同" same "$LF" "$WORK/orig-$1"
}
: > "$WORK/orig-empty";                       roundtrip empty "原本 0 bytes" 0
printf '  \n\n' > "$WORK/orig-blank";         roundtrip blank "原本只有空白（結尾有換行）" 0
printf '  ' > "$WORK/orig-blank2";            roundtrip blank2 "原本只有空白（結尾沒有換行）" 1
printf '# 我的筆記\n第二行\n' > "$WORK/orig-nl"; roundtrip nl "原本有內容、結尾有換行" 0
printf '# 我的筆記\n第二行' > "$WORK/orig-nonl"; roundtrip nonl "原本有內容、結尾沒有換行" 1

# C 暫停期間使用者自己在標記段後面加字：off 之後那些字留著
newrepo c1
printf '原本\n' > "$LF"
run "C on（結尾有換行的原檔）" 0 "$STOP" on
echo '暫停期間加的' >> "$LF"
run "C off" 0 "$STOP" off
ck "C 標記段沒了" blocks_is 0
ck "C 原本的與暫停期間加的都在、順序不變" content_is "$LF" "$(printf '原本\n暫停期間加的\nx')"
newrepo c2
printf '原本' > "$LF"
run "C on（結尾沒有換行的原檔）" 0 "$STOP" on
echo '暫停期間加的' >> "$LF"
run "C off（標記段後面有字）" 0 "$STOP" off
# on 補的那個換行這時要留著：拿掉的話「原本」與「暫停期間加的」會黏成一行
ck "C 結尾沒有換行的原檔：兩行沒有黏在一起" content_is "$LF" "$(printf '原本\n暫停期間加的\nx')"
newrepo c3
printf '前\n' > "$LF"
cat "$WORK/block-sample.md" >> "$LF"
printf '中\n' >> "$LF"
cat "$WORK/block-sample.md" >> "$LF"
git config --local dd.stopped true
run "C off（檔裡有兩份標記段）" 0 "$STOP" off
ck "C 兩份標記段都拿掉" blocks_is 0
ck "C 兩份標記段之間與之前的字留著" content_is "$LF" "$(printf '前\n中\nx')"

# D symlink
newrepo d1
printf '別處的檔\n' > "$WORK/d1-target.md"
cp "$WORK/d1-target.md" "$WORK/d1-target.orig"
ln -s "$WORK/d1-target.md" "$LF"
run "D ${LF} 是 symlink：on 拒絕" 4 "$STOP" on
said "symlink"
not_said "8 步迴圈已暫停"
ck "D on 被拒：旗標沒設" flag_unset
ck "D on 被拒：連結指到的檔沒被寫" same "$WORK/d1-target.md" "$WORK/d1-target.orig"
run "D symlink 而裡面沒有標記段：off 照常" 0 "$STOP" off
said "8 步迴圈已恢復"
newrepo d2
cp "$WORK/block-sample.md" "$WORK/d2-target.md"
cp "$WORK/d2-target.md" "$WORK/d2-target.orig"
ln -s "$WORK/d2-target.md" "$LF"
git config --local dd.stopped true
run "D symlink 而裡面有標記段：off 回 5" 5 "$STOP" off
said "旗標已清除"
not_said "8 步迴圈已恢復"
ck "D off：旗標照樣清掉" flag_unset
ck "D off：連結指到的檔沒被動" same "$WORK/d2-target.md" "$WORK/d2-target.orig"
ck "D off：symlink 還是 symlink" [ -L "$LF" ]

# E 已進版控
newrepo e1
printf '進了版控的筆記\n' > "$LF"
git add "$LF" && git commit -qm track
cp "$LF" "$WORK/e1.orig"
run "E ${LF} 已進版控：on 拒絕" 4 "$STOP" on
said "已經進版控"
not_said "8 步迴圈已暫停"
ck "E on 被拒：旗標沒設" flag_unset
ck "E on 被拒：檔案沒被寫" same "$LF" "$WORK/e1.orig"
cat "$WORK/block-sample.md" >> "$LF"
cp "$LF" "$WORK/e1.withblock"
git config --local dd.stopped true
run "E 已進版控而裡面有標記段：off 回 5" 5 "$STOP" off
not_said "8 步迴圈已恢復"
ck "E off：旗標照樣清掉" flag_unset
ck "E off：檔案沒被動" same "$LF" "$WORK/e1.withblock"

# F 同目錄的 gate 是舊版（不認得 dd.stopped）或不在
mkdir "$WORK/oldbin" "$WORK/nogatebin"
cp "$STOP" "$WORK/oldbin/dd-stop.sh"
sed 's/dd\.stopped/dd_removed/g' "$GATE" > "$WORK/oldbin/check-claude-md.sh"
chmod +x "$WORK/oldbin/dd-stop.sh" "$WORK/oldbin/check-claude-md.sh"
cp "$STOP" "$WORK/nogatebin/dd-stop.sh"
chmod +x "$WORK/nogatebin/dd-stop.sh"
newrepo f
run "F 舊版 gate：on 拒絕" 3 "$WORK/oldbin/dd-stop.sh" on
said "install-dd-pipeline.sh --force"
ck "F 舊版 gate：旗標沒設" flag_unset
ck "F 舊版 gate：沒有建 ${LF}" absent "$LF"
run "F 同目錄沒有 gate：on 拒絕" 3 "$WORK/nogatebin/dd-stop.sh" on
ck "F 沒有 gate：旗標沒設" flag_unset

# G 暫停期間的欠帳：off 列出來，之後 gate 真的恢復擋
newrepo g
run "G on" 0 "$STOP" on
mkdir a && echo 1 > a/x.sh
git add a
run "G 暫停中：改 a/ 不補文件的 commit 放行" 0 git commit -qm paused
said "gate 暫停中"
run "G off" 0 "$STOP" off
said "以下是 gate 的欠帳檢查（這次沒有 commit 被擋）"
said "a/CLAUDE.md"
not_said "沒有要補的"
said "8 步迴圈已恢復"
h=$(grep -n -F '以下是 gate 的欠帳檢查' "$OUT" | sed -n '1s/:.*//p')
d=$(grep -n -F 'a/CLAUDE.md' "$OUT" | sed -n '1s/:.*//p')
r=$(grep -n -F '8 步迴圈已恢復' "$OUT" | sed -n '1s/:.*//p')
ck "G 順序：說明那一行在欠帳清單之前" before "${h:-0}" "${d:-0}"
ck "G 順序：已恢復在欠帳清單之後" before "${d:-0}" "${r:-0}"
echo note > note.txt && git add note.txt
run "G off 之後：沒碰 a/ 的 commit 被擋（gate 恢復了）" 1 git commit -qm after
said "a/CLAUDE.md"
# 環境裡留著 SKIP_DOC_CHECK=1 時，off 的欠帳檢查照樣要查
newrepo g2
run "G2 on" 0 "$STOP" on
mkdir a && echo 1 > a/x.sh
git add a
run "G2 暫停中的 commit" 0 git commit -qm paused
run "G2 環境有 SKIP_DOC_CHECK=1 時 off" 0 env SKIP_DOC_CHECK=1 "$STOP" off
said "a/CLAUDE.md"
not_said "沒有要補的"

# H 起點檔壞掉：off 不可以說「沒有要補的」
newrepo h
run "H on" 0 "$STOP" on
echo not-a-sha > "$(git rev-parse --git-path dd-segment-base)"
run "H 起點檔壞掉時 off" 0 "$STOP" off
said "算不出來"
not_said "沒有要補的"
said "8 步迴圈已恢復"

# I 有 docs/reviews/ 的專案：off 多印一行（沒有的對照在 A）
newrepo i
mkdir -p docs/reviews && echo 說明 > docs/reviews/CLAUDE.md
run "I on" 0 "$STOP" on
run "I 有 docs/reviews/ 時 off" 0 "$STOP" off
said "review 報告"
said "SKIP.md"

# J status：旗標與聲明不一致的兩種（一致的兩種在 A）
newrepo j
git config --local dd.stopped true
run "J status：有旗標、沒有聲明" 0 "$STOP" status
said "暫停中"
said "標記段）：不在"
said "不一致"
ck "J status 不自己修：旗標還在" flag_true
ck "J status 不自己修：沒有建 ${LF}" absent "$LF"
run "J on 補上缺的聲明" 0 "$STOP" on
ck "J on 之後標記段一份" blocks_is 1
git config --local --unset dd.stopped
run "J status：沒有旗標、有聲明" 0 "$STOP" status
said "沒有暫停"
said "標記段）：在"
said "不一致"
ck "J status 不自己修：標記段還在" blocks_is 1
git config --local dd.stopped false
run "J status：dd.stopped=false 算沒有暫停" 0 "$STOP" status
said "沒有暫停"

# K repo 路徑有空白與中文；從子目錄跑
newrepo "我的 專案"
printf '筆記' > "$LF"
cp "$LF" "$WORK/k.orig"
mkdir -p "子 目錄"
run "K 路徑有空白與中文、從子目錄跑：on" 0 sh -c 'cd "子 目錄" && exec "$0" on' "$STOP"
ck "K 標記段寫在 repo 根目錄" blocks_is 1
ck "K 子目錄沒有多出 ${LF}" absent "子 目錄/$LF"
ck "K info/exclude 有那一行" exclude_is 1
ck "K 旗標是 true" flag_true
run "K 從子目錄跑：off" 0 sh -c 'cd "子 目錄" && exec "$0" off' "$STOP"
ck "K off 之後與原檔逐位元組相同" same "$LF" "$WORK/k.orig"

# L info/exclude 的兩種邊角
newrepo l1
echo "$LF" > .gitignore && git add .gitignore && git commit -qm ignore
run "L 已經被 .gitignore 忽略：on" 0 "$STOP" on
ck "L 已經被忽略：不再寫 info/exclude" exclude_is 0
newrepo l2
printf 'foo' > .git/info/exclude
run "L info/exclude 結尾沒有換行：on" 0 "$STOP" on
ck "L 原本那一行沒有被黏住" grep -q -x 'foo' .git/info/exclude
ck "L 新的那一行自成一行" exclude_is 1

# M 標記段沒有結尾行：off 不動檔、回 5
newrepo m
printf '前\n<!-- dd-stop:begin created=0 sep=0 手動弄壞的 -->\n後\n' > "$LF"
cp "$LF" "$WORK/m.orig"
git config --local dd.stopped true
run "M 標記段沒有結尾行：off 回 5" 5 "$STOP" off
not_said "8 步迴圈已恢復"
ck "M 檔案沒被動" same "$LF" "$WORK/m.orig"
ck "M 旗標照樣清掉" flag_unset

# N 用法與不在 git repo
newrepo n
run "N 沒有參數：exit 2" 2 "$STOP"
said "用法"
run "N 不認得的參數：exit 2" 2 "$STOP" pause
run "N 多一個參數：exit 2" 2 "$STOP" on extra
ck "N 用法錯時旗標沒設" flag_unset
mkdir "$WORK/nogit" && cd "$WORK/nogit" || exit 2
run "N 不在 git repo：exit 1" 1 "$STOP" on
said "不在 git repo"

exit $fail
