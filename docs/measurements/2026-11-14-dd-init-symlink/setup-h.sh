#!/bin/bash
# docker 臂 fixture：H1 pre-commit、H2 husky v8、H3 husky v9；結尾 K 的是不放 symlink 的對照臂（H1K、H2K、H3K）。
# 用法：setup-h.sh <臂> <BASE>。拋棄式 repo 與專案外假檔用相同絕對路徑 bind mount 進容器，gate 腳本也以相同路徑唯讀掛進去。
# symlink 臂照「先 install、後把掛載點換成 symlink」建。容器留著給 subagent 與事後核對用，名字印在最後一行。
set -eu
ARM="$1"; BASE="$2"; IMG=dd-symlink-arms:1
D="$BASE/$ARM"; R="$D/repo"; X="$D/outside"
[ ! -e "$D" ] || { echo "❌ ${D} 已經存在，換一個 BASE" >&2; exit 1; }
mkdir -p "$R" "$X"
NAME=$(printf 'dd-%s-%s' "$(basename "$BASE")" "$ARM" | tr 'A-Z' 'a-z')
docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -v "$D:$D" -v "$HOME/.claude/scripts:$HOME/.claude/scripts:ro" -e HOME="$HOME" -w "$R" "$IMG" sleep infinity >/dev/null
dx() { docker exec -w "$R" "$NAME" sh -c "$1"; }
OLDGATE='"$HOME/.claude/scripts/check-claude-md.sh" || exit 1'
case "$ARM" in
  H1|H1K)
    dx 'git init -q && printf "repos: []\n" > .pre-commit-config.yaml && printf "node_modules/\n" > .gitignore && git add -A && git commit -qm fixture && pre-commit install >/dev/null'
    printf '%s\n' "$OLDGATE" >> "$R/.git/hooks/pre-commit"   # 舊版 /dd-init 接在檔尾的 gate 呼叫
    link=.git/hooks/pre-commit ;;
  H2|H2K)
    dx 'git init -q && printf "node_modules/\n" > .gitignore && npm init -y >/dev/null && npm pkg set scripts.prepare="husky install" && npm install -D husky@8.0.3 --no-fund --no-audit >/dev/null 2>&1 && npx husky install >/dev/null && npx husky add .husky/pre-commit "echo hi" >/dev/null && git add -A && git commit -qm fixture'
    link=.husky/pre-commit ;;
  H3|H3K)
    dx 'git init -q && printf "node_modules/\n" > .gitignore && npm init -y >/dev/null && npm install -D husky@9.1.7 --no-fund --no-audit >/dev/null 2>&1 && npx husky init >/dev/null && printf "echo hi\n" > .husky/pre-commit && git add -A && git commit -qm fixture'
    link=.husky/pre-commit ;;
  *) echo "❌ 不認得的臂：${ARM}" >&2; exit 1 ;;
esac
case "$ARM" in
  *K) : > "$D/links.txt"; : > "$D/before.txt" ;;
  *)  mv "$R/$link" "$X/hook"; ln -s "$X/hook" "$R/$link"
      case "$link" in .husky/*) dx "git add $link && git commit -qm links" ;; esac
      chmod 644 "$X/hook"
      ( cd "$X" && find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r f; do
          printf '%s %s %s\n' "$f" "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$(stat -f '%Lp' "$f")"; done ) > "$D/before.txt"
      echo "./$link" > "$D/links.txt"
      # 主機剛建的 symlink，容器那邊（bind mount）有時要一兩秒才看得到，所以在容器裡重試幾次
      h_rl=$(readlink "$R/$link"); c_rl=$(docker exec "$NAME" sh -c "for i in 1 2 3 4 5; do readlink '$R/$link' && break; sleep 1; done")
      h_sha=$(shasum -a 256 "$X/hook" | cut -d' ' -f1); c_sha=$(docker exec "$NAME" sha256sum "$X/hook" | cut -d' ' -f1)
      [ "$h_rl" = "$c_rl" ] && [ "$h_sha" = "$c_sha" ] && echo "✅ 主機與容器解析到同一個檔（readlink、sha 一致）" || { echo "❌ 主機與容器不一致：${h_rl} / ${c_rl}；${h_sha} / ${c_sha}"; exit 1; } ;;
esac
echo "✅ ${ARM}：容器 ${NAME}；工具版本：$(dx 'git --version; pre-commit --version; node --version; [ -d node_modules/husky ] && node -p "\"husky \"+require(\"./node_modules/husky/package.json\").version" || true' | tr '\n' ' ')"
