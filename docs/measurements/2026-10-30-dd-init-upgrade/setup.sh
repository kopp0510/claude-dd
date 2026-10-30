#!/bin/bash
# 測試清單 4 的沙盒：每個案例一個拋棄式 git repo
set -e
T=${OUT:-$(mktemp -d)}; R=$(cd "$(dirname "$0")/../../.." && pwd)   # 案例 repo 建在 $OUT（預設暫存目錄），不建在 repo 裡
stamp() { awk '/^```markdown$/ && !f {f=1; next} f && /^```$/ {exit} f'; }
git -C "$R" show v1.6.12:commands/dd-init.md | stamp > "$T/b12.md"
git -C "$R" show 6a9addd:commands/dd-init.md | stamp > "$T/b2.md"
stamp < "$R/commands/dd-init.md" > "$T/b13.md"
locals() { awk '
  /^5\. / { print "   - LOCAL4 本專案的 review 一律附上 migration 清單" }
  /^驗證不過/ { print "   - LOCAL8 步驟 8 也看 docs/ 底下的 CLAUDE.md"; print "" }
  { print }'; }
mk() {  # $1=案例 $2=package.json 內容（空字串 = 不放）
  d="$T/$1"; rm -rf "$d"; mkdir -p "$d"; cd "$d"; git init -q; git config user.email t@e; git config user.name t
  [ -n "$2" ] && printf '%s\n' "$2" > package.json
  mkdir -p src && echo 'export const x = 1' > src/index.js
}
hdr='# 測試專案\n\nNode 服務。\n\n'
BE='{"name":"svc","dependencies":{"express":"^4.19.0"},"scripts":{"start":"node src/index.js"}}'
FE='{"name":"web","dependencies":{"react":"^18.3.1","react-dom":"^18.3.1"},"devDependencies":{"vite":"^5.4.0"}}'
mk agree "$BE";   { printf "$hdr"; locals < "$T/b12.md"; } > CLAUDE.md
mk refuse "$BE";  { printf "$hdr"; locals < "$T/b12.md"; } > CLAUDE.md
mk rental "$BE";  { printf "$hdr## 專案規則\n\n"; sed 's/^## 開發流程（每個功能段落依序走）$/### 工作流程（完成的定義，不可省略）/' "$T/b2.md"; printf '\n## 部署\n\n- LOCALD 用 docker compose\n'; } > CLAUDE.md
mk react "$FE";   { printf "$hdr"; locals < "$T/b12.md"; } > CLAUDE.md
mk create "$FE";  rm -f CLAUDE.md
mk cli "";        rm -rf src package.json; printf '[project]\nname = "tool"\n[project.scripts]\ntool = "tool.cli:main"\n' > pyproject.toml; mkdir -p tool && echo 'def main(): print("hi")' > tool/cli.py; { printf '# CLI 工具\n\n'; locals < "$T/b12.md"; } > CLAUDE.md
mk curl "$BE";    { printf "$hdr"; awk '/^6\. / { print "   - LOCALC curl -s localhost:3000/health | grep ok" } { print }' "$T/b12.md"; } > CLAUDE.md
mk rev13 "$BE";   { printf "$hdr"; cat "$T/b13.md"; } > CLAUDE.md
for c in agree refuse rental react create cli curl rev13; do cd "$T/$c"; git add -A; git commit -qm init; cp -f CLAUDE.md "$T/$c.orig" 2>/dev/null || true; done
echo "完成：$T"
