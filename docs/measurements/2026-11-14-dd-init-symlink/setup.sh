#!/bin/bash
# /dd-init 寫檔不跟 symlink 的沙盒臂 fixture（Y 是答「要」的臂：CLAUDE.md 指向專案裡的 AGENTS.md）。用法：setup.sh <臂> <BASE> <claude-dd repo 根目錄>
# 建 <BASE>/<臂>/repo（拋棄式專案）與 <BASE>/<臂>/outside（專案外的假檔，建好就 chmod 644），
# 最後在 <BASE>/<臂>/before.txt 記下專案外每個檔的 sha 與權限，給 check.sh 比對。
set -eu
ARM="$1"; BASE="$2"; DD="$3"
D="$BASE/$ARM"; R="$D/repo"; X="$D/outside"
[ ! -e "$D" ] || { echo "❌ ${D} 已經存在，換一個 BASE" >&2; exit 1; }
mkdir -p "$R" "$X"
gitinit() { git -C "$R" init -q; git -C "$R" config user.email t@example.invalid; git -C "$R" config user.name t; }
commit() { git -C "$R" add -A; git -C "$R" commit -q -m fixture; }
old_block() { { printf '# 專案\n\n專案自己的說明。\n\n'; git -C "$DD" show v1.6.4:commands/dd-init.md | awk '/^```markdown$/ && !f {f=1; next} f && /^```$/ {exit} f'; }; }
pkg_react() { printf '{\n  "name": "fixture",\n  "dependencies": { "react": "^18.3.1" }\n}\n' > "$R/package.json"; }
pkg_plain() { printf '{\n  "name": "fixture",\n  "bin": { "fixture": "cli.js" }\n}\n' > "$R/package.json"; printf '#!/usr/bin/env node\nconsole.log("hi")\n' > "$R/cli.js"; }
GATE='if [ -x "$HOME/.claude/scripts/check-claude-md.sh" ]; then "$HOME/.claude/scripts/check-claude-md.sh" || exit 1; else echo "⚠️ CLAUDE.md gate 沒執行：找不到 ~/.claude/scripts/check-claude-md.sh，這次 commit 沒檢查改到程式碼的目錄有沒有同批更新 CLAUDE.md（沒裝 claude-dd 的協作者可忽略；要恢復檢查請重新安裝 claude-dd）" >&2; fi'
NOTE='# CLAUDE.md gate — 由 /dd-init 安裝；規則：改碼目錄需有 CLAUDE.md 且同批更新'

case "$ARM" in
  A)  gitinit; pkg_plain; old_block > "$R/CLAUDE.md"; commit
      printf '專案外的檔\n' > "$X/target.md"; ln -s "$X/target.md" "$R/CLAUDE.md.dd-upgrade" ;;
  B)  gitinit; pkg_react; commit
      printf 'node_modules/\n' > "$X/gitignore"; mkdir "$X/shots"
      ln -s "$X/gitignore" "$R/.gitignore"; ln -s "$X/shots" "$R/.screenshots" ;;
  C)  gitinit; pkg_plain; commit
      printf '# 專案\n\n專案自己的說明。\n' > "$X/claude.md"; ln -s "$X/claude.md" "$R/CLAUDE.md" ;;
  C2) gitinit; pkg_plain; commit; ln -s "$X/nope.md" "$R/CLAUDE.md" ;;
  D)  gitinit; pkg_plain; commit; old_block > "$X/claude.md"; ln -s "$X/claude.md" "$R/CLAUDE.md" ;;
  E)  gitinit; pkg_plain; commit; rm -f "$R/.git/hooks/pre-commit"; ln -s "$X/nope-hook" "$R/.git/hooks/pre-commit" ;;
  F)  gitinit; pkg_plain; commit; printf '#!/bin/sh\necho hi\n' > "$X/hook"; ln -s "$X/hook" "$R/.git/hooks/pre-commit" ;;
  G)  gitinit; pkg_plain; commit
      printf '#!/bin/sh\necho hi\n"$HOME/.claude/scripts/check-claude-md.sh" || exit 1\n' > "$X/hook"; ln -s "$X/hook" "$R/.git/hooks/pre-commit" ;;
  G2) gitinit; pkg_plain; commit
      printf '#!/bin/sh\n%s\n%s\necho hi\n' "$NOTE" "$GATE" > "$X/hook"; ln -s "$X/hook" "$R/.git/hooks/pre-commit" ;;
  I)  gitinit; pkg_plain; commit; mkdir "$X/hooksdir"; ln -s "$X/hooksdir" "$R/.githooks"; git -C "$R" config core.hooksPath .githooks ;;
  Y)  gitinit; pkg_plain; printf '# 專案\n\n專案自己的說明。\n' > "$R/AGENTS.md"; ln -s AGENTS.md "$R/CLAUDE.md" ;;   # 連結在專案裡，答「要」
  K1) gitinit; pkg_react; commit ;;
  K2) pkg_react; printf '# 專案\n\n專案自己的說明。\n' > "$R/CLAUDE.md" ;;
  K3) gitinit; pkg_plain; commit; rm -f "$R/.git/hooks/pre-commit" ;;
  *)  echo "❌ 不認得的臂：${ARM}" >&2; exit 1 ;;
esac
# 專案裡的 symlink 一起 commit：模擬 clone 帶進來的連結（.git/hooks 底下的不進版控）
[ -d "$R/.git" ] && [ -n "$(git -C "$R" status --porcelain)" ] && { git -C "$R" add -A; git -C "$R" commit -q -m links; }
find "$X" -type f -exec chmod 644 {} +
# 專案外每個檔的 sha 與權限、以及外部目錄的檔案清單（check.sh 比對用）
( cd "$X" && find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r f; do
    if [ -f "$f" ]; then printf '%s %s %s\n' "$f" "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$(stat -f '%Lp' "$f" 2>/dev/null || stat -c '%a' "$f")"; else printf '%s dir\n' "$f"; fi
  done ) > "$D/before.txt"
( cd "$R" && find . -path ./.git -prune -o -type l -print; [ -L .git/hooks/pre-commit ] && echo ./.git/hooks/pre-commit; true ) | LC_ALL=C sort > "$D/links.txt"
echo "✅ ${ARM}：$(wc -l < "$D/before.txt" | tr -d ' ') 個專案外項目、$(wc -l < "$D/links.txt" | tr -d ' ') 個 symlink"
