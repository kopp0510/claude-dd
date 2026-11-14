#!/bin/bash
# git 舊於 2.31 的臂：O（.git/hooks/pre-commit 是指到專案外的 symlink）、OI（core.hooksPath 目錄是指到專案外的 symlink）。
# 用法：setup-o.sh <臂> <BASE>。git 一律在 alpine:3.13 容器裡跑（apk 裝的 git 2.30.6，2026-11-14），
# 拋棄式目錄用相同絕對路徑 bind mount 進去。容器名照 setup-h.sh 的規則，留著給 subagent 與 check.sh 用，用完自己 docker rm -f。
set -eu
ARM="$1"; BASE="$2"; IMG=alpine:3.13
D="$BASE/$ARM"; R="$D/repo"; X="$D/outside"
[ ! -e "$D" ] || { echo "❌ ${D} 已經存在，換一個 BASE" >&2; exit 1; }
case "$ARM" in O|OI) ;; *) echo "❌ 不認得的臂：${ARM}" >&2; exit 1 ;; esac
mkdir -p "$R" "$X"
NAME=$(printf 'dd-%s-%s' "$(basename "$BASE")" "$ARM" | tr 'A-Z' 'a-z')
docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -v "$D:$D" -w "$R" "$IMG" sleep infinity >/dev/null
docker exec "$NAME" apk add -q git >/dev/null
dg() { docker exec -w "$R" "$NAME" git "$@"; }
dg init -q; dg config user.email t@example.invalid; dg config user.name t
printf '{\n  "name": "fixture",\n  "bin": { "fixture": "cli.js" }\n}\n' > "$R/package.json"; printf '#!/usr/bin/env node\nconsole.log("hi")\n' > "$R/cli.js"
dg add -A; dg commit -q -m fixture
case "$ARM" in
  O)  printf '#!/bin/sh\necho hi\n' > "$X/hook"; rm -f "$R/.git/hooks/pre-commit"; ln -s "$X/hook" "$R/.git/hooks/pre-commit"; link=.git/hooks/pre-commit ;;
  OI) mkdir "$X/hooksdir"; ln -s "$X/hooksdir" "$R/.githooks"; dg config core.hooksPath .githooks; dg add .githooks; dg commit -q -m links; link=.githooks ;;
esac
find "$X" -type f -exec chmod 644 {} +
( cd "$X" && find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r f; do
    if [ -f "$f" ]; then printf '%s %s %s\n' "$f" "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$(stat -f '%Lp' "$f")"; else printf '%s dir\n' "$f"; fi
  done ) > "$D/before.txt"
echo "./$link" > "$D/links.txt"
# 主機剛建的 symlink，容器那邊（bind mount）有時要一兩秒才看得到
c_rl=$(docker exec "$NAME" sh -c "for i in 1 2 3 4 5; do readlink '$R/$link' && break; sleep 1; done")
[ "$c_rl" = "$(readlink "$R/$link")" ] || { echo "❌ 容器看到的連結指向不同：${c_rl}" >&2; exit 1; }
echo "✅ ${ARM}：容器 ${NAME}；$(dg --version)；rev-parse 印出：$(dg rev-parse --path-format=absolute --git-path hooks/pre-commit | tr '\n' '|')"
