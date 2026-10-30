#!/bin/bash
# /dd-init 升級分類腳本（scripts/dd-init-upgrade.sh）的情境測試：舊版蓋章區塊換新、專案自己加的內容留在原本那一步底下。
# CI 會在 ubuntu（bash 5）與 macOS（/bin/bash 3.2）各跑一次（.github/workflows/ci.yml）；要 git 歷史（fixture 從 tag 抽）。
#
# 用法：tests/test-dd-init-upgrade.sh [腳本路徑]　預設取 repo 裡的 scripts/dd-init-upgrade.sh。
# 給別的路徑可以做變異測試：複製一份腳本改壞一行，確認這裡會出現 ❌（變異對照見 tests/CLAUDE.md）。
#
# 斷言不讀腳本自己的清單：「該清掉的範本行」由各版 commands/dd-init.md 的區塊減掉現行區塊算出來，
# 「該留下的在地行」是這裡自己插進 fixture 的 LOCAL* 行。
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
UP="${1:-$ROOT/scripts/dd-init-upgrade.sh}"
case "$UP" in /*) ;; *) UP="$PWD/$UP" ;; esac
[ -x "$UP" ] || { echo "❌ 找不到可執行的 ${UP}"; exit 2; }
TPL="$ROOT/commands/dd-init.md"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
OUT="$WORK/out"
fail=0

ng() { echo "❌ $*"; fail=1; }
ok() { echo "✅ $*"; }
stamp() { awk '/^```markdown$/ && !f {f=1; next} f && /^```$/ {exit} f'; }
trimmed() { LC_ALL=C sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$1"; }
# $1=說明 $2=預期 exit 其餘=腳本參數；輸出（stdout+stderr）留在 $OUT
run() {
  desc="$1"; want="$2"; shift 2
  set +e; "$UP" --template "$TPL" "$@" > "$OUT" 2>&1; got=$?; set -e
  # 同 test-gate.sh：bash 3.2 不支援的寫法常常只印一行錯誤、結果照舊，輸出裡有 shell 錯誤就算失敗
  if grep -qE 'bad substitution|syntax error|command not found|invalid option|unbound variable|: line [0-9]+: ' "$OUT"; then
    ng "${desc}：輸出裡有 shell 錯誤"; sed 's/^/    /' "$OUT"; return
  fi
  if [ "$got" = "$want" ]; then ok "$desc"; else ng "${desc}：預期 exit ${want}，實際 ${got}"; sed 's/^/    /' "$OUT"; fi
}
lineof() { grep -nF -- "$2" "$1" | head -1 | cut -d: -f1; }   # 第一個含 $2 的行號，沒有就空字串
# 檔案 $1 裡 $2 出現在 $3 之前（各取第一個）
before() {
  a=$(lineof "$1" "$2"); b=$(lineof "$1" "$3")
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then return 0; fi
  ng "$(basename "$1")：「${2}」（第 ${a:-?} 行）應在「${3}」（第 ${b:-?} 行）之前"; return 1
}
count_is() {  # $1=檔 $2=固定字串 $3=預期次數
  c=$(grep -cF -- "$2" "$1" || true)
  [ "$c" = "$3" ] || ng "$(basename "$1")：「${2}」出現 ${c} 次，預期 ${3}"
}
said() { grep -qF -- "$1" "$OUT" || { ng "輸出沒提到：$1"; sed 's/^/    /' "$OUT"; }; }

stamp < "$TPL" > "$WORK/new"
[ -s "$WORK/new" ] || { echo "❌ 抽不到現行蓋章區塊"; exit 2; }
trimmed "$WORK/new" | LC_ALL=C sort -u > "$WORK/new.trim"

# 舊版區塊插入在地內容：步驟 1 之前、步驟 4、5、8 底下、驗證不過之後（含一行逐字等於 `---` 的）、CLAUDE.md 維護底下、區塊外一個在地小節
add_locals() {
  awk '
    /^1\. / && !p { print "LOCALP 步驟 1 之前的在地註記"; print ""; p = 1 }
    /^5\. / { print "   - LOCAL4 步驟 4 的在地規則" }
    /^6\. / { print "   - LOCAL5 專案驗證："; print "     ```bash"; print "     curl -s localhost:3000/LOCAL5"; print "     ```" }
    /^驗證不過/ { print "   - LOCAL8 步驟 8 的在地規則"; print ""; print; print ""; print "LOCALV 驗證不過之後的在地一行"; print "---"; next }
    m == 1 && /^- / { print; print "- LOCALM 維護小節的在地規則"; m = 2; next }
    /^## CLAUDE\.md 維護/ { m = 1 }
    { print }
  '
}
wrap() {  # stdin = 區塊；包上專案自己的檔頭與區塊外的在地小節
  printf '# 專案X\n\n專案說明 LOCALH\n\n'; cat; printf '\n## 在地小節\n\n- LOCALX 在地小節的內容\n'
}

# ---- 1. 四個舊版：在地內容留在原步驟、該版的範本行清乾淨、只有一個標記 ----
for tag in v1.6.12 v1.6.4 6a9addd v1.1.0; do
  f="$WORK/$tag.md"; o="$WORK/$tag.out.md"
  git -C "$ROOT" show "${tag}:commands/dd-init.md" | stamp > "$WORK/$tag.blk"
  grep -q 'dd-loop-version' "$WORK/$tag.blk" || { ng "${tag}：抽不到帶標記的區塊（CI 的 checkout 要 fetch-depth: 0）"; continue; }
  add_locals < "$WORK/$tag.blk" | wrap > "$f"
  run "${tag}：--plan" 0 --plan "$f"
  run "${tag}：--apply" 0 --apply "$f" "$o"
  [ -f "$o" ] || { ng "${tag}：沒有產生輸出檔"; continue; }
  for s in LOCALH LOCALP LOCAL4 "LOCAL5 專案驗證" "localhost:3000/LOCAL5" LOCAL8 LOCALV LOCALM LOCALX; do count_is "$o" "$s" 1; done
  before "$o" "LOCALH" "## 開發流程" || true
  before "$o" "dd-loop-version" "LOCALP" && before "$o" "LOCALP" "1. **實作功能" || true
  before "$o" "4. 跑 **code-review**" "LOCAL4" && before "$o" "LOCAL4" "5. **再測一次**" || true
  before "$o" "5. **再測一次**" "LOCAL5" && before "$o" "curl -s localhost:3000/LOCAL5" "6. **再 commit**" || true
  before "$o" "8. **評分" "LOCAL8" && before "$o" "LOCAL8" "驗證不過" || true
  before "$o" "驗證不過" "LOCALV" && before "$o" "LOCALV" "## CLAUDE.md 維護" || true
  [ "$(sed -n "$(( $(lineof "$o" LOCALV) + 1 ))p" "$o")" = "---" ] || ng "${tag}：LOCALV 下一行的 --- 不見了"
  before "$o" "## CLAUDE.md 維護" "LOCALM" && before "$o" "LOCALM" "## 在地小節" || true
  before "$o" "## 在地小節" "LOCALX" || true
  count_is "$o" "dd-loop-version" 1
  count_is "$o" "$(grep 'dd-loop-version' "$WORK/new")" 1   # 標記是現行版（rev 13）那一行
  count_is "$o" "## 開發流程" 1
  # 該版有、現行區塊沒有的範本行，在輸出裡要是 0 次
  trimmed "$o" > "$o.trim"
  left=0
  trimmed "$WORK/$tag.blk" | LC_ALL=C grep -v -e '^$' -e '^---$' -e '^```[A-Za-z]*$' | LC_ALL=C sort -u \
    | LC_ALL=C comm -23 - "$WORK/new.trim" > "$WORK/$tag.gone"
  while IFS= read -r t; do
    if grep -qxF -- "$t" "$o.trim"; then left=$((left + 1)); echo "    還在：$t"; fi
  done < "$WORK/$tag.gone"
  if [ "$left" = 0 ]; then ok "${tag}：該版獨有的 $(grep -c '' "$WORK/$tag.gone" || true) 行範本都清掉了"; else ng "${tag}：${left} 行舊範本還在"; fi
done

# ---- 2. 純範本（零在地內容）：整塊換成現行區塊，檔頭檔尾不動 ----
f="$WORK/pure.md"; o="$WORK/pure.out.md"
wrap < "$WORK/v1.6.4.blk" > "$f"
run "純範本：--apply" 0 --apply "$f" "$o"
wrap < "$WORK/new" > "$WORK/pure.want"
if cmp -s "$o" "$WORK/pure.want"; then ok "純範本：輸出等於檔頭 + 現行區塊 + 檔尾"; else ng "純範本：輸出與預期不同"; diff "$WORK/pure.want" "$o" | head -20 | sed 's/^/    /'; fi

# 現行區塊自己跑一次：結果與原檔逐字相同（現行區塊的每一行都在清單裡，不會被當成在地內容多留一份）
wrap < "$WORK/new" > "$WORK/cur.md"
run "現行區塊：--apply" 0 --apply "$WORK/cur.md" "$WORK/cur.out.md"
if cmp -s "$WORK/cur.md" "$WORK/cur.out.md"; then ok "現行區塊：輸出與原檔相同"; else ng "現行區塊：輸出與原檔不同"; diff "$WORK/cur.md" "$WORK/cur.out.md" | head -20 | sed 's/^/    /'; fi

# ---- 3. rental-management 型：區塊掛在專案自己的 ### 底下 ----
f="$WORK/rental.md"; o="$WORK/rental.out.md"
{ printf '# 專案R\n\n## 專案規則\n\n'
  sed 's/^## 開發流程（每個功能段落依序走）$/### 工作流程（完成的定義，不可省略）/' "$WORK/6a9addd.blk"
  printf '\n## 部署\n\n- LOCALD\n'; } > "$f"
run "rental 型：--plan" 0 --plan "$f"
said "在地，保留"
run "rental 型：--apply" 0 --apply "$f" "$o"
count_is "$o" "### 工作流程（完成的定義，不可省略）" 1
count_is "$o" "## 開發流程" 0
count_is "$o" "dd-loop-version" 1
grep -qx '#### CLAUDE.md 維護' "$o" && ok "rental 型：新區塊的 ## 降成 ####，掛在在地 ### 底下" || ng "rental 型：找不到降級後的 #### CLAUDE.md 維護"
before "$o" "dd-loop-version" "## 部署" && count_is "$o" "LOCALD" 1 || true
# 升級過一次（標題已降級）的再升一次：結果不變，降級後的 #### CLAUDE.md 維護 不會被當成在地行多留一份
run "rental 型：第二次 --apply" 0 --apply "$o" "$WORK/rental.out2.md"
if cmp -s "$o" "$WORK/rental.out2.md"; then ok "rental 型：第二次升級輸出不變"; else ng "rental 型：第二次升級輸出改變了"; diff "$o" "$WORK/rental.out2.md" | head -10 | sed 's/^/    /'; fi

# ---- 3b. 專案改寫過步驟 5 那一行：它底下的驗證指令仍算步驟 5（Phase 1 靠那一節決定佔位行填或刪） ----
f="$WORK/s5.md"; o="$WORK/s5.out.md"
awk '/^5\. / { print "5. **再測一次**（本專案改寫）"; print "   - LOCALS5 npm run e2e"; skip = 1; next } skip && /^6\. / { skip = 0 } !skip { print }' "$WORK/v1.6.12.blk" | wrap > "$f"
run "改寫步驟 5：--plan" 0 --plan "$f"
sed -n '/^## 步驟 5 既有的驗證指令行/,/^## /p' "$OUT" | grep -q 'LOCALS5' \
  && ok "改寫步驟 5：底下的指令列在「步驟 5 既有的驗證指令行」" || ng "改寫步驟 5：「步驟 5 既有的驗證指令行」沒列 LOCALS5"
run "改寫步驟 5：--apply" 0 --apply "$f" "$o"
before "$o" "5. **再測一次** —" "LOCALS5" && before "$o" "LOCALS5" "6. **再 commit**" || true

# ---- 4. 在地 ## 夾在步驟 8 與驗證不過之間：後面的範本行換不到，--plan 要點名 ----
f="$WORK/cut.md"
awk '/^驗證不過/ { print "## 在地插隊小節"; print ""; print "- LOCALY"; print "" } { print }' "$WORK/v1.6.4.blk" | wrap > "$f"
run "在地 ## 截斷區塊：--plan" 0 --plan "$f"
n=$(lineof "$f" "驗證不過")
sed -n '/^## 區塊外還有範本行/,$p' "$OUT" | grep -q "^  ${n}: 驗證不過" \
  && ok "在地 ## 截斷區塊：「區塊外還有範本行」列出第 ${n} 行的驗證不過" || ng "在地 ## 截斷區塊：「區塊外還有範本行」沒列第 ${n} 行"

# ---- 5. 區塊後段的大段在地內容原地不動；改寫過的範本句列在「相似」；步驟 7 改寫列在「疑似改寫」 ----
f="$WORK/tail.md"; o="$WORK/tail.out.md"
awk '
  /^   - 範圍要明講給 reviewer：/ { print $0 "（在地改寫）"; next }
  /^7\. / { print "7. **沉澱這輪學到的東西**（在地改寫的步驟行）"; next }
  { print }
  END { print ""; print "LOCALT1 區塊後段的在地段落"; print ""; print "- LOCALT2 後段清單"; print "- LOCALT3 後段清單" }
' "$WORK/v1.6.4.blk" | wrap > "$f"
run "後段在地內容：--plan" 0 --plan "$f"
n=$(lineof "$f" "（在地改寫）")
sed -n '/^## 保留、但與範本某行相似/,/^## 疑似/p' "$OUT" | grep -q "^  ${n}: " \
  && ok "改寫過的範本句列在「保留、但與範本某行相似」（第 ${n} 行）" || ng "「保留、但與範本某行相似」沒列第 ${n} 行"
n=$(lineof "$f" "在地改寫的步驟行")
sed -n '/^## 疑似改寫過的步驟行/,/^## 步驟 5/p' "$OUT" | grep -q "^  ${n}: 7\. " \
  && ok "改寫過的步驟 7 列在「疑似改寫過的步驟行」（第 ${n} 行）" || ng "「疑似改寫過的步驟行」沒列第 ${n} 行"
run "後段在地內容：--apply" 0 --apply "$f" "$o"
before "$o" "LOCALT1" "LOCALT2" && before "$o" "LOCALT2" "LOCALT3" && before "$o" "LOCALT3" "## 在地小節" || true
before "$o" "## CLAUDE.md 維護" "LOCALT1" || true
count_is "$o" "（在地改寫）" 1

# ---- 6. --plan 的各節標題都在；列出的行號真的指到那一行 ----
f="$WORK/v1.6.4.md"
run "--plan 輸出格式" 0 --plan "$f"
for h in "## 將刪除的行" "## 保留的行" "## 保留、但與範本某行相似" "## 疑似改寫過的步驟行" "## 步驟 5 既有的驗證指令行" "## 保留的圍欄裡有部分行在清單中" "## 區塊外還有範本行"; do
  grep -q "^${h}" "$OUT" || ng "--plan 少了「${h}」這一節"
done
sed -n '/^## 步驟 5 既有的驗證指令行/,/^## 保留的圍欄/p' "$OUT" | grep -q 'LOCAL5' \
  && ok "「步驟 5 既有的驗證指令行」列出 LOCAL5" || ng "「步驟 5 既有的驗證指令行」沒列 LOCAL5"
for sec in "## 將刪除的行" "## 保留的行"; do
  e=$(sed -n "/^${sec}\$/,/^## /p" "$OUT" | grep -E '^  [0-9]+' | sed -n 2p)
  num=$(printf '%s\n' "$e" | sed -E 's/^  ([0-9]+).*/\1/')
  txt=$(printf '%s\n' "$e" | sed -E 's/^  [0-9]+( \[[^]]*\])?: //')
  if [ -n "$num" ] && [ "$(sed -n "${num}p" "$f")" = "$txt" ]; then ok "「${sec#\#\# }」第 ${num} 行的原文對得上"; else ng "「${sec#\#\# }」的行號與原文對不上：${e}"; fi
done

# ---- 7. 保留的圍欄裡有部分行在清單中（React 圍欄被改過一行） ----
f="$WORK/react.md"
sed 's/^\(       set\.call(el, v);.*\)$/\1 \/\/ 在地改過/' "$WORK/v1.6.12.blk" | wrap > "$f"
grep -q '在地改過' "$f" || ng "React fixture 沒改到（v1.6.12 的圍欄內容變了？）"
run "React 圍欄改一行：--plan" 0 --plan "$f"
sed -n '/^## 保留的圍欄裡有部分行在清單中/,/^## 區塊外/p' "$OUT" | grep -qE '^  [0-9]+–[0-9]+：1/2 行在清單中' \
  && ok "「保留的圍欄裡有部分行在清單中」列出 React 圍欄" || ng "「保留的圍欄裡有部分行在清單中」沒列 React 圍欄"

# ---- 8. exit 碼 ----
printf '# 沒有標記\n\n## 開發流程\n\n1. 自己寫的\n' > "$WORK/nomark.md"
run "exit 2：沒有 dd-loop-version 標記" 2 --plan "$WORK/nomark.md"
printf '# X\n\n## 開發流程（每個功能段落依序走）\n<!-- dd-loop-version: 8step；dd-loop-rev: 12；供 /dd-init 判斷是否提議升級，勿刪 -->\n\n- 全部自己寫的\n' > "$WORK/onlyhead.md"
run "exit 3：只剩標題與標記可刪" 3 --plan "$WORK/onlyhead.md"
cat "$WORK/v1.6.4.md" "$WORK/v1.6.4.md" > "$WORK/twice.md"
run "exit 4：兩個標記" 4 --plan "$WORK/twice.md"
{ echo '```markdown'; cat "$WORK/new"; echo '<!-- dd-loop-version: 多一個 -->'; echo '```'; } > "$WORK/bad-tpl.md"
set +e; "$UP" --template "$WORK/bad-tpl.md" --apply "$WORK/v1.6.4.md" "$WORK/bad.out" > "$OUT" 2>&1; got=$?; set -e
if [ "$got" = 5 ] && [ ! -e "$WORK/bad.out" ]; then ok "exit 5：自檢失敗、沒寫檔"; else ng "exit 5：預期 5 且不寫檔，實際 exit ${got}$([ -e "$WORK/bad.out" ] && echo '、寫了檔')"; fi

exit $fail
